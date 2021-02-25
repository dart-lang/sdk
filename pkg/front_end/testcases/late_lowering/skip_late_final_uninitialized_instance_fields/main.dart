// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A declaration for each kind of late field/local lowering enabled by
// target bitmask.

main() {}

method() {
  late int? nullableUninitializedNonFinalLocal;
  late int nonNullableUninitializedNonFinalLocal;
  late final int? nullableUninitializedFinalLocal;
  late final int nonNullableUninitializedFinalLocal;
  late int? nullableInitializedNonFinalLocal = 0;
  late int nonNullableInitializedNonFinalLocal = 0;
  late final int? nullableInitializedFinalLocal = 0;
  late final int nonNullableInitializedFinalLocal = 0;
}

late int uninitializedNonFinalTopLevelField;
late final int uninitializedFinalTopLevelField;
late int initializedNonFinalTopLevelField = 0;
late final int initializedFinalTopLevelField = 0;

class Class {
  static late int uninitializedNonFinalStaticField;
  static late final int uninitializedFinalStaticField;
  static late int initializedNonFinalStaticField = 0;
  static late final int initializedFinalStaticField = 0;

  late int uninitializedNonFinalInstanceField;
  late final int uninitializedFinalInstanceField;
  late int initializedNonFinalInstanceField = 0;
  late final int initializedFinalInstanceField = 0;
}
