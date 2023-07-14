// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  for (var mode in [SerializationMode.json, SerializationMode.byteData]) {
    test('$mode can serialize and deserialize basic data', () {
      withSerializationMode(mode, () {
        var serializer = serializerFactory();
        serializer
          ..addInt(0)
          ..addInt(1)
          ..addInt(0xff)
          ..addInt(0xffff)
          ..addInt(0xffffffff)
          ..addInt(0xffffffffffffffff)
          ..addInt(-1)
          ..addInt(-0x80)
          ..addInt(-0x8000)
          ..addInt(-0x80000000)
          ..addInt(-0x8000000000000000)
          ..addNullableInt(null)
          ..addString('hello')
          ..addString('€') // Requires a two byte string
          ..addString('𐐷') // Requires two, 16 bit code units
          ..addNullableString(null)
          ..startList()
          ..addBool(true)
          ..startList()
          ..addNull()
          ..endList()
          ..addNullableBool(null)
          ..endList()
          ..addDouble(1.0)
          ..startList()
          ..endList();
        var deserializer = deserializerFactory(serializer.result);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 1);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xffff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xffffffff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), 0xffffffffffffffff);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -1);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x80);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x8000);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x80000000);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectInt(), -0x8000000000000000);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectNullableInt(), null);
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectString(), 'hello');
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectString(), '€');
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectString(), '𐐷');
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectNullableString(), null);
        expect(deserializer.moveNext(), true);

        deserializer.expectList();
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectBool(), true);
        expect(deserializer.moveNext(), true);

        deserializer.expectList();
        expect(deserializer.moveNext(), true);
        expect(deserializer.checkNull(), true);
        expect(deserializer.moveNext(), false);

        expect(deserializer.moveNext(), true);
        expect(deserializer.expectNullableBool(), null);
        expect(deserializer.moveNext(), false);

        // Have to move the parent again to advance it past the list entry.
        expect(deserializer.moveNext(), true);
        expect(deserializer.expectDouble(), 1.0);
        expect(deserializer.moveNext(), true);

        deserializer.expectList();
        expect(deserializer.moveNext(), false);

        expect(deserializer.moveNext(), false);
      });
    });
  }

  for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
    test('remote instances in $mode', () async {
      var string = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'String'),
          typeArguments: const []);
      var foo = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
          typeArguments: [string]);

      withSerializationMode(mode, () {
        final int zoneId = newRemoteInstanceZone();
        withRemoteInstanceZone(zoneId, () {
          var serializer = serializerFactory();
          foo.serialize(serializer);
          // This is a fake client, we don't want to actually share the cache,
          // so we negate the zone id and use that.
          var response = roundTrip(serializer.result, -zoneId);
          var deserializer = deserializerFactory(response);
          var instance = RemoteInstance.deserialize(deserializer);
          expect(instance, foo);
        });
      });
    });
  }

  group('declarations', () {
    final barType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        isNullable: false,
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Bar'),
        typeArguments: []);
    final fooType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        isNullable: true,
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
        typeArguments: [barType]);

    for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
      group('with mode $mode', () {
        test('NamedTypeAnnotation', () {
          expectSerializationEquality<TypeAnnotationImpl>(
              fooType, mode, RemoteInstance.deserialize);
        });

        final fooNamedParam = ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'foo'),
            library: Fixtures.library,
            metadata: [],
            type: fooType);
        final fooNamedFunctionTypeParam = FunctionTypeParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            metadata: [],
            name: 'foo',
            type: fooType);

        final barPositionalParam = ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            isNamed: false,
            isRequired: false,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            library: Fixtures.library,
            metadata: [],
            type: barType);
        final barPositionalFunctionTypeParam = FunctionTypeParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            metadata: [],
            name: 'bar',
            type: fooType);

        final unnamedFunctionTypeParam = FunctionTypeParameterImpl(
            id: RemoteInstance.uniqueId,
            isNamed: true,
            isRequired: true,
            metadata: [],
            name: null,
            type: fooType);

        final zapTypeParam = TypeParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Zap'),
            library: Fixtures.library,
            metadata: [],
            bound: barType);

        // Transitively tests `TypeParameterDeclaration` and
        // `ParameterDeclaration`.
        test('FunctionTypeAnnotation', () {
          var functionType = FunctionTypeAnnotationImpl(
            id: RemoteInstance.uniqueId,
            isNullable: true,
            namedParameters: [
              fooNamedFunctionTypeParam,
              unnamedFunctionTypeParam
            ],
            positionalParameters: [barPositionalFunctionTypeParam],
            returnType: fooType,
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality<TypeAnnotationImpl>(
              functionType, mode, RemoteInstance.deserialize);
        });

        test('FunctionDeclaration', () {
          var function = FunctionDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'name'),
              library: Fixtures.library,
              metadata: [],
              isAbstract: true,
              isExternal: false,
              isGetter: true,
              isOperator: false,
              isSetter: false,
              namedParameters: [],
              positionalParameters: [],
              returnType: fooType,
              typeParameters: []);
          expectSerializationEquality<DeclarationImpl>(
              function, mode, RemoteInstance.deserialize);
        });

        test('MethodDeclaration', () {
          var method = MethodDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'zorp'),
              library: Fixtures.library,
              metadata: [],
              isAbstract: false,
              isExternal: false,
              isGetter: false,
              isOperator: false,
              isSetter: true,
              namedParameters: [fooNamedParam],
              positionalParameters: [barPositionalParam],
              returnType: fooType,
              typeParameters: [zapTypeParam],
              definingType: fooType.identifier,
              isStatic: false);
          expectSerializationEquality<DeclarationImpl>(
              method, mode, RemoteInstance.deserialize);
        });

        test('ConstructorDeclaration', () {
          var constructor = ConstructorDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'new'),
            library: Fixtures.library,
            metadata: [],
            isAbstract: false,
            isExternal: false,
            isGetter: false,
            isOperator: true,
            isSetter: false,
            namedParameters: [fooNamedParam],
            positionalParameters: [barPositionalParam],
            returnType: fooType,
            typeParameters: [zapTypeParam],
            definingType: fooType.identifier,
            isFactory: true,
          );
          expectSerializationEquality<DeclarationImpl>(
              constructor, mode, RemoteInstance.deserialize);
        });

        test('VariableDeclaration', () {
          var bar = VariableDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            library: Fixtures.library,
            metadata: [],
            isExternal: true,
            isFinal: false,
            isLate: true,
            type: barType,
          );
          expectSerializationEquality<DeclarationImpl>(
              bar, mode, RemoteInstance.deserialize);
        });

        test('FieldDeclaration', () {
          var bar = FieldDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bar'),
            library: Fixtures.library,
            metadata: [],
            isExternal: false,
            isFinal: true,
            isLate: false,
            type: barType,
            definingType: fooType.identifier,
            isStatic: false,
          );
          expectSerializationEquality<DeclarationImpl>(
              bar, mode, RemoteInstance.deserialize);
        });

        var objectType = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Object'),
          isNullable: false,
          typeArguments: [],
        );
        var serializableType = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Serializable'),
          isNullable: false,
          typeArguments: [],
        );

        test('ClassDeclaration', () {
          for (var boolValue in [true, false]) {
            var fooClass = ClassDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
              library: Fixtures.library,
              metadata: [],
              interfaces: [barType],
              hasAbstract: boolValue,
              hasBase: boolValue,
              hasExternal: boolValue,
              hasFinal: boolValue,
              hasInterface: boolValue,
              hasMixin: boolValue,
              hasSealed: boolValue,
              mixins: [serializableType],
              superclass: objectType,
              typeParameters: [zapTypeParam],
            );
            expectSerializationEquality<DeclarationImpl>(
                fooClass, mode, RemoteInstance.deserialize);
          }
        });

        test('EnumDeclaration', () {
          var fooEnum = EnumDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyEnum'),
            library: Fixtures.library,
            metadata: [],
            interfaces: [barType],
            mixins: [serializableType],
            typeParameters: [zapTypeParam],
          );
          expectSerializationEquality<DeclarationImpl>(
              fooEnum, mode, RemoteInstance.deserialize);
        });

        test('EnumValueDeclaration', () {
          var entry = EnumValueDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'a'),
            library: Fixtures.library,
            metadata: [],
            definingEnum:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyEnum'),
          );
          expectSerializationEquality<DeclarationImpl>(
              entry, mode, RemoteInstance.deserialize);
        });

        test('MixinDeclaration', () {
          for (var base in [true, false]) {
            var mixin = MixinDeclarationImpl(
              id: RemoteInstance.uniqueId,
              identifier:
                  IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyMixin'),
              library: Fixtures.library,
              metadata: [],
              hasBase: base,
              interfaces: [barType],
              superclassConstraints: [serializableType],
              typeParameters: [zapTypeParam],
            );
            expectSerializationEquality<DeclarationImpl>(
                mixin, mode, RemoteInstance.deserialize);
          }
        });

        test('TypeAliasDeclaration', () {
          var typeAlias = TypeAliasDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'FooOfBar'),
            library: Fixtures.library,
            metadata: [],
            typeParameters: [zapTypeParam],
            aliasedType: NamedTypeAnnotationImpl(
                id: RemoteInstance.uniqueId,
                isNullable: false,
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Foo'),
                typeArguments: [barType]),
          );
          expectSerializationEquality<DeclarationImpl>(
              typeAlias, mode, RemoteInstance.deserialize);
        });

        /// Transitively tests [RecordField]
        test('RecordTypeAnnotation', () {
          var recordType = RecordTypeAnnotationImpl(
            id: RemoteInstance.uniqueId,
            isNullable: true,
            namedFields: [
              RecordFieldDeclarationImpl(
                id: RemoteInstance.uniqueId,
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: r'hello'),
                library: Fixtures.library,
                metadata: [],
                name: 'hello',
                type: barType,
              ),
            ],
            positionalFields: [
              RecordFieldDeclarationImpl(
                id: RemoteInstance.uniqueId,
                identifier:
                    IdentifierImpl(id: RemoteInstance.uniqueId, name: r'$1'),
                library: Fixtures.library,
                metadata: [],
                name: null,
                type: fooType,
              ),
            ],
          );
          expectSerializationEquality<TypeAnnotationImpl>(
              recordType, mode, RemoteInstance.deserialize);
        });
      });
    }
  });

  group('Arguments', () {
    test('can create properly typed collections', () {
      withSerializationMode(SerializationMode.json, () {
        final parsed = Arguments.deserialize(deserializerFactory([
          // positional args
          [
            // int
            ArgumentKind.int.index,
            1,
            // List<int>
            ArgumentKind.list.index,
            [ArgumentKind.int.index],
            [
              ArgumentKind.int.index,
              1,
              ArgumentKind.int.index,
              2,
              ArgumentKind.int.index,
              3,
            ],
            // List<Set<String>>
            ArgumentKind.list.index,
            [ArgumentKind.set.index, ArgumentKind.string.index],
            [
              // Set<String>
              ArgumentKind.set.index,
              [ArgumentKind.string.index],
              [
                ArgumentKind.string.index,
                'hello',
                ArgumentKind.string.index,
                'world',
              ]
            ],
            // Map<int, List<String>>
            ArgumentKind.map.index,
            [
              ArgumentKind.int.index,
              ArgumentKind.nullable.index,
              ArgumentKind.list.index,
              ArgumentKind.string.index
            ],
            [
              // key: int
              ArgumentKind.int.index,
              4,
              // value: List<String>
              ArgumentKind.list.index,
              [ArgumentKind.string.index],
              [
                ArgumentKind.string.index,
                'zip',
              ],
              ArgumentKind.int.index,
              5,
              ArgumentKind.nil.index,
            ]
          ],
          // named args
          [],
        ]));
        expect(parsed.positional.length, 4);
        expect(parsed.positional.first.value, 1);
        expect(parsed.positional[1].value, [1, 2, 3]);
        expect(parsed.positional[1].value, isA<List<int>>());
        expect(parsed.positional[2].value, [
          {'hello', 'world'}
        ]);
        expect(parsed.positional[2].value, isA<List<Set<String>>>());
        expect(
          parsed.positional[3].value,
          {
            4: ['zip'],
            5: null,
          },
        );
        expect(parsed.positional[3].value, isA<Map<int, List<String>?>>());
      });
    });

    group('can be serialized and deserialized', () {
      for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
        test('with mode $mode', () {
          final arguments = Arguments([
            MapArgument({
              StringArgument('hello'): ListArgument(
                  [BoolArgument(true), NullArgument()],
                  [ArgumentKind.nullable, ArgumentKind.bool]),
            }, [
              ArgumentKind.string,
              ArgumentKind.list,
              ArgumentKind.nullable,
              ArgumentKind.bool
            ]),
            CodeArgument(ExpressionCode.fromParts([
              '1 + ',
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'a')
            ])),
            ListArgument([
              TypeAnnotationArgument(Fixtures.myClassType),
              TypeAnnotationArgument(Fixtures.myEnumType),
              TypeAnnotationArgument(NamedTypeAnnotationImpl(
                  id: RemoteInstance.uniqueId,
                  isNullable: false,
                  identifier:
                      IdentifierImpl(id: RemoteInstance.uniqueId, name: 'List'),
                  typeArguments: [Fixtures.stringType])),
            ], [
              ArgumentKind.typeAnnotation
            ])
          ], {
            'a': SetArgument([
              MapArgument({
                IntArgument(1): StringArgument('1'),
              }, [
                ArgumentKind.int,
                ArgumentKind.string
              ])
            ], [
              ArgumentKind.map,
              ArgumentKind.int,
              ArgumentKind.string
            ])
          });
          expectSerializationEquality(arguments, mode, Arguments.deserialize);
        });
      }
    });
  });

  group('metadata annotations can be serialized and deserialized', () {
    for (var mode in [SerializationMode.byteData, SerializationMode.json]) {
      group('with mode $mode', () {
        test('identifiers', () {
          final identifierMetadata = IdentifierMetadataAnnotationImpl(
              id: RemoteInstance.uniqueId,
              identifier: IdentifierImpl(
                  id: RemoteInstance.uniqueId, name: 'singleton'));

          expectSerializationEquality<IdentifierMetadataAnnotationImpl>(
              identifierMetadata, mode, RemoteInstance.deserialize);
        });

        test('constructor invocations', () {
          final constructorMetadata = ConstructorMetadataAnnotationImpl(
              id: RemoteInstance.uniqueId,
              type: IdentifierImpl(
                  id: RemoteInstance.uniqueId, name: 'Singleton'),
              constructor: IdentifierImpl(
                  id: RemoteInstance.uniqueId, name: 'someName'));

          expectSerializationEquality<ConstructorMetadataAnnotationImpl>(
              constructorMetadata, mode, RemoteInstance.deserialize);
        });
      });
    }
  });
}

