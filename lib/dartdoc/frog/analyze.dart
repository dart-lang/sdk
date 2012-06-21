// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple code analyzer for Dart.
 *
 * Currently used to ensure all concrete generic types are visited.
 * Also performs all static type checks - so these don't need to be
 * done in later phases.
 *
 * Ultimately, this should include abstract interpreter work.  This will
 * result in an interesting split beteen this class and MethodGenerator
 * which should be turned into nothing more than a code generator.
 */
// TODO(jimhug): This class shares too much code with MethodGenerator.
class MethodAnalyzer implements TreeVisitor {
  MethodMember method;
  Statement body;

  CallFrame _frame;

  /**
   * Track whether or not [body] refers to any type parameters from the
   * enclosing type to advise future code generation and analysis.
   */
  bool hasTypeParams = false;

  MethodAnalyzer(this.method, this.body);

  // TODO(jimhug): Type issue with requiring CallFrame here...
  void analyze(CallFrame context) {
    var thisValue;
    // TODO(jimhug): Move Constructor analysis to here and below.

    if (context != null) {
      thisValue = context.thisValue;
    } else {
      thisValue = new PureStaticValue(method.declaringType, null);
    }
    var values = [];
    for (var p in method.parameters) {
      values.add(new PureStaticValue(p.type, null));
    }
    var args = new Arguments(null, values);

    _frame = new CallFrame(this, method, thisValue, args, context);
    _bindArguments(_frame.args);

    // Visit the super or this call in a constructor, if any.
    final declaredInitializers = method.definition.dynamic.initializers;
    if (declaredInitializers != null) {
      for (var init in declaredInitializers) {
        if (init is CallExpression) {
          visitCallExpression(init, true);
        }
      }
    }

    if (body != null) body.visit(this);
  }

  /* Checks whether or not a particular TypeReference Node includes references
   * to type parameters. */
  bool _hasTypeParams(node) {
    if (node is NameTypeReference) {
      var name = node.name.name;
      return (method.declaringType.lookupTypeParam(name) != null);
    } else if (node is GenericTypeReference) {
      for (var typeArg in node.typeArguments) {
        if (_hasTypeParams(typeArg)) return true;
      }
      return false;
    } else {
      // TODO(jimhug): Do we need to include FunctionTypeReference here?
      return false;
    }
  }

  Type resolveType(TypeReference node, bool typeErrors,
      bool allowTypeParams) {
    if (!hasTypeParams && _hasTypeParams(node)) {
      hasTypeParams = true;
    }
    return method.resolveType(node, typeErrors, allowTypeParams);
  }


  Value makeNeutral(Value inValue, SourceSpan span) {
    return new PureStaticValue(inValue.type, span);
  }

  void _bindArguments(Arguments args) {
    for (int i = 0; i < method.parameters.length; i++) {
      var p = method.parameters[i];
      Value currentArg = null;
      if (i < args.bareCount) {
        currentArg = args.values[i];
      } else {
        // Handle named or missing arguments
        currentArg = args.getValue(p.name);
        if (currentArg === null) {
          // TODO(jmesserly): this path won't work if we ever get here, because
          // Paramter.genValue assumes it has a MethodGenerator.

          // Ensure default value for param has been generated
          p.genValue(method, _frame); // TODO(jimhug): Needed here?
          if (p.value === null) {
            world.warning('missing argument at call - does not match');
          }
          currentArg = p.value;
        }
      }

      currentArg = makeNeutral(currentArg, p.definition.span);

      // TODO(jimhug): Add checks for constructor initializers.
      _frame.declareParameter(p, currentArg);
      // TODO(jimhug): Add type check?
    }
  }

  visitBool(Expression node) {
    return visitTypedValue(node, world.boolType);
  }

  visitValue(Expression node) {
    if (node == null) return null;

    var value = node.visit(this);
    value.checkFirstClass(node.span);
    return value;
  }

