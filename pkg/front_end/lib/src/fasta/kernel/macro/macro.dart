// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:front_end/src/fasta/kernel/benchmarker.dart'
    show BenchmarkSubdivides, Benchmarker;
import 'package:kernel/ast.dart' show DartType;
import 'package:kernel/src/types.dart';
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import '../../../base/common.dart';
import '../../builder/builder.dart';
import '../../builder/class_builder.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/library_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/named_type_builder.dart';
import '../../builder/nullability_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_alias_builder.dart';
import '../../builder/type_builder.dart';
import '../../builder/type_declaration_builder.dart';
import '../../identifiers.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_factory_builder.dart';
import '../../source/source_field_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_procedure_builder.dart';
import '../hierarchy/hierarchy_builder.dart';
import 'identifiers.dart';

bool enableMacros = false;

/// Enables macros whether the Macro class actually exists in the transitive
/// deps or not. This allows for easier experimentation.
///
/// TODO: Remove this once it is no longer necessary.
bool forceEnableMacros = false;

const String augmentationScheme = 'org-dartlang-augmentation';

final Uri macroLibraryUri =
    Uri.parse('package:_fe_analyzer_shared/src/macros/api.dart');
const String macroClassName = 'Macro';
final IdentifierImpl omittedTypeIdentifier =
    new OmittedTypeIdentifier(id: macro.RemoteInstance.uniqueId);

class MacroDeclarationData {
  bool macrosAreAvailable = false;
  Map<Uri, List<String>> macroDeclarations = {};
  List<List<Uri>>? compilationSequence;
  List<Map<Uri, Map<String, List<String>>>> neededPrecompilations = [];
}

class MacroApplication {
  final ClassBuilder classBuilder;
  final String constructorName;
  final macro.Arguments arguments;

  MacroApplication(this.classBuilder, this.constructorName, this.arguments);

  late macro.MacroInstanceIdentifier instanceIdentifier;

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(classBuilder.name);
    sb.write('.');
    if (constructorName.isEmpty) {
      sb.write('new');
    } else {
      sb.write(constructorName);
    }
    sb.write('(');
    String comma = '';
    for (Object? positional in arguments.positional) {
      sb.write(comma);
      sb.write(positional);
      comma = ',';
    }
    for (MapEntry<String, Object?> named in arguments.named.entries) {
      sb.write(comma);
      sb.write(named.key);
      sb.write(':');
      sb.write(named.value);
      comma = ',';
    }
    sb.write(')');
    return sb.toString();
  }
}

class MacroApplicationDataForTesting {
  Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData = {};
  Map<SourceLibraryBuilder, String> libraryTypesResult = {};
  Map<SourceLibraryBuilder, String> libraryDefinitionResult = {};

  Map<SourceClassBuilder, List<macro.MacroExecutionResult>> classTypesResults =
      {};

  Map<SourceClassBuilder, List<macro.MacroExecutionResult>>
      classDeclarationsResults = {};
  Map<SourceClassBuilder, List<String>> classDeclarationsSources = {};

  Map<SourceClassBuilder, List<macro.MacroExecutionResult>>
      classDefinitionsResults = {};

  Map<MemberBuilder, List<macro.MacroExecutionResult>> memberTypesResults = {};
  Map<MemberBuilder, List<String>> memberTypesSources = {};

  Map<MemberBuilder, List<macro.MacroExecutionResult>>
      memberDeclarationsResults = {};
  Map<MemberBuilder, List<String>> memberDeclarationsSources = {};

  Map<MemberBuilder, List<macro.MacroExecutionResult>>
      memberDefinitionsResults = {};

  List<ApplicationDataForTesting> typesApplicationOrder = [];
  List<ApplicationDataForTesting> declarationsApplicationOrder = [];
  List<ApplicationDataForTesting> definitionApplicationOrder = [];

  void registerTypesResults(
      Builder builder, List<macro.MacroExecutionResult> results) {
    if (builder is SourceClassBuilder) {
      (classTypesResults[builder] ??= []).addAll(results);
    } else {
      (memberTypesResults[builder as MemberBuilder] ??= []).addAll(results);
    }
  }

  void registerDeclarationsResult(
      Builder builder, macro.MacroExecutionResult result, String source) {
    if (builder is SourceClassBuilder) {
      (classDeclarationsResults[builder] ??= []).add(result);
      (classDeclarationsSources[builder] ??= []).add(source);
    } else {
      (memberDeclarationsResults[builder as MemberBuilder] ??= []).add(result);
      (memberDeclarationsSources[builder] ??= []).add(source);
    }
  }

  void registerDefinitionsResults(
      Builder builder, List<macro.MacroExecutionResult> results) {
    if (builder is SourceClassBuilder) {
      (classDefinitionsResults[builder] ??= []).addAll(results);
    } else {
      (memberDefinitionsResults[builder as MemberBuilder] ??= [])
          .addAll(results);
    }
  }
}

class ApplicationDataForTesting {
  final ApplicationData applicationData;
  final MacroApplication macroApplication;

  ApplicationDataForTesting(this.applicationData, this.macroApplication);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    Builder builder = applicationData.builder;
    if (builder is MemberBuilder) {
      if (builder.classBuilder != null) {
        sb.write(builder.classBuilder!.name);
        sb.write('.');
      }
      sb.write(builder.name);
    } else {
      sb.write((builder as ClassBuilder).name);
    }
    sb.write(':');
    sb.write(macroApplication);
    return sb.toString();
  }
}

