// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure_conversion;

import '../ast.dart';
import '../core_types.dart';
import '../visitor.dart';

Program transformProgram(Program program) {
  var captured = new CapturedVariables();
  captured.visitProgram(program);

  var convert =
      new ClosureConverter(new CoreTypes(program), captured.variables);
  return convert.visitProgram(program);
}

class CapturedVariables extends RecursiveVisitor {
  FunctionNode _currentFunction;
  final Map<VariableDeclaration, FunctionNode> _function =
      <VariableDeclaration, FunctionNode>{};

  final Set<VariableDeclaration> variables = new Set<VariableDeclaration>();

  visitFunctionNode(FunctionNode node) {
    var saved = _currentFunction;
    _currentFunction = node;
    node.visitChildren(this);
    _currentFunction = saved;
  }

  visitVariableDeclaration(VariableDeclaration node) {
    _function[node] = _currentFunction;
    node.visitChildren(this);
  }

  visitVariableGet(VariableGet node) {
    if (_function[node.variable] != _currentFunction) {
      variables.add(node.variable);
    }
    node.visitChildren(this);
  }

  visitVariableSet(VariableSet node) {
    if (_function[node.variable] != _currentFunction) {
      variables.add(node.variable);
    }
    node.visitChildren(this);
  }
}

abstract class Context {
  Expression get expression;

  void extend(VariableDeclaration variable, Expression value);

  Expression lookup(VariableDeclaration variable);
  Expression assign(VariableDeclaration variable, Expression value);

  Context toClosureContext(VariableDeclaration parameter);
}

class NoContext extends Context {
  final ClosureConverter converter;

  NoContext(this.converter);

  Expression get expression => new NullLiteral();

  void extend(VariableDeclaration variable, Expression value) {
    converter.context =
        new LocalContext(converter, this)..extend(variable, value);
  }


  Expression lookup(VariableDeclaration variable) {
    throw 'Unbound NoContext.lookup($variable)';
  }

  Expression assign(VariableDeclaration variable, Expression value) {
    throw 'Unbound NoContext.assign($variable, ...)';
  }

  Context toClosureContext(VariableDeclaration parameter) {
    return new ClosureContext(converter, parameter,
                              <List<VariableDeclaration>>[]);
  }
}


class LocalContext extends Context {
  final ClosureConverter converter;
  final Context parent;
  final VariableDeclaration self;
  final IntLiteral size;
  final List<VariableDeclaration> variables = <VariableDeclaration>[];
  
  LocalContext._internal(this.converter, this.parent, this.self, this.size);

  factory LocalContext(ClosureConverter converter, Context parent) {
    Class contextClass = converter.coreTypes.internalContextClass;
    assert(contextClass.constructors.length == 1);
    IntLiteral zero = new IntLiteral(0);
    VariableDeclaration declaration =
        new VariableDeclaration.forValue(
            new ConstructorInvocation(contextClass.constructors.first,
                                      new Arguments(<Expression>[zero])),
            type: new InterfaceType(contextClass));
    converter.insert(declaration);
    converter.insert(new ExpressionStatement(
        new PropertySet(new VariableGet(declaration),
                        new Name('parent'),
                        parent.expression)));
      
    return new LocalContext._internal(converter, parent, declaration, zero);
  }

  Expression get expression => new VariableGet(self);

  void extend(VariableDeclaration variable, Expression value) {
    converter.insert(
        new ExpressionStatement(
            new MethodInvocation(
                expression,
                new Name('[]='),
                new Arguments(
                    <Expression>[new IntLiteral(variables.length), value]))));
    ++size.value;
    variables.add(variable);
  }

  Expression lookup(VariableDeclaration variable) {
    var index = variables.indexOf(variable);
    return index == -1
        ? parent.lookup(variable)
        : new MethodInvocation(
              expression,
              new Name('[]'),
              new Arguments(<Expression>[new IntLiteral(index)]));
  }

