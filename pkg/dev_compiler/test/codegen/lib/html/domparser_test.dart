import 'dart:html';

import 'package:minitest/minitest.dart';

main() {
  var isDomParser = predicate((x) => x is DomParser, 'is a DomParser');

  test('constructorTest', () {
    var ctx = new DomParser();
    expect(ctx, isNotNull);
    expect(ctx, isDomParser);
  });
}
