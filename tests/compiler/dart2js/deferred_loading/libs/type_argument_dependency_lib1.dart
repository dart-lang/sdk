// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_argument_dependency_lib2.dart';

/*element: doCast:OutputUnit(main, {})*/
doCast(List<dynamic> l) => l.cast<B>().map((x) => 1);
