// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test to ensure that incremental_perf.dart is running without errors.

import 'dart:convert';
import 'dart:io';
import 'incremental_perf.dart' as m;

main() async {
  var entryUri = Platform.script.resolve('../../compiler/lib/src/dart2js.dart');
  var tmp = Directory.systemTemp.createTempSync();
  var jsonUri = tmp.uri.resolve('edits.json');
  var editedFile =
      Platform.script.resolve('../../compiler/lib/src/library_loader.dart');
  new File.fromUri(jsonUri).writeAsStringSync(JSON.encode([
    // iteration 1: no edits
    [],
    // iteration 2: a single edit
    [
      ['$editedFile', 'root=', 'root2=']
    ],
    // iteration 3: no edits
    [],
    // iteration 4: a single edit reverting to a known state from iteration 1,
    // if the incremental compiler is caching old results, this should not
    // require much work.
    [
      ['$editedFile', 'root2=', 'root=']
    ],
  ]));

  // Derive the outline.dill location from the vm.  Depending on whether tests
  // are run with --use-sdk, we resolve the outline file slightly differently.
  var dartVm = Uri.parse(Platform.resolvedExecutable);
  var dir = dartVm.resolve('.');
  var sdkOutline;
  if (dir.path.endsWith('dart-sdk/bin/')) {
    sdkOutline = dir.resolve('../lib/_internal/vm_outline.dill');
  } else {
    // TODO(sigmund): switch to outline.dill (issue #29881)
    sdkOutline = dir.resolve('patched_sdk/platform.dill');
  }
  await m.main(['--sdk-summary', '$sdkOutline', '$entryUri', '$jsonUri']);
  tmp.deleteSync(recursive: true);
}
