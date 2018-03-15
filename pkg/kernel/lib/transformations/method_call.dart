// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.transformations.method_call;

import 'dart:math' as math;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../kernel.dart';
import '../visitor.dart';

/// Problems with the method rewrite transformation:
///
/// * Cannot rewrite invocations to things called "call" because of tear-offs
///   and whatnot that when invoked turns into variableName.call(...).
///
/// * Cannot rewrite invocations to things sharing a name with a field because
///   one could have called clazz.fieldName(...).
///
/// * Rewrites will make stacktraces look weird.
///
/// * Rewrites will make noSuchMethod look weird --- e.g. calling a non-existing
///   function foo(a: 42) turns into foo%0%a(42), i.e. the method name has
///   changed ("foo" vs "foo%0%a") and the arguments has changed (named "a" vs
///   positional).
///   NOTE: At least for now this can be fixed by changing the
///   invocation_mirror_patch file. Doing this I can make all dill, language
///   and co19 tests pass!
///
/// Somewhat weird:
///
/// * Inserts methods that redirect to the correct noSuchMethod invocation
///   so that program #1 example below will work.
///   The reason it otherwise wouldn't is that b.foo(499, named1: 88) is
///   rewritten to b.foo%1%named1(499, 88) which is not legal for class B
///   (thus the method would not be create there) but IS legal for Bs parent
///   class (A), so it would be created there. The call will thus go to the
///   super (A) but shouldn't as foo was overwritten in B.
///
/// Program #1 example:
/// class A {
///   foo(required1, { named1: 499}) => print("Hello from class A");
/// }
///
/// class B extends A {
///   foo(required1) => print("Hello from class B");
/// }
///
/// main() {
///   var b = new B();
///   b.foo(499, named1: 88);
/// }
Component transformComponent(
    CoreTypes coreTypes, ClassHierarchy hierarchy, Component component,
    [debug = false]) {
  new MethodCallTransformer(coreTypes, hierarchy, debug)
      .visitComponent(component);
  return component;
}

class MethodCallTransformer extends Transformer {
  final CoreTypes coreTypes;

  /// Keep track of "visited" procedures and constructors to not visit already
  /// visited stuff, nor visit newly created stubs.
  Set<Member> _visited = new Set<Member>();

  /// Some things currently cannot be rewritten. Calls to methods called "call"
  /// (because invoking tear-offs and closures and whatnot becomes .call)
  /// as well as clashes with field names as a field can contain a function
  /// and one can then do a clazz.fieldName(...).
  Set<String> blacklistedSelectors = new Set<String>.from(["call"]);

  /// Map from a "originally named" procedure to the "%original" procedure
  /// for procedures that was moved.
  Map<Procedure, Procedure> _movedBodies = {};

  /// Map from a "originally named" constructor to the "%original"
  /// constructor for constructors that was moved.
  Map<Constructor, Constructor> _movedConstructors = {};

  /// For static method transformations:
  /// Maps a procedure to the mapping of argument signature to procedure stub.
  Map<Procedure, Map<String, Procedure>> _staticProcedureCalls = {};

  /// For constructor transformations:
  /// Maps a constructor to a mapping of argument signature to constructor stub.
  Map<Constructor, Map<String, Constructor>> _constructorCalls = {};

  /// For non-static method transformations:
  /// Maps from method name to the set of legal number of positional arguments.
  Map<String, Set<int>> _methodToLegalPositionalArgumentCount = {};

  /// For non-static method transformations:
  /// Maps from name of method to the set of new target names seen for at least
  /// one instance (i.e. rewriting has been performed from key to all values in
  /// the mapped to set at least once).
  Map<Name, Set<String>> _rewrittenMethods = {};

  /// For non-static method transformations:
  /// Maps a procedure to the mapping of argument signature to procedure stub.
  Map<Procedure, Map<String, Procedure>> _superProcedureCalls = {};

  /// Whether in debug mode, i.e. if we can insert extra print statements for
  /// debugging purposes.
  bool _debug;

  /// For noSuchMethod calls.
  ClassHierarchy hierarchy;
  Constructor _invocationMirrorConstructor; // cached
  Procedure _listFrom; // cached

  MethodCallTransformer(this.coreTypes, this.hierarchy, this._debug);

  @override
  TreeNode visitComponent(Component node) {
    // First move body of all procedures that takes optional positional or named
    // parameters and record which non-static procedure names have optional
    // positional arguments.
    // Do the same for constructors. Then also rewrite constructor initializers
    // using LocalInitializer and sort named arguments in those initializers
    for (final library in node.libraries) {
      for (final procedure in new List<Procedure>.from(library.procedures)) {
        _moveAndTransformProcedure(procedure);
      }

      for (final clazz in library.classes) {
        for (final field in clazz.fields) {
          blacklistedSelectors.add(field.name.name);
        }

        for (final procedure in new List<Procedure>.from(clazz.procedures)) {
          // This call creates new procedures
          _moveAndTransformProcedure(procedure);
          _recordNonStaticProcedureAndVariableArguments(procedure);
        }

        for (final constructor
            in new List<Constructor>.from(clazz.constructors)) {
          // This call creates new constructors
          _moveAndTransformConstructor(constructor);
        }

        for (final constructor in clazz.constructors) {
          _rewriteConstructorInitializations(constructor);
        }
      }
    }

    // Rewrite calls
    node.transformChildren(this);

    // Now for all method calls that was rewritten, make sure those call
    // destinations actually exist, i.e. for each method with a matching name
    // where the called-with-arguments is legal, create a stub
    for (final library in node.libraries) {
      for (final clazz in library.classes) {
        for (final procedure in new List<Procedure>.from(clazz.procedures)) {
          // This call creates new procedures
          _createNeededNonStaticStubs(procedure);
        }
      }
    }

    return node;
  }

  @override
  TreeNode visitProcedure(Procedure node) {
    if (!_visited.contains(node)) {
      _visited.add(node);
      node.transformChildren(this);
    }
    return node;
  }

