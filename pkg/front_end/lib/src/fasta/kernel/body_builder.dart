// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.body_builder;

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show
        Assert,
        BlockKind,
        ConstructorReferenceContext,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        Parser,
        lengthForToken,
        lengthOfSpan,
        optional;
import 'package:_fe_analyzer_shared/src/parser/quote.dart'
    show
        Quote,
        analyzeQuote,
        unescape,
        unescapeFirstStringPart,
        unescapeLastStringPart,
        unescapeString;
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart'
    show FixedNullableList, GrowableList, NullValue, ParserRecovery;
import 'package:_fe_analyzer_shared/src/parser/value_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show isBinaryOperator, isMinusOperator, isUserDefinableOperator;
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/bounds_checks.dart' hide calculateBounds;
import 'package:kernel/transformations/flags.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/field_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/modifier_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../builder/variable_builder.dart';
import '../builder/void_type_declaration_builder.dart';
import '../constant_context.dart' show ConstantContext;
import '../dill/dill_library_builder.dart' show DillLibraryBuilder;
import '../fasta_codes.dart' as fasta;
import '../fasta_codes.dart'
    show
        LocatedMessage,
        Message,
        Template,
        noLength,
        templateExperimentNotEnabled;
import '../identifiers.dart'
    show Identifier, InitializedIdentifier, QualifiedName, flattenName;
import '../messages.dart' as messages show getLocationFromUri;
import '../modifier.dart'
    show Modifier, constMask, covariantMask, finalMask, lateMask, requiredMask;
import '../names.dart' show emptyName, minusName, plusName;
import '../problems.dart'
    show internalProblem, unexpected, unhandled, unsupported;
import '../scope.dart';
import '../source/diet_parser.dart';
import '../source/scope_listener.dart' show JumpTargetKind, ScopeListener;
import '../source/source_class_builder.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_field_builder.dart';
import '../source/source_function_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_procedure_builder.dart';
import '../source/stack_listener_impl.dart' show offsetForToken;
import '../source/value_kinds.dart';
import '../type_inference/type_inferrer.dart'
    show TypeInferrer, InferredFunctionBody, InitializerInferenceResult;
import '../type_inference/type_schema.dart' show UnknownType;
import '../util/helpers.dart' show DelayedActionPerformer;
import 'collections.dart';
import 'constness.dart' show Constness;
import 'constructor_tearoff_lowering.dart';
import 'expression_generator.dart';
import 'expression_generator_helper.dart';
import 'forest.dart' show Forest;
import 'implicit_type_argument.dart' show ImplicitTypeArgument;
import 'internal_ast.dart';
import 'kernel_variable_builder.dart';
import 'load_library_builder.dart';
import 'redirecting_factory_body.dart'
    show
        RedirectingFactoryBody,
        RedirectionTarget,
        getRedirectingFactoryBody,
        getRedirectionTarget;
import 'type_algorithms.dart' show calculateBounds;
import 'utils.dart';

// TODO(ahe): Remove this and ensure all nodes have a location.
const int noLocation = TreeNode.noOffset;

// TODO(danrubel): Remove this once control flow and spread collection support
// has been enabled by default.
const Object invalidCollectionElement = const Object();

