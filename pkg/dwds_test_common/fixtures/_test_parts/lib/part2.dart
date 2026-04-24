// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'library.dart';

// Padding....
//
//
// 'return' below is at line that doesn't exist in the previous files,
// but still at offset 410.
//

String concatenate3(String a, double b) {
  return '$a$b'; // Breakpoint: Concatenate3
}
