// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/kernel/body_builder_context.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/augmentation_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../source/name_scheme.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart' show SourceLoader;
import 'source_builder_mixins.dart';
import 'source_class_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_function_builder.dart';
import 'source_member_builder.dart';

class SourceProcedureBuilder extends SourceFunctionBuilderImpl
    implements ProcedureBuilder {
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  final bool isExtensionInstanceMember;

  @override
  final bool isExtensionTypeInstanceMember;

  @override
  final TypeBuilder returnType;

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

  /// The builder for the original declaration.
  SourceProcedureBuilder? _origin;

  /// If this builder is a patch or an augmentation, this is the builder for
  /// the immediately augmented procedure.
  SourceProcedureBuilder? _augmentedBuilder;

  int _augmentationIndex = 0;

  List<SourceProcedureBuilder>? _patches;

  final MemberName _memberName;

  SourceProcedureBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      this.returnType,
      String name,
      List<NominalVariableBuilder>? typeVariables,
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
      NameScheme nameScheme,
      {String? nativeMethodName,
      bool isSynthetic = false})
      : assert(kind != ProcedureKind.Factory),
        this.isExtensionInstanceMember =
            nameScheme.isInstanceMember && nameScheme.isExtensionMember,
        this.isExtensionTypeInstanceMember =
            nameScheme.isInstanceMember && nameScheme.isExtensionTypeMember,
        _memberName = nameScheme.getDeclaredName(name),
        super(metadata, modifiers, name, typeVariables, formals, libraryBuilder,
            charOffset, nativeMethodName) {
    _procedure = new Procedure(
        dummyName,
        isExtensionInstanceMember || isExtensionTypeInstanceMember
            ? ProcedureKind.Method
            : kind,
        new FunctionNode(null),
        fileUri: libraryBuilder.fileUri,
        reference: procedureReference,
        isSynthetic: isSynthetic)
      ..fileStartOffset = startCharOffset
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = libraryBuilder.isNonNullableByDefault;
    nameScheme.getProcedureMemberName(kind, name).attachMember(_procedure);
    this.asyncModifier = asyncModifier;
    if ((isExtensionInstanceMember || isExtensionTypeInstanceMember) &&
        kind == ProcedureKind.Method) {
      _extensionTearOff = new Procedure(
          dummyName, ProcedureKind.Method, new FunctionNode(null),
          isStatic: true,
          isExtensionMember: isExtensionInstanceMember,
          isExtensionTypeMember: isExtensionTypeInstanceMember,
          reference: _tearOffReference,
          fileUri: fileUri)
        ..isNonNullableByDefault = libraryBuilder.isNonNullableByDefault;
      nameScheme
          .getProcedureMemberName(ProcedureKind.Getter, name)
          .attachMember(_extensionTearOff!);
    }
  }

  @override
  Name get memberName => _memberName.name;

  List<SourceProcedureBuilder>? get patchesForTesting => _patches;

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

  bool get isExtensionMethod {
    return parent is SourceExtensionBuilder;
  }

  bool get isExtensionTypeMethod {
    return parent is SourceExtensionTypeDeclarationBuilder;
  }

  @override
  Member get member => procedure;

  @override
  SourceProcedureBuilder get origin => _origin ?? this;

  @override
  Procedure get procedure => isPatch ? origin.procedure : _procedure;

  Procedure get actualProcedure => _procedure;

  Procedure? _augmentedProcedure;

  @override
  FunctionNode get function => _procedure.function;

  bool _typeEnsured = false;
  Set<ClassMember>? _overrideDependencies;

  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.declarationBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _overrideDependencies ??= {};
    _overrideDependencies!.addAll(overriddenMembers);
  }

  void _ensureTypes(ClassMembersBuilder membersBuilder) {
    if (_typeEnsured) return;
    if (_overrideDependencies != null) {
      if (isGetter) {
        membersBuilder.inferGetterType(this, _overrideDependencies!);
      } else if (isSetter) {
        membersBuilder.inferSetterType(this, _overrideDependencies!);
      } else {
        membersBuilder.inferMethodType(this, _overrideDependencies!);
      }
      _overrideDependencies = null;
    }
    returnType.build(libraryBuilder, TypeUse.fieldType,
        hierarchy: membersBuilder.hierarchyBuilder);
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        formal.type.build(libraryBuilder, TypeUse.parameterType,
            hierarchy: membersBuilder.hierarchyBuilder);
      }
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
        return null;
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
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    if (isExtensionMethod) {
      switch (kind) {
        case ProcedureKind.Method:
          f(
              member: _procedure,
              tearOff: extensionTearOff,
              kind: BuiltMemberKind.ExtensionMethod);
          break;
        case ProcedureKind.Getter:
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          f(member: _procedure, kind: BuiltMemberKind.ExtensionGetter);
          break;
        case ProcedureKind.Setter:
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          f(member: _procedure, kind: BuiltMemberKind.ExtensionSetter);
          break;
        case ProcedureKind.Operator:
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          f(member: _procedure, kind: BuiltMemberKind.ExtensionOperator);
          break;
        case ProcedureKind.Factory:
          throw new UnsupportedError(
              'Unexpected extension method kind ${kind}');
      }
    } else if (isExtensionTypeMethod) {
      switch (kind) {
        case ProcedureKind.Method:
          f(
              member: _procedure,
              tearOff: extensionTearOff,
              kind: BuiltMemberKind.ExtensionTypeMethod);
          break;
        case ProcedureKind.Getter:
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          f(member: _procedure, kind: BuiltMemberKind.ExtensionTypeGetter);
          break;
        case ProcedureKind.Setter:
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          f(member: _procedure, kind: BuiltMemberKind.ExtensionTypeSetter);
          break;
        case ProcedureKind.Operator:
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          f(member: _procedure, kind: BuiltMemberKind.ExtensionTypeOperator);
          break;
        case ProcedureKind.Factory:
          f(
              member: _procedure,
              tearOff: extensionTearOff,
              kind: BuiltMemberKind.ExtensionTypeFactory);
          break;
      }
    } else {
      f(member: member, kind: BuiltMemberKind.Method);
    }
  }

  void _build() {
    buildFunction();
    _procedure.function.fileOffset = charOpenParenOffset;
    _procedure.function.fileEndOffset = _procedure.fileEndOffset;
    _procedure.isAbstract = isAbstract;
    _procedure.isExternal = isExternal;
    _procedure.isConst = isConst;
    if (isExtensionMethod) {
      _procedure.isExtensionMember = true;
      _procedure.isStatic = true;
      if (isExtensionInstanceMember) {
        assert(_procedure.kind == ProcedureKind.Method);
      }
    } else if (isExtensionTypeMethod) {
      _procedure.isExtensionTypeMember = true;
      _procedure.isStatic = true;
      if (isExtensionTypeInstanceMember) {
        assert(_procedure.kind == ProcedureKind.Method);
      }
    } else {
      _procedure.isStatic = isStatic;
    }
    if (extensionTearOff != null) {
      _buildExtensionTearOff(
          libraryBuilder, parent as SourceDeclarationBuilderMixin);
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
  void _buildExtensionTearOff(SourceLibraryBuilder sourceLibraryBuilder,
      SourceDeclarationBuilderMixin declarationBuilder) {
    assert(
        _extensionTearOff != null, "No extension tear off created for $this.");

    _extensionTearOffParameterMap = {};

    int fileOffset = _procedure.fileOffset;
    int fileEndOffset = _procedure.fileEndOffset;

    int extensionTypeParameterCount =
        declarationBuilder.typeParameters?.length ?? 0;

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
        VariableDeclaration parameter, DartType type) {
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
        substitution.substituteType(function.positionalParameters.first.type));

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
        VariableDeclaration newParameter = copyParameter(parameter, type);
        closurePositionalParameters.add(newParameter);
        closurePositionalArguments
            .add(new VariableGet(newParameter)..fileOffset = fileOffset);
      }
    }
    List<VariableDeclaration> closureNamedParameters = [];
    List<NamedExpression> closureNamedArguments = [];
    for (VariableDeclaration parameter in function.namedParameters) {
      DartType type = substitution.substituteType(parameter.type);
      VariableDeclaration newParameter = copyParameter(parameter, type);
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
          returnType:
              closure.function.computeFunctionType(libraryBuilder.nonNullable))
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
      : <ClassMember>[
          new SourceProcedureMember(
              this, isGetter ? ClassMemberKind.Getter : ClassMemberKind.Method)
        ];

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= isSetter && !isConflictingSetter
          ? <ClassMember>[
              new SourceProcedureMember(this, ClassMemberKind.Setter)
            ]
          : const <ClassMember>[];

  @override
  void becomeNative(SourceLoader loader) {
    _procedure.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceProcedureBuilder) {
      if (checkPatch(patch)) {
        patch._origin = this;
        SourceProcedureBuilder augmentedBuilder =
            _patches == null ? this : _patches!.last;
        patch._augmentedBuilder = augmentedBuilder;
        patch._augmentationIndex = augmentedBuilder._augmentationIndex + 1;
        (_patches ??= []).add(patch);
      }
    } else {
      reportPatchMismatch(patch);
    }
  }

  Map<SourceProcedureBuilder, AugmentSuperTarget?> _augmentedProcedures = {};

  AugmentSuperTarget? _createAugmentSuperTarget(
      SourceProcedureBuilder? targetBuilder) {
    if (targetBuilder == null) return null;
    Procedure declaredProcedure = targetBuilder.actualProcedure;

    if (declaredProcedure.isAbstract || declaredProcedure.isExternal) {
      return targetBuilder._augmentedBuilder != null
          ? _getAugmentSuperTarget(targetBuilder._augmentedBuilder!)
          : null;
    }

    Procedure augmentedProcedure =
        targetBuilder._augmentedProcedure = new Procedure(
            augmentedName(declaredProcedure.name.text, libraryBuilder.library,
                targetBuilder._augmentationIndex),
            declaredProcedure.kind,
            declaredProcedure.function,
            fileUri: declaredProcedure.fileUri)
          ..flags = declaredProcedure.flags
          ..isStatic = procedure.isStatic
          ..parent = procedure.parent
          ..isInternalImplementation = true;

    Member? readTarget;
    Member? invokeTarget;
    Member? writeTarget;
    switch (kind) {
      case ProcedureKind.Method:
        readTarget = extensionTearOff ?? augmentedProcedure;
        invokeTarget = augmentedProcedure;
        break;
      case ProcedureKind.Getter:
        readTarget = augmentedProcedure;
        invokeTarget = augmentedProcedure;
        break;
      case ProcedureKind.Factory:
        readTarget = augmentedProcedure;
        invokeTarget = augmentedProcedure;
        break;
      case ProcedureKind.Operator:
        invokeTarget = augmentedProcedure;
        break;
      case ProcedureKind.Setter:
        writeTarget = augmentedProcedure;
        break;
    }
    return new AugmentSuperTarget(
        declaration: targetBuilder,
        readTarget: readTarget,
        invokeTarget: invokeTarget,
        writeTarget: writeTarget);
  }

  AugmentSuperTarget? _getAugmentSuperTarget(
      SourceProcedureBuilder augmentation) {
    return _augmentedProcedures[augmentation] ??=
        _createAugmentSuperTarget(augmentation._augmentedBuilder);
  }

  @override
  AugmentSuperTarget? get augmentSuperTarget =>
      origin._getAugmentSuperTarget(this);

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    List<SourceProcedureBuilder>? patches = _patches;
    if (patches != null) {
      void addAugmentedProcedure(SourceProcedureBuilder builder) {
        Procedure? augmentedProcedure = builder._augmentedProcedure;
        if (augmentedProcedure != null) {
          augmentedProcedure
            ..fileOffset = builder.actualProcedure.fileOffset
            ..fileEndOffset = builder.actualProcedure.fileEndOffset
            ..fileStartOffset = builder.actualProcedure.fileStartOffset
            ..signatureType = builder.actualProcedure.signatureType
            ..flags = builder.actualProcedure.flags;
          f(member: augmentedProcedure, kind: BuiltMemberKind.Method);
        }
      }

      addAugmentedProcedure(this);
      for (SourceProcedureBuilder patch in patches) {
        addAugmentedProcedure(patch);
      }
      finishProcedurePatch(procedure, patches.last.actualProcedure);

      return patches.length;
    }
    return 0;
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInFunction(
        procedure, typeEnvironment, sourceClassBuilder.cls.typeParameters);
    List<SourceProcedureBuilder>? patches = _patches;
    if (patches != null) {
      for (SourceProcedureBuilder patch in patches) {
        patch.checkVariance(sourceClassBuilder, typeEnvironment);
      }
    }
  }

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInFunctionBuilder(this, typeEnvironment);
    List<SourceProcedureBuilder>? patches = _patches;
    if (patches != null) {
      for (SourceProcedureBuilder patch in patches) {
        patch.checkTypes(library, typeEnvironment);
      }
    }
  }

  @override
  BodyBuilderContext get bodyBuilderContext =>
      new ProcedureBodyBuilderContext(this);

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [procedure];

  @override
  bool get isAugmented {
    if (isPatch) {
      return origin._patches!.last != this;
    } else {
      return _patches != null;
    }
  }
}

class SourceProcedureMember extends BuilderClassMember {
  @override
  final SourceProcedureBuilder memberBuilder;

  @override
  final ClassMemberKind memberKind;

  Covariance? _covariance;

  SourceProcedureMember(this.memberBuilder, this.memberKind);

  @override
  bool get isSourceDeclaration => true;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    memberBuilder._ensureTypes(membersBuilder);
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    memberBuilder.registerOverrideDependency(overriddenMembers);
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    memberBuilder._ensureTypes(membersBuilder);
    return memberBuilder.member;
  }

  @override
  Member? getTearOff(ClassMembersBuilder membersBuilder) {
    // Ensure function type is computed.
    getMember(membersBuilder);
    Member? readTarget = memberBuilder.readTarget;
    return readTarget != memberBuilder.invokeTarget ? readTarget : null;
  }

  @override
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= new Covariance.fromMember(getMember(membersBuilder),
        forSetter: forSetter);
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is SourceProcedureMember &&
        memberBuilder == other.memberBuilder;
  }
}
