// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library isolate.create.error_helper5_lib;

// This library has a main that is not a function,
// but is a constant with a function type.


void mymain() { print("Not call mymain function!"); }

const main = mymain;
