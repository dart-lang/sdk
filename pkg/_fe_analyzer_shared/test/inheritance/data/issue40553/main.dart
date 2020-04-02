// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";
import "dart:async";

Type typeOf<X>() => X;

/*class: C:A<FutureOr<int?>>,C,Object*/
class C extends A<FutureOr<int?>> {
  /*member: C.getType:Type* Function()**/
}

/*class: D:A<FutureOr<int>>,D,Object*/
class D extends A<FutureOr<int>> {
  /*member: D.getType:Type* Function()**/
}

/// TODO: Solve CFE / analyzer difference.
/// It looks to me that CFE type of `A` is incorrect.
/// As described in https://github.com/dart-lang/sdk/issues/40553,
/// NNBD_TOP_MERGE(FutureOr<int?>, FutureOr*<int*>) = FutureOr<int?>
/*cfe|cfe:builder.class: E:A<FutureOr<int?>?>,B,C,E,Object*/
/*analyzer.class: E:A<FutureOr<int?>>,B,C,E,Object*/
class E extends B implements C {
  /*member: E.getType:Type* Function()**/
}

main() {
  print(typeOf<FutureOr<int?>>() == E().getType());
  print(typeOf<FutureOr<int>>() == E().getType());
}
