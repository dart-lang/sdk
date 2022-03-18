// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
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
import '../hierarchy/hierarchy_node.dart';
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

  // TODO(johnniwinther): Add support for arguments.

  MacroApplication(this.classBuilder, this.constructorName);

  late macro.MacroInstanceIdentifier instanceIdentifier;

  @override
  String toString() {
    return '${classBuilder.name}.'
        '${constructorName.isEmpty ? 'new' : constructorName}()';
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
  Map<SourceClassBuilder, List<macro.MacroExecutionResult>>
      classDefinitionsResults = {};
  Map<MemberBuilder, List<macro.MacroExecutionResult>> memberTypesResults = {};
  Map<MemberBuilder, List<macro.MacroExecutionResult>>
      memberDeclarationsResults = {};
  Map<MemberBuilder, List<macro.MacroExecutionResult>>
      memberDefinitionsResults = {};
}

class LibraryMacroApplicationData {
  Map<SourceClassBuilder, ClassMacroApplicationData> classData = {};
  Map<MemberBuilder, List<MacroApplication>> memberApplications = {};
}

class ClassMacroApplicationData {
  List<MacroApplication>? classApplications;
  Map<MemberBuilder, List<MacroApplication>> memberApplications = {};
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
  List<_ApplicationData>? _applicationDataCache;

  MacroApplications(
      this._macroExecutor, this.libraryData, this.dataForTesting) {
    dataForTesting?.libraryData.addAll(libraryData);
  }

  static Future<MacroApplications> loadMacroIds(
      macro.MacroExecutor macroExecutor,
      Map<Uri, Uri> precompiledMacroUris,
      Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData,
      MacroApplicationDataForTesting? dataForTesting) async {
    Map<ClassBuilder, macro.MacroClassIdentifier> classIdCache = {};

    Map<MacroApplication, macro.MacroInstanceIdentifier> instanceIdCache = {};

    Future<void> ensureMacroClassIds(
        List<MacroApplication>? applications) async {
      if (applications != null) {
        for (MacroApplication application in applications) {
          Uri libraryUri = application.classBuilder.library.importUri;
          String macroClassName = application.classBuilder.name;
          Uri? precompiledMacroUri = precompiledMacroUris[libraryUri];
          try {
            macro.MacroClassIdentifier macroClassIdentifier =
                classIdCache[application.classBuilder] ??=
                    await macroExecutor.loadMacro(libraryUri, macroClassName,
                        precompiledKernelUri: precompiledMacroUri);
            try {
              application.instanceIdentifier = instanceIdCache[application] ??=
                  await macroExecutor.instantiateMacro(
                      macroClassIdentifier,
                      application.constructorName,
                      // TODO(johnniwinther): Support macro arguments.
                      new macro.Arguments([], {}));
            } catch (e) {
              throw "Error instantiating macro `${application}`: $e";
            }
          } catch (e) {
            throw "Error loading macro class "
                "'${application.classBuilder.name}' from "
                "'${application.classBuilder.library.importUri}': $e";
          }
        }
      }
    }

    for (LibraryMacroApplicationData libraryData in libraryData.values) {
      for (ClassMacroApplicationData classData
          in libraryData.classData.values) {
        await ensureMacroClassIds(classData.classApplications);
        for (List<MacroApplication> applications
            in classData.memberApplications.values) {
          await ensureMacroClassIds(applications);
        }
      }
      for (List<MacroApplication> applications
          in libraryData.memberApplications.values) {
        await ensureMacroClassIds(applications);
      }
    }
    return new MacroApplications(macroExecutor, libraryData, dataForTesting);
  }

  Map<ClassBuilder, macro.ClassDeclaration> _classDeclarations = {};
  Map<macro.ClassDeclaration, ClassBuilder> _classBuilders = {};
  Map<TypeAliasBuilder, macro.TypeAliasDeclaration> _typeAliasDeclarations = {};
  Map<MemberBuilder, macro.Declaration?> _memberDeclarations = {};

  // TODO(johnniwinther): Support all members.
  macro.Declaration? _getMemberDeclaration(MemberBuilder memberBuilder) {
    return _memberDeclarations[memberBuilder] ??=
        _createMemberDeclaration(memberBuilder);
  }

  macro.ClassDeclaration getClassDeclaration(ClassBuilder builder) {
    return _classDeclarations[builder] ??= _createClassDeclaration(builder);
  }

