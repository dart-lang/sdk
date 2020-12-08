// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:front_end/src/fasta/dill/dill_member_builder.dart';
import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:kernel/ast.dart';

import 'package:kernel/type_algebra.dart';

import '../kernel/class_hierarchy_builder.dart';
import '../kernel/forest.dart';
import '../kernel/internal_ast.dart';
import '../kernel/member_covariance.dart';
import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import '../loader.dart' show Loader;

import '../messages.dart'
    show messageConstFactoryRedirectionToNonConst, noLength;

import '../problems.dart' show unexpected, unhandled;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';

import 'builder.dart';
import 'constructor_reference_builder.dart';
import 'extension_builder.dart';
import 'formal_parameter_builder.dart';
import 'function_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'library_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ProcedureBuilder implements FunctionBuilder {
  int get charOpenParenOffset;

  ProcedureBuilder get patchForTesting;

  AsyncMarker actualAsyncModifier;

  Procedure get procedure;

  ProcedureKind get kind;

  Procedure get actualProcedure;

  @override
  ProcedureBuilder get origin;

  void set asyncModifier(AsyncMarker newModifier);

  bool get isEligibleForTopLevelInference;

  /// Returns `true` if this procedure is declared in an extension declaration.
  bool get isExtensionMethod;
}

abstract class ProcedureBuilderImpl extends FunctionBuilderImpl
    implements ProcedureBuilder {
  final Procedure _procedure;

  @override
  final int charOpenParenOffset;

  @override
  final ProcedureKind kind;

  @override
  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  ProcedureBuilder actualOrigin;

  @override
  Procedure get actualProcedure => _procedure;

  final bool isExtensionInstanceMember;

  ProcedureBuilderImpl(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      this.kind,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      Procedure referenceFrom,
      this.isExtensionInstanceMember,
      [String nativeMethodName])
      : _procedure = new Procedure(
            null, isExtensionInstanceMember ? ProcedureKind.Method : kind, null,
            fileUri: compilationUnit.fileUri,
            reference: referenceFrom?.reference)
          ..startFileOffset = startCharOffset
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset
          ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  ProcedureBuilder get origin => actualOrigin ?? this;

  @override
  ProcedureBuilder get patchForTesting => dataForTesting?.patchForTesting;

  @override
  AsyncMarker get asyncModifier => actualAsyncModifier;

  @override
  Statement get body {
    if (bodyInternal == null && !isAbstract && !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  @override
  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    if (function != null) {
      // No parent, it's an enum.
      function.asyncMarker = actualAsyncModifier;
      function.dartAsyncMarker = actualAsyncModifier;
    }
  }

  @override
  bool get isEligibleForTopLevelInference {
    if (isDeclarationInstanceMember) {
      if (returnType == null) return true;
      if (formals != null) {
        for (FormalParameterBuilder formal in formals) {
          if (formal.type == null) return true;
        }
      }
    }
    return false;
  }

  @override
  bool get isExtensionMethod {
    return parent is ExtensionBuilder;
  }

  @override
  Procedure get procedure => isPatch ? origin.procedure : _procedure;

  @override
  Member get member => procedure;

  @override
  void becomeNative(Loader loader) {
    _procedure.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is ProcedureBuilderImpl) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
        dataForTesting?.patchForTesting = patch;
      }
    } else {
      reportPatchMismatch(patch);
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.procedure.fileUri = fileUri;
    origin.procedure.startFileOffset = _procedure.startFileOffset;
    origin.procedure.fileOffset = _procedure.fileOffset;
    origin.procedure.fileEndOffset = _procedure.fileEndOffset;
    origin.procedure.annotations
        .forEach((m) => m.fileOffset = _procedure.fileOffset);

    origin.procedure.isAbstract = _procedure.isAbstract;
    origin.procedure.isExternal = _procedure.isExternal;
    origin.procedure.function = _procedure.function;
    origin.procedure.function.parent = origin.procedure;
    return 1;
  }
}

class SourceProcedureBuilder extends ProcedureBuilderImpl {
  final Procedure _tearOffReferenceFrom;

  /// If this is an extension instance method then [_extensionTearOff] holds
  /// the synthetically created tear off function.
  Procedure _extensionTearOff;

  /// If this is an extension instance method then
  /// [_extensionTearOffParameterMap] holds a map from the parameters of
  /// the methods to the parameter of the closure returned in the tear-off.
  ///
  /// This map is used to set the default values on the closure parameters when
  /// these have been built.
  Map<VariableDeclaration, VariableDeclaration> _extensionTearOffParameterMap;

  SourceProcedureBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      Procedure referenceFrom,
      this._tearOffReferenceFrom,
      AsyncMarker asyncModifier,
      bool isExtensionInstanceMember,
      [String nativeMethodName])
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            kind,
            compilationUnit,
            startCharOffset,
            charOffset,
            charOpenParenOffset,
            charEndOffset,
            referenceFrom,
            isExtensionInstanceMember,
            nativeMethodName) {
    this.asyncModifier = asyncModifier;
  }

  bool _typeEnsured = false;
  Set<ClassMember> _overrideDependencies;

  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.classBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _overrideDependencies ??= {};
    _overrideDependencies.addAll(overriddenMembers);
  }

  void _ensureTypes(ClassHierarchyBuilder hierarchy) {
    if (_typeEnsured) return;
    if (_overrideDependencies != null) {
      if (isGetter) {
        hierarchy.inferGetterType(this, _overrideDependencies);
      } else if (isSetter) {
        hierarchy.inferSetterType(this, _overrideDependencies);
      } else {
        hierarchy.inferMethodType(this, _overrideDependencies);
      }
      _overrideDependencies = null;
    }
    _typeEnsured = true;
  }

  @override
  Member get readTarget {
    switch (kind) {
      case ProcedureKind.Method:
        return extensionTearOff ?? procedure;
      case ProcedureKind.Getter:
        return procedure;
      case ProcedureKind.Operator:
      case ProcedureKind.Setter:
      case ProcedureKind.Factory:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Member get writeTarget {
    switch (kind) {
      case ProcedureKind.Setter:
        return procedure;
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Member get invokeTarget {
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return procedure;
      case ProcedureKind.Setter:
        return null;
    }
    throw unhandled('ProcedureKind', '$kind', charOffset, fileUri);
  }

  @override
  Iterable<Member> get exportedMembers => [procedure];

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    if (isExtensionMethod) {
      switch (kind) {
        case ProcedureKind.Method:
          f(member, BuiltMemberKind.ExtensionMethod);
          break;
        case ProcedureKind.Getter:
          f(member, BuiltMemberKind.ExtensionGetter);
          break;
        case ProcedureKind.Setter:
          f(member, BuiltMemberKind.ExtensionSetter);
          break;
        case ProcedureKind.Operator:
          f(member, BuiltMemberKind.ExtensionOperator);
          break;
        case ProcedureKind.Factory:
          throw new UnsupportedError(
              'Unexpected extension method kind ${kind}');
      }
      if (extensionTearOff != null) {
        f(extensionTearOff, BuiltMemberKind.ExtensionTearOff);
      }
    } else {
      f(member, BuiltMemberKind.Method);
    }
  }

  @override
  Procedure build(SourceLibraryBuilder libraryBuilder) {
    // TODO(ahe): I think we may call this twice on parts. Investigate.
    if (_procedure.name == null) {
      _procedure.function = buildFunction(libraryBuilder);
      _procedure.function.parent = _procedure;
      _procedure.function.fileOffset = charOpenParenOffset;
      _procedure.function.fileEndOffset = _procedure.fileEndOffset;
      _procedure.isAbstract = isAbstract;
      _procedure.isExternal = isExternal;
      _procedure.isConst = isConst;
      if (isExtensionMethod) {
        ExtensionBuilder extensionBuilder = parent;
        _procedure.isExtensionMember = true;
        _procedure.isStatic = true;
        if (isExtensionInstanceMember) {
          assert(_procedure.kind == ProcedureKind.Method);
        }
        _procedure.name = new Name(
            createProcedureName(true, !isExtensionInstanceMember, kind,
                extensionBuilder.name, name),
            libraryBuilder.library);
      } else {
        _procedure.isStatic = isStatic;
        _procedure.name = new Name(name, libraryBuilder.library);
      }
      if (extensionTearOff != null) {
        _buildExtensionTearOff(libraryBuilder, parent);
      }
    }
    return _procedure;
  }

  static String createProcedureName(bool isExtensionMethod, bool isStatic,
      ProcedureKind kind, String extensionName, String name) {
    if (isExtensionMethod) {
      String kindInfix = '';
      if (!isStatic) {
        // Instance getter and setter are converted to methods so we use an
        // infix to make their names unique.
        switch (kind) {
          case ProcedureKind.Getter:
            kindInfix = 'get#';
            break;
          case ProcedureKind.Setter:
            kindInfix = 'set#';
            break;
          case ProcedureKind.Method:
          case ProcedureKind.Operator:
            kindInfix = '';
            break;
          case ProcedureKind.Factory:
            throw new UnsupportedError(
                'Unexpected extension method kind ${kind}');
        }
      }
      return '${extensionName}|${kindInfix}${name}';
    } else {
      return name;
    }
  }

  /// Creates a top level function that creates a tear off of an extension
  /// instance method.
  ///
  /// For this declaration
  ///
  ///     extension E<T> on A<T> {
  ///       X method<S>(S s, Y y) {}
  ///     }
  ///
  /// we create the top level function
  ///
  ///     X E|method<T, S>(A<T> #this, S s, Y y) {}
  ///
  /// and the tear off function
  ///
  ///     X Function<S>(S, Y) E|get#method<T>(A<T> #this) {
  ///       return (S s, Y y) => E|method<T, S>(#this, s, y);
  ///     }
  ///
  void _buildExtensionTearOff(
      SourceLibraryBuilder libraryBuilder, ExtensionBuilder extensionBuilder) {
    assert(
        _extensionTearOff != null, "No extension tear off created for $this.");
    if (_extensionTearOff.name != null) return;

    _extensionTearOffParameterMap = {};

    int fileOffset = _procedure.fileOffset;
    int fileEndOffset = _procedure.fileEndOffset;

    int extensionTypeParameterCount =
        extensionBuilder.typeParameters?.length ?? 0;

    List<TypeParameter> typeParameters = <TypeParameter>[];

    Map<TypeParameter, DartType> substitutionMap = {};
    List<DartType> typeArguments = <DartType>[];
    for (TypeParameter typeParameter in function.typeParameters) {
      TypeParameter newTypeParameter = new TypeParameter(typeParameter.name);
      typeParameters.add(newTypeParameter);
      typeArguments.add(substitutionMap[typeParameter] =
          new TypeParameterType.forAlphaRenaming(
              typeParameter, newTypeParameter));
    }

    List<TypeParameter> tearOffTypeParameters = <TypeParameter>[];
    List<TypeParameter> closureTypeParameters = <TypeParameter>[];
    Substitution substitution = Substitution.fromMap(substitutionMap);
    for (int index = 0; index < typeParameters.length; index++) {
      TypeParameter newTypeParameter = typeParameters[index];
      newTypeParameter.bound =
          substitution.substituteType(function.typeParameters[index].bound);
      newTypeParameter.defaultType = function.typeParameters[index].defaultType;
      if (index < extensionTypeParameterCount) {
        tearOffTypeParameters.add(newTypeParameter);
      } else {
        closureTypeParameters.add(newTypeParameter);
      }
    }

    VariableDeclaration copyParameter(
        VariableDeclaration parameter, DartType type,
        {bool isOptional}) {
      VariableDeclaration newParameter = new VariableDeclaration(parameter.name,
          type: type,
          isFinal: parameter.isFinal,
          isLowered: parameter.isLowered)
        ..fileOffset = parameter.fileOffset;
      _extensionTearOffParameterMap[parameter] = newParameter;
      return newParameter;
    }

    VariableDeclaration extensionThis = copyParameter(
        function.positionalParameters.first,
        substitution.substituteType(function.positionalParameters.first.type),
        isOptional: false);

    DartType closureReturnType =
        substitution.substituteType(function.returnType);
    List<VariableDeclaration> closurePositionalParameters = [];
    List<Expression> closurePositionalArguments = [];

    for (int position = 0;
        position < function.positionalParameters.length;
        position++) {
      VariableDeclaration parameter = function.positionalParameters[position];
      if (position == 0) {
        /// Pass `this` as a captured variable.
        closurePositionalArguments
            .add(new VariableGet(extensionThis)..fileOffset = fileOffset);
      } else {
        DartType type = substitution.substituteType(parameter.type);
        VariableDeclaration newParameter = copyParameter(parameter, type,
            isOptional: position >= function.requiredParameterCount);
        closurePositionalParameters.add(newParameter);
        closurePositionalArguments
            .add(new VariableGet(newParameter)..fileOffset = fileOffset);
      }
    }
    List<VariableDeclaration> closureNamedParameters = [];
    List<NamedExpression> closureNamedArguments = [];
    for (VariableDeclaration parameter in function.namedParameters) {
      DartType type = substitution.substituteType(parameter.type);
      VariableDeclaration newParameter =
          copyParameter(parameter, type, isOptional: true);
      closureNamedParameters.add(newParameter);
      closureNamedArguments.add(new NamedExpression(parameter.name,
          new VariableGet(newParameter)..fileOffset = fileOffset));
    }

    Statement closureBody = new ReturnStatement(
        new StaticInvocation(
            _procedure,
            new Arguments(closurePositionalArguments,
                types: typeArguments, named: closureNamedArguments))
          ..fileOffset = fileOffset)
      ..fileOffset = fileOffset;

    FunctionExpression closure = new FunctionExpression(
        new FunctionNode(closureBody,
            typeParameters: closureTypeParameters,
            positionalParameters: closurePositionalParameters,
            namedParameters: closureNamedParameters,
            requiredParameterCount:
                _procedure.function.requiredParameterCount - 1,
            returnType: closureReturnType)
          ..fileOffset = fileOffset
          ..fileEndOffset = fileEndOffset)
      ..fileOffset = fileOffset;

    _extensionTearOff
      ..name = new Name(
          '${extensionBuilder.name}|get#${name}', libraryBuilder.library)
      ..function = (new FunctionNode(
          new ReturnStatement(closure)..fileOffset = fileOffset,
          typeParameters: tearOffTypeParameters,
          positionalParameters: [extensionThis],
          requiredParameterCount: 1,
          returnType: closure.function.computeFunctionType(library.nonNullable))
        ..fileOffset = fileOffset
        ..fileEndOffset = fileEndOffset)
      ..fileUri = fileUri
      ..fileOffset = fileOffset
      ..fileEndOffset = fileEndOffset;
    _extensionTearOff.function.parent = _extensionTearOff;
  }

  Procedure get extensionTearOff {
    if (isExtensionInstanceMember && kind == ProcedureKind.Method) {
      _extensionTearOff ??= new Procedure(null, ProcedureKind.Method, null,
          isStatic: true,
          isExtensionMember: true,
          reference: _tearOffReferenceFrom?.reference)
        ..isNonNullableByDefault = library.isNonNullableByDefault;
    }
    return _extensionTearOff;
  }

  @override
  VariableDeclaration getExtensionTearOffParameter(int index) {
    if (_extensionTearOffParameterMap != null) {
      return _extensionTearOffParameterMap[getFormalParameter(index)];
    }
    return null;
  }

  List<ClassMember> _localMembers;
  List<ClassMember> _localSetters;

  @override
  List<ClassMember> get localMembers => _localMembers ??= isSetter
      ? const <ClassMember>[]
      : <ClassMember>[new SourceProcedureMember(this)];

  @override
  List<ClassMember> get localSetters => _localSetters ??= isSetter
      ? <ClassMember>[new SourceProcedureMember(this)]
      : const <ClassMember>[];
}

class SourceProcedureMember extends BuilderClassMember {
  @override
  final SourceProcedureBuilder memberBuilder;

  Covariance _covariance;

  SourceProcedureMember(this.memberBuilder);

  @override
  bool get isSourceDeclaration => true;

  @override
  void inferType(ClassHierarchyBuilder hierarchy) {
    memberBuilder._ensureTypes(hierarchy);
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    memberBuilder.registerOverrideDependency(overriddenMembers);
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    memberBuilder._ensureTypes(hierarchy);
    return memberBuilder.member;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    return _covariance ??=
        new Covariance.fromMember(getMember(hierarchy), forSetter: forSetter);
  }

  @override
  bool get forSetter => isSetter;

  @override
  bool get isProperty =>
      memberBuilder.kind == ProcedureKind.Getter ||
      memberBuilder.kind == ProcedureKind.Setter;

  @override
  bool get isFunction => !isProperty;

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is SourceProcedureMember &&
        memberBuilder == other.memberBuilder;
  }
}

