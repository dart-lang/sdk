#library('CacheTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('ApplicationCache', () {
    DOMApplicationCache appCache = window.applicationCache;
    expect(cacheStatusToString(appCache.status), equals("UNCACHED"));
  });
}

String cacheStatusToString(int status) {
  switch (status) {
    case DOMApplicationCache.UNCACHED: // UNCACHED == 0
      return 'UNCACHED';
    case DOMApplicationCache.IDLE: // IDLE == 1
      return 'IDLE';
    case DOMApplicationCache.CHECKING: // CHECKING == 2
      return 'CHECKING';
    case DOMApplicationCache.DOWNLOADING: // DOWNLOADING == 3
      return 'DOWNLOADING';
    case DOMApplicationCache.UPDATEREADY:  // UPDATEREADY == 4
      return 'UPDATEREADY';
    case DOMApplicationCache.OBSOLETE: // OBSOLETE == 5
      return 'OBSOLETE';
    default:
      return 'UNKNOWN CACHE STATUS';
  };
}
