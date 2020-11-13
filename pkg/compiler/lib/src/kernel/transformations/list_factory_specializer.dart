// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/clone.dart' show CloneVisitorNotMembers;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'factory_specializer.dart';

/// Replaces invocation of List factory constructors.
///
/// Expands `List.generate` to a loop when the function argument is a function
/// expression (immediate closure).
///
class ListFactorySpecializer extends BaseSpecializer {
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;

  final Class _intClass;
  final Class _jsArrayClass;
  final Procedure _listGenerateFactory;
  final Procedure _arrayAllocateFixedFactory;
  final Procedure _arrayAllocateGrowableFactory;

  ListFactorySpecializer(this.coreTypes, this.hierarchy)
      : _listGenerateFactory =
            coreTypes.index.getMember('dart:core', 'List', 'generate'),
        _arrayAllocateFixedFactory = coreTypes.index
            .getMember('dart:_interceptors', 'JSArray', 'allocateFixed'),
        _arrayAllocateGrowableFactory = coreTypes.index
            .getMember('dart:_interceptors', 'JSArray', 'allocateGrowable'),
        _jsArrayClass =
            coreTypes.index.getClass('dart:_interceptors', 'JSArray'),
        _intClass = coreTypes.index.getClass('dart:core', 'int') {
    assert(_listGenerateFactory.isFactory);
    assert(_arrayAllocateGrowableFactory.isFactory);
    assert(_arrayAllocateFixedFactory.isFactory);
    transformers.addAll({
      _listGenerateFactory: transformListGenerateFactory,
    });
  }

  Member _intPlus;
  Member get intPlus =>
      _intPlus ??= hierarchy.getInterfaceMember(_intClass, Name('+'));

  Member _intLess;
  Member get intLess =>
      _intLess ??= hierarchy.getInterfaceMember(_intClass, Name('<'));

  Member _jsArrayIndexSet;
  Member get jsArrayIndexSet => _jsArrayIndexSet ??=
      hierarchy.getInterfaceMember(_jsArrayClass, Name('[]='));

  /// Replace calls to `List.generate(length, (i) => e)` with an expansion
  ///
  ///     BlockExpression
  ///       Block
  ///         var _length = <length>;
  ///         var _list = List.allocate(_length);
  ///         for (var _i = 0; _i < _length; _i++) {
  ///           _list[_i] = e;
  ///         }
  ///       => _list
  ///
  /// Declines to expand if:
  ///  - the function argument is not a simple closure,
  ///  - the `growable:` argument cannot be determined.
  TreeNode transformListGenerateFactory(
      StaticInvocation node, Member contextMember) {
    final args = node.arguments;
    assert(args.positional.length == 2);
    final length = args.positional[0];
    final generator = args.positional[1];
    final bool growable =
        _getConstantNamedOptionalArgument(args, 'growable', true);
    if (growable == null) return node;

    if (generator is! FunctionExpression) return node;

    if (!ListGenerateLoopBodyInliner.suitableFunctionExpression(generator)) {
      return node;
    }

    final intType = contextMember.isNonNullableByDefault
        ? coreTypes.intLegacyRawType
        : coreTypes.intNonNullableRawType;

    // If the length is a constant, use the constant directly so that the
    // inferrer can see the constant length.
    int /*?*/ lengthConstant = _getLengthArgument(args);
    VariableDeclaration lengthVariable;

    Expression getLength() {
      if (lengthConstant != null) return IntLiteral(lengthConstant);
      lengthVariable ??= VariableDeclaration('_length',
          initializer: length, isFinal: true, type: intType)
        ..fileOffset = node.fileOffset;
      return VariableGet(lengthVariable)..fileOffset = node.fileOffset;
    }

    TreeNode allocation = StaticInvocation(
        growable ? _arrayAllocateGrowableFactory : _arrayAllocateFixedFactory,
        Arguments(
          [getLength()],
          types: args.types,
        ))
      ..fileOffset = node.fileOffset;

    final listVariable = VariableDeclaration(
      _listNameFromContext(node),
      initializer: allocation,
      isFinal: true,
      type: InterfaceType(
          _jsArrayClass, Nullability.nonNullable, [...args.types]),
    )..fileOffset = node.fileOffset;

    final indexVariable = VariableDeclaration(
      _indexNameFromContext(generator),
      initializer: IntLiteral(0),
      type: intType,
    )..fileOffset = node.fileOffset;
    indexVariable.fileOffset = (generator as FunctionExpression)
        .function
        .positionalParameters
        .first
        .fileOffset;

    final loop = ForStatement(
      // initializers: _i = 0
      [indexVariable],
      // condition: _i < _length
      MethodInvocation(
        VariableGet(indexVariable)..fileOffset = node.fileOffset,
        Name('<'),
        Arguments([getLength()]),
      )..interfaceTarget = intLess,
      // updates: _i++
      [
        VariableSet(
          indexVariable,
          MethodInvocation(
            VariableGet(indexVariable)..fileOffset = node.fileOffset,
            Name('+'),
            Arguments([IntLiteral(1)]),
          )..interfaceTarget = intPlus,
        )..fileOffset = node.fileOffset,
      ],
      // body, e.g. _list[_i] = expression;
      _loopBody(node.fileOffset, listVariable, indexVariable, generator),
    )..fileOffset = node.fileOffset;

    return BlockExpression(
      Block([
        if (lengthVariable != null) lengthVariable,
        listVariable,
        loop,
      ]),
      VariableGet(listVariable)..fileOffset = node.fileOffset,
    );
  }

