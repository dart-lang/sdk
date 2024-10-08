// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/nullability_suffix.dart';
import 'package:test/test.dart';

import 'mini_types.dart';

main() {
  late TypeParameter t;
  late TypeParameter u;
  late TypeParameter v;

  setUp(() {
    TypeRegistry.init();
    t = TypeRegistry.addTypeParameter('T');
    u = TypeRegistry.addTypeParameter('U');
    v = TypeRegistry.addTypeParameter('V');
  });

  tearDown(() {
    TypeRegistry.uninit();
  });

  group('toString:', () {
    group('FunctionType:', () {
      group('positional parameters:', () {
        test('all required', () {
          expect(
              FunctionType(TypeParameterType(t),
                  [TypeParameterType(u), TypeParameterType(v)]).toString(),
              'T Function(U, V)');
        });

        test('all optional', () {
          expect(
              FunctionType(TypeParameterType(t),
                      [TypeParameterType(u), TypeParameterType(v)],
                      requiredPositionalParameterCount: 0)
                  .toString(),
              'T Function([U, V])');
        });

        test('mixed required and optional', () {
          expect(
              FunctionType(TypeParameterType(t),
                      [TypeParameterType(u), TypeParameterType(v)],
                      requiredPositionalParameterCount: 1)
                  .toString(),
              'T Function(U, [V])');
        });
      });

      test('named parameters', () {
        expect(
            FunctionType(TypeParameterType(t), [], namedParameters: [
              NamedFunctionParameter(
                  isRequired: false, type: TypeParameterType(u), name: 'x'),
              NamedFunctionParameter(
                  isRequired: true, type: TypeParameterType(v), name: 'y')
            ]).toString(),
            'T Function({U x, required V y})');
      });

      test('positional and named parameters', () {
        expect(
            FunctionType(TypeParameterType(t), [
              TypeParameterType(u)
            ], namedParameters: [
              NamedFunctionParameter(
                  isRequired: false, type: TypeParameterType(v), name: 'y')
            ]).toString(),
            'T Function(U, {V y})');
      });

      test('needs parentheses', () {
        expect(
            TypeParameterType(t, promotion: FunctionType(VoidType.instance, []))
                .toString(),
            'T&(void Function())');
      });
    });

    group('PrimaryType:', () {
      test('simple', () {
        expect(TypeParameterType(t).toString(), 'T');
      });

      test('with arguments', () {
        expect(
            PrimaryType(TypeRegistry.map,
                args: [TypeParameterType(t), TypeParameterType(u)]).toString(),
            'Map<T, U>');
      });
    });

    group('PromotedTypeVariableType:', () {
      test('basic', () {
        expect(TypeParameterType(t, promotion: TypeParameterType(u)).toString(),
            'T&U');
      });

      test('needs parentheses (right)', () {
        expect(
            TypeParameterType(t,
                    promotion:
                        TypeParameterType(u, promotion: TypeParameterType(v)))
                .toString(),
            'T&(U&V)');
      });

      test('needs parentheses (question)', () {
        expect(
            TypeParameterType(t,
                    promotion: TypeParameterType(u),
                    nullabilitySuffix: NullabilitySuffix.question)
                .toString(),
            '(T&U)?');
      });

      test('needs parentheses (star)', () {
        expect(
            TypeParameterType(t,
                    promotion: TypeParameterType(u),
                    nullabilitySuffix: NullabilitySuffix.star)
                .toString(),
            '(T&U)*');
      });
    });

    group('QuestionType:', () {
      test('basic', () {
        expect(
            TypeParameterType(t, nullabilitySuffix: NullabilitySuffix.question)
                .toString(),
            'T?');
      });

      test('needs parentheses', () {
        expect(
            TypeParameterType(t,
                    promotion: TypeParameterType(u,
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
            RecordType(positionalTypes: [TypeParameterType(t)], namedTypes: [])
                .toString(),
            '(T,)');
      });

      test('multiple positional arguments', () {
        expect(
            RecordType(
                positionalTypes: [TypeParameterType(t), TypeParameterType(u)],
                namedTypes: []).toString(),
            '(T, U)');
      });

      test('single named argument', () {
        expect(
            RecordType(positionalTypes: [], namedTypes: [
              NamedType(name: 't', type: TypeParameterType(t))
            ]).toString(),
            '({T t})');
      });

      test('multiple named arguments', () {
        expect(
            RecordType(positionalTypes: [], namedTypes: [
              NamedType(name: 't', type: TypeParameterType(t)),
              NamedType(name: 'u', type: TypeParameterType(u))
            ]).toString(),
            '({T t, U u})');
      });

      test('both positional and named arguments', () {
        expect(
            RecordType(positionalTypes: [
              TypeParameterType(t)
            ], namedTypes: [
              NamedType(name: 'u', type: TypeParameterType(u))
            ]).toString(),
            '(T, {U u})');
      });
    });

    group('StarType:', () {
      test('basic', () {
        expect(
            TypeParameterType(t, nullabilitySuffix: NullabilitySuffix.star)
                .toString(),
            'T*');
      });

      test('needs parentheses', () {
        expect(
            TypeParameterType(t,
                    promotion: TypeParameterType(u,
                        nullabilitySuffix: NullabilitySuffix.star))
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
        var type = Type('int') as PrimaryType;
        expect(type.name, 'int');
        expect(type.args, isEmpty);
      });

      test('type arg', () {
        var type = Type('List<int>') as PrimaryType;
        expect(type.name, 'List');
        expect(type.args, hasLength(1));
        expect(type.args[0].type, 'int');
      });

      test('type args', () {
        var type = Type('Map<int, String>') as PrimaryType;
        expect(type.name, 'Map');
        expect(type.args, hasLength(2));
        expect(type.args[0].type, 'int');
        expect(type.args[1].type, 'String');
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
        var type = Type('FutureOr<int>') as FutureOrType;
        expect(type.typeArgument.type, 'int');
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
      var type = Type('_');
      expect(type, TypeMatcher<UnknownType>());
    });

    test('question type', () {
      var type = Type('int?');
      expect(type.nullabilitySuffix, NullabilitySuffix.question);
      expect(type.withNullability(NullabilitySuffix.none).type, 'int');
    });

    test('star type', () {
      var type = Type('int*');
      expect(type.nullabilitySuffix, NullabilitySuffix.star);
      expect(type.withNullability(NullabilitySuffix.none).type, 'int');
    });

    test('promoted type variable', () {
      var type = Type('T&int') as TypeParameterType;
      expect(type.typeParameter, t);
      expect(type.promotion!.type, 'int');
    });

    test('parenthesized type', () {
      var type = Type('(int)');
      expect(type.type, 'int');
    });

    test('invalid token terminating parenthesized type', () {
      expect(() => Type('(?<'), throwsParseError);
    });

    group('function type:', () {
      test('no parameters', () {
        var type = Type('int Function()') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, isEmpty);
        expect(type.requiredPositionalParameterCount, 0);
        expect(type.namedParameters, isEmpty);
      });

      test('required positional parameter', () {
        var type = Type('int Function(String)') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, hasLength(1));
        expect(type.positionalParameters[0].type, 'String');
        expect(type.requiredPositionalParameterCount, 1);
        expect(type.namedParameters, isEmpty);
      });

      test('required positional parameters', () {
        var type = Type('int Function(String, double)') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, hasLength(2));
        expect(type.positionalParameters[0].type, 'String');
        expect(type.positionalParameters[1].type, 'double');
        expect(type.requiredPositionalParameterCount, 2);
        expect(type.namedParameters, isEmpty);
      });

      test('optional positional parameter', () {
        var type = Type('int Function([String])') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, hasLength(1));
        expect(type.positionalParameters[0].type, 'String');
        expect(type.requiredPositionalParameterCount, 0);
        expect(type.namedParameters, isEmpty);
      });

      test('optional positional parameters', () {
        var type = Type('int Function([String, double])') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, hasLength(2));
        expect(type.positionalParameters[0].type, 'String');
        expect(type.positionalParameters[1].type, 'double');
        expect(type.requiredPositionalParameterCount, 0);
        expect(type.namedParameters, isEmpty);
      });

      group('named parameter:', () {
        test('not required', () {
          var type = Type('int Function({String x})') as FunctionType;
          expect(type.returnType.type, 'int');
          expect(type.positionalParameters, isEmpty);
          expect(type.requiredPositionalParameterCount, 0);
          expect(type.namedParameters, hasLength(1));
          expect(type.namedParameters[0].isRequired, false);
          expect(type.namedParameters[0].type.type, 'String');
          expect(type.namedParameters[0].name, 'x');
        });

        test('required', () {
          var type = Type('int Function({required String x})') as FunctionType;
          expect(type.returnType.type, 'int');
          expect(type.positionalParameters, isEmpty);
          expect(type.requiredPositionalParameterCount, 0);
          expect(type.namedParameters, hasLength(1));
          expect(type.namedParameters[0].isRequired, true);
          expect(type.namedParameters[0].type.type, 'String');
          expect(type.namedParameters[0].name, 'x');
        });
      });

      test('named parameters', () {
        var type = Type('int Function({String x, double y})') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, isEmpty);
        expect(type.requiredPositionalParameterCount, 0);
        expect(type.namedParameters, hasLength(2));
        expect(type.namedParameters[0].isRequired, false);
        expect(type.namedParameters[0].type.type, 'String');
        expect(type.namedParameters[0].name, 'x');
        expect(type.namedParameters[1].isRequired, false);
        expect(type.namedParameters[1].type.type, 'double');
        expect(type.namedParameters[1].name, 'y');
      });

      test('named parameter sorting', () {
        var type = Type('int Function({double y, String x})') as FunctionType;
        expect(type.returnType.type, 'int');
        expect(type.positionalParameters, isEmpty);
        expect(type.requiredPositionalParameterCount, 0);
        expect(type.namedParameters, hasLength(2));
        expect(type.namedParameters[0].isRequired, false);
        expect(type.namedParameters[0].type.type, 'String');
        expect(type.namedParameters[0].name, 'x');
        expect(type.namedParameters[1].isRequired, false);
        expect(type.namedParameters[1].type.type, 'double');
        expect(type.namedParameters[1].name, 'y');
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
        var type = Type('()') as RecordType;
        expect(type.positionalTypes, isEmpty);
        expect(type.namedTypes, isEmpty);
      });

      test('named field', () {
        var type = Type('({int x})') as RecordType;
        expect(type.positionalTypes, isEmpty);
        expect(type.namedTypes, hasLength(1));
        expect(type.namedTypes[0].name, 'x');
        expect(type.namedTypes[0].type.type, 'int');
      });

      test('named field followed by comma', () {
        var type = Type('({int x,})') as RecordType;
        expect(type.positionalTypes, isEmpty);
        expect(type.namedTypes, hasLength(1));
        expect(type.namedTypes[0].name, 'x');
        expect(type.namedTypes[0].type.type, 'int');
      });

      test('named field followed by invalid token', () {
        expect(() => Type('({int x))'), throwsParseError);
      });

      test('named field name is not an identifier', () {
        expect(() => Type('({int )})'), throwsParseError);
      });

      test('named fields', () {
        var type = Type('({int x, String y})') as RecordType;
        expect(type.positionalTypes, isEmpty);
        expect(type.namedTypes, hasLength(2));
        expect(type.namedTypes[0].name, 'x');
        expect(type.namedTypes[0].type.type, 'int');
        expect(type.namedTypes[1].name, 'y');
        expect(type.namedTypes[1].type.type, 'String');
      });

      test('curly braces followed by invalid token', () {
        expect(() => Type('({int x}&'), throwsParseError);
      });

      test('curly braces but no named fields', () {
        expect(() => Type('({})'), throwsParseError);
      });

      test('positional field', () {
        var type = Type('(int,)') as RecordType;
        expect(type.namedTypes, isEmpty);
        expect(type.positionalTypes, hasLength(1));
        expect(type.positionalTypes[0].type, 'int');
      });

      group('positional fields:', () {
        test('two', () {
          var type = Type('(int, String)') as RecordType;
          expect(type.namedTypes, isEmpty);
          expect(type.positionalTypes, hasLength(2));
          expect(type.positionalTypes[0].type, 'int');
          expect(type.positionalTypes[1].type, 'String');
        });

        test('three', () {
          var type = Type('(int, String, double)') as RecordType;
          expect(type.namedTypes, isEmpty);
          expect(type.positionalTypes, hasLength(3));
          expect(type.positionalTypes[0].type, 'int');
          expect(type.positionalTypes[1].type, 'String');
          expect(type.positionalTypes[2].type, 'double');
        });
      });

      test('named and positional fields', () {
        var type = Type('(int, {String x})') as RecordType;
        expect(type.positionalTypes, hasLength(1));
        expect(type.positionalTypes[0].type, 'int');
        expect(type.namedTypes, hasLength(1));
        expect(type.namedTypes[0].name, 'x');
        expect(type.namedTypes[0].type.type, 'String');
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

      group('named parameters:', () {
        test('unchanged', () {
          expect(
              Type('void Function({int x, String y})')
                  .recursivelyDemote(covariant: true),
              isNull);
          expect(
              Type('void Function({int x, String y})')
                  .recursivelyDemote(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('void Function({T&int x, String y})')
                  .recursivelyDemote(covariant: true)!
                  .type,
              'void Function({Never x, String y})');
        });

        test('contravariant', () {
          expect(
              Type('void Function({T&int x, String y})')
                  .recursivelyDemote(covariant: false)!
                  .type,
              'void Function({T x, String y})');
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

      group('named parameters:', () {
        test('unchanged', () {
          expect(
              Type('void Function({int x, String y})')
                  .closureWithRespectToUnknown(covariant: true),
              isNull);
          expect(
              Type('void Function({int x, String y})')
                  .closureWithRespectToUnknown(covariant: false),
              isNull);
        });

        test('covariant', () {
          expect(
              Type('void Function({_ x, String y})')
                  .closureWithRespectToUnknown(covariant: true)!
                  .type,
              'void Function({Never x, String y})');
        });

        test('contravariant', () {
          expect(
              Type('void Function({_ x, String y})')
                  .closureWithRespectToUnknown(covariant: false)!
                  .type,
              'void Function({Object? x, String y})');
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
