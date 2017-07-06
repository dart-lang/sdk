// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.converter;

import '../../ast.dart'
    show
        Arguments,
        Block,
        Catch,
        Class,
        ClosureCreation,
        Constructor,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        ExpressionStatement,
        Field,
        FieldInitializer,
        ForInStatement,
        ForStatement,
        FunctionDeclaration,
        FunctionExpression,
        FunctionNode,
        FunctionType,
        Initializer,
        InterfaceType,
        InvalidExpression,
        InvocationExpression,
        Let,
        Library,
        LocalInitializer,
        Member,
        MethodInvocation,
        Name,
        NamedExpression,
        NamedType,
        NullLiteral,
        Procedure,
        ProcedureKind,
        PropertyGet,
        ReturnStatement,
        Statement,
        StaticGet,
        StaticInvocation,
        ThisExpression,
        Transformer,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        VariableGet,
        VariableSet,
        VectorType,
        transformList;

import '../../frontend/accessors.dart' show VariableAccessor;

import '../../clone.dart' show CloneVisitor;

import '../../core_types.dart' show CoreTypes;

import '../../type_algebra.dart' show substitute;

import 'clone_without_body.dart' show CloneWithoutBody;

import 'context.dart' show Context, NoContext;

import 'info.dart' show ClosureInfo;

import 'rewriter.dart'
    show
        AstRewriter,
        BlockRewriter,
        InitializerRewriter,
        FieldInitializerRewriter,
        LocalInitializerRewriter;

class ClosureConverter extends Transformer {
  final CoreTypes coreTypes;
  final Set<VariableDeclaration> capturedVariables;
  final Map<FunctionNode, Set<TypeParameter>> capturedTypeVariables;
  final Map<FunctionNode, VariableDeclaration> thisAccess;
  final Map<FunctionNode, String> localNames;

  /// Records place-holders for cloning contexts. See [visitForStatement].
  final Set<InvalidExpression> contextClonePlaceHolders =
      new Set<InvalidExpression>();

  /// Maps the names of all instance methods that may be torn off (aka
  /// implicitly closurized) to `${name.name}#get`.
  final Map<Name, Name> tearOffGetterNames;

  final CloneVisitor cloner = new CloneWithoutBody();

  /// New members to add to [currentLibrary] after it has been
  /// transformed. These members will not be transformed themselves.
  final List<TreeNode> newLibraryMembers = <TreeNode>[];

  /// New members to add to [currentClass] after it has been transformed. These
  /// members will not be transformed themselves.
  final List<Member> newClassMembers = <Member>[];

  Library currentLibrary;

  Class currentClass;

  Member currentMember;

  FunctionNode currentMemberFunction;

  FunctionNode currentFunction;

  Context context;

  AstRewriter rewriter;

  /// TODO(29181): update this comment when the type variables are restored.
  /// Maps original type variable (aka type parameter) to a hoisted type
  /// variable type.
  ///
  /// For example, consider:
  ///
  ///     class C<T> {
  ///       f() => (x) => x is T;
  ///     }
  ///
  /// This is currently converted to:
  ///
  ///    class C<T> {
  ///      f() => new Closure#0<T>();
  ///    }
  ///    class Closure#0<T_> implements Function {
  ///      call(x) => x is T_;
  ///    }
  ///
  /// In this example, `typeSubstitution[T].parameter == T_` when transforming
  /// the closure in `f`.
  Map<TypeParameter, DartType> typeSubstitution =
      const <TypeParameter, DartType>{};

  ClosureConverter(this.coreTypes, ClosureInfo info)
      : this.capturedVariables = info.variables,
        this.capturedTypeVariables = info.typeVariables,
        this.thisAccess = info.thisAccess,
        this.localNames = info.localNames,
        this.tearOffGetterNames = info.tearOffGetterNames;

  bool get isOuterMostContext {
    return currentFunction == null || currentMemberFunction == currentFunction;
  }

  String get currentFileUri {
    if (currentMember is Constructor) return currentClass.fileUri;
    if (currentMember is Field) return (currentMember as Field).fileUri;
    if (currentMember is Procedure) return (currentMember as Procedure).fileUri;
    throw "No file uri for ${currentMember.runtimeType}";
  }

