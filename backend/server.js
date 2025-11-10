const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const categoryRoutes = require('./routes/categoryRoutes');
const productRoutes = require('./routes/productRoutes');
const customerRoutes = require('./routes/customerRoutes');
const billRoutes = require('./routes/billRoutes');
const authRoutes = require('./routes/authRoutes');

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/products', productRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/bills', billRoutes);


const PORT = 3000;
app.listen(PORT, () => console.log(`Server running at http://localhost:${PORT}`));
//app.listen(3000, '0.0.0.0', () => {console.log(` Server running on http://0.0.0.0:${PORT}`);});