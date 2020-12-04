// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib.dart' as lib;

/*member: isFoo:member_unit=6{libA}*/
bool isFoo(o) => lib.isFoo(o);

/*member: isFunFunFoo:member_unit=6{libA}*/
bool isFunFunFoo(o) => lib.isFunFunFoo(o);

/*member: isMega:member_unit=6{libA}*/
bool isMega(o) => lib.isMega(o);
