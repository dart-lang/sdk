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
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/linked_library_context.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

class LinkedElementFactory {
  final AnalysisContextImpl analysisContext;
  final AnalysisSessionImpl analysisSession;
  final Reference rootReference;
  final Map<String, List<Reference>> linkingExports = {};
  final Map<String, LibraryReader> libraryReaders = {};

  LinkedElementFactory(
    this.analysisContext,
    this.analysisSession,
    this.rootReference,
  ) {
    ArgumentError.checkNotNull(analysisContext, 'analysisContext');
    ArgumentError.checkNotNull(analysisSession, 'analysisSession');
    _declareDartCoreDynamicNever();
  }

  Reference get dynamicRef {
    return rootReference.getChild('dart:core').getChild('dynamic');
  }

  bool get hasDartCore {
    return libraryReaders.containsKey('dart:core');
  }

  void addBundle(BundleReader bundle) {
    addLibraries(bundle.libraryMap);
  }

  void addLibraries(Map<String, LibraryReader> libraries) {
    libraryReaders.addAll(libraries);
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

  LibraryElementImpl createLibraryElementForLinking(
    LinkedLibraryContext libraryContext,
  ) {
    var sourceFactory = analysisContext.sourceFactory;
    var libraryUriStr = libraryContext.uriStr;
    var librarySource = sourceFactory.forUri(libraryUriStr);

    // The URI cannot be resolved, we don't know the library.
    if (librarySource == null) return null;

    var definingUnitContext = libraryContext.units[0];
    var definingUnitNode = definingUnitContext.unit;

    // TODO(scheglov) Do we need this?
    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in definingUnitNode.directives) {
      if (directive is LibraryDirective) {
        name = directive.name.components.map((e) => e.name).join('.');
        nameOffset = directive.name.offset;
        nameLength = directive.name.length;
        break;
      }
    }

    var libraryElement = LibraryElementImpl.forLinkedNode(
      analysisContext,
      analysisSession,
      name,
      nameOffset,
      nameLength,
      definingUnitContext,
      libraryContext.reference,
      definingUnitNode,
    );
    _setLibraryTypeSystem(libraryElement);

    var units = <CompilationUnitElementImpl>[];
    var unitContainerRef = libraryContext.reference.getChild('@unit');
    for (var unitContext in libraryContext.units) {
      var unitNode = unitContext.unit;

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
    libraryContext.reference.element = libraryElement;

    return libraryElement;
  }

  LibraryElementImpl createLibraryElementForReading(String uriStr) {
    var sourceFactory = analysisContext.sourceFactory;
    var librarySource = sourceFactory.forUri(uriStr);

    // The URI cannot be resolved, we don't know the library.
    if (librarySource == null) return null;

    var reader = libraryReaders[uriStr];
    if (reader == null) {
      throw ArgumentError(
        'Missing library: $uriStr\n'
        'Available libraries: ${libraryReaders.keys.toList()}',
      );
    }

    var libraryContext = LinkedLibraryContext(this, uriStr, reader.reference);
    var unitContainerRef = reader.reference.getChild('@unit');

    var unitContexts = <LinkedUnitContext>[];
    var indexInLibrary = 0;
    var unitReaders = reader.units;
    for (var unitReader in unitReaders) {
      var unitReference = unitContainerRef.getChild(unitReader.uriStr);
      var unitContext = LinkedUnitContext(
        libraryContext,
        indexInLibrary++,
        unitReader.partUriStr,
        unitReader.uriStr,
        unitReference,
        unitReader.isSynthetic,
        unit: unitReader.unit,
        unitReader: unitReader,
      );
      unitContexts.add(unitContext);
      libraryContext.units.add(unitContext);
    }

    var definingUnitContext = unitContexts[0];
    var libraryElement = LibraryElementImpl.forLinkedNode(
      analysisContext,
      analysisSession,
      reader.name,
      reader.nameOffset,
      reader.nameLength,
      definingUnitContext,
      reader.reference,
      unitReaders.first.unit,
    );
    _setLibraryTypeSystem(libraryElement);

    var units = <CompilationUnitElementImpl>[];
    for (var unitContext in unitContexts) {
      var unitNode = unitContext.unit;

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
    reader.reference.element = libraryElement;

    return libraryElement;
  }

  void createTypeProviders(
    LibraryElementImpl /*!*/ dartCore,
    LibraryElementImpl /*!*/ dartAsync,
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

    if (reference.isLibrary) {
      var uriStr = reference.name;
      return createLibraryElementForReading(uriStr);
    }

    var parent = reference.parent.parent;
    var parentElement = elementOfReference(parent);

    // Named formal parameters are created when we apply resolution to the
    // executable declaration, e.g. a constructor, or a method.
    if (reference.isParameter) {
      (parentElement as ExecutableElement).parameters;
      assert(reference.element != null);
      return reference.element;
    }

    // The default constructor might be synthetic, and has no node.
    // TODO(scheglov) We resynthesize all constructors here.
    if (reference.isConstructor && reference.name == '') {
      return (parentElement as ClassElement).unnamedConstructor;
    }

    if (parentElement is EnumElementImpl) {
      parentElement.constants;
      assert(reference.element != null);
      return reference.element;
    }

    if (reference.element != null) {
      return reference.element;
    }

    if (reference.isUnit) {
      assert(reference.element != null);
      return reference.element;
    }

    if (reference.isPrefix) {
      (parentElement as LibraryElement).prefixes;
      assert(reference.element != null);
      return reference.element;
    }

    // For class, mixin, extension - index members.
    parent.nodeAccessor.readIndex();

    // For any element - class, method, etc - read the node.
    var node = reference.nodeAccessor.node;

    if (node is ClassDeclaration) {
      ClassElementImpl.forLinkedNode(parentElement, reference, node);
      assert(reference.element != null);
      return reference.element;
    } else if (node is ClassTypeAlias) {
      ClassElementImpl.forLinkedNode(parentElement, reference, node);
      assert(reference.element != null);
      return reference.element;
    } else if (node is ConstructorDeclaration) {
      ConstructorElementImpl.forLinkedNode(parentElement, reference, node);
      var element = reference.element as ConstructorElementImpl;
      assert(element != null);
      return element;
    } else if (node is EnumDeclaration) {
      EnumElementImpl.forLinkedNode(parentElement, reference, node);
      assert(reference.element != null);
      return reference.element;
    } else if (node is ExtensionDeclaration) {
      ExtensionElementImpl.forLinkedNode(parentElement, reference, node);
      assert(reference.element != null);
      return reference.element;
    } else if (node is FieldDeclaration) {
      var variable = _variableDeclaration(node.fields, reference.name);
      if (variable.isConst) {
        ConstFieldElementImpl.forLinkedNode(parentElement, reference, variable);
      } else {
        FieldElementImpl.forLinkedNodeFactory(
            parentElement, reference, variable);
      }
      assert(reference.element != null);
      return reference.element;
    } else if (node is FunctionDeclaration) {
      if (node.propertyKeyword != null) {
        _topLevelPropertyAccessor(parent, parentElement, reference, node);
      } else {
        FunctionElementImpl.forLinkedNode(parentElement, reference, node);
      }
      assert(reference.element != null);
      return reference.element;
    } else if (node is FunctionTypeAlias || node is GenericTypeAlias) {
      TypeAliasElementImpl.forLinkedNodeFactory(parentElement, reference, node);
      assert(reference.element != null);
      return reference.element;
    } else if (node is MethodDeclaration) {
      if (node.propertyKeyword != null) {
        PropertyAccessorElementImpl.forLinkedNode(
            parentElement, reference, node);
      } else {
        MethodElementImpl.forLinkedNode(parentElement, reference, node);
      }
      assert(reference.element != null);
      return reference.element;
    } else if (node is MixinDeclaration) {
      MixinElementImpl.forLinkedNode(parentElement, reference, node);
      assert(reference.element != null);
      return reference.element;
    } else if (node is TopLevelVariableDeclaration) {
      var variable = _variableDeclaration(node.variables, reference.name);
      if (variable.isConst) {
        ConstTopLevelVariableElementImpl.forLinkedNode(
            parentElement, reference, variable);
      } else {
        TopLevelVariableElementImpl.forLinkedNode(
            parentElement, reference, variable);
      }
      assert(reference.element != null);
      return reference.element;
    }

    throw UnimplementedError('$reference');
  }

  List<Reference> exportsOfLibrary(String uriStr) {
    var linkingExportedReferences = linkingExports[uriStr];
    if (linkingExportedReferences != null) {
      return linkingExportedReferences;
    }

    var library = libraryReaders[uriStr];
    if (library == null) return const [];

    return library.exports;
  }

  bool hasLibrary(String uriStr) {
    return libraryReaders[uriStr] != null;
  }

  bool isLibraryUri(String uriStr) {
    var libraryContext = libraryReaders[uriStr];
    return !libraryContext.hasPartOfDirective;
  }

  LibraryElementImpl libraryOfUri(String uriStr) {
    var reference = rootReference.getChild(uriStr);
    return elementOfReference(reference);
  }

  /// We have linked the bundle, and need to disconnect its libraries, so
  /// that the client can re-add the bundle, this time read from bytes.
  void removeBundle(Set<String> uriStrSet) {
    removeLibraries(uriStrSet);

    // This is the bundle with dart:core and dart:async, based on full ASTs.
    // To link them, the linker set the type provider. We are removing these
    // libraries, and we should also remove the type provider.
    if (uriStrSet.contains('dart:core')) {
      if (!uriStrSet.contains('dart:async')) {
        throw StateError(
          'Expected to link dart:core and dart:async together: '
          '${uriStrSet.toList()}',
        );
      }
      if (libraryReaders.isNotEmpty) {
        throw StateError(
          'Expected to link dart:core and dart:async first: '
          '${libraryReaders.keys.toList()}',
        );
      }
      analysisContext.clearTypeProvider();
      _declareDartCoreDynamicNever();
    }
  }

  /// Remove libraries with the specified URIs from the reference tree, and
  /// any session level caches.
  void removeLibraries(Set<String> uriStrSet) {
    for (var uriStr in uriStrSet) {
      libraryReaders.remove(uriStr);
      linkingExports.remove(uriStr);
      rootReference.removeChild(uriStr);
    }

    analysisSession.classHierarchy.removeOfLibraries(uriStrSet);
    analysisSession.inheritanceManager.removeOfLibraries(uriStrSet);
  }

  void _declareDartCoreDynamicNever() {
    var dartCoreRef = rootReference.getChild('dart:core');
    dartCoreRef.getChild('dynamic').element = DynamicElementImpl.instance;
    dartCoreRef.getChild('Never').element = NeverElementImpl.instance;
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

  void _topLevelPropertyAccessor(
    Reference parentReference,
    CompilationUnitElementImpl parentElement,
    Reference reference,
    FunctionDeclaration node,
  ) {
    var accessor = PropertyAccessorElementImpl.forLinkedNode(
        parentElement, reference, node);

    var name = reference.name;
    var fieldRef = parentReference.getChild('@field').getChild(name);
    var field = fieldRef.element as TopLevelVariableElementImpl;
    if (field == null) {
      field = TopLevelVariableElementImpl(name, -1);
      fieldRef.element = field;
      field.enclosingElement = parentElement;
      field.isFinal = true;
      field.isSynthetic = true;
    }

    var isSetter = node.isSetter;
    if (isSetter) {
      field.isFinal = false;
    }

    accessor.variable = field;
    if (isSetter) {
      field.setter = accessor;
    } else {
      field.getter = accessor;
    }
  }

  static VariableDeclaration _variableDeclaration(
    VariableDeclarationList variableList,
    String name,
  ) {
    for (var variable in variableList.variables) {
      if (variable.name.name == name) {
        return variable;
      }
    }
    throw StateError('No "$name" in: $variableList');
  }
}
