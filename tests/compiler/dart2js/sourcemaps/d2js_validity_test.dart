// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2js.dart' as entry;
import 'package:compiler/src/apiimpl.dart';
import 'package:compiler/compiler_new.dart';

import 'helpers/source_map_validator_helper.dart';

void main() {
  String mainFile =
      'tests/compiler/dart2js/sourcemaps/test_files/validator_test_file.dart';
  asyncTest(() => createTempDir().then((Directory tmpDir) {
        print('Compiling $mainFile');
        Future<CompilationResult> result = entry.internalMain(
            [mainFile, '-o${tmpDir.path}/out.js', '--library-root=sdk']);
        return result.then((CompilationResult result) {
          CompilerImpl compiler = result.compiler;
          Uri uri = new Uri.file('${tmpDir.path}/out.js',
              windows: Platform.isWindows);
          validateSourceMap(uri,
              mainUri: Uri.base.resolve(mainFile),
              mainPosition: const Position(13, 1),
              compiler: compiler);

          print("Deleting '${tmpDir.path}'.");
          tmpDir.deleteSync(recursive: true);
        });
      }));
}
