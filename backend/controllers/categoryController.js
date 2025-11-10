const db = require('../db');

//  Get all categories
exports.getAllCategories = (req, res) => {
    db.query('SELECT * FROM categories', (err, results) => {
        if (err) {
            console.error('Error fetching categories:', err);
            return res.status(500).json({ error: 'Database error' });
        }
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

// Add category
exports.addCategory = (req, res) => {
    const { name, description } = req.body;
    if (!name || !description)
        return res.status(400).json({ error: 'Name and description required' });

    const createdAt = new Date();
    const updatedAt = new Date();

    db.query(
        'INSERT INTO categories (name, description, createdAt, updatedAt) VALUES (?, ?, ?, ?)',
        [name, description, createdAt, updatedAt],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to add category' });
            res.status(201).json({ message: 'Category added', id: result.insertId });
        }
    );
};

// Update category
exports.updateCategory = (req, res) => {
    const { id } = req.params;
    const { name, description } = req.body;
    const updatedAt = new Date();

    db.query(
        'UPDATE categories SET name=?, description=?, updatedAt=? WHERE id=?',
        [name, description, updatedAt, id],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to update category' });
            res.json({ message: 'Category updated successfully' });
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
