const db = require('../db');

exports.getSummary = (req, res) => {
    // Returns total customers, total sales and total profit (using 30% margin)
    const sql = `
      SELECT
        (SELECT COUNT(*) FROM customers) AS totalCustomers,
        (SELECT IFNULL(SUM(totalAmount),0) FROM bills) AS totalSales
    `;

    db.query(sql, (err, rows) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        const row = rows[0];
        const totalSales = parseFloat(row.totalSales) || 0;
        const totalProfit = totalSales * 0.3; // keep same assumption as frontend
        res.json({
            totalCustomers: row.totalCustomers || 0,
            totalSales: totalSales,
            totalProfit: totalProfit,
        });
    });
};
