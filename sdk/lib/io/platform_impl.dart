// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

class _Platform {
  external static int _numberOfProcessors();
  external static String _pathSeparator();
  external static String _operatingSystem();
  external static _localHostname();
  external static _executable();
  external static _environment();
  external static List<String> _executableArguments();
  external static String _packageRoot();
  external static String _version();

  static String executable = _executable();
  static String packageRoot = _packageRoot();

  // Cache the OS environemnt. This can be an OSError instance if
  // retrieving the environment failed.
  static var _environmentCache;

  static int get numberOfProcessors => _numberOfProcessors();
  static String get pathSeparator => _pathSeparator();
  static String get operatingSystem => _operatingSystem();
  static Uri script = _script();
  static Uri _script() {
    // The embedder (Dart executable) creates the Platform._nativeScript field.
    var s = Platform._nativeScript;
    if (s.startsWith('http:') ||
        s.startsWith('https:') ||
        s.startsWith('file:')) {
      return Uri.parse(s);
    } else {
      return Uri.base.resolveUri(new Uri.file(s));
    }
  }

  static String get localHostname {
    var result = _localHostname();
    if (result is OSError) {
      throw result;
    } else {
      return result;
    }
  }

  static List<String> get executableArguments => _executableArguments();

  static Map<String, String> get environment {
    if (_environmentCache == null) {
      var env = _environment();
      if (env is !OSError) {
        var isWindows = operatingSystem == 'windows';
        var result = isWindows ? new _CaseInsensitiveStringMap() : new Map();
        for (var str in env) {
          // When running on Windows through cmd.exe there are strange
          // environment variables that are used to record the current
          // working directory for each drive and the exit code for the
          // last command. As an example: '=A:=A:\subdir' records the
          // current working directory on the 'A' drive.  In order to
          // handle these correctly we search for a second occurrence of
          // of '=' in the string if the first occurrence is at index 0.
          var equalsIndex = str.indexOf('=');
          if (equalsIndex == 0) {
            equalsIndex = str.indexOf('=', 1);
          }
          assert(equalsIndex != -1);
          result[str.substring(0, equalsIndex)] =
              str.substring(equalsIndex + 1);
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

  bool containsKey(String key) => _map.containsKey(key.toUpperCase());
  bool containsValue(Object value) => _map.containsValue(value);
  V operator [](String key) => _map[key.toUpperCase()];
  void operator []=(String key, V value) {
    _map[key.toUpperCase()] = value;
  }
  V putIfAbsent(String key, V ifAbsent()) {
    _map.putIfAbsent(key.toUpperCase(), ifAbsent);
  }
  addAll(Map other) {
    other.forEach((key, value) => this[key.toUpperCase()] = value);
  }
  V remove(String key) => _map.remove(key.toUpperCase());
  void clear() => _map.clear();
  void forEach(void f(String key, V value)) => _map.forEach(f);
  Iterable<String> get keys => _map.keys;
  Iterable<V> get values => _map.values;
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
  String toString() => _map.toString();
}
