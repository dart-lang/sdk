import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isDomParser = predicate((x) => x is DomParser, 'is a DomParser');

  test('constructorTest', () {
    var ctx = new DomParser();
    expect(ctx, isNotNull);
    expect(ctx, isDomParser);
  });
}
