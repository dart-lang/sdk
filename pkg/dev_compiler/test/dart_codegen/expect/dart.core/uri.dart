part of dart.core;

class Uri {
  final String _host;
  num _port;
  String _path;
  final String scheme;
  String get authority {
    if (!hasAuthority) return "";
    var sb = new StringBuffer();
    _writeAuthority(sb);
    return sb.toString();
  }
  final String _userInfo;
  String get userInfo => _userInfo;
  String get host {
    if (_host == null) return "";
    if (_host.startsWith('[')) {
      return _host.substring(1, _host.length - 1);
    }
    return _host;
  }
  int get port {
    if (_port == null) return _defaultPort(scheme);
    return DDC$RT.cast(_port, num, int, "CastGeneral",
        """line 94, column 12 of dart:core/uri.dart: """, _port is int, true);
  }
  static int _defaultPort(String scheme) {
    if (scheme == "http") return 80;
    if (scheme == "https") return 443;
    return 0;
  }
  String get path => _path;
  final String _query;
  String get query => (_query == null) ? "" : _query;
  final String _fragment;
  String get fragment => (_fragment == null) ? "" : _fragment;
  List<String> _pathSegments;
  Map<String, String> _queryParameters;
  static Uri parse(String uri) {
    bool isRegName(int ch) {
      return ch < 128 && ((_regNameTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
    }
    const int EOI = -1;
    String scheme = "";
    String userinfo = "";
    String host = null;
    num port = null;
    String path = null;
    String query = null;
    String fragment = null;
    int index = 0;
    int pathStart = 0;
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
        int portNumber;
        if (lastColon + 1 < index) {
          portNumber = 0;
          for (int i = lastColon + 1; i < index; i++) {
            int digit = uri.codeUnitAt(i);
            if (_ZERO > digit || _NINE < digit) {
              _fail(uri, i, "Invalid port number");
            }
            portNumber = portNumber * 10 + (digit - _ZERO);
          }
        }
        port = _makePort(portNumber, scheme);
        hostEnd = lastColon;
      }
      host = _makeHost(uri, hostStart, hostEnd, true);
      if (index < uri.length) {
        char = uri.codeUnitAt(index);
      }
    }
    const int NOT_IN_PATH = 0;
    const int IN_PATH = 1;
    const int ALLOW_AUTH = 2;
    int state = NOT_IN_PATH;
    int i = index;
    while (i < uri.length) {
      char = uri.codeUnitAt(i);
      if (char == _QUESTION || char == _NUMBER_SIGN) {
        state = NOT_IN_PATH;
        break;
      }
      if (char == _SLASH) {
        state = (i == 0) ? ALLOW_AUTH : IN_PATH;
        break;
      }
      if (char == _COLON) {
        if (i == 0) _fail(uri, 0, "Invalid empty scheme");
        scheme = _makeScheme(uri, i);
        i++;
        pathStart = i;
        if (i == uri.length) {
          char = EOI;
          state = NOT_IN_PATH;
        } else {
          char = uri.codeUnitAt(i);
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
      i++;
      char = EOI;
    }
    index = i;
    if (state == ALLOW_AUTH) {
      assert(char == _SLASH);
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
    bool isFile = (scheme == "file");
    bool ensureLeadingSlash = host != null;
    path = _makePath(uri, pathStart, index, null, ensureLeadingSlash, isFile);
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
    return new Uri._internal(
        scheme, userinfo, host, port, path, query, fragment);
  }
  static void _fail(String uri, int index, String message) {
    throw new FormatException(message, uri, index);
  }
  Uri._internal(this.scheme, this._userInfo, this._host, this._port, this._path,
      this._query, this._fragment);
  factory Uri({String scheme: "", String userInfo: "", String host, int port,
      String path, Iterable<String> pathSegments, String query,
      Map<String, String> queryParameters, String fragment}) {
    scheme = _makeScheme(scheme, _stringOrNullLength(scheme));
    userInfo = _makeUserInfo(userInfo, 0, _stringOrNullLength(userInfo));
    host = _makeHost(host, 0, _stringOrNullLength(host), false);
    if (query == "") query = null;
    query = _makeQuery(query, 0, _stringOrNullLength(query), queryParameters);
    fragment = _makeFragment(fragment, 0, _stringOrNullLength(fragment));
    port = _makePort(port, scheme);
    bool isFile = (scheme == "file");
    if (host == null && (userInfo.isNotEmpty || port != null || isFile)) {
      host = "";
    }
    bool ensureLeadingSlash = host != null;
    path = _makePath(path, 0, _stringOrNullLength(path), pathSegments,
        ensureLeadingSlash, isFile);
    return new Uri._internal(
        scheme, userInfo, host, port, path, query, fragment);
  }
  factory Uri.http(String authority, String unencodedPath,
      [Map<String, String> queryParameters]) {
    return _makeHttpUri("http", authority, unencodedPath, queryParameters);
  }
  factory Uri.https(String authority, String unencodedPath,
      [Map<String, String> queryParameters]) {
    return _makeHttpUri("https", authority, unencodedPath, queryParameters);
  }
  static Uri _makeHttpUri(String scheme, String authority, String unencodedPath,
      Map<String, String> queryParameters) {
    var userInfo = "";
    var host = null;
    var port = null;
    if (authority != null && authority.isNotEmpty) {
      var hostStart = 0;
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
        for (; hostEnd < authority.length; hostEnd++) {
          if (authority.codeUnitAt(hostEnd) == _RIGHT_BRACKET) break;
        }
        if (hostEnd == authority.length) {
          throw new FormatException(
              "Invalid IPv6 host entry.", authority, hostStart);
        }
        parseIPv6Address(authority, hostStart + 1, hostEnd);
        hostEnd++;
        if (hostEnd != authority.length &&
            authority.codeUnitAt(hostEnd) != _COLON) {
          throw new FormatException(
              "Invalid end of authority", authority, hostEnd);
        }
      }
      bool hasPort = false;
      for (; hostEnd < authority.length; hostEnd++) {
        if (authority.codeUnitAt(hostEnd) == _COLON) {
          var portString = authority.substring(hostEnd + 1);
          if (portString.isNotEmpty) port = int.parse(portString);
          break;
        }
      }
      host = authority.substring(hostStart, hostEnd);
    }
    return new Uri(
        scheme: scheme,
        userInfo: userInfo,
        host: host,
        port: port,
        pathSegments: unencodedPath.split("/"),
        queryParameters: queryParameters);
  }
  factory Uri.file(String path, {bool windows}) {
    windows = windows == null ? Uri._isWindows : windows;
    return ((__x9) => DDC$RT.cast(__x9, dynamic, Uri, "CastGeneral",
        """line 698, column 12 of dart:core/uri.dart: """, __x9 is Uri,
        true))(windows ? _makeWindowsFileUrl(path) : _makeFileUri(path));
  }
  external static Uri get base;
  external static bool get _isWindows;
  static _checkNonWindowsPathReservedCharacters(
      List<String> segments, bool argumentError) {
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
  static _checkWindowsPathReservedCharacters(
      List<String> segments, bool argumentError, [int firstSegment = 0]) {
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
      throw new ArgumentError(
          "Illegal drive letter " + new String.fromCharCode(charCode));
    } else {
      throw new UnsupportedError(
          "Illegal drive letter " + new String.fromCharCode(charCode));
    }
  }
  static _makeFileUri(String path) {
    String sep = "/";
    if (path.startsWith(sep)) {
      return new Uri(scheme: "file", pathSegments: path.split(sep));
    } else {
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
      var pathSegments = path.split(sep);
      _checkWindowsPathReservedCharacters(pathSegments, true, 1);
      return new Uri(scheme: "file", pathSegments: pathSegments);
    }
    if (path.length > 0 && path[0] == sep) {
      if (path.length > 1 && path[1] == sep) {
        int pathStart = path.indexOf("\\", 2);
        String hostPart =
            pathStart == -1 ? path.substring(2) : path.substring(2, pathStart);
        String pathPart = pathStart == -1 ? "" : path.substring(pathStart + 1);
        var pathSegments = pathPart.split(sep);
        _checkWindowsPathReservedCharacters(pathSegments, true);
        return new Uri(
            scheme: "file", host: hostPart, pathSegments: pathSegments);
      } else {
        var pathSegments = path.split(sep);
        _checkWindowsPathReservedCharacters(pathSegments, true);
        return new Uri(scheme: "file", pathSegments: pathSegments);
      }
    } else {
      var pathSegments = path.split(sep);
      _checkWindowsPathReservedCharacters(pathSegments, true);
      return new Uri(pathSegments: pathSegments);
    }
  }
  Uri replace({String scheme, String userInfo, String host, int port,
      String path, Iterable<String> pathSegments, String query,
      Map<String, String> queryParameters, String fragment}) {
    bool schemeChanged = false;
    if (scheme != null) {
      scheme = _makeScheme(scheme, scheme.length);
      schemeChanged = true;
    } else {
      scheme = this.scheme;
    }
    bool isFile = (scheme == "file");
    if (userInfo != null) {
      userInfo = _makeUserInfo(userInfo, 0, userInfo.length);
    } else {
      userInfo = this.userInfo;
    }
    if (port != null) {
      port = _makePort(port, scheme);
    } else {
      port = ((__x10) => DDC$RT.cast(__x10, num, int, "CastGeneral",
          """line 889, column 14 of dart:core/uri.dart: """, __x10 is int,
          true))(this._port);
      if (schemeChanged) {
        port = _makePort(port, scheme);
      }
    }
    if (host != null) {
      host = _makeHost(host, 0, host.length, false);
    } else if (this.hasAuthority) {
      host = this.host;
    } else if (userInfo.isNotEmpty || port != null || isFile) {
      host = "";
    }
    bool ensureLeadingSlash = (host != null);
    if (path != null || pathSegments != null) {
      path = _makePath(path, 0, _stringOrNullLength(path), pathSegments,
          ensureLeadingSlash, isFile);
    } else {
      path = this.path;
      if ((isFile || (ensureLeadingSlash && !path.isEmpty)) &&
          !path.startsWith('/')) {
        path = "/$path";
      }
    }
    if (query != null || queryParameters != null) {
      query = _makeQuery(query, 0, _stringOrNullLength(query), queryParameters);
    } else if (this.hasQuery) {
      query = this.query;
    }
    if (fragment != null) {
      fragment = _makeFragment(fragment, 0, fragment.length);
    } else if (this.hasFragment) {
      fragment = this.fragment;
    }
    return new Uri._internal(
        scheme, userInfo, host, port, path, query, fragment);
  }
  List<String> get pathSegments {
    if (_pathSegments == null) {
      var pathToSplit = !path.isEmpty && path.codeUnitAt(0) == _SLASH
          ? path.substring(1)
          : path;
      _pathSegments = ((__x11) => DDC$RT.cast(__x11, DDC$RT.type(
                  (DDC$dartDOTcollection$.UnmodifiableListView<dynamic> _) {}),
              DDC$RT.type((List<String> _) {}), "CastExact",
              """line 945, column 23 of dart:core/uri.dart: """,
              __x11 is List<String>, false))(new UnmodifiableListView(
          pathToSplit == ""
              ? const <String>[]
              : pathToSplit
                  .split("/")
                  .map(Uri.decodeComponent)
                  .toList(growable: false)));
    }
    return _pathSegments;
  }
  Map<String, String> get queryParameters {
    if (_queryParameters == null) {
      _queryParameters = ((__x12) => DDC$RT.cast(__x12, DDC$RT.type(
          (DDC$dartDOTcollection$.UnmodifiableMapView<dynamic, dynamic> _) {
      }), DDC$RT.type((Map<String, String> _) {}), "CastExact",
          """line 969, column 26 of dart:core/uri.dart: """,
          __x12 is Map<String, String>,
          false))(new UnmodifiableMapView(splitQueryString(query)));
    }
    return _queryParameters;
  }
  static int _makePort(int port, String scheme) {
    if (port != null && port == _defaultPort(scheme)) return ((__x13) => DDC$RT
        .cast(__x13, Null, int, "CastLiteral",
            """line 976, column 62 of dart:core/uri.dart: """, __x13 is int,
            true))(null);
    return port;
  }
  static String _makeHost(String host, int start, int end, bool strictIPv6) {
    if (host == null) return null;
    if (start == end) return "";
    if (host.codeUnitAt(start) == _LEFT_BRACKET) {
      if (host.codeUnitAt(end - 1) != _RIGHT_BRACKET) {
        _fail(host, start, 'Missing end `]` to match `[` in host');
      }
      parseIPv6Address(host, start + 1, end - 1);
      return host.substring(start, end).toLowerCase();
    }
    if (!strictIPv6) {
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
  static String _normalizeRegName(String host, int start, int end) {
    StringBuffer buffer;
    int sectionStart = start;
    int index = start;
    bool isNormalized = true;
    while (index < end) {
      int char = host.codeUnitAt(index);
      if (char == _PERCENT) {
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
  static String _makeScheme(String scheme, int end) {
    if (end == 0) return "";
    final int firstCodeUnit = scheme.codeUnitAt(0);
    if (!_isAlphabeticCharacter(firstCodeUnit)) {
      _fail(scheme, 0, "Scheme not starting with alphabetic character");
    }
    bool allLowercase = firstCodeUnit >= _LOWER_CASE_A;
    for (int i = 0; i < end; i++) {
      final int codeUnit = scheme.codeUnitAt(i);
      if (!_isSchemeCharacter(codeUnit)) {
        _fail(scheme, i, "Illegal scheme character");
      }
      if (codeUnit < _LOWER_CASE_A || codeUnit > _LOWER_CASE_Z) {
        allLowercase = false;
      }
    }
    scheme = scheme.substring(0, end);
    if (!allLowercase) scheme = scheme.toLowerCase();
    return scheme;
  }
  static String _makeUserInfo(String userInfo, int start, int end) {
    if (userInfo == null) return "";
    return _normalize(userInfo, start, end, DDC$RT.cast(_userinfoTable, dynamic,
        DDC$RT.type((List<int> _) {}), "CastGeneral",
        """line 1126, column 45 of dart:core/uri.dart: """,
        _userinfoTable is List<int>, false));
  }
  static String _makePath(String path, int start, int end,
      Iterable<String> pathSegments, bool ensureLeadingSlash, bool isFile) {
    if (path == null && pathSegments == null) return isFile ? "/" : "";
    if (path != null && pathSegments != null) {
      throw new ArgumentError('Both path and pathSegments specified');
    }
    var result;
    if (path != null) {
      result = _normalize(path, start, end, DDC$RT.cast(_pathCharOrSlashTable,
          dynamic, DDC$RT.type((List<int> _) {}), "CastGeneral",
          """line 1139, column 45 of dart:core/uri.dart: """,
          _pathCharOrSlashTable is List<int>, false));
    } else {
      result = pathSegments
          .map((s) => _uriEncode(DDC$RT.cast(_pathCharTable, dynamic,
              DDC$RT.type((List<int> _) {}), "CastGeneral",
              """line 1141, column 51 of dart:core/uri.dart: """,
              _pathCharTable is List<int>, false), DDC$RT.cast(s, dynamic,
              String, "CastGeneral",
              """line 1141, column 67 of dart:core/uri.dart: """, s is String,
              true)))
          .join("/");
    }
    if (result.isEmpty) {
      if (isFile) return "/";
    } else if ((isFile || ensureLeadingSlash) &&
        result.codeUnitAt(0) != _SLASH) {
      return "/$result";
    }
    return DDC$RT.cast(result, dynamic, String, "CastGeneral",
        """line 1149, column 12 of dart:core/uri.dart: """, result is String,
        true);
  }
  static String _makeQuery(
      String query, int start, int end, Map<String, String> queryParameters) {
    if (query == null && queryParameters == null) return null;
    if (query != null && queryParameters != null) {
      throw new ArgumentError('Both query and queryParameters specified');
    }
    if (query != null) return _normalize(query, start, end, DDC$RT.cast(
        _queryCharTable, dynamic, DDC$RT.type((List<int> _) {}), "CastGeneral",
        """line 1158, column 61 of dart:core/uri.dart: """,
        _queryCharTable is List<int>, false));
    var result = new StringBuffer();
    var first = true;
    queryParameters.forEach((key, value) {
      if (!first) {
        result.write("&");
      }
      first = false;
      result.write(Uri.encodeQueryComponent(DDC$RT.cast(key, dynamic, String,
          "CastGeneral", """line 1167, column 45 of dart:core/uri.dart: """,
          key is String, true)));
      if (value != null && !value.isEmpty) {
        result.write("=");
        result.write(Uri.encodeQueryComponent(DDC$RT.cast(value, dynamic,
            String, "CastGeneral",
            """line 1170, column 47 of dart:core/uri.dart: """, value is String,
            true)));
      }
    });
    return result.toString();
  }
  static String _makeFragment(String fragment, int start, int end) {
    if (fragment == null) return null;
    return _normalize(fragment, start, end, DDC$RT.cast(_queryCharTable,
        dynamic, DDC$RT.type((List<int> _) {}), "CastGeneral",
        """line 1178, column 45 of dart:core/uri.dart: """,
        _queryCharTable is List<int>, false));
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
  static String _normalizeEscape(String source, int index, bool lowerCase) {
    assert(source.codeUnitAt(index) == _PERCENT);
    if (index + 2 >= source.length) {
      return "%";
    }
    int firstDigit = source.codeUnitAt(index + 1);
    int secondDigit = source.codeUnitAt(index + 2);
    if (!_isHexDigit(firstDigit) || !_isHexDigit(secondDigit)) {
      return "%";
    }
    int value = _hexValue(firstDigit) * 16 + _hexValue(secondDigit);
    if (_isUnreservedChar(value)) {
      if (lowerCase && _UPPER_CASE_A <= value && _UPPER_CASE_Z >= value) {
        value |= 0x20;
      }
      return new String.fromCharCode(value);
    }
    if (firstDigit >= _LOWER_CASE_A || secondDigit >= _LOWER_CASE_A) {
      return source.substring(index, index + 3).toUpperCase();
    }
    return null;
  }
  static bool _isUnreservedChar(int ch) {
    return ch < 127 && ((_unreservedTable[ch >> 4] & (1 << (ch & 0x0f))) != 0);
  }
  static String _escapeChar(char) {
    assert(char <= 0x10ffff);
    const hexDigits = "0123456789ABCDEF";
    List codeUnits;
    if (char < 0x80) {
      codeUnits = new List(3);
      codeUnits[0] = _PERCENT;
      codeUnits[1] = hexDigits.codeUnitAt(((__x14) => DDC$RT.cast(__x14,
          dynamic, int, "CastGeneral",
          """line 1248, column 43 of dart:core/uri.dart: """, __x14 is int,
          true))(char >> 4));
      codeUnits[2] = hexDigits.codeUnitAt(((__x15) => DDC$RT.cast(__x15,
          dynamic, int, "CastGeneral",
          """line 1249, column 43 of dart:core/uri.dart: """, __x15 is int,
          true))(char & 0xf));
    } else {
      int flag = 0xc0;
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
        int byte = ((__x16) => DDC$RT.cast(__x16, dynamic, int, "CastGeneral",
            """line 1265, column 20 of dart:core/uri.dart: """, __x16 is int,
            true))(((char >> (6 * encodedBytes)) & 0x3f) | flag);
        codeUnits[index] = _PERCENT;
        codeUnits[index + 1] = hexDigits.codeUnitAt(byte >> 4);
        codeUnits[index + 2] = hexDigits.codeUnitAt(byte & 0xf);
        index += 3;
        flag = 0x80;
      }
    }
    return new String.fromCharCodes(codeUnits);
  }
  static String _normalize(
      String component, int start, int end, List<int> charTable) {
    StringBuffer buffer;
    int sectionStart = start;
    int index = start;
    while (index < end) {
      int char = component.codeUnitAt(index);
      if (char < 127 && (charTable[char >> 4] & (1 << (char & 0x0f))) != 0) {
        index++;
      } else {
        String replacement;
        int sourceLength;
        if (char == _PERCENT) {
          replacement = _normalizeEscape(component, index, false);
          if (replacement == null) {
            index += 3;
            continue;
          }
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
            if (index + 1 < end) {
              int tail = component.codeUnitAt(index + 1);
              if ((tail & 0xFC00) == 0xDC00) {
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
  bool get isAbsolute => scheme != "" && fragment == "";
  String _merge(String base, String reference) {
    if (base.isEmpty) return "/$reference";
    int backCount = 0;
    int refStart = 0;
    while (reference.startsWith("../", refStart)) {
      refStart += 3;
      backCount++;
    }
    int baseEnd = base.lastIndexOf('/');
    while (baseEnd > 0 && backCount > 0) {
      int newEnd = base.lastIndexOf('/', baseEnd - 1);
      if (newEnd < 0) {
        break;
      }
      int delta = baseEnd - newEnd;
      if ((delta == 2 || delta == 3) &&
          base.codeUnitAt(newEnd + 1) == _DOT &&
          (delta == 2 || base.codeUnitAt(newEnd + 2) == _DOT)) {
        break;
      }
      baseEnd = newEnd;
      backCount--;
    }
    return base.substring(0, baseEnd + 1) +
        reference.substring(refStart - 3 * backCount);
  }
  bool _hasDotSegments(String path) {
    if (path.length > 0 && path.codeUnitAt(0) == _DOT) return true;
    int index = path.indexOf("/.");
    return index != -1;
  }
  String _removeDotSegments(String path) {
    if (!_hasDotSegments(path)) return path;
    List<String> output = ((__x17) => DDC$RT.cast(__x17,
        DDC$RT.type((List<dynamic> _) {}), DDC$RT.type((List<String> _) {}),
        "CastLiteral", """line 1402, column 27 of dart:core/uri.dart: """,
        __x17 is List<String>, false))([]);
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
  Uri resolve(String reference) {
    return resolveUri(Uri.parse(reference));
  }
  Uri resolveUri(Uri reference) {
    String targetScheme;
    String targetUserInfo = "";
    String targetHost;
    int targetPort;
    String targetPath;
    String targetQuery;
    if (reference.scheme.isNotEmpty) {
      targetScheme = reference.scheme;
      if (reference.hasAuthority) {
        targetUserInfo = reference.userInfo;
        targetHost = reference.host;
        targetPort = ((__x18) => DDC$RT.cast(__x18, dynamic, int, "CastGeneral",
            """line 1456, column 22 of dart:core/uri.dart: """, __x18 is int,
            true))(reference.hasPort ? reference.port : null);
      }
      targetPath = _removeDotSegments(reference.path);
      if (reference.hasQuery) {
        targetQuery = reference.query;
      }
    } else {
      targetScheme = this.scheme;
      if (reference.hasAuthority) {
        targetUserInfo = reference.userInfo;
        targetHost = reference.host;
        targetPort = _makePort(((__x19) => DDC$RT.cast(__x19, dynamic, int,
            "CastGeneral", """line 1467, column 32 of dart:core/uri.dart: """,
            __x19 is int,
            true))(reference.hasPort ? reference.port : null), targetScheme);
        targetPath = _removeDotSegments(reference.path);
        if (reference.hasQuery) targetQuery = reference.query;
      } else {
        if (reference.path == "") {
          targetPath = this._path;
          if (reference.hasQuery) {
            targetQuery = reference.query;
          } else {
            targetQuery = this._query;
          }
        } else {
          if (reference.path.startsWith("/")) {
            targetPath = _removeDotSegments(reference.path);
          } else {
            targetPath = _removeDotSegments(_merge(this._path, reference.path));
          }
          if (reference.hasQuery) targetQuery = reference.query;
        }
        targetUserInfo = this._userInfo;
        targetHost = this._host;
        targetPort = ((__x20) => DDC$RT.cast(__x20, num, int, "CastGeneral",
            """line 1489, column 22 of dart:core/uri.dart: """, __x20 is int,
            true))(this._port);
      }
    }
    String fragment = ((__x21) => DDC$RT.cast(__x21, dynamic, String,
        "CastGeneral", """line 1492, column 23 of dart:core/uri.dart: """,
        __x21 is String,
        true))(reference.hasFragment ? reference.fragment : null);
    return new Uri._internal(targetScheme, targetUserInfo, targetHost,
        targetPort, targetPath, targetQuery, fragment);
  }
  bool get hasAuthority => _host != null;
  bool get hasPort => _port != null;
  bool get hasQuery => _query != null;
  bool get hasFragment => _fragment != null;
  String get origin {
    if (scheme == "" || _host == null || _host == "") {
      throw new StateError("Cannot use origin without a scheme: $this");
    }
    if (scheme != "http" && scheme != "https") {
      throw new StateError(
          "Origin is only applicable schemes http and https: $this");
    }
    if (_port == null) return "$scheme://$_host";
    return "$scheme://$_host:$_port";
  }
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
          "Cannot extract a non-Windows file path from a file URI " "with an authority");
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
    if (_userInfo.isNotEmpty) {
      ss.write(_userInfo);
      ss.write("@");
    }
    if (_host != null) ss.write(_host);
    if (_port != null) {
      ss.write(":");
      ss.write(_port);
    }
  }
  String toString() {
    StringBuffer sb = new StringBuffer();
    _addIfNonEmpty(sb, scheme, scheme, ':');
    if (hasAuthority || path.startsWith("//") || (scheme == "file")) {
      sb.write("//");
      _writeAuthority(sb);
    }
    sb.write(path);
    if (_query != null) {
      sb
        ..write("?")
        ..write(_query);
    }
    if (_fragment != null) {
      sb
        ..write("#")
        ..write(_fragment);
    }
    return sb.toString();
  }
  bool operator ==(other) {
    if (other is! Uri) return false;
    Uri uri = DDC$RT.cast(other, dynamic, Uri, "CastGeneral",
        """line 1698, column 15 of dart:core/uri.dart: """, other is Uri, true);
    return scheme == uri.scheme &&
        hasAuthority == uri.hasAuthority &&
        userInfo == uri.userInfo &&
        host == uri.host &&
        port == uri.port &&
        path == uri.path &&
        hasQuery == uri.hasQuery &&
        query == uri.query &&
        hasFragment == uri.hasFragment &&
        fragment == uri.fragment;
  }
  int get hashCode {
    int combine(part, current) {
      return ((__x22) => DDC$RT.cast(__x22, dynamic, int, "CastGeneral",
          """line 1714, column 14 of dart:core/uri.dart: """, __x22 is int,
          true))((current * 31 + part.hashCode) & 0x3FFFFFFF);
    }
    return combine(scheme, combine(userInfo, combine(host,
        combine(port, combine(path, combine(query, combine(fragment, 1)))))));
  }
  static void _addIfNonEmpty(
      StringBuffer sb, String test, String first, String second) {
    if ("" != test) {
      sb.write(first);
      sb.write(second);
    }
  }
  static String encodeComponent(String component) {
    return _uriEncode(DDC$RT.cast(_unreserved2396Table, dynamic,
        DDC$RT.type((List<int> _) {}), "CastGeneral",
        """line 1749, column 23 of dart:core/uri.dart: """,
        _unreserved2396Table is List<int>, false), component);
  }
  static String encodeQueryComponent(String component,
      {Encoding encoding: UTF8}) {
    return _uriEncode(DDC$RT.cast(_unreservedTable, dynamic,
            DDC$RT.type((List<int> _) {}), "CastGeneral",
            """line 1788, column 9 of dart:core/uri.dart: """,
            _unreservedTable is List<int>, false), component,
        encoding: encoding, spaceToPlus: true);
  }
  static String decodeComponent(String encodedComponent) {
    return _uriDecode(encodedComponent);
  }
  static String decodeQueryComponent(String encodedComponent,
      {Encoding encoding: UTF8}) {
    return _uriDecode(encodedComponent, plusToSpace: true, encoding: encoding);
  }
  static String encodeFull(String uri) {
    return _uriEncode(DDC$RT.cast(_encodeFullTable, dynamic,
        DDC$RT.type((List<int> _) {}), "CastGeneral",
        """line 1832, column 23 of dart:core/uri.dart: """,
        _encodeFullTable is List<int>, false), uri);
  }
  static String decodeFull(String uri) {
    return _uriDecode(uri);
  }
  static Map<String, String> splitQueryString(String query,
      {Encoding encoding: UTF8}) {
    return ((__x23) => DDC$RT.cast(__x23, dynamic,
            DDC$RT.type((Map<String, String> _) {}), "CastGeneral",
            """line 1864, column 12 of dart:core/uri.dart: """,
            __x23 is Map<String, String>, false))(query
        .split("&")
        .fold({}, (map, element) {
      int index = ((__x24) => DDC$RT.cast(__x24, dynamic, int, "CastGeneral",
          """line 1865, column 19 of dart:core/uri.dart: """, __x24 is int,
          true))(element.indexOf("="));
      if (index == -1) {
        if (element != "") {
          map[decodeQueryComponent(DDC$RT.cast(element, dynamic, String,
              "CastGeneral", """line 1868, column 36 of dart:core/uri.dart: """,
              element is String, true), encoding: encoding)] = "";
        }
      } else if (index != 0) {
        var key = element.substring(0, index);
        var value = element.substring(index + 1);
        map[Uri.decodeQueryComponent(DDC$RT.cast(key, dynamic, String,
                "CastGeneral",
                """line 1873, column 38 of dart:core/uri.dart: """,
                key is String, true),
            encoding: encoding)] = decodeQueryComponent(DDC$RT.cast(value,
                dynamic, String, "CastGeneral",
                """line 1874, column 34 of dart:core/uri.dart: """,
                value is String, true), encoding: encoding);
      }
      return map;
    }));
  }
  static List<int> parseIPv4Address(String host) {
    void error(String msg) {
      throw new FormatException('Illegal IPv4 address, $msg');
    }
    var bytes = host.split('.');
    if (bytes.length != 4) {
      error('IPv4 address should contain exactly 4 parts');
    }
    return ((__x25) => DDC$RT.cast(__x25, DDC$RT.type((List<dynamic> _) {}),
        DDC$RT.type((List<int> _) {}), "CastDynamic",
        """line 1896, column 12 of dart:core/uri.dart: """, __x25 is List<int>,
        false))(bytes.map((byteString) {
      int byte = int.parse(DDC$RT.cast(byteString, dynamic, String,
          "CastGeneral", """line 1898, column 32 of dart:core/uri.dart: """,
          byteString is String, true));
      if (byte < 0 || byte > 255) {
        error('each part must be in the range of `0..255`');
      }
      return byte;
    }).toList());
  }
  static List<int> parseIPv6Address(String host, [int start = 0, int end]) {
    if (end == null) end = host.length;
    void error(String msg, [position]) {
      throw new FormatException('Illegal IPv6 address, $msg', host, position);
    }
    int parseHex(int start, int end) {
      if (end - start > 4) {
        error('an IPv6 part can only contain a maximum of 4 hex digits', start);
      }
      int value = int.parse(host.substring(start, end), radix: 16);
      if (value < 0 || value > (1 << 16) - 1) {
        error('each part must be in the range of `0x0..0xFFFF`', start);
      }
      return value;
    }
    if (host.length < 2) error('address is too short');
    List<int> parts = ((__x26) => DDC$RT.cast(__x26,
        DDC$RT.type((List<dynamic> _) {}), DDC$RT.type((List<int> _) {}),
        "CastLiteral", """line 1946, column 23 of dart:core/uri.dart: """,
        __x26 is List<int>, false))([]);
    bool wildcardSeen = false;
    int partStart = start;
    for (int i = start; i < end; i++) {
      if (host.codeUnitAt(i) == _COLON) {
        if (i == start) {
          i++;
          if (host.codeUnitAt(i) != _COLON) {
            error('invalid start colon.', i);
          }
          partStart = i;
        }
        if (i == partStart) {
          if (wildcardSeen) {
            error('only one wildcard `::` is allowed', i);
          }
          wildcardSeen = true;
          parts.add(-1);
        } else {
          parts.add(parseHex(partStart, i));
        }
        partStart = i + 1;
      }
    }
    if (parts.length == 0) error('too few parts');
    bool atEnd = (partStart == end);
    bool isLastWildcard = (parts.last == -1);
    if (atEnd && !isLastWildcard) {
      error('expected a part after last `:`', end);
    }
    if (!atEnd) {
      try {
        parts.add(parseHex(partStart, end));
      } catch (e) {
        try {
          List<int> last = parseIPv4Address(host.substring(partStart, end));
          parts.add(last[0] << 8 | last[1]);
          parts.add(last[2] << 8 | last[3]);
        } catch (e) {
          error('invalid end of IPv6 address.', partStart);
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
    return DDC$RT.cast(bytes, DDC$RT.type((List<dynamic> _) {}),
        DDC$RT.type((List<int> _) {}), "CastDynamic",
        """line 2018, column 12 of dart:core/uri.dart: """, bytes is List<int>,
        false);
  }
  static const int _SPACE = 0x20;
  static const int _DOUBLE_QUOTE = 0x22;
  static const int _NUMBER_SIGN = 0x23;
  static const int _PERCENT = 0x25;
  static const int _ASTERISK = 0x2A;
  static const int _PLUS = 0x2B;
  static const int _DOT = 0x2E;
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
  static String _uriEncode(List<int> canonicalTable, String text,
      {Encoding encoding: UTF8, bool spaceToPlus: false}) {
    byteToHex(byte, buffer) {
      const String hex = '0123456789ABCDEF';
      buffer.writeCharCode(hex.codeUnitAt(((__x27) => DDC$RT.cast(__x27,
          dynamic, int, "CastGeneral",
          """line 2059, column 43 of dart:core/uri.dart: """, __x27 is int,
          true))(byte >> 4)));
      buffer.writeCharCode(hex.codeUnitAt(((__x28) => DDC$RT.cast(__x28,
          dynamic, int, "CastGeneral",
          """line 2060, column 43 of dart:core/uri.dart: """, __x28 is int,
          true))(byte & 0x0f)));
    }
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
  static int _hexCharPairToByte(String s, int pos) {
    int byte = 0;
    for (int i = 0; i < 2; i++) {
      var charCode = s.codeUnitAt(pos + i);
      if (0x30 <= charCode && charCode <= 0x39) {
        byte = byte * 16 + charCode - 0x30;
      } else {
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
  static String _uriDecode(String text,
      {bool plusToSpace: false, Encoding encoding: UTF8}) {
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
      bytes = ((__x29) => DDC$RT.cast(__x29, DDC$RT.type((List<dynamic> _) {}),
          DDC$RT.type((List<int> _) {}), "CastExact",
          """line 2134, column 15 of dart:core/uri.dart: """,
          __x29 is List<int>, false))(new List());
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
  static bool _isAlphabeticCharacter(int codeUnit) =>
      (codeUnit >= _LOWER_CASE_A && codeUnit <= _LOWER_CASE_Z) ||
          (codeUnit >= _UPPER_CASE_A && codeUnit <= _UPPER_CASE_Z);
  static const _unreservedTable = const [
    0x0000,
    0x0000,
    0x6000,
    0x03ff,
    0xfffe,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _unreserved2396Table = const [
    0x0000,
    0x0000,
    0x6782,
    0x03ff,
    0xfffe,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _encodeFullTable = const [
    0x0000,
    0x0000,
    0xffda,
    0xafff,
    0xffff,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _schemeTable = const [
    0x0000,
    0x0000,
    0x6800,
    0x03ff,
    0xfffe,
    0x07ff,
    0xfffe,
    0x07ff
  ];
  static const _schemeLowerTable = const [
    0x0000,
    0x0000,
    0x6800,
    0x03ff,
    0x0000,
    0x0000,
    0xfffe,
    0x07ff
  ];
  static const _subDelimitersTable = const [
    0x0000,
    0x0000,
    0x7fd2,
    0x2bff,
    0xfffe,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _genDelimitersTable = const [
    0x0000,
    0x0000,
    0x8008,
    0x8400,
    0x0001,
    0x2800,
    0x0000,
    0x0000
  ];
  static const _userinfoTable = const [
    0x0000,
    0x0000,
    0x7fd2,
    0x2fff,
    0xfffe,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _regNameTable = const [
    0x0000,
    0x0000,
    0x7ff2,
    0x2bff,
    0xfffe,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _pathCharTable = const [
    0x0000,
    0x0000,
    0x7fd2,
    0x2fff,
    0xffff,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _pathCharOrSlashTable = const [
    0x0000,
    0x0000,
    0xffd2,
    0x2fff,
    0xffff,
    0x87ff,
    0xfffe,
    0x47ff
  ];
  static const _queryCharTable = const [
    0x0000,
    0x0000,
    0xffd2,
    0xafff,
    0xffff,
    0x87ff,
    0xfffe,
    0x47ff
  ];
}
