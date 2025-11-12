const express = require("express");
const router = express.Router();
const db = require("../db");

//  Dashboard route — get total counts and total sales
router.get("/", (req, res) => {
    const queries = {
        totalCategories: "SELECT COUNT(*) AS count FROM categories",
        totalProducts: "SELECT COUNT(*) AS count FROM products",
        totalCustomers: "SELECT COUNT(*) AS count FROM customers",
        totalSales: "SELECT IFNULL(SUM(totalAmount), 0) AS total FROM bills",
    };

    let results = {};
    let completed = 0;
    const totalQueries = Object.keys(queries).length;

    Object.entries(queries).forEach(([key, query]) => {
        db.query(query, (err, rows) => {
            if (err) {
                console.error(`Error fetching ${key}:`, err);
                return res.status(500).json({ error: `Database error in ${key}` });
            }

            results[key] = rows[0].count || rows[0].total || 0;
            completed++;

            if (completed === totalQueries) {
                res.json(results);
            }
        });
    });
});

module.exports = router;
