// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show
        Assert,
        BlockKind,
        ConstructorReferenceContext,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        Parser,
        boolFromToken,
        doubleFromToken,
        intFromToken,
        lengthForToken,
        lengthOfSpan,
        stripSeparators,
        DeclarationKind;
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
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show Keyword, Token, TokenIsAExtension, TokenType;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show isBinaryOperator, isMinusOperator, isUserDefinableOperator;
import 'package:_fe_analyzer_shared/src/type_inference/assigned_variables.dart';
import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';
import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/names.dart' show minusName, plusName;
import 'package:kernel/src/bounds_checks.dart' hide calculateBounds;
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../api_prototype/lowering_predicates.dart';
import '../base/compiler_context.dart';
import '../base/constant_context.dart' show ConstantContext;
import '../base/crash.dart';
import '../base/extension_scope.dart';
import '../base/identifiers.dart'
    show
        Identifier,
        InitializedIdentifier,
        QualifiedName,
        QualifiedNameBuilder,
        QualifiedNameGenerator,
        QualifiedNameIdentifier,
        SimpleIdentifier;
import '../base/label_scope.dart';
import '../base/local_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/modifiers.dart' show Modifiers;
import '../base/problems.dart'
    show internalProblem, unhandled, unsupported, DebugAbort;
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_type_builder.dart';
import '../builder/invalid_type_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/method_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/property_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../builder/variable_builder.dart';
import '../builder/void_type_builder.dart';
import '../codes/cfe_codes.dart' as cfe;
import '../source/check_helper.dart';
import '../source/diet_parser.dart';
import '../source/source_library_builder.dart';
import '../source/source_member_builder.dart';
import '../source/source_property_builder.dart';
import '../source/source_type_parameter_builder.dart';
import '../source/stack_listener_impl.dart'
    show StackListenerImpl, offsetForToken;
import '../source/type_parameter_factory.dart';
import '../source/value_kinds.dart';
import '../type_inference/external_ast_helper.dart';
import '../util/helpers.dart';
import '../util/local_stack.dart';
import 'assigned_variables_impl.dart';
import 'benchmarker.dart' show Benchmarker, BenchmarkSubdivides;
import 'body_builder_context.dart';
import 'collections.dart';
import 'constness.dart' show Constness;
import 'expression_generator.dart';
import 'expression_generator_helper.dart';
import 'forest.dart' show Forest;
import 'implicit_type_argument.dart' show ImplicitTypeArgument;
import 'internal_ast.dart';
import 'kernel_variable_builder.dart';
import 'load_library_builder.dart';
import 'type_algorithms.dart' show calculateBounds;
import 'utils.dart';

part 'body_builder_helpers.dart';

abstract class BodyBuilder {
  BuildInitializersResult buildInitializers({required Token beginInitializers});

  List<Initializer> buildInitializersUnfinished({
    required Token beginInitializers,
  });

  BuildParameterInitializerResult buildParameterInitializer({
    required Token initializerToken,
  });

  BuildRedirectingFactoryMethodResult buildRedirectingFactoryMethod({
    required Token token,
    required Token? metadata,
  });

  BuildPrimaryConstructorResult buildPrimaryConstructor({
    required Token startToken,
  });

  BuildFunctionBodyResult buildFunctionBody({
    required Token startToken,
    required Token? metadata,
    required MemberKind kind,
  });

  BuildPrimaryConstructorBodyResult buildPrimaryConstructorBody({
    required Token startToken,
    required Token? metadata,
  });

  /// Builds a single [Expression] for an annotation starting at [atToken].
  Expression buildAnnotation({required Token atToken});

  /// Returns the metadata [Expression]s parsed from [metadata].
  BuildMetadataListResult buildMetadataList({required Token metadata});

  BuildFieldsResult buildFields({
    required Token startToken,
    required Token? metadata,
    required bool isTopLevel,
  });

  BuildFieldInitializerResult buildFieldInitializer({
    required Token startToken,
    required bool isLate,
  });

  BuildEnumConstantResult buildEnumConstant({required Token token});

  BuildSingleExpressionResult buildSingleExpression({
    required Token token,
    required List<ExpressionVariable> extraKnownVariables,
    required List<NominalParameterBuilder>? typeParameterBuilders,
    required List<FormalParameterBuilder>? formals,
    required int fileOffset,
  });
}

