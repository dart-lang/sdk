// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test verifies that `is` and `==` tests performed on `this` do not lead
/// to code being considered unreachable.  (In principle, we could soundly mark
/// some such code as unreachable, but we have decided not to do so at this
/// time).

import '../../static_type_helper.dart';

class C {
  void equalitySimple(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Null) {
      if (this == null) {
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

  void isSimple(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Null) {
      if (this is Never) {
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

class D {}

extension on D {
  void equalitySimple(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Null) {
      if (this == null) {
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

  void isSimple(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Null) {
      if (this is Never) {
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

class E {}

extension on E? {
  void equalitySimple(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this == null) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void equalityWithBogusPromotion(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Null) {
      if (this == null) {
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

  void isSimple(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Never) {
      x = null;
    } else {
      y = null;
    }
    // Since the assignments to x and y were both reachable, they should have
    // static type `int?` now.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void isWithBogusPromotion(int? x, int? y) {
    if (x == null || y == null) return;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this is Null) {
      if (this is Never) {
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
  C().equalitySimple(1, 1);
  C().equalityWithBogusPromotion(1, 1);
  C().isSimple(1, 1);
  C().isWithBogusPromotion(1, 1);
  D().equalitySimple(1, 1);
  D().equalityWithBogusPromotion(1, 1);
  D().isSimple(1, 1);
  D().isWithBogusPromotion(1, 1);
  E().equalitySimple(1, 1);
  E().equalityWithBogusPromotion(1, 1);
  E().isSimple(1, 1);
  E().isWithBogusPromotion(1, 1);
  (null as E?).equalitySimple(1, 1);
  (null as E?).equalityWithBogusPromotion(1, 1);
  (null as E?).isSimple(1, 1);
  (null as E?).isWithBogusPromotion(1, 1);
}
