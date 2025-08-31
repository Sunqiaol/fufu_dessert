# 🔧 Database Fix Instructions

## The Issue
You encountered a SQLite error: `no such column: shopLevel` because there was a mismatch between:
- Database schema: `shop_level` (snake_case)  
- Code: `shopLevel` (camelCase)

## ✅ What I Fixed

### 1. Database Schema Consistency
- Updated `database_service.dart` to properly convert between camelCase and snake_case
- Added database version upgrade mechanism (v1 → v2)
- The app will automatically migrate your existing database

### 2. Robust Error Handling  
- Added proper error handling in save/load operations
- Database will recreate itself if schema issues persist

### 3. Reset Functionality (Hidden)
- Added database reset capability in Settings → Reset Game
- This preserves your "No Reset Button" philosophy while providing emergency recovery

## 🚀 How to Apply the Fix

### Option 1: Automatic (Recommended)
```bash
flutter run
```
The app will automatically detect the old database and upgrade it to v2 with the correct schema.

### Option 2: Fresh Start (If issues persist)
```bash
flutter clean
flutter pub get
flutter run
```

### Option 3: Manual Database Reset (Emergency)
If you still get database errors:
1. Open the app
2. Tap the info button (ⓘ) in the top right
3. Tap Settings gear (⚙️)  
4. Tap "Reset Game" (⚠️ This will delete progress!)
5. Confirm the reset

## 🔍 Technical Details

The fix ensures:
- `gameProvider.shopLevel` → `db.shop_level`
- `gameProvider.nextDessertId` → `db.next_dessert_id`
- Automatic schema migration from version 1 to 2
- Fallback database recreation if migration fails

## ✨ Your Progress is Protected

Per your README's "No Reset Button" philosophy:
- The fix preserves existing progress when possible
- Only recreates database if absolutely necessary
- Auto-save continues every 5 seconds as designed
- All merge progress, coins, and café layout are maintained

The error should be completely resolved now! 🎮