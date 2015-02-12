/// Tests for type inference.
library ddc.test.inferred_type_test;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'package:ddc/src/testing.dart';

main() {
  useCompactVMConfiguration();
  test('infer type on var', () {
    // Error also expected when declared type is `int`.
    testChecker({
      '/main.dart': '''
      test1() {
        int x = 3;
        x = /*severe:StaticTypeError*/"hi";
      }
    '''
    });

    // If inferred type is `int`, error is also reported
    testChecker({
      '/main.dart': '''
      test2() {
        var x = 3;
        x = /*severe:StaticTypeError*/"hi";
      }
    '''
    });
  });

  // Error when declared type is `int` and assigned null.
  testChecker({
    '/main.dart': '''
      test1() {
        int x = 3;
        x = /*warning:DownCastLiteral*/null;
      }
    '''
  });

  // Error when inferred type is `int` and assigned null.
  testChecker({
    '/main.dart': '''
      test1() {
        var x = 3;
        x = /*warning:DownCastLiteral*/null;
      }
    '''
  });

  // No error when declared type is `num` and assigned null.
  testChecker({
    '/main.dart': '''
      test1() {
        num x = 3;
        x = null;
      }
    '''
  });

  test('do not infer type on dynamic', () {
    testChecker({
      '/main.dart': '''
      test() {
        dynamic x = 3;
        x = "hi";
      }
    '''
    });
  });

  test('do not infer type when initializer is null', () {
    testChecker({
      '/main.dart': '''
      test() {
        var x = null;
        x = "hi";
        x = 3;
      }
    '''
    });
  });

  test('infer type on var from field', () {
    testChecker({
      '/main.dart': '''
      int x = 0;

      test1() {
        var a = x;
        a = /*severe:StaticTypeError*/"hi";
        a = 3;
        var b = y;
        b = /*severe:StaticTypeError*/"hi";
        b = 4;
        var c = z;
        c = /*pass should be severe:StaticTypeError*/"hi";
        c = 4;
      }

      int y = 0; // field def after use
      final z = 42; // should infer `int`
    '''
    });
  });

  test('infer types on loop indices', () {
    // foreach loop
    testChecker({
      '/main.dart': '''
      class Foo {
        int bar = 42;
      }

      test() {
        var l = List<Foo>();
        for (var x in list) {
          String y = /*info:DownCast should be severe:StaticTypeError*/x;
        }
      }
      '''
    });

    // for loop, with inference
    testChecker({
      '/main.dart': '''
      test() {
        for (var i = 0; i < 10; i++) {
          int j = i + 1;
        }
      }
      '''
    });
  });

  test('propagate inference to field in class', () {
    testChecker({
      '/main.dart': '''
      class A {
        int x = 2;
      }

      test() {
        var a = new A();
        A b = a;                      // doesn't require down cast
        print(a.x);     // doesn't require dynamic invoke
        print(a.x + 2); // ok to use in bigger expression
      }
    '''
    });

    // Same code with dynamic yields warnings
    testChecker({
      '/main.dart': '''
      class A {
        int x = 2;
      }

      test() {
        dynamic a = new A();
        A b = /*info:DownCast*/a;
        print(/*warning:DynamicInvoke*/a.x);
        print((/*warning:DynamicInvoke*/a.x) + 2);
      }
    '''
    });
  });

  test('propagate inference transitively ', () {
    testChecker({
      '/main.dart': '''
      class A {
        int x = 2;
      }

      test5() {
        var a1 = new A();
        a1.x = /*severe:StaticTypeError*/"hi";

        A a2 = new A();
        a2.x = /*severe:StaticTypeError*/"hi";
      }
    '''
    });

    testChecker({
      '/main.dart': '''
      class A {
        int x = 42;
      }

      class B {
        A a = new A();
      }

      class C {
        B b = new B();
      }

      class D {
        C c = new C();
      }

      void main() {
        var d1 = new D();
        print(d1.c.b.a.x);

        D d2 = new D();
        print(d2.c.b.a.x);
      }
    '''
    });
  });
}
