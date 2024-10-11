// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion distinguishes `this` accesses from `super`
// accesses when they resolve to different fields.

// In this test, the fields in question have generic types. This is an important
// special case to test because the analyzer uses special "Member" data
// structures to track accesses to fields with generic types.

// Since the analyzer has different logic for resolving ordinary variable gets
// and variable gets that look like member invocations, both scenarios are
// tested.

import 'package:expect/static_type_helper.dart';

class Base<T extends Object> {
  final T? _t;
  final T? Function() _f;
  Base(this._t, this._f);
}

/// In this class, `_t` and `_f` override the declarations of `_t` and `_f` in
/// `super`, so their promotions should be tracked separately.
class DerivedClassThatOverridesBaseMembers<T extends Object> extends Base<T> {
  final T? _t;
  final T? Function() _f;
  DerivedClassThatOverridesBaseMembers(
      this._t, this._f, T? superI, T? Function() superF)
      : super(superI, superF);

  void ordinaryVariableGet() {
    _t.expectStaticType<Exactly<T?>>();
    this._t.expectStaticType<Exactly<T?>>();
    super._t.expectStaticType<Exactly<T?>>();
    if (_t != null) {
      _t.expectStaticType<Exactly<T>>();
      this._t.expectStaticType<Exactly<T>>();
      super._t.expectStaticType<Exactly<T?>>();
    }
    if (this._t != null) {
      _t.expectStaticType<Exactly<T>>();
      this._t.expectStaticType<Exactly<T>>();
      super._t.expectStaticType<Exactly<T?>>();
    }
    if (super._t != null) {
      _t.expectStaticType<Exactly<T?>>();
      this._t.expectStaticType<Exactly<T?>>();
      super._t.expectStaticType<Exactly<T>>();
    }
  }

  void invokedVariableGet() {
    _f().expectStaticType<Exactly<T?>>();
    this._f().expectStaticType<Exactly<T?>>();
    super._f().expectStaticType<Exactly<T?>>();
    if (_f is T Function()) {
      _f().expectStaticType<Exactly<T>>();
      this._f().expectStaticType<Exactly<T>>();
      super._f().expectStaticType<Exactly<T?>>();
    }
    if (this._f is T Function()) {
      _f().expectStaticType<Exactly<T>>();
      this._f().expectStaticType<Exactly<T>>();
      super._f().expectStaticType<Exactly<T?>>();
    }
    if (super._f is T Function()) {
      _f().expectStaticType<Exactly<T?>>();
      this._f().expectStaticType<Exactly<T?>>();
      super._f().expectStaticType<Exactly<T>>();
    }
  }
}

/// In this class, `_i` and `_f` refer to the declarations of `_i` and `_f` in
/// `super`. However, accesses made through `this` still promote independently
/// from accesses made through `super`, since this is simpler to implement, has
/// no soundness problems, and is unlikely to cause problems in real-world code.
class DerivedClassThatOverridesNothing<T extends Object> extends Base<T> {
  DerivedClassThatOverridesNothing(super._t, super.f);

  void ordinaryVariableGet() {
    _t.expectStaticType<Exactly<T?>>();
    this._t.expectStaticType<Exactly<T?>>();
    super._t.expectStaticType<Exactly<T?>>();
    if (_t != null) {
      _t.expectStaticType<Exactly<T>>();
      this._t.expectStaticType<Exactly<T>>();
      super._t.expectStaticType<Exactly<T?>>();
    }
    if (this._t != null) {
      _t.expectStaticType<Exactly<T>>();
      this._t.expectStaticType<Exactly<T>>();
      super._t.expectStaticType<Exactly<T?>>();
    }
    if (super._t != null) {
      _t.expectStaticType<Exactly<T?>>();
      this._t.expectStaticType<Exactly<T?>>();
      super._t.expectStaticType<Exactly<T>>();
    }
  }

  void invokedVariableGet() {
    _f().expectStaticType<Exactly<T?>>();
    this._f().expectStaticType<Exactly<T?>>();
    super._f().expectStaticType<Exactly<T?>>();
    if (_f is T Function()) {
      _f().expectStaticType<Exactly<T>>();
      this._f().expectStaticType<Exactly<T>>();
      super._f().expectStaticType<Exactly<T?>>();
    }
    if (this._f is T Function()) {
      _f().expectStaticType<Exactly<T>>();
      this._f().expectStaticType<Exactly<T>>();
      super._f().expectStaticType<Exactly<T?>>();
    }
    if (super._f is T Function()) {
      _f().expectStaticType<Exactly<T?>>();
      this._f().expectStaticType<Exactly<T?>>();
      super._f().expectStaticType<Exactly<T>>();
    }
  }
}

main() {
  int f() => 0;
  int? g() => null;
  DerivedClassThatOverridesBaseMembers<int>(0, f, null, g)
    ..ordinaryVariableGet()
    ..invokedVariableGet();
  DerivedClassThatOverridesBaseMembers<int>(null, g, 0, f)
    ..ordinaryVariableGet()
    ..invokedVariableGet();
  DerivedClassThatOverridesNothing<int>(0, f)
    ..ordinaryVariableGet()
    ..invokedVariableGet();
}
