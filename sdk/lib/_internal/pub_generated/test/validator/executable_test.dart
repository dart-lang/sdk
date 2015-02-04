// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/entrypoint.dart';
import '../../lib/src/validator.dart';
import '../../lib/src/validator/executable.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator executable(Entrypoint entrypoint) =>
    new ExecutableValidator(entrypoint);

main() {
  initConfig();

  setUp(d.validPackage.create);

  group('should consider a package valid if it', () {
    integration('has executables that are present', () {
      d.dir(appPath, [d.pubspec({
          "name": "test_pkg",
          "version": "1.0.0",
          "executables": {
            "one": "one_script",
            "two": null
          }
        }),
            d.dir(
                "bin",
                [
                    d.file("one_script.dart", "main() => print('ok');"),
                    d.file("two.dart", "main() => print('ok');")])]).create();
      expectNoValidationError(executable);
    });
  });

  group("should consider a package invalid if it", () {
    integration('is missing one or more listed executables', () {
      d.dir(appPath, [d.pubspec({
          "name": "test_pkg",
          "version": "1.0.0",
          "executables": {
            "nope": "not_there",
            "nada": null
          }
        })]).create();
      expectValidationWarning(executable);
    });
  });
}
