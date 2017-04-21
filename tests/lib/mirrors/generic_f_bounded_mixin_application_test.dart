// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_f_bounded;

@MirrorsUsed(targets: "test.generic_f_bounded")
import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class Collection<C> {}

class Serializable<S> {}

class OrderedCollection<V> extends Collection<V>
    with Serializable<OrderedCollection<V>> {}

class AbstractOrderedCollection<W> = Collection<W>
    with Serializable<AbstractOrderedCollection<W>>;

class CustomOrderedCollection<Z> extends AbstractOrderedCollection<Z> {}

class OrderedIntegerCollection extends OrderedCollection<int> {}

class CustomOrderedIntegerCollection extends CustomOrderedCollection<int> {}

class Serializer<R extends Serializable<R>> {}

class CollectionSerializer extends Serializer<Collection> {}

class OrderedCollectionSerializer extends Serializer<OrderedCollection> {}

main() {
  ClassMirror collectionDecl = reflectClass(Collection);
  ClassMirror serializableDecl = reflectClass(Serializable);
  ClassMirror orderedCollectionDecl = reflectClass(OrderedCollection);
  ClassMirror abstractOrderedCollectionDecl =
      reflectClass(AbstractOrderedCollection);
  ClassMirror customOrderedCollectionDecl =
      reflectClass(CustomOrderedCollection);
  ClassMirror orderedIntegerCollection = reflectClass(OrderedIntegerCollection);
  ClassMirror customOrderedIntegerCollection =
      reflectClass(CustomOrderedIntegerCollection);
  ClassMirror serializerDecl = reflectClass(Serializer);
  ClassMirror collectionSerializerDecl = reflectClass(CollectionSerializer);
  ClassMirror orderedCollectionSerializerDecl =
      reflectClass(OrderedCollectionSerializer);

  ClassMirror orderedCollectionOfInt = orderedIntegerCollection.superclass;
  ClassMirror customOrderedCollectionOfInt =
      customOrderedIntegerCollection.superclass;
  ClassMirror serializerOfCollection = collectionSerializerDecl.superclass;
  ClassMirror serializerOfOrderedCollection =
      orderedCollectionSerializerDecl.superclass;
  ClassMirror collectionOfDynamic = reflect(new Collection()).type;
  ClassMirror orderedCollectionOfDynamic =
      reflect(new OrderedCollection()).type;
  ClassMirror collectionWithSerializableOfOrderedCollection =
      orderedCollectionDecl.superclass;

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
      collectionWithSerializableOfOrderedCollection.isOriginalDeclaration);

  TypeVariableMirror rFromSerializer = serializerDecl.typeVariables.single;
  ClassMirror serializableOfR = rFromSerializer.upperBound;
  Expect.isFalse(serializableOfR.isOriginalDeclaration);
  Expect.equals(serializableDecl, serializableOfR.originalDeclaration);
  Expect.equals(rFromSerializer, serializableOfR.typeArguments.single);

  typeParameters(collectionDecl, [#C]);
  typeParameters(serializableDecl, [#S]);
  typeParameters(orderedCollectionDecl, [#V]);
  typeParameters(abstractOrderedCollectionDecl, [#W]);
  typeParameters(customOrderedCollectionDecl, [#Z]);
  typeParameters(orderedIntegerCollection, []);
  typeParameters(customOrderedIntegerCollection, []);
  typeParameters(serializerDecl, [#R]);
  typeParameters(collectionSerializerDecl, []);
  typeParameters(orderedCollectionSerializerDecl, []);

  typeParameters(orderedCollectionOfInt, [#V]);
  typeParameters(customOrderedCollectionOfInt, [#Z]);
  typeParameters(serializerOfCollection, [#R]);
  typeParameters(serializerOfOrderedCollection, [#R]);
  typeParameters(collectionOfDynamic, [#C]);
  typeParameters(collectionWithSerializableOfOrderedCollection, []);

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
  typeArguments(serializerOfCollection, [collectionOfDynamic]);
  typeArguments(serializerOfOrderedCollection, [orderedCollectionOfDynamic]);
  typeArguments(collectionWithSerializableOfOrderedCollection, []);
}
