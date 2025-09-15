// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' as file_state;
import 'package:analyzer/src/dart/analysis/file_state.dart' hide DirectiveUri;
import 'package:analyzer/src/dart/analysis/unlinked_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart'
    as element_model;
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
import 'package:analyzer/src/summary2/element_builder.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/metadata_resolver.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

class DefiningLinkingUnit extends LinkingUnit {
  DefiningLinkingUnit({required super.node, required super.element});
}

class ImplicitEnumNodes {
  final EnumFragmentImpl fragment;
  final ast.NamedTypeImpl valuesTypeNode;
  final ast.VariableDeclarationImpl valuesNode;
  final FieldFragmentImpl valuesFragment;
  final Set<String> valuesNames;
  ast.ListLiteralImpl valuesInitializer;

  ImplicitEnumNodes({
    required this.fragment,
    required this.valuesTypeNode,
    required this.valuesNode,
    required this.valuesFragment,
    required this.valuesNames,
    required this.valuesInitializer,
  });
}

class LibraryBuilder {
  final Linker linker;
  final LibraryFileKind kind;
  final Uri uri;
  final Reference reference;
  final LibraryElementImpl element;
  final List<LinkingUnit> units;

  final Map<EnumFragmentImpl, ImplicitEnumNodes> implicitEnumNodes =
      Map.identity();

  /// Top fragments, in the same order as in AST.
  final Map<LibraryFragmentImpl, List<FragmentImpl>> _topFragments = {};

  /// Key: a parent fragment, e.g. [ClassFragmentImpl].
  /// Value: fragments of its direct children.
  ///
  /// For example `class A { void foo() {} }` has `foo` as child of `A`.
  final Map<FragmentImpl, List<FragmentImpl>> _parentChildFragments =
      Map.identity();

  /// Local declarations.
  final Map<String, Reference> _declaredReferences = {};

  /// The export scope of the library.
  ExportScope exportScope = ExportScope();

  /// The `export` directives that export this library.
  final List<Export> exports = [];

  /// The identifier of the reference used for unnamed fragments.
  int _nextUnnamedId = 0;

  /// The fields that were speculatively created as [FieldFragmentImpl],
  /// but we want to clear [VariableFragmentImpl.constantInitializer] for it
  /// if the class will not end up with a `const` constructor. We don't know
  /// at the time when we create them, because of future augmentations.
  final Set<FieldFragmentImpl> finalInstanceFields = Set.identity();

  LibraryBuilder._({
    required this.linker,
    required this.kind,
    required this.uri,
    required this.reference,
    required this.element,
    required this.units,
  });

  void addChildFragment(FragmentImpl parent, FragmentImpl child) {
    child.enclosingFragment = parent;
    (_parentChildFragments[parent] ??= []).add(child);
  }

  void addExporters() {
    for (var (fragmentIndex, fragment) in element.internal.fragments.indexed) {
      for (var (exportIndex, exportElement)
          in fragment.libraryExports.indexed) {
        var exportedLibrary = exportElement.exportedLibrary;
        if (exportedLibrary == null) {
          continue;
        }

        var exportedUri = exportedLibrary.uri;
        var exportedBuilder = linker.builders[exportedUri];
        var combinators = exportElement.combinators.build();

        var export = Export(
          exporter: this,
          location: ExportLocation(
            fragmentIndex: fragmentIndex,
            exportIndex: exportIndex,
          ),
          combinators: combinators,
        );
        if (exportedBuilder != null) {
          exportedBuilder.exports.add(export);
        } else {
          var exportedReferences = exportedLibrary.exportedReferences;
          for (var exported in exportedReferences) {
            var reference = exported.reference;
            var name = reference.name;
            if (reference.isSetter) {
              export.addToExportScope('$name=', exported);
            } else {
              export.addToExportScope(name, exported);
            }
          }
        }
      }
    }
  }

  void addTopFragment(LibraryFragmentImpl parent, FragmentImpl fragment) {
    fragment.enclosingFragment = parent;
    (_topFragments[parent] ??= []).add(fragment);
  }

