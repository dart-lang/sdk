// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void _mergeSort<T>(
    T Function(T) list, int compare(T a, T b), T Function(T) target) {
  /*@ typeArgs=_mergeSort::T* */ _mergeSort(list, compare, target);
  /*@ typeArgs=_mergeSort::T* */ _mergeSort(list, compare, list);
  /*@ typeArgs=_mergeSort::T* */ _mergeSort(target, compare, target);
  /*@ typeArgs=_mergeSort::T* */ _mergeSort(target, compare, list);
}

main() {}
