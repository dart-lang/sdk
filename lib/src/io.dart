import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/binary_serialization.dart' as binary;

Future<AllInfo> infoFromFile(String fileName) async {
  var file = new File(fileName);
  if (fileName.endsWith('.json')) {
    return new AllInfoJsonCodec().decode(jsonDecode(await file.readAsString()));
  } else {
    return binary.decode(file.readAsBytesSync());
  }
}
