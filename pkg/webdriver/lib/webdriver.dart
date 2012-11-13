// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library webdriver;

import 'dart:json';
import 'dart:uri';
import 'dart:io';
import 'dart:math';

part 'src/base64decoder.dart';

/**
 * WebDriver bindings for Dart.
 *
 * These bindings are based on the WebDriver JSON wire protocol spec
 * (http://code.google.com/p/selenium/wiki/JsonWireProtocol). Not
 * all of these commands are implemented yet by WebDriver itself.
 * Nontheless this is a complete implementation of the spec as the
 * unsupported commands may be supported in the future. Currently,
 * there are known issues with local and session storage, script
 * execution, and log access.
 *
 * To use these bindings, the Selenium standalone server must be running.
 * You can download it at http://code.google.com/p/selenium/downloads/list.
 *
 * There are a number of commands that use ids to access page elements.
 * These ids are not the HTML ids; they are opaque ids internal to
 * WebDriver. To get the id for an element you would first need to do
 * a search, get the results, and extract the WebDriver id from the returned
 * [Map] using the 'ELEMENT' key. For example:
 *
 *     String id;
 *     WebDriverSession session;
 *     Future f = web_driver.newSession('chrome');
 *     f.chain((_session) {
 *       session = _session;
 *       return session.setUrl('http://my.web.site.com');
 *    }).chain((_) {
 *      return session.findElement('id', 'username');
 *    }).chain((element) {
 *      id = element['ELEMENT'];
 *      return session.sendKeyStrokesToElement(id,
 *          [ 'j', 'o', 'e', ' ', 'u', 's', 'e', 'r' ]);
 *    }).chain((_) {
 *      return session.submit(id);
 *    }).chain((_) {
 *      return session.close();
 *    }).then((_) {
 *      session = null;
 *    });
 */

void writeStringToFile(String fileName, String contents) {
  var file = new File(fileName);
  var ostream = file.openOutputStream(FileMode.WRITE);
  ostream.writeString(contents);
  ostream.close();
}

void writeBytesToFile(String fileName, List<int> contents) {
  var file = new File(fileName);
  var ostream = file.openOutputStream(FileMode.WRITE);
  ostream.write(contents);
  ostream.close();
}

class WebDriverError {
  static List _errorTypes = null;
  static List _errorDetails = null;
  int statusCode;
  String type;
  String message;
  String details;
  String results;

  WebDriverError(this.statusCode, this.message, [this.results = '']) {
    /** These correspond to WebDrive exception types. */
    if (_errorTypes == null) {
      _errorTypes = [
        null,
        'IndexOutOfBounds',
        'NoCollection',
        'NoString',
        'NoStringLength',
        'NoStringWrapper',
        'NoSuchDriver',
        'NoSuchElement',
        'NoSuchFrame',
        'UnknownCommand',
        'ObsoleteElement',
        'ElementNotDisplayed',
        'InvalidElementState',
        'Unhandled',
        'Expected',
        'ElementNotSelectable',
        'NoSuchDocument',
        'UnexpectedJavascript',
        'NoScriptResult',
        'XPathLookup',
        'NoSuchCollection',
        'TimeOut',
        'NullPointer',
        'NoSuchWindow',
        'InvalidCookieDomain',
        'UnableToSetCookie',
        'UnexpectedAlertOpen',
        'NoAlertOpen',
        'ScriptTimeout',
        'InvalidElementCoordinates',
        'IMENotAvailable',
        'IMEEngineActivationFailed',
        'InvalidSelector',
        'SessionNotCreatedException',
        'MoveTargetOutOfBounds'
      ];
      // Explanations of the eror types. In thoses cases where the
      // explanation is the same as the type (e.g. NoCollection), that is an
      // error type used by an old version of the IE driver and is deprecated.
      _errorDetails = [
        null,
        'IndexOutOfBounds',
        'NoCollection',
        'NoString',
        'NoStringLength',
        'NoStringWrapper',
        'NoSuchDriver',
        'An element could not be located on the page using the given '
            'search parameters.',
        'A request to switch to a frame could not be satisfied because the '
            'frame could not be found.',
        'The requested resource could not be found, or a request was '
            'received using an HTTP method that is not supported by the '
            'mapped resource.',
        'An element command failed because the referenced element is no '
            'longer attached to the DOM.',
        'An element command could not be completed because the element '
            'is not visible on the page.',
        'An element command could not be completed because the element is in '
            'an invalid state (e.g. attempting to click a disabled element).',
        'An unknown server-side error occurred while processing the command.',
        'Expected',
        'An attempt was made to select an element that cannot be selected.',
        'NoSuchDocument',
        'An error occurred while executing user supplied JavaScript.',
        'NoScriptResult',
        'An error occurred while searching for an element by XPath.',
        'NoSuchCollection',
        'An operation did not complete before its timeout expired.',
        'NullPointer',
        'A request to switch to a different window could not be satisfied '
            'because the window could not be found.',
        'An illegal attempt was made to set a cookie under a different '
            'domain than the current page.',
        'A request to set a cookie\'s value could not be satisfied.',
        'A modal dialog was open, blocking this operation.',
        'An attempt was made to operate on a modal dialog when one was '
            'not open.',
        'A script did not complete before its timeout expired.',
        'The coordinates provided to an interactions operation are invalid.',
        'IME was not available.',
        'An IME engine could not be started.',
        'Argument was an invalid selector (e.g. XPath/CSS).',
        'A new session could not be created.',
        'Target provided for a move action is out of bounds.'
      ];
    }
    if (statusCode < 0 || statusCode > 32) {
      type = 'External';
      details = '';
    } else {
      type = _errorTypes[statusCode];
      details = _errorDetails[statusCode];
    }
  }

