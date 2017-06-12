import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  var isLocation = predicate((x) => x is Location, 'is a Location');

  test('location hash', () {
    final location = window.location;
    expect(location, isLocation);

    // The only navigation we dare try is hash.
    location.hash = 'hello';
    var h = location.hash;
    expect(h, '#hello');
  });

  test('location.origin', () {
    var origin = window.location.origin;

    // We build up the origin from Uri, then make sure that it matches.
    var uri = Uri.parse(window.location.href);
    var reconstructedOrigin = '${uri.scheme}://${uri.host}';
    if (uri.port != 0) {
      reconstructedOrigin = '$reconstructedOrigin:${uri.port}';
    }

    expect(origin, reconstructedOrigin);
  });
}
