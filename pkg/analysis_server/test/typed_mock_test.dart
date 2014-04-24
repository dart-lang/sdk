library test.typed_mock;

import 'package:unittest/unittest.dart';

import 'typed_mock.dart';


abstract class TestInterface {
  int get testProperty;
  set testProperty(x);
  String testMethod0();
  String testMethod1(int p);
}


class TestInterfaceMock extends TypedMock implements TestInterface {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


main() {
  group("TypedMock", () {
    test('then for getter', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testProperty).thenInvoke(() => 123);
      expect(obj.testProperty, 123);
    });

    test('then for method with 1 argument', () {
      TestInterface obj = new TestInterfaceMock();
      // TODO(scheglov) implement argument matchers
      when(obj.testMethod1(5)).thenInvoke((int p) => p + 10);
      expect(obj.testMethod1(1), equals(1 + 10));
      expect(obj.testMethod1(2), 2 + 10);
      expect(obj.testMethod1(10), 10 + 10);
    });

    test('thenReturn can replace behavior', () {
      TestInterface obj = new TestInterfaceMock();
      // set a behavior
      when(obj.testProperty).thenReturn(10);
      expect(obj.testProperty, 10);
      // set another behavior
      when(obj.testProperty).thenReturn(20);
      expect(obj.testProperty, 20);
    });

    test('thenReturn for getter', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testProperty).thenReturn(42);
      expect(obj.testProperty, 42);
      expect(obj.testProperty, 42);
    });

    test('thenReturn for method with 0 arguments', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod0()).thenReturn('abc');
      expect(obj.testMethod0(), 'abc');
      expect(obj.testMethod0(), 'abc');
    });

    test('thenReturn for method with 1 argument', () {
      TestInterface obj = new TestInterfaceMock();
      // TODO(scheglov) implement argument matchers
      when(obj.testMethod1(1)).thenReturn('qwerty');
      expect(obj.testMethod1(2), 'qwerty');
      expect(obj.testMethod1(3), 'qwerty');
    });

    test('thenThrow for getter', () {
      TestInterface obj = new TestInterfaceMock();
      Exception e = new Exception();
      when(obj.testProperty).thenThrow(e);
      expect(() => obj.testProperty, throwsA(e));
    });

    test('thenThrow for setter', () {
      TestInterface obj = new TestInterfaceMock();
      Exception e = new Exception();
      // TODO(scheglov) implement argument matchers
      when(obj.testProperty = 1).thenThrow(e);
      expect(
        () {
          obj.testProperty = 2;
        },
        throwsA(e));
    });
  });
}