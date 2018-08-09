import 'dart:io';
import 'dart:convert';
import 'package:source_maps/source_maps.dart';

main(List<String> args) {
  if (args.length != 1) {
    print('usage: read.dart <source-map-file>');
    exit(1);
  }

  var sourcemapFile = new File.fromUri(Uri.base.resolve(args[0]));
  if (!sourcemapFile.existsSync()) {
    print('no source-map-file in ${args[0]}');
  }
  var bytes = sourcemapFile.readAsBytesSync();
  parse(utf8.decode(bytes));
}