  @override
  TreeNode visitConstructor(Constructor node) {
    if (!_visited.contains(node)) {
      _visited.add(node);
      node.transformChildren(this);
    }
    return node;
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    if (!_isMethod(node.target)) return node;
    if (!_hasAnyOptionalParameters(node.target.function)) return node;
    if (!_callIsLegal(node.target.function, node.arguments)) return node;

    // Rewrite with let if needed (without named arguments it won't do anything)
    Expression rewrittenNode = _rewriteWithLetAndSort(node, node.arguments);

    // Create/lookup target and set it as the new target
    node.target = _getNewTargetForStaticLikeInvocation(
        node.target, node.arguments, _staticProcedureCalls);

    // Now turn any named parameters into positional parameters
    _turnNamedArgumentsIntoPositional(node.arguments);
    return rewrittenNode;
  }

  @override
  TreeNode visitDirectMethodInvocation(DirectMethodInvocation node) {
    node.transformChildren(this);
    if (!_isMethod(node.target)) return node;
    if (!_hasAnyOptionalParameters(node.target.function)) return node;
    if (!_callIsLegal(node.target.function, node.arguments)) return node;

    // Rewrite with let if needed (without named arguments it won't do anything)
    Expression rewrittenNode = _rewriteWithLetAndSort(node, node.arguments);

    // Create/lookup target and set it as the new target
    node.target = _getNewTargetForStaticLikeInvocation(
        node.target, node.arguments, _superProcedureCalls);

    // Now turn any named parameters into positional parameters instead
    _turnNamedArgumentsIntoPositional(node.arguments);
    return rewrittenNode;
  }

  @override
  TreeNode visitSuperMethodInvocation(SuperMethodInvocation node) {
    // SuperMethodInvocation was changed since I originally wrote this,
    // and now it seems to never be called anyway.
    throw "visitSuperMethodInvocation is not implemented!";
  }

  @override
  TreeNode visitMethodInvocation(MethodInvocation node) {
    node.transformChildren(this);
    final name = node.name.name;

    // Don't renamed calls to methods that clashes in name with a field
    // or is called "call".
    if (blacklistedSelectors.contains(name)) return node;

    // Rewrite with let if needed (without named arguments it won't do anything)
    Expression rewrittenNode = _rewriteWithLetAndSort(node, node.arguments);

    String argumentsSignature = _createArgumentsSignature(node.arguments);
    if (node.arguments.named.isEmpty) {
      // Positional: Don't rewrite if no procedure with that name can be called
      // with a variable number of arguments, or where the number of arguments
      // called with here isn't a legal number of arguments to any such
      // procedure.
      // Note for named arguments: Named arguments are always rewritten
      // (except for 'call' methods) so there's no such check
      final okCounts = _methodToLegalPositionalArgumentCount[name];

      if (okCounts == null ||
          !okCounts.contains(node.arguments.positional.length)) {
        return node;
      }
    }

    // Rewrite this call
    final originalName = node.name;
    node.name = _createName(node.name, argumentsSignature);

    // Remember that we rewrote this call
    _rewrittenMethods
        .putIfAbsent(originalName, () => new Set<String>())
        .add(argumentsSignature);

    // Now turn any named parameters into positional parameters instead
    _turnNamedArgumentsIntoPositional(node.arguments);
    return rewrittenNode;
  }

  @override
  TreeNode visitConstructorInvocation(ConstructorInvocation node) {
    node.transformChildren(this);
    if (!_callIsLegal(node.target.function, node.arguments)) return node;

    Expression rewrittenNode;
    if (node.isConst) {
      // Sort named arguments by name => it's const so there's no side-effects!
      // but DO NOT rewrite with let!
      node.arguments.named.sort((a, b) => a.name.compareTo(b.name));
      rewrittenNode = node;
    } else {
      rewrittenNode = _rewriteWithLetAndSort(node, node.arguments);
    }
    node.target = _getNewTargetForConstructor(node.target, node.arguments);

    // Now turn named parameters into positional parameters instead
    _turnNamedArgumentsIntoPositional(node.arguments);
    return rewrittenNode;
  }

  @override
  TreeNode visitSuperInitializer(SuperInitializer node) {
    // Note that sorting was done in _rewriteConstructorInitializations
    node.transformChildren(this);
    if (!_callIsLegal(node.target.function, node.arguments)) return node;

    node.target = _getNewTargetForConstructor(node.target, node.arguments);

    // Now turn named parameters into positional parameters instead
    _turnNamedArgumentsIntoPositional(node.arguments);
    return node;
  }

  @override
  TreeNode visitRedirectingInitializer(RedirectingInitializer node) {
    // Note that sorting was done in _rewriteConstructorInitializations
    node.transformChildren(this);
    if (!_callIsLegal(node.target.function, node.arguments)) return node;

    node.target = _getNewTargetForConstructor(node.target, node.arguments);

    // Now turn named parameters into positional parameters instead
    _turnNamedArgumentsIntoPositional(node.arguments);
    return node;
  }

  /// Gets the new target for an invocation, using cache or creating a new one.
  ///
  /// Assumes that any let-rewrite, named argument sorting etc has been done
  /// already.
  Procedure _getNewTargetForStaticLikeInvocation(Procedure target,
      Arguments arguments, Map<Procedure, Map<String, Procedure>> cache) {
    final createdProcedures = cache.putIfAbsent(target, () => {});

    // Rewrite target
    final argumentsSignature = _createArgumentsSignature(arguments);
    return createdProcedures[argumentsSignature] ??
        _createAndCacheInvocationProcedure(
            argumentsSignature,
            arguments.positional.length,
            arguments.named.map((e) => e.name).toList(),
            target,
            _movedBodies[target],
            createdProcedures,
            true);
  }

  /// Rewrite the [Argument]s turning named arguments into positional arguments.
  ///
  /// Note that if the [Argument]s does not take any named parameters this
  /// method does nothing.
  void _turnNamedArgumentsIntoPositional(Arguments arguments) {
    for (final named in arguments.named) {
      arguments.positional.add(named.value..parent = arguments);
    }
    arguments.named.clear();
  }