  /**
   * Visit [node] and ensure statically or with an runtime check that it has
   * the expected type (if specified).
   */
  visitTypedValue(Expression node, Type expectedType) {
    final val = visitValue(node);
    return val === null ? null : val.convertTo(_frame, expectedType);
  }

  visitVoid(Expression node) {
    // TODO(jimhug): Add some helpful diagnostics for silly void uses.
    return visitValue(node);
  }


  Arguments _visitArgs(List<ArgumentNode> arguments) {
    var args = [];
    bool seenLabel = false;
    for (var arg in arguments) {
      if (arg.label != null) {
        seenLabel = true;
      } else if (seenLabel) {
        // TODO(jimhug): Move this into parser?
        world.error('bare argument cannot follow named arguments', arg.span);
      }
      args.add(visitValue(arg.value));
    }

    return new Arguments(arguments, args);
  }

  MethodMember _makeLambdaMethod(String name, FunctionDefinition func) {
    var meth = new MethodMember.lambda(name, method.declaringType, func);
    meth.enclosingElement = method;
    meth._methodData = new MethodData(meth, _frame);
    meth.resolve();
    return meth;
  }

  void _pushBlock(Node node) {
    _frame.pushBlock(node);
  }
  void _popBlock(Node node) {
    _frame.popBlock(node);
  }

  Member _resolveBare(String name, Node node) {
    var type = _frame.method.declaringType;
    var member = type.getMember(name);
    if (member == null || member.declaringType != type) {
      var libMember = _frame.library.lookup(name, node.span);
      if (libMember !== null) return libMember;
    }

    if (member !== null && !member.isStatic && _frame.isStatic) {
      world.error('cannot refer to instance member from static method',
        node.span);
    }
    return member;
  }

  // ******************* Statements *******************

  void visitDietStatement(DietStatement node) {
    var parser = new Parser(node.span.file, startOffset: node.span.start);
    parser.block().visit(this);
  }

  void visitVariableDefinition(VariableDefinition node) {
    var isFinal = false;
    // TODO(jimhug): Clean this up and share modifier parsing somewhere.
    if (node.modifiers != null && node.modifiers[0].kind == TokenKind.FINAL) {
      isFinal = true;
    }
    var type = resolveType(node.type, false, true);
    for (int i=0; i < node.names.length; i++) {
      final name = node.names[i].name;
      var value = visitValue(node.values[i]);
      _frame.create(name, type, node.names[i], isFinal, value);
    }
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    var meth = _makeLambdaMethod(node.name.name, node);
    // TODO(jimhug): Better FunctionValue that tracks actual function
    var funcValue = _frame.create(meth.name, meth.functionType,
        method.definition, true, null);

    meth.methodData.analyze();
  }


  void visitReturnStatement(ReturnStatement node) {
    if (node.value == null) {
      _frame.returns(Value.fromNull(node.span));
    } else {
      _frame.returns(visitValue(node.value));
    }
  }

  void visitThrowStatement(ThrowStatement node) {
    // Dart allows throwing anything, just like JS
    if (node.value != null) {
      var value = visitValue(node.value);
    } else {
      // skip
    }
  }

  void visitAssertStatement(AssertStatement node) {
    // be sure to walk test for static checking even is asserts disabled
    var test = visitValue(node.test); // TODO(jimhug): check bool or callable.
  }

  void visitBreakStatement(BreakStatement node) {
  }

  void visitContinueStatement(ContinueStatement node) {
  }

  void visitIfStatement(IfStatement node) {
    var test = visitBool(node.test);
    node.trueBranch.visit(this);
    if (node.falseBranch != null) {
      node.falseBranch.visit(this);
    }
  }

  void visitWhileStatement(WhileStatement node) {
    var test = visitBool(node.test);
    node.body.visit(this);
  }

  void visitDoStatement(DoStatement node) {
    node.body.visit(this);
    var test = visitBool(node.test);
  }

