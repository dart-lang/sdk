// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('uri');

#import('dart:utf');

#source('encode_decode.dart');
#source('helpers.dart');

/**
 * A parsed URI, inspired by Closure's [URI][] class. Implements [RFC-3986][].
 * [uri]: http://closure-library.googlecode.com/svn/docs/class_goog_Uri.html
 * [RFC-3986]: http://tools.ietf.org/html/rfc3986#section-4.3)
 */
class Uri {
  final String scheme;
  final String userInfo;
  final String domain;
  final int port;
  final String path;
  final String query;
  final String fragment;

  Uri.fromString(String uri) : this._fromMatch(_splitRe.firstMatch(uri));

  Uri._fromMatch(Match m) : this(_emptyIfNull(m[_COMPONENT_SCHEME]),
                                 _emptyIfNull(m[_COMPONENT_USER_INFO]),
                                 _emptyIfNull(m[_COMPONENT_DOMAIN]),
                                 _parseIntOrZero(m[_COMPONENT_PORT]),
                                 _emptyIfNull(m[_COMPONENT_PATH]),
                                 _emptyIfNull(m[_COMPONENT_QUERY_DATA]),
                                 _emptyIfNull(m[_COMPONENT_FRAGMENT]));

  const Uri([String this.scheme = "", String this.userInfo ="",
             String this.domain = "", int this.port = 0,
             String this.path = "", String this.query = "",
             String this.fragment = ""]);

  static String _emptyIfNull(String val) => val != null ? val : '';

  static int _parseIntOrZero(String val) {
    if (val !== null && val != '') {
      return Math.parseInt(val);
    } else {
      return 0;
    }
  }

  // NOTE: This code was ported from: closure-library/closure/goog/uri/utils.js
  static final RegExp _splitRe = const RegExp(
      '^'
      '(?:'
        '([^:/?#.]+)'                   // scheme - ignore special characters
                                        // used by other URL parts such as :,
                                        // ?, /, #, and .
      ':)?'
      '(?://'
        '(?:([^/?#]*)@)?'               // userInfo
        '([\\w\\d\\-\\u0100-\\uffff.%]*)'
                                        // domain - restrict to letters,
                                        // digits, dashes, dots, percent
                                        // escapes, and unicode characters.
        '(?::([0-9]+))?'                // port
      ')?'
      '([^?#]+)?'                       // path
      '(?:\\?([^#]*))?'                 // query
      '(?:#(.*))?'                      // fragment
      '\$');

  static final _COMPONENT_SCHEME = 1;
  static final _COMPONENT_USER_INFO = 2;
  static final _COMPONENT_DOMAIN = 3;
  static final _COMPONENT_PORT = 4;
  static final _COMPONENT_PATH = 5;
  static final _COMPONENT_QUERY_DATA = 6;
  static final _COMPONENT_FRAGMENT = 7;

  /**
   * Returns `true` if the URI is absolute.
   */
  bool isAbsolute() {
    if ("" == scheme) return false;
    if ("" != fragment) return false;
    return true;

    /* absolute-URI  = scheme ":" hier-part [ "?" query ]
     * hier-part   = "//" authority path-abempty
     *             / path-absolute
     *             / path-rootless
     *             / path-empty
     *
     * path          = path-abempty    ; begins with "/" or is empty
     *               / path-absolute   ; begins with "/" but not "//"
     *               / path-noscheme   ; begins with a non-colon segment
     *               / path-rootless   ; begins with a segment
     *               / path-empty      ; zero characters
     *
     * path-abempty  = *( "/" segment )
     * path-absolute = "/" [ segment-nz *( "/" segment ) ]
     * path-noscheme = segment-nz-nc *( "/" segment )
     * path-rootless = segment-nz *( "/" segment )
     * path-empty    = 0<pchar>
     * segment       = *pchar
     * segment-nz    = 1*pchar
     * segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
     *               ; non-zero-length segment without any colon ":"
     *
     * pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"
     */
  }

  Uri resolve(String uri) {
    return resolveUri(new Uri.fromString(uri));
  }

  Uri resolveUri(Uri reference) {
    // From RFC 3986.
    String targetScheme;
    String targetUserInfo;
    String targetDomain;
    int targetPort;
    String targetPath;
    String targetQuery;
    if (reference.scheme != "") {
      targetScheme = reference.scheme;
      targetUserInfo = reference.userInfo;
      targetDomain = reference.domain;
      targetPort = reference.port;
      targetPath = removeDotSegments(reference.path);
      targetQuery = reference.query;
    } else {
      if (reference.hasAuthority()) {
        targetUserInfo = reference.userInfo;
        targetDomain = reference.domain;
        targetPort = reference.port;
        targetPath = removeDotSegments(reference.path);
        targetQuery = reference.query;
      } else {
        if (reference.path == "") {
          targetPath = this.path;
          if (reference.query != "") {
            targetQuery = reference.query;
          } else {
            targetQuery = this.query;
          }
        } else {
          if (reference.path.startsWith("/")) {
            targetPath = removeDotSegments(reference.path);
          } else {
            targetPath = removeDotSegments(merge(this.path, reference.path));
          }
          targetQuery = reference.query;
        }
        targetUserInfo = this.userInfo;
        targetDomain = this.domain;
        targetPort = this.port;
      }
      targetScheme = this.scheme;
    }
    return new Uri(targetScheme, targetUserInfo, targetDomain, targetPort,
                   targetPath, targetQuery, reference.fragment);
  }

  bool hasAuthority() {
    return (userInfo != "") || (domain != "") || (port != 0);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    _addIfNonEmpty(sb, scheme, scheme, ':');
    if (hasAuthority() || (scheme == "file")) {
      sb.add("//");
      _addIfNonEmpty(sb, userInfo, userInfo, "@");
      sb.add(domain === null ? "null" : domain);
      if (port != 0) {
        sb.add(":");
        sb.add(port.toString());
      }
    }
    sb.add(path === null ? "null" : path);
    _addIfNonEmpty(sb, query, "?", query);
    _addIfNonEmpty(sb, fragment, "#", fragment);
    return sb.toString();
  }

  static void _addIfNonEmpty(StringBuffer sb, String test,
                             String first, String second) {
    if ("" != test) {
      sb.add(first === null ? "null" : first);
      sb.add(second === null ? "null" : second);
    }
  }
}
