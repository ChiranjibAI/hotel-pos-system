import 'package:mockito/annotations.dart';
import 'package:hotel_pos_system/services/storage.dart';

import 'mock_storage.mocks.dart';

final storage = MockStorage();

@GenerateMocks([Storage])
void _initializeStorage() {
  Storage.instance = storage;
  _finished = true;
}

var _finished = false;
void initializeStorage() {
  if (!_finished) {
    _initializeStorage();
  }
}
