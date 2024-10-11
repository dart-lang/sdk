// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion distinguishes `this` accesses from `super`
// accesses when they resolve to different fields.

// Since the analyzer has different logic for resolving ordinary variable gets
// and variable gets that look like member invocations, both scenarios are
// tested.

import 'package:expect/static_type_helper.dart';

class Base {
  final int? _i;
  final int? Function() _f;
  Base(this._i, this._f);
}

/// In this class, `_i` and `_f` override the declarations of `_i` and `_f` in
/// `super`, so their promotions should be tracked separately.
class DerivedClassThatOverridesBaseMembers extends Base {
  final int? _i;
  final int? Function() _f;
  DerivedClassThatOverridesBaseMembers(
      this._i, this._f, int? superI, int? Function() superF)
      : super(superI, superF);

  void ordinaryVariableGet() {
    _i.expectStaticType<Exactly<int?>>();
    this._i.expectStaticType<Exactly<int?>>();
    super._i.expectStaticType<Exactly<int?>>();
    if (_i != null) {
      _i.expectStaticType<Exactly<int>>();
      this._i.expectStaticType<Exactly<int>>();
      super._i.expectStaticType<Exactly<int?>>();
    }
    if (this._i != null) {
      _i.expectStaticType<Exactly<int>>();
      this._i.expectStaticType<Exactly<int>>();
      super._i.expectStaticType<Exactly<int?>>();
    }
    if (super._i != null) {
      _i.expectStaticType<Exactly<int?>>();
      this._i.expectStaticType<Exactly<int?>>();
      super._i.expectStaticType<Exactly<int>>();
    }
  }

  void invokedVariableGet() {
    _f().expectStaticType<Exactly<int?>>();
    this._f().expectStaticType<Exactly<int?>>();
    super._f().expectStaticType<Exactly<int?>>();
    if (_f is int Function()) {
      _f().expectStaticType<Exactly<int>>();
      this._f().expectStaticType<Exactly<int>>();
      super._f().expectStaticType<Exactly<int?>>();
    }
    if (this._f is int Function()) {
      _f().expectStaticType<Exactly<int>>();
      this._f().expectStaticType<Exactly<int>>();
      super._f().expectStaticType<Exactly<int?>>();
    }
    if (super._f is int Function()) {
      _f().expectStaticType<Exactly<int?>>();
      this._f().expectStaticType<Exactly<int?>>();
      super._f().expectStaticType<Exactly<int>>();
    }
  }
}

/// In this class, `_i` and `_f` refer to the declarations of `_i` and `_f` in
/// `super`. However, accesses made through `this` still promote independently
/// from accesses made through `super`, since this is simpler to implement, has
/// no soundness problems, and is unlikely to cause problems in real-world code.
class DerivedClassThatOverridesNothing extends Base {
  DerivedClassThatOverridesNothing(super._i, super.f);

  void ordinaryVariableGet() {
    _i.expectStaticType<Exactly<int?>>();
    this._i.expectStaticType<Exactly<int?>>();
    super._i.expectStaticType<Exactly<int?>>();
    if (_i != null) {
      _i.expectStaticType<Exactly<int>>();
      this._i.expectStaticType<Exactly<int>>();
      super._i.expectStaticType<Exactly<int?>>();
    }
    if (this._i != null) {
      _i.expectStaticType<Exactly<int>>();
      this._i.expectStaticType<Exactly<int>>();
      super._i.expectStaticType<Exactly<int?>>();
    }
    if (super._i != null) {
      _i.expectStaticType<Exactly<int?>>();
      this._i.expectStaticType<Exactly<int?>>();
      super._i.expectStaticType<Exactly<int>>();
    }
  }

  void invokedVariableGet() {
    _f().expectStaticType<Exactly<int?>>();
    this._f().expectStaticType<Exactly<int?>>();
    super._f().expectStaticType<Exactly<int?>>();
    if (_f is int Function()) {
      _f().expectStaticType<Exactly<int>>();
      this._f().expectStaticType<Exactly<int>>();
      super._f().expectStaticType<Exactly<int?>>();
    }
    if (this._f is int Function()) {
      _f().expectStaticType<Exactly<int>>();
      this._f().expectStaticType<Exactly<int>>();
      super._f().expectStaticType<Exactly<int?>>();
    }
    if (super._f is int Function()) {
      _f().expectStaticType<Exactly<int?>>();
      this._f().expectStaticType<Exactly<int?>>();
      super._f().expectStaticType<Exactly<int>>();
    }
  }
}

main() {
  int f() => 0;
  int? g() => null;
  DerivedClassThatOverridesBaseMembers(0, f, null, g)
    ..ordinaryVariableGet()
    ..invokedVariableGet();
  DerivedClassThatOverridesBaseMembers(null, g, 0, f)
    ..ordinaryVariableGet()
    ..invokedVariableGet();
  DerivedClassThatOverridesNothing(0, f)
    ..ordinaryVariableGet()
    ..invokedVariableGet();
}
