// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library validator_test;

import 'dart:io';
import 'dart:json';

import 'test_pub.dart';
import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/entrypoint.dart';
import '../../pub/io.dart';
import '../../pub/validator.dart';
import '../../pub/validator/lib.dart';
import '../../pub/validator/license.dart';
import '../../pub/validator/name.dart';
import '../../pub/validator/pubspec_field.dart';

void expectNoValidationError(ValidatorCreator fn) {
  expectLater(schedulePackageValidation(fn), pairOf(isEmpty, isEmpty));
}

void expectValidationError(ValidatorCreator fn) {
  expectLater(schedulePackageValidation(fn), pairOf(isNot(isEmpty), anything));
}

void expectValidationWarning(ValidatorCreator fn) {
  expectLater(schedulePackageValidation(fn), pairOf(isEmpty, isNot(isEmpty)));
}

Validator lib(Entrypoint entrypoint) => new LibValidator(entrypoint);

Validator license(Entrypoint entrypoint) => new LicenseValidator(entrypoint);

Validator name(Entrypoint entrypoint) => new NameValidator(entrypoint);

Validator pubspecField(Entrypoint entrypoint) =>
  new PubspecFieldValidator(entrypoint);

void scheduleNormalPackage() => normalPackage.scheduleCreate();

main() {
  group('should consider a package valid if it', () {
    setUp(scheduleNormalPackage);

    test('looks normal', () {
      dir(appPath, [libPubspec("test_pkg", "1.0.0")]).scheduleCreate();
      expectNoValidationError(license);
      expectNoValidationError(pubspecField);
      run();
    });

    test('has a COPYING file', () {
      file(join(appPath, 'LICENSE'), '').scheduleDelete();
      file(join(appPath, 'COPYING'), '').scheduleCreate();
      expectNoValidationError(license);
      run();
    });

    test('has a prefixed LICENSE file', () {
      file(join(appPath, 'LICENSE'), '').scheduleDelete();
      file(join(appPath, 'MIT_LICENSE'), '').scheduleCreate();
      expectNoValidationError(license);
      run();
    });

    test('has a suffixed LICENSE file', () {
      file(join(appPath, 'LICENSE'), '').scheduleDelete();
      file(join(appPath, 'LICENSE.md'), '').scheduleCreate();
      expectNoValidationError(license);
      run();
    });

    test('has "authors" instead of "author"', () {
      var package = package("test_pkg", "1.0.0");
      package["authors"] = [package.remove("author")];
      dir(appPath, [pubspec(package)]).scheduleCreate();
      expectNoValidationError(pubspecField);
      run();
    });

    test('has a badly-named library in lib/src', () {
      dir(appPath, [
        libPubspec("test_pkg", "1.0.0"),
        dir("lib", [
          file("test_pkg.dart", "int i = 1;"),
          dir("src", [file("8ball.dart", "int j = 2;")])
        ])
      ]).scheduleCreate();
      expectNoValidationError(name);
      run();
    });

    test('has a non-Dart file in lib', () {
      dir(appPath, [
        libPubspec("test_pkg", "1.0.0"),
        dir("lib", [
          file("thing.txt", "woo hoo")
        ])
      ]).scheduleCreate();
      expectNoValidationError(lib);
      run();
    });
  });

  group('should consider a package invalid if it', () {
    setUp(scheduleNormalPackage);

    test('is missing the "homepage" field', () {
      var package = package("test_pkg", "1.0.0");
      package.remove("homepage");
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationError(pubspecField);
      run();
    });

    test('is missing the "description" field', () {
      var package = package("test_pkg", "1.0.0");
      package.remove("description");
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationError(pubspecField);
      run();
    });

    test('is missing the "author" field', () {
      var package = package("test_pkg", "1.0.0");
      package.remove("author");
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationError(pubspecField);
      run();
    });

    test('has a single author without an email', () {
      var package = package("test_pkg", "1.0.0");
      package["author"] = "Nathan Weizenbaum";
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationWarning(pubspecField);
      run();
    });

    test('has one of several authors without an email', () {
      var package = package("test_pkg", "1.0.0");
      package.remove("author");
      package["authors"] = [
        "Bob Nystrom <rnystrom@google.com>",
        "Nathan Weizenbaum",
        "John Messerly <jmesserly@google.com>"
      ];
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationWarning(pubspecField);
      run();
    });

    test('has a single author without a name', () {
      var package = package("test_pkg", "1.0.0");
      package["author"] = "<nweiz@google.com>";
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationWarning(pubspecField);
      run();
    });

    test('has one of several authors without a name', () {
      var package = package("test_pkg", "1.0.0");
      package.remove("author");
      package["authors"] = [
        "Bob Nystrom <rnystrom@google.com>",
        "<nweiz@google.com>",
        "John Messerly <jmesserly@google.com>"
      ];
      dir(appPath, [pubspec(package)]).scheduleCreate();

      expectValidationWarning(pubspecField);
      run();
    });

    test('has no LICENSE file', () {
      file(join(appPath, 'LICENSE'), '').scheduleDelete();
      expectValidationError(license);
      run();
    });

    test('has an empty package name', () {
      dir(appPath, [libPubspec("", "1.0.0")]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a package name with an invalid character', () {
      dir(appPath, [libPubspec("test-pkg", "1.0.0")]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a package name that begins with a number', () {
      dir(appPath, [libPubspec("8ball", "1.0.0")]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a package name that contains upper-case letters', () {
      dir(appPath, [libPubspec("TestPkg", "1.0.0")]).scheduleCreate();
      expectValidationWarning(name);
      run();
    });

    test('has a package name that is a Dart reserved word', () {
      dir(appPath, [libPubspec("operator", "1.0.0")]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a library name with an invalid character', () {
      dir(appPath, [
        libPubspec("test_pkg", "1.0.0"),
        dir("lib", [file("test-pkg.dart", "int i = 0;")])
      ]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a library name that begins with a number', () {
      dir(appPath, [
        libPubspec("test_pkg", "1.0.0"),
        dir("lib", [file("8ball.dart", "int i = 0;")])
      ]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a library name that contains upper-case letters', () {
      dir(appPath, [
        libPubspec("test_pkg", "1.0.0"),
        dir("lib", [file("TestPkg.dart", "int i = 0;")])
      ]).scheduleCreate();
      expectValidationWarning(name);
      run();
    });

    test('has a library name that is a Dart reserved word', () {
      dir(appPath, [
        libPubspec("test_pkg", "1.0.0"),
        dir("lib", [file("operator.dart", "int i = 0;")])
      ]).scheduleCreate();
      expectValidationError(name);
      run();
    });

    test('has a single library named differently than the package', () {
      file(join(appPath, "lib", "test_pkg.dart"), '').scheduleDelete();
      dir(appPath, [
        dir("lib", [file("best_pkg.dart", "int i = 0;")])
      ]).scheduleCreate();
      expectValidationWarning(name);
      run();
    });

    test('has no lib directory', () {
      dir(join(appPath, "lib")).scheduleDelete();
      expectValidationError(lib);
      run();
    });

    test('has an empty lib directory', () {
      file(join(appPath, "lib", "test_pkg.dart"), '').scheduleDelete();
      expectValidationError(lib);
      run();
    });

    test('has a lib directory containing only src', () {
      file(join(appPath, "lib", "test_pkg.dart"), '').scheduleDelete();
      dir(appPath, [
        dir("lib", [
          dir("src", [file("test_pkg.dart", "int i = 0;")])
        ])
      ]).scheduleCreate();
      expectValidationError(lib);
      run();
    });
  });
}
