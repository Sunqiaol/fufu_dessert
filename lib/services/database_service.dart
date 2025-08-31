import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:fufu_dessert2/models/dessert.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  Database? _database;
  
  // Add method to properly close database when app terminates
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Database connection closed');
    }
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'fufu_dessert.db');

    return await openDatabase(
      path,
      version: 3, // Increment version to trigger upgrade for storage column
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Game state table
    await db.execute('''
      CREATE TABLE game_state (
        id INTEGER PRIMARY KEY,
        coins INTEGER NOT NULL,
        score INTEGER NOT NULL,
        shop_level INTEGER NOT NULL,
        next_dessert_id INTEGER NOT NULL,
        storage TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Dessert grid table
    await db.execute('''
      CREATE TABLE dessert_grid (
        id INTEGER PRIMARY KEY,
        grid_x INTEGER NOT NULL,
        grid_y INTEGER NOT NULL,
        dessert_level INTEGER NOT NULL,
        dessert_id INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Cafe state table
    await db.execute('''
      CREATE TABLE cafe_state (
        id INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert initial game state
    await db.insert('game_state', {
      'id': 1,
      'coins': 100,
      'score': 0,
      'shop_level': 1,
      'next_dessert_id': 1,
      'storage': '{"items":{},"desserts":{}}',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 3) {
      // Handle upgrade to version 3 - Add storage column
      try {
        // First, let's check if storage column exists
        final columns = await db.rawQuery('PRAGMA table_info(game_state)');
        final hasStorageColumn = columns.any((col) => col['name'] == 'storage');
        
        if (!hasStorageColumn) {
          // Add storage column with default empty storage
          await db.execute('ALTER TABLE game_state ADD COLUMN storage TEXT DEFAULT \'{"items":{},"desserts":{}}\'');
          print('Added storage column to game_state table');
          
          // Update existing row to have proper storage
          await db.execute('UPDATE game_state SET storage = \'{"items":{},"desserts":{}}\' WHERE storage IS NULL');
          print('Initialized storage for existing game state');
        }
      } catch (e) {
        print('Error during ALTER TABLE upgrade: $e');
        // If ALTER TABLE fails, we need to recreate but preserve data
        try {
          print('Attempting to preserve data during database recreation...');
          
          // Save existing data
          final existingGameState = await db.query('game_state', limit: 1);
          final existingGrid = await db.query('dessert_grid');
          final existingCafe = await db.query('cafe_state', limit: 1);
          
          // Drop and recreate tables
          await db.execute('DROP TABLE IF EXISTS game_state');
          await db.execute('DROP TABLE IF EXISTS dessert_grid');
          await db.execute('DROP TABLE IF EXISTS cafe_state');
          
          // Recreate tables with correct schema
          await _onCreate(db, newVersion);
          
          // Restore data
          if (existingGameState.isNotEmpty) {
            final oldState = existingGameState.first;
            await db.insert('game_state', {
              'id': 1,
              'coins': oldState['coins'],
              'score': oldState['score'],
              'shop_level': oldState['shop_level'],
              'next_dessert_id': oldState['next_dessert_id'],
              'storage': '{"items":{},"desserts":{}}', // Empty storage for now
              'created_at': oldState['created_at'],
              'updated_at': DateTime.now().toIso8601String(),
            });
            print('Restored game state data');
          }
          
          // Restore grid data
          for (final gridItem in existingGrid) {
            await db.insert('dessert_grid', gridItem);
          }
          if (existingGrid.isNotEmpty) {
            print('Restored ${existingGrid.length} grid items');
          }
          
          // Restore cafe data if exists
          if (existingCafe.isNotEmpty) {
            await db.insert('cafe_state', existingCafe.first);
            print('Restored cafe state data');
          }
          
          print('Database recreation with data preservation completed');
        } catch (recreateError) {
          print('Error recreating database: $recreateError');
          // Last resort: just create clean database
          await _onCreate(db, newVersion);
        }
      }
    }
  }

  Future<void> saveGameState(Map<String, dynamic> gameState) async {
    final db = await database;
    
    // Convert camelCase to snake_case for database
    final dbGameState = <String, dynamic>{
      'coins': gameState['coins'],
      'score': gameState['score'],
      'shop_level': gameState['shopLevel'], // Convert camelCase to snake_case
      'next_dessert_id': gameState['nextDessertId'], // Convert camelCase to snake_case
      'storage': gameState['storage'] != null ? 
          jsonEncode(gameState['storage']) : '{"items":{},"desserts":{}}',
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await db.update(
      'game_state',
      dbGameState,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>?> loadGameState() async {
    final db = await database;
    
    final result = await db.query(
      'game_state',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty) {
      final row = result.first;
      Map<String, dynamic> storage = {};
      
      // Parse storage JSON if it exists
      if (row['storage'] != null) {
        try {
          final decoded = jsonDecode(row['storage'] as String);
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          if (decoded is Map) {
            storage = Map<String, dynamic>.from(decoded);
          } else {
            storage = {"items": {}, "desserts": {}};
          }
        } catch (e) {
          print('Error parsing storage JSON: $e');
          storage = {"items": {}, "desserts": {}};
        }
      } else {
        storage = {"items": {}, "desserts": {}};
      }
      
      return {
        'coins': row['coins'] as int,
        'score': row['score'] as int,
        'shopLevel': row['shop_level'] as int,
        'nextDessertId': row['next_dessert_id'] as int,
        'storage': storage,
      };
    }

    return null;
  }

  Future<void> saveDessertGrid(List<List<GridDessert?>> grid) async {
    final db = await database;
    
    // Clear existing grid
    await db.delete('dessert_grid');
    
    // Save current grid
    for (int y = 0; y < grid.length; y++) {
      for (int x = 0; x < grid[y].length; x++) {
        final dessert = grid[y][x];
        if (dessert != null) {
          await db.insert('dessert_grid', {
            'grid_x': x,
            'grid_y': y,
            'dessert_level': dessert.dessert.level,
            'dessert_id': dessert.id,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }
  }

  Future<List<List<GridDessert?>>?> loadDessertGrid() async {
    final db = await database;
    
    final result = await db.query('dessert_grid');
    
    if (result.isEmpty) return null;
    
    // Initialize empty grid with current dimensions
    final List<List<GridDessert?>> grid = List.generate(
      10, // gridHeight - updated to 10
      (_) => List<GridDessert?>.generate(7, (_) => null), // gridWidth - updated to 7
    );
    
    // Fill grid with saved desserts (with bounds checking)
    for (final row in result) {
      final x = row['grid_x'] as int;
      final y = row['grid_y'] as int;
      final level = row['dessert_level'] as int;
      final id = row['dessert_id'] as int;
      
      // Skip items that are outside the new grid bounds
      if (x >= 0 && x < 7 && y >= 0 && y < 10) {
        grid[y][x] = GridDessert(
          id: id,
          dessert: Dessert.getDessertByLevel(level),
          gridX: x,
          gridY: y,
        );
      } else {
        print('Skipping dessert at invalid position ($x, $y) - outside new grid bounds (7x10)');
      }
    }
    
    return grid;
  }

  Future<void> saveCafeState(Map<String, dynamic> cafeState) async {
    final db = await database;
    
    final existingState = await db.query('cafe_state', where: 'id = ?', whereArgs: [1]);
    
    if (existingState.isNotEmpty) {
      await db.update(
        'cafe_state',
        {
          'data': jsonEncode(cafeState),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    } else {
      await db.insert('cafe_state', {
        'id': 1,
        'data': jsonEncode(cafeState),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<Map<String, dynamic>?> loadCafeState() async {
    final db = await database;
    
    final result = await db.query(
      'cafe_state',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty) {
      final dataString = result.first['data'] as String;
      return jsonDecode(dataString) as Map<String, dynamic>;
    }

    return null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    
    // Clear all tables completely
    await db.delete('game_state');
    await db.delete('dessert_grid');
    await db.delete('cafe_state');
    
    // Reset to initial state with fresh values
    await db.insert('game_state', {
      'id': 1,
      'coins': 100,
      'score': 0,
      'shop_level': 1,
      'next_dessert_id': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Method to completely reset database (for debugging/development)
  Future<void> resetDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'fufu_dessert.db');
    
    await deleteDatabase(path);
    _database = null; // Force recreation on next access
  }
}