  void visitForStatement(ForStatement node) {
    _pushBlock(node);
    if (node.init != null) node.init.visit(this);

    if (node.test != null) {
      var test = visitBool(node.test);
    }
    for (var s in node.step) {
      var sv = visitVoid(s);
    }

    _pushBlock(node.body);
    node.body.visit(this);
    _popBlock(node.body);


    _popBlock(node);
  }

  void visitForInStatement(ForInStatement node) {
    // TODO(jimhug): visitValue and other cleanups here.
    var itemType = resolveType(node.item.type, false, true);
    var list = node.list.visit(this);
    _visitForInBody(node, itemType, list);
  }


  bool _isFinal(typeRef) {
    if (typeRef is GenericTypeReference) {
      typeRef = typeRef.baseType;
    } else if (typeRef is SimpleTypeReference) {
      return false;
    }
    return typeRef != null && typeRef.isFinal;
  }

  void _visitForInBody(ForInStatement node, Type itemType, Value list) {
    // TODO(jimhug): Check that itemType matches list members...
    _pushBlock(node);

    bool isFinal = _isFinal(node.item.type);
    var itemName = node.item.name.name;
    var item =
      _frame.create(itemName, itemType, node.item.name, isFinal, null);

    var iterator =
      list.invoke(_frame, 'iterator', node.list, Arguments.EMPTY);

    node.body.visit(this);
    _popBlock(node);
  }

  _createDI(DeclaredIdentifier di) {
    _frame.create(di.name.name, resolveType(di.type, false, true), di.name,
      true, null);
  }

  void visitTryStatement(TryStatement node) {
    _pushBlock(node.body);
    node.body.visit(this);
    _popBlock(node.body);
    if (node.catches.length > 0) {
      for (int i = 0; i < node.catches.length; i++) {
        var catch_ = node.catches[i];
        _pushBlock(catch_);
        _createDI(catch_.exception);
        if (catch_.trace !== null) {
          _createDI(catch_.trace);
        }
        catch_.body.visit(this);
        _popBlock(catch_);
      }
    }

    if (node.finallyBlock != null) {
      node.finallyBlock.visit(this);
    }
  }

  void visitSwitchStatement(SwitchStatement node) {
    var test = visitValue(node.test);
    for (var case_ in node.cases) {
      _pushBlock(case_);

      for (int i=0; i < case_.cases.length; i++) {
        var expr = case_.cases[i];
        if (expr == null) {
          //skip
        } else {
          var value = visitValue(expr);
        }
      }
      _visitAllStatements(case_.statements);
      _popBlock(case_);
    }
  }

  _visitAllStatements(statementList) {
    for (int i = 0; i < statementList.length; i++) {
      var stmt = statementList[i];
      stmt.visit(this);
    }
  }

  void visitBlockStatement(BlockStatement node) {
    _pushBlock(node);
    _visitAllStatements(node.body);
    _popBlock(node);
  }

  void visitLabeledStatement(LabeledStatement node) {
    node.body.visit(this);
  }

  void visitExpressionStatement(ExpressionStatement node) {
    var value = visitVoid(node.body);
  }

  void visitEmptyStatement(EmptyStatement node) {
  }



  // ******************* Expressions *******************
  visitLambdaExpression(LambdaExpression node) {
    var name = (node.func.name != null) ? node.func.name.name : '';

    MethodMember meth = _makeLambdaMethod(name, node.func);
    // TODO(jimhug): Worry about proper scope for recursive lambda.
    meth.methodData.analyze();

    return _frame._makeValue(world.functionType, node);
  }

