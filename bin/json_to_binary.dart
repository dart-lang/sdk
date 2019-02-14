// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/binary_serialization.dart' as binary;
import 'package:dart2js_info/json_info_codec.dart';

main(args) async {
  if (args.length < 1) {
    print('usage: json_to_binary <input.json>');
    exit(1);
  }

  var input = new File(args[0]).readAsStringSync();
  AllInfo info = new AllInfoJsonCodec().decode(jsonDecode(input));
  var outstream = new File("${args[0]}.data").openWrite();
  binary.encode(info, outstream);
  await outstream.done;
  binary.decode(new File("${args[0]}.data").readAsBytesSync());
}
