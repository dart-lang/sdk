// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.context;

import '../../ast.dart'
    show
        Arguments,
        Class,
        Expression,
        IntLiteral,
        MethodInvocation,
        Name,
        NullLiteral,
        PropertyGet,
        StringLiteral,
        Throw,
        TreeNode,
        VariableDeclaration,
        VariableGet,
        VariableSet;

import '../../frontend/accessors.dart'
    show Accessor, IndexAccessor, VariableAccessor;

import 'converter.dart' show ClosureConverter;

abstract class Context {
  /// Returns a new expression for accessing this context.
  Expression get expression;

  /// Returns an accessor (or null) for accessing this context.
  Accessor get accessor;

  /// Extend the context to include [variable] initialized to [value]. For
  /// example, this replaces the [VariableDeclaration] node of a captured local
  /// variable.
  ///
  /// This may create a new context and update the `context` field of the
  /// current [ClosureConverter].
  // TODO(ahe): Return context instead?
  void extend(VariableDeclaration variable, Expression value);

  /// Update the initializer [value] of [variable] which was previously added
  /// with [extend]. This is used when [value] isn't available when the context
  /// was extended.
  void update(VariableDeclaration variable, Expression value) {
    throw "not supported $runtimeType";
  }

  /// Returns a new expression for reading the value of [variable] from this
  /// context. For example, for replacing a [VariableGet] of a captured local
  /// variable.
  Expression lookup(VariableDeclaration variable);

  /// Returns a new expression which stores [value] in [variable] in this
  /// context. For example, for replacing a [VariableSet] of a captured local
  /// variable.
  Expression assign(VariableDeclaration variable, Expression value,
      {bool voidContext: false});

  /// Returns a new context whose parent is this context. The optional argument
  /// [accessor] controls how the nested context access this context. This is
  /// used, for example, when hoisting a local function. In this case, access
  /// to this context can't be accessed directly via [expression]. In other
  /// cases, for example, a for-loop, this context is still in scope and can be
  /// accessed directly (with [accessor]).
  Context toNestedContext([Accessor accessor]);

  /// Returns a new expression which will copy this context and store the copy
  /// in the local variable currently holding this context.
  Expression clone() {
    return new Throw(
        new StringLiteral("Context clone not implemented for ${runtimeType}"));
  }
}

class NoContext extends Context {
  final ClosureConverter converter;

  NoContext(this.converter);

  Expression get expression => new NullLiteral();

  Accessor get accessor => null;

  void extend(VariableDeclaration variable, Expression value) {
    converter.context = new LocalContext(converter, this)
      ..extend(variable, value);
  }

  Expression lookup(VariableDeclaration variable) {
    throw 'Unbound NoContext.lookup($variable)';
  }

  Expression assign(VariableDeclaration variable, Expression value,
      {bool voidContext: false}) {
    throw 'Unbound NoContext.assign($variable, ...)';
  }

  Context toNestedContext([Accessor accessor]) {
    return new NestedContext(
        converter, accessor, <List<VariableDeclaration>>[]);
  }
}

class LocalContext extends Context {
  final ClosureConverter converter;
  final Context parent;
  final VariableDeclaration self;
  final IntLiteral size;
  final List<VariableDeclaration> variables = <VariableDeclaration>[];
  final Map<VariableDeclaration, Arguments> initializers =
      <VariableDeclaration, Arguments>{};

  LocalContext._internal(this.converter, this.parent, this.self, this.size);

  factory LocalContext(ClosureConverter converter, Context parent) {
    Class contextClass = converter.contextClass;
    assert(contextClass.constructors.length == 1);
    converter.rewriter
        .insertContextDeclaration(contextClass, parent.expression);

    return new LocalContext._internal(converter, parent,
        converter.rewriter.contextDeclaration, converter.rewriter.contextSize);
  }

  Expression get expression => accessor.buildSimpleRead();

  Accessor get accessor => new VariableAccessor(self, null, TreeNode.noOffset);

  void extend(VariableDeclaration variable, Expression value) {
    Arguments arguments =
        new Arguments(<Expression>[new IntLiteral(variables.length), value]);
    converter.rewriter.insertExtendContext(expression, arguments);
    ++size.value;
    variables.add(variable);
    initializers[variable] = arguments;
  }

  void update(VariableDeclaration variable, Expression value) {
    Arguments arguments = initializers[variable];
    arguments.positional[1] = value;
    value.parent = arguments;
  }

  Expression lookup(VariableDeclaration variable) {
    var index = variables.indexOf(variable);
    return index == -1
        ? parent.lookup(variable)
        : new MethodInvocation(expression, new Name('[]'),
            new Arguments(<Expression>[new IntLiteral(index)]));
  }

  Expression assign(VariableDeclaration variable, Expression value,
      {bool voidContext: false}) {
    var index = variables.indexOf(variable);
    return index == -1
        ? parent.assign(variable, value, voidContext: voidContext)
        : IndexAccessor
            .make(expression, new IntLiteral(index), null, null)
            .buildAssignment(value, voidContext: voidContext);
  }

  Context toNestedContext([Accessor accessor]) {
    accessor ??= this.accessor;
    List<List<VariableDeclaration>> variabless = <List<VariableDeclaration>>[];
    var current = this;
    while (current != null && current is! NoContext) {
      if (current is LocalContext) {
        variabless.add(current.variables);
        current = current.parent;
      } else if (current is NestedContext) {
        variabless.addAll((current as NestedContext).variabless);
        current = null;
      }
    }
    return new NestedContext(converter, accessor, variabless);
  }

  Expression clone() {
    self.isFinal = false;
    return new VariableSet(
        self,
        new MethodInvocation(
            new VariableGet(self), new Name("copy"), new Arguments.empty()));
  }
}

class NestedContext extends Context {
  final ClosureConverter converter;
  final Accessor accessor;
  final List<List<VariableDeclaration>> variabless;

  NestedContext(this.converter, this.accessor, this.variabless);

  Expression get expression {
    return accessor?.buildSimpleRead() ?? new NullLiteral();
  }

  void extend(VariableDeclaration variable, Expression value) {
    converter.context = new LocalContext(converter, this)
      ..extend(variable, value);
  }

  Expression lookup(VariableDeclaration variable) {
    Expression context = expression;
    for (var variables in variabless) {
      var index = variables.indexOf(variable);
      if (index != -1) {
        return new MethodInvocation(context, new Name('[]'),
            new Arguments(<Expression>[new IntLiteral(index)]));
      }
      context = new PropertyGet(context, new Name('parent'));
    }
    throw 'Unbound NestedContext.lookup($variable)';
  }

  Expression assign(VariableDeclaration variable, Expression value,
      {bool voidContext: false}) {
    Expression context = expression;
    for (List<VariableDeclaration> variables in variabless) {
      var index = variables.indexOf(variable);
      if (index != -1) {
        return IndexAccessor
            .make(context, new IntLiteral(index), null, null)
            .buildAssignment(value, voidContext: voidContext);
      }
      context = new PropertyGet(context, new Name('parent'));
    }
    throw 'Unbound NestedContext.lookup($variable)';
  }

  Context toNestedContext([Accessor accessor]) {
    return new NestedContext(converter, accessor ?? this.accessor, variabless);
  }
}
