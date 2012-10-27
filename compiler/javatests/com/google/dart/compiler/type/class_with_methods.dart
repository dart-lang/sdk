// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class ClassWithMethods {
  untypedNoArgumentMethod();
  untypedOneArgumentMethod(argument);
  untypedTwoArgumentMethod(argument1, argument2);

  int intNoArgumentMethod();
  int intOneArgumentMethod(int argument);
  int intTwoArgumentMethod(int argument1, int argument2);

  Function functionField;
  var untypedField;
  int intField;
}
