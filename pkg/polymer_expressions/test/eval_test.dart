// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library eval_test;

import 'dart:async';

// Import mirrors to cause all mirrors to be retained by dart2js.
// The tests reflect on LinkedHashMap.length and String.length.
import 'dart:mirrors';

import 'package:polymer_expressions/eval.dart';
import 'package:polymer_expressions/filter.dart';
import 'package:polymer_expressions/parser.dart';
import 'package:unittest/unittest.dart';
import 'package:observe/observe.dart';
import 'package:observe/mirrors_used.dart'; // make test smaller.

main() {
  reflectClass(Object); // suppress unused import warning

  group('eval', () {
    test('should return the model for an empty expression', () {
      expectEval('', 'model', 'model');
    });

    test('should handle the "this" keyword', () {
      expectEval('this', 'model', 'model');
      expectEval('this.name', 'foo', new Foo(name: 'foo'));
      expectEval('this["a"]', 'x', {'a': 'x'});
    });

    test('should return a literal int', () {
      expectEval('1', 1);
      expectEval('+1', 1);
      expectEval('-1', -1);
    });

    test('should return a literal double', () {
      expectEval('1.2', 1.2);
      expectEval('+1.2', 1.2);
      expectEval('-1.2', -1.2);
    });

    test('should return a literal string', () {
      expectEval('"hello"', "hello");
      expectEval("'hello'", "hello");
    });

    test('should return a literal boolean', () {
      expectEval('true', true);
      expectEval('false', false);
    });

    test('should return a literal null', () {
      expectEval('null', null);
    });

    test('should return a literal list', () {
      expectEval('[1, 2, 3]', equals([1, 2, 3]));
    });

    test('should return a literal map', () {
      expectEval('{"a": 1}', equals(new Map.from({'a': 1})));
      expectEval('{"a": 1}', containsPair('a', 1));
    });

    test('should call methods on a literal map', () {
      expectEval('{"a": 1}.length', 1);
    });

    test('should evaluate unary operators', () {
      expectEval('+a', 2, null, {'a': 2});
      expectEval('-a', -2, null, {'a': 2});
      expectEval('!a', false, null, {'a': true});
    });

    test('should evaluate binary operators', () {
      expectEval('1 + 2', 3);
      expectEval('2 - 1', 1);
      expectEval('4 / 2', 2);
      expectEval('2 * 3', 6);
      expectEval('5 % 2', 1);
      expectEval('5 % -2', 1);
      expectEval('-5 % 2', 1);

      expectEval('1 == 1', true);
      expectEval('1 == 2', false);
      expectEval('1 == null', false);
      expectEval('1 != 1', false);
      expectEval('1 != 2', true);
      expectEval('1 != null', true);

      expectEval('1 > 1', false);
      expectEval('1 > 2', false);
      expectEval('2 > 1', true);
      expectEval('1 >= 1', true);
      expectEval('1 >= 2', false);
      expectEval('2 >= 1', true);
      expectEval('1 < 1', false);
      expectEval('1 < 2', true);
      expectEval('2 < 1', false);
      expectEval('1 <= 1', true);
      expectEval('1 <= 2', true);
      expectEval('2 <= 1', false);

      expectEval('true || true', true);
      expectEval('true || false', true);
      expectEval('false || true', true);
      expectEval('false || false', false);

      expectEval('true && true', true);
      expectEval('true && false', false);
      expectEval('false && true', false);
      expectEval('false && false', false);
    });

    test('should evaulate ternary operators', () {
      expectEval('true ? 1 : 2', 1);
      expectEval('false ? 1 : 2', 2);
      expectEval('true ? true ? 1 : 2 : 3', 1);
      expectEval('true ? false ? 1 : 2 : 3', 2);
      expectEval('false ? true ? 1 : 2 : 3', 3);
      expectEval('false ? 1 : true ? 2 : 3', 2);
      expectEval('false ? 1 : false ? 2 : 3', 3);
      expectEval('null ? 1 : 2', 2);
      // TODO(justinfagnani): re-enable and check for an EvalError when
      // we implement the final bool conversion rules and this expression
      // throws in both checked and unchecked mode
//      expect(() => eval(parse('42 ? 1 : 2'), null), throws);
    });

    test('should invoke a method on the model', () {
      var foo = new Foo(name: 'foo', age: 2);
      expectEval('x()', foo.x(), foo);
      expectEval('name', foo.name, foo);
    });

    test('should invoke chained methods', () {
      var foo = new Foo(name: 'foo', age: 2);
      expectEval('name.length', foo.name.length, foo);
      expectEval('x().toString()', foo.x().toString(), foo);
      expectEval('name.substring(2)', foo.name.substring(2), foo);
      expectEval('a()()', 1, null, {'a': () => () => 1});
    });

    test('should invoke a top-level function', () {
      expectEval('x()', 42, null, {'x': () => 42});
      expectEval('x(5)', 5, null, {'x': (i) => i});
      expectEval('y(5, 10)', 50, null, {'y': (i, j) => i * j});
    });

    test('should give precedence to top-level functions over methods', () {
      var foo = new Foo(name: 'foo', age: 2);
      expectEval('x()', 42, foo, {'x': () => 42});
    });

    test('should invoke the [] operator', () {
      var map = {'a': 1, 'b': 2};
      expectEval('map["a"]', 1, null, {'map': map});
      expectEval('map["a"] + map["b"]', 3, null, {'map': map});
    });

    test('should call a filter', () {
      var topLevel = {
        'a': 'foo',
        'uppercase': (s) => s.toUpperCase(),
      };
      expectEval('a | uppercase', 'FOO', null, topLevel);
    });

    test('should call a transformer', () {
      var topLevel = {
        'a': '42',
        'parseInt': parseInt,
        'add': add,
      };
      expectEval('a | parseInt()', 42, null, topLevel);
      expectEval('a | parseInt(8)', 34, null, topLevel);
      expectEval('a | parseInt() | add(10)', 52, null, topLevel);
    });

    test('should filter a list', () {
      expectEval('chars1 | filteredList', ['a', 'b'], new WordElement());
    });

    test('should return null if the receiver of a method is null', () {
      expectEval('a.b', null, null, {'a': null});
      expectEval('a.b()', null, null, {'a': null});
    });

    test('should return null if null is invoked', () {
      expectEval('a()', null, null, {'a': null});
    });

    test('should return null if an operand is null', () {
      expectEval('a + b', null, null, {'a': null, 'b': null});
      expectEval('+a', null, null, {'a': null});
    });

    test('should treat null as false', () {
      expectEval('!null', true);
      expectEval('true && null', false);
      expectEval('null || false', false);

      expectEval('!a', true, null, {'a': null});

      expectEval('a && b', false, null, {'a': null, 'b': true});
      expectEval('a && b', false, null, {'a': true, 'b': null});
      expectEval('a && b', false, null, {'a': null, 'b': false});
      expectEval('a && b', false, null, {'a': false, 'b': null});
      expectEval('a && b', false, null, {'a': null, 'b': null});

      expectEval('a || b', true, null, {'a': null, 'b': true});
      expectEval('a || b', true, null, {'a': true, 'b': null});
      expectEval('a || b', false, null, {'a': null, 'b': false});
      expectEval('a || b', false, null, {'a': false, 'b': null});
      expectEval('a || b', false, null, {'a': null, 'b': null});
    });

    test('should not evaluate "in" expressions', () {
      expect(() => eval(parse('item in items'), null), throws);
    });

  });

  group('assign', () {

    test('should assign a single identifier', () {
      var foo = new Foo(name: 'a');
      assign(parse('name'), 'b', new Scope(model: foo));
      expect(foo.name, 'b');
    });

    test('should assign a sub-property', () {
      var child = new Foo(name: 'child');
      var parent = new Foo(child: child);
      assign(parse('child.name'), 'Joe', new Scope(model: parent));
      expect(parent.child.name, 'Joe');
    });

    test('should assign an index', () {
      var foo = new Foo(items: [1, 2, 3]);
      assign(parse('items[0]'), 4, new Scope(model: foo));
      expect(foo.items[0], 4);
      assign(parse('items[a]'), 5, new Scope(model: foo, variables: {'a': 0}));
      expect(foo.items[0], 5);
    });

    test('should assign with a function call subexpression', () {
      var child = new Foo();
      var foo = new Foo(items: [1, 2, 3], child: child);
      assign(parse('getChild().name'), 'child', new Scope(model: foo));
      expect(child.name, 'child');
    });

    test('should assign through transformers', () {
      var foo = new Foo(name: '42', age: 32);
      var globals = {
        'a': '42',
        'parseInt': parseInt,
        'add': add,
      };
      var scope = new Scope(model: foo, variables: globals);
      assign(parse('age | add(7)'), 29, scope);
      expect(foo.age, 22);
      assign(parse('name | parseInt() | add(10)'), 29, scope);
      expect(foo.name, '19');
    });

    test('should not throw on assignments to properties on null', () {
      assign(parse('name'), 'b', new Scope(model: null));
    });

    test('should throw on assignments to non-assignable expressions', () {
      var foo = new Foo(name: 'a');
      var scope = new Scope(model: foo);
      expect(() => assign(parse('name + 1'), 1, scope),
          throwsA(new isInstanceOf<EvalException>()));
      expect(() => assign(parse('toString()'), 1, scope),
          throwsA(new isInstanceOf<EvalException>()));
      expect(() => assign(parse('name | filter'), 1, scope),
          throwsA(new isInstanceOf<EvalException>()));
    });

    test('should not throw on assignments to non-assignable expressions if '
        'checkAssignability is false', () {
      var foo = new Foo(name: 'a');
      var scope = new Scope(model: foo);
      expect(
          assign(parse('name + 1'), 1, scope, checkAssignability: false),
          null);
      expect(
          assign(parse('toString()'), 1, scope, checkAssignability: false),
          null);
      expect(
          assign(parse('name | filter'), 1, scope, checkAssignability: false),
          null);
    });

  });

  group('scope', () {
    test('should return fields on the model', () {
      var foo = new Foo(name: 'a', age: 1);
      var scope = new Scope(model: foo);
      expect(scope['name'], 'a');
      expect(scope['age'], 1);
    });

    test('should throw for undefined names', () {
      var scope = new Scope();
      expect(() => scope['a'], throwsException);
    });

    test('should return variables', () {
      var scope = new Scope(variables: {'a': 'A'});
      expect(scope['a'], 'A');
    });

    test("should a field from the parent's model", () {
      var parent = new Scope(variables: {'a': 'A', 'b': 'B'});
      var child = parent.childScope('a', 'a');
      expect(child['a'], 'a');
      expect(parent['a'], 'A');
      expect(child['b'], 'B');
    });

  });

  group('observe', () {
    test('should observe an identifier', () {
      var foo = new Foo(name: 'foo');
      return expectObserve('name',
          model: foo,
          beforeMatcher: 'foo',
          mutate: () {
            foo.name = 'fooz';
          },
          afterMatcher: 'fooz'
      );
    });

    test('should observe an invocation', () {
      var foo = new Foo(name: 'foo');
      return expectObserve('foo.name',
          variables: {'foo': foo},
          beforeMatcher: 'foo',
          mutate: () {
            foo.name = 'fooz';
          },
          afterMatcher: 'fooz'
      );
    });

    test('should observe map access', () {
      var foo = toObservable({'one': 'one', 'two': 'two'});
      return expectObserve('foo["one"]',
          variables: {'foo': foo},
          beforeMatcher: 'one',
          mutate: () {
            foo['one'] = '1';
          },
          afterMatcher: '1'
      );
    });

  });

}

