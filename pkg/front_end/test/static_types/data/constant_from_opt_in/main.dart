// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*library: nnbd=false*/

import 'opt_in.dart';

main() {
  /*cfe:nnbd.bool!*/ f;
  /*cfe:nnbd.bool!*/ c;
}
