

class StorageItem {
  final int dessertLevel;
  final int quantity;
  final DateTime addedAt;

  const StorageItem({
    required this.dessertLevel,
    required this.quantity,
    required this.addedAt,
  });

  StorageItem copyWith({
    int? dessertLevel,
    int? quantity,
    DateTime? addedAt,
  }) {
    return StorageItem(
      dessertLevel: dessertLevel ?? this.dessertLevel,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dessertLevel': dessertLevel,
      'quantity': quantity,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory StorageItem.fromJson(Map<String, dynamic> json) {
    return StorageItem(
      dessertLevel: json['dessertLevel'] as int,
      quantity: json['quantity'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int),
    );
  }
}

class DessertStorageItem {
  final int dessertId;
  final int quantity;
  final DateTime addedAt;

  const DessertStorageItem({
    required this.dessertId,
    required this.quantity,
    required this.addedAt,
  });

  DessertStorageItem copyWith({
    int? dessertId,
    int? quantity,
    DateTime? addedAt,
  }) {
    return DessertStorageItem(
      dessertId: dessertId ?? this.dessertId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dessertId': dessertId,
      'quantity': quantity,
      'addedAt': addedAt.millisecondsSinceEpoch,
    };
  }

  factory DessertStorageItem.fromJson(Map<String, dynamic> json) {
    return DessertStorageItem(
      dessertId: json['dessertId'] as int,
      quantity: json['quantity'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(json['addedAt'] as int),
    );
  }
}

class Storage {
  final Map<int, DessertStorageItem> _desserts = <int, DessertStorageItem>{};
  
  Map<int, DessertStorageItem> get desserts => Map.unmodifiable(_desserts);
  
  // For backward compatibility - return empty items
  Map<int, StorageItem> get items => <int, StorageItem>{};
  
  // Get total number of items in storage (only crafted desserts now)
  int getTotalItems() {
    return _desserts.values.fold(0, (sum, item) => sum + item.quantity);
  }
  
  // Legacy methods for backward compatibility - now do nothing since we only store crafted desserts
  void addDessert(int dessertLevel, {int quantity = 1}) {
    // No longer stores regular desserts - only for backward compatibility
  }
  
  bool removeDessert(int dessertLevel, {int quantity = 1}) {
    // No longer stores regular desserts - only for backward compatibility
    return false;
  }
  
  bool hasEnough(int dessertLevel, {int quantity = 1}) {
    // No longer stores regular desserts - only for backward compatibility
    return false;
  }
  
  int getQuantity(int dessertLevel) {
    // No longer stores regular desserts - only for backward compatibility
    return 0;
  }
  
  List<int> getAvailableLevels() {
    // No longer stores regular desserts - only for backward compatibility
    return [];
  }
  
  // Add crafted dessert to storage
  void addCraftedDessert(int dessertId, {int quantity = 1}) {
    if (_desserts.containsKey(dessertId)) {
      final existing = _desserts[dessertId]!;
      _desserts[dessertId] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _desserts[dessertId] = DessertStorageItem(
        dessertId: dessertId,
        quantity: quantity,
        addedAt: DateTime.now(),
      );
    }
  }

  // Remove crafted dessert from storage
  bool removeCraftedDessert(int dessertId, {int quantity = 1}) {
    if (!_desserts.containsKey(dessertId)) {
      return false;
    }

    final existing = _desserts[dessertId]!;
    if (existing.quantity < quantity) {
      return false;
    }

    if (existing.quantity == quantity) {
      _desserts.remove(dessertId);
    } else {
      _desserts[dessertId] = existing.copyWith(
        quantity: existing.quantity - quantity,
      );
    }

    return true;
  }

  // Get quantity of specific dessert
  int getDessertQuantity(int dessertId) {
    return _desserts[dessertId]?.quantity ?? 0;
  }

  // Get all available dessert IDs
  List<int> getAvailableDessertIds() {
    return _desserts.keys.toList()..sort();
  }
  
  // Check if storage has a specific crafted dessert (for auto-feeding)
  bool hasCraftedDessert(int dessertId) {
    return _desserts.containsKey(dessertId) && _desserts[dessertId]!.quantity > 0;
  }

  // Clear all storage
  void clear() {
    _desserts.clear();
  }
  
  // Convert to JSON for database
  Map<String, dynamic> toJson() {
    return {
      'desserts': _desserts.map((key, value) => MapEntry(key.toString(), value.toJson())),
    };
  }
  
  // Default constructor
  Storage();
  
  // Create from JSON
  factory Storage.fromJson(Map<String, dynamic> json) {
    final storage = Storage();
    final dessertsJson = json['desserts'] as Map<String, dynamic>? ?? {};
    
    for (final entry in dessertsJson.entries) {
      final dessertId = int.parse(entry.key);
      final dessert = DessertStorageItem.fromJson(entry.value as Map<String, dynamic>);
      storage._desserts[dessertId] = dessert;
    }
    
    return storage;
  }
}