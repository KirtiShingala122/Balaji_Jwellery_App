# Balaji Imitation Project

This repository contains a full-stack application for managing a business, including inventory, billing, customer management, and analytics. The project is organized into two main parts: a **backend** (Node.js/Express with Firebase integration) and a **frontend** (Flutter app).

## Project Structure

- **backend/**: Node.js Express server with Firebase Admin SDK for authentication and database operations. Handles REST APIs for authentication, billing, categories, customers, products, and dashboard analytics.
  - `controllers/`: Business logic for each API endpoint (auth, bill, category, customer, dashboard, product).
  - `middleware/`: Middleware for verifying Firebase tokens.
  - `routes/`: API route definitions for each resource.
  - `uploads/`: Directory for file uploads (e.g., images).
  - `db.js`, `firebaseAdmin.js`: Database and Firebase initialization.
  - `server.js`: Main server entry point.
  - `test_category_api.js`: Example/test script for category APIs.

- **frontend/**: Flutter application for the admin dashboard and business management UI.
  - `lib/`: Main Dart code for the app, organized by features (models, providers, screens, services, utils, widgets).
  - `assets/`: Icons and images used in the app.
  - `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Platform-specific code and configuration for Flutter.
  - `test/`: Flutter widget and integration tests.

- **db/**: Contains SQL schema for database structure and related files.

## Features

- **Authentication**: Secure login and user management using Firebase.
- **Billing**: Create, manage, and track bills and invoices.
- **Inventory Management**: Manage product categories, products, and stock levels.
- **Customer Management**: Add, update, and view customer details.
- **Dashboard & Analytics**: View business metrics and analytics.
- **File Uploads**: Upload and manage images/files for products and categories.

## Getting Started

### Backend
1. Navigate to the `backend/` folder.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Set up Firebase Admin credentials (`balaji-imitation-firebase-adminsdk-fbsvc-09bd2e0cec.json`).
4. Start the server:
   ```bash
   node server.js
   ```

### Frontend
1. Navigate to the `frontend/` folder.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
This project is licensed. See the LICENSE file for details (if available).
