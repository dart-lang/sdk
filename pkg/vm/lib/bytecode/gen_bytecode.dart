// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.gen_bytecode;

import 'package:front_end/src/api_unstable/vm.dart'
    show
        CompilerContext,
        Severity,
        isRedirectingFactoryField,
        messageBytecodeLimitExceededTooManyArguments,
        noLength,
        templateIllegalRecursiveType;

import 'package:kernel/ast.dart' hide MapEntry, Component, FunctionDeclaration;
import 'package:kernel/ast.dart' as ast show Component, FunctionDeclaration;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/external_name.dart'
    show getExternalName, getNativeExtensionUris;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/text/ast_to_text.dart'
    show globalDebuggingNames, NameSystem;
import 'package:kernel/type_algebra.dart'
    show Substitution, containsTypeVariable;
import 'package:kernel/type_environment.dart'
    show StatefulStaticTypeContext, SubtypeCheckMode, TypeEnvironment;
import 'assembler.dart';
import 'bytecode_serialization.dart' show StringTable;
import 'constant_pool.dart';
import 'dbc.dart';
import 'declarations.dart';
import 'exceptions.dart';
import 'generics.dart'
    show
        flattenInstantiatorTypeArguments,
        getDefaultFunctionTypeArguments,
        getInstantiatorTypeArguments,
        getStaticType,
        getTypeParameterTypes,
        hasFreeTypeParameters,
        hasInstantiatorTypeArguments,
        isAllDynamic,
        isInstantiatedInterfaceCall,
        isUncheckedCall,
        isUncheckedClosureCall;
import 'local_variable_table.dart' show LocalVariableTable;
import 'local_vars.dart' show LocalVariables;
import 'nullability_detector.dart' show NullabilityDetector;
import 'object_table.dart'
    show ObjectHandle, ObjectTable, NameAndType, topLevelClassName;
import 'options.dart' show BytecodeOptions;
import 'recognized_methods.dart' show RecognizedMethods;
import 'recursive_types_validator.dart' show IllegalRecursiveTypeException;
import 'source_positions.dart' show LineStarts, SourcePositions;
import '../metadata/bytecode.dart';
import '../metadata/direct_call.dart'
    show DirectCallMetadata, DirectCallMetadataRepository;
import '../metadata/inferred_type.dart'
    show InferredType, InferredTypeMetadataRepository;
import '../metadata/obfuscation_prohibitions.dart'
    show ObfuscationProhibitionsMetadataRepository;
import '../metadata/procedure_attributes.dart'
    show ProcedureAttributesMetadata, ProcedureAttributesMetadataRepository;

import 'dart:convert' show utf8;
import 'dart:developer';
import 'dart:math' as math;

// This symbol is used as the name in assert assignable's to indicate it comes
// from an explicit 'as' check.  This will cause the runtime to throw the right
// exception.
const String symbolForTypeCast = ' in type cast';

void generateBytecode(
  ast.Component component, {
  BytecodeOptions options,
  List<Library> libraries,
  CoreTypes coreTypes,
  ClassHierarchy hierarchy,
}) {
  Timeline.timeSync("generateBytecode", () {
    options ??= new BytecodeOptions();
    verifyBytecodeInstructionDeclarations();
    coreTypes ??= new CoreTypes(component);
    void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
    hierarchy ??= new ClassHierarchy(component, coreTypes,
        onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
    final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);
    libraries ??= component.libraries;

    // Save/restore global NameSystem to avoid accumulating garbage.
    // NameSystem holds the whole AST as it is strongly connected due to
    // parent pointers. Objects are added to NameSystem when toString()
    // is called from AST nodes.  Bytecode generator widely uses
    // Expression.getStaticType, which calls Expression.getStaticTypeAsInstanceOf,
    // which uses toString() when it crashes due to http://dartbug.com/34496.
    final savedGlobalDebuggingNames = globalDebuggingNames;
    globalDebuggingNames = new NameSystem();

    Library library;
    try {
      final bytecodeGenerator = new BytecodeGenerator(
          component, coreTypes, hierarchy, typeEnvironment, options);
      for (library in libraries) {
        bytecodeGenerator.visitLibrary(library);
      }
    } on IllegalRecursiveTypeException catch (e) {
      CompilerContext.current.options.report(
          templateIllegalRecursiveType
              .withArguments(e.type, library.isNonNullableByDefault)
              .withoutLocation(),
          Severity.error);
    } finally {
      globalDebuggingNames = savedGlobalDebuggingNames;
    }
  });
}

class BytecodeGenerator extends RecursiveVisitor<Null> {
  static final Name callName = new Name('call');
  static final Name noSuchMethodName = new Name('noSuchMethod');

  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final TypeEnvironment typeEnvironment;
  final StatefulStaticTypeContext staticTypeContext;
  final BytecodeOptions options;
  final BytecodeMetadataRepository metadata = new BytecodeMetadataRepository();
  final RecognizedMethods recognizedMethods;
  final int formatVersion;
  final Map<Uri, Source> astUriToSource;
  StringTable stringTable;
  ObjectTable objectTable;
  Component bytecodeComponent;
  NullabilityDetector nullabilityDetector;
  Map<TreeNode, DirectCallMetadata> directCallMetadata;
  ProcedureAttributesMetadataRepository procedureAttributesMetadataRepository;
  ProcedureAttributesMetadata procedureAttributesMetadata;
  Map<TreeNode, InferredType> inferredTypeMetadata;
  List<Constant> inferredTypesAttribute;

  List<ClassDeclaration> classDeclarations;
  List<FieldDeclaration> fieldDeclarations;
  List<FunctionDeclaration> functionDeclarations;
  Class enclosingClass;
  Member enclosingMember;
  FunctionNode enclosingFunction;
  FunctionNode parentFunction;
  bool isClosure;
  Set<TypeParameter> classTypeParameters;
  List<TypeParameter> functionTypeParameters;
  Set<TypeParameter> functionTypeParametersSet;
  List<DartType> instantiatorTypeArguments;
  LocalVariables locals;
  Map<LabeledStatement, Label> labeledStatements;
  Map<SwitchCase, Label> switchCases;
  Map<TryCatch, TryBlock> tryCatches;
  Map<TryFinally, List<FinallyBlock>> finallyBlocks;
  List<Label> yieldPoints;
  Map<TreeNode, int> contextLevels;
  List<ClosureDeclaration> closures;
  Set<Field> initializedFields;
  List<ObjectHandle> nullableFields;
  ConstantPool cp;
  BytecodeAssembler asm;
  List<BytecodeAssembler> savedAssemblers;
  bool hasErrors;
  int currentLoopDepth;
  List<int> savedMaxSourcePositions;
  int maxSourcePosition;

  BytecodeGenerator(
      ast.Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      BytecodeOptions options)
      : this._internal(component, coreTypes, hierarchy, typeEnvironment,
            options, new StatefulStaticTypeContext.flat(typeEnvironment));

  BytecodeGenerator._internal(
      ast.Component component,
      this.coreTypes,
      this.hierarchy,
      this.typeEnvironment,
      this.options,
      this.staticTypeContext)
      : recognizedMethods = new RecognizedMethods(staticTypeContext),
        formatVersion = currentBytecodeFormatVersion,
        astUriToSource = component.uriToSource {
    nullabilityDetector = new NullabilityDetector(recognizedMethods);
    component.addMetadataRepository(metadata);

    bytecodeComponent = new Component(formatVersion, coreTypes);
    metadata.mapping[component] = new BytecodeMetadata(bytecodeComponent);

    stringTable = bytecodeComponent.stringTable;
    objectTable = bytecodeComponent.objectTable;

    if (component.mainMethod != null) {
      bytecodeComponent.mainLibrary =
          objectTable.getHandle(component.mainMethod.enclosingLibrary);
    }

    directCallMetadata =
        component.metadata[DirectCallMetadataRepository.repositoryTag]?.mapping;

    procedureAttributesMetadataRepository =
        component.metadata[ProcedureAttributesMetadataRepository.repositoryTag];

    inferredTypeMetadata = component
        .metadata[InferredTypeMetadataRepository.repositoryTag]?.mapping;

    final obfuscationProhibitionsMetadataRepository = component
        .metadata[ObfuscationProhibitionsMetadataRepository.repositoryTag];
    if (obfuscationProhibitionsMetadataRepository != null) {
      bytecodeComponent.protectedNames =
          obfuscationProhibitionsMetadataRepository
              .mapping[component]?.protectedNames;
    }
  }

  @override
  visitLibrary(Library node) {
    staticTypeContext.enterLibrary(node);

    startMembers();
    visitList(node.procedures, this);
    visitList(node.fields, this);
    final members = endMembers(node);

    classDeclarations = <ClassDeclaration>[
      getTopLevelClassDeclaration(node, members)
    ];

    visitList(node.classes, this);

    bytecodeComponent.libraries
        .add(getLibraryDeclaration(node, classDeclarations));
    classDeclarations = null;
    staticTypeContext.leaveLibrary(node);
  }

  @override
  visitClass(Class node) {
    startMembers();
    visitList(node.constructors, this);
    visitList(node.procedures, this);
    visitList(node.fields, this);
    final members = endMembers(node);

    classDeclarations.add(getClassDeclaration(node, members));
  }

  void startMembers() {
    fieldDeclarations = <FieldDeclaration>[];
    functionDeclarations = <FunctionDeclaration>[];
  }

  Members endMembers(TreeNode node) {
    final members = new Members(fieldDeclarations, functionDeclarations);
    bytecodeComponent.members.add(members);
    fieldDeclarations = null;
    functionDeclarations = null;
    return members;
  }

  ObjectHandle getScript(Uri uri, bool includeSourceInfo) {
    SourceFile source;
    if (options.emitSourceFiles || options.emitSourcePositions) {
      final astSource = astUriToSource[uri];
      if (astSource != null) {
        source = bytecodeComponent.uriToSource[uri];
        if (source == null) {
          final importUri =
              objectTable.getConstStringHandle(astSource.importUri.toString());
          source = new SourceFile(importUri);
          bytecodeComponent.sourceFiles.add(source);
          bytecodeComponent.uriToSource[uri] = source;
        }
        if (options.emitSourcePositions &&
            includeSourceInfo &&
            source.lineStarts == null) {
          LineStarts lineStarts = new LineStarts(astSource.lineStarts);
          bytecodeComponent.lineStarts.add(lineStarts);
          source.lineStarts = lineStarts;
        }
        if (options.emitSourceFiles &&
            includeSourceInfo &&
            source.source == null) {
          String text = astSource.cachedText ??
              utf8.decode(astSource.source, allowMalformed: true);
          source.source = text;
        }
      }
    }
    return objectTable.getScriptHandle(uri, source);
  }

  LibraryDeclaration getLibraryDeclaration(
      Library library, List<ClassDeclaration> classes) {
    final importUri =
        objectTable.getConstStringHandle(library.importUri.toString());
    int flags = 0;
    for (var dependency in library.dependencies) {
      final targetLibrary = dependency.targetLibrary;
      assert(targetLibrary != null);
      if (targetLibrary == coreTypes.mirrorsLibrary) {
        flags |= LibraryDeclaration.usesDartMirrorsFlag;
      } else if (targetLibrary == dartFfiLibrary) {
        flags |= LibraryDeclaration.usesDartFfiFlag;
      }
    }
    final name = objectTable.getPublicNameHandle(library.name ?? '');
    final script = getScript(library.fileUri, true);
    final extensionUris =
        objectTable.getConstStringHandles(getNativeExtensionUris(library));
    if (extensionUris.isNotEmpty) {
      flags |= LibraryDeclaration.hasExtensionsFlag;
    }
    if (library.isNonNullableByDefault) {
      flags |= LibraryDeclaration.isNonNullableByDefaultFlag;
    }
    return new LibraryDeclaration(
        importUri, flags, name, script, extensionUris, classes);
  }

  ClassDeclaration getClassDeclaration(Class cls, Members members) {
    int flags = 0;
    if (cls.isAbstract) {
      flags |= ClassDeclaration.isAbstractFlag;
    }
    if (cls.isEnum) {
      flags |= ClassDeclaration.isEnumFlag;
    }
    int numTypeArguments = 0;
    TypeParametersDeclaration typeParameters;
    if (hasInstantiatorTypeArguments(cls)) {
      flags |= ClassDeclaration.hasTypeArgumentsFlag;
      numTypeArguments = flattenInstantiatorTypeArguments(
              cls, getTypeParameterTypes(cls.typeParameters))
          .length;
      assert(numTypeArguments > 0);
      if (cls.typeParameters.isNotEmpty) {
        flags |= ClassDeclaration.hasTypeParamsFlag;
        typeParameters = getTypeParametersDeclaration(cls.typeParameters);
      }
    }
    if (cls.isEliminatedMixin) {
      flags |= ClassDeclaration.isTransformedMixinApplicationFlag;
    }
    int position = TreeNode.noOffset;
    int endPosition = TreeNode.noOffset;
    if (options.emitSourcePositions && cls.fileOffset != TreeNode.noOffset) {
      flags |= ClassDeclaration.hasSourcePositionsFlag;
      position = cls.startFileOffset;
      endPosition = cls.fileEndOffset;
    }
    Annotations annotations = getAnnotations(cls.annotations);
    if (annotations.object != null) {
      flags |= ClassDeclaration.hasAnnotationsFlag;
      if (annotations.hasPragma) {
        flags |= ClassDeclaration.hasPragmaFlag;
      }
    }

    final nameHandle = objectTable.getNameHandle(
        cls.name.startsWith('_') ? cls.enclosingLibrary : null, cls.name);
    final script = getScript(cls.fileUri, !cls.isAnonymousMixin);
    final superType = objectTable.getHandle(cls.supertype?.asInterfaceType);
    final interfaces = objectTable.getHandles(
        cls.implementedTypes.map((t) => t.asInterfaceType).toList());

    final classDeclaration = new ClassDeclaration(
        nameHandle,
        flags,
        script,
        position,
        endPosition,
        typeParameters,
        numTypeArguments,
        superType,
        interfaces,
        members,
        annotations.object);
    bytecodeComponent.classes.add(classDeclaration);
    return classDeclaration;
  }

  ClassDeclaration getTopLevelClassDeclaration(
      Library library, Members members) {
    int flags = 0;
    int position = TreeNode.noOffset;
    if (options.emitSourcePositions &&
        library.fileOffset != TreeNode.noOffset) {
      flags |= ClassDeclaration.hasSourcePositionsFlag;
      position = library.fileOffset;
    }
    Annotations annotations = getLibraryAnnotations(library);
    if (annotations.object != null) {
      flags |= ClassDeclaration.hasAnnotationsFlag;
      if (annotations.hasPragma) {
        flags |= ClassDeclaration.hasPragmaFlag;
      }
    }

    final nameHandle = objectTable.getPublicNameHandle(topLevelClassName);
    final script = getScript(library.fileUri, true);

    final classDeclaration = new ClassDeclaration(
        nameHandle,
        flags,
        script,
        position,
        /* endPosition */ TreeNode.noOffset,
        /* typeParameters */ null,
        /* numTypeArguments */ 0,
        /* superType */ null,
        /* interfaces */ const <ObjectHandle>[],
        members,
        annotations.object);
    bytecodeComponent.classes.add(classDeclaration);
    return classDeclaration;
  }

  bool _isPragma(Constant annotation) =>
      annotation is InstanceConstant &&
      annotation.classNode == coreTypes.pragmaClass;

  Annotations getAnnotations(List<Expression> nodes) {
    if (nodes.isEmpty) {
      return const Annotations(null, false);
    }
    List<Constant> constants = nodes.map(_getConstant).toList();
    bool hasPragma = constants.any(_isPragma);
    if (!options.emitAnnotations) {
      if (hasPragma) {
        constants = constants.where(_isPragma).toList();
      } else {
        return const Annotations(null, false);
      }
    }
    final object =
        objectTable.getHandle(new ListConstant(const DynamicType(), constants));
    final decl = new AnnotationsDeclaration(object);
    bytecodeComponent.annotations.add(decl);
    return new Annotations(decl, hasPragma);
  }

  ObjectHandle getMemberAttributes() {
    if (procedureAttributesMetadata == null && inferredTypesAttribute == null) {
      return null;
    }
    // List of pairs (tag, value).
    final attrs = <Constant>[];
    if (procedureAttributesMetadata != null) {
      final attribute = procedureAttributesMetadataRepository
          .getBytecodeAttribute(procedureAttributesMetadata);
      attrs.add(
          StringConstant(ProcedureAttributesMetadataRepository.repositoryTag));
      attrs.add(attribute);
    }
    if (inferredTypesAttribute != null) {
      attrs.add(StringConstant(InferredTypeMetadataRepository.repositoryTag));
      attrs.add(ListConstant(const DynamicType(), inferredTypesAttribute));
    }
    return objectTable.getHandle(ListConstant(const DynamicType(), attrs));
  }

  ObjectHandle getClosureAttributes() {
    if (inferredTypesAttribute == null) {
      return null;
    }
    final attrs = <Constant>[
      StringConstant(InferredTypeMetadataRepository.repositoryTag),
      ListConstant(const DynamicType(), inferredTypesAttribute),
    ];
    return objectTable.getHandle(ListConstant(const DynamicType(), attrs));
  }

  // Insert annotations for the function and its parameters into the annotations
  // section. Return the annotations for the function only. The bytecode reader
  // will implicitly find the parameter annotations by reading N packed objects
  // after reading the function's annotations, one for each parameter.
  Annotations getFunctionAnnotations(Member member) {
    final functionNodes = member.annotations;
    final parameterNodeLists = new List<List<Expression>>();
    for (VariableDeclaration variable in member.function.positionalParameters) {
      parameterNodeLists.add(variable.annotations);
    }
    for (VariableDeclaration variable in member.function.namedParameters) {
      parameterNodeLists.add(variable.annotations);
    }

    if (functionNodes.isEmpty &&
        parameterNodeLists.every((nodes) => nodes.isEmpty)) {
      return const Annotations(null, false);
    }

    List<Constant> functionConstants = functionNodes.map(_getConstant).toList();
    bool hasPragma = functionConstants.any(_isPragma);
    if (!options.emitAnnotations && !hasPragma) {
      return const Annotations(null, false);
    }

    final functionObject = objectTable
        .getHandle(new ListConstant(const DynamicType(), functionConstants));
    final functionDecl = new AnnotationsDeclaration(functionObject);
    bytecodeComponent.annotations.add(functionDecl);

    for (final parameterNodes in parameterNodeLists) {
      List<Constant> parameterConstants =
          parameterNodes.map(_getConstant).toList();
      final parameterObject = objectTable
          .getHandle(new ListConstant(const DynamicType(), parameterConstants));
      final parameterDecl = new AnnotationsDeclaration(parameterObject);
      bytecodeComponent.annotations.add(parameterDecl);
    }

    return new Annotations(functionDecl, hasPragma);
  }

