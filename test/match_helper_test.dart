import 'package:flutter_test/flutter_test.dart';
import 'package:lost_link/models/claim_model.dart';
import 'package:lost_link/models/item_model.dart';
import 'package:lost_link/utils/item_form_helper.dart';
import 'package:lost_link/utils/match_helper.dart';

void main() {
  group('MatchHelper', () {
    test('scores strongly similar lost and found items', () {
      final lostItem = ItemModel(
        id: 'lost-1',
        name: 'Black Wallet',
        category: 'Wallet',
        color: 'Black',
        location: 'Cafeteria',
        description: 'Black leather wallet with student ID inside.',
        date: '22 Apr 2026',
        type: 'lost',
        status: 'Missing',
        imageEmoji: '👛',
      );

      final foundItem = ItemModel(
        id: 'found-1',
        name: 'Black Leather Wallet',
        category: 'Wallet',
        color: 'Black',
        location: 'Near Cafeteria',
        description: 'Found a black leather wallet on the cafeteria table.',
        date: '22 Apr 2026',
        type: 'found',
        status: 'Available',
        imageEmoji: '👛',
      );

      expect(MatchHelper.calculateMatchScore(lostItem, foundItem), 85);
    });

    test('filters weak matches and sorts remaining matches by score', () {
      final lostItem = ItemModel(
        id: 'lost-1',
        name: 'Laptop Charger',
        category: 'Electronics',
        color: 'White',
        location: 'Lecture Hall A',
        description: 'White laptop charger lost after class.',
        date: '20 Apr 2026',
        type: 'lost',
        status: 'Missing',
        imageEmoji: '🔌',
      );

      final strongMatch = ItemModel(
        id: 'found-1',
        name: 'White Charger',
        category: 'Electronics',
        color: 'White',
        location: 'Lecture Hall A',
        description: 'Found a white laptop charger under the chair.',
        date: '20 Apr 2026',
        type: 'found',
        status: 'Available',
        imageEmoji: '🔌',
      );

      final weakMatch = ItemModel(
        id: 'found-2',
        name: 'Blue ID Card',
        category: 'ID Card',
        color: 'Blue',
        location: 'Library',
        description: 'Found an ID card.',
        date: '20 Apr 2026',
        type: 'found',
        status: 'Available',
        imageEmoji: '🪪',
      );

      final matches = MatchHelper.findPossibleMatches(
        lostItem: lostItem,
        allItems: [weakMatch, strongMatch],
      );

      expect(matches, hasLength(1));
      expect(matches.single.item.id, strongMatch.id);
      expect(matches.single.score, greaterThanOrEqualTo(40));
    });
  });

  group('ItemFormHelper', () {
    test('maps known categories to display emoji', () {
      expect(ItemFormHelper.emojiForCategory('ID Card'), '🪪');
      expect(ItemFormHelper.emojiForCategory('Wallet'), '👛');
      expect(ItemFormHelper.emojiForCategory('Unknown'), '📦');
    });

    test('formats today as a human readable date', () {
      final formatted = ItemFormHelper.formattedToday();

      expect(formatted, matches(RegExp(r'^\d{1,2} [A-Z][a-z]{2} \d{4}$')));
    });
  });

  group('model serialization', () {
    test('round-trips item data through JSON', () {
      final item = ItemModel(
        id: 'item-1',
        name: 'Student ID Card',
        category: 'ID Card',
        color: 'Blue',
        location: 'Library',
        description: 'Blue lanyard attached.',
        date: '2 May 2026',
        type: 'found',
        status: 'Available',
        imageEmoji: '🪪',
      );

      final restored = ItemModel.fromJson(item.toJson());

      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.status, item.status);
      expect(restored.imageEmoji, item.imageEmoji);
    });

    test('round-trips claim data and links it to an existing item', () {
      final item = ItemModel(
        id: 'item-1',
        name: 'Student ID Card',
        category: 'ID Card',
        color: 'Blue',
        location: 'Library',
        description: 'Blue lanyard attached.',
        date: '2 May 2026',
        type: 'found',
        status: 'Available',
        imageEmoji: '🪪',
      );
      final claim = ClaimModel(
        id: 'claim-1',
        item: item,
        claimantName: 'Aina Rahman',
        studentId: 'I22012345',
        proofDescription: 'My name is printed on the card.',
        status: 'Pending',
      );

      final restored = ClaimModel.fromJson(claim.toJson(), [item]);

      expect(restored.id, claim.id);
      expect(restored.item, same(item));
      expect(restored.claimantName, claim.claimantName);
      expect(restored.status, claim.status);
    });
  });
}
