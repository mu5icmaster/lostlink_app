import 'package:flutter_test/flutter_test.dart';
import 'package:lost_link/models/chat_message_model.dart';
import 'package:lost_link/models/user_model.dart';
import 'package:lost_link/services/auth_service.dart';

void main() {
  group('authentication policy', () {
    test('accepts only configured campus domains', () {
      expect(
        AuthService.isValidInstitutionEmail('a@student.campus.edu.my'),
        isTrue,
      );
      expect(
        AuthService.isValidInstitutionEmail('a@staff.campus.edu.my'),
        isTrue,
      );
      expect(AuthService.isValidInstitutionEmail('a@example.com'), isFalse);
    });

    test('derives roles from normalized email addresses', () {
      expect(
        AuthService.roleForEmail(' L@LECTURER.CAMPUS.EDU.MY '),
        'Lecturer',
      );
    });
  });

  group('privacy-safe models', () {
    test('user profiles never serialize passwords', () {
      final user = UserModel(
        name: 'Test User',
        email: 'test@student.campus.edu.my',
        role: 'Student',
        contactNumber: '0123456789',
      );

      expect(user.toJson().containsKey('password'), isFalse);
    });

    test('chat messages preserve sender identity and sortable time', () {
      final message = ChatMessageModel(
        id: 'message-1',
        itemId: 'item-1',
        sender: 'Test User',
        senderUid: 'uid-1',
        senderEmail: 'test@student.campus.edu.my',
        message: 'Hello',
        createdAt: '3 Jul 2026',
        createdAtMillis: 1783010000000,
      );

      final restored = ChatMessageModel.fromJson(message.toJson());
      expect(restored.senderUid, 'uid-1');
      expect(restored.createdAtMillis, 1783010000000);
    });
  });
}
