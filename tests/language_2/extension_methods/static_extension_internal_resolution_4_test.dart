// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests resolution of identifiers inside of extension methods

// Test the non error cases for an extension MyExt with member names
// overlapping the global and instance scopes against:
//   - a class A with only its own members
//   - an extension ExtraExt which has members overlapping the global names,
//     the instance names from A, and the extension names from MyExt, as well as
//     its own names.

import "package:expect/expect.dart";

/////////////////////////////////////////////////////////////////////////
// Note: These imports may be deliberately unused.  They bring certain
// names into scope, in order to test that certain resolution choices are
// made even in the presence of other symbols.
/////////////////////////////////////////////////////////////////////////

// Do Not Delete.
// Bring global members into scope.
import "helpers/global_scope.dart";

// Do Not Delete.
// Bring a class A with instance members into scope.
import "helpers/class_no_shadow.dart";

// Do Not Delete.
// Bring an extension ExtraExt with symbols that overlap the global, instance,
// and extension names into scope.
import "helpers/extension_all.dart";

const bool extensionValue = true;

void checkExtensionValue(bool x) {
  Expect.equals(x, extensionValue);
}

// An extension which defines its own members
extension MyExt on A {
  bool get fieldInGlobalScope => extensionValue;
  bool get getterInGlobalScope => extensionValue;
  set setterInGlobalScope(bool x) {
    checkExtensionValue(x);
  }

  bool methodInGlobalScope() => extensionValue;

  bool get fieldInInstanceScope => extensionValue;
  bool get getterInInstanceScope => extensionValue;
  set setterInInstanceScope(bool x) {
    checkExtensionValue(x);
  }

  bool methodInInstanceScope() => extensionValue;

  bool get fieldInExtensionScope => extensionValue;
  bool get getterInExtensionScope => extensionValue;
  set setterInExtensionScope(bool x) {
    checkExtensionValue(x);
  }

  bool methodInExtensionScope() => extensionValue;

  void testNakedIdentifiers() {
    // Globals should resolve to local extension versions
    {
      bool t0 = fieldInGlobalScope;
      checkExtensionValue(t0);
      bool t1 = getterInGlobalScope;
      checkExtensionValue(t1);
      setterInGlobalScope = extensionValue;
      bool t2 = methodInGlobalScope();
      checkExtensionValue(t2);
    }

    // Un-prefixed instance members resolve to the local extension versions
    {
      bool t0 = fieldInInstanceScope;
      checkExtensionValue(t0);
      bool t1 = getterInInstanceScope;
      checkExtensionValue(t0);
      setterInInstanceScope = extensionValue;
      bool t2 = methodInInstanceScope();
      checkExtensionValue(t0);
    }

    // Extension members resolve to the extension methods in this extension
    {
      bool t0 = fieldInExtensionScope;
      checkExtensionValue(t0);
      bool t1 = getterInExtensionScope;
      checkExtensionValue(t1);
      setterInExtensionScope = extensionValue;
      bool t2 = methodInExtensionScope();
      checkExtensionValue(t2);
    }

    // Extension members not on this extension resolve to the extension methods
    // in the other extension (unresolved identifier "id" gets turned into
    // "this.id", which is then subject to extension method lookup).
    {
      double t0 = fieldInOtherExtensionScope;
      checkOtherExtensionValue(t0);
      double t1 = getterInOtherExtensionScope;
      checkOtherExtensionValue(t1);
      setterInOtherExtensionScope = otherExtensionValue;
      double t2 = methodInOtherExtensionScope();
      checkOtherExtensionValue(t2);
    }
  }

  void testIdentifiersOnThis() {
    // Prefixed globals are ambiguous
    {
      // Error cases tested in static_extension_internal_resolution_4_error_test.dart
    }

    // Instance members resolve to the instance methods and not the members
    // of either extension
    {
      String t0 = this.fieldInInstanceScope;
      checkInstanceValue(t0);
      String t1 = this.getterInInstanceScope;
      checkInstanceValue(t0);
      this.setterInInstanceScope = instanceValue;
      String t2 = this.methodInInstanceScope();
      checkInstanceValue(t0);
    }

    // Extension members are ambigious.
    {
      // Error cases tested in static_extension_internal_resolution_4_error_test.dart
    }

    // Extension members not on this extension resolve to the extension methods
    // in the other extension.
    {
      double t0 = this.fieldInOtherExtensionScope;
      checkOtherExtensionValue(t0);
      double t1 = this.getterInOtherExtensionScope;
      checkOtherExtensionValue(t1);
      this.setterInOtherExtensionScope = otherExtensionValue;
      double t2 = this.methodInOtherExtensionScope();
      checkOtherExtensionValue(t2);
    }
  }

