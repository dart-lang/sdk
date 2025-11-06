// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Collection<C> {}

mixin Serializable<S> {}

class OrderedCollection<V> extends Collection<V>
    with Serializable<OrderedCollection<V>> {}

class AbstractOrderedCollection<W> = Collection<W>
    with Serializable<AbstractOrderedCollection<W>>;

class CustomOrderedCollection<Z> extends AbstractOrderedCollection<Z> {}

class OrderedIntegerCollection extends OrderedCollection<int> {}

class CustomOrderedIntegerCollection extends CustomOrderedCollection<int> {}

class Serializer<R extends Serializable<R>> {}

class CollectionSerializer extends Serializer<AbstractOrderedCollection> {}

class OrderedCollectionSerializer extends Serializer<OrderedCollection> {}

void main() {
  ClassMirror collectionDecl = reflectClass(Collection);
  ClassMirror serializableDecl = reflectClass(Serializable);
  ClassMirror orderedCollectionDecl = reflectClass(OrderedCollection);
  ClassMirror abstractOrderedCollectionDecl = reflectClass(
    AbstractOrderedCollection,
  );
  ClassMirror customOrderedCollectionDecl = reflectClass(
    CustomOrderedCollection,
  );
  ClassMirror orderedIntegerCollection = reflectClass(OrderedIntegerCollection);
  ClassMirror customOrderedIntegerCollection = reflectClass(
    CustomOrderedIntegerCollection,
  );
  ClassMirror serializerDecl = reflectClass(Serializer);
  ClassMirror collectionSerializerDecl = reflectClass(CollectionSerializer);
  ClassMirror orderedCollectionSerializerDecl = reflectClass(
    OrderedCollectionSerializer,
  );

  ClassMirror orderedCollectionOfInt = orderedIntegerCollection.superclass!;
  ClassMirror customOrderedCollectionOfInt =
      customOrderedIntegerCollection.superclass!;
  ClassMirror serializerOfCollection = collectionSerializerDecl.superclass!;
  ClassMirror serializerOfOrderedCollection =
      orderedCollectionSerializerDecl.superclass!;
  ClassMirror collectionOfDynamic =
      reflectType(Collection<dynamic>) as ClassMirror;
  ClassMirror orderedCollectionOfDynamic =
      reflectType(OrderedCollection<dynamic>) as ClassMirror;
  ClassMirror collectionWithSerializableOfOrderedCollection =
      orderedCollectionDecl.superclass!;
  ClassMirror abstractOrderedCollectionOfDynamic =
      reflectType(AbstractOrderedCollection<dynamic>) as ClassMirror;

  Expect.isTrue(collectionDecl.isOriginalDeclaration);
  Expect.isTrue(serializableDecl.isOriginalDeclaration);
  Expect.isTrue(orderedCollectionDecl.isOriginalDeclaration);
  Expect.isTrue(abstractOrderedCollectionDecl.isOriginalDeclaration);
  Expect.isTrue(customOrderedCollectionDecl.isOriginalDeclaration);
  Expect.isTrue(orderedIntegerCollection.isOriginalDeclaration);
  Expect.isTrue(customOrderedIntegerCollection.isOriginalDeclaration);
  Expect.isTrue(serializerDecl.isOriginalDeclaration);
  Expect.isTrue(collectionSerializerDecl.isOriginalDeclaration);
  Expect.isTrue(orderedCollectionSerializerDecl.isOriginalDeclaration);

  Expect.isFalse(orderedCollectionOfInt.isOriginalDeclaration);
  Expect.isFalse(customOrderedCollectionOfInt.isOriginalDeclaration);
  Expect.isFalse(serializerOfCollection.isOriginalDeclaration);
  Expect.isFalse(serializerOfOrderedCollection.isOriginalDeclaration);
  Expect.isFalse(collectionOfDynamic.isOriginalDeclaration);
  Expect.isFalse(
    collectionWithSerializableOfOrderedCollection.isOriginalDeclaration,
  );

  TypeVariableMirror rFromSerializer = serializerDecl.typeVariables.single;
  ClassMirror serializableOfR = rFromSerializer.upperBound as ClassMirror;
  Expect.isFalse(serializableOfR.isOriginalDeclaration);
  Expect.equals(serializableDecl, serializableOfR.originalDeclaration);
  Expect.equals(rFromSerializer, serializableOfR.typeArguments.single);

  typeParameters(collectionDecl, [#X0]);
  typeParameters(serializableDecl, [#X0]);
  typeParameters(orderedCollectionDecl, [#X0]);
  typeParameters(abstractOrderedCollectionDecl, [#X0]);
  typeParameters(customOrderedCollectionDecl, [#X0]);
  typeParameters(orderedIntegerCollection, []);
  typeParameters(customOrderedIntegerCollection, []);
  typeParameters(serializerDecl, [#X0]);
  typeParameters(collectionSerializerDecl, []);
  typeParameters(orderedCollectionSerializerDecl, []);

  typeParameters(orderedCollectionOfInt, [#X0]);
  typeParameters(customOrderedCollectionOfInt, [#X0]);
  typeParameters(serializerOfCollection, [#X0]);
  typeParameters(serializerOfOrderedCollection, [#X0]);
  typeParameters(collectionOfDynamic, [#X0]);
  typeParameters(collectionWithSerializableOfOrderedCollection, [#X0]);

  typeArguments(collectionDecl, []);
  typeArguments(serializableDecl, []);
  typeArguments(orderedCollectionDecl, []);
  typeArguments(abstractOrderedCollectionDecl, []);
  typeArguments(customOrderedCollectionDecl, []);
  typeArguments(orderedIntegerCollection, []);
  typeArguments(customOrderedIntegerCollection, []);
  typeArguments(serializerDecl, []);
  typeArguments(collectionSerializerDecl, []);
  typeArguments(orderedCollectionSerializerDecl, []);

  typeArguments(orderedCollectionOfInt, [reflectClass(int)]);
  typeArguments(customOrderedCollectionOfInt, [reflectClass(int)]);
  typeArguments(serializerOfCollection, [abstractOrderedCollectionOfDynamic]);
  typeArguments(serializerOfOrderedCollection, [orderedCollectionOfDynamic]);
  typeArguments(collectionWithSerializableOfOrderedCollection, [
    collectionWithSerializableOfOrderedCollection.typeVariables[0],
  ]);
}
