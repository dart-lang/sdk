// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'lib2.dart';

/*member: doCast:member_unit=main{}*/
doCast(List<dynamic> l) => l.cast<B>().map(/*closure_unit=main{}*/ (x) => 1);