  // Insert annotations for library and its dependencies into the
  // annotations section. Returns annotations for the library only.
  // Bytecode reader will implicitly find library dependencies by reading
  // an extra object after reading library annotations.
  Annotations getLibraryAnnotations(Library library) {
    Annotations annotations = getAnnotations(library.annotations);
    final bool emitDependencies =
        options.emitAnnotations && library.dependencies.isNotEmpty;
    if (annotations.object == null && !emitDependencies) {
      return annotations;
    }

    // We need to emit both annotations and dependencies objects, appending
    // null if an object is missing.
    if (annotations.object == null) {
      final annotationsDecl = new AnnotationsDeclaration(null);
      bytecodeComponent.annotations.add(annotationsDecl);
      annotations = new Annotations(annotationsDecl, false);
    }
    if (!emitDependencies) {
      bytecodeComponent.annotations.add(new AnnotationsDeclaration(null));
      return annotations;
    }

    // Create a constant object representing library dependencies.
    // These objects are used by dart:mirrors and vm-service implementation.
    final deps = <Constant>[];
    for (var dependency in library.dependencies) {
      final prefix = dependency.name != null
          ? StringConstant(dependency.name)
          : NullConstant();
      final showNames = dependency.combinators
          .where((c) => c.isShow)
          .expand((c) => c.names)
          .map((name) => StringConstant(name))
          .toList();
      final hideNames = dependency.combinators
          .where((c) => c.isHide)
          .expand((c) => c.names)
          .map((name) => StringConstant(name))
          .toList();
      final depAnnots = dependency.annotations.map(_getConstant).toList();
      deps.add(ListConstant(const DynamicType(), <Constant>[
        StringConstant(dependency.targetLibrary.importUri.toString()),
        BoolConstant(dependency.isExport),
        BoolConstant(dependency.isDeferred),
        prefix,
        ListConstant(const DynamicType(), showNames),
        ListConstant(const DynamicType(), hideNames),
        ListConstant(const DynamicType(), depAnnots),
      ]));
    }
    final ObjectHandle dependenciesObject =
        objectTable.getHandle(ListConstant(const DynamicType(), deps));
    final dependenciesDecl = new AnnotationsDeclaration(dependenciesObject);
    bytecodeComponent.annotations.add(dependenciesDecl);

    return annotations;
  }

  FieldDeclaration getFieldDeclaration(Field field, Code initializer) {
    int flags = 0;
    Constant value;
    if (_hasNonTrivialInitializer(field)) {
      flags |= FieldDeclaration.hasNontrivialInitializerFlag;
    } else if (field.initializer != null) {
      value = _getConstant(field.initializer);
    }
    if (initializer != null) {
      flags |= FieldDeclaration.hasInitializerCodeFlag;
    }
    if (field.initializer != null) {
      flags |= FieldDeclaration.hasInitializerFlag;
    }
    final name = objectTable.getNameHandle(
        field.name.library, objectTable.mangleMemberName(field, false, false));
    ObjectHandle getterName;
    ObjectHandle setterName;
    if (_needsGetter(field)) {
      flags |= FieldDeclaration.hasGetterFlag;
      getterName = objectTable.getNameHandle(
          field.name.library, objectTable.mangleMemberName(field, true, false));
    }
    if (_needsSetter(field)) {
      flags |= FieldDeclaration.hasSetterFlag;
      setterName = objectTable.getNameHandle(
          field.name.library, objectTable.mangleMemberName(field, false, true));
    }
    if (isReflectable(field)) {
      flags |= FieldDeclaration.isReflectableFlag;
    }
    if (field.isStatic) {
      flags |= FieldDeclaration.isStaticFlag;
    }
    if (field.isConst) {
      flags |= FieldDeclaration.isConstFlag;
    }
    // Const fields are implicitly final.
    if (field.isConst || field.isFinal) {
      flags |= FieldDeclaration.isFinalFlag;
    }
    if (field.isCovariant) {
      flags |= FieldDeclaration.isCovariantFlag;
    }
    if (field.isGenericCovariantImpl) {
      flags |= FieldDeclaration.isGenericCovariantImplFlag;
    }
    if (field.isExtensionMember) {
      flags |= FieldDeclaration.isExtensionMemberFlag;
    }
    // In NNBD libraries, static fields with initializers are implicitly late.
    if (field.isLate ||
        (field.isStatic &&
            field.initializer != null &&
            field.isNonNullableByDefault)) {
      flags |= FieldDeclaration.isLateFlag;
    }
    int position = TreeNode.noOffset;
    int endPosition = TreeNode.noOffset;
    if (options.emitSourcePositions && field.fileOffset != TreeNode.noOffset) {
      flags |= FieldDeclaration.hasSourcePositionsFlag;
      position = field.fileOffset;
      endPosition = field.fileEndOffset;
    }
    Annotations annotations = getAnnotations(field.annotations);
    if (annotations.object != null) {
      flags |= FieldDeclaration.hasAnnotationsFlag;
      if (annotations.hasPragma) {
        flags |= FieldDeclaration.hasPragmaFlag;
      }
    }
    final ObjectHandle attributes = getMemberAttributes();
    if (attributes != null) {
      flags |= FieldDeclaration.hasAttributesFlag;
    }
    ObjectHandle script;
    if (field.fileUri != null &&
        field.fileUri != (field.parent as FileUriNode).fileUri) {
      final isInAnonymousMixin =
          enclosingClass != null && enclosingClass.isAnonymousMixin;
      script = getScript(field.fileUri, !isInAnonymousMixin);
      flags |= FieldDeclaration.hasCustomScriptFlag;
    }
    return new FieldDeclaration(
        flags,
        name,
        objectTable.getHandle(field.type),
        objectTable.getHandle(value),
        script,
        position,
        endPosition,
        getterName,
        setterName,
        initializer,
        annotations.object,
        attributes);
  }

  FunctionDeclaration getFunctionDeclaration(Member member, Code code) {
    int flags = 0;
    if (member is Constructor) {
      flags |= FunctionDeclaration.isConstructorFlag;
    }
    if (member is Procedure) {
      if (member.isGetter) {
        flags |= FunctionDeclaration.isGetterFlag;
      } else if (member.isSetter) {
        flags |= FunctionDeclaration.isSetterFlag;
      } else if (member.isFactory) {
        flags |= FunctionDeclaration.isFactoryFlag;
      }
      if (member.isStatic) {
        flags |= FunctionDeclaration.isStaticFlag;
      }
      if (member.isForwardingStub) {
        flags |= FunctionDeclaration.isForwardingStubFlag;
      }
      if (member.isNoSuchMethodForwarder) {
        flags |= FunctionDeclaration.isNoSuchMethodForwarderFlag;
      }
    }
    if (member.isAbstract && !_hasCode(member)) {
      flags |= FunctionDeclaration.isAbstractFlag;
    }
    if (member.isConst) {
      flags |= FunctionDeclaration.isConstFlag;
    }
    if (member.isExtensionMember) {
      flags |= FunctionDeclaration.isExtensionMemberFlag;
    }

    FunctionNode function = member.function;
    if (function.requiredParameterCount !=
        function.positionalParameters.length) {
      flags |= FunctionDeclaration.hasOptionalPositionalParamsFlag;
    }
    if (function.namedParameters.isNotEmpty) {
      flags |= FunctionDeclaration.hasOptionalNamedParamsFlag;
    }
    TypeParametersDeclaration typeParameters;
    if (function.typeParameters.isNotEmpty) {
      flags |= FunctionDeclaration.hasTypeParamsFlag;
      typeParameters = getTypeParametersDeclaration(function.typeParameters);
    }
    if (isReflectable(member)) {
      flags |= FunctionDeclaration.isReflectableFlag;
    }
    if (isDebuggable(member)) {
      flags |= FunctionDeclaration.isDebuggableFlag;
    }
    switch (function.dartAsyncMarker) {
      case AsyncMarker.Async:
        flags |= FunctionDeclaration.isAsyncFlag;
        break;
      case AsyncMarker.AsyncStar:
        flags |= FunctionDeclaration.isAsyncStarFlag;
        break;
      case AsyncMarker.SyncStar:
        flags |= FunctionDeclaration.isSyncStarFlag;
        break;
      default:
        break;
    }
    ObjectHandle nativeName;
    if (member.isExternal) {
      final String externalName = getExternalName(member);
      if (externalName == null) {
        flags |= FunctionDeclaration.isExternalFlag;
      } else {
        flags |= FunctionDeclaration.isNativeFlag;
        nativeName = objectTable.getConstStringHandle(externalName);
      }
    }
    int position = TreeNode.noOffset;
    int endPosition = TreeNode.noOffset;
    if (options.emitSourcePositions && member.fileOffset != TreeNode.noOffset) {
      flags |= FunctionDeclaration.hasSourcePositionsFlag;
      position = (member as dynamic).startFileOffset;
      endPosition = member.fileEndOffset;
    }
    final Annotations annotations = getFunctionAnnotations(member);
    if (annotations.object != null) {
      flags |= FunctionDeclaration.hasAnnotationsFlag;
      if (annotations.hasPragma) {
        flags |= FunctionDeclaration.hasPragmaFlag;
      }
    }
    final ObjectHandle attributes = getMemberAttributes();
    if (attributes != null) {
      flags |= FunctionDeclaration.hasAttributesFlag;
    }
    ObjectHandle script;
    if (member.fileUri != null &&
        member.fileUri != (member.parent as FileUriNode).fileUri) {
      final isInAnonymousMixin =
          enclosingClass != null && enclosingClass.isAnonymousMixin;
      final isSynthetic = member is Procedure &&
          (member.isNoSuchMethodForwarder || member.isSyntheticForwarder);
      script = getScript(member.fileUri, !isInAnonymousMixin && !isSynthetic);
      flags |= FunctionDeclaration.hasCustomScriptFlag;
    }

    final name = objectTable.getNameHandle(member.name.library,
        objectTable.mangleMemberName(member, false, false));

    final parameters = <ParameterDeclaration>[];
    for (var param in function.positionalParameters) {
      parameters.add(getParameterDeclaration(param));
    }
    for (var param in function.namedParameters) {
      parameters.add(getParameterDeclaration(param));
    }

    return new FunctionDeclaration(
        flags,
        name,
        script,
        position,
        endPosition,
        typeParameters,
        function.requiredParameterCount,
        parameters,
        objectTable.getHandle(function.returnType),
        nativeName,
        code,
        annotations.object,
        attributes);
  }

  bool isReflectable(Member member) {
    if (member is Field && member.fileOffset == TreeNode.noOffset) {
      return false;
    }
    final library = member.enclosingLibrary;
    if (library.importUri.scheme == 'dart' && member.name.isPrivate) {
      return false;
    }
    if (member is Procedure &&
        member.isStatic &&
        library.importUri.toString() == 'dart:_internal') {
      return false;
    }
    if (member is Procedure && member.isMemberSignature) {
      return false;
    }
    return true;
  }

  bool isDebuggable(Member member) {
    if (member is Constructor && member.isSynthetic) {
      return false;
    }
    if (member.function.dartAsyncMarker != AsyncMarker.Sync) {
      return false;
    }
    if (member == asyncAwaitCompleterGetFuture) {
      return false;
    }
    return true;
  }

  TypeParametersDeclaration getTypeParametersDeclaration(
      List<TypeParameter> typeParams) {
    return new TypeParametersDeclaration(
        objectTable.getTypeParameterHandles(typeParams));
  }

  ParameterDeclaration getParameterDeclaration(VariableDeclaration variable) {
    final name = variable.name;
    final lib = name.startsWith('_') ? enclosingMember.enclosingLibrary : null;
    final nameHandle = objectTable.getNameHandle(lib, name);
    final typeHandle = objectTable.getHandle(variable.type);
    return new ParameterDeclaration(nameHandle, typeHandle);
  }

  List<int> getParameterFlags(FunctionNode function) {
    int getFlags(VariableDeclaration variable) {
      int flags = 0;
      if (variable.isCovariant) {
        flags |= ParameterDeclaration.isCovariantFlag;
      }
      if (variable.isGenericCovariantImpl) {
        flags |= ParameterDeclaration.isGenericCovariantImplFlag;
      }
      if (variable.isFinal) {
        flags |= ParameterDeclaration.isFinalFlag;
      }
      if (variable.isRequired) {
        flags |= ParameterDeclaration.isRequiredFlag;
      }
      return flags;
    }

    final List<int> paramFlags = <int>[];
    for (var param in function.positionalParameters) {
      paramFlags.add(getFlags(param));
    }
    for (var param in function.namedParameters) {
      paramFlags.add(getFlags(param));
    }

    for (int flags in paramFlags) {
      if (flags != 0) {
        return paramFlags;
      }
    }
    return null;
  }

  @override
  defaultMember(Member node) {
    if (node is Procedure && node.isRedirectingFactoryConstructor) {
      return;
    }
    try {
      final bool hasCode = _hasCode(node);
      start(node, hasCode);
      if (node is Field) {
        if (hasCode) {
          if (node.isConst) {
            _genPushConstExpr(node.initializer);
          } else {
            _generateNode(node.initializer);
          }
          _genReturnTOS();
        }
      } else if ((node is Procedure && !node.isRedirectingFactoryConstructor) ||
          (node is Constructor)) {
        if (hasCode) {
          if (node is Constructor) {
            _genConstructorInitializers(node);
          }
          if (node.isExternal) {
            final String nativeName = getExternalName(node);
            if (nativeName != null) {
              _genNativeCall(nativeName);
            } else {
              // TODO(alexmarkov): generate throwing UnimplementedError
              //  ("No definition given for external method Foo.bar").
              asm.emitPushNull();
            }
          } else {
            _generateNode(node.function?.body);
            // BytecodeAssembler eliminates this bytecode if it is unreachable.
            asm.emitPushNull();
          }
          if (node.function != null) {
            _recordSourcePosition(node.function.fileEndOffset);
          }
          _genReturnTOS();
        }
      } else {
        throw 'Unexpected member ${node.runtimeType} $node';
      }
      end(node, hasCode);
    } on TooManyArgumentsException catch (e) {
      CompilerContext.current.options.report(
          messageBytecodeLimitExceededTooManyArguments.withLocation(
              node.fileUri, e.fileOffset, noLength),
          Severity.error);
      hasErrors = true;
      end(node, false);
    }
  }

  bool _hasCode(Member member) {
    if (member is Procedure && member.isRedirectingFactoryConstructor) {
      return false;
    }
    // Front-end might set abstract flag on static external procedures,
    // but they can be called and should have a body.
    if (member is Procedure && member.isStatic && member.isExternal) {
      return true;
    }
    if (member.isAbstract) {
      return false;
    }
    if (member is Field) {
      // TODO(dartbug.com/34277)
      // Front-end inserts synthetic static fields "_redirecting#" to record
      // information about redirecting constructors in kernel.
      // The problem is that initializers of these synthetic static fields
      // contain incorrect kernel AST, e.g. StaticGet which takes tear-off
      // of a constructor. Do not generate bytecode for them, as they should
      // never be used.
      if (isRedirectingFactoryField(member)) {
        return false;
      }
      return hasInitializerCode(member);
    }
    return true;
  }

  bool hasInitializerCode(Field field) =>
      (field.isStatic ||
          field.isLate ||
          options.emitInstanceFieldInitializers) &&
      _hasNonTrivialInitializer(field);

  bool _needsGetter(Field field) {
    // All instance fields need a getter.
    if (!field.isStatic) return true;

    // Static fields also need a getter if they have a non-trivial initializer,
    // because it needs to be initialized lazily.
    if (_hasNonTrivialInitializer(field)) return true;

    // Static late fields with no initializer also need a getter, to check if
    // it's been initialized.
    return field.isLate && field.initializer == null;
  }

  bool _needsSetter(Field field) {
    // Late fields always need a setter, unless they're static and non-final, or
    // final with an initializer.
    if (field.isLate) {
      if (field.isStatic && !field.isFinal) return false;
      if (field.isFinal && field.initializer != null) return false;
      return true;
    }

    // Non-late static fields never need a setter.
    if (field.isStatic) return false;

    // Otherwise, the field only needs a setter if it isn't final.
    return !field.isFinal;
  }

  void _genNativeCall(String nativeName) {
    final function = enclosingMember.function;
    assert(function != null);

    if (locals.hasFactoryTypeArgsVar) {
      asm.emitPush(locals.getVarIndexInFrame(locals.factoryTypeArgsVar));
    } else if (locals.hasFunctionTypeArgsVar) {
      asm.emitPush(locals.functionTypeArgsVarIndexInFrame);
    }
    if (locals.hasReceiver) {
      asm.emitPush(locals.getVarIndexInFrame(locals.receiverVar));
    }
    for (var param in function.positionalParameters) {
      asm.emitPush(locals.getVarIndexInFrame(param));
    }
    // Native methods access their parameters by indices, so
    // native wrappers should pass arguments in the original declaration
    // order instead of sorted order.
    for (var param in locals.originalNamedParameters) {
      asm.emitPush(locals.getVarIndexInFrame(param));
    }

    final nativeEntryCpIndex = cp.addNativeEntry(nativeName);
    asm.emitNativeCall(nativeEntryCpIndex);
  }

  LibraryIndex get libraryIndex => coreTypes.index;

  Procedure _listFromLiteral;
  Procedure get listFromLiteral => _listFromLiteral ??=
      libraryIndex.getMember('dart:core', 'List', '_fromLiteral');

  Procedure _mapFromLiteral;
  Procedure get mapFromLiteral => _mapFromLiteral ??=
      libraryIndex.getMember('dart:core', 'Map', '_fromLiteral');

  Procedure _interpolateSingle;
  Procedure get interpolateSingle => _interpolateSingle ??=
      libraryIndex.getMember('dart:core', '_StringBase', '_interpolateSingle');

  Procedure _interpolate;
  Procedure get interpolate => _interpolate ??=
      libraryIndex.getMember('dart:core', '_StringBase', '_interpolate');

  Class _closureClass;
  Class get closureClass =>
      _closureClass ??= libraryIndex.getClass('dart:core', '_Closure');

  Procedure _objectInstanceOf;
  Procedure get objectInstanceOf => _objectInstanceOf ??=
      libraryIndex.getMember('dart:core', 'Object', '_instanceOf');

  Procedure _objectSimpleInstanceOf;
  Procedure get objectSimpleInstanceOf => _objectSimpleInstanceOf ??=
      libraryIndex.getMember('dart:core', 'Object', '_simpleInstanceOf');

  Field _closureInstantiatorTypeArguments;
  Field get closureInstantiatorTypeArguments =>
      _closureInstantiatorTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_instantiator_type_arguments');

  Field _closureFunctionTypeArguments;
  Field get closureFunctionTypeArguments =>
      _closureFunctionTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_function_type_arguments');

