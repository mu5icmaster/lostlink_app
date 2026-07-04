class ItemFormHelper {
  static String createId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static String formattedToday() {
    return formatDate(DateTime.now());
  }

  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String emojiForCategory(String category) {
    switch (category) {
      case 'ID Card':
        return '🪪';
      case 'Wallet':
        return '👛';
      case 'Electronics':
        return '🔌';
      case 'Books':
        return '📚';
      case 'Bottle':
        return '🍼';
      case 'Clothing':
        return '👕';
      case 'Keys':
        return '🔑';
      case 'Stationery':
        return '✏️';
      case 'Documents':
        return '📄';
      case 'Bags':
        return '🎒';
      case 'Personal belongings':
        return '📦';
      default:
        return '📦';
    }
  }

  static String suggestCategory(String text) {
    final value = text.toLowerCase();
    if (_containsAny(value, ['phone', 'charger', 'laptop', 'calculator'])) {
      return 'Electronics';
    }
    if (_containsAny(value, ['pen', 'pencil', 'marker', 'ruler'])) {
      return 'Stationery';
    }
    if (_containsAny(value, ['card', 'student id', 'id'])) return 'ID Card';
    if (_containsAny(value, ['wallet', 'purse'])) return 'Wallet';
    if (_containsAny(value, ['book', 'notebook'])) return 'Books';
    if (_containsAny(value, ['bottle', 'flask'])) return 'Bottle';
    if (_containsAny(value, ['shirt', 'jacket', 'hoodie', 'clothing'])) {
      return 'Clothing';
    }
    if (_containsAny(value, ['key', 'keys'])) return 'Keys';
    if (_containsAny(value, ['document', 'paper', 'certificate'])) {
      return 'Documents';
    }
    if (_containsAny(value, ['bag', 'backpack'])) return 'Bags';
    return 'Others';
  }

  static bool _containsAny(String value, List<String> words) {
    return words.any(value.contains);
  }
}
