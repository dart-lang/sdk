// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';
import 'package:compiler/implementation/resolution/class_members.dart'
    show MembersCreator;

main() {
  asyncTest(() => Future.wait([
    testRequiredParameters(),
    testPositionalParameters(),
    testNamedParameters(),
    testNotSubtype(),
    testGetterNotSubtype(),
    testSetterNotSubtype(),
    testGenericNotSubtype(),
    testFieldNotSubtype(),
    testMixedOverride(),
    testAbstractMethods(),
    testNoSuchMethod(),
  ]));
}

Future check(String source, {errors, warnings, hints, infos}) {
  return MockCompiler.create((MockCompiler compiler) {
    compiler.diagnosticHandler = createHandler(compiler, source);
    compiler.parseScript(source);
    var cls = compiler.mainApp.find('Class');
    cls.ensureResolved(compiler);
    MembersCreator.computeAllClassMembers(compiler, cls);

    toList(o) => o == null ? [] : o is List ? o : [o];

    compareMessageKinds(source, toList(errors), compiler.errors, 'error');

    compareMessageKinds(source, toList(warnings), compiler.warnings, 'warning');

    if (infos != null) {
      compareMessageKinds(source, toList(infos), compiler.infos, 'info');
    }

    if (hints != null) {
      compareMessageKinds(source, toList(hints), compiler.hints, 'hint');
    }
  });
}

