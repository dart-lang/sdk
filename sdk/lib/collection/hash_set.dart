// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:collection";

/// An unordered hash-table based [Set] implementation.
///
/// The elements of a `HashSet` must have consistent equality
/// and hashCode implementations. This means that the equals operation
/// must define a stable equivalence relation on the elements (reflexive,
/// symmetric, transitive, and consistent over time), and that the hashCode
/// must be consistent with equality, so that it's the same for objects that are
/// considered equal.
///
/// Most simple operations on `HashSet` are done in (potentially amortized)
/// constant time: [add], [contains], [remove], and [length], provided the hash
/// codes of objects are well distributed.
///
/// **The iteration order of the set is not specified and depends on
/// the hashcodes of the provided elements.** However, the order is stable:
/// multiple iterations over the same set produce the same order, as long as
/// the set is not modified.
///
/// **Note:**
/// Do not modify a set (add or remove elements) while an operation
/// is being performed on that set, for example in functions
/// called during a [forEach] or [containsAll] call,
/// or while iterating the set.
///
/// Do not modify elements in a way which changes their equality (and thus their
/// hash code) while they are in the set. Some specialized kinds of sets may be
/// more permissive with regards to equality, in which case they should document
/// their different behavior and restrictions.
///
/// Example:
/// ```dart
/// final letters = HashSet<String>();
/// ```
/// To add data to a set, use  [add] or [addAll].
/// ```dart continued
/// letters.add('A');
/// letters.addAll({'B', 'C', 'D'});
/// ```
/// To check if the set is empty, use [isEmpty] or [isNotEmpty].
/// To find the number of elements in the set, use [length].
/// ```dart continued
/// print(letters.isEmpty); // false
/// print(letters.length); // 4
/// print(letters); // fx {A, D, C, B}
/// ```
/// To check whether the set has an element with a specific value,
/// use [contains].
/// ```dart continued
/// final bExists = letters.contains('B'); // true
/// ```
/// The [forEach] method calls a function with each element of the set.
/// ```dart continued
/// letters.forEach(print);
/// // A
/// // D
/// // C
/// // B
/// ```
/// To make a copy of the set, use [toSet].
/// ```dart continued
/// final anotherSet = letters.toSet();
/// print(anotherSet); // fx {A, C, D, B}
/// ```
/// To remove an element, use [remove].
/// ```dart continued
/// final removedValue = letters.remove('A'); // true
/// print(letters); // fx {B, C, D}
/// ```
/// To remove multiple elements at the same time, use [removeWhere] or
/// [removeAll].
/// ```dart continued
/// letters.removeWhere((element) => element.startsWith('B'));
/// print(letters); // fx {D, C}
/// ```
/// To removes all elements in this set that do not meet a condition,
/// use [retainWhere].
/// ```dart continued
/// letters.retainWhere((element) => element.contains('C'));
/// print(letters); // {C}
/// ```
/// To remove all elements and empty the set, use [clear].
/// ```dart continued
/// letters.clear();
/// print(letters.isEmpty); // true
/// print(letters); // {}
/// ```
/// **See also:**
/// * [Set] is the general interface of collection where each object can
/// occur only once.
/// * [LinkedHashSet] objects stored based on insertion order.
/// * [SplayTreeSet] iterates the objects in sorted order.
@Deprecated("Use LinkedHashSet instead")
typedef HashSet<E> = LinkedHashSet<E>;

