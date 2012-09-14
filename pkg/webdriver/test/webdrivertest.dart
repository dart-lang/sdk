#library('webdriver_test');
#import('../webdriver.dart');
#import('../../../pkg/unittest/unittest.dart');

WebDriver web_driver;

/**
 * These tests are not expected to be run as part of normal automated testing,
 * as they are slow, many of them do not yet work due to WebDriver limitations,
 * and they have external dependencies. Nontheless it is useful to keep them
 * here for manual testing.
 */
main() {
  var web_driver = new WebDriver('localhost', 4444, '/wd/hub');
  var session = null;
  var completionCallback;

  var exceptionHandler = (e) {
    print('Handled: ${e.toString()}');
    if (session != null) {
      session.close().then((_){
        session = null;
        config.handleExternalError(e, 'Unexpected failure');
      });
    }
    return true;
  };

  group('Sessionless tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    test('Get status', () {
      Future f = web_driver.getStatus();
      f.handleException(exceptionHandler);
      f.then((status) {
        expect(status['sessionId'], isNull);
        completionCallback();
      });
    });
  });

  group('Basic session tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    test('Create session/get capabilities', () {
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.getCapabilities();
      }).chain((capabilities) {
        expect(capabilities['browserName'], equals('chrome'));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });

    test('Create and get multiple sessions', () {
      Future f = web_driver.newSession('chrome');
      var session2 = null;
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return web_driver.newSession('firefox');
      }).chain((_session) {
        session2 = _session;
        return web_driver.getSessions();
      }).chain((sessions) {
        expect(sessions.length, greaterThanOrEqualTo(2));
        return session2.close();
      }).chain((_) {
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });

    test('Set/get url', () {
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.getUrl();
      }).chain((u) {
        expect(u, equals('http://translate.google.com/'));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });

    test('Navigation', () {
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.setUrl('http://www.google.com');
      }).chain((_) {
        return session.navigateBack();
      }).chain((_) {
        return session.getUrl();
      }).chain((u) {
        expect(u, equals('http://translate.google.com/'));
        return session.navigateForward();
      }).chain((_) {
        return session.getUrl();
      }).chain((url) {
        expect(url, equals('http://www.google.com/'));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });

    test('Take a Screen shot', () {
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.getScreenshot();
      }).chain((image) {
        expect(image.length, greaterThan(10000));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });
  });

  group('Window tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    test('Window position and size', () {
      var window;
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.getWindow();
      }).chain((_window) {
        window = _window;
        return window.setSize(200, 100);
      }).chain((_) {
        return window.getSize();
      }).chain((ws) {
        expect(ws['width'], equals(200));
        expect(ws['height'], equals(100));
        return window.setPosition(100, 80);
      }).chain((_) {
        return window.getPosition();
      }).chain((wp) {
        expect(wp['x'], equals(100));
        expect(wp['y'], equals(80));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });
  });

  group('Cookie tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    test('Create/query/delete', () {
      var window;
      var numcookies;
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        // Must go to a web page first to set a cookie.
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.getCookies();
      }).chain((cookies) {
        numcookies = cookies.length;
        return session.setCookie({ 'name': 'foo', 'value': 'bar'});
      }).chain((_) {
        return session.getCookies();
      }).chain((cookies) {
        expect(cookies.length, equals(numcookies + 1));
        expect(cookies, someElement(allOf(
            containsPair('name', 'foo'),
            containsPair('value', 'bar'))));
        return session.deleteCookie('foo');
      }).chain((_) {
        return session.getCookies();
      }).chain((cookies) {
        expect(cookies.length, numcookies);
        expect(cookies, everyElement(isNot(containsPair('name', 'foo'))));
        return session.deleteCookie('foo');
      }).chain((_) {
        return session.getCookies();
      }).chain((cookies) {
        expect(cookies.length, numcookies);
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });
  });

  group('Storage tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    // Storage tests are return 500 errors. This seems to be a bug in
    // the remote driver.

    test('Local Storage Create/query/delete', () {
      var window;
      var numkeys;
      Future f = web_driver.newSession('htmlunit', { 'webStorageEnabled': true });
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        // Must go to a web page first.
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.getLocalStorageKeys();
      }).chain((keys) {
        print(keys);
        numkeys = keys.length;
        return session.setLocalStorageItem('foo', 'bar');
      }).chain((_) {
        return session.getLocalStorageKeys();
      }).chain((keys) {
        expect(keys.length, equals(numkeys + 1));
        expect(keys, someElement(equals('foo')));
        return session.getLocalStorageCount();
      }).chain((count) {
        expect(count, equals(numkeys + 1));
        return session.getLocalStorageValue('foo');
      }).chain((value) {
        expect(value, equals('bar'));
        return session.deleteLocalStorageValue('foo');
      }).chain((_) {
        return session.getLocalStorageKeys();
      }).chain((keys) {
        expect(keys.length, equals(numkeys));
        expect(keys, everyElement(isNot(equals('foo'))));
        return session.setLocalStorageItem('foo', 'bar');
      }).chain((_) {
        return session.clearLocalStorage();
      }).chain((_) {
        return session.getLocalStorageKeys();
      }).chain((keys) {
        expect(keys.length, isZero);
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });

    test('Session Storage Create/query/delete', () {
      var window;
      var numkeys;
      Future f = web_driver.newSession('chrome', { 'webStorageEnabled': true });
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        // Must go to a web page first.
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.getSessionStorageKeys();
      }).chain((keys) {
        print(keys);
        numkeys = keys.length;
        return session.setSessionStorageItem('foo', 'bar');
      }).chain((_) {
        return session.getSessionStorageKeys();
      }).chain((keys) {
        expect(keys.length, equals(numkeys + 1));
        expect(keys, someElement(equals('foo')));
        return session.getSessionStorageCount();
      }).chain((count) {
        expect(count, equals(numkeys + 1));
        return session.getSessionStorageValue('foo');
      }).chain((value) {
        expect(value, equals('bar'));
        return session.deleteSessionStorageValue('foo');
      }).chain((_) {
        return session.getSessionStorageKeys();
      }).chain((keys) {
        expect(keys.length, equals(numkeys));
        expect(keys, everyElement(isNot(equals('foo'))));
        return session.setSessionStorageItem('foo', 'bar');
      }).chain((_) {
        return session.clearSessionStorage();
      }).chain((_) {
        return session.getSessionStorageKeys();
      }).chain((keys) {
        expect(keys.length, isZero);
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });

  });

  group('Script tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    // This test is just timing out eventually with a 500 response.

    test('Sync script', () {
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.setUrl('http://translate.google.com');
      }).chain((_) {
        return session.execute('function(x, y) { return x * y; }', [2, 3]);
      }).chain((value) {
        expect(value, equals(6));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });
  });

  group('Element tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    test('Elements', () {
      var w;
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
        return session.setUrl('http://duckduckgo.com');
      }).chain((_) {
        return session.findElement('id', 'search_form_input_homepage');
      }).chain((_w) {
        print(_w);
        w = _w['ELEMENT'];
        return session.sendKeyStrokesToElement(w,
            [ 'g', 'o', 'o', 'g', 'l', 'e' ]);
      }).chain((_) {
        return session.submit(w);
      }).chain((_) {
        return session.findElements('class name', 'links_zero_click_disambig');
      }).chain((divs) {
        expect(divs.length, greaterThan(0));
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });
  });

  group('Log tests', () {
    setUp(() {
      completionCallback = expectAsync0((){
      });
    });

    // Currently, getLogTypes returns a 404, and attempts to get the
    // logs either return 500 with 'Unknown log type' or 500 with
    // 'Unable to convert logEntries'.

    test('Log retrieval', () {
      Future f = web_driver.newSession('chrome');
      f.handleException(exceptionHandler);
      f.chain((_session) {
        session = _session;
          return session.getLogTypes();
      }).chain((logTypes) {
        //print(logTypes);
        return session.getLogs('driver');
      }).chain((logs) {
        //print(logs);
        return session.close();
      }).then((_) {
        session = null;
        completionCallback();
      });
    });
  });
}

