// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'closures.dart';
import 'translator.dart';

/// Information about a constructor's parameter usages, used to optimize
/// the signatures of the 3 (allocator, initializer,
/// body) constructor functions.
class ConstructorInfo {
  final Constructor constructor;
  final Translator translator;

  /// All parameters of the constructor in canonical order (positional first,
  /// then named sorted by name).
  final List<VariableDeclaration> allParameters;

  /// Parameters that must be passed to the initializer function.
  late final List<TypeParameter> initializerTypeParameters;
  late final List<VariableDeclaration> initializerParameters;

  /// Parameters that must be passed to the body function from the allocator.
  ///
  /// NOTE: Type parameters of a constructor always end up in fields and can be
  /// loaded from there. The constructor body therefore never needs to get them
  /// passed explicitly.
  late final List<VariableDeclaration> bodyParameters;

  /// Parameters that constructor bodies can load via `this`.
  final Map<VariableDeclaration, Field> parameterToField = {};

  ConstructorInfo(this.constructor, this.translator)
    : allParameters = [
        ...constructor.function.positionalParameters,
        ...(constructor.function.namedParameters.toList()
          ..sort((a, b) => a.name!.compareTo(b.name!))),
      ] {
    // The initializer gets all arguments and produces
    //   - arguments to be passed to the body function
    //   - field values.
    initializerTypeParameters = constructor.enclosingClass.typeParameters;
    initializerParameters = allParameters;

    if (constructor.isExternal) {
      // Currently the backend generates NSM in the initializer function
      // and a trap in body function and doesn't need the parameters.
      bodyParameters = [];
      return;
    }

    // Analyze parameter usages in initializers & body.
    final closures = translator.getClosures(constructor);
    final initializerCollector = _UsageCollector(translator, closures)
      ..collectInitializerUsages(constructor);
    final bodyCollector = _UsageCollector(translator, closures)
      ..collectBodyUsages(constructor);

    // Identify parameters that end up in fields and are not modified, so the
    // body function can load them from `this` instead of getting them as
    // parameters.
    for (final p in allParameters) {
      if (initializerCollector.variablesCaptured.contains(p)) {
        // The parameter will reside in the initializer context and doesn't
        // have to be passed to the body explicitly.
        continue;
      }
      if (initializerCollector.variablesWritten.contains(p)) {
        // If the parameter is modified by initializers the value that ends up
        // in a field may not be the same as the value of the (modified)
        // parameter. So the body function may need to get the modified value
        // as the value from the field may not reflect the modification.
        continue;
      }
      if (initializerCollector.variablesStoredInFields[p] case final field?) {
        // The parameter is
        //   * not captured by initializers
        //   * never written to by initializers
        //   * is available via `this` to the body
        parameterToField[p] = field;
      }
    }

    bodyParameters = [];
    for (final param in allParameters) {
      if (!bodyCollector.variablesRead.contains(param) &&
          !bodyCollector.variablesWritten.contains(param)) {
        // The body doesn't use the parameter.
        continue;
      }
      if (initializerCollector.variablesCaptured.contains(param)) {
        // The body should use the parameter from the context.
        continue;
      }
      if (parameterToField.containsKey(param)) {
        // The body can load the parameter via `this`.
        continue;
      }
      bodyParameters.add(param);
    }
  }
}

/// Collects used variables and type parameters from an AST subtree.
class _UsageCollector extends RecursiveVisitor {
  final Translator translator;
  final Closures closures;

  final variablesRead = <VariableDeclaration>{};
  final variablesWritten = <VariableDeclaration>{};
  final variablesCaptured = <VariableDeclaration>{};
  final usedTypeParameters = <TypeParameter>{};
  final variablesStoredInFields = <VariableDeclaration, Field>{};

  _UsageCollector(this.translator, this.closures);

  void collectInitializerUsages(Constructor constructor) {
    final rootContext = closures.contexts[constructor];
    if (rootContext != null) {
      assert(rootContext.parent == null);
      if (closures.contexts[constructor] case final context?) {
        variablesCaptured.addAll(context.variables);
      }
    }

    for (final init in constructor.initializers) {
      init.accept(this);
    }
  }

  void collectBodyUsages(Constructor constructor) {
    constructor.function.body?.accept(this);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    super.visitFieldInitializer(node);
    final value = node.value;
    if (value is VariableGet) {
      variablesStoredInFields[value.variable] = node.field;
    }
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    super.visitSuperInitializer(node);
    _findVariablesStoredInFields(node.target, node.arguments);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    super.visitRedirectingInitializer(node);
    _findVariablesStoredInFields(node.target, node.arguments);
  }

  void _findVariablesStoredInFields(Constructor target, Arguments arguments) {
    final targetInfo = translator.getConstructorInfo(target);
    for (int i = 0; i < arguments.positional.length; ++i) {
      final arg = arguments.positional[i];
      if (arg is VariableGet) {
        final targetParam = target.function.positionalParameters[i];
        final field = targetInfo.parameterToField[targetParam];
        if (field != null) {
          variablesStoredInFields[arg.variable] = field;
        }
      }
    }
    for (final namedArg in arguments.named) {
      final arg = namedArg.value;
      if (arg is VariableGet) {
        for (final targetNamedParameter in target.function.namedParameters) {
          if (targetNamedParameter.name == namedArg.name) {
            final field = targetInfo.parameterToField[targetNamedParameter];
            if (field != null) {
              variablesStoredInFields[arg.variable] = field;
            }
          }
        }
      }
    }
  }

  @override
  void visitVariableGet(VariableGet node) {
    variablesRead.add(node.variable);
  }

  @override
  void visitVariableSet(VariableSet node) {
    node.value.accept(this);
    variablesWritten.add(node.variable);
  }

  @override
  void visitTypeParameterType(TypeParameterType node) {
    usedTypeParameters.add(node.parameter);
  }

  @override
  void visitClassTypeParameterType(ClassTypeParameterType node) {
    usedTypeParameters.add(node.parameter);
  }
}
