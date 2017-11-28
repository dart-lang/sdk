// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS("ArrayTest.Util")
library js_array_test;

import 'dart:html';

import 'dart:js' as js;
import 'package:js/js.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'json_helper.dart' as json_helper;

_injectJs() {
  document.body.append(new ScriptElement()
    ..type = 'text/javascript'
    ..innerHtml = r"""
ArrayTest = {};
ArrayTest.Util = {
  callJsMethod: function(jsObj, jsMethodName, args) {
    return jsObj[jsMethodName].apply(jsObj, args);
  },

  jsEnumerateIndices: function(obj) {
    var ret = [];
    for(var i in obj) {
      ret.push(i);
    }
    return ret;
  },

  checkIsArray: function(obj) {
    return Array.isArray(obj);
  },

  concatValues: function(obj) {
    return obj.concat("a", "b", ["c", "d"], 42, {foo: 10});
  },

  concatOntoArray: function(obj) {
    return [1,2,3].concat(obj, "foo");
  },

  repeatedConcatOntoArray: function(obj) {
    return [1,2,3].concat(obj, obj);
  },

  everyGreaterThanZero: function(obj) {
    return obj.every(function(currentValue, index, array) {
      return currentValue > 0;
    });
  },

  everyGreaterThanZeroCheckThisArg: function(obj) {
    var j = 0;
    return obj.every(function(currentValue, index, array) {
      if (j != index) {
        throw "Unxpected index";
      }
      j++;
      if (array !== obj) {
        throw "Array argument doesn't match obj";
      }
      return currentValue > 0;
    });
  },

  filterGreater42: function(obj) {
    return obj.filter(function(currentValue, index, array) {
      return currentValue > 42;
    });
  },

  forEachCollectResult: function(array) {
    var result = [];
    array.forEach(function(currentValue) {
      result.push(currentValue * 2);
    });
    return result;
  },

  someEqual42: function(array) {
    return array.some(function(currentValue) {
      return currentValue == 42;
    });
  },

  sortNumbersBackwards: function(array) {
    return array.sort(function(a, b) {
      return b - a;
    });
  },

  spliceDummyItems: function(array) {
    return array.splice(1, 2, "quick" ,"brown", "fox");
  },

  spliceTestStringArgs: function(array) {
    return array.splice("1.2", "2.01", "quick" ,"brown", "fox");
  },

  splicePastEnd: function(array) {
    return array.splice(1, 5332, "quick" ,"brown", "fox");
  },

  callJsToString: function(array) {
    return array.toString();
  },

  mapAddIndexToEachElement: function(array) {
    return array.map(function(currentValue, index) {
      return currentValue + index;
    });
  },

  reduceSumDoubledElements: function(array) {
    return array.reduce(function(previousValue, currentValue) {
          return previousValue + currentValue*2;
        },
        0);
  },

  // TODO(jacobr): add a test that distinguishes reduce from reduceRight.
  reduceRightSumDoubledElements: function(array) {
    return array.reduceRight(function(previousValue, currentValue) {
          return previousValue + currentValue*2;
        },
        0);
  },

  getOwnPropertyDescriptor: function(array, property) {
    return Object.getOwnPropertyDescriptor(array, property);
  },

  setLength: function(array, len) {
    return array.length = len;
  },

  getValue: function(obj, index) {
    return obj[index];
  },

  setValue: function(obj, index, value) {
    return obj[index] = value;
  },

  // Calling a method from Dart List on an arbitrary target object.
  callListMethodOnTarget: function(dartArray, target, methodName, args) {
    return dartArray[methodName].apply(target, args);
  },

  newArray: function() { return []; },

  newLiteral: function() { return {}; },

};
""");
}

@JS()
class PropertyDescriptor {
  external get value;
  external bool get writable;
  external bool get enumerable;
  external bool get configurable;
}

@JS()
class SimpleJsLiteralClass {
  external get foo;
}

class Foo {}

@JS()
external callJsMethod(List array, String methodName, List args);