class LibraryMacroApplicationData {
  Map<SourceClassBuilder, ClassMacroApplicationData> classData = {};
  Map<MemberBuilder, ApplicationData> memberApplications = {};
}

class ClassMacroApplicationData {
  ApplicationData? classApplications;
  Map<MemberBuilder, ApplicationData> memberApplications = {};
}

/// Macro classes that need to be precompiled.
class NeededPrecompilations {
  /// Map from library uris to macro class names and the names of constructor
  /// their constructors is returned for macro classes that need to be
  /// precompiled.
  final Map<Uri, Map<String, List<String>>> macroDeclarations;

  NeededPrecompilations(this.macroDeclarations);
}

class MacroApplications {
  final macro.MacroExecutor _macroExecutor;
  final Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData;
  final MacroApplicationDataForTesting? dataForTesting;
  bool _hasComputedApplicationData = false;

  MacroApplications(
      this._macroExecutor, this.libraryData, this.dataForTesting) {
    dataForTesting?.libraryData.addAll(libraryData);
  }

  static Future<MacroApplications> loadMacroIds(
      macro.MultiMacroExecutor macroExecutor,
      Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData,
      MacroApplicationDataForTesting? dataForTesting,
      Benchmarker? benchmarker) async {
    Map<MacroApplication, macro.MacroInstanceIdentifier> instanceIdCache = {};

    Future<void> ensureMacroClassIds(
        List<MacroApplication>? applications) async {
      if (applications != null) {
        for (MacroApplication application in applications) {
          Uri libraryUri = application.classBuilder.libraryBuilder.importUri;
          String macroClassName = application.classBuilder.name;
          try {
            benchmarker?.beginSubdivide(
                BenchmarkSubdivides.macroApplications_macroExecutorLoadMacro);
            benchmarker?.endSubdivide();
            try {
              benchmarker?.beginSubdivide(BenchmarkSubdivides
                  .macroApplications_macroExecutorInstantiateMacro);
              application.instanceIdentifier = instanceIdCache[application] ??=
                  await macroExecutor.instantiateMacro(
                      libraryUri,
                      macroClassName,
                      application.constructorName,
                      application.arguments);
              benchmarker?.endSubdivide();
            } catch (e) {
              throw "Error instantiating macro `${application}`: $e";
            }
          } catch (e) {
            throw "Error loading macro class "
                "'${application.classBuilder.name}' from "
                "'${application.classBuilder.libraryBuilder.importUri}': $e";
          }
        }
      }
    }

    for (LibraryMacroApplicationData libraryData in libraryData.values) {
      for (ClassMacroApplicationData classData
          in libraryData.classData.values) {
        await ensureMacroClassIds(
            classData.classApplications?.macroApplications);
        for (ApplicationData applicationData
            in classData.memberApplications.values) {
          await ensureMacroClassIds(applicationData.macroApplications);
        }
      }
      for (ApplicationData applicationData
          in libraryData.memberApplications.values) {
        await ensureMacroClassIds(applicationData.macroApplications);
      }
    }
    return new MacroApplications(macroExecutor, libraryData, dataForTesting);
  }

  Map<ClassBuilder, macro.ParameterizedTypeDeclaration> _classDeclarations = {};
  Map<macro.ParameterizedTypeDeclaration, ClassBuilder> _classBuilders = {};
  Map<TypeAliasBuilder, macro.TypeAliasDeclaration> _typeAliasDeclarations = {};
  Map<MemberBuilder, macro.Declaration?> _memberDeclarations = {};

  // TODO(johnniwinther): Support all members.
  macro.Declaration? _getMemberDeclaration(MemberBuilder memberBuilder) {
    return _memberDeclarations[memberBuilder] ??=
        _createMemberDeclaration(memberBuilder);
  }

  macro.ParameterizedTypeDeclaration getClassDeclaration(ClassBuilder builder) {
    return _classDeclarations[builder] ??= _createClassDeclaration(builder);
  }

  macro.TypeAliasDeclaration getTypeAliasDeclaration(TypeAliasBuilder builder) {
    return _typeAliasDeclarations[builder] ??=
        _createTypeAliasDeclaration(builder);
  }

  ClassBuilder _getClassBuilder(
      macro.ParameterizedTypeDeclaration declaration) {
    return _classBuilders[declaration]!;
  }

  macro.Declaration _createMemberDeclaration(MemberBuilder memberBuilder) {
    if (memberBuilder is SourceProcedureBuilder) {
      return _createFunctionDeclaration(memberBuilder);
    } else if (memberBuilder is SourceFieldBuilder) {
      return _createVariableDeclaration(memberBuilder);
    } else if (memberBuilder is SourceConstructorBuilder) {
      return _createConstructorDeclaration(memberBuilder);
    } else if (memberBuilder is SourceFactoryBuilder) {
      return _createFactoryDeclaration(memberBuilder);
    } else {
      // TODO(johnniwinther): Throw when all members are supported.
      throw new UnimplementedError(
          'Unsupported member ${memberBuilder} (${memberBuilder.runtimeType})');
    }
  }

  macro.TypeDeclaration _resolveDeclaration(macro.Identifier identifier) {
    if (identifier is MemberBuilderIdentifier) {
      return getClassDeclaration(identifier.memberBuilder.classBuilder!);
    } else if (identifier is TypeDeclarationBuilderIdentifier) {
      final TypeDeclarationBuilder typeDeclarationBuilder =
          identifier.typeDeclarationBuilder;
      if (typeDeclarationBuilder is ClassBuilder) {
        return getClassDeclaration(typeDeclarationBuilder);
      }
      throw new UnimplementedError(
          'Resolving declarations is only supported for classes');
    } else {
      throw new UnimplementedError(
          'Resolving declarations not supported for $identifier');
    }
  }

