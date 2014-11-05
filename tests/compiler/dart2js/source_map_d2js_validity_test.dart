// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/implementation/dart2js.dart' as entry;
import 'package:compiler/implementation/apiimpl.dart';

import 'source_map_validator_helper.dart';
import 'compiler_alt.dart' as alt;

void main() {
  entry.compileFunc = alt.compile;

  asyncTest(() => createTempDir().then((Directory tmpDir) {
    print(
        'Compiling tests/compiler/dart2js/source_map_validator_test_file.dart');
    Future result = entry.internalMain(
        ['tests/compiler/dart2js/source_map_validator_test_file.dart',
         '-o${tmpDir.path}/out.js',
         '--library-root=sdk']);
      return result.then((_) {
        Compiler compiler = alt.compiler;
        Uri uri =
            new Uri.file('${tmpDir.path}/out.js', windows: Platform.isWindows);
        validateSourceMap(uri, compiler);

        print("Deleting '${tmpDir.path}'.");
        tmpDir.deleteSync(recursive: true);
      });
  }));
}
