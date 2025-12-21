const db = require('../db');
// Legacy libs kept for backward compatibility and commented logic
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const JWT_SECRET = 'supersecretkey'; // legacy; not used for Firebase auth
const admin = require('../firebaseAdmin');

// Register: store profile data only. If `firebaseUid` is provided, associate it.
// NOTE: Passwords must NOT be stored when using Firebase Auth. Legacy password
// logic is preserved below but the code path that writes passwords is bypassed
// when `firebaseUid` is present.
exports.register = async (req, res) => {
    try {
        let { username, password, email, fullName, phoneNumber, address, firebaseUid } = req.body;

        console.log('req.body', req.body);
        console.log('Register payload:', { username, email, fullName, phoneNumber, address, firebaseUid });

        // If Authorization header (Firebase token) is provided, verify it and
        // override any client-sent firebaseUid to ensure authenticity.
        try {
            const authHeader = req.headers.authorization || req.headers.Authorization;
            if (authHeader && authHeader.startsWith('Bearer ')) {
                const idToken = authHeader.split('Bearer ')[1];
                if (idToken) {
                    const decoded = await admin.auth().verifyIdToken(idToken);
                    firebaseUid = decoded.uid; // trust verified uid
                    console.log('firebaseUid (from token):', firebaseUid);
                }
            }
        } catch (tokenErr) {
            console.warn('Register: Firebase token verify skipped/failed:', tokenErr.message || tokenErr);
            // Continue — registration may still proceed if firebaseUid provided explicitly
        }

        if (!username || !fullName) {
            return res.status(400).json({ error: 'Username and fullName are required' });
        }

        // Check username uniqueness
        db.query('SELECT * FROM admins WHERE username = ?', [username], async (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (results.length > 0) return res.status(400).json({ error: 'Username already exists' });

            // If firebaseUid is present we MUST NOT store the password in DB.
            // Insert profile data and include firebaseUid if the column exists.
            db.query("SHOW COLUMNS FROM admins LIKE 'firebaseUid'", (colErr, colRows) => {
                if (colErr) {
                    console.error('Failed to check admins columns:', colErr);
                    // Fallback to insert without firebaseUid
                    const insertQuery = 'INSERT INTO admins (username, email, fullName, phoneNumber, address) VALUES (?, ?, ?, ?, ?)';
                    const insertParams = [username, email, fullName, phoneNumber || null, address || null];
                    db.query(insertQuery, insertParams, (err) => {
                        if (err) {
                            console.error('Failed to register user - SQL error:', err);
                            return res.status(500).json({ error: 'Failed to register user', details: err.message });
                        }
                        res.status(201).json({ message: 'Admin profile created successfully' });
                    });
                } else if (colRows.length > 0 && firebaseUid) {
                    // Column exists; include firebaseUid in insert. Do NOT store password.
                    const insertQuery = 'INSERT INTO admins (username, email, fullName, phoneNumber, address, firebaseUid) VALUES (?, ?, ?, ?, ?, ?)';
                    const insertParams = [username, email, fullName, phoneNumber || null, address || null, firebaseUid];
                    db.query(insertQuery, insertParams, (err) => {
                        if (err) {
                            console.error('Failed to register user with firebaseUid - SQL error:', err);
                            return res.status(500).json({ error: 'Failed to register user', details: err.message });
                        }
                        res.status(201).json({ message: 'Admin profile created successfully' });
                    });
                } else {
                    // Column does not exist or no firebaseUid provided; insert without firebaseUid
                    const insertQuery = 'INSERT INTO admins (username, email, fullName, phoneNumber, address) VALUES (?, ?, ?, ?, ?)';
                    const insertParams = [username, email, fullName, phoneNumber || null, address || null];
                    db.query(insertQuery, insertParams, (err) => {
                        if (err) {
                            console.error('Failed to register user - SQL error:', err);
                            return res.status(500).json({ error: 'Failed to register user', details: err.message });
                        }
                        res.status(201).json({ message: 'Admin profile created successfully' });
                    });
                }
            });
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Login: verify Firebase ID token from Authorization header and return profile
exports.login = async (req, res) => {
    try {
        const authHeader = req.headers.authorization || req.headers.Authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'No Firebase ID token provided' });
        }

        const idToken = authHeader.split('Bearer ')[1];
        if (!idToken) return res.status(401).json({ error: 'Invalid auth header' });

        // Verify the token with Firebase Admin SDK
        const decoded = await admin.auth().verifyIdToken(idToken);
        const firebaseUid = decoded.uid;
        console.log('firebaseUid (login):', firebaseUid);

        // Find admin profile by firebaseUid
        db.query('SELECT id, username, fullName, email, phoneNumber, address, firebaseUid FROM admins WHERE firebaseUid = ? LIMIT 1', [firebaseUid], (err, results) => {
            if (err) {
                console.error('Login DB error (firebaseUid lookup):', err);
                return res.status(500).json({ error: 'Database error', details: err.message });
            }
            if (!results || results.length === 0) {
                return res.status(404).json({ error: 'Profile not found. Please register first.' });
            }

            const adminRow = results[0];
            // Respond with profile data (do NOT return passwords or JWTs)
            return res.json({
                message: 'Login verified via Firebase',
                admin: {
                    id: adminRow.id,
                    username: adminRow.username,
                    fullName: adminRow.fullName,
                    email: adminRow.email,
                    phoneNumber: adminRow.phoneNumber,
                    address: adminRow.address,
                    firebaseUid: adminRow.firebaseUid,
                }
            });
        });
    } catch (err) {
        console.error('Firebase login verification failed:', err);
        return res.status(401).json({ error: 'Unauthorized: invalid Firebase token' });
    }
};

// Verify token middleware: verify Firebase ID token and attach `req.firebaseUser`.
exports.verifyToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization || req.headers.Authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'No Firebase ID token provided' });
        }

        const idToken = authHeader.split('Bearer ')[1];
        const decoded = await admin.auth().verifyIdToken(idToken);

        // Attach firebase info for downstream handlers
        req.firebaseUser = {
            uid: decoded.uid,
            email: decoded.email,
            claims: decoded,
        };
        next();
    } catch (err) {
        console.error('Firebase token verification failed:', err.message || err);
        return res.status(401).json({ error: 'Unauthorized: invalid Firebase token' });
    }
};