  Statement _loopBody(
      int constructorFileOffset,
      VariableDeclaration listVariable,
      VariableDeclaration indexVariable,
      FunctionExpression generator) {
    final inliner = ListGenerateLoopBodyInliner(
        this, constructorFileOffset, listVariable, generator.function);
    inliner.bind(indexVariable);
    return inliner.run();
  }

  /// Returns constant value of the first argument in [args], or null if it is
  /// not a constant.
  int /*?*/ _getLengthArgument(Arguments args) {
    if (args.positional.length < 1) return null;
    final value = args.positional.first;
    if (value is IntLiteral) {
      return value.value;
    } else if (value is ConstantExpression) {
      final constant = value.constant;
      if (constant is IntConstant) {
        return constant.value;
      }
    }
    return null;
  }

  /// Returns constant value of the only named optional argument in [args], or
  /// null if it is not a bool constant. Returns [defaultValue] if optional
  /// argument is not passed. Argument is asserted to have the given [name].
  bool /*?*/ _getConstantNamedOptionalArgument(
      Arguments args, String name, bool defaultValue) {
    if (args.named.isEmpty) {
      return defaultValue;
    }
    final namedArg = args.named.single;
    assert(namedArg.name == name);
    final value = namedArg.value;
    if (value is BoolLiteral) {
      return value.value;
    } else if (value is ConstantExpression) {
      final constant = value.constant;
      if (constant is BoolConstant) {
        return constant.value;
      }
    }
    return null;
  }

  /// Choose a name for the `_list` temporary. If the `List.generate` expression
  /// is an initializer for a variable, use that name so that dart2js can try to
  /// use one JavaScript variable with the source name for 'both' variables.
  String _listNameFromContext(Expression node) {
    TreeNode parent = node.parent;
    if (parent is VariableDeclaration) return parent.name;
    return '_list';
  }

  String _indexNameFromContext(FunctionExpression generator) {
    final function = generator.function;
    String /*?*/ candidate = function.positionalParameters.first.name;
    if (candidate == null || candidate == '' || candidate == '_') return '_i';
    return candidate;
  }
}

/// Inliner for function expressions of `List.generate` calls.
class ListGenerateLoopBodyInliner extends CloneVisitorNotMembers {
  final ListFactorySpecializer listFactorySpecializer;