  Field _closureDelayedTypeArguments;
  Field get closureDelayedTypeArguments =>
      _closureDelayedTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_delayed_type_arguments');

  Field _closureFunction;
  Field get closureFunction => _closureFunction ??=
      libraryIndex.getMember('dart:core', '_Closure', '_function');

  Field _closureContext;
  Field get closureContext => _closureContext ??=
      libraryIndex.getMember('dart:core', '_Closure', '_context');

  Procedure _prependTypeArguments;
  Procedure get prependTypeArguments => _prependTypeArguments ??=
      libraryIndex.getTopLevelMember('dart:_internal', '_prependTypeArguments');

  Procedure _boundsCheckForPartialInstantiation;
  Procedure get boundsCheckForPartialInstantiation =>
      _boundsCheckForPartialInstantiation ??= libraryIndex.getTopLevelMember(
          'dart:_internal', '_boundsCheckForPartialInstantiation');

  Procedure _futureValue;
  Procedure get futureValue =>
      _futureValue ??= libraryIndex.getMember('dart:async', 'Future', 'value');

  Procedure _throwNewLateInitializationError;
  Procedure get throwNewLateInitializationError =>
      _throwNewLateInitializationError ??= libraryIndex.getMember(
          'dart:core', '_LateInitializationError', '_throwNew');

  Procedure _throwNewAssertionError;
  Procedure get throwNewAssertionError => _throwNewAssertionError ??=
      libraryIndex.getMember('dart:core', '_AssertionError', '_throwNew');

  Procedure _allocateInvocationMirror;
  Procedure get allocateInvocationMirror =>
      _allocateInvocationMirror ??= libraryIndex.getMember(
          'dart:core', '_InvocationMirror', '_allocateInvocationMirror');

  Procedure _unsafeCast;
  Procedure get unsafeCast => _unsafeCast ??=
      libraryIndex.getTopLevelMember('dart:_internal', 'unsafeCast');

  Procedure _iterableIterator;
  Procedure get iterableIterator => _iterableIterator ??=
      libraryIndex.getMember('dart:core', 'Iterable', 'get:iterator');

  Procedure _iteratorMoveNext;
  Procedure get iteratorMoveNext => _iteratorMoveNext ??=
      libraryIndex.getMember('dart:core', 'Iterator', 'moveNext');

  Procedure _iteratorCurrent;
  Procedure get iteratorCurrent => _iteratorCurrent ??=
      libraryIndex.getMember('dart:core', 'Iterator', 'get:current');

  Procedure _asyncAwaitCompleterGetFuture;
  Procedure get asyncAwaitCompleterGetFuture =>
      _asyncAwaitCompleterGetFuture ??= libraryIndex.tryGetMember(
          'dart:async', '_AsyncAwaitCompleter', 'get:future');

  Procedure _setAsyncThreadStackTrace;
  Procedure get setAsyncThreadStackTrace => _setAsyncThreadStackTrace ??=
      libraryIndex.getTopLevelMember('dart:async', '_setAsyncThreadStackTrace');

  Procedure _clearAsyncThreadStackTrace;
  Procedure get clearAsyncThreadStackTrace =>
      _clearAsyncThreadStackTrace ??= libraryIndex.getTopLevelMember(
          'dart:async', '_clearAsyncThreadStackTrace');

  Library _dartFfiLibrary;
  Library get dartFfiLibrary =>
      _dartFfiLibrary ??= libraryIndex.tryGetLibrary('dart:ffi');

  void _recordSourcePosition(int fileOffset) {
    asm.currentSourcePosition = fileOffset;
    maxSourcePosition = math.max(maxSourcePosition, fileOffset);
  }

  void _generateNode(TreeNode node) {
    if (node == null) {
      return;
    }
    final savedSourcePosition = asm.currentSourcePosition;
    _recordSourcePosition(node.fileOffset);
    node.accept(this);
    asm.currentSourcePosition = savedSourcePosition;
  }

  void _generateNodeList(List<TreeNode> nodes) {
    nodes.forEach(_generateNode);
  }

  void _genConstructorInitializers(Constructor node) {
    bool isRedirecting = false;
    Set<Field> initializedInInitializersList = new Set<Field>();
    for (var initializer in node.initializers) {
      if (initializer is RedirectingInitializer) {
        isRedirecting = true;
      } else if (initializer is FieldInitializer) {
        initializedInInitializersList.add(initializer.field);
      }
    }

    if (!isRedirecting) {
      initializedFields = new Set<Field>();
      for (var field in node.enclosingClass.fields) {
        if (!field.isStatic) {
          if (field.isLate) {
            if (!initializedInInitializersList.contains(field)) {
              _genLateFieldInitializer(field);
            }
          } else if (field.initializer != null) {
            if (initializedInInitializersList.contains(field)) {
              // Do not store a value into the field as it is going to be
              // overwritten by initializers list.
              _generateNode(field.initializer);
              asm.emitDrop1();
            } else {
              _genFieldInitializer(field, field.initializer);
            }
          }
        }
      }
    }

    _generateNodeList(node.initializers);

    if (!isRedirecting) {
      nullableFields = <ObjectHandle>[];
      for (var field in node.enclosingClass.fields) {
        if (!field.isStatic &&
            !field.isLate &&
            !initializedFields.contains(field)) {
          nullableFields.add(objectTable.getHandle(field));
        }
      }
      initializedFields = null; // No more initialized fields, please.
    }
  }

  void _genFieldInitializer(Field field, Expression initializer) {
    assert(!field.isStatic);

    if (initializer is NullLiteral && !initializedFields.contains(field)) {
      return;
    }

    _genPushReceiver();
    _generateNode(initializer);

    final int cpIndex = cp.addInstanceField(field);
    asm.emitStoreFieldTOS(cpIndex);

    initializedFields.add(field);
  }

  void _genLateFieldInitializer(Field field) {
    assert(!field.isStatic);

    if (_isTrivialInitializer(field.initializer)) {
      _genFieldInitializer(field, field.initializer);
      return;
    }

    _genPushReceiver();

    final int cpIndex = cp.addInstanceField(field);
    asm.emitInitLateField(cpIndex);

    initializedFields.add(field);
  }

  void _genArguments(Expression receiver, Arguments arguments,
      {int storeReceiverToLocal}) {
    if (arguments.types.isNotEmpty) {
      _genTypeArguments(arguments.types);
    }
    _generateNode(receiver);
    if (storeReceiverToLocal != null) {
      asm.emitStoreLocal(storeReceiverToLocal);
    }
    _generateNodeList(arguments.positional);
    arguments.named.forEach((NamedExpression ne) => _generateNode(ne.value));
  }

  void _genPushBool(bool value) {
    if (value) {
      asm.emitPushTrue();
    } else {
      asm.emitPushFalse();
    }
  }

  void _genPushInt(int value) {
    // TODO(alexmarkov): relax this constraint as PushInt instruction can
    // hold up to 32-bit signed operand (note that interpreter assumes
    // it is Smi).
    if (value.bitLength + 1 <= 16) {
      asm.emitPushInt(value);
    } else {
      asm.emitPushConstant(cp.addObjectRef(new IntConstant(value)));
    }
  }

  Constant _getConstant(Expression expr) {
    if (expr is ConstantExpression) {
      return expr.constant;
    }

    // Literals outside of const expressions are not transformed by the
    // constant transformer, but they need to be treated as constants here.
    if (expr is BoolLiteral) return new BoolConstant(expr.value);
    if (expr is DoubleLiteral) return new DoubleConstant(expr.value);
    if (expr is IntLiteral) return new IntConstant(expr.value);
    if (expr is NullLiteral) return new NullConstant();
    if (expr is StringLiteral) return new StringConstant(expr.value);

    throw 'Expected constant, got ${expr.runtimeType}';
  }

  void _genPushConstant(Constant constant) {
    if (constant is NullConstant) {
      asm.emitPushNull();
    } else if (constant is BoolConstant) {
      _genPushBool(constant.value);
    } else if (constant is IntConstant) {
      _genPushInt(constant.value);
    } else {
      asm.emitPushConstant(cp.addObjectRef(constant));
    }
  }

  void _genPushConstExpr(Expression expr) {
    if (expr is ConstantExpression) {
      _genPushConstant(expr.constant);
    } else if (expr is NullLiteral) {
      asm.emitPushNull();
    } else if (expr is BoolLiteral) {
      _genPushBool(expr.value);
    } else if (expr is IntLiteral) {
      _genPushInt(expr.value);
    } else {
      _genPushConstant(_getConstant(expr));
    }
  }

  void _genReturnTOS([int yieldSourcePosition = null]) {
    if (options.causalAsyncStacks &&
        parentFunction != null &&
        (parentFunction.dartAsyncMarker == AsyncMarker.Async ||
            parentFunction.dartAsyncMarker == AsyncMarker.AsyncStar)) {
      final savedSourcePosition = asm.currentSourcePosition;
      _recordSourcePosition(TreeNode.noOffset);
      _genDirectCall(
          clearAsyncThreadStackTrace, objectTable.getArgDescHandle(0), 0);
      asm.emitDrop1();
      asm.currentSourcePosition = savedSourcePosition;
    }

    if (yieldSourcePosition != null && options.emitSourcePositions) {
      asm.emitYieldPointSourcePosition(yieldSourcePosition);
    }
    asm.emitReturnTOS();
  }

  void _genDirectCall(Member target, ObjectHandle argDesc, int totalArgCount,
      {bool isGet: false,
      bool isSet: false,
      bool isDynamicForwarder: false,
      bool isUnchecked: false,
      TreeNode node}) {
    assert(!isGet || !isSet);
    final kind = isGet
        ? InvocationKind.getter
        : (isSet ? InvocationKind.setter : InvocationKind.method);
    final cpIndex = cp.addDirectCall(kind, target, argDesc, isDynamicForwarder);

    if (totalArgCount >= argumentsLimit) {
      throw new TooManyArgumentsException(node.fileOffset);
    }
    if (inferredTypeMetadata != null && node != null) {
      _appendInferredType(node, asm.offset);
    }
    if (isUnchecked) {
      asm.emitUncheckedDirectCall(cpIndex, totalArgCount);
    } else {
      asm.emitDirectCall(cpIndex, totalArgCount);
    }
    if (inferredTypeMetadata != null && node != null) {
      _replaceWithConstantValue(node);
    }
  }

  void _genDirectCallWithArgs(Member target, Arguments args,
      {bool hasReceiver: false,
      bool isFactory: false,
      bool isUnchecked: false,
      TreeNode node}) {
    final argDesc = objectTable.getArgDescHandleByArguments(args,
        hasReceiver: hasReceiver, isFactory: isFactory);

    int totalArgCount = args.positional.length + args.named.length;
    if (hasReceiver) {
      totalArgCount++;
    }
    if (args.types.isNotEmpty || isFactory) {
      // VM needs type arguments for every invocation of a factory constructor.
      // TODO(alexmarkov): Clean this up.
      totalArgCount++;
    }

    _genDirectCall(target, argDesc, totalArgCount,
        isUnchecked: isUnchecked, node: node);
  }

  void _genTypeArguments(List<DartType> typeArgs, {Class instantiatingClass}) {
    int typeArgsCPIndex() {
      if (instantiatingClass != null) {
        typeArgs = getInstantiatorTypeArguments(instantiatingClass, typeArgs);
      }
      return cp.addTypeArguments(typeArgs);
    }

    if (typeArgs.isEmpty || !hasFreeTypeParameters(typeArgs)) {
      asm.emitPushConstant(typeArgsCPIndex());
    } else {
      final flattenedTypeArgs = (instantiatingClass != null &&
              (instantiatorTypeArguments != null ||
                  functionTypeParameters != null))
          ? flattenInstantiatorTypeArguments(instantiatingClass, typeArgs)
          : typeArgs;
      if (_canReuseInstantiatorTypeArguments(flattenedTypeArgs)) {
        _genPushInstantiatorTypeArguments();
      } else if (_canReuseFunctionTypeArguments(flattenedTypeArgs)) {
        _genPushFunctionTypeArguments();
      } else {
        _genPushInstantiatorAndFunctionTypeArguments(typeArgs);
        // TODO(alexmarkov): Optimize type arguments instantiation
        // by passing rA = 1 in InstantiateTypeArgumentsTOS.
        // For this purpose, we need to detect if type arguments
        // would be all-dynamic in case of all-dynamic instantiator and
        // function type arguments.
        // Corresponding check is implemented in VM in
        // TypeArguments::IsRawWhenInstantiatedFromRaw.
        asm.emitInstantiateTypeArgumentsTOS(0, typeArgsCPIndex());
      }
    }
  }

  void _genPushInstantiatorAndFunctionTypeArguments(List<DartType> types) {
    if (classTypeParameters != null &&
        types.any((t) => containsTypeVariable(t, classTypeParameters))) {
      assert(instantiatorTypeArguments != null);
      _genPushInstantiatorTypeArguments();
    } else {
      asm.emitPushNull();
    }
    if (functionTypeParametersSet != null &&
        types.any((t) => containsTypeVariable(t, functionTypeParametersSet))) {
      _genPushFunctionTypeArguments();
    } else {
      asm.emitPushNull();
    }
  }

  void _genPushInstantiatorTypeArguments() {
    if (instantiatorTypeArguments != null) {
      if (locals.hasFactoryTypeArgsVar) {
        assert(enclosingMember is Procedure &&
            (enclosingMember as Procedure).isFactory);
        _genLoadVar(locals.factoryTypeArgsVar);
      } else {
        _genPushReceiver();
        final int cpIndex = cp.addTypeArgumentsField(enclosingClass);
        asm.emitLoadTypeArgumentsField(cpIndex);
      }
    } else {
      asm.emitPushNull();
    }
  }

  bool _canReuseInstantiatorTypeArguments(List<DartType> typeArgs) {
    if (instantiatorTypeArguments == null) {
      return false;
    }

    if (typeArgs.length > instantiatorTypeArguments.length) {
      return false;
    }

    for (int i = 0; i < typeArgs.length; ++i) {
      if (typeArgs[i] != instantiatorTypeArguments[i]) {
        return false;
      }
    }

    return true;
  }

  bool _canReuseFunctionTypeArguments(List<DartType> typeArgs) {
    if (functionTypeParameters == null) {
      return false;
    }

    if (typeArgs.length > functionTypeParameters.length) {
      return false;
    }

    for (int i = 0; i < typeArgs.length; ++i) {
      final typeArg = typeArgs[i];
      if (!(typeArg is TypeParameterType &&
          typeArg.parameter == functionTypeParameters[i])) {
        return false;
      }
    }

    return true;
  }

  void _genPushFunctionTypeArguments() {
    if (locals.hasFunctionTypeArgsVar) {
      asm.emitPush(locals.functionTypeArgsVarIndexInFrame);
    } else {
      asm.emitPushNull();
    }
  }

  void _genPushContextForVariable(VariableDeclaration variable,
      {int currentContextLevel}) {
    currentContextLevel ??= locals.currentContextLevel;
    int depth = currentContextLevel - locals.getContextLevelOfVar(variable);
    assert(depth >= 0);

    asm.emitPush(locals.contextVarIndexInFrame);
    if (depth > 0) {
      for (; depth > 0; --depth) {
        asm.emitLoadContextParent();
      }
    }
  }

  void _genPushContextIfCaptured(VariableDeclaration variable) {
    if (locals.isCaptured(variable)) {
      _genPushContextForVariable(variable);
    }
  }

  void _genLoadVar(VariableDeclaration v, {int currentContextLevel}) {
    if (locals.isCaptured(v)) {
      _genPushContextForVariable(v, currentContextLevel: currentContextLevel);
      asm.emitLoadContextVar(
          locals.getVarContextId(v), locals.getVarIndexInContext(v));
    } else {
      asm.emitPush(locals.getVarIndexInFrame(v));
    }
  }

  void _genPushReceiver() {
    // TODO(alexmarkov): generate more efficient access to receiver
    // even if it is captured.
    _genLoadVar(locals.receiverVar);
  }

  // Stores value into variable.
  // If variable is captured, context should be pushed before value.
  void _genStoreVar(VariableDeclaration variable) {
    if (locals.isCaptured(variable)) {
      asm.emitStoreContextVar(locals.getVarContextId(variable),
          locals.getVarIndexInContext(variable));
    } else {
      asm.emitPopLocal(locals.getVarIndexInFrame(variable));
    }
  }

  /// Generates bool condition. Returns `true` if condition is negated.
  bool _genCondition(Expression condition) {
    bool negated = false;
    if (condition is Not) {
      condition = (condition as Not).operand;
      negated = true;
    }
    _generateNode(condition);
    if (nullabilityDetector.isNullable(condition)) {
      asm.emitAssertBoolean(0);
    }
    return negated;
  }

  /// Returns value of the given expression if it is a bool constant.
  /// Otherwise, returns `null`.
  bool _constantConditionValue(Expression condition) {
    if (options.keepUnreachableCode) {
      return null;
    }
    // TODO(dartbug.com/34585): use constant evaluator to evaluate
    // expressions in a non-constant context.
    if (condition is Not) {
      final operand = _constantConditionValue(condition.operand);
      return (operand != null) ? !operand : null;
    }
    if (condition is BoolLiteral) {
      return condition.value;
    }
    if (condition is ConstantExpression) {
      Constant constant = condition.constant;
      if (constant is BoolConstant) {
        return constant.value;
      }
    }
    return null;
  }

  void _genConditionAndJumpIf(Expression condition, bool value, Label dest) {
    final bool constantValue = _constantConditionValue(condition);
    if (constantValue != null) {
      if (constantValue == value) {
        asm.emitJump(dest);
      }
      return;
    }
    if (condition is MethodInvocation &&
        condition.name.name == '==' &&
        (condition.receiver is NullLiteral ||
            condition.arguments.positional.single is NullLiteral)) {
      if (condition.receiver is NullLiteral) {
        _generateNode(condition.arguments.positional.single);
      } else {
        _generateNode(condition.receiver);
      }
      if (options.emitDebuggerStops &&
          condition.fileOffset != TreeNode.noOffset) {
        final savedSourcePosition = asm.currentSourcePosition;
        _recordSourcePosition(condition.fileOffset);
        asm.emitDebugCheck();
        asm.currentSourcePosition = savedSourcePosition;
      }
      if (value) {
        asm.emitJumpIfNull(dest);
      } else {
        asm.emitJumpIfNotNull(dest);
      }
      return;
    }
    if (condition is Not) {
      _genConditionAndJumpIf(condition.operand, !value, dest);
    } else if (condition is LogicalExpression) {
      assert(condition.operator == '||' || condition.operator == '&&');
      final isOR = (condition.operator == '||');

      Label shortCircuit, done;
      if (isOR == value) {
        shortCircuit = dest;
      } else {
        shortCircuit = done = new Label();
      }
      _genConditionAndJumpIf(condition.left, isOR, shortCircuit);
      _genConditionAndJumpIf(condition.right, value, dest);
      if (done != null) {
        asm.bind(done);
      }
    } else {
      bool negated = _genCondition(condition);
      if (negated) {
        value = !value;
      }
      if (value) {
        asm.emitJumpIfTrue(dest);
      } else {
        asm.emitJumpIfFalse(dest);
      }
    }
  }

