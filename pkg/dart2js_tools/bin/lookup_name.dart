import 'dart:io';
import 'dart:convert';
import 'package:source_maps/source_maps.dart';
import 'package:dart2js_tools/src/dart2js_mapping.dart';

main(List<String> args) {
  if (args.length < 2) {
    print('usage: read.dart <source-map-file> <name>');
    exit(1);
  }
  var name = args[1];

  var sourcemapFile = new File.fromUri(Uri.base.resolve(args[0]));
  if (!sourcemapFile.existsSync()) {
    print('Error: no such file: $sourcemapFile');
    exit(1);
  }
  var json = jsonDecode(sourcemapFile.readAsStringSync());
  Dart2jsMapping mapping = Dart2jsMapping(parseJson(json), json);
  var global = mapping.globalNames[name];
  if (global != null) print('$name => $global (a global name)');
  var instance = mapping.instanceNames[name];
  if (instance != null) print('$name => $instance (an instance name)');
  if (global == null && instance == null) print('Name \'$name\' not found.');
}
