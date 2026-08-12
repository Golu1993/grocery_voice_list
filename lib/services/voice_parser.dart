import '../utils/constants.dart';

enum CommandAction {
  add,
  addMore,
  remove,
  subtractQuantity,
  setQuantity,
  check,
  uncheck,
  clear,
  undo,
  unknown,
}

class ParsedCommand {
  final CommandAction action;
  final String? itemName;
  final double? quantity;
  final String? unit;
  final String? categoryKey;
  final String rawText;

  const ParsedCommand({
    required this.action,
    this.itemName,
    this.quantity,
    this.unit,
    this.categoryKey,
    required this.rawText,
  });

  bool get isValid => action != CommandAction.unknown && itemName != null;

  @override
  String toString() =>
      'ParsedCommand(action:$action, item:$itemName, qty:$quantity, unit:$unit)';
}

class VoiceParser {
  // ── Action keywords ──────────────────────────────────────────────────────
  static const Map<String, CommandAction> _addKeywords = {
    'add': CommandAction.add,
    'get': CommandAction.add,
    'buy': CommandAction.add,
    'need': CommandAction.add,
    'want': CommandAction.add,
    'include': CommandAction.add,
    'put': CommandAction.add,
    'pick': CommandAction.add,
    'grab': CommandAction.add,
    'fetch': CommandAction.add,
    'require': CommandAction.add,
    // Hindi romanized
    'jodo': CommandAction.add,
    'jod': CommandAction.add,
    'daalo': CommandAction.add,
    'daal': CommandAction.add,
    'lao': CommandAction.add,
    'lana': CommandAction.add,
    'chahiye': CommandAction.add,
    'mangao': CommandAction.add,
    'kharido': CommandAction.add,
    'dena': CommandAction.add,
    'dedo': CommandAction.add,
  };

  static const Map<String, CommandAction> _removeKeywords = {
    'remove': CommandAction.remove,
    'delete': CommandAction.remove,
    'cancel': CommandAction.remove,
    'drop': CommandAction.remove,
    'skip': CommandAction.remove,
    // Hindi romanized
    'hatao': CommandAction.remove,
    'hata': CommandAction.remove,
    'nikalo': CommandAction.remove,
    'nikal': CommandAction.remove,
    'hato': CommandAction.remove,
    'mat': CommandAction.remove,
  };

  static const Map<String, CommandAction> _subtractKeywords = {
    'reduce': CommandAction.subtractQuantity,
    'decrease': CommandAction.subtractQuantity,
    'less': CommandAction.subtractQuantity,
    'subtract': CommandAction.subtractQuantity,
    'minus': CommandAction.subtractQuantity,
    'lower': CommandAction.subtractQuantity,
    'cut': CommandAction.subtractQuantity,
    // Hindi romanized
    'ghatao': CommandAction.subtractQuantity,
    'ghata': CommandAction.subtractQuantity,
    'kam': CommandAction.subtractQuantity,
    'kum': CommandAction.subtractQuantity,
  };

  static const Map<String, CommandAction> _updateKeywords = {
    'increase': CommandAction.setQuantity,
    'update': CommandAction.setQuantity,
    'change': CommandAction.setQuantity,
    'set': CommandAction.setQuantity,
    'make': CommandAction.setQuantity,
  };

  static const Map<String, CommandAction> _checkKeywords = {
    'check': CommandAction.check,
    'tick': CommandAction.check,
    'done': CommandAction.check,
    'got': CommandAction.check,
    'bought': CommandAction.check,
    'purchased': CommandAction.check,
    'complete': CommandAction.check,
    // Hindi romanized
    'mila': CommandAction.check,
    'milgaya': CommandAction.check,
    'khareedliya': CommandAction.check,
    'hogaya': CommandAction.check,
  };

  // ── Number words ─────────────────────────────────────────────────────────
  static const Map<String, double> _numberWords = {
    'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4,
    'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9,
    'ten': 10, 'eleven': 11, 'twelve': 12, 'thirteen': 13,
    'fourteen': 14, 'fifteen': 15, 'sixteen': 16, 'seventeen': 17,
    'eighteen': 18, 'nineteen': 19, 'twenty': 20, 'thirty': 30,
    'forty': 40, 'fifty': 50, 'hundred': 100, 'half': 0.5,
    'quarter': 0.25,
    // Hindi romanized
    'ek': 1, 'teen': 3, 'char': 4, 'paanch': 5,
    'chhe': 6, 'chhai': 6, 'saat': 7, 'aath': 8, 'nau': 9,
    'das': 10, 'gyara': 11, 'baara': 12, 'adha': 0.5, 'aadha': 0.5,
  };

