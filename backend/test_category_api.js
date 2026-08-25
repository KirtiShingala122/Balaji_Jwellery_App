// Test script to verify category API endpoints
// Run with: node test_category_api.js

const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api/categories';

console.log(' Testing Category API...\n');

// Test 1: Get all categories
async function testGetCategories() {
    console.log(' Test 1: GET all categories');
    try {
        const response = await axios.get(BASE_URL);
        console.log(' Status:', response.status);
        console.log(' Categories count:', response.data.length);
        console.log(' Data:', JSON.stringify(response.data, null, 2));
        return true;
    } catch (error) {
        console.error(' Error:', error.message);
        if (error.response) {
            console.error(' Response:', error.response.data);
        }
        return false;
    }
}

// Test 2: Add category without image
async function testAddCategoryNoImage() {
    console.log('\n Test 2: POST category without image');
    try {
        const response = await axios.post(BASE_URL, {
            name: 'Test Category ' + Date.now(),
            description: 'This is a test category without image'
        }, {
            headers: { 'Content-Type': 'application/json' }
        });
        console.log(' Status:', response.status);
        console.log(' Response:', response.data);
        return response.data.id;
    } catch (error) {
        console.error(' Error:', error.message);
        if (error.response) {
            console.error(' Response:', error.response.data);
        }
        return null;
    }
}

// Test 3: Add category with image
async function testAddCategoryWithImage() {
    console.log('\n Test 3: POST category with image');
    
    // Create a simple test image file
    const testImagePath = path.join(__dirname, 'test_image.jpg');
    
    // Check if test image exists, if not create a placeholder
    if (!fs.existsSync(testImagePath)) {
        console.log('ℹ  No test image found. Please create test_image.jpg in backend folder');
        console.log('   Or place any .jpg file and update the path');
        return null;
    }

    try {
        const form = new FormData();
        form.append('name', 'Test Category with Image ' + Date.now());
        form.append('description', 'This category has an image');
        form.append('image', fs.createReadStream(testImagePath));

        const response = await axios.post(BASE_URL, form, {
            headers: {
                ...form.getHeaders()
            }
        });
        console.log(' Status:', response.status);
        console.log(' Response:', response.data);
        return response.data.id;
    } catch (error) {
        console.error(' Error:', error.message);
        if (error.response) {
            console.error(' Response:', error.response.data);
        }
        return null;
    }
}

// Test 4: Database structure
async function testDatabaseStructure() {
    console.log('\n  Test 4: Check database structure');
    try {
        const db = require('./db');
        db.query('DESCRIBE categories', (err, results) => {
            if (err) {
                console.error(' Database error:', err);
                return;
            }
            console.log(' Categories table structure:');
            console.table(results);
        });
    } catch (error) {
        console.error(' Error checking database:', error.message);
    }
}

// Run all tests
async function runTests() {
    console.log('═══════════════════════════════════════════════\n');
    
    await testDatabaseStructure();
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const getSuccess = await testGetCategories();
    
    if (getSuccess) {
        await testAddCategoryNoImage();
        await testAddCategoryWithImage();
    }
    
    console.log('\n═══════════════════════════════════════════════');
    console.log(' Tests completed!');
    console.log('\n Tips:');
    console.log('   - If GET fails, check database connection');
    console.log('   - If POST fails, check multer configuration');
    console.log('   - Check uploads folder exists');
    console.log('   - Verify CORS is enabled');
    
    process.exit(0);
}

runTests();