  int _getDefaultParamConstIndex(VariableDeclaration param) {
    if (param.initializer == null) {
      return cp.addObjectRef(null);
    }
    final constant = _getConstant(param.initializer);
    return cp.addObjectRef(constant);
  }

  // Duplicates value on top of the stack using temporary variable with
  // given index.
  void _genDupTOS(int tempIndexInFrame) {
    // TODO(alexmarkov): Consider introducing Dup bytecode or keeping track of
    // expression stack depth.
    asm.emitStoreLocal(tempIndexInFrame);
    asm.emitPush(tempIndexInFrame);
  }

  /// Generates is-test for the value at TOS.
  void _genInstanceOf(DartType type) {
    if (typeEnvironment.isTop(type)) {
      asm.emitDrop1();
      asm.emitPushTrue();
      return;
    }

    if (type is InterfaceType &&
        (type.typeArguments.isEmpty || isAllDynamic(type.typeArguments))) {
      asm.emitPushConstant(cp.addType(type));
      final argDesc = objectTable.getArgDescHandle(2);
      final cpIndex = cp.addInterfaceCall(
          InvocationKind.method, objectSimpleInstanceOf, argDesc);
      asm.emitInterfaceCall(cpIndex, 2);
      return;
    }

    if (hasFreeTypeParameters([type])) {
      _genPushInstantiatorAndFunctionTypeArguments([type]);
    } else {
      asm.emitPushNull(); // Instantiator type arguments.
      asm.emitPushNull(); // Function type arguments.
    }
    asm.emitPushConstant(cp.addType(type));
    final argDesc = objectTable.getArgDescHandle(4);
    final cpIndex =
        cp.addInterfaceCall(InvocationKind.method, objectInstanceOf, argDesc);
    asm.emitInterfaceCall(cpIndex, 4);
  }

  void start(Member node, bool hasCode) {
    enclosingClass = node.enclosingClass;
    enclosingMember = node;
    enclosingFunction = node.function;
    parentFunction = null;
    isClosure = false;
    hasErrors = false;
    staticTypeContext.enterMember(node);
    final isFactory = node is Procedure && node.isFactory;
    if (node.isInstanceMember || node is Constructor || isFactory) {
      if (enclosingClass.typeParameters.isNotEmpty) {
        classTypeParameters =
            new Set<TypeParameter>.from(enclosingClass.typeParameters);
        // Treat type arguments of factory constructors as class
        // type parameters.
        if (isFactory) {
          classTypeParameters.addAll(node.function.typeParameters);
        }
      }
      if (hasInstantiatorTypeArguments(enclosingClass)) {
        final typeParameters = getTypeParameterTypes(isFactory
            ? node.function.typeParameters
            : enclosingClass.typeParameters);
        instantiatorTypeArguments =
            flattenInstantiatorTypeArguments(enclosingClass, typeParameters);
      }
    }
    if (enclosingFunction != null &&
        enclosingFunction.typeParameters.isNotEmpty) {
      functionTypeParameters =
          new List<TypeParameter>.from(enclosingFunction.typeParameters);
      functionTypeParametersSet = functionTypeParameters.toSet();
    }
    procedureAttributesMetadata = procedureAttributesMetadataRepository != null
        ? procedureAttributesMetadataRepository.mapping[node]
        : null;

    if (inferredTypeMetadata != null) {
      if (node is Field) {
        // Field type is at PC = -1.
        _appendInferredType(node, -1);
      } else if (enclosingFunction != null && hasCode) {
        assert(node is Procedure || node is Constructor);
        // Parameter types are at PC = -N,..,-1 where N - number of declared
        // (explicit) parameters.
        int i = -(enclosingFunction.positionalParameters.length +
            enclosingFunction.namedParameters.length);
        for (var v in enclosingFunction.positionalParameters) {
          _appendInferredType(v, i);
          ++i;
        }
        for (var v in enclosingFunction.namedParameters) {
          _appendInferredType(v, i);
          ++i;
        }
      }
    }

    if (!hasCode) {
      return;
    }

    labeledStatements = null;
    switchCases = null;
    tryCatches = null;
    finallyBlocks = null;
    yieldPoints = null; // Initialized when entering sync-yielding closure.
    contextLevels = null;
    closures = null;
    initializedFields = null; // Tracked for constructors only.
    nullableFields = const <ObjectHandle>[];
    cp = new ConstantPool(stringTable, objectTable);
    asm = new BytecodeAssembler(options);
    savedAssemblers = null;
    currentLoopDepth = 0;
    savedMaxSourcePositions = <int>[];
    maxSourcePosition = node.fileOffset;

    locals = new LocalVariables(
        node, options, staticTypeContext, directCallMetadata);
    locals.enterScope(node);
    assert(!locals.isSyncYieldingFrame);

    int position;
    if (node is Procedure) {
      position = node.startFileOffset;
    } else if (node is Constructor) {
      position = node.startFileOffset;
    } else {
      position = node.fileOffset;
    }
    _recordSourcePosition(position);
    _genPrologue(node, node.function);
    _setupInitialContext(node.function);
    _emitFirstDebugCheck(node.function);
    if (node is Procedure && node.isInstanceMember) {
      _checkArguments(node.function);
    }
    _genEqualsOperatorNullHandling(node);
  }

  void _appendInferredType(TreeNode node, int pc) {
    final InferredType md = inferredTypeMetadata[node];
    if (md == null || (pc >= 0 && asm.isUnreachable)) {
      return;
    }
    inferredTypesAttribute ??= <Constant>[];
    // List of triplets (PC, concreteClass, flags).
    // Verify that PCs are monotonically increasing.
    assert(inferredTypesAttribute.isEmpty ||
        (inferredTypesAttribute[inferredTypesAttribute.length - 3]
                    as IntConstant)
                .value <
            pc);
    inferredTypesAttribute.add(IntConstant(pc));
    Class concreteClass = md.concreteClass;
    // VM uses more specific function type and doesn't expect to
    // see inferred _Closure class.
    if (concreteClass != null && concreteClass != closureClass) {
      inferredTypesAttribute.add(TypeLiteralConstant(coreTypes.rawType(
          concreteClass,
          (concreteClass == coreTypes.nullClass)
              ? Nullability.nullable
              : staticTypeContext.nonNullable)));
    } else {
      inferredTypesAttribute.add(NullConstant());
    }
    // Inferred constant values are handled in bytecode generator
    // (_replaceWithConstantValue, _initConstantParameters) and
    // not propagated to VM.
    final flags = md.flags & ~InferredType.flagConstant;
    inferredTypesAttribute.add(IntConstant(flags));
  }

  void _replaceWithConstantValue(TreeNode node) {
    final InferredType md = inferredTypeMetadata[node];
    if (md == null || md.constantValue == null || asm.isUnreachable) {
      return;
    }
    asm.emitDrop1();
    _genPushConstant(md.constantValue);
  }

  // Generate additional code for 'operator ==' to handle nulls.
  void _genEqualsOperatorNullHandling(Member member) {
    if (member.name.name != '==' ||
        locals.numParameters != 2 ||
        member.enclosingClass == coreTypes.objectClass) {
      return;
    }

    Label done = new Label();

    _genLoadVar(member.function.positionalParameters[0]);
    asm.emitJumpIfNotNull(done);

    asm.emitPushFalse();
    _genReturnTOS();

    asm.bind(done);
  }

  void end(Member node, bool hasCode) {
    if (!hasErrors) {
      Code code;
      if (hasCode) {
        if (options.emitLocalVarInfo) {
          // Leave the scopes which were entered in _genPrologue and
          // _setupInitialContext.
          asm.localVariableTable.leaveAllScopes(
              asm.offset,
              node.function != null
                  ? node.function.fileEndOffset
                  : node.fileEndOffset);
        }

        List<int> parameterFlags = null;
        int forwardingStubTargetCpIndex = null;
        int defaultFunctionTypeArgsCpIndex = null;

        if (node is Constructor) {
          parameterFlags = getParameterFlags(node.function);
        } else if (node is Procedure) {
          parameterFlags = getParameterFlags(node.function);

          if (node.isForwardingStub) {
            forwardingStubTargetCpIndex =
                cp.addObjectRef(node.forwardingStubSuperTarget);
          }

          final defaultTypes = getDefaultFunctionTypeArguments(node.function);
          if (defaultTypes != null) {
            defaultFunctionTypeArgsCpIndex = cp.addTypeArguments(defaultTypes);
          }
        }
        code = new Code(
            cp,
            asm.bytecode,
            asm.exceptionsTable,
            finalizeSourcePositions(),
            finalizeLocalVariables(),
            nullableFields,
            closures ?? const <ClosureDeclaration>[],
            parameterFlags,
            forwardingStubTargetCpIndex,
            defaultFunctionTypeArgsCpIndex);
        bytecodeComponent.codes.add(code);
      }
      if (node is Field) {
        fieldDeclarations.add(getFieldDeclaration(node, code));
      } else {
        functionDeclarations.add(getFunctionDeclaration(node, code));
      }
    }

    staticTypeContext.leaveMember(node);
    enclosingClass = null;
    enclosingMember = null;
    enclosingFunction = null;
    parentFunction = null;
    isClosure = null;
    classTypeParameters = null;
    functionTypeParameters = null;
    functionTypeParametersSet = null;
    instantiatorTypeArguments = null;
    locals = null;
    labeledStatements = null;
    switchCases = null;
    tryCatches = null;
    finallyBlocks = null;
    yieldPoints = null;
    contextLevels = null;
    closures = null;
    initializedFields = null;
    nullableFields = null;
    cp = null;
    asm = null;
    savedAssemblers = null;
    hasErrors = false;
    procedureAttributesMetadata = null;
    inferredTypesAttribute = null;
  }

  SourcePositions finalizeSourcePositions() {
    if (asm.sourcePositions.isEmpty) {
      return null;
    }
    bytecodeComponent.sourcePositions.add(asm.sourcePositions);
    return asm.sourcePositions;
  }

  LocalVariableTable finalizeLocalVariables() {
    final localVariables = asm.localVariableTable;
    assert(!localVariables.hasActiveScopes);
    if (localVariables.isEmpty) {
      return null;
    }
    bytecodeComponent.localVariables.add(localVariables);
    return localVariables;
  }

