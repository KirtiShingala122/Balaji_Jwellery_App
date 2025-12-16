const db = require('../db');
const path = require('path');
const fs = require('fs');
const multer = require('multer');

//  Ensure uploads folder exists
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

//  Configure multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});

exports.upload = multer({ storage });

//  Get all categories
exports.getAllCategories = (req, res) => {
    db.query('SELECT * FROM categories', (err, results) => {
        if (err) {
            console.error(' Error fetching categories:', err);
            return res.status(500).json({ error: 'Database error' });
        }
        console.log(` Fetched ${results.length} categories`);
        res.json(results);
    });
};

// Get category by ID
exports.getCategoryById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM categories WHERE id = ?', [id], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0)
            return res.status(404).json({ error: 'Category not found' });
        res.json(results[0]);
    });
};

// Add category with image
exports.addCategory = (req, res) => {
    console.log(' Add Category Request:', {
        body: req.body,
        file: req.file ? { filename: req.file.filename, size: req.file.size } : 'No file'
    });

    const { name, description } = req.body;
    if (!name || !description) {
        console.error(' Missing name or description');
        return res.status(400).json({ error: 'Name and description required' });
    }

    const createdAt = new Date();
    const updatedAt = new Date();
    const imagePath = req.file ? `/uploads/${req.file.filename}` : null;

    console.log(' Inserting category:', { name, description, imagePath });

    db.query(
        'INSERT INTO categories (name, description, imagePath, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)',
        [name, description, imagePath, createdAt, updatedAt],
        (err, result) => {
            if (err) {
                console.error(' Database error:', err);
                return res.status(500).json({ error: 'Failed to add category', details: err.message });
            }
            
            const fullImageUrl = imagePath ? `${req.protocol}://${req.get('host')}${imagePath}` : null;
            console.log(' Category added successfully:', { id: result.insertId, imageUrl: fullImageUrl });
            res.status(201).json({ message: 'Category added', id: result.insertId, imageUrl: fullImageUrl });
        }
    );
};

// Update category with image
exports.updateCategory = (req, res) => {
    const { id } = req.params;
    const { name, description } = req.body;
    const updatedAt = new Date();
    const imagePath = req.file ? `/uploads/${req.file.filename}` : req.body.imagePath;

    db.query(
        'UPDATE categories SET name=?, description=?, imagePath=?, updatedAt=? WHERE id=?',
        [name, description, imagePath, updatedAt, id],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to update category' });
            
            const fullImageUrl = imagePath ? `${req.protocol}://${req.get('host')}${imagePath}` : null;
            res.json({ message: 'Category updated successfully', imageUrl: fullImageUrl });
        }
    );
};

// Delete category
exports.deleteCategory = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM categories WHERE id = ?', [id], (err, result) => {
        if (err) return res.status(500).json({ error: 'Failed to delete category' });
        res.json({ message: 'Category deleted successfully' });
    });
};
