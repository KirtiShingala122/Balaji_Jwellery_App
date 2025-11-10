const db = require('../db');

// Get all products
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

//  Add product
exports.addProduct = (req, res) => {
    const { uniqueCode, name, description, categoryId, price, stockQuantity } = req.body;
    db.query(
        'INSERT INTO products (uniqueCode, name, description, categoryId, price, stockQuantity) VALUES (?, ?, ?, ?, ?, ?)',
        [uniqueCode, name, description, categoryId, price, stockQuantity],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to add product' });
            res.status(201).json({ message: 'Product added', id: result.insertId });
        }
    );
};

//  Update product
exports.updateProduct = (req, res) => {
    const { id } = req.params;
    const { name, description, categoryId, price, stockQuantity } = req.body;
    db.query(
        'UPDATE products SET name=?, description=?, categoryId=?, price=?, stockQuantity=? WHERE id=?',
        [name, description, categoryId, price, stockQuantity, id],
        (err) => {
            if (err) return res.status(500).json({ error: 'Failed to update product' });
            res.json({ message: 'Product updated successfully' });
        }
    );
};

//  Delete product
exports.deleteProduct = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM products WHERE id=?', [id], (err) => {
        if (err) return res.status(500).json({ error: 'Failed to delete product' });
        res.json({ message: 'Product deleted successfully' });
    });
};
