// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.17

import './type_record_unsupported_lib.dart';

typedef R = Record; // Error.

typedef AR = A<Record>; // Error.

typedef AR2 = A<FromSupportedR>; // Ok.

typedef AR3 = A<FromSupportedRR>; // Ok.

typedef AR4 = A<FromSupportedAR>; // Ok: indirect use.

typedef RR = FromSupportedR; // Ok.

Record foo1() => throw ''; // Error.

dynamic foo2() => new Record(); // Error.

dynamic foo3() => const Record(); // Error.

dynamic foo4() => <Record>[]; // Error.

dynamic foo5() => Record; // Error.

dynamic foo6() => List<Record>; // Error.

dynamic foo7(Record r) => null; // Error.

dynamic foo8({required Record r}) => null; // Error.

List<Record> foo9() => throw ''; // Error.

dynamic foo10(List<Record> l) => null; // Error.

FromSupportedR foo11() => throw ''; // Ok.

FromSupportedAR foo12() => throw ''; // Ok: indirect use.

FromSupportedRR foo13() => throw ''; // Ok.

dynamic foo14(FromSupportedR r) => null; // Ok.

dynamic foo15(FromSupportedAR l) => null; // Ok: indirect use.

dynamic foo16(FromSupportedRR l) => null; // Ok.

dynamic foo17() => FromSupportedR; // Ok.

dynamic foo18() => FromSupportedAR; // Ok: indirect use.

dynamic foo19() => FromSupportedRR; // Ok.

abstract class A1 extends Record {} // Error.

abstract class A2 implements Record {} // Error.

abstract class A3 with Record {} // Error.

abstract class A4 extends A<Record> {} // Error.

abstract class A5 implements A<Record> {} // Error.

abstract class A6 with A<Record> {} // Error.

abstract class A7 extends FromSupportedR {} // Error.

abstract class A8 extends FromSupportedAR {} // Ok: indirect use.

abstract class A9 extends FromSupportedRR {} // Error.

main() {}