  // ── Unit keywords ─────────────────────────────────────────────────────────
  static const Map<String, String> _unitKeywords = {
    'kg': 'kg',
    'kilo': 'kg',
    'kilos': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'kgs': 'kg',
    'g': 'g', 'gram': 'g', 'grams': 'g', 'gm': 'g', 'gms': 'g', 'grm': 'g',
    'l': 'l',
    'litre': 'l',
    'litres': 'l',
    'liter': 'l',
    'liters': 'l',
    'lt': 'l',
    'ml': 'ml', 'millilitre': 'ml', 'millilitres': 'ml', 'milliliter': 'ml',
    'milliliters': 'ml',
    'piece': 'piece', 'pieces': 'piece', 'pc': 'piece', 'pcs': 'piece',
    'nos': 'piece', 'number': 'piece', 'count': 'piece', 'item': 'piece',
    'packet': 'packet',
    'packets': 'packet',
    'pack': 'packet',
    'packs': 'packet',
    'sachet': 'packet',
    'sachets': 'packet',
    'pouch': 'packet',
    'pouches': 'packet',
    'dozen': 'dozen', 'doz': 'dozen',
    'bundle': 'bundle',
    'bundles': 'bundle',
    'bunch': 'bundle',
    'bunches': 'bundle',
    'bottle': 'bottle', 'bottles': 'bottle',
    'can': 'can', 'cans': 'can', 'tin': 'can', 'tins': 'can',
    // Hindi romanized
    'kile': 'kg', 'kila': 'kg',
    'graam': 'g',
    'peket': 'packet', 'paket': 'packet', 'theli': 'packet',
    'botal': 'bottle', 'bottal': 'bottle',
    'dib': 'can', 'dibba': 'can',
  };

