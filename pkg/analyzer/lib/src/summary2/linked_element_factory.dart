// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/core_types.dart';
import 'package:analyzer/src/summary2/lazy_ast.dart';
import 'package:analyzer/src/summary2/linked_bundle_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class LinkedElementFactory {
  final AnalysisContextImpl analysisContext;
  final AnalysisSessionImpl analysisSession;
  final Reference rootReference;
  final Map<String, LinkedLibraryContext> libraryMap = {};

  CoreTypes _coreTypes;

  LinkedElementFactory(
    this.analysisContext,
    this.analysisSession,
    this.rootReference,
  ) {
    ArgumentError.checkNotNull(analysisContext, 'analysisContext');
    ArgumentError.checkNotNull(analysisSession, 'analysisSession');
    var dartCoreRef = rootReference.getChild('dart:core');
    dartCoreRef.getChild('dynamic').element = DynamicElementImpl.instance;
    dartCoreRef.getChild('Never').element = NeverElementImpl.instance;
  }

  CoreTypes get coreTypes {
    return _coreTypes ??= CoreTypes(this);
  }

  Reference get dynamicRef {
    return rootReference.getChild('dart:core').getChild('dynamic');
  }

  bool get hasDartCore {
    return libraryMap.containsKey('dart:core');
  }

  void addBundle(LinkedBundleContext context) {
    libraryMap.addAll(context.libraryMap);
  }

  Namespace buildExportNamespace(Uri uri) {
    var exportedNames = <String, Element>{};

    var exportedReferences = exportsOfLibrary('$uri');
    for (var exportedReference in exportedReferences) {
      var element = elementOfReference(exportedReference);
      // TODO(scheglov) Remove after https://github.com/dart-lang/sdk/issues/41212
      if (element == null) {
        throw StateError(
          '[No element]'
          '[uri: $uri]'
          '[exportedReferences: $exportedReferences]'
          '[exportedReference: $exportedReference]',
        );
      }
      exportedNames[element.name] = element;
    }

    return Namespace(exportedNames);
  }

  void createTypeProviders(
    LibraryElementImpl dartCore,
    LibraryElementImpl dartAsync,
  ) {
    if (analysisContext.typeProviderNonNullableByDefault != null) {
      return;
    }

    analysisContext.setTypeProviders(
      legacy: TypeProviderImpl(
        coreLibrary: dartCore,
        asyncLibrary: dartAsync,
        isNonNullableByDefault: false,
      ),
      nonNullableByDefault: TypeProviderImpl(
        coreLibrary: dartCore,
        asyncLibrary: dartAsync,
        isNonNullableByDefault: true,
      ),
    );

    // During linking we create libraries when typeProvider is not ready.
    // Update these libraries now, when typeProvider is ready.
    for (var reference in rootReference.children) {
      var libraryElement = reference.element as LibraryElementImpl;
      if (libraryElement != null && libraryElement.typeProvider == null) {
        _setLibraryTypeSystem(libraryElement);
      }
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
    if (library == null) return const [];

    // Ask for source to trigger dependency tracking.
    //
    // Usually we record a dependency because we request an element from a
    // library, so we build its library element, so request its source.
    // However if a library is just exported, and the exporting library is not
    // imported itself, we just copy references, without computing elements.
    analysisContext.sourceFactory.forUri(uriStr);

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

  /// We have linked the bundle, and need to disconnect its libraries, so
  /// that the client can re-add the bundle, this time read from bytes.
  void removeBundle(LinkedBundleContext context) {
    // TODO(scheglov) Use removeLibraries()
    for (var uriStr in context.libraryMap.keys) {
      libraryMap.remove(uriStr);
      rootReference.removeChild(uriStr);
    }

    var classHierarchy = analysisSession.classHierarchy;
    classHierarchy.removeOfLibraries(context.libraryMap.keys);
  }

  /// Remove libraries with the specified URIs from the reference tree, and
  /// any session level caches.
  void removeLibraries(List<String> uriStrList) {
    for (var uriStr in uriStrList) {
      libraryMap.remove(uriStr);
      rootReference.removeChild(uriStr);
    }

    var classHierarchy = analysisSession.classHierarchy;
    classHierarchy.removeOfLibraries(uriStrList);
  }

  /// Set optional informative data for the unit.
  void setInformativeData(
    String libraryUriStr,
    String unitUriStr,
    List<UnlinkedInformativeData> informativeData,
  ) {
    var libraryContext = libraryMap[libraryUriStr];
    if (libraryContext != null) {
      for (var unitContext in libraryContext.units) {
        if (unitContext.uriStr == unitUriStr) {
          unitContext.informativeData = informativeData;
          return;
        }
      }
    }
  }

  void _setLibraryTypeSystem(LibraryElementImpl libraryElement) {
    // During linking we create libraries when typeProvider is not ready.
    // And if we link dart:core and dart:async, we cannot create it.
    // We will set typeProvider later, during [createTypeProviders].
    if (analysisContext.typeProviderNonNullableByDefault == null) {
      return;
    }

    var isNonNullable = libraryElement.isNonNullableByDefault;
    libraryElement.typeProvider = isNonNullable
        ? analysisContext.typeProviderNonNullableByDefault
        : analysisContext.typeProviderLegacy;
    libraryElement.typeSystem = isNonNullable
        ? analysisContext.typeSystemNonNullableByDefault
        : analysisContext.typeSystemLegacy;

    libraryElement.createLoadLibraryFunction();
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

    if (parentName == '@extension') {
      var unit = elementOfReference(parent2);
      return _extension(unit, reference);
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

    if (reference.name == '@function' && parent2.name == '@typeAlias') {
      var parent = reference.parent;
      GenericTypeAliasElementImpl alias = elementOfReference(parent);
      return alias.function;
    }

    throw StateError('Not found: $input');
  }

  PropertyAccessorElementImpl _accessor(
      ElementImpl enclosing, Reference reference) {
    if (enclosing is ClassElementImpl) {
      enclosing.accessors;
    } else if (enclosing is CompilationUnitElementImpl) {
      enclosing.accessors;
    } else if (enclosing is EnumElementImpl) {
      enclosing.accessors;
    } else if (enclosing is ExtensionElementImpl) {
      enclosing.accessors;
    } else {
      throw StateError('${enclosing.runtimeType}');
    }
    // Requesting accessors sets elements for accessors and variables.
    assert(reference.element != null);
    return reference.element;
  }

  ClassElementImpl _class(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node != null, '$reference');
    }
    ClassElementImpl.forLinkedNode(unit, reference, reference.node);
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
    if (libraryContext == null) {
      throw ArgumentError(
        'Missing library: $uriStr\n'
        'Available libraries: ${elementFactory.libraryMap.keys.toList()}',
      );
    }
    var libraryNode = libraryContext.node;
    var hasName = libraryNode.name.isNotEmpty;

    var definingUnitContext = libraryContext.definingUnit;

    var libraryElement = LibraryElementImpl.forLinkedNode(
      elementFactory.analysisContext,
      elementFactory.analysisSession,
      libraryNode.name,
      hasName ? libraryNode.nameOffset : -1,
      libraryNode.nameLength,
      definingUnitContext,
      reference,
      definingUnitContext.unit_withDeclarations,
    );
    elementFactory._setLibraryTypeSystem(libraryElement);

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
      unitElement.uri = unitContext.partUriStr;
      units.add(unitElement);
      unitContainerRef.getChild(unitContext.uriStr).element = unitElement;
    }

    libraryElement.definingCompilationUnit = units[0];
    libraryElement.parts = units.skip(1).toList();
    reference.element = libraryElement;

    return libraryElement;
  }

  EnumElementImpl _enum(CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node != null, '$reference');
    }
    EnumElementImpl.forLinkedNode(unit, reference, reference.node);
    return reference.element;
  }

  ExtensionElementImpl _extension(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node != null, '$reference');
    }
    ExtensionElementImpl.forLinkedNode(unit, reference, reference.node);
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

  MethodElementImpl _method(ElementImpl enclosing, Reference reference) {
    if (enclosing is ClassElementImpl) {
      enclosing.methods;
    } else if (enclosing is ExtensionElementImpl) {
      enclosing.methods;
    } else {
      throw StateError('${enclosing.runtimeType}');
    }
    // Requesting methods sets elements for all of them.
    assert(reference.element != null);
    return reference.element;
  }

  MixinElementImpl _mixin(
      CompilationUnitElementImpl unit, Reference reference) {
    if (reference.node == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node != null, '$reference');
    }
    MixinElementImpl.forLinkedNode(unit, reference, reference.node);
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
    if (reference.node == null) {
      _indexUnitElementDeclarations(unit);
      assert(reference.node != null, '$reference');
    }
    GenericTypeAliasElementImpl.forLinkedNode(unit, reference, reference.node);
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
    var extensionRef = unitRef.getChild('@extension');
    var functionRef = unitRef.getChild('@function');
    var mixinRef = unitRef.getChild('@mixin');
    var typeAliasRef = unitRef.getChild('@typeAlias');
    var variableRef = unitRef.getChild('@variable');
    for (var declaration in unitNode.declarations) {
      if (declaration is ClassDeclaration) {
        var name = declaration.name.name;
        classRef.getChild(name).node = declaration;
      } else if (declaration is ClassTypeAlias) {
        var name = declaration.name.name;
        classRef.getChild(name).node = declaration;
      } else if (declaration is ExtensionDeclaration) {
        var refName = LazyExtensionDeclaration.get(declaration).refName;
        extensionRef.getChild(refName).node = declaration;
      } else if (declaration is EnumDeclaration) {
        var name = declaration.name.name;
        enumRef.getChild(name).node = declaration;
      } else if (declaration is FunctionDeclaration) {
        var name = declaration.name.name;
        functionRef.getChild(name).node = declaration;
      } else if (declaration is FunctionTypeAlias) {
        var name = declaration.name.name;
        typeAliasRef.getChild(name).node = declaration;
      } else if (declaration is GenericTypeAlias) {
        var name = declaration.name.name;
        typeAliasRef.getChild(name).node = declaration;
      } else if (declaration is MixinDeclaration) {
        var name = declaration.name.name;
        mixinRef.getChild(name).node = declaration;
      } else if (declaration is TopLevelVariableDeclaration) {
        for (var variable in declaration.variables.variables) {
          var name = variable.name.name;
          variableRef.getChild(name).node = declaration;
        }
      }
    }
  }
}