// Change password: Disabled for Firebase-backed auth. Clients should use
// Firebase Authentication flows (Firebase Console, FirebaseAuth SDK
// methods such as `sendPasswordResetEmail` or `updatePassword`).
exports.changePassword = async (req, res) => {
    return res.status(403).json({
        error: 'Password changes must be performed via Firebase Authentication. Do not call backend for password updates.'
    });
    /*
    // Legacy implementation kept below for reference. Do NOT enable when
    // Firebase Auth is the source of truth.
    try {
        // ...legacy code...
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal server error' });
    }
    */
};

// Update profile: identify user by `req.firebaseUser.uid` and update profile fields
exports.updateProfile = (req, res) => {
    try {
        const firebaseUid = req.firebaseUser?.uid;
        const { fullName, email, phoneNumber, address, username } = req.body;

        if (!firebaseUid) return res.status(401).json({ error: 'Missing Firebase authentication' });
        if (!fullName || !username) return res.status(400).json({ error: 'Full name and username are required' });

        // Find admin by firebaseUid
        db.query('SELECT id FROM admins WHERE firebaseUid = ? LIMIT 1', [firebaseUid], (err, rows) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (!rows || rows.length === 0) return res.status(404).json({ error: 'Admin profile not found' });

            const userId = rows[0].id;

            // Ensure username uniqueness if changed
            db.query('SELECT id FROM admins WHERE username = ? AND id != ?', [username, userId], (err2, dupRows) => {
                if (err2) return res.status(500).json({ error: 'Database error' });
                if (dupRows.length > 0) return res.status(400).json({ error: 'Username already taken' });

                db.query(
                    'UPDATE admins SET username = ?, fullName = ?, email = ?, phoneNumber = ?, address = ?, updatedAt = NOW() WHERE id = ?'
                    ,
                    [username, fullName, email || null, phoneNumber || null, address || null, userId],
                    (err3) => {
                        if (err3) return res.status(500).json({ error: 'Failed to update profile' });

                        db.query('SELECT id, username, fullName, email, phoneNumber, address FROM admins WHERE id = ?', [userId], (err4, result) => {
                            if (err4 || result.length === 0) {
                                return res.status(500).json({ error: 'Failed to fetch updated profile' });
                            }
                            res.json({ admin: result[0] });
                        });
                    }
                );
            });
        });
    } catch (error) {
        console.error('updateProfile error:', error);
        return res.status(500).json({ error: 'Internal server error' });
    }
};