  void testIdentifiersOnInstance() {
    A self = this;

    // Prefixed globals are ambiguous
    {
      // Error cases tested in static_extension_internal_resolution_4_error_test.dart
    }

    // Instance members resolve to the instance methods and not the members
    // of the extension
    {
      String t0 = self.fieldInInstanceScope;
      checkInstanceValue(t0);
      String t1 = self.getterInInstanceScope;
      checkInstanceValue(t0);
      self.setterInInstanceScope = instanceValue;
      String t2 = self.methodInInstanceScope();
      checkInstanceValue(t0);
    }

    // Extension members are ambigious.
    {
      // Error cases tested in static_extension_internal_resolution_4_error_test.dart
    }

    // Extension members not on this extension resolve to the extension methods
    // in the other extension.
    {
      double t0 = self.fieldInOtherExtensionScope;
      checkOtherExtensionValue(t0);
      double t1 = self.getterInOtherExtensionScope;
      checkOtherExtensionValue(t1);
      self.setterInOtherExtensionScope = otherExtensionValue;
      double t2 = self.methodInOtherExtensionScope();
      checkOtherExtensionValue(t2);
    }
  }

  void instanceTest() {
    MyExt(this).testNakedIdentifiers();
    MyExt(this).testIdentifiersOnThis();
    MyExt(this).testIdentifiersOnInstance();
  }
}

class B extends A {
  void testNakedIdentifiers() {
    // Globals should resolve to the global name space, and not to the members
    // of either extension
    {
      int t0 = fieldInGlobalScope;
      checkGlobalValue(t0);
      int t1 = getterInGlobalScope;
      checkGlobalValue(t1);
      setterInGlobalScope = globalValue;
      int t2 = methodInGlobalScope();
      checkGlobalValue(t2);
    }

    // Instance members resolve to the instance methods and not the members
    // of the other extension (when present)
    {
      String t0 = fieldInInstanceScope;
      checkInstanceValue(t0);
      String t1 = getterInInstanceScope;
      checkInstanceValue(t0);
      setterInInstanceScope = instanceValue;
      String t2 = methodInInstanceScope();
      checkInstanceValue(t0);
    }

    // Extension members are ambigious.
    {
      // Error cases tested in static_extension_internal_resolution_4_error_test.dart
    }

    // Extension members resolve to the extension methods in the other
    // extension (unresolved identifier "id" gets turned into "this.id",
    // which is then subject to extension method lookup).
    {
      double t0 = fieldInOtherExtensionScope;
      checkOtherExtensionValue(t0);
      double t1 = getterInOtherExtensionScope;
      checkOtherExtensionValue(t1);
      setterInOtherExtensionScope = otherExtensionValue;
      double t2 = methodInOtherExtensionScope();
      checkOtherExtensionValue(t2);
    }
  }
}

void main() {
  var a = new A();
  a.instanceTest();
  new B().testNakedIdentifiers();

  // Check external resolution as well while we're here

  // Global names come from both extensions and hence are ambiguous.
  {
    // Error cases tested in static_extension_internal_resolution_4_error_test.dart
  }

  // Instance members resolve to the instance methods and not the members
  // of the other extension (when present)
  {
    String t0 = a.fieldInInstanceScope;
    checkInstanceValue(t0);
    String t1 = a.getterInInstanceScope;
    checkInstanceValue(t1);
    a.setterInInstanceScope = instanceValue;
    String t2 = a.methodInInstanceScope();
    checkInstanceValue(t2);
  }

  // Extension members are ambigious.
  {
    // Error cases tested in static_extension_internal_resolution_4_error_test.dart
  }

  // Extension members resolve to the extension methods in the other
  // extension.
  {
    double t0 = a.fieldInOtherExtensionScope;
    checkOtherExtensionValue(t0);
    double t1 = a.getterInOtherExtensionScope;
    checkOtherExtensionValue(t1);
    a.setterInOtherExtensionScope = otherExtensionValue;
    double t2 = a.methodInOtherExtensionScope();
    checkOtherExtensionValue(t2);
  }
}