  // ── Hindi → English item translations ────────────────────────────────────
  static const Map<String, String> _hindiToEnglish = {
    // Vegetables
    'aloo': 'potato', 'aaloo': 'potato', 'alu': 'potato', 'aalu': 'potato',
    'pyaz': 'onion', 'pyaaz': 'onion', 'kanda': 'onion', 'dungri': 'onion',
    'tamatar': 'tomato', 'tamaatar': 'tomato',
    'lahsun': 'garlic', 'lahasun': 'garlic', 'lasan': 'garlic',
    'adrak': 'ginger', 'aadrak': 'ginger',
    'gajar': 'carrot',
    'palak': 'spinach',
    'matar': 'peas', 'mutter': 'peas', 'matar dana': 'peas',
    'bhindi': 'okra', 'bhende': 'okra',
    'baingan': 'brinjal', 'bengan': 'brinjal', 'baingun': 'brinjal',
    'gobhi': 'cauliflower',
    'phool gobhi': 'cauliflower',
    'ful gobhi': 'cauliflower',
    'patta gobhi': 'cabbage', 'band gobhi': 'cabbage',
    'shimla mirch': 'capsicum', 'simla mirch': 'capsicum',
    'mirchi': 'chilli', 'mirch': 'chilli', 'hari mirch': 'green chilli',
    'lal mirch': 'red chilli',
    'kheera': 'cucumber', 'kakdi': 'cucumber', 'kheere': 'cucumber',
    'kaddu': 'pumpkin', 'lal kaddu': 'pumpkin',
    'lauki': 'bottle gourd', 'ghiya': 'bottle gourd', 'doodhi': 'bottle gourd',
    'karela': 'bitter gourd',
    'dhaniya': 'coriander', 'hara dhaniya': 'coriander', 'dhaniye': 'coriander',
    'pudina': 'mint',
    'curry patta': 'curry leaves', 'kari patta': 'curry leaves',
    'mooli': 'radish',
    'chukander': 'beetroot',
    'tinda': 'apple gourd',
    'arbi': 'taro', 'arvi': 'taro',
    'sem': 'beans', 'sem ki phali': 'beans',
    'torai': 'ridge gourd', 'tori': 'ridge gourd',
    'parwal': 'pointed gourd',
    'suran': 'yam', 'jimikand': 'yam',
    'kathal': 'jackfruit',
    'methi': 'fenugreek leaves', 'methi patta': 'fenugreek leaves',
    // Fruits
    'seb': 'apple',
    'kela': 'banana', 'kele': 'banana',
    'aam': 'mango', 'kacha aam': 'raw mango',
    'santara': 'orange', 'narangi': 'orange', 'santra': 'orange',
    'angoor': 'grapes',
    'tarbuj': 'watermelon', 'tarbooj': 'watermelon',
    'papita': 'papaya', 'papaya': 'papaya',
    'ananas': 'pineapple',
    'nimbu': 'lemon', 'neembu': 'lemon',
    'mosambi': 'sweet lime',
    'nariyal': 'coconut',
    'anar': 'pomegranate',
    'amrood': 'guava', 'amrud': 'guava',
    'jamun': 'java plum',
    'lichi': 'lychee', 'litchi': 'lychee',
    'chiku': 'sapodilla',
    'ber': 'jujube',
    'nashpati': 'pear',
    'khajur': 'dates', 'khajoor': 'dates',
    'anjeer': 'fig',
    'kivi': 'kiwi',
    'strawberry': 'strawberry',
    // Dairy
    'doodh': 'milk', 'dudh': 'milk', 'dood': 'milk',
    'dahi': 'curd', 'dahi wala': 'curd', 'yogurt': 'yogurt',
    'paneer': 'paneer', 'chena': 'paneer',
    'makhan': 'butter', 'makkhan': 'butter',
    'ghee': 'ghee', 'desi ghee': 'ghee', 'vanaspati': 'dalda',
    'malai': 'cream',
    'chaach': 'buttermilk', 'lassi': 'lassi', 'mathha': 'buttermilk',
    'khoya': 'khoya', 'mawa': 'khoya',
    'mithai': 'sweets',
    'ice cream': 'ice cream',
    // Grains & Staples
    'aata': 'wheat flour', 'atta': 'wheat flour', 'gehu atta': 'wheat flour',
    'maida': 'all-purpose flour',
    'besan': 'chickpea flour',
    'chawal': 'rice', 'chaawal': 'rice', 'basmati': 'basmati rice',
    'dal': 'lentils', 'daal': 'lentils',
    'chana dal': 'chana dal', 'moong dal': 'moong dal',
    'masoor dal': 'masoor dal', 'urad dal': 'urad dal', 'arhar dal': 'toor dal',
    'rajma': 'kidney beans',
    'chana': 'chickpeas', 'chole': 'chickpeas', 'kabuli chana': 'chickpeas',
    'sooji': 'semolina', 'rava': 'semolina', 'rawa': 'semolina',
    'poha': 'flattened rice', 'chiwda': 'flattened rice',
    'sabudana': 'sago',
    'murmure': 'puffed rice', 'muri': 'puffed rice',
    'sewai': 'vermicelli', 'seviya': 'vermicelli',
    'daliya': 'broken wheat',
    'maize': 'corn', 'makka': 'corn', 'bhutta': 'corn',
    // Oils & Condiments
    'tel': 'oil', 'sarso tel': 'mustard oil', 'sunflower tel': 'sunflower oil',
    'sarso ka tel': 'mustard oil',
    'namak': 'salt',
    'cheeni': 'sugar', 'shakkar': 'sugar', 'chini': 'sugar',
    'gurr': 'jaggery', 'gur': 'jaggery', 'guda': 'jaggery',
    'haldi': 'turmeric',
    'jeera': 'cumin', 'zeera': 'cumin',
    'dhania powder': 'coriander powder', 'dhania': 'coriander seeds',
    'garam masala': 'garam masala',
    'sarso': 'mustard seeds', 'rai': 'mustard seeds',
    'methi dana': 'fenugreek seeds',
    'hing': 'asafoetida',
    'saunf': 'fennel seeds',
    'imli': 'tamarind', 'amchur': 'dry mango powder',
    'ketchup': 'ketchup', 'tomato sauce': 'tomato sauce',
    'sirka': 'vinegar',
    'soya sauce': 'soy sauce',
    // Beverages
    'chai': 'tea', 'chay': 'tea', 'chai patti': 'tea leaves',
    'coffee': 'coffee',
    'pani': 'water',
    'nimbu pani': 'lemonade',
    'nariyal pani': 'coconut water',
    // Meat & Eggs
    'murgi': 'chicken', 'murghi': 'chicken', 'broiler': 'chicken',
    'gosht': 'mutton', 'bakra gosht': 'mutton', 'keema': 'minced meat',
    'machi': 'fish', 'machli': 'fish', 'machhli': 'fish', 'meen': 'fish',
    'jhinga': 'prawns', 'chingri': 'prawns',
    'anda': 'egg', 'ande': 'eggs', 'anda unda': 'egg',
    // Bakery
    'bread': 'bread', 'double roti': 'bread', 'pav': 'pav bread',
    'bun': 'bun',
    'rusk': 'rusk',
    // Cleaning
    'sabun': 'soap', 'saabun': 'soap',
    'detergent': 'detergent', 'kapde dhone wala': 'detergent',
    'washing powder': 'washing powder',
    'bartan sabun': 'dish soap', 'vim': 'vim',
    'phenyl': 'phenyl',
    'jhadu': 'broom',
    'pocha': 'mop',
    // Personal care
    'shampoo': 'shampoo', 'tel baal ka': 'hair oil',
    'sabun naha': 'bath soap',
    'toothpaste': 'toothpaste', 'toothbrush': 'toothbrush',
    'cream': 'cream', 'lotion': 'lotion',
    'talcum powder': 'talcum powder', 'powder': 'body powder',
  };