class BodyBuilder extends ScopeListener<JumpTarget>
    implements ExpressionGeneratorHelper, EnsureLoaded, DelayedActionPerformer {
  @override
  final Forest forest;

  // TODO(ahe): Rename [library] to 'part'.
  @override
  final SourceLibraryBuilder libraryBuilder;

  final ModifierBuilder member;

  /// The class, mixin or extension declaration in which [member] is declared,
  /// if any.
  final DeclarationBuilder? declarationBuilder;

  /// The source class or mixin declaration in which [member] is declared, if
  /// any.
  ///
  /// If [member] is a synthesized member for expression evaluation the
  /// enclosing declaration might be a [DillClassBuilder]. This can be accessed
  /// through [declarationBuilder].
  final SourceClassBuilder? sourceClassBuilder;

  final ClassHierarchy hierarchy;

  @override
  final CoreTypes coreTypes;

  final bool isDeclarationInstanceMember;

  final Scope enclosingScope;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  /// Whether to ignore an unresolved reference to `main` within the body of
  /// `_getMainClosure` when compiling the current library.
  ///
  /// This as a temporary workaround. The standalone VM and flutter have
  /// special logic to resolve `main` in `_getMainClosure`, this flag is used to
  /// ignore that reference to `main`, but only on libraries where we expect to
  /// see it (today that is dart:_builtin and dart:ui).
  ///
  // TODO(ahe,sigmund): remove when the VM gets rid of the special rule, see
  // https://github.com/dart-lang/sdk/issues/28989.
  final bool ignoreMainInGetMainClosure;

  // TODO(ahe): Consider renaming [uri] to 'partUri'.
  @override
  final Uri uri;

  final TypeInferrer typeInferrer;

  /// Only used when [member] is a constructor. It tracks if an implicit super
  /// initializer is needed.
  ///
  /// An implicit super initializer isn't needed
  ///
  /// 1. if the current class is Object,
  /// 2. if there is an explicit super initializer,
  /// 3. if there is a redirecting (this) initializer, or
  /// 4. if a compile-time error prevented us from generating code for an
  ///    initializer. This avoids cascading errors.
  bool needsImplicitSuperInitializer;

  Scope? formalParameterScope;

  /// This is set to true when we start parsing an initializer. We use this to
  /// find the correct scope for initializers like in this example:
  ///
  ///     class C {
  ///       final x;
  ///       C(x) : x = x;
  ///     }
  ///
  /// When parsing this initializer `x = x`, `x` must be resolved in two
  /// different scopes. The first `x` must be resolved in the class' scope, the
  /// second in the formal parameter scope.
  bool inInitializerLeftHandSide = false;

  /// This is set to true when we are parsing constructor initializers.
  bool inConstructorInitializer = false;

  /// Set to `true` when we are parsing a field initializer either directly
  /// or within an initializer list.
  ///
  /// For instance in `<init>` in
  ///
  ///    var foo = <init>;
  ///    class Class {
  ///      var bar = <init>;
  ///      Class() : <init>;
  ///    }
  ///
  /// This is used to determine whether instance properties are available.
  bool inFieldInitializer = false;

  /// `true` if we are directly in a field initializer of a late field.
  ///
  /// For instance in `<init>` in
  ///
  ///    late var foo = <init>;
  ///    class Class {
  ///      late var bar = <init>;
  ///      Class() : bar = 42;
  ///    }
  ///
  bool inLateFieldInitializer = false;

  /// `true` if we are directly in the initializer of a late local.
  ///
  /// For instance in `<init>` in
  ///
  ///    method() {
  ///      late var foo = <init>;
  ///    }
  ///    class Class {
  ///      method() {
  ///        late var bar = <init>;
  ///      }
  ///    }
  ///
  bool get inLateLocalInitializer => _localInitializerState.head;

  Link<bool> _isOrAsOperatorTypeState = const Link<bool>().prepend(false);

  bool get inIsOrAsOperatorType => _isOrAsOperatorTypeState.head;

  Link<bool> _localInitializerState = const Link<bool>().prepend(false);

  List<Initializer>? _initializers;

  bool inCatchClause = false;

  bool inCatchBlock = false;

  int functionNestingLevel = 0;

  // Set when a spread element is encountered in a collection so the collection
  // needs to be desugared after type inference.
  bool transformCollections = false;

  // Set by type inference when a set literal is encountered that needs to be
  // transformed because the backend target does not support set literals.
  bool transformSetLiterals = false;

  Statement? problemInLoopOrSwitch;

  Scope? switchScope;

  late _BodyBuilderCloner _cloner = new _BodyBuilderCloner(this);

  @override
  ConstantContext constantContext = ConstantContext.none;

  DartType? currentLocalVariableType;

  // Using non-null value to initialize this field based on performance advice
  // from VM engineers. TODO(ahe): Does this still apply?
  int currentLocalVariableModifiers = -1;

  /// If non-null, records instance fields which have already been initialized
  /// and where that was.
  Map<String, int>? initializedFields;

  /// List of built redirecting factory invocations.  The targets of the
  /// invocations are to be resolved in a separate step.
  final List<FactoryConstructorInvocation> redirectingFactoryInvocations = [];

  /// List of redirecting factory invocations delayed for resolution.
  ///
  /// A resolution of a redirecting factory invocation can be delayed because
  /// the inference in the declaration of the redirecting factory isn't done
  /// yet.
  final List<FactoryConstructorInvocation>
      delayedRedirectingFactoryInvocations = [];

  /// List of built type aliased generative constructor invocations that
  /// require unaliasing.
  final List<TypeAliasedConstructorInvocation>
      typeAliasedConstructorInvocations = [];

  /// List of built type aliased factory constructor invocations that require
  /// unaliasing.
  final List<TypeAliasedFactoryInvocation> typeAliasedFactoryInvocations = [];

  /// List of type aliased factory invocations delayed for resolution.
  ///
  /// A resolution of a type aliased factory invocation can be delayed because
  /// the inference in the declaration of the target isn't done yet.
  final List<TypeAliasedFactoryInvocation>
      delayedTypeAliasedFactoryInvocations = [];

  /// Variables with metadata.  Their types need to be inferred late, for
  /// example, in [finishFunction].
  List<VariableDeclaration>? variablesWithMetadata;

  /// More than one variable declared in a single statement that has metadata.
  /// Their types need to be inferred late, for example, in [finishFunction].
  List<List<VariableDeclaration>>? multiVariablesWithMetadata;

  /// If the current member is an instance member in an extension declaration,
  /// [extensionThis] holds the synthetically add parameter holding the value
  /// for `this`.
  final VariableDeclaration? extensionThis;

  final List<TypeParameter>? extensionTypeParameters;

  BodyBuilder(
      {required this.libraryBuilder,
      required this.member,
      required this.enclosingScope,
      this.formalParameterScope,
      required this.hierarchy,
      required this.coreTypes,
      this.declarationBuilder,
      required this.isDeclarationInstanceMember,
      this.extensionThis,
      this.extensionTypeParameters,
      required this.uri,
      required this.typeInferrer})
      : forest = const Forest(),
        sourceClassBuilder = declarationBuilder is SourceClassBuilder
            ? declarationBuilder
            : null,
        enableNative = libraryBuilder.loader.target.backendTarget
            .enableNative(libraryBuilder.importUri),
        stringExpectedAfterNative = libraryBuilder
            .loader.target.backendTarget.nativeExtensionExpectsString,
        ignoreMainInGetMainClosure =
            libraryBuilder.importUri.isScheme('dart') &&
                (libraryBuilder.importUri.path == "_builtin" ||
                    libraryBuilder.importUri.path == "ui"),
        needsImplicitSuperInitializer =
            declarationBuilder is SourceClassBuilder &&
                coreTypes.objectClass != declarationBuilder.cls,
        super(enclosingScope) {
    formalParameterScope?.forEach((String name, Builder builder) {
      if (builder is VariableBuilder) {
        typeInferrer.assignedVariables.declare(builder.variable!);
      }
    });
  }

  BodyBuilder.withParents(FieldBuilder field, SourceLibraryBuilder part,
      DeclarationBuilder? declarationBuilder, TypeInferrer typeInferrer)
      : this(
            libraryBuilder: part,
            member: field,
            enclosingScope: declarationBuilder?.scope ?? field.library.scope,
            formalParameterScope: null,
            hierarchy: part.loader.hierarchy,
            coreTypes: part.loader.coreTypes,
            declarationBuilder: declarationBuilder,
            isDeclarationInstanceMember: field.isDeclarationInstanceMember,
            extensionThis: null,
            uri: field.fileUri!,
            typeInferrer: typeInferrer);

  BodyBuilder.forField(FieldBuilder field, TypeInferrer typeInferrer)
      : this.withParents(
            field,
            field.parent is DeclarationBuilder
                ? field.parent!.parent as SourceLibraryBuilder
                : field.parent as SourceLibraryBuilder,
            field.parent is DeclarationBuilder
                ? field.parent as DeclarationBuilder
                : null,
            typeInferrer);

  BodyBuilder.forOutlineExpression(
      SourceLibraryBuilder library,
      DeclarationBuilder? declarationBuilder,
      ModifierBuilder member,
      Scope scope,
      Uri fileUri,
      {Scope? formalParameterScope})
      : this(
            libraryBuilder: library,
            member: member,
            enclosingScope: scope,
            formalParameterScope: formalParameterScope,
            hierarchy: library.loader.hierarchy,
            coreTypes: library.loader.coreTypes,
            declarationBuilder: declarationBuilder,
            isDeclarationInstanceMember: member.isDeclarationInstanceMember,
            extensionThis: null,
            uri: fileUri,
            typeInferrer: library.loader.typeInferenceEngine
                .createLocalTypeInferrer(
                    fileUri, declarationBuilder?.thisType, library, null));

  bool get inConstructor {
    return functionNestingLevel == 0 && member is ConstructorBuilder;
  }

  @override
  bool get isDeclarationInstanceContext {
    return isDeclarationInstanceMember || member is ConstructorBuilder;
  }

  @override
  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    if (member.isExtensionMember && member.isField && !member.isExternal) {
      return InstanceTypeVariableAccessState.Invalid;
    } else if (isDeclarationInstanceContext || member is DeclarationBuilder) {
      return InstanceTypeVariableAccessState.Allowed;
    } else {
      return InstanceTypeVariableAccessState.Disallowed;
    }
  }

  @override
  TypeEnvironment get typeEnvironment => typeInferrer.typeSchemaEnvironment;

  DartType get implicitTypeArgument => const ImplicitTypeArgument();

  @override
  bool get enableExtensionTypesInLibrary {
    return libraryBuilder.enableExtensionTypesInLibrary;
  }

  @override
  bool get enableConstFunctionsInLibrary {
    return libraryBuilder.enableConstFunctionsInLibrary;
  }

  @override
  bool get enableConstructorTearOffsInLibrary {
    return libraryBuilder.enableConstructorTearOffsInLibrary;
  }

  @override
  bool get enableNamedArgumentsAnywhereInLibrary {
    return libraryBuilder.enableNamedArgumentsAnywhereInLibrary;
  }

  void _enterLocalState({bool inLateLocalInitializer: false}) {
    _localInitializerState =
        _localInitializerState.prepend(inLateLocalInitializer);
  }

  void _exitLocalState() {
    _localInitializerState = _localInitializerState.tail!;
  }

  @override
  void registerVariableAssignment(VariableDeclaration variable) {
    typeInferrer.assignedVariables.write(variable);
  }

  @override
  VariableDeclarationImpl createVariableDeclarationForValue(
      Expression expression) {
    VariableDeclarationImpl variable =
        forest.createVariableDeclarationForValue(expression);
    typeInferrer.assignedVariables.declare(variable);
    return variable;
  }

  @override
  void push(Object? node) {
    if (node is DartType) {
      unhandled("DartType", "push", -1, uri);
    }
    inInitializerLeftHandSide = false;
    super.push(node);
  }

  Expression popForValue() => toValue(pop());

  Expression popForEffect() => toEffect(pop());

  Expression? popForValueIfNotNull(Object? value) {
    return value == null ? null : popForValue();
  }

  @override
  Expression toValue(Object? node) {
    if (node is Generator) {
      return node.buildSimpleRead();
    } else if (node is Expression) {
      return node;
    } else if (node is SuperInitializer) {
      return buildProblem(
          fasta.messageSuperAsExpression, node.fileOffset, noLength);
    } else if (node is ProblemBuilder) {
      return buildProblem(node.message, node.charOffset, noLength);
    } else {
      return unhandled("${node.runtimeType}", "toValue", -1, uri);
    }
  }

  Expression toEffect(Object? node) {
    if (node is Generator) return node.buildForEffect();
    return toValue(node);
  }

  List<Expression> popListForValue(int n) {
    List<Expression> list =
        new List<Expression>.filled(n, dummyExpression, growable: true);
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForValue();
    }
    return list;
  }

  List<Expression> popListForEffect(int n) {
    List<Expression> list =
        new List<Expression>.filled(n, dummyExpression, growable: true);
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForEffect();
    }
    return list;
  }

  Statement popBlock(int count, Token openBrace, Token? closeBrace) {
    return forest.createBlock(
        offsetForToken(openBrace),
        offsetForToken(closeBrace),
        const GrowableList<Statement>()
                .popNonNullable(stack, count, dummyStatement) ??
            <Statement>[]);
  }

  Statement? popStatementIfNotNull(Object? value) {
    return value == null ? null : popStatement();
  }

  Statement popStatement() => forest.wrapVariables(pop() as Statement);

  Statement? popNullableStatement() {
    Statement? statement = pop(NullValue.Block) as Statement?;
    if (statement != null) {
      statement = forest.wrapVariables(statement);
    }
    return statement;
  }

  void enterSwitchScope() {
    push(switchScope ?? NullValue.SwitchScope);
    switchScope = scope;
  }

  void exitSwitchScope() {
    Scope? outerSwitchScope = pop() as Scope?;
    if (switchScope!.unclaimedForwardDeclarations != null) {
      switchScope!.unclaimedForwardDeclarations!
          .forEach((String name, JumpTarget declaration) {
        if (outerSwitchScope == null) {
          for (Statement statement in declaration.users) {
            statement.parent!.replaceChild(
                statement,
                wrapInProblemStatement(statement,
                    fasta.templateLabelNotFound.withArguments(name)));
          }
        } else {
          outerSwitchScope.forwardDeclareLabel(name, declaration);
        }
      });
    }
    switchScope = outerSwitchScope;
  }

  void wrapVariableInitializerInError(
      VariableDeclaration variable,
      Template<Message Function(String name)> template,
      List<LocatedMessage> context) {
    String name = variable.name!;
    int offset = variable.fileOffset;
    Message message = template.withArguments(name);
    if (variable.initializer == null) {
      variable.initializer =
          buildProblem(message, offset, name.length, context: context)
            ..parent = variable;
    } else {
      variable.initializer = wrapInLocatedProblem(
          variable.initializer!, message.withLocation(uri, offset, name.length),
          context: context)
        ..parent = variable;
    }
  }

  void declareVariable(VariableDeclaration variable, Scope scope) {
    String name = variable.name!;
    Builder? existing = scope.lookupLocalMember(name, setter: false);
    if (existing != null) {
      // This reports an error for duplicated declarations in the same scope:
      // `{ var x; var x; }`
      wrapVariableInitializerInError(
          variable, fasta.templateDuplicatedDeclaration, <LocatedMessage>[
        fasta.templateDuplicatedDeclarationCause
            .withArguments(name)
            .withLocation(uri, existing.charOffset, name.length)
      ]);
      return;
    }
    LocatedMessage? context = scope.declare(
        variable.name!, new VariableBuilderImpl(variable, member, uri), uri);
    if (context != null) {
      // This case is different from the above error. In this case, the problem
      // is using `x` before it's declared: `{ var x; { print(x); var x;
      // }}`. In this case, we want two errors, the `x` in `print(x)` and the
      // second (or innermost declaration) of `x`.
      wrapVariableInitializerInError(
          variable,
          fasta.templateDuplicatedNamePreviouslyUsed,
          <LocatedMessage>[context]);
    }
  }

  @override
  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(
        kind, functionNestingLevel, member as MemberBuilder, charOffset);
  }

  void inferAnnotations(TreeNode? parent, List<Expression>? annotations) {
    if (annotations != null) {
      typeInferrer.inferMetadata(this, parent, annotations);
      libraryBuilder.loader.transformListPostInference(annotations,
          transformSetLiterals, transformCollections, libraryBuilder.library);
    }
  }

  @override
  void beginMetadata(Token token) {
    debugEvent("beginMetadata");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
    assert(checkState(token, [ValueKinds.ConstantContext]));
  }

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    assert(checkState(beginToken, [
      /*arguments*/ ValueKinds.ArgumentsOrNull,
      /*suffix*/ if (periodBeforeName != null)
        unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
      /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
      /*type*/ unionOfKinds([
        ValueKinds.Generator,
        ValueKinds.QualifiedName,
        ValueKinds.ProblemBuilder,
        ValueKinds.ParserRecovery
      ])
    ]));
    debugEvent("Metadata");
    Arguments? arguments = pop() as Arguments?;
    pushQualifiedReference(
        beginToken.next!, periodBeforeName, ConstructorReferenceContext.Const);
    assert(checkState(beginToken, [
      /*constructor name identifier*/ ValueKinds.IdentifierOrNull,
      /*constructor name*/ ValueKinds.Name,
      /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
      /*class*/ unionOfKinds([
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.ParserRecovery
      ]),
    ]));
    if (arguments != null) {
      push(arguments);
      _buildConstructorReferenceInvocation(
          beginToken.next!, beginToken.offset, Constness.explicitConst,
          inMetadata: true, inImplicitCreationContext: false);
      push(popForValue());
    } else {
      pop(); // Name last identifier
      String? name = pop() as String?;
      pop(); // Type arguments (ignored, already reported by parser).
      Object? expression = pop();
      if (expression is Identifier) {
        Identifier identifier = expression;
        expression = new UnresolvedNameGenerator(this, identifier.token,
            new Name(identifier.name, libraryBuilder.nameOrigin),
            unresolvedReadKind: UnresolvedKind.Unknown);
      }
      if (name?.isNotEmpty ?? false) {
        Token period = periodBeforeName ?? beginToken.next!.next!;
        Generator generator = expression as Generator;
        expression = generator.buildSelectorAccess(
            new PropertySelector(
                this, period.next!, new Name(name!, libraryBuilder.nameOrigin)),
            period.next!.offset,
            false);
      }

      ConstantContext savedConstantContext = pop() as ConstantContext;
      if (expression is! StaticAccessGenerator &&
          expression is! VariableUseGenerator &&
          // TODO(johnniwinther): Stop using the type of the generator here.
          // Ask a property instead.
          (expression is! ReadOnlyAccessGenerator ||
              expression is TypeUseGenerator ||
              expression is ParenthesizedExpressionGenerator)) {
        Expression value = toValue(expression);
        push(wrapInProblem(value, fasta.messageExpressionNotMetadata,
            value.fileOffset, noLength));
      } else {
        push(toValue(expression));
      }
      constantContext = savedConstantContext;
    }
    assert(checkState(beginToken, [ValueKinds.Expression]));
  }

  @override
  void endMetadataStar(int count) {
    assert(checkState(null, repeatedKinds(ValueKinds.Expression, count)));
    debugEvent("MetadataStar");
    if (count == 0) {
      push(NullValue.Metadata);
    } else {
      push(const GrowableList<Expression>()
              .popNonNullable(stack, count, dummyExpression) ??
          NullValue.Metadata /* Ignore parser recovery */);
    }
    assert(checkState(null, [ValueKinds.AnnotationListOrNull]));
  }

  @override
  void endTopLevelFields(
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("TopLevelFields");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(lateToken);
      if (externalToken != null) {
        handleRecoverableError(
            fasta.messageExternalField, externalToken, externalToken);
      }
    }
    push(count);
    assert(checkState(beginToken, [ValueKinds.Integer]));
  }

  @override
  void endClassFields(
      Token? abstractToken,
      Token? externalToken,
      Token? staticToken,
      Token? covariantToken,
      Token? lateToken,
      Token? varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("Fields");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(lateToken);
      if (abstractToken != null) {
        handleRecoverableError(
            fasta.messageAbstractClassMember, abstractToken, abstractToken);
      }
      if (externalToken != null) {
        handleRecoverableError(
            fasta.messageExternalField, externalToken, externalToken);
      }
    }
    push(count);
    assert(checkState(beginToken, [ValueKinds.Integer]));
  }

  void finishFields() {
    debugEvent("finishFields");
    assert(checkState(null, [/*field count*/ ValueKinds.Integer]));
    int count = pop() as int;
    List<SourceFieldBuilder> fields = [];
    for (int i = 0; i < count; i++) {
      assert(checkState(null, [
        ValueKinds.FieldInitializerOrNull,
        ValueKinds.Identifier,
      ]));
      Expression? initializer = pop() as Expression?;
      Identifier identifier = pop() as Identifier;
      String name = identifier.name;
      Builder declaration;
      if (declarationBuilder != null) {
        declaration =
            declarationBuilder!.lookupLocalMember(name, required: true)!;
      } else {
        declaration = libraryBuilder.lookupLocalMember(name, required: true)!;
      }
      SourceFieldBuilder fieldBuilder;
      if (declaration.isField && declaration.next == null) {
        fieldBuilder = declaration as SourceFieldBuilder;
      } else {
        continue;
      }
      fields.add(fieldBuilder);
      if (initializer != null) {
        if (fieldBuilder.isDuplicate) {
          // Duplicate definition. The field might not be the correct one,
          // so we skip inference of the initializer.
          // Error reporting and recovery is handled elsewhere.
        } else if (fieldBuilder.hasBodyBeenBuilt) {
          // The initializer was already compiled (e.g., if it appear in the
          // outline, like constant field initializers) so we do not need to
          // perform type inference or transformations.

          // If the body is already built and it's a type aliased constructor or
          // factory invocation, they shouldn't be checked or resolved the
          // second time, so they are removed from the corresponding lists.
          if (initializer is TypeAliasedConstructorInvocation) {
            typeAliasedConstructorInvocations.remove(initializer);
          }
          if (initializer is TypeAliasedFactoryInvocation) {
            typeAliasedFactoryInvocations.remove(initializer);
          }
        } else {
          initializer = typeInferrer
              .inferFieldInitializer(this, fieldBuilder.builtType, initializer)
              .expression;

          if (transformCollections || transformSetLiterals) {
            // Wrap the initializer in a temporary parent expression; the
            // transformations need a parent relation.
            Not wrapper = new Not(initializer);
            libraryBuilder.loader.transformPostInference(
                wrapper,
                transformSetLiterals,
                transformCollections,
                libraryBuilder.library);
            initializer = wrapper.operand;
          }
          fieldBuilder.buildBody(coreTypes, initializer);
        }
      } else if (!fieldBuilder.hasBodyBeenBuilt) {
        fieldBuilder.buildBody(coreTypes, null);
      }
    }
    assert(checkState(
        null, [ValueKinds.TypeOrNull, ValueKinds.AnnotationListOrNull]));
    {
      // TODO(ahe): The type we compute here may be different from what is
      // computed in the outline phase. We should make sure that the outline
      // phase computes the same type. See
      // pkg/front_end/testcases/regress/issue_32200.dart for an example where
      // not calling [buildDartType] leads to a missing compile-time
      // error. Also, notice that the type of the problematic field isn't
      // `invalid-type`.
      TypeBuilder? type = pop() as TypeBuilder?;
      if (type != null) {
        buildDartType(type, allowPotentiallyConstantType: false);
      }
    }
    pop(); // Annotations.

    performBacklogComputations();
    assert(stack.length == 0);
  }

  /// Perform delayed computations that were put on back log during body
  /// building.
  ///
  /// Back logged computations include resolution of redirecting factory
  /// invocations and checking of typedef types.
  void performBacklogComputations(
      [List<DelayedActionPerformer>? delayedActionPerformers]) {
    _finishVariableMetadata();
    _unaliasTypeAliasedConstructorInvocations();
    _unaliasTypeAliasedFactoryInvocations(typeAliasedFactoryInvocations);
    _resolveRedirectingFactoryTargets(redirectingFactoryInvocations);
    libraryBuilder.checkUncheckedTypedefTypes(typeEnvironment);
    if (hasDelayedActions) {
      assert(
          delayedActionPerformers != null,
          "Body builder has delayed actions that cannot be performed: "
          "$delayedRedirectingFactoryInvocations");
      delayedActionPerformers?.add(this);
    }
  }

  void finishRedirectingFactoryBody() {
    performBacklogComputations();
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void endBlockFunctionBody(int count, Token? openBrace, Token closeBrace) {
    debugEvent("BlockFunctionBody");
    if (openBrace == null) {
      assert(count == 0);
      push(NullValue.Block);
    } else {
      Statement block = popBlock(count, openBrace, closeBrace);
      exitLocalScope();
      push(block);
    }
    assert(checkState(closeBrace, [ValueKinds.StatementOrNull]));
  }

  void prepareInitializers() {
    SourceFunctionBuilder member = this.member as SourceFunctionBuilder;
    scope = member.computeFormalParameterInitializerScope(scope);
    if (member is DeclaredSourceConstructorBuilder) {
      member.prepareInitializers();
      if (member.formals != null) {
        for (FormalParameterBuilder formal in member.formals!) {
          if (formal.isInitializingFormal) {
            List<Initializer> initializers;
            if (member.isExternal) {
              initializers = <Initializer>[
                buildInvalidInitializer(
                    buildProblem(
                        fasta.messageExternalConstructorWithFieldInitializers,
                        formal.charOffset,
                        formal.name.length),
                    formal.charOffset)
              ];
            } else {
              initializers = buildFieldInitializer(
                  formal.name,
                  formal.charOffset,
                  formal.charOffset,
                  new VariableGet(formal.variable!),
                  formal: formal);
            }
            for (Initializer initializer in initializers) {
              member.addInitializer(initializer, this, inferenceResult: null);
            }
          }
        }
      }
    }
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    if (functionNestingLevel == 0) {
      prepareInitializers();
      scope = formalParameterScope ?? new Scope.immutable();
    }
  }

  @override
  void beginInitializers(Token token) {
    debugEvent("beginInitializers");
    if (functionNestingLevel == 0) {
      prepareInitializers();
    }
    inConstructorInitializer = true;
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    if (functionNestingLevel == 0) {
      scope = formalParameterScope ?? new Scope.immutable();
    }
    inConstructorInitializer = false;
  }

  @override
  void beginInitializer(Token token) {
    debugEvent("beginInitializer");
    inInitializerLeftHandSide = true;
    inFieldInitializer = true;
  }

  @override
  void endInitializer(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Initializer,
        ValueKinds.Generator,
        ValueKinds.Expression,
      ])
    ]));

    debugEvent("endInitializer");
    inFieldInitializer = false;
    assert(!inInitializerLeftHandSide);
    Object? node = pop();
    List<Initializer> initializers;

    final ModifierBuilder member = this.member;
    if (!(member is ConstructorBuilder && !member.isExternal)) {
      // An error has been reported by the parser.
      initializers = <Initializer>[];
    } else if (node is Initializer) {
      initializers = <Initializer>[node];
    } else if (node is Generator) {
      initializers = node.buildFieldInitializer(initializedFields);
    } else if (node is ConstructorInvocation) {
      initializers = <Initializer>[
        buildSuperInitializer(
            false, node.target, node.arguments, token.charOffset)
      ];
    } else {
      Expression value = toValue(node);
      if (!forest.isThrow(node)) {
        value = wrapInProblem(value, fasta.messageExpectedAnInitializer,
            value.fileOffset, noLength);
      }
      initializers = <Initializer>[
        // TODO(johnniwinther): This should probably be [value] instead of
        //  [node].
        buildInvalidInitializer(node as Expression, token.charOffset)
      ];
    }

    _initializers ??= <Initializer>[];
    _initializers!.addAll(initializers);
  }

  DartType _computeReturnTypeContext(MemberBuilder member) {
    if (member is SourceProcedureBuilder) {
      final bool isReturnTypeUndeclared = member.returnType == null &&
          member.function.returnType is DynamicType;
      return isReturnTypeUndeclared && libraryBuilder.isNonNullableByDefault
          ? const UnknownType()
          : member.function.returnType;
    } else if (member is SourceFactoryBuilder) {
      return member.function.returnType;
    } else {
      assert(member is ConstructorBuilder);
      return const DynamicType();
    }
  }

  void finishFunction(
      FormalParameters? formals, AsyncMarker asyncModifier, Statement? body) {
    debugEvent("finishFunction");
    typeInferrer.assignedVariables.finish();

    final SourceFunctionBuilder builder = member as SourceFunctionBuilder;
    if (extensionThis != null) {
      typeInferrer.flowAnalysis.declare(extensionThis!, true);
    }
    if (formals?.parameters != null) {
      for (int i = 0; i < formals!.parameters!.length; i++) {
        FormalParameterBuilder parameter = formals.parameters![i];
        typeInferrer.flowAnalysis.declare(parameter.variable!, true);
      }
      for (int i = 0; i < formals.parameters!.length; i++) {
        FormalParameterBuilder parameter = formals.parameters![i];
        Expression? initializer = parameter.variable!.initializer;
        if (!parameter.isSuperInitializingFormal &&
            (parameter.isOptional || initializer != null)) {
          if (!parameter.initializerWasInferred) {
            parameter.initializerWasInferred = true;
            if (parameter.isOptional) {
              initializer ??= forest.createNullLiteral(
                  // TODO(ahe): Should store: originParameter.fileOffset
                  // https://github.com/dart-lang/sdk/issues/32289
                  noLocation);
            }
            VariableDeclaration originParameter = builder.getFormalParameter(i);
            initializer = typeInferrer.inferParameterInitializer(
                this,
                initializer!,
                originParameter.type,
                parameter.hasDeclaredInitializer);
            originParameter.initializer = initializer..parent = originParameter;
            libraryBuilder.loader.transformPostInference(
                originParameter,
                transformSetLiterals,
                transformCollections,
                libraryBuilder.library);
          }

          VariableDeclaration? tearOffParameter =
              builder.getTearOffParameter(i);
          if (tearOffParameter != null) {
            Expression tearOffInitializer =
                _cloner.cloneInContext(initializer!);
            tearOffParameter.initializer = tearOffInitializer
              ..parent = tearOffParameter;
            libraryBuilder.loader.transformPostInference(
                tearOffParameter,
                transformSetLiterals,
                transformCollections,
                libraryBuilder.library);
          }
        }
      }
    }
    if (builder is DeclaredSourceConstructorBuilder) {
      finishConstructor(builder, asyncModifier, body);
    } else if (builder is SourceProcedureBuilder) {
      builder.asyncModifier = asyncModifier;
    } else if (builder is SourceFactoryBuilder) {
      builder.asyncModifier = asyncModifier;
    } else {
      unhandled("${builder.runtimeType}", "finishFunction", builder.charOffset,
          builder.fileUri);
    }

    InferredFunctionBody? inferredFunctionBody;
    if (body != null) {
      inferredFunctionBody = typeInferrer.inferFunctionBody(
          this,
          builder.charOffset,
          _computeReturnTypeContext(builder),
          asyncModifier,
          body);
      body = inferredFunctionBody.body;
      builder.function.futureValueType = inferredFunctionBody.futureValueType;
      libraryBuilder.loader.transformPostInference(body, transformSetLiterals,
          transformCollections, libraryBuilder.library);
    }

    if (builder.returnType != null) {
      checkAsyncReturnType(asyncModifier, builder.function.returnType,
          builder.charOffset, builder.name.length);
    }

    if (builder.kind == ProcedureKind.Setter) {
      if (formals?.parameters == null ||
          formals!.parameters!.length != 1 ||
          formals.parameters!.single.isOptional) {
        int charOffset = formals?.charOffset ??
            body?.fileOffset ??
            builder.member.fileOffset;
        if (body == null) {
          body = new EmptyStatement()..fileOffset = charOffset;
        }
        if (builder.formals != null) {
          // Illegal parameters were removed by the function builder.
          // Add them as local variable to put them in scope of the body.
          List<Statement> statements = <Statement>[];
          for (FormalParameterBuilder parameter in builder.formals!) {
            statements.add(parameter.variable!);
          }
          statements.add(body);
          body = forest.createBlock(charOffset, noLocation, statements);
        }
        body = forest.createBlock(charOffset, noLocation, <Statement>[
          forest.createExpressionStatement(
              noLocation,
              // This error is added after type inference is done, so we
              // don't need to wrap errors in SyntheticExpressionJudgment.
              buildProblem(fasta.messageSetterWithWrongNumberOfFormals,
                  charOffset, noLength)),
          body,
        ]);
      }
    }
    // No-such-method forwarders get their bodies injected during outline
    // building, so we should skip them here.
    bool isNoSuchMethodForwarder = (builder.function.parent is Procedure &&
        (builder.function.parent as Procedure).isNoSuchMethodForwarder);
    if (body != null) {
      if (!builder.isExternal && !isNoSuchMethodForwarder) {
        builder.body = body;
      } else {
        builder.body = new Block(<Statement>[
          new ExpressionStatement(buildProblem(
              fasta.messageExternalMethodWithBody, body.fileOffset, noLength))
            ..fileOffset = body.fileOffset,
          body,
        ])
          ..fileOffset = body.fileOffset;
      }
    }

    performBacklogComputations();
  }

  void checkAsyncReturnType(AsyncMarker asyncModifier, DartType returnType,
      int charOffset, int length) {
    // For async, async*, and sync* functions with declared return types, we
    // need to determine whether those types are valid.
    // We use the same trick in each case below. For example to decide whether
    // Future<T> <: [returnType] for every T, we rely on Future<Bot> and
    // transitivity of the subtyping relation because Future<Bot> <: Future<T>
    // for every T.

    // We use [problem == null] to signal success.
    Message? problem;
    switch (asyncModifier) {
      case AsyncMarker.Async:
        DartType futureBottomType = libraryBuilder.loader.futureOfBottom;
        if (!typeEnvironment.isSubtypeOf(
            futureBottomType, returnType, SubtypeCheckMode.withNullabilities)) {
          problem = fasta.messageIllegalAsyncReturnType;
        }
        break;

      case AsyncMarker.AsyncStar:
        DartType streamBottomType = libraryBuilder.loader.streamOfBottom;
        if (returnType is VoidType) {
          problem = fasta.messageIllegalAsyncGeneratorVoidReturnType;
        } else if (!typeEnvironment.isSubtypeOf(
            streamBottomType, returnType, SubtypeCheckMode.withNullabilities)) {
          problem = fasta.messageIllegalAsyncGeneratorReturnType;
        }
        break;

      case AsyncMarker.SyncStar:
        DartType iterableBottomType = libraryBuilder.loader.iterableOfBottom;
        if (returnType is VoidType) {
          problem = fasta.messageIllegalSyncGeneratorVoidReturnType;
        } else if (!typeEnvironment.isSubtypeOf(iterableBottomType, returnType,
            SubtypeCheckMode.withNullabilities)) {
          problem = fasta.messageIllegalSyncGeneratorReturnType;
        }
        break;

      case AsyncMarker.Sync:
        break; // skip
      case AsyncMarker.SyncYielding:
        unexpected("async, async*, sync, or sync*", "$asyncModifier",
            member.charOffset, uri);
    }

    if (problem != null) {
      // TODO(hillerstrom): once types get annotated with location
      // information, we can improve the quality of the error message by
      // using the offset of [returnType] (and the length of its name).
      addProblem(problem, charOffset, length);
    }
  }

  /// Ensure that the containing library of the [member] has been loaded.
  ///
  /// This is for instance important for lazy dill library builders where this
  /// method has to be called to ensure that
  /// a) The library has been fully loaded (and for instance any internal
  ///    transformation needed has been performed); and
  /// b) The library is correctly marked as being used to allow for proper
  ///    'dependency pruning'.
  @override
  void ensureLoaded(Member? member) {
    if (member == null) return;
    Library ensureLibraryLoaded = member.enclosingLibrary;
    LibraryBuilder? builder = libraryBuilder.loader
            .lookupLibraryBuilder(ensureLibraryLoaded.importUri) ??
        libraryBuilder.loader.target.dillTarget.loader
            .lookupLibraryBuilder(ensureLibraryLoaded.importUri);
    if (builder is DillLibraryBuilder) {
      builder.ensureLoaded();
    }
  }

  /// Check if the containing library of the [member] has been loaded.
  ///
  /// This is designed for use with asserts.
  /// See [ensureLoaded] for a description of what 'loaded' means and the ideas
  /// behind that.
  @override
  bool isLoaded(Member? member) {
    if (member == null) return true;
    Library ensureLibraryLoaded = member.enclosingLibrary;
    LibraryBuilder? builder = libraryBuilder.loader
            .lookupLibraryBuilder(ensureLibraryLoaded.importUri) ??
        libraryBuilder.loader.target.dillTarget.loader
            .lookupLibraryBuilder(ensureLibraryLoaded.importUri);
    if (builder is DillLibraryBuilder) {
      return builder.isBuiltAndMarked;
    }
    return true;
  }

  /// Return an [Expression] resolving the argument invocation.
  ///
  /// The arguments specify the [StaticInvocation] whose `.target` is
  /// [target], `.arguments` is [arguments], `.fileOffset` is [fileOffset],
  /// and `.isConst` is [isConst].
  /// Returns null if the invocation can't be resolved.
  Expression? _resolveRedirectingFactoryTarget(
      Procedure target, Arguments arguments, int fileOffset, bool isConst) {
    Procedure initialTarget = target;
    Expression replacementNode;

    RedirectionTarget redirectionTarget =
        getRedirectionTarget(initialTarget, this);
    Member resolvedTarget = redirectionTarget.target;
    if (redirectionTarget.typeArguments.any((type) => type is UnknownType)) {
      return null;
    }

    RedirectingFactoryBody? redirectingFactoryBody =
        getRedirectingFactoryBody(resolvedTarget);
    if (redirectingFactoryBody != null) {
      // If the redirection target is itself a redirecting factory, it means
      // that it is unresolved.
      assert(redirectingFactoryBody.isError);
      String errorMessage = redirectingFactoryBody.errorMessage!;
      replacementNode = new InvalidExpression(errorMessage)
        ..fileOffset = fileOffset;
    } else {
      Substitution substitution = Substitution.fromPairs(
          initialTarget.function.typeParameters, arguments.types);
      for (int i = 0; i < redirectionTarget.typeArguments.length; i++) {
        DartType typeArgument =
            substitution.substituteType(redirectionTarget.typeArguments[i]);
        if (i < arguments.types.length) {
          arguments.types[i] = typeArgument;
        } else {
          arguments.types.add(typeArgument);
        }
      }
      arguments.types.length = redirectionTarget.typeArguments.length;

      replacementNode = buildStaticInvocation(
          resolvedTarget,
          forest.createArguments(noLocation, arguments.positional,
              types: arguments.types,
              named: arguments.named,
              hasExplicitTypeArguments: hasExplicitTypeArguments(arguments)),
          constness: isConst ? Constness.explicitConst : Constness.explicitNew,
          charOffset: fileOffset);
    }
    return replacementNode;
  }

  void _resolveRedirectingFactoryTargets(
      List<FactoryConstructorInvocation> redirectingFactoryInvocations) {
    List<FactoryConstructorInvocation> invocations =
        redirectingFactoryInvocations.toList();
    redirectingFactoryInvocations.clear();
    for (FactoryConstructorInvocation invocation in invocations) {
      // If the invocation was invalid, it or its parent has already been
      // desugared into an exception throwing expression.  There is nothing to
      // resolve anymore.  Note that in the case where the invocation's parent
      // was invalid, type inference won't reach the invocation node and won't
      // set its inferredType field.  If type inference is disabled, reach to
      // the outermost parent to check if the node is a dead code.
      if (invocation.parent == null) continue;
      // ignore: unnecessary_null_comparison
      if (typeInferrer != null) {
        if (!invocation.hasBeenInferred) {
          continue;
        }
      } else {
        TreeNode? parent = invocation.parent;
        while (parent is! Component && parent != null) {
          parent = parent.parent;
        }
        if (parent == null) continue;
      }
      Expression? replacement = _resolveRedirectingFactoryTarget(
          invocation.target,
          invocation.arguments,
          invocation.fileOffset,
          invocation.isConst);
      if (replacement == null) {
        delayedRedirectingFactoryInvocations.add(invocation);
      } else {
        invocation.replaceWith(replacement);
      }
    }
  }

  void _unaliasTypeAliasedConstructorInvocations() {
    for (TypeAliasedConstructorInvocation invocation
        in typeAliasedConstructorInvocations) {
      if (!invocation.hasBeenInferred) {
        assert(
            isOrphaned(invocation), "Node $invocation has not been inferred.");
        continue;
      }
      bool inferred = !hasExplicitTypeArguments(invocation.arguments);
      DartType aliasedType = new TypedefType(
          invocation.typeAliasBuilder.typedef,
          Nullability.nonNullable,
          invocation.arguments.types);
      libraryBuilder.checkBoundsInType(
          aliasedType, typeEnvironment, uri, invocation.fileOffset,
          allowSuperBounded: false, inferred: inferred);
      DartType unaliasedType = aliasedType.unalias;
      List<DartType>? invocationTypeArguments = null;
      if (unaliasedType is InterfaceType) {
        invocationTypeArguments = unaliasedType.typeArguments;
      }
      Arguments invocationArguments = forest.createArguments(
          noLocation, invocation.arguments.positional,
          types: invocationTypeArguments, named: invocation.arguments.named);
      invocation.replaceWith(new ConstructorInvocation(
          invocation.target, invocationArguments,
          isConst: invocation.isConst));
    }
    typeAliasedConstructorInvocations.clear();
  }

  void _unaliasTypeAliasedFactoryInvocations(
      List<TypeAliasedFactoryInvocation> typeAliasedFactoryInvocations) {
    List<TypeAliasedFactoryInvocation> invocations =
        typeAliasedFactoryInvocations.toList();
    typeAliasedFactoryInvocations.clear();
    for (TypeAliasedFactoryInvocation invocation in invocations) {
      if (!invocation.hasBeenInferred) {
        assert(
            isOrphaned(invocation), "Node $invocation has not been inferred.");
        continue;
      }
      bool inferred = !hasExplicitTypeArguments(invocation.arguments);
      DartType aliasedType = new TypedefType(
          invocation.typeAliasBuilder.typedef,
          Nullability.nonNullable,
          invocation.arguments.types);
      libraryBuilder.checkBoundsInType(
          aliasedType, typeEnvironment, uri, invocation.fileOffset,
          allowSuperBounded: false, inferred: inferred);
      DartType unaliasedType = aliasedType.unalias;
      List<DartType>? invocationTypeArguments = null;
      if (unaliasedType is InterfaceType) {
        invocationTypeArguments = unaliasedType.typeArguments;
      }
      Arguments invocationArguments = forest.createArguments(
          noLocation, invocation.arguments.positional,
          types: invocationTypeArguments,
          named: invocation.arguments.named,
          hasExplicitTypeArguments:
              hasExplicitTypeArguments(invocation.arguments));
      Expression? replacement = _resolveRedirectingFactoryTarget(
          invocation.target,
          invocationArguments,
          invocation.fileOffset,
          invocation.isConst);
      if (replacement == null) {
        delayedTypeAliasedFactoryInvocations.add(invocation);
      } else {
        invocation.replaceWith(replacement);
      }
    }
    typeAliasedFactoryInvocations.clear();
  }

  /// Perform actions that were delayed
  ///
  /// An action can be delayed, for instance, because it depends on some
  /// calculations in another library.  For example, a resolution of a
  /// redirecting factory invocation depends on the type inference in the
  /// redirecting factory.
  @override
  void performDelayedActions() {
    if (delayedRedirectingFactoryInvocations.isNotEmpty) {
      _resolveRedirectingFactoryTargets(delayedRedirectingFactoryInvocations);
      if (delayedRedirectingFactoryInvocations.isNotEmpty) {
        for (StaticInvocation invocation
            in delayedRedirectingFactoryInvocations) {
          internalProblem(
              fasta.templateInternalProblemUnhandled.withArguments(
                  invocation.target.name.text, 'performDelayedActions'),
              invocation.fileOffset,
              uri);
        }
      }
    }
    if (delayedTypeAliasedFactoryInvocations.isNotEmpty) {
      _unaliasTypeAliasedFactoryInvocations(
          delayedTypeAliasedFactoryInvocations);
      if (delayedTypeAliasedFactoryInvocations.isNotEmpty) {
        for (StaticInvocation invocation
            in delayedTypeAliasedFactoryInvocations) {
          internalProblem(
              fasta.templateInternalProblemUnhandled.withArguments(
                  invocation.target.name.text, 'performDelayedActions'),
              invocation.fileOffset,
              uri);
        }
      }
    }
  }

  @override
  bool get hasDelayedActions {
    return delayedRedirectingFactoryInvocations.isNotEmpty ||
        delayedTypeAliasedFactoryInvocations.isNotEmpty;
  }

  void _finishVariableMetadata() {
    List<VariableDeclaration>? variablesWithMetadata =
        this.variablesWithMetadata;
    this.variablesWithMetadata = null;
    List<List<VariableDeclaration>>? multiVariablesWithMetadata =
        this.multiVariablesWithMetadata;
    this.multiVariablesWithMetadata = null;

    if (variablesWithMetadata != null) {
      for (int i = 0; i < variablesWithMetadata.length; i++) {
        inferAnnotations(
            variablesWithMetadata[i], variablesWithMetadata[i].annotations);
      }
    }
    if (multiVariablesWithMetadata != null) {
      for (int i = 0; i < multiVariablesWithMetadata.length; i++) {
        List<VariableDeclaration> variables = multiVariablesWithMetadata[i];
        List<Expression> annotations = variables.first.annotations;
        inferAnnotations(variables.first, annotations);
        for (int i = 1; i < variables.length; i++) {
          VariableDeclaration variable = variables[i];
          for (int i = 0; i < annotations.length; i++) {
            variable.addAnnotation(_cloner.cloneInContext(annotations[i]));
          }
        }
      }
    }
  }

  @override
  List<Expression> finishMetadata(Annotatable? parent) {
    assert(checkState(null, [ValueKinds.AnnotationList]));
    List<Expression> expressions = pop() as List<Expression>;
    inferAnnotations(parent, expressions);

    // The invocation of [resolveRedirectingFactoryTargets] below may change the
    // root nodes of the annotation expressions.  We need to have a parent of
    // the annotation nodes before the resolution is performed, to collect and
    // return them later.  If [parent] is not provided, [temporaryParent] is
    // used.
    ListLiteral? temporaryParent;

    if (parent != null) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else {
      temporaryParent = new ListLiteral(expressions);
    }
    performBacklogComputations();
    return temporaryParent != null ? temporaryParent.expressions : expressions;
  }

  @override
  Expression parseSingleExpression(
      Parser parser, Token token, FunctionNode parameters) {
    assert(redirectingFactoryInvocations.isEmpty);
    int fileOffset = offsetForToken(token);
    List<TypeVariableBuilder>? typeParameterBuilders;
    for (TypeParameter typeParameter in parameters.typeParameters) {
      typeParameterBuilders ??= <TypeVariableBuilder>[];
      typeParameterBuilders.add(
          new TypeVariableBuilder.fromKernel(typeParameter, libraryBuilder));
    }
    enterFunctionTypeScope(typeParameterBuilders);

    List<FormalParameterBuilder>? formals =
        parameters.positionalParameters.length == 0
            ? null
            : new List<FormalParameterBuilder>.generate(
                parameters.positionalParameters.length, (int i) {
                VariableDeclaration formal = parameters.positionalParameters[i];
                return new FormalParameterBuilder(null, 0, null, formal.name!,
                    libraryBuilder, formal.fileOffset,
                    fileUri: uri)
                  ..variable = formal;
              }, growable: false);
    enterLocalScope(
        'formalParameters',
        new FormalParameters(formals, fileOffset, noLength, uri)
            .computeFormalParameterScope(scope, member, this));

    Token endToken =
        parser.parseExpression(parser.syntheticPreviousToken(token));

    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ])
    ]));
    Expression expression = popForValue();
    Token eof = endToken.next!;

    if (!eof.isEof) {
      expression = wrapInLocatedProblem(
          expression,
          fasta.messageExpectedOneExpression
              .withLocation(uri, eof.charOffset, eof.length));
    }

    ReturnStatementImpl fakeReturn = new ReturnStatementImpl(true, expression);
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        typeInferrer.flowAnalysis.declare(formals[i].variable!, true);
      }
    }
    InferredFunctionBody inferredFunctionBody = typeInferrer.inferFunctionBody(
        this, fileOffset, const DynamicType(), AsyncMarker.Sync, fakeReturn);
    assert(
        fakeReturn == inferredFunctionBody.body,
        "Previously implicit assumption about inferFunctionBody "
        "not returning anything different.");

    performBacklogComputations();
    libraryBuilder.loader.transformPostInference(fakeReturn,
        transformSetLiterals, transformCollections, libraryBuilder.library);

    return fakeReturn.expression!;
  }

  List<Initializer>? parseInitializers(Token token,
      {bool doFinishConstructor = true}) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    if (!token.isEof) {
      token = parser.parseInitializers(token);
      checkEmpty(token.charOffset);
    } else {
      handleNoInitializers();
    }
    if (doFinishConstructor) {
      finishConstructor(
          member as DeclaredSourceConstructorBuilder, AsyncMarker.Sync, null);
    }
    return _initializers;
  }

  Expression parseFieldInitializer(Token token) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    Token endToken =
        parser.parseExpression(parser.syntheticPreviousToken(token));
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ])
    ]));
    Expression expression = popForValue();
    checkEmpty(endToken.charOffset);
    return expression;
  }

  Expression parseAnnotation(Token token) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    Token endToken = parser.parseMetadata(parser.syntheticPreviousToken(token));
    assert(checkState(token, [ValueKinds.Expression]));
    Expression annotation = pop() as Expression;
    checkEmpty(endToken.charOffset);
    return annotation;
  }

  ArgumentsImpl parseArguments(Token token) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe);
    token = parser.parseArgumentsRest(token);
    ArgumentsImpl arguments = pop() as ArgumentsImpl;
    checkEmpty(token.charOffset);
    return arguments;
  }

  void finishConstructor(DeclaredSourceConstructorBuilder builder,
      AsyncMarker asyncModifier, Statement? body) {
    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf).
    assert(builder == member);
    Constructor constructor = builder.actualConstructor;
    List<FormalParameterBuilder>? formals = builder.formals;
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder parameter = formals[i];
        typeInferrer.flowAnalysis.declare(parameter.variable!, true);
      }
    }

    List<Expression>? positionalSuperParametersAsArguments;
    List<NamedExpression>? namedSuperParametersAsArguments;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isSuperInitializingFormal) {
          if (formal.isNamed) {
            (namedSuperParametersAsArguments ??= <NamedExpression>[]).add(
                new NamedExpression(
                    formal.name,
                    new VariableGetImpl(formal.variable!,
                        forNullGuardedAccess: false)
                      ..fileOffset = formal.charOffset)
                  ..fileOffset = formal.charOffset);
          } else {
            (positionalSuperParametersAsArguments ??= <Expression>[]).add(
                new VariableGetImpl(formal.variable!,
                    forNullGuardedAccess: false)
                  ..fileOffset = formal.charOffset);
          }
        }
      }
    }

    List<Initializer>? initializers = _initializers;
    if (initializers != null && initializers.isNotEmpty) {
      if (initializers.last is SuperInitializer) {
        SuperInitializer superInitializer =
            initializers.last as SuperInitializer;
        if (libraryBuilder.enableSuperParametersInLibrary) {
          Arguments arguments = superInitializer.arguments;

          if (positionalSuperParametersAsArguments != null) {
            if (arguments.positional.isNotEmpty) {
              addProblem(fasta.messagePositionalSuperParametersAndArguments,
                  arguments.fileOffset, noLength,
                  context: <LocatedMessage>[
                    fasta.messageSuperInitializerParameter.withLocation(
                        uri,
                        (positionalSuperParametersAsArguments.first
                                as VariableGet)
                            .variable
                            .fileOffset,
                        noLength)
                  ]);
            } else {
              arguments.positional.addAll(positionalSuperParametersAsArguments);
              setParents(positionalSuperParametersAsArguments, arguments);
            }
          }
          if (namedSuperParametersAsArguments != null) {
            // TODO(cstefantsova): Report name conflicts.
            arguments.named.addAll(namedSuperParametersAsArguments);
            setParents(namedSuperParametersAsArguments, arguments);
          }
        } else if (libraryBuilder.enableEnhancedEnumsInLibrary) {
          initializers[initializers.length - 1] = buildInvalidInitializer(
              buildProblem(fasta.messageEnumConstructorSuperInitializer,
                  superInitializer.fileOffset, noLength))
            ..parent = constructor;
        }
      } else if (initializers.last is RedirectingInitializer) {
        RedirectingInitializer redirectingInitializer =
            initializers.last as RedirectingInitializer;
        if (sourceClassBuilder is SourceEnumBuilder &&
            libraryBuilder.enableEnhancedEnumsInLibrary) {
          ArgumentsImpl arguments =
              redirectingInitializer.arguments as ArgumentsImpl;
          List<Expression> enumSyntheticArguments = [
            new VariableGetImpl(constructor.function.positionalParameters[0],
                forNullGuardedAccess: false)
              ..parent = redirectingInitializer.arguments,
            new VariableGetImpl(constructor.function.positionalParameters[1],
                forNullGuardedAccess: false)
              ..parent = redirectingInitializer.arguments
          ];
          arguments.positional.insertAll(0, enumSyntheticArguments);
          arguments.argumentsOriginalOrder
              ?.insertAll(0, enumSyntheticArguments);
        }
      }

      Map<Initializer, InitializerInferenceResult> inferenceResults =
          <Initializer, InitializerInferenceResult>{};
      for (Initializer initializer in initializers) {
        inferenceResults[initializer] =
            typeInferrer.inferInitializer(this, initializer);
      }
      if (!builder.isExternal) {
        for (Initializer initializer in initializers) {
          builder.addInitializer(initializer, this,
              inferenceResult: inferenceResults[initializer]!);
        }
      }
    }

    if (asyncModifier != AsyncMarker.Sync) {
      constructor.initializers.add(buildInvalidInitializer(buildProblem(
          fasta.messageConstructorNotSync, body!.fileOffset, noLength)));
    }
    if (needsImplicitSuperInitializer) {
      /// >If no superinitializer is provided, an implicit superinitializer
      /// >of the form super() is added at the end of k’s initializer list,
      /// >unless the enclosing class is class Object.
      Constructor? superTarget = lookupConstructor(emptyName, isSuper: true);
      Initializer initializer;
      Arguments arguments;
      List<Expression>? positionalArguments;
      List<NamedExpression>? namedArguments;
      if (libraryBuilder.enableSuperParametersInLibrary) {
        positionalArguments = positionalSuperParametersAsArguments;
        namedArguments = namedSuperParametersAsArguments;
      }
      if (sourceClassBuilder is SourceEnumBuilder) {
        assert(constructor.function.positionalParameters.length >= 2 &&
            constructor.function.positionalParameters[0].name == "index" &&
            constructor.function.positionalParameters[1].name == "name");
        (positionalArguments ??= <Expression>[]).insertAll(0, [
          new VariableGet(constructor.function.positionalParameters[0]),
          new VariableGet(constructor.function.positionalParameters[1])
        ]);
      }
      if (positionalArguments != null || namedArguments != null) {
        arguments = forest.createArguments(
            noLocation, positionalArguments ?? <Expression>[],
            named: namedArguments);
      } else {
        arguments = forest.createArgumentsEmpty(noLocation);
      }
      if (superTarget == null ||
          checkArgumentsForFunction(superTarget.function, arguments,
                  builder.charOffset, const <TypeParameter>[]) !=
              null) {
        String superclass =
            sourceClassBuilder!.supertypeBuilder!.fullNameForErrors;
        int length = constructor.name.text.length;
        if (length == 0) {
          length = (constructor.parent as Class).name.length;
        }
        initializer = buildInvalidInitializer(
            buildProblem(
                fasta.templateSuperclassHasNoDefaultConstructor
                    .withArguments(superclass),
                builder.charOffset,
                length),
            builder.charOffset);
      } else {
        initializer = buildSuperInitializer(
            true, superTarget, arguments, builder.charOffset);
      }
      constructor.initializers.add(initializer);
    }
    setParents(constructor.initializers, constructor);
    libraryBuilder.loader.transformListPostInference(constructor.initializers,
        transformSetLiterals, transformCollections, libraryBuilder.library);
    if (body == null) {
      /// >If a generative constructor c is not a redirecting constructor
      /// >and no body is provided, then c implicitly has an empty body {}.
      /// We use an empty statement instead.
      constructor.function.body = new EmptyStatement()
        ..parent = constructor.function;
    }
  }

  @override
  void handleExpressionStatement(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    debugEvent("ExpressionStatement");
    push(forest.createExpressionStatement(
        offsetForToken(token), popForEffect()));
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List<Object?>? arguments = count == 0
        ? <Object>[]
        : const FixedNullableList<Object>().pop(stack, count);
    if (arguments == null) {
      push(new ParserRecovery(beginToken.charOffset));
      return;
    }
    List<Object?>? argumentsOriginalOrder;
    if (libraryBuilder.enableNamedArgumentsAnywhereInLibrary) {
      argumentsOriginalOrder = new List<Object?>.of(arguments);
    }
    int firstNamedArgumentIndex = arguments.length;
    int positionalCount = 0;
    bool hasNamedBeforePositional = false;
    for (int i = 0; i < arguments.length; i++) {
      Object? node = arguments[i];
      if (node is NamedExpression) {
        firstNamedArgumentIndex =
            i < firstNamedArgumentIndex ? i : firstNamedArgumentIndex;
      } else {
        positionalCount++;
        Expression argument = toValue(node);
        arguments[i] = argument;
        argumentsOriginalOrder?[i] = argument;
        if (i > firstNamedArgumentIndex) {
          hasNamedBeforePositional = true;
          if (!libraryBuilder.enableNamedArgumentsAnywhereInLibrary) {
            arguments[i] = new NamedExpression(
                "#$i",
                buildProblem(fasta.messageExpectedNamedArgument,
                    argument.fileOffset, noLength))
              ..fileOffset = beginToken.charOffset;
          }
        }
      }
    }
    if (!hasNamedBeforePositional) {
      argumentsOriginalOrder = null;
    }
    if (firstNamedArgumentIndex < arguments.length) {
      List<Expression> positional;
      List<NamedExpression> named;
      if (libraryBuilder.enableNamedArgumentsAnywhereInLibrary) {
        positional = new List<Expression>.filled(
            positionalCount, dummyExpression,
            growable: true);
        named = new List<NamedExpression>.filled(
            arguments.length - positionalCount, dummyNamedExpression,
            growable: true);
        int positionalIndex = 0;
        int namedIndex = 0;
        for (int i = 0; i < arguments.length; i++) {
          if (arguments[i] is NamedExpression) {
            named[namedIndex++] = arguments[i] as NamedExpression;
          } else {
            positional[positionalIndex++] = arguments[i] as Expression;
          }
        }
        assert(
            positionalIndex == positional.length && namedIndex == named.length);
      } else {
        // arguments have non-null Expression entries after the initial loop.
        positional = new List<Expression>.from(
            arguments.getRange(0, firstNamedArgumentIndex));
        named = new List<NamedExpression>.from(
            arguments.getRange(firstNamedArgumentIndex, arguments.length));
      }

      push(forest.createArguments(beginToken.offset, positional,
          named: named, argumentsOriginalOrder: argumentsOriginalOrder));
    } else {
      // TODO(kmillikin): Find a way to avoid allocating a second list in the
      // case where there were no named arguments, which is a common one.

      // arguments have non-null Expression entries after the initial loop.
      push(forest.createArguments(
          beginToken.offset, new List<Expression>.from(arguments),
          argumentsOriginalOrder: argumentsOriginalOrder));
    }
    assert(checkState(beginToken, [ValueKinds.Arguments]));
  }

  @override
  void handleParenthesizedCondition(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    debugEvent("ParenthesizedCondition");
    push(popForValue());
    assert(checkState(token, [ValueKinds.Expression]));
  }

  @override
  void handleParenthesizedExpression(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    debugEvent("ParenthesizedExpression");
    Expression value = popForValue();
    if (value is ShadowLargeIntLiteral) {
      // We need to know that the expression was parenthesized because we will
      // treat -n differently from -(n).  If the expression occurs in a double
      // context, -n is a double literal and -(n) is an application of unary- to
      // an integer literal.  And in any other context, '-' is part of the
      // syntax of -n, i.e., -9223372036854775808 is OK and it is the minimum
      // 64-bit integer, and '-' is an application of unary- in -(n), i.e.,
      // -(9223372036854775808) is an error because the literal does not fit in
      // 64-bits.
      push(value..isParenthesized = true);
    } else {
      push(new ParenthesizedExpressionGenerator(this, token.endGroup!, value));
    }
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ]),
    ]));
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    assert(checkState(beginToken, [
      unionOfKinds([
        ValueKinds.ArgumentsOrNull,
        ValueKinds.ParserRecovery,
      ]),
      ValueKinds.TypeArgumentsOrNull,
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Identifier,
        ValueKinds.ParserRecovery,
        ValueKinds.ProblemBuilder
      ])
    ]));
    debugEvent("Send");
    Object? arguments = pop();
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    Object receiver = pop()!;
    // Delay adding [typeArguments] to [forest] for type aliases: They
    // must be unaliased to the type arguments of the denoted type.
    bool isInForest = arguments is Arguments &&
        typeArguments != null &&
        (receiver is! TypeUseGenerator ||
            receiver.declaration is! TypeAliasBuilder);
    if (isInForest) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(
          arguments,
          buildDartTypeArguments(typeArguments,
              allowPotentiallyConstantType: false));
    } else {
      assert(typeArguments == null ||
          (receiver is TypeUseGenerator &&
              receiver.declaration is TypeAliasBuilder));
    }
    if (receiver is ParserRecovery || arguments is ParserRecovery) {
      push(new ParserErrorGenerator(
          this, beginToken, fasta.messageSyntheticToken));
    } else if (receiver is Identifier) {
      Name name = new Name(receiver.name, libraryBuilder.nameOrigin);
      if (arguments == null) {
        push(new PropertySelector(this, beginToken, name));
      } else {
        push(new InvocationSelector(
            this, beginToken, name, typeArguments, arguments as Arguments,
            isTypeArgumentsInForest: isInForest));
      }
    } else if (arguments == null) {
      push(receiver);
    } else {
      push(finishSend(receiver, typeArguments, arguments as ArgumentsImpl,
          beginToken.charOffset,
          isTypeArgumentsInForest: isInForest));
    }
    assert(checkState(beginToken, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Initializer,
        ValueKinds.ProblemBuilder,
        ValueKinds.Selector,
      ])
    ]));
  }

  @override
  Expression_Generator_Initializer finishSend(Object receiver,
      List<TypeBuilder>? typeArguments, ArgumentsImpl arguments, int charOffset,
      {bool isTypeArgumentsInForest = false}) {
    if (receiver is Generator) {
      return receiver.doInvocation(charOffset, typeArguments, arguments,
          isTypeArgumentsInForest: isTypeArgumentsInForest);
    } else {
      return forest.createExpressionInvocation(
          charOffset, toValue(receiver), arguments);
    }
  }

  @override
  void beginCascade(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ]),
    ]));
    debugEvent("beginCascade");
    Expression expression = popForValue();
    if (expression is Cascade) {
      push(expression);
      push(_createReadOnlyVariableAccess(expression.variable, token,
          expression.fileOffset, null, ReadOnlyAccessKind.LetVariable));
    } else {
      bool isNullAware = optional('?..', token);
      if (isNullAware && !libraryBuilder.isNonNullableByDefault) {
        reportMissingNonNullableSupport(token);
      }
      VariableDeclaration variable =
          createVariableDeclarationForValue(expression);
      push(new Cascade(variable, isNullAware: isNullAware)
        ..fileOffset = expression.fileOffset);
      push(_createReadOnlyVariableAccess(variable, token, expression.fileOffset,
          null, ReadOnlyAccessKind.LetVariable));
    }
    assert(checkState(token, [
      ValueKinds.Generator,
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ]),
    ]));
  }

  @override
  void endCascade() {
    assert(checkState(null, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ]),
      ValueKinds.Expression,
    ]));
    debugEvent("endCascade");
    Expression expression = popForEffect();
    Cascade cascadeReceiver = pop() as Cascade;
    cascadeReceiver.addCascadeExpression(expression);
    push(cascadeReceiver);
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    debugEvent("beginCaseExpression");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
    assert(checkState(caseKeyword, [ValueKinds.ConstantContext]));
  }

  @override
  void endCaseExpression(Token colon) {
    assert(checkState(colon, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      ValueKinds.ConstantContext,
    ]));
    debugEvent("endCaseExpression");
    Expression expression = popForValue();
    constantContext = pop() as ConstantContext;
    super.push(expression);
    assert(checkState(colon, [ValueKinds.Expression]));
  }

  @override
  void beginBinaryExpression(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    bool isAnd = optional("&&", token);
    if (isAnd || optional("||", token)) {
      Expression lhs = popForValue();
      // This is matched by the call to [endNode] in
      // [doLogicalExpression].
      if (isAnd) {
        typeInferrer.assignedVariables.beginNode();
      }
      push(lhs);
    }
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
  }

  @override
  void endBinaryExpression(Token token) {
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Selector,
      ]),
    ]));
    debugEvent("BinaryExpression");
    if (optional(".", token) ||
        optional("..", token) ||
        optional("?..", token)) {
      doDotOrCascadeExpression(token);
    } else if (optional("&&", token) || optional("||", token)) {
      doLogicalExpression(token);
    } else if (optional("??", token)) {
      doIfNull(token);
    } else if (optional("?.", token)) {
      doIfNotNull(token);
    } else {
      doBinaryExpression(token);
    }
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Initializer,
      ]),
    ]));
  }

  void doBinaryExpression(Token token) {
    assert(checkState(token, <ValueKind>[
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    Expression right = popForValue();
    Object? left = pop();
    int fileOffset = offsetForToken(token);
    String operator = token.stringValue!;
    bool isNot = identical("!=", operator);
    if (isNot || identical("==", operator)) {
      if (left is Generator) {
        push(left.buildEqualsOperation(token, right, isNot: isNot));
      } else {
        if (left is ProblemBuilder) {
          ProblemBuilder problem = left;
          left = buildProblem(problem.message, problem.charOffset, noLength);
        }
        assert(left is Expression);
        push(forest.createEquals(fileOffset, left as Expression, right,
            isNot: isNot));
      }
    } else {
      Name name = new Name(operator);
      if (!isBinaryOperator(operator) && !isMinusOperator(operator)) {
        if (isUserDefinableOperator(operator)) {
          push(buildProblem(
              fasta.templateNotBinaryOperator.withArguments(token),
              token.charOffset,
              token.length));
        } else {
          push(buildProblem(fasta.templateInvalidOperator.withArguments(token),
              token.charOffset, token.length));
        }
      } else if (left is Generator) {
        push(left.buildBinaryOperation(token, name, right));
      } else {
        if (left is ProblemBuilder) {
          ProblemBuilder problem = left;
          left = buildProblem(problem.message, problem.charOffset, noLength);
        }
        assert(left is Expression);
        push(forest.createBinary(fileOffset, left as Expression, name, right));
      }
    }
    assert(checkState(token, <ValueKind>[
      ValueKinds.Expression,
    ]));
  }

  /// Handle `a && b` and `a || b`.
  void doLogicalExpression(Token token) {
    assert(checkState(token, <ValueKind>[
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    Expression argument = popForValue();
    Expression receiver = pop() as Expression;
    Expression logicalExpression = forest.createLogicalExpression(
        offsetForToken(token), receiver, token.stringValue!, argument);
    push(logicalExpression);
    if (optional("&&", token)) {
      // This is matched by the call to [beginNode] in
      // [beginBinaryExpression].
      typeInferrer.assignedVariables.endNode(logicalExpression);
    }
    assert(checkState(token, <ValueKind>[
      ValueKinds.Expression,
    ]));
  }

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    assert(checkState(token, <ValueKind>[
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    Expression b = popForValue();
    Expression a = popForValue();
    push(new IfNullExpression(a, b)..fileOffset = offsetForToken(token));
    assert(checkState(token, <ValueKind>[
      ValueKinds.Expression,
    ]));
  }

  /// Handle `a?.b(...)`.
  void doIfNotNull(Token token) {
    assert(checkState(token, <ValueKind>[
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Selector,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Initializer,
      ]),
    ]));
    Object? send = pop();
    if (send is Selector) {
      push(send.withReceiver(pop(), token.charOffset, isNullAware: true));
    } else {
      pop();
      token = token.next!;
      push(buildProblem(fasta.templateExpectedIdentifier.withArguments(token),
          offsetForToken(token), lengthForToken(token)));
    }
    assert(checkState(token, <ValueKind>[
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Initializer,
      ]),
    ]));
  }

  void doDotOrCascadeExpression(Token token) {
    assert(checkState(token, <ValueKind>[
      /* after . or .. */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Selector,
      ]),
      /* before . or .. */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Initializer,
      ]),
    ]));
    Object? send = pop();
    if (send is Selector) {
      Object? receiver = optional(".", token) ? pop() : popForValue();
      push(send.withReceiver(receiver, token.charOffset));
    } else if (send is IncompleteErrorGenerator) {
      // Pop the "receiver" and push the error.
      pop();
      push(send);
    } else {
      // Pop the "receiver" and push the error.
      pop();
      token = token.next!;
      push(buildProblem(fasta.templateExpectedIdentifier.withArguments(token),
          offsetForToken(token), lengthForToken(token)));
    }
    assert(checkState(token, <ValueKind>[
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Initializer,
      ]),
    ]));
  }

  bool areArgumentsCompatible(FunctionNode function, Arguments arguments) {
    // TODO(ahe): Implement this.
    return true;
  }

  @override
  Expression buildUnresolvedError(
      Expression receiver, String name, Arguments arguments, int charOffset,
      {Member? candidate,
      bool isSuper: false,
      required UnresolvedKind kind,
      bool isStatic: false,
      LocatedMessage? message}) {
    int length = name.length;
    int periodIndex = name.lastIndexOf(".");
    if (periodIndex != -1) {
      length -= periodIndex + 1;
    }
    Name kernelName = new Name(name, libraryBuilder.nameOrigin);
    List<LocatedMessage>? context;
    if (candidate != null && candidate.location != null) {
      Uri uri = candidate.location!.file;
      int offset = candidate.fileOffset;
      Message contextMessage;
      int length = noLength;
      if (candidate is Constructor && candidate.isSynthetic) {
        offset = candidate.enclosingClass.fileOffset;
        contextMessage = fasta.templateCandidateFoundIsDefaultConstructor
            .withArguments(candidate.enclosingClass.name);
      } else {
        if (candidate is Constructor) {
          if (candidate.name.text == '') {
            length = candidate.enclosingClass.name.length;
          } else {
            // Assume no spaces around the dot. Not perfect, but probably the
            // best we can do with the information available.
            length = candidate.enclosingClass.name.length + 1 + name.length;
          }
        } else {
          length = name.length;
        }
        contextMessage = fasta.messageCandidateFound;
      }
      context = [contextMessage.withLocation(uri, offset, length)];
    }
    if (message == null) {
      switch (kind) {
        case UnresolvedKind.Unknown:
          assert(!isSuper);
          message = fasta.templateNameNotFound
              .withArguments(name)
              .withLocation(uri, charOffset, length);
          break;
        case UnresolvedKind.Member:
          message = warnUnresolvedMember(kernelName, charOffset,
                  isSuper: isSuper, reportWarning: false, context: context)
              .withLocation(uri, charOffset, length);
          break;
        case UnresolvedKind.Getter:
          message = warnUnresolvedGet(kernelName, charOffset,
                  isSuper: isSuper, reportWarning: false, context: context)
              .withLocation(uri, charOffset, length);
          break;
        case UnresolvedKind.Setter:
          message = warnUnresolvedSet(kernelName, charOffset,
                  isSuper: isSuper, reportWarning: false, context: context)
              .withLocation(uri, charOffset, length);
          break;
        case UnresolvedKind.Method:
          message = warnUnresolvedMethod(kernelName, charOffset,
                  isSuper: isSuper, reportWarning: false, context: context)
              .withLocation(uri, charOffset, length);
          break;
        case UnresolvedKind.Constructor:
          message = warnUnresolvedConstructor(kernelName, isSuper: isSuper)
              .withLocation(uri, charOffset, length);
          break;
      }
    }
    return buildProblem(
        message.messageObject, message.charOffset, message.length,
        context: context);
  }

  Message warnUnresolvedMember(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage>? context}) {
    Message message = isSuper
        ? fasta.templateSuperclassHasNoMember.withArguments(name.text)
        : fasta.templateMemberNotFound.withArguments(name.text);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, name.text.length,
          context: context);
    }
    return message;
  }

  @override
  Message warnUnresolvedGet(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage>? context}) {
    Message message = isSuper
        ? fasta.templateSuperclassHasNoGetter.withArguments(name.text)
        : fasta.templateGetterNotFound.withArguments(name.text);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, name.text.length,
          context: context);
    }
    return message;
  }

  @override
  Message warnUnresolvedSet(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage>? context}) {
    Message message = isSuper
        ? fasta.templateSuperclassHasNoSetter.withArguments(name.text)
        : fasta.templateSetterNotFound.withArguments(name.text);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, name.text.length,
          context: context);
    }
    return message;
  }

  @override
  Message warnUnresolvedMethod(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage>? context}) {
    String plainName = name.text;

    int dotIndex = plainName.lastIndexOf(".");
    if (dotIndex != -1) {
      plainName = plainName.substring(dotIndex + 1);
    }
    // TODO(ahe): This is rather brittle. We would probably be better off with
    // more precise location information in this case.
    int length = plainName.length;
    if (plainName.startsWith("[")) {
      length = 1;
    }
    Message message = isSuper
        ? fasta.templateSuperclassHasNoMethod.withArguments(name.text)
        : fasta.templateMethodNotFound.withArguments(name.text);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, length, context: context);
    }
    return message;
  }

  Message warnUnresolvedConstructor(Name name, {bool isSuper: false}) {
    Message message = isSuper
        ? fasta.templateSuperclassHasNoConstructor.withArguments(name.text)
        : fasta.templateConstructorNotFound.withArguments(name.text);
    return message;
  }

  @override
  void warnTypeArgumentsMismatch(String name, int expected, int charOffset) {
    addProblemErrorIfConst(
        fasta.templateTypeArgumentMismatch.withArguments(expected),
        charOffset,
        name.length);
  }

  @override
  Member? lookupSuperMember(Name name, {bool isSetter: false}) {
    return (declarationBuilder as ClassBuilder).lookupInstanceMember(
        hierarchy, name,
        isSetter: isSetter, isSuper: true);
  }

  @override
  Constructor? lookupConstructor(Name name, {bool isSuper: false}) {
    return sourceClassBuilder!.lookupConstructor(name, isSuper: isSuper);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    String name = token.lexeme;
    if (context.isScopeReference) {
      assert(!inInitializerLeftHandSide ||
          this.scope == enclosingScope ||
          this.scope.parent == enclosingScope);
      // This deals with this kind of initializer: `C(a) : a = a;`
      Scope scope = inInitializerLeftHandSide ? enclosingScope : this.scope;
      push(scopeLookup(scope, name, token));
    } else {
      if (!context.inDeclaration &&
          constantContext != ConstantContext.none &&
          !context.allowedInConstantExpression) {
        addProblem(fasta.messageNotAConstantExpression, token.charOffset,
            token.length);
      }
      if (token.isSynthetic) {
        push(new ParserRecovery(offsetForToken(token)));
      } else {
        push(new Identifier(token));
      }
    }
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Identifier,
        ValueKinds.Generator,
        ValueKinds.ParserRecovery,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
  }

  /// Helper method to create a [VariableGet] of the [variable] using
  /// [charOffset] as the file offset.
  @override
  VariableGet createVariableGet(VariableDeclaration variable, int charOffset,
      {bool forNullGuardedAccess: false}) {
    if (!(variable as VariableDeclarationImpl).isLocalFunction) {
      typeInferrer.assignedVariables.read(variable);
    }
    return new VariableGetImpl(variable,
        forNullGuardedAccess: forNullGuardedAccess)
      ..fileOffset = charOffset;
  }

  /// Helper method to create a [ReadOnlyAccessGenerator] on the [variable]
  /// using [token] and [charOffset] for offset information and [name]
  /// for `ExpressionGenerator._plainNameForRead`.
  ReadOnlyAccessGenerator _createReadOnlyVariableAccess(
      VariableDeclaration variable,
      Token token,
      int charOffset,
      String? name,
      ReadOnlyAccessKind kind) {
    return new ReadOnlyAccessGenerator(
        this, token, createVariableGet(variable, charOffset), name ?? '', kind);
  }

  /// Look up [name] in [scope] using [token] as location information (both to
  /// report problems and as the file offset in the generated kernel code).
  /// [isQualified] should be true if [name] is a qualified access (which
  /// implies that it shouldn't be turned into a [ThisPropertyAccessGenerator]
  /// if the name doesn't resolve in the scope).
  @override
  Expression_Generator_Builder scopeLookup(
      Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder? prefix}) {
    int charOffset = offsetForToken(token);
    if (token.isSynthetic) {
      return new ParserErrorGenerator(this, token, fasta.messageSyntheticToken);
    }
    Builder? declaration = scope.lookup(name, charOffset, uri);
    if (declaration == null &&
        prefix == null &&
        (sourceClassBuilder?.isPatch ?? false)) {
      // The scope of a patched method includes the origin class.
      declaration = sourceClassBuilder!.origin
          .findStaticBuilder(name, charOffset, uri, libraryBuilder);
    }
    if (declaration != null &&
        declaration.isDeclarationInstanceMember &&
        (inFieldInitializer && !inLateFieldInitializer) &&
        !inInitializerLeftHandSide) {
      // We cannot access a class instance member in an initializer of a
      // field.
      //
      // For instance
      //
      //     class M {
      //       int foo = bar;
      //       int bar;
      //     }
      //
      return new IncompleteErrorGenerator(this, token,
          fasta.templateThisAccessInFieldInitializer.withArguments(name));
    }
    if (declaration == null ||
        (!isDeclarationInstanceContext &&
            declaration.isDeclarationInstanceMember)) {
      // We either didn't find a declaration or found an instance member from
      // a non-instance context.
      Name n = new Name(name, libraryBuilder.nameOrigin);
      if (!isQualified && isDeclarationInstanceContext) {
        assert(declaration == null);
        if (constantContext != ConstantContext.none ||
            (inFieldInitializer && !inLateFieldInitializer) &&
                !inInitializerLeftHandSide) {
          return new UnresolvedNameGenerator(this, token, n,
              unresolvedReadKind: UnresolvedKind.Unknown);
        }
        if (extensionThis != null) {
          // If we are in an extension instance member we interpret this as an
          // implicit access on the 'this' parameter.
          return PropertyAccessGenerator.make(this, token,
              createVariableGet(extensionThis!, charOffset), n, false);
        } else {
          // This is an implicit access on 'this'.
          return new ThisPropertyAccessGenerator(this, token, n);
        }
      } else if (ignoreMainInGetMainClosure &&
          name == "main" &&
          member.name == "_getMainClosure") {
        return forest.createNullLiteral(charOffset);
      } else {
        return new UnresolvedNameGenerator(this, token, n,
            unresolvedReadKind: UnresolvedKind.Unknown);
      }
    } else if (declaration.isTypeDeclaration) {
      if (declaration is AccessErrorBuilder) {
        AccessErrorBuilder accessError = declaration;
        declaration = accessError.builder;
      }
      return new TypeUseGenerator(
          this, token, declaration as TypeDeclarationBuilder, name);
    } else if (declaration.isLocal) {
      VariableBuilder variableBuilder = declaration as VariableBuilder;
      if (constantContext != ConstantContext.none &&
          !variableBuilder.isConst &&
          !member.isConstructor &&
          !enableConstFunctionsInLibrary) {
        return new IncompleteErrorGenerator(
            this, token, fasta.messageNotAConstantExpression);
      }
      VariableDeclaration variable = variableBuilder.variable!;
      if (!variableBuilder.isAssignable) {
        return _createReadOnlyVariableAccess(
            variable,
            token,
            charOffset,
            name,
            variableBuilder.isConst
                ? ReadOnlyAccessKind.ConstVariable
                : ReadOnlyAccessKind.FinalVariable);
      } else {
        return new VariableUseGenerator(this, token, variable);
      }
    } else if (declaration.isClassInstanceMember) {
      if (constantContext != ConstantContext.none &&
          !inInitializerLeftHandSide &&
          // TODO(ahe): This is a hack because Fasta sets up the scope
          // "this.field" parameters according to old semantics. Under the new
          // semantics, such parameters introduces a new parameter with that
          // name that should be resolved here.
          !member.isConstructor) {
        addProblem(
            fasta.messageNotAConstantExpression, charOffset, token.length);
      }
      Name n = new Name(name, libraryBuilder.nameOrigin);
      return new ThisPropertyAccessGenerator(this, token, n);
    } else if (declaration.isExtensionInstanceMember) {
      ExtensionBuilder extensionBuilder =
          declarationBuilder as ExtensionBuilder;
      MemberBuilder? setterBuilder =
          _getCorrespondingSetterBuilder(scope, declaration, name, charOffset);
      // TODO(johnniwinther): Check for constantContext like below?
      if (declaration.isField) {
        declaration = null;
      }
      if (setterBuilder != null &&
          (setterBuilder.isField || setterBuilder.isStatic)) {
        setterBuilder = null;
      }
      if (declaration == null && setterBuilder == null) {
        return new UnresolvedNameGenerator(
            this, token, new Name(name, libraryBuilder.nameOrigin),
            unresolvedReadKind: UnresolvedKind.Unknown);
      }
      MemberBuilder? getterBuilder =
          declaration is MemberBuilder ? declaration : null;
      return new ExtensionInstanceAccessGenerator.fromBuilder(
          this,
          token,
          extensionBuilder.extension,
          name,
          extensionThis!,
          extensionTypeParameters,
          getterBuilder,
          setterBuilder);
    } else if (declaration.isRegularMethod) {
      assert(declaration.isStatic || declaration.isTopLevel);
      MemberBuilder memberBuilder = declaration as MemberBuilder;
      return new StaticAccessGenerator(
          this, token, name, memberBuilder.member, null);
    } else if (declaration is PrefixBuilder) {
      assert(prefix == null);
      return new PrefixUseGenerator(this, token, declaration);
    } else if (declaration is LoadLibraryBuilder) {
      return new LoadLibraryGenerator(this, token, declaration);
    } else if (declaration.hasProblem && declaration is! AccessErrorBuilder) {
      return declaration;
    } else {
      MemberBuilder? setterBuilder =
          _getCorrespondingSetterBuilder(scope, declaration, name, charOffset);
      MemberBuilder? getterBuilder =
          declaration is MemberBuilder ? declaration : null;
      assert(getterBuilder != null || setterBuilder != null);
      StaticAccessGenerator generator = new StaticAccessGenerator.fromBuilder(
          this, name, token, getterBuilder, setterBuilder);
      if (constantContext != ConstantContext.none) {
        Member? readTarget = generator.readTarget;
        if (!(readTarget is Field && readTarget.isConst ||
            // Static tear-offs are also compile time constants.
            readTarget is Procedure)) {
          addProblem(
              fasta.messageNotAConstantExpression, charOffset, token.length);
        }
      }
      return generator;
    }
  }

  /// Returns the setter builder corresponding to [declaration] using the
  /// [name] and [charOffset] for the lookup into [scope] if necessary.
  MemberBuilder? _getCorrespondingSetterBuilder(
      Scope scope, Builder declaration, String name, int charOffset) {
    Builder? setter;
    if (declaration.isSetter) {
      setter = declaration;
    } else if (declaration.isGetter) {
      setter = scope.lookupSetter(name, charOffset, uri);
    } else if (declaration.isField) {
      MemberBuilder fieldBuilder = declaration as MemberBuilder;
      if (!fieldBuilder.isAssignable) {
        setter = scope.lookupSetter(name, charOffset, uri);
      } else {
        setter = declaration;
      }
    }
    return setter is MemberBuilder ? setter : null;
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified");
    Object? node = pop();
    Object? qualifier = pop();
    if (qualifier is ParserRecovery) {
      push(qualifier);
    } else if (node is ParserRecovery) {
      push(node);
    } else {
      Identifier identifier = node as Identifier;
      push(identifier.withQualifier(qualifier!));
    }
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("StringPart");
    push(token);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop() as Token;
      String value = unescapeString(token.lexeme, token, this);
      push(forest.createStringLiteral(offsetForToken(token), value));
    } else {
      int count = 1 + interpolationCount * 2;
      List<Object>? parts = const FixedNullableList<Object>()
          .popNonNullable(stack, count, /* dummyValue = */ 0);
      if (parts == null) {
        push(new ParserRecovery(endToken.charOffset));
        return;
      }
      Token first = parts.first as Token;
      Token last = parts.last as Token;
      Quote quote = analyzeQuote(first.lexeme);
      List<Expression> expressions = <Expression>[];
      // Contains more than just \' or \".
      if (first.lexeme.length > 1) {
        String value =
            unescapeFirstStringPart(first.lexeme, quote, first, this);
        if (value.isNotEmpty) {
          expressions
              .add(forest.createStringLiteral(offsetForToken(first), value));
        }
      }
      for (int i = 1; i < parts.length - 1; i++) {
        Object part = parts[i];
        if (part is Token) {
          if (part.lexeme.length != 0) {
            String value = unescape(part.lexeme, quote, part, this);
            expressions
                .add(forest.createStringLiteral(offsetForToken(part), value));
          }
        } else {
          expressions.add(toValue(part));
        }
      }
      // Contains more than just \' or \".
      if (last.lexeme.length > 1) {
        String value = unescapeLastStringPart(
            last.lexeme, quote, last, last.isSynthetic, this);
        if (value.isNotEmpty) {
          expressions
              .add(forest.createStringLiteral(offsetForToken(last), value));
        }
      }
      push(forest.createStringConcatenation(
          offsetForToken(endToken), expressions));
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop() as StringLiteral;
    }
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleStringJuxtaposition(Token startToken, int literalCount) {
    debugEvent("StringJuxtaposition");
    List<Expression> parts = popListForValue(literalCount);
    List<Expression>? expressions;
    // Flatten string juxtapositions of string interpolation.
    for (int i = 0; i < parts.length; i++) {
      Expression part = parts[i];
      if (part is StringConcatenation) {
        if (expressions == null) {
          expressions = parts.sublist(0, i);
        }
        for (Expression expression in part.expressions) {
          expressions.add(expression);
        }
      } else {
        if (expressions != null) {
          expressions.add(part);
        }
      }
    }
    push(forest.createStringConcatenation(
        offsetForToken(startToken), expressions ?? parts));
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    int? value = int.tryParse(token.lexeme);
    // Postpone parsing of literals resulting in a negative value
    // (hex literals >= 2^63). These are only allowed when not negated.
    if (value == null || value < 0) {
      push(forest.createIntLiteralLarge(offsetForToken(token), token.lexeme));
    } else {
      push(forest.createIntLiteral(offsetForToken(token), value, token.lexeme));
    }
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    debugEvent("ExpressionFunctionBody");
    endBlockFunctionBody(0, null, semicolon);
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token? endToken) {
    debugEvent("ExpressionFunctionBody");
    endReturnStatement(true, arrowToken.next!, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token? endToken) {
    debugEvent("ReturnStatement");
    Expression? expression = hasExpression ? popForValue() : null;
    if (expression != null && inConstructor) {
      push(buildProblemStatement(
          fasta.messageConstructorWithReturnType, beginToken.charOffset));
    } else {
      push(forest.createReturnStatement(offsetForToken(beginToken), expression,
          isArrow: !identical(beginToken.lexeme, "return")));
    }
  }

  @override
  void beginThenStatement(Token token) {
    Expression condition = popForValue();
    // This is matched by the call to [deferNode] in
    // [endThenStatement].
    typeInferrer.assignedVariables.beginNode();
    push(condition);
    super.beginThenStatement(token);
  }

  @override
  void endThenStatement(Token token) {
    super.endThenStatement(token);
    // This is matched by the call to [beginNode] in
    // [beginThenStatement] and by the call to [storeInfo] in
    // [endIfStatement].
    push(typeInferrer.assignedVariables.deferNode());
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken) {
    Statement? elsePart = popStatementIfNotNull(elseToken);
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo<VariableDeclaration>;
    Statement thenPart = popStatement();
    Expression condition = pop() as Expression;
    Statement node = forest.createIfStatement(
        offsetForToken(ifToken), condition, thenPart, elsePart);
    // This is matched by the call to [deferNode] in
    // [endThenStatement].
    typeInferrer.assignedVariables.storeInfo(node, assignedVariablesInfo);
    push(node);
  }

  @override
  void beginVariableInitializer(Token token) {
    if ((currentLocalVariableModifiers & lateMask) != 0) {
      // This is matched by the call to [endNode] in [endVariableInitializer].
      typeInferrer.assignedVariables.beginNode();
    }
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    AssignedVariablesNodeInfo<VariableDeclaration>? assignedVariablesInfo;
    bool isLate = (currentLocalVariableModifiers & lateMask) != 0;
    Expression initializer = popForValue();
    if (isLate) {
      assignedVariablesInfo = typeInferrer.assignedVariables
          .deferNode(isClosureOrLateVariableInitializer: true);
    }
    pushNewLocalVariable(initializer, equalsToken: assignmentOperator);
    if (isLate) {
      VariableDeclaration node = peek() as VariableDeclaration;
      // This is matched by the call to [beginNode] in
      // [beginVariableInitializer].
      typeInferrer.assignedVariables.storeInfo(node, assignedVariablesInfo!);
    }
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
    bool isConst = (currentLocalVariableModifiers & constMask) != 0;
    bool isFinal = (currentLocalVariableModifiers & finalMask) != 0;
    bool isLate = (currentLocalVariableModifiers & lateMask) != 0;
    Expression? initializer;
    if (!optional("in", token.next!)) {
      // A for-in loop-variable can't have an initializer. So let's remain
      // silent if the next token is `in`. Since a for-in loop can only have
      // one variable it must be followed by `in`.
      if (!token.isSynthetic) {
        // If [token] is synthetic it is created from error recovery.
        if (isConst) {
          initializer = buildProblem(
              fasta.templateConstFieldWithoutInitializer
                  .withArguments(token.lexeme),
              token.charOffset,
              token.length);
        } else if (!libraryBuilder.isNonNullableByDefault &&
            isFinal &&
            !isLate) {
          initializer = buildProblem(
              fasta.templateFinalFieldWithoutInitializer
                  .withArguments(token.lexeme),
              token.charOffset,
              token.length);
        }
      }
    }
    pushNewLocalVariable(initializer);
  }

  void pushNewLocalVariable(Expression? initializer, {Token? equalsToken}) {
    Object? node = pop();
    if (node is ParserRecovery) {
      push(node);
      return;
    }
    Identifier identifier = node as Identifier;
    assert(currentLocalVariableModifiers != -1);
    bool isConst = (currentLocalVariableModifiers & constMask) != 0;
    bool isFinal = (currentLocalVariableModifiers & finalMask) != 0;
    bool isLate = (currentLocalVariableModifiers & lateMask) != 0;
    bool isRequired = (currentLocalVariableModifiers & requiredMask) != 0;
    assert(isConst == (constantContext == ConstantContext.inferred));
    VariableDeclaration variable = new VariableDeclarationImpl(
        identifier.name, functionNestingLevel,
        forSyntheticToken: identifier.token.isSynthetic,
        initializer: initializer,
        type: currentLocalVariableType,
        isFinal: isFinal,
        isConst: isConst,
        isLate: isLate,
        isRequired: isRequired,
        hasDeclaredInitializer: initializer != null,
        isStaticLate: libraryBuilder.isNonNullableByDefault &&
            isFinal &&
            initializer == null)
      ..fileOffset = identifier.charOffset
      ..fileEqualsOffset = offsetForToken(equalsToken);
    typeInferrer.assignedVariables.declare(variable);
    libraryBuilder.checkBoundsInVariableDeclaration(
        variable, typeEnvironment, uri);
    push(variable);
  }

  @override
  void beginFieldInitializer(Token token) {
    inFieldInitializer = true;
    constantContext = member.isConst
        ? ConstantContext.inferred
        : !member.isStatic &&
                sourceClassBuilder != null &&
                sourceClassBuilder!.declaresConstConstructor
            ? ConstantContext.required
            : ConstantContext.none;
    if (member is SourceFieldBuilder) {
      SourceFieldBuilder fieldBuilder = member as SourceFieldBuilder;
      inLateFieldInitializer = fieldBuilder.isLate;
      if (fieldBuilder.isAbstract) {
        addProblem(
            fasta.messageAbstractFieldInitializer, token.charOffset, noLength);
      } else if (fieldBuilder.isExternal) {
        addProblem(
            fasta.messageExternalFieldInitializer, token.charOffset, noLength);
      }
    } else {
      inLateFieldInitializer = false;
    }
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer");
    inFieldInitializer = false;
    inLateFieldInitializer = false;
    assert(assignmentOperator.stringValue == "=");
    push(popForValue());
    constantContext = ConstantContext.none;
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    constantContext = member.isConst
        ? ConstantContext.inferred
        : !member.isStatic &&
                sourceClassBuilder != null &&
                sourceClassBuilder!.declaresConstConstructor
            ? ConstantContext.required
            : ConstantContext.none;
    if (constantContext == ConstantContext.inferred) {
      // Creating a null value to prevent the Dart VM from crashing.
      push(forest.createNullLiteral(offsetForToken(token)));
    } else {
      push(NullValue.FieldInitializer);
    }
    constantContext = ConstantContext.none;
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    // TODO(ahe): Use [InitializedIdentifier] here?
    debugEvent("InitializedIdentifier");
    Object? node = pop();
    if (node is ParserRecovery) {
      push(node);
      return;
    }
    VariableDeclaration variable = node as VariableDeclaration;
    variable.fileOffset = nameToken.charOffset;
    push(variable);
    declareVariable(variable, scope);
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token? lateToken, Token? varFinalOrConst) {
    debugEvent("beginVariablesDeclaration");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(lateToken);
    }
    TypeBuilder? unresolvedType = pop(NullValue.TypeBuilder) as TypeBuilder?;
    DartType? type = unresolvedType != null
        ? buildDartType(unresolvedType, allowPotentiallyConstantType: false)
        : null;
    int modifiers = (lateToken != null ? lateMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    _enterLocalState(inLateLocalInitializer: lateToken != null);
    super.push(currentLocalVariableModifiers);
    super.push(currentLocalVariableType ?? NullValue.Type);
    currentLocalVariableType = type;
    currentLocalVariableModifiers = modifiers;
    super.push(constantContext);
    constantContext = ((modifiers & constMask) != 0)
        ? ConstantContext.inferred
        : ConstantContext.none;
  }

  @override
  void endVariablesDeclaration(int count, Token? endToken) {
    debugEvent("VariablesDeclaration");
    if (count == 1) {
      Object? node = pop();
      constantContext = pop() as ConstantContext;
      currentLocalVariableType = pop(NullValue.Type) as DartType?;
      currentLocalVariableModifiers = pop() as int;
      List<Expression>? annotations = pop() as List<Expression>?;
      if (node is ParserRecovery) {
        push(node);
        return;
      }
      VariableDeclaration variable = node as VariableDeclaration;
      if (annotations != null) {
        for (int i = 0; i < annotations.length; i++) {
          variable.addAnnotation(annotations[i]);
        }
        (variablesWithMetadata ??= <VariableDeclaration>[]).add(variable);
      }
      push(variable);
    } else {
      List<VariableDeclaration>? variables =
          const FixedNullableList<VariableDeclaration>()
              .popNonNullable(stack, count, dummyVariableDeclaration);
      constantContext = pop() as ConstantContext;
      currentLocalVariableType = pop(NullValue.Type) as DartType?;
      currentLocalVariableModifiers = pop() as int;
      List<Expression>? annotations = pop() as List<Expression>?;
      if (variables == null) {
        push(new ParserRecovery(offsetForToken(endToken)));
        return;
      }
      if (annotations != null) {
        VariableDeclaration first = variables.first;
        for (int i = 0; i < annotations.length; i++) {
          first.addAnnotation(annotations[i]);
        }
        (multiVariablesWithMetadata ??= <List<VariableDeclaration>>[])
            .add(variables);
      }
      push(forest.variablesDeclaration(variables, uri));
    }
    _exitLocalState();
  }

  /// Stack containing assigned variables info for try statements.
  ///
  /// These are created in [beginTryStatement] and ended in either [beginBlock]
  /// when a finally block starts or in [endTryStatement] when the try statement
  /// ends. Since these need to be associated with the try statement created in
  /// in [endTryStatement] we store them the stack until the try statement is
  /// created.
  Link<AssignedVariablesNodeInfo<VariableDeclaration>> tryStatementInfoStack =
      const Link<AssignedVariablesNodeInfo<VariableDeclaration>>();

  @override
  void beginBlock(Token token, BlockKind blockKind) {
    if (blockKind == BlockKind.tryStatement) {
      // This is matched by the call to [endNode] in [endBlock].
      typeInferrer.assignedVariables.beginNode();
    } else if (blockKind == BlockKind.finallyClause) {
      // This is matched by the call to [beginNode] in [beginTryStatement].
      tryStatementInfoStack = tryStatementInfoStack
          .prepend(typeInferrer.assignedVariables.deferNode());
    }
    super.beginBlock(token, blockKind);
  }

  @override
  void endBlock(
      int count, Token openBrace, Token closeBrace, BlockKind blockKind) {
    debugEvent("Block");
    Statement block = popBlock(count, openBrace, closeBrace);
    exitLocalScope();
    push(block);
    if (blockKind == BlockKind.tryStatement) {
      // This is matched by the call to [beginNode] in [beginBlock].
      typeInferrer.assignedVariables.endNode(block);
    }
  }

  @override
  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  @override
  void handleAssignmentExpression(Token token) {
    assert(checkState(token, [
      unionOfKinds(<ValueKind>[
        ValueKinds.Expression,
        ValueKinds.Generator,
        // TODO(johnniwinther): Avoid problem builders here.
        ValueKinds.ProblemBuilder
      ]),
      unionOfKinds(<ValueKind>[
        ValueKinds.Expression, ValueKinds.Generator,
        // TODO(johnniwinther): Avoid problem builders here.
        ValueKinds.ProblemBuilder
      ])
    ]));
    debugEvent("AssignmentExpression");
    Expression value = popForValue();
    Object? generator = pop();
    if (generator is! Generator) {
      push(buildProblem(fasta.messageNotAnLvalue, offsetForToken(token),
          lengthForToken(token)));
    } else {
      push(new DelayedAssignment(
          this, token, generator, value, token.stringValue!));
    }
  }

  @override
  void enterLoop(int charOffset) {
    if (peek() is LabelTarget) {
      LabelTarget target = peek() as LabelTarget;
      enterBreakTarget(charOffset, target.breakTarget);
      enterContinueTarget(charOffset, target.continueTarget);
    } else {
      enterBreakTarget(charOffset);
      enterContinueTarget(charOffset);
    }
  }

  void exitLoopOrSwitch(Statement statement) {
    if (problemInLoopOrSwitch != null) {
      push(problemInLoopOrSwitch);
      problemInLoopOrSwitch = null;
    } else {
      push(statement);
    }
  }

  List<VariableDeclaration>? _buildForLoopVariableDeclarations(
      variableOrExpression) {
    // TODO(ahe): This can be simplified now that we have the events
    // `handleForInitializer...` events.
    if (variableOrExpression is Generator) {
      variableOrExpression = variableOrExpression.buildForEffect();
    }
    if (variableOrExpression is VariableDeclaration) {
      // Late for loop variables are not supported. An error has already been
      // reported by the parser.
      variableOrExpression.isLate = false;
      return <VariableDeclaration>[variableOrExpression];
    } else if (variableOrExpression is Expression) {
      VariableDeclaration variable =
          new VariableDeclarationImpl.forEffect(variableOrExpression);
      return <VariableDeclaration>[variable];
    } else if (variableOrExpression is ExpressionStatement) {
      VariableDeclaration variable = new VariableDeclarationImpl.forEffect(
          variableOrExpression.expression);
      return <VariableDeclaration>[variable];
    } else if (forest.isVariablesDeclaration(variableOrExpression)) {
      return forest
          .variablesDeclarationExtractDeclarations(variableOrExpression);
    } else if (variableOrExpression is List<Object>) {
      List<VariableDeclaration> variables = <VariableDeclaration>[];
      for (Object v in variableOrExpression) {
        variables.addAll(_buildForLoopVariableDeclarations(v)!);
      }
      return variables;
    } else if (variableOrExpression == null) {
      return <VariableDeclaration>[];
    }
    return null;
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement");
    push(NullValue.Expression);
    // This is matched by the call to [deferNode] in [endForStatement] or
    // [endForControlFlow].
    typeInferrer.assignedVariables.beginNode();
  }

  @override
  void handleForInitializerExpressionStatement(Token token, bool forIn) {
    debugEvent("ForInitializerExpressionStatement");
    if (!forIn) {
      // This is matched by the call to [deferNode] in [endForStatement] or
      // [endForControlFlow].
      typeInferrer.assignedVariables.beginNode();
    }
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token, bool forIn) {
    debugEvent("ForInitializerLocalVariableDeclaration");
    if (forIn) {
      // If the declaration is of the form `for (final x in ...)`, then we may
      // have erroneously set the `isStaticLate` flag, so un-set it.
      Object? declaration = peek();
      if (declaration is VariableDeclarationImpl) {
        declaration.isStaticLate = false;
      }
    } else {
      // This is matched by the call to [deferNode] in [endForStatement] or
      // [endForControlFlow].
      typeInferrer.assignedVariables.beginNode();
    }
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    push(forKeyword);
    push(leftParen);
    push(leftSeparator);
    push(updateExpressionCount);
  }

  @override
  void endForControlFlow(Token token) {
    debugEvent("ForControlFlow");
    Object? entry = pop();
    int updateExpressionCount = pop() as int;
    pop(); // left separator
    pop(); // left parenthesis
    Token forToken = pop() as Token;
    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement(); // condition

    if (constantContext != ConstantContext.none) {
      pop(); // Pop variable or expression.
      exitLocalScope();
      typeInferrer.assignedVariables.discardNode();

      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(forToken),
          forToken,
          forToken);
      push(invalidCollectionElement);
      return;
    }

    // This is matched by the call to [beginNode] in
    // [handleForInitializerEmptyStatement],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.popNode();

    Object? variableOrExpression = pop();
    exitLocalScope();

    transformCollections = true;
    List<VariableDeclaration> variables =
        _buildForLoopVariableDeclarations(variableOrExpression)!;
    typeInferrer.assignedVariables.pushNode(assignedVariablesNodeInfo);
    Expression? condition;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is EmptyStatement);
    }
    if (entry is MapLiteralEntry) {
      ForMapEntry result = forest.createForMapEntry(
          offsetForToken(forToken), variables, condition, updates, entry);
      typeInferrer.assignedVariables.endNode(result);
      push(result);
    } else {
      ForElement result = forest.createForElement(offsetForToken(forToken),
          variables, condition, updates, toValue(entry));
      typeInferrer.assignedVariables.endNode(result);
      push(result);
    }
  }

  @override
  void endForStatement(Token endToken) {
    assert(checkState(endToken, <ValueKind>[
      /* body */ ValueKinds.Statement,
      /* expression count */ ValueKinds.Integer,
      /* left separator */ ValueKinds.Token,
      /* left parenthesis */ ValueKinds.Token,
      /* for keyword */ ValueKinds.Token,
    ]));
    debugEvent("ForStatement");
    Statement body = popStatement();

    int updateExpressionCount = pop() as int;
    pop(); // Left separator.
    pop(); // Left parenthesis.
    Token forKeyword = pop() as Token;

    assert(checkState(endToken, <ValueKind>[
      /* expressions */ ...repeatedKinds(
          unionOfKinds(
              <ValueKind>[ValueKinds.Expression, ValueKinds.Generator]),
          updateExpressionCount),
      /* condition */ ValueKinds.Statement,
      /* variable or expression */ unionOfKinds(<ValueKind>[
        ValueKinds.Generator,
        ValueKinds.ExpressionOrNull,
        ValueKinds.Statement,
        ValueKinds.ObjectList,
        ValueKinds.ParserRecovery,
      ]),
    ]));

    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement();
    // This is matched by the call to [beginNode] in
    // [handleForInitializerEmptyStatement],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.deferNode();

    Object? variableOrExpression = pop();
    List<VariableDeclaration>? variables =
        _buildForLoopVariableDeclarations(variableOrExpression);
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget() as JumpTarget;
    JumpTarget breakTarget = exitBreakTarget() as JumpTarget;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements =
          continueTarget.resolveContinues(forest, labeledStatement);
      body = labeledStatement;
    }
    Expression? condition;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is EmptyStatement);
    }
    Statement forStatement = forest.createForStatement(
        offsetForToken(forKeyword), variables, condition, updates, body);
    typeInferrer.assignedVariables
        .storeInfo(forStatement, assignedVariablesNodeInfo);
    if (continueStatements != null) {
      for (BreakStatementImpl continueStatement in continueStatements) {
        continueStatement.targetStatement = forStatement;
      }
    }
    Statement result = forStatement;
    if (breakTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(result);
      breakTarget.resolveBreaks(forest, labeledStatement, forStatement);
      result = labeledStatement;
    }
    if (variableOrExpression is ParserRecovery) {
      problemInLoopOrSwitch ??= buildProblemStatement(
          fasta.messageSyntheticToken, variableOrExpression.charOffset,
          suppressMessage: true);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void endAwaitExpression(Token keyword, Token endToken) {
    debugEvent("AwaitExpression");
    int fileOffset = offsetForToken(keyword);
    Expression value = popForValue();
    if (inLateLocalInitializer) {
      push(buildProblem(fasta.messageAwaitInLateLocalInitializer, fileOffset,
          keyword.charCount));
    } else {
      push(forest.createAwaitExpression(fileOffset, value));
    }
  }

  @override
  void endInvalidAwaitExpression(
      Token keyword, Token endToken, fasta.MessageCode errorCode) {
    debugEvent("AwaitExpression");
    popForValue();
    push(buildProblem(errorCode, keyword.offset, keyword.length));
  }

  @override
  void endInvalidYieldStatement(Token keyword, Token? starToken, Token endToken,
      fasta.MessageCode errorCode) {
    debugEvent("YieldStatement");
    popForValue();
    push(buildProblemStatement(errorCode, keyword.offset));
  }

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token? constKeyword, Token rightBracket) {
    debugEvent("LiteralList");

    if (constantContext == ConstantContext.required && constKeyword == null) {
      addProblem(fasta.messageMissingExplicitConst, offsetForToken(leftBracket),
          noLength);
    }

    // TODO(danrubel): Replace this with popListForValue
    // when control flow and spread collections have been enabled by default
    List<Expression> expressions =
        new List<Expression>.filled(count, dummyExpression, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      Object? elem = pop();
      if (elem != invalidCollectionElement) {
        expressions[i] = toValue(elem);
      } else {
        expressions.removeAt(i);
      }
    }

    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;

    DartType typeArgument;
    if (typeArguments != null) {
      if (typeArguments.length > 1) {
        addProblem(
            fasta.messageListLiteralTooManyTypeArguments,
            offsetForToken(leftBracket),
            lengthOfSpan(leftBracket, leftBracket.endGroup));
        typeArgument = const InvalidType();
      } else {
        typeArgument = buildDartType(typeArguments.single,
            allowPotentiallyConstantType: false);
        typeArgument = instantiateToBounds(
            typeArgument, coreTypes.objectClass, libraryBuilder.library);
      }
    } else {
      typeArgument = implicitTypeArgument;
    }

    ListLiteral node = forest.createListLiteral(
        // TODO(johnniwinther): The file offset computed below will not be
        // correct if there are type arguments but no `const` keyword.
        offsetForToken(constKeyword ?? leftBracket),
        typeArgument,
        expressions,
        isConst: constKeyword != null ||
            constantContext == ConstantContext.inferred);
    libraryBuilder.checkBoundsInListLiteral(node, typeEnvironment, uri);
    push(node);
  }

  void buildLiteralSet(List<TypeBuilder>? typeArguments, Token? constKeyword,
      Token leftBrace, List<dynamic>? setOrMapEntries) {
    DartType typeArgument;
    if (typeArguments != null) {
      typeArgument = buildDartType(typeArguments.single,
          allowPotentiallyConstantType: false);
      typeArgument = instantiateToBounds(
          typeArgument, coreTypes.objectClass, libraryBuilder.library);
    } else {
      typeArgument = implicitTypeArgument;
    }

    List<Expression> expressions = <Expression>[];
    if (setOrMapEntries != null) {
      for (dynamic entry in setOrMapEntries) {
        if (entry is MapLiteralEntry) {
          // TODO(danrubel): report the error on the colon
          addProblem(fasta.templateExpectedButGot.withArguments(','),
              entry.fileOffset, 1);
        } else {
          // TODO(danrubel): Revise once control flow and spread
          //  collection entries are supported.
          expressions.add(entry as Expression);
        }
      }
    }

    SetLiteral node = forest.createSetLiteral(
        // TODO(johnniwinther): The file offset computed below will not be
        // correct if there are type arguments but no `const` keyword.
        offsetForToken(constKeyword ?? leftBrace),
        typeArgument,
        expressions,
        isConst: constKeyword != null ||
            constantContext == ConstantContext.inferred);
    libraryBuilder.checkBoundsInSetLiteral(node, typeEnvironment, uri);
    push(node);
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token? constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    debugEvent("LiteralSetOrMap");

    if (constantContext == ConstantContext.required && constKeyword == null) {
      addProblem(fasta.messageMissingExplicitConst, offsetForToken(leftBrace),
          noLength);
    }

    List<dynamic> setOrMapEntries =
        new List<dynamic>.filled(count, null, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      Object? elem = pop();
      // TODO(danrubel): Revise this to handle control flow and spread
      if (elem == invalidCollectionElement) {
        setOrMapEntries.removeAt(i);
      } else if (elem is MapLiteralEntry) {
        setOrMapEntries[i] = elem;
      } else {
        setOrMapEntries[i] = toValue(elem);
      }
    }
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;

    // Replicate existing behavior that has been removed from the parser.
    // This will be removed once unified collections is implemented.

    // Determine if this is a set or map based on type args and content
    // TODO(danrubel): Since type resolution is needed to disambiguate
    // set or map in some situations, consider always deferring determination
    // until the type resolution phase.
    final int? typeArgCount = typeArguments?.length;
    bool? isSet = typeArgCount == 1
        ? true
        : typeArgCount != null
            ? false
            : null;

    for (int i = 0; i < setOrMapEntries.length; ++i) {
      if (setOrMapEntries[i] is! MapLiteralEntry &&
          !isConvertibleToMapEntry(setOrMapEntries[i])) {
        hasSetEntry = true;
      }
    }

    // TODO(danrubel): If the type arguments are not known (null) then
    // defer set/map determination until after type resolution as per the
    // unified collection spec: https://github.com/dart-lang/language/pull/200
    // rather than trying to guess as done below.
    isSet ??= hasSetEntry;

    if (isSet) {
      buildLiteralSet(typeArguments, constKeyword, leftBrace, setOrMapEntries);
    } else {
      List<MapLiteralEntry> mapEntries = new List<MapLiteralEntry>.filled(
          setOrMapEntries.length, dummyMapLiteralEntry);
      for (int i = 0; i < setOrMapEntries.length; ++i) {
        if (setOrMapEntries[i] is MapLiteralEntry) {
          mapEntries[i] = setOrMapEntries[i];
        } else {
          mapEntries[i] = convertToMapEntry(setOrMapEntries[i], this,
              typeInferrer.assignedVariables.reassignInfo);
        }
      }
      buildLiteralMap(typeArguments, constKeyword, leftBrace, mapEntries);
    }
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = optional("true", token);
    assert(value || optional("false", token));
    push(forest.createBoolLiteral(offsetForToken(token), value));
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(forest.createDoubleLiteral(
        offsetForToken(token), double.parse(token.lexeme)));
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(forest.createNullLiteral(offsetForToken(token)));
  }

  void buildLiteralMap(List<TypeBuilder>? typeArguments, Token? constKeyword,
      Token leftBrace, List<MapLiteralEntry> entries) {
    DartType keyType;
    DartType valueType;
    if (typeArguments != null) {
      if (typeArguments.length != 2) {
        keyType = const InvalidType();
        valueType = const InvalidType();
      } else {
        keyType = buildDartType(typeArguments[0],
            allowPotentiallyConstantType: false);
        valueType = buildDartType(typeArguments[1],
            allowPotentiallyConstantType: false);
        keyType = instantiateToBounds(
            keyType, coreTypes.objectClass, libraryBuilder.library);
        valueType = instantiateToBounds(
            valueType, coreTypes.objectClass, libraryBuilder.library);
      }
    } else {
      DartType implicitTypeArgument = this.implicitTypeArgument;
      keyType = implicitTypeArgument;
      valueType = implicitTypeArgument;
    }

    MapLiteral node = forest.createMapLiteral(
        // TODO(johnniwinther): The file offset computed below will not be
        // correct if there are type arguments but no `const` keyword.
        offsetForToken(constKeyword ?? leftBrace),
        keyType,
        valueType,
        entries,
        isConst: constKeyword != null ||
            constantContext == ConstantContext.inferred);
    libraryBuilder.checkBoundsInMapLiteral(node, typeEnvironment, uri);
    push(node);
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry");
    Expression value = popForValue();
    Expression key = popForValue();
    push(forest.createMapEntry(offsetForToken(colon), key, value));
  }

  String symbolPartToString(name) {
    if (name is Identifier) {
      return name.name;
    } else if (name is Operator) {
      return name.name;
    } else {
      return unhandled("${name.runtimeType}", "symbolPartToString", -1, uri);
    }
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    debugEvent("LiteralSymbol");
    if (identifierCount == 1) {
      Object? part = pop();
      if (part is ParserRecovery) {
        push(new ParserErrorGenerator(
            this, hashToken, fasta.messageSyntheticToken));
      } else {
        push(forest.createSymbolLiteral(
            offsetForToken(hashToken), symbolPartToString(part)));
      }
    } else {
      List<Identifier>? parts = const FixedNullableList<Identifier>()
          .popNonNullable(stack, identifierCount, dummyIdentifier);
      if (parts == null) {
        push(new ParserErrorGenerator(
            this, hashToken, fasta.messageSyntheticToken));
        return;
      }
      String value = symbolPartToString(parts.first);
      for (int i = 1; i < parts.length; i++) {
        value += ".${symbolPartToString(parts[i])}";
      }
      push(forest.createSymbolLiteral(offsetForToken(hashToken), value));
    }
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    assert(checkState(bang, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.Initializer,
        ValueKinds.ProblemBuilder
      ])
    ]));
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullAssertExpressionNotEnabled(bang);
    }
    Expression operand = popForValue();
    push(forest.createNullCheck(offsetForToken(bang), operand));
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    // TODO(ahe): The scope is wrong for return types of generic functions.
    debugEvent("Type");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }
    bool isMarkedAsNullable = questionMark != null;
    List<TypeBuilder>? arguments = pop() as List<TypeBuilder>?;
    Object? name = pop();
    if (name is QualifiedName) {
      QualifiedName qualified = name;
      Object prefix = qualified.qualifier;
      Token suffix = qualified.suffix;
      if (prefix is Generator) {
        name = prefix.qualifiedLookup(suffix);
      } else {
        String name = getNodeName(prefix);
        String displayName = debugName(name, suffix.lexeme);
        int offset = offsetForToken(beginToken);
        Message message = fasta.templateNotAType.withArguments(displayName);
        libraryBuilder.addProblem(
            message, offset, lengthOfSpan(beginToken, suffix), uri);
        push(new NamedTypeBuilder.fromTypeDeclarationBuilder(
            new InvalidTypeDeclarationBuilder(
                name,
                message.withLocation(
                    uri, offset, lengthOfSpan(beginToken, suffix))),
            libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable),
            fileUri: uri,
            charOffset: offset,
            instanceTypeVariableAccess:
                InstanceTypeVariableAccessState.Unexpected));
        return;
      }
    }
    TypeBuilder? result;
    if (name is Generator) {
      bool allowPotentiallyConstantType;
      if (libraryBuilder.isNonNullableByDefault) {
        if (enableConstructorTearOffsInLibrary) {
          allowPotentiallyConstantType = true;
        } else {
          allowPotentiallyConstantType = inIsOrAsOperatorType;
        }
      } else {
        allowPotentiallyConstantType = false;
      }
      result = name.buildTypeWithResolvedArguments(
          libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable), arguments,
          allowPotentiallyConstantType: allowPotentiallyConstantType);
      // ignore: unnecessary_null_comparison
      if (result == null) {
        unhandled("null", "result", beginToken.charOffset, uri);
      }
    } else if (name is ProblemBuilder) {
      // TODO(ahe): Arguments could be passed here.
      libraryBuilder.addProblem(
          name.message, name.charOffset, name.name.length, name.fileUri);
      result = new NamedTypeBuilder.fromTypeDeclarationBuilder(
          new InvalidTypeDeclarationBuilder(
              name.name,
              name.message.withLocation(
                  name.fileUri, name.charOffset, name.name.length)),
          libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable),
          fileUri: name.fileUri,
          charOffset: name.charOffset,
          instanceTypeVariableAccess:
              InstanceTypeVariableAccessState.Unexpected);
    } else {
      unhandled(
          "${name.runtimeType}", "handleType", beginToken.charOffset, uri);
    }
    push(result);
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
  }

  void enterFunctionTypeScope(List<TypeVariableBuilder>? typeVariables) {
    debugEvent("enterFunctionTypeScope");
    enterLocalScope('FunctionTypeScope',
        scope.createNestedScope("function-type scope", isModifiable: true));
    if (typeVariables != null) {
      ScopeBuilder scopeBuilder = new ScopeBuilder(scope);
      for (TypeVariableBuilder builder in typeVariables) {
        String name = builder.name;
        TypeVariableBuilder? existing =
            scopeBuilder[name] as TypeVariableBuilder?;
        if (existing == null) {
          scopeBuilder.addMember(name, builder);
        } else {
          reportDuplicatedDeclaration(existing, name, builder.charOffset);
        }
      }
    }
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    debugEvent("FunctionType");
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }
    FormalParameters formals = pop() as FormalParameters;
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    if (typeVariables != null) {
      for (TypeVariableBuilder builder in typeVariables) {
        if (builder.parameter.annotations.isNotEmpty) {
          if (!libraryBuilder.enableGenericMetadataInLibrary) {
            addProblem(fasta.messageAnnotationOnFunctionTypeTypeVariable,
                builder.charOffset, builder.name.length);
          }
          // Annotations on function types are not constant evaluated and are
          // not included in the generated AST so we clear them here.
          builder.parameter.annotations = const <Expression>[];
        }
      }
    }
    TypeBuilder type = formals.toFunctionType(
        returnType,
        libraryBuilder.nullableBuilderIfTrue(questionMark != null),
        typeVariables);
    exitLocalScope();
    push(type);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    int offset = offsetForToken(token);
    // "void" is always nullable.
    push(new NamedTypeBuilder.fromTypeDeclarationBuilder(
        new VoidTypeDeclarationBuilder(
            const VoidType(), libraryBuilder, offset),
        const NullabilityBuilder.inherent(),
        fileUri: uri,
        charOffset: offset,
        instanceTypeVariableAccess:
            InstanceTypeVariableAccessState.Unexpected));
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token token) {
    assert(checkState(token, <ValueKind>[
      /* arguments */ ValueKinds.TypeArgumentsOrNull,
    ]));

    debugEvent("handleVoidKeywordWithTypeArguments");
    pop(); // arguments.
    handleVoidKeyword(token);
  }

  @override
  void beginAsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.prepend(true);
  }

  @override
  void endAsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.tail!;
  }

  @override
  void handleAsOperator(Token operator) {
    debugEvent("AsOperator");
    DartType type = buildDartType(pop() as TypeBuilder,
        allowPotentiallyConstantType: libraryBuilder.isNonNullableByDefault);
    libraryBuilder.checkBoundsInType(
        type, typeEnvironment, uri, operator.charOffset);
    Expression expression = popForValue();
    Expression asExpression = forest.createAsExpression(
        offsetForToken(operator), expression, type,
        forNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
    push(asExpression);
  }

  @override
  void beginIsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.prepend(true);
  }

  @override
  void endIsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.tail!;
  }

  @override
  void handleIsOperator(Token isOperator, Token? not) {
    debugEvent("IsOperator");
    DartType type = buildDartType(pop() as TypeBuilder,
        allowPotentiallyConstantType: libraryBuilder.isNonNullableByDefault);
    Expression operand = popForValue();
    Expression isExpression = forest.createIsExpression(
        offsetForToken(isOperator), operand, type,
        forNonNullableByDefault: libraryBuilder.isNonNullableByDefault,
        notFileOffset: not != null ? offsetForToken(not) : null);
    libraryBuilder.checkBoundsInType(
        type, typeEnvironment, uri, isOperator.charOffset);
    push(isExpression);
  }

  @override
  void beginConditionalExpression(Token question) {
    Expression condition = popForValue();
    // This is matched by the call to [deferNode] in
    // [handleConditionalExpressionColon].
    typeInferrer.assignedVariables.beginNode();
    push(condition);
    super.beginConditionalExpression(question);
  }

  @override
  void handleConditionalExpressionColon() {
    Expression then = popForValue();
    // This is matched by the call to [beginNode] in
    // [beginConditionalExpression] and by the call to [storeInfo] in
    // [endConditionalExpression].
    push(typeInferrer.assignedVariables.deferNode());
    push(then);
    super.handleConditionalExpressionColon();
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = popForValue();
    Expression thenExpression = pop() as Expression;
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo<VariableDeclaration>;
    Expression condition = pop() as Expression;
    Expression node = forest.createConditionalExpression(
        offsetForToken(question), condition, thenExpression, elseExpression);
    push(node);
    // This is matched by the call to [deferNode] in
    // [handleConditionalExpressionColon].
    typeInferrer.assignedVariables.storeInfo(node, assignedVariablesInfo);
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    Expression expression = popForValue();
    if (constantContext != ConstantContext.none) {
      push(buildProblem(
          fasta.templateNotConstantExpression.withArguments('Throw'),
          throwToken.offset,
          throwToken.length));
    } else {
      push(forest.createThrow(offsetForToken(throwToken), expression));
    }
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token? requiredToken,
      Token? covariantToken, Token? varFinalOrConst) {
    // TODO(danrubel): handle required token
    if (!libraryBuilder.isNonNullableByDefault) {
      reportNonNullableModifierError(requiredToken);
    }
    push((covariantToken != null ? covariantMask : 0) |
        (requiredToken != null ? requiredMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme));
  }

  @override
  void endFormalParameter(
      Token? thisKeyword,
      Token? superKeyword,
      Token? periodAfterThisOrSuper,
      Token nameToken,
      Token? initializerStart,
      Token? initializerEnd,
      FormalParameterKind kind,
      MemberKind memberKind) {
    debugEvent("FormalParameter");
    if (thisKeyword != null) {
      if (!inConstructor) {
        handleRecoverableError(fasta.messageFieldInitializerOutsideConstructor,
            thisKeyword, thisKeyword);
        thisKeyword = null;
      }
    }
    Object? nameNode = pop();
    TypeBuilder? type = pop() as TypeBuilder?;
    if (functionNestingLevel == 0 && type != null) {
      // TODO(ahe): The type we compute here may be different from what is
      // computed in the outline phase. We should make sure that the outline
      // phase computes the same type. See
      // pkg/front_end/testcases/deferred_type_annotation.dart for an example
      // where not calling [buildDartType] leads to a missing compile-time
      // error. Also, notice that the type of the problematic parameter isn't
      // `invalid-type`.
      buildDartType(type, allowPotentiallyConstantType: false);
    }
    int modifiers = pop() as int;
    if (inCatchClause) {
      modifiers |= finalMask;
    }
    List<Expression>? annotations = pop() as List<Expression>?;
    if (nameNode is ParserRecovery) {
      push(nameNode);
      return;
    }
    Identifier? name = nameNode as Identifier?;
    FormalParameterBuilder? parameter;
    if (!inCatchClause &&
        functionNestingLevel == 0 &&
        memberKind != MemberKind.GeneralizedFunctionType) {
      SourceFunctionBuilder member = this.member as SourceFunctionBuilder;
      parameter = member.getFormal(name!);
      if (parameter == null) {
        // This happens when the list of formals (originally) contains a
        // ParserRecovery - then the popped list becomes null.
        push(new ParserRecovery(nameToken.charOffset));
        return;
      }
    } else {
      parameter = new FormalParameterBuilder(null, modifiers, type,
          name?.name ?? '', libraryBuilder, offsetForToken(nameToken),
          fileUri: uri)
        ..hasDeclaredInitializer = (initializerStart != null);
    }
    VariableDeclaration variable =
        parameter.build(libraryBuilder, functionNestingLevel);
    Expression? initializer = name?.initializer;
    if (initializer != null) {
      if (member is RedirectingFactoryBuilder) {
        RedirectingFactoryBuilder factory = member as RedirectingFactoryBuilder;
        addProblem(
            fasta.templateDefaultValueInRedirectingFactoryConstructor
                .withArguments(factory.redirectionTarget.fullNameForErrors),
            initializer.fileOffset,
            noLength);
      } else {
        if (!parameter.initializerWasInferred) {
          variable.initializer = initializer..parent = variable;
        }
      }
    } else if (kind != FormalParameterKind.mandatory) {
      variable.initializer ??= forest.createNullLiteral(noLocation)
        ..parent = variable;
    }
    if (annotations != null) {
      if (functionNestingLevel == 0) {
        inferAnnotations(variable, annotations);
      }
      variable.clearAnnotations();
      for (Expression annotation in annotations) {
        variable.addAnnotation(annotation);
      }
    }
    push(parameter);
    typeInferrer.assignedVariables.declare(variable);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterKind kind = optional("{", beginToken)
        ? FormalParameterKind.optionalNamed
        : FormalParameterKind.optionalPositional;
    // When recovering from an empty list of optional arguments, count may be
    // 0. It might be simpler if the parser didn't call this method in that
    // case, however, then [beginOptionalFormalParameters] wouldn't always be
    // matched by this method.
    List<FormalParameterBuilder>? parameters =
        const FixedNullableList<FormalParameterBuilder>()
            .popNonNullable(stack, count, dummyFormalParameterBuilder);
    if (parameters == null) {
      push(new ParserRecovery(offsetForToken(beginToken)));
    } else {
      for (FormalParameterBuilder parameter in parameters) {
        parameter.kind = kind;
      }
      push(parameters);
    }
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    functionNestingLevel++;
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    debugEvent("FunctionTypedFormalParameter");
    if (inCatchClause || functionNestingLevel != 0) {
      exitLocalScope();
    }
    FormalParameters formals = pop() as FormalParameters;
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(question);
    }
    TypeBuilder type = formals.toFunctionType(returnType,
        libraryBuilder.nullableBuilderIfTrue(question != null), typeVariables);
    exitLocalScope();
    push(type);
    functionNestingLevel--;
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    super.push(constantContext);
    constantContext = ConstantContext.required;
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression");
    Object? defaultValueExpression = pop();
    constantContext = pop() as ConstantContext;
    push(defaultValueExpression);
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter");
    Expression initializer = popForValue();
    Object? name = pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(new InitializedIdentifier(name as Identifier, initializer));
    }
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    super.push(constantContext);
    constantContext = ConstantContext.none;
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    List<FormalParameterBuilder>? optionals;
    int optionalsCount = 0;
    if (count > 0 && peek() is List<FormalParameterBuilder>) {
      optionals = pop() as List<FormalParameterBuilder>;
      count--;
      optionalsCount = optionals.length;
    }
    List<FormalParameterBuilder>? parameters =
        const FixedNullableList<FormalParameterBuilder>().popPaddedNonNullable(
            stack, count, optionalsCount, dummyFormalParameterBuilder);
    if (optionals != null && parameters != null) {
      parameters.setRange(count, count + optionalsCount, optionals);
    }
    assert(parameters?.isNotEmpty ?? true);
    FormalParameters formals = new FormalParameters(parameters,
        offsetForToken(beginToken), lengthOfSpan(beginToken, endToken), uri);
    constantContext = pop() as ConstantContext;
    push(formals);
    if ((inCatchClause || functionNestingLevel != 0) &&
        kind != MemberKind.GeneralizedFunctionType) {
      enterLocalScope('formalParameters',
          formals.computeFormalParameterScope(scope, member, this));
    }
  }

  @override
  void beginCatchClause(Token token) {
    debugEvent("beginCatchClause");
    inCatchClause = true;
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
    inCatchClause = false;
    push(inCatchBlock);
    inCatchBlock = true;
  }

  @override
  void handleCatchBlock(Token? onKeyword, Token? catchKeyword, Token? comma) {
    debugEvent("CatchBlock");
    Statement body = pop() as Statement;
    inCatchBlock = pop() as bool;
    if (catchKeyword != null) {
      exitLocalScope();
    }
    FormalParameters? catchParameters =
        popIfNotNull(catchKeyword) as FormalParameters?;
    TypeBuilder? unresolvedExceptionType =
        popIfNotNull(onKeyword) as TypeBuilder?;
    DartType exceptionType;
    if (unresolvedExceptionType != null) {
      exceptionType = buildDartType(unresolvedExceptionType,
          allowPotentiallyConstantType: false);
    } else {
      exceptionType = (libraryBuilder.isNonNullableByDefault
          ? coreTypes.objectNonNullableRawType
          : const DynamicType());
    }
    FormalParameterBuilder? exception;
    FormalParameterBuilder? stackTrace;
    List<Statement>? compileTimeErrors;
    if (catchParameters?.parameters != null) {
      int parameterCount = catchParameters!.parameters!.length;
      if (parameterCount > 0) {
        exception = catchParameters.parameters![0];
        exception.build(libraryBuilder, functionNestingLevel).type =
            exceptionType;
        if (parameterCount > 1) {
          stackTrace = catchParameters.parameters![1];
          stackTrace.build(libraryBuilder, functionNestingLevel).type =
              coreTypes.stackTraceRawType(libraryBuilder.nonNullable);
        }
      }
      if (parameterCount > 2) {
        // If parameterCount is 0, the parser reported an error already.
        if (parameterCount != 0) {
          for (int i = 2; i < parameterCount; i++) {
            FormalParameterBuilder parameter = catchParameters.parameters![i];
            compileTimeErrors ??= <Statement>[];
            compileTimeErrors.add(buildProblemStatement(
                fasta.messageCatchSyntaxExtraParameters, parameter.charOffset,
                length: parameter.name.length));
          }
        }
      }
    }
    push(forest.createCatch(
        offsetForToken(onKeyword ?? catchKeyword),
        exceptionType,
        exception?.variable,
        stackTrace?.variable,
        coreTypes.stackTraceRawType(libraryBuilder.nonNullable),
        body));
    if (compileTimeErrors == null) {
      push(NullValue.Block);
    } else {
      push(forest.createBlock(noLocation, noLocation, compileTimeErrors));
    }
  }

  @override
  void beginTryStatement(Token token) {
    // This is matched by the call to [endNode] in [endTryStatement].
    typeInferrer.assignedVariables.beginNode();
  }

  @override
  void endTryStatement(
      int catchCount, Token tryKeyword, Token? finallyKeyword) {
    Statement? finallyBlock;
    if (finallyKeyword != null) {
      finallyBlock = pop() as Statement;
    } else {
      // This is matched by the call to [beginNode] in [beginTryStatement].
      tryStatementInfoStack = tryStatementInfoStack
          .prepend(typeInferrer.assignedVariables.deferNode());
    }
    List<Catch>? catchBlocks;
    List<Statement>? compileTimeErrors;
    if (catchCount != 0) {
      List<Object?> catchBlocksAndErrors =
          const FixedNullableList<Object?>().pop(stack, catchCount * 2)!;
      catchBlocks =
          new List<Catch>.filled(catchCount, dummyCatch, growable: true);
      for (int i = 0; i < catchCount; i++) {
        catchBlocks[i] = catchBlocksAndErrors[i * 2] as Catch;
        Statement? error = catchBlocksAndErrors[i * 2 + 1] as Statement?;
        if (error != null) {
          compileTimeErrors ??= <Statement>[];
          compileTimeErrors.add(error);
        }
      }
    }
    Statement tryBlock = popStatement();
    int fileOffset = offsetForToken(tryKeyword);
    Statement result = forest.createTryStatement(
        fileOffset, tryBlock, catchBlocks, finallyBlock);
    typeInferrer.assignedVariables
        .storeInfo(result, tryStatementInfoStack.head);
    tryStatementInfoStack = tryStatementInfoStack.tail!;

    if (compileTimeErrors != null) {
      compileTimeErrors.add(result);
      push(forest.createBlock(noLocation, noLocation, compileTimeErrors));
    } else {
      push(result);
    }
  }

  @override
  void handleIndexedExpression(
      Token? question, Token openSquareBracket, Token closeSquareBracket) {
    assert(checkState(openSquareBracket, [
      unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      unionOfKinds(
          [ValueKinds.Expression, ValueKinds.Generator, ValueKinds.Initializer])
    ]));
    debugEvent("IndexedExpression");
    Expression index = popForValue();
    Object? receiver = pop();
    bool isNullAware = question != null;
    if (isNullAware && !libraryBuilder.isNonNullableByDefault) {
      reportMissingNonNullableSupport(openSquareBracket);
    }
    if (receiver is Generator) {
      push(receiver.buildIndexedAccess(index, openSquareBracket,
          isNullAware: isNullAware));
    } else if (receiver is Expression) {
      push(IndexedAccessGenerator.make(this, openSquareBracket, receiver, index,
          isNullAware: isNullAware));
    } else {
      assert(receiver is Initializer);
      push(IndexedAccessGenerator.make(
          this, openSquareBracket, toValue(receiver), index,
          isNullAware: isNullAware));
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    assert(checkState(token, <ValueKind>[
      unionOfKinds(<ValueKind>[
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder
      ]),
    ]));
    debugEvent("UnaryPrefixExpression");
    Object? receiver = pop();
    if (optional("!", token)) {
      push(forest.createNot(offsetForToken(token), toValue(receiver)));
    } else {
      String operator = token.stringValue!;
      if (optional("-", token)) {
        operator = "unary-";
      }
      int fileOffset = offsetForToken(token);
      Name name = new Name(operator);
      if (receiver is Generator) {
        push(receiver.buildUnaryOperation(token, name));
      } else {
        assert(receiver is Expression);
        push(forest.createUnary(fileOffset, name, receiver as Expression));
      }
    }
  }

  Name incrementOperator(Token token) {
    if (optional("++", token)) return plusName;
    if (optional("--", token)) return minusName;
    return unhandled(token.lexeme, "incrementOperator", token.charOffset, uri);
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    Object? generator = pop();
    if (generator is Generator) {
      push(generator.buildPrefixIncrement(incrementOperator(token),
          offset: token.charOffset));
    } else {
      Expression value = toValue(generator);
      push(wrapInProblem(
          value, fasta.messageNotAnLvalue, value.fileOffset, noLength));
    }
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    Object? generator = pop();
    if (generator is Generator) {
      push(new DelayedPostfixIncrement(
          this, token, generator, incrementOperator(token)));
    } else {
      Expression value = toValue(generator);
      push(wrapInProblem(
          value, fasta.messageNotAnLvalue, value.fileOffset, noLength));
    }
  }

  @override
  void endConstructorReference(Token start, Token? periodBeforeName,
      Token endToken, ConstructorReferenceContext constructorReferenceContext) {
    debugEvent("ConstructorReference");
    pushQualifiedReference(
        start, periodBeforeName, constructorReferenceContext);
  }

  /// A qualified reference is something that matches one of:
  ///
  ///     identifier
  ///     identifier typeArguments? '.' identifier
  ///     identifier '.' identifier typeArguments? '.' identifier
  ///
  /// That is, one to three identifiers separated by periods and optionally one
  /// list of type arguments.
  ///
  /// A qualified reference can be used to represent both a reference to
  /// compile-time constant variable (metadata) or a constructor reference
  /// (used by metadata, new/const expression, and redirecting factories).
  ///
  /// Note that the parser will report errors if metadata includes type
  /// arguments, but will other preserve them for error recovery.
  ///
  /// A constructor reference can contain up to three identifiers:
  ///
  ///     a) type typeArguments?
  ///     b) type typeArguments? '.' name
  ///     c) prefix '.' type typeArguments?
  ///     d) prefix '.' type typeArguments? '.' name
  ///
  /// This isn't a legal constructor reference:
  ///
  ///     type '.' name typeArguments?
  ///
  /// But the parser can't tell this from type c) above.
  ///
  /// This method pops 2 (or 3 if `periodBeforeName != null`) values from the
  /// stack and pushes 3 values: a generator (the type in a constructor
  /// reference, or an expression in metadata), a list of type arguments, and a
  /// name.
  void pushQualifiedReference(Token start, Token? periodBeforeName,
      ConstructorReferenceContext constructorReferenceContext) {
    assert(checkState(start, [
      /*suffix*/ if (periodBeforeName != null)
        unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
      /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
      /*type*/ unionOfKinds([
        ValueKinds.Generator,
        ValueKinds.QualifiedName,
        ValueKinds.ProblemBuilder,
        ValueKinds.ParserRecovery
      ]),
    ]));
    Object? suffixObject = popIfNotNull(periodBeforeName);
    Identifier? suffix;
    if (suffixObject is Identifier) {
      suffix = suffixObject;
    } else {
      assert(
          suffixObject == null || suffixObject is ParserRecovery,
          "Unexpected qualified name suffix $suffixObject "
          "(${suffixObject.runtimeType})");
      // There was a `.` without a suffix.
    }

    Identifier? identifier;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    Object? type = pop();
    if (type is QualifiedName) {
      identifier = type;
      QualifiedName qualified = type;
      Object qualifier = qualified.qualifier;
      assert(checkValue(
          start,
          unionOfKinds([ValueKinds.Generator, ValueKinds.ProblemBuilder]),
          qualifier));
      if (qualifier is TypeUseGenerator && suffix == null) {
        type = qualifier;
        if (typeArguments != null) {
          // TODO(ahe): Point to the type arguments instead.
          addProblem(fasta.messageConstructorWithTypeArguments,
              identifier.charOffset, identifier.name.length);
        }
      } else if (qualifier is Generator) {
        if (constructorReferenceContext !=
            ConstructorReferenceContext.Implicit) {
          type = qualifier.qualifiedLookup(qualified.token);
        } else {
          type = qualifier.buildSelectorAccess(
              new PropertySelector(this, qualified.token,
                  new Name(qualified.name, libraryBuilder.nameOrigin)),
              qualified.token.charOffset,
              false);
        }
        identifier = null;
      } else if (qualifier is ProblemBuilder) {
        type = qualifier;
      } else {
        unhandled("${qualifier.runtimeType}", "pushQualifiedReference",
            start.charOffset, uri);
      }
    }
    String name;
    if (identifier != null && suffix != null) {
      name = "${identifier.name}.${suffix.name}";
    } else if (identifier != null) {
      name = identifier.name;
    } else if (suffix != null) {
      name = suffix.name;
    } else {
      name = "";
    }

    // TODO(johnniwinther): Provide sufficient offsets for pointing correctly
    //  to prefix, class name and suffix.
    push(type);
    push(typeArguments ?? NullValue.TypeArguments);
    push(name);
    push(suffix ?? identifier ?? NullValue.Identifier);

    assert(checkState(start, [
      /*constructor name identifier*/ ValueKinds.IdentifierOrNull,
      /*constructor name*/ ValueKinds.Name,
      /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
      /*class*/ unionOfKinds([
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.ParserRecovery,
        ValueKinds.Expression,
      ]),
    ]));
  }

  @override
  Expression buildStaticInvocation(Member target, Arguments arguments,
      {Constness constness: Constness.implicit,
      TypeAliasBuilder? typeAliasBuilder,
      int charOffset: -1,
      int charLength: noLength}) {
    // The argument checks for the initial target of redirecting factories
    // invocations are skipped in Dart 1.
    List<TypeParameter> typeParameters = target.function!.typeParameters;
    if (target is Constructor) {
      assert(!target.enclosingClass.isAbstract);
      typeParameters = target.enclosingClass.typeParameters;
    }
    LocatedMessage? argMessage = checkArgumentsForFunction(
        target.function!, arguments, charOffset, typeParameters);
    if (argMessage != null) {
      return buildUnresolvedError(forest.createNullLiteral(charOffset),
          target.name.text, arguments, charOffset,
          candidate: target, message: argMessage, kind: UnresolvedKind.Method);
    }

    bool isConst = constness == Constness.explicitConst ||
        constantContext != ConstantContext.none;
    if (target is Constructor) {
      if (constantContext == ConstantContext.required &&
          constness == Constness.implicit) {
        addProblem(fasta.messageMissingExplicitConst, charOffset, charLength);
      }
      if (isConst && !target.isConst) {
        return buildProblem(
            fasta.messageNonConstConstructor, charOffset, charLength);
      }
      ConstructorInvocation node;
      if (typeAliasBuilder == null) {
        node = new ConstructorInvocation(target, arguments, isConst: isConst)
          ..fileOffset = charOffset;
        libraryBuilder.checkBoundsInConstructorInvocation(
            node, typeEnvironment, uri);
      } else {
        TypeAliasedConstructorInvocation constructorInvocation =
            node = new TypeAliasedConstructorInvocation(
                typeAliasBuilder, target, arguments,
                isConst: isConst)
              ..fileOffset = charOffset;
        // No type arguments were passed, so we need not check bounds.
        assert(arguments.types.isEmpty);
        typeAliasedConstructorInvocations.add(constructorInvocation);
      }
      return node;
    } else {
      Procedure procedure = target as Procedure;
      if (procedure.isFactory) {
        if (constantContext == ConstantContext.required &&
            constness == Constness.implicit) {
          addProblem(fasta.messageMissingExplicitConst, charOffset, charLength);
        }
        if (isConst && !procedure.isConst) {
          return buildProblem(
              fasta.messageNonConstFactory, charOffset, charLength);
        }
        StaticInvocation node;
        if (typeAliasBuilder == null) {
          FactoryConstructorInvocation factoryInvocation =
              new FactoryConstructorInvocation(target, arguments,
                  isConst: isConst)
                ..fileOffset = charOffset;
          libraryBuilder.checkBoundsInFactoryInvocation(
              factoryInvocation, typeEnvironment, uri,
              inferred: !hasExplicitTypeArguments(arguments));
          redirectingFactoryInvocations.add(factoryInvocation);
          node = factoryInvocation;
        } else {
          TypeAliasedFactoryInvocation constructorInvocation =
              new TypeAliasedFactoryInvocation(
                  typeAliasBuilder, target, arguments,
                  isConst: isConst)
                ..fileOffset = charOffset;
          // No type arguments were passed, so we need not check bounds.
          assert(arguments.types.isEmpty);
          typeAliasedFactoryInvocations.add(constructorInvocation);
          node = constructorInvocation;
        }
        return node;
      } else {
        assert(constness == Constness.implicit);
        return new StaticInvocation(target, arguments, isConst: false)
          ..fileOffset = charOffset;
      }
    }
  }

  @override
  Expression buildExtensionMethodInvocation(
      int fileOffset, Procedure target, Arguments arguments,
      {required bool isTearOff}) {
    List<TypeParameter> typeParameters = target.function.typeParameters;
    LocatedMessage? argMessage = checkArgumentsForFunction(
        target.function, arguments, fileOffset, typeParameters,
        isExtensionMemberInvocation: true);
    if (argMessage != null) {
      return buildUnresolvedError(forest.createNullLiteral(fileOffset),
          target.name.text, arguments, fileOffset,
          candidate: target, message: argMessage, kind: UnresolvedKind.Method);
    }

    Expression node;
    if (isTearOff) {
      node = new ExtensionTearOff(target, arguments);
    } else {
      node = new StaticInvocation(target, arguments);
    }
    node.fileOffset = fileOffset;
    return node;
  }

  @override
  LocatedMessage? checkArgumentsForFunction(FunctionNode function,
      Arguments arguments, int offset, List<TypeParameter> typeParameters,
      {bool isExtensionMemberInvocation = false}) {
    int requiredPositionalParameterCountToReport =
        function.requiredParameterCount;
    int positionalParameterCountToReport = function.positionalParameters.length;
    int positionalArgumentCountToReport =
        forest.argumentsPositional(arguments).length;
    if (isExtensionMemberInvocation) {
      // Extension member invocations have additional synthetic parameter for
      // `this`.
      --requiredPositionalParameterCountToReport;
      --positionalParameterCountToReport;
      --positionalArgumentCountToReport;
    }
    if (forest.argumentsPositional(arguments).length <
        function.requiredParameterCount) {
      return fasta.templateTooFewArguments
          .withArguments(requiredPositionalParameterCountToReport,
              positionalArgumentCountToReport)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    if (forest.argumentsPositional(arguments).length >
        function.positionalParameters.length) {
      return fasta.templateTooManyArguments
          .withArguments(
              positionalParameterCountToReport, positionalArgumentCountToReport)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    List<NamedExpression> named = forest.argumentsNamed(arguments);
    if (named.isNotEmpty) {
      Set<String?> parameterNames =
          new Set.of(function.namedParameters.map((a) => a.name));
      for (NamedExpression argument in named) {
        if (!parameterNames.contains(argument.name)) {
          return fasta.templateNoSuchNamedParameter
              .withArguments(argument.name)
              .withLocation(uri, argument.fileOffset, argument.name.length);
        }
      }
    }
    if (function.namedParameters.isNotEmpty) {
      if (libraryBuilder.isNonNullableByDefault) {
        Set<String> argumentNames = new Set.of(named.map((a) => a.name));
        for (VariableDeclaration parameter in function.namedParameters) {
          if (parameter.isRequired && !argumentNames.contains(parameter.name)) {
            return fasta.templateValueForRequiredParameterNotProvidedError
                .withArguments(parameter.name!)
                .withLocation(uri, arguments.fileOffset, fasta.noLength);
          }
        }
      }
    }

    List<DartType> types = forest.argumentsTypeArguments(arguments);
    if (typeParameters.length != types.length) {
      if (types.length == 0) {
        // Expected `typeParameters.length` type arguments, but none given, so
        // we use type inference.
      } else {
        // A wrong (non-zero) amount of type arguments given. That's an error.
        // TODO(jensj): Position should be on type arguments instead.
        return fasta.templateTypeArgumentMismatch
            .withArguments(typeParameters.length)
            .withLocation(uri, offset, noLength);
      }
    }

    return null;
  }

  @override
  LocatedMessage? checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset,
      {bool isExtensionMemberInvocation = false}) {
    int requiredPositionalParameterCountToReport =
        function.requiredParameterCount;
    int positionalParameterCountToReport = function.positionalParameters.length;
    int positionalArgumentCountToReport =
        forest.argumentsPositional(arguments).length;
    if (isExtensionMemberInvocation) {
      // Extension member invocations have additional synthetic parameter for
      // `this`.
      --requiredPositionalParameterCountToReport;
      --positionalParameterCountToReport;
      --positionalArgumentCountToReport;
    }
    if (forest.argumentsPositional(arguments).length <
        function.requiredParameterCount) {
      return fasta.templateTooFewArguments
          .withArguments(requiredPositionalParameterCountToReport,
              positionalArgumentCountToReport)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    if (forest.argumentsPositional(arguments).length >
        function.positionalParameters.length) {
      return fasta.templateTooManyArguments
          .withArguments(
              positionalParameterCountToReport, positionalArgumentCountToReport)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    List<NamedExpression> named = forest.argumentsNamed(arguments);
    if (named.isNotEmpty) {
      Set<String> names =
          new Set.of(function.namedParameters.map((a) => a.name));
      for (NamedExpression argument in named) {
        if (!names.contains(argument.name)) {
          return fasta.templateNoSuchNamedParameter
              .withArguments(argument.name)
              .withLocation(uri, argument.fileOffset, argument.name.length);
        }
      }
    }
    if (function.namedParameters.isNotEmpty) {
      if (libraryBuilder.isNonNullableByDefault) {
        Set<String> argumentNames = new Set.of(named.map((a) => a.name));
        for (NamedType parameter in function.namedParameters) {
          if (parameter.isRequired && !argumentNames.contains(parameter.name)) {
            return fasta.templateValueForRequiredParameterNotProvidedError
                .withArguments(parameter.name)
                .withLocation(uri, arguments.fileOffset, fasta.noLength);
          }
        }
      }
    }
    List<Object> types = forest.argumentsTypeArguments(arguments);
    List<TypeParameter> typeParameters = function.typeParameters;
    if (typeParameters.length != types.length && types.length != 0) {
      // A wrong (non-zero) amount of type arguments given. That's an error.
      // TODO(jensj): Position should be on type arguments instead.
      return fasta.templateTypeArgumentMismatch
          .withArguments(typeParameters.length)
          .withLocation(uri, offset, noLength);
    }

    return null;
  }

  @override
  void beginNewExpression(Token token) {
    debugEvent("beginNewExpression");
    super.push(constantContext);
    if (constantContext != ConstantContext.none) {
      addProblem(
          fasta.templateNotConstantExpression.withArguments('New expression'),
          token.charOffset,
          token.length);
    }
    constantContext = ConstantContext.none;
  }

  @override
  void beginConstExpression(Token token) {
    debugEvent("beginConstExpression");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void beginConstLiteral(Token token) {
    debugEvent("beginConstLiteral");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void beginImplicitCreationExpression(Token token) {
    debugEvent("beginImplicitCreationExpression");
    super.push(constantContext);
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("endConstLiteral");
    Object? literal = pop();
    constantContext = pop() as ConstantContext;
    push(literal);
  }

  @override
  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    _buildConstructorReferenceInvocation(
        token.next!, token.offset, Constness.explicitNew,
        inMetadata: false, inImplicitCreationContext: false);
  }

  void _buildConstructorReferenceInvocation(
      Token nameToken, int offset, Constness constness,
      {required bool inMetadata, required bool inImplicitCreationContext}) {
    assert(checkState(nameToken, [
      /*arguments*/ ValueKinds.Arguments,
      /*constructor name identifier*/ ValueKinds.IdentifierOrNull,
      /*constructor name*/ ValueKinds.Name,
      /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
      /*class*/ unionOfKinds([
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.ParserRecovery,
        ValueKinds.Expression,
      ]),
      /*previous constant context*/ ValueKinds.ConstantContext,
    ]));
    Arguments arguments = pop() as Arguments;
    Identifier? nameLastIdentifier = pop(NullValue.Identifier) as Identifier?;
    Token nameLastToken = nameLastIdentifier?.token ?? nameToken;
    String name = pop() as String;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    if (inMetadata && typeArguments != null) {
      if (!libraryBuilder.enableGenericMetadataInLibrary) {
        handleRecoverableError(fasta.messageMetadataTypeArguments,
            nameLastToken.next!, nameLastToken.next!);
      }
    }

    Object? type = pop();

    ConstantContext savedConstantContext = pop() as ConstantContext;
    if (type is Generator) {
      push(type.invokeConstructor(
          typeArguments, name, arguments, nameToken, nameLastToken, constness,
          inImplicitCreationContext: inImplicitCreationContext));
    } else if (type is ParserRecovery) {
      push(new ParserErrorGenerator(
          this, nameToken, fasta.messageSyntheticToken));
    } else if (type is InvalidExpression) {
      push(type);
    } else if (type is Expression) {
      push(createInstantiationAndInvocation(
          () => type, typeArguments, name, name, arguments,
          instantiationOffset: offset,
          invocationOffset: nameLastToken.charOffset,
          inImplicitCreationContext: inImplicitCreationContext));
    } else {
      String? typeName;
      if (type is ProblemBuilder) {
        typeName = type.fullNameForErrors;
      }
      push(buildUnresolvedError(forest.createNullLiteral(offset),
          debugName(typeName!, name), arguments, nameToken.charOffset,
          kind: UnresolvedKind.Constructor));
    }
    constantContext = savedConstantContext;
    assert(checkState(nameToken, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ])
    ]));
  }

  @override
  Expression createInstantiationAndInvocation(
      Expression Function() receiverFunction,
      List<TypeBuilder>? typeArguments,
      String className,
      String constructorName,
      Arguments arguments,
      {required int instantiationOffset,
      required int invocationOffset,
      required bool inImplicitCreationContext}) {
    if (enableConstructorTearOffsInLibrary && inImplicitCreationContext) {
      Expression receiver = receiverFunction();
      if (typeArguments != null) {
        if (receiver is StaticTearOff &&
                (receiver.target.isFactory ||
                    isTearOffLowering(receiver.target)) ||
            receiver is ConstructorTearOff ||
            receiver is RedirectingFactoryTearOff) {
          return buildProblem(fasta.messageConstructorTearOffWithTypeArguments,
              instantiationOffset, noLength);
        }
        receiver = forest.createInstantiation(
            instantiationOffset,
            receiver,
            buildDartTypeArguments(typeArguments,
                allowPotentiallyConstantType: true));
      }
      return forest.createMethodInvocation(invocationOffset, receiver,
          new Name(constructorName, libraryBuilder.nameOrigin), arguments);
    } else {
      if (typeArguments != null) {
        assert(forest.argumentsTypeArguments(arguments).isEmpty);
        forest.argumentsSetTypeArguments(
            arguments,
            buildDartTypeArguments(typeArguments,
                allowPotentiallyConstantType: false));
      }
      return buildUnresolvedError(
          forest.createNullLiteral(instantiationOffset),
          constructorNameForDiagnostics(constructorName, className: className),
          arguments,
          invocationOffset,
          kind: UnresolvedKind.Constructor);
    }
  }

  @override
  void endImplicitCreationExpression(Token token, Token openAngleBracket) {
    debugEvent("ImplicitCreationExpression");
    _buildConstructorReferenceInvocation(
        token, openAngleBracket.offset, Constness.implicit,
        inMetadata: false, inImplicitCreationContext: true);
  }

  @override
  Expression buildConstructorInvocation(
      TypeDeclarationBuilder? type,
      Token nameToken,
      Token nameLastToken,
      Arguments? arguments,
      String name,
      List<TypeBuilder>? typeArguments,
      int charOffset,
      Constness constness,
      {bool isTypeArgumentsInForest = false,
      TypeDeclarationBuilder? typeAliasBuilder,
      required UnresolvedKind unresolvedKind}) {
    if (arguments == null) {
      return buildProblem(fasta.messageMissingArgumentList,
          nameToken.charOffset, nameToken.length);
    }
    if (name.isNotEmpty && arguments.types.isNotEmpty) {
      // TODO(ahe): Point to the type arguments instead.
      addProblem(fasta.messageConstructorWithTypeArguments,
          nameToken.charOffset, nameToken.length);
    }

    String? errorName;
    LocatedMessage? message;

    if (type is TypeAliasBuilder) {
      errorName = debugName(type.name, name);
      TypeAliasBuilder aliasBuilder = type;
      int numberOfTypeParameters = aliasBuilder.typeVariablesCount;
      int numberOfTypeArguments = typeArguments?.length ?? 0;
      if (typeArguments != null &&
          numberOfTypeParameters != numberOfTypeArguments) {
        // TODO(eernst): Use position of type arguments, not nameToken.
        return evaluateArgumentsBefore(
            arguments,
            buildProblem(
                fasta.templateTypeArgumentMismatch
                    .withArguments(numberOfTypeParameters),
                charOffset,
                noLength));
      }
      type = aliasBuilder.unaliasDeclaration(null,
          isUsedAsClass: true,
          usedAsClassCharOffset: nameToken.charOffset,
          usedAsClassFileUri: uri);
      List<TypeBuilder> typeArgumentBuilders = [];
      if (typeArguments != null) {
        for (TypeBuilder typeBuilder in typeArguments) {
          typeArgumentBuilders.add(typeBuilder);
        }
      } else {
        if (aliasBuilder.typeVariablesCount > 0) {
          // Raw generic type alias used for instance creation, needs inference.
          ClassBuilder classBuilder;
          if (type is ClassBuilder) {
            classBuilder = type;
          } else {
            if (type is InvalidTypeDeclarationBuilder) {
              LocatedMessage message = type.message;
              return evaluateArgumentsBefore(
                  arguments,
                  buildProblem(message.messageObject, nameToken.charOffset,
                      nameToken.lexeme.length));
            }

            return buildUnresolvedError(forest.createNullLiteral(charOffset),
                errorName, arguments, nameLastToken.charOffset,
                message: message, kind: UnresolvedKind.Constructor);
          }
          MemberBuilder? b = classBuilder.findConstructorOrFactory(
              name, charOffset, uri, libraryBuilder);
          Member? target = b?.member;
          if (b == null) {
            // Not found. Reported below.
          } else if (b is AmbiguousMemberBuilder) {
            message = b.message.withLocation(uri, charOffset, noLength);
          } else if (b.isConstructor) {
            if (classBuilder.isAbstract) {
              return evaluateArgumentsBefore(
                  arguments,
                  buildAbstractClassInstantiationError(
                      fasta.templateAbstractClassInstantiation
                          .withArguments(type.name),
                      type.name,
                      nameToken.charOffset));
            }
          }
          if (target is Constructor ||
              (target is Procedure && target.kind == ProcedureKind.Factory)) {
            Expression invocation;
            invocation = buildStaticInvocation(target!, arguments,
                constness: constness,
                typeAliasBuilder: aliasBuilder,
                charOffset: nameToken.charOffset,
                charLength: nameToken.length);
            return invocation;
          } else {
            return buildUnresolvedError(forest.createNullLiteral(charOffset),
                errorName, arguments, nameLastToken.charOffset,
                message: message, kind: UnresolvedKind.Constructor);
          }
        } else {
          // Empty `typeArguments` and `aliasBuilder``is non-generic, but it
          // may still unalias to a class type with some type arguments.
          if (type is ClassBuilder) {
            List<TypeBuilder>? unaliasedTypeArgumentBuilders =
                aliasBuilder.unaliasTypeArguments(const []);
            if (unaliasedTypeArgumentBuilders == null) {
              // TODO(eernst): This is a wrong number of type arguments,
              // occurring indirectly (in an alias of an alias, etc.).
              return evaluateArgumentsBefore(
                  arguments,
                  buildProblem(
                      fasta.templateTypeArgumentMismatch
                          .withArguments(numberOfTypeParameters),
                      nameToken.charOffset,
                      nameToken.length,
                      suppressMessage: true));
            }
            List<DartType> dartTypeArguments = [];
            for (TypeBuilder typeBuilder in unaliasedTypeArgumentBuilders) {
              dartTypeArguments.add(typeBuilder.build(libraryBuilder));
            }
            assert(forest.argumentsTypeArguments(arguments).isEmpty);
            forest.argumentsSetTypeArguments(arguments, dartTypeArguments);
          }
        }
      }

      List<DartType> typeArgumentsToCheck = const <DartType>[];
      // ignore: unnecessary_null_comparison
      if (typeArgumentBuilders != null && typeArgumentBuilders.isNotEmpty) {
        typeArgumentsToCheck = new List.filled(
            typeArgumentBuilders.length, const DynamicType(),
            growable: false);
        for (int i = 0; i < typeArgumentsToCheck.length; ++i) {
          typeArgumentsToCheck[i] =
              typeArgumentBuilders[i].build(libraryBuilder);
        }
      }
      DartType typeToCheck = new TypedefType(
          aliasBuilder.typedef, Nullability.nonNullable, typeArgumentsToCheck);
      libraryBuilder.checkBoundsInType(
          typeToCheck, typeEnvironment, uri, charOffset,
          allowSuperBounded: false);

      if (type is ClassBuilder) {
        if (typeArguments != null) {
          int numberOfTypeParameters = aliasBuilder.typeVariables?.length ?? 0;
          if (numberOfTypeParameters != typeArgumentBuilders.length) {
            // TODO(eernst): Use position of type arguments, not nameToken.
            return evaluateArgumentsBefore(
                arguments,
                buildProblem(
                    fasta.templateTypeArgumentMismatch
                        .withArguments(numberOfTypeParameters),
                    nameToken.charOffset,
                    nameToken.length));
          }
          List<TypeBuilder>? unaliasedTypeArgumentBuilders =
              aliasBuilder.unaliasTypeArguments(typeArgumentBuilders);
          if (unaliasedTypeArgumentBuilders == null) {
            // TODO(eernst): This is a wrong number of type arguments,
            // occurring indirectly (in an alias of an alias, etc.).
            return evaluateArgumentsBefore(
                arguments,
                buildProblem(
                    fasta.templateTypeArgumentMismatch
                        .withArguments(numberOfTypeParameters),
                    nameToken.charOffset,
                    nameToken.length,
                    suppressMessage: true));
          }
          List<DartType> dartTypeArguments = [];
          for (TypeBuilder typeBuilder in unaliasedTypeArgumentBuilders) {
            dartTypeArguments.add(typeBuilder.build(libraryBuilder));
          }
          assert(forest.argumentsTypeArguments(arguments).isEmpty);
          forest.argumentsSetTypeArguments(arguments, dartTypeArguments);
        } else {
          ClassBuilder cls = type;
          if (cls.typeVariables?.isEmpty ?? true) {
            assert(forest.argumentsTypeArguments(arguments).isEmpty);
            forest.argumentsSetTypeArguments(arguments, []);
          } else {
            if (forest.argumentsTypeArguments(arguments).isEmpty) {
              // No type arguments provided to unaliased class, use defaults.
              List<DartType> result = new List<DartType>.generate(
                  cls.typeVariables!.length,
                  (int i) =>
                      cls.typeVariables![i].defaultType!.build(cls.library),
                  growable: true);
              forest.argumentsSetTypeArguments(arguments, result);
            }
          }
        }
      }
    } else {
      if (typeArguments != null && !isTypeArgumentsInForest) {
        assert(forest.argumentsTypeArguments(arguments).isEmpty);
        forest.argumentsSetTypeArguments(
            arguments,
            buildDartTypeArguments(typeArguments,
                allowPotentiallyConstantType: false));
      }
    }
    if (type is ClassBuilder) {
      MemberBuilder? b =
          type.findConstructorOrFactory(name, charOffset, uri, libraryBuilder);
      Member? target;
      if (b == null) {
        // Not found. Reported below.
      } else if (b is AmbiguousMemberBuilder) {
        message = b.message.withLocation(uri, charOffset, noLength);
      } else if (b.isConstructor) {
        if (type.isAbstract) {
          return evaluateArgumentsBefore(
              arguments,
              buildAbstractClassInstantiationError(
                  fasta.templateAbstractClassInstantiation
                      .withArguments(type.name),
                  type.name,
                  nameToken.charOffset));
        }
        target = b.member;
      } else {
        target = b.member;
      }
      if (type.isEnum &&
          !(libraryBuilder.enableEnhancedEnumsInLibrary &&
              target is Procedure &&
              target.kind == ProcedureKind.Factory)) {
        return buildProblem(fasta.messageEnumInstantiation,
            nameToken.charOffset, nameToken.length);
      }
      if (target is Constructor ||
          (target is Procedure && target.kind == ProcedureKind.Factory)) {
        Expression invocation;

        invocation = buildStaticInvocation(target!, arguments,
            constness: constness,
            charOffset: nameToken.charOffset,
            charLength: nameToken.length,
            typeAliasBuilder: typeAliasBuilder as TypeAliasBuilder?);
        return invocation;
      } else {
        errorName ??= debugName(type.name, name);
      }
    } else if (type is InvalidTypeDeclarationBuilder) {
      LocatedMessage message = type.message;
      return evaluateArgumentsBefore(
          arguments,
          buildProblem(message.messageObject, nameToken.charOffset,
              nameToken.lexeme.length));
    } else {
      errorName ??= debugName(type!.fullNameForErrors, name);
    }

    return buildUnresolvedError(forest.createNullLiteral(charOffset), errorName,
        arguments, nameLastToken.charOffset,
        message: message, kind: unresolvedKind);
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("endConstExpression");
    _buildConstructorReferenceInvocation(
        token.next!, token.offset, Constness.explicitConst,
        inMetadata: false, inImplicitCreationContext: false);
  }

  @override
  void handleConstFactory(Token constKeyword) {
    debugEvent("ConstFactory");
    if (!libraryBuilder.enableConstFunctionsInLibrary) {
      handleRecoverableError(
          fasta.messageConstFactory, constKeyword, constKeyword);
    }
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    // TODO(danrubel): consider removing this when control flow support is added
    // if the ifToken is not needed for error reporting
    push(ifToken);
  }

  @override
  void handleThenControlFlow(Token token) {
    Expression condition = popForValue();
    // This is matched by the call to [deferNode] in
    // [handleElseControlFlow] and by the call to [endNode] in
    // [endIfControlFlow].
    typeInferrer.assignedVariables.beginNode();
    push(condition);
    super.handleThenControlFlow(token);
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    // Resolve the top of the stack so that if it's a delayed assignment it
    // happens before we go into the else block.
    Object? node = pop();
    if (node is! MapLiteralEntry) node = toValue(node);
    // This is matched by the call to [beginNode] in
    // [handleThenControlFlow] and by the call to [storeInfo] in
    // [endIfElseControlFlow].
    push(typeInferrer.assignedVariables.deferNode());
    push(node);
  }

  @override
  void endIfControlFlow(Token token) {
    debugEvent("endIfControlFlow");
    Object? entry = pop();
    Object? condition = pop(); // parenthesized expression
    Token ifToken = pop() as Token;

    transformCollections = true;
    TreeNode node;
    if (entry is MapLiteralEntry) {
      node = forest.createIfMapEntry(
          offsetForToken(ifToken), toValue(condition), entry);
    } else {
      node = forest.createIfElement(
          offsetForToken(ifToken), toValue(condition), toValue(entry));
    }
    push(node);
    // This is matched by the call to [beginNode] in
    // [handleThenControlFlow].
    typeInferrer.assignedVariables.endNode(node);
  }

  @override
  void endIfElseControlFlow(Token token) {
    debugEvent("endIfElseControlFlow");
    Object? elseEntry = pop(); // else entry
    Object? thenEntry = pop(); // then entry
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo<VariableDeclaration>;
    Object? condition = pop(); // parenthesized expression
    Token ifToken = pop() as Token;

    transformCollections = true;
    TreeNode node;
    if (thenEntry is MapLiteralEntry) {
      if (elseEntry is MapLiteralEntry) {
        node = forest.createIfMapEntry(
            offsetForToken(ifToken), toValue(condition), thenEntry, elseEntry);
      } else if (elseEntry is ControlFlowElement) {
        MapLiteralEntry? elseMapEntry = elseEntry
            .toMapLiteralEntry(typeInferrer.assignedVariables.reassignInfo);
        if (elseMapEntry != null) {
          node = forest.createIfMapEntry(offsetForToken(ifToken),
              toValue(condition), thenEntry, elseMapEntry);
        } else {
          int offset = elseEntry.fileOffset;
          node = new MapLiteralEntry(
              buildProblem(
                  fasta.messageCantDisambiguateAmbiguousInformation, offset, 1),
              new NullLiteral())
            ..fileOffset = offsetForToken(ifToken);
        }
      } else {
        int offset = elseEntry is Expression
            ? elseEntry.fileOffset
            : offsetForToken(ifToken);
        node = new MapLiteralEntry(
            buildProblem(fasta.templateExpectedAfterButGot.withArguments(':'),
                offset, 1),
            new NullLiteral())
          ..fileOffset = offsetForToken(ifToken);
      }
    } else if (elseEntry is MapLiteralEntry) {
      if (thenEntry is ControlFlowElement) {
        MapLiteralEntry? thenMapEntry = thenEntry
            .toMapLiteralEntry(typeInferrer.assignedVariables.reassignInfo);
        if (thenMapEntry != null) {
          node = forest.createIfMapEntry(offsetForToken(ifToken),
              toValue(condition), thenMapEntry, elseEntry);
        } else {
          int offset = thenEntry.fileOffset;
          node = new MapLiteralEntry(
              buildProblem(
                  fasta.messageCantDisambiguateAmbiguousInformation, offset, 1),
              new NullLiteral())
            ..fileOffset = offsetForToken(ifToken);
        }
      } else {
        int offset = thenEntry is Expression
            ? thenEntry.fileOffset
            : offsetForToken(ifToken);
        node = new MapLiteralEntry(
            buildProblem(fasta.templateExpectedAfterButGot.withArguments(':'),
                offset, 1),
            new NullLiteral())
          ..fileOffset = offsetForToken(ifToken);
      }
    } else {
      node = forest.createIfElement(offsetForToken(ifToken), toValue(condition),
          toValue(thenEntry), toValue(elseEntry));
    }
    push(node);
    // This is matched by the call to [deferNode] in
    // [handleElseControlFlow].
    typeInferrer.assignedVariables.storeInfo(node, assignedVariablesInfo);
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    debugEvent("SpreadExpression");
    Object? expression = pop();
    transformCollections = true;
    push(forest.createSpreadElement(
        offsetForToken(spreadToken), toValue(expression),
        isNullAware: spreadToken.lexeme == '...?'));
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, count, dummyTypeBuilder) ??
        NullValue.TypeArguments);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValue.TypeArguments);
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    if (context.isScopeReference && isDeclarationInstanceContext) {
      if (extensionThis != null) {
        push(_createReadOnlyVariableAccess(extensionThis!, token,
            offsetForToken(token), 'this', ReadOnlyAccessKind.ExtensionThis));
      } else {
        push(new ThisAccessGenerator(this, token, inInitializerLeftHandSide,
            inFieldInitializer, inLateFieldInitializer));
      }
    } else {
      push(new IncompleteErrorGenerator(
          this, token, fasta.messageThisAsIdentifier));
    }
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    debugEvent("SuperExpression");
    if (context.isScopeReference &&
        isDeclarationInstanceContext &&
        extensionThis == null) {
      MemberBuilder memberBuilder = member as MemberBuilder;
      memberBuilder.member.transformerFlags |= TransformerFlag.superCalls;
      push(new ThisAccessGenerator(this, token, inInitializerLeftHandSide,
          inFieldInitializer, inLateFieldInitializer,
          isSuper: true));
    } else {
      push(new IncompleteErrorGenerator(
          this, token, fasta.messageSuperAsIdentifier));
    }
  }

  @override
  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument");
    assert(checkState(colon, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
      ]),
      unionOfKinds([
        ValueKinds.Identifier,
        ValueKinds.ParserRecovery,
      ])
    ]));
    Expression value = popForValue();
    Object? identifier = pop();
    if (identifier is Identifier) {
      push(new NamedExpression(identifier.name, value)
        ..fileOffset = identifier.charOffset);
    } else {
      assert(
          identifier is ParserRecovery,
          "Unexpected argument name: "
          "${identifier} (${identifier.runtimeType})");
      push(identifier);
    }
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
    Identifier name = pop() as Identifier;
    Token nameToken = name.token;
    VariableDeclaration variable = new VariableDeclarationImpl(
        name.name, functionNestingLevel,
        forSyntheticToken: nameToken.isSynthetic,
        isFinal: true,
        isLocalFunction: true)
      ..fileOffset = name.charOffset;
    // TODO(ahe): Why are we looking up in local scope, but declaring in parent
    // scope?
    Builder? existing = scope.lookupLocalMember(name.name, setter: false);
    if (existing != null) {
      reportDuplicatedDeclaration(existing, name.name, name.charOffset);
    }
    push(new FunctionDeclarationImpl(
        variable,
        // The real function node is created later.
        dummyFunctionNode)
      ..fileOffset = beginToken.charOffset);
    declareVariable(variable, scope.parent!);
  }

  void enterFunction() {
    _enterLocalState();
    debugEvent("enterFunction");
    functionNestingLevel++;
    push(switchScope ?? NullValue.SwitchScope);
    switchScope = null;
    push(inCatchBlock);
    inCatchBlock = false;
    // This is matched by the call to [endNode] in [pushNamedFunction] or
    // [endFunctionExpression].
    typeInferrer.assignedVariables.beginNode();
    assert(checkState(null, [
      /* inCatchBlock */ ValueKinds.Bool,
      /* switch scope */ ValueKinds.SwitchScopeOrNull,
    ]));
  }

  void exitFunction() {
    assert(checkState(null, [
      /* inCatchBlock */ ValueKinds.Bool,
      /* switch scope */ ValueKinds.SwitchScopeOrNull,
      /* function type variables */ ValueKinds.TypeVariableListOrNull,
      /* function block scope */ ValueKinds.Scope,
    ]));
    debugEvent("exitFunction");
    functionNestingLevel--;
    inCatchBlock = pop() as bool;
    switchScope = pop() as Scope?;
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    exitLocalScope();
    push(typeVariables ?? NullValue.TypeVariables);
    _exitLocalState();
    assert(checkState(null, [
      ValueKinds.TypeVariableListOrNull,
    ]));
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    debugEvent("beginLocalFunctionDeclaration");
    enterFunction();
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    debugEvent("beginNamedFunctionExpression");
    List<TypeVariableBuilder>? typeVariables =
        pop() as List<TypeVariableBuilder>?;
    // Create an additional scope in which the named function expression is
    // declared.
    enterLocalScope("named function");
    push(typeVariables ?? NullValue.TypeVariables);
    enterFunction();
  }

  @override
  void beginFunctionExpression(Token token) {
    debugEvent("beginFunctionExpression");
    enterFunction();
  }

  void pushNamedFunction(Token token, bool isFunctionExpression) {
    Statement body = popStatement();
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    exitLocalScope();
    FormalParameters formals = pop() as FormalParameters;
    Object? declaration = pop();
    TypeBuilder? returnType = pop() as TypeBuilder?;
    bool hasImplicitReturnType = returnType == null;
    exitFunction();
    List<TypeVariableBuilder>? typeParameters =
        pop() as List<TypeVariableBuilder>?;
    List<Expression>? annotations;
    if (!isFunctionExpression) {
      annotations = pop() as List<Expression>?; // Metadata.
    }
    FunctionNode function = formals.buildFunctionNode(libraryBuilder,
        returnType, typeParameters, asyncModifier, body, token.charOffset);

    if (declaration is FunctionDeclaration) {
      VariableDeclaration variable = declaration.variable;
      if (annotations != null) {
        for (Expression annotation in annotations) {
          variable.addAnnotation(annotation);
        }
      }
      FunctionDeclarationImpl.setHasImplicitReturnType(
          declaration as FunctionDeclarationImpl, hasImplicitReturnType);
      if (!hasImplicitReturnType) {
        checkAsyncReturnType(asyncModifier, function.returnType,
            variable.fileOffset, variable.name!.length);
      }

      variable.type = function.computeFunctionType(libraryBuilder.nonNullable);
      if (isFunctionExpression) {
        Expression? oldInitializer = variable.initializer;
        variable.initializer = new FunctionExpression(function)
          ..parent = variable
          ..fileOffset = formals.charOffset;
        exitLocalScope();
        // This is matched by the call to [beginNode] in [enterFunction].
        typeInferrer.assignedVariables.endNode(variable.initializer!,
            isClosureOrLateVariableInitializer: true);
        Expression expression = new NamedFunctionExpressionJudgment(variable);
        if (oldInitializer != null) {
          // This must have been a compile-time error.
          Expression error = oldInitializer;
          assert(isErroneousNode(error));
          int offset = expression.fileOffset;
          push(new Let(
              new VariableDeclaration.forValue(error)..fileOffset = offset,
              expression)
            ..fileOffset = offset);
        } else {
          push(expression);
        }
      } else {
        declaration.function = function;
        function.parent = declaration;
        if (variable.initializer != null) {
          // This must have been a compile-time error.
          assert(isErroneousNode(variable.initializer!));

          push(forest
              .createBlock(declaration.fileOffset, noLocation, <Statement>[
            forest.createExpressionStatement(
                offsetForToken(token), variable.initializer!),
            declaration
          ]));
          variable.initializer = null;
        } else {
          push(declaration);
        }
        // This is matched by the call to [beginNode] in [enterFunction].
        typeInferrer.assignedVariables
            .endNode(declaration, isClosureOrLateVariableInitializer: true);
      }
    } else {
      unhandled("${declaration.runtimeType}", "pushNamedFunction",
          token.charOffset, uri);
    }
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    debugEvent("NamedFunctionExpression");
    pushNamedFunction(endToken, true);
  }

  @override
  void endLocalFunctionDeclaration(Token token) {
    debugEvent("LocalFunctionDeclaration");
    pushNamedFunction(token, false);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    debugEvent("FunctionExpression");
    assert(checkState(beginToken, [
      /* body */ ValueKinds.StatementOrNull,
      /* async marker */ ValueKinds.AsyncMarker,
      /* function type scope */ ValueKinds.Scope,
      /* formal parameters */ ValueKinds.FormalParameters,
      /* inCatchBlock */ ValueKinds.Bool,
      /* switch scope */ ValueKinds.SwitchScopeOrNull,
      /* function type variables */ ValueKinds.TypeVariableListOrNull,
      /* function block scope */ ValueKinds.Scope,
    ]));
    Statement body = popNullableStatement() ??
        // In erroneous cases, there might not be function body. In such cases
        // we use an empty statement instead.
        forest.createEmptyStatement(token.charOffset);
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    exitLocalScope();
    FormalParameters formals = pop() as FormalParameters;
    exitFunction();
    List<TypeVariableBuilder>? typeParameters =
        pop() as List<TypeVariableBuilder>?;
    FunctionNode function = formals.buildFunctionNode(libraryBuilder, null,
        typeParameters, asyncModifier, body, token.charOffset)
      ..fileOffset = beginToken.charOffset;

    Expression result;
    if (constantContext != ConstantContext.none) {
      result = buildProblem(fasta.messageNotAConstantExpression,
          formals.charOffset, formals.length);
    } else {
      result = new FunctionExpression(function)
        ..fileOffset = offsetForToken(beginToken);
    }
    push(result);
    // This is matched by the call to [beginNode] in [enterFunction].
    typeInferrer.assignedVariables
        .endNode(result, isClosureOrLateVariableInitializer: true);
    assert(checkState(beginToken, [
      /* function expression or problem */ ValueKinds.Expression,
    ]));
  }

  @override
  void beginDoWhileStatement(Token token) {
    // This is matched by the [endNode] call in [endDoWhileStatement].
    typeInferrer.assignedVariables.beginNode();
    super.beginDoWhileStatement(token);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    debugEvent("DoWhileStatement");
    Expression condition = popForValue();
    Statement body = popStatement();
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements =
          continueTarget.resolveContinues(forest, labeledStatement);
      body = labeledStatement;
    }
    Statement doStatement =
        forest.createDoStatement(offsetForToken(doKeyword), body, condition);
    // This is matched by the [beginNode] call in [beginDoWhileStatement].
    typeInferrer.assignedVariables.endNode(doStatement);
    if (continueStatements != null) {
      for (BreakStatementImpl continueStatement in continueStatements) {
        continueStatement.targetStatement = doStatement;
      }
    }
    Statement result = doStatement;
    if (breakTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(result);
      breakTarget.resolveBreaks(forest, labeledStatement, doStatement);
      result = labeledStatement;
    }
    exitLoopOrSwitch(result);
  }

  @override
  void beginForInExpression(Token token) {
    enterLocalScope('forIn', scope.parent);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression");
    Expression expression = popForValue();
    exitLocalScope();
    push(expression);
  }

  @override
  void handleForInLoopParts(Token? awaitToken, Token forToken,
      Token leftParenthesis, Token inKeyword) {
    push(awaitToken ?? NullValue.AwaitToken);
    push(forToken);
    push(inKeyword);
    // This is matched by the call to [deferNode] in [endForIn] or
    // [endForInControlFlow].
    typeInferrer.assignedVariables.beginNode();
  }

  @override
  void endForInControlFlow(Token token) {
    debugEvent("ForInControlFlow");
    Object? entry = pop();
    Token inToken = pop() as Token;
    Token forToken = pop() as Token;
    Token? awaitToken = pop(NullValue.AwaitToken) as Token?;

    if (constantContext != ConstantContext.none) {
      popForValue(); // Pop iterable
      pop(); // Pop lvalue
      exitLocalScope();
      typeInferrer.assignedVariables.discardNode();

      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(forToken),
          forToken,
          forToken);
      push(invalidCollectionElement);
      return;
    }

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.popNode();

    Expression iterable = popForValue();
    Object? lvalue = pop(); // lvalue
    exitLocalScope();

    transformCollections = true;
    ForInElements elements =
        _computeForInElements(forToken, inToken, lvalue, null);
    typeInferrer.assignedVariables.pushNode(assignedVariablesNodeInfo);
    VariableDeclaration variable = elements.variable;
    Expression? problem = elements.expressionProblem;
    if (entry is MapLiteralEntry) {
      ForInMapEntry result = forest.createForInMapEntry(
          offsetForToken(forToken),
          variable,
          iterable,
          elements.syntheticAssignment,
          elements.expressionEffects,
          entry,
          problem,
          isAsync: awaitToken != null);
      typeInferrer.assignedVariables.endNode(result);
      push(result);
    } else {
      ForInElement result = forest.createForInElement(
          offsetForToken(forToken),
          variable,
          iterable,
          elements.syntheticAssignment,
          elements.expressionEffects,
          toValue(entry),
          problem,
          isAsync: awaitToken != null);
      typeInferrer.assignedVariables.endNode(result);
      push(result);
    }
  }

  ForInElements _computeForInElements(
      Token forToken, Token inToken, Object? lvalue, Statement? body) {
    ForInElements elements = new ForInElements();
    if (lvalue is VariableDeclaration) {
      // Late for-in variables are not supported. An error has already been
      // reported by the parser.
      lvalue.isLate = false;
      elements.explicitVariableDeclaration = lvalue;
      if (lvalue.isConst) {
        elements.expressionProblem = buildProblem(
            fasta.messageForInLoopWithConstVariable,
            lvalue.fileOffset,
            lvalue.name!.length);
      }
    } else {
      VariableDeclaration variable = elements.syntheticVariableDeclaration =
          forest.createVariableDeclaration(
              offsetForToken(forToken), null, functionNestingLevel,
              isFinal: true);
      if (lvalue is Generator) {
        /// We are in this case, where `lvalue` isn't a [VariableDeclaration]:
        ///
        ///     for (lvalue in expression) body
        ///
        /// This is normalized to:
        ///
        ///     for (final #t in expression) {
        ///       lvalue = #t;
        ///       body;
        ///     }
        elements.syntheticAssignment = lvalue.buildAssignment(
            new VariableGetImpl(variable, forNullGuardedAccess: false)
              ..fileOffset = inToken.offset,
            voidContext: true);
      } else {
        Message message = forest.isVariablesDeclaration(lvalue)
            ? fasta.messageForInLoopExactlyOneVariable
            : fasta.messageForInLoopNotAssignable;
        Token token = forToken.next!.next!;
        elements.expressionProblem =
            buildProblem(message, offsetForToken(token), lengthForToken(token));
        Statement effects;
        if (forest.isVariablesDeclaration(lvalue)) {
          effects = forest.createBlock(
              noLocation,
              noLocation,
              // New list because the declarations are not a growable list.
              new List<Statement>.of(
                  forest.variablesDeclarationExtractDeclarations(lvalue)));
        } else {
          effects = forest.createExpressionStatement(
              noLocation, lvalue as Expression);
        }
        elements.expressionEffects = combineStatements(
            forest.createExpressionStatement(
                noLocation,
                buildProblem(
                    message, offsetForToken(token), lengthForToken(token))),
            effects);
      }
    }
    return elements;
  }

  @override
  void endForIn(Token endToken) {
    debugEvent("ForIn");
    Statement body = popStatement();

    Token inKeyword = pop() as Token;
    Token forToken = pop() as Token;
    Token? awaitToken = pop(NullValue.AwaitToken) as Token?;

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo<VariableDeclaration> assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.deferNode();

    Expression expression = popForValue();
    Object? lvalue = pop();
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements =
          continueTarget.resolveContinues(forest, labeledStatement);
      body = labeledStatement;
    }
    ForInElements elements =
        _computeForInElements(forToken, inKeyword, lvalue, body);
    VariableDeclaration variable = elements.variable;
    Expression? problem = elements.expressionProblem;
    Statement forInStatement;
    if (elements.explicitVariableDeclaration != null) {
      forInStatement = new ForInStatement(variable, expression, body,
          isAsync: awaitToken != null)
        ..fileOffset = awaitToken?.charOffset ?? forToken.charOffset
        ..bodyOffset = body.fileOffset; // TODO(ahe): Isn't this redundant?
    } else {
      forInStatement = new ForInStatementWithSynthesizedVariable(
          variable,
          expression,
          elements.syntheticAssignment,
          elements.expressionEffects,
          body,
          isAsync: awaitToken != null,
          hasProblem: problem != null)
        ..fileOffset = awaitToken?.charOffset ?? forToken.charOffset
        ..bodyOffset = body.fileOffset; // TODO(ahe): Isn't this redundant?
    }
    typeInferrer.assignedVariables
        .storeInfo(forInStatement, assignedVariablesNodeInfo);
    if (continueStatements != null) {
      for (BreakStatementImpl continueStatement in continueStatements) {
        continueStatement.targetStatement = forInStatement;
      }
    }
    Statement result = forInStatement;
    if (breakTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(result);
      breakTarget.resolveBreaks(forest, labeledStatement, forInStatement);
      result = labeledStatement;
    }
    if (problem != null) {
      result = combineStatements(
          forest.createExpressionStatement(noLocation, problem), result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label");
    Identifier identifier = pop() as Identifier;
    push(new Label(identifier.name, identifier.charOffset));
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    debugEvent("beginLabeledStatement");
    List<Label>? labels = const FixedNullableList<Label>()
        .popNonNullable(stack, labelCount, dummyLabel);
    enterLocalScope('labeledStatement', scope.createNestedLabelScope());
    LabelTarget target = new LabelTarget(
        member as MemberBuilder, functionNestingLevel, token.charOffset);
    if (labels != null) {
      for (Label label in labels) {
        scope.declareLabel(label.name, target);
      }
    }
    push(target);
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");
    Statement statement = pop() as Statement;
    LabelTarget target = pop() as LabelTarget;
    exitLocalScope();
    if (target.breakTarget.hasUsers || target.continueTarget.hasUsers) {
      if (forest.isVariablesDeclaration(statement)) {
        internalProblem(
            fasta.messageInternalProblemLabelUsageInVariablesDeclaration,
            statement.fileOffset,
            uri);
      }
      if (statement is! LabeledStatement) {
        statement = forest.createLabeledStatement(statement);
      }
      target.breakTarget.resolveBreaks(forest, statement, statement);
      List<BreakStatementImpl>? continueStatements =
          target.continueTarget.resolveContinues(forest, statement);
      if (continueStatements != null) {
        for (BreakStatementImpl continueStatement in continueStatements) {
          continueStatement.targetStatement = statement;
        }
      }
    }
    push(statement);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement");
    if (inCatchBlock) {
      push(forest.createRethrowStatement(
          offsetForToken(rethrowToken), offsetForToken(endToken)));
    } else {
      push(new ExpressionStatement(buildProblem(fasta.messageRethrowNotCatch,
          offsetForToken(rethrowToken), lengthForToken(rethrowToken)))
        ..fileOffset = offsetForToken(rethrowToken));
    }
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock");
    // Do nothing, handled by [endTryStatement].
  }

  @override
  void beginWhileStatement(Token token) {
    // This is matched by the [endNode] call in [endWhileStatement].
    typeInferrer.assignedVariables.beginNode();
    super.beginWhileStatement(token);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    debugEvent("WhileStatement");
    Statement body = popStatement();
    Expression condition = popForValue();
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements =
          continueTarget.resolveContinues(forest, labeledStatement);
      body = labeledStatement;
    }
    Statement whileStatement = forest.createWhileStatement(
        offsetForToken(whileKeyword), condition, body);
    if (continueStatements != null) {
      for (BreakStatementImpl continueStatement in continueStatements) {
        continueStatement.targetStatement = whileStatement;
      }
    }
    Statement result = whileStatement;
    if (breakTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(result);
      breakTarget.resolveBreaks(forest, labeledStatement, whileStatement);
      result = labeledStatement;
    }
    exitLoopOrSwitch(result);
    // This is matched by the [beginNode] call in [beginWhileStatement].
    typeInferrer.assignedVariables.endNode(whileStatement);
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement");
    push(forest.createEmptyStatement(offsetForToken(token)));
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    debugEvent("beginAssert");
    // If in an assert initializer, make sure [inInitializer] is false so we
    // use the formal parameter scope. If this is any other kind of assert,
    // inInitializer should be false anyway.
    inInitializerLeftHandSide = false;
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token? commaToken, Token semicolonToken) {
    debugEvent("Assert");
    Expression? message = popForValueIfNotNull(commaToken);
    Expression condition = popForValue();
    int fileOffset = offsetForToken(assertKeyword);

    /// Return a representation of an assert that appears as a statement.
    AssertStatement createAssertStatement() {
      // Compute start and end offsets for the condition expression.
      // This code is a temporary workaround because expressions don't carry
      // their start and end offsets currently.
      //
      // The token that follows leftParenthesis is considered to be the
      // first token of the condition.
      // TODO(ahe): this really should be condition.fileOffset.
      int startOffset = leftParenthesis.next!.offset;
      int endOffset;

      // Search forward from leftParenthesis to find the last token of
      // the condition - which is a token immediately followed by a commaToken,
      // right parenthesis or a trailing comma.
      Token? conditionBoundary = commaToken ?? leftParenthesis.endGroup;
      Token conditionLastToken = leftParenthesis;
      while (!conditionLastToken.isEof) {
        Token nextToken = conditionLastToken.next!;
        if (nextToken == conditionBoundary) {
          break;
        } else if (optional(',', nextToken) &&
            nextToken.next == conditionBoundary) {
          // The next token is trailing comma, which means current token is
          // the last token of the condition.
          break;
        }
        conditionLastToken = nextToken;
      }
      if (conditionLastToken.isEof) {
        endOffset = startOffset = -1;
      } else {
        endOffset = conditionLastToken.offset + conditionLastToken.length;
      }

      return forest.createAssertStatement(
          fileOffset, condition, message, startOffset, endOffset);
    }

    switch (kind) {
      case Assert.Statement:
        push(createAssertStatement());
        break;

      case Assert.Expression:
        // The parser has already reported an error indicating that assert
        // cannot be used in an expression.
        push(buildProblem(
            fasta.messageAssertAsExpression, fileOffset, assertKeyword.length));
        break;

      case Assert.Initializer:
        push(forest.createAssertInitializer(
            fileOffset, createAssertStatement()));
        break;
    }
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    debugEvent("YieldStatement");
    push(forest.createYieldStatement(offsetForToken(yieldToken), popForValue(),
        isYieldStar: starToken != null));
  }

  @override
  void beginSwitchBlock(Token token) {
    debugEvent("beginSwitchBlock");
    // This is matched by the [endNode] call in [endSwitchStatement].
    typeInferrer.assignedVariables.beginNode();
    enterLocalScope("switch block");
    enterSwitchScope();
    enterBreakTarget(token.charOffset);
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    debugEvent("beginSwitchCase");
    int count = labelCount + expressionCount;
    List<Object>? labelsAndExpressions = const FixedNullableList<Object>()
        .popNonNullable(stack, count, dummyLabel);
    List<Label>? labels =
        labelCount == 0 ? null : new List<Label>.filled(labelCount, dummyLabel);
    List<Expression> expressions = new List<Expression>.filled(
        expressionCount, dummyExpression,
        growable: true);
    int labelIndex = 0;
    int expressionIndex = 0;
    if (labelsAndExpressions != null) {
      for (Object labelOrExpression in labelsAndExpressions) {
        if (labelOrExpression is Label) {
          labels![labelIndex++] = labelOrExpression;
        } else {
          expressions[expressionIndex++] = labelOrExpression as Expression;
        }
      }
    }
    assert(scope == switchScope);
    if (labels != null) {
      for (Label label in labels) {
        String labelName = label.name;
        if (scope.hasLocalLabel(labelName)) {
          // TODO(ahe): Should validate this is a goto target.
          if (!scope.claimLabel(labelName)) {
            addProblem(
                fasta.templateDuplicateLabelInSwitchStatement
                    .withArguments(labelName),
                label.charOffset,
                labelName.length);
          }
        } else {
          scope.declareLabel(
              labelName, createGotoTarget(firstToken.charOffset));
        }
      }
    }
    push(expressions);
    push(labels ?? NullValue.Labels);
    enterLocalScope("switch case");
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token? defaultKeyword,
      Token? colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    debugEvent("SwitchCase");
    // We always create a block here so that we later know that there's always
    // one synthetic block when we finish compiling the switch statement and
    // check this switch case to see if it falls through to the next case.
    Statement block = popBlock(statementCount, firstToken, null);
    exitLocalScope();
    List<Label>? labels = pop() as List<Label>?;
    List<Expression> expressions = pop() as List<Expression>;
    List<int> expressionOffsets = <int>[];
    for (Expression expression in expressions) {
      expressionOffsets.add(expression.fileOffset);
    }
    assert(labels == null || labels.isNotEmpty);
    push(new SwitchCaseImpl(expressions, expressionOffsets, block,
        isDefault: defaultKeyword != null, hasLabel: labels != null)
      ..fileOffset = firstToken.charOffset);
    push(labels ?? NullValue.Labels);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");

    List<SwitchCase> cases = pop() as List<SwitchCase>;
    JumpTarget target = exitBreakTarget()!;
    exitSwitchScope();
    exitLocalScope();
    Expression expression = popForValue();
    Statement switchStatement = new SwitchStatement(expression, cases)
      ..fileOffset = switchKeyword.charOffset;
    Statement result = switchStatement;
    if (target.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(result);
      target.resolveBreaks(forest, labeledStatement, switchStatement);
      result = labeledStatement;
    }
    exitLoopOrSwitch(result);
    // This is matched by the [beginNode] call in [beginSwitchBlock].
    typeInferrer.assignedVariables.endNode(switchStatement);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    debugEvent("SwitchBlock");
    List<SwitchCase> cases =
        new List<SwitchCase>.filled(caseCount, dummySwitchCase, growable: true);
    for (int i = caseCount - 1; i >= 0; i--) {
      List<Label>? labels = pop() as List<Label>?;
      SwitchCase current = cases[i] = pop() as SwitchCase;
      if (labels != null) {
        for (Label label in labels) {
          JumpTarget? target =
              switchScope!.lookupLabel(label.name) as JumpTarget?;
          if (target != null) {
            target.resolveGotos(forest, current);
          }
        }
      }
    }
    for (int i = 0; i < caseCount - 1; i++) {
      SwitchCase current = cases[i];
      Block block = current.body as Block;
      // [block] is a synthetic block that is added to handle variable
      // declarations in the switch case.
      TreeNode? lastNode =
          block.statements.isEmpty ? null : block.statements.last;
      if (lastNode is Block) {
        // This is a non-synthetic block.
        Block block = lastNode;
        lastNode = block.statements.isEmpty ? null : block.statements.last;
      }
      if (lastNode is ExpressionStatement) {
        ExpressionStatement statement = lastNode;
        lastNode = statement.expression;
      }
      // The rule that every case block should end with one of the predefined
      // set of statements is specific to pre-NNBD code and is replaced with
      // another rule based on flow analysis for NNBD code.  For details, see
      // the following link:
      // https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md#errors-and-warnings
      if (!libraryBuilder.isNonNullableByDefault) {
        if (lastNode is! BreakStatement &&
            lastNode is! ContinueSwitchStatement &&
            lastNode is! Rethrow &&
            lastNode is! ReturnStatement &&
            !forest.isThrow(lastNode)) {
          block.addStatement(new ExpressionStatement(
              buildFallThroughError(current.fileOffset)));
        }
      }
    }

    push(cases);
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    debugEvent("CaseMatch");
    // Do nothing. Handled by [handleSwitchCase].
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    debugEvent("BreakStatement");
    JumpTarget? target = breakTarget;
    Identifier? identifier;
    String? name;
    if (hasTarget) {
      identifier = pop() as Identifier;
      name = identifier.name;
      target = scope.lookupLabel(name) as JumpTarget?;
    }
    if (target == null && name == null) {
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.messageBreakOutsideOfLoop, breakKeyword.charOffset));
    } else if (target == null || !target.isBreakTarget) {
      Token labelToken = breakKeyword.next!;
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.templateInvalidBreakTarget.withArguments(name!),
          labelToken.charOffset,
          length: labelToken.length));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(buildProblemTargetOutsideLocalFunction(name, breakKeyword));
    } else {
      Statement statement =
          forest.createBreakStatement(offsetForToken(breakKeyword), identifier);
      target.addBreak(statement);
      push(statement);
    }
  }

  Statement buildProblemTargetOutsideLocalFunction(
      String? name, Token keyword) {
    Statement problem;
    bool isBreak = optional("break", keyword);
    if (name != null) {
      Template<Message Function(String)> template = isBreak
          ? fasta.templateBreakTargetOutsideFunction
          : fasta.templateContinueTargetOutsideFunction;
      problem = buildProblemStatement(
          template.withArguments(name), offsetForToken(keyword),
          length: lengthOfSpan(keyword, keyword.next));
    } else {
      Message message = isBreak
          ? fasta.messageAnonymousBreakTargetOutsideFunction
          : fasta.messageAnonymousContinueTargetOutsideFunction;
      problem = buildProblemStatement(message, offsetForToken(keyword),
          length: lengthForToken(keyword));
    }
    problemInLoopOrSwitch ??= problem;
    return problem;
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    debugEvent("ContinueStatement");
    JumpTarget? target = continueTarget;
    Identifier? identifier;
    String? name;
    if (hasTarget) {
      identifier = pop() as Identifier;
      name = identifier.name;
      Builder? namedTarget = scope.lookupLabel(identifier.name);
      if (namedTarget != null && namedTarget is! JumpTarget) {
        Token labelToken = continueKeyword.next!;
        push(problemInLoopOrSwitch = buildProblemStatement(
            fasta.messageContinueLabelNotTarget, labelToken.charOffset,
            length: labelToken.length));
        return;
      }
      target = namedTarget as JumpTarget?;
      if (target == null) {
        if (switchScope == null) {
          push(buildProblemStatement(
              fasta.templateLabelNotFound.withArguments(name),
              continueKeyword.next!.charOffset));
          return;
        }
        switchScope!.forwardDeclareLabel(
            identifier.name, target = createGotoTarget(identifier.charOffset));
      }
      if (target.isGotoTarget &&
          target.functionNestingLevel == functionNestingLevel) {
        ContinueSwitchStatement statement =
            new ContinueSwitchStatement(dummySwitchCase)
              ..fileOffset = continueKeyword.charOffset;
        target.addGoto(statement);
        push(statement);
        return;
      }
    }
    if (target == null) {
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.messageContinueWithoutLabelInCase, continueKeyword.charOffset,
          length: continueKeyword.length));
    } else if (!target.isContinueTarget) {
      Token labelToken = continueKeyword.next!;
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.templateInvalidContinueTarget.withArguments(name!),
          labelToken.charOffset,
          length: labelToken.length));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(buildProblemTargetOutsideLocalFunction(name, continueKeyword));
    } else {
      Statement statement = forest.createContinueStatement(
          offsetForToken(continueKeyword), identifier);
      target.addContinue(statement);
      push(statement);
    }
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    assert(checkState(token, [
      unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
      ValueKinds.AnnotationListOrNull,
    ]));
    Object? name = pop();
    List<Expression>? annotations = pop() as List<Expression>?;
    String? typeVariableName;
    int typeVariableCharOffset;
    if (name is Identifier) {
      typeVariableName = name.name;
      typeVariableCharOffset = name.charOffset;
    } else if (name is ParserRecovery) {
      typeVariableName = TypeVariableBuilder.noNameSentinel;
      typeVariableCharOffset = name.charOffset;
    } else {
      unhandled("${name.runtimeType}", "beginTypeVariable.name",
          token.charOffset, uri);
    }
    TypeVariableBuilder variable = new TypeVariableBuilder(
        typeVariableName, libraryBuilder, typeVariableCharOffset, uri);
    if (annotations != null) {
      inferAnnotations(variable.parameter, annotations);
      for (Expression annotation in annotations) {
        variable.parameter.addAnnotation(annotation);
      }
    }
    push(variable);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("handleTypeVariablesDefined");
    assert(count > 0);
    List<TypeVariableBuilder>? typeVariables =
        const FixedNullableList<TypeVariableBuilder>()
            .popNonNullable(stack, count, dummyTypeVariableBuilder);
    enterFunctionTypeScope(typeVariables);
    push(typeVariables);
  }

  @override
  void endTypeVariable(
      Token token, int index, Token? extendsOrSuper, Token? variance) {
    debugEvent("TypeVariable");
    TypeBuilder? bound = pop() as TypeBuilder?;
    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilder> typeVariables =
        peek() as List<TypeVariableBuilder>;

    TypeVariableBuilder variable = typeVariables[index];
    variable.bound = bound;
    if (variance != null) {
      if (!libraryBuilder.enableVarianceInLibrary) {
        reportVarianceModifierNotEnabled(variance);
      }
      variable.variance = Variance.fromString(variance.lexeme);
    }
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    // Peek to leave type parameters on top of stack.
    List<TypeVariableBuilder> typeVariables =
        peek() as List<TypeVariableBuilder>;

    List<TypeBuilder> unboundTypes = [];
    List<TypeVariableBuilder> unboundTypeVariables = [];
    List<TypeBuilder> calculatedBounds = calculateBounds(
        typeVariables,
        libraryBuilder.loader.target.dynamicType,
        libraryBuilder.loader.target.nullType,
        libraryBuilder.loader.target.objectClassBuilder,
        unboundTypes: unboundTypes,
        unboundTypeVariables: unboundTypeVariables);
    assert(unboundTypes.isEmpty,
        "Found a type not bound to a declaration in BodyBuilder.");
    for (int i = 0; i < typeVariables.length; ++i) {
      typeVariables[i].defaultType = calculatedBounds[i];
      typeVariables[i].defaultType!.resolveIn(
          scope,
          typeVariables[i].charOffset,
          typeVariables[i].fileUri!,
          libraryBuilder);
      typeVariables[i].finish(
          libraryBuilder,
          libraryBuilder.loader.target.objectClassBuilder,
          libraryBuilder.loader.target.dynamicType);
    }
    for (int i = 0; i < unboundTypeVariables.length; ++i) {
      unboundTypeVariables[i].finish(
          libraryBuilder,
          libraryBuilder.loader.target.objectClassBuilder,
          libraryBuilder.loader.target.dynamicType);
    }
    libraryBuilder.processPendingNullabilities();
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    enterFunctionTypeScope(null);
    push(NullValue.TypeVariables);
  }

  List<TypeParameter>? typeVariableBuildersToKernel(
      List<TypeVariableBuilder>? typeVariableBuilders) {
    if (typeVariableBuilders == null) return null;
    return new List<TypeParameter>.generate(typeVariableBuilders.length,
        (int i) => typeVariableBuilders[i].parameter,
        growable: true);
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    Statement statement = pop() as Statement;
    push(new ExpressionStatement(
        buildProblem(message, statement.fileOffset, noLength)));
  }

  @override
  Expression buildProblem(Message message, int charOffset, int length,
      {List<LocatedMessage>? context,
      bool suppressMessage: false,
      Expression? expression}) {
    if (!suppressMessage) {
      addProblem(message, charOffset, length,
          wasHandled: true, context: context);
    }
    String text = libraryBuilder.loader.target.context
        .format(message.withLocation(uri, charOffset, length), Severity.error)
        .plain;
    return new InvalidExpression(text, expression)..fileOffset = charOffset;
  }

  @override
  Expression wrapInProblem(
      Expression expression, Message message, int fileOffset, int length,
      {List<LocatedMessage>? context}) {
    Severity severity = message.code.severity;
    if (severity == Severity.error) {
      return wrapInLocatedProblem(
          expression, message.withLocation(uri, fileOffset, length),
          context: context);
    } else {
      addProblem(message, fileOffset, length, context: context);
      return expression;
    }
  }

  @override
  Expression wrapInLocatedProblem(Expression expression, LocatedMessage message,
      {List<LocatedMessage>? context}) {
    // TODO(askesc): Produce explicit error expression wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    int offset = expression.fileOffset;
    if (offset == -1) {
      offset = message.charOffset;
    }
    return buildProblem(
        message.messageObject, message.charOffset, message.length,
        context: context, expression: expression);
  }

  Expression buildFallThroughError(int charOffset) {
    addProblem(fasta.messageSwitchCaseFallThrough, charOffset, noLength);

    // TODO(ahe): The following doesn't make sense for the Analyzer. It should
    // be moved to [Forest] or conditional on `forest is Fangorn`.

    // TODO(ahe): Compute a LocatedMessage above instead?
    Location? location = messages.getLocationFromUri(uri, charOffset);

    return forest.createThrow(
        charOffset,
        buildStaticInvocation(
            libraryBuilder
                .loader.coreTypes.fallThroughErrorUrlAndLineConstructor,
            forest.createArguments(noLocation, <Expression>[
              forest.createStringLiteral(
                  charOffset, "${location?.file ?? uri}"),
              forest.createIntLiteral(charOffset, location?.line ?? 0),
            ]),
            constness: Constness.explicitNew,
            charOffset: charOffset));
  }

  Expression buildAbstractClassInstantiationError(
      Message message, String className,
      [int charOffset = -1]) {
    addProblemErrorIfConst(message, charOffset, className.length);
    // TODO(ahe): The following doesn't make sense to Analyzer AST.
    MemberBuilder constructor =
        libraryBuilder.loader.getAbstractClassInstantiationError();
    Expression invocation = buildStaticInvocation(
        constructor.member,
        forest.createArguments(charOffset,
            <Expression>[forest.createStringLiteral(charOffset, className)]),
        constness: Constness.explicitNew,
        charOffset: charOffset);
    return forest.createThrow(charOffset, invocation);
  }

  Statement buildProblemStatement(Message message, int charOffset,
      {List<LocatedMessage>? context,
      int? length,
      bool suppressMessage: false}) {
    length ??= noLength;
    return new ExpressionStatement(buildProblem(message, charOffset, length,
        context: context, suppressMessage: suppressMessage));
  }

  Statement wrapInProblemStatement(Statement statement, Message message) {
    // TODO(askesc): Produce explicit error statement wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    return buildProblemStatement(message, statement.fileOffset);
  }

  @override
  Initializer buildInvalidInitializer(Expression expression,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new ShadowInvalidInitializer(
        new VariableDeclaration.forValue(expression))
      ..fileOffset = charOffset;
  }

  Initializer buildDuplicatedInitializer(Field field, Expression value,
      String name, int offset, int previousInitializerOffset) {
    return new ShadowInvalidFieldInitializer(
        field,
        value,
        new VariableDeclaration.forValue(buildProblem(
            fasta.templateConstructorInitializeSameInstanceVariableSeveralTimes
                .withArguments(name),
            offset,
            noLength)))
      ..fileOffset = offset;
  }

  /// Parameter [formalType] should only be passed in the special case of
  /// building a field initializer as a desugaring of an initializing formal
  /// parameter.  The spec says the following:
  ///
  /// "If an explicit type is attached to the initializing formal, that is its
  /// static type.  Otherwise, the type of an initializing formal named _id_ is
  /// _Tid_, where _Tid_ is the type of the instance variable named _id_ in the
  /// immediately enclosing class.  It is a static warning if the static type of
  /// _id_ is not a subtype of _Tid_."
  @override
  List<Initializer> buildFieldInitializer(String name, int fieldNameOffset,
      int assignmentOffset, Expression expression,
      {FormalParameterBuilder? formal}) {
    Builder? builder = declarationBuilder!.lookupLocalMember(name);
    if (builder?.next != null) {
      // Duplicated name, already reported.
      return <Initializer>[
        buildInvalidInitializer(
            buildProblem(
                fasta.templateDuplicatedDeclarationUse.withArguments(name),
                fieldNameOffset,
                name.length),
            fieldNameOffset)
      ];
    } else if (builder is SourceFieldBuilder &&
        builder.isDeclarationInstanceMember) {
      initializedFields ??= <String, int>{};
      if (initializedFields!.containsKey(name)) {
        return <Initializer>[
          buildDuplicatedInitializer(builder.field, expression, name,
              assignmentOffset, initializedFields![name]!)
        ];
      }
      initializedFields![name] = assignmentOffset;
      if (builder.isAbstract) {
        return <Initializer>[
          buildInvalidInitializer(
              buildProblem(fasta.messageAbstractFieldConstructorInitializer,
                  fieldNameOffset, name.length),
              fieldNameOffset)
        ];
      } else if (builder.isExternal) {
        return <Initializer>[
          buildInvalidInitializer(
              buildProblem(fasta.messageExternalFieldConstructorInitializer,
                  fieldNameOffset, name.length),
              fieldNameOffset)
        ];
      } else if (builder.isFinal && builder.hasInitializer) {
        addProblem(
            fasta.templateFieldAlreadyInitializedAtDeclaration
                .withArguments(name),
            assignmentOffset,
            noLength,
            context: [
              fasta.templateFieldAlreadyInitializedAtDeclarationCause
                  .withArguments(name)
                  .withLocation(uri, builder.charOffset, name.length)
            ]);
        MemberBuilder constructor =
            libraryBuilder.loader.getDuplicatedFieldInitializerError();
        Expression invocation = buildStaticInvocation(
            constructor.member,
            forest.createArguments(assignmentOffset, <Expression>[
              forest.createStringLiteral(assignmentOffset, name)
            ]),
            constness: Constness.explicitNew,
            charOffset: assignmentOffset);
        return <Initializer>[
          new ShadowInvalidFieldInitializer(
              builder.field,
              expression,
              new VariableDeclaration.forValue(
                  forest.createThrow(assignmentOffset, invocation)))
            ..fileOffset = assignmentOffset
        ];
      } else {
        if (formal != null && formal.type != null) {
          DartType formalType = formal.variable!.type;
          if (!typeEnvironment.isSubtypeOf(formalType, builder.fieldType,
              SubtypeCheckMode.withNullabilities)) {
            libraryBuilder.addProblem(
                fasta.templateInitializingFormalTypeMismatch.withArguments(
                    name,
                    formalType,
                    builder.fieldType,
                    libraryBuilder.isNonNullableByDefault),
                assignmentOffset,
                noLength,
                uri,
                context: [
                  fasta.messageInitializingFormalTypeMismatchField.withLocation(
                      builder.fileUri, builder.charOffset, noLength)
                ]);
          }
        }
        DeclaredSourceConstructorBuilder constructorBuilder =
            member as DeclaredSourceConstructorBuilder;
        constructorBuilder.registerInitializedField(builder);
        return builder.buildInitializer(assignmentOffset, expression,
            isSynthetic: formal != null);
      }
    } else {
      return <Initializer>[
        buildInvalidInitializer(
            buildProblem(
                fasta.templateInitializerForStaticField.withArguments(name),
                fieldNameOffset,
                name.length),
            fieldNameOffset)
      ];
    }
  }

  @override
  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    if (member.isConst && !constructor.isConst) {
      addProblem(fasta.messageConstConstructorWithNonConstSuper, charOffset,
          constructor.name.text.length);
    }
    needsImplicitSuperInitializer = false;
    return new SuperInitializer(constructor, arguments)
      ..fileOffset = charOffset
      ..isSynthetic = isSynthetic;
  }

  @override
  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    if (sourceClassBuilder!
        .checkConstructorCyclic(member.name!, constructor.name.text)) {
      int length = constructor.name.text.length;
      if (length == 0) length = "this".length;
      addProblem(fasta.messageConstructorCyclic, charOffset, length);
      // TODO(askesc): Produce invalid initializer.
    }
    needsImplicitSuperInitializer = false;
    return new RedirectingInitializer(constructor, arguments)
      ..fileOffset = charOffset;
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator");
    push(new Operator(token, token.charOffset));
  }

  @override
  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(new Identifier(token));
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    if (member.isNative) {
      push(NullValue.FunctionBody);
    } else {
      push(forest.createBlock(offsetForToken(token), noLocation, <Statement>[
        buildProblemStatement(
            fasta.templateExpectedFunctionBody.withArguments(token),
            token.charOffset,
            length: token.length)
      ]));
    }
  }

  @override
  void handleTypeArgumentApplication(Token openAngleBracket) {
    assert(checkState(openAngleBracket, [
      ValueKinds.TypeArguments,
      unionOfKinds([ValueKinds.Generator, ValueKinds.Expression])
    ]));
    List<TypeBuilder>? typeArguments =
        pop() as List<TypeBuilder>?; // typeArguments
    if (libraryBuilder.enableConstructorTearOffsInLibrary) {
      Object? operand = pop();
      if (operand is Generator) {
        push(operand.applyTypeArguments(
            openAngleBracket.charOffset, typeArguments));
      } else if (operand is StaticTearOff &&
              (operand.target.isFactory || isTearOffLowering(operand.target)) ||
          operand is ConstructorTearOff ||
          operand is RedirectingFactoryTearOff) {
        push(buildProblem(fasta.messageConstructorTearOffWithTypeArguments,
            openAngleBracket.charOffset, noLength));
      } else {
        push(new Instantiation(
            toValue(operand),
            buildDartTypeArguments(typeArguments,
                allowPotentiallyConstantType: true))
          ..fileOffset = openAngleBracket.charOffset);
      }
    } else {
      addProblem(
          templateExperimentNotEnabled.withArguments(
              'constructor-tearoffs',
              libraryBuilder.enableConstructorTearOffsVersionInLibrary
                  .toText()),
          openAngleBracket.charOffset,
          noLength);
    }
  }

  @override
  TypeBuilder validateTypeVariableUse(TypeBuilder typeBuilder,
      {required bool allowPotentiallyConstantType}) {
    // ignore: unnecessary_null_comparison
    assert(allowPotentiallyConstantType != null);
    _validateTypeVariableUseInternal(typeBuilder,
        allowPotentiallyConstantType: allowPotentiallyConstantType);
    return typeBuilder;
  }

  void _validateTypeVariableUseInternal(TypeBuilder? builder,
      {required bool allowPotentiallyConstantType}) {
    // ignore: unnecessary_null_comparison
    assert(allowPotentiallyConstantType != null);
    if (builder is NamedTypeBuilder) {
      if (builder.declaration!.isTypeVariable) {
        TypeVariableBuilder typeParameterBuilder =
            builder.declaration as TypeVariableBuilder;
        TypeParameter typeParameter = typeParameterBuilder.parameter;
        if (typeParameter.parent is Class ||
            typeParameter.parent is Extension) {
          switch (builder.instanceTypeVariableAccess) {
            case InstanceTypeVariableAccessState.Allowed:
              if (constantContext != ConstantContext.none &&
                  (!inConstructorInitializer ||
                      !allowPotentiallyConstantType)) {
                LocatedMessage message =
                    fasta.messageTypeVariableInConstantContext.withLocation(
                        builder.fileUri!,
                        builder.charOffset!,
                        typeParameter.name!.length);
                builder.bind(new InvalidTypeDeclarationBuilder(
                    typeParameter.name!, message));
                addProblem(
                    message.messageObject, message.charOffset, message.length);
              }
              break;
            case InstanceTypeVariableAccessState.Disallowed:
              // TODO(johnniwinther): Can we unify this check with the similar
              // check in NamedTypeBuilder.buildTypeInternal. If we skip it
              // here, the error below (type variable in constant context) will
              // be emitted _instead_ of this (type variable in static context),
              // which seems like an odd prioritization.
              // TODO: Handle this case.
              LocatedMessage message = fasta.messageTypeVariableInStaticContext
                  .withLocation(builder.fileUri!, builder.charOffset!,
                      typeParameter.name!.length);
              builder.bind(new InvalidTypeDeclarationBuilder(
                  typeParameter.name!, message));
              addProblem(
                  message.messageObject, message.charOffset, message.length);
              break;
            case InstanceTypeVariableAccessState.Invalid:
              break;
            case InstanceTypeVariableAccessState.Unexpected:
              assert(false,
                  "Unexpected instance type variable $typeParameterBuilder");
              break;
          }
        }
      }
      if (builder.arguments != null) {
        for (TypeBuilder typeBuilder in builder.arguments!) {
          _validateTypeVariableUseInternal(typeBuilder,
              allowPotentiallyConstantType: allowPotentiallyConstantType);
        }
      }
    } else if (builder is FunctionTypeBuilder) {
      _validateTypeVariableUseInternal(builder.returnType,
          allowPotentiallyConstantType: allowPotentiallyConstantType);
      if (builder.formals != null) {
        for (FormalParameterBuilder formalParameterBuilder
            in builder.formals!) {
          _validateTypeVariableUseInternal(formalParameterBuilder.type,
              allowPotentiallyConstantType: allowPotentiallyConstantType);
        }
      }
    }
  }

  @override
  Expression evaluateArgumentsBefore(
      Arguments? arguments, Expression expression) {
    if (arguments == null) return expression;
    List<Expression> expressions =
        new List<Expression>.of(forest.argumentsPositional(arguments));
    for (NamedExpression named in forest.argumentsNamed(arguments)) {
      expressions.add(named.value);
    }
    for (Expression argument in expressions.reversed) {
      expression = new Let(
          new VariableDeclaration.forValue(argument,
              isFinal: true,
              type: coreTypes.objectRawType(libraryBuilder.nullable)),
          expression);
    }
    return expression;
  }

  @override
  bool isIdentical(Member? member) => member == coreTypes.identicalProcedure;

  @override
  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression: false, bool isNullAware: false}) {
    if (constantContext != ConstantContext.none &&
        !isConstantExpression &&
        !enableConstFunctionsInLibrary) {
      return buildProblem(
          fasta.templateNotConstantExpression
              .withArguments('Method invocation'),
          offset,
          name.text.length);
    }
    if (isNullAware) {
      VariableDeclarationImpl variable =
          createVariableDeclarationForValue(receiver);
      return new NullAwareMethodInvocation(
          variable,
          forest.createMethodInvocation(
              offset,
              createVariableGet(variable, receiver.fileOffset),
              name,
              arguments))
        ..fileOffset = receiver.fileOffset;
    } else {
      return forest.createMethodInvocation(offset, receiver, name, arguments);
    }
  }

  @override
  Expression buildSuperInvocation(Name name, Arguments arguments, int offset,
      {bool isConstantExpression: false,
      bool isNullAware: false,
      bool isImplicitCall: false}) {
    if (constantContext != ConstantContext.none &&
        !isConstantExpression &&
        !enableConstFunctionsInLibrary) {
      return buildProblem(
          fasta.templateNotConstantExpression
              .withArguments('Method invocation'),
          offset,
          name.text.length);
    }
    Member? target = lookupSuperMember(name);

    if (target == null || (target is Procedure && !target.isAccessor)) {
      if (target == null) {
        warnUnresolvedMethod(name, offset, isSuper: true);
      } else if (!areArgumentsCompatible(target.function!, arguments)) {
        target = null;
        addProblemErrorIfConst(
            fasta.templateSuperclassMethodArgumentMismatch
                .withArguments(name.text),
            offset,
            name.text.length);
      }
      return new SuperMethodInvocation(name, arguments, target as Procedure?)
        ..fileOffset = offset;
    }
    if (isImplicitCall) {
      return buildProblem(
          fasta.messageImplicitSuperCallOfNonMethod, offset, noLength);
    } else {
      Expression receiver = new SuperPropertyGet(name, target)
        ..fileOffset = offset;
      return forest.createExpressionInvocation(
          arguments.fileOffset, receiver, arguments);
    }
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false,
      List<LocatedMessage>? context,
      Severity? severity}) {
    libraryBuilder.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context, severity: severity);
  }

  @override
  void addProblemErrorIfConst(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage>? context}) {
    // TODO(askesc): Instead of deciding on the severity, this method should
    // take two messages: one to use when a constant expression is
    // required and one to use otherwise.
    Severity severity = message.code.severity;
    if (constantContext != ConstantContext.none) {
      severity = Severity.error;
    }
    addProblem(message, charOffset, length,
        wasHandled: wasHandled, context: context, severity: severity);
  }

  @override
  Expression buildProblemErrorIfConst(
      Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage>? context}) {
    addProblemErrorIfConst(message, charOffset, length,
        wasHandled: wasHandled, context: context);
    String text = libraryBuilder.loader.target.context
        .format(message.withLocation(uri, charOffset, length), Severity.error)
        .plain;
    InvalidExpression expression = new InvalidExpression(text)
      ..fileOffset = charOffset;
    return expression;
  }

  @override
  void reportDuplicatedDeclaration(
      Builder existing, String name, int charOffset) {
    List<LocatedMessage>? context = existing.isSynthetic
        ? null
        : <LocatedMessage>[
            fasta.templateDuplicatedDeclarationCause
                .withArguments(name)
                .withLocation(
                    existing.fileUri!, existing.charOffset, name.length)
          ];
    addProblem(fasta.templateDuplicatedDeclaration.withArguments(name),
        charOffset, name.length,
        context: context);
  }

  @override
  void debugEvent(String name) {
    // printEvent('BodyBuilder: $name');
  }

  @override
  Expression wrapInDeferredCheck(
      Expression expression, PrefixBuilder prefix, int charOffset) {
    VariableDeclaration check = new VariableDeclaration.forValue(
        forest.checkLibraryIsLoaded(charOffset, prefix.dependency!));
    return new DeferredCheck(check, expression)..fileOffset = charOffset;
  }

  bool isErroneousNode(TreeNode node) {
    return libraryBuilder.loader.handledErrors.isNotEmpty &&
        forest.isErroneousNode(node);
  }

  @override
  DartType buildDartType(TypeBuilder typeBuilder,
      {required bool allowPotentiallyConstantType}) {
    return validateTypeVariableUse(typeBuilder,
            allowPotentiallyConstantType: allowPotentiallyConstantType)
        .build(libraryBuilder);
  }

  @override
  DartType buildTypeLiteralDartType(TypeBuilder typeBuilder,
      {required bool allowPotentiallyConstantType}) {
    return validateTypeVariableUse(typeBuilder,
            allowPotentiallyConstantType: allowPotentiallyConstantType)
        .buildTypeLiteralType(libraryBuilder);
  }

  @override
  List<DartType> buildDartTypeArguments(List<TypeBuilder>? unresolvedTypes,
      {required bool allowPotentiallyConstantType}) {
    if (unresolvedTypes == null) return <DartType>[];
    return new List<DartType>.generate(
        unresolvedTypes.length,
        (int i) => buildDartType(unresolvedTypes[i],
            allowPotentiallyConstantType: allowPotentiallyConstantType),
        growable: true);
  }

  @override
  String constructorNameForDiagnostics(String name,
      {String? className, bool isSuper: false}) {
    if (className == null) {
      Class cls = sourceClassBuilder!.cls;
      if (isSuper) {
        cls = cls.superclass!;
        while (cls.isMixinApplication) {
          cls = cls.superclass!;
        }
      }
      className = cls.name;
    }
    return name.isEmpty ? className : "$className.$name";
  }

  @override
  void handleNewAsIdentifier(Token token) {
    if (!libraryBuilder.enableConstructorTearOffsInLibrary) {
      addProblem(
          templateExperimentNotEnabled.withArguments(
              'constructor-tearoffs',
              libraryBuilder.enableConstructorTearOffsVersionInLibrary
                  .toText()),
          token.charOffset,
          token.length);
    }
  }
}

