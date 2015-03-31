// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.semantics_visitor_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/dart2jslib.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/resolution/resolution.dart';
import 'package:compiler/src/resolution/semantic_visitor.dart';
import 'package:compiler/src/resolution/operators.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/util/util.dart';
import 'memory_compiler.dart';

class Visit {
  final VisitKind method;
  final element;
  final rhs;
  final arguments;
  final receiver;
  final name;
  final expression;
  final left;
  final right;
  final type;
  final operator;
  final index;
  final getter;
  final setter;
  final constant;
  final selector;
  final parameters;
  final body;
  final target;
  final targetType;
  final initializers;

  const Visit(this.method,
              {this.element,
               this.rhs,
               this.arguments,
               this.receiver,
               this.name,
               this.expression,
               this.left,
               this.right,
               this.type,
               this.operator,
               this.index,
               this.getter,
               this.setter,
               this.constant,
               this.selector,
               this.parameters,
               this.body,
               this.target,
               this.targetType,
               this.initializers});

  int get hashCode => toString().hashCode;

  bool operator ==(other) => '$this' == '$other';

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('method=$method');
    if (element != null) {
      sb.write(',element=$element');
    }
    if (rhs != null) {
      sb.write(',rhs=$rhs');
    }
    if (arguments != null) {
      sb.write(',arguments=$arguments');
    }
    if (receiver != null) {
      sb.write(',receiver=$receiver');
    }
    if (name != null) {
      sb.write(',name=$name');
    }
    if (expression != null) {
      sb.write(',expression=$expression');
    }
    if (left != null) {
      sb.write(',left=$left');
    }
    if (right != null) {
      sb.write(',right=$right');
    }
    if (type != null) {
      sb.write(',type=$type');
    }
    if (operator != null) {
      sb.write(',operator=$operator');
    }
    if (index != null) {
      sb.write(',index=$index');
    }
    if (getter != null) {
      sb.write(',getter=$getter');
    }
    if (setter != null) {
      sb.write(',setter=$setter');
    }
    if (constant != null) {
      sb.write(',constant=$constant');
    }
    if (selector != null) {
      sb.write(',selector=$selector');
    }
    if (parameters != null) {
      sb.write(',parameters=$parameters');
    }
    if (body != null) {
      sb.write(',body=$body');
    }
    if (target != null) {
      sb.write(',target=$target');
    }
    if (targetType != null) {
      sb.write(',targetType=$targetType');
    }
    if (initializers != null) {
      sb.write(',initializers=$initializers');
    }
    return sb.toString();
  }
}

class Test {
  final String codeByPrefix;
  final String code;
  final /*Visit | List<Visit>*/ expectedVisits;
  final String cls;
  final String method;

  const Test(this.code, this.expectedVisits)
      : cls = null, method = 'm', codeByPrefix = null;
  const Test.clazz(this.code, this.expectedVisits,
                   {this.cls: 'C', this.method: 'm'})
      : codeByPrefix = null;
  const Test.prefix(this.codeByPrefix, this.code, this.expectedVisits)
      : cls = null, method = 'm';

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.writeln();
    sb.writeln(code);
    if (codeByPrefix != null) {
      sb.writeln('imported by prefix:');
      sb.writeln(codeByPrefix);
    }
    return sb.toString();
  }
}