  TreeNode saveContext(TreeNode f()) {
    AstRewriter old = rewriter;
    Context savedContext = context;
    try {
      return f();
    } finally {
      rewriter = old;
      context = savedContext;
    }
  }

  TreeNode visitLibrary(Library node) {
    assert(newLibraryMembers.isEmpty);

    currentLibrary = node;
    node = super.visitLibrary(node);
    for (TreeNode member in newLibraryMembers) {
      if (member is Class) {
        node.addClass(member);
      } else {
        node.addMember(member);
      }
    }
    newLibraryMembers.clear();
    currentLibrary = null;
    return node;
  }

  TreeNode visitClass(Class node) {
    assert(newClassMembers.isEmpty);
    currentClass = node;
    node = super.visitClass(node);
    newClassMembers.forEach(node.addMember);
    newClassMembers.clear();
    currentClass = null;
    return node;
  }

  void extendContextWith(VariableDeclaration parameter) {
    context.extend(parameter, new VariableGet(parameter));
  }

  static InitializerRewriter getRewriterForInitializer(
      Initializer initializer) {
    if (initializer is FieldInitializer) {
      return new FieldInitializerRewriter(initializer.value);
    }
    if (initializer is LocalInitializer) {
      return new LocalInitializerRewriter(initializer.variable.initializer);
    }
    throw "Trying to extract an initializer expression from "
        "${initializer.runtimeType}, but only FieldInitializer and "
        "LocalInitializer are supported.";
  }

  static Expression getInitializerExpression(Initializer initializer) {
    if (initializer is FieldInitializer) {
      return initializer.value;
    }
    if (initializer is LocalInitializer) {
      return initializer.variable.initializer;
    }
    throw "Trying to get initializing expressino from "
        "${initializer.runtimeType}, but only Field Initializer and "
        "LocalInitializer are supported.";
  }

  TreeNode visitConstructor(Constructor node) {
    assert(isEmptyContext);
    currentMember = node;
    // Transform initializers.
    for (Initializer initializer in node.initializers) {
      if (initializer is FieldInitializer || initializer is LocalInitializer) {
        // Create a rewriter and a context for the initializer expression.
        InitializerRewriter initializerRewriter =
            getRewriterForInitializer(initializer);
        rewriter = initializerRewriter;
        context = new NoContext(this);
        // Save the expression to visit it in the extended context, since the
        // rewriter will modify `initializer.value` (for [FieldInitializer]) or
        // `initializer.variable.initializer` (for [LocalInitializer]).
        Expression initializerExpression =
            getInitializerExpression(initializer);
        // Extend the context with all captured parameters of the constructor.
        // TODO(karlklose): add a fine-grained analysis of captured parameters.
        node.function.positionalParameters
            .where(capturedVariables.contains)
            .forEach(extendContextWith);
        node.function.namedParameters
            .where(capturedVariables.contains)
            .forEach(extendContextWith);
        // Transform the initializer expression.
        var parent = initializerExpression.parent;
        initializerExpression = initializerExpression.accept(this);
        initializerExpression.parent = parent;
        if (parent is Let) {
          parent.body = initializerExpression;
        } else if (parent is FieldInitializer) {
          parent.value = initializerExpression;
        } else if (parent is LocalInitializer) {
          parent.variable.initializer = initializerExpression;
        } else {
          throw "Found unexpected node '${node.runtimeType}, expected a 'Let' "
              ",a 'FieldInitializer', or a 'LocalInitializer'.";
        }
      }
    }
    rewriter = null;
    // Transform constructor body.
    FunctionNode function = node.function;
    if (function.body != null && function.body is! EmptyStatement) {
      setupContextForFunctionBody(function);
      VariableDeclaration self = thisAccess[currentMemberFunction];
      if (self != null) {
        context.extend(self, new ThisExpression());
      }
      node.function.accept(this);
      resetContext();
    }
    return node;
  }

  AstRewriter makeRewriterForBody(FunctionNode function) {
    Statement body = function.body;
    if (body is! Block) {
      body = new Block(<Statement>[body]);
      function.body = function.body.parent = body;
    }
    return new BlockRewriter(body);
  }

  bool isObject(DartType type) {
    return type is InterfaceType && type.classNode.supertype == null;
  }

