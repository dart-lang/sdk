// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart' as lib;

/*spec|three-frag.member: callFooMethod:member_unit=1{libB}*/
/*two-frag.member: callFooMethod:member_unit=1{libB, libA}*/
int callFooMethod() => lib.callFooMethod();

/*spec|three-frag.member: isFoo:member_unit=1{libB}*/
/*two-frag.member: isFoo:member_unit=1{libB, libA}*/
bool isFoo(o) => lib.isFoo(o);

/*spec|three-frag.member: isFunFunFoo:member_unit=1{libB}*/
/*two-frag.member: isFunFunFoo:member_unit=1{libB, libA}*/
bool isFunFunFoo(o) => lib.isFunFunFoo(o);

/*spec|three-frag.member: isDooFunFunFoo:member_unit=1{libB}*/
/*two-frag.member: isDooFunFunFoo:member_unit=1{libB, libA}*/
bool isDooFunFunFoo(o) => o is lib.Doo<lib.FunFunFoo>;