  analyzeInitializerConstructorCall(CallExpression node,
                                    Expression receiver,
                                    String name) {
    var type = _frame.method.declaringType;
    if (receiver is SuperExpression) {
      type = type.parent;
    }
    var member = type.getConstructor(name == null ? '' : name);
    if (member !== null) {
      return member.invoke(_frame, node, _frame.makeThisValue(node),
                           _visitArgs(node.arguments));
    } else {
      String constructorName = name == null ? '' : '.$name';
      world.warning('cannot find constructor "${type.name}$constructorName"',
                    node.span);
      return _frame._makeValue(world.varType, node);
    }
  }

  bool isThisOrSuper(Expression node) {
    return node is ThisExpression || node is SuperExpression;
  }

  Value visitCallExpression(CallExpression node,
                            [bool visitingInitializers = false]) {
    var target;
    var position = node.target;
    var name = ':call';
    if (node.target is DotExpression) {
      DotExpression dot = node.target;
      target = dot.self.visit(this);
      name = dot.name.name;
      if (isThisOrSuper(dot.self) && visitingInitializers) {
        return analyzeInitializerConstructorCall(node, dot.self, name);
      } else {
        position = dot.name;
      }
    } else if (isThisOrSuper(node.target) && visitingInitializers) {
      return analyzeInitializerConstructorCall(node, node.target, null);
    } else if (node.target is VarExpression) {
      VarExpression varExpr = node.target;
      name = varExpr.name.name;
      // First check in block scopes.
      target = _frame.lookup(name);
      if (target != null) {
        return target.get(position).invoke(_frame, ':call', node,
          _visitArgs(node.arguments));
      }

      var member = _resolveBare(name, varExpr.name);
      if (member !== null) {
        return member.invoke(_frame, node, _frame.makeThisValue(node),
                             _visitArgs(node.arguments));
      } else {
        world.warning('cannot find "$name"', node.span);
        return _frame._makeValue(world.varType, node);
      }
    } else {
      target = node.target.visit(this);
    }

    return target.invoke(_frame, name, position, _visitArgs(node.arguments));
  }

  Value visitIndexExpression(IndexExpression node) {
    var target = visitValue(node.target);
    var index = visitValue(node.index);

    return target.invoke(_frame, ':index', node,
      new Arguments(null, [index]));
  }


  Value visitBinaryExpression(BinaryExpression node, [bool isVoid = false]) {
    final kind = node.op.kind;

    if (kind == TokenKind.AND || kind == TokenKind.OR) {
      var xb = visitBool(node.x);
      var yb = visitBool(node.y);
      return xb.binop(kind, yb, _frame, node);
    }

    final assignKind = TokenKind.kindFromAssign(node.op.kind);
    if (assignKind == -1) {
      final x = visitValue(node.x);
      final y = visitValue(node.y);
      return x.binop(kind, y, _frame, node);
    } else {
      return _visitAssign(assignKind, node.x, node.y, node);
    }
  }

  /**
   * Visits an assignment expression.
   */
  Value _visitAssign(int kind, Expression xn, Expression yn, Node position) {
    if (xn is VarExpression) {
      return _visitVarAssign(kind, xn, yn, position);
    } else if (xn is IndexExpression) {
      return _visitIndexAssign(kind, xn, yn, position);
    } else if (xn is DotExpression) {
      return _visitDotAssign(kind, xn, yn, position);
    } else {
      world.error('illegal lhs', xn.span);
    }
  }

  _visitVarAssign(int kind, VarExpression xn, Expression yn, Node node) {
    final value = visitValue(yn);
    final name = xn.name.name;

    // First check in block scopes.
    var slot = _frame.lookup(name);
    if (slot != null) {
      slot.set(value);
    } else {
      var member = _resolveBare(name, xn.name);
      if (member !== null) {
        member._set(_frame, node, _frame.makeThisValue(node), value);
      } else {
        world.warning('cannot find "$name"', node.span);
      }
    }
    return _frame._makeValue(value.type, node);
  }

  _visitIndexAssign(int kind, IndexExpression xn, Expression yn,
      Node position) {
    var target = visitValue(xn.target);
    var index = visitValue(xn.index);
    var y = visitValue(yn);

    return target.setIndex(_frame, index, position, y, kind: kind);
  }

