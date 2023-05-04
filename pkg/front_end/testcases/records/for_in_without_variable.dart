// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  left([(1,2), (3, 4)]);
}

List<A> left<A, B>(List<(A, B)> pairs) => [for (var (a, _) in pairs) a];
