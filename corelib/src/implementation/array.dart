// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Array<E> extends List<E> factory ArrayFactory {
  // TODO(bak): Only constructors should be here for the rename Array->List.
  Array([int length]);
  Array.from(Iterable<E> other);
  Array.fromArray(Array<E> other, int startIndex, int endIndex);
}
