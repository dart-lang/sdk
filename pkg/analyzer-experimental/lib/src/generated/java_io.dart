library java.io;

import "dart:io";
import "dart:uri";

class JavaSystemIO {
  static String getProperty(String name) {
    if (name == 'os.name') {
      return Platform.operatingSystem;
    }
    if (name == 'line.separator') {
      if (Platform.operatingSystem == 'windows') {
        return '\r\n';
      }
      return '\n';
    }
    return null;
  }
  static String getenv(String name) => Platform.environment[name];
}

class JavaFile {
  static final String separator = Platform.pathSeparator;
  static final int separatorChar = Platform.pathSeparator.codeUnitAt(0);
  Path _path;
  JavaFile(String path) {
    this._path = new Path(path);
  }
  JavaFile.relative(JavaFile base, String child) {
    this._path = base._path.join(new Path(child));
  }
  JavaFile.fromUri(Uri uri) : this(uri.path);
  int get hashCode => _path.hashCode;
  bool operator ==(other) {
    return other is JavaFile && _path == other._path;
  }
  String getPath() => _path.toNativePath();
  String getName() => _path.filename;
  String getParent() => _path.directoryPath.toNativePath();
  JavaFile getParentFile() => new JavaFile(getParent());
  String getAbsolutePath() => _path.canonicalize().toNativePath();
  String getCanonicalPath() => _path.canonicalize().toNativePath();
  JavaFile getAbsoluteFile() => new JavaFile(getAbsolutePath());
  JavaFile getCanonicalFile() => new JavaFile(getCanonicalPath());
  bool exists() => _newFile().existsSync();
  Uri toURI() => new Uri.fromComponents(path: _path.toString());
  String readAsStringSync() => _newFile().readAsStringSync();
  int lastModified() => _newFile().lastModifiedSync().millisecondsSinceEpoch;
  File _newFile() => new File.fromPath(_path);
}
