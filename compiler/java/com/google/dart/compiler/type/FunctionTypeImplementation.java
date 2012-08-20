// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.dart.compiler.resolver.ClassElement;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

class FunctionTypeImplementation extends AbstractType implements FunctionType {
  private static final Map<String, Type> EMPTY_MAP = Collections.<String, Type>emptyMap();
  private final ClassElement classElement;
  private final List<Type> parameterTypes;
  private final Type returnType;
  private final Map<String, Type> optionalParameterTypes;
  private final Map<String, Type> namedParameterTypes;
  private final Type rest;

  private FunctionTypeImplementation(ClassElement element,
                                     List<Type> parameterTypes,
                                     Map<String, Type> optionalParameterTypes,
                                     Map<String, Type> namedParameterTypes,
                                     Type rest,
                                     Type returnType) {
    this.classElement = element;
    this.parameterTypes = parameterTypes;
    this.optionalParameterTypes = optionalParameterTypes == null ? EMPTY_MAP : optionalParameterTypes;
    this.namedParameterTypes = namedParameterTypes == null ? EMPTY_MAP : namedParameterTypes;
    this.rest = rest;
    this.returnType = returnType;
  }

  @Override
  public Type subst(List<Type> arguments,
                    List<Type> parameters) {
    List<Type> substitutedParameterTypes = Types.subst(getParameterTypes(), arguments, parameters);

    Map<String, Type> substitutedOptionalParameterTypes = null;
    if (!getOptionalParameterTypes().isEmpty()) {
      substitutedOptionalParameterTypes = new LinkedHashMap<String, Type>();
      for (Map.Entry<String, Type> entry : getOptionalParameterTypes().entrySet()) {
        substitutedOptionalParameterTypes.put(entry.getKey(),
                                           entry.getValue().subst(arguments, parameters));
      }
    }
    
    Map<String, Type> substitutedNamedParameterTypes = null;
    if (!getNamedParameterTypes().isEmpty()) {
      substitutedNamedParameterTypes = new LinkedHashMap<String, Type>();
      for (Map.Entry<String, Type> entry : getNamedParameterTypes().entrySet()) {
        substitutedNamedParameterTypes.put(entry.getKey(),
            entry.getValue().subst(arguments, parameters));
      }
    }

    Type substitutedRest = null;
    if (getRest() != null) {
      substitutedRest = getRest().subst(arguments, parameters);
    }
    Type substitutedReturnType = getReturnType().subst(arguments, parameters);
    return new FunctionTypeImplementation(getElement(),
                                          substitutedParameterTypes,
                                          substitutedOptionalParameterTypes,
                                          substitutedNamedParameterTypes,
                                          substitutedRest, substitutedReturnType);
  }

  @Override
  public ClassElement getElement() {
    return classElement;
  }

  @Override
  public Type getReturnType() {
    return returnType;
  }

  @Override
  public List<Type> getParameterTypes() {
    return parameterTypes;
  }

  @Override
  public TypeKind getKind() {
    return TypeKind.FUNCTION;
  }

  public Map<String, Type> getOptionalParameterTypes() {
    return optionalParameterTypes;
  }
  
  @Override
  public Map<String, Type> getNamedParameterTypes() {
    return namedParameterTypes;
  }

  @Override
  public Type getRest() {
    return rest;
  }

  @Override
  public boolean hasRest() {
    return rest != null;
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("(");
    boolean first = true;
    for (Type argument : getParameterTypes()) {
      if (!first) {
        sb.append(", ");
      }
      sb.append(argument);
      first = false;
    }
    Type rest = getRest();
    if (rest != null) {
      if (!first) {
        sb.append(", ");
      }
      sb.append(rest);
      sb.append("...");
      first = false;
    }
    Map<String, Type> namedParameterTypes = getNamedParameterTypes();
    if (!namedParameterTypes.isEmpty()) {
      if (!first) {
        sb.append(", ");
      }
      sb.append("[");
      first = true;
      for (Entry<String, Type> entry : namedParameterTypes.entrySet()) {
        if (!first) {
          sb.append(", ");
        }
        sb.append(entry.getValue());
        sb.append(" ");
        sb.append(entry.getKey());
        first = false;
      }
      sb.append("]");
    }
    sb.append(") -> ");
    sb.append(getReturnType());
    return sb.toString();
  }

  @Override
  public boolean equals(Object o) {
    // Two FunctionType objects representing the "same" type may not be equal,
    // because they may have different elements.
    if (o instanceof FunctionType) {
      FunctionType other = (FunctionType) o;
      return getElement().equals(other.getElement())
          && getReturnType().equals(other.getReturnType())
          && getParameterTypes().equals(other.getParameterTypes())
          && hasRest() == other.hasRest()
          && (!hasRest() || getRest().equals(other.getRest()))
          && getNamedParameterTypes().equals(other.getNamedParameterTypes());
    }
    return false;
  }

  @Override
  public int hashCode() {
    Type rest = getRest();
    Map<String, Type> namedParameterTypes = getNamedParameterTypes();
    return getElement().hashCode()
        + getReturnType().hashCode()
        + getParameterTypes().hashCode()
        + (rest == null ? 0 : rest.hashCode())
        + (namedParameterTypes == null ? 0 : namedParameterTypes.hashCode());
  }

  /**
   * Returns a function type with the given parameter types and return type. The
   * {@link ClassElement} should always be the element corresponding to the
   * interface Function in the core library.
   */
  static FunctionType of(ClassElement element, List<Type> parameterTypes,
                         Map<String, Type> optionalParameterTypes,
                         Map<String, Type> namedParameterTypes,
                         Type rest, Type returnType) {
    assert element.isDynamic() || element.getName().equals("Function");
    return new FunctionTypeImplementation(element, parameterTypes, optionalParameterTypes,
        namedParameterTypes, rest, returnType);
  }
}
