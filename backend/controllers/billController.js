const db = require('../db');

//  Helper: generate next bill number
const getNextBillNumber = () => {
    return new Promise((resolve, reject) => {
        // Use SUBSTRING_INDEX to support both "BILL-0001" and "BILL0001" formats.
        const sql = `
      SELECT IFNULL(MAX(CAST(SUBSTRING_INDEX(billNumber, '-', -1) AS UNSIGNED)), 0) + 1 AS next
      FROM bills
    `;
        db.query(sql, (err, result) => {
            if (err) return reject(err);
            const next = result[0].next;
            resolve(`BILL-${String(next).padStart(4, '0')}`);
        });
    });
};

// Get all bills with customer name
exports.getAllBills = (req, res) => {
    const sql = `
      SELECT b.*, c.name AS customerName
      FROM bills b
      JOIN customers c ON c.id = b.customerId
      ORDER BY b.createdAt DESC
    `;

    db.query(sql, (err, rows) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        res.json(rows);
    });
};

// Get single bill with items
exports.getBillById = (req, res) => {
    const billId = req.params.id;

    db.query('SELECT * FROM bills WHERE id = ?', [billId], (err, bills) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (!bills.length) return res.status(404).json({ error: 'Bill not found' });

        const bill = bills[0];

        db.query('SELECT * FROM bill_items WHERE billId = ?', [billId], (err, items) => {
            if (err) return res.status(500).json({ error: 'Database error' });

            res.json({
                ...bill,
                items,
            });
        });
    });
};

//  Add Bill (FINAL, SAFE VERSION)
exports.addBill = async (req, res) => {
    const {
        customerId,
        taxAmount,
        discountAmount,
        paymentStatus,
        notes,
        items = [],
    } = req.body;

    if (!customerId || !items.length) {
        return res.status(400).json({ error: 'Customer and items required' });
    }

    db.beginTransaction(async (err) => {
        if (err) return res.status(500).json({ error: 'Transaction failed' });

        try {
            // 1 Generate bill number
            const billNumber = await getNextBillNumber();

            let subtotal = 0;

            //  Validate stock + calculate subtotal
            for (const item of items) {
                const [product] = await new Promise((resolve, reject) => {
                    db.query(
                        'SELECT stockQuantity, price FROM products WHERE id = ?',
                        [item.productId],
                        (err, res) => (err ? reject(err) : resolve(res))
                    );
                });

                if (!product || product.stockQuantity < item.quantity) {
                    throw new Error(
                        `Out of stock. Available: ${product?.stockQuantity ?? 0}`
                    );
                }

                subtotal += product.price * item.quantity;
            }

            const totalAmount = subtotal + taxAmount - discountAmount;

            //  Insert bill
            const billResult = await new Promise((resolve, reject) => {
                db.query(
                    `INSERT INTO bills
          (billNumber, customerId, subtotal, taxAmount, discountAmount, totalAmount, paymentStatus, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                    [
                        billNumber,
                        customerId,
                        subtotal,
                        taxAmount,
                        discountAmount,
                        totalAmount,
                        paymentStatus,
                        notes,
                    ],
                    (err, res) => (err ? reject(err) : resolve(res))
                );
            });

            const billId = billResult.insertId;

            // Insert bill items + reduce stock
            for (const item of items) {
                await new Promise((resolve, reject) => {
                    db.query(
                        `INSERT INTO bill_items (billId, productId, quantity, unitPrice, totalPrice)
             VALUES (?, ?, ?, ?, ?)`,
                        [
                            billId,
                            item.productId,
                            item.quantity,
                            item.unitPrice,
                            item.totalPrice,
                        ],
                        (err) => (err ? reject(err) : resolve())
                    );
                });

                await new Promise((resolve, reject) => {
                    db.query(
                        `UPDATE products
             SET stockQuantity = stockQuantity - ?
             WHERE id = ?`,
                        [item.quantity, item.productId],
                        (err) => (err ? reject(err) : resolve())
                    );
                });
            }

            db.commit(() => {
                res.status(201).json({
                    message: 'Bill created',
                    billId,
                    billNumber,
                });
            });
        } catch (e) {
            db.rollback(() => {
                res.status(400).json({ error: e.message });
            });
        }
    });
};

// Delete bill and restore stock
exports.deleteBill = (req, res) => {
    const billId = req.params.id;

    db.beginTransaction(async (err) => {
        if (err) return res.status(500).json({ error: 'Transaction failed' });

        try {
            // Fetch bill items
            const items = await new Promise((resolve, reject) => {
                db.query('SELECT productId, quantity FROM bill_items WHERE billId = ?', [billId], (err, rows) => (err ? reject(err) : resolve(rows)));
            });

            // Restore product stock for each item
            for (const it of items) {
                await new Promise((resolve, reject) => {
                    db.query(
                        `UPDATE products SET stockQuantity = stockQuantity + ? WHERE id = ?`,
                        [it.quantity, it.productId],
                        (err) => (err ? reject(err) : resolve())
                    );
                });
            }

            // Delete bill items
            await new Promise((resolve, reject) => {
                db.query('DELETE FROM bill_items WHERE billId = ?', [billId], (err) => (err ? reject(err) : resolve()));
            });

            // Delete bill
            await new Promise((resolve, reject) => {
                db.query('DELETE FROM bills WHERE id = ?', [billId], (err, result) => (err ? reject(err) : resolve(result)));
            });

            db.commit(() => {
                res.json({ message: 'Bill deleted' });
            });
        } catch (e) {
            db.rollback(() => {
                res.status(400).json({ error: e.message });
            });
        }
    });
};
