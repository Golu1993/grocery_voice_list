import 'constants.dart';

class UnitConverter {
  static String formatQuantity(double quantity, String unit) {
    final qStr = _formatNumber(quantity);
    final unitDisplay = kUnitDisplay[unit] ?? unit;

    if (unit == 'piece') {
      if (quantity == 1) return '1 pc';
      return '$qStr pcs';
    }
    return '$qStr $unitDisplay';
  }

  static String _formatNumber(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    // Show at most 2 decimal places, trimming trailing zeros
    final s = value.toStringAsFixed(2);
    return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  // Convert to base unit for comparison: g for weight, ml for volume
  static double toBaseUnit(double quantity, String unit) {
    switch (unit) {
      case 'kg':
        return quantity * 1000;
      case 'g':
        return quantity;
      case 'l':
        return quantity * 1000;
      case 'ml':
        return quantity;
      default:
        return quantity;
    }
  }

  static bool isSameUnitFamily(String unit1, String unit2) {
    const weightUnits = {'kg', 'g'};
    const volumeUnits = {'l', 'ml'};
    if (weightUnits.contains(unit1) && weightUnits.contains(unit2)) return true;
    if (volumeUnits.contains(unit1) && volumeUnits.contains(unit2)) return true;
    return unit1 == unit2;
  }

  // Merge quantities: add secondQty (in secondUnit) to firstQty (in firstUnit)
  // Returns merged quantity in firstUnit, or null if units are incompatible
  static double? mergeQuantities(
    double firstQty, String firstUnit,
    double secondQty, String secondUnit,
  ) {
    if (firstUnit == secondUnit) return firstQty + secondQty;
    if (!isSameUnitFamily(firstUnit, secondUnit)) return null;

    final base1 = toBaseUnit(firstQty, firstUnit);
    final base2 = toBaseUnit(secondQty, secondUnit);
    final merged = base1 + base2;

    // Convert back to firstUnit
    switch (firstUnit) {
      case 'kg':
        return merged / 1000;
      case 'g':
        return merged;
      case 'l':
        return merged / 1000;
      case 'ml':
        return merged;
      default:
        return firstQty + secondQty;
    }
  }
}