/// Serializes [serializable] in server mode, then deserializes it in client
/// mode, and checks that all the fields are the same.
void expectSerializationEquality<T extends Serializable>(T serializable,
    SerializationMode mode, T deserialize(Deserializer deserializer)) {
  withSerializationMode(mode, () {
    late Object? serialized;
    final int zoneId = newRemoteInstanceZone();
    withRemoteInstanceZone(zoneId, () {
      var serializer = serializerFactory();
      serializable.serialize(serializer);
      serialized = serializer.result;
    });

    // This is a fake client, we don't want to actually share the cache,
    // so we negate the zone id and use that.
    withRemoteInstanceZone(-zoneId, () {
      var deserializer = deserializerFactory(serialized);
      var deserialized = deserialize(deserializer);

      expect(
          serializable,
          switch (deserialized) {
            Declaration() => deepEqualsDeclaration(deserialized as Declaration),
            TypeAnnotation() =>
              deepEqualsTypeAnnotation(deserialized as TypeAnnotation),
            Arguments() => deepEqualsArguments(deserialized),
            MetadataAnnotation() =>
              deepEqualsMetadataAnnotation(deserialized as MetadataAnnotation),
            _ => throw new UnsupportedError(
                'Unsupported object type $deserialized'),
          });
    }, createIfMissing: true);
  });
}

/// Deserializes [serialized] in its own remote instance cache and sends it
/// back.
Object? roundTrip<Declaration>(Object? serialized, int zoneId) {
  return withRemoteInstanceZone(zoneId, () {
    var deserializer = deserializerFactory(serialized);
    var instance = RemoteInstance.deserialize(deserializer) as Serializable;
    var serializer = serializerFactory();
    instance.serialize(serializer);
    return serializer.result;
  }, createIfMissing: true);
}
