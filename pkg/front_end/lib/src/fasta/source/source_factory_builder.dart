// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';

import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../dill/dill_member_builder.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/forest.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/redirecting_factory_body.dart'
    show getRedirectingFactoryBody, RedirectingFactoryBody;
import '../messages.dart'
    show messageConstFactoryRedirectionToNonConst, noLength;
import '../problems.dart' show unexpected, unhandled;
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';
import '../util/helpers.dart';
import 'name_scheme.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceFunctionBuilderImpl {
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  final bool isExtensionInstanceMember = false;

  final Procedure _procedureInternal;
  final Procedure? _factoryTearOff;

  SourceFactoryBuilder? actualOrigin;

  SourceFactoryBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder>? formals,
      SourceLibraryBuilder libraryBuilder,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      Reference? procedureReference,
      Reference? tearOffReference,
      AsyncMarker asyncModifier,
      NameScheme nameScheme,
      {String? nativeMethodName})
      : _procedureInternal = new Procedure(
            nameScheme.getProcedureName(ProcedureKind.Factory, name),
            ProcedureKind.Factory,
            new FunctionNode(null),
            fileUri: libraryBuilder.fileUri,
            reference: procedureReference)
          ..startFileOffset = startCharOffset
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset
          ..isNonNullableByDefault = libraryBuilder.isNonNullableByDefault,
        _factoryTearOff = createFactoryTearOffProcedure(name, libraryBuilder,
            libraryBuilder.fileUri, charOffset, tearOffReference),
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            libraryBuilder, charOffset, nativeMethodName) {
    this.asyncModifier = asyncModifier;
  }

  SourceFactoryBuilder? get patchForTesting =>
      dataForTesting?.patchForTesting as SourceFactoryBuilder?;

  @override
  AsyncMarker get asyncModifier => actualAsyncModifier;

  @override
  Statement? get body {
    if (bodyInternal == null && !isAbstract && !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    function.asyncMarker = actualAsyncModifier;
    function.dartAsyncMarker = actualAsyncModifier;
  }

  @override
  Member get member => _procedure;

  @override
  SourceFactoryBuilder get origin => actualOrigin ?? this;

  @override
  ProcedureKind get kind => ProcedureKind.Factory;

  Procedure get _procedure => isPatch ? origin._procedure : _procedureInternal;

  @override
  FunctionNode get function => _procedureInternal.function;

  @override
  Member? get readTarget => origin._factoryTearOff ?? _procedure;

  @override
  Member? get writeTarget => null;

  @override
  Member? get invokeTarget => _procedure;

  @override
  Iterable<Member> get exportedMembers => [_procedure];

  @override
  void buildMembers(
      SourceLibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    f(member, BuiltMemberKind.Method);
    if (_factoryTearOff != null) {
      f(_factoryTearOff!, BuiltMemberKind.Method);
    }
  }

  @override
  Procedure build(SourceLibraryBuilder libraryBuilder) {
    buildFunction(libraryBuilder);
    _procedureInternal.function.fileOffset = charOpenParenOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = isAbstract;
    _procedureInternal.isExternal = isExternal;
    _procedureInternal.isConst = isConst;
    updatePrivateMemberName(_procedureInternal, libraryBuilder);
    _procedureInternal.isStatic = isStatic;

    if (_factoryTearOff != null) {
      buildConstructorTearOffProcedure(_factoryTearOff!, _procedureInternal,
          classBuilder!.cls, libraryBuilder);
    }
    return _procedureInternal;
  }

  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    if (_hasBuiltOutlines) return;
    super.buildOutlineExpressions(library, classHierarchy,
        delayedActionPerformers, synthesizedFunctionNodes);
    _hasBuiltOutlines = true;
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    if (_factoryTearOff != null) {
      if (index < _factoryTearOff!.function.positionalParameters.length) {
        return _factoryTearOff!.function.positionalParameters[index];
      } else {
        index -= _factoryTearOff!.function.positionalParameters.length;
        if (index < _factoryTearOff!.function.namedParameters.length) {
          return _factoryTearOff!.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  @override
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  void becomeNative(SourceLoader loader) {
    _procedureInternal.isExternal = true;
    super.becomeNative(loader);
  }

  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", charOffset, fileUri);
    }
    bodyInternal = new RedirectingFactoryBody(target, typeArguments, function);
    function.body = bodyInternal;
    bodyInternal?.parent = function;
    if (isPatch) {
      actualOrigin!.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceFactoryBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
        dataForTesting?.patchForTesting = patch;
      }
    } else {
      reportPatchMismatch(patch);
    }
  }

  void _finishPatch() {
    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin._procedure.fileUri = fileUri;
    origin._procedure.startFileOffset = _procedureInternal.startFileOffset;
    origin._procedure.fileOffset = _procedureInternal.fileOffset;
    origin._procedure.fileEndOffset = _procedureInternal.fileEndOffset;
    origin._procedure.annotations
        .forEach((m) => m.fileOffset = _procedureInternal.fileOffset);

    origin._procedure.isAbstract = _procedureInternal.isAbstract;
    origin._procedure.isExternal = _procedureInternal.isExternal;
    origin._procedure.function = _procedureInternal.function;
    origin._procedure.function.parent = origin._procedure;
    origin._procedure.isRedirectingFactory =
        _procedureInternal.isRedirectingFactory;
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;
    _finishPatch();
    return 1;
  }
}