  /// Gets the new target for an invocation, using cache or creating a new one.
  ///
  /// Assumes that any let-rewrite, named argument sorting etc has been done
  /// already.
  Constructor _getNewTargetForConstructor(
      Constructor target, Arguments arguments) {
    if (!_isNotExternal(target)) return target;
    if (!_hasAnyOptionalParameters(target.function)) return target;

    final argumentsSignature = _createArgumentsSignature(arguments);
    final createdConstructor = _constructorCalls.putIfAbsent(target, () => {});
    return createdConstructor[argumentsSignature] ??
        _createAndCacheInvocationConstructor(
            argumentsSignature,
            arguments.positional.length,
            arguments.named.map((e) => e.name).toList(),
            target,
            _movedConstructors[target],
            createdConstructor,
            true);
  }

  /// Create a signature for the [Arguments].
  ///
  /// Assumes that any needed sorting etc has already been done.
  ///
  /// Looks like x%positionalCount%named --- but it shouldn't matter if always
  /// using these methods
  String _createArgumentsSignature(Arguments arguments) {
    String namedString = arguments.named.map((e) => e.name).join("%");
    return "${arguments.positional.length}%$namedString";
  }

  /// Parse the argument signature.
  ///
  /// First element will be the string representation of the number of
  /// positional arguments used.
  /// The rest will be the named arguments, except that with no named arguments
  /// there still is a 2nd entry: the empty string...
  List<String> _parseArgumentsSignature(String argumentsSignature) {
    return argumentsSignature.split("%");
  }

  /// Rewrites an expression with let, replacing expressions in the [Arguments].
  ///
  /// Sorts the named arguments after rewriting with let.
  ///
  /// Note that this method does nothing if there are no named arguments, or the
  /// named arguments list contain only a single named argument as any sorting
  /// would have no effect. As such, the let-rewrite will also have no effect.
  /// In such a case the return value is [original].
  Expression _rewriteWithLetAndSort(Expression original, Arguments arguments) {
    final named = arguments.named;

    // Only bother if names can be unordered
    if (named.length < 2) return original;

    // Rewrite named with let in given order
    Let let;
    for (int i = named.length - 1; i >= 0; i--) {
      VariableDeclaration letDeclaration =
          new VariableDeclaration.forValue(named[i].value);
      named[i].value = new VariableGet(letDeclaration)..parent = arguments;
      let = new Let(letDeclaration, let ?? original);
    }

    // Sort named arguments by name
    named.sort((a, b) => a.name.compareTo(b.name));

    // Now also add the given positional arguments into the let
    final expressions = arguments.positional;
    for (int i = expressions.length - 1; i >= 0; i--) {
      VariableDeclaration letDeclaration =
          new VariableDeclaration.forValue(expressions[i]);
      expressions[i] = new VariableGet(letDeclaration)..parent = arguments;
      let = new Let(letDeclaration, let ?? original);
    }

    return let;
  }

  /// Creates all needed stubs for non static procedures.
  ///
  /// More specifically: If calls have been made to a procedure with the same
  /// name as this procedure with both 1 and 2 arguments, where both of these
  /// are legal inputs to this procedure, create stubs for both of them,
  /// each of which calls with whatever default parameter values are defined for
  /// the non-given arguments.
  void _createNeededNonStaticStubs(Procedure procedure) {
    final incomingCalls = _rewrittenMethods[procedure.name];
    if (incomingCalls != null &&
        procedure.kind == ProcedureKind.Method &&
        !procedure.isStatic) {
      final createdOnSuper = _superProcedureCalls[procedure];
      final names =
          procedure.function.namedParameters.map((e) => e.name).toSet();

      // A procedure with this name was called on at least one object with
      // an argument signature like any in [incomingCalls]
      nextArgumentSignature:
      for (final argumentsSignature in incomingCalls) {
        // Skip if it was created in a super call already
        if (createdOnSuper != null &&
            createdOnSuper.containsKey(argumentsSignature)) {
          continue;
        }

        final elements = _parseArgumentsSignature(argumentsSignature);
        int positional = int.parse(elements[0]);

        if (positional < procedure.function.requiredParameterCount ||
            positional > procedure.function.positionalParameters.length) {
          // We don't take that number of positional parameters!
          // Call noSuchMethod in case anyone called on object with wrong
          // parameters, but where superclass does take these parameters.
          _createNoSuchMethodStub(
              argumentsSignature, positional, elements.sublist(1), procedure);
          continue;
        }

        if (elements.length > 2 || elements[1] != "") {
          // Named: Could the call be for this method?
          for (int i = 1; i < elements.length; i++) {
            String name = elements[i];
            // Using a name that we don't have?
            if (!names.contains(name)) {
              // Call noSuchMethod in case anyone called on object with wrong
              // parameters, but where superclass does take these parameters.
              _createNoSuchMethodStub(argumentsSignature, positional,
                  elements.sublist(1), procedure);
              continue nextArgumentSignature;
            }
          }
        }

        // Potential legal call => make stub
        // Note the ?? here: E.g. contains on list doesn't take optionals so it
        // wasn't moved, but calls were rewritten because contains on string
        // takes either 1 or 2 arguments.
        final destination = _movedBodies[procedure] ?? procedure;
        _createAndCacheInvocationProcedure(argumentsSignature, positional,
            elements.sublist(1), procedure, destination, {}, false);
      }
    }
  }

  /// Records how this procedure can be called (if it is non-static).
  ///
  /// More specifically: Assuming that the procedure given is non-static taking
  /// a variable number of positional parameters, record all number of arguments
  /// that is legal, e.g. foo(int a, [int b]) is legal for 1 and 2 parameters.
  /// If it takes named parameters, remember how many positional there is so
  /// we also know to rewrite calls without the named arguments.
  void _recordNonStaticProcedureAndVariableArguments(Procedure procedure) {
    if (_isMethod(procedure) &&
        !procedure.isStatic &&
        _hasAnyOptionalParameters(procedure.function)) {
      final name = procedure.name.name;
      final okCounts = _methodToLegalPositionalArgumentCount.putIfAbsent(
          name, () => new Set<int>());
      for (int i = procedure.function.requiredParameterCount;
          i <= procedure.function.positionalParameters.length;
          i++) {
        okCounts.add(i);
      }
    }
  }

