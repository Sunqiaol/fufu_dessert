# 🧁 Fufu Dessert - Game Instructions

## How to Run the Game

### Prerequisites
- Flutter SDK installed (3.9.0 or higher)
- Android Studio or VS Code with Flutter plugin
- Android emulator or physical device

### Setup Steps
1. Open terminal in the project directory
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the game
4. Or use `flutter build apk` to build an APK file

## How to Play

### 🍰 Merge Grid (Main Game)
1. **Merge Desserts**: Tap on a dessert that has 2 or more identical neighbors to merge them
2. **Triple Merge System**: You need 3 identical desserts touching each other to merge
3. **Generate Random**: Tap the "Generate" button to add random desserts to empty spaces
4. **Progression**: Merge desserts to create higher-level treats (10 levels total)
5. **Earn Coins**: Each successful merge awards coins based on the dessert level

### 🏪 Café Management
1. **View Customers**: Switch to the "Café" tab to see your 2.5D shop
2. **Zoom & Pan**: Use pinch gestures to zoom, drag to pan around your café
3. **Customer States**: 
   - 🔵 Blue: Entering
   - 🟢 Green: Browsing
   - 🟠 Orange: Ordering (serve them!)
   - 🟡 Yellow: Waiting
   - 🟣 Purple: Eating
   - ⚫ Grey: Leaving
4. **Serve Customers**: Tap ordering customers to serve them desserts
5. **Furniture Shop**: Tap the furniture button to buy and place items

### 👥 Customer System
- New customers spawn every 8 seconds (max 6 at once)
- Each customer has patience - serve them quickly!
- Match their desired dessert level for better tips
- Happy customers give more coins
- Impatient customers (red patience bar) may leave

### 💰 Economy & Progression
- **Coins**: Earn by merging desserts and serving customers
- **Score**: Points accumulate for shop level progression  
- **Shop Level**: Higher levels unlock new features
- **Level Up Bonus**: Get extra coins when reaching new shop levels

### 🛋️ Furniture System
- **Attraction Bonus**: Furniture attracts more customers
- **Upgradeable Items**: Look for yellow "+" icons
- **Drag & Drop**: Move furniture by selecting and dragging
- **Strategic Placement**: Create efficient paths for customers

## Game Features

### ✨ Dessert Evolution Chain
1. 🍪 Cookie (Level 1) - 1 coin
2. 🍩 Donut (Level 2) - 3 coins
3. 🧁 Cupcake (Level 3) - 9 coins
4. 🍦 Ice Cream (Level 4) - 27 coins
5. 🥧 Pie (Level 5) - 81 coins
6. 🎂 Birthday Cake (Level 6) - 243 coins
7. 💒 Wedding Cake (Level 7) - 729 coins
8. 🍫 Chocolate Fountain (Level 8) - 2,187 coins
9. 🏗️ Dessert Tower (Level 9) - 6,561 coins
10. 🌈 Rainbow Cake (Level 10) - 19,683 coins

### 🎯 Tips for Success
- **Merge Strategy**: Plan ahead to create space for new desserts
- **Customer Priority**: Serve ordering customers before they get impatient
- **Furniture Investment**: Better furniture = more customers = more profit
- **Level Management**: Higher dessert levels = exponentially more coins
- **Patience Management**: Keep an eye on customer patience bars

### 🎮 Controls
- **Tap**: Merge desserts, serve customers, select furniture
- **Pinch**: Zoom in/out in café view  
- **Drag**: Pan café view, move selected furniture
- **Swipe**: Switch between Merge and Café tabs

### 🏆 Objectives
- Reach the highest dessert level (Rainbow Cake)
- Maximize your coin earnings
- Keep customers happy
- Build and upgrade your dream café
- Achieve the highest shop level possible

### 💾 Save System
- Game automatically saves every 5 seconds
- All progress is preserved between sessions
- Dessert grid, coins, furniture, and levels are all saved

### 🐛 Known Issues
- Animation system is basic (placeholder for Rive/Flare integration)
- Furniture shop is simplified 
- Sound effects are not yet implemented
- Some UI polish is pending

Enjoy building your dessert empire! 🧁✨