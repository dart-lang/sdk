// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.test.util.yaml_test;

import 'package:analyzer/src/util/yaml.dart';
import 'package:test/test.dart';

main() {
  group('yaml', () {
    group('merge', () {
      test('map', () {
        expect(
            merge({
              'one': true,
              'two': false,
              'three': {
                'nested': {'four': true, 'six': true}
              }
            }, {
              'three': {
                'nested': {'four': false, 'five': true},
                'five': true
              },
              'seven': true
            }),
            equals({
              'one': true,
              'two': false,
              'three': {
                'nested': {'four': false, 'five': true, 'six': true},
                'five': true
              },
              'seven': true
            }));
      });

      test('list', () {
        expect(merge([1, 2, 3], [2, 3, 4, 5]), equals([1, 2, 3, 4, 5]));
      });

      test('list w/ promotion', () {
        expect(merge(['one', 'two', 'three'], {'three': false, 'four': true}),
            equals({'one': true, 'two': true, 'three': false, 'four': true}));
        expect(merge({'one': false, 'two': false}, ['one', 'three']),
            equals({'one': true, 'two': false, 'three': true}));
      });

      test('map w/ list promotion', () {
        var map1 = {
          'one': ['a', 'b', 'c']
        };
        var map2 = {
          'one': {'a': true, 'b': false}
        };
        var map3 = {
          'one': {'a': true, 'b': false, 'c': true}
        };
        expect(merge(map1, map2), map3);
      });

      test('map w/ no promotion', () {
        var map1 = {
          'one': ['a', 'b', 'c']
        };
        var map2 = {
          'one': {'a': 'foo', 'b': 'bar'}
        };
        var map3 = {
          'one': {'a': 'foo', 'b': 'bar'}
        };
        expect(merge(map1, map2), map3);
      });

      test('map w/ no promotion (2)', () {
        var map1 = {
          'one': {'a': 'foo', 'b': 'bar'}
        };
        var map2 = {
          'one': ['a', 'b', 'c']
        };
        var map3 = {
          'one': ['a', 'b', 'c']
        };
        expect(merge(map1, map2), map3);
      });

      test('object', () {
        expect(merge(1, 2), 2);
        expect(merge(1, 'foo'), 'foo');
        expect(merge({'foo': 1}, 'foo'), 'foo');
      });
    });
  });
}

final Merger merger = new Merger();

Object merge(Object o1, Object o2) => merger.merge(o1, o2);
