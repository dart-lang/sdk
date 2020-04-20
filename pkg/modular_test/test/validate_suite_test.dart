// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit test for validation of modular steps in a pipeline.
import 'package:test/test.dart';
import 'package:modular_test/src/suite.dart';

main() {
  test('module test is not empty', () {
    expect(
        () => ModularTest([], null, []), throwsA(TypeMatcher<ArgumentError>()));

    var m = Module("a", [], Uri.parse("app:/"), []);
    expect(() => ModularTest([], m, []), throwsA(TypeMatcher<ArgumentError>()));
  });

  test('module test must have a main module', () {
    var m = Module("a", [], Uri.parse("app:/"), []);
    expect(() => ModularTest([m], null, []),
        throwsA(TypeMatcher<ArgumentError>()));
  });

  test('package must depend on package', () {
    var m1a = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isPackage: false);
    var m1b = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isPackage: true);

    var m2a = Module("b", [m1a], Uri.parse("app:/"),
        [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")],
        isPackage: true);
    var m2b = Module("b", [m1b], Uri.parse("app:/"),
        [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")],
        isPackage: true);
    expect(() => ModularTest([m1a, m2a], m2a, []),
        throwsA(TypeMatcher<InvalidModularTestError>()));
    expect(ModularTest([m1b, m2b], m2b, []), isNotNull);
  });

  test('shared module must depend on shared modules', () {
    var m1a = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isShared: false);
    var m1b = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isShared: true);

    var m2a = Module("b", [m1a], Uri.parse("app:/"),
        [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")],
        isShared: true);
    var m2b = Module("b", [m1b], Uri.parse("app:/"),
        [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")],
        isShared: true);
    expect(() => ModularTest([m1a, m2a], m2a, []),
        throwsA(TypeMatcher<InvalidModularTestError>()));
    expect(ModularTest([m1b, m2b], m2b, []), isNotNull);
  });

  test('sdk module must not have dependencies', () {
    var m1a = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isSdk: false);
    var m1b = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isSdk: true);

    var m2a = Module("b", [m1a], Uri.parse("app:/"),
        [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")],
        isSdk: true);
    var m2b = Module("b", [m1b], Uri.parse("app:/"),
        [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")],
        isSdk: true);
    expect(() => ModularTest([m1a, m2a], m2a, []),
        throwsA(TypeMatcher<InvalidModularTestError>()));
    expect(() => ModularTest([m1b, m2b], m2b, []),
        throwsA(TypeMatcher<InvalidModularTestError>()));
  });

  test('sdk module cannot be package module', () {
    var m = Module("a", const [], Uri.parse("app:/"),
        [Uri.parse("a1.dart"), Uri.parse("a2.dart")],
        isSdk: true);
    expect(ModularTest([m], m, []), isNotNull);

    m.isPackage = true;
    expect(() => ModularTest([m], m, []),
        throwsA(TypeMatcher<InvalidModularTestError>()));
  });
}
