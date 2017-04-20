// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docs_test;

import 'dart:io';

import 'package:unittest/unittest.dart';
import 'package:path/path.dart' as path;

import '../bin/docs.dart';
import '../lib/docs.dart';

final testJsonPath = Platform.script.resolve('test.json').toFilePath();

main() {
  // Some tests take more than the default 20 second unittest timeout.
  unittestConfiguration.timeout = null;
  group('docs', () {
    var oldJson = new File(json_path);
    var testJson = new File(testJsonPath);

    tearDown(() {
      // Clean up.
      if (testJson.existsSync()) {
        testJson.deleteSync();
      }
      assert(!testJson.existsSync());
    });

    test('Ensure that docs.json is up to date', () {
      // We should find a json file where we expect it.
      expect(oldJson.existsSync(), isTrue);

      // Save the last modified time to check it at the end.
      var oldJsonModified = oldJson.lastModifiedSync();

      // There should be no test file yet.
      if (testJson.existsSync()) testJson.deleteSync();
      assert(!testJson.existsSync());

      expect(
          convert(lib_uri, testJsonPath).then((bool anyErrors) {
            expect(anyErrors, isFalse);

            // We should have a file now.
            expect(testJson.existsSync(), isTrue);

            // Ensure that there's nothing different between the new JSON and old.
            expect(testJson.readAsStringSync(),
                equals(oldJson.readAsStringSync()));

            // Ensure that the old JSON file didn't actually change.
            expect(oldJsonModified, equals(oldJson.lastModifiedSync()));
          }),
          completes);
    });
  });
}
