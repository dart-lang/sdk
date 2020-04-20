// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/

import "opt_out.dart";

/*class: B:A<int?>,B,Object*/
class B extends A<int?> {
  /*member: B.getType:Type* Function()**/
}

/*class: C:A<int?>,B,C,Object,out_int*/
class C extends out_int implements B {
  /*member: C.getType:Type* Function()**/
}

Type typeOf<X>() => X;

main() {
  print(typeOf<int?>() == C().getType());
}
