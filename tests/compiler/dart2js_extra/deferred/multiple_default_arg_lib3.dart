// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

defaultArg3() => "3b";
defaultArg4() => "4b";
myFunction3(positional1, positional2,
        {argumentName3: defaultArg3, argumentName4: defaultArg4}) =>
    "$positional1 $positional2 ${argumentName3()} - ${argumentName4()}";

myFunction4(positional1, positional2,
        {argumentName5: const X(5), argumentName6}) =>
    argumentName5.value;

class X {
  final int value;
  const X(this.value);
}

const value3 = const X(3);
