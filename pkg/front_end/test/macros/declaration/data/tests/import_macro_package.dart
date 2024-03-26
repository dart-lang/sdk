// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:_macros/src/api.dart|package:macro/macro.dart|package:macros/macros.dart,
  main.dart],
 macrosAreAvailable,
 neededPrecompilations=[package:macro/macro.dart=Macro1(named/new)|Macro2(named/new)|Macro3(named/new)|Macro4(new)]
*/

// ignore: unused_import
import 'package:macro/macro.dart';

void main() {}
