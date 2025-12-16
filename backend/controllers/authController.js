const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const JWT_SECRET = 'supersecretkey'; //  change this in production!

//  Register new admin
exports.register = async (req, res) => {
    try {
        const { username, password, email, fullName, phoneNumber, address } = req.body;

        if (!username || !password || !fullName) {
            return res.status(400).json({ error: 'All required fields must be provided' });
        }

        db.query('SELECT * FROM admins WHERE username = ?', [username], async (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (results.length > 0) return res.status(400).json({ error: 'Username already exists' });

            const hashedPassword = await bcrypt.hash(password, 10);

            db.query(
                'INSERT INTO admins (username, password, email, fullName, phoneNumber, address) VALUES (?, ?, ?, ?, ?, ?)',
                [username, hashedPassword, email, fullName, phoneNumber || null, address || null],
                (err) => {
                    if (err) return res.status(500).json({ error: 'Failed to register user' });
                    res.status(201).json({ message: 'Admin registered successfully' });
                }
            );
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

//  Login admin
exports.login = (req, res) => {
    const { username, password } = req.body;

    db.query('SELECT * FROM admins WHERE username = ?', [username], async (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0) return res.status(401).json({ error: 'Invalid username or password' });

        const admin = results[0];

        // Compare password (supports legacy plain-text seed on first login)
        let isMatch = await bcrypt.compare(password, admin.password);
        let rehash = false;

        if (!isMatch && admin.password === password) {
            isMatch = true;
            rehash = true; // migrate legacy plain password to bcrypt
        }

        if (!isMatch) return res.status(401).json({ error: 'Invalid username or password' });

        // Generate JWT token
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

        res.json({
            message: 'Login successful',
            token,
            admin: {
                id: admin.id,
                username: admin.username,
                fullName: admin.fullName,
                email: admin.email,
                phoneNumber: admin.phoneNumber,
                address: admin.address,
            }
        });
    });
};

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
