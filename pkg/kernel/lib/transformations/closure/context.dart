// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.closure.context;

import '../../ast.dart'
    show
        Expression,
        NullLiteral,
        StringLiteral,
        Throw,
        TreeNode,
        VariableDeclaration,
        VariableGet,
        VariableSet,
        VectorCreation,
        VectorGet,
        VectorSet,
        VectorCopy;

import '../../frontend/accessors.dart' show Accessor, VariableAccessor;

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
  final VectorCreation vectorCreation;
  final List<VariableDeclaration> variables = <VariableDeclaration>[];
  final Map<VariableDeclaration, VectorSet> initializers =
      <VariableDeclaration, VectorSet>{};

  LocalContext._internal(
      this.converter, this.parent, this.self, this.vectorCreation);

  factory LocalContext(ClosureConverter converter, Context parent) {
    converter.rewriter.insertContextDeclaration(parent.expression);

    return new LocalContext._internal(
        converter,
        parent,
        converter.rewriter.contextDeclaration,
        converter.rewriter.vectorCreation);
  }

  Expression get expression => accessor.buildSimpleRead();

  Accessor get accessor => new VariableAccessor(self, null, TreeNode.noOffset);

  void extend(VariableDeclaration variable, Expression value) {
    // Increase index by 1, because the parent occupies item 0, and all other
    // variables are therefore shifted by 1.
    VectorSet initializer =
        new VectorSet(expression, variables.length + 1, value);
    value.parent = initializer;

    converter.rewriter.insertExtendContext(initializer);

    ++vectorCreation.length;
    variables.add(variable);
    initializers[variable] = initializer;
  }

  void update(VariableDeclaration variable, Expression value) {
    VectorSet initializer = initializers[variable];
    initializer.value = value;
    value.parent = initializer;
  }

  Expression lookup(VariableDeclaration variable) {
    var index = variables.indexOf(variable);
    // Increase index by 1 in case of success, because the parent occupies
    // item 0, and all other variables are therefore shifted by 1.
    return index == -1
        ? parent.lookup(variable)
        : new VectorGet(expression, index + 1);
  }

  Expression assign(VariableDeclaration variable, Expression value,
      {bool voidContext: false}) {
    var index = variables.indexOf(variable);
    // Increase index by 1 in case of success, because the parent occupies
    // item 0, and all other variables are therefore shifted by 1.
    return index == -1
        ? parent.assign(variable, value, voidContext: voidContext)
        : new VectorSet(expression, index + 1, value);
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
    return new VariableSet(self, new VectorCopy(new VariableGet(self)));
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
        // Increase index by 1, because the parent occupies item 0, and all
        // other variables are therefore shifted by 1.
        return new VectorGet(context, index + 1);
      }
      // Item 0 of a context always points to its parent.
      context = new VectorGet(context, 0);
    }
    throw 'Unbound NestedContext.lookup($variable)';
  }

  Expression assign(VariableDeclaration variable, Expression value,
      {bool voidContext: false}) {
    Expression context = expression;
    for (List<VariableDeclaration> variables in variabless) {
      var index = variables.indexOf(variable);
      if (index != -1) {
        // Increase index by 1, because the parent occupies item 0, and all
        // other variables are therefore shifted by 1.
        return new VectorSet(context, index + 1, value);
      }
      // Item 0 of a context always points to its parent.
      context = new VectorGet(context, 0);
    }
    throw 'Unbound NestedContext.lookup($variable)';
  }

  Context toNestedContext([Accessor accessor]) {
    return new NestedContext(converter, accessor ?? this.accessor, variabless);
  }
}
