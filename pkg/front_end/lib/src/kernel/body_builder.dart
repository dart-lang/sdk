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
import '../base/uri_offset.dart';
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
import '../codes/diagnostic.dart' as diag;
import '../source/check_helper.dart';
import '../source/diet_parser.dart';
import '../source/source_constructor_builder.dart';
import '../source/source_factory_builder.dart';
import '../source/source_library_builder.dart';
import '../source/source_property_builder.dart';
import '../source/source_type_parameter_builder.dart';
import '../source/stack_listener_impl.dart'
    show StackListenerImpl, offsetForToken, AsyncModifier;
import '../source/type_parameter_factory.dart';
import '../source/value_kinds.dart';
import '../util/helpers.dart';
import '../util/local_stack.dart';
import 'assigned_variables_impl.dart';
import 'benchmarker.dart' show Benchmarker, BenchmarkSubdivides;
import 'body_builder_context.dart';
import 'constness.dart' show Constness;
import 'expression_generator.dart';
import 'expression_generator_helper.dart';
import 'internal_ast.dart';
import 'internal_ast_helper.dart' as intern;
import 'kernel_variable_builder.dart';
import 'load_library_builder.dart';
import 'type_algorithms.dart' show calculateBounds;
import 'utils.dart';

part 'body_builder_helpers.dart';

abstract class BodyBuilder {
  /// Builds a single [InternalExpression] for an annotation starting at
  /// [atToken].
  InternalExpression buildAnnotation({required Token atToken});

  BuildEnumConstantResult buildEnumConstant({required Token token});

  BuildFieldInitializerResult buildFieldInitializer({
    required Token startToken,
    required bool isLate,
  });

  BuildFieldsResult buildFields({
    required Token startToken,
    required Token? metadata,
    required bool isTopLevel,
  });

  BuildFunctionBodyResult buildFunctionBody({
    required Token startToken,
    required Token? metadata,
    required MemberKind kind,
  });

  BuildInitializersResult buildInitializers({
    required Token? beginInitializers,
  });

  List<InternalInitializer> buildInitializersUnfinished({
    required Token? beginInitializers,
  });

  /// Returns the metadata [InternalExpression]s parsed from [metadata].
  BuildMetadataListResult buildMetadataList({required Token metadata});

  BuildParameterDefaultValueResult buildParameterDefaultValue({
    required Token initializerToken,
  });

  BuildPrimaryConstructorResult buildPrimaryConstructor({
    required Token startToken,
  });

  BuildPrimaryConstructorBodyResult buildPrimaryConstructorBody({
    required Token startToken,
    required Token? metadata,
  });

  BuildRedirectingFactoryMethodResult buildRedirectingFactoryMethod({
    required Token token,
    required Token? metadata,
  });

  BuildSingleExpressionResult buildSingleExpression({
    required Token token,
    required List<InternalVariable> extraKnownVariables,
    required List<NominalParameterBuilder>? typeParameterBuilders,
    required List<FormalParameterBuilder>? formals,
    required int fileOffset,
  });
}

