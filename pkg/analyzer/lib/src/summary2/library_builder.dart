// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/field_promotability.dart';
import 'package:_fe_analyzer_shared/src/macros/code_optimizer.dart' as macro;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' as file_state;
import 'package:analyzer/src/dart/analysis/file_state.dart' hide DirectiveUri;
import 'package:analyzer/src/dart/analysis/info_declaration_store.dart';
import 'package:analyzer/src/dart/analysis/unlinked_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/mixin_super_invoked_names.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/field_name_non_promotability_info.dart'
    as element_model;
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/summary2/augmentation.dart';
import 'package:analyzer/src/summary2/combinator.dart';
import 'package:analyzer/src/summary2/constructor_initializer_resolver.dart';
import 'package:analyzer/src/summary2/default_value_resolver.dart';
import 'package:analyzer/src/summary2/element_builder.dart';
import 'package:analyzer/src/summary2/export.dart';
import 'package:analyzer/src/summary2/informative_data.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro_application.dart';
import 'package:analyzer/src/summary2/macro_application_error.dart';
import 'package:analyzer/src/summary2/macro_merge.dart';
import 'package:analyzer/src/summary2/macro_not_allowed_declaration.dart';
import 'package:analyzer/src/summary2/metadata_resolver.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/summary2/reference_resolver.dart';
import 'package:analyzer/src/summary2/types_builder.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:macros/src/executor.dart' as macro;

class DefiningLinkingUnit extends LinkingUnit {
  DefiningLinkingUnit({
    required super.reference,
    required super.node,
    required super.element,
    required super.container,
  });
}

class ImplicitEnumNodes {
  final EnumElementImpl element;
  final ast.NamedTypeImpl valuesTypeNode;
  final ast.VariableDeclarationImpl valuesNode;
  final ConstFieldElementImpl valuesElement;
  final Set<String> valuesNames;
  ast.ListLiteralImpl valuesInitializer;

  ImplicitEnumNodes({
    required this.element,
    required this.valuesTypeNode,
    required this.valuesNode,
    required this.valuesElement,
    required this.valuesNames,
    required this.valuesInitializer,
  });
}

class LibraryBuilder with MacroApplicationsContainer {
  static const _enableMacroCodeOptimizer = false;

  final Linker linker;
  final LibraryFileKind kind;
  final Uri uri;
  final Reference reference;
  final LibraryElementImpl element;
  final List<LinkingUnit> units;

  final Map<EnumElementImpl, ImplicitEnumNodes> implicitEnumNodes =
      Map.identity();

  /// The top-level elements that can be augmented.
  final Map<String, AugmentedInstanceDeclarationBuilder> _augmentedBuilders =
      {};

  /// The top-level variables and accessors that can be augmented.
  late final AugmentedTopVariablesBuilder topVariables =
      AugmentedTopVariablesBuilder(_augmentationTargets);

  /// The top-level elements that can be augmented.
  final Map<String, ElementImpl> _augmentationTargets = {};

  /// Local declarations.
  final Map<String, Reference> _declaredReferences = {};

  /// The export scope of the library.
  ExportScope exportScope = ExportScope();

  /// The `export` directives that export this library.
  final List<Export> exports = [];

  /// The fields that were speculatively created as [ConstFieldElementImpl],
  /// but we want to clear [ConstVariableElement.constantInitializer] for it
  /// if the class will not end up with a `const` constructor. We don't know
  /// at the time when we create them, because of future augmentations, user
  /// written or macro generated.
  final Set<ConstFieldElementImpl> finalInstanceFields = Set.identity();

  /// Set if the library reuses the cached macro result.
  PartIncludeWithFile? inputMacroPartInclude;

  /// The sink for macro applying facts, for caching.
  final MacroProcessing macroProcessing = MacroProcessing();

  final List<List<macro.MacroExecutionResult>> _macroResults = [];

  LibraryBuilder._({
    required this.linker,
    required this.kind,
    required this.uri,
    required this.reference,
    required this.element,
    required this.units,
  });

