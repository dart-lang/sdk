// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.ast;

import com.google.dart.compiler.common.HasSymbol;
import com.google.dart.compiler.common.Symbol;
import com.google.dart.compiler.resolver.ClassElement;

import java.util.List;

/**
 * Represents a Dart class.
 */
public class DartClass extends DartDeclaration<DartIdentifier> implements HasSymbol {

  private ClassElement element;

  private DartTypeNode superclass;

  private final List<DartNode> members;
  private final List<DartTypeParameter> typeParameters;
  private final List<DartTypeNode> interfaces;

  private boolean isInterface;
  private final Modifiers modifiers;
  private DartTypeNode defaultClass;

  private int hash = -1;

  // If the Dart class is implemented by a native JS class the nativeName
  // points to the JS class. Otherwise it is null.
  private final DartStringLiteral nativeName;

  public DartClass(DartIdentifier name, DartStringLiteral nativeName,
                   DartTypeNode superclass, List<DartTypeNode> interfaces,
                   List<DartNode> members,
                   List<DartTypeParameter> typeParameters,
                   Modifiers modifiers) {
    this(name, nativeName, superclass, interfaces, members, typeParameters, null, false, modifiers);
  }

  public DartClass(DartIdentifier name, DartTypeNode superclass, List<DartTypeNode> interfaces,
                   List<DartNode> members,
                   List<DartTypeParameter> typeParameters, DartTypeNode defaultClass) {
    this(name,
        null,
        superclass,
        interfaces,
        members,
        typeParameters,
        defaultClass,
        true,
        Modifiers.NONE);
  }

  /**
   * Set the diet-string hash code for the class
   * @param hash the hash code to set
   */
  void setHash(int hash) {
    this.hash = hash;
  }

  public DartClass(DartIdentifier name, DartStringLiteral nativeName,
                   DartTypeNode superclass, List<DartTypeNode> interfaces,
                   List<DartNode> members,
                   List<DartTypeParameter> typeParameters, DartTypeNode defaultClass,
                   boolean isInterface,
                   Modifiers modifiers) {
    super(name);
    this.nativeName = nativeName;
    this.superclass = becomeParentOf(superclass);
    this.members = becomeParentOf(members);
    this.typeParameters = becomeParentOf(typeParameters);
    this.interfaces = becomeParentOf(interfaces);
    this.defaultClass = becomeParentOf(defaultClass);
    this.isInterface = isInterface;
    this.modifiers = modifiers;
  }

  public boolean isInterface() {
    return isInterface;
  }

  public Modifiers getModifiers() {
    return modifiers;
  }

  public boolean isAbstract() {
    if (modifiers.isAbstract()) {
      return true;
    }
    for (DartNode node : members) {
      if (node instanceof DartMethodDefinition) {
        DartMethodDefinition methodDefinition = (DartMethodDefinition) node;
        if (methodDefinition.getModifiers().isAbstract()) {
          return true;
        }
      }
      if (node instanceof DartFieldDefinition) {
        DartFieldDefinition fieldDefinition = (DartFieldDefinition) node;
        for (DartField field : fieldDefinition.getFields()) {
          if (field.getModifiers().isAbstract()) {
            return true;
          }
        }
      }
    }
    return false;
  }

  public List<DartNode> getMembers() {
    return members;
  }

  public List<DartTypeParameter> getTypeParameters() {
    return typeParameters;
  }

  public List<DartTypeNode> getInterfaces() {
    return interfaces;
  }

  public String getClassName() {
    if (getName() == null) {
      return null;
    }
    return getName().getTargetName();
  }

  public DartTypeNode getSuperclass() {
    return superclass;
  }

  public DartTypeNode getDefaultClass() {
    return defaultClass;
  }

  public Symbol getDefaultSymbol() {
    if (defaultClass != null) {
      return defaultClass.getType().getElement();
    } else {
      return null;
    }
  }

  public Symbol getSuperSymbol() {
    if (superclass != null) {
      return superclass.getType().getElement();
    } else {
      return null;
    }
  }

  @Override
  public ClassElement getSymbol() {
    return element;
  }

  public void setDefaultClass(DartTypeNode newName) {
    defaultClass = becomeParentOf(newName);
  }

  public void setSuperclass(DartTypeNode newName) {
    superclass = becomeParentOf(newName);
  }

  @Override
  public void setSymbol(Symbol symbol) {
    this.element = (ClassElement) symbol;
  }

  public DartStringLiteral getNativeName() {
    return nativeName;
  }

  @Override
  public void traverse(DartVisitor v, DartContext ctx) {
    if (v.visit(this, ctx)) {
      if (superclass != null) {
        superclass = becomeParentOf(v.accept(superclass));
      }
      v.acceptWithInsertRemove(this, getMembers());
      if (getTypeParameters() != null) {
        v.acceptWithInsertRemove(this, getTypeParameters());
      }
      if (getInterfaces() != null) {
        v.acceptWithInsertRemove(this, getInterfaces());
      }
      if (defaultClass != null) {
        defaultClass = becomeParentOf(v.accept(defaultClass));
      }
    }
    v.endVisit(this, ctx);
  }

  @Override
  public void visitChildren(DartPlainVisitor<?> visitor) {
    visitor.visit(typeParameters);
    if (superclass != null) {
      superclass.accept(visitor);
    }
    visitor.visit(interfaces);
    if (defaultClass != null) {
      defaultClass.accept(visitor);
    }
    visitor.visit(members);
  }

  @Override
  public <R> R accept(DartPlainVisitor<R> visitor) {
    return visitor.visitClass(this);
  }

  @Override
  public int computeHash() {
    // TODO(jgw): Remove this altogether in fixing b/5324113.

    // Cache hashes for DartClass, because they're always needed.
    if (this.hash == -1) {
      this.hash = super.computeHash();
    }
    return this.hash;
  }
}
