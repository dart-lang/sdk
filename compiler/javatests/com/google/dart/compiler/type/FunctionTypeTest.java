// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import java.util.Arrays;
import java.util.List;

public class FunctionTypeTest extends TypeTestCase {
  private final Types types = Types.getInstance(null);

  private final FunctionType objectsToObject = ftype(function, itype(object), null, itype(object));
  private final FunctionType objectAndObjectsToObject =
      ftype(function, itype(object), null, itype(object), itype(object));
  private final FunctionType stringsToObject = ftype(function, itype(object), null, itype(string));
  private final FunctionType namedStringToObject =
      ftype(function, itype(object), named(itype(string), "arg"), null);
  private final FunctionType namedObjectToObject =
      ftype(function, itype(object), named(itype(object), "arg"), null);
  private final FunctionType objectAndNamedStringToObject =
      ftype(function, itype(object), named(itype(string), "arg"), null, itype(object));
  private final FunctionType manyNames =
      ftype(function, itype(object),
            named(itype(string), "arg1", itype(intElement), "arg2", itype(object), "arg3"),
            null, itype(object));

  @Override
  Types getTypes() {
    return types;
  }

  public void testToString() {
    assertEquals("() -> Object", returnObject.toString());
    assertEquals("() -> String", returnString.toString());
    assertEquals("(Object) -> String", objectToString.toString());
    assertEquals("(String) -> Object", stringToObject.toString());
    assertEquals("(String, int) -> bool", stringAndIntToBool.toString());
    assertEquals("(Object...) -> Object", objectsToObject.toString());
    assertEquals("(Object, Object...) -> Object", objectAndObjectsToObject.toString());
    assertEquals("([String arg]) -> Object", namedStringToObject.toString());
    assertEquals("(Object, [String arg]) -> Object", objectAndNamedStringToObject.toString());
    assertEquals("(Object, [String arg1, int arg2, Object arg3]) -> Object", manyNames.toString());
  }

  public void testAsInstanceOf() {
    checkAsInstanceOf(returnObject);
    checkAsInstanceOf(returnString);
    checkAsInstanceOf(objectToString);
    checkAsInstanceOf(stringToObject);
    checkAsInstanceOf(stringAndIntToBool);
    checkAsInstanceOf(stringAndIntToMap);
    checkAsInstanceOf(objectAndNamedStringToObject);
  }

  private void checkAsInstanceOf(FunctionType type) {
    assertEquals(itype(function), types.asInstanceOf(type, function));
    assertEquals(itype(object), types.asInstanceOf(type, object));
    assertNull(types.asInstanceOf(type, string));
  }

  public void testSubst() {
    Type s = typeVar("S", itype(object));
    Type o = typeVar("O", itype(object));
    List<Type> vars = Arrays.<Type>asList(s, o);
    List<Type> args = Arrays.<Type>asList(itype(string), itype(object));
    Type returnO = ftype(function, o, null, null);
    Type returnS = ftype(function, s, null, null);
    Type oToO = ftype(function, o, null, null, o);
    Type oToS = ftype(function, s, null, null, o);
    Type stringAndIntToMapS = ftype(function, itype(map, s, itype(intElement)),
                                    null, null, itype(string), itype(intElement));
    Type sAndIntToBool = ftype(function, itype(bool), null, null, s, itype(intElement));
    assertEquals(returnObject, returnO.subst(args, vars));
    assertEquals(returnString, returnS.subst(args, vars));
    assertEquals(objectToObject, oToO.subst(args, vars));
    assertEquals(objectToString, oToS.subst(args, vars));
    assertEquals(stringAndIntToBool, sAndIntToBool.subst(args, vars));
    assertEquals(stringAndIntToMap, stringAndIntToMapS.subst(args, vars));

    FunctionType oAndNamedToO = FunctionTypeImplementation.of(function, Arrays.<Type>asList(o),
                                                              null,
                                                              named(itype(string), "arg"), null, o);
    assertEquals(objectAndNamedStringToObject, oAndNamedToO.subst(args, vars));

    Type osToO = FunctionTypeImplementation.of(function, Arrays.<Type>asList(), null, null, o, o);
    assertEquals(objectsToObject, osToO.subst(args, vars));
  }

  public void testEquals() {
    assertEquals(returnObject, ftype(function, itype(object), null, null));
    assertEquals(returnObject, ftype(function, object.getType(), null, null));
    assertFalse(returnObject.equals(returnString));
    assertFalse(returnObject.equals(returnString));
    assertEquals(objectToObject, ftype(function, itype(object), null, null, itype(object)));
    assertFalse(objectToObject.equals(objectToString));
    assertFalse(objectToObject.equals(objectsToObject));
    assertEquals(objectsToObject, objectsToObject);
    assertEquals(objectAndNamedStringToObject, objectAndNamedStringToObject);
    assertFalse(objectsToObject.equals(objectAndNamedStringToObject));
    assertFalse(objectAndNamedStringToObject.equals(objectsToObject));
  }

  public void testIsSubtype() {
    checkSubtype(returnObject, returnObject);
    checkSubtype(returnString, returnObject);
    checkSubtype(objectToObject, stringToObject);
    checkSubtype(objectsToObject, objectsToObject);
    checkSubtype(objectsToObject, stringsToObject);
    checkSubtype(namedObjectToObject, namedObjectToObject);
    checkSubtype(namedObjectToObject, namedStringToObject);
  }
}
