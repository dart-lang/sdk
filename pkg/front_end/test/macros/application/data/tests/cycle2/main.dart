// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 method:Macro2.new()*/

import 'dart:async';
import 'main_lib1.dart';
import 'main_lib2.dart';

@Macro1() // Error
@Macro2() // Ok
method() {}