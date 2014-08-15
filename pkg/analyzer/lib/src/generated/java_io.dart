library java.io;

import "dart:io";
import 'java_core.dart' show JavaIOException, CharSequence;
import 'package:path/path.dart' as pathos;

class JavaSystemIO {
  static Map<String, String> _properties = new Map();
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
          var outDir = pathos.dirname(pathos.dirname(exec));
          sdkPath = pathos.join(pathos.dirname(outDir), "sdk");
          if (new Directory(sdkPath).existsSync()) {
            _properties[name] = sdkPath;
            return sdkPath;
          }
        }
        // probably be "dart-sdk/bin/dart"
        sdkPath = pathos.dirname(pathos.dirname(exec));
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
  static String getenv(String name) => Platform.environment[name];
}

class JavaFile {
  static final String separator = Platform.pathSeparator;
  static final int separatorChar = Platform.pathSeparator.codeUnitAt(0);
  String _path;
  JavaFile(String path) {
    _path = path;
  }
  JavaFile.relative(JavaFile base, String child) {
    if (child.isEmpty) {
      this._path = base._path;
    } else {
      this._path = pathos.join(base._path, child);
    }
  }
  JavaFile.fromUri(Uri uri) : this(pathos.fromUri(uri));
  String toString() => _path.toString();
  int get hashCode => _path.hashCode;
  bool operator ==(other) {
    return other is JavaFile && other._path == _path;
  }
  String getPath() => _path;
  String getName() => pathos.basename(_path);
  String getParent() {
    var result = pathos.dirname(_path);
    // "." or  "/" or  "C:\"
    if (result.length < 4) return null;
    return result;
  }
  JavaFile getParentFile() {
    var parent = getParent();
    if (parent == null) return null;
    return new JavaFile(parent);
  }
  String getAbsolutePath() => pathos.absolute(_path);
  String getCanonicalPath() {
    try {
      return _newFile().resolveSymbolicLinksSync();
    } catch (e) {
      throw new JavaIOException('IOException', e);
    }
  }
  JavaFile getAbsoluteFile() => new JavaFile(getAbsolutePath());
  JavaFile getCanonicalFile() => new JavaFile(getCanonicalPath());
  bool exists() {
    if (_newFile().existsSync()) {
      return true;
    }
    if (_newDirectory().existsSync()) {
      return true;
    }
    return false;
  }
  bool isExecutable() {
    return _newFile().statSync().mode & 0x111 != 0;
  }
  bool isFile() {
    return _newFile().existsSync();
  }
  bool isDirectory() {
    return _newDirectory().existsSync();
  }
  Uri toURI() {
    String path = getAbsolutePath();
    return pathos.toUri(path);
  }
  String readAsStringSync() => _newFile().readAsStringSync();
  int lastModified() {
    if (!_newFile().existsSync()) return 0;
    return _newFile().lastModifiedSync().millisecondsSinceEpoch;

  }
  List<JavaFile> listFiles() {
    var files = <JavaFile>[];
    var entities = _newDirectory().listSync();
    for (FileSystemEntity entity in entities) {
      files.add(new JavaFile(entity.path));
    }
    return files;
  }
  File _newFile() => new File(_path);
  Directory _newDirectory() => new Directory(_path);
}
