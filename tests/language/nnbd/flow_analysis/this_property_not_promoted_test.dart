// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Disable `inference-update-2` (field promotion) feature.
// @dart=3.0

import '../../static_type_helper.dart';

// Verify that neither an `== null` nor an `is` test promotes the type of a
// property access on `this` when the field-promotion feature is not enabled.

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

  void notEquals_implicitThis() {
    if (_f != null) {
      _f.expectStaticType<Exactly<int?>>();
    } else {
      _f.expectStaticType<Exactly<int?>>();
    }
  }

  void notEquals_explicitThis() {
    if (this._f != null) {
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

  void notEquals_implicitThis() {
    if (_f != null) {
      _f.expectStaticType<Exactly<int?>>();
    } else {
      _f.expectStaticType<Exactly<int?>>();
    }
  }

  void notEquals_explicitThis() {
    if (this._f != null) {
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
  _C(1).notEquals_implicitThis();
  _C(1).notEquals_explicitThis();
  _C(1).is_implicitThis();
  _C(1).is_explicitThis();
  _C(null).equality_implicitThis();
  _C(null).equality_explicitThis();
  _C(null).notEquals_implicitThis();
  _C(null).notEquals_explicitThis();
  _C(null).is_implicitThis();
  _C(null).is_explicitThis();
  _D(1).equality_implicitThis();
  _D(1).equality_explicitThis();
  _D(1).notEquals_implicitThis();
  _D(1).notEquals_explicitThis();
  _D(1).is_implicitThis();
  _D(1).is_explicitThis();
  _D(null).equality_implicitThis();
  _D(null).equality_explicitThis();
  _D(null).notEquals_implicitThis();
  _D(null).notEquals_explicitThis();
  _D(null).is_implicitThis();
  _D(null).is_explicitThis();
}
