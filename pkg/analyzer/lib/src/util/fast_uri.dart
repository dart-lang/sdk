// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/**
 * Implementation of [Uri] that understands only a limited set of valid
 * URI formats, but works fast. In practice Dart code almost always uses such
 * limited URI format, so almost always can be processed fast.
 */
class FastUri implements Uri {
  /***
   * The maximum [_cache] length before we flush it and start a new generation.
   */
  static const int _MAX_CACHE_LENGTH_BEFORE_FLUSH = 50000;

  static HashMap<String, Uri> _cache = new HashMap<String, Uri>();
  static int _currentCacheLength = 0;
  static int _currentCacheGeneration = 0;

  static bool _hashUsingText = _shouldComputeHashCodeUsingText();

  final int _cacheGeneration;
  final String _text;
  final String _scheme;
  final bool _hasEmptyAuthority;
  final String _path;

  /**
   * The offset of the last `/` in [_text], or `null` if there isn't any.
   */
  final int _lastSlashIndex;

  /**
   * The cached hash code.
   */
  int _hashCode;

  Uri _cachedFallbackUri;

  FastUri._(this._cacheGeneration, this._text, this._scheme,
      this._hasEmptyAuthority, this._path, this._lastSlashIndex);

  @override
  String get authority => '';

  @override
  UriData get data => null;

  @override
  String get fragment => '';

  @override
  bool get hasAbsolutePath => path.startsWith('/');

  @override
  bool get hasAuthority => _hasEmptyAuthority;

  @override
  bool get hasEmptyPath => _path.isEmpty;

  @override
  bool get hasFragment => false;

  @override
  int get hashCode {
    return _hashCode ??= _hashUsingText
        ? _computeHashUsingText(this)
        : _computeHashUsingCombine(this);
  }

  @override
  bool get hasPort => false;

  @override
  bool get hasQuery => false;

  @override
  bool get hasScheme => _scheme.isNotEmpty;

  @override
  String get host => '';

  @override
  bool get isAbsolute => hasScheme;

  @override
  String get origin => _fallbackUri.origin;

  @override
  String get path => _path;

  @override
  List<String> get pathSegments => _fallbackUri.pathSegments;

  @override
  int get port => 0;

  @override
  String get query => '';

  @override
  Map<String, String> get queryParameters => const <String, String>{};

  @override
  Map<String, List<String>> get queryParametersAll =>
      const <String, List<String>>{};

  @override
  String get scheme => _scheme;

  @override
  String get userInfo => '';

  /**
   * Full [Uri] object computed on demand; we fall back to this for some of the
   * more complex methods of [Uri] that are less in need of a fast
   * implementation.
   */
  Uri get _fallbackUri => _cachedFallbackUri ??= Uri.parse(_text);

  @override
  bool operator ==(other) {
    if (other is FastUri) {
      if (other._cacheGeneration == _cacheGeneration) {
        return identical(other, this);
      }
      return _text == other._text;
    } else if (other is Uri) {
      return _fallbackUri == other;
    }
    return false;
  }

  @override
  Uri normalizePath() {
    return this;
  }

  @override
  Uri removeFragment() {
    return this;
  }

  @override
  Uri replace(
      {String scheme,
      String userInfo,
      String host,
      int port,
      String path,
      Iterable<String> pathSegments,
      String query,
      Map<String, dynamic> queryParameters,
      String fragment}) {
    return _fallbackUri.replace(
        scheme: scheme,
        userInfo: userInfo,
        host: host,
        port: port,
        path: path,
        pathSegments: pathSegments,
        query: query,
        queryParameters: queryParameters,
        fragment: fragment);
  }

  @override
  Uri resolve(String reference) {
    // TODO: maybe implement faster
    return _fallbackUri.resolve(reference);
  }

  @override
  Uri resolveUri(Uri reference) {
    if (reference.hasScheme) {
      return reference;
    }
    String refPath = reference.path;
    if (refPath.startsWith('./')) {
      refPath = refPath.substring(2);
    }
    if (refPath.startsWith('../') ||
        refPath.contains('/../') ||
        refPath.contains('/./')) {
      Uri slowResult = _fallbackUri.resolveUri(reference);
      return FastUri.parse(slowResult.toString());
    }
    String newText;
    if (_lastSlashIndex != null) {
      newText = _text.substring(0, _lastSlashIndex + 1) + refPath;
    } else {
      newText = _text + '/' + refPath;
    }
    return FastUri.parse(newText);
  }

