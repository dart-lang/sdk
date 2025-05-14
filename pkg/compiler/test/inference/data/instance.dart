// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  thisExact();
  thisSubclass();
  thisSubclassExact();
  thisSubtype();
  thisSubtypeExact();
  thisSubtypeMixedIn();
  thisSubtypeExactMixedIn();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class with no subclasses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class1.:[exact=Class1|powerset=0]*/
class Class1 {
  /*member: Class1.method:[exact=Class1|powerset=0]*/
  method() => this;
}

/*member: thisExact:[exact=Class1|powerset=0]*/
thisExact() => Class1(). /*invoke: [exact=Class1|powerset=0]*/ method();

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class with an instantiated subclass.
////////////////////////////////////////////////////////////////////////////////

/*member: Class2a.:[exact=Class2a|powerset=0]*/
class Class2a {
  /*member: Class2a.method:[subclass=Class2a|powerset=0]*/
  method() => this;
}

/*member: Class2b.:[exact=Class2b|powerset=0]*/
class Class2b extends Class2a {}

/*member: thisSubclass:[subclass=Class2a|powerset=0]*/
thisSubclass() {
  Class2b();
  return Class2a(). /*invoke: [exact=Class2a|powerset=0]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class with no instantiated subclasses.
////////////////////////////////////////////////////////////////////////////////

/*member: Class3a.:[exact=Class3a|powerset=0]*/
class Class3a {
  /*member: Class3a.method:[exact=Class3a|powerset=0]*/
  method() => this;
}

class Class3b extends Class3a {}

/*member: thisSubclassExact:[exact=Class3a|powerset=0]*/
thisSubclassExact() {
  return Class3a(). /*invoke: [exact=Class3a|powerset=0]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class that is mixed into an instantiated class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class4a.:[exact=Class4a|powerset=0]*/
mixin class Class4a {
  /*member: Class4a.method:[subtype=Class4a|powerset=0]*/
  method() => this;
}

/*member: Class4b.:[exact=Class4b|powerset=0]*/
class Class4b extends Object with Class4a {}

/*member: thisSubtype:[subtype=Class4a|powerset=0]*/
thisSubtype() {
  Class4b();
  return Class4a(). /*invoke: [exact=Class4a|powerset=0]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a class that is mixed into an uninstantiated class.
////////////////////////////////////////////////////////////////////////////////

/*member: Class5a.:[exact=Class5a|powerset=0]*/
mixin class Class5a {
  /*member: Class5a.method:[exact=Class5a|powerset=0]*/
  method() => this;
}

class Class5b extends Object with Class5a {}

/*member: thisSubtypeExact:[exact=Class5a|powerset=0]*/
thisSubtypeExact() {
  return Class5a(). /*invoke: [exact=Class5a|powerset=0]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a mixed in class that is itself instantiated.
////////////////////////////////////////////////////////////////////////////////

/*member: Class6a.:[exact=Class6a|powerset=0]*/
mixin class Class6a {
  /*member: Class6a.method:[subtype=Class6a|powerset=0]*/
  method() => this;
}

/*member: Class6b.:[exact=Class6b|powerset=0]*/
class Class6b extends Object with Class6a {}

/*member: thisSubtypeMixedIn:[subtype=Class6a|powerset=0]*/
thisSubtypeMixedIn() {
  Class6a();
  return Class6b(). /*invoke: [exact=Class6b|powerset=0]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
/// Return `this` of a mixed in class that is itself uninstantiated.
////////////////////////////////////////////////////////////////////////////////

mixin Class7a {
  /*member: Class7a.method:[exact=Class7b|powerset=0]*/
  method() => this;
}

/*member: Class7b.:[exact=Class7b|powerset=0]*/
class Class7b extends Object with Class7a {}

/*member: thisSubtypeExactMixedIn:[exact=Class7b|powerset=0]*/
thisSubtypeExactMixedIn() {
  return Class7b(). /*invoke: [exact=Class7b|powerset=0]*/ method();
}
