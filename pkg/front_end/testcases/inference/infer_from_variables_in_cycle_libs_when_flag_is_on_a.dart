// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
import 'infer_from_variables_in_cycle_libs_when_flag_is_on2.dart';

var /*@topType=int*/ x = 2; // ok to infer

main() {}
