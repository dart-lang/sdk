// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "deferred_prefix_constraints_lib.dart" deferred as lib; //# 01: compile-time error
import "deferred_prefix_constraints_lib2.dart" deferred as lib; //# 01: continued

void main() {}
