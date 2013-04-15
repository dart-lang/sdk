library webdriver_test;
import 'dart:async' show getAttachedStackTrace;
import 'package:webdriver/webdriver.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

WebDriver web_driver;

/**
 * These tests are not expected to be run as part of normal automated testing,
 * as they are slow and they have external dependencies.
 */
main() {
  useVMConfiguration();

  var web_driver = new WebDriver('localhost', 4444, '/wd/hub');
  var session = null;

  var exceptionHandler = (error) {
    var trace = getAttachedStackTrace(error);
    String traceString = trace == null ? "" : trace.toString();
    if (error is TestFailure) {
      currentTestCase.fail(error.message, traceString);
    } else {
      currentTestCase.error("Unexpected error: ${error}", traceString);
    }
    if (session != null) {
      var s = session;
      session = null;
      s.close();
    }
  };

  group('Sessionless tests', () {
    test('Get status', () {
      return web_driver.getStatus()
          .then((status) {
            expect(status['sessionId'], isNull);
          })
          .catchError(exceptionHandler);
    });
  });

  group('Basic session tests', () {
    test('Create session/get capabilities', () {
      return web_driver.newSession('chrome')
          .then((_session) {
            expect(_session, isNotNull);
            session = _session;
            return session.getCapabilities();
          })
          .then((capabilities) {
            expect(capabilities, isNotNull);
            expect(capabilities['browserName'], equals('chrome'));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });

    test('Create and get multiple sessions', () {
      var session2 = null;
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return web_driver.newSession('chrome');
          })
          .then((_session) {
            session2 = _session;
            return web_driver.getSessions();
          })
          .then((sessions) {
            expect(sessions.length, greaterThanOrEqualTo(2));
            return session2.close();
          })
          .then((_) {
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });

    test('Set/get url', () {
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.getUrl();
          })
          .then((u) {
            expect(u, equals('http://translate.google.com/'));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });

    test('Navigation', () {
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.setUrl('http://www.google.com');
          })
          .then((_) {
            return session.navigateBack();
          })
          .then((_) {
            return session.getUrl();
          })
          .then((u) {
            expect(u, equals('http://translate.google.com/'));
            return session.navigateForward();
          })
          .then((_) {
            return session.getUrl();
          })
          .then((url) {
            expect(url, equals('http://www.google.com/'));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });

    test('Take a Screen shot', () {
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.getScreenshot();
          })
          .then((image) {
            expect(image.length, greaterThan(10000));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });
  });

  group('Window tests', () {
    test('Window position and size', () {
      // We don't validate the results. Setting size and position is flaky.
      // I tried with the Selenium python client code and found it had the
      // same issue, so this is not a bug in the Dart code.
      var window;
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return session.getWindow();
          })
          .then((_window) {
            window = _window;
            return window.setSize(220, 400);
          })
          .then((_) {
            return window.getSize();
          })
          .then((ws) {
            return window.setPosition(100, 80);
          })
          .then((_) {
            return window.getPosition();
          })
          .then((wp) {
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });
  });

  group('Cookie tests', () {
    test('Create/query/delete', () {
      var window;
      var numcookies;
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            // Must go to a web page first to set a cookie.
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.getCookies();
          })
          .then((cookies) {
            numcookies = cookies.length;
            return session.setCookie({ 'name': 'foo', 'value': 'bar'});
          })
          .then((_) {
            return session.getCookies();
          })
          .then((cookies) {
            expect(cookies.length, equals(numcookies + 1));
            expect(cookies, someElement(allOf(
                containsPair('name', 'foo'),
                containsPair('value', 'bar'))));
            return session.deleteCookie('foo');
          })
          .then((_) {
            return session.getCookies();
          })
          .then((cookies) {
            expect(cookies.length, numcookies);
            expect(cookies, everyElement(isNot(containsPair('name', 'foo'))));
            return session.deleteCookie('foo');
          })
          .then((_) {
            return session.getCookies();
          })
          .then((cookies) {
            expect(cookies.length, numcookies);
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });
  });

  group('Storage tests', () {
    test('Local Storage Create/query/delete', () {
      var window;
      var numkeys;
      return web_driver.newSession('firefox', { 'webStorageEnabled': true })
          .then((_session) {
            session = _session;
            return session.getCapabilities();
          })
          .then((capabilities) {
            expect(capabilities, isNotNull);
            expect(capabilities['webStorageEnabled'], isTrue);
            // Must go to a web page first.
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.getLocalStorageKeys();
          })
          .then((keys) {
            numkeys = keys.length;
            return session.setLocalStorageItem('foo', 'bar');
          })
          .then((_) {
            return session.getLocalStorageKeys();
          })
          .then((keys) {
            expect(keys.length, equals(numkeys + 1));
            expect(keys, someElement(equals('foo')));
            return session.getLocalStorageCount();
          })
          .then((count) {
            expect(count, equals(numkeys + 1));
            return session.getLocalStorageValue('foo');
          })
          .then((value) {
            expect(value, equals('bar'));
            return session.setLocalStorageItem('bar', 'foo');
          })
          .then((_) {
            return session.getLocalStorageKeys();
          })
          .then((keys) {
            expect(keys.length, equals(numkeys + 2));
            expect(keys, someElement(equals('bar')));
            expect(keys, someElement(equals('foo')));
            return session.deleteLocalStorageValue('foo');
          })
          .then((_) {
            return session.getLocalStorageKeys();
          })
          .then((keys) {
            expect(keys.length, equals(numkeys + 1));
            expect(keys, everyElement(isNot(equals('foo'))));
            return session.setLocalStorageItem('foo', 'bar');
          })
          .then((_) {
            return session.clearLocalStorage();
          })
          .then((_) {
            return session.getLocalStorageKeys();
          })
          .then((keys) {
            expect(keys.length, isZero);
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });

    test('Session Storage Create/query/delete', () {
      var window;
      var numkeys;
      return web_driver.newSession('chrome', { 'webStorageEnabled': true })
          .then((_session) {
            session = _session;
            // Must go to a web page first.
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.getSessionStorageKeys();
          })
          .then((keys) {
            numkeys = keys.length;
            return session.setSessionStorageItem('foo', 'bar');
          })
          .then((_) {
            return session.getSessionStorageKeys();
          })
          .then((keys) {
            expect(keys.length, equals(numkeys + 1));
            expect(keys, someElement(equals('foo')));
            return session.getSessionStorageCount();
          })
          .then((count) {
            expect(count, equals(numkeys + 1));
            return session.getSessionStorageValue('foo');
          })
          .then((value) {
            expect(value, equals('bar'));
            return session.deleteSessionStorageValue('foo');
          })
          .then((_) {
            return session.getSessionStorageKeys();
          })
          .then((keys) {
            expect(keys.length, equals(numkeys));
            expect(keys, everyElement(isNot(equals('foo'))));
            return session.setSessionStorageItem('foo', 'bar');
          })
          .then((_) {
            return session.clearSessionStorage();
          })
          .then((_) {
            return session.getSessionStorageKeys();
          })
          .then((keys) {
            expect(keys.length, isZero);
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
        });

  });

  group('Script tests', () {
    // This test is just timing out eventually with a 500 response.

    test('Sync script', () {
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return session.setUrl('http://translate.google.com');
          })
          .then((_) {
            return session.execute('return arguments[0] * arguments[1];',
                [2, 3]);
          })
          .then((value) {
            expect(value, equals(6));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });
  });

  group('Element tests', () {
    test('Elements', () {
      var w;
      return web_driver.newSession('chrome')
          .then((_session) {
            session = _session;
            return session.setUrl('http://duckduckgo.com');
          })
          .then((_) {
            return session.findElement('id', 'search_form_input_homepage');
          })
          .then((_w) {
            w = _w['ELEMENT'];
            return session.sendKeyStrokesToElement(w,
                [ 'g', 'o', 'o', 'g', 'l', 'e' ]);
          })
          .then((_) {
            return session.submit(w);
          })
          .then((_) {
            return session.findElements('class name',
                'links_zero_click_disambig');
          })
          .then((divs) {
            expect(divs.length, greaterThan(0));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
    });
  });

  group('Log tests', () {
    // Currently, getLogTypes returns a 404, and attempts to get the
    // logs either return 500 with 'Unknown log type' or 500 with
    // 'Unable to convert logEntries'.

    test('Log retrieval', () {
      return web_driver.newSession('firefox')
          .then((_session) {
            session = _session;
            return session.getLogTypes();
          })
          .then((logTypes) {
            expect(logTypes, someElement(equals('client')));
            expect(logTypes, someElement(equals('server')));
            return session.getLogs('driver');
          })
          .then((logs) {
            expect(logs.length, greaterThan(0));
            return session.close();
          })
          .then((_) {
            session = null;
          })
          .catchError(exceptionHandler);
        });
  });

  group('Cleanup', () {
    test('Cleanup', () {
      web_driver = null;
      if (session != null) {
        var s = session;
        session = null;
        s.close();
      }
    });
  });
}

