// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' hide TypeBuilder;
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';
import 'package:kernel/ast.dart' show DartType, DynamicType;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_environment.dart';

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

  late MacroInstanceIdentifier instanceIdentifier;
}

class MacroApplicationDataForTesting {
  Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData = {};
  Map<MemberBuilder, List<MacroExecutionResult>> memberDefinitionsResults = {};
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
  final MacroExecutor _macroExecutor;
  final Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData;
  final MacroApplicationDataForTesting? dataForTesting;

  MacroApplications(
      this._macroExecutor, this.libraryData, this.dataForTesting) {
    dataForTesting?.libraryData.addAll(libraryData);
  }

  static Future<MacroApplications> loadMacroIds(
      MacroExecutor macroExecutor,
      Map<MacroClass, Uri> precompiledMacroUris,
      Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData,
      MacroApplicationDataForTesting? dataForTesting) async {
    Map<ClassBuilder, MacroClassIdentifier> classIdCache = {};

    Map<MacroApplication, MacroInstanceIdentifier> instanceIdCache = {};

    Future<void> ensureMacroClassIds(
        List<MacroApplication>? applications) async {
      if (applications != null) {
        for (MacroApplication application in applications) {
          MacroClass macroClass = new MacroClass(
              application.classBuilder.library.importUri,
              application.classBuilder.name);
          Uri? precompiledMacroUri = precompiledMacroUris[macroClass];
          MacroClassIdentifier macroClassIdentifier =
              classIdCache[application.classBuilder] ??= await macroExecutor
                  .loadMacro(macroClass.importUri, macroClass.className,
                      precompiledKernelUri: precompiledMacroUri);
          application.instanceIdentifier = instanceIdCache[application] =
              await macroExecutor.instantiateMacro(
                  macroClassIdentifier,
                  application.constructorName,
                  // TODO(johnniwinther): Support macro arguments.
                  new Arguments([], {}));
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

  Map<MemberBuilder, Declaration?> _memberDeclarations = {};

  // TODO(johnniwinther): Support all members.
  Declaration? _getMemberDeclaration(MemberBuilder memberBuilder) {
    return _memberDeclarations[memberBuilder] ??=
        _createMemberDeclaration(memberBuilder);
  }

  Declaration? _createMemberDeclaration(MemberBuilder memberBuilder) {
    if (memberBuilder is SourceProcedureBuilder) {
      return createTopLevelFunctionDeclaration(memberBuilder);
    } else {
      // TODO(johnniwinther): Throw when all members are supported.
      //throw new UnimplementedError('Unsupported member ${memberBuilder}');
      return null;
    }
  }

  Future<void> _applyTypeMacros(
      Declaration declaration, List<MacroApplication> macroApplications) async {
    for (MacroApplication macroApplication in macroApplications) {
      await _macroExecutor.executeTypesPhase(
          macroApplication.instanceIdentifier, declaration);
    }
  }

  Future<void> applyTypeMacros() async {
    for (MapEntry<SourceLibraryBuilder,
        LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
      LibraryMacroApplicationData libraryMacroApplicationData =
          libraryEntry.value;
      for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          await _applyTypeMacros(declaration, memberEntry.value);
        }
      }
    }
  }

  Future<void> _applyDeclarationMacros(
      Declaration declaration,
      List<MacroApplication> macroApplications,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector) async {
    for (MacroApplication macroApplication in macroApplications) {
      await _macroExecutor.executeDeclarationsPhase(
          macroApplication.instanceIdentifier,
          declaration,
          typeResolver,
          classIntrospector);
    }
  }

  Future<void> applyDeclarationMacros() async {
    TypeResolver typeResolver = new _TypeResolver(this);
    ClassIntrospector classIntrospector = new _ClassIntrospector();
    for (MapEntry<SourceLibraryBuilder,
        LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
      LibraryMacroApplicationData libraryMacroApplicationData =
          libraryEntry.value;
      for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          await _applyDeclarationMacros(
              declaration, memberEntry.value, typeResolver, classIntrospector);
        }
      }
    }
  }

