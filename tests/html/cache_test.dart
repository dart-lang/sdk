library CacheTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('ApplicationCache', () {
    ApplicationCache appCache = window.applicationCache;
    expect(cacheStatusToString(appCache.status), equals("UNCACHED"));
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
    case ApplicationCache.UPDATEREADY:  // UPDATEREADY == 4
      return 'UPDATEREADY';
    case ApplicationCache.OBSOLETE: // OBSOLETE == 5
      return 'OBSOLETE';
    default:
      return 'UNKNOWN CACHE STATUS';
  };
}
