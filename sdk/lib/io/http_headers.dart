// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _HttpHeaders implements HttpHeaders {
  _HttpHeaders(String this.protocolVersion)
      : _headers = new Map<String, List<String>>();

  List<String> operator[](String name) {
    name = name.toLowerCase();
    return _headers[name];
  }

  String value(String name) {
    name = name.toLowerCase();
    List<String> values = _headers[name];
    if (values == null) return null;
    if (values.length > 1) {
      throw new HttpException("More than one value for header $name");
    }
    return values[0];
  }

  void add(String name, value) {
    _checkMutable();
    if (value is List) {
      for (int i = 0; i < value.length; i++) {
        _add(name, value[i]);
      }
    } else {
      _add(name, value);
    }
  }

  void set(String name, Object value) {
    name = name.toLowerCase();
    _checkMutable();
    removeAll(name);
    add(name, value);
  }

  void remove(String name, Object value) {
    _checkMutable();
    name = name.toLowerCase();
    List<String> values = _headers[name];
    if (values != null) {
      int index = values.indexOf(value);
      if (index != -1) {
        values.removeRange(index, index + 1);
      }
      if (values.length == 0) _headers.remove(name);
    }
  }

  void removeAll(String name) {
    _checkMutable();
    name = name.toLowerCase();
    _headers.remove(name);
  }

  void forEach(void f(String name, List<String> values)) {
    _headers.forEach(f);
  }

  void noFolding(String name) {
    if (_noFoldingHeaders == null) _noFoldingHeaders = new List<String>();
    _noFoldingHeaders.add(name);
  }

  bool get persistentConnection {
    List<String> connection = _headers[HttpHeaders.CONNECTION];
    if (protocolVersion == "1.1") {
      if (connection == null) return true;
      return !connection.any((value) => value.toLowerCase() == "close");
    } else {
      if (connection == null) return false;
      return connection.any((value) => value.toLowerCase() == "keep-alive");
    }
  }

  void set persistentConnection(bool persistentConnection) {
    _checkMutable();
    // Determine the value of the "Connection" header.
    remove(HttpHeaders.CONNECTION, "close");
    remove(HttpHeaders.CONNECTION, "keep-alive");
    if (protocolVersion == "1.1" && !persistentConnection) {
      add(HttpHeaders.CONNECTION, "close");
    } else if (protocolVersion == "1.0" && persistentConnection) {
      add(HttpHeaders.CONNECTION, "keep-alive");
    }
  }

  int get contentLength => _contentLength;

  void set contentLength(int contentLength) {
    _checkMutable();
    _contentLength = contentLength;
    if (_contentLength >= 0) {
      _set(HttpHeaders.CONTENT_LENGTH, contentLength.toString());
    } else {
      removeAll(HttpHeaders.CONTENT_LENGTH);
    }
  }

  bool get chunkedTransferEncoding => _chunkedTransferEncoding;

  void set chunkedTransferEncoding(bool chunkedTransferEncoding) {
    _checkMutable();
    _chunkedTransferEncoding = chunkedTransferEncoding;
    List<String> values = _headers[HttpHeaders.TRANSFER_ENCODING];
    if ((values == null || values[values.length - 1] != "chunked") &&
        chunkedTransferEncoding) {
      // Headers does not specify chunked encoding - add it if set.
        _addValue(HttpHeaders.TRANSFER_ENCODING, "chunked");
    } else if (!chunkedTransferEncoding) {
      // Headers does specify chunked encoding - remove it if not set.
      remove(HttpHeaders.TRANSFER_ENCODING, "chunked");
    }
  }

  String get host => _host;

  void set host(String host) {
    _checkMutable();
    _host = host;
    _updateHostHeader();
  }

  int get port => _port;

  void set port(int port) {
    _checkMutable();
    _port = port;
    _updateHostHeader();
  }

  DateTime get ifModifiedSince {
    List<String> values = _headers[HttpHeaders.IF_MODIFIED_SINCE];
    if (values != null) {
      try {
        return HttpDate.parse(values[0]);
      } on Exception catch (e) {
        return null;
      }
    }
    return null;
  }

  void set ifModifiedSince(DateTime ifModifiedSince) {
    _checkMutable();
    // Format "ifModifiedSince" header with date in Greenwich Mean Time (GMT).
    String formatted = HttpDate.format(ifModifiedSince.toUtc());
    _set(HttpHeaders.IF_MODIFIED_SINCE, formatted);
  }

  DateTime get date {
    List<String> values = _headers[HttpHeaders.DATE];
    if (values != null) {
      try {
        return HttpDate.parse(values[0]);
      } on Exception catch (e) {
        return null;
      }
    }
    return null;
  }

  void set date(DateTime date) {
    _checkMutable();
    // Format "DateTime" header with date in Greenwich Mean Time (GMT).
    String formatted = HttpDate.format(date.toUtc());
    _set("date", formatted);
  }

  DateTime get expires {
    List<String> values = _headers[HttpHeaders.EXPIRES];
    if (values != null) {
      try {
        return HttpDate.parse(values[0]);
      } on Exception catch (e) {
        return null;
      }
    }
    return null;
  }

  void set expires(DateTime expires) {
    _checkMutable();
    // Format "Expires" header with date in Greenwich Mean Time (GMT).
    String formatted = HttpDate.format(expires.toUtc());
    _set(HttpHeaders.EXPIRES, formatted);
  }

  ContentType get contentType {
    var values = _headers["content-type"];
    if (values != null) {
      return ContentType.parse(values[0]);
    } else {
      return null;
    }
  }

  void set contentType(ContentType contentType) {
    _checkMutable();
    _set(HttpHeaders.CONTENT_TYPE, contentType.toString());
  }

  void _add(String name, value) {
    var lowerCaseName = name.toLowerCase();
    // TODO(sgjesse): Add immutable state throw HttpException is immutable.
    if (lowerCaseName == HttpHeaders.CONTENT_LENGTH) {
      if (value is int) {
        contentLength = value;
      } else if (value is String) {
        contentLength = int.parse(value);
      } else {
        throw new HttpException("Unexpected type for header named $name");
      }
    } else if (lowerCaseName == HttpHeaders.TRANSFER_ENCODING) {
      if (value == "chunked") {
        chunkedTransferEncoding = true;
      } else {
        _addValue(lowerCaseName, value);
      }
    } else if (lowerCaseName == HttpHeaders.DATE) {
      if (value is DateTime) {
        date = value;
      } else if (value is String) {
        _set(HttpHeaders.DATE, value);
      } else {
        throw new HttpException("Unexpected type for header named $name");
      }
    } else if (lowerCaseName == HttpHeaders.EXPIRES) {
      if (value is DateTime) {
        expires = value;
      } else if (value is String) {
        _set(HttpHeaders.EXPIRES, value);
      } else {
        throw new HttpException("Unexpected type for header named $name");
      }
    } else if (lowerCaseName == HttpHeaders.IF_MODIFIED_SINCE) {
      if (value is DateTime) {
        ifModifiedSince = value;
      } else if (value is String) {
        _set(HttpHeaders.IF_MODIFIED_SINCE, value);
      } else {
        throw new HttpException("Unexpected type for header named $name");
      }
    } else if (lowerCaseName == HttpHeaders.HOST) {
      if (value is String) {
        int pos = value.indexOf(":");
        if (pos == -1) {
          _host = value;
          _port = HttpClient.DEFAULT_HTTP_PORT;
        } else {
          if (pos > 0) {
            _host = value.substring(0, pos);
          } else {
            _host = null;
          }
          if (pos + 1 == value.length) {
            _port = HttpClient.DEFAULT_HTTP_PORT;
          } else {
            try {
              _port = int.parse(value.substring(pos + 1));
            } on FormatException catch (e) {
              _port = null;
            }
          }
        }
        _set(HttpHeaders.HOST, value);
      } else {
        throw new HttpException("Unexpected type for header named $name");
      }
    } else if (lowerCaseName == HttpHeaders.CONTENT_TYPE) {
      _set(HttpHeaders.CONTENT_TYPE, value);
    } else {
      _addValue(lowerCaseName, value);
    }
  }

  void _addValue(String name, Object value) {
    List<String> values = _headers[name];
    if (values == null) {
      values = new List<String>();
      _headers[name] = values;
    }
    if (value is DateTime) {
      values.add(HttpDate.format(value));
    } else {
      values.add(value.toString());
    }
  }

  void _set(String name, String value) {
    name = name.toLowerCase();
    List<String> values = new List<String>();
    _headers[name] = values;
    values.add(value);
  }

  _checkMutable() {
    if (!_mutable) throw new HttpException("HTTP headers are not mutable");
  }

  _updateHostHeader() {
    bool defaultPort = _port == null || _port == HttpClient.DEFAULT_HTTP_PORT;
    String portPart = defaultPort ? "" : ":$_port";
    _set("host", "$host$portPart");
  }

  _foldHeader(String name) {
    if (name == HttpHeaders.SET_COOKIE ||
        (_noFoldingHeaders != null &&
         _noFoldingHeaders.indexOf(name) != -1)) {
      return false;
    }
    return true;
  }

  void _synchronize() {
    // If the content length is not known make sure chunked transfer
    // encoding is used for HTTP 1.1.
    if (contentLength < 0) {
      if (protocolVersion == "1.0") {
        persistentConnection = false;
      } else {
        chunkedTransferEncoding = true;
      }
    }
    // If a Transfer-Encoding header field is present the
    // Content-Length header MUST NOT be sent (RFC 2616 section 4.4).
    if (chunkedTransferEncoding &&
        contentLength >= 0 &&
        protocolVersion == "1.1") {
      contentLength = -1;
    }
  }

  void _finalize() {
    _synchronize();
    _mutable = false;
  }

  _write(BytesBuilder builder) {
    final COLONSP = const [_CharCode.COLON, _CharCode.SP];
    final COMMASP = const [_CharCode.COMMA, _CharCode.SP];
    final CRLF = const [_CharCode.CR, _CharCode.LF];

    // Format headers.
    _headers.forEach((String name, List<String> values) {
      bool fold = _foldHeader(name);
      var nameData = name.codeUnits;
      builder.add(nameData);
      builder.add(const [_CharCode.COLON, _CharCode.SP]);
      for (int i = 0; i < values.length; i++) {
        if (i > 0) {
          if (fold) {
            builder.add(const [_CharCode.COMMA, _CharCode.SP]);
          } else {
            builder.add(const [_CharCode.CR, _CharCode.LF]);
            builder.add(nameData);
            builder.add(const [_CharCode.COLON, _CharCode.SP]);
          }
        }
        builder.add(values[i].codeUnits);
      }
      builder.add(const [_CharCode.CR, _CharCode.LF]);
    });
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    _headers.forEach((String name, List<String> values) {
      sb.write(name);
      sb.write(": ");
      bool fold = _foldHeader(name);
      for (int i = 0; i < values.length; i++) {
        if (i > 0) {
          if (fold) {
            sb.write(", ");
          } else {
            sb.write("\n");
            sb.write(name);
            sb.write(": ");
          }
        }
        sb.write(values[i]);
      }
      sb.write("\n");
    });
    return sb.toString();
  }

  List<Cookie> _parseCookies() {
    // Parse a Cookie header value according to the rules in RFC 6265.
    var cookies = new List<Cookie>();
    void parseCookieString(String s) {
      int index = 0;

      bool done() => index == s.length;

      void skipWS() {
        while (!done()) {
         if (s[index] != " " && s[index] != "\t") return;
         index++;
        }
      }

      String parseName() {
        int start = index;
        while (!done()) {
          if (s[index] == " " || s[index] == "\t" || s[index] == "=") break;
          index++;
        }
        return s.substring(start, index);
      }

      String parseValue() {
        int start = index;
        while (!done()) {
          if (s[index] == " " || s[index] == "\t" || s[index] == ";") break;
          index++;
        }
        return s.substring(start, index);
      }

      void expect(String expected) {
        if (done()) {
          throw new HttpException("Failed to parse header value [$s]");
        }
        if (s[index] != expected) {
          throw new HttpException("Failed to parse header value [$s]");
        }
        index++;
      }

      while (!done()) {
        skipWS();
        if (done()) return;
        String name = parseName();
        skipWS();
        expect("=");
        skipWS();
        String value = parseValue();
        cookies.add(new _Cookie(name, value));
        skipWS();
        if (done()) return;
        expect(";");
      }
    }
    List<String> values = _headers[HttpHeaders.COOKIE];
    if (values != null) {
      values.forEach((headerValue) => parseCookieString(headerValue));
    }
    return cookies;
  }


  bool _mutable = true;  // Are the headers currently mutable?
  Map<String, List<String>> _headers;
  List<String> _noFoldingHeaders;

  int _contentLength = -1;
  bool _chunkedTransferEncoding = false;
  final String protocolVersion;
  String _host;
  int _port;
}


