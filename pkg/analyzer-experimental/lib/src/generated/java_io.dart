library java.io;

import "dart:io";
import "dart:uri";

class JavaSystemIO {
  static final String pathSeparator = Platform.pathSeparator;
  static final int pathSeparatorChar = Platform.pathSeparator.codeUnitAt(0);
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


File newRelativeFile(File base, String child) {
  var childPath = new Path(base.fullPathSync()).join(new Path(child));
  return new File.fromPath(childPath);
}

File newFileFromUri(Uri uri) {
  return new File(uri.path);
}

File getAbsoluteFile(File file) {
  var path = file.fullPathSync();
  return new File(path);
}

Uri newUriFromFile(File file) {
  return new Uri.fromComponents(path: file.fullPathSync());
}
