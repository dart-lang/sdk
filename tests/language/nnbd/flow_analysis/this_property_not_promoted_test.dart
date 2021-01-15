// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test verifies that neither an `== null` nor an `is` test can promote the
// type of a property access on `this`.  (In principle, we could soundly promote
// some such accesses, but we have decided not to do so at this time).

class _C {
  final int? _f;

  _C(this._f);

  void equality_implicitThis() {
    if (_f == null) {
      _f.expectStaticType<Exactly<int?>>();
    } else {
      _f.expectStaticType<Exactly<int?>>();
    }
  }

  void equality_explicitThis() {
    if (this._f == null) {
      this._f.expectStaticType<Exactly<int?>>();
    } else {
      this._f.expectStaticType<Exactly<int?>>();
    }
  }

  void is_implicitThis() {
    if (_f is int) {
      _f.expectStaticType<Exactly<int?>>();
    } else {
      _f.expectStaticType<Exactly<int?>>();
    }
  }

  void is_explicitThis() {
    if (this._f is int) {
      this._f.expectStaticType<Exactly<int?>>();
    } else {
      this._f.expectStaticType<Exactly<int?>>();
    }
  }
}

class _D {
  final int? _f;

  _D(this._f);
}

extension on _D {
  void equality_implicitThis() {
    if (_f == null) {
      _f.expectStaticType<Exactly<int?>>();
    } else {
      _f.expectStaticType<Exactly<int?>>();
    }
  }

  void equality_explicitThis() {
    if (this._f == null) {
      this._f.expectStaticType<Exactly<int?>>();
    } else {
      this._f.expectStaticType<Exactly<int?>>();
    }
  }

  void is_implicitThis() {
    if (_f is int) {
      _f.expectStaticType<Exactly<int?>>();
    } else {
      _f.expectStaticType<Exactly<int?>>();
    }
  }

  void is_explicitThis() {
    if (this._f is int) {
      this._f.expectStaticType<Exactly<int?>>();
    } else {
      this._f.expectStaticType<Exactly<int?>>();
    }
  }
}

main() {
  _C(1).equality_implicitThis();
  _C(1).equality_explicitThis();
  _C(1).is_implicitThis();
  _C(1).is_explicitThis();
  _C(null).equality_implicitThis();
  _C(null).equality_explicitThis();
  _C(null).is_implicitThis();
  _C(null).is_explicitThis();
  _D(1).equality_implicitThis();
  _D(1).equality_explicitThis();
  _D(1).is_implicitThis();
  _D(1).is_explicitThis();
  _D(null).equality_implicitThis();
  _D(null).equality_explicitThis();
  _D(null).is_implicitThis();
  _D(null).is_explicitThis();
}
