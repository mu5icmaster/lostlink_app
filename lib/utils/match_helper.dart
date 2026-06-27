import '../models/item_model.dart';

class MatchResult {
  final ItemModel item;
  final int score;

  MatchResult({required this.item, required this.score});
}

class MatchHelper {
  static int calculateMatchScore(ItemModel lostItem, ItemModel foundItem) {
    int score = 0;

    final lostName = lostItem.name.toLowerCase();
    final foundName = foundItem.name.toLowerCase();

    final lostCategory = lostItem.category.toLowerCase();
    final foundCategory = foundItem.category.toLowerCase();

    final lostColor = lostItem.color.toLowerCase();
    final foundColor = foundItem.color.toLowerCase();

    final lostLocation = lostItem.location.toLowerCase();
    final foundLocation = foundItem.location.toLowerCase();

    final lostDescription = lostItem.description.toLowerCase();
    final foundDescription = foundItem.description.toLowerCase();

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

    if (score > 100) {
      score = 100;
    }

    return score;
  }

  static List<MatchResult> findPossibleMatches({
    required ItemModel lostItem,
    required List<ItemModel> allItems,
  }) {
    final foundItems = allItems.where((item) => item.type == 'found').toList();

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