abstract class EnsureLoaded {
  void ensureLoaded(Member? member);

  bool isLoaded(Member? member);
}

class Operator {
  final Token token;

  String get name => token.stringValue!;

  final int charOffset;

  Operator(this.token, this.charOffset);

  @override
  String toString() => "operator($name)";
}

class JumpTarget extends BuilderImpl {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  @override
  final MemberBuilder parent;

  @override
  final int charOffset;

  JumpTarget(
      this.kind, this.functionNestingLevel, this.parent, this.charOffset);

  @override
  Uri get fileUri => parent.fileUri!;

  bool get isBreakTarget => kind == JumpTargetKind.Break;

  bool get isContinueTarget => kind == JumpTargetKind.Continue;

  bool get isGotoTarget => kind == JumpTargetKind.Goto;

  bool get hasUsers => users.isNotEmpty;

  void addBreak(Statement statement) {
    assert(isBreakTarget);
    users.add(statement);
  }

  void addContinue(Statement statement) {
    assert(isContinueTarget);
    users.add(statement);
  }

  void addGoto(Statement statement) {
    assert(isGotoTarget);
    users.add(statement);
  }

  void resolveBreaks(
      Forest forest, LabeledStatement target, Statement targetStatement) {
    assert(isBreakTarget);
    for (Statement user in users) {
      BreakStatementImpl breakStatement = user as BreakStatementImpl;
      breakStatement.target = target;
      breakStatement.targetStatement = targetStatement;
    }
    users.clear();
  }

