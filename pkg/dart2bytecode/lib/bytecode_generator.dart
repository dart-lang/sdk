// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:math' as math;

import 'package:kernel/ast.dart' hide Component, FunctionDeclaration;
import 'package:kernel/ast.dart' as ast show Component, FunctionDeclaration;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/external_name.dart' show getExternalName;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/target/targets.dart' show Target;
import 'package:kernel/type_algebra.dart'
    show Substitution, containsTypeVariable;
import 'package:kernel/type_environment.dart'
    show StatefulStaticTypeContext, SubtypeCheckMode, TypeEnvironment;

import 'package:vm/transformations/pragma.dart';

import 'assembler.dart';
import 'bytecode_serialization.dart'
    show BufferedWriter, LinkWriter, StringTable;
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
        isUncheckedCall;
import 'local_variable_table.dart' show LocalVariableTable;
import 'local_vars.dart' show LocalVariables;
import 'object_table.dart'
    show ObjectHandle, ObjectTable, NameAndType, topLevelClassName;
import 'options.dart' show BytecodeOptions;
import 'recognized_methods.dart' show RecognizedMethods;
import 'source_positions.dart' show LineStarts, SourcePositions;

// This symbol is used as the name in assert assignable's to indicate it comes
// from an explicit 'as' check.  This will cause the runtime to throw the right
// exception.
const String symbolForTypeCast = ' in type cast';

void generateBytecode(
  ast.Component component,
  Sink<List<int>> sink, {
  required BytecodeOptions options,
  required List<Library> libraries,
  required CoreTypes coreTypes,
  required ClassHierarchy hierarchy,
  required Target target,
}) {
  Timeline.timeSync("generateBytecode", () {
    verifyBytecodeInstructionDeclarations();
    final typeEnvironment = TypeEnvironment(coreTypes, hierarchy);
    final pragmaParser = ConstantPragmaAnnotationParser(coreTypes, target);

    final bytecodeGenerator = BytecodeGenerator(component, coreTypes, hierarchy,
        typeEnvironment, options, pragmaParser);
    for (Library library in libraries) {
      bytecodeGenerator.visitLibrary(library);
    }

    final bytecodeComponent = bytecodeGenerator.bytecodeComponent;

    final mainMethod = component.mainMethod;
    if (mainMethod != null && bytecodeComponent.dynModuleEntryPoint == null) {
      bytecodeComponent.dynModuleEntryPoint =
          bytecodeComponent.objectTable.getHandle(mainMethod);
    }

    final linkWriter = new LinkWriter();
    final writer = new BufferedWriter(bytecodeComponent.stringTable,
        bytecodeComponent.objectTable, linkWriter);
    bytecodeComponent.write(writer);
    writer.writeContentsToSink(sink);
  });
}

class BytecodeGenerator extends RecursiveVisitor {
  static final Name callName = new Name('call');
  static final Name noSuchMethodName = new Name('noSuchMethod');

  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final TypeEnvironment typeEnvironment;
  final StatefulStaticTypeContext staticTypeContext;
  final BytecodeOptions options;
  final PragmaAnnotationParser pragmaParser;
  final RecognizedMethods recognizedMethods;
  final Map<Uri, Source> astUriToSource;
  late StringTable stringTable;
  late ObjectTable objectTable;
  late Component bytecodeComponent;

  List<ClassDeclaration> classDeclarations = const [];
  List<FieldDeclaration> fieldDeclarations = const [];
  List<FunctionDeclaration> functionDeclarations = const [];
  Class? enclosingClass;
  Member? enclosingMember;
  FunctionNode? enclosingFunction;
  FunctionNode? parentFunction;
  bool isClosure = false;
  Set<TypeParameter>? classTypeParameters;
  List<TypeParameter>? functionTypeParameters;
  Set<TypeParameter>? functionTypeParametersSet;
  List<DartType>? instantiatorTypeArguments;
  late LocalVariables locals;
  Map<LabeledStatement, Label>? labeledStatements;
  Map<SwitchCase, Label>? switchCases;
  Map<TryCatch, TryBlock>? tryCatches;
  Map<TryFinally, List<FinallyBlock>>? finallyBlocks;
  Map<TreeNode, int>? contextLevels;
  List<ClosureDeclaration>? closures;
  Set<Field> initializedFields = const {};
  List<ObjectHandle> nullableFields = const [];
  late ConstantPool cp;
  late BytecodeAssembler asm;
  List<BytecodeAssembler>? savedAssemblers;
  bool hasErrors = false;
  int currentLoopDepth = 0;
  List<int>? savedMaxSourcePositions;
  int maxSourcePosition = 0;
  Member? dynModuleEntryPoint;

  BytecodeGenerator(
      ast.Component component,
      CoreTypes coreTypes,
      ClassHierarchy hierarchy,
      TypeEnvironment typeEnvironment,
      BytecodeOptions options,
      PragmaAnnotationParser pragmaParser)
      : this._internal(
            component,
            coreTypes,
            hierarchy,
            typeEnvironment,
            options,
            pragmaParser,
            StatefulStaticTypeContext.flat(typeEnvironment));

  BytecodeGenerator._internal(
      ast.Component component,
      this.coreTypes,
      this.hierarchy,
      this.typeEnvironment,
      this.options,
      this.pragmaParser,
      this.staticTypeContext)
      : recognizedMethods = new RecognizedMethods(staticTypeContext),
        astUriToSource = component.uriToSource {
    bytecodeComponent = new Component(coreTypes);
    stringTable = bytecodeComponent.stringTable;
    objectTable = bytecodeComponent.objectTable;
  }

  @override
  void visitLibrary(Library node) {
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
    classDeclarations = const [];
    staticTypeContext.leaveLibrary(node);
  }

  @override
  void visitClass(Class node) {
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
    fieldDeclarations = const [];
    functionDeclarations = const [];
    return members;
  }

