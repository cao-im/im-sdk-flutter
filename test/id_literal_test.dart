import 'package:cao_im_sdk_flutter/utils/id_literal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snowflake digits stay exact when carried as text', () {
    const snowflake = '176000000000000123';
    expect(IdLiteral.text(snowflake), snowflake);
    expect(IdLiteral.isPositive(snowflake), isTrue);
    expect(IdLiteral.isPositive('0'), isFalse);
  });

  test('numeric compare is not lexicographic', () {
    expect(IdLiteral.greaterThan('20', '3'), isTrue);
    expect(IdLiteral.greaterThan('3', '20'), isFalse);
    expect(IdLiteral.maxOf(['3', '20', '100']), '100');
  });
}
