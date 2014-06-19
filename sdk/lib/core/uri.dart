// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A parsed URI, such as a URL.
 *
 * **See also:**
 *
 * * [URIs][uris] in the [library tour][libtour]
 * * [RFC-3986](http://tools.ietf.org/html/rfc3986)
 *
 * [uris]: http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#ch03-uri
 * [libtour]: http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html
 */
class Uri {
  final String _host;
  int _port;
  String _path;

  /**
   * Returns the scheme component.
   *
   * Returns the empty string if there is no scheme component.
   */
  final String scheme;

  /**
   * Returns the authority component.
   *
   * The authority is formatted from the [userInfo], [host] and [port]
   * parts.
   *
   * Returns the empty string if there is no authority component.
   */
  String get authority {
    if (!hasAuthority) return "";
    var sb = new StringBuffer();
    _writeAuthority(sb);
    return sb.toString();
  }

  /**
   * Returns the user info part of the authority component.
   *
   * Returns the empty string if there is no user info in the
   * authority component.
   */
  final String userInfo;

  /**
   * Returns the host part of the authority component.
   *
   * Returns the empty string if there is no authority component and
   * hence no host.
   *
   * If the host is an IP version 6 address, the surrounding `[` and `]` is
   * removed.
   */
  String get host {
    if (_host != null && _host.startsWith('[')) {
      return _host.substring(1, _host.length - 1);
    }
    return _host;
  }

  /**
   * Returns the port part of the authority component.
   *
   * Returns 0 if there is no port in the authority component.
   */
  int get port {
    if (_port == 0) {
      if (scheme == "http") return 80;
      if (scheme == "https") return 443;
    }
    return _port;
  }

  /**
   * Returns the path component.
   *
   * The returned path is encoded. To get direct access to the decoded
   * path use [pathSegments].
   *
   * Returns the empty string if there is no path component.
   */
  String get path => _path;

  /**
   * Returns the query component. The returned query is encoded. To get
   * direct access to the decoded query use [queryParameters].
   *
   * Returns the empty string if there is no query component.
   */
  final String query;

  /**
   * Returns the fragment identifier component.
   *
   * Returns the empty string if there is no fragment identifier
   * component.
   */
  final String fragment;

  /**
   * Cache the computed return value of [pathSegements].
   */
  List<String> _pathSegments;

  /**
   * Cache the computed return value of [queryParameters].
   */
  Map<String, String> _queryParameters;

  /**
   * Creates a new `Uri` object by parsing a URI string.
   *
   * If the string is not valid as a URI or URI reference,
   * invalid characters will be percent escaped where possible.
   * The resulting `Uri` will represent a valid URI or URI reference.
   */
  static Uri parse(String uri) {
    // This parsing will not validate percent-encoding, IPv6, etc. When done
    // it will call `new Uri(...)` which will perform these validations.
    // This is purely splitting up the URI string into components.
    //
    // Important parts of the RFC 3986 used here:
    // URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
    //
    // hier-part     = "//" authority path-abempty
    //               / path-absolute
    //               / path-rootless
    //               / path-empty
    //
    // URI-reference = URI / relative-ref
    //
    // absolute-URI  = scheme ":" hier-part [ "?" query ]
    //
    // relative-ref  = relative-part [ "?" query ] [ "#" fragment ]
    //
    // relative-part = "//" authority path-abempty
    //               / path-absolute
    //               / path-noscheme
    //               / path-empty
    //
    // scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    //
    // authority     = [ userinfo "@" ] host [ ":" port ]
    // userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
    // host          = IP-literal / IPv4address / reg-name
    // port          = *DIGIT
    // reg-name      = *( unreserved / pct-encoded / sub-delims )
    //
    // path          = path-abempty    ; begins with "/" or is empty
    //               / path-absolute   ; begins with "/" but not "//"
    //               / path-noscheme   ; begins with a non-colon segment
    //               / path-rootless   ; begins with a segment
    //               / path-empty      ; zero characters
    //
    // path-abempty  = *( "/" segment )
    // path-absolute = "/" [ segment-nz *( "/" segment ) ]
    // path-noscheme = segment-nz-nc *( "/" segment )
    // path-rootless = segment-nz *( "/" segment )
    // path-empty    = 0<pchar>
    //
    // segment       = *pchar
    // segment-nz    = 1*pchar
    // segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
    //               ; non-zero-length segment without any colon ":"
    //
    // pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"
    //
    // query         = *( pchar / "/" / "?" )
    //
    // fragment      = *( pchar / "/" / "?" )
    bool isRegName(int ch) {
      return ch < 128 && ((_regNameTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
    }
    const int EOI = -1;

    String scheme = "";
    String path;
    String userinfo = "";
    String host = "";
    int port = 0;
    String query = "";
    String fragment = "";

    int index = 0;
    int pathStart = 0;
    // End of input-marker.
    int char = EOI;

    void parseAuth() {
      if (index == uri.length) {
        char = EOI;
        return;
      }
      int authStart = index;
      int lastColon = -1;
      int lastAt = -1;
      char = uri.codeUnitAt(index);
      while (index < uri.length) {
        char = uri.codeUnitAt(index);
        if (char == _SLASH || char == _QUESTION || char == _NUMBER_SIGN) {
          break;
        }
        if (char == _AT_SIGN) {
          lastAt = index;
          lastColon = -1;
        } else if (char == _COLON) {
          lastColon = index;
        } else if (char == _LEFT_BRACKET) {
          lastColon = -1;
          int endBracket = uri.indexOf(']', index + 1);
          if (endBracket == -1) {
            index = uri.length;
            char = EOI;
            break;
          } else {
            index = endBracket;
          }
        }
        index++;
        char = EOI;
      }
      int hostStart = authStart;
      int hostEnd = index;
      if (lastAt >= 0) {
        userinfo = _makeUserInfo(uri, authStart, lastAt);
        hostStart = lastAt + 1;
      }
      if (lastColon >= 0) {
        if (lastColon + 1 == index) {
          _fail(uri, index, "Invalid port number");
        }
        int portNumber = 0;
        for (int i = lastColon + 1; i < index; i++) {
          int digit = uri.codeUnitAt(i);
          if (_ZERO > digit || _NINE < digit) {
            _fail(uri, i, "Invalid port number");
          }
          portNumber = portNumber * 10 + (digit - _ZERO);
        }
        port = _makePort(portNumber, scheme);
        hostEnd = lastColon;
      }
      host = _makeHost(uri, hostStart, hostEnd, true);
      if (index < uri.length) {
        char = uri.codeUnitAt(index);
      }
    }

    // When reaching path parsing, the current character is known to not
    // be part of the path.
    const int NOT_IN_PATH = 0;
    // When reaching path parsing, the current character is part
    // of the a non-empty path.
    const int IN_PATH = 1;
    // When reaching authority parsing, authority is possible.
    // This is only true at start or right after scheme.
    const int ALLOW_AUTH = 2;

    // Current state.
    // Initialized to the default value that is used when exiting the
    // scheme loop by reaching the end of input.
    // All other breaks set their own state.
    int state = NOT_IN_PATH;
    while (index < uri.length) {
      char = uri.codeUnitAt(index);
      if (char == _QUESTION || char == _NUMBER_SIGN) {
        state = NOT_IN_PATH;
        break;
      }
      if (char == _SLASH) {
        state = (index == 0) ? ALLOW_AUTH : IN_PATH;
        break;
      }
      if (char == _COLON) {
        if (index == 0) _fail(uri, 0, "Invalid empty scheme");
        scheme = _makeScheme(uri, index);
        index++;
        pathStart = index;
        if (index == uri.length) {
          char = EOI;
          state = NOT_IN_PATH;
        } else {
          char = uri.codeUnitAt(index);
          if (char == _QUESTION || char == _NUMBER_SIGN) {
            state = NOT_IN_PATH;
          } else if (char == _SLASH) {
            state = ALLOW_AUTH;
          } else {
            state = IN_PATH;
          }
        }
        break;
      }
      index++;
      char = EOI;
    }

    if (state == ALLOW_AUTH) {
      assert(char == _SLASH);
      // Have seen one slash either at start or right after scheme.
      // If two slashes, it's an authority, otherwise it's just the path.
      index++;
      if (index == uri.length) {
        char = EOI;
        state = NOT_IN_PATH;
      } else {
        char = uri.codeUnitAt(index);
        if (char == _SLASH) {
          index++;
          parseAuth();
          pathStart = index;
        }
        if (char == _QUESTION || char == _NUMBER_SIGN || char == EOI) {
          state = NOT_IN_PATH;
        } else {
          state = IN_PATH;
        }
      }
    }

    assert(state == IN_PATH || state == NOT_IN_PATH);
    if (state == IN_PATH) {
      // Characters from pathStart to index (inclusive) are known
      // to be part of the path.
      while (++index < uri.length) {
        char = uri.codeUnitAt(index);
        if (char == _QUESTION || char == _NUMBER_SIGN) {
          break;
        }
        char = EOI;
      }
      state = NOT_IN_PATH;
    }

    assert(state == NOT_IN_PATH);
    bool ensureLeadingSlash = (host != "" || scheme == "file");
    path = _makePath(uri, pathStart, index, null, ensureLeadingSlash);

    if (char == _QUESTION) {
      int numberSignIndex = uri.indexOf('#', index + 1);
      if (numberSignIndex < 0) {
        query = _makeQuery(uri, index + 1, uri.length, null);
      } else {
        query = _makeQuery(uri, index + 1, numberSignIndex, null);
        fragment = _makeFragment(uri, numberSignIndex + 1, uri.length);
      }
    } else if (char == _NUMBER_SIGN) {
      fragment = _makeFragment(uri, index + 1, uri.length);
    }
    return new Uri._internal(scheme,
                             userinfo,
                             host,
                             port,
                             path,
                             query,
                             fragment);
  }

  // Report a parse failure.
  static void _fail(String uri, int index, String message) {
    // TODO(lrn): Consider adding this to FormatException.
    if (index == uri.length) {
      message += " at end of input.";
    } else {
      message += " at position $index.\n";
      // Pick a slice of uri containing index and, if
      // necessary, truncate the ends to ensure the entire
      // slice fits on one line.
      int min = 0;
      int max = uri.length;
      String pre = "";
      String post = "";
      if (uri.length > 78) {
        min = index - 10;
        if (min < 0) min = 0;
        int max = min + 72;
        if (max > uri.length) {
          max = uri.length;
          min = max - 72;
        }
        if (min != 0) pre = "...";
        if (max != uri.length) post = "...";
      }
      // Combine message, slice and a caret pointing to the error index.
      message = "$message$pre${uri.substring(min, max)}$post\n"
                "${' ' * (pre.length + index - min)}^";
    }
    throw new FormatException(message);
  }

  /// Internal non-verifying constructor. Only call with validated arguments.
  Uri._internal(this.scheme,
                this.userInfo,
                this._host,
                this._port,
                this._path,
                this.query,
                this.fragment);

  /**
   * Creates a new URI from its components.
   *
   * Each component is set through a named argument. Any number of
   * components can be provided. The default value for the components
   * not provided is the empry string, except for [port] which has a
   * default value of 0. The [path] and [query] components can be set
   * using two different named arguments.
   *
   * The scheme component is set through [scheme]. The scheme is
   * normalized to all lowercase letters.
   *
   * The user info part of the authority component is set through
   * [userInfo].
   *
   * The host part of the authority component is set through
   * [host]. The host can either be a hostname, an IPv4 address or an
   * IPv6 address, contained in '[' and ']'. If the host contains a
   * ':' character, the '[' and ']' are added if not already provided.
   * The host is normalized to all lowercase letters.
   *
   * The port part of the authority component is set through
   * [port]. The port is normalized for scheme http and https where
   * port 80 and port 443 respectively is set.
   *
   * The path component is set through either [path] or
   * [pathSegments]. When [path] is used, the provided string is
   * expected to be fully percent-encoded, and is used in its literal
   * form. When [pathSegments] is used, each of the provided segments
   * is percent-encoded and joined using the forward slash
   * separator. The percent-encoding of the path segments encodes all
   * characters except for the unreserved characters and the following
   * list of characters: `!$&'()*+,;=:@`. If the other components
   * calls for an absolute path a leading slash `/` is prepended if
   * not already there.
   *
   * The query component is set through either [query] or
   * [queryParameters]. When [query] is used the provided string is
   * expected to be fully percent-encoded and is used in its literal
   * form. When [queryParameters] is used the query is built from the
   * provided map. Each key and value in the map is percent-encoded
   * and joined using equal and ampersand characters. The
   * percent-encoding of the keys and values encodes all characters
   * except for the unreserved characters.
   *
   * The fragment component is set through [fragment].
   */
  factory Uri({String scheme,
       String userInfo: "",
       String host: "",
       port: 0,
       String path,
       Iterable<String> pathSegments,
       String query,
       Map<String, String> queryParameters,
       fragment: ""}) {
    scheme = _makeScheme(scheme, _stringOrNullLength(scheme));
    userInfo = _makeUserInfo(userInfo, 0, _stringOrNullLength(userInfo));
    host = _makeHost(host, 0, _stringOrNullLength(host), false);
    query = _makeQuery(query, 0, _stringOrNullLength(query), queryParameters);
    fragment = _makeFragment(fragment, 0, _stringOrNullLength(fragment));
    port = _makePort(port, scheme);
    bool ensureLeadingSlash = (host != "" || scheme == "file");
    path = _makePath(path, 0, _stringOrNullLength(path), pathSegments,
                     ensureLeadingSlash);

    return new Uri._internal(scheme, userInfo, host, port,
                             path, query, fragment);
  }

  /**
   * Creates a new `http` URI from authority, path and query.
   *
   * Examples:
   *
   * ```
   * // http://example.org/path?q=dart.
   * new Uri.http("google.com", "/search", { "q" : "dart" });
   *
   * // http://user:pass@localhost:8080
   * new Uri.http("user:pass@localhost:8080", "");
   *
   * // http://example.org/a%20b
   * new Uri.http("example.org", "a b");
   *
   * // http://example.org/a%252F
   * new Uri.http("example.org", "/a%2F");
   * ```
   *
   * The `scheme` is always set to `http`.
   *
   * The `userInfo`, `host` and `port` components are set from the
   * [authority] argument.
   *
   * The `path` component is set from the [unencodedPath]
   * argument. The path passed must not be encoded as this constructor
   * encodes the path.
   *
   * The `query` component is set from the optional [queryParameters]
   * argument.
   */
  factory Uri.http(String authority,
                   String unencodedPath,
                   [Map<String, String> queryParameters]) {
    return _makeHttpUri("http", authority, unencodedPath, queryParameters);
  }

  /**
   * Creates a new `https` URI from authority, path and query.
   *
   * This constructor is the same as [Uri.http] except for the scheme
   * which is set to `https`.
   */
  factory Uri.https(String authority,
                    String unencodedPath,
                    [Map<String, String> queryParameters]) {
    return _makeHttpUri("https", authority, unencodedPath, queryParameters);
  }

  static Uri _makeHttpUri(String scheme,
                          String authority,
                          String unencodedPath,
                          Map<String, String> queryParameters) {
    var userInfo = "";
    var host = "";
    var port = 0;

    var hostStart = 0;
    // Split off the user info.
    bool hasUserInfo = false;
    for (int i = 0; i < authority.length; i++) {
      if (authority.codeUnitAt(i) == _AT_SIGN) {
        hasUserInfo = true;
        userInfo = authority.substring(0, i);
        hostStart = i + 1;
        break;
      }
    }
    var hostEnd = hostStart;
    if (hostStart < authority.length &&
        authority.codeUnitAt(hostStart) == _LEFT_BRACKET) {
      // IPv6 host.
      for (; hostEnd < authority.length; hostEnd++) {
        if (authority.codeUnitAt(hostEnd) == _RIGHT_BRACKET) break;
      }
      if (hostEnd == authority.length) {
        throw new FormatException("Invalid IPv6 host entry.");
      }
      parseIPv6Address(authority, hostStart + 1, hostEnd);
      hostEnd++;  // Skip the closing bracket.
      if (hostEnd != authority.length &&
          authority.codeUnitAt(hostEnd) != _COLON) {
        throw new FormatException("Invalid end of authority");
      }
    }
    // Split host and port.
    bool hasPort = false;
    for (; hostEnd < authority.length; hostEnd++) {
      if (authority.codeUnitAt(hostEnd) == _COLON) {
        var portString = authority.substring(hostEnd + 1);
        // We allow the empty port - falling back to initial value.
        if (portString.isNotEmpty) port = int.parse(portString);
        break;
      }
    }
    host = authority.substring(hostStart, hostEnd);

    return new Uri(scheme: scheme,
                   userInfo: userInfo,
                   host: host,
                   port: port,
                   pathSegments: unencodedPath.split("/"),
                   queryParameters: queryParameters);
  }

  /**
   * Creates a new file URI from an absolute or relative file path.
   *
   * The file path is passed in [path].
   *
   * This path is interpreted using either Windows or non-Windows
   * semantics.
   *
   * With non-Windows semantics the slash ("/") is used to separate
   * path segments.
   *
   * With Windows semantics, backslash ("\") and forward-slash ("/")
   * are used to separate path segments, except if the path starts
   * with "\\?\" in which case, only backslash ("\") separates path
   * segments.
   *
   * If the path starts with a path separator an absolute URI is
   * created. Otherwise a relative URI is created. One exception from
   * this rule is that when Windows semantics is used and the path
   * starts with a drive letter followed by a colon (":") and a
   * path separator then an absolute URI is created.
   *
   * The default for whether to use Windows or non-Windows semantics
   * determined from the platform Dart is running on. When running in
   * the standalone VM this is detected by the VM based on the
   * operating system. When running in a browser non-Windows semantics
   * is always used.
   *
   * To override the automatic detection of which semantics to use pass
   * a value for [windows]. Passing `true` will use Windows
   * semantics and passing `false` will use non-Windows semantics.
   *
   * Examples using non-Windows semantics:
   *
   * ```
   * // xxx/yyy
   * new Uri.file("xxx/yyy", windows: false);
   *
   * // xxx/yyy/
   * new Uri.file("xxx/yyy/", windows: false);
   *
   * // file:///xxx/yyy
   * new Uri.file("/xxx/yyy", windows: false);
   *
   * // file:///xxx/yyy/
   * new Uri.file("/xxx/yyy/", windows: false);
   *
   * // C:
   * new Uri.file("C:", windows: false);
   * ```
   *
   * Examples using Windows semantics:
   *
   * ```
   * // xxx/yyy
   * new Uri.file(r"xxx\yyy", windows: true);
   *
   * // xxx/yyy/
   * new Uri.file(r"xxx\yyy\", windows: true);
   *
   * file:///xxx/yyy
   * new Uri.file(r"\xxx\yyy", windows: true);
   *
   * file:///xxx/yyy/
   * new Uri.file(r"\xxx\yyy/", windows: true);
   *
   * // file:///C:/xxx/yyy
   * new Uri.file(r"C:\xxx\yyy", windows: true);
   *
   * // This throws an error. A path with a drive letter is not absolute.
   * new Uri.file(r"C:", windows: true);
   *
   * // This throws an error. A path with a drive letter is not absolute.
   * new Uri.file(r"C:xxx\yyy", windows: true);
   *
   * // file://server/share/file
   * new Uri.file(r"\\server\share\file", windows: true);
   * ```
   *
   * If the path passed is not a legal file path [ArgumentError] is thrown.
   */
  factory Uri.file(String path, {bool windows}) {
    windows = windows == null ? Uri._isWindows : windows;
    return windows ? _makeWindowsFileUrl(path) : _makeFileUri(path);
  }

  /**
   * Returns the natural base URI for the current platform.
   *
   * When running in a browser this is the current URL (from
   * `window.location.href`).
   *
   * When not running in a browser this is the file URI referencing
   * the current working directory.
   */
  external static Uri get base;

  external static bool get _isWindows;

  static _checkNonWindowsPathReservedCharacters(List<String> segments,
                                                bool argumentError) {
    segments.forEach((segment) {
      if (segment.contains("/")) {
        if (argumentError) {
          throw new ArgumentError("Illegal path character $segment");
        } else {
          throw new UnsupportedError("Illegal path character $segment");
        }
      }
    });
  }

  static _checkWindowsPathReservedCharacters(List<String> segments,
                                             bool argumentError,
                                             [int firstSegment = 0]) {
    segments.skip(firstSegment).forEach((segment) {
      if (segment.contains(new RegExp(r'["*/:<>?\\|]'))) {
        if (argumentError) {
          throw new ArgumentError("Illegal character in path");
        } else {
          throw new UnsupportedError("Illegal character in path");
        }
      }
    });
  }

  static _checkWindowsDriveLetter(int charCode, bool argumentError) {
    if ((_UPPER_CASE_A <= charCode && charCode <= _UPPER_CASE_Z) ||
        (_LOWER_CASE_A <= charCode && charCode <= _LOWER_CASE_Z)) {
      return;
    }
    if (argumentError) {
      throw new ArgumentError("Illegal drive letter " +
                              new String.fromCharCode(charCode));
    } else {
      throw new UnsupportedError("Illegal drive letter " +
                              new String.fromCharCode(charCode));
    }
  }

  static _makeFileUri(String path) {
    String sep = "/";
    if (path.length > 0 && path[0] == sep) {
      // Absolute file:// URI.
      return new Uri(scheme: "file", pathSegments: path.split(sep));
    } else {
      // Relative URI.
      return new Uri(pathSegments: path.split(sep));
    }
  }

  static _makeWindowsFileUrl(String path) {
    if (path.startsWith("\\\\?\\")) {
      if (path.startsWith("\\\\?\\UNC\\")) {
        path = "\\${path.substring(7)}";
      } else {
        path = path.substring(4);
        if (path.length < 3 ||
            path.codeUnitAt(1) != _COLON ||
            path.codeUnitAt(2) != _BACKSLASH) {
          throw new ArgumentError(
              "Windows paths with \\\\?\\ prefix must be absolute");
        }
      }
    } else {
      path = path.replaceAll("/", "\\");
    }
    String sep = "\\";
    if (path.length > 1 && path[1] == ":") {
      _checkWindowsDriveLetter(path.codeUnitAt(0), true);
      if (path.length == 2 || path.codeUnitAt(2) != _BACKSLASH) {
        throw new ArgumentError(
            "Windows paths with drive letter must be absolute");
      }
      // Absolute file://C:/ URI.
      var pathSegments = path.split(sep);
      _checkWindowsPathReservedCharacters(pathSegments, true, 1);
      return new Uri(scheme: "file", pathSegments: pathSegments);
    }

    if (path.length > 0 && path[0] == sep) {
      if (path.length > 1 && path[1] == sep) {
        // Absolute file:// URI with host.
        int pathStart = path.indexOf("\\", 2);
        String hostPart =
            pathStart == -1 ? path.substring(2) : path.substring(2, pathStart);
        String pathPart =
            pathStart == -1 ? "" : path.substring(pathStart + 1);
        var pathSegments = pathPart.split(sep);
        _checkWindowsPathReservedCharacters(pathSegments, true);
        return new Uri(
            scheme: "file", host: hostPart, pathSegments: pathSegments);
      } else {
        // Absolute file:// URI.
        var pathSegments = path.split(sep);
        _checkWindowsPathReservedCharacters(pathSegments, true);
        return new Uri(scheme: "file", pathSegments: pathSegments);
      }
    } else {
      // Relative URI.
      var pathSegments = path.split(sep);
      _checkWindowsPathReservedCharacters(pathSegments, true);
      return new Uri(pathSegments: pathSegments);
    }
  }

  /**
   * Returns the URI path split into its segments. Each of the
   * segments in the returned list have been decoded. If the path is
   * empty the empty list will be returned. A leading slash `/` does
   * not affect the segments returned.
   *
   * The returned list is unmodifiable and will throw [UnsupportedError] on any
   * calls that would mutate it.
   */
  List<String> get pathSegments {
    if (_pathSegments == null) {
      var pathToSplit = !path.isEmpty && path.codeUnitAt(0) == _SLASH
                        ? path.substring(1)
                        : path;
      _pathSegments = new UnmodifiableListView(
        pathToSplit == "" ? const<String>[]
                          : pathToSplit.split("/")
                                       .map(Uri.decodeComponent)
                                       .toList(growable: false));
    }
    return _pathSegments;
  }

  /**
   * Returns the URI query split into a map according to the rules
   * specified for FORM post in the [HTML 4.01 specification section 17.13.4]
   * (http://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4
   * "HTML 4.01 section 17.13.4"). Each key and value in the returned map
   * has been decoded. If there is no query the empty map is returned.
   *
   * Keys in the query string that have no value are mapped to the
   * empty string.
   *
   * The returned map is unmodifiable and will throw [UnsupportedError] on any
   * calls that would mutate it.
   */
  Map<String, String> get queryParameters {
    if (_queryParameters == null) {
      _queryParameters = new UnmodifiableMapView(splitQueryString(query));
    }
    return _queryParameters;
  }

  static int _makePort(int port, String scheme) {
    // Perform scheme specific normalization.
    if (port == 80 && scheme == "http") {
      return 0;
    }
    if (port == 443 && scheme == "https") {
      return 0;
    }
    return port;
  }

  /**
   * Check and normalize a most name.
   *
   * If the host name starts and ends with '[' and ']', it is considered an
   * IPv6 address. If [strictIPv6] is false, the address is also considered
   * an IPv6 address if it contains any ':' character.
   *
   * If it is not an IPv6 address, it is case- and escape-normalized.
   * This escapes all characters not valid in a reg-name,
   * and converts all non-escape upper-case letters to lower-case.
   */
  static String _makeHost(String host, int start, int end, bool strictIPv6) {
    // TODO(lrn): Should we normalize IPv6 addresses according to RFC 5952?

    if (host == null) return null;
    if (start == end) return "";
    // Host is an IPv6 address if it starts with '[' or contains a colon.
    if (host.codeUnitAt(start) == _LEFT_BRACKET) {
      if (host.codeUnitAt(end - 1) != _RIGHT_BRACKET) {
        _fail(host, start, 'Missing end `]` to match `[` in host');
      }
      parseIPv6Address(host, start + 1, end - 1);
      // RFC 5952 requires hex digits to be lower case.
      return host.substring(start, end).toLowerCase();
    }
    if (!strictIPv6) {
      // TODO(lrn): skip if too short to be a valid IPv6 address?
      for (int i = start; i < end; i++) {
        if (host.codeUnitAt(i) == _COLON) {
          parseIPv6Address(host, start, end);
          return '[$host]';
        }
      }
    }
    return _normalizeRegName(host, start, end);
  }

  static bool _isRegNameChar(int char) {
    return char < 127 && (_regNameTable[char >> 4] & (1 << (char & 0xf))) != 0;
  }

  /**
   * Validates and does case- and percent-encoding normalization.
   *
   * The [host] must be an RFC3986 "reg-name". It is converted
   * to lower case, and percent escapes are converted to either
   * lower case unreserved characters or upper case escapes.
   */
  static String _normalizeRegName(String host, int start, int end) {
    StringBuffer buffer;
    int sectionStart = start;
    int index = start;
    // Whether all characters between sectionStart and index are normalized,
    bool isNormalized = true;

    while (index < end) {
      int char = host.codeUnitAt(index);
      if (char == _PERCENT) {
        // The _regNameTable contains "%", so we check that first.
        String replacement = _normalizeEscape(host, index, true);
        if (replacement == null && isNormalized) {
          index += 3;
          continue;
        }
        if (buffer == null) buffer = new StringBuffer();
        String slice = host.substring(sectionStart, index);
        if (!isNormalized) slice = slice.toLowerCase();
        buffer.write(slice);
        int sourceLength = 3;
        if (replacement == null) {
          replacement = host.substring(index, index + 3);
        } else if (replacement == "%") {
          replacement = "%25";
          sourceLength = 1;
        }
        buffer.write(replacement);
        index += sourceLength;
        sectionStart = index;
        isNormalized = true;
      } else if (_isRegNameChar(char)) {
        if (isNormalized && _UPPER_CASE_A <= char && _UPPER_CASE_Z >= char) {
          // Put initial slice in buffer and continue in non-normalized mode
          if (buffer == null) buffer = new StringBuffer();
          if (sectionStart < index) {
            buffer.write(host.substring(sectionStart, index));
            sectionStart = index;
          }
          isNormalized = false;
        }
        index++;
      } else if (_isGeneralDelimiter(char)) {
        _fail(host, index, "Invalid character");
      } else {
        int sourceLength = 1;
        if ((char & 0xFC00) == 0xD800 && (index + 1) < end) {
          int tail = host.codeUnitAt(index + 1);
          if ((tail & 0xFC00) == 0xDC00) {
            char = 0x10000 | ((char & 0x3ff) << 10) | (tail & 0x3ff);
            sourceLength = 2;
          }
        }
        if (buffer == null) buffer = new StringBuffer();
        String slice = host.substring(sectionStart, index);
        if (!isNormalized) slice = slice.toLowerCase();
        buffer.write(slice);
        buffer.write(_escapeChar(char));
        index += sourceLength;
        sectionStart = index;
      }
    }
    if (buffer == null) return host.substring(start, end);
    if (sectionStart < end) {
      String slice = host.substring(sectionStart, end);
      if (!isNormalized) slice = slice.toLowerCase();
      buffer.write(slice);
    }
    return buffer.toString();
  }

  /**
   * Validates scheme characters and does case-normalization.
   *
   * Schemes are converted to lower case. They cannot contain escapes.
   */
  static String _makeScheme(String scheme, int end) {
    if (end == 0) return "";
    int char = scheme.codeUnitAt(0);
    if (!_isAlphabeticCharacter(char)) {
      _fail(scheme, 0, "Scheme not starting with alphabetic character");
    }
    bool allLowercase = char >= _LOWER_CASE_A;
    for (int i = 0; i < end; i++) {
      int codeUnit = scheme.codeUnitAt(i);
      if (!_isSchemeCharacter(codeUnit)) {
        _fail(scheme, i, "Illegal scheme character");
      }
      if (_LOWER_CASE_A <= char && _LOWER_CASE_Z >= char) {
        allLowercase = false;
      }
    }
    scheme = scheme.substring(0, end);
    if (!allLowercase) scheme = scheme.toLowerCase();
    return scheme;
  }

  static String _makeUserInfo(String userInfo, int start, int end) {
    if (userInfo == null) return "null";
    return _normalize(userInfo, start, end, _userinfoTable);
  }

  static String _makePath(String path, int start, int end,
                          Iterable<String> pathSegments,
                          bool ensureLeadingSlash) {
    if (path == null && pathSegments == null) return "";
    if (path != null && pathSegments != null) {
      throw new ArgumentError('Both path and pathSegments specified');
    }
    var result;
    if (path != null) {
      result = _normalize(path, start, end, _pathCharOrSlashTable);
    } else {
      result = pathSegments.map((s) => _uriEncode(_pathCharTable, s)).join("/");
    }
    if (ensureLeadingSlash && result.isNotEmpty && !result.startsWith("/")) {
      return "/$result";
    }
    return result;
  }

  static String _makeQuery(String query, int start, int end,
                           Map<String, String> queryParameters) {
    if (query == null && queryParameters == null) return "";
    if (query != null && queryParameters != null) {
      throw new ArgumentError('Both query and queryParameters specified');
    }
    if (query != null) return _normalize(query, start, end, _queryCharTable);

    var result = new StringBuffer();
    var first = true;
    queryParameters.forEach((key, value) {
      if (!first) {
        result.write("&");
      }
      first = false;
      result.write(Uri.encodeQueryComponent(key));
      if (value != null && !value.isEmpty) {
        result.write("=");
        result.write(Uri.encodeQueryComponent(value));
      }
    });
    return result.toString();
  }

  static String _makeFragment(String fragment, int start, int end) {
    if (fragment == null) return "";
    return _normalize(fragment, start, end, _queryCharTable);
  }

  static int _stringOrNullLength(String s) => (s == null) ? 0 : s.length;

  static bool _isHexDigit(int char) {
    if (_NINE >= char) return _ZERO <= char;
    char |= 0x20;
    return _LOWER_CASE_A <= char && _LOWER_CASE_F >= char;
  }

  static int _hexValue(int char) {
    assert(_isHexDigit(char));
    if (_NINE >= char) return char - _ZERO;
    char |= 0x20;
    return char - (_LOWER_CASE_A - 10);
  }

  /**
   * Performs RFC 3986 Percent-Encoding Normalization.
   *
   * Returns a replacement string that should be replace the original escape.
   * Returns null if no replacement is necessary because the escape is
   * not for an unreserved character and is already non-lower-case.
   *
   * Returns "%" if the escape is invalid (not two valid hex digits following
   * the percent sign). The calling code should replace the percent
   * sign with "%25", but leave the following two characters unmodified.
   *
   * If [lowerCase] is true, a single character returned is always lower case,
   */
  static String _normalizeEscape(String source, int index, bool lowerCase) {
    assert(source.codeUnitAt(index) == _PERCENT);
    if (index + 2 >= source.length) {
      return "%";  // Marks the escape as invalid.
    }
    int firstDigit = source.codeUnitAt(index + 1);
    int secondDigit = source.codeUnitAt(index + 2);
    if (!_isHexDigit(firstDigit) || !_isHexDigit(secondDigit)) {
      return "%";  // Marks the escape as invalid.
    }
    int value = _hexValue(firstDigit) * 16 + _hexValue(secondDigit);
    if (_isUnreservedChar(value)) {
      if (lowerCase && _UPPER_CASE_A <= value && _UPPER_CASE_Z >= value) {
        value |= 0x20;
      }
      return new String.fromCharCode(value);
    }
    if (firstDigit >= _LOWER_CASE_A || secondDigit >= _LOWER_CASE_A) {
      // Either digit is lower case.
      return source.substring(index, index + 3).toUpperCase();
    }
    // Escape is retained, and is already non-lower case, so return null to
    // represent "no replacement necessary".
    return null;
  }

  static bool _isUnreservedChar(int ch) {
    return ch < 127 &&
           ((_unreservedTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
  }

  static String _escapeChar(char) {
    assert(char <= 0x10ffff);  // It's a valid unicode code point.
    const hexDigits = "0123456789ABCDEF";
    List codeUnits;
    if (char < 0x80) {
      // ASCII, a single percent encoded sequence.
      codeUnits = new List(3);
      codeUnits[0] = _PERCENT;
      codeUnits[1] = hexDigits.codeUnitAt(char >> 4);
      codeUnits[2] = hexDigits.codeUnitAt(char & 0xf);
    } else {
      // Do UTF-8 encoding of character, then percent encode bytes.
      int flag = 0xc0;  // The high-bit markers on the first byte of UTF-8.
      int encodedBytes = 2;
      if (char > 0x7ff) {
        flag = 0xe0;
        encodedBytes = 3;
        if (char > 0xffff) {
          encodedBytes = 4;
          flag = 0xf0;
        }
      }
      codeUnits = new List(3 * encodedBytes);
      int index = 0;
      while (--encodedBytes >= 0) {
        int byte = ((char >> (6 * encodedBytes)) & 0x3f) | flag;
        codeUnits[index] = _PERCENT;
        codeUnits[index + 1] = hexDigits.codeUnitAt(byte >> 4);
        codeUnits[index + 2] = hexDigits.codeUnitAt(byte & 0xf);
        index += 3;
        flag = 0x80;  // Following bytes have only high bit set.
      }
    }
    return new String.fromCharCodes(codeUnits);
  }

  /**
   * Runs through component checking that each character is valid and
   * normalize percent escapes.
   *
   * Uses [charTable] to check if a non-`%` character is allowed.
   * Each `%` character must be followed by two hex digits.
   * If the hex-digits are lower case letters, they are converted to
   * upper case.
   */
  static String _normalize(String component, int start, int end,
                           List<int> charTable) {
    StringBuffer buffer;
    int sectionStart = start;
    int index = start;
    // Loop while characters are valid and escapes correct and upper-case.
    while (index < end) {
      int char = component.codeUnitAt(index);
      if (char < 127 && (charTable[char >> 4] & (1 << (char & 0x0f))) != 0) {
        index++;
      } else {
        String replacement;
        int sourceLength;
        if (char == _PERCENT) {
          replacement = _normalizeEscape(component, index, false);
          // Returns null if we should keep the existing escape.
          if (replacement == null) {
            index += 3;
            continue;
          }
          // Returns "%" if we should escape the existing percent.
          if ("%" == replacement) {
            replacement = "%25";
            sourceLength = 1;
          } else {
            sourceLength = 3;
          }
        } else if (_isGeneralDelimiter(char)) {
          _fail(component, index, "Invalid character");
        } else {
          sourceLength = 1;
          if ((char & 0xFC00) == 0xD800) {
            // Possible lead surrogate.
            if (index + 1 < end) {
              int tail = component.codeUnitAt(index + 1);
              if ((tail & 0xFC00) == 0xDC00) {
                // Tail surrogat.
                sourceLength = 2;
                char = 0x10000 | ((char & 0x3ff) << 10) | (tail & 0x3ff);
              }
            }
          }
          replacement = _escapeChar(char);
        }
        if (buffer == null) buffer = new StringBuffer();
        buffer.write(component.substring(sectionStart, index));
        buffer.write(replacement);
        index += sourceLength;
        sectionStart = index;
      }
    }
    if (buffer == null) {
      // Makes no copy if start == 0 and end == component.length.
      return component.substring(start, end);
    }
    if (sectionStart < end) {
      buffer.write(component.substring(sectionStart, end));
    }
    return buffer.toString();
  }

  static bool _isSchemeCharacter(int ch) {
    return ch < 128 && ((_schemeTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
  }

  static bool _isGeneralDelimiter(int ch) {
    return ch <= _RIGHT_BRACKET &&
        ((_genDelimitersTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
  }

  /**
   * Returns whether the URI is absolute.
   */
  bool get isAbsolute => scheme != "" && fragment == "";

  String _merge(String base, String reference) {
    if (base == "") return "/$reference";
    return "${base.substring(0, base.lastIndexOf("/") + 1)}$reference";
  }

  bool _hasDotSegments(String path) {
    if (path.length > 0 && path.codeUnitAt(0) == _COLON) return true;
    int index = path.indexOf("/.");
    return index != -1;
  }

  String _removeDotSegments(String path) {
    if (!_hasDotSegments(path)) return path;
    List<String> output = [];
    bool appendSlash = false;
    for (String segment in path.split("/")) {
      appendSlash = false;
      if (segment == "..") {
        if (!output.isEmpty &&
            ((output.length != 1) || (output[0] != ""))) output.removeLast();
        appendSlash = true;
      } else if ("." == segment) {
        appendSlash = true;
      } else {
        output.add(segment);
      }
    }
    if (appendSlash) output.add("");
    return output.join("/");
  }

  /**
   * Resolve [reference] as an URI relative to `this`.
   *
   * First turn [reference] into a URI using [Uri.parse]. Then resolve the
   * resulting URI relative to `this`.
   *
   * Returns the resolved URI.
   *
   * See [resolveUri] for details.
   */
  Uri resolve(String reference) {
    return resolveUri(Uri.parse(reference));
  }

  /**
   * Resolve [reference] as an URI relative to `this`.
   *
   * Returns the resolved URI.
   *
   * The algorithm for resolving a reference is described in
   * [RFC-3986 Section 5]
   * (http://tools.ietf.org/html/rfc3986#section-5 "RFC-1123").
   */
  Uri resolveUri(Uri reference) {
    // From RFC 3986.
    String targetScheme;
    String targetUserInfo;
    String targetHost;
    int targetPort;
    String targetPath;
    String targetQuery;
    if (reference.scheme != "") {
      targetScheme = reference.scheme;
      targetUserInfo = reference.userInfo;
      targetHost = reference.host;
      targetPort = reference.port;
      targetPath = _removeDotSegments(reference.path);
      targetQuery = reference.query;
    } else {
      if (reference.hasAuthority) {
        targetUserInfo = reference.userInfo;
        targetHost = reference.host;
        targetPort = reference.port;
        targetPath = _removeDotSegments(reference.path);
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
            targetPath = _removeDotSegments(reference.path);
          } else {
            targetPath = _removeDotSegments(_merge(this.path, reference.path));
          }
          targetQuery = reference.query;
        }
        targetUserInfo = this.userInfo;
        targetHost = this.host;
        targetPort = this.port;
      }
      targetScheme = this.scheme;
    }
    return new Uri(scheme: targetScheme,
                   userInfo: targetUserInfo,
                   host: targetHost,
                   port: targetPort,
                   path: targetPath,
                   query: targetQuery,
                   fragment: reference.fragment);
  }

  /**
   * Returns whether the URI has an [authority] component.
   */
  bool get hasAuthority => host != "";

  /**
   * Returns the origin of the URI in the form scheme://host:port for the
   * schemes http and https.
   *
   * It is an error if the scheme is not "http" or "https".
   *
   * See: http://www.w3.org/TR/2011/WD-html5-20110405/origin-0.html#origin
   */
  String get origin {
    if (scheme == "" || _host == null || _host == "") {
      throw new StateError("Cannot use origin without a scheme: $this");
    }
    if (scheme != "http" && scheme != "https") {
      throw new StateError(
        "Origin is only applicable schemes http and https: $this");
    }
    if (_port == 0) return "$scheme://$_host";
    return "$scheme://$_host:$_port";
  }

  /**
   * Returns the file path from a file URI.
   *
   * The returned path has either Windows or non-Windows
   * semantics.
   *
   * For non-Windows semantics the slash ("/") is used to separate
   * path segments.
   *
   * For Windows semantics the backslash ("\") separator is used to
   * separate path segments.
   *
   * If the URI is absolute the path starts with a path separator
   * unless Windows semantics is used and the first path segment is a
   * drive letter. When Windows semantics is used a host component in
   * the uri in interpreted as a file server and a UNC path is
   * returned.
   *
   * The default for whether to use Windows or non-Windows semantics
   * determined from the platform Dart is running on. When running in
   * the standalone VM this is detected by the VM based on the
   * operating system. When running in a browser non-Windows semantics
   * is always used.
   *
   * To override the automatic detection of which semantics to use pass
   * a value for [windows]. Passing `true` will use Windows
   * semantics and passing `false` will use non-Windows semantics.
   *
   * If the URI ends with a slash (i.e. the last path component is
   * empty) the returned file path will also end with a slash.
   *
   * With Windows semantics URIs starting with a drive letter cannot
   * be relative to the current drive on the designated drive. That is
   * for the URI `file:///c:abc` calling `toFilePath` will throw as a
   * path segment cannot contain colon on Windows.
   *
   * Examples using non-Windows semantics (resulting of calling
   * toFilePath in comment):
   *
   *     Uri.parse("xxx/yyy");  // xxx/yyy
   *     Uri.parse("xxx/yyy/");  // xxx/yyy/
   *     Uri.parse("file:///xxx/yyy");  // /xxx/yyy
   *     Uri.parse("file:///xxx/yyy/");  // /xxx/yyy/
   *     Uri.parse("file:///C:");  // /C:
   *     Uri.parse("file:///C:a");  // /C:a
   *
   * Examples using Windows semantics (resulting URI in comment):
   *
   *     Uri.parse("xxx/yyy");  // xxx\yyy
   *     Uri.parse("xxx/yyy/");  // xxx\yyy\
   *     Uri.parse("file:///xxx/yyy");  // \xxx\yyy
   *     Uri.parse("file:///xxx/yyy/");  // \xxx\yyy/
   *     Uri.parse("file:///C:/xxx/yyy");  // C:\xxx\yyy
   *     Uri.parse("file:C:xxx/yyy");  // Throws as a path segment
   *                                   // cannot contain colon on Windows.
   *     Uri.parse("file://server/share/file");  // \\server\share\file
   *
   * If the URI is not a file URI calling this throws
   * [UnsupportedError].
   *
   * If the URI cannot be converted to a file path calling this throws
   * [UnsupportedError].
   */
  String toFilePath({bool windows}) {
    if (scheme != "" && scheme != "file") {
      throw new UnsupportedError(
          "Cannot extract a file path from a $scheme URI");
    }
    if (query != "") {
      throw new UnsupportedError(
          "Cannot extract a file path from a URI with a query component");
    }
    if (fragment != "") {
      throw new UnsupportedError(
          "Cannot extract a file path from a URI with a fragment component");
    }
    if (windows == null) windows = _isWindows;
    return windows ? _toWindowsFilePath() : _toFilePath();
  }

  String _toFilePath() {
    if (host != "") {
      throw new UnsupportedError(
          "Cannot extract a non-Windows file path from a file URI "
          "with an authority");
    }
    _checkNonWindowsPathReservedCharacters(pathSegments, false);
    var result = new StringBuffer();
    if (_isPathAbsolute) result.write("/");
    result.writeAll(pathSegments, "/");
    return result.toString();
  }

  String _toWindowsFilePath() {
    bool hasDriveLetter = false;
    var segments = pathSegments;
    if (segments.length > 0 &&
        segments[0].length == 2 &&
        segments[0].codeUnitAt(1) == _COLON) {
      _checkWindowsDriveLetter(segments[0].codeUnitAt(0), false);
      _checkWindowsPathReservedCharacters(segments, false, 1);
      hasDriveLetter = true;
    } else {
      _checkWindowsPathReservedCharacters(segments, false);
    }
    var result = new StringBuffer();
    if (_isPathAbsolute && !hasDriveLetter) result.write("\\");
    if (host != "") {
      result.write("\\");
      result.write(host);
      result.write("\\");
    }
    result.writeAll(segments, "\\");
    if (hasDriveLetter && segments.length == 1) result.write("\\");
    return result.toString();
  }

  bool get _isPathAbsolute {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('/');
  }

  void _writeAuthority(StringSink ss) {
    _addIfNonEmpty(ss, userInfo, userInfo, "@");
    ss.write(_host == null ? "null" : _host);
    if (_port != 0) {
      ss.write(":");
      ss.write(_port.toString());
    }
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    _addIfNonEmpty(sb, scheme, scheme, ':');
    if (hasAuthority || (scheme == "file")) {
      sb.write("//");
      _writeAuthority(sb);
    }
    sb.write(path);
    _addIfNonEmpty(sb, query, "?", query);
    _addIfNonEmpty(sb, fragment, "#", fragment);
    return sb.toString();
  }

  bool operator==(other) {
    if (other is! Uri) return false;
    Uri uri = other;
    return scheme == uri.scheme &&
        userInfo == uri.userInfo &&
        host == uri.host &&
        port == uri.port &&
        path == uri.path &&
        query == uri.query &&
        fragment == uri.fragment;
  }

  int get hashCode {
    int combine(part, current) {
      // The sum is truncated to 30 bits to make sure it fits into a Smi.
      return (current * 31 + part.hashCode) & 0x3FFFFFFF;
    }
    return combine(scheme, combine(userInfo, combine(host, combine(port,
        combine(path, combine(query, combine(fragment, 1)))))));
  }

  static void _addIfNonEmpty(StringBuffer sb, String test,
                             String first, String second) {
    if ("" != test) {
      sb.write(first);
      sb.write(second);
    }
  }

  /**
   * Encode the string [component] using percent-encoding to make it
   * safe for literal use as a URI component.
   *
   * All characters except uppercase and lowercase letters, digits and
   * the characters `-_.!~*'()` are percent-encoded. This is the
   * set of characters specified in RFC 2396 and the which is
   * specified for the encodeUriComponent in ECMA-262 version 5.1.
   *
   * When manually encoding path segments or query components remember
   * to encode each part separately before building the path or query
   * string.
   *
   * For encoding the query part consider using
   * [encodeQueryComponent].
   *
   * To avoid the need for explicitly encoding use the [pathSegments]
   * and [queryParameters] optional named arguments when constructing
   * a [Uri].
   */
  static String encodeComponent(String component) {
    return _uriEncode(_unreserved2396Table, component);
  }

  /**
   * Encode the string [component] according to the HTML 4.01 rules
   * for encoding the posting of a HTML form as a query string
   * component.
   *
   * Encode the string [component] according to the HTML 4.01 rules
   * for encoding the posting of a HTML form as a query string
   * component.

   * The component is first encoded to bytes using [encoding].
   * The default is to use [UTF8] encoding, which preserves all
   * the characters that don't need encoding.

   * Then the resulting bytes are "percent-encoded". This transforms
   * spaces (U+0020) to a plus sign ('+') and all bytes that are not
   * the ASCII decimal digits, letters or one of '-._~' are written as
   * a percent sign '%' followed by the two-digit hexadecimal
   * representation of the byte.

   * Note that the set of characters which are percent-encoded is a
   * superset of what HTML 4.01 requires, since it refers to RFC 1738
   * for reserved characters.
   *
   * When manually encoding query components remember to encode each
   * part separately before building the query string.
   *
   * To avoid the need for explicitly encoding the query use the
   * [queryParameters] optional named arguments when constructing a
   * [Uri].
   *
   * See http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.2 for more
   * details.
   */
  static String encodeQueryComponent(String component,
                                     {Encoding encoding: UTF8}) {
    return _uriEncode(
        _unreservedTable, component, encoding: encoding, spaceToPlus: true);
  }

  /**
   * Decodes the percent-encoding in [encodedComponent].
   *
   * Note that decoding a URI component might change its meaning as
   * some of the decoded characters could be characters with are
   * delimiters for a given URI componene type. Always split a URI
   * component using the delimiters for the component before decoding
   * the individual parts.
   *
   * For handling the [path] and [query] components consider using
   * [pathSegments] and [queryParameters] to get the separated and
   * decoded component.
   */
  static String decodeComponent(String encodedComponent) {
    return _uriDecode(encodedComponent);
  }

  /**
   * Decodes the percent-encoding in [encodedComponent], converting
   * pluses to spaces.
   *
   * It will create a byte-list of the decoded characters, and then use
   * [encoding] to decode the byte-list to a String. The default encoding is
   * UTF-8.
   */
  static String decodeQueryComponent(
      String encodedComponent,
      {Encoding encoding: UTF8}) {
    return _uriDecode(encodedComponent, plusToSpace: true, encoding: encoding);
  }

  /**
   * Encode the string [uri] using percent-encoding to make it
   * safe for literal use as a full URI.
   *
   * All characters except uppercase and lowercase letters, digits and
   * the characters `!#$&'()*+,-./:;=?@_~` are percent-encoded. This
   * is the set of characters specified in in ECMA-262 version 5.1 for
   * the encodeURI function .
   */
  static String encodeFull(String uri) {
    return _uriEncode(_encodeFullTable, uri);
  }

  /**
   * Decodes the percent-encoding in [uri].
   *
   * Note that decoding a full URI might change its meaning as some of
   * the decoded characters could be reserved characters. In most
   * cases an encoded URI should be parsed into components using
   * [Uri.parse] before decoding the separate components.
   */
  static String decodeFull(String uri) {
    return _uriDecode(uri);
  }

  /**
   * Returns the [query] split into a map according to the rules
   * specified for FORM post in the
   * [HTML 4.01 specification section 17.13.4]
   * (http://www.w3.org/TR/REC-html40/interact/forms.html#h-17.13.4
   * "HTML 4.01 section 17.13.4"). Each key and value in the returned
   * map has been decoded. If the [query]
   * is the empty string an empty map is returned.
   *
   * Keys in the query string that have no value are mapped to the
   * empty string.
   *
   * Each query component will be decoded using [encoding]. The default encoding
   * is UTF-8.
   */
  static Map<String, String> splitQueryString(String query,
                                              {Encoding encoding: UTF8}) {
    return query.split("&").fold({}, (map, element) {
      int index = element.indexOf("=");
      if (index == -1) {
        if (element != "") {
          map[decodeQueryComponent(element, encoding: encoding)] = "";
        }
      } else if (index != 0) {
        var key = element.substring(0, index);
        var value = element.substring(index + 1);
        map[Uri.decodeQueryComponent(key, encoding: encoding)] =
            decodeQueryComponent(value, encoding: encoding);
      }
      return map;
    });
  }

  /**
   * Parse the [host] as an IP version 4 (IPv4) address, returning the address
   * as a list of 4 bytes in network byte order (big endian).
   *
   * Throws a [FormatException] if [host] is not a valid IPv4 address
   * representation.
   */
  static List<int> parseIPv4Address(String host) {
    void error(String msg) {
      throw new FormatException('Illegal IPv4 address, $msg');
    }
    var bytes = host.split('.');
    if (bytes.length != 4) {
      error('IPv4 address should contain exactly 4 parts');
    }
    // TODO(ajohnsen): Consider using Uint8List.
    return bytes
        .map((byteString) {
          int byte = int.parse(byteString);
          if (byte < 0 || byte > 255) {
            error('each part must be in the range of `0..255`');
          }
          return byte;
        })
        .toList();
  }

  /**
   * Parse the [host] as an IP version 6 (IPv6) address, returning the address
   * as a list of 16 bytes in network byte order (big endian).
   *
   * Throws a [FormatException] if [host] is not a valid IPv6 address
   * representation.
   *
   * Acts on the substring from [start] to [end]. If [end] is omitted, it
   * defaults ot the end of the string.
   *
   * Some examples of IPv6 addresses:
   *  * ::1
   *  * FEDC:BA98:7654:3210:FEDC:BA98:7654:3210
   *  * 3ffe:2a00:100:7031::1
   *  * ::FFFF:129.144.52.38
   *  * 2010:836B:4179::836B:4179
   */
  static List<int> parseIPv6Address(String host, [int start = 0, int end]) {
    if (end == null) end = host.length;
    // An IPv6 address consists of exactly 8 parts of 1-4 hex digits, seperated
    // by `:`'s, with the following exceptions:
    //
    //  - One (and only one) wildcard (`::`) may be present, representing a fill
    //    of 0's. The IPv6 `::` is thus 16 bytes of `0`.
    //  - The last two parts may be replaced by an IPv4 address.
    void error(String msg) {
      throw new FormatException('Illegal IPv6 address, $msg');
    }
    int parseHex(int start, int end) {
      if (end - start > 4) {
        error('an IPv6 part can only contain a maximum of 4 hex digits');
      }
      int value = int.parse(host.substring(start, end), radix: 16);
      if (value < 0 || value > (1 << 16) - 1) {
        error('each part must be in the range of `0x0..0xFFFF`');
      }
      return value;
    }
    if (host.length < 2) error('address is too short');
    List<int> parts = [];
    bool wildcardSeen = false;
    int partStart = start;
    // Parse all parts, except a potential last one.
    for (int i = start; i < end; i++) {
      if (host.codeUnitAt(i) == _COLON) {
        if (i == start) {
          // If we see a `:` in the beginning, expect wildcard.
          i++;
          if (host.codeUnitAt(i) != _COLON) {
            error('invalid start colon.');
          }
          partStart = i;
        }
        if (i == partStart) {
          // Wildcard. We only allow one.
          if (wildcardSeen) {
            error('only one wildcard `::` is allowed');
          }
          wildcardSeen = true;
          parts.add(-1);
        } else {
          // Found a single colon. Parse [partStart..i] as a hex entry.
          parts.add(parseHex(partStart, i));
        }
        partStart = i + 1;
      }
    }
    if (parts.length == 0) error('too few parts');
    bool atEnd = (partStart == end);
    bool isLastWildcard = (parts.last == -1);
    if (atEnd && !isLastWildcard) {
      error('expected a part after last `:`');
    }
    if (!atEnd) {
      try {
        parts.add(parseHex(partStart, end));
      } catch (e) {
        // Failed to parse the last chunk as hex. Try IPv4.
        try {
          List<int> last = parseIPv4Address(host.substring(partStart, end));
          parts.add(last[0] << 8 | last[1]);
          parts.add(last[2] << 8 | last[3]);
        } catch (e) {
          error('invalid end of IPv6 address.');
        }
      }
    }
    if (wildcardSeen) {
      if (parts.length > 7) {
        error('an address with a wildcard must have less than 7 parts');
      }
    } else if (parts.length != 8) {
      error('an address without a wildcard must contain exactly 8 parts');
    }
    // TODO(ajohnsen): Consider using Uint8List.
    List bytes = new List<int>(16);
    for (int i = 0, index = 0; i < parts.length; i++) {
      int value = parts[i];
      if (value == -1) {
        int wildCardLength = 9 - parts.length;
        for (int j = 0; j < wildCardLength; j++) {
          bytes[index] = 0;
          bytes[index + 1] = 0;
          index += 2;
        }
      } else {
        bytes[index] = value >> 8;
        bytes[index + 1] = value & 0xff;
        index += 2;
      }
    }
    return bytes;
  }

  // Frequently used character codes.
  static const int _SPACE = 0x20;
  static const int _DOUBLE_QUOTE = 0x22;
  static const int _NUMBER_SIGN = 0x23;
  static const int _PERCENT = 0x25;
  static const int _ASTERISK = 0x2A;
  static const int _PLUS = 0x2B;
  static const int _SLASH = 0x2F;
  static const int _ZERO = 0x30;
  static const int _NINE = 0x39;
  static const int _COLON = 0x3A;
  static const int _LESS = 0x3C;
  static const int _GREATER = 0x3E;
  static const int _QUESTION = 0x3F;
  static const int _AT_SIGN = 0x40;
  static const int _UPPER_CASE_A = 0x41;
  static const int _UPPER_CASE_F = 0x46;
  static const int _UPPER_CASE_Z = 0x5A;
  static const int _LEFT_BRACKET = 0x5B;
  static const int _BACKSLASH = 0x5C;
  static const int _RIGHT_BRACKET = 0x5D;
  static const int _LOWER_CASE_A = 0x61;
  static const int _LOWER_CASE_F = 0x66;
  static const int _LOWER_CASE_Z = 0x7A;
  static const int _BAR = 0x7C;

  /**
   * This is the internal implementation of JavaScript's encodeURI function.
   * It encodes all characters in the string [text] except for those
   * that appear in [canonicalTable], and returns the escaped string.
   */
  static String _uriEncode(List<int> canonicalTable,
                           String text,
                           {Encoding encoding: UTF8,
                            bool spaceToPlus: false}) {
    byteToHex(byte, buffer) {
      const String hex = '0123456789ABCDEF';
      buffer.writeCharCode(hex.codeUnitAt(byte >> 4));
      buffer.writeCharCode(hex.codeUnitAt(byte & 0x0f));
    }

    // Encode the string into bytes then generate an ASCII only string
    // by percent encoding selected bytes.
    StringBuffer result = new StringBuffer();
    var bytes = encoding.encode(text);
    for (int i = 0; i < bytes.length; i++) {
      int byte = bytes[i];
      if (byte < 128 &&
          ((canonicalTable[byte >> 4] & (1 << (byte & 0x0f))) != 0)) {
        result.writeCharCode(byte);
      } else if (spaceToPlus && byte == _SPACE) {
        result.writeCharCode(_PLUS);
      } else {
        result.writeCharCode(_PERCENT);
        byteToHex(byte, result);
      }
    }
    return result.toString();
  }

  /**
   * Convert a byte (2 character hex sequence) in string [s] starting
   * at position [pos] to its ordinal value
   */
  static int _hexCharPairToByte(String s, int pos) {
    int byte = 0;
    for (int i = 0; i < 2; i++) {
      var charCode = s.codeUnitAt(pos + i);
      if (0x30 <= charCode && charCode <= 0x39) {
        byte = byte * 16 + charCode - 0x30;
      } else {
        // Check ranges A-F (0x41-0x46) and a-f (0x61-0x66).
        charCode |= 0x20;
        if (0x61 <= charCode && charCode <= 0x66) {
          byte = byte * 16 + charCode - 0x57;
        } else {
          throw new ArgumentError("Invalid URL encoding");
        }
      }
    }
    return byte;
  }

  /**
   * Uri-decode a percent-encoded string.
   *
   * It unescapes the string [text] and returns the unescaped string.
   *
   * This function is similar to the JavaScript-function `decodeURI`.
   *
   * If [plusToSpace] is `true`, plus characters will be converted to spaces.
   *
   * The decoder will create a byte-list of the percent-encoded parts, and then
   * decode the byte-list using [encoding]. The default encodingis UTF-8.
   */
  static String _uriDecode(String text,
                           {bool plusToSpace: false,
                            Encoding encoding: UTF8}) {
    // First check whether there is any characters which need special handling.
    bool simple = true;
    for (int i = 0; i < text.length && simple; i++) {
      var codeUnit = text.codeUnitAt(i);
      simple = codeUnit != _PERCENT && codeUnit != _PLUS;
    }
    List<int> bytes;
    if (simple) {
      if (encoding == UTF8 || encoding == LATIN1) {
        return text;
      } else {
        bytes = text.codeUnits;
      }
    } else {
      bytes = new List();
      for (int i = 0; i < text.length; i++) {
        var codeUnit = text.codeUnitAt(i);
        if (codeUnit > 127) {
          throw new ArgumentError("Illegal percent encoding in URI");
        }
        if (codeUnit == _PERCENT) {
          if (i + 3 > text.length) {
            throw new ArgumentError('Truncated URI');
          }
          bytes.add(_hexCharPairToByte(text, i + 1));
          i += 2;
        } else if (plusToSpace && codeUnit == _PLUS) {
          bytes.add(_SPACE);
        } else {
          bytes.add(codeUnit);
        }
      }
    }
    return encoding.decode(bytes);
  }

  static bool _isAlphabeticCharacter(int codeUnit)
    => (codeUnit >= _LOWER_CASE_A && codeUnit <= _LOWER_CASE_Z) ||
       (codeUnit >= _UPPER_CASE_A && codeUnit <= _UPPER_CASE_Z);

  // Tables of char-codes organized as a bit vector of 128 bits where
  // each bit indicate whether a character code on the 0-127 needs to
  // be escaped or not.

  // The unreserved characters of RFC 3986.
  static const _unreservedTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                           -.
      0x6000,   // 0x20 - 0x2f  0000000000000110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // The unreserved characters of RFC 2396.
  static const _unreserved2396Table = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !     '()*  -.
      0x6782,   // 0x20 - 0x2f  0100000111100110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Table of reserved characters specified by ECMAScript 5.
  static const _encodeFullTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               ! #$ &'()*+,-./
      0xffda,   // 0x20 - 0x2f  0101101111111111
                //              0123456789:; = ?
      0xafff,   // 0x30 - 0x3f  1111111111110101
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the scheme.
  static const _schemeTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                         + -.
      0x6800,   // 0x20 - 0x2f  0000000000010110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ
      0x07ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz
      0x07ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in scheme except for upper case letters.
  static const _schemeLowerTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                         + -.
      0x6800,   // 0x20 - 0x2f  0000000000010110
                //              0123456789
      0x03ff,   // 0x30 - 0x3f  1111111111000000
                //
      0x0000,   // 0x40 - 0x4f  0111111111111111
                //
      0x0000,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz
      0x07ff];  // 0x70 - 0x7f  1111111111100010

  // Sub delimiter characters combined with unreserved as of 3986.
  // sub-delims  = "!" / "$" / "&" / "'" / "(" / ")"
  //             / "*" / "+" / "," / ";" / "="
  // RFC 3986 section 2.3.
  // unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
  static const _subDelimitersTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-.
      0x7fd2,   // 0x20 - 0x2f  0100101111111110
                //              0123456789 ; =
      0x2bff,   // 0x30 - 0x3f  1111111111010100
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // General delimiter characters, RFC 3986 section 2.2.
  // gen-delims  = ":" / "/" / "?" / "#" / "[" / "]" / "@"
  //
  static const _genDelimitersTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //                 #           /
      0x8008,   // 0x20 - 0x2f  0001000000000001
                //                        :    ?
      0x8400,   // 0x30 - 0x3f  0000000000100001
                //              @
      0x0001,   // 0x40 - 0x4f  1000000000000000
                //                         [ ]
      0x2800,   // 0x50 - 0x5f  0000000000010100
                //
      0x0000,   // 0x60 - 0x6f  0000000000000000
                //
      0x0000];  // 0x70 - 0x7f  0000000000000000

  // Characters allowed in the userinfo as of RFC 3986.
  // RFC 3986 Apendix A
  // userinfo = *( unreserved / pct-encoded / sub-delims / ':')
  static const _userinfoTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-.
      0x7fd2,   // 0x20 - 0x2f  0100101111111110
                //              0123456789:; =
      0x2fff,   // 0x30 - 0x3f  1111111111110100
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the reg-name as of RFC 3986.
  // RFC 3986 Apendix A
  // reg-name = *( unreserved / pct-encoded / sub-delims )
  static const _regNameTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $%&'()*+,-.
      0x7ff2,   // 0x20 - 0x2f  0100111111111110
                //              0123456789 ; =
      0x2bff,   // 0x30 - 0x3f  1111111111010100
                //               ABCDEFGHIJKLMNO
      0xfffe,   // 0x40 - 0x4f  0111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the path as of RFC 3986.
  // RFC 3986 section 3.3.
  // pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
  static const _pathCharTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-.
      0x7fd2,   // 0x20 - 0x2f  0100101111111110
                //              0123456789:; =
      0x2fff,   // 0x30 - 0x3f  1111111111110100
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the path as of RFC 3986.
  // RFC 3986 section 3.3 *and* slash.
  static const _pathCharOrSlashTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-./
      0xffd2,   // 0x20 - 0x2f  0100101111111111
                //              0123456789:; =
      0x2fff,   // 0x30 - 0x3f  1111111111110100
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111

                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010

  // Characters allowed in the query as of RFC 3986.
  // RFC 3986 section 3.4.
  // query = *( pchar / "/" / "?" )
  static const _queryCharTable = const [
                //             LSB            MSB
                //              |              |
      0x0000,   // 0x00 - 0x0f  0000000000000000
      0x0000,   // 0x10 - 0x1f  0000000000000000
                //               !  $ &'()*+,-./
      0xffd2,   // 0x20 - 0x2f  0100101111111111
                //              0123456789:; = ?
      0xafff,   // 0x30 - 0x3f  1111111111110101
                //              @ABCDEFGHIJKLMNO
      0xffff,   // 0x40 - 0x4f  1111111111111111
                //              PQRSTUVWXYZ    _
      0x87ff,   // 0x50 - 0x5f  1111111111100001
                //               abcdefghijklmno
      0xfffe,   // 0x60 - 0x6f  0111111111111111
                //              pqrstuvwxyz   ~
      0x47ff];  // 0x70 - 0x7f  1111111111100010
}
