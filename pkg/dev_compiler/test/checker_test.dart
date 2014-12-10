/// Tests for type inference.
library ddc.test.inferred_type_test;

import 'package:unittest/compact_vm_config.dart';
import 'package:unittest/unittest.dart';

import 'package:ddc/src/testing.dart';

main() {
  useCompactVMConfiguration();

  test('conversion and dynamic invoke', () {
    testChecker({
      '/main.dart': '''
      class A {
        String x = "hello world";
      }

      void foo(String str) {
        print(str);
      }

      void bar(a) {
        foo(/*info:DownCast,warning:DynamicInvoke*/a.x);
      }

      void main() => bar(new A());
    '''
    });
  });
}
