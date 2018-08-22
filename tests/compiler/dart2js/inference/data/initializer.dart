// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  initializingFormal();
  fieldInitializer();
  thisInitializer();
  superInitializer();
}

////////////////////////////////////////////////////////////////////////////////
// Constructor with initializing formal.
////////////////////////////////////////////////////////////////////////////////

class Class1 {
  /*element: Class1.field:[exact=JSUInt31]*/
  var field;

  /*element: Class1.:[exact=Class1]*/
  Class1(this. /*[exact=JSUInt31]*/ field);
}

/*element: initializingFormal:[exact=Class1]*/
initializingFormal() => new Class1(0);

////////////////////////////////////////////////////////////////////////////////
// Constructor with field initializer.
////////////////////////////////////////////////////////////////////////////////

class Class2 {
  /*element: Class2.field:[exact=JSUInt31]*/
  var field;

  /*element: Class2.:[exact=Class2]*/
  Class2(/*[exact=JSUInt31]*/ field) : this.field = field;
}

/*element: fieldInitializer:[exact=Class2]*/
fieldInitializer() => new Class2(0);

////////////////////////////////////////////////////////////////////////////////
// Redirecting generative constructor.
////////////////////////////////////////////////////////////////////////////////

class Class3 {
  /*element: Class3.field:[exact=JSUInt31]*/
  var field;

  /*element: Class3._:[exact=Class3]*/
  Class3._(this. /*[exact=JSUInt31]*/ field);

  /*element: Class3.:[exact=Class3]*/
  Class3(/*[exact=JSUInt31]*/ field) : this._(field);
}

/*element: thisInitializer:[exact=Class3]*/
thisInitializer() => new Class3(0);

////////////////////////////////////////////////////////////////////////////////
// Constructor with super constructor call.
////////////////////////////////////////////////////////////////////////////////

abstract class SuperClass4 {
  /*element: SuperClass4.field:[exact=JSUInt31]*/
  var field;

  /*element: SuperClass4.:[exact=Class4]*/
  SuperClass4(this. /*[exact=JSUInt31]*/ field);
}

class Class4 extends SuperClass4 {
  /*element: Class4.:[exact=Class4]*/
  Class4(/*[exact=JSUInt31]*/ field) : super(field);
}

/*element: superInitializer:[exact=Class4]*/
superInitializer() => new Class4(0);