  // ── Category auto-detection ───────────────────────────────────────────────
  static const Map<String, GroceryCategory> _categoryKeywords = {
    // Vegetables
    'potato': GroceryCategory.vegetables, 'onion': GroceryCategory.vegetables,
    'tomato': GroceryCategory.vegetables, 'garlic': GroceryCategory.vegetables,
    'ginger': GroceryCategory.vegetables, 'carrot': GroceryCategory.vegetables,
    'spinach': GroceryCategory.vegetables, 'peas': GroceryCategory.vegetables,
    'okra': GroceryCategory.vegetables, 'brinjal': GroceryCategory.vegetables,
    'cauliflower': GroceryCategory.vegetables,
    'capsicum': GroceryCategory.vegetables,
    'cucumber': GroceryCategory.vegetables,
    'pumpkin': GroceryCategory.vegetables,
    'radish': GroceryCategory.vegetables,
    'beetroot': GroceryCategory.vegetables,
    'cabbage': GroceryCategory.vegetables, 'chilli': GroceryCategory.vegetables,
    'coriander': GroceryCategory.vegetables, 'mint': GroceryCategory.vegetables,
    'curry leaves': GroceryCategory.vegetables,
    'bitter gourd': GroceryCategory.vegetables,
    'bottle gourd': GroceryCategory.vegetables,
    'fenugreek': GroceryCategory.vegetables,
    'beans': GroceryCategory.vegetables,
    'jackfruit': GroceryCategory.vegetables,
    'ridge gourd': GroceryCategory.vegetables,
    'taro': GroceryCategory.vegetables,
    'yam': GroceryCategory.vegetables, 'corn': GroceryCategory.vegetables,
    'green chilli': GroceryCategory.vegetables,
    'red chilli': GroceryCategory.vegetables,
    'mushroom': GroceryCategory.vegetables,
    // Fruits
    'apple': GroceryCategory.fruits, 'banana': GroceryCategory.fruits,
    'mango': GroceryCategory.fruits, 'orange': GroceryCategory.fruits,
    'grapes': GroceryCategory.fruits, 'watermelon': GroceryCategory.fruits,
    'papaya': GroceryCategory.fruits, 'pineapple': GroceryCategory.fruits,
    'lemon': GroceryCategory.fruits, 'coconut': GroceryCategory.fruits,
    'pomegranate': GroceryCategory.fruits, 'guava': GroceryCategory.fruits,
    'sweet lime': GroceryCategory.fruits, 'lychee': GroceryCategory.fruits,
    'sapodilla': GroceryCategory.fruits, 'strawberry': GroceryCategory.fruits,
    'kiwi': GroceryCategory.fruits, 'pear': GroceryCategory.fruits,
    'dates': GroceryCategory.fruits, 'fig': GroceryCategory.fruits,
    // Dairy
    'milk': GroceryCategory.dairy, 'curd': GroceryCategory.dairy,
    'paneer': GroceryCategory.dairy, 'butter': GroceryCategory.dairy,
    'ghee': GroceryCategory.dairy, 'cream': GroceryCategory.dairy,
    'buttermilk': GroceryCategory.dairy, 'yogurt': GroceryCategory.dairy,
    'lassi': GroceryCategory.dairy, 'cheese': GroceryCategory.dairy,
    'khoya': GroceryCategory.dairy, 'ice cream': GroceryCategory.dairy,
    'dalda': GroceryCategory.dairy,
    // Meat & Eggs
    'chicken': GroceryCategory.meatAndEggs,
    'mutton': GroceryCategory.meatAndEggs,
    'fish': GroceryCategory.meatAndEggs, 'prawns': GroceryCategory.meatAndEggs,
    'egg': GroceryCategory.meatAndEggs, 'eggs': GroceryCategory.meatAndEggs,
    'minced meat': GroceryCategory.meatAndEggs,
    'beef': GroceryCategory.meatAndEggs,
    'pork': GroceryCategory.meatAndEggs,
    // Bakery
    'bread': GroceryCategory.bakery, 'roti': GroceryCategory.bakery,
    'paratha': GroceryCategory.bakery, 'chapati': GroceryCategory.bakery,
    'biscuit': GroceryCategory.bakery, 'cake': GroceryCategory.bakery,
    'cookies': GroceryCategory.bakery, 'pav bread': GroceryCategory.bakery,
    'bun': GroceryCategory.bakery, 'rusk': GroceryCategory.bakery,
    'naan': GroceryCategory.bakery, 'pita': GroceryCategory.bakery,
    // Beverages
    'tea': GroceryCategory.beverages, 'coffee': GroceryCategory.beverages,
    'juice': GroceryCategory.beverages, 'water': GroceryCategory.beverages,
    'soda': GroceryCategory.beverages, 'cold drink': GroceryCategory.beverages,
    'lemonade': GroceryCategory.beverages,
    'coconut water': GroceryCategory.beverages,
    'tea leaves': GroceryCategory.beverages,
    // Snacks
    'chips': GroceryCategory.snacks, 'namkeen': GroceryCategory.snacks,
    'chocolate': GroceryCategory.snacks, 'candy': GroceryCategory.snacks,
    'sweets': GroceryCategory.snacks, 'popcorn': GroceryCategory.snacks,
    'mixture': GroceryCategory.snacks, 'wafer': GroceryCategory.snacks,
    'biscuits': GroceryCategory.snacks,
    // Cleaning
    'soap': GroceryCategory.cleaning, 'detergent': GroceryCategory.cleaning,
    'dish soap': GroceryCategory.cleaning,
    'floor cleaner': GroceryCategory.cleaning,
    'phenyl': GroceryCategory.cleaning, 'vim': GroceryCategory.cleaning,
    'washing powder': GroceryCategory.cleaning,
    'broom': GroceryCategory.cleaning,
    'mop': GroceryCategory.cleaning,
    // Personal Care
    'shampoo': GroceryCategory.personalCare,
    'conditioner': GroceryCategory.personalCare,
    'face wash': GroceryCategory.personalCare,
    'toothpaste': GroceryCategory.personalCare,
    'toothbrush': GroceryCategory.personalCare,
    'lotion': GroceryCategory.personalCare,
    'body powder': GroceryCategory.personalCare,
    'talcum powder': GroceryCategory.personalCare,
    'hair oil': GroceryCategory.personalCare,
    'bath soap': GroceryCategory.personalCare,
  };

