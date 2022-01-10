// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Check whether two references are to the same object.
/// ```dart
/// void main() {
///  Car micro = Car(type: 'Micro', color: 'Red');
///  Car suv = Car(type: 'SUV', color: 'Black');
///
///  var areObjectsIdentical = identical(micro, micro);
///  print(areObjectsIdentical); // true
///
///  areObjectsIdentical = identical(micro, suv);
///  print(areObjectsIdentical); // false
/// }
///
/// class Car {
///  late final type;
///  late final color;
///
///  Car({this.type, this.color});
/// }
/// ```
external bool identical(Object? a, Object? b);

/// The identity hash code of [object].
///
/// Returns the value that the original [Object.hashCode] would return
/// on this object, even if `hashCode` has been overridden.
///
/// This hash code is compatible with [identical],
/// which just means that it's guaranteed to be stable over time.
/// ```dart
/// void main() {
///  Car micro = Car(type: 'Micro', color: 'Red');
///  int identityHashCode = identityHashCode(micro);
///  print(identityHashCode); // Hash code of the object
/// }
///
/// class Car {
///  late final type;
///  late final color;
///
///  Car({this.type, this.color});
/// }
/// ```
@pragma("vm:entry-point")
external int identityHashCode(Object? object);
