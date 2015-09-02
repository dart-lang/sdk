// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.closure_annotation_test;

import 'package:test/test.dart';

import 'package:dev_compiler/src/closure/closure_annotation.dart';
import 'package:dev_compiler/src/closure/closure_type.dart';

void main() {
  group('ClosureAnnotation', () {
    var allType = new ClosureType.all();
    var unknownType = new ClosureType.unknown();
    var numberType = new ClosureType.number();
    var stringType = new ClosureType.string();
    var booleanType = new ClosureType.boolean();
    var fooType = new ClosureType.type("foo.Foo");
    var barType = new ClosureType.type("bar.Bar");
    var bazType = new ClosureType.type("baz.Baz");
    var bamType = new ClosureType.type("bam.Bam");
    var batType = new ClosureType.type("bat.Bat");

    test('gives empty comment when no has no meaningful info', () {
      expect(new ClosureAnnotation().toString(), "");
      expect(new ClosureAnnotation(type: allType).toString(), "");
      expect(new ClosureAnnotation(type: unknownType).toString(), "");
    });

    test('gives single line comment when it fits', () {
      expect(new ClosureAnnotation(type: numberType).toString(),
          "/** @type {number} */");
      expect(new ClosureAnnotation(paramTypes: {'foo': allType}).toString(),
          "/** @param {*} foo */");
      expect(new ClosureAnnotation(paramTypes: {'foo': unknownType}).toString(),
          "/** @param {?} foo */");
    });

    test('gives multiple line comment when it it does not fit on one line', () {
      expect(new ClosureAnnotation(
                  returnType: stringType, paramTypes: {'foo': numberType})
              .toString(),
          "/**\n"
          " * @param {number} foo\n"
          " * @return {string}\n"
          " */");
    });

    test('inserts indentation', () {
      expect(new ClosureAnnotation(
                  returnType: stringType, paramTypes: {'foo': numberType})
              .toString("  "),
          "/**\n" // No indent on first line.
          "   * @param {number} foo\n"
          "   * @return {string}\n"
          "   */");
    });

    test('compresses @type, @final, @const, @private, @protected, @typedef',
        () {
      expect(new ClosureAnnotation(type: stringType).toString(),
          "/** @type {string} */");
      expect(new ClosureAnnotation(type: stringType, isConst: true).toString(),
          "/** @const {string} */");
      expect(new ClosureAnnotation(type: stringType, isFinal: true).toString(),
          "/** @final {string} */");
      expect(
          new ClosureAnnotation(type: stringType, isPrivate: true).toString(),
          "/** @private {string} */");
      expect(
          new ClosureAnnotation(type: stringType, isTypedef: true).toString(),
          "/** @typedef {string} */");
      expect(
          new ClosureAnnotation(type: stringType, isProtected: true).toString(),
          "/** @protected {string} */");
      expect(new ClosureAnnotation(
              type: stringType,
              isPrivate: true,
              isConst: true,
              isFinal: true,
              isProtected: true,
              isTypedef: true).toString(),
          "/** @private @protected @final @const @typedef {string} */");
    });

    test('supports a full constructor annotation', () {
      expect(new ClosureAnnotation(
              returnType: booleanType,
              throwsType: bamType,
              thisType: fooType,
              superType: barType,
              lendsToType: batType,
              interfaces: [bazType],
              isStruct: true,
              isPrivate: true,
              isProtected: true,
              isOverride: true,
              isFinal: true,
              isConst: true,
              isConstructor: true,
              isNoSideEffects: true,
              isNoCollapse: true,
              paramTypes: {'x': stringType, 'y': numberType},
              templates: ['A', 'B']).toString(),
          '/**\n'
          ' * @template A, B\n'
          ' * @this {foo.Foo}\n'
          ' * @override\n'
          ' * @nosideeffects\n'
          ' * @nocollapse\n'
          ' * @lends {bat.Bat}\n'
          ' * @private @protected @final @const\n'
          ' * @constructor @struct @extends {bar.Bar}\n'
          ' * @implements {baz.Baz}\n'
          ' * @param {string} x\n'
          ' * @param {number} y\n'
          ' * @return {boolean}\n'
          ' * @throws {bam.Bam}\n'
          ' */');
    });
  });
}