class RedirectingFactoryBuilder extends ProcedureBuilderImpl {
  final ConstructorReferenceBuilder redirectionTarget;
  List<DartType> typeArguments;

  RedirectingFactoryBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      Procedure referenceFrom,
      [String nativeMethodName,
      this.redirectionTarget])
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            ProcedureKind.Factory,
            compilationUnit,
            startCharOffset,
            charOffset,
            charOpenParenOffset,
            charEndOffset,
            referenceFrom,
            /* isExtensionInstanceMember = */ false,
            nativeMethodName);

  @override
  Member get readTarget => null;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => procedure;

  @override
  Iterable<Member> get exportedMembers => [procedure];

  @override
  Statement get body => bodyInternal;

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

    bodyInternal = new RedirectingFactoryBody(target, typeArguments);
    function.body = bodyInternal;
    bodyInternal?.parent = function;
    if (isPatch) {
      if (function.typeParameters != null) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullabilityForLibrary(
                  actualOrigin.function.typeParameters[i], library.library);
        }
        List<DartType> newTypeArguments =
            new List<DartType>.filled(typeArguments.length, null);
        for (int i = 0; i < newTypeArguments.length; i++) {
          newTypeArguments[i] = substitute(typeArguments[i], substitution);
        }
        typeArguments = newTypeArguments;
      }
      actualOrigin.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    f(member, BuiltMemberKind.RedirectingFactory);
  }

  @override
  Procedure build(SourceLibraryBuilder libraryBuilder) {
    // TODO(ahe): I think we may call this twice on parts. Investigate.
    if (_procedure.name == null) {
      _procedure.function = buildFunction(libraryBuilder);
      _procedure.function.parent = _procedure;
      _procedure.function.fileOffset = charOpenParenOffset;
      _procedure.function.fileEndOffset = _procedure.fileEndOffset;
      _procedure.isAbstract = isAbstract;
      _procedure.isExternal = isExternal;
      _procedure.isConst = isConst;
      _procedure.isStatic = isStatic;
      _procedure.name = new Name(name, libraryBuilder.library);
    }
    _procedure.isRedirectingFactoryConstructor = true;
    if (redirectionTarget.typeArguments != null) {
      typeArguments = new List<DartType>.filled(
          redirectionTarget.typeArguments.length, null);
      for (int i = 0; i < typeArguments.length; i++) {
        typeArguments[i] = redirectionTarget.typeArguments[i].build(library);
      }
    }
    return _procedure;
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    super.buildOutlineExpressions(library, coreTypes);
    LibraryBuilder thisLibrary = this.library;
    if (thisLibrary is SourceLibraryBuilder) {
      RedirectingFactoryBody redirectingFactoryBody = procedure.function.body;
      if (redirectingFactoryBody.typeArguments != null &&
          redirectingFactoryBody.typeArguments.any((t) => t is UnknownType)) {
        TypeInferrerImpl inferrer = thisLibrary.loader.typeInferenceEngine
            .createLocalTypeInferrer(
                fileUri, classBuilder.thisType, thisLibrary, null);
        inferrer.helper = thisLibrary.loader
            .createBodyBuilderForOutlineExpression(
                this.library, classBuilder, this, classBuilder.scope, fileUri);
        Builder targetBuilder = redirectionTarget.target;
        Member target;
        if (targetBuilder is FunctionBuilder) {
          target = targetBuilder.member;
        } else if (targetBuilder is DillMemberBuilder) {
          target = targetBuilder.member;
        } else {
          unhandled("${targetBuilder.runtimeType}", "buildOutlineExpressions",
              charOffset, fileUri);
        }
        Arguments targetInvocationArguments;
        {
          List<Expression> positionalArguments = <Expression>[];
          for (VariableDeclaration parameter
              in member.function.positionalParameters) {
            inferrer.flowAnalysis?.declare(parameter, true);
            positionalArguments.add(new VariableGetImpl(
                parameter,
                inferrer.typePromoter.getFactForAccess(parameter, 0),
                inferrer.typePromoter.currentScope,
                forNullGuardedAccess: false));
          }
          List<NamedExpression> namedArguments = <NamedExpression>[];
          for (VariableDeclaration parameter
              in member.function.namedParameters) {
            inferrer.flowAnalysis?.declare(parameter, true);
            namedArguments.add(new NamedExpression(
                parameter.name,
                new VariableGetImpl(
                    parameter,
                    inferrer.typePromoter.getFactForAccess(parameter, 0),
                    inferrer.typePromoter.currentScope,
                    forNullGuardedAccess: false)));
          }
          // If arguments are created using [Forest.createArguments], and the
          // type arguments are omitted, they are to be inferred.
          targetInvocationArguments = const Forest().createArguments(
              member.fileOffset, positionalArguments,
              named: namedArguments);
        }
        InvocationInferenceResult result = inferrer.inferInvocation(
            function.returnType,
            charOffset,
            target.function.computeFunctionType(Nullability.nonNullable),
            targetInvocationArguments,
            staticTarget: target);
        List<DartType> typeArguments;
        if (result.inferredType is InterfaceType) {
          typeArguments = (result.inferredType as InterfaceType).typeArguments;
        } else {
          // Assume that the error is reported elsewhere, use 'dynamic' for
          // recovery.
          typeArguments = new List<DartType>.filled(
              target.enclosingClass.typeParameters.length, const DynamicType(),
              growable: true);
        }
        member.function.body =
            new RedirectingFactoryBody(target, typeArguments);
      }
    }
  }

  @override
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    super.finishPatch();

    if (origin is RedirectingFactoryBuilder) {
      RedirectingFactoryBuilder redirectingOrigin = origin;
      redirectingOrigin.typeArguments = typeArguments;
    }

    return 1;
  }
}
