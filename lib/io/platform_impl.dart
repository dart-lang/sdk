// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Platform {
  external static int _numberOfProcessors();
  external static String _pathSeparator();
  external static String _operatingSystem();
  external static _localHostname();
  external static _environment();

  static int get numberOfProcessors {
    return _numberOfProcessors();
  }

  static String get pathSeparator {
    return _pathSeparator();
  }

  static String get operatingSystem {
    return _operatingSystem();
  }

  static String get localHostname {
    var result = _localHostname();
    if (result is OSError) {
      throw result;
    } else {
      return result;
    }
  }

  static Map<String, String> get environment {
    var env = _environment();
    if (env is OSError) {
      throw env;
    } else {
      var result = new Map();
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
        result[str.substring(0, equalsIndex)] = str.substring(equalsIndex + 1);
      }
      return result;
    }
  }
}
