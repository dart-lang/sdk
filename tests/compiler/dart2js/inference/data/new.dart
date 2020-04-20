// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  generativeConstructorCall();
  factoryConstructorCall1();
  factoryConstructorCall2();
  factoryConstructorCall3();
  classWithFinalFieldInitializer();
  classWithNonFinalFieldInitializer();
  classWithExplicitFieldInitializer();
  classWithFieldInitializerInBody();
  classWithNullNoFieldInitializerInBody();
  classWithNullFieldInitializerInBody();
  classWithNullMaybeFieldInitializerInBody();
  classWithNullFinalFieldInitializer();
}

////////////////////////////////////////////////////////////////////////////////
/// Call default constructor of a field-less class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1]*/
class Class1 {}

/*member: generativeConstructorCall:[exact=Class1]*/
generativeConstructorCall() => new Class1();

////////////////////////////////////////////////////////////////////////////////
/// Call factory constructor that returns `null`.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*member: Class2.:[null]*/
  factory Class2() => null;
}

/*member: factoryConstructorCall1:[null]*/
factoryConstructorCall1() => new Class2();

////////////////////////////////////////////////////////////////////////////////
/// Call factory constructor that returns an instance of the same class.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.:[exact=Class3]*/
  factory Class3() => new Class3.named();
  /*member: Class3.named:[exact=Class3]*/
  Class3.named();
}

/*member: factoryConstructorCall2:[exact=Class3]*/
factoryConstructorCall2() => new Class3();

////////////////////////////////////////////////////////////////////////////////
/// Call factory constructor that returns an instance of another class.
////////////////////////////////////////////////////////////////////////////////

class Class4a {
  /*member: Class4a.:[exact=Class4b]*/
  factory Class4a() => new Class4b();
}

/*member: Class4b.:[exact=Class4b]*/
class Class4b implements Class4a {}

/*member: factoryConstructorCall3:[exact=Class4b]*/
factoryConstructorCall3() => new Class4a();

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with final field initialization.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  final /*member: Class5.field:[exact=JSUInt31]*/ field;

  /*member: Class5.:[exact=Class5]*/
  Class5(this. /*[exact=JSUInt31]*/ field);
}

/*member: classWithFinalFieldInitializer:[exact=Class5]*/
classWithFinalFieldInitializer() => new Class5(0);

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with non-final field initialization.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  var /*member: Class6.field:[exact=JSUInt31]*/ field;

  /*member: Class6.:[exact=Class6]*/
  Class6(this. /*[exact=JSUInt31]*/ field);
}

/*member: classWithNonFinalFieldInitializer:[exact=Class6]*/
classWithNonFinalFieldInitializer() => new Class6(0);

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with explicit field initialization.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  var /*member: Class7.field:[exact=JSUInt31]*/ field;

  /*member: Class7.:[exact=Class7]*/
  Class7(/*[exact=JSUInt31]*/ value) : this.field = value;
}

/*member: classWithExplicitFieldInitializer:[exact=Class7]*/
classWithExplicitFieldInitializer() => new Class7(0);

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with field initialization in the constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class8 {
  var /*member: Class8.field:[exact=JSUInt31]*/ field;

  /*member: Class8.:[exact=Class8]*/
  Class8(/*[exact=JSUInt31]*/ value) {
    this. /*update: [exact=Class8]*/ field = value;
  }
}

/*member: classWithFieldInitializerInBody:[exact=Class8]*/
classWithFieldInitializerInBody() => new Class8(0);

////////////////////////////////////////////////////////////////////////////////
/// Instance field with `null` initializer and no assignment in the constructor
/// body.
////////////////////////////////////////////////////////////////////////////////

class Class9 {
  var /*member: Class9.field:[null]*/ field = null;

  /*member: Class9.:[exact=Class9]*/
  Class9() {}
}

/*member: classWithNullNoFieldInitializerInBody:[exact=Class9]*/
classWithNullNoFieldInitializerInBody() => new Class9();

////////////////////////////////////////////////////////////////////////////////
/// Instance field with `null` initializer and an assignment in the constructor
/// body.
////////////////////////////////////////////////////////////////////////////////

class Class10 {
  var /*member: Class10.field:[exact=JSUInt31]*/ field = null;

  /*member: Class10.:[exact=Class10]*/
  Class10(/*[exact=JSUInt31]*/ value) {
    this. /*update: [exact=Class10]*/ field = value;
  }
}

/*member: classWithNullFieldInitializerInBody:[exact=Class10]*/
classWithNullFieldInitializerInBody() => new Class10(0);

////////////////////////////////////////////////////////////////////////////////
/// Instance field with `null` initializer and an assignment in one of the
/// constructor bodies.
////////////////////////////////////////////////////////////////////////////////

class Class11 {
  var /*member: Class11.field:[null|exact=JSUInt31]*/ field = null;

  /*member: Class11.a:[exact=Class11]*/
  Class11.a(/*[exact=JSUInt31]*/ value) {
    this. /*update: [exact=Class11]*/ field = value;
  }

  /*member: Class11.b:[exact=Class11]*/
  Class11.b() {}
}

/*member: classWithNullMaybeFieldInitializerInBody:[exact=Class11]*/
classWithNullMaybeFieldInitializerInBody() {
  new Class11.a(0);
  return new Class11.b();
}

////////////////////////////////////////////////////////////////////////////////
/// Final instance field with `null` initializer.
////////////////////////////////////////////////////////////////////////////////

class Class12 {
  final /*member: Class12.field:[null]*/ field = null;

  /*member: Class12.:[exact=Class12]*/
  Class12();
}

/*member: classWithNullFinalFieldInitializer:[exact=Class12]*/
classWithNullFinalFieldInitializer() {
  return new Class12();
}
