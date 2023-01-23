// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:heapsnapshot/src/expression.dart';

import 'package:test/test.dart';

class ErrorCollector extends Output {
  final errors = <String>[];
  void printError(String error) {
    errors.add(error);
  }

  void print(String message) {}
}

main([List<String> args = const []]) {
  group('parser', () {
    late ErrorCollector ec;

    setUp(() {
      ec = ErrorCollector();
    });

    void match<T>(SetExpression? expr, void Function(T) fun) {
      expect(expr is T, true);
      fun(expr as T);
    }

    void matchNamed(SetExpression? expr, String name) {
      match<NamedExpression>(expr, (expr) {
        expect(expr.name, name);
      });
    }

    void parseMatch<T>(String input, void Function(T) fun) {
      final expr =
          parseExpression(input, ec, {'all', 'set1', 'set2', 'set3', 'set4'});
      match<T>(expr, fun);
    }

    void parseError(String input, Set<String> namedSets, List<String> errors) {
      final expr = parseExpression(input, ec, namedSets);
      expect(expr, null);
      expect(ec.errors, errors);
    }

    group('expression', () {
      test('filter', () {
        parseMatch<FilterExpression>('filter  all  cls  (cls2:field)', (expr) {
          expect(expr.patterns, ['cls', '(cls2:field)']);
          matchNamed(expr.expr, 'all');
        });
      });

      test('dfilter', () {
        parseMatch<DFilterExpression>('dfilter  all content ==0', (expr) {
          expect(expr.patterns, ['content', '==0']);
          matchNamed(expr.expr, 'all');
        });
      });
      test('minus', () {
        parseMatch<MinusExpression>('minus set1 set2 set3', (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.operands.length, 2);
          matchNamed(expr.operands[0], 'set2');
          matchNamed(expr.operands[1], 'set3');
        });
      });
      test('or', () {
        parseMatch<OrExpression>('or set1 set2 set3', (expr) {
          expect(expr.exprs.length, 3);
          matchNamed(expr.exprs[0], 'set1');
          matchNamed(expr.exprs[1], 'set2');
          matchNamed(expr.exprs[2], 'set3');
        });
      });
      test('or-empty', () {
        parseMatch<OrExpression>('or', (expr) {
          expect(expr.exprs.length, 0);
        });
      });
      test('and', () {
        parseMatch<AndExpression>('and set1 set2 set3', (expr) {
          expect(expr.operands.length, 2);
          matchNamed(expr.expr, 'set1');
          matchNamed(expr.operands[0], 'set2');
          matchNamed(expr.operands[1], 'set3');
        });
      });
      test('sample', () {
        parseMatch<SampleExpression>('sample set1', (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.count, 1);
        });
      });

      test('sample-num', () {
        parseMatch<SampleExpression>('sample set1 10', (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.count, 10);
        });
      });

      test('closure', () {
        parseMatch<ClosureExpression>('closure set1', (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.patterns, []);
        });
      });
      test('closure-filter', () {
        parseMatch<ClosureExpression>('closure set1 cls cls:field', (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.patterns, ['cls', 'cls:field']);
        });
      });

      test('uclosure', () {
        parseMatch<UserClosureExpression>('uclosure set1', (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.patterns, []);
        });
      });
      test('uclosure-filter', () {
        parseMatch<UserClosureExpression>('uclosure set1 cls cls:field',
            (expr) {
          matchNamed(expr.expr, 'set1');
          expect(expr.patterns, ['cls', 'cls:field']);
        });
      });

      test('follow', () {
        parseMatch<FollowExpression>('follow set1 cls cls:field', (expr) {
          matchNamed(expr.objs, 'set1');
          expect(expr.patterns, ['cls', 'cls:field']);
        });
      });
      test('users', () {
        parseMatch<UserFollowExpression>('users set1 cls cls:field', (expr) {
          matchNamed(expr.objs, 'set1');
          expect(expr.patterns, ['cls', 'cls:field']);
        });
      });

      test('set-name', () {
        parseMatch<SetNameExpression>('set1 = closure set1', (expr) {
          match<ClosureExpression>(expr.expr, (expr) {});
          expect(expr.name, 'set1');
        });
      });

      test('parens', () {
        parseMatch<OrExpression>('or (( set1 )) ( set2 ) ( set3) (set4 )',
            (expr) {
          expect(expr.exprs.length, 4);
          matchNamed(expr.exprs[0], 'set1');
          matchNamed(expr.exprs[1], 'set2');
          matchNamed(expr.exprs[2], 'set3');
          matchNamed(expr.exprs[3], 'set4');
        });
      });
    });

    group('expression-errors', () {
      test('empty-and', () {
        parseError('and', {}, [
          'Reached end of input: expected expression',
          'See `help eval` for available expression types and arguments.'
        ]);
      });
      test('empty-minus', () {
        parseError('minus', {}, [
          'Reached end of input: expected expression',
          'See `help eval` for available expression types and arguments.'
        ]);
      });
      test('unknown set', () {
        parseError('closure foobar', {}, [
          'There is no set with name "foobar". See `info`.',
          'See `help eval` for available expression types and arguments.'
        ]);
      });
      test('missing )', () {
        parseError('closure (a', {
          'a'
        }, [
          'Expected closing ")" after "closure (a".',
          'See `help eval` for available expression types and arguments.'
        ]);
      });
      test('garbage', () {
        parseError('sample set1 10 foo', {
          'set1'
        }, [
          'Found unexpected "foo" after SampleExpression.',
          'See `help eval` for available expression types and arguments.'
        ]);
      });
    });
  });
}