  String toString() {
    return '$statusCode $type: $message $results\n$details';
  }
}

/**
 * Base class for all WebDriver request classes. This class wraps up
 * an URL prefix (host, port, and initial path), and provides a client
 * function for doing HTTP requests with JSON payloads.
 */
class WebDriverBase {

  String _host;
  int _port;
  String _path;
  String _url;

  String get path => _path;
  String get url => _url;

  /**
   * The default URL for WebDriver remote server is
   * http://localhost:4444/wd/hub.
   */
  WebDriverBase.fromUrl([this._url = 'http://localhost:4444/wd/hub']) {
    // Break out the URL components.
    var re = const RegExp('[^:/]+://([^/]+)(/.*)');
    var matches = re.firstMatch(_url);
    _host = matches[1];
    _path = matches[2];
    var idx = _host.indexOf(':');
    if (idx >= 0) {
      _port = parseInt(_host.substring(idx+1));
      _host = _host.substring(0, idx);
    } else {
      _port = 80;
    }
  }

  WebDriverBase([
      this._host = 'localhost',
      this._port = 4444,
      this._path = '/wd/hub']) {
    _url = 'http://$_host:$_port$_path';
  }

  /**
   * Execute a request to the WebDriver server. [http_method] should be
   * one of 'GET', 'POST', or 'DELETE'. [command] is the text to append
   * to the base URL path to get the full URL. [params] are the additional
   * parameters. If a [List] or [Map] they will be posted as JSON parameters.
   * If a number or string, "/params" is appended to the URL.
   */
  void _serverRequest(String http_method, String command, Completer completer,
                      [List successCodes, Map params, Function customHandler]) {
    var status = 0;
    var results = null;
    var message = null;
    if (successCodes == null) {
      successCodes = [ 200, 204 ];
    }
    try {
      if (params != null && params is List && http_method != 'POST') {
        throw new Exception(
          'The http method called for ${command} is ${http_method} but it has '
          'to be POST if you want to pass the JSON params '
          '${JSON.stringify(params)}');
      }

      var path = command;
      if (params != null && (params is num || params is String)) {
        path = '$path/$params';
      }

      var client = new HttpClient();
      var connection = client.open(http_method, _host, _port, path);

      connection.onRequest = (r) {
        r.headers.add(HttpHeaders.ACCEPT, "application/json");
        r.headers.add(
            HttpHeaders.CONTENT_TYPE, 'application/json;charset=UTF-8');
        OutputStream s = r.outputStream;
        if (params != null && params is Map) {
          s.writeString(JSON.stringify(params));
        }
        s.close();
      };
      connection.onError = (e) {
        if (completer != null) {
          completer.completeException(new WebDriverError(-1, e));
          completer = null;
        }
      };
      connection.followRedirects = false;
      connection.onResponse = (r) {
        StringInputStream s = new StringInputStream(r.inputStream);
        StringBuffer sbuf = new StringBuffer();
        s.onData = () {
          var data = s.read();
          if (data != null) {
            sbuf.add(data);
          }
        };
        s.onClosed = () {
          var value = null;
          results  = sbuf.toString().trim();
          // For some reason we get a bunch of NULs on the end
          // of the text and the JSON parser blows up on these, so
          // strip them. We have to do this the hard way as
          // replaceAll('\0', '') does not work.
          // These NULs can be seen in the TCP packet, so it is not
          // an issue with character encoding; it seems to be a bug
          // in WebDriver stack.
          for (var i = results.length; --i >= 0;) {
            var code = results.charCodeAt(i);
            if (code != 0) {
              results = results.substring(0, i+1);
              break;
            }
          }
          if (successCodes.indexOf(r.statusCode) < 0) {
            throw 'Unexpected response ${r.statusCode}';
          }
          if (status == 0 && results.length > 0) {
            // 4xx responses send plain text; others send JSON.
            if (r.statusCode < 400) {
              results = JSON.parse(results);
              status = results['status'];
            }
            if (results is Map && (results as Map).containsKey('value')) {
              value = results['value'];
            }
            if (value is Map && value.containsKey('message')) {
              message = value['message'];
            }
          }
          if (status == 0) {
            if (customHandler != null) {
              customHandler(r, value);
            } else if (completer != null) {
              completer.complete(value);
            }
          }
        };
      };
    } catch (e, s) {
      completer.completeException(
          new WebDriverError(-1, e), s);
      completer = null;
    }
  }

