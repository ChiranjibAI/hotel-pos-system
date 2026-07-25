import 'package:image_cropper/image_cropper.dart';
import 'package:mockito/annotations.dart';

import 'package:hotel_pos_system/services/image_dumper.dart';
import 'mock_helpers.mocks.dart';

final imageCropper = MockImageCropper();

@GenerateMocks([ImageCropper])
void initializeImageCropper() {
  ImageDumper.cropper = imageCropper;
}
