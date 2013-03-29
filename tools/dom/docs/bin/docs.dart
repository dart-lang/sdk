// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This program reads the HTML libraries from [LIB_PATH] and outputs their
 * documentation to [JSON_PATH].
 */

import 'dart:io';
import 'dart:async';

import '../lib/docs.dart';

final Path json_path = scriptDir.append('../docs.json').canonicalize();
final Path lib_path = scriptDir.append('../../../../sdk/').canonicalize();

main() {
  print('Converting HTML docs from $lib_path to $json_path.');

  convert(lib_path, json_path)
    .then((bool anyErrors) {
      print('Converted HTML docs ${anyErrors ? "with": "without"}'
        ' errors.');
    });
}

/**
 * Gets the full path to the directory containing the entrypoint of the current
 * script.
 */
Path get scriptDir =>
    new Path(new Options().script).directoryPath;
