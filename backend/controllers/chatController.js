const db = require('../db');
const http = require('http');

// ─── Ollama Config ──────────────────────────────────────────────────────────
const OLLAMA_HOST = 'localhost';
const OLLAMA_PORT = 11434;
const OLLAMA_MODEL = 'llama3'; // Change to 'mistral' or 'phi3' if preferred

// ─── Helper: query DB as Promise ─────────────────────────────────────────────
function queryAsync(sql, params = []) {
    return new Promise((resolve, reject) => {
        db.query(sql, params, (err, results) => {
            if (err) reject(err);
            else resolve(results);
        });
    });
}

// ─── Step 1: Fetch live context data from MySQL ───────────────────────────────
async function fetchShopContext() {
    try {
        const [
            productsCount,
            lowStockProducts,
            categoriesCount,
            customersCount,
            totalSales,
            recentBills,
            topProducts,
        ] = await Promise.all([
            queryAsync('SELECT COUNT(*) AS count FROM products'),
            queryAsync(
                'SELECT name, uniqueCode, stockQuantity FROM products WHERE stockQuantity < 5 ORDER BY stockQuantity ASC LIMIT 10'
            ),
            queryAsync('SELECT COUNT(*) AS count FROM categories'),
            queryAsync('SELECT COUNT(*) AS count FROM customers'),
            queryAsync(
                'SELECT COALESCE(SUM(totalAmount), 0) AS total FROM bills WHERE paymentStatus = "paid"'
            ),
            queryAsync(
                `SELECT b.billNumber, c.name AS customerName, b.totalAmount, b.paymentStatus, b.createdAt
                 FROM bills b
                 JOIN customers c ON b.customerId = c.id
                 ORDER BY b.id DESC LIMIT 5`
            ),
            queryAsync(
                `SELECT p.name, SUM(bi.quantity) AS totalSold
                 FROM bill_items bi
                 JOIN products p ON bi.productId = p.id
                 GROUP BY p.id ORDER BY totalSold DESC LIMIT 5`
            ),
        ]);

        return {
            totalProducts: productsCount[0]?.count ?? 0,
            totalCategories: categoriesCount[0]?.count ?? 0,
            totalCustomers: customersCount[0]?.count ?? 0,
            totalSalesPaid: totalSales[0]?.total ?? 0,
            lowStockProducts: lowStockProducts,
            recentBills: recentBills,
            topSellingProducts: topProducts,
        };
    } catch (err) {
        console.error('Context fetch error:', err.message);
        // Return empty context if DB fails — AI will still respond gracefully
        return {
            totalProducts: 'unknown',
            totalCategories: 'unknown',
            totalCustomers: 'unknown',
            totalSalesPaid: 'unknown',
            lowStockProducts: [],
            recentBills: [],
            topSellingProducts: [],
        };
    }
}

// ─── Step 2: Build System Prompt with injected context (Prompt Engineering) ──
function buildSystemPrompt(context) {
    return `You are an intelligent AI assistant for "Balaji Imitation Jewellery" shop admin panel.
Your job is to help the shop admin by answering questions about inventory, sales, customers, and business performance.

Here is the CURRENT LIVE DATA from the shop database (as of this moment):

INVENTORY:
- Total products in catalogue: ${context.totalProducts}
- Total product categories: ${context.totalCategories}
- Low stock products (stock < 5 units): ${
        context.lowStockProducts.length === 0
            ? 'None — all products are well stocked!'
            : JSON.stringify(context.lowStockProducts, null, 2)
    }

CUSTOMERS & SALES:
- Total registered customers: ${context.totalCustomers}
- Total revenue collected (paid bills): ₹${context.totalSalesPaid}
- Recent bills: ${
        context.recentBills.length === 0
            ? 'No recent bills'
            : JSON.stringify(context.recentBills, null, 2)
    }

TOP SELLING PRODUCTS:
${
        context.topSellingProducts.length === 0
            ? 'No sales data yet'
            : JSON.stringify(context.topSellingProducts, null, 2)
    }

INSTRUCTIONS:
- Answer ONLY based on the data provided above. Do NOT make up numbers or products.
- If data is unavailable, say "I don't have that information right now."
- Be concise, friendly, and professional.
- Use ₹ for Indian Rupees. Numbers in Indian format where relevant.
- If asked something unrelated to the jewellery shop, politely redirect.`;
}

// ─── Step 3: Call Ollama REST API ────────────────────────────────────────────
function callOllama(systemPrompt, userMessage) {
    return new Promise((resolve, reject) => {
        const requestBody = JSON.stringify({
            model: OLLAMA_MODEL,
            prompt: `${systemPrompt}\n\nAdmin Question: ${userMessage}\n\nAnswer:`,
            stream: false,
        });

        const options = {
            hostname: OLLAMA_HOST,
            port: OLLAMA_PORT,
            path: '/api/generate',
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(requestBody),
            },
        };

        const req = http.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    resolve(parsed.response || 'No response from AI.');
                } catch {
                    reject(new Error('Failed to parse Ollama response'));
                }
            });
        });

        req.on('error', (err) => {
            reject(new Error(`Ollama connection failed: ${err.message}. Make sure Ollama is running (ollama serve).`));
        });

        req.setTimeout(60000, () => {
            req.destroy();
            reject(new Error('Ollama request timed out after 60 seconds.'));
        });

        req.write(requestBody);
        req.end();
    });
}

// ─── Main Controller: POST /api/chat ─────────────────────────────────────────
exports.chat = async (req, res) => {
    const { message } = req.body;

    if (!message || message.trim() === '') {
        return res.status(400).json({ error: 'Message is required.' });
    }

    try {
        // 1. Fetch live shop context from DB
        const context = await fetchShopContext();

        // 2. Build system prompt with injected context (Prompt Engineering)
        const systemPrompt = buildSystemPrompt(context);

        // 3. Call Ollama LLM
        const aiResponse = await callOllama(systemPrompt, message.trim());

        res.json({
            reply: aiResponse,
            context_used: {
                totalProducts: context.totalProducts,
                totalCustomers: context.totalCustomers,
                lowStockCount: context.lowStockProducts.length,
            },
        });
    } catch (err) {
        console.error('Chat error:', err.message);
        res.status(500).json({
            error: err.message || 'AI assistant is unavailable. Please ensure Ollama is running.',
        });
    }
};