  Future _simpleCommand(method, extraPath, [successCodes, params]) {
    var completer = new Completer();
    _serverRequest(method, '${_path}/$extraPath', completer,
          successCodes, params: params);
    return completer.future;
  }

  Future _get(extraPath, [successCodes]) =>
      _simpleCommand('GET', extraPath, successCodes);

  Future _post(extraPath, [successCodes, params]) =>
      _simpleCommand('POST', extraPath, successCodes, params);

  Future _delete(extraPath, [successCodes]) =>
      _simpleCommand('DELETE', extraPath, successCodes);
}

class WebDriver extends WebDriverBase {

  WebDriver(host, port, path) : super(host, port, path);

  /**
   * Create a new session. The server will attempt to create a session that
   * most closely matches the desired and required capabilities. Required
   * capabilities have higher priority than desired capabilities and must be
   * set for the session to be created.
   *
   * The capabilities are:
   *
   * - browserName (String)  The name of the browser being used; should be one
   *   of chrome|firefox|htmlunit|internet explorer|iphone.
   *
   * - version (String) The browser version, or the empty string if unknown.
   *
   * - platform (String) A key specifying which platform the browser is
   *   running on. This value should be one of WINDOWS|XP|VISTA|MAC|LINUX|UNIX.
   *   When requesting a new session, the client may specify ANY to indicate
   *   any available platform may be used.
   *
   * - javascriptEnabled (bool) Whether the session supports executing user
   *   supplied JavaScript in the context of the current page.
   *
   * - takesScreenshot (bool) Whether the session supports taking screenshots
   *   of the current page.
   *
   * - handlesAlerts (bool) Whether the session can interact with modal popups,
   *   such as window.alert and window.confirm.
   *
   * - databaseEnabled (bool) Whether the session can interact database storage.
   *
   * - locationContextEnabled (bool) Whether the session can set and query the
   *   browser's location context.
   *
   * - applicationCacheEnabled (bool) Whether the session can interact with
   *   the application cache.
   *
   * - browserConnectionEnabled (bool) Whether the session can query for the
   *   browser's connectivity and disable it if desired.
   *
   * - cssSelectorsEnabled (bool) Whether the session supports CSS selectors
   *   when searching for elements.
   *
   * - webStorageEnabled (bool) Whether the session supports interactions with
   *   storage objects.
   *
   * - rotatable (bool) Whether the session can rotate the current page's
   *   current layout between portrait and landscape orientations (only applies
   *   to mobile platforms).
   *
   * - acceptSslCerts (bool) Whether the session should accept all SSL certs
   *   by default.
   *
   * - nativeEvents (bool) Whether the session is capable of generating native
   *   events when simulating user input.
   *
   * - proxy (proxy object) Details of any proxy to use. If no proxy is
   *   specified, whatever the system's current or default state is used.
   *
   * The format of the proxy object is:
   *
   * - proxyType (String) The type of proxy being used. Possible values are:
   *
   *   direct - A direct connection - no proxy in use,
   *
   *   manual - Manual proxy settings configured,
   *
   *   pac - Proxy autoconfiguration from a URL),
   *
   *   autodetect (proxy autodetection, probably with WPAD),
   *
   *   system - Use system settings
   *
   * - proxyAutoconfigUrl (String) Required if proxyType == pac, Ignored
   *   otherwise. Specifies the URL to be used for proxy autoconfiguration.
   *
   * - ftpProxy, httpProxy, sslProxy (String) (Optional, Ignored if
   *   proxyType != manual) Specifies the proxies to be used for FTP, HTTP
   *   and HTTPS requests respectively. Behaviour is undefined if a request
   *   is made, where the proxy for the particular protocol is undefined,
   *   if proxyType is manual.
   *
   * Potential Errors: SessionNotCreatedException (if a required capability
   * could not be set).
   */
  Future<WebDriverSession> newSession([
      browser = 'chrome', Map additional_capabilities]) {
    var completer = new Completer();
    if (additional_capabilities == null) {
      additional_capabilities = {};
    }

    additional_capabilities['browserName'] = browser;

    _serverRequest('POST', '${_path}/session', null, [ 302 ],
        customHandler: (r, v) {
          var url = r.headers.value(HttpHeaders.LOCATION);
          var session = new WebDriverSession.fromUrl(url);
          completer.complete(session);
        }, params: { 'desiredCapabilities': additional_capabilities });
    return completer.future;
  }

  /** Get the set of currently active sessions. */
  Future<List<WebDriverSession>> getSessions() {
    var completer = new Completer();
    _get('sessions', (result) {
      var _sessions = [];
      for (var session in result) {
        _sessions.add(new WebDriverSession.fromUrl(
          '${this._path}/session/${session["id"]}'));
      }
      completer.complete(_sessions);
    });
    return completer.future;
  }

  /** Query the server's current status. */
  Future<Map> getStatus() => _get('status');
}

class WebDriverWindow extends WebDriverBase {
  WebDriverWindow.fromUrl(url) : super.fromUrl(url);

  /** Get the window size. */
  Future<Map> getSize() => _get('size');