  macro.ResolvedIdentifier _resolveIdentifier(macro.Identifier identifier) {
    if (identifier is IdentifierImpl) {
      return identifier.resolveIdentifier();
    } else {
      throw new UnsupportedError(
          'Unsupported identifier ${identifier} (${identifier.runtimeType})');
    }
  }

  macro.TypeAnnotation? _inferOmittedType(
      macro.OmittedTypeAnnotation omittedType) {
    if (omittedType is _OmittedTypeAnnotationImpl) {
      OmittedTypeBuilder typeBuilder = omittedType.typeBuilder;
      if (typeBuilder.hasType) {
        return _computeTypeAnnotation(
            sourceLoader.coreLibrary,
            sourceLoader.target.dillTarget.loader
                .computeTypeBuilder(typeBuilder.type));
      }
    }
    return null;
  }

  void _ensureApplicationData() {
    if (_hasComputedApplicationData) return;
    for (LibraryMacroApplicationData libraryMacroApplicationData
        in libraryData.values) {
      for (MapEntry<MemberBuilder, ApplicationData> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        macro.Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          memberEntry.value.declaration = declaration;
        }
      }
      for (MapEntry<SourceClassBuilder, ClassMacroApplicationData> classEntry
          in libraryMacroApplicationData.classData.entries) {
        SourceClassBuilder classBuilder = classEntry.key;
        ClassMacroApplicationData classData = classEntry.value;
        ApplicationData? classApplicationData = classData.classApplications;
        if (classApplicationData != null) {
          macro.ParameterizedTypeDeclaration classDeclaration =
              getClassDeclaration(classBuilder);
          classApplicationData.declaration = classDeclaration;
        }
        for (MapEntry<MemberBuilder, ApplicationData> memberEntry
            in classData.memberApplications.entries) {
          MemberBuilder memberBuilder = memberEntry.key;
          macro.Declaration? declaration = _getMemberDeclaration(memberBuilder);
          if (declaration != null) {
            memberEntry.value.declaration = declaration;
          }
        }
      }
    }
    _hasComputedApplicationData = true;
  }

  Future<List<macro.MacroExecutionResult>> _applyTypeMacros(
      ApplicationData applicationData) async {
    macro.Declaration declaration = applicationData.declaration;
    List<macro.MacroExecutionResult> results = [];
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (macroApplication.instanceIdentifier
          .shouldExecute(_declarationKind(declaration), macro.Phase.types)) {
        if (retainDataForTesting) {
          dataForTesting!.typesApplicationOrder.add(
              new ApplicationDataForTesting(applicationData, macroApplication));
        }
        macro.MacroExecutionResult result =
            await _macroExecutor.executeTypesPhase(
                macroApplication.instanceIdentifier,
                declaration,
                identifierResolver);
        if (result.isNotEmpty) {
          results.add(result);
        }
      }
    }

    if (retainDataForTesting) {
      dataForTesting?.registerTypesResults(applicationData.builder, results);
    }
    return results;
  }

  late macro.IdentifierResolver identifierResolver;
  late SourceLoader sourceLoader;

  Future<List<SourceLibraryBuilder>> applyTypeMacros(
      SourceLoader sourceLoader) async {
    this.sourceLoader = sourceLoader;
    identifierResolver = new _IdentifierResolver(sourceLoader);
    List<SourceLibraryBuilder> augmentationLibraries = [];
    _ensureApplicationData();
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in libraryData.entries) {
      List<macro.MacroExecutionResult> executionResults = [];
      SourceLibraryBuilder libraryBuilder = entry.key;
      LibraryMacroApplicationData data = entry.value;
      for (ApplicationData applicationData in data.memberApplications.values) {
        executionResults.addAll(await _applyTypeMacros(applicationData));
      }
      for (MapEntry<ClassBuilder, ClassMacroApplicationData> entry
          in data.classData.entries) {
        ClassMacroApplicationData classApplicationData = entry.value;
        for (ApplicationData applicationData
            in classApplicationData.memberApplications.values) {
          executionResults.addAll(await _applyTypeMacros(applicationData));
        }
        if (classApplicationData.classApplications != null) {
          executionResults.addAll(
              await _applyTypeMacros(classApplicationData.classApplications!));
        }
      }
      if (executionResults.isNotEmpty) {
        Map<macro.OmittedTypeAnnotation, String> omittedTypes = {};
        String result = _macroExecutor
            .buildAugmentationLibrary(executionResults, _resolveDeclaration,
                _resolveIdentifier, _inferOmittedType,
                omittedTypes: omittedTypes)
            .trim();
        assert(
            result.trim().isNotEmpty,
            "Empty types phase augmentation library source for "
            "$libraryBuilder}");
        if (result.isNotEmpty) {
          if (retainDataForTesting) {
            dataForTesting?.libraryTypesResult[libraryBuilder] = result;
          }
          Map<String, OmittedTypeBuilder>? omittedTypeBuilders;
          if (omittedTypes.isNotEmpty) {
            omittedTypeBuilders = {};
            for (MapEntry<macro.OmittedTypeAnnotation, String> entry
                in omittedTypes.entries) {
              _OmittedTypeAnnotationImpl omittedType =
                  entry.key as _OmittedTypeAnnotationImpl;
              omittedTypeBuilders[entry.value] = omittedType.typeBuilder;
            }
          }
          augmentationLibraries.add(
              await libraryBuilder.createAugmentationLibrary(result,
                  omittedTypes: omittedTypeBuilders));
        }
      }
    }

    return augmentationLibraries;
  }

  Future<void> _applyDeclarationsMacros(ApplicationData applicationData,
      Future<void> Function(SourceLibraryBuilder) onAugmentationLibrary) async {
    List<macro.MacroExecutionResult> results = [];
    macro.Declaration declaration = applicationData.declaration;
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          _declarationKind(declaration), macro.Phase.declarations)) {
        if (retainDataForTesting) {
          dataForTesting!.declarationsApplicationOrder.add(
              new ApplicationDataForTesting(applicationData, macroApplication));
        }
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDeclarationsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                identifierResolver,
                typeDeclarationResolver,
                typeResolver,
                typeIntrospector);
        if (result.isNotEmpty) {
          Map<macro.OmittedTypeAnnotation, String> omittedTypes = {};
          String source = _macroExecutor.buildAugmentationLibrary([result],
              _resolveDeclaration, _resolveIdentifier, _inferOmittedType,
              omittedTypes: omittedTypes);
          if (retainDataForTesting) {
            dataForTesting?.registerDeclarationsResult(
                applicationData.builder, result, source);
          }
          Map<String, OmittedTypeBuilder>? omittedTypeBuilders;
          if (omittedTypes.isNotEmpty) {
            omittedTypeBuilders = {};
            for (MapEntry<macro.OmittedTypeAnnotation, String> entry
                in omittedTypes.entries) {
              _OmittedTypeAnnotationImpl omittedType =
                  entry.key as _OmittedTypeAnnotationImpl;
              omittedTypeBuilders[entry.value] = omittedType.typeBuilder;
            }
          }
          SourceLibraryBuilder augmentationLibrary = await applicationData
              .libraryBuilder
              .createAugmentationLibrary(source,
                  omittedTypes: omittedTypeBuilders);
          await onAugmentationLibrary(augmentationLibrary);
          if (retainDataForTesting) {
            results.add(result);
          }
        }
      }
    }
    if (retainDataForTesting) {
      Builder builder = applicationData.builder;
      if (builder is SourceClassBuilder) {
        dataForTesting?.classDeclarationsResults[builder] = results;
      } else {
        dataForTesting?.memberDeclarationsResults[builder as MemberBuilder] =
            results;
      }
    }
  }

  late Types types;
  late macro.TypeDeclarationResolver typeDeclarationResolver;
  late macro.TypeResolver typeResolver;
  late macro.TypeIntrospector typeIntrospector;

  Future<void> applyDeclarationsMacros(
      ClassHierarchyBuilder classHierarchy,
      List<SourceClassBuilder> sortedSourceClassBuilders,
      Future<void> Function(SourceLibraryBuilder) onAugmentationLibrary) async {
    types = new Types(classHierarchy);
    typeDeclarationResolver = new _TypeDeclarationResolver(this);
    typeResolver = new _TypeResolver(this);
    typeIntrospector = new _TypeIntrospector(this, classHierarchy);

    // Apply macros to classes first, in class hierarchy order.
    for (SourceClassBuilder classBuilder in sortedSourceClassBuilders) {
      LibraryMacroApplicationData? libraryApplicationData =
          libraryData[classBuilder.libraryBuilder];
      if (libraryApplicationData == null) continue;

      ClassMacroApplicationData? classApplicationData =
          libraryApplicationData.classData[classBuilder];
      if (classApplicationData == null) continue;
      for (ApplicationData applicationData
          in classApplicationData.memberApplications.values) {
        await _applyDeclarationsMacros(applicationData, onAugmentationLibrary);
      }
      if (classApplicationData.classApplications != null) {
        await _applyDeclarationsMacros(
            classApplicationData.classApplications!, onAugmentationLibrary);
      }
    }

    // Apply macros to library members second.
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in libraryData.entries) {
      LibraryMacroApplicationData data = entry.value;
      for (ApplicationData applicationData in data.memberApplications.values) {
        await _applyDeclarationsMacros(applicationData, onAugmentationLibrary);
      }
    }
  }

  Future<List<macro.MacroExecutionResult>> _applyDefinitionMacros(
      ApplicationData applicationData) async {
    List<macro.MacroExecutionResult> results = [];
    macro.Declaration declaration = applicationData.declaration;
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          _declarationKind(declaration), macro.Phase.definitions)) {
        if (retainDataForTesting) {
          dataForTesting!.definitionApplicationOrder.add(
              new ApplicationDataForTesting(applicationData, macroApplication));
        }
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDefinitionsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                identifierResolver,
                typeDeclarationResolver,
                typeResolver,
                typeIntrospector,
                typeInferrer);
        if (result.isNotEmpty) {
          results.add(result);
        }
      }
    }
    if (retainDataForTesting) {
      dataForTesting?.registerDefinitionsResults(
          applicationData.builder, results);
    }
    return results;
  }

  late macro.TypeInferrer typeInferrer;

  Future<List<SourceLibraryBuilder>> applyDefinitionMacros() async {
    typeInferrer = new _TypeInferrer(this);
    List<SourceLibraryBuilder> augmentationLibraries = [];
    for (MapEntry<SourceLibraryBuilder, LibraryMacroApplicationData> entry
        in libraryData.entries) {
      List<macro.MacroExecutionResult> executionResults = [];
      SourceLibraryBuilder libraryBuilder = entry.key;
      LibraryMacroApplicationData data = entry.value;
      for (ApplicationData applicationData in data.memberApplications.values) {
        executionResults.addAll(await _applyDefinitionMacros(applicationData));
      }
      for (MapEntry<ClassBuilder, ClassMacroApplicationData> entry
          in data.classData.entries) {
        ClassMacroApplicationData classApplicationData = entry.value;
        for (ApplicationData applicationData
            in classApplicationData.memberApplications.values) {
          executionResults
              .addAll(await _applyDefinitionMacros(applicationData));
        }
        if (classApplicationData.classApplications != null) {
          executionResults.addAll(await _applyDefinitionMacros(
              classApplicationData.classApplications!));
        }
      }
      if (executionResults.isNotEmpty) {
        String result = _macroExecutor
            .buildAugmentationLibrary(executionResults, _resolveDeclaration,
                _resolveIdentifier, _inferOmittedType)
            .trim();
        assert(
            result.trim().isNotEmpty,
            "Empty definitions phase augmentation library source for "
            "$libraryBuilder}");
        if (retainDataForTesting) {
          dataForTesting?.libraryDefinitionResult[libraryBuilder] = result;
        }
        augmentationLibraries
            .add(await libraryBuilder.createAugmentationLibrary(result));
      }
    }
    return augmentationLibraries;
  }

  void close() {
    _macroExecutor.close();
    _staticTypeCache.clear();
    _typeAnnotationCache.clear();
    if (!retainDataForTesting) {
      libraryData.clear();
    }
  }

  List<macro.NamedTypeAnnotationImpl> _typeBuildersToAnnotations(
      LibraryBuilder libraryBuilder, List<TypeBuilder>? typeBuilders) {
    return typeBuilders == null
        ? []
        : typeBuilders
            .map((TypeBuilder typeBuilder) =>
                computeTypeAnnotation(libraryBuilder, typeBuilder)
                    as macro.NamedTypeAnnotationImpl)
            .toList();
  }

  macro.ParameterizedTypeDeclaration _createClassDeclaration(
      ClassBuilder builder) {
    assert(
        !builder.isAnonymousMixinApplication,
        "Trying to create a ClassDeclaration for the mixin application "
        "${builder}.");
    TypeBuilder? supertypeBuilder = builder.supertypeBuilder;
    List<TypeBuilder>? mixins;
    while (supertypeBuilder != null) {
      TypeDeclarationBuilder? declaration = supertypeBuilder.declaration;
      if (declaration is ClassBuilder &&
          declaration.isAnonymousMixinApplication) {
        (mixins ??= []).add(declaration.mixedInTypeBuilder!);
        supertypeBuilder = declaration.supertypeBuilder;
      } else {
        break;
      }
    }
    if (mixins != null) {
      mixins = mixins.reversed.toList();
    }
    final TypeDeclarationBuilderIdentifier identifier =
        new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: builder,
            libraryBuilder: builder.libraryBuilder,
            id: macro.RemoteInstance.uniqueId,
            name: builder.name);
    // TODO(johnniwinther): Support typeParameters
    final List<macro.TypeParameterDeclarationImpl> typeParameters = [];
    final List<macro.NamedTypeAnnotationImpl> interfaces =
        _typeBuildersToAnnotations(
            builder.libraryBuilder, builder.interfaceBuilders);
    macro.ParameterizedTypeDeclaration declaration = builder.isMixinDeclaration
        // TODO: These shouldn't always be introspectable. In the declarations
        // phase we need to limit the introspectable declarations to those that
        // are part of the super chain of the directly macro annotated class.
        ? new macro.IntrospectableMixinDeclarationImpl(
                id: macro.RemoteInstance.uniqueId,
                identifier: identifier,
                typeParameters: typeParameters,
                hasBase: builder.isBase,
                interfaces: interfaces,
                superclassConstraints: _typeBuildersToAnnotations(
                    builder.libraryBuilder, builder.onTypes))
            // This cast is not necessary but LUB doesn't give the desired type
            // without it.
            as macro.ParameterizedTypeDeclaration
        : new macro.IntrospectableClassDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            typeParameters: typeParameters,
            interfaces: interfaces,
            hasAbstract: builder.isAbstract,
            hasBase: builder.isBase,
            hasExternal: builder.isExternal,
            hasFinal: builder.isFinal,
            hasInterface: builder.isInterface,
            hasMixin: builder.isMixinClass,
            hasSealed: builder.isSealed,
            mixins: _typeBuildersToAnnotations(builder.libraryBuilder, mixins),
            superclass: supertypeBuilder != null
                ? _computeTypeAnnotation(
                        builder.libraryBuilder, supertypeBuilder)
                    as macro.NamedTypeAnnotationImpl
                : null);
    _classBuilders[declaration] = builder;
    return declaration;
  }

  macro.TypeAliasDeclaration _createTypeAliasDeclaration(
      TypeAliasBuilder builder) {
    macro.TypeAliasDeclaration declaration = new macro.TypeAliasDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: builder,
            libraryBuilder: builder.libraryBuilder,
            id: macro.RemoteInstance.uniqueId,
            name: builder.name),
        // TODO(johnniwinther): Support typeParameters
        typeParameters: [],
        aliasedType:
            _computeTypeAnnotation(builder.libraryBuilder, builder.type));
    return declaration;
  }

  List<List<macro.ParameterDeclarationImpl>> _createParameters(
      MemberBuilder builder, List<FormalParameterBuilder>? formals) {
    List<macro.ParameterDeclarationImpl>? positionalParameters;
    List<macro.ParameterDeclarationImpl>? namedParameters;
    if (formals == null) {
      positionalParameters = namedParameters = const [];
    } else {
      positionalParameters = [];
      namedParameters = [];
      for (FormalParameterBuilder formal in formals) {
        macro.TypeAnnotationImpl type =
            computeTypeAnnotation(builder.libraryBuilder, formal.type);
        macro.IdentifierImpl identifier = new FormalParameterBuilderIdentifier(
            id: macro.RemoteInstance.uniqueId,
            name: formal.name,
            parameterBuilder: formal,
            libraryBuilder: builder.libraryBuilder);
        if (formal.isNamed) {
          namedParameters.add(new macro.ParameterDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            isRequired: formal.isRequiredNamed,
            isNamed: true,
            type: type,
          ));
        } else {
          positionalParameters.add(new macro.ParameterDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            isRequired: formal.isRequiredPositional,
            isNamed: false,
            type: type,
          ));
        }
      }
    }
    return [positionalParameters, namedParameters];
  }

  macro.ConstructorDeclaration _createConstructorDeclaration(
      SourceConstructorBuilder builder) {
    List<FormalParameterBuilder>? formals = null;
    // TODO(johnniwinther): Support formals for other constructors.
    if (builder is DeclaredSourceConstructorBuilder) {
      formals = builder.formals;
    }
    List<List<macro.ParameterDeclarationImpl>> parameters =
        _createParameters(builder, formals);
    macro.ParameterizedTypeDeclaration definingClass =
        getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: builder.name),
      definingType: definingClass.identifier as macro.IdentifierImpl,
      isFactory: builder.isFactory,
      isAbstract: builder.isAbstract,
      isExternal: builder.isExternal,
      isGetter: builder.isGetter,
      isOperator: builder.isOperator,
      isSetter: builder.isSetter,
      positionalParameters: parameters[0],
      namedParameters: parameters[1],
      // TODO(johnniwinther): Support constructor return type.
      returnType: computeTypeAnnotation(builder.libraryBuilder, null),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const [],
    );
  }

  macro.ConstructorDeclaration _createFactoryDeclaration(
      SourceFactoryBuilder builder) {
    List<List<macro.ParameterDeclarationImpl>> parameters =
        _createParameters(builder, builder.formals);
    macro.ParameterizedTypeDeclaration definingClass =
        getClassDeclaration(builder.classBuilder);

    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: builder.name),
      definingType: definingClass.identifier as macro.IdentifierImpl,
      isFactory: builder.isFactory,
      isAbstract: builder.isAbstract,
      isExternal: builder.isExternal,
      isGetter: builder.isGetter,
      isOperator: builder.isOperator,
      isSetter: builder.isSetter,
      positionalParameters: parameters[0],
      namedParameters: parameters[1],
      // TODO(johnniwinther): Support constructor return type.
      returnType: computeTypeAnnotation(builder.libraryBuilder, null),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const [],
    );
  }

  macro.FunctionDeclaration _createFunctionDeclaration(
      SourceProcedureBuilder builder) {
    List<List<macro.ParameterDeclarationImpl>> parameters =
        _createParameters(builder, builder.formals);

    macro.ParameterizedTypeDeclaration? definingClass = null;
    if (builder.classBuilder != null) {
      definingClass =
          getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    }
    if (definingClass != null) {
      // TODO(johnniwinther): Should static fields be field or variable
      //  declarations?
      return new macro.MethodDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          definingType: definingClass.identifier as macro.IdentifierImpl,
          isAbstract: builder.isAbstract,
          isExternal: builder.isExternal,
          isGetter: builder.isGetter,
          isOperator: builder.isOperator,
          isSetter: builder.isSetter,
          isStatic: builder.isStatic,
          positionalParameters: parameters[0],
          namedParameters: parameters[1],
          returnType:
              computeTypeAnnotation(builder.libraryBuilder, builder.returnType),
          // TODO(johnniwinther): Support typeParameters
          typeParameters: const []);
    } else {
      return new macro.FunctionDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          isAbstract: builder.isAbstract,
          isExternal: builder.isExternal,
          isGetter: builder.isGetter,
          isOperator: builder.isOperator,
          isSetter: builder.isSetter,
          positionalParameters: parameters[0],
          namedParameters: parameters[1],
          returnType:
              computeTypeAnnotation(builder.libraryBuilder, builder.returnType),
          // TODO(johnniwinther): Support typeParameters
          typeParameters: const []);
    }
  }

  macro.VariableDeclaration _createVariableDeclaration(
      SourceFieldBuilder builder) {
    macro.ParameterizedTypeDeclaration? definingClass = null;
    if (builder.classBuilder != null) {
      definingClass =
          getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    }
    if (definingClass != null) {
      // TODO(johnniwinther): Should static fields be field or variable
      //  declarations?
      return new macro.FieldDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          definingType: definingClass.identifier as macro.IdentifierImpl,
          isExternal: builder.isExternal,
          isFinal: builder.isFinal,
          isLate: builder.isLate,
          isStatic: builder.isStatic,
          type: computeTypeAnnotation(builder.libraryBuilder, builder.type));
    } else {
      return new macro.VariableDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new MemberBuilderIdentifier(
              memberBuilder: builder,
              id: macro.RemoteInstance.uniqueId,
              name: builder.name),
          isExternal: builder.isExternal,
          isFinal: builder.isFinal,
          isLate: builder.isLate,
          type: computeTypeAnnotation(builder.libraryBuilder, builder.type));
    }
  }

  Map<TypeBuilder?, macro.TypeAnnotationImpl> _typeAnnotationCache = {};

  List<macro.TypeAnnotationImpl> computeTypeAnnotations(
      LibraryBuilder library, List<TypeBuilder>? typeBuilders) {
    if (typeBuilders == null) return const [];
    return new List.generate(typeBuilders.length,
        (int index) => computeTypeAnnotation(library, typeBuilders[index]));
  }

  macro.TypeAnnotationImpl _computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    if (typeBuilder != null) {
      if (typeBuilder is NamedTypeBuilder) {
        Object name = typeBuilder.name;
        List<macro.TypeAnnotationImpl> typeArguments =
            computeTypeAnnotations(libraryBuilder, typeBuilder.arguments);
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        if (name is String) {
          return new macro.NamedTypeAnnotationImpl(
              id: macro.RemoteInstance.uniqueId,
              identifier: new TypeBuilderIdentifier(
                  typeBuilder: typeBuilder,
                  libraryBuilder: libraryBuilder,
                  id: macro.RemoteInstance.uniqueId,
                  name: name),
              typeArguments: typeArguments,
              isNullable: isNullable);
        } else if (name is QualifiedName) {
          assert(name.qualifier is String);
          return new macro.NamedTypeAnnotationImpl(
              id: macro.RemoteInstance.uniqueId,
              identifier: new TypeBuilderIdentifier(
                  typeBuilder: typeBuilder,
                  libraryBuilder: libraryBuilder,
                  id: macro.RemoteInstance.uniqueId,
                  name: name.name),
              typeArguments: typeArguments,
              isNullable: isNullable);
        }
      } else if (typeBuilder is OmittedTypeBuilder) {
        return new _OmittedTypeAnnotationImpl(typeBuilder,
            id: macro.RemoteInstance.uniqueId);
      }
    }
    return new macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: omittedTypeIdentifier,
        isNullable: false,
        typeArguments: const []);
  }

  macro.TypeAnnotationImpl computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    return _typeAnnotationCache[typeBuilder] ??=
        _computeTypeAnnotation(libraryBuilder, typeBuilder);
  }

  DartType _typeForAnnotation(macro.TypeAnnotationCode typeAnnotation) {
    NullabilityBuilder nullabilityBuilder;
    if (typeAnnotation is macro.NullableTypeAnnotationCode) {
      nullabilityBuilder = const NullabilityBuilder.nullable();
      typeAnnotation = typeAnnotation.underlyingType;
    } else {
      nullabilityBuilder = const NullabilityBuilder.omitted();
    }

    if (typeAnnotation is macro.NamedTypeAnnotationCode) {
      macro.NamedTypeAnnotationCode namedTypeAnnotation = typeAnnotation;
      IdentifierImpl typeIdentifier = typeAnnotation.name as IdentifierImpl;
      List<DartType> arguments = new List<DartType>.generate(
          namedTypeAnnotation.typeArguments.length,
          (int index) =>
              _typeForAnnotation(namedTypeAnnotation.typeArguments[index]));
      return typeIdentifier.buildType(nullabilityBuilder, arguments);
    }
    // TODO: Implement support for function types.
    throw new UnimplementedError(
        'Unimplemented type annotation kind ${typeAnnotation.kind}');
  }

  macro.StaticType resolveTypeAnnotation(
      macro.TypeAnnotationCode typeAnnotation) {
    return createStaticType(_typeForAnnotation(typeAnnotation));
  }

  Map<DartType, _StaticTypeImpl> _staticTypeCache = {};

  macro.StaticType createStaticType(DartType dartType) {
    return _staticTypeCache[dartType] ??= new _StaticTypeImpl(this, dartType);
  }
}

