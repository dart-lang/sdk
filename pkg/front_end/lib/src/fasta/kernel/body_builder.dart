// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.body_builder;

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
    show FixedNullableList, GrowableList, NullValues, ParserRecovery;
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show isBinaryOperator, isMinusOperator, isUserDefinableOperator;
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/fasta/kernel/benchmarker.dart' show Benchmarker;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/src/bounds_checks.dart' hide calculateBounds;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/extension_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/inline_class_builder.dart';
import '../builder/invalid_type_builder.dart';
import '../builder/invalid_type_declaration_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/record_type_builder.dart';
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
        messageNamedFieldClashesWithPositionalFieldInRecord,
        noLength,
        templateDuplicatedRecordLiteralFieldName,
        templateDuplicatedRecordLiteralFieldNameContext,
        templateExperimentNotEnabledOffByDefault;
import '../identifiers.dart'
    show Identifier, InitializedIdentifier, QualifiedName, flattenName;
import '../modifier.dart'
    show Modifier, constMask, covariantMask, finalMask, lateMask, requiredMask;
import '../names.dart' show emptyName, minusName, plusName;
import '../problems.dart' show internalProblem, unhandled, unsupported;
import '../scope.dart';
import '../source/diet_parser.dart';
import '../source/source_field_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/stack_listener_impl.dart'
    show StackListenerImpl, offsetForToken;
import '../source/value_kinds.dart';
import '../type_inference/inference_results.dart'
    show InitializerInferenceResult;
import '../type_inference/type_inferrer.dart'
    show TypeInferrer, InferredFunctionBody;
import '../type_inference/type_schema.dart' show UnknownType;
import '../util/helpers.dart';
import 'body_builder_context.dart';
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
import 'type_algorithms.dart' show calculateBounds;
import 'utils.dart';

// TODO(ahe): Remove this and ensure all nodes have a location.
const int noLocation = TreeNode.noOffset;

enum JumpTargetKind {
  Break,
  Continue,
  Goto, // Continue label in switch.
}

