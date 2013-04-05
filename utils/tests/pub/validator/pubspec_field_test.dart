// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../../pub/entrypoint.dart';
import '../../../pub/validator.dart';
import '../../../pub/validator/pubspec_field.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator pubspecField(Entrypoint entrypoint) =>
  new PubspecFieldValidator(entrypoint);

main() {
  initConfig();

  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);

    integration('looks normal', () => expectNoValidationError(pubspecField));

    integration('has "authors" instead of "author"', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["authors"] = [pkg.remove("author")];
      d.dir(appPath, [d.pubspec(pkg)]).create();
      expectNoValidationError(pubspecField);
    });
  });

  group('should consider a package invalid if it', () {
    setUp(d.validPackage.create);

    integration('is missing the "homepage" field', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("homepage");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationError(pubspecField);
    });

    integration('is missing the "description" field', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("description");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationError(pubspecField);
    });

    integration('is missing the "author" field', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("author");
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationError(pubspecField);
    });

    integration('has a single author without an email', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["author"] = "Nathan Weizenbaum";
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has one of several authors without an email', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("author");
      pkg["authors"] = [
        "Bob Nystrom <rnystrom@google.com>",
        "Nathan Weizenbaum",
        "John Messerly <jmesserly@google.com>"
      ];
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has a single author without a name', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg["author"] = "<nweiz@google.com>";
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });

    integration('has one of several authors without a name', () {
      var pkg = packageMap("test_pkg", "1.0.0");
      pkg.remove("author");
      pkg["authors"] = [
        "Bob Nystrom <rnystrom@google.com>",
        "<nweiz@google.com>",
        "John Messerly <jmesserly@google.com>"
      ];
      d.dir(appPath, [d.pubspec(pkg)]).create();

      expectValidationWarning(pubspecField);
    });
  });
}
