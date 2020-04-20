// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that a cyclic dependence is not reported twice in case the
// class declarations from the cycle are in different libraries, but have the
// same name within their respective libraries.
//
// This file is the supplement library for
// 'non_simple_many_libs_same_name_cycle.dart'.

library non_simple_many_libs_same_name_cycle_lib;

import './non_simple_many_libs_same_name_cycle.dart' as lib;

class Hest<TypeY extends lib.Hest> {}