  /// Move body of procedure to new procedure and call that from this procedure.
  ///
  /// More specifically: For all procedures with optional positional parameters,
  /// or named parameters, create a new procedure without optional positional
  /// parameters and named parameters and move the body of the original
  /// procedure into this new procedure.
  /// Then make the body of the original procedure call the new procedure.
  ///
  /// The idea is that all rewrites should call the moved procedure instead,
  /// bypassing the optional/named arguments entirely.
  void _moveAndTransformProcedure(Procedure procedure) {
    if (_isMethod(procedure) && _hasAnyOptionalParameters(procedure.function)) {
      final function = procedure.function;

      // Create variable lists
      final newParameterDeclarations = <VariableDeclaration>[];
      final newNamedParameterDeclarations = <VariableDeclaration>[];
      final newParameterVariableGets = <Expression>[];
      final targetParameters = function.positionalParameters;
      final targetNamedParameters = function.namedParameters;
      _moveVariableInitialization(
          targetParameters,
          targetNamedParameters,
          newParameterDeclarations,
          newNamedParameterDeclarations,
          newParameterVariableGets,
          procedure.function);

      // Create new procedure looking like the old one
      // (with the old body and parameters)
      FunctionNode functionNode = _createShallowFunctionCopy(function);
      final newProcedure = new Procedure(
          _createOriginalName(procedure), ProcedureKind.Method, functionNode,
          isAbstract: procedure.isAbstract,
          isStatic: procedure.isStatic,
          isConst: procedure.isConst,
          fileUri: procedure.fileUri);

      // Add procedure to the code
      _addMember(procedure, newProcedure);

      // Map moved body
      _movedBodies[procedure] = newProcedure;

      // Transform original procedure
      if (procedure.isAbstract && procedure.function.body == null) {
        // do basically nothing then
        procedure.function.positionalParameters = newParameterDeclarations;
        procedure.function.namedParameters = newNamedParameterDeclarations;
      } else if (procedure.isStatic) {
        final expression = new StaticInvocation(
            newProcedure, new Arguments(newParameterVariableGets));
        final statement = new ReturnStatement(expression)
          ..parent = procedure.function;
        procedure.function.body = statement;
        procedure.function.positionalParameters = newParameterDeclarations;
        procedure.function.namedParameters = newNamedParameterDeclarations;
      } else {
        final expression = new DirectMethodInvocation(new ThisExpression(),
            newProcedure, new Arguments(newParameterVariableGets));
        final statement = new ReturnStatement(expression)
          ..parent = procedure.function;
        procedure.function.body = statement;
        procedure.function.positionalParameters = newParameterDeclarations;
        procedure.function.namedParameters = newNamedParameterDeclarations;
      }

      if (_debug) {
        // Debug flag set: Print something to the terminal before returning to
        // easily detect if rewrites are missing.
        Expression debugPrint = _getPrintExpression(
            "DEBUG! Procedure shouldn't have been called...", procedure);
        procedure.function.body = new Block(
            [new ExpressionStatement(debugPrint), procedure.function.body])
          ..parent = procedure.function;
      }

      // Mark original procedure as seen (i.e. don't transform it further)
      _visited.add(procedure);
    }
  }

