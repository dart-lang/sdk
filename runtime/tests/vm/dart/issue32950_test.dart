import 'dart:isolate';
import 'dart:io';

import 'package:path/path.dart' as p;

main() async {
  var path = '/tmp/other.dart';
  new File(path).writeAsStringSync("""
    import 'package:path/path.dart' as p;

    void main() => print(p.current);
  """);

  var exitPort = new ReceivePort();
  await Isolate.spawnUri(p.toUri(p.absolute(path)), [], null,
      packageConfig: p.toUri(p.absolute(".packages")),
      onExit: exitPort.sendPort);
  await exitPort.first;
}
