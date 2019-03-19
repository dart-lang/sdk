// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/tokens_context.dart';

class LinkedElementFactory {
  final AnalysisContext analysisContext;
  final AnalysisSession analysisSession;
  final Reference rootReference;
  final Map<String, _Library> libraryMap = {};

  LinkedElementFactory(
      this.analysisContext, this.analysisSession, this.rootReference);

  void addBundle(LinkedNodeBundle bundle, {LinkedBundleContext context}) {
    context ??= LinkedBundleContext(this, bundle.references);
    for (var library in bundle.libraries) {
      libraryMap[library.uriStr] = _Library(context, library);
    }
  }

  Element elementOfReference(Reference reference) {
    if (reference.element != null) {
      return reference.element;
    }
    if (reference.parent == null) {
      return null;
    }

    return _ElementRequest(this, reference).elementOfReference(reference);
  }

  List<Reference> exportsOfLibrary(String uriStr) {
    var library = libraryMap[uriStr];
    var exportIndexList = library.node.exports;
    var exportReferences = List<Reference>(exportIndexList.length);
    for (var i = 0; i < exportIndexList.length; ++i) {
      var index = exportIndexList[i];
      var reference = library.context.referenceOfIndex(index);
      exportReferences[i] = reference;
    }
    return exportReferences;
  }

  LibraryElementImpl libraryOfUri(String uriStr) {
    var reference = rootReference.getChild(uriStr);
    return elementOfReference(reference);
  }
}

class _ElementRequest {
  final LinkedElementFactory elementFactory;
  final Reference input;

  _ElementRequest(this.elementFactory, this.input);

  ElementImpl elementOfReference(Reference reference) {
    if (reference.element != null) {
      return reference.element;
    }

    var parent2 = reference.parent.parent;
    if (parent2 == null) {
      return _createLibraryElement(reference);
    }

    var parentName = reference.parent.name;

    if (parentName == '@class') {
      var unit = elementOfReference(parent2);
      return _class(unit, reference);
    }

    if (parentName == '@constructor') {
      var class_ = elementOfReference(parent2);
      return _constructor(class_, reference);
    }

    if (parentName == '@function') {
      CompilationUnitElementImpl enclosing = elementOfReference(parent2);
      return _function(enclosing, reference);
    }

    if (parentName == '@getter') {
      var enclosing = elementOfReference(parent2);
      return _getter(enclosing, reference);
    }

    if (parentName == '@method') {
      var enclosing = elementOfReference(parent2);
      return _method(enclosing, reference);
    }

    if (parentName == '@parameter') {
      ExecutableElementImpl enclosing = elementOfReference(parent2);
      return _parameter(enclosing, reference);
    }

    if (parentName == '@typeAlias') {
      var unit = elementOfReference(parent2);
      return _typeAlias(unit, reference);
    }

    if (parentName == '@typeParameter') {
      var enclosing = elementOfReference(parent2) as TypeParameterizedElement;
      return _typeParameter(enclosing, reference);
    }

    if (parentName == '@unit') {
      elementOfReference(parent2);
      // Creating a library fills all its units.
      assert(reference.element != null);
      return reference.element;
    }

    // TODO(scheglov) support other elements
    throw StateError('Not found: $input');
  }