  /// Rewrite constructor initializers by introducing variables and sorting.
  ///
  /// For any* [SuperInitializer] or [RedirectingInitializer], extract the
  /// parameters, put them into variables, then sorting the named parameters.
  /// The idea is to sort the named parameters without changing any invocation
  /// order.
  ///
  /// * only with at least 2 named arguments, otherwise sorting would do nothing
  void _rewriteConstructorInitializations(Constructor constructor) {
    if (_isNotExternal(constructor)) {
      // Basically copied from "super_calls.dart"
      List<Initializer> initializers = constructor.initializers;
      int foundIndex = -1;
      Arguments arguments;
      for (int i = initializers.length - 1; i >= 0; --i) {
        Initializer initializer = initializers[i];
        if (initializer is SuperInitializer) {
          foundIndex = i;
          arguments = initializer.arguments;
          break;
        } else if (initializer is RedirectingInitializer) {
          foundIndex = i;
          arguments = initializer.arguments;
          break;
        }
      }
      if (foundIndex == -1) return;

      // Rewrite using variables if using named parameters (so we can sort them)
      // (note that with 1 named it cannot be unsorted so we don't bother)
      if (arguments.named.length < 2) return;

      int argumentCount = arguments.positional.length + arguments.named.length;

      // Make room for [argumentCount] [LocalInitializer]s before the
      // super/redirector call.
      initializers.length += argumentCount;
      initializers.setRange(
          foundIndex + argumentCount, // destination start (inclusive)
          initializers.length, // destination end (exclusive)
          initializers, // source list
          foundIndex); // source start index

      // Fill in the [argumentCount] reserved slots with the evaluation
      // expressions of the arguments to the super/redirector constructor call
      int storeIndex = foundIndex;
      for (int i = 0; i < arguments.positional.length; ++i) {
        var variable =
            new VariableDeclaration.forValue(arguments.positional[i]);
        arguments.positional[i] = new VariableGet(variable)..parent = arguments;
        initializers[storeIndex++] = new LocalInitializer(variable)
          ..parent = constructor;
      }
      for (int i = 0; i < arguments.named.length; ++i) {
        NamedExpression argument = arguments.named[i];
        var variable = new VariableDeclaration.forValue(argument.value);
        arguments.named[i].value = new VariableGet(variable)..parent = argument;
        initializers[storeIndex++] = new LocalInitializer(variable)
          ..parent = constructor;
      }

      // Sort the named arguments
      arguments.named.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// Move body of constructor to new one and call that from this one.
  ///
  /// More specifically: For all constructors with optional positional
  /// parameters, or named parameters, create a new constructor without optional
  /// positional parameters and named parameters, and move the body of the
  /// original constructor into this new constructor.
  /// Then make the original constructor redirect to the new constructor.
  ///
  /// The idea is that all rewrites should call the moved constructor instead,
  /// bypassing the optional/named arguments entirely.
  ///
  /// This method is very similar to _moveAndTransformProcedure
  void _moveAndTransformConstructor(Constructor constructor) {
    if (_isNotExternal(constructor) &&
        _hasAnyOptionalParameters(constructor.function)) {
      final function = constructor.function;

      // Create variable lists
      final newParameterDeclarations = <VariableDeclaration>[];
      final newNamedParameterDeclarations = <VariableDeclaration>[];
      final newParameterVariableGets = <Expression>[];
      final targetParameters = function.positionalParameters;
      final targetNamedParameters = function.namedParameters;
      _moveVariableInitialization(
          targetParameters,
          targetNamedParameters,
          newParameterDeclarations,
          newNamedParameterDeclarations,
          newParameterVariableGets,
          constructor.function);

      // Create new constructor looking like the old one
      // (with the old body, parameters and initializers)
      FunctionNode functionNode = _createShallowFunctionCopy(function);
      final newConstructor = new Constructor(functionNode,
          name: _createOriginalName(constructor),
          isConst: constructor.isConst,
          isExternal: constructor.isExternal,
          initializers: constructor.initializers);

      // Add constructor to the code
      _addMember(constructor, newConstructor);

      // Map moved body
      _movedConstructors[constructor] = newConstructor;

      // Transform original constructor
      constructor.function.body = null;
      constructor.function.positionalParameters = newParameterDeclarations;
      constructor.function.namedParameters = newNamedParameterDeclarations;
      constructor.initializers = [
        new RedirectingInitializer(
            newConstructor, new Arguments(newParameterVariableGets))
          ..parent = constructor
      ];

      if (_debug) {
        // Debug flag set: Print something to the terminal before returning to
        // easily detect if rewrites are missing.
        Expression debugPrint = _getPrintExpression(
            "DEBUG! Constructor shouldn't have been called...", constructor);
        var variable = new VariableDeclaration.forValue(debugPrint);
        final debugInitializer = new LocalInitializer(variable)
          ..parent = constructor;
        final redirector = constructor.initializers[0];
        constructor.initializers = [debugInitializer, redirector];
      }

      // Mark original procedure as seen (i.e. don't transform it further)
      _visited.add(constructor);
    }
  }

  /// Creates a new [FunctionNode] based on the given one.
  ///
  /// Parameters are taken directly (i.e. after returning the parameters will
  /// have a new parent (the returned value), but still be referenced in the
  /// original [FunctionNode].
  /// The same goes for the body of the function.
  /// The caller should take steps to remedy this after this call.
  ///
  /// The parameters are no longer optional and named parameters have been
  /// sorted and turned into regular parameters in the returned [FunctionNode].
  FunctionNode _createShallowFunctionCopy(FunctionNode function) {
    final newParameters =
        new List<VariableDeclaration>.from(function.positionalParameters);
    final named = new List<VariableDeclaration>.from(function.namedParameters);
    named.sort((a, b) => a.name.compareTo(b.name));
    newParameters.addAll(named);
    final functionNode = new FunctionNode(function.body,
        positionalParameters: newParameters,
        namedParameters: [],
        requiredParameterCount: newParameters.length,
        returnType: function.returnType,
        asyncMarker: function.asyncMarker,
        dartAsyncMarker: function.dartAsyncMarker);
    return functionNode;
  }

  /// Creates new variables, moving old initializers into them
  ///
  /// Specifically: Given lists for output, create new variables based on
  /// original parameters. Any new variable will receive the original variables
  /// initializer, and the original variable will have its initializer set to
  /// null.
  /// Named parameters have been sorted in [newParameterVariableGets].
  void _moveVariableInitialization(
      List<VariableDeclaration> originalParameters,
      List<VariableDeclaration> originalNamedParameters,
      List<VariableDeclaration> newParameterDeclarations,
      List<VariableDeclaration> newNamedParameterDeclarations,
      List<Expression> newParameterVariableGets,
      TreeNode newStuffParent) {
    for (final orgVar in originalParameters) {
      final variableDeclaration = new VariableDeclaration(orgVar.name,
          initializer: orgVar.initializer,
          type: orgVar.type,
          isFinal: orgVar.isFinal,
          isConst: orgVar.isConst)
        ..parent = newStuffParent;
      variableDeclaration.initializer?.parent = variableDeclaration;
      newParameterDeclarations.add(variableDeclaration);
      orgVar.initializer = null;
      newParameterVariableGets.add(new VariableGet(variableDeclaration));
    }

    // Named expressions in newParameterVariableGets should be sorted
    final tmp = new List<_Pair<String, Expression>>();
    for (final orgVar in originalNamedParameters) {
      final variableDeclaration = new VariableDeclaration(orgVar.name,
          initializer: orgVar.initializer,
          type: orgVar.type,
          isFinal: orgVar.isFinal,
          isConst: orgVar.isConst)
        ..parent = newStuffParent;
      variableDeclaration.initializer?.parent = variableDeclaration;
      newNamedParameterDeclarations.add(variableDeclaration);
      orgVar.initializer = null;
      tmp.add(new _Pair(orgVar.name, new VariableGet(variableDeclaration)));
    }
    tmp.sort((a, b) => a.key.compareTo(b.key));
    for (final item in tmp) {
      newParameterVariableGets.add(item.value);
    }
  }

  /// Creates a stub redirecting to noSuchMethod.
  ///
  /// Needed because if B extends A, both have a foo method, but taking
  /// different optional parameters, a call on an instance of B with parameters
  /// for A should actually result in a noSuchMethod call, but if only A has
  /// the rewritten method name, that method will be called...
  /// TODO: We only have to create these stubs for arguments that a procedures
  /// super allows, otherwise it will become a noSuchMethod automatically!
  Procedure _createNoSuchMethodStub(
      String argumentsSignature,
      int positionalCount,
      List<String> givenNamedParameters,
      Procedure existing) {
    // Build parameter lists
    final newParameterDeclarations = <VariableDeclaration>[];
    final newParameterVariableGets = <Expression>[];
    for (int i = 0; i < positionalCount + givenNamedParameters.length; i++) {
      final variableDeclaration = new VariableDeclaration("v%$i");
      newParameterDeclarations.add(variableDeclaration);
      newParameterVariableGets.add(new VariableGet(variableDeclaration));
    }

    var procedureName = _createName(existing.name, argumentsSignature);

    // Find noSuchMethod to call
    Member noSuchMethod = hierarchy.getDispatchTarget(
        existing.enclosingClass, new Name("noSuchMethod"));
    Arguments argumentsToNoSuchMethod;

    if (noSuchMethod.function.positionalParameters.length == 1 &&
        noSuchMethod.function.namedParameters.isEmpty) {
      // We have a correct noSuchMethod method.
      ConstructorInvocation invocation = _createInvocation(
          procedureName.name, new Arguments(newParameterVariableGets));
      argumentsToNoSuchMethod = new Arguments([invocation]);
    } else {
      // Get noSuchMethod on Object then...
      noSuchMethod = hierarchy.getDispatchTarget(
          coreTypes.objectClass, new Name("noSuchMethod"));
      ConstructorInvocation invocation = _createInvocation(
          procedureName.name, new Arguments(newParameterVariableGets));
      ConstructorInvocation invocationPrime =
          _createInvocation("noSuchMethod", new Arguments([invocation]));
      argumentsToNoSuchMethod = new Arguments([invocationPrime]);
    }

    // Create return statement to call noSuchMethod
    ReturnStatement statement;
    final expression = new DirectMethodInvocation(
        new ThisExpression(), noSuchMethod, argumentsToNoSuchMethod);
    statement = new ReturnStatement(expression);

    // Build procedure
    final functionNode = new FunctionNode(statement,
        positionalParameters: newParameterDeclarations,
        namedParameters: [],
        requiredParameterCount: newParameterDeclarations.length,
        returnType: existing.function.returnType,
        asyncMarker: existing.function.asyncMarker,
        dartAsyncMarker: existing.function.dartAsyncMarker);
    final procedure = new Procedure(
        procedureName, ProcedureKind.Method, functionNode,
        isStatic: existing.isStatic, fileUri: existing.fileUri);

    // Add procedure to the code
    _addMember(existing, procedure);

    // Mark the new procedure as visited already (i.e. don't rewrite it again!)
    _visited.add(procedure);

    return procedure;
  }

  /// Creates an "new _InvocationMirror(...)" invocation.
  ConstructorInvocation _createInvocation(
      String methodName, Arguments callArguments) {
    if (_invocationMirrorConstructor == null) {
      Class clazz = coreTypes.invocationMirrorClass;
      _invocationMirrorConstructor = clazz.constructors[0];
    }

    // The _InvocationMirror constructor takes the following arguments:
    // * Method name (a string).
    // * An arguments descriptor - a list consisting of:
    //   - number of arguments (including receiver).
    //   - number of positional arguments (including receiver).
    //   - pairs (2 entries in the list) of
    //     * named arguments name.
    //     * index of named argument in arguments list.
    // * A list of arguments, where the first ones are the positional arguments.
    // * Whether it's a super invocation or not.

    int numPositionalArguments = callArguments.positional.length + 1;
    int numArguments = numPositionalArguments + callArguments.named.length;
    List<Expression> argumentsDescriptor = [
      new IntLiteral(numArguments),
      new IntLiteral(numPositionalArguments)
    ];
    List<Expression> arguments = [];
    arguments.add(new ThisExpression());
    for (Expression pos in callArguments.positional) {
      arguments.add(pos);
    }
    for (NamedExpression named in callArguments.named) {
      argumentsDescriptor.add(new StringLiteral(named.name));
      argumentsDescriptor.add(new IntLiteral(arguments.length));
      arguments.add(named.value);
    }

    return new ConstructorInvocation(
        _invocationMirrorConstructor,
        new Arguments([
          new StringLiteral(methodName),
          _fixedLengthList(argumentsDescriptor),
          _fixedLengthList(arguments),
          new BoolLiteral(false)
        ]));
  }

  /// Create a fixed length list containing given expressions.
  Expression _fixedLengthList(List<Expression> list) {
    _listFrom ??= coreTypes.listFromConstructor;
    return new StaticInvocation(
        _listFrom,
        new Arguments([new ListLiteral(list)],
            named: [new NamedExpression("growable", new BoolLiteral(false))],
            types: [const DynamicType()]));
  }

  /// Creates a new procedure taking given arguments, caching it.
  ///
  /// Copies any non-given default values for parameters into the new procedure
  /// to be able to call the [realTarget] without using optionals and named
  /// parameters.
  Procedure _createAndCacheInvocationProcedure(
      String argumentsSignature,
      int positionalCount,
      List<String> givenNamedParameters,
      Procedure target,
      Procedure realTarget,
      Map<String, Procedure> createdProcedures,
      bool doSpecialCaseForAllParameters) {
    // Special case: Calling with all parameters
    if (doSpecialCaseForAllParameters &&
        positionalCount == target.function.positionalParameters.length &&
        givenNamedParameters.length == target.function.namedParameters.length) {
      // We don't cache this procedure as this could make it look like
      // something with name argumentsSignature actually exists
      // while it doesn't (which is bad as we could then decide that we don't
      // need to create a stub even though we do!)
      return realTarget;
    }

    // Create and cache (save) constructor

    // Build parameter lists
    final newParameterDeclarations = <VariableDeclaration>[];
    final newParameterVariableGets = <Expression>[];
    _extractAndCreateParameters(positionalCount, newParameterDeclarations,
        newParameterVariableGets, target, givenNamedParameters);

    // Create return statement to call real target
    ReturnStatement statement;
    if (target.isAbstract && target.function?.body == null) {
      // statement should just be null then
    } else if (target.isStatic) {
      final expression = new StaticInvocation(
          realTarget, new Arguments(newParameterVariableGets));
      statement = new ReturnStatement(expression);
    } else {
      final expression = new DirectMethodInvocation(new ThisExpression(),
          realTarget, new Arguments(newParameterVariableGets));
      statement = new ReturnStatement(expression);
    }

    // Build procedure
    final functionNode = new FunctionNode(statement,
        positionalParameters: newParameterDeclarations,
        namedParameters: [],
        requiredParameterCount: newParameterDeclarations.length,
        returnType: target.function.returnType,
        asyncMarker: target.function.asyncMarker,
        dartAsyncMarker: target.function.dartAsyncMarker);
    final procedure = new Procedure(
        _createName(target.name, argumentsSignature),
        ProcedureKind.Method,
        functionNode,
        isAbstract: target.isAbstract,
        isStatic: target.isStatic,
        isConst: target.isConst,
        fileUri: target.fileUri);

    // Add procedure to the code
    _addMember(target, procedure);

    // Cache it for future reference
    createdProcedures[argumentsSignature] = procedure;

    // Mark the new procedure as visited already (i.e. don't rewrite it again!)
    _visited.add(procedure);

    return procedure;
  }

  /// Creates a new constructor taking given arguments, caching it.
  ///
  /// Copies any non-given default values for parameters into the new
  /// constructor to be able to call the [realTarget] without using optionals
  /// and named parameters.
  Constructor _createAndCacheInvocationConstructor(
      String argumentsSignature,
      int positionalCount,
      List<String> givenNamedParameters,
      Constructor target,
      Constructor realTarget,
      Map<String, Constructor> createdConstructor,
      bool doSpecialCaseForAllParameters) {
    // Special case: Calling with all parameters
    if (doSpecialCaseForAllParameters &&
        positionalCount == target.function.positionalParameters.length &&
        givenNamedParameters.length == target.function.namedParameters.length) {
      createdConstructor[argumentsSignature] = realTarget;
      return realTarget;
    }

    // Create and cache (save) constructor

    // Build parameter lists
    final newParameterDeclarations = <VariableDeclaration>[];
    final newParameterVariableGets = <Expression>[];
    _extractAndCreateParameters(positionalCount, newParameterDeclarations,
        newParameterVariableGets, target, givenNamedParameters);

    // Build constructor
    final functionNode = new FunctionNode(null,
        positionalParameters: newParameterDeclarations,
        namedParameters: [],
        requiredParameterCount: newParameterDeclarations.length,
        returnType: target.function.returnType,
        asyncMarker: target.function.asyncMarker,
        dartAsyncMarker: target.function.dartAsyncMarker);
    final constructor = new Constructor(functionNode,
        name: _createName(target.name, argumentsSignature),
        isConst: target.isConst,
        isExternal: target.isExternal,
        initializers: [
          new RedirectingInitializer(
              realTarget, new Arguments(newParameterVariableGets))
        ]);

    // Add procedure to the code
    _addMember(target, constructor);

    // Cache it for future reference
    createdConstructor[argumentsSignature] = constructor;

    // Mark the new procedure as visited already (i.e. don't rewrite it again!)
    _visited.add(constructor);

    return constructor;
  }

  /// Extracts and creates parameters into the first two given lists.
  ///
  /// What is done:
  /// Step 1: Re-create the parameters given (i.e. the non-optional positional
  /// ones) - i.e. create a new variable with the same name etc, put it in
  /// [newParameterDeclarations]; create VariableGet for that and put it in
  /// [newParameterVariableGets]
  /// Step 2: Re-create the positional parameters NOT given, i.e. insert
  /// defaults and add to [newParameterVariableGets] only.
  /// Step 3: Re-create the named arguments (in sorted order). For actually
  /// given named parameters, do as in step 1, for not-given named parameters
  /// do as in step 2.
  ///
  /// NOTE: [newParameterDeclarations] and [newParameterVariableGets] are OUTPUT
  /// lists.
  void _extractAndCreateParameters(
      int positionalCount,
      List<VariableDeclaration> newParameterDeclarations,
      List<Expression> newParameterVariableGets,
      Member target,
      List<String> givenNamedParameters) {
    // First re-create the parameters given (i.e. the non-optional positional ones)
    final targetParameters = target.function.positionalParameters;
    positionalCount = math.min(positionalCount, targetParameters.length);
    for (int i = 0; i < positionalCount; i++) {
      final orgVar = targetParameters[i];
      final variableDeclaration = new VariableDeclaration(orgVar.name,
          type: orgVar.type, isFinal: orgVar.isFinal, isConst: orgVar.isConst);
      newParameterDeclarations.add(variableDeclaration);
      newParameterVariableGets.add(new VariableGet(variableDeclaration));
    }

    // Default parameters for the rest of them
    _fillInPositionalParameters(
        positionalCount, target, newParameterVariableGets);

    // Then all named parameters (given here or not)
    final orgNamed =
        new List<VariableDeclaration>.from(target.function.namedParameters);
    orgNamed.sort((a, b) => a.name.compareTo(b.name));
    final givenArgumentsIterator = givenNamedParameters.iterator;
    givenArgumentsIterator.moveNext();
    for (VariableDeclaration named in orgNamed) {
      if (givenArgumentsIterator.current == named.name) {
        // We have that one: Use it and move the iterator
        final variableDeclaration = new VariableDeclaration(named.name);
        newParameterDeclarations.add(variableDeclaration);
        newParameterVariableGets.add(new VariableGet(variableDeclaration));
        givenArgumentsIterator.moveNext();
      } else {
        // We don't have that one: Fill it in
        _fillInSingleParameter(named, newParameterVariableGets, target);
      }
    }
  }

  /// Adds the new member the same place as the existing member
  void _addMember(Member existingMember, Member newMember) {
    if (existingMember.enclosingClass != null) {
      existingMember.enclosingClass.addMember(newMember);
    } else {
      existingMember.enclosingLibrary.addMember(newMember);
    }
  }

  /// Create expressions based on the default values from the given [Member].
  ///
  /// More specifically: static gets and nulls will be "copied" whereas other
  /// things (e.g. literals or things like "a+b") will be moved from the
  /// original member as argument initializers to const fields and both the
  /// original member and the expression-copy will use static gets to these.
  void _fillInPositionalParameters(
      int startFrom, Member copyFrom, List<Expression> fillInto) {
    final targetParameters = copyFrom.function.positionalParameters;
    for (int i = startFrom; i < targetParameters.length; i++) {
      final parameter = targetParameters[i];
      _fillInSingleParameter(parameter, fillInto, copyFrom);
    }
  }

  /// Create expression based on the default values from the given variable.
  ///
  /// More specifically: a static get or null will be "copied" whereas other
  /// things (e.g. literals or things like "a+b") will be moved from the
  /// original member as an argument initializer to a const field and both the
  /// original member and the expression-copy will use a static get to it.
  void _fillInSingleParameter(VariableDeclaration parameter,
      List<Expression> fillInto, Member copyFrom) {
    if (parameter.initializer is StaticGet) {
      // Reference to const => recreate it
      StaticGet staticGet = parameter.initializer;
      fillInto.add(new StaticGet(staticGet.target));
    } else if (parameter.initializer == null) {
      // No default given => output null
      fillInto.add(new NullLiteral());
    } else if (parameter.initializer is IntLiteral) {
      // Int literal => recreate (or else class ByteBuffer in typed_data will
      // get 2 fields and the C++ code will complain!)
      IntLiteral value = parameter.initializer;
      fillInto.add(new IntLiteral(value.value));
    } else {
      // Advanced stuff => move to static const field and reference that
      final initializer = parameter.initializer;
      final f = new Field(
          new Name('${copyFrom.name.name}%_${parameter.name}',
              copyFrom.enclosingLibrary),
          type: parameter.type,
          initializer: initializer,
          isFinal: false,
          isConst: true,
          isStatic: true,
          fileUri: copyFrom.enclosingClass?.fileUri ??
              copyFrom.enclosingLibrary.fileUri);
      initializer.parent = f;

      // Add field to the code
      if (copyFrom.enclosingClass != null) {
        copyFrom.enclosingClass.addMember(f);
      } else {
        copyFrom.enclosingLibrary.addMember(f);
      }

      // Use it at the call site
      fillInto.add(new StaticGet(f));

      // Now replace the initializer in the method to a StaticGet
      parameter.initializer = new StaticGet(f)..parent = parameter;
    }
  }

  /// Create an "original name" for a member.
  ///
  /// Specifically, for a member "x" just returns "x%original";
  Name _createOriginalName(Member member) {
    return new Name("${member.name.name}%original", member.enclosingLibrary);
  }

  /// Create a [Name] based on current name and argument signature.
  Name _createName(Name name, String argumentsSignature) {
    String nameString = '${name.name}%$argumentsSignature';
    return new Name(nameString, name.library);
  }

  /// Is the procedure a method?
  bool _isMethod(Procedure procedure) => procedure.kind == ProcedureKind.Method;

  /// Is the procedure NOT marked as external?
  bool _isNotExternal(Constructor constructor) => !constructor.isExternal;

  /// Does the target function have any optional arguments? (positional/named)
  bool _hasAnyOptionalParameters(FunctionNode targetFunction) =>
      _hasOptionalParameters(targetFunction) ||
      _hasNamedParameters(targetFunction);

  /// Does the target function have optional positional arguments?
  bool _hasOptionalParameters(FunctionNode targetFunction) =>
      targetFunction.positionalParameters.length >
      targetFunction.requiredParameterCount;

  /// Does the target function have named parameters?
  bool _hasNamedParameters(FunctionNode targetFunction) =>
      targetFunction.namedParameters.isNotEmpty;

  bool _callIsLegal(FunctionNode targetFunction, Arguments arguments) {
    if ((targetFunction.requiredParameterCount > arguments.positional.length) ||
        (targetFunction.positionalParameters.length <
            arguments.positional.length)) {
      // Given too few or too many positional arguments
      return false;
    }

    // Do we give named that we don't take?
    Set<String> givenNamed = arguments.named.map((v) => v.name).toSet();
    Set<String> takenNamed =
        targetFunction.namedParameters.map((v) => v.name).toSet();
    givenNamed.removeAll(takenNamed);
    return givenNamed.isEmpty;
  }

  // Below methods used to add debug prints etc

  Library _getDartCoreLibrary(Component component) {
    if (component == null) return null;
    return component.libraries.firstWhere((lib) =>
        lib.importUri.scheme == 'dart' && lib.importUri.path == 'core');
  }

  Procedure _getProcedureInLib(Library lib, String name) {
    if (lib == null) return null;
    return lib.procedures
        .firstWhere((procedure) => procedure.name.name == name);
  }

  Procedure _getProcedureInClassInLib(
      Library lib, String className, String procedureName) {
    if (lib == null) return null;
    Class clazz = lib.classes.firstWhere((clazz) => clazz.name == className);
    return clazz.procedures
        .firstWhere((procedure) => procedure.name.name == procedureName);
  }

  Expression _getPrintExpression(String msg, TreeNode treeNode) {
    TreeNode component = treeNode;
    while (component is! Component) component = component.parent;
    var finalMsg = msg;
    if (treeNode is Member) {
      finalMsg += " [ ${treeNode.name.name} ]";
      if (treeNode.enclosingClass != null) {
        finalMsg += " [ class ${treeNode.enclosingClass.name} ]";
      }
      if (treeNode.enclosingLibrary != null) {
        finalMsg += " [ lib ${treeNode.enclosingLibrary.name} ]";
      }
    }

    var stacktrace = new StaticGet(_getProcedureInClassInLib(
        _getDartCoreLibrary(component), 'StackTrace', 'current'));
    var printStackTrace = new StaticInvocation(
        _getProcedureInLib(_getDartCoreLibrary(component), 'print'),
        new Arguments([
          new StringConcatenation([
            new StringLiteral(finalMsg),
            new StringLiteral("\n"),
            stacktrace,
            new StringLiteral("\n")
          ])
        ]));

    return printStackTrace;
  }
}

class _Pair<K, V> {
  final K key;
  final V value;

  _Pair(this.key, this.value);
}
