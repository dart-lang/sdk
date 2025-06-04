// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/messages.dart'
    show
        LocatedMessage,
        Message,
        messageMoreThanOneSuperInitializer,
        messageRedirectingConstructorWithAnotherInitializer,
        messageRedirectingConstructorWithMultipleRedirectInitializers,
        messageRedirectingConstructorWithSuperInitializer,
        messageSuperInitializerNotLast,
        noLength,
        templateCantInferTypeDueToCircularity;
import '../base/name_space.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart' show DelayedDefaultValueCloner;
import '../kernel/type_algorithms.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_inference_engine.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_member_builder.dart';
import 'source_property_builder.dart';

class ExtensionTypeInitializerToStatementConverter
    implements InitializerVisitor<void> {
  VariableDeclaration thisVariable;
  final List<Statement> statements;

  ExtensionTypeInitializerToStatementConverter(
      this.statements, this.thisVariable);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    statements.add(node.statement);
  }

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    if (node is ExtensionTypeRedirectingInitializer) {
      statements.add(new ExpressionStatement(
          new VariableSet(
              thisVariable,
              new StaticInvocation(node.target, node.arguments)
                ..fileOffset = node.fileOffset)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset);
      return;
    } else if (node is ExtensionTypeRepresentationFieldInitializer) {
      thisVariable
        ..initializer = (node.value..parent = thisVariable)
        ..fileOffset = node.fileOffset;
      return;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitFieldInitializer(FieldInitializer node) {
    thisVariable
      ..initializer = (node.value..parent = thisVariable)
      ..fileOffset = node.fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitInvalidInitializer(InvalidInitializer node) {
    statements.add(new ExpressionStatement(
        new InvalidExpression(null)..fileOffset = node.fileOffset)
      ..fileOffset);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    statements.add(node.variable);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperInitializer(SuperInitializer node) {
    // TODO(johnniwinther): Report error for this case.
  }
}

class InferableConstructor implements InferableMember {
  @override
  final Member member;

  final SourceConstructorBuilder _builder;

  InferableConstructor(this.member, this._builder);

  @override
  void inferMemberTypes(ClassHierarchyBase classHierarchy) {
    _builder.inferFormalTypes(classHierarchy);
  }

  @override
  void reportCyclicDependency() {
    // There is a cyclic dependency where inferring the types of the
    // initializing formals of a constructor required us to infer the
    // corresponding field type which required us to know the type of the
    // constructor.
    String name = _builder.declarationBuilder.name;
    if (_builder.name.isNotEmpty) {
      // TODO(ahe): Use `inferrer.helper.constructorNameForDiagnostics`
      // instead. However, `inferrer.helper` may be null.
      name += ".${_builder.name}";
    }
    _builder.libraryBuilder.addProblem(
        templateCantInferTypeDueToCircularity.withArguments(name),
        _builder.fileOffset,
        name.length,
        _builder.fileUri);
  }
}

class SourceConstructorBuilder extends SourceMemberBuilderImpl
    implements ConstructorBuilder, SourceMemberBuilder, Inferable {
  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  /// The introductory declaration for this constructor.
  final ConstructorDeclaration _introductory;

  /// The augmenting declarations for this constructor.
  final List<ConstructorDeclaration> _augmentations;

  /// All constructor declarations for this constructor that are augmented by
  /// at least one constructor declaration.
  late final List<ConstructorDeclaration> _augmentedDeclarations;

  /// The last constructor declaration between [_introductory] and
  /// [_augmentations].
  ///
  /// This is the declaration that creates the emitted kernel member(s).
  late final ConstructorDeclaration _lastDeclaration;

  final MemberName _memberName;

  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners = [];

  Set<SourcePropertyBuilder>? _initializedFields;

  late final Reference _invokeTargetReference;
  late final Member _invokeTarget;
  late final Reference _readTargetReference;
  late final Member _readTarget;

  late final Substitution _fieldTypeSubstitution =
      _introductory.computeFieldTypeSubstitution(declarationBuilder);

  final String? nativeMethodName;

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  bool _hasBuiltOutlines = false;

  bool hasBuiltOutlineExpressions = false;

  bool _hasFormalsInferred = false;

  @override
  final bool isConst;

  final bool isExternal;

  SourceConstructorBuilder({
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required this.fileOffset,
    required this.fileUri,
    this.nativeMethodName,
    required Reference? constructorReference,
    required Reference? tearOffReference,
    required NameScheme nameScheme,
    required ConstructorDeclaration introductory,
    List<ConstructorDeclaration> augmentations = const [],
    required this.isConst,
    required this.isExternal,
  })  : _introductory = introductory,
        _augmentations = augmentations,
        _memberName = nameScheme.getDeclaredName(name) {
    if (augmentations.isEmpty) {
      _augmentedDeclarations = augmentations;
      _lastDeclaration = introductory;
    } else {
      _augmentedDeclarations = [_introductory, ..._augmentations];
      _lastDeclaration = _augmentedDeclarations.removeLast();
    }
    for (ConstructorDeclaration declaration in _augmentedDeclarations) {
      declaration.createNode(
          name: name,
          libraryBuilder: libraryBuilder,
          nameScheme: nameScheme,
          constructorReference: null,
          tearOffReference: null);
    }
    _lastDeclaration.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference);
    _invokeTargetReference = _lastDeclaration.invokeTargetReference;
    _invokeTarget = _lastDeclaration.invokeTarget;
    _readTargetReference = _lastDeclaration.readTargetReference;
    _readTarget = _lastDeclaration.readTarget;

    _introductory.registerInferable(this);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.registerInferable(this);
    }
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  Iterable<Annotatable> get annotatables => [invokeTarget];

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [invokeTargetReference];

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  @override
  FunctionNode get function => _lastDeclaration.function;

  @override
  // Coverage-ignore(suite): Not run.
  NamedBuilder get getable => this;

  bool get hasParameters => _introductory.hasParameters;

  @override
  Member get invokeTarget => _invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _invokeTargetReference;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isClassInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isDeclarationInstanceMember => false;

  /// Returns `true` if this constructor, including its augmentations, is
  /// external.
  ///
  /// An augmented constructor is considered external if all of the origin
  /// and augmentation constructors are external.
  bool get isEffectivelyExternal {
    bool isExternal = this.isExternal;
    if (isExternal) {
      for (ConstructorDeclaration augmentation in _augmentations) {
        isExternal &= augmentation.isExternal;
      }
    }
    return isExternal;
  }

  /// Returns `true` if this constructor or any of its augmentations are
  /// redirecting.
  ///
  /// An augmented constructor is considered redirecting if any of the origin
  /// or augmentation constructors is redirecting. Since it is an error if more
  /// than one is redirecting, only one can be redirecting in the without
  /// errors.
  bool get isEffectivelyRedirecting {
    bool isRedirecting = _introductory.isRedirecting;
    if (!isRedirecting) {
      for (ConstructorDeclaration augmentation in _augmentations) {
        isRedirecting |= augmentation.isRedirecting;
      }
    }
    return isRedirecting;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  // Coverage-ignore(suite): Not run.
  bool get isNative => nativeMethodName != null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  /// Returns `true` if this constructor is an redirecting generative
  /// constructor.
  ///
  /// It is considered redirecting if it has at least one redirecting
  /// initializer.
  bool get isRedirecting => _lastDeclaration.isRedirecting;

  @override
  bool get isStatic => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => _introductory.metadata;

  @override
  Builder get parent => declarationBuilder;

  @override
  Member get readTarget => _readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _readTargetReference;

  @override
  // Coverage-ignore(suite): Not run.
  NamedBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  List<Initializer> get _initializers => _lastDeclaration.initializers;

  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult,
      required TreeNode parent}) {
    if (initializer is SuperInitializer) {
      if (superInitializer != null) {
        _injectInvalidInitializer(messageMoreThanOneSuperInitializer,
            initializer.fileOffset, "super".length, helper, parent);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            initializer.fileOffset,
            "super".length,
            helper,
            parent);
      } else {
        inferenceResult?.applyResult(_initializers, parent);
        superInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, <TypeParameter>[]);
        if (message != null) {
          _initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text),
                  initializer.fileOffset,
                  arguments: initializer.arguments,
                  isSuper: true,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = parent);
        } else {
          _initializers.add(initializer..parent = parent);
        }
      }
    } else if (initializer
        case RedirectingInitializer(
              target: Member initializerTarget,
              arguments: var initializerArguments
            ) ||
            ExtensionTypeRedirectingInitializer(
              target: Member initializerTarget,
              arguments: var initializerArguments
            )) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            superInitializer!.fileOffset,
            "super".length,
            helper,
            parent);
        markAsErroneous();
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithMultipleRedirectInitializers,
            initializer.fileOffset,
            noLength,
            helper,
            parent);
        markAsErroneous();
      } else if (_initializers.isNotEmpty) {
        // Error on all previous ones.
        for (int i = 0; i < _initializers.length; i++) {
          Initializer initializer = _initializers[i];
          int length = noLength;
          if (initializer is AssertInitializer) length = "assert".length;
          Initializer error = helper.buildInvalidInitializer(
              helper.buildProblem(
                  messageRedirectingConstructorWithAnotherInitializer,
                  initializer.fileOffset,
                  length));
          error.parent = parent;
          _initializers[i] = error;
        }
        inferenceResult?.applyResult(_initializers, parent);
        _initializers.add(initializer..parent = parent);
        if (initializer is RedirectingInitializer) {
          redirectingInitializer = initializer;
        }
        markAsErroneous();
      } else {
        inferenceResult?.applyResult(_initializers, parent);
        if (initializer is RedirectingInitializer) {
          redirectingInitializer = initializer;
        }

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializerTarget.function!,
            initializerArguments,
            initializerArguments.fileOffset,
            initializer is ExtensionTypeRedirectingInitializer
                ? initializerTarget.function!.typeParameters
                : const <TypeParameter>[]);
        if (message != null) {
          _initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.constructorNameForDiagnostics(
                      initializerTarget.name.text),
                  initializer.fileOffset,
                  arguments: initializerArguments,
                  isSuper: false,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = parent);
          markAsErroneous();
        } else {
          _initializers.add(initializer..parent = parent);
        }
      }
    } else if (redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      _injectInvalidInitializer(
          messageRedirectingConstructorWithAnotherInitializer,
          initializer.fileOffset,
          length,
          helper,
          parent);
      markAsErroneous();
    } else if (superInitializer != null) {
      _injectInvalidInitializer(messageSuperInitializerNotLast,
          initializer.fileOffset, noLength, helper, parent);
      markAsErroneous();
    } else {
      inferenceResult?.applyResult(_initializers, parent);
      _initializers.add(initializer..parent = parent);
    }
  }

  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    _introductory.addSuperParameterDefaultValueCloners(
        libraryBuilder, declarationBuilder, delayedDefaultValueCloners);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.addSuperParameterDefaultValueCloners(
          libraryBuilder, declarationBuilder, delayedDefaultValueCloners);
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    _introductory.buildBody();
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.buildBody();
    }
    return _augmentations.length;
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;

    if (!hasBuiltOutlineExpressions) {
      _introductory.buildOutlineExpressions(
          annotatables: annotatables,
          annotatablesFileUri: invokeTarget.fileUri,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          constructorBuilder: this,
          classHierarchy: classHierarchy,
          delayedDefaultValueCloners: delayedDefaultValueCloners);
      for (ConstructorDeclaration augmentation in _augmentations) {
        augmentation.buildOutlineExpressions(
            annotatables: annotatables,
            annotatablesFileUri: invokeTarget.fileUri,
            libraryBuilder: libraryBuilder,
            declarationBuilder: declarationBuilder,
            constructorBuilder: this,
            classHierarchy: classHierarchy,
            delayedDefaultValueCloners: delayedDefaultValueCloners);
      }
      hasBuiltOutlineExpressions = true;
    }

    delayedDefaultValueCloners.addAll(_delayedDefaultValueCloners);
    _delayedDefaultValueCloners.clear();
    _hasBuiltOutlines = true;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _lastDeclaration.buildOutlineNodes(f,
        constructorBuilder: this,
        libraryBuilder: libraryBuilder,
        declarationConstructor: invokeTarget,
        delayedDefaultValueCloners: _delayedDefaultValueCloners);
    for (ConstructorDeclaration declaration in _augmentedDeclarations) {
      declaration.buildOutlineNodes(noAddBuildNodesCallback,
          constructorBuilder: this,
          libraryBuilder: libraryBuilder,
          declarationConstructor: invokeTarget,
          delayedDefaultValueCloners: _delayedDefaultValueCloners);
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    _introductory.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.checkTypes(libraryBuilder, nameSpace, typeEnvironment);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = _introductory.computeDefaultTypes(context,
        inErrorRecovery: inErrorRecovery);
    for (ConstructorDeclaration augmentation in _augmentations) {
      count += augmentation.computeDefaultTypes(context,
          inErrorRecovery: inErrorRecovery);
    }
    return count;
  }

  /// Infers the types of any untyped initializing formals.
  void inferFormalTypes(ClassHierarchyBase hierarchy) {
    if (_hasFormalsInferred) return;
    _introductory.inferFormalTypes(libraryBuilder, declarationBuilder, this,
        hierarchy, _delayedDefaultValueCloners);
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.inferFormalTypes(libraryBuilder, declarationBuilder, this,
          hierarchy, _delayedDefaultValueCloners);
    }
    _hasFormalsInferred = true;
  }

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferFormalTypes(hierarchy);
  }

  void prepareInitializers() {
    _introductory.prepareInitializers();
    for (ConstructorDeclaration augmentation in _augmentations) {
      augmentation.prepareInitializers();
    }
    redirectingInitializer = null;
    superInitializer = null;
  }

  void prependInitializer(Initializer initializer) {
    _lastDeclaration.prependInitializer(initializer);
  }

  /// Registers field as being initialized by this constructor.
  ///
  /// The field can be initialized either via an initializing formal or via an
  /// entry in the constructor initializer list.
  void registerInitializedField(SourcePropertyBuilder fieldBuilder) {
    (_initializedFields ??= {}).add(fieldBuilder);
  }

  /// Substitute [fieldType] from the context of the enclosing class or
  /// extension type declaration to this constructor.
  ///
  /// This is used for generic extension type constructors where the type
  /// variable referring to the class type parameters must be substituted for
  /// the synthesized constructor type parameters.
  DartType substituteFieldType(DartType fieldType) {
    return _fieldTypeSubstitution.substituteType(fieldType);
  }

  /// Returns the fields registered as initialized by this constructor.
  ///
  /// Returns the set of fields previously registered via
  /// [registerInitializedField] and passes on the ownership of the collection
  /// to the caller.
  Set<SourcePropertyBuilder>? takeInitializedFields() {
    Set<SourcePropertyBuilder>? result = _initializedFields;
    _initializedFields = null;
    return result;
  }

  void _injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper, TreeNode parent) {
    Initializer lastInitializer = _initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.buildProblem(message, charOffset, length));
    _initializers.add(error..parent = parent);
    _initializers.add(lastInitializer);
  }

  /// Mark the constructor as erroneous.
  ///
  /// This is used during the compilation phase to set the appropriate flag on
  /// the input AST node. The flag helps the verifier to skip apriori erroneous
  /// members and to avoid reporting cascading errors.
  void markAsErroneous() {
    _introductory.markAsErroneous();
    for (ConstructorDeclaration augmentation in _augmentations)
    // Coverage-ignore(suite): Not run.
    {
      augmentation.markAsErroneous();
    }
  }
}
