// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';

Future<AllInfo> infoFromFile(String fileName) async {
  var file = File(fileName);
  if (fileName.endsWith('.json')) {
    return AllInfoJsonCodec().decode(jsonDecode(await file.readAsString()));
  } else {
    return binary.decode(file.readAsBytesSync());
  }
}
