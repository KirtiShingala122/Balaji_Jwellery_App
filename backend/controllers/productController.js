const db = require('../db');
const path = require('path');
const fs = require('fs');
const multer = require('multer');

// ✅ Ensure uploads folder exists
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

// ✅ Configure multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});

exports.upload = multer({ storage });

// ✅ Get all products
exports.getAllProducts = (req, res) => {
    const query = `
    SELECT p.*, c.name AS categoryName
    FROM products p
    JOIN categories c ON p.categoryId = c.id
    ORDER BY p.id DESC`;

    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(results);
    });
};

// ✅ Get product by ID
exports.getProductById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM products WHERE id = ?', [id], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0) return res.status(404).json({ error: 'Not found' });
        res.json(results[0]);
    });
};

// ✅ Get low-stock products
exports.getLowStockProducts = (req, res) => {
    db.query('SELECT * FROM products WHERE stockQuantity < 5', (err, results) => {
        if (err) return res.status(500).json({ error: 'Failed to fetch low-stock' });
        res.json(results);
    });
};

// ✅ Add product with image
exports.addProduct = (req, res) => {
    const { uniqueCode, name, description, categoryId, price, stockQuantity } = req.body;
    const imagePath = req.file ? `/uploads/${req.file.filename}` : null;

    db.query(
        'INSERT INTO products (uniqueCode, name, description, categoryId, price, stockQuantity, imagePath) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [uniqueCode, name, description, categoryId, price, stockQuantity, imagePath],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to add product' });

            const fullImageUrl = imagePath ? `${req.protocol}://${req.get('host')}${imagePath}` : null;
            res.status(201).json({ message: 'Product added', id: result.insertId, imageUrl: fullImageUrl });
        }
    );
};

// ✅ Update product with image
exports.updateProduct = (req, res) => {
    const { id } = req.params;
    const { uniqueCode, name, description, categoryId, price, stockQuantity } = req.body;
    const imagePath = req.file ? `/uploads/${req.file.filename}` : req.body.imagePath;

    db.query(
        'UPDATE products SET uniqueCode=?, name=?, description=?, categoryId=?, price=?, stockQuantity=?, imagePath=? WHERE id=?',
        [uniqueCode, name, description, categoryId, price, stockQuantity, imagePath, id],
        (err) => {
            if (err) return res.status(500).json({ error: 'Failed to update product' });
            const fullImageUrl = imagePath ? `${req.protocol}://${req.get('host')}${imagePath}` : null;
            res.json({ message: 'Product updated successfully', imageUrl: fullImageUrl });
        }
    );
};

// ✅ Delete product
exports.deleteProduct = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM products WHERE id=?', [id], (err) => {
        if (err) return res.status(500).json({ error: 'Failed to delete product' });
        res.json({ message: 'Product deleted successfully' });
    });
};
