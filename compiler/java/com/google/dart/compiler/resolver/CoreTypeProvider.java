// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.type.DynamicType;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;

public interface CoreTypeProvider {

  InterfaceType getIntType();

  InterfaceType getDoubleType();

  InterfaceType getBoolType();

  InterfaceType getStringType();

  InterfaceType getFunctionType();

  Type getNullType();

  Type getVoidType();

  DynamicType getDynamicType();

  InterfaceType getFallThroughError();

  InterfaceType getArrayType(Type elementType);

  InterfaceType getArrayLiteralType(Type elementType);
  
  InterfaceType getIteratorType(Type elementType);
  
  InterfaceType getMapType(Type key, Type value);

  InterfaceType getMapLiteralType(Type key, Type value);

  InterfaceType getObjectArrayType();

  InterfaceType getObjectType();

  InterfaceType getNumType();

  InterfaceType getStringImplementationType();
  
  InterfaceType getTypeType();
}