  List<BreakStatementImpl>? resolveContinues(
      Forest forest, LabeledStatement target) {
    assert(isContinueTarget);
    List<BreakStatementImpl> statements = <BreakStatementImpl>[];
    for (Statement user in users) {
      BreakStatementImpl breakStatement = user as BreakStatementImpl;
      breakStatement.target = target;
      statements.add(breakStatement);
    }
    users.clear();
    return statements;
  }

  void resolveGotos(Forest forest, SwitchCase target) {
    assert(isGotoTarget);
    for (Statement user in users) {
      ContinueSwitchStatement continueSwitchStatement =
          user as ContinueSwitchStatement;
      continueSwitchStatement.target = target;
    }
    users.clear();
  }

  @override
  String get fullNameForErrors => "<jump-target>";
}

class LabelTarget extends BuilderImpl implements JumpTarget {
  @override
  final MemberBuilder parent;

  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  @override
  final int functionNestingLevel;

  @override
  final int charOffset;

  LabelTarget(this.parent, this.functionNestingLevel, this.charOffset)
      : breakTarget = new JumpTarget(
            JumpTargetKind.Break, functionNestingLevel, parent, charOffset),
        continueTarget = new JumpTarget(
            JumpTargetKind.Continue, functionNestingLevel, parent, charOffset);

