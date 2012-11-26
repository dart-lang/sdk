// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.resolver;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilationError;
import com.google.dart.compiler.DartCompilerContext;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.ErrorCode;
import com.google.dart.compiler.ast.ASTVisitor;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartField;
import com.google.dart.compiler.ast.DartFieldDefinition;
import com.google.dart.compiler.ast.DartFunctionTypeAlias;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartLibraryDirective;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartTypeParameter;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.LibraryExport;
import com.google.dart.compiler.ast.LibraryImport;
import com.google.dart.compiler.ast.LibraryUnit;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.type.Type;
import com.google.dart.compiler.type.TypeVariable;
import com.google.dart.compiler.type.Types;
import com.google.dart.compiler.util.apache.StringUtils;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Builds all class elements and types of a library. Once all libraries
 * of an application have built their types, the library scope per
 * library can be computed.
 */
public class TopLevelElementBuilder {

  public void exec(LibraryUnit library, DartCompilerContext context) {
    assert library.getElement().getScope().isClear();
    for (DartUnit unit : library.getUnits()) {
      unit.accept(new Builder(library.getElement()));
    }
  }

  public void exec(LibraryUnit library, DartUnit unit, DartCompilerContext context) {
    unit.accept(new Builder(library.getElement()));
  }

  public void exec(LibraryUnit library, DartClass cls, DartCompilerContext context) {
    cls.accept(new Builder(library.getElement()));
  }

  /**
   * Fill the scope for this library, using its own top-level elements and elements from imported
   * libraries.
   */
  public void fillInLibraryScope(LibraryUnit library, DartCompilerListener listener) {
    fillInLibraryScope(library, listener, Sets.newHashSet());
  }
    
    /**
     * Fill the scope for this library, using its own top-level elements and elements from imported
     * libraries.
     */
  private void fillInLibraryScope(LibraryUnit library, DartCompilerListener listener,
      Set<Object> processedObjects) {
    Scope importScope = library.getElement().getImportScope();
    Scope scope = library.getElement().getScope();
    
    // We are done with this library. 
    if (library.getElement().getScope().isStateReady()) {
      return;
    }

    // Fill "library" scope.
    if (processedObjects.add(library)) {
      List<Element> exportedElements = Lists.newArrayList();
      {
        DartUnit selfUnit = library.getSelfDartUnit();
        if (selfUnit != null && !selfUnit.getDirectives().isEmpty()
            && selfUnit.getDirectives().get(0) instanceof DartLibraryDirective) {
          DartLibraryDirective libraryDirective = (DartLibraryDirective) selfUnit.getDirectives().get(
              0);
          if (!libraryDirective.isObsoleteFormat()) {
            String name = libraryDirective.getLibraryName();
            if (name != null) {
              String elementName = "__library_" + name;
              scope.declareElement(elementName, library.getElement());
            }
          }
        }
      }
      for (DartUnit unit : library.getUnits()) {
        fillInUnitScope(unit, listener, scope, exportedElements);
      }
      // Remember exported elements.
      for (Element exportedElement : exportedElements) {
        Elements.addExportedElement(library.getElement(), exportedElement);
      }
    }

    // Fill "import" scope.
    Map<String, LibraryPrefixElement> libraryPrefixElements = Maps.newHashMap();
    for (LibraryImport libraryImport : library.getImports()) {
      if (!processedObjects.add(libraryImport)) {
        continue;
      }
      LibraryUnit lib = libraryImport.getLibrary();
      // Prepare scope for this import.
      Scope scopeForImport;
      String prefix = libraryImport.getPrefix();
      {
        if (prefix != null) {
          // Put the prefix in the scope.
          LibraryPrefixElement libraryPrefixElement = libraryPrefixElements.get(prefix);
          if (libraryPrefixElement == null) {
            libraryPrefixElement = new LibraryPrefixElementImplementation(prefix, scope);
            libraryPrefixElements.put(prefix, libraryPrefixElement);
            Element existingElement = scope.declareElement(prefix, libraryPrefixElement);
            // Check for conflict between import prefix and top-level element.
            if (existingElement != null) {
              listener.onError(new DartCompilationError(existingElement.getNameLocation(),
                  ResolverErrorCode.CANNOT_HIDE_IMPORT_PREFIX, prefix));
            }
          }
          libraryPrefixElement.addLibrary(lib.getElement());
          // Fill prefix scope.
          scopeForImport = libraryPrefixElement.getScope();
        } else {
          scopeForImport = importScope;
        }
      }
      // Prepare "lib" scope.
      fillInLibraryScope(lib, listener, processedObjects);
      // Fill "library" scope with element exported from "lib".
      for (Element element : lib.getElement().getExportedElements()) {
        String name = element.getName();
        if (libraryImport.isVisible(name)) {
          Element oldElement = scopeForImport.declareElement(name, element);
          if (oldElement != null) {
            scopeForImport.declareElement(name,
                Elements.createDuplicateElement(oldElement, element));
          }
        }
      }
    }

    // Fill "library" export scope with re-exports.
    for (LibraryExport export : library.getExports()) {
      if (!processedObjects.add(export)) {
        continue;
      }
      LibraryUnit lib = export.getLibrary();
      fillInLibraryScope(lib, listener, processedObjects);
      for (Element element : lib.getElement().getExportedElements()) {
        String name = element.getName();
        // re-export only if not defined locally
        if (scope.findLocalElement(name) != null) {
          continue;
        }
        // check if show/hide combinators of "export" are satisfied
        if (!export.isVisible(name)) {
          continue;
        }
        // do export
        Element oldElement = Elements.addExportedElement(library.getElement(), element);
        if (oldElement != null && oldElement.getEnclosingElement() instanceof LibraryElement) {
          LibraryElement oldLibrary = (LibraryElement) oldElement.getEnclosingElement();
          SourceInfo sourceInfo = export.getSourceInfo();
          if (sourceInfo != null) {
            String oldLibraryName = oldLibrary.getLibraryUnit().getName();
            listener.onError(new DartCompilationError(sourceInfo,
                ResolverErrorCode.DUPLICATE_EXPORTED_NAME, Elements.getUserElementTitle(oldElement),
                oldLibraryName));
          }
        }
      }
    }

    // Done.
    library.getElement().getScope().markStateReady();
  }
  
