// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Platform implements Platform {
  _Platform();

  static int _numberOfProcessors() native "Platform_NumberOfProcessors";
  static String _pathSeparator() native "Platform_PathSeparator";
  static String _operatingSystem() native "Platform_OperatingSystem";
  static _localHostname() native "Platform_LocalHostname";

  int numberOfProcessors() {
    return _numberOfProcessors();
  }

  String pathSeparator() {
    return _pathSeparator();
  }

  String operatingSystem() {
    return _operatingSystem();
  }

  String localHostname() {
    var result = _localHostname();
    if (result is OSError) {
      throw result;
    } else {
      return result;
    }
  }
}