  @override
  Uri get fileUri => parent.fileUri!;

  @override
  bool get hasUsers => breakTarget.hasUsers || continueTarget.hasUsers;

  @override
  List<Statement> get users => unsupported("users", charOffset, fileUri);

  @override
  JumpTargetKind get kind => unsupported("kind", charOffset, fileUri);

  @override
  bool get isBreakTarget => true;

  @override
  bool get isContinueTarget => true;

  @override
  bool get isGotoTarget => false;

  @override
  void addBreak(Statement statement) {
    breakTarget.addBreak(statement);
  }

  @override
  void addContinue(Statement statement) {
    continueTarget.addContinue(statement);
  }

  @override
  void addGoto(Statement statement) {
    unsupported("addGoto", charOffset, fileUri);
  }

  @override
  void resolveBreaks(
      Forest forest, LabeledStatement target, Statement targetStatement) {
    breakTarget.resolveBreaks(forest, target, targetStatement);
  }

  @override
  List<BreakStatementImpl>? resolveContinues(
      Forest forest, LabeledStatement target) {
    return continueTarget.resolveContinues(forest, target);
  }

  @override
  void resolveGotos(Forest forest, SwitchCase target) {
    unsupported("resolveGotos", charOffset, fileUri);
  }

  @override
  String get fullNameForErrors => "<label-target>";
}

