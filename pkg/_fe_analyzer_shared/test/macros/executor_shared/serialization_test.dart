// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/serialization.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/serialization_extensions.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  group('json serializer', () {
    test('can serialize and deserialize basic data', () {
      var serializer = JsonSerializer();
      serializer
        ..addNum(1)
        ..addNullableNum(null)
        ..addString('hello')
        ..addNullableString(null)
        ..startList()
        ..addBool(true)
        ..startList()
        ..addNull()
        ..endList()
        ..addNullableBool(null)
        ..endList()
        ..addNum(1.0)
        ..startList()
        ..endList();
      expect(
          serializer.result,
          equals([
            1,
            null,
            'hello',
            null,
            [
              true,
              [null],
              null
            ],
            1.0,
            [],
          ]));
      var deserializer = JsonDeserializer(serializer.result);
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNum(), 1);
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectNullableNum(), null);
      expect(deserializer.moveNext(), true);
      expect(deserializer.expectString(), 'hello');
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
      expect(deserializer.expectNum(), 1.0);
      expect(deserializer.moveNext(), true);

      deserializer.expectList();
      expect(deserializer.moveNext(), false);

      expect(deserializer.moveNext(), false);
    });

    test('remote instances', () async {
      var string = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          name: 'String',
          typeArguments: const []);
      var foo = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          name: 'Foo',
          typeArguments: [string]);
      Object? serializedFoo;
      var serializer = JsonSerializer();

      withSerializationMode(SerializationMode.server, () {
        foo.serialize(serializer);
        serializedFoo = serializer.result;
        var response = roundTrip(serializedFoo);
        var deserializer = JsonDeserializer(response as List<Object?>);
        var instance = RemoteInstance.deserialize(deserializer);
        expect(instance, foo);
      });
    });

    group('declarations', () {
      final barType = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          name: 'Bar',
          typeArguments: []);
      final fooType = NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: true,
          name: 'Foo',
          typeArguments: [barType]);

      test('NamedTypeAnnotation', () {
        expectSerializationEquality(fooType);
      });

      final fooNamedParam = ParameterDeclarationImpl(
          id: RemoteInstance.uniqueId,
          defaultValue: null,
          isNamed: true,
          isRequired: true,
          name: 'foo',
          type: fooType);

      final barPositionalParam = ParameterDeclarationImpl(
          id: RemoteInstance.uniqueId,
          defaultValue: Code.fromString('const Bar()'),
          isNamed: false,
          isRequired: false,
          name: 'bar',
          type: barType);

      final zapTypeParam = TypeParameterDeclarationImpl(
          id: RemoteInstance.uniqueId, name: 'Zap', bounds: barType);

      // Transitively tests `TypeParameterDeclaration` and
      // `ParameterDeclaration`.
      test('FunctionTypeAnnotation', () {
        var functionType = FunctionTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: true,
          namedParameters: [fooNamedParam],
          positionalParameters: [barPositionalParam],
          returnType: fooType,
          typeParameters: [zapTypeParam],
        );
        expectSerializationEquality(functionType);
      });

      test('FunctionDeclaration', () {
        var function = FunctionDeclarationImpl(
            id: RemoteInstance.uniqueId,
            name: 'name',
            isAbstract: true,
            isExternal: false,
            isGetter: true,
            isSetter: false,
            namedParameters: [],
            positionalParameters: [],
            returnType: fooType,
            typeParameters: []);
        expectSerializationEquality(function);
      });

      test('MethodDeclaration', () {
        var method = MethodDeclarationImpl(
            id: RemoteInstance.uniqueId,
            name: 'zorp',
            isAbstract: false,
            isExternal: false,
            isGetter: false,
            isSetter: true,
            namedParameters: [fooNamedParam],
            positionalParameters: [barPositionalParam],
            returnType: fooType,
            typeParameters: [zapTypeParam],
            definingClass: fooType);
        expectSerializationEquality(method);
      });

      test('ConstructorDeclaration', () {
        var constructor = ConstructorDeclarationImpl(
          id: RemoteInstance.uniqueId,
          name: 'new',
          isAbstract: false,
          isExternal: false,
          isGetter: false,
          isSetter: false,
          namedParameters: [fooNamedParam],
          positionalParameters: [barPositionalParam],
          returnType: fooType,
          typeParameters: [zapTypeParam],
          definingClass: fooType,
          isFactory: true,
        );
        expectSerializationEquality(constructor);
      });

      test('VariableDeclaration', () {
        var bar = VariableDeclarationImpl(
          id: RemoteInstance.uniqueId,
          name: 'bar',
          isAbstract: false,
          isExternal: true,
          initializer: Code.fromString('Bar()'),
          type: barType,
        );
        expectSerializationEquality(bar);
      });

      test('FieldDeclaration', () {
        var bar = FieldDeclarationImpl(
          id: RemoteInstance.uniqueId,
          name: 'bar',
          isAbstract: false,
          isExternal: false,
          initializer: null,
          type: barType,
          definingClass: fooType,
        );
        expectSerializationEquality(bar);
      });

      var objectType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'Object',
        isNullable: false,
        typeArguments: [],
      );
      var serializableType = NamedTypeAnnotationImpl(
        id: RemoteInstance.uniqueId,
        name: 'Serializable',
        isNullable: false,
        typeArguments: [],
      );

      test('ClassDeclaration', () {
        var fooClass = ClassDeclarationImpl(
          id: RemoteInstance.uniqueId,
          name: 'Foo',
          interfaces: [barType],
          isAbstract: true,
          isExternal: false,
          mixins: [serializableType],
          superclass: objectType,
          typeParameters: [zapTypeParam],
        );
        expectSerializationEquality(fooClass);
      });

      test('TypeAliasDeclaration', () {
        var typeAlias = TypeAliasDeclarationImpl(
          id: RemoteInstance.uniqueId,
          name: 'FooOfBar',
          type: NamedTypeAnnotationImpl(
              id: RemoteInstance.uniqueId,
              isNullable: false,
              name: 'Foo',
              typeArguments: [barType]),
          typeParameters: [zapTypeParam],
        );
        expectSerializationEquality(typeAlias);
      });
    });
  });
}

/// Serializes [serializable] in server mode, then deserializes it in client
/// mode, and checks that all the fields are the same.
void expectSerializationEquality(Serializable serializable) {
  var serializer = JsonSerializer();
  withSerializationMode(SerializationMode.server, () {
    serializable.serialize(serializer);
  });
  withSerializationMode(SerializationMode.client, () {
    var deserializer = JsonDeserializer(serializer.result);
    var deserialized = (deserializer..moveNext()).expectRemoteInstance();
    if (deserialized is Declaration) {
      expect(serializable, deepEqualsDeclaration(deserialized));
    } else if (deserialized is TypeAnnotation) {
      expect(serializable, deepEqualsTypeAnnotation(deserialized));
    } else {
      throw new UnsupportedError('Unsupported object type $deserialized');
    }
  });
}

/// Deserializes [serialized] in client mode and sends it back.
Object? roundTrip<Declaration>(Object? serialized) {
  return withSerializationMode(SerializationMode.client, () {
    var deserializer = JsonDeserializer(serialized as List<Object?>);
    var instance =
        RemoteInstance.deserialize<NamedTypeAnnotationImpl>(deserializer);
    var serializer = JsonSerializer();
    instance.serialize(serializer);
    return serializer.result;
  });
}
