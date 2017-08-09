// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor_test;

const Map<String, List<Test>> DECL_TESTS = const {
  'Function declarations': const [
    const Test('''
        m(a, b) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,b)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#b)', index: 1),
    ]),
    const Test('''
        m(a, [b]) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,[b])', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
          element: 'parameter(m#b)', index: 1, constant: 'null'),
    ]),
    const Test('''
        m(a, [b = null]) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,[b=null])', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
          element: 'parameter(m#b)', constant: 'null', index: 1),
    ]),
    const Test('''
        m(a, [b = 42]) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,[b=42])', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_OPTIONAL_PARAMETER_DECL,
          element: 'parameter(m#b)', constant: 42, index: 1),
    ]),
    const Test('''
        m(a, {b}) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,{b})', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
          element: 'parameter(m#b)', constant: 'null'),
    ]),
    const Test('''
        m(a, {b: null}) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,{b: null})', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
          element: 'parameter(m#b)', constant: 'null'),
    ]),
    const Test('''
        m(a, {b:42}) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,{b: 42})', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_NAMED_PARAMETER_DECL,
          element: 'parameter(m#b)', constant: 42),
    ]),
    const Test('''
        get m => null;
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_DECL,
          element: 'getter(m)', body: '=>null;'),
    ]),
    const Test('''
        set m(a) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_DECL,
          element: 'setter(m)', parameters: '(a)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
    ]),
    const Test.clazz('''
        class C {
          static m(a, b) {}
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_FUNCTION_DECL,
          element: 'function(C#m)', parameters: '(a,b)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#b)', index: 1),
    ]),
    const Test.clazz('''
        class C {
          static get m => null;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_GETTER_DECL,
          element: 'getter(C#m)', body: '=>null;'),
    ]),
    const Test.clazz('''
        class C {
          static set m(a) {}
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_SETTER_DECL,
          element: 'setter(C#m)', parameters: '(a)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
    ]),
    const Test.clazz('''
        class C {
          m(a, b) {}
        }
        ''', const [
      const Visit(VisitKind.VISIT_INSTANCE_METHOD_DECL,
          element: 'function(C#m)', parameters: '(a,b)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#b)', index: 1),
    ]),
    const Test.clazz('''
        class C {
          get m => null;
        }
        ''', const [
      const Visit(VisitKind.VISIT_INSTANCE_GETTER_DECL,
          element: 'getter(C#m)', body: '=>null;'),
    ]),
    const Test.clazz('''
        class C {
          set m(a) {}
        }
        ''', const [
      const Visit(VisitKind.VISIT_INSTANCE_SETTER_DECL,
          element: 'setter(C#m)', parameters: '(a)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
    ]),
    const Test.clazz('''
        abstract class C {
          m(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_ABSTRACT_METHOD_DECL,
          element: 'function(C#m)', parameters: '(a,b)'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#b)', index: 1),
    ]),
    const Test.clazz('''
        abstract class C {
          get m;
        }
        ''', const [
      const Visit(VisitKind.VISIT_ABSTRACT_GETTER_DECL, element: 'getter(C#m)'),
    ]),
    const Test.clazz('''
        abstract class C {
          set m(a);
        }
        ''', const [
      const Visit(VisitKind.VISIT_ABSTRACT_SETTER_DECL,
          element: 'setter(C#m)', parameters: '(a)'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
    ]),
    const Test('''
        m(a, b) {}
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '(a,b)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(m#b)', index: 1),
    ]),
    const Test('''
        m() {
          local(a, b) {}
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '()', body: '{local(a,b){}}'),
      const Visit(VisitKind.VISIT_LOCAL_FUNCTION_DECL,
          element: 'function(m#local)', parameters: '(a,b)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(local#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(local#b)', index: 1),
    ]),
    const Test('''
        m() => (a, b) {};
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '()', body: '=>(a,b){};'),
      const Visit(VisitKind.VISIT_CLOSURE_DECL,
          element: 'function(m#)', parameters: '(a,b)', body: '{}'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
    ]),
  ],
  'Constructor declarations': const [
    const Test.clazz('''
        class C {
          C(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,b)',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
      const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)', type: 'Object'),
    ], method: ''),
    const Test.clazz('''
        class C {
          var b;
          C(a, this.b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,this.b)',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_INITIALIZING_FORMAL_DECL,
          element: 'initializing_formal(#b)', index: 1),
      const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)', type: 'Object'),
    ], method: ''),
    const Test.clazz('''
        class C {
          var b;
          C(a, [this.b = 42]);
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,[this.b=42])',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_OPTIONAL_INITIALIZING_FORMAL_DECL,
          element: 'initializing_formal(#b)', constant: 42, index: 1),
      const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)', type: 'Object'),
    ], method: ''),
    const Test.clazz('''
        class C {
          var b;
          C(a, {this.b: 42});
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,{this.b: 42})',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_NAMED_INITIALIZING_FORMAL_DECL,
          element: 'initializing_formal(#b)', constant: 42),
      const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)', type: 'Object'),
    ], method: ''),
    const Test.clazz('''
        class C {
          C(a, b) : super();
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,b)',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
      const Visit(VisitKind.VISIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)',
          type: 'Object',
          arguments: '()',
          selector: 'CallStructure(arity=0)'),
    ], method: ''),
    const Test.clazz('''
        class C {
          var field;
          C(a, b) : this.field = a;
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,b)',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
      const Visit(VisitKind.VISIT_FIELD_INITIALIZER,
          element: 'field(C#field)', rhs: 'a'),
      const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)', type: 'Object'),
    ], method: ''),
    const Test.clazz('''
        class C {
          var field1;
          var field2;
          C(a, b) : this.field1 = a, this.field2 = b;
        }
        ''', const [
      const Visit(VisitKind.VISIT_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,b)',
          body: ';'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
      const Visit(VisitKind.VISIT_FIELD_INITIALIZER,
          element: 'field(C#field1)', rhs: 'a'),
      const Visit(VisitKind.VISIT_FIELD_INITIALIZER,
          element: 'field(C#field2)', rhs: 'b'),
      const Visit(VisitKind.VISIT_IMPLICIT_SUPER_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(Object#)', type: 'Object'),
    ], method: ''),
    const Test.clazz('''
        class C {
          C(a, b) : this._(a, b);
          C._(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_REDIRECTING_GENERATIVE_CONSTRUCTOR_DECL,
          element: 'generative_constructor(C#)',
          parameters: '(a,b)',
          initializers: ':this._(a,b)'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
      const Visit(VisitKind.VISIT_THIS_CONSTRUCTOR_INVOKE,
          element: 'generative_constructor(C#_)',
          arguments: '(a,b)',
          selector: 'CallStructure(arity=2)'),
    ], method: ''),
    const Test.clazz('''
        class C {
          factory C(a, b) => null;
        }
        ''', const [
      const Visit(VisitKind.VISIT_FACTORY_CONSTRUCTOR_DECL,
          element: 'factory_constructor(C#)',
          parameters: '(a,b)',
          body: '=>null;'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
    ], method: ''),
    const Test.clazz('''
        class C {
          factory C(a, b) = C._;
          C._(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
          element: 'factory_constructor(C#)',
          parameters: '(a,b)',
          target: 'generative_constructor(C#_)',
          type: 'C'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
    ], method: ''),
    const Test.clazz('''
        class C {
          factory C(a, b) = D;
        }
        class D<T> {
          D(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
          element: 'factory_constructor(C#)',
          parameters: '(a,b)',
          target: 'generative_constructor(D#)',
          type: 'D'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
    ], method: ''),
    const Test.clazz('''
        class C {
          factory C(a, b) = D<int>;
        }
        class D<T> {
          D(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
          element: 'factory_constructor(C#)',
          parameters: '(a,b)',
          target: 'generative_constructor(D#)',
          type: 'D<int>'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
    ], method: ''),
    const Test.clazz('''
        class C {
          factory C(a, b) = D<int>;
        }
        class D<T> {
          factory D(a, b) = E<D<T>>;
        }
        class E<S> {
          E(a, b);
        }
        ''', const [
      const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_DECL,
          element: 'factory_constructor(C#)',
          parameters: '(a,b)',
          target: 'factory_constructor(D#)',
          type: 'D<int>'),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#a)', index: 0),
      const Visit(VisitKind.VISIT_REQUIRED_PARAMETER_DECL,
          element: 'parameter(#b)', index: 1),
    ], method: ''),
  ],
  "Field declarations": const [
    const Test.clazz('''
        class C {
          var m;
        }
        ''', const [
      const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL, element: 'field(C#m)'),
    ]),
    const Test.clazz('''
        class C {
          var m, n;
        }
        ''', const [
      const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL, element: 'field(C#m)'),
      const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL, element: 'field(C#n)'),
    ]),
    const Test.clazz('''
        class C {
          var m = 42;
        }
        ''', const [
      const Visit(VisitKind.VISIT_INSTANCE_FIELD_DECL,
          element: 'field(C#m)', rhs: 42),
    ]),
    const Test('''
        m() {
          var local;
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '()', body: '{var local;}'),
      const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
          element: 'variable(m#local)'),
    ]),
    const Test('''
        m() {
          var local = 42;
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '()', body: '{var local=42;}'),
      const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
          element: 'variable(m#local)', rhs: 42),
    ]),
    const Test('''
        m() {
          const local = 42;
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)', parameters: '()', body: '{const local=42;}'),
      const Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
          element: 'variable(m#local)', constant: 42),
    ]),
    const Test('''
        m() {
          var local1, local2;
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)',
          parameters: '()',
          body: '{var local1,local2;}'),
      const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
          element: 'variable(m#local1)'),
      const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
          element: 'variable(m#local2)'),
    ]),
    const Test('''
        m() {
          var local1 = 42, local2 = true;
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)',
          parameters: '()',
          body: '{var local1=42,local2=true;}'),
      const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
          element: 'variable(m#local1)', rhs: 42),
      const Visit(VisitKind.VISIT_LOCAL_VARIABLE_DECL,
          element: 'variable(m#local2)', rhs: true),
    ]),
    const Test('''
        m() {
          const local1 = 42, local2 = true;
        }
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_DECL,
          element: 'function(m)',
          parameters: '()',
          body: '{const local1=42,local2=true;}'),
      const Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
          element: 'variable(m#local1)', constant: 42),
      const Visit(VisitKind.VISIT_LOCAL_CONSTANT_DECL,
          element: 'variable(m#local2)', constant: true),
    ]),
    const Test.clazz('''
        class C {
          static var m;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#m)'),
    ]),
    const Test.clazz('''
        class C {
          static var m, n;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#m)'),
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#n)'),
    ]),
    const Test.clazz('''
        class C {
          static var k, l, m, n;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#k)'),
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#l)'),
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#m)'),
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL, element: 'field(C#n)'),
    ]),
    const Test.clazz('''
        class C {
          static var m = 42;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
          element: 'field(C#m)', rhs: 42),
    ]),
    const Test.clazz('''
        class C {
          static var m = 42, n = true;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
          element: 'field(C#m)', rhs: 42),
      const Visit(VisitKind.VISIT_STATIC_FIELD_DECL,
          element: 'field(C#n)', rhs: true),
    ]),
    const Test.clazz('''
        class C {
          static const m = 42;
        }
        ''', const [
      const Visit(VisitKind.VISIT_STATIC_CONSTANT_DECL,
          element: 'field(C#m)', constant: 42),
    ]),
    const Test('''
        var m;
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL, element: 'field(m)'),
    ]),
    const Test('''
        var m, n;
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL, element: 'field(m)'),
      const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL, element: 'field(n)'),
    ]),
    const Test('''
        var m = 42;
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_DECL,
          element: 'field(m)', rhs: 42),
    ]),
    const Test('''
        const m = 42;
        ''', const [
      const Visit(VisitKind.VISIT_TOP_LEVEL_CONSTANT_DECL,
          element: 'field(m)', constant: 42),
    ]),
  ],
};