class FormalParameters {
  final List<FormalParameterBuilder>? parameters;
  final int charOffset;
  final int length;
  final Uri uri;

  FormalParameters(this.parameters, this.charOffset, this.length, this.uri) {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  FunctionNode buildFunctionNode(
      SourceLibraryBuilder library,
      TypeBuilder? returnType,
      List<TypeVariableBuilder>? typeParameters,
      AsyncMarker asyncModifier,
      Statement body,
      int fileEndOffset) {
    FunctionType type = toFunctionType(
            returnType, const NullabilityBuilder.omitted(), typeParameters)
        .build(library) as FunctionType;
    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    if (parameters != null) {
      for (FormalParameterBuilder parameter in parameters!) {
        if (parameter.isNamed) {
          namedParameters.add(parameter.variable!);
        } else {
          positionalParameters.add(parameter.variable!);
        }
      }
      namedParameters.sort((VariableDeclaration a, VariableDeclaration b) {
        return a.name!.compareTo(b.name!);
      });
    }
    return new FunctionNode(body,
        typeParameters: type.typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: type.requiredParameterCount,
        returnType: type.returnType,
        asyncMarker: asyncModifier)
      ..fileOffset = charOffset
      ..fileEndOffset = fileEndOffset;
  }

  TypeBuilder toFunctionType(
      TypeBuilder? returnType, NullabilityBuilder nullabilityBuilder,
      [List<TypeVariableBuilder>? typeParameters]) {
    return new FunctionTypeBuilder(returnType, typeParameters, parameters,
        nullabilityBuilder, uri, charOffset);
  }

  Scope computeFormalParameterScope(
      Scope parent, Builder declaration, ExpressionGeneratorHelper helper) {
    if (parameters == null) return parent;
    assert(parameters!.isNotEmpty);
    Map<String, Builder> local = <String, Builder>{};

    for (FormalParameterBuilder parameter in parameters!) {
      Builder? existing = local[parameter.name];
      if (existing != null) {
        helper.reportDuplicatedDeclaration(
            existing, parameter.name, parameter.charOffset);
      } else {
        local[parameter.name] = parameter;
      }
    }
    return new Scope(
        local: local,
        parent: parent,
        debugName: "formals",
        isModifiable: false);
  }

  @override
  String toString() {
    return "FormalParameters($parameters, $charOffset, $uri)";
  }
}

/// Returns a block like this:
///
///     {
///       statement;
///       body;
///     }
///
/// If [body] is a [Block], it's returned with [statement] prepended to it.
Block combineStatements(Statement statement, Statement body) {
  if (body is Block) {
    if (statement is Block) {
      body.statements.insertAll(0, statement.statements);
      setParents(statement.statements, body);
    } else {
      body.statements.insert(0, statement);
      statement.parent = body;
    }
    return body;
  } else {
    return new Block(<Statement>[statement, body])
      ..fileOffset = statement.fileOffset;
  }
}

/// DartDocTest(
///   debugName("myClassName", "myName", "myPrefix"),
///   "myPrefix.myClassName.myName"
/// )
/// DartDocTest(
///   debugName("myClassName", "myName"),
///   "myClassName.myName"
/// )
/// DartDocTest(
///   debugName("myClassName", ""),
///   "myClassName"
/// )
/// DartDocTest(
///   debugName("", ""),
///   ""
/// )
String debugName(String className, String name, [String? prefix]) {
  String result = name.isEmpty ? className : "$className.$name";
  return prefix == null ? result : "$prefix.$result";
}

// TODO(johnniwinther): This is a bit ad hoc. Call sites should know what kind
// of objects can be anticipated and handle these directly.
String getNodeName(Object node) {
  if (node is Identifier) {
    return node.name;
  } else if (node is Builder) {
    return node.fullNameForErrors;
  } else if (node is QualifiedName) {
    return flattenName(node, node.charOffset, null);
  } else {
    return unhandled("${node.runtimeType}", "getNodeName", -1, null);
  }
}

/// A data holder used to hold the information about a label that is pushed on
/// the stack.
class Label {
  String name;
  int charOffset;

