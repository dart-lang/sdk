// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This program reads the HTML libraries from [LIB_PATH] and outputs their
 * documentation to [JSON_PATH].
 */

import 'dart:io';
import 'dart:async';

import 'package:path/path.dart' as path;

import '../lib/docs.dart';

final String json_path = Platform.script.resolve('../docs.json').toFilePath();
final String lib_uri = Platform.script.resolve('../../../../sdk').toString();

main() {
  print('Converting HTML docs from $lib_uri to $json_path.');

  convert(lib_uri, json_path).then((bool anyErrors) {
    print('Converted HTML docs ${anyErrors ? "with": "without"}'
        ' errors.');
  });
}
