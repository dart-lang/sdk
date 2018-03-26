// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_bool_literals_in_conditional_expressions`

bool a, b, c;

var d = a ? true : b; // LINT
var e = a ? false : b; // LINT
var f = a ? b : true; // LINT
var g = a ? b : false; // LINT
var h = a ? b : c; // OK