  void buildClassSyntheticConstructors() {
    for (var classElement in element.children) {
      if (classElement is! ClassElementImpl) continue;
      if (classElement.isMixinApplication) continue;
      if (classElement.constructors.isNotEmpty) continue;

      var fragment = ConstructorFragmentImpl(name: 'new')..isSynthetic = true;
      fragment.typeName = classElement.name;
      classElement.firstFragment.constructors = [fragment].toFixedList();

      classElement.constructors = [
        ConstructorElementImpl(
          name: fragment.name,
          reference: classElement.reference
              .getChild('@constructor')
              .addChild('new'),
          firstFragment: fragment,
        ),
      ];
    }
  }

  /// Build elements for declarations in the library units, add top-level
  /// declarations to the local scope, for combining into export scopes.
  void buildElements() {
    _buildDirectives(kind: kind, containerUnit: element.firstFragment);

    for (var linkingUnit in units) {
      var elementBuilder = FragmentBuilder(
        libraryBuilder: this,
        unitElement: linkingUnit.element,
      );
      elementBuilder.buildDirectives(linkingUnit.node);
      elementBuilder.buildDeclarationFragments(linkingUnit.node);
      if (linkingUnit is DefiningLinkingUnit) {
        elementBuilder.buildLibraryMetadata(linkingUnit.node);
      }
    }

    ElementBuilder(libraryBuilder: this).buildElements(
      topFragments: _topFragments,
      parentChildFragments: _parentChildFragments,
    );

    for (var linkingUnit in units) {
      InformativeDataApplier().applyFromNode(
        linkingUnit.element,
        linkingUnit.node,
      );
    }

    _declareDartCoreDynamicNever();
  }

  void buildEnumChildren() {
    var typeProvider = element.typeProvider;
    for (var enum_ in implicitEnumNodes.values) {
      enum_.fragment.element.supertype =
          typeProvider.enumType ?? typeProvider.objectType;
      var valuesType = typeProvider.listType(
        element.typeSystem.instantiateInterfaceToBounds(
          element: enum_.fragment.asElement2,
          nullabilitySuffix: typeProvider.objectType.nullabilitySuffix,
        ),
      );
      enum_.valuesTypeNode.type = valuesType;
      enum_.valuesFragment.element.type = valuesType;
    }
  }

  void buildEnumSyntheticConstructors() {
    bool hasConstructor(EnumElementImpl enumElement) {
      for (var constructor in enumElement.constructors) {
        if (constructor.isGenerative || constructor.name == 'new') {
          return true;
        }
      }
      return false;
    }

    for (var enumElement in element.enums) {
      if (hasConstructor(enumElement)) continue;

      var constructorFragment = ConstructorFragmentImpl(name: 'new')
        ..isConst = true
        ..isSynthetic = true
        ..typeName = enumElement.name;
      enumElement.firstFragment.addConstructor(constructorFragment);

      var constructorElement = ConstructorElementImpl(
        name: constructorFragment.name,
        reference: enumElement.reference
            .getChild('@constructor')
            .addChild('new'),
        firstFragment: constructorFragment,
      );
      enumElement.addConstructor(constructorElement);
    }
  }

  void buildInitialExportScope() {
    exportScope = ExportScope();
    _declaredReferences.forEach((name, reference) {
      if (name.startsWith('_')) return;
      if (reference.isPrefix) return;
      exportScope.declare(name, reference);
    });
  }

  void collectMixinSuperInvokedNames() {
    for (var linkingUnit in units) {
      for (var declaration in linkingUnit.node.declarations) {
        if (declaration is ast.MixinDeclarationImpl) {
          var names = <String>{};
          var collector = MixinSuperInvokedNamesCollector(names);
          for (var executable in declaration.members) {
            if (executable is ast.MethodDeclarationImpl) {
              executable.body.accept(collector);
            }
          }
          var fragment = declaration.declaredFragment!;
          fragment.superInvokedNames = names.sorted();
        }
      }
    }
  }

