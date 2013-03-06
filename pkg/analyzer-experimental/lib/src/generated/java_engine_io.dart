library java.engine.io;

import "dart:io";


class OSUtilities {
  static bool isWindows() => Platform.operatingSystem == 'windows';
  static bool isMac() => Platform.operatingSystem == 'macos';
}

class FileUtilities2 {
  static File createFile(String path) => new File(path);
}
