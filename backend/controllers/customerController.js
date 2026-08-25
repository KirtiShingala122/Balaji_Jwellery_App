const db = require('../db');

// Get all customers
exports.getAllCustomers = (req, res) => {
    db.query('SELECT * FROM customers ORDER BY id DESC', (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(results);
    });
};

// Search customers by name or phone (case-insensitive)
exports.searchCustomers = (req, res) => {
    const { q } = req.query;
    if (!q || !q.trim()) {
        // Fallback to full list if no query provided
        return exports.getAllCustomers(req, res);
    }

    const term = `%${q.trim()}%`;
    const sql = `
      SELECT *
      FROM customers
      WHERE LOWER(name) LIKE LOWER(?)
         OR phoneNumber LIKE ?
      ORDER BY id DESC
      LIMIT 25
    `;

    db.query(sql, [term, term], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(results);
    });
};

// Get customer by ID
exports.getCustomerById = (req, res) => {
    const { id } = req.params;
    db.query('SELECT * FROM customers WHERE id = ?', [id], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0) return res.status(404).json({ error: 'Customer not found' });
        res.json(results[0]);
    });
};

// Add customer
exports.addCustomer = (req, res) => {
    const { name, email, phoneNumber, address } = req.body;
    db.query(
        'INSERT INTO customers (name, email, phoneNumber, address) VALUES (?, ?, ?, ?)',
        [name, email, phoneNumber, address],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to add customer' });
            res.status(201).json({ message: 'Customer added', id: result.insertId });
        }
    );
};

// Update customer
exports.updateCustomer = (req, res) => {
    const { id } = req.params;
    const { name, email, phoneNumber, address } = req.body;
    db.query(
        'UPDATE customers SET name=?, email=?, phoneNumber=?, address=? WHERE id=?',
        [name, email, phoneNumber, address, id],
        (err) => {
            if (err) return res.status(500).json({ error: 'Failed to update customer' });
            res.json({ message: 'Customer updated successfully' });
        }
    );
};

// Delete customer
exports.deleteCustomer = (req, res) => {
    const { id } = req.params;
    db.query('DELETE FROM customers WHERE id=?', [id], (err) => {
        if (err) return res.status(500).json({ error: 'Failed to delete customer' });
        res.json({ message: 'Customer deleted successfully' });
    });
};
