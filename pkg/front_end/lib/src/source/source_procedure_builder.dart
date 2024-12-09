// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/augmentation_lowering.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/hierarchy/members_builder.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/member_covariance.dart';
import '../kernel/type_algorithms.dart';
import 'name_scheme.dart';
import 'source_builder_mixins.dart';
import 'source_class_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';

class SourceProcedureBuilder extends SourceFunctionBuilderImpl
    implements ProcedureBuilder {
  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder? declarationBuilder;

  final int formalsOffset;

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

  final ProcedureKind _kind;

  /// The builder for the original declaration.
  SourceProcedureBuilder? _origin;

  /// If this builder is a patch or an augmentation, this is the builder for
  /// the immediately augmented procedure.
  SourceProcedureBuilder? _augmentedBuilder;

  int _augmentationIndex = 0;

  List<SourceProcedureBuilder>? _augmentations;

  final MemberName _memberName;

  final int nameOffset;

  @override
  final Uri fileUri;

  SourceProcedureBuilder(
      {required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required this.returnType,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required ProcedureKind kind,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required int startOffset,
      required this.nameOffset,
      required this.formalsOffset,
      required int endOffset,
      required Reference? procedureReference,
      required Reference? tearOffReference,
      required AsyncMarker asyncModifier,
      required NameScheme nameScheme,
      String? nativeMethodName,
      bool isSynthetic = false})
      : assert(kind != ProcedureKind.Factory),
        this._tearOffReference = tearOffReference,
        this._kind = kind,
        this.isExtensionInstanceMember =
            nameScheme.isInstanceMember && nameScheme.isExtensionMember,
        this.isExtensionTypeInstanceMember =
            nameScheme.isInstanceMember && nameScheme.isExtensionTypeMember,
        this._memberName = nameScheme.getDeclaredName(name),
        super(metadata, modifiers, name, typeParameters, formals,
            nativeMethodName) {
    _procedure = new Procedure(
        dummyName,
        isExtensionInstanceMember || isExtensionTypeInstanceMember
            ? ProcedureKind.Method
            : kind,
        new FunctionNode(null),
        fileUri: fileUri,
        reference: procedureReference,
        isSynthetic: isSynthetic)
      ..fileStartOffset = startOffset
      ..fileOffset = nameOffset
      ..fileEndOffset = endOffset;
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
        ..fileOffset = nameOffset;
      nameScheme
          .getProcedureMemberName(ProcedureKind.Getter, name)
          .attachMember(_extensionTearOff!);
    }
  }

  @override
  int get fileOffset => nameOffset;

  @override
  Builder get parent => declarationBuilder ?? libraryBuilder;

  @override
  Name get memberName => _memberName.name;

  // Coverage-ignore(suite): Not run.
  List<SourceProcedureBuilder>? get augmentationsForTesting => _augmentations;

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
  SourceProcedureBuilder get origin => _origin ?? this;

  @override
  Procedure get procedure => isAugmenting ? origin.procedure : _procedure;

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
        // Coverage-ignore-block(suite): Not run.
        membersBuilder.inferGetterType(declarationBuilder as SourceClassBuilder,
            returnType, _overrideDependencies!,
            name: fullNameForErrors,
            fileUri: fileUri,
            nameOffset: nameOffset,
            nameLength: fullNameForErrors.length);
      } else if (isSetter) {
        membersBuilder.inferSetterType(declarationBuilder as SourceClassBuilder,
            formals, _overrideDependencies!,
            name: fullNameForErrors,
            fileUri: fileUri,
            nameOffset: nameOffset,
            nameLength: fullNameForErrors.length);
      } else {
        membersBuilder.inferMethodType(declarationBuilder as SourceClassBuilder,
            function, returnType, formals, _overrideDependencies!,
            name: fullNameForErrors,
            fileUri: fileUri,
            nameOffset: nameOffset,
            nameLength: fullNameForErrors.length);
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
    switch (_kind) {
      case ProcedureKind.Method:
        return extensionTearOff ?? procedure;
      case ProcedureKind.Getter:
        // Coverage-ignore(suite): Not run.
        return procedure;
      case ProcedureKind.Factory:
        // Coverage-ignore(suite): Not run.
        return procedure;
      case ProcedureKind.Operator:
      case ProcedureKind.Setter:
        return null;
    }
  }

  @override
  Member? get writeTarget {
    switch (_kind) {
      case ProcedureKind.Setter:
        return procedure;
      case ProcedureKind.Method:
      // Coverage-ignore(suite): Not run.
      case ProcedureKind.Getter:
      // Coverage-ignore(suite): Not run.
      case ProcedureKind.Operator:
      // Coverage-ignore(suite): Not run.
      case ProcedureKind.Factory:
        return null;
    }
  }

  @override
  Member? get invokeTarget {
    switch (_kind) {
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
  Iterable<Reference> get exportedMemberReferences => [procedure.reference];

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    if (isExtensionMethod) {
      switch (_kind) {
        case ProcedureKind.Method:
          f(
              member: _procedure,
              tearOff: extensionTearOff,
              kind: BuiltMemberKind.ExtensionMethod);
          break;
        case ProcedureKind.Getter:
          // Coverage-ignore(suite): Not run.
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          // Coverage-ignore(suite): Not run.
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
        // Coverage-ignore(suite): Not run.
        case ProcedureKind.Factory:
          throw new UnsupportedError(
              'Unexpected extension method kind ${_kind}');
      }
    } else if (isExtensionTypeMethod) {
      switch (_kind) {
        case ProcedureKind.Method:
          f(
              member: _procedure,
              tearOff: extensionTearOff,
              kind: BuiltMemberKind.ExtensionTypeMethod);
          break;
        case ProcedureKind.Getter:
          // Coverage-ignore(suite): Not run.
          assert(extensionTearOff == null, "Unexpected extension tear-off.");
          // Coverage-ignore(suite): Not run.
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
        // Coverage-ignore(suite): Not run.
        case ProcedureKind.Factory:
          f(
              member: _procedure,
              tearOff: extensionTearOff,
              kind: BuiltMemberKind.ExtensionTypeFactory);
          break;
      }
    } else {
      f(member: _procedure, kind: BuiltMemberKind.Method);
    }
  }

  void _build() {
    buildFunction();
    _procedure.function.fileOffset = formalsOffset;
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
          isLowered: parameter.isLowered,
          isRequired: parameter.isRequired)
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
              closure.function.computeFunctionType(Nullability.nonNullable))
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
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceProcedureBuilder) {
      if (checkAugmentation(
          augmentationLibraryBuilder: augmentation.libraryBuilder,
          origin: this,
          augmentation: augmentation)) {
        augmentation._origin = this;
        SourceProcedureBuilder augmentedBuilder =
            _augmentations == null ? this : _augmentations!.last;
        augmentation._augmentedBuilder = augmentedBuilder;
        augmentation._augmentationIndex =
            augmentedBuilder._augmentationIndex + 1;
        (_augmentations ??= []).add(augmentation);
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      reportAugmentationMismatch(
          originLibraryBuilder: libraryBuilder,
          origin: this,
          augmentation: augmentation);
    }
  }

  Map<SourceProcedureBuilder, AugmentSuperTarget?> _augmentedProcedures = {};

  AugmentSuperTarget? _createAugmentSuperTarget(
      SourceProcedureBuilder? targetBuilder) {
    if (targetBuilder == null) return null;
    Procedure declaredProcedure = targetBuilder.actualProcedure;

    if (declaredProcedure.isAbstract || declaredProcedure.isExternal) {
      // Coverage-ignore-block(suite): Not run.
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
    switch (_kind) {
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
    List<SourceProcedureBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
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
      for (SourceProcedureBuilder augmentation in augmentations) {
        addAugmentedProcedure(augmentation);
      }
      finishProcedureAugmentation(
          procedure, augmentations.last.actualProcedure);

      return augmentations.length;
    }
    return 0;
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInFunction(
        procedure, typeEnvironment, sourceClassBuilder.cls.typeParameters);
    List<SourceProcedureBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceProcedureBuilder augmentation in augmentations) {
        augmentation.checkVariance(sourceClassBuilder, typeEnvironment);
      }
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    List<TypeParameterBuilder>? typeParameters = this.typeParameters;
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(formals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
    List<SourceProcedureBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceProcedureBuilder augmentation in augmentations) {
        augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
      }
    }
    if (isGetter) {
      // Coverage-ignore-block(suite): Not run.
      if (!isClassMember) {
        // Getter/setter type conflict for class members is handled in the class
        // hierarchy builder.
        Builder? setterDeclaration =
            nameSpace.lookupLocalMember(name, setter: true);
        if (setterDeclaration != null) {
          SourceProcedureBuilder getterBuilder = this;
          SourceProcedureBuilder setterBuilder =
              setterDeclaration as SourceProcedureBuilder;

          DartType getterType;
          List<TypeParameter>? getterExtensionTypeParameters;
          if (getterBuilder.isExtensionInstanceMember ||
              setterBuilder.isExtensionTypeInstanceMember) {
            // An extension instance getter
            //
            //     extension E<T> on A {
            //       T get property => ...
            //     }
            //
            // is encoded as a top level method
            //
            //   T# E#get#property<T#>(A #this) => ...
            //
            // Similarly for extension type instance getters.
            //
            Procedure procedure = getterBuilder.procedure;
            getterType = procedure.function.returnType;
            getterExtensionTypeParameters = procedure.function.typeParameters;
          } else {
            getterType = getterBuilder.procedure.getterType;
          }
          DartType setterType = getSetterType(setterBuilder,
              getterExtensionTypeParameters: getterExtensionTypeParameters);

          libraryBuilder.checkGetterSetterTypes(typeEnvironment,
              getterType: getterType,
              getterName: getterBuilder.name,
              getterFileUri: getterBuilder.fileUri,
              getterFileOffset: getterBuilder.nameOffset,
              getterNameLength: getterBuilder.name.length,
              setterType: setterType,
              setterName: setterBuilder.name,
              setterFileUri: setterBuilder.fileUri,
              setterFileOffset: setterBuilder.nameOffset,
              setterNameLength: setterBuilder.name.length);
        }
      }
    }
  }

  static DartType getSetterType(SourceProcedureBuilder setterBuilder,
      {required List<TypeParameter>? getterExtensionTypeParameters}) {
    DartType setterType;
    if (setterBuilder.isExtensionInstanceMember ||
        setterBuilder.isExtensionTypeInstanceMember) {
      // An extension instance setter
      //
      //     extension E<T> on A {
      //       void set property(T value) { ... }
      //     }
      //
      // is encoded as a top level method
      //
      //   void E#set#property<T#>(A #this, T# value) { ... }
      //
      // Similarly for extension type instance setters.
      //
      Procedure procedure = setterBuilder.procedure;
      setterType = procedure.function.positionalParameters[1].type;
      if (getterExtensionTypeParameters != null &&
          getterExtensionTypeParameters.isNotEmpty) {
        // We substitute the setter type parameters for the getter type
        // parameters to check them below in a shared context.
        List<TypeParameter> setterExtensionTypeParameters =
            procedure.function.typeParameters;
        assert(getterExtensionTypeParameters.length ==
            setterExtensionTypeParameters.length);
        setterType = Substitution.fromPairs(
                setterExtensionTypeParameters,
                new List<DartType>.generate(
                    getterExtensionTypeParameters.length,
                    (int index) => new TypeParameterType.forAlphaRenaming(
                        setterExtensionTypeParameters[index],
                        getterExtensionTypeParameters[index])))
            .substituteType(setterType);
      }
    } else {
      setterType = setterBuilder.procedure.setterType;
    }
    return setterType;
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    bool hasErrors =
        context.reportSimplicityIssuesForTypeParameters(typeParameters);
    context.reportGenericFunctionTypesForFormals(formals);
    if (returnType is! OmittedTypeBuilder) {
      hasErrors |= context.reportInboundReferenceIssuesForType(returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(returnType);
    }
    return context.computeDefaultTypesForVariables(typeParameters,
        inErrorRecovery: hasErrors);
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new ProcedureBodyBuilderContext(this, procedure);
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [procedure];

  @override
  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }

  @override
  bool get isRegularMethod => identical(ProcedureKind.Method, _kind);

  @override
  bool get isGetter => identical(ProcedureKind.Getter, _kind);

  @override
  bool get isSetter => identical(ProcedureKind.Setter, _kind);

  @override
  bool get isOperator => identical(ProcedureKind.Operator, _kind);

  @override
  bool get isFactory => identical(ProcedureKind.Factory, _kind);

  @override
  bool get isProperty => isGetter || isSetter;
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
    return memberBuilder._procedure;
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
  // Coverage-ignore(suite): Not run.
  bool isSameDeclaration(ClassMember other) {
    return other is SourceProcedureMember &&
        memberBuilder == other.memberBuilder;
  }
}