  /// Offset for the constructor call, used for all nodes that carry the value of the list.
  final int constructorFileOffset;
  final VariableDeclaration listVariable;
  final FunctionNode function;
  VariableDeclaration argument;
  VariableDeclaration parameter;
  int functionNestingLevel = 0;

  ListGenerateLoopBodyInliner(this.listFactorySpecializer,
      this.constructorFileOffset, this.listVariable, this.function);

  static bool suitableFunctionExpression(FunctionExpression node) {
    final function = node.function;
    // These conditions should be satisfied by language rules.
    if (function.typeParameters.isNotEmpty) return false;
    if (function.requiredParameterCount != 1) return false;
    if (function.positionalParameters.length != 1) return false;
    if (function.namedParameters.isNotEmpty) return false;

    final body = function.body;

    // Arrow functions.
    if (body is ReturnStatement) return true;

    if (body is Block) {
      // Simple body containing just a return.
      final statements = body.statements;
      if (statements.length == 1 && statements.single is ReturnStatement) {
        return true;
      }

      // TODO(sra): We can accept more complex closures but, with diminishing
      // returns. It would probably be best to handle more complex cases by
      // improving environment design and inlining.
    }

    return false;
  }

  void bind(VariableDeclaration argument) {
    // The [argument] is the loop index variable. In the general case this needs
    // to be copied to a variable for the closure parameter as that is a
    // separate location that may be mutated.  In the usual case the closure
    // parameter is not modified. We use the same name for the parameter and
    // argument to help dart2js allocate both locations to the same JavaScript
    // variable. The argument is usually named after the closure parameter.
    final closureParameter = function.positionalParameters.single;
    parameter = VariableDeclaration(argument.name,
        initializer: VariableGet(argument)..fileOffset = argument.fileOffset,
        type: closureParameter.type)
      ..fileOffset = closureParameter.fileOffset;
    this.argument = argument;
    variables[closureParameter] = parameter;
  }

  Statement run() {
    final body = cloneInContext(function.body);
    return Block([parameter, body]);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    // Do the default for return statements in nested functions.
    if (functionNestingLevel > 0) return super.visitReturnStatement(node);

    // We don't use a variable for the returned value. In the simple case it is
    // not necessary, and it is not clear that the rules for definite assignment
    // are not a perfect match for the locations of return statements. Instead
    // we expand
    //
    //     return expression;
    //
    // to
    //
    //     list[index] = expression;
    //
    // TODO(sra): Currently this inliner accepts only arrow functions (a single
    // return). If a wider variety is accepted, we might need to break after the
    // assignment to 'exit' the inlined code.

    final expression = node.expression;
    final value = expression == null ? NullLiteral() : clone(expression);
    // TODO(sra): Indicate that this indexed setter is safe.
    return ExpressionStatement(
      MethodInvocation(
        VariableGet(listVariable)..fileOffset = constructorFileOffset,
        Name('[]='),
        Arguments([
          VariableGet(argument)..fileOffset = node.fileOffset,
          value,
        ]),
      )
        ..interfaceTarget = listFactorySpecializer.jsArrayIndexSet
        ..isInvariant = true
        ..isBoundsSafe = true
        ..fileOffset = constructorFileOffset,
    );
  }

  /// Nested functions.
  @override
  visitFunctionNode(FunctionNode node) {
    functionNestingLevel++;
    final cloned = super.visitFunctionNode(node);
    functionNestingLevel--;
    return cloned;
  }

  @override
  visitVariableGet(VariableGet node) {
    // Unmapped variables are from an outer scope.
    var mapped = variables[node.variable] ?? node.variable;
    return VariableGet(mapped, visitOptionalType(node.promotedType))
      ..fileOffset = node.fileOffset;
  }

  @override
  visitVariableSet(VariableSet node) {
    // Unmapped variables are from an outer scope.
    var mapped = variables[node.variable] ?? node.variable;
    return VariableSet(mapped, clone(node.value))..fileOffset = node.fileOffset;
  }
}
