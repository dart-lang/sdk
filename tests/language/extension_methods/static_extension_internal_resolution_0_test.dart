// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests resolution of identifiers inside of extension methods

// Test an extension MyExt with no members against:
//   - a class A with only its own members
//   - and another extension ExtraExt with only its own members

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

// An extension which defines no members of its own
extension MyExt on A {
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

  void testIdentifiersOnThis() {
    // Instance members resolve to the instance methods and not the members
    // of the other extension (when present)
    {
      String t0 = this.fieldInInstanceScope;
      checkInstanceValue(t0);
      String t1 = this.getterInInstanceScope;
      checkInstanceValue(t0);
      this.setterInInstanceScope = instanceValue;
      String t2 = this.methodInInstanceScope();
      checkInstanceValue(t0);
    }

    // Extension members resolve to the extension methods in the other
    // extension.
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

    // Instance members resolve to the instance methods and not the members
    // of the other extension (when present)
    {
      String t0 = self.fieldInInstanceScope;
      checkInstanceValue(t0);
      String t1 = self.getterInInstanceScope;
      checkInstanceValue(t1);
      self.setterInInstanceScope = instanceValue;
      String t2 = self.methodInInstanceScope();
      checkInstanceValue(t2);
    }

    // Extension members resolve to the extension methods in the other
    // extension.
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
