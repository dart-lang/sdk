// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Static field used in tests below.
var field;

/// Static getter with no side effects. Used in tests below.
/*element: emptyGetter:Depends on nothing, Changes nothing.*/
get emptyGetter => null;

/// Static getter with a single side effect of reading a static. Used in tests
/// below.
/*element: nonEmptyGetter:Depends on static store, Changes nothing.*/
get nonEmptyGetter => field;

/// Static method with no side effects. Used in tests below.
/*element: emptyMethod:Depends on nothing, Changes nothing.*/
emptyMethod() {}

/// Static method with a single side effect of reading a static. Used in tests
/// below.
/*element: nonEmptyMethod:Depends on static store, Changes nothing.*/
nonEmptyMethod() => field;

/*element: Class.:Depends on nothing, Changes nothing.*/
class Class {
  /// Instance field used in tests below.
  var field;

  /// Instance getter with no side effects. Used in tests below.
  /*element: Class.emptyGetter:Depends on nothing, Changes nothing.*/
  get emptyGetter => null;

  /// Instance getter with a single side effect of reading a static. Used in
  /// tests below.
  /*element: Class.nonEmptyGetter:Depends on field store, Changes nothing.*/
  get nonEmptyGetter => field;

  /// Instance method with no side effects. Used in tests below.
  /*element: Class.emptyMethod:Depends on nothing, Changes nothing.*/
  emptyMethod() {}

  /// Instance method with a single side effect of reading a static. Used in
  /// tests below.
  /*element: Class.nonEmptyMethod:Depends on field store, Changes nothing.*/
  nonEmptyMethod() => field;
}

/// Call an empty instance method. This propagates the side effects of the
/// instance method; here none.
/*element: callEmptyInstanceMethod:Depends on nothing, Changes nothing.*/
callEmptyInstanceMethod(c) => c.emptyMethod();

/// Call an empty instance getter. This marks the method as having all side
/// effects.
/*element: callEmptyInstanceGetter:Depends on [] field store static store, Changes [] field static.*/
callEmptyInstanceGetter(c) => c.emptyGetter();

/// Call a non-empty instance method. This propagates the side effects of the
/// instance method; here dependency of static properties.
/*element: callNonEmptyInstanceMethod:Depends on field store, Changes nothing.*/
callNonEmptyInstanceMethod(c) => c.nonEmptyMethod();

/// Call a non-empty instance getter. This marks the method as having all side
/// effects.
/*element: callNonEmptyInstanceGetter:Depends on [] field store static store, Changes [] field static.*/
callNonEmptyInstanceGetter(c) => c.nonEmptyGetter();

/// Read an empty instance method. This propagates the side effects of the
/// instance method; here none.
/*element: readEmptyInstanceMethod:Depends on nothing, Changes nothing.*/
readEmptyInstanceMethod(c) => c.emptyMethod;

/// Read an empty instance getter. This propagates the side effects of the
/// instance getter; here none.
/*element: readEmptyInstanceGetter:Depends on nothing, Changes nothing.*/
readEmptyInstanceGetter(c) => c.emptyGetter;

/// Read a non-empty instance method. This propagates the side effects of the
/// instance method; here dependency of static properties.
/*element: readNonEmptyInstanceMethod:Depends on field store, Changes nothing.*/
readNonEmptyInstanceMethod(c) => c.nonEmptyMethod;

/// Read a non-empty instance getter. This propagates the side effects of the
/// instance getter; here dependency of static properties.
/*element: readNonEmptyInstanceGetter:Depends on field store, Changes nothing.*/
readNonEmptyInstanceGetter(c) => c.nonEmptyGetter;

/// Read an instance field. This adds dependency of instance properties to the
/// side effects of the method.
/*element: readInstanceField:Depends on field store, Changes nothing.*/
readInstanceField(c) => c.field;

/// Write to an instance field. This adds change of instance properties to the
/// side effects of the method.
/*element: writeInstanceField:Depends on nothing, Changes field.*/
writeInstanceField(c) => c.field = 42;

/// Call an instance field. This marks the method as having all side effects.
/*element: callInstanceField:Depends on [] field store static store, Changes [] field static.*/
callInstanceField(c) => c.field();

/// Read a static field. This adds dependency of static properties to the
/// side effects of the method.
/*element: readStaticField:Depends on static store, Changes nothing.*/
readStaticField() => field;

/// Write to a static field. This adds change of static properties to the
/// side effects of the method.
/*element: writeStaticField:Depends on nothing, Changes static.*/
writeStaticField() => field = 42;

/// Call a static field. This marks the method as having all side effects.
/*element: callStaticField:Depends on [] field store static store, Changes [] field static.*/
callStaticField() => field();

