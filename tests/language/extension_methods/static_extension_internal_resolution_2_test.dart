// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests resolution of identifiers inside of extension methods

// Test an extension MyExt with members whose names overlap with names from the
// global, and instance scopes:
//   - a class A with only its own members
//   - an extension ExtraExt which has only its own members

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
// Bring an extension ExtraExt with no overlapping symbols into scope.
import "helpers/extension_only.dart";

const bool extensionValue = true;

void checkExtensionValue(bool x) {
  Expect.equals(x, extensionValue);
}

// An extension which defines all members
extension MyExt on A {
  bool get fieldInGlobalScope => true;
  bool get getterInGlobalScope => true;
  set setterInGlobalScope(bool x) {
    Expect.equals(true, x);
  }

  bool methodInGlobalScope() => true;

  bool get fieldInInstanceScope => true;
  bool get getterInInstanceScope => true;
  set setterInInstanceScope(bool x) {
    Expect.equals(true, x);
  }

  bool methodInInstanceScope() => true;

  bool get fieldInExtensionScope => true;
  bool get getterInExtensionScope => true;
  set setterInExtensionScope(bool x) {
    Expect.equals(true, x);
  }

  bool methodInExtensionScope() => true;

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
    // Globals should resolve to local extension versions
    {
      bool t0 = this.fieldInGlobalScope;
      checkExtensionValue(t0);
      bool t1 = this.getterInGlobalScope;
      checkExtensionValue(t1);
      this.setterInGlobalScope = extensionValue;
      bool t2 = this.methodInGlobalScope();
      checkExtensionValue(t2);
    }

    // Instance members resolve to the instance methods and not the members
    // of the extension
    {
      String t0 = this.fieldInInstanceScope;
      checkInstanceValue(t0);
      String t1 = this.getterInInstanceScope;
      checkInstanceValue(t0);
      this.setterInInstanceScope = instanceValue;
      String t2 = this.methodInInstanceScope();
      checkInstanceValue(t0);
    }

    // Extension members resolve to the extension methods on this extension
    {
      bool t0 = this.fieldInExtensionScope;
      checkExtensionValue(t0);
      bool t1 = this.getterInExtensionScope;
      checkExtensionValue(t1);
      this.setterInExtensionScope = extensionValue;
      bool t2 = this.methodInExtensionScope();
      checkExtensionValue(t2);
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

    // Globals should resolve to local extension versions
    {
      bool t0 = self.fieldInGlobalScope;
      checkExtensionValue(t0);
      bool t1 = self.getterInGlobalScope;
      checkExtensionValue(t1);
      self.setterInGlobalScope = extensionValue;
      bool t2 = self.methodInGlobalScope();
      checkExtensionValue(t2);
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

    // Extension members resolve to the extension methods on this extension
    {
      bool t0 = self.fieldInExtensionScope;
      checkExtensionValue(t0);
      bool t1 = self.getterInExtensionScope;
      checkExtensionValue(t1);
      self.setterInExtensionScope = extensionValue;
      bool t2 = self.methodInExtensionScope();
      checkExtensionValue(t2);
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
    // of the other extension (when present)
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

    // Extension members defined only in this extension resolve correctly.
    {
      bool t0 = fieldInExtensionScope;
      checkExtensionValue(t0);
      bool t1 = getterInExtensionScope;
      checkExtensionValue(t1);
      setterInExtensionScope = extensionValue;
      bool t2 = methodInExtensionScope();
      checkExtensionValue(t2);
    }

    // Extension members defined in the external extension resolve correctly
    // (an unresolved identifier "id" gets turned into "this.id",
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

  // Global symbols on an instance resolve to the version on this
  // extension
  {
    bool t0 = a.fieldInGlobalScope;
    checkExtensionValue(t0);
    bool t1 = a.getterInGlobalScope;
    checkExtensionValue(t1);
    a.setterInGlobalScope = extensionValue;
    bool t2 = a.methodInGlobalScope();
    checkExtensionValue(t2);
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

  // Extension members resolve to the extension methods in this
  // extension.
  {
    bool t0 = a.fieldInExtensionScope;
    checkExtensionValue(t0);
    bool t1 = a.getterInExtensionScope;
    checkExtensionValue(t1);
    a.setterInExtensionScope = extensionValue;
    bool t2 = a.methodInExtensionScope();
    checkExtensionValue(t2);
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
