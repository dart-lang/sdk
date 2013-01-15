// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The common interface of all collections.
 *
 * The [Collection] class contains a skeleton implementation of
 * an iterator based collection.
 */
abstract class Collection<E> extends Iterable<E> {
  const Collection();
}
