library test.typed_mock;

import 'package:unittest/unittest.dart';

import 'typed_mock.dart' hide equals;
import 'typed_mock.dart' as typed_mocks show equals;


abstract class TestInterface {
  int get testProperty;
  set testProperty(x);
  int get testPropertyB;
  String testMethod0();
  String testMethod1(a);
  String testMethod2(String a, int b);
  void testMethodVoid(a);
  int operator [](index);
}


class TestInterfaceMock extends TypedMock implements TestInterface {
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


main() {
  // lets make it redable
  groupSep = ' | ';

  group('VerifyError', () {
    test('VerifyError', () {
      var error = new VerifyError('msg');
      expect(error.message, 'msg');
      expect(error.toString(), 'VerifyError: msg');
    });
  });

  group('Matchers', () {
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

  group('when', () {
    TestInterface obj;
    setUp(() {
      obj = new TestInterfaceMock();
    });

    test('thenInvoke for getter', () {
      when(obj.testProperty).thenInvoke(() => 123);
      expect(obj.testProperty, 123);
    });

    test('thenInvoke for method with 1 argument', () {
      when(obj.testMethod1(anyInt)).thenInvoke((int p) => p + 10);
      expect(obj.testMethod1(1), 1 + 10);
      expect(obj.testMethod1(2), 2 + 10);
      expect(obj.testMethod1(10), 10 + 10);
    });

    test('thenReturn can replace behavior, getter', () {
      // set a behavior
      when(obj.testProperty).thenReturn(10);
      expect(obj.testProperty, 10);
      // set another behavior
      when(obj.testProperty).thenReturn(20);
      expect(obj.testProperty, 20);
    });

    test('thenReturn for getter', () {
      when(obj.testProperty).thenReturn(42);
      expect(obj.testProperty, 42);
      expect(obj.testProperty, 42);
    });

    test('thenReturn for []', () {
      when(obj[1]).thenReturn(10);
      when(obj[2]).thenReturn(20);
      when(obj[anyInt]).thenReturn(99);
      expect(obj[1], 10);
      expect(obj[2], 20);
      expect(obj[5], 99);
    });

    test('thenReturn for method with 0 arguments', () {
      when(obj.testMethod0()).thenReturn('abc');
      expect(obj.testMethod0(), 'abc');
      expect(obj.testMethod0(), 'abc');
    });

    test('thenReturn for method with 1 argument, anyBool', () {
      when(obj.testMethod1(anyBool)).thenReturn('qwerty');
      expect(obj.testMethod1(true), 'qwerty');
      expect(obj.testMethod1(false), 'qwerty');
    });

    test('thenReturn for method with 1 argument, anyInt', () {
      when(obj.testMethod1(anyInt)).thenReturn('qwerty');
      expect(obj.testMethod1(2), 'qwerty');
      expect(obj.testMethod1(3), 'qwerty');
    });

    test('thenReturn for method with 1 argument, anyObject', () {
      when(obj.testMethod1(anyObject)).thenReturn('qwerty');
      expect(obj.testMethod1([]), 'qwerty');
      expect(obj.testMethod1([1, 2, 3]), 'qwerty');
    });

    test('thenReturn for method with 1 argument, argument value', () {
      when(obj.testMethod1(10)).thenReturn('ten');
      when(obj.testMethod1(20)).thenReturn('twenty');
      expect(obj.testMethod1(10), 'ten');
      expect(obj.testMethod1(10), 'ten');
      expect(obj.testMethod1(20), 'twenty');
      expect(obj.testMethod1(20), 'twenty');
    });

    test('thenReturn for method with 2 arguments', () {
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
      when(obj.testProperty).thenReturnList(['a', 'b', 'c']);
      expect(obj.testProperty, 'a');
      expect(obj.testProperty, 'b');
      expect(obj.testProperty, 'c');
      expect(() => obj.testProperty, throwsA(new isInstanceOf<StateError>()));
    });

    test('thenThrow for getter', () {
      Exception e = new Exception();
      when(obj.testProperty).thenThrow(e);
      expect(() => obj.testProperty, throwsA(e));
    });

    test('thenThrow for setter, anyInt', () {
      Exception e = new Exception();
      when(obj.testProperty = anyInt).thenThrow(e);
      expect(() => (obj.testProperty = 2), throwsA(e));
    });

    test('thenThrow for setter, argument value', () {
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

  group('verify', () {
    TestInterface obj;
    setUp(() {
      obj = new TestInterfaceMock();
    });

    group('times', () {
      test('OK, getter', () {
        obj.testProperty;
        obj.testProperty;
        verify(obj.testProperty).times(2);
      });

      test('OK, 2 getters', () {
        obj.testProperty;
        obj.testPropertyB;
        obj.testProperty;
        verify(obj.testProperty).times(2);
        verify(obj.testPropertyB).times(1);
      });

      test('OK, method with 1 argument', () {
        obj.testMethod1(10);
        obj.testMethod1('abc');
        obj.testMethod1(20);
        verify(obj.testMethod1(10)).times(1);
        verify(obj.testMethod1(20)).times(1);
        verify(obj.testMethod1(30)).times(0);
        verify(obj.testMethod1(anyInt)).times(2);
        verify(obj.testMethod1(anyString)).times(1);
        verify(obj.testMethod1(anyBool)).times(0);
      });

      test('OK, getter, with thenReturn', () {
        when(obj.testProperty).thenReturn('abc');
        obj.testProperty;
        obj.testProperty;
        verify(obj.testProperty).times(2);
      });

    test('OK, void method', () {
      obj.testMethodVoid(10);
      obj.testMethodVoid(20);
      verify(obj.testMethodVoid(anyInt)).times(2);
    });

      test('mismatch, getter', () {
        obj.testProperty;
        obj.testProperty;
        obj.testProperty;
        expect(() {
          verify(obj.testProperty).times(2);
        }, throwsA(_isVerifyError));
      });
    });

    group('never', () {
      test('OK', () {
        verify(obj.testProperty).never();
      });
      test('mismatch', () {
        obj.testProperty;
        expect(() {
          verify(obj.testProperty).never();
        }, throwsA(_isVerifyError));
      });
    });

    group('once', () {
      test('OK', () {
        obj.testProperty;
        verify(obj.testProperty).once();
      });
      test('mismatch, actually 0', () {
        expect(() {
          verify(obj.testProperty).once();
        }, throwsA(_isVerifyError));
      });
      test('mismatch, actually 2', () {
        obj.testProperty;
        obj.testProperty;
        expect(() {
          verify(obj.testProperty).once();
        }, throwsA(_isVerifyError));
      });
    });

    group('atLeast', () {
      test('OK, 1', () {
        obj.testProperty;
        verify(obj.testProperty).atLeast(1);
      });
      test('OK, 2', () {
        obj.testProperty;
        obj.testProperty;
        verify(obj.testProperty).atLeast(1);
        verify(obj.testProperty).atLeast(2);
      });
      test('mismatch', () {
        obj.testProperty;
        obj.testProperty;
        expect(() {
          verify(obj.testProperty).atLeast(10);
        }, throwsA(_isVerifyError));
      });
    });

    group('atMost', () {
      test('OK, 0', () {
        verify(obj.testProperty).atMost(5);
        verify(obj.testProperty).atMost(0);
      });
      test('OK, 2', () {
        obj.testProperty;
        obj.testProperty;
        verify(obj.testProperty).atMost(5);
        verify(obj.testProperty).atMost(3);
        verify(obj.testProperty).atMost(2);
      });
      test('mismatch', () {
        obj.testProperty;
        obj.testProperty;
        obj.testProperty;
        expect(() {
          verify(obj.testProperty).atMost(2);
        }, throwsA(_isVerifyError));
      });
    });
  });
}

const _isVerifyError = const isInstanceOf<VerifyError>();
