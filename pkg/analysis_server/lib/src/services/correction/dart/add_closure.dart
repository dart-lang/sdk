// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/numeric.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';
import 'package:linter/src/lint_names.dart';

/// A closure parameter to write: its `name`, plus the `element` it's written
/// to match when its type and modifiers should be written too, or `null` when
/// only the name should be.
typedef _Parameter = ({String name, FormalParameterElement? element});

class AddMissingClosureParameters extends ResolvedCorrectionProducer {
  final _Kind _kind;

  @override
  final FixKind fixKind;

  /// The `{0}` argument for [fixKind]:
  ///
  /// - the argument name when [_kind] is `.named`,
  /// - the 1-based ordinal when [_kind] is `.positional`,
  /// - the count of missing parameters when [_kind] is `.parameters`, and
  /// - unused when [_kind] is `.expression`.
  String _fixArgument = '';

  new expression({required super.context})
    : _kind = .expression,
      fixKind = DartFixKind.addClosure;

  new named({required super.context})
    : _kind = .named,
      fixKind = DartFixKind.addClosureNamed;

  new parameters({required super.context})
    : _kind = .parameters,
      fixKind = DartFixKind.addClosureParameters;

  new positional({required super.context})
    : _kind = .positional,
      fixKind = DartFixKind.addClosurePositional;

  @override
  CorrectionApplicability get applicability => .singleLocation;

  @override
  List<String>? get fixArguments =>
      _fixArgument.isEmpty ? null : [_fixArgument];

  /// Whether missing named closure parameters should be written with the
  /// required ones first, based on the
  /// `always_put_required_named_parameters_first` lint.
  bool get _requiredNamedParametersFirst => analysisOptions.isLintEnabled(
    LintNames.always_put_required_named_parameters_first,
  );

  @override
  Future<void> compute(ChangeBuilder builder) async {
    switch (_kind) {
      case .parameters:
        await _computeParameters(builder);
      case .expression:
        await _computeExpression(builder);
      case .named:
        await _computeNamedArgument(builder);
      case .positional:
        await _computePositionalArgument(builder);
    }
  }

  /// Inserts a closure matching [hole]'s expected type in place of the
  /// missing (synthetic) expression [hole].
  ///
  /// A synthetic hole's offset can coincide with the following token (for
  /// example, a ternary's missing `then` branch sits directly against the
  /// `:` that follows it, having absorbed the separating whitespace as that
  /// token's leading trivia), so a trailing space is added when needed to
  /// avoid writing the closure hard up against it.
  Future<void> _addMissingClosureExpression(
    ChangeBuilder builder,
    Expression hole,
  ) async {
    var content = unitResult.content;
    // The end of the file needs no separation, so stand in for it with a
    // character that doesn't either.
    var nextChar = hole.offset < content.length ? content[hole.offset] : ' ';

    await _insertClosure(
      builder,
      _expectedType(hole),
      hole.offset,
      suffix: ' \t\n\r)],;'.contains(nextChar) ? '' : ' ',
    );
  }

  /// Inserts a brand new closure argument, matching the missing callback
  /// parameter's signature, into [argumentList].
  Future<void> _addNewClosureArgument(
    ChangeBuilder builder,
    ArgumentList argumentList,
  ) async {
    // A function expression invocation's callee is often not an element at
    // all (for example, a function-typed parameter), so its parameters come
    // from its invoked type instead.
    var formalParameters = switch (argumentList.parent) {
      FunctionExpressionInvocation(:FunctionType staticInvokeType) =>
        staticInvokeType.formalParameters,
      MethodInvocation(
        methodName: SimpleIdentifier(:ExecutableElement element),
      ) ||
      InstanceCreationExpression(
        constructorName: ConstructorName(:ExecutableElement element),
      ) ||
      DotShorthandInvocation(
        memberName: SimpleIdentifier(:ExecutableElement element),
      ) ||
      DotShorthandConstructorInvocation(
        constructorName: SimpleIdentifier(:ExecutableElement element),
      ) ||
      EnumConstantArguments(
        parent: EnumConstantDeclaration(
          constructorElement: ExecutableElement element,
        ),
      ) ||
      RedirectingConstructorInvocation(:ExecutableElement element) ||
      SuperConstructorInvocation(
        :ExecutableElement element,
      ) => element.formalParameters,
      _ => null,
    };
    if (formalParameters == null) {
      return;
    }

    var arguments = argumentList.arguments;
    var positionalArguments = arguments.whereNotType<NamedArgument>().toList();
    var positionalCount = positionalArguments.length;
    if (positionalCount >= formalParameters.length) {
      return;
    }

    // The closure fills the next positional slot: at the start of the
    // argument list when nothing positional precedes it, otherwise directly
    // after the last positional argument.
    var (offset, prefix, suffix) = switch (positionalArguments.lastOrNull) {
      _ when arguments.isEmpty => (argumentList.leftParenthesis.end, '', ''),
      null => (arguments.first.offset, '', ', '),
      var last => (last.end, ', ', ''),
    };

    var inserted = await _insertClosure(
      builder,
      formalParameters[positionalCount].type,
      offset,
      prefix: prefix,
      suffix: suffix,
    );
    if (inserted) {
      _fixArgument = (positionalCount + 1).toStringWithSuffix();
    }
  }

