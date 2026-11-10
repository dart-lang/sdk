// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'unordered_method.dart';

@annotation1
augment void topLevelMethod1();

augment void topLevelMethod2() {
  print("topLevelMethod2");
}

@annotation2
augment void topLevelMethod3();

augment abstract class Class {
  @annotation1
  augment void instanceMethod1();

  augment void instanceMethod2() {
    print("instanceMethod2");
  }

  @annotation2
  augment void instanceMethod3();

  @annotation1
  augment void instanceMethod4();

  @annotation1
  augment static void staticMethod1();

  augment static void staticMethod2() {
    print("staticMethod2");
  }

  @annotation2
  augment static void staticMethod3();
}
