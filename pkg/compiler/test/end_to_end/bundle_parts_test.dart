// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that bundling part files into the same file still allows them to load
// correctly.

import 'dart:io';

import 'package:expect/expect.dart';

import '../helpers/d8_helper.dart';

const String verifyParts = '''
if (!\$__dart_deferred_initializers__) {
  throw 'Did not intialize \$__dart_deferred_initializers__';
}
// Expect 'eventLog', 'current', and 2 hashes for part files.
if (Object.keys(\$__dart_deferred_initializers__).length != 4) {
  var data =  JSON.stringify(\$__dart_deferred_initializers__);
  throw '\$__dart_deferred_initializers__ has unexpected format: ' + data;
}
''';

Future<Directory> createTempDir() {
  return Directory.systemTemp.createTemp('dart2js_bundle_parts_test-');
}

Future<void> runTestWithOptions(List<String> options) async {
  print('Running with flags: $options');
  final tmpDir = await createTempDir();
  Uri inUri = Platform.script.resolve('deferred_data/deferred_main.dart');
  Uri outUri = tmpDir.uri.resolve('out.js');
  await getCompilationResultsForD8(inUri, outUri, options: options);
  final part1 = File(tmpDir.uri.resolve('out.js_1.part.js').toFilePath());
  final part2 = File(tmpDir.uri.resolve('out.js_2.part.js').toFilePath());
  final bundledPartsUri = tmpDir.uri.resolve('out.bundle.js');
  final bundledParts = File(bundledPartsUri.toFilePath());
  await bundledParts.writeAsBytes(await part1.readAsBytes());
  await bundledParts.writeAsBytes(await part2.readAsBytes(),
      mode: FileMode.append);
  await bundledParts.writeAsString('\n$verifyParts', mode: FileMode.append);
  final result = executeJsWithD8([bundledPartsUri]);
  if (result.exitCode != 0) {
    Expect.fail('Expected exit code 0. D8 results:\n'
        '${(result.stdout as String).trim()}');
  }
  Expect.equals(0, result.exitCode);
}

void main() async {
  await runTestWithOptions([]);
  await runTestWithOptions(['--minify']);
}
