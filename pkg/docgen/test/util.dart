import 'dart:io';
import 'package:path/path.dart' as p;

String getMultiLibraryCodePath() {
  var currentScript = p.fromUri(Platform.script);
  var codeDir = p.join(p.dirname(currentScript), 'multi_library_code');

  assert(FileSystemEntity.isDirectorySync(codeDir));

  return codeDir;
}
