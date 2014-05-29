// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library smoke.test.codegen.generator_test;

import 'package:smoke/codegen/generator.dart';
import 'package:unittest/unittest.dart';

import 'common.dart' show checkResults;

main() {
  test('getters', () {
    var generator = new SmokeCodeGenerator();
    generator.addGetter('i');
    checkResults(generator, initCall:
        'useGeneratedCode(new StaticConfiguration(\n'
        '    checkedMode: false,\n'
        '    getters: {\n'
        '      #i: (o) => o.i,\n'
        '    }));\n');

    generator.addGetter('foo');
    checkResults(generator, initCall:
        'useGeneratedCode(new StaticConfiguration(\n'
        '    checkedMode: false,\n'
        '    getters: {\n'
        '      #foo: (o) => o.foo,\n'
        '      #i: (o) => o.i,\n'
        '    }));\n');
  });

  test('setters', () {
    var generator = new SmokeCodeGenerator();
    generator.addSetter('i');
    checkResults(generator, initCall:
        'useGeneratedCode(new StaticConfiguration(\n'
        '    checkedMode: false,\n'
        '    setters: {\n'
        '      #i: (o, v) { o.i = v; },\n'
        '    }));\n');

    generator.addSetter('foo');
    checkResults(generator, initCall:
        'useGeneratedCode(new StaticConfiguration(\n'
        '    checkedMode: false,\n'
        '    setters: {\n'
        '      #foo: (o, v) { o.foo = v; },\n'
        '      #i: (o, v) { o.i = v; },\n'
        '    }));\n');
  });

  test('names/symbols', () {
    var generator = new SmokeCodeGenerator();
    generator.addSymbol('i');
    generator.addSymbol('foo');
    generator.addSymbol('a.b.c');
    generator.addSymbol('a.b.[]');
    generator.addSymbol('[]');
    generator.addSymbol('+');
    checkResults(generator, initCall:
        'useGeneratedCode(new StaticConfiguration(\n'
        '    checkedMode: false,\n'
        '    names: {\n'
        '      const Symbol(\'+\'): r\'+\',\n'
        '      const Symbol(\'[]\'): r\'[]\',\n'
        '      const Symbol(\'a.b.[]\'): r\'a.b.[]\',\n'
        '      #a.b.c: r\'a.b.c\',\n'
        '      #foo: r\'foo\',\n'
        '      #i: r\'i\',\n'
        '    }));\n');
  });

  group('invalid symbols', () {
    var invalidError =
        predicate((e) => e is StateError && '$e'.contains("invalid symbol"));
    test('traling period', () {
      var generator = new SmokeCodeGenerator();
      generator.addSymbol('a.');
      var sb = new StringBuffer();
      expect(() => generator.writeInitCall(sb), throwsA(invalidError));
    });

    test('operator in the middle', () {
      var generator = new SmokeCodeGenerator();
      generator.addSymbol('a.[].b');
      var sb = new StringBuffer();
      expect(() => generator.writeInitCall(sb), throwsA(invalidError));
    });
  });

  test('getters, setters, and names', () {
    var generator = new SmokeCodeGenerator();
    generator.addGetter('i');
    generator.addSetter('i');
    generator.addSetter('foo');
    generator.addSymbol('foo');
    checkResults(generator, initCall:
        'useGeneratedCode(new StaticConfiguration(\n'
        '    checkedMode: false,\n'
        '    getters: {\n'
        '      #i: (o) => o.i,\n'
        '    },\n'
        '    setters: {\n'
        '      #foo: (o, v) { o.foo = v; },\n'
        '      #i: (o, v) { o.i = v; },\n'
        '    },\n'
        '    names: {\n'
        '      #foo: r\'foo\',\n'
        '    }));\n');
  });

  test('parents', () {
    var generator = new SmokeCodeGenerator();
    generator.addParent(new TypeIdentifier('a.dart', 'A'),
        new TypeIdentifier('b.dart', 'B'));
    generator.addParent(new TypeIdentifier('a.dart', 'C'),
        new TypeIdentifier('a.dart', 'A'));
    checkResults(generator,
        imports: [
          "import 'a.dart' as smoke_0;",
          "import 'b.dart' as smoke_1;"
        ],
        initCall:
          'useGeneratedCode(new StaticConfiguration(\n'
          '    checkedMode: false,\n'
          '    parents: {\n'
          '      smoke_0.A: smoke_1.B,\n'
          '      smoke_0.C: smoke_0.A,\n'
          '    }));\n');
  });

  test('declarations', () {
    var generator = new SmokeCodeGenerator();
    generator.addDeclaration(new TypeIdentifier('a.dart', 'A'), 'foo',
        new TypeIdentifier('dart:core', 'int'), isField: true, isFinal: true);
    generator.addDeclaration(new TypeIdentifier('a.dart', 'A'), 'bar',
        new TypeIdentifier('dart:core', 'Function'), isMethod: true,
        annotations: [new ConstExpression.constructor(null, 'Annotation',
          [new ConstExpression.string("hi")], const {})]);
    generator.addDeclaration(new TypeIdentifier('a.dart', 'A'), '[]',
        new TypeIdentifier('dart:core', 'Function'), isMethod: true);
    var symbol = "const Symbol('[]')";
    var details = "$symbol, Function, kind: METHOD";
    checkResults(generator,
        imports: ["import 'a.dart' as smoke_0;"],
        initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    declarations: {\n'
            '      smoke_0.A: {\n'
            '        $symbol: const Declaration($details),\n'
            '        #bar: const Declaration(#bar, Function, kind: METHOD, '
                           'annotations: const [const Annotation(\'hi\')]),\n'
            '        #foo: const Declaration(#foo, int, isFinal: true),\n'
            '      },\n'
            '    }));\n');
  });

  test('staticMethod', () {
    var generator = new SmokeCodeGenerator();
    generator.addStaticMethod(new TypeIdentifier('a.dart', 'A'), 'm1');
    checkResults(generator,
        imports: ["import 'a.dart' as smoke_0;"],
        initCall:
            'useGeneratedCode(new StaticConfiguration(\n'
            '    checkedMode: false,\n'
            '    staticMethods: {\n'
            '      smoke_0.A: {\n'
            '        #m1: smoke_0.A.m1,\n'
            '      },\n'
            '    }));\n');
  });

  test('repeated entries appear only once', () {
    var generator = new SmokeCodeGenerator();
    generator.addGetter('a');
    generator.addGetter('a');
    generator.addSetter('b');
    generator.addSetter('b');
    generator.addSymbol('d');
    generator.addSymbol('d');
    generator.addSymbol('c');
    generator.addSymbol('c');
    generator.addSymbol('c');

    generator.addParent(new TypeIdentifier('a.dart', 'C'),
        new TypeIdentifier('a.dart', 'A'));
    generator.addParent(new TypeIdentifier('a.dart', 'C'),
        new TypeIdentifier('a.dart', 'A'));
    generator.addParent(new TypeIdentifier('a.dart', 'C'),
        new TypeIdentifier('a.dart', 'A'));

    generator.addDeclaration(new TypeIdentifier('a.dart', 'A'), 'foo',
        new TypeIdentifier('dart:core', 'int'), isField: true, isFinal: true);
    generator.addDeclaration(new TypeIdentifier('a.dart', 'A'), 'foo',
        new TypeIdentifier('dart:core', 'int'), isField: true, isFinal: true);
    generator.addDeclaration(new TypeIdentifier('a.dart', 'A'), 'foo',
        new TypeIdentifier('dart:core', 'int'), isField: true, isFinal: true);

    checkResults(generator,
        imports: [
          "import 'a.dart' as smoke_0;",
        ],
        initCall:
          'useGeneratedCode(new StaticConfiguration(\n'
          '    checkedMode: false,\n'
          '    getters: {\n'
          '      #a: (o) => o.a,\n'
          '    },\n'
          '    setters: {\n'
          '      #b: (o, v) { o.b = v; },\n'
          '    },\n'
          '    parents: {\n'
          '      smoke_0.C: smoke_0.A,\n'
          '    },\n'
          '    declarations: {\n'
          '      smoke_0.A: {\n'
          '        #foo: const Declaration(#foo, int, isFinal: true),\n'
          '      },\n'
          '    },\n'
          '    names: {\n'
          '      #c: r\'c\',\n'
          '      #d: r\'d\',\n'
          '    }));\n');
  });
}
