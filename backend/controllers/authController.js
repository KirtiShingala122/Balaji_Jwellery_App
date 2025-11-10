const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const JWT_SECRET = 'supersecretkey'; //  change this in production!

//  Register new admin
exports.register = async (req, res) => {
    try {
        const { username, password, email, fullName } = req.body;

        if (!username || !password || !fullName) {
            return res.status(400).json({ error: 'All fields are required' });
        }

        // Check if username already exists
        db.query('SELECT * FROM admins WHERE username = ?', [username], async (err, results) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            if (results.length > 0) return res.status(400).json({ error: 'Username already exists' });

            // Hash password
            const hashedPassword = await bcrypt.hash(password, 10);

            // Insert into DB
            db.query(
                'INSERT INTO admins (username, password, email, fullName) VALUES (?, ?, ?, ?)',
                [username, hashedPassword, email, fullName],
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

        // Compare password
        const isMatch = await bcrypt.compare(password, admin.password);
        if (!isMatch) return res.status(401).json({ error: 'Invalid username or password' });

        // Generate JWT token
        const token = jwt.sign(
            { id: admin.id, username: admin.username },
            JWT_SECRET,
            { expiresIn: '1d' }
        );

        // Update last login
        db.query('UPDATE admins SET lastLogin = NOW() WHERE id = ?', [admin.id]);

        res.json({
            message: 'Login successful',
            token,
            admin: {
                id: admin.id,
                username: admin.username,
                fullName: admin.fullName,
                email: admin.email
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