  @override
  String toFilePath({bool windows}) {
    return _fallbackUri.toFilePath(windows: windows);
  }

  @override
  String toString() => _text;

  /**
   * Parse the given URI [text] and return the corresponding [Uri] instance.  If
   * the [text] can be represented as a [FastUri], then it is returned.  If the
   * [text] is more complex, then `dart:core` [Uri] is created and returned.
   * This method also performs memoization, so that usually the same instance
   * of [FastUri] or [Uri] is returned for the same [text].
   */
  static Uri parse(String text) {
    Uri uri = _cache[text];
    if (uri == null) {
      uri = _parse(text);
      uri ??= Uri.parse(text);
      _cache[text] = uri;
      _currentCacheLength++;
      // If the cache is too big, start a new generation.
      if (_currentCacheLength > _MAX_CACHE_LENGTH_BEFORE_FLUSH) {
        _cache.clear();
        _currentCacheLength = 0;
        _currentCacheGeneration++;
      }
    }
    return uri;
  }

  /**
   * This implementation was used before 'fast-URI' in Dart VM.
   */
  static int _computeHashUsingCombine(FastUri uri) {
    // This code is copied from the standard Uri implementation.
    // It is important that Uri and FastUri generate compatible hashCodes
    // because Uri and FastUri may be used as keys in the same map.
    int combine(part, current) {
      // The sum is truncated to 30 bits to make sure it fits into a Smi.
      return (current * 31 + part.hashCode) & 0x3FFFFFFF;
    }

    return combine(
        uri.scheme,
        combine(
            uri.userInfo,
            combine(
                uri.host,
                combine(
                    uri.port,
                    combine(uri.path,
                        combine(uri.query, combine(uri.fragment, 1)))))));
  }

  /**
   * This implementation should be used with 'fast-URI' in Dart VM.
   * https://github.com/dart-lang/sdk/commit/afbbbb97cfcd86a64d0ba5dcfe1ab758954adaf4
   */
  static int _computeHashUsingText(FastUri uri) {
    return uri._text.hashCode;
  }

  static bool _isAlphabetic(int char) {
    return char >= 'A'.codeUnitAt(0) && char <= 'Z'.codeUnitAt(0) ||
        char >= 'a'.codeUnitAt(0) && char <= 'z'.codeUnitAt(0);
  }

  static bool _isDigit(int char) {
    return char >= '0'.codeUnitAt(0) && char <= '9'.codeUnitAt(0);
  }

  /**
   * Parse the given [text] into a new [FastUri].  If the [text] uses URI
   * features that are not supported by [FastUri], return `null`.
   */
  static FastUri _parse(String text) {
    int schemeEnd = null;
    int pathStart = 0;
    int lastSlashIndex = null;
    for (int i = 0; i < text.length; i++) {
      int char = text.codeUnitAt(i);
      if (_isAlphabetic(char) ||
          _isDigit(char) ||
          char == '.'.codeUnitAt(0) ||
          char == '-'.codeUnitAt(0) ||
          char == '_'.codeUnitAt(0)) {
        // Valid characters.
      } else if (char == '/'.codeUnitAt(0)) {
        lastSlashIndex = i;
      } else if (char == ':'.codeUnitAt(0)) {
        if (schemeEnd != null) {
          return null;
        }
        schemeEnd = i;
        pathStart = i + 1;
      } else {
        return null;
      }
    }
    String scheme = schemeEnd != null ? text.substring(0, schemeEnd) : '';
    bool hasEmptyAuthority = false;
    String path = text.substring(pathStart);
    if (path.startsWith('//')) {
      hasEmptyAuthority = true;
      path = path.substring(2);
      if (!path.startsWith('/')) {
        return null;
      }
    }
    return new FastUri._(_currentCacheGeneration, text, scheme,
        hasEmptyAuthority, path, lastSlashIndex);
  }

  /**
   * Determine whether VM has the text based hash code computation in [Uri],
   * or the old combine style.
   *
   * See https://github.com/dart-lang/sdk/issues/27159 for details.
   */
  static bool _shouldComputeHashCodeUsingText() {
    String text = 'package:foo/foo.dart';
    return Uri.parse(text).hashCode == text.hashCode;
  }
}