class _StaticTypeImpl implements macro.StaticType {
  final MacroApplications macroApplications;
  final DartType type;

  _StaticTypeImpl(this.macroApplications, this.type);

  @override
  Future<bool> isExactly(covariant _StaticTypeImpl other) {
    return new Future.value(type == other.type);
  }

  @override
  Future<bool> isSubtypeOf(covariant _StaticTypeImpl other) {
    return new Future.value(macroApplications.types
        .isSubtypeOf(type, other.type, SubtypeCheckMode.withNullabilities));
  }
}

class _IdentifierResolver implements macro.IdentifierResolver {
  final SourceLoader sourceLoader;

  _IdentifierResolver(this.sourceLoader);

  @override
  Future<macro.Identifier> resolveIdentifier(Uri library, String name) {
    LibraryBuilder? libraryBuilder = sourceLoader.lookupLibraryBuilder(library);
    if (libraryBuilder == null) {
      return new Future.error(
          new ArgumentError('Library at uri $library could not be resolved.'),
          StackTrace.current);
    }
    bool isSetter = false;
    String memberName = name;
    if (name.endsWith('=')) {
      memberName = name.substring(0, name.length - 1);
      isSetter = true;
    }
    Builder? builder =
        libraryBuilder.scope.lookupLocalMember(memberName, setter: isSetter);
    if (builder == null) {
      return new Future.error(
          new ArgumentError(
              'Unable to find top level identifier "$name" in $library'),
          StackTrace.current);
    } else if (builder is TypeDeclarationBuilder) {
      return new Future.value(new TypeDeclarationBuilderIdentifier(
          typeDeclarationBuilder: builder,
          libraryBuilder: libraryBuilder,
          id: macro.RemoteInstance.uniqueId,
          name: name));
    } else if (builder is MemberBuilder) {
      return new Future.value(new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: name));
    } else {
      return new Future.error(
          new UnsupportedError('Unsupported identifier kind $builder'),
          StackTrace.current);
    }
  }
}