// Legacy JWT/bcrypt block retained for reference only. It previously overwrote
// the Firebase-first exports above; commenting it out ensures Firebase
// remains the single source of truth.
/*
// Helper to handle password comparison / token generation given an `admin` row
async function handleLoginWithAdmin(admin, password, res) {
    try {
        // Compare password (supports legacy plain-text seed on first login)
        let isMatch = await bcrypt.compare(password, admin.password);
        let rehash = false;

        if (!isMatch && admin.password === password) {
            isMatch = true;
            rehash = true; // migrate legacy plain password to bcrypt
        }

        if (!isMatch) return res.status(401).json({ error: 'Invalid username or password' });

        // Generate JWT token (legacy - not used when Firebase is source of truth)
        const token = jwt.sign(
            { id: admin.id, username: admin.username },
            JWT_SECRET,
            { expiresIn: '1d' }
        );

        // Update last login (and migrate legacy password if needed)
        const updateFields = rehash
            ? [await bcrypt.hash(password, 10), admin.id]
            : [admin.id];

        const query = rehash
            ? 'UPDATE admins SET password = ?, lastLogin = NOW() WHERE id = ?'
            : 'UPDATE admins SET lastLogin = NOW() WHERE id = ?';

        db.query(query, updateFields);

        return res.json({
            message: 'Login successful',
            token, // legacy token included for backward compatibility (clients should ignore)
            admin: {
                id: admin.id,
                username: admin.username,
                fullName: admin.fullName,
                email: admin.email,
                phoneNumber: admin.phoneNumber,
                address: admin.address,
            }
        });
    } catch (err) {
        console.error('Login processing error:', err);
        return res.status(500).json({ error: 'Internal server error' });
    }
}

//  Middleware: verify token
exports.verifyToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) return res.status(401).json({ error: 'No token provided' });

    jwt.verify(token, JWT_SECRET, (err, decoded) => {
        if (err) return res.status(403).json({ error: 'Invalid token' });

        req.user = decoded;
        next();
    });
};

// Change password (protected)
exports.changePassword = async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        if (!currentPassword || !newPassword) {
            return res.status(400).json({ error: 'Current and new password are required' });
        }

        const userId = req.user.id;
        db.query('SELECT * FROM admins WHERE id = ?', [userId], async (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (results.length === 0) return res.status(404).json({ error: 'User not found' });

            const admin = results[0];
            const matches = await bcrypt.compare(currentPassword, admin.password);
            if (!matches) return res.status(401).json({ error: 'Current password incorrect' });

            const hashed = await bcrypt.hash(newPassword, 10);
            db.query(
                'UPDATE admins SET password = ?, updatedAt = NOW() WHERE id = ?',
                [hashed, userId],
                (err) => {
                    if (err) return res.status(500).json({ error: 'Failed to update password' });
                    res.json({ message: 'Password updated successfully' });
                }
            );
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Update profile (protected)
exports.updateProfile = (req, res) => {
    const userId = req.user.id;
    const { fullName, email, phoneNumber, address, username } = req.body;

    if (!fullName || !username) {
        return res.status(400).json({ error: 'Full name and username are required' });
    }

    // Ensure username uniqueness if changed
    db.query('SELECT id FROM admins WHERE username = ? AND id != ?', [username, userId], (err, rows) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (rows.length > 0) return res.status(400).json({ error: 'Username already taken' });

        db.query(
            'UPDATE admins SET username = ?, fullName = ?, email = ?, phoneNumber = ?, address = ?, updatedAt = NOW() WHERE id = ?',
            [username, fullName, email || null, phoneNumber || null, address || null, userId],
            (err) => {
                if (err) return res.status(500).json({ error: 'Failed to update profile' });

                db.query('SELECT id, username, fullName, email, phoneNumber, address FROM admins WHERE id = ?', [userId], (err, result) => {
                    if (err || result.length === 0) {
                        return res.status(500).json({ error: 'Failed to fetch updated profile' });
                    }
                    res.json({ admin: result[0] });
                });
            }
        );
    });
};
*/
