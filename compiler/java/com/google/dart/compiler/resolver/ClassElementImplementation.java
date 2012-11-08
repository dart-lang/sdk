// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.collect.Lists;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartObsoleteMetadata;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

class ClassElementImplementation extends AbstractNodeElement implements ClassNodeElement {
  private InterfaceType type;
  private InterfaceType supertype;
  private InterfaceType defaultClass;
  private final List<InterfaceType> interfaces = Lists.newArrayList();
  private final boolean isInterface;
  private final String nativeName;
  private final DartObsoleteMetadata metadata;
  private final Modifiers modifiers;
  private final AtomicReference<List<InterfaceType>> allSupertypes =
      new AtomicReference<List<InterfaceType>>();
  private final SourceInfo nameLocation;
  private final String declarationNameWithTypeParameter;
  private List<Element> unimplementedMembers;
  private final int openBraceOffset;
  private final int closeBraceOffset;

  // declared volatile for thread-safety
  @SuppressWarnings("unused")
  private volatile Set<InterfaceType> subtypes;

  private final List<ConstructorNodeElement> constructors = Lists.newArrayList();
  private final ElementMap members = new ElementMap();

  private final LibraryElement library;

  private static ThreadLocal<Set<Element>> seenSupertypes = new ThreadLocal<Set<Element>>() {
    @Override
    protected Set<Element> initialValue() {
      return new HashSet<Element>();
    }
  };

  ClassElementImplementation(DartClass node, String name, String nativeName,
                             LibraryElement library) {
    super(node, name);
    this.nativeName = nativeName;
    this.library = library;
    if (node != null) {
      isInterface = node.isInterface();
      metadata = node.getObsoleteMetadata();
      modifiers = node.getModifiers();
      nameLocation = node.getName().getSourceInfo();
      declarationNameWithTypeParameter = createDeclarationName(node.getName(), node.getTypeParameters());
      openBraceOffset = node.getOpenBraceOffset();
      closeBraceOffset = node.getCloseBraceOffset();
    } else {
      isInterface = false;
      metadata = DartObsoleteMetadata.EMPTY;
      modifiers = Modifiers.NONE;
      nameLocation = SourceInfo.UNKNOWN;
      declarationNameWithTypeParameter = "";
      openBraceOffset = -1;
      closeBraceOffset = -1;
    }
  }

  @Override
  public DartDeclaration<?> getNode() {
    return (DartClass) super.getNode();
  }

  @Override
  public SourceInfo getNameLocation() {
    return nameLocation;
  }

  @Override
  public void setType(InterfaceType type) {
    this.type = type;
  }

  @Override
  public InterfaceType getType() {
    return type;
  }

  @Override
  public List<Type> getTypeParameters() {
    return getType().getArguments();
  }

  @Override
  public InterfaceType getSupertype() {
    return supertype;
  }

  @Override
  public InterfaceType getDefaultClass() {
    return defaultClass;
  }

  @Override
  public void setSupertype(InterfaceType supertype) {
    if (this.supertype != null) {
      this.supertype.unregisterSubClass(this);
    }
    this.supertype = supertype;
    if (this.supertype != null) {
      this.supertype.registerSubClass(this);
    }
  }

  void setDefaultClass(InterfaceType element) {
    defaultClass = element;
  }

  @Override
  public Iterable<NodeElement> getMembers() {
    return new Iterable<NodeElement>() {
      // The only use case for calling getMembers() is for iterating through the
      // members. You should not be able to add or remove members through the
      // object returned by this method. Returning members or members.value()
      // would allow such direct manipulation which might be problematic for
      // keeping the element model consistent.
      //
      // On the other hand, we don't want to make a defensive copy of the list
      // because that makes this method expensive. This method should not be
      // expensive because the IDE may be using it in interactive scenarios.
      // Strictly speaking, we should also wrap the iterator as we don't want
      // the method Iterator.remove to be used either.
      @Override
      public Iterator<NodeElement> iterator() {
        return members.values().iterator();
      }
    };
  }

  @Override
  public List<ConstructorNodeElement> getConstructors() {
    return constructors;
  }

  @Override
  public List<InterfaceType> getInterfaces() {
    return interfaces;
  }

  @Override
  public ElementKind getKind() {
    return ElementKind.CLASS;
  }

  @Override
  public boolean isInterface() {
    return isInterface;
  }

  @Override
  public DartObsoleteMetadata getMetadata() {
    return metadata;
  }

  @Override
  public Modifiers getModifiers() {
    return modifiers;
  }

  @Override
  public LibraryElement getLibrary() {
    return library;
  }

  @Override
  public String getNativeName() {
    return nativeName;
  }

  @Override
  public String getDeclarationNameWithTypeParameters() {
    return declarationNameWithTypeParameter;
  }

  void addMethod(MethodNodeElement member) {
    String name = member.getName();
    if (member.getModifiers().isOperator()) {
      name = "operator " + name;
    }
    members.add(name, member);
  }

  void addConstructor(ConstructorNodeElement member) {
    constructors.add(member);
  }

  void addField(FieldNodeElement member) {
    members.add(member.getName(), member);
  }

  void addInterface(InterfaceType type) {
    interfaces.add(type);
    type.registerSubClass(this);
  }

