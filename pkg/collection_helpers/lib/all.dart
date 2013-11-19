// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Exports all the individual parts of the collection-helper library.
 *
 * The sub-libraries of this package are:
 *
 * - `algorithms.dart`: Algorithms that work on lists (shuffle, binary search
 *   and various sorting algorithms).
 * - `wrappers.dart`: Wrapper classes that delegate to a collection object.
 * - `equality.dart`: Different notions of equality of collections.
 * - `typed_buffers.dart`: Growable typed data lists.
 */
library dart.collection_helper;

export "algorithms.dart";
export "equality.dart";
export "typed_buffers.dart";
export "wrappers.dart";
