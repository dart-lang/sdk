#library('LocationTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  var isLocation = predicate((x) => x is Location, 'is a Location');

  test('location hash', () {
      final location = window.location;
      expect(location, isLocation);

      // The only navigation we dare try is hash.
      location.hash = 'hello';
      var h = location.hash;
      expect(h, '#hello');
    });
}
