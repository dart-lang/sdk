// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Lots of comment lines that pushes the length of this file beyond that of
// error_location_06. This in turn causes the (first) 'z' in 'x2' to get an
// offset that is larger than the largest valid offset in error_location_06.
// This in turn can cause a crash, if the fileUri for that z is the wrong file.

part of error_location_06;

x1(z, {z}) {}

x2() {
  y(z, {z}) {}
}
