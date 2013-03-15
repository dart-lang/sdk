library java.engine.io;

import "dart:io";
import "java_io.dart";


class OSUtilities {
  static bool isWindows() => Platform.operatingSystem == 'windows';
  static bool isMac() => Platform.operatingSystem == 'macos';
}

class FileUtilities2 {
  static JavaFile createFile(String path) => new JavaFile(path);
}
