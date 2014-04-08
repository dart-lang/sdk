// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_transformers.test.assets_test;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:code_transformers/resolver.dart';
import 'package:code_transformers/tests.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

main() {
  useCompactVMConfiguration();

  Future checkDartEntry({Map<String, String> inputs, bool expectation}) {
    var transformer = new Validator((transform) {
      return isPossibleDartEntry(transform.primaryInput).then((value) {
        expect(value, expectation);
      });
    });
    return applyTransformers(
          [[transformer]],
          inputs: inputs);
  }

  group('isPossibleDartEntry', () {
    test('should handle empty files', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.dart': '',
          },
          expectation: false);
    });

    test('should detect main methods', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.dart': 'main() {}',
          },
          expectation: true);
    });

    test('should exclude dart mains in lib folder', () {
      return checkDartEntry(
          inputs: {
            'a|lib/main.dart': 'main() {}',
          },
          expectation: false);
    });

    test('should validate file extension', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.not_dart': 'main() {}',
          },
          expectation: false);
    });

    test('should count exports as main', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.dart': 'export "foo.dart";',
          },
          expectation: true);
    });

    test('should count parts as main', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.dart': 'part "foo.dart";',
          },
          expectation: true);
    });

    test('is tolerant of syntax errors with main', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.dart': 'main() {} {',
          },
          expectation: true);
    });

    test('is tolerant of syntax errors without main', () {
      return checkDartEntry(
          inputs: {
            'a|web/main.dart': 'class Foo {',
          },
          expectation: false);
    });
  });
}

class Validator extends Transformer {
  final Function validation;

  Validator(this.validation);

  Future apply(Transform transform) {
    return new Future.value(validation(transform));
  }
}
