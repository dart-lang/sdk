// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  generativeConstructorCall();
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

/*member: Class1.:[exact=Class1|powerset={N}{O}{N}]*/
class Class1 {}

/*member: generativeConstructorCall:[exact=Class1|powerset={N}{O}{N}]*/
generativeConstructorCall() => Class1();

////////////////////////////////////////////////////////////////////////////////
/// Call factory constructor that returns an instance of the same class.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*member: Class3.:[exact=Class3|powerset={N}{O}{N}]*/
  factory Class3() => Class3.named();
  /*member: Class3.named:[exact=Class3|powerset={N}{O}{N}]*/
  Class3.named();
}

/*member: factoryConstructorCall2:[exact=Class3|powerset={N}{O}{N}]*/
factoryConstructorCall2() => Class3();

////////////////////////////////////////////////////////////////////////////////
/// Call factory constructor that returns an instance of another class.
////////////////////////////////////////////////////////////////////////////////

class Class4a {
  /*member: Class4a.:[exact=Class4b|powerset={N}{O}{N}]*/
  factory Class4a() => Class4b();
}

/*member: Class4b.:[exact=Class4b|powerset={N}{O}{N}]*/
class Class4b implements Class4a {}

/*member: factoryConstructorCall3:[exact=Class4b|powerset={N}{O}{N}]*/
factoryConstructorCall3() => Class4a();

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with final field initialization.
////////////////////////////////////////////////////////////////////////////////

class Class5 {
  final /*member: Class5.field:[exact=JSUInt31|powerset={I}{O}{N}]*/ field;

  /*member: Class5.:[exact=Class5|powerset={N}{O}{N}]*/
  Class5(this. /*[exact=JSUInt31|powerset={I}{O}{N}]*/ field);
}

/*member: classWithFinalFieldInitializer:[exact=Class5|powerset={N}{O}{N}]*/
classWithFinalFieldInitializer() => Class5(0);

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with non-final field initialization.
////////////////////////////////////////////////////////////////////////////////

class Class6 {
  var /*member: Class6.field:[exact=JSUInt31|powerset={I}{O}{N}]*/ field;

  /*member: Class6.:[exact=Class6|powerset={N}{O}{N}]*/
  Class6(this. /*[exact=JSUInt31|powerset={I}{O}{N}]*/ field);
}

/*member: classWithNonFinalFieldInitializer:[exact=Class6|powerset={N}{O}{N}]*/
classWithNonFinalFieldInitializer() => Class6(0);

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with explicit field initialization.
////////////////////////////////////////////////////////////////////////////////

class Class7 {
  var /*member: Class7.field:[exact=JSUInt31|powerset={I}{O}{N}]*/ field;

  /*member: Class7.:[exact=Class7|powerset={N}{O}{N}]*/
  Class7(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ value) : this.field = value;
}

/*member: classWithExplicitFieldInitializer:[exact=Class7|powerset={N}{O}{N}]*/
classWithExplicitFieldInitializer() => Class7(0);

////////////////////////////////////////////////////////////////////////////////
/// Call constructor with field initialization in the constructor body.
////////////////////////////////////////////////////////////////////////////////

class Class8 {
  var /*member: Class8.field:[exact=JSUInt31|powerset={I}{O}{N}]*/ field;

  /*member: Class8.:[exact=Class8|powerset={N}{O}{N}]*/
  Class8(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ value) {
    this. /*update: [exact=Class8|powerset={N}{O}{N}]*/ field = value;
  }
}

/*member: classWithFieldInitializerInBody:[exact=Class8|powerset={N}{O}{N}]*/
classWithFieldInitializerInBody() => Class8(0);

////////////////////////////////////////////////////////////////////////////////
/// Instance field with `null` initializer and no assignment in the constructor
/// body.
////////////////////////////////////////////////////////////////////////////////

class Class9 {
  var /*member: Class9.field:[null|powerset={null}]*/ field = null;

  /*member: Class9.:[exact=Class9|powerset={N}{O}{N}]*/
  Class9() {}
}

/*member: classWithNullNoFieldInitializerInBody:[exact=Class9|powerset={N}{O}{N}]*/
classWithNullNoFieldInitializerInBody() => Class9();

////////////////////////////////////////////////////////////////////////////////
/// Instance field with `null` initializer and an assignment in the constructor
/// body.
////////////////////////////////////////////////////////////////////////////////

class Class10 {
  var /*member: Class10.field:[exact=JSUInt31|powerset={I}{O}{N}]*/ field =
      null;

  /*member: Class10.:[exact=Class10|powerset={N}{O}{N}]*/
  Class10(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ value) {
    this. /*update: [exact=Class10|powerset={N}{O}{N}]*/ field = value;
  }
}

/*member: classWithNullFieldInitializerInBody:[exact=Class10|powerset={N}{O}{N}]*/
classWithNullFieldInitializerInBody() => Class10(0);

////////////////////////////////////////////////////////////////////////////////
/// Instance field with `null` initializer and an assignment in one of the
/// constructor bodies.
////////////////////////////////////////////////////////////////////////////////

class Class11 {
  var /*member: Class11.field:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/ field =
      null;

  /*member: Class11.a:[exact=Class11|powerset={N}{O}{N}]*/
  Class11.a(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ value) {
    this. /*update: [exact=Class11|powerset={N}{O}{N}]*/ field = value;
  }

  /*member: Class11.b:[exact=Class11|powerset={N}{O}{N}]*/
  Class11.b() {}
}

/*member: classWithNullMaybeFieldInitializerInBody:[exact=Class11|powerset={N}{O}{N}]*/
classWithNullMaybeFieldInitializerInBody() {
  Class11.a(0);
  return Class11.b();
}

////////////////////////////////////////////////////////////////////////////////
/// Final instance field with `null` initializer.
////////////////////////////////////////////////////////////////////////////////

class Class12 {
  final /*member: Class12.field:[null|powerset={null}]*/ field = null;

  /*member: Class12.:[exact=Class12|powerset={N}{O}{N}]*/
  Class12();
}

/*member: classWithNullFinalFieldInitializer:[exact=Class12|powerset={N}{O}{N}]*/
classWithNullFinalFieldInitializer() {
  return Class12();
}