  /// Inserts the missing positional and named parameters into the existing
  /// closure [closure]'s parameter list, given that [closure] is expected to
  /// match [contextType], returning whether an edit was made.
  Future<bool> _addToExistingClosure(
    ChangeBuilder builder,
    FunctionExpression closure,
    DartType? contextType,
  ) async {
    var functionType = contextType;
    if (functionType is! FunctionType) {
      return false;
    }
    var parameterList = closure.parameters;
    if (parameterList == null) {
      return false;
    }
    var existingParameters = parameterList.parameters;
    var existingPositional = <FormalParameter>[];
    var existingNamedNames = <String>{};
    var usedNames = <String>{};
    for (var parameter in existingParameters) {
      var name = parameter.name?.lexeme;
      if (parameter.isPositional) {
        existingPositional.add(parameter);
      } else if (name != null) {
        existingNamedNames.add(name);
      }
      if (name != null) {
        usedNames.add(name);
      }
    }

    var targetParameters = functionType.formalParameters;
    var positionalTargets = [
      for (var parameter in targetParameters)
        if (parameter.isPositional) parameter,
    ];
    var missingNamed = _namedParameters([
      for (var parameter in targetParameters)
        if (parameter.isNamed && !existingNamedNames.contains(parameter.name))
          parameter,
    ]);

    for (var (i, existing)
        in existingPositional.take(positionalTargets.length).indexed) {
      var declaredType = existing.type?.type;
      if (declaredType == null) {
        continue;
      }
      if (!typeSystem.isAssignableTo(declaredType, positionalTargets[i].type)) {
        return false;
      }
    }

    // Optional positional parameters always follow the required ones, so
    // this claims names in the same order they'll be written in.
    var missingRequired = <_Parameter>[];
    var missingOptional = <_Parameter>[];
    var existingPositionalCount = existingPositional.length;
    for (var (i, target)
        in positionalTargets.skip(existingPositionalCount).indexed) {
      var name = _parameterName(target, existingPositionalCount + i, usedNames);
      var parameter = (name: name, element: null);
      if (target.isOptionalPositional) {
        missingOptional.add(parameter);
      } else {
        missingRequired.add(parameter);
      }
    }

    var missingCount =
        missingRequired.length + missingOptional.length + missingNamed.length;
    if (missingCount == 0) {
      return false;
    }
    _fixArgument = '$missingCount';

    await _writeAdditions(
      builder,
      parameterList,
      missingRequired,
      missingOptional,
      missingNamed,
    );
    return true;
  }

  /// Returns the sub-expressions of [node] that a closure could be written in
  /// place of: a conditional expression's branches, or a switch expression's
  /// case results.
  List<Expression> _branchesOf(AstNode node) => switch (node) {
    ConditionalExpression(:var thenExpression, :var elseExpression) => [
      thenExpression,
      elseExpression,
    ],
    SwitchExpression(:var cases) => [
      for (var switchCase in cases) switchCase.expression,
    ],
    _ => const [],
  };

  /// Returns a [FunctionType] for [type].
  ///
  /// - Returns [type] if [type] is a [FunctionType].
  /// - Returns `dynamic Function()` if [type] is [Function].
  /// - Returns `null` otherwise.
  FunctionType? _closureTypeFor(DartType? type) => switch (type) {
    FunctionType functionType => functionType,
    DartType(isDartCoreFunction: true) => FunctionTypeImpl(
      typeParameters: const [],
      formalParameters: const [],
      returnType: DynamicTypeImpl.instance,
      nullabilitySuffix: .none,
    ),
    _ => null,
  };

