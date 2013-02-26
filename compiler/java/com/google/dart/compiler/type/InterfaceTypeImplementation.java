// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.type;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.Lists;
import com.google.common.collect.MapMaker;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.util.apache.StringUtils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

/**
 * An interface type.
 */
@VisibleForTesting
public class InterfaceTypeImplementation extends AbstractType implements InterfaceType {
  private final ClassElement element;
  private final List<Type> arguments;
  private final Map<ClassElement, Object> subClasses = new MapMaker().weakKeys().makeMap();

  InterfaceTypeImplementation(ClassElement element, List<Type> arguments) {
    this.element = element;
    this.arguments = arguments;
  }

  @Override
  public ClassElement getElement() {
    return element;
  }

  @Override
  public List<Type> getArguments() {
    return arguments;
  }

  @Override
  public String toString() {
    if (getArguments().isEmpty()) {
      return getElement().getName();
    } else {
      StringBuilder sb = new StringBuilder();
      sb.append(getElement().getName());
      Types.printTypesOn(sb, getArguments(), "<", ">");
      return sb.toString();
    }
  }

  @Override
  public boolean hasDynamicTypeArgs() {
    for (Type t : getArguments()) {
      if (t.getKind() == TypeKind.DYNAMIC) {
        return true;
      }
    }
    return false;
  }

  @Override
  public boolean isRaw() {
    return getArguments().size() != getElement().getTypeParameters().size();
  }

  @Override
  public InterfaceType subst(List<Type> arguments, List<Type> parameters) {
    if (arguments.isEmpty() && parameters.isEmpty()) {
      return this;
    }
    List<Type> substitutedArguments = Types.subst(getArguments(), arguments, parameters);
    return new InterfaceTypeImplementation(getElement(), substitutedArguments);
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof InterfaceType) {
      InterfaceType other = (InterfaceType) obj;
      return getElement().equals(other.getElement()) && getArguments().equals(other.getArguments());
    }
    return false;
  }

  @Override
  public int hashCode() {
    int hashCode = 31;
    hashCode += getElement().hashCode();
    hashCode += 31 * hashCode + getArguments().hashCode();
    return hashCode;
  }

  @Override
  public InterfaceType asRawType() {
    return new InterfaceTypeImplementation(getElement(), Arrays.<Type>asList());
  }

  @Override
  public TypeKind getKind() {
    return TypeKind.INTERFACE;
  }

  @Override
  public Member lookupMember(String name) {
    Member member = lookupMember0(this, name);
    if (member != null) {
      return member;
    }
    InterfaceType supertype = getSupertype();
    if (supertype != null) {
      member = supertype.lookupMember(name);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType intrface : getInterfaces()) {
      member = intrface.lookupMember(name);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType mixin : getMixins()) {
      member = lookupMember0(mixin, name);
      if (member != null) {
        return member;
      }
    }
    return null;
  }

  private static Member lookupMember0(InterfaceType type, String name) {
    Element element = type.getElement().lookupLocalElement(name);
    if (element != null) {
      return new MemberImplementation(type, element);
    }
    return null;
  }

  private InterfaceType getSupertype() {
    InterfaceType supertype = getElement().getSupertype();
    if (supertype == null) {
      return null;
    } else {
      return supertype.subst(getArguments(), getElement().getTypeParameters());
    }
  }

  private List<InterfaceType> getInterfaces() {
    List<InterfaceType> result = new ArrayList<InterfaceType>();
    List<Type> typeArguments = getArguments();
    List<Type> typeParameters = getElement().getTypeParameters();
    for (InterfaceType type : getElement().getInterfaces()) {
      result.add(type.subst(typeArguments, typeParameters));
    }
    return result;
  }
  
  private List<InterfaceType> getMixins() {
    List<InterfaceType> result = new ArrayList<InterfaceType>();
    List<Type> typeArguments = getArguments();
    List<Type> typeParameters = getElement().getTypeParameters();
    for (InterfaceType type : getElement().getMixins()) {
      result.add(type.subst(typeArguments, typeParameters));
    }
    return result;
  }

  private static class MemberImplementation implements Member {
    private final InterfaceType holder;
    private final Element member;

    MemberImplementation(InterfaceType holder, Element member) {
      this.holder = holder;
      this.member = member;
    }

    @Override
    public InterfaceType getHolder() {
      return holder;
    }

    @Override
    public Element getElement() {
      return member;
    }

    @Override
    public Type getType() {
      List<Type> typeArguments = getHolder().getArguments();
      List<Type> typeParameters = getHolder().getElement().getTypeParameters();
      return getElement().getType().subst(typeArguments, typeParameters);
    }

    @Override
    public Type getSetterType() {
      Element element = getElement();
      if (!ElementKind.of(element).equals(ElementKind.FIELD)) {
        return getType();
      }
      FieldElement field = (FieldElement) element;
      MethodElement setter = field.getSetter();
      if (setter == null) {
        setter = Elements.lookupFieldElementSetter(holder.getElement(), member.getName());
        if (setter == null) {
          setter = Elements.lookupFieldElementSetter(holder.getElement(), "setter " + member.getName());
        }
        if (setter == null) {
          return null;
        }
      }
      if (setter.getParameters().size() == 0) {
        return null;
      }
      Type setterType = setter.getParameters().get(0).getType();
      List<Type> typeArguments = getHolder().getArguments();
      List<Type> typeParameters = getHolder().getElement().getTypeParameters();
      return setterType.subst(typeArguments, typeParameters);
    }

    @Override
    public Type getGetterType() {
      Element element = getElement();
      if (!ElementKind.of(element).equals(ElementKind.FIELD)) {
        return getType();
      }
      FieldElement field = (FieldElement) element;
      MethodElement getter = field.getGetter();
      if (getter == null) {
        String name = member.getName();
        name = StringUtils.stripStart(name, "setter ");
        getter = Elements.lookupFieldElementGetter(holder.getElement(), name);
        if (getter == null) {
          return null;
        }
      }
      Type getterType = getter.getReturnType();
      List<Type> typeArguments = getHolder().getArguments();
      List<Type> typeParameters = getHolder().getElement().getTypeParameters();
      return getterType.subst(typeArguments, typeParameters);
    }
  }
  
  @Override
  public void registerSubClass(ClassElement subClass) {
    subClasses.put(subClass, this);
  }
  
  @Override
  public void unregisterSubClass(ClassElement subClass) {
    subClasses.remove(subClass);
  }
  
  @Override
  public List<Member> lookupSubTypeMembers(String name) {
    List<Member> members = Lists.newArrayList();
    fillSubTypeMember(members, name);
    return members;
  }
  
  private void fillSubTypeMember(List<Member> members, String name) {
    {
      Member member = lookupMember(name);
      if (member != null) {
        members.add(member);
      }
    }
    for (ClassElement subClass : subClasses.keySet()) {
      InterfaceType type = subClass.getType();
      if (type instanceof InterfaceTypeImplementation) {
        ((InterfaceTypeImplementation)type).fillSubTypeMember(members, name);
      }
    }
  }
}