const Map<String, List<Test>> SEND_TESTS = const {
  'Parameters': const [
    // Parameters
    const Test('m(o) => o;',
        const Visit(VisitKind.VISIT_PARAMETER_GET,
                    element: 'parameter(m#o)')),
    const Test('m(o) { o = 42; }',
        const Visit(VisitKind.VISIT_PARAMETER_SET,
                    element: 'parameter(m#o)',
                    rhs:'42')),
    const Test('m(o) { o(null, 42); }',
        const Visit(VisitKind.VISIT_PARAMETER_INVOKE,
                    element: 'parameter(m#o)',
                    arguments: '(null,42)',
                    selector: 'Selector(call, call, arity=2)')),
  ],
  'Local variables': const [
    // Local variables
    const Test('m() { var o; return o; }',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_GET,
                    element: 'variable(m#o)')),
    const Test('m() { var o; o = 42; }',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_SET,
                    element: 'variable(m#o)',
                    rhs:'42')),
    const Test('m() { var o; o(null, 42); }',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_INVOKE,
                    element: 'variable(m#o)',
                    arguments: '(null,42)',
                    selector: 'Selector(call, call, arity=2)')),
  ],
  'Local functions': const [
    // Local functions
    const Test('m() { o(a, b) {}; return o; }',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_GET,
                    element: 'function(m#o)')),
    const Test('m() { o(a, b) {}; o(null, 42); }',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_INVOKE,
                    element: 'function(m#o)',
                    arguments: '(null,42)',
                    selector: 'Selector(call, call, arity=2)')),
  ],
  'Static fields': const [
    // Static fields
    const Test(
        '''
        class C { static var o; }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET,
                    element: 'field(C#o)')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET,
                    element: 'field(C#o)')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET,
                    element: 'field(C#o)')),
    const Test.prefix(
        '''
        class C {
          static var o;
        }
        ''',
        'm() => p.C.o;',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET,
                    element: 'field(C#o)')),
    const Test(
        '''
        class C { static var o; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
                    element: 'field(C#o)',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
                    element: 'field(C#o)',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
                    element: 'field(C#o)',
                    rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static var o;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
                    element: 'field(C#o)',
                    rhs: '42')),
    const Test(
        '''
        class C { static var o; }
        m() { C.o(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
                    element: 'field(C#o)',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
                    element: 'field(C#o)',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
                    element: 'field(C#o)',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static var o;
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
                    element: 'field(C#o)',
                    arguments: '(null,42)')),
  ],
  'Static properties': const [
    // Static properties
    const Test(
        '''
        class C {
          static get o => null;
        }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET,
                    element: 'getter(C#o)')),
    const Test.clazz(
        '''
        class C {
          static get o => null;
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET,
                    element: 'getter(C#o)')),
    const Test.clazz(
        '''
        class C {
          static get o => null;
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET,
                    element: 'getter(C#o)')),
    const Test.prefix(
        '''
        class C {
          static get o => null;
        }
        ''',
        'm() => p.C.o;',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET,
                    element: 'getter(C#o)')),
    const Test(
        '''
        class C { static set o(_) {} }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
                    element: 'setter(C#o)',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
                    element: 'setter(C#o)',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
                    element: 'setter(C#o)',
                    rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static set o(_) {}
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
                    element: 'setter(C#o)',
                    rhs: '42')),
    const Test(
        '''
        class C { static get o => null; }
        m() => C.o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
                    element: 'getter(C#o)',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static get o => null;
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
                    element: 'getter(C#o)',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static get o => null;
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
                    element: 'getter(C#o)',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static get o => null;
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
                    element: 'getter(C#o)',
                    arguments: '(null,42)')),
  ],
  'Static functions': const [
    // Static functions
    const Test(
        '''
        class C { static o(a, b) {} }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_GET,
                    element: 'function(C#o)')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_GET,
                    element: 'function(C#o)')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_GET,
                    element: 'function(C#o)')),
    const Test.prefix(
        '''
        class C { static o(a, b) {} }
        ''',
        '''
        m() => p.C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_GET,
                    element: 'function(C#o)')),
    const Test(
        '''
        class C { static o(a, b) {} }
        m() => C.o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
                    element: 'function(C#o)',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
                    element: 'function(C#o)',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
                    element: 'function(C#o)',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static o(a, b) {}
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
                    element: 'function(C#o)',
                    arguments: '(null,42)')),
  ],
  'Top level fields': const [
    // Top level fields
    const Test(
        '''
        var o;
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET,
                    element: 'field(o)')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() => p.o;',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET,
                    element: 'field(o)')),
    const Test(
        '''
        var o;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET,
                    element: 'field(o)',
                    rhs: '42')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET,
                    element: 'field(o)',
                    rhs: '42')),
    const Test(
        '''
        var o;
        m() { o(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_INVOKE,
                    element: 'field(o)',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_INVOKE,
                    element: 'field(o)',
                    arguments: '(null,42)')),
  ],
  'Top level properties': const [
    // Top level properties
    const Test(
        '''
        get o => null;
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_GET,
                    element: 'getter(o)')),
    const Test.prefix(
        '''
        get o => null;
        ''',
        '''
        m() => p.o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_GET,
                    element: 'getter(o)')),
    const Test(
        '''
        set o(_) {}
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
                    element: 'setter(o)',
                    rhs: '42')),
    const Test.prefix(
        '''
        set o(_) {}
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
                    element: 'setter(o)',
                    rhs: '42')),
    const Test(
        '''
        get o => null;
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
                    element: 'getter(o)',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        get o => null;
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
                    element: 'getter(o)',
                    arguments: '(null,42)')),
  ],
  'Top level functions': const [
    // Top level functions
    const Test(
        '''
        o(a, b) {}
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_GET,
                    element: 'function(o)')),
    const Test(
        '''
        o(a, b) {}
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
                    element: 'function(o)',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        o(a, b) {}
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
                    element: 'function(o)',
                    arguments: '(null,42)')),
  ],
  'Dynamic properties': const [
    // Dynamic properties
    const Test('m(o) => o.foo;',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
                      receiver: 'o',
                      name: 'foo'),
          const Visit(VisitKind.VISIT_PARAMETER_GET,
                      element: 'parameter(m#o)'),
        ]),
    const Test('m(o) { o.foo = 42; }',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_SET,
                      receiver: 'o',
                      name: 'foo',
                      rhs: '42'),
          const Visit(VisitKind.VISIT_PARAMETER_GET,
                      element: 'parameter(m#o)'),
        ]),
    const Test('m(o) { o.foo(null, 42); }',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_INVOKE,
                      receiver: 'o',
                      name: 'foo',
                      arguments: '(null,42)'),
          const Visit(VisitKind.VISIT_PARAMETER_GET,
                      element: 'parameter(m#o)'),
        ]),
  ],
  'This access': const [
    // This access
    const Test.clazz(
        '''
        class C {
          m() => this;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_GET)),
    const Test.clazz(
        '''
        class C {
          call(a, b) {}
          m() { this(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_INVOKE,
                    arguments: '(null,42)')),
  ],
  'This properties': const [
    // This properties
    const Test.clazz(
        '''
        class C {
          var foo;
          m() => foo;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_GET,
                    name: 'foo')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() => this.foo;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_GET,
                    name: 'foo')),
    const Test.clazz(
        '''
        class C {
          get foo => null;
          m() => foo;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_GET,
                    name: 'foo')),
    const Test.clazz(
        '''
        class C {
          get foo => null;
          m() => this.foo;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_GET,
                    name: 'foo')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() { foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET,
                    name: 'foo',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() { this.foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET,
                    name: 'foo',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          set foo(_) {}
          m() { foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET,
                    name: 'foo',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          set foo(_) {}
          m() { this.foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET,
                    name: 'foo',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() { foo(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_INVOKE,
                    name: 'foo',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() { this.foo(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_INVOKE,
                    name: 'foo',
                    arguments: '(null,42)')),
  ],
  'Super fields': const [
    // Super fields
    const Test.clazz(
        '''
        class B {
          var o;
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_GET,
                    element: 'field(B#o)')),
    const Test.clazz(
        '''
        class B {
          var o;
        }
        class C extends B {
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_SET,
                    element: 'field(B#o)',
                    rhs: '42')),
    const Test.clazz(
        '''
        class B {
          var o;
        }
        class C extends B {
          m() { super.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_INVOKE,
                    element: 'field(B#o)',
                    arguments: '(null,42)')),
  ],
  'Super properties': const [
    // Super properties
    const Test.clazz(
        '''
        class B {
          get o => null;
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_GET,
                    element: 'getter(B#o)')),
    const Test.clazz(
        '''
        class B {
          set o(_) {}
        }
        class C extends B {
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_SETTER_SET,
                    element: 'setter(B#o)',
                    rhs: '42')),
    const Test.clazz(
        '''
        class B {
          get o => null;
        }
        class C extends B {
          m() { super.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_INVOKE,
                    element: 'getter(B#o)',
                    arguments: '(null,42)')),
  ],
  'Super methods': const [
    // Super methods
    const Test.clazz(
        '''
        class B {
          o(a, b) {}
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_GET,
                    element: 'function(B#o)')),
    const Test.clazz(
        '''
        class B {
          o(a, b) {}
        }
        class C extends B {
          m() { super.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_INVOKE,
                    element: 'function(B#o)',
                    arguments: '(null,42)')),
  ],
  'Expression invoke': const [
    // Expression invoke
    const Test('m() => (a, b){}(null, 42);',
        const Visit(VisitKind.VISIT_EXPRESSION_INVOKE,
                    receiver: '(a,b){}',
                    arguments: '(null,42)')),
  ],
  'Class type literals': const [
    // Class type literals
    const Test(
        '''
        class C {}
        m() => C;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_GET,
                    constant: 'C')),
    const Test(
        '''
        class C {}
        m() => C(null, 42);
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
                    constant: 'C',
                    arguments: '(null,42)')),
  ],
  'Typedef type literals': const [
    // Typedef type literals
    const Test(
        '''
        typedef F();
        m() => F;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_GET,
                    constant: 'F')),
    const Test(
        '''
        typedef F();
        m() => F(null, 42);
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
                    constant: 'F',
                    arguments: '(null,42)')),
  ],
  'Type variable type literals': const [
    // Type variable type literals
    const Test.clazz(
        '''
        class C<T> {
          m() => T;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_GET,
                    element: 'type_variable(C#T)')),
    const Test.clazz(
        '''
        class C<T> {
          m() => T(null, 42);
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
                    element: 'type_variable(C#T)',
                    arguments: '(null,42)')),

  ],
  'Dynamic type literals': const [
    // Dynamic type literals
    const Test(
        '''
        m() => dynamic;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_GET,
                    constant: 'dynamic')),
    // TODO(johnniwinther): Enable this when we pass the right constant.
    // Currently we generated the constant for `Type` instead of `dynamic`.
    /*const Test(
        '''
        m() { dynamic(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
                    constant: 'dynamic',
                    arguments: '(null,42)')),*/
  ],
  'Assert': const [
    // Assert
    const Test(
        '''
        m() { assert(false); }
        ''',
        const Visit(VisitKind.VISIT_ASSERT, expression: 'false')),
  ],
  'Logical and': const [
    // Logical and
    const Test(
        '''
        m() => true && false;
        ''',
        const Visit(VisitKind.VISIT_LOGICAL_AND, left: 'true', right: 'false')),
  ],
  'Logical or': const [
    // Logical or
    const Test(
        '''
        m() => true || false;
        ''',
        const Visit(VisitKind.VISIT_LOGICAL_OR, left: 'true', right: 'false')),
  ],
  'Is test': const [
    // Is test
    const Test(
        '''
        class C {}
        m() => 0 is C;
        ''',
        const Visit(VisitKind.VISIT_IS, expression: '0', type: 'C')),
  ],
  'Is not test': const [
    // Is not test
    const Test(
        '''
        class C {}
        m() => 0 is! C;
        ''',
        const Visit(VisitKind.VISIT_IS_NOT, expression: '0', type: 'C')),
  ],
  'As test': const [
    // As test
    const Test(
        '''
        class C {}
        m() => 0 as C;
        ''',
        const Visit(VisitKind.VISIT_AS, expression: '0', type: 'C')),
  ],
  'Binary operators': const [
    // Binary operators
    const Test(
        '''
        m() => 2 + 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '+', right: '3')),
    const Test(
        '''
        m() => 2 - 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '-', right: '3')),
    const Test(
        '''
        m() => 2 * 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '*', right: '3')),
    const Test(
        '''
        m() => 2 / 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '/', right: '3')),
    const Test(
        '''
        m() => 2 ~/ 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '~/', right: '3')),
    const Test(
        '''
        m() => 2 % 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '%', right: '3')),
    const Test(
        '''
        m() => 2 << 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '<<', right: '3')),
    const Test(
        '''
        m() => 2 >> 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '>>', right: '3')),
    const Test(
        '''
        m() => 2 <= 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '<=', right: '3')),
    const Test(
        '''
        m() => 2 < 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '<', right: '3')),
    const Test(
        '''
        m() => 2 >= 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '>=', right: '3')),
    const Test(
        '''
        m() => 2 > 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '>', right: '3')),
    const Test(
        '''
        m() => 2 & 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '&', right: '3')),
    const Test(
        '''
        m() => 2 | 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '|', right: '3')),
    const Test(
        '''
        m() => 2 ^ 3;
        ''',
        const Visit(VisitKind.VISIT_BINARY,
                    left: '2', operator: '^', right: '3')),
    const Test.clazz(
        '''
        class B {
          operator +(_) => null;
        }
        class C extends B {
          m() => super + 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_BINARY,
                    element: 'function(B#+)',
                    operator: '+',
                    right: '42')),
  ],
  'Index': const [
    // Index
    const Test(
        '''
        m() => 2[3];
        ''',
        const Visit(VisitKind.VISIT_INDEX,
                    receiver: '2', index: '3')),
    const Test(
        '''
        m() => --2[3];
        ''',
        const Visit(VisitKind.VISIT_INDEX_PREFIX,
                    receiver: '2', index: '3', operator: '--')),
    const Test(
        '''
        m() => 2[3]++;
        ''',
        const Visit(VisitKind.VISIT_INDEX_POSTFIX,
                    receiver: '2', index: '3', operator: '++')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
        }
        class C extends B {
          m() => super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_INDEX,
                    element: 'function(B#[])',
                    index: '42')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
          operator []=(a, b) {}
        }
        class C extends B {
          m() => ++super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_INDEX_PREFIX,
                    getter: 'function(B#[])',
                    setter: 'function(B#[]=)',
                    index: '42',
                    operator: '++')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[42]--;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_INDEX_POSTFIX,
                    getter: 'function(B#[])',
                    setter: 'function(B#[]=)',
                    index: '42',
                    operator: '--')),
  ],
  'Equals': const [
    // Equals
    const Test(
        '''
        m() => 2 == 3;
        ''',
        const Visit(VisitKind.VISIT_EQUALS,
                    left: '2', right: '3')),
    const Test.clazz(
        '''
        class B {
          operator ==(_) => null;
        }
        class C extends B {
          m() => super == 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_EQUALS,
                    element: 'function(B#==)',
                    right: '42')),
  ],
  'Not equals': const [
    // Not equals
    const Test(
        '''
        m() => 2 != 3;
        ''',
        const Visit(VisitKind.VISIT_NOT_EQUALS,
                    left: '2', right: '3')),
    // TODO(johnniwinther): Enable this. Resolution does not store the element.
    /*const Test.clazz(
        '''
        class B {
          operator ==(_) => null;
        }
        class C extends B {
          m() => super != 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_NOT_EQUALS,
                    element: 'function(B#==)',
                    right: '42')),*/
  ],
  'Unary expression': const [
    // Unary expression
    const Test(
        '''
        m() => -false;
        ''',
        const Visit(VisitKind.VISIT_UNARY,
                    expression: 'false', operator: '-')),
    const Test(
        '''
        m() => ~false;
        ''',
        const Visit(VisitKind.VISIT_UNARY,
                    expression: 'false', operator: '~')),
    const Test.clazz(
        '''
        class B {
          operator -() => null;
        }
        class C extends B {
          m() => -super;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_UNARY,
                    element: 'function(B#unary-)', operator: '-')),
    const Test.clazz(
        '''
        class B {
          operator ~() => null;
        }
        class C extends B {
          m() => ~super;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_UNARY,
                    element: 'function(B#~)', operator: '~')),
    const Test(
        '''
        m() => !0;
        ''',
        const Visit(VisitKind.VISIT_NOT, expression: '0')),
  ],
  'Index set': const [
    // Index set
    const Test(
        '''
        m() => 0[1] = 2;
        ''',
        const Visit(VisitKind.VISIT_INDEX_SET,
            receiver: '0', index: '1', rhs: '2')),
    const Test.clazz(
        '''
        class B {
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[1] = 2;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_INDEX_SET,
            element: 'function(B#[]=)', index: '1', rhs: '2')),
  ],
  'Compound assignment': const [
    // Compound assignment
    const Test(
        '''
        m(a) => a.b += 42;
        ''',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_COMPOUND,
              receiver: 'a', operator: '+=', rhs: '42',
              getter: 'Selector(getter, b, arity=0)',
              setter: 'Selector(setter, b, arity=1)'),
          const Visit(VisitKind.VISIT_PARAMETER_GET,
              element: 'parameter(m#a)')
        ]),
    // TODO(johnniwinther): Enable this when type literals are recognized in
    // SendSet.
    /*const Test(
        '''
        class C {}
        m(a) => C += 42;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_COMPOUND,
            constant: 'C', operator: '+=', rhs: '42')),
    const Test(
        '''
        typedef F();
        m(a) => F += 42;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
            constant: 'F', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          m(a) => T += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
            element: 'type_variable(C#T)', operator: '+=', rhs: '42')),
    const Test(
        '''
        m(a) => dynamic += 42;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
            constant: 'dynamic',
            operator: '+=', rhs: '42')),*/
    const Test(
        '''
        m(a) => a += 42;
        ''',
        const Visit(VisitKind.VISIT_PARAMETER_COMPOUND,
            element: 'parameter(m#a)', operator: '+=', rhs: '42')),
    const Test(
        '''
        m() {
          var a;
          a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_COMPOUND,
            element: 'variable(m#a)', operator: '+=', rhs: '42')),
    const Test(
        '''
        var a;
        m() => a += 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_COMPOUND,
            element: 'field(a)', operator: '+=', rhs: '42')),
    const Test(
        '''
        get a => 0;
        set a(_) {}
        m() => a += 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_COMPOUND,
            getter: 'getter(a)', setter: 'setter(a)',
            operator: '+=', rhs: '42')),
    const Test(
        '''
        class C {
          static var a;
        }
        m() => C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_COMPOUND,
            element: 'field(C#a)', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => C.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_COMPOUND,
            element: 'field(C#a)', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_COMPOUND,
            element: 'field(C#a)', operator: '+=', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static var a;
        }
        ''',
        '''
        m() => p.C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_COMPOUND,
            element: 'field(C#a)', operator: '+=', rhs: '42')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => C.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        ''',
        '''
        m() => p.C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    // TODO(johnniwinther): Enable these when dart2js supports method and setter
    // with the same name.
    /*const Test(
        '''
        class C {
          static a() {}
          static set a(_) {}
        }
        m() => C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static a() {}
          static set a(_) {}
          m() => C.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static a() {}
          static set a(_) {}
          m() => a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static a() {}
          static set a(_) {}
        }
        ''',
        '''
        m() => p.C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            operator: '+=', rhs: '42')),*/
    const Test.clazz(
        '''
        class C {
          var a;
          m() => a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_COMPOUND,
            operator: '+=', rhs: '42',
            getter: 'Selector(getter, a, arity=0)',
            setter: 'Selector(setter, a, arity=1)')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => this.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_COMPOUND,
            operator: '+=', rhs: '42',
            getter: 'Selector(getter, a, arity=0)',
            setter: 'Selector(setter, a, arity=1)')),
    const Test.clazz(
        '''
        class B {
          var a = 0;
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_COMPOUND,
            element: 'field(B#a)', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          get a => 0;
          set a (_) {}
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_COMPOUND,
            getter: 'getter(B#a)', setter: 'setter(B#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          get a => 0;
        }
        class B extends A {
          set a (_) {}
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_COMPOUND,
            getter: 'getter(A#a)', setter: 'setter(B#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          get a => 0;
        }

        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_COMPOUND,
            getter: 'getter(B#a)', setter: 'field(A#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          set a(_) {}
        }

        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_COMPOUND,
            getter: 'field(A#a)', setter: 'setter(B#a)',
            operator: '+=', rhs: '42')),
    // TODO(johnniwinther): Enable this when dart2js supports shadow setters.
    /*const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          final a;
        }

        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_COMPOUND,
            getter: 'field(B#a)', setter: 'field(A#a)',
            operator: '+=', rhs: '42')),*/
  ],
  'Compound index assignment': const [
    // Compound index assignment
    const Test(
        '''
        m() => 0[1] += 42;
        ''',
        const Visit(VisitKind.VISIT_COMPOUND_INDEX_SET,
            receiver: '0', index: '1', operator: '+=', rhs: '42')),
    // TODO(johnniwinther): Enable this when the getter element is stored.
    /*const Test.clazz(
        '''
        class B {
          operator [](_) {}
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[1] += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_COMPOUND_INDEX_SET,
            getter: 'function(B#[])', setter: 'function(B#[]=)',
            index: '1', operator: '+=', rhs: '42')),*/
  ],
  'Prefix expression': const [
    // Prefix expression
    const Test(
        '''
        m(a) => --a.b;
        ''',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_PREFIX,
              receiver: 'a', operator: '--',
              getter: 'Selector(getter, b, arity=0)',
              setter: 'Selector(setter, b, arity=1)'),
          const Visit(VisitKind.VISIT_PARAMETER_GET,
              element: 'parameter(m#a)')
        ]),
    const Test(
        '''
        m(a) => ++a;
        ''',
        const Visit(VisitKind.VISIT_PARAMETER_PREFIX,
            element: 'parameter(m#a)', operator: '++')),
    const Test(
        '''
        m() {
          var a;
          --a;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_PREFIX,
            element: 'variable(m#a)', operator: '--')),
    const Test(
        '''
        var a;
        m() => ++a;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_PREFIX,
            element: 'field(a)', operator: '++')),
    const Test(
        '''
        get a => 0;
        set a(_) {}
        m() => --a;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_PREFIX,
            getter: 'getter(a)', setter: 'setter(a)',
            operator: '--')),
    const Test(
        '''
        class C {
          static var a;
        }
        m() => ++C.a;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_PREFIX,
            element: 'field(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => ++C.a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_PREFIX,
            element: 'field(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => --a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_PREFIX,
            element: 'field(C#a)', operator: '--')),
    const Test.prefix(
        '''
        class C {
          static var a;
        }
        ''',
        '''
        m() => --p.C.a;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_PREFIX,
            element: 'field(C#a)', operator: '--')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => ++C.a;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => --C.a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '--')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => --a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '--')),
    const Test.prefix(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        ''',
        '''
        m() => ++p.C.a;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class C {
          var a;
          m() => --a;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_PREFIX,
            operator: '--',
            getter: 'Selector(getter, a, arity=0)',
            setter: 'Selector(setter, a, arity=1)')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => ++this.a;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_PREFIX,
            operator: '++',
            getter: 'Selector(getter, a, arity=0)',
            setter: 'Selector(setter, a, arity=1)')),
    const Test.clazz(
        '''
        class B {
          var a = 0;
        }
        class C extends B {
          m() => --super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_PREFIX,
            element: 'field(B#a)', operator: '--')),
    const Test.clazz(
        '''
        class B {
          get a => 0;
          set a (_) {}
        }
        class C extends B {
          m() => --super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_PREFIX,
            getter: 'getter(B#a)', setter: 'setter(B#a)',
            operator: '--')),
    const Test.clazz(
        '''
        class A {
          get a => 0;
        }
        class B extends A {
          set a (_) {}
        }
        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_PREFIX,
            getter: 'getter(A#a)', setter: 'setter(B#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          get a => 0;
        }

        class C extends B {
          m() => --super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_PREFIX,
            getter: 'getter(B#a)', setter: 'field(A#a)',
            operator: '--')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          set a(_) {}
        }

        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_PREFIX,
            getter: 'field(A#a)', setter: 'setter(B#a)',
            operator: '++')),
  ],
  'Postfix expression': const [
    // Postfix expression
    const Test(
        '''
        m(a) => a.b--;
        ''',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_POSTFIX,
              receiver: 'a', operator: '--',
              getter: 'Selector(getter, b, arity=0)',
              setter: 'Selector(setter, b, arity=1)'),
          const Visit(VisitKind.VISIT_PARAMETER_GET,
              element: 'parameter(m#a)')
        ]),
    const Test(
        '''
        m(a) => a++;
        ''',
        const Visit(VisitKind.VISIT_PARAMETER_POSTFIX,
            element: 'parameter(m#a)', operator: '++')),
    const Test(
        '''
        m() {
          var a;
          a--;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_POSTFIX,
            element: 'variable(m#a)', operator: '--')),
    const Test(
        '''
        var a;
        m() => a++;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_POSTFIX,
            element: 'field(a)', operator: '++')),
    const Test(
        '''
        get a => 0;
        set a(_) {}
        m() => a--;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_POSTFIX,
            getter: 'getter(a)', setter: 'setter(a)',
            operator: '--')),
    const Test(
        '''
        class C {
          static var a;
        }
        m() => C.a++;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_POSTFIX,
            element: 'field(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => C.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_POSTFIX,
            element: 'field(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => a--;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_POSTFIX,
            element: 'field(C#a)', operator: '--')),
    const Test.prefix(
        '''
        class C {
          static var a;
        }
        ''',
        '''
        m() => p.C.a--;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_POSTFIX,
            element: 'field(C#a)', operator: '--')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => C.a++;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => C.a--;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '--')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => a--;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '--')),
    const Test.prefix(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        ''',
        '''
        m() => p.C.a++;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class C {
          var a;
          m() => a--;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_POSTFIX,
            operator: '--',
            getter: 'Selector(getter, a, arity=0)',
            setter: 'Selector(setter, a, arity=1)')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => this.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_POSTFIX,
            operator: '++',
            getter: 'Selector(getter, a, arity=0)',
            setter: 'Selector(setter, a, arity=1)')),
    const Test.clazz(
        '''
        class B {
          var a = 0;
        }
        class C extends B {
          m() => super.a--;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_POSTFIX,
            element: 'field(B#a)', operator: '--')),
    const Test.clazz(
        '''
        class B {
          get a => 0;
          set a (_) {}
        }
        class C extends B {
          m() => super.a--;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_POSTFIX,
            getter: 'getter(B#a)', setter: 'setter(B#a)',
            operator: '--')),
    const Test.clazz(
        '''
        class A {
          get a => 0;
        }
        class B extends A {
          set a (_) {}
        }
        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_POSTFIX,
            getter: 'getter(A#a)', setter: 'setter(B#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          get a => 0;
        }

        class C extends B {
          m() => super.a--;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_POSTFIX,
            getter: 'getter(B#a)', setter: 'field(A#a)',
            operator: '--')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          set a(_) {}
        }

        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_POSTFIX,
            getter: 'field(A#a)', setter: 'setter(B#a)',
            operator: '++')),
  ],
  'Constructor invocations': const [
    const Test(
        '''
        class Class {
          const Class(a, b);
        }
        m() => const Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_CONST_CONSTRUCTOR_INVOKE,
            constant: 'const Class(true, 42)')),
    const Test(
        '''
        class Class {}
        m() => new Class();
        ''',
        const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(Class#)',
            arguments: '()',
            type: 'Class',
            selector: 'Selector(call, , arity=0)')),
    const Test(
        '''
        class Class {
          Class(a, b);
        }
        m() => new Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        class Class {
          Class.named(a, b);
        }
        m() => new Class.named(true, 42);
        ''',
        const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(Class#named)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, named, arity=2)')),
    const Test(
        '''
        class Class {
          Class(a, b) : this._(a, b);
          Class._(a, b);
        }
        m() => new Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) => new Class._(a, b);
          Class._(a, b);
        }
        m() => new Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        class Class<T> {
          factory Class(a, b) = Class<int>.a;
          factory Class.a(a, b) = Class<Class<T>>.b;
          Class.b(a, b);
        }
        m() => new Class<double>(true, 42);
        ''',
        const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class<double>',
            target: 'generative_constructor(Class#b)',
            targetType: 'Class<Class<int>>',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        class Class {
          Class(a, b);
        }
        m() => new Class.unresolved(true, 42);
        ''',
        const Visit(
            VisitKind.ERROR_UNRESOLVED_CONSTRUCTOR_INVOKE,
            arguments: '(true,42)')),
    const Test(
        '''
        m() => new Unresolved(true, 42);
        ''',
        const Visit(
            // TODO(johnniwinther): Update this to
            // `VisitKind.ERROR_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE`.
            VisitKind.ERROR_UNRESOLVED_CONSTRUCTOR_INVOKE,
            arguments: '(true,42)')),
    const Test(
        '''
        abstract class AbstractClass {}
        m() => new AbstractClass();
        ''',
        const Visit(
            VisitKind.ERROR_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(AbstractClass#)',
            type: 'AbstractClass',
            arguments: '()',
            selector: 'Selector(call, , arity=0)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) = Unresolved;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.ERROR_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) = Class.named;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.ERROR_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) = Class.named;
          factory Class.named(a, b) = Class.unresolved;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.ERROR_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
    const Test(
        '''
        abstract class AbstractClass {
          AbstractClass(a, b);
        }
        class Class {
          factory Class(a, b) = AbstractClass;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.ERROR_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'Selector(call, , arity=2)')),
  ],
};

main(List<String> arguments) {
  asyncTest(() => Future.forEach([
    () {
      return test(
          arguments,
          SEND_TESTS,
          (elements) => new SemanticSendTestVisitor(elements));
    },
  ], (f) => f()));
}

Future test(List<String> arguments,
            Map<String, List<Test>> TESTS,
            SemanticTestVisitor createVisitor(TreeElements elements)) {
  Map<String, String> sourceFiles = {};
  Map<String, Test> testMap = {};
  StringBuffer mainSource = new StringBuffer();
  int index = 0;
  TESTS.forEach((String group, List<Test> tests) {
    if (arguments.isNotEmpty && !arguments.contains(group)) return;

    tests.forEach((Test test) {
      StringBuffer testSource = new StringBuffer();
      if (test.codeByPrefix != null) {
        String prefixFilename = 'pre$index.dart';
        sourceFiles[prefixFilename] = test.codeByPrefix;
        testSource.writeln("import '$prefixFilename' as p;");
      }

      String filename = 'lib$index.dart';
      testSource.writeln(test.code);
      sourceFiles[filename] = testSource.toString();
      mainSource.writeln("import '$filename';");
      testMap[filename] = test;
      index++;
    });
  });
  mainSource.writeln("main() {}");
  sourceFiles['main.dart'] = mainSource.toString();

  Compiler compiler = compilerFor(sourceFiles,
      options: ['--analyze-all', '--analyze-only']);
  return compiler.run(Uri.parse('memory:main.dart')).then((_) {
    testMap.forEach((String filename, Test test) {
      LibraryElement library = compiler.libraryLoader.lookupLibrary(
          Uri.parse('memory:$filename'));
      var expectedVisits = test.expectedVisits;
      if (expectedVisits is! List) {
        expectedVisits = [expectedVisits];
      }
      AstElement element;
      String cls = test.cls;
      String method = test.method;
      if (cls == null) {
        element = library.find(method);
      } else {
        ClassElement classElement = library.find(cls);
        Expect.isNotNull(classElement,
                         "Class '$cls' not found in:\n"
                         "${library.compilationUnit.script.text}");
        element = classElement.localLookup(method);
      }
      Expect.isNotNull(element, "Element '$method' not found in:\n"
                                "${library.compilationUnit.script.text}");
      ResolvedAst resolvedAst = element.resolvedAst;
      SemanticTestVisitor visitor = createVisitor(resolvedAst.elements);
      try {
        compiler.withCurrentElement(resolvedAst.element, () {
          //print(resolvedAst.node.toDebugString());
          resolvedAst.node.accept(visitor);
        });
      } catch (e, s) {
        Expect.fail("$e:\n$s\nIn test:\n"
                    "${library.compilationUnit.script.text}");
      }
      Expect.listEquals(expectedVisits, visitor.visits,
          "In test:\n"
          "${library.compilationUnit.script.text}");
    });
  });
}


abstract class SemanticTestVisitor extends TraversalVisitor {
  List<Visit> visits = <Visit>[];

  SemanticTestVisitor(TreeElements elements) : super(elements);

  apply(Node node, arg) => node.accept(this);

  internalError(Spannable spannable, String message) {
    throw new SpannableAssertionFailure(spannable, message);
  }
}

class SemanticSendTestVisitor extends SemanticTestVisitor {

  SemanticSendTestVisitor(TreeElements elements) : super(elements);

  @override
  visitAs(
      Send node,
      Node expression,
      DartType type,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_AS,
        expression: expression, type: type));
    apply(expression, arg);
  }

  @override
  visitAssert(
      Send node,
      Node expression,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_ASSERT, expression: expression));
    apply(expression, arg);
  }

  @override
  errorInvalidAssert(
      Send node,
      NodeList arguments,
      arg) {
    // TODO: implement errorAssert
  }

  @override
  visitBinary(
      Send node,
      Node left,
      BinaryOperator operator,
      Node right,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_BINARY,
        left: left, operator: operator, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitIndex(
      Send node,
      Node receiver,
      Node index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX,
        receiver: receiver, index: index));
    apply(receiver, arg);
    apply(index, arg);
  }

  @override
  visitClassTypeLiteralGet(
      Send node,
      ConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_GET,
        constant: constant.getText()));
  }

  @override
  visitClassTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), arguments: arguments));
    apply(arguments, arg);
  }

  @override
  errorClassTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitNotEquals(
      Send node,
      Node left,
      Node right,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_NOT_EQUALS,
        left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitDynamicPropertyPrefix(
      Send node,
      Node receiver,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_PREFIX,
        receiver: receiver, operator: operator,
        getter: getterSelector, setter: setterSelector));
    apply(receiver, arg);
  }

  @override
  visitDynamicPropertyPostfix(
      Send node,
      Node receiver,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_POSTFIX,
        receiver: receiver, operator: operator,
        getter: getterSelector, setter: setterSelector));
    apply(receiver, arg);
  }

  @override
  visitDynamicPropertyGet(
      Send node,
      Node receiver,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
        receiver: receiver, name: selector.name));
    apply(receiver, arg);
  }

  @override
  visitDynamicPropertyInvoke(
      Send node,
      Node receiver,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_INVOKE,
        receiver: receiver, name: selector.name, arguments: arguments));
    apply(receiver, arg);
    apply(arguments, arg);
  }

  @override
  visitDynamicPropertySet(
      SendSet node,
      Node receiver,
      Selector selector,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_SET,
        receiver: receiver, name: selector.name, rhs: rhs));
    apply(receiver, arg);
  }

  @override
  visitDynamicTypeLiteralGet(
      Send node,
      ConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_GET,
        constant: constant.getText()));
  }

  @override
  visitDynamicTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), arguments: arguments));
  }

  @override
  errorDynamicTypeLiteralSet(
      Send node,
      ConstantExpression constant,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET,
        rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitExpressionInvoke(
      Send node,
      Node expression,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_EXPRESSION_INVOKE,
        receiver: expression, arguments: arguments));
  }

  @override
  visitIs(
      Send node,
      Node expression,
      DartType type,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_IS,
        expression: expression, type: type));
    apply(expression, arg);
  }

  @override
  visitIsNot(
      Send node,
      Node expression,
      DartType type,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_IS_NOT,
        expression: expression, type: type));
    apply(expression, arg);
  }

  @override
  visitLogicalAnd(
      Send node,
      Node left,
      Node right,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOGICAL_AND,
        left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitLogicalOr(
      Send node,
      Node left,
      Node right,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOGICAL_OR,
        left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitLocalFunctionGet(
      Send node,
      LocalFunctionElement function,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_GET,
                         element: function));
  }

  @override
  visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_INVOKE,
        element: function, arguments: arguments, selector: selector));
    apply(arguments, arg);
  }

  @override
  visitLocalVariableGet(
      Send node,
      LocalVariableElement variable,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_GET,
                         element: variable));
  }

  @override
  visitLocalVariableInvoke(
      Send node,
      LocalVariableElement variable,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_INVOKE,
        element: variable, arguments: arguments, selector: selector));
    apply(arguments, arg);
  }

  @override
  visitLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_SET,
        element: variable, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitParameterGet(
      Send node,
      ParameterElement parameter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_GET, element: parameter));
  }

  @override
  visitParameterInvoke(
      Send node,
      ParameterElement parameter,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_INVOKE,
        element: parameter, arguments: arguments, selector: selector));
    apply(arguments, arg);
  }

  @override
  visitParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_SET,
                         element: parameter, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticFieldGet(
      Send node,
      FieldElement field,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: field));
  }

  @override
  visitStaticFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_SET,
        element: field, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticFunctionGet(
      Send node,
      MethodElement function,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_GET,
        element: function));
  }

  @override
  visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
        element: function, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitStaticGetterGet(
      Send node,
      FunctionElement getter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_GET,
        element: getter));
  }

  @override
  visitStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
        element: getter, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitStaticSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_SET,
        element: setter, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperBinary(
      Send node,
      FunctionElement function,
      BinaryOperator operator,
      Node argument,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_BINARY,
            element: function, operator: operator, right: argument));
    apply(argument, arg);
  }

  @override
  visitSuperIndex(
      Send node,
      FunctionElement function,
      Node index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX,
            element: function, index: index));
    apply(index, arg);
  }

  @override
  visitSuperNotEquals(
      Send node,
      FunctionElement function,
      Node argument,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_NOT_EQUALS,
            element: function, right: argument));
    apply(argument, arg);
  }

  @override
  visitThisGet(Identifier node, arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_GET));
  }

  @override
  visitThisInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_INVOKE, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitThisPropertyGet(
      Send node,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_GET,
                         name: selector.name));
  }

  @override
  visitThisPropertyInvoke(
      Send node,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_INVOKE,
                         name: selector.name, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitThisPropertySet(
      SendSet node,
      Selector selector,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_SET,
                         name: selector.name, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTopLevelFieldGet(
      Send node,
      FieldElement field,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET, element: field));
  }

  @override
  visitTopLevelFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET,
        element: field, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTopLevelFunctionGet(
      Send node,
      MethodElement function,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_GET,
        element: function));
  }

  @override
  visitTopLevelFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
        element: function, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelGetterGet(
      Send node,
      FunctionElement getter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_GET,
        element: getter));
  }

  @override
  visitTopLevelGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
        element: getter, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
        element: setter, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTypeVariableTypeLiteralGet(
      Send node,
      TypeVariableElement element,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_GET,
        element: element));
  }

  @override
  visitTypeVariableTypeLiteralInvoke(
      Send node,
      TypeVariableElement element,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
        element: element, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  errorTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
        element: element, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTypedefTypeLiteralGet(
      Send node,
      ConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_GET,
        constant: constant.getText()));
  }

  @override
  visitTypedefTypeLiteralInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), arguments: arguments));
    apply(arguments, arg);
  }

  @override
  errorTypedefTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET,
        constant: constant.getText(), rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnary(
      Send node,
      UnaryOperator operator,
      Node expression,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNARY,
        expression: expression, operator: operator));
    apply(expression, arg);
  }

  @override
  visitNot(
      Send node,
      Node expression,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_NOT, expression: expression));
    apply(expression, arg);
  }

  @override
  visitSuperFieldGet(
      Send node,
      FieldElement field,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_GET, element: field));
  }

  @override
  visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SET,
        element: field, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodGet(
      Send node,
      MethodElement method,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_GET, element: method));
  }

  @override
  visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_INVOKE,
        element: method, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperGetterGet(
      Send node,
      FunctionElement getter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_GET, element: getter));
  }

  @override
  visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_INVOKE,
        element: getter, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_SETTER_SET,
        element: setter, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperUnary(
      Send node,
      UnaryOperator operator,
      FunctionElement function,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_UNARY,
        element: function, operator: operator));
  }

  @override
  visitEquals(
      Send node,
      Node left,
      Node right,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_EQUALS, left: left, right: right));
    apply(left, arg);
    apply(right, arg);
  }

  @override
  visitSuperEquals(
      Send node,
      FunctionElement function,
      Node argument,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_EQUALS,
        element: function, right: argument));
    apply(argument, arg);
  }

  @override
  visitIndexSet(
      Send node,
      Node receiver,
      Node index,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_SET,
        receiver: receiver, index: index, rhs: rhs));
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitSuperIndexSet(
      Send node,
      FunctionElement function,
      Node index,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_SET,
        element: function, index: index, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  errorFinalLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      arg) {
    // TODO: implement errorFinalLocalVariableSet
  }

  @override
  errorFinalParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      arg) {
    // TODO: implement errorFinalParameterSet
  }

  @override
  errorFinalStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    // TODO: implement errorFinalStaticFieldSet
  }

  @override
  errorFinalSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    // TODO: implement errorFinalSuperFieldSet
  }

  @override
  errorFinalTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    // TODO: implement errorFinalTopLevelFieldSet
  }

  @override
  errorLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      arg) {
    // TODO: implement errorLocalFunctionSet
  }

  @override
  errorStaticFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      arg) {
    // TODO: implement errorStaticFunctionSet
  }

  @override
  errorStaticGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      arg) {
    // TODO: implement errorStaticGetterSet
  }

  @override
  errorStaticSetterGet(
      Send node,
      FunctionElement setter,
      arg) {
    // TODO: implement errorStaticSetterGet
  }

  @override
  errorStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement errorStaticSetterInvoke
  }

  @override
  errorSuperGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      arg) {
    // TODO: implement errorSuperGetterSet
  }

  @override
  errorSuperMethodSet(
      Send node,
      MethodElement method,
      Node rhs,
      arg) {
    // TODO: implement errorSuperMethodSet
  }

  @override
  errorSuperSetterGet(
      Send node,
      FunctionElement setter,
      arg) {
    // TODO: implement errorSuperSetterGet
  }

  @override
  errorSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement errorSuperSetterInvoke
  }

  @override
  errorTopLevelFunctionSet(
      Send node,
      MethodElement function,
      Node rhs,
      arg) {
    // TODO: implement errorTopLevelFunctionSet
  }

  @override
  errorTopLevelGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      arg) {
    // TODO: implement errorTopLevelGetterSet
  }

  @override
  errorTopLevelSetterGet(
      Send node,
      FunctionElement setter,
      arg) {
    // TODO: implement errorTopLevelSetterGet
  }

  @override
  errorTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement errorTopLevelSetterInvoke
  }

  @override
  visitDynamicPropertyCompound(
      Send node,
      Node receiver,
      AssignmentOperator operator,
      Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_COMPOUND,
        receiver: receiver, operator: operator, rhs: rhs,
        getter: getterSelector, setter: setterSelector));
    apply(receiver, arg);
    apply(rhs, arg);
  }

  @override
  errorFinalLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorFinalLocalVariableCompound
  }

  @override
  errorFinalParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorFinalParameterCompound
  }

  @override
  errorFinalStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorFinalStaticFieldCompound
  }

  @override
  errorFinalSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorFinalSuperFieldCompound
  }

  @override
  errorFinalTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorFinalTopLevelFieldCompound
  }

  @override
  errorLocalFunctionCompound(
      Send node,
      LocalFunctionElement function,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorLocalFunctionCompound
  }

  @override
  visitLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_COMPOUND,
        element: variable, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_COMPOUND,
        element: parameter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
        operator: operator, rhs: rhs,
        getter: getter, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_COMPOUND,
        operator: operator, rhs: rhs,
        getter: getter, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitThisPropertyCompound(
      Send node,
      AssignmentOperator operator,
      Node rhs,
      Selector getterSelector,
      Selector setterSelector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_COMPOUND,
        operator: operator, rhs: rhs,
        getter: getterSelector, setter: setterSelector));
    apply(rhs, arg);
  }

  @override
  visitTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTopLevelGetterSetterCompound(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_COMPOUND,
        operator: operator, rhs: rhs,
        getter: getter, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitStaticMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
        operator: operator, rhs: rhs,
        getter: method, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitSuperFieldSetterCompound(
      Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_COMPOUND,
        operator: operator, rhs: rhs,
        getter: field, setter: setter));
    apply(rhs, arg);
  }

  @override
  visitSuperGetterFieldCompound(
      Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_COMPOUND,
        operator: operator, rhs: rhs,
        getter: getter, setter: field));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement visitSuperMethodSetterCompound
  }

  @override
  visitTopLevelMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement visitTopLevelMethodSetterCompound
  }

  @override
  visitCompoundIndexSet(
      Send node,
      Node receiver,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_COMPOUND_INDEX_SET,
        receiver: receiver, index: index, rhs: rhs, operator: operator));
    apply(receiver, arg);
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitSuperCompoundIndexSet(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_COMPOUND_INDEX_SET,
        getter: getter, setter: setter,
        index: index, rhs: rhs, operator: operator));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  errorClassTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_CLASS_TYPE_LITERAL_COMPOUND,
        constant: constant.getText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  errorDynamicTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_DYNAMIC_TYPE_LITERAL_COMPOUND,
        constant: constant.getText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  errorTypeVariableTypeLiteralCompound(
      Send node,
      TypeVariableElement element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
        element: element, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  errorTypedefTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_TYPEDEF_TYPE_LITERAL_COMPOUND,
        constant: constant.getText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  errorLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      arg) {
    // TODO: implement errorLocalFunctionPrefix
  }

  @override
  errorClassTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_CLASS_TYPE_LITERAL_PREFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  errorDynamicTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_DYNAMIC_TYPE_LITERAL_PREFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_PREFIX,
        element: variable, operator: operator));
  }

  @override
  visitParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_PREFIX,
        element: parameter, operator: operator));
  }

  @override
  visitStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitStaticGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitStaticMethodSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitStaticMethodSetterPrefix
  }

  @override
  visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitSuperFieldFieldPrefix
  }

  @override
  visitSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitSuperFieldSetterPrefix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_PREFIX,
        getter: field, setter: setter, operator: operator));
  }

  @override
  visitSuperGetterFieldPrefix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_PREFIX,
        getter: getter, setter: field, operator: operator));
  }

  @override
  visitSuperGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitSuperMethodSetterPrefix
  }

  @override
  visitThisPropertyPrefix(
      Send node,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_PREFIX,
        operator: operator,
        getter: getterSelector, setter: setterSelector));
  }

  @override
  visitTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitTopLevelGetterSetterPrefix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitTopLevelMethodSetterPrefix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitTopLevelMethodSetterPrefix
  }

  @override
  errorTypeVariableTypeLiteralPrefix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
        element: element, operator: operator));
  }

  @override
  errorTypedefTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_TYPEDEF_TYPE_LITERAL_PREFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  errorLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      arg) {
    // TODO: implement errorLocalFunctionPostfix
  }

  @override
  errorClassTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_CLASS_TYPE_LITERAL_POSTFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  errorDynamicTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_DYNAMIC_TYPE_LITERAL_POSTFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_POSTFIX,
        element: variable, operator: operator));
  }

  @override
  visitParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_POSTFIX,
        element: parameter, operator: operator));
  }

  @override
  visitStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitStaticGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitStaticMethodSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitStaticMethodSetterPostfix
  }

  @override
  visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitSuperFieldFieldPostfix
  }

  @override
  visitSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitSuperFieldSetterPostfix(
      Send node,
      FieldElement field,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_POSTFIX,
        getter: field, setter: setter, operator: operator));
  }

  @override
  visitSuperGetterFieldPostfix(
      Send node,
      FunctionElement getter,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_POSTFIX,
        getter: getter, setter: field, operator: operator));
  }

  @override
  visitSuperGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitSuperMethodSetterPostfix
  }

  @override
  visitThisPropertyPostfix(
      Send node,
      IncDecOperator operator,
      Selector getterSelector,
      Selector setterSelector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_PROPERTY_POSTFIX,
        operator: operator,
        getter: getterSelector, setter: setterSelector));
  }

  @override
  visitTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitTopLevelGetterSetterPostfix(
      Send node,
      FunctionElement getter,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitTopLevelMethodSetterPostfix(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      IncDecOperator operator,
      arg) {
    // TODO: implement visitTopLevelMethodSetterPostfix
  }

  @override
  errorTypeVariableTypeLiteralPostfix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,
        element: element, operator: operator));
  }

  @override
  errorTypedefTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.ERROR_TYPEDEF_TYPE_LITERAL_POSTFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitConstantGet(
      Send node,
      ConstantExpression constant,
      arg) {
    // TODO: implement visitConstantGet
  }

  @override
  visitConstantInvoke(
      Send node,
      ConstantExpression constant,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement visitConstantInvoke
  }

  @override
  errorUnresolvedCompound(
      Send node,
      ErroneousElement element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorUnresolvedCompound
  }

  @override
  errorUnresolvedGet(
      Send node,
      ErroneousElement element,
      arg) {
    // TODO: implement errorUnresolvedGet
  }

  @override
  errorUnresolvedInvoke(
      Send node,
      ErroneousElement element,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement errorUnresolvedInvoke
  }

  @override
  errorUnresolvedPostfix(
      Send node,
      ErroneousElement element,
      IncDecOperator operator,
      arg) {
    // TODO: implement errorUnresolvedPostfix
  }

  @override
  errorUnresolvedPrefix(
      Send node,
      ErroneousElement element,
      IncDecOperator operator,
      arg) {
    // TODO: implement errorUnresolvedPrefix
  }

  @override
  errorUnresolvedSet(
      Send node,
      ErroneousElement element,
      Node rhs,
      arg) {
    // TODO: implement errorUnresolvedSet
  }

  @override
  errorUndefinedBinaryExpression(
      Send node,
      Node left,
      Operator operator,
      Node right,
      arg) {
    // TODO: implement errorUndefinedBinaryExpression
  }

  @override
  errorUndefinedUnaryExpression(
      Send node,
      Operator operator,
      Node expression,
      arg) {
    // TODO: implement errorUndefinedUnaryExpression
  }

  @override
  errorUnresolvedSuperBinary(
      Send node,
      ErroneousElement element,
      BinaryOperator operator,
      Node argument,
      arg) {
    // TODO: implement errorUnresolvedSuperBinary
  }

  @override
  errorUnresolvedSuperCompoundIndexSet(
      Send node,
      ErroneousElement element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    // TODO: implement errorUnresolvedSuperCompoundIndexSet
  }

  @override
  errorUnresolvedSuperIndexSet(
      Send node,
      ErroneousElement element,
      Node index,
      Node rhs,
      arg) {
    // TODO: implement errorUnresolvedSuperIndexSet
  }

  @override
  errorUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      ErroneousElement element,
      arg) {
    // TODO: implement errorUnresolvedSuperUnary
  }

  @override
  errorUnresolvedSuperIndex(
      Send node,
      Element element,
      Node index,
      arg) {
    // TODO: implement errorUnresolvedSuperIndex
  }

  @override
  errorUnresolvedSuperIndexPostfix(
      Send node,
      Element function,
      Node index,
      IncDecOperator operator,
      arg) {
    // TODO: implement errorUnresolvedSuperIndexPostfix
  }

  @override
  errorUnresolvedSuperIndexPrefix(
      Send node,
      Element function,
      Node index,
      IncDecOperator operator,
      arg) {
    // TODO: implement errorUnresolvedSuperIndexPrefix
  }

  @override
  visitIndexPostfix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_POSTFIX,
        receiver: receiver, index: index, operator: operator));
    apply(receiver, arg);
    apply(index, arg);
  }

  @override
  visitIndexPrefix(
      Send node,
      Node receiver,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INDEX_PREFIX,
        receiver: receiver, index: index, operator: operator));
    apply(receiver, arg);
    apply(index, arg);
  }

  @override
  visitSuperIndexPostfix(
      Send node,
      FunctionElement indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_POSTFIX,
        getter: indexFunction, setter: indexSetFunction,
        index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitSuperIndexPrefix(
      Send node,
      FunctionElement indexFunction,
      FunctionElement indexSetFunction,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_INDEX_PREFIX,
        getter: indexFunction, setter: indexSetFunction,
        index: index, operator: operator));
    apply(index, arg);
  }

  @override
  errorUnresolvedClassConstructorInvoke(
      NewExpression node,
      Element constructor,
      MalformedType type,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO(johnniwinther): Test [type] and [selector].
    visits.add(new Visit(
        VisitKind.ERROR_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  errorUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO(johnniwinther): Test [type] and [selector].
    visits.add(new Visit(
        VisitKind.ERROR_UNRESOLVED_CONSTRUCTOR_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitConstConstructorInvoke(
      NewExpression node,
      ConstructedConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CONST_CONSTRUCTOR_INVOKE,
                         constant: constant.getText()));
  }

  @override
  visitFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: selector));
    apply(arguments, arg);
  }

  @override
  visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: selector));
    apply(arguments, arg);
  }

  @override
  visitRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      ConstructorElement effectiveTarget,
      InterfaceType effectiveTargetType,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        target: effectiveTarget,
        targetType: effectiveTargetType,
        arguments: arguments,
        selector: selector));
    apply(arguments, arg);
  }

  @override
  visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: selector));
    apply(arguments, arg);
  }

  @override
  errorAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(
        VisitKind.ERROR_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: selector));
    apply(arguments, arg);
  }

  @override
  errorUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(
        VisitKind.ERROR_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: selector));
    apply(arguments, arg);
  }
}

enum VisitKind {
  VISIT_PARAMETER_GET,
  VISIT_PARAMETER_SET,
  VISIT_PARAMETER_INVOKE,
  VISIT_PARAMETER_COMPOUND,
  VISIT_PARAMETER_PREFIX,
  VISIT_PARAMETER_POSTFIX,

  VISIT_LOCAL_VARIABLE_GET,
  VISIT_LOCAL_VARIABLE_SET,
  VISIT_LOCAL_VARIABLE_INVOKE,
  VISIT_LOCAL_VARIABLE_COMPOUND,
  VISIT_LOCAL_VARIABLE_PREFIX,
  VISIT_LOCAL_VARIABLE_POSTFIX,

  VISIT_LOCAL_FUNCTION_GET,
  VISIT_LOCAL_FUNCTION_INVOKE,

  VISIT_STATIC_FIELD_GET,
  VISIT_STATIC_FIELD_SET,
  VISIT_STATIC_FIELD_INVOKE,
  VISIT_STATIC_FIELD_COMPOUND,
  VISIT_STATIC_FIELD_PREFIX,
  VISIT_STATIC_FIELD_POSTFIX,

  VISIT_STATIC_GETTER_GET,
  VISIT_STATIC_SETTER_SET,
  VISIT_STATIC_GETTER_INVOKE,
  VISIT_STATIC_GETTER_SETTER_COMPOUND,
  VISIT_STATIC_METHOD_SETTER_COMPOUND,
  VISIT_STATIC_GETTER_SETTER_PREFIX,
  VISIT_STATIC_GETTER_SETTER_POSTFIX,

  VISIT_STATIC_FUNCTION_GET,
  VISIT_STATIC_FUNCTION_INVOKE,

  VISIT_TOP_LEVEL_FIELD_GET,
  VISIT_TOP_LEVEL_FIELD_SET,
  VISIT_TOP_LEVEL_FIELD_INVOKE,
  VISIT_TOP_LEVEL_FIELD_COMPOUND,
  VISIT_TOP_LEVEL_FIELD_PREFIX,
  VISIT_TOP_LEVEL_FIELD_POSTFIX,

  VISIT_TOP_LEVEL_GETTER_GET,
  VISIT_TOP_LEVEL_SETTER_SET,
  VISIT_TOP_LEVEL_GETTER_INVOKE,
  VISIT_TOP_LEVEL_GETTER_SETTER_COMPOUND,
  VISIT_TOP_LEVEL_GETTER_SETTER_PREFIX,
  VISIT_TOP_LEVEL_GETTER_SETTER_POSTFIX,

  VISIT_TOP_LEVEL_FUNCTION_GET,
  VISIT_TOP_LEVEL_FUNCTION_INVOKE,

  VISIT_DYNAMIC_PROPERTY_GET,
  VISIT_DYNAMIC_PROPERTY_SET,
  VISIT_DYNAMIC_PROPERTY_INVOKE,
  VISIT_DYNAMIC_PROPERTY_COMPOUND,
  VISIT_DYNAMIC_PROPERTY_PREFIX,
  VISIT_DYNAMIC_PROPERTY_POSTFIX,

  VISIT_THIS_GET,
  VISIT_THIS_INVOKE,

  VISIT_THIS_PROPERTY_GET,
  VISIT_THIS_PROPERTY_SET,
  VISIT_THIS_PROPERTY_INVOKE,
  VISIT_THIS_PROPERTY_COMPOUND,
  VISIT_THIS_PROPERTY_PREFIX,
  VISIT_THIS_PROPERTY_POSTFIX,

  VISIT_SUPER_FIELD_GET,
  VISIT_SUPER_FIELD_SET,
  VISIT_SUPER_FIELD_INVOKE,
  VISIT_SUPER_FIELD_COMPOUND,
  VISIT_SUPER_FIELD_PREFIX,
  VISIT_SUPER_FIELD_POSTFIX,

  VISIT_SUPER_GETTER_GET,
  VISIT_SUPER_SETTER_SET,
  VISIT_SUPER_GETTER_INVOKE,
  VISIT_SUPER_GETTER_SETTER_COMPOUND,
  VISIT_SUPER_GETTER_FIELD_COMPOUND,
  VISIT_SUPER_FIELD_SETTER_COMPOUND,
  VISIT_SUPER_GETTER_SETTER_PREFIX,
  VISIT_SUPER_GETTER_FIELD_PREFIX,
  VISIT_SUPER_FIELD_SETTER_PREFIX,
  VISIT_SUPER_GETTER_SETTER_POSTFIX,
  VISIT_SUPER_GETTER_FIELD_POSTFIX,
  VISIT_SUPER_FIELD_SETTER_POSTFIX,

  VISIT_SUPER_METHOD_GET,
  VISIT_SUPER_METHOD_INVOKE,

  VISIT_BINARY,
  VISIT_INDEX,
  VISIT_EQUALS,
  VISIT_NOT_EQUALS,
  VISIT_INDEX_PREFIX,
  VISIT_INDEX_POSTFIX,

  VISIT_SUPER_BINARY,
  VISIT_SUPER_INDEX,
  VISIT_SUPER_EQUALS,
  VISIT_SUPER_NOT_EQUALS,
  VISIT_SUPER_INDEX_PREFIX,
  VISIT_SUPER_INDEX_POSTFIX,

  VISIT_UNARY,
  VISIT_SUPER_UNARY,
  VISIT_NOT,

  VISIT_EXPRESSION_INVOKE,

  VISIT_CLASS_TYPE_LITERAL_GET,
  VISIT_CLASS_TYPE_LITERAL_SET,
  VISIT_CLASS_TYPE_LITERAL_INVOKE,
  VISIT_CLASS_TYPE_LITERAL_BINARY,
  ERROR_CLASS_TYPE_LITERAL_COMPOUND,
  ERROR_CLASS_TYPE_LITERAL_PREFIX,
  ERROR_CLASS_TYPE_LITERAL_POSTFIX,

  VISIT_TYPEDEF_TYPE_LITERAL_GET,
  VISIT_TYPEDEF_TYPE_LITERAL_SET,
  VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
  VISIT_TYPEDEF_TYPE_LITERAL_BINARY,
  ERROR_TYPEDEF_TYPE_LITERAL_COMPOUND,
  ERROR_TYPEDEF_TYPE_LITERAL_PREFIX,
  ERROR_TYPEDEF_TYPE_LITERAL_POSTFIX,

  VISIT_TYPE_VARIABLE_TYPE_LITERAL_GET,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_BINARY,
  ERROR_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
  ERROR_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
  ERROR_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,

  VISIT_DYNAMIC_TYPE_LITERAL_GET,
  VISIT_DYNAMIC_TYPE_LITERAL_SET,
  VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
  VISIT_DYNAMIC_TYPE_LITERAL_BINARY,
  ERROR_DYNAMIC_TYPE_LITERAL_COMPOUND,
  ERROR_DYNAMIC_TYPE_LITERAL_PREFIX,
  ERROR_DYNAMIC_TYPE_LITERAL_POSTFIX,

  VISIT_INDEX_SET,
  VISIT_COMPOUND_INDEX_SET,
  VISIT_SUPER_INDEX_SET,
  VISIT_SUPER_COMPOUND_INDEX_SET,

  VISIT_ASSERT,
  VISIT_LOGICAL_AND,
  VISIT_LOGICAL_OR,
  VISIT_IS,
  VISIT_IS_NOT,
  VISIT_AS,

  VISIT_CONST_CONSTRUCTOR_INVOKE,
  VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
  VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
  VISIT_FACTORY_CONSTRUCTOR_INVOKE,
  VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,

  ERROR_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
  ERROR_UNRESOLVED_CONSTRUCTOR_INVOKE,
  ERROR_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
  ERROR_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,

  // TODO(johnniwinther): Add tests for error cases.
}
