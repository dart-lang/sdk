// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  zero();
  one();
  half();
  large();
  huge();

  thisExact();
  thisSubclass();
  thisSubclassExact();
  thisSubtype();
  thisSubtypeExact();
  thisSubtypeMixedIn();
  thisSubtypeExactMixedIn();
}

////////////////////////////////////////////////////////////////////////////////
/// Return a zero integer literal.
////////////////////////////////////////////////////////////////////////////////

/*element: zero:[exact=JSUInt31]*/
zero() => 0;

////////////////////////////////////////////////////////////////////////////////
/// Return a positive integer literal.
////////////////////////////////////////////////////////////////////////////////

/*element: one:[exact=JSUInt31]*/
one() => 1;

////////////////////////////////////////////////////////////////////////////////
/// Return a double literal.
////////////////////////////////////////////////////////////////////////////////

/*element: half:[exact=JSDouble]*/
half() => 0.5;

////////////////////////////////////////////////////////////////////////////////
/// Return a >31bit integer literal.
////////////////////////////////////////////////////////////////////////////////

/*element: large:[subclass=JSUInt32]*/
large() => 2147483648;

////////////////////////////////////////////////////////////////////////////////
/// Return a >32bit integer literal.
////////////////////////////////////////////////////////////////////////////////

/*element: huge:[subclass=JSPositiveInt]*/
huge() => 4294967296;

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class with no subclasses.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.method:[exact=Class1]*/
  method() => this;
}

/*element: thisExact:[exact=Class1]*/
thisExact() => new Class1(). /*invoke: [exact=Class1]*/ method();

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class with an instantiated subclass.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2a.:[exact=Class2a]*/
class Class2a {
  /*element: Class2a.method:[subclass=Class2a]*/
  method() => this;
}

/*element: Class2b.:[exact=Class2b]*/
class Class2b extends Class2a {}

/*element: thisSubclass:[subclass=Class2a]*/
thisSubclass() {
  new Class2b();
  return new Class2a(). /*invoke: [exact=Class2a]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class with no instantiated subclasses.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3a.:[exact=Class3a]*/
class Class3a {
  /*element: Class3a.method:[exact=Class3a]*/
  method() => this;
}

class Class3b extends Class3a {}

/*element: thisSubclassExact:[exact=Class3a]*/
thisSubclassExact() {
  return new Class3a(). /*invoke: [exact=Class3a]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class that is mixed into an instantiated class.
////////////////////////////////////////////////////////////////////////////////

/*element: Class4a.:[exact=Class4a]*/
class Class4a {
  /*element: Class4a.method:[subtype=Class4a]*/
  method() => this;
}

/*element: Class4b.:[exact=Class4b]*/
class Class4b extends Object with Class4a {}

/*element: thisSubtype:[subtype=Class4a]*/
thisSubtype() {
  new Class4b();
  return new Class4a(). /*invoke: [exact=Class4a]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class that is mixed into an uninstantiated class.
////////////////////////////////////////////////////////////////////////////////

/*element: Class5a.:[exact=Class5a]*/
class Class5a {
  /*element: Class5a.method:[exact=Class5a]*/
  method() => this;
}

class Class5b extends Object with Class5a {}

/*element: thisSubtypeExact:[exact=Class5a]*/
thisSubtypeExact() {
  return new Class5a(). /*invoke: [exact=Class5a]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a mixed in class that is itself instantiated.
////////////////////////////////////////////////////////////////////////////////

/*element: Class6a.:[exact=Class6a]*/
class Class6a {
  /*element: Class6a.method:[subtype=Class6a]*/
  method() => this;
}

/*element: Class6b.:[exact=Class6b]*/
class Class6b extends Object with Class6a {}

/*element: thisSubtypeMixedIn:[subtype=Class6a]*/
thisSubtypeMixedIn() {
  new Class6a();
  return new Class6b(). /*invoke: [exact=Class6b]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a mixed in class that is itself uninstantiated.
////////////////////////////////////////////////////////////////////////////////

class Class7a {
  /*element: Class7a.method:[exact=Class7b]*/
  method() => this;
}

/*element: Class7b.:[exact=Class7b]*/
class Class7b extends Object with Class7a {}

/*element: thisSubtypeExactMixedIn:[exact=Class7b]*/
thisSubtypeExactMixedIn() {
  return new Class7b(). /*invoke: [exact=Class7b]*/ method();
}