  _visitDotAssign(int kind, DotExpression xn, Expression yn, Node position) {
    // This is not visitValue because types members are assignable.
    var target = xn.self.visit(this);
    var y = visitValue(yn);

    return target.set_(_frame, xn.name.name, xn.name, y, kind: kind);
  }

  visitUnaryExpression(UnaryExpression node) {
    var value = visitValue(node.self);
    switch (node.op.kind) {
      case TokenKind.INCR:
      case TokenKind.DECR:
        return value.binop(TokenKind.ADD,
          _frame._makeValue(world.intType, node), _frame, node);
    }
    return value.unop(node.op.kind, _frame, node);
  }

  visitDeclaredIdentifier(DeclaredIdentifier node) {
    world.error('Expected expression', node.span);
  }

  visitAwaitExpression(AwaitExpression node) {
    world.internalError(
        'Await expressions should have been eliminated before code generation',
        node.span);
  }

  Value visitPostfixExpression(PostfixExpression node,
      [bool isVoid = false]) {
    var value = visitValue(node.body);

    return _frame._makeValue(value.type, node);
  }

  Value visitNewExpression(NewExpression node) {
    var typeRef = node.type;

    var constructorName = '';
    if (node.name != null) {
      constructorName = node.name.name;
    }

    // Named constructors and library prefixes, oh my!
    // At last, we can collapse the ambiguous wave function...
    if (constructorName == '' && typeRef is NameTypeReference &&
        typeRef.names != null) {

      // Pull off the last name from the type, guess it's the constructor name.
      var names = new List.from(typeRef.names);
      constructorName = names.removeLast().name;
      if (names.length == 0) names = null;

      typeRef = new NameTypeReference(
          typeRef.isFinal, typeRef.name, names, typeRef.span);
    }

    var type = resolveType(typeRef, true, true);
    if (type.isTop) {
      type = type.library.findTypeByName(constructorName);
      if (type == null) {
        world.error('cannot resolve type $constructorName', node.span);
      }
      constructorName = '';
    }

    if (type is ParameterType) {
      world.error('cannot instantiate a type parameter', node.span);
      return _frame._makeValue(world.varType, node);
    }

    var m = type.getConstructor(constructorName);
    if (m == null) {
      var name = type.jsname;
      if (type.isVar) {
        name = typeRef.name.name;
      }
      world.warning('no matching constructor for $name', node.span);
      return _frame._makeValue(type, node);
    }

    if (node.isConst) {
      if (!m.isConst) {
        world.error('can\'t use const on a non-const constructor', node.span);
      }
      for (var arg in node.arguments) {
        // TODO(jimhug): Remove this double walk of arguments.
        if (!visitValue(arg.value).isConst) {
          world.error('const constructor expects const arguments', arg.span);
        }
      }
    }


    var args = _visitArgs(node.arguments);
    var target = new TypeValue(type, typeRef.span);
    return new PureStaticValue(type, node.span, node.isConst);
  }

  Value visitListExpression(ListExpression node) {
    var argValues = [];
    var listType = world.listType;
    var type = world.varType;
    if (node.itemType != null) {
      type = resolveType(node.itemType, true, !node.isConst);
      if (node.isConst && (type is ParameterType || type.hasTypeParams)) {
        world.error('type parameter cannot be used in const list literals');
      }
      listType = listType.getOrMakeConcreteType([type]);
    }
    for (var item in node.values) {
      var arg = visitTypedValue(item, type);
      argValues.add(arg);
      // TODO(jimhug): Reenable these checks here - and remove from MethodGen
      //if (node.isConst && !arg.isConst) {
      //  world.error('const list can only contain const values', arg.span);
      //}
    }

    world.listFactoryType.markUsed();

    return new PureStaticValue(listType, node.span, node.isConst);
  }


