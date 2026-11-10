// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}

sealed class B implements A {}

final class _B1Impl extends B {}

final class _B2Impl extends B {}

int f(A a) => /*
 checkingOrder={A,B,_B1Impl,_B2Impl},
 error=non-exhaustive:_B1Impl();_B2Impl(),
 expandedSubtypes={_B1Impl,_B2Impl},
 reduced=non-exhaustive:B(),
 subtypes={B},
 type=A
*/
    switch (a) {};
