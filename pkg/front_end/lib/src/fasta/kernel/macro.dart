// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' hide TypeBuilder;
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';

import '../builder/class_builder.dart';
import '../builder/formal_parameter_builder.dart';
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

class MacroApplications {
  final MacroExecutor macroExecutor;
  final Map<SourceLibraryBuilder, LibraryMacroApplicationData> libraryData;
  final MacroApplicationDataForTesting? dataForTesting;

  MacroApplications(this.macroExecutor, this.libraryData, this.dataForTesting) {
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
      await macroExecutor.executeTypesPhase(
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
      await macroExecutor.executeDeclarationsPhase(
          macroApplication.instanceIdentifier,
          declaration,
          typeResolver,
          classIntrospector);
    }
  }

  Future<void> applyDeclarationMacros() async {
    TypeResolver typeResolver = new _TypeResolver();
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
      MacroExecutionResult result = await macroExecutor.executeDefinitionsPhase(
          macroApplication.instanceIdentifier,
          declaration,
          typeResolver,
          classIntrospector,
          typeDeclarationResolver);
      results.add(result);
    }
    return results;
  }

  Future<void> applyDefinitionMacros() async {
    TypeResolver typeResolver = new _TypeResolver();
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
      TypeAnnotationImpl type = computeTypeAnnotation(formal.type);
      // TODO(johnniwinther): Support default values.
      if (formal.isNamed) {
        namedParameters.add(new ParameterDeclarationImpl(
            id: _removeInstanceId++,
            name: formal.name,
            isRequired: formal.isNamedRequired,
            isNamed: true,
            type: type,
            defaultValue: null));
      } else {
        positionalParameters.add(new ParameterDeclarationImpl(
            id: _removeInstanceId++,
            name: formal.name,
            isRequired: formal.isRequired,
            isNamed: false,
            type: type,
            defaultValue: null));
      }
    }
  }

  return new FunctionDeclarationImpl(
      id: _removeInstanceId++,
      name: builder.name,
      isAbstract: builder.isAbstract,
      isExternal: builder.isExternal,
      isGetter: builder.isGetter,
      isSetter: builder.isSetter,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      returnType: computeTypeAnnotation(builder.returnType),
      // TODO(johnniwinther): Support typeParameters
      typeParameters: const []);
}

// TODO(johnniwinther): Cache remote instances when needed.
int _removeInstanceId = 0;

List<TypeAnnotationImpl> computeTypeAnnotations(
    List<TypeBuilder>? typeBuilders) {
  if (typeBuilders == null) return const [];
  return new List.generate(typeBuilders.length,
      (int index) => computeTypeAnnotation(typeBuilders[index]));
}

TypeAnnotationImpl computeTypeAnnotation(TypeBuilder? typeBuilder) {
  if (typeBuilder != null) {
    if (typeBuilder is NamedTypeBuilder) {
      Object name = typeBuilder.name;
      List<TypeAnnotationImpl> typeArguments =
          computeTypeAnnotations(typeBuilder.arguments);
      bool isNullable = typeBuilder.nullabilityBuilder.isNullable;
      if (name is String) {
        return new NamedTypeAnnotationImpl(
            id: _removeInstanceId++,
            name: name,
            typeArguments: typeArguments,
            isNullable: isNullable);
      } else if (name is QualifiedName) {
        assert(name.qualifier is String);
        return new NamedTypeAnnotationImpl(
            id: _removeInstanceId++,
            name: '${name.qualifier}.${name.name}',
            typeArguments: typeArguments,
            isNullable: isNullable);
      }
    }
  }
  return new NamedTypeAnnotationImpl(
      id: _removeInstanceId++,
      name: 'dynamic',
      isNullable: false,
      typeArguments: const []);
}

class _TypeResolver implements TypeResolver {
  @override
  Future<StaticType> resolve(TypeAnnotation typeAnnotation) {
    // TODO: implement resolve
    throw new UnimplementedError('_TypeResolver.resolve');
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
