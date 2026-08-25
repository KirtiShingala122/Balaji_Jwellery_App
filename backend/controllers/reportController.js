const db = require('../db');

function queryAsync(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.query(sql, params, (err, results) => {
            if (err) reject(err);
            else resolve(results);
        });
    });
}

// GET /api/reports/monthly-sales
// Returns total sales grouped by month for current year
exports.getMonthlySales = async (req, res) => {
    try {
        const results = await queryAsync(`
            SELECT
                MONTH(createdAt) AS month,
                MONTHNAME(createdAt) AS monthName,
                COALESCE(SUM(totalAmount), 0) AS revenue,
                COUNT(*) AS billCount
            FROM bills
            WHERE YEAR(createdAt) = YEAR(NOW())
            GROUP BY MONTH(createdAt), MONTHNAME(createdAt)
            ORDER BY month ASC
        `);
        res.json(results);
    } catch (err) {
        console.error('Monthly sales error:', err);
        res.status(500).json({ error: 'Failed to fetch monthly sales' });
    }
};

// GET /api/reports/top-products
// Returns top 5 selling products by quantity sold
exports.getTopProducts = async (req, res) => {
    try {
        const results = await queryAsync(`
            SELECT
                p.name,
                p.uniqueCode,
                c.name AS categoryName,
                COALESCE(SUM(bi.quantity), 0) AS totalSold,
                COALESCE(SUM(bi.quantity * bi.unitPrice), 0) AS totalRevenue
            FROM products p
            LEFT JOIN bill_items bi ON p.id = bi.productId
            LEFT JOIN categories c ON p.categoryId = c.id
            GROUP BY p.id, p.name, p.uniqueCode, c.name
            ORDER BY totalSold DESC
            LIMIT 5
        `);
        res.json(results);
    } catch (err) {
        console.error('Top products error:', err);
        res.status(500).json({ error: 'Failed to fetch top products' });
    }
};

// GET /api/reports/category-breakdown
// Returns revenue per category
exports.getCategoryBreakdown = async (req, res) => {
    try {
        const results = await queryAsync(`
            SELECT
                c.name AS categoryName,
                COUNT(DISTINCT p.id) AS productCount,
                COALESCE(SUM(bi.quantity), 0) AS totalSold,
                COALESCE(SUM(bi.quantity * bi.unitPrice), 0) AS totalRevenue
            FROM categories c
            LEFT JOIN products p ON c.id = p.categoryId
            LEFT JOIN bill_items bi ON p.id = bi.productId
            GROUP BY c.id, c.name
            ORDER BY totalRevenue DESC
        `);
        res.json(results);
    } catch (err) {
        console.error('Category breakdown error:', err);
        res.status(500).json({ error: 'Failed to fetch category breakdown' });
    }
};

// GET /api/reports/summary
// Returns key summary stats for the report header cards
exports.getSummary = async (req, res) => {
    try {
        const [totalRevenue, totalBills, totalProducts, lowStock] = await Promise.all([
            queryAsync(`SELECT COALESCE(SUM(totalAmount), 0) AS total FROM bills WHERE paymentStatus = 'paid'`),
            queryAsync(`SELECT COUNT(*) AS count FROM bills`),
            queryAsync(`SELECT COUNT(*) AS count FROM products`),
            queryAsync(`SELECT COUNT(*) AS count FROM products WHERE stockQuantity < 5`),
        ]);

        res.json({
            totalRevenue: totalRevenue[0]?.total ?? 0,
            totalBills: totalBills[0]?.count ?? 0,
            totalProducts: totalProducts[0]?.count ?? 0,
            lowStockCount: lowStock[0]?.count ?? 0,
            avgBillValue:
                totalBills[0]?.count > 0
                    ? (totalRevenue[0]?.total / totalBills[0]?.count).toFixed(2)
                    : 0,
        });
    } catch (err) {
        console.error('Summary error:', err);
        res.status(500).json({ error: 'Failed to fetch summary' });
    }
};
