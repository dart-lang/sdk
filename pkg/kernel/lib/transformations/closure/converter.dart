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
        EmptyStatement,
        Expression,
        ExpressionStatement,
        Field,
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
        Library,
        LocalInitializer,
        RedirectingInitializer,
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

import 'context.dart' show Context, NoContext, LocalContext;

import 'info.dart' show ClosureInfo;

import 'rewriter.dart' show AstRewriter, BlockRewriter, InitializerListRewriter;

class ClosureConverter extends Transformer {
  final CoreTypes coreTypes;

  // This map pairs variables that are captured with flags indicating whether
  // they are captured inside or outside an initializer. See
  // [ClosureInfo.variables].
  final Map<VariableDeclaration, int> capturedVariables;

  final Map<FunctionNode, Set<TypeParameter>> capturedTypeVariables;
  final Map<FunctionNode, VariableDeclaration> thisAccess;
  final Map<FunctionNode, String> localNames;

  /// Records place-holders for cloning contexts. See [visitForStatement].
  final Set<InvalidExpression> contextClonePlaceHolders =
      new Set<InvalidExpression>();

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
        this.localNames = info.localNames;

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

  extendContextConditionally({bool inInitializer}) {
    return (VariableDeclaration parameter) {
      int flags = capturedVariables[parameter];

      // When moving variables into the context while scanning initializers,
      // we need to add the variable if it's captured in an initializer,
      // whether or not it's used/captured in the body. However, in the body,
      // we only need to add the variable into the context if it's *not*
      // captured in an initializer.
      if (flags != null && inInitializer
          ? (flags & ClosureInfo.INSIDE_INITIALIZER) > 0
          : flags == ClosureInfo.OUTSIDE_INITIALIZER) {
        context.extend(parameter, new VariableGet(parameter));
      }
      return flags ?? 0;
    };
  }