  /**
   * Set the window size.
   *
   * Potential Errors:
   *   NoSuchWindow - If the specified window cannot be found.
   */
  Future<String> setSize(int width, int height) =>
      _post('size', params: { 'width': width, 'height': height });

  /** Get the window position. */
  Future<Map> getPosition() => _get('position');

  /**
   * Set the window position.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future setPosition(int x, int y) =>
      _post('position', params: { 'x': x, 'y': y });

  /** Maximize the specified window if not already maximized. */
  Future maximize() => _post('maximize');
}

class WebDriverSession extends WebDriverBase {
  WebDriverSession.fromUrl(url) : super.fromUrl(url);

  /** Close the session. */
  Future close() => _delete('');

  /** Get the session capabilities. See [newSession] for details. */
  Future<Map> getCapabilities() => _get('');

  /**
   * Configure the amount of time in milliseconds that a script can execute
   * for before it is aborted and a Timeout error is returned to the client.
   */
  Future setScriptTimeout(t) =>
      _post('timeouts', params: { 'type': 'script', 'ms': t });

  /*Future<String> setImplicitWaitTimeout(t) =>
      simplePost('timeouts', { 'type': 'implicit', 'ms': t });*/

  /**
   * Configure the amount of time in milliseconds that a page can load for
   * before it is aborted and a Timeout error is returned to the client.
   */
  Future setPageLoadTimeout(t) =>
      _post('timeouts', params: { 'type': 'page load', 'ms': t });

  /**
   * Set the amount of time, in milliseconds, that asynchronous scripts
   * executed by /session/:sessionId/execute_async are permitted to run
   * before they are aborted and a Timeout error is returned to the client.
   */
  Future setAsyncScriptTimeout(t) =>
      _post('timeouts/async_script', params: { 'ms': t });

  /**
   * Set the amount of time the driver should wait when searching for elements.
   * When searching for a single element, the driver should poll the page until
   * an element is found or the timeout expires, whichever occurs first. When
   * searching for multiple elements, the driver should poll the page until at
   * least one element is found or the timeout expires, at which point it should
   * return an empty list.
   *
   * If this command is never sent, the driver should default to an implicit
   * wait of 0ms.
   */
  Future setImplicitWaitTimeout(t) =>
      _post('timeouts/implicit_wait', params: { 'ms': t });

  /**
   * Retrieve the current window handle.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getWindowHandle() => _get('window_handle');

  /**
   * Retrieve a [WebDriverWindow] for the specified window. We don't
   * have to use a Future here but do so to be consistent.
   */
  Future<WebDriverWindow> getWindow([handle = 'current']) {
    var completer = new Completer();
    completer.complete(new WebDriverWindow.fromUrl('${_url}/window/$handle'));
    return completer.future;
  }

  /** Retrieve the list of all window handles available to the session. */
  Future<List<String>> getWindowHandles() => _get('window_handles');

  /**
   * Retrieve the URL of the current page.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getUrl() => _get('url');

  /**
   * Navigate to a new URL.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future setUrl(String url) => _post('url', params: { 'url': url });

  /**
   * Navigate forwards in the browser history, if possible.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future navigateForward() => _post('forward');

  /**
   * Navigate backwards in the browser history, if possible.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future navigateBack() => _post('back');

  /**
   * Refresh the current page.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future refresh() => _post('refresh');

  /**
   * Inject a snippet of JavaScript into the page for execution in the context
   * of the currently selected frame. The executed script is assumed to be
   * synchronous and the result of evaluating the script is returned to the
   * client.
   *
   * The script argument defines the script to execute in the form of a
   * function body. The value returned by that function will be returned to
   * the client. The function will be invoked with the provided args array
   * and the values may be accessed via the arguments object in the order
   * specified.
   *
   * Arguments may be any JSON-primitive, array, or JSON object. JSON objects
   * that define a WebElement reference will be converted to the corresponding
   * DOM element. Likewise, any WebElements in the script result will be
   * returned to the client as WebElement JSON objects.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference, JavaScriptError.
   */
  Future execute(String script, [List args]) =>
      _post('execute', params: { 'script': script, 'args': args });

  /**
   * Inject a snippet of JavaScript into the page for execution in the context
   * of the currently selected frame. The executed script is assumed to be
   * asynchronous and must signal that it is done by invoking the provided
   * callback, which is always provided as the final argument to the function.
   * The value to this callback will be returned to the client.
   *
   * Asynchronous script commands may not span page loads. If an unload event
   * is fired while waiting for a script result, an error should be returned
   * to the client.
   *
   * The script argument defines the script to execute in the form of a function
   * body. The function will be invoked with the provided args array and the
   * values may be accessed via the arguments object in the order specified.
   * The final argument will always be a callback function that must be invoked
   * to signal that the script has finished.
   *
   * Arguments may be any JSON-primitive, array, or JSON object. JSON objects
   * that define a WebElement reference will be converted to the corresponding
   * DOM element. Likewise, any WebElements in the script result will be
   * returned to the client as WebElement JSON objects.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference, Timeout (controlled
   * by the [setAsyncScriptTimeout] command), JavaScriptError (if the script
   * callback is not invoked before the timout expires).
   */
  Future executeAsync(String script, [List args]) =>
      _post('execute_async', params: { 'script': script, 'args': args });

