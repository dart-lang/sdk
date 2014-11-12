// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/entrypoint.dart';
import '../../lib/src/validator.dart';
import '../../lib/src/validator/sdk_constraint.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator sdkConstraint(Entrypoint entrypoint) =>
    new SdkConstraintValidator(entrypoint);

main() {
  initConfig();

  group('should consider a package valid if it', () {
    integration('has no SDK constraint', () {
      d.validPackage.create();
      expectNoValidationError(sdkConstraint);
    });

    integration('has an SDK constraint without ^', () {
      d.dir(
          appPath,
          [d.libPubspec("test_pkg", "1.0.0", sdk: ">=1.8.0 <2.0.0")]).create();
      expectNoValidationError(sdkConstraint);
    });
  });

  test(
      "should consider a package invalid if it has an SDK constraint with " "^",
      () {
    d.dir(appPath, [d.libPubspec("test_pkg", "1.0.0", sdk: "^1.8.0")]).create();
    expect(
        schedulePackageValidation(sdkConstraint),
        completion(pairOf(anyElement(contains('">=1.8.0 <2.0.0"')), isEmpty)));
  });
}