  // ── Public parse method ────────────────────────────────────────────────────
  static ParsedCommand parse(String rawText) {
    final text = rawText.trim().toLowerCase();

    if (text.isEmpty) {
      return ParsedCommand(action: CommandAction.unknown, rawText: rawText);
    }

    // Handle undo
    if (_containsWord(text, ['undo', 'go back', 'wapas', 'cancel last'])) {
      return ParsedCommand(action: CommandAction.undo, rawText: rawText);
    }

    // Handle clear
    if (_containsWord(text, [
      'clear all',
      'clear list',
      'start fresh',
      'sab hatao',
      'sab delete',
    ])) {
      return ParsedCommand(action: CommandAction.clear, rawText: rawText);
    }

    // Detect "more" modifier for addMore
    final hasMore = _containsWord(text, [
      'more',
      'aur',
      'zyada',
      'extra',
      'additional',
    ]);
    final setsExactQuantity = _wordsContain(text, 'to');

    // Detect language hints
    final isHindiContext = _isHindiText(text);

    // Try to detect action from first few words
    final words = _tokenize(text);
    CommandAction action = CommandAction.unknown;
    int actionIdx = -1;

    for (int i = 0; i < words.length && i < 4; i++) {
      final w = words[i];
      if (_subtractKeywords.containsKey(w)) {
        action = CommandAction.subtractQuantity;
        actionIdx = i;
        break;
      }
      if (_updateKeywords.containsKey(w)) {
        action = setsExactQuantity
            ? CommandAction.setQuantity
            : CommandAction.addMore;
        actionIdx = i;
        break;
      }
      if (_addKeywords.containsKey(w)) {
        action = hasMore ? CommandAction.addMore : CommandAction.add;
        actionIdx = i;
        break;
      }
      if (_removeKeywords.containsKey(w)) {
        action = CommandAction.remove;
        actionIdx = i;
        break;
      }
      if (_checkKeywords.containsKey(w)) {
        action = CommandAction.check;
        actionIdx = i;
        break;
      }
    }

    // If no action found at front, check at end (e.g., "doodh chahiye")
    if (action == CommandAction.unknown) {
      for (int i = words.length - 1; i >= 0 && i >= words.length - 3; i--) {
        final w = words[i];
        if (_subtractKeywords.containsKey(w)) {
          action = CommandAction.subtractQuantity;
          actionIdx = i;
          break;
        }
        if (_updateKeywords.containsKey(w)) {
          action = setsExactQuantity
              ? CommandAction.setQuantity
              : CommandAction.addMore;
          actionIdx = i;
          break;
        }
        if (_addKeywords.containsKey(w)) {
          action = hasMore ? CommandAction.addMore : CommandAction.add;
          actionIdx = i;
          break;
        }
        if (_removeKeywords.containsKey(w)) {
          action = CommandAction.remove;
          actionIdx = i;
          break;
        }
        if (_checkKeywords.containsKey(w)) {
          action = CommandAction.check;
          actionIdx = i;
          break;
        }
      }
    }

    // Default to add if no action found (assume user just said item name)
    if (action == CommandAction.unknown) {
      action = hasMore ? CommandAction.addMore : CommandAction.add;
      actionIdx = -1;
    }

    // Remove action word from tokens
    final remaining = List<String>.from(words);
    if (actionIdx >= 0) remaining.removeAt(actionIdx);
    // Also remove 'more', 'aur', 'mark', 'as', 'done' helper words
    remaining.removeWhere(
      (w) => [
        'more',
        'aur',
        'zyada',
        'extra',
        'additional',
        'mark',
        'as',
        'done',
        'please',
        'some',
        'the',
        'a',
        'an',
        'and',
        'or',
        'to',
        'by',
      ].contains(w),
    );

    // Extract quantity
    double? quantity;
    int? quantityIdx;
    for (int i = 0; i < remaining.length; i++) {
      final parsed = _parseNumber(remaining[i], isHindiContext);
      if (parsed != null) {
        quantity = parsed;
        quantityIdx = i;
        break;
      }
    }
    if (quantityIdx != null) remaining.removeAt(quantityIdx);

    // "remove 1 kg potatoes" → the user means decrease, not delete
    if (action == CommandAction.remove && quantity != null) {
      action = CommandAction.subtractQuantity;
    }

    if (action == CommandAction.setQuantity && quantity == null) {
      return ParsedCommand(action: CommandAction.unknown, rawText: rawText);
    }

    // Extract unit
    String? unit;
    int? unitIdx;
    for (int i = 0; i < remaining.length; i++) {
      if (_unitKeywords.containsKey(remaining[i])) {
        unit = _unitKeywords[remaining[i]];
        unitIdx = i;
        break;
      }
    }
    if (unitIdx != null) remaining.removeAt(unitIdx);

    // What remains is the item name
    if (remaining.isEmpty) {
      return ParsedCommand(
        action: action,
        quantity: quantity ?? 1.0,
        unit: unit,
        rawText: rawText,
      );
    }

    // Try multi-word Hindi item first
    final joinedRemaining = remaining.join(' ');
    String itemName = _translateHindi(joinedRemaining) ?? joinedRemaining;
    itemName = _capitalize(itemName);

    // Detect category
    final category = _detectCategory(itemName.toLowerCase());

    // Default unit based on category if not specified
    unit ??= _defaultUnit(category, itemName.toLowerCase());

    return ParsedCommand(
      action: action,
      itemName: itemName,
      quantity: quantity ?? 1.0,
      unit: unit,
      categoryKey: category.storageKey,
      rawText: rawText,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _containsWord(String text, List<String> words) {
    return words.any((w) => text.contains(w));
  }

  static bool _wordsContain(String text, String word) {
    return RegExp('(^|\\s)${RegExp.escape(word)}(\\s|\$)').hasMatch(text);
  }

  static bool _isHindiText(String text) {
    if (RegExp(r'[ऀ-ॿ]').hasMatch(text)) return true;
    const hindiMarkers = [
      'aloo',
      'doodh',
      'pyaz',
      'tamatar',
      'anda',
      'chai',
      'jodo',
      'daalo',
      'hatao',
      'chahiye',
      'mangao',
      'teen',
      'char',
      'paanch',
      'chhe',
      'saat',
      'aath',
      'nau',
      'das',
      'adha',
      'aadha',
      'ek ',
      ' ek',
    ];
    return hindiMarkers.any((m) => text.contains(m));
  }

  static List<String> _tokenize(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'(\d+(?:\.\d+)?)(kg|kgs|g|gm|gms|l|lt|ml|pc|pcs)\b'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static double? _parseNumber(String word, bool isHindiContext) {
    // Try numeric parse first
    final numeric = double.tryParse(word);
    if (numeric != null) return numeric;

    // Try word-to-number (skip 'do' unless Hindi context to avoid English confusion)
    if (word == 'do' && !isHindiContext) return null;
    return _numberWords[word];
  }

  static String? _translateHindi(String text) {
    // Try longest match first (multi-word phrases)
    final sorted = _hindiToEnglish.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in sorted) {
      if (text == key || text.contains(key)) {
        return _hindiToEnglish[key];
      }
    }
    return null;
  }

  static GroceryCategory _detectCategory(String itemName) {
    // Try exact match first
    if (_categoryKeywords.containsKey(itemName)) {
      return _categoryKeywords[itemName]!;
    }
    // Try partial match
    for (final entry in _categoryKeywords.entries) {
      if (itemName.contains(entry.key) || entry.key.contains(itemName)) {
        return entry.value;
      }
    }
    return GroceryCategory.other;
  }

  static String _defaultUnit(GroceryCategory category, String itemName) {
    // Liquids
    if ([
      'milk',
      'oil',
      'buttermilk',
      'juice',
      'water',
      'soda',
      'coconut water',
      'ghee',
      'cream',
    ].any((w) => itemName.contains(w))) {
      return 'l';
    }
    // Weight items
    if (category == GroceryCategory.vegetables ||
        category == GroceryCategory.fruits) {
      return 'kg';
    }
    if ([
      'flour',
      'rice',
      'lentils',
      'sugar',
      'salt',
      'semolina',
      'dal',
      'wheat',
    ].any((w) => itemName.contains(w))) {
      return 'kg';
    }
    // Packaged items
    if (category == GroceryCategory.snacks ||
        category == GroceryCategory.bakery) {
      return 'packet';
    }
    return 'piece';
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Fuzzy item name match (for remove/check operations)
  static bool itemNamesMatch(String listName, String spokenName) {
    final n1 = listName.toLowerCase().trim();
    final n2 = spokenName.toLowerCase().trim();
    if (n1 == n2) return true;
    if (n1.contains(n2) || n2.contains(n1)) return true;
    // Remove trailing 's' for plural matching
    if (n1.replaceAll(RegExp(r's$'), '') == n2.replaceAll(RegExp(r's$'), '')) {
      return true;
    }
    return false;
  }
}