  Element findElement(String name) {
    // Temporary find all strategy to get things working.
    // Match resolve order in Resolver.visitMethodInvocation
    Element element = lookupLocalMethod(name);
    if (element != null) {
      return element;
    }
    element = lookupLocalField(name);
    if (element != null) {
      return element;
    }
    if (type != null) {
      for (Type arg : type.getArguments()) {
        if (arg.getElement().getName().equals(name)) {
          return arg.getElement();
        }
      }
    }
    // Don't look for constructors, they are in a different namespace.
    return null;
  }

  /**
   * Lookup a constructor declared in this class. Note that a class may define
   * constructors for interfaces in case the class is a default implementation.
   *
   * @param type The type of the object this constructor is creating.
   * @param name The constructor name ("" if unnamed).
   *
   * @return The constructor found in the class, or null if not found.
   */
  ConstructorElement lookupConstructor(ClassElement type, String name) {
    for (ConstructorElement element : constructors) {
      if (element.getConstructorType().equals(type) && element.getName().equals(name)) {
        return element;
      }
    }
    return null;
  }

  @Override
  public ConstructorElement lookupConstructor(String name) {
    // Lookup a constructor that creates instances of this class.
    return lookupConstructor(this, name);
  }

  @Override
  public Element lookupLocalElement(String name) {
    return members.get(name);
  }

  FieldElement lookupLocalField(String name) {
    return (FieldElement) members.get(name, ElementKind.FIELD);
  }

  MethodElement lookupLocalMethod(String name) {
    return (MethodElement) members.get(name, ElementKind.METHOD);
  }

  public static ClassElementImplementation fromNode(DartClass node, LibraryElement library) {
    DartStringLiteral nativeName = node.getNativeName();
    String nativeNameString = (nativeName == null ? null : nativeName.getValue());
    return new ClassElementImplementation(node, node.getClassName(), nativeNameString, library);
  }

  public static ClassElementImplementation named(String name) {
    return new ClassElementImplementation(null, name, null, null);
  }

  @Override
  public boolean isObject() {
    return supertype == null;
  }

  @Override
  public boolean isObjectChild() {
    return supertype != null && supertype.getElement().isObject();
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return library;
  }

  @Override
  public List<InterfaceType> getAllSupertypes()
      throws CyclicDeclarationException {
    List<InterfaceType> list = allSupertypes.get();
    if (list == null) {
      allSupertypes.compareAndSet(null, computeAllSupertypes());
      list = allSupertypes.get();
    }
    return list;
  }

  private List<InterfaceType> computeAllSupertypes()
      throws CyclicDeclarationException {
    Map<ClassElement, InterfaceType> interfaces = new HashMap<ClassElement, InterfaceType>();
    if (!seenSupertypes.get().add(this)) {
      throw new CyclicDeclarationException(this);
    }
    ArrayList<InterfaceType> supertypes = new ArrayList<InterfaceType>();
    try {
      for (InterfaceType intf : getInterfaces()) {
        addInterfaceToSupertypes(interfaces, supertypes, intf);
      }
      for (InterfaceType intf : getInterfaces()) {
        for (InterfaceType t : intf.getElement().getAllSupertypes()) {
          if (!t.getElement().isObject()) {
            addInterfaceToSupertypes(interfaces, supertypes,
                               t.subst(intf.getArguments(),
                                       intf.getElement().getTypeParameters()));
          }
        }
      }
      if (supertype != null) {
        for (InterfaceType t : supertype.getElement().getAllSupertypes()) {
          if (t.getElement().isInterface()) {
            addInterfaceToSupertypes(interfaces, supertypes,
                               t.subst(supertype.getArguments(),
                                       supertype.getElement().getTypeParameters()));
          }
        }
        supertypes.add(supertype);
        for (InterfaceType t : supertype.getElement().getAllSupertypes()) {
          if (!t.getElement().isInterface()) {
            supertypes.add(t.subst(supertype.getArguments(),
                                   supertype.getElement().getTypeParameters()));
          }
        }
      }
    } finally {
      seenSupertypes.get().remove(this);
    }
    return supertypes;
  }

  private String createDeclarationName(
      DartIdentifier name, List<DartTypeParameter> typeParameters) {
    StringBuilder builder = new StringBuilder();
    builder.append(name.toSource());
    int count = typeParameters.size();
    if (count > 0) {
      builder.append("<");
      for (int i = 0; i < count; i++) {
        if (i > 0) {
          builder.append(", ");
        }
        builder.append(typeParameters.get(i).toSource());
      }
      builder.append(">");
    }
    return builder.toString();
  }

  private void addInterfaceToSupertypes(Map<ClassElement, InterfaceType> interfaces,
                                  ArrayList<InterfaceType> supertypes,
                                  InterfaceType intf) {
    InterfaceType existing = interfaces.put(intf.getElement(), intf);
    if (existing == null || !(existing.equals(intf))){
      supertypes.add(intf);
    }
  }

  @Override
  public List<Element> getUnimplementedMembers() {
    return unimplementedMembers;
  }

  @Override
  public void setUnimplementedMembers(List<Element> members) {
    this.unimplementedMembers = members;
  }
  
  @Override
  public int getOpenBraceOffset() {
    return openBraceOffset;
  }
  
  @Override
  public int getCloseBraceOffset() {
    return closeBraceOffset;
  }
}
