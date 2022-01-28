// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart'
    as macro;
import 'package:kernel/ast.dart' show DartType, DynamicType;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/types.dart';
import 'package:kernel/type_environment.dart' show SubtypeCheckMode;

import '../builder/class_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_builder.dart';
import '../identifiers.dart';
import '../source/source_class_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_procedure_builder.dart';

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

class MacroApplications {
  final macro.MacroExecutor _macroExecutor;
  final Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData;
  final MacroApplicationDataForTesting? dataForTesting;

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

  Map<MemberBuilder, macro.Declaration?> _memberDeclarations = {};

  // TODO(johnniwinther): Support all members.
  macro.Declaration? _getMemberDeclaration(MemberBuilder memberBuilder) {
    return _memberDeclarations[memberBuilder] ??=
        _createMemberDeclaration(memberBuilder);
  }

  macro.Declaration? _createMemberDeclaration(MemberBuilder memberBuilder) {
    if (memberBuilder is SourceProcedureBuilder) {
      return createTopLevelFunctionDeclaration(memberBuilder);
    } else {
      // TODO(johnniwinther): Throw when all members are supported.
      //throw new UnimplementedError('Unsupported member ${memberBuilder}');
      return null;
    }
  }

  Future<List<macro.MacroExecutionResult>> _applyTypeMacros(
      macro.Declaration declaration,
      List<MacroApplication> macroApplications) async {
    List<macro.MacroExecutionResult> results = [];
    for (MacroApplication macroApplication in macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          // TODO(johnniwinther): Get the declaration kind from [declaration].
          macro.DeclarationKind.function,
          macro.Phase.types)) {
        macro.MacroExecutionResult result =
            await _macroExecutor.executeTypesPhase(
                macroApplication.instanceIdentifier, declaration);
        results.add(result);
      }
    }
    return results;
  }

  Future<void> applyTypeMacros() async {
    for (MapEntry<SourceLibraryBuilder,
        LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
      LibraryMacroApplicationData libraryMacroApplicationData =
          libraryEntry.value;
      for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        macro.Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          List<macro.MacroExecutionResult> results =
              await _applyTypeMacros(declaration, memberEntry.value);
          dataForTesting?.memberTypesResults[memberBuilder] = results;
        }
      }
    }
  }

  Future<List<macro.MacroExecutionResult>> _applyDeclarationMacros(
      macro.Declaration declaration,
      List<MacroApplication> macroApplications,
      macro.TypeResolver typeResolver,
      macro.ClassIntrospector classIntrospector) async {
    List<macro.MacroExecutionResult> results = [];
    for (MacroApplication macroApplication in macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          // TODO(johnniwinther): Get the declaration kind from [declaration].
          macro.DeclarationKind.function,
          macro.Phase.declarations)) {
        macro.MacroExecutionResult result =
            await _macroExecutor.executeDeclarationsPhase(
                macroApplication.instanceIdentifier,
                declaration,
                typeResolver,
                classIntrospector);
        results.add(result);
      }
    }
    return results;
  }

  late Types types;
  late macro.TypeResolver typeResolver;
  late macro.ClassIntrospector classIntrospector;

  Future<void> applyDeclarationMacros(ClassHierarchyBase classHierarchy) async {
    types = new Types(classHierarchy);
    typeResolver = new _TypeResolver(this);
    classIntrospector = new _ClassIntrospector();
    for (MapEntry<SourceLibraryBuilder,
        LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
      LibraryMacroApplicationData libraryMacroApplicationData =
          libraryEntry.value;
      for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        macro.Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          List<macro.MacroExecutionResult> results =
              await _applyDeclarationMacros(declaration, memberEntry.value,
                  typeResolver, classIntrospector);
          dataForTesting?.memberDeclarationsResults[memberBuilder] = results;
        }
      }
    }
  }

  Future<List<macro.MacroExecutionResult>> _applyDefinitionMacros(
      macro.Declaration declaration,
      List<MacroApplication> macroApplications,
      macro.TypeResolver typeResolver,
      macro.ClassIntrospector classIntrospector,
      macro.TypeDeclarationResolver typeDeclarationResolver) async {
    List<macro.MacroExecutionResult> results = [];
    for (MacroApplication macroApplication in macroApplications) {
      if (macroApplication.instanceIdentifier.shouldExecute(
          // TODO(johnniwinther): Get the declaration kind from [declaration].
          macro.DeclarationKind.function,
          macro.Phase.definitions)) {
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
    return results;
  }

  Future<void> applyDefinitionMacros() async {
    macro.TypeDeclarationResolver typeDeclarationResolver =
        new _TypeDeclarationResolver();
    for (MapEntry<SourceLibraryBuilder,
        LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
      LibraryMacroApplicationData libraryMacroApplicationData =
          libraryEntry.value;
      for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        macro.Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          List<macro.MacroExecutionResult> results =
              await _applyDefinitionMacros(declaration, memberEntry.value,
                  typeResolver, classIntrospector, typeDeclarationResolver);
          dataForTesting?.memberDefinitionsResults[memberBuilder] = results;
        }
      }
    }
  }

  void close() {
    _macroExecutor.close();
    _staticTypeCache.clear();
    _typeAnnotationCache.clear();
  }

  macro.FunctionDeclaration createTopLevelFunctionDeclaration(
      SourceProcedureBuilder builder) {
    List<macro.ParameterDeclarationImpl>? positionalParameters;
    List<macro.ParameterDeclarationImpl>? namedParameters;

    List<FormalParameterBuilder>? formals = builder.formals;
    if (formals == null) {
      positionalParameters = namedParameters = const [];
    } else {
      positionalParameters = [];
      namedParameters = [];
      for (FormalParameterBuilder formal in formals) {
        macro.TypeAnnotationImpl type =
            computeTypeAnnotation(builder.library, formal.type);
        // TODO(johnniwinther): Support default values.
        if (formal.isNamed) {
          namedParameters.add(new macro.ParameterDeclarationImpl(
              id: macro.RemoteInstance.uniqueId,
              identifier: new macro.IdentifierImpl(
                  id: macro.RemoteInstance.uniqueId, name: formal.name),
              isRequired: formal.isNamedRequired,
              isNamed: true,
              type: type,
              defaultValue: null));
        } else {
          positionalParameters.add(new macro.ParameterDeclarationImpl(
              id: macro.RemoteInstance.uniqueId,
              identifier: new macro.IdentifierImpl(
                  id: macro.RemoteInstance.uniqueId, name: formal.name),
              isRequired: formal.isRequired,
              isNamed: false,
              type: type,
              defaultValue: null));
        }
      }
    }

    return new macro.FunctionDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: new macro.IdentifierImpl(
            id: macro.RemoteInstance.uniqueId, name: builder.name),
        isAbstract: builder.isAbstract,
        isExternal: builder.isExternal,
        isGetter: builder.isGetter,
        isSetter: builder.isSetter,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        returnType: computeTypeAnnotation(builder.library, builder.returnType),
        // TODO(johnniwinther): Support typeParameters
        typeParameters: const []);
  }

  Map<TypeBuilder?, _NamedTypeAnnotationImpl> _typeAnnotationCache = {};

  List<macro.TypeAnnotationImpl> computeTypeAnnotations(
      LibraryBuilder library, List<TypeBuilder>? typeBuilders) {
    if (typeBuilders == null) return const [];
    return new List.generate(typeBuilders.length,
        (int index) => computeTypeAnnotation(library, typeBuilders[index]));
  }

  _NamedTypeAnnotationImpl _computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    if (typeBuilder != null) {
      if (typeBuilder is NamedTypeBuilder) {
        Object name = typeBuilder.name;
        List<macro.TypeAnnotationImpl> typeArguments =
            computeTypeAnnotations(libraryBuilder, typeBuilder.arguments);
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        if (name is String) {
          return new _NamedTypeAnnotationImpl(
              typeBuilder: typeBuilder,
              libraryBuilder: libraryBuilder,
              id: macro.RemoteInstance.uniqueId,
              identifier: new macro.IdentifierImpl(
                  id: macro.RemoteInstance.uniqueId, name: name),
              typeArguments: typeArguments,
              isNullable: isNullable);
        } else if (name is QualifiedName) {
          assert(name.qualifier is String);
          return new _NamedTypeAnnotationImpl(
              typeBuilder: typeBuilder,
              libraryBuilder: libraryBuilder,
              id: macro.RemoteInstance.uniqueId,
              identifier: new macro.IdentifierImpl(
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
    return new _NamedTypeAnnotationImpl(
        typeBuilder: typeBuilder,
        libraryBuilder: libraryBuilder,
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

  macro.StaticType resolveTypeAnnotation(
      _NamedTypeAnnotationImpl typeAnnotation) {
    TypeBuilder? typeBuilder = typeAnnotation.typeBuilder;
    LibraryBuilder libraryBuilder = typeAnnotation.libraryBuilder;
    DartType dartType;
    if (typeBuilder != null) {
      dartType = typeBuilder.build(libraryBuilder);
    } else {
      dartType = const DynamicType();
    }
    return createStaticType(dartType);
  }

  Map<DartType, _StaticTypeImpl> _staticTypeCache = {};

  macro.StaticType createStaticType(DartType dartType) {
    return _staticTypeCache[dartType] ??= new _StaticTypeImpl(this, dartType);
  }
}

class _NamedTypeAnnotationImpl extends macro.NamedTypeAnnotationImpl {
  final TypeBuilder? typeBuilder;
  final LibraryBuilder libraryBuilder;

  _NamedTypeAnnotationImpl({
    required this.typeBuilder,
    required this.libraryBuilder,
    required int id,
    required bool isNullable,
    required macro.IdentifierImpl identifier,
    required List<macro.TypeAnnotationImpl> typeArguments,
  }) : super(
            id: id,
            isNullable: isNullable,
            identifier: identifier,
            typeArguments: typeArguments);
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
  Future<macro.StaticType> instantiateCode(macro.ExpressionCode code) {
    // TODO: implement instantiateCode
    throw new UnimplementedError();
  }

  @override
  Future<macro.StaticType> instantiateType(
      covariant _NamedTypeAnnotationImpl typeAnnotation) {
    return new Future.value(
        macroApplications.resolveTypeAnnotation(typeAnnotation));
  }
}

class _ClassIntrospector implements macro.ClassIntrospector {
  @override
  Future<List<macro.ConstructorDeclaration>> constructorsOf(
      macro.ClassDeclaration clazz) {
    // TODO: implement constructorsOf
    throw new UnimplementedError('_ClassIntrospector.constructorsOf');
  }

  @override
  Future<List<macro.FieldDeclaration>> fieldsOf(macro.ClassDeclaration clazz) {
    // TODO: implement fieldsOf
    throw new UnimplementedError('_ClassIntrospector.fieldsOf');
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
    // TODO: implement methodsOf
    throw new UnimplementedError('_ClassIntrospector.methodsOf');
  }

  @override
  Future<List<macro.ClassDeclaration>> mixinsOf(macro.ClassDeclaration clazz) {
    // TODO: implement mixinsOf
    throw new UnimplementedError('_ClassIntrospector.mixinsOf');
  }

  @override
  Future<macro.ClassDeclaration?> superclassOf(macro.ClassDeclaration clazz) {
    // TODO: implement superclassOf
    throw new UnimplementedError('_ClassIntrospector.superclassOf');
  }
}

class _TypeDeclarationResolver implements macro.TypeDeclarationResolver {
  @override
  Future<macro.TypeDeclaration> declarationOf(macro.Identifier identifier) {
    // TODO: implement declarationOf
    throw new UnimplementedError('_TypeDeclarationResolver.declarationOf');
  }
}
