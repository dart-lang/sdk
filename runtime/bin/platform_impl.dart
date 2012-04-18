// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Platform {
  static int _numberOfProcessors() native "Platform_NumberOfProcessors";
  static String _pathSeparator() native "Platform_PathSeparator";
  static String _operatingSystem() native "Platform_OperatingSystem";
  static _localHostname() native "Platform_LocalHostname";
  static _environment() native "Platform_Environment";

  static int numberOfProcessors() {
    return _numberOfProcessors();
  }

  static String pathSeparator() {
    return _pathSeparator();
  }

  static String operatingSystem() {
    return _operatingSystem();
  }

  static String localHostname() {
    var result = _localHostname();
    if (result is OSError) {
      throw result;
    } else {
      return result;
    }
  }

  static Map<String, String> environment() {
    var env = _environment();
    if (env is OSError) {
      throw env;
    } else {
      var result = new Map();
      for (var str in env) {
        var equalsIndex = str.indexOf('=');
        assert(equalsIndex != -1);
        result[str.substring(0, equalsIndex)] = str.substring(equalsIndex + 1);
      }
      return result;
    }
  }
}