callIndexOf(List array, value) => callJsMethod(array, "indexOf", [value]);
callLastIndexOf(List array, value) =>
    callJsMethod(array, "lastIndexOf", [value]);

callPop(List array) => callJsMethod(array, "pop", []);
callPush(List array, element) => callJsMethod(array, "push", [element]);
callShift(List array) => callJsMethod(array, "shift", []);
callReverse(List array) => callJsMethod(array, "reverse", []);

callListMethodOnObject(object, String methodName, List args) =>
    callListMethodOnTarget([], object, methodName, args);

@JS()
external jsEnumerateIndices(obj);
@JS()
external bool checkIsArray(obj);
@JS()
external concatValues(obj);

@JS()
external concatOntoArray(obj);

@JS()
external repeatedConcatOntoArray(obj);
@JS()
external bool everyGreaterThanZero(obj);
@JS()
external bool everyGreaterThanZeroCheckThisArg(obj);

@JS()
external filterGreater42(obj);

@JS()
external forEachCollectResult(List array);
@JS()
external someEqual42(List array);
@JS()
external sortNumbersBackwards(List array);

@JS()
external List spliceDummyItems(List array);

@JS()
external List spliceTestStringArgs(List array);

@JS()
external List splicePastEnd(List array);

@JS()
external String callJsToString(List array);

@JS()
external mapAddIndexToEachElement(List array);
@JS()
external reduceSumDoubledElements(List array);

// TODO(jacobr): add a test that distinguishes reduce from reduceRight.
@JS()
external reduceRightSumDoubledElements(List array);

@JS()
external PropertyDescriptor getOwnPropertyDescriptor(obj, property);

@JS("setLength")
external callSetLength(List array, length);

@JS()
external getValue(obj, index);

@JS()
external setValue(obj, index, value);

@JS()
external callListMethodOnTarget(
    List target, object, String methodName, List args);

@JS()
external newArray();

@JS()
external newLiteral();

