// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

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
import 'source_class_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceFunctionBuilderImpl {
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  final bool isExtensionInstanceMember = false;

  @override
  final TypeBuilder returnType;

  final Procedure _procedureInternal;
  final Procedure? _factoryTearOff;

  SourceFactoryBuilder? actualOrigin;

  List<SourceFactoryBuilder>? _patches;

  SourceFactoryBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      this.returnType,
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
        super(metadata, modifiers, name, typeVariables, formals, libraryBuilder,
            charOffset, nativeMethodName) {
    this.asyncModifier = asyncModifier;
  }

  List<SourceFactoryBuilder>? get patchesForTesting => _patches;

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
  void buildMembers(void Function(Member, BuiltMemberKind) f) {
    Member member = build();
    f(member, BuiltMemberKind.Method);
    if (_factoryTearOff != null) {
      f(_factoryTearOff!, BuiltMemberKind.Method);
    }
  }

  @override
  Procedure build() {
    buildFunction();
    _procedureInternal.function.fileOffset = charOpenParenOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = isAbstract;
    _procedureInternal.isExternal = isExternal;
    _procedureInternal.isConst = isConst;
    updatePrivateMemberName(_procedureInternal, libraryBuilder);
    _procedureInternal.isStatic = isStatic;

    if (_factoryTearOff != null) {
      buildConstructorTearOffProcedure(
          tearOff: _factoryTearOff!,
          declarationConstructor: _procedure,
          implementationConstructor: _procedureInternal,
          enclosingClass: classBuilder!.cls,
          libraryBuilder: libraryBuilder);
    }
    return _procedureInternal;
  }

  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
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
        (_patches ??= []).add(patch);
      }
    } else {
      reportPatchMismatch(patch);
    }
  }

  void _finishPatch() {
    finishProcedurePatch(origin._procedure, _procedureInternal);

    if (_factoryTearOff != null) {
      finishProcedurePatch(origin._factoryTearOff!, _factoryTearOff!);
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;
    _finishPatch();
    return 1;
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInFunctionBuilder(this, typeEnvironment);
    List<SourceFactoryBuilder>? patches = _patches;
    if (patches != null) {
      for (SourceFactoryBuilder patch in patches) {
        patch.checkTypes(library, typeEnvironment);
      }
    }
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
      libraryBuilder.addProblem(messageConstFactoryRedirectionToNonConst,
          charOffset, noLength, fileUri);
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
                  actualOrigin!.function.typeParameters[i],
                  libraryBuilder.library);
        }
        typeArguments = new List<DartType>.generate(typeArguments.length,
            (int i) => substitute(typeArguments[i], substitution),
            growable: false);
      }
      actualOrigin!.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  void buildMembers(void Function(Member, BuiltMemberKind) f) {
    Member member = build();
    f(member, BuiltMemberKind.RedirectingFactory);
    if (_factoryTearOff != null) {
      f(_factoryTearOff!, BuiltMemberKind.Method);
    }
  }

  @override
  Procedure build() {
    buildFunction();
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
          (int i) => redirectionTarget.typeArguments![i]
              .build(libraryBuilder, TypeUse.redirectionTypeArgument),
          growable: false);
    }
    updatePrivateMemberName(_procedureInternal, libraryBuilder);
    if (_factoryTearOff != null) {
      _tearOffTypeParameters =
          buildRedirectingFactoryTearOffProcedureParameters(
              tearOff: _factoryTearOff!,
              implementationConstructor: _procedureInternal,
              libraryBuilder: libraryBuilder);
    }
    return _procedureInternal;
  }

  @override
  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    if (isConst && isPatch) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    }
    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    RedirectingFactoryBody redirectingFactoryBody =
        _procedureInternal.function.body as RedirectingFactoryBody;
    List<DartType>? typeArguments = redirectingFactoryBody.typeArguments;
    Member? target = redirectingFactoryBody.target;
    if (typeArguments != null && typeArguments.any((t) => t is UnknownType)) {
      TypeInferrer inferrer = libraryBuilder.loader.typeInferenceEngine
          .createLocalTypeInferrer(
              fileUri, classBuilder!.thisType, libraryBuilder, null);
      inferrer.helper = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, classBuilder, this, classBuilder!.scope, fileUri);
      Builder? targetBuilder = redirectionTarget.target;
      if (targetBuilder is SourceMemberBuilder) {
        // Ensure that target has been built.
        targetBuilder.buildOutlineExpressions(classHierarchy,
            delayedActionPerformers, delayedDefaultValueCloners);
      }
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

    Set<Procedure> seenTargets = {};
    while (target is Procedure && target.isRedirectingFactory) {
      if (!seenTargets.add(target)) {
        // Cyclic dependency.
        target = null;
        break;
      }
      RedirectingFactoryBody body =
          target.function.body as RedirectingFactoryBody;
      if (typeArguments != null) {
        Substitution substitution = Substitution.fromPairs(
            target.function.typeParameters, typeArguments);
        typeArguments =
            body.typeArguments?.map(substitution.substituteType).toList();
      } else {
        typeArguments = body.typeArguments;
      }
      target = body.target;
    }

    if (target is Constructor || target is Procedure && target.isFactory) {
      typeArguments ??= [];
      if (_factoryTearOff != null) {
        delayedDefaultValueCloners.add(buildRedirectingFactoryTearOffBody(
            _factoryTearOff!,
            target!,
            typeArguments,
            _tearOffTypeParameters!,
            libraryBuilder));
      }
      Map<TypeParameter, DartType> substitutionMap;
      if (function.typeParameters.length == typeArguments.length) {
        substitutionMap = new Map<TypeParameter, DartType>.fromIterables(
            function.typeParameters, typeArguments);
      } else {
        // Error case: Substitute type parameters with `dynamic`.
        substitutionMap = new Map<TypeParameter, DartType>.fromIterables(
            function.typeParameters,
            new List<DartType>.generate(function.typeParameters.length,
                (int index) => const DynamicType()));
      }
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          target!, _procedure, substitutionMap,
          libraryBuilder: libraryBuilder, identicalSignatures: false));
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

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInRedirectingFactoryBuilder(this, typeEnvironment);
  }
}
