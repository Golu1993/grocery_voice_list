import 'package:flutter/material.dart';

const String kGroceryBox = 'grocery_items';
const String kOrderBox = 'grocery_orders';

enum GroceryCategory {
  all,
  vegetables,
  fruits,
  dairy,
  meatAndEggs,
  bakery,
  beverages,
  snacks,
  cleaning,
  personalCare,
  other,
}

extension GroceryCategoryExt on GroceryCategory {
  String get displayName {
    switch (this) {
      case GroceryCategory.all:
        return 'All';
      case GroceryCategory.vegetables:
        return 'Vegetables';
      case GroceryCategory.fruits:
        return 'Fruits';
      case GroceryCategory.dairy:
        return 'Dairy';
      case GroceryCategory.meatAndEggs:
        return 'Meat & Eggs';
      case GroceryCategory.bakery:
        return 'Bakery';
      case GroceryCategory.beverages:
        return 'Beverages';
      case GroceryCategory.snacks:
        return 'Snacks';
      case GroceryCategory.cleaning:
        return 'Cleaning';
      case GroceryCategory.personalCare:
        return 'Personal Care';
      case GroceryCategory.other:
        return 'Other';
    }
  }

  String get storageKey {
    switch (this) {
      case GroceryCategory.all:
        return 'all';
      case GroceryCategory.vegetables:
        return 'vegetables';
      case GroceryCategory.fruits:
        return 'fruits';
      case GroceryCategory.dairy:
        return 'dairy';
      case GroceryCategory.meatAndEggs:
        return 'meat_eggs';
      case GroceryCategory.bakery:
        return 'bakery';
      case GroceryCategory.beverages:
        return 'beverages';
      case GroceryCategory.snacks:
        return 'snacks';
      case GroceryCategory.cleaning:
        return 'cleaning';
      case GroceryCategory.personalCare:
        return 'personal_care';
      case GroceryCategory.other:
        return 'other';
    }
  }

  Color get color {
    switch (this) {
      case GroceryCategory.all:
        return Colors.blueGrey;
      case GroceryCategory.vegetables:
        return const Color(0xFF43A047);
      case GroceryCategory.fruits:
        return const Color(0xFFFB8C00);
      case GroceryCategory.dairy:
        return const Color(0xFF1E88E5);
      case GroceryCategory.meatAndEggs:
        return const Color(0xFFE53935);
      case GroceryCategory.bakery:
        return const Color(0xFF8D6E63);
      case GroceryCategory.beverages:
        return const Color(0xFF00ACC1);
      case GroceryCategory.snacks:
        return const Color(0xFF8E24AA);
      case GroceryCategory.cleaning:
        return const Color(0xFF00897B);
      case GroceryCategory.personalCare:
        return const Color(0xFFEC407A);
      case GroceryCategory.other:
        return const Color(0xFF78909C);
    }
  }

  IconData get icon {
    switch (this) {
      case GroceryCategory.all:
        return Icons.list_alt_rounded;
      case GroceryCategory.vegetables:
        return Icons.eco_rounded;
      case GroceryCategory.fruits:
        return Icons.apple_rounded;
      case GroceryCategory.dairy:
        return Icons.water_drop_rounded;
      case GroceryCategory.meatAndEggs:
        return Icons.egg_alt_rounded;
      case GroceryCategory.bakery:
        return Icons.bakery_dining_rounded;
      case GroceryCategory.beverages:
        return Icons.local_drink_rounded;
      case GroceryCategory.snacks:
        return Icons.cookie_rounded;
      case GroceryCategory.cleaning:
        return Icons.clean_hands_rounded;
      case GroceryCategory.personalCare:
        return Icons.spa_rounded;
      case GroceryCategory.other:
        return Icons.category_rounded;
    }
  }

  static GroceryCategory fromStorageKey(String key) {
    return GroceryCategory.values.firstWhere(
      (c) => c.storageKey == key,
      orElse: () => GroceryCategory.other,
    );
  }
}

const List<String> kUnits = [
  'piece',
  'kg',
  'g',
  'l',
  'ml',
  'packet',
  'dozen',
  'bottle',
  'can',
  'bundle',
];

const Map<String, String> kUnitDisplay = {
  'piece': 'pc',
  'kg': 'kg',
  'g': 'g',
  'l': 'L',
  'ml': 'ml',
  'packet': 'pkt',
  'dozen': 'doz',
  'bottle': 'btl',
  'can': 'can',
  'bundle': 'bdl',
};
