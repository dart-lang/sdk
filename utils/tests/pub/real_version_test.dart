// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'test_pub.dart';

main() {
  initConfig();

  // This test is a bit funny.
  //
  // Pub parses the "version" file that gets generated and shipped with the SDK.
  // Most of the pub tests here generate a synthetic SDK directory so that we
  // can tests against a known SDK state. But we want to make sure that the
  // actual version file that gets created is also one pub can parse. If this
  // test fails, it means the version file's format has changed in a way pub
  // didn't expect.
  //
  // Note that this test expects to be invoked from a Dart executable that is
  // in the built SDK's "bin" directory. Note also that this invokes pub from
  // the built SDK directory, and not the live pub code directly in the repo.
  test('parse the real SDK "version" file', () {
    // Get the path to the pub binary in the SDK.
    var dartPath = new Options().executable;
    var pubPath = path.join(path.dirname(dartPath), "pub");
    if (Platform.operatingSystem == "windows") pubPath = '$pubPath.bat';

    Process.run(pubPath, ['version']).then(expectAsync1((result) {
      expect(result.stdout, startsWith("Pub"));
      expect(result.exitCode, equals(0));
    }));
  });
}
