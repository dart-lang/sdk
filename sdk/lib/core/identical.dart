// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Check whether two references are to the same object.
///
/// Example:
/// ```dart
/// var o = new Object();
/// var isIdentical = identical(o, new Object()); // false, different objects.
/// isIdentical = identical(o, o); // true, same object
/// isIdentical = identical(const Object(), const Object()); // true, const canonicalizes
/// isIdentical = identical([1], [1]); // false
/// isIdentical = identical(const [1], const [1]); // true
/// isIdentical = identical(const [1], const [2]); // false
/// isIdentical = identical(2, 1 + 1); // true, integers canonicalizes
/// ```
external bool identical(Object? a, Object? b);

/// The identity hash code of [object].
///
/// Returns the value that the original [Object.hashCode] would return
/// on this object, even if `hashCode` has been overridden.
///
/// This hash code is compatible with [identical],
/// which just means that it's guaranteed to be stable over time.
/// ```dart import:dart:collection
/// var identitySet = HashSet(equals: identical, hashCode: identityHashCode);
/// var dt1 = DateTime.now();
/// var dt2 = DateTime.fromMicrosecondsSinceEpoch(dt1.microsecondsSinceEpoch);
/// assert(dt1 == dt2);
/// identitySet.add(dt1);
/// print(identitySet.contains(dt1)); // true
/// print(identitySet.contains(dt2)); // false
/// ```
@pragma("vm:entry-point")
external int identityHashCode(Object? object);
