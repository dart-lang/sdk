// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler;

import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeKind;

import java.net.URI;

/**
 * A visitor that fills in {@link LibraryDeps} for a compilation unit.
 */
public class LibraryDepsVisitor extends DartNodeTraverser<Void> {

  /**
   * Fill in library dependencies from a compilation unit.
   *
   * @param unit the unit whose dependencies are to be filled in
   * @param deps the target library deps
   */
  static void exec(DartUnit unit, LibraryDeps deps) {
    LibraryDepsVisitor v = new LibraryDepsVisitor();
    unit.accept(v);

    String relPath = unit.getSource().getRelativePath();
    deps.setSource(relPath, v.source);
  }

  private final LibraryDeps.Source source = new LibraryDeps.Source();
  private DartClass currentClass;

  private LibraryDepsVisitor() {
  }

  @Override
  public Void visitIdentifier(DartIdentifier node) {
    Element target = node.getTargetSymbol();
    ElementKind kind = ElementKind.of(target);

    // Deal with field and method references:
    // - Add explicit dependencies on top-level fields and method.
    // - Add "holes" for fields and methods found in a superclass (see LibraryDeps for further
    //   explanation).
    switch (kind) {
      case FIELD:
      case METHOD:
        EnclosingElement enclosing = target.getEnclosingElement();
        addHoleIfSuper(node, enclosing);
        if (enclosing.getKind().equals(ElementKind.LIBRARY)) {
          addElementDependency(target);
        }
        break;
    }

    // Add dependency on the computed type of identifiers.
    switch (kind) {
      case NONE:
      case DYNAMIC:
        break;

      default: {
        Type type = target.getType();
        if (type != null) {
          Element element = type.getElement();
          if (ElementKind.of(element).equals(ElementKind.CLASS)) {
            addElementDependency(element);
          }
        }
        break;
      }
    }

    return null;
  }

  @Override
  public Void visitPropertyAccess(DartPropertyAccess node) {
    if (node.getQualifier() instanceof DartIdentifier) {
      DartIdentifier qualifier = (DartIdentifier) node.getQualifier();
      Element target = qualifier.getTargetSymbol();
      if (target != null && target.getKind() == ElementKind.LIBRARY) {
        // Handle library prefixes normally (the prefix part of the qualifier
        // doesn't contain any resolvable library source info)
        return super.visitPropertyAccess(node);
      }
    }
    // Skip rhs of property accesses, so that all identifiers we visit will be
    // unqualified.
    return node.getQualifier().accept(this);
  }

  @Override
  public Void visitClass(DartClass node) {
    currentClass = node;
    node.visitChildren(this);
    currentClass = null;
    return null;
  }

  @Override
  public Void visitTypeNode(DartTypeNode node) {
    if (TypeKind.of(node.getType()).equals(TypeKind.INTERFACE)) {
      addElementDependency(((InterfaceType) node.getType()).getElement());
    }
    node.visitChildren(this);
    return null;
  }

  /**
   * Add a 'hole' for the given identifier, if its declaring class is a superclass of the current
   * class. A 'hole' dependency specifies a name that, if filled by something in the library scope,
   * would require this unit to be recompiled.
   *
   * This situation occurs because names in the library scope bind more strongly than unqualified
   * superclass members.
   */
  private void addHoleIfSuper(DartIdentifier node, Element holder) {
    if (ElementKind.of(holder).equals(ElementKind.CLASS)
        && holder != currentClass.getSymbol()) {
      source.putHole(node.getTargetName());
    }
  }

  /**
   * Adds a direct dependency on the given class.
   */
  private void addElementDependency(Element elem) {
    DartNode node = elem.getNode();
    if (node != null) {
      Source nodeSource = node.getSource();
      URI libUri = ((DartSource) nodeSource).getLibrary().getUri();
      LibraryDeps.Dependency dep = new LibraryDeps.Dependency(libUri,
          Integer.toString(node.computeHash()));

      String name;
      switch (elem.getKind()) {
        case CLASS:
          name = ((DartClass) node).getClassName();
          break;
        case FIELD:
          name = ((DartField) node).getName().getTargetName();
          break;
        case METHOD:
          DartMethodDefinition method = (DartMethodDefinition) node;
          DartIdentifier ident = (DartIdentifier) method.getName();
          name = ident.getTargetName();
          break;
        default:
          throw new AssertionError("Unexpected top-level node type");
      }

      source.putDependency(name, dep);
    }
  }
}