class _TypeResolver implements macro.TypeResolver {
  final MacroApplications macroApplications;

  _TypeResolver(this.macroApplications);

  @override
  Future<macro.StaticType> resolve(macro.TypeAnnotationCode typeAnnotation) {
    return new Future.value(
        macroApplications.resolveTypeAnnotation(typeAnnotation));
  }
}

class _TypeIntrospector implements macro.TypeIntrospector {
  final MacroApplications macroApplications;
  final ClassHierarchyBuilder classHierarchy;

  _TypeIntrospector(this.macroApplications, this.classHierarchy);

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
      macro.IntrospectableType type) {
    if (type is! macro.IntrospectableClassDeclaration) {
      throw new UnsupportedError('Only introspection on classes is supported');
    }
    ClassBuilder classBuilder = macroApplications._getClassBuilder(type);
    List<macro.ConstructorDeclaration> result = [];
    Iterator<MemberBuilder> iterator = classBuilder.fullConstructorIterator();
    while (iterator.moveNext()) {
      MemberBuilder memberBuilder = iterator.current;
      if (memberBuilder is DeclaredSourceConstructorBuilder) {
        // TODO(johnniwinther): Should we support synthesized constructors?
        result.add(macroApplications._getMemberDeclaration(memberBuilder)
            as macro.ConstructorDeclaration);
      } else if (memberBuilder is SourceFactoryBuilder) {
        result.add(macroApplications._getMemberDeclaration(memberBuilder)
            as macro.ConstructorDeclaration);
      }
    }
    return new Future.value(result);
  }

  @override
  Future<List<macro.EnumValueDeclaration>> valuesOf(
      covariant macro.IntrospectableEnum enumType) {
    // TODO: implement valuesOf
    throw new UnimplementedError();
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(macro.IntrospectableType type) {
    if (type is! macro.IntrospectableClassDeclaration) {
      throw new UnsupportedError('Only introspection on classes is supported');
    }
    ClassBuilder classBuilder = macroApplications._getClassBuilder(type);
    List<macro.FieldDeclaration> result = [];
    Iterator<SourceFieldBuilder> iterator =
        classBuilder.fullMemberIterator<SourceFieldBuilder>();
    while (iterator.moveNext()) {
      result.add(macroApplications._getMemberDeclaration(iterator.current)
          as macro.FieldDeclaration);
    }
    return new Future.value(result);
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
      macro.IntrospectableType type) {
    if (type is! macro.IntrospectableClassDeclaration &&
        type is! macro.IntrospectableMixinDeclaration) {
      throw new UnsupportedError(
          'Only introspection on classes and mixins is supported');
    }
    ClassBuilder classBuilder = macroApplications
        ._getClassBuilder(type as macro.ParameterizedTypeDeclaration);
    List<macro.MethodDeclaration> result = [];
    Iterator<SourceProcedureBuilder> iterator =
        classBuilder.fullMemberIterator<SourceProcedureBuilder>();
    while (iterator.moveNext()) {
      result.add(macroApplications._getMemberDeclaration(iterator.current)
          as macro.MethodDeclaration);
    }
    return new Future.value(result);
  }
}

