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

import '../../base/common.dart';
import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../identifiers.dart';
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_procedure_builder.dart';
import 'hierarchy/hierarchy_builder.dart';
import 'hierarchy/hierarchy_node.dart';

bool enableMacros = false;

final Uri macroLibraryUri =
    Uri.parse('package:_fe_analyzer_shared/src/macros/api.dart');
const String macroClassName = 'Macro';
final macro.IdentifierImpl dynamicIdentifier = new macro.IdentifierImpl(
    id: macro.RemoteInstance.uniqueId, name: 'dynamic');

class MacroDeclarationData {
  bool macrosAreAvailable = false;
  Map<Uri, List<String>> macroDeclarations = {};
  List<List<Uri>>? compilationSequence;
  List<Map<Uri, Map<String, List<String>>>> neededPrecompilations = [];
}

class MacroClass {
  final Uri importUri;
  final String className;

  const MacroClass(this.importUri, this.className);

  @override
  int get hashCode => importUri.hashCode * 13 + className.hashCode * 17;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MacroClass &&
        importUri == other.importUri &&
        className == other.className;
  }
}

class MacroApplication {
  final ClassBuilder classBuilder;
  final String constructorName;

  // TODO(johnniwinther): Add support for arguments.

  MacroApplication(this.classBuilder, this.constructorName);

  late macro.MacroInstanceIdentifier instanceIdentifier;
}

