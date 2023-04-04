// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// This [Iterable] mixin implements all [Iterable] members except `iterator`.
///
/// All other methods are implemented in terms of `iterator`.
// @Deprecated("Use Iterable instead")
typedef IterableMixin<E> = Iterable<E>;

/// Base class for implementing [Iterable].
///
/// This class implements all methods of [Iterable], except [Iterable.iterator],
/// in terms of `iterator`.
// @Deprecated("Use Iterable instead")
typedef IterableBase<E> = Iterable<E>;
