// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int nonNullableTopLevelFieldReads = 0;

late final int nonNullableTopLevelField =
    nonNullableTopLevelFieldReads++ == 0 ? nonNullableTopLevelField + 1 : 0;

int nullableTopLevelFieldReads = 0;

late final int? nullableTopLevelField =
    nullableTopLevelFieldReads++ == 0 ? nullableTopLevelField.hashCode : 0;

class Class {
  static int nonNullableStaticFieldReads = 0;

  static late final int nonNullableStaticField =
      nonNullableStaticFieldReads++ == 0 ? nonNullableStaticField + 1 : 0;

  static int nullableStaticFieldReads = 0;

  static late final int? nullableStaticField =
      nullableStaticFieldReads++ == 0 ? nullableStaticField.hashCode : 0;

  int nonNullableInstanceFieldReads = 0;

  late final int nonNullableInstanceField =
      nonNullableInstanceFieldReads++ == 0 ? nonNullableInstanceField + 1 : 0;

  int nullableInstanceFieldReads = 0;

  late final int? nullableInstanceField =
      nullableInstanceFieldReads++ == 0 ? nullableInstanceField.hashCode : 0;
}

void main() {
  throws(() => nonNullableTopLevelField, "Read nonNullableTopLevelField");
  throws(() => nullableTopLevelField, "Read nullableTopLevelField");
  throws(() => Class.nonNullableStaticField, "Read nonNullableStaticField");
  throws(() => Class.nullableStaticField, "Read nullableStaticField");
  throws(() => new Class().nonNullableInstanceField,
      "Read nonNullableInstanceField");
  throws(() => new Class().nullableInstanceField, "Read nullableInstanceField");
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } on LateInitializationError catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
