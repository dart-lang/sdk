// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/compiler_new.dart';

import 'source_map_validator_helper.dart';

void main() {
  asyncTest(() => createTempDir().then((Directory tmpDir) {
        String file =
            'tests/compiler/dart2js/source_map_deferred_validator_test_file.dart';
        print("Compiling $file");
        var result = entry.internalMain(
            [file, '-o${tmpDir.path}/out.js', '--library-root=sdk']);
        return result.then((CompilationResult result) {
          CompilerImpl compiler = result.compiler;
          Uri mainUri = new Uri.file('${tmpDir.path}/out.js',
              windows: Platform.isWindows);
          Uri deferredUri = new Uri.file('${tmpDir.path}/out.js_1.part.js',
              windows: Platform.isWindows);
          validateSourceMap(mainUri,
              mainUri: Uri.base.resolve(file),
              mainPosition: const Position(7, 1),
              compiler: compiler);
          validateSourceMap(deferredUri, compiler: compiler);

          print("Deleting '${tmpDir.path}'.");
          tmpDir.deleteSync(recursive: true);
        });
      }));
}
