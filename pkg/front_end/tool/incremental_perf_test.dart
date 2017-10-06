// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test to ensure that incremental_perf.dart is running without errors.

import 'dart:io';
import 'incremental_perf.dart' as m;

/// Run the incremental compiler on a couple examples.
main() async {
  // Derive the outline.dill location from the vm.  Depending on whether tests
  // are run with --use-sdk, we resolve the outline file slightly differently.
  var dartVm = Uri.parse(Platform.resolvedExecutable);
  var dir = dartVm.resolve('.');
  var sdkOutline;
  if (dir.path.endsWith('dart-sdk/bin/')) {
    sdkOutline = dir.resolve('../lib/_internal/vm_outline.dill');
  } else {
    // TODO(sigmund): switch to outline.dill (issue #29881)
    sdkOutline = dir.resolve('vm_platform.dill');
  }

  var tmp = Directory.systemTemp.createTempSync();
  await runSmallExample(sdkOutline, tmp.uri);
  await runLargeExample(sdkOutline, tmp.uri);
  tmp.deleteSync(recursive: true);
}

/// Creates a small example with a few files in a temporary folder, and runs the
/// benchmark on it. The example includes several edits in sequence.
runSmallExample(Uri sdkOutline, Uri tmpUri) async {
  Map<String, String> files = {
    'a.dart': '''
        import 'b.dart';
        main() => b();
    ''',
    'b.dart': '''
        import 'c.dart';
        b() => new C().m1();
    ''',
    'c.dart': '''
        class C {
          m1() => print('hello1');
          m2() => print('hello2');
        }
    ''',
    //
    // iteration 1: no edits
    // iteration 2: edit b.dart (a.dart may recompile, c.dart unchanged)
    // iteration 3: no edits
    // iteration 4: edit c.dart (may recompile everything)
    // iteration 4: edit b.dart and c.dart to revert to state of iteration 1
    //              may skip recompile if compiler cached old results.
    'edits.json': '''[
      [],
      [["${tmpUri.resolve('b.dart')}", "m1()", "m2()"]],
      [],
      [["${tmpUri.resolve('c.dart')}", "hello1", "hello3"]],
      [
        ["${tmpUri.resolve('b.dart')}", "m2()", "m1()"],
        ["${tmpUri.resolve('c.dart')}", "hello3", "hello1"]
      ]
    ]''',
  };

  files.forEach((name, contents) {
    new File.fromUri(tmpUri.resolve(name)).writeAsStringSync(contents);
  });
  var entryUri = tmpUri.resolve('a.dart');
  var jsonUri = tmpUri.resolve('edits.json');
  await m.main(['--sdk-summary', '$sdkOutline', '$entryUri', '$jsonUri']);
}

/// Create an example using the dart2js codebase. It can take a while to
/// compile dart2js, so to avoid timeouts we only run a single iteration of the
/// incremental compiler on this codebase.
runLargeExample(Uri sdkOutline, Uri tmpUri) async {
  var jsonUri = tmpUri.resolve('edits.json');
  var loaderFile =
      Platform.script.resolve('../../compiler/lib/src/library_loader.dart');
  new File.fromUri(jsonUri)
      .writeAsStringSync('[[["$loaderFile", "root=", "root2="]]]');
  var entryUri = Platform.script.resolve('../../compiler/lib/src/dart2js.dart');
  await m.main(['--sdk-summary', '$sdkOutline', '$entryUri', '$jsonUri']);
}
