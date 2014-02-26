// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import "deferred_constraints_lib2.dart" as lib;
@lazy import "deferred_constraints_lib.dart" as lib; /// 01: compile-time error

const lazy = const DeferredLibrary('lib');

void main() {}