  Label(this.name, this.charOffset);

  @override
  String toString() => "label($name)";
}

class ForInElements {
  VariableDeclaration? explicitVariableDeclaration;
  VariableDeclaration? syntheticVariableDeclaration;
  Expression? syntheticAssignment;
  Expression? expressionProblem;
  Statement? expressionEffects;

  VariableDeclaration get variable =>
      (explicitVariableDeclaration ?? syntheticVariableDeclaration)!;
}

class _BodyBuilderCloner extends CloneVisitorNotMembers {
  final BodyBuilder bodyBuilder;

  _BodyBuilderCloner(this.bodyBuilder);

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    if (node is FactoryConstructorInvocation) {
      FactoryConstructorInvocation result = new FactoryConstructorInvocation(
          node.target, clone(node.arguments),
          isConst: node.isConst)
        ..hasBeenInferred = node.hasBeenInferred;
      bodyBuilder.redirectingFactoryInvocations.add(result);
      return result;
    } else if (node is TypeAliasedFactoryInvocation) {
      TypeAliasedFactoryInvocation result = new TypeAliasedFactoryInvocation(
          node.typeAliasBuilder, node.target, clone(node.arguments),
          isConst: node.isConst)
        ..hasBeenInferred = node.hasBeenInferred;
      bodyBuilder.typeAliasedFactoryInvocations.add(result);
      return result;
    }
    return super.visitStaticInvocation(node);
  }

