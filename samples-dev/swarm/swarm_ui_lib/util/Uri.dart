// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of utilslib;

/**
 * A parsed URI, inspired by:
 * http://closure-library.googlecode.com/svn/docs/class_goog_Uri.html
 */
class SwarmUri {
  /**
   * Parses a URL query string into a map. Because you can have multiple values
   * for the same parameter name, each parameter name maps to a list of
   * values. For example, '?a=b&c=d&a=e' would be parsed as
   * [{'a':['b','e'],'c':['d']}].
   */
  // TODO(jmesserly): consolidate with Uri.parse(...)
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
          if (values == null) {
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
    return component
        .replaceAll(':', '%3A')
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

    return component
        .replaceAll('%3A', ':')
        .replaceAll('%2F', '/')
        .replaceAll('%3F', '?')
        .replaceAll('%3D', '=')
        .replaceAll('%26', '&')
        .replaceAll('%20', ' ');
  }
}