  macro.TypeAliasDeclaration getTypeAliasDeclaration(TypeAliasBuilder builder) {
    return _typeAliasDeclarations[builder] ??=
        _createTypeAliasDeclaration(builder);
  }

  ClassBuilder _getClassBuilder(macro.ClassDeclaration declaration) {
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

  macro.ResolvedIdentifier _resolveIdentifier(macro.Identifier identifier) {
    if (identifier is IdentifierImpl) {
      return identifier.resolveIdentifier();
    } else {
      throw new UnsupportedError(
          'Unsupported identifier ${identifier} (${identifier.runtimeType})');
    }
  }

  macro.TypeAnnotation _inferOmittedType(
      macro.OmittedTypeAnnotation omittedType) {
    throw new UnimplementedError('This is not yet supported!');
  }

  Iterable<_ApplicationData> get _applicationData {
    if (_applicationDataCache == null) {
      List<_ApplicationData> data = _applicationDataCache = [];
      for (MapEntry<SourceLibraryBuilder,
          LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
        SourceLibraryBuilder libraryBuilder = libraryEntry.key;
        LibraryMacroApplicationData libraryMacroApplicationData =
            libraryEntry.value;
        for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
            in libraryMacroApplicationData.memberApplications.entries) {
          MemberBuilder memberBuilder = memberEntry.key;
          macro.Declaration? declaration = _getMemberDeclaration(memberBuilder);
          if (declaration != null) {
            data.add(new _ApplicationData(
                libraryBuilder, memberBuilder, declaration, memberEntry.value));
          }
        }
        for (MapEntry<SourceClassBuilder, ClassMacroApplicationData> classEntry
            in libraryMacroApplicationData.classData.entries) {
          SourceClassBuilder classBuilder = classEntry.key;
          ClassMacroApplicationData classData = classEntry.value;
          List<MacroApplication>? classApplications =
              classData.classApplications;
          if (classApplications != null) {
            macro.ClassDeclaration classDeclaration =
                getClassDeclaration(classBuilder);
            data.add(new _ApplicationData(libraryBuilder, classBuilder,
                classDeclaration, classApplications));
          }
          for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
              in classData.memberApplications.entries) {
            MemberBuilder memberBuilder = memberEntry.key;
            macro.Declaration? declaration =
                _getMemberDeclaration(memberBuilder);
            if (declaration != null) {
              data.add(new _ApplicationData(libraryBuilder, memberBuilder,
                  declaration, memberEntry.value));
            }
          }
        }
      }
    }
    return _applicationDataCache!;
  }

  Future<List<macro.MacroExecutionResult>> _applyTypeMacros(
      _ApplicationData applicationData) async {
    macro.Declaration declaration = applicationData.declaration;
    List<macro.MacroExecutionResult> results = [];
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (macroApplication.instanceIdentifier
          .shouldExecute(_declarationKind(declaration), macro.Phase.types)) {
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
      Builder builder = applicationData.builder;
      if (builder is SourceClassBuilder) {
        dataForTesting?.classTypesResults[builder] = results;
      } else {
        dataForTesting?.memberTypesResults[builder as MemberBuilder] = results;
      }
    }
    return results;
  }

  late macro.IdentifierResolver identifierResolver;
  late SourceLoader sourceLoader;

  Future<List<SourceLibraryBuilder>> applyTypeMacros(
      SourceLoader sourceLoader) async {
    identifierResolver = new _IdentifierResolver(sourceLoader);
    List<SourceLibraryBuilder> augmentationLibraries = [];
    Map<SourceLibraryBuilder, List<macro.MacroExecutionResult>> results = {};
    for (_ApplicationData macroApplication in _applicationData) {
      List<macro.MacroExecutionResult> executionResults =
          await _applyTypeMacros(macroApplication);
      if (executionResults.isNotEmpty) {
        (results[macroApplication.libraryBuilder] ??= [])
            .addAll(executionResults);
      }
    }
    for (MapEntry<SourceLibraryBuilder, List<macro.MacroExecutionResult>> entry
        in results.entries) {
      SourceLibraryBuilder sourceLibraryBuilder = entry.key;
      assert(entry.value.isNotEmpty);
      String result = _macroExecutor
          .buildAugmentationLibrary(
              entry.value, _resolveIdentifier, _inferOmittedType)
          .trim();
      assert(
          result.trim().isNotEmpty,
          "Empty types phase augmentation library source for "
          "$sourceLibraryBuilder}");
      if (result.isNotEmpty) {
        if (retainDataForTesting) {
          dataForTesting?.libraryTypesResult[sourceLibraryBuilder] = result;
        }
        augmentationLibraries
            .add(await sourceLibraryBuilder.createAugmentationLibrary(result));
      }
    }
    return augmentationLibraries;
  }

  Future<void> _applyDeclarationsMacros(_ApplicationData applicationData,
      Future<void> Function(SourceLibraryBuilder) onAugmentationLibrary) async {
    List<macro.MacroExecutionResult> results = [];
    macro.Declaration declaration = applicationData.declaration;
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          _declarationKind(declaration), macro.Phase.declarations)) {
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDeclarationsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                identifierResolver,
                typeResolver,
                classIntrospector);
        if (result.isNotEmpty) {
          String source = _macroExecutor.buildAugmentationLibrary(
              [result], _resolveIdentifier, _inferOmittedType);
          SourceLibraryBuilder augmentationLibrary = await applicationData
              .libraryBuilder
              .createAugmentationLibrary(source);
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
  late macro.TypeResolver typeResolver;
  late macro.ClassIntrospector classIntrospector;

  Future<void> applyDeclarationsMacros(ClassHierarchyBuilder classHierarchy,
      Future<void> Function(SourceLibraryBuilder) onAugmentationLibrary) async {
    types = new Types(classHierarchy);
    typeResolver = new _TypeResolver(this);
    classIntrospector = new _ClassIntrospector(this, classHierarchy);
    for (_ApplicationData macroApplication in _applicationData) {
      await _applyDeclarationsMacros(macroApplication, onAugmentationLibrary);
    }
  }

  Future<List<macro.MacroExecutionResult>> _applyDefinitionMacros(
      _ApplicationData applicationData) async {
    List<macro.MacroExecutionResult> results = [];
    macro.Declaration declaration = applicationData.declaration;
    for (MacroApplication macroApplication
        in applicationData.macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          _declarationKind(declaration), macro.Phase.definitions)) {
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDefinitionsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                identifierResolver,
                typeResolver,
                classIntrospector,
                typeDeclarationResolver);
        if (result.isNotEmpty) {
          results.add(result);
        }
      }
    }
    if (retainDataForTesting) {
      Builder builder = applicationData.builder;
      if (builder is SourceClassBuilder) {
        dataForTesting?.classDefinitionsResults[builder] = results;
      } else {
        dataForTesting?.memberDefinitionsResults[builder as MemberBuilder] =
            results;
      }
    }
    return results;
  }

  late macro.TypeDeclarationResolver typeDeclarationResolver;

  Future<List<SourceLibraryBuilder>> applyDefinitionMacros() async {
    typeDeclarationResolver = new _TypeDeclarationResolver(this);
    List<SourceLibraryBuilder> augmentationLibraries = [];
    Map<SourceLibraryBuilder, List<macro.MacroExecutionResult>> results = {};
    for (_ApplicationData macroApplication in _applicationData) {
      List<macro.MacroExecutionResult> executionResults =
          await _applyDefinitionMacros(macroApplication);
      if (executionResults.isNotEmpty) {
        (results[macroApplication.libraryBuilder] ??= [])
            .addAll(executionResults);
      }
    }
    for (MapEntry<SourceLibraryBuilder, List<macro.MacroExecutionResult>> entry
        in results.entries) {
      SourceLibraryBuilder sourceLibraryBuilder = entry.key;
      String result = _macroExecutor.buildAugmentationLibrary(
          entry.value, _resolveIdentifier, _inferOmittedType);
      assert(
          result.trim().isNotEmpty,
          "Empty definitions phase augmentation library source for "
          "$sourceLibraryBuilder}");
      if (retainDataForTesting) {
        dataForTesting?.libraryDefinitionResult[sourceLibraryBuilder] = result;
      }
      augmentationLibraries
          .add(await sourceLibraryBuilder.createAugmentationLibrary(result));
    }
    return augmentationLibraries;
  }

  void close() {
    _macroExecutor.close();
    _staticTypeCache.clear();
    _typeAnnotationCache.clear();
    _applicationDataCache?.clear();
  }

  macro.ClassDeclaration _createClassDeclaration(ClassBuilder builder) {
    macro.ClassDeclaration declaration = new macro.ClassDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: builder,
            libraryBuilder: builder.library,
            id: macro.RemoteInstance.uniqueId,
            name: builder.name),
        // TODO(johnniwinther): Support typeParameters
        typeParameters: [],
        // TODO(johnniwinther): Support interfaces
        interfaces: [],
        isAbstract: builder.isAbstract,
        isExternal: builder.isExternal,
        // TODO(johnniwinther): Support mixins
        mixins: [],
        // TODO(johnniwinther): Support superclass
        superclass: null);
    _classBuilders[declaration] = builder;
    return declaration;
  }

  macro.TypeAliasDeclaration _createTypeAliasDeclaration(
      TypeAliasBuilder builder) {
    macro.TypeAliasDeclaration declaration = new macro.TypeAliasDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: new TypeDeclarationBuilderIdentifier(
            typeDeclarationBuilder: builder,
            libraryBuilder: builder.library,
            id: macro.RemoteInstance.uniqueId,
            name: builder.name),
        // TODO(johnniwinther): Support typeParameters
        typeParameters: [],
        aliasedType: _computeTypeAnnotation(builder.library, builder.type));
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
            computeTypeAnnotation(builder.library, formal.type);
        macro.IdentifierImpl identifier = new FormalParameterBuilderIdentifier(
            id: macro.RemoteInstance.uniqueId,
            name: formal.name,
            parameterBuilder: formal,
            libraryBuilder: builder.library);
        if (formal.isNamed) {
          namedParameters.add(new macro.ParameterDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            isRequired: formal.isNamedRequired,
            isNamed: true,
            type: type,
          ));
        } else {
          positionalParameters.add(new macro.ParameterDeclarationImpl(
            id: macro.RemoteInstance.uniqueId,
            identifier: identifier,
            isRequired: formal.isRequired,
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
    macro.ClassDeclaration definingClass =
        getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: builder.name),
      definingClass: definingClass.identifier as macro.IdentifierImpl,
      isFactory: builder.isFactory,
      isAbstract: builder.isAbstract,
      isExternal: builder.isExternal,
      isGetter: builder.isGetter,
      isOperator: builder.isOperator,
      isSetter: builder.isSetter,
      positionalParameters: parameters[0],
      namedParameters: parameters[1],
      // TODO(johnniwinther): Support constructor return type.
      returnType: computeTypeAnnotation(builder.library, null),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const [],
    );
  }

  macro.ConstructorDeclaration _createFactoryDeclaration(
      SourceFactoryBuilder builder) {
    List<List<macro.ParameterDeclarationImpl>> parameters =
        _createParameters(builder, builder.formals);
    macro.ClassDeclaration definingClass =
        getClassDeclaration(builder.classBuilder as SourceClassBuilder);

    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new MemberBuilderIdentifier(
          memberBuilder: builder,
          id: macro.RemoteInstance.uniqueId,
          name: builder.name),
      definingClass: definingClass.identifier as macro.IdentifierImpl,
      isFactory: builder.isFactory,
      isAbstract: builder.isAbstract,
      isExternal: builder.isExternal,
      isGetter: builder.isGetter,
      isOperator: builder.isOperator,
      isSetter: builder.isSetter,
      positionalParameters: parameters[0],
      namedParameters: parameters[1],
      // TODO(johnniwinther): Support constructor return type.
      returnType: computeTypeAnnotation(builder.library, null),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const [],
    );
  }

  macro.FunctionDeclaration _createFunctionDeclaration(
      SourceProcedureBuilder builder) {
    List<List<macro.ParameterDeclarationImpl>> parameters =
        _createParameters(builder, builder.formals);

    macro.ClassDeclaration? definingClass = null;
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
          definingClass: definingClass.identifier as macro.IdentifierImpl,
          isAbstract: builder.isAbstract,
          isExternal: builder.isExternal,
          isGetter: builder.isGetter,
          isOperator: builder.isOperator,
          isSetter: builder.isSetter,
          isStatic: builder.isStatic,
          positionalParameters: parameters[0],
          namedParameters: parameters[1],
          returnType:
              computeTypeAnnotation(builder.library, builder.returnType),
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
              computeTypeAnnotation(builder.library, builder.returnType),
          // TODO(johnniwinther): Support typeParameters
          typeParameters: const []);
    }
  }

  macro.VariableDeclaration _createVariableDeclaration(
      SourceFieldBuilder builder) {
    macro.ClassDeclaration? definingClass = null;
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
          definingClass: definingClass.identifier as macro.IdentifierImpl,
          isExternal: builder.isExternal,
          isFinal: builder.isFinal,
          isLate: builder.isLate,
          isStatic: builder.isStatic,
          type: computeTypeAnnotation(builder.library, builder.type));
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
          type: computeTypeAnnotation(builder.library, builder.type));
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

