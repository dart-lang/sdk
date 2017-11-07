// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.members;

import 'package:front_end/src/fasta/scanner.dart' show isUserDefinableOperator;

import '../common.dart';
import '../common/names.dart' show Selectors;
import '../common/resolution.dart' show Resolution;
import '../compile_time_constants.dart';
import '../constants/constructors.dart'
    show RedirectingFactoryConstantConstructor;
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
import '../elements/elements.dart';
import '../elements/entities.dart' show AsyncMarker;
import '../elements/modelx.dart'
    show
        ConstructorElementX,
        ErroneousElementX,
        FunctionElementX,
        JumpTargetX,
        LabelDefinitionX,
        LocalFunctionElementX,
        LocalParameterElementX,
        ParameterElementX,
        VariableElementX,
        VariableList;
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/operators.dart';
import '../elements/resolution_types.dart';
import '../options.dart';
import '../tree/tree.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/feature.dart' show Feature;
import '../universe/selector.dart' show Selector;
import '../universe/use.dart' show DynamicUse, StaticUse, TypeUse;
import '../util/util.dart' show Link;
import 'access_semantics.dart';
import 'class_members.dart' show MembersCreator;
import 'constructors.dart'
    show ConstructorResolver, ConstructorResult, ConstructorResultKind;
import 'label_scope.dart' show StatementScope;
import 'registry.dart' show ResolutionRegistry;
import 'resolution.dart' show ResolverTask;
import 'resolution_common.dart' show MappingVisitor;
import 'resolution_result.dart';
import 'scope.dart' show BlockScope, MethodScope, Scope;
import 'send_structure.dart';
import 'signatures.dart' show SignatureResolver;
import 'type_resolver.dart' show FunctionTypeParameterScope;
import 'variables.dart' show VariableDefinitionsVisitor;

/// The state of constants in resolutions.
enum ConstantState {
  /// Expressions are not required to be constants.
  NON_CONSTANT,

  /// Expressions are required to be constants.
  ///
  /// For instance the values of a constant list literal.
  CONSTANT,

  /// Expressions are required to be constants and parameter references are
  /// also considered constant.
  ///
  /// This is used for resolving constructor initializers of constant
  /// constructors.
  CONSTANT_INITIALIZER,
}

/**
 * Core implementation of resolution.
 *
 * Do not subclass or instantiate this class outside this library
 * except for testing.
 */
class ResolverVisitor extends MappingVisitor<ResolutionResult> {
  /**
   * The current enclosing element for the visited AST nodes.
   *
   * This field is updated when nested closures are visited.
   */
  Element enclosingElement;

  /// Whether we are in a context where `this` is accessible (this will be false
  /// in static contexts, factory methods, and field initializers).
  bool inInstanceContext;
  bool inCheckContext;
  bool inCatchParameters = false;
  bool inCatchBlock;
  ConstantState constantState;

  Scope scope;
  ClassElement currentClass;
  ExpressionStatement currentExpressionStatement;

  /// `true` if a [Send] or [SendSet] is visited as the prefix of member access.
  /// For instance `Class` in `Class.staticField` or `prefix.Class` in
  /// `prefix.Class.staticMethod()`.
  bool sendIsMemberAccess = false;

  StatementScope statementScope;
  int allowedCategory = ElementCategory.VARIABLE |
      ElementCategory.FUNCTION |
      ElementCategory.IMPLIES_TYPE;

  /// When visiting the type declaration of the variable in a [ForIn] loop,
  /// the initializer of the variable is implicit and we should not emit an
  /// error when verifying that all final variables are initialized.
  bool inLoopVariable = false;

  /// The nodes for which variable access and mutation must be registered in
  /// order to determine when the static type of variables types is promoted.
  Link<Node> promotionScope = const Link<Node>();

  bool isPotentiallyMutableTarget(Element target) {
    if (target == null) return false;
    return (target.isVariable || target.isRegularParameter) &&
        !(target.isFinal || target.isConst);
  }

  // TODO(ahe): Find a way to share this with runtime implementation.
  static final RegExp symbolValidationPattern =
      new RegExp(r'^(?:[a-zA-Z$][a-zA-Z$0-9_]*\.)*(?:[a-zA-Z$][a-zA-Z$0-9_]*=?|'
          r'-|'
          r'unary-|'
          r'\[\]=|'
          r'~|'
          r'==|'
          r'\[\]|'
          r'\*|'
          r'/|'
          r'%|'
          r'~/|'
          r'\+|'
          r'<<|'
          r'>>|'
          r'>=|'
          r'>|'
          r'<=|'
          r'<|'
          r'&|'
          r'\^|'
          r'\|'
          r')$');

  ResolverVisitor(
      Resolution resolution, Element element, ResolutionRegistry registry,
      {Scope scope, bool useEnclosingScope: false})
      : this.enclosingElement = element,
        // When the element is a field, we are actually resolving its
        // initial value, which should not have access to instance
        // fields.
        inInstanceContext = (element.isInstanceMember && !element.isField) ||
            element.isGenerativeConstructor,
        this.currentClass =
            element.isClassMember ? element.enclosingClass : null,
        this.statementScope = new StatementScope(),
        this.scope = scope ??
            (useEnclosingScope
                ? Scope.buildEnclosingScope(element)
                : element.buildScope()),
        // The type annotations on a typedef do not imply type checks.
        // TODO(karlklose): clean this up (dartbug.com/8870).
        inCheckContext = resolution.options.enableTypeAssertions &&
            !element.isLibrary &&
            !element.isTypedef &&
            !element.enclosingElement.isTypedef,
        inCatchBlock = false,
        constantState = element.isConst
            ? ConstantState.CONSTANT
            : ConstantState.NON_CONSTANT,
        super(resolution, registry);

  CommonElements get commonElements => resolution.commonElements;
  ConstantEnvironment get constants => resolution.constants;
  ResolverTask get resolver => resolution.resolver;
  CompilerOptions get options => resolution.options;

  AsyncMarker get currentAsyncMarker {
    if (enclosingElement is FunctionElement) {
      FunctionElement function = enclosingElement;
      return function.asyncMarker;
    }
    return AsyncMarker.SYNC;
  }

  Element reportLookupErrorIfAny(Element result, Node node, String name) {
    if (!Elements.isUnresolved(result)) {
      if (!inInstanceContext && result.isInstanceMember) {
        reporter.reportErrorMessage(
            node, MessageKind.NO_INSTANCE_AVAILABLE, {'name': name});
        return new ErroneousElementX(MessageKind.NO_INSTANCE_AVAILABLE,
            {'name': name}, name, enclosingElement);
      } else if (result.isAmbiguous) {
        AmbiguousElement ambiguous = result;
        return reportAndCreateErroneousElement(
            node, name, ambiguous.messageKind, ambiguous.messageArguments,
            infos: ambiguous.computeInfos(enclosingElement, reporter),
            isError: true);
      }
    }
    return result;
  }

  // Create, or reuse an already created, target element for a statement.
  JumpTarget getOrDefineTarget(Node statement) {
    JumpTarget element = registry.getTargetDefinition(statement);
    if (element == null) {
      element = new JumpTargetX(
          statement, statementScope.nestingLevel, enclosingElement);
      registry.defineTarget(statement, element);
    }
    return element;
  }

  doInPromotionScope(Node node, action()) {
    promotionScope = promotionScope.prepend(node);
    var result = action();
    promotionScope = promotionScope.tail;
    return result;
  }

  inStaticContext(action(), {bool inConstantInitializer: false}) {
    bool wasInstanceContext = inInstanceContext;
    ConstantState oldConstantState = constantState;
    constantState = inConstantInitializer
        ? ConstantState.CONSTANT_INITIALIZER
        : constantState;
    inInstanceContext = false;
    var result = action();
    inInstanceContext = wasInstanceContext;
    constantState = oldConstantState;
    return result;
  }

  ResolutionResult visitInStaticContext(Node node,
      {bool inConstantInitializer: false}) {
    return inStaticContext(() => visit(node),
        inConstantInitializer: inConstantInitializer);
  }

  /// Execute [action] where the constant state is `ConstantState.CONSTANT` if
  /// not already `ConstantState.CONSTANT_INITIALIZER`.
  inConstantContext(action()) {
    ConstantState oldConstantState = constantState;
    if (constantState != ConstantState.CONSTANT_INITIALIZER) {
      constantState = ConstantState.CONSTANT;
    }
    var result = action();
    constantState = oldConstantState;
    return result;
  }

  /// Visit [node] where the constant state is `ConstantState.CONSTANT` if
  /// not already `ConstantState.CONSTANT_INITIALIZER`.
  ResolutionResult visitInConstantContext(Node node) {
    ResolutionResult result = inConstantContext(() => visit(node));
    assert(result != null, failedAt(node, "No resolution result for $node."));

    return result;
  }

  ErroneousElement reportAndCreateErroneousElement(
      Node node, String name, MessageKind kind, Map arguments,
      {List<DiagnosticMessage> infos: const <DiagnosticMessage>[],
      bool isError: false}) {
    if (isError) {
      reporter.reportError(
          reporter.createMessage(node, kind, arguments), infos);
    } else {
      reporter.reportWarning(
          reporter.createMessage(node, kind, arguments), infos);
    }
    // TODO(ahe): Use [allowedCategory] to synthesize a more precise subclass
    // of [ErroneousElementX]. For example, [ErroneousFieldElementX],
    // [ErroneousConstructorElementX], etc.
    return new ErroneousElementX(kind, arguments, name, enclosingElement);
  }

  /// Report a warning or error on an unresolved access in non-instance context.
  ///
  /// The [ErroneousElement] corresponding to the message is returned.
  ErroneousElement reportCannotResolve(Node node, String name) {
    assert(
        !inInstanceContext,
        failedAt(
            node,
            "ResolverVisitor.reportCannotResolve must not be called in "
            "instance context."));

    // We report an error within initializers because `this` is implicitly
    // accessed when unqualified identifiers are not resolved.  For
    // details, see section 16.14.3 of the spec (2nd edition):
    //   An unqualified invocation `i` of the form `id(a1, ...)`
    //   ...
    //   If `i` does not occur inside a top level or static function, `i`
    //   is equivalent to `this.id(a1 , ...)`.
    bool inInitializer = enclosingElement.isGenerativeConstructor ||
        (enclosingElement.isInstanceMember && enclosingElement.isField);
    MessageKind kind;
    Map arguments = {'name': name};
    if (inInitializer) {
      kind = MessageKind.CANNOT_RESOLVE_IN_INITIALIZER;
    } else if (name == 'await') {
      var functionName = enclosingElement.name;
      if (functionName == '') {
        kind = MessageKind.CANNOT_RESOLVE_AWAIT_IN_CLOSURE;
      } else {
        kind = MessageKind.CANNOT_RESOLVE_AWAIT;
        arguments['functionName'] = functionName;
      }
    } else {
      kind = MessageKind.CANNOT_RESOLVE;
    }
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    return reportAndCreateErroneousElement(node, name, kind, arguments,
        isError: inInitializer);
  }

  ResolutionResult visitIdentifier(Identifier node) {
    if (node.isThis()) {
      if (!inInstanceContext) {
        reporter.reportErrorMessage(
            node, MessageKind.NO_INSTANCE_AVAILABLE, {'name': node});
      }
      return const NoneResult();
    } else if (node.isSuper()) {
      if (!inInstanceContext) {
        reporter.reportErrorMessage(node, MessageKind.NO_SUPER_IN_STATIC);
      }
      if ((ElementCategory.SUPER & allowedCategory) == 0) {
        reporter.reportErrorMessage(node, MessageKind.INVALID_USE_OF_SUPER);
      }
      return const NoneResult();
    } else {
      String name = node.source;
      Element element = lookupInScope(reporter, node, scope, name);
      if (Elements.isUnresolved(element) && name == 'dynamic') {
        // TODO(johnniwinther): Remove this hack when we can return more complex
        // objects than [Element] from this method.
        ClassElement typeClass = commonElements.typeClass;
        element = typeClass;
        // Set the type to be `dynamic` to mark that this is a type literal.
        registry.setType(node, const ResolutionDynamicType());
      }
      element = reportLookupErrorIfAny(element, node, name);
      if (element == null) {
        if (!inInstanceContext) {
          element = reportCannotResolve(node, name);
        }
      } else if (element.isMalformed) {
        // Use the malformed element.
      } else {
        if ((element.kind.category & allowedCategory) == 0) {
          element =
              reportAndCreateErroneousElement(node, name, MessageKind.GENERIC,
                  // TODO(ahe): Improve error message. Need UX input.
                  {'text': "is not an expression $element"});
        }
      }
      if (!Elements.isUnresolved(element) && element.isClass) {
        ClassElement classElement = element;
        classElement.ensureResolved(resolution);
      }
      if (element != null) {
        registry.useElement(node, element);
        if (element.isPrefix) {
          return new PrefixResult(element, null);
        } else if (element.isClass && sendIsMemberAccess) {
          return new PrefixResult(null, element);
        }
        return new ElementResult(element);
      }
      return const NoneResult();
    }
  }

  TypeResult visitTypeAnnotation(TypeAnnotation node) {
    return new TypeResult(resolveTypeAnnotation(node));
  }

  bool isNamedConstructor(Send node) => node.receiver != null;

  Name getRedirectingThisOrSuperConstructorName(Send node) {
    if (isNamedConstructor(node)) {
      String constructorName = node.selector.asIdentifier().source;
      return new Name(constructorName, enclosingElement.library);
    } else {
      return const PublicName('');
    }
  }

  FunctionElement resolveConstructorRedirection(FunctionElementX constructor) {
    FunctionExpression node = constructor.parseNode(resolution.parsingContext);

    // A synthetic constructor does not have a node.
    if (node == null) return null;
    if (node.initializers == null) return null;
    Link<Node> initializers = node.initializers.nodes;
    if (!initializers.isEmpty &&
        Initializers.isConstructorRedirect(initializers.head)) {
      Name name = getRedirectingThisOrSuperConstructorName(initializers.head);
      final ClassElement classElement = constructor.enclosingClass;
      return classElement.lookupConstructor(name.text);
    }
    return null;
  }

  void setupFunction(FunctionExpression node, FunctionElement function) {
    Element enclosingElement = function.enclosingElement;
    if (node.modifiers.isStatic && enclosingElement.kind != ElementKind.CLASS) {
      reporter.reportErrorMessage(node, MessageKind.ILLEGAL_STATIC);
    }
    FunctionSignature functionSignature = function.functionSignature;

    // Create the scope where the type variables are introduced, if any.
    scope = new MethodScope(scope, function);
    functionSignature.typeVariables
        .forEach((ResolutionDartType type) => addToScope(type.element));

    // Create the scope for the function body, and put the parameters in scope.
    scope = new BlockScope(scope);
    Link<Node> parameterNodes =
        (node.parameters == null) ? const Link<Node>() : node.parameters.nodes;
    functionSignature.forEachParameter((_element) {
      ParameterElementX element = _element;
      // TODO(karlklose): should be a list of [FormalElement]s, but the actual
      // implementation uses [Element].
      List<Element> optionals = functionSignature.optionalParameters;
      if (!optionals.isEmpty && element == optionals.first) {
        NodeList nodes = parameterNodes.head;
        parameterNodes = nodes.nodes;
      }
      if (element.isOptional) {
        if (element.initializer != null) {
          ResolutionResult result = visitInConstantContext(element.initializer);
          if (result.isConstant) {
            element.constant = result.constant;
          }
        } else {
          registry.registerConstantLiteral(
              element.constant = new NullConstantExpression());
        }
      }
      VariableDefinitions variableDefinitions = parameterNodes.head;
      Node parameterNode = variableDefinitions.definitions.nodes.head;
      // Field parameters (this.x) are not visible inside the constructor. The
      // fields they reference are visible, but must be resolved independently.
      if (element.isInitializingFormal) {
        registry.useElement(parameterNode, element);
      } else {
        LocalParameterElementX parameterElement = element;
        defineLocalVariable(parameterNode, parameterElement);
        addToScope(parameterElement);
      }
      parameterNodes = parameterNodes.tail;
    });
    addDeferredAction(enclosingElement, () {
      functionSignature.forEachOptionalParameter((_parameter) {
        ParameterElementX parameter = _parameter;
        parameter.constant =
            resolver.constantCompiler.compileConstant(parameter);
      });
    });
    registry.registerCheckedModeCheck(functionSignature.returnType);
    functionSignature.forEachParameter((_element) {
      ParameterElement element = _element;
      registry.registerCheckedModeCheck(element.type);
    });
  }

  ResolutionResult visitAssert(Assert node) {
    // TODO(sra): We could completely ignore the assert in production mode if we
    // didn't need it to be resolved for type checking.
    registry.registerFeature(
        node.hasMessage ? Feature.ASSERT_WITH_MESSAGE : Feature.ASSERT);
    visit(node.condition);
    visit(node.message);
    return const NoneResult();
  }

  ResolutionResult visitCascade(Cascade node) {
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitCascadeReceiver(CascadeReceiver node) {
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitIn(Node node, Scope nestedScope) {
    Scope oldScope = scope;
    scope = nestedScope;
    ResolutionResult result = visit(node);
    scope = oldScope;
    return result;
  }

  /**
   * Introduces new default targets for break and continue
   * before visiting the body of the loop
   */
  void visitLoopBodyIn(Loop loop, Node body, Scope bodyScope) {
    JumpTarget element = getOrDefineTarget(loop);
    statementScope.enterLoop(element);
    visitIn(body, bodyScope);
    statementScope.exitLoop();
    if (!element.isTarget) {
      registry.undefineTarget(loop);
    }
  }

  ResolutionResult visitBlock(Block node) {
    visitIn(node.statements, new BlockScope(scope));
    return const NoneResult();
  }

  ResolutionResult visitDoWhile(DoWhile node) {
    visitLoopBodyIn(node, node.body, new BlockScope(scope));
    visit(node.condition);
    return const NoneResult();
  }

  ResolutionResult visitEmptyStatement(EmptyStatement node) {
    return const NoneResult();
  }

  ResolutionResult visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement oldExpressionStatement = currentExpressionStatement;
    currentExpressionStatement = node;
    visit(node.expression);
    currentExpressionStatement = oldExpressionStatement;
    return const NoneResult();
  }

  ResolutionResult visitFor(For node) {
    Scope blockScope = new BlockScope(scope);
    visitIn(node.initializer, blockScope);
    visitIn(node.condition, blockScope);
    visitIn(node.update, blockScope);
    visitLoopBodyIn(node, node.body, blockScope);
    return const NoneResult();
  }

  ResolutionResult visitFunctionDeclaration(FunctionDeclaration node) {
    assert(node.function.name != null);
    visitFunctionExpression(node.function, inFunctionDeclaration: true);
    return const NoneResult();
  }

  /// Process a local function declaration or an anonymous function expression.
  ///
  /// [inFunctionDeclaration] is `true` when the current node is the immediate
  /// child of a function declaration.
  ///
  /// This is used to distinguish local function declarations from anonymous
  /// function expressions.
  ResolutionResult visitFunctionExpression(FunctionExpression node,
      {bool inFunctionDeclaration: false}) {
    bool doAddToScope = inFunctionDeclaration;
    if (!inFunctionDeclaration && node.name != null) {
      reporter.reportErrorMessage(node.name,
          MessageKind.NAMED_FUNCTION_EXPRESSION, {'name': node.name});
    }
    String name;
    if (node.name == null) {
      name = "";
    } else {
      name = node.name.asIdentifier().source;
    }
    LocalFunctionElementX function = new LocalFunctionElementX(
        name, node, ElementKind.FUNCTION, Modifiers.EMPTY, enclosingElement);
    ResolverTask.processAsyncMarker(resolution, function, registry);
    function.functionSignature = SignatureResolver.analyze(
        resolution,
        scope,
        const FunctionTypeParameterScope(),
        node.typeVariables,
        node.parameters,
        node.returnType,
        function,
        registry,
        createRealParameters: true,
        isFunctionExpression: !inFunctionDeclaration);
    checkLocalDefinitionName(node, function);
    registry.defineFunction(node, function);
    if (doAddToScope) {
      addToScope(function);
    }
    Scope oldScope = scope; // The scope is modified by [setupFunction].
    setupFunction(node, function);

    Element previousEnclosingElement = enclosingElement;
    enclosingElement = function;
    // Run the body in a fresh statement scope.
    StatementScope oldStatementScope = statementScope;
    statementScope = new StatementScope();
    visit(node.body);
    statementScope = oldStatementScope;

    scope = oldScope;
    enclosingElement = previousEnclosingElement;

    registry.registerStaticUse(new StaticUse.closure(function));
    return const NoneResult();
  }

  ResolutionResult visitIf(If node) {
    doInPromotionScope(node.condition.expression, () => visit(node.condition));
    doInPromotionScope(
        node.thenPart, () => visitIn(node.thenPart, new BlockScope(scope)));
    visitIn(node.elsePart, new BlockScope(scope));
    return const NoneResult();
  }

  static Selector computeSendSelector(
      Send node, LibraryElement library, Element element) {
    // First determine if this is part of an assignment.
    bool isSet = node.asSendSet() != null;

    if (node.isIndex) {
      return isSet ? new Selector.indexSet() : new Selector.index();
    }

    if (node.isOperator) {
      String source = node.selector.asOperator().source;
      String string = source;
      if (identical(string, '!') ||
          identical(string, '&&') ||
          identical(string, '||') ||
          identical(string, 'is') ||
          identical(string, 'as') ||
          identical(string, '?') ||
          identical(string, '??')) {
        return null;
      }
      String op = source;
      if (!isUserDefinableOperator(source)) {
        op = Elements.mapToUserOperatorOrNull(source);
      }
      if (op == null) {
        // Unsupported operator. An error has been reported during parsing.
        return new Selector.call(new Name(source, library),
            new CallStructure.unnamed(node.argumentsNode.slowLength()));
      }
      return node.arguments.isEmpty
          ? new Selector.unaryOperator(op)
          : new Selector.binaryOperator(op);
    }

    Identifier identifier = node.selector.asIdentifier();
    if (node.isPropertyAccess) {
      assert(!isSet);
      return new Selector.getter(new Name(identifier.source, library));
    } else if (isSet) {
      return new Selector.setter(
          new Name(identifier.source, library, isSetter: true));
    }

    // Compute the arity and the list of named arguments.
    int arity = 0;
    List<String> named = <String>[];
    for (Link<Node> link = node.argumentsNode.nodes;
        !link.isEmpty;
        link = link.tail) {
      Expression argument = link.head;
      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        named.add(namedArgument.name.source);
      }
      arity++;
    }

    if (element != null && element.isConstructor) {
      return new Selector.callConstructor(
          new Name(element.name, library), arity, named);
    }

    // If we're invoking a closure, we do not have an identifier.
    return (identifier == null)
        ? new Selector.callClosure(arity, named)
        : new Selector.call(new Name(identifier.source, library),
            new CallStructure(arity, named));
  }

