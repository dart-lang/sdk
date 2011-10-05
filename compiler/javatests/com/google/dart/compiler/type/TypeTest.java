// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;


import org.junit.Assert;

import java.util.Arrays;
import java.util.List;

public class TypeTest extends TypeTestCase {
  private final Types types = Types.getInstance(null);

  @Override
  Types getTypes() {
    return types;
  }

  public void testToString() {
    Assert.assertEquals("Object", itype(object).toString());
    Assert.assertEquals("Array<Object>", objectArray.toString());
    Assert.assertEquals("GrowableArray<Object>", growableObjectArray.toString());
    Assert.assertEquals("Map<Object, Object>", objectMap.toString());
    Assert.assertEquals("ReverseMap<Object, Object>", reverseObjectMap.toString());

    Assert.assertEquals("CLASS Object", object.toString());
    Assert.assertEquals("CLASS Array", array.toString());
    Assert.assertEquals("CLASS GrowableArray", growableArray.toString());
    Assert.assertEquals("CLASS Map", map.toString());
    Assert.assertEquals("CLASS ReverseMap", reverseMap.toString());

    Assert.assertEquals("Object", object.getType().toString());
    Assert.assertEquals("Array<E>", array.getType().toString());
    Assert.assertEquals("GrowableArray<E>", growableArray.getType().toString());
    Assert.assertEquals("Map<K, V>", map.getType().toString());
    Assert.assertEquals("ReverseMap<K, V>", reverseMap.getType().toString());
  }

  public void testRaw() {
    Assert.assertFalse(itype(object).isRaw());
    Assert.assertFalse(objectArray.isRaw());
    Assert.assertFalse(growableObjectArray.isRaw());
    Assert.assertFalse(objectMap.isRaw());
    Assert.assertFalse(reverseObjectMap.isRaw());

    Assert.assertTrue(itype(array).isRaw());
    Assert.assertTrue(itype(array, itype(object), itype(object)).isRaw());

    Assert.assertFalse(itype(array, objectMap).isRaw());
  }

  public void testAsInstanceOf() {
    Assert.assertSame(growableObjectArray, types.asInstanceOf(growableObjectArray, growableArray));

    Assert.assertEquals(itype(object), types.asInstanceOf(growableObjectArray, object));
    Assert.assertEquals(objectArray, types.asInstanceOf(growableObjectArray, array));

    Assert.assertNull(types.asInstanceOf(growableObjectArray, map));

    Assert.assertNull(types.asInstanceOf(itype(object), array));

    Assert.assertEquals(intStringMap, types.asInstanceOf(stringIntReverseMap, map));

    Assert.assertFalse(stringIntMap.equals(types.asInstanceOf(stringIntReverseMap, map)));

    Assert.assertEquals(itype(array), types.asInstanceOf(itype(array), array));
    Assert.assertEquals(itype(array), types.asInstanceOf(itype(growableArray), array));
  }

  public void testSubst() {
    List<Type> vars = Arrays.<Type>asList(typeVar("K", itype(object)), typeVar("V", itype(object)));
    Type canonMap = map.getType();
    Type substMap = canonMap.subst(vars, map.getTypeParameters());
    checkNotAssignable(canonMap, substMap);
    Assert.assertFalse(canonMap.equals(substMap));
    Assert.assertFalse(substMap.equals(canonMap));

    List<Type> args = Arrays.<Type>asList(itype(string), itype(intElement));
    Assert.assertTrue(types.isSubtype(canonMap.subst(args, map.getTypeParameters()), stringIntMap));
    Assert.assertTrue(types.isSubtype(substMap.subst(args, vars), stringIntMap));

    TypeVariable tv = typeVar("T", itype(object));
    Assert.assertSame(tv, tv.subst(vars, args));
  }

  public void testEquals() {
    Assert.assertEquals(object.getType(), itype(object));
    Assert.assertNotSame(object.getType(), itype(object));
    Assert.assertFalse(object.getType().equals(map.getTypeParameters().get(0)));
  }

  public void testIsSubtype() {
    checkSubtype(itype(object), itype(object));

    checkStrictSubtype(itype(string), itype(object));
    checkStrictSubtype(itype(intElement), itype(object));
    checkNotAssignable(itype(string), itype(intElement));

    checkStrictSubtype(objectArray, itype(object));

    checkStrictSubtype(growableObjectArray, itype(object));
    checkStrictSubtype(growableObjectArray, objectArray);

    checkStrictSubtype(objectMap, itype(object));

    checkStrictSubtype(reverseObjectMap, itype(object));
    checkStrictSubtype(reverseObjectMap, objectMap);

    checkNotAssignable(objectMap, objectArray);
    checkNotAssignable(reverseObjectMap, objectArray);
    checkNotAssignable(objectMap, growableObjectArray);
    checkNotAssignable(reverseObjectMap, growableObjectArray);

    checkSubtype(itype(growableArray), growableObjectArray);
    checkSubtype(growableObjectArray, itype(growableArray));

    checkStrictSubtype(itype(growableArray), itype(object));
    checkStrictSubtype(itype(growableArray), itype(array));
    checkStrictSubtype(itype(growableArray), objectArray);
  }
}