Future testRequiredParameters() {
  return Future.wait([
    check("""
          class A {
            method() => null; // testRequiredParameters:0
          }
          class Class extends A {
            method() => null; // testRequiredParameters:1
          }
          """),

    check("""
          class A {
            method(a) => null; // testRequiredParameters:2
          }
          class Class extends A {
            method(b) => null; // testRequiredParameters:3
          }
          """),

    check("""
          class A {
            method(a, b, c, d) => null; // testRequiredParameters:3
          }
          class Class extends A {
            method(b, a, d, c) => null; // testRequiredParameters:4
          }
          """),

    check("""
          class A {
            method() => null; // testRequiredParameters:5
          }
          class Class extends A {
            method(a) => null; // testRequiredParameters:6
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method() => null; // testRequiredParameters:7
          }
          class Class implements A {
            method(a) => null; // testRequiredParameters:8
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(a, b, c) => null; // testRequiredParameters:9
          }
          class Class extends A {
            method(a, b, c, d) => null; // testRequiredParameters:10
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),
  ]);
}

Future testPositionalParameters() {
  return Future.wait([
    check("""
          class A {
            method([a]) => null; // testPositionalParameters:1
          }
          class Class extends A {
            method([a]) => null; // testPositionalParameters:2
          }
          """),

    check("""
          class A {
            method([a, b]) => null; // testPositionalParameters:3
          }
          class Class extends A {
            method([b, a]) => null; // testPositionalParameters:4
          }
          """),

    check("""
          class A {
            method([a, b, c]) => null; // testPositionalParameters:5
          }
          class Class extends A {
            method([b, d, a, c]) => null; // testPositionalParameters:6
          }
          """),

    check("""
          class A {
            method([a]) => null; // testPositionalParameters:7
          }
          class Class extends A {
            method([a]) => null; // testPositionalParameters:8
          }
          """),

    check("""
          class A {
            method(a) => null; // testPositionalParameters:9
          }
          class Class extends A {
            method() => null; // testPositionalParameters:10
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(a, [b]) => null; // testPositionalParameters:11
          }
          class Class extends A {
            method(a) => null; // testPositionalParameters:12
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(a, [b]) => null; // testPositionalParameters:13
          }
          class Class extends A {
            method([a]) => null; // testPositionalParameters:14
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(a, b, [c, d, e]) => null; // testPositionalParameters:15
          }
          class Class extends A {
            method([a, b, c, d]) => null; // testPositionalParameters:16
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),
  ]);
}

Future testNamedParameters() {
  return Future.wait([
    check("""
          class A {
            method({a}) => null; // testNamedParameters:1
          }
          class Class extends A {
            method({a}) => null; // testNamedParameters:2
          }
          """),

    check("""
          class A {
            method({a, b}) => null; // testNamedParameters:3
          }
          class Class extends A {
            method({b, a}) => null; // testNamedParameters:4
          }
          """),

    check("""
          class A {
            method({a, b, c}) => null; // testNamedParameters:5
          }
          class Class extends A {
            method({b, c, a, d}) => null; // testNamedParameters:6
          }
          """),

    check("""
          class A {
            method(d, {a, b, c}) => null; // testNamedParameters:7
          }
          class Class extends A {
            method(e, {b, c, a, d}) => null; // testNamedParameters:8
          }
          """),

    check("""
          class A {
            method({a}) => null; // testNamedParameters:9
          }
          class Class extends A {
            method() => null; // testNamedParameters:10
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method({a, b}) => null; // testNamedParameters:11
          }
          class Class extends A {
            method({b}) => null; // testNamedParameters:12
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method({a, b, c, d}) => null; // testNamedParameters:13
          }
          class Class extends A {
            method({a, e, d, c}) => null; // testNamedParameters:14
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),
  ]);
}

Future testNotSubtype() {
  return Future.wait([
    check("""
          class A {
            method(int a) => null; // testNotSubtype:1
          }
          class Class extends A {
            method(int a) => null; // testNotSubtype:2
          }
          """),

    check("""
          class A {
            method(int a) => null; // testNotSubtype:3
          }
          class Class extends A {
            method(num a) => null; // testNotSubtype:4
          }
          """),

    check("""
          class A {
            void method() {} // testNotSubtype:5
          }
          class Class extends A {
            method() => null; // testNotSubtype:6
          }
          """),

    check("""
          class A {
            method() => null; // testNotSubtype:7
          }
          class Class extends A {
            void method() {} // testNotSubtype:8
          }
          """),

    check("""
          class A {
            void method() {} // testNotSubtype:9
          }
          class Class extends A {
            int method() => null; // testNotSubtype:10
          }
          """),

    check("""
          class A {
            int method() => null; // testNotSubtype:11
          }
          class Class extends A {
            void method() {} // testNotSubtype:12
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(int a) => null; // testNotSubtype:13
          }
          class B extends A {
            method(num a) => null; // testNotSubtype:14
          }
          class Class extends B {
            method(double a) => null; // testNotSubtype:15
          }
          """),

    check("""
          class A {
            method(int a) => null; // testNotSubtype:16
          }
          class B extends A {
            method(a) => null; // testNotSubtype:17
          }
          class Class extends B {
            method(String a) => null; // testNotSubtype:18
          }
          """),

    check("""
          class A {
            method(int a) => null; // testNotSubtype:19
          }
          class Class extends A {
            method(String a) => null; // testNotSubtype:20
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    // TODO(johnniwinther): These are unclear. Issue 16443 has been filed.
    check("""
          class A {
            method(int a) => null; // testNotSubtype:23
          }
          class B {
            method(num a) => null; // testNotSubtype:24
          }
          abstract class C implements A, B {
          }
          class Class implements C {
            method(double a) => null; // testNotSubtype:25
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(num a) => null; // testNotSubtype:29
          }
          class B {
            method(int a) => null; // testNotSubtype:30
          }
          abstract class C implements A, B {
          }
          class Class implements C {
            method(double a) => null; // testNotSubtype:31
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A {
            method(int a) => null; // testNotSubtype:26
          }
          class B {
            method(num a) => null; // testNotSubtype:27
          }
          abstract class C implements A, B {
          }
          class Class implements C {
            method(String a) => null; // testNotSubtype:28
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_METHOD,
                          MessageKind.INVALID_OVERRIDE_METHOD],
               infos: [MessageKind.INVALID_OVERRIDDEN_METHOD,
                       MessageKind.INVALID_OVERRIDDEN_METHOD]),
  ]);
}

Future testGetterNotSubtype() {
  return Future.wait([
    check("""
          class A {
            get getter => null; // testGetterNotSubtype:1
          }
          class Class extends A {
            get getter => null; // testGetterNotSubtype:2
          }
          """),

    check("""
          class A {
            num get getter => null; // testGetterNotSubtype:3
          }
          class Class extends A {
            num get getter => null; // testGetterNotSubtype:4
          }
          """),

    check("""
          class A {
            num get getter => null; // testGetterNotSubtype:5
          }
          class Class extends A {
            int get getter => null; // testGetterNotSubtype:6
          }
          """),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:7
          }
          class Class extends A {
            num get getter => null; // testGetterNotSubtype:8
          }
          """),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:9
          }
          class Class extends A {
            double get getter => null; // testGetterNotSubtype:10
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_GETTER,
               infos: MessageKind.INVALID_OVERRIDDEN_GETTER),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:11
          }
          class B extends A {
            num get getter => null; // testGetterNotSubtype:12
          }
          class Class extends B {
            double get getter => null; // testGetterNotSubtype:13
          }
          """),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:14
          }
          class B {
            num get getter => null; // testGetterNotSubtype:15
          }
          class Class extends A implements B {
            double get getter => null; // testGetterNotSubtype:16
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_GETTER,
               infos: MessageKind.INVALID_OVERRIDDEN_GETTER),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:17
          }
          class B {
            String get getter => null; // testGetterNotSubtype:18
          }
          class Class extends A implements B {
            double get getter => null; // testGetterNotSubtype:19
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_GETTER,
                          MessageKind.INVALID_OVERRIDE_GETTER],
               infos: [MessageKind.INVALID_OVERRIDDEN_GETTER,
                       MessageKind.INVALID_OVERRIDDEN_GETTER]),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:20
          }
          class B {
            String get getter => null; // testGetterNotSubtype:21
          }
          class Class implements A, B {
            double get getter => null; // testGetterNotSubtype:22
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_GETTER,
                          MessageKind.INVALID_OVERRIDE_GETTER],
               infos: [MessageKind.INVALID_OVERRIDDEN_GETTER,
                       MessageKind.INVALID_OVERRIDDEN_GETTER]),

    // TODO(johnniwinther): These are unclear. Issue 16443 has been filed.
    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:23
          }
          class B {
            num get getter => null; // testGetterNotSubtype:24
          }
          abstract class C implements A, B {
          }
          class Class implements C {
            double get getter => null; // testGetterNotSubtype:25
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_GETTER,
               infos: MessageKind.INVALID_OVERRIDDEN_GETTER),

    check("""
          class A {
            int get getter => null; // testGetterNotSubtype:26
          }
          class B {
            num get getter => null; // testGetterNotSubtype:27
          }
          abstract class C implements A, B {
          }
          class Class implements C {
            String get getter => null; // testGetterNotSubtype:28
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_GETTER,
                          MessageKind.INVALID_OVERRIDE_GETTER],
               infos: [MessageKind.INVALID_OVERRIDDEN_GETTER,
                       MessageKind.INVALID_OVERRIDDEN_GETTER]),
  ]);
}