main() {
  _injectJs();
  useHtmlConfiguration();

  group('indexOf', () {
    var div = new DivElement();
    var list = [3, 42, "foo", 42, div];
    test('found', () {
      expect(callIndexOf(list, 3), equals(0));
      expect(callIndexOf(list, 42), equals(1));
      expect(callIndexOf(list, "foo"), equals(2));
      expect(callIndexOf(list, div), equals(4));
    });

    test('missing', () {
      expect(callIndexOf(list, 31), equals(-1));
      expect(callIndexOf(list, "42"), equals(-1));
      expect(callIndexOf(list, null), equals(-1));
    });
  });

  group('set length', () {
    test('larger', () {
      var list = ["a", "b", "c", "d"];
      expect(callSetLength(list, 10), equals(10));
      expect(list.length, equals(10));
      expect(list.last, equals(null));
      expect(list[3], equals("d"));
    });

    test('smaller', () {
      var list = ["a", "b", "c", "d"];
      expect(callSetLength(list, 2), equals(2));
      expect(list.first, equals("a"));
      expect(list.last, equals("b"));
      expect(list.length, equals(2));
      expect(callSetLength(list, 0), equals(0));
      expect(list.length, equals(0));
      expect(callSetLength(list, 2), equals(2));
      expect(list.first, equals(null));
    });

    test('invalid', () {
      var list = ["a", "b", "c", "d"];
      expect(() => callSetLength(list, 2.3), throws);
      expect(list.length, equals(4));
      expect(() => callSetLength(list, -1), throws);
      expect(list.length, equals(4));
      // Make sure we are coercing to a JS number.
      expect(callSetLength(list, "2"), equals("2"));
      expect(list.length, equals(2));
    });
  });

  group('join', () {
    var list = [3, 42, "foo"];
    var listWithDartClasses = [3, new Foo(), 42, "foo", new Object()];
    test('default', () {
      expect(callJsMethod(list, "join", []), equals("3,42,foo"));
      expect(callJsMethod(listWithDartClasses, "join", []),
          equals("3,${new Foo()},42,foo,${new Object()}"));
    });

    test('custom separator', () {
      expect(callJsMethod(list, "join", ["##"]), equals("3##42##foo"));
    });
  });

  group('lastIndexOf', () {
    var list = [3, 42, "foo", 42];
    test('found', () {
      expect(callLastIndexOf(list, 3), equals(0));
      expect(callLastIndexOf(list, 42), equals(3));
      expect(callLastIndexOf(list, "foo"), equals(2));
    });

    test('missing', () {
      expect(callLastIndexOf(list, 31), equals(-1));
      expect(callLastIndexOf(list, "42"), equals(-1));
      expect(callLastIndexOf(list, null), equals(-1));
    });
  });

  group('pop', () {
    test('all', () {
      var foo = new Foo();
      var div = new DivElement();
      var list = [3, 42, "foo", foo, div];
      expect(callPop(list), equals(div));
      expect(list.length, equals(4));
      expect(callPop(list), equals(foo));
      expect(list.length, equals(3));
      expect(callPop(list), equals("foo"));
      expect(list.length, equals(2));
      expect(callPop(list), equals(42));
      expect(list.length, equals(1));
      expect(callPop(list), equals(3));
      expect(list.length, equals(0));
      expect(callPop(list), equals(null));
      expect(list.length, equals(0));
    });
  });

  group('push', () {
    test('strings', () {
      var list = [];
      var div = new DivElement();
      expect(callPush(list, "foo"), equals(1));
      expect(callPush(list, "bar"), equals(2));
      // Calling push with 0 elements should do nothing.
      expect(callJsMethod(list, "push", []), equals(2));
      expect(callPush(list, "baz"), equals(3));
      expect(callPush(list, div), equals(4));
      expect(callJsMethod(list, "push", ["a", "b"]), equals(6));
      expect(list, equals(["foo", "bar", "baz", div, "a", "b"]));
    });
  });

  group('shift', () {
    test('all', () {
      var foo = new Foo();
      var div = new DivElement();
      var list = [3, 42, "foo", foo, div];
      expect(callShift(list), equals(3));
      expect(list.length, equals(4));
      expect(callShift(list), equals(42));
      expect(list.length, equals(3));
      expect(callShift(list), equals("foo"));
      expect(list.length, equals(2));
      expect(callShift(list), equals(foo));
      expect(list.length, equals(1));
      expect(callShift(list), equals(div));
      expect(list.length, equals(0));
      expect(callShift(list), equals(null));
      expect(list.length, equals(0));
    });
  });

  group('reverse', () {
    test('simple', () {
      var foo = new Foo();
      var div = new DivElement();
      var list = [div, 42, foo];
      callReverse(list);
      expect(list, equals([foo, 42, div]));
      list = [3, 42];
      callReverse(list);
      expect(list, equals([42, 3]));
    });
  });

  group('slice', () {
    test('copy', () {
      var foo = new Foo();
      var div = new DivElement();
      var list = [3, 42, "foo", foo, div];
      var copy = callJsMethod(list, "slice", []);
      expect(identical(list, copy), isFalse);
      expect(copy.length, equals(list.length));
      for (var i = 0; i < list.length; i++) {
        expect(list[i], equals(copy[i]));
      }
      expect(identical(list[3], copy[3]), isTrue);
      expect(identical(list[4], copy[4]), isTrue);

      copy.add("dummy");
      expect(list.length + 1, equals(copy.length));
    });

    test('specify start', () {
      var list = [3, 42, "foo"];
      var copy = callJsMethod(list, "slice", [1]);
      expect(copy.first, equals(42));
    });

    test('specify start and end', () {
      var list = [3, 42, 92, "foo"];
      var copy = callJsMethod(list, "slice", [1, 3]);
      expect(copy.first, equals(42));
      expect(copy.last, equals(92));
    });

    test('from end', () {
      var list = [3, 42, 92, "foo"];
      expect(callJsMethod(list, "slice", [-2]), equals([92, "foo"]));

      // Past the end of the front of the array.
      expect(callJsMethod(list, "slice", [-2, 3]), equals([92]));

      // Past the end of the front of the array.
      expect(callJsMethod(list, "slice", [-10, 2]), equals([3, 42]));
    });
  });

  group("js snippet tests", () {
    test("enumerate indices", () {
      var list = ["a", "b", "c", "d"];
      var indices = jsEnumerateIndices(list);
      expect(indices.length, equals(4));
      for (int i = 0; i < 4; i++) {
        expect(indices[i], equals('$i'));
      }
    });

    test("set element", () {
      var list = ["a", "b", "c", "d"];
      setValue(list, 0, 42);
      expect(list[0], equals(42));
      setValue(list, 1, 84);
      expect(list[1], equals(84));
      setValue(list, 6, 100); // Off the end of the list.
      expect(list.length, equals(7));
      expect(list[4], equals(null));
      expect(list[6], equals(100));

      // These tests have to be commented out because we don't persist
      // JS proxies for Dart objects like we could/should.
      // setValue(list, -1, "foo"); // Not a valid array index
      // expect(getValue(list, -1), equals("foo"));
      // expect(getValue(list, "-1"), equals("foo"));
    });

    test("get element", () {
      var list = ["a", "b", "c", "d"];
      expect(getValue(list, 0), equals("a"));
      expect(getValue(list, 1), equals("b"));
      expect(getValue(list, 6), equals(null));
      expect(getValue(list, -1), equals(null));

      expect(getValue(list, "0"), equals("a"));
      expect(getValue(list, "1"), equals("b"));
    });

    test("is array", () {
      var list = ["a", "b"];
      expect(checkIsArray(list), isTrue);
    });

    test("property descriptors", () {
      // This test matters to make behavior consistent with JS native arrays
      // and to make devtools integration work well.
      var list = ["a", "b"];
      var descriptor = getOwnPropertyDescriptor(list, 0);

      expect(descriptor.value, equals("a"));
      expect(descriptor.writable, isTrue);
      // TODO(jacobr): commented out until https://github.com/dart-lang/sdk/issues/26128
      // is fixed.
      // expect(descriptor.enumerable, isTrue);
      // expect(descriptor.configurable, isTrue);

      descriptor = getOwnPropertyDescriptor(list, "length");
      expect(descriptor.value, equals(2));
      expect(descriptor.writable, isTrue);
      expect(descriptor.enumerable, isFalse);
      expect(descriptor.configurable, isFalse);
    });

    test("concat js arrays", () {
      var list = ["1", "2"];
      // Tests that calling the concat method from JS will flatten out JS arrays
      // We concat the array with "a", "b", ["c", "d"], 42, {foo: 10}
      // which should generate ["1", "2", "a", "b", ["c", "d"], 42, {foo: 10}]
      var ret = concatValues(list);
      expect(list.length, equals(2));
      expect(ret.length, equals(8));
      expect(ret[0], equals("1"));
      expect(ret[3], equals("b"));
      expect(ret[5], equals("d"));
      expect(ret[6], equals(42));
      dynamic item = ret[7];
      expect(item.foo, equals(10));
    });

    test("concat onto arrays", () {
      // This test only passes if we have monkey patched the core Array object
      // prototype to handle Dart Lists.
      var list = ["a", "b"];
      var ret = concatOntoArray(list);
      expect(list.length, equals(2));
      expect(ret, equals([1, 2, 3, "a", "b", "foo"]));
    });

    test("dart arrays on dart arrays", () {
      // This test only passes if we have monkey patched the core Array object
      // prototype to handle Dart Lists.
      var list = ["a", "b"];
      var ret = callJsMethod(list, "concat", [
        ["c", "d"],
        "e",
        ["f", "g"]
      ]);
      expect(list.length, equals(2));
      expect(ret, equals(["a", "b", "c", "d", "e", "f", "g"]));
    });

    test("every greater than zero", () {
      expect(everyGreaterThanZero([1, 5]), isTrue);
      expect(everyGreaterThanZeroCheckThisArg([1, 5]), isTrue);
      expect(everyGreaterThanZero([1, 0]), isFalse);
      expect(everyGreaterThanZero([]), isTrue);
    });

    test("filter greater than 42", () {
      expect(filterGreater42([1, 5]), equals([]));
      expect(filterGreater42([43, 5, 49]), equals([43, 49]));
      expect(filterGreater42(["43", "5", "49"]), equals(["43", "49"]));
    });

    test("for each collect result", () {
      expect(forEachCollectResult([1, 5, 7]), equals([2, 10, 14]));
    });

    test("some", () {
      expect(someEqual42([1, 5, 9]), isFalse);
      expect(someEqual42([1, 42, 9]), isTrue);
    });

    test("sort backwards", () {
      var arr = [1, 5, 9];
      var ret = sortNumbersBackwards(arr);
      expect(identical(arr, ret), isTrue);
      expect(ret, equals([9, 5, 1]));
    });

    test("splice dummy items", () {
      var list = [1, 2, 3, 4];
      var removed = spliceDummyItems(list);
      expect(removed.length, equals(2));
      expect(removed[0], equals(2));
      expect(removed[1], equals(3));
      expect(list.first, equals(1));
      expect(list[1], equals("quick"));
      expect(list[2], equals("brown"));
      expect(list[3], equals("fox"));
      expect(list.last, equals(4));
    });

    test("splice string args", () {
      var list = [1, 2, 3, 4];
      var removed = spliceTestStringArgs(list);
      expect(removed.length, equals(2));
      expect(removed[0], equals(2));
      expect(removed[1], equals(3));
      expect(list.first, equals(1));
      expect(list[1], equals("quick"));
      expect(list[2], equals("brown"));
      expect(list[3], equals("fox"));
      expect(list.last, equals(4));
    });

    test("splice pastEndOfArray", () {
      var list = [1, 2, 3, 4];
      var removed = splicePastEnd(list);
      expect(removed.length, equals(3));
      expect(list.first, equals(1));
      expect(list.length, equals(4));
      expect(list[1], equals("quick"));
      expect(list[2], equals("brown"));
      expect(list[3], equals("fox"));
    });

    test("splice both bounds past end of array", () {
      var list = [1];
      var removed = splicePastEnd(list);
      expect(removed.length, equals(0));
      expect(list.first, equals(1));
      expect(list.length, equals(4));
      expect(list[1], equals("quick"));
      expect(list[2], equals("brown"));
      expect(list[3], equals("fox"));
    });

    test("call List method on JavaScript object", () {
      var jsObject = newLiteral();
      callListMethodOnObject(jsObject, 'push', ["a"]);
      callListMethodOnObject(jsObject, 'push', ["b"]);
      callListMethodOnObject(jsObject, 'push', ["c", "d"]);
      callListMethodOnObject(jsObject, 'push', []);

      expect(json_helper.stringify(jsObject),
          equals('{"0":"a","1":"b","2":"c","3":"d","length":4}'));

      expect(callListMethodOnObject(jsObject, 'pop', []), equals("d"));
      expect(callListMethodOnObject(jsObject, 'join', ["#"]), equals("a#b#c"));

      var jsArray = newArray();
      callListMethodOnObject(jsArray, 'push', ["a"]);
      callListMethodOnObject(jsArray, 'push', ["b"]);
      callListMethodOnObject(jsArray, 'push', ["c", "d"]);
      callListMethodOnObject(jsArray, 'push', []);

      expect(json_helper.stringify(jsArray), equals('["a","b","c","d"]'));
    });
  });

  // This test group is disabled until we figure out an efficient way to
  // distinguish between "array" Dart List types and non-array Dart list types.
  /*
  group('Non-array Lists', () {
    test('opaque proxy', () {
      // Dartium could easily support making LinkedList and all other classes
      // implementing List behave like a JavaScript array but that would
      // be challenging to implement in dart2js until browsers support ES6.
      var list = ["a", "b", "c", "d"];
      var listView = new UnmodifiableListView(list.getRange(1,3));
      expect(listView is List, isTrue);
      expect(listView.length, equals(2));
      expect(checkIsArray(listView), isFalse);
      expect(checkIsArray(listView.toList()), isTrue);
      expect(getOwnPropertyDescriptor(
          listView, "length"), equals(null));
    });
  });
  */
}
