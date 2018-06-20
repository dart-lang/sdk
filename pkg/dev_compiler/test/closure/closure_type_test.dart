// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.test.closure_type_test;

import 'package:test/test.dart';

import 'package:dev_compiler/src/closure/closure_type.dart';

void main() {
  expectToString(ClosureType t, String s,
      {String nullable, String nonNullable}) {
    expect(t.toString(), s);
    if (nullable != null) {
      expect(t.toNullable().toString(), nullable);
    }
    if (nonNullable != null) {
      expect(t.toNonNullable().toString(), nonNullable);
    }
  }

  group('ClosureType', () {
    test('supports simple types', () {
      expectToString(ClosureType.number(), "number",
          nullable: "?number", nonNullable: "number");
      expectToString(ClosureType.boolean(), "boolean",
          nullable: "?boolean", nonNullable: "boolean");
      expectToString(ClosureType.string(), "string",
          nullable: "string", nonNullable: "!string");
      expectToString(ClosureType.type("foo.Bar"), "foo.Bar",
          nullable: "foo.Bar", nonNullable: "!foo.Bar");
    });

    test('supports array types', () {
      expectToString(ClosureType.array(), "Array<*>",
          nullable: "Array<*>", nonNullable: "!Array<*>");
      expectToString(ClosureType.array(ClosureType.type("Foo")), "Array<Foo>",
          nullable: "Array<Foo>", nonNullable: "!Array<Foo>");
    });

    test('supports map types', () {
      expectToString(
          ClosureType.map(ClosureType.type("Foo"), ClosureType.type("Bar")),
          "Object<Foo, Bar>",
          nullable: "Object<Foo, Bar>",
          nonNullable: "!Object<Foo, Bar>");
      expectToString(ClosureType.map(), "Object<*, *>",
          nullable: "Object<*, *>", nonNullable: "!Object<*, *>");
    });

    test('supports function types', () {
      expectToString(ClosureType.function(), "Function",
          nullable: "Function", nonNullable: "!Function");
      expectToString(
          ClosureType.function([ClosureType.number()]), "function(number)");
      expectToString(ClosureType.function(null, ClosureType.number()),
          "function(...*):number");
      expectToString(
          ClosureType.function([ClosureType.number(), ClosureType.string()],
              ClosureType.boolean()),
          "function(number, string):boolean");
    });

    test('supports union types', () {
      expectToString(
          ClosureType.number().or(ClosureType.boolean()), "(number|boolean)");
      expectToString(ClosureType.number().orUndefined(), "(number|undefined)");
    });

    test('supports record types', () {
      expectToString(
          ClosureType.record(
              {'x': ClosureType.number(), 'y': ClosureType.boolean()}),
          "{x: number, y: boolean}");
    });

    test('supports optional pseudo-types', () {
      expectToString(ClosureType.number().toOptional(), "number=");
    });
  });
}
