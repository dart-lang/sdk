// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.DynamicElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.Elements;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Type of untyped expressions.
 */
class DynamicTypeImplementation extends AbstractType implements DynamicType {

  @Override
  public DynamicTypeImplementation subst(List<Type> arguments,
                                         List<Type> parameters) {
    return this;
  }

  @Override
  public DynamicElement getElement() {
    return Elements.dynamicElement();
  }

  @Override
  public DynamicElement getTypeVariableElement() {
    return getElement();
  }

  @Override
  public String toString() {
    return "dynamic";
  }

  @Override
  public boolean equals(Object obj) {
    return obj instanceof DynamicType;
  }

  @Override
  public int hashCode() {
    return DynamicType.class.hashCode();
  }

  @Override
  public List<Type> getArguments() {
    return Collections.<Type>emptyList();
  }

  @Override
  public boolean isRaw() {
    return false;
  }

  @Override
  public boolean hasDynamicTypeArgs() {
    return false;
  }

  @Override
  public DynamicType asRawType() {
    return this;
  }

  @Override
  public TypeKind getKind() {
    return TypeKind.DYNAMIC;
  }

  @Override
  public Type getReturnType() {
    return this;
  }

  @Override
  public List<Type> getParameterTypes() {
    return Collections.emptyList();
  }

  @Override
  public Member lookupMember(String name) {
    return new Member() {

      @Override
      public Type getGetterType() {
        return DynamicTypeImplementation.this;
      }

      @Override
      public Type getSetterType() {
        return DynamicTypeImplementation.this;
      }

      @Override
      public Type getType() {
        return DynamicTypeImplementation.this;
      }

      @Override
      public InterfaceType getHolder() {
        return DynamicTypeImplementation.this;
      }

      @Override
      public Element getElement() {
        return Elements.dynamicElement();
      }
    };
  }

  @Override
  public Type getRest() {
    return null;
  }

  @Override
  public boolean hasRest() {
    return false;
  }
  
  @Override
  public Map<String, Type> getOptionalParameterTypes() {
    return null;
  }

  @Override
  public Map<String, Type> getNamedParameterTypes() {
    return null;
  }
}
