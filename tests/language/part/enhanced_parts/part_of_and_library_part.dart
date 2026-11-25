// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'part_of_and_library_error_test.dart';

library not_a_library;
// [error column 1]
// [analyzer] unspecified
// [cfe] A part cannot have a library directive.

int x = 42;