  Selector resolveSelector(Send node, Element element) {
    LibraryElement library = enclosingElement.library;
    Selector selector = computeSendSelector(node, library, element);
    if (selector != null) registry.setSelector(node, selector);
    return selector;
  }

  ArgumentsResult resolveArguments(NodeList list) {
    if (list == null) return null;
    bool isValidAsConstant = true;
    List<ResolutionResult> argumentResults = <ResolutionResult>[];
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;
    Map<String, Node> seenNamedArguments = new Map<String, Node>();
    int argumentCount = 0;
    List<String> namedArguments = <String>[];
    for (Link<Node> link = list.nodes; !link.isEmpty; link = link.tail) {
      Expression argument = link.head;
      ResolutionResult result = visit(argument);
      if (!result.isConstant) {
        isValidAsConstant = false;
      }
      argumentResults.add(result);

      NamedArgument namedArgument = argument.asNamedArgument();
      if (namedArgument != null) {
        String source = namedArgument.name.source;
        namedArguments.add(source);
        if (seenNamedArguments.containsKey(source)) {
          reportDuplicateDefinition(
              source, argument, seenNamedArguments[source]);
          isValidAsConstant = false;
        } else {
          seenNamedArguments[source] = namedArgument;
        }
      } else if (!seenNamedArguments.isEmpty) {
        reporter.reportErrorMessage(
            argument, MessageKind.INVALID_ARGUMENT_AFTER_NAMED);
        isValidAsConstant = false;
      }
      argumentCount++;
    }
    sendIsMemberAccess = oldSendIsMemberAccess;
    return new ArgumentsResult(
        new CallStructure(argumentCount, namedArguments), argumentResults,
        isValidAsConstant: isValidAsConstant);
  }

