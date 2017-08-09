// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.semantics_visitor_test;

const Map<String, List<Test>> SEND_TESTS = const {
  'Parameters': const [
    // Parameters
    const Test('m(o) => o;',
        const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#o)')),
    const Test(
        'm(o) { o = 42; }',
        const Visit(VisitKind.VISIT_PARAMETER_SET,
            element: 'parameter(m#o)', rhs: '42')),
    const Test(
        'm(o) { o(null, 42); }',
        const Visit(VisitKind.VISIT_PARAMETER_INVOKE,
            element: 'parameter(m#o)',
            arguments: '(null,42)',
            selector: 'CallStructure(arity=2)')),
    const Test(
        'm(final o) { o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_PARAMETER_SET,
            element: 'parameter(m#o)', rhs: '42')),
  ],
  'Local variables': const [
    // Local variables
    const Test(
        'm() { var o; return o; }',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_GET,
            element: 'variable(m#o)')),
    const Test(
        'm() { var o; o = 42; }',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_SET,
            element: 'variable(m#o)', rhs: '42')),
    const Test(
        'm() { var o; o(null, 42); }',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_INVOKE,
            element: 'variable(m#o)',
            arguments: '(null,42)',
            selector: 'CallStructure(arity=2)')),
    const Test(
        'm() { final o = 0; o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET,
            element: 'variable(m#o)', rhs: '42')),
    const Test(
        'm() { const o = 0; o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET,
            element: 'variable(m#o)', rhs: '42')),
  ],
  'Local functions': const [
    // Local functions
    const Test(
        'm() { o(a, b) {}; return o; }',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_GET,
            element: 'function(m#o)')),
    const Test(
        'm() { o(a, b) {}; o(null, 42); }',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_INVOKE,
            element: 'function(m#o)',
            arguments: '(null,42)',
            selector: 'CallStructure(arity=2)')),
    const Test(
        'm() { o(a) {}; o(null, 42); }',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_INCOMPATIBLE_INVOKE,
            element: 'function(m#o)',
            arguments: '(null,42)',
            selector: 'CallStructure(arity=2)')),
    const Test(
        'm() { o(a, b) {}; o = 42; }',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_SET,
            element: 'function(m#o)', rhs: '42')),
  ],
  'Static fields': const [
    // Static fields
    const Test('''
        class C { static var o; }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: 'field(C#o)')),
    const Test.clazz('''
        class C {
          static var o;
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: 'field(C#o)')),
    const Test.clazz('''
        class C {
          static var o;
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: 'field(C#o)')),
    const Test.prefix('''
        class C {
          static var o;
        }
        ''', 'm() => p.C.o;',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: 'field(C#o)')),
    const Test.clazz(
        '''
        class C {
          var o;
          static m() => o;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_GET,
            error: MessageKind.NO_INSTANCE_AVAILABLE)),
    const Test.prefix(
        '''
        class C {
          static var o;
        }
        ''',
        'm() => p.C.o;',
        const [
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: 'field(C#o)'),
        ],
        isDeferred: true),
    const Test('''
        class C {
          var o;
        }
        m() => C.o;
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o')),
    const Test('''
        class C {
          var o;
        }
        m() { C.o = 42; }
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_SET, name: 'o', rhs: '42')),
    const Test('''
        class C {
          C.o();
        }
        m() => C.o;
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o')),
    const Test.prefix(
        '''
        ''',
        'm() => p.C.o;',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
              receiver: 'p.C', name: 'o'),
          const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'C'),
        ]),
    const Test.prefix('''
        class C {
        }
        ''', 'm() => p.C.o;',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o')),
    const Test.prefix(
        '''
        ''',
        'm() => p.C.o;',
        const [
          const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
              receiver: 'p.C', name: 'o'),
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'C'),
        ],
        isDeferred: true),
    const Test.prefix(
        '''
        class C {
        }
        ''',
        'm() => p.C.o;',
        const [
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o'),
        ],
        isDeferred: true),
    const Test('''
        class C {}
        m() => C.this;
        ''', null),
    const Test(
        '''
        class C {
          static var o;
        }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static var o;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var o;
          static m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_SET,
            error: MessageKind.NO_INSTANCE_AVAILABLE, rhs: '42')),
    const Test(
        '''
        class C {
          static var o;
        }
        m() { C.o(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
            element: 'field(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
            element: 'field(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static var o;
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
            element: 'field(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          var o;
          static m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.NO_INSTANCE_AVAILABLE, arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static var o;
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_FIELD_INVOKE,
            element: 'field(C#o)', arguments: '(null,42)')),
    const Test(
        '''
        class C {}
        m() => C.this(null, 42);
        ''',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.THIS_PROPERTY, arguments: '(null,42)')),
    const Test(
        '''
        class C { static final o = 0; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static final o = 0;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static final o = 0;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static final o = 0;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test(
        '''
        class C { static const o = 0; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static const o = 0;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static const o = 0;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static const o = 0;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_STATIC_FIELD_SET,
            element: 'field(C#o)', rhs: '42')),
  ],
  'Static properties': const [
    // Static properties
    const Test('''
        class C {
          static get o => null;
        }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET, element: 'getter(C#o)')),
    const Test.clazz('''
        class C {
          static get o => null;
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET, element: 'getter(C#o)')),
    const Test.clazz('''
        class C {
          static get o => null;
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET, element: 'getter(C#o)')),
    const Test.prefix('''
        class C {
          static get o => null;
        }
        ''', 'm() => p.C.o;',
        const Visit(VisitKind.VISIT_STATIC_GETTER_GET, element: 'getter(C#o)')),
    const Test(
        '''
        class C { static get o => 42; }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SET,
            element: 'getter(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get o => 42;
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SET,
            element: 'getter(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get o => 42;
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SET,
            element: 'getter(C#o)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static get o => 42;
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SET,
            element: 'getter(C#o)', rhs: '42')),
    const Test('''
        class C {
          static set o(_) {}
        }
        m() => C.o;
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_GET, element: 'setter(C#o)')),
    const Test.clazz('''
        class C {
          static set o(_) {}
          m() => o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_GET, element: 'setter(C#o)')),

    const Test.clazz('''
        class C {
          static set o(_) {}
          m() => C.o;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_GET, element: 'setter(C#o)')),
    const Test.prefix('''
        class C {
          static set o(_) {}
        }
        ''', 'm() => p.C.o;',
        const Visit(VisitKind.VISIT_STATIC_SETTER_GET, element: 'setter(C#o)')),
    const Test(
        '''
        class C { static set o(_) {} }
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
            element: 'setter(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
            element: 'setter(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
            element: 'setter(C#o)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static set o(_) {}
        }
        ''',
        'm() { p.C.o = 42; }',
        const Visit(VisitKind.VISIT_STATIC_SETTER_SET,
            element: 'setter(C#o)', rhs: '42')),
    const Test(
        '''
        class C { static get o => null; }
        m() => C.o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
            element: 'getter(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static get o => null;
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
            element: 'getter(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static get o => null;
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
            element: 'getter(C#o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static get o => null;
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_GETTER_INVOKE,
            element: 'getter(C#o)', arguments: '(null,42)')),
    const Test(
        '''
        class C { static set o(_) {} }
        m() => C.o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_INVOKE,
            element: 'setter(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_INVOKE,
            element: 'setter(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static set o(_) {}
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_SETTER_INVOKE,
            element: 'setter(C#o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static set o(_) {}
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_SETTER_INVOKE,
            element: 'setter(C#o)', arguments: '(null,42)')),
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
        m() { C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_SET,
            element: 'function(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_SET,
            element: 'function(C#o)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { C.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_SET,
            element: 'function(C#o)', rhs: '42')),
    const Test.prefix(
        '''
        class C { static o(a, b) {} }
        ''',
        '''
        m() { p.C.o = 42; }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_SET,
            element: 'function(C#o)', rhs: '42')),
    const Test(
        '''
        class C { static o(a, b) {} }
        m() => C.o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
            element: 'function(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
            element: 'function(C#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          static o(a, b) {}
          m() { C.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
            element: 'function(C#o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        class C {
          static o(a, b) {}
        }
        ''',
        'm() { p.C.o(null, 42); }',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INVOKE,
            element: 'function(C#o)', arguments: '(null,42)')),
    const Test(
        '''
        class C { static o(a, b) {} }
        m() => C.o(null);
        ''',
        const Visit(VisitKind.VISIT_STATIC_FUNCTION_INCOMPATIBLE_INVOKE,
            element: 'function(C#o)', arguments: '(null)')),
  ],
  'Top level fields': const [
    // Top level fields
    const Test('''
        var o;
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET, element: 'field(o)')),
    const Test.prefix('''
        var o;
        ''', 'm() => p.o;',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET, element: 'field(o)')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() => p.o;',
        const [
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_GET, element: 'field(o)'),
        ],
        isDeferred: true),
    const Test.prefix('''
        ''', 'm() => p.o;',
        const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o')),
    const Test.prefix(
        '''
        ''',
        'm() => p.o;',
        const [
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o'),
        ],
        isDeferred: true),
    const Test.prefix(
        '''
        ''',
        'm() => p;',
        const Visit(VisitKind.ERROR_INVALID_GET,
            error: MessageKind.PREFIX_AS_EXPRESSION)),
    const Test(
        '''
        var o;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET,
            element: 'field(o)', rhs: '42')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET,
            element: 'field(o)', rhs: '42')),
    const Test.prefix(
        '''
        ''',
        'm() { p = 42; }',
        const Visit(VisitKind.ERROR_INVALID_SET,
            error: MessageKind.PREFIX_AS_EXPRESSION, rhs: '42')),
    const Test(
        '''
        final o = 0;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
            element: 'field(o)', rhs: '42')),
    const Test.prefix(
        '''
        final o = 0;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
            element: 'field(o)', rhs: '42')),
    const Test(
        '''
        const o = 0;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
            element: 'field(o)', rhs: '42')),
    const Test.prefix(
        '''
        const o = 0;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_FINAL_TOP_LEVEL_FIELD_SET,
            element: 'field(o)', rhs: '42')),
    const Test(
        '''
        var o;
        m() { o(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_INVOKE,
            element: 'field(o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_INVOKE,
            element: 'field(o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        ''',
        'm() { p(null, 42); }',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.PREFIX_AS_EXPRESSION, arguments: '(null,42)')),
    const Test('''
        m() => o;
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_GET, name: 'o')),
    const Test('''
        m() { o = 42; }
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_SET, name: 'o', rhs: '42')),
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
        m() => o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_GET,
            element: 'setter(o)')),
    const Test.prefix(
        '''
        set o(_) {}
        ''',
        '''
        m() => p.o;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_GET,
            element: 'setter(o)')),
    const Test(
        '''
        get o => null;
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SET,
            element: 'getter(o)', rhs: '42')),
    const Test.prefix(
        '''
        get o => null;
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SET,
            element: 'getter(o)', rhs: '42')),
    const Test(
        '''
        set o(_) {}
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
            element: 'setter(o)', rhs: '42')),
    const Test.prefix(
        '''
        set o(_) {}
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_SET,
            element: 'setter(o)', rhs: '42')),
    const Test(
        '''
        get o => null;
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
            element: 'getter(o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        get o => null;
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_INVOKE,
            element: 'getter(o)', arguments: '(null,42)')),
    const Test(
        '''
        set o(_) {}
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_INVOKE,
            element: 'setter(o)', arguments: '(null,42)')),
    const Test.prefix(
        '''
        set o(_) {}
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_SETTER_INVOKE,
            element: 'setter(o)', arguments: '(null,42)')),
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
            element: 'function(o)', arguments: '(null,42)')),
    const Test(
        '''
        o(a, b) {}
        m() => o(null);
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INCOMPATIBLE_INVOKE,
            element: 'function(o)', arguments: '(null)')),
    const Test.prefix(
        '''
        o(a, b) {}
        ''',
        'm() { p.o(null, 42); }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
            element: 'function(o)', arguments: '(null,42)')),
    const Test(
        '''
        m() => o(null, 42);
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
            name: 'o', arguments: '(null,42)')),
    const Test.prefix(
        '''
        o(a, b) {}
        ''',
        'm() => p.o(null, 42);',
        const [
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
              element: 'function(o)', arguments: '(null,42)'),
        ],
        isDeferred: true),
    const Test.prefix(
        '''
        ''',
        'm() => p.o(null, 42);',
        const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
            name: 'o', arguments: '(null,42)')),
    const Test.prefix(
        '''
        ''',
        'm() => p.o(null, 42);',
        const [
          const Visit(VisitKind.PREVISIT_DEFERRED_ACCESS, element: 'prefix(p)'),
          const Visit(VisitKind.VISIT_UNRESOLVED_INVOKE,
              name: 'o', arguments: '(null,42)'),
        ],
        isDeferred: true),
    const Test.prefix(
        '''
        ''',
        'm() => p(null, 42);',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.PREFIX_AS_EXPRESSION, arguments: '(null,42)')),
    const Test(
        '''
        o(a, b) {}
        m() { o = 42; }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_SET,
            element: 'function(o)', rhs: '42')),
    const Test.prefix(
        '''
        o(a, b) {}
        ''',
        'm() { p.o = 42; }',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_SET,
            element: 'function(o)', rhs: '42')),
  ],
  'Dynamic properties': const [
    // Dynamic properties
    const Test('m(o) => o.foo;', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
          receiver: 'o', name: 'foo'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#o)'),
    ]),
    const Test('m(o) { o.foo = 42; }', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_SET,
          receiver: 'o', name: 'foo', rhs: '42'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#o)'),
    ]),
    const Test('m(o) { o.foo(null, 42); }', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_INVOKE,
          receiver: 'o', name: 'foo', arguments: '(null,42)'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#o)'),
    ]),
  ],
  'This access': const [
    // This access
    const Test.clazz('''
        class C {
          m() => this;
        }
        ''', const Visit(VisitKind.VISIT_THIS_GET)),
    const Test.clazz('''
        class C {
          call(a, b) {}
          m() { this(null, 42); }
        }
        ''', const Visit(VisitKind.VISIT_THIS_INVOKE, arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          call(a, b) {}
          static m() { this(null, 42); }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.NO_THIS_AVAILABLE, arguments: '(null,42)')),
  ],
  'This properties': const [
    // This properties
    const Test.clazz('''
        class C {
          var foo;
          m() => foo;
        }
        ''', const Visit(VisitKind.VISIT_THIS_PROPERTY_GET, name: 'foo')),
    const Test.clazz('''
        class C {
          var foo;
          m() => this.foo;
        }
        ''', const Visit(VisitKind.VISIT_THIS_PROPERTY_GET, name: 'foo')),
    const Test.clazz('''
        class C {
          get foo => null;
          m() => foo;
        }
        ''', const Visit(VisitKind.VISIT_THIS_PROPERTY_GET, name: 'foo')),
    const Test.clazz(
        '''
        class C {
          var foo;
          static m() => this.foo;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_GET,
            error: MessageKind.NO_THIS_AVAILABLE)),
    const Test.clazz('''
        class C {
          get foo => null;
          m() => this.foo;
        }
        ''', const Visit(VisitKind.VISIT_THIS_PROPERTY_GET, name: 'foo')),
    const Test.clazz('''
        class C {
          var foo;
          m() { foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET, name: 'foo', rhs: '42')),
    const Test.clazz('''
        class C {
          var foo;
          m() { this.foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET, name: 'foo', rhs: '42')),
    const Test.clazz('''
        class C {
          set foo(_) {}
          m() { foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET, name: 'foo', rhs: '42')),
    const Test.clazz('''
        class C {
          set foo(_) {}
          m() { this.foo = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET, name: 'foo', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() { foo(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_INVOKE,
            name: 'foo', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          var foo;
          m() { this.foo(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_INVOKE,
            name: 'foo', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C {
          var foo;
          static m() { this.foo(null, 42); }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.NO_THIS_AVAILABLE, arguments: '(null,42)')),
  ],
  'Super fields': const [
    // Super fields
    const Test.clazz('''
        class B {
          var o;
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_GET, element: 'field(B#o)')),
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
            element: 'field(B#o)', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          final o = 0;
        }
        class C extends B {
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_SUPER_FIELD_SET,
            element: 'field(B#o)', rhs: '42')),
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
            element: 'field(B#o)', arguments: '(null,42)')),
    const Test.clazz('''
        class B {
        }
        class C extends B {
          m() => super.o;
        }
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GET)),
    const Test.clazz('''
    class B {
    }
    class C extends B {
      m() => super.o = 42;
    }
    ''', const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SET, rhs: '42')),
  ],
  'Super properties': const [
    // Super properties
    const Test.clazz('''
        class B {
          get o => null;
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_GET, element: 'getter(B#o)')),
    const Test.clazz('''
        class B {
          set o(_) {}
        }
        class C extends B {
          m() => super.o;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_SETTER_GET, element: 'setter(B#o)')),
    const Test.clazz(
        '''
        class B {
          get o => 0;
        }
        class C extends B {
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SET,
            element: 'getter(B#o)', rhs: '42')),
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
            element: 'setter(B#o)', rhs: '42')),
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
            element: 'getter(B#o)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class B {
          set o(_) {}
        }
        class C extends B {
          m() { super.o(null, 42); }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_SETTER_INVOKE,
            element: 'setter(B#o)', arguments: '(null,42)')),
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
          m() { super.o = 42; }
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_SET,
            element: 'function(B#o)', rhs: '42')),
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
            element: 'function(B#o)', arguments: '(null,42)')),
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
            element: 'function(B#o)', arguments: '(null)')),
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
    const Test(
        'm() => (a, b){}(null, 42);',
        const Visit(VisitKind.VISIT_EXPRESSION_INVOKE,
            receiver: '(a,b){}', arguments: '(null,42)')),
  ],
  'Class type literals': const [
    // Class type literals
    const Test('''
        class C {}
        m() => C;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_GET, constant: 'C')),
    const Test(
        '''
        class C {}
        m() => C(null, 42);
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_INVOKE,
            constant: 'C', arguments: '(null,42)')),
    const Test(
        '''
        class C {}
        m() => C = 42;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_SET,
            constant: 'C', rhs: '42')),
    const Test(
        '''
        class C {}
        m() => C += 42;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_COMPOUND,
            constant: 'C', operator: '+=', rhs: '42')),
    const Test(
        '''
        class C {}
        m() => C ??= 42;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_SET_IF_NULL,
            constant: 'C', rhs: '42')),
    const Test(
        '''
        class C {}
        m() => ++C;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_PREFIX,
            constant: 'C', operator: '++')),
    const Test(
        '''
        class C {}
        m() => C--;
        ''',
        const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_POSTFIX,
            constant: 'C', operator: '--')),
    const Test('''
        class C {}
        m() => (C).hashCode;
        ''', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_GET,
          receiver: '(C)', name: 'hashCode'),
      const Visit(VisitKind.VISIT_CLASS_TYPE_LITERAL_GET, constant: 'C'),
    ]),
  ],
  'Typedef type literals': const [
    // Typedef type literals
    const Test('''
        typedef F();
        m() => F;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_GET, constant: 'F')),
    const Test(
        '''
        typedef F();
        m() => F(null, 42);
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_INVOKE,
            constant: 'F', arguments: '(null,42)')),
    const Test(
        '''
        typedef F();
        m() => F = 42;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET,
            constant: 'F', rhs: '42')),
    const Test(
        '''
        typedef F();
        m() => F += 42;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_COMPOUND,
            constant: 'F', operator: '+=', rhs: '42')),
    const Test(
        '''
        typedef F();
        m() => F ??= 42;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_SET_IF_NULL,
            constant: 'F', rhs: '42')),
    const Test(
        '''
        typedef F();
        m() => ++F;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_PREFIX,
            constant: 'F', operator: '++')),
    const Test(
        '''
        typedef F();
        m() => F--;
        ''',
        const Visit(VisitKind.VISIT_TYPEDEF_TYPE_LITERAL_POSTFIX,
            constant: 'F', operator: '--')),
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
            element: 'type_variable(C#T)', arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C<T> {
          m() => T = 42;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET,
            element: 'type_variable(C#T)', rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          m() => T += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_COMPOUND,
            element: 'type_variable(C#T)', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          m() => T ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_SET_IF_NULL,
            element: 'type_variable(C#T)', rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          m() => ++T;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_PREFIX,
            element: 'type_variable(C#T)', operator: '++')),
    const Test.clazz(
        '''
        class C<T> {
          m() => T--;
        }
        ''',
        const Visit(VisitKind.VISIT_TYPE_VARIABLE_TYPE_LITERAL_POSTFIX,
            element: 'type_variable(C#T)', operator: '--')),
    const Test.clazz(
        '''
        class C<T> {
          static m() => T;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_GET,
            error: MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER)),
    const Test.clazz(
        '''
        class C<T> {
          static m() => T(null, 42);
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INVOKE,
            error: MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
            arguments: '(null,42)')),
    const Test.clazz(
        '''
        class C<T> {
          static m() => T ??= 42;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_SET_IF_NULL,
            error: MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER, rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          static m() => T ??= 42;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_SET_IF_NULL,
            error: MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER, rhs: '42')),
    const Test.clazz(
        '''
        class C<T> {
          static m() => ++T;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_PREFIX,
            error: MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
            operator: '++')),
    const Test.clazz(
        '''
        class C<T> {
          static m() => T--;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_POSTFIX,
            error: MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
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
    const Test(
        '''
        m() { dynamic(null, 42); }
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_INVOKE,
            constant: 'dynamic', arguments: '(null,42)')),
    const Test(
        '''
        m() => dynamic = 42;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET,
            constant: 'dynamic', rhs: '42')),
    const Test(
        '''
        m() => dynamic += 42;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_COMPOUND,
            constant: 'dynamic', operator: '+=', rhs: '42')),
    const Test(
        '''
        m() => dynamic ??= 42;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_SET_IF_NULL,
            constant: 'dynamic', rhs: '42')),
    const Test(
        '''
        m() => ++dynamic;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_PREFIX,
            constant: 'dynamic', operator: '++')),
    const Test(
        '''
        m() => dynamic--;
        ''',
        const Visit(VisitKind.VISIT_DYNAMIC_TYPE_LITERAL_POSTFIX,
            constant: 'dynamic', operator: '--')),
  ],
  'Assert': const [
    // Assert
    const Test(
        '''
        m() { assert(m()); }
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FUNCTION_INVOKE,
            element: 'function(m)', arguments: '()')),
  ],
  'Logical and': const [
    // Logical and
    const Test('''
        m() => true && false;
        ''',
        const Visit(VisitKind.VISIT_LOGICAL_AND, left: 'true', right: 'false')),
  ],
  'Logical or': const [
    // Logical or
    const Test('''
        m() => true || false;
        ''',
        const Visit(VisitKind.VISIT_LOGICAL_OR, left: 'true', right: 'false')),
  ],
  'Is test': const [
    // Is test
    const Test('''
        class C {}
        m() => 0 is C;
        ''', const Visit(VisitKind.VISIT_IS, expression: '0', type: 'C')),
  ],
  'Is not test': const [
    // Is not test
    const Test('''
        class C {}
        m() => 0 is! C;
        ''', const Visit(VisitKind.VISIT_IS_NOT, expression: '0', type: 'C')),
  ],
  'As test': const [
    // As test
    const Test('''
        class C {}
        m() => 0 as C;
        ''', const Visit(VisitKind.VISIT_AS, expression: '0', type: 'C')),
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
            element: 'function(B#+)', operator: '+', right: '42')),
    const Test.clazz(
        '''
        class B {}
        class C extends B {
          m() => super + 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_BINARY,
            operator: '+', right: '42')),
    const Test(
        '''
        m() => 2 === 3;
        ''',
        const Visit(VisitKind.ERROR_UNDEFINED_BINARY_EXPRESSION,
            left: '2', operator: '===', right: '3')),
    const Test(
        '''
        m() => 2 !== 3;
        ''',
        const Visit(VisitKind.ERROR_UNDEFINED_BINARY_EXPRESSION,
            left: '2', operator: '!==', right: '3')),
    const Test.clazz(
        '''
        class B {
          operator +(_) => null;
        }
        class C extends B {
          static m() => super + 42;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_BINARY,
            error: MessageKind.NO_SUPER_IN_STATIC, operator: '+', right: '42')),
  ],
  'Index': const [
    // Index
    const Test('''
        m() => 2[3];
        ''', const Visit(VisitKind.VISIT_INDEX, receiver: '2', index: '3')),
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
            element: 'function(B#[])', index: '42')),
    const Test.clazz('''
        class B {
        }
        class C extends B {
          m() => super[42];
        }
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX, index: '42')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
        }
        class C extends B {
          static m() => super[42];
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INDEX,
            error: MessageKind.NO_SUPER_IN_STATIC, index: '42')),
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
            setter: 'function(B#[]=)', index: '42', operator: '++')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => ++super[42];
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_PREFIX,
            index: '42', operator: '++')),
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
            getter: 'function(B#[])', index: '42', operator: '++')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
          operator []=(a, b) {}
        }
        class C extends B {
          static m() => ++super[42];
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INDEX_PREFIX,
            error: MessageKind.NO_SUPER_IN_STATIC,
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
            setter: 'function(B#[]=)', index: '42', operator: '--')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super[42]--;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_POSTFIX,
            index: '42', operator: '--')),
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
            getter: 'function(B#[])', index: '42', operator: '--')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
          operator []=(a, b) {}
        }
        class C extends B {
          static m() => super[42]--;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INDEX_POSTFIX,
            error: MessageKind.NO_SUPER_IN_STATIC,
            index: '42',
            operator: '--')),
    const Test(
        '''
        m() => [][42] ??= 0;
        ''',
        const Visit(VisitKind.VISIT_INDEX_SET_IF_NULL,
            receiver: '[] ', index: '42', rhs: '0')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[42] ??= 0;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_INDEX_SET_IF_NULL,
            getter: 'function(B#[])',
            setter: 'function(B#[]=)',
            index: '42',
            rhs: '0')),
    const Test.clazz(
        '''
        class B {
          operator []=(a, b) {}
        }
        class C extends B {
          m() => super[42] ??= 0;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_INDEX_SET_IF_NULL,
            setter: 'function(B#[]=)', index: '42', rhs: '0')),
    const Test.clazz(
        '''
        class B {
          operator [](_) => null;
        }
        class C extends B {
          m() => super[42] ??= 0;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_INDEX_SET_IF_NULL,
            getter: 'function(B#[])', index: '42', rhs: '0')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super[42] ??= 0;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_INDEX_SET_IF_NULL,
            index: '42', rhs: '0')),
  ],
  'Equals': const [
    // Equals
    const Test('''
        m() => 2 == 3;
        ''', const Visit(VisitKind.VISIT_EQUALS, left: '2', right: '3')),
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
            element: 'function(B#==)', right: '42')),
    const Test.clazz(
        '''
        class B {
          operator ==(_) => null;
        }
        class C extends B {
          static m() => super == 42;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_EQUALS,
            error: MessageKind.NO_SUPER_IN_STATIC, right: '42')),
  ],
  'Not equals': const [
    // Not equals
    const Test('''
        m() => 2 != 3;
        ''', const Visit(VisitKind.VISIT_NOT_EQUALS, left: '2', right: '3')),
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
            element: 'function(B#==)', right: '42')),
    const Test.clazz(
        '''
        class B {
          operator ==(_) => null;
        }
        class C extends B {
          static m() => super != 42;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_NOT_EQUALS,
            error: MessageKind.NO_SUPER_IN_STATIC, right: '42')),
  ],
  'Unary expression': const [
    // Unary expression
    const Test('''
        m() => -false;
        ''',
        const Visit(VisitKind.VISIT_UNARY, expression: 'false', operator: '-')),
    const Test('''
        m() => ~false;
        ''',
        const Visit(VisitKind.VISIT_UNARY, expression: 'false', operator: '~')),
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
    const Test.clazz('''
        class B {
        }
        class C extends B {
          m() => -super;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_UNARY, operator: '-')),
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
    const Test.clazz(
        '''
        class B {
          operator -() => null;
        }
        class C extends B {
          static m() => -super;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_UNARY,
            error: MessageKind.NO_SUPER_IN_STATIC, operator: '-')),
    const Test('''
        m() => !0;
        ''', const Visit(VisitKind.VISIT_NOT, expression: '0')),
    const Test('''
        m() => +false;
        ''',
        // TODO(johnniwinther): Should this be an
        // ERROR_UNDEFINED_UNARY_EXPRESSION? Currently the parser just skips
        // the `+`.
        const []),
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
    const Test.clazz(
        '''
        class B {
          operator []=(a, b) {}
        }
        class C extends B {
          static m() => super[1] = 2;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_INDEX_SET,
            error: MessageKind.NO_SUPER_IN_STATIC, index: '1', rhs: '2')),
  ],
  'Compound assignment': const [
    // Compound assignment
    const Test('''
        m(a) => a.b += 42;
        ''', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_COMPOUND,
          receiver: 'a', name: 'b', operator: '+=', rhs: '42'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)')
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
          final a = 0;
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
            getter: 'getter(a)',
            setter: 'setter(a)',
            operator: '+=',
            rhs: '42')),
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
    const Test.clazz(
        '''
        class C {
          var o;
          static m() { o += 42; }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_COMPOUND,
            error: MessageKind.NO_INSTANCE_AVAILABLE,
            operator: '+=',
            rhs: '42')),
    const Test.prefix(
        '''
        ''',
        '''
        m() { p += 42; }
        ''',
        const Visit(VisitKind.ERROR_INVALID_COMPOUND,
            error: MessageKind.PREFIX_AS_EXPRESSION,
            operator: '+=',
            rhs: '42')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => C.a += 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)',
            setter: 'setter(C#a)',
            operator: '+=',
            rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => C.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)',
            setter: 'setter(C#a)',
            operator: '+=',
            rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_COMPOUND,
            getter: 'getter(C#a)',
            setter: 'setter(C#a)',
            operator: '+=',
            rhs: '42')),
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
            getter: 'getter(C#a)',
            setter: 'setter(C#a)',
            operator: '+=',
            rhs: '42')),
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
            operator: '+=', name: 'a', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => this.a += 42;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_COMPOUND,
            name: 'a', operator: '+=', rhs: '42')),
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
            getter: 'getter(B#a)',
            setter: 'setter(B#a)',
            operator: '+=',
            rhs: '42')),
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
            getter: 'getter(A#a)',
            setter: 'setter(B#a)',
            operator: '+=',
            rhs: '42')),
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
            getter: 'getter(B#a)',
            setter: 'field(A#a)',
            operator: '+=',
            rhs: '42')),
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
            getter: 'field(A#a)',
            setter: 'setter(B#a)',
            operator: '+=',
            rhs: '42')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          final a = 0;
        }

        class C extends B {
          m() => super.a += 42;
        }
        ''',
        // TODO(johnniwinther): Change this to
        // [VISIT_SUPER_FIELD_FIELD_COMPOUND] when dart2js supports shadow
        // setters.
        const Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_COMPOUND,
            element: 'field(B#a)', operator: '+=', rhs: '42')),
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
            element: 'function(B#a)', operator: '+=', rhs: '42')),
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
            getter: 'function(B#[])',
            setter: 'function(B#[]=)',
            index: '1',
            operator: '+=',
            rhs: '42')),
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
            setter: 'function(B#[]=)', index: '1', operator: '+=', rhs: '42')),
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
            getter: 'function(B#[])', index: '1', operator: '+=', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          operator [](_) {}
          operator []=(a, b) {}
        }
        class C extends B {
          static m() => super[1] += 42;
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_COMPOUND_INDEX_SET,
            error: MessageKind.NO_SUPER_IN_STATIC,
            index: '1',
            operator: '+=',
            rhs: '42')),
  ],
  'Prefix expression': const [
    // Prefix expression
    const Test('''
        m(a) => --a.b;
        ''', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_PREFIX,
          receiver: 'a', name: 'b', operator: '--'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)')
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
            getter: 'getter(a)', setter: 'setter(a)', operator: '--')),
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
    const Test.clazz(
        '''
        class C {
          var o;
          static m() { ++o; }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_PREFIX,
            error: MessageKind.NO_INSTANCE_AVAILABLE, operator: '++')),
    const Test.prefix(
        '''
        ''',
        '''
        m() { ++p; }
        ''',
        const Visit(VisitKind.ERROR_INVALID_PREFIX,
            error: MessageKind.PREFIX_AS_EXPRESSION, operator: '++')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => ++C.a;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => --C.a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '--')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => --a;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_PREFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '--')),
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
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          var a;
          m() => --a;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_PREFIX,
            name: 'a', operator: '--')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => ++this.a;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_PREFIX,
            name: 'a', operator: '++')),
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
            getter: 'getter(B#a)', setter: 'setter(B#a)', operator: '--')),
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
            getter: 'getter(A#a)', setter: 'setter(B#a)', operator: '++')),
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
            getter: 'getter(B#a)', setter: 'field(A#a)', operator: '--')),
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
            getter: 'field(A#a)', setter: 'setter(B#a)', operator: '++')),
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
            element: 'function(B#a)', operator: '++')),
    const Test.clazz('''
        class B {
        }
        class C extends B {
          m() => ++super.a;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_PREFIX, operator: '++')),
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

    const Test('''
        m() => ++unresolved;
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_PREFIX, operator: '++')),
  ],
  'Postfix expression': const [
    // Postfix expression
    const Test('''
        m(a) => a.b--;
        ''', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_POSTFIX,
          receiver: 'a', name: 'b', operator: '--'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)')
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
            getter: 'getter(a)', setter: 'setter(a)', operator: '--')),
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
    const Test.clazz(
        '''
        class C {
          var o;
          static m() { o--; }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_POSTFIX,
            error: MessageKind.NO_INSTANCE_AVAILABLE, operator: '--')),
    const Test.prefix(
        '''
        ''',
        '''
        m() { p--; }
        ''',
        const Visit(VisitKind.ERROR_INVALID_POSTFIX,
            error: MessageKind.PREFIX_AS_EXPRESSION, operator: '--')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => C.a++;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => C.a--;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '--')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => a--;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_POSTFIX,
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '--')),
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
            getter: 'getter(C#a)', setter: 'setter(C#a)', operator: '++')),
    const Test.clazz(
        '''
        class C {
          var a;
          m() => a--;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_POSTFIX,
            name: 'a', operator: '--')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => this.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_POSTFIX,
            name: 'a', operator: '++')),
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
            getter: 'getter(B#a)', setter: 'setter(B#a)', operator: '--')),
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
            getter: 'getter(A#a)', setter: 'setter(B#a)', operator: '++')),
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
            getter: 'getter(B#a)', setter: 'field(A#a)', operator: '--')),
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
            getter: 'field(A#a)', setter: 'setter(B#a)', operator: '++')),
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
            element: 'function(B#a)', operator: '++')),
    const Test.clazz('''
        class B {
        }
        class C extends B {
          m() => super.a++;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_POSTFIX, operator: '++')),
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

    const Test('''
        m() => unresolved++;
        ''', const Visit(VisitKind.VISIT_UNRESOLVED_POSTFIX, operator: '++')),
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
        m() => const bool.fromEnvironment('foo');
        ''',
        const Visit(VisitKind.VISIT_BOOL_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
            constant: 'const bool.fromEnvironment("foo")')),
    const Test(
        '''
        m() => const bool.fromEnvironment('foo', defaultValue: true);
        ''',
        const Visit(VisitKind.VISIT_BOOL_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
            constant: 'const bool.fromEnvironment("foo", defaultValue: true)')),
    const Test(
        '''
        m() => const int.fromEnvironment('foo');
        ''',
        const Visit(VisitKind.VISIT_INT_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
            constant: 'const int.fromEnvironment("foo")')),
    const Test(
        '''
        m() => const String.fromEnvironment('foo');
        ''',
        const Visit(VisitKind.VISIT_STRING_FROM_ENVIRONMENT_CONSTRUCTOR_INVOKE,
            constant: 'const String.fromEnvironment("foo")')),
    const Test(
        '''
        class Class {
          Class(a, b);
        }
        m() => const Class(true, 42);
        ''',
        const Visit(VisitKind.ERROR_NON_CONSTANT_CONSTRUCTOR_INVOKE,
            element: 'generative_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
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
        class Class {}
        m() => new Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_CONSTRUCTOR_INCOMPATIBLE_INVOKE,
            element: 'generative_constructor(Class#)',
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
          Class() : this._(true, 42);
          Class._(a, b);
        }
        m() => new Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_CONSTRUCTOR_INCOMPATIBLE_INVOKE,
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
            element: 'factory_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class {
          factory Class() => new Class._(true, 42);
          Class._(a, b);
        }
        m() => new Class(true, 42);
        ''',
        const Visit(VisitKind.VISIT_CONSTRUCTOR_INCOMPATIBLE_INVOKE,
            element: 'factory_constructor(Class#)',
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
            element: 'factory_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class<double>',
            target: 'generative_constructor(Class#b)',
            targetType: 'Class<Class<int>>',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class<T> {
          factory Class(a) = Class<int>.a;
          factory Class.a(a, [b]) = Class<Class<T>>.b;
          Class.b(a, [b]);
        }
        m() => new Class<double>(true, 42);
        ''',
        const Visit(VisitKind.VISIT_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'factory_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class<double>',
            target: 'generative_constructor(Class#b)',
            targetType: 'Class<Class<int>>',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class {
          factory Class() = Class._;
          Class._();
        }
        m() => new Class(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'factory_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class<T> {
          factory Class(a, b) = Class<int>.a;
          factory Class.a(a, b) = Class<Class<T>>.b;
          Class.b(a);
        }
        m() => new Class<double>(true, 42);
        ''',
        const Visit(
            VisitKind.VISIT_UNRESOLVED_REDIRECTING_FACTORY_CONSTRUCTOR_INVOKE,
            element: 'factory_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class<double>',
            selector: 'CallStructure(arity=2)')),
    const Test(
        '''
        class Class {
          Class(a, b);
        }
        m() => new Class.unresolved(true, 42);
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_CONSTRUCTOR_INVOKE,
            arguments: '(true,42)')),
    const Test(
        '''
        m() => new Unresolved(true, 42);
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_CLASS_CONSTRUCTOR_INVOKE,
            arguments: '(true,42)')),
    const Test(
        '''
        abstract class AbstractClass {}
        m() => new AbstractClass();
        ''',
        const Visit(VisitKind.VISIT_ABSTRACT_CLASS_CONSTRUCTOR_INVOKE,
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
            element: 'factory_constructor(Class#)',
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
            element: 'factory_constructor(Class#)',
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
            element: 'factory_constructor(Class#)',
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
            element: 'factory_constructor(Class#)',
            arguments: '(true,42)',
            type: 'Class',
            selector: 'CallStructure(arity=2)')),
  ],
  'If not null expressions': const [
    const Test('''
        m(a) => a?.b;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_GET,
          receiver: 'a', name: 'b'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        class C {
          static var b;
        }
        m(a) => C?.b;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_GET, element: 'field(C#b)')),
    const Test('''
        m(a) => a?.b = 42;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_SET,
          receiver: 'a', name: 'b', rhs: '42'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        m(a) => a?.b(42, true);
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_INVOKE,
          receiver: 'a',
          arguments: '(42,true)',
          selector: 'Selector(call, b, arity=2)'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        m(a) => ++a?.b;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_PREFIX,
          receiver: 'a', name: 'b', operator: '++'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        m(a) => a?.b--;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_POSTFIX,
          receiver: 'a', name: 'b', operator: '--'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        m(a) => a?.b *= 42;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_COMPOUND,
          receiver: 'a', name: 'b', operator: '*=', rhs: '42'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        m(a) => a?.b ??= 42;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NOT_NULL_DYNAMIC_PROPERTY_SET_IF_NULL,
          receiver: 'a', name: 'b', rhs: '42'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
    ]),
    const Test('''
        m(a, b) => a ?? b;
        ''', const [
      const Visit(VisitKind.VISIT_IF_NULL, left: 'a', right: 'b'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#b)'),
    ]),
    const Test(
        '''
        m(a) => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_PARAMETER_SET_IF_NULL,
            element: 'parameter(m#a)', rhs: '42')),
    const Test.prefix(
        '''
        var o;
        ''',
        'm() => p?.o;',
        const Visit(VisitKind.ERROR_INVALID_GET,
            error: MessageKind.PREFIX_AS_EXPRESSION)),
  ],
  'Set if null': const [
    const Test('''
        m(a) => a.b ??= 42;
        ''', const [
      const Visit(VisitKind.VISIT_DYNAMIC_PROPERTY_SET_IF_NULL,
          receiver: 'a', name: 'b', rhs: '42'),
      const Visit(VisitKind.VISIT_PARAMETER_GET, element: 'parameter(m#a)')
    ]),
    const Test(
        '''
        m(a) => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_PARAMETER_SET_IF_NULL,
            element: 'parameter(m#a)', rhs: '42')),
    const Test(
        '''
        m(final a) => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_FINAL_PARAMETER_SET_IF_NULL,
            element: 'parameter(m#a)', rhs: '42')),
    const Test(
        '''
        m() {
          var a;
          a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_VARIABLE_SET_IF_NULL,
            element: 'variable(m#a)', rhs: '42')),
    const Test(
        '''
        m() {
          final a = 0;
          a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_FINAL_LOCAL_VARIABLE_SET_IF_NULL,
            element: 'variable(m#a)', rhs: '42')),
    const Test(
        '''
        m() {
          a() {}
          a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_LOCAL_FUNCTION_SET_IF_NULL,
            element: 'function(m#a)', rhs: '42')),
    const Test(
        '''
        var a;
        m() => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FIELD_SET_IF_NULL,
            element: 'field(a)', rhs: '42')),
    const Test(
        '''
        get a => 0;
        set a(_) {}
        m() => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(a)', setter: 'setter(a)', rhs: '42')),
    const Test(
        '''
        class C {
          static var a;
        }
        m() => C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET_IF_NULL,
            element: 'field(C#a)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => C.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET_IF_NULL,
            element: 'field(C#a)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static var a;
          m() => a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET_IF_NULL,
            element: 'field(C#a)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static var a;
        }
        ''',
        '''
        m() => p.C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_FIELD_SET_IF_NULL,
            element: 'field(C#a)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var o;
          static m() { o ??= 42; }
        }
        ''',
        const Visit(VisitKind.ERROR_INVALID_SET_IF_NULL,
            error: MessageKind.NO_INSTANCE_AVAILABLE, rhs: '42')),
    const Test.prefix(
        '''
        ''',
        '''
        m() { p ??= 42; }
        ''',
        const Visit(VisitKind.ERROR_INVALID_SET_IF_NULL,
            error: MessageKind.PREFIX_AS_EXPRESSION, rhs: '42')),
    const Test(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        m() => C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(C#a)', setter: 'setter(C#a)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => C.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(C#a)', setter: 'setter(C#a)', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
          m() => a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(C#a)', setter: 'setter(C#a)', rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static get a => 0;
          static set a(_) {}
        }
        ''',
        '''
        m() => p.C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(C#a)', setter: 'setter(C#a)', rhs: '42')),
    // TODO(johnniwinther): Enable these when dart2js supports method and setter
    // with the same name.
    /*const Test(
        '''
        class C {
          static a() {}
          static set a(_) {}
        }
        m() => C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static a() {}
          static set a(_) {}
          m() => C.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            rhs: '42')),
    const Test.clazz(
        '''
        class C {
          static a() {}
          static set a(_) {}
          m() => a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            rhs: '42')),
    const Test.prefix(
        '''
        class C {
          static a() {}
          static set a(_) {}
        }
        ''',
        '''
        m() => p.C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SETTER_SET_IF_NULL,
            getter: 'function(C#a)', setter: 'setter(C#a)',
            rhs: '42')),*/
    const Test.clazz(
        '''
        class C {
          var a;
          m() => a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET_IF_NULL,
            name: 'a', rhs: '42')),
    const Test.clazz(
        '''
        class C {
          var a = 0;
          m() => this.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_THIS_PROPERTY_SET_IF_NULL,
            name: 'a', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          var a = 0;
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_SET_IF_NULL,
            element: 'field(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          final a = 0;
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_SET_IF_NULL,
            element: 'field(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          get a => 0;
          set a (_) {}
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(B#a)', setter: 'setter(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          get a => 0;
        }
        class B extends A {
          set a (_) {}
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_SETTER_SET_IF_NULL,
            getter: 'getter(A#a)', setter: 'setter(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          get a => 0;
        }

        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_GETTER_FIELD_SET_IF_NULL,
            getter: 'getter(B#a)', setter: 'field(A#a)', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          set a(_) {}
        }

        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_FIELD_SETTER_SET_IF_NULL,
            getter: 'field(A#a)', setter: 'setter(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class A {
          var a;
        }
        class B extends A {
          final a = 0;
        }

        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        // TODO(johnniwinther): Change this to
        // [VISIT_SUPER_FIELD_FIELD_SET_IF_NULL] when dart2js supports shadow
        // setters.
        const Visit(VisitKind.VISIT_SUPER_FINAL_FIELD_SET_IF_NULL,
            element: 'field(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          a() {}
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_SUPER_METHOD_SET_IF_NULL,
            element: 'function(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class B {
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SET_IF_NULL,
            name: 'a', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          set a(_) {}
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_GETTER_SET_IF_NULL,
            setter: 'setter(B#a)', rhs: '42')),
    const Test.clazz(
        '''
        class B {
          get a => 42;
        }
        class C extends B {
          m() => super.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SUPER_SETTER_SET_IF_NULL,
            getter: 'getter(B#a)', rhs: '42')),

    const Test.clazz(
        '''
        class C {
          static set a(var value) { }
          m() => a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_GETTER_SET_IF_NULL,
            setter: 'setter(C#a)', rhs: '42')),

    const Test.clazz(
        '''
        class C {
          static get a => 42;
          m() => C.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_STATIC_SETTER_SET_IF_NULL,
            getter: 'getter(C#a)', rhs: '42')),

    const Test.clazz(
        '''
        class C {
          static final a = 42;
          m() => C.a ??= 42;
        }
        ''',
        const Visit(VisitKind.VISIT_STATIC_FINAL_FIELD_SET_IF_NULL,
            element: 'field(C#a)', rhs: '42')),

    const Test(
        '''
        class C {
          static a(var value) { }
        }
        m() => C.a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_STATIC_METHOD_SET_IF_NULL,
            element: 'function(C#a)', rhs: '42')),

    const Test(
        '''
        set a(var value) { }
        m() => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_GETTER_SET_IF_NULL,
            setter: 'setter(a)', rhs: '42')),

    const Test(
        '''
        get a => 42;
        m() => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_TOP_LEVEL_SETTER_SET_IF_NULL,
            getter: 'getter(a)', rhs: '42')),

    const Test(
        '''
        a(var value) { }
        m() => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_METHOD_SET_IF_NULL,
            element: 'function(a)', rhs: '42')),

    const Test(
        '''
        final a = 42;
        m() => a ??= 42;
        ''',
        const Visit(VisitKind.VISIT_TOP_LEVEL_FINAL_FIELD_SET_IF_NULL,
            element: 'field(a)', rhs: '42')),

    const Test(
        '''
        m() => unresolved ??= 42;
        ''',
        const Visit(VisitKind.VISIT_UNRESOLVED_SET_IF_NULL,
            name: 'unresolved', rhs: '42')),
  ],
};