  void addExporters() {
    for (var (fragmentIndex, fragment) in element.units.indexed) {
      for (var (exportIndex, exportElement)
          in fragment.libraryExports.indexed) {
        var exportedLibrary = exportElement.exportedLibrary;
        if (exportedLibrary == null) {
          continue;
        }

        var exportedUri = exportedLibrary.source.uri;
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

  void buildClassSyntheticConstructors() {
    bool hasConstructor(ClassElementImpl element) {
      if (element.constructors.isNotEmpty) return true;
      if (element.augmentation case var augmentation?) {
        return hasConstructor(augmentation);
      }
      return false;
    }

    for (var classElement in element.topLevelElements) {
      if (classElement is! ClassElementImpl) continue;
      if (classElement.isMixinApplication) continue;
      if (classElement.augmentationTarget != null) continue;
      if (hasConstructor(classElement)) continue;

      var constructor = ConstructorElementImpl('', -1)..isSynthetic = true;
      var containerRef = classElement.reference!.getChild('@constructor');
      var reference = containerRef.getChild('new');
      reference.element = constructor;
      constructor.reference = reference;

      classElement.constructors = [constructor].toFixedList();

      if (classElement.augmented case AugmentedClassElementImpl augmented) {
        augmented.constructors = classElement.constructors;
      }
    }
  }

  /// Build elements for declarations in the library units, add top-level
  /// declarations to the local scope, for combining into export scopes.
  void buildElements() {
    _buildDirectives(
      kind: kind,
      containerLibrary: element,
      containerUnit: element.definingCompilationUnit,
    );

    for (var linkingUnit in units) {
      var elementBuilder = ElementBuilder(
        libraryBuilder: this,
        unitReference: linkingUnit.reference,
        unitElement: linkingUnit.element,
      );
      elementBuilder.buildDirectiveElements(linkingUnit.node);
      elementBuilder.buildDeclarationElements(linkingUnit.node);
      if (linkingUnit is DefiningLinkingUnit) {
        elementBuilder.buildLibraryMetadata(linkingUnit.node);
      }
    }

    _declareDartCoreDynamicNever();
  }

  void buildEnumChildren() {
    var typeProvider = element.typeProvider;
    for (var enum_ in implicitEnumNodes.values) {
      enum_.element.supertype =
          typeProvider.enumType ?? typeProvider.objectType;
      var valuesType = typeProvider.listType(
        element.typeSystem.instantiateInterfaceToBounds(
          element: enum_.element,
          nullabilitySuffix: typeProvider.objectType.nullabilitySuffix,
        ),
      );
      enum_.valuesTypeNode.type = valuesType;
      enum_.valuesElement.type = valuesType;
    }
  }

  void buildEnumSyntheticConstructors() {
    bool hasConstructor(EnumElementImpl element) {
      for (var constructor in element.augmented.constructors) {
        if (constructor.isGenerative || constructor.name == '') {
          return true;
        }
      }
      return false;
    }

    for (var enumElement in element.topLevelElements) {
      if (enumElement is! EnumElementImpl) continue;
      if (enumElement.augmentationTarget != null) continue;
      if (hasConstructor(enumElement)) continue;

      var constructor = ConstructorElementImpl('', -1)
        ..isConst = true
        ..isSynthetic = true;
      var containerRef = enumElement.reference!.getChild('@constructor');
      var reference = containerRef.getChild('new');
      reference.element = constructor;
      constructor.reference = reference;

      enumElement.constructors = [
        ...enumElement.constructors,
        constructor,
      ].toFixedList();

      if (enumElement.augmented case AugmentedEnumElementImpl augmented) {
        augmented.constructors = enumElement.constructors;
      }
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
          var element = declaration.declaredElement as MixinElementImpl;
          element.superInvokedNames = names.toList();
        }
      }
    }
  }

  /// Computes which fields in this library are promotable.
  void computeFieldPromotability() {
    _FieldPromotability(this,
            enabled: element.featureSet.isEnabled(Feature.inference_update_2))
        .perform();
  }

  void declare(String name, Reference reference) {
    _declaredReferences[name] = reference;
  }

  void disposeMacroApplications() {
    var macroApplier = linker.macroApplier;
    if (macroApplier == null) {
      return;
    }

    macroApplier.disposeMacroApplications(
      libraryBuilder: this,
    );
  }

  /// Completes with `true` if a macro application was run in this library.
  ///
  /// Completes with `false` if there are no macro applications to run, either
  /// because we ran all, or those that we have not run yet have dependencies
  /// of interfaces declared in other libraries that, and we have not run yet
  /// declarations phase macro applications for them.
  Future<MacroDeclarationsPhaseStepResult> executeMacroDeclarationsPhase({
    required ElementImpl? targetElement,
    required OperationPerformanceImpl performance,
  }) async {
    if (!element.featureSet.isEnabled(Feature.macros)) {
      return MacroDeclarationsPhaseStepResult.nothing;
    }

    var macroApplier = linker.macroApplier;
    if (macroApplier == null) {
      return MacroDeclarationsPhaseStepResult.nothing;
    }

    var applicationResult = await performance.runAsync(
      'macroApplier.executeDeclarationsPhase',
      (performance) async {
        return await macroApplier.executeDeclarationsPhase(
          libraryBuilder: this,
          targetElement: targetElement,
          performance: performance,
        );
      },
    );

    // No more applications to execute.
    if (applicationResult == null) {
      return MacroDeclarationsPhaseStepResult.nothing;
    }

    await performance.runAsync(
      'addMacroResults',
      (performance) async {
        await _addMacroResults(
          macroApplier,
          applicationResult,
          phase: macro.Phase.declarations,
          performance: performance,
        );
      },
    );

    // Check if a new top-level declaration was added.
    var augmentationUnit = units.last.element;
    if (augmentationUnit.functions.isNotEmpty ||
        augmentationUnit.topLevelVariables.isNotEmpty) {
      element.resetScope();
      return MacroDeclarationsPhaseStepResult.topDeclaration;
    }

    // Probably class member declarations.
    return MacroDeclarationsPhaseStepResult.otherProgress;
  }

  Future<void> executeMacroDefinitionsPhase({
    required OperationPerformanceImpl performance,
  }) async {
    if (!element.featureSet.isEnabled(Feature.macros)) {
      return;
    }

    var macroApplier = linker.macroApplier;
    if (macroApplier == null) {
      return;
    }

    while (true) {
      var applicationResult = await performance.runAsync(
        'macroApplier.executeDefinitionsPhase',
        (performance) async {
          return await macroApplier.executeDefinitionsPhase(
            libraryBuilder: this,
            performance: performance,
          );
        },
      );

      // No more applications to execute.
      if (applicationResult == null) {
        return;
      }

      await performance.runAsync(
        'addMacroResults',
        (performance) async {
          await _addMacroResults(
            macroApplier,
            applicationResult,
            phase: macro.Phase.definitions,
            performance: performance,
          );
        },
      );
    }
  }

  Future<void> executeMacroTypesPhase({
    required OperationPerformanceImpl performance,
  }) async {
    if (!element.featureSet.isEnabled(Feature.macros)) {
      return;
    }

    var macroApplier = linker.macroApplier;
    if (macroApplier == null) {
      return;
    }

    while (true) {
      var applicationResult = await performance.runAsync(
        'macroApplier.executeTypesPhase',
        (performance) async {
          return await macroApplier.executeTypesPhase(
            libraryBuilder: this,
          );
        },
      );

      // No more applications to execute.
      if (applicationResult == null) {
        break;
      }

      await performance.runAsync(
        'addMacroResults',
        (performance) async {
          await _addMacroResults(
            macroApplier,
            applicationResult,
            phase: macro.Phase.types,
            performance: performance,
          );
        },
      );
    }
  }

  /// Fills with macro applications in user code.
  Future<void> fillMacroApplier(LibraryMacroApplier macroApplier) async {
    for (var linkingUnit in units) {
      await macroApplier.add(
        libraryBuilder: this,
        container: linkingUnit.element,
        unit: linkingUnit.node,
      );
    }
  }

  AugmentedInstanceDeclarationBuilder? getAugmentedBuilder(String name) {
    return _augmentedBuilders[name];
  }

  MacroResultOutput? getCacheableMacroResult() {
    // Nothing if we already reuse a cached result.
    if (inputMacroPartInclude != null) {
      return null;
    }

    var macroImport = kind.partIncludes.lastOrNull;
    if (macroImport is file_state.PartIncludeWithFile) {
      var includedFile = macroImport.includedFile;
      if (includedFile.isMacroPart) {
        return MacroResultOutput(
          library: kind,
          processing: macroProcessing,
          code: includedFile.content,
        );
      }
    }

    return null;
  }

  /// Merges accumulated [_macroResults] and corresponding macro augmentation
  /// libraries into a single macro augmentation library.
  Future<void> mergeMacroAugmentations({
    required OperationPerformanceImpl performance,
  }) async {
    var macroApplier = linker.macroApplier;
    if (macroApplier == null) {
      return;
    }

    var augmentationCode = performance.run(
      'buildAugmentationLibraryCode',
      (performance) {
        var code = macroApplier.buildAugmentationLibraryCode(
          uri,
          _macroResults.flattenedToList,
        );
        // TODO(scheglov): Replace when the framework is migrated.
        return code?.replaceAll(
          'augment library ',
          'part of ',
        );
      },
    );
    if (augmentationCode == null) {
      return;
    }

    kind.disposeMacroAugmentations(disposeFiles: true);

    // Remove import for partial macro augmentations.
    element.definingCompilationUnit.parts = element
        .definingCompilationUnit.parts
        .take(
            element.definingCompilationUnit.parts.length - _macroResults.length)
        .toFixedList();

    // Remove units with partial macro augmentations.
    var partialUnits = units.sublist(units.length - _macroResults.length);
    units.length -= _macroResults.length;

    List<macro.Edit> optimizedCodeEdits;
    String optimizedCode;
    if (_enableMacroCodeOptimizer) {
      optimizedCodeEdits = _CodeOptimizer(
        elementFactory: linker.elementFactory,
      ).optimize(
        augmentationCode,
        libraryDeclarationNames: element.definingCompilationUnit.children
            .map((e) => e.name)
            .nonNulls
            .toSet(),
        scannerConfiguration: Scanner.buildConfig(kind.file.featureSet),
      );
      optimizedCode = macro.Edit.applyList(
        optimizedCodeEdits,
        augmentationCode,
      );
    } else {
      optimizedCodeEdits = [];
      optimizedCode = augmentationCode;
    }

    var partIncludeState = performance.run(
      'kind.addMacroAugmentation',
      (performance) {
        return kind.addMacroPart(
          optimizedCode,
          partialIndex: null,
          performance: performance,
        );
      },
    );
    var includedPart = partIncludeState.includedPart!;
    var includedFile = includedPart.file;

    var includedFileParsed = includedFile.getParsed(
      performance: performance,
    );
    var unitNode = includedFileParsed.unit;

    var unitElement = CompilationUnitElementImpl(
      library: element,
      source: includedFile.source,
      lineInfo: unitNode.lineInfo,
    );
    unitElement.setCodeRange(0, unitNode.length);

    var unitReference =
        reference.getChild('@fragment').getChild(includedFile.uriStr);
    _bindReference(unitReference, unitElement);

    var informativeBytes = includedFile.unlinked2.informativeBytes;
    unitElement.macroGenerated = MacroGeneratedLibraryFragment(
      code: includedFile.content,
      informativeBytes: informativeBytes,
    );

    _buildDirectives(
      kind: includedPart,
      containerLibrary: element,
      containerUnit: unitElement,
    );

    MacroElementsMerger(
      partialUnits: partialUnits,
      unitReference: unitReference,
      unitNode: unitNode,
      unitElement: unitElement,
    ).perform(updateConstants: () {
      if (optimizedCodeEdits.isNotEmpty) {
        var mergedUnit = performance.run(
          'mergedUnit',
          (performance) {
            performance.getDataInt('length').add(augmentationCode.length);
            return kind.file.parseCode(
              code: augmentationCode,
              errorListener: AnalysisErrorListener.NULL_LISTENER,
              performance: performance,
            );
          },
        );

        MacroUpdateConstantsForOptimizedCode(
          libraryElement: element,
          unitNode: mergedUnit,
          codeEdits: optimizedCodeEdits,
          unitElement: unitElement,
        ).perform();
      }
    });

    var importUri = DirectiveUriWithUnitImpl(
      relativeUriString: partIncludeState.selectedUri.relativeUriStr,
      relativeUri: partIncludeState.selectedUri.relativeUri,
      unit: unitElement,
    );

    var partInclude = PartElementImpl(
      uri: importUri,
    );
    partInclude.isSynthetic = true;

    element.definingCompilationUnit.parts = [
      ...element.definingCompilationUnit.parts,
      partInclude,
    ].toFixedList();

    // Set offsets the same way as when reading from summary.
    InformativeDataApplier(
      linker.elementFactory,
      {},
      NoOpInfoDeclarationStore(),
    ).applyToUnit(unitElement, informativeBytes);
  }

  void putAugmentedBuilder(
    String name,
    AugmentedInstanceDeclarationBuilder element,
  ) {
    _augmentedBuilders[name] = element;
  }

  void replaceConstFieldsIfNoConstConstructor() {
    var withConstConstructors = Set<ClassElementImpl>.identity();
    for (var classElement in element.topLevelElements) {
      if (classElement is! ClassElementImpl) continue;
      if (classElement.isMixinApplication) continue;
      if (classElement.isAugmentation) continue;
      var hasConst = classElement.augmented.constructors.any((e) => e.isConst);
      if (hasConst) {
        withConstConstructors.add(classElement);
      }
    }

    for (var fieldElement in finalInstanceFields) {
      var enclosing = fieldElement.enclosingElement3;
      var augmented = enclosing.ifTypeOrNull<ClassElementImpl>()?.augmented;
      if (augmented == null) continue;
      if (!withConstConstructors.contains(augmented.declaration)) {
        fieldElement.constantInitializer = null;
      }
    }
  }

  void resolveConstructorFieldFormals() {
    for (var interface in element.topLevelElements) {
      if (interface is! InterfaceElementImpl) {
        continue;
      }

      if (interface is ClassElementImpl && interface.isMixinApplication) {
        continue;
      }

      var augmented = interface.augmented;
      for (var constructor in interface.constructors) {
        for (var parameter in constructor.parameters) {
          if (parameter is FieldFormalParameterElementImpl) {
            parameter.field = augmented.getField(parameter.name);
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
    for (var interface in element.topLevelElements) {
      switch (interface) {
        case ClassElementImpl():
          if (interface.augmentationTarget != null) continue;
          if (interface.isDartCoreObject) continue;
          if (interface.supertype == null) {
            shouldResetClassHierarchies = true;
            interface.supertype = objectType;
          }
        case MixinElementImpl():
          if (interface.augmentationTarget != null) continue;
          var augmented = interface.augmented;
          if (augmented.superclassConstraints.isEmpty) {
            shouldResetClassHierarchies = true;
            interface.superclassConstraints = [objectType];
            if (augmented is AugmentedMixinElementImpl) {
              augmented.superclassConstraints = [objectType];
            }
          }
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
      var element = linker.elementFactory.elementOfReference(reference);
      if (element != null) {
        definedNames[entry.key] = element;
      }
    }

    var namespace = Namespace(definedNames);
    element.exportNamespace = namespace;

    var entryPoint = namespace.get(FunctionElement.MAIN_FUNCTION_NAME);
    if (entryPoint is FunctionElement) {
      element.entryPoint = entryPoint;
    }
  }

  void updateAugmentationTarget<T extends ElementImpl>(
    String name,
    AugmentableElement<T> augmentation,
  ) {
    if (augmentation.isAugmentation) {
      var target = _augmentationTargets[name];
      target ??= topVariables.accessors[name];
      target ??= topVariables.accessors['$name='];

      augmentation.augmentationTargetAny = target;
      switch (target) {
        case null:
          _augmentationTargets[name] = augmentation;
        case AugmentableElement<T> target:
          augmentation.isAugmentationChainStart = false;
          target.augmentation = augmentation as T;
          _augmentationTargets[name] = augmentation;
      }
    } else {
      _augmentationTargets[name] = augmentation;
    }
  }

  /// Updates the element of the macro augmentation.
  void updateInputMacroAugmentation() {
    if (inputMacroPartInclude case var import?) {
      var partInclude = element.units.last;
      var includedFile = import.includedFile;
      var informativeBytes = includedFile.unlinked2.informativeBytes;
      partInclude.macroGenerated = MacroGeneratedLibraryFragment(
        code: includedFile.content,
        informativeBytes: informativeBytes,
      );
    }
  }

  CompilationUnitElementImpl _addMacroAugmentation(
    PartIncludeWithFile state, {
    required OperationPerformanceImpl performance,
  }) {
    // TODO(scheglov): measure performance
    var partInclude = _buildPartInclude(
      containerLibrary: element,
      containerUnit: element.definingCompilationUnit,
      state: state,
    );
    partInclude.isSynthetic = true;
    element.definingCompilationUnit.parts = [
      ...element.definingCompilationUnit.parts,
      partInclude,
    ].toFixedList();

    // TODO(scheglov): add like `LibraryElementImpl? get importedLibrary`
    var partUri = partInclude.uri as DirectiveUriWithUnitImpl;
    var includedUnit = partUri.unit;
    includedUnit.macroGenerated = MacroGeneratedLibraryFragment(
      code: state.includedFile.content,
      informativeBytes: state.includedFile.unlinked2.informativeBytes,
    );

    return includedUnit;
  }

  /// Add results from the declarations or definitions phase.
  Future<void> _addMacroResults(
    LibraryMacroApplier macroApplier,
    ApplicationResult applicationResult, {
    required macro.Phase phase,
    required OperationPerformanceImpl performance,
  }) async {
    // No results from the application.
    var results = applicationResult.results;
    if (results.isEmpty) {
      return;
    }

    var augmentationCode = performance.run(
      'buildAugmentationLibraryCode',
      (performance) {
        var code = macroApplier.buildAugmentationLibraryCode(
          uri,
          results,
        );
        // TODO(scheglov): Replace when the framework is migrated.
        return code?.replaceAll(
          'augment library ',
          'part of ',
        );
      },
    );
    if (augmentationCode == null) {
      return;
    }

    var importState = performance.run(
      'kind.addMacroAugmentation',
      (performance) {
        performance.getDataInt('length').add(augmentationCode.length);
        return kind.addMacroPart(
          augmentationCode,
          partialIndex: _macroResults.length,
          performance: performance,
        );
      },
    );

    var unitElement = performance.run(
      '_addMacroAugmentation',
      (performance) {
        return _addMacroAugmentation(
          importState,
          performance: performance,
        );
      },
    );
    var macroLinkingUnit = units.last;

    // If the generated code contains declarations that are not allowed at
    // this phase, then add a diagnostic, and discard the code.
    var notAllowed = findDeclarationsNotAllowedAtPhase(
      unit: macroLinkingUnit.node,
      phase: phase,
    );
    if (notAllowed.isNotEmpty) {
      var application = applicationResult.application;
      application.target.element.addMacroDiagnostic(
        NotAllowedDeclarationDiagnostic(
          annotationIndex: application.annotationIndex,
          phase: phase,
          code: augmentationCode,
          nodeRanges: notAllowed
              .map((node) => SourceRange(node.offset, node.length))
              .toList(),
        ),
      );
      units.removeLast();
      element.definingCompilationUnit.parts =
          element.definingCompilationUnit.parts.withoutLast.toFixedList();
      kind.removeLastMacroPartInclude();
      return;
    }

    performance.run('elements + types', (performance) {
      ElementBuilder(
        libraryBuilder: this,
        unitReference: macroLinkingUnit.reference,
        unitElement: macroLinkingUnit.element,
      ).buildDeclarationElements(macroLinkingUnit.node);

      if (phase != macro.Phase.types) {
        var nodesToBuildType = NodesToBuildType();
        var resolver = ReferenceResolver(
          linker,
          nodesToBuildType,
          element.typeSystem,
          macroLinkingUnit.element.scope,
        );
        macroLinkingUnit.node.accept(resolver);
        TypesBuilder(linker).build(nodesToBuildType);
      }
    });

    _macroResults.add(results);

    // Append applications from the partial augmentation.
    await macroApplier.add(
      libraryBuilder: this,
      container: unitElement,
      unit: macroLinkingUnit.node,
    );
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
    required LibraryOrAugmentationElementImpl containerLibrary,
    required CompilationUnitElementImpl containerUnit,
  }) {
    containerUnit.libraryExports = kind.libraryExports.map((state) {
      return _buildLibraryExport(state);
    }).toFixedList();

    containerUnit.libraryImports = kind.libraryImports.map((state) {
      return _buildLibraryImport(
        containerLibrary: containerLibrary,
        containerUnit: containerUnit,
        state: state,
      );
    }).toFixedList();

    containerUnit.parts = kind.partIncludes.map((partState) {
      return _buildPartInclude(
        containerLibrary: element,
        containerUnit: containerUnit,
        state: partState,
      );
    }).toFixedList();
  }

  LibraryExportElementImpl _buildLibraryExport(LibraryExportState state) {
    var combinators = _buildCombinators(
      state.unlinked.combinators,
    );

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

    return LibraryExportElementImpl(
      combinators: combinators,
      exportKeywordOffset: state.unlinked.exportKeywordOffset,
      uri: uri,
    );
  }

  LibraryImportElementImpl _buildLibraryImport({
    required LibraryOrAugmentationElementImpl containerLibrary,
    required CompilationUnitElementImpl containerUnit,
    required LibraryImportState state,
  }) {
    var importPrefix = state.unlinked.prefix.mapOrNull((unlinked) {
      var prefix = _buildLibraryImportPrefix(
        name: unlinked.name,
        nameOffset: unlinked.nameOffset,
        containerLibrary: containerLibrary,
        containerUnit: containerUnit,
      );
      if (unlinked.deferredOffset != null) {
        return DeferredImportElementPrefixImpl(
          element: prefix,
        );
      } else {
        return ImportElementPrefixImpl(
          element: prefix,
        );
      }
    });

    var prefixFragment = state.unlinked.prefix.mapOrNull((unlinked) {
      return _buildLibraryImportPrefixFragment(
        libraryFragment: containerUnit,
        name: unlinked.name,
        nameOffset: unlinked.nameOffset,
        isDeferred: unlinked.deferredOffset != null,
      );
    });

    var combinators = _buildCombinators(
      state.unlinked.combinators,
    );

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

    return LibraryImportElementImpl(
      combinators: combinators,
      importKeywordOffset: state.unlinked.importKeywordOffset,
      prefix: importPrefix,
      prefix2: prefixFragment,
      uri: uri,
    )..isSynthetic = state.isSyntheticDartCore;
  }

  PrefixElementImpl _buildLibraryImportPrefix({
    required String name,
    required int nameOffset,
    required LibraryOrAugmentationElementImpl containerLibrary,
    required CompilationUnitElementImpl containerUnit,
  }) {
    // TODO(scheglov): Make reference required.
    var containerRef = containerUnit.reference!;
    var reference = containerRef.getChild('@prefix').getChild(name);
    var existing = reference.element;
    if (existing is PrefixElementImpl) {
      return existing;
    } else {
      var result = PrefixElementImpl(
        name,
        nameOffset,
        reference: reference,
      );
      result.enclosingElement = containerLibrary;
      result.enclosingElement3 = containerUnit;
      return result;
    }
  }

  PrefixFragmentImpl _buildLibraryImportPrefixFragment({
    required CompilationUnitElementImpl libraryFragment,
    required String name,
    required int nameOffset,
    required bool isDeferred,
  }) {
    var fragment = PrefixFragmentImpl(
      enclosingFragment: libraryFragment,
      name: name,
      nameOffset: nameOffset,
      isDeferred: isDeferred,
    );

    var containerRef = libraryFragment.reference!;
    var reference = containerRef.getChild('@prefix2').getChild(name);
    var element = reference.element2 as PrefixElementImpl2?;

    if (element == null) {
      element = PrefixElementImpl2(
        reference: reference,
        firstFragment: fragment,
      );
    } else {
      element.addFragment(fragment);
    }

    fragment.element = element;
    return fragment;
  }

  PartElementImpl _buildPartInclude({
    required LibraryElementImpl containerLibrary,
    required CompilationUnitElementImpl containerUnit,
    required file_state.PartIncludeState state,
  }) {
    DirectiveUri directiveUri;
    switch (state) {
      case PartIncludeWithFile():
        var includedPart = state.includedPart;
        if (includedPart != null) {
          var partFile = includedPart.file;
          var partUnitNode = partFile.parse(
            performance: OperationPerformanceImpl('<root>'),
          );
          var unitElement = CompilationUnitElementImpl(
            library: containerLibrary,
            source: partFile.source,
            lineInfo: partUnitNode.lineInfo,
          );
          partUnitNode.declaredElement = unitElement;
          unitElement.isSynthetic = !partFile.exists;
          unitElement.uri = partFile.uriStr;
          unitElement.setCodeRange(0, partUnitNode.length);

          var unitReference =
              reference.getChild('@fragment').getChild(partFile.uriStr);
          _bindReference(unitReference, unitElement);

          units.add(
            LinkingUnit(
              reference: unitReference,
              node: partUnitNode,
              container: containerLibrary,
              element: unitElement,
            ),
          );

          _buildDirectives(
            kind: includedPart,
            containerLibrary: element,
            containerUnit: unitElement,
          );

          directiveUri = DirectiveUriWithUnitImpl(
            relativeUriString: state.selectedUri.relativeUriStr,
            relativeUri: state.selectedUri.relativeUri,
            unit: unitElement,
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

    return PartElementImpl(
      uri: directiveUri,
    );
  }

  /// These elements are implicitly declared in `dart:core`.
  void _declareDartCoreDynamicNever() {
    if (reference.name == 'dart:core') {
      var dynamicRef = reference.getChild('dynamic');
      dynamicRef.element = DynamicElementImpl.instance;
      declare('dynamic', dynamicRef);

      var neverRef = reference.getChild('Never');
      neverRef.element = NeverElementImpl.instance;
      declare('Never', neverRef);
    }
  }

  static void build({
    required Linker linker,
    required LibraryFileKind inputLibrary,
    required MacroResultInput? inputMacroResult,
    required OperationPerformanceImpl performance,
  }) {
    var elementFactory = linker.elementFactory;
    var rootReference = linker.rootReference;

    var libraryFile = inputLibrary.file;
    var libraryUriStr = libraryFile.uriStr;
    var libraryReference = rootReference.getChild(libraryUriStr);

    var libraryUnitNode = performance.run('libraryFile', (performance) {
      return libraryFile.parse(
        performance: performance,
      );
    });

    var name = '';
    var nameOffset = -1;
    var nameLength = 0;
    for (var directive in libraryUnitNode.directives) {
      if (directive is ast.LibraryDirectiveImpl) {
        var nameIdentifier = directive.name2;
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
    libraryElement.languageVersion = libraryUnitNode.languageVersion!;
    _bindReference(libraryReference, libraryElement);
    elementFactory.setLibraryTypeSystem(libraryElement);

    var unitContainerRef = libraryReference.getChild('@fragment');

    var linkingUnits = <LinkingUnit>[];
    {
      var unitElement = CompilationUnitElementImpl(
        library: libraryElement,
        source: libraryFile.source,
        lineInfo: libraryUnitNode.lineInfo,
      );
      libraryUnitNode.declaredElement = unitElement;
      unitElement.isSynthetic = !libraryFile.exists;
      unitElement.setCodeRange(0, libraryUnitNode.length);

      var unitReference = unitContainerRef.getChild(libraryFile.uriStr);
      _bindReference(unitReference, unitElement);

      linkingUnits.add(
        DefiningLinkingUnit(
          reference: unitReference,
          node: libraryUnitNode,
          element: unitElement,
          container: libraryElement,
        ),
      );

      libraryElement.definingCompilationUnit = unitElement;
    }

    var builder = LibraryBuilder._(
      linker: linker,
      kind: inputLibrary,
      uri: libraryFile.uri,
      reference: libraryReference,
      element: libraryElement,
      units: linkingUnits,
    );

    if (inputMacroResult != null) {
      var import = inputLibrary.addMacroPart(
        inputMacroResult.code,
        partialIndex: null,
        performance: OperationPerformanceImpl('<root>'),
      );
      builder.inputMacroPartInclude = import;
    }

    linker.builders[builder.uri] = builder;
  }

  static void _bindReference(Reference reference, ElementImpl element) {
    reference.element = element;
    element.reference = reference;
  }
}

class LinkingUnit {
  final Reference reference;
  final ast.CompilationUnitImpl node;
  final LibraryOrAugmentationElementImpl container;
  final CompilationUnitElementImpl element;

  LinkingUnit({
    required this.reference,
    required this.node,
    required this.container,
    required this.element,
  });
}

enum MacroDeclarationsPhaseStepResult {
  nothing,
  otherProgress,
  topDeclaration,
}

class _CodeOptimizer extends macro.CodeOptimizer {
  final LinkedElementFactory elementFactory;
  final Map<Uri, Set<String>> exportedNames = {};

  _CodeOptimizer({
    required this.elementFactory,
  });

  @override
  Set<String> getImportedNames(String uriStr) {
    var uri = Uri.parse(uriStr);
    var libraryElement = elementFactory.libraryOfUri(uri);
    if (libraryElement != null) {
      return exportedNames[uri] ??= libraryElement.exportedReferences
          .map((exported) => exported.reference.name)
          .toSet();
    }
    return const <String>{};
  }
}

/// This class examines all the [InterfaceElement]s in a library and determines
/// which fields are promotable within that library.
class _FieldPromotability extends FieldPromotability<InterfaceElement,
    FieldElement, PropertyAccessorElement> {
  /// The [_libraryBuilder] for the library being analyzed.
  final LibraryBuilder _libraryBuilder;

  final bool enabled;

  /// Fields that might be promotable, if not marked unpromotable later.
  final List<FieldElementImpl> _potentiallyPromotableFields = [];

  _FieldPromotability(this._libraryBuilder, {required this.enabled});

  @override
  Iterable<InterfaceElement> getSuperclasses(InterfaceElement class_,
      {required bool ignoreImplements}) {
    List<InterfaceElement> result = [];
    var supertype = class_.supertype;
    if (supertype != null) {
      result.add(supertype.element);
    }
    for (var m in class_.mixins) {
      result.add(m.element);
    }
    if (!ignoreImplements) {
      for (var interface in class_.interfaces) {
        result.add(interface.element);
      }
      if (class_ is MixinElement) {
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
    for (var unitElement in _libraryBuilder.element.units) {
      for (var class_ in unitElement.classes) {
        _handleMembers(addClass(class_, isAbstract: class_.isAbstract), class_);
      }
      for (var enum_ in unitElement.enums) {
        _handleMembers(addClass(enum_, isAbstract: false), enum_);
      }
      for (var mixin_ in unitElement.mixins) {
        _handleMembers(addClass(mixin_, isAbstract: true), mixin_);
      }
      // Private representation fields of extension types are always promotable.
      // They also don't affect promotability of any other fields.
      for (var extensionType in unitElement.extensionTypes) {
        if (extensionType.augmentationTarget == null) {
          var representation = extensionType.representation;
          if (representation.name.startsWith('_')) {
            representation.isPromotable = true;
          }
        }
      }
    }

    // Compute the set of field names that are not promotable.
    var fieldNonPromotabilityInfo = computeNonPromotabilityInfo();

    // Set the `isPromotable` bit for each field element that *is* promotable.
    for (var field in _potentiallyPromotableFields) {
      if (fieldNonPromotabilityInfo[field.name] == null) {
        field.isPromotable = true;
      }
    }

    _libraryBuilder.element.fieldNameNonPromotabilityInfo = {
      for (var MapEntry(:key, :value) in fieldNonPromotabilityInfo.entries)
        key: element_model.FieldNameNonPromotabilityInfo(
            conflictingFields: value.conflictingFields,
            conflictingGetters: value.conflictingGetters,
            conflictingNsmClasses: value.conflictingNsmClasses)
    };
  }

  /// Records all the non-synthetic instance fields and getters of [class_] into
  /// [classInfo].
  void _handleMembers(
      ClassInfo<InterfaceElement> classInfo, InterfaceElementImpl class_) {
    for (var field in class_.fields) {
      if (field.isStatic || field.isSynthetic) {
        continue;
      }

      var nonPromotabilityReason = addField(classInfo, field, field.name,
          isFinal: field.isFinal,
          isAbstract: field.isAbstract,
          isExternal: field.isExternal);
      if (enabled && nonPromotabilityReason == null) {
        _potentiallyPromotableFields.add(field);
      }
    }

    for (var accessor in class_.accessors) {
      if (!accessor.isGetter || accessor.isStatic || accessor.isSynthetic) {
        continue;
      }

      var nonPromotabilityReason = addGetter(classInfo, accessor, accessor.name,
          isAbstract: accessor.isAbstract);
      if (enabled && nonPromotabilityReason == null) {
        _potentiallyPromotableFields
            .add(accessor.variable2 as FieldElementImpl);
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
