// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=extension-methods

// Tests resolution of identifiers inside of extension methods

// Test various static error corner cases around internal resolution.

import "package:expect/expect.dart";

// Bring global members into scope
import "helpers/global_scope.dart";

// Bring a class AGlobal with instance members and global members into scope
import "helpers/class_shadow.dart";

extension GenericExtension<T> on T {
  T get self => this;
  // Check that capture is avoided when expanding out
  // self references.
  void shadowTypeParam<T>(T x) {
    T y = self;
    //    ^^^^
    // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
    //     ^^^
    // [cfe] unspecified
  }
  void castToShadowedTypeParam<T>() {
    dynamic s = self;
    (s as T);
  }

  List<T> mkList() => <T>[];
  void castToShadowedTypeList<T>() {
    (mkList() as List<T>);
  }
}


const bool extensionValue = true;

void checkExtensionValue(bool x) {
  Expect.equals(x, extensionValue);
}

extension StaticExt on AGlobal {
  // Valid to overlap static names with the target type symbols
  static bool get fieldInInstanceScope => extensionValue;
  static bool get getterInInstanceScope => extensionValue;
  static set setterInInstanceScope(bool x) {
    checkExtensionValue(x);
  }
  static bool methodInInstanceScope() => extensionValue;

  // Add the global symbols
  static bool get fieldInGlobalScope => extensionValue;
  static bool get getterInGlobalScope => extensionValue;
  static set setterInGlobalScope(bool x) {
    checkExtensionValue(x);
  }
  static bool methodInGlobalScope() => extensionValue;

  // Invalid to overlap the static and extension scopes
  bool get fieldInInstanceScope => extensionValue;
  //       ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
  bool get getterInInstanceScope => extensionValue;
  //       ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
  set setterInInstanceScope(bool x) {
  //  ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
    checkExtensionValue(x);
  }
  bool methodInInstanceScope() => extensionValue;
  //   ^^^
  // [analyzer] unspecified
  // [cfe] unspecified


  void testNakedIdentifiers() {
    // Symbols in the global scope and the local static scope resolve to
    // the local static scope.
    {
      // No errors: see static_extension_internal_resolution_6_test.dart
    }

    // Symbols in the global scope, the instance scope, and the local static scope
    // resolve to the local static scope.
    {
      // No errors: see static_extension_internal_resolution_6_test.dart
    }
  }
  void instanceTest() {
    StaticExt(this).testNakedIdentifiers();
  }
}

void main() {
  var a = new AGlobal();
  a.instanceTest();

  Expect.throwsCastError(() => 3.castToShadowedTypeParam<String>());
  Expect.throwsCastError(() => 3.castToShadowedTypeList<String>());
}