  Expression handleLocalFunction(FunctionNode function) {
    FunctionNode enclosingFunction = currentFunction;
    Map<TypeParameter, DartType> enclosingTypeSubstitution = typeSubstitution;
    currentFunction = function;
    Statement body = function.body;
    assert(body != null);

    rewriter = makeRewriterForBody(function);

    VariableDeclaration contextVariable =
        new VariableDeclaration("#contextParameter", type: const VectorType());
    Context parent = context;
    context = context.toNestedContext(
        new VariableAccessor(contextVariable, null, TreeNode.noOffset));

    Set<TypeParameter> captured = capturedTypeVariables[currentFunction];
    if (captured != null) {
      typeSubstitution = copyTypeVariables(captured);
    } else {
      typeSubstitution = const <TypeParameter, DartType>{};
    }

    // TODO(29181): remove replacementTypeSubstitution variable and its usages.
    // All the type variables used in this function body are replaced with
    // either dynamic or their bounds. This is to temporarily remove the type
    // variables from closure conversion. They should be returned after the VM
    // changes are done to support vectors and closure creation. See #29181.
    Map<TypeParameter, DartType> replacementTypeSubstitution =
        <TypeParameter, DartType>{};
    for (TypeParameter parameter in typeSubstitution.keys) {
      replacementTypeSubstitution[parameter] = const DynamicType();
    }
    for (TypeParameter parameter in typeSubstitution.keys) {
      if (!isObject(parameter.bound)) {
        replacementTypeSubstitution[parameter] =
            substitute(parameter.bound, replacementTypeSubstitution);
      }
    }
    typeSubstitution = replacementTypeSubstitution;
    function.transformChildren(this);

    // TODO(29181): don't replace typeSubstitution with an empty map.
    // Information about captured type variables is deleted from the closure
    // class, because the type variables in this function body are already
    // replaced with either dynamic or their bounds. This change should be
    // undone after the VM support for vectors and closure creation is
    // implemented. See #29181.
    typeSubstitution = <TypeParameter, DartType>{};
    Expression result = addClosure(function, contextVariable, parent.expression,
        typeSubstitution, enclosingTypeSubstitution);
    currentFunction = enclosingFunction;
    typeSubstitution = enclosingTypeSubstitution;
    return result;
  }

  TreeNode visitFunctionDeclaration(FunctionDeclaration node) {
    /// Is this closure itself captured by a closure?
    bool isCaptured = capturedVariables.contains(node.variable);
    if (isCaptured) {
      context.extend(node.variable, new InvalidExpression());
    }
    Context parent = context;
    return saveContext(() {
      Expression expression = handleLocalFunction(node.function);

      if (isCaptured) {
        parent.update(node.variable, expression);
        return null;
      } else {
        node.variable.initializer = expression;
        expression.parent = node.variable;
        return node.variable;
      }
    });
  }

  TreeNode visitFunctionExpression(FunctionExpression node) {
    return saveContext(() {
      return handleLocalFunction(node.function);
    });
  }

  /// Add a new procedure to the current library that looks like this:
  ///
  ///     static method closure#0(Vector #c, /* Parameters of [function]. */)
  ///         → dynamic {
  ///
  ///       /* Context is represented by #c. */
  ///
  ///       /* Body of [function]. */
  ///
  ///     }
  ///
  /// Returns an invocation of the closure creation primitive that binds the
  /// above top-level function to a context represented as Vector.
  Expression addClosure(
      FunctionNode function,
      VariableDeclaration contextVariable,
      Expression accessContext,
      Map<TypeParameter, DartType> substitution,
      Map<TypeParameter, DartType> enclosingTypeSubstitution) {
    function.positionalParameters.insert(0, contextVariable);
    ++function.requiredParameterCount;
    Procedure closedTopLevelFunction = new Procedure(
        new Name(createNameForClosedTopLevelFunction(function)),
        ProcedureKind.Method,
        function,
        isStatic: true,
        fileUri: currentFileUri);
    newLibraryMembers.add(closedTopLevelFunction);

    FunctionType closureType = new FunctionType(
        function.positionalParameters
            .skip(1)
            .map((VariableDeclaration decl) => decl.type)
            .toList(),
        function.returnType,
        namedParameters: function.namedParameters
            .map((VariableDeclaration decl) =>
                new NamedType(decl.name, decl.type))
            .toList(),
        typeParameters: function.typeParameters,
        requiredParameterCount: function.requiredParameterCount - 1);

    return new ClosureCreation(
        closedTopLevelFunction, accessContext, closureType);
  }

