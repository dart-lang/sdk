import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';

Future<AllInfo> infoFromFile(String fileName) async {
  var file = await new File(fileName).readAsString();
  return new AllInfoJsonCodec().decode(jsonDecode(file));
}
