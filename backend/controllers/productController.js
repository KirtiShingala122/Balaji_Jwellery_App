const db = require('../db');
const path = require('path');
const fs = require('fs');
const multer = require('multer');

// Ensure uploads folder exists
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir);

//  Configure multer
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});

exports.upload = multer({ storage });

//  Get all products
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

//  Get product by ID
exports.getProductById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM products WHERE id = ?', [id], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0) return res.status(404).json({ error: 'Not found' });
        res.json(results[0]);
    });
};

//  Get low-stock products
exports.getLowStockProducts = (req, res) => {
    db.query('SELECT * FROM products WHERE stockQuantity < 5', (err, results) => {
        if (err) return res.status(500).json({ error: 'Failed to fetch low-stock' });
        res.json(results);
    });
};

// Add product with image
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

// Update product with image
exports.updateProduct = (req, res) => {
    const { id } = req.params;
    const { uniqueCode, name, description, categoryId, price, stockQuantity } = req.body;
    const newImagePath = req.file ? `/uploads/${req.file.filename}` : req.body.imagePath;

    // If a new file was uploaded, remove the old image file (if any)
    const getSql = 'SELECT imagePath FROM products WHERE id = ?';
    db.query(getSql, [id], (gErr, gRows) => {
        if (gErr) return res.status(500).json({ error: 'Failed to fetch existing product' });

        const oldImagePath = gRows && gRows[0] ? gRows[0].imagePath : null;

        db.query(
            'UPDATE products SET uniqueCode=?, name=?, description=?, categoryId=?, price=?, stockQuantity=?, imagePath=? WHERE id=?',
            [uniqueCode, name, description, categoryId, price, stockQuantity, newImagePath, id],
            (err) => {
                if (err) return res.status(500).json({ error: 'Failed to update product' });

                // delete old file if a new one replaced it
                if (req.file && oldImagePath) {
                    const rel = oldImagePath.replace(/^\/+/, '');
                    const filePath = path.join(__dirname, '..', rel);
                    fs.unlink(filePath, (uErr) => {
                        if (uErr && uErr.code !== 'ENOENT') console.error('Failed to remove old image', uErr);
                    });
                }

                const fullImageUrl = newImagePath ? `${req.protocol}://${req.get('host')}${newImagePath}` : null;
                res.json({ message: 'Product updated successfully', imageUrl: fullImageUrl });
            }
        );
    });
};

// Delete product
exports.deleteProduct = (req, res) => {
    const { id } = req.params;
    // Check for references in bill_items to avoid FK constraint errors
    // First fetch product to get imagePath and ensure it exists
    db.query('SELECT imagePath FROM products WHERE id = ?', [id], (gErr, gRows) => {
        if (gErr) return res.status(500).json({ error: 'Failed to fetch product' });
        if (!gRows || gRows.length === 0) return res.status(404).json({ error: 'Product not found' });

        const imagePath = gRows[0].imagePath;

        db.query('SELECT COUNT(*) AS cnt FROM bill_items WHERE productId = ?', [id], (err, rows) => {
            if (err) return res.status(500).json({ error: 'Failed to check product references' });
            const cnt = rows[0].cnt || 0;
            if (cnt > 0) {
                return res.status(400).json({ error: 'Product is referenced by existing bills. Remove bill items referencing this product before deleting it.' });
            }

            db.query('DELETE FROM products WHERE id=?', [id], (err) => {
                if (err) return res.status(500).json({ error: 'Failed to delete product' });

                // remove image file if present (best-effort)
                if (imagePath) {
                    const rel = imagePath.replace(/^\/+/, '');
                    const filePath = path.join(__dirname, '..', rel);
                    fs.unlink(filePath, (uErr) => {
                        if (uErr && uErr.code !== 'ENOENT') console.error('Failed to remove product image', uErr);
                    });
                }

                res.json({ message: 'Product deleted successfully' });
            });
        });
    });
};

exports.getProductByCode = (req, res) => {
    const { code } = req.params;
    db.query(
        `SELECT p.*, c.name AS categoryName
     FROM products p
     JOIN categories c ON p.categoryId = c.id
     WHERE p.uniqueCode = ?`,
        [code],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'DB error' });
            if (!result.length)
                return res.status(404).json({ error: 'Product not found' });
            res.json(result[0]);
        }
    );
};