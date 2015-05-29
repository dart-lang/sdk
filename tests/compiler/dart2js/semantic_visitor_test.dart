// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.semantics_visitor_test;

import 'dart:async';
import 'dart:mirrors';
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
                    selector: 'CallStructure(arity=2)')),
    // TODO(johnniwinther): Expect [VISIT_FINAL_PARAMETER_SET] instead.
    const Test('m(final o) { o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs:'42')),
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
                    selector: 'CallStructure(arity=2)')),
    // TODO(johnniwinther): Expect [VISIT_FINAL_LOCAL_VARIABLE_SET] instead.
    const Test('m() { final o = 0; o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs:'42')),
    // TODO(johnniwinther): Expect [VISIT_FINAL_LOCAL_VARIABLE_SET] instead.
    const Test('m() { const o = 0; o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs:'42')),
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
                    selector: 'CallStructure(arity=2)')),
    // TODO(johnniwinther): Expect [VISIT_LOCAL_FUNCTION_SET] instead.
    const Test('m() { o(a, b) {}; o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
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
    // TODO(johnniwinther): Expect [VISIT_FINAL_STATIC_FIELD_SET] instead.
    const Test(
        '''
        class C { static final o = 0; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static final o = 0;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static final o = 0;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static final o = 0;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test(
        '''
        class C { static const o = 0; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static const o = 0;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static const o = 0;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static const o = 0;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
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
    // TODO(johnniwinther): Expected [VISIT_STATIC_GETTER_SET] instead.
    const Test(
        '''
        class C { static get o => 42; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static static get o => 42;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static static get o => 42;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static static get o => 42;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    // TODO(johnniwinther): Expected [VISIT_STATIC_SETTER_GET] instead.
    const Test(
        '''
        class C {
          static set o(_) {}
        }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
    const Test.prefix(
        '''
        class C {
          static set o(_) {}
        }
        ''',
        'm() => p.C.o;',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
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
    // TODO(johnniwinther): Expect [VISIT_STATIC_SETTER_INVOKE] instead.
    const Test(
        '''
        class C { static set o(_) {} }
        m() => C.o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
                    arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static set o(_) {}
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
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
    // TODO(johnniwinther): Expect [VISIT_STATIC_FUNCTION_SET] instead.
    const Test(
        '''
        class C { static o(a, b) {} }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        class C { static o(a, b) {} }
        ''',
        '''
        m() { p.C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
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
    const Test(
        '''
        class C { static o(a, b) {} }
        m() => C.o(null);
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INCOMPATIBLE_INVOKE,
                    element: 'function(C#o)',
                    arguments: '(null)')),
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
    // TODO(johnniwinther): Expect [VISIT_FINAL_TOP_LEVEL_FIELD_SET] instead.
    const Test(
        '''
        final o = 0;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        final o = 0;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test(
        '''
        const o = 0;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        const o = 0;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
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
    const Test(
        '''
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
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
    // TODO(johnniwinther): Expect [VISIT_TOP_LEVEL_SETTER_GET] instead.
    const Test(
        '''
        set o(_) {}
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
    const Test.prefix(
        '''
        set o(_) {}
        ''',
        '''
        m() => p.o;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET,
                    name: 'o')),
    // TODO(johnniwinther): Expect [VISIT_TOP_LEVEL_GETTER_SET] instead.
    const Test(
        '''
        get o => null;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        get o => null;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
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
    // TODO(johnniwinther): Expected [VISIT_TOP_LEVEL_SETTER_INVOKE] instead.
    const Test(
        '''
        set o(_) {}
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
                    arguments: '(null,42)')),
    const Test.prefix(
        '''
        set o(_) {}
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
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
    const Test(
        '''
        o(a, b) {}
        m() => o(null);
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INCOMPATIBLE_INVOKE,
                    element: 'function(o)',
                    arguments: '(null)')),
    const Test.prefix(
        '''
        o(a, b) {}
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
                    element: 'function(o)',
                    arguments: '(null,42)')),
    const Test(
        '''
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                    name: 'o',
                    arguments: '(null,42)')),
    // TODO(johnniwinther): Expect [VISIT_TOP_LEVEL_FUNCTION_SET] instead.
    const Test(
        '''
        o(a, b) {}
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
    const Test.prefix(
        '''
        o(a, b) {}
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
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
    // TODO(johnniwinther): Expect [VISIT_FINAL_SUPER_FIELD_SET] instead.
    const Test.clazz(
        '''
        class B {
          final o = 0;
        }
        class C extends B {
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
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
    const Test.clazz(
            '''
        class B {
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GET)),
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
    // TODO(johnniwinther): Expect [VISIT_SUPER_SETTER_GET] instead.
    const Test.clazz(
        '''
        class B {
          set o(_) {}
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GET)),
    // TODO(johnniwinther): Expect [VISIT_SUPER_GETTER_SET] instead.
    const Test.clazz(
        '''
        class B {
          get o => 0;
        }
        class C extends B {
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET,
                    name: 'o',
                    rhs: '42')),
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
    // TODO(johnniwinther): Expect [VISIT_SUPER_SETTER_INVOKE] instead.
    const Test.clazz(
        '''
        class B {
          set o(_) {}
        }
        class C extends B {
          m() { super.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INVOKE,
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
    const Test.clazz(
        '''
        class B {
          o(a, b) {}
        }
        class C extends B {
          m() { super.o(null); }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_INCOMPATIBLE_INVOKE,
                    element: 'function(B#o)',
                    arguments: '(null)')),
    const Test.clazz(
            '''
            class B {
            }
            class C extends B {
              m() => super.o(null, 42);
            }
            ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INVOKE,
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
    const Test(
        '''
        class C {}
        m() => C += 42;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_COMPOUND,
                    constant: 'C',
                    operator: '+=',
                    rhs: '42')),
    const Test(
        '''
        class C {}
        m() => ++C;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_PREFIX,
                    constant: 'C',
                    operator: '++')),
    const Test(
        '''
        class C {}
        m() => C--;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_POSTFIX,
                    constant: 'C',
                    operator: '--')),
    const Test(
        '''
        class C {}
        m() => C;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_GET,
                    constant: 'C')),
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
    const Test(
        '''
        typedef F();
        m() => F += 42;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
                    constant: 'F',
                    operator: '+=',
                    rhs: '42')),
    const Test(
        '''
        typedef F();
        m() => ++F;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_PREFIX,
                    constant: 'F',
                    operator: '++')),
    const Test(
        '''
        typedef F();
        m() => F--;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_POSTFIX,
                    constant: 'F',
                    operator: '--')),
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
    const Test.clazz(
        '''
        class C<T> {
          m() => T += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
                    element: 'type_variable(C#T)',
                    operator: '+=',
                    rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          m() => ++T;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
                    element: 'type_variable(C#T)',
                    operator: '++')),
    const Test.clazz(
        '''
        class C<T> {
          m() => T--;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,
                    element: 'type_variable(C#T)',
                    operator: '--')),

  ],
  'Dynamic type literals': const [
    // Dynamic type literals
    const Test(
        '''
        m() => dynamic;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_GET,
                    constant: 'dynamic')),
    // TODO(johnniwinther): Update these to expect the constant to be `dynamic`
    // instead of `Type`. Currently the compile time constant evaluator cannot
    // detect `dynamic` as a constant subexpression.
    const Test(
        '''
        m() { dynamic(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
                    constant: 'Type',
                    arguments: '(null,42)')),
    const Test(
        '''
        m() => dynamic += 42;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
                    constant: 'Type',
                    operator: '+=',
                    rhs: '42')),
    const Test(
        '''
        m() => ++dynamic;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_PREFIX,
                    constant: 'Type',
                    operator: '++')),
    const Test(
        '''
        m() => dynamic--;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_POSTFIX,
                    constant: 'Type',
                    operator: '--')),
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
    const Test.clazz(
        '''
        class B {}
        class C extends B {
          m() => super + 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_BINARY,
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
        }
        class C extends B {
          m() => super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX,
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
          operator []=(a, b) {}
        }
        class C extends B {
          m() => ++super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_PREFIX,
                    setter: 'function(B#[]=)',
                    index: '42',
                    operator: '++')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => ++super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_PREFIX,
                    index: '42',
                    operator: '++')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
        }
        class C extends B {
          m() => ++super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_PREFIX,
                    getter: 'function(B#[])',
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
    const Test.clazz(
        '''
        class B {
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[42]--;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_POSTFIX,
                    setter: 'function(B#[]=)',
                    index: '42',
                    operator: '--')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super[42]--;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_POSTFIX,
                    index: '42',
                    operator: '--')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
        }
        class C extends B {
          m() => super[42]--;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_POSTFIX,
                    getter: 'function(B#[])',
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
    const Test.clazz(
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
                    right: '42')),
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
        }
        class C extends B {
          m() => -super;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_UNARY,
                    operator: '-')),
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
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super[1] = 2;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_SET,
            index: '1', rhs: '2')),
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
    const Test(
        '''
        m(a) => a += 42;
        ''',
        const Visit(VisitKind.VISIT_PARAMETER_COMPOUND,
            element: 'parameter(m#a)', operator: '+=', rhs: '42')),
    const Test(
        '''
        m(final a) => a += 42;
        ''',
        const Visit(VisitKind.VISIT_FINAL_PARAMETER_COMPOUND,
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
        m() {
          final a;
          a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_COMPOUND,
            element: 'variable(m#a)', operator: '+=', rhs: '42')),
    const Test(
        '''
        m() {
          a() {}
          a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_COMPOUND,
            element: 'function(m#a)', operator: '+=', rhs: '42')),
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
          final a = 0;
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_COMPOUND,
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
    const Test.clazz(
        '''
        class B {
          a() {}
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_COMPOUND,
            element: 'function(B#a)',
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_COMPOUND,
            operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          set a(_) {}
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND,
            setter: 'setter(B#a)', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          get a => 42;
        }
        class C extends B {
          m() => super.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND,
            getter: 'getter(B#a)', operator: '+=', rhs: '42')),

    const Test.clazz(
        '''
        class C {
          static set a(var value) { }
          m() => a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_COMPOUND,
            setter: 'setter(C#a)', operator: '+=', rhs: '42')),

    const Test.clazz(
        '''
        class C {
          static get a => 42;
          m() => C.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_COMPOUND,
            getter: 'getter(C#a)', operator: '+=', rhs: '42')),

    const Test.clazz(
        '''
        class C {
          static final a = 42;
          m() => C.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_COMPOUND,
            element: 'field(C#a)', operator: '+=', rhs: '42')),

    const Test(
        '''
        class C {
          static a(var value) { }
        }
        m() => C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_COMPOUND,
            element: 'function(C#a)', operator: '+=', rhs: '42')),

    const Test(
        '''
        set a(var value) { }
        m() => a += 42;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_COMPOUND,
            setter: 'setter(a)', operator: '+=', rhs: '42')),

    const Test(
        '''
        get a => 42;
        m() => a += 42;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_COMPOUND,
            getter: 'getter(a)', operator: '+=', rhs: '42')),

    const Test(
        '''
        a(var value) { }
        m() => a += 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_COMPOUND,
            element: 'function(a)', operator: '+=', rhs: '42')),

    const Test(
        '''
        final a = 42;
        m() => a += 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_COMPOUND,
            element: 'field(a)', operator: '+=', rhs: '42')),

    const Test(
        '''
        m() => unresolved += 42;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_COMPOUND,
            operator: '+=', rhs: '42')),
  ],
  'Compound index assignment': const [
    // Compound index assignment
    const Test(
        '''
        m() => 0[1] += 42;
        ''',
        const Visit(VisitKind.VISIT_COMPOUND_INDEX_SET,
            receiver: '0', index: '1', operator: '+=', rhs: '42')),
    const Test.clazz(
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
            index: '1', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[1] += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND_INDEX_SET,
            setter: 'function(B#[]=)',
            index: '1', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super[1] += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_COMPOUND_INDEX_SET,
            index: '1', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          operator [](_) {}
        }
        class C extends B {
          m() => super[1] += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND_INDEX_SET,
            getter: 'function(B#[])',
            index: '1', operator: '+=', rhs: '42')),
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
        m(final a) => ++a;
        ''',
        const Visit(VisitKind.VISIT_FINAL_PARAMETER_PREFIX,
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
        m() {
          final a = 42;
          --a;
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_PREFIX,
            element: 'variable(m#a)', operator: '--')),
    const Test(
        '''
        m() {
          a() {}
          --a;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_PREFIX,
            element: 'function(m#a)', operator: '--')),
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
          final a = 0;
        }
        class C extends B {
          m() => --super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_PREFIX,
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
    const Test.clazz(
        '''
        class B {
          a() {}
        }
        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_PREFIX,
            element: 'function(B#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_PREFIX,
            operator: '++')),
    const Test.clazz(
        '''
        class B {
          set a(_) {}
        }
        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_PREFIX,
            setter: 'setter(B#a)', operator: '++')),
    const Test.clazz(
        '''
        class B {
          get a => 42;
        }
        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_PREFIX,
            getter: 'getter(B#a)', operator: '++')),

    const Test.clazz(
        '''
        class C {
          static set a(var value) { }
          m() => ++a;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_PREFIX,
            setter: 'setter(C#a)', operator: '++')),

    const Test.clazz(
        '''
        class C {
          static get a => 42;
          m() => ++C.a;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_PREFIX,
            getter: 'getter(C#a)', operator: '++')),

    const Test.clazz(
        '''
        class C {
          static final a = 42;
          m() => ++C.a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_PREFIX,
            element: 'field(C#a)', operator: '++')),

    const Test(
        '''
        class C {
          static a(var value) { }
        }
        m() => ++C.a;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_PREFIX,
            element: 'function(C#a)', operator: '++')),

    const Test(
        '''
        set a(var value) { }
        m() => ++a;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_PREFIX,
            setter: 'setter(a)', operator: '++')),

    const Test(
        '''
        get a => 42;
        m() => ++a;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_PREFIX,
            getter: 'getter(a)', operator: '++')),

    const Test(
        '''
        a(var value) { }
        m() => ++a;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_PREFIX,
            element: 'function(a)', operator: '++')),

    const Test(
        '''
        final a = 42;
        m() => ++a;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_PREFIX,
            element: 'field(a)', operator: '++')),

    const Test(
        '''
        m() => ++unresolved;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_PREFIX,
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
        m(final a) => a++;
        ''',
        const Visit(VisitKind.VISIT_FINAL_PARAMETER_POSTFIX,
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
        m() {
          final a = 42;
          a--;
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_POSTFIX,
            element: 'variable(m#a)', operator: '--')),
    const Test(
        '''
        m() {
          a() {}
          a--;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_POSTFIX,
            element: 'function(m#a)', operator: '--')),
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
          final a = 0;
        }
        class C extends B {
          m() => super.a--;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_POSTFIX,
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
    const Test.clazz(
        '''
        class B {
          a() {}
        }
        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_POSTFIX,
            element: 'function(B#a)',
            operator: '++')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_POSTFIX,
            operator: '++')),
    const Test.clazz(
        '''
        class B {
          set a(_) {}
        }
        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_POSTFIX,
            setter: 'setter(B#a)', operator: '++')),
    const Test.clazz(
        '''
        class B {
          get a => 42;
        }
        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_POSTFIX,
            getter: 'getter(B#a)', operator: '++')),

    const Test.clazz(
        '''
        class C {
          static set a(var value) { }
          m() => a++;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_POSTFIX,
            setter: 'setter(C#a)', operator: '++')),

    const Test.clazz(
        '''
        class C {
          static get a => 42;
          m() => C.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_POSTFIX,
            getter: 'getter(C#a)', operator: '++')),

    const Test.clazz(
        '''
        class C {
          static final a = 42;
          m() => C.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_POSTFIX,
            element: 'field(C#a)', operator: '++')),

    const Test(
        '''
        class C {
          static a(var value) { }
        }
        m() => C.a++;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_POSTFIX,
            element: 'function(C#a)', operator: '++')),

    const Test(
        '''
        set a(var value) { }
        m() => a++;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_POSTFIX,
            setter: 'setter(a)', operator: '++')),

    const Test(
        '''
        get a => 42;
        m() => a++;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_POSTFIX,
            getter: 'getter(a)', operator: '++')),

    const Test(
        '''
        a(var value) { }
        m() => a++;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_POSTFIX,
            element: 'function(a)', operator: '++')),

    const Test(
        '''
        final a = 42;
        m() => a++;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_POSTFIX,
            element: 'field(a)', operator: '++')),

    const Test(
        '''
        m() => unresolved++;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_POSTFIX,
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
            selector: 'CallStructure(arity=0)')),
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
            selector: 'CallStructure(arity=2)')),
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
            selector: 'CallStructure(arity=2)')),
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
            selector: 'CallStructure(arity=2)')),
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
            selector: 'CallStructure(arity=2)')),
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
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class {
          Class(a, b);
        }
        m() => new Class.unresolved(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
            arguments: '(true,42)')),
    const Test(
        '''
        m() => new Unresolved(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
            arguments: '(true,42)')),
    const Test(
        '''
        abstract class AbstractClass {}
        m() => new AbstractClass();
        ''',
        const Visit(
            VisitKind.VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(AbstractClass#)',
            type: 'AbstractClass',
            arguments: '()',
            selector: 'CallStructure(arity=0)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) = Unresolved;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) = Class.named;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class {
          factory Class(a, b) = Class.named;
          factory Class.named(a, b) = Class.unresolved;
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
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
            VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'function(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
  ],
};

const Map<String, List<Test>> DECL_TESTS = const {
  'Function declarations': const [
    const Test(
        '''
        m(a, b) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,b)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              index: 1),
        ]),
    const Test(
        '''
        m(a, [b]) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,[b])',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
              element: 'parameter(m#b)',
              index: 1,
              constant: 'null'),
        ]),
    const Test(
        '''
        m(a, [b = null]) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,[b=null])',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
              element: 'parameter(m#b)',
              constant: 'null',
              index: 1),
        ]),
    const Test(
        '''
        m(a, [b = 42]) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,[b=42])',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
              element: 'parameter(m#b)',
              constant: 42,
              index: 1),
        ]),
    const Test(
        '''
        m(a, {b}) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,{b})',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              constant: 'null'),
        ]),
    const Test(
        '''
        m(a, {b: null}) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,{b: null})',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              constant: 'null'),
        ]),
    const Test(
        '''
        m(a, {b:42}) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,{b: 42})',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              constant: 42),
        ]),
    const Test(
        '''
        get m => null;
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_DECL,
              element: 'getter(m)',
              body: '=>null;'),
        ]),
    const Test(
        '''
        set m(a) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_DECL,
              element: 'setter(m)',
              parameters: '(a)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
        ]),
    const Test.clazz(
        '''
        class C {
          static m(a, b) {}
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_FUNCTION_DECL,
              element: 'function(C#m)',
              parameters: '(a,b)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              index: 1),
        ]),
    const Test.clazz(
        '''
        class C {
          static get m => null;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_GETTER_DECL,
              element: 'getter(C#m)',
              body: '=>null;'),
        ]),
    const Test.clazz(
        '''
        class C {
          static set m(a) {}
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_SETTER_DECL,
              element: 'setter(C#m)',
              parameters: '(a)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
        ]),
    const Test.clazz(
        '''
        class C {
          m(a, b) {}
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_INSTANCE_METHOD_DECL,
              element: 'function(C#m)',
              parameters: '(a,b)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              index: 1),
        ]),
    const Test.clazz(
        '''
        class C {
          get m => null;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_INSTANCE_GETTER_DECL,
              element: 'getter(C#m)',
              body: '=>null;'),
        ]),
    const Test.clazz(
        '''
        class C {
          set m(a) {}
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_INSTANCE_SETTER_DECL,
              element: 'setter(C#m)',
              parameters: '(a)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
        ]),
    const Test.clazz(
        '''
        abstract class C {
          m(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_ABSTRACT_METHOD_DECL,
              element: 'function(C#m)',
              parameters: '(a,b)'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              index: 1),
        ]),
    const Test.clazz(
        '''
        abstract class C {
          get m;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_ABSTRACT_GETTER_DECL,
              element: 'getter(C#m)'),
        ]),
    const Test.clazz(
        '''
        abstract class C {
          set m(a);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_ABSTRACT_SETTER_DECL,
              element: 'setter(C#m)',
              parameters: '(a)'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
        ]),
    const Test(
        '''
        m(a, b) {}
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '(a,b)',
              body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(m#b)',
              index: 1),
        ]),
    const Test(
        '''
        m() {
          local(a, b) {}
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
               element: 'function(m)',
               parameters: '()',
               body: '{local(a,b){}}'),
          const Visit(VisitKind.VISIT_LOCAL_FUNCTION_DECL,
               element: 'function(m#local)',
               parameters: '(a,b)',
               body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(local#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(local#b)',
              index: 1),
        ]),
    const Test(
        '''
        m() => (a, b) {};
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
               element: 'function(m)',
               parameters: '()',
               body: '=>(a,b){};'),
          const Visit(VisitKind.VISIT_CLOSURE_DECL,
               element: 'function(m#)',
               parameters: '(a,b)',
               body: '{}'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
        ]),
  ],
  'Constructor declarations': const [
    const Test.clazz(
        '''
        class C {
          C(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,b)',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
          const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          var b;
          C(a, this.b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,this.b)',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_INITIALIZING_FORMAL_DECL,
              element: 'initializing_formal(#b)',
              index: 1),
          const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          var b;
          C(a, [this.b = 42]);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,[this.b=42])',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_OPTIONAL_INITIALIZING_FORMAL_DECL,
              element: 'initializing_formal(#b)',
              constant: 42,
              index: 1),
          const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          var b;
          C(a, {this.b: 42});
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,{this.b: 42})',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_NAMED_INITIALIZING_FORMAL_DECL,
              element: 'initializing_formal(#b)',
              constant: 42),
          const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          C(a, b) : super();
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,b)',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
          const Visit(VisitKind.VISIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object',
              arguments: '()',
              selector: 'CallStructure(arity=0)'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          var field;
          C(a, b) : this.field = a;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,b)',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
          const Visit(VisitKind.VISIT_FIELD_INITIALIZER,
              element: 'field(C#field)',
              rhs: 'a'),
          const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          var field1;
          var field2;
          C(a, b) : this.field1 = a, this.field2 = b;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,b)',
              body: ';'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
          const Visit(VisitKind.VISIT_FIELD_INITIALIZER,
              element: 'field(C#field1)',
              rhs: 'a'),
          const Visit(VisitKind.VISIT_FIELD_INITIALIZER,
              element: 'field(C#field2)',
              rhs: 'b'),
          const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(Object#)',
              type: 'Object'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          C(a, b) : this._(a, b);
          C._(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_DECL,
              element: 'generative_constructor(C#)',
              parameters: '(a,b)',
              initializers: ':this._(a,b)'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
          const Visit(VisitKind.VISIT_THIS_CONSTRUCTOR_INVOKE,
              element: 'generative_constructor(C#_)',
              arguments: '(a,b)',
              selector: 'CallStructure(arity=2)'),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          factory C(a, b) => null;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_FACTORY_CONSTRUCTOR_DECL,
              element: 'function(C#)',
              parameters: '(a,b)',
              body: '=>null;'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          factory C(a, b) = C._;
          C._(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
              element: 'function(C#)',
              parameters: '(a,b)',
              target: 'generative_constructor(C#_)',
              type: 'C'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          factory C(a, b) = D;
        }
        class D<T> {
          D(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
              element: 'function(C#)',
              parameters: '(a,b)',
              target: 'generative_constructor(D#)',
              type: 'D'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          factory C(a, b) = D<int>;
        }
        class D<T> {
          D(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
              element: 'function(C#)',
              parameters: '(a,b)',
              target: 'generative_constructor(D#)',
              type: 'D<int>'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
        ],
        method: ''),
    const Test.clazz(
        '''
        class C {
          factory C(a, b) = D<int>;
        }
        class D<T> {
          factory D(a, b) = E<D<T>>;
        }
        class E<S> {
          E(a, b);
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
              element: 'function(C#)',
              parameters: '(a,b)',
              target: 'function(D#)',
              type: 'D<int>'),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#a)',
              index: 0),
          const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
              element: 'parameter(#b)',
              index: 1),
        ],
        method: ''),
  ],
  "Field declarations": const [
    const Test.clazz(
        '''
        class C {
          var m;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL,
              element: 'field(C#m)'),
        ]),
    const Test.clazz(
        '''
        class C {
          var m, n;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL,
              element: 'field(C#m)'),
        ]),
    const Test.clazz(
        '''
        class C {
          var m = 42;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL,
              element: 'field(C#m)',
              rhs: 42),
        ]),
    const Test(
        '''
        m() {
          var local;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '()',
              body: '{var local;}'),
          const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
              element: 'variable(m#local)'),
        ]),
    const Test(
        '''
        m() {
          var local = 42;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '()',
              body: '{var local=42;}'),
          const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
              element: 'variable(m#local)',
              rhs: 42),
        ]),
    const Test(
        '''
        m() {
          const local = 42;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '()',
              body: '{const local=42;}'),
          const Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
              element: 'variable(m#local)',
              constant: 42),
        ]),
    const Test(
        '''
        m() {
          var local1, local2;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '()',
              body: '{var local1,local2;}'),
          const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
              element: 'variable(m#local1)'),
          const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
              element: 'variable(m#local2)'),
        ]),
    const Test(
        '''
        m() {
          var local1 = 42, local2 = true;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '()',
              body: '{var local1=42,local2=true;}'),
          const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
              element: 'variable(m#local1)',
              rhs: 42),
          const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
              element: 'variable(m#local2)',
              rhs: true),
        ]),
    const Test(
        '''
        m() {
          const local1 = 42, local2 = true;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
              element: 'function(m)',
              parameters: '()',
              body: '{const local1=42,local2=true;}'),
          const Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
              element: 'variable(m#local1)',
              constant: 42),
          const Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
              element: 'variable(m#local2)',
              constant: true),
        ]),
    const Test.clazz(
        '''
        class C {
          static var m;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
                element: 'field(C#m)'),
        ]),
    const Test.clazz(
        '''
        class C {
          static var m, n;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
                element: 'field(C#m)'),
        ]),
    const Test.clazz(
        '''
        class C {
          static var k, l, m, n;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
                element: 'field(C#m)'),
        ]),
    const Test.clazz(
        '''
        class C {
          static var m = 42;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
                element: 'field(C#m)',
                rhs: 42),
        ]),
    const Test.clazz(
        '''
        class C {
          static var m = 42, n = true;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
                element: 'field(C#m)',
                rhs: 42),
        ]),
    const Test.clazz(
        '''
        class C {
          static const m = 42;
        }
        ''',
        const [
          const Visit(VisitKind.VISIT_STATIC_CONSTANT_DECL,
                element: 'field(C#m)',
                constant: 42),
        ]),
    const Test(
        '''
        var m;
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL,
                element: 'field(m)'),
        ]),
    const Test(
        '''
        var m, n;
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL,
                element: 'field(m)'),
        ]),
    const Test(
        '''
        var m = 42;
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL,
                element: 'field(m)',
                rhs: 42),
        ]),
    const Test(
        '''
        const m = 42;
        ''',
        const [
          const Visit(VisitKind.VISIT_TOP_LEVEL_CONSTANT_DECL,
                element: 'field(m)',
                constant: 42),
        ]),
  ],
};

const List<VisitKind> UNTESTABLE_KINDS = const <VisitKind>[
  VisitKind.VISIT_STATIC_METHOD_SETTER_COMPOUND,
  VisitKind.VISIT_STATIC_METHOD_SETTER_PREFIX,
  VisitKind.VISIT_STATIC_METHOD_SETTER_POSTFIX,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_COMPOUND,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_PREFIX,
  VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_POSTFIX,
  VisitKind.VISIT_SUPER_FIELD_FIELD_COMPOUND,
  VisitKind.VISIT_SUPER_FIELD_FIELD_PREFIX,
  VisitKind.VISIT_SUPER_FIELD_FIELD_POSTFIX,
  VisitKind.VISIT_SUPER_METHOD_SETTER_COMPOUND,
  VisitKind.VISIT_SUPER_METHOD_SETTER_PREFIX,
  VisitKind.VISIT_SUPER_METHOD_SETTER_POSTFIX,
  VisitKind.VISIT_CLASS_TYPE_LITERAL_SET,
  VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET,
  VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
  VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET,
  VisitKind.VISIT_FINAL_PARAMETER_SET,
  VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET,
  VisitKind.VISIT_LOCAL_FUNCTION_SET,
  VisitKind.VISIT_STATIC_GETTER_SET,
  VisitKind.VISIT_STATIC_SETTER_GET,
  VisitKind.VISIT_STATIC_SETTER_INVOKE,
  VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
  VisitKind.VISIT_STATIC_FUNCTION_SET,
  VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
  VisitKind.VISIT_TOP_LEVEL_GETTER_SET,
  VisitKind.VISIT_TOP_LEVEL_SETTER_GET,
  VisitKind.VISIT_TOP_LEVEL_SETTER_INVOKE,
  VisitKind.VISIT_TOP_LEVEL_FUNCTION_SET,
  VisitKind.VISIT_FINAL_SUPER_FIELD_SET,
  VisitKind.VISIT_SUPER_GETTER_SET,
  VisitKind.VISIT_SUPER_SETTER_GET,
  VisitKind.VISIT_SUPER_SETTER_INVOKE,
  VisitKind.VISIT_SUPER_METHOD_SET,
];

main(List<String> arguments) {
  Set<VisitKind> kinds = new Set<VisitKind>.from(VisitKind.values);
  asyncTest(() => Future.forEach([
    () {
      return test(
          kinds,
          arguments,
          SEND_TESTS,
          (elements) => new SemanticSendTestVisitor(elements));
    },
    () {
      return test(
          kinds,
          arguments,
          DECL_TESTS,
          (elements) => new SemanticDeclarationTestVisitor(elements));
    },
    () {
      Set<VisitKind> unvisitedKindSet =
          kinds.toSet()..removeAll(UNTESTABLE_KINDS);
      List<VisitKind> unvisitedKindList = unvisitedKindSet.toList();
      unvisitedKindList..sort((a, b) => a.index.compareTo(b.index));

      Expect.isTrue(unvisitedKindList.isEmpty,
          "Untested visit kinds:\n  ${unvisitedKindList.join(',\n  ')},\n");

      Set<VisitKind> testedUntestableKinds =
          UNTESTABLE_KINDS.toSet()..removeAll(kinds);
      Expect.isTrue(testedUntestableKinds.isEmpty,
          "Tested untestable visit kinds (remove from UNTESTABLE_KINDS):\n  "
          "${testedUntestableKinds.join(',\n  ')},\n");
    },
    () {
      ClassMirror mirror1 = reflectType(SemanticSendTestVisitor);
      Set<Symbol> symbols1 = mirror1.declarations.keys.toSet();
      ClassMirror mirror2 = reflectType(SemanticSendVisitor);
      Set<Symbol> symbols2 =
          mirror2.declarations.values
              .where((m) => m is MethodMirror &&
                            !m.isConstructor &&
                            m.simpleName != #apply)
              .map((m) => m.simpleName).toSet();
      symbols2.removeAll(symbols1);
      print("Untested visit methods:\n  ${symbols2.join(',\n  ')},\n");
    }
  ], (f) => f()));
}

Future test(Set<VisitKind> unvisitedKinds,
            List<String> arguments,
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
      Element element;
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

      void testAstElement(AstElement astElement) {
        Expect.isNotNull(astElement, "Element '$method' not found in:\n"
                                     "${library.compilationUnit.script.text}");
        ResolvedAst resolvedAst = astElement.resolvedAst;
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
        unvisitedKinds.removeAll(visitor.visits.map((visit) => visit.method));
      }
      if (element.isAbstractField) {
        AbstractFieldElement abstractFieldElement = element;
        if (abstractFieldElement.getter != null) {
          testAstElement(abstractFieldElement.getter);
        } else if (abstractFieldElement.setter != null) {
          testAstElement(abstractFieldElement.setter);
        }
      } else {
        testAstElement(element);
      }
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitClassTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), rhs: rhs));
    super.visitClassTypeLiteralSet(node, constant, rhs, arg);
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
    super.visitDynamicPropertySet(node, receiver, selector, rhs, arg);
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), arguments: arguments));
  }

  @override
  visitDynamicTypeLiteralSet(
      Send node,
      ConstantExpression constant,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET,
        rhs: rhs));
    super.visitDynamicTypeLiteralSet(node, constant, rhs, arg);
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
  visitLocalFunctionSet(
      SendSet node,
      LocalFunctionElement function,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_SET,
        element: function, rhs: rhs));
    super.visitLocalFunctionSet(node, function, rhs, arg);
  }

  @override
  visitLocalFunctionInvoke(
      Send node,
      LocalFunctionElement function,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_INVOKE,
        element: function, arguments: arguments, selector: callStructure));
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_INVOKE,
        element: variable, arguments: arguments, selector: callStructure));
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
    super.visitLocalVariableSet(node, variable, rhs, arg);
  }

  @override
  visitFinalLocalVariableSet(
      SendSet node,
      LocalVariableElement variable,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET,
        element: variable, rhs: rhs));
    super.visitFinalLocalVariableSet(node, variable, rhs, arg);
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_PARAMETER_INVOKE,
        element: parameter, arguments: arguments, selector: callStructure));
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
    super.visitParameterSet(node, parameter, rhs, arg);
  }

  @override
  visitFinalParameterSet(
      SendSet node,
      ParameterElement parameter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_SET,
                         element: parameter, rhs: rhs));
    super.visitFinalParameterSet(node, parameter, rhs, arg);
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
      CallStructure callStructure,
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
    super.visitStaticFieldSet(node, field, rhs, arg);
  }

  @override
  visitFinalStaticFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
        element: field, rhs: rhs));
    super.visitFinalStaticFieldSet(node, field, rhs, arg);
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
  visitStaticFunctionSet(
      SendSet node,
      MethodElement function,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_SET,
        element: function, rhs: rhs));
    super.visitStaticFunctionSet(node, function, rhs, arg);
  }

  @override
  visitStaticFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
        element: function, arguments: arguments));
    super.visitStaticFunctionInvoke(
        node, function, arguments, callStructure, arg);
  }

  @override
  visitStaticFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_INCOMPATIBLE_INVOKE,
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
    super.visitStaticGetterGet(node, getter, arg);
  }

  @override
  visitStaticGetterSet(
      SendSet node,
      MethodElement getter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_SET,
        element: getter, rhs: rhs));
    super.visitStaticGetterSet(node, getter, rhs, arg);
  }

  @override
  visitStaticGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
        element: getter, arguments: arguments));
    super.visitStaticGetterInvoke(node, getter, arguments, callStructure, arg);
  }

  @override
  visitStaticSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_INVOKE,
        element: setter, arguments: arguments));
    super.visitStaticSetterInvoke(node, setter, arguments, callStructure, arg);
  }

  @override
  visitStaticSetterGet(
      Send node,
      FunctionElement getter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_GET,
        element: getter));
    super.visitStaticSetterGet(node, getter, arg);
  }

  @override
  visitStaticSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_SET,
        element: setter, rhs: rhs));
    super.visitStaticSetterSet(node, setter, rhs, arg);
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
  visitUnresolvedSuperBinary(
      Send node,
      Element element,
      BinaryOperator operator,
      Node argument,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_BINARY,
        operator: operator, right: argument));
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
  visitUnresolvedSuperIndex(
      Send node,
      Element element,
      Node index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX,
        index: index));
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
      CallStructure callStructure,
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
      CallStructure callStructure,
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
    super.visitTopLevelFieldSet(node, field, rhs, arg);
  }

  @override
  visitFinalTopLevelFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
        element: field, rhs: rhs));
    super.visitFinalTopLevelFieldSet(node, field, rhs, arg);
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
  visitTopLevelFunctionSet(
      SendSet node,
      MethodElement function,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_SET,
        element: function, rhs: rhs));
    super.visitTopLevelFunctionSet(node, function, rhs, arg);
  }

  @override
  visitTopLevelFunctionInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
        element: function, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTopLevelFunctionIncompatibleInvoke(
      Send node,
      MethodElement function,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INCOMPATIBLE_INVOKE,
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
    super.visitTopLevelGetterGet(node, getter, arg);
  }

  @override
  visitTopLevelSetterGet(
      Send node,
      FunctionElement setter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_GET,
        element: setter));
    super.visitTopLevelSetterGet(node, setter, arg);
  }

  @override
  visitTopLevelGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
        element: getter, arguments: arguments));
    super.visitTopLevelGetterInvoke(
        node, getter, arguments, callStructure, arg);
  }

  @override
  visitTopLevelSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_INVOKE,
        element: setter, arguments: arguments));
    super.visitTopLevelSetterInvoke(
        node, setter, arguments, callStructure, arg);
  }

  @override
  visitTopLevelGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SET,
        element: getter, rhs: rhs));
    super.visitTopLevelGetterSet(node, getter, rhs, arg);
  }

  @override
  visitTopLevelSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
        element: setter, rhs: rhs));
    super.visitTopLevelSetterSet(node, setter, rhs, arg);
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
        element: element, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTypeVariableTypeLiteralSet(
      SendSet node,
      TypeVariableElement element,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
        element: element, rhs: rhs));
    super.visitTypeVariableTypeLiteralSet(node, element, rhs, arg);
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
        constant: constant.getText(), arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitTypedefTypeLiteralSet(
      SendSet node,
      ConstantExpression constant,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET,
        constant: constant.getText(), rhs: rhs));
    super.visitTypedefTypeLiteralSet(node, constant, rhs, arg);
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
  visitUnresolvedSuperGet(
      Send node,
      Element element,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GET));
  }

  @override
  visitSuperFieldInvoke(
      Send node,
      FieldElement field,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_INVOKE,
        element: field, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedSuperInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INVOKE,
        arguments: arguments));
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
    super.visitSuperFieldSet(node, field, rhs, arg);
  }

  @override
  visitFinalSuperFieldSet(
      SendSet node,
      FieldElement field,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_SUPER_FIELD_SET,
        element: field, rhs: rhs));
    super.visitFinalSuperFieldSet(node, field, rhs, arg);
  }

  @override
  visitSuperMethodGet(
      Send node,
      MethodElement method,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_GET, element: method));
  }

  @override
  visitSuperMethodSet(
      SendSet node,
      MethodElement method,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SET,
        element: method, rhs: rhs));
    super.visitSuperMethodSet(node, method, rhs, arg);
  }

  @override
  visitSuperMethodInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_INVOKE,
        element: method, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperMethodIncompatibleInvoke(
      Send node,
      MethodElement method,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_INCOMPATIBLE_INVOKE,
        element: method, arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitSuperGetterGet(
      Send node,
      FunctionElement getter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_GET, element: getter));
    super.visitSuperGetterGet(node, getter, arg);
  }

  @override
  visitSuperSetterGet(
      Send node,
      FunctionElement setter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_SETTER_GET, element: setter));
    super.visitSuperSetterGet(node, setter, arg);
  }

  @override
  visitSuperGetterInvoke(
      Send node,
      FunctionElement getter,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_INVOKE,
        element: getter, arguments: arguments));
    super.visitSuperGetterInvoke(node, getter, arguments, callStructure, arg);
  }

  @override
  visitSuperSetterInvoke(
      Send node,
      FunctionElement setter,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_SETTER_INVOKE,
        element: setter, arguments: arguments));
    super.visitSuperSetterInvoke(node, setter, arguments, callStructure, arg);
  }

  @override
  visitSuperGetterSet(
      SendSet node,
      FunctionElement getter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_GETTER_SET,
        element: getter, rhs: rhs));
    super.visitSuperGetterSet(node, getter, rhs, arg);
  }

  @override
  visitSuperSetterSet(
      SendSet node,
      FunctionElement setter,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_SETTER_SET,
        element: setter, rhs: rhs));
    super.visitSuperSetterSet(node, setter, rhs, arg);
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
  visitUnresolvedSuperUnary(
      Send node,
      UnaryOperator operator,
      Element element,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_UNARY,
        operator: operator));
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
  visitFinalLocalVariableCompound(
      Send node,
      LocalVariableElement variable,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_COMPOUND,
        element: variable, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalLocalVariablePrefix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_PREFIX,
        element: variable, operator: operator));
  }

  @override
  visitFinalLocalVariablePostfix(
      Send node,
      LocalVariableElement variable,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_POSTFIX,
        element: variable, operator: operator));
  }

  @override
  visitFinalParameterCompound(
      Send node,
      ParameterElement parameter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_COMPOUND,
        element: parameter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalParameterPrefix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_PREFIX,
        element: parameter, operator: operator));
  }

  @override
  visitFinalParameterPostfix(
      Send node,
      ParameterElement parameter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FINAL_PARAMETER_POSTFIX,
        element: parameter, operator: operator));
  }

  @override
  visitFinalStaticFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalStaticFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalStaticFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalSuperFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalTopLevelFieldCompound(
      Send node,
      FieldElement field,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_COMPOUND,
        element: field, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitFinalTopLevelFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_POSTFIX,
        element: field, operator: operator));
  }

  @override
  visitFinalTopLevelFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_PREFIX,
        element: field, operator: operator));
  }

  @override
  visitLocalFunctionCompound(
      Send node,
      LocalFunctionElement function,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_COMPOUND,
        element: function, operator: operator, rhs: rhs));
    apply(rhs, arg);
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
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_COMPOUND,
        getter: method, setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodCompound(
      Send node,
      FunctionElement method,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_COMPOUND,
        element: method, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperMethodPrefix(
      Send node,
      FunctionElement method,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_PREFIX,
        element: method, operator: operator));
  }

  @override
  visitSuperMethodPostfix(
      Send node,
      FunctionElement method,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_POSTFIX,
        element: method, operator: operator));
  }

  @override
  visitUnresolvedSuperCompound(
      Send node,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_COMPOUND,
        operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperPrefix(
      Send node,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_PREFIX,
        operator: operator));
  }

  @override
  visitUnresolvedSuperPostfix(
      Send node,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_POSTFIX,
        operator: operator));
  }

  @override
  visitTopLevelMethodSetterCompound(
      Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_COMPOUND,
        getter: method, setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
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
  visitClassTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_COMPOUND,
        constant: constant.getText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitDynamicTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
        constant: constant.getText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTypeVariableTypeLiteralCompound(
      Send node,
      TypeVariableElement element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
        element: element, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTypedefTypeLiteralCompound(
      Send node,
      ConstantExpression constant,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
        constant: constant.getText(), operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitLocalFunctionPrefix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_PREFIX,
        element: function, operator: operator));
  }

  @override
  visitClassTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_PREFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitDynamicTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_PREFIX,
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
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_PREFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperFieldFieldCompound(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_COMPOUND,
        getter: readField, setter: writtenField, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitSuperFieldFieldPrefix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_PREFIX,
        getter: readField, setter: writtenField, operator: operator));
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
  visitFinalSuperFieldPrefix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_PREFIX,
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
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_PREFIX,
        getter: method, setter: setter, operator: operator));
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
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_PREFIX,
        getter: method, setter: setter, operator: operator));
  }

  @override
  visitTypeVariableTypeLiteralPrefix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
        element: element, operator: operator));
  }

  @override
  visitTypedefTypeLiteralPrefix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_PREFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitLocalFunctionPostfix(
      Send node,
      LocalFunctionElement function,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_POSTFIX,
        element: function, operator: operator));
  }

  @override
  visitClassTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_POSTFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitDynamicTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_POSTFIX,
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
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_POSTFIX,
        getter: getter, setter: setter, operator: operator));
  }

  @override
  visitSuperFieldFieldPostfix(
      Send node,
      FieldElement readField,
      FieldElement writtenField,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FIELD_FIELD_POSTFIX,
        getter: readField, setter: writtenField, operator: operator));
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
  visitFinalSuperFieldPostfix(
      Send node,
      FieldElement field,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_POSTFIX,
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
    visits.add(new Visit(VisitKind.VISIT_SUPER_METHOD_SETTER_POSTFIX,
        getter: method, setter: setter, operator: operator));
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
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SETTER_POSTFIX,
        getter: method, setter: setter, operator: operator));
  }

  @override
  visitTypeVariableTypeLiteralPostfix(
      Send node,
      TypeVariableElement element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,
        element: element, operator: operator));
  }

  @override
  visitTypedefTypeLiteralPostfix(
      Send node,
      ConstantExpression constant,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_POSTFIX,
        constant: constant.getText(), operator: operator));
  }

  @override
  visitUnresolvedCompound(
      Send node,
      ErroneousElement element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_COMPOUND,
        operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedGet(
      Send node,
      Element element,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_GET, name: element.name));
  }

  @override
  visitUnresolvedSet(
      Send node,
      Element element,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SET,
                         name: element.name, rhs: rhs));
    super.visitUnresolvedSet(node, element, rhs, arg);
  }

  @override
  visitUnresolvedInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
                         name: element.name, arguments: arguments));
    super.visitUnresolvedInvoke(node, element, arguments, selector, arg);
  }

  @override
  visitUnresolvedPostfix(
      Send node,
      ErroneousElement element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_POSTFIX, operator: operator));
  }

  @override
  visitUnresolvedPrefix(
      Send node,
      ErroneousElement element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_PREFIX, operator: operator));
  }

  @override
  visitUnresolvedSuperCompoundIndexSet(
      Send node,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_COMPOUND_INDEX_SET,
        index: index, operator: operator, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperGetterCompoundIndexSet(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND_INDEX_SET,
        setter: setter, index: index, operator: operator, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperSetterCompoundIndexSet(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND_INDEX_SET,
        getter: getter, index: index, operator: operator, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperIndexSet(
      Send node,
      ErroneousElement element,
      Node index,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_SET,
               index: index, rhs: rhs));
    apply(index, arg);
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperIndexPostfix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_POSTFIX,
               index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperGetterIndexPostfix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_POSTFIX,
               setter: setter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperSetterIndexPostfix(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_POSTFIX,
               getter: getter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperIndexPrefix(
      Send node,
      Element element,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_PREFIX,
               index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperGetterIndexPrefix(
      Send node,
      Element element,
      MethodElement setter,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_PREFIX,
               setter: setter, index: index, operator: operator));
    apply(index, arg);
  }

  @override
  visitUnresolvedSuperSetterIndexPrefix(
      Send node,
      MethodElement getter,
      Element element,
      Node index,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_PREFIX,
               getter: getter, index: index, operator: operator));
    apply(index, arg);
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
  visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO(johnniwinther): Test [type] when it is not `dynamic`.
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO(johnniwinther): Test [type] when it is not `dynamic`.
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        target: effectiveTarget,
        targetType: effectiveTargetType,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedStaticGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_COMPOUND,
        setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedTopLevelGetterCompound(
      Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_COMPOUND,
        setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedStaticSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_COMPOUND,
        getter: getter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedTopLevelSetterCompound(
      Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_COMPOUND,
        getter: getter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitStaticMethodCompound(
      Send node,
      MethodElement method,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_COMPOUND,
        element: method, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitTopLevelMethodCompound(
      Send node,
      MethodElement method,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_COMPOUND,
        element: method, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedStaticGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_PREFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_PREFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedStaticSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_PREFIX,
        getter: getter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_PREFIX,
        getter: getter, operator: operator));
  }

  @override
  visitStaticMethodPrefix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_PREFIX,
        element: method, operator: operator));
  }

  @override
  visitTopLevelMethodPrefix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_PREFIX,
        element: method, operator: operator));
  }

  @override
  visitUnresolvedStaticGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_POSTFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_POSTFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedStaticSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_POSTFIX,
        getter: getter, operator: operator));
  }

  @override
  visitUnresolvedTopLevelSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_POSTFIX,
        getter: getter, operator: operator));
  }

  @override
  visitStaticMethodPostfix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_METHOD_POSTFIX,
        element: method, operator: operator));
  }

  @override
  visitTopLevelMethodPostfix(
      Send node,
      MethodElement method,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_POSTFIX,
        element: method, operator: operator));
  }

  @override
  visitUnresolvedSuperGetterCompound(
      Send node, Element element,
      MethodElement setter,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND,
        setter: setter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperGetterPostfix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_POSTFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedSuperGetterPrefix(
      Send node,
      Element element,
      MethodElement setter,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_PREFIX,
        setter: setter, operator: operator));
  }

  @override
  visitUnresolvedSuperSetterCompound(
      Send node, MethodElement getter,
      Element element,
      AssignmentOperator operator,
      Node rhs,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND,
        getter: getter, operator: operator, rhs: rhs));
    apply(rhs, arg);
  }

  @override
  visitUnresolvedSuperSetterPostfix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_POSTFIX,
        getter: getter, operator: operator));
  }

  @override
  visitUnresolvedSuperSetterPrefix(
      Send node,
      MethodElement getter,
      Element element,
      IncDecOperator operator,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_PREFIX,
        getter: getter, operator: operator));
  }
}

class SemanticDeclarationTestVisitor extends SemanticTestVisitor {

  SemanticDeclarationTestVisitor(TreeElements elements) : super(elements);

  @override
  errorUnresolvedSuperConstructorInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement errorUnresolvedSuperConstructorInvoke
  }

  @override
  errorUnresolvedThisConstructorInvoke(
      Send node,
      Element element,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO: implement errorUnresolvedThisConstructorInvoke
  }

  @override
  visitAbstractMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_ABSTRACT_METHOD_DECL,
        element: method, parameters: parameters));
    applyParameters(parameters, arg);
  }

  @override
  visitClosureDeclaration(
      FunctionExpression node,
      LocalFunctionElement function,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_CLOSURE_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FACTORY_CONSTRUCTOR_DECL,
        element: constructor, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitFieldInitializer(
      SendSet node,
      FieldElement field,
      Node initializer,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_FIELD_INITIALIZER,
        element: field, rhs: initializer));
    apply(initializer, arg);
  }

  @override
  visitGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
        element: constructor, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    applyInitializers(node, arg);
    apply(body, arg);
  }

  @override
  visitInstanceMethodDeclaration(
      FunctionExpression node,
      MethodElement method,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_METHOD_DECL,
        element: method, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitLocalFunctionDeclaration(
      FunctionExpression node,
      LocalFunctionElement function,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_FUNCTION_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitRedirectingFactoryConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      InterfaceType redirectionType,
      ConstructorElement redirectionTarget,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
        element: constructor,
        parameters: parameters,
        target: redirectionTarget,
        type: redirectionType));
    applyParameters(parameters, arg);
  }

  @override
  visitRedirectingGenerativeConstructorDeclaration(
      FunctionExpression node,
      ConstructorElement constructor,
      NodeList parameters,
      NodeList initializers,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_DECL,
        element: constructor,
        parameters: parameters,
        initializers: initializers));
    applyParameters(parameters, arg);
    applyInitializers(node, arg);
  }

  @override
  visitStaticFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FUNCTION_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitSuperConstructorInvoke(
      Send node,
      ConstructorElement superConstructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_SUPER_CONSTRUCTOR_INVOKE,
        element: superConstructor, type: type,
        arguments: arguments, selector: callStructure));
    super.visitSuperConstructorInvoke(
        node, superConstructor, type, arguments, callStructure, arg);
  }

  @override
  visitImplicitSuperConstructorInvoke(
      FunctionExpression node,
      ConstructorElement superConstructor,
      InterfaceType type,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
        element: superConstructor, type: type));
    super.visitImplicitSuperConstructorInvoke(
        node, superConstructor, type, arg);
  }

  @override
  visitThisConstructorInvoke(
      Send node,
      ConstructorElement thisConstructor,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_THIS_CONSTRUCTOR_INVOKE,
        element: thisConstructor,
        arguments: arguments, selector: callStructure));
    super.visitThisConstructorInvoke(
        node, thisConstructor, arguments, callStructure, arg);
  }

  @override
  visitTopLevelFunctionDeclaration(
      FunctionExpression node,
      MethodElement function,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
        element: function, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  errorUnresolvedFieldInitializer(
      SendSet node,
      Element element,
      Node initializer,
      arg) {
    // TODO: implement errorUnresolvedFieldInitializer
  }

  @override
  visitOptionalParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      int index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
        element: parameter,
        constant: defaultValue != null ? defaultValue.getText() : null,
        index: index));
  }

  @override
  visitParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      int index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
        element: parameter, index: index));
  }

  @override
  visitInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      int index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_REQUIRED_INITIALIZING_FORMAL_DECL,
        element: initializingFormal, index: index));
  }

  @override
  visitLocalVariableDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      Node initializer,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
        element: variable, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitLocalConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      LocalVariableElement variable,
      ConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
        element: variable, constant: constant.getText()));
  }

  @override
  visitNamedInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      ConstantExpression defaultValue,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_NAMED_INITIALIZING_FORMAL_DECL,
        element: initializingFormal,
        constant: defaultValue != null ? defaultValue.getText() : null));
  }

  @override
  visitNamedParameterDeclaration(
      VariableDefinitions node,
      Node definition,
      ParameterElement parameter,
      ConstantExpression defaultValue,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
        element: parameter,
        constant: defaultValue != null ? defaultValue.getText() : null));
  }

  @override
  visitOptionalInitializingFormalDeclaration(
      VariableDefinitions node,
      Node definition,
      InitializingFormalElement initializingFormal,
      ConstantExpression defaultValue,
      int index,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_OPTIONAL_INITIALIZING_FORMAL_DECL,
        element: initializingFormal,
        constant: defaultValue != null ? defaultValue.getText() : null,
        index: index));
  }

  @override
  visitInstanceFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL,
        element: field, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitStaticConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_CONSTANT_DECL,
        element: field, constant: constant.getText()));
  }

  @override
  visitStaticFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
        element: field, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitTopLevelConstantDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      ConstantExpression constant,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_CONSTANT_DECL,
        element: field, constant: constant.getText()));
  }

  @override
  visitTopLevelFieldDeclaration(
      VariableDefinitions node,
      Node definition,
      FieldElement field,
      Node initializer,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL,
        element: field, rhs: initializer));
    if (initializer != null) {
      apply(initializer, arg);
    }
  }

  @override
  visitAbstractGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_ABSTRACT_GETTER_DECL,
        element: getter));
  }

  @override
  visitAbstractSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_ABSTRACT_SETTER_DECL,
        element: setter, parameters: parameters));
    applyParameters(parameters, arg);
  }

  @override
  visitInstanceGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_GETTER_DECL,
        element: getter, body: body));
    apply(body, arg);
  }

  @override
  visitInstanceSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_INSTANCE_SETTER_DECL,
        element: setter, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitTopLevelGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_DECL,
        element: getter, body: body));
    apply(body, arg);
  }

  @override
  visitTopLevelSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_DECL,
        element: setter, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitStaticGetterDeclaration(
      FunctionExpression node,
      MethodElement getter,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_GETTER_DECL,
        element: getter, body: body));
    apply(body, arg);
  }

  @override
  visitStaticSetterDeclaration(
      FunctionExpression node,
      MethodElement setter,
      NodeList parameters,
      Node body,
      arg) {
    visits.add(new Visit(VisitKind.VISIT_STATIC_SETTER_DECL,
        element: setter, parameters: parameters, body: body));
    applyParameters(parameters, arg);
    apply(body, arg);
  }

  @override
  visitUnresolvedClassConstructorInvoke(
      NewExpression node,
      Element constructor,
      MalformedType type,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO(johnniwinther): Test [type] and [selector].
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
        arguments: arguments));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedConstructorInvoke(
      NewExpression node,
      Element constructor,
      DartType type,
      NodeList arguments,
      Selector selector,
      arg) {
    // TODO(johnniwinther): Test [type] and [selector].
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
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
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        target: effectiveTarget,
        targetType: effectiveTargetType,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitRedirectingGenerativeConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitAbstractClassConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
    apply(arguments, arg);
  }

  @override
  visitUnresolvedRedirectingFactoryConstructorInvoke(
      NewExpression node,
      ConstructorElement constructor,
      InterfaceType type,
      NodeList arguments,
      CallStructure callStructure,
      arg) {
    visits.add(new Visit(
        VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
        element: constructor,
        type: type,
        arguments: arguments,
        selector: callStructure));
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
  VISIT_FINAL_PARAMETER_SET,
  VISIT_FINAL_PARAMETER_COMPOUND,
  VISIT_FINAL_PARAMETER_PREFIX,
  VISIT_FINAL_PARAMETER_POSTFIX,

  VISIT_LOCAL_VARIABLE_GET,
  VISIT_LOCAL_VARIABLE_SET,
  VISIT_LOCAL_VARIABLE_INVOKE,
  VISIT_LOCAL_VARIABLE_COMPOUND,
  VISIT_LOCAL_VARIABLE_PREFIX,
  VISIT_LOCAL_VARIABLE_POSTFIX,
  VISIT_LOCAL_VARIABLE_DECL,
  VISIT_LOCAL_CONSTANT_DECL,
  VISIT_FINAL_LOCAL_VARIABLE_SET,
  VISIT_FINAL_LOCAL_VARIABLE_COMPOUND,
  VISIT_FINAL_LOCAL_VARIABLE_PREFIX,
  VISIT_FINAL_LOCAL_VARIABLE_POSTFIX,

  VISIT_LOCAL_FUNCTION_GET,
  VISIT_LOCAL_FUNCTION_INVOKE,
  VISIT_LOCAL_FUNCTION_DECL,
  VISIT_CLOSURE_DECL,
  VISIT_LOCAL_FUNCTION_SET,
  VISIT_LOCAL_FUNCTION_COMPOUND,
  VISIT_LOCAL_FUNCTION_PREFIX,
  VISIT_LOCAL_FUNCTION_POSTFIX,

  VISIT_STATIC_FIELD_GET,
  VISIT_STATIC_FIELD_SET,
  VISIT_STATIC_FIELD_INVOKE,
  VISIT_STATIC_FIELD_COMPOUND,
  VISIT_STATIC_FIELD_PREFIX,
  VISIT_STATIC_FIELD_POSTFIX,
  VISIT_STATIC_FIELD_DECL,
  VISIT_STATIC_CONSTANT_DECL,

  VISIT_STATIC_GETTER_GET,
  VISIT_STATIC_GETTER_SET,
  VISIT_STATIC_GETTER_INVOKE,

  VISIT_STATIC_SETTER_GET,
  VISIT_STATIC_SETTER_SET,
  VISIT_STATIC_SETTER_INVOKE,

  VISIT_STATIC_GETTER_SETTER_COMPOUND,
  VISIT_STATIC_METHOD_SETTER_COMPOUND,
  VISIT_STATIC_GETTER_SETTER_PREFIX,
  VISIT_STATIC_GETTER_SETTER_POSTFIX,

  VISIT_STATIC_GETTER_DECL,
  VISIT_STATIC_SETTER_DECL,

  VISIT_FINAL_STATIC_FIELD_SET,
  VISIT_STATIC_FINAL_FIELD_COMPOUND,
  VISIT_STATIC_FINAL_FIELD_POSTFIX,
  VISIT_STATIC_FINAL_FIELD_PREFIX,

  VISIT_STATIC_FUNCTION_GET,
  VISIT_STATIC_FUNCTION_SET,
  VISIT_STATIC_FUNCTION_INVOKE,
  VISIT_STATIC_FUNCTION_INCOMPATIBLE_INVOKE,
  VISIT_STATIC_FUNCTION_DECL,
  VISIT_STATIC_METHOD_SETTER_PREFIX,
  VISIT_STATIC_METHOD_SETTER_POSTFIX,

  VISIT_UNRESOLVED_STATIC_GETTER_COMPOUND,
  VISIT_UNRESOLVED_STATIC_SETTER_COMPOUND,
  VISIT_STATIC_METHOD_COMPOUND,
  VISIT_UNRESOLVED_STATIC_GETTER_PREFIX,
  VISIT_UNRESOLVED_STATIC_SETTER_PREFIX,
  VISIT_STATIC_METHOD_PREFIX,
  VISIT_UNRESOLVED_STATIC_GETTER_POSTFIX,
  VISIT_UNRESOLVED_STATIC_SETTER_POSTFIX,
  VISIT_STATIC_METHOD_POSTFIX,

  VISIT_TOP_LEVEL_FIELD_GET,
  VISIT_TOP_LEVEL_FIELD_SET,
  VISIT_TOP_LEVEL_FIELD_INVOKE,
  VISIT_FINAL_TOP_LEVEL_FIELD_SET,
  VISIT_TOP_LEVEL_FIELD_COMPOUND,
  VISIT_TOP_LEVEL_FIELD_PREFIX,
  VISIT_TOP_LEVEL_FIELD_POSTFIX,
  VISIT_TOP_LEVEL_FIELD_DECL,
  VISIT_TOP_LEVEL_CONSTANT_DECL,
  VISIT_TOP_LEVEL_FINAL_FIELD_COMPOUND,
  VISIT_TOP_LEVEL_FINAL_FIELD_POSTFIX,
  VISIT_TOP_LEVEL_FINAL_FIELD_PREFIX,

  VISIT_TOP_LEVEL_GETTER_GET,
  VISIT_TOP_LEVEL_GETTER_SET,
  VISIT_TOP_LEVEL_GETTER_INVOKE,
  VISIT_TOP_LEVEL_SETTER_GET,
  VISIT_TOP_LEVEL_SETTER_SET,
  VISIT_TOP_LEVEL_SETTER_INVOKE,
  VISIT_TOP_LEVEL_GETTER_SETTER_COMPOUND,
  VISIT_TOP_LEVEL_GETTER_SETTER_PREFIX,
  VISIT_TOP_LEVEL_GETTER_SETTER_POSTFIX,
  VISIT_TOP_LEVEL_GETTER_DECL,
  VISIT_TOP_LEVEL_SETTER_DECL,

  VISIT_TOP_LEVEL_FUNCTION_GET,
  VISIT_TOP_LEVEL_FUNCTION_SET,
  VISIT_TOP_LEVEL_FUNCTION_INVOKE,
  VISIT_TOP_LEVEL_FUNCTION_INCOMPATIBLE_INVOKE,
  VISIT_TOP_LEVEL_FUNCTION_DECL,
  VISIT_TOP_LEVEL_METHOD_SETTER_COMPOUND,
  VISIT_TOP_LEVEL_METHOD_SETTER_PREFIX,
  VISIT_TOP_LEVEL_METHOD_SETTER_POSTFIX,

  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_COMPOUND,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_COMPOUND,
  VISIT_TOP_LEVEL_METHOD_COMPOUND,
  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_PREFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_PREFIX,
  VISIT_TOP_LEVEL_METHOD_PREFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_GETTER_POSTFIX,
  VISIT_UNRESOLVED_TOP_LEVEL_SETTER_POSTFIX,
  VISIT_TOP_LEVEL_METHOD_POSTFIX,

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
  VISIT_FINAL_SUPER_FIELD_SET,
  VISIT_SUPER_FIELD_INVOKE,
  VISIT_SUPER_FIELD_COMPOUND,
  VISIT_SUPER_FIELD_PREFIX,
  VISIT_SUPER_FIELD_POSTFIX,
  VISIT_SUPER_FINAL_FIELD_COMPOUND,
  VISIT_SUPER_FINAL_FIELD_PREFIX,
  VISIT_SUPER_FINAL_FIELD_POSTFIX,
  VISIT_SUPER_FIELD_FIELD_COMPOUND,
  VISIT_SUPER_FIELD_FIELD_PREFIX,
  VISIT_SUPER_FIELD_FIELD_POSTFIX,

  VISIT_SUPER_GETTER_GET,
  VISIT_SUPER_GETTER_SET,
  VISIT_SUPER_GETTER_INVOKE,
  VISIT_SUPER_SETTER_GET,
  VISIT_SUPER_SETTER_SET,
  VISIT_SUPER_SETTER_INVOKE,
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
  VISIT_SUPER_METHOD_SET,
  VISIT_SUPER_METHOD_INVOKE,
  VISIT_SUPER_METHOD_INCOMPATIBLE_INVOKE,
  VISIT_SUPER_METHOD_SETTER_COMPOUND,
  VISIT_SUPER_METHOD_SETTER_PREFIX,
  VISIT_SUPER_METHOD_SETTER_POSTFIX,
  VISIT_SUPER_METHOD_COMPOUND,
  VISIT_SUPER_METHOD_PREFIX,
  VISIT_SUPER_METHOD_POSTFIX,

  VISIT_UNRESOLVED_GET,
  VISIT_UNRESOLVED_SET,
  VISIT_UNRESOLVED_INVOKE,
  VISIT_UNRESOLVED_SUPER_GET,
  VISIT_UNRESOLVED_SUPER_INVOKE,

  VISIT_BINARY,
  VISIT_INDEX,
  VISIT_EQUALS,
  VISIT_NOT_EQUALS,
  VISIT_INDEX_PREFIX,
  VISIT_INDEX_POSTFIX,

  VISIT_SUPER_BINARY,
  VISIT_UNRESOLVED_SUPER_BINARY,
  VISIT_SUPER_INDEX,
  VISIT_UNRESOLVED_SUPER_INDEX,
  VISIT_SUPER_EQUALS,
  VISIT_SUPER_NOT_EQUALS,
  VISIT_SUPER_INDEX_PREFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND,
  VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND,
  VISIT_UNRESOLVED_SUPER_GETTER_PREFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_PREFIX,
  VISIT_UNRESOLVED_SUPER_INDEX_PREFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_INDEX_PREFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_INDEX_PREFIX,
  VISIT_SUPER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_POSTFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_POSTFIX,
  VISIT_UNRESOLVED_SUPER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_GETTER_INDEX_POSTFIX,
  VISIT_UNRESOLVED_SUPER_SETTER_INDEX_POSTFIX,

  VISIT_UNRESOLVED_SUPER_COMPOUND,
  VISIT_UNRESOLVED_SUPER_PREFIX,
  VISIT_UNRESOLVED_SUPER_POSTFIX,

  VISIT_UNARY,
  VISIT_SUPER_UNARY,
  VISIT_UNRESOLVED_SUPER_UNARY,
  VISIT_NOT,

  VISIT_EXPRESSION_INVOKE,

  VISIT_CLASS_TYPE_LITERAL_GET,
  VISIT_CLASS_TYPE_LITERAL_SET,
  VISIT_CLASS_TYPE_LITERAL_INVOKE,
  VISIT_CLASS_TYPE_LITERAL_COMPOUND,
  VISIT_CLASS_TYPE_LITERAL_PREFIX,
  VISIT_CLASS_TYPE_LITERAL_POSTFIX,

  VISIT_TYPEDEF_TYPE_LITERAL_GET,
  VISIT_TYPEDEF_TYPE_LITERAL_SET,
  VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
  VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
  VISIT_TYPEDEF_TYPE_LITERAL_PREFIX,
  VISIT_TYPEDEF_TYPE_LITERAL_POSTFIX,

  VISIT_TYPE_VARIABLE_TYPE_LITERAL_GET,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_INVOKE,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
  VISIT_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,

  VISIT_DYNAMIC_TYPE_LITERAL_GET,
  VISIT_DYNAMIC_TYPE_LITERAL_SET,
  VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
  VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
  VISIT_DYNAMIC_TYPE_LITERAL_PREFIX,
  VISIT_DYNAMIC_TYPE_LITERAL_POSTFIX,

  VISIT_INDEX_SET,
  VISIT_COMPOUND_INDEX_SET,
  VISIT_SUPER_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_INDEX_SET,
  VISIT_SUPER_COMPOUND_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_COMPOUND_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_GETTER_COMPOUND_INDEX_SET,
  VISIT_UNRESOLVED_SUPER_SETTER_COMPOUND_INDEX_SET,

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

  VISIT_SUPER_CONSTRUCTOR_INVOKE,
  VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
  VISIT_THIS_CONSTRUCTOR_INVOKE,
  VISIT_FIELD_INITIALIZER,

  VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
  VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
  VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
  VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,

  VISIT_INSTANCE_GETTER_DECL,
  VISIT_INSTANCE_SETTER_DECL,
  VISIT_INSTANCE_METHOD_DECL,
  VISIT_ABSTRACT_GETTER_DECL,
  VISIT_ABSTRACT_SETTER_DECL,
  VISIT_ABSTRACT_METHOD_DECL,
  VISIT_INSTANCE_FIELD_DECL,

  VISIT_GENERATIVE_CONSTRUCTOR_DECL,
  VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_DECL,
  VISIT_FACTORY_CONSTRUCTOR_DECL,
  VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,

  VISIT_REQUIRED_PARAMETER_DECL,
  VISIT_OPTIONAL_PARAMETER_DECL,
  VISIT_NAMED_PARAMETER_DECL,
  VISIT_REQUIRED_INITIALIZING_FORMAL_DECL,
  VISIT_OPTIONAL_INITIALIZING_FORMAL_DECL,
  VISIT_NAMED_INITIALIZING_FORMAL_DECL,

  VISIT_UNRESOLVED_COMPOUND,
  VISIT_UNRESOLVED_PREFIX,
  VISIT_UNRESOLVED_POSTFIX,

  // TODO(johnniwinther): Add tests for more error cases.
}
