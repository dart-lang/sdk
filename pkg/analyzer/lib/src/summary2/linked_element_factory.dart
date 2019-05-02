// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/core_types.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class LinkedElementFactory {
  final AnalysisContext analysisContext;
  final AnalysisSession analysisSession;
  final Reference rootReference;
  final Map<String, LinkedLibraryContext> libraryMap = {};

  CoreTypes _coreTypes;

  LinkedElementFactory(
      this.analysisContext, this.analysisSession, this.rootReference);

  CoreTypes get coreTypes {
    return _coreTypes ??= CoreTypes(this);
  }

  void addBundle(LinkedBundleContext context) {
    libraryMap.addAll(context.libraryMap);
  }

  Namespace buildExportNamespace(Uri uri) {
    var exportedNames = <String, Element>{};

    var exportedReferences = exportsOfLibrary('$uri');
    for (var exportedReference in exportedReferences) {
      var element = elementOfReference(exportedReference);
      exportedNames[element.name] = element;
    }

    return Namespace(exportedNames);
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
    if (library == null) return const [];

    var exportIndexList = library.node.exports;
    var exportReferences = List<Reference>(exportIndexList.length);
    for (var i = 0; i < exportIndexList.length; ++i) {
      var index = exportIndexList[i];
      var reference = library.context.referenceOfIndex(index);
      exportReferences[i] = reference;
    }
    return exportReferences;
  }

  bool isLibraryUri(String uriStr) {
    var libraryContext = libraryMap[uriStr];
    return !libraryContext.definingUnit.hasPartOfDirective;
  }

  LibraryElementImpl libraryOfUri(String uriStr) {
    var reference = rootReference.getChild(uriStr);
    return elementOfReference(reference);
  }

  LinkedNode nodeOfReference(Reference reference) {
//    if (reference.node != null) {
//      return reference.node;
//    }
//
//    var unitRef = reference.parent?.parent;
//    var unitContainer = unitRef?.parent;
//    if (unitContainer?.name == '@unit') {
//      var libraryUriStr = unitContainer.parent.name;
//      var libraryData = libraryMap[libraryUriStr];
//      for (var unitData in libraryData.node.units) {
//        var definingUnitContext = LinkedUnitContext(
//          libraryData.context,
//          TokensContext(unitData.tokens),
//        );
//        _ElementRequest._indexUnitDeclarations(
//          definingUnitContext,
//          unitRef,
//          unitData.node,
//        );
//        return reference.node;
//      }
//    }

    throw UnimplementedError('$reference');
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

    if (parentName == '@enum') {
      var unit = elementOfReference(parent2);
      return _enum(unit, reference);
    }

    if (parentName == '@field') {
      var enclosing = elementOfReference(parent2);
      return _field(enclosing, reference);
    }

    if (parentName == '@function') {
      CompilationUnitElementImpl enclosing = elementOfReference(parent2);
      return _function(enclosing, reference);
    }

    if (parentName == '@getter' || parentName == '@setter') {
      var enclosing = elementOfReference(parent2);
      return _accessor(enclosing, reference);
    }

    if (parentName == '@method') {
      var enclosing = elementOfReference(parent2);
      return _method(enclosing, reference);
    }

    if (parentName == '@mixin') {
      var unit = elementOfReference(parent2);
      return _mixin(unit, reference);
    }

    if (parentName == '@parameter') {
      ExecutableElementImpl enclosing = elementOfReference(parent2);
      return _parameter(enclosing, reference);
    }

    if (parentName == '@prefix') {
      LibraryElementImpl enclosing = elementOfReference(parent2);
      return _prefix(enclosing, reference);
    }

    if (parentName == '@typeAlias') {
      var unit = elementOfReference(parent2);
      return _typeAlias(unit, reference);
    }

    if (parentName == '@typeParameter') {
      var enclosing = elementOfReference(parent2);
      if (enclosing is ParameterElement) {
        (enclosing as ParameterElement).typeParameters;
      } else {
        (enclosing as TypeParameterizedElement).typeParameters;
      }
      assert(reference.element != null);
      return reference.element;
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

  PropertyAccessorElementImpl _accessor(
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
    if (enclosing is EnumElementImpl) {
      enclosing.accessors;
      // Requesting accessors sets elements for accessors and variables.
      assert(reference.element != null);
      return reference.element;
    }
    // Only classes and units have accessors.
    throw StateError('${enclosing.runtimeType}');
  }

  ClassElementImpl _class(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node2 == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node2 != null, '$reference');
    }
    ClassElementImpl.forLinkedNode(unit, reference, reference.node2);
    return reference.element;
  }

  ConstructorElementImpl _constructor(
      ClassElementImpl enclosing, Reference reference) {
    enclosing.constructors;
    // Requesting constructors sets elements for all of them.
    assert(reference.element != null);
    return reference.element;
  }

  LibraryElementImpl _createLibraryElement(Reference reference) {
    var uriStr = reference.name;

    var sourceFactory = elementFactory.analysisContext.sourceFactory;
    var librarySource = sourceFactory.forUri(uriStr);

    // The URI cannot be resolved, we don't know the library.
    if (librarySource == null) return null;

    var libraryContext = elementFactory.libraryMap[uriStr];
    var libraryNode = libraryContext.node;
    var hasName = libraryNode.name.isNotEmpty;

    var definingUnitContext = libraryContext.definingUnit;

    var libraryElement = LibraryElementImpl.forLinkedNode(
      elementFactory.analysisContext,
      elementFactory.analysisSession,
      libraryNode.name,
      hasName ? libraryNode.nameOffset : -1,
      libraryNode.name.length,
      definingUnitContext,
      reference,
      definingUnitContext.unit_withDeclarations,
    );

    var units = <CompilationUnitElementImpl>[];
    var unitContainerRef = reference.getChild('@unit');
    for (var unitContext in libraryContext.units) {
      var unitNode = unitContext.unit_withDeclarations;

      var unitSource = sourceFactory.forUri(unitContext.uriStr);
      var unitElement = CompilationUnitElementImpl.forLinkedNode(
        libraryElement,
        unitContext,
        unitContext.reference,
        unitNode,
      );
      unitElement.lineInfo = unitNode.lineInfo;
      unitElement.source = unitSource;
      unitElement.librarySource = librarySource;
      units.add(unitElement);
      unitContainerRef.getChild(unitContext.uriStr).element = unitElement;
    }

    libraryElement.definingCompilationUnit = units[0];
    libraryElement.parts = units.skip(1).toList();
    reference.element = libraryElement;

    var typeProvider = elementFactory.analysisContext.typeProvider;
    if (typeProvider != null) {
      libraryElement.createLoadLibraryFunction(typeProvider);
    }

    return libraryElement;
  }

  EnumElementImpl _enum(CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node2 == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node2 != null, '$reference');
    }
    EnumElementImpl.forLinkedNode(unit, reference, reference.node2);
    return reference.element;
  }

  FieldElementImpl _field(ClassElementImpl enclosing, Reference reference) {
    enclosing.fields;
    // Requesting fields sets elements for all fields.
    assert(reference.element != null);
    return reference.element;
  }

  Element _function(CompilationUnitElementImpl enclosing, Reference reference) {
    enclosing.functions;
    assert(reference.element != null);
    return reference.element;
  }

  void _indexUnitElementDeclarations(CompilationUnitElementImpl unit) {
    var unitContext = unit.linkedContext;
    var unitRef = unit.reference;
    var unitNode = unit.linkedNode;
    _indexUnitDeclarations(unitContext, unitRef, unitNode);
  }

  MethodElementImpl _method(ClassElementImpl enclosing, Reference reference) {
    enclosing.methods;
    // Requesting methods sets elements for all of them.
    assert(reference.element != null);
    return reference.element;
  }

  MixinElementImpl _mixin(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node2 == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node2 != null, '$reference');
    }
    MixinElementImpl.forLinkedNode(unit, reference, reference.node2);
    return reference.element;
  }

  Element _parameter(ExecutableElementImpl enclosing, Reference reference) {
    enclosing.parameters;
    assert(reference.element != null);
    return reference.element;
  }

  PrefixElementImpl _prefix(LibraryElementImpl library, Reference reference) {
    for (var import in library.imports) {
      import.prefix;
    }
    assert(reference.element != null);
    return reference.element;
  }

  GenericTypeAliasElementImpl _typeAlias(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node2 == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node2 != null, '$reference');
    }
    GenericTypeAliasElementImpl.forLinkedNode(unit, reference, reference.node2);
    return reference.element;
  }

  /// Index nodes for which we choose to create elements individually,
  /// for example [ClassDeclaration], so that its [Reference] has the node,
  /// and we can call the [ClassElementImpl] constructor.
  static void _indexUnitDeclarations(
    LinkedUnitContext unitContext,
    Reference unitRef,
    CompilationUnit unitNode,
  ) {
    var classRef = unitRef.getChild('@class');
    var enumRef = unitRef.getChild('@enum');
    var functionRef = unitRef.getChild('@function');
    var mixinRef = unitRef.getChild('@mixin');
    var typeAliasRef = unitRef.getChild('@typeAlias');
    var variableRef = unitRef.getChild('@variable');
    for (var declaration in unitNode.declarations) {
      if (declaration is ClassDeclaration) {
        var name = declaration.name.name;
        classRef.getChild(name).node2 = declaration;
      } else if (declaration is ClassTypeAlias) {
        var name = declaration.name.name;
        classRef.getChild(name).node2 = declaration;
      } else if (declaration is EnumDeclaration) {
        var name = declaration.name.name;
        enumRef.getChild(name).node2 = declaration;
      } else if (declaration is FunctionDeclaration) {
        var name = declaration.name.name;
        functionRef.getChild(name).node2 = declaration;
      } else if (declaration is FunctionTypeAlias) {
        var name = declaration.name.name;
        typeAliasRef.getChild(name).node2 = declaration;
      } else if (declaration is GenericTypeAlias) {
        var name = declaration.name.name;
        typeAliasRef.getChild(name).node2 = declaration;
      } else if (declaration is MixinDeclaration) {
        var name = declaration.name.name;
        mixinRef.getChild(name).node2 = declaration;
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          var name = variable.name.name;
          variableRef.getChild(name).node2 = declaration;
        }
      }
    }
  }
}