  TreeNode visitField(Field node) {
    currentMember = node;
    context = new NoContext(this);
    if (node.isInstanceMember) {
      Name tearOffName = tearOffGetterNames[node.name];
      if (tearOffName != null) {
        // TODO(ahe): If we rewrite setters, we can rename the field to avoid
        // an indirection in most cases.
        addFieldForwarder(tearOffName, node);
      }
    }
    node = super.visitField(node);
    context = null;
    currentMember = null;
    return node;
  }

  TreeNode visitProcedure(Procedure node) {
    assert(isEmptyContext);

    currentMember = node;

    if (node.isInstanceMember) {
      Name tearOffName = tearOffGetterNames[node.name];
      if (tearOffName != null) {
        if (node.isGetter) {
          // We rename the getter to avoid an indirection in most cases.
          Name oldName = node.name;
          node.name = tearOffName;
          node.canonicalName?.unbind();
          addGetterForwarder(oldName, node);
        } else if (node.kind == ProcedureKind.Method) {
          addTearOffMethod(tearOffName, node);
        }
      }
    }

    FunctionNode function = node.function;
    if (function.body != null) {
      setupContextForFunctionBody(function);
      VariableDeclaration self = thisAccess[currentMemberFunction];
      if (self != null) {
        context.extend(self, new ThisExpression());
      }
      node.transformChildren(this);
      resetContext();
    }

    return node;
  }

  void setupContextForFunctionBody(FunctionNode function) {
    Statement body = function.body;
    assert(body != null);
    currentMemberFunction = function;
    // Ensure that the body is a block which becomes the current block.
    rewriter = makeRewriterForBody(function);
    // Start with no context.  This happens after setting up _currentBlock
    // so statements can be emitted into _currentBlock if necessary.
    context = new NoContext(this);
  }

  void resetContext() {
    rewriter = null;
    context = null;
    currentMemberFunction = null;
    currentMember = null;
  }

  bool get isEmptyContext {
    return rewriter == null && context == null;
  }

  TreeNode visitLocalInitializer(LocalInitializer node) {
    assert(!capturedVariables.contains(node.variable));
    node.transformChildren(this);
    return node;
  }

  TreeNode visitFunctionNode(FunctionNode node) {
    transformList(node.typeParameters, this, node);
    // TODO: Can parameters contain initializers (e.g., for optional ones) that
    // need to be closure converted?
    node.positionalParameters
        .where(capturedVariables.contains)
        .forEach(extendContextWith);
    node.namedParameters
        .where(capturedVariables.contains)
        .forEach(extendContextWith);
    assert(node.body != null);
    node.body = node.body.accept(this);
    node.body.parent = node;
    return node;
  }

  TreeNode visitBlock(Block node) {
    return saveContext(() {
      BlockRewriter blockRewriter = rewriter = rewriter.forNestedBlock(node);
      blockRewriter.transformStatements(node, this);
      return node;
    });
  }