/// Read and write of a static field. This adds dependency of static properties
/// and change of static properties to the side effects of the method.
/*element: readAndWriteStaticField:Depends on static store, Changes static.*/
readAndWriteStaticField() {
  field = field;
}

/// Call an empty static method. This propagates the side effects of the
/// instance method; here none.
/*element: callEmptyStaticMethod:Depends on nothing, Changes nothing.*/
callEmptyStaticMethod() => emptyMethod();

/// Call an empty static getter. This marks the method as having all side
/// effects.
/*element: callEmptyStaticGetter:Depends on [] field store static store, Changes [] field static.*/
callEmptyStaticGetter() => emptyGetter();

/// Call a non-empty static method. This propagates the side effects of the
/// instance method; here dependency of static properties.
/*element: callNonEmptyStaticMethod:Depends on static store, Changes nothing.*/
callNonEmptyStaticMethod() => nonEmptyMethod();

/// Call a non-empty static getter. This marks the method as having all side
/// effects.
/*element: callNonEmptyStaticGetter:Depends on [] field store static store, Changes [] field static.*/
callNonEmptyStaticGetter() => nonEmptyGetter();

/// Read an empty static method. This propagates the side effects of the
/// static method; here none.
/*element: readEmptyStaticMethod:Depends on nothing, Changes nothing.*/
readEmptyStaticMethod() => emptyMethod;

/// Read an empty static getter. This propagates the side effects of the
/// static getter; here none.
/*element: readEmptyStaticGetter:Depends on nothing, Changes nothing.*/
readEmptyStaticGetter() => emptyGetter;

/// Read a non-empty static method. This propagates the side effects of the
/// static method; here dependency of static properties.
/*element: readNonEmptyStaticMethod:Depends on static store, Changes nothing.*/
readNonEmptyStaticMethod() => nonEmptyMethod;

/// Read a non-empty static getter. This propagates the side effects of the
/// static getter; here dependency of static properties.
/*element: readNonEmptyStaticGetter:Depends on static store, Changes nothing.*/
readNonEmptyStaticGetter() => nonEmptyGetter;

/// Call a static method that reads an instance field. This propagates the side
/// effects of the static method; here dependency of instance properties.
/*element: callingReadInstanceField:Depends on field store, Changes nothing.*/
callingReadInstanceField(c) => readInstanceField(c);

/// Call a static method that writes to an instance field. This propagates the
/// side effects of the static method; here change of instance properties.
/*element: callingWriteInstanceField:Depends on nothing, Changes field.*/
callingWriteInstanceField(c) => writeInstanceField(c);

/// Call a static method that calls an instance field. This propagates the side
/// effects of the static method; here all side-effects.
/*element: callingCallInstanceField:Depends on [] field store static store, Changes [] field static.*/
callingCallInstanceField(c) => callInstanceField(c);

/// Call a static method that reads a static field. This propagates the side
/// effects of the static method; here dependency of static properties.
/*element: callingReadStaticField:Depends on static store, Changes nothing.*/
callingReadStaticField() => readStaticField();

/// Call a static method that writes to a static field. This propagates the
/// side effects of the static method; here change of static properties.
/*element: callingWriteStaticField:Depends on nothing, Changes static.*/
callingWriteStaticField() => writeStaticField();

/// Call a static method that calls a static field. This propagates the side
/// effects of the static method; here all side-effects.
/*element: callingCallStaticField:Depends on [] field store static store, Changes [] field static.*/
callingCallStaticField() => callStaticField();

/*element: main:Depends on [] field store static store, Changes [] field static.*/
main() {
  var c = new Class();

  callEmptyInstanceMethod(c);
  callEmptyInstanceGetter(c);
  callNonEmptyInstanceMethod(c);
  callNonEmptyInstanceGetter(c);

  readEmptyInstanceMethod(c);
  readEmptyInstanceGetter(c);
  readNonEmptyInstanceMethod(c);
  readNonEmptyInstanceGetter(c);

  readInstanceField(c);
  writeInstanceField(c);
  callInstanceField(c);

  callEmptyStaticMethod();
  callEmptyStaticGetter();
  callNonEmptyStaticMethod();
  callNonEmptyStaticGetter();

  readEmptyStaticMethod();
  readEmptyStaticGetter();
  readNonEmptyStaticMethod();
  readNonEmptyStaticGetter();

  readStaticField();
  writeStaticField();
  callStaticField();
  readAndWriteStaticField();

  callingReadInstanceField(c);
  callingWriteInstanceField(c);
  callingCallInstanceField(c);

  callingReadStaticField();
  callingWriteStaticField();
  callingCallStaticField();
}