  void _genPrologue(Node node, FunctionNode function) {
    if (locals.hasOptionalParameters) {
      final int numOptionalPositional = function.positionalParameters.length -
          function.requiredParameterCount;
      final int numOptionalNamed = function.namedParameters.length;
      final int numFixed =
          locals.numParameters - (numOptionalPositional + numOptionalNamed);

      asm.emitEntryOptional(numFixed, numOptionalPositional, numOptionalNamed);

      if (numOptionalPositional != 0) {
        assert(numOptionalNamed == 0);
        for (int i = 0; i < numOptionalPositional; i++) {
          final param = function
              .positionalParameters[function.requiredParameterCount + i];
          asm.emitLoadConstant(numFixed + i, _getDefaultParamConstIndex(param));
        }
      } else {
        assert(numOptionalNamed != 0);
        for (int i = 0; i < numOptionalNamed; i++) {
          final param = locals.sortedNamedParameters[i];
          asm.emitLoadConstant(numFixed + i, cp.addName(param.name));
          asm.emitLoadConstant(numFixed + i, _getDefaultParamConstIndex(param));
        }
      }

      asm.emitFrame(locals.frameSize - locals.numParameters);
    } else if (isClosure) {
      asm.emitEntryFixed(locals.numParameters, locals.frameSize);
    } else {
      asm.emitEntry(locals.frameSize);
    }

    if (isClosure) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureContext));
      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }

    if (locals.hasFunctionTypeArgsVar && function.typeParameters.isNotEmpty) {
      assert(!(node is Procedure && node.isFactory));

      Label done = new Label();

      if (isClosure) {
        _handleDelayedTypeArguments(done);
      }

      asm.emitCheckFunctionTypeArgs(function.typeParameters.length,
          locals.functionTypeArgsVarIndexInFrame);

      _handleDefaultTypeArguments(function, done);

      asm.bind(done);
    } else if (isClosure &&
        !(parentFunction != null &&
            parentFunction.dartAsyncMarker != AsyncMarker.Sync)) {
      // Closures can be called dynamically with arbitrary arguments,
      // so they should check number of type arguments, even if
      // closure is not generic.
      // Synthetic async_op closures don't need this check.
      asm.emitCheckFunctionTypeArgs(0, locals.scratchVarIndexInFrame);
    }

    // Open initial scope before the first CheckStack, as VM might
    // need to know context level.
    if (options.emitLocalVarInfo && function != null) {
      asm.localVariableTable.enterScope(
          asm.offset,
          isClosure ? locals.contextLevelAtEntry : locals.currentContextLevel,
          function.fileOffset);
      if (locals.hasContextVar) {
        asm.localVariableTable
            .recordContextVariable(asm.offset, locals.contextVarIndexInFrame);
      }
      if (locals.hasReceiver &&
          (!isClosure || locals.isCaptured(locals.receiverVar))) {
        _declareLocalVariable(locals.receiverVar, function.fileOffset);
      }
      for (var v in function.positionalParameters) {
        if (!locals.isCaptured(v)) {
          _declareLocalVariable(v, function.fileOffset);
        }
      }
      for (var v in locals.sortedNamedParameters) {
        if (!locals.isCaptured(v)) {
          _declareLocalVariable(v, function.fileOffset);
        }
      }
      if (locals.hasFunctionTypeArgsVar) {
        _declareLocalVariable(locals.functionTypeArgsVar, function.fileOffset);
      }
    }

    // CheckStack must see a properly initialized context when stress-testing
    // stack trace collection.
    asm.emitCheckStack(0);

    if (locals.hasFunctionTypeArgsVar && isClosure) {
      if (function.typeParameters.isNotEmpty) {
        final int numParentTypeArgs = locals.numParentTypeArguments;
        asm.emitPush(locals.functionTypeArgsVarIndexInFrame);
        asm.emitPush(locals.closureVarIndexInFrame);
        asm.emitLoadFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));
        _genPushInt(numParentTypeArgs);
        _genPushInt(numParentTypeArgs + function.typeParameters.length);
        _genDirectCall(
            prependTypeArguments, objectTable.getArgDescHandle(4), 4);
        asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
      } else {
        asm.emitPush(locals.closureVarIndexInFrame);
        asm.emitLoadFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));
        asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
      }
    }

    if (inferredTypeMetadata != null && function != null) {
      _initConstantParameters(function);
    }
  }

  void _handleDelayedTypeArguments(Label doneCheckingTypeArguments) {
    Label noDelayedTypeArgs = new Label();

    asm.emitPush(locals.closureVarIndexInFrame);
    asm.emitLoadFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));
    asm.emitStoreLocal(locals.functionTypeArgsVarIndexInFrame);
    asm.emitPushConstant(cp.addEmptyTypeArguments());
    asm.emitJumpIfEqStrict(noDelayedTypeArgs);

    // There are non-empty delayed type arguments, and they are stored
    // into function type args variable already.
    // Just verify that there are no passed type arguments.
    asm.emitCheckFunctionTypeArgs(0, locals.scratchVarIndexInFrame);
    asm.emitJump(doneCheckingTypeArguments);

    asm.bind(noDelayedTypeArgs);
  }

  void _handleDefaultTypeArguments(
      FunctionNode function, Label doneCheckingTypeArguments) {
    List<DartType> defaultTypes = getDefaultFunctionTypeArguments(function);
    if (defaultTypes == null) {
      return;
    }

    asm.emitJumpIfNotZeroTypeArgs(doneCheckingTypeArguments);

    // Load parent function type arguments if they are used to
    // instantiate default types.
    if (isClosure &&
        defaultTypes
            .any((t) => containsTypeVariable(t, functionTypeParametersSet))) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));
      asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
    }

    _genTypeArguments(defaultTypes);
    asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
  }

  void _initConstantParameters(FunctionNode function) {
    function.positionalParameters.forEach(_initParameterIfConstant);
    locals.sortedNamedParameters.forEach(_initParameterIfConstant);
  }

  void _initParameterIfConstant(VariableDeclaration variable) {
    final md = inferredTypeMetadata[variable];
    if (md != null && md.constantValue != null) {
      _genPushConstant(md.constantValue);
      asm.emitPopLocal(locals.isCaptured(variable)
          ? locals.getOriginalParamSlotIndex(variable)
          : locals.getVarIndexInFrame(variable));
    }
  }

  void _setupInitialContext(FunctionNode function) {
    _allocateContextIfNeeded();

    if (options.emitLocalVarInfo && locals.currentContextSize > 0) {
      // Open a new scope after allocating context.
      asm.localVariableTable.enterScope(asm.offset, locals.currentContextLevel,
          function != null ? function.fileOffset : enclosingMember.fileOffset);
    }

    if (locals.hasCapturedParameters) {
      // Copy captured parameters to their respective locations in the context.
      if (!isClosure) {
        if (locals.hasFactoryTypeArgsVar) {
          _copyParamIfCaptured(locals.factoryTypeArgsVar);
        }
        if (locals.hasCapturedReceiverVar) {
          _genPushContextForVariable(locals.capturedReceiverVar);
          asm.emitPush(locals.getVarIndexInFrame(locals.receiverVar));
          _genStoreVar(locals.capturedReceiverVar);
        }
      }
      if (function != null) {
        function.positionalParameters.forEach(_copyParamIfCaptured);
        locals.sortedNamedParameters.forEach(_copyParamIfCaptured);
      }
    }
  }

  void _emitFirstDebugCheck(FunctionNode function) {
    if (options.emitDebuggerStops) {
      // DebugCheck instruction should be emitted after parameter variables
      // are declared and copied into context.
      // The debugger expects the source position to correspond to the
      // declaration position of the last parameter, if any, or of the function.
      // The DebugCheck must be encountered each time an async op is reentered.
      if (options.emitSourcePositions && function != null) {
        var pos = TreeNode.noOffset;
        if (function.namedParameters.isNotEmpty) {
          pos = function.namedParameters.last.fileOffset;
        } else if (function.positionalParameters.isNotEmpty) {
          pos = function.positionalParameters.last.fileOffset;
        }
        if (pos == TreeNode.noOffset) {
          pos = function.fileOffset;
        }
        _recordSourcePosition(pos);
      }
      asm.emitDebugCheck();
    }
  }

  void _copyParamIfCaptured(VariableDeclaration variable) {
    if (locals.isCaptured(variable)) {
      if (options.emitLocalVarInfo) {
        _declareLocalVariable(variable, enclosingFunction.fileOffset);
      }
      _genPushContextForVariable(variable);
      asm.emitPush(locals.getOriginalParamSlotIndex(variable));
      _genStoreVar(variable);
      // TODO(alexmarkov): We need to store null at the original parameter
      // location, because the original value may need to be GC'ed.
    }
  }

  void _declareLocalVariable(
      VariableDeclaration variable, int initializedPosition) {
    assert(variable.name != null);
    bool isCaptured = locals.isCaptured(variable);
    asm.localVariableTable.declareVariable(
        asm.offset,
        isCaptured,
        isCaptured
            ? locals.getVarIndexInContext(variable)
            : locals.getVarIndexInFrame(variable),
        cp.addName(variable.name),
        cp.addType(variable.type),
        variable.fileOffset,
        initializedPosition);
  }

  bool get canSkipTypeChecksForNonCovariantArguments =>
      !isClosure && enclosingMember.name.name != 'call';

  bool get skipTypeChecksForGenericCovariantImplArguments =>
      procedureAttributesMetadata != null &&
      !procedureAttributesMetadata.hasNonThisUses &&
      // TODO(alexmarkov): fix building of flow graph for implicit closures so
      // it would include missing checks and remove this condition.
      !procedureAttributesMetadata.hasTearOffUses;

  Member _getForwardingStubSuperTarget() {
    if (!isClosure) {
      final member = enclosingMember;
      if (member.isInstanceMember &&
          member is Procedure &&
          member.isForwardingStub) {
        return member.forwardingStubSuperTarget;
      }
    }
    return null;
  }

  // Types in a target of a forwarding stub are encoded in terms of target type
  // parameters. Substitute them with host type parameters to be able
  // to use them (e.g. instantiate) in the context of host.
  Substitution _getForwardingSubstitution(
      FunctionNode host, Member forwardingTarget) {
    if (forwardingTarget == null) {
      return null;
    }
    final Class targetClass = forwardingTarget.enclosingClass;
    final Supertype instantiatedTargetClass =
        hierarchy.getClassAsInstanceOf(enclosingClass, targetClass);
    if (instantiatedTargetClass == null) {
      throw 'Class $targetClass is not found among implemented interfaces of'
          ' $enclosingClass (for forwarding stub $enclosingMember)';
    }
    assert(instantiatedTargetClass.classNode == targetClass);
    assert(instantiatedTargetClass.typeArguments.length ==
        targetClass.typeParameters.length);
    final Map<TypeParameter, DartType> map =
        new Map<TypeParameter, DartType>.fromIterables(
            targetClass.typeParameters, instantiatedTargetClass.typeArguments);
    if (forwardingTarget.function != null) {
      final targetTypeParameters = forwardingTarget.function.typeParameters;
      assert(host.typeParameters.length == targetTypeParameters.length);
      for (int i = 0; i < targetTypeParameters.length; ++i) {
        map[targetTypeParameters[i]] =
            new TypeParameterType(host.typeParameters[i], Nullability.legacy);
      }
    }
    return Substitution.fromMap(map);
  }

  /// If member being compiled is a forwarding stub, then returns type
  /// parameter bounds to check for the forwarding stub target.
  Map<TypeParameter, DartType> _getForwardingBounds(FunctionNode function,
      Member forwardingTarget, Substitution forwardingSubstitution) {
    if (function.typeParameters.isEmpty || forwardingTarget == null) {
      return null;
    }
    final forwardingBounds = <TypeParameter, DartType>{};
    for (int i = 0; i < function.typeParameters.length; ++i) {
      DartType bound = forwardingSubstitution
          .substituteType(forwardingTarget.function.typeParameters[i].bound);
      forwardingBounds[function.typeParameters[i]] = bound;
    }
    return forwardingBounds;
  }

  /// If member being compiled is a forwarding stub, then returns parameter
  /// types to check for the forwarding stub target.
  Map<VariableDeclaration, DartType> _getForwardingParameterTypes(
      FunctionNode function,
      Member forwardingTarget,
      Substitution forwardingSubstitution) {
    if (forwardingTarget == null) {
      return null;
    }

    if (forwardingTarget is Field) {
      if ((enclosingMember as Procedure).isGetter) {
        return const <VariableDeclaration, DartType>{};
      } else {
        // Forwarding stub for a covariant field setter.
        assert((enclosingMember as Procedure).isSetter);
        assert(function.typeParameters.isEmpty &&
            function.positionalParameters.length == 1 &&
            function.namedParameters.length == 0);
        return <VariableDeclaration, DartType>{
          function.positionalParameters.single:
              forwardingSubstitution.substituteType(forwardingTarget.type)
        };
      }
    }

    final forwardingParams = <VariableDeclaration, DartType>{};
    for (int i = 0; i < function.positionalParameters.length; ++i) {
      DartType type = forwardingSubstitution.substituteType(
          forwardingTarget.function.positionalParameters[i].type);
      forwardingParams[function.positionalParameters[i]] = type;
    }
    for (var hostParam in function.namedParameters) {
      VariableDeclaration targetParam = forwardingTarget
          .function.namedParameters
          .firstWhere((p) => p.name == hostParam.name);
      forwardingParams[hostParam] =
          forwardingSubstitution.substituteType(targetParam.type);
    }
    return forwardingParams;
  }

  void _checkArguments(FunctionNode function) {
    // When checking arguments of a forwarding stub, we need to use parameter
    // types (and bounds of type parameters) from stub's target.
    // These more accurate type checks is the sole purpose of a forwarding stub.
    final forwardingTarget = _getForwardingStubSuperTarget();
    final forwardingSubstitution =
        _getForwardingSubstitution(function, forwardingTarget);
    final forwardingBounds = _getForwardingBounds(
        function, forwardingTarget, forwardingSubstitution);
    final forwardingParamTypes = _getForwardingParameterTypes(
        function, forwardingTarget, forwardingSubstitution);

    if (_hasSkippableTypeChecks(
        function, forwardingBounds, forwardingParamTypes)) {
      final Label skipChecks = new Label();
      asm.emitJumpIfUnchecked(skipChecks);

      // We can skip bounds checks of type parameter and type checks of
      // non-covariant parameters if function is called via unchecked call.

      for (var typeParam in function.typeParameters) {
        if (_typeParameterNeedsBoundCheck(typeParam, forwardingBounds)) {
          _genTypeParameterBoundCheck(typeParam, forwardingBounds);
        }
      }
      for (var param in function.positionalParameters) {
        if (!param.isCovariant &&
            _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
          _genArgumentTypeCheck(param, forwardingParamTypes);
        }
      }
      for (var param in locals.sortedNamedParameters) {
        if (!param.isCovariant &&
            _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
          _genArgumentTypeCheck(param, forwardingParamTypes);
        }
      }

      asm.bind(skipChecks);
    }

    // Covariant parameters need to be checked even if function is called
    // via unchecked call, so they are generated outside of JumpIfUnchecked.

    for (var param in function.positionalParameters) {
      if (param.isCovariant &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        _genArgumentTypeCheck(param, forwardingParamTypes);
      }
    }
    for (var param in locals.sortedNamedParameters) {
      if (param.isCovariant &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        _genArgumentTypeCheck(param, forwardingParamTypes);
      }
    }
  }

  /// Returns true if bound of [typeParam] should be checked.
  bool _typeParameterNeedsBoundCheck(TypeParameter typeParam,
      Map<TypeParameter, DartType> forwardingTypeParameterBounds) {
    if (canSkipTypeChecksForNonCovariantArguments &&
        (!typeParam.isGenericCovariantImpl ||
            skipTypeChecksForGenericCovariantImplArguments)) {
      return false;
    }
    final DartType bound = (forwardingTypeParameterBounds != null)
        ? forwardingTypeParameterBounds[typeParam]
        : typeParam.bound;
    if (typeEnvironment.isTop(bound)) {
      return false;
    }
    return true;
  }

  /// Returns true if type of [param] should be checked.
  bool _parameterNeedsTypeCheck(VariableDeclaration param,
      Map<VariableDeclaration, DartType> forwardingParameterTypes) {
    if (canSkipTypeChecksForNonCovariantArguments &&
        !param.isCovariant &&
        (!param.isGenericCovariantImpl ||
            skipTypeChecksForGenericCovariantImplArguments)) {
      return false;
    }
    final DartType type = (forwardingParameterTypes != null)
        ? forwardingParameterTypes[param]
        : param.type;
    if (typeEnvironment.isTop(type)) {
      return false;
    }
    return true;
  }

  /// Returns true if there are parameter type/bound checks which can
  /// be skipped on unchecked call.
  bool _hasSkippableTypeChecks(
      FunctionNode function,
      Map<TypeParameter, DartType> forwardingBounds,
      Map<VariableDeclaration, DartType> forwardingParamTypes) {
    for (var typeParam in function.typeParameters) {
      if (_typeParameterNeedsBoundCheck(typeParam, forwardingBounds)) {
        return true;
      }
    }
    for (var param in function.positionalParameters) {
      if (!param.isCovariant &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        return true;
      }
    }
    for (var param in locals.sortedNamedParameters) {
      if (!param.isCovariant &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        return true;
      }
    }
    return false;
  }

  void _genTypeParameterBoundCheck(TypeParameter typeParam,
      Map<TypeParameter, DartType> forwardingTypeParameterBounds) {
    final DartType bound = (forwardingTypeParameterBounds != null)
        ? forwardingTypeParameterBounds[typeParam]
        : typeParam.bound;
    final DartType type = new TypeParameterType(typeParam, Nullability.legacy);
    _genPushInstantiatorAndFunctionTypeArguments([type, bound]);
    asm.emitPushConstant(cp.addType(type));
    asm.emitPushConstant(cp.addType(bound));
    asm.emitPushConstant(cp.addName(typeParam.name));
    asm.emitAssertSubtype();
  }

  void _genArgumentTypeCheck(VariableDeclaration variable,
      Map<VariableDeclaration, DartType> forwardingParameterTypes) {
    final DartType type = (forwardingParameterTypes != null)
        ? forwardingParameterTypes[variable]
        : variable.type;
    if (locals.isCaptured(variable)) {
      asm.emitPush(locals.getOriginalParamSlotIndex(variable));
    } else {
      asm.emitPush(locals.getVarIndexInFrame(variable));
    }
    _genAssertAssignable(type, name: variable.name);
    asm.emitDrop1();
  }

  void _genAssertAssignable(DartType type, {String name, String message}) {
    assert(!typeEnvironment.isTop(type));
    asm.emitPushConstant(cp.addType(type));
    _genPushInstantiatorAndFunctionTypeArguments([type]);
    asm.emitPushConstant(
        name != null ? cp.addName(name) : cp.addString(message));
    bool isIntOk = typeEnvironment.isSubtypeOf(
        typeEnvironment.coreTypes.intLegacyRawType,
        type,
        SubtypeCheckMode.ignoringNullabilities);
    int subtypeTestCacheCpIndex = cp.addSubtypeTestCache();
    asm.emitAssertAssignable(isIntOk ? 1 : 0, subtypeTestCacheCpIndex);
  }

  void _pushAssemblerState() {
    savedAssemblers ??= <BytecodeAssembler>[];
    savedAssemblers.add(asm);
    asm = new BytecodeAssembler(options);
  }

  void _popAssemblerState() {
    asm = savedAssemblers.removeLast();
  }

  int _genClosureBytecode(
      LocalFunction node, String name, FunctionNode function) {
    _pushAssemblerState();

    locals.enterScope(node);

    final savedParentFunction = parentFunction;
    parentFunction = enclosingFunction;
    final savedIsClosure = isClosure;
    isClosure = true;
    enclosingFunction = function;
    final savedLoopDepth = currentLoopDepth;
    currentLoopDepth = 0;
    final savedInferredTypesAttribute = inferredTypesAttribute;
    inferredTypesAttribute = null;

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters ??= new List<TypeParameter>();
      functionTypeParameters.addAll(function.typeParameters);
      functionTypeParametersSet = functionTypeParameters.toSet();
    }

    List<Label> savedYieldPoints = yieldPoints;
    yieldPoints = locals.isSyncYieldingFrame ? <Label>[] : null;

    closures ??= <ClosureDeclaration>[];
    final int closureIndex = closures.length;
    final closure = getClosureDeclaration(node, function, name, closureIndex,
        savedIsClosure ? parentFunction : enclosingMember);
    closures.add(closure);

    final int closureFunctionIndex = cp.addClosureFunction(closureIndex);

    _recordSourcePosition(function.fileOffset);
    _genPrologue(node, function);

    if (options.causalAsyncStacks &&
        parentFunction != null &&
        (parentFunction.dartAsyncMarker == AsyncMarker.Async ||
            parentFunction.dartAsyncMarker == AsyncMarker.AsyncStar)) {
      final savedSourcePosition = asm.currentSourcePosition;
      _recordSourcePosition(TreeNode.noOffset);
      _genLoadVar(locals.asyncStackTraceVar,
          currentContextLevel: locals.contextLevelAtEntry);
      _genDirectCall(
          setAsyncThreadStackTrace, objectTable.getArgDescHandle(1), 1);
      asm.emitDrop1();
      asm.currentSourcePosition = savedSourcePosition;
    }

    Label continuationSwitchLabel;
    int continuationSwitchVar;
    if (locals.isSyncYieldingFrame) {
      continuationSwitchLabel = new Label();
      continuationSwitchVar = locals.scratchVarIndexInFrame;
      _genSyncYieldingPrologue(
          function, continuationSwitchLabel, continuationSwitchVar);
    } else {
      _setupInitialContext(function);
      _emitFirstDebugCheck(function);
    }
    _checkArguments(function);

    _generateNode(function.body);

    // BytecodeAssembler eliminates this bytecode if it is unreachable.
    _recordSourcePosition(function.fileEndOffset);
    asm.emitPushNull();
    _genReturnTOS();

    if (locals.isSyncYieldingFrame) {
      _genSyncYieldingEpilogue(
          function, continuationSwitchLabel, continuationSwitchVar);
    }

    if (options.emitLocalVarInfo) {
      // Leave the scopes which were entered in _genPrologue and
      // _setupInitialContext.
      asm.localVariableTable.leaveAllScopes(asm.offset, function.fileEndOffset);
    }

    cp.addEndClosureFunctionScope();

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters.length -= function.typeParameters.length;
      functionTypeParametersSet = functionTypeParameters.toSet();
    }

    enclosingFunction = parentFunction;
    parentFunction = savedParentFunction;
    isClosure = savedIsClosure;
    currentLoopDepth = savedLoopDepth;

    final attributes = getClosureAttributes();
    if (attributes != null) {
      closure.attributes = attributes;
      closure.flags |= ClosureDeclaration.hasAttributesFlag;
    }
    inferredTypesAttribute = savedInferredTypesAttribute;

    locals.leaveScope();

    closure.code = new ClosureCode(asm.bytecode, asm.exceptionsTable,
        finalizeSourcePositions(), finalizeLocalVariables());

    _popAssemblerState();
    yieldPoints = savedYieldPoints;

    return closureFunctionIndex;
  }

  ClosureDeclaration getClosureDeclaration(LocalFunction node,
      FunctionNode function, String name, int closureIndex, TreeNode parent) {
    objectTable.declareClosure(function, enclosingMember, closureIndex);

    int flags = 0;
    int position = TreeNode.noOffset;
    int endPosition = TreeNode.noOffset;
    if (options.emitSourcePositions) {
      position = (node is ast.FunctionDeclaration)
          ? node.fileOffset
          : function.fileOffset;
      endPosition = function.fileEndOffset;
      if (position != TreeNode.noOffset) {
        flags |= ClosureDeclaration.hasSourcePositionsFlag;
      }
    }

    switch (function.dartAsyncMarker) {
      case AsyncMarker.Async:
        flags |= ClosureDeclaration.isAsyncFlag;
        break;
      case AsyncMarker.AsyncStar:
        flags |= ClosureDeclaration.isAsyncStarFlag;
        break;
      case AsyncMarker.SyncStar:
        flags |= ClosureDeclaration.isSyncStarFlag;
        break;
      default:
        flags |= ClosureDeclaration.isDebuggableFlag;
        break;
    }

    final List<NameAndType> parameters = <NameAndType>[];
    for (var v in function.positionalParameters) {
      parameters.add(new NameAndType(objectTable.getPublicNameHandle(v.name),
          objectTable.getHandle(v.type)));
    }
    for (var v in function.namedParameters) {
      parameters.add(new NameAndType(objectTable.getPublicNameHandle(v.name),
          objectTable.getHandle(v.type)));
    }
    if (function.requiredParameterCount != parameters.length) {
      if (function.namedParameters.isNotEmpty) {
        flags |= ClosureDeclaration.hasOptionalNamedParamsFlag;
      } else {
        flags |= ClosureDeclaration.hasOptionalPositionalParamsFlag;
      }
    }

    final typeParams =
        objectTable.getTypeParameterHandles(function.typeParameters);
    if (typeParams.isNotEmpty) {
      flags |= ClosureDeclaration.hasTypeParamsFlag;
    }

    final List<int> parameterFlags = getParameterFlags(function);
    if (parameterFlags != null) {
      flags |= ClosureDeclaration.hasParameterFlagsFlag;
    }

    return new ClosureDeclaration(
        flags,
        objectTable.getHandle(parent),
        objectTable.getPublicNameHandle(name),
        position,
        endPosition,
        typeParams,
        function.requiredParameterCount,
        function.namedParameters.length,
        parameters,
        parameterFlags,
        objectTable.getHandle(function.returnType));
  }

  void _genSyncYieldingPrologue(FunctionNode function, Label continuationLabel,
      int switchVarIndexInFrame) {
    Label debugCheckLabel = new Label();

    // switch_var = :await_jump_var
    _genLoadVar(locals.awaitJumpVar);
    asm.emitStoreLocal(switchVarIndexInFrame);

    _genPushInt(0);

    if (options.emitDebuggerStops) {
      // if (switch_var != 0) goto debugCheckLabel
      asm.emitJumpIfNeStrict(debugCheckLabel);

      _setupInitialContext(function);

      asm.bind(debugCheckLabel);
      // The debugger may set a breakpoint on this DebugCheck opcode and it
      // expects to hit it on the first entry to the async op, as well as on
      // each subsequent reentry.
      _emitFirstDebugCheck(function);

      _genLoadVar(locals.awaitJumpVar);

      // if (switch_var != 0) goto continuationLabel
      _genPushInt(0);
      asm.emitJumpIfNeStrict(continuationLabel);
    } else {
      // if (switch_var != 0) goto continuationLabel
      asm.emitJumpIfNeStrict(continuationLabel);

      _setupInitialContext(function);
    }

    // Proceed to normal entry.
  }

  void _genSyncYieldingEpilogue(FunctionNode function, Label continuationLabel,
      int switchVarIndexInFrame) {
    asm.bind(continuationLabel);

    if (yieldPoints.isEmpty) {
      asm.emitTrap();
      return;
    }

    // context = :await_ctx_var
    _genLoadVar(locals.awaitContextVar);
    asm.emitPopLocal(locals.contextVarIndexInFrame);

    for (int i = 0; i < yieldPoints.length; i++) {
      // 0 is reserved for normal entry, yield points are counted from 1.
      final int index = i + 1;

      // if (switch_var == #index) goto yieldPoints[i]
      // There is no need to test switch_var for the last yield statement.
      if (i != yieldPoints.length - 1) {
        asm.emitPush(switchVarIndexInFrame);
        _genPushInt(index);
        asm.emitJumpIfEqStrict(yieldPoints[i]);
      } else {
        asm.emitJump(yieldPoints[i]);
      }
    }
  }

  void _genAllocateClosureInstance(
      TreeNode node, int closureFunctionIndex, FunctionNode function) {
    asm.emitAllocateClosure(closureFunctionIndex);

    final int temp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(temp);

    // TODO(alexmarkov): We need to fill _instantiator_type_arguments field
    // only if function signature uses instantiator type arguments.
    asm.emitPush(temp);
    _genPushInstantiatorTypeArguments();
    asm.emitStoreFieldTOS(
        cp.addInstanceField(closureInstantiatorTypeArguments));

    asm.emitPush(temp);
    _genPushFunctionTypeArguments();
    asm.emitStoreFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));

    // Delayed type arguments are only used by generic closures.
    if (function.typeParameters.isNotEmpty) {
      asm.emitPush(temp);
      asm.emitPushConstant(cp.addEmptyTypeArguments());
      asm.emitStoreFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));
    }

    asm.emitPush(temp);
    asm.emitPushConstant(closureFunctionIndex);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureFunction));

    asm.emitPush(temp);
    asm.emitPush(locals.contextVarIndexInFrame);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureContext));
  }

  void _genClosure(LocalFunction node, String name, FunctionNode function) {
    final int closureFunctionIndex = _genClosureBytecode(node, name, function);
    _genAllocateClosureInstance(node, closureFunctionIndex, function);
  }

  void _allocateContextIfNeeded() {
    final int contextSize = locals.currentContextSize;
    if (contextSize > 0) {
      asm.emitAllocateContext(locals.currentContextId, contextSize);

      if (locals.currentContextLevel > 0) {
        _genDupTOS(locals.scratchVarIndexInFrame);
        asm.emitPush(locals.contextVarIndexInFrame);
        asm.emitStoreContextParent();
      }

      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }
  }

  void _enterScope(TreeNode node) {
    locals.enterScope(node);
    _allocateContextIfNeeded();
    if (options.emitLocalVarInfo) {
      asm.localVariableTable
          .enterScope(asm.offset, locals.currentContextLevel, node.fileOffset);
      _startRecordingMaxPosition(node.fileOffset);
    }
  }

  void _leaveScope() {
    if (options.emitLocalVarInfo) {
      asm.localVariableTable.leaveScope(asm.offset, _endRecordingMaxPosition());
    }
    if (locals.currentContextSize > 0) {
      _genUnwindContext(locals.currentContextLevel - 1);
    }
    locals.leaveScope();
  }

  void _startRecordingMaxPosition(int fileOffset) {
    savedMaxSourcePositions.add(maxSourcePosition);
    maxSourcePosition = fileOffset;
  }

  int _endRecordingMaxPosition() {
    int localMax = maxSourcePosition;
    maxSourcePosition =
        math.max(localMax, savedMaxSourcePositions.removeLast());
    return localMax;
  }

  void _genUnwindContext(int targetContextLevel) {
    int currentContextLevel = locals.currentContextLevel;
    assert(currentContextLevel >= targetContextLevel);
    while (currentContextLevel > targetContextLevel) {
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitLoadContextParent();
      asm.emitPopLocal(locals.contextVarIndexInFrame);
      --currentContextLevel;
    }
  }

  /// Returns the list of try-finally blocks between [from] and [to],
  /// ordered from inner to outer. If [to] is null, returns all enclosing
  /// try-finally blocks up to the function boundary.
  List<TryFinally> _getEnclosingTryFinallyBlocks(TreeNode from, TreeNode to) {
    List<TryFinally> blocks = <TryFinally>[];
    TreeNode node = from;
    for (;;) {
      if (node == to) {
        return blocks;
      }
      if (node == null || node is FunctionNode || node is Member) {
        if (to == null) {
          return blocks;
        } else {
          throw 'Unable to find node $to up from $from';
        }
      }
      // Inspect parent as we only need try-finally blocks enclosing [node]
      // in the body, and not in the finally-block.
      final parent = node.parent;
      if (parent is TryFinally && parent.body == node) {
        blocks.add(parent);
      }
      node = parent;
    }
  }

  /// Appends chained [FinallyBlock]s to each try-finally in the given
  /// list [tryFinallyBlocks] (ordered from inner to outer).
  /// [continuation] is invoked to generate control transfer code following
  /// the last finally block.
  void _addFinallyBlocks(
      List<TryFinally> tryFinallyBlocks, GenerateContinuation continuation) {
    // Add finally blocks to all try-finally from outer to inner.
    // The outermost finally block should generate continuation, each inner
    // finally block should proceed to a corresponding outer block.
    for (var tryFinally in tryFinallyBlocks.reversed) {
      final finallyBlock = new FinallyBlock(continuation);
      finallyBlocks[tryFinally].add(finallyBlock);

      final Label nextFinally = finallyBlock.entry;
      continuation = () {
        asm.emitJump(nextFinally);
      };
    }

    // Generate jump to the innermost finally (or to the original
    // continuation if there are no try-finally blocks).
    continuation();
  }

  /// Generates non-local transfer from inner node [from] into the outer
  /// node, executing finally blocks on the way out. [to] can be null,
  /// in such case all enclosing finally blocks are executed.
  /// [continuation] is invoked to generate control transfer code following
  /// the last finally block.
  void _generateNonLocalControlTransfer(
      TreeNode from, TreeNode to, GenerateContinuation continuation) {
    if (options.emitDebuggerStops && from.fileOffset != TreeNode.noOffset) {
      asm.emitDebugCheck(); // Before context is unwound.
    }
    List<TryFinally> tryFinallyBlocks = _getEnclosingTryFinallyBlocks(from, to);
    _addFinallyBlocks(tryFinallyBlocks, continuation);
  }

  // For certain expressions wrapped into ExpressionStatement we can
  // omit pushing result on the stack.
  bool isExpressionWithoutResult(Expression expr) =>
      expr.parent is ExpressionStatement &&
      (expr is VariableSet ||
          expr is PropertySet ||
          expr is StaticSet ||
          expr is SuperPropertySet ||
          expr is DirectPropertySet);

  void _createArgumentsArray(int temp, List<DartType> typeArgs,
      List<Expression> args, bool storeLastArgumentToTemp) {
    final int totalCount = (typeArgs.isNotEmpty ? 1 : 0) + args.length;

    _genTypeArguments([const DynamicType()]);
    _genPushInt(totalCount);
    asm.emitCreateArrayTOS();

    asm.emitStoreLocal(temp);

    int index = 0;
    if (typeArgs.isNotEmpty) {
      asm.emitPush(temp);
      _genPushInt(index++);
      _genTypeArguments(typeArgs);
      asm.emitStoreIndexedTOS();
    }

    for (Expression arg in args) {
      asm.emitPush(temp);
      _genPushInt(index++);
      _generateNode(arg);
      if (storeLastArgumentToTemp && index == totalCount) {
        // Arguments array in 'temp' is replaced with the last argument
        // in order to return result of RHS value in case of setter.
        asm.emitStoreLocal(temp);
      }
      asm.emitStoreIndexedTOS();
    }
  }

  void _genNoSuchMethodForSuperCall(String name, int temp, int argDescCpIndex,
      List<DartType> typeArgs, List<Expression> args,
      {bool storeLastArgumentToTemp: false}) {
    // Receiver for noSuchMethod() call.
    _genPushReceiver();

    // Argument 0 for _allocateInvocationMirror(): function name.
    asm.emitPushConstant(cp.addName(name));

    // Argument 1 for _allocateInvocationMirror(): arguments descriptor.
    asm.emitPushConstant(argDescCpIndex);

    // Argument 2 for _allocateInvocationMirror(): list of arguments.
    _createArgumentsArray(temp, typeArgs, args, storeLastArgumentToTemp);

    // Argument 3 for _allocateInvocationMirror(): isSuperInvocation flag.
    asm.emitPushTrue();

    _genDirectCall(
        allocateInvocationMirror, objectTable.getArgDescHandle(4), 4);

    final Member target = hierarchy.getDispatchTarget(
        enclosingClass.superclass, noSuchMethodName);
    assert(target != null);
    _genDirectCall(target, objectTable.getArgDescHandle(2), 2);
  }

  @override
  defaultTreeNode(Node node) => throw new UnsupportedOperationError(
      'Unsupported node ${node.runtimeType}');

  @override
  visitAsExpression(AsExpression node) {
    _generateNode(node.operand);

    final type = node.type;
    if (typeEnvironment.isTop(type)) {
      return;
    }

    _genAssertAssignable(type,
        message: node.isTypeError ? '' : symbolForTypeCast);
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    _genPushBool(node.value);
  }

  @override
  visitIntLiteral(IntLiteral node) {
    _genPushInt(node.value);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    final cpIndex = cp.addObjectRef(new DoubleConstant(node.value));
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    final Label otherwisePart = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);

    _genConditionAndJumpIf(node.condition, false, otherwisePart);

    _generateNode(node.then);
    asm.emitPopLocal(temp);
    asm.emitJump(done);

    asm.bind(otherwisePart);
    _generateNode(node.otherwise);
    asm.emitPopLocal(temp);

    asm.bind(done);
    asm.emitPush(temp);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }

    final constructedClass = node.constructedType.classNode;
    final classIndex = cp.addClass(constructedClass);

    if (hasInstantiatorTypeArguments(constructedClass)) {
      _genTypeArguments(node.arguments.types,
          instantiatingClass: constructedClass);
      asm.emitPushConstant(cp.addClass(constructedClass));
      asm.emitAllocateT();
    } else {
      assert(node.arguments.types.isEmpty);
      asm.emitAllocate(classIndex);
    }

    _genDupTOS(locals.tempIndexInFrame(node));

    // Remove type arguments as they are only passed to instance allocation,
    // and not passed to a constructor.
    final args =
        new Arguments(node.arguments.positional, named: node.arguments.named)
          ..parent = node;
    _genArguments(null, args);
    _genDirectCallWithArgs(node.target, args, hasReceiver: true, node: node);
    asm.emitDrop1();
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    final args = node.arguments;
    _genArguments(node.receiver, args);
    final target = node.target;
    if (target is Procedure && !target.isGetter && !target.isSetter) {
      _genDirectCallWithArgs(target, args, hasReceiver: true, node: node);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported DirectMethodInvocation with target ${target.runtimeType} $target');
    }
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    _generateNode(node.receiver);
    final target = node.target;
    if (target is Field || (target is Procedure && target.isGetter)) {
      _genDirectCall(target, objectTable.getArgDescHandle(1), 1,
          isGet: true, node: node);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported DirectPropertyGet with ${target.runtimeType} $target');
    }
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(node.receiver);
    _generateNode(node.value);

    if (hasResult) {
      asm.emitStoreLocal(temp);
    }

    final target = node.target;
    assert(target is Field || (target is Procedure && target.isSetter));
    _genDirectCall(target, objectTable.getArgDescHandle(2), 2,
        isSet: true, node: node);
    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _genClosure(node, '<anonymous closure>', node.function);
  }

  @override
  visitInstantiation(Instantiation node) {
    final int oldClosure = locals.tempIndexInFrame(node, tempIndex: 0);
    final int newClosure = locals.tempIndexInFrame(node, tempIndex: 1);
    final int typeArguments = locals.tempIndexInFrame(node, tempIndex: 2);

    _generateNode(node.expression);
    asm.emitStoreLocal(oldClosure);

    _genTypeArguments(node.typeArguments);
    asm.emitStoreLocal(typeArguments);

    _genDirectCall(
        boundsCheckForPartialInstantiation, objectTable.getArgDescHandle(2), 2);
    asm.emitDrop1();

    assert(closureClass.typeParameters.isEmpty);
    asm.emitAllocate(cp.addClass(closureClass));
    asm.emitStoreLocal(newClosure);

    asm.emitPush(typeArguments);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));

    // Copy the rest of the fields from old closure to a new closure.
    final fieldsToCopy = <Field>[
      closureInstantiatorTypeArguments,
      closureFunctionTypeArguments,
      closureFunction,
      closureContext,
    ];

    for (Field field in fieldsToCopy) {
      final fieldOffsetCpIndex = cp.addInstanceField(field);
      asm.emitPush(newClosure);
      asm.emitPush(oldClosure);
      asm.emitLoadFieldTOS(fieldOffsetCpIndex);
      asm.emitStoreFieldTOS(fieldOffsetCpIndex);
    }

    asm.emitPush(newClosure);
  }

  @override
  visitIsExpression(IsExpression node) {
    _generateNode(node.operand);
    _genInstanceOf(node.type);
  }

  @override
  visitLet(Let node) {
    _enterScope(node);
    _generateNode(node.variable);
    _generateNode(node.body);
    _leaveScope();
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }

    _genTypeArguments([node.typeArgument]);

    if (node.expressions.isEmpty) {
      asm.emitPushConstant(
          cp.addObjectRef(new ListConstant(const DynamicType(), const [])));
    } else {
      _genDupTOS(locals.tempIndexInFrame(node));
      _genPushInt(node.expressions.length);
      asm.emitCreateArrayTOS();
      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      for (int i = 0; i < node.expressions.length; i++) {
        asm.emitPush(temp);
        _genPushInt(i);
        _generateNode(node.expressions[i]);
        asm.emitStoreIndexedTOS();
      }
    }

    // List._fromLiteral is a factory constructor.
    // Type arguments passed to a factory constructor are counted as a normal
    // argument and not counted in number of type arguments.
    assert(listFromLiteral.isFactory);
    _genDirectCall(listFromLiteral, objectTable.getArgDescHandle(2), 2);
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    assert(node.operator == '||' || node.operator == '&&');

    final Label shortCircuit = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);
    final isOR = (node.operator == '||');

    _genConditionAndJumpIf(node.left, isOR, shortCircuit);

    bool negated = _genCondition(node.right);
    if (negated) {
      asm.emitBooleanNegateTOS();
    }
    asm.emitPopLocal(temp);
    asm.emitJump(done);

    asm.bind(shortCircuit);
    _genPushBool(isOR);
    asm.emitPopLocal(temp);

    asm.bind(done);
    asm.emitPush(temp);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }

    _genTypeArguments([node.keyType, node.valueType]);

    if (node.entries.isEmpty) {
      asm.emitPushConstant(
          cp.addObjectRef(new ListConstant(const DynamicType(), const [])));
    } else {
      _genTypeArguments([const DynamicType()]);
      _genPushInt(node.entries.length * 2);
      asm.emitCreateArrayTOS();

      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      for (int i = 0; i < node.entries.length; i++) {
        // key
        asm.emitPush(temp);
        _genPushInt(i * 2);
        _generateNode(node.entries[i].key);
        asm.emitStoreIndexedTOS();
        // value
        asm.emitPush(temp);
        _genPushInt(i * 2 + 1);
        _generateNode(node.entries[i].value);
        asm.emitStoreIndexedTOS();
      }
    }

    // Map._fromLiteral is a factory constructor.
    // Type arguments passed to a factory constructor are counted as a normal
    // argument and not counted in number of type arguments.
    assert(mapFromLiteral.isFactory);
    _genDirectCall(mapFromLiteral, objectTable.getArgDescHandle(2), 2);
  }

  void _genMethodInvocationUsingSpecializedBytecode(
      Opcode opcode, MethodInvocation node) {
    switch (opcode) {
      case Opcode.kEqualsNull:
        if (node.receiver is NullLiteral) {
          _generateNode(node.arguments.positional.single);
        } else {
          _generateNode(node.receiver);
        }
        break;

      case Opcode.kNegateInt:
      case Opcode.kNegateDouble:
        _generateNode(node.receiver);
        break;

      case Opcode.kAddInt:
      case Opcode.kSubInt:
      case Opcode.kMulInt:
      case Opcode.kTruncDivInt:
      case Opcode.kModInt:
      case Opcode.kBitAndInt:
      case Opcode.kBitOrInt:
      case Opcode.kBitXorInt:
      case Opcode.kShlInt:
      case Opcode.kShrInt:
      case Opcode.kCompareIntEq:
      case Opcode.kCompareIntGt:
      case Opcode.kCompareIntLt:
      case Opcode.kCompareIntGe:
      case Opcode.kCompareIntLe:
      case Opcode.kAddDouble:
      case Opcode.kSubDouble:
      case Opcode.kMulDouble:
      case Opcode.kDivDouble:
      case Opcode.kCompareDoubleEq:
      case Opcode.kCompareDoubleGt:
      case Opcode.kCompareDoubleLt:
      case Opcode.kCompareDoubleGe:
      case Opcode.kCompareDoubleLe:
        _generateNode(node.receiver);
        _generateNode(node.arguments.positional.single);
        break;

      default:
        throw 'Unexpected specialized bytecode $opcode';
    }

    asm.emitSpecializedBytecode(opcode);
  }

  bool _isUncheckedCall(
          Node node, Member interfaceTarget, Expression receiver) =>
      isUncheckedCall(interfaceTarget, receiver, staticTypeContext) ||
      (inferredTypeMetadata != null &&
          inferredTypeMetadata[node]?.skipCheck == true);

  void _genInstanceCall(
      Node node,
      InvocationKind invocationKind,
      Member interfaceTarget,
      Name targetName,
      Expression receiver,
      int totalArgCount,
      ObjectHandle argDesc) {
    final isDynamic = interfaceTarget == null;
    final isUnchecked = invocationKind != InvocationKind.getter &&
        _isUncheckedCall(node, interfaceTarget, receiver);

    if (inferredTypeMetadata != null && node != null) {
      _appendInferredType(node, asm.offset);
    }

    bool generated = false;
    if (invocationKind != InvocationKind.getter && !isDynamic && !isUnchecked) {
      final staticReceiverType = getStaticType(receiver, staticTypeContext);
      if (isInstantiatedInterfaceCall(interfaceTarget, staticReceiverType)) {
        final callCpIndex = cp.addInstantiatedInterfaceCall(
            invocationKind, interfaceTarget, argDesc, staticReceiverType);
        asm.emitInstantiatedInterfaceCall(callCpIndex, totalArgCount);
        generated = true;
      }
    }

    if (!generated) {
      final callCpIndex = cp.addInstanceCall(
          invocationKind, interfaceTarget, targetName, argDesc);
      if (isDynamic) {
        assert(!isUnchecked);
        asm.emitDynamicCall(callCpIndex, totalArgCount);
      } else if (isUnchecked) {
        asm.emitUncheckedInterfaceCall(callCpIndex, totalArgCount);
      } else {
        asm.emitInterfaceCall(callCpIndex, totalArgCount);
      }
    }

    if (inferredTypeMetadata != null && node != null) {
      _replaceWithConstantValue(node);
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    final directCall =
        directCallMetadata != null ? directCallMetadata[node] : null;
    final Opcode opcode = recognizedMethods.specializedBytecodeFor(node);
    if (opcode != null && directCall == null) {
      _genMethodInvocationUsingSpecializedBytecode(opcode, node);
      return;
    }
    final args = node.arguments;
    final totalArgCount = args.positional.length +
        args.named.length +
        1 /* receiver */ +
        (args.types.isNotEmpty ? 1 : 0) /* type arguments */;
    if (totalArgCount >= argumentsLimit) {
      throw new TooManyArgumentsException(node.fileOffset);
    }
    // Front-end guarantees that all calls with known function type
    // do not need any argument type checks.
    if (isUncheckedClosureCall(node, staticTypeContext, options)) {
      final int receiverTemp = locals.tempIndexInFrame(node);
      _genArguments(node.receiver, args, storeReceiverToLocal: receiverTemp);
      // Duplicate receiver (closure) for UncheckedClosureCall.
      asm.emitPush(receiverTemp);
      final argDescCpIndex = cp.addArgDescByArguments(args, hasReceiver: true);
      asm.emitUncheckedClosureCall(argDescCpIndex, totalArgCount);
      return;
    }

    final Member interfaceTarget = node.interfaceTarget;
    if (!(interfaceTarget == null ||
        interfaceTarget is Procedure && !interfaceTarget.isGetter)) {
      throw new UnsupportedOperationError(
          'Unsupported MethodInvocation with interface target ${interfaceTarget.runtimeType} $interfaceTarget');
    }

    if (directCall != null && directCall.checkReceiverForNull) {
      final int receiverTemp = locals.tempIndexInFrame(node);
      _genArguments(node.receiver, args, storeReceiverToLocal: receiverTemp);
      asm.emitPush(receiverTemp);
      asm.emitNullCheck(cp.addSelectorName(node.name, InvocationKind.method));
    } else {
      _genArguments(node.receiver, args);
    }

    final argDesc =
        objectTable.getArgDescHandleByArguments(args, hasReceiver: true);

    if (directCall != null) {
      final isDynamicForwarder = (interfaceTarget == null);
      final isUnchecked =
          _isUncheckedCall(node, interfaceTarget, node.receiver);
      _genDirectCall(directCall.target, argDesc, totalArgCount,
          isDynamicForwarder: isDynamicForwarder,
          isUnchecked: isUnchecked,
          node: node);
    } else {
      _genInstanceCall(node, InvocationKind.method, interfaceTarget, node.name,
          node.receiver, totalArgCount, argDesc);
    }
  }

  @override
  visitPropertyGet(PropertyGet node) {
    _generateNode(node.receiver);
    final argDesc = objectTable.getArgDescHandle(1);

    final directCall =
        directCallMetadata != null ? directCallMetadata[node] : null;
    if (directCall != null) {
      if (directCall.checkReceiverForNull) {
        final int receiverTemp = locals.tempIndexInFrame(node);
        asm.emitStoreLocal(receiverTemp);
        asm.emitPush(receiverTemp);
        asm.emitNullCheck(cp.addSelectorName(node.name, InvocationKind.getter));
      }
      _genDirectCall(directCall.target, argDesc, 1, isGet: true, node: node);
    } else {
      _genInstanceCall(node, InvocationKind.getter, node.interfaceTarget,
          node.name, node.receiver, 1, argDesc);
    }
  }

  @override
  visitPropertySet(PropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(node.receiver);

    final directCall =
        directCallMetadata != null ? directCallMetadata[node] : null;
    if (directCall != null && directCall.checkReceiverForNull) {
      asm.emitStoreLocal(temp);
      _generateNode(node.value);
      asm.emitPush(temp);
      asm.emitNullCheck(cp.addSelectorName(node.name, InvocationKind.setter));
    } else {
      _generateNode(node.value);
    }

    if (hasResult) {
      asm.emitStoreLocal(temp);
    }

    const int numArguments = 2;
    final argDesc = objectTable.getArgDescHandle(numArguments);

    if (directCall != null) {
      final isDynamicForwarder = (node.interfaceTarget == null);
      final isUnchecked =
          _isUncheckedCall(node, node.interfaceTarget, node.receiver);
      _genDirectCall(directCall.target, argDesc, numArguments,
          isSet: true,
          isDynamicForwarder: isDynamicForwarder,
          isUnchecked: isUnchecked,
          node: node);
    } else {
      _genInstanceCall(node, InvocationKind.setter, node.interfaceTarget,
          node.name, node.receiver, numArguments, argDesc);
    }

    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    final args = node.arguments;
    final Member target =
        hierarchy.getDispatchTarget(enclosingClass.superclass, node.name);
    if (target == null) {
      final int temp = locals.tempIndexInFrame(node);
      _genNoSuchMethodForSuperCall(
          node.name.name,
          temp,
          cp.addArgDescByArguments(args, hasReceiver: true),
          args.types,
          <Expression>[new ThisExpression()]
            ..addAll(args.positional)
            ..addAll(args.named.map((x) => x.value)));
      return;
    }
    if (!(target is Procedure && !target.isGetter)) {
      throw new UnsupportedOperationError(
          'Unsupported SuperMethodInvocation with target ${target.runtimeType} $target');
    }
    _genArguments(new ThisExpression(), args);
    _genDirectCallWithArgs(target, args,
        hasReceiver: true, isUnchecked: true, node: node);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    final Member target =
        hierarchy.getDispatchTarget(enclosingClass.superclass, node.name);
    if (target == null) {
      final int temp = locals.tempIndexInFrame(node);
      _genNoSuchMethodForSuperCall(node.name.name, temp, cp.addArgDesc(1), [],
          <Expression>[new ThisExpression()]);
      return;
    }
    _genPushReceiver();
    _genDirectCall(target, objectTable.getArgDescHandle(1), 1,
        isGet: true, node: node);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    final Member target = hierarchy
        .getDispatchTarget(enclosingClass.superclass, node.name, setter: true);
    if (target == null) {
      _genNoSuchMethodForSuperCall(node.name.name, temp, cp.addArgDesc(2), [],
          <Expression>[new ThisExpression(), node.value],
          storeLastArgumentToTemp: hasResult);
    } else {
      _genPushReceiver();
      _generateNode(node.value);

      if (hasResult) {
        asm.emitStoreLocal(temp);
      }

      assert(target is Field || (target is Procedure && target.isSetter));
      _genDirectCall(target, objectTable.getArgDescHandle(2), 2,
          isSet: true, isUnchecked: true, node: node);
    }

    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  visitNot(Not node) {
    bool negated = _genCondition(node.operand);
    if (!negated) {
      asm.emitBooleanNegateTOS();
    }
  }

  @override
  visitNullCheck(NullCheck node) {
    _generateNode(node.operand);
    final operandTemp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(operandTemp);
    asm.emitPush(operandTemp);
    asm.emitNullCheck(cp.addObjectRef(null));
  }

  @override
  visitNullLiteral(NullLiteral node) {
    asm.emitPushNull();
  }

  @override
  visitRethrow(Rethrow node) {
    TryCatch tryCatch;
    for (var parent = node.parent;; parent = parent.parent) {
      if (parent is Catch) {
        tryCatch = parent.parent as TryCatch;
        break;
      }
      if (parent == null || parent is FunctionNode) {
        throw 'Unable to find enclosing catch for $node';
      }
    }
    tryCatches[tryCatch].needsStackTrace = true;

    if (options.emitDebuggerStops) {
      asm.emitDebugCheck(); // Allow breakpoint on explicit rethrow statement.
    }
    _genRethrow(tryCatch);
  }

  bool _hasNonTrivialInitializer(Field field) {
    if (field.initializer == null) return false;
    return !_isTrivialInitializer(field.initializer);
  }

  bool _isTrivialInitializer(Expression initializer) {
    if (initializer == null) return false;
    if (initializer is StringLiteral ||
        initializer is BoolLiteral ||
        initializer is IntLiteral ||
        initializer is DoubleLiteral ||
        initializer is NullLiteral) {
      return true;
    }
    if (initializer is ConstantExpression &&
        initializer.constant is PrimitiveConstant) {
      return true;
    }
    return false;
  }

  @override
  visitStaticGet(StaticGet node) {
    final target = node.target;
    if (target is Field) {
      if (target.isConst) {
        _genPushConstExpr(target.initializer);
      } else if (!_needsGetter(target)) {
        if (inferredTypeMetadata != null) {
          final InferredType md = inferredTypeMetadata[node];
          if (md != null && md.constantValue != null) {
            _genPushConstant(md.constantValue);
            return;
          }
        }
        asm.emitLoadStatic(cp.addStaticField(target));
      } else {
        _genDirectCall(target, objectTable.getArgDescHandle(0), 0,
            isGet: true, node: node);
      }
    } else if (target is Procedure) {
      if (target.isGetter) {
        _genDirectCall(target, objectTable.getArgDescHandle(0), 0,
            isGet: true, node: node);
      } else if (target.isFactory || target.isRedirectingFactoryConstructor) {
        throw 'Unexpected target for StaticGet: factory $target';
      } else {
        asm.emitPushConstant(cp.addObjectRef(new TearOffConstant(target)));
      }
    } else {
      throw 'Unexpected target for StaticGet: ${target.runtimeType} $target';
    }
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }
    Arguments args = node.arguments;
    final target = node.target;
    if (target == unsafeCast) {
      // The result of the unsafeCast() intrinsic method is its sole argument,
      // without any additional checks or type casts.
      assert(args.named.isEmpty);
      _generateNode(args.positional.single);
      return;
    }
    if (!options.causalAsyncStacks &&
        target == coreTypes.asyncStackTraceHelperProcedure) {
      // Eliminate calls to _asyncStackTraceHelper as causal async stacks are
      // disabled. These calls are inserted by async transformation
      // (pkg/kernel/lib/transformations/continuation.dart), but they should be
      // consistent with _setAsyncThreadStackTrace and
      // _clearAsyncThreadStackTrace calls generated by bytecode generator.
      //
      // Push null as _asyncStackTraceHelper call should leave result
      // on the stack.
      asm.emitPushNull();
      return;
    }
    if (target.isFactory) {
      final constructedClass = target.enclosingClass;
      if (hasInstantiatorTypeArguments(constructedClass)) {
        _genTypeArguments(args.types, instantiatingClass: constructedClass);
      } else {
        assert(args.types.isEmpty);
        // VM needs type arguments for every invocation of a factory
        // constructor. TODO(alexmarkov): Clean this up.
        asm.emitPushNull();
      }
      args =
          new Arguments(node.arguments.positional, named: node.arguments.named)
            ..parent = node;
    }
    _genArguments(null, args);
    _genDirectCallWithArgs(target, args,
        isFactory: target.isFactory, node: node);
  }

  @override
  visitStaticSet(StaticSet node) {
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(node.value);

    if (hasResult) {
      _genDupTOS(locals.tempIndexInFrame(node));
    }

    final target = node.target;
    if (target is Field && !_needsSetter(target)) {
      if (options.emitDebuggerStops &&
          _variableSetNeedsDebugCheck(node.value)) {
        asm.emitDebugCheck();
      }
      int cpIndex = cp.addStaticField(target);
      asm.emitStoreStaticTOS(cpIndex);
    } else {
      _genDirectCall(target, objectTable.getArgDescHandle(1), 1,
          isSet: true, node: node);
      asm.emitDrop1();
    }
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    if (node.expressions.length == 1) {
      _generateNode(node.expressions.single);
      _genDirectCall(interpolateSingle, objectTable.getArgDescHandle(1), 1);
    } else {
      asm.emitPushNull();
      _genPushInt(node.expressions.length);
      asm.emitCreateArrayTOS();

      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      for (int i = 0; i < node.expressions.length; i++) {
        asm.emitPush(temp);
        _genPushInt(i);
        _generateNode(node.expressions[i]);
        asm.emitStoreIndexedTOS();
      }

      _genDirectCall(interpolate, objectTable.getArgDescHandle(1), 1);
    }
  }

  @override
  visitStringLiteral(StringLiteral node) {
    final cpIndex = cp.addString(node.value);
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    _genPushConstExpr(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    _genPushReceiver();
  }

  @override
  visitThrow(Throw node) {
    _generateNode(node.expression);

    if (options.emitDebuggerStops) {
      asm.emitDebugCheck();
    }
    asm.emitThrow(0);
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    final DartType type = node.type;
    final int typeCPIndex = cp.addType(type);
    if (!hasFreeTypeParameters([type])) {
      asm.emitPushConstant(typeCPIndex);
    } else {
      _genPushInstantiatorAndFunctionTypeArguments([type]);
      asm.emitInstantiateType(typeCPIndex);
    }
  }

  @override
  visitVariableGet(VariableGet node) {
    final v = node.variable;
    if (v.isConst) {
      _genPushConstExpr(v.initializer);
    } else if (v.isLate) {
      _genLoadVar(v);

      final Label done = new Label();
      asm.emitJumpIfInitialized(done);

      if (v.initializer != null) {
        final init = v.initializer;
        _genPushContextIfCaptured(v);
        // Late local variable initializers are transformed to wrap the
        // initializer in a closure (see late_var_init_transformer.dart). The
        // closure call needs one temporary, so withTemp lets us use this
        // VariableGet's temporary when visiting the initializer.
        assert(init is MethodInvocation &&
            init.name.name == "call" &&
            init.arguments.positional.length == 0);
        locals.withTemp(
            init, locals.tempIndexInFrame(node), () => _generateNode(init));
        _genStoreVar(v);
      } else {
        asm.emitPushConstant(cp.addName(v.name));
        _genDirectCall(throwNewLateInitializationError,
            objectTable.getArgDescHandle(1), 1);
        asm.emitDrop1();
      }

      asm.bind(done);
      _genLoadVar(v);
    } else {
      _genLoadVar(v);
    }
  }

  @override
  visitVariableSet(VariableSet node) {
    final v = node.variable;
    final bool hasResult = !isExpressionWithoutResult(node);
    final bool isLateFinal = v.isLate && v.isFinal;

    if (!isLateFinal) {
      _genPushContextIfCaptured(v);
    }

    _generateNode(node.value);

    if (options.emitDebuggerStops && _variableSetNeedsDebugCheck(node.value)) {
      asm.emitDebugCheck();
    }

    if (isLateFinal) {
      final int temp = locals.tempIndexInFrame(node);
      asm.emitPopLocal(temp);

      final Label error = new Label();
      final Label done = new Label();
      _genLoadVar(v);
      asm.emitJumpIfInitialized(error);

      _genPushContextIfCaptured(v);
      asm.emitPush(temp);
      _genStoreVar(v);
      asm.emitJump(done);

      asm.bind(error);
      asm.emitPushConstant(cp.addName(v.name));
      _genDirectCall(
          throwNewLateInitializationError, objectTable.getArgDescHandle(1), 1);
      asm.emitDrop1();

      asm.bind(done);

      if (hasResult) {
        asm.emitPush(temp);
      }
    } else if (locals.isCaptured(v)) {
      final int temp = locals.tempIndexInFrame(node);
      if (hasResult) {
        asm.emitStoreLocal(temp);
      }

      _genStoreVar(v);

      if (hasResult) {
        asm.emitPush(temp);
      }
    } else {
      final int localIndex = locals.getVarIndexInFrame(v);
      if (hasResult) {
        asm.emitStoreLocal(localIndex);
      } else {
        asm.emitPopLocal(localIndex);
      }
    }
  }

  bool _variableSetNeedsDebugCheck(Expression rhs) =>
      rhs is BasicLiteral ||
      rhs is ConstantExpression ||
      rhs is StaticGet ||
      rhs is FunctionExpression ||
      rhs is VariableGet ||
      rhs is AsExpression;

  void _genFutureNull() {
    asm.emitPushNull();
    _genDirectCall(futureValue, objectTable.getArgDescHandle(1), 1);
  }

  @override
  visitLoadLibrary(LoadLibrary node) {
    _genFutureNull();
  }

  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    _genFutureNull();
  }

  @override
  visitAssertStatement(AssertStatement node) {
    if (!options.enableAsserts) {
      return;
    }

    final Label done = new Label();
    asm.emitJumpIfNoAsserts(done);

    _genConditionAndJumpIf(node.condition, true, done);

    _genPushInt(
        options.omitAssertSourcePositions ? 0 : node.conditionStartOffset);
    _genPushInt(
        options.omitAssertSourcePositions ? 0 : node.conditionEndOffset);

    if (node.message != null) {
      _generateNode(node.message);
    } else {
      asm.emitPushNull();
    }

    _genDirectCall(throwNewAssertionError, objectTable.getArgDescHandle(3), 3);
    asm.emitDrop1();

    asm.bind(done);
  }

  @override
  visitBlock(Block node) {
    _enterScope(node);
    _generateNodeList(node.statements);
    _leaveScope();
  }

  @override
  visitAssertBlock(AssertBlock node) {
    if (!options.enableAsserts) {
      return;
    }

    final Label done = new Label();
    asm.emitJumpIfNoAsserts(done);

    _enterScope(node);
    _generateNodeList(node.statements);
    _leaveScope();

    asm.bind(done);
  }

  @override
  visitBlockExpression(BlockExpression node) {
    _enterScope(node);
    _generateNodeList(node.body.statements);
    _generateNode(node.value);
    _leaveScope();
  }

  @override
  visitBreakStatement(BreakStatement node) {
    final targetLabel = labeledStatements[node.target] ??
        (throw 'Target label ${node.target} was not registered for break $node');
    final targetContextLevel = contextLevels[node.target];

    _generateNonLocalControlTransfer(node, node.target, () {
      _genUnwindContext(targetContextLevel);
      asm.emitJump(targetLabel);
    });
  }

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    final targetLabel = switchCases[node.target] ??
        (throw 'Target label ${node.target} was not registered for continue-switch $node');
    final targetContextLevel = contextLevels[node.target.parent];

    _generateNonLocalControlTransfer(node, node.target.parent, () {
      _genUnwindContext(targetContextLevel);
      asm.emitJump(targetLabel);
    });
  }

  @override
  visitDoStatement(DoStatement node) {
    if (asm.isUnreachable) {
      // Bail out before binding a label which allows backward jumps,
      // as it is not handled by local unreachable code elimination.
      return;
    }

    final Label join = new Label(allowsBackwardJumps: true);
    asm.bind(join);

    asm.emitCheckStack(++currentLoopDepth);

    _generateNode(node.body);

    _genConditionAndJumpIf(node.condition, true, join);

    --currentLoopDepth;
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
    // no-op
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    final expr = node.expression;
    _generateNode(expr);
    if (!isExpressionWithoutResult(expr)) {
      asm.emitDrop1();
    }
  }

  @override
  visitForInStatement(ForInStatement node) {
    // Should be lowered by the async transformation.
    throw "unreachable";
  }

  @override
  visitForStatement(ForStatement node) {
    _enterScope(node);
    try {
      _generateNodeList(node.variables);

      if (asm.isUnreachable) {
        // Bail out before binding a label which allows backward jumps,
        // as it is not handled by local unreachable code elimination.
        return;
      }

      final Label done = new Label();
      final Label join = new Label(allowsBackwardJumps: true);
      asm.bind(join);

      asm.emitCheckStack(++currentLoopDepth);

      if (node.condition != null) {
        _genConditionAndJumpIf(node.condition, false, done);
      }

      _generateNode(node.body);

      if (locals.currentContextSize > 0) {
        asm.emitPush(locals.contextVarIndexInFrame);
        asm.emitCloneContext(
            locals.currentContextId, locals.currentContextSize);
        asm.emitPopLocal(locals.contextVarIndexInFrame);
      }

      for (var update in node.updates) {
        _generateNode(update);
        asm.emitDrop1();
      }

      asm.emitJump(join);

      asm.bind(done);
      --currentLoopDepth;
    } finally {
      _leaveScope();
    }
  }

  @override
  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    if (options.emitDebuggerStops) {
      asm.emitDebugCheck();
    }
    _genPushContextIfCaptured(node.variable);
    _genClosure(node, node.variable.name, node.function);
    _genStoreVar(node.variable);
  }

  @override
  visitIfStatement(IfStatement node) {
    final Label otherwisePart = new Label();

    _genConditionAndJumpIf(node.condition, false, otherwisePart);

    _generateNode(node.then);

    if (node.otherwise != null) {
      final Label done = new Label();
      asm.emitJump(done);
      asm.bind(otherwisePart);
      _generateNode(node.otherwise);
      asm.bind(done);
    } else {
      asm.bind(otherwisePart);
    }
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    final label = new Label();
    labeledStatements ??= new Map<LabeledStatement, Label>();
    labeledStatements[node] = label;
    contextLevels ??= new Map<TreeNode, int>();
    contextLevels[node] = locals.currentContextLevel;
    _generateNode(node.body);
    asm.bind(label);
    labeledStatements.remove(node);
    contextLevels.remove(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    final expr = node.expression ?? new NullLiteral();

    final List<TryFinally> tryFinallyBlocks =
        _getEnclosingTryFinallyBlocks(node, null);
    if (tryFinallyBlocks.isEmpty) {
      _generateNode(expr);
      _genReturnTOS();
    } else {
      if (options.emitDebuggerStops) {
        // Stop on the return statement before executing finally blocks.
        asm.emitDebugCheck();
      }
      if (expr is BasicLiteral) {
        _addFinallyBlocks(tryFinallyBlocks, () {
          _generateNode(expr);
          _genReturnTOS();
        });
      } else {
        // Keep return value in a variable as try-catch statements
        // inside finally can zap expression stack.
        _generateNode(node.expression);
        asm.emitPopLocal(locals.returnVarIndexInFrame);

        _addFinallyBlocks(tryFinallyBlocks, () {
          asm.emitPush(locals.returnVarIndexInFrame);
          _genReturnTOS();
        });
      }
    }
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    contextLevels ??= new Map<TreeNode, int>();
    contextLevels[node] = locals.currentContextLevel;

    _generateNode(node.expression);

    if (asm.isUnreachable) {
      // Bail out before binding labels which allow backward jumps,
      // as they are not handled by local unreachable code elimination.
      return;
    }

    final int temp = locals.tempIndexInFrame(node);
    asm.emitPopLocal(temp);

    final Label done = new Label();
    final List<Label> caseLabels = new List<Label>.generate(
        node.cases.length, (_) => new Label(allowsBackwardJumps: true));
    final equalsArgDesc = objectTable.getArgDescHandle(2);

    switchCases ??= new Map<SwitchCase, Label>();

    Label defaultLabel = done;
    for (int i = 0; i < node.cases.length; i++) {
      final SwitchCase switchCase = node.cases[i];
      final Label caseLabel = caseLabels[i];
      switchCases[switchCase] = caseLabel;

      if (switchCase.isDefault) {
        defaultLabel = caseLabel;
      } else {
        final savedSourcePosition = asm.currentSourcePosition;
        for (int i = 0; i < switchCase.expressions.length; ++i) {
          _recordSourcePosition(switchCase.expressionOffsets[i]);
          _genPushConstExpr(switchCase.expressions[i]);
          asm.emitPush(temp);
          asm.emitInterfaceCall(
              cp.addInterfaceCall(
                  InvocationKind.method, coreTypes.objectEquals, equalsArgDesc),
              2);
          asm.emitJumpIfTrue(caseLabel);
        }
        asm.currentSourcePosition = savedSourcePosition;
      }
    }

    asm.emitJump(defaultLabel);

    for (int i = 0; i < node.cases.length; i++) {
      final SwitchCase switchCase = node.cases[i];
      final Label caseLabel = caseLabels[i];

      asm.bind(caseLabel);
      _generateNode(switchCase.body);

      // Front-end issues a compile-time error if there is a fallthrough
      // between cases. Also, default case should be the last one.
    }

    asm.bind(done);
    node.cases.forEach(switchCases.remove);
    contextLevels.remove(node);
  }

  bool _isTryBlock(TreeNode node) => node is TryCatch || node is TryFinally;

  int _savedContextVar(TreeNode node) {
    assert(_isTryBlock(node));
    assert(locals.capturedSavedContextVar(node) == null);
    return locals.tempIndexInFrame(node, tempIndex: 0);
  }

  // Exception var occupies the same slot as saved context, so context
  // should be restored first, before loading exception.
  int _exceptionVar(TreeNode node) {
    assert(_isTryBlock(node));
    return locals.tempIndexInFrame(node, tempIndex: 0);
  }

  int _stackTraceVar(TreeNode node) {
    assert(_isTryBlock(node));
    return locals.tempIndexInFrame(node, tempIndex: 1);
  }

  _saveContextForTryBlock(TreeNode node) {
    if (!locals.hasContextVar) {
      return;
    }
    final capturedSavedContextVar = locals.capturedSavedContextVar(node);
    if (capturedSavedContextVar != null) {
      assert(locals.isSyncYieldingFrame);
      _genPushContextForVariable(capturedSavedContextVar);
      asm.emitPush(locals.contextVarIndexInFrame);
      _genStoreVar(capturedSavedContextVar);
    } else {
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitPopLocal(_savedContextVar(node));
    }
  }

  _restoreContextForTryBlock(TreeNode node) {
    if (!locals.hasContextVar) {
      return;
    }
    final capturedSavedContextVar = locals.capturedSavedContextVar(node);
    if (capturedSavedContextVar != null) {
      // 1. Restore context from closure var.
      // This context has a context level at frame entry.
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureContext));
      asm.emitPopLocal(locals.contextVarIndexInFrame);

      // 2. Restore context from captured :saved_try_context_var${depth}.
      assert(locals.isCaptured(capturedSavedContextVar));
      _genLoadVar(capturedSavedContextVar,
          currentContextLevel: locals.contextLevelAtEntry);
    } else {
      asm.emitPush(_savedContextVar(node));
    }
    asm.emitPopLocal(locals.contextVarIndexInFrame);
  }

  /// Start try block
  TryBlock _startTryBlock(TreeNode node) {
    assert(_isTryBlock(node));

    _saveContextForTryBlock(node);

    return asm.exceptionsTable.enterTryBlock(asm.offset);
  }

  /// End try block and start its handler.
  void _endTryBlock(TreeNode node, TryBlock tryBlock) {
    tryBlock.endPC = asm.offset;
    tryBlock.handlerPC = asm.offset;

    // Exception handlers are reachable although there are no labels or jumps.
    asm.isUnreachable = false;

    asm.emitSetFrame(locals.frameSize);

    _restoreContextForTryBlock(node);

    asm.emitMoveSpecial(SpecialIndex.exception, _exceptionVar(node));
    asm.emitMoveSpecial(SpecialIndex.stackTrace, _stackTraceVar(node));

    final capturedExceptionVar = locals.capturedExceptionVar(node);
    if (capturedExceptionVar != null) {
      _genPushContextForVariable(capturedExceptionVar);
      asm.emitPush(_exceptionVar(node));
      _genStoreVar(capturedExceptionVar);
    }

    final capturedStackTraceVar = locals.capturedStackTraceVar(node);
    if (capturedStackTraceVar != null) {
      _genPushContextForVariable(capturedStackTraceVar);
      asm.emitPush(_stackTraceVar(node));
      _genStoreVar(capturedStackTraceVar);
    }
  }

  void _genRethrow(TreeNode node) {
    final capturedExceptionVar = locals.capturedExceptionVar(node);
    if (capturedExceptionVar != null) {
      assert(locals.isCaptured(capturedExceptionVar));
      _genLoadVar(capturedExceptionVar);
    } else {
      asm.emitPush(_exceptionVar(node));
    }

    final capturedStackTraceVar = locals.capturedStackTraceVar(node);
    if (capturedStackTraceVar != null) {
      assert(locals.isCaptured(capturedStackTraceVar));
      _genLoadVar(capturedStackTraceVar);
    } else {
      asm.emitPush(_stackTraceVar(node));
    }

    asm.emitThrow(1);
  }

  @override
  visitTryCatch(TryCatch node) {
    if (asm.isUnreachable) {
      return;
    }

    final Label done = new Label();

    final TryBlock tryBlock = _startTryBlock(node);
    tryBlock.isSynthetic = node.isSynthetic;
    tryCatches ??= new Map<TryCatch, TryBlock>();
    tryCatches[node] = tryBlock; // Used by rethrow.

    _generateNode(node.body);
    asm.emitJump(done);

    _endTryBlock(node, tryBlock);

    final int exception = _exceptionVar(node);
    final int stackTrace = _stackTraceVar(node);

    bool hasCatchAll = false;

    final savedSourcePosition = asm.currentSourcePosition;
    for (Catch catchClause in node.catches) {
      _recordSourcePosition(catchClause.fileOffset);
      tryBlock.types.add(cp.addType(catchClause.guard));

      Label skipCatch;
      if (catchClause.guard == const DynamicType()) {
        hasCatchAll = true;
      } else {
        asm.emitPush(exception);
        _genInstanceOf(catchClause.guard);

        skipCatch = new Label();
        asm.emitJumpIfFalse(skipCatch);
      }

      _enterScope(catchClause);

      if (catchClause.exception != null) {
        _genPushContextIfCaptured(catchClause.exception);
        asm.emitPush(exception);
        _genStoreVar(catchClause.exception);
      }

      if (catchClause.stackTrace != null) {
        tryBlock.needsStackTrace = true;
        _genPushContextIfCaptured(catchClause.stackTrace);
        asm.emitPush(stackTrace);
        _genStoreVar(catchClause.stackTrace);
      }

      _generateNode(catchClause.body);

      _leaveScope();
      asm.emitJump(done);

      if (skipCatch != null) {
        asm.bind(skipCatch);
      }
    }
    asm.currentSourcePosition = savedSourcePosition;

    if (!hasCatchAll) {
      tryBlock.needsStackTrace = true;
      _genRethrow(node);
    }

    asm.bind(done);
    tryCatches.remove(node);
  }

  @override
  visitTryFinally(TryFinally node) {
    if (asm.isUnreachable) {
      return;
    }

    final TryBlock tryBlock = _startTryBlock(node);
    tryBlock.isSynthetic = true;
    finallyBlocks ??= new Map<TryFinally, List<FinallyBlock>>();
    finallyBlocks[node] = <FinallyBlock>[];

    _generateNode(node.body);

    if (!asm.isUnreachable) {
      final normalContinuation = new FinallyBlock(() {
        /* do nothing (fall through) */
      });
      finallyBlocks[node].add(normalContinuation);
      asm.emitJump(normalContinuation.entry);
    }

    _endTryBlock(node, tryBlock);

    tryBlock.types.add(cp.addType(const DynamicType()));

    _generateNode(node.finalizer);

    tryBlock.needsStackTrace = true; // For rethrowing.
    _genRethrow(node);

    for (var finallyBlock in finallyBlocks[node]) {
      asm.bind(finallyBlock.entry);
      _restoreContextForTryBlock(node);
      _generateNode(node.finalizer);
      finallyBlock.generateContinuation();
    }

    finallyBlocks.remove(node);
  }

  bool _skipVariableInitialization(VariableDeclaration v, bool isCaptured) {
    // We can skip variable initialization if the variable is supposed to be
    // initialized to null and it's captured. This is because all the slots in
    // the capture context are implicitly initialized to null.

    // Check if the variable is supposed to be initialized to null.
    if (!(v.initializer == null || v.initializer is NullLiteral)) {
      return false;
    }

    // Late variables need to be initialized to a sentinel, not null.
    if (v.isLate) return false;

    // Non-captured variables go in stack slots that aren't implicitly nulled.
    return isCaptured;
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (!node.isConst) {
      final bool isCaptured = locals.isCaptured(node);
      final initializer = node.initializer;
      final bool emitStore = !_skipVariableInitialization(node, isCaptured);
      int maxInitializerPosition = node.fileOffset;
      if (emitStore) {
        if (isCaptured) {
          _genPushContextForVariable(node);
        }
        if (node.isLate && !_isTrivialInitializer(initializer)) {
          asm.emitPushUninitializedSentinel();
        } else if (initializer != null) {
          _startRecordingMaxPosition(node.fileOffset);
          _generateNode(initializer);
          maxInitializerPosition = _endRecordingMaxPosition();
        } else {
          asm.emitPushNull();
        }
      }

      if (options.emitDebuggerStops &&
          (initializer == null || _variableSetNeedsDebugCheck(initializer))) {
        final savedSourcePosition = asm.currentSourcePosition;
        if (node.fileEqualsOffset != TreeNode.noOffset) {
          _recordSourcePosition(node.fileEqualsOffset);
        }
        asm.emitDebugCheck();
        asm.currentSourcePosition = savedSourcePosition;
      }

      if (options.emitLocalVarInfo && !asm.isUnreachable && node.name != null) {
        _declareLocalVariable(node, maxInitializerPosition + 1);
      }

      if (emitStore) {
        _genStoreVar(node);
      }
    }
  }

  @override
  visitWhileStatement(WhileStatement node) {
    if (asm.isUnreachable) {
      // Bail out before binding a label which allows backward jumps,
      // as it is not handled by local unreachable code elimination.
      return;
    }

    final Label done = new Label();
    final Label join = new Label(allowsBackwardJumps: true);
    asm.bind(join);

    asm.emitCheckStack(++currentLoopDepth);

    _genConditionAndJumpIf(node.condition, false, done);

    _generateNode(node.body);

    asm.emitJump(join);
    --currentLoopDepth;

    asm.bind(done);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    if (!node.isNative) {
      throw 'YieldStatement must be desugared: $node';
    }

    if (asm.isUnreachable) {
      return;
    }

    // 0 is reserved for normal entry, yield points are counted from 1.
    final int yieldIndex = yieldPoints.length + 1;
    final Label continuationLabel = new Label(allowsBackwardJumps: true);
    yieldPoints.add(continuationLabel);

    // :await_jump_var = #index
    assert(locals.isCaptured(locals.awaitJumpVar));
    _genPushContextForVariable(locals.awaitJumpVar);
    _genPushInt(yieldIndex);
    _genStoreVar(locals.awaitJumpVar);

    // :await_ctx_var = context
    assert(locals.isCaptured(locals.awaitContextVar));
    _genPushContextForVariable(locals.awaitContextVar);
    asm.emitPush(locals.contextVarIndexInFrame);
    _genStoreVar(locals.awaitContextVar);

    // return <expression>
    // Note: finally blocks are *not* executed on the way out.
    _generateNode(node.expression);
    _genReturnTOS(node.fileOffset);

    asm.bind(continuationLabel);

    if (parentFunction.dartAsyncMarker == AsyncMarker.Async ||
        parentFunction.dartAsyncMarker == AsyncMarker.AsyncStar) {
      final int exceptionParam = locals.asyncExceptionParamIndexInFrame;
      final int stackTraceParam = locals.asyncStackTraceParamIndexInFrame;

      // if (:exception != null) rethrow (:exception, :stack_trace)
      final Label cont = new Label();
      asm.emitPush(exceptionParam);
      asm.emitJumpIfNull(cont);

      asm.emitPush(exceptionParam);
      asm.emitPush(stackTraceParam);
      asm.emitThrow(1);

      asm.bind(cont);
    }
  }

  @override
  visitFieldInitializer(FieldInitializer node) {
    _genFieldInitializer(node.field, node.value);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    _genArguments(new ThisExpression(), args);
    _genDirectCallWithArgs(node.target, args, hasReceiver: true, node: node);
    asm.emitDrop1();
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    _genArguments(new ThisExpression(), args);
    // Re-resolve target due to partial mixin resolution.
    Member target;
    for (var replacement in enclosingClass.superclass.constructors) {
      if (node.target.name == replacement.name) {
        target = replacement;
        break;
      }
    }
    assert(target != null);
    _genDirectCallWithArgs(target, args, hasReceiver: true, node: node);
    asm.emitDrop1();
  }

  @override
  visitLocalInitializer(LocalInitializer node) {
    _generateNode(node.variable);
  }

  @override
  visitAssertInitializer(AssertInitializer node) {
    _generateNode(node.statement);
  }

  @override
  visitConstantExpression(ConstantExpression node) {
    _genPushConstant(node.constant);
  }
}

class UnsupportedOperationError {
  final String message;
  UnsupportedOperationError(this.message);

  @override
  String toString() => message;
}

class TooManyArgumentsException extends BytecodeLimitExceededException {
  final int fileOffset;
  TooManyArgumentsException(this.fileOffset);
}

typedef void GenerateContinuation();

class FinallyBlock {
  final Label entry = new Label();
  final GenerateContinuation generateContinuation;

  FinallyBlock(this.generateContinuation);
}

class Annotations {
  final AnnotationsDeclaration object;
  final bool hasPragma;

  const Annotations(this.object, this.hasPragma);
}

ast.Component createFreshComponentWithBytecode(ast.Component component) {
  final newComponent = new ast.Component();
  final newRepository = new BytecodeMetadataRepository();
  newComponent.addMetadataRepository(newRepository);

  final oldRepository = component.metadata.remove(newRepository.tag);
  final metadata = oldRepository.mapping[component];
  newRepository.mapping[newComponent] = metadata;

  return newComponent;
}