  /**
   * Take a screenshot of the current page (PNG).
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<List<int>> getScreenshot([fname]) {
    var completer = new Completer();
    var result = _serverRequest('GET', '$_path/screenshot', completer,
        customHandler: (r, v) {
      var image = Base64Decoder.decode(v);
      if (fname != null) {
        writeBytesToFile(fname, image);
      }
      completer.complete(image);
    });
    return completer.future;
  }

  /**
   * List all available IME (Input Method Editor) engines on the machine.
   * To use an engine, it has to be present in this list.
   *
   * Potential Errors: ImeNotAvailableException.
   */
  Future<List<String>> getAvailableImeEngines() =>
      _get('ime/available_engines');

  /**
   * Get the name of the active IME engine. The name string is
   * platform specific.
   *
   * Potential Errors: ImeNotAvailableException.
   */
  Future<String> getActiveImeEngine() => _get('ime/active_engine');

  /**
   * Indicates whether IME input is active at the moment (not if
   * it's available).
   *
   * Potential Errors: ImeNotAvailableException.
   */
  Future<bool> getIsImeActive() => _get('ime/activated');

  /**
   * De-activates the currently-active IME engine.
   *
   * Potential Errors: ImeNotAvailableException.
   */
  Future deactivateIme() => _post('ime/deactivate');

  /**
   * Make an engine that is available (appears on the list returned by
   * getAvailableEngines) active. After this call, the engine will be added
   * to the list of engines loaded in the IME daemon and the input sent using
   * sendKeys will be converted by the active engine. Note that this is a
   * platform-independent method of activating IME (the platform-specific way
   * being using keyboard shortcuts).
   *
   * Potential Errors: ImeActivationFailedException, ImeNotAvailableException.
   */
  Future activateIme(String engine) =>
      _post('ime/activate', params: { 'engine': engine });

  /**
   * Change focus to another frame on the page. If the frame id is null,
   * the server should switch to the page's default content.
   * [id] is the Identifier for the frame to change focus to, and can be
   * a string, number, null, or JSON Object.
   *
   * Potential Errors: NoSuchWindow, NoSuchFrame.
   */
  Future setFrameFocus(id) => _post('frame', params: { 'id': id });

  /**
   * Change focus to another window. The window to change focus to may be
   * specified by [name], which is its server assigned window handle, or
   * the value of its name attribute.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future setWindowFocus(name) =>
      _post('window', params: { 'name': name });

  /**
   * Close the current window.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future closeWindow() => _delete('window');

  /**
   * Retrieve all cookies visible to the current page.
   *
   * The returned List contains Maps with the following keys:
   *
   * 'name' - The name of the cookie.
   *
   * 'value' - The cookie value.
   *
   * The following keys may optionally be present:
   *
   * 'path' - The cookie path.
   *
   * 'domain' - The domain the cookie is visible to.
   *
   * 'secure' - Whether the cookie is a secure cookie.
   *
   * 'expiry' - When the cookie expires, seconds since midnight, 1/1/1970 UTC.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<List<Map>> getCookies() => _get('cookie');

  /**
   * Set a cookie. If the cookie path is not specified, it should be set
   * to "/". Likewise, if the domain is omitted, it should default to the
   * current page's domain. See [getCookies] for the structure of a cookie
   * Map.
   */
  Future setCookie(Map cookie) =>
      _post('cookie', params: { 'cookie': cookie });

  /**
   * Delete all cookies visible to the current page.
   *
   * Potential Errors: InvalidCookieDomain (the cookie's domain is not
   * visible from the current page), NoSuchWindow, UnableToSetCookie (if
   * attempting to set a cookie on a page that does not support cookies,
   * e.g. pages with mime-type text/plain).
   */
  Future deleteCookies() => _delete('cookie');

  /**
   * Delete the cookie with the given [name]. This command should be a no-op
   * if there is no such cookie visible to the current page.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future deleteCookie(String name) => _delete('cookie/$name');

  /**
   * Get the current page source.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getPageSource() => _get('source');

  /**
   * Get the current page title.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getPageTitle() => _get('title');

  /**
   * Search for an element on the page, starting from the document root. The
   * first matching located element will be returned as a WebElement JSON
   * object (a [Map] with an 'ELEMENT' key whose value should be used to
   * identify the element in further requests). The [strategy] should be
   * one of:
   *
   * 'class name' - Returns an element whose class name contains the search
   *    value; compound class names are not permitted.
   *
   * 'css selector' - Returns an element matching a CSS selector.
   *
   * 'id' - Returns an element whose ID attribute matches the search value.
   *
   * 'name' - Returns an element whose NAME attribute matches the search value.
   *
   * 'link text' - Returns an anchor element whose visible text matches the
   *   search value.
   *
   * 'partial link text' - Returns an anchor element whose visible text
   *   partially matches the search value.
   *
   * 'tag name' - Returns an element whose tag name matches the search value.
   *
   * 'xpath' - Returns an element matching an XPath expression.
   *
   * Potential Errors: NoSuchWindow, NoSuchElement, XPathLookupError (if
   * using XPath and the input expression is invalid).
   */
  Future<String> findElement(String strategy, String searchValue) =>
      _post('element', params: { 'using': strategy, 'value' : searchValue });

