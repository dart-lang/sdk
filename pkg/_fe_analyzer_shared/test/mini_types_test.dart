// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'mini_types.dart';

main() {
  group('recursivelyDemote:', () {
    group('FunctionType:', () {
      group('return type:', () {
        test('unchanged', () {
          expect(Type('int Function()').recursivelyDemote(covariant: true),
              isNull);
          expect(Type('int Function()').recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('T&int Function()').recursivelyDemote(covariant: true)!.type,
              'T Function()');
        });

        test('contravariant', () {
          expect(
              Type('T&int Function()')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'Never Function()');
        });
      });

      group('positional parameters:', () {
        test('unchanged', () {
          expect(
              Type('void Function(int, String)')
                  .recursivelyDemote(covariant: true),
              isNull);
          expect(
              Type('void Function(int, String)')
                  .recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('void Function(T&int, String)')
                  .recursivelyDemote(covariant: true)!
                  .type,
              'void Function(Never, String)');
        });

        test('contravariant', () {
          expect(
              Type('void Function(T&int, String)')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'void Function(T, String)');
        });
      });
    });

    group('NonFunctionType', () {
      test('unchanged', () {
        expect(Type('int').recursivelyDemote(covariant: true), isNull);
        expect(Type('int').recursivelyDemote(covariant: false), isNull);
      });

      group('type parameters:', () {
        test('unchanged', () {
          expect(Type('Map<int, String>').recursivelyDemote(covariant: true),
              isNull);
          expect(Type('Map<int, String>').recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('Map<T&int, String>')
                  .recursivelyDemote(covariant: true)!
                  .type,
              'Map<T, String>');
        });

        test('contravariant', () {
          expect(
              Type('Map<T&int, String>')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'Map<Never, String>');
        });
      });
    });

    group('QuestionType:', () {
      test('unchanged', () {
        expect(Type('int?').recursivelyDemote(covariant: true), isNull);
        expect(Type('int?').recursivelyDemote(covariant: false), isNull);
      });

      test('covariant', () {
        expect(Type('(T&int)?').recursivelyDemote(covariant: true)!.type, 'T?');
      });

      test('contravariant', () {
        // Note: we don't normalize `Never?` to `Null`.
        expect(Type('(T&int)?').recursivelyDemote(covariant: false)!.type,
            'Never?');
      });
    });

    group('StarType:', () {
      test('unchanged', () {
        expect(Type('int*').recursivelyDemote(covariant: true), isNull);
        expect(Type('int*').recursivelyDemote(covariant: false), isNull);
      });

      test('covariant', () {
        expect(Type('(T&int)*').recursivelyDemote(covariant: true)!.type, 'T*');
      });

      test('contravariant', () {
        expect(Type('(T&int)*').recursivelyDemote(covariant: false)!.type,
            'Never*');
      });
    });

    test('UnknownType:', () {
      expect(Type('?').recursivelyDemote(covariant: true), isNull);
      expect(Type('?').recursivelyDemote(covariant: false), isNull);
    });
  });
}