  /// Writes a closure in place of an expression that's missing entirely.
  Future<void> _computeExpression(ChangeBuilder builder) async {
    var target = node;
    // A closure that's already written isn't missing; a switch or conditional
    // expression, on the other hand, can be missing a branch entirely.
    if (target is FunctionExpression) return;

    if (target is ReturnStatement) {
      if (target.expression != null) return;
      // Insert a closure matching the enclosing function's return type in
      // place of the missing value of this `return;`.
      await _insertClosure(
        builder,
        target.enclosingExecutableElement?.returnType,
        target.returnKeyword.end,
        prefix: ' ',
      );
      return;
    }

    var diagnosticOffset = diagnostic?.problemMessage.offset;
    if (diagnosticOffset == null) return;
    // The diagnostic's length spans the token that *follows* the missing
    // expression, so [node] (the node covering that whole range) is the
    // enclosing statement or expression rather than the hole itself. A
    // zero-length lookup at the same offset lands on the synthetic
    // expression the parser inserted in the hole, at whatever depth it is.
    var hole = unit.nodeCovering(offset: diagnosticOffset);
    // A named argument's missing value is `.named`'s to fix.
    if (hole is! Expression ||
        !hole.isSynthetic ||
        hole.parent is NamedArgument) {
      return;
    }
    await _addMissingClosureExpression(builder, hole);
  }

  /// Writes a closure in place of a named argument's missing value.
  Future<void> _computeNamedArgument(ChangeBuilder builder) async {
    if (_enclosingArgumentList() case (_, var missingArgument?)) {
      // Insert a closure matching the argument's corresponding parameter's
      // function type in place of its missing expression.
      var inserted = await _insertClosure(
        builder,
        missingArgument.correspondingParameter?.type,
        missingArgument.argumentExpression.offset,
      );
      if (inserted) {
        _fixArgument = "'${missingArgument.name.lexeme}'";
      }
    }
  }

  /// Adds the parameters missing from a closure that's already written.
  Future<void> _computeParameters(ChangeBuilder builder) async {
    // Only a closure that's already written can be missing parameters, and a
    // switch or conditional expression can have one in any of its branches;
    // anything else has no branches to search (see [_branchesOf]) and isn't
    // itself a closure, so the search below is a no-op for it.
    if (node case Expression target) {
      await _fixFirstMismatchedClosure(builder, target);
    }
  }

  /// Writes a brand new closure argument for a missing positional argument.
  Future<void> _computePositionalArgument(ChangeBuilder builder) async {
    // A named argument that's missing its value is `.named`'s to fix, so only
    // an argument list without one is handled here.
    if (_enclosingArgumentList() case (var argumentList, null)) {
      await _addNewClosureArgument(builder, argumentList);
    }
  }

  /// Returns the [ArgumentList] holding the missing argument, paired with the
  /// first argument in it that's named but missing its value (or `null` when
  /// there isn't one), or `null` if [node] isn't in an argument list.
  ///
  /// The `notEnoughPositionalArguments` diagnostic is reported at the token
  /// following the last positional argument. When there is no positional
  /// argument to follow (every existing argument is named), that token falls
  /// inside the first named argument rather than between arguments, so [node]
  /// resolves to a node nested inside the [ArgumentList] rather than the
  /// [ArgumentList] itself.
  (ArgumentList, NamedArgument?)? _enclosingArgumentList() {
    var target = node;
    // Neither a closure that's already written nor a `return` statement is a
    // missing argument, so don't walk out of one into an enclosing call.
    if (target is FunctionExpression || target is ReturnStatement) return null;
    var argumentList = target is ArgumentList
        ? target
        : target.thisOrAncestorOfType<ArgumentList>();
    if (argumentList == null) return null;
    return (
      argumentList,
      argumentList.arguments.whereType<NamedArgument>().firstWhereOrNull(
        (argument) => argument.argumentExpression.isSynthetic,
      ),
    );
  }

  /// Returns the type that a closure written in place of [expression] (or as
  /// [expression] itself, if it's an already-written closure) is expected to
  /// match, based on where [expression] appears: as a call argument, a
  /// variable's initializer, a switch expression case's result, an arrow
  /// function's body, or a `return` statement's value.
  ///
  /// Only the parents that have more than one [Expression] child need to
  /// check which of them [expression] is; for the rest the kind of the parent
  /// alone identifies it.
  DartType? _expectedType(Expression expression) {
    if (expression.correspondingParameter case var parameter?) {
      return parameter.type;
    }
    return switch (expression.parent) {
      // A named argument's parameter hangs off the argument rather than off
      // the expression, so the lookup above doesn't cover this case.
      NamedArgument(:var correspondingParameter) =>
        correspondingParameter?.type,
      VariableDeclaration(parent: VariableDeclarationList(:var type)) =>
        type?.type,
      ExpressionFunctionBody() ||
      ReturnStatement() => expression.enclosingExecutableElement?.returnType,
      SwitchExpressionCase(parent: SwitchExpression switchExpression) =>
        _expectedType(switchExpression),
      AssignmentExpression(:var rightHandSide, :var writeType)
          when rightHandSide == expression =>
        writeType,
      ConditionalExpression conditional
          when conditional.thenExpression == expression ||
              conditional.elseExpression == expression =>
        _expectedType(conditional),
      _ => null,
    };
  }

