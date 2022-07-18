import 'dart:isolate';
import 'dart:io';

import 'package:path/path.dart' as p;

main() async {
  Directory tmp = await Directory.systemTemp.createTemp("testCopy");
  var path = "${tmp.path}/other.dart";
  var sourceFile = new File(path);
  sourceFile.writeAsStringSync("""
    import 'package:path/path.dart' as p;

    void main() => print(p.current);
  """);

  var exitPort = new ReceivePort();
  await Isolate.spawnUri(p.toUri(p.absolute(path)), [], null,
      packageConfig: p.toUri(p.absolute(".dart_tool/package_config.json")),
      onExit: exitPort.sendPort);
  await exitPort.first;
  await sourceFile.delete();
}
