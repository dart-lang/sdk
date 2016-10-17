// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.java_io;

import "dart:io";

import 'package:path/path.dart' as path;

class JavaFile {
  @deprecated
  static path.Context pathContext = path.context;
  static final String separator = Platform.pathSeparator;
  static final int separatorChar = Platform.pathSeparator.codeUnitAt(0);
  String _path;
  JavaFile(String path) {
    _path = path;
  }
  JavaFile.fromUri(Uri uri) : this(path.context.fromUri(uri));
  JavaFile.relative(JavaFile base, String child) {
    if (child.isEmpty) {
      this._path = base._path;
    } else {
      this._path = path.context.join(base._path, child);
    }
  }
  @override
  int get hashCode => _path.hashCode;
  @override
  bool operator ==(other) {
    return other is JavaFile && other._path == _path;
  }

  bool exists() {
    if (_newFile().existsSync()) {
      return true;
    }
    if (_newDirectory().existsSync()) {
      return true;
    }
    return false;
  }

  JavaFile getAbsoluteFile() => new JavaFile(getAbsolutePath());
  String getAbsolutePath() {
    String abolutePath = path.context.absolute(_path);
    abolutePath = path.context.normalize(abolutePath);
    return abolutePath;
  }

  JavaFile getCanonicalFile() => new JavaFile(getCanonicalPath());
  String getCanonicalPath() {
    return _newFile().resolveSymbolicLinksSync();
  }

  String getName() => path.context.basename(_path);
  String getParent() {
    var result = path.context.dirname(_path);
    // "." or  "/" or  "C:\"
    if (result.length < 4) return null;
    return result;
  }

  JavaFile getParentFile() {
    var parent = getParent();
    if (parent == null) return null;
    return new JavaFile(parent);
  }

  String getPath() => _path;
  bool isDirectory() {
    return _newDirectory().existsSync();
  }

  bool isExecutable() {
    return _newFile().statSync().mode & 0x111 != 0;
  }

  bool isFile() {
    return _newFile().existsSync();
  }

  int lastModified() {
    try {
      return _newFile().lastModifiedSync().millisecondsSinceEpoch;
    } catch (exception) {
      return -1;
    }
  }

  List<JavaFile> listFiles() {
    var files = <JavaFile>[];
    var entities = _newDirectory().listSync();
    for (FileSystemEntity entity in entities) {
      files.add(new JavaFile(entity.path));
    }
    return files;
  }

  String readAsStringSync() => _newFile().readAsStringSync();
  @override
  String toString() => _path.toString();
  Uri toURI() {
    String absolutePath = getAbsolutePath();
    return path.context.toUri(absolutePath);
  }

  Directory _newDirectory() => new Directory(_path);
  File _newFile() => new File(_path);
}

class JavaSystemIO {
  static Map<String, String> _properties = new Map();
  static String getenv(String name) => Platform.environment[name];
  static String getProperty(String name) {
    {
      String value = _properties[name];
      if (value != null) {
        return value;
      }
    }
    if (name == 'os.name') {
      return Platform.operatingSystem;
    }
    if (name == 'line.separator') {
      if (Platform.isWindows) {
        return '\r\n';
      }
      return '\n';
    }
    if (name == 'com.google.dart.sdk') {
      String exec = Platform.executable;
      if (exec.length != 0) {
        String sdkPath;
        // may be "xcodebuild/ReleaseIA32/dart" with "sdk" sibling
        {
          var outDir = path.context.dirname(path.context.dirname(exec));
          sdkPath = path.context.join(path.context.dirname(outDir), "sdk");
          if (new Directory(sdkPath).existsSync()) {
            _properties[name] = sdkPath;
            return sdkPath;
          }
        }
        // probably be "dart-sdk/bin/dart"
        sdkPath = path.context.dirname(path.context.dirname(exec));
        _properties[name] = sdkPath;
        return sdkPath;
      }
    }
    return null;
  }

  static String setProperty(String name, String value) {
    String oldValue = _properties[name];
    _properties[name] = value;
    return oldValue;
  }
}
