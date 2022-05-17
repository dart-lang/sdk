// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Definition Order:
 function:ImportConflictMacro.new()
Definitions:
import 'dart:core' as prefix2_0;
import 'dart:async' as prefix2_1;
import 'dart:math' as prefix2_2;
import 'dart:convert' as prefix2_3;

augment void function(prefix2_0.int i, prefix2_1.FutureOr<prefix2_2.Random> f, prefix2_3.JsonCodec c, ) {
  var prefix = prefix2_0.int;
  var prefix0 = prefix2_1.FutureOr<prefix2_2.Random>;
  var prefix10 = prefix2_3.JsonCodec;
}*/

import 'package:macro/macro.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

@ImportConflictMacro()
/*member: function:
augment void function(int i, FutureOr<Random> f, JsonCodec c, ) {
  var prefix = int;
  var prefix0 = FutureOr<Random>;
  var prefix10 = JsonCodec;
}*/
external void function(int i, FutureOr<Random> f, JsonCodec c);
