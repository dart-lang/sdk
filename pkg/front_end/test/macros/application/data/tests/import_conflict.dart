// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Definition Order:
 function:ImportConflictMacro.new()
Definitions:
augment library 'org-dartlang-test:///a/b/c/main.dart';

import 'dart:core' as prefix1_0;
import 'dart:async' as prefix1_1;
import 'dart:math' as prefix1_2;
import 'dart:convert' as prefix1_3;

augment void function(prefix1_0.int i, prefix1_1.FutureOr<prefix1_2.Random> f, prefix1_3.JsonCodec c, ) {
  var prefix = prefix1_0.int;
  var prefix0 = prefix1_1.FutureOr<prefix1_2.Random>;
  var prefix10 = prefix1_3.JsonCodec;
}
*/

import 'package:macro/macro.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

@ImportConflictMacro()
/*member: function:
definitions:
augment void function(int i, FutureOr<Random> f, JsonCodec c, ) {
  var prefix = int;
  var prefix0 = FutureOr<Random>;
  var prefix10 = JsonCodec;
}*/
external void function(int i, FutureOr<Random> f, JsonCodec c);