class _TypeDeclarationResolver implements macro.TypeDeclarationResolver {
  final MacroApplications macroApplications;

  _TypeDeclarationResolver(this.macroApplications);

  @override
  Future<macro.TypeDeclaration> declarationOf(macro.Identifier identifier) {
    if (identifier is IdentifierImpl) {
      return identifier.resolveTypeDeclaration(macroApplications);
    }
    throw new UnsupportedError(
        'Unsupported identifier $identifier (${identifier.runtimeType})');
  }
}

class _TypeInferrer implements macro.TypeInferrer {
  final MacroApplications _macroApplications;

  _TypeInferrer(this._macroApplications);

  @override
  Future<macro.TypeAnnotation> inferType(
          macro.OmittedTypeAnnotation omittedType) =>
      new Future.value(_macroApplications._inferOmittedType(omittedType));
}

macro.DeclarationKind _declarationKind(macro.Declaration declaration) {
  if (declaration is macro.ConstructorDeclaration) {
    return macro.DeclarationKind.constructor;
  } else if (declaration is macro.MethodDeclaration) {
    return macro.DeclarationKind.method;
  } else if (declaration is macro.FunctionDeclaration) {
    return macro.DeclarationKind.function;
  } else if (declaration is macro.FieldDeclaration) {
    return macro.DeclarationKind.field;
  } else if (declaration is macro.VariableDeclaration) {
    return macro.DeclarationKind.variable;
  } else if (declaration is macro.ClassDeclaration) {
    return macro.DeclarationKind.classType;
  } else if (declaration is macro.EnumDeclaration) {
    return macro.DeclarationKind.enumType;
  } else if (declaration is macro.MixinDeclaration) {
    return macro.DeclarationKind.mixinType;
  }
  throw new UnsupportedError(
      "Unexpected declaration ${declaration} (${declaration.runtimeType})");
}

/// Data needed to apply a list of macro applications to a class or member.
class ApplicationData {
  final SourceLibraryBuilder libraryBuilder;
  final Builder builder;
  final List<MacroApplication> macroApplications;

  late final macro.Declaration declaration;

  ApplicationData(this.libraryBuilder, this.builder, this.macroApplications);
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      enumValueAugmentations.isNotEmpty ||
      libraryAugmentations.isNotEmpty ||
      typeAugmentations.isNotEmpty;
}

class _OmittedTypeAnnotationImpl extends macro.OmittedTypeAnnotationImpl {
  final OmittedTypeBuilder typeBuilder;

  _OmittedTypeAnnotationImpl(this.typeBuilder, {required int id})
      : super(id: id);
}
