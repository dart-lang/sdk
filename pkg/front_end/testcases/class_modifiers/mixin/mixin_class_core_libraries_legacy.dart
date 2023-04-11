// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is not an error to mix in a non-mixin class post 3.0, assuming
// the class fills the requirements to be used as a mixin.

// @dart=2.19

class A with Comparable<int> {
  int compareTo(int x) => 0;
} /* Ok */

class B with Error {} /* Error */
