// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:async_helper/async_helper.dart';

import 'source_map_validator_helper.dart';

void main() {
  asyncTest(() => createTempDir().then((Directory tmpDir) {
    Directory sunflowerDir = new Directory.fromUri(
        Platform.script.resolve('../../../samples/sunflower'));

    print("Copying '${sunflowerDir.path}' to '${tmpDir.path}'.");
    copyDirectory(sunflowerDir, tmpDir);
    String ext = Platform.isWindows ? '.bat' : '';
    String command = path.normalize(path.join(path.fromUri(Platform.script),
                                              '../../../../sdk/bin/pub${ext}'));
    String file = path.join(tmpDir.path, 'build/web/sunflower.dart.js');
    print("Running '$command build --mode=debug' from '${tmpDir}'.");
    return Process.run(command, ['build','--mode=debug'],
        workingDirectory: tmpDir.path).then((process) {
      print(process.stdout);
      validateSourceMap(new Uri.file(file, windows: Platform.isWindows));
      print("Deleting '${tmpDir.path}'.");
      tmpDir.deleteSync(recursive: true);
    });
  }));
}