  /// Applies [_addToExistingClosure] to the first [FunctionExpression]
  /// reachable from [candidate] (which may itself be a closure, or a switch
  /// expression or conditional expression whose cases/branches are searched
  /// recursively, to any depth) that's missing parameters expected to match
  /// its [_expectedType], returning whether an edit was made.
  Future<bool> _fixFirstMismatchedClosure(
    ChangeBuilder builder,
    Expression candidate,
  ) async {
    if (candidate is FunctionExpression) {
      return _addToExistingClosure(
        builder,
        candidate,
        _expectedType(candidate),
      );
    }
    for (var branch in _branchesOf(candidate)) {
      if (await _fixFirstMismatchedClosure(builder, branch)) {
        return true;
      }
    }
    return false;
  }

  /// Inserts a closure matching [type]'s function type at [offset], written
  /// between [prefix] and [suffix], returning whether an edit was made.
  Future<bool> _insertClosure(
    ChangeBuilder builder,
    DartType? type,
    int offset, {
    String prefix = '',
    String suffix = '',
  }) async {
    var functionType = _closureTypeFor(type);
    if (functionType == null) return false;

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(offset, (builder) {
        builder.write(prefix);
        _writeClosure(builder, functionType);
        builder.write(suffix);
      });
    });
    return true;
  }

  /// Returns [parameters], ordered by [_orderNamed], as [_Parameter]s that
  /// carry their element, so a type is written for them when
  /// `always_specify_types` is on.
  List<_Parameter> _namedParameters(List<FormalParameterElement> parameters) =>
      [
        for (var parameter in _orderNamed(parameters))
          (name: parameter.name ?? '', element: parameter),
      ];

  /// Returns [parameters] with the required named ones moved to the front
  /// when [_requiredNamedParametersFirst] is enabled, and unchanged
  /// otherwise.
  List<FormalParameterElement> _orderNamed(
    List<FormalParameterElement> parameters,
  ) {
    if (!_requiredNamedParametersFirst) {
      return parameters;
    }
    return [
      ...parameters.where((parameter) => parameter.isRequiredNamed),
      ...parameters.where((parameter) => !parameter.isRequiredNamed),
    ];
  }

  /// Returns the name to use for a positional closure parameter, preferring
  /// the [parameter]'s declared name, falling back to `p$index`, and
  /// avoiding a collision with any name already in [usedNames] by trying
  /// successive indices. The chosen name is added to [usedNames].
  String _parameterName(
    FormalParameterElement parameter,
    int index,
    Set<String> usedNames,
  ) {
    var declaredName = parameter.name;
    var name = (declaredName != null && declaredName.isNotEmpty)
        ? declaredName
        : 'p$index';
    while (usedNames.contains(name)) {
      index++;
      name = 'p$index';
    }
    usedNames.add(name);
    return name;
  }

  /// Writes [missingRequired], [missingOptional], and [missingNamed] into
  /// [parameterList].
  ///
  /// If [parameterList] already contains an optional-positional or named
  /// parameter, the corresponding missing parameters are merged into that
  /// existing bracketed group rather than being written as a brand new
  /// group. A parameter list has at most one such group, so at most one of
  /// the two kinds can be merged.
  ///
  /// Any remaining missing parameters that don't merge into an existing
  /// group (required positional parameters, and brand new optional or named
  /// groups) are appended at the end of [parameterList]. If [parameterList]
  /// already ends with a trailing comma (before its closing parenthesis),
  /// those additions are written immediately after that comma (preserving
  /// the source's existing trailing-comma formatting). Otherwise, if there
  /// were already existing parameters, the additions are preceded by a
  /// leading comma.
  Future<void> _writeAdditions(
    ChangeBuilder builder,
    FormalParameterList parameterList,
    List<_Parameter> missingRequired,
    List<_Parameter> missingOptional,
    List<_Parameter> missingNamed,
  ) async {
    var existingParameters = parameterList.parameters;
    var delimiterOffset = parameterList.rightDelimiter?.offset;
    // A parameter list has at most one bracketed group, so its delimiter
    // alone says whether that existing group is the named one or the
    // optional-positional one.
    var existingGroupIsNamed =
        parameterList.leftDelimiter?.type == .OPEN_CURLY_BRACKET;

    var mergeOptional =
        delimiterOffset != null &&
        missingOptional.isNotEmpty &&
        !existingGroupIsNamed;
    var mergeNamed =
        delimiterOffset != null &&
        missingNamed.isNotEmpty &&
        existingGroupIsNamed;

    var newOptional = mergeOptional ? const <_Parameter>[] : missingOptional;
    var newNamed = mergeNamed ? const <_Parameter>[] : missingNamed;

    await builder.addDartFileEdit(file, (builder) {
      if (delimiterOffset != null && (mergeOptional || mergeNamed)) {
        builder.addInsertion(delimiterOffset, (builder) {
          for (var parameter
              in mergeOptional ? missingOptional : missingNamed) {
            builder.write(', ');
            _writeParameter(builder, parameter);
          }
        });
      }

      if (missingRequired.isEmpty && newOptional.isEmpty && newNamed.isEmpty) {
        return;
      }

      var rightParenthesis = parameterList.rightParenthesis;
      var previousToken = rightParenthesis.previous;
      var hasTrailingComma =
          previousToken != null &&
          previousToken.type == .COMMA &&
          !previousToken.isSynthetic;
      var insertionOffset = hasTrailingComma
          ? previousToken.end
          : rightParenthesis.offset;
      var leadingSeparator = hasTrailingComma
          ? ' '
          : (existingParameters.isNotEmpty ? ', ' : '');

      builder.addInsertion(insertionOffset, (builder) {
        builder.write(leadingSeparator);
        _writeParameterGroups(
          builder,
          required: missingRequired,
          optionalPositional: newOptional,
          named: newNamed,
        );
      });
    });
  }

  /// Writes a closure (parameter list and empty body) matching
  /// [functionType]'s parameters into [builder].
  void _writeClosure(DartEditBuilder builder, FunctionType functionType) {
    var usedNames = <String>{};
    var required = <_Parameter>[];
    var optionalPositional = <_Parameter>[];
    var named = <FormalParameterElement>[];
    // A function type lists its parameters in the order they're written, so
    // names are claimed here in that same order.
    for (var (index, parameter) in functionType.formalParameters.indexed) {
      if (parameter.isNamed) {
        named.add(parameter);
        continue;
      }
      var positional = (
        name: _parameterName(parameter, index, usedNames),
        element: parameter,
      );
      if (parameter.isOptionalPositional) {
        optionalPositional.add(positional);
      } else {
        required.add(positional);
      }
    }

    builder.write('(');
    _writeParameterGroups(
      builder,
      required: required,
      optionalPositional: optionalPositional,
      named: _namedParameters(named),
    );
    builder.write(') {}');
  }

  /// Writes [parameter] into [builder], writing its type and modifiers along
  /// with its name only when it carries the element they come from.
  void _writeParameter(DartEditBuilder builder, _Parameter parameter) {
    var element = parameter.element;
    if (element == null) {
      builder.write(parameter.name);
      return;
    }
    builder.writeFormalParameter(
      parameter.name,
      isCovariant: element.isCovariant,
      isRequiredNamed: element.isRequiredNamed,
      type: element.type,
      onClosure: true,
    );
  }

  /// Writes `a, b, [c, d], {e, f}` into [builder], omitting each group that
  /// has no parameters along with the separator it would otherwise need.
  void _writeParameterGroups(
    DartEditBuilder builder, {
    List<_Parameter> required = const [],
    List<_Parameter> optionalPositional = const [],
    List<_Parameter> named = const [],
  }) {
    assert(
      optionalPositional.isEmpty || named.isEmpty,
      'A parameter list cannot have both optional-positional and named '
      'parameters.',
    );
    var wroteGroup = false;
    void writeGroup(
      List<_Parameter> parameters, [
      String open = '',
      String close = '',
    ]) {
      if (parameters.isEmpty) {
        return;
      }
      if (wroteGroup) {
        builder.write(', ');
      }
      wroteGroup = true;
      builder.write(open);
      for (var (index, parameter) in parameters.indexed) {
        if (index > 0) {
          builder.write(', ');
        }
        _writeParameter(builder, parameter);
      }
      builder.write(close);
    }

    writeGroup(required);
    writeGroup(optionalPositional, '[', ']');
    writeGroup(named, '{', '}');
  }
}

enum _Kind { named, parameters, positional, expression }
