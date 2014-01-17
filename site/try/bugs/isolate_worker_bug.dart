// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Successful test: output div contains "future!".

import 'dart:async';

const greeting = "Hello, cool people doing nice things!";

// Prints a greeting.
void main() {
  print(greeting);

  new Future(() => print("future!"));
}