  /// Check that access to `super` is currently allowed. Returns an
  /// [AccessSemantics] in case of an error, `null` otherwise.
  AccessSemantics checkSuperAccess(Send node) {
    if (!inInstanceContext) {
      ErroneousElement error = reportAndCreateErroneousElement(
          node, 'super', MessageKind.NO_SUPER_IN_STATIC, {},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      return new StaticAccess.invalid(error);
    }
    if (node.isConditional) {
      // `super?.foo` is not allowed.
      ErroneousElement error = reportAndCreateErroneousElement(
          node, 'super', MessageKind.INVALID_USE_OF_SUPER, {},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      return new StaticAccess.invalid(error);
    }
    if (currentClass.supertype == null) {
      // This is just to guard against internal errors, so no need
      // for a real error message.
      ErroneousElement error = reportAndCreateErroneousElement(node, 'super',
          MessageKind.GENERIC, {'text': "Object has no superclass"},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      return new StaticAccess.invalid(error);
    }
    registry.registerSuperUse(reporter.spanFromSpannable(node));
    return null;
  }

  /// Check that access to `this` is currently allowed. Returns an
  /// [AccessSemantics] in case of an error, `null` otherwise.
  AccessSemantics checkThisAccess(Send node) {
    if (!inInstanceContext) {
      ErroneousElement error = reportAndCreateErroneousElement(
          node, 'this', MessageKind.NO_THIS_AVAILABLE, const {},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      return new StaticAccess.invalid(error);
    }
    return null;
  }

  /// Compute the [AccessSemantics] corresponding to a super access of [target].
  AccessSemantics computeSuperAccessSemantics(Spannable node, Element target) {
    if (target.isMalformed) {
      return new StaticAccess.unresolvedSuper(target);
    } else if (target.isGetter) {
      return new StaticAccess.superGetter(target);
    } else if (target.isSetter) {
      return new StaticAccess.superSetter(target);
    } else if (target.isField) {
      if (target.isFinal) {
        return new StaticAccess.superFinalField(target);
      } else {
        return new StaticAccess.superField(target);
      }
    } else {
      assert(target.isFunction,
          failedAt(node, "Unexpected super target '$target'."));
      return new StaticAccess.superMethod(target);
    }
  }

  /// Compute the [AccessSemantics] corresponding to a compound super access
  /// reading from [getter] and writing to [setter].
  AccessSemantics computeCompoundSuperAccessSemantics(
      Spannable node, Element getter, Element setter,
      {bool isIndex: false}) {
    if (getter.isMalformed) {
      if (setter.isMalformed) {
        return new StaticAccess.unresolvedSuper(getter);
      } else if (setter.isFunction) {
        assert(setter.name == '[]=',
            failedAt(node, "Unexpected super setter '$setter'."));
        return new CompoundAccessSemantics(
            CompoundAccessKind.UNRESOLVED_SUPER_GETTER, getter, setter);
      } else {
        assert(setter.isSetter,
            failedAt(node, "Unexpected super setter '$setter'."));
        return new CompoundAccessSemantics(
            CompoundAccessKind.UNRESOLVED_SUPER_GETTER, getter, setter);
      }
    } else if (getter.isField) {
      if (setter.isMalformed) {
        assert(
            getter.isFinal,
            failedAt(node,
                "Unexpected super setter '$setter' for getter '$getter."));
        return new StaticAccess.superFinalField(getter);
      } else if (setter.isField) {
        if (getter == setter) {
          return new StaticAccess.superField(getter);
        } else {
          return new CompoundAccessSemantics(
              CompoundAccessKind.SUPER_FIELD_FIELD, getter, setter);
        }
      } else {
        // Either the field is accessible directly, or a setter shadows the
        // setter access. If there was another instance member it would shadow
        // the field.
        assert(setter.isSetter,
            failedAt(node, "Unexpected super setter '$setter'."));
        return new CompoundAccessSemantics(
            CompoundAccessKind.SUPER_FIELD_SETTER, getter, setter);
      }
    } else if (getter.isGetter) {
      if (setter.isMalformed) {
        return new CompoundAccessSemantics(
            CompoundAccessKind.UNRESOLVED_SUPER_SETTER, getter, setter);
      } else if (setter.isField) {
        return new CompoundAccessSemantics(
            CompoundAccessKind.SUPER_GETTER_FIELD, getter, setter);
      } else {
        assert(setter.isSetter,
            failedAt(node, "Unexpected super setter '$setter'."));
        return new CompoundAccessSemantics(
            CompoundAccessKind.SUPER_GETTER_SETTER, getter, setter);
      }
    } else {
      assert(getter.isFunction,
          failedAt(node, "Unexpected super getter '$getter'."));
      if (setter.isMalformed) {
        if (isIndex) {
          return new CompoundAccessSemantics(
              CompoundAccessKind.UNRESOLVED_SUPER_SETTER, getter, setter);
        } else {
          return new StaticAccess.superMethod(getter);
        }
      } else if (setter.isFunction) {
        assert(setter.name == '[]=',
            failedAt(node, "Unexpected super setter '$setter'."));
        assert(getter.name == '[]',
            failedAt(node, "Unexpected super getter '$getter'."));
        return new CompoundAccessSemantics(
            CompoundAccessKind.SUPER_GETTER_SETTER, getter, setter);
      } else {
        assert(setter.isSetter,
            failedAt(node, "Unexpected super setter '$setter'."));
        return new CompoundAccessSemantics(
            CompoundAccessKind.SUPER_METHOD_SETTER, getter, setter);
      }
    }
  }

  /// Compute the [AccessSemantics] corresponding to a local access of [target].
  AccessSemantics computeLocalAccessSemantics(
      Spannable node, LocalElement target) {
    if (target.isRegularParameter) {
      if (target.isFinal || target.isConst) {
        return new StaticAccess.finalParameter(target);
      } else {
        return new StaticAccess.parameter(target);
      }
    } else if (target.isInitializingFormal) {
      return new StaticAccess.finalParameter(target);
    } else if (target.isVariable) {
      if (target.isFinal || target.isConst) {
        return new StaticAccess.finalLocalVariable(target);
      } else {
        return new StaticAccess.localVariable(target);
      }
    } else {
      assert(target.isFunction,
          failedAt(node, "Unexpected local target '$target'."));
      return new StaticAccess.localFunction(target);
    }
  }

  /// Compute the [AccessSemantics] corresponding to a static or toplevel access
  /// of [target].
  AccessSemantics computeStaticOrTopLevelAccessSemantics(
      Spannable node, Element target) {
    target = target.declaration;
    if (target.isMalformed) {
      // This handles elements with parser errors.
      return new StaticAccess.unresolved(target);
    }
    if (target.isStatic) {
      if (target.isGetter) {
        return new StaticAccess.staticGetter(target);
      } else if (target.isSetter) {
        return new StaticAccess.staticSetter(target);
      } else if (target.isField) {
        if (target.isFinal || target.isConst) {
          return new StaticAccess.finalStaticField(target);
        } else {
          return new StaticAccess.staticField(target);
        }
      } else {
        assert(target.isFunction,
            failedAt(node, "Unexpected static target '$target'."));
        return new StaticAccess.staticMethod(target);
      }
    } else {
      assert(target.isTopLevel,
          failedAt(node, "Unexpected statically resolved target '$target'."));
      if (target.isGetter) {
        return new StaticAccess.topLevelGetter(target);
      } else if (target.isSetter) {
        return new StaticAccess.topLevelSetter(target);
      } else if (target.isField) {
        if (target.isFinal) {
          return new StaticAccess.finalTopLevelField(target);
        } else {
          return new StaticAccess.topLevelField(target);
        }
      } else {
        assert(target.isFunction,
            failedAt(node, "Unexpected top level target '$target'."));
        return new StaticAccess.topLevelMethod(target);
      }
    }
  }

  /// Compute the [AccessSemantics] for accessing the name of [selector] on the
  /// super class.
  ///
  /// If no matching super member is found and error is reported and
  /// `noSuchMethod` on `super` is registered. Furthermore, if [alternateName]
  /// is provided, the [AccessSemantics] corresponding to the alternate name is
  /// returned. For instance, the access of a super setter for an unresolved
  /// getter:
  ///
  ///     class Super {
  ///       set name(_) {}
  ///     }
  ///     class Sub extends Super {
  ///       foo => super.name; // Access to the setter.
  ///     }
  ///
  AccessSemantics computeSuperAccessSemanticsForSelector(
      Spannable node, Selector selector,
      {Name alternateName}) {
    Name name = selector.memberName;
    // TODO(johnniwinther): Ensure correct behavior if currentClass is a
    // patch.
    Element target = currentClass.lookupSuperByName(name);
    // [target] may be null which means invoking noSuchMethod on super.
    if (target == null) {
      if (alternateName != null) {
        target = currentClass.lookupSuperByName(alternateName);
      }
      Element error;
      if (selector.isSetter) {
        error = reportAndCreateErroneousElement(
            node,
            name.text,
            MessageKind.UNDEFINED_SUPER_SETTER,
            {'className': currentClass.name, 'memberName': name});
      } else {
        error = reportAndCreateErroneousElement(
            node,
            name.text,
            MessageKind.NO_SUCH_SUPER_MEMBER,
            {'className': currentClass.name, 'memberName': name});
      }
      if (target == null) {
        // If a setter wasn't resolved, use the [ErroneousElement].
        target = error;
      }
      // We still need to register the invocation, because we might
      // call [:super.noSuchMethod:] which calls [JSInvocationMirror._invokeOn].
      registry.registerDynamicUse(new DynamicUse(selector, null));
      registry.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
    return computeSuperAccessSemantics(node, target);
  }

  /// Compute the [AccessSemantics] for accessing the name of [selector] on the
  /// super class.
  ///
  /// If no matching super member is found and error is reported and
  /// `noSuchMethod` on `super` is registered. Furthermore, if [alternateName]
  /// is provided, the [AccessSemantics] corresponding to the alternate name is
  /// returned. For instance, the access of a super setter for an unresolved
  /// getter:
  ///
  ///     class Super {
  ///       set name(_) {}
  ///     }
  ///     class Sub extends Super {
  ///       foo => super.name; // Access to the setter.
  ///     }
  ///
  AccessSemantics computeSuperAccessSemanticsForSelectors(
      Spannable node, Selector getterSelector, Selector setterSelector,
      {bool isIndex: false}) {
    bool getterError = false;
    bool setterError = false;

    // TODO(johnniwinther): Ensure correct behavior if currentClass is a
    // patch.
    Element getter = currentClass.lookupSuperByName(getterSelector.memberName);
    // [target] may be null which means invoking noSuchMethod on super.
    if (getter == null) {
      getter = reportAndCreateErroneousElement(
          node,
          getterSelector.name,
          MessageKind.NO_SUCH_SUPER_MEMBER,
          {'className': currentClass.name, 'memberName': getterSelector.name});
      getterError = true;
    }
    Element setter = currentClass.lookupSuperByName(setterSelector.memberName);
    // [target] may be null which means invoking noSuchMethod on super.
    if (setter == null) {
      setter = reportAndCreateErroneousElement(
          node,
          setterSelector.name,
          MessageKind.NO_SUCH_SUPER_MEMBER,
          {'className': currentClass.name, 'memberName': setterSelector.name});
      setterError = true;
    } else if (getter == setter) {
      if (setter.isFunction) {
        setter = reportAndCreateErroneousElement(
            node, setterSelector.name, MessageKind.ASSIGNING_METHOD_IN_SUPER, {
          'superclassName': setter.enclosingClass.name,
          'name': setterSelector.name
        });
        setterError = true;
      } else if (setter.isField && setter.isFinal) {
        setter = reportAndCreateErroneousElement(node, setterSelector.name,
            MessageKind.ASSIGNING_FINAL_FIELD_IN_SUPER, {
          'superclassName': setter.enclosingClass.name,
          'name': setterSelector.name
        });
        setterError = true;
      }
    }
    if (getterError) {
      // We still need to register the invocation, because we might
      // call [:super.noSuchMethod:] which calls [JSInvocationMirror._invokeOn].
      registry.registerDynamicUse(new DynamicUse(getterSelector, null));
    }
    if (setterError) {
      // We still need to register the invocation, because we might
      // call [:super.noSuchMethod:] which calls [JSInvocationMirror._invokeOn].
      registry.registerDynamicUse(new DynamicUse(setterSelector, null));
    }
    if (getterError || setterError) {
      registry.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
    }
    return computeCompoundSuperAccessSemantics(node, getter, setter,
        isIndex: isIndex);
  }

  /// Resolve [node] as a subexpression that is _not_ the prefix of a member
  /// access. For instance `a` in `a + b`, as opposed to `a` in `a.b`.
  ResolutionResult visitExpression(Node node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;
    ResolutionResult result = visit(node);
    sendIsMemberAccess = oldSendIsMemberAccess;
    return result;
  }

  /// Resolve [node] as a subexpression that _is_ the prefix of a member access.
  /// For instance `a` in `a.b`, as opposed to `a` in `a + b`.
  ResolutionResult visitExpressionPrefix(Node node) {
    int oldAllowedCategory = allowedCategory;
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    allowedCategory |= ElementCategory.PREFIX | ElementCategory.SUPER;
    sendIsMemberAccess = true;
    ResolutionResult result = visit(node);
    sendIsMemberAccess = oldSendIsMemberAccess;
    allowedCategory = oldAllowedCategory;
    return result;
  }

  /// Handle a type test expression, like `a is T` and `a is! T`.
  ResolutionResult handleIs(Send node) {
    Node expression = node.receiver;
    visitExpression(expression);

    // TODO(johnniwinther): Use seen type tests to avoid registration of
    // mutation/access to unpromoted variables.

    Send notTypeNode = node.arguments.head.asSend();
    ResolutionDartType type;
    SendStructure sendStructure;
    if (notTypeNode != null) {
      // `e is! T`.
      Node typeNode = notTypeNode.receiver;
      type = resolveTypeAnnotation(typeNode, registerCheckedModeCheck: false);
      sendStructure = new IsNotStructure(type);
    } else {
      // `e is T`.
      Node typeNode = node.arguments.head;
      type = resolveTypeAnnotation(typeNode, registerCheckedModeCheck: false);
      sendStructure = new IsStructure(type);
    }

    // GENERIC_METHODS: Method type variables are not reified so we must warn
    // about the error which will occur at runtime.
    if (type is MethodTypeVariableType) {
      reporter.reportWarningMessage(
          node, MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED);
    }

    registry.registerTypeUse(new TypeUse.isCheck(type));
    registry.registerSendStructure(node, sendStructure);
    return const NoneResult();
  }

  /// Handle a type cast expression, like `a as T`.
  ResolutionResult handleAs(Send node) {
    Node expression = node.receiver;
    visitExpression(expression);

    Node typeNode = node.arguments.head;
    ResolutionDartType type =
        resolveTypeAnnotation(typeNode, registerCheckedModeCheck: false);

    // GENERIC_METHODS: Method type variables are not reified, so we must inform
    // the developer about the potentially bug-inducing semantics.
    if (type is MethodTypeVariableType) {
      reporter.reportHintMessage(
          node, MessageKind.TYPE_VARIABLE_FROM_METHOD_CONSIDERED_DYNAMIC);
    }

    registry.registerTypeUse(new TypeUse.asCast(type));
    registry.registerSendStructure(node, new AsStructure(type));
    return const NoneResult();
  }

  /// Handle the unary expression of an unresolved unary operator [text], like
  /// the no longer supported `+a`.
  ResolutionResult handleUnresolvedUnary(Send node, String text) {
    Node expression = node.receiver;
    if (node.isSuperCall) {
      checkSuperAccess(node);
    } else {
      visitExpression(expression);
    }

    registry.registerSendStructure(node, const InvalidUnaryStructure());
    return const NoneResult();
  }

  /// Handle the unary expression of a user definable unary [operator], like
  /// `-a`, and `-super`.
  ResolutionResult handleUserDefinableUnary(Send node, UnaryOperator operator) {
    ResolutionResult result = const NoneResult();
    Node expression = node.receiver;
    Selector selector = operator.selector;
    // TODO(23998): Remove this when all information goes through the
    // [SendStructure].
    registry.setSelector(node, selector);

    AccessSemantics semantics;
    if (node.isSuperCall) {
      semantics = checkSuperAccess(node);
      if (semantics == null) {
        semantics = computeSuperAccessSemanticsForSelector(node, selector);
        // TODO(johnniwinther): Add information to [AccessSemantics] about
        // whether it is erroneous.
        if (semantics.kind == AccessKind.SUPER_METHOD) {
          MethodElement superMethod = semantics.element.declaration;
          registry.registerStaticUse(
              new StaticUse.superInvoke(superMethod, selector.callStructure));
        }
        // TODO(23998): Remove this when all information goes through
        // the [SendStructure].
        registry.useElement(node, semantics.element);
      }
    } else {
      ResolutionResult expressionResult = visitExpression(expression);
      semantics = const DynamicAccess.expression();
      registry.registerDynamicUse(new DynamicUse(selector, null));

      if (expressionResult.isConstant) {
        bool isValidConstant;
        ConstantExpression expressionConstant = expressionResult.constant;
        ResolutionDartType knownExpressionType =
            expressionConstant.getKnownType(commonElements);
        switch (operator.kind) {
          case UnaryOperatorKind.COMPLEMENT:
            isValidConstant = knownExpressionType == commonElements.intType;
            break;
          case UnaryOperatorKind.NEGATE:
            isValidConstant = knownExpressionType == commonElements.intType ||
                knownExpressionType == commonElements.doubleType;
            break;
          case UnaryOperatorKind.NOT:
            reporter.internalError(
                node, "Unexpected user definable unary operator: $operator");
        }
        if (isValidConstant) {
          // TODO(johnniwinther): Handle potentially invalid constant
          // expressions.
          ConstantExpression constant =
              new UnaryConstantExpression(operator, expressionConstant);
          registry.setConstant(node, constant);
          result = new ConstantResult(node, constant);
        }
      }
    }
    if (semantics != null) {
      registry.registerSendStructure(
          node, new UnaryStructure(semantics, operator));
    }
    return result;
  }

  /// Handle a not expression, like `!a`.
  ResolutionResult handleNot(Send node, UnaryOperator operator) {
    assert(operator.kind == UnaryOperatorKind.NOT, failedAt(node));

    Node expression = node.receiver;
    ResolutionResult result = visitExpression(expression);
    registry.registerSendStructure(node, const NotStructure());

    if (result.isConstant) {
      ConstantExpression expressionConstant = result.constant;
      if (expressionConstant.getKnownType(commonElements) ==
          commonElements.boolType) {
        // TODO(johnniwinther): Handle potentially invalid constant expressions.
        ConstantExpression constant =
            new UnaryConstantExpression(operator, expressionConstant);
        registry.setConstant(node, constant);
        return new ConstantResult(node, constant);
      }
    }

    return const NoneResult();
  }

  /// Handle a logical and expression, like `a && b`.
  ResolutionResult handleLogicalAnd(Send node) {
    Node left = node.receiver;
    Node right = node.arguments.head;
    ResolutionResult leftResult =
        doInPromotionScope(left, () => visitExpression(left));
    ResolutionResult rightResult =
        doInPromotionScope(right, () => visitExpression(right));
    registry.registerSendStructure(node, const LogicalAndStructure());

    if (leftResult.isConstant && rightResult.isConstant) {
      ConstantExpression leftConstant = leftResult.constant;
      ConstantExpression rightConstant = rightResult.constant;
      if (leftConstant.getKnownType(commonElements) ==
              commonElements.boolType &&
          rightConstant.getKnownType(commonElements) ==
              commonElements.boolType) {
        // TODO(johnniwinther): Handle potentially invalid constant expressions.
        ConstantExpression constant = new BinaryConstantExpression(
            leftConstant, BinaryOperator.LOGICAL_AND, rightConstant);
        registry.setConstant(node, constant);
        return new ConstantResult(node, constant);
      }
    }

    return const NoneResult();
  }

  /// Handle a logical or expression, like `a || b`.
  ResolutionResult handleLogicalOr(Send node) {
    Node left = node.receiver;
    Node right = node.arguments.head;
    ResolutionResult leftResult = visitExpression(left);
    ResolutionResult rightResult = visitExpression(right);
    registry.registerSendStructure(node, const LogicalOrStructure());

    if (leftResult.isConstant && rightResult.isConstant) {
      ConstantExpression leftConstant = leftResult.constant;
      ConstantExpression rightConstant = rightResult.constant;
      if (leftConstant.getKnownType(commonElements) ==
              commonElements.boolType &&
          rightConstant.getKnownType(commonElements) ==
              commonElements.boolType) {
        // TODO(johnniwinther): Handle potentially invalid constant expressions.
        ConstantExpression constant = new BinaryConstantExpression(
            leftConstant, BinaryOperator.LOGICAL_OR, rightConstant);
        registry.setConstant(node, constant);
        return new ConstantResult(node, constant);
      }
    }
    return const NoneResult();
  }

  /// Handle an if-null expression, like `a ?? b`.
  ResolutionResult handleIfNull(Send node) {
    Node left = node.receiver;
    Node right = node.arguments.head;
    visitExpression(left);
    visitExpression(right);
    registry.registerConstantLiteral(new NullConstantExpression());
    registry.registerDynamicUse(new DynamicUse(Selectors.equals, null));
    registry.registerSendStructure(node, const IfNullStructure());
    return const NoneResult();
  }

  /// Handle the binary expression of an unresolved binary operator [text], like
  /// the no longer supported `a === b`.
  ResolutionResult handleUnresolvedBinary(Send node, String text) {
    Node left = node.receiver;
    Node right = node.arguments.head;
    if (node.isSuperCall) {
      checkSuperAccess(node);
    } else {
      visitExpression(left);
    }
    visitExpression(right);
    registry.registerSendStructure(node, const InvalidBinaryStructure());
    return const NoneResult();
  }

  /// Handle the binary expression of a user definable binary [operator], like
  /// `a + b`, `super + b`, `a == b` and `a != b`.
  ResolutionResult handleUserDefinableBinary(
      Send node, BinaryOperator operator) {
    ResolutionResult result = const NoneResult();
    Node left = node.receiver;
    Node right = node.arguments.head;
    AccessSemantics semantics;
    Selector selector;
    if (operator.kind == BinaryOperatorKind.INDEX) {
      selector = new Selector.index();
    } else {
      selector = new Selector.binaryOperator(operator.selectorName);
    }
    // TODO(23998): Remove this when all information goes through the
    // [SendStructure].
    registry.setSelector(node, selector);

    if (node.isSuperCall) {
      semantics = checkSuperAccess(node);
      if (semantics == null) {
        semantics = computeSuperAccessSemanticsForSelector(node, selector);
        // TODO(johnniwinther): Add information to [AccessSemantics] about
        // whether it is erroneous.
        if (semantics.kind == AccessKind.SUPER_METHOD) {
          MethodElement superMethod = semantics.element.declaration;
          registry.registerStaticUse(
              new StaticUse.superInvoke(superMethod, selector.callStructure));
        }
        // TODO(23998): Remove this when all information goes through
        // the [SendStructure].
        registry.useElement(node, semantics.element);
      }
      visitExpression(right);
    } else {
      ResolutionResult leftResult = visitExpression(left);
      ResolutionResult rightResult = visitExpression(right);
      registry.registerDynamicUse(new DynamicUse(selector, null));
      semantics = const DynamicAccess.expression();

      if (leftResult.isConstant && rightResult.isConstant) {
        bool isValidConstant;
        ConstantExpression leftConstant = leftResult.constant;
        ConstantExpression rightConstant = rightResult.constant;
        ResolutionDartType knownLeftType =
            leftConstant.getKnownType(commonElements);
        ResolutionDartType knownRightType =
            rightConstant.getKnownType(commonElements);
        switch (operator.kind) {
          case BinaryOperatorKind.EQ:
          case BinaryOperatorKind.NOT_EQ:
            isValidConstant = (knownLeftType == commonElements.intType ||
                    knownLeftType == commonElements.doubleType ||
                    knownLeftType == commonElements.stringType ||
                    knownLeftType == commonElements.boolType ||
                    knownLeftType == commonElements.nullType) &&
                (knownRightType == commonElements.intType ||
                    knownRightType == commonElements.doubleType ||
                    knownRightType == commonElements.stringType ||
                    knownRightType == commonElements.boolType ||
                    knownRightType == commonElements.nullType);
            break;
          case BinaryOperatorKind.ADD:
            isValidConstant = (knownLeftType == commonElements.intType ||
                    knownLeftType == commonElements.doubleType ||
                    knownLeftType == commonElements.stringType) &&
                (knownRightType == commonElements.intType ||
                    knownRightType == commonElements.doubleType ||
                    knownRightType == commonElements.stringType);
            break;
          case BinaryOperatorKind.SUB:
          case BinaryOperatorKind.MUL:
          case BinaryOperatorKind.DIV:
          case BinaryOperatorKind.IDIV:
          case BinaryOperatorKind.MOD:
          case BinaryOperatorKind.GTEQ:
          case BinaryOperatorKind.GT:
          case BinaryOperatorKind.LTEQ:
          case BinaryOperatorKind.LT:
            isValidConstant = (knownLeftType == commonElements.intType ||
                    knownLeftType == commonElements.doubleType) &&
                (knownRightType == commonElements.intType ||
                    knownRightType == commonElements.doubleType);
            break;
          case BinaryOperatorKind.SHL:
          case BinaryOperatorKind.SHR:
          case BinaryOperatorKind.AND:
          case BinaryOperatorKind.OR:
          case BinaryOperatorKind.XOR:
            isValidConstant = knownLeftType == commonElements.intType &&
                knownRightType == commonElements.intType;
            break;
          case BinaryOperatorKind.INDEX:
            isValidConstant = false;
            break;
          case BinaryOperatorKind.LOGICAL_AND:
          case BinaryOperatorKind.LOGICAL_OR:
          case BinaryOperatorKind.IF_NULL:
            reporter.internalError(
                node, "Unexpected binary operator '${operator}'.");
            break;
        }
        if (isValidConstant) {
          // TODO(johnniwinther): Handle potentially invalid constant
          // expressions.
          ConstantExpression constant = new BinaryConstantExpression(
              leftResult.constant, operator, rightResult.constant);
          registry.setConstant(node, constant);
          result = new ConstantResult(node, constant);
        }
      }
    }

    if (semantics != null) {
      // TODO(johnniwinther): Support invalid super access as an
      // [AccessSemantics].
      SendStructure sendStructure;
      switch (operator.kind) {
        case BinaryOperatorKind.EQ:
          sendStructure = new EqualsStructure(semantics);
          break;
        case BinaryOperatorKind.NOT_EQ:
          sendStructure = new NotEqualsStructure(semantics);
          break;
        case BinaryOperatorKind.INDEX:
          sendStructure = new IndexStructure(semantics);
          break;
        case BinaryOperatorKind.ADD:
        case BinaryOperatorKind.SUB:
        case BinaryOperatorKind.MUL:
        case BinaryOperatorKind.DIV:
        case BinaryOperatorKind.IDIV:
        case BinaryOperatorKind.MOD:
        case BinaryOperatorKind.SHL:
        case BinaryOperatorKind.SHR:
        case BinaryOperatorKind.GTEQ:
        case BinaryOperatorKind.GT:
        case BinaryOperatorKind.LTEQ:
        case BinaryOperatorKind.LT:
        case BinaryOperatorKind.AND:
        case BinaryOperatorKind.OR:
        case BinaryOperatorKind.XOR:
          sendStructure = new BinaryStructure(semantics, operator);
          break;
        case BinaryOperatorKind.LOGICAL_AND:
        case BinaryOperatorKind.LOGICAL_OR:
        case BinaryOperatorKind.IF_NULL:
          reporter.internalError(
              node, "Unexpected binary operator '${operator}'.");
          break;
      }
      registry.registerSendStructure(node, sendStructure);
    }
    return result;
  }

  /// Handle an invocation of an expression, like `(){}()` or `(foo)()`.
  ResolutionResult handleExpressionInvoke(Send node) {
    assert(node.isCall, failedAt(node, "Unexpected expression: $node"));
    Node expression = node.selector;
    visitExpression(expression);
    CallStructure callStructure =
        resolveArguments(node.argumentsNode).callStructure;
    Selector selector = callStructure.callSelector;
    // TODO(23998): Remove this when all information goes through the
    // [SendStructure].
    registry.setSelector(node, selector);
    registry.registerDynamicUse(new DynamicUse(selector, null));
    registry.registerSendStructure(
        node, new InvokeStructure(const DynamicAccess.expression(), selector));
    return const NoneResult();
  }

  /// Handle access of a property of [name] on `this`, like `this.name` and
  /// `this.name()`, or `name` and `name()` in instance context.
  ResolutionResult handleThisPropertyAccess(Send node, Name name) {
    AccessSemantics semantics = new DynamicAccess.thisProperty(name);
    return handleDynamicAccessSemantics(node, name, semantics);
  }

  /// Handle update of a property of [name] on `this`, like `this.name = b` and
  /// `this.name++`, or `name = b` and `name++` in instance context.
  ResolutionResult handleThisPropertyUpdate(
      SendSet node, Name name, Element element) {
    AccessSemantics semantics = new DynamicAccess.thisProperty(name);
    return handleDynamicUpdateSemantics(node, name, element, semantics);
  }

  /// Handle access on `this`, like `this()` and `this` when it is parsed as a
  /// [Send] node.
  ResolutionResult handleThisAccess(Send node) {
    if (node.isCall) {
      CallStructure callStructure =
          resolveArguments(node.argumentsNode).callStructure;
      Selector selector = callStructure.callSelector;
      // TODO(johnniwinther): Handle invalid this access as an
      // [AccessSemantics].
      AccessSemantics accessSemantics = checkThisAccess(node);
      if (accessSemantics == null) {
        accessSemantics = const DynamicAccess.thisAccess();
        registry.registerDynamicUse(new DynamicUse(selector, null));
      }
      registry.registerSendStructure(
          node, new InvokeStructure(accessSemantics, selector));
      // TODO(23998): Remove this when all information goes through
      // the [SendStructure].
      registry.setSelector(node, selector);
      return const NoneResult();
    } else {
      // TODO(johnniwinther): Handle get of `this` when it is a [Send] node.
      reporter.internalError(node, "Unexpected node '$node'.");
    }
    return const NoneResult();
  }

  /// Handle access of a super property, like `super.foo` and `super.foo()`.
  ResolutionResult handleSuperPropertyAccess(Send node, Name name) {
    Element target;
    Selector selector;
    CallStructure callStructure;
    if (node.isCall) {
      callStructure = resolveArguments(node.argumentsNode).callStructure;
      selector = new Selector.call(name, callStructure);
    } else {
      selector = new Selector.getter(name);
    }
    AccessSemantics semantics = checkSuperAccess(node);
    if (semantics == null) {
      semantics = computeSuperAccessSemanticsForSelector(node, selector,
          alternateName: name.setter);
    }
    if (node.isCall) {
      bool isIncompatibleInvoke = false;
      switch (semantics.kind) {
        case AccessKind.SUPER_METHOD:
          MethodElement superMethod = semantics.element;
          superMethod.computeType(resolution);
          if (!callStructure.signatureApplies(superMethod.parameterStructure)) {
            registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
            registry.registerDynamicUse(new DynamicUse(selector, null));
            registry.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
            isIncompatibleInvoke = true;
          } else {
            registry.registerStaticUse(
                new StaticUse.superInvoke(superMethod, callStructure));
          }
          break;
        case AccessKind.SUPER_FIELD:
        case AccessKind.SUPER_FINAL_FIELD:
        case AccessKind.SUPER_GETTER:
          MemberElement superMember = semantics.element;
          registry.registerStaticUse(new StaticUse.superGet(superMember));
          selector = callStructure.callSelector;
          registry.registerDynamicUse(new DynamicUse(selector, null));
          break;
        case AccessKind.SUPER_SETTER:
        case AccessKind.UNRESOLVED_SUPER:
          // NoSuchMethod registered in [computeSuperSemantics].
          break;
        case AccessKind.INVALID:
          // 'super' is not allowed.
          break;
        default:
          reporter.internalError(
              node, "Unexpected super property access $semantics.");
          break;
      }
      registry.registerSendStructure(
          node,
          isIncompatibleInvoke
              ? new IncompatibleInvokeStructure(semantics, selector)
              : new InvokeStructure(semantics, selector));
    } else {
      switch (semantics.kind) {
        case AccessKind.SUPER_METHOD:
          // TODO(johnniwinther): Method this should be registered as a
          // closurization.
          MethodElement superMethod = semantics.element;
          registry.registerStaticUse(new StaticUse.superTearOff(superMethod));
          break;
        case AccessKind.SUPER_FIELD:
        case AccessKind.SUPER_FINAL_FIELD:
        case AccessKind.SUPER_GETTER:
          MemberElement superMember = semantics.element;
          registry.registerStaticUse(new StaticUse.superGet(superMember));
          break;
        case AccessKind.SUPER_SETTER:
        case AccessKind.UNRESOLVED_SUPER:
          // NoSuchMethod registered in [computeSuperSemantics].
          break;
        case AccessKind.INVALID:
          // 'super' is not allowed.
          break;
        default:
          reporter.internalError(
              node, "Unexpected super property access $semantics.");
          break;
      }
      registry.registerSendStructure(node, new GetStructure(semantics));
    }
    target = semantics.element;

    // TODO(23998): Remove these when all information goes through
    // the [SendStructure].
    registry.useElement(node, target);
    registry.setSelector(node, selector);
    return const NoneResult();
  }

  /// Handle a [Send] whose selector is an [Operator], like `a && b`, `a is T`,
  /// `a + b`, and `~a`.
  // ignore: MISSING_RETURN
  ResolutionResult handleOperatorSend(Send node) {
    String operatorText = node.selector.asOperator().source;
    if (operatorText == 'is') {
      return handleIs(node);
    } else if (operatorText == 'as') {
      return handleAs(node);
    } else if (node.arguments.isEmpty) {
      UnaryOperator operator = UnaryOperator.parse(operatorText);
      if (operator == null) {
        return handleUnresolvedUnary(node, operatorText);
      } else {
        switch (operator.kind) {
          case UnaryOperatorKind.NOT:
            return handleNot(node, operator);
          case UnaryOperatorKind.COMPLEMENT:
          case UnaryOperatorKind.NEGATE:
            assert(operator.isUserDefinable,
                failedAt(node, "Unexpected unary operator '${operator}'."));
            return handleUserDefinableUnary(node, operator);
        }
      }
    } else {
      BinaryOperator operator = BinaryOperator.parse(operatorText);
      if (operator == null) {
        return handleUnresolvedBinary(node, operatorText);
      } else {
        switch (operator.kind) {
          case BinaryOperatorKind.LOGICAL_AND:
            return handleLogicalAnd(node);
          case BinaryOperatorKind.LOGICAL_OR:
            return handleLogicalOr(node);
          case BinaryOperatorKind.IF_NULL:
            return handleIfNull(node);
          case BinaryOperatorKind.EQ:
          case BinaryOperatorKind.NOT_EQ:
          case BinaryOperatorKind.INDEX:
          case BinaryOperatorKind.ADD:
          case BinaryOperatorKind.SUB:
          case BinaryOperatorKind.MUL:
          case BinaryOperatorKind.DIV:
          case BinaryOperatorKind.IDIV:
          case BinaryOperatorKind.MOD:
          case BinaryOperatorKind.SHL:
          case BinaryOperatorKind.SHR:
          case BinaryOperatorKind.GTEQ:
          case BinaryOperatorKind.GT:
          case BinaryOperatorKind.LTEQ:
          case BinaryOperatorKind.LT:
          case BinaryOperatorKind.AND:
          case BinaryOperatorKind.OR:
          case BinaryOperatorKind.XOR:
            return handleUserDefinableBinary(node, operator);
        }
      }
    }
  }

  /// Handle qualified access to an unresolved static class member, like `a.b`
  /// or `a.b()` where `a` is a class and `b` is unresolved.
  ResolutionResult handleUnresolvedStaticMemberAccess(
      Send node, Name name, ClassElement receiverClass) {
    // TODO(johnniwinther): Share code with [handleStaticInstanceMemberAccess]
    // and [handlePrivateStaticMemberAccess].
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    // TODO(johnniwinther): Produce a different error if [name] is resolves to
    // a constructor.

    // TODO(johnniwinther): With the simplified [TreeElements] invariant,
    // try to resolve injected elements if [currentClass] is in the patch
    // library of [receiverClass].

    // TODO(karlklose): this should be reported by the caller of
    // [resolveSend] to select better warning messages for getters and
    // setters.
    ErroneousElement error = reportAndCreateErroneousElement(
        node,
        name.text,
        MessageKind.UNDEFINED_GETTER,
        {'className': receiverClass.name, 'memberName': name.text});
    // TODO(johnniwinther): Add an [AccessSemantics] for unresolved static
    // member access.
    return handleErroneousAccess(
        node, name, new StaticAccess.unresolved(error));
  }

  /// Handle qualified update to an unresolved static class member, like
  /// `a.b = c` or `a.b++` where `a` is a class and `b` is unresolved.
  ResolutionResult handleUnresolvedStaticMemberUpdate(
      SendSet node, Name name, ClassElement receiverClass) {
    // TODO(johnniwinther): Share code with [handleStaticInstanceMemberUpdate]
    // and [handlePrivateStaticMemberUpdate].
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    // TODO(johnniwinther): Produce a different error if [name] is resolves to
    // a constructor.

    // TODO(johnniwinther): With the simplified [TreeElements] invariant,
    // try to resolve injected elements if [currentClass] is in the patch
    // library of [receiverClass].

    // TODO(johnniwinther): Produce a different error for complex update.
    ErroneousElement error = reportAndCreateErroneousElement(
        node,
        name.text,
        MessageKind.UNDEFINED_GETTER,
        {'className': receiverClass.name, 'memberName': name.text});
    // TODO(johnniwinther): Add an [AccessSemantics] for unresolved static
    // member access.
    return handleUpdate(node, name, new StaticAccess.unresolved(error));
  }

  /// Handle qualified access of an instance member, like `a.b` or `a.b()` where
  /// `a` is a class and `b` is a non-static member.
  ResolutionResult handleStaticInstanceMemberAccess(
      Send node, Name name, ClassElement receiverClass, Element member) {
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    // TODO(johnniwinther): With the simplified [TreeElements] invariant,
    // try to resolve injected elements if [currentClass] is in the patch
    // library of [receiverClass].

    // TODO(karlklose): this should be reported by the caller of
    // [resolveSend] to select better warning messages for getters and
    // setters.
    ErroneousElement error = reportAndCreateErroneousElement(
        node,
        name.text,
        MessageKind.MEMBER_NOT_STATIC,
        {'className': receiverClass.name, 'memberName': name});

    // TODO(johnniwinther): Add an [AccessSemantics] for statically accessed
    // instance members.
    return handleErroneousAccess(
        node, name, new StaticAccess.unresolved(error));
  }

  /// Handle qualified update of an instance member, like `a.b = c` or `a.b++`
  /// where `a` is a class and `b` is a non-static member.
  ResolutionResult handleStaticInstanceMemberUpdate(
      SendSet node, Name name, ClassElement receiverClass, Element member) {
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    // TODO(johnniwinther): With the simplified [TreeElements] invariant,
    // try to resolve injected elements if [currentClass] is in the patch
    // library of [receiverClass].

    // TODO(johnniwinther): Produce a different error for complex update.
    ErroneousElement error = reportAndCreateErroneousElement(
        node,
        name.text,
        MessageKind.MEMBER_NOT_STATIC,
        {'className': receiverClass.name, 'memberName': name});

    // TODO(johnniwinther): Add an [AccessSemantics] for statically accessed
    // instance members.
    return handleUpdate(node, name, new StaticAccess.unresolved(error));
  }

  /// Handle qualified access of an inaccessible private static class member,
  /// like `a._b` or `a._b()` where `a` is class, `_b` is static member of `a`
  /// but `a` is not defined in the current library.
  ResolutionResult handlePrivateStaticMemberAccess(
      Send node, Name name, ClassElement receiverClass, Element member) {
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    ErroneousElement error = reportAndCreateErroneousElement(
        node,
        name.text,
        MessageKind.PRIVATE_ACCESS,
        {'libraryName': member.library.name, 'name': name});
    // TODO(johnniwinther): Add an [AccessSemantics] for unresolved static
    // member access.
    return handleErroneousAccess(
        node, name, new StaticAccess.unresolved(error));
  }

  /// Handle qualified update of an inaccessible private static class member,
  /// like `a._b = c` or `a._b++` where `a` is class, `_b` is static member of
  /// `a` but `a` is not defined in the current library.
  ResolutionResult handlePrivateStaticMemberUpdate(
      SendSet node, Name name, ClassElement receiverClass, Element member) {
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
    ErroneousElement error = reportAndCreateErroneousElement(
        node,
        name.text,
        MessageKind.PRIVATE_ACCESS,
        {'libraryName': member.library.name, 'name': name});
    // TODO(johnniwinther): Add an [AccessSemantics] for unresolved static
    // member access.
    return handleUpdate(node, name, new StaticAccess.unresolved(error));
  }

  /// Handle qualified access to a static member, like `a.b` or `a.b()` where
  /// `a` is a class and `b` is a static member of `a`.
  ResolutionResult handleStaticMemberAccess(
      Send node, Name memberName, ClassElement receiverClass) {
    String name = memberName.text;
    receiverClass.ensureResolved(resolution);
    if (node.isOperator) {
      // When the resolved receiver is a class, we can have two cases:
      //  1) a static send: C.foo, or
      //  2) an operator send, where the receiver is a class literal: 'C + 1'.
      // The following code that looks up the selector on the resolved
      // receiver will treat the second as the invocation of a static operator
      // if the resolved receiver is not null.
      return const NoneResult();
    }
    MembersCreator.computeClassMembersByName(
        resolution, receiverClass.declaration, name);
    Element member = receiverClass.lookupLocalMember(name);
    if (member == null) {
      return handleUnresolvedStaticMemberAccess(
          node, memberName, receiverClass);
    } else if (member.isAmbiguous) {
      return handleAmbiguousSend(node, memberName, member);
    } else if (member.isInstanceMember) {
      return handleStaticInstanceMemberAccess(
          node, memberName, receiverClass, member);
    } else if (memberName.isPrivate && memberName.library != member.library) {
      return handlePrivateStaticMemberAccess(
          node, memberName, receiverClass, member);
    } else {
      return handleStaticOrTopLevelAccess(node, memberName, member);
    }
  }

  /// Handle qualified update to a static member, like `a.b = c` or `a.b++`
  /// where `a` is a class and `b` is a static member of `a`.
  ResolutionResult handleStaticMemberUpdate(
      Send node, Name memberName, ClassElement receiverClass) {
    String name = memberName.text;
    receiverClass.ensureResolved(resolution);
    MembersCreator.computeClassMembersByName(
        resolution, receiverClass.declaration, name);
    Element member = receiverClass.lookupLocalMember(name);
    if (member == null) {
      return handleUnresolvedStaticMemberUpdate(
          node, memberName, receiverClass);
    } else if (member.isAmbiguous) {
      return handleAmbiguousUpdate(node, memberName, member);
    } else if (member.isInstanceMember) {
      return handleStaticInstanceMemberUpdate(
          node, memberName, receiverClass, member);
    } else if (memberName.isPrivate && memberName.library != member.library) {
      return handlePrivateStaticMemberUpdate(
          node, memberName, receiverClass, member);
    } else {
      return handleStaticOrTopLevelUpdate(node, memberName, member);
    }
  }

  /// Handle access to a type literal of type variable [element]. Like `T` or
  /// `T()` where 'T' is type variable.
  // TODO(johnniwinther): Remove [name] when [Selector] is not required for the
  // the [GetStructure].
  // TODO(johnniwinther): Remove [element] when it is no longer needed for
  // evaluating constants.
  ResolutionResult handleTypeVariableTypeLiteralAccess(
      Send node, Name name, TypeVariableElement element) {
    AccessSemantics semantics;
    if (!Elements.hasAccessToTypeVariable(enclosingElement, element)) {
      // TODO(johnniwinther): Add another access semantics for this.
      ErroneousElement error = reportAndCreateErroneousElement(
          node,
          name.text,
          MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
          {'typeVariableName': name},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      semantics = new StaticAccess.invalid(error);
      // TODO(johnniwinther): Clean up registration of elements and selectors
      // for this case.
    } else {
      // GENERIC_METHODS: Method type variables are not reified so we must warn
      // about the error which will occur at runtime.
      if (element.type is MethodTypeVariableType) {
        reporter.reportWarningMessage(
            node, MessageKind.TYPE_VARIABLE_FROM_METHOD_NOT_REIFIED);
      }
      semantics = new StaticAccess.typeParameterTypeLiteral(element);
    }

    registry.useElement(node, element);
    registry.registerTypeLiteral(node, element.type);

    if (node.isCall) {
      CallStructure callStructure =
          resolveArguments(node.argumentsNode).callStructure;
      Selector selector = callStructure.callSelector;
      // TODO(23998): Remove this when all information goes through
      // the [SendStructure].
      registry.setSelector(node, selector);

      registry.registerSendStructure(
          node, new InvokeStructure(semantics, selector));
    } else {
      // TODO(johnniwinther): Avoid the need for a [Selector] here.
      registry.registerSendStructure(node, new GetStructure(semantics));
    }
    return const NoneResult();
  }

  /// Handle access to a type literal of type variable [element]. Like `T = b`,
  /// `T++` or `T += b` where 'T' is type variable.
  ResolutionResult handleTypeVariableTypeLiteralUpdate(
      SendSet node, Name name, TypeVariableElement element) {
    AccessSemantics semantics;
    if (!Elements.hasAccessToTypeVariable(enclosingElement, element)) {
      // TODO(johnniwinther): Add another access semantics for this.
      ErroneousElement error = reportAndCreateErroneousElement(
          node,
          name.text,
          MessageKind.TYPE_VARIABLE_WITHIN_STATIC_MEMBER,
          {'typeVariableName': name},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      semantics = new StaticAccess.invalid(error);
    } else {
      ErroneousElement error;
      if (node.isIfNullAssignment) {
        error = reportAndCreateErroneousElement(node.selector, name.text,
            MessageKind.IF_NULL_ASSIGNING_TYPE, const {});
        // TODO(23998): Remove these when all information goes through
        // the [SendStructure].
        registry.useElement(node.selector, element);
      } else {
        error = reportAndCreateErroneousElement(
            node.selector, name.text, MessageKind.ASSIGNING_TYPE, const {});
      }

      // TODO(23998): Remove this when all information goes through
      // the [SendStructure].
      registry.useElement(node, error);
      // TODO(johnniwinther): Register only on read?
      registry.registerTypeLiteral(node, element.type);
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      semantics = new StaticAccess.typeParameterTypeLiteral(element);
    }
    return handleUpdate(node, name, semantics);
  }

  /// Handle access to a constant type literal of [type].
  // TODO(johnniwinther): Remove [name] when [Selector] is not required for the
  // the [GetStructure].
  // TODO(johnniwinther): Remove [element] when it is no longer needed for
  // evaluating constants.
  ResolutionResult handleConstantTypeLiteralAccess(
      Send node,
      Name name,
      TypeDeclarationElement element,
      ResolutionDartType type,
      ConstantAccess semantics) {
    registry.useElement(node, element);
    registry.registerTypeLiteral(node, type);

    if (node.isCall) {
      CallStructure callStructure =
          resolveArguments(node.argumentsNode).callStructure;
      Selector selector = callStructure.callSelector;
      // TODO(23998): Remove this when all information goes through
      // the [SendStructure].
      registry.setSelector(node, selector);

      // The node itself is not a constant but we register the selector (the
      // identifier that refers to the class/typedef) as a constant.
      registry.useElement(node.selector, element);
      analyzeConstantDeferred(node.selector, enforceConst: false);

      registry.registerSendStructure(
          node, new InvokeStructure(semantics, selector));
      return const NoneResult();
    } else {
      analyzeConstantDeferred(node, enforceConst: false);

      registry.setConstant(node, semantics.constant);
      registry.registerSendStructure(node, new GetStructure(semantics));
      return new ConstantResult(node, semantics.constant);
    }
  }

  /// Handle access to a constant type literal of [type].
  // TODO(johnniwinther): Remove [name] when [Selector] is not required for the
  // the [GetStructure].
  // TODO(johnniwinther): Remove [element] when it is no longer needed for
  // evaluating constants.
  ResolutionResult handleConstantTypeLiteralUpdate(
      SendSet node,
      Name name,
      TypeDeclarationElement element,
      ResolutionDartType type,
      ConstantAccess semantics) {
    // TODO(johnniwinther): Remove this when all constants are evaluated.
    resolver.constantCompiler.evaluate(semantics.constant);

    ErroneousElement error;
    if (node.isIfNullAssignment) {
      error = reportAndCreateErroneousElement(node.selector, name.text,
          MessageKind.IF_NULL_ASSIGNING_TYPE, const {});
      // TODO(23998): Remove these when all information goes through
      // the [SendStructure].
      registry.setConstant(node.selector, semantics.constant);
      registry.useElement(node.selector, element);
    } else {
      error = reportAndCreateErroneousElement(
          node.selector, name.text, MessageKind.ASSIGNING_TYPE, const {});
    }

    // TODO(23998): Remove this when all information goes through
    // the [SendStructure].
    registry.useElement(node, error);
    registry.registerTypeLiteral(node, type);
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);

    return handleUpdate(node, name, semantics);
  }

  /// Handle access to a type literal of a typedef. Like `F` or
  /// `F()` where 'F' is typedef.
  ResolutionResult handleTypedefTypeLiteralAccess(
      Send node, Name name, TypedefElement typdef) {
    typdef.ensureResolved(resolution);
    ResolutionDartType type = typdef.rawType;
    ConstantExpression constant = new TypeConstantExpression(type, name.text);
    AccessSemantics semantics = new ConstantAccess.typedefTypeLiteral(constant);
    return handleConstantTypeLiteralAccess(node, name, typdef, type, semantics);
  }

  /// Handle access to a type literal of a typedef. Like `F = b`, `F++` or
  /// `F += b` where 'F' is typedef.
  ResolutionResult handleTypedefTypeLiteralUpdate(
      SendSet node, Name name, TypedefElement typdef) {
    typdef.ensureResolved(resolution);
    ResolutionDartType type = typdef.rawType;
    ConstantExpression constant = new TypeConstantExpression(type, name.text);
    AccessSemantics semantics = new ConstantAccess.typedefTypeLiteral(constant);
    return handleConstantTypeLiteralUpdate(node, name, typdef, type, semantics);
  }

  /// Handle access to a type literal of the type 'dynamic'. Like `dynamic` or
  /// `dynamic()`.
  ResolutionResult handleDynamicTypeLiteralAccess(Send node) {
    ResolutionDartType type = const ResolutionDynamicType();
    ConstantExpression constant = new TypeConstantExpression(
        // TODO(johnniwinther): Use [type] when evaluation of constants is done
        // directly on the constant expressions.
        node.isCall ? commonElements.typeType : type,
        'dynamic');
    AccessSemantics semantics = new ConstantAccess.dynamicTypeLiteral(constant);
    ClassElement typeClass = commonElements.typeClass;
    return handleConstantTypeLiteralAccess(
        node, const PublicName('dynamic'), typeClass, type, semantics);
  }

  /// Handle update to a type literal of the type 'dynamic'. Like `dynamic++` or
  /// `dynamic = 0`.
  ResolutionResult handleDynamicTypeLiteralUpdate(SendSet node) {
    ResolutionDartType type = const ResolutionDynamicType();
    ConstantExpression constant =
        new TypeConstantExpression(const ResolutionDynamicType(), 'dynamic');
    AccessSemantics semantics = new ConstantAccess.dynamicTypeLiteral(constant);
    ClassElement typeClass = commonElements.typeClass;
    return handleConstantTypeLiteralUpdate(
        node, const PublicName('dynamic'), typeClass, type, semantics);
  }

  /// Handle access to a type literal of a class. Like `C` or
  /// `C()` where 'C' is class.
  ResolutionResult handleClassTypeLiteralAccess(
      Send node, Name name, ClassElement cls) {
    cls.ensureResolved(resolution);
    ResolutionDartType type = cls.rawType;
    ConstantExpression constant = new TypeConstantExpression(type, name.text);
    AccessSemantics semantics = new ConstantAccess.classTypeLiteral(constant);
    return handleConstantTypeLiteralAccess(node, name, cls, type, semantics);
  }

  /// Handle access to a type literal of a class. Like `C = b`, `C++` or
  /// `C += b` where 'C' is class.
  ResolutionResult handleClassTypeLiteralUpdate(
      SendSet node, Name name, ClassElement cls) {
    cls.ensureResolved(resolution);
    ResolutionDartType type = cls.rawType;
    ConstantExpression constant = new TypeConstantExpression(type, name.text);
    AccessSemantics semantics = new ConstantAccess.classTypeLiteral(constant);
    return handleConstantTypeLiteralUpdate(node, name, cls, type, semantics);
  }

  /// Handle a [Send] that resolves to a [prefix]. Like `prefix` in
  /// `prefix.Class` or `prefix` in `prefix()`, the latter being a compile time
  /// error.
  ResolutionResult handleClassSend(Send node, Name name, ClassElement cls) {
    cls.ensureResolved(resolution);
    if (sendIsMemberAccess) {
      registry.useElement(node, cls);
      return new PrefixResult(null, cls);
    } else {
      // `C` or `C()` where 'C' is a class.
      return handleClassTypeLiteralAccess(node, name, cls);
    }
  }

  /// Compute a [DeferredPrefixStructure] for [node].
  ResolutionResult handleDeferredAccess(
      Send node, PrefixElement prefix, ResolutionResult result) {
    assert(
        prefix.isDeferred, failedAt(node, "Prefix $prefix is not deferred."));
    SendStructure sendStructure = registry.getSendStructure(node);
    assert(
        sendStructure != null, failedAt(node, "No SendStructure for $node."));
    registry.registerSendStructure(
        node, new DeferredPrefixStructure(prefix, sendStructure));
    if (result.isConstant) {
      ConstantExpression constant = new DeferredConstantExpression(
          result.constant, prefix.deferredImport);
      registry.setConstant(node, constant);
      result = new ConstantResult(node, constant);
    }
    return result;
  }

  /// Handle qualified [Send] where the receiver resolves to a [prefix],
  /// like `prefix.toplevelFunction()` or `prefix.Class.staticField` where
  /// `prefix` is a library prefix.
  ResolutionResult handleLibraryPrefixSend(
      Send node, Name name, PrefixElement prefix) {
    ResolutionResult result;
    Element member = prefix.lookupLocalMember(name.text);
    if (member == null) {
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      Element error = reportAndCreateErroneousElement(
          node,
          name.text,
          MessageKind.NO_SUCH_LIBRARY_MEMBER,
          {'libraryName': prefix.name, 'memberName': name});
      result = handleUnresolvedAccess(node, name, error);
    } else {
      result = handleResolvedSend(node, name, member);
    }
    if (result.kind == ResultKind.PREFIX) {
      // [member] is a class prefix of a static access like `prefix.Class` of
      // `prefix.Class.foo`. No need to call [handleDeferredAccess]; it will
      // called on the parent `prefix.Class.foo` node.
      result = new PrefixResult(prefix, result.element);
    } else if (prefix.isDeferred &&
        (member == null || !member.isDeferredLoaderGetter)) {
      result = handleDeferredAccess(node, prefix, result);
    }
    return result;
  }

  /// Handle qualified [SendSet] where the receiver resolves to a [prefix],
  /// like `prefix.toplevelField = b` or `prefix.Class.staticField++` where
  /// `prefix` is a library prefix.
  ResolutionResult handleLibraryPrefixSendSet(
      SendSet node, Name name, PrefixElement prefix) {
    ResolutionResult result;
    Element member = prefix.lookupLocalMember(name.text);
    if (member == null) {
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      Element error = reportAndCreateErroneousElement(
          node,
          name.text,
          MessageKind.NO_SUCH_LIBRARY_MEMBER,
          {'libraryName': prefix.name, 'memberName': name});
      return handleUpdate(node, name, new StaticAccess.unresolved(error));
    } else {
      result = handleResolvedSendSet(node, name, member);
    }
    if (result.kind == ResultKind.PREFIX) {
      // [member] is a class prefix of a static access like `prefix.Class` of
      // `prefix.Class.foo`. No need to call [handleDeferredAccess]; it will
      // called on the parent `prefix.Class.foo` node.
      result = new PrefixResult(prefix, result.element);
    } else if (prefix.isDeferred &&
        (member == null || !member.isDeferredLoaderGetter)) {
      result = handleDeferredAccess(node, prefix, result);
    }
    return result;
  }

  /// Handle a [Send] that resolves to a [prefix]. Like `prefix` in
  /// `prefix.Class` or `prefix` in `prefix()`, the latter being a compile time
  /// error.
  ResolutionResult handleLibraryPrefix(
      Send node, Name name, PrefixElement prefix) {
    if ((ElementCategory.PREFIX & allowedCategory) == 0) {
      ErroneousElement error = reportAndCreateErroneousElement(
          node, name.text, MessageKind.PREFIX_AS_EXPRESSION, {'prefix': name},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      return handleErroneousAccess(node, name, new StaticAccess.invalid(error));
    }
    if (prefix.isDeferred) {
      // TODO(23998): Remove this when deferred access is detected
      // through a [SendStructure].
      registry.useElement(node.selector, prefix);
    }
    registry.useElement(node, prefix);
    return new PrefixResult(prefix, null);
  }

  /// Handle qualified [Send] where the receiver resolves to an [Element], like
  /// `a.b` where `a` is a prefix or a class.
  ResolutionResult handlePrefixSend(
      Send node, Name name, PrefixResult prefixResult) {
    Element element = prefixResult.element;
    if (element.isPrefix) {
      if (node.isConditional) {
        return handleLibraryPrefix(node, name, element);
      } else {
        return handleLibraryPrefixSend(node, name, element);
      }
    } else {
      assert(element.isClass);
      ResolutionResult result = handleStaticMemberAccess(node, name, element);
      if (prefixResult.isDeferred) {
        result = handleDeferredAccess(node, prefixResult.prefix, result);
      }
      return result;
    }
  }

  /// Handle qualified [SendSet] where the receiver resolves to an [Element],
  /// like `a.b = c` where `a` is a prefix or a class.
  ResolutionResult handlePrefixSendSet(
      SendSet node, Name name, PrefixResult prefixResult) {
    Element element = prefixResult.element;
    if (element.isPrefix) {
      if (node.isConditional) {
        return handleLibraryPrefix(node, name, element);
      } else {
        return handleLibraryPrefixSendSet(node, name, element);
      }
    } else {
      assert(element.isClass);
      ResolutionResult result = handleStaticMemberUpdate(node, name, element);
      if (prefixResult.isDeferred) {
        result = handleDeferredAccess(node, prefixResult.prefix, result);
      }
      return result;
    }
  }

  /// Handle dynamic access of [semantics].
  ResolutionResult handleDynamicAccessSemantics(
      Send node, Name name, AccessSemantics semantics) {
    SendStructure sendStructure;
    Selector selector;
    if (node.isCall) {
      CallStructure callStructure =
          resolveArguments(node.argumentsNode).callStructure;
      selector = new Selector.call(name, callStructure);
      registry.registerDynamicUse(new DynamicUse(selector, null));
      sendStructure = new InvokeStructure(semantics, selector);
    } else {
      assert(node.isPropertyAccess, failedAt(node));
      selector = new Selector.getter(name);
      registry.registerDynamicUse(new DynamicUse(selector, null));
      sendStructure = new GetStructure(semantics);
    }
    registry.registerSendStructure(node, sendStructure);
    // TODO(23998): Remove this when all information goes through
    // the [SendStructure].
    registry.setSelector(node, selector);
    return const NoneResult();
  }

  /// Handle dynamic update of [semantics].
  ResolutionResult handleDynamicUpdateSemantics(
      SendSet node, Name name, Element element, AccessSemantics semantics) {
    Selector getterSelector = new Selector.getter(name);
    Selector setterSelector = new Selector.setter(name.setter);
    registry.registerDynamicUse(new DynamicUse(setterSelector, null));
    if (node.isComplex) {
      registry.registerDynamicUse(new DynamicUse(getterSelector, null));
    }

    // TODO(23998): Remove these when elements are only accessed through the
    // send structure.
    Element getter = element;
    Element setter = element;
    if (element != null && element.isAbstractField) {
      AbstractFieldElement abstractField = element;
      getter = abstractField.getter;
      setter = abstractField.setter;
    }
    if (setter != null) {
      registry.useElement(node, setter);
      if (getter != null && node.isComplex) {
        registry.useElement(node.selector, getter);
      }
    }

    return handleUpdate(node, name, semantics);
  }

  /// Handle `this` as a qualified property, like `a.this`.
  ResolutionResult handleQualifiedThisAccess(Send node, Name name) {
    ErroneousElement error = reportAndCreateErroneousElement(
        node.selector, name.text, MessageKind.THIS_PROPERTY, {},
        isError: true);
    registry.registerFeature(Feature.COMPILE_TIME_ERROR);
    AccessSemantics accessSemantics = new StaticAccess.invalid(error);
    return handleErroneousAccess(node, name, accessSemantics);
  }

  /// Handle a qualified [Send], that is where the receiver is non-null, like
  /// `a.b`, `a.b()`, `this.a()` and `super.a()`.
  ResolutionResult handleQualifiedSend(Send node) {
    Identifier selector = node.selector.asIdentifier();
    String text = selector.source;
    Name name = new Name(text, enclosingElement.library);
    if (text == 'this') {
      return handleQualifiedThisAccess(node, name);
    } else if (node.isSuperCall) {
      return handleSuperPropertyAccess(node, name);
    } else if (node.receiver.isThis()) {
      AccessSemantics semantics = checkThisAccess(node);
      if (semantics == null) {
        return handleThisPropertyAccess(node, name);
      } else {
        // TODO(johnniwinther): Handle invalid this access as an
        // [AccessSemantics].
        return handleErroneousAccess(node, name, semantics);
      }
    }
    ResolutionResult result = visitExpressionPrefix(node.receiver);
    if (result.kind == ResultKind.PREFIX) {
      return handlePrefixSend(node, name, result);
    } else if (node.isConditional) {
      registry.registerConstantLiteral(new NullConstantExpression());
      registry.registerDynamicUse(new DynamicUse(Selectors.equals, null));
      return handleDynamicAccessSemantics(
          node, name, new DynamicAccess.ifNotNullProperty(name));
    } else {
      // Handle dynamic property access, like `a.b` or `a.b()` where `a` is not
      // a prefix or class.
      // TODO(johnniwinther): Use the `element` of [result].
      return handleDynamicAccessSemantics(
          node, name, new DynamicAccess.dynamicProperty(name));
    }
  }

  /// Handle a qualified [SendSet], that is where the receiver is non-null, like
  /// `a.b = c`, `a.b++`, and `a.b += c`.
  ResolutionResult handleQualifiedSendSet(SendSet node) {
    Identifier selector = node.selector.asIdentifier();
    String text = selector.source;
    Name name = new Name(text, enclosingElement.library);
    if (text == 'this') {
      return handleQualifiedThisAccess(node, name);
    } else if (node.receiver.isThis()) {
      AccessSemantics semantics = checkThisAccess(node);
      if (semantics == null) {
        return handleThisPropertyUpdate(node, name, null);
      } else {
        // TODO(johnniwinther): Handle invalid this access as an
        // [AccessSemantics].
        return handleUpdate(node, name, semantics);
      }
    }
    ResolutionResult result = visitExpressionPrefix(node.receiver);
    if (result.kind == ResultKind.PREFIX) {
      return handlePrefixSendSet(node, name, result);
    } else if (node.isConditional) {
      registry.registerConstantLiteral(new NullConstantExpression());
      registry.registerDynamicUse(new DynamicUse(Selectors.equals, null));
      return handleDynamicUpdateSemantics(
          node, name, null, new DynamicAccess.ifNotNullProperty(name));
    } else {
      // Handle dynamic property access, like `a.b = c`, `a.b++` or `a.b += c`
      // where `a` is not a prefix or class.
      // TODO(johnniwinther): Use the `element` of [result].
      return handleDynamicUpdateSemantics(
          node, name, null, new DynamicAccess.dynamicProperty(name));
    }
  }

  /// Handle access unresolved access to [name] in a non-instance context.
  ResolutionResult handleUnresolvedAccess(
      Send node, Name name, Element element) {
    // TODO(johnniwinther): Support unresolved top level access as an
    // [AccessSemantics].
    AccessSemantics semantics = new StaticAccess.unresolved(element);
    return handleErroneousAccess(node, name, semantics);
  }

  /// Handle erroneous access of [element] of the given [semantics].
  ResolutionResult handleErroneousAccess(
      Send node, Name name, AccessSemantics semantics) {
    SendStructure sendStructure;
    Selector selector;
    if (node.isCall) {
      CallStructure callStructure =
          resolveArguments(node.argumentsNode).callStructure;
      selector = new Selector.call(name, callStructure);
      registry.registerDynamicUse(new DynamicUse(selector, null));
      sendStructure = new InvokeStructure(semantics, selector);
    } else {
      assert(node.isPropertyAccess, failedAt(node));
      selector = new Selector.getter(name);
      registry.registerDynamicUse(new DynamicUse(selector, null));
      sendStructure = new GetStructure(semantics);
    }
    // TODO(23998): Remove this when all information goes through
    // the [SendStructure].
    registry.setSelector(node, selector);
    registry.useElement(node, semantics.element);
    registry.registerSendStructure(node, sendStructure);
    return const NoneResult();
  }

  /// Handle access to an ambiguous element, that is, a name imported twice.
  ResolutionResult handleAmbiguousSend(
      Send node, Name name, AmbiguousElement element) {
    ErroneousElement error = reportAndCreateErroneousElement(
        node, name.text, element.messageKind, element.messageArguments,
        infos: element.computeInfos(enclosingElement, reporter));
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);

    // TODO(johnniwinther): Support ambiguous access as an [AccessSemantics].
    AccessSemantics semantics = new StaticAccess.unresolved(error);
    return handleErroneousAccess(node, name, semantics);
  }

  /// Handle update to an ambiguous element, that is, a name imported twice.
  ResolutionResult handleAmbiguousUpdate(
      SendSet node, Name name, AmbiguousElement element) {
    ErroneousElement error = reportAndCreateErroneousElement(
        node, name.text, element.messageKind, element.messageArguments,
        infos: element.computeInfos(enclosingElement, reporter));
    registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);

    // TODO(johnniwinther): Support ambiguous access as an [AccessSemantics].
    AccessSemantics accessSemantics = new StaticAccess.unresolved(error);
    return handleUpdate(node, name, accessSemantics);
  }

  /// Report access of an instance [member] from a non-instance context.
  AccessSemantics reportStaticInstanceAccess(Send node, Name name) {
    ErroneousElement error = reportAndCreateErroneousElement(
        node, name.text, MessageKind.NO_INSTANCE_AVAILABLE, {'name': name},
        isError: true);
    // TODO(johnniwinther): Support static instance access as an
    // [AccessSemantics].
    registry.registerFeature(Feature.COMPILE_TIME_ERROR);
    return new StaticAccess.invalid(error);
  }

  /// Handle access of a parameter, local variable or local function.
  ResolutionResult handleLocalAccess(Send node, Name name, Element element) {
    ResolutionResult result = const NoneResult();
    AccessSemantics semantics = computeLocalAccessSemantics(node, element);
    Selector selector;
    if (node.isCall) {
      CallStructure callStructure =
          resolveArguments(node.argumentsNode).callStructure;
      selector = new Selector.call(name, callStructure);
      bool isIncompatibleInvoke = false;
      switch (semantics.kind) {
        case AccessKind.LOCAL_FUNCTION:
          LocalFunctionElementX function = semantics.element;
          function.computeType(resolution);
          if (!callStructure.signatureApplies(function.parameterStructure)) {
            registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
            registry.registerDynamicUse(new DynamicUse(selector, null));
            isIncompatibleInvoke = true;
          }
          break;
        case AccessKind.PARAMETER:
        case AccessKind.FINAL_PARAMETER:
        case AccessKind.LOCAL_VARIABLE:
        case AccessKind.FINAL_LOCAL_VARIABLE:
          selector = callStructure.callSelector;
          registry.registerDynamicUse(new DynamicUse(selector, null));
          break;
        default:
          reporter.internalError(node, "Unexpected local access $semantics.");
          break;
      }
      registry.registerSendStructure(
          node,
          isIncompatibleInvoke
              ? new IncompatibleInvokeStructure(semantics, selector)
              : new InvokeStructure(semantics, selector));
    } else {
      switch (semantics.kind) {
        case AccessKind.LOCAL_VARIABLE:
        case AccessKind.LOCAL_FUNCTION:
          result = new ElementResult(element);
          break;
        case AccessKind.PARAMETER:
        case AccessKind.FINAL_PARAMETER:
          if (constantState == ConstantState.CONSTANT_INITIALIZER) {
            ParameterElement parameter = element;
            if (parameter.isNamed) {
              result = new ConstantResult(
                  node, new NamedArgumentReference(parameter.name),
                  element: element);
            } else {
              result = new ConstantResult(
                  node,
                  new PositionalArgumentReference(parameter
                      .functionDeclaration.parameters
                      .indexOf(parameter)),
                  element: element);
            }
          } else {
            result = new ElementResult(element);
          }
          break;
        case AccessKind.FINAL_LOCAL_VARIABLE:
          if (element.isConst) {
            LocalVariableElement local = element;
            result = new ConstantResult(
                node, new LocalVariableConstantExpression(local),
                element: element);
          } else {
            result = new ElementResult(element);
          }
          break;
        default:
          reporter.internalError(node, "Unexpected local access $semantics.");
          break;
      }
      selector = new Selector.getter(name);
      registry.registerSendStructure(node, new GetStructure(semantics));
    }

    // TODO(23998): Remove these when all information goes through
    // the [SendStructure].
    registry.useElement(node, element);
    registry.setSelector(node, selector);

    registerPotentialAccessInClosure(node, element);

    return result;
  }

  /// Handle update of a parameter, local variable or local function.
  ResolutionResult handleLocalUpdate(Send node, Name name, Element element) {
    AccessSemantics semantics;
    ErroneousElement error;
    if (element.isRegularParameter) {
      if (element.isFinal) {
        error = reportAndCreateErroneousElement(node.selector, name.text,
            MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER, {'name': name});
        semantics = new StaticAccess.finalParameter(element);
      } else {
        semantics = new StaticAccess.parameter(element);
      }
    } else if (element.isInitializingFormal) {
      error = reportAndCreateErroneousElement(node.selector, name.text,
          MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER, {'name': name});
      semantics = new StaticAccess.finalParameter(element);
    } else if (element.isVariable) {
      if (element.isFinal || element.isConst) {
        error = reportAndCreateErroneousElement(node.selector, name.text,
            MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER, {'name': name});
        semantics = new StaticAccess.finalLocalVariable(element);
      } else {
        semantics = new StaticAccess.localVariable(element);
      }
    } else {
      assert(element.isFunction, failedAt(node, "Unexpected local $element."));
      error = reportAndCreateErroneousElement(
          node.selector, name.text, MessageKind.ASSIGNING_METHOD, const {});
      semantics = new StaticAccess.localFunction(element);
    }
    if (isPotentiallyMutableTarget(element)) {
      registry.registerPotentialMutation(element, node);
      if (enclosingElement != element.enclosingElement) {
        registry.registerPotentialMutationInClosure(element, node);
      }
      for (Node scope in promotionScope) {
        registry.registerPotentialMutationIn(scope, element, node);
      }
    }

    ResolutionResult result = handleUpdate(node, name, semantics);
    if (error != null) {
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      // TODO(23998): Remove this when all information goes through
      // the [SendStructure].
      registry.useElement(node, error);
    }
    return result;
  }

  /// Handle access of a static or top level [element].
  ResolutionResult handleStaticOrTopLevelAccess(
      Send node, Name name, Element element) {
    ResolutionResult result = const NoneResult();
    MemberElement member;
    if (element.isAbstractField) {
      AbstractFieldElement abstractField = element;
      if (abstractField.getter != null) {
        member = abstractField.getter;
      } else {
        member = abstractField.setter;
      }
    } else {
      member = element;
    }
    // TODO(johnniwinther): Needed to provoke a parsing and with it discovery
    // of parse errors to make [element] erroneous. Fix this!
    member.computeType(resolution);

    if (resolution.commonElements.isMirrorSystemGetNameFunction(member) &&
        !resolution.mirrorUsageAnalyzerTask.hasMirrorUsage(enclosingElement)) {
      reporter.reportHintMessage(
          node.selector, MessageKind.STATIC_FUNCTION_BLOAT, {
        'class': resolution.commonElements.mirrorSystemClass.name,
        'name': member.name
      });
    }

    Selector selector;
    AccessSemantics semantics =
        computeStaticOrTopLevelAccessSemantics(node, member);
    if (node.isCall) {
      ArgumentsResult argumentsResult = resolveArguments(node.argumentsNode);
      CallStructure callStructure = argumentsResult.callStructure;
      selector = new Selector.call(name, callStructure);

      bool isIncompatibleInvoke = false;
      switch (semantics.kind) {
        case AccessKind.STATIC_METHOD:
        case AccessKind.TOPLEVEL_METHOD:
          MethodElement method = semantics.element;
          method.computeType(resolution);
          if (!callStructure.signatureApplies(method.parameterStructure)) {
            registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
            registry.registerDynamicUse(new DynamicUse(selector, null));
            isIncompatibleInvoke = true;
          } else {
            registry.registerStaticUse(
                new StaticUse.staticInvoke(method, callStructure));
            handleForeignCall(node, semantics.element, callStructure);
            if (method == resolution.commonElements.identicalFunction &&
                argumentsResult.isValidAsConstant) {
              result = new ConstantResult(
                  node,
                  new IdenticalConstantExpression(
                      argumentsResult.argumentResults[0].constant,
                      argumentsResult.argumentResults[1].constant));
            }
          }
          break;
        case AccessKind.STATIC_FIELD:
        case AccessKind.FINAL_STATIC_FIELD:
        case AccessKind.STATIC_GETTER:
        case AccessKind.TOPLEVEL_FIELD:
        case AccessKind.FINAL_TOPLEVEL_FIELD:
        case AccessKind.TOPLEVEL_GETTER:
          MemberElement member = semantics.element;
          registry.registerStaticUse(new StaticUse.staticGet(member));
          selector = callStructure.callSelector;
          registry.registerDynamicUse(new DynamicUse(selector, null));
          break;
        case AccessKind.STATIC_SETTER:
        case AccessKind.TOPLEVEL_SETTER:
        case AccessKind.UNRESOLVED:
          registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
          member = reportAndCreateErroneousElement(node.selector, name.text,
              MessageKind.UNDEFINED_STATIC_GETTER_BUT_SETTER, {'name': name});
          break;
        default:
          reporter.internalError(
              node, "Unexpected statically resolved access $semantics.");
          break;
      }
      registry.registerSendStructure(
          node,
          isIncompatibleInvoke
              ? new IncompatibleInvokeStructure(semantics, selector)
              : new InvokeStructure(semantics, selector));
    } else {
      selector = new Selector.getter(name);
      switch (semantics.kind) {
        case AccessKind.STATIC_METHOD:
        case AccessKind.TOPLEVEL_METHOD:
          MethodElement method = semantics.element;
          registry.registerStaticUse(new StaticUse.staticTearOff(method));
          break;
        case AccessKind.STATIC_FIELD:
        case AccessKind.FINAL_STATIC_FIELD:
        case AccessKind.STATIC_GETTER:
        case AccessKind.TOPLEVEL_FIELD:
        case AccessKind.FINAL_TOPLEVEL_FIELD:
        case AccessKind.TOPLEVEL_GETTER:
          MemberElement member = semantics.element;
          registry.registerStaticUse(new StaticUse.staticGet(member));
          break;
        case AccessKind.STATIC_SETTER:
        case AccessKind.TOPLEVEL_SETTER:
        case AccessKind.UNRESOLVED:
          registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
          member = reportAndCreateErroneousElement(node.selector, name.text,
              MessageKind.UNDEFINED_STATIC_GETTER_BUT_SETTER, {'name': name});
          break;
        default:
          reporter.internalError(
              node, "Unexpected statically resolved access $semantics.");
          break;
      }
      registry.registerSendStructure(node, new GetStructure(semantics));
      if (member.isConst) {
        FieldElement field = member;
        result = new ConstantResult(node, new FieldConstantExpression(field),
            element: field);
      } else {
        result = new ElementResult(member);
      }
    }

    // TODO(23998): Remove these when all information goes through
    // the [SendStructure].
    registry.useElement(node, member);
    registry.setSelector(node, selector);

    return result;
  }

  /// Handle update of a static or top level [element].
  ResolutionResult handleStaticOrTopLevelUpdate(
      SendSet node, Name name, Element element) {
    AccessSemantics semantics;
    if (element.isAbstractField) {
      AbstractFieldElement abstractField = element;
      if (abstractField.setter == null) {
        ErroneousElement error = reportAndCreateErroneousElement(
            node.selector,
            name.text,
            MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER,
            {'name': name});
        registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);

        if (node.isComplex) {
          // `a++` or `a += b` where `a` has no setter.
          semantics = new CompoundAccessSemantics(
              element.isTopLevel
                  ? CompoundAccessKind.UNRESOLVED_TOPLEVEL_SETTER
                  : CompoundAccessKind.UNRESOLVED_STATIC_SETTER,
              abstractField.getter,
              error);
        } else {
          // `a = b` where `a` has no setter.
          semantics = element.isTopLevel
              ? new StaticAccess.topLevelGetter(abstractField.getter)
              : new StaticAccess.staticGetter(abstractField.getter);
        }
        registry
            .registerStaticUse(new StaticUse.staticGet(abstractField.getter));
      } else if (node.isComplex) {
        if (abstractField.getter == null) {
          ErroneousElement error = reportAndCreateErroneousElement(
              node.selector,
              name.text,
              MessageKind.UNDEFINED_STATIC_GETTER_BUT_SETTER,
              {'name': name});
          registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
          // `a++` or `a += b` where `a` has no getter.
          semantics = new CompoundAccessSemantics(
              element.isTopLevel
                  ? CompoundAccessKind.UNRESOLVED_TOPLEVEL_GETTER
                  : CompoundAccessKind.UNRESOLVED_STATIC_GETTER,
              error,
              abstractField.setter);
          registry
              .registerStaticUse(new StaticUse.staticSet(abstractField.setter));
        } else {
          // `a++` or `a += b` where `a` has both a getter and a setter.
          semantics = new CompoundAccessSemantics(
              element.isTopLevel
                  ? CompoundAccessKind.TOPLEVEL_GETTER_SETTER
                  : CompoundAccessKind.STATIC_GETTER_SETTER,
              abstractField.getter,
              abstractField.setter);
          registry
              .registerStaticUse(new StaticUse.staticGet(abstractField.getter));
          registry
              .registerStaticUse(new StaticUse.staticSet(abstractField.setter));
        }
      } else {
        // `a = b` where `a` has a setter.
        semantics = element.isTopLevel
            ? new StaticAccess.topLevelSetter(abstractField.setter)
            : new StaticAccess.staticSetter(abstractField.setter);
        registry
            .registerStaticUse(new StaticUse.staticSet(abstractField.setter));
      }
    } else {
      MemberElement member = element;
      // TODO(johnniwinther): Needed to provoke a parsing and with it discovery
      // of parse errors to make [element] erroneous. Fix this!
      member.computeType(resolution);
      if (member.isMalformed) {
        // [member] has parse errors.
        semantics = new StaticAccess.unresolved(member);
      } else if (member.isFunction) {
        // `a = b`, `a++` or `a += b` where `a` is a function.
        MethodElement method = member;
        reportAndCreateErroneousElement(
            node.selector, name.text, MessageKind.ASSIGNING_METHOD, const {});
        registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
        if (node.isComplex) {
          // `a++` or `a += b` where `a` is a function.
          registry.registerStaticUse(new StaticUse.staticTearOff(method));
        }
        semantics = member.isTopLevel
            ? new StaticAccess.topLevelMethod(method)
            : new StaticAccess.staticMethod(method);
      } else {
        // `a = b`, `a++` or `a += b` where `a` is a field.
        assert(member.isField, failedAt(node, "Unexpected element: $member."));
        if (node.isComplex) {
          // `a++` or `a += b` where `a` is a field.
          registry.registerStaticUse(new StaticUse.staticGet(member));
        }
        if (member.isFinal || member.isConst) {
          reportAndCreateErroneousElement(node.selector, name.text,
              MessageKind.UNDEFINED_STATIC_SETTER_BUT_GETTER, {'name': name});
          registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
          semantics = member.isTopLevel
              ? new StaticAccess.finalTopLevelField(member)
              : new StaticAccess.finalStaticField(member);
        } else {
          registry.registerStaticUse(new StaticUse.staticSet(member));
          semantics = member.isTopLevel
              ? new StaticAccess.topLevelField(member)
              : new StaticAccess.staticField(member);
        }
      }
    }
    return handleUpdate(node, name, semantics);
  }

  /// Handle access to resolved [element].
  ResolutionResult handleResolvedSend(Send node, Name name, Element element) {
    if (element.isAmbiguous) {
      return handleAmbiguousSend(node, name, element);
    }
    if (element.isMalformed) {
      // This handles elements with parser errors.
      assert(element is! ErroneousElement,
          failedAt(node, "Unexpected erroneous element $element."));
      return handleErroneousAccess(
          node, name, new StaticAccess.unresolved(element));
    }
    if (element.isInstanceMember) {
      if (inInstanceContext) {
        // TODO(johnniwinther): Maybe use the found [element].
        return handleThisPropertyAccess(node, name);
      } else {
        return handleErroneousAccess(
            node, name, reportStaticInstanceAccess(node, name));
      }
    }
    if (element.isClass) {
      // `C`, `C()`, or 'C.b` where 'C' is a class.
      return handleClassSend(node, name, element);
    } else if (element.isTypedef) {
      // `F` or `F()` where 'F' is a typedef.
      return handleTypedefTypeLiteralAccess(node, name, element);
    } else if (element.isTypeVariable) {
      return handleTypeVariableTypeLiteralAccess(node, name, element);
    } else if (element.isPrefix) {
      return handleLibraryPrefix(node, name, element);
    } else if (element.isLocal) {
      return handleLocalAccess(node, name, element);
    } else if (element.isStatic || element.isTopLevel) {
      return handleStaticOrTopLevelAccess(node, name, element);
    }
    return reporter.internalError(node, "Unexpected resolved send: $element");
  }

  /// Handle update to resolved [element].
  ResolutionResult handleResolvedSendSet(
      SendSet node, Name name, Element element) {
    if (element.isAmbiguous) {
      return handleAmbiguousUpdate(node, name, element);
    }
    if (element.isMalformed) {
      // This handles elements with parser errors..
      assert(element is! ErroneousElement,
          failedAt(node, "Unexpected erroneous element $element."));
      return handleUpdate(node, name, new StaticAccess.unresolved(element));
    }
    if (element.isInstanceMember) {
      if (inInstanceContext) {
        return handleThisPropertyUpdate(node, name, element);
      } else {
        return handleUpdate(node, name, reportStaticInstanceAccess(node, name));
      }
    }
    if (element.isClass) {
      // `C = b`, `C++`, or 'C += b` where 'C' is a class.
      return handleClassTypeLiteralUpdate(node, name, element);
    } else if (element.isTypedef) {
      // `C = b`, `C++`, or 'C += b` where 'F' is a typedef.
      return handleTypedefTypeLiteralUpdate(node, name, element);
    } else if (element.isTypeVariable) {
      // `T = b`, `T++`, or 'T += b` where 'T' is a type variable.
      return handleTypeVariableTypeLiteralUpdate(node, name, element);
    } else if (element.isPrefix) {
      // `p = b` where `p` is a prefix.
      ErroneousElement error = reportAndCreateErroneousElement(
          node, name.text, MessageKind.PREFIX_AS_EXPRESSION, {'prefix': name},
          isError: true);
      registry.registerFeature(Feature.COMPILE_TIME_ERROR);
      return handleUpdate(node, name, new StaticAccess.invalid(error));
    } else if (element.isLocal) {
      return handleLocalUpdate(node, name, element);
    } else if (element.isStatic || element.isTopLevel) {
      return handleStaticOrTopLevelUpdate(node, name, element);
    }
    return reporter.internalError(node, "Unexpected resolved send: $element");
  }

  /// Handle an unqualified [Send], that is where the `node.receiver` is null,
  /// like `a`, `a()`, `this()`, `assert()`, and `(){}()`.
  ResolutionResult handleUnqualifiedSend(Send node) {
    Identifier selector = node.selector.asIdentifier();
    if (selector == null) {
      // `(){}()` and `(foo)()`.
      return handleExpressionInvoke(node);
    }
    String text = selector.source;
    if (text == 'this') {
      // `this()`.
      return handleThisAccess(node);
    }
    // `name` or `name()`
    Name name = new Name(text, enclosingElement.library);
    Element element = lookupInScope(reporter, node, scope, text);
    if (element == null) {
      if (text == 'dynamic') {
        // `dynamic` or `dynamic()` where 'dynamic' is not declared in the
        // current scope.
        return handleDynamicTypeLiteralAccess(node);
      } else if (inInstanceContext) {
        // Implicitly `this.name`.
        return handleThisPropertyAccess(node, name);
      } else {
        // Create [ErroneousElement] for unresolved access.
        ErroneousElement error = reportCannotResolve(node, text);
        return handleUnresolvedAccess(node, name, error);
      }
    } else {
      return handleResolvedSend(node, name, element);
    }
  }

  /// Handle an unqualified [SendSet], that is where the `node.receiver` is
  /// null, like `a = b`, `a++`, and `a += b`.
  ResolutionResult handleUnqualifiedSendSet(SendSet node) {
    Identifier selector = node.selector.asIdentifier();
    String text = selector.source;
    Name name = new Name(text, enclosingElement.library);
    Element element = lookupInScope(reporter, node, scope, text);
    if (element == null) {
      if (text == 'dynamic') {
        // `dynamic = b`, `dynamic++`, or `dynamic += b` where 'dynamic' is not
        // declared in the current scope.
        return handleDynamicTypeLiteralUpdate(node);
      } else if (inInstanceContext) {
        // Left-hand side is implicitly `this.name`.
        return handleThisPropertyUpdate(node, name, null);
      } else {
        // Create [ErroneousElement] for unresolved access.
        ErroneousElement error = reportCannotResolve(node, text);
        return handleUpdate(node, name, new StaticAccess.unresolved(error));
      }
    } else {
      return handleResolvedSendSet(node, name, element);
    }
  }

  ResolutionResult visitSend(Send node) {
    // Resolve type arguments to ensure that these are well-formed types.
    if (node.typeArgumentsNode != null) {
      for (TypeAnnotation type in node.typeArgumentsNode.nodes) {
        resolveTypeAnnotation(type, registerCheckedModeCheck: false);
      }
    }
    if (node.isOperator) {
      // `a && b`, `a + b`, `-a`, or `a is T`.
      return handleOperatorSend(node);
    } else if (node.receiver != null) {
      // `a.b`.
      return handleQualifiedSend(node);
    } else {
      // `a`.
      return handleUnqualifiedSend(node);
    }
  }

  /// Register read access of [target] inside a closure.
  void registerPotentialAccessInClosure(Send node, Element target) {
    if (isPotentiallyMutableTarget(target)) {
      if (enclosingElement != target.enclosingElement) {
        for (Node scope in promotionScope) {
          registry.setAccessedByClosureIn(scope, target, node);
        }
      }
    }
  }

  // TODO(johnniwinther): Move this to the backend resolution callbacks.
  void handleForeignCall(
      Send node, Element target, CallStructure callStructure) {
    if (target != null && resolution.target.isForeign(target)) {
      registry.registerForeignCall(node, target, callStructure, this);
    }
  }

  /// Callback for native enqueuer to parse a type.  Returns [:null:] on error.
  ResolutionDartType resolveTypeFromString(Node node, String typeName) {
    Element element = lookupInScope(reporter, node, scope, typeName);
    if (element == null) return null;
    if (element is! ClassElement) return null;
    ClassElement cls = element;
    cls.ensureResolved(resolution);
    cls.computeType(resolution);
    return cls.rawType;
  }

  /// Handle index operations like `a[b] = c`, `a[b] += c`, and `a[b]++`.
  ResolutionResult handleIndexSendSet(SendSet node) {
    String operatorText = node.assignmentOperator.source;
    Node receiver = node.receiver;
    Node index = node.arguments.head;
    visitExpression(receiver);
    visitExpression(index);
    AccessSemantics semantics = const DynamicAccess.expression();
    if (node.isPrefix || node.isPostfix) {
      // `a[b]++` or `++a[b]`.
      IncDecOperator operator = IncDecOperator.parse(operatorText);
      Selector getterSelector = new Selector.index();
      Selector setterSelector = new Selector.indexSet();
      Selector operatorSelector =
          new Selector.binaryOperator(operator.selectorName);

      // TODO(23998): Remove these when selectors are only accessed
      // through the send structure.
      registry.setGetterSelectorInComplexSendSet(node, getterSelector);
      registry.setSelector(node, setterSelector);
      registry.setOperatorSelectorInComplexSendSet(node, operatorSelector);

      registry.registerDynamicUse(new DynamicUse(getterSelector, null));
      registry.registerDynamicUse(new DynamicUse(setterSelector, null));
      registry.registerDynamicUse(new DynamicUse(operatorSelector, null));

      SendStructure sendStructure = node.isPrefix
          ? new IndexPrefixStructure(semantics, operator)
          : new IndexPostfixStructure(semantics, operator);
      registry.registerSendStructure(node, sendStructure);
      return const NoneResult();
    } else {
      Node rhs = node.arguments.tail.head;
      visitExpression(rhs);

      AssignmentOperator operator = AssignmentOperator.parse(operatorText);
      if (operator.kind == AssignmentOperatorKind.ASSIGN) {
        // `a[b] = c`.
        Selector setterSelector = new Selector.indexSet();

        // TODO(23998): Remove this when selectors are only accessed
        // through the send structure.
        registry.setSelector(node, setterSelector);
        registry.registerDynamicUse(new DynamicUse(setterSelector, null));

        SendStructure sendStructure = new IndexSetStructure(semantics);
        registry.registerSendStructure(node, sendStructure);
        return const NoneResult();
      } else {
        // `a[b] += c`.
        Selector getterSelector = new Selector.index();
        Selector setterSelector = new Selector.indexSet();
        Selector operatorSelector =
            new Selector.binaryOperator(operator.selectorName);

        // TODO(23998): Remove these when selectors are only accessed
        // through the send structure.
        registry.setGetterSelectorInComplexSendSet(node, getterSelector);
        registry.setSelector(node, setterSelector);
        registry.setOperatorSelectorInComplexSendSet(node, operatorSelector);

        registry.registerDynamicUse(new DynamicUse(getterSelector, null));
        registry.registerDynamicUse(new DynamicUse(setterSelector, null));
        registry.registerDynamicUse(new DynamicUse(operatorSelector, null));

        SendStructure sendStructure;
        if (operator.kind == AssignmentOperatorKind.IF_NULL) {
          sendStructure = new IndexSetIfNullStructure(semantics);
        } else {
          sendStructure = new CompoundIndexSetStructure(semantics, operator);
        }
        registry.registerSendStructure(node, sendStructure);
        return const NoneResult();
      }
    }
  }

  /// Handle super index operations like `super[a] = b`, `super[a] += b`, and
  /// `super[a]++`.
  // TODO(johnniwinther): Share code with [handleIndexSendSet].
  ResolutionResult handleSuperIndexSendSet(SendSet node) {
    String operatorText = node.assignmentOperator.source;
    Node index = node.arguments.head;
    visitExpression(index);

    AccessSemantics semantics = checkSuperAccess(node);
    if (node.isPrefix || node.isPostfix) {
      // `super[a]++` or `++super[a]`.
      IncDecOperator operator = IncDecOperator.parse(operatorText);
      Selector getterSelector = new Selector.index();
      Selector setterSelector = new Selector.indexSet();
      Selector operatorSelector =
          new Selector.binaryOperator(operator.selectorName);

      // TODO(23998): Remove these when selectors are only accessed
      // through the send structure.
      registry.setGetterSelectorInComplexSendSet(node, getterSelector);
      registry.setSelector(node, setterSelector);
      registry.setOperatorSelectorInComplexSendSet(node, operatorSelector);

      if (semantics == null) {
        semantics = computeSuperAccessSemanticsForSelectors(
            node, getterSelector, setterSelector,
            isIndex: true);

        if (!semantics.getter.isError) {
          MethodElement getter = semantics.getter;
          registry.registerStaticUse(
              new StaticUse.superInvoke(getter, getterSelector.callStructure));
        }
        if (!semantics.setter.isError) {
          MethodElement setter = semantics.setter;
          registry.registerStaticUse(
              new StaticUse.superInvoke(setter, setterSelector.callStructure));
        }

        // TODO(23998): Remove these when elements are only accessed
        // through the send structure.
        registry.useElement(node, semantics.setter);
        registry.useElement(node.selector, semantics.getter);
      }
      registry.registerDynamicUse(new DynamicUse(operatorSelector, null));

      SendStructure sendStructure = node.isPrefix
          ? new IndexPrefixStructure(semantics, operator)
          : new IndexPostfixStructure(semantics, operator);
      registry.registerSendStructure(node, sendStructure);
      return const NoneResult();
    } else {
      Node rhs = node.arguments.tail.head;
      visitExpression(rhs);

      AssignmentOperator operator = AssignmentOperator.parse(operatorText);
      if (operator.kind == AssignmentOperatorKind.ASSIGN) {
        // `super[a] = b`.
        Selector setterSelector = new Selector.indexSet();
        if (semantics == null) {
          semantics =
              computeSuperAccessSemanticsForSelector(node, setterSelector);

          // TODO(23998): Remove these when elements are only accessed
          // through the send structure.
          registry.useElement(node, semantics.setter);
        }

        // TODO(23998): Remove this when selectors are only accessed
        // through the send structure.
        registry.setSelector(node, setterSelector);
        if (!semantics.setter.isError) {
          MethodElement setter = semantics.setter;
          registry.registerStaticUse(
              new StaticUse.superInvoke(setter, setterSelector.callStructure));
        }

        SendStructure sendStructure = new IndexSetStructure(semantics);
        registry.registerSendStructure(node, sendStructure);
        return const NoneResult();
      } else {
        // `super[a] += b`.
        Selector getterSelector = new Selector.index();
        Selector setterSelector = new Selector.indexSet();
        Selector operatorSelector =
            new Selector.binaryOperator(operator.selectorName);
        if (semantics == null) {
          semantics = computeSuperAccessSemanticsForSelectors(
              node, getterSelector, setterSelector,
              isIndex: true);

          if (!semantics.getter.isError) {
            MethodElement getter = semantics.getter;
            registry.registerStaticUse(new StaticUse.superInvoke(
                getter, getterSelector.callStructure));
          }
          if (!semantics.setter.isError) {
            MethodElement setter = semantics.setter;
            registry.registerStaticUse(new StaticUse.superInvoke(
                setter, setterSelector.callStructure));
          }

          // TODO(23998): Remove these when elements are only accessed
          // through the send structure.
          registry.useElement(node, semantics.setter);
          registry.useElement(node.selector, semantics.getter);
        }

        // TODO(23998): Remove these when selectors are only accessed
        // through the send structure.
        registry.setGetterSelectorInComplexSendSet(node, getterSelector);
        registry.setSelector(node, setterSelector);
        registry.setOperatorSelectorInComplexSendSet(node, operatorSelector);

        registry.registerDynamicUse(new DynamicUse(operatorSelector, null));

        SendStructure sendStructure;
        if (operator.kind == AssignmentOperatorKind.IF_NULL) {
          sendStructure = new IndexSetIfNullStructure(semantics);
        } else {
          sendStructure = new CompoundIndexSetStructure(semantics, operator);
        }
        registry.registerSendStructure(node, sendStructure);
        return const NoneResult();
      }
    }
  }

  /// Handle super index operations like `super.a = b`, `super.a += b`, and
  /// `super.a++`.
  // TODO(johnniwinther): Share code with [handleSuperIndexSendSet].
  ResolutionResult handleSuperSendSet(SendSet node) {
    Identifier selector = node.selector.asIdentifier();
    String text = selector.source;
    Name name = new Name(text, enclosingElement.library);
    String operatorText = node.assignmentOperator.source;
    Selector getterSelector = new Selector.getter(name);
    Selector setterSelector = new Selector.setter(name);

    void registerStaticUses(AccessSemantics semantics) {
      switch (semantics.kind) {
        case AccessKind.SUPER_METHOD:
          MethodElement method = semantics.element;
          registry.registerStaticUse(new StaticUse.superTearOff(method));
          break;
        case AccessKind.SUPER_GETTER:
          MethodElement getter = semantics.getter;
          registry.registerStaticUse(new StaticUse.superGet(getter));
          break;
        case AccessKind.SUPER_SETTER:
          MethodElement setter = semantics.setter;
          registry.registerStaticUse(new StaticUse.superSetterSet(setter));
          break;
        case AccessKind.SUPER_FIELD:
          FieldElement field = semantics.element;
          registry.registerStaticUse(new StaticUse.superGet(field));
          registry.registerStaticUse(new StaticUse.superFieldSet(field));
          break;
        case AccessKind.SUPER_FINAL_FIELD:
          FieldElement field = semantics.element;
          registry.registerStaticUse(new StaticUse.superGet(field));
          break;
        case AccessKind.COMPOUND:
          CompoundAccessSemantics compoundSemantics = semantics;
          switch (compoundSemantics.compoundAccessKind) {
            case CompoundAccessKind.SUPER_GETTER_FIELD:
            case CompoundAccessKind.SUPER_FIELD_FIELD:
              MemberElement getter = semantics.getter;
              FieldElement setter = semantics.setter;
              registry.registerStaticUse(new StaticUse.superGet(getter));
              registry.registerStaticUse(new StaticUse.superFieldSet(setter));
              break;
            case CompoundAccessKind.SUPER_FIELD_SETTER:
            case CompoundAccessKind.SUPER_GETTER_SETTER:
              MemberElement getter = semantics.getter;
              MethodElement setter = semantics.setter;
              registry.registerStaticUse(new StaticUse.superGet(getter));
              registry.registerStaticUse(new StaticUse.superSetterSet(setter));
              break;
            case CompoundAccessKind.SUPER_METHOD_SETTER:
              MethodElement setter = semantics.setter;
              registry.registerStaticUse(new StaticUse.superSetterSet(setter));
              break;
            case CompoundAccessKind.UNRESOLVED_SUPER_GETTER:
              MethodElement setter = semantics.setter;
              registry.registerStaticUse(new StaticUse.superSetterSet(setter));
              break;
            case CompoundAccessKind.UNRESOLVED_SUPER_SETTER:
              MethodElement getter = semantics.getter;
              registry.registerStaticUse(new StaticUse.superGet(getter));
              break;
            default:
              break;
          }
          break;
        default:
          break;
      }
    }

    AccessSemantics semantics = checkSuperAccess(node);
    if (node.isPrefix || node.isPostfix) {
      // `super.a++` or `++super.a`.
      if (semantics == null) {
        semantics = computeSuperAccessSemanticsForSelectors(
            node, getterSelector, setterSelector);
        registerStaticUses(semantics);
      }
      return handleUpdate(node, name, semantics);
    } else {
      AssignmentOperator operator = AssignmentOperator.parse(operatorText);
      if (operator.kind == AssignmentOperatorKind.ASSIGN) {
        // `super.a = b`.
        if (semantics == null) {
          semantics = computeSuperAccessSemanticsForSelector(
              node, setterSelector,
              alternateName: name);
          switch (semantics.kind) {
            case AccessKind.SUPER_FINAL_FIELD:
              reporter.reportWarningMessage(
                  node, MessageKind.ASSIGNING_FINAL_FIELD_IN_SUPER, {
                'name': name,
                'superclassName': semantics.setter.enclosingClass.name
              });
              // TODO(johnniwinther): This shouldn't be needed.
              registry.registerDynamicUse(new DynamicUse(setterSelector, null));
              registry.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
              break;
            case AccessKind.SUPER_METHOD:
              reporter.reportWarningMessage(
                  node, MessageKind.ASSIGNING_METHOD_IN_SUPER, {
                'name': name,
                'superclassName': semantics.setter.enclosingClass.name
              });
              // TODO(johnniwinther): This shouldn't be needed.
              registry.registerDynamicUse(new DynamicUse(setterSelector, null));
              registry.registerFeature(Feature.SUPER_NO_SUCH_METHOD);
              break;
            case AccessKind.SUPER_FIELD:
              FieldElement field = semantics.setter;
              registry.registerStaticUse(new StaticUse.superFieldSet(field));
              break;
            case AccessKind.SUPER_SETTER:
              MethodElement setter = semantics.setter;
              registry.registerStaticUse(new StaticUse.superSetterSet(setter));
              break;
            default:
              break;
          }
        }
        return handleUpdate(node, name, semantics);
      } else {
        // `super.a += b`.
        if (semantics == null) {
          semantics = computeSuperAccessSemanticsForSelectors(
              node, getterSelector, setterSelector);
          registerStaticUses(semantics);
        }
        return handleUpdate(node, name, semantics);
      }
    }
  }

  /// Handle update of an entity defined by [semantics]. For instance `a = b`,
  /// `a++` or `a += b` where [semantics] describe `a`.
  ResolutionResult handleUpdate(
      SendSet node, Name name, AccessSemantics semantics) {
    String operatorText = node.assignmentOperator.source;
    Selector getterSelector = new Selector.getter(name);
    Selector setterSelector = new Selector.setter(name);
    if (node.isPrefix || node.isPostfix) {
      // `e++` or `++e`.
      IncDecOperator operator = IncDecOperator.parse(operatorText);
      Selector operatorSelector =
          new Selector.binaryOperator(operator.selectorName);

      // TODO(23998): Remove these when selectors are only accessed
      // through the send structure.
      registry.setGetterSelectorInComplexSendSet(node, getterSelector);
      registry.setSelector(node, setterSelector);
      registry.setOperatorSelectorInComplexSendSet(node, operatorSelector);

      // TODO(23998): Remove these when elements are only accessed
      // through the send structure.
      registry.useElement(node, semantics.setter);
      registry.useElement(node.selector, semantics.getter);

      registry.registerDynamicUse(new DynamicUse(operatorSelector, null));

      SendStructure sendStructure = node.isPrefix
          ? new PrefixStructure(semantics, operator)
          : new PostfixStructure(semantics, operator);
      registry.registerSendStructure(node, sendStructure);
      registry.registerConstantLiteral(new IntConstantExpression(1));
    } else {
      Node rhs = node.arguments.head;
      visitExpression(rhs);

      AssignmentOperator operator = AssignmentOperator.parse(operatorText);
      if (operator.kind == AssignmentOperatorKind.ASSIGN) {
        // `e1 = e2`.

        // TODO(23998): Remove these when elements are only accessed
        // through the send structure.
        registry.useElement(node, semantics.setter);

        // TODO(23998): Remove this when selectors are only accessed
        // through the send structure.
        registry.setSelector(node, setterSelector);

        SendStructure sendStructure = new SetStructure(semantics);
        registry.registerSendStructure(node, sendStructure);
      } else {
        // `e1 += e2`.
        Selector operatorSelector =
            new Selector.binaryOperator(operator.selectorName);

        // TODO(23998): Remove these when elements are only accessed
        // through the send structure.
        registry.useElement(node, semantics.setter);
        registry.useElement(node.selector, semantics.getter);

        // TODO(23998): Remove these when selectors are only accessed
        // through the send structure.
        registry.setGetterSelectorInComplexSendSet(node, getterSelector);
        registry.setSelector(node, setterSelector);
        registry.setOperatorSelectorInComplexSendSet(node, operatorSelector);

        SendStructure sendStructure;
        if (operator.kind == AssignmentOperatorKind.IF_NULL) {
          registry.registerConstantLiteral(new NullConstantExpression());
          registry.registerDynamicUse(new DynamicUse(Selectors.equals, null));
          sendStructure = new SetIfNullStructure(semantics);
        } else {
          registry.registerDynamicUse(new DynamicUse(operatorSelector, null));
          sendStructure = new CompoundStructure(semantics, operator);
        }
        registry.registerSendStructure(node, sendStructure);
      }
    }
    return new ResolutionResult.forElement(semantics.setter);
  }

  ResolutionResult visitSendSet(SendSet node) {
    if (node.isIndex) {
      // `a[b] = c`
      if (node.isSuperCall) {
        // `super[b] = c`
        return handleSuperIndexSendSet(node);
      } else {
        return handleIndexSendSet(node);
      }
    } else if (node.isSuperCall) {
      // `super.a = c`
      return handleSuperSendSet(node);
    } else if (node.receiver == null) {
      // `a = c`
      return handleUnqualifiedSendSet(node);
    } else {
      // `a.b = c`
      return handleQualifiedSendSet(node);
    }
  }

  ConstantResult visitLiteralInt(LiteralInt node) {
    ConstantExpression constant = new IntConstantExpression(node.value);
    registry.registerConstantLiteral(constant);
    registry.setConstant(node, constant);
    return new ConstantResult(node, constant);
  }

  ConstantResult visitLiteralDouble(LiteralDouble node) {
    ConstantExpression constant = new DoubleConstantExpression(node.value);
    registry.registerConstantLiteral(constant);
    registry.setConstant(node, constant);
    return new ConstantResult(node, constant);
  }

  ConstantResult visitLiteralBool(LiteralBool node) {
    ConstantExpression constant = new BoolConstantExpression(node.value);
    registry.registerConstantLiteral(constant);
    registry.setConstant(node, constant);
    return new ConstantResult(node, constant);
  }

  ResolutionResult visitLiteralString(LiteralString node) {
    if (node.dartString != null) {
      // [dartString] might be null on parser errors.
      ConstantExpression constant =
          new StringConstantExpression(node.dartString.slowToString());
      registry.registerConstantLiteral(constant);
      registry.setConstant(node, constant);
      return new ConstantResult(node, constant);
    }
    return const NoneResult();
  }

  ConstantResult visitLiteralNull(LiteralNull node) {
    ConstantExpression constant = new NullConstantExpression();
    registry.registerConstantLiteral(constant);
    registry.setConstant(node, constant);
    return new ConstantResult(node, constant);
  }

  ConstantResult visitLiteralSymbol(LiteralSymbol node) {
    String name = node.slowNameString;
    // TODO(johnniwinther): Use [registerConstantLiteral] instead.
    registry.registerConstSymbol(name);
    if (!validateSymbol(node, name, reportError: false)) {
      reporter.reportErrorMessage(
          node, MessageKind.UNSUPPORTED_LITERAL_SYMBOL, {'value': name});
    }
    analyzeConstantDeferred(node);
    ConstantExpression constant = new SymbolConstantExpression(name);
    registry.setConstant(node, constant);
    return new ConstantResult(node, constant);
  }

  ResolutionResult visitStringJuxtaposition(StringJuxtaposition node) {
    registry.registerFeature(Feature.STRING_JUXTAPOSITION);
    ResolutionResult first = visit(node.first);
    ResolutionResult second = visit(node.second);
    if (first.isConstant && second.isConstant) {
      ConstantExpression constant = new ConcatenateConstantExpression(
          <ConstantExpression>[first.constant, second.constant]);
      registry.setConstant(node, constant);
      return new ConstantResult(node, constant);
    }
    return const NoneResult();
  }

  ResolutionResult visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      visit(link.head);
    }
    return const NoneResult();
  }

  ResolutionResult visitRethrow(Rethrow node) {
    if (!inCatchBlock && node.throwToken.stringValue == 'rethrow') {
      reporter.reportErrorMessage(node, MessageKind.RETHROW_OUTSIDE_CATCH);
    }
    return const NoneResult();
  }

  ResolutionResult visitReturn(Return node) {
    Node expression = node.expression;
    if (expression != null) {
      if (enclosingElement.isGenerativeConstructor) {
        // It is a compile-time error if a return statement of the form
        // `return e;` appears in a generative constructor.  (Dart Language
        // Specification 13.12.)
        reporter.reportErrorMessage(
            expression, MessageKind.RETURN_IN_GENERATIVE_CONSTRUCTOR);
      } else if (!node.isArrowBody && currentAsyncMarker.isYielding) {
        reporter.reportErrorMessage(node, MessageKind.RETURN_IN_GENERATOR,
            {'modifier': currentAsyncMarker});
      }
    }
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitYield(Yield node) {
    if (!resolution.target.supportsAsyncAwait) {
      reporter.reportErrorMessage(reporter.spanFromToken(node.yieldToken),
          MessageKind.ASYNC_AWAIT_NOT_SUPPORTED);
    } else {
      if (!currentAsyncMarker.isYielding) {
        reporter.reportErrorMessage(node, MessageKind.INVALID_YIELD);
      }
      ClassElement cls;
      if (currentAsyncMarker.isAsync) {
        cls = commonElements.streamClass;
      } else {
        cls = commonElements.iterableClass;
      }
      cls.ensureResolved(resolution);
    }
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitRedirectingFactoryBody(RedirectingFactoryBody node) {
    if (!enclosingElement.isFactoryConstructor) {
      reporter.reportErrorMessage(
          node, MessageKind.FACTORY_REDIRECTION_IN_NON_FACTORY);
      reporter.reportHintMessage(
          enclosingElement, MessageKind.MISSING_FACTORY_KEYWORD);
    }

    ConstructorElementX constructor = enclosingElement;
    bool isConstConstructor = constructor.isConst;
    bool isValidAsConstant = isConstConstructor;
    ConstructorResult result =
        resolveRedirectingFactory(node, inConstContext: isConstConstructor);
    ConstructorElement redirectionTarget = result.element;
    constructor.setImmediateRedirectionTarget(
        redirectionTarget, result.isDeferred ? result.prefix : null);

    registry.setRedirectingTargetConstructor(node, redirectionTarget);
    switch (result.kind) {
      case ConstructorResultKind.GENERATIVE:
      case ConstructorResultKind.FACTORY:
        // Register a post process to check for cycles in the redirection chain
        // and set the actual generative constructor at the end of the chain.
        addDeferredAction(constructor, () {
          resolver.resolveRedirectionChain(constructor, node);
        });
        break;
      case ConstructorResultKind.ABSTRACT:
      case ConstructorResultKind.INVALID_TYPE:
      case ConstructorResultKind.UNRESOLVED_CONSTRUCTOR:
      case ConstructorResultKind.NON_CONSTANT:
        isValidAsConstant = false;
        constructor.setEffectiveTarget(result.element, result.type,
            isMalformed: true);
        break;
    }
    if (Elements.isUnresolved(redirectionTarget)) {
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      return const NoneResult();
    } else {
      if (isConstConstructor && !redirectionTarget.isConst) {
        reporter.reportErrorMessage(node, MessageKind.CONSTRUCTOR_IS_NOT_CONST);
        isValidAsConstant = false;
      }
      if (redirectionTarget == constructor) {
        reporter.reportErrorMessage(
            node, MessageKind.CYCLIC_REDIRECTING_FACTORY);
        // TODO(johnniwinther): Create constant constructor for this case and
        // let evaluation detect the cyclicity.
        isValidAsConstant = false;
      }
    }

    // Check that the target constructor is type compatible with the
    // redirecting constructor.
    ClassElement targetClass = redirectionTarget.enclosingClass;
    ResolutionInterfaceType type = registry.getType(node);
    ResolutionFunctionType targetConstructorType = redirectionTarget
        .computeType(resolution)
        .subst(type.typeArguments, targetClass.typeVariables);
    ResolutionFunctionType constructorType =
        constructor.computeType(resolution);
    bool isSubtype =
        resolution.types.isSubtype(targetConstructorType, constructorType);
    if (!isSubtype) {
      reporter.reportWarningMessage(node, MessageKind.NOT_ASSIGNABLE,
          {'fromType': targetConstructorType, 'toType': constructorType});
      // TODO(johnniwinther): Handle this (potentially) erroneous case.
      isValidAsConstant = false;
    }
    if (type.typeArguments.any((ResolutionDartType type) => !type.isDynamic)) {
      registry.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
    }

    redirectionTarget.computeType(resolution);
    FunctionSignature targetSignature = redirectionTarget.functionSignature;
    constructor.computeType(resolution);
    FunctionSignature constructorSignature = constructor.functionSignature;
    if (!targetSignature.isCompatibleWith(constructorSignature)) {
      assert(!isSubtype);
      registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
      isValidAsConstant = false;
    }

    registry.registerStaticUse(new StaticUse.constructorRedirect(
        redirectionTarget,
        redirectionTarget.enclosingClass.thisType
            .subst(type.typeArguments, targetClass.typeVariables)));
    if (resolution.commonElements.isSymbolConstructor(constructor)) {
      registry.registerFeature(Feature.SYMBOL_CONSTRUCTOR);
    }
    if (isValidAsConstant) {
      List<String> names = <String>[];
      List<ConstantExpression> arguments = <ConstantExpression>[];
      int index = 0;
      constructorSignature.forEachParameter((_parameter) {
        ParameterElement parameter = _parameter;
        if (parameter.isNamed) {
          String name = parameter.name;
          names.add(name);
          arguments.add(new NamedArgumentReference(name));
        } else {
          arguments.add(new PositionalArgumentReference(index));
        }
        index++;
      });
      CallStructure callStructure =
          new CallStructure(constructorSignature.parameterCount, names);
      constructor.constantConstructor =
          new RedirectingFactoryConstantConstructor(
              new ConstructedConstantExpression(
                  type, redirectionTarget, callStructure, arguments));
    }
    return const NoneResult();
  }

  ResolutionResult visitThrow(Throw node) {
    registry.registerFeature(Feature.THROW_EXPRESSION);
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitAwait(Await node) {
    if (!resolution.target.supportsAsyncAwait) {
      reporter.reportErrorMessage(reporter.spanFromToken(node.awaitToken),
          MessageKind.ASYNC_AWAIT_NOT_SUPPORTED);
    } else {
      if (!currentAsyncMarker.isAsync) {
        reporter.reportErrorMessage(node, MessageKind.INVALID_AWAIT);
      }
      ClassElement futureClass = commonElements.futureClass;
      futureClass.ensureResolved(resolution);
    }
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitVariableDefinitions(VariableDefinitions node) {
    ResolutionDartType type;
    if (node.type != null) {
      type = resolveTypeAnnotation(node.type);
    } else {
      type = const ResolutionDynamicType();
    }
    VariableList variables = new VariableList.node(node, type);
    VariableDefinitionsVisitor visitor =
        new VariableDefinitionsVisitor(resolution, node, this, variables);

    Modifiers modifiers = node.modifiers;
    void reportExtraModifier(String modifier) {
      Node modifierNode;
      for (Link<Node> nodes = modifiers.nodes.nodes;
          !nodes.isEmpty;
          nodes = nodes.tail) {
        if (modifier == nodes.head.asIdentifier().source) {
          modifierNode = nodes.head;
          break;
        }
      }
      assert(modifierNode != null);
      reporter.reportErrorMessage(modifierNode, MessageKind.EXTRANEOUS_MODIFIER,
          {'modifier': modifier});
    }

    if (modifiers.isFinal && (modifiers.isConst || modifiers.isVar)) {
      reportExtraModifier('final');
    }
    if (modifiers.isVar && (modifiers.isConst || node.type != null)) {
      reportExtraModifier('var');
    }
    if (enclosingElement.isFunction || enclosingElement.isConstructor) {
      if (modifiers.isAbstract) {
        reportExtraModifier('abstract');
      }
      if (modifiers.isStatic) {
        reportExtraModifier('static');
      }
    }
    if (node.metadata != null) {
      variables.metadataInternal =
          resolver.resolveMetadata(enclosingElement, node);
    }
    visitor.visit(node.definitions);
    return const NoneResult();
  }

  ResolutionResult visitWhile(While node) {
    visit(node.condition);
    visitLoopBodyIn(node, node.body, new BlockScope(scope));
    return const NoneResult();
  }

  ResolutionResult visitParenthesizedExpression(ParenthesizedExpression node) {
    bool oldSendIsMemberAccess = sendIsMemberAccess;
    sendIsMemberAccess = false;
    var oldCategory = allowedCategory;
    allowedCategory = ElementCategory.VARIABLE |
        ElementCategory.FUNCTION |
        ElementCategory.IMPLIES_TYPE;
    ResolutionResult result = visit(node.expression);
    allowedCategory = oldCategory;
    sendIsMemberAccess = oldSendIsMemberAccess;
    if (result.kind == ResultKind.CONSTANT) {
      return result;
    }
    return const NoneResult();
  }

  ResolutionResult visitNewExpression(NewExpression node) {
    ConstructorResult result = resolveConstructor(node);
    ConstructorElement constructor = result.element;
    if (resolution.commonElements.isSymbolConstructor(constructor)) {
      registry.registerFeature(Feature.SYMBOL_CONSTRUCTOR);
    }
    ArgumentsResult argumentsResult;
    if (node.isConst) {
      argumentsResult =
          inConstantContext(() => resolveArguments(node.send.argumentsNode));
    } else {
      if (!node.isConst && constructor.isFromEnvironmentConstructor) {
        // TODO(sigmund): consider turning this into a compile-time-error.
        reporter.reportHintMessage(
            node,
            MessageKind.FROM_ENVIRONMENT_MUST_BE_CONST,
            {'className': constructor.enclosingClass.name});
        registry.registerFeature(Feature.THROW_UNSUPPORTED_ERROR);
      }
      argumentsResult = resolveArguments(node.send.argumentsNode);
    }
    // TODO(johnniwinther): Avoid the need for a [Selector].
    Selector selector = resolveSelector(node.send, constructor);
    CallStructure callStructure = selector.callStructure;
    registry.useElement(node.send, constructor);

    ResolutionDartType type = result.type;
    ConstructorAccessKind kind;
    bool isInvalid = false;
    switch (result.kind) {
      case ConstructorResultKind.GENERATIVE:
        // Ensure that the signature of [constructor] has been computed.
        constructor.computeType(resolution);
        if (!callStructure.signatureApplies(constructor.parameterStructure)) {
          isInvalid = true;
          kind = ConstructorAccessKind.INCOMPATIBLE;
          registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
        } else {
          kind = ConstructorAccessKind.GENERATIVE;
        }
        break;
      case ConstructorResultKind.FACTORY:
        // Ensure that the signature of [constructor] has been computed.
        constructor.computeType(resolution);
        if (!callStructure.signatureApplies(constructor.parameterStructure)) {
          // The effective target might still be valid(!) so the is not an
          // invalid case in itself. For instance
          //
          //    class A {
          //       factory A() = A.a;
          //       A.a(a);
          //    }
          //    m() => new A(0); // This creates a warning but works at runtime.
          //
          registry.registerFeature(Feature.THROW_NO_SUCH_METHOD);
        }
        kind = ConstructorAccessKind.FACTORY;
        break;
      case ConstructorResultKind.ABSTRACT:
        isInvalid = true;
        kind = ConstructorAccessKind.ABSTRACT;
        break;
      case ConstructorResultKind.INVALID_TYPE:
        isInvalid = true;
        kind = ConstructorAccessKind.UNRESOLVED_TYPE;
        break;
      case ConstructorResultKind.UNRESOLVED_CONSTRUCTOR:
        // TODO(johnniwinther): Unify codepaths to only have one return.
        registry.registerNewStructure(
            node,
            new NewInvokeStructure(
                new ConstructorAccessSemantics(
                    ConstructorAccessKind.UNRESOLVED_CONSTRUCTOR,
                    constructor,
                    type),
                selector));
        return new ResolutionResult.forElement(constructor);
      case ConstructorResultKind.NON_CONSTANT:
        registry.registerNewStructure(
            node,
            new NewInvokeStructure(
                new ConstructorAccessSemantics(
                    ConstructorAccessKind.NON_CONSTANT_CONSTRUCTOR,
                    constructor,
                    type),
                selector));
        return new ResolutionResult.forElement(constructor);
    }

    if (!isInvalid) {
      // [constructor] might be the implementation element
      // and only declaration elements may be registered.
      // TODO(johniwinther): Avoid registration of `type` in face of redirecting
      // factory constructors.
      ConstructorElement declaration = constructor.declaration;
      registry.registerStaticUse(node.isConst
          ? new StaticUse.constConstructorInvoke(
              declaration, callStructure, type)
          : new StaticUse.typedConstructorInvoke(
              constructor, callStructure, type));
      ResolutionInterfaceType interfaceType = type;
      if (interfaceType.typeArguments
          .any((ResolutionDartType type) => !type.isDynamic)) {
        registry.registerFeature(Feature.TYPE_VARIABLE_BOUNDS_CHECK);
      }
    }

    ResolutionResult resolutionResult = const NoneResult();
    if (node.isConst) {
      bool isValidAsConstant = !isInvalid && constructor.isConst;

      CommonElements commonElements = resolution.commonElements;
      if (commonElements.isSymbolConstructor(constructor)) {
        Node argumentNode = node.send.arguments.head;
        ConstantExpression constant = resolver.constantCompiler
            .compileNode(argumentNode, registry.mapping);
        ConstantValue name = resolution.constants.getConstantValue(constant);
        if (!name.isString) {
          ResolutionDartType type = name.getType(commonElements);
          reporter.reportErrorMessage(
              argumentNode, MessageKind.STRING_EXPECTED, {'type': type});
        } else {
          StringConstantValue stringConstant = name;
          String nameString = stringConstant.primitiveValue;
          if (validateSymbol(argumentNode, nameString)) {
            registry.registerConstSymbol(nameString);
          }
        }
      } else if (commonElements.isMirrorsUsedConstructor(constructor)) {
        resolution.mirrorUsageAnalyzerTask.validate(node, registry.mapping);
      }

      analyzeConstantDeferred(node);

      if (type.containsTypeVariables) {
        reporter.reportErrorMessage(
            node.send.selector, MessageKind.TYPE_VARIABLE_IN_CONSTANT);
        isValidAsConstant = false;
        isInvalid = true;
      }

      if (result.isDeferred) {
        isValidAsConstant = false;
      }

      // Callback hook for when the compile-time constant evaluator has
      // analyzed the constant.
      // TODO(johnniwinther): Remove this when all constants are computed
      // in resolution.
      Function onAnalyzed;
      if (isValidAsConstant &&
          argumentsResult.isValidAsConstant &&
          // TODO(johnniwinther): Remove this when all constants are computed
          // in resolution.
          !constructor.isFromEnvironmentConstructor) {
        ResolutionInterfaceType interfaceType = type;
        CallStructure callStructure = argumentsResult.callStructure;
        List<ConstantExpression> arguments = argumentsResult.constantArguments;

        ConstructedConstantExpression constant =
            new ConstructedConstantExpression(
                interfaceType, constructor, callStructure, arguments);
        registry.registerNewStructure(node,
            new ConstInvokeStructure(ConstantInvokeKind.CONSTRUCTED, constant));
        resolutionResult = new ConstantResult(node, constant);
      } else if (isInvalid) {
        // Known to be non-constant.
        kind == ConstructorAccessKind.NON_CONSTANT_CONSTRUCTOR;
        registry.registerNewStructure(
            node,
            new NewInvokeStructure(
                new ConstructorAccessSemantics(kind, constructor, type),
                selector));
      } else {
        // Might be valid but we don't know for sure. The compile-time constant
        // evaluator will compute the actual constant as a deferred action.
        LateConstInvokeStructure structure =
            new LateConstInvokeStructure(registry.mapping);
        // TODO(johnniwinther): Avoid registering the
        // [LateConstInvokeStructure]; it might not be necessary.
        registry.registerNewStructure(node, structure);
        onAnalyzed = () {
          registry.registerNewStructure(node, structure.resolve(node));
        };
      }

      analyzeConstantDeferred(node, onAnalyzed: onAnalyzed);
    } else {
      // Not constant.
      if (resolution.commonElements.isSymbolConstructor(constructor) &&
          !resolution.mirrorUsageAnalyzerTask
              .hasMirrorUsage(enclosingElement)) {
        reporter.reportHintMessage(
            reporter.spanFromToken(node.newToken),
            MessageKind.NON_CONST_BLOAT,
            {'name': commonElements.symbolClass.name});
      }
      registry.registerNewStructure(
          node,
          new NewInvokeStructure(
              new ConstructorAccessSemantics(kind, constructor, type),
              selector));
    }

    return resolutionResult;
  }

  void checkConstMapKeysDontOverrideEquals(
      Spannable spannable, MapConstantValue map) {
    for (ConstantValue key in map.keys) {
      if (!key.isObject) continue;
      ObjectConstantValue objectConstant = key;
      ResolutionInterfaceType keyType = objectConstant.type;
      ClassElement cls = keyType.element;
      if (cls == commonElements.stringClass) continue;
      Element equals = cls.lookupMember('==');
      if (equals.enclosingClass != commonElements.objectClass) {
        reporter.reportErrorMessage(spannable,
            MessageKind.CONST_MAP_KEY_OVERRIDES_EQUALS, {'type': keyType});
      }
    }
  }

  void analyzeConstant(Node node, {enforceConst: true}) {
    ConstantExpression constant = resolver.constantCompiler
        .compileNode(node, registry.mapping, enforceConst: enforceConst);

    if (constant == null) {
      assert(reporter.hasReportedError, failedAt(node));
      return;
    }

    ConstantValue value = resolution.constants.getConstantValue(constant);
    if (value.isMap) {
      checkConstMapKeysDontOverrideEquals(node, value);
    }
  }

  void analyzeConstantDeferred(Node node,
      {bool enforceConst: true, void onAnalyzed()}) {
    addDeferredAction(enclosingElement, () {
      analyzeConstant(node, enforceConst: enforceConst);
      if (onAnalyzed != null) {
        onAnalyzed();
      }
    });
  }

  bool validateSymbol(Node node, String name, {bool reportError: true}) {
    if (name.isEmpty) return true;
    if (name.startsWith('_')) {
      if (reportError) {
        reporter.reportErrorMessage(
            node, MessageKind.PRIVATE_IDENTIFIER, {'value': name});
      }
      return false;
    }
    if (!symbolValidationPattern.hasMatch(name)) {
      if (reportError) {
        reporter.reportErrorMessage(
            node, MessageKind.INVALID_SYMBOL, {'value': name});
      }
      return false;
    }
    return true;
  }

  /**
   * Try to resolve the constructor that is referred to by [node].
   * Note: this function may return an ErroneousFunctionElement instead of
   * [:null:], if there is no corresponding constructor, class or library.
   */
  ConstructorResult resolveConstructor(NewExpression node) {
    return node.accept(new ConstructorResolver(resolution, this,
        inConstContext: node.isConst));
  }

  ConstructorResult resolveRedirectingFactory(RedirectingFactoryBody node,
      {bool inConstContext: false}) {
    return node.accept(new ConstructorResolver(resolution, this,
        inConstContext: inConstContext));
  }

  ResolutionDartType resolveTypeAnnotation(TypeAnnotation node,
      {FunctionTypeParameterScope functionTypeParameters:
          const FunctionTypeParameterScope(),
      bool malformedIsError: false,
      bool deferredIsMalformed: true,
      bool registerCheckedModeCheck: true}) {
    ResolutionDartType type = typeResolver.resolveTypeAnnotation(
        this, node, functionTypeParameters,
        malformedIsError: malformedIsError,
        deferredIsMalformed: deferredIsMalformed);
    if (registerCheckedModeCheck) {
      registry.registerCheckedModeCheck(type);
    }
    return type;
  }

  ResolutionResult visitLiteralList(LiteralList node) {
    bool isValidAsConstant = true;
    sendIsMemberAccess = false;

    NodeList arguments = node.typeArguments;
    ResolutionDartType typeArgument;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty) {
        // The syntax [: <>[] :] is not allowed.
        reporter.reportErrorMessage(
            arguments, MessageKind.MISSING_TYPE_ARGUMENT);
        isValidAsConstant = false;
      } else {
        typeArgument = resolveTypeAnnotation(nodes.head);
        for (nodes = nodes.tail; !nodes.isEmpty; nodes = nodes.tail) {
          reporter.reportWarningMessage(
              nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
          resolveTypeAnnotation(nodes.head);
        }
      }
    }
    ResolutionInterfaceType listType;
    if (typeArgument != null) {
      if (node.isConst && typeArgument.containsTypeVariables) {
        reporter.reportErrorMessage(
            arguments.nodes.head, MessageKind.TYPE_VARIABLE_IN_CONSTANT);
        isValidAsConstant = false;
      }
      listType = commonElements.listType(typeArgument);
    } else {
      listType = commonElements.listType();
    }
    registry.registerLiteralList(node, listType,
        isConstant: node.isConst, isEmpty: node.elements.isEmpty);
    if (node.isConst) {
      List<ConstantExpression> constantExpressions = <ConstantExpression>[];
      inConstantContext(() {
        for (Node element in node.elements) {
          ResolutionResult elementResult = visit(element);
          if (isValidAsConstant && elementResult.isConstant) {
            constantExpressions.add(elementResult.constant);
          } else {
            isValidAsConstant = false;
          }
        }
      });
      analyzeConstantDeferred(node);
      sendIsMemberAccess = false;
      if (isValidAsConstant) {
        ConstantExpression constant =
            new ListConstantExpression(listType, constantExpressions);
        registry.setConstant(node, constant);
        return new ConstantResult(node, constant);
      }
    } else {
      visit(node.elements);
      sendIsMemberAccess = false;
    }
    return const NoneResult();
  }

  ResolutionResult visitConditional(Conditional node) {
    ResolutionResult conditionResult =
        doInPromotionScope(node.condition, () => visit(node.condition));
    ResolutionResult thenResult = doInPromotionScope(
        node.thenExpression, () => visit(node.thenExpression));
    ResolutionResult elseResult = visit(node.elseExpression);
    if (conditionResult.isConstant &&
        thenResult.isConstant &&
        elseResult.isConstant) {
      ConstantExpression constant = new ConditionalConstantExpression(
          conditionResult.constant, thenResult.constant, elseResult.constant);
      registry.setConstant(node, constant);
      return new ConstantResult(node, constant);
    }
    return const NoneResult();
  }

  ResolutionResult visitStringInterpolation(StringInterpolation node) {
    // TODO(johnniwinther): This should be a consequence of the registration
    // of [registerStringInterpolation].
    registry.registerFeature(Feature.STRING_INTERPOLATION);

    bool isValidAsConstant = true;
    List<ConstantExpression> parts = <ConstantExpression>[];

    void resolvePart(Node subnode) {
      ResolutionResult result = visit(subnode);
      if (isValidAsConstant && result.isConstant) {
        parts.add(result.constant);
      } else {
        isValidAsConstant = false;
      }
    }

    resolvePart(node.string);
    for (StringInterpolationPart part in node.parts) {
      resolvePart(part.expression);
      resolvePart(part.string);
    }

    if (isValidAsConstant) {
      ConstantExpression constant = new ConcatenateConstantExpression(parts);
      registry.setConstant(node, constant);
      return new ConstantResult(node, constant);
    }
    return const NoneResult();
  }

  ResolutionResult visitBreakStatement(BreakStatement node) {
    JumpTargetX target;
    if (node.target == null) {
      target = statementScope.currentBreakTarget();
      if (target == null) {
        reporter.reportErrorMessage(node, MessageKind.NO_BREAK_TARGET);
        return const NoneResult();
      }
      target.isBreakTarget = true;
    } else {
      String labelName = node.target.source;
      LabelDefinitionX label = statementScope.lookupLabel(labelName);
      if (label == null) {
        reporter.reportErrorMessage(
            node.target, MessageKind.UNBOUND_LABEL, {'labelName': labelName});
        return const NoneResult();
      }
      target = label.target;
      if (!target.statement.isValidBreakTarget()) {
        reporter.reportErrorMessage(node.target, MessageKind.INVALID_BREAK);
        return const NoneResult();
      }
      label.setBreakTarget();
      registry.useLabel(node, label);
    }
    registry.registerTargetOf(node, target);
    return const NoneResult();
  }

  ResolutionResult visitContinueStatement(ContinueStatement node) {
    JumpTargetX target;
    if (node.target == null) {
      target = statementScope.currentContinueTarget();
      if (target == null) {
        reporter.reportErrorMessage(node, MessageKind.NO_CONTINUE_TARGET);
        return const NoneResult();
      }
      target.isContinueTarget = true;
    } else {
      String labelName = node.target.source;
      LabelDefinitionX label = statementScope.lookupLabel(labelName);
      if (label == null) {
        reporter.reportErrorMessage(
            node.target, MessageKind.UNBOUND_LABEL, {'labelName': labelName});
        return const NoneResult();
      }
      target = label.target;
      if (!target.statement.isValidContinueTarget()) {
        reporter.reportErrorMessage(node.target, MessageKind.INVALID_CONTINUE);
      }
      label.setContinueTarget();
      registry.useLabel(node, label);
    }
    registry.registerTargetOf(node, target);
    return const NoneResult();
  }

  ResolutionResult visitAsyncForIn(AsyncForIn node) {
    if (!resolution.target.supportsAsyncAwait) {
      reporter.reportErrorMessage(reporter.spanFromToken(node.awaitToken),
          MessageKind.ASYNC_AWAIT_NOT_SUPPORTED);
    } else {
      if (!currentAsyncMarker.isAsync) {
        reporter.reportErrorMessage(reporter.spanFromToken(node.awaitToken),
            MessageKind.INVALID_AWAIT_FOR_IN);
      }
      registry.registerFeature(Feature.ASYNC_FOR_IN);
      registry.registerDynamicUse(new DynamicUse(Selectors.current, null));
      registry.registerDynamicUse(new DynamicUse(Selectors.moveNext, null));
    }
    visit(node.expression);

    Scope blockScope = new BlockScope(scope);
    visitForInDeclaredIdentifierIn(node.declaredIdentifier, node, blockScope);
    visitLoopBodyIn(node, node.body, blockScope);
    return const NoneResult();
  }

  ResolutionResult visitSyncForIn(SyncForIn node) {
    registry.registerFeature(Feature.SYNC_FOR_IN);
    registry.registerDynamicUse(new DynamicUse(Selectors.iterator, null));
    registry.registerDynamicUse(new DynamicUse(Selectors.current, null));
    registry.registerDynamicUse(new DynamicUse(Selectors.moveNext, null));

    visit(node.expression);

    Scope blockScope = new BlockScope(scope);
    visitForInDeclaredIdentifierIn(node.declaredIdentifier, node, blockScope);
    visitLoopBodyIn(node, node.body, blockScope);
    return const NoneResult();
  }

  void visitForInDeclaredIdentifierIn(
      Node declaration, ForIn node, Scope blockScope) {
    LibraryElement library = enclosingElement.library;

    bool oldAllowFinalWithoutInitializer = inLoopVariable;
    inLoopVariable = true;
    visitIn(declaration, blockScope);
    inLoopVariable = oldAllowFinalWithoutInitializer;

    Send send = declaration.asSend();
    VariableDefinitions variableDefinitions =
        declaration.asVariableDefinitions();
    Element loopVariable;
    Selector loopVariableSelector;
    if (send != null) {
      loopVariable = registry.getDefinition(send);
      Identifier identifier = send.selector.asIdentifier();
      if (identifier == null) {
        reporter.reportErrorMessage(send.selector, MessageKind.INVALID_FOR_IN);
      } else {
        loopVariableSelector =
            new Selector.setter(new Name(identifier.source, library));
      }
      if (send.receiver != null) {
        reporter.reportErrorMessage(send.receiver, MessageKind.INVALID_FOR_IN);
      }
    } else if (variableDefinitions != null) {
      Link<Node> nodes = variableDefinitions.definitions.nodes;
      if (!nodes.tail.isEmpty) {
        reporter.reportErrorMessage(
            nodes.tail.head, MessageKind.INVALID_FOR_IN);
      }
      Node first = nodes.head;
      Identifier identifier = first.asIdentifier();
      if (identifier == null) {
        reporter.reportErrorMessage(first, MessageKind.INVALID_FOR_IN);
      } else {
        loopVariableSelector =
            new Selector.setter(new Name(identifier.source, library));
        loopVariable = registry.getDefinition(identifier);
      }
    } else {
      reporter.reportErrorMessage(declaration, MessageKind.INVALID_FOR_IN);
    }
    if (loopVariableSelector != null) {
      registry.setSelector(declaration, loopVariableSelector);
      if (loopVariable == null || loopVariable.isInstanceMember) {
        registry.registerDynamicUse(new DynamicUse(loopVariableSelector, null));
      } else if (loopVariable.isStatic || loopVariable.isTopLevel) {
        MemberElement member = loopVariable.declaration;
        registry.registerStaticUse(new StaticUse.staticSet(member));
      }
    } else {
      // The selector may only be null if we reported an error.
      assert(reporter.hasReportedError, failedAt(declaration));
    }
    if (loopVariable != null) {
      // loopVariable may be null if it could not be resolved.
      registry.setForInVariable(node, loopVariable);
    }
  }

  visitLabel(Label node) {
    // Labels are handled by their containing statements/cases.
  }

  ResolutionResult visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    JumpTarget targetElement = getOrDefineTarget(body);
    Map<String, LabelDefinitionX> labelElements = <String, LabelDefinitionX>{};
    for (Label label in node.labels) {
      String labelName = label.labelName;
      if (labelElements.containsKey(labelName)) continue;
      LabelDefinition element = targetElement.addLabel(label, labelName);
      labelElements[labelName] = element;
    }
    statementScope.enterLabelScope(labelElements);
    visit(node.statement);
    statementScope.exitLabelScope();
    labelElements.forEach((String labelName, LabelDefinitionX element) {
      if (element.isTarget) {
        registry.defineLabel(element.label, element);
      } else {
        reporter.reportWarningMessage(
            element.label, MessageKind.UNUSED_LABEL, {'labelName': labelName});
      }
    });
    if (!targetElement.isTarget) {
      registry.undefineTarget(body);
    }
    return const NoneResult();
  }

  ResolutionResult visitLiteralMap(LiteralMap node) {
    bool isValidAsConstant = true;
    sendIsMemberAccess = false;

    NodeList arguments = node.typeArguments;
    ResolutionDartType keyTypeArgument;
    ResolutionDartType valueTypeArgument;
    if (arguments != null) {
      Link<Node> nodes = arguments.nodes;
      if (nodes.isEmpty) {
        // The syntax [: <>{} :] is not allowed.
        reporter.reportErrorMessage(
            arguments, MessageKind.MISSING_TYPE_ARGUMENT);
        isValidAsConstant = false;
      } else {
        keyTypeArgument = resolveTypeAnnotation(nodes.head);
        nodes = nodes.tail;
        if (nodes.isEmpty) {
          reporter.reportWarningMessage(
              arguments, MessageKind.MISSING_TYPE_ARGUMENT);
        } else {
          valueTypeArgument = resolveTypeAnnotation(nodes.head);
          for (nodes = nodes.tail; !nodes.isEmpty; nodes = nodes.tail) {
            reporter.reportWarningMessage(
                nodes.head, MessageKind.ADDITIONAL_TYPE_ARGUMENT);
            resolveTypeAnnotation(nodes.head);
          }
        }
      }
    }
    ResolutionInterfaceType mapType;
    if (valueTypeArgument != null) {
      mapType = commonElements.mapType(keyTypeArgument, valueTypeArgument);
    } else {
      mapType = commonElements.mapType();
    }
    if (node.isConst && mapType.containsTypeVariables) {
      reporter.reportErrorMessage(
          arguments, MessageKind.TYPE_VARIABLE_IN_CONSTANT);
      isValidAsConstant = false;
    }
    registry.registerMapLiteral(node, mapType,
        isConstant: node.isConst, isEmpty: node.entries.isEmpty);

    if (node.isConst) {
      List<ConstantExpression> keyExpressions = <ConstantExpression>[];
      List<ConstantExpression> valueExpressions = <ConstantExpression>[];
      inConstantContext(() {
        for (LiteralMapEntry entry in node.entries) {
          ResolutionResult keyResult = visit(entry.key);
          ResolutionResult valueResult = visit(entry.value);
          if (isValidAsConstant &&
              keyResult.isConstant &&
              valueResult.isConstant) {
            keyExpressions.add(keyResult.constant);
            valueExpressions.add(valueResult.constant);
          } else {
            isValidAsConstant = false;
          }
        }
      });
      analyzeConstantDeferred(node);
      sendIsMemberAccess = false;
      if (isValidAsConstant) {
        ConstantExpression constant = new MapConstantExpression(
            mapType, keyExpressions, valueExpressions);
        registry.setConstant(node, constant);
        return new ConstantResult(node, constant);
      }
    } else {
      node.visitChildren(this);
      sendIsMemberAccess = false;
    }
    return const NoneResult();
  }

  ResolutionResult visitLiteralMapEntry(LiteralMapEntry node) {
    node.visitChildren(this);
    return const NoneResult();
  }

  ResolutionResult visitNamedArgument(NamedArgument node) {
    return visit(node.expression);
  }

  ResolutionInterfaceType typeOfConstant(ConstantValue constant) {
    if (constant.isInt) return commonElements.intType;
    if (constant.isBool) return commonElements.boolType;
    if (constant.isDouble) return commonElements.doubleType;
    if (constant.isString) return commonElements.stringType;
    if (constant.isNull) return commonElements.nullType;
    if (constant.isFunction) return commonElements.functionType;
    assert(constant.isObject);
    ObjectConstantValue objectConstant = constant;
    ResolutionInterfaceType type = objectConstant.type;
    return type;
  }

  bool overridesEquals(ResolutionDartType type) {
    ClassElement cls = type.element;
    Element equals = cls.lookupMember('==');
    return equals.enclosingClass != commonElements.objectClass;
  }

  void checkCaseExpressions(SwitchStatement node) {
    CaseMatch firstCase = null;
    ResolutionDartType firstCaseType = null;
    DiagnosticMessage error;
    List<DiagnosticMessage> infos = <DiagnosticMessage>[];

    for (Link<Node> cases = node.cases.nodes;
        !cases.isEmpty;
        cases = cases.tail) {
      SwitchCase switchCase = cases.head;

      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch == null) continue;

        // Analyze the constant.
        ConstantExpression constant =
            registry.getConstant(caseMatch.expression);
        assert(
            constant != null, failedAt(node, 'No constant computed for $node'));

        ConstantValue value = resolution.constants.getConstantValue(constant);
        ResolutionDartType caseType =
            value.getType(commonElements); //typeOfConstant(value);

        if (firstCaseType == null) {
          firstCase = caseMatch;
          firstCaseType = caseType;

          // We only report the bad type on the first class element. All others
          // get a "type differs" error.
          if (caseType == commonElements.doubleType) {
            reporter.reportErrorMessage(
                node,
                MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
                {'type': "double"});
          } else if (caseType == commonElements.functionType) {
            reporter.reportErrorMessage(
                node, MessageKind.SWITCH_CASE_FORBIDDEN, {'type': "Function"});
          } else if (value.isObject && overridesEquals(caseType)) {
            reporter.reportErrorMessage(
                firstCase.expression,
                MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS,
                {'type': caseType});
          }
        } else {
          if (caseType != firstCaseType) {
            if (error == null) {
              error = reporter.createMessage(
                  node,
                  MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL,
                  {'type': firstCaseType});
              infos.add(reporter.createMessage(
                  firstCase.expression,
                  MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
                  {'type': firstCaseType}));
            }
            infos.add(reporter.createMessage(
                caseMatch.expression,
                MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL_CASE,
                {'type': caseType}));
          }
        }
      }
    }
    if (error != null) {
      reporter.reportError(error, infos);
    }
  }

  ResolutionResult visitSwitchStatement(SwitchStatement node) {
    node.expression.accept(this);

    JumpTarget breakElement = getOrDefineTarget(node);
    Map<String, LabelDefinitionX> continueLabels = <String, LabelDefinitionX>{};
    Set<SwitchCase> switchCasesWithContinues = new Set<SwitchCase>();
    Link<Node> cases = node.cases.nodes;
    while (!cases.isEmpty) {
      SwitchCase switchCase = cases.head;
      for (Node labelOrCase in switchCase.labelsAndCases) {
        CaseMatch caseMatch = labelOrCase.asCaseMatch();
        if (caseMatch != null) {
          analyzeConstantDeferred(caseMatch.expression);
          continue;
        }
        Label label = labelOrCase;
        String labelName = label.labelName;

        LabelDefinitionX existingElement = continueLabels[labelName];
        if (existingElement != null) {
          // It's an error if the same label occurs twice in the same switch.
          reporter.reportError(
              reporter.createMessage(
                  label, MessageKind.DUPLICATE_LABEL, {'labelName': labelName}),
              <DiagnosticMessage>[
                reporter.createMessage(existingElement.label,
                    MessageKind.EXISTING_LABEL, {'labelName': labelName}),
              ]);
        } else {
          // It's only a warning if it shadows another label.
          existingElement = statementScope.lookupLabel(labelName);
          if (existingElement != null) {
            reporter.reportWarning(
                reporter.createMessage(label, MessageKind.DUPLICATE_LABEL,
                    {'labelName': labelName}),
                <DiagnosticMessage>[
                  reporter.createMessage(existingElement.label,
                      MessageKind.EXISTING_LABEL, {'labelName': labelName}),
                ]);
          }
        }

        JumpTarget targetElement = getOrDefineTarget(switchCase);
        LabelDefinition labelElement = targetElement.addLabel(label, labelName);
        registry.defineLabel(label, labelElement);
        continueLabels[labelName] = labelElement;
      }
      cases = cases.tail;
      // Test that only the last case, if any, is a default case.
      if (switchCase.defaultKeyword != null && !cases.isEmpty) {
        reporter.reportErrorMessage(
            switchCase, MessageKind.INVALID_CASE_DEFAULT);
      }
      if (cases.isNotEmpty && switchCase.statements.isNotEmpty) {
        Node last = switchCase.statements.last;
        if (last.asReturn() == null &&
            last.asBreakStatement() == null &&
            last.asContinueStatement() == null &&
            (last.asExpressionStatement() == null ||
                last.asExpressionStatement().expression.asThrow() == null)) {
          registry.registerFeature(Feature.FALL_THROUGH_ERROR);
        }
      }
    }

    addDeferredAction(enclosingElement, () {
      checkCaseExpressions(node);
    });

    statementScope.enterSwitch(breakElement, continueLabels);
    node.cases.accept(this);
    statementScope.exitSwitch();

    continueLabels.forEach((String key, LabelDefinition label) {
      if (label.isContinueTarget) {
        JumpTarget targetElement = label.target;
        SwitchCase switchCase = targetElement.statement;
        switchCasesWithContinues.add(switchCase);
      }
    });

    // Clean-up unused labels.
    continueLabels.forEach((String key, LabelDefinitionX label) {
      if (!label.isContinueTarget) {
        JumpTarget targetElement = label.target;
        SwitchCase switchCase = targetElement.statement;
        if (!switchCasesWithContinues.contains(switchCase)) {
          registry.undefineTarget(switchCase);
        }
        registry.undefineLabel(label.label);
      }
    });
    // TODO(15575): We should warn if we can detect a fall through
    // error.
    return const NoneResult();
  }

  ResolutionResult visitSwitchCase(SwitchCase node) {
    node.labelsAndCases.accept(this);
    visitIn(node.statements, new BlockScope(scope));
    return const NoneResult();
  }

  ResolutionResult visitCaseMatch(CaseMatch node) {
    visit(node.expression);
    return const NoneResult();
  }

  ResolutionResult visitTryStatement(TryStatement node) {
    // TODO(karlklose): also track the information about mutated variables,
    // catch, and finally-block.
    registry.registerTryStatement();

    visit(node.tryBlock);
    if (node.catchBlocks.isEmpty && node.finallyBlock == null) {
      reporter.reportErrorMessage(
          reporter.spanFromToken(node.getEndToken().next),
          MessageKind.NO_CATCH_NOR_FINALLY);
    }
    visit(node.catchBlocks);
    visit(node.finallyBlock);
    return const NoneResult();
  }

  ResolutionResult visitCatchBlock(CatchBlock node) {
    registry.registerFeature(Feature.CATCH_STATEMENT);
    // Check that if catch part is present, then
    // it has one or two formal parameters.
    VariableDefinitions exceptionDefinition;
    VariableDefinitions stackTraceDefinition;
    if (node.formals != null) {
      Link<Node> formalsToProcess = node.formals.nodes;
      if (formalsToProcess.isEmpty) {
        reporter.reportErrorMessage(node, MessageKind.EMPTY_CATCH_DECLARATION);
      } else {
        exceptionDefinition = formalsToProcess.head.asVariableDefinitions();
        formalsToProcess = formalsToProcess.tail;
        if (!formalsToProcess.isEmpty) {
          stackTraceDefinition = formalsToProcess.head.asVariableDefinitions();
          formalsToProcess = formalsToProcess.tail;
          if (!formalsToProcess.isEmpty) {
            for (Node extra in formalsToProcess) {
              reporter.reportErrorMessage(
                  extra, MessageKind.EXTRA_CATCH_DECLARATION);
            }
          }
          registry.registerFeature(Feature.STACK_TRACE_IN_CATCH);
        }
      }

      // Check that the formals aren't optional and that they have no
      // modifiers or type.
      for (Link<Node> link = node.formals.nodes;
          !link.isEmpty;
          link = link.tail) {
        // If the formal parameter is a node list, it means that it is a
        // sequence of optional parameters.
        NodeList nodeList = link.head.asNodeList();
        if (nodeList != null) {
          reporter.reportErrorMessage(
              nodeList, MessageKind.OPTIONAL_PARAMETER_IN_CATCH);
        } else {
          VariableDefinitions declaration = link.head;

          for (Node modifier in declaration.modifiers.nodes) {
            reporter.reportErrorMessage(
                modifier, MessageKind.PARAMETER_WITH_MODIFIER_IN_CATCH);
          }
          TypeAnnotation type = declaration.type;
          if (type != null) {
            reporter.reportErrorMessage(
                type, MessageKind.PARAMETER_WITH_TYPE_IN_CATCH);
          }
        }
      }
    }

    Scope blockScope = new BlockScope(scope);
    inCatchParameters = true;
    visitIn(node.formals, blockScope);
    inCatchParameters = false;
    var oldInCatchBlock = inCatchBlock;
    inCatchBlock = true;
    visitIn(node.block, blockScope);
    inCatchBlock = oldInCatchBlock;

    if (node.type != null) {
      ResolutionDartType exceptionType =
          resolveTypeAnnotation(node.type, registerCheckedModeCheck: false);
      if (exceptionDefinition != null) {
        Node exceptionVariable = exceptionDefinition.definitions.nodes.head;
        VariableElementX exceptionElement =
            registry.getDefinition(exceptionVariable);
        exceptionElement.variables.type = exceptionType;
      }
      registry.registerTypeUse(new TypeUse.catchType(exceptionType));
    }
    if (stackTraceDefinition != null) {
      Node stackTraceVariable = stackTraceDefinition.definitions.nodes.head;
      VariableElementX stackTraceElement =
          registry.getDefinition(stackTraceVariable);
      ResolutionInterfaceType stackTraceType = commonElements.stackTraceType;
      stackTraceElement.variables.type = stackTraceType;
    }
    return const NoneResult();
  }
}

/// Looks up [name] in [scope] and unwraps the result.
Element lookupInScope(
    DiagnosticReporter reporter, Node node, Scope scope, String name) {
  return Elements.unwrap(scope.lookup(name), reporter, node);
}