  /**
   * Search for multiple elements on the page, starting from the document root.
   * The located elements will be returned as WebElement JSON objects. See
   * [findElement] for the locator strategies that each server supports.
   * Elements are be returned in the order located in the DOM.
   *
   * Potential Errors: NoSuchWindow, XPathLookupError.
   */
  Future<List<String>> findElements(String strategy, String searchValue) =>
      _post('elements', params: { 'using': strategy, 'value' : searchValue });

  /**
   * Get the element on the page that currently has focus. The element will
   * be returned as a WebElement JSON object.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getElementWithFocus() => _post('element/active');

  /**
   * Search for an element on the page, starting from element with id [id].
   * The located element will be returned as WebElement JSON objects. See
   * [findElement] for the locator strategies that each server supports.
   *
   * Potential Errors: NoSuchWindow, XPathLookupError.
   */
  Future<String>
      findElementFromId(String id, String strategy, String searchValue) {
    _post('element/$id/element',
              params: { 'using': strategy, 'value' : searchValue });
  }

  /**
   * Search for multiple elements on the page, starting from the element with
   * id [id].The located elements will be returned as WebElement JSON objects.
   * See [findElement] for the locator strategies that each server supports.
   * Elements are be returned in the order located in the DOM.
   *
   * Potential Errors: NoSuchWindow, XPathLookupError.
   */
  Future<List<String>>
      findElementsFromId(String id, String strategy, String searchValue) =>
          _post('element/$id/elements',
              params: { 'using': strategy, 'value' : searchValue });

  /**
   * Click on an element specified by [id].
   *
   * Potential Errors: NoSuchWindow, StaleElementReference, ElementNotVisible
   * (if the referenced element is not visible on the page, either hidden
   * by CSS, or has 0-width or 0-height).
   */
  Future clickElement(String id) => _post('element/$id/click');

  /**
   * Submit a FORM element. The submit command may also be applied to any
   * element that is a descendant of a FORM element.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future submit(String id) => _post('element/$id/submit');

  /** Returns the visible text for the element.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<String> getElementText(String id) => _get('element/$id/text');

  /**
   * Send a sequence of key strokes to an element.
   *
   * Any UTF-8 character may be specified, however, if the server does not
   * support native key events, it will simulate key strokes for a standard
   * US keyboard layout. The Unicode Private Use Area code points,
   * 0xE000-0xF8FF, are used to represent pressable, non-text keys:
   *
   * NULL - U+E000
   *
   * Cancel - U+E001
   *
   * Help - U+E002
   *
   * Backspace - U+E003
   *
   * Tab - U+E004
   *
   * Clear - U+E005
   *
   * Return - U+E006
   *
   * Enter - U+E007
   *
   * Shift - U+E008
   *
   * Control - U+E009
   *
   * Alt - U+E00A
   *
   * Pause - U+E00B
   *
   * Escape - U+E00C
   *
   * Space - U+E00D
   *
   * Pageup - U+E00E
   *
   * Pagedown - U+E00F
   *
   * End - U+E010
   *
   * Home - U+E011
   *
   * Left arrow - U+E012
   *
   * Up arrow - U+E013
   *
   * Right arrow - U+E014
   *
   * Down arrow - U+E015
   *
   * Insert - U+E016
   *
   * Delete - U+E017
   *
   * Semicolon - U+E018
   *
   * Equals - U+E019
   *
   * Numpad 0..9 - U+E01A..U+E023
   *
   * Multiply - U+E024
   *
   * Add - U+E025
   *
   * Separator - U+E026
   *
   * Subtract - U+E027
   *
   * Decimal - U+E028
   *
   * Divide - U+E029
   *
   * F1..F12 - U+E031..U+E03C
   *
   * Command/Meta U+E03D
   *
   * The server processes the key sequence as follows:
   *
   * - Each key that appears on the keyboard without requiring modifiers is
   *   sent as a keydown followed by a key up.
   *
   * - If the server does not support native events and must simulate key
   *   strokes with JavaScript, it will generate keydown, keypress, and keyup
   *   events, in that order. The keypress event is only fired when the
   *   corresponding key is for a printable character.
   *
   * - If a key requires a modifier key (e.g. "!" on a standard US keyboard),
   *   the sequence is: modifier down, key down, key up, modifier up, where
   *   key is the ideal unmodified key value (using the previous example,
   *   a "1").
   *
   * - Modifier keys (Ctrl, Shift, Alt, and Command/Meta) are assumed to be
   *  "sticky"; each modifier is held down (e.g. only a keydown event) until
   *   either the modifier is encountered again in the sequence, or the NULL
   *   (U+E000) key is encountered.
   *
   * - Each key sequence is terminated with an implicit NULL key.
   *   Subsequently, all depressed modifier keys are released (with
   *   corresponding keyup events) at the end of the sequence.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference, ElementNotVisible.
   */
  Future sendKeyStrokesToElement(String id, List<String> keys) =>
      _post('element/$id/value', params: { 'value': keys });

