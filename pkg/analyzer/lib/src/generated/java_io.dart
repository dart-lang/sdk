// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.java_io;

import "dart:io";

import 'package:analyzer/src/generated/java_core.dart' show JavaIOException;
import 'package:path/path.dart' as path;

class JavaFile {
  static path.Context pathContext = path.context;
  static final String separator = Platform.pathSeparator;
  static final int separatorChar = Platform.pathSeparator.codeUnitAt(0);
  String _path;
  JavaFile(String path) {
    _path = path;
  }
  JavaFile.fromUri(Uri uri) : this(pathContext.fromUri(uri));
  JavaFile.relative(JavaFile base, String child) {
    if (child.isEmpty) {
      this._path = base._path;
    } else {
      this._path = pathContext.join(base._path, child);
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
    String path = pathContext.absolute(_path);
    path = pathContext.normalize(path);
    return path;
  }

  JavaFile getCanonicalFile() => new JavaFile(getCanonicalPath());
  String getCanonicalPath() {
    try {
      return _newFile().resolveSymbolicLinksSync();
    } catch (e) {
      throw new JavaIOException('IOException', e);
    }
  }

  String getName() => pathContext.basename(_path);
  String getParent() {
    var result = pathContext.dirname(_path);
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
    String path = getAbsolutePath();
    return pathContext.toUri(path);
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
          var outDir =
              JavaFile.pathContext.dirname(JavaFile.pathContext.dirname(exec));
          sdkPath = JavaFile.pathContext
              .join(JavaFile.pathContext.dirname(outDir), "sdk");
          if (new Directory(sdkPath).existsSync()) {
            _properties[name] = sdkPath;
            return sdkPath;
          }
        }
        // probably be "dart-sdk/bin/dart"
        sdkPath =
            JavaFile.pathContext.dirname(JavaFile.pathContext.dirname(exec));
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
