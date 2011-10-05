// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A parsed URI, inspired by:
 * http://closure-library.googlecode.com/svn/docs/class_goog_Uri.html
 */
class Uri {
  /**
   * Parses a URL query string into a map. Because you can have multiple values
   * for the same parameter name, each parameter name maps to a list of
   * values. For example, '?a=b&c=d&a=e' would be parsed as
   * [{'a':['b','e'],'c':['d']}].
   */
  // TODO(jmesserly): consolidate with new Uri.fromString(...)
  static Map<String, List<String>> parseQuery(String queryString) {
    final queryParams = new Map<String, List<String>>();
    if (queryString.startsWith('?')) {
      final params = queryString.substring(1, queryString.length).split('&');
      for (final param in params) {
        List<String> parts = param.split('=');
        if (parts.length == 2) {
          // TODO(hiltonc) the name and value should be URL decoded.
          String name = parts[0];
          String value = parts[1];

          // Create a list of values for this name if not yet done.
          List values = queryParams[name];
          if (values === null) {
            values = new List();
            queryParams[name] = values;
          }

          values.add(value);
        }
      }
    }
    return queryParams;
  }

  /**
   * Percent-encodes a string for use as a query parameter in a URI.
   */
  // TODO(rnystrom): Get rid of this when the real encodeURIComponent()
  // function is available within Dart.
  static String encodeComponent(String component) {
    if (component == null) return component;

    // TODO(terry): Added b/5096547 to track replace should by default behave
    //              like replaceAll to avoid a problematic usage pattern.
    return component.replaceAll(':', '%3A')
                    .replaceAll('/', '%2F')
                    .replaceAll('?', '%3F')
                    .replaceAll('=', '%3D')
                    .replaceAll('&', '%26')
                    .replaceAll(' ', '%20');
  }

  /**
   * Decodes a string used a query parameter by replacing percent-encoded
   * sequences with their original characters.
   */
  // TODO(jmesserly): replace this with a better implementation
  static String decodeComponent(String component) {
    if (component == null) return component;

    return component.replaceAll('%3A', ':')
                    .replaceAll('%2F', '/')
                    .replaceAll('%3F', '?')
                    .replaceAll('%3D', '=')
                    .replaceAll('%26', '&')
                    .replaceAll('%20', ' ');
  }

  String scheme;
  String userInfo;
  String domain;
  int port;
  String path;
  String query;
  String fragment;

  Uri.fromString(String uri) {
    final m = _splitRe.firstMatch(uri);

    scheme = _decodeOrEmpty(m[_COMPONENT_SCHEME]);
    userInfo = _decodeOrEmpty(m[_COMPONENT_USER_INFO]);
    domain = _decodeOrEmpty(m[_COMPONENT_DOMAIN]);
    port = _parseIntOrZero(m[_COMPONENT_PORT]);
    path = _decodeOrEmpty(m[_COMPONENT_PATH]);
    query = _decodeOrEmpty(m[_COMPONENT_QUERY_DATA]);
    fragment = _decodeOrEmpty(m[_COMPONENT_FRAGMENT]);
  }

  static String _decodeOrEmpty(String val) {
    // TODO(jmesserly): use Uri.decodeComponent when available
    //return val ? Uri.decodeComponent(val) : '';
    return val != null ? val : '';
  }

  static int _parseIntOrZero(String val) {
    if (val !== null && val != '') {
      return Math.parseInt(val);
    } else {
      return 0;
    }
  }

  // NOTE: This code was ported from: closure-library/closure/goog/uri/utils.js
  static RegExp _splitReLazy;

  static RegExp get _splitRe() {
    if (_splitReLazy == null) {
      _splitReLazy = new RegExp(
        '^' +
        '(?:' +
          '([^:/?#.]+)' +                 // scheme - ignore special characters
                                          // used by other URL parts such as :,
                                          // ?, /, #, and .
        ':)?' +
        '(?://' +
          '(?:([^/?#]*)@)?' +             // userInfo
          '([\\w\\d\\-\\u0100-\\uffff.%]*)' +
                                          // domain - restrict to letters,
                                          // digits, dashes, dots, percent
                                          // escapes, and unicode characters.
          '(?::([0-9]+))?' +              // port
        ')?' +
        '([^?#]+)?' +                     // path
        '(?:\\?([^#]*))?' +               // query
        '(?:#(.*))?' +                    // fragment
        '\$', '');
    }
    return _splitReLazy;
  }

  static final _COMPONENT_SCHEME = 1;
  static final _COMPONENT_USER_INFO = 2;
  static final _COMPONENT_DOMAIN = 3;
  static final _COMPONENT_PORT = 4;
  static final _COMPONENT_PATH = 5;
  static final _COMPONENT_QUERY_DATA = 6;
  static final _COMPONENT_FRAGMENT = 7;
}