class _HeaderValue implements HeaderValue {
  String _value;
  _UnmodifiableMap<String, String> _parameters;

  _HeaderValue([String this._value = "", Map<String, String> parameters]) {
    if (parameters != null) {
      _parameters =
          new _UnmodifiableMap(new Map<String, String>.from(parameters));
    }
  }

  static _HeaderValue parse(String value,
                            {parameterSeparator: ";",
                             preserveBackslash: false}) {
    // Parse the string.
    var result = new _HeaderValue();
    result._parse(value, parameterSeparator, preserveBackslash);
    return result;
  }

  String get value => _value;

  void _ensureParameters() {
    if (_parameters == null) {
      _parameters = new _UnmodifiableMap(new Map<String, String>());
    }
  }

  Map<String, String> get parameters {
    _ensureParameters();
    return _parameters;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(_value);
    if (parameters != null && parameters.length > 0) {
      _parameters.forEach((String name, String value) {
        sb.write("; ");
        sb.write(name);
        sb.write("=");
        sb.write(value);
      });
    }
    return sb.toString();
  }

  void _parse(String s, String parameterSeparator, bool preserveBackslash) {
    int index = 0;

    bool done() => index == s.length;

    void skipWS() {
      while (!done()) {
        if (s[index] != " " && s[index] != "\t") return;
        index++;
      }
    }

    String parseValue() {
      int start = index;
      while (!done()) {
        if (s[index] == " " ||
            s[index] == "\t" ||
            s[index] == parameterSeparator) break;
        index++;
      }
      return s.substring(start, index);
    }

    void expect(String expected) {
      if (done() || s[index] != expected) {
        throw new HttpException("Failed to parse header value");
      }
      index++;
    }

    void maybeExpect(String expected) {
      if (s[index] == expected) index++;
    }

    void parseParameters() {
      var parameters = new Map<String, String>();
      _parameters = new _UnmodifiableMap(parameters);

      String parseParameterName() {
        int start = index;
        while (!done()) {
          if (s[index] == " " || s[index] == "\t" || s[index] == "=") break;
          index++;
        }
        return s.substring(start, index).toLowerCase();
      }

      String parseParameterValue() {
        if (s[index] == "\"") {
          // Parse quoted value.
          StringBuffer sb = new StringBuffer();
          index++;
          while (!done()) {
            if (s[index] == "\\") {
              if (index + 1 == s.length) {
                throw new HttpException("Failed to parse header value");
              }
              if (preserveBackslash && s[index + 1] != "\"") {
                sb.write(s[index]);
              }
              index++;
            } else if (s[index] == "\"") {
              index++;
              break;
            }
            sb.write(s[index]);
            index++;
          }
          return sb.toString();
        } else {
          // Parse non-quoted value.
          return parseValue();
        }
      }

      while (!done()) {
        skipWS();
        if (done()) return;
        String name = parseParameterName();
        skipWS();
        expect("=");
        skipWS();
        String value = parseParameterValue();
        parameters[name] = value;
        skipWS();
        if (done()) return;
        expect(parameterSeparator);
      }
    }

    skipWS();
    _value = parseValue();
    skipWS();
    if (done()) return;
    maybeExpect(parameterSeparator);
    parseParameters();
  }
}


