/*element: main:[null]*/
main() {
  missingGetter();
  missingMethod();
  closureThroughMissingMethod();
  closureThroughMissingSetter();
}

////////////////////////////////////////////////////////////////////////////////
// Access missing getter.
////////////////////////////////////////////////////////////////////////////////

/*element: Class1.:[exact=Class1]*/
class Class1 {
  /*element: Class1.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(/*[null|subclass=Object]*/ _) => 42;

  /*element: Class1.method:[exact=JSUInt31]*/
  // ignore: UNDEFINED_GETTER
  method() => this. /*[exact=Class1]*/ missingGetter;
}

/*element: missingGetter:[exact=JSUInt31]*/
missingGetter() => new Class1(). /*invoke: [exact=Class1]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Invoke missing method.
////////////////////////////////////////////////////////////////////////////////

/*element: Class2.:[exact=Class2]*/
class Class2 {
  /*element: Class2.noSuchMethod:[exact=JSUInt31]*/
  noSuchMethod(/*[null|subclass=Object]*/ _) => 42;

  /*element: Class2.method:[exact=JSUInt31]*/
  // ignore: UNDEFINED_METHOD
  method() => this. /*invoke: [exact=Class2]*/ missingMethod();
}

/*element: missingMethod:[exact=JSUInt31]*/
missingMethod() => new Class2(). /*invoke: [exact=Class2]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing method.
////////////////////////////////////////////////////////////////////////////////

/*element: Class3.:[exact=Class3]*/
class Class3 {
  /*element: Class3.noSuchMethod:[null|subclass=Object]*/
  noSuchMethod(Invocation /*[null|subclass=Object]*/ invocation) {
    return invocation.positionalArguments.first;
  }

  /*element: Class3.method:[null|subclass=Object]*/
  // ignore: UNDEFINED_METHOD
  method() => this. /*invoke: [exact=Class3]*/ missingMethod(
      /*[null]*/ (/*[null|subclass=Object]*/ parameter) {})(0);
}

/*element: closureThroughMissingMethod:[null|subclass=Object]*/
closureThroughMissingMethod() =>
    new Class3(). /*invoke: [exact=Class3]*/ method();

////////////////////////////////////////////////////////////////////////////////
// Pass closure to missing setter.
////////////////////////////////////////////////////////////////////////////////

/*element: Class4.:[exact=Class4]*/
class Class4 {
  /*element: Class4.field:[null|subclass=Object]*/
  var field;

  /*element: Class4.noSuchMethod:[null]*/
  noSuchMethod(Invocation /*[null|subclass=Object]*/ invocation) {
    this. /*update: [exact=Class4]*/ field =
        invocation.positionalArguments.first;
    return null;
  }

  /*element: Class4.method:[null]*/
  method() {
    // ignore: UNDEFINED_SETTER
    this. /*update: [exact=Class4]*/ missingSetter =
        /*[null]*/ (/*[null|subclass=Object]*/ parameter) {};
    this. /*invoke: [exact=Class4]*/ field(0);
  }
}

/*element: closureThroughMissingSetter:[null]*/
closureThroughMissingSetter() =>
    new Class4(). /*invoke: [exact=Class4]*/ method();
