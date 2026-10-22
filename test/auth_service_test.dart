import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vocart/services/auth_service.dart';

void main() {
  test('account picker cancellation does not fail silently', () {
    const error = GoogleSignInException(
      code: GoogleSignInExceptionCode.canceled,
    );

    expect(AuthService.errorMessage(error), isNotEmpty);
  });
}
