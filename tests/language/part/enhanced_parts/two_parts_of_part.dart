// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'two_parts_of_error_test.dart';
part of 'two_parts_of_other_lib.dart';
// [error column 1]
// [analyzer] unspecified
// [cfe] Only one part-of directive may be declared in a file.

int x = 42;