  Expression assign(VariableDeclaration variable, Expression value) {
    var index = variables.indexOf(variable);
    return index == -1
        ? parent.assign(variable, value)
        : new MethodInvocation(
              expression,
              new Name('[]='),
              new Arguments(<Expression>[new IntLiteral(index), value]));
  }

  Context toClosureContext(VariableDeclaration parameter) {
    List<List<VariableDeclaration>> variabless = <List<VariableDeclaration>>[];
    var current = this;
    while (current != null && current is! NoContext) {
      if (current is LocalContext) {
        variabless.add(current.variables);
        current = current.parent;
      } else if (current is ClosureContext) {
        variabless.addAll(current.variabless);
        current = null;
      } else if (current is LoopContext) {
        // TODO.
        current = current.parent;
      }
    }
    return new ClosureContext(converter, parameter, variabless);
  }
}

class LoopContext {
  final ClosureConverter converter;
  final Context parent;

  LoopContext(this.converter, this.parent);

  void extend(VariableDeclaration variable, Expression value) {
    converter.context =
        new LocalContext(converter, parent)..extend(variable, value);
  }
}

class ClosureContext extends Context {
  final ClosureConverter converter;
  final VariableDeclaration self;
  final List<List<VariableDeclaration>> variabless;

  ClosureContext(this.converter, this.self, this.variabless);

  Expression get expression => new VariableGet(self);

  void extend(VariableDeclaration variable, Expression value) {
    converter.context =
        new LocalContext(converter, this)..extend(variable, value);
  }

  Expression lookup(VariableDeclaration variable) {
    var context = expression;
    for (var variables in variabless) {
      var index = variables.indexOf(variable);
      if (index != -1) {
        return new MethodInvocation(
            context,
            new Name('[]'),
            new Arguments(<Expression>[new IntLiteral(index)]));
      }
      context = new PropertyGet(context, new Name('parent'));
    }
    throw 'Unbound ClosureContext.lookup($variable)';
  }

  Expression assign(VariableDeclaration variable, Expression value) {
    var context = expression;
    for (var variables in variabless) {
      var index = variables.indexOf(variable);
      if (index != -1) {
        return new MethodInvocation(
            context,
            new Name('[]='),
            new Arguments(<Expression>[new IntLiteral(index), value]));
      }
      context = new PropertyGet(context, new Name('parent'));
    }
    throw 'Unbound ClosureContext.lookup($variable)';
  }

  Context toClosureContext(VariableDeclaration parameter) {
    return new ClosureContext(converter, parameter, variabless);
  }
}

class ClosureConverter extends Transformer {
  final CoreTypes coreTypes;
  final Set<VariableDeclaration> captured;

  Block _currentBlock;
  int _insertionIndex = 0;

  Context context;

  ClosureConverter(this.coreTypes, this.captured);

  void insert(Statement statement) {
    _currentBlock.statements.insert(_insertionIndex++, statement);
    statement.parent = _currentBlock;
  }

  TreeNode visitConstructor(Constructor node) {
    return node;
  }

  TreeNode visitFunctionDeclaration(FunctionDeclaration node) {
    if (captured.contains(node.variable)) {
      context.extend(node.variable,
                     new FunctionExpression(node.function));
    }

    Block savedBlock = _currentBlock;
    int savedIndex = _insertionIndex;
    Context savedContext = context;

    Statement body = node.function.body;
    assert(body != null);

    if (body is Block) {
      _currentBlock = body;
    } else {
      _currentBlock = new Block(<Statements>[body]);
      node.function.body = body.parent = _currentBlock;
    }
    _insertionIndex = 0;

    // TODO: This is really the closure, not the context.
    VariableDeclaration parameter =
        new VariableDeclaration(null,
            type: new InterfaceType(coreTypes.internalContextClass),
            isFinal: true);
    node.function.positionalParameters.insert(0, parameter);
    parameter.parent = node.function;
    ++node.function.requiredParameterCount;
    context = context.toClosureContext(parameter);

    // Don't visit the children, because that included a variable declaration.
    node.function = node.function.accept(this);

    _currentBlock = savedBlock;
    _insertionIndex = savedIndex;
    context = savedContext;

    return captured.contains(node.variable) ? null : node;
  }