  @VisibleForTesting
  void fillInUnitScope(DartUnit unit, DartCompilerListener listener, Scope scope,
      List<Element> exportedElements) {
    for (DartNode node : unit.getTopLevelNodes()) {
      if (node instanceof DartFieldDefinition) {
        for (DartField field : ((DartFieldDefinition) node).getFields()) {
          declareNodeInScope(field, listener, scope, exportedElements);
        }
      } else {
        declareNodeInScope(node, listener, scope, exportedElements);
      }
    }
  }

  void declareNodeInScope(DartNode node, DartCompilerListener listener, Scope scope,
      List<Element> exportedElements) {
    Element element = node.getElement();
    String name = element.getName();
    declare(element, listener, scope);
    if (exportedElements != null && !DartIdentifier.isPrivateName(name)) {
      exportedElements.add(element);
    }
  }
  
  private static void compilationError(DartCompilerListener listener, SourceInfo node, ErrorCode errorCode,
                        Object... args) {
    DartCompilationError error = new DartCompilationError(node, errorCode, args);
    listener.onError(error);
  }

  private void declare(Element newElement, DartCompilerListener listener, Scope scope) {
    String name = newElement.getName();
    Element oldElement = scope.findLocalElement(name);
    if (oldElement == null && newElement instanceof FieldElement) {
      FieldElement eField = (FieldElement) newElement;
      if (!eField.getModifiers().isAbstractField()) {
        oldElement = scope.findLocalElement("setter " + name);
      }
      if (eField.getModifiers().isAbstractField()
          && StringUtils.startsWith(name, "setter ")) {
        Element other2 = scope.findLocalElement(StringUtils.removeStart(name, "setter "));
        if (other2 instanceof FieldElement) {
          FieldElement otherField = (FieldElement) other2;
          if (!otherField.getModifiers().isAbstractField()) {
            oldElement = otherField;
          }
        }
      }
    }
    if (oldElement != null) {
      reportDuplicateDeclaration(listener, oldElement, newElement);
      reportDuplicateDeclaration(listener, newElement, oldElement);
    }
    scope.declareElement(name, newElement);
  }
  
  /**
   * Reports {@link ResolverErrorCode#DUPLICATE_TOP_LEVEL_DECLARATION} for given named element.
   */
  private void reportDuplicateDeclaration(DartCompilerListener listener, Element element,
      Element otherElement) {
    compilationError(listener, element.getNameLocation(),
        ResolverErrorCode.DUPLICATE_TOP_LEVEL_DECLARATION,
        Elements.getUserElementTitle(otherElement),
        Elements.getRelativeElementLocation(element, otherElement));
  }

  /**
   * Creates a ClassElement for a class.
   */
  private class Builder extends ASTVisitor<Void> {

    private LibraryElement library;

    public Builder(LibraryElement library) {
      this.library = library;
    }

    @Override
    public Void visitClass(DartClass node) {
      ClassElement element = Elements.classFromNode(node, library);
      List<DartTypeParameter> parameterNodes = node.getTypeParameters();
      List<TypeVariable> typeVariables = Elements.makeTypeVariables(parameterNodes, element);
      element.setType(Types.interfaceType(
          element,
          Collections.<Type>unmodifiableList(typeVariables)));
      node.setElement(element);
      node.getName().setElement(element);
      return null;
    }

    @Override
    public Void visitFunctionTypeAlias(DartFunctionTypeAlias node) {
      FunctionAliasElement element = Elements.functionTypeAliasFromNode(node, library);
      List<DartTypeParameter> parameterNodes = node.getTypeParameters();
      element.setType(Types.functionAliasType(element,
                                              Elements.makeTypeVariables(parameterNodes, element)));
      node.getName().setElement(element);
      node.setElement(element);
      return null;
    }

    @Override
    public Void visitMethodDefinition(DartMethodDefinition node) {
      node.setElement(Elements.methodFromMethodNode(node, library));
      return null;
    }

    @Override
    public Void visitField(DartField node) {
      Modifiers modifiers = node.getModifiers();
      node.setElement(Elements.fieldFromNode(node, library, node.getObsoleteMetadata(), modifiers));
      return null;
    }
  }
}
