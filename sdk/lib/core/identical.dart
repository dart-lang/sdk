// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// Check whether two references are to the same object.
external bool identical(Object? a, Object? b);

/// The identity hash code of [object].
///
/// Returns the value that the original [Object.hashCode] would return
/// on this object, even if `hashCode` has been overridden.
///
/// This hash code is compatible with [identical],
/// which just means that it's guaranteed to be stable over time.
@pragma("vm:entry-point")
external int identityHashCode(Object? object);