Future testGenericNotSubtype() {
  return Future.wait([
    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:1
          }
          class Class<S> extends A<S> {
            method(S s) => null; // testGenericNotSubtype:2
          }
          """),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:3
          }
          class Class extends A<num> {
            method(int i) => null; // testGenericNotSubtype:4
          }
          """),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:5
          }
          class B<S> {
            method(S s) => null; // testGenericNotSubtype:6
          }
          class Class extends A<double> implements B<int> {
            method(num i) => null; // testGenericNotSubtype:7
          }
          """),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:8
          }
          class Class<S> extends A<S> {
            method(int i) => null; // testGenericNotSubtype:9
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:10
          }
          class B<S> extends A<S> {

          }
          class Class<U> extends B<U> {
            method(U u) => null; // testGenericNotSubtype:11
          }
          """),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:12
          }
          class B<S> {
            method(S s) => null; // testGenericNotSubtype:13
          }
          class Class<U> extends A<U> implements B<num> {
            method(int i) => null; // testGenericNotSubtype:14
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:15
          }
          class B<S> {
            method(S s) => null; // testGenericNotSubtype:16
          }
          class Class extends A<int> implements B<String> {
            method(double d) => null; // testGenericNotSubtype:17
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_METHOD,
                          MessageKind.INVALID_OVERRIDE_METHOD],
               infos: [MessageKind.INVALID_OVERRIDDEN_METHOD,
                       MessageKind.INVALID_OVERRIDDEN_METHOD]),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:18
          }
          class B<S> {
            method(S s) => null; // testGenericNotSubtype:19
          }
          class Class implements A<int>, B<String> {
            method(double d) => null; // testGenericNotSubtype:20
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_METHOD,
                          MessageKind.INVALID_OVERRIDE_METHOD],
               infos: [MessageKind.INVALID_OVERRIDDEN_METHOD,
                       MessageKind.INVALID_OVERRIDDEN_METHOD]),

    // TODO(johnniwinther): These are unclear. Issue 16443 has been filed.
    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:21
          }
          class B<S> {
            method(S s) => null; // testGenericNotSubtype:22
          }
          abstract class C implements A<int>, B<num> {
          }
          class Class implements C {
            method(double d) => null; // testGenericNotSubtype:23
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_METHOD,
               infos: MessageKind.INVALID_OVERRIDDEN_METHOD),

    check("""
          class A<T> {
            method(T t) => null; // testGenericNotSubtype:24
          }
          class B<S> {
            method(S s) => null; // testGenericNotSubtype:25
          }
          abstract class C implements A<int>, B<num> {
          }
          class Class implements C {
            method(String s) => null; // testGenericNotSubtype:26
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_METHOD,
                          MessageKind.INVALID_OVERRIDE_METHOD],
               infos: [MessageKind.INVALID_OVERRIDDEN_METHOD,
                       MessageKind.INVALID_OVERRIDDEN_METHOD]),
  ]);
}

Future testSetterNotSubtype() {
  return Future.wait([
  check("""
        class A {
          set setter(_) => null; // testSetterNotSubtype:1
        }
        class Class extends A {
          set setter(_) => null; // testSetterNotSubtype:2
        }
        """),

  check("""
        class A {
          void set setter(_) {} // testSetterNotSubtype:3
        }
        class Class extends A {
          set setter(_) => null; // testSetterNotSubtype:4
        }
        """),

  check("""
        class A {
          set setter(_) => null; // testSetterNotSubtype:5
        }
        class Class extends A {
          void set setter(_) {} // testSetterNotSubtype:6
        }
        """),

  check("""
        class A {
          set setter(_) => null; // testSetterNotSubtype:7
        }
        class Class extends A {
          void set setter(_) {} // testSetterNotSubtype:8
        }
        """),

  check("""
        class A {
          set setter(num _) => null; // testSetterNotSubtype:9
        }
        class Class extends A {
          set setter(num _) => null; // testSetterNotSubtype:10
        }
        """),

  check("""
        class A {
          set setter(num _) => null; // testSetterNotSubtype:11
        }
        class Class extends A {
          set setter(int _) => null; // testSetterNotSubtype:12
        }
        """),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:13
        }
        class Class extends A {
          set setter(num _) => null; // testSetterNotSubtype:14
        }
        """),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:15
        }
        class Class extends A {
          set setter(double _) => null; // testSetterNotSubtype:16
        }
        """, warnings: MessageKind.INVALID_OVERRIDE_SETTER,
             infos: MessageKind.INVALID_OVERRIDDEN_SETTER),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:17
        }
        class B extends A {
          set setter(num _) => null; // testSetterNotSubtype:18
        }
        class Class extends B {
          set setter(double _) => null; // testSetterNotSubtype:19
        }
        """),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:20
        }
        class B {
          set setter(num _) => null; // testSetterNotSubtype:21
        }
        class Class extends A implements B {
          set setter(double _) => null; // testSetterNotSubtype:22
        }
        """, warnings: MessageKind.INVALID_OVERRIDE_SETTER,
             infos: MessageKind.INVALID_OVERRIDDEN_SETTER),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:23
        }
        class B {
          set setter(String _) => null; // testSetterNotSubtype:24
        }
        class Class extends A implements B {
          set setter(double _) => null; // testSetterNotSubtype:25
        }
        """, warnings: [MessageKind.INVALID_OVERRIDE_SETTER,
                        MessageKind.INVALID_OVERRIDE_SETTER],
             infos: [MessageKind.INVALID_OVERRIDDEN_SETTER,
                     MessageKind.INVALID_OVERRIDDEN_SETTER]),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:26
        }
        class B {
          set setter(String _) => null; // testSetterNotSubtype:27
        }
        class Class implements A, B {
          set setter(double _) => null; // testSetterNotSubtype:28
        }
        """, warnings: [MessageKind.INVALID_OVERRIDE_SETTER,
                        MessageKind.INVALID_OVERRIDE_SETTER],
             infos: [MessageKind.INVALID_OVERRIDDEN_SETTER,
                     MessageKind.INVALID_OVERRIDDEN_SETTER]),

  // TODO(johnniwinther): These are unclear. Issue 16443 has been filed.
  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:29
        }
        class B {
          set setter(num _) => null; // testSetterNotSubtype:30
        }
        abstract class C implements A, B {
        }
        class Class implements C {
          set setter(double _) => null; // testSetterNotSubtype:31
        }
        """, warnings: MessageKind.INVALID_OVERRIDE_SETTER,
             infos: MessageKind.INVALID_OVERRIDDEN_SETTER),

  check("""
        class A {
          set setter(int _) => null; // testSetterNotSubtype:32
        }
        class B {
          set setter(num _) => null; // testSetterNotSubtype:33
        }
        abstract class C implements A, B {
        }
        class Class implements C {
          set setter(String _) => null; // testSetterNotSubtype:34
        }
        """, warnings: [MessageKind.INVALID_OVERRIDE_SETTER,
                        MessageKind.INVALID_OVERRIDE_SETTER],
             infos: [MessageKind.INVALID_OVERRIDDEN_SETTER,
                     MessageKind.INVALID_OVERRIDDEN_SETTER]),
  ]);
}