  TreeNode visitConstructor(Constructor node) {
    assert(isEmptyContext);
    currentMember = node;

    // If we created a context for the initializers, we need to re-use that
    // context in the body of the function. Unfortunately, the context is
    // declared in a local initializer and local initializers aren't visible
    // in the body of the constructor. To work around this issue, we move the
    // body into a new constructor and make this constructor redirect to that
    // one, passing the context as an argument to the new constructor.
    var movingCtor = false;

    // Transform initializers.
    if (node.initializers.length > 0) {
      var initRewriter = new InitializerListRewriter(node);
      rewriter = initRewriter;
      context = new NoContext(this);

      final int capturedBoth =
          ClosureInfo.OUTSIDE_INITIALIZER | ClosureInfo.INSIDE_INITIALIZER;

      // TODO(karlklose): add a fine-grained analysis of captured parameters.
      movingCtor = node.function.positionalParameters
              .map(extendContextConditionally(inInitializer: true))
              .any((flags) => flags == capturedBoth) ||
          node.function.namedParameters
              .map(extendContextConditionally(inInitializer: true))
              .any((flags) => flags == capturedBoth);

      transformList(node.initializers, this, node);
      node.initializers.insertAll(0, initRewriter.prefix);
      rewriter = null;
    }

    // Transform constructor body.
    FunctionNode function = node.function;
    if (function.body != null && function.body is! EmptyStatement) {
      setupRewriterForFunctionBody(function);
      if (!movingCtor) context = new NoContext(this);
      VariableDeclaration self = thisAccess[currentMemberFunction];
      if (self != null) {
        context.extend(self, new ThisExpression());
      }
      node.function.accept(this);

      if (movingCtor) {
        var contextDecl = (context as LocalContext).self;
        var newCtorName = new Name("${node.name.name}#redir");
        var newCtor = new Constructor(node.function, name: newCtorName);
        newClassMembers.add(newCtor);

        LocalInitializer contextDeclInit = null;
        for (var init in node.initializers) {
          if (init is LocalInitializer && init.variable == contextDecl) {
            contextDeclInit = init;
          } else {
            newCtor.initializers.add(init);
          }
        }

        node.initializers = <Initializer>[contextDeclInit];

        var cv = new CloneVisitor();
        var oldCtorParams = function.positionalParameters
            .map(cv.visitVariableDeclaration)
            .toList();
        var oldCtorNamedParams =
            function.namedParameters.map(cv.visitVariableDeclaration).toList();

        function.positionalParameters.addAll(function.namedParameters);
        function.namedParameters = [];

        var args = <Expression>[];
        args.addAll(oldCtorParams.map((decl) => new VariableGet(decl)));
        args.addAll(oldCtorNamedParams.map((decl) => new VariableGet(decl)));

        node.function = new FunctionNode(new EmptyStatement(),
            typeParameters: [],
            positionalParameters: oldCtorParams,
            namedParameters: oldCtorNamedParams,
            requiredParameterCount: function.requiredParameterCount,
            returnType: function.returnType,
            asyncMarker: function.asyncMarker,
            dartAsyncMarker: function.dartAsyncMarker);
        node.function.parent = node;

        var oldCtorDecl = cv.visitVariableDeclaration(contextDecl);
        contextDecl.initializer = null;
        function.positionalParameters.add(contextDecl);
        function.requiredParameterCount++;

        contextDeclInit.variable = oldCtorDecl;
        oldCtorDecl.parent = contextDeclInit;

        args.add(new VariableGet(oldCtorDecl));
        var redirInit =
            new RedirectingInitializer(newCtor, new Arguments(args));
        node.initializers.add(redirInit);
      }
    }
    resetContext();
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

  TreeNode visitField(Field node) {
    currentMember = node;
    context = new NoContext(this);
    node = super.visitField(node);
    context = null;
    currentMember = null;
    return node;
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

    Set<TypeParameter> captured =
        capturedTypeVariables[currentFunction] ?? new Set<TypeParameter>();
    typeSubstitution = copyTypeVariables(captured);

    function.transformChildren(this);

    Expression result = addClosure(function, contextVariable, parent.expression,
        typeSubstitution, enclosingTypeSubstitution);
    currentFunction = enclosingFunction;
    typeSubstitution = enclosingTypeSubstitution;
    return result;
  }

  TreeNode visitFunctionDeclaration(FunctionDeclaration node) {
    /// Is this closure itself captured by a closure?
    bool isCaptured = capturedVariables.containsKey(node.variable);
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
    return saveContext(() => handleLocalFunction(node.function));
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
    var fnTypeParams = <TypeParameter>[];
    var fnTypeArgs = <TypeParameterType>[];
    for (TypeParameter t in substitution.keys) {
      var fnTypeParam = (substitution[t] as TypeParameterType).parameter;
      fnTypeParams.add(fnTypeParam);
      fnTypeArgs
          .add(substitute(new TypeParameterType(t), enclosingTypeSubstitution));
    }

    function.typeParameters.insertAll(0, fnTypeParams);
    function.positionalParameters.insert(0, contextVariable);
    ++function.requiredParameterCount;
    Procedure closedTopLevelFunction = new Procedure(
        new Name(createNameForClosedTopLevelFunction(function)),
        ProcedureKind.Method,
        function,
        isStatic: true,
        fileUri: currentFileUri);
    newLibraryMembers.add(closedTopLevelFunction);

    // We need to again make new type parameters for the function's function
    // type, and substitute them into the function type's arguments' types.
    var closureTypeParams = <TypeParameter>[];
    var closureTypeSubstitutionMap = copyTypeVariables(function.typeParameters);
    for (DartType d in closureTypeSubstitutionMap.values)
      closureTypeParams.add((d as TypeParameterType).parameter);

    FunctionType closureType = new FunctionType(
        function.positionalParameters
            .skip(1)
            .map((VariableDeclaration decl) =>
                substitute(decl.type, closureTypeSubstitutionMap))
            .toList(),
        substitute(function.returnType, closureTypeSubstitutionMap),
        namedParameters: function.namedParameters
            .map((VariableDeclaration decl) => new NamedType(
                decl.name, substitute(decl.type, closureTypeSubstitutionMap)))
            .toList(),
        typeParameters: closureTypeParams,
        requiredParameterCount: function.requiredParameterCount - 1);

    return new ClosureCreation(
        closedTopLevelFunction, accessContext, closureType, fnTypeArgs);
  }

  TreeNode visitProcedure(Procedure node) {
    assert(isEmptyContext);

    currentMember = node;

    FunctionNode function = node.function;
    if (function.body != null) {
      setupRewriterForFunctionBody(function);
      // Start with no context.  This happens after setting up _currentBlock
      // so statements can be emitted into _currentBlock if necessary.
      context = new NoContext(this);

      VariableDeclaration self = thisAccess[currentMemberFunction];
      if (self != null) {
        context.extend(self, new ThisExpression());
      }
      node.transformChildren(this);
      resetContext();
    }

    return node;
  }

  void setupRewriterForFunctionBody(FunctionNode function) {
    Statement body = function.body;
    assert(body != null);
    currentMemberFunction = function;
    // Ensure that the body is a block which becomes the current block.
    rewriter = makeRewriterForBody(function);
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
    assert(!capturedVariables.containsKey(node.variable));
    node.transformChildren(this);
    return node;
  }

  TreeNode visitFunctionNode(FunctionNode node) {
    transformList(node.typeParameters, this, node);
    // Initializers for optional parameters must be compile-time constants,
    // which excludes closures. Therefore, we can avoid looking for closures in
    // initializers of the parameters.
    node.positionalParameters
        .forEach(extendContextConditionally(inInitializer: false));
    node.namedParameters
        .forEach(extendContextConditionally(inInitializer: false));
    assert(node.body != null);
    node.body = node.body.accept(this);
    node.body.parent = node;
    return node;
  }

  TreeNode visitBlock(Block node) {
    return saveContext(() {
      BlockRewriter blockRewriter = rewriter = rewriter.forNestedBlock(node);
      blockRewriter.transformStatements(this);
      return node;
    });
  }

  TreeNode visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);

    if (!capturedVariables.containsKey(node)) return node;
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
      // When returning null, the parent block will remove
      // this node from its list of statements.
      return null;
    }
  }

  TreeNode visitVariableGet(VariableGet node) {
    return capturedVariables.containsKey(node.variable)
        ? context.lookup(node.variable)
        : node;
  }

  TreeNode visitVariableSet(VariableSet node) {
    node.transformChildren(this);

    return capturedVariables.containsKey(node.variable)
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
    if (node.variables.any(capturedVariables.containsKey)) {
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
    if (capturedVariables.containsKey(node.variable)) {
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

  TreeNode visitCatch(Catch node) {
    VariableDeclaration exception = node.exception;
    VariableDeclaration stackTrace = node.stackTrace;
    if (stackTrace != null && capturedVariables.containsKey(stackTrace)) {
      Block block = node.body = ensureBlock(node.body);
      block.parent = node;
      node.stackTrace = new VariableDeclaration(null);
      node.stackTrace.parent = node;
      stackTrace.initializer = new VariableGet(node.stackTrace);
      block.statements.insert(0, stackTrace);
      stackTrace.parent = block;
    }
    if (exception != null && capturedVariables.containsKey(exception)) {
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
  /// [original] with their copies. Additionally returns a list of new type
  /// parameters to prefix to the enclosing function's type parameters and the
  /// arguments to be passed for those parameters.
  ///
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
}
