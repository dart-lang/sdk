// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart' as lib;

/*member: isFoo:member_unit=2{libC}*/
bool isFoo(o) => lib.isFoo(o);

/*member: isFunFunFoo:member_unit=2{libC}*/
bool isFunFunFoo(o) => lib.isFunFunFoo(o);

/*member: createB2:member_unit=2{libC}*/
createB2() => new lib.B2();

/*member: createC3:member_unit=2{libC}*/
createC3() => new lib.C3();

/*member: createD3:member_unit=2{libC}*/
createD3() => new lib.D3();

/*member: createDooFunFunFoo:member_unit=2{libC}*/
createDooFunFunFoo() => lib.createDooFunFunFoo();
