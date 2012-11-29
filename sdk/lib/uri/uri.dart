// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_uri;

import 'dart:math';
import 'dart:utf';

part 'encode_decode.dart';
part 'helpers.dart';

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

  Uri._fromMatch(Match m) :
    this.fromComponents(scheme: _emptyIfNull(m[_COMPONENT_SCHEME]),
                        userInfo: _emptyIfNull(m[_COMPONENT_USER_INFO]),
                        domain: _emptyIfNull(m[_COMPONENT_DOMAIN]),
                        port: _parseIntOrZero(m[_COMPONENT_PORT]),
                        path: _emptyIfNull(m[_COMPONENT_PATH]),
                        query: _emptyIfNull(m[_COMPONENT_QUERY_DATA]),
                        fragment: _emptyIfNull(m[_COMPONENT_FRAGMENT]));

  const Uri.fromComponents({this.scheme: "",
                            this.userInfo: "",
                            this.domain: "",
                            this.port: 0,
                            this.path: "",
                            this.query: "",
                            this.fragment: ""});

  Uri(String uri) : this.fromString(uri);

  static String _emptyIfNull(String val) => val != null ? val : '';

  static int _parseIntOrZero(String val) {
    if (val != null && val != '') {
      return int.parse(val);
    } else {
      return 0;
    }
  }

  // NOTE: This code was ported from: closure-library/closure/goog/uri/utils.js
  static final RegExp _splitRe = new RegExp(
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

  static const _COMPONENT_SCHEME = 1;
  static const _COMPONENT_USER_INFO = 2;
  static const _COMPONENT_DOMAIN = 3;
  static const _COMPONENT_PORT = 4;
  static const _COMPONENT_PATH = 5;
  static const _COMPONENT_QUERY_DATA = 6;
  static const _COMPONENT_FRAGMENT = 7;

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
    return new Uri.fromComponents(scheme: targetScheme,
                                  userInfo: targetUserInfo,
                                  domain: targetDomain,
                                  port: targetPort,
                                  path: targetPath,
                                  query: targetQuery,
                                  fragment: reference.fragment);
  }

  bool hasAuthority() {
    return (userInfo != "") || (domain != "") || (port != 0);
  }

  /**
   * For http/https schemes returns URI's [origin][] - scheme://domain:port.
   * For all other schemes throws ArgumentError.
   * [origin]: http://www.w3.org/TR/2011/WD-html5-20110405/origin-0.html#origin
   */
  String get origin {
    if (scheme == "") {
      // TODO(aprelev@gmail.com): Use StateException instead
      throw new ArgumentError("Cannot use origin without a scheme");
    }
    if (scheme != "http" && scheme != "https") {
      // TODO(aprelev@gmail.com): Use StateException instead
      throw new ArgumentError(
        "origin is applicable to http/https schemes only. Not \'$scheme\'");
    }
    StringBuffer sb = new StringBuffer();
    sb.add(scheme);
    sb.add(":");
    if (domain == null || domain == "") {
      // TODO(aprelev@gmail.com): Use StateException instead
      throw new ArgumentError("Cannot use origin without a domain");
    }

    sb.add("//");
    sb.add(domain);
    if (port != 0) {
      sb.add(":");
      sb.add(port);
    }
    return sb.toString();
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    _addIfNonEmpty(sb, scheme, scheme, ':');
    if (hasAuthority() || (scheme == "file")) {
      sb.add("//");
      _addIfNonEmpty(sb, userInfo, userInfo, "@");
      sb.add(domain == null ? "null" : domain);
      if (port != 0) {
        sb.add(":");
        sb.add(port.toString());
      }
    }
    sb.add(path == null ? "null" : path);
    _addIfNonEmpty(sb, query, "?", query);
    _addIfNonEmpty(sb, fragment, "#", fragment);
    return sb.toString();
  }

  static void _addIfNonEmpty(StringBuffer sb, String test,
                             String first, String second) {
    if ("" != test) {
      sb.add(first == null ? "null" : first);
      sb.add(second == null ? "null" : second);
    }
  }
}
