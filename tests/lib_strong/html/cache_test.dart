import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(ApplicationCache.supported, isTrue);
    });
  });

  group('ApplicationCache', () {
    test('ApplicationCache', () {
      var expectation = ApplicationCache.supported ? returnsNormally : throws;
      expect(() {
        ApplicationCache appCache = window.applicationCache;
        expect(cacheStatusToString(appCache.status), "UNCACHED");
      }, expectation);
    });
  });
}

String cacheStatusToString(int status) {
  switch (status) {
    case ApplicationCache.UNCACHED: // UNCACHED == 0
      return 'UNCACHED';
    case ApplicationCache.IDLE: // IDLE == 1
      return 'IDLE';
    case ApplicationCache.CHECKING: // CHECKING == 2
      return 'CHECKING';
    case ApplicationCache.DOWNLOADING: // DOWNLOADING == 3
      return 'DOWNLOADING';
    case ApplicationCache.UPDATEREADY: // UPDATEREADY == 4
      return 'UPDATEREADY';
    case ApplicationCache.OBSOLETE: // OBSOLETE == 5
      return 'OBSOLETE';
    default:
      return 'UNKNOWN CACHE STATUS';
  }
  ;
}