class BodyBuilderImpl extends StackListenerImpl
    implements BodyBuilder, ExpressionGeneratorHelper {
  static const Modifiers noCurrentLocalVariableModifiers = const Modifiers(-1);

  @override
  final SourceLibraryBuilder libraryBuilder;

  final BodyBuilderContext _context;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final LocalScope enclosingScope;

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

  Link<bool> _isOrAsOperatorTypeState = const Link<bool>().prepend(false);

  Link<bool> _localInitializerState = const Link<bool>().prepend(false);

  List<InternalInitializer> _initializers = [];

  bool inCatchClause = false;

  bool inCatchBlock = false;

  int functionNestingLevel = 0;

  InternalStatement? problemInLoopOrSwitch;

  final LocalStack<LabelScope> _labelScopes;

  final LocalStack<LabelScope?> _switchScopes = new LocalStack([]);

  @override
  ConstantContext constantContext = ConstantContext.none;

  DartType? currentLocalVariableType;

  Modifiers currentLocalVariableModifiers = noCurrentLocalVariableModifiers;

  /// If non-null, records instance fields which have already been initialized
  /// and where that was.
  Map<String, int>? initializedFields;

  List<SingleTargetAnnotations>? _singleTargetAnnotations;

  List<MultiTargetAnnotations>? _multiTargetAnnotations;

  final LocalStack<InternalVariable> _thisVariables;

  /// If the current member is an instance member of a non-extension
  /// declaration, and the closure context lowering experiment is enabled, this
  /// field contains the variable representing `this`.
  InternalThisVariable? _internalThisVariable;

  final List<TypeParameter>? thisTypeParameters;

  final LocalStack<LocalScope> _localScopes;

  int _parameterlessAnonymousMethodDepth = 0;

  Set<InternalVariable>? declaredInCurrentGuard;

  JumpTarget? breakTarget;

  JumpTarget? continueTarget;

  /// Index for building unique lowered names for wildcard variables.
  int wildcardVariableIndex = 0;
  @override
  ExtensionScope extensionScope;

  /// Stack containing assigned variables info for try statements.
  ///
  /// These are created in [beginTryStatement] and ended in either [beginBlock]
  /// when a finally block starts or in [endTryStatement] when the try statement
  /// ends. Since these need to be associated with the try statement created in
  /// in [endTryStatement] we store them the stack until the try statement is
  /// created.
  Link<AssignedVariablesNodeInfo> tryStatementInfoStack =
      const Link<AssignedVariablesNodeInfo>();

  new({
    required this.libraryBuilder,
    required BodyBuilderContext context,
    required this.enclosingScope,
    this.formalParameterScope,
    required this.hierarchy,
    required this.coreTypes,
    InternalVariable? thisVariable,
    this.thisTypeParameters,
    required this.uri,
    required this.assignedVariables,
    required this.typeEnvironment,
    required ConstantContext constantContext,
    required this.extensionScope,
    required InternalThisVariable? internalThisVariable,
  }) : _context = context,
       benchmarker = libraryBuilder.loader.target.benchmarker,
       _localScopes = new LocalStack([enclosingScope]),
       _labelScopes = new LocalStack([new LabelScopeImpl()]),
       _thisVariables = new LocalStack([?thisVariable]),
       _internalThisVariable = internalThisVariable {
    this.constantContext = constantContext;
    if (formalParameterScope != null) {
      for (VariableBuilder builder in formalParameterScope!.localVariables) {
        assignedVariables.declare(builder.variable);
      }
    }
    if (thisVariable != null && context.isConstructor) {
      // The this variable is not part of the [formalParameterScope] in
      // constructors.
      assignedVariables.declare(thisVariable);
    }
    if (isClosureContextLoweringEnabled && _internalThisVariable != null) {
      assignedVariables.declare(_internalThisVariable!);
    }
  }

  @override
  CompilerContext get compilerContext => libraryBuilder.loader.target.context;

  bool get inConstructor {
    return functionNestingLevel == 0 && _context.isConstructor;
  }

  bool get inFunctionType =>
      _structuralParameterDepthLevel > 0 || _insideOfFormalParameterType;

  bool get inIsOrAsOperatorType => _isOrAsOperatorTypeState.head;

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

  @override
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState {
    return _context.instanceTypeParameterAccessState;
  }

  bool get isClosureContextLoweringEnabled {
    return libraryBuilder.loader.isClosureContextLoweringEnabled;
  }

  @override
  bool get isDartLibrary =>
      libraryBuilder.importUri.isScheme("dart") ||
      uri.isScheme("org-dartlang-sdk");

  bool get isDeclarationInstanceContext {
    return _context.isDeclarationInstanceContext;
  }

  @override
  LibraryFeatures get libraryFeatures => libraryBuilder.libraryFeatures;

  @override
  ProblemReporting get problemReporting => libraryBuilder;

  /// If the current member is an instance member in an extension declaration or
  /// an instance member or constructor in and extension type declaration,
  /// [thisVariable] holds the synthetically added variable holding the value
  /// for `this`.
  @override
  InternalVariable? get thisVariable => _thisVariables.currentOrNull;

  LabelScope get _labelScope => _labelScopes.current;

  LocalScope get _localScope => _localScopes.current;

  LabelScope? get _switchScope =>
      _switchScopes.hasCurrent ? _switchScopes.current : null;

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
  void beginAnonymousMethodInvocation(Token token) {
    debugEvent("beginAnonymousMethodInvocation");
    assert(
      checkState(token, [
        /* receiver */ const UnionValueKind([
          ValueKinds.Expression,
          ValueKinds.Generator,
        ]),
      ]),
    );
    assignedVariables.beginNode();
  }

  @override
  void beginAsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.prepend(true);
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
  void beginBinaryExpression(Token token) {
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    bool isAnd = token.isA(TokenType.AMPERSAND_AMPERSAND);
    if (isAnd || token.isA(TokenType.BAR_BAR)) {
      InternalExpression lhs = popForValue();
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
  void beginBlockFunctionBody(Token begin) {
    debugEvent("beginBlockFunctionBody");
    createAndEnterLocalScope(kind: LocalScopeKind.functionBody);
  }

  @override
  void beginCascade(Token token) {
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    debugEvent("beginCascade");
    InternalExpression expression = popForValue();
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
      InternalSyntheticVariable variable = intern.createSyntheticVariable(
        isFinal: true,
        fileOffset: expression.fileOffset,
      );
      assignedVariables.declare(variable);
      push(
        new Cascade(
          variable: variable,
          receiver: expression,
          isNullAware: isNullAware,
          fileOffset: expression.fileOffset,
        ),
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
  void beginCatchClause(Token token) {
    debugEvent("beginCatchClause");
    inCatchClause = true;
  }

  @override
  void beginConditionalExpression(Token question) {
    InternalExpression condition = popForValue();
    // This is matched by the call to [deferNode] in
    // [handleConditionalExpressionColon].
    assignedVariables.beginNode();
    push(condition);
    super.beginConditionalExpression(question);
  }

  @override
  void beginConstantPattern(Token? constKeyword) {
    debugEvent("ConstantPattern");
    push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void beginConstDotShorthand(Token token) {
    debugEvent("beginConstDotShorthand");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
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
  void beginDoWhileStatement(Token token) {
    debugEvent("beginDoWhileStatement");
    // This is matched by the [endNode] call in [endDoWhileStatement].
    assignedVariables.beginNode();
    enterLoop(token.charOffset);
  }

  @override
  void beginDoWhileStatementBody(Token token) {
    debugEvent("beginDoWhileStatementBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void beginElseStatement(Token token) {
    debugEvent("beginElseStatement");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void beginFieldInitializer(Token token) {
    inFieldInitializer = true;
    constantContext = _context.constantContext;
    inLateFieldInitializer = _context.isLateField;
    _enterFieldInitializerScope();
    if (_context.isAbstractField) {
      addProblem(diag.abstractFieldInitializer, token.charOffset, noLength);
    } else if (_context.isExternalField) {
      addProblem(diag.externalFieldInitializer, token.charOffset, noLength);
    }
  }

  @override
  void beginForControlFlow(Token? awaitToken, Token forToken) {
    debugEvent("beginForControlFlow");
    createAndEnterLocalScope(kind: LocalScopeKind.forStatement);
  }

  @override
  void beginForInBody(Token token) {
    debugEvent("beginForInBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
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
  void beginFormalParameterDefaultValueExpression() {
    super.push(constantContext);
    _insideOfFormalParameterType = false;
    constantContext = ConstantContext.required;
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    super.push(constantContext);
    super.push(inFormals);
    constantContext = ConstantContext.none;
    inFormals = true;
  }

  @override
  void beginForStatement(Token token) {
    debugEvent("beginForStatement");
    enterLoop(token.charOffset);
    createAndEnterLocalScope(kind: LocalScopeKind.forStatement);
  }

  @override
  void beginForStatementBody(Token token) {
    debugEvent("beginForStatementBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  @override
  void beginFunctionExpression(Token token) {
    debugEvent("beginFunctionExpression");
    enterFunction();
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
    _structuralParameterDepthLevel++;
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    _insideOfFormalParameterType = false;
    functionNestingLevel++;
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    // TODO(danrubel): consider removing this when control flow support is added
    // if the ifToken is not needed for error reporting
    push(ifToken);
  }

  @override
  void beginImplicitCreationExpression(Token token) {
    debugEvent("beginImplicitCreationExpression");
    super.push(constantContext);
  }

  @override
  void beginInitializer(Token token) {
    debugEvent("beginInitializer");
    inInitializerLeftHandSide = true;
    inFieldInitializer = true;
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
  void beginIsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.prepend(true);
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
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    debugEvent("beginLocalFunctionDeclaration");
    enterFunction();
  }

  @override
  void beginMetadata(Token token) {
    debugEvent("beginMetadata");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
    assert(checkState(token, [ValueKinds.ConstantContext]));
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
  void beginNewExpression(Token token) {
    debugEvent("beginNewExpression");
    super.push(constantContext);
    constantContext = ConstantContext.none;
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
  void beginPatternGuard(Token when) {
    debugEvent("PatternGuard");
    assert(
      checkState(when, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Pattern]),
      ]),
    );

    InternalPattern pattern = toPattern(peek());
    createAndEnterLocalScope(kind: LocalScopeKind.ifCaseHead);
    for (InternalDeclaredVariable variable in pattern.declaredVariables) {
      assert(!variable.hasInitializer);
      declareVariable(variable, _localScope);
    }
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

    List<InternalDeclaredVariable>? jointPatternVariables;
    List<InternalDeclaredVariable>?
    jointPatternVariablesWithMismatchingFinality;
    List<InternalDeclaredVariable>? jointPatternVariablesNotInAll;
    enterLocalScope(switchCaseScope);
    if (expressionCount > 1) {
      for (int i = 0; i < expressionOrPatterns.length; i++) {
        ExpressionOrPatternGuardCase expressionOrPattern =
            expressionOrPatterns[i];
        InternalPatternGuard? patternGuard = expressionOrPattern.patternGuard;
        if (patternGuard != null) {
          InternalPattern pattern = patternGuard.pattern;
          if (jointPatternVariables == null) {
            jointPatternVariables = [
              for (InternalDeclaredVariable variable
                  in pattern.declaredVariables)
                intern.createSyntheticVariable(
                  name: variable.cosmeticName!,
                  isFinal: variable.isFinal,
                  fileOffset: variable.fileOffset,
                  isSynthesized: false,
                ),
            ];
            if (i != 0) {
              // The previous heads were non-pattern ones, so no variables can
              // be joined.
              (jointPatternVariablesNotInAll ??= []).addAll(
                jointPatternVariables,
              );
            }
          } else {
            Map<String, InternalDeclaredVariable> patternVariablesByName = {
              for (InternalDeclaredVariable variable
                  in pattern.declaredVariables)
                variable.cosmeticName!: variable,
            };
            for (InternalDeclaredVariable jointVariable
                in jointPatternVariables) {
              String jointVariableName = jointVariable.cosmeticName!;
              InternalDeclaredVariable? patternVariable = patternVariablesByName
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
              for (InternalDeclaredVariable variable
                  in patternVariablesByName.values) {
                InternalDeclaredVariable jointVariable = intern
                    .createSyntheticVariable(
                      name: variable.cosmeticName!,
                      isFinal: variable.isFinal,
                      fileOffset: variable.fileOffset,
                      isSynthesized: false,
                    );
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
          for (InternalVariable jointVariable in jointPatternVariables) {
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
        ValueKinds.InternalDeclaredVariableListOrNull,
        ValueKinds.InternalDeclaredVariableListOrNull,
        ValueKinds.InternalDeclaredVariableListOrNull,
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
    if (pattern is InternalPattern) {
      for (InternalDeclaredVariable variable in pattern.declaredVariables) {
        assert(!variable.hasInitializer);
        declareVariable(variable, _localScope);
      }
    }
    push(constantContext);
    constantContext = ConstantContext.none;
  }

  @override
  void beginThenStatement(Token token) {
    debugEvent("beginThenStatement");
    assert(checkState(token, [ValueKinds.Condition]));
    // This is matched by the call to [deferNode] in
    // [endThenStatement].
    assignedVariables.beginNode();
    Condition condition = pop() as Condition;
    InternalPatternGuard? patternGuard = condition.patternGuard;
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
        InternalPattern pattern = patternGuard.pattern;
        for (InternalDeclaredVariable variable in pattern.declaredVariables) {
          assert(!variable.hasInitializer);
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
  void beginTryStatement(Token token) {
    // This is matched by the call to [endNode] in [endTryStatement].
    assignedVariables.beginNode();
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
    List<InternalExpression>? annotations = pop() as List<InternalExpression>?;
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
          _registerSingleTargetAnnotations(variable.parameter, annotations);
          break;
      }
    }
    push(variable);
  }

  @override
  void beginVariableInitializer(Token token) {
    if (currentLocalVariableModifiers.isLate) {
      // This is matched by the call to [endNode] in [endVariableInitializer].
      assignedVariables.beginNode();
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
  void beginWhileStatement(Token token) {
    debugEvent("beginWhileStatement");
    // This is matched by the [endNode] call in [endWhileStatement].
    assignedVariables.beginNode();
    enterLoop(token.charOffset);
  }

  @override
  void beginWhileStatementBody(Token token) {
    debugEvent("beginWhileStatementBody");
    createAndEnterLocalScope(kind: LocalScopeKind.statementLocalScope);
  }

  InternalExpression buildAbstractClassInstantiationError(
    Message message,
    String className,
    int charOffset,
  ) {
    addProblemErrorIfConst(message, charOffset, className.length);
    return intern.createInvalidExpression(
      message.problemMessage,
      fileOffset: charOffset,
    );
  }

  @override
  InternalExpression buildAnnotation({required Token atToken}) {
    return parseAnnotation(atToken);
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

  InternalInitializer buildDuplicatedInitializer(
    SourcePropertyBuilder fieldBuilder,
    InternalExpression value,
    String name,
    int offset,
    int previousInitializerOffset,
  ) {
    return intern.createInvalidInitializer(
      buildProblem(
        message: diag.constructorInitializeSameInstanceVariableSeveralTimes
            .withArguments(fieldName: name),
        fileUri: uri,
        fileOffset: offset,
        length: noLength,
      ),
    );
  }

  @override
  BuildEnumConstantResult buildEnumConstant({required Token token}) {
    ActualArguments arguments = parseArguments(token);
    return new BuildEnumConstantResult(arguments, _takePendingAnnotations());
  }

  @override
  BuildFieldInitializerResult buildFieldInitializer({
    required Token startToken,
    required bool isLate,
  }) {
    inFieldInitializer = true;
    inLateFieldInitializer = isLate;
    _enterFieldInitializerScope();
    InternalExpression initializer = _parseInitializer(startToken);
    _exitFieldInitializerScope();
    return new BuildFieldInitializerResult(
      initializer,
      _takePendingAnnotations(),
    );
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
    Map<Identifier, InternalExpression?> result = {};
    for (int i = 0; i < count; i++) {
      assert(
        checkState(null, [
          ValueKinds.FieldInitializerOrNull,
          ValueKinds.Identifier,
        ]),
      );
      InternalExpression? initializer = pop() as InternalExpression?;
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
    AsyncModifier asyncModifier =
        pop() as AsyncModifier? ?? AsyncModifier.implicitSync;
    if (kind == MemberKind.Factory && asyncModifier.kind != AsyncMarker.Sync) {
      // Factories has to be sync. The parser issued an error.
      // Recover to sync.
      asyncModifier = AsyncModifier.implicitSync;
    }
    bool isExpression = false;
    bool allowAbstract = asyncModifier.kind == AsyncMarker.Sync;

    benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(
      BenchmarkSubdivides.diet_listener_buildFunctionBody_parseFunctionBody,
    );
    parser.parseFunctionBody(token, isExpression, allowAbstract);
    InternalStatement? body = pop() as InternalStatement?;
    benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    checkEmpty(token.charOffset);
    return new BuildFunctionBodyResult(
      asyncModifier: asyncModifier,
      body: body,
      initializers: _initializers,
      annotations: _takePendingAnnotations(),
    );
  }

  @override
  BuildInitializersResult buildInitializers({
    required Token? beginInitializers,
  }) {
    parseInitializers(beginInitializers);
    return new BuildInitializersResult(
      _initializers,
      _takePendingAnnotations(),
    );
  }

  @override
  List<InternalInitializer> buildInitializersUnfinished({
    required Token? beginInitializers,
  }) {
    return parseInitializers(beginInitializers);
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
    List<InternalExpression> expressions = pop() as List<InternalExpression>;
    return new BuildMetadataListResult(expressions, _takePendingAnnotations());
  }

  @override
  InternalExpression buildMethodInvocation(
    InternalExpression receiver,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int offset, {
    bool isConstantExpression = false,
    bool isNullAware = false,
    bool isImplicitThis = false,
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
    return intern.createMethodInvocation(
      offset,
      receiver,
      name,
      typeArguments,
      arguments,
      isNullAware: isNullAware,
      isImplicitThis: isImplicitThis,
    );
  }

  @override
  BuildParameterDefaultValueResult buildParameterDefaultValue({
    required Token initializerToken,
  }) {
    InternalExpression initializer = _parseInitializer(initializerToken);
    return new BuildParameterDefaultValueResult(
      initializer,
      _takePendingAnnotations(),
    );
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
        assignedVariables.declare(formal.variable, ignoreDuplicates: true);
      }
    }
    token = parser.parseInitializersOpt(token);
    token = parser.parseAsyncModifierOpt(token);
    AsyncModifier asyncModifier =
        pop() as AsyncModifier? ?? AsyncModifier.implicitSync;
    bool isExpression = false;
    bool allowAbstract = asyncModifier.kind == AsyncMarker.Sync;

    benchmarker
    // Coverage-ignore(suite): Not run.
    ?.beginSubdivide(
      BenchmarkSubdivides.diet_listener_buildFunctionBody_parseFunctionBody,
    );
    parser.parseFunctionBody(token, isExpression, allowAbstract);
    InternalStatement? body = pop() as InternalStatement?;
    benchmarker
        // Coverage-ignore(suite): Not run.
        ?.endSubdivide();
    checkEmpty(token.charOffset);
    return new BuildPrimaryConstructorBodyResult(
      asyncModifier: asyncModifier,
      body: body,
      initializers: _initializers,
      annotations: _takePendingAnnotations(),
    );
  }

  @override
  InternalInvalidExpression buildProblem({
    required Message message,
    required Uri fileUri,
    required int fileOffset,
    required int length,
    List<LocatedMessage>? context,
    bool errorHasBeenReported = false,
    InternalExpression? expression,
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
    return intern.createInvalidExpression(
      text,
      expression: expression,
      fileOffset: fileOffset,
    );
  }

  @override
  InternalExpression buildProblemErrorIfConst(
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
    InternalInvalidExpression expression = intern.createInvalidExpression(
      text,
      fileOffset: charOffset,
    );
    return expression;
  }

  InternalStatement buildProblemStatement(
    Message message,
    int charOffset, {
    List<LocatedMessage>? context,
    int? length,
    bool errorHasBeenReported = false,
  }) {
    length ??= noLength;
    return intern.createExpressionStatement(
      buildProblem(
        message: message,
        fileUri: uri,
        fileOffset: charOffset,
        length: length,
        context: context,
        errorHasBeenReported: errorHasBeenReported,
      ),
      fileOffset: charOffset,
    );
  }

  InternalStatement buildProblemTargetOutsideLocalFunction(
    String? name,
    Token keyword,
  ) {
    InternalStatement problem;
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
  InternalInitializer buildRedirectingInitializer(
    Name name,
    ActualArguments arguments, {
    required int fileOffset,
  }) {
    MemberLookupResult? result = _context.lookupConstructor(name);
    if (result == null) {
      int length = name.text.length;
      if (length == 0) {
        // The constructor is unnamed so the offset points to 'this'.
        length = "this".length;
      }
      String fullName = constructorNameForDiagnostics(name.text);
      return intern.createInvalidInitializer(
        buildProblem(
          message: diag.constructorNotFound.withArguments(name: fullName),
          fileUri: uri,
          fileOffset: fileOffset,
          length: length,
        ),
        isRedirectingInitializer: true,
      );
    } else if (result.isInvalidLookup) {
      return intern.createInvalidInitializerFromErrorText(
        LookupResult.createDuplicateErrorText(
          result,
          context: compilerContext,
          name: name.text,
          fileUri: uri,
          fileOffset: fileOffset,
          length: noLength,
        ),
        isRedirectingInitializer: true,
      );
    } else {
      MemberBuilder builder = result.getable!;
      if (builder is SourceFactoryBuilder) {
        return intern.createInvalidInitializer(
          buildProblem(
            message: diag.redirectGenerativeToNonGenerativeConstructor,
            fileUri: uri,
            fileOffset: fileOffset,
            length: noLength,
          ),
          isRedirectingInitializer: true,
        );
      } else {
        assert(
          builder is SourceConstructorBuilder,
          "Unexpected constructor builder $builder.",
        );
        if (_context.isConstructorCyclic(name.text)) {
          int length = name.text.length;
          if (length == 0) length = "this".length;
          return intern.createInvalidInitializer(
            buildProblem(
              message: diag.constructorCyclic,
              fileUri: uri,
              fileOffset: fileOffset,
              length: length,
            ),
            isRedirectingInitializer: true,
          );
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
          builder,
          arguments,
          fileOffset: fileOffset,
        );
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  BuildSingleExpressionResult buildSingleExpression({
    required Token token,
    required List<InternalVariable> extraKnownVariables,
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
        assignedVariables.declare(formalParameterBuilder.variable);
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
      for (InternalVariable extraVariable in extraKnownVariables) {
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
    InternalExpression expression = popForValue();
    Token eof = endToken.next!;

    if (!eof.isEof) {
      expression = intern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblemFromLocatedMessage(
          compilerContext: compilerContext,
          message: diag.expectedOneExpression.withLocation(
            uri,
            eof.charOffset,
            eof.length,
          ),
        ),
        expression: expression,
      );
    }

    return new BuildSingleExpressionResult(
      expression,
      _takePendingAnnotations(),
    );
  }

  @override
  InternalExpression buildStaticInvocation({
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required int fileOffset,
  }) {
    ErrorText? errorText = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
      explicitTypeArguments: typeArguments,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: uri,
    );
    if (errorText != null) {
      return intern.createInvalidExpressionFromErrorText(errorText);
    }

    return new InternalStaticInvocation(
      target.name,
      target,
      typeArguments,
      arguments,
      fileOffset: fileOffset,
    );
  }

  @override
  InternalInitializer buildSuperInitializer(
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
    return intern.createSuperInitializer(
      target: constructor,
      arguments: arguments,
      isSynthetic: isSynthetic,
      fileOffset: charOffset,
    );
  }

  @override
  InternalExpression buildSuperInvocation(
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
      return intern.createSuperMethodInvocation(
        name: name,
        typeArguments: typeArguments,
        arguments: arguments,
        procedure: target,
        fileOffset: offset,
      );
    }
    if (isImplicitCall) {
      return buildProblem(
        message: diag.implicitSuperCallOfNonMethod,
        fileUri: uri,
        fileOffset: offset,
        length: noLength,
      );
    } else {
      InternalExpression receiver = intern.createSuperPropertyGet(
        intern.createThisExpression(fileOffset: offset),
        name,
        target,
        fileOffset: offset,
      );
      return intern.createExpressionInvocation(
        arguments.fileOffset,
        receiver,
        typeArguments,
        arguments,
      );
    }
  }

  @override
  InternalInvalidExpression buildUnresolvedError(
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

  @override
  String constructorNameForDiagnostics(String name, {String? className}) {
    className ??= _context.className;
    return name.isEmpty ? className : "$className.$name";
  }

  void createAndEnterLocalScope({required LocalScopeKind kind}) {
    _localScopes.push(_localScope.createNestedScope(kind: kind));
    _labelScopes.push(new LabelScopeImpl(_labelScope));
  }

  JumpTarget createBreakTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Break, charOffset);
  }

  JumpTarget createContinueTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Continue, charOffset);
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
  List<InternalInitializer> createFieldInitializer(
    String name,
    int fieldNameOffset,
    InternalExpression expression, {
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
        _context.registerInitializedField(
          firstBuilder,
          new FieldInitialization(
            new UriOffsetLength(uri, fieldNameOffset, name.length),
            fromInitializingFormal: formal != null,
          ),
        );
      }
      return [
        intern.createInvalidInitializerFromErrorText(
          LookupResult.createDuplicateErrorText(
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
      if (builder.isInvalidField) {
        // Operating on an invalid field. Don't report anything though
        // as we've already reported that the field isn't valid.
        return [
          intern.createInvalidInitializer(
            intern.createInvalidExpression(
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
              fileOffset: builder.fileOffset,
            ),
          ),
        ];
      }

      initializedFields ??= <String, int>{};
      if (initializedFields!.containsKey(name)) {
        return [
          buildDuplicatedInitializer(
            builder,
            expression,
            name,
            fieldNameOffset,
            initializedFields![name]!,
          ),
        ];
      }
      initializedFields![name] = fieldNameOffset;
      if (builder.hasAbstractField) {
        return [
          intern.createInvalidInitializer(
            buildProblem(
              message: diag.abstractFieldConstructorInitializer,
              fileUri: uri,
              fileOffset: fieldNameOffset,
              length: name.length,
            ),
          ),
        ];
      } else if (builder.hasExternalField) {
        return [
          intern.createInvalidInitializer(
            buildProblem(
              message: diag.externalFieldConstructorInitializer,
              fileUri: uri,
              fileOffset: fieldNameOffset,
              length: name.length,
            ),
          ),
        ];
      } else if (builder.isFinal && builder.hasInitializer) {
        return [
          intern.createInvalidInitializer(
            buildProblem(
              message: diag.fieldAlreadyInitializedAtDeclaration.withArguments(
                fieldName: name,
              ),
              fileUri: uri,
              fileOffset: fieldNameOffset,
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
        _context.registerInitializedField(
          builder,
          new FieldInitialization(
            new UriOffsetLength(uri, fieldNameOffset, name.length),
            fromInitializingFormal: formal != null,
          ),
        );
        if (formal != null && formal.type is! OmittedTypeBuilder) {
          DartType formalType = formal.variable.type;
          DartType fieldType = _context.substituteFieldType(builder.fieldType);
          if (!typeEnvironment.isSubtypeOf(formalType, fieldType)) {
            return [
              intern.createInvalidInitializer(
                buildProblem(
                  message: diag.initializingFormalTypeMismatch.withArguments(
                    parameterName: name,
                    parameterType: formalType,
                    fieldType: builder.fieldType,
                  ),
                  fileOffset: fieldNameOffset,
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
          fieldNameOffset,
          expression,
          isSynthetic: formal != null,
        );
      }
    } else {
      return [
        intern.createInvalidInitializer(
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

  JumpTarget createGotoTarget(int charOffset) {
    return createJumpTarget(JumpTargetKind.Goto, charOffset);
  }

  @override
  InternalExpression createInstantiationAndInvocation(
    InternalExpression Function() receiverFunction,
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
      InternalExpression receiver = receiverFunction();
      if (typeArgumentBuilders != null) {
        if (receiver is InternalStaticTearOff &&
                (receiver.target.isFactory ||
                    isTearOffLowering(receiver.target)) ||
            receiver is InternalConstructorTearOff ||
            receiver is InternalRedirectingFactoryTearOff) {
          return buildProblem(
            message: diag.constructorTearOffWithTypeArguments,
            fileUri: uri,
            fileOffset: instantiationOffset,
            length: noLength,
          );
        }
        receiver = intern.createInstantiation(
          fileOffset: instantiationOffset,
          receiver,
          buildDartTypeArguments(
            typeArgumentBuilders,
            TypeUse.tearOffTypeArgument,
            allowPotentiallyConstantType: true,
          ),
        );
      }
      return intern.createMethodInvocation(
        invocationOffset,
        receiver,
        new Name(constructorName, libraryBuilder.nameOrigin),
        null,
        arguments,
        isNullAware: false,
        isImplicitThis: false,
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

  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(kind, functionNestingLevel, uri, charOffset);
  }

  /// Helper method to create a [VariableGet] of the [variable] using
  /// [charOffset] as the file offset.
  @override
  InternalVariableGet createVariableGet(
    InternalVariable variable,
    int charOffset,
  ) {
    registerVariableRead(variable);
    return intern.createVariableGet(variable, fileOffset: charOffset);
  }

  @override
  void debugEvent(String name) {
    // printEvent('BodyBuilder: $name');
  }

  InternalInvalidExpression? declareVariable(
    InternalVariable variable,
    LocalScope scope, [
    InternalExpression? initializer,
  ]) {
    String name = variable.cosmeticName!;
    Builder? existing = scope.lookupLocalVariable(name);
    if (existing != null) {
      // This reports an error for duplicated declarations in the same scope:
      // `{ var x; var x; }`
      return wrapVariableInitializerInError(
        variable,
        initializer,
        <LocatedMessage>[
          diag.duplicatedDeclarationCause
              .withArguments(name: name)
              .withLocation(uri, existing.fileOffset, name.length),
        ],
      );
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
    return null;
  }

  void doBinaryExpression(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    InternalExpression right = popForValue();
    Object? left = pop();
    int fileOffset = offsetForToken(token);
    String operator = token.stringValue!;
    bool isNot = identical("!=", operator);
    if (isNot || identical("==", operator)) {
      if (left is Generator) {
        push(left.buildEqualsOperation(token, right, isNot: isNot));
      } else {
        assert(left is InternalExpression);
        push(
          intern.createEquals(
            fileOffset,
            left as InternalExpression,
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
        assert(left is InternalExpression);
        push(
          intern.createBinary(
            fileOffset,
            left as InternalExpression,
            name,
            right,
          ),
        );
      }
    }
    assert(checkState(token, <ValueKind>[ValueKinds.Expression]));
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

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    assert(
      checkState(token, <ValueKind>[
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    InternalExpression b = popForValue();
    InternalExpression a = popForValue();
    push(
      intern.createIfNullExpression(
        left: a,
        right: b,
        fileOffset: offsetForToken(token),
      ),
    );
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
    InternalExpression argument = popForValue();
    InternalExpression receiver = pop() as InternalExpression;
    InternalExpression logicalExpression = intern.createLogicalExpression(
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

  @override
  void endAnonymousMethodInvocation(
    Token beginToken,
    Token? functionDefinition,
    Token endToken, {
    required bool isExpression,
  }) {
    debugEvent("endAnonymousMethodInvocation");
    assert(
      checkState(beginToken, [
        /* body */ const UnionValueKind([
          ValueKinds.Block,
          ValueKinds.Expression,
          ValueKinds.Generator,
        ]),
        /* formal parameters */ const UnionValueKind([
          ValueKinds.AnonymousMethodParameters,
          ValueKinds.AnonymousMethodParameterListOrNull,
        ]),
        /* receiver */ const UnionValueKind([
          ValueKinds.Expression,
          ValueKinds.Generator,
        ]),
      ]),
    );

    Object? body = pop();
    AnonymousMethodParameters? formals =
        pop(NullValues.FormalParameters) as AnonymousMethodParameters?;
    if (formals != null && _localScope.kind == LocalScopeKind.formals) {
      exitLocalScope(expectedScopeKinds: const [LocalScopeKind.formals]);
    }

    InternalExpression? bodyExpr;
    if (isExpression) {
      bodyExpr = toValue(body);
    }

    InternalExpression receiver;
    InternalAnonymousMethodParameter variable;
    bool isImplicitlyTyped;
    int typeOffset;

    if (formals == null) {
      variable = _thisVariables.pop() as InternalAnonymousMethodParameter;
      _parameterlessAnonymousMethodDepth--;
      receiver = popForValue();
      isImplicitlyTyped = true;
      typeOffset = variable.fileOffset;
    } else if (formals.parameters?.length == 1 &&
        formals.parameters![0].isRequiredPositional) {
      receiver = popForValue();
      AnonymousMethodParameterBuilder formal = formals.parameters![0];

      // Build the variable declaration.
      variable = formal.build(libraryBuilder);

      isImplicitlyTyped = variable.isImplicitlyTyped;
      typeOffset = formal.type.charOffset ?? variable.fileOffset;
    } else {
      InternalExpression result = buildProblem(
        message: diag.anonymousMethodWrongParameterList,
        fileUri: uri,
        fileOffset: formals.charOffset,
        length: formals.length,
      );
      popForValue();
      push(result);
      assignedVariables.endNode(
        result,
        isClosureOrLateVariableInitializer: false,
      );
      return;
    }
    int variableOffset = receiver.fileOffset;

    // Build the result expression.
    bool isNullAware = beginToken.lexeme == '?.' || beginToken.lexeme == '?..';
    bool isCascade = beginToken.lexeme == '..' || beginToken.lexeme == '?..';

    InternalExpression result;
    if (isExpression) {
      result = intern.createAnonymousMethodExpression(
        variable: variable,
        receiver: receiver,
        body: bodyExpr!,
        isImplicitlyTyped: isImplicitlyTyped,
        isNullAware: isNullAware,
        isCascade: isCascade,
        typeOffset: typeOffset,
        fileOffset: variableOffset,
      );
    } else {
      InternalStatement bodyStatement = body as InternalStatement;
      result = intern.createAnonymousMethodBlock(
        variable: variable,
        receiver: receiver,
        body: bodyStatement,
        isImplicitlyTyped: isImplicitlyTyped,
        isNullAware: isNullAware,
        isCascade: isCascade,
        typeOffset: typeOffset,
        fileOffset: variableOffset,
      );
    }

    push(result);
    assignedVariables.endNode(
      result,
      isClosureOrLateVariableInitializer: false,
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
        intern.createArguments(
          beginToken.offset,
          arguments: argumentsOriginalOrder,
          hasNamedBeforePositional: hasNamedBeforePositional,
          positionalCount: positionalCount,
        ),
      );
    } else {
      // TODO(kmillikin): Find a way to avoid allocating a second list in the
      // case where there were no named arguments, which is a common one.
      // arguments have non-null InternalExpression entries after the initial
      // loop.
      push(
        intern.createArguments(
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
  void endAsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.tail!;
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
    InternalExpression? message = popForValueIfNotNull(commaToken);
    InternalExpression condition = popForValue();
    int fileOffset = offsetForToken(assertKeyword);

    /// Return a representation of an assert that appears as a statement.
    InternalAssertStatement createAssertStatement() {
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

      return intern.createAssertStatement(
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
          intern.createAssertInitializer(
            createAssertStatement(),
            fileOffset: fileOffset,
          ),
        );
        break;
    }
  }

  @override
  void endAwaitExpression(Token keyword, Token endToken) {
    debugEvent("AwaitExpression");
    int fileOffset = offsetForToken(keyword);
    InternalExpression value = popForValue();
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
      push(intern.createAwaitExpression(fileOffset, value));
    }
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
  void endBinaryPattern(Token operatorToken) {
    debugEvent("BinaryPattern");
    assert(
      checkState(operatorToken, [
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
      operatorToken.charOffset,
      operatorToken.charCount,
    );
    InternalPattern right = toPattern(pop());
    InternalPattern left = toPattern(pop());

    String operator = operatorToken.lexeme;
    switch (operator) {
      case '&&':
        push(intern.createAndPattern(operatorToken.charOffset, left, right));
        break;
      case '||':
        Map<String, InternalDeclaredVariable> leftVariablesByName = {
          for (InternalDeclaredVariable leftVariable in left.declaredVariables)
            leftVariable.cosmeticName!: leftVariable,
        };
        for (InternalDeclaredVariable rightVariable
            in right.declaredVariables) {
          if (!leftVariablesByName.containsKey(rightVariable.cosmeticName)) {
            addProblem(
              diag.missingVariablePattern.withArguments(
                variableName: rightVariable.cosmeticName!,
              ),
              left.fileOffset,
              noLength,
            );
          }
        }
        Map<String, InternalDeclaredVariable> rightVariablesByName = {
          for (InternalDeclaredVariable rightVariable
              in right.declaredVariables)
            rightVariable.cosmeticName!: rightVariable,
        };
        for (InternalDeclaredVariable leftVariable in left.declaredVariables) {
          if (!rightVariablesByName.containsKey(leftVariable.cosmeticName)) {
            addProblem(
              diag.missingVariablePattern.withArguments(
                variableName: leftVariable.cosmeticName!,
              ),
              right.fileOffset,
              noLength,
            );
          }
        }
        List<InternalDeclaredVariable> jointVariables = [
          for (InternalDeclaredVariable leftVariable in left.declaredVariables)
            intern.createSyntheticVariable(
              name: leftVariable.cosmeticName!,
              fileOffset: leftVariable.fileOffset,
              isSynthesized: false,
              // TODO(johnniwinther): Should this be final if [leftVariable]
              //  is?
            ),
        ];
        for (InternalDeclaredVariable variable in jointVariables) {
          assert(!variable.hasInitializer);
          declareVariable(variable, _localScope);
          assignedVariables.declare(variable);
        }
        push(
          intern.createOrPattern(
            operatorToken.charOffset,
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
          operatorToken.charOffset,
          uri,
        );
    }
  }

  @override
  void endBlock(
    int count,
    Token openBrace,
    Token closeBrace,
    BlockKind blockKind,
  ) {
    debugEvent("Block");
    InternalStatement block = popBlock(count, openBrace, closeBrace);
    exitLocalScope();
    push(block);
    if (blockKind == BlockKind.tryStatement) {
      // This is matched by the call to [beginNode] in [beginBlock].
      assignedVariables.endNode(block);
    }
  }

  @override
  void endBlockFunctionBody(int count, Token? openBrace, Token closeBrace) {
    debugEvent("BlockFunctionBody");
    if (openBrace == null) {
      assert(count == 0);
      push(NullValues.Block);
    } else {
      InternalStatement block = popBlock(count, openBrace, closeBrace);
      exitLocalScope();
      push(block);
    }
    assert(checkState(closeBrace, [ValueKinds.StatementOrNull]));
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
    InternalExpression expression = popForEffect();
    Cascade cascadeReceiver = pop() as Cascade;
    cascadeReceiver.addCascadeExpression(expression);
    push(cascadeReceiver);
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

    InternalExpression? guard;
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
    if (value is InternalPattern) {
      super.push(
        new ExpressionOrPatternGuardCase.patternGuard(
          caseKeyword.charOffset,
          intern.createPatternGuard(caseKeyword.charOffset, value, guard),
        ),
      );
    } else if (guard != null) {
      super.push(
        new ExpressionOrPatternGuardCase.patternGuard(
          caseKeyword.charOffset,
          intern.createPatternGuard(
            caseKeyword.charOffset,
            toPattern(value),
            guard,
          ),
        ),
      );
    } else {
      InternalExpression expression = toValue(value);
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
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
    inCatchClause = false;
    push(inCatchBlock);
    inCatchBlock = true;
  }

  @override
  void endConditionalExpression(Token question, Token colon, Token endToken) {
    debugEvent("ConditionalExpression");
    InternalExpression elseExpression = popForValue();
    InternalExpression thenExpression = pop() as InternalExpression;
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
    InternalExpression condition = pop() as InternalExpression;
    InternalExpression node = intern.createConditionalExpression(
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
  void endConstantPattern(Token? constKeyword) {
    debugEvent("ConstantPattern");
    assert(
      checkState(constKeyword, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        ValueKinds.ConstantContext,
      ]),
    );
    InternalExpression expression = toValue(pop());
    constantContext = pop() as ConstantContext;
    push(expression);
  }

  @override
  void endConstDotShorthand(Token token) {
    debugEvent("endConstDotShorthand");
    Object? dotShorthand = pop();
    constantContext = pop() as ConstantContext;
    push(dotShorthand);
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
  void endConstLiteral(Token endToken) {
    debugEvent("endConstLiteral");
    Object? literal = pop();
    constantContext = pop() as ConstantContext;
    push(literal);
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
    InternalExpression expression = condition.expression;
    InternalStatement body = popStatement(doKeyword);
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;

    InternalLoopStatement doStatement = intern.createDoStatement(
      offsetForToken(doKeyword),
      body,
      expression,
    );
    if (breakTarget.hasUsers) {
      breakTarget.resolveBreaks(doStatement);
    }
    if (continueTarget.hasUsers) {
      continueTarget.resolveContinues(doStatement);
    }
    // This is matched by the [beginNode] call in [beginDoWhileStatement].
    assignedVariables.endNode(doStatement);

    exitLoopOrSwitch(doStatement);
  }

  @override
  void endDoWhileStatementBody(Token token) {
    debugEvent("endDoWhileStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void endElseStatement(Token beginToken, Token endToken) {
    debugEvent("endElseStatement");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token endToken) {
    debugEvent("FieldInitializer");
    inFieldInitializer = false;
    inLateFieldInitializer = false;
    assert(assignmentOperator.stringValue == "=");
    push(popForValue());
    _exitFieldInitializerScope();
    constantContext = ConstantContext.none;
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

  @override
  void endForControlFlow(Token token) {
    assert(
      checkState(token, <ValueKind>[
        /* entry = */ unionOfKinds(<ValueKind>[
          ValueKinds.Generator,
          ValueKinds.ExpressionOrNull,
          ValueKinds.Statement,
          ValueKinds.ParserRecovery,
          ValueKinds.Element,
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
    List<InternalExpression> updates = popListForEffect(updateExpressionCount);
    InternalStatement conditionStatement = popStatement(forToken); // condition

    if (constantContext != ConstantContext.none) {
      Object? variableOrExpression = pop();
      if (variableOrExpression is InternalPatternVariableDeclaration) {
        pop(); // Internal variables.
        pop(); // Intermediate variables.
      }
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
    List<InternalVariableDeclaration>? variables;
    List<InternalVariableDeclaration>? intermediateVariables;
    if (variableOrExpression is InternalPatternVariableDeclaration) {
      variables =
          pop() as List<InternalVariableDeclaration>; // Internal variables.
      intermediateVariables = pop() as List<InternalVariableDeclaration>;
    } else {
      variables = _buildForLoopVariableDeclarations(variableOrExpression)!;
    }
    exitLocalScope();

    assignedVariables.pushNode(assignedVariablesNodeInfo);
    InternalExpression? condition;
    if (conditionStatement is InternalExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is InternalEmptyStatement);
    }
    InternalElement result;
    if (variableOrExpression is InternalPatternVariableDeclaration) {
      result = intern.createPatternForElement(
        patternVariableDeclaration: variableOrExpression,
        intermediateVariables: intermediateVariables!,
        variables: variables,
        condition: condition,
        updates: updates,
        body: toElement(entry),
        fileOffset: offsetForToken(forToken),
      );
    } else {
      result = intern.createForElement(
        variables: variables,
        condition: condition,
        updates: updates,
        body: toElement(entry),
        fileOffset: offsetForToken(forToken),
      );
    }
    assignedVariables.endNode(result);
    push(result);
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
    InternalStatement body = popStatement(endToken);

    Token inKeyword = pop() as Token;
    Token forToken = pop() as Token;
    Token? awaitToken = pop(NullValues.AwaitToken) as Token?;

    // This is matched by the call to [beginNode] in [handleForInLoopParts].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo = assignedVariables
        .deferNode();

    InternalExpression expression = popForValue();
    Object? lvalue = pop();
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    InternalLoopStatement forInStatement = new InternalForInStatement(
      _computeForInElement(
        forToken: forToken,
        inToken: inKeyword,
        lvalue: lvalue,
      ),
      expression,
      body,
      isAsync: awaitToken != null,
      fileOffset: awaitToken?.charOffset ?? forToken.charOffset,
      bodyOffset: body.fileOffset,
    );
    if (breakTarget.hasUsers) {
      breakTarget.resolveBreaks(forInStatement);
    }
    if (continueTarget.hasUsers) {
      continueTarget.resolveContinues(forInStatement);
    }
    assignedVariables.storeInfo(forInStatement, assignedVariablesNodeInfo);
    exitLoopOrSwitch(forInStatement);
  }

  @override
  void endForInBody(Token endToken) {
    debugEvent("endForInBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
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

    InternalExpression iterable = popForValue();
    Object? lvalue = pop(); // lvalue
    exitLocalScope();

    InternalForInElement element = _computeForInElement(
      forToken: forToken,
      inToken: inToken,
      lvalue: lvalue,
    );
    assignedVariables.pushNode(assignedVariablesNodeInfo);
    ForInElement result = intern.createForInElement(
      element: element,
      iterable: iterable,
      body: toElement(entry),
      isAsync: awaitToken != null,
      fileOffset: awaitToken?.charOffset ?? forToken.charOffset,
      forOffset: forToken.charOffset,
    );
    assignedVariables.endNode(result);
    push(result);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression");
    InternalExpression expression = popForValue();
    exitLocalScope();
    push(expression);
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
    if (memberKind != MemberKind.PrimaryConstructor) {
      // The parser reports a special error for declaring parameters, so we
      // avoid emitting this error here for primary constructors.
      if (superKeyword != null &&
          varOrFinalOrConst != null &&
          varOrFinalOrConst.isA(Keyword.VAR)) {
        handleRecoverableError(
          diag.extraneousModifier.withArguments(lexeme: varOrFinalOrConst),
          varOrFinalOrConst,
          varOrFinalOrConst,
        );
      }
    }
    Modifiers modifiers = pop() as Modifiers;
    if (inCatchClause) {
      modifiers |= Modifiers.Final;
    }
    List<InternalExpression>? annotations = pop() as List<InternalExpression>?;
    if (nameNode is ParserRecovery) {
      push(nameNode);
      return;
    }
    Identifier? name = nameNode as Identifier?;

    FormalParameterBuilder? parameterBuilder;
    int nameOffset = offsetForToken(nameToken);
    if (!inCatchClause &&
        functionNestingLevel == 0 &&
        memberKind != MemberKind.GeneralizedFunctionType &&
        memberKind != MemberKind.AnonymousMethod) {
      parameterBuilder = _context.getFormalParameterByNameOffset(nameOffset);

      if (parameterBuilder == null) {
        // This happens when the list of formals (originally) contains a
        // ParserRecovery - then the popped list becomes null.
        push(new ParserRecovery(nameToken.charOffset));
        return;
      }
    } else {
      String parameterName = name?.name ?? '';
      bool isWildcard =
          libraryFeatures.wildcardVariables.isEnabled && parameterName == '_';
      int? wildcardIndex;
      if (isWildcard) {
        wildcardIndex = wildcardVariableIndex++;
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
      switch (memberKind) {
        case MemberKind.Catch:
          CatchParameterBuilder builder = new CatchParameterBuilder(
            modifiers: modifiers,
            type: type ?? const ImplicitTypeBuilder(),
            name: parameterName,
            fileOffset: nameOffset,
            nameOffset: nameOffset,
            fileUri: uri,
            wildcardIndex: wildcardIndex,
          );
          InternalCatchVariable catchVariable = builder.build(libraryBuilder);
          push(builder);
          assignedVariables.declare(catchVariable);
          return;
        case MemberKind.AnonymousMethod:
          AnonymousMethodParameterBuilder builder =
              new AnonymousMethodParameterBuilder(
                modifiers: modifiers,
                type: type ?? const ImplicitTypeBuilder(),
                name: parameterName,
                fileOffset: nameOffset,
                nameOffset: nameOffset,
                fileUri: uri,
                wildcardIndex: wildcardIndex,
                kind: kind,
              );
          InternalAnonymousMethodParameter anonymousMethodParameter = builder
              .build(libraryBuilder);
          push(builder);
          assignedVariables.declare(anonymousMethodParameter);
          return;
        default:
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
          parameterBuilder = new FormalParameterBuilder(
            kind: kind,
            modifiers: modifiers,
            type: type ?? const ImplicitTypeBuilder(),
            name: parameterName,
            fileOffset: nameOffset,
            nameOffset: nameOffset,
            fileUri: uri,
            hasImmediatelyDeclaredDefaultValue: initializerStart != null,
            wildcardIndex: wildcardIndex,
            publicName: publicName,
          );
      }
    }

    InternalFunctionParameter functionParameter = parameterBuilder.build(
      libraryBuilder,
    );
    InternalExpression? initializer = name?.initializer;
    if (initializer != null) {
      if (_context.isRedirectingFactory) {
        addProblem(
          diag.defaultValueInRedirectingFactoryConstructor.withArguments(
            redirectionTarget: _context.redirectingFactoryTargetName,
          ),
          initializer.fileOffset,
          noLength,
        );
        functionParameter.hasErroneousDefaultValue = true;
      } else {
        if (!parameterBuilder.defaultValueWasInferred) {
          functionParameter.updateDefaultValue(initializer);
        }
      }
    } else if (kind.isOptional) {
      if (functionParameter.defaultValue == null) {
        functionParameter.updateDefaultValue(
          intern.createNullLiteral(noLocation),
        );
      }
    }
    if (annotations != null) {
      _registerSingleTargetAnnotations(
        functionParameter.astVariable,
        annotations,
      );
    }

    push(parameterBuilder);
    // We pass `ignoreDuplicates: true` because the variable might have been
    // previously passed to `declare` in the `BodyBuilder` constructor.
    assignedVariables.declare(functionParameter, ignoreDuplicates: true);
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression");
    Object? defaultValueExpression = pop();
    constantContext = pop() as ConstantContext;
    push(defaultValueExpression);
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
          if (count > 0 && peek() is List<ParameterVariableBuilder>) ...[
            ValueKinds.ParameterList,
            ...repeatedKind(
              unionOfKinds([
                ValueKinds.FormalParameterBuilder,
                ValueKinds.CatchParameterBuilder,
                ValueKinds.AnonymousMethodParameterBuilder,
                ValueKinds.ParserRecovery,
              ]),
              count - 1,
            ),
          ] else
            ...repeatedKind(
              unionOfKinds([
                ValueKinds.FormalParameterBuilder,
                ValueKinds.CatchParameterBuilder,
                ValueKinds.AnonymousMethodParameterBuilder,
                ValueKinds.ParserRecovery,
              ]),
              count,
            ),
          /* inFormals */ ValueKinds.Bool,
          /* constantContext */ ValueKinds.ConstantContext,
        ]),
      );
      List<ParameterVariableBuilder>? optionals;
      int optionalsCount = 0;
      if (count > 0 && peek() is List<ParameterVariableBuilder>) {
        optionals = pop() as List<ParameterVariableBuilder>;
        count--;
        optionalsCount = optionals.length;
      }

      List<ParameterVariableBuilder>? parameters = _popParameterBuilders(
        kind: kind,
        count: count,
        optionalsCount: optionalsCount,
      );

      if (optionals != null && parameters != null) {
        parameters.setRange(count, count + optionalsCount, optionals);
      }
      assert(parameters?.isNotEmpty ?? true);
      Parameters formals;
      switch (kind) {
        case MemberKind.Catch:
          formals = new CatchParameters(
            parameters as List<CatchParameterBuilder>?,
            offsetForToken(beginToken),
            lengthOfSpan(beginToken, endToken),
            uri,
          );
        case MemberKind.AnonymousMethod:
          formals = new AnonymousMethodParameters(
            parameters as List<AnonymousMethodParameterBuilder>?,
            offsetForToken(beginToken),
            lengthOfSpan(beginToken, endToken),
            uri,
          );
        default:
          formals = new FormalParameters(
            parameters as List<FormalParameterBuilder>?,
            offsetForToken(beginToken),
            lengthOfSpan(beginToken, endToken),
            uri,
          );
      }
      inFormals = pop() as bool;
      constantContext = pop() as ConstantContext;
      push(formals);
      if ((inCatchClause ||
              functionNestingLevel != 0 ||
              kind == MemberKind.AnonymousMethod) &&
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
    InternalStatement body = popStatement(endToken);

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

    List<InternalExpression> updates = popListForEffect(updateExpressionCount);
    InternalStatement conditionStatement = popStatement(forKeyword);
    // This is matched by the call to [beginNode] in
    // [handleForInitializerEmptyStatement],
    // [handleForInitializerPatternVariableAssignment],
    // [handleForInitializerExpressionStatement], and
    // [handleForInitializerLocalVariableDeclaration].
    AssignedVariablesNodeInfo assignedVariablesNodeInfo = assignedVariables
        .deferNode();

    Object? variableOrExpression = pop();
    List<InternalVariableDeclaration>? variables;
    List<InternalVariableDeclaration>? intermediateVariableDeclarations;
    if (variableOrExpression is InternalPatternVariableDeclaration) {
      variables =
          pop() as List<InternalVariableDeclaration>; // Internal variables.
      intermediateVariableDeclarations =
          pop() as List<InternalVariableDeclaration>;
    } else {
      variables = _buildForLoopVariableDeclarations(variableOrExpression);
    }
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget() as JumpTarget;
    JumpTarget breakTarget = exitBreakTarget() as JumpTarget;
    InternalExpression? condition;
    if (conditionStatement is InternalExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is InternalEmptyStatement);
    }
    InternalLoopStatement forStatement = intern.createForStatement(
      offsetForToken(forKeyword),
      variables,
      condition,
      updates,
      body,
    );
    if (breakTarget.hasUsers) {
      breakTarget.resolveBreaks(forStatement);
    }
    if (continueTarget.hasUsers) {
      continueTarget.resolveContinues(forStatement);
    }
    assignedVariables.storeInfo(forStatement, assignedVariablesNodeInfo);
    InternalStatement result = forStatement;
    if (variableOrExpression is InternalPatternVariableDeclaration) {
      result = intern.createBlock(
        fileOffset: result.fileOffset,
        fileEndOffset: result.fileOffset,
        [
          variableOrExpression,
          for (InternalVariableDeclaration intermediateVariableDeclaration
              in intermediateVariableDeclarations!)
            intern.createVariableStatement(intermediateVariableDeclaration),
          result,
        ],
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
  void endForStatementBody(Token endToken) {
    debugEvent("endForStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void endFunctionExpression(Token beginToken, Token endToken) {
    debugEvent("FunctionExpression");
    assert(
      checkState(beginToken, [
        /* body */ ValueKinds.StatementOrNull,
        /* async marker */ ValueKinds.AsyncModifier,
        /* formal parameters */ ValueKinds.FormalParameters,
        /* inCatchBlock */ ValueKinds.Bool,
        /* nominal parameters */ ValueKinds.NominalVariableListOrNull,
      ]),
    );
    InternalStatement body =
        popNullableStatement() ??
        // In erroneous cases, there might not be function body. In such cases
        // we use an empty statement instead.
        // TODO(jensj): Is this the offset we want?
        intern.createEmptyStatement(endToken.next!.charOffset);
    AsyncModifier asyncModifier = pop() as AsyncModifier;
    exitLocalScope();
    FormalParameters formals = pop() as FormalParameters;
    exitFunction();
    List<NominalParameterBuilder>? typeParameters =
        pop() as List<NominalParameterBuilder>?;
    InternalFunctionNode function = formals.buildFunctionNode(
      libraryBuilder: libraryBuilder,
      returnTypeBuilder: null,
      typeParameterBuilders: typeParameters,
      asyncModifier: asyncModifier,
      body: body,
      fileOffset: beginToken.charOffset,
      // TODO(jensj): Is this the offset we want?
      fileEndOffset: endToken.next!.charOffset,
    );

    InternalExpression result;
    if (constantContext != ConstantContext.none) {
      result = buildProblem(
        message: diag.notAConstantExpression,
        fileUri: uri,
        fileOffset: formals.charOffset,
        length: formals.length,
      );
    } else {
      result = intern.createFunctionExpression(
        function: function,
        fileOffset: offsetForToken(beginToken),
      );
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
    InternalLocalFunctionVariable variable = intern.createLocalFunctionVariable(
      name: identifierName,
      type: null,
      forSyntheticToken: nameToken.isSynthetic,
      isWildcard: isWildcard,
      fileOffset: name.nameOffset,
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
      assert(!variable.hasInitializer);
      InternalInvalidExpression? error = declareVariable(variable, scope);
      if (error != null) {
        push(
          intern.createExpressionStatement(
            error,
            fileOffset: beginToken.charOffset,
          ),
        );
        return;
      }
    }
    push(
      intern.createFunctionDeclaration(
        variable: variable,
        fileOffset: beginToken.charOffset,
      ),
    );
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
  void endIfControlFlow(Token token) {
    debugEvent("endIfControlFlow");
    assert(
      checkState(token, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Element,
        ]),
        ValueKinds.Condition,
        ValueKinds.Token,
      ]),
    );

    Object? entry = pop();
    Condition condition = pop() as Condition;
    exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifElement]);
    Token ifToken = pop() as Token;

    InternalPatternGuard? patternGuard = condition.patternGuard;
    InternalElement node;
    if (patternGuard == null) {
      node = intern.createIfElement(
        condition: condition.expression,
        then: toElement(entry),
        otherwise: null,
        fileOffset: offsetForToken(ifToken),
      );
    } else {
      node = intern.createIfCaseElement(
        expression: condition.expression,
        patternGuard: patternGuard,
        then: toElement(entry),
        otherwise: null,
        fileOffset: offsetForToken(ifToken),
      );
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
          ValueKinds.Element,
        ]),
        /* then element */ unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Element,
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

    InternalPatternGuard? patternGuard = condition.patternGuard;
    InternalElement node;
    if (patternGuard == null) {
      node = intern.createIfElement(
        condition: condition.expression,
        then: toElement(thenEntry),
        otherwise: toElement(elseEntry),
        fileOffset: offsetForToken(ifToken),
      );
    } else {
      node = intern.createIfCaseElement(
        expression: condition.expression,
        patternGuard: patternGuard,
        then: toElement(thenEntry),
        otherwise: toElement(elseEntry),
        fileOffset: offsetForToken(ifToken),
      );
    }
    push(node);
    // This is matched by the call to [deferNode] in
    // [handleElseControlFlow].
    assignedVariables.storeInfo(node, assignedVariablesInfo);
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
    InternalStatement? elsePart = popStatementIfNotNull(elseToken);
    AssignedVariablesNodeInfo assignedVariablesInfo =
        pop() as AssignedVariablesNodeInfo;
    InternalStatement thenPart = popStatement(ifToken);
    Condition condition = pop() as Condition;
    InternalPatternGuard? patternGuard = condition.patternGuard;
    InternalExpression expression = condition.expression;
    InternalStatement node;
    if (patternGuard != null) {
      node = intern.createIfCaseStatement(
        ifToken.charOffset,
        expression,
        patternGuard,
        thenPart,
        elsePart,
      );
    } else {
      node = intern.createIfStatement(
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
  void endInitializedIdentifier(Token nameToken) {
    // TODO(ahe): Use [InitializedIdentifier] here?
    debugEvent("InitializedIdentifier");
    Object? node = pop();
    if (node is ParserRecovery) {
      push(node);
      return;
    }
    InternalVariableDeclaration declaration =
        node as InternalVariableDeclaration;
    push(declaration);

    // Avoid adding the local identifier to scope if it's a wildcard.
    // TODO(kallentu): Emit better error on lookup, rather than not adding it to
    // the scope.
    if (!(libraryFeatures.wildcardVariables.isEnabled &&
        declaration.variable.isWildcard)) {
      InternalInvalidExpression? error = declareVariable(
        declaration.variable,
        _localScope,
        declaration.initializer,
      );
      if (error != null) {
        declaration.updateInitializer(error);
      }
    }
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
    List<InternalInitializer> initializers;

    if (!_context.isConstructor || _context.isExternalConstructor) {
      // An error has been reported by the parser.
      initializers = <InternalInitializer>[];
    } else if (node is InternalInitializer) {
      initializers = <InternalInitializer>[node];
    } else if (node is Generator) {
      initializers = node.buildFieldInitializer(initializedFields);
    } else if (node is InternalConstructorInvocation) {
      // Coverage-ignore-block(suite): Not run.
      initializers = [
        // TODO(jensj): Does this offset make sense?
        buildSuperInitializer(
          false,
          node.target,
          node.arguments,
          endToken.next!.charOffset,
        ),
      ];
    } else {
      InternalExpression value = toValue(node);
      if (value is! InternalInvalidExpression) {
        // TODO(johnniwinther): Derive the message position from the [node]
        // and not the [value].  For instance this occurs for `super()?.foo()`
        // in an initializer list, pointing to `foo` as expecting an
        // initializer.
        value = intern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.expectedAnInitializer,
            fileUri: uri,
            fileOffset: value.fileOffset,
            length: noLength,
          ),
          expression: value,
        );
      }
      initializers = [intern.createInvalidInitializer(value)];
    }

    _initializers.addAll(initializers);
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
  void endIsOperatorType(Token operator) {
    _isOrAsOperatorTypeState = _isOrAsOperatorTypeState.tail!;
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");
    InternalStatement statement = popStatementNoWrap();
    LabelTarget target = pop() as LabelTarget;
    _labelScopes.pop();
    if (target.breakTarget.hasUsers || target.continueTarget.hasUsers) {
      if (statement is MultiVariableDeclaration) {
        internalProblem(
          diag.internalProblemLabelUsageInVariablesDeclaration,
          statement.fileOffset,
          uri,
        );
      }
      if (statement is! InternalLabeledStatement) {
        // We avoid nested labeled statements by only inserting one if
        // [statement] isn't already a labeled statement. This helps simplify
        // the handling of labeled continue statements, which should redirect
        // to the loop enclosed by the label statement(s).
        statement = intern.createLabeledStatement(statement);
      }
      target.breakTarget.resolveBreaks(statement);
      if (target.continueTarget.hasUsers) {
        InternalStatement labelStatementBody = statement.body;
        if (labelStatementBody is InternalLoopStatement) {
          // Continue statements targeting this label redirect to the loop.
          target.continueTarget.resolveContinues(labelStatementBody);
        } else {
          push(
            buildProblemStatement(
              diag.continueLabelInvalid,
              target.continueTarget.users.first.fileOffset,
              length: 8,
            ),
          );
          return;
        }
      }
    }
    push(statement);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop() as Token;
      String value = unescapeString(token.lexeme, token, this);
      push(intern.createStringLiteral(offsetForToken(token), value));
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
      List<InternalExpression> expressions = <InternalExpression>[];
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
            intern.createStringLiteral(offsetForToken(first), value),
          );
        }
      }
      for (int i = 1; i < parts.length - 1; i++) {
        Object part = parts[i];
        if (part is Token) {
          if (part.lexeme.length != 0) {
            String value = unescape(part.lexeme, quote, part, this);
            expressions.add(
              intern.createStringLiteral(offsetForToken(part), value),
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
            intern.createStringLiteral(offsetForToken(last), value),
          );
        }
      }
      push(
        intern.createStringConcatenation(offsetForToken(first), expressions),
      );
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
          intern.createSymbolLiteral(
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
      push(intern.createSymbolLiteral(offsetForToken(hashToken), value));
    }
  }

  @override
  void endLocalFunctionDeclaration(Token token) {
    debugEvent("LocalFunctionDeclaration");
    pushNamedFunction(token, false);
  }

  @override
  void endMember() {
    debugEvent("Member");
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
        InternalExpression value = toValue(expression);
        push(
          intern.createInvalidExpressionFromErrorText(
            problemReporting.buildProblem(
              compilerContext: compilerContext,
              message: diag.expressionNotMetadata,
              fileUri: uri,
              fileOffset: value.fileOffset,
              length: noLength,
              errorHasBeenReported: value is InternalInvalidExpression,
            ),
            expression: value,
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
        const GrowableList<InternalExpression>().popNonNullable(
              stack,
              count,
              dummyInternalExpression,
            ) ??
            NullValues.Metadata /* Ignore parser recovery */,
      );
    }
    assert(checkState(null, [ValueKinds.AnnotationListOrNull]));
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    debugEvent("NamedFunctionExpression");
    pushNamedFunction(endToken, true);
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
      List<ParameterBuilder>? parameters = _popParameterBuilders(
        kind: kind,
        count: count,
        optionalsCount: 0,
      );
      if (parameters == null) {
        push(new ParserRecovery(offsetForToken(beginToken)));
      } else {
        push(parameters);
      }
    }
  }

  @override
  void endParenthesizedExpression(Token token) {
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    debugEvent("ParenthesizedExpression");
    InternalExpression value = popForValue();
    if (value is LargeIntLiteral) {
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
      if (pattern is InternalPattern) {
        for (InternalDeclaredVariable variable in pattern.declaredVariables) {
          assert(!variable.hasInitializer);
          declareVariable(variable, _localScope);
        }
      }
    }

    push(pattern);
  }

  @override
  void endPatternGuard(Token token) {
    debugEvent("PatternGuard");
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
    List<Object?>? elements = const FixedNullableList<Object?>().pop(
      stack,
      count,
    );

    List<RecordField> fields = [];
    int positionalCount = 0;
    Map<String, NamedRecordField>? namedFields;
    const List<String> forbiddenObjectMemberNames = [
      "noSuchMethod",
      "toString",
      "hashCode",
      "runtimeType",
    ];
    if (elements != null) {
      for (Object? element in elements) {
        if (element is InternalNamedExpression) {
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
          namedFields ??= {};
          NamedRecordField? existingExpression = namedFields[element.name];
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
            );
          } else {
            NamedRecordField field = new NamedRecordField(
              name: element.name,
              value: element.value,
              fileOffset: element.fileOffset,
            );
            namedFields[element.name] = field;
            fields.add(field);
          }
        } else {
          InternalExpression expression = toValue(element);
          fields.add(
            new PositionalRecordField(
              value: expression,
              fileOffset: expression.fileOffset,
            ),
          );
          positionalCount++;
        }
      }
      if (namedFields != null) {
        for (NamedRecordField element in namedFields.values) {
          if (tryParseRecordPositionalGetterName(
                element.name,
                positionalCount,
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
        fields: fields,
        namedFields: namedFields,
        isConst:
            constKeyword != null || constantContext == ConstantContext.inferred,
        fileOffset: token.offset,
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
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement");
    if (inCatchBlock) {
      push(
        intern.createRethrowStatement(
          offsetForToken(rethrowToken),
          offsetForToken(endToken),
        ),
      );
    } else {
      push(
        intern.createExpressionStatement(
          buildProblem(
            message: diag.rethrowNotCatch,
            fileUri: uri,
            fileOffset: offsetForToken(rethrowToken),
            length: lengthForToken(rethrowToken),
          ),
          fileOffset: offsetForToken(rethrowToken),
        ),
      );
    }
  }

  @override
  void endReturnStatement(
    bool hasExpression,
    Token beginToken,
    Token? endToken,
  ) {
    debugEvent("ReturnStatement");
    InternalExpression? expression = hasExpression ? popForValue() : null;
    if (expression != null &&
        inConstructor &&
        _parameterlessAnonymousMethodDepth == 0) {
      push(
        buildProblemStatement(
          diag.constructorWithReturnType,
          beginToken.charOffset,
        ),
      );
    } else {
      push(
        intern.createReturnStatement(
          fileOffset: offsetForToken(beginToken),
          expression: expression,
          isArrow: !identical(beginToken.lexeme, "return"),
        ),
      );
    }
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
    List<InternalSwitchCase> cases = new List.filled(
      caseCount,
      dummyInternalSwitchCase,
      growable: true,
    );
    for (int i = caseCount - 1; i >= 0; i--) {
      List<Label>? labels = pop() as List<Label>?;
      InternalSwitchCase current = cases[i] = pop() as InternalSwitchCase;
      if (labels != null) {
        for (Label label in labels) {
          JumpTarget? target = _switchScope!.lookupLabel(label.name);
          if (target != null) {
            target.resolveGotos(current);
          }
        }
      }
      if (current is InternalPatternSwitchCase) {
        containsPatterns = true;
      }
    }
    for (int i = 0; i < caseCount - 1; i++) {
      InternalSwitchCase current = cases[i];
      InternalBlock block = current.body as InternalBlock;
      // [block] is a synthetic block that is added to handle variable
      // declarations in the switch case.
      InternalNode? lastNode = block.statements.isEmpty
          ? null
          : block.statements.last;
      if (lastNode is InternalBlock) {
        // This is a non-synthetic block.
        InternalBlock block = lastNode;
        lastNode = block.statements.isEmpty ? null : block.statements.last;
      }
      if (lastNode is InternalExpressionStatement) {
        InternalExpressionStatement statement = lastNode;
        lastNode = statement.expression;
      }
    }

    push(containsPatterns);
    push(cases);
    assert(
      checkState(beginToken, [ValueKinds.SwitchCaseList, ValueKinds.Bool]),
    );
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
        ValueKinds.InternalDeclaredVariableListOrNull,
        ValueKinds.InternalDeclaredVariableListOrNull,
        ValueKinds.InternalDeclaredVariableListOrNull,
        ValueKinds.LabelListOrNull,
        ValueKinds.Bool,
        ValueKinds.ExpressionOrPatternGuardCaseList,
      ]),
    );

    // We always create a block here so that we later know that there's always
    // one synthetic block when we finish compiling the switch statement and
    // check this switch case to see if it falls through to the next case.
    InternalStatement block = popBlock(statementCount, beginToken, null);
    exitLocalScope(expectedScopeKinds: const [LocalScopeKind.switchCaseBody]);
    List<InternalDeclaredVariable>? jointPatternVariables =
        pop() as List<InternalDeclaredVariable>?;
    List<InternalDeclaredVariable>?
    jointPatternVariablesWithMismatchingFinality =
        pop() as List<InternalDeclaredVariable>?;
    List<InternalDeclaredVariable>? jointPatternVariablesNotInAll =
        pop() as List<InternalDeclaredVariable>?;

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

    List<InternalDeclaredVariable>? usedJointPatternVariables;
    List<int>? jointVariableFirstUseOffsets;
    if (jointPatternVariables != null) {
      usedJointPatternVariables = [];
      Map<InternalVariable, int> firstUseOffsets = {};
      for (InternalDeclaredVariable variable in jointPatternVariables) {
        if (usedNamesOffsets?[variable.cosmeticName!] case [int offset, ...]) {
          usedJointPatternVariables.add(variable);
          firstUseOffsets[variable] = offset;
        }
      }
      if (jointPatternVariablesWithMismatchingFinality != null ||
          jointPatternVariablesNotInAll != null ||
          hasDefaultOrLabels) {
        for (InternalVariable jointVariable in usedJointPatternVariables) {
          if (jointPatternVariablesWithMismatchingFinality?.contains(
                jointVariable,
              ) ??
              false) {
            String jointVariableName = jointVariable.cosmeticName!;
            addProblem(
              diag.jointPatternVariablesMismatch.withArguments(
                variableName: jointVariableName,
              ),
              firstUseOffsets[jointVariable]!,
              jointVariableName.length,
            );
          }
          if (jointPatternVariablesNotInAll?.contains(jointVariable) ?? false) {
            String jointVariableName = jointVariable.cosmeticName!;
            addProblem(
              diag.jointPatternVariableNotInAll.withArguments(
                variableName: jointVariableName,
              ),
              firstUseOffsets[jointVariable]!,
              jointVariableName.length,
            );
          }
          if (hasDefaultOrLabels) {
            String jointVariableName = jointVariable.cosmeticName!;
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
        for (InternalVariable variable in usedJointPatternVariables)
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
      InternalPatternGuard? patternGuard =
          expressionsOrPatternGuards.first.patternGuard;
      if (patternGuard != null) {
        InternalPattern pattern = patternGuard.pattern;
        for (InternalDeclaredVariable variable in pattern.declaredVariables) {
          String variableName = variable.cosmeticName!;
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
      List<InternalPatternGuard> patternGuards = [];
      for (ExpressionOrPatternGuardCase expressionOrPatternGuard
          in expressionsOrPatternGuards) {
        caseOffsets.add(expressionOrPatternGuard.caseOffset);
        if (expressionOrPatternGuard.patternGuard != null) {
          patternGuards.add(expressionOrPatternGuard.patternGuard!);
        } else {
          patternGuards.add(
            intern.createPatternGuard(
              expressionOrPatternGuard.caseOffset,
              toPattern(expressionOrPatternGuard.expression!),
            ),
          );
        }
      }
      push(
        intern.createPatternSwitchCase(
          beginToken.charOffset,
          caseOffsets,
          patternGuards,
          block,
          isDefault: defaultKeyword != null,
          labels: labels,
          jointVariables: usedJointPatternVariables,
          jointVariableFirstUseOffsets: jointVariableFirstUseOffsets,
        ),
      );
    } else {
      List<InternalExpression> expressions = <InternalExpression>[];
      List<int> caseOffsets = [];
      List<int> expressionOffsets = <int>[];
      for (ExpressionOrPatternGuardCase expressionOrPatternGuard
          in expressionsOrPatternGuards) {
        InternalExpression expression = expressionOrPatternGuard.expression!;
        expressions.add(expression);
        caseOffsets.add(expressionOrPatternGuard.caseOffset);
        expressionOffsets.add(expression.fileOffset);
      }
      push(
        intern.createSwitchStatementCase(
          caseOffsets: caseOffsets,
          expressions: expressions,
          expressionOffsets: expressionOffsets,
          body: block,
          isDefault: defaultKeyword != null,
          labels: labels,
          fileOffset: beginToken.charOffset,
        ),
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
  void endSwitchExpression(Token switchKeyword, Token endToken) {
    debugEvent("endSwitchExpression");
    assert(
      checkState(switchKeyword, [
        ValueKinds.SwitchExpressionCaseList,
        ValueKinds.Condition,
      ]),
    );

    List<InternalSwitchExpressionCase> cases =
        pop() as List<InternalSwitchExpressionCase>;
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in switch expression: ${condition.patternGuard}.",
    );
    InternalExpression expression = condition.expression;
    push(
      intern.createSwitchExpression(
        switchKeyword.charOffset,
        expression,
        cases,
      ),
    );
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
    List<InternalSwitchExpressionCase> cases = new List.filled(
      caseCount,
      dummyInternalSwitchExpressionCase,
    );
    for (int i = caseCount - 1; i >= 0; i--) {
      cases[i] = pop() as InternalSwitchExpressionCase;
    }
    push(cases);
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

    InternalExpression expression = popForValue();
    InternalExpression? guard;
    if (when != null) {
      guard = popForValue();
    }
    Object? value = pop();
    exitLocalScope();
    InternalPatternGuard patternGuard = intern.createPatternGuard(
      arrow.charOffset,
      toPattern(value),
      guard,
    );
    push(
      intern.createSwitchExpressionCase(
        arrow.charOffset,
        patternGuard,
        expression,
      ),
    );
    assert(checkState(arrow, [ValueKinds.SwitchExpressionCase]));
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");
    assert(
      checkState(switchKeyword, [
        /* cases = */ ValueKinds.SwitchCaseList,
        /* containsPatterns */ ValueKinds.Bool,
        /* break target = */ ValueKinds.BreakTarget,
        /* expression = */ ValueKinds.Condition,
      ]),
    );
    List<InternalSwitchCase> cases = pop() as List<InternalSwitchCase>;
    bool containsPatterns = pop() as bool;
    JumpTarget target = exitBreakTarget()!;
    exitSwitchScope();
    exitLocalScope();
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in switch statement: ${condition.patternGuard}.",
    );
    InternalExpression expression = condition.expression;
    InternalSwitchStatement switchStatement;
    if (containsPatterns || libraryFeatures.patterns.isEnabled) {
      // If patterns are enabled, we always use the pattern switch encoding.
      // Otherwise, we use pattern switch encoding to handle the erroneous case
      // of an unsupported use of patterns.
      List<InternalPatternSwitchCase> patternSwitchCases =
          new List<InternalPatternSwitchCase>.generate(cases.length, (
            int index,
          ) {
            InternalSwitchCase switchCase = cases[index];
            InternalPatternSwitchCase patternSwitchCase;
            switch (switchCase) {
              case InternalPatternSwitchCase():
                patternSwitchCase = switchCase;
              // Coverage-ignore(suite): Not run.
              case InternalSwitchStatementCase():
                List<InternalPatternGuard> patterns = new List.generate(
                  switchCase.expressions.length,
                  (int index) {
                    return intern.createPatternGuard(
                      switchCase.expressions[index].fileOffset,
                      intern.createConstantPattern(
                        switchCase.expressions[index],
                      ),
                    );
                  },
                );
                patternSwitchCase = intern.createPatternSwitchCase(
                  switchCase.fileOffset,
                  switchCase.caseOffsets,
                  patterns,
                  switchCase.body,
                  isDefault: switchCase.isDefault,
                  labels: switchCase.labels,
                  jointVariables: [],
                  jointVariableFirstUseOffsets: null,
                );
            }

            return patternSwitchCase;
          });
      switchStatement = intern.createPatternSwitchStatement(
        switchKeyword.charOffset,
        expression,
        patternSwitchCases,
      );
    } else {
      switchStatement = intern.createSwitchStatement(expression, [
        for (InternalSwitchCase case_ in cases)
          case_ as InternalSwitchStatementCase,
      ], fileOffset: switchKeyword.charOffset);
    }
    if (target.hasUsers) {
      target.resolveBreaks(switchStatement);
    }
    exitLoopOrSwitch(switchStatement);
    // This is matched by the [beginNode] call in [beginSwitchBlock].
    assignedVariables.endNode(switchStatement);
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
  void endTopLevelFields(
    Token? augmentToken,
    Token? abstractToken,
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
  void endTryStatement(
    int catchCount,
    Token tryKeyword,
    Token? finallyKeyword,
    Token endToken,
  ) {
    InternalStatement? finallyBlock;
    if (finallyKeyword != null) {
      finallyBlock = pop() as InternalStatement;
    } else {
      // This is matched by the call to [beginNode] in [beginTryStatement].
      tryStatementInfoStack = tryStatementInfoStack.prepend(
        assignedVariables.deferNode(),
      );
    }
    List<InternalCatch>? catchBlocks;
    List<InternalStatement>? compileTimeErrors;
    if (catchCount != 0) {
      List<Object?> catchBlocksAndErrors = const FixedNullableList<Object?>()
          .pop(stack, catchCount * 2)!;
      catchBlocks = new List<InternalCatch>.filled(
        catchCount,
        dummyInternalCatch,
        growable: true,
      );
      for (int i = 0; i < catchCount; i++) {
        catchBlocks[i] = catchBlocksAndErrors[i * 2] as InternalCatch;
        InternalStatement? error =
            catchBlocksAndErrors[i * 2 + 1] as InternalStatement?;
        if (error != null) {
          compileTimeErrors ??= <InternalStatement>[];
          compileTimeErrors.add(error);
        }
      }
    }
    InternalStatement tryBlock = popStatement(tryKeyword);
    int fileOffset = offsetForToken(tryKeyword);
    InternalStatement result = intern.createTryStatement(
      fileOffset,
      tryBlock,
      catchBlocks,
      finallyBlock,
    );
    assignedVariables.storeInfo(result, tryStatementInfoStack.head);
    tryStatementInfoStack = tryStatementInfoStack.tail!;

    if (compileTimeErrors != null) {
      compileTimeErrors.add(result);
      push(
        intern.createBlock(
          fileOffset: noLocation,
          fileEndOffset: noLocation,
          compileTimeErrors,
        ),
      );
    } else {
      push(result);
    }
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
  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    AssignedVariablesNodeInfo? assignedVariablesInfo;
    bool isLate = currentLocalVariableModifiers.isLate;
    InternalExpression initializer = popForValue();
    if (isLate) {
      assignedVariablesInfo = assignedVariables.deferNode(
        isClosureOrLateVariableInitializer: true,
      );
    }
    pushNewLocalVariable(initializer, equalsToken: assignmentOperator);
    if (isLate) {
      InternalVariableDeclaration node = peek() as InternalVariableDeclaration;
      // This is matched by the call to [beginNode] in
      // [beginVariableInitializer].

      assignedVariables.storeInfo(node.variable, assignedVariablesInfo!);
    }
  }

  @override
  void endVariablesDeclaration(int count, Token? endToken) {
    debugEvent("VariablesDeclaration");
    if (count == 1) {
      Object? node = pop();
      constantContext = pop() as ConstantContext;
      currentLocalVariableType = pop(NullValues.Type) as DartType?;
      currentLocalVariableModifiers = pop() as Modifiers;
      List<InternalExpression>? annotations =
          pop() as List<InternalExpression>?;
      if (node is ParserRecovery) {
        push(node);
        return;
      }
      InternalVariableDeclaration declaration =
          node as InternalVariableDeclaration;
      if (annotations != null) {
        _registerSingleTargetAnnotations(
          declaration.variable.astVariable,
          annotations,
        );
      }
      // TODO(johnniwinther): Should [VariableStatement] use offset from
      //  [endToken]?
      push(intern.createVariableStatement(declaration));
    } else {
      List<InternalVariableDeclaration>? variables =
          const FixedNullableList<InternalVariableDeclaration>().popNonNullable(
            stack,
            count,
            dummyInternalVariableDeclaration,
          );
      constantContext = pop() as ConstantContext;
      currentLocalVariableType = pop(NullValues.Type) as DartType?;
      currentLocalVariableModifiers = pop() as Modifiers;
      List<InternalExpression>? annotations =
          pop() as List<InternalExpression>?;
      if (variables == null) {
        push(new ParserRecovery(offsetForToken(endToken)));
        return;
      }
      if (annotations != null) {
        _registerMultiTargetAnnotations(
          variables.map((v) => v.variable.astVariable).toList(),
          annotations,
        );
      }
      push(
        intern.createMultiVariableDeclaration(
          variables,
          fileOffset: TreeNode.noOffset,
        ),
      );
    }
    _exitLocalState();
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
    InternalStatement body = popStatement(whileKeyword);
    Condition condition = pop() as Condition;
    assert(
      condition.patternGuard == null,
      "Unexpected pattern in while statement: ${condition.patternGuard}.",
    );
    InternalExpression expression = condition.expression;
    JumpTarget continueTarget = exitContinueTarget()!;
    JumpTarget breakTarget = exitBreakTarget()!;
    InternalLoopStatement whileStatement = intern.createWhileStatement(
      offsetForToken(whileKeyword),
      expression,
      body,
    );
    if (breakTarget.hasUsers) {
      breakTarget.resolveBreaks(whileStatement);
    }
    if (continueTarget.hasUsers) {
      continueTarget.resolveContinues(whileStatement);
    }
    // This is matched by the [beginNode] call in [beginWhileStatement].
    assignedVariables.endNode(whileStatement);
    exitLoopOrSwitch(whileStatement);
  }

  @override
  void endWhileStatementBody(Token endToken) {
    debugEvent("endWhileStatementBody");
    Object? body = pop();
    exitLocalScope();
    push(body);
  }

  @override
  void endYieldStatement(Token yieldToken, Token? starToken, Token endToken) {
    debugEvent("YieldStatement");
    push(
      intern.createYieldStatement(
        offsetForToken(yieldToken),
        popForValue(),
        isYieldStar: starToken != null,
      ),
    );
  }

  void enterBreakTarget(int charOffset, [JumpTarget? target]) {
    push(breakTarget ?? NullValues.BreakTarget);
    breakTarget = target ?? createBreakTarget(charOffset);
  }

  void enterContinueTarget(int charOffset, [JumpTarget? target]) {
    push(continueTarget ?? NullValues.ContinueTarget);
    continueTarget = target ?? createContinueTarget(charOffset);
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

  void enterLocalScope(LocalScope localScope) {
    _localScopes.push(localScope);
    _labelScopes.push(new LabelScopeImpl(_labelScope));
  }

  void enterLoop(int charOffset) {
    enterBreakTarget(charOffset);
    enterContinueTarget(charOffset);
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

  void enterSwitchScope() {
    _switchScopes.push(_labelScope);
  }

  @override
  InternalExpression evaluateArgumentsBefore(
    ActualArguments? arguments,
    InternalExpression expression,
  ) {
    if (arguments == null) return expression;
    for (Argument argument in arguments.argumentList.reversed) {
      expression = intern.createLetForEffect(
        effect: argument.expression,
        // TODO(johnniwinther): Should we use `void` instead?
        effectType: coreTypes.objectRawType(Nullability.nullable),
        expression: expression,
      );
    }
    return expression;
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

  void exitLoopOrSwitch(InternalStatement statement) {
    if (problemInLoopOrSwitch != null) {
      push(problemInLoopOrSwitch);
      problemInLoopOrSwitch = null;
    } else {
      push(statement);
    }
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
          for (InternalGotoStatement statement in declaration.users) {
            statement.error = buildProblem(
              message: diag.labelNotFound.withArguments(label: name),
              fileUri: uri,
              fileOffset: statement.fileOffset,
              length: name.length,
            );
          }
        } else {
          outerSwitchScope.forwardDeclareLabel(name, declaration);
        }
      });
    }
    _switchScopes.pop();
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
      return intern.createExpressionInvocation(
        charOffset,
        toValue(receiver),
        typeArguments,
        arguments,
      );
    }
  }

  @override
  void handleAdjacentStringLiterals(Token startToken, int literalCount) {
    debugEvent("AdjacentStringLiterals");
    List<InternalExpression> parts = popListForValue(literalCount);
    List<InternalExpression>? expressions;
    // Flatten string juxtapositions of string interpolation.
    for (int i = 0; i < parts.length; i++) {
      InternalExpression part = parts[i];
      if (part is InternalStringConcatenation) {
        if (expressions == null) {
          expressions = parts.sublist(0, i);
        }
        for (InternalExpression expression in part.expressions) {
          expressions.add(expression);
        }
      } else {
        if (expressions != null) {
          expressions.add(part);
        }
      }
    }
    push(
      intern.createStringConcatenation(
        offsetForToken(startToken),
        expressions ?? parts,
      ),
    );
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
    InternalExpression expression = popForValue();
    InternalExpression asExpression = intern.createAsExpression(
      offsetForToken(operator),
      expression,
      type,
    );
    push(asExpression);
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
    Generator generator = scopeLookup(_localScope, variable);
    push(generator.buildPatternAssignment(variable));
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
    InternalExpression value = popForValue();
    Object? generator = pop();
    if (generator is! Generator) {
      push(
        buildProblem(
          message: diag.notAnLvalue,
          fileUri: uri,
          fileOffset: offsetForToken(token),
          length: lengthForToken(token),
          errorHasBeenReported: generator is InternalInvalidExpression,
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

  @override
  void handleAsyncModifier(Token? asyncToken, Token? starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
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
      InternalBreakStatement statement = intern.createBreakStatement(
        offsetForToken(breakKeyword),
        identifier?.name,
      );
      target.addBreak(statement);
      push(statement);
    }
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
    InternalPattern operand = toPattern(pop());
    push(intern.createCastPattern(operator.charOffset, operand, type));
  }

  @override
  void handleCatchBlock(Token? onKeyword, Token? catchKeyword, Token? comma) {
    debugEvent("CatchBlock");
    InternalStatement body = pop() as InternalStatement;
    inCatchBlock = pop() as bool;
    if (catchKeyword != null) {
      exitLocalScope();
    }
    CatchParameters? catchParameters =
        popIfNotNull(catchKeyword) as CatchParameters?;
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
    CatchParameterBuilder? exception;
    CatchParameterBuilder? stackTrace;
    List<InternalStatement>? compileTimeErrors;
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
            CatchParameterBuilder parameter = catchParameters.parameters![i];
            compileTimeErrors ??= <InternalStatement>[];
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
    push(
      intern.createCatch(
        offsetForToken(onKeyword ?? catchKeyword),
        exceptionType,
        exception?.variable,
        stackTrace?.variable,
        coreTypes.stackTraceRawType(Nullability.nonNullable),
        body,
      ),
    );
    if (compileTimeErrors == null) {
      push(NullValues.Block);
    } else {
      push(
        intern.createBlock(
          fileOffset: noLocation,
          fileEndOffset: noLocation,
          compileTimeErrors,
        ),
      );
    }
  }

  @override
  void handleConditionalExpressionColon() {
    InternalExpression then = popForValue();
    // This is matched by the call to [beginNode] in
    // [beginConditionalExpression] and by the call to [storeInfo] in
    // [endConditionalExpression].
    push(assignedVariables.deferNode());
    push(then);
    super.handleConditionalExpressionColon();
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
        InternalContinueSwitchStatement statement = intern
            .createContinueSwitchStatement(
              fileOffset: continueKeyword.charOffset,
            );
        target.addGoto(statement);
        push(statement);
        return;
      }
    }
    if (target == null) {
      push(
        problemInLoopOrSwitch = buildProblemStatement(
          _switchScope != null
              ? diag.continueWithoutLabelInCase
              : diag.continueOutsideOfLoop,
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
      InternalContinueStatement statement = intern.createContinueStatement(
        offsetForToken(continueKeyword),
        identifier?.name,
      );
      target.addContinue(statement);
      push(statement);
    }
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
    InternalPattern pattern;
    if (inAssignmentPattern) {
      // Error has already been reported.
      pattern = intern.createInvalidPattern(
        intern.createInvalidExpression(
          'declared variable pattern in assignment',
          fileOffset: variable.charOffset,
        ),
        declaredVariables: const [],
      );
    } else {
      InternalDeclaredVariable declaredVariable = intern.createLocalVariable(
        fileOffset: variable.charOffset,
        name: variable.lexeme,
        type: patternType,
        isFinal: Modifiers.from(varFinalOrConst: keyword).isFinal,
      );
      pattern = intern.createVariablePattern(
        variable.charOffset,
        patternType,
        declaredVariable,
      );
      assert(!declaredVariable.hasInitializer);
      declareVariable(declaredVariable, _localScope);
      assignedVariables.declare(declaredVariable);
    }
    push(pattern);
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
    InternalExpression value = popForValue();
    push(intern.createDotShorthandContext(token.charOffset, value));
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
        intern.createDotShorthandInvocation(
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
        intern.createDotShorthandPropertyGet(
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
  void handleElseControlFlow(Token elseToken) {
    assert(
      checkState(elseToken, [
        unionOfKinds([
          ValueKinds.Expression,
          ValueKinds.Generator,
          ValueKinds.Element,
        ]),
        ValueKinds.Condition,
      ]),
    );
    // Resolve the top of the stack so that if it's a delayed assignment it
    // happens before we go into the else block.
    Object then = toElement(pop());
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
  void handleEmptyFunctionBody(Token semicolon) {
    debugEvent("ExpressionFunctionBody");
    endBlockFunctionBody(0, null, semicolon);
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement");
    push(intern.createEmptyStatement(offsetForToken(token)));
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token? endToken) {
    debugEvent("ExpressionFunctionBody");
    endReturnStatement(true, arrowToken.next!, endToken);
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
      intern.createExpressionStatement(
        fileOffset: offsetForToken(endToken),
        popForEffect(),
      ),
    );
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock");
    // Do nothing, handled by [endTryStatement].
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
      if (declaration case InternalVariableStatement(
        declaration: InternalVariableDeclaration(:InternalVariable variable),
      )) {
        variable.isStaticLate = false;
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

    if (pattern is InternalPattern) {
      pop(); // Metadata.
      for (InternalDeclaredVariable variable in pattern.declaredVariables) {
        assert(!variable.hasInitializer);
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
      List<InternalVariableDeclaration> intermediateVariableDeclarations = [];
      List<InternalVariableDeclaration> internalVariableDeclarations = [];
      for (InternalDeclaredVariable variable in pattern.declaredVariables) {
        variable.isFinal |= isFinal;

        // TODO(johnniwinther): Can we avoid creating synthetic variables here?
        InternalDeclaredVariable intermediateVariable = intern
            .createSyntheticVariable(
              isFinal: true,
              fileOffset: variable.fileOffset,
            );
        intermediateVariableDeclarations.add(
          intern.createVariableDeclaration(
            intermediateVariable,
            initializer: intern.createVariableGet(
              variable,
              fileOffset: variable.fileOffset,
            ),
          ),
        );

        InternalDeclaredVariable internalVariable = intern
            .createSyntheticVariable(
              name: variable.cosmeticName!,
              fileOffset: variable.fileOffset,
              isFinal: isFinal,
              isSynthesized: false,
            );
        internalVariableDeclarations.add(
          intern.createVariableDeclaration(
            internalVariable,
            initializer: intern.createVariableGet(
              intermediateVariable,
              fileOffset: variable.fileOffset,
            ),
          ),
        );

        declareVariable(internalVariable, _localScope);
        assignedVariables.declare(internalVariable);
      }
      push(intermediateVariableDeclarations);
      push(internalVariableDeclarations);
      push(
        intern.createPatternVariableDeclaration(
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
          ValueKinds
              .Statement, // VariableDeclaration for non-pattern for-in loop.
          ValueKinds.ParserRecovery,
        ]),
      ]),
    );
    Object expression = pop() as Object;
    Object pattern = pop() as Object;

    if (pattern is InternalPattern) {
      pop(); // Metadata.
      bool isFinal = patternKeyword?.lexeme == 'final';
      for (InternalDeclaredVariable variable in pattern.declaredVariables) {
        variable.isFinal |= isFinal;
        assert(!variable.hasInitializer);
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
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
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
  void handleImplicitFormalParameters(Token punctuation) {
    debugEvent("handleImplicitFormalParameters");
    // If `variable` is captured in a nested function literal, dart2js
    // requires the variable to have a name. It is sufficient to use
    // `anonymous#this` because no user-written variable can have that name,
    // and we never have access to more than one of these variables. It does
    // not disrupt other backends that this name exists.
    InternalAnonymousMethodParameter variable = intern
        .createAnonymousMethodParameter(
          fileOffset: offsetForToken(punctuation),
          name: "anonymous#this",
          type: const DynamicType(),
          isImplicitlyTyped: true,
          isFinal: true,
          isSynthesized: true,
          isWildcard: false,
        );
    _thisVariables.push(variable);
    _parameterlessAnonymousMethodDepth++;

    assignedVariables.declare(variable);
    push(NullValues.FormalParameters);
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
    InternalExpression index = popForValue();
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
    } else if (receiver is InternalExpression) {
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
      assert(receiver is InternalInitializer);
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
  void handleInvalidFunctionBody(Token token) {
    if (_context.isNativeMethod) {
      // Coverage-ignore-block(suite): Not run.
      push(NullValues.FunctionBody);
    } else {
      push(
        intern.createBlock(
          fileOffset: offsetForToken(token),
          fileEndOffset: noLocation,
          <InternalStatement>[
            buildProblemStatement(
              diag.expectedFunctionBody.withArguments(lexeme: token),
              token.charOffset,
              length: token.length,
            ),
          ],
        ),
      );
    }
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    InternalStatement statement = pop() as InternalStatement;
    push(
      intern.createExpressionStatement(
        buildProblem(
          message: message,
          fileUri: uri,
          fileOffset: statement.fileOffset,
          length: noLength,
        ),
        fileOffset: statement.fileOffset,
      ),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValues.TypeArguments);
  }

  @override
  void handleIsOperator(Token isOperator, Token? not) {
    debugEvent("IsOperator");
    DartType type = buildDartType(
      pop() as TypeBuilder,
      TypeUse.isType,
      allowPotentiallyConstantType: true,
    );
    InternalExpression operand = popForValue();
    InternalExpression isExpression = intern.createIsExpression(
      offsetForToken(isOperator),
      operand,
      type,
      notFileOffset: not != null ? offsetForToken(not) : null,
    );
    push(isExpression);
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label");
    Identifier identifier = pop() as Identifier;
    push(new Label(identifier.name, identifier.nameOffset));
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

    List<InternalPattern> patterns = new List<InternalPattern>.filled(
      count,
      dummyInternalPattern,
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
      intern.createListPattern(leftBracket.charOffset, typeArgument, patterns),
    );
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = boolFromToken(token);
    push(intern.createBoolLiteral(value, fileOffset: offsetForToken(token)));
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(
      intern.createDoubleLiteral(
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
    push(intern.createDoubleLiteral(offsetForToken(token), value));
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    int? value = intFromToken(token, hasSeparators: false);
    // Postpone parsing of literals resulting in a negative value
    // (hex literals >= 2^63). These are only allowed when not negated.
    if (value == null || value < 0) {
      push(
        intern.createIntLiteralLarge(
          offsetForToken(token),
          token.lexeme,
          token.lexeme,
        ),
      );
    } else {
      push(
        intern.createIntLiteral(
          fileOffset: offsetForToken(token),
          value: value,
          literal: token.lexeme,
        ),
      );
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
        intern.createIntLiteralLarge(
          offsetForToken(token),
          source,
          token.lexeme,
        ),
      );
    } else {
      push(
        intern.createIntLiteral(
          fileOffset: offsetForToken(token),
          value: value,
          literal: token.lexeme,
        ),
      );
    }
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
          unionOfKinds([
            ValueKinds.Generator,
            ValueKinds.Expression,
            ValueKinds.Element,
          ]),
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
    List<InternalElement> elements = popListForElement(count);

    List<TypeBuilder>? typeArguments = pop() as List<TypeBuilder>?;

    DartType? typeArgument;
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
    }

    InternalExpression node = intern.createListLiteral(
      // TODO(johnniwinther): The file offset computed below will not be
      // correct if there are type arguments but no `const` keyword.
      fileOffset: offsetForToken(constKeyword ?? leftBracket),
      typeArgument: typeArgument,
      elements: elements,
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
    InternalExpression value = popForValue();
    InternalExpression key = popForValue();
    if ((nullAwareKeyToken != null || nullAwareValueToken != null) &&
        !libraryFeatures.nullAwareElements.isEnabled) {
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
      intern.createMapEntryElement(
        isKeyNullAware: nullAwareKeyToken != null,
        key: key,
        isValueNullAware: nullAwareValueToken != null,
        value: value,
        fileOffset: offsetForToken(colon),
      ),
    );
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(intern.createNullLiteral(offsetForToken(token)));
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
            ValueKinds.Element,
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
    List<InternalElement> elements = popListForElement(count);
    List<TypeBuilder>? typeArgumentBuilders = pop() as List<TypeBuilder>?;

    List<DartType>? typeArguments;
    if (typeArgumentBuilders != null) {
      typeArguments = [];
      for (TypeBuilder typeBuilder in typeArgumentBuilders) {
        typeArguments.add(
          instantiateToBounds(
            buildDartType(
              typeBuilder,
              TypeUse.literalTypeArgument,
              allowPotentiallyConstantType: false,
            ),
            coreTypes.objectClass,
          ),
        );
      }
    }

    if (typeArguments != null && typeArguments.length > 2) {
      // An error has been reported in the parser.
      typeArguments = [const InvalidType(), const InvalidType()];
    }
    InternalExpression node = intern.createMapOrSetLiteral(
      typeArguments: typeArguments,
      elements: elements,
      isConst:
          constKeyword != null || constantContext == ConstantContext.inferred,
      // TODO(johnniwinther): The file offset computed below will not be
      // correct if there are type arguments but no `const` keyword.
      fileOffset: offsetForToken(constKeyword ?? leftBrace),
    );
    push(node);
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
    List<InternalMapPatternEntry> entries = <InternalMapPatternEntry>[];
    for (int i = 0; i < count; i++) {
      Object? entry = pop();
      if (entry is InternalMapPatternEntry) {
        entries.add(entry);
      } else {
        entry as InternalRestPattern;
        entries.add(intern.createMapPatternRestEntry(entry.fileOffset));
      }
    }

    for (int i = 0, j = entries.length - 1; i < j; i++, j--) {
      InternalMapPatternEntry entry = entries[i];
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
      intern.createMapPattern(
        leftBrace.charOffset,
        keyType,
        valueType,
        entries,
      ),
    );
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
    InternalPattern value = toPattern(pop());
    InternalExpression key = toValue(pop());
    push(intern.createMapPatternEntry(colon.charOffset, key, value));
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
    InternalExpression value = popForValue();
    Object? identifier = pop();
    if (identifier is Identifier) {
      push(
        new NamedArgument(
          intern.createNamedExpression(
            identifier.name,
            value,
            fileOffset: identifier.nameOffset,
          ),
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
  void handleNamedRecordField(Token colon) {
    debugEvent("handleNamedRecordField");
    assert(
      checkState(colon, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
        unionOfKinds([ValueKinds.Identifier, ValueKinds.ParserRecovery]),
      ]),
    );
    InternalExpression value = popForValue();
    Object? identifier = pop();
    if (identifier is Identifier) {
      push(
        intern.createNamedExpression(
          identifier.name,
          value,
          fileOffset: identifier.nameOffset,
        ),
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
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      pop() as InternalStringLiteral;
    }
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
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    constantContext = _context.constantContext;
    if (constantContext == ConstantContext.inferred) {
      // Creating a null value to prevent the Dart VM from crashing.
      push(intern.createNullLiteral(offsetForToken(token)));
    } else {
      push(NullValues.FieldInitializer);
    }
    constantContext = ConstantContext.none;
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
    InternalExpression operand = popForValue();
    push(intern.createNullCheck(offsetForToken(bang), operand));
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
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
    bool isConst = currentLocalVariableModifiers.isConst;
    InternalExpression? initializer;
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
    InternalPattern operand = toPattern(pop());
    push(intern.createNullAssertPattern(bang.charOffset, operand));
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
    InternalExpression expression = popForValue(); // InternalExpression.
    push(
      intern.createNullAwareElement(
        expression: expression,
        fileOffset: offsetForToken(nullAwareElement),
      ),
    );
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
    InternalPattern operand = toPattern(pop());
    push(intern.createNullCheckPattern(question.charOffset, operand));
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
        ValueKinds.NamedPatternListOrNull,
        ValueKinds.TypeArgumentsOrNull,
      ]),
    );

    reportIfNotEnabled(
      libraryFeatures.patterns,
      firstIdentifier.charOffset,
      firstIdentifier.charCount,
    );

    List<InternalNamedPattern>? fields = pop() as List<InternalNamedPattern>?;
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
      intern.createObjectPattern(
        requiredType: type,
        fields: fields ?? [],
        typedef: typeDeclaration is TypeAliasBuilder
            ? typeDeclaration.typedef
            : null,
        hasExplicitTypeArguments: typeArguments != null,
        fileOffset: firstIdentifier.charOffset,
      ),
    );
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
    List<InternalNamedPattern>? fields;
    for (int i = 0; i < count; i++) {
      Object? field = pop();
      if (field is InternalNamedPattern) {
        (fields ??= []).add(field);
      } else {
        InternalPattern pattern = toPattern(field);
        if (pattern is! InternalInvalidPattern) {
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
        InternalNamedPattern field = fields[i];
        fields[i] = fields[j];
        fields[j] = field;
      }
    }
    push(fields ?? NullValues.PatternList);
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator");
    push(new Operator(token, token.charOffset));
  }

  @override
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    debugEvent("ParenthesizedCondition");
    if (case_ != null) {
      InternalExpression? guard;
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
      InternalPattern pattern = toPattern(pop());
      InternalExpression expression = popForValue();
      push(
        new Condition(
          expression,
          intern.createPatternGuard(expression.fileOffset, pattern, guard),
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
    if (value is InternalPattern) {
      push(value);
    } else {
      push(toValue(value));
    }
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
    InternalExpression expression = popForValue();
    InternalPattern pattern = toPattern(pop());
    push(
      intern.createPatternAssignment(equals.charOffset, pattern, expression),
    );
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
    InternalPattern pattern = toPattern(value);
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
            intern.createInvalidPattern(
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
          push(intern.createNamedPattern(colon.charOffset, name, pattern));
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
    InternalExpression initializer = popForValue();
    InternalPattern pattern = toPattern(pop());
    bool isFinal = keyword.lexeme == 'final';
    for (InternalDeclaredVariable variable in pattern.declaredVariables) {
      variable.isFinal = isFinal;
      variable.hasDeclaredInitializer = true;
      assert(!variable.hasInitializer);
      declareVariable(variable, _localScope);
    }
    // TODO(johnniwinther,cstefantsova): Handle metadata.
    pop(NullValues.Metadata) as List<InternalExpression>?;
    push(
      intern.createPatternVariableDeclaration(
        keyword.charOffset,
        pattern,
        initializer,
        isFinal: isFinal,
      ),
    );
  }

  @override
  void handlePositionalArgument(Token token) {
    debugEvent("NamedArgument");
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    InternalExpression value = popForValue();
    push(new PositionalArgument(value));
  }

  @override
  void handlePositionalRecordField(Token token) {
    debugEvent("handlePositionalRecordField");
    assert(
      checkState(token, [
        unionOfKinds([ValueKinds.Expression, ValueKinds.Generator]),
      ]),
    );
    InternalExpression value = popForValue();
    push(value);
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

    List<InternalPattern> patterns = new List<InternalPattern>.filled(
      count,
      dummyInternalPattern,
    );
    for (int i = count - 1; i >= 0; i--) {
      patterns[i] = toPattern(pop());
    }
    push(intern.createRecordPattern(token.charOffset, patterns));
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
    InternalExpression operand = toValue(pop());
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
    push(intern.createRelationalPattern(token.charOffset, kind, operand));
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

    InternalPattern? subPattern;
    if (hasSubPattern) {
      subPattern = toPattern(pop());
    }
    push(intern.createRestPattern(dots.charOffset, subPattern));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void handleScript(Token token) {
    debugEvent("Script");
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
  void handleSpreadExpression(Token spreadToken) {
    debugEvent("SpreadExpression");
    Object? expression = pop();
    push(
      intern.createSpreadElement(
        expression: toValue(expression),
        isNullAware: spreadToken.lexeme == '...?',
        fileOffset: offsetForToken(spreadToken),
      ),
    );
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("handleStringPart");
    push(token);
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
    if (pattern is InternalPattern) {
      for (InternalDeclaredVariable variable in pattern.declaredVariables) {
        assert(!variable.hasInitializer);
        declareVariable(variable, _localScope);
      }
    }
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
    if (pattern is InternalPattern) {
      for (InternalDeclaredVariable variable in pattern.declaredVariables) {
        assert(!variable.hasInitializer);
        declareVariable(variable, _localScope);
      }
    }
    push(pattern);
  }

  @override
  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(new SimpleIdentifier(token));
  }

  @override
  void handleThenControlFlow(Token token) {
    assert(checkState(token, [ValueKinds.Condition]));
    // This is matched by the call to [deferNode] in
    // [handleElseControlFlow] and by the call to [endNode] in
    // [endIfControlFlow].
    assignedVariables.beginNode();

    Condition condition = pop() as Condition;
    InternalPatternGuard? patternGuard = condition.patternGuard;
    if (patternGuard != null) {
      if (patternGuard.guard != null) {
        LocalScope thenScope = _localScope.createNestedScope(
          kind: LocalScopeKind.ifElement,
        );
        exitLocalScope(expectedScopeKinds: const [LocalScopeKind.ifCaseHead]);
        enterLocalScope(thenScope);
      } else {
        createAndEnterLocalScope(kind: LocalScopeKind.ifCaseHead);
        InternalPattern pattern = patternGuard.pattern;
        for (InternalDeclaredVariable variable in pattern.declaredVariables) {
          assert(!variable.hasInitializer);
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
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    if (context.isScopeReference &&
        (isDeclarationInstanceContext ||
            _thisVariables.currentOrNull != null)) {
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
        bool inParameterlessAnonymousMethod =
            _parameterlessAnonymousMethodDepth > 0;
        push(
          new ThisAccessGenerator(
            this,
            token,
            inInitializerLeftHandSide,
            inFieldInitializer && !inParameterlessAnonymousMethod,
            inLateFieldInitializer && !inParameterlessAnonymousMethod,
          ),
        );
      }
    } else {
      push(new IncompleteErrorGenerator(this, token, diag.thisAsIdentifier));
    }
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    InternalExpression expression = popForValue();
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
      push(intern.createThrow(offsetForToken(throwToken), expression));
    }
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
      } else if (operand is InternalStaticTearOff &&
              (operand.target.isFactory || isTearOffLowering(operand.target)) ||
          operand is InternalConstructorTearOff ||
          operand is InternalRedirectingFactoryTearOff) {
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
          intern.createInstantiation(
            toValue(operand),
            buildDartTypeArguments(
              typeArguments,
              TypeUse.tearOffTypeArgument,
              allowPotentiallyConstantType: true,
            ),
            fileOffset: openAngleBracket.charOffset,
          ),
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
      InternalExpression value = toValue(generator);
      push(
        intern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.notAnLvalue,
            fileUri: uri,
            fileOffset: value.fileOffset,
            length: noLength,
            errorHasBeenReported: value is InternalInvalidExpression,
          ),
          expression: value,
        ),
      );
    }
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
      InternalExpression value = toValue(generator);
      push(
        intern.createInvalidExpressionFromErrorText(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.notAnLvalue,
            fileUri: uri,
            fileOffset: value.fileOffset,
            length: noLength,
            errorHasBeenReported: value is InternalInvalidExpression,
          ),
          expression: value,
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
      push(intern.createNot(offsetForToken(token), toValue(receiver)));
    } else {
      String operator = token.stringValue!;
      if (token.isA(TokenType.MINUS)) {
        operator = "unary-";
      }
      int fileOffset = offsetForToken(token);
      Name name = new Name(operator);
      if (receiver is Generator) {
        push(receiver.buildUnaryOperation(token, name));
      } else if (receiver is InternalExpression) {
        push(intern.createUnary(fileOffset, name, receiver));
      } else {
        // Coverage-ignore-block(suite): Not run.
        InternalExpression value = toValue(receiver);
        push(intern.createUnary(fileOffset, name, value));
      }
    }
  }

  @override
  void handleValuedFormalParameter(
    Token equals,
    Token token,
    FormalParameterKind kind,
  ) {
    debugEvent("ValuedFormalParameter");
    InternalExpression initializer = popForValue();
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

    push(intern.createWildcardPattern(wildcard.charOffset, patternType));
  }

  Name incrementOperator(Token token) {
    if (token.isA(TokenType.PLUS_PLUS)) return plusName;
    if (token.isA(TokenType.MINUS_MINUS)) return minusName;
    return unhandled(token.lexeme, "incrementOperator", token.charOffset, uri);
  }

  @override
  bool isDeclaredInEnclosingCase(InternalVariable variable) {
    return declaredInCurrentGuard?.contains(variable) ?? false;
  }

  bool isGuardScope(LocalScope scope) =>
      scope.kind == LocalScopeKind.caseHead ||
      scope.kind == LocalScopeKind.ifCaseHead;

  @override
  bool isIdentical(Member? member) => member == coreTypes.identicalProcedure;

  @override
  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  ) {
    return _context.lookupSuperConstructor(name, accessingLibrary);
  }

  @override
  Member? lookupSuperMember(Name name, {bool isSetter = false}) {
    return _context.lookupSuperMember(hierarchy, name, isSetter: isSetter);
  }

  InternalExpression parseAnnotation(Token token) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    Token endToken = parser.parseMetadata(parser.syntheticPreviousToken(token));
    assert(checkState(token, [ValueKinds.Expression]));
    InternalExpression annotation = pop() as InternalExpression;
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

  List<InternalInitializer> parseInitializers(Token? token) {
    Parser parser = new Parser(
      this,
      useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
      experimentalFeatures: new LibraryExperimentalFeatures(libraryFeatures),
    );
    if (token != null) {
      token = parser.parseInitializers(token);
      checkEmpty(token.charOffset);
    } else {
      handleNoInitializers();
    }
    return _initializers;
  }

  InternalStatement popBlock(int count, Token openBrace, Token? closeBrace) {
    return intern.createBlock(
      const GrowableList<InternalStatement>().popNonNullable(
            stack,
            count,
            dummyInternalStatement,
          ) ??
          <InternalStatement>[],
      fileOffset: offsetForToken(openBrace),
      fileEndOffset: offsetForToken(closeBrace),
    );
  }

  InternalExpression popForEffect() => toEffect(pop());

  InternalExpression popForValue() => toValue(pop());

  InternalElement popForElement() => toElement(pop());

  InternalExpression? popForValueIfNotNull(Object? value) {
    return value == null ? null : popForValue();
  }

  List<InternalExpression> popListForEffect(int n) {
    List<InternalExpression> list = new List<InternalExpression>.filled(
      n,
      dummyInternalExpression,
      growable: true,
    );
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForEffect();
    }
    return list;
  }

  List<InternalExpression> popListForValue(int n) {
    List<InternalExpression> list = new List<InternalExpression>.filled(
      n,
      dummyInternalExpression,
      growable: true,
    );
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForValue();
    }
    return list;
  }

  List<InternalElement> popListForElement(int n) {
    List<InternalElement> list = new List<InternalElement>.filled(
      n,
      dummyInternalElement,
      growable: true,
    );
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForElement();
    }
    return list;
  }

  InternalStatement? popNullableStatement() {
    InternalStatement? statement = pop(NullValues.Block) as InternalStatement?;
    if (statement != null) {
      statement = intern.wrapVariables(statement);
    }
    return statement;
  }

  InternalStatement popStatement(Token token) {
    Object? element = pop();
    if (element is InternalStatement) {
      return intern.wrapVariables(element);
    } else {
      return _handleStatementNotStatement(element, token);
    }
  }

  InternalStatement? popStatementIfNotNull(Token? token) {
    return token == null ? null : popStatement(token);
  }

  InternalStatement popStatementNoWrap([Token? token]) {
    Object? element = pop();
    if (element is InternalStatement) {
      return element;
    } else {
      return _handleStatementNotStatement(element, token);
    }
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
      hasThisAccess = false;
      if (!isQualified) {
        if (_parameterlessAnonymousMethodDepth > 0) {
          hasThisAccess = true;
        } else if (isDeclarationInstanceContext && !inFormals) {
          hasThisAccess =
              !inFieldInitializer ||
              (inLateFieldInitializer &&
                  !_context.isExtensionDeclaration &&
                  !_context.isExtensionTypeDeclaration);
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
          isThisExplicit: false,
        );
      } else {
        // We're in an error state. In expression compilation there might be an
        // out though.
        lookupResult = _context.expressionEvaluationHelper
            // Coverage-ignore(suite): Not run.
            ?.additionalScopeLookup(name);

        if (lookupResult == null) {
          // [name] is unresolved.
          return new UnresolvedNameGenerator(
            this,
            nameToken,
            memberName,
            unresolvedReadKind: UnresolvedKind.Unknown,
          );
        }
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
            !_context.inPrimaryConstructorFieldInitializer &&
            !libraryFeatures.constFunctions.isEnabled) {
          return new IncompleteErrorGenerator(
            this,
            nameToken,
            diag.notAConstantExpression,
          );
        }
        InternalVariable variable = getable.variable;
        if (forStatementScope &&
            getable.isAssignable &&
            getable.isLate &&
            getable.isFinal) {
          return new ForInLateFinalVariableUseGenerator(
            this,
            nameToken,
            variable,
          );
        } else if (getable.isPrimaryConstructorParameter &&
            inConstructorInitializer) {
          return _createReadOnlyVariableAccess(
            variable,
            nameToken,
            nameOffset,
            name,
            ReadOnlyAccessKind.PrimaryConstructorParameter,
          );
        } else if (!getable.isAssignable ||
            (getable.isFinal && forStatementScope)) {
          return _createReadOnlyVariableAccess(
            variable,
            nameToken,
            nameOffset,
            name,
            getable.isConst
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
            isThisExplicit: false,
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
          isQualifiedAccess: false,
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
            isThisExplicit: false,
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
          isQualifiedAccess: false,
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
  void push(Object? node) {
    if (node is DartType) {
      unhandled("DartType", "push", -1, uri);
    }
    inInitializerLeftHandSide = false;
    super.push(node);
  }

  void pushNamedFunction(Token token, bool isFunctionExpression) {
    InternalStatement body = popStatement(token);
    AsyncModifier asyncModifier = pop() as AsyncModifier;
    exitLocalScope();
    FormalParameters formals = pop() as FormalParameters;
    Object? declaration = pop();
    TypeBuilder? returnType = pop() as TypeBuilder?;
    bool hasImplicitReturnType = returnType == null;
    exitFunction();
    List<NominalParameterBuilder>? typeParameters =
        pop() as List<NominalParameterBuilder>?;
    List<InternalExpression>? annotations;
    if (!isFunctionExpression) {
      annotations = pop() as List<InternalExpression>?; // Metadata.
    }
    InternalFunctionNode function = formals.buildFunctionNode(
      libraryBuilder: libraryBuilder,
      returnTypeBuilder: returnType,
      typeParameterBuilders: typeParameters,
      asyncModifier: asyncModifier,
      body: body,
      // TODO(johnniwinther): Shouldn't we provide the start offset here?
      fileOffset: TreeNode.noOffset,
      fileEndOffset: token.charOffset,
    );

    if (declaration is InternalFunctionDeclaration) {
      InternalVariable variable = declaration.variable;
      if (annotations != null) {
        _registerSingleTargetAnnotations(variable.astVariable, annotations);
      }
      declaration.hasImplicitReturnType = hasImplicitReturnType;
      if (!hasImplicitReturnType) {
        problemReporting.checkAsyncReturnType(
          libraryBuilder: libraryBuilder,
          typeEnvironment: typeEnvironment,
          asyncModifier: asyncModifier,
          returnType: function.returnType,
          returnTypeBuilder: returnType,
          fileUri: uri,
        );
      }

      variable.type = function.computeFunctionType();

      declaration.function = function;
      assert(!variable.hasInitializer);
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
          intern.createBlockExpression(
            intern.createBlock(
              fileOffset: declaration.fileOffset,
              fileEndOffset: noLocation,
              [declaration],
            ),
            buildProblem(
              message: diag.namedFunctionExpression,
              fileUri: uri,
              fileOffset: declaration.fileOffset,
              length: noLength,
              // Error has already been reported by the parser.
              errorHasBeenReported: true,
            ),
            fileOffset: declaration.fileOffset,
          ),
        );
      } else {
        push(declaration);
      }
    } else if (declaration is InternalExpressionStatement) {
      // For duplicate local functions generate an [ExpressionStatement] holding
      // the [InvalidExpression] for the error.
      push(declaration);
      assignedVariables.endNode(
        declaration,
        isClosureOrLateVariableInitializer: true,
      );
    } else {
      unhandled(
        "${declaration.runtimeType}",
        "pushNamedFunction",
        token.charOffset,
        uri,
      );
    }
  }

  void pushNewLocalVariable(
    InternalExpression? initializer, {
    Token? equalsToken,
  }) {
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
    assert(isConst == (constantContext == ConstantContext.inferred));
    String name = identifier.name;
    bool isWildcard =
        libraryFeatures.wildcardVariables.isEnabled && name == '_';
    if (isWildcard) {
      name = createWildcardVariableName(wildcardVariableIndex);
      wildcardVariableIndex++;
    }
    InternalVariableDeclaration variableDeclaration;
    InternalDeclaredVariable internalVariable;
    if (isLate) {
      assert(!isConst);
      internalVariable = intern.createLateVariable(
        name: name,
        type: currentLocalVariableType,
        isFinal: isFinal,
        isWildcard: isWildcard,
        hasDeclaredInitializer: initializer != null,
        isStaticLate: isFinal && initializer == null,
        forSyntheticToken: identifier.token.isSynthetic,
        isImplicitlyTyped: currentLocalVariableType == null,
        fileOffset: identifier.nameOffset,
        fileEqualsOffset: offsetForToken(equalsToken),
      );
    } else if (isConst) {
      internalVariable = intern.createConstVariable(
        name: name,
        type: currentLocalVariableType,
        isFinal: isFinal,
        isWildcard: isWildcard,
        hasDeclaredInitializer: initializer != null,
        forSyntheticToken: identifier.token.isSynthetic,
        isImplicitlyTyped: currentLocalVariableType == null,
        fileOffset: identifier.nameOffset,
        fileEqualsOffset: offsetForToken(equalsToken),
      );
    } else {
      internalVariable = intern.createLocalVariable(
        name: name,
        type: currentLocalVariableType,
        fileOffset: identifier.nameOffset,
        isFinal: isFinal,
        isWildcard: isWildcard,
        isStaticLate: isFinal && initializer == null,
        hasDeclaredInitializer: initializer != null,
        forSyntheticToken: identifier.token.isSynthetic,
        fileEqualsOffset: offsetForToken(equalsToken),
        isImplicitlyTyped: currentLocalVariableType == null,
      );
    }

    variableDeclaration = intern.createVariableDeclaration(
      internalVariable,
      initializer: initializer,
      nameOffset: identifier.nameOffset,
      equalsOffset: offsetForToken(equalsToken),
    );
    assignedVariables.declare(internalVariable);
    push(variableDeclaration);
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

  @override
  void readInternalThisVariable() {
    if (isClosureContextLoweringEnabled && _internalThisVariable != null) {
      assignedVariables.read(_internalThisVariable!);
    }
  }

  @override
  void registerVariableAssignment(InternalVariable variable) {
    // TODO(cstefantsova): Always pass [variable] to [assignedVariables.write]
    // when [InferenceVisitorBase.flowAnalysis] will use
    // [InternalExpressionVariable] instead of [ExpressionVariable] (that is,
    // pass it for the `VariableDeclaration` type parameter of [FlowAnalysis]).
    assignedVariables.write(variable);
  }

  @override
  void registerVariableRead(InternalVariable variable) {
    if (!variable.isLocalFunction && !variable.isWildcard) {
      assignedVariables.read(variable);
    }
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
          InternalExpression invocation;

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
  String superConstructorNameForDiagnostics(String name) {
    String className = _context.superClassName;
    return name.isEmpty ? className : "$className.$name";
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

  InternalExpression toEffect(Object? node) {
    if (node is Generator) return node.buildForEffect();
    return toValue(node);
  }

  InternalPattern toPattern(Object? node) {
    if (node is InternalPattern) {
      return node;
    } else if (node is Generator) {
      return intern.createConstantPattern(node.buildSimpleRead());
    } else if (node is InternalExpression) {
      return intern.createConstantPattern(node);
    } else {
      return unhandled("${node.runtimeType}", "toPattern", -1, uri);
    }
  }

  @override
  InternalExpression toValue(Object? node) {
    if (node is Generator) {
      return node.buildSimpleRead();
    } else if (node is InternalExpression) {
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

  InternalElement toElement(Object? node) {
    if (node is InternalElement) {
      return node;
    } else {
      return intern.createExpressionElement(toValue(node));
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

  @override
  InternalExpression wrapInDeferredCheck(
    InternalExpression expression,
    PrefixBuilder prefix,
    int charOffset,
  ) {
    return new DeferredCheck(
      dependency: prefix.dependency!,
      expression: expression,
      fileOffset: charOffset,
    );
  }

  InternalInvalidExpression wrapVariableInitializerInError(
    InternalVariable variable,
    InternalExpression? initializer,
    List<LocatedMessage> context,
  ) {
    String name = variable.cosmeticName!;
    int offset = variable.fileOffset;
    Message message = diag.duplicatedDeclaration.withArguments(name: name);
    if (initializer == null) {
      return buildProblem(
        message: message,
        fileUri: uri,
        fileOffset: offset,
        length: name.length,
        context: context,
      );
    } else {
      return intern.createInvalidExpressionFromErrorText(
        problemReporting.buildProblemFromLocatedMessage(
          compilerContext: compilerContext,
          message: message.withLocation(uri, offset, name.length),
          context: context,
        ),
        expression: initializer,
      );
    }
  }

  InternalExpression _buildConstructorInvocation(
    Member target,
    TypeArguments? typeArguments,
    ActualArguments arguments, {
    Constness constness = Constness.implicit,
    required TypeAliasBuilder? typeAliasBuilder,
    required int fileOffset,
    required int charLength,
    required bool hasInferredTypeArguments,
  }) {
    ErrorText? errorText = problemReporting.checkStaticArguments(
      compilerContext: compilerContext,
      target: target,
      explicitTypeArguments: typeArguments,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: uri,
    );
    if (errorText != null) {
      return intern.createInvalidExpressionFromErrorText(errorText);
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
      InternalExpression node;
      if (typeAliasBuilder == null) {
        node = intern.createConstructorInvocation(
          target: target,
          typeArguments: typeArguments,
          arguments: arguments,
          isConst: isConst,
          fileOffset: fileOffset,
        );
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
        node = intern.createTypeAliasedConstructorInvocation(
          typeAliasBuilder: typeAliasBuilder,
          target: target,
          typeArguments: typeArguments,
          arguments: arguments,
          isConst: isConst,
          fileOffset: fileOffset,
        );
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
      InternalExpression node;
      if (typeAliasBuilder == null) {
        FactoryConstructorInvocation factoryConstructorInvocation =
            new FactoryConstructorInvocation(
              target: target,
              typeArguments: typeArguments,
              arguments: arguments,
              isConst: isConst,
              fileOffset: fileOffset,
            );
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
        node = intern.createTypeAliasedFactoryInvocation(
          typeAliasBuilder: typeAliasBuilder,
          target: target,
          typeArguments: typeArguments,
          arguments: arguments,
          isConst: isConst,
          fileOffset: fileOffset,
        );
        // No type arguments were passed, so we need not check bounds.
        assert(typeArguments == null);
      }
      return node;
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
      arguments = intern.createArgumentsEmpty(offset);
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
    } else if (type is InternalInvalidExpression) {
      push(type);
    } else if (type is InternalExpression) {
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

  List<InternalVariableDeclaration>? _buildForLoopVariableDeclarations(
    variableOrExpression,
  ) {
    // TODO(ahe): This can be simplified now that we have the events
    // `handleForInitializer...` events.
    if (variableOrExpression is Generator) {
      variableOrExpression = variableOrExpression.buildForEffect();
    }
    if (variableOrExpression is InternalVariableStatement) {
      // TODO(johnniwinther): Avoid parsing variable declarations initializers
      //  in for statements as statements.
      InternalVariableDeclaration variableDeclaration =
          variableOrExpression.declaration;
      // Late for loop variables are not supported. An error has already been
      // reported by the parser.
      variableDeclaration.variable.isLate = false;
      return [variableDeclaration];
    } else if (variableOrExpression is InternalVariableDeclaration) {
      // Coverage-ignore-block(suite): Not run.
      // Late for loop variables are not supported. An error has already been
      // reported by the parser.
      variableOrExpression.variable.isLate = false;
      return [variableOrExpression];
    } else if (variableOrExpression is InternalExpression) {
      InternalSyntheticVariable variable = intern.createSyntheticVariable(
        isFinal: true,
        fileOffset: variableOrExpression.fileOffset,
      );
      return [
        intern.createVariableDeclaration(
          variable,
          initializer: variableOrExpression,
        ),
      ];
    } else if (variableOrExpression is InternalExpressionStatement) {
      // Coverage-ignore-block(suite): Not run.
      InternalExpression expression = variableOrExpression.expression;
      InternalSyntheticVariable variable = intern.createSyntheticVariable(
        isFinal: true,
        fileOffset: expression.fileOffset,
      );
      return [
        intern.createVariableDeclaration(variable, initializer: expression),
      ];
    } else if (variableOrExpression is MultiVariableDeclaration) {
      return variableOrExpression.declarations;
    } else if (variableOrExpression is List<Object>) {
      // Coverage-ignore-block(suite): Not run.
      List<InternalVariableDeclaration> variables = [];
      for (Object v in variableOrExpression) {
        variables.addAll(_buildForLoopVariableDeclarations(v)!);
      }
      return variables;
    } else if (variableOrExpression is InternalPatternVariableDeclaration) {
      // Coverage-ignore-block(suite): Not run.
      return [];
    } else if (variableOrExpression is ParserRecovery) {
      return [];
    } else if (variableOrExpression == null) {
      return [];
    }
    // Coverage-ignore(suite): Not run.
    assert(false, "Unexpected for statement initializer $variableOrExpression");
    return null;
  }

  InternalInvalidExpression _buildProblemFromLocatedMessage(
    LocatedMessage message,
  ) {
    return buildProblem(
      message: message.messageObject,
      fileUri: uri,
      fileOffset: message.charOffset,
      length: message.length,
    );
  }

  InternalForInElement _computeForInElement({
    required Token forToken,
    required Token inToken,
    required Object? lvalue,
  }) {
    if (lvalue is InternalVariableStatement) {
      // TODO(johnniwinther): Avoid parsing variable declarations in
      //  for-in statements as statements.
      InternalVariableDeclaration declaration = lvalue.declaration;
      // Variable initializers are not supported. An error has already been
      // reported by the parser.
      declaration.updateInitializer(null);
      declaration.variable.hasDeclaredInitializer = false;
      // Late for-in variables are not supported. An error has already been
      // reported by the parser.
      declaration.variable.isLate = false;
      InternalInvalidExpression? error;
      if (declaration.variable.isConst) {
        error = buildProblem(
          message: diag.forInLoopWithConstVariable,
          fileUri: uri,
          fileOffset: declaration.fileOffset,
          length: declaration.variable.cosmeticName!.length,
        );
        // As a recovery step, remove the const flag, to not confuse the
        // constant evaluator further in the pipeline.
        declaration.variable.isConst = false;
      }
      return new SingleVariableDeclarationForInElement(
        variableDeclaration: declaration,
        error: error,
      );
    } else if (lvalue is InternalVariableDeclaration) {
      // Coverage-ignore-block(suite): Not run.
      // Variable initializers are not supported. An error has already been
      // reported by the parser.
      lvalue.updateInitializer(null);
      lvalue.variable.hasDeclaredInitializer = false;
      // Late for-in variables are not supported. An error has already been
      // reported by the parser.
      lvalue.variable.isLate = false;
      InternalInvalidExpression? error;
      if (lvalue.variable.isConst) {
        error = buildProblem(
          message: diag.forInLoopWithConstVariable,
          fileUri: uri,
          fileOffset: lvalue.fileOffset,
          length: lvalue.variable.cosmeticName!.length,
        );
        // As a recovery step, remove the const flag, to not confuse the
        // constant evaluator further in the pipeline.
        lvalue.variable.isConst = false;
      }
      return new SingleVariableDeclarationForInElement(
        variableDeclaration: lvalue,
        error: error,
      );
    } else if (lvalue is Generator) {
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
      ///
      return lvalue.buildForInElement(inOffset: inToken.offset);
    } else if (lvalue is InternalPattern) {
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
      return new PatternForInElement(pattern: lvalue, inOffset: inToken.offset);
    } else if (lvalue is InternalInvalidExpression) {
      // Coverage-ignore-block(suite): Not run.
      return new InvalidForInElement(error: lvalue, inOffset: inToken.offset);
    } else if (lvalue is ParserRecovery) {
      return new InvalidForInElement(
        error: buildProblem(
          message: diag.syntheticToken,
          fileUri: uri,
          fileOffset: lvalue.charOffset,
          length: noLength,
        ),
        inOffset: inToken.offset,
      );
    } else if (lvalue is MultiVariableDeclaration) {
      Token token = forToken.next!.next!;
      InternalInvalidExpression error = buildProblem(
        message: diag.forInLoopExactlyOneVariable,
        fileUri: uri,
        fileOffset: offsetForToken(token),
        length: lengthForToken(token),
      );
      return new MultiVariableDeclarationForInElement(
        variableDeclarations: lvalue.declarations,
        error: error,
        fileOffset: lvalue.fileOffset,
      );
    } else {
      lvalue as InternalExpression;
      Token token = forToken.next!.next!;
      InternalInvalidExpression error = buildProblem(
        message: diag.forInLoopNotAssignable,
        fileUri: uri,
        fileOffset: offsetForToken(token),
        length: lengthForToken(token),
      );
      return new UnassignableForInElement(expression: lvalue, error: error);
    }
  }

  /// Helper method to create a [ReadOnlyAccessGenerator] on the [variable]
  /// using [token] and [charOffset] for offset information and [name]
  /// for `ExpressionGenerator._plainNameForRead`.
  ReadOnlyAccessGenerator _createReadOnlyVariableAccess(
    InternalVariable variable,
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

  /// Sets up the local scope for a field initializer.
  ///
  /// For non-late instance fields the scope includes primary constructor
  /// parameter.
  void _enterFieldInitializerScope() {
    if (_context.inPrimaryConstructorFieldInitializer) {
      inConstructorInitializer = true;
      LocalScope enclosingScope = _localScope;
      List<FormalParameterBuilder>? parameters =
          _context.primaryConstructorInitializerScopeParameters;
      if (parameters != null) {
        Map<String, VariableBuilder> local = {};
        for (FormalParameterBuilder formal in parameters) {
          assignedVariables.declare(formal.variable);
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
  }

  void _enterLocalState({bool inLateLocalInitializer = false}) {
    _localInitializerState = _localInitializerState.prepend(
      inLateLocalInitializer,
    );
  }

  /// Pop the locals scope set up in [_enterFieldInitializerScope].
  void _exitFieldInitializerScope() {
    if (_context.inPrimaryConstructorFieldInitializer) {
      _localScopes.pop();
      inConstructorInitializer = false;
    }
  }

  void _exitLocalState() {
    _localInitializerState = _localInitializerState.tail!;
  }

  InternalStatement _handleStatementNotStatement(
    Object? element,
    Token? token,
  ) {
    if (element is ParserRecovery) {
      return intern.createBlock(
        [
          intern.createExpressionStatement(
            fileOffset: element.charOffset,
            ParserErrorGenerator.buildProblemExpression(
              this,
              diag.syntheticToken,
              element.charOffset,
            ),
          ),
        ],
        fileOffset: element.charOffset,
        fileEndOffset: element.charOffset,
      );
    } else {
      unhandled(
        "expected statement is ${element.runtimeType}: $element",
        "popStatement",
        token?.charOffset ?? -1,
        uri,
      );
    }
  }

  InternalExpression _parseInitializer(Token token) {
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
    InternalExpression expression = popForValue();
    checkEmpty(endToken.charOffset);
    return expression;
  }

  List<ParameterVariableBuilder>? _popParameterBuilders({
    required MemberKind kind,
    required int count,
    required int optionalsCount,
  }) {
    switch (kind) {
      case MemberKind.Catch:
        return const FixedNullableList<CatchParameterBuilder>()
            .popPaddedNonNullable(
              stack,
              count,
              optionalsCount,
              dummyCatchParameterBuilder,
            );
      case MemberKind.AnonymousMethod:
        return const FixedNullableList<AnonymousMethodParameterBuilder>()
            .popPaddedNonNullable(
              stack,
              count,
              optionalsCount,
              dummyAnonymousMethodParameterBuilder,
            );
      default:
        return const FixedNullableList<FormalParameterBuilder>()
            .popPaddedNonNullable(
              stack,
              count,
              optionalsCount,
              dummyFormalParameterBuilder,
            );
    }
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
            List<InternalInitializer> initializers;
            if (_context.isExternalConstructor) {
              initializers = [
                intern.createInvalidInitializer(
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
                intern.createVariableGet(
                  formal.variable,
                  fileOffset: formal.fileOffset,
                ),
                formal: formal,
              );
            }
            _initializers.addAll(initializers);
          }
        }
      }
    }
  }

  void _registerMultiTargetAnnotations(
    List<Annotatable> targets,
    List<InternalExpression> annotations,
  ) {
    (_multiTargetAnnotations ??= []).add(
      new MultiTargetAnnotations(targets, annotations),
    );
  }

  void _registerSingleTargetAnnotations(
    Annotatable target,
    List<InternalExpression> annotations,
  ) {
    (_singleTargetAnnotations ??= []).add(
      new SingleTargetAnnotations(target, annotations),
    );
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
}
