const db = require('../db');

//  Get all bills
exports.getAllBills = (req, res) => {
    const query = `
    SELECT b.*, c.name AS customerName
    FROM bills b
    JOIN customers c ON b.customerId = c.id
    ORDER BY b.id DESC`;
    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ error: 'Failed to fetch bills' });
        res.json(results);
    });
};

//  Get bill by ID (with items)
exports.getBillById = (req, res) => {
    const { id } = req.params;
    const billQuery = 'SELECT * FROM bills WHERE id = ?';
    const itemsQuery = 'SELECT * FROM bill_items WHERE billId = ?';

    db.query(billQuery, [id], (err, bills) => {
        if (err) return res.status(500).json({ error: 'Failed to fetch bill' });
        if (bills.length === 0) return res.status(404).json({ error: 'Bill not found' });

        db.query(itemsQuery, [id], (err, items) => {
            if (err) return res.status(500).json({ error: 'Failed to fetch items' });
            res.json({ ...bills[0], items });
        });
    });
};

//  Add bill
exports.addBill = (req, res) => {
    const { billNumber, customerId, subtotal, taxAmount, discountAmount, totalAmount, paymentStatus, notes } = req.body;

    db.query(
        'INSERT INTO bills (billNumber, customerId, subtotal, taxAmount, discountAmount, totalAmount, paymentStatus, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [billNumber, customerId, subtotal, taxAmount, discountAmount, totalAmount, paymentStatus, notes],
        (err, result) => {
            if (err) return res.status(500).json({ error: 'Failed to add bill' });
            res.status(201).json({ message: 'Bill added', id: result.insertId });
        }
    );
};
