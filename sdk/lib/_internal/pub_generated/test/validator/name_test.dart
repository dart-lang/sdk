// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/entrypoint.dart';
import '../../lib/src/io.dart';
import '../../lib/src/validator.dart';
import '../../lib/src/validator/name.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

Validator name(Entrypoint entrypoint) => new NameValidator(entrypoint);

main() {
  initConfig();

  group('should consider a package valid if it', () {
    setUp(d.validPackage.create);

    integration('looks normal', () => expectNoValidationError(name));

    integration('has a badly-named library in lib/src', () {
      d.dir(
          appPath,
          [
              d.libPubspec("test_pkg", "1.0.0"),
              d.dir(
                  "lib",
                  [
                      d.file("test_pkg.dart", "int i = 1;"),
                      d.dir("src", [d.file("8ball.dart", "int j = 2;")])])]).create();
      expectNoValidationError(name);
    });

    integration('has a name that starts with an underscore', () {
      d.dir(
          appPath,
          [
              d.libPubspec("_test_pkg", "1.0.0"),
              d.dir("lib", [d.file("_test_pkg.dart", "int i = 1;")])]).create();
      expectNoValidationError(name);
    });
  });

  group('should consider a package invalid if it', () {
    setUp(d.validPackage.create);

    integration('has an empty package name', () {
      d.dir(appPath, [d.libPubspec("", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a package name with an invalid character', () {
      d.dir(appPath, [d.libPubspec("test-pkg", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a package name that begins with a number', () {
      d.dir(appPath, [d.libPubspec("8ball", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a package name that contains upper-case letters', () {
      d.dir(appPath, [d.libPubspec("TestPkg", "1.0.0")]).create();
      expectValidationWarning(name);
    });

    integration('has a package name that is a Dart reserved word', () {
      d.dir(appPath, [d.libPubspec("final", "1.0.0")]).create();
      expectValidationError(name);
    });

    integration('has a library name with an invalid character', () {
      d.dir(
          appPath,
          [
              d.libPubspec("test_pkg", "1.0.0"),
              d.dir("lib", [d.file("test-pkg.dart", "int i = 0;")])]).create();
      expectValidationWarning(name);
    });

    integration('has a library name that begins with a number', () {
      d.dir(
          appPath,
          [
              d.libPubspec("test_pkg", "1.0.0"),
              d.dir("lib", [d.file("8ball.dart", "int i = 0;")])]).create();
      expectValidationWarning(name);
    });

    integration('has a library name that contains upper-case letters', () {
      d.dir(
          appPath,
          [
              d.libPubspec("test_pkg", "1.0.0"),
              d.dir("lib", [d.file("TestPkg.dart", "int i = 0;")])]).create();
      expectValidationWarning(name);
    });

    integration('has a library name that is a Dart reserved word', () {
      d.dir(
          appPath,
          [
              d.libPubspec("test_pkg", "1.0.0"),
              d.dir("lib", [d.file("for.dart", "int i = 0;")])]).create();
      expectValidationWarning(name);
    });

    integration('has a single library named differently than the package', () {
      schedule(
          () => deleteEntry(path.join(sandboxDir, appPath, "lib", "test_pkg.dart")));
      d.dir(
          appPath,
          [d.dir("lib", [d.file("best_pkg.dart", "int i = 0;")])]).create();
      expectValidationWarning(name);
    });
  });
}
