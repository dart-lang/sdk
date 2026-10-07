// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'unordered_method.dart';

@annotation2
augment void topLevelMethod1();

@annotation2
augment void topLevelMethod2();

augment void topLevelMethod3() {
  print("topLevelMethod3");
}

augment abstract class Class {
  @annotation2
  augment void instanceMethod1();

  @annotation2
  augment void instanceMethod2();

  augment void instanceMethod3() {
    print("instanceMethod3");
  }

  @annotation2
  augment void instanceMethod4();

  @annotation2
  augment static void staticMethod1();

  @annotation2
  augment static void staticMethod2();

  augment static void staticMethod3() {
    print("staticMethod3");
  }
}
