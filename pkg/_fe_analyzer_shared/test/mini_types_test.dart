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

    group('NamedType:', () {
      test('unchanged', () {
        var namedType = NamedType('foo', Type('int'));
        expect(namedType.recursivelyDemote(covariant: true), isNull);
        expect(namedType.recursivelyDemote(covariant: false), isNull);
      });

      group('type parameters:', () {
        test('unchanged', () {
          var type = Type('Map<int, String>');
          var namedType = NamedType('foo', type);
          expect(namedType.recursivelyDemote(covariant: true), isNull);
          expect(namedType.recursivelyDemote(covariant: false), isNull);
        });

        test('covariant', () {
          var type = Type('Map<T&int, String>');
          var namedType = NamedType('foo', type);
          expect(
            namedType.recursivelyDemote(covariant: true)!.type,
            'Map<T, String> foo',
          );
        });

        test('contravariant', () {
          var type = Type('Map<T&int, String>');
          var namedType = NamedType('foo', type);
          expect(
            namedType.recursivelyDemote(covariant: false)!.type,
            'Map<Never, String> foo',
          );
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

    group('RecordType:', () {
      test('unchanged', () {
        var type = RecordType(positional: [
          Type('int'),
        ], named: [
          NamedType('a', Type('double')),
        ]);
        expect(type.recursivelyDemote(covariant: true), isNull);
        expect(type.recursivelyDemote(covariant: false), isNull);
      });

      group('changed:', () {
        group('positional:', () {
          var type = RecordType(positional: [
            Type('T&int'),
          ], named: [
            NamedType('a', Type('double')),
          ]);
          test('covariant', () {
            expect(
              type.recursivelyDemote(covariant: true)!.type,
              '(T, {double a})',
            );
          });
          test('contravariant', () {
            expect(
              type.recursivelyDemote(covariant: false)!.type,
              '(Never, {double a})',
            );
          });
        });
        group('named:', () {
          var type = RecordType(positional: [
            Type('double'),
          ], named: [
            NamedType('a', Type('T&int')),
          ]);
          test('covariant', () {
            expect(
              type.recursivelyDemote(covariant: true)!.type,
              '(double, {T a})',
            );
          });
          test('contravariant', () {
            expect(
              type.recursivelyDemote(covariant: false)!.type,
              '(double, {Never a})',
            );
          });
        });
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