  Future<List<MacroExecutionResult>> _applyDefinitionMacros(
      Declaration declaration,
      List<MacroApplication> macroApplications,
      TypeResolver typeResolver,
      ClassIntrospector classIntrospector,
      TypeDeclarationResolver typeDeclarationResolver) async {
    List<MacroExecutionResult> results = [];
    for (MacroApplication macroApplication in macroApplications) {
      MacroExecutionResult result =
          await _macroExecutor.executeDefinitionsPhase(
              macroApplication.instanceIdentifier,
              declaration,
              typeResolver,
              classIntrospector,
              typeDeclarationResolver);
      results.add(result);
    }
    return results;
  }

  late TypeEnvironment typeEnvironment;

  Future<void> applyDefinitionMacros(
      CoreTypes coreTypes, ClassHierarchy classHierarchy) async {
    typeEnvironment = new TypeEnvironment(coreTypes, classHierarchy);
    TypeResolver typeResolver = new _TypeResolver(this);
    ClassIntrospector classIntrospector = new _ClassIntrospector();
    TypeDeclarationResolver typeDeclarationResolver =
        new _TypeDeclarationResolver();
    for (MapEntry<SourceLibraryBuilder,
        LibraryMacroApplicationData> libraryEntry in libraryData.entries) {
      LibraryMacroApplicationData libraryMacroApplicationData =
          libraryEntry.value;
      for (MapEntry<MemberBuilder, List<MacroApplication>> memberEntry
          in libraryMacroApplicationData.memberApplications.entries) {
        MemberBuilder memberBuilder = memberEntry.key;
        Declaration? declaration = _getMemberDeclaration(memberBuilder);
        if (declaration != null) {
          List<MacroExecutionResult> results = await _applyDefinitionMacros(
              declaration,
              memberEntry.value,
              typeResolver,
              classIntrospector,
              typeDeclarationResolver);
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

  FunctionDeclaration createTopLevelFunctionDeclaration(
      SourceProcedureBuilder builder) {
    List<ParameterDeclarationImpl>? positionalParameters;
    List<ParameterDeclarationImpl>? namedParameters;

    List<FormalParameterBuilder>? formals = builder.formals;
    if (formals == null) {
      positionalParameters = namedParameters = const [];
    } else {
      positionalParameters = [];
      namedParameters = [];
      for (FormalParameterBuilder formal in formals) {
        TypeAnnotationImpl type =
            computeTypeAnnotation(builder.library, formal.type);
        // TODO(johnniwinther): Support default values.
        if (formal.isNamed) {
          namedParameters.add(new ParameterDeclarationImpl(
              id: RemoteInstance.uniqueId,
              name: formal.name,
              isRequired: formal.isNamedRequired,
              isNamed: true,
              type: type,
              defaultValue: null));
        } else {
          positionalParameters.add(new ParameterDeclarationImpl(
              id: RemoteInstance.uniqueId,
              name: formal.name,
              isRequired: formal.isRequired,
              isNamed: false,
              type: type,
              defaultValue: null));
        }
      }
    }

    return new FunctionDeclarationImpl(
        id: RemoteInstance.uniqueId,
        name: builder.name,
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

  List<TypeAnnotationImpl> computeTypeAnnotations(
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
        List<TypeAnnotationImpl> typeArguments =
            computeTypeAnnotations(libraryBuilder, typeBuilder.arguments);
        bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
        if (name is String) {
          return new _NamedTypeAnnotationImpl(
              typeBuilder: typeBuilder,
              libraryBuilder: libraryBuilder,
              id: RemoteInstance.uniqueId,
              name: name,
              typeArguments: typeArguments,
              isNullable: isNullable);
        } else if (name is QualifiedName) {
          assert(name.qualifier is String);
          return new _NamedTypeAnnotationImpl(
              typeBuilder: typeBuilder,
              libraryBuilder: libraryBuilder,
              id: RemoteInstance.uniqueId,
              name: '${name.qualifier}.${name.name}',
              typeArguments: typeArguments,
              isNullable: isNullable);
        }
      }
    }
    return new _NamedTypeAnnotationImpl(
        typeBuilder: typeBuilder,
        libraryBuilder: libraryBuilder,
        id: RemoteInstance.uniqueId,
        name: 'dynamic',
        isNullable: false,
        typeArguments: const []);
  }

  TypeAnnotationImpl computeTypeAnnotation(
      LibraryBuilder libraryBuilder, TypeBuilder? typeBuilder) {
    return _typeAnnotationCache[typeBuilder] ??=
        _computeTypeAnnotation(libraryBuilder, typeBuilder);
  }

  StaticType resolveTypeAnnotation(_NamedTypeAnnotationImpl typeAnnotation) {
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

  StaticType createStaticType(DartType dartType) {
    return _staticTypeCache[dartType] ??= new _StaticTypeImpl(this, dartType);
  }
}

class _NamedTypeAnnotationImpl extends NamedTypeAnnotationImpl {
  final TypeBuilder? typeBuilder;
  final LibraryBuilder libraryBuilder;

  _NamedTypeAnnotationImpl({
    required this.typeBuilder,
    required this.libraryBuilder,
    required int id,
    required bool isNullable,
    required String name,
    required List<TypeAnnotationImpl> typeArguments,
  }) : super(
            id: id,
            isNullable: isNullable,
            name: name,
            typeArguments: typeArguments);
}

class _StaticTypeImpl extends StaticType {
  final MacroApplications macroApplications;
  final DartType type;

  _StaticTypeImpl(this.macroApplications, this.type);

  @override
  Future<bool> isExactly(covariant _StaticTypeImpl other) {
    return new Future.value(type == other.type);
  }

  @override
  Future<bool> isSubtypeOf(covariant _StaticTypeImpl other) {
    return new Future.value(macroApplications.typeEnvironment
        .isSubtypeOf(type, other.type, SubtypeCheckMode.withNullabilities));
  }
}

class _TypeResolver implements TypeResolver {
  final MacroApplications macroApplications;

  _TypeResolver(this.macroApplications);

  @override
  Future<StaticType> resolve(
      covariant _NamedTypeAnnotationImpl typeAnnotation) {
    return new Future.value(
        macroApplications.resolveTypeAnnotation(typeAnnotation));
  }
}

class _ClassIntrospector implements ClassIntrospector {
  @override
  Future<List<ConstructorDeclaration>> constructorsOf(ClassDeclaration clazz) {
    // TODO: implement constructorsOf
    throw new UnimplementedError('_ClassIntrospector.constructorsOf');
  }

  @override
  Future<List<FieldDeclaration>> fieldsOf(ClassDeclaration clazz) {
    // TODO: implement fieldsOf
    throw new UnimplementedError('_ClassIntrospector.fieldsOf');
  }

  @override
  Future<List<ClassDeclaration>> interfacesOf(ClassDeclaration clazz) {
    // TODO: implement interfacesOf
    throw new UnimplementedError('_ClassIntrospector.interfacesOf');
  }

  @override
  Future<List<MethodDeclaration>> methodsOf(ClassDeclaration clazz) {
    // TODO: implement methodsOf
    throw new UnimplementedError('_ClassIntrospector.methodsOf');
  }

  @override
  Future<List<ClassDeclaration>> mixinsOf(ClassDeclaration clazz) {
    // TODO: implement mixinsOf
    throw new UnimplementedError('_ClassIntrospector.mixinsOf');
  }

  @override
  Future<ClassDeclaration?> superclassOf(ClassDeclaration clazz) {
    // TODO: implement superclassOf
    throw new UnimplementedError('_ClassIntrospector.superclassOf');
  }
}

class _TypeDeclarationResolver implements TypeDeclarationResolver {
  @override
  Future<TypeDeclaration> declarationOf(NamedStaticType annotation) {
    // TODO: implement declarationOf
    throw new UnimplementedError('_TypeDeclarationResolver.declarationOf');
  }
}
