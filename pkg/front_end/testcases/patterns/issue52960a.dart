// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

(int, int) firstAndLast(List<int> a) => (a.first, a.last);

main() {
  final (first, last) = firstAndLast([1, 2, 3]);
  print('first: $first, last: $last');
}
