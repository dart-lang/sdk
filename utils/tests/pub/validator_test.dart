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

Validator pubspecField(Entrypoint entrypoint) =>
  new PubspecFieldValidator(entrypoint);

main() {
  group('should consider a package valid if it', () {
    test('looks normal', () {
      dir(appPath, [libPubspec("test_pkg", "1.0.0")]).scheduleCreate();
      expectNoValidationError(pubspecField);
      run();
    });

    test('has "authors" instead of "author"', () {
      var package = package("test_pkg", "1.0.0");
      package["authors"] = [package.remove("author")];
      dir(appPath, [pubspec(package)]).scheduleCreate();
      expectNoValidationError(pubspecField);
      run();
    });
  });

  group('should consider a package invalid if it', () {
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
  });
}