  ObjectHandle getScript(Uri uri, bool includeSourceInfo) {
    SourceFile? source;
    if (options.emitSourcePositions) {
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
          LineStarts lineStarts = new LineStarts(astSource.lineStarts!);
          bytecodeComponent.lineStarts.add(lineStarts);
          source.lineStarts = lineStarts;
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
      if (targetLibrary == coreTypes.mirrorsLibrary) {
        flags |= LibraryDeclaration.usesDartMirrorsFlag;
      } else if (targetLibrary == dartFfiLibrary) {
        flags |= LibraryDeclaration.usesDartFfiFlag;
      }
    }
    final name = objectTable.getPublicNameHandle(library.name ?? '');
    final script = getScript(library.fileUri, true);
    return new LibraryDeclaration(importUri, flags, name, script, classes);
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
    TypeParametersDeclaration? typeParameters;
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
    final interfaces = objectTable.getNonNullHandles(
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
    final object = objectTable
        .getHandle(new ListConstant(const DynamicType(), constants))!;
    final decl = new AnnotationsDeclaration(object);
    bytecodeComponent.annotations.add(decl);
    return new Annotations(decl, hasPragma);
  }

  // Insert annotations for the function and its parameters into the annotations
  // section. Return the annotations for the function only. The bytecode reader
  // will implicitly find the parameter annotations by reading N packed objects
  // after reading the function's annotations, one for each parameter.
  Annotations getFunctionAnnotations(Member member) {
    final functionNodes = member.annotations;
    final parameterNodeLists = <List<Expression>>[];
    for (VariableDeclaration variable
        in member.function!.positionalParameters) {
      parameterNodeLists.add(variable.annotations);
    }
    for (VariableDeclaration variable in member.function!.namedParameters) {
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
        .getHandle(new ListConstant(const DynamicType(), functionConstants))!;
    final functionDecl = new AnnotationsDeclaration(functionObject);
    bytecodeComponent.annotations.add(functionDecl);

    for (final parameterNodes in parameterNodeLists) {
      List<Constant> parameterConstants =
          parameterNodes.map(_getConstant).toList();
      final parameterObject = objectTable.getHandle(
          new ListConstant(const DynamicType(), parameterConstants))!;
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
      final dependencyName = dependency.name;
      final prefix = dependencyName != null
          ? StringConstant(dependencyName)
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
        objectTable.getHandle(ListConstant(const DynamicType(), deps))!;
    final dependenciesDecl = new AnnotationsDeclaration(dependenciesObject);
    bytecodeComponent.annotations.add(dependenciesDecl);

    return annotations;
  }

  FieldDeclaration getFieldDeclaration(Field field, Code? initializer) {
    int flags = 0;
    Constant? value;
    final astInitializer = field.initializer;
    if (_hasNonTrivialInitializer(field)) {
      flags |= FieldDeclaration.hasNontrivialInitializerFlag;
    } else if (astInitializer != null) {
      value = _getConstant(astInitializer);
    }
    if (initializer != null) {
      flags |= FieldDeclaration.hasInitializerCodeFlag;
    }
    if (astInitializer != null) {
      flags |= FieldDeclaration.hasInitializerFlag;
    }
    final name = objectTable.getNameHandle(
        field.name.library, objectTable.mangleMemberName(field, false, false));
    ObjectHandle? getterName;
    ObjectHandle? setterName;
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
    if (field.isCovariantByDeclaration) {
      flags |= FieldDeclaration.isCovariantFlag;
    }
    if (field.isCovariantByClass) {
      flags |= FieldDeclaration.isGenericCovariantImplFlag;
    }
    if (field.isExtensionMember) {
      flags |= FieldDeclaration.isExtensionMemberFlag;
    }
    // In NNBD libraries, static fields with initializers are implicitly late.
    if (field.isLate || (field.isStatic && field.initializer != null)) {
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
    ObjectHandle? script;
    if (field.fileUri != (field.parent as FileUriNode).fileUri) {
      final isInAnonymousMixin = enclosingClass?.isAnonymousMixin ?? false;
      script = getScript(field.fileUri, !isInAnonymousMixin);
      flags |= FieldDeclaration.hasCustomScriptFlag;
    }
    return new FieldDeclaration(
        flags,
        name,
        objectTable.getHandle(field.type)!,
        objectTable.getHandle(value),
        script,
        position,
        endPosition,
        getterName,
        setterName,
        initializer,
        annotations.object);
  }

  FunctionDeclaration getFunctionDeclaration(Member member, Code? code) {
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

    FunctionNode function = member.function!;
    if (function.requiredParameterCount !=
        function.positionalParameters.length) {
      flags |= FunctionDeclaration.hasOptionalPositionalParamsFlag;
    }
    if (function.namedParameters.isNotEmpty) {
      flags |= FunctionDeclaration.hasOptionalNamedParamsFlag;
    }
    TypeParametersDeclaration? typeParameters;
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
    ObjectHandle? nativeName;
    if (member.isExternal) {
      final String? externalName = getExternalName(coreTypes, member);
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
        if (pragmaParser
            .parsedPragmas<ParsedDynModuleEntryPointPragma>(member.annotations)
            .isNotEmpty) {
          if (dynModuleEntryPoint != null) {
            throw 'Duplicate Dynamic Module Entry Points: $dynModuleEntryPoint and $member';
          }
          if (!(member is Procedure &&
              member.isStatic &&
              function.typeParameters.isEmpty &&
              function.positionalParameters.isEmpty &&
              function.namedParameters.isEmpty)) {
            throw 'Dynamic Module Entry Point should be a static no-argument method: $member';
          }
          dynModuleEntryPoint = member;
          bytecodeComponent.dynModuleEntryPoint = objectTable.getHandle(member);
        }
      }
    }
    ObjectHandle? script;
    if (member.fileUri != (member.parent as FileUriNode).fileUri) {
      final isInAnonymousMixin = enclosingClass?.isAnonymousMixin ?? false;
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
    // We only need the required flags when loading the function declaration.
    final parameterFlags =
        getParameterFlags(function, mask: ParameterDeclaration.isRequiredFlag);
    if (parameterFlags != null) {
      flags |= FunctionDeclaration.hasParameterFlagsFlag;
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
        parameterFlags,
        objectTable.getHandle(function.returnType)!,
        nativeName,
        code,
        annotations.object);
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
    return true;
  }

  TypeParametersDeclaration getTypeParametersDeclaration(
      List<TypeParameter> typeParams) {
    return new TypeParametersDeclaration(
        objectTable.getTypeParameterHandles(typeParams));
  }

  ParameterDeclaration getParameterDeclaration(VariableDeclaration variable) {
    final name = variable.name!;
    final lib = name.startsWith('_') ? enclosingMember!.enclosingLibrary : null;
    final nameHandle = objectTable.getNameHandle(lib, name);
    final typeHandle = objectTable.getHandle(variable.type)!;
    return new ParameterDeclaration(nameHandle, typeHandle);
  }

  // Most uses of parameter flags in the VM only nee a subset of the flags,
  // so the optional [mask] argument allows the caller to specify the subset
  // that should be retained.
  List<int>? getParameterFlags(FunctionNode function, {int mask = -1}) {
    int getFlags(VariableDeclaration variable, int mask) {
      int flags = 0;
      if (variable.isCovariantByDeclaration) {
        flags |= ParameterDeclaration.isCovariantFlag;
      }
      if (variable.isCovariantByClass) {
        flags |= ParameterDeclaration.isGenericCovariantImplFlag;
      }
      if (variable.isFinal) {
        flags |= ParameterDeclaration.isFinalFlag;
      }
      if (variable.isRequired) {
        flags |= ParameterDeclaration.isRequiredFlag;
      }
      return flags & mask;
    }

    final List<int> paramFlags = <int>[];
    for (var param in function.positionalParameters) {
      paramFlags.add(getFlags(param, mask));
    }
    for (var param in function.namedParameters) {
      paramFlags.add(getFlags(param, mask));
    }

    for (int flags in paramFlags) {
      if (flags != 0) {
        return paramFlags;
      }
    }
    return null;
  }

  @override
  void defaultMember(Member node) {
    final bool hasCode = _hasCode(node);
    start(node, hasCode);
    if (node is Field) {
      if (hasCode) {
        if (node.isConst) {
          _genPushConstExpr(node.initializer!);
        } else {
          _generateNode(node.initializer!);
        }
        _genReturnTOS();
      }
    } else if (node is Procedure || node is Constructor) {
      if (hasCode) {
        if (node is Constructor) {
          _genConstructorInitializers(node);
        }
        if (node.isExternal) {
          _unimplemented(node, 'external member');
        } else {
          _generateNode(node.function?.body);
          // BytecodeAssembler eliminates this bytecode if it is unreachable.
          asm.emitPushNull();
        }
        if (node.function != null) {
          _recordSourcePosition(node.function!.fileEndOffset);
        }
        _genReturnTOS();
      }
    } else {
      throw 'Unexpected member ${node.runtimeType} $node';
    }
    end(node, hasCode);
  }

  bool _hasCode(Member member) {
    // Front-end might set abstract flag on static external procedures,
    // but they can be called and should have a body.
    if (member is Procedure && member.isStatic && member.isExternal) {
      return true;
    }
    if (member.isAbstract) {
      return false;
    }
    if (member is Field) {
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
    // Final fields don't have a setter, except late final fields
    // without initializer.
    if (field.isFinal) {
      // Late final fields without initializer always need a setter to check
      // if they are already initialized.
      if (field.isLate && (field.initializer == null)) {
        return true;
      }
      return false;
    }

    // Instance non-final fields always need a setter.
    if (!field.isStatic) return true;

    // Otherwise, setters for static fields can be omitted
    // and fields can be accessed directly.
    return false;
  }

  LibraryIndex get libraryIndex => coreTypes.index;

  late Procedure growableListLiteral =
      libraryIndex.getProcedure('dart:core', '_GrowableList', '_literal');

  late Procedure mapFromLiteral =
      libraryIndex.getProcedure('dart:core', 'Map', '_fromLiteral');

  late Procedure interpolateSingle = libraryIndex.getProcedure(
      'dart:core', '_StringBase', '_interpolateSingle');

  late Procedure interpolate =
      libraryIndex.getProcedure('dart:core', '_StringBase', '_interpolate');

  late Class closureClass = libraryIndex.getClass('dart:core', '_Closure');

  late Procedure objectInstanceOf =
      libraryIndex.getProcedure('dart:core', 'Object', '_instanceOf');

  late Procedure objectSimpleInstanceOf =
      libraryIndex.getProcedure('dart:core', 'Object', '_simpleInstanceOf');

  late Field closureInstantiatorTypeArguments = libraryIndex.getField(
      'dart:core', '_Closure', '_instantiator_type_arguments');

  late Field closureFunctionTypeArguments = libraryIndex.getField(
      'dart:core', '_Closure', '_function_type_arguments');

  late Field closureDelayedTypeArguments =
      libraryIndex.getField('dart:core', '_Closure', '_delayed_type_arguments');

  late Field closureFunction =
      libraryIndex.getField('dart:core', '_Closure', '_function');

  late Field closureContext =
      libraryIndex.getField('dart:core', '_Closure', '_context');

  late Procedure prependTypeArguments = libraryIndex.getTopLevelProcedure(
      'dart:_internal', '_prependTypeArguments');

  late Procedure boundsCheckForPartialInstantiation =
      libraryIndex.getTopLevelProcedure(
          'dart:_internal', '_boundsCheckForPartialInstantiation');

  late Procedure futureValue =
      libraryIndex.getProcedure('dart:async', 'Future', 'value');

  late Procedure throwLocalNotInitialized = libraryIndex.getProcedure(
      'dart:_internal', 'LateError', '_throwLocalNotInitialized');

  late Procedure throwLocalAlreadyInitialized = libraryIndex.getProcedure(
      'dart:_internal', 'LateError', '_throwLocalAlreadyInitialized');

  late Procedure throwLocalAssignedDuringInitialization =
      libraryIndex.getProcedure('dart:_internal', 'LateError',
          '_throwLocalAssignedDuringInitialization');

  late Procedure throwNewAssertionError =
      libraryIndex.getProcedure('dart:core', '_AssertionError', '_throwNew');

  late Procedure allocateInvocationMirror = libraryIndex.getProcedure(
      'dart:core', '_InvocationMirror', '_allocateInvocationMirror');

  late Procedure unsafeCast =
      libraryIndex.getTopLevelProcedure('dart:_internal', 'unsafeCast');

  late Procedure iterableIterator =
      libraryIndex.getProcedure('dart:core', 'Iterable', 'get:iterator');

  late Procedure iteratorMoveNext =
      libraryIndex.getProcedure('dart:core', 'Iterator', 'moveNext');

  late Procedure iteratorCurrent =
      libraryIndex.getProcedure('dart:core', 'Iterator', 'get:current');

  late Procedure setAsyncThreadStackTrace = libraryIndex.getTopLevelProcedure(
      'dart:async', '_setAsyncThreadStackTrace');

  late Procedure clearAsyncThreadStackTrace = libraryIndex.getTopLevelProcedure(
      'dart:async', '_clearAsyncThreadStackTrace');

  late Procedure initAsync =
      libraryIndex.getProcedure('dart:async', '_SuspendState', '_initAsync');

  late Procedure suspendStateFunctionData = libraryIndex.getProcedure(
      'dart:async',
      '_SuspendState',
      LibraryIndex.getterPrefix + '_functionData');

  late Procedure initAsyncStar = libraryIndex.getProcedure(
      'dart:async', '_SuspendState', '_initAsyncStar');

  late Procedure initSyncStar =
      libraryIndex.getProcedure('dart:async', '_SuspendState', '_initSyncStar');

  late Procedure _await =
      libraryIndex.getProcedure('dart:async', '_SuspendState', '_await');

  late Procedure _awaitWithTypeCheck = libraryIndex.getProcedure(
      'dart:async', '_SuspendState', '_awaitWithTypeCheck');

  late Procedure yieldAsyncStar = libraryIndex.getProcedure(
      'dart:async', '_SuspendState', '_yieldAsyncStar');

  late Procedure suspendSyncStarAtStart = libraryIndex.getProcedure(
      'dart:async', '_SuspendState', '_suspendSyncStarAtStart');

  late Procedure returnAsync =
      libraryIndex.getProcedure('dart:async', '_SuspendState', '_returnAsync');

  late Procedure returnAsyncStar = libraryIndex.getProcedure(
      'dart:async', '_SuspendState', '_returnAsyncStar');

  late Procedure asyncStarStreamControllerAdd = libraryIndex.getProcedure(
      'dart:async', '_AsyncStarStreamController', 'add');

  late Procedure asyncStarStreamControllerAddStream = libraryIndex.getProcedure(
      'dart:async', '_AsyncStarStreamController', 'addStream');

  late Field syncStarIteratorCurrent =
      libraryIndex.getField('dart:async', '_SyncStarIterator', '_current');

  late Field syncStarIteratorYieldStarIterable = libraryIndex.getField(
      'dart:async', '_SyncStarIterator', '_yieldStarIterable');

  late Library? dartFfiLibrary = libraryIndex.tryGetLibrary('dart:ffi');

  void _recordSourcePosition(int fileOffset) {
    asm.currentSourcePosition = fileOffset;
    maxSourcePosition = math.max(maxSourcePosition, fileOffset);
  }

  void _generateNode(TreeNode? node) {
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
      initializedFields = Set<Field>();
      for (var field in node.enclosingClass.fields) {
        if (!field.isStatic) {
          if (field.isLate) {
            if (!initializedInInitializersList.contains(field)) {
              _genLateFieldInitializer(field);
            }
          } else {
            final fieldInitializer = field.initializer;
            if (fieldInitializer != null) {
              if (initializedInInitializersList.contains(field)) {
                // Do not store a value into the field as it is going to be
                // overwritten by initializers list.
                _generateNode(fieldInitializer);
                asm.emitDrop1();
              } else {
                _genFieldInitializer(field, fieldInitializer);
              }
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
          nullableFields.add(objectTable.getHandle(field)!);
        }
      }
      initializedFields = const {}; // No more initialized fields, please.
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
      _genFieldInitializer(field, field.initializer!);
      return;
    }

    _genPushReceiver();

    final int cpIndex = cp.addInstanceField(field);
    asm.emitInitLateField(cpIndex);

    initializedFields.add(field);
  }

  void _genArguments(Expression? receiver, Arguments arguments,
      {int? storeReceiverToLocal}) {
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

  void _genReturnTOS() {
    final enclosingFunction = this.enclosingFunction;
    if (enclosingFunction != null) {
      Procedure? returnMethod;
      switch (enclosingFunction.dartAsyncMarker) {
        case AsyncMarker.Async:
          returnMethod = returnAsync;
          break;
        case AsyncMarker.AsyncStar:
          returnMethod = returnAsyncStar;
          break;
        case AsyncMarker.SyncStar:
          asm.emitDrop1();
          asm.emitPushFalse();
          break;
        case AsyncMarker.Sync:
          break;
      }
      if (returnMethod != null) {
        asm.emitPopLocal(locals.returnVarIndexInFrame);
        asm.emitPush(locals.suspendStateVarIndexInFrame);
        asm.emitPush(locals.returnVarIndexInFrame);
        asm.emitPushNull();
        asm.emitPopLocal(locals.suspendStateVarIndexInFrame);
        _genDirectCall(returnMethod, objectTable.getArgDescHandle(2), 2);
      }
    }
    asm.emitReturnTOS();
  }

  void _genDirectCall(Member target, ObjectHandle argDesc, int totalArgCount,
      {bool isGet = false,
      bool isSet = false,
      bool isUnchecked = false,
      TreeNode? node}) {
    assert(!isGet || !isSet);
    final kind = isGet
        ? InvocationKind.getter
        : (isSet ? InvocationKind.setter : InvocationKind.method);
    final cpIndex = cp.addDirectCall(kind, target, argDesc);

    if (totalArgCount >= argumentsLimit) {
      throw 'Too many arguments';
    }
    if (isUnchecked) {
      asm.emitUncheckedDirectCall(cpIndex, totalArgCount);
    } else {
      asm.emitDirectCall(cpIndex, totalArgCount);
    }
  }

  void _genDirectCallWithArgs(Member target, Arguments args,
      {bool hasReceiver = false,
      bool isFactory = false,
      bool isUnchecked = false,
      TreeNode? node}) {
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

  void _genTypeArguments(List<DartType> typeArgs, {Class? instantiatingClass}) {
    int typeArgsCPIndex() {
      if (instantiatingClass != null) {
        return cp.addTypeArguments(
            getInstantiatorTypeArguments(instantiatingClass, typeArgs));
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
    final classTypeParameters = this.classTypeParameters;
    if (classTypeParameters != null &&
        types.any((t) => containsTypeVariable(t, classTypeParameters))) {
      assert(instantiatorTypeArguments != null);
      _genPushInstantiatorTypeArguments();
    } else {
      asm.emitPushNull();
    }
    final functionTypeParametersSet = this.functionTypeParametersSet;
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
        final int cpIndex = cp.addTypeArgumentsField(enclosingClass!);
        asm.emitLoadTypeArgumentsField(cpIndex);
      }
    } else {
      asm.emitPushNull();
    }
  }

  bool _canReuseInstantiatorTypeArguments(List<DartType> typeArgs) {
    final instantiatorTypeArguments = this.instantiatorTypeArguments;
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
    final functionTypeParameters = this.functionTypeParameters;
    if (functionTypeParameters == null) {
      return false;
    }

    if (typeArgs.length > functionTypeParameters.length) {
      return false;
    }

    for (int i = 0; i < typeArgs.length; ++i) {
      final typeArg = typeArgs[i];
      if (!(typeArg is TypeParameterType &&
          typeArg.parameter == functionTypeParameters[i] &&
          (typeArg.nullability == Nullability.nonNullable ||
              typeArg.nullability == Nullability.undetermined))) {
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
      {int? currentContextLevel}) {
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

  void _genLoadVar(VariableDeclaration v, {int? currentContextLevel}) {
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
      condition = condition.operand;
      negated = true;
    }
    _generateNode(condition);
    return negated;
  }

  /// Returns value of the given expression if it is a bool constant.
  /// Otherwise, returns `null`.
  bool? _constantConditionValue(Expression condition) {
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
    final bool? constantValue = _constantConditionValue(condition);
    if (constantValue != null) {
      if (constantValue == value) {
        asm.emitJump(dest);
      }
      return;
    }
    if (condition is EqualsNull) {
      _generateNode(condition.expression);
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
      final isOR = (condition.operatorEnum == LogicalExpressionOperator.OR);

      Label shortCircuit;
      Label? done;
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
    final paramInitializer = param.initializer;
    if (paramInitializer == null) {
      return cp.addObjectRef(null);
    }
    final constant = _getConstant(paramInitializer);
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
    final enclosingClass = this.enclosingClass = node.enclosingClass;
    enclosingMember = node;
    final enclosingFunction = this.enclosingFunction = node.function;
    parentFunction = null;
    isClosure = false;
    hasErrors = false;
    staticTypeContext.enterMember(node);
    final isFactory = node is Procedure && node.isFactory;
    if (node.isInstanceMember || node is Constructor || isFactory) {
      if (enclosingClass!.typeParameters.isNotEmpty) {
        final classTypeParameters = this.classTypeParameters =
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
      final functionTypeParameters = this.functionTypeParameters =
          new List<TypeParameter>.from(enclosingFunction.typeParameters);
      functionTypeParametersSet = functionTypeParameters.toSet();
    }

    if (!hasCode) {
      return;
    }

    labeledStatements = null;
    switchCases = null;
    tryCatches = null;
    finallyBlocks = null;
    contextLevels = null;
    closures = null;
    initializedFields = const {}; // Tracked for constructors only.
    nullableFields = const [];
    cp = new ConstantPool(stringTable, objectTable);
    asm = new BytecodeAssembler(options);
    savedAssemblers = null;
    currentLoopDepth = 0;
    savedMaxSourcePositions = <int>[];
    maxSourcePosition = node.fileOffset;

    locals = new LocalVariables(node, options, staticTypeContext);
    locals.enterScope(node);

    int position;
    if (node is Procedure) {
      position = node.fileStartOffset;
    } else if (node is Constructor) {
      position = node.startFileOffset;
    } else {
      position = node.fileOffset;
    }
    _recordSourcePosition(position);
    _genPrologue(node, node.function);
    _setupInitialContext(node.function);
    _emitFirstDebugCheck(node.function);
    _genEqualsOperatorNullHandling(node);
    if (node is Procedure && node.isInstanceMember) {
      _checkArguments(node.function);
    }
    _initSuspendableFunction(node.function);
  }

  // Generate additional code for 'operator ==' to handle nulls.
  void _genEqualsOperatorNullHandling(Member member) {
    if (member.name.text != '==' ||
        locals.numParameters != 2 ||
        member.enclosingClass == coreTypes.objectClass) {
      return;
    }

    Label done = new Label();

    _genLoadVar(member.function!.positionalParameters[0]);
    asm.emitJumpIfNotNull(done);

    asm.emitPushFalse();
    _genReturnTOS();

    asm.bind(done);
  }

  void _initSuspendableFunction(FunctionNode? function) {
    if (!locals.isSuspendableFunction) {
      return;
    }
    Procedure initMethod;
    switch (function!.dartAsyncMarker) {
      case AsyncMarker.Async:
        initMethod = initAsync;
        break;
      case AsyncMarker.AsyncStar:
        initMethod = initAsyncStar;
        break;
      case AsyncMarker.SyncStar:
        initMethod = initSyncStar;
        break;
      default:
        throw 'Unexpected async marker ${function.dartAsyncMarker}';
    }
    _genTypeArguments([function.emittedValueType!]);
    _genDirectCall(initMethod, objectTable.getArgDescHandle(0, 1), 1);
    asm.emitPopLocal(locals.suspendStateVarIndexInFrame);

    if (function.dartAsyncMarker != AsyncMarker.Async) {
      // Suspend async* and sync* functions after prologue is finished.
      Label done = Label();
      asm.emitSuspend(done);

      final suspendMethod = (function.dartAsyncMarker == AsyncMarker.AsyncStar)
          ? yieldAsyncStar
          : suspendSyncStarAtStart;
      asm.emitPush(locals.suspendStateVarIndexInFrame);
      asm.emitPushNull();
      _genDirectCall(suspendMethod, objectTable.getArgDescHandle(2), 2);
      asm.emitReturnTOS();

      asm.bind(done);
      asm.emitDrop1(); // Discard result of Suspend.
    }

    if (function.dartAsyncMarker == AsyncMarker.SyncStar &&
        locals.currentContextSize > 0) {
      // Clone context if there are any captured parameter variables, so
      // each invocation of .iterator would get its own copy of parameters.
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitCloneContext(locals.currentContextId, locals.currentContextSize);
      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }
  }

  void end(Member node, bool hasCode) {
    if (!hasErrors) {
      Code? code;
      if (hasCode) {
        if (options.emitLocalVarInfo) {
          // Leave the scopes which were entered in _genPrologue and
          // _setupInitialContext.
          asm.localVariableTable.leaveAllScopes(
              asm.offset, node.function?.fileEndOffset ?? node.fileEndOffset);
        }

        List<int>? parameterFlags = null;
        int? forwardingStubTargetCpIndex = null;
        int? defaultFunctionTypeArgsCpIndex = null;

        // We don't need the required flag when loading the code, but do need
        // all other parameter flags.
        final parameterFlagMask = ~ParameterDeclaration.isRequiredFlag;

        if (node is Constructor) {
          parameterFlags =
              getParameterFlags(node.function, mask: parameterFlagMask);
        } else if (node is Procedure) {
          parameterFlags =
              getParameterFlags(node.function, mask: parameterFlagMask);

          if (node.isForwardingStub) {
            forwardingStubTargetCpIndex = cp.addObjectRef(node.stubTarget);
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
    isClosure = false;
    classTypeParameters = null;
    functionTypeParameters = null;
    functionTypeParametersSet = null;
    instantiatorTypeArguments = null;
    labeledStatements = null;
    switchCases = null;
    tryCatches = null;
    finallyBlocks = null;
    contextLevels = null;
    closures = null;
    initializedFields = const {};
    nullableFields = const [];
    savedAssemblers = null;
    hasErrors = false;
  }

  SourcePositions? finalizeSourcePositions() {
    if (asm.sourcePositions.isEmpty) {
      return null;
    }
    bytecodeComponent.sourcePositions.add(asm.sourcePositions);
    return asm.sourcePositions;
  }

  LocalVariableTable? finalizeLocalVariables() {
    final localVariables = asm.localVariableTable;
    assert(!localVariables.hasActiveScopes);
    if (localVariables.isEmpty) {
      return null;
    }
    bytecodeComponent.localVariables.add(localVariables);
    return localVariables;
  }

  void _genPrologue(Node node, FunctionNode? function) {
    if (locals.makesCopyOfParameters) {
      final int numOptionalPositional = function!.positionalParameters.length -
          function.requiredParameterCount;
      final int numOptionalNamed = function.namedParameters.length;
      final int numFixed =
          locals.numParameters - (numOptionalPositional + numOptionalNamed);

      if (locals.isSuspendableFunction) {
        asm.emitEntrySuspendable(
            numFixed, numOptionalPositional, numOptionalNamed);
      } else {
        asm.emitEntryOptional(
            numFixed, numOptionalPositional, numOptionalNamed);
      }

      if (numOptionalPositional != 0) {
        assert(numOptionalNamed == 0);
        for (int i = 0; i < numOptionalPositional; i++) {
          final param = function
              .positionalParameters[function.requiredParameterCount + i];
          final localIndex = locals.getParamIndexInFrame(param);
          asm.emitLoadConstant(localIndex, _getDefaultParamConstIndex(param));
        }
      } else {
        for (int i = 0; i < numOptionalNamed; i++) {
          final param = locals.sortedNamedParameters[i];
          final localIndex = locals.getParamIndexInFrame(param);
          asm.emitLoadConstant(localIndex, cp.addName(param.name!));
          asm.emitLoadConstant(localIndex, _getDefaultParamConstIndex(param));
        }
      }

      asm.emitFrame(locals.frameSize - locals.numParameters);
    } else {
      asm.emitEntry(locals.frameSize);
    }

    if (isClosure) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureContext));
      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }

    if (locals.hasFunctionTypeArgsVar && function!.typeParameters.isNotEmpty) {
      assert(!(node is Procedure && node.isFactory));

      Label done = new Label();

      if (isClosure) {
        _handleDelayedTypeArguments(done);
      }

      asm.emitCheckFunctionTypeArgs(function.typeParameters.length,
          locals.functionTypeArgsVarIndexInFrame);

      _handleDefaultTypeArguments(function, done);

      asm.bind(done);
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
      if (function!.typeParameters.isNotEmpty) {
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
    List<DartType>? defaultTypes = getDefaultFunctionTypeArguments(function);
    if (defaultTypes == null) {
      return;
    }

    asm.emitJumpIfNotZeroTypeArgs(doneCheckingTypeArguments);

    // Load parent function type arguments if they are used to
    // instantiate default types.
    if (isClosure &&
        defaultTypes
            .any((t) => containsTypeVariable(t, functionTypeParametersSet!))) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));
      asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
    }

    _genTypeArguments(defaultTypes);
    asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
  }

  void _setupInitialContext(FunctionNode? function) {
    _allocateContextIfNeeded();

    if (options.emitLocalVarInfo && locals.currentContextSize > 0) {
      // Open a new scope after allocating context.
      asm.localVariableTable.enterScope(asm.offset, locals.currentContextLevel,
          function?.fileOffset ?? enclosingMember!.fileOffset);
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

  void _emitFirstDebugCheck(FunctionNode? function) {
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
        _declareLocalVariable(variable, enclosingFunction!.fileOffset);
      }
      _genPushContextForVariable(variable);
      asm.emitPush(locals.getParamIndexInFrame(variable));
      _genStoreVar(variable);
      // TODO(alexmarkov): We need to store null at the original parameter
      // location, because the original value may need to be GC'ed.
    }
  }

  void _declareLocalVariable(
      VariableDeclaration variable, int initializedPosition) {
    bool isCaptured = locals.isCaptured(variable);
    asm.localVariableTable.declareVariable(
        asm.offset,
        isCaptured,
        isCaptured
            ? locals.getVarIndexInContext(variable)
            : locals.getVarIndexInFrame(variable),
        cp.addName(variable.name!),
        cp.addType(variable.type),
        variable.fileOffset,
        initializedPosition);
  }

  // TODO(dartbug.com/40813): Remove the closure case when we move the
  // type checks out of closure bodies.
  bool get canSkipTypeChecksForNonCovariantArguments => !isClosure;

  Member? _getForwardingStubSuperTarget() {
    if (!isClosure) {
      final member = enclosingMember!;
      if (member.isInstanceMember &&
          member is Procedure &&
          member.isForwardingStub) {
        return member.stubTarget;
      }
    }
    return null;
  }

  // Types in a target of a forwarding stub are encoded in terms of target type
  // parameters. Substitute them with host type parameters to be able
  // to use them (e.g. instantiate) in the context of host.
  Substitution? _getForwardingSubstitution(
      FunctionNode host, Member? forwardingTarget) {
    if (forwardingTarget == null) {
      return null;
    }
    final Class targetClass = forwardingTarget.enclosingClass!;
    final Supertype? instantiatedTargetClass =
        hierarchy.getClassAsInstanceOf(enclosingClass!, targetClass);
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
      final targetTypeParameters = forwardingTarget.function!.typeParameters;
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
  Map<TypeParameter, DartType>? _getForwardingBounds(FunctionNode function,
      Member? forwardingTarget, Substitution? forwardingSubstitution) {
    if (function.typeParameters.isEmpty || forwardingTarget == null) {
      return null;
    }
    final forwardingBounds = <TypeParameter, DartType>{};
    for (int i = 0; i < function.typeParameters.length; ++i) {
      DartType bound = forwardingSubstitution!
          .substituteType(forwardingTarget.function!.typeParameters[i].bound);
      forwardingBounds[function.typeParameters[i]] = bound;
    }
    return forwardingBounds;
  }

  /// If member being compiled is a forwarding stub, then returns parameter
  /// types to check for the forwarding stub target.
  Map<VariableDeclaration, DartType>? _getForwardingParameterTypes(
      FunctionNode function,
      Member? forwardingTarget,
      Substitution? forwardingSubstitution) {
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
            function.namedParameters.isEmpty);
        return <VariableDeclaration, DartType>{
          function.positionalParameters.single:
              forwardingSubstitution!.substituteType(forwardingTarget.type)
        };
      }
    }

    final forwardingParams = <VariableDeclaration, DartType>{};
    for (int i = 0; i < function.positionalParameters.length; ++i) {
      DartType type = forwardingSubstitution!.substituteType(
          forwardingTarget.function!.positionalParameters[i].type);
      forwardingParams[function.positionalParameters[i]] = type;
    }
    for (var hostParam in function.namedParameters) {
      VariableDeclaration targetParam = forwardingTarget
          .function!.namedParameters
          .firstWhere((p) => p.name == hostParam.name);
      forwardingParams[hostParam] =
          forwardingSubstitution!.substituteType(targetParam.type);
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
        if (!param.isCovariantByDeclaration &&
            _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
          _genArgumentTypeCheck(param, forwardingParamTypes);
        }
      }
      for (var param in locals.sortedNamedParameters) {
        if (!param.isCovariantByDeclaration &&
            _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
          _genArgumentTypeCheck(param, forwardingParamTypes);
        }
      }

      asm.bind(skipChecks);
    }

    // Covariant parameters need to be checked even if function is called
    // via unchecked call, so they are generated outside of JumpIfUnchecked.

    for (var param in function.positionalParameters) {
      if (param.isCovariantByDeclaration &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        _genArgumentTypeCheck(param, forwardingParamTypes);
      }
    }
    for (var param in locals.sortedNamedParameters) {
      if (param.isCovariantByDeclaration &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        _genArgumentTypeCheck(param, forwardingParamTypes);
      }
    }
  }

  /// Returns true if bound of [typeParam] should be checked.
  bool _typeParameterNeedsBoundCheck(TypeParameter typeParam,
      Map<TypeParameter, DartType>? forwardingTypeParameterBounds) {
    if (canSkipTypeChecksForNonCovariantArguments &&
        !typeParam.isCovariantByClass) {
      return false;
    }
    final DartType bound = (forwardingTypeParameterBounds != null)
        ? forwardingTypeParameterBounds[typeParam]!
        : typeParam.bound;
    if (typeEnvironment.isTop(bound)) {
      return false;
    }
    return true;
  }

  /// Returns true if type of [param] should be checked.
  bool _parameterNeedsTypeCheck(VariableDeclaration param,
      Map<VariableDeclaration, DartType>? forwardingParameterTypes) {
    if (canSkipTypeChecksForNonCovariantArguments &&
        !param.isCovariantByDeclaration &&
        !param.isCovariantByClass) {
      return false;
    }
    final DartType type = (forwardingParameterTypes != null)
        ? forwardingParameterTypes[param]!
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
      Map<TypeParameter, DartType>? forwardingBounds,
      Map<VariableDeclaration, DartType>? forwardingParamTypes) {
    for (var typeParam in function.typeParameters) {
      if (_typeParameterNeedsBoundCheck(typeParam, forwardingBounds)) {
        return true;
      }
    }
    for (var param in function.positionalParameters) {
      if (!param.isCovariantByDeclaration &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        return true;
      }
    }
    for (var param in locals.sortedNamedParameters) {
      if (!param.isCovariantByDeclaration &&
          _parameterNeedsTypeCheck(param, forwardingParamTypes)) {
        return true;
      }
    }
    return false;
  }

  void _genTypeParameterBoundCheck(TypeParameter typeParam,
      Map<TypeParameter, DartType>? forwardingTypeParameterBounds) {
    final DartType bound = (forwardingTypeParameterBounds != null)
        ? forwardingTypeParameterBounds[typeParam]!
        : typeParam.bound;
    final DartType type = new TypeParameterType(typeParam, Nullability.legacy);
    _genPushInstantiatorAndFunctionTypeArguments([type, bound]);
    asm.emitPushConstant(cp.addType(type));
    asm.emitPushConstant(cp.addType(bound));
    asm.emitPushConstant(cp.addName(typeParam.name!));
    asm.emitAssertSubtype();
  }

  void _genArgumentTypeCheck(VariableDeclaration variable,
      Map<VariableDeclaration, DartType>? forwardingParameterTypes) {
    final DartType type = (forwardingParameterTypes != null)
        ? forwardingParameterTypes[variable]!
        : variable.type;
    asm.emitPush(locals.getParamIndexInFrame(variable));
    _genAssertAssignable(type, name: variable.name);
    asm.emitDrop1();
  }

  void _genAssertAssignable(DartType type, {String? name, String? message}) {
    assert(!typeEnvironment.isTop(type));
    asm.emitPushConstant(cp.addType(type));
    _genPushInstantiatorAndFunctionTypeArguments([type]);
    asm.emitPushConstant(
        name != null ? cp.addName(name) : cp.addString(message!));
    bool isIntOk = typeEnvironment.isSubtypeOf(
        typeEnvironment.coreTypes.intNonNullableRawType,
        type,
        SubtypeCheckMode.ignoringNullabilities);
    int subtypeTestCacheCpIndex = cp.addSubtypeTestCache();
    asm.emitAssertAssignable(isIntOk ? 1 : 0, subtypeTestCacheCpIndex);
  }

  void _pushAssemblerState() {
    final savedAssemblers = this.savedAssemblers ??= <BytecodeAssembler>[];
    savedAssemblers.add(asm);
    asm = new BytecodeAssembler(options);
  }

  void _popAssemblerState() {
    asm = savedAssemblers!.removeLast();
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

    if (function.typeParameters.isNotEmpty) {
      final functionTypeParameters =
          this.functionTypeParameters ??= <TypeParameter>[];
      functionTypeParameters.addAll(function.typeParameters);
      functionTypeParametersSet = functionTypeParameters.toSet();
    }

    final closures = this.closures ??= <ClosureDeclaration>[];
    final int closureIndex = closures.length;
    final closure = getClosureDeclaration(node, function, name, closureIndex,
        savedIsClosure ? parentFunction! : enclosingMember!);
    closures.add(closure);

    final int closureFunctionIndex = cp.addClosureFunction(closureIndex);

    _recordSourcePosition(function.fileOffset);
    _genPrologue(node, function);

    _setupInitialContext(function);
    _emitFirstDebugCheck(function);
    _checkArguments(function);
    _initSuspendableFunction(function);

    _generateNode(function.body);

    // BytecodeAssembler eliminates this bytecode if it is unreachable.
    _recordSourcePosition(function.fileEndOffset);
    asm.emitPushNull();
    _genReturnTOS();

    if (options.emitLocalVarInfo) {
      // Leave the scopes which were entered in _genPrologue and
      // _setupInitialContext.
      asm.localVariableTable.leaveAllScopes(asm.offset, function.fileEndOffset);
    }

    cp.addEndClosureFunctionScope();

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters!.length -= function.typeParameters.length;
      functionTypeParametersSet = functionTypeParameters!.toSet();
    }

    enclosingFunction = parentFunction;
    parentFunction = savedParentFunction;
    isClosure = savedIsClosure;
    currentLoopDepth = savedLoopDepth;

    locals.leaveScope();

    closure.code = new ClosureCode(asm.bytecode, asm.exceptionsTable,
        finalizeSourcePositions(), finalizeLocalVariables());

    _popAssemblerState();

    return closureFunctionIndex;
  }

  ClosureDeclaration getClosureDeclaration(LocalFunction node,
      FunctionNode function, String name, int closureIndex, TreeNode parent) {
    objectTable.declareClosure(function, enclosingMember!, closureIndex);

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
      parameters.add(new NameAndType(objectTable.getPublicNameHandle(v.name!),
          objectTable.getHandle(v.type)!));
    }
    for (var v in function.namedParameters) {
      parameters.add(new NameAndType(objectTable.getPublicNameHandle(v.name!),
          objectTable.getHandle(v.type)!));
    }
    if (function.requiredParameterCount != parameters.length) {
      if (function.namedParameters.isNotEmpty) {
        flags |= ClosureDeclaration.hasOptionalNamedParamsFlag;
      } else {
        flags |= ClosureDeclaration.hasOptionalPositionalParamsFlag;
      }
    }

    TypeParametersDeclaration? typeParameters;
    if (function.typeParameters.isNotEmpty) {
      flags |= ClosureDeclaration.hasTypeParamsFlag;
      typeParameters = getTypeParametersDeclaration(function.typeParameters);
    }

    // We only need the required flags when loading the closure declaration.
    final parameterFlags =
        getParameterFlags(function, mask: ParameterDeclaration.isRequiredFlag);
    if (parameterFlags != null) {
      flags |= ClosureDeclaration.hasParameterFlagsFlag;
    }

    return new ClosureDeclaration(
        flags,
        objectTable.getHandle(parent)!,
        objectTable.getPublicNameHandle(name),
        position,
        endPosition,
        typeParameters,
        function.requiredParameterCount,
        function.namedParameters.length,
        parameters,
        parameterFlags,
        objectTable.getHandle(function.returnType)!);
  }

  void _genAllocateClosureInstance(
      TreeNode node, int closureFunctionIndex, FunctionNode function) {
    asm.emitPushConstant(closureFunctionIndex);
    asm.emitPush(locals.contextVarIndexInFrame);
    _genPushInstantiatorTypeArguments();
    asm.emitAllocateClosure();

    final int temp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(temp);

    if (locals.hasFunctionTypeArgsVar) {
      asm.emitPush(temp);
      _genPushFunctionTypeArguments();
      asm.emitStoreFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));
    }

    // Delayed type arguments are only used by generic closures.
    if (function.typeParameters.isNotEmpty) {
      asm.emitPush(temp);
      asm.emitPushConstant(cp.addEmptyTypeArguments());
      asm.emitStoreFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));
    }
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
    savedMaxSourcePositions!.add(maxSourcePosition);
    maxSourcePosition = fileOffset;
  }

  int _endRecordingMaxPosition() {
    int localMax = maxSourcePosition;
    maxSourcePosition =
        math.max(localMax, savedMaxSourcePositions!.removeLast());
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
  List<TryFinally> _getEnclosingTryFinallyBlocks(TreeNode from, TreeNode? to) {
    List<TryFinally> blocks = <TryFinally>[];
    TreeNode? node = from;
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
      finallyBlocks![tryFinally]!.add(finallyBlock);

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
          expr is DynamicSet ||
          expr is InstanceSet ||
          expr is StaticSet ||
          expr is SuperPropertySet);

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
      {bool storeLastArgumentToTemp = false}) {
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
        enclosingClass!.superclass!, noSuchMethodName)!;
    _genDirectCall(target, objectTable.getArgDescHandle(2), 2);
  }

  @override
  void defaultTreeNode(Node node) => throw new UnsupportedOperationError(
      'Unsupported node ${node.runtimeType}');

  @override
  void visitAsExpression(AsExpression node) {
    _generateNode(node.operand);

    final type = node.type;
    if (typeEnvironment.isTop(type)) {
      return;
    }

    _genAssertAssignable(type,
        message: node.isTypeError ? '' : symbolForTypeCast);
  }

  @override
  void visitBoolLiteral(BoolLiteral node) {
    _genPushBool(node.value);
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    _genPushInt(node.value);
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    final cpIndex = cp.addObjectRef(new DoubleConstant(node.value));
    asm.emitPushConstant(cpIndex);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
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
  void visitConstructorInvocation(ConstructorInvocation node) {
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
  void visitFunctionExpression(FunctionExpression node) {
    _genClosure(node, '<anonymous closure>', node.function);
  }

  @override
  void visitInstantiation(Instantiation node) {
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

    asm.emitPush(oldClosure);
    asm.emitLoadFieldTOS(cp.addInstanceField(closureFunction));
    asm.emitPush(oldClosure);
    asm.emitLoadFieldTOS(cp.addInstanceField(closureContext));
    asm.emitPush(oldClosure);
    asm.emitLoadFieldTOS(cp.addInstanceField(closureInstantiatorTypeArguments));
    asm.emitAllocateClosure();
    asm.emitStoreLocal(newClosure);

    asm.emitPush(typeArguments);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));

    asm.emitPush(newClosure);
    asm.emitPush(oldClosure);
    final closureFunctionTypeArgumentsCpIndex =
        cp.addInstanceField(closureFunctionTypeArguments);
    asm.emitLoadFieldTOS(closureFunctionTypeArgumentsCpIndex);
    asm.emitStoreFieldTOS(closureFunctionTypeArgumentsCpIndex);

    asm.emitPush(newClosure);
  }

  @override
  void visitIsExpression(IsExpression node) {
    _generateNode(node.operand);
    _genInstanceOf(node.type);
  }

  @override
  void visitLet(Let node) {
    _enterScope(node);
    _generateNode(node.variable);
    _generateNode(node.body);
    _leaveScope();
  }

  @override
  void visitListLiteral(ListLiteral node) {
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

    // _GrowableList._literal is a factory constructor.
    // Type arguments passed to a factory constructor are counted as a normal
    // argument and not counted in number of type arguments.
    assert(growableListLiteral.isFactory);
    _genDirectCall(growableListLiteral, objectTable.getArgDescHandle(2), 2);
  }

  @override
  void visitLogicalExpression(LogicalExpression node) {
    final Label shortCircuit = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);
    final isOR = (node.operatorEnum == LogicalExpressionOperator.OR);

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
  void visitMapLiteral(MapLiteral node) {
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
      Opcode opcode, InstanceInvocationExpression node) {
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
          Node node, Member? interfaceTarget, Expression receiver) =>
      isUncheckedCall(interfaceTarget, receiver, staticTypeContext);

  void _genInstanceCall(
      TreeNode node,
      InvocationKind invocationKind,
      Member? interfaceTarget,
      Name targetName,
      Expression receiver,
      int totalArgCount,
      ObjectHandle argDesc) {
    final isDynamic = interfaceTarget == null;
    final isUnchecked = invocationKind != InvocationKind.getter &&
        _isUncheckedCall(node, interfaceTarget, receiver);

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
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    _genMethodInvocation(node, null);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    _genMethodInvocation(node, node.interfaceTarget);
  }

  @override
  void visitEqualsCall(EqualsCall node) {
    _generateNode(node.left);
    _generateNode(node.right);
    final argDesc = objectTable.getArgDescHandle(2);
    _genInstanceCall(node, InvocationKind.method, coreTypes.objectEquals,
        Name('=='), node.left, 2, argDesc);
  }

  @override
  void visitEqualsNull(EqualsNull node) {
    _generateNode(node.expression);
    asm.emitSpecializedBytecode(Opcode.kEqualsNull);
  }

  void _genMethodInvocation(
      InstanceInvocationExpression node, Procedure? interfaceTarget) {
    final Opcode? opcode = recognizedMethods.specializedBytecodeFor(node);
    if (opcode != null) {
      _genMethodInvocationUsingSpecializedBytecode(opcode, node);
      return;
    }
    final args = node.arguments;
    final totalArgCount = args.positional.length +
        args.named.length +
        1 /* receiver */ +
        (args.types.isNotEmpty ? 1 : 0) /* type arguments */;
    if (totalArgCount >= argumentsLimit) {
      throw 'Too many arguments';
    }

    _genArguments(node.receiver, args);

    final argDesc =
        objectTable.getArgDescHandleByArguments(args, hasReceiver: true);

    _genInstanceCall(node, InvocationKind.method, interfaceTarget, node.name,
        node.receiver, totalArgCount, argDesc);
  }

  @override
  void visitFunctionInvocation(FunctionInvocation node) {
    final args = node.arguments;
    final totalArgCount = args.positional.length +
        args.named.length +
        1 /* receiver */ +
        (args.types.isNotEmpty ? 1 : 0) /* type arguments */;
    if (totalArgCount >= argumentsLimit) {
      throw 'Too many arguments';
    }
    // Front-end guarantees that all calls with known function type
    // do not need any argument type checks.
    if (node.kind == FunctionAccessKind.FunctionType) {
      final int receiverTemp = locals.tempIndexInFrame(node);
      _genArguments(node.receiver, args, storeReceiverToLocal: receiverTemp);
      // Duplicate receiver (closure) for UncheckedClosureCall.
      asm.emitPush(receiverTemp);
      final argDescCpIndex = cp.addArgDescByArguments(args, hasReceiver: true);
      asm.emitUncheckedClosureCall(argDescCpIndex, totalArgCount);
      return;
    }

    _genArguments(node.receiver, args);
    final argDesc =
        objectTable.getArgDescHandleByArguments(args, hasReceiver: true);
    _genInstanceCall(node, InvocationKind.method, null, Name.callName,
        node.receiver, totalArgCount, argDesc);
  }

  @override
  void visitLocalFunctionInvocation(LocalFunctionInvocation node) {
    final args = node.arguments;
    final totalArgCount = args.positional.length +
        args.named.length +
        1 /* receiver */ +
        (args.types.isNotEmpty ? 1 : 0) /* type arguments */;
    if (totalArgCount >= argumentsLimit) {
      throw 'Too many arguments';
    }

    if (args.types.isNotEmpty) {
      _genTypeArguments(args.types);
    }
    _genLoadVar(node.variable);
    _generateNodeList(args.positional);
    args.named.forEach((NamedExpression ne) => _generateNode(ne.value));

    // Duplicate receiver (closure) for UncheckedClosureCall.
    _genLoadVar(node.variable);
    final argDescCpIndex = cp.addArgDescByArguments(args, hasReceiver: true);
    asm.emitUncheckedClosureCall(argDescCpIndex, totalArgCount);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    _genPropertyGet(node, node.name, null, node.receiver);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    _genPropertyGet(node, node.name, node.interfaceTarget, node.receiver);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    _genPropertyGet(node, node.name, node.interfaceTarget, node.receiver);
  }

  void _genPropertyGet(Expression node, Name name, Member? interfaceTarget,
      Expression receiver) {
    _generateNode(receiver);
    final argDesc = objectTable.getArgDescHandle(1);

    _genInstanceCall(node, InvocationKind.getter, interfaceTarget, name,
        receiver, 1, argDesc);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    _genPropertySet(node, node.name, null, node.receiver, node.value);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    _genPropertySet(
        node, node.name, node.interfaceTarget, node.receiver, node.value);
  }

  void _genPropertySet(Expression node, Name name, Member? interfaceTarget,
      Expression receiver, Expression value) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(receiver);

    _generateNode(value);

    if (hasResult) {
      asm.emitStoreLocal(temp);
    }

    const int numArguments = 2;
    final argDesc = objectTable.getArgDescHandle(numArguments);

    _genInstanceCall(node, InvocationKind.setter, interfaceTarget, name,
        receiver, numArguments, argDesc);

    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    final args = node.arguments;
    final Member? target =
        hierarchy.getDispatchTarget(enclosingClass!.superclass!, node.name);
    if (target == null) {
      final int temp = locals.tempIndexInFrame(node);
      _genNoSuchMethodForSuperCall(
          node.name.text,
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
  void visitSuperPropertyGet(SuperPropertyGet node) {
    final Member? target =
        hierarchy.getDispatchTarget(enclosingClass!.superclass!, node.name);
    if (target == null) {
      final int temp = locals.tempIndexInFrame(node);
      _genNoSuchMethodForSuperCall(node.name.text, temp, cp.addArgDesc(1), [],
          <Expression>[new ThisExpression()]);
      return;
    }
    _genPushReceiver();
    _genDirectCall(target, objectTable.getArgDescHandle(1), 1,
        isGet: true, node: node);
  }

  @override
  void visitSuperPropertySet(SuperPropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    final Member? target = hierarchy.getDispatchTarget(
        enclosingClass!.superclass!, node.name,
        setter: true);
    if (target == null) {
      _genNoSuchMethodForSuperCall(node.name.text, temp, cp.addArgDesc(2), [],
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
  void visitNot(Not node) {
    bool negated = _genCondition(node.operand);
    if (!negated) {
      asm.emitBooleanNegateTOS();
    }
  }

  @override
  void visitNullCheck(NullCheck node) {
    _generateNode(node.operand);
    final operandTemp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(operandTemp);
    asm.emitPush(operandTemp);
    asm.emitNullCheck(cp.addObjectRef(null));
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    asm.emitPushNull();
  }

  @override
  void visitRethrow(Rethrow node) {
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
    tryCatches![tryCatch]!.needsStackTrace = true;

    if (options.emitDebuggerStops) {
      asm.emitDebugCheck(); // Allow breakpoint on explicit rethrow statement.
    }
    _genRethrow(tryCatch);
  }

  bool _hasNonTrivialInitializer(Field field) {
    if (field.initializer == null) return false;
    return !_isTrivialInitializer(field.initializer);
  }

  bool _isTrivialInitializer(Expression? initializer) {
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
  void visitStaticGet(StaticGet node) {
    final target = node.target;
    if (target is Field) {
      if (target.isConst) {
        _genPushConstExpr(target.initializer!);
      } else if (!_needsGetter(target)) {
        asm.emitLoadStatic(cp.addStaticField(target));
      } else {
        _genDirectCall(target, objectTable.getArgDescHandle(0), 0,
            isGet: true, node: node);
      }
    } else if (target is Procedure) {
      if (target.isGetter) {
        _genDirectCall(target, objectTable.getArgDescHandle(0), 0,
            isGet: true, node: node);
      } else {
        throw 'Unexpected target for StaticGet: ${target.runtimeType} $target';
      }
    } else {
      throw 'Unexpected target for StaticGet: ${target.runtimeType} $target';
    }
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
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
    if (target.isFactory) {
      final constructedClass = target.enclosingClass!;
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
  void visitStaticSet(StaticSet node) {
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
  void visitStringConcatenation(StringConcatenation node) {
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
  void visitStringLiteral(StringLiteral node) {
    final cpIndex = cp.addString(node.value);
    asm.emitPushConstant(cpIndex);
  }

  @override
  void visitSymbolLiteral(SymbolLiteral node) {
    _genPushConstExpr(node);
  }

  @override
  void visitThisExpression(ThisExpression node) {
    _genPushReceiver();
  }

  @override
  void visitThrow(Throw node) {
    _generateNode(node.expression);

    if (options.emitDebuggerStops) {
      asm.emitDebugCheck();
    }
    asm.emitThrow(0);
  }

  @override
  void visitTypeLiteral(TypeLiteral node) {
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
  void visitVariableGet(VariableGet node) {
    final v = node.variable;
    if (v.isConst) {
      _genPushConstExpr(v.initializer!);
    } else if (v.isLate) {
      _genLoadVar(v);

      final Label done = new Label();
      asm.emitJumpIfInitialized(done);

      final init = v.initializer;
      if (init != null) {
        _genPushContextIfCaptured(v);
        // Late local variable initializers are transformed to wrap the
        // initializer in a closure (see late_var_init_transformer.dart). The
        // closure call needs one temporary, so withTemp lets us use this
        // VariableGet's temporary when visiting the initializer.
        assert(init is LocalFunctionInvocation &&
            init.arguments.positional.isEmpty);
        locals.withTemp(
            init, locals.tempIndexInFrame(node), () => _generateNode(init));
        if (v.isFinal) {
          // Check that variable was not assigned during initialization.
          _genLoadVar(v);

          final error = Label();
          final store = Label();
          asm.emitJumpIfInitialized(error);
          asm.emitJump(store);

          asm.bind(error);
          asm.emitPushConstant(cp.addName(v.name!));
          _genDirectCall(throwLocalAssignedDuringInitialization,
              objectTable.getArgDescHandle(1), 1);
          asm.emitDrop1();

          asm.bind(store);
        }
        _genStoreVar(v);
      } else {
        asm.emitPushConstant(cp.addName(v.name!));
        _genDirectCall(
            throwLocalNotInitialized, objectTable.getArgDescHandle(1), 1);
        asm.emitDrop1();
      }

      asm.bind(done);
      _genLoadVar(v);
    } else {
      _genLoadVar(v);
    }
  }

  @override
  void visitVariableSet(VariableSet node) {
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
      asm.emitPushConstant(cp.addName(v.name!));
      _genDirectCall(
          throwLocalAlreadyInitialized, objectTable.getArgDescHandle(1), 1);
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
  void visitLoadLibrary(LoadLibrary node) {
    _genFutureNull();
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    _genFutureNull();
  }

  @override
  void visitAssertStatement(AssertStatement node) {
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
  void visitBlock(Block node) {
    _enterScope(node);
    _generateNodeList(node.statements);
    _leaveScope();
  }

  @override
  void visitAssertBlock(AssertBlock node) {
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
  void visitBlockExpression(BlockExpression node) {
    _enterScope(node);
    _generateNodeList(node.body.statements);
    _generateNode(node.value);
    _leaveScope();
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    final targetLabel = labeledStatements?[node.target] ??
        (throw 'Target label ${node.target} was not registered for break $node');
    final targetContextLevel = contextLevels![node.target]!;

    _generateNonLocalControlTransfer(node, node.target, () {
      _genUnwindContext(targetContextLevel);
      asm.emitJump(targetLabel);
    });
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    final targetLabel = switchCases?[node.target] ??
        (throw 'Target label ${node.target} was not registered for continue-switch $node');
    final targetContextLevel = contextLevels![node.target.parent]!;

    _generateNonLocalControlTransfer(node, node.target.parent!, () {
      _genUnwindContext(targetContextLevel);
      asm.emitJump(targetLabel);
    });
  }

  @override
  void visitDoStatement(DoStatement node) {
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
  void visitEmptyStatement(EmptyStatement node) {
    // no-op
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    final expr = node.expression;
    _generateNode(expr);
    if (!isExpressionWithoutResult(expr)) {
      asm.emitDrop1();
    }
  }

  @override
  void visitForInStatement(ForInStatement node) {
    // Should be lowered by the async transformation.
    throw "unreachable";
  }

  @override
  void visitForStatement(ForStatement node) {
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

      final condition = node.condition;
      if (condition != null) {
        _genConditionAndJumpIf(condition, false, done);
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
  void visitFunctionDeclaration(ast.FunctionDeclaration node) {
    if (options.emitDebuggerStops) {
      asm.emitDebugCheck();
    }
    _genPushContextIfCaptured(node.variable);
    _genClosure(node, node.variable.name!, node.function);
    _genStoreVar(node.variable);
  }

  @override
  void visitIfStatement(IfStatement node) {
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
  void visitLabeledStatement(LabeledStatement node) {
    final label = new Label();
    final labeledStatements =
        this.labeledStatements ??= <LabeledStatement, Label>{};
    labeledStatements[node] = label;
    final contextLevels = this.contextLevels ??= <TreeNode, int>{};
    contextLevels[node] = locals.currentContextLevel;
    _generateNode(node.body);
    asm.bind(label);
    labeledStatements.remove(node);
    contextLevels.remove(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
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
  void visitSwitchStatement(SwitchStatement node) {
    final contextLevels = this.contextLevels ??= <TreeNode, int>{};
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

    final switchCases = this.switchCases ??= <SwitchCase, Label>{};

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
    asm.emitPush(locals.contextVarIndexInFrame);
    asm.emitPopLocal(_savedContextVar(node));
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
  void visitTryCatch(TryCatch node) {
    if (asm.isUnreachable) {
      return;
    }

    final Label done = new Label();

    final TryBlock tryBlock = _startTryBlock(node);
    tryBlock.isSynthetic = node.isSynthetic;
    final tryCatches = this.tryCatches ??= <TryCatch, TryBlock>{};
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

      Label? skipCatch;
      final guardType = catchClause.guard;
      // Exception objects are guaranteed to be non-nullable, so
      // non-nullable Object is also a catch-all type.
      if (guardType is DynamicType ||
          (guardType is InterfaceType &&
              guardType.classNode == coreTypes.objectClass)) {
        hasCatchAll = true;
      } else {
        asm.emitPush(exception);
        _genInstanceOf(catchClause.guard);

        skipCatch = new Label();
        asm.emitJumpIfFalse(skipCatch);
      }

      _enterScope(catchClause);

      final exceptionVar = catchClause.exception;
      if (exceptionVar != null) {
        _genPushContextIfCaptured(exceptionVar);
        asm.emitPush(exception);
        _genStoreVar(exceptionVar);
      }

      final stackTraceVar = catchClause.stackTrace;
      if (stackTraceVar != null) {
        tryBlock.needsStackTrace = true;
        _genPushContextIfCaptured(stackTraceVar);
        asm.emitPush(stackTrace);
        _genStoreVar(stackTraceVar);
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
  void visitTryFinally(TryFinally node) {
    if (asm.isUnreachable) {
      return;
    }

    final TryBlock tryBlock = _startTryBlock(node);
    tryBlock.isSynthetic = true;
    final finallyBlocks =
        this.finallyBlocks ??= <TryFinally, List<FinallyBlock>>{};
    finallyBlocks[node] = <FinallyBlock>[];

    _generateNode(node.body);

    if (!asm.isUnreachable) {
      final normalContinuation = new FinallyBlock(() {
        /* do nothing (fall through) */
      });
      finallyBlocks[node]!.add(normalContinuation);
      asm.emitJump(normalContinuation.entry);
    }

    _endTryBlock(node, tryBlock);

    tryBlock.types.add(cp.addType(const DynamicType()));

    _generateNode(node.finalizer);

    tryBlock.needsStackTrace = true; // For rethrowing.
    _genRethrow(node);

    for (var finallyBlock in finallyBlocks[node]!) {
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
  void visitVariableDeclaration(VariableDeclaration node) {
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
  void visitWhileStatement(WhileStatement node) {
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
  void visitFieldInitializer(FieldInitializer node) {
    _genFieldInitializer(node.field, node.value);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    _genArguments(new ThisExpression(), args);
    _genDirectCallWithArgs(node.target, args, hasReceiver: true, node: node);
    asm.emitDrop1();
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    _genArguments(new ThisExpression(), args);
    // Re-resolve target due to partial mixin resolution.
    Member? target;
    for (var replacement in enclosingClass!.superclass!.constructors) {
      if (node.target.name == replacement.name) {
        target = replacement;
        break;
      }
    }
    _genDirectCallWithArgs(target!, args, hasReceiver: true, node: node);
    asm.emitDrop1();
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    _generateNode(node.variable);
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    _generateNode(node.statement);
  }

  @override
  void visitConstantExpression(ConstantExpression node) {
    _genPushConstant(node.constant);
  }

  @override
  void visitRecordIndexGet(RecordIndexGet node) {
    _generateNode(node.receiver);
    asm.emitLoadRecordField(node.index);
  }

  @override
  void visitRecordNameGet(RecordNameGet node) {
    final type = node.receiverType;
    final namedFields = type.named;
    final name = node.name;
    int fieldIndex = -1;
    for (int i = 0; i < namedFields.length; ++i) {
      if (namedFields[i].name == name) {
        fieldIndex = type.positional.length + i;
        break;
      }
    }
    if (fieldIndex < 0) {
      throw 'Unable to find record field "$name" in $type';
    }
    _generateNode(node.receiver);
    asm.emitLoadRecordField(fieldIndex);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    assert(!node.isConst);
    for (final expr in node.positional) {
      _generateNode(expr);
    }
    for (final expr in node.named) {
      _generateNode(expr.value);
    }
    asm.emitAllocateRecord(cp.addType(node.recordType));
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _generateNode(node.operand);

    final int temp = locals.tempIndexInFrame(node);
    asm.emitPopLocal(temp);

    Label done = Label();
    asm.emitSuspend(done);

    final runtimeCheckType = node.runtimeCheckType;
    if (runtimeCheckType != null) {
      assert((runtimeCheckType as InterfaceType).classNode ==
          coreTypes.futureClass);
      _genTypeArguments((runtimeCheckType as InterfaceType).typeArguments);
      asm.emitPush(locals.suspendStateVarIndexInFrame);
      asm.emitPush(temp);
      _genDirectCall(
          _awaitWithTypeCheck, objectTable.getArgDescHandle(2, 1), 3);
    } else {
      asm.emitPush(locals.suspendStateVarIndexInFrame);
      asm.emitPush(temp);
      _genDirectCall(_await, objectTable.getArgDescHandle(2), 2);
    }
    asm.emitReturnTOS();

    asm.bind(done);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    asm.emitPush(locals.suspendStateVarIndexInFrame);
    _genDirectCall(
        suspendStateFunctionData, objectTable.getArgDescHandle(1), 1);

    _generateNode(node.expression);

    if (enclosingFunction!.dartAsyncMarker == AsyncMarker.AsyncStar) {
      Procedure addMethod = node.isYieldStar
          ? asyncStarStreamControllerAddStream
          : asyncStarStreamControllerAdd;
      _genDirectCall(addMethod, objectTable.getArgDescHandle(2), 2);

      Label ret = Label(allowsBackwardJumps: true);
      asm.emitJumpIfTrue(ret);

      Label resume = Label();
      asm.emitSuspend(resume);
      asm.emitPush(locals.suspendStateVarIndexInFrame);
      asm.emitPushNull();
      _genDirectCall(yieldAsyncStar, objectTable.getArgDescHandle(2), 2);
      asm.emitDrop1();

      asm.bind(ret);
      asm.emitPushNull();
      asm.emitReturnTOS();

      asm.bind(resume);
      asm.emitJumpIfTrue(ret);
    } else if (enclosingFunction!.dartAsyncMarker == AsyncMarker.SyncStar) {
      Field field = node.isYieldStar
          ? syncStarIteratorYieldStarIterable
          : syncStarIteratorCurrent;
      asm.emitStoreFieldTOS(cp.addInstanceField(field));

      Label done = Label();
      asm.emitSuspend(done);
      asm.emitPushTrue();
      asm.emitReturnTOS();

      asm.bind(done);
      asm.emitDrop1();
    } else {
      throw 'Unexpected ${enclosingFunction!.dartAsyncMarker}';
    }
  }

  void _unimplemented(TreeNode node, String what) {
    print('Unimplemented $what at ${node.location}');
    asm.emitTrap();
    asm.isUnreachable = false;
  }
}

class UnsupportedOperationError {
  final String message;
  UnsupportedOperationError(this.message);

  @override
  String toString() => message;
}

typedef GenerateContinuation = void Function();

class FinallyBlock {
  final Label entry = new Label();
  final GenerateContinuation generateContinuation;

  FinallyBlock(this.generateContinuation);
}

class Annotations {
  final AnnotationsDeclaration? object;
  final bool hasPragma;

  const Annotations(this.object, this.hasPragma);
}