class _ContentType extends _HeaderValue implements ContentType {
  String _primaryType = "";
  String _subType = "";

  _ContentType(String primaryType,
               String subType,
               String charset,
               Map<String, String> parameters)
      : _primaryType = primaryType, _subType = subType, super("") {
    if (_primaryType == null) _primaryType = "";
    if (_subType == null) _subType = "";
    _value = "$_primaryType/$_subType";
    if (parameters != null) {
      _ensureParameters();
      parameters.forEach((String key, String value) {
        this._parameters._map[key.toLowerCase()] = value.toLowerCase();
      });
    }
    if (charset != null) {
      _ensureParameters();
      this._parameters._map["charset"] = charset.toLowerCase();
    }
  }

  _ContentType._();

  static _ContentType parse(String value) {
    var result = new _ContentType._();
    result._parse(value, ";", false);
    int index = result._value.indexOf("/");
    if (index == -1 || index == (result._value.length - 1)) {
      result._primaryType = result._value.trim().toLowerCase();
      result._subType = "";
    } else {
      result._primaryType =
          result._value.substring(0, index).trim().toLowerCase();
      result._subType = result._value.substring(index + 1).trim().toLowerCase();
    }
    return result;
  }

  String get mimeType => '$primaryType/$subType';

  String get primaryType => _primaryType;

