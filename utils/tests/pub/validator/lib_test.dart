// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../pub/entrypoint.dart';
import '../../../pub/io.dart';
import '../../../pub/validator.dart';
import '../../../pub/validator/lib.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator lib(Entrypoint entrypoint) => new LibValidator(entrypoint);

main() {
  initConfig();

  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);

    integration('looks normal', () => expectNoValidationError(lib));

    integration('has a non-Dart file in lib', () {
      d.dir(appPath, [
        d.libPubspec("test_pkg", "1.0.0"),
        d.dir("lib", [
          d.file("thing.txt", "woo hoo")
        ])
      ]).create();
      expectNoValidationError(lib);
    });
  });

  group('should consider a package invalid if it', () {
    setUp(d.validPackage.create);

    integration('has no lib directory', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, "lib")));
      expectValidationError(lib);
    });

    integration('has an empty lib directory', () {
      schedule(() =>
          deleteEntry(path.join(sandboxDir, appPath, "lib", "test_pkg.dart")));
      expectValidationError(lib);
    });

    integration('has a lib directory containing only src', () {
      schedule(() =>
          deleteEntry(path.join(sandboxDir, appPath, "lib", "test_pkg.dart")));
      d.dir(appPath, [
        d.dir("lib", [
          d.dir("src", [d.file("test_pkg.dart", "int i = 0;")])
        ])
      ]).create();
      expectValidationError(lib);
    });
  });
}