  ClassElementImpl _class(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node == null) {
      _indexUnitDeclarations(unit);
      assert(reference.node != 0, '$reference');
    }
    return reference.element = ClassElementImpl.forLinkedNode(
      unit,
      reference,
      reference.node,
    );
  }

  ConstructorElementImpl _constructor(
      ClassElementImpl class_, Reference reference) {
    return reference.element = ConstructorElementImpl.forLinkedNode(
      reference,
      reference.node,
      class_,
    );
  }

  LibraryElementImpl _createLibraryElement(Reference reference) {
    var uriStr = reference.name;

    var sourceFactory = elementFactory.analysisContext.sourceFactory;
    var librarySource = sourceFactory.forUri(uriStr);

    var libraryData = elementFactory.libraryMap[uriStr];
    var node = libraryData.node;
    var hasName = node.name.isNotEmpty;

    var definingUnitData = node.units[0];
    var definingUnitContext = LinkedUnitContext(
      libraryData.context,
      TokensContext(definingUnitData.tokens),
    );

    var libraryElement = LibraryElementImpl.forLinkedNode(
      elementFactory.analysisContext,
      elementFactory.analysisSession,
      node.name,
      hasName ? node.nameOffset : -1,
      node.name.length,
      definingUnitContext,
      reference,
      definingUnitData.node,
    );

    var units = <CompilationUnitElementImpl>[];
    var unitContainerRef = reference.getChild('@unit');
    for (var unitData in node.units) {
      var unitSource = sourceFactory.forUri(unitData.uriStr);
      var tokensContext = TokensContext(unitData.tokens);
      var unitElement = CompilationUnitElementImpl.forLinkedNode(
        libraryElement,
        LinkedUnitContext(libraryData.context, tokensContext),
        unitContainerRef.getChild(unitData.uriStr),
        unitData.node,
      );
      unitElement.source = unitSource;
      unitElement.librarySource = librarySource;
      units.add(unitElement);
      unitContainerRef.getChild(unitData.uriStr).element = unitElement;
    }

    libraryElement.definingCompilationUnit = units[0];
    libraryElement.parts = units.skip(1).toList();
    return reference.element = libraryElement;
  }

  Element _function(CompilationUnitElementImpl enclosing, Reference reference) {
    enclosing.functions;
    assert(reference.element != null);
    return reference.element;
  }

  PropertyAccessorElementImpl _getter(
      ElementImpl enclosing, Reference reference) {
    if (enclosing is ClassElementImpl) {
      enclosing.accessors;
      // Requesting accessors sets elements for accessors and fields.
      assert(reference.element != null);
      return reference.element;
    }
    if (enclosing is CompilationUnitElementImpl) {
      enclosing.accessors;
      // Requesting accessors sets elements for accessors and variables.
      assert(reference.element != null);
      return reference.element;
    }
    // Only classes and units have accessors.
    throw StateError('${enclosing.runtimeType}');
  }

  void _indexUnitDeclarations(CompilationUnitElementImpl unit) {
    var context = unit.linkedContext;
    var unitRef = unit.reference;
    var classRef = unitRef.getChild('@class');
    var enumRef = unitRef.getChild('@class');
    var functionRef = unitRef.getChild('@function');
    var typeAliasRef = unitRef.getChild('@typeAlias');
    var variableRef = unitRef.getChild('@variable');
    for (var declaration in unit.linkedNode.compilationUnit_declarations) {
      var kind = declaration.kind;
      if (kind == LinkedNodeKind.classDeclaration ||
          kind == LinkedNodeKind.classTypeAlias) {
        var name = context.getUnitMemberName(declaration);
        classRef.getChild(name).node = declaration;
      } else if (kind == LinkedNodeKind.enumDeclaration) {
        var name = context.getUnitMemberName(declaration);
        enumRef.getChild(name).node = declaration;
      } else if (kind == LinkedNodeKind.functionDeclaration) {
        var name = context.getUnitMemberName(declaration);
        functionRef.getChild(name).node = declaration;
      } else if (kind == LinkedNodeKind.functionTypeAlias) {
        var name = context.getUnitMemberName(declaration);
        typeAliasRef.getChild(name).node = declaration;
      } else if (kind == LinkedNodeKind.topLevelVariableDeclaration) {
        var variables = declaration.topLevelVariableDeclaration_variableList;
        for (var variable in variables.variableDeclarationList_variables) {
          var name = context.getSimpleName(variable.variableDeclaration_name);
          variableRef.getChild(name).node = variable;
        }
      } else {
        throw UnimplementedError('$kind');
      }
    }
  }

  MethodElementImpl _method(ClassElementImpl enclosing, Reference reference) {
    enclosing.methods;
    // Requesting methods sets elements for all of them.
    assert(reference.element != null);
    return reference.element;
  }

  Element _parameter(ExecutableElementImpl enclosing, Reference reference) {
    enclosing.parameters;
    assert(reference.element != null);
    return reference.element;
  }

  GenericTypeAliasElementImpl _typeAlias(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node == null) {
      _indexUnitDeclarations(unit);
      assert(reference.node != 0, '$reference');
    }
    return reference.element = GenericTypeAliasElementImpl.forLinkedNode(
      unit,
      reference,
      reference.node,
    );
  }

  Element _typeParameter(
      TypeParameterizedElement enclosing, Reference reference) {
    enclosing.typeParameters;
    // Requesting type parameters sets elements for all their references.
    assert(reference.element != null);
    return reference.element;
  }
}

class _Library {
  final LinkedBundleContext context;
  final LinkedNodeLibrary node;

  _Library(this.context, this.node);
}
