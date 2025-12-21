const express = require('express');
const cors = require('cors');
const path = require('path');

// Initialize express app
const app = express();

//  Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

//  Serve static image files from uploads/
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

//  Import routes
const categoryRoutes = require('./routes/categoryRoutes');
const productRoutes = require('./routes/productRoutes');
const customerRoutes = require('./routes/customerRoutes');
const billRoutes = require('./routes/billRoutes');
const authRoutes = require('./routes/authRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');

//  Use routes
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/products', productRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/dashboard', dashboardRoutes);

//  Start server
const PORT = 3000;
// Listen on all interfaces so your phone (on same Wi-Fi) can access the server
// without changing routes or other logic.
app.listen(PORT, '0.0.0.0', () => {
    console.log(` Server running at http://localhost:${PORT} and on 0.0.0.0:${PORT}`);
});