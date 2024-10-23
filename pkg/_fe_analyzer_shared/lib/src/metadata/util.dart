// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension ResolveHelper<E> on List<E> {
  /// Calls [f] on all elements in the list an returns the resulting list.
  ///
  /// If all elements returned `null`, `null` is returned. Otherwise a list
  /// which for each element is the element returned from [f] or itself if
  /// `null`.
  List<E>? resolve(E? Function(E) f) {
    List<E>? newList;
    for (int index = 0; index < this.length; index++) {
      E element = this[index];
      E? newElement = f(element);
      if (newElement != null) {
        newList ??= this.toList(growable: false);
        newList[index] = newElement;
      }
    }
    return newList;
  }
}
