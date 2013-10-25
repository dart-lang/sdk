// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch int get numberOfProcessors => _platform.numberOfProcessors;

patch String get pathSeparator => _platform.pathSeparator;

patch String get operatingSystem => _platform.operatingSystem;

patch String get localHostname => _platform.localHostname;

patch String get version => _platform.version;

patch Map<String, String> get environment => _platform.environment;

patch String get executable => _platform.executable;

patch Uri get script => _platform.script;

patch List<String> get executableArguments => _platform.executableArguments;

patch String get packageRoot => _platform.packageRoot;

patch bool get isLinux => _platform.operatingSystem == "linux";

patch bool get isMacOS => _platform.operatingSystem == "macos";

patch bool get isWindows => _platform.operatingSystem == "windows";

patch bool get isAndroid => _platform.operatingSystem == "android";

class _Platform {
  int get numberOfProcessors;
  String get pathSeparator;
  String get operatingSystem;
  String get localHostname;
  String get version;
  Map get environment;
  Uri get script;
  String get executable;
  List<String>  get executableArguments;
  String get packageRoot;
}

// A non-default _Platform, with real values, is stored here by the embedder.
_Platform _platform = new _DefaultPlatform();

class _DefaultPlatform implements _Platform {
  int get numberOfProcessors {
    return null;
  }

  String get pathSeparator {
    return "/";
  }

  String get operatingSystem {
    return null;
  }

  String get localHostname {
    return null;
  }

  String get version {
    return null;
  }

  Map get environment {
    return null;
  }

  Uri get script {
    return null;
  }

  String get executable {
    return null;
  }

  List<String>  get executableArguments {
    return new List<String>(0);
  }

  String get packageRoot {
    return null;
  }
}
