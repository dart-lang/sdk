// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// It is an error to import a deferred library containing extensions without
// hiding them.
import "helpers/on_object.dart" deferred as p1;
// [error line 9, column 1]
// [cfe] Extension 'OnObject' cannot be imported through a deferred import.
//     ^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.DEFERRED_IMPORT_OF_EXTENSION

void main() async {}
