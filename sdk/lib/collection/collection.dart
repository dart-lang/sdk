// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes and utilities that supplement the collection support in dart:core.
///
/// To use this library in your code:
/// ```dart
/// import 'dart:collection';
/// ```
///
/// ## Map
/// A collection of key/value pairs, from which to retrieve a value
/// using the associated key. [Map] is the general interface of key/value pair
/// collections.
/// * [HashMap] is unordered, the order of iteration is not guaranteed.
/// * [LinkedHashMap] iterates in key insertion order.
/// * [SplayTreeMap] iterates the keys in sorted order.
/// * [UnmodifiableMapView] is a wrapper, an unmodifiable [Map] view of another
/// Map.
///
/// ## Set
/// A collection of objects in which each object can occur only once.
/// [Set] is the general interface of collection where each object can occur
/// only once.
/// * [HashSet] the order of the objects in the iterations is not guaranteed.
/// * [LinkedHashSet] iterates the objects in insertion order.
/// * [SplayTreeSet] iterates the objects in sorted order.
/// * [UnmodifiableSetView] is a wrapper, an unmodifiable [Set] view of another
/// Set.
///
/// ## Queue
/// A queue is a collection that can be processed at both ends.
/// No access to object data through the index, access to first and last object.
/// * [Queue] is a base class for queue.
/// * [ListQueue] is a queue-based list. Default implementation for [Queue].
/// * [DoubleLinkedQueue] is a queue implementation based on a double-linked
/// list.
///
/// ## List
/// An indexable collection of objects, objects can be accessed through index
/// of list. [List] is also called an "array" in other programming languages.
/// * [UnmodifiableListView] is a wrapper, an unmodifiable [List] view of
/// another List.
///
/// ## LinkedList
/// [LinkedList] is a specialized double-linked list of elements that extends
/// [LinkedListEntry]. Each element knows its own place in the linked list,
/// as well as which list it is in.
/// {@category Core}
library dart.collection;

import 'dart:_internal' hide Symbol;
import 'dart:math' show Random; // Used by ListMixin.shuffle.

export 'dart:_internal' show DoubleLinkedQueueEntry;

part 'collections.dart';
part 'hash_map.dart';
part 'hash_set.dart';
part 'iterable.dart';
part 'iterator.dart';
part 'linked_hash_map.dart';
part 'linked_hash_set.dart';
part 'linked_list.dart';
part 'list.dart';
part 'maps.dart';
part 'queue.dart';
part 'set.dart';
part 'splay_tree.dart';
