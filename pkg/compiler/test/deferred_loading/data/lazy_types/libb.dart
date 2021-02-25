// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart' as lib;

/*member: callFooMethod:member_unit=1{libB}*/
int callFooMethod() => lib.callFooMethod();

/*member: isFoo:member_unit=1{libB}*/
bool isFoo(o) => lib.isFoo(o);

/*member: isFunFunFoo:member_unit=1{libB}*/
bool isFunFunFoo(o) => lib.isFunFunFoo(o);

/*member: isDooFunFunFoo:member_unit=1{libB}*/
bool isDooFunFunFoo(o) => o is lib.Doo<lib.FunFunFoo>;