  /// Computes which fields in this library are promotable.
  void computeFieldPromotability() {
    _FieldPromotability(
      this,
      enabled: element.featureSet.isEnabled(Feature.inference_update_2),
    ).perform();
  }

  void declare(Element element, Reference reference) {
    if (element.lookupName case var lookupName?) {
      _declaredReferences[lookupName] = reference;
    }
  }

  String getReferenceName(String? name) {
    return name ?? '${_nextUnnamedId++}';
  }

  void replaceConstFieldsIfNoConstConstructor() {
    var hasConstConstructorCache = <InterfaceElement, bool>{};

    bool hasConstConstructor(Element element) {
      if (element is InterfaceElement) {
        var result = hasConstConstructorCache[element];
        if (result == null) {
          result = element.constructors.any((e) => e.isConst);
          hasConstConstructorCache[element] = result;
        }
        return result;
      }
      return false;
    }

    for (var fieldFragment in finalInstanceFields) {
      var enclosingElement = fieldFragment.enclosingFragment.element;
      if (!hasConstConstructor(enclosingElement)) {
        fieldFragment.constantInitializer = null;
      }
    }
  }

  void resolveConstructorFieldFormals() {
    for (var interfaceElement in element.children) {
      if (interfaceElement is! InterfaceElementImpl) {
        continue;
      }

      if (interfaceElement is ClassElementImpl &&
          interfaceElement.isMixinApplication) {
        continue;
      }

      for (var constructor in interfaceElement.constructors) {
        for (var parameter in constructor.formalParameters) {
          if (parameter is FieldFormalParameterElementImpl) {
            parameter.field = interfaceElement.getField(parameter.name ?? '');
          }
        }
      }
    }
  }

  void resolveConstructors() {
    ConstructorInitializerResolver(linker, this).resolve();
  }

  void resolveDefaultValues() {
    DefaultValueResolver(linker, this).resolve();
  }

  void resolveMetadata() {
    for (var linkingUnit in units) {
      var resolver = MetadataResolver(linker, linkingUnit.element, this);
      linkingUnit.node.accept(resolver);
    }
  }

  void resolveTypes(NodesToBuildType nodesToBuildType) {
    for (var linkingUnit in units) {
      var resolver = ReferenceResolver(
        linker,
        nodesToBuildType,
        element.typeSystem,
        linkingUnit.element.scope,
      );
      linkingUnit.node.accept(resolver);
    }
  }

  void setDefaultSupertypes() {
    var shouldResetClassHierarchies = false;
    var objectType = element.typeProvider.objectType;

    for (var classElement in element.classes) {
      if (!classElement.isDartCoreObject) {
        if (classElement.supertype == null) {
          shouldResetClassHierarchies = true;
          classElement.supertype = objectType;
        }
      }
    }

    for (var mixinElement in element.mixins) {
      if (mixinElement.superclassConstraints.isEmpty) {
        shouldResetClassHierarchies = true;
        mixinElement.superclassConstraints = [objectType];
      }
    }

    if (shouldResetClassHierarchies) {
      element.session.classHierarchy.removeOfLibraries({uri});
    }
  }

  void storeExportScope() {
    element.exportedReferences = exportScope.toReferences();

    var definedNames = <String, Element>{};
    for (var entry in exportScope.map.entries) {
      var reference = entry.value.reference;
      var element = linker.elementFactory.elementOfReference3(reference);
      definedNames[entry.key] = element;
    }

    var namespace = Namespace(definedNames);
    element.exportNamespace = namespace;

    var entryPoint = namespace.get2(TopLevelFunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is TopLevelFunctionElementImpl) {
      element.entryPoint = entryPoint;
    }
  }

  List<NamespaceCombinator> _buildCombinators(
    List<UnlinkedCombinator> combinators2,
  ) {
    return combinators2.map((unlinked) {
      if (unlinked.isShow) {
        return ShowElementCombinatorImpl()
          ..offset = unlinked.keywordOffset
          ..end = unlinked.endOffset
          ..shownNames = unlinked.names;
      } else {
        return HideElementCombinatorImpl()
          ..offset = unlinked.keywordOffset
          ..end = unlinked.endOffset
          ..hiddenNames = unlinked.names;
      }
    }).toFixedList();
  }

