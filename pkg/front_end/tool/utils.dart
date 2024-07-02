// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns the index in the [list] at which [find] is or should have been.
///
/// [list] has to be sorted.
/// If there are several elements matching what we're looking for it can return
/// the index to of an arbitrary one of them.
/// If there is no match the element at the index will be smaller than the data
/// searched for.
/// If the input list is empty it will return 0 which is not a valid entry.
int binarySearch(List<int> list, int find) {
  int low = 0, high = list.length - 1;
  while (low < high) {
    int mid = high - ((high - low) >> 1); // Get middle, rounding up.
    int pivot = list[mid];
    if (pivot <= find) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  return low;
}