class BodyBuilder extends StackListenerImpl
    implements ExpressionGeneratorHelper, EnsureLoaded, DelayedActionPerformer {
  @override
  final Forest forest;

  @override
  final SourceLibraryBuilder libraryBuilder;

  final BodyBuilderContext _context;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final Scope enclosingScope;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  // TODO(ahe): Consider renaming [uri] to 'partUri'.
  @override
  final Uri uri;

  final TypeInferrer typeInferrer;

  final Benchmarker? benchmarker;

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

  /// If the current member is an instance member in an extension declaration or
  /// an instance member or constructor in and inline class declaration,
  /// [thisVariable] holds the synthetically added variable holding the value
  /// for `this`.
  final VariableDeclaration? thisVariable;

  final List<TypeParameter>? thisTypeParameters;

  Scope scope;

  Set<VariableDeclaration>? declaredInCurrentGuard;

  JumpTarget? breakTarget;

  JumpTarget? continueTarget;

  BodyBuilder(
      {required this.libraryBuilder,
      required BodyBuilderContext context,
      required this.enclosingScope,
      this.formalParameterScope,
      required this.hierarchy,
      required this.coreTypes,
      this.thisVariable,
      this.thisTypeParameters,
      required this.uri,
      required this.typeInferrer})
      : _context = context,
        forest = const Forest(),
        enableNative = libraryBuilder.loader.target.backendTarget
            .enableNative(libraryBuilder.importUri),
        stringExpectedAfterNative = libraryBuilder
            .loader.target.backendTarget.nativeExtensionExpectsString,
        needsImplicitSuperInitializer =
            context.needsImplicitSuperInitializer(coreTypes),
        benchmarker = libraryBuilder.loader.target.benchmarker,
        this.scope = enclosingScope {
    Iterator<VariableBuilder>? iterator =
        formalParameterScope?.filteredIterator<VariableBuilder>(
            includeDuplicates: false, includeAugmentations: false);
    if (iterator != null) {
      while (iterator.moveNext()) {
        typeInferrer.assignedVariables.declare(iterator.current.variable!);
      }
    }
  }

  BodyBuilder.forField(
      SourceLibraryBuilder libraryBuilder,
      BodyBuilderContext bodyBuilderContext,
      Scope enclosingScope,
      TypeInferrer typeInferrer,
      Uri uri)
      : this(
            libraryBuilder: libraryBuilder,
            context: bodyBuilderContext,
            enclosingScope: enclosingScope,
            formalParameterScope: null,
            hierarchy: libraryBuilder.loader.hierarchy,
            coreTypes: libraryBuilder.loader.coreTypes,
            thisVariable: null,
            uri: uri,
            typeInferrer: typeInferrer);

  BodyBuilder.forOutlineExpression(SourceLibraryBuilder library,
      BodyBuilderContext bodyBuilderContext, Scope scope, Uri fileUri,
      {Scope? formalParameterScope})
      : this(
            libraryBuilder: library,
            context: bodyBuilderContext,
            enclosingScope: scope,
            formalParameterScope: formalParameterScope,
            hierarchy: library.loader.hierarchy,
            coreTypes: library.loader.coreTypes,
            thisVariable: null,
            uri: fileUri,
            typeInferrer: library.loader.typeInferenceEngine
                .createLocalTypeInferrer(
                    fileUri, bodyBuilderContext.thisType, library, null));

  JumpTarget createBreakTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Break, charOffset);
  }

  JumpTarget createContinueTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Continue, charOffset);
  }

  JumpTarget createGotoTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Goto, charOffset);
  }

  void enterLocalScope(Scope localScope) {
    push(scope);
    scope = localScope;
    assert(checkState(null, [
      ValueKinds.Scope,
    ]));
  }

  void createAndEnterLocalScope(
      {required String debugName, required ScopeKind kind}) {
    push(scope);
    scope = scope.createNestedScope(debugName: debugName, kind: kind);
    assert(checkState(null, [
      ValueKinds.Scope,
    ]));
  }

  @override
  void exitLocalScope({List<ScopeKind>? expectedScopeKinds}) {
    assert(checkState(null, [
      ValueKinds.Scope,
    ]));
    assert(
        expectedScopeKinds == null || expectedScopeKinds.contains(scope.kind),
        "Expected the current scope to be one of the kinds "
        "${expectedScopeKinds.map((k) => "'${k}'").join(", ")}, "
        "but got '${scope.kind}'.");
    if (isGuardScope(scope) && declaredInCurrentGuard != null) {
      for (Builder builder in scope.localMembers) {
        if (builder is VariableBuilder) {
          declaredInCurrentGuard!.remove(builder.variable);
        }
      }
      if (declaredInCurrentGuard!.isEmpty) {
        declaredInCurrentGuard = null;
      }
    }
    scope = pop() as Scope;
  }

  void enterBreakTarget(int charOffset, [JumpTarget? target]) {
    push(breakTarget ?? NullValues.BreakTarget);
    breakTarget = target ?? createBreakTarget(charOffset);
  }

  void enterContinueTarget(int charOffset, [JumpTarget? target]) {
    push(continueTarget ?? NullValues.ContinueTarget);
    continueTarget = target ?? createContinueTarget(charOffset);
  }

  JumpTarget? exitBreakTarget() {
    JumpTarget? current = breakTarget;
    breakTarget = pop() as JumpTarget?;
    return current;
  }

  JumpTarget? exitContinueTarget() {
    JumpTarget? current = continueTarget;
    continueTarget = pop() as JumpTarget?;
    return current;
  }

  @override
  void beginBlockFunctionBody(Token begin) {
    debugEvent("beginBlockFunctionBody");
    createAndEnterLocalScope(
        debugName: "block function body", kind: ScopeKind.functionBody);
  }

  @override
  void beginForStatement(Token token) {
    debugEvent("beginForStatement");
    enterLoop(token.charOffset);
    createAndEnterLocalScope(
        debugName: "for statement", kind: ScopeKind.forStatement);
  }

  @override
  void beginForControlFlow(Token? awaitToken, Token forToken) {
    debugEvent("beginForControlFlow");
    createAndEnterLocalScope(
        debugName: "for in a collection", kind: ScopeKind.forStatement);
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    debugEvent("beginDoWhileStatementBody");
    createAndEnterLocalScope(
        debugName: "do-while statement body",
        kind: ScopeKind.statementLocalScope);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("endDoWhileStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginWhileStatementBody(Token token) {
    debugEvent("beginWhileStatementBody");
    createAndEnterLocalScope(
        debugName: "while statement body", kind: ScopeKind.statementLocalScope);
  }

  @override
  void endWhileStatementBody(Token token) {
    debugEvent("endWhileStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForStatementBody(Token token) {
    debugEvent("beginForStatementBody");
    createAndEnterLocalScope(
        debugName: "for statement body", kind: ScopeKind.statementLocalScope);
  }

  @override
  void endForStatementBody(Token token) {
    debugEvent("endForStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForInBody(Token token) {
    debugEvent("beginForInBody");
    createAndEnterLocalScope(
        debugName: "for-in body", kind: ScopeKind.statementLocalScope);
  }

  @override
  void endForInBody(Token token) {
    debugEvent("endForInBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginElseStatement(Token token) {
    debugEvent("beginElseStatement");
    createAndEnterLocalScope(
        debugName: "else", kind: ScopeKind.statementLocalScope);
  }

  @override
  void endElseStatement(Token token) {
    debugEvent("endElseStatement");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  bool get inConstructor {
    return functionNestingLevel == 0 && _context.isConstructor;
  }

  @override
  bool get isDeclarationInstanceContext {
    return _context.isDeclarationInstanceContext;
  }

  @override
  InstanceTypeVariableAccessState get instanceTypeVariableAccessState {
    return _context.instanceTypeVariableAccessState;
  }

  @override
  TypeEnvironment get typeEnvironment => typeInferrer.typeSchemaEnvironment;

  DartType get implicitTypeArgument => const ImplicitTypeArgument();

  void _enterLocalState({bool inLateLocalInitializer = false}) {
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

  Pattern toPattern(Object? node) {
    if (node is Pattern) {
      return node;
    } else if (node is Generator) {
      return forest.createConstantPattern(node.buildSimpleRead());
    } else if (node is Expression) {
      return forest.createConstantPattern(node);
    } else if (node is ProblemBuilder) {
      // ignore: unused_local_variable
      Expression expression =
          buildProblem(node.message, node.charOffset, noLength);
      return forest.createConstantPattern(expression);
    } else {
      return unhandled("${node.runtimeType}", "toPattern", -1, uri);
    }
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
    Statement? statement = pop(NullValues.Block) as Statement?;
    if (statement != null) {
      statement = forest.wrapVariables(statement);
    }
    return statement;
  }

  void enterSwitchScope() {
    push(switchScope ?? NullValues.SwitchScope);
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
    if (isGuardScope(scope)) {
      (declaredInCurrentGuard ??= {}).add(variable);
    }
    LocatedMessage? context = scope.declare(
        variable.name!, new VariableBuilderImpl(variable, uri), uri);
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

  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(kind, functionNestingLevel, uri, charOffset);
  }

  void inferAnnotations(TreeNode? parent, List<Expression>? annotations) {
    if (annotations != null) {
      typeInferrer.inferMetadata(this, parent, annotations);
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
    assert(checkState(null, repeatedKind(ValueKinds.Expression, count)));
    debugEvent("MetadataStar");
    if (count == 0) {
      push(NullValues.Metadata);
    } else {
      push(const GrowableList<Expression>()
              .popNonNullable(stack, count, dummyExpression) ??
          NullValues.Metadata /* Ignore parser recovery */);
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
      Token? augmentToken,
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
    for (int i = 0; i < count; i++) {
      assert(checkState(null, [
        ValueKinds.FieldInitializerOrNull,
        ValueKinds.Identifier,
      ]));
      Expression? initializer = pop() as Expression?;
      Identifier identifier = pop() as Identifier;
      String name = identifier.name;
      Builder declaration = _context.lookupLocalMember(name, required: true)!;
      int fileOffset = identifier.charOffset;
      while (declaration.next != null) {
        // If we have duplicates, we try to find the right declaration.
        if (declaration.fileUri == uri &&
            declaration.charOffset == fileOffset) {
          break;
        }
        declaration = declaration.next!;
      }
      if (declaration.fileUri != uri || declaration.charOffset != fileOffset) {
        // If we don't have the right declaration, skip the initializer.
        continue;
      }
      SourceFieldBuilder fieldBuilder;
      if (declaration.isField) {
        fieldBuilder = declaration as SourceFieldBuilder;
      } else {
        continue;
      }
      if (initializer != null) {
        if (fieldBuilder.hasBodyBeenBuilt) {
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
        buildDartType(type, TypeUse.fieldType,
            allowPotentiallyConstantType: false);
      }
    }
    pop(); // Annotations.

    performBacklogComputations(allowFurtherDelays: false);
    assert(stack.length == 0);
  }

  /// Perform delayed computations that were put on back log during body
  /// building.
  ///
  /// Back logged computations include resolution of redirecting factory
  /// invocations and checking of typedef types.
  ///
  /// If the parameter [allowFurtherDelays] is set to `true`, the backlog
  /// computations are allowed to be delayed one more time if they can't be
  /// completed in the current invocation of [performBacklogComputations] and
  /// have a chance to be completed during the next invocation. If
  /// [allowFurtherDelays] is set to `false`, the backlog computations are
  /// assumed to be final and the function throws an internal exception in case
  /// if any of the computations can't be completed.
  void performBacklogComputations(
      {List<DelayedActionPerformer>? delayedActionPerformers,
      required bool allowFurtherDelays}) {
    _finishVariableMetadata();
    _unaliasTypeAliasedConstructorInvocations();
    _unaliasTypeAliasedFactoryInvocations(typeAliasedFactoryInvocations);
    _resolveRedirectingFactoryTargets(redirectingFactoryInvocations,
        allowFurtherDelays: allowFurtherDelays);
    libraryBuilder.checkPendingBoundsChecks(typeEnvironment);
    if (hasDelayedActions) {
      assert(
          delayedActionPerformers != null,
          "Body builder has delayed actions that cannot be performed: "
          "$delayedRedirectingFactoryInvocations");
      delayedActionPerformers?.add(this);
    }
  }

  void finishRedirectingFactoryBody() {
    performBacklogComputations(allowFurtherDelays: false);
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
      push(NullValues.Block);
    } else {
      Statement block = popBlock(count, openBrace, closeBrace);
      exitLocalScope();
      push(block);
    }
    assert(checkState(closeBrace, [ValueKinds.StatementOrNull]));
  }

  void prepareInitializers() {
    scope = _context.computeFormalParameterInitializerScope(scope);
    if (_context.isConstructor) {
      _context.prepareInitializers();
      if (_context.formals != null) {
        for (FormalParameterBuilder formal in _context.formals!) {
          if (formal.isInitializingFormal) {
            List<Initializer> initializers;
            if (_context.isExternalConstructor) {
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
              _context.addInitializer(initializer, this, inferenceResult: null);
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
      scope = formalParameterScope ??
          new Scope.immutable(kind: ScopeKind.initializers);
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
      scope = formalParameterScope ??
          new Scope.immutable(kind: ScopeKind.initializers);
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

    if (!(_context.isConstructor && !_context.isExternalConstructor)) {
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

  List<Object>? createSuperParametersAsArguments(
      List<FormalParameterBuilder> formals) {
    List<Object>? superParametersAsArguments;
    for (FormalParameterBuilder formal in formals) {
      if (formal.isSuperInitializingFormal) {
        if (formal.isNamed) {
          (superParametersAsArguments ??= <Object>[]).add(new NamedExpression(
              formal.name,
              createVariableGet(formal.variable!, formal.charOffset,
                  forNullGuardedAccess: false))
            ..fileOffset = formal.charOffset);
        } else {
          (superParametersAsArguments ??= <Object>[]).add(createVariableGet(
              formal.variable!, formal.charOffset,
              forNullGuardedAccess: false));
        }
      }
    }
    return superParametersAsArguments;
  }

  void finishFunction(
      FormalParameters? formals, AsyncMarker asyncModifier, Statement? body) {
    debugEvent("finishFunction");

    // Create variable get expressions for super parameters before finishing
    // the analysis of the assigned variables. Creating the expressions later
    // that point results in a flow analysis error.
    List<Object>? superParametersAsArguments;
    if (formals != null) {
      List<FormalParameterBuilder>? formalParameters = formals.parameters;
      if (formalParameters != null) {
        superParametersAsArguments =
            createSuperParametersAsArguments(formalParameters);
      }
    }
    typeInferrer.assignedVariables.finish();

    FunctionNode function = _context.function;
    if (thisVariable != null) {
      typeInferrer.flowAnalysis
          .declare(thisVariable!, thisVariable!.type, initialized: true);
    }
    if (formals?.parameters != null) {
      for (int i = 0; i < formals!.parameters!.length; i++) {
        FormalParameterBuilder parameter = formals.parameters![i];
        VariableDeclaration variable = parameter.variable!;
        typeInferrer.flowAnalysis
            .declare(variable, variable.type, initialized: true);
      }
      for (int i = 0; i < formals.parameters!.length; i++) {
        FormalParameterBuilder parameter = formals.parameters![i];
        Expression? initializer = parameter.variable!.initializer;
        if (!parameter.isSuperInitializingFormal &&
            (parameter.isOptionalPositional || initializer != null)) {
          if (!parameter.initializerWasInferred) {
            parameter.initializerWasInferred = true;
            if (parameter.isOptionalPositional) {
              initializer ??= forest.createNullLiteral(
                  // TODO(ahe): Should store: originParameter.fileOffset
                  // https://github.com/dart-lang/sdk/issues/32289
                  noLocation);
            }
            VariableDeclaration originParameter =
                _context.getFormalParameter(i);
            initializer = typeInferrer.inferParameterInitializer(
                this,
                initializer!,
                originParameter.type,
                parameter.hasDeclaredInitializer);
            originParameter.initializer = initializer..parent = originParameter;
          }

          VariableDeclaration? tearOffParameter =
              _context.getTearOffParameter(i);
          if (tearOffParameter != null) {
            Expression tearOffInitializer =
                _cloner.cloneInContext(initializer!);
            tearOffParameter.initializer = tearOffInitializer
              ..parent = tearOffParameter;
          }
        }
      }
    }

    if (_context.isConstructor) {
      finishConstructor(asyncModifier, body,
          superParametersAsArguments: superParametersAsArguments);
    } else if (body != null) {
      _context.setAsyncModifier(asyncModifier);
    }

    InferredFunctionBody? inferredFunctionBody;
    if (body != null) {
      inferredFunctionBody = typeInferrer.inferFunctionBody(
          this,
          _context.memberCharOffset,
          _context.returnTypeContext,
          asyncModifier,
          body);
      body = inferredFunctionBody.body;
      function.futureValueType = inferredFunctionBody.futureValueType;
      assert(
          !(function.asyncMarker == AsyncMarker.Async &&
              function.futureValueType == null),
          "No future value type computed.");
    }

    if (_context.returnType is! OmittedTypeBuilder) {
      checkAsyncReturnType(asyncModifier, function.returnType,
          _context.memberCharOffset, _context.memberName.length);
    }

    if (_context.isSetter) {
      if (formals?.parameters == null ||
          formals!.parameters!.length != 1 ||
          formals.parameters!.single.isOptionalPositional) {
        int charOffset = formals?.charOffset ??
            body?.fileOffset ??
            _context.memberCharOffset;
        if (body == null) {
          body = new EmptyStatement()..fileOffset = charOffset;
        }
        if (_context.formals != null) {
          // Illegal parameters were removed by the function builder.
          // Add them as local variable to put them in scope of the body.
          List<Statement> statements = <Statement>[];
          for (FormalParameterBuilder parameter in _context.formals!) {
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
    bool isNoSuchMethodForwarder = (function.parent is Procedure &&
        (function.parent as Procedure).isNoSuchMethodForwarder);
    if (body != null) {
      if (_context.isExternalFunction || isNoSuchMethodForwarder) {
        body = new Block(<Statement>[
          new ExpressionStatement(buildProblem(
              fasta.messageExternalMethodWithBody, body.fileOffset, noLength))
            ..fileOffset = body.fileOffset,
          body,
        ])
          ..fileOffset = body.fileOffset;
      }
      _context.setBody(body);
    }

    performBacklogComputations(allowFurtherDelays: false);
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

  RedirectionTarget _getRedirectionTarget(Procedure factory) {
    List<DartType> typeArguments = new List<DartType>.generate(
        factory.function.typeParameters.length, (int i) {
      return new TypeParameterType.withDefaultNullabilityForLibrary(
          factory.function.typeParameters[i], factory.enclosingLibrary);
    }, growable: true);

    // Cyclic factories are detected earlier, so we're guaranteed to
    // reach either a non-redirecting factory or an error eventually.
    Member target = factory;
    for (;;) {
      RedirectingFactoryTarget? redirectingFactoryTarget =
          target.function?.redirectingFactoryTarget;
      if (redirectingFactoryTarget == null ||
          redirectingFactoryTarget.isError) {
        return new RedirectionTarget(target, typeArguments);
      }
      Member nextMember = redirectingFactoryTarget.target!;
      ensureLoaded(nextMember);
      List<DartType>? nextTypeArguments =
          redirectingFactoryTarget.typeArguments;
      if (nextTypeArguments != null) {
        Substitution sub = Substitution.fromPairs(
            target.function!.typeParameters, typeArguments);
        typeArguments =
            new List<DartType>.generate(nextTypeArguments.length, (int i) {
          return sub.substituteType(nextTypeArguments[i]);
        }, growable: true);
      } else {
        typeArguments = <DartType>[];
      }
      target = nextMember;
    }
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

    RedirectionTarget redirectionTarget = _getRedirectionTarget(initialTarget);
    Member resolvedTarget = redirectionTarget.target;
    if (redirectionTarget.typeArguments.any((type) => type is UnknownType)) {
      return null;
    }

    RedirectingFactoryTarget? redirectingFactoryTarget =
        resolvedTarget.function?.redirectingFactoryTarget;
    if (redirectingFactoryTarget != null) {
      // If the redirection target is itself a redirecting factory, it means
      // that it is unresolved.
      assert(redirectingFactoryTarget.isError);
      String errorMessage = redirectingFactoryTarget.errorMessage!;
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
          charOffset: fileOffset,
          isConstructorInvocation: true);
    }
    return replacementNode;
  }

  /// If the parameter [allowFurtherDelays] is set to `true`, the resolution of
  /// redirecting factories is allowed to be delayed one more time if it can't
  /// be completed in the current invocation of
  /// [_resolveRedirectingFactoryTargets] and has a chance to be completed
  /// during the next invocation. If [allowFurtherDelays] is set to `false`,
  /// the resolution of redirecting factories is assumed to be final and the
  /// function throws an internal exception in case if any of the resolutions
  /// can't be completed.
  void _resolveRedirectingFactoryTargets(
      List<FactoryConstructorInvocation> redirectingFactoryInvocations,
      {required bool allowFurtherDelays}) {
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
      if (!invocation.hasBeenInferred) {
        if (allowFurtherDelays) {
          delayedRedirectingFactoryInvocations.add(invocation);
        }
        continue;
      }
      Expression? replacement = _resolveRedirectingFactoryTarget(
          invocation.target,
          invocation.arguments,
          invocation.fileOffset,
          invocation.isConst);
      if (replacement == null) {
        delayedRedirectingFactoryInvocations.add(invocation);
      } else {
        invocation.parent?.replaceChild(invocation, replacement);
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
      invocation.parent?.replaceChild(
          invocation,
          new ConstructorInvocation(invocation.target, invocationArguments,
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
        invocation.parent?.replaceChild(invocation, replacement);
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
  void performDelayedActions({required bool allowFurtherDelays}) {
    if (delayedRedirectingFactoryInvocations.isNotEmpty) {
      _resolveRedirectingFactoryTargets(delayedRedirectingFactoryInvocations,
          allowFurtherDelays: allowFurtherDelays);
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
    performBacklogComputations(allowFurtherDelays: false);
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
                return new FormalParameterBuilder(
                    /* metadata = */
                    null,
                    FormalParameterKind.requiredPositional,
                    /* modifiers = */
                    0,
                    const ImplicitTypeBuilder(),
                    formal.name!,
                    libraryBuilder,
                    formal.fileOffset,
                    fileUri: uri)
                  ..variable = formal;
              }, growable: false);
    enterLocalScope(new FormalParameters(formals, fileOffset, noLength, uri)
        .computeFormalParameterScope(scope, this));

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
        VariableDeclaration variable = formals[i].variable!;
        typeInferrer.flowAnalysis
            .declare(variable, variable.type, initialized: true);
      }
    }
    InferredFunctionBody inferredFunctionBody = typeInferrer.inferFunctionBody(
        this, fileOffset, const DynamicType(), AsyncMarker.Sync, fakeReturn);
    assert(
        fakeReturn == inferredFunctionBody.body,
        "Previously implicit assumption about inferFunctionBody "
        "not returning anything different.");

    performBacklogComputations(allowFurtherDelays: false);

    return fakeReturn.expression!;
  }

  List<Initializer>? parseInitializers(Token token,
      {bool doFinishConstructor = true}) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
        allowPatterns: libraryFeatures.patterns.isEnabled);
    if (!token.isEof) {
      token = parser.parseInitializers(token);
      checkEmpty(token.charOffset);
    } else {
      handleNoInitializers();
    }
    if (doFinishConstructor) {
      List<FormalParameterBuilder>? formals = _context.formals;
      finishConstructor(AsyncMarker.Sync, null,
          superParametersAsArguments: formals != null
              ? createSuperParametersAsArguments(formals)
              : null);
    }
    return _initializers;
  }

  Expression parseFieldInitializer(Token token) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
        allowPatterns: libraryFeatures.patterns.isEnabled);
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
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
        allowPatterns: libraryFeatures.patterns.isEnabled);
    Token endToken = parser.parseMetadata(parser.syntheticPreviousToken(token));
    assert(checkState(token, [ValueKinds.Expression]));
    Expression annotation = pop() as Expression;
    checkEmpty(endToken.charOffset);
    return annotation;
  }

  ArgumentsImpl parseArguments(Token token) {
    Parser parser = new Parser(this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
        allowPatterns: libraryFeatures.patterns.isEnabled);
    token = parser.parseArgumentsRest(token);
    ArgumentsImpl arguments = pop() as ArgumentsImpl;
    checkEmpty(token.charOffset);
    return arguments;
  }

  void finishConstructor(AsyncMarker asyncModifier, Statement? body,
      {required List<Object /* Expression | NamedExpression */ >?
          superParametersAsArguments}) {
    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf).
    assert(() {
      if (superParametersAsArguments == null) {
        return true;
      }
      for (Object superParameterAsArgument in superParametersAsArguments) {
        if (superParameterAsArgument is! Expression &&
            superParameterAsArgument is! NamedExpression) {
          return false;
        }
      }
      return true;
    }(),
        "Expected 'superParametersAsArguments' "
        "to contain nothing but Expressions and NamedExpressions.");
    assert(() {
      if (superParametersAsArguments == null) {
        return true;
      }
      int previousOffset = -1;
      for (Object superParameterAsArgument in superParametersAsArguments) {
        int offset;
        if (superParameterAsArgument is Expression) {
          offset = superParameterAsArgument.fileOffset;
        } else if (superParameterAsArgument is NamedExpression) {
          offset = superParameterAsArgument.value.fileOffset;
        } else {
          return false;
        }
        if (previousOffset > offset) {
          return false;
        }
        previousOffset = offset;
      }
      return true;
    }(),
        "Expected 'superParametersAsArguments' "
        "to be sorted by occurrence in file.");

    FunctionNode function = _context.function;
    List<FormalParameterBuilder>? formals = _context.formals;
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder parameter = formals[i];
        VariableDeclaration variable = parameter.variable!;
        // TODO(paulberry): `skipDuplicateCheck` is currently needed to work
        // around a failure in
        // co19/Language/Expressions/Postfix_Expressions/conditional_increment_t02;
        // fix this.
        typeInferrer.flowAnalysis.declare(variable, variable.type,
            initialized: true, skipDuplicateCheck: true);
      }
    }

    Set<String>? namedSuperParameterNames;
    List<Expression>? positionalSuperParametersAsArguments;
    List<NamedExpression>? namedSuperParametersAsArguments;
    if (superParametersAsArguments != null) {
      for (Object superParameterAsArgument in superParametersAsArguments) {
        if (superParameterAsArgument is Expression) {
          (positionalSuperParametersAsArguments ??= <Expression>[])
              .add(superParameterAsArgument);
        } else {
          NamedExpression namedSuperParameterAsArgument =
              superParameterAsArgument as NamedExpression;
          (namedSuperParametersAsArguments ??= <NamedExpression>[])
              .add(namedSuperParameterAsArgument);
          (namedSuperParameterNames ??= <String>{})
              .add(namedSuperParameterAsArgument.name);
        }
      }
    } else if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isSuperInitializingFormal) {
          if (formal.isNamed) {
            NamedExpression superParameterAsArgument = new NamedExpression(
                formal.name,
                createVariableGet(formal.variable!, formal.charOffset,
                    forNullGuardedAccess: false))
              ..fileOffset = formal.charOffset;
            (namedSuperParametersAsArguments ??= <NamedExpression>[])
                .add(superParameterAsArgument);
            (namedSuperParameterNames ??= <String>{}).add(formal.name);
            (superParametersAsArguments ??= <Object>[])
                .add(superParameterAsArgument);
          } else {
            Expression superParameterAsArgument = createVariableGet(
                formal.variable!, formal.charOffset,
                forNullGuardedAccess: false);
            (positionalSuperParametersAsArguments ??= <Expression>[])
                .add(superParameterAsArgument);
            (superParametersAsArguments ??= <Object>[])
                .add(superParameterAsArgument);
          }
        }
      }
    }

    List<Initializer>? initializers = _initializers;
    if (initializers != null && initializers.isNotEmpty) {
      if (_context.isMixinClass) {
        // Report an error if a mixin class has a constructor with an
        // initializer.
        buildProblem(
            fasta.templateIllegalMixinDueToConstructors
                .withArguments(_context.className),
            _context.memberCharOffset,
            noLength);
      }
      if (initializers.last is SuperInitializer) {
        SuperInitializer superInitializer =
            initializers.last as SuperInitializer;
        if (_context.isEnumClass) {
          initializers[initializers.length - 1] = buildInvalidInitializer(
              buildProblem(fasta.messageEnumConstructorSuperInitializer,
                  superInitializer.fileOffset, noLength))
            ..parent = superInitializer.parent;
        } else if (libraryFeatures.superParameters.isEnabled) {
          ArgumentsImpl arguments = superInitializer.arguments as ArgumentsImpl;

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
              arguments.positionalAreSuperParameters = true;
            }
          }
          if (namedSuperParametersAsArguments != null) {
            // TODO(cstefantsova): Report name conflicts.
            arguments.named.addAll(namedSuperParametersAsArguments);
            setParents(namedSuperParametersAsArguments, arguments);
            arguments.namedSuperParameterNames = namedSuperParameterNames;
          }
          if (superParametersAsArguments != null) {
            arguments.argumentsOriginalOrder
                ?.insertAll(0, superParametersAsArguments);
          }
        }
      } else if (initializers.last is RedirectingInitializer) {
        RedirectingInitializer redirectingInitializer =
            initializers.last as RedirectingInitializer;
        if (_context.isEnumClass && libraryFeatures.enhancedEnums.isEnabled) {
          ArgumentsImpl arguments =
              redirectingInitializer.arguments as ArgumentsImpl;
          List<Expression> enumSyntheticArguments = [
            new VariableGetImpl(function.positionalParameters[0],
                forNullGuardedAccess: false)
              ..parent = redirectingInitializer.arguments,
            new VariableGetImpl(function.positionalParameters[1],
                forNullGuardedAccess: false)
              ..parent = redirectingInitializer.arguments
          ];
          arguments.positional.insertAll(0, enumSyntheticArguments);
          arguments.argumentsOriginalOrder
              ?.insertAll(0, enumSyntheticArguments);
        }
      }

      List<InitializerInferenceResult> inferenceResults =
          new List<InitializerInferenceResult>.generate(
              initializers.length,
              (index) => _context.inferInitializer(
                  initializers[index], this, typeInferrer),
              growable: false);

      if (!_context.isExternalConstructor) {
        for (int i = 0; i < initializers.length; i++) {
          _context.addInitializer(initializers[i], this,
              inferenceResult: inferenceResults[i]);
        }
      }
    }

    if (asyncModifier != AsyncMarker.Sync) {
      _context.addInitializer(
          buildInvalidInitializer(buildProblem(
              fasta.messageConstructorNotSync, body!.fileOffset, noLength)),
          this,
          inferenceResult: null);
    }
    if (needsImplicitSuperInitializer) {
      /// >If no superinitializer is provided, an implicit superinitializer
      /// >of the form super() is added at the end of k’s initializer list,
      /// >unless the enclosing class is class Object.
      Constructor? superTarget = lookupSuperConstructor(emptyName);
      Initializer initializer;
      ArgumentsImpl arguments;
      List<Expression>? positionalArguments;
      List<NamedExpression>? namedArguments;
      if (libraryFeatures.superParameters.isEnabled) {
        positionalArguments = positionalSuperParametersAsArguments;
        namedArguments = namedSuperParametersAsArguments;
      }
      if (_context.isEnumClass) {
        assert(function.positionalParameters.length >= 2 &&
            function.positionalParameters[0].name == "#index" &&
            function.positionalParameters[1].name == "#name");
        (positionalArguments ??= <Expression>[]).insertAll(0, [
          new VariableGetImpl(function.positionalParameters[0],
              forNullGuardedAccess: false),
          new VariableGetImpl(function.positionalParameters[1],
              forNullGuardedAccess: false)
        ]);
      }

      if (positionalArguments != null || namedArguments != null) {
        arguments = forest.createArguments(
            noLocation, positionalArguments ?? <Expression>[],
            named: namedArguments);
      } else {
        arguments = forest.createArgumentsEmpty(noLocation);
      }

      arguments.positionalAreSuperParameters =
          positionalSuperParametersAsArguments != null;
      arguments.namedSuperParameterNames = namedSuperParameterNames;

      if (superTarget == null ||
          checkArgumentsForFunction(superTarget.function, arguments,
                  _context.memberCharOffset, const <TypeParameter>[]) !=
              null) {
        String superclass = _context.superClassName;
        int length = _context.memberName.length;
        if (length == 0) {
          length = _context.className.length;
        }
        initializer = buildInvalidInitializer(
            buildProblem(
                fasta.templateSuperclassHasNoDefaultConstructor
                    .withArguments(superclass),
                _context.memberCharOffset,
                length),
            _context.memberCharOffset);
      } else {
        initializer = buildSuperInitializer(
            true, superTarget, arguments, _context.memberCharOffset);
      }
      if (libraryFeatures.superParameters.isEnabled) {
        InitializerInferenceResult inferenceResult =
            _context.inferInitializer(initializer, this, typeInferrer);
        _context.addInitializer(initializer, this,
            inferenceResult: inferenceResult);
      } else {
        _context.addInitializer(initializer, this, inferenceResult: null);
      }
    }
    if (body == null && !_context.isExternalConstructor) {
      /// >If a generative constructor c is not a redirecting constructor
      /// >and no body is provided, then c implicitly has an empty body {}.
      /// We use an empty statement instead.
      function.body = new EmptyStatement()..parent = function;
    } else if (body != null && _context.isMixinClass && !_context.isFactory) {
      // Report an error if a mixin class has a non-factory constructor with a
      // body.
      buildProblem(
          fasta.templateIllegalMixinDueToConstructors
              .withArguments(_context.className),
          _context.memberCharOffset,
          noLength);
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
    if (libraryFeatures.namedArgumentsAnywhere.isEnabled) {
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
          if (!libraryFeatures.namedArgumentsAnywhere.isEnabled) {
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
      if (libraryFeatures.namedArgumentsAnywhere.isEnabled) {
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
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    debugEvent("ParenthesizedCondition");
    if (case_ != null) {
      // ignore: unused_local_variable
      Expression? guard;
      Scope? scope;
      if (when != null) {
        assert(checkState(token, [
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Generator,
            ValueKinds.ProblemBuilder,
          ]),
          ValueKinds.Scope,
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Pattern,
          ]),
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Generator,
            ValueKinds.ProblemBuilder,
          ]),
        ]));
        guard = popForValue();
        scope = pop() as Scope;
      }
      assert(checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Pattern,
        ]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.ProblemBuilder,
        ]),
      ]));
      reportIfNotEnabled(
          libraryFeatures.patterns, case_.charOffset, case_.charCount);
      Pattern pattern = toPattern(pop());
      Expression expression = popForValue();
      if (scope != null) {
        push(scope);
      }
      push(new Condition(expression,
          forest.createPatternGuard(expression.fileOffset, pattern, guard)));
    } else {
      assert(checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.ProblemBuilder,
        ]),
      ]));
      push(new Condition(popForValue()));
    }
    assert(checkState(token, [
      ValueKinds.Condition,
    ]));
  }

  @override
  void endParenthesizedExpression(Token token) {
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
  void handleParenthesizedPattern(Token token) {
    debugEvent("ParenthesizedPattern");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ])
    ]));
    // TODO(johnniwinther): Do we need a ParenthesizedPattern ?
    reportIfNotEnabled(
        libraryFeatures.patterns, token.charOffset, token.charCount);

    Object? value = pop();
    if (value is Pattern) {
      push(value);
    } else {
      push(toValue(value));
    }
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
          buildDartTypeArguments(typeArguments, TypeUse.invocationTypeArgument,
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

    // Case heads can be preceded by labels. The scope that we need to exit lies
    // under the labels on the stack.
    List<Label>? labels;
    Object? value;
    do {
      assert(checkState(caseKeyword, [
        unionOfKinds([ValueKinds.Label, ValueKinds.Scope])
      ]));
      value = pop();
      if (value is Label) {
        (labels ??= <Label>[]).add(value);
      }
    } while (value is! Scope);
    push(value);

    // Scope of the preceding case head or a sentinel if it's the first head.
    exitLocalScope(expectedScopeKinds: const [ScopeKind.caseHead]);

    // Return labels back on the stack.
    if (labels != null) {
      for (int i = labels.length - 1; i >= 0; i--) {
        push(labels[i]);
      }
    }

    createAndEnterLocalScope(debugName: "case-head", kind: ScopeKind.caseHead);
    super.push(constantContext);
    if (!libraryFeatures.patterns.isEnabled) {
      constantContext = ConstantContext.inferred;
    }
    assert(checkState(
        caseKeyword, [ValueKinds.ConstantContext, ValueKinds.Scope]));
  }

  @override
  void endCaseExpression(Token caseKeyword, Token? when, Token colon) {
    debugEvent("endCaseExpression");
    assert(checkState(colon, [
      if (when != null)
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.ProblemBuilder,
        ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      ValueKinds.ConstantContext,
      ValueKinds.Scope,
    ]));

    Expression? guard;
    if (when != null) {
      guard = popForValue();
    }
    Object? value = pop();
    constantContext = pop() as ConstantContext;
    Scope headScope = pop() as Scope;
    assert(
        headScope.classNameOrDebugName == "switch block",
        "Expected to have scope 'switch block', "
        "but got '${headScope.classNameOrDebugName}'.");
    if (value is Pattern) {
      super.push(new ExpressionOrPatternGuardCase.patternGuard(
          caseKeyword.charOffset,
          forest.createPatternGuard(caseKeyword.charOffset, value, guard)));
    } else if (guard != null) {
      super.push(new ExpressionOrPatternGuardCase.patternGuard(
          caseKeyword.charOffset,
          forest.createPatternGuard(
              caseKeyword.charOffset, toPattern(value), guard)));
    } else {
      Expression expression = toValue(value);
      super.push(new ExpressionOrPatternGuardCase.expression(
          caseKeyword.charOffset, expression));
    }
    push(headScope);
    assert(checkState(
        colon, [ValueKinds.Scope, ValueKinds.ExpressionOrPatternGuardCase]));
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

  @override
  void beginPattern(Token token) {
    debugEvent("Pattern");
    if (token.lexeme == "||") {
      createAndEnterLocalScope(
          debugName: "rhs of a binary-or pattern",
          kind: ScopeKind.orPatternRight);
    } else {
      createAndEnterLocalScope(debugName: "pattern", kind: ScopeKind.pattern);
    }
  }

  @override
  void endPattern(Token token) {
    debugEvent("Pattern");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      ValueKinds.Scope,
    ]));
    Object pattern = pop()!;
    ScopeKind scopeKind = scope.kind;

    exitLocalScope(expectedScopeKinds: const [
      ScopeKind.pattern,
      ScopeKind.orPatternRight
    ]);

    // Bring the variables into the enclosing pattern scope, unless that was
    // the scope of the RHS of a binary-or pattern. In the latter case, the
    // joint variables will be declared in the enclosing scope instead later in
    // the process.
    //
    // Here we only handle the visibility of the pattern declared variables
    // within the pattern itself, so we declare the pattern variables in the
    // enclosing scope only if that enclosing scope is a pattern scope as well,
    // that is, if its kind is [ScopeKind.pattern] or
    // [ScopeKind.orPatternRight].
    bool enclosingScopeIsPatternScope = scope.kind == ScopeKind.pattern ||
        scope.kind == ScopeKind.orPatternRight;
    if (scopeKind != ScopeKind.orPatternRight && enclosingScopeIsPatternScope) {
      if (pattern is Pattern) {
        for (VariableDeclaration variable in pattern.declaredVariables) {
          declareVariable(variable, scope);
        }
      }
    }

    push(pattern);
  }

  @override
  void beginBinaryPattern(Token token) {
    debugEvent("BinaryPattern");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      ValueKinds.Scope,
    ]));

    // In case of the binary-or pattern, its LHS and RHS should contain
    // declarations of the variables with matching names, and we need to put
    // them into separate scopes to avoid the naming conflict. For that, we're
    // exiting the scope for the LHS, and the scope for the RHS will be created
    // when the RHS will be parsed. Additionally, since it's the first time
    // we're realizing that it's the binary-or pattern, we need to create the
    // enclosing scope for its joint variables as well.
    if (token.lexeme == "||") {
      Object lhsPattern = pop()!;

      // Exit the scope of the LHS.
      exitLocalScope(expectedScopeKinds: const [ScopeKind.pattern]);

      createAndEnterLocalScope(
          debugName: "joint variables of binary-or patterns",
          kind: ScopeKind.pattern);
      push(lhsPattern);
    }
  }

  @override
  void endBinaryPattern(Token token) {
    debugEvent("BinaryPattern");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ])
    ]));
    reportIfNotEnabled(
        libraryFeatures.patterns, token.charOffset, token.charCount);
    Pattern right = toPattern(pop());
    Pattern left = toPattern(pop());

    String operator = token.lexeme;
    switch (operator) {
      case '&&':
        push(forest.createAndPattern(token.charOffset, left, right));
        break;
      case '||':
        Map<String, VariableDeclaration> leftVariablesByName = {
          for (VariableDeclaration leftVariable in left.declaredVariables)
            leftVariable.name!: leftVariable
        };
        for (VariableDeclaration rightVariable in right.declaredVariables) {
          if (!leftVariablesByName.containsKey(rightVariable.name)) {
            addProblem(
                fasta.templateMissingVariablePattern
                    .withArguments(rightVariable.name!),
                left.fileOffset,
                noLength);
          }
        }
        Map<String, VariableDeclaration> rightVariablesByName = {
          for (VariableDeclaration rightVariable in right.declaredVariables)
            rightVariable.name!: rightVariable
        };
        for (VariableDeclaration leftVariable in left.declaredVariables) {
          if (!rightVariablesByName.containsKey(leftVariable.name)) {
            addProblem(
                fasta.templateMissingVariablePattern
                    .withArguments(leftVariable.name!),
                right.fileOffset,
                noLength);
          }
        }
        List<VariableDeclaration> jointVariables = [
          for (VariableDeclaration leftVariable in left.declaredVariables)
            forest.createVariableDeclaration(
                leftVariable.fileOffset, leftVariable.name!)
        ];
        for (VariableDeclaration variable in jointVariables) {
          declareVariable(variable, scope);
          typeInferrer.assignedVariables.declare(variable);
        }
        push(forest.createOrPattern(token.charOffset, left, right,
            orPatternJointVariables: jointVariables));
        break;
      default:
        internalProblem(
            fasta.templateInternalProblemUnhandled
                .withArguments(operator, 'endBinaryPattern'),
            token.charOffset,
            uri);
    }
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

  @override
  Expression buildUnresolvedError(String name, int charOffset,
      {Member? candidate,
      bool isSuper = false,
      required UnresolvedKind kind,
      bool isStatic = false,
      Arguments? arguments,
      Expression? rhs,
      LocatedMessage? message,
      int? length}) {
    // TODO(johnniwinther): Use [arguments] and [rhs] to create an unresolved
    // access expression to include in the invalid expression.
    if (length == null) {
      length = name.length;
      int periodIndex = name.lastIndexOf(".");
      if (periodIndex != -1) {
        length -= periodIndex + 1;
      }
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
      {bool isSuper = false,
      bool reportWarning = true,
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
      {bool isSuper = false,
      bool reportWarning = true,
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
      {bool isSuper = false,
      bool reportWarning = true,
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
      {bool isSuper = false,
      bool reportWarning = true,
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

  Message warnUnresolvedConstructor(Name name, {bool isSuper = false}) {
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
  Member? lookupSuperMember(Name name, {bool isSetter = false}) {
    return _context.lookupSuperMember(hierarchy, name, isSetter: isSetter);
  }

  @override
  Constructor? lookupSuperConstructor(Name name) {
    return _context.lookupSuperConstructor(name);
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
      {bool forNullGuardedAccess = false}) {
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

  @override
  bool isDeclaredInEnclosingCase(VariableDeclaration variable) {
    return declaredInCurrentGuard?.contains(variable) ?? false;
  }

  bool isGuardScope(Scope scope) =>
      scope.kind == ScopeKind.caseHead || scope.kind == ScopeKind.ifCaseHead;

  /// Look up [name] in [scope] using [token] as location information (both to
  /// report problems and as the file offset in the generated kernel code).
  /// [isQualified] should be true if [name] is a qualified access (which
  /// implies that it shouldn't be turned into a [ThisPropertyAccessGenerator]
  /// if the name doesn't resolve in the scope).
  @override
  Expression_Generator_Builder scopeLookup(
      Scope scope, String name, Token token,
      {bool isQualified = false, PrefixBuilder? prefix}) {
    int charOffset = offsetForToken(token);
    if (token.isSynthetic) {
      return new ParserErrorGenerator(this, token, fasta.messageSyntheticToken);
    }
    Builder? declaration = scope.lookup(name, charOffset, uri);
    if (declaration == null && prefix == null && _context.isPatchClass) {
      // The scope of a patched method includes the origin class.
      declaration = _context.lookupStaticOriginMember(name, charOffset, uri);
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
        if (thisVariable != null) {
          // If we are in an extension instance member we interpret this as an
          // implicit access on the 'this' parameter.
          return PropertyAccessGenerator.make(this, token,
              createVariableGet(thisVariable!, charOffset), n, false);
        } else {
          // This is an implicit access on 'this'.
          return new ThisPropertyAccessGenerator(this, token, n,
              thisVariable: thisVariable);
        }
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
          !_context.isConstructor &&
          !libraryFeatures.constFunctions.isEnabled) {
        return new IncompleteErrorGenerator(
            this, token, fasta.messageNotAConstantExpression);
      }
      VariableDeclaration variable = variableBuilder.variable!;
      if (scope.kind == ScopeKind.forStatement &&
          variable.isAssignable &&
          variable.isLate &&
          variable.isFinal) {
        return new ForInLateFinalVariableUseGenerator(this, token, variable);
      } else if (!variableBuilder.isAssignable ||
          (variable.isFinal && scope.kind == ScopeKind.forStatement)) {
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
    } else if (declaration.isClassInstanceMember ||
        declaration.isInlineClassInstanceMember) {
      if (constantContext != ConstantContext.none &&
          !inInitializerLeftHandSide &&
          // TODO(ahe): This is a hack because Fasta sets up the scope
          // "this.field" parameters according to old semantics. Under the new
          // semantics, such parameters introduces a new parameter with that
          // name that should be resolved here.
          !_context.isConstructor) {
        addProblem(
            fasta.messageNotAConstantExpression, charOffset, token.length);
      }
      Name n = new Name(name, libraryBuilder.nameOrigin);
      return new ThisPropertyAccessGenerator(this, token, n,
          thisVariable: inConstructorInitializer ? null : thisVariable);
    } else if (declaration.isExtensionInstanceMember) {
      ExtensionBuilder extensionBuilder =
          declaration.parent as ExtensionBuilder;
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
          thisVariable!,
          thisTypeParameters,
          getterBuilder,
          setterBuilder);
    } else if (declaration.isRegularMethod) {
      assert(declaration.isStatic || declaration.isTopLevel);
      MemberBuilder memberBuilder = declaration as MemberBuilder;
      return new StaticAccessGenerator(
          this, token, name, memberBuilder.parent, memberBuilder.member, null);
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
  void beginPatternGuard(Token when) {
    debugEvent("PatternGuard");
    assert(checkState(when, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ])
    ]));

    Pattern pattern = toPattern(peek());
    createAndEnterLocalScope(
        debugName: "if-case-head", kind: ScopeKind.ifCaseHead);
    for (VariableDeclaration variable in pattern.declaredVariables) {
      declareVariable(variable, scope);
    }
  }

  @override
  void endPatternGuard(Token token) {
    debugEvent("PatternGuard");
  }

  @override
  void beginThenStatement(Token token) {
    debugEvent("beginThenStatement");
    assert(checkState(token, [ValueKinds.Condition]));
    // This is matched by the call to [deferNode] in
    // [endThenStatement].
    typeInferrer.assignedVariables.beginNode();
    Condition condition = pop() as Condition;
    PatternGuard? patternGuard = condition.patternGuard;
    if (patternGuard != null && patternGuard.guard != null) {
      assert(checkState(token, [ValueKinds.Scope]));
      Scope thenScope = scope.createNestedScope(
          debugName: "then body", kind: ScopeKind.statementLocalScope);
      exitLocalScope(expectedScopeKinds: const [ScopeKind.ifCaseHead]);
      push(condition);
      enterLocalScope(thenScope);
    } else {
      push(condition);
      // There is no guard, so the scope for "then" isn't entered yet. We need
      // to enter the scope and declare all of the pattern variables.
      if (patternGuard != null) {
        createAndEnterLocalScope(
            debugName: "if-case-head", kind: ScopeKind.ifCaseHead);
        for (VariableDeclaration variable
            in patternGuard.pattern.declaredVariables) {
          declareVariable(variable, scope);
        }
        Scope thenScope = scope.createNestedScope(
            debugName: "then body", kind: ScopeKind.statementLocalScope);
        exitLocalScope();
        enterLocalScope(thenScope);
      } else {
        createAndEnterLocalScope(
            debugName: "then body", kind: ScopeKind.statementLocalScope);
      }
    }
  }

  @override
  void endThenStatement(Token token) {
    debugEvent("endThenStatement");
    Object? body = pop();
    exitLocalScope();
    push(body);
    // This is matched by the call to [beginNode] in
    // [beginThenStatement] and by the call to [storeInfo] in
    // [endIfStatement].
    push(typeInferrer.assignedVariables.deferNode());
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken) {
    assert(checkState(ifToken, [
      /* else = */ if (elseToken != null) ValueKinds.Statement,
      ValueKinds.AssignedVariablesNodeInfo,
      /* then = */ ValueKinds.Statement,
      /* condition = */ ValueKinds.Condition,
    ]));
    Statement? elsePart = popStatementIfNotNull(elseToken);
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
    Statement thenPart = popStatement();
    Condition condition = pop() as Condition;
    PatternGuard? patternGuard = condition.patternGuard;
    Expression expression = condition.expression;
    Statement node;
    if (patternGuard != null) {
      node = forest.createIfCaseStatement(
          ifToken.charOffset, expression, patternGuard, thenPart, elsePart);
    } else {
      node = forest.createIfStatement(
          offsetForToken(ifToken), expression, thenPart, elsePart);
    }
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
    AssignedVariablesNodeInfo? assignedVariablesInfo;
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
    VariableDeclaration variable = new VariableDeclarationImpl(identifier.name,
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
    push(variable);
  }

  @override
  void beginFieldInitializer(Token token) {
    inFieldInitializer = true;
    constantContext = _context.constantContext;
    inLateFieldInitializer = _context.isLateField;
    if (_context.isAbstractField) {
      addProblem(
          fasta.messageAbstractFieldInitializer, token.charOffset, noLength);
    } else if (_context.isExternalField) {
      addProblem(
          fasta.messageExternalFieldInitializer, token.charOffset, noLength);
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
    constantContext = _context.constantContext;
    if (constantContext == ConstantContext.inferred) {
      // Creating a null value to prevent the Dart VM from crashing.
      push(forest.createNullLiteral(offsetForToken(token)));
    } else {
      push(NullValues.FieldInitializer);
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
    TypeBuilder? unresolvedType = pop(NullValues.TypeBuilder) as TypeBuilder?;
    DartType? type = unresolvedType != null
        ? buildDartType(unresolvedType, TypeUse.variableType,
            allowPotentiallyConstantType: false)
        : null;
    int modifiers = (lateToken != null ? lateMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    _enterLocalState(inLateLocalInitializer: lateToken != null);
    super.push(currentLocalVariableModifiers);
    super.push(currentLocalVariableType ?? NullValues.Type);
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
      currentLocalVariableType = pop(NullValues.Type) as DartType?;
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
      currentLocalVariableType = pop(NullValues.Type) as DartType?;
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
  Link<AssignedVariablesNodeInfo> tryStatementInfoStack =
      const Link<AssignedVariablesNodeInfo>();

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
    debugEvent("beginBlock");
    createAndEnterLocalScope(
        debugName: "block", kind: ScopeKind.statementLocalScope);
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
    } else if (variableOrExpression is PatternVariableDeclaration) {
      return <VariableDeclaration>[];
    } else if (variableOrExpression is ParserRecovery) {
      return <VariableDeclaration>[];
    } else if (variableOrExpression == null) {
      return <VariableDeclaration>[];
    }
    return null;
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement");
    push(NullValues.Expression);
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
  void handleForInitializerPatternVariableAssignment(
      Token keyword, Token equals) {
    debugEvent("handleForInitializerPatternVariableAssignment");
    assert(checkState(keyword, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
    ]));

    Object expression = pop() as Object;
    Object pattern = pop() as Object;

    if (pattern is Pattern) {
      pop(); // Metadata.
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, scope);
      }
      Scope forScope = scope.createNestedScope(
          debugName: "pattern-for internal variables",
          kind: ScopeKind.forStatement);
      exitLocalScope();
      enterLocalScope(forScope);

      bool isFinal = keyword.lexeme == "final";

      // We use intermediate variables to transfer values between the pattern
      // variables and the replacement internal variables. It allows to avoid
      // using the variables with the same name within the same block.
      List<VariableDeclaration> intermediateVariables = [];
      List<VariableDeclaration> internalVariables = [];
      for (VariableDeclaration variable in pattern.declaredVariables) {
        variable.isFinal |= isFinal;

        VariableDeclaration intermediateVariable =
            forest.createVariableDeclarationForValue(
                forest.createVariableGet(variable.fileOffset, variable));
        intermediateVariables.add(intermediateVariable);

        VariableDeclaration internalVariable = forest.createVariableDeclaration(
            variable.fileOffset, variable.name!,
            initializer: forest.createVariableGet(
                variable.fileOffset, intermediateVariable),
            isFinal: isFinal);
        internalVariables.add(internalVariable);

        declareVariable(internalVariable, scope);
        typeInferrer.assignedVariables.declare(internalVariable);
      }
      push(intermediateVariables);
      push(internalVariables);
      push(forest.createPatternVariableDeclaration(
          offsetForToken(keyword), pattern, toValue(expression),
          isFinal: isFinal));
    }

    // This is matched by the call to [deferNode] in [endForStatement].
    typeInferrer.assignedVariables.beginNode();
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
    assert(checkState(token, <ValueKind>[
      /* entry = */ unionOfKinds(<ValueKind>[
        ValueKinds.Generator,
        ValueKinds.ExpressionOrNull,
        ValueKinds.Statement,
        ValueKinds.ParserRecovery,
        ValueKinds.MapLiteralEntry,
      ]),
      /* update expression count = */ ValueKinds.Integer,
      /* left separator = */ ValueKinds.Token,
      /* left parenthesis = */ ValueKinds.Token,
      /* for keyword = */ ValueKinds.Token,
    ]));
    debugEvent("ForControlFlow");
    Object? entry = pop();
    int updateExpressionCount = pop() as int;
    pop(); // left separator
    pop(); // left parenthesis
    Token forToken = pop() as Token;

    assert(checkState(token, <ValueKind>[
      /* updates = */ ...repeatedKind(
          unionOfKinds(
              <ValueKind>[ValueKinds.Expression, ValueKinds.Generator]),
          updateExpressionCount),
      /* condition = */ ValueKinds.Statement,
    ]));
    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement(); // condition

    if (constantContext != ConstantContext.none) {
      pop(); // Pop variable or expression.
      exitLocalScope();
      typeInferrer.assignedVariables.discardNode();

      push(buildProblem(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(forToken),
          forToken.charOffset,
          forToken.charCount));
      return;
    }

    // This is matched by the call to [beginNode] in
    // [handleForInitializerEmptyStatement],
    // [handleForInitializerPatternVariableAssignment],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.popNode();

    Object? variableOrExpression = pop();
    List<VariableDeclaration>? variables;
    List<VariableDeclaration>? intermediateVariables;
    if (variableOrExpression is PatternVariableDeclaration) {
      variables = pop() as List<VariableDeclaration>; // Internal variables.
      intermediateVariables = pop() as List<VariableDeclaration>;
    } else {
      variables = _buildForLoopVariableDeclarations(variableOrExpression)!;
    }
    exitLocalScope();

    typeInferrer.assignedVariables.pushNode(assignedVariablesNodeInfo);
    Expression? condition;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is EmptyStatement);
    }
    if (entry is MapLiteralEntry) {
      ForMapEntry result;
      if (variableOrExpression is PatternVariableDeclaration) {
        result = forest.createPatternForMapEntry(offsetForToken(forToken),
            patternVariableDeclaration: variableOrExpression,
            intermediateVariables: intermediateVariables!,
            variables: variables,
            condition: condition,
            updates: updates,
            body: entry);
      } else {
        result = forest.createForMapEntry(
            offsetForToken(forToken), variables, condition, updates, entry);
      }
      typeInferrer.assignedVariables.endNode(result);
      push(result);
    } else {
      ForElement result;
      if (variableOrExpression is PatternVariableDeclaration) {
        result = forest.createPatternForElement(offsetForToken(forToken),
            patternVariableDeclaration: variableOrExpression,
            intermediateVariables: intermediateVariables!,
            variables: variables,
            condition: condition,
            updates: updates,
            body: toValue(entry));
      } else {
        result = forest.createForElement(offsetForToken(forToken), variables,
            condition, updates, toValue(entry));
      }
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
      /* expressions */ ...repeatedKind(
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
    // [handleForInitializerPatternVariableAssignment],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.deferNode();

    Object? variableOrExpression = pop();
    List<VariableDeclaration>? variables;
    List<VariableDeclaration>? intermediateVariables;
    if (variableOrExpression is PatternVariableDeclaration) {
      variables = pop() as List<VariableDeclaration>;
      intermediateVariables = pop() as List<VariableDeclaration>;
    } else {
      variables = _buildForLoopVariableDeclarations(variableOrExpression);
    }
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
    if (variableOrExpression is PatternVariableDeclaration) {
      result = forest.createBlock(result.fileOffset, result.fileOffset,
          <Statement>[variableOrExpression, ...intermediateVariables!, result]);
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
    assert(checkState(leftBracket, [
      ...repeatedKind(
          unionOfKinds([
            ValueKinds.Generator,
            ValueKinds.Expression,
            ValueKinds.ProblemBuilder,
          ]),
          count),
      ValueKinds.TypeArgumentsOrNull,
    ]));

    if (constantContext == ConstantContext.required && constKeyword == null) {
      addProblem(fasta.messageMissingExplicitConst, offsetForToken(leftBracket),
          noLength);
    }

    List<Expression> expressions = popListForValue(count);

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
        typeArgument = buildDartType(
            typeArguments.single, TypeUse.literalTypeArgument,
            allowPotentiallyConstantType: false);
        typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
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
    push(node);
  }

  @override
  void handleListPattern(int count, Token leftBracket, Token rightBracket) {
    debugEvent("ListPattern");
    assert(checkState(leftBracket, [
      ...repeatedKind(
          unionOfKinds([
            ValueKinds.Generator,
            ValueKinds.Expression,
            ValueKinds.ProblemBuilder,
            ValueKinds.Pattern,
          ]),
          count),
      ValueKinds.TypeArgumentsOrNull,
    ]));

    reportIfNotEnabled(libraryFeatures.patterns, leftBracket.charOffset,
        leftBracket.charCount);

    List<Pattern> patterns =
        new List<Pattern>.filled(count, dummyPattern, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      patterns[i] = toPattern(pop());
    }
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    DartType? typeArgument;
    if (typeArguments != null) {
      if (typeArguments.length > 1) {
        addProblem(
            fasta.messageListPatternTooManyTypeArguments,
            offsetForToken(leftBracket),
            lengthOfSpan(leftBracket, leftBracket.endGroup));
        typeArgument = const InvalidType();
      } else {
        typeArgument = buildDartType(
            typeArguments.single, TypeUse.literalTypeArgument,
            allowPotentiallyConstantType: false);
        typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
      }
    }

    push(forest.createListPattern(
        leftBracket.charOffset, typeArgument, patterns));
  }

  @override
  void endRecordLiteral(Token token, int count, Token? constKeyword) {
    debugEvent("RecordLiteral");
    assert(checkState(
        token,
        repeatedKind(
            unionOfKinds([
              ValueKinds.Generator,
              ValueKinds.Expression,
              ValueKinds.ProblemBuilder,
              ValueKinds.NamedExpression,
              ValueKinds.ParserRecovery,
            ]),
            count)));

    reportIfNotEnabled(
        libraryFeatures.records, token.charOffset, token.charCount);

    // Pop all elements. This will put them in evaluation order.
    List<Object?>? elements =
        const FixedNullableList<Object>().pop(stack, count);

    List<Object> originalElementOrder = [];
    List<Expression> positional = [];
    List<NamedExpression> named = [];
    Map<String, NamedExpression>? namedElements;
    const List<String> forbiddenObjectMemberNames = [
      "noSuchMethod",
      "toString",
      "hashCode",
      "runtimeType"
    ];
    if (elements != null) {
      for (Object? element in elements) {
        if (element is NamedExpression) {
          if (forbiddenObjectMemberNames.contains(element.name)) {
            libraryBuilder.addProblem(
                fasta.messageObjectMemberNameUsedForRecordField,
                element.fileOffset,
                element.name.length,
                uri);
          }
          if (element.name.startsWith("_")) {
            libraryBuilder.addProblem(fasta.messageRecordFieldsCantBePrivate,
                element.fileOffset, element.name.length, uri);
          }
          namedElements ??= {};
          NamedExpression? existingExpression = namedElements[element.name];
          if (existingExpression != null) {
            existingExpression.value = buildProblem(
                templateDuplicatedRecordLiteralFieldName
                    .withArguments(element.name),
                element.fileOffset,
                element.name.length,
                context: [
                  templateDuplicatedRecordLiteralFieldNameContext
                      .withArguments(element.name)
                      .withLocation(uri, existingExpression.fileOffset,
                          element.name.length)
                ])
              ..parent = existingExpression;
          } else {
            originalElementOrder.add(element);
            namedElements[element.name] = element;
            named.add(element);
          }
        } else {
          Expression expression = toValue(element);
          positional.add(expression);
          originalElementOrder.add(expression);
        }
      }
      if (namedElements != null) {
        for (NamedExpression element in namedElements.values) {
          if (tryParseRecordPositionalGetterName(
                  element.name, positional.length) !=
              null) {
            libraryBuilder.addProblem(
                messageNamedFieldClashesWithPositionalFieldInRecord,
                element.fileOffset,
                element.name.length,
                uri);
          }
        }
      }
    }

    push(new InternalRecordLiteral(
        positional, named, namedElements, originalElementOrder,
        isConst:
            constKeyword != null || constantContext == ConstantContext.inferred,
        offset: token.offset));
  }

  @override
  void handleRecordPattern(Token token, int count) {
    debugEvent("RecordPattern");
    assert(checkState(
        token,
        repeatedKind(
            unionOfKinds([
              ValueKinds.Generator,
              ValueKinds.Expression,
              ValueKinds.ProblemBuilder,
              ValueKinds.NamedExpression,
              ValueKinds.Pattern,
            ]),
            count)));

    reportIfNotEnabled(
        libraryFeatures.patterns, token.charOffset, token.charCount);

    List<Pattern> patterns = new List<Pattern>.filled(count, dummyPattern);
    for (int i = count - 1; i >= 0; i--) {
      patterns[i] = toPattern(pop());
    }
    push(forest.createRecordPattern(token.charOffset, patterns));
  }

  void buildLiteralSet(List<TypeBuilder>? typeArguments, Token? constKeyword,
      Token leftBrace, List<dynamic>? setOrMapEntries) {
    DartType typeArgument;
    if (typeArguments != null) {
      typeArgument = buildDartType(
          typeArguments.single, TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false);
      typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass,
          isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
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
    assert(checkState(leftBrace, [
      ...repeatedKind(
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Generator,
            ValueKinds.ProblemBuilder,
            ValueKinds.MapLiteralEntry,
          ]),
          count),
      ValueKinds.TypeArgumentsOrNull
    ]));

    if (constantContext == ConstantContext.required && constKeyword == null) {
      addProblem(fasta.messageMissingExplicitConst, offsetForToken(leftBrace),
          noLength);
    }

    List<dynamic> setOrMapEntries =
        new List<dynamic>.filled(count, null, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      Object? elem = pop();
      if (elem is MapLiteralEntry) {
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
  void handleMapPatternEntry(Token colon, Token endToken) {
    debugEvent('MapPatternEntry');
    assert(checkState(colon, [
      /* value */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      /* key */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ])
    ]));
    Pattern value = toPattern(pop());
    Expression key = toValue(pop());
    push(forest.createMapPatternEntry(colon.charOffset, key, value));
  }

  @override
  void handleMapPattern(int count, Token leftBrace, Token rightBrace) {
    debugEvent('MapPattern');
    assert(checkState(leftBrace, [
      ...repeatedKind(
          unionOfKinds([ValueKinds.MapPatternEntry, ValueKinds.Pattern]),
          count),
      ValueKinds.TypeArgumentsOrNull,
    ]));

    reportIfNotEnabled(
        libraryFeatures.patterns, leftBrace.charOffset, leftBrace.charCount);
    List<MapPatternEntry> entries = <MapPatternEntry>[];
    for (int i = 0; i < count; i++) {
      Object? entry = pop();
      if (entry is MapPatternEntry) {
        entries.add(entry);
      } else {
        entry as RestPattern;
        entries.add(forest.createMapPatternRestEntry(entry.fileOffset));
      }
    }

    for (int i = 0, j = entries.length - 1; i < j; i++, j--) {
      MapPatternEntry entry = entries[i];
      entries[i] = entries[j];
      entries[j] = entry;
    }

    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    DartType? keyType;
    DartType? valueType;
    if (typeArguments != null) {
      if (typeArguments.length != 2) {
        keyType = const InvalidType();
        valueType = const InvalidType();
        addProblem(fasta.messageMapPatternTypeArgumentMismatch,
            leftBrace.charOffset, noLength);
      } else {
        keyType = buildDartType(typeArguments[0], TypeUse.literalTypeArgument,
            allowPotentiallyConstantType: false);
        valueType = buildDartType(typeArguments[1], TypeUse.literalTypeArgument,
            allowPotentiallyConstantType: false);
        keyType = instantiateToBounds(keyType, coreTypes.objectClass,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
        valueType = instantiateToBounds(valueType, coreTypes.objectClass,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
      }
    }

    push(forest.createMapPattern(
        leftBrace.charOffset, keyType, valueType, entries));
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
        keyType = buildDartType(typeArguments[0], TypeUse.literalTypeArgument,
            allowPotentiallyConstantType: false);
        valueType = buildDartType(typeArguments[1], TypeUse.literalTypeArgument,
            allowPotentiallyConstantType: false);
        keyType = instantiateToBounds(keyType, coreTypes.objectClass,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
        valueType = instantiateToBounds(valueType, coreTypes.objectClass,
            isNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
      }
    } else {
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
    assert(checkState(beginToken, [
      ValueKinds.TypeArgumentsOrNull,
      unionOfKinds([
        ValueKinds.QualifiedName,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));

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
      if (prefix is ParserErrorGenerator) {
        // An error have already been issued.
        push(prefix.buildTypeWithResolvedArgumentsDoNotAddProblem(
            libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable)));
        return;
      } else if (prefix is Generator) {
        name = prefix.qualifiedLookup(suffix);
      } else {
        String name = getNodeName(prefix);
        String displayName = debugName(name, suffix.lexeme);
        int offset = offsetForToken(beginToken);
        Message message = fasta.templateNotAType.withArguments(displayName);
        libraryBuilder.addProblem(
            message, offset, lengthOfSpan(beginToken, suffix), uri);
        push(new NamedTypeBuilder.forInvalidType(
            name,
            libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable),
            message.withLocation(
                uri, offset, lengthOfSpan(beginToken, suffix))));
        return;
      }
    }
    TypeBuilder result;
    if (name is Generator) {
      bool allowPotentiallyConstantType;
      if (libraryBuilder.isNonNullableByDefault) {
        if (libraryFeatures.constructorTearoffs.isEnabled) {
          allowPotentiallyConstantType = true;
        } else {
          allowPotentiallyConstantType = inIsOrAsOperatorType;
        }
      } else {
        allowPotentiallyConstantType = false;
      }
      result = name.buildTypeWithResolvedArguments(
          libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable), arguments,
          allowPotentiallyConstantType: allowPotentiallyConstantType,
          performTypeCanonicalization: constantContext != ConstantContext.none);
    } else if (name is ProblemBuilder) {
      // TODO(ahe): Arguments could be passed here.
      libraryBuilder.addProblem(
          name.message, name.charOffset, name.name.length, name.fileUri);
      result = new NamedTypeBuilder.forInvalidType(
          name.name,
          libraryBuilder.nullableBuilderIfTrue(isMarkedAsNullable),
          name.message
              .withLocation(name.fileUri, name.charOffset, name.name.length));
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
    enterLocalScope(scope.createNestedScope(
        debugName: "function-type scope",
        isModifiable: true,
        kind: ScopeKind.typeParameters));
    if (typeVariables != null) {
      for (TypeVariableBuilder builder in typeVariables) {
        String name = builder.name;
        TypeVariableBuilder? existing = scope.lookupLocalMember(name,
            setter: false) as TypeVariableBuilder?;
        if (existing == null) {
          scope.addLocalMember(name, builder, setter: false);
        } else {
          reportDuplicatedDeclaration(existing, name, builder.charOffset);
        }
      }
    }
  }

  @override
  void endRecordType(
      Token leftBracket, Token? questionMark, int count, bool hasNamedFields) {
    debugEvent("RecordType");
    assert(checkState(leftBracket, [
      if (hasNamedFields) ValueKinds.RecordTypeFieldBuilderListOrNull,
      ...repeatedKind(ValueKinds.RecordTypeFieldBuilder,
          hasNamedFields ? count - 1 : count),
    ]));

    if (!libraryFeatures.records.isEnabled) {
      addProblem(
          templateExperimentNotEnabledOffByDefault
              .withArguments(ExperimentalFlag.records.name),
          leftBracket.offset,
          noLength);
    }

    if (!libraryBuilder.isNonNullableByDefault) {
      reportErrorIfNullableType(questionMark);
    }

    List<RecordTypeFieldBuilder>? namedFields;
    if (hasNamedFields) {
      namedFields =
          pop(NullValues.RecordTypeFieldList) as List<RecordTypeFieldBuilder>?;
    }
    List<RecordTypeFieldBuilder>? positionalFields =
        const FixedNullableList<RecordTypeFieldBuilder>().popNonNullable(stack,
            hasNamedFields ? count - 1 : count, dummyRecordTypeFieldBuilder);

    push(new RecordTypeBuilder(
      positionalFields,
      namedFields,
      questionMark != null
          ? libraryBuilder.nullableBuilder
          : libraryBuilder.nonNullableBuilder,
      uri,
      leftBracket.charOffset,
    ));
  }

  @override
  void endRecordTypeEntry() {
    debugEvent("RecordTypeEntry");
    assert(checkState(null, [
      unionOfKinds([
        ValueKinds.IdentifierOrNull,
        ValueKinds.ParserRecovery,
      ]),
      unionOfKinds([
        ValueKinds.TypeBuilder,
        ValueKinds.ParserRecovery,
      ]),
      ValueKinds.AnnotationListOrNull,
    ]));

    Object? name = pop();
    Object? type = pop();
    // TODO(johnniwinther): How should we handle annotations?
    pop(NullValues.Metadata); // Annotations.
    push(new RecordTypeFieldBuilder(
        [],
        type is ParserRecovery
            ? new InvalidTypeBuilder(uri, type.charOffset)
            : type as TypeBuilder,
        name is Identifier ? name.name : null,
        name is Identifier ? name.charOffset : TreeNode.noOffset));
  }

  @override
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    debugEvent("RecordTypeNamedFields");
    assert(checkState(leftBracket, [
      ...repeatedKind(ValueKinds.RecordTypeFieldBuilder, count),
    ]));
    List<RecordTypeFieldBuilder>? fields =
        const FixedNullableList<RecordTypeFieldBuilder>()
            .popNonNullable(stack, count, dummyRecordTypeFieldBuilder);
    push(fields ?? NullValues.RecordTypeFieldList);
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
          if (!libraryFeatures.genericMetadata.isEnabled) {
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
        returnType ?? const ImplicitTypeBuilder(),
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
    assert(checkState(operator, [
      ValueKinds.TypeBuilder,
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    DartType type = buildDartType(pop() as TypeBuilder, TypeUse.asType,
        allowPotentiallyConstantType: libraryBuilder.isNonNullableByDefault);
    Expression expression = popForValue();
    Expression asExpression = forest.createAsExpression(
        offsetForToken(operator), expression, type,
        forNonNullableByDefault: libraryBuilder.isNonNullableByDefault);
    push(asExpression);
  }

  @override
  void handleCastPattern(Token operator) {
    debugEvent('CastPattern');
    assert(checkState(operator, [
      ValueKinds.TypeBuilder,
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
    ]));
    reportIfNotEnabled(
        libraryFeatures.patterns, operator.charOffset, operator.charCount);
    DartType type = buildDartType(pop() as TypeBuilder, TypeUse.asType,
        allowPotentiallyConstantType: libraryBuilder.isNonNullableByDefault);
    Pattern operand = toPattern(pop());
    push(forest.createCastPattern(operator.charOffset, operand, type));
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
    DartType type = buildDartType(pop() as TypeBuilder, TypeUse.isType,
        allowPotentiallyConstantType: libraryBuilder.isNonNullableByDefault);
    Expression operand = popForValue();
    Expression isExpression = forest.createIsExpression(
        offsetForToken(isOperator), operand, type,
        forNonNullableByDefault: libraryBuilder.isNonNullableByDefault,
        notFileOffset: not != null ? offsetForToken(not) : null);
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
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
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
    push(varFinalOrConst ?? NullValues.Token);
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
    if (superKeyword != null) {
      if (!inConstructor) {
        handleRecoverableError(
            fasta.messageSuperParameterInitializerOutsideConstructor,
            superKeyword,
            superKeyword);
        superKeyword = null;
      }
    }
    Object? nameNode = pop();
    TypeBuilder? type = pop() as TypeBuilder?;
    Token? varOrFinalOrConst = pop(NullValues.Token) as Token?;
    if (superKeyword != null &&
        varOrFinalOrConst != null &&
        optional('var', varOrFinalOrConst)) {
      handleRecoverableError(
          fasta.templateExtraneousModifier.withArguments(varOrFinalOrConst),
          varOrFinalOrConst,
          varOrFinalOrConst);
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
      parameter = _context.getFormalParameterByName(name!);

      if (parameter == null) {
        // This happens when the list of formals (originally) contains a
        // ParserRecovery - then the popped list becomes null.
        push(new ParserRecovery(nameToken.charOffset));
        return;
      }
    } else {
      parameter = new FormalParameterBuilder(
          null,
          kind,
          modifiers,
          type ?? const ImplicitTypeBuilder(),
          name?.name ?? '',
          libraryBuilder,
          offsetForToken(nameToken),
          fileUri: uri)
        ..hasDeclaredInitializer = (initializerStart != null);
    }
    VariableDeclaration variable = parameter.build(libraryBuilder);
    Expression? initializer = name?.initializer;
    if (initializer != null) {
      if (_context.isRedirectingFactory) {
        addProblem(
            fasta.templateDefaultValueInRedirectingFactoryConstructor
                .withArguments(_context.redirectingFactoryTargetName),
            initializer.fileOffset,
            noLength);
      } else {
        if (!parameter.initializerWasInferred) {
          variable.initializer = initializer..parent = variable;
        }
      }
    } else if (kind != FormalParameterKind.requiredPositional) {
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
    // We pass `ignoreDuplicates: true` because the variable might have been
    // previously passed to `declare` in the `BodyBuilder` constructor.
    typeInferrer.assignedVariables.declare(variable, ignoreDuplicates: true);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
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
    TypeBuilder type = formals.toFunctionType(
        returnType ?? const ImplicitTypeBuilder(),
        libraryBuilder.nullableBuilderIfTrue(question != null),
        typeVariables);
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
  void handleValuedFormalParameter(
      Token equals, Token token, FormalParameterKind kind) {
    debugEvent("ValuedFormalParameter");
    Expression initializer = popForValue();
    Object? name = pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(new InitializedIdentifier(name as Identifier, initializer));
    }
    if ((kind == FormalParameterKind.optionalNamed ||
            kind == FormalParameterKind.requiredNamed) &&
        equals.lexeme == ':' &&
        libraryBuilder.languageVersion.version.major >= 3) {
      addProblem(fasta.messageObsoleteColonForDefaultValue, equals.charOffset,
          equals.charCount);
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
      enterLocalScope(formals.computeFormalParameterScope(scope, this));
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
      exceptionType = buildDartType(unresolvedExceptionType, TypeUse.catchType,
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
        exception.build(libraryBuilder).type = exceptionType;
        if (parameterCount > 1) {
          stackTrace = catchParameters.parameters![1];
          stackTrace.build(libraryBuilder).type =
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
      push(NullValues.Block);
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
    push(typeArguments ?? NullValues.TypeArguments);
    push(name);
    push(suffix ?? identifier ?? NullValues.Identifier);

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
      {Constness constness = Constness.implicit,
      TypeAliasBuilder? typeAliasBuilder,
      int charOffset = -1,
      int charLength = noLength,
      required bool isConstructorInvocation}) {
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
      return buildUnresolvedError(target.name.text, charOffset,
          arguments: arguments,
          candidate: target,
          message: argMessage,
          kind: UnresolvedKind.Method);
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
      if (isConstructorInvocation) {
        if (constantContext == ConstantContext.required &&
            constness == Constness.implicit) {
          addProblem(fasta.messageMissingExplicitConst, charOffset, charLength);
        }
        if (isConst && !procedure.isConst) {
          if (procedure.isInlineClassMember) {
            // Both generative constructors and factory constructors from
            // inline classes are encoded as procedures so we use the message
            // for non-const constructors here.
            return buildProblem(
                fasta.messageNonConstConstructor, charOffset, charLength);
          } else {
            return buildProblem(
                fasta.messageNonConstFactory, charOffset, charLength);
          }
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
      return buildUnresolvedError(target.name.text, fileOffset,
          arguments: arguments,
          candidate: target,
          message: argMessage,
          kind: UnresolvedKind.Method);
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
      /*arguments*/ unionOfKinds(
          [ValueKinds.Arguments, ValueKinds.ParserRecovery]),
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
    Object? arguments = pop();
    Identifier? nameLastIdentifier = pop(NullValues.Identifier) as Identifier?;
    Token nameLastToken = nameLastIdentifier?.token ?? nameToken;
    String name = pop() as String;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    if (inMetadata && typeArguments != null) {
      if (!libraryFeatures.genericMetadata.isEnabled) {
        handleRecoverableError(fasta.messageMetadataTypeArguments,
            nameLastToken.next!, nameLastToken.next!);
      }
    }

    Object? type = pop();

    ConstantContext savedConstantContext = pop() as ConstantContext;

    if (arguments is! Arguments) {
      push(new ParserErrorGenerator(
          this, nameToken, fasta.messageSyntheticToken));
      arguments = forest.createArguments(offset, []);
    } else if (type is Generator) {
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
      push(buildUnresolvedError(
          debugName(typeName!, name), nameToken.charOffset,
          arguments: arguments, kind: UnresolvedKind.Constructor));
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
    if (libraryFeatures.constructorTearoffs.isEnabled &&
        inImplicitCreationContext) {
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
            buildDartTypeArguments(typeArguments, TypeUse.tearOffTypeArgument,
                allowPotentiallyConstantType: true));
      }
      return forest.createMethodInvocation(invocationOffset, receiver,
          new Name(constructorName, libraryBuilder.nameOrigin), arguments);
    } else {
      if (typeArguments != null) {
        assert(forest.argumentsTypeArguments(arguments).isEmpty);
        forest.argumentsSetTypeArguments(
            arguments,
            buildDartTypeArguments(
                typeArguments, TypeUse.constructorTypeArgument,
                allowPotentiallyConstantType: false));
      }
      return buildUnresolvedError(
          constructorNameForDiagnostics(constructorName, className: className),
          invocationOffset,
          arguments: arguments,
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

            return buildUnresolvedError(errorName, nameLastToken.charOffset,
                arguments: arguments,
                message: message,
                kind: UnresolvedKind.Constructor);
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
                charLength: nameToken.length,
                isConstructorInvocation: true);
            return invocation;
          } else {
            return buildUnresolvedError(errorName, nameLastToken.charOffset,
                arguments: arguments,
                message: message,
                kind: UnresolvedKind.Constructor);
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
              dartTypeArguments.add(typeBuilder.build(
                  libraryBuilder, TypeUse.constructorTypeArgument));
            }
            assert(forest.argumentsTypeArguments(arguments).isEmpty);
            forest.argumentsSetTypeArguments(arguments, dartTypeArguments);
          }
        }
      }

      List<DartType> typeArgumentsToCheck = const <DartType>[];
      if (typeArgumentBuilders.isNotEmpty) {
        typeArgumentsToCheck = new List.filled(
            typeArgumentBuilders.length, const DynamicType(),
            growable: false);
        for (int i = 0; i < typeArgumentsToCheck.length; ++i) {
          typeArgumentsToCheck[i] = typeArgumentBuilders[i]
              .build(libraryBuilder, TypeUse.constructorTypeArgument);
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
            dartTypeArguments.add(typeBuilder.build(
                libraryBuilder, TypeUse.constructorTypeArgument));
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
                  (int i) => cls.typeVariables![i].defaultType!.build(
                      cls.libraryBuilder, TypeUse.constructorTypeArgument),
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
            buildDartTypeArguments(
                typeArguments, TypeUse.constructorTypeArgument,
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
          !(libraryFeatures.enhancedEnums.isEnabled &&
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
            typeAliasBuilder: typeAliasBuilder as TypeAliasBuilder?,
            isConstructorInvocation: true);
        return invocation;
      } else {
        errorName ??= debugName(type.name, name);
      }
    } else if (type is InlineClassBuilder) {
      MemberBuilder? b =
          type.findConstructorOrFactory(name, charOffset, uri, libraryBuilder);
      Member? target;
      if (b == null) {
        // Not found. Reported below.
      } else if (b is AmbiguousMemberBuilder) {
        message = b.message.withLocation(uri, charOffset, noLength);
      } else {
        target = b.member;
      }
      if (target != null) {
        return buildStaticInvocation(target, arguments,
            constness: constness,
            charOffset: nameToken.charOffset,
            charLength: nameToken.length,
            typeAliasBuilder: typeAliasBuilder as TypeAliasBuilder?,
            isConstructorInvocation: true);
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

    return buildUnresolvedError(errorName, nameLastToken.charOffset,
        arguments: arguments, message: message, kind: unresolvedKind);
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
    if (!libraryFeatures.constFunctions.isEnabled) {
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
    assert(checkState(token, [ValueKinds.Condition]));
    // This is matched by the call to [deferNode] in
    // [handleElseControlFlow] and by the call to [endNode] in
    // [endIfControlFlow].
    typeInferrer.assignedVariables.beginNode();

    Condition condition = pop() as Condition;
    PatternGuard? patternGuard = condition.patternGuard;
    if (patternGuard != null) {
      if (patternGuard.guard != null) {
        Scope thenScope = scope.createNestedScope(
            debugName: "then-control-flow", kind: ScopeKind.ifElement);
        exitLocalScope(expectedScopeKinds: const [ScopeKind.ifCaseHead]);
        enterLocalScope(thenScope);
      } else {
        createAndEnterLocalScope(
            debugName: "if-case-head", kind: ScopeKind.ifCaseHead);
        for (VariableDeclaration variable
            in patternGuard.pattern.declaredVariables) {
          declareVariable(variable, scope);
        }
        Scope thenScope = scope.createNestedScope(
            debugName: "then-control-flow", kind: ScopeKind.ifElement);
        exitLocalScope(expectedScopeKinds: const [ScopeKind.ifCaseHead]);
        enterLocalScope(thenScope);
      }
    } else {
      createAndEnterLocalScope(
          debugName: "then-control-flow", kind: ScopeKind.ifElement);
    }
    push(condition);

    super.handleThenControlFlow(token);
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    assert(checkState(elseToken, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.MapLiteralEntry,
      ]),
      ValueKinds.Condition,
    ]));
    // Resolve the top of the stack so that if it's a delayed assignment it
    // happens before we go into the else block.
    Object then = pop() as Object;
    if (then is! MapLiteralEntry) then = toValue(then);

    Object condition = pop() as Condition;
    exitLocalScope(expectedScopeKinds: const [ScopeKind.ifElement]);
    push(condition);

    // This is matched by the call to [beginNode] in
    // [handleThenControlFlow] and by the call to [storeInfo] in
    // [endIfElseControlFlow].
    push(typeInferrer.assignedVariables.deferNode());
    push(then);
  }

  @override
  void endIfControlFlow(Token token) {
    debugEvent("endIfControlFlow");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.MapLiteralEntry,
      ]),
      ValueKinds.Condition,
      ValueKinds.Scope,
      ValueKinds.Token,
    ]));

    Object? entry = pop();
    Condition condition = pop() as Condition;
    exitLocalScope(expectedScopeKinds: const [ScopeKind.ifElement]);
    Token ifToken = pop() as Token;

    PatternGuard? patternGuard = condition.patternGuard;
    TreeNode node;
    if (entry is MapLiteralEntry) {
      if (patternGuard == null) {
        node = forest.createIfMapEntry(
            offsetForToken(ifToken), condition.expression, entry);
      } else {
        node = forest.createIfCaseMapEntry(offsetForToken(ifToken),
            prelude: [],
            expression: condition.expression,
            patternGuard: patternGuard,
            then: entry);
      }
    } else {
      if (patternGuard == null) {
        node = forest.createIfElement(
            offsetForToken(ifToken), condition.expression, toValue(entry));
      } else {
        node = forest.createIfCaseElement(offsetForToken(ifToken),
            prelude: [],
            expression: condition.expression,
            patternGuard: patternGuard,
            then: toValue(entry));
      }
    }
    push(node);
    // This is matched by the call to [beginNode] in
    // [handleThenControlFlow].
    typeInferrer.assignedVariables.endNode(node);
  }

  @override
  void endIfElseControlFlow(Token token) {
    debugEvent("endIfElseControlFlow");
    assert(checkState(token, [
      /* else element */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.MapLiteralEntry,
      ]),
      /* then element */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.MapLiteralEntry,
      ]),
      ValueKinds.AssignedVariablesNodeInfo,
      ValueKinds.Condition,
      ValueKinds.Token,
    ]));

    Object? elseEntry = pop(); // else entry
    Object? thenEntry = pop(); // then entry
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
    Condition condition = pop() as Condition; // parenthesized expression
    Token ifToken = pop() as Token;

    PatternGuard? patternGuard = condition.patternGuard;
    TreeNode node;
    if (thenEntry is MapLiteralEntry) {
      if (elseEntry is MapLiteralEntry) {
        if (patternGuard == null) {
          node = forest.createIfMapEntry(offsetForToken(ifToken),
              condition.expression, thenEntry, elseEntry);
        } else {
          node = forest.createIfCaseMapEntry(offsetForToken(ifToken),
              prelude: [],
              expression: condition.expression,
              patternGuard: patternGuard,
              then: thenEntry,
              otherwise: elseEntry);
        }
      } else if (elseEntry is ControlFlowElement) {
        MapLiteralEntry? elseMapEntry = elseEntry
            .toMapLiteralEntry(typeInferrer.assignedVariables.reassignInfo);
        if (elseMapEntry != null) {
          if (patternGuard == null) {
            node = forest.createIfMapEntry(offsetForToken(ifToken),
                condition.expression, thenEntry, elseMapEntry);
          } else {
            node = forest.createIfCaseMapEntry(offsetForToken(ifToken),
                prelude: [],
                expression: condition.expression,
                patternGuard: patternGuard,
                then: thenEntry,
                otherwise: elseMapEntry);
          }
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
          if (patternGuard == null) {
            node = forest.createIfMapEntry(offsetForToken(ifToken),
                condition.expression, thenMapEntry, elseEntry);
          } else {
            node = forest.createIfCaseMapEntry(offsetForToken(ifToken),
                prelude: [],
                expression: condition.expression,
                patternGuard: patternGuard,
                then: thenMapEntry,
                otherwise: elseEntry);
          }
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
      if (condition.patternGuard == null) {
        node = forest.createIfElement(offsetForToken(ifToken),
            condition.expression, toValue(thenEntry), toValue(elseEntry));
      } else {
        node = forest.createIfCaseElement(offsetForToken(ifToken),
            prelude: [],
            expression: condition.expression,
            patternGuard: condition.patternGuard!,
            then: toValue(thenEntry),
            otherwise: toValue(elseEntry));
      }
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
    push(forest.createSpreadElement(
        offsetForToken(spreadToken), toValue(expression),
        isNullAware: spreadToken.lexeme == '...?'));
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(const FixedNullableList<TypeBuilder>()
            .popNonNullable(stack, count, dummyTypeBuilder) ??
        NullValues.TypeArguments);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValues.TypeArguments);
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    if (context.isScopeReference && isDeclarationInstanceContext) {
      if (thisVariable != null && !inConstructorInitializer) {
        push(_createReadOnlyVariableAccess(thisVariable!, token,
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
        thisVariable == null) {
      _context.registerSuperCall();
      push(new ThisAccessGenerator(this, token, inInitializerLeftHandSide,
          inFieldInitializer, inLateFieldInitializer,
          isSuper: true));
    } else {
      push(new IncompleteErrorGenerator(
          this, token, fasta.messageSuperAsIdentifier));
    }
  }

  @override
  void handleAugmentSuperExpression(
      Token augmentToken, Token superToken, IdentifierContext context) {
    debugEvent("AugmentSuperExpression");
    AugmentSuperTarget? augmentSuperTarget = _context.augmentSuperTarget;
    if (augmentSuperTarget != null) {
      push(new AugmentSuperAccessGenerator(
          this, augmentToken, augmentSuperTarget));
      return;
    }
    push(new IncompleteErrorGenerator(
        this, augmentToken, fasta.messageInvalidAugmentSuper));
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
// TODO: Handle directly.
  void handleNamedRecordField(Token colon) => handleNamedArgument(colon);

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
    Identifier name = pop() as Identifier;
    Token nameToken = name.token;
    VariableDeclaration variable = new VariableDeclarationImpl(name.name,
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
    push(switchScope ?? NullValues.SwitchScope);
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
    push(typeVariables ?? NullValues.TypeVariables);
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
    createAndEnterLocalScope(
        debugName: "named function", kind: ScopeKind.namedFunctionExpression);
    push(typeVariables ?? NullValues.TypeVariables);
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

      declaration.function = function;
      function.parent = declaration;
      Statement statement;
      if (variable.initializer != null) {
        // This must have been a compile-time error.
        assert(isErroneousNode(variable.initializer!));

        statement =
            forest.createBlock(declaration.fileOffset, noLocation, <Statement>[
          forest.createExpressionStatement(
              offsetForToken(token), variable.initializer!),
          declaration
        ]);
        variable.initializer = null;
      } else {
        statement = declaration;
      }
      // This is matched by the call to [beginNode] in [enterFunction].
      typeInferrer.assignedVariables
          .endNode(declaration, isClosureOrLateVariableInitializer: true);
      if (isFunctionExpression) {
        // This is an error case. An expression is expected but we got a
        // function declaration instead. We wrap it in a [BlockExpression].
        exitLocalScope();
        push(new BlockExpression(
            forest.createBlock(declaration.fileOffset, noLocation, [statement]),
            buildProblem(fasta.messageNamedFunctionExpression,
                declaration.fileOffset, noLength,
                // Error has already been reported by the parser.
                suppressMessage: true))
          ..fileOffset = declaration.fileOffset);
      } else {
        push(statement);
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
    debugEvent("beginDoWhileStatement");
    // This is matched by the [endNode] call in [endDoWhileStatement].
    typeInferrer.assignedVariables.beginNode();
    enterLoop(token.charOffset);
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    debugEvent("DoWhileStatement");
    assert(checkState(doKeyword, [
      /* condition = */ ValueKinds.Condition,
      /* body = */ ValueKinds.Statement,
      /* continue target = */ ValueKinds.ContinueTarget,
      /* break target = */ ValueKinds.BreakTarget,
    ]));
    Condition condition = pop() as Condition;
    assert(condition.patternGuard == null,
        "Unexpected pattern in do statement: ${condition.patternGuard}.");
    Expression expression = condition.expression;
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
        forest.createDoStatement(offsetForToken(doKeyword), body, expression);
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
    if (scope.parent != null) {
      enterLocalScope(scope.parent!);
    } else {
      createAndEnterLocalScope(
          debugName: 'forIn', kind: ScopeKind.statementLocalScope);
    }
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
      Token leftParenthesis, Token? patternKeyword, Token inKeyword) {
    debugEvent("ForIntLoopParts");
    assert(checkState(forToken, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
        ValueKinds.Statement, // Variable for non-pattern for-in loop.
      ]),
    ]));
    Object expression = pop() as Object;
    Object pattern = pop() as Object;

    if (pattern is Pattern) {
      pop(); // Metadata.
      bool isFinal = patternKeyword?.lexeme == 'final';
      for (VariableDeclaration variable in pattern.declaredVariables) {
        variable.isFinal |= isFinal;
        declareVariable(variable, scope);
      }
    }

    push(pattern);
    push(expression);
    push(awaitToken ?? NullValues.AwaitToken);
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
    Token? awaitToken = pop(NullValues.AwaitToken) as Token?;

    if (constantContext != ConstantContext.none) {
      popForValue(); // Pop iterable
      pop(); // Pop lvalue
      exitLocalScope();
      typeInferrer.assignedVariables.discardNode();

      push(buildProblem(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(forToken),
          forToken.charOffset,
          forToken.charCount));
      return;
    }

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo =
        typeInferrer.assignedVariables.popNode();

    Expression iterable = popForValue();
    Object? lvalue = pop(); // lvalue
    exitLocalScope();

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
        // As a recovery step, remove the const flag, to not confuse the
        // constant evaluator further in the pipeline.
        lvalue.isConst = false;
      }
    } else {
      VariableDeclaration variable = elements.syntheticVariableDeclaration =
          forest.createVariableDeclaration(offsetForToken(forToken), null,
              isFinal: true, isSynthesized: true);
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
      } else if (lvalue is Pattern) {
        /// We are in the case where `lvalue` is a pattern:
        ///
        ///     for (pattern in expression) body
        ///
        /// This is normalized to:
        ///
        ///     for (final #t in expression) {
        ///       pattern = #t;
        ///       body;
        ///     }
        elements.syntheticAssignment = null;
        elements.expressionEffects = forest.createPatternVariableDeclaration(
            inToken.offset,
            lvalue,
            new VariableGetImpl(variable, forNullGuardedAccess: false),
            isFinal: false);
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
    assert(checkState(endToken, [
      /* body= */ ValueKinds.Statement,
      /* inKeyword = */ ValueKinds.Token,
      /* forToken = */ ValueKinds.Token,
      /* awaitToken = */ ValueKinds.AwaitTokenOrNull,
      /* expression = */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      /* lvalue = */ unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
        ValueKinds.Statement,
      ]),
    ]));
    Statement body = popStatement();

    Token inKeyword = pop() as Token;
    Token forToken = pop() as Token;
    Token? awaitToken = pop(NullValues.AwaitToken) as Token?;

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo =
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
    enterLocalScope(scope.createNestedLabelScope());
    LabelTarget target =
        new LabelTarget(functionNestingLevel, uri, token.charOffset);
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
          Statement body = statement.body;
          if (body is! ForStatement &&
              body is! DoStatement &&
              body is! WhileStatement) {
            push(buildProblemStatement(
                fasta.messageContinueLabelInvalid, continueStatement.fileOffset,
                length: 8));
            return;
          }
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
    debugEvent("beginWhileStatement");
    // This is matched by the [endNode] call in [endWhileStatement].
    typeInferrer.assignedVariables.beginNode();
    enterLoop(token.charOffset);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    debugEvent("WhileStatement");
    assert(checkState(whileKeyword, [
      /* body = */ ValueKinds.Statement,
      /* condition = */ ValueKinds.Condition,
      /* continue target = */ ValueKinds.ContinueTarget,
      /* break target = */ ValueKinds.BreakTarget,
    ]));
    Statement body = popStatement();
    Condition condition = pop() as Condition;
    assert(condition.patternGuard == null,
        "Unexpected pattern in while statement: ${condition.patternGuard}.");
    Expression expression = condition.expression;
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
        offsetForToken(whileKeyword), expression, body);
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
    createAndEnterLocalScope(
        debugName: "switch block", kind: ScopeKind.statementLocalScope);
    enterSwitchScope();
    enterBreakTarget(token.charOffset);
    createAndEnterLocalScope(
        debugName: "case-head", kind: ScopeKind.caseHead); // Sentinel scope.
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    debugEvent("beginSwitchCase");
    int count = labelCount + expressionCount;
    assert(checkState(
        firstToken,
        repeatedKind(
            unionOfKinds([
              ValueKinds.Label,
              ValueKinds.ExpressionOrPatternGuardCase,
              ValueKinds.Scope,
            ]),
            count)));

    Scope? switchCaseScope;
    List<Label>? labels =
        labelCount == 0 ? null : new List<Label>.filled(labelCount, dummyLabel);
    int labelIndex = labelCount - 1;
    bool containsPatterns = false;
    List<ExpressionOrPatternGuardCase> expressionOrPatterns =
        new List<ExpressionOrPatternGuardCase>.filled(
            expressionCount, dummyExpressionOrPatternGuardCase,
            growable: true);
    int expressionOrPatternIndex = expressionCount - 1;

    for (int i = 0; i < count + 1; i++) {
      Object? value = peek();
      if (value is Label) {
        labels![labelIndex--] = value;
        pop();
      } else if (value is Scope) {
        assert(switchCaseScope == null);
        if (expressionCount == 1) {
          // The single-head case. The scope of the head should be remembered
          // and reused later; it already contains the declared pattern
          // variables.
          switchCaseScope = scope;
          exitLocalScope(expectedScopeKinds: const [ScopeKind.caseHead]);
        } else {
          // The multi-head or "default" case. The scope of the last head should
          // be exited, and the new scope for the joint variables should be
          // created.
          exitLocalScope(expectedScopeKinds: const [ScopeKind.caseHead]);
          switchCaseScope = scope.createNestedScope(
              debugName: "joint-variables", kind: ScopeKind.jointVariables);
        }
      } else {
        expressionOrPatterns[expressionOrPatternIndex--] =
            value as ExpressionOrPatternGuardCase;
        if (value.patternGuard != null) {
          containsPatterns = true;
        }
        pop();
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
    push(expressionOrPatterns);
    push(containsPatterns);
    push(labels ?? NullValues.Labels);

    List<VariableDeclaration>? jointPatternVariables;
    List<VariableDeclaration>? jointPatternVariablesWithMismatchingFinality;
    List<VariableDeclaration>? jointPatternVariablesNotInAll;
    enterLocalScope(switchCaseScope!);
    if (expressionCount > 1) {
      for (int i = 0; i < expressionOrPatterns.length; i++) {
        ExpressionOrPatternGuardCase expressionOrPattern =
            expressionOrPatterns[i];
        PatternGuard? patternGuard = expressionOrPattern.patternGuard;
        if (patternGuard != null) {
          if (jointPatternVariables == null) {
            jointPatternVariables = [
              for (VariableDeclaration variable
                  in patternGuard.pattern.declaredVariables)
                forest.createVariableDeclaration(
                    variable.fileOffset, variable.name!)
                  ..isFinal = variable.isFinal
            ];
            if (i != 0) {
              // The previous heads were non-pattern ones, so no variables can
              // be joined.
              (jointPatternVariablesNotInAll ??= [])
                  .addAll(jointPatternVariables);
            }
          } else {
            Map<String, VariableDeclaration> patternVariablesByName = {
              for (VariableDeclaration variable
                  in patternGuard.pattern.declaredVariables)
                variable.name!: variable
            };
            for (VariableDeclaration jointVariable in jointPatternVariables) {
              String jointVariableName = jointVariable.name!;
              VariableDeclaration? patternVariable =
                  patternVariablesByName.remove(jointVariableName);
              if (patternVariable != null) {
                if (patternVariable.isFinal != jointVariable.isFinal) {
                  (jointPatternVariablesWithMismatchingFinality ??= [])
                      .add(jointVariable);
                }
              } else {
                (jointPatternVariablesNotInAll ??= []).add(jointVariable);
              }
            }
            if (patternVariablesByName.isNotEmpty) {
              for (VariableDeclaration variable
                  in patternVariablesByName.values) {
                VariableDeclaration jointVariable = forest
                    .createVariableDeclaration(
                        variable.fileOffset, variable.name!)
                  ..isFinal = variable.isFinal;
                (jointPatternVariablesNotInAll ??= []).add(jointVariable);
                jointPatternVariables.add(jointVariable);
              }
            }
          }
        } else {
          // It's a non-pattern head, so no variables can be joined.
          if (jointPatternVariables != null) {
            (jointPatternVariablesNotInAll ??= [])
                .addAll(jointPatternVariables);
          }
        }
      }
      if (jointPatternVariables != null) {
        if (jointPatternVariables.isEmpty) {
          jointPatternVariables = null;
        } else {
          for (VariableDeclaration jointVariable in jointPatternVariables) {
            assert(scope.kind == ScopeKind.jointVariables);
            declareVariable(jointVariable, scope);
            typeInferrer.assignedVariables.declare(jointVariable);
          }
        }
      }
      switchCaseScope = scope.createNestedScope(
          debugName: "switch case", kind: ScopeKind.switchCase);
      exitLocalScope(expectedScopeKinds: const [ScopeKind.jointVariables]);
      enterLocalScope(switchCaseScope);
    } else if (expressionCount == 1) {
      switchCaseScope = scope.createNestedScope(
          debugName: "switch case", kind: ScopeKind.switchCase);
      exitLocalScope(expectedScopeKinds: const [ScopeKind.caseHead]);
      enterLocalScope(switchCaseScope);
    }
    push(jointPatternVariablesNotInAll ?? NullValues.VariableDeclarationList);
    push(jointPatternVariablesWithMismatchingFinality ??
        NullValues.VariableDeclarationList);
    push(jointPatternVariables ?? NullValues.VariableDeclarationList);

    createAndEnterLocalScope(
        debugName: "switch-case-body", kind: ScopeKind.switchCaseBody);

    assert(checkState(firstToken, [
      ValueKinds.Scope,
      ValueKinds.VariableDeclarationListOrNull,
      ValueKinds.VariableDeclarationListOrNull,
      ValueKinds.VariableDeclarationListOrNull,
      ValueKinds.Scope,
      ValueKinds.LabelListOrNull,
      ValueKinds.Bool,
      ValueKinds.ExpressionOrPatternGuardCaseList,
    ]));
  }

  @override
  void beginSwitchCaseWhenClause(Token when) {
    debugEvent("SwitchCaseWhenClause");
    assert(checkState(when, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      ValueKinds.ConstantContext,
    ]));

    // Here we declare the pattern variables in the scope of the case head. It
    // makes the variables visible in the 'when' clause of the head.
    Object? pattern = peek();
    if (pattern is Pattern) {
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, scope);
      }
    }
    push(constantContext);
    constantContext = ConstantContext.none;
  }

  @override
  void endSwitchCaseWhenClause(Token token) {
    debugEvent("SwitchCaseWhenClause");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.ProblemBuilder,
        ValueKinds.Generator
      ]),
      ValueKinds.ConstantContext,
    ]));
    Object? guard = pop();
    constantContext = pop() as ConstantContext;
    push(guard);
  }

  @override
  void handleSwitchCaseNoWhenClause(Token token) {
    debugEvent("SwitchCaseWhenClause");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ])
    ]));

    // Here we declare the pattern variables. It makes the variables visible
    // body of the case.
    Object? pattern = peek();
    if (pattern is Pattern) {
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, scope);
      }
    }
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
    assert(checkState(firstToken, [
      ...repeatedKind(ValueKinds.Statement, statementCount),
      ValueKinds.Scope,
      ValueKinds.VariableDeclarationListOrNull,
      ValueKinds.VariableDeclarationListOrNull,
      ValueKinds.VariableDeclarationListOrNull,
      ValueKinds.Scope,
      ValueKinds.LabelListOrNull,
      ValueKinds.Bool,
      ValueKinds.ExpressionOrPatternGuardCaseList,
    ]));

    // We always create a block here so that we later know that there's always
    // one synthetic block when we finish compiling the switch statement and
    // check this switch case to see if it falls through to the next case.
    Statement block = popBlock(statementCount, firstToken, null);
    exitLocalScope(expectedScopeKinds: const [ScopeKind.switchCaseBody]);
    List<VariableDeclaration>? jointPatternVariables =
        pop() as List<VariableDeclaration>?;
    List<VariableDeclaration>? jointPatternVariablesWithMismatchingFinality =
        pop() as List<VariableDeclaration>?;
    List<VariableDeclaration>? jointPatternVariablesNotInAll =
        pop() as List<VariableDeclaration>?;

    // The current scope should be the scope of the body of the switch case
    // because we want to lookup the first use of the pattern variables
    // specifically in the body of the case, as opposed to, for example, the
    // guard in one of the heads of the case.
    assert(
        scope.kind == ScopeKind.switchCase ||
            scope.kind == ScopeKind.jointVariables,
        "Expected the current scope to be of kind '${ScopeKind.switchCase}' "
        "or '${ScopeKind.jointVariables}', but got '${scope.kind}.");
    Map<String, int>? usedNamesOffsets = scope.usedNames;

    bool hasDefaultOrLabels = defaultKeyword != null || labelCount > 0;

    List<VariableDeclaration>? usedJointPatternVariables;
    List<int>? jointVariableFirstUseOffsets;
    if (jointPatternVariables != null) {
      usedJointPatternVariables = [];
      Map<VariableDeclaration, int> firstUseOffsets = {};
      for (VariableDeclaration variable in jointPatternVariables) {
        int? firstUseOffset = usedNamesOffsets?[variable.name!];
        if (firstUseOffset != null) {
          usedJointPatternVariables.add(variable);
          firstUseOffsets[variable] = firstUseOffset;
        }
      }
      if (jointPatternVariablesWithMismatchingFinality != null ||
          jointPatternVariablesNotInAll != null ||
          hasDefaultOrLabels) {
        for (VariableDeclaration jointVariable in usedJointPatternVariables) {
          if (jointPatternVariablesWithMismatchingFinality
                  ?.contains(jointVariable) ??
              false) {
            String jointVariableName = jointVariable.name!;
            addProblem(
                fasta.templateJointPatternVariablesMismatch
                    .withArguments(jointVariableName),
                firstUseOffsets[jointVariable]!,
                jointVariableName.length);
          }
          if (jointPatternVariablesNotInAll?.contains(jointVariable) ?? false) {
            String jointVariableName = jointVariable.name!;
            addProblem(
                fasta.templateJointPatternVariableNotInAll
                    .withArguments(jointVariableName),
                firstUseOffsets[jointVariable]!,
                jointVariableName.length);
          }
          if (hasDefaultOrLabels) {
            String jointVariableName = jointVariable.name!;
            addProblem(
                fasta.templateJointPatternVariableWithLabelDefault
                    .withArguments(jointVariableName),
                firstUseOffsets[jointVariable]!,
                jointVariableName.length);
          }
        }
      }
      jointVariableFirstUseOffsets = [
        for (VariableDeclaration variable in usedJointPatternVariables)
          firstUseOffsets[variable]!
      ];
    }

    exitLocalScope(expectedScopeKinds: const [
      ScopeKind.switchCase,
      ScopeKind.caseHead,
      ScopeKind.jointVariables
    ]);

    List<Label>? labels = pop() as List<Label>?;
    assert(labels == null || labels.isNotEmpty);
    bool containsPatterns = pop() as bool;
    List<ExpressionOrPatternGuardCase> expressionsOrPatternGuards =
        pop() as List<ExpressionOrPatternGuardCase>;

    if (expressionCount == 1 &&
        containsPatterns &&
        hasDefaultOrLabels &&
        usedNamesOffsets != null) {
      PatternGuard? patternGuard =
          expressionsOrPatternGuards.first.patternGuard;
      if (patternGuard != null) {
        for (VariableDeclaration variable
            in patternGuard.pattern.declaredVariables) {
          String variableName = variable.name!;
          int? offset = usedNamesOffsets[variableName];
          if (offset != null) {
            addProblem(
                fasta.templateJointPatternVariableWithLabelDefault
                    .withArguments(variableName),
                offset,
                variableName.length);
          }
        }
      }
    }
    if (containsPatterns || libraryFeatures.patterns.isEnabled) {
      // If patterns are enabled, we always use the pattern switch encoding.
      // Otherwise, we use pattern switch encoding to handle the erroneous case
      // of an unsupported use of patterns.
      List<int> caseOffsets = [];
      List<PatternGuard> patternGuards = <PatternGuard>[];
      for (ExpressionOrPatternGuardCase expressionOrPatternGuard
          in expressionsOrPatternGuards) {
        caseOffsets.add(expressionOrPatternGuard.caseOffset);
        if (expressionOrPatternGuard.patternGuard != null) {
          patternGuards.add(expressionOrPatternGuard.patternGuard!);
        } else {
          patternGuards.add(forest.createPatternGuard(
              expressionOrPatternGuard.caseOffset,
              toPattern(expressionOrPatternGuard.expression!)));
        }
      }
      push(forest.createPatternSwitchCase(
          firstToken.charOffset, caseOffsets, patternGuards, block,
          isDefault: defaultKeyword != null,
          hasLabel: labels != null,
          jointVariables: usedJointPatternVariables ?? [],
          jointVariableFirstUseOffsets: jointVariableFirstUseOffsets));
    } else {
      List<Expression> expressions = <Expression>[];
      List<int> caseOffsets = [];
      List<int> expressionOffsets = <int>[];
      for (ExpressionOrPatternGuardCase expressionOrPatternGuard
          in expressionsOrPatternGuards) {
        Expression expression = expressionOrPatternGuard.expression!;
        expressions.add(expression);
        caseOffsets.add(expressionOrPatternGuard.caseOffset);
        expressionOffsets.add(expression.fileOffset);
      }
      push(new SwitchCaseImpl(
          caseOffsets, expressions, expressionOffsets, block,
          isDefault: defaultKeyword != null, hasLabel: labels != null)
        ..fileOffset = firstToken.charOffset);
    }
    push(labels ?? NullValues.Labels);
    createAndEnterLocalScope(
        debugName: "case-head", kind: ScopeKind.caseHead); // Sentinel scope.
    assert(checkState(firstToken, [
      ValueKinds.Scope,
      ValueKinds.LabelListOrNull,
      ValueKinds.SwitchCase,
    ]));
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");
    assert(checkState(switchKeyword, [
      /* labelUsers = */ ValueKinds.StatementListOrNullList,
      /* cases = */ ValueKinds.SwitchCaseList,
      /* containsPatterns */ ValueKinds.Bool,
      /* break target = */ ValueKinds.BreakTarget,
      /* switch scope = */ ValueKinds.SwitchScopeOrNull,
      /* local scope = */ ValueKinds.Scope,
      /* expression = */ ValueKinds.Condition,
    ]));
    List<List<Statement>?> labelUsers = pop() as List<List<Statement>?>;
    List<SwitchCase> cases = pop() as List<SwitchCase>;
    bool containsPatterns = pop() as bool;
    JumpTarget target = exitBreakTarget()!;
    exitSwitchScope();
    exitLocalScope();
    Condition condition = pop() as Condition;
    assert(condition.patternGuard == null,
        "Unexpected pattern in switch statement: ${condition.patternGuard}.");
    Expression expression = condition.expression;
    Statement switchStatement;
    if (containsPatterns || libraryFeatures.patterns.isEnabled) {
      // If patterns are enabled, we always use the pattern switch encoding.
      // Otherwise, we use pattern switch encoding to handle the erroneous case
      // of an unsupported use of patterns.
      List<PatternSwitchCase> patternSwitchCases =
          new List<PatternSwitchCase>.generate(cases.length, (int index) {
        SwitchCase switchCase = cases[index];
        PatternSwitchCase patternSwitchCase;
        if (switchCase is PatternSwitchCase) {
          patternSwitchCase = switchCase;
        } else {
          List<PatternGuard> patterns = new List<PatternGuard>.generate(
              switchCase.expressions.length, (int index) {
            return forest.createPatternGuard(
                switchCase.expressions[index].fileOffset,
                forest.createConstantPattern(switchCase.expressions[index]));
          });
          patternSwitchCase = forest.createPatternSwitchCase(
              switchCase.fileOffset,
              (switchCase as SwitchCaseImpl).caseOffsets,
              patterns,
              switchCase.body,
              isDefault: switchCase.isDefault,
              hasLabel: switchCase.hasLabel,
              jointVariables: [],
              jointVariableFirstUseOffsets: null);
        }
        List<Statement>? users = labelUsers[index];
        if (users != null) {
          patternSwitchCase.labelUsers.addAll(users);
        }
        return patternSwitchCase;
      });
      switchStatement = forest.createPatternSwitchStatement(
          switchKeyword.charOffset, expression, patternSwitchCases);
    } else {
      switchStatement = new SwitchStatement(expression, cases)
        ..fileOffset = switchKeyword.charOffset;
    }
    Statement result = switchStatement;
    // We create a labeled statement enclosing the switch statement if it has
    // explicit break statements targeting it, or if the patterns feature is
    // enabled, in which case synthetic break statements might be inserted.
    // TODO(johnniwinther): Remove [LabeledStatement]s in inference visitor
    // when they have no target.
    if (target.hasUsers || libraryFeatures.patterns.isEnabled) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(result);
      target.resolveBreaks(forest, labeledStatement, switchStatement);
      result = labeledStatement;
    }
    exitLoopOrSwitch(result);
    // This is matched by the [beginNode] call in [beginSwitchBlock].
    typeInferrer.assignedVariables.endNode(switchStatement);
  }

  @override
  void handleSwitchExpressionCasePattern(Token token) {
    debugEvent("SwitchExpressionCasePattern");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern
      ])
    ]));
    Object? pattern = pop();
    createAndEnterLocalScope(
        debugName: "switch-expression-case", kind: ScopeKind.caseHead);
    if (pattern is Pattern) {
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, scope);
      }
    }
    push(pattern);
  }

  @override
  void endSwitchExpressionCase(Token? when, Token arrow, Token endToken) {
    debugEvent("endSwitchExpressionCase");
    assert(checkState(arrow, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      if (when != null)
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.ProblemBuilder,
        ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      ValueKinds.Scope,
    ]));

    Expression expression = popForValue();
    Expression? guard;
    if (when != null) {
      guard = popForValue();
    }
    Object? value = pop();
    exitLocalScope();
    PatternGuard patternGuard =
        forest.createPatternGuard(arrow.charOffset, toPattern(value), guard);
    push(forest.createSwitchExpressionCase(
        arrow.charOffset, patternGuard, expression));
    assert(checkState(arrow, [
      ValueKinds.SwitchExpressionCase,
    ]));
  }

  @override
  void endSwitchExpressionBlock(
      int caseCount, Token beginToken, Token endToken) {
    debugEvent("endSwitchExpressionBlock");
    assert(checkState(
        beginToken, repeatedKind(ValueKinds.SwitchExpressionCase, caseCount)));
    List<SwitchExpressionCase> cases = new List<SwitchExpressionCase>.filled(
        caseCount, dummySwitchExpressionCase);
    for (int i = caseCount - 1; i >= 0; i--) {
      cases[i] = pop() as SwitchExpressionCase;
    }
    push(cases);
  }

  @override
  void endSwitchExpression(Token switchKeyword, Token endToken) {
    debugEvent("endSwitchExpression");
    assert(checkState(switchKeyword,
        [ValueKinds.SwitchExpressionCaseList, ValueKinds.Condition]));

    List<SwitchExpressionCase> cases = pop() as List<SwitchExpressionCase>;
    Condition condition = pop() as Condition;
    assert(condition.patternGuard == null,
        "Unexpected pattern in switch expression: ${condition.patternGuard}.");
    Expression expression = condition.expression;
    push(forest.createSwitchExpression(
        switchKeyword.charOffset, expression, cases));
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    debugEvent("SwitchBlock");
    assert(checkState(beginToken, [
      ValueKinds.Scope,
      ...repeatedKinds([
        ValueKinds.LabelListOrNull,
        ValueKinds.SwitchCase,
      ], caseCount)
    ]));

    exitLocalScope(expectedScopeKinds: const [
      ScopeKind.caseHead
    ]); // Exit the sentinel scope.

    bool containsPatterns = false;
    List<SwitchCase> cases =
        new List<SwitchCase>.filled(caseCount, dummySwitchCase, growable: true);
    List<List<Statement>?> caseLabelUsers =
        new List<List<Statement>?>.filled(caseCount, null, growable: true);
    for (int i = caseCount - 1; i >= 0; i--) {
      List<Label>? labels = pop() as List<Label>?;
      SwitchCase current = cases[i] = pop() as SwitchCase;
      if (labels != null) {
        for (Label label in labels) {
          JumpTarget? target = switchScope!.lookupLabel(label.name);
          if (target != null) {
            (caseLabelUsers[i] ??= <Statement>[]).addAll(target.users);
            target.resolveGotos(forest, current);
          }
        }
      }
      if (current is PatternSwitchCase) {
        containsPatterns = true;
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

    push(containsPatterns);
    push(cases);
    push(caseLabelUsers);
    assert(checkState(beginToken, [
      ValueKinds.StatementListOrNullList,
      ValueKinds.SwitchCaseList,
      ValueKinds.Bool,
    ]));
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
      target = scope.lookupLabel(name);
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
      target = scope.lookupLabel(identifier.name);
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
        typeVariableName, libraryBuilder, typeVariableCharOffset, uri,
        kind: TypeVariableKind.function);
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
      if (!libraryFeatures.variance.isEnabled) {
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
        unboundTypes: unboundTypes,
        unboundTypeVariables: unboundTypeVariables);
    assert(unboundTypes.isEmpty,
        "Found a type not bound to a declaration in BodyBuilder.");
    for (int i = 0; i < typeVariables.length; ++i) {
      typeVariables[i].defaultType = calculatedBounds[i];
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
    push(NullValues.TypeVariables);
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
  InvalidExpression buildProblem(Message message, int charOffset, int length,
      {List<LocatedMessage>? context,
      bool suppressMessage = false,
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
    return new InvalidExpression(
        fasta.messageSwitchCaseFallThrough.problemMessage);
  }

  Expression buildAbstractClassInstantiationError(
      Message message, String className,
      [int charOffset = -1]) {
    addProblemErrorIfConst(message, charOffset, className.length);
    return new InvalidExpression(message.problemMessage);
  }

  Statement buildProblemStatement(Message message, int charOffset,
      {List<LocatedMessage>? context,
      int? length,
      bool suppressMessage = false}) {
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
    Builder? builder = _context.lookupLocalMember(name);
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
            charOffset: assignmentOffset,
            isConstructorInvocation: true);
        return <Initializer>[
          new ShadowInvalidFieldInitializer(
              builder.field,
              expression,
              new VariableDeclaration.forValue(
                  forest.createThrow(assignmentOffset, invocation)))
            ..fileOffset = assignmentOffset
        ];
      } else {
        if (formal != null && formal.type is! OmittedTypeBuilder) {
          DartType formalType = formal.variable!.type;
          DartType fieldType = _context.substituteFieldType(builder.fieldType);
          if (!typeEnvironment.isSubtypeOf(
              formalType, fieldType, SubtypeCheckMode.withNullabilities)) {
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
        _context.registerInitializedField(builder);
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
    if (_context.isConstConstructor && !constructor.isConst) {
      addProblem(fasta.messageConstConstructorWithNonConstSuper, charOffset,
          constructor.name.text.length);
    }
    needsImplicitSuperInitializer = false;
    return new SuperInitializer(constructor, arguments)
      ..fileOffset = charOffset
      ..isSynthetic = isSynthetic;
  }

  @override
  Initializer buildRedirectingInitializer(Name name, Arguments arguments,
      {required int fileOffset}) {
    Builder? constructorBuilder = _context.lookupConstructor(name);
    if (constructorBuilder == null) {
      int length = name.text.length;
      if (length == 0) {
        // The constructor is unnamed so the offset points to 'this'.
        length = "this".length;
      }
      String fullName = constructorNameForDiagnostics(name.text);
      LocatedMessage message = fasta.templateConstructorNotFound
          .withArguments(fullName)
          .withLocation(uri, fileOffset, length);
      return buildInvalidInitializer(
          buildUnresolvedError(fullName, fileOffset,
              arguments: arguments,
              isSuper: false,
              message: message,
              kind: UnresolvedKind.Constructor),
          fileOffset);
    } else {
      if (_context.isConstructorCyclic(name.text)) {
        int length = name.text.length;
        if (length == 0) length = "this".length;
        addProblem(fasta.messageConstructorCyclic, fileOffset, length);
        // TODO(askesc): Produce invalid initializer.
      }
      needsImplicitSuperInitializer = false;
      return _context.buildRedirectingInitializer(constructorBuilder, arguments,
          fileOffset: fileOffset);
    }
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
    if (_context.isNativeMethod) {
      push(NullValues.FunctionBody);
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
    if (libraryFeatures.constructorTearoffs.isEnabled) {
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
            buildDartTypeArguments(typeArguments, TypeUse.tearOffTypeArgument,
                allowPotentiallyConstantType: true))
          ..fileOffset = openAngleBracket.charOffset);
      }
    } else {
      libraryBuilder.reportFeatureNotEnabled(
          libraryFeatures.constructorTearoffs,
          uri,
          openAngleBracket.charOffset,
          noLength);
    }
  }

  @override
  TypeBuilder validateTypeVariableUse(TypeBuilder typeBuilder,
      {required bool allowPotentiallyConstantType}) {
    _validateTypeVariableUseInternal(typeBuilder,
        allowPotentiallyConstantType: allowPotentiallyConstantType);
    return typeBuilder;
  }

  void _validateTypeVariableUseInternal(TypeBuilder? builder,
      {required bool allowPotentiallyConstantType}) {
    if (builder is NamedTypeBuilder) {
      if (builder.declaration!.isTypeVariable) {
        TypeVariableBuilder typeParameterBuilder =
            builder.declaration as TypeVariableBuilder;
        TypeParameter typeParameter = typeParameterBuilder.parameter;
        if (typeParameter.parent is Class ||
            typeParameter.parent is Extension) {
          if (constantContext != ConstantContext.none &&
              (!inConstructorInitializer || !allowPotentiallyConstantType)) {
            LocatedMessage message = fasta.messageTypeVariableInConstantContext
                .withLocation(builder.fileUri!, builder.charOffset!,
                    typeParameter.name!.length);
            builder.bind(
                libraryBuilder,
                new InvalidTypeDeclarationBuilder(
                    typeParameter.name!, message));
            addProblem(
                message.messageObject, message.charOffset, message.length);
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
        for (ParameterBuilder formalParameterBuilder in builder.formals!) {
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
      {bool isConstantExpression = false, bool isNullAware = false}) {
    if (constantContext != ConstantContext.none &&
        !isConstantExpression &&
        !libraryFeatures.constFunctions.isEnabled) {
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
      {bool isConstantExpression = false,
      bool isNullAware = false,
      bool isImplicitCall = false}) {
    if (constantContext != ConstantContext.none &&
        !isConstantExpression &&
        !libraryFeatures.constFunctions.isEnabled) {
      return buildProblem(
          fasta.templateNotConstantExpression
              .withArguments('Method invocation'),
          offset,
          name.text.length);
    }
    Member? target = lookupSuperMember(name);

    if (target == null) {
      return buildUnresolvedError(name.text, offset,
          isSuper: true, arguments: arguments, kind: UnresolvedKind.Method);
    } else if (target is Procedure && !target.isAccessor) {
      return new SuperMethodInvocation(name, arguments, target)
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
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity}) {
    libraryBuilder.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context, severity: severity);
  }

  @override
  void addProblemErrorIfConst(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
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
      {bool wasHandled = false, List<LocatedMessage>? context}) {
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
  DartType buildDartType(TypeBuilder typeBuilder, TypeUse typeUse,
      {required bool allowPotentiallyConstantType}) {
    return validateTypeVariableUse(typeBuilder,
            allowPotentiallyConstantType: allowPotentiallyConstantType)
        .build(libraryBuilder, typeUse);
  }

  DartType buildAliasedDartType(TypeBuilder typeBuilder, TypeUse typeUse,
      {required bool allowPotentiallyConstantType}) {
    return validateTypeVariableUse(typeBuilder,
            allowPotentiallyConstantType: allowPotentiallyConstantType)
        .buildAliased(libraryBuilder, typeUse, /* hierarchy = */ null);
  }

  @override
  List<DartType> buildDartTypeArguments(
      List<TypeBuilder>? unresolvedTypes, TypeUse typeUse,
      {required bool allowPotentiallyConstantType}) {
    if (unresolvedTypes == null) return <DartType>[];
    return new List<DartType>.generate(
        unresolvedTypes.length,
        (int i) => buildDartType(unresolvedTypes[i], typeUse,
            allowPotentiallyConstantType: allowPotentiallyConstantType),
        growable: true);
  }

  @override
  String constructorNameForDiagnostics(String name, {String? className}) {
    className ??= _context.className;
    return name.isEmpty ? className : "$className.$name";
  }

  @override
  String superConstructorNameForDiagnostics(String name) {
    String className = _context.superClassName;
    return name.isEmpty ? className : "$className.$name";
  }

  @override
  void handleNewAsIdentifier(Token token) {
    reportIfNotEnabled(
        libraryFeatures.constructorTearoffs, token.charOffset, token.length);
  }

  @override
  void beginConstantPattern(Token? constKeyword) {
    debugEvent("ConstantPattern");
    push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void endConstantPattern(Token? constKeyword) {
    debugEvent("ConstantPattern");
    assert(checkState(constKeyword, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      ValueKinds.ConstantContext,
    ]));
    Expression expression = toValue(pop());
    constantContext = pop() as ConstantContext;
    push(expression);
  }

  @override
  void handleObjectPatternFields(int count, Token beginToken, Token endToken) {
    debugEvent("ObjectPattern");
    assert(checkState(
        beginToken,
        repeatedKind(
            unionOfKinds([
              ValueKinds.Expression,
              ValueKinds.Generator,
              ValueKinds.ProblemBuilder,
              ValueKinds.Pattern,
            ]),
            count)));
    reportIfNotEnabled(
        libraryFeatures.patterns, beginToken.charOffset, beginToken.charCount);
    List<NamedPattern>? fields;
    for (int i = 0; i < count; i++) {
      Object? field = pop();
      if (field is NamedPattern) {
        (fields ??= <NamedPattern>[]).add(field);
      } else {
        Pattern pattern = toPattern(field);
        if (pattern is! InvalidPattern) {
          addProblem(fasta.messageUnnamedObjectPatternField, pattern.fileOffset,
              noLength);
        }
      }
    }
    if (fields != null) {
      for (int i = 0, j = fields.length - 1; i < j; i++, j--) {
        NamedPattern field = fields[i];
        fields[i] = fields[j];
        fields[j] = field;
      }
    }
    push(fields ?? NullValues.PatternList);
  }

  @override
  void handleObjectPattern(
      Token firstIdentifier, Token? dot, Token? secondIdentifier) {
    debugEvent("ObjectPattern");
    assert(checkState(firstIdentifier, [
      ValueKinds.PatternListOrNull,
      ValueKinds.TypeArgumentsOrNull,
    ]));

    reportIfNotEnabled(libraryFeatures.patterns, firstIdentifier.charOffset,
        firstIdentifier.charCount);

    List<NamedPattern>? fields = pop() as List<NamedPattern>?;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;

    handleIdentifier(firstIdentifier, IdentifierContext.prefixedTypeReference);
    if (secondIdentifier != null) {
      handleIdentifier(
          secondIdentifier, IdentifierContext.typeReferenceContinuation);
      handleQualified(dot!);
    }
    push(typeArguments ?? NullValues.TypeArguments);
    handleType(firstIdentifier, null);
    TypeBuilder typeBuilder = pop() as TypeBuilder;
    TypeDeclarationBuilder? typeDeclaration = typeBuilder.declaration;
    DartType type = buildDartType(typeBuilder, TypeUse.objectPatternType,
        allowPotentiallyConstantType: true);
    push(new ObjectPatternInternal(type, fields ?? <NamedPattern>[],
        typeDeclaration is TypeAliasBuilder ? typeDeclaration.typedef : null,
        hasExplicitTypeArguments: typeArguments != null)
      ..fileOffset = firstIdentifier.charOffset);
  }

  @override
  void handleRestPattern(Token dots, {required bool hasSubPattern}) {
    debugEvent("RestPattern");
    assert(checkState(dots, [
      if (hasSubPattern)
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.ProblemBuilder,
          ValueKinds.Pattern,
        ]),
    ]));

    Pattern? subPattern;
    if (hasSubPattern) {
      subPattern = toPattern(pop());
    }
    push(forest.createRestPattern(dots.charOffset, subPattern));
  }

  @override
  void handleRelationalPattern(Token token) {
    debugEvent("RelationalPattern");
    assert(checkState(token, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
    ]));
    reportIfNotEnabled(
        libraryFeatures.patterns, token.charOffset, token.charCount);
    Expression operand = toValue(pop());
    RelationalPatternKind kind;
    String operator = token.lexeme;
    switch (operator) {
      case '==':
        kind = RelationalPatternKind.equals;
        break;
      case '!=':
        kind = RelationalPatternKind.notEquals;
        break;
      case '<':
        kind = RelationalPatternKind.lessThan;
        break;
      case '<=':
        kind = RelationalPatternKind.lessThanEqual;
        break;
      case '>':
        kind = RelationalPatternKind.greaterThan;
        break;
      case '>=':
        kind = RelationalPatternKind.greaterThanEqual;
        break;
      default:
        internalProblem(
            fasta.templateInternalProblemUnhandled
                .withArguments(operator, 'handleRelationalPattern'),
            token.charOffset,
            uri);
    }
    push(forest.createRelationalPattern(token.charOffset, kind, operand));
  }

  @override
  void handleNullAssertPattern(Token bang) {
    debugEvent("NullAssertPattern");
    assert(checkState(bang, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
    ]));
    reportIfNotEnabled(
        libraryFeatures.patterns, bang.charOffset, bang.charCount);
    Pattern operand = toPattern(pop());
    push(forest.createNullAssertPattern(bang.charOffset, operand));
  }

  @override
  void handleNullCheckPattern(Token question) {
    debugEvent('NullCheckPattern');
    assert(checkState(question, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
    ]));
    reportIfNotEnabled(
        libraryFeatures.patterns, question.charOffset, question.charCount);
    // ignore: unused_local_variable
    Pattern operand = toPattern(pop());
    push(forest.createNullCheckPattern(question.charOffset, operand));
  }

  @override
  void handleAssignedVariablePattern(Token variable) {
    debugEvent('AssignedVariablePattern');

    reportIfNotEnabled(
        libraryFeatures.patterns, variable.charOffset, variable.charCount);
    assert(variable.lexeme != '_');
    Pattern pattern;
    String name = variable.lexeme;
    Expression variableUse = toValue(scopeLookup(scope, name, variable));
    if (variableUse is VariableGet) {
      VariableDeclaration variableDeclaration = variableUse.variable;
      pattern = forest.createAssignedVariablePattern(
          variable.charOffset, variableDeclaration);
      registerVariableAssignment(variableDeclaration);
    } else {
      addProblem(fasta.messagePatternAssignmentNotLocalVariable,
          variable.charOffset, variable.charCount);
      // Recover by using [WildcardPattern] instead.
      pattern = forest.createWildcardPattern(variable.charOffset, null);
    }
    push(pattern);
  }

  @override
  void handleDeclaredVariablePattern(Token? keyword, Token variable,
      {required bool inAssignmentPattern}) {
    debugEvent('DeclaredVariablePattern');
    assert(checkState(keyword ?? variable, [
      ValueKinds.TypeBuilderOrNull,
    ]));

    reportIfNotEnabled(
        libraryFeatures.patterns, variable.charOffset, variable.charCount);
    assert(variable.lexeme != '_');
    TypeBuilder? type = pop(NullValues.TypeBuilder) as TypeBuilder?;
    DartType? patternType = type?.build(libraryBuilder, TypeUse.variableType);
    Pattern pattern;
    if (inAssignmentPattern) {
      // Error has already been reported.
      pattern = forest.createInvalidPattern(
          new InvalidExpression('declared variable pattern in assignment'),
          declaredVariables: const []);
    } else {
      VariableDeclaration declaredVariable = forest.createVariableDeclaration(
          variable.charOffset, variable.lexeme,
          type: patternType,
          isFinal:
              Modifier.validateVarFinalOrConst(keyword?.lexeme) == finalMask);
      pattern = forest.createVariablePattern(
          variable.charOffset, patternType, declaredVariable);
      declareVariable(declaredVariable, scope);
      typeInferrer.assignedVariables.declare(declaredVariable);
    }
    push(pattern);
  }

  @override
  void handleWildcardPattern(Token? keyword, Token wildcard) {
    debugEvent('WildcardPattern');
    assert(checkState(keyword ?? wildcard, [
      ValueKinds.TypeBuilderOrNull,
    ]));

    reportIfNotEnabled(
        libraryFeatures.patterns, wildcard.charOffset, wildcard.charCount);
    TypeBuilder? type = pop(NullValues.TypeBuilder) as TypeBuilder?;
    DartType? patternType = type?.build(libraryBuilder, TypeUse.variableType);
    // Note: if `default` appears in a switch expression, parser error recovery
    // treats it as a wildcard pattern.
    assert(wildcard.lexeme == '_' || wildcard.lexeme == 'default');
    push(forest.createWildcardPattern(wildcard.charOffset, patternType));
  }

  @override
  void handlePatternField(Token? colon) {
    debugEvent("PatternField");
    assert(checkState(colon, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern,
      ]),
      if (colon != null)
        unionOfKinds([ValueKinds.IdentifierOrNull, ValueKinds.ParserRecovery]),
    ]));

    Object? value = pop();
    Pattern pattern = toPattern(value);
    if (colon != null) {
      Object? identifier = pop();
      if (identifier is ParserRecovery) {
        push(
            new ParserErrorGenerator(this, colon, fasta.messageSyntheticToken));
      } else {
        String? name;
        if (identifier is Identifier) {
          name = identifier.name;
        } else {
          name = pattern.variableName;
        }
        if (name == null) {
          push(forest.createInvalidPattern(
              buildProblem(fasta.messageUnspecifiedGetterNameInObjectPattern,
                  colon.charOffset, noLength),
              declaredVariables: const []));
        } else {
          push(forest.createNamedPattern(colon.charOffset, name, pattern));
        }
      }
    } else {
      push(pattern);
    }
  }

  @override
  void handlePatternVariableDeclarationStatement(
      Token keyword, Token equals, Token semicolon) {
    debugEvent('PatternVariableDeclarationStatement');
    assert(checkState(keyword, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
        ValueKinds.Pattern
      ]),
      ValueKinds.AnnotationListOrNull,
    ]));
    Expression initializer = popForValue();
    Pattern pattern = toPattern(pop());
    bool isFinal = keyword.lexeme == 'final';
    for (VariableDeclaration variable in pattern.declaredVariables) {
      variable.isFinal = isFinal;
      variable.hasDeclaredInitializer = true;
      declareVariable(variable, scope);
    }
    // TODO(johnniwinther,cstefantsova): Handle metadata.
    pop(NullValues.Metadata) as List<Expression>?;
    push(forest.createPatternVariableDeclaration(
        keyword.charOffset, pattern, initializer,
        isFinal: isFinal));
  }

  @override
  void handlePatternAssignment(Token equals) {
    debugEvent("PatternAssignment");
    assert(checkState(equals, [
      unionOfKinds([
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
      unionOfKinds([
        ValueKinds.Pattern,
        ValueKinds.Expression,
        ValueKinds.Generator,
        ValueKinds.ProblemBuilder,
      ]),
    ]));
    Expression expression = popForValue();
    Pattern pattern = toPattern(pop());
    push(
        forest.createPatternAssignment(equals.charOffset, pattern, expression));
  }
}

class Operator {
  final Token token;

  String get name => token.stringValue!;

  final int charOffset;

  Operator(this.token, this.charOffset);

  @override
  String toString() => "operator($name)";
}

class JumpTarget {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  final Uri fileUri;

  final int charOffset;

  JumpTarget(
      this.kind, this.functionNestingLevel, this.fileUri, this.charOffset);

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

  String get fullNameForErrors => "<jump-target>";
}

class LabelTarget implements JumpTarget {
  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  @override
  final int functionNestingLevel;

  @override
  final Uri fileUri;

  @override
  final int charOffset;

  LabelTarget(this.functionNestingLevel, this.fileUri, this.charOffset)
      : breakTarget = new JumpTarget(
            JumpTargetKind.Break, functionNestingLevel, fileUri, charOffset),
        continueTarget = new JumpTarget(
            JumpTargetKind.Continue, functionNestingLevel, fileUri, charOffset);

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
      TypeBuilder? returnTypeBuilder,
      List<TypeVariableBuilder>? typeVariableBuilders,
      AsyncMarker asyncModifier,
      Statement body,
      int fileEndOffset) {
    DartType returnType =
        returnTypeBuilder?.build(library, TypeUse.returnType) ??
            const DynamicType();
    int requiredParameterCount = 0;
    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    if (parameters != null) {
      for (FormalParameterBuilder formal in parameters!) {
        VariableDeclaration parameter = formal.build(
          library,
        );
        if (formal.isPositional) {
          positionalParameters.add(parameter);
          if (formal.isRequiredPositional) requiredParameterCount++;
        } else if (formal.isNamed) {
          namedParameters.add(parameter);
        }
      }
      namedParameters.sort((VariableDeclaration a, VariableDeclaration b) {
        return a.name!.compareTo(b.name!);
      });
    }

    List<TypeParameter>? typeParameters;
    if (typeVariableBuilders != null) {
      typeParameters = <TypeParameter>[];
      for (TypeVariableBuilder t in typeVariableBuilders) {
        typeParameters.add(t.parameter);
        // Build the bound to detect cycles in typedefs.
        t.bound?.build(library, TypeUse.typeParameterBound);
      }
    }
    return new FunctionNode(body,
        typeParameters: typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        returnType: returnType,
        asyncMarker: asyncModifier)
      ..fileOffset = charOffset
      ..fileEndOffset = fileEndOffset;
  }

  TypeBuilder toFunctionType(
      TypeBuilder returnType, NullabilityBuilder nullabilityBuilder,
      [List<TypeVariableBuilder>? typeParameters]) {
    return new FunctionTypeBuilder(returnType, typeParameters, parameters,
        nullabilityBuilder, uri, charOffset);
  }

  Scope computeFormalParameterScope(
      Scope parent, ExpressionGeneratorHelper helper) {
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
        kind: ScopeKind.formals,
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
    return new Block(<Statement>[
      if (statement is Block) ...statement.statements else statement,
      body
    ])
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

class Condition {
  final Expression expression;
  final PatternGuard? patternGuard;

  Condition(this.expression, [this.patternGuard]);

  @override
  String toString() => 'Condition($expression'
      '${patternGuard != null ? ',$patternGuard' : ''})';
}

final ExpressionOrPatternGuardCase dummyExpressionOrPatternGuardCase =
    new ExpressionOrPatternGuardCase.expression(
        TreeNode.noOffset, dummyExpression);

class ExpressionOrPatternGuardCase {
  final int caseOffset;
  final Expression? expression;
  final PatternGuard? patternGuard;

  ExpressionOrPatternGuardCase.expression(
      this.caseOffset, Expression this.expression)
      : patternGuard = null;

  ExpressionOrPatternGuardCase.patternGuard(
      this.caseOffset, PatternGuard this.patternGuard)
      : expression = null;
}

class RedirectionTarget {
  final Member target;
  final List<DartType> typeArguments;

  RedirectionTarget(this.target, this.typeArguments);
}