  @override
  TreeNode visitConstructorInvocation(ConstructorInvocation node) {
    if (node is TypeAliasedConstructorInvocation) {
      TypeAliasedConstructorInvocation result =
          new TypeAliasedConstructorInvocation(
              node.typeAliasBuilder, node.target, clone(node.arguments),
              isConst: node.isConst)
            ..hasBeenInferred = node.hasBeenInferred;
      bodyBuilder.typeAliasedConstructorInvocations.add(result);
      return result;
    }
    return super.visitConstructorInvocation(node);
  }

  @override
  TreeNode visitArguments(Arguments node) {
    if (node is ArgumentsImpl) {
      return ArgumentsImpl.clone(node, node.positional.map(clone).toList(),
          node.named.map(clone).toList(), node.types.map(visitType).toList());
    }
    return super.visitArguments(node);
  }
}

/// Returns `true` if [node] is not part of its parent member.
///
/// This computation is costly and should only be used in assertions to verify
/// that [node] has been removed from the AST.
bool isOrphaned(TreeNode node) {
  TreeNode? parent = node;
  Member? member;
  while (parent != null) {
    if (parent is Member) {
      member = parent;
      break;
    }
    parent = parent.parent;
  }
  if (member == null) {
    return true;
  }
  _FindChildVisitor visitor = new _FindChildVisitor(node);
  member.accept(visitor);
  return !visitor.foundNode;
}

class _FindChildVisitor extends Visitor<void> with VisitorVoidMixin {
  final TreeNode soughtNode;
  bool foundNode = false;

  _FindChildVisitor(this.soughtNode);

  @override
  void defaultNode(Node node) {
    if (!foundNode) {
      if (identical(node, soughtNode)) {
        foundNode = true;
      } else {
        node.visitChildren(this);
      }
    }
  }
}