@reflectable
class Foo extends ChangeNotifier {
  String _name;
  String get name => _name;
  void set name(String n) {
    _name = notifyPropertyChange(#name, _name, n);
  }

  int age;
  Foo child;
  List<int> items;

  Foo({name, this.age, this.child, this.items}) : _name = name;

  int x() => age * age;

  getChild() => child;

  filter(i) => i;
}

@reflectable
class ListHolder {
  List items;
  ListHolder(this.items);
}

parseInt([int radix = 10]) => new IntToString(radix: radix);

class IntToString extends Transformer<int, String> {
  final int radix;
  IntToString({this.radix: 10});
  int forward(String s) => int.parse(s, radix: radix);
  String reverse(int i) => '$i';
}

add(int i) => new Add(i);

class Add extends Transformer<int, int> {
  final int i;
  Add(this.i);
  int forward(int x) => x + i;
  int reverse(int x) => x - i;
}

Object evalString(String s, [Object model, Map vars]) =>
    eval(new Parser(s).parse(), new Scope(model: model, variables: vars));

expectEval(String s, dynamic matcher, [Object model, Map vars = const {}]) {
  var expr = new Parser(s).parse();
  var scope = new Scope(model: model, variables: vars);
  expect(eval(expr, scope), matcher, reason: s);

  var observer = observe(expr, scope);
  new Updater(scope).visit(observer);
  expect(observer.currentValue, matcher, reason: s);
}

expectObserve(String s, {
    Object model,
    Map variables: const {},
    dynamic beforeMatcher,
    mutate(),
    dynamic afterMatcher}) {

  var scope = new Scope(model: model, variables: variables);
  var observer = observe(new Parser(s).parse(), scope);
  update(observer, scope);
  expect(observer.currentValue, beforeMatcher);
  var passed = false;
  var future = observer.onUpdate.first.then((value) {
    expect(value, afterMatcher);
    expect(observer.currentValue, afterMatcher);
    passed = true;
  });
  mutate();
  // fail if we don't receive an update by the next event loop
  return Future.wait([future, new Future(() {
    expect(passed, true, reason: "Didn't receive a change notification on $s");
  })]);
}

// Regression test from https://code.google.com/p/dart/issues/detail?id=13459
class WordElement extends Observable {
  @observable List chars1 = 'abcdefg'.split('');
  @reflectable List filteredList(List original) => [original[0], original[1]];
}
