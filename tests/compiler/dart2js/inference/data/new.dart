// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  generativeConstructorCall();
  factoryConstructorCall1();
  factoryConstructorCall2();
  factoryConstructorCall3();
}

/// Call default constructor of a field-less class.

class Class1 {}

/*element: generativeConstructorCall:[exact=Class1]*/
generativeConstructorCall() => new Class1();

/// Call factory constructor that returns `null`.

class Class2 {
  factory Class2() => null;
}

/*element: factoryConstructorCall1:[null]*/
factoryConstructorCall1() => new Class2();

/// Call factory constructor that returns an instance of the same class.

class Class3 {
  factory Class3() => new Class3.named();
  Class3.named();
}

/*element: factoryConstructorCall2:[exact=Class3]*/
factoryConstructorCall2() => new Class3();

/// Call factory constructor that returns an instance of another class.

class Class4a {
  factory Class4a() => new Class4b();
}

class Class4b implements Class4a {}

/*element: factoryConstructorCall3:[exact=Class4b]*/
factoryConstructorCall3() => new Class4a();
