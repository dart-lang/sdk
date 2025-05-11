// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
            FunctionType(TypeParameterType(t), [
              TypeParameterType(u),
              TypeParameterType(v),
            ]).toString(),
            'T Function(U, V)',
          );
        });

        test('all optional', () {
          expect(
            FunctionType(TypeParameterType(t), [
              TypeParameterType(u),
              TypeParameterType(v),
            ], requiredPositionalParameterCount: 0).toString(),
            'T Function([U, V])',
          );
        });

        test('mixed required and optional', () {
          expect(
            FunctionType(TypeParameterType(t), [
              TypeParameterType(u),
              TypeParameterType(v),
            ], requiredPositionalParameterCount: 1).toString(),
            'T Function(U, [V])',
          );
        });
      });

      test('named parameters', () {
        expect(
          FunctionType(
            TypeParameterType(t),
            [],
            namedParameters: [
              NamedFunctionParameter(
                isRequired: false,
                type: TypeParameterType(u),
                name: 'x',
              ),
              NamedFunctionParameter(
                isRequired: true,
                type: TypeParameterType(v),
                name: 'y',
              ),
            ],
          ).toString(),
          'T Function({U x, required V y})',
        );
      });

      test('positional and named parameters', () {
        expect(
          FunctionType(
            TypeParameterType(t),
            [TypeParameterType(u)],
            namedParameters: [
              NamedFunctionParameter(
                isRequired: false,
                type: TypeParameterType(v),
                name: 'y',
              ),
            ],
          ).toString(),
          'T Function(U, {V y})',
        );
      });

      test('type formals, unbounded', () {
        expect(
          FunctionType(
            VoidType.instance,
            [],
            typeParametersShared: [t, u],
          ).toString(),
          'void Function<T, U>()',
        );
      });

      test('type formals, bounded', () {
        t.explicitBound = TypeParameterType(u);
        expect(
          FunctionType(
            VoidType.instance,
            [],
            typeParametersShared: [t, u],
          ).toString(),
          'void Function<T extends U, U>()',
        );
      });

      test('needs parentheses', () {
        expect(
          TypeParameterType(
            t,
            promotion: FunctionType(VoidType.instance, []),
          ).toString(),
          'T&(void Function())',
        );
      });
    });

    group('PrimaryType:', () {
      test('simple', () {
        expect(TypeParameterType(t).toString(), 'T');
      });

      test('with arguments', () {
        expect(
          PrimaryType(
            TypeRegistry.map,
            args: [TypeParameterType(t), TypeParameterType(u)],
          ).toString(),
          'Map<T, U>',
        );
      });
    });

    group('PromotedTypeVariableType:', () {
      test('basic', () {
        expect(
          TypeParameterType(t, promotion: TypeParameterType(u)).toString(),
          'T&U',
        );
      });

      test('needs parentheses (right)', () {
        expect(
          TypeParameterType(
            t,
            promotion: TypeParameterType(u, promotion: TypeParameterType(v)),
          ).toString(),
          'T&(U&V)',
        );
      });

      test('needs parentheses (question)', () {
        expect(
          TypeParameterType(
            t,
            promotion: TypeParameterType(u),
            isQuestionType: true,
          ).toString(),
          '(T&U)?',
        );
      });
    });

    group('QuestionType:', () {
      test('basic', () {
        expect(TypeParameterType(t, isQuestionType: true).toString(), 'T?');
      });

      test('needs parentheses', () {
        expect(
          TypeParameterType(
            t,
            promotion: TypeParameterType(u, isQuestionType: true),
          ).toString(),
          'T&(U?)',
        );
      });
    });

    group('RecordType:', () {
      test('no arguments', () {
        expect(
          RecordType(positionalTypes: [], namedTypes: []).toString(),
          '()',
        );
      });

      test('single positional argument', () {
        expect(
          RecordType(
            positionalTypes: [TypeParameterType(t)],
            namedTypes: [],
          ).toString(),
          '(T,)',
        );
      });

      test('multiple positional arguments', () {
        expect(
          RecordType(
            positionalTypes: [TypeParameterType(t), TypeParameterType(u)],
            namedTypes: [],
          ).toString(),
          '(T, U)',
        );
      });

      test('single named argument', () {
        expect(
          RecordType(
            positionalTypes: [],
            namedTypes: [NamedType(name: 't', type: TypeParameterType(t))],
          ).toString(),
          '({T t})',
        );
      });

      test('multiple named arguments', () {
        expect(
          RecordType(
            positionalTypes: [],
            namedTypes: [
              NamedType(name: 't', type: TypeParameterType(t)),
              NamedType(name: 'u', type: TypeParameterType(u)),
            ],
          ).toString(),
          '({T t, U u})',
        );
      });

      test('both positional and named arguments', () {
        expect(
          RecordType(
            positionalTypes: [TypeParameterType(t)],
            namedTypes: [NamedType(name: 'u', type: TypeParameterType(u))],
          ).toString(),
          '(T, {U u})',
        );
      });
    });

    test('UnknownType', () {
      expect(UnknownType().toString(), '_');
    });
  });

  group('parse:', () {
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
      expect(type.isQuestionType, true);
      expect(type.asQuestionType(false).type, 'int');
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

      group('type formals:', () {
        test('single', () {
          var type = Type('int Function<T>()') as FunctionType;
          expect(type.typeParametersShared, hasLength(1));
          expect(type.typeParametersShared[0].name, 'T');
        });

        test('multiple', () {
          var type = Type('int Function<T, U>()') as FunctionType;
          expect(type.typeParametersShared, hasLength(2));
          expect(type.typeParametersShared[0].name, 'T');
          expect(type.typeParametersShared[1].name, 'U');
        });

        test('return type and parameters can refer to type formal', () {
          var type = Type('T Function<T>(T, {T t})') as FunctionType;
          var t = type.typeParametersShared.single;
          expect((type.returnType as TypeParameterType).typeParameter, same(t));
          expect(
            (type.positionalParameters.single as TypeParameterType)
                .typeParameter,
            same(t),
          );
          expect(
            (type.namedParameters.single.type as TypeParameterType)
                .typeParameter,
            same(t),
          );
        });

        test('unbounded', () {
          var type = Type('void Function<T>()') as FunctionType;
          var t = type.typeParametersShared.single;
          expect(t.explicitBound, isNull);
        });

        test('bounded', () {
          var type = Type('void Function<T extends Object>()') as FunctionType;
          var t = type.typeParametersShared.single;
          expect(t.explicitBound!.type, 'Object');
        });

        test('F-bounded', () {
          var type = Type('void Function<T extends U, U>()') as FunctionType;
          var t = type.typeParametersShared[0];
          var u = type.typeParametersShared[1];
          expect((t.explicitBound as TypeParameterType).typeParameter, same(u));
        });

        test('invalid token in type formals', () {
          expect(() => Type('int Function<{>()'), throwsParseError);
        });

        test('invalid token at end of type formals', () {
          expect(() => Type('int Function<T}()'), throwsParseError);
        });
      });

      test('invalid parameter separator', () {
        expect(
          () => Type('int Function(String Function()< double)'),
          throwsParseError,
        );
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

  group('hashCode and equality:', () {
    void checkEqual(Type t1, Type t2) {
      expect(t1 == t2, isTrue);
      expect(t1.hashCode == t2.hashCode, isTrue);
    }

    void checkNotEqual(Type t1, Type t2) {
      expect(t1 == t2, isFalse);
      // Note: don't compare `t1.hashCode` to `t2.hashCode` because it's not
      // guaranteed whether they will be different or not. And besides, it
      // really only matters for efficiency, and efficiency is not needed for
      // the "mini_types" representation because it's only used in unit tests.
    }

    test('FunctionType', () {
      checkEqual(Type('void Function()'), Type('void Function()'));
      checkNotEqual(Type('void Function()?'), Type('void Function()'));
      checkNotEqual(Type('T Function()'), Type('void Function()'));
      checkNotEqual(Type('void Function(T)'), Type('void Function()'));
      checkEqual(Type('void Function(T)'), Type('void Function(T)'));
      checkNotEqual(Type('void Function(T)'), Type('void Function(U)'));
      checkNotEqual(Type('void Function(T)'), Type('void Function([T])'));
      checkNotEqual(Type('void Function({T t})'), Type('void Function()'));
      checkEqual(Type('void Function({T t})'), Type('void Function({T t})'));
      checkNotEqual(
        Type('void Function({T t})'),
        Type('void Function({required T t})'),
      );
      checkNotEqual(Type('void Function({T t})'), Type('void Function({U t})'));
      checkNotEqual(Type('void Function({T t})'), Type('void Function({T u})'));
      checkNotEqual(Type('void Function()'), Type('void Function<T>()'));
      checkNotEqual(
        Type('void Function<T, U>(T, U)?'),
        Type('void Function<U, T>(U, T)'),
      );
      checkEqual(
        Type('void Function<T, U>(T, U)'),
        Type('void Function<U, T>(U, T)'),
      );
      checkNotEqual(
        Type('void Function<T, U>(T, U)'),
        Type('void Function<T, U>(U, T)'),
      );
      checkEqual(
        Type('void Function<T, U>({T p1, U p2})'),
        Type('void Function<U, T>({U p1, T p2})'),
      );
      checkNotEqual(
        Type('void Function<T, U>({T p1, U p2})'),
        Type('void Function<T, U>({U p1, T p2})'),
      );
      checkEqual(
        Type('void Function<T extends Object>()'),
        Type('void Function<U extends Object>()'),
      );
      checkEqual(
        Type('void Function<T extends Object?>()'),
        Type('void Function<U>()'),
      );
      checkNotEqual(
        Type('void Function<T extends Object>()'),
        Type('void Function<U extends int>()'),
      );
      checkEqual(
        Type('void Function<T extends U, U>()'),
        Type('void Function<V extends W, W>()'),
      );
      checkEqual(
        Type('void Function<T>(void Function<U extends T>(T, U))'),
        Type('void Function<V>(void Function<W extends V>(V, W))'),
      );

      // For these final test cases, we give one of the type parameters a name
      // that would be chosen by `FreshTypeParameterGenerator`, to verify that
      // the logic for avoiding name collisions does the right thing.
      var t = FreshTypeParameterGenerator().generate().name;
      checkEqual(Type('$t Function<$t>()'), Type('U Function<U>()'));
      checkNotEqual(
        Type('void Function<$t>(X Function<X>($t))'),
        Type('void Function<$t>($t Function<X>($t))'),
      );
    });

    test('PrimaryType', () {
      checkEqual(Type('int'), Type('int'));
      checkNotEqual(Type('int'), Type('String'));
      checkNotEqual(Type('int'), Type('int?'));
      checkEqual(Type('Map<int, String>'), Type('Map<int, String>'));
      checkNotEqual(Type('Map<int, String>'), Type('Map<int, double>'));
      checkNotEqual(Type('Map<int, String>'), Type('Map<num, String>'));
      checkNotEqual(Type('List<int>'), Type('Iterable<int>'));
      checkEqual(Type('dynamic'), Type('dynamic'));
      checkEqual(Type('error'), Type('error'));
      checkEqual(Type('Never'), Type('Never'));
      checkEqual(Type('Null'), Type('Null'));
      checkEqual(Type('void'), Type('void'));
      checkEqual(Type('FutureOr<int>'), Type('FutureOr<int>'));
      checkNotEqual(Type('dynamic'), Type('error'));
      checkNotEqual(Type('error'), Type('Never'));
      checkNotEqual(Type('Never'), Type('Null'));
      checkNotEqual(Type('Null'), Type('void'));
      checkNotEqual(Type('void'), Type('dynamic'));
      checkNotEqual(Type('FutureOr<int>'), Type('FutureOr<String>'));
      checkNotEqual(Type('FutureOr<int>'), Type('dynamic'));
    });

    test('RecordType', () {
      checkEqual(Type('(int,)'), Type('(int,)'));
      checkNotEqual(Type('(int,)?'), Type('(int,)'));
      checkNotEqual(Type('(int, T)'), Type('(int,)'));
      checkNotEqual(Type('(T,)'), Type('(U,)'));
      checkNotEqual(Type('(int, {T t})'), Type('(int,)'));
      checkEqual(Type('({T t})'), Type('({T t})'));
      checkNotEqual(Type('({T t})'), Type('({U t})'));
      checkNotEqual(Type('({T t})'), Type('({T u})'));
    });

    test('TypeParameterType', () {
      checkEqual(Type('T'), Type('T'));
      checkNotEqual(Type('T?'), Type('T'));
      checkNotEqual(Type('T'), Type('U'));
      checkNotEqual(Type('T&int'), Type('T'));
      checkEqual(Type('T&int'), Type('T&int'));
      checkNotEqual(Type('T&int'), Type('T&String'));
      // Type formals from different function types are not equal
      checkNotEqual(
        TypeParameterType(
          (Type('void Function<T>()') as FunctionType)
              .typeParametersShared
              .single,
        ),
        TypeParameterType(
          (Type('void Function<T>()') as FunctionType)
              .typeParametersShared
              .single,
        ),
      );
    });

    test('UnknownType', () {
      checkEqual(Type('_'), Type('_'));
      checkNotEqual(Type('_?'), Type('_'));
    });
  });

  group('FreshTypeParameterGenerator:', () {
    test('generates type parameters with a bound of Object?', () {
      var ftpg = FreshTypeParameterGenerator();
      expect(ftpg.generate().bound.toString(), 'Object?');
      expect(ftpg.generate().bound.toString(), 'Object?');
      expect(ftpg.generate().bound.toString(), 'Object?');
    });

    test('generates a fresh name each time generate is called', () {
      var ftpg = FreshTypeParameterGenerator();
      expect(ftpg.generate().name, 'T0');
      expect(ftpg.generate().name, 'T1');
      expect(ftpg.generate().name, 'T2');
    });

    test('skips names appearing in types passed to excludeNamesUsedIn', () {
      var ftpg = FreshTypeParameterGenerator();
      TypeRegistry.addInterfaceTypeName('T0');
      TypeRegistry.addInterfaceTypeName('T2');
      TypeRegistry.addInterfaceTypeName('T3');
      ftpg.excludeNamesUsedIn(Type('T0<T2, T3>'));
      expect(ftpg.generate().name, 'T1');
      expect(ftpg.generate().name, 'T4');
      expect(ftpg.generate().name, 'T5');
    });
  });

  group('recursivelyDemote:', () {
    group('FunctionType:', () {
      group('return type:', () {
        test('unchanged', () {
          expect(
            Type('int Function()').recursivelyDemote(covariant: true),
            isNull,
          );
          expect(
            Type('int Function()').recursivelyDemote(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type('T&int Function()').recursivelyDemote(covariant: true)!.type,
            'T Function()',
          );
        });

        test('contravariant', () {
          expect(
            Type('T&int Function()').recursivelyDemote(covariant: false)!.type,
            'Never Function()',
          );
        });

        test('generic', () {
          expect(
            Type(
              'T&int Function<U>()',
            ).recursivelyDemote(covariant: true)!.type,
            'T Function<U>()',
          );
        });
      });

      group('positional parameters:', () {
        test('unchanged', () {
          expect(
            Type(
              'void Function(int, String)',
            ).recursivelyDemote(covariant: true),
            isNull,
          );
          expect(
            Type(
              'void Function(int, String)',
            ).recursivelyDemote(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type(
              'void Function(T&int, String)',
            ).recursivelyDemote(covariant: true)!.type,
            'void Function(Never, String)',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              'void Function(T&int, String)',
            ).recursivelyDemote(covariant: false)!.type,
            'void Function(T, String)',
          );
        });
      });

      group('named parameters:', () {
        test('unchanged', () {
          expect(
            Type(
              'void Function({int x, String y})',
            ).recursivelyDemote(covariant: true),
            isNull,
          );
          expect(
            Type(
              'void Function({int x, String y})',
            ).recursivelyDemote(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type(
              'void Function({T&int x, String y})',
            ).recursivelyDemote(covariant: true)!.type,
            'void Function({Never x, String y})',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              'void Function({T&int x, String y})',
            ).recursivelyDemote(covariant: false)!.type,
            'void Function({T x, String y})',
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
          expect(
            Type('Map<int, String>').recursivelyDemote(covariant: true),
            isNull,
          );
          expect(
            Type('Map<int, String>').recursivelyDemote(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type('Map<T&int, String>').recursivelyDemote(covariant: true)!.type,
            'Map<T, String>',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              'Map<T&int, String>',
            ).recursivelyDemote(covariant: false)!.type,
            'Map<Never, String>',
          );
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
        expect(
          Type('(T&int)?').recursivelyDemote(covariant: false)!.type,
          'Never?',
        );
      });
    });

    group('RecordType:', () {
      test('unchanged', () {
        expect(
          Type('(int, {double a})').recursivelyDemote(covariant: true),
          isNull,
        );
        expect(
          Type('(int, {double a})').recursivelyDemote(covariant: false),
          isNull,
        );
      });

      group('changed:', () {
        group('positional:', () {
          test('covariant', () {
            expect(
              Type(
                '(T&int, {double a})',
              ).recursivelyDemote(covariant: true)!.type,
              '(T, {double a})',
            );
          });
          test('contravariant', () {
            expect(
              Type(
                '(T&int, {double a})',
              ).recursivelyDemote(covariant: false)!.type,
              '(Never, {double a})',
            );
          });
        });
        group('named:', () {
          test('covariant', () {
            expect(
              Type(
                '(double, {T&int a})',
              ).recursivelyDemote(covariant: true)!.type,
              '(double, {T a})',
            );
          });
          test('contravariant', () {
            expect(
              Type(
                '(double, {T&int a})',
              ).recursivelyDemote(covariant: false)!.type,
              '(double, {Never a})',
            );
          });
        });
      });
    });

    test('UnknownType:', () {
      expect(Type('_').recursivelyDemote(covariant: true), isNull);
      expect(Type('_').recursivelyDemote(covariant: false), isNull);
    });
  });

  group('closureWithRespectToUnknown:', () {
    test('UnknownType:', () {
      expect(
        Type('_').closureWithRespectToUnknown(covariant: true)!.type,
        'Object?',
      );
      expect(
        Type('_').closureWithRespectToUnknown(covariant: false)!.type,
        'Never',
      );
    });

    group('FunctionType:', () {
      group('return type:', () {
        test('unchanged', () {
          expect(
            Type('int Function()').closureWithRespectToUnknown(covariant: true),
            isNull,
          );
          expect(
            Type(
              'int Function()',
            ).closureWithRespectToUnknown(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type(
              '_ Function()',
            ).closureWithRespectToUnknown(covariant: true)!.type,
            'Object? Function()',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              '_ Function()',
            ).closureWithRespectToUnknown(covariant: false)!.type,
            'Never Function()',
          );
        });

        test('generic', () {
          expect(
            Type(
              '_ Function<T>()',
            ).closureWithRespectToUnknown(covariant: true)!.type,
            'Object? Function<T>()',
          );
        });
      });

      group('positional parameters:', () {
        test('unchanged', () {
          expect(
            Type(
              'void Function(int, String)',
            ).closureWithRespectToUnknown(covariant: true),
            isNull,
          );
          expect(
            Type(
              'void Function(int, String)',
            ).closureWithRespectToUnknown(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type(
              'void Function(_, String)',
            ).closureWithRespectToUnknown(covariant: true)!.type,
            'void Function(Never, String)',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              'void Function(_, String)',
            ).closureWithRespectToUnknown(covariant: false)!.type,
            'void Function(Object?, String)',
          );
        });
      });

      group('named parameters:', () {
        test('unchanged', () {
          expect(
            Type(
              'void Function({int x, String y})',
            ).closureWithRespectToUnknown(covariant: true),
            isNull,
          );
          expect(
            Type(
              'void Function({int x, String y})',
            ).closureWithRespectToUnknown(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type(
              'void Function({_ x, String y})',
            ).closureWithRespectToUnknown(covariant: true)!.type,
            'void Function({Never x, String y})',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              'void Function({_ x, String y})',
            ).closureWithRespectToUnknown(covariant: false)!.type,
            'void Function({Object? x, String y})',
          );
        });
      });
    });

    group('NonFunctionType', () {
      test('unchanged', () {
        expect(
          Type('int').closureWithRespectToUnknown(covariant: true),
          isNull,
        );
        expect(
          Type('int').closureWithRespectToUnknown(covariant: false),
          isNull,
        );
      });

      group('type parameters:', () {
        test('unchanged', () {
          expect(
            Type(
              'Map<int, String>',
            ).closureWithRespectToUnknown(covariant: true),
            isNull,
          );
          expect(
            Type(
              'Map<int, String>',
            ).closureWithRespectToUnknown(covariant: false),
            isNull,
          );
        });

        test('covariant', () {
          expect(
            Type(
              'Map<_, String>',
            ).closureWithRespectToUnknown(covariant: true)!.type,
            'Map<Object?, String>',
          );
        });

        test('contravariant', () {
          expect(
            Type(
              'Map<_, String>',
            ).closureWithRespectToUnknown(covariant: false)!.type,
            'Map<Never, String>',
          );
        });
      });
    });

    group('QuestionType:', () {
      test('unchanged', () {
        expect(
          Type('int?').closureWithRespectToUnknown(covariant: true),
          isNull,
        );
        expect(
          Type('int?').closureWithRespectToUnknown(covariant: false),
          isNull,
        );
      });

      test('covariant', () {
        expect(
          Type('_?').closureWithRespectToUnknown(covariant: true)!.type,
          'Object?',
        );
      });
    });

    group('RecordType:', () {
      test('unchanged', () {
        expect(
          Type(
            '(int, {double a})',
          ).closureWithRespectToUnknown(covariant: true),
          isNull,
        );
        expect(
          Type(
            '(int, {double a})',
          ).closureWithRespectToUnknown(covariant: false),
          isNull,
        );
      });

      group('changed:', () {
        group('positional:', () {
          test('covariant', () {
            expect(
              Type(
                '(_, {double a})',
              ).closureWithRespectToUnknown(covariant: true)!.type,
              '(Object?, {double a})',
            );
          });
          test('contravariant', () {
            expect(
              Type(
                '(_, {double a})',
              ).closureWithRespectToUnknown(covariant: false)!.type,
              '(Never, {double a})',
            );
          });
        });
        group('named:', () {
          test('covariant', () {
            expect(
              Type(
                '(double, {_ a})',
              ).closureWithRespectToUnknown(covariant: true)!.type,
              '(double, {Object? a})',
            );
          });
          test('contravariant', () {
            expect(
              Type(
                '(double, {_ a})',
              ).closureWithRespectToUnknown(covariant: false)!.type,
              '(double, {Never a})',
            );
          });
        });
      });
    });
  });

  group('gatherUsedIdentifiers:', () {
    Set<String> queryUsedIdentifiers(Type t) {
      var identifiers = <String>{};
      t.gatherUsedIdentifiers(identifiers);
      return identifiers;
    }

    test('FunctionType', () {
      expect(
        queryUsedIdentifiers(Type('int Function<X>(String, {bool b})')),
        unorderedEquals({'int', 'X', 'String', 'bool', 'b'}),
      );
      expect(
        queryUsedIdentifiers(Type('void Function<X extends int>()')),
        unorderedEquals({'void', 'X', 'int'}),
      );
    });

    test('PrimaryType', () {
      expect(
        queryUsedIdentifiers(Type('Map<String, int>')),
        unorderedEquals({'Map', 'String', 'int'}),
      );
      expect(
        queryUsedIdentifiers(Type('dynamic')),
        unorderedEquals({'dynamic'}),
      );
      expect(queryUsedIdentifiers(Type('error')), unorderedEquals({'error'}));
      expect(queryUsedIdentifiers(Type('Never')), unorderedEquals({'Never'}));
      expect(queryUsedIdentifiers(Type('Null')), unorderedEquals({'Null'}));
      expect(queryUsedIdentifiers(Type('void')), unorderedEquals({'void'}));
      expect(
        queryUsedIdentifiers(Type('FutureOr<int>')),
        unorderedEquals({'FutureOr', 'int'}),
      );
    });

    test('RecordType', () {
      expect(
        queryUsedIdentifiers(Type('(int, {String s})')),
        unorderedEquals({'int', 'String', 's'}),
      );
    });

    test('TypeParameterType', () {
      expect(queryUsedIdentifiers(Type('T')), unorderedEquals({'T'}));
      expect(
        queryUsedIdentifiers(Type('T&int')),
        unorderedEquals({'T', 'int'}),
      );
    });

    test('UnknownType', () {
      expect(queryUsedIdentifiers(Type('_')), isEmpty);
    });
  });

  group('substitute:', () {
    test('FunctionType', () {
      expect(
        Type('int Function<U>(int, {int i})').substitute({t: Type('String')}),
        isNull,
      );
      expect(
        Type('T Function<U>(int, {int i})').substitute({t: Type('String')}),
        Type('String Function<U>(int, {int i})'),
      );
      expect(
        Type('int Function<U>(T, {int i})?').substitute({t: Type('String')}),
        Type('int Function<U>(String, {int i})?'),
      );
      expect(
        Type('int Function<U>(int, {T i})').substitute({t: Type('String')}),
        Type('int Function<U>(int, {String i})'),
      );
      expect(
        (Type('int Function<U>(int, {int i})') as FunctionType).substitute({
          t: Type('String'),
        }, dropTypeFormals: true),
        Type('int Function(int, {int i})'),
      );
      expect(
        (Type('int Function<U>(int, {int i})?') as FunctionType).substitute({
          t: Type('String'),
        }, dropTypeFormals: true),
        Type('int Function(int, {int i})?'),
      );
      expect(
        Type('int Function(T, T)').substitute({t: Type('String')}),
        Type('int Function(String, String)'),
      );
      expect(
        Type('int Function({T t1, T t2})').substitute({t: Type('String')}),
        Type('int Function({String t1, String t2})'),
      );

      // Verify that bounds of type parameters are substituted
      var origType = Type(
        'Map<U, V> Function<U extends T, V extends U>(U, V, {U u, V v})',
      );
      var substitutedType =
          origType.substitute({t: Type('String')}) as FunctionType;
      expect(
        substitutedType,
        Type(
          'Map<U, V> Function<U extends String, V extends U>(U, V, {U u, '
          'V v})',
        ),
      );
      // And verify that references to the type parameters now point to the
      // new, updated type parameters.
      expect(
        ((substitutedType.returnType as PrimaryType).args[0]
                as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[0]),
      );
      expect(
        ((substitutedType.returnType as PrimaryType).args[1]
                as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[1]),
      );
      expect(
        (substitutedType.typeParametersShared[1].explicitBound
                as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[0]),
      );
      expect(
        (substitutedType.positionalParameters[0] as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[0]),
      );
      expect(
        (substitutedType.positionalParameters[1] as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[1]),
      );
      expect(
        (substitutedType.namedParameters[0].type as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[0]),
      );
      expect(
        (substitutedType.namedParameters[1].type as TypeParameterType)
            .typeParameter,
        same(substitutedType.typeParametersShared[1]),
      );
      // Finally, verify that the original type didn't change (this is important
      // because `TypeParameter.explicitBound` is non-final in order to allow
      // for the creation of F-bounded types).
      expect(
        origType,
        Type(
          'Map<U, V> Function<U extends T, V extends U>(U, V, {U u, '
          'V v})',
        ),
      );
    });

    test('PrimaryType', () {
      expect(Type('Map<int, int>').substitute({t: Type('String')}), isNull);
      expect(
        Type('Map<T, int>').substitute({t: Type('String')}),
        Type('Map<String, int>'),
      );
      expect(
        Type('Map<int, T>').substitute({t: Type('String')}),
        Type('Map<int, String>'),
      );
      expect(
        Type('Map<T, T>').substitute({t: Type('String')}),
        Type('Map<String, String>'),
      );
      expect(Type('dynamic').substitute({t: Type('String')}), isNull);
      expect(Type('error').substitute({t: Type('String')}), isNull);
      expect(Type('Never').substitute({t: Type('String')}), isNull);
      expect(Type('Null').substitute({t: Type('String')}), isNull);
      expect(Type('void').substitute({t: Type('String')}), isNull);
      expect(Type('FutureOr<int>').substitute({t: Type('String')}), isNull);
      expect(
        Type('FutureOr<T>').substitute({t: Type('String')}),
        Type('FutureOr<String>'),
      );
    });

    test('RecordType', () {
      expect(Type('(int, {int i})').substitute({t: Type('String')}), isNull);
      expect(
        Type('(T, {int i})?').substitute({t: Type('String')}),
        Type('(String, {int i})?'),
      );
      expect(
        Type('(int, {T i})').substitute({t: Type('String')}),
        Type('(int, {String i})'),
      );
      expect(
        Type('(T, T)').substitute({t: Type('String')}),
        Type('(String, String)'),
      );
      expect(
        Type('({T t1, T t2})').substitute({t: Type('String')}),
        Type('({String t1, String t2})'),
      );
    });

    test('TypeParameterType', () {
      expect(Type('T').substitute({u: Type('String')}), isNull);
      expect(Type('T').substitute({t: Type('String')}), Type('String'));
      expect(Type('T&Object').substitute({t: Type('String')}), Type('String'));
    });

    test('UnknownType', () {
      expect(Type('_').substitute({t: Type('String')}), isNull);
    });
  });
}
