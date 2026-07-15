// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dartpad_worker/src/util/jsonify.dart';
import 'package:test/test.dart';

void main() {
  test('jsonify() handles primitives', () {
    expect(jsonify('hello'), equals('hello'));
    expect(jsonify(42), equals(42));
    expect(jsonify(3.14), equals(3.14));
    expect(jsonify(true), isTrue);
    expect(jsonify(null), isNull);
  });

  test('jsonify() handles lists', () {
    expect(jsonify([1, 2, 3]), equals([1, 2, 3]));
    expect(jsonify(['a', 1, null]), equals(['a', 1, null]));
  });

  test('jsonify() handles maps and ensures string keys', () {
    expect(jsonify({'a': 1, 'b': 2}), equals({'a': 1, 'b': 2}));
    expect(jsonify({1: 'a', true: 'b'}), equals({'1': 'a', 'true': 'b'}));
  });

  test('jsonify() handles nested collections', () {
    final input = {
      'list': [
        {'a': 1},
        [2, 3],
      ],
      'map': {'inner': 'value'},
    };
    expect(jsonify(input), equals(input));
  });

  test('jsonify() calls toJson() recursively', () {
    final obj = _HasToJson({'nested': _HasToJson('deep')});

    final result = jsonify(obj);
    expect(
      result,
      equals({
        'data': {
          'nested': {'data': 'deep'},
        },
      }),
    );
  });

  test('jsonify() handles mixed objects and collections', () {
    final input = [
      _HasToJson('a'),
      {
        'b': [_HasToJson('c')],
      },
    ];

    expect(
      jsonify(input),
      equals([
        {'data': 'a'},
        {
          'b': [
            {'data': 'c'},
          ],
        },
      ]),
    );
  });

  test('jsonify() avoids allocation for pure JSON', () {
    final list = ['a', 1, true, null];
    final map = {'key': 'value', 'nested': list};

    // We must ensure the Map is already Map<String, Object?>
    final Map<String, Object?> typedMap = map;

    expect(identical(jsonify(list), list), isTrue);
    expect(identical(jsonify(typedMap), typedMap), isTrue);
  });

  test('jsonify() allocates only when needed', () {
    final list = [1, _HasToJson('a'), 2];
    final result = jsonify(list) as List;

    expect(identical(result, list), isFalse);
    expect(result[0], equals(1));
    expect(result[1], equals({'data': 'a'}));
    expect(result[2], equals(2));
  });

  test('jsonify() falls back to toString() for unknown objects', () {
    final obj = _NoToJson('secret');
    expect(jsonify(obj), equals('secret'));
  });
}

class _HasToJson {
  final Object? data;
  _HasToJson(this.data);
  Map<String, Object?> toJson() => {'data': data};
}

class _NoToJson {
  final String value;
  _NoToJson(this.value);
  @override
  String toString() => value;
}