class MacroApplicationDataForTesting {
  Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData = {};
  Map<SourceLibraryBuilder, String> libraryTypesResult = {};
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
      Map<MacroClass, Uri> precompiledMacroUris,
      Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData,
      MacroApplicationDataForTesting? dataForTesting) async {
    Map<ClassBuilder, macro.MacroClassIdentifier> classIdCache = {};

    Map<MacroApplication, macro.MacroInstanceIdentifier> instanceIdCache = {};

    Future<void> ensureMacroClassIds(
        List<MacroApplication>? applications) async {
      if (applications != null) {
        for (MacroApplication application in applications) {
          MacroClass macroClass = new MacroClass(
              application.classBuilder.library.importUri,
              application.classBuilder.name);
          Uri? precompiledMacroUri = precompiledMacroUris[macroClass];
          macro.MacroClassIdentifier macroClassIdentifier =
              classIdCache[application.classBuilder] ??= await macroExecutor
                  .loadMacro(macroClass.importUri, macroClass.className,
                      precompiledKernelUri: precompiledMacroUri);
          application.instanceIdentifier = instanceIdCache[application] ??=
              await macroExecutor.instantiateMacro(
                  macroClassIdentifier,
                  application.constructorName,
                  // TODO(johnniwinther): Support macro arguments.
                  new macro.Arguments([], {}));
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
  Map<MemberBuilder, macro.Declaration?> _memberDeclarations = {};

  // TODO(johnniwinther): Support all members.
  macro.Declaration? _getMemberDeclaration(MemberBuilder memberBuilder) {
    return _memberDeclarations[memberBuilder] ??=
        _createMemberDeclaration(memberBuilder);
  }

  macro.ClassDeclaration _getClassDeclaration(ClassBuilder builder) {
    return _classDeclarations[builder] ??= _createClassDeclaration(builder);
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
    if (identifier is _IdentifierImpl) {
      MemberBuilder? memberBuilder = identifier.memberBuilder;
      TypeBuilder? typeBuilder = identifier.typeBuilder;
      FormalParameterBuilder? parameterBuilder = identifier.parameterBuilder;
      if (memberBuilder != null) {
        Uri? uri;
        String? staticScope;
        macro.IdentifierKind kind;
        if (memberBuilder.isStatic || memberBuilder.isConstructor) {
          ClassBuilder classBuilder = memberBuilder.classBuilder!;
          staticScope = classBuilder.name;
          uri = classBuilder.library.importUri;
          kind = macro.IdentifierKind.staticInstanceMember;
        } else if (memberBuilder.isTopLevel) {
          uri = memberBuilder.library.importUri;
          kind = macro.IdentifierKind.topLevelMember;
        } else {
          kind = macro.IdentifierKind.instanceMember;
        }
        return new macro.ResolvedIdentifier(
            kind: kind,
            name: identifier.name,
            staticScope: staticScope,
            uri: uri);
      } else if (typeBuilder != null) {
        TypeDeclarationBuilder typeDeclarationBuilder =
            typeBuilder.declaration!;
        Uri? uri;
        if (typeDeclarationBuilder is ClassBuilder) {
          uri = typeDeclarationBuilder.library.importUri;
        } else if (typeDeclarationBuilder is TypeAliasBuilder) {
          uri = typeDeclarationBuilder.library.importUri;
        } else if (identifier.name == 'dynamic') {
          uri = Uri.parse('dart:core');
        }
        return new macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.topLevelMember,
            name: identifier.name,
            staticScope: null,
            uri: uri);
      } else if (parameterBuilder != null) {
        return new macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.local,
            name: identifier.name,
            staticScope: null,
            uri: null);
      } else {
        throw new StateError('Unable to resolve identifier $identifier');
      }
    } else {
      // TODO(johnniwinther): Use [_IdentifierImpl] for all identifiers.
      if (identical(identifier, dynamicIdentifier)) {
        return new macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.topLevelMember,
            name: identifier.name,
            staticScope: null,
            uri: Uri.parse('dart:core'));
      } else {
        return new macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.topLevelMember,
            name: identifier.name,
            staticScope: null,
            uri: null);
      }
    }
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
                _getClassDeclaration(classBuilder);
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
                macroApplication.instanceIdentifier, declaration);
        results.add(result);
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

  Future<List<SourceLibraryBuilder>> applyTypeMacros() async {
    List<SourceLibraryBuilder> augmentationLibraries = [];
    Map<SourceLibraryBuilder, List<macro.MacroExecutionResult>> results = {};
    for (_ApplicationData macroApplication in _applicationData) {
      List<macro.MacroExecutionResult> executionResults =
          await _applyTypeMacros(macroApplication);
      (results[macroApplication.libraryBuilder] ??= [])
          .addAll(executionResults);
    }
    for (MapEntry<SourceLibraryBuilder, List<macro.MacroExecutionResult>> entry
        in results.entries) {
      SourceLibraryBuilder sourceLibraryBuilder = entry.key;
      String result = _macroExecutor.buildAugmentationLibrary(
          entry.value, _resolveIdentifier);
      if (retainDataForTesting) {
        dataForTesting?.libraryTypesResult[sourceLibraryBuilder] = result;
      }
      augmentationLibraries
          .add(await sourceLibraryBuilder.createAugmentationLibrary(result));
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
                typeResolver,
                classIntrospector);
        String source = _macroExecutor
            .buildAugmentationLibrary([result], _resolveIdentifier);
        SourceLibraryBuilder augmentationLibrary = await applicationData
            .libraryBuilder
            .createAugmentationLibrary(source);
        await onAugmentationLibrary(augmentationLibrary);
        if (retainDataForTesting) {
          results.add(result);
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
                typeResolver,
                classIntrospector,
                typeDeclarationResolver);
        results.add(result);
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

  Future<void> applyDefinitionMacros() async {
    typeDeclarationResolver = new _TypeDeclarationResolver();
    for (_ApplicationData macroApplication in _applicationData) {
      await _applyDefinitionMacros(macroApplication);
    }
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
        identifier: new _IdentifierImpl.forTypeDeclarationBuilder(
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
        macro.IdentifierImpl identifier =
            new _IdentifierImpl.forParameterBuilder(
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
        _getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new _IdentifierImpl.forMemberBuilder(
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
        _getClassDeclaration(builder.classBuilder as SourceClassBuilder);

    return new macro.ConstructorDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: new _IdentifierImpl.forMemberBuilder(
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
          _getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    }
    if (definingClass != null) {
      // TODO(johnniwinther): Should static fields be field or variable
      //  declarations?
      return new macro.MethodDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new _IdentifierImpl.forMemberBuilder(
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
          identifier: new _IdentifierImpl.forMemberBuilder(
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
          _getClassDeclaration(builder.classBuilder as SourceClassBuilder);
    }
    if (definingClass != null) {
      // TODO(johnniwinther): Should static fields be field or variable
      //  declarations?
      return new macro.FieldDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new macro.IdentifierImpl(
              id: macro.RemoteInstance.uniqueId, name: builder.name),
          definingClass: definingClass.identifier as macro.IdentifierImpl,
          isExternal: builder.isExternal,
          isFinal: builder.isFinal,
          isLate: builder.isLate,
          isStatic: builder.isStatic,
          type: computeTypeAnnotation(builder.library, builder.type));
    } else {
      return new macro.VariableDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: new macro.IdentifierImpl(
              id: macro.RemoteInstance.uniqueId, name: builder.name),
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
              identifier: new _IdentifierImpl.forTypeBuilder(
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
              identifier: new _IdentifierImpl.forTypeBuilder(
                  typeBuilder: typeBuilder,
                  libraryBuilder: libraryBuilder,
                  id: macro.RemoteInstance.uniqueId,
                  // TODO: We probably shouldn't be including the qualifier
                  // here. Kernel should probably have its own implementation
                  // of Identifier which holds on to the qualified reference
                  // instead.
                  name: '${name.qualifier}.${name.name}'),
              typeArguments: typeArguments,
              isNullable: isNullable);
        }
      }
    }
    return new macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: dynamicIdentifier,
        isNullable: false,
        typeArguments: const []);
  }

  macro.TypeAnnotationImpl computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    return _typeAnnotationCache[typeBuilder] ??=
        _computeTypeAnnotation(libraryBuilder, typeBuilder);
  }

  TypeBuilder _typeBuilderForAnnotation(
      macro.TypeAnnotationCode typeAnnotation) {
    NullabilityBuilder nullabilityBuilder;
    if (typeAnnotation is macro.NullableTypeAnnotationCode) {
      nullabilityBuilder = const NullabilityBuilder.nullable();
      typeAnnotation = typeAnnotation.underlyingType;
    } else {
      nullabilityBuilder = const NullabilityBuilder.omitted();
    }

    if (typeAnnotation is macro.NamedTypeAnnotationCode) {
      _IdentifierImpl typeIdentifier = typeAnnotation.name as _IdentifierImpl;
      TypeDeclarationBuilder? typeDeclarationBuilder =
          typeIdentifier.typeDeclarationBuilder;
      InstanceTypeVariableAccessState instanceTypeVariableAccessState =
          InstanceTypeVariableAccessState.Unexpected;
      if (typeDeclarationBuilder == null) {
        TypeBuilder? originalTypeBuilder = typeIdentifier.typeBuilder;

        if (originalTypeBuilder == null) {
          throw new StateError('No type builder for $typeIdentifier');
        }
        if (originalTypeBuilder is! NamedTypeBuilder) {
          throw new StateError(
              'Type $typeIdentifier was not a named type as expected!');
        }
        typeDeclarationBuilder = originalTypeBuilder.declaration!;
        instanceTypeVariableAccessState =
            originalTypeBuilder.instanceTypeVariableAccess;
      }
      List<TypeBuilder> arguments = [
        for (macro.TypeAnnotationCode argumentCode
            in typeAnnotation.typeArguments)
          _typeBuilderForAnnotation(argumentCode),
      ];

      return new NamedTypeBuilder.fromTypeDeclarationBuilder(
          typeDeclarationBuilder, nullabilityBuilder,
          instanceTypeVariableAccess: instanceTypeVariableAccessState,
          arguments: arguments);
    }
    // TODO: Implement support for function types.
    throw new UnimplementedError(
        'Unimplemented type annotation kind ${typeAnnotation.kind}');
  }

  macro.StaticType resolveTypeAnnotation(
      macro.TypeAnnotationCode typeAnnotation) {
    TypeBuilder typeBuilder = _typeBuilderForAnnotation(typeAnnotation);
    // TODO: This should probably be passed in instead, possibly attached to the
    // TypeResolver class?
    LibraryBuilder libraryBuilder =
        typeAnnotation.parts.whereType<_IdentifierImpl>().first.libraryBuilder;
    return createStaticType(typeBuilder.build(libraryBuilder));
  }

  Map<DartType, _StaticTypeImpl> _staticTypeCache = {};

  macro.StaticType createStaticType(DartType dartType) {
    return _staticTypeCache[dartType] ??= new _StaticTypeImpl(this, dartType);
  }
}

