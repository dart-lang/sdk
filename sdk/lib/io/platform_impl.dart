// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _Platform {
  external static int _numberOfProcessors();
  external static String _pathSeparator();
  external static String _operatingSystem();
  external static _operatingSystemVersion();
  external static _localHostname();
  external static _executable();
  external static _resolvedExecutable();

  /**
   * Retrieve the entries of the process environment.
   *
   * The result is an [Iterable] of strings, where each string represents
   * an environment entry.
   *
   * Environment entries should be strings containing
   * a non-empty name and a value separated by a '=' character.
   * The name does not contain a '=' character,
   * so the name is everything up to the first '=' character.
   * Values are everything after the first '=' character.
   * A value may contain further '=' characters, and it may be empty.
   *
   * Returns an [OSError] if retrieving the environment fails.
   */
  external static _environment();
  external static List<String> _executableArguments();
  external static String _packageRoot();
  external static String _packageConfig();
  external static String _version();
  external static String _localeName();
  external static Uri _script();

  static String executable = _executable();
  static String resolvedExecutable = _resolvedExecutable();
  static String packageRoot = _packageRoot();
  static String packageConfig = _packageConfig();

  static String _cachedLocaleName;
  static String get localeName {
    if (_cachedLocaleName == null) {
      var result = _localeName();
      if (result is OSError) {
        throw result;
      }
      _cachedLocaleName = result;
    }
    return _cachedLocaleName;
  }

  // Cache the OS environment. This can be an OSError instance if
  // retrieving the environment failed.
  static var /*OSError|Map<String,String>*/ _environmentCache;

  static int get numberOfProcessors => _numberOfProcessors();
  static String get pathSeparator => _pathSeparator();
  static String get operatingSystem => _operatingSystem();
  static Uri get script => _script();

  static String _cachedOSVersion;
  static String get operatingSystemVersion {
    if (_cachedOSVersion == null) {
      var result = _operatingSystemVersion();
      if (result is OSError) {
        throw result;
      }
      _cachedOSVersion = result;
    }
    return _cachedOSVersion;
  }

  static String get localHostname {
    var result = _localHostname();
    if (result is OSError) {
      throw result;
    }
    return result;
  }

  static List<String> get executableArguments => _executableArguments();

  static Map<String, String> get environment {
    if (_environmentCache == null) {
      var env = _environment();
      if (env is! OSError) {
        var isWindows = operatingSystem == 'windows';
        var result = isWindows
            ? new _CaseInsensitiveStringMap<String>()
            : new Map<String, String>();
        for (var str in env) {
          if (str == null) {
            continue;
          }
          // The Strings returned by [_environment()] are expected to be
          // valid environment entries, but exceptions have been seen
          // (e.g., an entry of just '=' has been seen on OS/X).
          // Invalid entries (lines without a '=' or with an empty name)
          // are discarded.
          var equalsIndex = str.indexOf('=');
          if (equalsIndex > 0) {
            result[str.substring(0, equalsIndex)] =
                str.substring(equalsIndex + 1);
          }
        }
        _environmentCache = new UnmodifiableMapView<String, String>(result);
      } else {
        _environmentCache = env;
      }
    }

    if (_environmentCache is OSError) {
      throw _environmentCache;
    } else {
      return _environmentCache;
    }
  }

  static String get version => _version();
}

// Environment variables are case-insensitive on Windows. In order
// to reflect that we use a case-insensitive string map on Windows.
class _CaseInsensitiveStringMap<V> implements Map<String, V> {
  final Map<String, V> _map = new Map<String, V>();

  bool containsKey(Object key) =>
      key is String && _map.containsKey(key.toUpperCase());
  bool containsValue(Object value) => _map.containsValue(value);
  V operator [](Object key) => key is String ? _map[key.toUpperCase()] : null;
  void operator []=(String key, V value) {
    _map[key.toUpperCase()] = value;
  }

  V putIfAbsent(String key, V ifAbsent()) {
    return _map.putIfAbsent(key.toUpperCase(), ifAbsent);
  }

  void addAll(Map<String, V> other) {
    other.forEach((key, value) => this[key.toUpperCase()] = value);
  }

  V remove(Object key) => key is String ? _map.remove(key.toUpperCase()) : null;
  void clear() {
    _map.clear();
  }

  void forEach(void f(String key, V value)) {
    _map.forEach(f);
  }

  Iterable<String> get keys => _map.keys;
  Iterable<V> get values => _map.values;
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  String toString() => _map.toString();
}