Future testFieldNotSubtype() {
  return Future.wait([
    check("""
          class A {
            int field; // testFieldNotSubtype:1
          }
          class Class extends A {
            int field; // testFieldNotSubtype:2
          }
          """),

    check("""
          class A {
            num field; // testFieldNotSubtype:3
          }
          class Class extends A {
            int field; // testFieldNotSubtype:4
          }
          """),

    check("""
          class A {
            int field; // testFieldNotSubtype:5
          }
          class Class extends A {
            num field; // testFieldNotSubtype:6
          }
          """),

    check("""
          class A {
            int field; // testFieldNotSubtype:7
          }
          class Class extends A {
            double field; // testFieldNotSubtype:8
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_FIELD,
               infos: MessageKind.INVALID_OVERRIDDEN_FIELD),

    check("""
          class A {
            int field; // testFieldNotSubtype:9
          }
          class B extends A {
            num field; // testFieldNotSubtype:10
          }
          class Class extends B {
            double field; // testFieldNotSubtype:11
          }
          """),

    check("""
          class A {
            num field; // testFieldNotSubtype:12
          }
          class Class extends A {
            int get field => null; // testFieldNotSubtype:13
          }
          """),

    check("""
          class A {
            num field; // testFieldNotSubtype:14
          }
          class Class extends A {
            String get field => null; // testFieldNotSubtype:15
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_FIELD_WITH_GETTER,
               infos: MessageKind.INVALID_OVERRIDDEN_FIELD),

    check("""
          class A {
            num get field => null; // testFieldNotSubtype:16
          }
          class Class extends A {
            String field; // testFieldNotSubtype:17
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_GETTER_WITH_FIELD,
               infos: MessageKind.INVALID_OVERRIDDEN_GETTER),

    check("""
          class A {
            num field; // testFieldNotSubtype:18
          }
          class Class extends A {
            set field(int _) {} // testFieldNotSubtype:19
          }
          """),

    check("""
          class A {
            num field; // testFieldNotSubtype:19
          }
          class Class extends A {
            void set field(int _) {} // testFieldNotSubtype:20
          }
          """),

    check("""
          class A {
            set field(int _) {} // testFieldNotSubtype:21
          }
          class Class extends A {
            num field; // testFieldNotSubtype:22
          }
          """),

    check("""
          class A {
            void set field(int _) {} // testFieldNotSubtype:23
          }
          class Class extends A {
            num field; // testFieldNotSubtype:24
          }
          """),

    check("""
          class A {
            num field; // testFieldNotSubtype:25
          }
          class Class extends A {
            set field(String _) {} // testFieldNotSubtype:26
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_FIELD_WITH_SETTER,
               infos: MessageKind.INVALID_OVERRIDDEN_FIELD),

    check("""
          class A {
            set field(num _) {} // testFieldNotSubtype:27
          }
          class Class extends A {
            String field; // testFieldNotSubtype:28
          }
          """, warnings: MessageKind.INVALID_OVERRIDE_SETTER_WITH_FIELD,
               infos: MessageKind.INVALID_OVERRIDDEN_SETTER),

    check("""
          class A {
            int field; // testFieldNotSubtype:29
          }
          class Class implements A {
            String get field => null; // testFieldNotSubtype:30
            void set field(String s) {} // testFieldNotSubtype:31
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_FIELD_WITH_GETTER,
                          MessageKind.INVALID_OVERRIDE_FIELD_WITH_SETTER],
               infos: [MessageKind.INVALID_OVERRIDDEN_FIELD,
                       MessageKind.INVALID_OVERRIDDEN_FIELD]),


    check("""
          class A {
            String get field => null; // testFieldNotSubtype:32
            void set field(String s) {} // testFieldNotSubtype:33
          }
          class Class implements A {
            int field; // testFieldNotSubtype:34
          }
          """, warnings: [MessageKind.INVALID_OVERRIDE_GETTER_WITH_FIELD,
                          MessageKind.INVALID_OVERRIDE_SETTER_WITH_FIELD],
               infos: [MessageKind.INVALID_OVERRIDDEN_GETTER,
                       MessageKind.INVALID_OVERRIDDEN_SETTER]),
  ]);
}

Future testMixedOverride() {
  return Future.wait([
    check("""
          class A {
            var member; // testMixedOverride:1
          }
          class Class extends A {
            member() {} // testMixedOverride:2
          }
          """, errors: MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD,
               infos: MessageKind.CANNOT_OVERRIDE_FIELD_WITH_METHOD_CONT),

    check("""
          class A {
            member() {} // testMixedOverride:3
          }
          class Class extends A {
            var member; // testMixedOverride:4
          }
          """, errors: MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD,
               infos: MessageKind.CANNOT_OVERRIDE_METHOD_WITH_FIELD_CONT),

    check("""
          class A {
            get member => null; // testMixedOverride:5
          }
          class Class extends A {
            member() {} // testMixedOverride:6
          }
          """, errors: MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD,
               infos: MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT),

    check("""
          class A {
            member() {} // testMixedOverride:7
          }
          class Class extends A {
            get member => null; // testMixedOverride:8
          }
          """, errors: MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER,
               infos: MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT),

    check("""
          abstract class A {
            var member; // testMixedOverride:9
          }
          abstract class B {
            get member; // testMixedOverride:10
          }
          abstract class Class implements A, B {
          }
          """),

    check("""
          abstract class A {
            var member; // testMixedOverride:11
          }
          abstract class B {
            member() {} // testMixedOverride:12
          }
          abstract class Class implements A, B {
          }
          """, warnings: MessageKind.INHERIT_GETTER_AND_METHOD,
               infos: [MessageKind.INHERITED_METHOD,
                       MessageKind.INHERITED_IMPLICIT_GETTER]),

    check("""
          abstract class A {
            get member; // testMixedOverride:13
          }
          abstract class B {
            member() {} // testMixedOverride:14
          }
          abstract class Class implements A, B {
          }
          """, warnings: MessageKind.INHERIT_GETTER_AND_METHOD,
               infos: [MessageKind.INHERITED_METHOD,
                       MessageKind.INHERITED_EXPLICIT_GETTER]),

    check("""
          abstract class A {
            get member; // testMixedOverride:15
          }
          abstract class B {
            member() {} // testMixedOverride:16
          }
          abstract class C {
            var member; // testMixedOverride:17
          }
          abstract class D {
            member() {} // testMixedOverride:18
          }
          abstract class E {
            get member; // testMixedOverride:19
          }
          abstract class Class implements A, B, C, D, E {
          }
          """, warnings: MessageKind.INHERIT_GETTER_AND_METHOD,
               infos: [MessageKind.INHERITED_EXPLICIT_GETTER,
                       MessageKind.INHERITED_METHOD,
                       MessageKind.INHERITED_IMPLICIT_GETTER,
                       MessageKind.INHERITED_METHOD,
                       MessageKind.INHERITED_EXPLICIT_GETTER]),

    check("""
          abstract class A {
            get member; // testMixedOverride:20
          }
          abstract class B {
            member() {} // testMixedOverride:21
          }
          abstract class C implements A, B {
          }
          class Class extends C {
            member() {} // testMixedOverride:22
          }
          """, errors: MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD,
               warnings: MessageKind.INHERIT_GETTER_AND_METHOD,
               infos: [MessageKind.INHERITED_METHOD,
                       MessageKind.INHERITED_EXPLICIT_GETTER,
                       MessageKind.CANNOT_OVERRIDE_GETTER_WITH_METHOD_CONT]),

    check("""
          abstract class A {
            get member; // testMixedOverride:23
          }
          abstract class B {
            member() {} // testMixedOverride:24
          }
          abstract class C implements A, B {
          }
          class Class extends C {
            get member => null; // testMixedOverride:25
          }
          """, errors: MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER,
               warnings: MessageKind.INHERIT_GETTER_AND_METHOD,
               infos: [MessageKind.INHERITED_METHOD,
                       MessageKind.INHERITED_EXPLICIT_GETTER,
                       MessageKind.CANNOT_OVERRIDE_METHOD_WITH_GETTER_CONT]),
  ]);
}

Future testAbstractMethods() {
  return Future.wait([
    check("""
          abstract class Class {
            method(); // testAbstractMethod:1
          }
          """),

    check("""
          class Class {
            method(); // testAbstractMethod:2
          }
          """, warnings: MessageKind.ABSTRACT_METHOD,
               infos: []),

    check("""
          class Class {
            get getter; // testAbstractMethod:3
          }
          """, warnings: MessageKind.ABSTRACT_GETTER,
               infos: []),

    check("""
          class Class {
            set setter(_); // testAbstractMethod:4
          }
          """, warnings: MessageKind.ABSTRACT_SETTER,
               infos: []),

    check("""
          abstract class A {
            method(); // testAbstractMethod:5
          }
          class Class extends A {
            method() {} // testAbstractMethod:6
          }
          """),

    check("""
          abstract class A {
            method(); // testAbstractMethod:7
          }
          class Class extends A {
            method([a]) {} // testAbstractMethod:8
          }
          """),

    check("""
          abstract class A {
            method(); // testAbstractMethod:9
          }
          class Class extends A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          abstract class A {
            get getter; // testAbstractMethod:10
          }
          class Class extends A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_GETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER),

    check("""
          abstract class A {
            set setter(_); // testAbstractMethod:11
          }
          class Class extends A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_SETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER),

    check("""
          abstract class A {
            method(); // testAbstractMethod:12
          }
          class B {
            method() {} // testAbstractMethod:13
          }
          class Class extends A implements B {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD,
               infos: [MessageKind.UNIMPLEMENTED_METHOD_CONT,
                       MessageKind.UNIMPLEMENTED_METHOD_CONT]),

    check("""
          class Class implements Function {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: []),

    check("""
          abstract class A {
            get getter; // testAbstractMethod:14
          }
          class B {
            get getter => 0; // testAbstractMethod:15
          }
          class Class extends A implements B {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_GETTER,
               infos: [MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER]),

    check("""
          abstract class A {
            set setter(_); // testAbstractMethod:16
          }
          class B {
            set setter(_) {} // testAbstractMethod:17
          }
          class Class extends A implements B {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_SETTER,
               infos: [MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER,
                       MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER]),

    check("""
          abstract class A {
            get field; // testAbstractMethod:18
          }
          class B {
            var field; // testAbstractMethod:19
          }
          class Class extends A implements B {
            set field(_) {} // testAbstractMethod:20
          }
          """, warnings: MessageKind.UNIMPLEMENTED_GETTER,
               infos: [MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER]),

    check("""
          abstract class A {
            set field(_); // testAbstractMethod:21
          }
          class B {
            var field; // testAbstractMethod:22
          }
          class Class extends A implements B {
            get field => 0; // testAbstractMethod:23
          }
          """, warnings: MessageKind.UNIMPLEMENTED_SETTER,
               infos: [MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER]),

    check("""
          class A {
            method() {} // testAbstractMethod:24
          }
          class Class implements A {
            method() {} // testAbstractMethod:25
          }
          """),

    check("""
          class A {
            method() {} // testAbstractMethod:26
          }
          class Class implements A {
            method([a]) {} // testAbstractMethod:27
          }
          """),

    check("""
          class A {
            method() {} // testAbstractMethod:28
          }
          class Class implements A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          class A {
            method() {} // testAbstractMethod:29
          }
          class B {
            method() {} // testAbstractMethod:30
          }
          class Class extends A implements B {
          }
          """),

    check("""
          class A {
            var member; // testAbstractMethod:31
          }
          class Class implements A {
          }
          """, warnings: [MessageKind.UNIMPLEMENTED_GETTER_ONE,
                          MessageKind.UNIMPLEMENTED_SETTER_ONE],
               infos: [MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER]),

    check("""
          class A {
            var member; // testAbstractMethod:32
          }
          class B {
            get member => null; // testAbstractMethod:33
            set member(_) {} // testAbstractMethod:34
          }
          class Class implements A, B {
          }
          """, warnings: [MessageKind.UNIMPLEMENTED_GETTER,
                          MessageKind.UNIMPLEMENTED_SETTER],
               infos: [MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER]),

    check("""
          class A {
            var member; // testAbstractMethod:35
          }
          class B {
            var member; // testAbstractMethod:36
          }
          class Class implements A, B {
          }
          """, warnings: [MessageKind.UNIMPLEMENTED_GETTER,
                          MessageKind.UNIMPLEMENTED_SETTER],
               infos: [MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER,
                       MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER]),

    check("""
          class A {
            get member => 0; // testAbstractMethod:37
          }
          class Class implements A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_GETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_EXPLICIT_GETTER),

    check("""
          class A {
            set member(_) {} // testAbstractMethod:38
          }
          class Class implements A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_SETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_EXPLICIT_SETTER),

    check("""
          class A {
            var member; // testAbstractMethod:39
          }
          class Class implements A {
            get member => 0;
          }
          """, warnings: MessageKind.UNIMPLEMENTED_SETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER),

    check("""
          class A {
            var field; // testAbstractMethod:40
          }
          class Class implements A {
            final field = 0; // testAbstractMethod:41
          }
          """, warnings: MessageKind.UNIMPLEMENTED_SETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_IMPLICIT_SETTER),

    check("""
          class A {
            var member; // testAbstractMethod:42
          }
          class Class implements A {
            set member(_) {}
          }
          """, warnings: MessageKind.UNIMPLEMENTED_GETTER_ONE,
               infos: MessageKind.UNIMPLEMENTED_IMPLICIT_GETTER),

    check("""
          abstract class A {
            method() {} // testAbstractMethod:43
          }
          class Class extends A {
            method();
          }
          """),
  ]);
}

Future testNoSuchMethod() {
  return Future.wait([
    check("""
          class Class {
            method(); // testNoSuchMethod:1
          }
          """, warnings: MessageKind.ABSTRACT_METHOD,
               infos: []),

    check("""
          @proxy
          class Class {
            method(); // testNoSuchMethod:2
          }
          """, warnings: MessageKind.ABSTRACT_METHOD,
               infos: []),

    check("""
          class Class {
            noSuchMethod(_) => null;
            method(); // testNoSuchMethod:3
          }
          """),

    check("""
          class Class {
            noSuchMethod(_, [__]) => null;
            method(); // testNoSuchMethod:4
          }
          """),

    check("""
          class Class {
            noSuchMethod(_);
            method(); // testNoSuchMethod:5
          }
          """),

    check("""
          abstract class A {
            method(); // testNoSuchMethod:6
          }
          class Class extends A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          abstract class A {
            method(); // testNoSuchMethod:7
          }
          @proxy
          class Class extends A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          abstract class A {
            method(); // testNoSuchMethod:8
          }
          class Class extends A {
            noSuchMethod(_) => null;
          }
          """),

    check("""
          class A {
            method() {} // testNoSuchMethod:9
          }
          class Class implements A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          class A {
            method() {} // testNoSuchMethod:10
          }
          class Class implements A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          class A {
            method() {} // testNoSuchMethod:11
          }
          @proxy
          class Class implements A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),

    check("""
          class A {
            method() {} // testNoSuchMethod:12
          }
          class Class implements A {
            noSuchMethod(_) => null;
          }
          """),

    check("""
          class A {
            noSuchMethod(_) => null;
            method(); // testNoSuchMethod:13
          }
          class Class extends A {
          }
          """, warnings: MessageKind.UNIMPLEMENTED_METHOD_ONE,
               infos: MessageKind.UNIMPLEMENTED_METHOD_CONT),
  ]);
}
