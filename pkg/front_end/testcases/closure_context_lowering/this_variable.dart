// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A a = new A();
  A? aNull;
  int n = 0;
  Object? field;
  method() {}
  Object? call() => null;
  Object? operator[](int index) => null;
  void operator[]=(int index, Object? value) {}
  A operator+(A other) => this;
  A operator-() => this;

  notCapturedMethodCall() {
    method();
  }

  notCapturedExpression() {
    this;
  }

  notCapturedPropertyGet() {
    field;
  }

  notCapturedPropertySet() {
    field = null;
  }

  notCapturedCall() {
    this();
  }

  notCapturedIndexGet() {
    this[0];
  }

  notCapturedIndexSet() {
    this[0] = null;
  }

  notCapturedUnary() {
    -this;
  }

  notCapturedBinary() {
    this + this;
  }

  notCapturedPropertyCall() {
    a();
  }

  notCapturedPropertyPrefix() {
    ++n;
  }

  notCapturedPropertyPostfix() {
    n++;
  }

  notCapturedPropertyIndexGet() {
    a[0];
  }

  notCapturedPropertyIndexSet() {
    a[0] = null;
  }

  notCapturedPropertyIfNullAssignment() {
    aNull ??= new A();
  }

  notCapturedPropertyCompoundAssignment() {
    a += new A();
  }

  capturedMethodCall() {
    return () => method();
  }

  capturedExpression() {
    return () => this;
  }

  capturedPropertyGet() {
    return () => field;
  }

  capturedPropertySet() {
    return () { field = null; };
  }

  capturedCall() {
    return () => this();
  }

  capturedIndexGet() {
    return () => this[0];
  }

  capturedIndexSet() {
    return () { this[0] = null; };
  }

  capturedUnary() {
    return () => -this;
  }

  capturedBinary() {
    return () => this + this;
  }

  capturedPropertyCall() {
    return () => a();
  }

  capturedPropertyPrefix() {
    return () => ++n;
  }

  capturedPropertyPostfix() {
    return () => n++;
  }

  capturedPropertyIndexGet() {
    return () => a[0];
  }

  capturedPropertyIndexSet() {
    return () => (a[0] = null);
  }

  capturedPropertyIfNullAssignment() {
    return () => (aNull ??= new A());
  }

  capturedPropertyCompoundAssignment() {
    return () => (a += new A());
  }
}

class B extends A {
  @override
  notCapturedMethodCall() {
    super.method();
  }

  @override
  notCapturedPropertyGet() {
    super.field;
  }

  @override
  notCapturedPropertySet() {
    super.field = null;
  }

  @override
  notCapturedCall() {
    super();
  }

  @override
  notCapturedIndexGet() {
    super[0];
  }

  @override
  notCapturedIndexSet() {
    super[0] = null;
  }

  @override
  notCapturedUnary() {
    -super;
  }

  @override
  notCapturedBinary() {
    super + this;
  }

  @override
  notCapturedPropertyCall() {
    super.a();
  }

  @override
  notCapturedPropertyPrefix() {
    ++super.n;
  }

  @override
  notCapturedPropertyPostfix() {
    super.n++;
  }

  @override
  notCapturedPropertyIndexGet() {
    super.a[0];
  }

  @override
  notCapturedPropertyIndexSet() {
    super.a[0] = null;
  }

  @override
  notCapturedPropertyIfNullAssignment() {
    super.aNull ??= new A();
  }

  @override
  notCapturedPropertyCompoundAssignment() {
    super.a += new A();
  }

  @override
  capturedMethodCall() {
    return () => super.method();
  }

  @override
  capturedPropertyGet() {
    return () => super.field;
  }

  @override
  capturedPropertySet() {
    return () { super.field = null; };
  }

  @override
  capturedCall() {
    return () => super();
  }

  @override
  capturedIndexGet() {
    return () => super[0];
  }

  @override
  capturedIndexSet() {
    return () { super[0] = null; };
  }

  @override
  capturedUnary() {
    return () => -super;
  }

  @override
  capturedBinary() {
    return () => super + this;
  }

  @override
  capturedPropertyCall() {
    return () => super.a();
  }

  @override
  capturedPropertyPrefix() {
    return () => ++super.n;
  }

  @override
  capturedPropertyPostfix() {
    return () => super.n++;
  }

  @override
  capturedPropertyIndexGet() {
    return () => super.a[0];
  }

  @override
  capturedPropertyIndexSet() {
    return () => (super.a[0] = null);
  }

  @override
  capturedPropertyIfNullAssignment() {
    return () => (super.aNull ??= new A());
  }

  @override
  capturedPropertyCompoundAssignment() {
    return () => (super.a += new A());
  }
}
