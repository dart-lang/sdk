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
    Assert.assertEquals("List<Object>", objectList.toString());
    Assert.assertEquals("Map<Object, Object>", objectMap.toString());
    Assert.assertEquals("ReverseMap<Object, Object>", reverseObjectMap.toString());

    Assert.assertEquals("CLASS Object", object.toString());
    Assert.assertEquals("CLASS List", list.toString());
    Assert.assertEquals("CLASS Map", map.toString());
    Assert.assertEquals("CLASS ReverseMap", reverseMap.toString());

    Assert.assertEquals("Object", object.getType().toString());
    Assert.assertEquals("List<E>", list.getType().toString());
    Assert.assertEquals("Map<K, V>", map.getType().toString());
    Assert.assertEquals("ReverseMap<K, V>", reverseMap.getType().toString());
  }

  public void testRaw() {
    Assert.assertFalse(itype(object).isRaw());
    Assert.assertFalse(objectList.isRaw());
    Assert.assertFalse(objectMap.isRaw());
    Assert.assertFalse(reverseObjectMap.isRaw());

    Assert.assertTrue(itype(list).isRaw());
    Assert.assertTrue(itype(list, itype(object), itype(object)).isRaw());

    Assert.assertFalse(itype(list, objectMap).isRaw());
  }

  public void testAsInstanceOf() {
    Assert.assertEquals(itype(object), types.asInstanceOf(objectList, object));
    Assert.assertEquals(objectList, types.asInstanceOf(objectList, list));

    Assert.assertNull(types.asInstanceOf(objectList, map));

    Assert.assertNull(types.asInstanceOf(itype(object), list));

    Assert.assertEquals(intStringMap, types.asInstanceOf(stringIntReverseMap, map));

    Assert.assertFalse(stringIntMap.equals(types.asInstanceOf(stringIntReverseMap, map)));

    Assert.assertEquals(itype(list), types.asInstanceOf(itype(list), list));
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


    checkStrictSubtype(objectList, itype(object));

    checkStrictSubtype(objectMap, itype(object));

    checkStrictSubtype(reverseObjectMap, itype(object));
    checkStrictSubtype(reverseObjectMap, objectMap);

    checkNotAssignable(objectMap, objectList);
    checkNotAssignable(reverseObjectMap, objectList);
    checkNotAssignable(objectMap, objectList);
    checkNotAssignable(reverseObjectMap, objectList);
  }
}