  /// Builds directive elements, for the library and recursively for its
  /// augmentations.
  void _buildDirectives({
    required FileKind kind,
    required LibraryFragmentImpl containerUnit,
  }) {
    containerUnit.libraryExports = kind.libraryExports.map((state) {
      return _buildLibraryExport(state);
    }).toFixedList();

    containerUnit.libraryImports = kind.libraryImports.map((state) {
      return _buildLibraryImport(containerUnit: containerUnit, state: state);
    }).toFixedList();

    containerUnit.parts = kind.partIncludes.map((partState) {
      return _buildPartInclude(
        containerLibrary: element,
        containerUnit: containerUnit,
        state: partState,
      );
    }).toFixedList();
  }

  LibraryExportImpl _buildLibraryExport(LibraryExportState state) {
    var combinators = _buildCombinators(state.unlinked.combinators);

    DirectiveUri uri;
    switch (state) {
      case LibraryExportWithFile():
        var exportedLibraryKind = state.exportedLibrary;
        if (exportedLibraryKind != null) {
          var exportedFile = exportedLibraryKind.file;
          var exportedUri = exportedFile.uri;
          var elementFactory = linker.elementFactory;
          var exportedLibrary = elementFactory.libraryOfUri2(exportedUri);
          uri = DirectiveUriWithLibraryImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: exportedLibrary.source,
            library: exportedLibrary,
          );
        } else {
          uri = DirectiveUriWithSourceImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: state.exportedSource,
          );
        }
      case LibraryExportWithInSummarySource():
        var exportedLibrarySource = state.exportedLibrarySource;
        if (exportedLibrarySource != null) {
          var exportedUri = exportedLibrarySource.uri;
          var elementFactory = linker.elementFactory;
          var exportedLibrary = elementFactory.libraryOfUri2(exportedUri);
          uri = DirectiveUriWithLibraryImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: exportedLibrary.source,
            library: exportedLibrary,
          );
        } else {
          uri = DirectiveUriWithSourceImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: state.exportedSource,
          );
        }
      default:
        var selectedUri = state.selectedUri;
        switch (selectedUri) {
          case file_state.DirectiveUriWithUri():
            uri = DirectiveUriWithRelativeUriImpl(
              relativeUriString: selectedUri.relativeUriStr,
              relativeUri: selectedUri.relativeUri,
            );
          case file_state.DirectiveUriWithString():
            uri = DirectiveUriWithRelativeUriStringImpl(
              relativeUriString: selectedUri.relativeUriStr,
            );
          default:
            uri = DirectiveUriImpl();
        }
    }

    return LibraryExportImpl(
      combinators: combinators,
      exportKeywordOffset: state.unlinked.exportKeywordOffset,
      uri: uri,
    );
  }

  LibraryImportImpl _buildLibraryImport({
    required LibraryFragmentImpl containerUnit,
    required LibraryImportState state,
  }) {
    var prefixFragment = state.unlinked.prefix.mapOrNull((unlinked) {
      return _buildLibraryImportPrefixFragment(
        libraryFragment: containerUnit,
        unlinkedName: unlinked.name,
        offset: unlinked.nameOffset,
        isDeferred: unlinked.deferredOffset != null,
      );
    });

    var combinators = _buildCombinators(state.unlinked.combinators);

    DirectiveUri uri;
    switch (state) {
      case LibraryImportWithFile():
        var importedLibraryKind = state.importedLibrary;
        if (importedLibraryKind != null) {
          var importedFile = importedLibraryKind.file;
          var importedUri = importedFile.uri;
          var elementFactory = linker.elementFactory;
          var importedLibrary = elementFactory.libraryOfUri2(importedUri);
          uri = DirectiveUriWithLibraryImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: importedLibrary.source,
            library: importedLibrary,
          );
        } else {
          uri = DirectiveUriWithSourceImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: state.importedSource,
          );
        }
      case LibraryImportWithInSummarySource():
        var importedLibrarySource = state.importedLibrarySource;
        if (importedLibrarySource != null) {
          var importedUri = importedLibrarySource.uri;
          var elementFactory = linker.elementFactory;
          var importedLibrary = elementFactory.libraryOfUri2(importedUri);
          uri = DirectiveUriWithLibraryImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: importedLibrary.source,
            library: importedLibrary,
          );
        } else {
          uri = DirectiveUriWithSourceImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: state.importedSource,
          );
        }
      default:
        var selectedUri = state.selectedUri;
        switch (selectedUri) {
          case file_state.DirectiveUriWithUri():
            uri = DirectiveUriWithRelativeUriImpl(
              relativeUriString: selectedUri.relativeUriStr,
              relativeUri: selectedUri.relativeUri,
            );
          case file_state.DirectiveUriWithString():
            uri = DirectiveUriWithRelativeUriStringImpl(
              relativeUriString: selectedUri.relativeUriStr,
            );
          default:
            uri = DirectiveUriImpl();
        }
    }

    return LibraryImportImpl(
      isSynthetic: state.isSyntheticDartCore,
      combinators: combinators,
      importKeywordOffset: state.unlinked.importKeywordOffset,
      prefix: prefixFragment,
      uri: uri,
    );
  }

  PrefixFragmentImpl _buildLibraryImportPrefixFragment({
    required LibraryFragmentImpl libraryFragment,
    required UnlinkedLibraryImportPrefixName? unlinkedName,
    required int offset,
    required bool isDeferred,
  }) {
    var fragment = PrefixFragmentImpl(
      name: unlinkedName?.name,
      firstTokenOffset: null,
      nameOffset: unlinkedName?.nameOffset,
      isDeferred: isDeferred,
    )..offset = offset;
    fragment.enclosingFragment = libraryFragment;

    var refName = getReferenceName(unlinkedName?.name);
    var reference = this.reference
        .getChild('@fragment')
        .getChild('${libraryFragment.source.uri}')
        .getChild('@prefix2')
        .getChild(refName);
    var element = reference.element as PrefixElementImpl?;

    if (element == null) {
      element = PrefixElementImpl(
        reference: reference,
        firstFragment: fragment,
      );
    } else {
      element.addFragment(fragment);
    }

    fragment.element = element;
    return fragment;
  }

  PartIncludeImpl _buildPartInclude({
    required LibraryElementImpl containerLibrary,
    required LibraryFragmentImpl containerUnit,
    required file_state.PartIncludeState state,
  }) {
    DirectiveUriImpl directiveUri;
    switch (state) {
      case PartIncludeWithFile():
        var includedPart = state.includedPart;
        if (includedPart != null) {
          var partFile = includedPart.file;
          var partUnitNode = partFile.parse(
            performance: OperationPerformanceImpl('<root>'),
          );
          var unitElement = LibraryFragmentImpl(
            library: containerLibrary,
            source: partFile.source,
            lineInfo: partUnitNode.lineInfo,
          );
          partUnitNode.declaredFragment = unitElement;
          unitElement.isSynthetic = !partFile.exists;
          unitElement.setCodeRange(0, partUnitNode.length);

          units.add(LinkingUnit(node: partUnitNode, element: unitElement));

          _buildDirectives(kind: includedPart, containerUnit: unitElement);

          directiveUri = DirectiveUriWithUnitImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            libraryFragment: unitElement,
          );
        } else {
          directiveUri = DirectiveUriWithSourceImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            source: state.includedFile.source,
          );
        }
      default:
        var uriState = state.selectedUri;
        switch (uriState) {
          case file_state.DirectiveUriWithSource():
            directiveUri = DirectiveUriWithSourceImpl(
              relativeUriString: uriState.relativeUriStr,
              relativeUri: uriState.relativeUri,
              source: uriState.source,
            );
          case file_state.DirectiveUriWithUri():
            directiveUri = DirectiveUriWithRelativeUriImpl(
              relativeUriString: uriState.relativeUriStr,
              relativeUri: uriState.relativeUri,
            );
          case file_state.DirectiveUriWithString():
            directiveUri = DirectiveUriWithRelativeUriStringImpl(
              relativeUriString: uriState.relativeUriStr,
            );
          default:
            directiveUri = DirectiveUriImpl();
        }
    }

    return PartIncludeImpl(
      partKeywordOffset: state.unlinked.partKeywordOffset,
      uri: directiveUri,
    );
  }

  /// We want to have stable references for `loadLibrary` function. But we
  /// cannot create the function itself right now, because the type provider
  /// might be not available yet. So, we create references together with the
  /// library, and create the fragment and element later.
  void _createLoadLibraryReferences() {
    var name = TopLevelFunctionElement.LOAD_LIBRARY_NAME;

    var elementContainer = reference.getChild('@function');
    var elementReference = elementContainer.addChild(name);

    element.loadLibraryProvider = LoadLibraryFunctionProvider(
      elementReference: elementReference,
    );
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (reference.name == 'dart:core') {
      var dynamicRef = reference.getChild('dynamic');
      dynamicRef.element = DynamicElementImpl.instance;
      declare(DynamicElementImpl.instance, dynamicRef);

      var neverRef = reference.getChild('Never');
      neverRef.element = NeverElementImpl.instance;
      declare(NeverElementImpl.instance, neverRef);
    }
  }

  static void build({
    required Linker linker,
    required LibraryFileKind inputLibrary,
    required OperationPerformanceImpl performance,
  }) {
    var elementFactory = linker.elementFactory;
    var rootReference = linker.rootReference;

    var libraryFile = inputLibrary.file;
    var libraryUriStr = libraryFile.uriStr;
    var libraryReference = rootReference.getChild(libraryUriStr);

    var libraryUnitNode = performance.run('libraryFile', (performance) {
      return libraryFile.parse(performance: performance);
    });

    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in libraryUnitNode.directives) {
      if (directive is ast.LibraryDirectiveImpl) {
        var nameIdentifier = directive.name;
        if (nameIdentifier != null) {
          name = nameIdentifier.components.map((e) => e.name).join('.');
          nameOffset = nameIdentifier.offset;
          nameLength = nameIdentifier.length;
        }
        break;
      }
    }

    var libraryElement = LibraryElementImpl(
      elementFactory.analysisContext,
      elementFactory.analysisSession,
      name,
      nameOffset,
      nameLength,
      libraryUnitNode.featureSet,
    );
    libraryElement.isSynthetic = !libraryFile.exists;
    libraryElement.languageVersion = libraryUnitNode.languageVersion;
    libraryElement.reference = libraryReference;
    libraryReference.element = libraryElement;

    var linkingUnits = <LinkingUnit>[];
    {
      var unitElement = LibraryFragmentImpl(
        library: libraryElement,
        source: libraryFile.source,
        lineInfo: libraryUnitNode.lineInfo,
      );
      libraryUnitNode.declaredFragment = unitElement;
      unitElement.isSynthetic = !libraryFile.exists;
      unitElement.setCodeRange(0, libraryUnitNode.length);

      linkingUnits.add(
        DefiningLinkingUnit(node: libraryUnitNode, element: unitElement),
      );

      libraryElement.firstFragment = unitElement;
    }

    var builder = LibraryBuilder._(
      linker: linker,
      kind: inputLibrary,
      uri: libraryFile.uri,
      reference: libraryReference,
      element: libraryElement,
      units: linkingUnits,
    );

    builder._createLoadLibraryReferences();
    elementFactory.setLibraryTypeSystem(libraryElement);

    linker.builders[builder.uri] = builder;
  }
}

