const mysql = require('mysql2');

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',        // replace with your MySQL username
    password: '',        // add password if you have one
    database: 'balaji_imitation', // your database name
});

db.connect((err) => {
    if (err) {
        console.error(' DB connection failed:', err);
    } else {
        console.log(' Connected to MySQL Database');
    }
});

module.exports = db;