  String get subType => _subType;

  String get charset => parameters["charset"];
}


class _Cookie implements Cookie {
  _Cookie([String this.name, String this.value]);

  _Cookie.fromSetCookieValue(String value) {
    // Parse the 'set-cookie' header value.
    _parseSetCookieValue(value);
  }

  // Parse a 'set-cookie' header value according to the rules in RFC 6265.
  void _parseSetCookieValue(String s) {
    int index = 0;

    bool done() => index == s.length;

    String parseName() {
      int start = index;
      while (!done()) {
        if (s[index] == "=") break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    String parseValue() {
      int start = index;
      while (!done()) {
        if (s[index] == ";") break;
        index++;
      }
      return s.substring(start, index).trim();
    }

    void expect(String expected) {
      if (done()) throw new HttpException("Failed to parse header value [$s]");
      if (s[index] != expected) {
        throw new HttpException("Failed to parse header value [$s]");
      }
      index++;
    }

    void parseAttributes() {
      String parseAttributeName() {
        int start = index;
        while (!done()) {
          if (s[index] == "=" || s[index] == ";") break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      String parseAttributeValue() {
        int start = index;
        while (!done()) {
          if (s[index] == ";") break;
          index++;
        }
        return s.substring(start, index).trim().toLowerCase();
      }

      while (!done()) {
        String name = parseAttributeName();
        String value = "";
        if (!done() && s[index] == "=") {
          index++;  // Skip the = character.
          value = parseAttributeValue();
        }
        if (name == "expires") {
          expires = HttpDate._parseCookieDate(value);
        } else if (name == "max-age") {
          maxAge = int.parse(value);
        } else if (name == "domain") {
          domain = value;
        } else if (name == "path") {
          path = value;
        } else if (name == "httponly") {
          httpOnly = true;
        } else if (name == "secure") {
          secure = true;
        }
        if (!done()) index++;  // Skip the ; character
      }
    }

    name = parseName();
    if (done() || name.length == 0) {
      throw new HttpException("Failed to parse header value [$s]");
    }
    index++;  // Skip the = character.
    value = parseValue();
    if (done()) return;
    index++;  // Skip the ; character.
    parseAttributes();
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(name);
    sb.write("=");
    sb.write(value);
    if (expires != null) {
      sb.write("; Expires=");
      sb.write(HttpDate.format(expires));
    }
    if (maxAge != null) {
      sb.write("; Max-Age=");
      sb.write(maxAge);
    }
    if (domain != null) {
      sb.write("; Domain=");
      sb.write(domain);
    }
    if (path != null) {
      sb.write("; Path=");
      sb.write(path);
    }
    if (secure) sb.write("; Secure");
    if (httpOnly) sb.write("; HttpOnly");
    return sb.toString();
  }

  String name;
  String value;
  DateTime expires;
  int maxAge;
  String domain;
  String path;
  bool httpOnly = false;
  bool secure = false;
}


class _UnmodifiableMap<K, V> implements Map<K, V> {
  final Map _map;
  const _UnmodifiableMap(this._map);

  bool containsValue(Object value) => _map.containsValue(value);
  bool containsKey(Object key) => _map.containsKey(key);
  V operator [](Object key) => _map[key];
  void operator []=(K key, V value) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  V putIfAbsent(K key, V ifAbsent()) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  addAll(Map other) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  V remove(Object key) {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  void clear() {
    throw new UnsupportedError("Cannot modify an unmodifiable map");
  }
  void forEach(void f(K key, V value)) => _map.forEach(f);
  Iterable<K> get keys => _map.keys;
  Iterable<V> get values => _map.values;
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}
