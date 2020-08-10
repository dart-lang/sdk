// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart' as lib;

/*member: isFoo:OutputUnit(6, {libC})*/
bool isFoo(o) => lib.isFoo(o);

/*member: isFunFunFoo:OutputUnit(6, {libC})*/
bool isFunFunFoo(o) => lib.isFunFunFoo(o);

/*member: createB2:OutputUnit(6, {libC})*/
createB2() => new lib.B2();

/*member: createC3:OutputUnit(6, {libC})*/
createC3() => new lib.C3();

/*member: createD3:OutputUnit(6, {libC})*/
createD3() => new lib.D3();

/*member: createDooFunFunFoo:OutputUnit(6, {libC})*/
createDooFunFunFoo() => lib.createDooFunFunFoo();
