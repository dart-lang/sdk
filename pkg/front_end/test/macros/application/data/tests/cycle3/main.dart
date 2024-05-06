// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Macro1.buildDeclarationsForFunction:Macro2.new()*/

import 'dart:async';
import 'main_lib1.dart';

@Macro1() // Error
method() {}