class RedirectingFactoryBuilder extends SourceFactoryBuilder {
  final ConstructorReferenceBuilder redirectionTarget;
  List<DartType>? typeArguments;

  FreshTypeParameters? _tearOffTypeParameters;

  RedirectingFactoryBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder>? formals,
      SourceLibraryBuilder libraryBuilder,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      Reference? procedureReference,
      Reference? tearOffReference,
      NameScheme nameScheme,
      String? nativeMethodName,
      this.redirectionTarget)
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            libraryBuilder,
            startCharOffset,
            charOffset,
            charOpenParenOffset,
            charEndOffset,
            procedureReference,
            tearOffReference,
            AsyncMarker.Sync,
            nameScheme,
            nativeMethodName: nativeMethodName);

  @override
  Statement? get body => bodyInternal;

  @override
  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", charOffset, fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (isConst && !target.isConst) {
      library.addProblem(messageConstFactoryRedirectionToNonConst, charOffset,
          noLength, fileUri);
    }

    bodyInternal = new RedirectingFactoryBody(target, typeArguments, function);
    function.body = bodyInternal;
    bodyInternal?.parent = function;
    _procedure.isRedirectingFactory = true;
    if (isPatch) {
      // ignore: unnecessary_null_comparison
      if (function.typeParameters != null) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullabilityForLibrary(
                  actualOrigin!.function.typeParameters[i], library.library);
        }
        typeArguments = new List<DartType>.generate(typeArguments.length,
            (int i) => substitute(typeArguments[i], substitution),
            growable: false);
      }
      actualOrigin!.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  void buildMembers(
      SourceLibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    f(member, BuiltMemberKind.RedirectingFactory);
    if (_factoryTearOff != null) {
      f(_factoryTearOff!, BuiltMemberKind.Method);
    }
  }

  @override
  Procedure build(SourceLibraryBuilder libraryBuilder) {
    buildFunction(libraryBuilder);
    _procedureInternal.function.fileOffset = charOpenParenOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = isAbstract;
    _procedureInternal.isExternal = isExternal;
    _procedureInternal.isConst = isConst;
    _procedureInternal.isStatic = isStatic;
    _procedureInternal.isRedirectingFactory = true;
    if (redirectionTarget.typeArguments != null) {
      typeArguments = new List<DartType>.generate(
          redirectionTarget.typeArguments!.length,
          (int i) => redirectionTarget.typeArguments![i].build(library),
          growable: false);
    }
    updatePrivateMemberName(_procedureInternal, libraryBuilder);
    if (_factoryTearOff != null) {
      _tearOffTypeParameters =
          buildRedirectingFactoryTearOffProcedureParameters(
              _factoryTearOff!, _procedureInternal, libraryBuilder);
    }
    return _procedureInternal;
  }

  @override
  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    if (_hasBuiltOutlines) return;
    if (isConst && isPatch) {
      origin.buildOutlineExpressions(library, classHierarchy,
          delayedActionPerformers, synthesizedFunctionNodes);
    }
    super.buildOutlineExpressions(library, classHierarchy,
        delayedActionPerformers, synthesizedFunctionNodes);
    RedirectingFactoryBody redirectingFactoryBody =
        _procedureInternal.function.body as RedirectingFactoryBody;
    List<DartType>? typeArguments = redirectingFactoryBody.typeArguments;
    Member? target = redirectingFactoryBody.target;
    if (typeArguments != null && typeArguments.any((t) => t is UnknownType)) {
      TypeInferrerImpl inferrer = library.loader.typeInferenceEngine
              .createLocalTypeInferrer(
                  fileUri, classBuilder!.thisType, library, null)
          as TypeInferrerImpl;
      inferrer.helper = library.loader.createBodyBuilderForOutlineExpression(
          library, classBuilder, this, classBuilder!.scope, fileUri);
      Builder? targetBuilder = redirectionTarget.target;
      if (targetBuilder is FunctionBuilder) {
        target = targetBuilder.member;
      } else if (targetBuilder is DillMemberBuilder) {
        target = targetBuilder.member;
      } else {
        unhandled("${targetBuilder.runtimeType}", "buildOutlineExpressions",
            charOffset, fileUri);
      }
      ArgumentsImpl targetInvocationArguments;
      {
        List<Expression> positionalArguments = <Expression>[];
        for (VariableDeclaration parameter
            in _procedure.function.positionalParameters) {
          inferrer.flowAnalysis.declare(parameter, true);
          positionalArguments
              .add(new VariableGetImpl(parameter, forNullGuardedAccess: false));
        }
        List<NamedExpression> namedArguments = <NamedExpression>[];
        for (VariableDeclaration parameter
            in _procedure.function.namedParameters) {
          inferrer.flowAnalysis.declare(parameter, true);
          namedArguments.add(new NamedExpression(parameter.name!,
              new VariableGetImpl(parameter, forNullGuardedAccess: false)));
        }
        // If arguments are created using [Forest.createArguments], and the
        // type arguments are omitted, they are to be inferred.
        targetInvocationArguments = const Forest().createArguments(
            _procedure.fileOffset, positionalArguments,
            named: namedArguments);
      }
      InvocationInferenceResult result = inferrer.inferInvocation(
          function.returnType,
          charOffset,
          target.function!.computeFunctionType(Nullability.nonNullable),
          targetInvocationArguments,
          staticTarget: target);
      if (result.inferredType is InterfaceType) {
        typeArguments = (result.inferredType as InterfaceType).typeArguments;
      } else {
        // Assume that the error is reported elsewhere, use 'dynamic' for
        // recovery.
        typeArguments = new List<DartType>.filled(
            target.enclosingClass!.typeParameters.length, const DynamicType(),
            growable: true);
      }

      function.body =
          new RedirectingFactoryBody(target, typeArguments, function);
      function.body!.parent = function;
    }
    if (_factoryTearOff != null &&
        (target is Constructor || target is Procedure && target.isFactory)) {
      synthesizedFunctionNodes.add(buildRedirectingFactoryTearOffBody(
          _factoryTearOff!,
          target!,
          typeArguments ?? [],
          _tearOffTypeParameters!));
    }
    if (isConst && isPatch) {
      _finishPatch();
    }
    _hasBuiltOutlines = true;
  }

  @override
  void _finishPatch() {
    super._finishPatch();

    SourceFactoryBuilder redirectingOrigin = origin;
    if (redirectingOrigin is RedirectingFactoryBuilder) {
      redirectingOrigin.typeArguments = typeArguments;
    }
  }

  List<DartType>? getTypeArguments() {
    return getRedirectingFactoryBody(_procedure)!.typeArguments;
  }
}
