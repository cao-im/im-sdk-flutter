import 'package:flutter_test/flutter_test.dart';

import 'package:cao_im_sdk_flutter/cao_im_sdk_flutter.dart';

void main() {
  test('exports IMClient singleton', () {
    expect(IMClient.instance, isNotNull);
  });
}