  /**
   * Send a sequence of key strokes to the active element. This command is
   * similar to [sendKeyStrokesToElement] command in every aspect except the
   * implicit termination: The modifiers are not released at the end of the
   * call. Rather, the state of the modifier keys is kept between calls,
   * so mouse interactions can be performed while modifier keys are depressed.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future sendKeyStrokes(List<String> keys) =>
      _post('keys', params: { 'value': keys });

  /**
   * Query for an element's tag name, as a lower-case string.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<String> getElementTagName(String id) => _get('element/$id/name');

  /**
   * Clear a TEXTAREA or text INPUT element's value.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference, ElementNotVisible,
   * InvalidElementState.
   */
  Future clearValue(String id) => _post('/element/$id/clear');

  /**
   * Determine if an OPTION element, or an INPUT element of type checkbox
   * or radiobutton is currently selected.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<bool> isSelected(String id) => _get('element/$id/selected');

  /**
   * Determine if an element is currently enabled.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<bool> isEnabled(String id) => _get('element/$id/enabled');

  /**
   * Get the value of an element's attribute, or null if it has no such
   * attribute.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<String> getAttribute(String id, String attribute) =>
      _get('element/$id/attribute/$attribute');

  /**
   * Test if two element IDs refer to the same DOM element.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<bool> areSameElement(String id, String other) =>
      _get('element/$id/equals/$other');

  /**
   * Determine if an element is currently displayed.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<bool> isDiplayed(String id) => _get('element/$id/displayed');

  /**
   * Determine an element's location on the page. The point (0, 0) refers to
   * the upper-left corner of the page. The element's coordinates are returned
   * as a [Map] object with x and y properties.
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<Map> getElementLocation(String id) => _get('element/$id/location');

  /**
   * Determine an element's size in pixels. The size will be returned as a
   * [Map] object with width and height properties.
   *
   * Potential Errors: NoSuchWindow, StalElementReference.
   */
  Future<Map> getElementSize(String id) => _get('element/$id/size');

  /**
   * Query the value of an element's computed CSS property. The CSS property
   * to query should be specified using the CSS property name, not the
   * JavaScript property name (e.g. background-color instead of
   * backgroundColor).
   *
   * Potential Errors: NoSuchWindow, StaleElementReference.
   */
  Future<String> getElementCssProperty(String id, String property) =>
      _get('element/$id/css/$property');

  /**
   * Get the current browser orientation ('LANDSCAPE' or 'PORTRAIT').
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getBrowserOrientation() => _get('orientation');

  /**
   * Gets the text of the currently displayed JavaScript alert(), confirm(),
   * or prompt() dialog.
   *
   * Potential Errors: NoAlertPresent.
   */
  Future<String> getAlertText() => _get('alert_text');

  /**
   * Sends keystrokes to a JavaScript prompt() dialog.
   *
   * Potential Errors: NoAlertPresent.
   */
  Future sendKeyStrokesToPrompt(String text) =>
      _post('alert_text', params: { 'text': text });

  /**
   * Accepts the currently displayed alert dialog. Usually, this is equivalent
   * to clicking on the 'OK' button in the dialog.
   *
   * Potential Errors: NoAlertPresent.
   */
  Future acceptAlert() => _post('accept_alert');

  /**
   * Dismisses the currently displayed alert dialog. For confirm() and prompt()
   * dialogs, this is equivalent to clicking the 'Cancel' button. For alert()
   * dialogs, this is equivalent to clicking the 'OK' button.
   *
   * Potential Errors: NoAlertPresent.
   */
  Future dismissAlert() => _post('dismiss_alert');

  /**
   * Move the mouse by an offset of the specificed element. If no element is
   * specified, the move is relative to the current mouse cursor. If an
   * element is provided but no offset, the mouse will be moved to the center
   * of the element. If the element is not visible, it will be scrolled
   * into view.
   */
  Future moveTo(String id, int x, int y) =>
      _post('moveto', params: { 'element': id, 'xoffset': x, 'yoffset' : y});

  /**
   * Click a mouse button (at the coordinates set by the last [moveTo] command).
   * Note that calling this command after calling [buttonDown] and before
   * calling [buttonUp] (or any out-of-order interactions sequence) will yield
   * undefined behaviour).
   *
   * [button] should be 0 for left, 1 for middle, or 2 for right.
   */
  Future clickMouse([button = 0]) =>
      _post('click', params: { 'button' : button });

  /**
   * Click and hold the left mouse button (at the coordinates set by the last
   * [moveTo] command). Note that the next mouse-related command that should
   * follow is [buttonDown]. Any other mouse command (such as [click] or
   * another call to [buttonDown]) will yield undefined behaviour.
   *
   * [button] should be 0 for left, 1 for middle, or 2 for right.
   */
  Future buttonDown([button = 0]) =>
      _post('click', params: { 'button' : button });