  Value visitMapExpression(MapExpression node) {
    var values = <Value>[];
    var valueType = world.varType, keyType = world.stringType;
    var mapType = world.mapType; // TODO(jimhug): immutable type?
    if (node.valueType !== null) {
      if (node.keyType !== null) {
        keyType = method.resolveType(node.keyType, true, !node.isConst);
        // TODO(jimhug): Would be nice to allow arbitrary keys here (this is
        // currently not allowed by the spec).
        if (!keyType.isString) {
          world.error('the key type of a map literal must be "String"',
              keyType.span);
        }
        if (node.isConst &&
            (keyType is ParameterType || keyType.hasTypeParams)) {
          world.error('type parameter cannot be used in const map literals');
        }
      }

      valueType = resolveType(node.valueType, true, !node.isConst);
      if (node.isConst &&
          (valueType is ParameterType || valueType.hasTypeParams)) {
        world.error('type parameter cannot be used in const map literals');
      }

      mapType = mapType.getOrMakeConcreteType([keyType, valueType]);
    }

    for (int i = 0; i < node.items.length; i += 2) {
      var key = visitTypedValue(node.items[i], keyType);
      // TODO(jimhug): Reenable these checks here - and remove from MethodGen
      //if (node.isConst && !key.isConst) {
      //  world.error('const map can only contain const keys', key.span);
      //}
      values.add(key);

      var value = visitTypedValue(node.items[i + 1], valueType);
      if (node.isConst && !value.isConst) {
        world.error('const map can only contain const values', value.span);
      }
      values.add(value);
    }

    return new PureStaticValue(mapType, node.span, node.isConst);
  }


  Value visitConditionalExpression(ConditionalExpression node) {
    var test = visitBool(node.test);
    var trueBranch = visitValue(node.trueBranch);
    var falseBranch = visitValue(node.falseBranch);

    // TODO(jimhug): Should be unioning values, not just types.
    return _frame._makeValue(Type.union(trueBranch.type, falseBranch.type),
      node);
  }

  Value visitIsExpression(IsExpression node) {
    var value = visitValue(node.x);
    var type = resolveType(node.type, false, true);
    return _frame._makeValue(world.boolType, node);
  }

  Value visitParenExpression(ParenExpression node) {
    return visitValue(node.body);
  }

  Value visitDotExpression(DotExpression node) {
    // Types are legal targets of .
    var target = node.self.visit(this);
    return target.get_(_frame, node.name.name, node);
  }


  Value visitVarExpression(VarExpression node) {
    final name = node.name.name;

    // First check in block scopes.
    var slot = _frame.lookup(name);
    if (slot != null) {
      return slot.get(node);
    }

    var member = _resolveBare(name, node.name);
    if (member !== null) {
      if (member is TypeMember) {
        return new PureStaticValue(member.dynamic.type, node.span, true,
          true);
      } else {
        return member._get(_frame, node, _frame.makeThisValue(node));
      }
    } else {
      world.warning('cannot find "$name"', node.span);
      return _frame._makeValue(world.varType, node);
    }
  }

  Value visitThisExpression(ThisExpression node) {
    return _frame.makeThisValue(node);
  }

  Value visitSuperExpression(SuperExpression node) {
    return _frame.makeSuperValue(node);
  }

  Value visitLiteralExpression(LiteralExpression node) {
    return new PureStaticValue(node.value.type, node.span, true);
  }

  Value visitStringConcatExpression(StringConcatExpression node) {
    bool isConst = true;
    node.strings.forEach((each) {
      if (!visitValue(each).isConst) isConst = false;
    });
    return new PureStaticValue(world.stringType, node.span, isConst);
  }

  Value visitStringInterpExpression(StringInterpExpression node) {
    bool isConst = true;
    node.pieces.forEach((each) {
      if (!visitValue(each).isConst) isConst = false;
    });
    return new PureStaticValue(world.stringType, node.span, isConst);
  }
}

