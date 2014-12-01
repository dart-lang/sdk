/// Tests for type inference.
library ddc.test.inferred_type_test;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'package:ddc/src/testing.dart';

main() {
  useCompactVMConfiguration();
  test('infer type on var', () {
    // Error also expected when declared type is `int`.
    testChecker({'/main.dart': '''
      test1() {
        int x = 3;
        x = /*severe:StaticTypeError*/"hi";
      }
    '''});

    // If inferred type is `int`, error is also reported
    testChecker({'/main.dart': '''
      test2() {
        var x = 3;
        x = /*severe:StaticTypeError*/"hi";
      }
    '''});
  });

  test('do not infer type on dynamic', () {
    testChecker({'/main.dart': '''
      test() {
        dynamic x = /*config:Box*/3;
        x = "hi";
      }
    '''});
  });

  test('propagate inference to field in class', () {
    testChecker({'/main.dart': '''
      class A {
        int x = 2;
      }

      test() {
        var a = new A();
        A b = a;        // doesn't require down cast
        print(a.x);     // doesn't require dynamic invoke
        print(a.x + 2); // ok to use in bigger expression
      }
    '''});

    // Same code with dynamic yields warnings
    testChecker({'/main.dart': '''
      class A {
        int x = 2;
      }

      test() {
        dynamic a = new A();
        A b = /*info:DownCast*/a;
        print(/*warning:DynamicInvoke*/a.x);
        print((/*warning:DynamicInvoke*/a.x) + 2);
      }
    '''});

  });

  // The following tests are currently failing

  test('propagate inference transitively ', () {
    testChecker({'/main.dart': '''
      class A {
        int x = 2;
      }

      test5() {
        var a = new A();
        a.x = "hi"; // invalid, declared type is `int`, checker should complain
      }
    '''});

    testChecker({'/main.dart': '''
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
        print(/*warning:DynamicInvoke*/(
                /*warning:DynamicInvoke*/(
                  /*warning:DynamicInvoke*/(d1.c).b).a).x);
        D d2 = new D();
        print(/*config:Box*/d2.c.b.a.x);  
      }
    '''});

  });
}