  TreeNode visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);

    if (!capturedVariables.contains(node)) return node;
    if (node.initializer == null && node.parent is FunctionNode) {
      // If the variable is a function parameter and doesn't have an
      // initializer, just use this variable name to put it into the context.
      context.extend(node, new VariableGet(node));
    } else {
      context.extend(node, node.initializer ?? new NullLiteral());
    }

    if (node.parent == currentFunction) {
      return node;
    } else {
      assert(node.parent is Block);
      // When returning null, the parent block will remove this node from its
      // list of statements.
      return null;
    }
  }

  TreeNode visitVariableGet(VariableGet node) {
    return capturedVariables.contains(node.variable)
        ? context.lookup(node.variable)
        : node;
  }

  TreeNode visitVariableSet(VariableSet node) {
    node.transformChildren(this);

    return capturedVariables.contains(node.variable)
        ? context.assign(node.variable, node.value,
            voidContext: isInVoidContext(node))
        : node;
  }

  bool isInVoidContext(Expression node) {
    TreeNode parent = node.parent;
    return parent is ExpressionStatement ||
        parent is ForStatement && parent.condition != node;
  }

  DartType visitDartType(DartType node) {
    return substitute(node, typeSubstitution);
  }

  VariableDeclaration getReplacementLoopVariable(VariableDeclaration variable) {
    VariableDeclaration newVariable = new VariableDeclaration(variable.name,
        initializer: variable.initializer, type: variable.type)
      ..flags = variable.flags;
    variable.initializer = new VariableGet(newVariable);
    variable.initializer.parent = variable;
    return newVariable;
  }

  Expression cloneContext() {
    InvalidExpression placeHolder = new InvalidExpression();
    contextClonePlaceHolders.add(placeHolder);
    return placeHolder;
  }

  TreeNode visitInvalidExpression(InvalidExpression node) {
    return contextClonePlaceHolders.remove(node) ? context.clone() : node;
  }

  TreeNode visitForStatement(ForStatement node) {
    if (node.variables.any(capturedVariables.contains)) {
      // In Dart, loop variables are new variables on each iteration of the
      // loop. This is only observable when a loop variable is captured by a
      // closure, which is the situation we're in here. So we transform the
      // loop.
      //
      // Consider the following example, where `x` is `node.variables.first`,
      // and `#t1` is a temporary variable:
      //
      //     for (var x = 0; x < 10; x++) body;
      //
      // This is transformed to:
      //
      //     {
      //       var x = 0;
      //       for (; x < 10; clone-context, x++) body;
      //     }
      //
      // `clone-context` is a place-holder that will later be replaced by an
      // expression that clones the current closure context (see
      // [visitInvalidExpression]).
      return saveContext(() {
        context = context.toNestedContext();
        List<Statement> statements = <Statement>[];
        statements.addAll(node.variables);
        statements.add(node);
        node.variables.clear();
        node.updates.insert(0, cloneContext());
        Block block = new Block(statements);
        rewriter = new BlockRewriter(block);
        return block.accept(this);
      });
    }
    return super.visitForStatement(node);
  }

  TreeNode visitForInStatement(ForInStatement node) {
    if (capturedVariables.contains(node.variable)) {
      // In Dart, loop variables are new variables on each iteration of the
      // loop. This is only observable when the loop variable is captured by a
      // closure, so we need to transform the for-in loop when `node.variable`
      // is captured.
      //
      // Consider the following example, where `x` is `node.variable`, and
      // `#t1` is a temporary variable:
      //
      //     for (var x in expr) body;
      //
      // Notice that we can assume that `x` doesn't have an initializer based
      // on invariants in the Kernel AST. This is transformed to:
      //
      //     for (var #t1 in expr) { var x = #t1; body; }
      //
      // After this, we call super to apply the normal closure conversion to
      // the transformed for-in loop.
      VariableDeclaration variable = node.variable;
      VariableDeclaration newVariable = getReplacementLoopVariable(variable);
      node.variable = newVariable;
      newVariable.parent = node;
      node.body = new Block(<Statement>[variable, node.body]);
      node.body.parent = node;
    }
    return super.visitForInStatement(node);
  }

  TreeNode visitThisExpression(ThisExpression node) {
    return isOuterMostContext
        ? node
        : context.lookup(thisAccess[currentMemberFunction]);
  }

  TreeNode visitStaticGet(StaticGet node) {
    Member target = node.target;
    if (target is Procedure && target.kind == ProcedureKind.Method) {
      VariableDeclaration contextVariable = new VariableDeclaration(
          "#contextParameter",
          type: const VectorType());
      Expression expression = getTearOffExpression(
          null, node.target, contextVariable, new NullLiteral());
      expression.transformChildren(this);
      return expression;
    }
    return super.visitStaticGet(node);
  }

  TreeNode visitPropertyGet(PropertyGet node) {
    Name tearOffName = tearOffGetterNames[node.name];
    if (tearOffName != null) {
      MethodInvocation replacement = new MethodInvocation(
          node.receiver, tearOffName, new Arguments(<Expression>[]));
      return super.visitMethodInvocation(replacement);
    }
    return super.visitPropertyGet(node);
  }

  TreeNode visitCatch(Catch node) {
    VariableDeclaration exception = node.exception;
    VariableDeclaration stackTrace = node.stackTrace;
    if (stackTrace != null && capturedVariables.contains(stackTrace)) {
      Block block = node.body = ensureBlock(node.body);
      block.parent = node;
      node.stackTrace = new VariableDeclaration(null);
      node.stackTrace.parent = node;
      stackTrace.initializer = new VariableGet(node.stackTrace);
      block.statements.insert(0, stackTrace);
      stackTrace.parent = block;
    }
    if (exception != null && capturedVariables.contains(exception)) {
      Block block = node.body = ensureBlock(node.body);
      block.parent = node;
      node.exception = new VariableDeclaration(null);
      node.exception.parent = node;
      exception.initializer = new VariableGet(node.exception);
      block.statements.insert(0, exception);
      exception.parent = block;
    }
    return super.visitCatch(node);
  }

  Block ensureBlock(Statement statement) {
    return statement is Block ? statement : new Block(<Statement>[statement]);
  }

  /// Creates a closure that will invoke method [procedure] of [receiver] and
  /// return an expression that instantiates that closure.
  Expression getTearOffExpression(
      VariableDeclaration receiver,
      Procedure procedure,
      VariableDeclaration contextVariable,
      Expression accessContext) {
    Map<TypeParameter, DartType> substitution = procedure.isInstanceMember
        // Note: we do not attempt to avoid copying type variables that aren't
        // used in the signature of [procedure]. It might be more economical to
        // only copy type variables that are used. However, we assume that
        // passing type arguments that match the enclosing class' type
        // variables will be handled most efficiently.
        ? copyTypeVariables(procedure.enclosingClass.typeParameters)
        : const <TypeParameter, DartType>{};

    // TODO(29181): remove variable `dynamicSubstitution` and replace its usages
    // with `substitution`.

    Map<TypeParameter, DartType> dynamicSubstitution =
        <TypeParameter, DartType>{};
    for (TypeParameter parameter in substitution.keys) {
      dynamicSubstitution[parameter] = const DynamicType();
    }
    for (TypeParameter parameter in substitution.keys) {
      if (!isObject(parameter.bound)) {
        dynamicSubstitution[parameter] =
            substitute(parameter.bound, dynamicSubstitution);
      }
    }

    // Find the closure class for the function. If there isn't one, create it.
    String closedTopLevelFunctionName =
        createNameForClosedTopLevelFunction(procedure.function);
    Procedure closedTopLevelFunction = null;
    for (TreeNode node in newLibraryMembers) {
      if (node is Procedure && node.name.name == closedTopLevelFunctionName) {
        closedTopLevelFunction = node;
      }
    }
    if (closedTopLevelFunction == null) {
      closedTopLevelFunction = new Procedure(
          new Name(closedTopLevelFunctionName),
          ProcedureKind.Method,
          forwardFunction(
              procedure, receiver, contextVariable, dynamicSubstitution),
          isStatic: true,
          fileUri: currentFileUri);
      newLibraryMembers.add(closedTopLevelFunction);
    }

    return new ClosureCreation(
        closedTopLevelFunction, accessContext, procedure.function.functionType);
  }

  /// Creates a function that has the same signature as `procedure.function`
  /// and which forwards all arguments to `procedure`.
  FunctionNode forwardFunction(
      Procedure procedure,
      VariableDeclaration receiver,
      VariableDeclaration contextVariable,
      Map<TypeParameter, DartType> substitution) {
    CloneVisitor cloner = substitution.isEmpty
        ? this.cloner
        : new CloneWithoutBody(typeSubstitution: substitution);
    FunctionNode function = procedure.function;
    List<TypeParameter> typeParameters =
        function.typeParameters.map(cloner.clone).toList();
    List<VariableDeclaration> positionalParameters =
        function.positionalParameters.map(cloner.clone).toList();
    if (contextVariable != null) {
      positionalParameters.insert(0, contextVariable);
    }
    List<VariableDeclaration> namedParameters =
        function.namedParameters.map(cloner.clone).toList();

    List<DartType> types = typeParameters
        .map((TypeParameter parameter) => new TypeParameterType(parameter))
        .toList();
    List<Expression> positional = positionalParameters
        .map((VariableDeclaration parameter) => new VariableGet(parameter))
        .toList();
    if (contextVariable != null) {
      positional.removeAt(0);
    }
    List<NamedExpression> named =
        namedParameters.map((VariableDeclaration parameter) {
      return new NamedExpression(parameter.name, new VariableGet(parameter));
    }).toList();

    Arguments arguments = new Arguments(positional, types: types, named: named);
    InvocationExpression invocation = procedure.isInstanceMember
        ? new MethodInvocation(
            context.lookup(receiver), procedure.name, arguments, procedure)
        : new StaticInvocation(procedure, arguments);
    int requiredParameterCount = function.requiredParameterCount;
    if (contextVariable != null) {
      ++requiredParameterCount;
    }
    return new FunctionNode(new ReturnStatement(invocation),
        typeParameters: typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        returnType: substitute(function.returnType, cloner.typeSubstitution));
  }

  /// Creates copies of the type variables in [original] and returns a
  /// substitution that can be passed to [substitute] to substitute all uses of
  /// [original] with their copies.
  Map<TypeParameter, DartType> copyTypeVariables(
      Iterable<TypeParameter> original) {
    if (original.isEmpty) return const <TypeParameter, DartType>{};
    Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
    for (TypeParameter t in original) {
      substitution[t] = new TypeParameterType(new TypeParameter(t.name));
    }
    substitution.forEach((TypeParameter t, DartType copy) {
      if (copy is TypeParameterType) {
        copy.parameter.bound = substitute(t.bound, substitution);
      }
    });
    return substitution;
  }

  String createNameForClosedTopLevelFunction(FunctionNode function) {
    return 'closure#${localNames[function]}';
  }

  Statement forwardToThisProperty(Member node) {
    assert(node is Field || (node is Procedure && node.isGetter));
    return new ReturnStatement(
        new PropertyGet(new ThisExpression(), node.name, node));
  }

  void addFieldForwarder(Name name, Field field) {
    newClassMembers.add(new Procedure(name, ProcedureKind.Getter,
        new FunctionNode(forwardToThisProperty(field)),
        fileUri: currentFileUri));
  }

  Procedure copyWithBody(Procedure procedure, Statement body) {
    Procedure copy = cloner.clone(procedure);
    copy.function.body = body;
    copy.function.body.parent = copy.function;
    return copy;
  }

  void addGetterForwarder(Name name, Procedure getter) {
    assert(getter.isGetter);
    newClassMembers
        .add(copyWithBody(getter, forwardToThisProperty(getter))..name = name);
  }

  void addTearOffMethod(Name name, Procedure procedure) {
    // [addTearOffMethod] generates a method along with a context that captures
    // `this`. The work with contexts is typically done using the data gathered
    // by a [ClosureInfo] instance. In absence of this information, we need to
    // create some variables, like `#self` and `#context`, and manipulate
    // contexts directly in some cases.
    //
    // Also, the tear-off method is generated during a visit to the AST node
    // of the procedure being torn off, so we need to save and restore some
    // auxiliary variables like `currentMember` and `currentMemberFunction`
    // and use [saveContext], so that those variables have proper values when
    // the procedure itself is being transformed.
    Member oldCurrentMember = currentMember;
    FunctionNode oldCurrentMemberFunction = currentMemberFunction;
    try {
      saveContext(() {
        Block body = new Block(<Statement>[]);
        FunctionNode tearOffMethodFunction = new FunctionNode(body);
        setupContextForFunctionBody(tearOffMethodFunction);

        // We need a variable that refers to `this` to put it into the context.
        VariableDeclaration self = new VariableDeclaration("#self",
            type: procedure.enclosingClass.rawType);
        context.extend(self, new ThisExpression());

        // The `#context` variable is used to access the context in the closed
        // top-level function that represents the closure and is generated in
        // [getTearOffExpression].
        VariableDeclaration contextVariable = new VariableDeclaration(
            "#contextParameter",
            type: const VectorType());
        Context parent = context;
        context = context.toNestedContext(
            new VariableAccessor(contextVariable, null, TreeNode.noOffset));

        body.addStatement(new ReturnStatement(getTearOffExpression(
            self, procedure, contextVariable, parent.expression)));

        Procedure tearOffMethod = new Procedure(
            name, ProcedureKind.Method, tearOffMethodFunction,
            fileUri: currentFileUri);
        newClassMembers.add(tearOffMethod);

        resetContext();
      });
    } finally {
      currentMember = oldCurrentMember;
      currentMemberFunction = oldCurrentMemberFunction;
    }
  }
}
