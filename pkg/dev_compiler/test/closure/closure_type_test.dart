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
      expectToString(new ClosureType.number(), "number",
          nullable: "?number", nonNullable: "number");
      expectToString(new ClosureType.boolean(), "boolean",
          nullable: "?boolean", nonNullable: "boolean");
      expectToString(new ClosureType.string(), "string",
          nullable: "string", nonNullable: "!string");
      expectToString(new ClosureType.type("foo.Bar"), "foo.Bar",
          nullable: "foo.Bar", nonNullable: "!foo.Bar");
    });

    test('supports array types', () {
      expectToString(new ClosureType.array(), "Array<*>",
          nullable: "Array<*>", nonNullable: "!Array<*>");
      expectToString(
          new ClosureType.array(new ClosureType.type("Foo")), "Array<Foo>",
          nullable: "Array<Foo>", nonNullable: "!Array<Foo>");
    });

    test('supports map types', () {
      expectToString(new ClosureType.map(
              new ClosureType.type("Foo"), new ClosureType.type("Bar")),
          "Object<Foo, Bar>",
          nullable: "Object<Foo, Bar>", nonNullable: "!Object<Foo, Bar>");
      expectToString(new ClosureType.map(), "Object<*, *>",
          nullable: "Object<*, *>", nonNullable: "!Object<*, *>");
    });

    test('supports function types', () {
      expectToString(new ClosureType.function(), "Function",
          nullable: "Function", nonNullable: "!Function");
      expectToString(new ClosureType.function([new ClosureType.number()]),
          "function(number)");
      expectToString(new ClosureType.function(null, new ClosureType.number()),
          "function(...*):number");
      expectToString(new ClosureType.function([
        new ClosureType.number(),
        new ClosureType.string()
      ], new ClosureType.boolean()), "function(number, string):boolean");
    });

    test('supports union types', () {
      expectToString(new ClosureType.number().or(new ClosureType.boolean()),
          "(number|boolean)");
      expectToString(
          new ClosureType.number().orUndefined(), "(number|undefined)");
    });

    test('supports record types', () {
      expectToString(new ClosureType.record(
              {'x': new ClosureType.number(), 'y': new ClosureType.boolean()}),
          "{x: number, y: boolean}");
    });

    test('supports optional pseudo-types', () {
      expectToString(new ClosureType.number().toOptional(), "number=");
    });
  });
}
