// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  num field = 42;
  num get getter => 42;
  num method(num n) => n;
}

num topLevelMethod(num n) => n;

exhaustiveField(Class c) {
  return /*
   fields={field:num},
   type=Class
  */
      switch (c) {
    Class(:var field) /*space=Class(field: num)*/ => field,
  };
}

exhaustiveGetter(Class c) {
  return /*
   fields={getter:num},
   type=Class
  */
      switch (c) {
    Class(:var getter) /*space=Class(getter: num)*/ => getter,
  };
}

exhaustiveMethod(Class c) {
  return /*
   fields={method:num Function(num)},
   type=Class
  */
      switch (c) {
    Class(:var method) /*space=Class(method: num Function(num))*/ => method,
  };
}

exhaustiveFieldTyped(Class c) {
  return /*
     fields={field:num},
     type=Class
    */
      switch (c) {
    Class(:num field) /*space=Class(field: num)*/ => field,
  };
}

exhaustiveGetterTyped(Class c) {
  return /*
   fields={getter:num},
   type=Class
  */
      switch (c) {
    Class(:num getter) /*space=Class(getter: num)*/ => getter,
  };
}

exhaustiveMethodTyped(Class c) {
  return /*
   fields={method:num Function(num)},
   type=Class
  */
      switch (c) {
    Class(
      :num Function(num) method
    ) /*space=Class(method: num Function(num))*/ =>
      method,
  };
}

nonExhaustiveFieldRestrictedValue(Class c) {
  return /*
   error=non-exhaustive:Class(field: double()),
   fields={field:num},
   type=Class
  */
      switch (c) {
    Class(field: 5) /*space=Class(field: 5)*/ => 5,
  };
}

nonExhaustiveGetterRestrictedValue(Class c) {
  return /*
   error=non-exhaustive:Class(getter: double()),
   fields={getter:num},
   type=Class
  */
      switch (c) {
    Class(getter: 5) /*space=Class(getter: 5)*/ => 5,
  };
}

nonExhaustiveMethodRestrictedValue(Class c) {
  return /*
   error=non-exhaustive:Class(method: num Function(num) _)/Class(),
   fields={method:num Function(num)},
   type=Class
  */
      switch (c) {
    Class(method: topLevelMethod) /*space=Class(method: topLevelMethod)*/ =>
      topLevelMethod,
  };
}

nonExhaustiveFieldRestrictedType(Class c) {
  return /*
   error=non-exhaustive:Class(field: double()),
   fields={field:num},
   type=Class
  */
      switch (c) {
    Class(:int field) /*space=Class(field: int)*/ => field,
  };
}

exhaustiveGetterRestrictedType(Class c) {
  return /*
   error=non-exhaustive:Class(getter: double()),
   fields={getter:num},
   type=Class
  */
      switch (c) {
    Class(:int getter) /*space=Class(getter: int)*/ => getter,
  };
}

exhaustiveMethodRestrictedType(Class c) {
  return /*
   error=non-exhaustive:Class(method: num Function(num) _)/Class(),
   fields={method:num Function(num)},
   type=Class
  */
      switch (c) {
    Class(
      :int Function(num) method
    ) /*space=Class(method: int Function(num))*/ =>
      method,
  };
}

unreachableGetter(Class c) {
  return /*
   fields={field:num,getter:num},
   type=Class
  */
      switch (c) {
    Class(:var field) /*space=Class(field: num)*/ => field,
    Class(
      :var getter
    ) /*
     error=unreachable,
     space=Class(getter: num)
    */
      =>
      getter,
  };
}
