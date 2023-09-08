// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles late fields.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C {
  final int? _i;
  late final int? _finalWithInitializer = _i;
  late final int? _finalWithoutInitializer;
  late int? _nonFinalWithInitializer = _i;
  late int? _nonFinalWithoutInitializer;
  C(this._i) {
    _finalWithoutInitializer = _i;
    _nonFinalWithoutInitializer = _i;
  }

  void testImplicitThisAccess() {
    // Late final fields are promotable
    if (_finalWithInitializer != null) {
      _finalWithInitializer.expectStaticType<Exactly<int>>();
    }
    if (_finalWithoutInitializer != null) {
      _finalWithoutInitializer.expectStaticType<Exactly<int>>();
    }
    // Late non-final fields are not promotable
    if (_nonFinalWithInitializer != null) {
      _nonFinalWithInitializer.expectStaticType<Exactly<int?>>();
    }
    if (_nonFinalWithoutInitializer != null) {
      _nonFinalWithoutInitializer.expectStaticType<Exactly<int?>>();
    }
  }

  void testExplicitThisAccess() {
    // Late final fields are promotable
    if (this._finalWithInitializer != null) {
      this._finalWithInitializer.expectStaticType<Exactly<int>>();
    }
    if (this._finalWithoutInitializer != null) {
      this._finalWithoutInitializer.expectStaticType<Exactly<int>>();
    }
    // Late non-final fields are not promotable
    if (this._nonFinalWithInitializer != null) {
      this._nonFinalWithInitializer.expectStaticType<Exactly<int?>>();
    }
    if (this._nonFinalWithoutInitializer != null) {
      this._nonFinalWithoutInitializer.expectStaticType<Exactly<int?>>();
    }
  }
}

void testOrdinaryPropertyAccess(C c) {
  // Late final fields are promotable
  if (c._finalWithInitializer != null) {
    c._finalWithInitializer.expectStaticType<Exactly<int>>();
  }
  if (c._finalWithoutInitializer != null) {
    c._finalWithoutInitializer.expectStaticType<Exactly<int>>();
  }
  // Late non-final fields are not promotable
  if (c._nonFinalWithInitializer != null) {
    c._nonFinalWithInitializer.expectStaticType<Exactly<int?>>();
  }
  if (c._nonFinalWithoutInitializer != null) {
    c._nonFinalWithoutInitializer.expectStaticType<Exactly<int?>>();
  }
}

class D {
  final int? _finalWithInitializer;
  final int? _finalWithoutInitializer;
  final int? _nonFinalWithInitializer;
  final int? _nonFinalWithoutInitializer;
  D(int? i)
      : _finalWithInitializer = i,
        _finalWithoutInitializer = i,
        _nonFinalWithInitializer = i,
        _nonFinalWithoutInitializer = i;

  void testInterference() {
    // Late final fields do not interfere with other fields having the same name
    if (_finalWithInitializer != null) {
      _finalWithInitializer.expectStaticType<Exactly<int>>();
    }
    if (_finalWithoutInitializer != null) {
      _finalWithoutInitializer.expectStaticType<Exactly<int>>();
    }
    // Late non-final fields *do* interfere with other fields having the same
    // name
    if (_nonFinalWithInitializer != null) {
      _nonFinalWithInitializer.expectStaticType<Exactly<int?>>();
    }
    if (_nonFinalWithoutInitializer != null) {
      _nonFinalWithoutInitializer.expectStaticType<Exactly<int?>>();
    }
  }
}

main() {
  for (int? i in [0, null]) {
    C(i).testImplicitThisAccess();
    C(i).testExplicitThisAccess();
    testOrdinaryPropertyAccess(C(i));
    D(i).testInterference();
  }
}
