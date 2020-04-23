// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file contains code that has been modified by running dartfix.
// See example.dart for the original unmodified code.

// Dart will automatically convert int literals to doubles.
// Running dartfix converts this double literal to an int
// if --double-to-int is specified on the command line.
const double myDouble = 4;

// This class is used as a mixin but does not use the new mixin syntax.
// Running dartfix converts this class to use the new syntax.
mixin MyMixin {
  final someValue = myDouble;
}

class MyClass with MyMixin {}

void main(List<String> args) {
  if (args.length == 0) {
    print('myDouble = ${MyClass().someValue}');
  }
}
