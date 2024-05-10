// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:test/test.dart';

import 'mini_types.dart';

main() {
  group('toString:', () {
    group('FunctionType:', () {
      test('basic', () {
        expect(
            FunctionType(PrimaryType('T'), [PrimaryType('U'), PrimaryType('V')])
                .toString(),
            'T Function(U, V)');
      });

      test('needs parentheses', () {
        expect(
            PromotedTypeVariableType(
                    PrimaryType('T'), FunctionType(VoidType.instance, []))
                .toString(),
            'T&(void Function())');
      });
    });

    group('PrimaryType:', () {
      test('simple', () {
        expect(PrimaryType('T').toString(), 'T');
      });

      test('with arguments', () {
        expect(
            PrimaryType('Map', args: [PrimaryType('T'), PrimaryType('U')])
                .toString(),
            'Map<T, U>');
      });
    });

    group('PromotedTypeVariableType:', () {
      test('basic', () {
        expect(
            PromotedTypeVariableType(PrimaryType('T'), PrimaryType('U'))
                .toString(),
            'T&U');
      });

      test('needs parentheses (left)', () {
        expect(
            PromotedTypeVariableType(
                    PromotedTypeVariableType(
                        PrimaryType('T'), PrimaryType('U')),
                    PrimaryType('V'))
                .toString(),
            '(T&U)&V');
      });

      test('needs parentheses (right)', () {
        expect(
            PromotedTypeVariableType(
                    PrimaryType('T'),
                    PromotedTypeVariableType(
                        PrimaryType('U'), PrimaryType('V')))
                .toString(),
            'T&(U&V)');
      });

      test('needs parentheses (question)', () {
        expect(
            PromotedTypeVariableType(PrimaryType('T'), PrimaryType('U'),
                    nullabilitySuffix: NullabilitySuffix.question)
                .toString(),
            '(T&U)?');
      });

      test('needs parentheses (star)', () {
        expect(
            PromotedTypeVariableType(PrimaryType('T'), PrimaryType('U'),
                    nullabilitySuffix: NullabilitySuffix.star)
                .toString(),
            '(T&U)*');
      });
    });

    group('QuestionType:', () {
      test('basic', () {
        expect(
            PrimaryType('T', nullabilitySuffix: NullabilitySuffix.question)
                .toString(),
            'T?');
      });

      test('needs parentheses', () {
        expect(
            PromotedTypeVariableType(
                    PrimaryType('T'),
                    PrimaryType('U',
                        nullabilitySuffix: NullabilitySuffix.question))
                .toString(),
            'T&(U?)');
      });
    });

    group('RecordType:', () {
      test('no arguments', () {
        expect(
            RecordType(positionalTypes: [], namedTypes: []).toString(), '()');
      });

      test('single positional argument', () {
        expect(
            RecordType(positionalTypes: [PrimaryType('T')], namedTypes: [])
                .toString(),
            '(T,)');
      });

      test('multiple positional arguments', () {
        expect(
            RecordType(
                positionalTypes: [PrimaryType('T'), PrimaryType('U')],
                namedTypes: []).toString(),
            '(T, U)');
      });

      test('single named argument', () {
        expect(
            RecordType(
                    positionalTypes: [],
                    namedTypes: [NamedType(name: 't', type: PrimaryType('T'))])
                .toString(),
            '({T t})');
      });

      test('multiple named arguments', () {
        expect(
            RecordType(positionalTypes: [], namedTypes: [
              NamedType(name: 't', type: PrimaryType('T')),
              NamedType(name: 'u', type: PrimaryType('U'))
            ]).toString(),
            '({T t, U u})');
      });

      test('both positional and named arguments', () {
        expect(
            RecordType(
                    positionalTypes: [PrimaryType('T')],
                    namedTypes: [NamedType(name: 'u', type: PrimaryType('U'))])
                .toString(),
            '(T, {U u})');
      });
    });

    group('StarType:', () {
      test('basic', () {
        expect(
            PrimaryType('T', nullabilitySuffix: NullabilitySuffix.star)
                .toString(),
            'T*');
      });

      test('needs parentheses', () {
        expect(
            PromotedTypeVariableType(PrimaryType('T'),
                    PrimaryType('U', nullabilitySuffix: NullabilitySuffix.star))
                .toString(),
            'T&(U*)');
      });
    });

    test('UnknownType', () {
      expect(UnknownType().toString(), '_');
    });
  });

  group('parse', () {
    var throwsParseError = throwsA(TypeMatcher<ParseError>());

    group('primary type:', () {
      test('no type args', () {
        var t = Type('int') as PrimaryType;
        expect(t.name, 'int');
        expect(t.args, isEmpty);
      });

      test('type arg', () {
        var t = Type('List<int>') as PrimaryType;
        expect(t.name, 'List');
        expect(t.args, hasLength(1));
        expect(t.args[0].type, 'int');
      });

      test('type args', () {
        var t = Type('Map<int, String>') as PrimaryType;
        expect(t.name, 'Map');
        expect(t.args, hasLength(2));
        expect(t.args[0].type, 'int');
        expect(t.args[1].type, 'String');
      });

      test('invalid type arg separator', () {
        expect(() => Type('Map<int) String>'), throwsParseError);
      });

      test('dynamic', () {
        expect(Type('dynamic'), same(DynamicType.instance));
      });

      test('error', () {
        expect(Type('error'), same(InvalidType.instance));
      });

      test('FutureOr', () {
        var t = Type('FutureOr<int>') as FutureOrType;
        expect(t.typeArgument.type, 'int');
      });

      test('Never', () {
        expect(Type('Never'), same(NeverType.instance));
      });

      test('Null', () {
        expect(Type('Null'), same(NullType.instance));
      });

      test('void', () {
        expect(Type('void'), same(VoidType.instance));
      });
    });

    test('invalid initial token', () {
      expect(() => Type('<'), throwsParseError);
    });

    test('unknown type', () {
      var t = Type('_');
      expect(t, TypeMatcher<UnknownType>());
    });

    test('question type', () {
      var t = Type('int?');
      expect(t.nullabilitySuffix, NullabilitySuffix.question);
      expect(t.withNullability(NullabilitySuffix.none).type, 'int');
    });

    test('star type', () {
      var t = Type('int*');
      expect(t.nullabilitySuffix, NullabilitySuffix.star);
      expect(t.withNullability(NullabilitySuffix.none).type, 'int');
    });

    test('promoted type variable', () {
      var t = Type('T&int') as PromotedTypeVariableType;
      expect(t.innerType.type, 'T');
      expect(t.promotion.type, 'int');
    });

    test('parenthesized type', () {
      var t = Type('(int)');
      expect(t.type, 'int');
    });

    test('invalid token terminating parenthesized type', () {
      expect(() => Type('(?<'), throwsParseError);
    });

    group('function type:', () {
      test('no parameters', () {
        var t = Type('int Function()') as FunctionType;
        expect(t.returnType.type, 'int');
        expect(t.positionalParameters, isEmpty);
      });

      test('positional parameter', () {
        var t = Type('int Function(String)') as FunctionType;
        expect(t.returnType.type, 'int');
        expect(t.positionalParameters, hasLength(1));
        expect(t.positionalParameters[0].type, 'String');
      });

      test('positional parameters', () {
        var t = Type('int Function(String, double)') as FunctionType;
        expect(t.returnType.type, 'int');
        expect(t.positionalParameters, hasLength(2));
        expect(t.positionalParameters[0].type, 'String');
        expect(t.positionalParameters[1].type, 'double');
      });

      test('invalid parameter separator', () {
        expect(() => Type('int Function(String Function()< double)'),
            throwsParseError);
      });

      test('invalid token after Function', () {
        expect(() => Type('int Function&)'), throwsParseError);
      });
    });

    group('record type:', () {
      test('no fields', () {
        var t = Type('()') as RecordType;
        expect(t.positionalTypes, isEmpty);
        expect(t.namedTypes, isEmpty);
      });

      test('named field', () {
        var t = Type('({int x})') as RecordType;
        expect(t.positionalTypes, isEmpty);
        expect(t.namedTypes, hasLength(1));
        expect(t.namedTypes[0].name, 'x');
        expect(t.namedTypes[0].type.type, 'int');
      });

      test('named field followed by comma', () {
        var t = Type('({int x,})') as RecordType;
        expect(t.positionalTypes, isEmpty);
        expect(t.namedTypes, hasLength(1));
        expect(t.namedTypes[0].name, 'x');
        expect(t.namedTypes[0].type.type, 'int');
      });

      test('named field followed by invalid token', () {
        expect(() => Type('({int x))'), throwsParseError);
      });

      test('named field name is not an identifier', () {
        expect(() => Type('({int )})'), throwsParseError);
      });

      test('named fields', () {
        var t = Type('({int x, String y})') as RecordType;
        expect(t.positionalTypes, isEmpty);
        expect(t.namedTypes, hasLength(2));
        expect(t.namedTypes[0].name, 'x');
        expect(t.namedTypes[0].type.type, 'int');
        expect(t.namedTypes[1].name, 'y');
        expect(t.namedTypes[1].type.type, 'String');
      });

      test('curly braces followed by invalid token', () {
        expect(() => Type('({int x}&'), throwsParseError);
      });

      test('curly braces but no named fields', () {
        expect(() => Type('({})'), throwsParseError);
      });

      test('positional field', () {
        var t = Type('(int,)') as RecordType;
        expect(t.namedTypes, isEmpty);
        expect(t.positionalTypes, hasLength(1));
        expect(t.positionalTypes[0].type, 'int');
      });

      group('positional fields:', () {
        test('two', () {
          var t = Type('(int, String)') as RecordType;
          expect(t.namedTypes, isEmpty);
          expect(t.positionalTypes, hasLength(2));
          expect(t.positionalTypes[0].type, 'int');
          expect(t.positionalTypes[1].type, 'String');
        });

        test('three', () {
          var t = Type('(int, String, double)') as RecordType;
          expect(t.namedTypes, isEmpty);
          expect(t.positionalTypes, hasLength(3));
          expect(t.positionalTypes[0].type, 'int');
          expect(t.positionalTypes[1].type, 'String');
          expect(t.positionalTypes[2].type, 'double');
        });
      });

      test('named and positional fields', () {
        var t = Type('(int, {String x})') as RecordType;
        expect(t.positionalTypes, hasLength(1));
        expect(t.positionalTypes[0].type, 'int');
        expect(t.namedTypes, hasLength(1));
        expect(t.namedTypes[0].name, 'x');
        expect(t.namedTypes[0].type.type, 'String');
      });

      test('terminated by invalid token', () {
        expect(() => Type('(int, String('), throwsParseError);
      });
    });

    group('invalid token:', () {
      test('before other tokens', () {
        expect(() => Type('#int'), throwsParseError);
      });

      test('at end', () {
        expect(() => Type('int#'), throwsParseError);
      });
    });

    test('extra token after type', () {
      expect(() => Type('int)'), throwsParseError);
    });
  });

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

    group('RecordType:', () {
      test('unchanged', () {
        expect(Type('(int, {double a})').recursivelyDemote(covariant: true),
            isNull);
        expect(Type('(int, {double a})').recursivelyDemote(covariant: false),
            isNull);
      });

      group('changed:', () {
        group('positional:', () {
          test('covariant', () {
            expect(
              Type('(T&int, {double a})')
                  .recursivelyDemote(covariant: true)!
                  .type,
              '(T, {double a})',
            );
          });
          test('contravariant', () {
            expect(
              Type('(T&int, {double a})')
                  .recursivelyDemote(covariant: false)!
                  .type,
              '(Never, {double a})',
            );
          });
        });
        group('named:', () {
          test('covariant', () {
            expect(
              Type('(double, {T&int a})')
                  .recursivelyDemote(covariant: true)!
                  .type,
              '(double, {T a})',
            );
          });
          test('contravariant', () {
            expect(
              Type('(double, {T&int a})')
                  .recursivelyDemote(covariant: false)!
                  .type,
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
      expect(Type('_').recursivelyDemote(covariant: true), isNull);
      expect(Type('_').recursivelyDemote(covariant: false), isNull);
    });
  });

  group('closureWithRespectToUnknown:', () {
    test('UnknownType:', () {
      expect(Type('_').closureWithRespectToUnknown(covariant: true)!.type,
          'Object?');
      expect(Type('_').closureWithRespectToUnknown(covariant: false)!.type,
          'Never');
    });

    group('FunctionType:', () {
      group('return type:', () {
        test('unchanged', () {
          expect(
              Type('int Function()')
                  .closureWithRespectToUnknown(covariant: true),
              isNull);
          expect(
              Type('int Function()')
                  .closureWithRespectToUnknown(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('_ Function()')
                  .closureWithRespectToUnknown(covariant: true)!
                  .type,
              'Object? Function()');
        });

        test('contravariant', () {
          expect(
              Type('_ Function()')
                  .closureWithRespectToUnknown(covariant: false)!
                  .type,
              'Never Function()');
        });
      });

      group('positional parameters:', () {
        test('unchanged', () {
          expect(
              Type('void Function(int, String)')
                  .closureWithRespectToUnknown(covariant: true),
              isNull);
          expect(
              Type('void Function(int, String)')
                  .closureWithRespectToUnknown(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('void Function(_, String)')
                  .closureWithRespectToUnknown(covariant: true)!
                  .type,
              'void Function(Never, String)');
        });

        test('contravariant', () {
          expect(
              Type('void Function(_, String)')
                  .closureWithRespectToUnknown(covariant: false)!
                  .type,
              'void Function(Object?, String)');
        });
      });
    });

    group('NonFunctionType', () {
      test('unchanged', () {
        expect(
            Type('int').closureWithRespectToUnknown(covariant: true), isNull);
        expect(
            Type('int').closureWithRespectToUnknown(covariant: false), isNull);
      });

      group('type parameters:', () {
        test('unchanged', () {
          expect(
              Type('Map<int, String>')
                  .closureWithRespectToUnknown(covariant: true),
              isNull);
          expect(
              Type('Map<int, String>')
                  .closureWithRespectToUnknown(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('Map<_, String>')
                  .closureWithRespectToUnknown(covariant: true)!
                  .type,
              'Map<Object?, String>');
        });

        test('contravariant', () {
          expect(
              Type('Map<_, String>')
                  .closureWithRespectToUnknown(covariant: false)!
                  .type,
              'Map<Never, String>');
        });
      });
    });

    group('QuestionType:', () {
      test('unchanged', () {
        expect(
            Type('int?').closureWithRespectToUnknown(covariant: true), isNull);
        expect(
            Type('int?').closureWithRespectToUnknown(covariant: false), isNull);
      });

      test('covariant', () {
        expect(Type('_?').closureWithRespectToUnknown(covariant: true)!.type,
            'Object?');
      });
    });

    group('RecordType:', () {
      test('unchanged', () {
        expect(
            Type('(int, {double a})')
                .closureWithRespectToUnknown(covariant: true),
            isNull);
        expect(
            Type('(int, {double a})')
                .closureWithRespectToUnknown(covariant: false),
            isNull);
      });

      group('changed:', () {
        group('positional:', () {
          test('covariant', () {
            expect(
              Type('(_, {double a})')
                  .closureWithRespectToUnknown(covariant: true)!
                  .type,
              '(Object?, {double a})',
            );
          });
          test('contravariant', () {
            expect(
              Type('(_, {double a})')
                  .closureWithRespectToUnknown(covariant: false)!
                  .type,
              '(Never, {double a})',
            );
          });
        });
        group('named:', () {
          test('covariant', () {
            expect(
              Type('(double, {_ a})')
                  .closureWithRespectToUnknown(covariant: true)!
                  .type,
              '(double, {Object? a})',
            );
          });
          test('contravariant', () {
            expect(
              Type('(double, {_ a})')
                  .closureWithRespectToUnknown(covariant: false)!
                  .type,
              '(double, {Never a})',
            );
          });
        });
      });
    });

    group('StarType:', () {
      test('unchanged', () {
        expect(
            Type('int*').closureWithRespectToUnknown(covariant: true), isNull);
        expect(
            Type('int*').closureWithRespectToUnknown(covariant: false), isNull);
      });

      test('covariant', () {
        expect(Type('_*').closureWithRespectToUnknown(covariant: true)!.type,
            'Object?');
      });
    });
  });
}
