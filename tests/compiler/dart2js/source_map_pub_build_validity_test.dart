// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'source_map_validator_helper.dart';

void main() {
  asyncTest(() async {
    Directory tmpDir = await createTempDir();
    try {
      Directory sunflowerDir = new Directory.fromUri(
          Platform.script.resolve('../../../third_party/sunflower'));

      print("Copying '${sunflowerDir.path}' to '${tmpDir.path}'.");
      copyDirectory(sunflowerDir, tmpDir);
      String ext = Platform.isWindows ? '.bat' : '';
      String command = path.normalize(path.join(
          path.fromUri(Platform.script), '../../../../sdk/bin/pub${ext}'));
      String file = path.join(tmpDir.path, 'build/web/sunflower.dart.js');

      print("Running '$command get' from '${tmpDir}'.");
      ProcessResult getResult =
          await Process.run(command, ['get'], workingDirectory: tmpDir.path);
      print(getResult.stdout);
      print(getResult.stderr);
      Expect.equals(0, getResult.exitCode, 'Unexpected exitCode from pub get');

      print("Running '$command build --mode=debug' from '${tmpDir}'.");
      ProcessResult buildResult = await Process.run(
          command, ['build', '--mode=debug'],
          workingDirectory: tmpDir.path);
      print(buildResult.stdout);
      print(buildResult.stderr);
      Expect.equals(0, buildResult.exitCode, 'Unexpected exitCode from pub');
      validateSourceMap(new Uri.file(file, windows: Platform.isWindows));
      print("Deleting '${tmpDir.path}'.");
    } finally {
      tmpDir.deleteSync(recursive: true);
    }
  });
}
