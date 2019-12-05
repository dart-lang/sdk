// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/utils.dart';
import 'package:test/test.dart';

import 'util/test_utils.dart';

void main() {
  group('isDartFileName', () {
    testEach(['foo.dart'], isDartFileName, isTrue);
    testEach([
      'foo.d', 'foo',
      // Analysis server cares about case.
      'baz.DART',
    ], isDartFileName, isFalse);
  });

  group('pubspec', () {
    testEach(['pubspec.yaml', '_pubspec.yaml'], isPubspecFileName, isTrue);
    testEach(['__pubspec.yaml', 'foo.yaml'], isPubspecFileName, isFalse);
  });

  group('camel case', () {
    group('upper', () {
      var good = [
        '_FooBar',
        'FooBar',
        '_Foo',
        'Foo',
        'F',
        'FB',
        'F1',
        'FooBar1',
        '\$Foo',
        'Bar\$',
        'Foo\$Generated',
        'Foo\$Generated\$Bar'
      ];
      testEach(good, isCamelCase, isTrue);
      var bad = ['fooBar', 'foo', 'f', '_f', 'F_B'];
      testEach(bad, isCamelCase, isFalse);
    });

    group('CamelCaseString', () {
      test('invalid creation', () {
        expect(() => CamelCaseString('invalid'),
            throwsA(TypeMatcher<ArgumentError>()));
      });
      test('toString', () {
        expect(CamelCaseString('CamelCase').toString(), 'CamelCase');
      });
      test('humanize', () {
        expect(CamelCaseString('CamelCase').humanized, 'Camel Case');
      });
    });
  });

  group('library prefixes', () {
    const good = [
      'foo_bar',
      'foo',
      'foo_bar_baz',
      'p',
      'p1',
      'p21',
      'p1ll0',
      '_foo',
      // Ensure multiple underscores don't cause issues (#940).
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa__aa',
      'abc_def_ghi_jkl_mnomnomno_abcabcabc__defdefdefdef__ghighighighi',
      'abc_____def____ghi_jkl__mnomnomno_abcabcabc__defdefdefdef___ghighighighi',
      r'$foo',
      '__foo',
      r'$_foo',
      r'$__foo',
    ];
    testEach(good, isValidLibraryPrefix, isTrue);

    const bad = [
      'JSON',
      'JS',
      'Math',
      'jsUtils',
      'foo_Bar',
      'F_B',
      '1',
      '1b',
      r'foo$',
      r'f$oo',
      r'$$foo',
      r'$_$foo',
      r'_$foo',
      '__',
      '_',
      '_1',
    ];
    testEach(bad, isValidLibraryPrefix, isFalse);
  });

  group('lower_case_underscores', () {
    var good = ['foo_bar', 'foo', 'foo_bar_baz', 'p', 'p1', 'p21', 'p1ll0'];
    testEach(good, isLowerCaseUnderScore, isTrue);

    var bad = [
      'Foo',
      'fooBar',
      'foo_Bar',
      'foo_',
      '_f',
      'F_B',
      'JS',
      'JSON',
      '1',
      '1b',
    ];
    testEach(bad, isLowerCaseUnderScore, isFalse);
  });

  group('isLowerCaseUnderScoreWithDots', () {
    var good = [
      'bwu_server.shared.datastore.some_file',
      'foo_bar.baz',
      'foo_bar',
      'foo.bar',
      'foo_bar_baz',
      'foo',
      'foo_',
      'foo.bar_baz.bang',
      //See: https://github.com/flutter/flutter/pull/1996
      'pointycastle.impl.ec_domain_parameters.gostr3410_2001_cryptopro_a',
      'a.b',
      'a.b.c',
      'p2.src.acme',
      //https://github.com/dart-lang/linter/issues/1803
      '_',
      '_f',
      '__f',
      '___f',
      '_file.dart',
    ];
    testEach(good, isLowerCaseUnderScoreWithDots, isTrue);

    var bad = [
      'Foo',
      'fooBar.',
      '.foo_Bar',
      '_.',
      '.',
      'F_B',
      'JS',
      'JSON',
    ];

    testEach(bad, isLowerCaseUnderScoreWithDots, isFalse);
  });

  group('lowerCamelCase', () {
    var good = [
      'fooBar',
      'foo',
      'f',
      'f1',
      '_f',
      '_foo',
      '_',
      'F',
      '__x',
      '___x',
      '\$foo',
      'bar\$',
      'foo\$Generated',
      'foo\$Generated\$Bar'
    ];
    testEach(good, isLowerCamelCase, isTrue);

    var bad = ['Foo', 'foo_', 'foo_bar', '_X'];
    testEach(bad, isLowerCamelCase, isFalse);
  });

  group('isUpperCase', () {
    var caps = List<int>.generate(26, (i) => 'A'.codeUnitAt(0) + i);
    testEach(caps, isUpperCase, isTrue);

    var bad = ['a', '1', 'z'].map((c) => c.codeUnitAt(0));
    testEach(bad, isUpperCase, isFalse);
  });
}
