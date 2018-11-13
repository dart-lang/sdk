import 'dart:io';
import 'dart:convert';
import 'package:source_maps/source_maps.dart';

main(List<String> args) {
  if (args.length < 2) {
    print('usage: read.dart <source-map-file> <name>');
    exit(1);
  }
  var sourcemapFile = new File.fromUri(Uri.base.resolve(args[0]));
  if (!sourcemapFile.existsSync()) {
    print('no source-map-file in ${args[0]}');
    exit(1);
  }
  var name = args[1];
  var json = jsonDecode(sourcemapFile.readAsStringSync());
  SingleMapping mapping = parseJson(json);
  var extensions = json['x_org_dartlang_dart2js'];
  if (extensions == null) {
    print('source-map file has no dart2js extensions');
    exit(1);
  }
  var minifiedNames = extensions['minified_names'];
  if (minifiedNames == null) {
    print('source-map file has no minified names in the dart2js extensions');
    exit(1);
  }
  var gid = minifiedNames['global'][name];
  if (gid != null) print('$name => ${mapping.names[gid]} (a global name)');
  var iid = minifiedNames['instance'][name];
  if (iid != null) print('$name => ${mapping.names[iid]} (an instance name)');
  if (gid == null && iid == null) print('Name \'$name\' not found.');
}