class _StaticTypeImpl extends macro.StaticType {
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

class _ClassIntrospector implements macro.ClassIntrospector {
  final MacroApplications macroApplications;
  final ClassHierarchyBuilder classHierarchy;

  _ClassIntrospector(this.macroApplications, this.classHierarchy);

  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
      macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    List<macro.ConstructorDeclaration> result = [];
    classBuilder.forEachConstructor((_, MemberBuilder memberBuilder) {
      if (memberBuilder is DeclaredSourceConstructorBuilder) {
        // TODO(johnniwinther): Should we support synthesized constructors?
        result.add(macroApplications._getMemberDeclaration(memberBuilder)
            as macro.ConstructorDeclaration);
      } else if (memberBuilder is SourceFactoryBuilder) {
        result.add(macroApplications._getMemberDeclaration(memberBuilder)
            as macro.ConstructorDeclaration);
      }
    });
    return new Future.value(result);
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    List<macro.FieldDeclaration> result = [];
    classBuilder.forEach((_, Builder memberBuilder) {
      if (memberBuilder is SourceFieldBuilder) {
        result.add(macroApplications._getMemberDeclaration(memberBuilder)
            as macro.FieldDeclaration);
      }
    });
    return new Future.value(result);
  }

  @override
  Future<List<macro.ClassDeclaration>> interfacesOf(
      macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    ClassHierarchyNode node =
        classHierarchy.getNodeFromClassBuilder(classBuilder);
    List<ClassHierarchyNode>? directInterfaceNodes = node.directInterfaceNodes;
    if (directInterfaceNodes != null) {
      List<macro.ClassDeclaration> list = [];
      for (ClassHierarchyNode interfaceNode in directInterfaceNodes) {
        list.add(
            macroApplications.getClassDeclaration(interfaceNode.classBuilder));
      }
      return new Future.value(list);
    }
    return new Future.value(const []);
  }

