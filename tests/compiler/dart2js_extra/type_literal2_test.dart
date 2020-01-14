// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

typedef Typedef();
typedef GenericTypedef<T> = void Function(T);
typedef GenericFunctionTypedef = void Function<T>(T);
typedef TypedefWithFutureOr = void Function<T>(FutureOr<T>);

const typedef = Typedef;
const genericTypedef = GenericTypedef;
const genericFunctionTypedef = GenericFunctionTypedef;
const typedefWithFutureOr = TypedefWithFutureOr;
const futureOr = FutureOr;
const null_ = Null;

main() {
  Expect.isTrue(identical(typedef, Typedef));
  Expect.isTrue(identical(genericTypedef, GenericTypedef));
  Expect.isTrue(identical(genericFunctionTypedef, GenericFunctionTypedef));
  Expect.isTrue(identical(typedefWithFutureOr, TypedefWithFutureOr));
  Expect.isTrue(identical(futureOr, FutureOr));
  Expect.isTrue(identical(null_, Null));
}
