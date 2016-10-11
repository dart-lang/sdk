// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.closure_annotation_test;

import 'package:test/test.dart';

import 'package:dev_compiler/src/closure/closure_annotation.dart';
import 'package:dev_compiler/src/js_ast/js_ast.dart' show TypeRef, Identifier;

void main() {
  group('ClosureAnnotation', () {
    var anyType = new TypeRef.any();
    var unknownType = new TypeRef.unknown();
    var numberType = new TypeRef.number();
    var stringType = new TypeRef.string();
    var booleanType = new TypeRef.boolean();
    var fooType = new TypeRef.qualified(
        [new Identifier("foo"), new Identifier("Foo")]);
    var barType = new TypeRef.named("Bar");
    var bazType = new TypeRef.named("Baz");
    var bamType = new TypeRef.named("Bam");
    var batType = new TypeRef.named("Bat");

    test('gives empty comment when no has no meaningful info', () {
      expect(new ClosureAnnotation().toString(), "");
      expect(new ClosureAnnotation(type: anyType).toString(), "");
      expect(new ClosureAnnotation(type: unknownType).toString(), "");
    });

    test('gives single line comment when it fits', () {
      expect(new ClosureAnnotation(type: numberType).toString(),
          "/** @type {number} */");
      expect(new ClosureAnnotation(paramTypes: {'foo': anyType}).toString(),
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
          ' * @lends {Bat}\n'
          ' * @private @protected @final @const\n'
          ' * @constructor @struct @extends {Bar}\n'
          ' * @implements {Baz}\n'
          ' * @param {string} x\n'
          ' * @param {number} y\n'
          ' * @return {boolean}\n'
          ' * @throws {Bam}\n'
          ' */');
    });
  });
}
