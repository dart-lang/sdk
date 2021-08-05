// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../kernel/class_hierarchy_builder.dart';
import '../kernel/kernel_api.dart';
import '../kernel/member_covariance.dart';

import '../loader.dart' show Loader;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'builder.dart';
import 'extension_builder.dart';
import 'formal_parameter_builder.dart';
import 'function_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ProcedureBuilder implements FunctionBuilder {
  int get charOpenParenOffset;

  ProcedureBuilder? get patchForTesting;

  AsyncMarker get actualAsyncModifier;

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

class SourceProcedureBuilder extends FunctionBuilderImpl
    implements ProcedureBuilder {
  @override
  final int charOpenParenOffset;

  @override
  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  final bool isExtensionInstanceMember;

  late Procedure _procedure;

  final Reference? _tearOffReference;

  /// If this is an extension instance method then [_extensionTearOff] holds
  /// the synthetically created tear off function.
  Procedure? _extensionTearOff;

  /// If this is an extension instance method then
  /// [_extensionTearOffParameterMap] holds a map from the parameters of
  /// the methods to the parameter of the closure returned in the tear-off.
  ///
  /// This map is used to set the default values on the closure parameters when
  /// these have been built.
  Map<VariableDeclaration, VariableDeclaration>? _extensionTearOffParameterMap;

  @override
  final ProcedureKind kind;

  SourceProcedureBuilder? actualOrigin;

  SourceProcedureBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder? returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      this.kind,
      SourceLibraryBuilder libraryBuilder,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      Reference? procedureReference,
      this._tearOffReference,
      AsyncMarker asyncModifier,
      ProcedureNameScheme procedureNameScheme,
      {required bool isExtensionMember,
      required bool isInstanceMember,
      String? nativeMethodName})
      // ignore: unnecessary_null_comparison
      : assert(isExtensionMember != null),
        // ignore: unnecessary_null_comparison
        assert(isInstanceMember != null),
        assert(kind != ProcedureKind.Factory),
        this.isExtensionInstanceMember = isInstanceMember && isExtensionMember,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            libraryBuilder, charOffset, nativeMethodName) {
    _procedure = new Procedure(
        procedureNameScheme.getName(kind, name),
        isExtensionInstanceMember ? ProcedureKind.Method : kind,
        new FunctionNode(null),
        fileUri: libraryBuilder.fileUri,
        reference: procedureReference)
      ..startFileOffset = startCharOffset
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = libraryBuilder.isNonNullableByDefault;
    this.asyncModifier = asyncModifier;
    if (isExtensionMember && isInstanceMember && kind == ProcedureKind.Method) {
      _extensionTearOff ??= new Procedure(
          procedureNameScheme.getName(ProcedureKind.Getter, name),
          ProcedureKind.Method,
          new FunctionNode(null),
          isStatic: true,
          isExtensionMember: true,
          reference: _tearOffReference,
          fileUri: fileUri)
        ..isNonNullableByDefault = library.isNonNullableByDefault;
    }
  }

  @override
  ProcedureBuilder? get patchForTesting =>
      dataForTesting?.patchForTesting as ProcedureBuilder?;

  @override
  AsyncMarker get asyncModifier => actualAsyncModifier;

  @override
  Statement? get body {
    if (bodyInternal == null && !isAbstract && !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  @override
  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    function.asyncMarker = actualAsyncModifier;
    function.dartAsyncMarker = actualAsyncModifier;
  }

  @override
  bool get isEligibleForTopLevelInference {
    if (isDeclarationInstanceMember) {
      if (returnType == null) return true;
      if (formals != null) {
        for (FormalParameterBuilder formal in formals!) {
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
  Member get member => procedure;

  @override
  SourceProcedureBuilder get origin => actualOrigin ?? this;

  @override
  Procedure get procedure => isPatch ? origin.procedure : _procedure;

  @override
  Procedure get actualProcedure => _procedure;

  @override
  FunctionNode get function => _procedure.function;

  bool _typeEnsured = false;
  Set<ClassMember>? _overrideDependencies;

  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.classBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _overrideDependencies ??= {};
    _overrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes(ClassHierarchyBuilder hierarchy) {
    if (_typeEnsured) return;
    if (_overrideDependencies != null) {
      if (isGetter) {
        hierarchy.inferGetterType(this, _overrideDependencies!);
      } else if (isSetter) {
        hierarchy.inferSetterType(this, _overrideDependencies!);
      } else {
        hierarchy.inferMethodType(this, _overrideDependencies!);
      }
      _overrideDependencies = null;
    }
    _typeEnsured = true;
  }

  @override
  Member? get readTarget {
    switch (kind) {
      case ProcedureKind.Method:
        return extensionTearOff ?? procedure;
      case ProcedureKind.Getter:
        return procedure;
      case ProcedureKind.Factory:
        return procedure;
      case ProcedureKind.Operator:
      case ProcedureKind.Setter:
    }
  }

  @override
  Member? get writeTarget {
    switch (kind) {
      case ProcedureKind.Setter:
        return procedure;
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return null;
    }
  }

  @override
  Member? get invokeTarget {
    switch (kind) {
      case ProcedureKind.Method:
      case ProcedureKind.Getter:
      case ProcedureKind.Operator:
      case ProcedureKind.Factory:
        return procedure;
      case ProcedureKind.Setter:
        return null;
    }
  }

  @override
  Iterable<Member> get exportedMembers => [procedure];

  @override
  void buildMembers(
      SourceLibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
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
        f(extensionTearOff!, BuiltMemberKind.ExtensionTearOff);
      }
    } else {
      f(member, BuiltMemberKind.Method);
    }
  }

  @override
  Procedure build(SourceLibraryBuilder libraryBuilder) {
    buildFunction(libraryBuilder);
    _procedure.function.fileOffset = charOpenParenOffset;
    _procedure.function.fileEndOffset = _procedure.fileEndOffset;
    _procedure.isAbstract = isAbstract;
    _procedure.isExternal = isExternal;
    _procedure.isConst = isConst;
    updatePrivateMemberName(_procedure, libraryBuilder);
    if (isExtensionMethod) {
      _procedure.isExtensionMember = true;
      _procedure.isStatic = true;
      if (isExtensionInstanceMember) {
        assert(_procedure.kind == ProcedureKind.Method);
      }
    } else {
      _procedure.isStatic = isStatic;
    }
    if (extensionTearOff != null) {
      _buildExtensionTearOff(libraryBuilder, parent as ExtensionBuilder);
      updatePrivateMemberName(extensionTearOff!, libraryBuilder);
    }
    return _procedure;
  }

  static String createProcedureName(bool isExtensionMethod, bool isStatic,
      ProcedureKind kind, String? extensionName, String name) {
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
        {required bool isOptional}) {
      VariableDeclaration newParameter = new VariableDeclaration(parameter.name,
          type: type,
          isFinal: parameter.isFinal,
          isLowered: parameter.isLowered)
        ..fileOffset = parameter.fileOffset;
      _extensionTearOffParameterMap![parameter] = newParameter;
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
      closureNamedArguments.add(new NamedExpression(parameter.name!,
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

    _extensionTearOff!
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
    _extensionTearOff!.function.parent = _extensionTearOff;
  }

  Procedure? get extensionTearOff => _extensionTearOff;

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _extensionTearOffParameterMap?[getFormalParameter(index)];
  }

  List<ClassMember>? _localMembers;
  List<ClassMember>? _localSetters;

  @override
  List<ClassMember> get localMembers => _localMembers ??= isSetter
      ? const <ClassMember>[]
      : <ClassMember>[new SourceProcedureMember(this)];

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= isSetter && !isConflictingSetter
          ? <ClassMember>[new SourceProcedureMember(this)]
          : const <ClassMember>[];

  @override
  void becomeNative(Loader loader) {
    _procedure.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceProcedureBuilder) {
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
    origin.procedure.isRedirectingFactory = _procedure.isRedirectingFactory;
    return 1;
  }
}

class SourceProcedureMember extends BuilderClassMember {
  @override
  final SourceProcedureBuilder memberBuilder;

  Covariance? _covariance;

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
  bool isSameDeclaration(ClassMember other) {
    return other is SourceProcedureMember &&
        memberBuilder == other.memberBuilder;
  }
}

class ProcedureNameScheme {
  final bool isExtensionMember;
  final bool isStatic;
  final String? extensionName;
  final Reference libraryReference;

  ProcedureNameScheme(
      {required this.isExtensionMember,
      required this.isStatic,
      this.extensionName,
      required this.libraryReference})
      // ignore: unnecessary_null_comparison
      : assert(isExtensionMember != null),
        // ignore: unnecessary_null_comparison
        assert(isStatic != null),
        // ignore: unnecessary_null_comparison
        assert(!isExtensionMember || extensionName != null),
        // ignore: unnecessary_null_comparison
        assert(libraryReference != null);

  Name getName(ProcedureKind kind, String name) {
    // ignore: unnecessary_null_comparison
    assert(kind != null);
    return new Name.byReference(
        SourceProcedureBuilder.createProcedureName(
            isExtensionMember, isStatic, kind, extensionName, name),
        libraryReference);
  }
}
