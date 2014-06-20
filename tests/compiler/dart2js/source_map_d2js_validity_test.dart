// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';

import 'source_map_validator_helper.dart';
import 'package:compiler/implementation/dart2js.dart' as entry;

void main() {
  asyncTest(() => createTempDir().then((Directory tmpDir) {
    print('Compiling tests/compiler/dart2js/exit_code_helper.dart');
    Future result =
          entry.internalMain(['tests/compiler/dart2js/exit_code_helper.dart',
                              '-o${tmpDir.path}/out.js',
                              '--library-root=sdk']);
      return result.then((_) {
        Uri uri =
            new Uri.file('${tmpDir.path}/out.js', windows: Platform.isWindows);
        validateSourceMap(uri);

        print("Deleting '${tmpDir.path}'.");
        tmpDir.deleteSync(recursive: true);
      });
  }));
}
