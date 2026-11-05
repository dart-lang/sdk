// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'unordered_method_part1.dart';
part 'unordered_method_part2.dart';

const annotation1 = 1;
const annotation2 = 2;

void topLevelMethod1() {
  print("topLevelMethod1");
}

@annotation1
void topLevelMethod2();

@annotation1
void topLevelMethod3();

abstract class Class {
  void instanceMethod1() {
    print("instanceMethod1");
  }

  @annotation1
  void instanceMethod2();

  @annotation1
  void instanceMethod3();

  void instanceMethod4();

  static void staticMethod1() {
    print("staticMethod1");
  }

  @annotation1
  static void staticMethod2();

  @annotation1
  static void staticMethod3();
}