  /**
   * Releases the mouse button previously held (where the mouse is currently
   * at). Must be called once for every [buttonDown] command issued. See the
   * note in [click] and [buttonDown] about implications of out-of-order
   * commands.
   *
   * [button] should be 0 for left, 1 for middle, or 2 for right.
   */
  Future buttonUp([button = 0]) =>
      _post('click', params: { 'button' : button });

  /** Double-clicks at the current mouse coordinates (set by [moveTo]). */
  Future doubleClick() => _post('doubleclick');

  /** Single tap on the touch enabled device on the element with id [id]. */
  Future touchClick(String id) =>
      _post('touch/click', params: { 'element': id });

  /** Finger down on the screen. */
  Future touchDown(int x, int y) =>
      _post('touch/down', params: { 'x': x, 'y': y });

  /** Finger up on the screen. */
  Future touchUp(int x, int y) =>
      _post('touch/up', params: { 'x': x, 'y': y });

  /** Finger move on the screen. */
  Future touchMove(int x, int y) =>
      _post('touch/move', params: { 'x': x, 'y': y });

  /**
   * Scroll on the touch screen using finger based motion events. If [id] is
   * specified, scrolling will start at a particular screen location.
   */
  Future touchScroll(int xOffset, int yOffset, [String id = null]) {
    if (id == null) {
      return _post('touch/scroll',
          params: { 'xoffset': xOffset, 'yoffset': yOffset });
    } else {
      return _post('touch/scroll',
          params: { 'element': id, 'xoffset': xOffset, 'yoffset': yOffset });
    }
  }

  /** Double tap on the touch screen using finger motion events. */
  Future touchDoubleClick(String id) =>
      _post('touch/doubleclick', params: { 'element': id });

  /** Long press on the touch screen using finger motion events. */
  Future touchLongClick(String id) =>
      _post('touch/longclick', params: { 'element': id });

  /**
   * Flick on the touch screen using finger based motion events, starting
   * at a particular screen location. [speed] is in pixels-per-second.
   */
  Future touchFlickFrom(String id, int xOffset, int yOffset, int speed) =>
          _post('touch/flick',
              params: { 'element': id, 'xoffset': xOffset, 'yoffset': yOffset,
                        'speed': speed });

  /**
   * Flick on the touch screen using finger based motion events. Use this
   * instead of [touchFlickFrom] if you don'tr care where the flick starts.
   */
  Future touchFlick(int xSpeed, int ySpeed) =>
      _post('touch/flick', params: { 'xSpeed': xSpeed, 'ySpeed': ySpeed });

  /**
   * Get the current geo location. Returns a [Map] with latitude,
   * longitude and altitude properties.
   */
  Future<Map> getGeolocation() => _get('location');

  /** Set the current geo location. */
  Future setLocation(double latitude, double longitude, double altitude) =>
          _post('location', params:
              { 'latitude': latitude,
                'longitude': longitude,
                'altitude': altitude });

  /**
   * Get all keys of the local storage. Completes with [null] if there
   * are no keys or the keys could not be retrieved.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<List<String>> getLocalStorageKeys() => _get('local_storage');

  /**
   * Set the local storage item for the given key.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future setLocalStorageItem(String key, String value) =>
      _post('local_storage', params: { 'key': key, 'value': value });

  /**
   * Clear the local storage.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future clearLocalStorage() => _delete('local_storage');

  /**
   * Get the local storage item for the given key.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getLocalStorageValue(String key) =>
      _get('local_storage/key/$key');

  /**
   * Delete the local storage item for the given key.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future deleteLocalStorageValue(String key) =>
      _delete('local_storage/key/$key');

  /**
   * Get the number of items in the local storage.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<int> getLocalStorageCount() => _get('local_storage/size');

  /**
   * Get all keys of the session storage.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<List<String>> getSessionStorageKeys() => _get('session_storage');

  /**
   * Set the sessionstorage item for the given key.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future setSessionStorageItem(String key, String value) =>
      _post('session_storage', params: { 'key': key, 'value': value });

  /**
   * Clear the session storage.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future clearSessionStorage() => _delete('session_storage');

  /**
   * Get the session storage item for the given key.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getSessionStorageValue(String key) =>
      _get('session_storage/key/$key');

  /**
   * Delete the session storage item for the given key.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future deleteSessionStorageValue(String key) =>
      _delete('session_storage/key/$key');

  /**
   * Get the number of items in the session storage.
   *
   * Potential Errors: NoSuchWindow.
   */
  Future<String> getSessionStorageCount() => _get('session_storage/size');

  /** Get available log types ('client', 'driver', 'browser', 'server'). */
  Future<List<String>> getLogTypes() => _get('log/types');

  /**
   * Get the log for a given log type. Log buffer is reset after each request.
   * Each log entry is a [Map] with these fields:
   *
   * 'timestamp' (int) - The timestamp of the entry.
   * 'level' (String) - The log level of the entry, for example, "INFO".
   * 'message' (String) - The log message.
   */
  Future<List<Map>> getLogs(String type) =>
      _post('log', params: { 'type': type });
}
