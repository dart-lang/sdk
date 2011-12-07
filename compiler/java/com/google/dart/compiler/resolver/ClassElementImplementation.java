// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartDeclaration;
import com.google.dart.compiler.ast.DartStringLiteral;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicReference;

class ClassElementImplementation extends AbstractElement implements ClassElement {
  private InterfaceType type;
  private InterfaceType supertype;
  private InterfaceType defaultClass;
  private List<InterfaceType> interfaces;
  private Set<InterfaceType> immediateSubtypes = new HashSet<InterfaceType>();
  private final boolean isInterface;
  private final String nativeName;
  private final Modifiers modifiers;
  private final AtomicReference<List<InterfaceType>> allSupertypes =
      new AtomicReference<List<InterfaceType>>();

  // declared volatile for thread-safety
  private volatile Set<InterfaceType> subtypes;

  private final List<ConstructorElement> constructors;
  private final Map<String, Element> members;

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
    constructors = new ArrayList<ConstructorElement>();
    members = new LinkedHashMap<String, Element>();
    interfaces = new ArrayList<InterfaceType>();
    if (node != null) {
      isInterface = node.isInterface();
      modifiers = node.getModifiers();
    } else {
      isInterface = false;
      modifiers = Modifiers.NONE;
    }
  }

  @Override
  public DartDeclaration<?> getNode() {
    return (DartClass) super.getNode();
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
  public List<? extends Type> getTypeParameters() {
    return getType().getArguments();
  }

  private void computeTransitiveSubtypes(Set<InterfaceType> computedSubtypes) {
    if (computedSubtypes.addAll(immediateSubtypes)) {
      for (InterfaceType subtype : immediateSubtypes) {
        ClassElementImplementation classElement = (ClassElementImplementation) subtype.getElement();
        classElement.computeTransitiveSubtypes(computedSubtypes);
      }
    }
  }

  @Override
  public Set<InterfaceType> getSubtypes() {
    if (subtypes == null) {
      // add double-checked locking, with subtypes being declared volatile, for
      // thread-safety
      synchronized (this) {
        if (subtypes == null) {
          // Compute once, this will be an issue when we get to code
          // generation...
          HashSet<InterfaceType> newSubtypes = new HashSet<InterfaceType>();
          newSubtypes.add(getType());
          computeTransitiveSubtypes(newSubtypes);
          subtypes = newSubtypes;
        }
      }
    }
    return subtypes;
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
    this.supertype = supertype;
    if (TypeKind.of(supertype) == TypeKind.INTERFACE) {
      ClassElementImplementation superClassElement =
        (ClassElementImplementation) supertype.getElement();
      superClassElement.immediateSubtypes.add(this.getType());
    }
  }

  void setDefaultClass(InterfaceType element) {
    this.defaultClass = element;
  }

  @Override
  public Iterable<Element> getMembers() {
    return new Iterable<Element>() {
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
      public Iterator<Element> iterator() {
        return members.values().iterator();
      }
    };
  }

  @Override
  public List<ConstructorElement> getConstructors() {
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

  void addMethod(MethodElement member) {
    String name = member.getName();
    if (member.getModifiers().isOperator()) {
      name = "operator " + name;
    }
    members.put(name, member);
  }

  void addConstructor(ConstructorElement member) {
    constructors.add(member);
  }

  void addField(FieldElement member) {
    members.put(member.getName(), member);
  }

  void addInterface(InterfaceType type) {
    interfaces.add(type);

    if (TypeKind.of(type) == TypeKind.INTERFACE) {
      ClassElementImplementation interfaceElement = (ClassElementImplementation) type.getElement();
      interfaceElement.immediateSubtypes.add(this.getType());
    }
  }

  Element findElement(String name) {
    // Temporary find all strategy to get things working.
    Element element = lookupLocalField(name);
    if (element != null) {
      return element;
    }
    element = lookupLocalMethod(name);
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
    Element element = lookupLocalElement(name);
    if (ElementKind.of(element).equals(ElementKind.FIELD)) {
      return (FieldElement) element;
    }
    return null;
  }

  MethodElement lookupLocalMethod(String name) {
    Element element = lookupLocalElement(name);
    if (ElementKind.of(element).equals(ElementKind.METHOD)) {
      return (MethodElement) element;
    }
    return null;
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
  public boolean isAbstract() {
    if (modifiers.isAbstract()) {
      return true;
    }
    for (Element element : getMembers()) {
      if (element.getModifiers().isAbstract()) {
        return true;
      }
    }
    return false;
  }

  @Override
  public EnclosingElement getEnclosingElement() {
    return library;
  }

  @Override
  public List<InterfaceType> getAllSupertypes()
      throws CyclicDeclarationException, DuplicatedInterfaceException {
    List<InterfaceType> list = allSupertypes.get();
    if (list == null) {
      allSupertypes.compareAndSet(null, computeAllSupertypes());
      list = allSupertypes.get();
    }
    return list;
  }

  private List<InterfaceType> computeAllSupertypes()
      throws CyclicDeclarationException, DuplicatedInterfaceException {
    Map<ClassElement, InterfaceType> interfaces = new HashMap<ClassElement, InterfaceType>();
    if (!seenSupertypes.get().add(this)) {
      throw new CyclicDeclarationException(this);
    }
    ArrayList<InterfaceType> supertypes = new ArrayList<InterfaceType>();
    try {
      for (InterfaceType intf : getInterfaces()) {
        addCheckDuplicated(interfaces, supertypes, intf);
      }
      for (InterfaceType intf : getInterfaces()) {
        for (InterfaceType t : intf.getElement().getAllSupertypes()) {
          if (!t.getElement().isObject()) {
            addCheckDuplicated(interfaces, supertypes,
                               t.subst(intf.getArguments(),
                                       intf.getElement().getTypeParameters()));
          }
        }
      }
      if (supertype != null) {
        for (InterfaceType t : supertype.getElement().getAllSupertypes()) {
          if (t.getElement().isInterface()) {
            addCheckDuplicated(interfaces, supertypes,
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

  private void addCheckDuplicated(Map<ClassElement, InterfaceType> interfaces,
                                  ArrayList<InterfaceType> supertypes,
                                  InterfaceType intf) throws DuplicatedInterfaceException {
    InterfaceType existing = interfaces.put(intf.getElement(), intf);
    if (existing == null) {
      supertypes.add(intf);
    } else {
      if (!existing.equals(intf)) {
        throw new DuplicatedInterfaceException(existing, intf);
      }
    }
  }
}
