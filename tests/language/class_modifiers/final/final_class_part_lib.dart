// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library declarations used by final_class_part_test.dart.

part of 'final_class_part_test.dart';

final class A extends FinalClass {}

final class B implements FinalClass {
  int foo = 1;
}
