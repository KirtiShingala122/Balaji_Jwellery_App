# Quick Error Diagnosis Guide

## What to Look For in Console Logs

###  SUCCESSFUL Flow (What you SHOULD see):

#### When Adding Category:
```
Flutter Console:
 Starting category save operation...
 Name: [your category name]
 Description: [your description]
 Image: [number] bytes
 Creating new category...
 Sending category: [name]
 Posting to: http://localhost:3000/api/categories
 Response status: 201
 Response data: {message: Category added, id: X, imageUrl: ...}
 Category added successfully
 Reloading categories...
 Fetching categories from: http://localhost:3000/api/categories
 Response status: 200
 Received X categories
 Parsing category from map: {...}
 Category parsed: [name], imagePath: [path]
 Parsed categories successfully
 Categories loaded: X items
 State updated with X categories

Backend Console:
 Add Category Request: { body: { name: '...', description: '...' }, file: { filename: '...', size: ... } }
 Inserting category: { name: '...', description: '...', imagePath: '/uploads/...' }
 Category added successfully: { id: X, imageUrl: '...' }
 Fetched X categories
```

---

## ERROR Patterns & Solutions

### Error Pattern 1: Blank Screen After Add
**Symptoms:**
```
Flutter Console:
 Error loading categories: [error message]
```

**Possible Causes:**
1. Database connection lost
2. Category parsing error
3. Network error

**Check:**
- Backend console for database errors
- Category model fromMap() logs
- Network tab in browser DevTools

**Solution:**
- Restart backend server
- Check MySQL is running
- Verify database schema

---

### Error Pattern 2: Image Not Uploading
**Symptoms:**
```
Flutter Console:
 Error adding category: [error]
 Dio Error Details: [details]
```

**Possible Causes:**
1. File too large
2. Multer not receiving file
3. CORS issue
4. Backend not processing multipart

**Check:**
```
Backend Console:
 Add Category Request: { body: {...}, file: 'No file' }  THIS IS WRONG
```

**Should be:**
```
 Add Category Request: { body: {...}, file: { filename: '...', size: ... } }   CORRECT
```

**Solution:**
- Check image picker is working (check imageBytes is not null)
- Verify FormData is correctly constructed
- Check multer middleware is on the route

---

### Error Pattern 3: Categories Load But New One Doesn't Appear
**Symptoms:**
- Old categories show
- New category added but not visible
- No error messages

**Check:**
```
Flutter Console:
 Category added successfully
 Reloading categories...
 Received X categories  ← Should be X+1 after add
```

**Possible Causes:**
1. Database insert failed silently
2. Reload happened before database commit
3. Cached response

**Solution:**
- Check backend database logs
- Add delay before reload
- Verify database transaction completed

---

### Error Pattern 4: 500 Server Error
**Symptoms:**
```
Flutter Console:
 Dio Error Details: {error: 'Failed to add category'}
 Status Code: 500
```

**Backend Console:**
```
 Database error: [specific error]
```

**Common Causes:**
1. Missing required field
2. Database constraint violation
3. Duplicate category name

**Solution:**
- Check backend error details
- Verify all required fields sent
- Check database constraints

---

### Error Pattern 5: CORS Error
**Symptoms:**
```
Browser Console:
Access to XMLHttpRequest at 'http://localhost:3000/api/categories' 
from origin 'http://localhost:[port]' has been blocked by CORS policy
```

**Solution:**
Already fixed in server.js:
```javascript
app.use(cors());
```

If still occurs:
- Restart backend server
- Clear browser cache
- Check cors package installed

---

### Error Pattern 6: Image Shows Broken Icon
**Symptoms:**
- Category added successfully
- List reloads
- Image shows broken icon or placeholder

**Check:**
```
Flutter Console:
 Category parsed: [name], imagePath: null   WRONG - should have path
```

**Backend Console:**
```
 Inserting category: { ..., imagePath: null }   WRONG
```

**Possible Causes:**
1. req.file is null (multer not receiving file)
2. File not saved to uploads folder
3. Path not returned from database

**Solution:**
- Verify uploads folder exists
- Check multer storage configuration
- Verify file actually uploaded
- Check response returns imagePath

---

## Testing Checklist

### Before Testing:
- [ ] Backend running: `node server.js`
- [ ] Database connected (see "Connected to MySQL Database" message)
- [ ] Flutter app running: `flutter run -d chrome`
- [ ] Console logs visible in both terminals

### During Testing:
- [ ] Click + button to add category
- [ ] Select image (not skip)
- [ ] Fill name and description
- [ ] Click Add
- [ ] Watch BOTH consoles for logs

### After Testing:
- [ ] Check for any  in logs
- [ ] Verify category appears in list
- [ ] Verify image displays correctly
- [ ] Test edit and delete functions

---

## Quick Diagnostic Commands

### Check if backend is accessible:
```bash
curl http://localhost:3000/api/categories
```

### Check uploads folder:
```bash
ls -la backend/uploads/
```

### Check database categories:
```sql
SELECT id, name, imagePath FROM categories;
```

### Check recent uploads:
```bash
ls -lt backend/uploads/ | head -5
```

---

## Still Having Issues?

### Copy these logs and share:

1. **Full Backend Console Output** (from server start to error)
2. **Full Flutter Console Output** (from add button click to error)
3. **Browser DevTools Console** (any red errors)
4. **Network Tab** (failed request details)

### Include these details:
- Operating System
- Flutter version: `flutter --version`
- Node version: `node --version`
- MySQL version
- Exact steps to reproduce
- Does it work without image?
- Does it work with image?
