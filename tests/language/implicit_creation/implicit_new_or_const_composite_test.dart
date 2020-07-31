// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests that new-insertion always inserts `new` when not in const context,
// no matter what the arguments are.
// There is (currently) no automatic const insertion in non-const context.
//
// Not testing inference, so all type arguments are explicit.

main() {
  var x = 42;
  const cc42 = const C(42);
  var c42 = cc42;

  const clist = const <int>[37];
  var list = clist;
  const cmap = const <int, int>{19: 87};
  var map = cmap;

  {
    // Constructor inside constructor.
    var d42 = const D<int>(42);

    const cd1 = const C(const D<int>(42));
    const cd2 = C(D<int>(42)); // Const context.
    var cd3 = C(D<int>(42)); // Non-constant context, so `new`.
    var cd4 = C(D<int>(x)); // Non-constant context, so `new`.
    var cd5 = C(d42); // Non-constant context, so `new`.

    Expect.identical(cd1, cd2);
    Expect.allDistinct([cd1, cd3, cd4, cd5]);
  }

  {
    // List inside other constructor
    const cl1 = const C(const <int>[37]);
    const cl2 = C(clist); // Constant context.
    const cl3 = C(const <int>[37]); // Constant context.
    const cl4 = C(<int>[37]); // Constant context.
    var cl5 = C(clist); // Non-constant context, so `new`.
    var cl6 = C(const <int>[37]); // Non-constant context, so `new`.
    var cl7 = C(list); // Non-constant context, so `new`.
    var cl8 = C(<int>[37]); // Non-constant context, so `new`.

    Expect.allIdentical([cl1, cl2, cl3, cl4]);
    Expect.allDistinct([cl1, cl5, cl6, cl7, cl8]);
  }

  {
    // Map inside other constructor.
    const cm1 = C(cmap); // Constant context.
    const cm2 = C(const <int, int>{19: 87}); // Constant context.
    const cm3 = C(<int, int>{19: 87}); // Constant context.
    var cm4 = C(cmap); // Non-constant context, so `new`.
    var cm5 = C(const <int, int>{19: 87}); // Non-constant context, so `new`.
    var cm6 = C(map); // Non-constant context, so `new`.
    var cm7 = C(<int, int>{19: 87}); // Non-constant context, so `new`.

    Expect.identical(cm1, cm2);
    Expect.identical(cm1, cm3);
    Expect.allDistinct([cm1, cm4, cm5, cm6, cm7]);
  }

  {
    // Composite with more than one sub-expression.
    const n1 = N(clist, cmap);
    const n2 = N(const <int>[37], const <int, int>{19: 87});
    const n3 = N(<int>[37], <int, int>{19: 87});
    var n4 = N(const <int>[37], const <int, int>{19: 87});
    var n5 = N(<int>[37], const <int, int>{19: 87});
    var n6 = N(const <int>[37], <int, int>{19: 87});
    var n7 = N(<int>[37], <int, int>{19: 87});
    var n8 = N(clist, cmap);
    var n9 = N(<int>[37], cmap);
    var n10 = N(clist, <int, int>{19: 87});
    var n11 = N(<int>[37], <int, int>{19: 87});
    var n12 = N(list, cmap);
    var n13 = N(clist, map);
    var n14 = N(list, map);

    Expect.identical(n1, n2);
    Expect.identical(n1, n3);
    Expect.allDistinct([n1, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14]);

    Expect
        .allIdentical([clist, n6.left, n10.left, n12.left, n13.left, n14.left]);
    Expect.allDistinct([n5.left, n7.left, n9.left, n11.left]);

    Expect.allIdentical(
        [cmap, n5.right, n9.right, n12.right, n13.right, n14.right]);
    Expect.allDistinct([n6.right, n7.right, n10.right, n11.right]);

    const n20 = const N(const C(42), const <int>[37]);
    const n21 = N(const C(42), const <int>[37]);
    const n22 = N(C(42), const <int>[37]);
    const n23 = N(C(42), clist);
    const n24 = N(C(42), <int>[37]);
    var n25 = N(const C(42), const <int>[37]);
    var n26 = N(C(42), const <int>[37]);
    var n27 = N(C(42), clist);
    var n28 = N(C(42), <int>[37]);
    var n29 = N(C(42), list);
    var n30 = N(c42, clist);
    var n31 = N(cc42, list);

    Expect.allIdentical([n20, n21, n22, n23, n24]);
    Expect.allDistinct([n20, n25, n26, n27, n28, n29, n30, n31]);

    Expect.allDistinct([cc42, n28.left, n29.left]);
    Expect.identical(cc42, n30.left);
    Expect.identical(cc42, n31.left);
    Expect.allIdentical([clist, n29.right, n30.right, n31.right]);
    Expect.notIdentical(clist, n28.right);
  }

  {
    // List literals.
    const l20 = const [
      const C(42),
      const <int>[37]
    ];
    const l21 = [
      const C(42),
      const <int>[37]
    ];
    const l22 = [
      C(42),
      const <int>[37]
    ];
    var l23 = const [C(42), clist];
    const l24 = [
      C(42),
      <int>[37]
    ];
    var l25 = [
      const C(42),
      const <int>[37]
    ];
    var l26 = [
      C(42),
      const <int>[37]
    ];
    var l27 = [C(42), clist];
    var l28 = [
      C(42),
      <int>[37]
    ];
    var l29 = [C(42), list];
    var l30 = [c42, clist];
    var l31 = [cc42, list];

    Expect.allIdentical([l20, l21, l22, l23, l24]);
    // List literals are never const unless in const context.
    Expect.allDistinct([l20, l25, l26, l27, l28, l29, l30, l31]);
    Expect.allIdentical([cc42, l25[0], l30[0], l31[0]]);
    Expect.allDistinct([cc42, l26[0], l27[0], l28[0], l29[0]]);
    Expect
        .allIdentical([clist, l25[1], l26[1], l27[1], l29[1], l30[1], l31[1]]);
    Expect.notIdentical(clist, l28[1]);
  }

  {
    // Map literals.
    const m20 = const <C, List<int>>{
      const C(42): const <int>[37]
    };
    const m21 = {
      const C(42): const <int>[37]
    };
    const m22 = {
      C(42): const <int>[37]
    };
    var m23 = const {C(42): clist};
    const m24 = {
      C(42): <int>[37]
    };
    var m25 = {
      const C(42): const <int>[37]
    };
    var m26 = {
      C(42): const <int>[37]
    };
    var m27 = {C(42): clist};
    var m28 = {
      C(42): <int>[37]
    };
    var m29 = {C(42): list};
    var m30 = {c42: clist};
    var m31 = {cc42: list};

    Expect.allIdentical([m20, m21, m22, m23, m24]);
    // Map literals are never const unless in const context.
    Expect.allDistinct([m20, m25, m26, m27, m28, m29, m30, m31]);
    Expect.identical(cc42, m25.keys.first);
    Expect.allDistinct(
        [cc42, m26.keys.first, m27.keys.first, m28.keys.first, m29.keys.first]);
    Expect.identical(cc42, m30.keys.first);
    Expect.identical(cc42, m31.keys.first);
    Expect.allIdentical([
      clist,
      m25.values.first,
      m26.values.first,
      m27.values.first,
      m29.values.first,
      m30.values.first,
      m31.values.first
    ]);
    Expect.notIdentical(clist, m28.values.first);
  }
}

class C {
  final Object x;
  const C(this.x);
}

class D<T> {
  final T x;
  const D(this.x);
}

class N {
  final Object left, right;
  const N(this.left, this.right);
}
