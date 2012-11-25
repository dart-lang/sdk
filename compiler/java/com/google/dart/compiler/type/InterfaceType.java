// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;

import java.util.List;

/**
 * An interface type.
 */
public interface InterfaceType extends Type {
  @Override
  InterfaceType subst(List<Type> arguments,
                      List<Type> parameters);

  @Override
  ClassElement getElement();

  List<Type> getArguments();

  boolean isRaw();

  /**
   * @return Whether type args for this interface instance is of type DYNAMIC.
   */
  boolean hasDynamicTypeArgs();

  InterfaceType asRawType();

  Member lookupMember(String name);
  
  void registerSubClass(ClassElement subClass);
  void unregisterSubClass(ClassElement subClass);
  /**
   * @return the unique {@link Member} with given name, defined in one of the subtypes. May be
   *         <code>null</code> if not found or not unique.
   */
  Member lookupSubTypeMember(String name);

  interface Member {
    InterfaceType getHolder();
    Element getElement();
    Type getType();
    Type getSetterType();
    Type getGetterType();

  }
}
