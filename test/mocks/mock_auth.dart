import 'package:http/http.dart';
import 'package:mockito/annotations.dart';
import 'package:hotel_pos_system/services/auth.dart';

import 'mock_auth.mocks.dart';

final auth = MockAuth();

@GenerateMocks([Auth, Client])
void initializeAuth() {
  Auth.instance = auth;
}
