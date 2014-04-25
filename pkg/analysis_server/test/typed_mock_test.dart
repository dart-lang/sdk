library test.typed_mock;

import 'package:unittest/unittest.dart';

import 'typed_mock.dart' hide equals;
import 'typed_mock.dart' as typed_mocks show equals;


abstract class TestInterface {
  int get testProperty;
  set testProperty(x);
  String testMethod0();
  String testMethod1(int a);
  String testMethod1b(bool a);
  String testMethod1o(List a);
  String testMethod2(String a, int b);
  int operator [](index);
}


class TestInterfaceMock extends TypedMock implements TestInterface {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


main() {
  group("Matchers", () {
    test('equals', () {
      expect(typed_mocks.equals(10).match(10), true);
      expect(typed_mocks.equals(10).match(20), false);
      expect(typed_mocks.equals('abc').match('abc'), true);
      expect(typed_mocks.equals('abc').match('xyz'), false);
    });

    test('anyBool', () {
      expect(anyBool.match(true), true);
      expect(anyBool.match(false), true);
      expect(anyBool.match(0), false);
      expect(anyBool.match('0'), false);
    });

    test('anyInt', () {
      expect(anyInt.match(true), false);
      expect(anyInt.match(-99), true);
      expect(anyInt.match(0), true);
      expect(anyInt.match(42), true);
      expect(anyInt.match('0'), false);
    });

    test('anyObject', () {
      expect(anyObject.match(true), true);
      expect(anyObject.match(0), true);
      expect(anyObject.match('0'), true);
    });

    test('anyString', () {
      expect(anyString.match(true), false);
      expect(anyString.match(0), false);
      expect(anyString.match(''), true);
      expect(anyString.match('0'), true);
      expect(anyString.match('abc'), true);
    });
  });

  group("TypedMock", () {
    test('thenInvoke for getter', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testProperty).thenInvoke(() => 123);
      expect(obj.testProperty, 123);
    });

    test('thenInvoke for method with 1 argument', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod1(anyInt)).thenInvoke((int p) => p + 10);
      expect(obj.testMethod1(1), 1 + 10);
      expect(obj.testMethod1(2), 2 + 10);
      expect(obj.testMethod1(10), 10 + 10);
    });

    test('thenReturn can replace behavior, getter', () {
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

    test('thenReturn for []', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj[1]).thenReturn(10);
      when(obj[2]).thenReturn(20);
      when(obj[anyInt]).thenReturn(99);
      expect(obj[1], 10);
      expect(obj[2], 20);
      expect(obj[5], 99);
    });

    test('thenReturn for method with 0 arguments', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod0()).thenReturn('abc');
      expect(obj.testMethod0(), 'abc');
      expect(obj.testMethod0(), 'abc');
    });

    test('thenReturn for method with 1 argument, anyBool', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod1b(anyBool)).thenReturn('qwerty');
      expect(obj.testMethod1b(true), 'qwerty');
      expect(obj.testMethod1b(false), 'qwerty');
    });

    test('thenReturn for method with 1 argument, anyInt', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod1(anyInt)).thenReturn('qwerty');
      expect(obj.testMethod1(2), 'qwerty');
      expect(obj.testMethod1(3), 'qwerty');
    });

    test('thenReturn for method with 1 argument, anyObject', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod1o(anyObject)).thenReturn('qwerty');
      expect(obj.testMethod1o([]), 'qwerty');
      expect(obj.testMethod1o([1, 2, 3]), 'qwerty');
    });

    test('thenReturn for method with 1 argument, argument value', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod1(10)).thenReturn('ten');
      when(obj.testMethod1(20)).thenReturn('twenty');
      expect(obj.testMethod1(10), 'ten');
      expect(obj.testMethod1(10), 'ten');
      expect(obj.testMethod1(20), 'twenty');
      expect(obj.testMethod1(20), 'twenty');
    });

    test('thenReturn for method with 2 arguments', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testMethod2(anyString, 10)).thenReturn('any+10');
      when(obj.testMethod2(anyString, 20)).thenReturn('any+20');
      when(obj.testMethod2(anyString, anyInt)).thenReturn('everything else');
      expect(obj.testMethod2('aaa', 10), 'any+10');
      expect(obj.testMethod2('bbb', 10), 'any+10');
      expect(obj.testMethod2('ccc', 20), 'any+20');
      expect(obj.testMethod2('ddd', 20), 'any+20');
      expect(obj.testMethod2('eee', 99), 'everything else');
    });

    test('thenReturnList for getter', () {
      TestInterface obj = new TestInterfaceMock();
      when(obj.testProperty).thenReturnList(['a', 'b', 'c']);
      expect(obj.testProperty, 'a');
      expect(obj.testProperty, 'b');
      expect(obj.testProperty, 'c');
      expect(() => obj.testProperty, throwsA(new isInstanceOf<StateError>()));
    });

    test('thenThrow for getter', () {
      TestInterface obj = new TestInterfaceMock();
      Exception e = new Exception();
      when(obj.testProperty).thenThrow(e);
      expect(() => obj.testProperty, throwsA(e));
    });

    test('thenThrow for setter, anyInt', () {
      TestInterface obj = new TestInterfaceMock();
      Exception e = new Exception();
      when(obj.testProperty = anyInt).thenThrow(e);
      expect(() => (obj.testProperty = 2), throwsA(e));
    });

    test('thenThrow for setter, argument value', () {
      TestInterface obj = new TestInterfaceMock();
      Exception e1 = new Exception('one');
      Exception e2 = new Exception('two');
      when(obj.testProperty = 1).thenThrow(e1);
      when(obj.testProperty = 2).thenThrow(e2);
      expect(() => (obj.testProperty = 1), throwsA(e1));
      expect(() => (obj.testProperty = 1), throwsA(e1));
      expect(() => (obj.testProperty = 2), throwsA(e2));
      expect(() => (obj.testProperty = 2), throwsA(e2));
    });
  });
}