class _IdentifierImpl extends macro.IdentifierImpl {
  final TypeDeclarationBuilder? typeDeclarationBuilder;
  final MemberBuilder? memberBuilder;
  final TypeBuilder? typeBuilder;
  final LibraryBuilder libraryBuilder;
  final FormalParameterBuilder? parameterBuilder;

  _IdentifierImpl.forTypeBuilder({
    required TypeBuilder this.typeBuilder,
    required this.libraryBuilder,
    required int id,
    required String name,
  })  : typeDeclarationBuilder = null,
        memberBuilder = null,
        parameterBuilder = null,
        super(id: id, name: name);

  _IdentifierImpl.forTypeDeclarationBuilder({
    required TypeDeclarationBuilder this.typeDeclarationBuilder,
    required this.libraryBuilder,
    required int id,
    required String name,
  })  : typeBuilder = null,
        memberBuilder = null,
        parameterBuilder = null,
        super(id: id, name: name);

  _IdentifierImpl.forMemberBuilder(
      {required MemberBuilder this.memberBuilder,
      required int id,
      required String name})
      : typeBuilder = null,
        typeDeclarationBuilder = null,
        parameterBuilder = null,
        libraryBuilder = memberBuilder.library,
        super(id: id, name: name);

  _IdentifierImpl.forParameterBuilder({
    required FormalParameterBuilder this.parameterBuilder,
    required this.libraryBuilder,
    required int id,
    required String name,
  })  : typeBuilder = null,
        typeDeclarationBuilder = null,
        memberBuilder = null,
        super(id: id, name: name);
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
      }
    });
    classBuilder.forEach((_, Builder memberBuilder) {
      if (memberBuilder is SourceFactoryBuilder) {
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
    // TODO: implement interfacesOf
    throw new UnimplementedError('_ClassIntrospector.interfacesOf');
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
    // TODO: implement mixinsOf
    throw new UnimplementedError('_ClassIntrospector.mixinsOf');
  }

  @override
  Future<macro.ClassDeclaration?> superclassOf(macro.ClassDeclaration clazz) {
    ClassBuilder classBuilder = macroApplications._getClassBuilder(clazz);
    ClassHierarchyNode node =
        classHierarchy.getNodeFromClassBuilder(classBuilder);
    ClassHierarchyNode? superNode = node.supernode;
    while (superNode != null &&
        superNode.classBuilder.isAnonymousMixinApplication) {
      superNode = superNode.supernode;
    }
    if (superNode != null) {
      return new Future.value(
          macroApplications._getClassDeclaration(superNode.classBuilder));
    }
    return new Future.value();
  }
}

class _TypeDeclarationResolver implements macro.TypeDeclarationResolver {
  @override
  Future<macro.TypeDeclaration> declarationOf(macro.Identifier identifier) {
    // TODO: implement declarationOf
    throw new UnimplementedError('_TypeDeclarationResolver.declarationOf');
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
