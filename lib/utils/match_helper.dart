import '../models/item_model.dart';

class MatchResult {
  final ItemModel item;
  final int score;

  MatchResult({required this.item, required this.score});
}

class MatchHelper {
  static int calculateMatchScore(ItemModel lostItem, ItemModel foundItem) {
    int score = 0;

    final lostName = _normalize(lostItem.name);
    final foundName = _normalize(foundItem.name);

    final lostCategory = _canonicalCategory(lostItem.category);
    final foundCategory = _canonicalCategory(foundItem.category);

    final lostColor = _canonicalColor(lostItem.color);
    final foundColor = _canonicalColor(foundItem.color);

    final lostLocation = _normalize(lostItem.location);
    final foundLocation = _normalize(foundItem.location);

    final lostDescription = _normalize(lostItem.description);
    final foundDescription = _normalize(foundItem.description);

    // Same category
    if (lostCategory == foundCategory) {
      score += 25;
    }

    // Similar name
    if (lostName.contains(foundName) || foundName.contains(lostName)) {
      score += 25;
    } else {
      final lostWords = lostName.split(' ');
      for (final word in lostWords) {
        if (word.length > 2 && foundName.contains(word)) {
          score += 10;
          break;
        }
      }
      if (_similarity(lostName, foundName) >= 0.72) score += 10;
    }

    // Same colour
    if (lostColor == foundColor) {
      score += 20;
    }

    // Similar location
    if (lostLocation.contains(foundLocation) ||
        foundLocation.contains(lostLocation)) {
      score += 15;
    } else {
      final lostLocationWords = lostLocation.split(' ');
      for (final word in lostLocationWords) {
        if (word.length > 2 && foundLocation.contains(word)) {
          score += 8;
          break;
        }
      }
    }

    // Description keyword similarity
    final lostDescriptionWords = lostDescription.split(' ');
    int commonWords = 0;

    for (final word in lostDescriptionWords) {
      if (word.length > 3 && foundDescription.contains(word)) {
        commonWords++;
      }
    }

    if (commonWords >= 3) {
      score += 15;
    } else if (commonWords == 2) {
      score += 10;
    } else if (commonWords == 1) {
      score += 5;
    }

    final lostDate = _parseDate(lostItem.date);
    final foundDate = _parseDate(foundItem.date);
    if (lostDate != null && foundDate != null) {
      final dayGap = lostDate.difference(foundDate).inDays.abs();
      if (dayGap > 30) {
        score -= 20;
      } else if (dayGap > 14) {
        score -= 10;
      }
    }

    if (score > 100) {
      score = 100;
    }

    return score;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _canonicalColor(String value) {
    final color = _normalize(value);
    const aliases = {
      'grey': 'gray',
      'navy blue': 'blue',
      'light blue': 'blue',
      'dark blue': 'blue',
      'maroon': 'red',
    };
    return aliases[color] ?? color;
  }

  static String _canonicalCategory(String value) {
    final category = _normalize(value);
    const aliases = {
      'electronic': 'electronics',
      'phone': 'electronics',
      'book': 'books',
      'bag': 'bags',
      'key': 'keys',
    };
    return aliases[category] ?? category;
  }

  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final previous = List<int>.generate(b.length + 1, (index) => index);
    for (var i = 1; i <= a.length; i++) {
      var diagonal = previous[0];
      previous[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final above = previous[j];
        previous[j] = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1)
            ? diagonal
            : 1 +
                  [
                    diagonal,
                    above,
                    previous[j - 1],
                  ].reduce((left, right) => left < right ? left : right);
        diagonal = above;
      }
    }
    return 1 - (previous.last / (a.length > b.length ? a.length : b.length));
  }

  static DateTime? _parseDate(String value) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final parts = value.split(' ');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static List<MatchResult> findPossibleMatches({
    required ItemModel lostItem,
    required List<ItemModel> allItems,
  }) {
    final foundItems = allItems
        .where((item) => item.type == 'found' && item.status == 'Available')
        .toList();

    final results = foundItems
        .map((foundItem) {
          final score = calculateMatchScore(lostItem, foundItem);

          return MatchResult(item: foundItem, score: score);
        })
        .where((result) {
          return result.score >= 40;
        })
        .toList();

    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }
}
