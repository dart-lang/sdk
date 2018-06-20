// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool to convert an info.json file ouputted by dart2js to the
/// alternative protobuf format.

import 'dart:io';

import 'package:dart2js_info/proto_info_codec.dart';
import 'package:dart2js_info/src/util.dart';

main(args) async {
  if (args.length != 2) {
    print('usage: dart tool/info_json_to_proto.dart '
        'path-to-info.json path-to-info.pb');
    exit(1);
  }

  final info = await infoFromFile(args.first);
  final proto = new AllInfoProtoCodec().encode(info);
  final outputFile = new File(args.last);
  await outputFile.writeAsBytes(proto.writeToBuffer(), mode: FileMode.write);
}
