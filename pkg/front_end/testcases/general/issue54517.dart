// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int test0({required int a}) => a;

void main() {
  Function.apply(test0, [], {Symbol("a"): 17});
}
