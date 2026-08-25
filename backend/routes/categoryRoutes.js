const express = require('express');
const router = express.Router();
const {
    getAllCategories,
    getCategoryById,
    addCategory,
    updateCategory,
    deleteCategory,
    upload
} = require('../controllers/categoryController');

router.get('/', getAllCategories);
router.get('/:id', getCategoryById);
router.post('/', upload.single('image'), addCategory);
router.put('/:id', upload.single('image'), updateCategory);
router.delete('/:id', deleteCategory);

module.exports = router;
