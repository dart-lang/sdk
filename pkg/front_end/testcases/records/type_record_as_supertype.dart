// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef R = Record;

typedef RR = R;

class G<X> {}

abstract class A1 extends Record {} // Error.

abstract class A2 extends RR {} // Error.

abstract class A3 extends G<Record> {} // Ok.

abstract class A4 extends G<RR> {} // Ok.

abstract class B1 implements Record {} // Error.

abstract class B2 implements RR {} // Error.

abstract class B3 implements G<Record> {} // Ok.

abstract class B4 implements G<RR> {} // Ok.

abstract class C1 with Record {} // Error.

abstract class C2 with RR {} // Error.

abstract class C3 with G<Record> {} // Ok.

abstract class C4 with G<RR> {} // Ok.

main() {}