  @override
  Future<List<macro.MethodDeclaration>> methodsOf(
      macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    List<macro.MethodDeclaration> result = [];
    classBuilder.forEach((_, Builder memberBuilder) {
      if (memberBuilder is SourceProcedureBuilder) {
        result.add(macroApplications._getMemberDeclaration(memberBuilder)
            as macro.MethodDeclaration);
      }
    });
    return new Future.value(result);
  }

  @override
  Future<List<macro.ClassDeclaration>> mixinsOf(macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    ClassHierarchyNode node =
        classHierarchy.getNodeFromClassBuilder(classBuilder);
    ClassHierarchyNode? superNode = node.directSuperClassNode;
    List<macro.ClassDeclaration>? list;
    while (superNode != null && superNode.isMixinApplication) {
      (list ??= []).add(macroApplications
          .getClassDeclaration(superNode.mixedInNode!.classBuilder));
      superNode = superNode.directSuperClassNode;
    }
    return new Future.value(list?.reversed.toList() ?? const []);
  }

  @override
  Future<macro.ClassDeclaration?> superclassOf(macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    ClassHierarchyNode node =
        classHierarchy.getNodeFromClassBuilder(classBuilder);
    ClassHierarchyNode? superNode = node.directSuperClassNode;
    while (superNode != null &&
        superNode.classBuilder.isAnonymousMixinApplication) {
      superNode = superNode.directSuperClassNode;
    }
    if (superNode != null) {
      return new Future.value(
          macroApplications.getClassDeclaration(superNode.classBuilder));
    }
    return new Future.value();
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
    return macro.DeclarationKind.clazz;
  }
  throw new UnsupportedError(
      "Unexpected declaration ${declaration} (${declaration.runtimeType})");
}

/// Data needed to apply a list of macro applications to a class or member.
class _ApplicationData {
  final SourceLibraryBuilder libraryBuilder;
  final Builder builder;
  final macro.Declaration declaration;
  final List<MacroApplication> macroApplications;

  _ApplicationData(this.libraryBuilder, this.builder, this.declaration,
      this.macroApplications);
}

extension on macro.MacroExecutionResult {
  bool get isNotEmpty =>
      libraryAugmentations.isNotEmpty || classAugmentations.isNotEmpty;
}