  TreeNode visitFunctionExpression(FunctionExpression node) {
    Block savedBlock = _currentBlock;
    int savedIndex = _insertionIndex;
    Context savedContext = context;

    Statement body = node.function.body;
    assert(body != null);

    if (body is Block) {
      _currentBlock = body;
    } else {
      _currentBlock = new Block(<Statements>[body]);
      node.function.body = body.parent = _currentBlock;
    }
    _insertionIndex = 0;

    // TODO: This is really the closure, not the context.
    VariableDeclaration parameter =
        new VariableDeclaration(null,
            type: new InterfaceType(coreTypes.internalContextClass),
            isFinal: true);
    node.function.positionalParameters.insert(0, parameter);
    parameter.parent = node.function;
    ++node.function.requiredParameterCount;
    context = context.toClosureContext(parameter);

    node.transformChildren(this);

    _currentBlock = savedBlock;
    _insertionIndex = savedIndex;
    context = savedContext;

    return node;
  }

  TreeNode visitProcedure(Procedure node) {
    assert(_currentBlock == null);
    assert(_insertionIndex == 0);
    assert(context == null);

    Statement body = node.function.body;
    if (body == null) return node;

    // Ensure that the body is a block which becomes the current block.
    if (body is Block) {
      _currentBlock = body;
    } else {
      _currentBlock = new Block(<Statements>[body]);
      node.function.body = body.parent = _currentBlock;
    }
    _insertionIndex = 0;
    
    // Start with no context.  This happens after setting up _currentBlock
    // so statements can be emitted into _currentBlock if necessary.
    context = new NoContext(this);

    node.transformChildren(this);

    _currentBlock = null;
    _insertionIndex = 0;
    context = null;
    return node;
  }

  TreeNode visitLocalInitializer(LocalInitializer node) {
    assert(!captured.contains(node.variable));
    node.transformChildren(this);
    return node;
  }

  TreeNode visitFunctionNode(FunctionNode node) {
    transformList(node.typeParameters, this, node);

    void extend(VariableDeclaration parameter) {
      context.extend(parameter, new VariableGet(parameter));
    }
    // TODO: Can parameters contain initializers (e.g., for optional ones) that
    // need to be closure converted?
    node.positionalParameters.where(captured.contains).forEach(extend);
    node.namedParameters.where(captured.contains).forEach(extend);
    
    assert(node.body != null);
    node.body = node.body.accept(this);
    node.body.parent = node;
    return node;
  }

  TreeNode visitBlock(Block node) {
    Block savedBlock;
    int savedIndex;
    if (_currentBlock != node) {
      savedBlock = _currentBlock;
      savedIndex = _insertionIndex;
      _currentBlock = node;
      _insertionIndex = 0;
    }

    while (_insertionIndex < _currentBlock.statements.length) {
      assert(_currentBlock == node);

      var original = _currentBlock.statements[_insertionIndex];
      var transformed = original.accept(this);
      assert(_currentBlock.statements[_insertionIndex] == original);
      if (transformed == null) {
        _currentBlock.statements.removeAt(_insertionIndex);
      } else {
        _currentBlock.statements[_insertionIndex++] = transformed;
        transformed.parent = _currentBlock;
      }
    }

    if (savedBlock != null) {
      _currentBlock = savedBlock;
      _insertionIndex = savedIndex;
    }
    return node;
  }

  TreeNode visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);

    if (!captured.contains(node)) return node;
    context.extend(node, node.initializer ?? new NullLiteral());
    return null;
  }

  TreeNode visitVariableGet(VariableGet node) {
    return captured.contains(node.variable)
        ? context.lookup(node.variable)
        : node;
  }

  TreeNode visitVariableSet(VariableSet node) {
    node.transformChildren(this);

    return captured.contains(node.variable)
        ? context.assign(node.variable, node.value)
        : node;
  }
}
