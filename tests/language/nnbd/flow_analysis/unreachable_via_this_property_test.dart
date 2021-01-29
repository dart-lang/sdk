// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test verifies that `is` and `==` tests performed on a property get of
/// `this` do not lead to code being considered unreachable.  (In principle, we
/// could soundly mark some such code as unreachable, but we have decided not to
/// do so at this time).
///
/// Exception: when the static type of the property access is guaranteed to be
/// Null, and we are performing an `== null` test, then we do mark the non-null
/// branch as unreachable.

import '../../static_type_helper.dart';

class B {
  Null get nullProperty => null;
  Object? get objectQProperty => null;
}

class C extends B {
  void equalitySimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (nullProperty == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalitySimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.nullProperty == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalityWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (objectQProperty is Null) {
      if (objectQProperty == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.objectQProperty is Null) {
      if (this.objectQProperty == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (nullProperty is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.nullProperty is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (objectQProperty is Null) {
      if (objectQProperty is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.objectQProperty is Null) {
      if (this.objectQProperty is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }
}

class D extends B {}

extension on D {
  void equalitySimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (nullProperty == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalitySimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.nullProperty == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalityWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (objectQProperty is Null) {
      if (objectQProperty == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.objectQProperty is Null) {
      if (this.objectQProperty == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (nullProperty is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.nullProperty is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (objectQProperty is Null) {
      if (objectQProperty is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this.objectQProperty is Null) {
      if (this.objectQProperty is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }
}

class _B {
  final Null _nullField = null;
  final Object? _objectQField = null;
}

class _C extends _B {
  void equalitySimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_nullField == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalitySimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._nullField == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalityWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_objectQField is Null) {
      if (_objectQField == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._objectQField is Null) {
      if (this._objectQField == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_nullField is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._nullField is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_objectQField is Null) {
      if (_objectQField is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._objectQField is Null) {
      if (this._objectQField is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }
}

class _D extends _B {}

extension on _D {
  void equalitySimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_nullField == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalitySimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._nullField == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignment to x was reachable, it should have static type
    // `int?` now.  But y should still have static type `int`.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void equalityWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_objectQField is Null) {
      if (_objectQField == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._objectQField is Null) {
      if (this._objectQField == null) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_nullField is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isSimple_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._nullField is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_implicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_objectQField is Null) {
      if (_objectQField is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion_explicitThis(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._objectQField is Null) {
      if (this._objectQField is Never) {
        x = null;
      } else {
        y = null;
      }
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }
}

main() {
  C().equalitySimple_implicitThis(1, 1);
  C().equalitySimple_explicitThis(1, 1);
  C().equalityWithBogusPromotion_implicitThis(1, 1);
  C().equalityWithBogusPromotion_explicitThis(1, 1);
  C().isSimple_implicitThis(1, 1);
  C().isSimple_explicitThis(1, 1);
  C().isWithBogusPromotion_implicitThis(1, 1);
  C().isWithBogusPromotion_explicitThis(1, 1);
  D().equalitySimple_implicitThis(1, 1);
  D().equalitySimple_explicitThis(1, 1);
  D().equalityWithBogusPromotion_implicitThis(1, 1);
  D().equalityWithBogusPromotion_explicitThis(1, 1);
  D().isSimple_implicitThis(1, 1);
  D().isSimple_explicitThis(1, 1);
  D().isWithBogusPromotion_implicitThis(1, 1);
  D().isWithBogusPromotion_explicitThis(1, 1);
  _C().equalitySimple_implicitThis(1, 1);
  _C().equalitySimple_explicitThis(1, 1);
  _C().equalityWithBogusPromotion_implicitThis(1, 1);
  _C().equalityWithBogusPromotion_explicitThis(1, 1);
  _C().isSimple_implicitThis(1, 1);
  _C().isSimple_explicitThis(1, 1);
  _C().isWithBogusPromotion_implicitThis(1, 1);
  _C().isWithBogusPromotion_explicitThis(1, 1);
  _D().equalitySimple_implicitThis(1, 1);
  _D().equalitySimple_explicitThis(1, 1);
  _D().equalityWithBogusPromotion_implicitThis(1, 1);
  _D().equalityWithBogusPromotion_explicitThis(1, 1);
  _D().isSimple_implicitThis(1, 1);
  _D().isSimple_explicitThis(1, 1);
  _D().isWithBogusPromotion_implicitThis(1, 1);
  _D().isWithBogusPromotion_explicitThis(1, 1);
}
