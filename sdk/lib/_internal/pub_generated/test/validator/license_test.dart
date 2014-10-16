// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/entrypoint.dart';
import '../../lib/src/io.dart';
import '../../lib/src/validator.dart';
import '../../lib/src/validator/license.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator license(Entrypoint entrypoint) => new LicenseValidator(entrypoint);

main() {
  initConfig();

  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);

    integration('looks normal', () => expectNoValidationError(license));

    integration('has a COPYING file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      d.file(path.join(appPath, 'COPYING'), '').create();
      expectNoValidationError(license);
    });

    integration('has a prefixed LICENSE file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      d.file(path.join(appPath, 'MIT_LICENSE'), '').create();
      expectNoValidationError(license);
    });

    integration('has a suffixed LICENSE file', () {
      schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
      d.file(path.join(appPath, 'LICENSE.md'), '').create();
      expectNoValidationError(license);
    });
  });

  integration(
      'should consider a package invalid if it has no LICENSE file',
      () {
    d.validPackage.create();
    schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'LICENSE')));
    expectValidationError(license);
  });
}