class LinkingUnit {
  final ast.CompilationUnitImpl node;
  final LibraryFragmentImpl element;

  LinkingUnit({required this.node, required this.element});
}

/// This class examines all the [InterfaceElementImpl]s in a library and
/// determines which fields are promotable within that library.
class _FieldPromotability
    extends
        FieldPromotability<
          InterfaceElementImpl,
          FieldElementImpl,
          GetterElementImpl
        > {
  /// The [_libraryBuilder] for the library being analyzed.
  final LibraryBuilder _libraryBuilder;

  final bool enabled;

  /// Fields that might be promotable, if not marked unpromotable later.
  final List<FieldElementImpl> _potentiallyPromotableFields = [];

  _FieldPromotability(this._libraryBuilder, {required this.enabled});

  @override
  Iterable<InterfaceElementImpl> getSuperclasses(
    InterfaceElementImpl class_, {
    required bool ignoreImplements,
  }) {
    var result = <InterfaceElementImpl>[];

    var supertype = class_.supertype;
    if (supertype != null) {
      result.add(supertype.element);
    }

    for (var mixin in class_.mixins) {
      result.add(mixin.element);
    }

    if (!ignoreImplements) {
      for (var interface in class_.interfaces) {
        result.add(interface.element);
      }
      if (class_ is MixinElementImpl) {
        for (var constraint in class_.superclassConstraints) {
          result.add(constraint.element);
        }
      }
    }

    return result;
  }

  /// Computes which fields are promotable and updates their `isPromotable`
  /// properties accordingly.
  void perform() {
    // Iterate through all the classes, enums, and mixins in the library,
    // recording the non-synthetic instance fields and getters of each.
    var element = _libraryBuilder.element;
    for (var class_ in element.classes) {
      _handleMembers(addClass(class_, isAbstract: class_.isAbstract), class_);
    }
    for (var enum_ in element.enums) {
      _handleMembers(addClass(enum_, isAbstract: false), enum_);
    }
    for (var mixin_ in element.mixins) {
      _handleMembers(addClass(mixin_, isAbstract: true), mixin_);
    }

    // Private representation fields of extension types are always promotable.
    // They also don't affect promotability of any other fields.
    for (var extensionType in element.extensionTypes) {
      var representation = extensionType.representation;
      var representationName = representation.name;
      if (representationName != null) {
        if (representationName.startsWith('_')) {
          representation.firstFragment.isPromotable = true;
        }
      }
    }

    // Compute the set of field names that are not promotable.
    var fieldNonPromotabilityInfo = computeNonPromotabilityInfo();

    // Set the `isPromotable` bit for each field element that *is* promotable.
    for (var field in _potentiallyPromotableFields) {
      if (fieldNonPromotabilityInfo[field.name!] == null) {
        field.firstFragment.isPromotable = true;
      }
    }

    element.fieldNameNonPromotabilityInfo = {
      for (var MapEntry(:key, :value) in fieldNonPromotabilityInfo.entries)
        key: element_model.FieldNameNonPromotabilityInfo(
          conflictingFields: value.conflictingFields,
          conflictingGetters: value.conflictingGetters,
          conflictingNsmClasses: value.conflictingNsmClasses,
        ),
    };
  }

  /// Records all the non-synthetic instance fields and getters of [class_]
  /// into [classInfo].
  void _handleMembers(
    ClassInfo<InterfaceElementImpl> classInfo,
    InterfaceElementImpl class_,
  ) {
    for (var field in class_.fields) {
      if (field.isStatic || field.isSynthetic) {
        continue;
      }

      var fieldName = field.name;
      if (fieldName != null) {
        var nonPromotabilityReason = addField(
          classInfo,
          field,
          fieldName,
          isFinal: field.isFinal,
          isAbstract: field.isAbstract,
          isExternal: field.isExternal,
        );
        if (enabled && nonPromotabilityReason == null) {
          _potentiallyPromotableFields.add(field);
        }
      }
    }

    for (var getter in class_.getters) {
      if (getter.isStatic || getter.isSynthetic) {
        continue;
      }

      var getterName = getter.name;
      if (getterName != null) {
        var nonPromotabilityReason = addGetter(
          classInfo,
          getter,
          getterName,
          isAbstract: getter.isAbstract,
        );
        if (enabled && nonPromotabilityReason == null) {
          var field = getter.variable as FieldElementImpl;
          _potentiallyPromotableFields.add(field);
        }
      }
    }
  }
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    var self = this;
    return self != null ? mapper(self) : null;
  }
}