class BodyBuilderImpl extends StackListenerImpl
    implements BodyBuilder, ExpressionGeneratorHelper {
  @override
  final Forest forest;

  @override
  final SourceLibraryBuilder libraryBuilder;

  final BodyBuilderContext _context;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final LocalScope enclosingScope;

  final bool enableNative;

  // TODO(ahe): Consider renaming [uri] to 'partUri'.
  @override
  final Uri uri;

  final AssignedVariablesImpl assignedVariables;

  @override
  final TypeEnvironment typeEnvironment;

  final Benchmarker? benchmarker;

  LocalScope? formalParameterScope;

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

  /// This is set to `true` when we are parsing formals.
  bool inFormals = false;

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

  /// Level of nesting of function-type type parameters.
  ///
  /// For instance, `X` is at nesting level 1, and `Y` is at nesting level 2 in
  /// the following:
  ///
  ///    method() {
  ///      Function<X>(Function<Y extends X>(Y))? f;
  ///    }
  ///
  /// For simplicity, non-generic functions are considered generic functions
  /// with 0 type parameters.
  int _structuralParameterDepthLevel = 0;

  /// True if a type of a formal parameter is currently compiled.
  ///
  /// This variable is needed to distinguish between the type of a formal
  /// parameter and its initializer because in those two regions of code the
  /// type parameters should be interpreted differently: as structural and
  /// nominal correspondingly.
  bool _insideOfFormalParameterType = false;

  bool get inFunctionType =>
      _structuralParameterDepthLevel > 0 || _insideOfFormalParameterType;

  Link<bool> _isOrAsOperatorTypeState = const Link<bool>().prepend(false);

  bool get inIsOrAsOperatorType => _isOrAsOperatorTypeState.head;

  Link<bool> _localInitializerState = const Link<bool>().prepend(false);

  List<Initializer> _initializers = [];

  bool inCatchClause = false;

  bool inCatchBlock = false;

  int functionNestingLevel = 0;

  Statement? problemInLoopOrSwitch;

  final LocalStack<LabelScope> _labelScopes;

  final LocalStack<LabelScope?> _switchScopes = new LocalStack([]);

  @override
  ConstantContext constantContext = ConstantContext.none;

  DartType? currentLocalVariableType;

  static const Modifiers noCurrentLocalVariableModifiers = const Modifiers(-1);

  Modifiers currentLocalVariableModifiers = noCurrentLocalVariableModifiers;

  /// If non-null, records instance fields which have already been initialized
  /// and where that was.
  Map<String, int>? initializedFields;

  List<SingleTargetAnnotations>? _singleTargetAnnotations;

  List<MultiTargetAnnotations>? _multiTargetAnnotations;

  /// If the current member is an instance member in an extension declaration or
  /// an instance member or constructor in and extension type declaration,
  /// [thisVariable] holds the synthetically added variable holding the value
  /// for `this`.
  final VariableDeclaration? thisVariable;

  /// If the current member is an instance member of a non-extension
  /// declaration, and the closure context lowering experiment is enabled, this
  /// field contains the variable representing `this`.
  ThisVariable? _internalThisVariable;

  final List<TypeParameter>? thisTypeParameters;

  final LocalStack<LocalScope> _localScopes;

  Set<ExpressionVariable>? declaredInCurrentGuard;

  JumpTarget? breakTarget;

  JumpTarget? continueTarget;

  /// Index for building unique lowered names for wildcard variables.
  int wildcardVariableIndex = 0;

  @override
  ExtensionScope extensionScope;

  BodyBuilderImpl({
    required this.libraryBuilder,
    required BodyBuilderContext context,
    required this.enclosingScope,
    this.formalParameterScope,
    required this.hierarchy,
    required this.coreTypes,
    this.thisVariable,
    this.thisTypeParameters,
    required this.uri,
    required this.assignedVariables,
    required this.typeEnvironment,
    required ConstantContext constantContext,
    required this.extensionScope,
    required ThisVariable? internalThisVariable,
  }) : _context = context,
       forest = const Forest(),
       enableNative = libraryBuilder.loader.target.backendTarget.enableNative(
         libraryBuilder.importUri,
       ),
       benchmarker = libraryBuilder.loader.target.benchmarker,
       _localScopes = new LocalStack([enclosingScope]),
       _labelScopes = new LocalStack([new LabelScopeImpl()]),
       _internalThisVariable = internalThisVariable {
    this.constantContext = constantContext;
    if (formalParameterScope != null) {
      for (VariableBuilder builder in formalParameterScope!.localVariables) {
        // TODO(62401): Remove the cast when the flow analysis uses
        // [InternalExpressionVariable]s.
        assignedVariables.declare(
          (builder.variable as InternalExpressionVariable).astVariable,
        );
      }
    }
    if (thisVariable != null && context.isConstructor) {
      // The this variable is not part of the [formalParameterScope] in
      // constructors.
      // TODO(62401): Remove the cast when the flow analysis uses
      // [InternalExpressionVariable]s.
      assignedVariables.declare(
        (thisVariable as InternalExpressionVariable).astVariable,
      );
    }
    if (isClosureContextLoweringEnabled && _internalThisVariable != null) {
      assignedVariables.declare(_internalThisVariable!);
    }
  }

  @override
  void readInternalThisVariable() {
    if (isClosureContextLoweringEnabled && _internalThisVariable != null) {
      assignedVariables.read(_internalThisVariable!);
    }
  }

  @override
  ProblemReporting get problemReporting => libraryBuilder;

  @override
  CompilerContext get compilerContext => libraryBuilder.loader.target.context;

  LocalScope get _localScope => _localScopes.current;

  LabelScope get _labelScope => _labelScopes.current;

  LabelScope? get _switchScope =>
      _switchScopes.hasCurrent ? _switchScopes.current : null;

  @override
  LibraryFeatures get libraryFeatures => libraryBuilder.libraryFeatures;

  @override
  bool get isDartLibrary =>
      libraryBuilder.importUri.isScheme("dart") ||
      uri.isScheme("org-dartlang-sdk");

  bool get isClosureContextLoweringEnabled {
    return libraryBuilder
        .loader
        .target
        .backendTarget
        .flags
        .isClosureContextLoweringEnabled;
  }

  @override
  Message reportFeatureNotEnabled(
    LibraryFeature feature,
    int charOffset,
    int length,
  ) {
    return libraryBuilder.reportFeatureNotEnabled(
      feature,
      uri,
      charOffset,
      length,
    );
  }

  JumpTarget createBreakTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Break, charOffset);
  }

  JumpTarget createContinueTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Continue, charOffset);
  }

  JumpTarget createGotoTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Goto, charOffset);
  }

  void enterLocalScope(LocalScope localScope) {
    _localScopes.push(localScope);
    _labelScopes.push(new LabelScopeImpl(_labelScope));
  }

  void createAndEnterLocalScope({required LocalScopeKind kind}) {
    _localScopes.push(_localScope.createNestedScope(kind: kind));
    _labelScopes.push(new LabelScopeImpl(_labelScope));
  }

  void exitLocalScope({List<LocalScopeKind>? expectedScopeKinds}) {
    assert(
      expectedScopeKinds == null ||
          expectedScopeKinds.contains(_localScope.kind),
      "Expected the current scope to be one of the kinds "
      "${expectedScopeKinds.map((k) => "'${k}'").join(", ")}, "
      "but got '${_localScope.kind}'.",
    );
    if (isGuardScope(_localScope) && declaredInCurrentGuard != null) {
      for (VariableBuilder builder in _localScope.localVariables) {
        declaredInCurrentGuard!.remove(builder.variable);
      }
      if (declaredInCurrentGuard!.isEmpty) {
        declaredInCurrentGuard = null;
      }
    }
    _labelScopes.pop();
    _localScopes.pop();
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
    createAndEnterLocalScope(kind: LocalScopeKind.functionBody);
  }

  @override
  void beginForStatement(Token token) {
    debugEvent("beginForStatement");
    enterLoop(token.charOffset);
    createAndEnterLocalScope(kind: LocalScopeKind.forStatement);
  }

  @override
  void beginForControlFlow(Token? awaitToken, Token forToken) {
    debugEvent("beginForControlFlow");
    createAndEnterLocalScope(kind: LocalScopeKind.forStatement);
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    debugEvent("beginDoWhileStatementBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
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
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void endWhileStatementBody(Token endToken) {
    debugEvent("endWhileStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForStatementBody(Token token) {
    debugEvent("beginForStatementBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void endForStatementBody(Token endToken) {
    debugEvent("endForStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginForInBody(Token token) {
    debugEvent("beginForInBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void endForInBody(Token endToken) {
    debugEvent("endForInBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void beginElseStatement(Token token) {
    debugEvent("beginElseStatement");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void endElseStatement(Token beginToken, Token endToken) {
    debugEvent("endElseStatement");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  bool get inConstructor {
    return functionNestingLevel == 0 && _context.isConstructor;
  }

  bool get isDeclarationInstanceContext {
    return _context.isDeclarationInstanceContext;
  }

  @override
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    return _context.instanceTypeParameterAccessState;
  }

  DartType get implicitTypeArgument => const ImplicitTypeArgument();

  void _enterLocalState({bool inLateLocalInitializer = false}) {
    _localInitializerState = _localInitializerState.prepend(
      inLateLocalInitializer,
    );
  }

  void _exitLocalState() {
    _localInitializerState = _localInitializerState.tail!;
  }

  @override
  void registerVariableAssignment(ExpressionVariable variable) {
    // TODO(cstefantsova): Always pass [variable] to [assignedVariables.write]
    // when [InferenceVisitorBase.flowAnalysis] will use
    // [InternalExpressionVariable] instead of [ExpressionVariable] (that is,
    // pass it for the `Variable` type parameter of [FlowAnalysis]).
    if (variable case InternalExpressionVariable variable) {
      assignedVariables.write(variable.astVariable);
    } else {
      // Coverage-ignore-block(suite): Not run.
      assignedVariables.write(variable);
    }
  }

  @override
  VariableDeclarationImpl createVariableDeclarationForValue(
    Expression expression,
  ) {
    VariableDeclarationImpl variable = forest.createVariableDeclarationForValue(
      expression,
    );
    assignedVariables.declare(variable);
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
    } else if (node is InternalSuperInitializer) {
      return buildProblem(
        message: diag.superAsExpression,
        fileUri: uri,
        fileOffset: node.fileOffset,
        length: noLength,
      );
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
    } else {
      return unhandled("${node.runtimeType}", "toPattern", -1, uri);
    }
  }

  List<Expression> popListForValue(int n) {
    List<Expression> list = new List<Expression>.filled(
      n,
      dummyExpression,
      growable: true,
    );
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForValue();
    }
    return list;
  }

  List<Expression> popListForEffect(int n) {
    List<Expression> list = new List<Expression>.filled(
      n,
      dummyExpression,
      growable: true,
    );
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForEffect();
    }
    return list;
  }

  Statement popBlock(int count, Token openBrace, Token? closeBrace) {
    return forest.createBlock(
      offsetForToken(openBrace),
      offsetForToken(closeBrace),
      const GrowableList<Statement>().popNonNullable(
            stack,
            count,
            dummyStatement,
          ) ??
          <Statement>[],
    );
  }

  Statement? popStatementIfNotNull(Token? token) {
    return token == null ? null : popStatement(token);
  }

  Statement popStatement(Token token) {
    Object? element = pop();
    if (element is Statement) {
      return forest.wrapVariables(element);
    } else {
      return _handleStatementNotStatement(element, token);
    }
  }

  Statement _handleStatementNotStatement(Object? element, Token? token) {
    if (element is ParserRecovery) {
      return new Block(<Statement>[
        forest.createExpressionStatement(
          element.charOffset,
          ParserErrorGenerator.buildProblemExpression(
            this,
            diag.syntheticToken,
            element.charOffset,
          ),
        ),
      ])..fileOffset = element.charOffset;
    } else {
      unhandled(
        "expected statement is ${element.runtimeType}: $element",
        "popStatement",
        token?.charOffset ?? -1,
        uri,
      );
    }
  }

  Statement popStatementNoWrap([Token? token]) {
    Object? element = pop();
    if (element is Statement) {
      return element;
    } else {
      return _handleStatementNotStatement(element, token);
    }
  }

  Statement? popNullableStatement() {
    Statement? statement = pop(NullValues.Block) as Statement?;
    if (statement != null) {
      statement = forest.wrapVariables(statement);
    }
    return statement;
  }

  void enterSwitchScope() {
    _switchScopes.push(_labelScope);
  }

  void exitSwitchScope() {
    LabelScope switchScope = _switchScope!;
    LabelScope? outerSwitchScope = _switchScopes.hasPrevious
        ? _switchScopes.previous
        : null;
    if (switchScope.unclaimedForwardDeclarations != null) {
      switchScope.unclaimedForwardDeclarations!.forEach((
        String name,
        JumpTarget declaration,
      ) {
        if (outerSwitchScope == null) {
          for (Statement statement in declaration.users) {
            statement.parent!.replaceChild(
              statement,
              wrapInProblemStatement(
                statement,
                diag.labelNotFound.withArguments(label: name),
              ),
            );
          }
        } else {
          outerSwitchScope.forwardDeclareLabel(name, declaration);
        }
      });
    }
    _switchScopes.pop();
  }

  void wrapVariableInitializerInError(
    ExpressionVariable variable,
    List<LocatedMessage> context,
  ) {
    String name = variable.cosmeticName!;
    int offset = variable.fileOffset;
    Message message = diag.duplicatedDeclaration.withArguments(name: name);
    if (variable.initializer == null) {
      variable.initializer = buildProblem(
        message: message,
        fileUri: uri,
        fileOffset: offset,
        length: name.length,
        context: context,
      )..parent = variable;
    } else {
      variable.initializer = problemReporting.wrapInLocatedProblem(
        compilerContext: compilerContext,
        expression: variable.initializer!,
        message: message.withLocation(uri, offset, name.length),
        context: context,
      )..parent = variable;
    }
  }

  void declareVariable(ExpressionVariable variable, LocalScope scope) {
    String name = variable.cosmeticName!;
    Builder? existing = scope.lookupLocalVariable(name);
    if (existing != null) {
      // This reports an error for duplicated declarations in the same scope:
      // `{ var x; var x; }`
      wrapVariableInitializerInError(variable, <LocatedMessage>[
        diag.duplicatedDeclarationCause
            .withArguments(name: name)
            .withLocation(uri, existing.fileOffset, name.length),
      ]);
      return;
    }
    if (isGuardScope(scope)) {
      (declaredInCurrentGuard ??= {}).add(variable);
    }
    String variableName = variable.cosmeticName!;
    List<int>? previousOffsets = scope.declare(
      variableName,
      new VariableBuilderImpl(variableName, variable, uri),
    );
    if (previousOffsets != null && previousOffsets.isNotEmpty) {
      // This case is different from the above error. In this case, the problem
      // is using `x` before it's declared: `{ var x; { print(x); var x;
      // }}`. In this case, we want two errors, the `x` in `print(x)` and the
      // second (or innermost declaration) of `x`.
      for (int previousOffset in previousOffsets) {
        addProblem(
          diag.localVariableUsedBeforeDeclared.withArguments(
            variableName: variableName,
          ),
          previousOffset,
          variableName.length,
          context: <LocatedMessage>[
            diag.localVariableUsedBeforeDeclaredContext
                .withArguments(variableName: variableName)
                .withLocation(uri, variable.fileOffset, variableName.length),
          ],
        );
      }
    }
  }

  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(kind, functionNestingLevel, uri, charOffset);
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
    assert(
      checkState(beginToken, [
        /*arguments*/ ValueKinds.ArgumentsOrNull,
        /*suffix*/ if (periodBeforeName != null)
          unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
        /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
        /*type*/ unionOfKinds([
          ValueKinds.Generator,
          ValueKinds.QualifiedName,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    debugEvent("Metadata");
    ActualArguments? arguments = pop() as ActualArguments?;
    pushQualifiedReference(
      beginToken.next!,
      periodBeforeName,
      ConstructorReferenceContext.Const,
    );
    assert(
      checkState(beginToken, [
        /*constructor name identifier*/ ValueKinds.IdentifierOrNull,
        /*constructor name*/ ValueKinds.Name,
        /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
        /*class*/ unionOfKinds([
          ValueKinds.Generator,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    if (arguments != null) {
      push(arguments);
      _buildConstructorReferenceInvocation(
        beginToken.next!,
        beginToken.offset,
        Constness.explicitConst,
        inMetadata: true,
        inImplicitCreationContext: false,
      );
      push(popForValue());
    } else {
      pop(); // Name last identifier
      String? name = pop() as String?;
      pop(); // Type arguments (ignored, already reported by parser).
      Object? expression = pop();
      if (expression is Identifier) {
        // Coverage-ignore-block(suite): Not run.
        Identifier identifier = expression;
        expression = new UnresolvedNameGenerator(
          this,
          identifier.token,
          new Name(identifier.name, libraryBuilder.nameOrigin),
          unresolvedReadKind: UnresolvedKind.Unknown,
        );
      }

      if ((name?.isNotEmpty ?? false) && expression is Generator) {
        Token period = periodBeforeName ?? beginToken.next!.next!;
        Generator generator = expression;
        expression = generator.buildSelectorAccess(
          new PropertySelector(
            this,
            period.next!,
            new Name(name!, libraryBuilder.nameOrigin),
          ),
          period.next!.offset,
          false,
        );
      }

      ConstantContext savedConstantContext = pop() as ConstantContext;
      if (!(expression is StaticAccessGenerator &&
              expression.readTarget is Field) &&
          expression is! VariableUseGenerator &&
          // TODO(johnniwinther): Stop using the type of the generator here.
          // Ask a property instead.
          (expression is! ReadOnlyAccessGenerator ||
              // Coverage-ignore(suite): Not run.
              expression is TypeUseGenerator ||
              // Coverage-ignore(suite): Not run.
              expression is ParenthesizedExpressionGenerator)) {
        Expression value = toValue(expression);
        push(
          problemReporting.wrapInProblem(
            compilerContext: compilerContext,
            expression: value,
            message: diag.expressionNotMetadata,
            fileUri: uri,
            fileOffset: value.fileOffset,
            length: noLength,
          ),
        );
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
      push(
        const GrowableList<Expression>().popNonNullable(
              stack,
              count,
              dummyExpression,
            ) ??
            NullValues.Metadata /* Ignore parser recovery */,
      );
    }
    assert(checkState(null, [ValueKinds.AnnotationListOrNull]));
  }

  @override
  void endTopLevelFields(
    Token? augmentToken,
    Token? externalToken,
    Token? staticToken,
    Token? covariantToken,
    Token? lateToken,
    Token? varFinalOrConst,
    int count,
    Token beginToken,
    Token endToken,
  ) {
    debugEvent("TopLevelFields");
    push(count);
    assert(checkState(beginToken, [ValueKinds.Integer]));
  }

  @override
  void endFields(
    DeclarationKind kind,
    Token? abstractToken,
    Token? augmentToken,
    Token? externalToken,
    Token? staticToken,
    Token? covariantToken,
    Token? lateToken,
    Token? varFinalOrConst,
    int count,
    Token beginToken,
    Token endToken,
  ) {
    debugEvent("Fields");
    push(count);
    assert(checkState(beginToken, [ValueKinds.Integer]));
  }

  /// Returns the cached of annotations that need to be inferred and clears the
  /// cache.
  PendingAnnotations? _takePendingAnnotations() {
    if (_singleTargetAnnotations != null || _multiTargetAnnotations != null) {
      List<SingleTargetAnnotations>? singleTargetAnnotations =
          _singleTargetAnnotations;
      _singleTargetAnnotations = null;
      List<MultiTargetAnnotations>? multiTargetAnnotations =
          _multiTargetAnnotations;
      _multiTargetAnnotations = null;
      return new PendingAnnotations(
        singleTargetAnnotations,
        multiTargetAnnotations,
      );
    }
    return null;
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

  void _prepareInitializers() {
    _localScopes.push(
      _context.computeFormalParameterInitializerScope(_localScope),
    );
    if (_context.isConstructor) {
      _context.prepareInitializers();
      if (_context.formals != null) {
        for (FormalParameterBuilder formal in _context.formals!) {
          if (formal.isInitializingFormal) {
            List<Initializer> initializers;
            if (_context.isExternalConstructor) {
              initializers = <Initializer>[
                createInvalidInitializer(
                  buildProblem(
                    message: diag.externalConstructorWithFieldInitializers,
                    fileUri: uri,
                    fileOffset: formal.fileOffset,
                    length: formal.name.length,
                  ),
                ),
              ];
            } else {
              initializers = createFieldInitializer(
                formal.name,
                formal.fileOffset,
                formal.fileOffset,
                new VariableGet(formal.variable!)
                  ..fileOffset = formal.fileOffset,
                formal: formal,
              );
            }
            _initializers.addAll(initializers);
          }
        }
      }
    }
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    if (functionNestingLevel == 0) {
      _prepareInitializers();
      _localScopes.push(
        formalParameterScope ??
            new FixedLocalScope(kind: LocalScopeKind.initializers),
      );
    }
  }

  @override
  void beginInitializers(Token token) {
    debugEvent("beginInitializers");
    if (functionNestingLevel == 0) {
      _prepareInitializers();
    }
    inConstructorInitializer = true;
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    if (functionNestingLevel == 0) {
      _localScopes.push(
        formalParameterScope ??
            new FixedLocalScope(kind: LocalScopeKind.initializers),
      );
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
  void endInitializer(Token endToken) {
    assert(
      checkState(endToken, [
        unionOfKinds([
          ValueKinds.Initializer,
          ValueKinds.Generator,
          ValueKinds.Expression,
        ]),
      ]),
    );

    debugEvent("endInitializer");
    inFieldInitializer = false;
    assert(!inInitializerLeftHandSide);
    Object? node = pop();
    List<Initializer> initializers;

    if (!_context.isConstructor || _context.isExternalConstructor) {
      // An error has been reported by the parser.
      initializers = <Initializer>[];
    } else if (node is Initializer) {
      initializers = <Initializer>[node];
    } else if (node is Generator) {
      initializers = node.buildFieldInitializer(initializedFields);
    } else if (node is InternalConstructorInvocation) {
      // Coverage-ignore-block(suite): Not run.
      initializers = <Initializer>[
        // TODO(jensj): Does this offset make sense?
        buildSuperInitializer(
          false,
          node.target,
          node.arguments,
          endToken.next!.charOffset,
        ),
      ];
    } else {
      Expression value = toValue(node);
      if (value is! InvalidExpression) {
        // TODO(johnniwinther): Derive the message position from the [node]
        // and not the [value].  For instance this occurs for `super()?.foo()`
        // in an initializer list, pointing to `foo` as expecting an
        // initializer.
        value = problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: value,
          message: diag.expectedAnInitializer,
          fileUri: uri,
          fileOffset: value.fileOffset,
          length: noLength,
        );
      }
      initializers = <Initializer>[
        createInvalidInitializer(value as InvalidExpression),
      ];
    }

    _initializers.addAll(initializers);
  }

  List<Initializer> parseInitializers(Token token) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    if (!token.isEof) {
      token = parser.parseInitializers(token);
      checkEmpty(token.charOffset);
    } else {
      handleNoInitializers();
    }
    return _initializers;
  }

  Expression parseFieldInitializer(Token token) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    Token endToken = parser.parseExpression(
      parser.syntheticPreviousToken(token),
    );
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    //print(constantContext);
    Expression expression = popForValue();
    checkEmpty(endToken.charOffset);
    return expression;
  }

  Expression parseAnnotation(Token token) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    Token endToken = parser.parseMetadata(parser.syntheticPreviousToken(token));
    assert(checkState(token, [ValueKinds.Expression]));
    Expression annotation = pop() as Expression;
    checkEmpty(endToken.charOffset);
    return annotation;
  }

  ActualArguments parseArguments(Token token) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    token = parser.parseArgumentsRest(token);
    ActualArguments arguments = pop() as ActualArguments;
    checkEmpty(token.charOffset);
    return arguments;
  }

  @override
  void handleExpressionStatement(Token beginToken, Token endToken) {
    assert(
      checkState(endToken, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    debugEvent("ExpressionStatement");
    push(
      forest.createExpressionStatement(
        offsetForToken(endToken),
        popForEffect(),
      ),
    );
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    assert(
      checkState(
        beginToken,
        repeatedKind(
          unionOfKinds([ValueKinds.Argument, ValueKinds.ParserRecovery]),
          count,
        ),
      ),
    );

    List<Argument>? arguments = count == 0
        ? <Argument>[]
        : const FixedNullableList<Argument>().popNonNullable(
            stack,
            count,
            dummyArgument,
          );
    if (arguments == null) {
      push(new ParserRecovery(beginToken.charOffset));
      return;
    }
    List<Argument> argumentsOriginalOrder = new List.of(arguments);
    int firstNamedArgumentIndex = arguments.length;
    int positionalCount = 0;
    bool hasNamedBeforePositional = false;
    for (int i = 0; i < arguments.length; i++) {
      Argument argument = arguments[i];
      switch (argument) {
        case NamedArgument():
          firstNamedArgumentIndex = i < firstNamedArgumentIndex
              ? i
              : firstNamedArgumentIndex;
        case PositionalArgument():
          positionalCount++;
          if (i > firstNamedArgumentIndex) {
            hasNamedBeforePositional = true;
            if (!libraryFeatures.namedArgumentsAnywhere.isEnabled) {
              addProblem(
                diag.expectedNamedArgument,
                argument.expression.fileOffset,
                noLength,
              );
            }
          }
      }
    }
    if (firstNamedArgumentIndex < arguments.length) {
      push(
        forest.createArguments(
          beginToken.offset,
          arguments: argumentsOriginalOrder,
          hasNamedBeforePositional: hasNamedBeforePositional,
          positionalCount: positionalCount,
        ),
      );
    } else {
      // TODO(kmillikin): Find a way to avoid allocating a second list in the
      // case where there were no named arguments, which is a common one.
      // arguments have non-null Expression entries after the initial loop.
      push(
        forest.createArguments(
          beginToken.offset,
          arguments: argumentsOriginalOrder,
          hasNamedBeforePositional: hasNamedBeforePositional,
          positionalCount: argumentsOriginalOrder.length,
        ),
      );
    }
    assert(checkState(beginToken, [ValueKinds.Arguments]));
  }

  @override
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    debugEvent("ParenthesizedCondition");
    if (case_ != null) {
      Expression? guard;
      if (when != null) {
        assert(
          checkState(token, [
            unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
            unionOfKinds([ValueKinds.Expression, ValueKinds.Pattern]),
            unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
          ]),
        );
        guard = popForValue();
      }
      assert(
        checkState(token, [
          unionOfKinds([ValueKinds.Expression, ValueKinds.Pattern]),
          unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        ]),
      );
      reportIfNotEnabled(
        libraryFeatures.patterns,
        case_.charOffset,
        case_.charCount,
      );
      Pattern pattern = toPattern(pop());
      Expression expression = popForValue();
      push(
        new Condition(
          expression,
          forest.createPatternGuard(expression.fileOffset, pattern, guard),
        ),
      );
    } else {
      assert(
        checkState(token, [
          unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        ]),
      );
      push(new Condition(popForValue()));
    }
    assert(checkState(token, [ValueKinds.Condition]));
  }

  @override
  void endParenthesizedExpression(Token token) {
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
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
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
  }

  @override
  void handleParenthesizedPattern(Token token) {
    debugEvent("ParenthesizedPattern");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    // TODO(johnniwinther): Do we need a ParenthesizedPattern ?
    reportIfNotEnabled(
      libraryFeatures.patterns,
      token.charOffset,
      token.charCount,
    );

    Object? value = pop();
    if (value is Pattern) {
      push(value);
    } else {
      push(toValue(value));
    }
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    assert(
      checkState(beginToken, [
        unionOfKinds([ValueKinds.ArgumentsOrNull, ValueKinds.ParserRecovery]),
        ValueKinds.TypeArgumentsOrNull,
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Identifier,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    debugEvent("Send");
    Object? arguments = pop();
    List<TypeBuilder>? typeArgumentBuilders = pop() as List<TypeBuilder>?;
    Object receiver = pop()!;
    // Delay adding [typeArgumentBuilders] to [forest] for type aliases: They
    // must be unaliased to the type arguments of the denoted type.
    bool isInForest =
        arguments is ActualArguments &&
        typeArgumentBuilders != null &&
        (receiver is! TypeUseGenerator ||
            receiver.declaration is! TypeAliasBuilder);
    TypeArguments? typeArguments;
    if (isInForest) {
      List<DartType> types = buildDartTypeArguments(
        typeArgumentBuilders,
        TypeUse.invocationTypeArgument,
        allowPotentiallyConstantType: false,
      );
      typeArguments = new TypeArguments(types);
    } else {
      assert(
        typeArgumentBuilders == null ||
            (receiver is TypeUseGenerator &&
                receiver.declaration is TypeAliasBuilder),
      );
    }
    if (receiver is ParserRecovery || arguments is ParserRecovery) {
      push(new ParserErrorGenerator(this, beginToken, diag.syntheticToken));
    } else if (receiver is Identifier) {
      Name name = new Name(receiver.name, libraryBuilder.nameOrigin);
      if (arguments == null) {
        push(new PropertySelector(this, beginToken, name));
      } else {
        push(
          new InvocationSelector(
            this,
            beginToken,
            name,
            typeArgumentBuilders,
            typeArguments,
            arguments as ActualArguments,
            isTypeArgumentsInForest: isInForest,
          ),
        );
      }
    } else if (arguments == null) {
      push(receiver);
    } else {
      push(
        finishSend(
          receiver,
          typeArgumentBuilders,
          typeArguments,
          arguments as ActualArguments,
          beginToken.charOffset,
          isTypeArgumentsInForest: isInForest,
        ),
      );
    }
    assert(
      checkState(beginToken, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
          ValueKinds.Selector,
        ]),
      ]),
    );
  }

  @override
  Expression_Generator_Initializer finishSend(
    Object receiver,
    List<TypeBuilder>? typeArgumentBuilders,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int charOffset, {
    bool isTypeArgumentsInForest = false,
  }) {
    if (receiver is Generator) {
      return receiver.doInvocation(
        offset: charOffset,
        typeArgumentBuilders: typeArgumentBuilders,
        typeArguments: typeArguments,
        arguments: arguments,
        isTypeArgumentsInForest: isTypeArgumentsInForest,
      );
    } else {
      return forest.createExpressionInvocation(
        charOffset,
        toValue(receiver),
        typeArguments,
        arguments,
      );
    }
  }

  @override
  void beginCascade(Token token) {
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    debugEvent("beginCascade");
    Expression expression = popForValue();
    if (expression is Cascade) {
      push(expression);
      push(
        _createReadOnlyVariableAccess(
          expression.variable,
          token,
          expression.fileOffset,
          null,
          ReadOnlyAccessKind.LetVariable,
        ),
      );
    } else {
      bool isNullAware = token.isA(TokenType.QUESTION_PERIOD_PERIOD);
      VariableDeclaration variable = createVariableDeclarationForValue(
        expression,
      );
      push(
        new Cascade(variable, isNullAware: isNullAware)
          ..fileOffset = expression.fileOffset,
      );
      push(
        _createReadOnlyVariableAccess(
          variable,
          token,
          expression.fileOffset,
          null,
          ReadOnlyAccessKind.LetVariable,
        ),
      );
    }
    assert(
      checkState(token, [
        ValueKinds.Generator,
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
  }

  @override
  void endCascade() {
    assert(
      checkState(null, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        ValueKinds.Expression,
      ]),
    );
    debugEvent("endCascade");
    Expression expression = popForEffect();
    Cascade cascadeReceiver = pop() as Cascade;
    cascadeReceiver.addCascadeExpression(expression);
    push(cascadeReceiver);
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    debugEvent("beginCaseExpression");

    // Scope of the preceding case head or a sentinel if it's the first head.
    exitLocalScope(expectedScopeKinds: const [LocalScopeKind.caseHead]);

    createAndEnterLocalScope(kind: LocalScopeKind.caseHead);
    super.push(constantContext);
    if (!libraryFeatures.patterns.isEnabled) {
      constantContext = ConstantContext.inferred;
    }
    assert(checkState(caseKeyword, [ValueKinds.ConstantContext]));
  }

  @override
  void endCaseExpression(Token caseKeyword, Token? when, Token colon) {
    debugEvent("endCaseExpression");
    assert(
      checkState(colon, [
        if (when != null)
          unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
        ValueKinds.ConstantContext,
      ]),
    );

    Expression? guard;
    if (when != null) {
      guard = popForValue();
    }
    Object? value = pop();
    constantContext = pop() as ConstantContext;
    assert(
      _localScopes.previous.kind == LocalScopeKind.switchBlock,
      "Expected to have scope kind ${LocalScopeKind.switchBlock}, "
      "but got ${_localScopes.previous.kind}.",
    );
    if (value is Pattern) {
      super.push(
        new ExpressionOrPatternGuardCase.patternGuard(
          caseKeyword.charOffset,
          forest.createPatternGuard(caseKeyword.charOffset, value, guard),
        ),
      );
    } else if (guard != null) {
      super.push(
        new ExpressionOrPatternGuardCase.patternGuard(
          caseKeyword.charOffset,
          forest.createPatternGuard(
            caseKeyword.charOffset,
            toPattern(value),
            guard,
          ),
        ),
      );
    } else {
      Expression expression = toValue(value);
      super.push(
        new ExpressionOrPatternGuardCase.expression(
          caseKeyword.charOffset,
          expression,
        ),
      );
    }
    assert(checkState(colon, [ValueKinds.ExpressionOrPatternGuardCase]));
  }

  @override
  void beginBinaryExpression(Token token) {
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    bool isAnd = token.isA(TokenType.AMPERSAND_AMPERSAND);
    if (isAnd || token.isA(TokenType.BAR_BAR)) {
      Expression lhs = popForValue();
      // This is matched by the call to [endNode] in
      // [doLogicalExpression].
      if (isAnd) {
        assignedVariables.beginNode();
      }
      push(lhs);
    }
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
  }

  @override
  void handleDotAccess(Token token, Token endToken, bool isNullAware) {
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Selector,
        ]),
      ]),
    );
    debugEvent("DotAccess");
    if (isNullAware) {
      doIfNotNull(token);
    } else {
      doDotExpression(token);
    }
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
  }

  @override
  void handleCascadeAccess(Token token, Token endToken, bool isNullAware) {
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Selector,
        ]),
      ]),
    );
    debugEvent("CascadeAccess");
    doCascadeExpression(token);
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
  }

  @override
  void endBinaryExpression(Token token, Token endToken) {
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Selector,
        ]),
      ]),
    );
    debugEvent("BinaryExpression");
    if (token.isA(TokenType.AMPERSAND_AMPERSAND) ||
        token.isA(TokenType.BAR_BAR)) {
      doLogicalExpression(token);
    } else if (token.isA(TokenType.QUESTION_QUESTION)) {
      doIfNull(token);
    } else {
      doBinaryExpression(token);
    }
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
  }

  @override
  void beginPattern(Token token) {
    debugEvent("Pattern");
    if (token.lexeme == "||") {
      createAndEnterLocalScope(kind: LocalScopeKind.orPatternRight);
    } else {
      createAndEnterLocalScope(kind: LocalScopeKind.pattern);
    }
  }

  @override
  void endPattern(Token token) {
    debugEvent("Pattern");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    Object pattern = pop()!;
    LocalScopeKind scopeKind = _localScope.kind;

    exitLocalScope(
      expectedScopeKinds: const [
        LocalScopeKind.pattern,
        LocalScopeKind.orPatternRight,
      ],
    );

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
    bool enclosingScopeIsPatternScope =
        _localScope.kind == LocalScopeKind.pattern ||
        _localScope.kind == LocalScopeKind.orPatternRight;
    if (scopeKind != LocalScopeKind.orPatternRight &&
        enclosingScopeIsPatternScope) {
      if (pattern is Pattern) {
        for (VariableDeclaration variable in pattern.declaredVariables) {
          declareVariable(variable, _localScope);
        }
      }
    }

    push(pattern);
  }

  @override
  void beginBinaryPattern(Token token) {
    debugEvent("BinaryPattern");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );

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
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.pattern]);

      createAndEnterLocalScope(kind: LocalScopeKind.pattern);
      push(lhsPattern);
    }
  }

  @override
  void endBinaryPattern(Token token) {
    debugEvent("BinaryPattern");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    reportIfNotEnabled(
      libraryFeatures.patterns,
      token.charOffset,
      token.charCount,
    );
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
            leftVariable.name!: leftVariable,
        };
        for (VariableDeclaration rightVariable in right.declaredVariables) {
          if (!leftVariablesByName.containsKey(rightVariable.name)) {
            addProblem(
              diag.missingVariablePattern.withArguments(
                variableName: rightVariable.name!,
              ),
              left.fileOffset,
              noLength,
            );
          }
        }
        Map<String, VariableDeclaration> rightVariablesByName = {
          for (VariableDeclaration rightVariable in right.declaredVariables)
            rightVariable.name!: rightVariable,
        };
        for (VariableDeclaration leftVariable in left.declaredVariables) {
          if (!rightVariablesByName.containsKey(leftVariable.name)) {
            addProblem(
              diag.missingVariablePattern.withArguments(
                variableName: leftVariable.name!,
              ),
              right.fileOffset,
              noLength,
            );
          }
        }
        List<VariableDeclaration> jointVariables = [
          for (VariableDeclaration leftVariable in left.declaredVariables)
            forest.createVariableDeclaration(
              leftVariable.fileOffset,
              leftVariable.name!,
            ),
        ];
        for (VariableDeclaration variable in jointVariables) {
          declareVariable(variable, _localScope);
          assignedVariables.declare(variable);
        }
        push(
          forest.createOrPattern(
            token.charOffset,
            left,
            right,
            orPatternJointVariables: jointVariables,
          ),
        );
        break;
      // Coverage-ignore(suite): Not run.
      default:
        internalProblem(
          diag.internalProblemUnhandled.withArguments(
            what: operator,
            where: 'endBinaryPattern',
          ),
          token.charOffset,
          uri,
        );
    }
  }

  void doBinaryExpression(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression right = popForValue();
    Object? left = pop();
    int fileOffset = offsetForToken(token);
    String operator = token.stringValue!;
    bool isNot = identical("!=", operator);
    if (isNot || identical("==", operator)) {
      if (left is Generator) {
        push(left.buildEqualsOperation(token, right, isNot: isNot));
      } else {
        assert(left is Expression);
        push(
          forest.createEquals(
            fileOffset,
            left as Expression,
            right,
            isNot: isNot,
          ),
        );
      }
    } else {
      Name name = new Name(operator);
      if (!isBinaryOperator(operator) && !isMinusOperator(operator)) {
        if (isUserDefinableOperator(operator)) {
          push(
            buildProblem(
              message: diag.notBinaryOperator.withArguments(token: token),
              fileUri: uri,
              fileOffset: token.charOffset,
              length: token.length,
            ),
          );
        } else {
          push(
            buildProblem(
              message: diag.invalidOperator.withArguments(lexeme: token),
              fileUri: uri,
              fileOffset: token.charOffset,
              length: token.length,
            ),
          );
        }
      } else if (left is Generator) {
        push(left.buildBinaryOperation(token, name, right));
      } else {
        assert(left is Expression);
        push(forest.createBinary(fileOffset, left as Expression, name, right));
      }
    }
    assert(checkState(token, <ValueKind>[ValueKinds.Expression]));
  }

  /// Handle `a && b` and `a || b`.
  void doLogicalExpression(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression argument = popForValue();
    Expression receiver = pop() as Expression;
    Expression logicalExpression = forest.createLogicalExpression(
      offsetForToken(token),
      receiver,
      token.stringValue!,
      argument,
    );
    push(logicalExpression);
    if (token.isA(TokenType.AMPERSAND_AMPERSAND)) {
      // This is matched by the call to [beginNode] in
      // [beginBinaryExpression].
      assignedVariables.endNode(logicalExpression);
    }
    assert(checkState(token, <ValueKind>[ValueKinds.Expression]));
  }

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression b = popForValue();
    Expression a = popForValue();
    push(new IfNullExpression(a, b)..fileOffset = offsetForToken(token));
    assert(checkState(token, <ValueKind>[ValueKinds.Expression]));
  }

  /// Handle `a?.b(...)`.
  void doIfNotNull(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Selector,
        ]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
    Object? send = pop();
    if (send is Selector) {
      push(send.withReceiver(pop(), token.charOffset, isNullAware: true));
    } else {
      pop();
      token = token.next!;
      push(
        buildProblem(
          message: diag.expectedIdentifier.withArguments(lexeme: token),
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
        ),
      );
    }
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
  }

  void doDotExpression(Token token) {
    assert(
      checkState(token, <ValueKind>[
        /* after . */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Selector,
        ]),
        /* before . */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
    Object? send = pop();
    if (send is Selector) {
      Object? receiver = pop();
      push(send.withReceiver(receiver, token.charOffset));
    } else if (send is IncompleteErrorGenerator) {
      // Pop the "receiver" and push the error.
      pop();
      push(send);
    } else {
      // Pop the "receiver" and push the error.
      pop();
      token = token.next!;
      push(
        buildProblem(
          message: diag.expectedIdentifier.withArguments(lexeme: token),
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
        ),
      );
    }
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
  }

  void doCascadeExpression(Token token) {
    assert(
      checkState(token, <ValueKind>[
        /* after .. */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Selector,
        ]),
        /* before .. */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
    Object? send = pop();
    if (send is Selector) {
      Object? receiver = popForValue();
      push(send.withReceiver(receiver, token.charOffset));
    }
    // Coverage-ignore(suite): Not run.
    else if (send is IncompleteErrorGenerator) {
      // Pop the "receiver" and push the error.
      pop();
      push(send);
    } else {
      // Pop the "receiver" and push the error.
      pop();
      token = token.next!;
      push(
        buildProblem(
          message: diag.expectedIdentifier.withArguments(lexeme: token),
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
        ),
      );
    }
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
  }

  @override
  InvalidExpression buildUnresolvedError(
    String name,
    int charOffset, {
    bool isSuper = false,
    required UnresolvedKind kind,
    int? length,
    bool errorHasBeenReported = false,
  }) {
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
    LocatedMessage? message;
    switch (kind) {
      case UnresolvedKind.Unknown:
        assert(!isSuper);
        message = diag.nameNotFound
            .withArguments(name: name)
            .withLocation(uri, charOffset, length);
        break;
      case UnresolvedKind.Member:
        message = warnUnresolvedMember(
          kernelName,
          charOffset,
          isSuper: isSuper,
          reportWarning: false,
        ).withLocation(uri, charOffset, length);
        break;
      case UnresolvedKind.Getter:
        message = warnUnresolvedGet(
          kernelName,
          charOffset,
          isSuper: isSuper,
          reportWarning: false,
        ).withLocation(uri, charOffset, length);
        break;
      case UnresolvedKind.Setter:
        message = warnUnresolvedSet(
          kernelName,
          charOffset,
          isSuper: isSuper,
          reportWarning: false,
        ).withLocation(uri, charOffset, length);
        break;
      case UnresolvedKind.Method:
        message = warnUnresolvedMethod(
          kernelName,
          charOffset,
          isSuper: isSuper,
          reportWarning: false,
        ).withLocation(uri, charOffset, length);
        break;
      case UnresolvedKind.Constructor:
        message = warnUnresolvedConstructor(
          kernelName,
          isSuper: isSuper,
        ).withLocation(uri, charOffset, length);
        break;
    }
    return buildProblem(
      message: message.messageObject,
      fileUri: uri,
      fileOffset: message.charOffset,
      length: message.length,
      errorHasBeenReported: errorHasBeenReported,
    );
  }

  InvalidExpression _buildProblemFromLocatedMessage(LocatedMessage message) {
    return buildProblem(
      message: message.messageObject,
      fileUri: uri,
      fileOffset: message.charOffset,
      length: message.length,
    );
  }

  Message warnUnresolvedMember(
    Name name,
    int charOffset, {
    bool isSuper = false,
    bool reportWarning = true,
    List<LocatedMessage>? context,
  }) {
    Message message = isSuper
        ?
          // Coverage-ignore(suite): Not run.
          diag.superclassHasNoMember.withArguments(memberName: name.text)
        : diag.memberNotFound.withArguments(name: name.text);
    if (reportWarning) {
      // Coverage-ignore-block(suite): Not run.
      addProblemErrorIfConst(
        message,
        charOffset,
        name.text.length,
        context: context,
      );
    }
    return message;
  }

  Message warnUnresolvedGet(
    Name name,
    int charOffset, {
    bool isSuper = false,
    bool reportWarning = true,
    List<LocatedMessage>? context,
  }) {
    Message message = isSuper
        ? diag.superclassHasNoGetter.withArguments(getterName: name.text)
        : diag.getterNotFound.withArguments(name: name.text);
    if (reportWarning) {
      // Coverage-ignore-block(suite): Not run.
      addProblemErrorIfConst(
        message,
        charOffset,
        name.text.length,
        context: context,
      );
    }
    return message;
  }

  Message warnUnresolvedSet(
    Name name,
    int charOffset, {
    bool isSuper = false,
    bool reportWarning = true,
    List<LocatedMessage>? context,
  }) {
    Message message = isSuper
        ? diag.superclassHasNoSetter.withArguments(setterName: name.text)
        : diag.setterNotFound.withArguments(name: name.text);
    if (reportWarning) {
      // Coverage-ignore-block(suite): Not run.
      addProblemErrorIfConst(
        message,
        charOffset,
        name.text.length,
        context: context,
      );
    }
    return message;
  }

  Message warnUnresolvedMethod(
    Name name,
    int charOffset, {
    bool isSuper = false,
    bool reportWarning = true,
    List<LocatedMessage>? context,
  }) {
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
        ? diag.superclassHasNoMethod.withArguments(name: name.text)
        : diag.methodNotFound.withArguments(name: name.text);
    if (reportWarning) {
      // Coverage-ignore-block(suite): Not run.
      addProblemErrorIfConst(message, charOffset, length, context: context);
    }
    return message;
  }

  Message warnUnresolvedConstructor(Name name, {bool isSuper = false}) {
    Message message = isSuper
        ?
          // Coverage-ignore(suite): Not run.
          diag.superclassHasNoConstructor.withArguments(
            constructorName: name.text,
          )
        : diag.constructorNotFound.withArguments(name: name.text);
    return message;
  }

  @override
  Member? lookupSuperMember(Name name, {bool isSetter = false}) {
    return _context.lookupSuperMember(hierarchy, name, isSetter: isSetter);
  }

  @override
  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  ) {
    return _context.lookupSuperConstructor(name, accessingLibrary);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    if (context.isScopeReference) {
      assert(
        !inInitializerLeftHandSide ||
            _localScopes.current == enclosingScope ||
            _localScopes.previous == enclosingScope,
      );
      // This deals with this kind of initializer: `C(a) : a = a;`
      LocalScope scope = inInitializerLeftHandSide
          ? enclosingScope
          : this._localScope;
      push(scopeLookup(scope, token));
    } else {
      if (!context.inDeclaration &&
          constantContext != ConstantContext.none &&
          !context.allowedInConstantExpression) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(diag.notAConstantExpression, token.charOffset, token.length);
      }
      if (token.isSynthetic) {
        push(new ParserRecovery(offsetForToken(token)));
      } else {
        push(new SimpleIdentifier(token));
      }
    }
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Identifier,
          ValueKinds.Generator,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
  }

  @override
  void registerVariableRead(ExpressionVariable variable) {
    if (variable case InternalExpressionVariable variable) {
      if (!variable.isLocalFunction && !variable.isWildcard) {
        assignedVariables.read(variable.astVariable);
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      if (!variable.isWildcard) {
        assignedVariables.read(variable);
      }
    }
  }

  /// Helper method to create a [VariableGet] of the [variable] using
  /// [charOffset] as the file offset.
  @override
  VariableGet createVariableGet(ExpressionVariable variable, int charOffset) {
    registerVariableRead(variable);
    return new VariableGet(variable)..fileOffset = charOffset;
  }

  /// Helper method to create a [ReadOnlyAccessGenerator] on the [variable]
  /// using [token] and [charOffset] for offset information and [name]
  /// for `ExpressionGenerator._plainNameForRead`.
  ReadOnlyAccessGenerator _createReadOnlyVariableAccess(
    ExpressionVariable variable,
    Token token,
    int charOffset,
    String? name,
    ReadOnlyAccessKind kind,
  ) {
    return new ReadOnlyAccessGenerator(
      this,
      token,
      createVariableGet(variable, charOffset),
      name ?? '',
      kind,
    );
  }

  @override
  bool isDeclaredInEnclosingCase(ExpressionVariable variable) {
    return declaredInCurrentGuard?.contains(variable) ?? false;
  }

  bool isGuardScope(LocalScope scope) =>
      scope.kind == LocalScopeKind.caseHead ||
      scope.kind == LocalScopeKind.ifCaseHead;

  /// Look up the name from [nameToken] in [scope] using [nameToken] as location
  /// information.
  Generator scopeLookup(LocalScope scope, Token nameToken) {
    String name = nameToken.lexeme;
    int nameOffset = nameToken.charOffset;
    LookupResult? lookupResult = scope.lookup(name, fileOffset: nameOffset);
    return processLookupResult(
      lookupResult: lookupResult,
      name: name,
      nameToken: nameToken,
      nameOffset: nameOffset,
      forStatementScope: scope.kind == LocalScopeKind.forStatement,
    );
  }

  @override
  Generator processLookupResult({
    required LookupResult? lookupResult,
    required String name,
    required Token nameToken,
    required int nameOffset,
    PrefixBuilder? prefix,
    Token? prefixToken,
    required bool forStatementScope,
  }) {
    if (nameToken.isSynthetic) {
      return new ParserErrorGenerator(this, nameToken, diag.syntheticToken);
    }
    if (lookupResult != null && lookupResult.isInvalidLookup) {
      return new DuplicateDeclarationGenerator(
        this,
        nameToken,
        lookupResult,
        new Name(name, libraryBuilder.nameOrigin),
        name.length,
      );
    }

    bool isQualified = prefixToken != null;
    bool mustBeConst =
        constantContext != ConstantContext.none && !inInitializerLeftHandSide;
    bool hasThisAccess;
    if (inInitializerLeftHandSide) {
      // The left hand side of an initializer, like 'x' in:
      //
      //    class C {
      //      C() : x = 0;
      //    }
      //
      // must always refer to field in the encoding class. By assuming we
      // have `this` access, the error reported in when creating the
      // initializer will mention this.
      // TODO(johnniwinther): Could we just report that error here instead?
      hasThisAccess = true;
    } else {
      // TODO(johnniwinther): This should exclude identifies occurring in
      //  metadata.
      hasThisAccess = isDeclarationInstanceContext && !inFormals;
      if (hasThisAccess) {
        if (isQualified) {
          hasThisAccess = false;
        } else if (inFieldInitializer) {
          if (!inLateFieldInitializer ||
              _context.isExtensionDeclaration ||
              _context.isExtensionTypeDeclaration) {
            hasThisAccess = false;
          }
        }
      }
    }

    if (lookupResult == null) {
      Name memberName = new Name(name, libraryBuilder.nameOrigin);
      if (hasThisAccess) {
        if (mustBeConst) {
          return new IncompleteErrorGenerator(
            this,
            nameToken,
            diag.notAConstantExpression,
          );
        }
        // This is an implicit access on 'this'.
        return new ThisPropertyAccessGenerator(
          this,
          nameToken,
          memberName,
          thisVariable: thisVariable,
        );
      } else {
        // [name] is unresolved.
        return new UnresolvedNameGenerator(
          this,
          nameToken,
          memberName,
          unresolvedReadKind: UnresolvedKind.Unknown,
        );
      }
    }
    Builder? getable = lookupResult.getable;
    Builder? setable = lookupResult.setable;
    if (getable != null) {
      if (getable is InvalidBuilder) {
        // TODO(johnniwinther): Create an `InvalidGenerator` instead.
        return new TypeUseGenerator(
          this,
          nameToken,
          getable,
          prefixToken != null
              ? new QualifiedTypeName(
                  prefixToken.lexeme,
                  prefixToken.charOffset,
                  name,
                  nameOffset,
                )
              : new IdentifierTypeName(name, nameOffset),
        );
      } else if (getable is VariableBuilder) {
        if (mustBeConst &&
            !getable.isConst &&
            !(_context.isConstructor && inFieldInitializer) &&
            !libraryFeatures.constFunctions.isEnabled) {
          return new IncompleteErrorGenerator(
            this,
            nameToken,
            diag.notAConstantExpression,
          );
        }
        ExpressionVariable variable = getable.variable!;
        // TODO(johnniwinther): The handling of for-in variables should be
        //  done through the builder.
        if (forStatementScope &&
            variable.isAssignable &&
            variable.isLate &&
            variable.isFinal) {
          return new ForInLateFinalVariableUseGenerator(
            this,
            nameToken,
            variable,
          );
        } else if (!getable.isAssignable ||
            (variable.isFinal && forStatementScope)) {
          return _createReadOnlyVariableAccess(
            variable,
            nameToken,
            nameOffset,
            name,
            variable.isConst
                ? ReadOnlyAccessKind.ConstVariable
                : ReadOnlyAccessKind.FinalVariable,
          );
        } else {
          return new VariableUseGenerator(this, nameToken, variable);
        }
      } else if (getable.isDeclarationInstanceMember) {
        if (!inInitializerLeftHandSide && inFieldInitializer) {
          // We cannot access a class instance member in an initializer of a
          // field.
          //
          // For instance
          //
          //     class M {
          //       int foo = bar; // Implicit this access on `bar`.
          //       int bar;
          //       int baz = 4;
          //       M() : bar = baz; // Implicit this access on `baz`.
          //     }
          //
          // We can if it's late, but not if we're in an extension (type), even
          // if it's late.
          if (!inLateFieldInitializer ||
              _context.isExtensionDeclaration ||
              _context.isExtensionTypeDeclaration) {
            return new IncompleteErrorGenerator(
              this,
              nameToken,
              diag.thisAccessInFieldInitializer.withArguments(name: name),
            );
          }
        }

        if (mustBeConst && !libraryFeatures.constFunctions.isEnabled) {
          return new IncompleteErrorGenerator(
            this,
            nameToken,
            diag.notAConstantExpression,
          );
        }

        Name memberName = new Name(name, libraryBuilder.nameOrigin);
        if (hasThisAccess) {
          // This is an implicit access on 'this'.
          if (getable.isExtensionInstanceMember && thisVariable != null) {
            ExtensionBuilder extensionBuilder =
                getable.parent as ExtensionBuilder;
            if (getable is PropertyBuilder && getable.hasConcreteField) {
              getable = null;
            }
            if (setable != null &&
                ((setable is PropertyBuilder && setable.hasConcreteField) ||
                    setable.isStatic)) {
              setable = null;
            }
            if (getable == null && setable == null) {
              return new UnresolvedNameGenerator(
                this,
                nameToken,
                memberName,
                unresolvedReadKind: UnresolvedKind.Unknown,
              );
            }
            return new ExtensionInstanceAccessGenerator.fromBuilder(
              this,
              nameToken,
              extensionBuilder.extension,
              memberName,
              thisVariable!,
              thisTypeParameters,
              getable as MemberBuilder?,
              setable as MemberBuilder?,
            );
          }
          return new ThisPropertyAccessGenerator(
            this,
            nameToken,
            memberName,
            thisVariable: thisVariable,
          );
        } else {
          // [name] is an instance member but this is not an instance context.
          return new UnresolvedNameGenerator(
            this,
            nameToken,
            memberName,
            unresolvedReadKind: UnresolvedKind.Unknown,
          );
        }
      } else if (getable is TypeDeclarationBuilder) {
        return new TypeUseGenerator(
          this,
          nameToken,
          getable,
          prefixToken != null
              ? new QualifiedTypeName(
                  prefixToken.lexeme,
                  prefixToken.charOffset,
                  name,
                  nameOffset,
                )
              : new IdentifierTypeName(name, nameOffset),
        );
      } else if (getable is MemberBuilder) {
        assert(
          getable.isStatic || getable.isTopLevel,
          "Unexpected getable: $getable",
        );
        assert(
          setable == null ||
              setable.isStatic ||
              // Coverage-ignore(suite): Not run.
              setable.isTopLevel,
          "Unexpected setable: $setable",
        );

        if (mustBeConst &&
            !(getable is PropertyBuilder && getable.hasConstField) &&
            !(getable is MethodBuilder && getable.isRegularMethod) &&
            !libraryFeatures.constFunctions.isEnabled) {
          return new IncompleteErrorGenerator(
            this,
            nameToken,
            diag.notAConstantExpression,
          );
        }
        return new StaticAccessGenerator.fromBuilder(
          this,
          new Name(name, libraryBuilder.nameOrigin),
          nameToken,
          getable,
          setable as MemberBuilder?,
        );
      } else if (getable is PrefixBuilder) {
        // Wildcard import prefixes are non-binding and cannot be used.
        if (libraryFeatures.wildcardVariables.isEnabled && getable.isWildcard) {
          // TODO(kallentu): Provide a helpful error related to wildcard
          //  prefixes.
          return new UnresolvedNameGenerator(
            this,
            nameToken,
            new Name(getable.name, libraryBuilder.nameOrigin),
            unresolvedReadKind: UnresolvedKind.Unknown,
          );
        }
        return new PrefixUseGenerator(this, nameToken, getable);
      } else if (getable is LoadLibraryBuilder) {
        return new LoadLibraryGenerator(this, nameToken, getable);
      }
    } else {
      if (setable is InvalidBuilder) {
        // Coverage-ignore-block(suite): Not run.
        return new TypeUseGenerator(
          this,
          nameToken,
          setable,
          prefixToken != null
              ? new QualifiedTypeName(
                  prefixToken.lexeme,
                  prefixToken.charOffset,
                  name,
                  nameOffset,
                )
              : new IdentifierTypeName(name, nameOffset),
        );
      } else if (setable!.isDeclarationInstanceMember) {
        Name memberName = new Name(name, libraryBuilder.nameOrigin);
        if (hasThisAccess) {
          if (setable.isExtensionInstanceMember && thisVariable != null) {
            ExtensionBuilder extensionBuilder =
                setable.parent as ExtensionBuilder;
            if (setable is PropertyBuilder && setable.hasConcreteField) {
              setable = null;
            }
            if (setable == null) {
              // Coverage-ignore-block(suite): Not run.
              return new UnresolvedNameGenerator(
                this,
                nameToken,
                memberName,
                unresolvedReadKind: UnresolvedKind.Unknown,
              );
            }
            return new ExtensionInstanceAccessGenerator.fromBuilder(
              this,
              nameToken,
              extensionBuilder.extension,
              memberName,
              thisVariable!,
              thisTypeParameters,
              getable as MemberBuilder?,
              setable as MemberBuilder?,
            );
          }
          // This is an implicit access on 'this'.
          return new ThisPropertyAccessGenerator(
            this,
            nameToken,
            memberName,
            thisVariable: thisVariable,
          );
        } else {
          // [name] is an instance member but this is not an instance context.
          return new UnresolvedNameGenerator(
            this,
            nameToken,
            memberName,
            unresolvedReadKind: UnresolvedKind.Unknown,
          );
        }
      } else if (setable is MemberBuilder) {
        assert(
          setable.isStatic ||
              // Coverage-ignore(suite): Not run.
              setable.isTopLevel,
          "Unexpected setable: $setable",
        );
        return new StaticAccessGenerator.fromBuilder(
          this,
          new Name(name, libraryBuilder.nameOrigin),
          nameToken,
          null,
          setable,
        );
      }
    }

    // Coverage-ignore(suite): Not run.
    return new UnresolvedNameGenerator(
      this,
      nameToken,
      new Name(name, libraryBuilder.nameOrigin),
      unresolvedReadKind: UnresolvedKind.Unknown,
    );
  }

  @override
  void handleQualified(Token period) {
    // handleQualified is called after two handleIdentifier calls.
    // This happens via one of these:
    // * ComplexTypeInfo.parseType (with context prefixedTypeReference)
    // * parseLibraryName (with context libraryName)
    // * parsePartOf (with context partName)
    // * parseMetadata (with context metadataReference)
    // * parseMethod (with context methodDeclaration)
    // * parseFactoryMethod (with context methodDeclaration)
    // * parseConstructorReference (with context constructorReference)
    // Of these ComplexTypeInfo.parseType, parseMetadata, parseFactoryMethod and
    // parseConstructorReference has a context where isScopeReference is true,
    // meaning handleIdentifier pushes a scopeLookup which returns either a
    // Generator or a Builder. In the below we thus assume those are the two
    // prefixes we'll have.
    debugEvent("handleQualified");
    assert(
      checkState(period, [
        /* suffix */ ValueKinds.IdentifierOrParserRecovery,
        /* prefix */ unionOfKinds([ValueKinds.Generator]),
      ]),
    );

    Object? node = pop();
    Object? qualifier = pop();
    if (node is ParserRecovery) {
      push(node);
    } else {
      SimpleIdentifier identifier = node as SimpleIdentifier;
      if (qualifier is Generator) {
        push(identifier.withGeneratorQualifier(qualifier));
      }
      // Coverage-ignore(suite): Not run.
      else if (qualifier is Builder) {
        push(identifier.withBuilderQualifier(qualifier));
      } else {
        unhandled(
          "qualifier is ${qualifier.runtimeType}",
          "handleQualified",
          period.charOffset,
          uri,
        );
      }
    }
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("handleStringPart");
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
      List<Object>? parts = const FixedNullableList<Object>().popNonNullable(
        stack,
        count,
        /* dummyValue = */ 0,
      );
      if (parts == null) {
        // Coverage-ignore-block(suite): Not run.
        push(new ParserRecovery(endToken.charOffset));
        return;
      }
      Token first = parts.first as Token;
      Token last = parts.last as Token;
      Quote quote = analyzeQuote(first.lexeme);
      List<Expression> expressions = <Expression>[];
      // Contains more than just \' or \".
      if (first.lexeme.length > 1) {
        String value = unescapeFirstStringPart(
          first.lexeme,
          quote,
          first,
          this,
        );
        if (value.isNotEmpty) {
          expressions.add(
            forest.createStringLiteral(offsetForToken(first), value),
          );
        }
      }
      for (int i = 1; i < parts.length - 1; i++) {
        Object part = parts[i];
        if (part is Token) {
          if (part.lexeme.length != 0) {
            String value = unescape(part.lexeme, quote, part, this);
            expressions.add(
              forest.createStringLiteral(offsetForToken(part), value),
            );
          }
        } else {
          expressions.add(toValue(part));
        }
      }
      // Contains more than just \' or \".
      if (last.lexeme.length > 1) {
        String value = unescapeLastStringPart(
          last.lexeme,
          quote,
          last,
          last.isSynthetic,
          this,
        );
        if (value.isNotEmpty) {
          expressions.add(
            forest.createStringLiteral(offsetForToken(last), value),
          );
        }
      }
      push(
        forest.createStringConcatenation(offsetForToken(endToken), expressions),
      );
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
  // Coverage-ignore(suite): Not run.
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleAdjacentStringLiterals(Token startToken, int literalCount) {
    debugEvent("AdjacentStringLiterals");
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
    push(
      forest.createStringConcatenation(
        offsetForToken(startToken),
        expressions ?? parts,
      ),
    );
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    int? value = intFromToken(token, hasSeparators: false);
    // Postpone parsing of literals resulting in a negative value
    // (hex literals >= 2^63). These are only allowed when not negated.
    if (value == null || value < 0) {
      push(
        forest.createIntLiteralLarge(
          offsetForToken(token),
          token.lexeme,
          token.lexeme,
        ),
      );
    } else {
      push(forest.createIntLiteral(offsetForToken(token), value, token.lexeme));
    }
  }

  @override
  void handleLiteralIntWithSeparators(Token token) {
    debugEvent("LiteralIntWithSeparators");

    if (!libraryFeatures.digitSeparators.isEnabled) {
      addProblem(
        diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: ExperimentalFlag.digitSeparators.name,
        ),
        token.offset,
        token.length,
      );
    }

    String source = stripSeparators(token.lexeme);
    int? value = int.tryParse(source);
    // Postpone parsing of literals resulting in a negative value
    // (hex literals >= 2^63). These are only allowed when not negated.
    if (value == null || value < 0) {
      push(
        forest.createIntLiteralLarge(
          offsetForToken(token),
          source,
          token.lexeme,
        ),
      );
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
    bool hasExpression,
    Token beginToken,
    Token? endToken,
  ) {
    debugEvent("ReturnStatement");
    Expression? expression = hasExpression ? popForValue() : null;
    if (expression != null && inConstructor) {
      push(
        buildProblemStatement(
          diag.constructorWithReturnType,
          beginToken.charOffset,
        ),
      );
    } else {
      push(
        forest.createReturnStatement(
          offsetForToken(beginToken),
          expression,
          isArrow: !identical(beginToken.lexeme, "return"),
        ),
      );
    }
  }

  @override
  void beginPatternGuard(Token when) {
    debugEvent("PatternGuard");
    assert(
      checkState(when, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Pattern]),
      ]),
    );

    Pattern pattern = toPattern(peek());
    createAndEnterLocalScope(kind: LocalScopeKind.ifCaseHead);
    for (VariableDeclaration variable in pattern.declaredVariables) {
      declareVariable(variable, _localScope);
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
    assignedVariables.beginNode();
    Condition condition = pop() as Condition;
    PatternGuard? patternGuard = condition.patternGuard;
    if (patternGuard != null && patternGuard.guard != null) {
      LocalScope thenScope = _localScope.createNestedScope(
        kind: LocalScopeKind.statementLocalScope,
      );
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifCaseHead]);
      push(condition);
      enterLocalScope(thenScope);
    } else {
      push(condition);
      // There is no guard, so the scope for "then" isn't entered yet. We need
      // to enter the scope and declare all of the pattern variables.
      if (patternGuard != null) {
        createAndEnterLocalScope(kind: LocalScopeKind.ifCaseHead);
        for (VariableDeclaration variable
            in patternGuard.pattern.declaredVariables) {
          declareVariable(variable, _localScope);
        }
        LocalScope thenScope = _localScope.createNestedScope(
          kind: LocalScopeKind.statementLocalScope,
        );
        exitLocalScope();
        enterLocalScope(thenScope);
      } else {
        createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
      }
    }
  }

  @override
  void endThenStatement(Token beginToken, Token endToken) {
    debugEvent("endThenStatement");
    Object? body = pop();
    exitLocalScope();
    push(body);
    // This is matched by the call to [beginNode] in
    // [beginThenStatement] and by the call to [storeInfo] in
    // [endIfStatement].
    push(assignedVariables.deferNode());
  }

  @override
  void endIfStatement(Token ifToken, Token? elseToken, Token endToken) {
    assert(
      checkState(ifToken, [
        /* else = */ if (elseToken != null)
          unionOfKinds([ValueKinds.Statement, ValueKinds.ParserRecovery]),
        ValueKinds.AssignedVariablesNodeInfo,
        /* then = */ unionOfKinds([
          ValueKinds.Statement,
          ValueKinds.ParserRecovery,
        ]),
        /* condition = */ ValueKinds.Condition,
      ]),
    );
    Statement? elsePart = popStatementIfNotNull(elseToken);
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
    Statement thenPart = popStatement(ifToken);
    Condition condition = pop() as Condition;
    PatternGuard? patternGuard = condition.patternGuard;
    Expression expression = condition.expression;
    Statement node;
    if (patternGuard != null) {
      node = forest.createIfCaseStatement(
        ifToken.charOffset,
        expression,
        patternGuard,
        thenPart,
        elsePart,
      );
    } else {
      node = forest.createIfStatement(
        offsetForToken(ifToken),
        expression,
        thenPart,
        elsePart,
      );
    }
    // This is matched by the call to [deferNode] in
    // [endThenStatement].
    assignedVariables.storeInfo(node, assignedVariablesInfo);
    push(node);
  }

  @override
  void beginVariableInitializer(Token token) {
    if (currentLocalVariableModifiers.isLate) {
      // This is matched by the call to [endNode] in [endVariableInitializer].
      assignedVariables.beginNode();
    }
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    AssignedVariablesNodeInfo? assignedVariablesInfo;
    bool isLate = currentLocalVariableModifiers.isLate;
    Expression initializer = popForValue();
    if (isLate) {
      assignedVariablesInfo = assignedVariables.deferNode(
        isClosureOrLateVariableInitializer: true,
      );
    }
    pushNewLocalVariable(initializer, equalsToken: assignmentOperator);
    if (isLate) {
      VariableInitialization node = peek() as VariableInitialization;
      // This is matched by the call to [beginNode] in
      // [beginVariableInitializer].

      // TODO(62401): Remove the cast when the flow analysis uses
      // [InternalExpressionVariable]s.
      assignedVariables.storeInfo(
        (node.variable as InternalExpressionVariable).astVariable,
        assignedVariablesInfo!,
      );
    }
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
    bool isConst = currentLocalVariableModifiers.isConst;
    Expression? initializer;
    if (!token.next!.isA(Keyword.IN)) {
      // A for-in loop-variable can't have an initializer. So let's remain
      // silent if the next token is `in`. Since a for-in loop can only have
      // one variable it must be followed by `in`.
      if (!token.isSynthetic) {
        // If [token] is synthetic it is created from error recovery.
        if (isConst) {
          initializer = buildProblem(
            message: diag.constFieldWithoutInitializer.withArguments(
              name: token.lexeme,
            ),
            fileUri: uri,
            fileOffset: token.charOffset,
            length: token.length,
          );
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
    assert(currentLocalVariableModifiers != noCurrentLocalVariableModifiers);
    bool isConst = currentLocalVariableModifiers.isConst;
    bool isFinal = currentLocalVariableModifiers.isFinal;
    bool isLate = currentLocalVariableModifiers.isLate;
    bool isRequired = currentLocalVariableModifiers.isRequired;
    assert(isConst == (constantContext == ConstantContext.inferred));
    String name = identifier.name;
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && name == '_';
    if (isWildcard) {
      name = createWildcardVariableName(wildcardVariableIndex);
      wildcardVariableIndex++;
    }
    VariableInitialization variableInitialization;
    InternalExpressionVariable internalVariable;
    if (isClosureContextLoweringEnabled) {
      internalVariable = new InternalLocalVariable(
        astVariable: new LocalVariable(
          cosmeticName: name,
          type: currentLocalVariableType,
          isFinal: isFinal,
          isConst: isConst,
          isLate: isLate,
          isWildcard: isWildcard,
        ),
        forSyntheticToken: identifier.token.isSynthetic,
        isImplicitlyTyped: currentLocalVariableType == null,
      );
      variableInitialization = new VariableInitialization(
        variable: internalVariable.asExpressionVariable,
        initializer: initializer,
        hasDeclaredInitializer: initializer != null,
      );
    } else {
      variableInitialization = internalVariable =
          new VariableDeclarationImpl(
              name,
              forSyntheticToken: identifier.token.isSynthetic,
              initializer: initializer,
              type: currentLocalVariableType,
              isFinal: isFinal,
              isConst: isConst,
              isLate: isLate,
              isRequired: isRequired,
              hasDeclaredInitializer: initializer != null,
              isStaticLate: isFinal && initializer == null,
              isWildcard: isWildcard,
            )
            ..fileOffset = identifier.nameOffset
            ..fileEqualsOffset = offsetForToken(equalsToken);
    }
    assignedVariables.declare(internalVariable.astVariable);
    push(variableInitialization);
  }

  @override
  void beginFieldInitializer(Token token) {
    inFieldInitializer = true;
    constantContext = _context.constantContext;
    inLateFieldInitializer = _context.isLateField;
    if (_context.isDeclarationInstanceContext && !inLateFieldInitializer) {
      LocalScope enclosingScope = _localScope;
      List<FormalParameterBuilder>? parameters =
          _context.primaryConstructorInitializerScopeParameters;
      if (parameters != null) {
        Map<String, VariableBuilder> local = {};
        for (FormalParameterBuilder formal in parameters) {
          assignedVariables.declare(formal.variable!);
          local[formal.name] = formal;
        }
        _localScopes.push(
          enclosingScope.createNestedFixedScope(
            kind: LocalScopeKind.initializers,
            local: local,
          ),
        );
      } else {
        _localScopes.push(enclosingScope);
      }
    }
    if (_context.isAbstractField) {
      addProblem(diag.abstractFieldInitializer, token.charOffset, noLength);
    } else if (_context.isExternalField) {
      addProblem(diag.externalFieldInitializer, token.charOffset, noLength);
    }
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token endToken) {
    debugEvent("FieldInitializer");
    if (_context.isDeclarationInstanceContext && !inLateFieldInitializer) {
      _localScopes.pop();
    }
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
    VariableInitialization variableInitialization =
        node as VariableInitialization;
    variableInitialization.fileOffset = nameToken.charOffset;
    push(variableInitialization);

    // Avoid adding the local identifier to scope if it's a wildcard.
    // TODO(kallentu): Emit better error on lookup, rather than not adding it to
    // the scope.
    if (!(libraryFeatures.wildcardVariables.isEnabled &&
        variableInitialization.isWildcard)) {
      declareVariable(variableInitialization.variable, _localScope);
    }
  }

  @override
  void beginVariablesDeclaration(
    Token token,
    Token? lateToken,
    Token? varFinalOrConst,
  ) {
    debugEvent("beginVariablesDeclaration");
    TypeBuilder? unresolvedType = pop(NullValues.TypeBuilder) as TypeBuilder?;
    DartType? type = unresolvedType != null
        ? buildDartType(
            unresolvedType,
            TypeUse.variableType,
            allowPotentiallyConstantType: false,
          )
        : null;
    Modifiers modifiers = Modifiers.from(
      lateToken: lateToken,
      varFinalOrConst: varFinalOrConst,
    );
    _enterLocalState(inLateLocalInitializer: lateToken != null);
    super.push(currentLocalVariableModifiers);
    super.push(currentLocalVariableType ?? NullValues.Type);
    currentLocalVariableType = type;
    currentLocalVariableModifiers = modifiers;
    super.push(constantContext);
    constantContext = modifiers.isConst
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
      currentLocalVariableModifiers = pop() as Modifiers;
      List<Expression>? annotations = pop() as List<Expression>?;
      if (node is ParserRecovery) {
        push(node);
        return;
      }
      VariableInitialization variableInitialization =
          node as VariableInitialization;
      if (annotations != null) {
        for (int i = 0; i < annotations.length; i++) {
          variableInitialization.addAnnotation(annotations[i]);
        }
        _registerSingleTargetAnnotations(variableInitialization);
        // (variablesWithMetadata ??= <VariableDeclaration>[]).add(
        //   variableInitialization,
        // );
      }
      push(variableInitialization);
    } else {
      List<VariableDeclaration>? variables =
          const FixedNullableList<VariableDeclaration>().popNonNullable(
            stack,
            count,
            dummyVariableDeclaration,
          );
      constantContext = pop() as ConstantContext;
      currentLocalVariableType = pop(NullValues.Type) as DartType?;
      currentLocalVariableModifiers = pop() as Modifiers;
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
        _registerMultiTargetAnnotations(variables);
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
      assignedVariables.beginNode();
    } else if (blockKind == BlockKind.finallyClause) {
      // This is matched by the call to [beginNode] in [beginTryStatement].
      tryStatementInfoStack = tryStatementInfoStack.prepend(
        assignedVariables.deferNode(),
      );
    }
    debugEvent("beginBlock");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void endBlock(
    int count,
    Token openBrace,
    Token closeBrace,
    BlockKind blockKind,
  ) {
    debugEvent("Block");
    Statement block = popBlock(count, openBrace, closeBrace);
    exitLocalScope();
    push(block);
    if (blockKind == BlockKind.tryStatement) {
      // This is matched by the call to [beginNode] in [beginBlock].
      assignedVariables.endNode(block);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  @override
  void handleAssignmentExpression(Token token, Token endToken) {
    assert(
      checkState(token, [
        unionOfKinds(<ValueKind>[ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds(<ValueKind>[ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    debugEvent("AssignmentExpression");
    Expression value = popForValue();
    Object? generator = pop();
    if (generator is! Generator) {
      push(
        buildProblem(
          message: diag.notAnLvalue,
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
          errorHasBeenReported: generator is InvalidExpression,
        ),
      );
    } else {
      push(
        new DelayedAssignment(
          this,
          token,
          generator,
          value,
          token.stringValue!,
        ),
      );
    }
  }

  void enterLoop(int charOffset) {
    enterBreakTarget(charOffset);
    enterContinueTarget(charOffset);
  }

  void exitLoopOrSwitch(Statement statement) {
    if (problemInLoopOrSwitch != null) {
      push(problemInLoopOrSwitch);
      problemInLoopOrSwitch = null;
    } else {
      push(statement);
    }
  }

  List<VariableInitialization>? _buildForLoopVariableDeclarations(
    variableOrExpression,
  ) {
    // TODO(ahe): This can be simplified now that we have the events
    // `handleForInitializer...` events.
    if (variableOrExpression is Generator) {
      variableOrExpression = variableOrExpression.buildForEffect();
    }
    if (variableOrExpression is VariableInitialization) {
      // Late for loop variables are not supported. An error has already been
      // reported by the parser.
      variableOrExpression.isLate = false;
      return <VariableInitialization>[variableOrExpression];
    } else if (variableOrExpression is Expression) {
      VariableDeclaration variable = new VariableDeclarationImpl.forEffect(
        variableOrExpression,
      );
      return <VariableInitialization>[variable];
    } else if (variableOrExpression is ExpressionStatement) {
      // Coverage-ignore-block(suite): Not run.
      VariableDeclaration variable = new VariableDeclarationImpl.forEffect(
        variableOrExpression.expression,
      );
      return <VariableInitialization>[variable];
    } else if (forest.isVariablesDeclaration(variableOrExpression)) {
      return forest.variablesDeclarationExtractDeclarations(
        variableOrExpression,
      );
    } else if (variableOrExpression is List<Object>) {
      // Coverage-ignore-block(suite): Not run.
      List<VariableInitialization> variables = <VariableInitialization>[];
      for (Object v in variableOrExpression) {
        variables.addAll(_buildForLoopVariableDeclarations(v)!);
      }
      return variables;
    } else if (variableOrExpression is PatternVariableDeclaration) {
      // Coverage-ignore-block(suite): Not run.
      return <VariableInitialization>[];
    } else if (variableOrExpression is ParserRecovery) {
      return <VariableInitialization>[];
    } else if (variableOrExpression == null) {
      return <VariableInitialization>[];
    }
    return null;
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement");
    push(NullValues.Expression);
    // This is matched by the call to [deferNode] in [endForStatement] or
    // [endForControlFlow].
    assignedVariables.beginNode();
  }

  @override
  void handleForInitializerExpressionStatement(Token token, bool forIn) {
    debugEvent("ForInitializerExpressionStatement");
    if (!forIn) {
      // This is matched by the call to [deferNode] in [endForStatement] or
      // [endForControlFlow].
      assignedVariables.beginNode();
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
      assignedVariables.beginNode();
    }
  }

  @override
  void handleForInitializerPatternVariableAssignment(
    Token keyword,
    Token equals,
  ) {
    debugEvent("handleForInitializerPatternVariableAssignment");
    assert(
      checkState(keyword, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );

    Object expression = pop() as Object;
    Object pattern = pop() as Object;

    if (pattern is Pattern) {
      pop(); // Metadata.
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, _localScope);
      }
      LocalScope forScope = _localScope.createNestedScope(
        kind: LocalScopeKind.forStatement,
      );
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

        VariableDeclaration intermediateVariable = forest
            .createVariableDeclarationForValue(
              forest.createVariableGet(variable.fileOffset, variable),
            );
        intermediateVariables.add(intermediateVariable);

        VariableDeclaration internalVariable = forest.createVariableDeclaration(
          variable.fileOffset,
          variable.name!,
          initializer: forest.createVariableGet(
            variable.fileOffset,
            intermediateVariable,
          ),
          isFinal: isFinal,
        );
        internalVariables.add(internalVariable);

        declareVariable(internalVariable, _localScope);
        assignedVariables.declare(internalVariable);
      }
      push(intermediateVariables);
      push(internalVariables);
      push(
        forest.createPatternVariableDeclaration(
          offsetForToken(keyword),
          pattern,
          toValue(expression),
          isFinal: isFinal,
        ),
      );
    }

    // This is matched by the call to [deferNode] in [endForStatement].
    assignedVariables.beginNode();
  }

  @override
  void handleForLoopParts(
    Token forKeyword,
    Token leftParen,
    Token leftSeparator,
    Token rightSeparator,
    int updateExpressionCount,
  ) {
    push(forKeyword);
    // TODO(jensj): Seems like leftParen and leftSeparator are just popped and
    // thrown away. If that's the case there's no reason to push them.
    push(leftParen);
    push(leftSeparator);
    push(updateExpressionCount);
  }

  @override
  void endForControlFlow(Token token) {
    assert(
      checkState(token, <ValueKind>[
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
      ]),
    );
    debugEvent("ForControlFlow");
    Object? entry = pop();
    int updateExpressionCount = pop() as int;
    pop(); // left separator
    pop(); // left parenthesis
    Token forToken = pop() as Token;

    assert(
      checkState(token, <ValueKind>[
        /* updates = */ ...repeatedKind(
          unionOfKinds(<ValueKind>[
            ValueKinds.Expression,
            ValueKinds.Generator,
          ]),
          updateExpressionCount,
        ),
        /* condition = */ ValueKinds.Statement,
      ]),
    );
    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement(forToken); // condition

    if (constantContext != ConstantContext.none) {
      pop(); // Pop variable or expression.
      exitLocalScope();
      assignedVariables.discardNode();

      push(
        buildProblem(
          message: diag.cantUseControlFlowOrSpreadAsConstant.withArguments(
            token: forToken,
          ),
          fileUri: uri,
          fileOffset: forToken.charOffset,
          length: forToken.charCount,
        ),
      );
      return;
    }

    // This is matched by the call to [beginNode] in
    // [handleForInitializerEmptyStatement],
    // [handleForInitializerPatternVariableAssignment],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo = assignedVariables
        .popNode();

    Object? variableOrExpression = pop();
    List<VariableInitialization>? variables;
    List<VariableDeclaration>? intermediateVariables;
    if (variableOrExpression is PatternVariableDeclaration) {
      variables = pop() as List<VariableDeclaration>; // Internal variables.
      intermediateVariables = pop() as List<VariableDeclaration>;
    } else {
      variables = _buildForLoopVariableDeclarations(variableOrExpression)!;
    }
    exitLocalScope();

    assignedVariables.pushNode(assignedVariablesNodeInfo);
    Expression? condition;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is EmptyStatement);
    }
    if (entry is MapLiteralEntry) {
      TreeNode result;
      if (variableOrExpression is PatternVariableDeclaration) {
        result = forest.createPatternForMapEntry(
          offsetForToken(forToken),
          patternVariableDeclaration: variableOrExpression,
          intermediateVariables: intermediateVariables!,
          variableInitializations: variables,
          condition: condition,
          updates: updates,
          body: entry,
        );
      } else {
        result = forest.createForMapEntry(
          offsetForToken(forToken),
          variables,
          condition,
          updates,
          entry,
        );
      }
      assignedVariables.endNode(result);
      push(result);
    } else {
      TreeNode result;
      if (variableOrExpression is PatternVariableDeclaration) {
        result = forest.createPatternForElement(
          offsetForToken(forToken),
          patternVariableDeclaration: variableOrExpression,
          intermediateVariables: intermediateVariables!,
          variables: variables,
          condition: condition,
          updates: updates,
          body: toValue(entry),
        );
      } else {
        result = forest.createForElement(
          offsetForToken(forToken),
          variables,
          condition,
          updates,
          toValue(entry),
        );
      }
      assignedVariables.endNode(result);
      push(result);
    }
  }

  @override
  void endForStatement(Token endToken) {
    assert(
      checkState(endToken, <ValueKind>[
        /* body */ unionOfKinds([
          ValueKinds.Statement,
          ValueKinds.ParserRecovery,
        ]),
        /* expression count */ ValueKinds.Integer,
        /* left separator */ ValueKinds.Token,
        /* left parenthesis */ ValueKinds.Token,
        /* for keyword */ ValueKinds.Token,
      ]),
    );
    debugEvent("ForStatement");
    Statement body = popStatement(endToken);

    int updateExpressionCount = pop() as int;
    pop(); // Left separator.
    pop(); // Left parenthesis.
    Token forKeyword = pop() as Token;

    assert(
      checkState(endToken, <ValueKind>[
        /* expressions */ ...repeatedKind(
          unionOfKinds(<ValueKind>[
            ValueKinds.Expression,
            ValueKinds.Generator,
          ]),
          updateExpressionCount,
        ),
        /* condition */ ValueKinds.Statement,
        /* variable or expression */ unionOfKinds(<ValueKind>[
          ValueKinds.Generator,
          ValueKinds.ExpressionOrNull,
          ValueKinds.Statement,
          ValueKinds.ObjectList,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );

    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement(forKeyword);
    // This is matched by the call to [beginNode] in
    // [handleForInitializerEmptyStatement],
    // [handleForInitializerPatternVariableAssignment],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo = assignedVariables
        .deferNode();

    Object? variableOrExpression = pop();
    List<VariableInitialization>? variables;
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
      continueStatements = continueTarget.resolveContinues(
        forest,
        labeledStatement,
      );
      body = labeledStatement;
    }
    Expression? condition;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is EmptyStatement);
    }
    Statement forStatement = forest.createForStatement(
      offsetForToken(forKeyword),
      variables,
      condition,
      updates,
      body,
    );
    assignedVariables.storeInfo(forStatement, assignedVariablesNodeInfo);
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
      result = forest.createBlock(
        result.fileOffset,
        result.fileOffset,
        <Statement>[variableOrExpression, ...intermediateVariables!, result],
      );
    }
    if (variableOrExpression is ParserRecovery) {
      problemInLoopOrSwitch ??= buildProblemStatement(
        diag.syntheticToken,
        variableOrExpression.charOffset,
        errorHasBeenReported: true,
      );
    }
    exitLoopOrSwitch(result);
  }

  @override
  void endAwaitExpression(Token keyword, Token endToken) {
    debugEvent("AwaitExpression");
    int fileOffset = offsetForToken(keyword);
    Expression value = popForValue();
    if (inLateLocalInitializer) {
      push(
        buildProblem(
          message: diag.awaitInLateLocalInitializer,
          fileUri: uri,
          fileOffset: fileOffset,
          length: keyword.charCount,
        ),
      );
    } else {
      push(forest.createAwaitExpression(fileOffset, value));
    }
  }

  @override
  void endInvalidAwaitExpression(
    Token keyword,
    Token endToken,
    cfe.MessageCode errorCode,
  ) {
    debugEvent("AwaitExpression");
    popForValue();
    push(
      buildProblem(
        message: errorCode,
        fileUri: uri,
        fileOffset: keyword.offset,
        length: keyword.length,
      ),
    );
  }

  @override
  void endInvalidYieldStatement(
    Token keyword,
    Token? starToken,
    Token endToken,
    cfe.MessageCode errorCode,
  ) {
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
    int count,
    Token leftBracket,
    Token? constKeyword,
    Token rightBracket,
  ) {
    debugEvent("LiteralList");
    assert(
      checkState(leftBracket, [
        ...repeatedKind(
          unionOfKinds([ValueKinds.Generator, ValueKinds.Expression]),
          count,
        ),
        ValueKinds.TypeArgumentsOrNull,
      ]),
    );

    if (constantContext == ConstantContext.required && constKeyword == null) {
      addProblem(
        diag.missingExplicitConst,
        offsetForToken(leftBracket),
        noLength,
      );
    }

    List<Expression> expressions = popListForValue(count);

    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;

    DartType typeArgument;
    if (typeArguments != null) {
      if (typeArguments.length > 1) {
        addProblem(
          diag.listLiteralTooManyTypeArguments,
          offsetForToken(leftBracket),
          lengthOfSpan(leftBracket, leftBracket.endGroup),
        );
        typeArgument = const InvalidType();
      } else {
        typeArgument = buildDartType(
          typeArguments.single,
          TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false,
        );
        typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass);
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
      isConst:
          constKeyword != null || constantContext == ConstantContext.inferred,
    );
    push(node);
  }

  @override
  void handleListPattern(int count, Token leftBracket, Token rightBracket) {
    debugEvent("ListPattern");
    assert(
      checkState(leftBracket, [
        ...repeatedKind(
          unionOfKinds([
            ValueKinds.Generator,
            ValueKinds.Expression,
            ValueKinds.Pattern,
          ]),
          count,
        ),
        ValueKinds.TypeArgumentsOrNull,
      ]),
    );

    reportIfNotEnabled(
      libraryFeatures.patterns,
      leftBracket.charOffset,
      leftBracket.charCount,
    );

    List<Pattern> patterns = new List<Pattern>.filled(
      count,
      dummyPattern,
      growable: true,
    );
    for (int i = count - 1; i >= 0; i--) {
      patterns[i] = toPattern(pop());
    }
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    DartType? typeArgument;
    if (typeArguments != null) {
      if (typeArguments.length > 1) {
        addProblem(
          diag.listPatternTooManyTypeArguments,
          offsetForToken(leftBracket),
          lengthOfSpan(leftBracket, leftBracket.endGroup),
        );
        typeArgument = const InvalidType();
      } else {
        typeArgument = buildDartType(
          typeArguments.single,
          TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false,
        );
        typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass);
      }
    }

    push(
      forest.createListPattern(leftBracket.charOffset, typeArgument, patterns),
    );
  }

  @override
  void endRecordLiteral(Token token, int count, Token? constKeyword) {
    debugEvent("RecordLiteral");
    assert(
      checkState(
        token,
        repeatedKind(
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.NamedExpression,
            ValueKinds.ParserRecovery,
          ]),
          count,
        ),
      ),
    );

    reportIfNotEnabled(
      libraryFeatures.records,
      token.charOffset,
      token.charCount,
    );

    // Pop all elements. This will put them in evaluation order.
    List<Object?>? elements = const FixedNullableList<Object>().pop(
      stack,
      count,
    );

    List<Object> originalElementOrder = [];
    List<Expression> positional = [];
    List<NamedExpression> named = [];
    Map<String, NamedExpression>? namedElements;
    const List<String> forbiddenObjectMemberNames = [
      "noSuchMethod",
      "toString",
      "hashCode",
      "runtimeType",
    ];
    if (elements != null) {
      for (Object? element in elements) {
        if (element is NamedExpression) {
          if (forbiddenObjectMemberNames.contains(element.name)) {
            libraryBuilder.addProblem(
              diag.objectMemberNameUsedForRecordField,
              element.fileOffset,
              element.name.length,
              uri,
            );
          }
          if (element.name.startsWith("_")) {
            libraryBuilder.addProblem(
              diag.recordFieldsCantBePrivate,
              element.fileOffset,
              element.name.length,
              uri,
            );
          }
          namedElements ??= {};
          NamedExpression? existingExpression = namedElements[element.name];
          if (existingExpression != null) {
            existingExpression.value = buildProblem(
              message: diag.duplicatedRecordLiteralFieldName.withArguments(
                fieldName: element.name,
              ),
              fileUri: uri,
              fileOffset: element.fileOffset,
              length: element.name.length,
              context: [
                diag.duplicatedRecordLiteralFieldNameContext
                    .withArguments(fieldName: element.name)
                    .withLocation(
                      uri,
                      existingExpression.fileOffset,
                      element.name.length,
                    ),
              ],
            )..parent = existingExpression;
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
                element.name,
                positional.length,
              ) !=
              null) {
            libraryBuilder.addProblem(
              diag.namedFieldClashesWithPositionalFieldInRecord,
              element.fileOffset,
              element.name.length,
              uri,
            );
          }
        }
      }
    }

    push(
      new InternalRecordLiteral(
        positional,
        named,
        namedElements,
        originalElementOrder,
        isConst:
            constKeyword != null || constantContext == ConstantContext.inferred,
        offset: token.offset,
      ),
    );
  }

  @override
  void handleRecordPattern(Token token, int count) {
    debugEvent("RecordPattern");
    assert(
      checkState(
        token,
        repeatedKind(
          unionOfKinds([
            ValueKinds.Generator,
            ValueKinds.Expression,
            ValueKinds.NamedExpression,
            ValueKinds.Pattern,
          ]),
          count,
        ),
      ),
    );

    reportIfNotEnabled(
      libraryFeatures.patterns,
      token.charOffset,
      token.charCount,
    );

    List<Pattern> patterns = new List<Pattern>.filled(count, dummyPattern);
    for (int i = count - 1; i >= 0; i--) {
      patterns[i] = toPattern(pop());
    }
    push(forest.createRecordPattern(token.charOffset, patterns));
  }

  void buildLiteralSet(
    List<TypeBuilder>? typeArguments,
    Token? constKeyword,
    Token leftBrace,
    List<dynamic>? setOrMapEntries,
  ) {
    DartType typeArgument;
    if (typeArguments != null) {
      typeArgument = buildDartType(
        typeArguments.single,
        TypeUse.literalTypeArgument,
        allowPotentiallyConstantType: false,
      );
      typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass);
    } else {
      typeArgument = implicitTypeArgument;
    }

    List<Expression> expressions = <Expression>[];
    if (setOrMapEntries != null) {
      for (dynamic entry in setOrMapEntries) {
        if (entry is MapLiteralEntry) {
          // TODO(danrubel): report the error on the colon
          addProblem(
            diag.expectedButGot.withArguments(expected: ','),
            entry.fileOffset,
            1,
          );
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
      isConst:
          constKeyword != null || constantContext == ConstantContext.inferred,
    );
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
    assert(
      checkState(leftBrace, [
        ...repeatedKind(
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Generator,
            ValueKinds.MapLiteralEntry,
          ]),
          count,
        ),
        ValueKinds.TypeArgumentsOrNull,
      ]),
    );

    if (constantContext == ConstantContext.required && constKeyword == null) {
      addProblem(
        diag.missingExplicitConst,
        offsetForToken(leftBrace),
        noLength,
      );
    }

    List<dynamic> setOrMapEntries = new List<dynamic>.filled(
      count,
      null,
      growable: true,
    );
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
        setOrMapEntries.length,
        dummyMapLiteralEntry,
      );
      for (int i = 0; i < setOrMapEntries.length; ++i) {
        if (setOrMapEntries[i] is MapLiteralEntry) {
          mapEntries[i] = setOrMapEntries[i];
        } else {
          mapEntries[i] = convertToMapEntry(
            setOrMapEntries[i],
            problemReporting,
            libraryBuilder.loader.target.context,
            uri,
            assignedVariables.reassignInfo,
          );
        }
      }
      buildLiteralMap(typeArguments, constKeyword, leftBrace, mapEntries);
    }
  }

  @override
  void handleMapPatternEntry(Token colon, Token endToken) {
    debugEvent('MapPatternEntry');
    assert(
      checkState(colon, [
        /* value */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
        /* key */ unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Pattern value = toPattern(pop());
    Expression key = toValue(pop());
    push(forest.createMapPatternEntry(colon.charOffset, key, value));
  }

  @override
  void handleMapPattern(int count, Token leftBrace, Token rightBrace) {
    debugEvent('MapPattern');
    assert(
      checkState(leftBrace, [
        ...repeatedKind(
          unionOfKinds([ValueKinds.MapPatternEntry, ValueKinds.Pattern]),
          count,
        ),
        ValueKinds.TypeArgumentsOrNull,
      ]),
    );

    reportIfNotEnabled(
      libraryFeatures.patterns,
      leftBrace.charOffset,
      leftBrace.charCount,
    );
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
        addProblem(
          diag.mapPatternTypeArgumentMismatch,
          leftBrace.charOffset,
          noLength,
        );
      } else {
        keyType = buildDartType(
          typeArguments[0],
          TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false,
        );
        valueType = buildDartType(
          typeArguments[1],
          TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false,
        );
        keyType = instantiateToBounds(keyType, coreTypes.objectClass);
        valueType = instantiateToBounds(valueType, coreTypes.objectClass);
      }
    }

    push(
      forest.createMapPattern(
        leftBrace.charOffset,
        keyType,
        valueType,
        entries,
      ),
    );
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = boolFromToken(token);
    push(forest.createBoolLiteral(offsetForToken(token), value));
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(
      forest.createDoubleLiteral(
        offsetForToken(token),
        doubleFromToken(token, hasSeparators: false),
      ),
    );
  }

  @override
  void handleLiteralDoubleWithSeparators(Token token) {
    debugEvent("LiteralDoubleWithSeparators");

    if (!libraryFeatures.digitSeparators.isEnabled) {
      addProblem(
        diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: ExperimentalFlag.digitSeparators.name,
        ),
        token.offset,
        token.length,
      );
    }

    double value = doubleFromToken(token, hasSeparators: true);
    push(forest.createDoubleLiteral(offsetForToken(token), value));
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(forest.createNullLiteral(offsetForToken(token)));
  }

  void buildLiteralMap(
    List<TypeBuilder>? typeArguments,
    Token? constKeyword,
    Token leftBrace,
    List<MapLiteralEntry> entries,
  ) {
    DartType keyType;
    DartType valueType;
    if (typeArguments != null) {
      if (typeArguments.length != 2) {
        keyType = const InvalidType();
        valueType = const InvalidType();
      } else {
        keyType = buildDartType(
          typeArguments[0],
          TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false,
        );
        valueType = buildDartType(
          typeArguments[1],
          TypeUse.literalTypeArgument,
          allowPotentiallyConstantType: false,
        );
        keyType = instantiateToBounds(keyType, coreTypes.objectClass);
        valueType = instantiateToBounds(valueType, coreTypes.objectClass);
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
      isConst:
          constKeyword != null || constantContext == ConstantContext.inferred,
    );
    push(node);
  }

  @override
  void handleLiteralMapEntry(
    Token colon,
    Token endToken, {
    Token? nullAwareKeyToken,
    Token? nullAwareValueToken,
  }) {
    debugEvent("LiteralMapEntry");
    Expression value = popForValue();
    Expression key = popForValue();
    if (nullAwareKeyToken == null && nullAwareValueToken == null) {
      push(forest.createMapEntry(offsetForToken(colon), key, value));
    } else {
      if (!libraryFeatures.nullAwareElements.isEnabled) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(
          diag.experimentNotEnabledOffByDefault.withArguments(
            featureName: ExperimentalFlag.nullAwareElements.name,
          ),
          (nullAwareKeyToken ?? nullAwareValueToken!).offset,
          noLength,
        );
      }
      push(
        forest.createNullAwareMapEntry(
          offsetForToken(colon),
          isKeyNullAware: nullAwareKeyToken != null,
          key: key,
          isValueNullAware: nullAwareValueToken != null,
          value: value,
        ),
      );
    }
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
        push(new ParserErrorGenerator(this, hashToken, diag.syntheticToken));
      } else {
        push(
          forest.createSymbolLiteral(
            offsetForToken(hashToken),
            symbolPartToString(part),
          ),
        );
      }
    } else {
      List<Identifier>? parts = const FixedNullableList<Identifier>()
          .popNonNullable(stack, identifierCount, dummyIdentifier);
      if (parts == null) {
        // Coverage-ignore-block(suite): Not run.
        push(new ParserErrorGenerator(this, hashToken, diag.syntheticToken));
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
    assert(
      checkState(bang, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
    Expression operand = popForValue();
    push(forest.createNullCheck(offsetForToken(bang), operand));
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    // TODO(ahe): The scope is wrong for return types of generic functions.
    debugEvent("Type");
    assert(
      checkState(beginToken, [
        ValueKinds.TypeArgumentsOrNull,
        unionOfKinds([ValueKinds.QualifiedName, ValueKinds.Generator]),
      ]),
    );

    bool isMarkedAsNullable = questionMark != null;
    List<TypeBuilder>? arguments = pop() as List<TypeBuilder>?;
    Object? name = pop();

    // Coverage-ignore(suite): Not run.
    void errorCase(String name, Token suffix) {
      String displayName = debugName(name, suffix.lexeme);
      int offset = offsetForToken(beginToken);
      Message message = diag.notAType.withArguments(name: displayName);
      libraryBuilder.addProblem(
        message,
        offset,
        lengthOfSpan(beginToken, suffix),
        uri,
      );
      push(
        new NamedTypeBuilderImpl.forInvalidType(
          name,
          isMarkedAsNullable
              ? const NullabilityBuilder.nullable()
              : const NullabilityBuilder.omitted(),
          message.withLocation(uri, offset, lengthOfSpan(beginToken, suffix)),
        ),
      );
    }

    if (name is QualifiedName) {
      QualifiedName qualified = name;
      switch (qualified) {
        case QualifiedNameGenerator():
          Generator prefix = qualified.qualifier;
          Token suffix = qualified.suffix;
          if (prefix is ParserErrorGenerator) {
            // An error have already been issued.
            push(
              prefix.buildTypeWithResolvedArgumentsDoNotAddProblem(
                isMarkedAsNullable
                    ? const NullabilityBuilder.nullable()
                    : const NullabilityBuilder.omitted(),
              ),
            );
            return;
          } else {
            name = prefix.qualifiedLookup(suffix);
          }
        // Coverage-ignore(suite): Not run.
        case QualifiedNameBuilder():
          errorCase(qualified.qualifier.fullNameForErrors, qualified.suffix);
          return;
        // Coverage-ignore(suite): Not run.
        case QualifiedNameIdentifier():
          unhandled(
            "qualified is ${qualified.runtimeType}",
            "handleType",
            qualified.charOffset,
            uri,
          );
      }
    }
    TypeBuilder result;
    if (name is Generator) {
      bool allowPotentiallyConstantType;
      if (libraryFeatures.constructorTearoffs.isEnabled) {
        allowPotentiallyConstantType = true;
      } else {
        allowPotentiallyConstantType = inIsOrAsOperatorType;
      }
      result = name.buildTypeWithResolvedArguments(
        isMarkedAsNullable
            ? const NullabilityBuilder.nullable()
            : const NullabilityBuilder.omitted(),
        arguments,
        allowPotentiallyConstantType: allowPotentiallyConstantType,
        performTypeCanonicalization: constantContext != ConstantContext.none,
      );
    } else {
      unhandled(
        "${name.runtimeType}",
        "handleType",
        beginToken.charOffset,
        uri,
      );
    }
    push(result);
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
    _structuralParameterDepthLevel++;
  }

  void enterNominalVariablesScope(
    List<NominalParameterBuilder>? nominalVariableBuilders,
  ) {
    debugEvent("enterNominalVariableScope");
    Map<String, TypeParameterBuilder> typeParameters = {};
    if (nominalVariableBuilders != null) {
      for (NominalParameterBuilder builder in nominalVariableBuilders) {
        if (builder.isWildcard) continue;
        String name = builder.name;
        TypeParameterBuilder? existing = typeParameters[name];
        if (existing == null) {
          typeParameters[name] = builder;
        } else {
          // Coverage-ignore-block(suite): Not run.
          reportDuplicatedDeclaration(existing, name, builder.fileOffset);
        }
      }
    }
    enterLocalScope(
      new LocalTypeParameterScope(
        local: typeParameters,
        parent: _localScope,
        kind: LocalScopeKind.typeParameters,
      ),
    );
  }

  void enterStructuralVariablesScope(
    List<StructuralParameterBuilder>? structuralVariableBuilders,
  ) {
    debugEvent("enterStructuralVariableScope");
    Map<String, TypeParameterBuilder> typeParameters = {};
    if (structuralVariableBuilders != null) {
      for (StructuralParameterBuilder builder in structuralVariableBuilders) {
        if (builder.isWildcard) continue;
        String name = builder.name;
        TypeParameterBuilder? existing = typeParameters[name];
        if (existing == null) {
          typeParameters[name] = builder;
        } else {
          // Coverage-ignore-block(suite): Not run.
          reportDuplicatedDeclaration(existing, name, builder.fileOffset);
        }
      }
    }
    enterLocalScope(
      new LocalTypeParameterScope(
        local: typeParameters,
        parent: _localScope,
        kind: LocalScopeKind.typeParameters,
      ),
    );
  }

  @override
  void endRecordType(
    Token leftBracket,
    Token? questionMark,
    int count,
    bool hasNamedFields,
  ) {
    debugEvent("RecordType");
    assert(
      checkState(leftBracket, [
        if (hasNamedFields) ValueKinds.RecordTypeFieldBuilderListOrNull,
        ...repeatedKind(
          ValueKinds.RecordTypeFieldBuilder,
          hasNamedFields ? count - 1 : count,
        ),
      ]),
    );

    if (!libraryFeatures.records.isEnabled) {
      addProblem(
        diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: ExperimentalFlag.records.name,
        ),
        leftBracket.offset,
        noLength,
      );
    }

    List<RecordTypeFieldBuilder>? namedFields;
    if (hasNamedFields) {
      namedFields =
          pop(NullValues.RecordTypeFieldList) as List<RecordTypeFieldBuilder>?;
    }
    List<RecordTypeFieldBuilder>? positionalFields =
        const FixedNullableList<RecordTypeFieldBuilder>().popNonNullable(
          stack,
          hasNamedFields ? count - 1 : count,
          dummyRecordTypeFieldBuilder,
        );

    push(
      new RecordTypeBuilderImpl(
        positionalFields,
        namedFields,
        questionMark != null
            ? const NullabilityBuilder.nullable()
            : const NullabilityBuilder.omitted(),
        uri,
        leftBracket.charOffset,
      ),
    );
  }

  @override
  void endRecordTypeEntry() {
    debugEvent("RecordTypeEntry");
    assert(
      checkState(null, [
        unionOfKinds([ValueKinds.IdentifierOrNull, ValueKinds.ParserRecovery]),
        unionOfKinds([ValueKinds.TypeBuilder, ValueKinds.ParserRecovery]),
        ValueKinds.AnnotationListOrNull,
      ]),
    );

    Object? name = pop();
    Object? type = pop();
    // TODO(johnniwinther): How should we handle annotations?
    pop(NullValues.Metadata); // Annotations.

    String? fieldName = name is Identifier ? name.name : null;
    push(
      new RecordTypeFieldBuilder(
        [],
        type is ParserRecovery
            ?
              // Coverage-ignore(suite): Not run.
              new InvalidTypeBuilderImpl(uri, type.charOffset)
            : type as TypeBuilder,
        fieldName,
        name is Identifier ? name.nameOffset : TreeNode.noOffset,
        isWildcard:
            libraryFeatures.wildcardVariables.isEnabled && fieldName == '_',
      ),
    );
  }

  @override
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    debugEvent("RecordTypeNamedFields");
    assert(
      checkState(leftBracket, [
        ...repeatedKind(ValueKinds.RecordTypeFieldBuilder, count),
      ]),
    );
    List<RecordTypeFieldBuilder>? fields =
        const FixedNullableList<RecordTypeFieldBuilder>().popNonNullable(
          stack,
          count,
          dummyRecordTypeFieldBuilder,
        );
    push(fields ?? NullValues.RecordTypeFieldList);
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    debugEvent("FunctionType");
    _structuralParameterDepthLevel--;
    FunctionTypeParameters parameters = pop() as FunctionTypeParameters;
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<StructuralParameterBuilder>? typeParameters =
        pop() as List<StructuralParameterBuilder>?;
    TypeBuilder type = parameters.toFunctionType(
      returnType ?? const ImplicitTypeBuilder(),
      questionMark != null
          ? const NullabilityBuilder.nullable()
          : const NullabilityBuilder.omitted(),
      structuralVariableBuilders: typeParameters,
      hasFunctionFormalParameterSyntax: false,
    );
    exitLocalScope();
    push(type);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    int offset = offsetForToken(token);
    push(new VoidTypeBuilder(uri, offset));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleVoidKeywordWithTypeArguments(Token token) {
    assert(
      checkState(token, <ValueKind>[
        /* arguments */ ValueKinds.TypeArgumentsOrNull,
      ]),
    );

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
    assert(
      checkState(operator, [
        ValueKinds.TypeBuilder,
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    DartType type = buildDartType(
      pop() as TypeBuilder,
      TypeUse.asType,
      allowPotentiallyConstantType: true,
    );
    Expression expression = popForValue();
    Expression asExpression = forest.createAsExpression(
      offsetForToken(operator),
      expression,
      type,
    );
    push(asExpression);
  }

  @override
  void handleCastPattern(Token operator) {
    debugEvent('CastPattern');
    assert(
      checkState(operator, [
        ValueKinds.TypeBuilder,
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    reportIfNotEnabled(
      libraryFeatures.patterns,
      operator.charOffset,
      operator.charCount,
    );
    DartType type = buildDartType(
      pop() as TypeBuilder,
      TypeUse.asType,
      allowPotentiallyConstantType: true,
    );
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
    DartType type = buildDartType(
      pop() as TypeBuilder,
      TypeUse.isType,
      allowPotentiallyConstantType: true,
    );
    Expression operand = popForValue();
    Expression isExpression = forest.createIsExpression(
      offsetForToken(isOperator),
      operand,
      type,
      notFileOffset: not != null ? offsetForToken(not) : null,
    );
    push(isExpression);
  }

  @override
  void beginConditionalExpression(Token question) {
    Expression condition = popForValue();
    // This is matched by the call to [deferNode] in
    // [handleConditionalExpressionColon].
    assignedVariables.beginNode();
    push(condition);
    super.beginConditionalExpression(question);
  }

  @override
  void handleConditionalExpressionColon() {
    Expression then = popForValue();
    // This is matched by the call to [beginNode] in
    // [beginConditionalExpression] and by the call to [storeInfo] in
    // [endConditionalExpression].
    push(assignedVariables.deferNode());
    push(then);
    super.handleConditionalExpressionColon();
  }

  @override
  void endConditionalExpression(Token question, Token colon, Token endToken) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = popForValue();
    Expression thenExpression = pop() as Expression;
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
    Expression condition = pop() as Expression;
    Expression node = forest.createConditionalExpression(
      offsetForToken(question),
      condition,
      thenExpression,
      elseExpression,
    );
    push(node);
    // This is matched by the call to [deferNode] in
    // [handleConditionalExpressionColon].
    assignedVariables.storeInfo(node, assignedVariablesInfo);
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    Expression expression = popForValue();
    if (constantContext != ConstantContext.none) {
      push(
        buildProblem(
          message: diag.notConstantExpression.withArguments(
            description: 'Throw',
          ),
          fileUri: uri,
          fileOffset: throwToken.offset,
          length: throwToken.length,
        ),
      );
    } else {
      push(forest.createThrow(offsetForToken(throwToken), expression));
    }
  }

  @override
  void beginFormalParameter(
    Token token,
    MemberKind kind,
    Token? requiredToken,
    Token? covariantToken,
    Token? varFinalOrConst,
  ) {
    _insideOfFormalParameterType = true;
    push(
      Modifiers.from(
        requiredToken: requiredToken,
        covariantToken: covariantToken,
        varFinalOrConst: varFinalOrConst,
      ),
    );
    push(varFinalOrConst ?? NullValues.Token);
  }

  @override
  void endFormalParameter(
    Token? varOrFinal,
    Token? thisKeyword,
    Token? superKeyword,
    Token? periodAfterThisOrSuper,
    Token nameToken,
    Token? initializerStart,
    Token? initializerEnd,
    FormalParameterKind kind,
    MemberKind memberKind,
  ) {
    debugEvent("FormalParameter");

    _insideOfFormalParameterType = false;

    if (thisKeyword != null) {
      if (!inConstructor) {
        handleRecoverableError(
          diag.fieldInitializerOutsideConstructor,
          thisKeyword,
          thisKeyword,
        );
        thisKeyword = null;
      }
    }
    if (superKeyword != null) {
      if (!inConstructor) {
        handleRecoverableError(
          diag.superParameterInitializerOutsideConstructor,
          superKeyword,
          superKeyword,
        );
        superKeyword = null;
      }
    }
    Object? nameNode = pop();
    TypeBuilder? type = pop() as TypeBuilder?;
    Token? varOrFinalOrConst = pop(NullValues.Token) as Token?;
    if (superKeyword != null &&
        varOrFinalOrConst != null &&
        varOrFinalOrConst.isA(Keyword.VAR)) {
      handleRecoverableError(
        diag.extraneousModifier.withArguments(lexeme: varOrFinalOrConst),
        varOrFinalOrConst,
        varOrFinalOrConst,
      );
    }
    Modifiers modifiers = pop() as Modifiers;
    if (inCatchClause) {
      modifiers |= Modifiers.Final;
    }
    List<Expression>? annotations = pop() as List<Expression>?;
    if (nameNode is ParserRecovery) {
      push(nameNode);
      return;
    }
    Identifier? name = nameNode as Identifier?;

    FormalParameterBuilder? parameter;
    int nameOffset = offsetForToken(nameToken);
    if (!inCatchClause &&
        functionNestingLevel == 0 &&
        memberKind != MemberKind.GeneralizedFunctionType) {
      parameter = _context.getFormalParameterByNameOffset(nameOffset);

      if (parameter == null) {
        // This happens when the list of formals (originally) contains a
        // ParserRecovery - then the popped list becomes null.
        push(new ParserRecovery(nameToken.charOffset));
        return;
      }
    } else {
      String parameterName = name?.name ?? '';
      String? publicName = problemReporting.checkPublicName(
        compilationUnit: libraryBuilder.compilationUnit,
        kind: kind,
        parameterName: parameterName,
        nameToken: nameToken,
        thisKeyword: thisKeyword,
        isDeclaring: false,
        libraryFeatures: libraryFeatures,
        fileUri: uri,
      );
      bool isWildcard =
          libraryFeatures.wildcardVariables.isEnabled && parameterName == '_';
      if (isWildcard) {
        parameterName = createWildcardFormalParameterName(
          wildcardVariableIndex,
        );
        wildcardVariableIndex++;
      }
      if (memberKind.isFunctionType) {
        push(
          new FunctionTypeParameterBuilder(
            kind,
            type ?? const ImplicitTypeBuilder(),
            parameterName,
          ),
        );
        return;
      }
      parameter = new FormalParameterBuilder(
        kind: kind,
        modifiers: modifiers,
        type: type ?? const ImplicitTypeBuilder(),
        name: parameterName,
        fileOffset: nameOffset,
        nameOffset: nameOffset,
        fileUri: uri,
        hasImmediatelyDeclaredInitializer: initializerStart != null,
        isWildcard: isWildcard,
        publicName: publicName,
        isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
      );
    }
    VariableDeclaration functionParameter = parameter.build(libraryBuilder);
    Expression? initializer = name?.initializer;
    if (initializer != null) {
      if (_context.isRedirectingFactory) {
        addProblem(
          diag.defaultValueInRedirectingFactoryConstructor.withArguments(
            redirectionTarget: _context.redirectingFactoryTargetName,
          ),
          initializer.fileOffset,
          noLength,
        );
        functionParameter.isErroneouslyInitialized = true;
      } else {
        if (!parameter.initializerWasInferred) {
          functionParameter.initializer = initializer
            ..parent = functionParameter;
        }
      }
    } else if (kind.isOptional) {
      functionParameter.initializer ??= forest.createNullLiteral(noLocation)
        ..parent = functionParameter;
    }
    if (annotations != null) {
      functionParameter.clearAnnotations();
      for (Expression annotation in annotations) {
        functionParameter.addAnnotation(annotation);
      }
      // TODO(johnniwinther): This seems wrong. If we add the annotations, we
      //  should infer them.
      if (functionNestingLevel == 0) {
        _registerSingleTargetAnnotations(functionParameter);
      }
    }
    push(parameter);
    // We pass `ignoreDuplicates: true` because the variable might have been
    // previously passed to `declare` in the `BodyBuilder` constructor.
    // TODO(62401): Remove the cast when the flow analysis uses
    // [InternalExpressionVariable]s.
    assignedVariables.declare(
      (functionParameter as InternalExpressionVariable).astVariable,
      ignoreDuplicates: true,
    );
  }

  @override
  void endOptionalFormalParameters(
    int count,
    Token beginToken,
    Token endToken,
    MemberKind kind,
  ) {
    debugEvent("OptionalFormalParameters");
    // When recovering from an empty list of optional arguments, count may be
    // 0. It might be simpler if the parser didn't call this method in that
    // case, however, then [beginOptionalFormalParameters] wouldn't always be
    // matched by this method.
    if (kind.isFunctionType) {
      List<FunctionTypeParameterBuilder>? parameters =
          const FixedNullableList<FunctionTypeParameterBuilder>()
              .popNonNullable(stack, count, dummyFunctionTypeParameterBuilder);
      if (parameters == null) {
        push(new ParserRecovery(offsetForToken(beginToken)));
      } else {
        push(parameters);
      }
    } else {
      List<FormalParameterBuilder>? parameters =
          const FixedNullableList<FormalParameterBuilder>().popNonNullable(
            stack,
            count,
            dummyFormalParameterBuilder,
          );
      if (parameters == null) {
        push(new ParserRecovery(offsetForToken(beginToken)));
      } else {
        push(parameters);
      }
    }
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    _insideOfFormalParameterType = false;
    functionNestingLevel++;
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken, Token? question) {
    debugEvent("FunctionTypedFormalParameter");
    if (inCatchClause || functionNestingLevel != 0) {
      exitLocalScope();
    }
    FunctionTypeParameters parameters = pop() as FunctionTypeParameters;
    TypeBuilder? returnType = pop() as TypeBuilder?;
    List<StructuralParameterBuilder>? typeParameters =
        pop() as List<StructuralParameterBuilder>?;
    TypeBuilder type = parameters.toFunctionType(
      returnType ?? const ImplicitTypeBuilder(),
      question != null
          ? const NullabilityBuilder.nullable()
          : const NullabilityBuilder.omitted(),
      structuralVariableBuilders: typeParameters,
      hasFunctionFormalParameterSyntax: true,
    );
    push(type);
    functionNestingLevel--;
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    super.push(constantContext);
    _insideOfFormalParameterType = false;
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
    Token equals,
    Token token,
    FormalParameterKind kind,
  ) {
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
        libraryBuilder.languageVersion.major >= 3) {
      addProblem(
        diag.obsoleteColonForDefaultValue,
        equals.charOffset,
        equals.charCount,
      );
    }
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    super.push(constantContext);
    super.push(inFormals);
    constantContext = ConstantContext.none;
    inFormals = true;
  }

  @override
  void endFormalParameters(
    int count,
    Token beginToken,
    Token endToken,
    MemberKind kind,
  ) {
    debugEvent("FormalParameters");
    if (kind.isFunctionType) {
      assert(
        checkState(beginToken, [
          if (count > 0 && peek() is List<FunctionTypeParameterBuilder>) ...[
            ValueKinds.FunctionTypeParameterBuilderList,
            ...repeatedKind(
              unionOfKinds([
                ValueKinds.FunctionTypeParameterBuilder,
                ValueKinds.ParserRecovery,
              ]),
              count - 1,
            ),
          ] else
            ...repeatedKind(
              unionOfKinds([
                ValueKinds.FunctionTypeParameterBuilder,
                ValueKinds.ParserRecovery,
              ]),
              count,
            ),
          /* inFormals */ ValueKinds.Bool,
          /* constantContext */ ValueKinds.ConstantContext,
        ]),
      );
      List<FunctionTypeParameterBuilder>? optionals;
      int optionalsCount = 0;
      if (count > 0 && peek() is List<FunctionTypeParameterBuilder>) {
        optionals = pop() as List<FunctionTypeParameterBuilder>;
        count--;
        optionalsCount = optionals.length;
      }
      List<FunctionTypeParameterBuilder>? parameters =
          const FixedNullableList<FunctionTypeParameterBuilder>()
              .popPaddedNonNullable(
                stack,
                count,
                optionalsCount,
                dummyFunctionTypeParameterBuilder,
              );
      if (optionals != null && parameters != null) {
        parameters.setRange(count, count + optionalsCount, optionals);
      }
      assert(parameters?.isNotEmpty ?? true);
      FunctionTypeParameters formals = new FunctionTypeParameters(
        parameters,
        offsetForToken(beginToken),
        lengthOfSpan(beginToken, endToken),
        uri,
      );
      inFormals = pop() as bool;
      constantContext = pop() as ConstantContext;
      push(formals);
    } else {
      assert(
        checkState(beginToken, [
          if (count > 0 && peek() is List<FormalParameterBuilder>) ...[
            ValueKinds.FormalList,
            ...repeatedKind(
              unionOfKinds([
                ValueKinds.FormalParameterBuilder,
                ValueKinds.ParserRecovery,
              ]),
              count - 1,
            ),
          ] else
            ...repeatedKind(
              unionOfKinds([
                ValueKinds.FormalParameterBuilder,
                ValueKinds.ParserRecovery,
              ]),
              count,
            ),
          /* inFormals */ ValueKinds.Bool,
          /* constantContext */ ValueKinds.ConstantContext,
        ]),
      );
      List<FormalParameterBuilder>? optionals;
      int optionalsCount = 0;
      if (count > 0 && peek() is List<FormalParameterBuilder>) {
        optionals = pop() as List<FormalParameterBuilder>;
        count--;
        optionalsCount = optionals.length;
      }
      List<FormalParameterBuilder>? parameters =
          const FixedNullableList<FormalParameterBuilder>()
              .popPaddedNonNullable(
                stack,
                count,
                optionalsCount,
                dummyFormalParameterBuilder,
              );
      if (optionals != null && parameters != null) {
        parameters.setRange(count, count + optionalsCount, optionals);
      }
      assert(parameters?.isNotEmpty ?? true);
      FormalParameters formals = new FormalParameters(
        parameters,
        offsetForToken(beginToken),
        lengthOfSpan(beginToken, endToken),
        uri,
      );
      inFormals = pop() as bool;
      constantContext = pop() as ConstantContext;
      push(formals);
      if ((inCatchClause || functionNestingLevel != 0) &&
          kind != MemberKind.GeneralizedFunctionType) {
        enterLocalScope(
          formals.computeFormalParameterScope(
            _localScope,
            this,
            wildcardVariablesEnabled:
                libraryFeatures.wildcardVariables.isEnabled,
          ),
        );
      }
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
      exceptionType = buildDartType(
        unresolvedExceptionType,
        TypeUse.catchType,
        allowPotentiallyConstantType: false,
      );
    } else {
      exceptionType = coreTypes.objectNonNullableRawType;
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
          stackTrace.build(libraryBuilder).type = coreTypes.stackTraceRawType(
            Nullability.nonNullable,
          );
        }
      }
      if (parameterCount > 2) {
        // If parameterCount is 0, the parser reported an error already.
        if (parameterCount != 0) {
          for (int i = 2; i < parameterCount; i++) {
            FormalParameterBuilder parameter = catchParameters.parameters![i];
            compileTimeErrors ??= <Statement>[];
            compileTimeErrors.add(
              buildProblemStatement(
                diag.catchSyntaxExtraParameters,
                parameter.fileOffset,
                length: parameter.name.length,
              ),
            );
          }
        }
      }
    }
    assert(
      exception == null ||
          exception.kind == FormalParameterKind.requiredPositional ||
          // Coverage-ignore(suite): Not run.
          exception.kind == FormalParameterKind.optionalPositional,
    );
    assert(
      stackTrace == null ||
          stackTrace.kind == FormalParameterKind.requiredPositional ||
          // Coverage-ignore(suite): Not run.
          stackTrace.kind == FormalParameterKind.optionalPositional,
    );

    CatchVariable? exceptionVariable;
    if (exception?.variable
        case VariableDeclaration exceptionVariableDeclaration) {
      if (isClosureContextLoweringEnabled) {
        // Coverage-ignore-block(suite): Not run.
        // TODO(62743): Avoid the conversion when [FormalParameterBuilder]
        // produces [CatchVariable]s directly.
        exceptionVariable = new CatchVariable(
          name: exceptionVariableDeclaration.name!,
          type: exceptionVariableDeclaration.type,
          isWildcard: exceptionVariableDeclaration.isWildcard,
        );
      } else {
        exceptionVariable = exceptionVariableDeclaration;
      }
    }

    CatchVariable? stackTraceVariable;
    if (stackTrace?.variable
        case VariableDeclaration stackTraceVariableDeclaration) {
      if (isClosureContextLoweringEnabled) {
        // Coverage-ignore-block(suite): Not run.
        // TODO(62743): Avoid the conversion when [FormalParameterBuilder]
        // produces [CatchVariable]s directly.
        stackTraceVariable = new CatchVariable(
          name: stackTraceVariableDeclaration.name!,
          type: stackTraceVariableDeclaration.type,
          isWildcard: stackTraceVariableDeclaration.isWildcard,
        );
      } else {
        stackTraceVariable = stackTraceVariableDeclaration;
      }
    }

    push(
      forest.createCatch(
        offsetForToken(onKeyword ?? catchKeyword),
        exceptionType,
        exceptionVariable,
        stackTraceVariable,
        coreTypes.stackTraceRawType(Nullability.nonNullable),
        body,
      ),
    );
    if (compileTimeErrors == null) {
      push(NullValues.Block);
    } else {
      push(forest.createBlock(noLocation, noLocation, compileTimeErrors));
    }
  }

  @override
  void beginTryStatement(Token token) {
    // This is matched by the call to [endNode] in [endTryStatement].
    assignedVariables.beginNode();
  }

  @override
  void endTryStatement(
    int catchCount,
    Token tryKeyword,
    Token? finallyKeyword,
    Token endToken,
  ) {
    Statement? finallyBlock;
    if (finallyKeyword != null) {
      finallyBlock = pop() as Statement;
    } else {
      // This is matched by the call to [beginNode] in [beginTryStatement].
      tryStatementInfoStack = tryStatementInfoStack.prepend(
        assignedVariables.deferNode(),
      );
    }
    List<Catch>? catchBlocks;
    List<Statement>? compileTimeErrors;
    if (catchCount != 0) {
      List<Object?> catchBlocksAndErrors = const FixedNullableList<Object?>()
          .pop(stack, catchCount * 2)!;
      catchBlocks = new List<Catch>.filled(
        catchCount,
        dummyCatch,
        growable: true,
      );
      for (int i = 0; i < catchCount; i++) {
        catchBlocks[i] = catchBlocksAndErrors[i * 2] as Catch;
        Statement? error = catchBlocksAndErrors[i * 2 + 1] as Statement?;
        if (error != null) {
          compileTimeErrors ??= <Statement>[];
          compileTimeErrors.add(error);
        }
      }
    }
    Statement tryBlock = popStatement(tryKeyword);
    int fileOffset = offsetForToken(tryKeyword);
    Statement result = forest.createTryStatement(
      fileOffset,
      tryBlock,
      catchBlocks,
      finallyBlock,
    );
    assignedVariables.storeInfo(result, tryStatementInfoStack.head);
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
    Token? question,
    Token openSquareBracket,
    Token closeSquareBracket,
  ) {
    assert(
      checkState(openSquareBracket, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Initializer,
        ]),
      ]),
    );
    debugEvent("IndexedExpression");
    Expression index = popForValue();
    Object? receiver = pop();
    bool isNullAware = question != null;
    if (receiver is Generator) {
      push(
        receiver.buildIndexedAccess(
          index,
          openSquareBracket,
          isNullAware: isNullAware,
        ),
      );
    } else if (receiver is Expression) {
      push(
        IndexedAccessGenerator.make(
          this,
          openSquareBracket,
          receiver,
          index,
          isNullAware: isNullAware,
        ),
      );
    } else {
      assert(receiver is Initializer);
      push(
        IndexedAccessGenerator.make(
          this,
          openSquareBracket,
          toValue(receiver),
          index,
          isNullAware: isNullAware,
        ),
      );
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds(<ValueKind>[ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    debugEvent("UnaryPrefixExpression");
    Object? receiver = pop();
    if (token.isA(TokenType.BANG)) {
      push(forest.createNot(offsetForToken(token), toValue(receiver)));
    } else {
      String operator = token.stringValue!;
      if (token.isA(TokenType.MINUS)) {
        operator = "unary-";
      }
      int fileOffset = offsetForToken(token);
      Name name = new Name(operator);
      if (receiver is Generator) {
        push(receiver.buildUnaryOperation(token, name));
      } else if (receiver is Expression) {
        push(forest.createUnary(fileOffset, name, receiver));
      } else {
        // Coverage-ignore-block(suite): Not run.
        Expression value = toValue(receiver);
        push(forest.createUnary(fileOffset, name, value));
      }
    }
  }

  Name incrementOperator(Token token) {
    if (token.isA(TokenType.PLUS_PLUS)) return plusName;
    if (token.isA(TokenType.MINUS_MINUS)) return minusName;
    return unhandled(token.lexeme, "incrementOperator", token.charOffset, uri);
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    Object? generator = pop();
    if (generator is Generator) {
      push(
        generator.buildPrefixIncrement(
          incrementOperator(token),
          operatorOffset: token.charOffset,
        ),
      );
    } else {
      Expression value = toValue(generator);
      push(
        problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: value,
          message: diag.notAnLvalue,
          fileUri: uri,
          fileOffset: value.fileOffset,
          length: noLength,
        ),
      );
    }
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    Object? generator = pop();
    if (generator is Generator) {
      push(
        new DelayedPostfixIncrement(
          this,
          token,
          generator,
          incrementOperator(token),
        ),
      );
    } else {
      Expression value = toValue(generator);
      push(
        problemReporting.wrapInProblem(
          compilerContext: compilerContext,
          expression: value,
          message: diag.notAnLvalue,
          fileUri: uri,
          fileOffset: value.fileOffset,
          length: noLength,
        ),
      );
    }
  }

  @override
  void endConstructorReference(
    Token start,
    Token? periodBeforeName,
    Token endToken,
    ConstructorReferenceContext constructorReferenceContext,
  ) {
    debugEvent("ConstructorReference");
    pushQualifiedReference(
      start,
      periodBeforeName,
      constructorReferenceContext,
    );
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
  void pushQualifiedReference(
    Token start,
    Token? periodBeforeName,
    ConstructorReferenceContext constructorReferenceContext,
  ) {
    assert(
      checkState(start, [
        /*suffix*/ if (periodBeforeName != null)
          unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
        /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
        /*type*/ unionOfKinds([
          ValueKinds.Generator,
          ValueKinds.QualifiedName,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    Object? suffixObject = popIfNotNull(periodBeforeName);
    Identifier? suffix;
    if (suffixObject is Identifier) {
      suffix = suffixObject;
    } else {
      assert(
        suffixObject == null ||
            // Coverage-ignore(suite): Not run.
            suffixObject is ParserRecovery,
        "Unexpected qualified name suffix $suffixObject "
        "(${suffixObject.runtimeType})",
      );
      // There was a `.` without a suffix.
    }

    Identifier? identifier;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    Object? type = pop();
    if (type is QualifiedName) {
      identifier = type;
      QualifiedName qualified = type;
      switch (qualified) {
        case QualifiedNameGenerator():
          Generator qualifier = qualified.qualifier;
          if (qualifier is TypeUseGenerator && suffix == null) {
            type = qualifier;
            if (typeArguments != null) {
              // TODO(ahe): Point to the type arguments instead.
              addProblem(
                diag.constructorWithTypeArguments,
                identifier.nameOffset,
                identifier.name.length,
              );
            }
          } else {
            if (constructorReferenceContext !=
                ConstructorReferenceContext.Implicit) {
              type = qualifier.qualifiedLookup(qualified.token);
            } else {
              type = qualifier.buildSelectorAccess(
                new PropertySelector(
                  this,
                  qualified.token,
                  new Name(qualified.name, libraryBuilder.nameOrigin),
                ),
                qualified.token.charOffset,
                false,
              );
            }
            identifier = null;
          }
        // Coverage-ignore(suite): Not run.
        case QualifiedNameBuilder():
        case QualifiedNameIdentifier():
          unhandled(
            "${qualified.runtimeType}",
            "pushQualifiedReference",
            start.charOffset,
            uri,
          );
      }
    }
    String name;
    if (identifier != null && suffix != null) {
      // Coverage-ignore-block(suite): Not run.
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

    assert(
      checkState(start, [
        /*constructor name identifier*/ ValueKinds.IdentifierOrNull,
        /*constructor name*/ ValueKinds.Name,
        /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
        /*class*/ unionOfKinds([
          ValueKinds.Generator,
          ValueKinds.ParserRecovery,
          ValueKinds.Expression,
        ]),
      ]),
    );
  }

  Expression _buildConstructorInvocation(
    Member target,
    TypeArguments? typeArguments,
    ActualArguments arguments, {
    Constness constness = Constness.implicit,
    required TypeAliasBuilder? typeAliasBuilder,
    required int fileOffset,
    required int charLength,
    required bool hasInferredTypeArguments,
  }) {
    Expression? result = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
      explicitTypeArguments: typeArguments,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: uri,
    );
    if (result != null) {
      return result;
    }

    bool isConst =
        constness == Constness.explicitConst ||
        constantContext != ConstantContext.none;
    if (target is Constructor) {
      if (constantContext == ConstantContext.required &&
          constness == Constness.implicit) {
        addProblem(diag.missingExplicitConst, fileOffset, charLength);
      }
      if (isConst && !target.isConst) {
        return buildProblem(
          message: diag.nonConstConstructor,
          fileUri: uri,
          fileOffset: fileOffset,
          length: charLength,
        );
      }
      Expression node;
      if (typeAliasBuilder == null) {
        node = new InternalConstructorInvocation(
          target,
          typeArguments,
          arguments,
          isConst: isConst,
        )..fileOffset = fileOffset;
        if (typeArguments != null) {
          problemReporting.checkBoundsInConstructorInvocation(
            libraryFeatures: libraryFeatures,
            constructor: target,
            explicitOrInferredTypeArguments: typeArguments.types,
            typeEnvironment: typeEnvironment,
            fileUri: uri,
            fileOffset: fileOffset,
            hasInferredTypeArguments: hasInferredTypeArguments,
          );
        }
      } else {
        node = new TypeAliasedConstructorInvocation(
          typeAliasBuilder,
          target,
          typeArguments,
          arguments,
          isConst: isConst,
        )..fileOffset = fileOffset;
        // No type arguments were passed, so we need not check bounds.
        assert(typeArguments == null);
      }
      return node;
    } else {
      Procedure procedure = target as Procedure;
      if (constantContext == ConstantContext.required &&
          // Coverage-ignore(suite): Not run.
          constness == Constness.implicit) {
        // Coverage-ignore-block(suite): Not run.
        addProblem(diag.missingExplicitConst, fileOffset, charLength);
      }
      if (isConst && !procedure.isConst) {
        if (procedure.isExtensionTypeMember) {
          // Both generative constructors and factory constructors from
          // extension type declarations are encoded as procedures so we use
          // the message for non-const constructors here.
          return buildProblem(
            message: diag.nonConstConstructor,
            fileUri: uri,
            fileOffset: fileOffset,
            length: charLength,
          );
        } else {
          return buildProblem(
            message: diag.nonConstFactory,
            fileUri: uri,
            fileOffset: fileOffset,
            length: charLength,
          );
        }
      }
      Expression node;
      if (typeAliasBuilder == null) {
        FactoryConstructorInvocation factoryConstructorInvocation =
            new FactoryConstructorInvocation(
              target,
              typeArguments,
              arguments,
              isConst: isConst,
            )..fileOffset = fileOffset;
        if (typeArguments != null) {
          problemReporting.checkBoundsInFactoryInvocation(
            libraryFeatures: libraryFeatures,
            factory: target,
            explicitOrInferredTypeArguments: typeArguments.types,
            typeEnvironment: typeEnvironment,
            fileUri: uri,
            fileOffset: fileOffset,
            hasInferredTypeArguments: hasInferredTypeArguments,
          );
        }
        node = factoryConstructorInvocation;
      } else {
        TypeAliasedFactoryInvocation typeAliasedFactoryInvocation =
            new TypeAliasedFactoryInvocation(
              typeAliasBuilder,
              target,
              typeArguments,
              arguments,
              isConst: isConst,
            )..fileOffset = fileOffset;
        // No type arguments were passed, so we need not check bounds.
        assert(typeArguments == null);
        node = typeAliasedFactoryInvocation;
      }
      return node;
    }
  }

  @override
  Expression buildStaticInvocation({
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required int fileOffset,
  }) {
    Expression? result = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
      explicitTypeArguments: typeArguments,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: uri,
    );
    if (result != null) {
      return result;
    }

    return new InternalStaticInvocation(
      target.name,
      target,
      typeArguments,
      arguments,
    )..fileOffset = fileOffset;
  }

  @override
  void beginNewExpression(Token token) {
    debugEvent("beginNewExpression");
    super.push(constantContext);
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
  void endConstLiteral(Token endToken) {
    debugEvent("endConstLiteral");
    Object? literal = pop();
    constantContext = pop() as ConstantContext;
    push(literal);
  }

  @override
  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    _buildConstructorReferenceInvocation(
      token.next!,
      token.offset,
      Constness.explicitNew,
      inMetadata: false,
      inImplicitCreationContext: false,
    );
    if (constantContext != ConstantContext.none) {
      pop(); // Pop the created new expression.
      push(
        buildProblem(
          message: diag.notConstantExpression.withArguments(
            description: 'New expression',
          ),
          fileUri: uri,
          fileOffset: token.charOffset,
          length: token.length,
        ),
      );
    }
  }

  void _buildConstructorReferenceInvocation(
    Token nameToken,
    int offset,
    Constness constness, {
    required bool inMetadata,
    required bool inImplicitCreationContext,
  }) {
    assert(
      checkState(nameToken, [
        /*arguments*/ unionOfKinds([
          ValueKinds.Arguments,
          ValueKinds.ParserRecovery,
        ]),
        /*constructor name identifier*/ ValueKinds.IdentifierOrNull,
        /*constructor name*/ ValueKinds.Name,
        /*type arguments*/ ValueKinds.TypeArgumentsOrNull,
        /*class*/ unionOfKinds([
          ValueKinds.Generator,
          ValueKinds.ParserRecovery,
          ValueKinds.Expression,
        ]),
        /*previous constant context*/ ValueKinds.ConstantContext,
      ]),
    );
    Object? arguments = pop();
    Identifier? nameLastIdentifier = pop(NullValues.Identifier) as Identifier?;
    Token nameLastToken = nameLastIdentifier?.token ?? nameToken;
    String name = pop() as String;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;
    if (inMetadata && typeArguments != null) {
      if (!libraryFeatures.genericMetadata.isEnabled) {
        handleRecoverableError(
          diag.metadataTypeArguments,
          nameLastToken.next!,
          nameLastToken.next!,
        );
      }
    }

    Object? type = pop();

    ConstantContext savedConstantContext = pop() as ConstantContext;

    if (arguments is! ActualArguments) {
      push(new ParserErrorGenerator(this, nameToken, diag.syntheticToken));
      arguments = forest.createArgumentsEmpty(offset);
    } else if (type is Generator) {
      push(
        type.invokeConstructor(
          name: name,
          typeArgumentBuilders: typeArguments,
          typeArguments: null,
          arguments: arguments,
          nameToken: nameToken,
          nameLastToken: nameLastToken,
          constness: constness,
          inImplicitCreationContext: inImplicitCreationContext,
        ),
      );
    } else if (type is ParserRecovery) {
      push(new ParserErrorGenerator(this, nameToken, diag.syntheticToken));
    } else if (type is InvalidExpression) {
      // Coverage-ignore-block(suite): Not run.
      push(type);
    } else if (type is Expression) {
      push(
        createInstantiationAndInvocation(
          () => type,
          typeArguments,
          name,
          name,
          arguments,
          instantiationOffset: offset,
          invocationOffset: nameLastToken.charOffset,
          inImplicitCreationContext: inImplicitCreationContext,
        ),
      );
    } else {
      // Coverage-ignore-block(suite): Not run.
      String? typeName;
      push(
        buildUnresolvedError(
          debugName(typeName!, name),
          nameLastToken.charOffset,
          kind: UnresolvedKind.Constructor,
        ),
      );
    }
    constantContext = savedConstantContext;
    assert(
      checkState(nameToken, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
  }

  @override
  Expression createInstantiationAndInvocation(
    Expression Function() receiverFunction,
    List<TypeBuilder>? typeArgumentBuilders,
    String className,
    String constructorName,
    ActualArguments arguments, {
    required int instantiationOffset,
    required int invocationOffset,
    required bool inImplicitCreationContext,
  }) {
    if (libraryFeatures.constructorTearoffs.isEnabled &&
        inImplicitCreationContext) {
      Expression receiver = receiverFunction();
      if (typeArgumentBuilders != null) {
        if (receiver is StaticTearOff &&
                (receiver.target.isFactory ||
                    isTearOffLowering(receiver.target)) ||
            receiver is ConstructorTearOff ||
            receiver is RedirectingFactoryTearOff) {
          return buildProblem(
            message: diag.constructorTearOffWithTypeArguments,
            fileUri: uri,
            fileOffset: instantiationOffset,
            length: noLength,
          );
        }
        receiver = forest.createInstantiation(
          instantiationOffset,
          receiver,
          buildDartTypeArguments(
            typeArgumentBuilders,
            TypeUse.tearOffTypeArgument,
            allowPotentiallyConstantType: true,
          ),
        );
      }
      return forest.createMethodInvocation(
        invocationOffset,
        receiver,
        new Name(constructorName, libraryBuilder.nameOrigin),
        null,
        arguments,
        isNullAware: false,
      );
    } else {
      if (typeArgumentBuilders != null) {
        buildDartTypeArguments(
          typeArgumentBuilders,
          TypeUse.constructorTypeArgument,
          allowPotentiallyConstantType: false,
        );
      }
      return buildUnresolvedError(
        constructorNameForDiagnostics(constructorName, className: className),
        invocationOffset,
        kind: UnresolvedKind.Constructor,
      );
    }
  }

  @override
  void endImplicitCreationExpression(Token token, Token openAngleBracket) {
    debugEvent("ImplicitCreationExpression");
    _buildConstructorReferenceInvocation(
      token,
      openAngleBracket.offset,
      Constness.implicit,
      inMetadata: false,
      inImplicitCreationContext: true,
    );
  }

  @override
  ConstructorResolutionResult resolveAndBuildConstructorInvocation(
    TypeDeclarationBuilder? typeDeclarationBuilder,
    Token nameToken,
    Token nameLastToken,
    ActualArguments arguments,
    String name,
    List<TypeBuilder>? typeArgumentBuilders,
    TypeArguments? typeArguments,
    int charOffset,
    Constness constness, {
    required bool isTypeArgumentsInForest,
    TypeAliasBuilder? typeAliasBuilder,
    required UnresolvedKind unresolvedKind,
  }) {
    bool hasInferredTypeArguments = false;
    if (name.isNotEmpty && typeArguments != null) {
      // TODO(ahe): Point to the type arguments instead.
      addProblem(
        diag.constructorWithTypeArguments,
        nameToken.charOffset,
        nameToken.length,
      );
    }

    String? errorName;
    if (typeDeclarationBuilder is TypeAliasBuilder) {
      errorName = debugName(typeDeclarationBuilder.name, name);
      TypeAliasBuilder aliasBuilder = typeDeclarationBuilder;
      int numberOfTypeParameters = aliasBuilder.typeParametersCount;
      int numberOfTypeArguments = typeArgumentBuilders?.length ?? 0;
      if (typeArgumentBuilders != null &&
          numberOfTypeParameters != numberOfTypeArguments) {
        // TODO(eernst): Use position of type arguments, not nameToken.
        return new ErroneousConstructorResolutionResult(
          errorExpression: evaluateArgumentsBefore(
            arguments,
            buildProblem(
              message: diag.typeArgumentMismatch.withArguments(
                expectedCount: numberOfTypeParameters,
              ),
              fileUri: uri,
              fileOffset: charOffset,
              length: noLength,
            ),
          ),
        );
      }
      typeDeclarationBuilder = aliasBuilder.unaliasDeclaration(
        null,
        isUsedAsClass: true,
        usedAsClassCharOffset: nameToken.charOffset,
        usedAsClassFileUri: uri,
      );
      if (typeArgumentBuilders == null) {
        if (aliasBuilder.typeParametersCount > 0) {
          // Raw generic type alias used for instance creation, needs inference.
          switch (typeDeclarationBuilder) {
            case ClassBuilder():
              MemberLookupResult? result = typeDeclarationBuilder
                  .findConstructorOrFactory(name, libraryBuilder);
              Member? target;
              if (result == null) {
                // Not found. Reported below.
                target = null;
              } else if (result.isInvalidLookup) {
                return new ErroneousConstructorResolutionResult(
                  errorExpression: _buildProblemFromLocatedMessage(
                    LookupResult.createDuplicateMessage(
                      result,
                      enclosingDeclaration: typeDeclarationBuilder,
                      name: name,
                      fileUri: uri,
                      fileOffset: charOffset,
                      length: noLength,
                    ),
                  ),
                );
              } else {
                MemberBuilder? constructorBuilder = result.getable!;
                if (constructorBuilder is ConstructorBuilder) {
                  if (typeDeclarationBuilder.isAbstract) {
                    return new ErroneousConstructorResolutionResult(
                      errorExpression: evaluateArgumentsBefore(
                        arguments,
                        buildAbstractClassInstantiationError(
                          diag.abstractClassInstantiation.withArguments(
                            name: typeDeclarationBuilder.name,
                          ),
                          typeDeclarationBuilder.name,
                          nameToken.charOffset,
                        ),
                      ),
                    );
                  }
                  target = constructorBuilder.invokeTarget;
                } else {
                  target = constructorBuilder.invokeTarget;
                }
              }
              if (target is Constructor ||
                  (target is Procedure &&
                      target.kind == ProcedureKind.Factory)) {
                return new SuccessfulConstructorResolutionResult(
                  _buildConstructorInvocation(
                    target!,
                    typeArguments,
                    arguments,
                    constness: constness,
                    typeAliasBuilder: aliasBuilder,
                    fileOffset: nameToken.charOffset,
                    charLength: nameToken.length,
                    hasInferredTypeArguments: hasInferredTypeArguments,
                  ),
                );
              } else {
                return new UnresolvedConstructorResolutionResult(
                  helper: this,
                  errorName: errorName,
                  charOffset: nameLastToken.charOffset,
                  unresolvedKind: unresolvedKind,
                );
              }
            case ExtensionTypeDeclarationBuilder():
              // TODO(johnniwinther): Add shared interface between
              //  [ClassBuilder] and [ExtensionTypeDeclarationBuilder].
              MemberLookupResult? result = typeDeclarationBuilder
                  .findConstructorOrFactory(name, libraryBuilder);
              MemberBuilder? constructorBuilder = result?.getable;
              if (result != null && result.isInvalidLookup) {
                // Coverage-ignore-block(suite): Not run.
                return new ErroneousConstructorResolutionResult(
                  errorExpression: _buildProblemFromLocatedMessage(
                    LookupResult.createDuplicateMessage(
                      result,
                      enclosingDeclaration: typeDeclarationBuilder,
                      name: name,
                      fileUri: uri,
                      fileOffset: charOffset,
                      length: noLength,
                    ),
                  ),
                );
              } else if (constructorBuilder == null) {
                // Not found. Reported below.
              } else if (constructorBuilder is ConstructorBuilder ||
                  // Coverage-ignore(suite): Not run.
                  constructorBuilder is FactoryBuilder) {
                Member target = constructorBuilder.invokeTarget!;
                return new SuccessfulConstructorResolutionResult(
                  _buildConstructorInvocation(
                    target,
                    typeArguments,
                    arguments,
                    constness: constness,
                    typeAliasBuilder: aliasBuilder,
                    fileOffset: nameToken.charOffset,
                    charLength: nameToken.length,
                    hasInferredTypeArguments: hasInferredTypeArguments,
                  ),
                );
              }
              return new UnresolvedConstructorResolutionResult(
                helper: this,
                errorName: errorName,
                charOffset: nameLastToken.charOffset,
                unresolvedKind: unresolvedKind,
              );
            case InvalidBuilder():
              // Coverage-ignore(suite): Not run.
              LocatedMessage message = typeDeclarationBuilder.message;
              // Coverage-ignore(suite): Not run.
              return new ErroneousConstructorResolutionResult(
                errorExpression: evaluateArgumentsBefore(
                  arguments,
                  buildProblem(
                    message: message.messageObject,
                    fileUri: uri,
                    fileOffset: nameToken.charOffset,
                    length: nameToken.lexeme.length,
                  ),
                ),
              );
            case TypeAliasBuilder():
            // Coverage-ignore(suite): Not run.
            case NominalParameterBuilder():
            // Coverage-ignore(suite): Not run.
            case StructuralParameterBuilder():
            // Coverage-ignore(suite): Not run.
            case ExtensionBuilder():
            // Coverage-ignore(suite): Not run.
            case BuiltinTypeDeclarationBuilder():
            case null:
              return new UnresolvedConstructorResolutionResult(
                helper: this,
                errorName: errorName,
                charOffset: nameLastToken.charOffset,
                unresolvedKind: unresolvedKind,
              );
          }
        } else {
          // Empty `typeArguments` and `aliasBuilder``is non-generic, but it
          // may still unalias to a class type with some type arguments.
          switch (typeDeclarationBuilder) {
            case ClassBuilder():
            case ExtensionTypeDeclarationBuilder():
              List<TypeBuilder>? unaliasedTypeArgumentBuilders = aliasBuilder
                  .unaliasTypeArguments(const []);
              if (unaliasedTypeArgumentBuilders == null) {
                // Coverage-ignore-block(suite): Not run.
                // TODO(eernst): This is a wrong number of type arguments,
                // occurring indirectly (in an alias of an alias, etc.).
                return new ErroneousConstructorResolutionResult(
                  errorExpression: evaluateArgumentsBefore(
                    arguments,
                    buildProblem(
                      message: diag.typeArgumentMismatch.withArguments(
                        expectedCount: numberOfTypeParameters,
                      ),
                      fileUri: uri,
                      fileOffset: nameToken.charOffset,
                      length: nameToken.length,
                      errorHasBeenReported: true,
                    ),
                  ),
                );
              }
              if (unaliasedTypeArgumentBuilders.isNotEmpty) {
                List<DartType> dartTypeArguments = [];
                for (TypeBuilder typeBuilder in unaliasedTypeArgumentBuilders) {
                  dartTypeArguments.add(
                    typeBuilder.build(
                      libraryBuilder,
                      TypeUse.constructorTypeArgument,
                    ),
                  );
                }
                hasInferredTypeArguments = isTypeArgumentsInForest
                    ? typeArguments == null
                    : typeArgumentBuilders == null;
                typeArguments = new TypeArguments(dartTypeArguments);
              }
            case TypeAliasBuilder():
            // Coverage-ignore(suite): Not run.
            case NominalParameterBuilder():
            // Coverage-ignore(suite): Not run.
            case StructuralParameterBuilder():
            // Coverage-ignore(suite): Not run.
            case ExtensionBuilder():
            // Coverage-ignore(suite): Not run.
            case InvalidBuilder():
            // Coverage-ignore(suite): Not run.
            case BuiltinTypeDeclarationBuilder():
            case null:
          }
        }
      }

      DartType typeToCheck = new TypedefType(
        aliasBuilder.typedef,
        Nullability.nonNullable,
        typeArgumentBuilders != null
            ? new List.generate(
                typeArgumentBuilders.length,
                (int index) => typeArgumentBuilders[index].build(
                  libraryBuilder,
                  TypeUse.constructorTypeArgument,
                ),
              )
            : null,
      );
      problemReporting.checkBoundsInType(
        libraryFeatures: libraryFeatures,
        type: typeToCheck,
        typeEnvironment: typeEnvironment,
        fileUri: uri,
        fileOffset: charOffset,
        allowSuperBounded: false,
        hasInferredTypeArguments: false,
      );

      switch (typeDeclarationBuilder) {
        case ClassBuilder():
        case ExtensionTypeDeclarationBuilder():
          if (typeArgumentBuilders != null) {
            int numberOfTypeParameters = aliasBuilder.typeParametersCount;
            if (numberOfTypeParameters != typeArgumentBuilders.length) {
              // Coverage-ignore-block(suite): Not run.
              // TODO(eernst): Use position of type arguments, not nameToken.
              return new ErroneousConstructorResolutionResult(
                errorExpression: evaluateArgumentsBefore(
                  arguments,
                  buildProblem(
                    message: diag.typeArgumentMismatch.withArguments(
                      expectedCount: numberOfTypeParameters,
                    ),
                    fileUri: uri,
                    fileOffset: nameToken.charOffset,
                    length: nameToken.length,
                  ),
                ),
              );
            }
            List<TypeBuilder>? unaliasedTypeArgumentBuilders = aliasBuilder
                .unaliasTypeArguments(typeArgumentBuilders);
            if (unaliasedTypeArgumentBuilders == null) {
              // Coverage-ignore-block(suite): Not run.
              // TODO(eernst): This is a wrong number of type arguments,
              // occurring indirectly (in an alias of an alias, etc.).
              return new ErroneousConstructorResolutionResult(
                errorExpression: evaluateArgumentsBefore(
                  arguments,
                  buildProblem(
                    message: diag.typeArgumentMismatch.withArguments(
                      expectedCount: numberOfTypeParameters,
                    ),
                    fileUri: uri,
                    fileOffset: nameToken.charOffset,
                    length: nameToken.length,
                    errorHasBeenReported: true,
                  ),
                ),
              );
            }
            if (unaliasedTypeArgumentBuilders.isNotEmpty) {
              List<DartType> dartTypeArguments = [];
              for (TypeBuilder typeBuilder in unaliasedTypeArgumentBuilders) {
                dartTypeArguments.add(
                  typeBuilder.build(
                    libraryBuilder,
                    TypeUse.constructorTypeArgument,
                  ),
                );
              }
              hasInferredTypeArguments = isTypeArgumentsInForest
                  ? typeArguments == null
                  : false;
              typeArguments = new TypeArguments(dartTypeArguments);
            }
          } else {
            LibraryBuilder libraryBuilder;
            List<NominalParameterBuilder>? typeParameters;
            // TODO(johnniwinther): Add a shared interface for [ClassBuilder]
            // and [ExtensionTypeDeclarationBuilder].
            if (typeDeclarationBuilder is ClassBuilder) {
              libraryBuilder = typeDeclarationBuilder.libraryBuilder;
              typeParameters = typeDeclarationBuilder.typeParameters;
            } else {
              typeDeclarationBuilder as ExtensionTypeDeclarationBuilder;
              libraryBuilder = typeDeclarationBuilder.libraryBuilder;
              typeParameters = typeDeclarationBuilder.typeParameters;
            }
            if (typeParameters != null &&
                typeParameters.isNotEmpty &&
                typeArguments == null) {
              // No type arguments provided to unaliased class, use defaults.
              List<DartType> result = new List<DartType>.generate(
                typeParameters.length,
                (int i) => typeParameters![i].defaultType!.build(
                  libraryBuilder,
                  TypeUse.constructorTypeArgument,
                ),
                growable: true,
              );
              hasInferredTypeArguments = isTypeArgumentsInForest
                  ? typeArguments == null
                  : typeArgumentBuilders == null;
              typeArguments = new TypeArguments(result);
            }
          }
        case TypeAliasBuilder():
        case NominalParameterBuilder():
        case StructuralParameterBuilder():
        case ExtensionBuilder():
        case InvalidBuilder():
        // Coverage-ignore(suite): Not run.
        case BuiltinTypeDeclarationBuilder():
        case null:
      }
    } else {
      // TODO(johnniwinther): Could we use [typeArguments] here?
      if (typeArgumentBuilders != null && !isTypeArgumentsInForest) {
        List<DartType> types = buildDartTypeArguments(
          typeArgumentBuilders,
          TypeUse.constructorTypeArgument,
          allowPotentiallyConstantType: false,
        );
        hasInferredTypeArguments = false;
        typeArguments = new TypeArguments(types);
      }
    }
    switch (typeDeclarationBuilder) {
      case ClassBuilder():
        MemberLookupResult? result = typeDeclarationBuilder
            .findConstructorOrFactory(name, libraryBuilder);
        MemberBuilder? constructorBuilder = result?.getable;
        Member? target;
        if (result != null && result.isInvalidLookup) {
          return new ErroneousConstructorResolutionResult(
            errorExpression: _buildProblemFromLocatedMessage(
              LookupResult.createDuplicateMessage(
                result,
                enclosingDeclaration: typeDeclarationBuilder,
                name: name,
                fileUri: uri,
                fileOffset: charOffset,
                length: noLength,
              ),
            ),
          );
        } else if (constructorBuilder == null) {
          // Not found. Reported below.
        } else if (constructorBuilder is ConstructorBuilder) {
          if (typeDeclarationBuilder.isAbstract) {
            return new ErroneousConstructorResolutionResult(
              errorExpression: evaluateArgumentsBefore(
                arguments,
                buildAbstractClassInstantiationError(
                  diag.abstractClassInstantiation.withArguments(
                    name: typeDeclarationBuilder.name,
                  ),
                  typeDeclarationBuilder.name,
                  nameToken.charOffset,
                ),
              ),
            );
          }
          target = constructorBuilder.invokeTarget;
        } else {
          target = constructorBuilder.invokeTarget;
        }
        if (typeDeclarationBuilder.isEnum) {
          if (libraryFeatures.staticExtensions.isEnabled && target == null) {
            return new UnresolvedConstructorResolutionResult(
              errorName: debugName(typeDeclarationBuilder.name, name),
              charOffset: nameLastToken.charOffset,
              helper: this,
            );
          }
          if (!(libraryFeatures.enhancedEnums.isEnabled &&
              target is Procedure &&
              target.kind == ProcedureKind.Factory)) {
            return new ErroneousConstructorResolutionResult(
              errorExpression: buildProblem(
                message: diag.enumInstantiation,
                fileUri: uri,
                fileOffset: nameToken.charOffset,
                length: nameToken.length,
              ),
            );
          }
        }
        if (target is Constructor ||
            (target is Procedure && target.kind == ProcedureKind.Factory)) {
          Expression invocation;

          invocation = _buildConstructorInvocation(
            target!,
            typeArguments,
            arguments,
            constness: constness,
            fileOffset: nameToken.charOffset,
            charLength: nameToken.length,
            typeAliasBuilder: typeAliasBuilder,
            hasInferredTypeArguments: hasInferredTypeArguments,
          );
          return new SuccessfulConstructorResolutionResult(invocation);
        } else {
          errorName ??= debugName(typeDeclarationBuilder.name, name);
        }
      case ExtensionTypeDeclarationBuilder():
        MemberLookupResult? result = typeDeclarationBuilder
            .findConstructorOrFactory(name, libraryBuilder);
        MemberBuilder? constructorBuilder = result?.getable;
        Member? target;
        if (result != null && result.isInvalidLookup) {
          // Coverage-ignore-block(suite): Not run.
          return new ErroneousConstructorResolutionResult(
            errorExpression: _buildProblemFromLocatedMessage(
              LookupResult.createDuplicateMessage(
                result,
                enclosingDeclaration: typeDeclarationBuilder,
                name: name,
                fileUri: uri,
                fileOffset: charOffset,
                length: noLength,
              ),
            ),
          );
        } else if (constructorBuilder == null) {
          // Not found. Reported below.
        } else {
          target = constructorBuilder.invokeTarget;
        }
        if (target != null) {
          return new SuccessfulConstructorResolutionResult(
            _buildConstructorInvocation(
              target,
              typeArguments,
              arguments,
              constness: constness,
              fileOffset: nameToken.charOffset,
              charLength: nameToken.length,
              typeAliasBuilder: typeAliasBuilder,
              hasInferredTypeArguments: hasInferredTypeArguments,
            ),
          );
        } else {
          errorName ??= debugName(typeDeclarationBuilder.name, name);
        }
      case InvalidBuilder():
        LocatedMessage message = typeDeclarationBuilder.message;
        return new ErroneousConstructorResolutionResult(
          errorExpression: evaluateArgumentsBefore(
            arguments,
            buildProblem(
              message: message.messageObject,
              fileUri: uri,
              fileOffset: nameToken.charOffset,
              length: nameToken.lexeme.length,
            ),
          ),
        );
      case TypeAliasBuilder():
      case NominalParameterBuilder():
      case StructuralParameterBuilder():
      case ExtensionBuilder():
      case BuiltinTypeDeclarationBuilder():
      case null:
        errorName ??= debugName(
          typeDeclarationBuilder!.fullNameForErrors,
          name,
        );
    }
    return new UnresolvedConstructorResolutionResult(
      helper: this,
      errorName: errorName,
      charOffset: nameLastToken.charOffset,
      unresolvedKind: unresolvedKind,
    );
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("endConstExpression");
    _buildConstructorReferenceInvocation(
      token.next!,
      token.offset,
      Constness.explicitConst,
      inMetadata: false,
      inImplicitCreationContext: false,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleConstFactory(Token constKeyword) {
    debugEvent("ConstFactory");
    if (!libraryFeatures.constFunctions.isEnabled) {
      handleRecoverableError(diag.constFactory, constKeyword, constKeyword);
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
    assignedVariables.beginNode();

    Condition condition = pop() as Condition;
    PatternGuard? patternGuard = condition.patternGuard;
    if (patternGuard != null) {
      if (patternGuard.guard != null) {
        LocalScope thenScope = _localScope.createNestedScope(
          kind: LocalScopeKind.ifElement,
        );
        exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifCaseHead]);
        enterLocalScope(thenScope);
      } else {
        createAndEnterLocalScope(kind: LocalScopeKind.ifCaseHead);
        for (VariableDeclaration variable
            in patternGuard.pattern.declaredVariables) {
          declareVariable(variable, _localScope);
        }
        LocalScope thenScope = _localScope.createNestedScope(
          kind: LocalScopeKind.ifElement,
        );
        exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifCaseHead]);
        enterLocalScope(thenScope);
      }
    } else {
      createAndEnterLocalScope(kind: LocalScopeKind.ifElement);
    }
    push(condition);

    super.handleThenControlFlow(token);
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    assert(
      checkState(elseToken, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.MapLiteralEntry,
        ]),
        ValueKinds.Condition,
      ]),
    );
    // Resolve the top of the stack so that if it's a delayed assignment it
    // happens before we go into the else block.
    Object then = pop() as Object;
    if (then is! MapLiteralEntry) then = toValue(then);

    Object condition = pop() as Condition;
    exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifElement]);
    push(condition);

    // This is matched by the call to [beginNode] in
    // [handleThenControlFlow] and by the call to [storeInfo] in
    // [endIfElseControlFlow].
    push(assignedVariables.deferNode());
    push(then);
  }

  @override
  void endIfControlFlow(Token token) {
    debugEvent("endIfControlFlow");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.MapLiteralEntry,
        ]),
        ValueKinds.Condition,
        ValueKinds.Token,
      ]),
    );

    Object? entry = pop();
    Condition condition = pop() as Condition;
    exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifElement]);
    Token ifToken = pop() as Token;

    PatternGuard? patternGuard = condition.patternGuard;
    TreeNode node;
    if (entry is MapLiteralEntry) {
      if (patternGuard == null) {
        node = forest.createIfMapEntry(
          offsetForToken(ifToken),
          condition.expression,
          entry,
        );
      } else {
        node = forest.createIfCaseMapEntry(
          offsetForToken(ifToken),
          prelude: [],
          expression: condition.expression,
          patternGuard: patternGuard,
          then: entry,
        );
      }
    } else {
      if (patternGuard == null) {
        node = forest.createIfElement(
          offsetForToken(ifToken),
          condition.expression,
          toValue(entry),
        );
      } else {
        node = forest.createIfCaseElement(
          offsetForToken(ifToken),
          prelude: [],
          expression: condition.expression,
          patternGuard: patternGuard,
          then: toValue(entry),
        );
      }
    }
    push(node);
    // This is matched by the call to [beginNode] in
    // [handleThenControlFlow].
    assignedVariables.endNode(node);
  }

  @override
  void endIfElseControlFlow(Token token) {
    debugEvent("endIfElseControlFlow");
    assert(
      checkState(token, [
        /* else element */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.MapLiteralEntry,
        ]),
        /* then element */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.MapLiteralEntry,
        ]),
        ValueKinds.AssignedVariablesNodeInfo,
        ValueKinds.Condition,
        ValueKinds.Token,
      ]),
    );

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
          node = forest.createIfMapEntry(
            offsetForToken(ifToken),
            condition.expression,
            thenEntry,
            elseEntry,
          );
        } else {
          node = forest.createIfCaseMapEntry(
            offsetForToken(ifToken),
            prelude: [],
            expression: condition.expression,
            patternGuard: patternGuard,
            then: thenEntry,
            otherwise: elseEntry,
          );
        }
      } else if (elseEntry is ControlFlowElement) {
        MapLiteralEntry? elseMapEntry = elseEntry.toMapLiteralEntry(
          assignedVariables.reassignInfo,
        );
        if (elseMapEntry != null) {
          if (patternGuard == null) {
            node = forest.createIfMapEntry(
              offsetForToken(ifToken),
              condition.expression,
              thenEntry,
              elseMapEntry,
            );
          } else {
            node = forest.createIfCaseMapEntry(
              offsetForToken(ifToken),
              prelude: [],
              expression: condition.expression,
              patternGuard: patternGuard,
              then: thenEntry,
              otherwise: elseMapEntry,
            );
          }
        } else {
          int offset = elseEntry.fileOffset;
          node = new MapLiteralEntry(
            buildProblem(
              message: diag.cantDisambiguateAmbiguousInformation,
              fileUri: uri,
              fileOffset: offset,
              length: 1,
            ),
            new NullLiteral(),
          )..fileOffset = offsetForToken(ifToken);
        }
      } else {
        int offset = elseEntry is Expression
            ? elseEntry.fileOffset
            :
              // Coverage-ignore(suite): Not run.
              offsetForToken(ifToken);
        node = new MapLiteralEntry(
          buildProblem(
            message: diag.expectedAfterButGot.withArguments(expected: ':'),
            fileUri: uri,
            fileOffset: offset,
            length: 1,
          ),
          new NullLiteral(),
        )..fileOffset = offsetForToken(ifToken);
      }
    } else if (elseEntry is MapLiteralEntry) {
      if (thenEntry is ControlFlowElement) {
        MapLiteralEntry? thenMapEntry = thenEntry.toMapLiteralEntry(
          assignedVariables.reassignInfo,
        );
        if (thenMapEntry != null) {
          if (patternGuard == null) {
            node = forest.createIfMapEntry(
              offsetForToken(ifToken),
              condition.expression,
              thenMapEntry,
              elseEntry,
            );
          } else {
            // Coverage-ignore-block(suite): Not run.
            node = forest.createIfCaseMapEntry(
              offsetForToken(ifToken),
              prelude: [],
              expression: condition.expression,
              patternGuard: patternGuard,
              then: thenMapEntry,
              otherwise: elseEntry,
            );
          }
        } else {
          int offset = thenEntry.fileOffset;
          node = new MapLiteralEntry(
            buildProblem(
              message: diag.cantDisambiguateAmbiguousInformation,
              fileUri: uri,
              fileOffset: offset,
              length: 1,
            ),
            new NullLiteral(),
          )..fileOffset = offsetForToken(ifToken);
        }
      } else {
        int offset = thenEntry is Expression
            ? thenEntry.fileOffset
            :
              // Coverage-ignore(suite): Not run.
              offsetForToken(ifToken);
        node = new MapLiteralEntry(
          buildProblem(
            message: diag.expectedAfterButGot.withArguments(expected: ':'),
            fileUri: uri,
            fileOffset: offset,
            length: 1,
          ),
          new NullLiteral(),
        )..fileOffset = offsetForToken(ifToken);
      }
    } else {
      if (condition.patternGuard == null) {
        node = forest.createIfElement(
          offsetForToken(ifToken),
          condition.expression,
          toValue(thenEntry),
          toValue(elseEntry),
        );
      } else {
        node = forest.createIfCaseElement(
          offsetForToken(ifToken),
          prelude: [],
          expression: condition.expression,
          patternGuard: condition.patternGuard!,
          then: toValue(thenEntry),
          otherwise: toValue(elseEntry),
        );
      }
    }
    push(node);
    // This is matched by the call to [deferNode] in
    // [handleElseControlFlow].
    assignedVariables.storeInfo(node, assignedVariablesInfo);
  }

  @override
  void handleNullAwareElement(Token nullAwareElement) {
    debugEvent("NullAwareElement");
    if (!libraryFeatures.nullAwareElements.isEnabled) {
      addProblem(
        diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: ExperimentalFlag.nullAwareElements.name,
        ),
        nullAwareElement.offset,
        noLength,
      );
    }
    Expression expression = popForValue(); // Expression.
    push(
      forest.createNullAwareElement(
        offsetForToken(nullAwareElement),
        expression,
      ),
    );
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    debugEvent("SpreadExpression");
    Object? expression = pop();
    push(
      forest.createSpreadElement(
        offsetForToken(spreadToken),
        toValue(expression),
        isNullAware: spreadToken.lexeme == '...?',
      ),
    );
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(
      const FixedNullableList<TypeBuilder>().popNonNullable(
            stack,
            count,
            dummyTypeBuilder,
          ) ??
          NullValues.TypeArguments,
    );
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
        if (constantContext != ConstantContext.none) {
          push(
            new IncompleteErrorGenerator(this, token, diag.thisAsIdentifier),
          );
        } else {
          push(
            _createReadOnlyVariableAccess(
              thisVariable!,
              token,
              offsetForToken(token),
              'this',
              ReadOnlyAccessKind.ExtensionThis,
            ),
          );
        }
      } else if ((!inConstructorInitializer || !inInitializerLeftHandSide) &&
          (_context.isExtensionDeclaration ||
              _context.isExtensionTypeDeclaration)) {
        // In an extension (type) where we don't (here) have a "this" variable.
        push(new IncompleteErrorGenerator(this, token, diag.thisAsIdentifier));
      } else {
        push(
          new ThisAccessGenerator(
            this,
            token,
            inInitializerLeftHandSide,
            inFieldInitializer,
            inLateFieldInitializer,
          ),
        );
      }
    } else {
      push(new IncompleteErrorGenerator(this, token, diag.thisAsIdentifier));
    }
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    debugEvent("SuperExpression");
    if (context.isScopeReference &&
        isDeclarationInstanceContext &&
        thisVariable == null) {
      _context.registerSuperCall();
      push(
        new ThisAccessGenerator(
          this,
          token,
          inInitializerLeftHandSide,
          inFieldInitializer,
          inLateFieldInitializer,
          isSuper: true,
        ),
      );
    } else {
      push(new IncompleteErrorGenerator(this, token, diag.superAsIdentifier));
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleAugmentSuperExpression(
    Token augmentToken,
    Token superToken,
    IdentifierContext context,
  ) {
    debugEvent("AugmentSuperExpression");
    AugmentSuperTarget? augmentSuperTarget = _context.augmentSuperTarget;
    if (augmentSuperTarget != null) {
      push(
        new AugmentSuperAccessGenerator(this, augmentToken, augmentSuperTarget),
      );
      return;
    }
    push(
      new IncompleteErrorGenerator(
        this,
        augmentToken,
        diag.invalidAugmentSuper,
      ),
    );
  }

  @override
  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument");
    assert(
      checkState(colon, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
      ]),
    );
    Expression value = popForValue();
    Object? identifier = pop();
    if (identifier is Identifier) {
      push(
        new NamedArgument(
          new NamedExpression(identifier.name, value)
            ..fileOffset = identifier.nameOffset,
        ),
      );
    } else {
      assert(
        identifier is ParserRecovery,
        "Unexpected argument name: "
        "${identifier} (${identifier.runtimeType})",
      );
      push(identifier);
    }
  }

  @override
  void handlePositionalArgument(Token token) {
    debugEvent("NamedArgument");
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression value = popForValue();
    push(new PositionalArgument(value));
  }

  @override
  void handleNamedRecordField(Token colon) {
    debugEvent("handleNamedRecordField");
    assert(
      checkState(colon, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
      ]),
    );
    Expression value = popForValue();
    Object? identifier = pop();
    if (identifier is Identifier) {
      push(
        new NamedExpression(identifier.name, value)
          ..fileOffset = identifier.nameOffset,
      );
    } else {
      assert(
        identifier is ParserRecovery,
        "Unexpected record field name: "
        "${identifier} (${identifier.runtimeType})",
      );
      push(identifier);
    }
  }

  @override
  void handlePositionalRecordField(Token token) {
    debugEvent("handlePositionalRecordField");
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression value = popForValue();
    push(value);
  }

  @override
  void endFunctionName(
    Token beginToken,
    Token token,
    bool isFunctionExpression,
  ) {
    debugEvent("FunctionName");
    Identifier name = pop() as Identifier;
    Token nameToken = name.token;
    String identifierName = name.name;
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && identifierName == '_';
    if (isWildcard) {
      identifierName = createWildcardVariableName(wildcardVariableIndex);
      wildcardVariableIndex++;
    }
    VariableDeclaration variable = new VariableDeclarationImpl(
      identifierName,
      forSyntheticToken: nameToken.isSynthetic,
      isFinal: true,
      isLocalFunction: true,
      isWildcard: isWildcard,
    )..fileOffset = name.nameOffset;
    push(
      new FunctionDeclarationImpl(
        variable,
        // The real function node is created later.
        dummyFunctionNode,
      )..fileOffset = beginToken.charOffset,
    );
    if (!(libraryFeatures.wildcardVariables.isEnabled && variable.isWildcard)) {
      // The local scope stack contains a type parameter scope for the local
      // function on top of the scope for the block in which the local function
      // declaration occurs. So for a local function declaration, we add the
      // declaration to the previous scope, i.e. the block scope.
      //
      // For a named function expression, a nested scope is created to hold the
      // name, so that it doesn't pollute the block scope (the named function
      // expression is erroneous and should introduce the name in the scope) and
      // we therefore use the current scope in this case.
      LocalScope scope = isFunctionExpression
          ? _localScope
          : _localScopes.previous;
      declareVariable(variable, scope);
    }
  }

  void enterFunction() {
    _enterLocalState();
    debugEvent("enterFunction");
    functionNestingLevel++;
    _switchScopes.push(null);
    push(inCatchBlock);
    inCatchBlock = false;
    // This is matched by the call to [endNode] in [pushNamedFunction] or
    // [endFunctionExpression].
    assignedVariables.beginNode();
    assert(checkState(null, [/* inCatchBlock */ ValueKinds.Bool]));
  }

  void exitFunction() {
    assert(
      checkState(null, [
        /* inCatchBlock */ ValueKinds.Bool,
        /* nominal parameters */ ValueKinds.NominalVariableListOrNull,
      ]),
    );
    debugEvent("exitFunction");
    functionNestingLevel--;
    inCatchBlock = pop() as bool;
    _switchScopes.pop();
    List<NominalParameterBuilder>? typeParameters =
        pop() as List<NominalParameterBuilder>?;
    exitLocalScope();
    push(typeParameters ?? NullValues.NominalParameters);
    _exitLocalState();
    assert(checkState(null, [ValueKinds.NominalVariableListOrNull]));
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    debugEvent("beginLocalFunctionDeclaration");
    enterFunction();
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    debugEvent("beginNamedFunctionExpression");
    List<NominalParameterBuilder>? typeParameters =
        pop() as List<NominalParameterBuilder>?;
    // Create an additional scope in which the named function expression is
    // declared.
    createAndEnterLocalScope(kind: LocalScopeKind.namedFunctionExpression);
    push(typeParameters ?? NullValues.NominalParameters);
    enterFunction();
  }

  @override
  void beginFunctionExpression(Token token) {
    debugEvent("beginFunctionExpression");
    enterFunction();
  }

  void pushNamedFunction(Token token, bool isFunctionExpression) {
    Statement body = popStatement(token);
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    exitLocalScope();
    FormalParameters formals = pop() as FormalParameters;
    Object? declaration = pop();
    TypeBuilder? returnType = pop() as TypeBuilder?;
    bool hasImplicitReturnType = returnType == null;
    exitFunction();
    List<NominalParameterBuilder>? typeParameters =
        pop() as List<NominalParameterBuilder>?;
    List<Expression>? annotations;
    if (!isFunctionExpression) {
      annotations = pop() as List<Expression>?; // Metadata.
    }
    FunctionNode function = formals.buildFunctionNode(
      libraryBuilder,
      returnType,
      typeParameters,
      asyncModifier,
      body,
      token.charOffset,
    );

    if (declaration is FunctionDeclaration) {
      VariableDeclaration variable = declaration.variable;
      if (annotations != null) {
        for (Expression annotation in annotations) {
          variable.addAnnotation(annotation);
        }
      }
      FunctionDeclarationImpl.setHasImplicitReturnType(
        declaration as FunctionDeclarationImpl,
        hasImplicitReturnType,
      );
      if (!hasImplicitReturnType) {
        problemReporting.checkAsyncReturnType(
          libraryBuilder: libraryBuilder,
          typeEnvironment: typeEnvironment,
          asyncMarker: asyncModifier,
          returnType: function.returnType,
          returnTypeBuilder: returnType,
          fileUri: uri,
        );
      }

      variable.type = function.computeFunctionType(Nullability.nonNullable);

      declaration.function = function;
      function.parent = declaration;
      Statement statement;
      if (variable.initializer != null) {
        // This must have been a compile-time error.
        assert(isErroneousNode(variable.initializer!));

        statement = forest
            .createBlock(declaration.fileOffset, noLocation, <Statement>[
              forest.createExpressionStatement(
                offsetForToken(token),
                variable.initializer!,
              ),
              declaration,
            ]);
        variable.initializer = null;
      } else {
        statement = declaration;
      }
      // This is matched by the call to [beginNode] in [enterFunction].
      assignedVariables.endNode(
        declaration,
        isClosureOrLateVariableInitializer: true,
      );
      if (isFunctionExpression) {
        // This is an error case. An expression is expected but we got a
        // function declaration instead. We wrap it in a [BlockExpression].
        exitLocalScope();
        push(
          new BlockExpression(
            forest.createBlock(declaration.fileOffset, noLocation, [statement]),
            buildProblem(
              message: diag.namedFunctionExpression,
              fileUri: uri,
              fileOffset: declaration.fileOffset,
              length: noLength,
              // Error has already been reported by the parser.
              errorHasBeenReported: true,
            ),
          )..fileOffset = declaration.fileOffset,
        );
      } else {
        push(statement);
      }
    } else {
      unhandled(
        "${declaration.runtimeType}",
        "pushNamedFunction",
        token.charOffset,
        uri,
      );
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
  void endFunctionExpression(Token beginToken, Token endToken) {
    debugEvent("FunctionExpression");
    assert(
      checkState(beginToken, [
        /* body */ ValueKinds.StatementOrNull,
        /* async marker */ ValueKinds.AsyncMarker,
        /* formal parameters */ ValueKinds.FormalParameters,
        /* inCatchBlock */ ValueKinds.Bool,
        /* nominal parameters */ ValueKinds.NominalVariableListOrNull,
      ]),
    );
    Statement body =
        popNullableStatement() ??
        // In erroneous cases, there might not be function body. In such cases
        // we use an empty statement instead.
        // TODO(jensj): Is this the offset we want?
        forest.createEmptyStatement(endToken.next!.charOffset);
    AsyncMarker asyncModifier = pop() as AsyncMarker;
    exitLocalScope();
    FormalParameters formals = pop() as FormalParameters;
    exitFunction();
    List<NominalParameterBuilder>? typeParameters =
        pop() as List<NominalParameterBuilder>?;
    FunctionNode function = formals.buildFunctionNode(
      libraryBuilder,
      null,
      typeParameters,
      asyncModifier,
      body,
      // TODO(jensj): Is this the offset we want?
      endToken.next!.charOffset,
    )..fileOffset = beginToken.charOffset;

    Expression result;
    if (constantContext != ConstantContext.none) {
      result = buildProblem(
        message: diag.notAConstantExpression,
        fileUri: uri,
        fileOffset: formals.charOffset,
        length: formals.length,
      );
    } else {
      result = new FunctionExpression(function)
        ..fileOffset = offsetForToken(beginToken);
    }
    push(result);
    // This is matched by the call to [beginNode] in [enterFunction].
    assignedVariables.endNode(result, isClosureOrLateVariableInitializer: true);
    assert(
      checkState(beginToken, [
        /* function expression or problem */ ValueKinds.Expression,
      ]),
    );
  }

  @override
  void beginDoWhileStatement(Token token) {
    debugEvent("beginDoWhileStatement");
    // This is matched by the [endNode] call in [endDoWhileStatement].
    assignedVariables.beginNode();
    enterLoop(token.charOffset);
  }

  @override
  void endDoWhileStatement(
    Token doKeyword,
    Token whileKeyword,
    Token endToken,
  ) {
    debugEvent("DoWhileStatement");
    assert(
      checkState(doKeyword, [
        /* condition = */ ValueKinds.Condition,
        /* body = */ ValueKinds.Statement,
        /* continue target = */ ValueKinds.ContinueTarget,
        /* break target = */ ValueKinds.BreakTarget,
      ]),
    );
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in do statement: ${condition.patternGuard}.",
    );
    Expression expression = condition.expression;
    Statement body = popStatement(doKeyword);
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements = continueTarget.resolveContinues(
        forest,
        labeledStatement,
      );
      body = labeledStatement;
    }
    Statement doStatement = forest.createDoStatement(
      offsetForToken(doKeyword),
      body,
      expression,
    );
    // This is matched by the [beginNode] call in [beginDoWhileStatement].
    assignedVariables.endNode(doStatement);
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
    if (_localScopes.hasPrevious) {
      enterLocalScope(_localScopes.previous);
    } else {
      // Coverage-ignore-block(suite): Not run.
      createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
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
  void handleForInLoopParts(
    Token? awaitToken,
    Token forToken,
    Token leftParenthesis,
    Token? patternKeyword,
    Token inKeyword,
  ) {
    debugEvent("ForInLoopParts");
    assert(
      checkState(forToken, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
          ValueKinds.Statement, // Variable for non-pattern for-in loop.
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    Object expression = pop() as Object;
    Object pattern = pop() as Object;

    if (pattern is Pattern) {
      pop(); // Metadata.
      bool isFinal = patternKeyword?.lexeme == 'final';
      for (VariableDeclaration variable in pattern.declaredVariables) {
        variable.isFinal |= isFinal;
        declareVariable(variable, _localScope);
      }
    }

    push(pattern);
    push(expression);
    push(awaitToken ?? NullValues.AwaitToken);
    push(forToken);
    push(inKeyword);
    // This is matched by the call to [deferNode] in [endForIn] or
    // [endForInControlFlow].
    assignedVariables.beginNode();
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
      assignedVariables.discardNode();

      push(
        buildProblem(
          message: diag.cantUseControlFlowOrSpreadAsConstant.withArguments(
            token: forToken,
          ),
          fileUri: uri,
          fileOffset: forToken.charOffset,
          length: forToken.charCount,
        ),
      );
      return;
    }

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo = assignedVariables
        .popNode();

    Expression iterable = popForValue();
    Object? lvalue = pop(); // lvalue
    exitLocalScope();

    ForInElements elements = _computeForInElements(
      forToken,
      inToken,
      lvalue,
      null,
    );
    assignedVariables.pushNode(assignedVariablesNodeInfo);
    ExpressionVariable variable = elements.variable;
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
        isAsync: awaitToken != null,
      );
      assignedVariables.endNode(result);
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
        isAsync: awaitToken != null,
      );
      assignedVariables.endNode(result);
      push(result);
    }
  }

  ForInElements _computeForInElements(
    Token forToken,
    Token inToken,
    Object? lvalue,
    Statement? body,
  ) {
    ForInElements elements = new ForInElements();
    if (lvalue is VariableDeclaration) {
      // Late for-in variables are not supported. An error has already been
      // reported by the parser.
      lvalue.isLate = false;
      elements.explicitVariableDeclaration = lvalue;
      if (lvalue.isConst) {
        elements.expressionProblem = buildProblem(
          message: diag.forInLoopWithConstVariable,
          fileUri: uri,
          fileOffset: lvalue.fileOffset,
          length: lvalue.name!.length,
        );
        // As a recovery step, remove the const flag, to not confuse the
        // constant evaluator further in the pipeline.
        lvalue.isConst = false;
      }
    } else if (lvalue is VariableInitialization) {
      // Late for-in variables are not supported. An error has already been
      // reported by the parser.
      lvalue.isLate = false;
      elements.explicitVariableDeclaration = lvalue.variable;
      if (lvalue.isConst) {
        // Coverage-ignore-block(suite): Not run.
        elements.expressionProblem = buildProblem(
          message: diag.forInLoopWithConstVariable,
          fileUri: uri,
          fileOffset: lvalue.fileOffset,
          length: lvalue.cosmeticName!.length,
        );
        // As a recovery step, remove the const flag, to not confuse the
        // constant evaluator further in the pipeline.
        lvalue.isConst = false;
      }
    } else if (lvalue is ExpressionVariable) {
      // Coverage-ignore-block(suite): Not run.
      // Late for-in variables are not supported. An error has already been
      // reported by the parser.
      lvalue.isLate = false;
      elements.explicitVariableDeclaration = lvalue;
      if (lvalue.isConst) {
        elements.expressionProblem = buildProblem(
          message: diag.forInLoopWithConstVariable,
          fileUri: uri,
          fileOffset: lvalue.fileOffset,
          length: lvalue.cosmeticName!.length,
        );
        // As a recovery step, remove the const flag, to not confuse the
        // constant evaluator further in the pipeline.
        lvalue.isConst = false;
      }
    } else {
      VariableDeclaration variable = elements.syntheticVariableDeclaration =
          forest.createVariableDeclaration(
            offsetForToken(forToken),
            null,
            isFinal: true,
            isSynthesized: true,
          );
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
          new VariableGet(variable)..fileOffset = inToken.offset,
          voidContext: true,
        );
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
          new VariableGet(variable),
          isFinal: false,
        );
      } else if (lvalue is InvalidExpression) {
        // Coverage-ignore-block(suite): Not run.
        elements.expressionProblem = lvalue;
      } else if (lvalue is ParserRecovery) {
        elements.expressionProblem = buildProblem(
          message: diag.syntheticToken,
          fileUri: uri,
          fileOffset: lvalue.charOffset,
          length: noLength,
        );
      } else {
        Message message = forest.isVariablesDeclaration(lvalue)
            ? diag.forInLoopExactlyOneVariable
            : diag.forInLoopNotAssignable;
        Token token = forToken.next!.next!;
        elements.expressionProblem = buildProblem(
          message: message,
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
        );
        Statement effects;
        if (forest.isVariablesDeclaration(lvalue)) {
          effects = forest.createBlock(
            noLocation,
            noLocation,
            // New list because the declarations are not a growable list.
            new List<Statement>.of(
              forest.variablesDeclarationExtractDeclarations(lvalue),
            ),
          );
        } else {
          effects = forest.createExpressionStatement(
            noLocation,
            lvalue as Expression,
          );
        }
        elements.expressionEffects = combineStatements(
          forest.createExpressionStatement(
            noLocation,
            buildProblem(
              message: message,
              fileUri: uri,
              fileOffset: offsetForToken(token),
              length: lengthForToken(token),
            ),
          ),
          effects,
        );
      }
    }
    return elements;
  }

  @override
  void endForIn(Token endToken) {
    debugEvent("ForIn");
    assert(
      checkState(endToken, [
        /* body= */ unionOfKinds([
          ValueKinds.Statement,
          ValueKinds.ParserRecovery,
        ]),
        /* inKeyword = */ ValueKinds.Token,
        /* forToken = */ ValueKinds.Token,
        /* awaitToken = */ ValueKinds.AwaitTokenOrNull,
        /* expression = */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
        ]),
        /* lvalue = */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
          ValueKinds.Statement,
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    Statement body = popStatement(endToken);

    Token inKeyword = pop() as Token;
    Token forToken = pop() as Token;
    Token? awaitToken = pop(NullValues.AwaitToken) as Token?;

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo = assignedVariables
        .deferNode();

    Expression expression = popForValue();
    Object? lvalue = pop();
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements = continueTarget.resolveContinues(
        forest,
        labeledStatement,
      );
      body = labeledStatement;
    }
    ForInElements elements = _computeForInElements(
      forToken,
      inKeyword,
      lvalue,
      body,
    );
    ExpressionVariable variable = elements.variable;
    Expression? problem = elements.expressionProblem;
    Statement forInStatement;
    if (elements.explicitVariableDeclaration != null) {
      forInStatement =
          new ForInStatement(
              variable,
              expression,
              body,
              isAsync: awaitToken != null,
            )
            ..fileOffset = awaitToken?.charOffset ?? forToken.charOffset
            ..bodyOffset = body.fileOffset; // TODO(ahe): Isn't this redundant?
    } else {
      forInStatement =
          new ForInStatementWithSynthesizedVariable(
              variable,
              expression,
              elements.syntheticAssignment,
              elements.expressionEffects,
              body,
              isAsync: awaitToken != null,
              hasProblem: problem != null,
            )
            ..fileOffset = awaitToken?.charOffset ?? forToken.charOffset
            ..bodyOffset = body.fileOffset; // TODO(ahe): Isn't this redundant?
    }
    assignedVariables.storeInfo(forInStatement, assignedVariablesNodeInfo);
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
        forest.createExpressionStatement(noLocation, problem),
        result,
      );
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label");
    Identifier identifier = pop() as Identifier;
    push(new Label(identifier.name, identifier.nameOffset));
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    debugEvent("beginLabeledStatement");
    List<Label>? labels = const FixedNullableList<Label>().popNonNullable(
      stack,
      labelCount,
      dummyLabel,
    );
    _labelScopes.push(new LabelScopeImpl(_labelScope));
    LabelTarget target = new LabelTarget(
      functionNestingLevel,
      uri,
      token.charOffset,
    );
    if (labels != null) {
      for (Label label in labels) {
        _labelScope.declareLabel(label.name, target);
      }
    }
    push(target);
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");
    Statement statement = popStatementNoWrap();
    LabelTarget target = pop() as LabelTarget;
    _labelScopes.pop();
    // TODO(johnniwinther): Split the handling of breaks and continue.
    if (target.breakTarget.hasUsers || target.continueTarget.hasUsers) {
      if (forest.isVariablesDeclaration(statement)) {
        internalProblem(
          diag.internalProblemLabelUsageInVariablesDeclaration,
          statement.fileOffset,
          uri,
        );
      }
      if (statement is! LabeledStatement) {
        statement = forest.createLabeledStatement(statement);
      }
      target.breakTarget.resolveBreaks(forest, statement, statement);
      List<BreakStatementImpl>? continueStatements = target.continueTarget
          .resolveContinues(forest, statement);
      if (continueStatements != null) {
        for (BreakStatementImpl continueStatement in continueStatements) {
          continueStatement.targetStatement = statement;
          Statement labelStatementBody = statement.body;
          if (labelStatementBody is LoopStatement) {
            Statement loopBody = labelStatementBody.body;
            if (loopBody is LabeledStatement) {
              continueStatement.target = loopBody;
            } else {
              labelStatementBody.body = continueStatement.target =
                  forest.createLabeledStatement(labelStatementBody.body)
                    ..parent = labelStatementBody;
            }
          } else {
            push(
              buildProblemStatement(
                diag.continueLabelInvalid,
                continueStatement.fileOffset,
                length: 8,
              ),
            );
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
      push(
        forest.createRethrowStatement(
          offsetForToken(rethrowToken),
          offsetForToken(endToken),
        ),
      );
    } else {
      push(
        new ExpressionStatement(
          buildProblem(
            message: diag.rethrowNotCatch,
            fileUri: uri,
            fileOffset: offsetForToken(rethrowToken),
            length: lengthForToken(rethrowToken),
          ),
        )..fileOffset = offsetForToken(rethrowToken),
      );
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
    assignedVariables.beginNode();
    enterLoop(token.charOffset);
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    debugEvent("WhileStatement");
    assert(
      checkState(whileKeyword, [
        /* body = */ unionOfKinds([
          ValueKinds.Statement,
          ValueKinds.ParserRecovery,
        ]),
        /* condition = */ ValueKinds.Condition,
        /* continue target = */ ValueKinds.ContinueTarget,
        /* break target = */ ValueKinds.BreakTarget,
      ]),
    );
    Statement body = popStatement(whileKeyword);
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in while statement: ${condition.patternGuard}.",
    );
    Expression expression = condition.expression;
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    List<BreakStatementImpl>? continueStatements;
    if (continueTarget.hasUsers) {
      LabeledStatement labeledStatement = forest.createLabeledStatement(body);
      continueStatements = continueTarget.resolveContinues(
        forest,
        labeledStatement,
      );
      body = labeledStatement;
    }
    Statement whileStatement = forest.createWhileStatement(
      offsetForToken(whileKeyword),
      expression,
      body,
    );
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
    assignedVariables.endNode(whileStatement);
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement");
    push(forest.createEmptyStatement(offsetForToken(token)));
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    debugEvent("beginAssert");
    assignedVariables.enterAssert();
    // If in an assert initializer, make sure [inInitializer] is false so we
    // use the formal parameter scope. If this is any other kind of assert,
    // inInitializer should be false anyway.
    inInitializerLeftHandSide = false;
  }

  @override
  void endAssert(
    Token assertKeyword,
    Assert kind,
    Token leftParenthesis,
    Token? commaToken,
    Token endToken,
  ) {
    debugEvent("Assert");
    assignedVariables.exitAssert();
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
        } else if (nextToken.isA(TokenType.COMMA) &&
            nextToken.next == conditionBoundary) {
          // The next token is trailing comma, which means current token is
          // the last token of the condition.
          break;
        }
        conditionLastToken = nextToken;
      }
      if (conditionLastToken.isEof) {
        // Coverage-ignore-block(suite): Not run.
        endOffset = startOffset = -1;
      } else {
        endOffset = conditionLastToken.offset + conditionLastToken.length;
      }

      return forest.createAssertStatement(
        fileOffset,
        condition,
        message,
        startOffset,
        endOffset,
      );
    }

    switch (kind) {
      case Assert.Statement:
        push(createAssertStatement());
        break;

      case Assert.Expression:
        // The parser has already reported an error indicating that assert
        // cannot be used in an expression.
        push(
          buildProblem(
            message: diag.assertAsExpression,
            fileUri: uri,
            fileOffset: fileOffset,
            length: assertKeyword.length,
          ),
        );
        break;

      case Assert.Initializer:
        push(
          forest.createAssertInitializer(fileOffset, createAssertStatement()),
        );
        break;
    }
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    debugEvent("YieldStatement");
    push(
      forest.createYieldStatement(
        offsetForToken(yieldToken),
        popForValue(),
        isYieldStar: starToken != null,
      ),
    );
  }

  @override
  void beginSwitchBlock(Token token) {
    debugEvent("beginSwitchBlock");
    // This is matched by the [endNode] call in [endSwitchStatement].
    assignedVariables.beginNode();
    createAndEnterLocalScope(kind: LocalScopeKind.switchBlock);
    enterSwitchScope();
    enterBreakTarget(token.charOffset);
    createAndEnterLocalScope(kind: LocalScopeKind.caseHead); // Sentinel scope.
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token beginToken) {
    debugEvent("beginSwitchCase");
    int count = labelCount + expressionCount;
    assert(
      checkState(
        beginToken,
        repeatedKind(
          unionOfKinds([
            ValueKinds.Label,
            ValueKinds.ExpressionOrPatternGuardCase,
          ]),
          count,
        ),
      ),
    );

    List<Label>? labels = labelCount == 0
        ? null
        : new List<Label>.filled(labelCount, dummyLabel);
    int labelIndex = labelCount - 1;
    bool containsPatterns = false;
    List<ExpressionOrPatternGuardCase> expressionOrPatterns =
        new List<ExpressionOrPatternGuardCase>.filled(
          expressionCount,
          dummyExpressionOrPatternGuardCase,
          growable: true,
        );
    int expressionOrPatternIndex = expressionCount - 1;

    for (int i = 0; i < count; i++) {
      Object? value = pop();
      if (value is Label) {
        labels![labelIndex--] = value;
      } else {
        expressionOrPatterns[expressionOrPatternIndex--] =
            value as ExpressionOrPatternGuardCase;
        if (value.patternGuard != null) {
          containsPatterns = true;
        }
      }
    }

    LocalScope switchCaseScope;
    if (expressionCount == 1) {
      // The single-head case. The scope of the head should be remembered
      // and reused later; it already contains the declared pattern
      // variables.
      switchCaseScope = _localScope;
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.caseHead]);
    } else {
      // The multi-head or "default" case. The scope of the last head should
      // be exited, and the new scope for the joint variables should be
      // created.
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.caseHead]);
      switchCaseScope = _localScope.createNestedScope(
        kind: LocalScopeKind.jointVariables,
      );
    }

    assert(_labelScope == _switchScope);

    if (labels != null) {
      for (Label label in labels) {
        String labelName = label.name;
        if (_labelScope.hasLocalLabel(labelName)) {
          // TODO(ahe): Should validate this is a goto target.
          if (!_labelScope.claimLabel(labelName)) {
            addProblem(
              diag.duplicateLabelInSwitchStatement.withArguments(
                labelName: labelName,
              ),
              label.charOffset,
              labelName.length,
            );
          }
        } else {
          _labelScope.declareLabel(
            labelName,
            createGotoTarget(beginToken.charOffset),
          );
        }
      }
    }
    push(expressionOrPatterns);
    push(containsPatterns);
    push(labels ?? NullValues.Labels);

    List<VariableDeclaration>? jointPatternVariables;
    List<VariableDeclaration>? jointPatternVariablesWithMismatchingFinality;
    List<VariableDeclaration>? jointPatternVariablesNotInAll;
    enterLocalScope(switchCaseScope);
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
                  variable.fileOffset,
                  variable.name!,
                )..isFinal = variable.isFinal,
            ];
            if (i != 0) {
              // The previous heads were non-pattern ones, so no variables can
              // be joined.
              (jointPatternVariablesNotInAll ??= []).addAll(
                jointPatternVariables,
              );
            }
          } else {
            Map<String, VariableDeclaration> patternVariablesByName = {
              for (VariableDeclaration variable
                  in patternGuard.pattern.declaredVariables)
                variable.name!: variable,
            };
            for (VariableDeclaration jointVariable in jointPatternVariables) {
              String jointVariableName = jointVariable.name!;
              VariableDeclaration? patternVariable = patternVariablesByName
                  .remove(jointVariableName);
              if (patternVariable != null) {
                if (patternVariable.isFinal != jointVariable.isFinal) {
                  (jointPatternVariablesWithMismatchingFinality ??= []).add(
                    jointVariable,
                  );
                }
              } else {
                (jointPatternVariablesNotInAll ??= []).add(jointVariable);
              }
            }
            if (patternVariablesByName.isNotEmpty) {
              for (VariableDeclaration variable
                  in patternVariablesByName.values) {
                VariableDeclaration jointVariable =
                    forest.createVariableDeclaration(
                      variable.fileOffset,
                      variable.name!,
                    )..isFinal = variable.isFinal;
                (jointPatternVariablesNotInAll ??= []).add(jointVariable);
                jointPatternVariables.add(jointVariable);
              }
            }
          }
        } else {
          // It's a non-pattern head, so no variables can be joined.
          if (jointPatternVariables != null) {
            (jointPatternVariablesNotInAll ??= []).addAll(
              jointPatternVariables,
            );
          }
        }
      }
      if (jointPatternVariables != null) {
        if (jointPatternVariables.isEmpty) {
          jointPatternVariables = null;
        } else {
          for (VariableDeclaration jointVariable in jointPatternVariables) {
            assert(_localScope.kind == LocalScopeKind.jointVariables);
            declareVariable(jointVariable, _localScope);
            assignedVariables.declare(jointVariable);
          }
        }
      }
      switchCaseScope = _localScope.createNestedScope(
        kind: LocalScopeKind.switchCase,
      );
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.jointVariables]);
      enterLocalScope(switchCaseScope);
    } else if (expressionCount == 1) {
      switchCaseScope = _localScope.createNestedScope(
        kind: LocalScopeKind.switchCase,
      );
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.caseHead]);
      enterLocalScope(switchCaseScope);
    }
    push(jointPatternVariablesNotInAll ?? NullValues.VariableDeclarationList);
    push(
      jointPatternVariablesWithMismatchingFinality ??
          NullValues.VariableDeclarationList,
    );
    push(jointPatternVariables ?? NullValues.VariableDeclarationList);

    createAndEnterLocalScope(kind: LocalScopeKind.switchCaseBody);

    assert(
      checkState(beginToken, [
        ValueKinds.VariableDeclarationListOrNull,
        ValueKinds.VariableDeclarationListOrNull,
        ValueKinds.VariableDeclarationListOrNull,
        ValueKinds.LabelListOrNull,
        ValueKinds.Bool,
        ValueKinds.ExpressionOrPatternGuardCaseList,
      ]),
    );
  }

  @override
  void beginSwitchCaseWhenClause(Token when) {
    debugEvent("SwitchCaseWhenClause");
    assert(
      checkState(when, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
        ValueKinds.ConstantContext,
      ]),
    );

    // Here we declare the pattern variables in the scope of the case head. It
    // makes the variables visible in the 'when' clause of the head.
    Object? pattern = peek();
    if (pattern is Pattern) {
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, _localScope);
      }
    }
    push(constantContext);
    constantContext = ConstantContext.none;
  }

  @override
  void endSwitchCaseWhenClause(Token token) {
    debugEvent("SwitchCaseWhenClause");
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        ValueKinds.ConstantContext,
      ]),
    );
    Object? guard = pop();
    constantContext = pop() as ConstantContext;
    push(guard);
  }

  @override
  void handleSwitchCaseNoWhenClause(Token token) {
    debugEvent("SwitchCaseWhenClause");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );

    // Here we declare the pattern variables. It makes the variables visible
    // body of the case.
    Object? pattern = peek();
    if (pattern is Pattern) {
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, _localScope);
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
    Token beginToken,
    Token endToken,
  ) {
    debugEvent("SwitchCase");
    assert(
      checkState(beginToken, [
        ...repeatedKind(ValueKinds.Statement, statementCount),
        ValueKinds.VariableDeclarationListOrNull,
        ValueKinds.VariableDeclarationListOrNull,
        ValueKinds.VariableDeclarationListOrNull,
        ValueKinds.LabelListOrNull,
        ValueKinds.Bool,
        ValueKinds.ExpressionOrPatternGuardCaseList,
      ]),
    );

    // We always create a block here so that we later know that there's always
    // one synthetic block when we finish compiling the switch statement and
    // check this switch case to see if it falls through to the next case.
    Statement block = popBlock(statementCount, beginToken, null);
    exitLocalScope(expectedScopeKinds: const [LocalScopeKind.switchCaseBody]);
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
      _localScope.kind == LocalScopeKind.switchCase ||
          _localScope.kind == LocalScopeKind.jointVariables,
      "Expected the current scope to be of kind '${LocalScopeKind.switchCase}' "
      "or '${LocalScopeKind.jointVariables}', but got '${_localScope.kind}.",
    );
    Map<String, List<int>>? usedNamesOffsets = _localScope.usedNames;

    bool hasDefaultOrLabels = defaultKeyword != null || labelCount > 0;

    List<VariableDeclaration>? usedJointPatternVariables;
    List<int>? jointVariableFirstUseOffsets;
    if (jointPatternVariables != null) {
      usedJointPatternVariables = [];
      Map<VariableDeclaration, int> firstUseOffsets = {};
      for (VariableDeclaration variable in jointPatternVariables) {
        if (usedNamesOffsets?[variable.name!] case [int offset, ...]) {
          usedJointPatternVariables.add(variable);
          firstUseOffsets[variable] = offset;
        }
      }
      if (jointPatternVariablesWithMismatchingFinality != null ||
          jointPatternVariablesNotInAll != null ||
          hasDefaultOrLabels) {
        for (VariableDeclaration jointVariable in usedJointPatternVariables) {
          if (jointPatternVariablesWithMismatchingFinality?.contains(
                jointVariable,
              ) ??
              false) {
            String jointVariableName = jointVariable.name!;
            addProblem(
              diag.jointPatternVariablesMismatch.withArguments(
                variableName: jointVariableName,
              ),
              firstUseOffsets[jointVariable]!,
              jointVariableName.length,
            );
          }
          if (jointPatternVariablesNotInAll?.contains(jointVariable) ?? false) {
            String jointVariableName = jointVariable.name!;
            addProblem(
              diag.jointPatternVariableNotInAll.withArguments(
                variableName: jointVariableName,
              ),
              firstUseOffsets[jointVariable]!,
              jointVariableName.length,
            );
          }
          if (hasDefaultOrLabels) {
            String jointVariableName = jointVariable.name!;
            addProblem(
              diag.jointPatternVariableWithLabelDefault.withArguments(
                variableName: jointVariableName,
              ),
              firstUseOffsets[jointVariable]!,
              jointVariableName.length,
            );
          }
        }
      }
      jointVariableFirstUseOffsets = [
        for (VariableDeclaration variable in usedJointPatternVariables)
          firstUseOffsets[variable]!,
      ];
    }

    exitLocalScope(
      expectedScopeKinds: const [
        LocalScopeKind.switchCase,
        LocalScopeKind.caseHead,
        LocalScopeKind.jointVariables,
      ],
    );

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
          if (usedNamesOffsets[variableName] case [int offset, ...]) {
            addProblem(
              diag.jointPatternVariableWithLabelDefault.withArguments(
                variableName: variableName,
              ),
              offset,
              variableName.length,
            );
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
          patternGuards.add(
            forest.createPatternGuard(
              expressionOrPatternGuard.caseOffset,
              toPattern(expressionOrPatternGuard.expression!),
            ),
          );
        }
      }
      push(
        forest.createPatternSwitchCase(
          beginToken.charOffset,
          caseOffsets,
          patternGuards,
          block,
          isDefault: defaultKeyword != null,
          hasLabel: labels != null,
          jointVariables: usedJointPatternVariables ?? [],
          jointVariableFirstUseOffsets: jointVariableFirstUseOffsets,
        ),
      );
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
      push(
        new SwitchCaseImpl(
          caseOffsets,
          expressions,
          expressionOffsets,
          block,
          isDefault: defaultKeyword != null,
          hasLabel: labels != null,
        )..fileOffset = beginToken.charOffset,
      );
    }
    push(labels ?? NullValues.Labels);
    createAndEnterLocalScope(kind: LocalScopeKind.caseHead); // Sentinel scope.
    assert(
      checkState(beginToken, [
        ValueKinds.LabelListOrNull,
        ValueKinds.SwitchCase,
      ]),
    );
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");
    assert(
      checkState(switchKeyword, [
        /* labelUsers = */ ValueKinds.StatementListOrNullList,
        /* cases = */ ValueKinds.SwitchCaseList,
        /* containsPatterns */ ValueKinds.Bool,
        /* break target = */ ValueKinds.BreakTarget,
        /* expression = */ ValueKinds.Condition,
      ]),
    );
    List<List<Statement>?> labelUsers = pop() as List<List<Statement>?>;
    List<SwitchCase> cases = pop() as List<SwitchCase>;
    bool containsPatterns = pop() as bool;
    JumpTarget target = exitBreakTarget()!;
    exitSwitchScope();
    exitLocalScope();
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in switch statement: ${condition.patternGuard}.",
    );
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
              // Coverage-ignore-block(suite): Not run.
              List<PatternGuard> patterns = new List<PatternGuard>.generate(
                switchCase.expressions.length,
                (int index) {
                  return forest.createPatternGuard(
                    switchCase.expressions[index].fileOffset,
                    forest.createConstantPattern(switchCase.expressions[index]),
                  );
                },
              );
              patternSwitchCase = forest.createPatternSwitchCase(
                switchCase.fileOffset,
                (switchCase as SwitchCaseImpl).caseOffsets,
                patterns,
                switchCase.body,
                isDefault: switchCase.isDefault,
                hasLabel: switchCase.hasLabel,
                jointVariables: [],
                jointVariableFirstUseOffsets: null,
              );
            }
            List<Statement>? users = labelUsers[index];
            if (users != null) {
              patternSwitchCase.labelUsers.addAll(users);
            }
            return patternSwitchCase;
          });
      switchStatement = forest.createPatternSwitchStatement(
        switchKeyword.charOffset,
        expression,
        patternSwitchCases,
      );
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
    assignedVariables.endNode(switchStatement);
  }

  @override
  void handleSwitchExpressionCasePattern(Token token) {
    debugEvent("SwitchExpressionCasePattern");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    Object? pattern = pop();
    createAndEnterLocalScope(kind: LocalScopeKind.caseHead);
    if (pattern is Pattern) {
      for (VariableDeclaration variable in pattern.declaredVariables) {
        declareVariable(variable, _localScope);
      }
    }
    push(pattern);
  }

  @override
  void endSwitchExpressionCase(
    Token beginToken,
    Token? when,
    Token arrow,
    Token endToken,
  ) {
    debugEvent("endSwitchExpressionCase");
    assert(
      checkState(arrow, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        if (when != null)
          unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );

    Expression expression = popForValue();
    Expression? guard;
    if (when != null) {
      guard = popForValue();
    }
    Object? value = pop();
    exitLocalScope();
    PatternGuard patternGuard = forest.createPatternGuard(
      arrow.charOffset,
      toPattern(value),
      guard,
    );
    push(
      forest.createSwitchExpressionCase(
        arrow.charOffset,
        patternGuard,
        expression,
      ),
    );
    assert(checkState(arrow, [ValueKinds.SwitchExpressionCase]));
  }

  @override
  void endSwitchExpressionBlock(
    int caseCount,
    Token beginToken,
    Token endToken,
  ) {
    debugEvent("endSwitchExpressionBlock");
    assert(
      checkState(
        beginToken,
        repeatedKind(ValueKinds.SwitchExpressionCase, caseCount),
      ),
    );
    List<SwitchExpressionCase> cases = new List<SwitchExpressionCase>.filled(
      caseCount,
      dummySwitchExpressionCase,
    );
    for (int i = caseCount - 1; i >= 0; i--) {
      cases[i] = pop() as SwitchExpressionCase;
    }
    push(cases);
  }

  @override
  void endSwitchExpression(Token switchKeyword, Token endToken) {
    debugEvent("endSwitchExpression");
    assert(
      checkState(switchKeyword, [
        ValueKinds.SwitchExpressionCaseList,
        ValueKinds.Condition,
      ]),
    );

    List<SwitchExpressionCase> cases = pop() as List<SwitchExpressionCase>;
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in switch expression: ${condition.patternGuard}.",
    );
    Expression expression = condition.expression;
    push(
      forest.createSwitchExpression(
        switchKeyword.charOffset,
        expression,
        cases,
      ),
    );
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    debugEvent("SwitchBlock");
    assert(
      checkState(
        beginToken,
        repeatedKinds([
          ValueKinds.LabelListOrNull,
          ValueKinds.SwitchCase,
        ], caseCount),
      ),
    );

    exitLocalScope(
      expectedScopeKinds: const [LocalScopeKind.caseHead],
    ); // Exit the sentinel scope.

    bool containsPatterns = false;
    List<SwitchCase> cases = new List<SwitchCase>.filled(
      caseCount,
      dummySwitchCase,
      growable: true,
    );
    List<List<Statement>?> caseLabelUsers = new List<List<Statement>?>.filled(
      caseCount,
      null,
      growable: true,
    );
    for (int i = caseCount - 1; i >= 0; i--) {
      List<Label>? labels = pop() as List<Label>?;
      SwitchCase current = cases[i] = pop() as SwitchCase;
      if (labels != null) {
        for (Label label in labels) {
          JumpTarget? target = _switchScope!.lookupLabel(label.name);
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
      TreeNode? lastNode = block.statements.isEmpty
          ? null
          : block.statements.last;
      if (lastNode is Block) {
        // This is a non-synthetic block.
        Block block = lastNode;
        lastNode = block.statements.isEmpty ? null : block.statements.last;
      }
      if (lastNode is ExpressionStatement) {
        ExpressionStatement statement = lastNode;
        lastNode = statement.expression;
      }
    }

    push(containsPatterns);
    push(cases);
    push(caseLabelUsers);
    assert(
      checkState(beginToken, [
        ValueKinds.StatementListOrNullList,
        ValueKinds.SwitchCaseList,
        ValueKinds.Bool,
      ]),
    );
  }

  @override
  void handleBreakStatement(
    bool hasTarget,
    Token breakKeyword,
    Token endToken,
  ) {
    debugEvent("BreakStatement");
    JumpTarget? target = breakTarget;
    Identifier? identifier;
    String? name;
    if (hasTarget) {
      identifier = pop() as Identifier;
      name = identifier.name;
      target = _labelScope.lookupLabel(name);
    }
    if (target == null && name == null) {
      push(
        problemInLoopOrSwitch = buildProblemStatement(
          diag.breakOutsideOfLoop,
          breakKeyword.charOffset,
        ),
      );
    } else if (target == null || !target.isBreakTarget) {
      Token labelToken = breakKeyword.next!;
      push(
        problemInLoopOrSwitch = buildProblemStatement(
          diag.invalidBreakTarget.withArguments(label: name!),
          labelToken.charOffset,
          length: labelToken.length,
        ),
      );
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(buildProblemTargetOutsideLocalFunction(name, breakKeyword));
    } else {
      Statement statement = forest.createBreakStatement(
        offsetForToken(breakKeyword),
        identifier,
      );
      target.addBreak(statement);
      push(statement);
    }
  }

  Statement buildProblemTargetOutsideLocalFunction(
    String? name,
    Token keyword,
  ) {
    Statement problem;
    bool isBreak = keyword.isA(Keyword.BREAK);
    if (name != null) {
      Template<Message Function({required String label})> template = isBreak
          ? diag.breakTargetOutsideFunction
          : diag.continueTargetOutsideFunction;
      problem = buildProblemStatement(
        template.withArguments(label: name),
        offsetForToken(keyword),
        length: lengthOfSpan(keyword, keyword.next),
      );
    } else {
      Message message = isBreak
          ? diag.anonymousBreakTargetOutsideFunction
          : diag.anonymousContinueTargetOutsideFunction;
      problem = buildProblemStatement(
        message,
        offsetForToken(keyword),
        length: lengthForToken(keyword),
      );
    }
    problemInLoopOrSwitch ??= problem;
    return problem;
  }

  @override
  void handleContinueStatement(
    bool hasTarget,
    Token continueKeyword,
    Token endToken,
  ) {
    debugEvent("ContinueStatement");
    JumpTarget? target = continueTarget;
    Identifier? identifier;
    String? name;
    if (hasTarget) {
      identifier = pop() as Identifier;
      name = identifier.name;
      target = _labelScope.lookupLabel(identifier.name);
      if (target == null) {
        if (_switchScope == null) {
          push(
            buildProblemStatement(
              diag.labelNotFound.withArguments(label: name),
              continueKeyword.next!.charOffset,
            ),
          );
          return;
        }
        _switchScope!.forwardDeclareLabel(
          identifier.name,
          target = createGotoTarget(identifier.nameOffset),
        );
      }
      if (target.isGotoTarget &&
          target.functionNestingLevel == functionNestingLevel) {
        ContinueSwitchStatement statement = new ContinueSwitchStatement(
          dummySwitchCase,
        )..fileOffset = continueKeyword.charOffset;
        target.addGoto(statement);
        push(statement);
        return;
      }
    }
    if (target == null) {
      push(
        problemInLoopOrSwitch = buildProblemStatement(
          diag.continueWithoutLabelInCase,
          continueKeyword.charOffset,
          length: continueKeyword.length,
        ),
      );
    } else if (!target.isContinueTarget) {
      Token labelToken = continueKeyword.next!;
      push(
        problemInLoopOrSwitch = buildProblemStatement(
          diag.invalidContinueTarget.withArguments(label: name!),
          labelToken.charOffset,
          length: labelToken.length,
        ),
      );
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(buildProblemTargetOutsideLocalFunction(name, continueKeyword));
    } else {
      Statement statement = forest.createContinueStatement(
        offsetForToken(continueKeyword),
        identifier,
      );
      target.addContinue(statement);
      push(statement);
    }
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
        ValueKinds.AnnotationListOrNull,
      ]),
    );
    Object? name = pop();
    List<Expression>? annotations = pop() as List<Expression>?;
    String? typeParameterName;
    int typeParameterNameOffset;
    if (name is Identifier) {
      typeParameterName = name.name;
      typeParameterNameOffset = name.nameOffset;
    } else if (name is ParserRecovery) {
      typeParameterName = inFunctionType
          ? StructuralParameterBuilder.noNameSentinel
          : NominalParameterBuilder.noNameSentinel;
      typeParameterNameOffset = name.charOffset;
    } else {
      unhandled(
        "${name.runtimeType}",
        "beginTypeVariable.name",
        token.charOffset,
        uri,
      );
    }
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && typeParameterName == '_';
    if (isWildcard) {
      typeParameterName = createWildcardTypeParameterName(
        wildcardVariableIndex,
      );
      wildcardVariableIndex++;
    }
    TypeParameterBuilder variable = inFunctionType
        ? new SourceStructuralParameterBuilder(
            new RegularStructuralParameterDeclaration(
              metadata: null,
              name: typeParameterName,
              fileOffset: typeParameterNameOffset,
              fileUri: uri,
              isWildcard: isWildcard,
            ),
          )
        : new SourceNominalParameterBuilder(
            new DirectNominalParameterDeclaration(
              name: typeParameterName,
              kind: TypeParameterKind.function,
              isWildcard: isWildcard,
              fileOffset: typeParameterNameOffset,
              fileUri: uri,
            ),
          );
    if (annotations != null) {
      switch (variable) {
        case StructuralParameterBuilder():
          if (!libraryFeatures.genericMetadata.isEnabled) {
            addProblem(
              diag.annotationOnFunctionTypeTypeParameter,
              variable.fileOffset,
              variable.name.length,
            );
          }
          break;
        case NominalParameterBuilder():
          //inferAnnotations(variable.parameter, annotations);
          for (Expression annotation in annotations) {
            variable.parameter.addAnnotation(annotation);
          }
          _registerSingleTargetAnnotations(variable.parameter);
          break;
      }
    }
    push(variable);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("handleTypeVariablesDefined");
    assert(count > 0);
    if (inFunctionType) {
      List<StructuralParameterBuilder>? structuralVariableBuilders =
          const FixedNullableList<StructuralParameterBuilder>().popNonNullable(
            stack,
            count,
            dummyStructuralVariableBuilder,
          );
      enterStructuralVariablesScope(structuralVariableBuilders);
      push(structuralVariableBuilders);
    } else {
      List<NominalParameterBuilder>? nominalVariableBuilders =
          const FixedNullableList<NominalParameterBuilder>().popNonNullable(
            stack,
            count,
            dummyNominalVariableBuilder,
          );
      enterNominalVariablesScope(nominalVariableBuilders);
      push(nominalVariableBuilders);
    }
  }

  @override
  void endTypeVariable(
    Token token,
    int index,
    Token? extendsOrSuper,
    Token? variance,
  ) {
    debugEvent("TypeVariable");
    TypeBuilder? bound = pop() as TypeBuilder?;
    // Peek to leave type parameters on top of stack.
    List<TypeParameterBuilder> typeParameters =
        peek() as List<TypeParameterBuilder>;

    TypeParameterBuilder typeParameter = typeParameters[index];
    typeParameter.bound = bound;
    if (variance != null) {
      // Coverage-ignore-block(suite): Not run.
      if (!libraryFeatures.variance.isEnabled) {
        reportVarianceModifierNotEnabled(variance);
      }
      typeParameter.variance = new Variance.fromKeywordString(variance.lexeme);
    }
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    // Peek to leave type parameters on top of stack.
    List<TypeParameterBuilder> typeParameters =
        peek() as List<TypeParameterBuilder>;
    checkTypeParameterDependencies(libraryBuilder, typeParameters);

    TypeParameterFactory typeParameterFactory = new TypeParameterFactory();
    List<TypeBuilder> calculatedBounds = calculateBounds(
      typeParameters,
      libraryBuilder.loader.target.dynamicType,
      libraryBuilder.loader.target.nullType,
      typeParameterFactory: typeParameterFactory,
    );
    for (int i = 0; i < typeParameters.length; ++i) {
      typeParameters[i].defaultType = calculatedBounds[i];
      typeParameters[i].finish(
        libraryBuilder,
        libraryBuilder.loader.target.objectClassBuilder,
        libraryBuilder.loader.target.dynamicType,
      );
    }
    for (TypeParameterBuilder builder
        in typeParameterFactory.collectTypeParameters()) {
      // Coverage-ignore-block(suite): Not run.
      builder.finish(
        libraryBuilder,
        libraryBuilder.loader.target.objectClassBuilder,
        libraryBuilder.loader.target.dynamicType,
      );
    }
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    if (inFunctionType) {
      enterStructuralVariablesScope(null);
      push(NullValues.StructuralParameters);
    } else {
      enterNominalVariablesScope(null);
      push(NullValues.NominalParameters);
    }
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    Statement statement = pop() as Statement;
    push(
      new ExpressionStatement(
        buildProblem(
          message: message,
          fileUri: uri,
          fileOffset: statement.fileOffset,
          length: noLength,
        ),
      ),
    );
  }

  @override
  InvalidExpression buildProblem({
    required Message message,
    required Uri fileUri,
    required int fileOffset,
    required int length,
    List<LocatedMessage>? context,
    bool errorHasBeenReported = false,
    Expression? expression,
  }) {
    if (!errorHasBeenReported) {
      addProblem(
        message,
        fileOffset,
        length,
        wasHandled: true,
        context: context,
      );
    }
    String text = libraryBuilder.loader.target.context
        .format(
          message.withLocation(fileUri, fileOffset, length),
          CfeSeverity.error,
        )
        .plain;
    return new InvalidExpression(text, expression)..fileOffset = fileOffset;
  }

  Expression buildAbstractClassInstantiationError(
    Message message,
    String className, [
    int charOffset = -1,
  ]) {
    addProblemErrorIfConst(message, charOffset, className.length);
    return new InvalidExpression(message.problemMessage);
  }

  Statement buildProblemStatement(
    Message message,
    int charOffset, {
    List<LocatedMessage>? context,
    int? length,
    bool errorHasBeenReported = false,
  }) {
    length ??= noLength;
    return new ExpressionStatement(
      buildProblem(
        message: message,
        fileUri: uri,
        fileOffset: charOffset,
        length: length,
        context: context,
        errorHasBeenReported: errorHasBeenReported,
      ),
    );
  }

  Statement wrapInProblemStatement(Statement statement, Message message) {
    // TODO(askesc): Produce explicit error statement wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    return buildProblemStatement(message, statement.fileOffset);
  }

  Initializer buildDuplicatedInitializer(
    SourcePropertyBuilder fieldBuilder,
    Expression value,
    String name,
    int offset,
    int previousInitializerOffset,
  ) {
    return createInvalidInitializer(
      buildProblem(
        message: diag.constructorInitializeSameInstanceVariableSeveralTimes
            .withArguments(fieldName: name),
        fileUri: uri,
        fileOffset: offset,
        length: noLength,
      ),
    );
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
  List<Initializer> createFieldInitializer(
    String name,
    int fieldNameOffset,
    int assignmentOffset,
    Expression expression, {
    FormalParameterBuilder? formal,
  }) {
    if (isWildcardLoweredFormalParameter(name)) {
      name = '_';
    }
    LookupResult? result = _context.lookupLocalMember(name);
    NamedBuilder? builder = result?.getable;
    if (result != null && result is DuplicateMemberLookupResult) {
      // Duplicated name, already reported.
      MemberBuilder firstBuilder = result.declarations.first;
      if (firstBuilder is SourcePropertyBuilder && firstBuilder.hasField) {
        // Assume the first field has been initialized.
        _context.registerInitializedField(firstBuilder);
      }
      return <Initializer>[
        createInvalidInitializer(
          LookupResult.createDuplicateExpression(
            result,
            context: libraryBuilder.loader.target.context,
            name: name,
            fileUri: uri,
            fileOffset: fieldNameOffset,
            length: name.length,
          ),
        ),
      ];
    } else if (builder is SourcePropertyBuilder &&
        builder.hasField &&
        builder.isDeclarationInstanceMember) {
      if (builder.isExtensionTypeDeclaredInstanceField) {
        // Operating on an invalid field. Don't report anything though
        // as we've already reported that the field isn't valid.
        return <Initializer>[
          createInvalidInitializer(
            new InvalidExpression(
              compilerContext
                  .format(
                    diag.extensionTypeDeclaresInstanceField.withLocation(
                      builder.fileUri,
                      builder.fileOffset,
                      builder.name.length,
                    ),
                    cfe.CfeSeverity.error,
                  )
                  .plain,
            ),
          ),
        ];
      }

      initializedFields ??= <String, int>{};
      if (initializedFields!.containsKey(name)) {
        return <Initializer>[
          buildDuplicatedInitializer(
            builder,
            expression,
            name,
            assignmentOffset,
            initializedFields![name]!,
          ),
        ];
      }
      initializedFields![name] = assignmentOffset;
      if (builder.hasAbstractField) {
        return <Initializer>[
          createInvalidInitializer(
            buildProblem(
              message: diag.abstractFieldConstructorInitializer,
              fileUri: uri,
              fileOffset: fieldNameOffset,
              length: name.length,
            ),
          ),
        ];
      } else if (builder.hasExternalField) {
        return <Initializer>[
          createInvalidInitializer(
            buildProblem(
              message: diag.externalFieldConstructorInitializer,
              fileUri: uri,
              fileOffset: fieldNameOffset,
              length: name.length,
            ),
          ),
        ];
      } else if (builder.isFinal && builder.hasInitializer) {
        return <Initializer>[
          createInvalidInitializer(
            buildProblem(
              message: diag.fieldAlreadyInitializedAtDeclaration.withArguments(
                fieldName: name,
              ),
              fileUri: uri,
              fileOffset: assignmentOffset,
              length: noLength,
              context: [
                diag.fieldAlreadyInitializedAtDeclarationCause
                    .withArguments(fieldName: name)
                    .withLocation(uri, builder.fileOffset, name.length),
              ],
            ),
          ),
        ];
      } else {
        _context.registerInitializedField(builder);
        if (formal != null && formal.type is! OmittedTypeBuilder) {
          DartType formalType = formal.variable!.type;
          DartType fieldType = _context.substituteFieldType(builder.fieldType);
          if (!typeEnvironment.isSubtypeOf(formalType, fieldType)) {
            return [
              createInvalidInitializer(
                buildProblem(
                  message: diag.initializingFormalTypeMismatch.withArguments(
                    parameterName: name,
                    parameterType: formalType,
                    fieldType: builder.fieldType,
                  ),
                  fileOffset: assignmentOffset,
                  length: noLength,
                  fileUri: uri,
                  context: [
                    diag.initializingFormalTypeMismatchField.withLocation(
                      builder.fileUri,
                      builder.fileOffset,
                      noLength,
                    ),
                  ],
                ),
              ),
            ];
          }
        }
        return builder.buildInitializer(
          assignmentOffset,
          expression,
          isSynthetic: formal != null,
        );
      }
    } else {
      return <Initializer>[
        createInvalidInitializer(
          buildProblem(
            message: diag.initializerForStaticField.withArguments(
              fieldName: name,
            ),
            fileUri: uri,
            fileOffset: fieldNameOffset,
            length: name.length,
          ),
        ),
      ];
    }
  }

  @override
  Initializer buildSuperInitializer(
    bool isSynthetic,
    Constructor constructor,
    ActualArguments arguments, [
    int charOffset = -1,
  ]) {
    if (_context.isConstConstructor && !constructor.isConst) {
      addProblem(
        diag.constConstructorWithNonConstSuper,
        charOffset,
        constructor.name.text.length,
      );
    }
    return new InternalSuperInitializer(
      constructor,
      arguments,
      isSynthetic: isSynthetic,
    )..fileOffset = charOffset;
  }

  @override
  Initializer buildRedirectingInitializer(
    Name name,
    ActualArguments arguments, {
    required int fileOffset,
  }) {
    Builder? constructorBuilder = _context.lookupConstructor(name);
    if (constructorBuilder == null) {
      int length = name.text.length;
      if (length == 0) {
        // The constructor is unnamed so the offset points to 'this'.
        length = "this".length;
      }
      String fullName = constructorNameForDiagnostics(name.text);
      return createInvalidInitializer(
        buildProblem(
          message: diag.constructorNotFound.withArguments(name: fullName),
          fileUri: uri,
          fileOffset: fileOffset,
          length: length,
        ),
      );
    } else {
      if (_context.isConstructorCyclic(name.text)) {
        int length = name.text.length;
        if (length == 0) length = "this".length;
        addProblem(diag.constructorCyclic, fileOffset, length);
        // TODO(askesc): Produce invalid initializer.
      }
      if (_context.formals != null) {
        for (FormalParameterBuilder formal in _context.formals!) {
          if (formal.isSuperInitializingFormal) {
            addProblem(
              diag.unexpectedSuperParametersInGenerativeConstructors,
              formal.fileOffset,
              noLength,
            );
            _context.markAsErroneous();
          }
        }
      }
      return _context.buildRedirectingInitializer(
        constructorBuilder,
        arguments,
        fileOffset: fileOffset,
      );
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
    push(new SimpleIdentifier(token));
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    if (_context.isNativeMethod) {
      // Coverage-ignore-block(suite): Not run.
      push(NullValues.FunctionBody);
    } else {
      push(
        forest.createBlock(offsetForToken(token), noLocation, <Statement>[
          buildProblemStatement(
            diag.expectedFunctionBody.withArguments(lexeme: token),
            token.charOffset,
            length: token.length,
          ),
        ]),
      );
    }
  }

  @override
  void handleTypeArgumentApplication(Token openAngleBracket) {
    assert(
      checkState(openAngleBracket, [
        ValueKinds.TypeArguments,
        unionOfKinds([ValueKinds.Generator, ValueKinds.Expression]),
      ]),
    );
    List<TypeBuilder>? typeArguments =
        pop() as List<TypeBuilder>?; // typeArguments
    if (libraryFeatures.constructorTearoffs.isEnabled) {
      Object? operand = pop();
      if (operand is DotShorthandPropertyGet && typeArguments != null) {
        operand.hasTypeParameters = true;
      }
      if (operand is Generator) {
        push(
          operand.applyTypeArguments(
            openAngleBracket.charOffset,
            typeArguments,
          ),
        );
      } else if (operand is StaticTearOff &&
              (operand.target.isFactory || isTearOffLowering(operand.target)) ||
          operand is ConstructorTearOff ||
          operand is RedirectingFactoryTearOff) {
        push(
          buildProblem(
            message: diag.constructorTearOffWithTypeArguments,
            fileUri: uri,
            fileOffset: openAngleBracket.charOffset,
            length: noLength,
          ),
        );
      } else {
        push(
          new Instantiation(
            toValue(operand),
            buildDartTypeArguments(
              typeArguments,
              TypeUse.tearOffTypeArgument,
              allowPotentiallyConstantType: true,
            ),
          )..fileOffset = openAngleBracket.charOffset,
        );
      }
    } else {
      libraryBuilder.reportFeatureNotEnabled(
        libraryFeatures.constructorTearoffs,
        uri,
        openAngleBracket.charOffset,
        noLength,
      );
    }
  }

  @override
  TypeBuilder validateTypeParameterUse(
    TypeBuilder typeBuilder, {
    required bool allowPotentiallyConstantType,
  }) {
    _validateTypeParameterUseInternal(
      typeBuilder,
      allowPotentiallyConstantType: allowPotentiallyConstantType,
    );
    return typeBuilder;
  }

  void _validateTypeParameterUseInternal(
    TypeBuilder? builder, {
    required bool allowPotentiallyConstantType,
  }) {
    switch (builder) {
      case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        typeArguments: List<TypeBuilder>? arguments,
      ):
        if (declaration!.isTypeParameter &&
            builder.declaration is NominalParameterBuilder) {
          NominalParameterBuilder typeParameterBuilder =
              declaration as NominalParameterBuilder;
          TypeParameter typeParameter = typeParameterBuilder.parameter;
          GenericDeclaration? typeParameterDeclaration =
              typeParameter.declaration;
          if (typeParameterDeclaration is Class ||
              typeParameterDeclaration is Extension ||
              typeParameterDeclaration is ExtensionTypeDeclaration) {
            if (constantContext != ConstantContext.none &&
                (!inConstructorInitializer || !allowPotentiallyConstantType)) {
              LocatedMessage message = diag.typeVariableInConstantContext
                  .withLocation(
                    builder.fileUri!,
                    builder.charOffset!,
                    typeParameter.name!.length,
                  );
              builder.bind(
                libraryBuilder,
                new InvalidBuilder(typeParameter.name!, message),
              );
              addProblem(
                message.messageObject,
                message.charOffset,
                message.length,
              );
            }
          }
        }
        if (arguments != null) {
          for (TypeBuilder typeBuilder in arguments) {
            _validateTypeParameterUseInternal(
              typeBuilder,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            );
          }
        }
      case FunctionTypeBuilder(
        typeParameters: List<StructuralParameterBuilder>? typeParameters,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType,
      ):
        if (typeParameters != null) {
          for (StructuralParameterBuilder typeParameter in typeParameters) {
            _validateTypeParameterUseInternal(
              typeParameter.bound,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            );
            _validateTypeParameterUseInternal(
              typeParameter.defaultType,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            );
          }
        }
        _validateTypeParameterUseInternal(
          returnType,
          allowPotentiallyConstantType: allowPotentiallyConstantType,
        );
        if (formals != null) {
          for (ParameterBuilder formalParameterBuilder in formals) {
            _validateTypeParameterUseInternal(
              formalParameterBuilder.type,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            );
          }
        }
      case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields,
      ):
        if (positionalFields != null) {
          for (RecordTypeFieldBuilder field in positionalFields) {
            _validateTypeParameterUseInternal(
              field.type,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            );
          }
        }
        if (namedFields != null) {
          for (RecordTypeFieldBuilder field in namedFields) {
            _validateTypeParameterUseInternal(
              field.type,
              allowPotentiallyConstantType: allowPotentiallyConstantType,
            );
          }
        }
      case OmittedTypeBuilder():
      case FixedTypeBuilder():
      case InvalidTypeBuilder():
      case null:
    }
  }

  @override
  Expression evaluateArgumentsBefore(
    ActualArguments? arguments,
    Expression expression,
  ) {
    if (arguments == null) return expression;
    for (Argument argument in arguments.argumentList.reversed) {
      expression = new Let(
        new VariableDeclaration.forValue(
          argument.expression,
          isFinal: true,
          type: coreTypes.objectRawType(Nullability.nullable),
        ),
        expression,
      );
    }
    return expression;
  }

  @override
  bool isIdentical(Member? member) => member == coreTypes.identicalProcedure;

  @override
  Expression buildMethodInvocation(
    Expression receiver,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int offset, {
    bool isConstantExpression = false,
    bool isNullAware = false,
  }) {
    if (constantContext != ConstantContext.none &&
        !isConstantExpression &&
        !libraryFeatures.constFunctions.isEnabled) {
      return buildProblem(
        message: diag.notConstantExpression.withArguments(
          description: 'Method invocation',
        ),
        fileUri: uri,
        fileOffset: offset,
        length: name.text.length,
      );
    }
    return forest.createMethodInvocation(
      offset,
      receiver,
      name,
      typeArguments,
      arguments,
      isNullAware: isNullAware,
    );
  }

  @override
  Expression buildSuperInvocation(
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int offset, {
    bool isConstantExpression = false,
    bool isNullAware = false,
    bool isImplicitCall = false,
  }) {
    if (constantContext != ConstantContext.none &&
        !isConstantExpression &&
        !libraryFeatures.constFunctions.isEnabled) {
      return buildProblem(
        message: diag.notConstantExpression.withArguments(
          description: 'Method invocation',
        ),
        fileUri: uri,
        fileOffset: offset,
        length: name.text.length,
      );
    }
    Member? target = lookupSuperMember(name);

    if (target == null) {
      return buildUnresolvedError(
        name.text,
        offset,
        isSuper: true,
        kind: UnresolvedKind.Method,
      );
    } else if (target is Procedure && !target.isAccessor) {
      return new InternalSuperMethodInvocation(
        name,
        typeArguments,
        arguments,
        target,
      )..fileOffset = offset;
    }
    if (isImplicitCall) {
      return buildProblem(
        message: diag.implicitSuperCallOfNonMethod,
        fileUri: uri,
        fileOffset: offset,
        length: noLength,
      );
    } else {
      Expression receiver = new SuperPropertyGet(
        new ThisExpression(),
        name,
        target,
      )..fileOffset = offset;
      return forest.createExpressionInvocation(
        arguments.fileOffset,
        receiver,
        typeArguments,
        arguments,
      );
    }
  }

  @override
  void addProblem(
    Message message,
    int charOffset,
    int length, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
    CfeSeverity? severity,
  }) {
    libraryBuilder.addProblem(
      message,
      charOffset,
      length,
      uri,
      wasHandled: wasHandled,
      context: context,
      severity: severity,
    );
  }

  @override
  void addProblemErrorIfConst(
    Message message,
    int charOffset,
    int length, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
  }) {
    // TODO(askesc): Instead of deciding on the severity, this method should
    // take two messages: one to use when a constant expression is
    // required and one to use otherwise.
    CfeSeverity severity = message.code.severity;
    if (constantContext != ConstantContext.none) {
      severity = CfeSeverity.error;
    }
    addProblem(
      message,
      charOffset,
      length,
      wasHandled: wasHandled,
      context: context,
      severity: severity,
    );
  }

  @override
  Expression buildProblemErrorIfConst(
    Message message,
    int charOffset,
    int length, {
    bool wasHandled = false,
    List<LocatedMessage>? context,
  }) {
    addProblemErrorIfConst(
      message,
      charOffset,
      length,
      wasHandled: wasHandled,
      context: context,
    );
    String text = libraryBuilder.loader.target.context
        .format(
          message.withLocation(uri, charOffset, length),
          CfeSeverity.error,
        )
        .plain;
    InvalidExpression expression = new InvalidExpression(text)
      ..fileOffset = charOffset;
    return expression;
  }

  @override
  void reportDuplicatedDeclaration(
    Builder existing,
    String name,
    int charOffset,
  ) {
    List<LocatedMessage>? context = existing.isSynthetic
        ? null
        : <LocatedMessage>[
            diag.duplicatedDeclarationCause
                .withArguments(name: name)
                .withLocation(
                  existing.fileUri!,
                  existing.fileOffset,
                  name.length,
                ),
          ];
    addProblem(
      diag.duplicatedDeclaration.withArguments(name: name),
      charOffset,
      name.length,
      context: context,
    );
  }

  @override
  void debugEvent(String name) {
    // printEvent('BodyBuilder: $name');
  }

  @override
  Expression wrapInDeferredCheck(
    Expression expression,
    PrefixBuilder prefix,
    int charOffset,
  ) {
    VariableDeclaration check = new VariableDeclaration.forValue(
      forest.checkLibraryIsLoaded(charOffset, prefix.dependency!),
    );
    return new DeferredCheck(check, expression)..fileOffset = charOffset;
  }

  bool isErroneousNode(TreeNode node) {
    return libraryBuilder.loader.handledErrors.isNotEmpty &&
        forest.isErroneousNode(node);
  }

  @override
  DartType buildDartType(
    TypeBuilder typeBuilder,
    TypeUse typeUse, {
    required bool allowPotentiallyConstantType,
  }) {
    return validateTypeParameterUse(
      typeBuilder,
      allowPotentiallyConstantType: allowPotentiallyConstantType,
    ).build(libraryBuilder, typeUse);
  }

  @override
  List<DartType> buildDartTypeArguments(
    List<TypeBuilder>? unresolvedTypes,
    TypeUse typeUse, {
    required bool allowPotentiallyConstantType,
  }) {
    if (unresolvedTypes == null) {
      // Coverage-ignore-block(suite): Not run.
      return <DartType>[];
    }
    return new List<DartType>.generate(
      unresolvedTypes.length,
      (int i) => buildDartType(
        unresolvedTypes[i],
        typeUse,
        allowPotentiallyConstantType: allowPotentiallyConstantType,
      ),
      growable: true,
    );
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
      libraryFeatures.constructorTearoffs,
      token.charOffset,
      token.length,
    );
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
    assert(
      checkState(constKeyword, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        ValueKinds.ConstantContext,
      ]),
    );
    Expression expression = toValue(pop());
    constantContext = pop() as ConstantContext;
    push(expression);
  }

  @override
  void handleObjectPatternFields(int count, Token beginToken, Token endToken) {
    debugEvent("ObjectPattern");
    assert(
      checkState(
        beginToken,
        repeatedKind(
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Generator,
            ValueKinds.Pattern,
          ]),
          count,
        ),
      ),
    );
    reportIfNotEnabled(
      libraryFeatures.patterns,
      beginToken.charOffset,
      beginToken.charCount,
    );
    List<NamedPattern>? fields;
    for (int i = 0; i < count; i++) {
      Object? field = pop();
      if (field is NamedPattern) {
        (fields ??= <NamedPattern>[]).add(field);
      } else {
        Pattern pattern = toPattern(field);
        if (pattern is! InvalidPattern) {
          addProblem(
            diag.unnamedObjectPatternField,
            pattern.fileOffset,
            noLength,
          );
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
    Token firstIdentifier,
    Token? dot,
    Token? secondIdentifier,
  ) {
    debugEvent("ObjectPattern");
    assert(
      checkState(firstIdentifier, [
        ValueKinds.PatternListOrNull,
        ValueKinds.TypeArgumentsOrNull,
      ]),
    );

    reportIfNotEnabled(
      libraryFeatures.patterns,
      firstIdentifier.charOffset,
      firstIdentifier.charCount,
    );

    List<NamedPattern>? fields = pop() as List<NamedPattern>?;
    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;

    handleIdentifier(firstIdentifier, IdentifierContext.prefixedTypeReference);
    if (secondIdentifier != null) {
      handleIdentifier(
        secondIdentifier,
        IdentifierContext.typeReferenceContinuation,
      );
      handleQualified(dot!);
    }
    push(typeArguments ?? NullValues.TypeArguments);
    handleType(firstIdentifier, null);
    TypeBuilder typeBuilder = pop() as TypeBuilder;
    TypeDeclarationBuilder? typeDeclaration = typeBuilder.declaration;
    DartType type = buildDartType(
      typeBuilder,
      TypeUse.objectPatternType,
      allowPotentiallyConstantType: true,
    );
    push(
      new ObjectPatternInternal(
        type,
        fields ?? <NamedPattern>[],
        typeDeclaration is TypeAliasBuilder ? typeDeclaration.typedef : null,
        hasExplicitTypeArguments: typeArguments != null,
      )..fileOffset = firstIdentifier.charOffset,
    );
  }

  @override
  void handleRestPattern(Token dots, {required bool hasSubPattern}) {
    debugEvent("RestPattern");
    assert(
      checkState(dots, [
        if (hasSubPattern)
          unionOfKinds([
            ValueKinds.Expression,
            ValueKinds.Generator,
            ValueKinds.Pattern,
          ]),
      ]),
    );

    Pattern? subPattern;
    if (hasSubPattern) {
      subPattern = toPattern(pop());
    }
    push(forest.createRestPattern(dots.charOffset, subPattern));
  }

  @override
  void handleRelationalPattern(Token token) {
    debugEvent("RelationalPattern");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    reportIfNotEnabled(
      libraryFeatures.patterns,
      token.charOffset,
      token.charCount,
    );
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
      // Coverage-ignore(suite): Not run.
      default:
        internalProblem(
          diag.internalProblemUnhandled.withArguments(
            what: operator,
            where: 'handleRelationalPattern',
          ),
          token.charOffset,
          uri,
        );
    }
    push(forest.createRelationalPattern(token.charOffset, kind, operand));
  }

  @override
  void handleNullAssertPattern(Token bang) {
    debugEvent("NullAssertPattern");
    assert(
      checkState(bang, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    reportIfNotEnabled(
      libraryFeatures.patterns,
      bang.charOffset,
      bang.charCount,
    );
    Pattern operand = toPattern(pop());
    push(forest.createNullAssertPattern(bang.charOffset, operand));
  }

  @override
  void handleNullCheckPattern(Token question) {
    debugEvent('NullCheckPattern');
    assert(
      checkState(question, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
      ]),
    );
    reportIfNotEnabled(
      libraryFeatures.patterns,
      question.charOffset,
      question.charCount,
    );
    Pattern operand = toPattern(pop());
    push(forest.createNullCheckPattern(question.charOffset, operand));
  }

  @override
  void handleAssignedVariablePattern(Token variable) {
    debugEvent('AssignedVariablePattern');

    reportIfNotEnabled(
      libraryFeatures.patterns,
      variable.charOffset,
      variable.charCount,
    );
    assert(variable.lexeme != '_');
    Pattern pattern;
    Expression variableUse = scopeLookup(
      _localScope,
      variable,
    ).buildSimpleRead();
    if (variableUse is VariableGet) {
      ExpressionVariable variableDeclaration = variableUse.variable;
      pattern = forest.createAssignedVariablePattern(
        variable.charOffset,
        variableDeclaration,
      );
      registerVariableAssignment(variableDeclaration);
    } else {
      addProblem(
        diag.patternAssignmentNotLocalVariable,
        variable.charOffset,
        variable.charCount,
      );
      // Recover by using [WildcardPattern] instead.
      pattern = forest.createWildcardPattern(variable.charOffset, null);
    }
    push(pattern);
  }

  @override
  void handleDeclaredVariablePattern(
    Token? keyword,
    Token variable, {
    required bool inAssignmentPattern,
  }) {
    debugEvent('DeclaredVariablePattern');
    assert(checkState(keyword ?? variable, [ValueKinds.TypeBuilderOrNull]));

    reportIfNotEnabled(
      libraryFeatures.patterns,
      variable.charOffset,
      variable.charCount,
    );
    assert(variable.lexeme != '_');
    TypeBuilder? type = pop(NullValues.TypeBuilder) as TypeBuilder?;
    DartType? patternType = type?.build(libraryBuilder, TypeUse.variableType);
    Pattern pattern;
    if (inAssignmentPattern) {
      // Error has already been reported.
      pattern = forest.createInvalidPattern(
        new InvalidExpression('declared variable pattern in assignment'),
        declaredVariables: const [],
      );
    } else {
      VariableDeclaration declaredVariable = forest.createVariableDeclaration(
        variable.charOffset,
        variable.lexeme,
        type: patternType,
        isFinal: Modifiers.from(varFinalOrConst: keyword).isFinal,
      );
      pattern = forest.createVariablePattern(
        variable.charOffset,
        patternType,
        declaredVariable,
      );
      declareVariable(declaredVariable, _localScope);
      assignedVariables.declare(declaredVariable);
    }
    push(pattern);
  }

  @override
  void handleWildcardPattern(Token? keyword, Token wildcard) {
    debugEvent('WildcardPattern');
    assert(checkState(keyword ?? wildcard, [ValueKinds.TypeBuilderOrNull]));

    reportIfNotEnabled(
      libraryFeatures.patterns,
      wildcard.charOffset,
      wildcard.charCount,
    );
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
    assert(
      checkState(colon, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
        if (colon != null)
          unionOfKinds([
            ValueKinds.IdentifierOrNull,
            ValueKinds.ParserRecovery,
          ]),
      ]),
    );

    Object? value = pop();
    Pattern pattern = toPattern(value);
    if (colon != null) {
      Object? identifier = pop();
      if (identifier is ParserRecovery) {
        push(new ParserErrorGenerator(this, colon, diag.syntheticToken));
      } else {
        String? name;
        if (identifier is Identifier) {
          name = identifier.name;
        } else {
          name = pattern.variableName;
        }
        if (name == null) {
          push(
            forest.createInvalidPattern(
              buildProblem(
                message: diag.unspecifiedGetterNameInObjectPattern,
                fileUri: uri,
                fileOffset: colon.charOffset,
                length: noLength,
              ),
              declaredVariables: const [],
            ),
          );
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
    Token keyword,
    Token equals,
    Token semicolon,
  ) {
    debugEvent('PatternVariableDeclarationStatement');
    assert(
      checkState(keyword, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Pattern,
        ]),
        ValueKinds.AnnotationListOrNull,
      ]),
    );
    Expression initializer = popForValue();
    Pattern pattern = toPattern(pop());
    bool isFinal = keyword.lexeme == 'final';
    for (VariableDeclaration variable in pattern.declaredVariables) {
      variable.isFinal = isFinal;
      variable.hasDeclaredInitializer = true;
      declareVariable(variable, _localScope);
    }
    // TODO(johnniwinther,cstefantsova): Handle metadata.
    pop(NullValues.Metadata) as List<Expression>?;
    push(
      forest.createPatternVariableDeclaration(
        keyword.charOffset,
        pattern,
        initializer,
        isFinal: isFinal,
      ),
    );
  }

  @override
  void handlePatternAssignment(Token equals) {
    debugEvent("PatternAssignment");
    assert(
      checkState(equals, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([
          ValueKinds.Pattern,
          ValueKinds.Expression,
          ValueKinds.Generator,
        ]),
      ]),
    );
    Expression expression = popForValue();
    Pattern pattern = toPattern(pop());
    push(
      forest.createPatternAssignment(equals.charOffset, pattern, expression),
    );
  }

  @override
  void handleDotShorthandContext(Token token) {
    debugEvent("DotShorthandContext");
    if (!libraryFeatures.dotShorthands.isEnabled) {
      addProblem(
        diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: ExperimentalFlag.dotShorthands.name,
        ),
        token.offset,
        token.length,
      );
    }

    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression value = popForValue();
    push(forest.createDotShorthandContext(token.charOffset, value));
  }

  @override
  void handleDotShorthandHead(Token token) {
    debugEvent("DotShorthandHead");
    if (!libraryFeatures.dotShorthands.isEnabled) {
      addProblem(
        diag.experimentNotEnabledOffByDefault.withArguments(
          featureName: ExperimentalFlag.dotShorthands.name,
        ),
        token.offset,
        token.length,
      );
    }

    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Selector, ValueKinds.ParserRecovery]),
      ]),
    );
    Object? node = pop();
    if (node is InvocationSelector) {
      // e.g. `.parse(2)`
      push(
        forest.createDotShorthandInvocation(
          offsetForToken(token),
          node.name,
          node.typeArguments,
          node.arguments,
          nameOffset: offsetForToken(token.next),
          isConst: constantContext == ConstantContext.inferred,
        ),
      );
    } else if (node is PropertySelector) {
      // e.g. `.zero`
      push(
        forest.createDotShorthandPropertyGet(
          offsetForToken(token),
          node.name,
          nameOffset: offsetForToken(token.next),
        ),
      );
    } else if (node is ParserRecovery) {
      // Recovery for cases like `var x = .;` where we're missing an identifier.
      token = token.next!;
      push(
        buildProblem(
          message: diag.expectedIdentifier.withArguments(lexeme: token),
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
        ),
      );
    }
  }

  @override
  void beginConstDotShorthand(Token token) {
    debugEvent("beginConstDotShorthand");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void endConstDotShorthand(Token token) {
    debugEvent("endConstDotShorthand");
    Object? dotShorthand = pop();
    constantContext = pop() as ConstantContext;
    push(dotShorthand);
  }

  @override
  BuildInitializersResult buildInitializers({
    required Token beginInitializers,
  }) {
    parseInitializers(beginInitializers);
    return new BuildInitializersResult(
      _initializers,
      _takePendingAnnotations(),
    );
  }

  @override
  List<Initializer> buildInitializersUnfinished({
    required Token beginInitializers,
  }) {
    return parseInitializers(beginInitializers);
  }

  @override
  BuildParameterInitializerResult buildParameterInitializer({
    required Token initializerToken,
  }) {
    Expression initializer = parseFieldInitializer(initializerToken);
    return new BuildParameterInitializerResult(
      initializer,
      _takePendingAnnotations(),
    );
  }

  @override
  BuildRedirectingFactoryMethodResult buildRedirectingFactoryMethod({
    required Token token,
    required Token? metadata,
  }) {
    try {
      Parser parser = new Parser(
        this,
        useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
        experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
      );
      if (metadata != null) {
        parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
        pop(); // Pops metadata constants.
      }

      token = parser.parseFormalParametersOpt(
        parser.syntheticPreviousToken(token),
        MemberKind.Factory,
      );
      pop(); // Pops formal parameters.
      //finishRedirectingFactoryBody();
      checkEmpty(token.next!.charOffset);
      return new BuildRedirectingFactoryMethodResult(_takePendingAnnotations());
    }
    // Coverage-ignore(suite): Not run.
    on DebugAbort {
      rethrow;
    } catch (e, s) {
      throw new Crash(uri, token.charOffset, e, s);
    }
  }

  @override
  BuildPrimaryConstructorResult buildPrimaryConstructor({
    required Token startToken,
  }) {
    Token token = startToken;
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    token = parser.parseFormalParametersOpt(
      parser.syntheticPreviousToken(token),
      MemberKind.PrimaryConstructor,
    );
    // We discard the formals here since access to these are provided through
    // [_context].
    pop(); // Formals

    checkEmpty(token.next!.charOffset);
    handleNoInitializers();
    checkEmpty(token.charOffset);
    return new BuildPrimaryConstructorResult(
      _initializers,
      _takePendingAnnotations(),
    );
  }

  @override
  BuildFunctionBodyResult buildFunctionBody({
    required Token startToken,
    required Token? metadata,
    required MemberKind kind,
  }) {
    Token token = startToken;
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    if (metadata != null) {
      parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
      pop(); // Annotations.
    }
    token = parser.parseFormalParametersOpt(
      parser.syntheticPreviousToken(token),
      kind,
    );
    // We discard the formals here since access to these are provided through
    // [_context].
    pop(); // Formals

    checkEmpty(token.next!.charOffset);
    token = parser.parseInitializersOpt(token);
    token = parser.parseAsyncModifierOpt(token);
    AsyncMarker asyncMarker = pop() as AsyncMarker? ?? AsyncMarker.Sync;
    if (kind == MemberKind.Factory && asyncMarker != AsyncMarker.Sync) {
      // Factories has to be sync. The parser issued an error.
      // Recover to sync.
      asyncMarker = AsyncMarker.Sync;
    }
    bool isExpression = false;
    bool allowAbstract = asyncMarker == AsyncMarker.Sync;

    benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(
      BenchmarkSubdivides.diet_listener_buildFunctionBody_parseFunctionBody,
    );
    parser.parseFunctionBody(token, isExpression, allowAbstract);
    Statement? body = pop() as Statement?;
    benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    checkEmpty(token.charOffset);
    return new BuildFunctionBodyResult(
      asyncMarker: asyncMarker,
      body: body,
      initializers: _initializers,
      annotations: _takePendingAnnotations(),
    );
  }

  @override
  BuildPrimaryConstructorBodyResult buildPrimaryConstructorBody({
    required Token startToken,
    required Token? metadata,
  }) {
    assert(startToken.isA(Keyword.THIS));
    Token token = startToken;
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    if (metadata != null) {
      parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
      pop(); // Annotations.
    }
    checkEmpty(token.next!.charOffset);
    List<FormalParameterBuilder>? formals = _context.formals;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        // We pass `ignoreDuplicates: true` because the variable might have been
        // previously passed to `declare` in the `BodyBuilder` constructor.
        assignedVariables.declare(formal.variable!, ignoreDuplicates: true);
      }
    }
    token = parser.parseInitializersOpt(token);
    token = parser.parseAsyncModifierOpt(token);
    AsyncMarker asyncMarker = pop() as AsyncMarker? ?? AsyncMarker.Sync;
    bool isExpression = false;
    bool allowAbstract = asyncMarker == AsyncMarker.Sync;

    benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(
      BenchmarkSubdivides.diet_listener_buildFunctionBody_parseFunctionBody,
    );
    parser.parseFunctionBody(token, isExpression, allowAbstract);
    Statement? body = pop() as Statement?;
    benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    checkEmpty(token.charOffset);
    return new BuildPrimaryConstructorBodyResult(
      asyncMarker: asyncMarker,
      body: body,
      initializers: _initializers,
      annotations: _takePendingAnnotations(),
    );
  }

  @override
  Expression buildAnnotation({required Token atToken}) {
    return parseAnnotation(atToken);
  }

  @override
  BuildMetadataListResult buildMetadataList({required Token metadata}) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
    assert(checkState(null, [ValueKinds.AnnotationList]));
    List<Expression> expressions = pop() as List<Expression>;
    return new BuildMetadataListResult(expressions, _takePendingAnnotations());
  }

  @override
  BuildFieldsResult buildFields({
    required Token startToken,
    required Token? metadata,
    required bool isTopLevel,
  }) {
    Token token = startToken;
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    if (isTopLevel) {
      token = parser.parseTopLevelMember(metadata ?? token);
    } else {
      // TODO(danrubel): disambiguate between class/mixin/extension members
      token = parser.parseClassMember(metadata ?? token, null).next!;
    }

    assert(checkState(null, [/*field count*/ ValueKinds.Integer]));
    int count = pop() as int;
    Map<Identifier, Expression?> result = {};
    for (int i = 0; i < count; i++) {
      assert(
        checkState(null, [
          ValueKinds.FieldInitializerOrNull,
          ValueKinds.Identifier,
        ]),
      );
      Expression? initializer = pop() as Expression?;
      Identifier identifier = pop() as Identifier;
      result[identifier] = initializer;
    }
    assert(
      checkState(null, [
        ValueKinds.TypeOrNull,
        ValueKinds.AnnotationListOrNull,
      ]),
    );
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
        buildDartType(
          type,
          TypeUse.fieldType,
          allowPotentiallyConstantType: false,
        );
      }
    }
    pop(); // Annotations.

    checkEmpty(token.charOffset);

    return new BuildFieldsResult(result, _takePendingAnnotations());
  }

  @override
  BuildFieldInitializerResult buildFieldInitializer({
    required Token startToken,
    required bool isLate,
  }) {
    inFieldInitializer = true;
    inLateFieldInitializer = isLate;
    Expression initializer = parseFieldInitializer(startToken);
    return new BuildFieldInitializerResult(
      initializer,
      _takePendingAnnotations(),
    );
  }

  @override
  BuildEnumConstantResult buildEnumConstant({required Token token}) {
    ActualArguments arguments = parseArguments(token);
    return new BuildEnumConstantResult(arguments, _takePendingAnnotations());
  }

  @override
  // Coverage-ignore(suite): Not run.
  BuildSingleExpressionResult buildSingleExpression({
    required Token token,
    required List<ExpressionVariable> extraKnownVariables,
    required List<NominalParameterBuilder>? typeParameterBuilders,
    required List<FormalParameterBuilder>? formals,
    required int fileOffset,
  }) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );

    if (formals != null) {
      for (FormalParameterBuilder formalParameterBuilder in formals) {
        assignedVariables.declare(formalParameterBuilder.variable!);
      }
    }

    enterNominalVariablesScope(typeParameterBuilders);

    enterLocalScope(
      new FormalParameters(
        formals,
        fileOffset,
        noLength,
        uri,
      ).computeFormalParameterScope(
        _localScope,
        this,
        wildcardVariablesEnabled: libraryFeatures.wildcardVariables.isEnabled,
      ),
    );

    if (extraKnownVariables.isNotEmpty) {
      LocalScope extraKnownVariablesScope = _localScope.createNestedScope(
        kind: LocalScopeKind.ifElement,
      );
      enterLocalScope(extraKnownVariablesScope);
      for (ExpressionVariable extraVariable in extraKnownVariables) {
        declareVariable(extraVariable, _localScope);
        assignedVariables.declare(extraVariable);
      }
    }

    Token endToken = parser.parseExpression(
      parser.syntheticPreviousToken(token),
    );

    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    Expression expression = popForValue();
    Token eof = endToken.next!;

    if (!eof.isEof) {
      expression = problemReporting.wrapInLocatedProblem(
        compilerContext: compilerContext,
        expression: expression,
        message: diag.expectedOneExpression.withLocation(
          uri,
          eof.charOffset,
          eof.length,
        ),
      );
    }

    return new BuildSingleExpressionResult(
      expression,
      _takePendingAnnotations(),
    );
  }

  void _registerSingleTargetAnnotations(Annotatable target) {
    (_singleTargetAnnotations ??= []).add(
      new SingleTargetAnnotations(
        target,
        null /*indicesOfAnnotationsToBeInferred*/,
      ),
    );
  }

  void _registerMultiTargetAnnotations(List<Annotatable> targets) {
    (_multiTargetAnnotations ??= []).add(new MultiTargetAnnotations(targets));
  }
}
