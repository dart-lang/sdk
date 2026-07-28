// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file declares a "shadow hierarchy" of concrete classes which extend
/// the kernel class hierarchy, adding methods and fields needed by the
/// BodyBuilder.
///
/// Instances of these classes may be created using the factory methods in
/// `ast_factory.dart`.
///
/// Note that these classes represent the Dart language prior to desugaring.
/// When a single Dart construct desugars to a tree containing multiple kernel
/// AST nodes, the shadow class extends the kernel object at the top of the
/// desugared tree.
///
/// This means that in some cases multiple shadow classes may extend the same
/// kernel class, because multiple constructs in Dart may desugar to a tree
/// with the same kind of root node.
///
/// @docImport 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
library;

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/src/text_util.dart';
import 'package:kernel/text/ast_to_text.dart' show Precedence;

import '../base/problems.dart' show unsupported;
import '../builder/declaration_builders.dart';
import '../codes/diagnostic.dart' as diag;
import '../type_inference/element_inference.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor.dart';
import '../type_inference/inference_visitor_base.dart';
import '../type_inference/type_schema.dart';
import 'body_builder.dart';
import 'external_ast_helper.dart' as extern;

part 'collections.dart';

typedef SharedMatchContext =
    shared.MatchContext<
      InternalNode,
      InternalExpression,
      InternalPattern,
      InternalVariable
    >;

abstract class InternalNode({required final int fileOffset}) {
  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toStringInternal] should only be used for debugging, but should not leak.
  ///
  /// The data is generally bare-bones, but can easily be updated for your
  /// specific debugging needs.
  ///
  /// This method is called internally by toString methods to create conciser
  /// textual representations.
  // Coverage-ignore(suite): Not run.
  String toStringInternal() => toText(defaultAstTextStrategy);

  // Coverage-ignore(suite): Not run.
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer);

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

/// Common base class for internal statements.
abstract class InternalStatement({required super.fileOffset})
    extends InternalNode {
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor);
}

class TryStatement extends InternalStatement {
  final InternalStatement tryBlock;
  final List<InternalCatch> catchBlocks;
  final InternalStatement? finallyBlock;

  new(
    this.tryBlock,
    this.catchBlocks,
    this.finallyBlock, {
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitTryStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('try ');
    tryBlock.toTextInternal(printer);
    for (InternalCatch catchBlock in catchBlocks) {
      printer.write(' ');
      catchBlock.toTextInternal(printer);
    }
    if (finallyBlock != null) {
      printer.write(' finally ');
      finallyBlock!.toTextInternal(printer);
    }
  }
}

sealed class InternalSwitchCase({required super.fileOffset})
    extends InternalNode {
  List<Label>? get labels;
  InternalStatement get body;

  bool get hasLabel => labels != null;

  List<ContinueSwitchStatement>? _continueStatements;
  SwitchCase? _node;

  void _connectContinueToCase(
    ContinueSwitchStatement continueStatement,
    SwitchCase switchCase,
  ) {
    continueStatement.target = switchCase;
    if (switchCase is PatternSwitchCase) {
      switchCase.labelUsers.add(continueStatement);
    }
  }

  /// Registers that [statement] targets this switch case.
  ///
  /// The ensures that continue statements and switch cases are connected
  /// correctly in the external AST.
  void registerContinueSwitchStatement(ContinueSwitchStatement statement) {
    (_continueStatements ??= [])..add(statement);
    SwitchCase? node = _node;
    if (node != null) {
      _connectContinueToCase(statement, node);
    }
  }

  /// Registers that [node] corresponds to this switch case.
  ///
  /// The ensures that continue statements and switch cases are connected
  /// correctly in the external AST.
  void registerSwitchCase(SwitchCase node) {
    assert(_node == null, "SwitchCase already created for $this.");
    _node = node;

    List<ContinueSwitchStatement>? continueStatements = _continueStatements;
    if (continueStatements != null) {
      for (ContinueSwitchStatement continueStatement in continueStatements) {
        _connectContinueToCase(continueStatement, node);
      }
    }
  }
}

class InternalSwitchStatementCase extends InternalSwitchCase {
  final List<InternalExpression> expressions;
  final List<int> expressionOffsets;
  @override
  final InternalStatement body;
  final bool isDefault;
  final List<int> caseOffsets;
  @override
  final List<Label>? labels;

  new({
    required this.caseOffsets,
    required this.expressions,
    required this.expressionOffsets,
    required this.body,
    required this.isDefault,
    required this.labels,
    required super.fileOffset,
  });

  int get caseHeadCount => expressions.length;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    bool needsNewLine = false;
    if (labels != null) {
      for (Label label in labels!) {
        if (needsNewLine) {
          printer.newLine();
        }
        printer.write(label.name);
        printer.write(':');
        needsNewLine = true;
      }
    }
    for (InternalExpression expression in expressions) {
      if (needsNewLine) {
        printer.newLine();
      }
      printer.write('case ');
      expression.toTextInternal(printer);
      printer.write(':');
      needsNewLine = true;
    }
    if (isDefault) {
      if (needsNewLine) {
        printer.newLine();
      }
      printer.write('default:');
    }
    printer.incIndentation();
    InternalStatement? block = body;
    if (block is InternalBlock) {
      for (InternalStatement statement in block.statements) {
        printer.newLine();
        statement.toTextInternal(printer);
      }
    } else {
      printer.write(' ');
      body.toTextInternal(printer);
    }
    printer.decIndentation();
  }
}

class InternalRegularSwitchStatement extends InternalStatement
    implements InternalSwitchStatement {
  final InternalExpression expression;

  @override
  final List<InternalSwitchStatementCase> cases;

  @override
  final List<BreakStatement> breakStatements = [];

  new({
    required this.expression,
    required this.cases,
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalRegularSwitchStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    expression.toTextInternal(printer);
    printer.write(') {');
    printer.incIndentation();
    for (InternalSwitchStatementCase switchCase in cases) {
      printer.newLine();
      switchCase.toTextInternal(printer);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }
}

sealed class InternalGotoStatement implements InternalStatement {
  /// If this statement is erroneous, [error] holds the invalid expression
  /// to be used in its place.
  abstract InternalInvalidExpression? error;
}

/// A statement that can be the target of a break statement.
sealed class InternalBreakableStatement implements InternalStatement {
  /// List of [BreakStatement]s that will target this breakable statement.
  List<BreakStatement> get breakStatements;
}

/// A statement that can be the target of a continue statement.
sealed class InternalContinuableStatement implements InternalStatement {
  /// List of [BreakStatement]s that will target this continuable statement.
  List<BreakStatement> get continueStatements;
}

class InternalBreakStatement extends InternalStatement
    implements InternalGotoStatement {
  final String? label;
  late InternalBreakableStatement targetStatement;

  @override
  InternalInvalidExpression? error;

  new({required this.label, required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalBreakStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('break');
    if (label != null) {
      printer.write(' ');
      printer.write(label!);
    }
    printer.write(';');
  }
}

class InternalContinueStatement extends InternalStatement
    implements InternalGotoStatement {
  final String? label;
  late InternalContinuableStatement targetStatement;

  @override
  InternalInvalidExpression? error;

  new({required this.label, required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalContinueStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('continue');
    if (label != null) {
      printer.write(' ');
      printer.write(label!);
    }
    printer.write(';');
  }
}

// Coverage-ignore(suite): Not run.
extension on List<InternalExpression> {
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      this[index].toTextInternal(printer);
    }
  }
}

// Coverage-ignore(suite): Not run.
extension on List<InternalElement> {
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      this[index].toTextInternal(printer);
    }
  }
}

/// Common base class for internal expressions.
abstract class InternalExpression({required super.fileOffset})
    extends InternalNode {
  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Implement this in subclasses.
  int get precedence => Precedence.PRIMARY;

  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  );
}

/// Common base class for internal initializers.
sealed class InternalInitializer({required super.fileOffset})
    extends InternalNode {
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor);
}

// Coverage-ignore(suite): Not run.
/// Common base class for internal initializers that can be used as external
/// initializers.
// TODO(johnniwinther): Avoid the need for this
sealed class ExternalInitializer extends AuxiliaryInitializer {
  @override
  void visitChildren(Visitor<dynamic> v) =>
      unsupported("${runtimeType}.visitChildren", -1, null);

  @override
  void transformChildren(Transformer v) =>
      unsupported("${runtimeType}.transformChildren", -1, null);

  @override
  void transformOrRemoveChildren(RemovingTransformer v) =>
      unsupported("${runtimeType}.transformOrRemoveChildren", -1, null);
}

// TODO(johnniwinther): Add offsets. Maybe add `isExplicit` property, since this
// is currently used to pass converted/computed type arguments for type alias
// constructor invocation.
class TypeArguments {
  final List<DartType> types;

  new(this.types);

  // Coverage-ignore(suite): Not run.
  void toText(AstPrinter printer) {
    printer.writeTypeArguments(types);
  }
}

sealed class Argument({required super.fileOffset}) extends InternalNode {
  InternalExpression get expression;

  bool get isSuperParameter => false;
}

class PositionalArgument extends Argument {
  @override
  final InternalExpression expression;

  new(this.expression) : super(fileOffset: expression.fileOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }
}

class SuperPositionalArgument extends PositionalArgument {
  new(super.expression);

  @override
  bool get isSuperParameter => true;
}

class NamedArgument extends Argument {
  final InternalNamedExpression namedExpression;

  new(this.namedExpression) : super(fileOffset: namedExpression.fileOffset);

  String get name => namedExpression.name;

  @override
  InternalExpression get expression => namedExpression.value;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    namedExpression.toTextInternal(printer);
  }

  @override
  String toString() => '$runtimeType($namedExpression)';
}

class SuperNamedArgument extends NamedArgument {
  new(super.expression);

  @override
  bool get isSuperParameter => true;
}

/// Front end specific implementation of [Argument].
class ActualArguments extends InternalNode {
  final List<Argument> argumentList;

  bool _hasNamedBeforePositional;
  int _positionalCount;

  new({
    required this.argumentList,
    required bool hasNamedBeforePositional,
    required int positionalCount,
    required super.fileOffset,
  }) : _hasNamedBeforePositional = hasNamedBeforePositional,
       _positionalCount = positionalCount;

  int get positionalCount => _positionalCount;

  int get namedCount => argumentList.length - positionalCount;

  bool get hasNamedBeforePositional => _hasNamedBeforePositional;

  /// Determines how many argument expressions should be hoisted when
  /// implementing the "named arguments anywhere" feature.
  ///
  /// The reason argument expressions need to be hoisted when implementing this
  /// feature is that in kernel semantics, positional arguments are evaluated
  /// before named arguments, so if any named argument appears before a
  /// positional argument, it needs to be hoisted to ensure that it is evaluated
  /// before the positional arguments that follow it.
  int computeHoistingEndIndexForNamedArgumentsAnywhere() {
    // The computation is based on the following observation: the largest suffix
    // of the argument vector, such that every positional argument in that
    // suffix comes before any named argument, retains the evaluation order
    // after the rest of the arguments are hoisted, and therefore doesn't need
    // to be hoisted itself. The loop below finds the starting position of such
    // suffix and returns it. In case all positional arguments come before all
    // named arguments, the suffix coincides with the entire argument vector,
    // and none of the arguments is hoisted. That way the legacy behavior is
    // preserved.
    if (hasNamedBeforePositional) {
      int hoistingEndIndex = argumentList.length - 1;
      for (
        int i = argumentList.length - 2;
        i >= 0 && hoistingEndIndex == i + 1;
        i--
      ) {
        int previousWeight = argumentList[i + 1] is NamedArgument ? 1 : 0;
        int currentWeight = argumentList[i] is NamedArgument ? 1 : 0;
        if (currentWeight <= previousWeight) {
          --hoistingEndIndex;
        }
      }
      return hoistingEndIndex;
    } else {
      return 0;
    }
  }

  void prependArguments(List<Argument> list, {required int positionalCount}) {
    assert(list.whereType<PositionalArgument>().length == positionalCount);
    argumentList.insertAll(0, list);
    if (!_hasNamedBeforePositional &&
        _positionalCount > 0 &&
        positionalCount < list.length) {
      _hasNamedBeforePositional = true;
    }
    _positionalCount += positionalCount;
  }

  Arguments toArguments(
    List<DartType> typeArguments,
    List<Expression> positionalArguments,
    List<NamedExpression> namedArguments,
  ) {
    return extern.createArguments(
      positionalArguments,
      types: typeArguments,
      named: namedArguments,
      fileOffset: fileOffset,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    for (int index = 0; index < argumentList.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      argumentList[index].toTextInternal(printer);
    }
    printer.write(')');
  }
}

/// Internal expression representing a cascade expression.
///
/// A cascade expression of the form `a..b()..c()` is represented as the kernel
/// expression:
///
///     let v = a in
///         let _ = v.b() in
///             let _ = v.c() in
///                 v
///
/// In the documentation that follows, `v` is referred to as the "cascade
/// variable"--this is the variable that remembers the value of the expression
/// preceding the first `..` while the cascades are being evaluated.
class Cascade extends InternalExpression {
  /// The temporary variable holding the cascade receiver expression in its
  /// initializer;
  final InternalSyntheticVariable variable;

  final InternalExpression receiver;

  /// `true` if the access is null-aware, i.e. of the form `a?..b()`.
  final bool isNullAware;

  /// The expressions performed on [variable].
  final List<InternalExpression> expressions = <InternalExpression>[];

  /// Creates a [Cascade] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  new({
    required this.variable,
    required this.receiver,
    required this.isNullAware,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCascade(this, typeContext);
  }

  /// Adds [expression] to the list of [expressions] performed on [variable].
  void addCascadeExpression(InternalExpression expression) {
    expressions.add(expression);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    variable.toTextInternal(printer, initializer: receiver);
    printer.write(' in cascade {');
    printer.incIndentation();
    for (InternalExpression expression in expressions) {
      printer.newLine();
      expression.toTextInternal(printer);
      printer.write(';');
    }
    printer.decIndentation();
    if (expressions.isNotEmpty) {
      printer.newLine();
    }
    printer.write('} => ');
    printer.write(printer.getVariableName(variable._astVariable));
  }
}

/// Internal expression representing an anonymous method invocation.
class AnonymousMethodExpression extends InternalExpression {
  final InternalAnonymousMethodParameter variable;
  final InternalExpression receiver;
  final InternalExpression body;
  final bool isCascade;
  final bool isImplicitlyTyped;
  final bool isNullAware;
  final bool isParameterless;
  final int typeOffset;

  new({
    required this.variable,
    required this.receiver,
    required this.body,
    required this.isImplicitlyTyped,
    required this.isNullAware,
    required this.isCascade,
    required this.typeOffset,
    required super.fileOffset,
  }) : isParameterless = variable.isSynthesized;

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAnonymousMethodExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    variable.toTextInternal(printer, initializer: receiver);
    printer.write(' in ');
    body.toTextInternal(printer);
  }
}

/// Internal expression representing an anonymous block method invocation.
class AnonymousMethodBlock extends InternalExpression {
  final InternalAnonymousMethodParameter variable;
  final InternalStatement body;
  final InternalExpression receiver;
  final bool isCascade;
  final bool isImplicitlyTyped;
  final bool isNullAware;
  final bool isParameterless;
  final int typeOffset;

  new({
    required this.variable,
    required this.receiver,
    required this.body,
    required this.isImplicitlyTyped,
    required this.isNullAware,
    required this.isCascade,
    required this.typeOffset,
    required super.fileOffset,
  }) : isParameterless = variable.isSynthesized;

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAnonymousMethodBlock(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    variable.toTextInternal(printer, initializer: receiver);
    printer.write(' in ');
    body.toTextInternal(printer);
  }
}

/// Internal expression representing a deferred check.
// TODO(johnniwinther): Change the representation to be direct and perform
// the [Let] encoding in the replacement.
class DeferredCheck extends InternalExpression {
  final LibraryDependency dependency;
  final InternalExpression expression;

  new({
    required this.dependency,
    required this.expression,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDeferredCheck(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let final dynamic # = ');
    printer.write(dependency.name!);
    printer.write('.checkLibraryIsLoaded() in ');
    expression.toTextInternal(printer);
  }
}

/// Internal expression for an invocation of a factory constructor.
class FactoryConstructorInvocation extends InternalExpression {
  final Procedure target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  new({
    required this.target,
    required this.typeArguments,
    required this.arguments,
    required this.isConst,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitFactoryConstructorInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass?.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Internal expression for an invocation of a type aliased constructor.
class TypeAliasedConstructorInvocation extends InternalExpression {
  final TypeAliasBuilder typeAliasBuilder;
  final Constructor target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;
  final bool isConst;

  new({
    required this.typeAliasBuilder,
    required this.target,
    required this.typeArguments,
    required this.arguments,
    required this.isConst,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitTypeAliasedConstructorInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeTypedefName(typeAliasBuilder.typedef.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Internal expression for an invocation of a type aliased factory constructor.
class TypeAliasedFactoryInvocation extends InternalExpression {
  final TypeAliasBuilder typeAliasBuilder;
  final Procedure target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  new({
    required this.typeAliasBuilder,
    required this.target,
    required this.typeArguments,
    required this.arguments,
    required this.isConst,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitTypeAliasedFactoryInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeTypedefName(typeAliasBuilder.typedef.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Internal expression representing an if-null expression.
///
/// An if-null expression of the form `a ?? b` is encoded as:
///
///     let v = a in v == null ? b : v
///
class IfNullExpression extends InternalExpression {
  final InternalExpression left;
  final InternalExpression right;

  new(this.left, this.right, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    left.toTextInternal(
      printer /*, minimumPrecedence: Precedence.CONDITIONAL*/,
    );
    printer.write(' ?? ');
    right.toTextInternal(
      printer,
      /*minimumPrecedence: Precedence.CONDITIONAL + 1,*/
    );
  }
}

/// Concrete shadow object representing an integer literal in kernel form.
class InternalIntLiteral extends InternalExpression {
  final int value;

  /// The literal text of the number, as it appears in the source, which may
  /// include digit separators (and may not be safe for parsing with
  /// `int.parse`).
  final String? literal;

  new(this.value, this.literal, {required super.fileOffset});

  double? asDouble({bool negated = false}) {
    if (value == 0 && negated) {
      return -0.0;
    }
    BigInt intValue = new BigInt.from(negated ? -value : value);
    double doubleValue = intValue.toDouble();
    return intValue == new BigInt.from(doubleValue) ? doubleValue : null;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalIntLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (literal == null) {
      printer.write('$value');
    } else {
      printer.write(literal!);
    }
  }
}

class LargeIntLiteral extends InternalExpression {
  /// The parsable String source, stripped of any digit separators.
  final String _strippedLiteral;

  /// The original textual source, possibly with digit separators.
  final String literal;

  bool isParenthesized = false;

  new(this._strippedLiteral, this.literal, {required super.fileOffset});

  double? asDouble({bool negated = false}) {
    BigInt? intValue = BigInt.tryParse(
      negated ? '-${_strippedLiteral}' : _strippedLiteral,
    );
    if (intValue == null) {
      return null;
    }
    double doubleValue = intValue.toDouble();
    return !doubleValue.isNaN &&
            !doubleValue.isInfinite &&
            intValue == new BigInt.from(doubleValue)
        ? doubleValue
        : null;
  }

  int? asInt64({bool negated = false}) {
    return int.tryParse(negated ? '-${_strippedLiteral}' : _strippedLiteral);
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitLargeIntLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(literal);
  }
}

class ExpressionInvocation extends InternalExpression {
  final InternalExpression expression;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  new(
    this.expression,
    this.typeArguments,
    this.arguments, {
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExpressionInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// Front end specific implementation of [ReturnStatement].
class InternalReturnStatement extends InternalStatement {
  final InternalExpression? expression; // May be null.
  final bool isArrow;

  new({this.expression, required this.isArrow, required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalReturnStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isArrow) {
      printer.write('=>');
    } else {
      printer.write('return');
    }
    if (expression != null) {
      printer.write(' ');
      expression!.toTextInternal(printer);
    }
    printer.write(';');
  }
}

class InternalLocalVariable extends InternalDeclaredVariable {
  @override
  LocalVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  new({
    required String name,
    required DartType? type,
    bool isFinal = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    bool isStaticLate = false,
    required super.fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
  }) : _astVariable = extern.createLocalVariable(
         name: name,
         type: type,
         isFinal: isFinal,
         isWildcard: isWildcard,
         hasDeclaredInitializer: hasDeclaredInitializer,
         fileOffset: fileOffset,
         fileEqualsOffset: fileEqualsOffset,
       ) {
    this.isStaticLate = isStaticLate;
  }

  @override
  bool get isLocalFunction => false;

  @override
  LocalVariable get astVariable => _astVariable;

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }
}

class InternalLocalFunctionVariable extends InternalDeclaredVariable {
  @override
  LocalFunctionVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  new({
    required String name,
    required DartType? type,
    bool isWildcard = false,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    required super.fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
  }) : _astVariable = extern.createLocalFunctionVariable(
         name: name,
         type: type,
         isWildcard: isWildcard,
         isLowered: false,
         fileOffset: fileOffset,
         fileEqualsOffset: fileEqualsOffset,
       );

  @override
  bool get isLocalFunction => true;

  @override
  LocalFunctionVariable get astVariable => _astVariable;

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }
}

class InternalLateVariable extends InternalDeclaredVariable {
  @override
  LateVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  new({
    required String name,
    required DartType? type,
    bool isFinal = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    bool isStaticLate = false,
    required super.fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
  }) : _astVariable = extern.createLateVariable(
         name: name,
         type: type,
         isFinal: isFinal,
         isWildcard: isWildcard,
         hasDeclaredInitializer: hasDeclaredInitializer,
         fileOffset: fileOffset,
         fileEqualsOffset: fileEqualsOffset,
       ) {
    this.isStaticLate = isStaticLate;
  }

  @override
  bool get isLocalFunction => false;

  @override
  LateVariable get astVariable => _astVariable;

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }
}

class InternalConstVariable extends InternalDeclaredVariable {
  @override
  ConstVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  new({
    required String name,
    required DartType? type,
    bool isFinal = false,
    bool isWildcard = false,
    bool hasDeclaredInitializer = false,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    required super.fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
  }) : _astVariable = extern.createConstVariable(
         name: name,
         type: type,
         isFinal: isFinal,
         isWildcard: isWildcard,
         hasDeclaredInitializer: hasDeclaredInitializer,
         fileOffset: fileOffset,
         fileEqualsOffset: fileEqualsOffset,
       );

  @override
  bool get isLocalFunction => false;

  @override
  ConstVariable get astVariable => _astVariable;

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }
}

sealed class InternalFunctionParameter extends InternalVariable {
  InternalExpression? _defaultValue;

  new({required this._defaultValue, required super.fileOffset});

  @override
  FunctionParameter get astVariable;

  @override
  FunctionParameter get _astVariable;

  bool get hasErroneousDefaultValue => _astVariable.hasErroneousDefaultValue;

  void set hasErroneousDefaultValue(bool value) {
    _astVariable.hasErroneousDefaultValue = value;
  }

  @Deprecated('Use InternalFunctionParameter.hasErroneousDefaultValue instead.')
  @override
  bool get isErroneouslyInitialized;

  @Deprecated('Use InternalFunctionParameter.hasErroneousDefaultValue instead.')
  @override
  void set isErroneouslyInitialized(bool value);

  // Coverage-ignore(suite): Not run.
  bool get hasDeclaredDefaultValue => _astVariable.hasDeclaredDefaultValue;

  InternalExpression? get defaultValue => _defaultValue;

  void updateDefaultValue(InternalExpression? value) {
    _defaultValue = value;
  }

  Expression? get inferredDefaultValue => _astVariable.defaultValue;

  void setInferredDefaultValue(Expression? value) {
    _astVariable.defaultValue = value?..parent = _astVariable;
  }
}

class InternalPositionalParameter extends InternalFunctionParameter {
  @override
  PositionalParameter _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required super.defaultValue,
    required this._astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required super.fileOffset,
  });

  @override
  PositionalParameter get astVariable => _astVariable;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(_astVariable);
    List<String> modifiers = [
      if (forSyntheticToken) "forSyntheticToken",
      if (isImplicitlyTyped) "isImplicitlyTyped",
      if (isLocalFunction) "isLocalFunction",
    ];
    if (modifiers.isNotEmpty) {
      printer.write("[${modifiers.join(",")}]");
    }
  }
}

class InternalNamedParameter extends InternalFunctionParameter {
  @override
  NamedParameter _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required super.defaultValue,
    required this._astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required super.fileOffset,
  });

  @override
  NamedParameter get astVariable => _astVariable;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(_astVariable);
    List<String> modifiers = [
      if (forSyntheticToken) "forSyntheticToken",
      if (isImplicitlyTyped) "isImplicitlyTyped",
      if (isLocalFunction) "isLocalFunction",
    ];
    if (modifiers.isNotEmpty) {
      printer.write("[${modifiers.join(",")}]");
    }
  }

  // Coverage-ignore(suite): Not run.
  String get parameterName => _astVariable.parameterName;
}

class InternalCatchVariable extends InternalVariable {
  @override
  CatchVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required String name,
    DartType? type,
    bool isWildcard = false,
    bool isFinal = false,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required super.fileOffset,
  }) : _astVariable = extern.createCatchVariable(
         name: name,
         type: type,
         isWildcard: isWildcard,
         isFinal: isFinal,
         fileOffset: fileOffset,
       );

  @override
  CatchVariable get astVariable => _astVariable;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(_astVariable);
    List<String> modifiers = [
      if (forSyntheticToken) "forSyntheticToken",
      if (isImplicitlyTyped) "isImplicitlyTyped",
      if (isLocalFunction) "isLocalFunction",
    ];
    if (modifiers.isNotEmpty) {
      printer.write("[${modifiers.join(",")}]");
    }
  }

  // Coverage-ignore(suite): Not run.
  String get catchVariableName => _astVariable.catchVariableName;
}

class InternalAnonymousMethodParameter extends InternalDeclaredVariable {
  @override
  SyntheticVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isWildcard;

  new({
    required String name,
    required DartType type,
    required this.isImplicitlyTyped,
    required bool isFinal,
    required bool isSynthesized,
    this.forSyntheticToken = false,
    required this.isWildcard,
    required super.fileOffset,
  }) : _astVariable = new SyntheticVariable(
         cosmeticName: name,
         isFinal: isFinal,
         isSynthesized: isSynthesized,
         type: type,
       )..fileOffset = fileOffset;

  @override
  bool get isLocalFunction => false;

  @override
  SyntheticVariable get astVariable => _astVariable;
}

class InternalSyntheticVariable extends InternalDeclaredVariable {
  @override
  SyntheticVariable _astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  new({
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    String? name,
    DartType? type,
    bool isFinal = false,
    bool isLowered = false,
    bool isSynthesized = true,
    required super.fileOffset,
  }) : _astVariable = new SyntheticVariable(
         cosmeticName: name,
         type: type ?? const DynamicType(),
         isFinal: isFinal,
         isLowered: isLowered,
         isSynthesized: isSynthesized,
       )..fileOffset = fileOffset;

  @override
  bool get isLocalFunction => false;

  @override
  SyntheticVariable get astVariable => _astVariable;
}

sealed class InternalVariable({required super.fileOffset})
    extends InternalNode {
  /// This is the output variable that the clients receive.
  ///
  /// Most of the calls to variable properties are delegated to [astVariable],
  /// but some operations must be performed directly on [astVariable], as
  /// follows:
  ///
  /// * passing [astVariable] into the flow analysis engine,
  /// * using [astVariable] as a part of the generated AST,
  /// * checking semantic properties of an AST node, such as [isExtensionThis]
  ///   in `lowering_predicates.dart`.
  Variable get astVariable;

  Variable get _astVariable;

  bool get forSyntheticToken;

  /// Determine whether the given [InternalVariable] had an implicit
  /// type.
  bool get isImplicitlyTyped;

  /// Determines whether the given [InternalVariable] represents a
  /// local function.
  bool get isLocalFunction;

  /// Whether the variable is final with no initializer.
  ///
  /// Such variables behave similar to those declared with the `late` keyword,
  /// except that the don't have lazy evaluation semantics, and it is statically
  /// verified by the front end that they are always assigned before they are
  /// used.
  bool isStaticLate = false;

  /// The synthesized local getter function for a lowered late variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  LocalFunctionVariable? lateGetter;

  /// The synthesized local setter function for an assignable lowered late
  /// variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  LocalFunctionVariable? lateSetter;

  /// Is `true` if this a lowered late final variable without an initializer.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  bool isLateFinalWithoutInitializer = false;

  /// The original type (declared or inferred) of a lowered late variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  DartType? lateType;

  /// The original name of a lowered late variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  String? lateName;

  String? get cosmeticName => _astVariable.cosmeticName;

  void set cosmeticName(String? value) {
    _astVariable.cosmeticName = value;
  }

  bool get hasDeclaredInitializer => _astVariable.hasDeclaredInitializer;

  void set hasDeclaredInitializer(bool value) {
    _astVariable.hasDeclaredInitializer = value;
  }

  bool get isConst => _astVariable.isConst;

  void set isConst(bool value) {
    _astVariable.isConst = value;
  }

  // Coverage-ignore(suite): Not run.
  bool get isErroneouslyInitialized => astVariable.isErroneouslyInitialized;

  void set isErroneouslyInitialized(bool value) {
    _astVariable.isErroneouslyInitialized = value;
  }

  bool get isFinal => _astVariable.isFinal;

  void set isFinal(bool value) {
    _astVariable.isFinal = value;
  }

  bool get isLate => _astVariable.isLate;

  void set isLate(bool value) {
    _astVariable.isLate = value;
  }

  // Coverage-ignore(suite): Not run.
  bool get isLowered => _astVariable.isLowered;

  void set isLowered(bool value) {
    _astVariable.isLowered = value;
  }

  bool get isRequired => _astVariable.isRequired;

  // Coverage-ignore(suite): Not run.
  void set isRequired(bool value) {
    _astVariable.isRequired = value;
  }

  bool get isSynthesized => _astVariable.isSynthesized;

  // Coverage-ignore(suite): Not run.
  void set isSynthesized(bool value) {
    _astVariable.isSynthesized = value;
  }

  bool get isWildcard => _astVariable.isWildcard;

  // Coverage-ignore(suite): Not run.
  void set isWildcard(bool value) {
    _astVariable.isWildcard = value;
  }

  DartType get type => _astVariable.type;

  void set type(DartType value) {
    _astVariable.type = value;
  }

  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return !hasDeclaredInitializer;
      return false;
    }
    return true;
  }

  bool get hasInitializer => _astVariable.initializer != null;
}

sealed class InternalDeclaredVariable({required super.fileOffset})
    extends InternalVariable {
  @override
  DeclaredVariable get astVariable;

  @override
  DeclaredVariable get _astVariable;

  /// Writes this [InternalVariable] to the [printer].
  ///
  /// If [includeModifiersAndType] is `true`, the declaration is prefixed by
  /// the modifiers and declared type of the variable. Otherwise only the
  /// name and the [initializer], if present, are included.
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(
    AstPrinter printer, {
    bool includeModifiersAndType = true,
    InternalExpression? initializer,
  }) {
    if (includeModifiersAndType) {
      if (isRequired) {
        printer.write('required ');
      }
      if (isLate) {
        printer.write('late ');
      }
      if (isFinal) {
        printer.write('final ');
      }
      if (isConst) {
        printer.write('const ');
      }
      if (isImplicitlyTyped) {
        printer.write('var ');
      } else {
        printer.writeType(type);
        printer.write(' ');
      }
    }
    printer.write(cosmeticName ?? '<unnamed-variable>');
    if (initializer != null) {
      printer.write(' = ');
      initializer.toTextInternal(printer);
    }
  }
}

/// Front end specific implementation of [LoadLibrary].
class InternalLoadLibrary extends InternalExpression {
  final LibraryDependency import;

  final ActualArguments? arguments;

  new(this.import, this.arguments, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalLoadLibrary(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary');
    if (arguments != null) {
      arguments!.toTextInternal(printer);
    } else {
      printer.write('()');
    }
  }
}

/// Internal expression representing a tear-off of a `loadLibrary` function.
class LoadLibraryTearOff extends InternalExpression {
  final LibraryDependency import;
  final Procedure target;

  new(this.import, this.target, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitLoadLibraryTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary');
  }
}

/// Internal expression representing an if-null property set.
///
/// An if-null property set of the form `o.a ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in v1.a == null ? v1.a = b : null
///
class IfNullPropertySet extends InternalExpression {
  /// The receiver used for the read/write operations.
  final InternalExpression receiver;

  /// Name of the property.
  final Name propertyName;

  /// The right-hand side of the binary operation.
  final InternalExpression rhs;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form `o?.a ??= b`.
  final bool isNullAware;

  new({
    required this.receiver,
    required this.propertyName,
    required this.rhs,
    required this.forEffect,
    required this.readOffset,
    required this.writeOffset,
    required this.isNullAware,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullPropertySet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ??= ');
    rhs.toTextInternal(printer);
  }
}

/// Internal expression representing an if-null assignment.
///
/// An if-null assignment of the form `a ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = a in v1 == null ? a = b : v1
///
/// and, if used for effect, encoded as the expression:
///
///     a == null ? a = b : null
///
class IfNullSet extends InternalExpression {
  /// The expression that reads the property from [variable].
  final InternalExpression read;

  /// The expression that writes the value to the property on [variable].
  final InternalExpression write;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  new({
    required this.read,
    required this.write,
    required this.forEffect,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    read.toTextInternal(printer);
    printer.write(' ?? ');
    write.toTextInternal(printer);
  }
}

/// Internal expression representing an compound extension assignment.
///
/// An compound extension assignment of the form
///
///     Extension(receiver).propertyName ??= rhs
///
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = receiver in
///       let valueVariable =
///           Extension|get#propertyName(receiverVariable) in
///         valueVariable == null
///           ? let rhsVariable = rhs in
///             let writeVariable in
///                 Extension|set#propertyName(receiverVariable, rhsVariable) in
///               rhsVariable
///           : valueVariable
///
/// and if used for effect as:
///
///     let receiverVariable = receiver in
///       Extension|get#propertyName(receiverVariable) == null
///         ? Extension|set#propertyName(receiverVariable, rhs)
///         : null
///
class ExtensionIfNullSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a ??= b` or
  /// implied as in `a ??= b` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver used for the read/write operations.
  final InternalExpression receiver;

  /// The name of property.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name propertyName;

  /// The member used for the read operation.
  final Member getter;

  /// The right-hand side of the binary operation.
  final InternalExpression rhs;

  /// The member used for the write operation.
  final Member setter;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a ??= b`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a ??= b` and
  /// not implicit like `a ??= b` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required InternalExpression receiver,
    required Name propertyName,
    required Procedure getter,
    required InternalExpression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         propertyName,
         getter,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name propertyName,
    required Procedure getter,
    required InternalExpression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         propertyName,
         getter,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  new _(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.propertyName,
    this.getter,
    this.rhs,
    this.setter, {
    required this.forEffect,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ),
       super(fileOffset: binaryOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIfNullSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ??= ');
    rhs.toTextInternal(printer);
  }
}

/// Internal expression representing an compound extension assignment.
///
/// An compound extension assignment of the form
///
///     Extension(receiver).propertyName += rhs
///
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = receiver in
///       let valueVariable =
///           Extension|get#propertyName(receiverVariable) + rhs) in
///         let writeVariable =
///             Extension|set#propertyName(receiverVariable, valueVariable) in
///           valueVariable
///
/// and if used for effect as:
///
///     let receiverVariable = receiver in
///         Extension|set#propertyName(receiverVariable,
///           Extension|get#propertyName(receiverVariable) + rhs)
///
class ExtensionCompoundSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a += b` or
  /// implied as in `a += b` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver used for the read/write operations.
  final InternalExpression receiver;

  /// The name of property.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name propertyName;

  /// The member used for the read operation.
  final Member getter;

  /// The binary operation performed on the getter result and [rhs].
  final Name binaryName;

  /// The right-hand side of the binary operation.
  final InternalExpression rhs;

  /// The member used for the write operation.
  final Member setter;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a += b`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a += b` and
  /// not implicit like `a += b` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required InternalExpression receiver,
    required Name propertyName,
    required Procedure getter,
    required Name binaryName,
    required InternalExpression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         propertyName,
         getter,
         binaryName,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name propertyName,
    required Procedure getter,
    required Name binaryName,
    required InternalExpression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         propertyName,
         getter,
         binaryName,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  new _(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.propertyName,
    this.getter,
    this.binaryName,
    this.rhs,
    this.setter, {
    required this.forEffect,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ),
       super(fileOffset: binaryOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionCompoundSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ');
    printer.writeName(binaryName);
    printer.write('= ');
    rhs.toTextInternal(printer);
  }
}

/// Internal expression representing an compound property assignment.
///
/// An compound property assignment of the form
///
///     receiver.propertyName += rhs
///
/// is encoded as the expression:
///
///     let receiverVariable = receiver in
///       receiverVariable.propertyName = receiverVariable.propertyName + rhs
///
class CompoundPropertySet extends InternalExpression {
  /// The receiver used for the read/write operations.
  final InternalExpression receiver;

  /// The name of the property accessed by the read/write operations.
  final Name propertyName;

  /// The binary operation performed on the getter result and [value].
  final Name binaryName;

  /// The right-hand side of the binary operation.
  final InternalExpression value;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form `o?.a += b`.
  final bool isNullAware;

  new({
    required this.receiver,
    required this.propertyName,
    required this.binaryName,
    required this.value,
    required this.forEffect,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.isNullAware,
  }) : super(fileOffset: binaryOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCompoundPropertySet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ');
    printer.writeName(binaryName);
    printer.write('= ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing an property inc/dec, for instance
/// `o.a++` and `--o.a`.
///
/// An property postfix increment of the form `o.a++` is encoded as the
/// expression:
///
///     let v1 = o in let v2 = v1.a in let v3 = v1.a = v2 + 1 in v2
///
/// and a property prefix increment of the form `--o.a` or a postfix decrement
/// of the form `o.a--` for effect is encoded as the expression:
///
///     let v1 = o in let v2 = v1.a in v1.a = v2 - 1
///
class PropertyIncDec extends InternalExpression {
  /// The receiver of the assigned property.
  final InternalExpression receiver;

  /// The name of the assigned property.
  final Name name;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `o.a++` as
  /// opposed the prefix expression `++o.a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `o.a++` as opposed to `o.a--`.
  final bool isInc;

  /// `true` if the access is null-aware, i.e. of the form `o?.a++`.
  final bool isNullAware;

  /// The file offset of the [name].
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  /// `true` if the access is an implicit `this` access.
  final bool isImplicitThis;

  new({
    required this.receiver,
    required this.name,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.isNullAware,
    required this.nameOffset,
    required this.operatorOffset,
    required this.isImplicitThis,
  }) : super(fileOffset: nameOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitPropertyIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }
}

/// Internal expression representing an post-inc/dec expression on an explicit
/// extension member access.
///
/// An post-inc/dec expression of the form `E(o).a++` is encoded as the
/// expression:
///
///     let v1 = o in let v2 = E|a(v1) in let v3 = E|a(v1, v2 + 1) in v2
///
class ExtensionIncDec extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a++` or
  /// implied as in `a++` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver used for the read/write operations.
  final InternalExpression receiver;

  /// The name of property.
  ///
  /// This is the name of the access and _not_ the name of the lowered methods.
  final Name name;

  /// The [Procedure] used for the read of the property.
  final Procedure getter;

  /// The [Procedure] used for the write of the property.
  final Procedure setter;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `E(o).a++`
  /// as opposed the prefix expression `++E(o).a`.
  final bool isPost;

  /// `true` if this is a post increment expression, i.e. `E(o).a++` as opposed
  /// to `E(o).a--`.
  final bool isInc;

  /// `true` if the expression is for effect only, i.e. that the resulting value
  /// is not used.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form `E(o)?.b++`.
  final bool isNullAware;

  /// `true` if this an explicit extension access, i.e. `E(o).a++` as opposed
  /// to the implicit access of `a++` occurring within the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required InternalExpression receiver,
    required Name name,
    required Procedure getter,
    required Procedure setter,
    required bool isPost,
    required bool isInc,
    required bool forEffect,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
    required int fileOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         getter,
         setter,
         isPost: isPost,
         isInc: isInc,
         forEffect: forEffect,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         fileOffset: fileOffset,
       );

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name name,
    required Procedure getter,
    required Procedure setter,
    required bool isPost,
    required bool isInc,
    required bool forEffect,
    required int fileOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         getter,
         setter,
         isPost: isPost,
         isInc: isInc,
         forEffect: forEffect,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
         fileOffset: fileOffset,
       );

  new _(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.getter,
    this.setter, {
    required this.isPost,
    required this.isInc,
    required this.forEffect,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionPostIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      printer.write(isInc ? '++' : '--');
    }
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    if (isPost) {
      printer.write(isInc ? '++' : '--');
    }
  }
}

/// Internal expression representing an local variable post inc/dec expression.
///
/// An local variable post inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = v1 + 1 in v1
///
class LocalIncDec extends InternalExpression {
  /// The accessed variable.
  final InternalVariable variable;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `a++` as
  /// opposed the prefix expression `++a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `a++` as opposed to `a--`.
  final bool isInc;

  /// The file offset of the name of the getter/setter, i.e. `a` in `a++`.
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  new({
    required this.variable,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.nameOffset,
    required this.operatorOffset,
  }) : super(fileOffset: nameOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitLocalIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.write(variable.cosmeticName!);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }
}

/// Internal expression representing a static member inc/dec expression.
///
/// A static postfix inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = v1 + 1 in v1
///
/// A static prefix inc/dec expression of the form `++a` or a postfix inc/dec
/// expression for effect is encoded as the expression:
///
///     a = a + 1
///
class StaticIncDec extends InternalExpression {
  /// The getter used to read the original value.
  final Member getter;

  /// The setter to which to updated value is assigned.
  final Member setter;

  /// The name of the accessed property.
  final Name name;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `a++` as
  /// opposed the prefix expression `++a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `a++` as opposed to `a--`.
  final bool isInc;

  /// The file offset of the name of the getter/setter, i.e. `a` in `a++`.
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  new({
    required this.getter,
    required this.setter,
    required this.name,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.nameOffset,
    required this.operatorOffset,
  }) : super(fileOffset: nameOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitStaticIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.writeName(name);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }
}

/// Internal expression representing a super member inc/dec expression.
///
/// A super postfix inc/dec expression of the form `super.a++` is encoded as
/// the expression:
///
///     let v1 = super.a in let v2 = super.a = v1 + 1 in v1
///
/// A super prefix inc/dec expression of the form `++super.a` or a postfix
/// inc/dec expression for effect is encoded as the expression:
///
///     super.a = super.a + 1
///
class SuperIncDec extends InternalExpression {
  /// The implicit this expression on which the getter/setter is accessed.
  final InternalThisExpression receiver;

  /// The getter used to read the original value.
  final Member getter;

  /// The setter to which to updated value is assigned.
  final Member setter;

  /// The name of the accessed property.
  final Name name;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form
  /// `super.a++` as opposed the prefix expression `++super.a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `super.a++` as opposed to
  /// `super.a--`.
  final bool isInc;

  /// The file offset of the name of the getter/setter, i.e. `a` in `super.a++`.
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  new({
    required this.receiver,
    required this.getter,
    required this.setter,
    required this.name,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.nameOffset,
    required this.operatorOffset,
  }) : super(fileOffset: nameOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitSuperIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.write('super.');
    printer.writeName(getter.name);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }
}

/// Internal expression representing an index get expression, `o[a]`.
class IndexGet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  final InternalExpression receiver;

  /// The index expression of the operation.
  final InternalExpression index;

  /// `true` if the access is null-aware, i.e. of the form `o?[a]`.
  final bool isNullAware;

  new(
    this.receiver,
    this.index, {
    required this.isNullAware,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIndexGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write(']');
  }
}

/// Internal expression representing an index set expression, `o[a] = b`.
///
/// An index set expression of the form `o[a] = b` used for value is encoded as
/// the expression:
///
///     let v1 = o in let v2 = a in let v3 = b in let _ = o.[]=(v2, v3) in v3
///
/// An index set expression used for effect is encoded as
///
///    o.[]=(a, b)
///
/// using [InstanceInvocation] or [DynamicInvocation].
///
class IndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  final InternalExpression receiver;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The value expression of the operation.
  final InternalExpression value;

  /// `true` if the assignment is for effect only, i.e the result value of the
  /// assignment is _not_ used.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form `o?[a] = b`.
  final bool isNullAware;

  new(
    this.receiver,
    this.index,
    this.value, {
    required this.forEffect,
    required this.isNullAware,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write('] = ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing a  super index set expression.
///
/// A super index set expression of the form `super[a] = b` used for value is
/// encoded as the expression:
///
///     let v1 = a in let v2 = b in let _ = super.[]=(v1, v2) in v2
///
/// An index set expression used for effect is encoded as
///
///    super.[]=(a, b)
///
/// using [SuperMethodInvocation].
///
class SuperIndexSet extends InternalExpression {
  /// The []= member.
  final Member setter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The value expression of the operation.
  final InternalExpression value;

  new({
    required this.setter,
    required this.index,
    required this.value,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitSuperIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super[');
    index.toTextInternal(printer);
    printer.write('] = ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing an extension index get expression.
///
/// An extension index set expression of the form `Extension(o)[a]` used
/// for value is encoded as the expression:
///
///     Extension|[](o, a)
///
/// using [StaticInvocation].
///
class ExtensionIndexGet extends InternalExpression {
  /// The extension in which the [getter] is declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension].
  final TypeArguments? explicitTypeArguments;

  /// The receiver of the extension access.
  final InternalExpression receiver;

  /// The [] procedure.
  final Procedure getter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?[a]`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new(
    this.extension,
    this.explicitTypeArguments,
    this.receiver,
    this.getter,
    this.index, {
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : assert(
         explicitTypeArguments == null ||
             explicitTypeArguments.types.length ==
                 extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIndexGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!.types);
    }
    printer.write('(');
    receiver.toTextInternal(printer);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write(']');
  }
}

/// Internal expression representing an extension index set expression.
///
/// An extension index set expression of the form `Extension(o)[a] = b` used
/// for value is encoded as the expression:
///
///     let valueVariable = b in '
///     let writeVariable =
///         Extension|[]=(o, a, valueVariable) in
///           valueVariable
///
/// An extension index set expression used for effect is encoded as
///
///    Extension|[]=(o, a, b)
///
/// using [StaticInvocation].
///
class ExtensionIndexSet extends InternalExpression {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension].
  final TypeArguments? explicitTypeArguments;

  /// The receiver of the extension access.
  final InternalExpression receiver;

  /// The []= procedure.
  final Procedure setter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The value expression of the operation.
  final InternalExpression value;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?[a] = b`.
  final bool isNullAware;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new(
    this.extension,
    this.explicitTypeArguments,
    this.receiver,
    this.setter,
    this.index,
    this.value, {
    required this.isNullAware,
    required this.forEffect,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : assert(
         explicitTypeArguments == null ||
             explicitTypeArguments.types.length ==
                 extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!.types);
    }
    printer.write('(');
    receiver.toTextInternal(printer);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write('] = ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing an if-null index assignment.
///
/// An if-null index assignment of the form `o[a] ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in
///     let v2 = a in
///     let v3 = v1[v2] in
///       v3 == null
///        ? (let v4 = b in
///           let _ = v1.[]=(v2, v4) in
///           v4)
///        : v3
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in
///     let v2 = a in
///     let v3 = v1[v2] in
///        v3 == null ? v1.[]=(v2, b) : null
///
/// If the [readOnlyReceiver] is true, no temporary variable is created for the
/// receiver and its use is inlined.
class IfNullIndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  final InternalExpression receiver;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The value expression of the operation.
  final InternalExpression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form `o?[a] ??= b`.
  final bool isNullAware;

  new({
    required this.receiver,
    required this.index,
    required this.value,
    required this.readOffset,
    required this.testOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.isNullAware,
  }) : super(fileOffset: testOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write('] ??= ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing an if-null super index set expression.
///
/// An if-null super index set expression of the form `super[a] ??= b` is, if
/// used for value, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///       v2 == null
///        ? (let v3 = b in
///           let _ = super.[]=(v1, v3) in
///           v3)
///        : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///        v2 == null ? super.[]=(v1, b) : null
///
class IfNullSuperIndexSet extends InternalExpression {
  /// The [] member;
  final Member? getter;

  /// The []= member;
  final Member? setter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The value expression of the operation.
  final InternalExpression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  new({
    required this.getter,
    required this.setter,
    required this.index,
    required this.value,
    required this.readOffset,
    required this.testOffset,
    required this.writeOffset,
    required this.forEffect,
  }) : super(fileOffset: testOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullSuperIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super[');
    index.toTextInternal(printer);
    printer.write('] ??= ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing an if-null extension index set expression.
///
/// An if-null super index set expression of the form `E(o)[a] ??= b` is, if
/// used for value, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///       v2 == null
///        ? (let v3 = b in
///           let _ = super.[]=(v1, v3) in
///           v3)
///        : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///        v2 == null ? super.[]=(v1, b) : null
///
class ExtensionIfNullIndexSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a()` or
  /// implied as in `a()` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The extension receiver;
  final InternalExpression receiver;

  /// The [] member;
  final Member getter;

  /// The []= member;
  final Member setter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The value expression of the operation.
  final InternalExpression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// `true` if the invocation is null-aware, i.e. of the form
  /// `E(o)?[a] ??= b`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new({
    required this.extension,
    required this.knownTypeArguments,
    required this.receiver,
    required this.getter,
    required this.setter,
    required this.index,
    required this.value,
    required this.readOffset,
    required this.testOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : assert(
         knownTypeArguments == null ||
             knownTypeArguments.length == extension.typeParameters.length,
       ),
       super(fileOffset: testOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIfNullIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (knownTypeArguments != null) {
      printer.writeTypeArguments(knownTypeArguments!);
    }
    printer.write('(');
    receiver.toTextInternal(printer);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write(']');
    printer.write(' ??= ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing a compound index assignment.
///
/// An if-null index assignment of the form `o[a] += b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in
///     let v2 = a in
///     let v3 = v1.[](v2) + b
///     let v4 = v1.[]=(v2, c3) in v3
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in let v2 = a in v1.[]=(v2, v1.[](v2) + b)
///
class CompoundIndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  final InternalExpression receiver;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The name of the binary operation.
  final Name binaryName;

  /// The right-hand side of the binary expression.
  final InternalExpression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a post-fix inc/dec expression.
  final bool forPostIncDec;

  /// `true` if the access is null-aware, i.e. of the form `o?[a] += b`.
  final bool isNullAware;

  new({
    required this.receiver,
    required this.index,
    required this.binaryName,
    required this.value,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.forPostIncDec,
    required this.isNullAware,
  }) : super(fileOffset: binaryOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCompoundIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write(']');
    if (forPostIncDec &&
        (binaryName.text == '+' || binaryName.text == '-') &&
        value is InternalIntLiteral &&
        (value as InternalIntLiteral).value == 1) {
      if (binaryName.text == '+') {
        printer.write('++');
      } else {
        printer.write('--');
      }
    } else {
      printer.write(' ');
      printer.write(binaryName.text);
      printer.write('= ');
      value.toTextInternal(printer);
    }
  }
}

/// Internal expression representing a compound super index assignment.
///
/// An if-null index assignment of the form `super[a] += b` is, if used for
/// value, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) + b
///     let v3 = super.[]=(v1, v2) in v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = a in super.[]=(v2, super.[](v2) + b)
///
class CompoundSuperIndexSet extends InternalExpression {
  /// The [] member.
  final Member getter;

  /// The []= member.
  final Member setter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The name of the binary operation.
  final Name binaryName;

  /// The right-hand side of the binary expression.
  final InternalExpression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a post-fix inc/dec expression.
  final bool forPostIncDec;

  new({
    required this.getter,
    required this.setter,
    required this.index,
    required this.binaryName,
    required this.value,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.forPostIncDec,
  }) : super(fileOffset: binaryOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCompoundSuperIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super[');
    index.toTextInternal(printer);
    printer.write(']');
    if (forPostIncDec &&
        (binaryName.text == '+' || binaryName.text == '-') &&
        value is InternalIntLiteral &&
        (value as InternalIntLiteral).value == 1) {
      if (binaryName.text == '+') {
        printer.write('++');
      } else {
        printer.write('--');
      }
    } else {
      printer.write(' ');
      printer.write(binaryName.text);
      printer.write('= ');
      value.toTextInternal(printer);
    }
  }
}

/// Internal expression representing a compound extension index assignment.
///
/// An compound extension index assignment of the form `Extension(o)[a] += b`
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = o;
///     let indexVariable = a in
///     let valueVariable = receiverVariable.[](indexVariable) + b
///     let writeVariable =
///       receiverVariable.[]=(indexVariable, valueVariable) in
///         valueVariable
///
/// and, if used for effect, encoded as the expression:
///
///     let receiverVariable = o;
///     let indexVariable = a in
///         receiverVariable.[]=(indexVariable,
///             receiverVariable.[](indexVariable) + b)
///
class ExtensionCompoundIndexSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension], if provided.
  final TypeArguments? explicitTypeArguments;

  /// The receiver used for the read/write operations.
  final InternalExpression receiver;

  /// The [] member.
  final Member getter;

  /// The []= member.
  final Member setter;

  /// The index expression of the operation.
  final InternalExpression index;

  /// The name of the binary operation.
  final Name binaryName;

  /// The right-hand side of the binary expression.
  final InternalExpression rhs;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a post-fix inc/dec expression.
  final bool forPostIncDec;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?[a] += b`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new({
    required this.extension,
    required this.explicitTypeArguments,
    required this.receiver,
    required this.getter,
    required this.setter,
    required this.index,
    required this.binaryName,
    required this.rhs,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.forPostIncDec,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : assert(
         explicitTypeArguments == null ||
             explicitTypeArguments.types.length ==
                 extension.typeParameters.length,
       ),
       super(fileOffset: binaryOffset);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionCompoundIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!.types);
    }
    printer.write('(');
    receiver.toTextInternal(printer);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write(']');
    if (forPostIncDec) {
      printer.write(binaryName == plusName ? '++' : '--');
    } else {
      printer.write(' ');
      printer.writeName(binaryName);
      printer.write('= ');
      rhs.toTextInternal(printer);
    }
  }
}

/// Internal expression representing a read of an explicit extension getter,
/// for instance `E(o).a` or `a` from within the extension `E`.
///
/// An extension get of the form `E(o).a` is encoded as the static
/// invocation:
///
///     E|a(o)
///
class ExtensionGet extends InternalExpression {
  /// The extension in which the [getter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a` or
  /// implied as in `a` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the read.
  final InternalExpression receiver;

  /// The name of getter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension member called for the assignment.
  final Procedure getter;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a` and
  /// not implicit like `a` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name name,
    required Procedure getter,
    required int fileOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         getter,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
         fileOffset: fileOffset,
       );

  new explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required InternalExpression receiver,
    required Name name,
    required Procedure getter,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
    required int fileOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         getter,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         fileOffset: fileOffset,
       );

  new _(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.getter, {
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
  }
}

/// Internal expression representing an assignment to an extension setter.
///
/// An extension set of the form `receiver.target = value` is, if used for
/// value, encoded as the expression:
///
///     let receiverVariable = receiver in
///     let valueVariable = value in
///     let writeVariable = target(receiverVariable, valueVariable) in
///        valueVariable
///
/// or if the receiver is read-only, like `this` or a final variable,
///
///     let valueVariable = value in
///     let writeVariable = target(receiver, valueVariable) in
///        valueVariable
///
/// and, if used for effect, encoded as a [StaticInvocation]:
///
///     target(receiver, value)
///
// TODO(johnniwinther): Rename read-only to side-effect-free.
class ExtensionSet extends InternalExpression {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a = b` or
  /// implied as in `a = b` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the assignment.
  final InternalExpression receiver;

  /// The name of setter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension member called for the assignment.
  final Procedure setter;

  /// The right-hand side value of the assignment.
  final InternalExpression value;

  /// If `true` the assignment is only needed for effect and not its result
  /// value.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a = b`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a = b` and
  /// not implicit like `a = b` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name name,
    required Procedure setter,
    required InternalExpression value,
    required bool forEffect,
    required int fileOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         setter,
         value,
         forEffect: forEffect,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
         fileOffset: fileOffset,
       );

  new explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required InternalExpression receiver,
    required Name name,
    required Procedure setter,
    required InternalExpression value,
    required bool forEffect,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
    required int fileOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         setter,
         value,
         forEffect: forEffect,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         fileOffset: fileOffset,
       );

  new _(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.setter,
    this.value, {
    required this.forEffect,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    value.toTextInternal(printer);
  }
}

/// Internal expression representing an invocation of an extension method.
///
/// An extension get of the form `receiver.target(arguments)` is encoded as the
/// static invocation:
///
///     target(receiver, arguments)
///
class ExtensionMethodInvocation extends InternalExpression {
  /// The extension in which the [method] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a()` or
  /// implied as in `a()` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the invocation.
  final InternalExpression receiver;

  /// The name of method.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension method called for the assignment.
  final Procedure method;

  /// The type arguments provided to the method, if any.
  final TypeArguments? typeArguments;

  /// The arguments provided to the method.
  final ActualArguments arguments;

  /// `true` if the extension access is explicit, i.e. `E(o).a()` and
  /// not implicit like `a()` inside the extension `E`.
  final bool _isExplicit;

  /// `true` if the invocation is null-aware, i.e. of the form
  /// `Extension(o)?.a()`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required int fileOffset,
  }) : this._(
         extension,
         thisAccess,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: false,
         knownTypeArguments: thisTypeArguments,
         extensionTypeArgumentOffset: null,
         isNullAware: false,
         fileOffset: fileOffset,
       );

  new explicit({
    required Extension extension,
    required InternalExpression receiver,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required List<DartType>? explicitTypeArguments,
    required int? extensionTypeArgumentOffset,
    required bool isNullAware,
    required int fileOffset,
  }) : this._(
         extension,
         receiver,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: true,
         knownTypeArguments: explicitTypeArguments,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         isNullAware: isNullAware,
         fileOffset: fileOffset,
       );

  new _(
    this.extension,
    this.receiver,
    this.name,
    this.method,
    this.typeArguments,
    this.arguments, {
    required this.knownTypeArguments,
    required bool isExplicit,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionMethodInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// Internal expression representing an invocation of an explicit extension
/// method, for instance `E(o).a()` or `a()` from within the extension `E`.
///
/// An extension get of the form `E(o).a(b)` is encoded as the static
/// invocation:
///
///     E|a(o, b)
///
class ExtensionGetterInvocation extends InternalExpression {
  /// The extension in which the [getter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a()` or
  /// implied as in `a()` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the invocation.
  final InternalExpression receiver;

  /// The name of getter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension getter called for the assignment.
  final Procedure getter;

  /// The type arguments provided to the getter, if any.
  final TypeArguments? typeArguments;

  /// The arguments provided to the getter.
  final ActualArguments arguments;

  /// `true` if the extension access is explicit, i.e. `E(o).a()` and
  /// not implicit like `a()` inside the extension `E`.
  final bool _isExplicit;

  /// `true` if the invocation is null-aware, i.e. of the form
  /// `Extension(o)?.a()`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required int fileOffset,
  }) : this._(
         extension,
         thisAccess,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: false,
         knownTypeArguments: thisTypeArguments,
         extensionTypeArgumentOffset: null,
         isNullAware: false,
         fileOffset: fileOffset,
       );

  new explicit({
    required Extension extension,
    required InternalExpression receiver,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required List<DartType>? explicitTypeArguments,
    required int? extensionTypeArgumentOffset,
    required bool isNullAware,
    required int fileOffset,
  }) : this._(
         extension,
         receiver,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: true,
         knownTypeArguments: explicitTypeArguments,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         isNullAware: isNullAware,
         fileOffset: fileOffset,
       );

  new _(
    this.extension,
    this.receiver,
    this.name,
    this.getter,
    this.typeArguments,
    this.arguments, {
    required this.knownTypeArguments,
    required bool isExplicit,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionGetterInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// Internal representation of a tear-foo of an extension instance method.
///
/// A tear-off of an extension instance member `o.foo()` is encoded as the
/// [StaticInvocation]
///
///     extension|get#foo(o)
///
/// where `extension|get#foo` is the top level method created for tearing off
/// the `foo` method.
class ExtensionTearOff extends InternalExpression {
  /// The extension in which the [method] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a` or
  /// implied as in `a` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the tear-off.
  final InternalExpression receiver;

  /// The name of method.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The top-level method that is that target for the read operation.
  final Procedure tearOff;

  /// `true` if the access is null-aware, i.e. of the form `Extension(o)?.a`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a` and
  /// not implicit like `a` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  new implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required InternalExpression thisAccess,
    required Name name,
    required Procedure tearOff,
    required int fileOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         tearOff,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
         fileOffset: fileOffset,
       );

  new explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required InternalExpression receiver,
    required Name name,
    required Procedure tearOff,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
    required int fileOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         tearOff,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         fileOffset: fileOffset,
       );

  new _(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.tearOff, {
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
    required super.fileOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      receiver.toTextInternal(printer);
      printer.write(')');
    } else {
      receiver.toTextInternal(printer);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
  }
}

/// Internal expression for an equals or not-equals expression.
class EqualsExpression extends InternalExpression {
  final InternalExpression left;
  final InternalExpression right;
  final bool isNot;

  new(this.left, this.right, {required this.isNot, required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitEquals(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    left.toTextInternal(printer /*, minimumPrecedence: Precedence.EQUALITY*/);
    if (isNot) {
      printer.write(' != ');
    } else {
      printer.write(' == ');
    }
    right.toTextInternal(
      printer /*minimumPrecedence: Precedence.EQUALITY + 1*/,
    );
  }
}

/// Internal expression for a binary expression.
class BinaryExpression extends InternalExpression {
  final InternalExpression left;
  final Name binaryName;
  final InternalExpression right;

  new(this.left, this.binaryName, this.right, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitBinary(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.binaryPrecedence[binaryName.text]!;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    left.toTextInternal(printer /*, minimumPrecedence: precedence*/);
    printer.write(' ${binaryName.text} ');
    right.toTextInternal(printer /*, minimumPrecedence: precedence*/);
  }
}

/// Internal expression for a unary expression.
class UnaryExpression extends InternalExpression {
  final Name unaryName;
  final InternalExpression expression;

  new(this.unaryName, this.expression, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitUnary(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.PREFIX;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (unaryName == unaryMinusName) {
      printer.write('-');
    } else {
      printer.write('${unaryName.text}');
    }
    // TODO(johnniwinther): Support precedence on internal expressions.
    expression.toTextInternal(printer /*, minimumPrecedence: precedence*/);
  }
}

/// Internal expression for a parenthesized expression.
class ParenthesizedExpression extends InternalExpression {
  final InternalExpression expression;

  new(this.expression, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitParenthesized(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.CALLEE;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    expression.toTextInternal(printer);
    printer.write(')');
  }
}

/// A dynamically bound method invocation of the form `o.a()`.
///
/// This will be transformed into an [InstanceInvocation], [DynamicInvocation],
/// [FunctionInvocation] or [StaticInvocation] (for implicit extension method
/// invocation) after type inference.
class MethodInvocation extends InternalExpression {
  /// The receiver of the invocation.
  final InternalExpression receiver;

  /// The name of the invoked method or property.
  final Name name;

  /// The type arguments applied at the invocation, if any.
  final TypeArguments? typeArguments;

  /// The arguments applied at the invocation.
  final ActualArguments arguments;

  /// `true` if the access is null-aware, i.e. of the form `o?.a()`.
  final bool isNullAware;

  /// `true` if the access is an implicit `this` access.
  final bool isImplicitThis;

  new(
    this.receiver,
    this.name,
    this.typeArguments,
    this.arguments, {
    required this.isNullAware,
    required this.isImplicitThis,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitMethodInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.PRIMARY;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    receiver.toTextInternal(
      printer /*, minimumPrecedence: Precedence.PRIMARY*/,
    );
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// A dynamically bound property read of the form `o.a`.
///
/// This will be transformed into an [InstanceGet], [InstanceTearOff],
/// [DynamicGet], [FunctionTearOff] or [StaticInvocation] (for implicit
/// extension member access) after type inference.
class PropertyGet extends InternalExpression {
  /// The receiver of the property access.
  final InternalExpression receiver;

  /// The name of the accessed property.
  final Name name;

  /// `true` if the access is null-aware, i.e. of the form `o?.a`.
  final bool isNullAware;

  /// `true` if the access is an implicit `this` access.
  final bool isImplicitThis;

  new(
    this.receiver,
    this.name, {
    required this.isNullAware,
    required this.isImplicitThis,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitPropertyGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.PRIMARY;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    receiver.toTextInternal(
      printer /*, minimumPrecedence: Precedence.PRIMARY*/,
    );
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
  }
}

/// A dynamically bound property write of the form `o.a = b`.
///
/// This will be transformed into an [InstanceSet], [DynamicSet], or
/// [StaticInvocation] (for implicit extension member access) after type
/// inference.
class PropertySet extends InternalExpression {
  /// The receiver of the assigned property.
  final InternalExpression receiver;

  /// The name of the assigned property.
  final Name name;

  /// The value assigned to the property.
  final InternalExpression value;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// If `true` the receiver can be cloned and doesn't need a temporary variable
  /// for multiple reads.
  final bool readOnlyReceiver;

  /// `true` if the access is null-aware, i.e. of the form `o?.a = b`.
  final bool isNullAware;

  /// `true` if the access is an implicit `this` access.
  final bool isImplicitThis;

  new(
    this.receiver,
    this.name,
    this.value, {
    required this.forEffect,
    required this.readOnlyReceiver,
    required this.isNullAware,
    required this.isImplicitThis,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitPropertySet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    receiver.toTextInternal(
      printer /*, minimumPrecedence: Precedence.PRIMARY*/,
    );
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    value.toTextInternal(printer);
  }
}

sealed class RecordField({
  required var InternalExpression value,
  required final int fileOffset,
});

class PositionalRecordField({required super.value, required super.fileOffset})
    extends RecordField;

class NamedRecordField({
  required final String name,
  required super.value,
  required super.fileOffset,
}) extends RecordField;

class InternalRecordLiteral extends InternalExpression {
  final List<RecordField> fields;
  final Map<String, NamedRecordField>? namedFields;
  final bool isConst;

  new({
    required this.fields,
    required this.namedFields,
    required this.isConst,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalRecordLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('(');
    String comma = '';
    for (RecordField field in fields) {
      printer.write(comma);
      switch (field) {
        case PositionalRecordField():
          field.value.toTextInternal(printer);
        case NamedRecordField():
          printer.write(field.name);
          printer.write(': ');
          field.value.toTextInternal(printer);
      }
      comma = ', ';
    }
    printer.write(')');
  }
}

class ExtensionTypeRedirectingInitializer extends InternalInitializer {
  final Procedure target;
  final ActualArguments arguments;

  new(this.target, this.arguments, {required super.fileOffset});

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitExtensionTypeRedirectingInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

class ExternalExtensionTypeRedirectingInitializer extends ExternalInitializer {
  final Procedure target;
  final Arguments arguments;

  new(this.target, this.arguments, {required int fileOffset}) {
    arguments.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  bool get isRedirectingInitializer => true;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }

  @override
  String toString() => '$runtimeType(${toStringInternal()})';
}

/// Internal expression for an explicit initialization of an extension type
/// declaration representation field.
class ExtensionTypeRepresentationFieldInitializer extends InternalInitializer {
  /// [Procedure] that represents the representation field.
  final Procedure field;
  final InternalExpression value;

  new(this.field, this.value, {required super.fileOffset})
    : assert(field.stubKind == ProcedureStubKind.RepresentationField);

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitExtensionTypeRepresentationFieldInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(field.reference);
    printer.write(" = ");
    value.toTextInternal(printer);
  }
}

/// Internal expression for an explicit initialization of an extension type
/// declaration representation field.
class ExternalExtensionTypeRepresentationFieldInitializer
    extends ExternalInitializer {
  /// [Procedure] that represents the representation field.
  final Procedure field;
  final Expression value;

  new(this.field, this.value, {required int fileOffset})
    : assert(field.stubKind == ProcedureStubKind.RepresentationField) {
    value.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(field.reference);
    printer.write(" = ");
    value.toTextInternal(printer);
  }

  @override
  String toString() => '$runtimeType(${toStringInternal()})';
}

/// Internal expression for a dot shorthand.
///
/// This node wraps around the [innerExpression] and indicates to the
/// [InferenceVisitor] that we need to save the context type of the expression.
class DotShorthand extends InternalExpression {
  /// The entire dot shorthand expression (e.g. `.zero` or `.parse(input)`).
  final InternalExpression innerExpression;

  new(this.innerExpression, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDotShorthand(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    innerExpression.toTextInternal(printer);
  }
}

/// Internal expression for a dot shorthand head with arguments.
/// (e.g. `.parse(42)`).
///
/// This node could represent a shorthand of a static method or a named
/// constructor.
class DotShorthandInvocation extends InternalExpression {
  final Name name;
  final int nameOffset;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  new(
    this.name,
    this.typeArguments,
    this.arguments, {
    required this.nameOffset,
    required this.isConst,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDotShorthandInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// Internal expression for a dot shorthand head with no arguments.
/// (e.g. `.zero`).
///
/// This node could represent a shorthand of a static get or a tearoff.
class DotShorthandPropertyGet extends InternalExpression {
  final Name name;
  final int nameOffset;

  /// Whether this dot shorthand has type parameters.
  ///
  /// Used for error checking for constructors with type parameters in the
  /// [InferenceVisitor].
  bool hasTypeParameters;

  new(
    this.name, {
    required this.nameOffset,
    this.hasTypeParameters = false,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDotShorthandPropertyGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('.');
    printer.writeName(name);
  }
}

class InternalConstructorInvocation extends InternalExpression {
  final Constructor target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;
  final bool isConst;

  new({
    required this.target,
    required this.typeArguments,
    required this.arguments,
    required this.isConst,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalConstructorInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

class InternalStaticInvocation extends InternalExpression {
  final Name name;
  final Procedure target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  new(
    this.name,
    this.target,
    this.typeArguments,
    this.arguments, {
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStaticInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

class InternalSuperMethodInvocation extends InternalExpression {
  final Name name;
  final Procedure target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  new(
    this.name,
    this.typeArguments,
    this.arguments,
    this.target, {
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSuperMethodInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

class InternalRedirectingInitializer extends InternalInitializer {
  final Constructor target;
  final ActualArguments arguments;

  new(this.target, this.arguments, {required super.fileOffset});

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalRedirectingInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

class InternalSuperInitializer extends InternalInitializer {
  final Constructor target;
  final ActualArguments arguments;

  final bool isSynthetic;

  new(
    this.target,
    this.arguments, {
    required this.isSynthetic,
    required super.fileOffset,
  });

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalSuperInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Internal node for encoding the "element" of a for-in loop.
///
/// The element is the part before "in" which can either an identifier or
/// a single variable declaration.
sealed class InternalForInElement({required super.fileOffset})
    extends InternalNode {
  /// Infers the for-in element and the [iterable].
  ForInHeaderResult inferForInHeader(
    InferenceVisitorBase visitor, {
    required InternalNode node,
    required InternalExpression iterable,
    required bool isAsync,
    required int forOffset,
  });
}

/// Base implementation for non-pattern for-in elements.
sealed class _BaseForInElement({required super.fileOffset})
    extends InternalForInElement {
  InternalVariable? get _declaredVariable => null;

  /// Computes the type context from the element. This is type context used for
  /// inferring the for-in iterable.
  DartType _computeElementTypeContext(InferenceVisitorBase visitor);

  /// Computes the [Variable] that will be used in the emitted
  /// [ForInStatement].
  ///
  /// This can be the variable declared as the for-in element or a synthetic
  /// variable, when there is no declared variable or it doesn't suffice for
  /// the correct runtime behavior.
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  });

  /// Computes the [ForInEncoding] for the additional nodes needed for the
  /// assignment to the for-in element.
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  });

  /// Helper for creating a synthetic variable declaration for the emitted
  /// [ForInStatement].
  SyntheticVariable _createSyntheticVariableDeclaration(
    DartType type, {
    required int forOffset,
  }) {
    return extern.createUninitializedVariable(
      type: type,
      fileOffset: forOffset,
      isFinal: true,
    );
  }

  @override
  ForInHeaderResult inferForInHeader(
    InferenceVisitorBase visitor, {
    required InternalNode node,
    required InternalExpression iterable,
    required bool isAsync,
    required int forOffset,
  }) {
    DartType elementTypeContext = _computeElementTypeContext(visitor);

    ExpressionInferenceResult iterableResult = visitor.inferForInIterable(
      iterable,
      elementTypeContext,
      isAsync: isAsync,
    );
    DartType inferredType = iterableResult.inferredType;
    DeclaredVariable variable = _computeLoopVariable(
      visitor,
      inferredType,
      forOffset: forOffset,
    );

    return new ForInHeaderResult(
      declaredVariable: _declaredVariable,
      loopVariable: variable,
      iterable: iterableResult.expression,
      computeEncoding: () => _computeEncoding(visitor, loopVariable: variable),
    );
  }
}

/// For-in element for a single declared variable.
class SingleVariableDeclarationForInElement extends _BaseForInElement {
  /// Error that must be emitted prior to the generated for-in statement.
  ///
  /// This is used for instance for constant loop variables.
  final InternalInvalidExpression? error;

  /// If the assignment to [_variable] needs additional steps, like
  /// a type coercion, this holds a synthetic variable declaration used as an
  /// intermediate step.
  VariableDeclaration? _variableForSideEffect;

  /// The declared variable.
  final InternalVariableDeclaration variableDeclaration;

  new({required this.variableDeclaration, required this.error})
    : super(fileOffset: variableDeclaration.fileOffset);

  @override
  InternalVariable get _declaredVariable => variableDeclaration.variable;

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    DeclaredVariable loopVariable = variableDeclaration.variable._astVariable;
    DartType loopVariableType;
    bool checkAssignment = true;
    if (variableDeclaration.variable.isImplicitlyTyped) {
      loopVariableType = variableDeclaration.variable.type = type;
      checkAssignment = false;
    } else {
      loopVariableType = variableDeclaration.variable.type;
    }
    if (checkAssignment) {
      SyntheticVariable tempVariable = _createSyntheticVariableDeclaration(
        type,
        forOffset: forOffset,
      );
      ExpressionInferenceResult canary = new ExpressionInferenceResult(
        type,
        extern.createVariableGet(
          tempVariable,
          fileOffset: loopVariable.fileOffset,
        ),
      );
      ExpressionInferenceResult assignmentResult = visitor
          .ensureAssignableResult(
            loopVariableType,
            canary,
            isVoidAllowed: true,
            errorTemplate: diag.forInLoopElementTypeNotAssignable,
            assignedNode: this,
          );
      if (!identical(assignmentResult, canary)) {
        // Something happened during assignment, like an error or a type
        // coercion, so we need to use the temp variable as the loop variable
        // and assign to the declared variable in the loop.
        Expression initializer = assignmentResult.expression;
        // visitor.flowAnalysis.declare(
        //   internalLoopVariable,
        //   new SharedTypeView(loopVariableType),
        //   initialized: true,
        // );
        _variableForSideEffect = extern.createVariableDeclaration(
          loopVariable,
          initializer: initializer,
        );
        loopVariable = tempVariable;
      }
    }
    return loopVariable;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      preLoopError: error != null
          ? extern.createInvalidExpression(
              error!.message,
              fileOffset: error!.fileOffset,
            )
          : null,
      bodyPrologue: _variableForSideEffect != null
          ? extern.createVariableStatement(_variableForSideEffect!)
          : null,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableInitialization(
      variableDeclaration.variable._astVariable,
      isImplicitlyTyped: variableDeclaration.variable.isImplicitlyTyped,
    );
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    if (variableDeclaration.variable case InternalVariable variable) {
      if (variable.isImplicitlyTyped) {
        return const UnknownType();
      }
    }
    return variableDeclaration.variable.type;
  }
}

/// For-in element for a multi-variable declaration, like
/// `for (var a, b in [])`. This is an error case.
class MultiVariableDeclarationForInElement extends _BaseForInElement {
  /// The declared variables.
  final List<InternalVariableDeclaration> variableDeclarations;

  /// The error that should be emitted prior to the for-in statement.
  final InternalInvalidExpression error;

  new({
    required this.variableDeclarations,
    required this.error,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    for (int i = 0; i < variableDeclarations.length; i++) {
      InternalVariableDeclaration variableDeclaration = variableDeclarations[i];
      if (i == 0) {
        printer.writeVariableInitialization(
          variableDeclaration.variable._astVariable,
          includeModifiersAndType: true,
          isImplicitlyTyped: variableDeclaration.variable.isImplicitlyTyped,
        );
      } else {
        printer.write(', ');
        printer.writeVariableInitialization(
          variableDeclaration.variable._astVariable,
          includeModifiersAndType: false,
        );
      }
    }
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) =>
      const UnknownType();

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      preLoopError: extern.createInvalidExpression(
        error.message,
        fileOffset: error.fileOffset,
      ),
      bodyPrologue: extern.createBlock([
        for (InternalVariableDeclaration variableDeclaration
            in variableDeclarations)
          extern.createVariableStatement(
            extern.createVariableDeclaration(
              variableDeclaration.variable._astVariable,
              fileOffset: variableDeclaration.fileOffset,
            ),
          ),
      ], fileOffset: TreeNode.noOffset),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: forOffset);
  }
}

/// For-in element for an unassignable expression, like `for (1 in [])`. This is
/// an error case.
class UnassignableForInElement extends _BaseForInElement {
  /// The unassignable expression.
  final InternalExpression expression;

  /// The error that should be emitted prior to the for-in statement.
  final InternalInvalidExpression error;

  new({required this.expression, required this.error})
    : super(fileOffset: expression.fileOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) =>
      const UnknownType();

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      preLoopError: extern.createInvalidExpression(
        error.message,
        fileOffset: error.fileOffset,
      ),
      bodyPrologue: extern.createBlock([
        extern.createExpressionStatement(
          visitor.inferExpression(expression, const UnknownType()).expression,
        ),
      ], fileOffset: TreeNode.noOffset),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: forOffset);
  }
}

/// For-in element for a pattern variable declaration.
class PatternForInElement extends InternalForInElement {
  /// The pattern used in the variable declaration.
  final InternalPattern pattern;

  /// The file offset of the `in` keyword.
  final int inOffset;

  new({required this.pattern, required this.inOffset})
    : super(fileOffset: pattern.fileOffset);

  @override
  ForInHeaderResult inferForInHeader(
    InferenceVisitorBase visitor, {
    required InternalNode node,
    required InternalExpression iterable,
    required bool isAsync,
    required int forOffset,
  }) {
    PatternForInData data = visitor.inferPatternForInHeader(
      node: node,
      pattern: pattern,
      iterable: iterable,
      isAsync: isAsync,
      inOffset: inOffset,
    );
    return new ForInHeaderResult(
      declaredVariable: null,
      loopVariable: data.loopVariable,
      iterable: data.iterable,
      computeEncoding: () => new ForInEncoding(
        bodyPrologue: data.computePatternVariableDeclaration(),
      ),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('var ');
    pattern.toTextInternal(printer);
  }
}

/// For-in element for an erroneous expression.
class InvalidForInElement extends _BaseForInElement {
  /// The error for the erroneous expression.
  final InternalInvalidExpression error;

  /// The file offset of the `in` keyword.
  final int inOffset;

  new({required this.error, required this.inOffset})
    : super(fileOffset: error.fileOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    error.toTextInternal(printer);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) =>
      const UnknownType();

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      bodyPrologue: extern.createBlock([
        extern.createExpressionStatement(
          extern.createInvalidExpression(
            error.message,
            fileOffset: error.fileOffset,
          ),
        ),
      ], fileOffset: TreeNode.noOffset),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: forOffset);
  }
}

/// For-in element for an existing variable, like `for (a in [])` where `a` is
/// an already defined local variable.
class ExistingVariableForInElement extends _BaseForInElement {
  /// The variable used as the for-in element.
  final InternalVariable variable;

  /// The file offset of the variable name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// Error that must be emitted prior to the generated for-in statement.
  ///
  /// This is used for instance for a final local variable.
  final InternalInvalidExpression? error;

  new({
    required this.variable,
    required this.nameOffset,
    required this.inOffset,
    this.error,
  }) : super(fileOffset: nameOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName!);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    DartType? promotedType = visitor.flowAnalysis
        .promotedType(variable)
        ?.unwrapTypeView();
    return promotedType ?? variable.type;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferVariableSet(
      node: this,
      variable: variable,
      variableType: variable.type,
      rhsResult: new ExpressionInferenceResult(
        loopVariable.type,
        error != null
            ? extern.createInvalidExpression(
                error!.message,
                fileOffset: error!.fileOffset,
              )
            : extern.createVariableGet(loopVariable),
      ),
      assignOffset: inOffset,
      nameOffset: nameOffset,
      valueNode: this,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: inOffset);
  }
}

/// For-in element for a property access, like `for (a in [])` where `a` is an
/// instance field in the enclosing class.
class PropertyForInElement extends _BaseForInElement {
  /// The implicit `this` expression on which the property write is performed.
  final InternalExpression receiver;

  /// The name of the accessed instance member.
  final Name name;

  /// The file offset of the property name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// Data computed during [_computeElementTypeContext] for use in
  /// [_computeEncoding].
  late final PropertySetData _data;

  new({
    required this.receiver,
    required this.name,
    required this.nameOffset,
    required this.inOffset,
  }) : super(fileOffset: nameOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(name);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    _data = visitor.computePropertySetData(
      receiver: receiver,
      name: name,
      fileOffset: nameOffset,
      isNullAware: false,
    );
    return _data.writeContext;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferPropertySet(
      fileOffset: nameOffset,
      receiver: _data.receiver,
      receiverType: _data.receiverType,
      propertyName: name,
      writeTarget: _data.target,
      writeContext: _data.writeContext,
      valueResult: new ExpressionInferenceResult(
        loopVariable.type,
        extern.createVariableGet(loopVariable),
      ),
      forEffect: true,
      valueNode: this,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: inOffset);
  }
}

/// For-in element for a property access, like `for (a in [])` where `a` is a
/// top-level field.
class StaticForInElement extends _BaseForInElement {
  /// The accessed property.
  final Member target;

  /// The file offset of the property name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// The property type computed during [_computeElementTypeContext] for use in
  /// [_computeEncoding].
  late final DartType _writeContext;

  new({required this.target, required this.nameOffset, required this.inOffset})
    : super(fileOffset: nameOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(target.name);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    return _writeContext = visitor.computeStaticSetWriteContext(target);
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferStaticSet(
      member: target,
      rhsResult: new ExpressionInferenceResult(
        loopVariable.type,
        extern.createVariableGet(loopVariable),
      ),
      writeContext: _writeContext,
      assignOffset: inOffset,
      nameOffset: nameOffset,
      valueNode: this,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: inOffset);
  }
}

/// For-in element for a property access, like `for (a in [])` where `a` is an
/// instance getter in the enclosing extension.
class ExtensionForInElement extends _BaseForInElement {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a = b` or
  /// implied as in `a = b` from within the extension `E`.
  final List<DartType>? thisTypeArguments;

  /// The receiver for the assignment.
  InternalExpression thisAccess;

  /// The name of setter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension member called for the assignment.
  Procedure setter;

  /// The file offset of the property name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// Data computed during [_computeElementTypeContext] for use in
  /// [_computeEncoding].
  late final ExtensionSetData _data;

  new({
    required this.extension,
    required this.thisTypeArguments,
    required this.thisAccess,
    required this.name,
    required this.setter,
    required this.nameOffset,
    required this.inOffset,
  }) : assert(
         thisTypeArguments == null ||
             // Coverage-ignore(suite): Not run.
             extension.typeParameters.isNotEmpty &&
                 thisTypeArguments.length == extension.typeParameters.length,
       ),
       super(fileOffset: nameOffset);

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(name);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    _data = visitor.computeExtensionSetData(
      extension: extension,
      knownTypeArguments: thisTypeArguments,
      receiver: thisAccess,
      extensionTypeArgumentOffset: null,
      setter: setter,
      isNullAware: false,
      fileOffset: nameOffset,
      valueNode: this,
    );
    return _data.valueType;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferExtensionSet(
      data: _data,
      valueResult: new ExpressionInferenceResult(
        loopVariable.type,
        extern.createVariableGet(loopVariable),
      ),
      forEffect: true,
      fileOffset: nameOffset,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  DeclaredVariable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
  }) {
    return _createSyntheticVariableDeclaration(type, forOffset: inOffset);
  }
}

/// Encoding of additional nodes need for correct runtime behavior of a for-in
/// loop.
class ForInEncoding {
  /// Error that needs to be thrown before trying to execute the loop.
  final InvalidExpression? preLoopError;

  /// Statement that needs to be executed before the loop body.
  ///
  /// This can contain variable declarations for variables used in the loop and
  /// must therefore be emitted in the same block as the body content.
  final Statement? bodyPrologue;

  new({this.preLoopError, this.bodyPrologue});

  @override
  String toString() => 'ForInStatementResult($preLoopError,$bodyPrologue)';
}

/// The result of inferring a for-in loop element and iterable.
class ForInHeaderResult {
  /// The [InternalVariable] declared in the for-in statement, if any.
  final InternalVariable? declaredVariable;

  /// The [Variable] that should be used as the variable in the
  /// emitted [ForInStatement].
  final DeclaredVariable loopVariable;

  /// The [Expression] that should be used as the iterable in the emitted
  /// [ForInStatement].
  final Expression iterable;

  /// Function that computes the [ForInEncoding] need for the for-in element.
  ///
  /// This must be called between [FlowAnalysis.forEach_bodyBegin] and
  /// [FlowAnalysis.forEach_end] to ensure the effect of the encoding is seen
  /// as being part of the loop body.
  final ForInEncoding Function() computeEncoding;

  new({
    required this.declaredVariable,
    required this.loopVariable,
    required this.iterable,
    required this.computeEncoding,
  });

  @override
  String toString() =>
      'ForInHeaderResult($loopVariable,$iterable,$computeEncoding)';
}

/// Internal node for a for-in loop statement.
class InternalForInStatement extends InternalLoopStatement {
  /// The element of the for-in loop.
  ///
  /// For instance 'x' and 'var x' in
  ///
  ///     for (x in list) {}
  ///     for (var x in list) {}
  ///
  final InternalForInElement element;

  /// The iterable of the for-in loop.
  ///
  /// For instance 'x' in
  ///
  ///     for (var e in x) {}
  ///     await for (var e in x) {}
  ///
  final InternalExpression iterable;

  /// The for-in loop body.
  final InternalStatement body;

  /// Whether the for-in loop is asynchronous.
  final bool isAsync;

  /// The file offset for the for-in body.
  final int bodyOffset;

  new(
    this.element,
    this.iterable,
    this.body, {
    required this.isAsync,
    required super.fileOffset,
    required this.bodyOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalForInStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isAsync) {
      printer.write('async ');
    }
    printer.write('for (');
    element.toTextInternal(printer);
    printer.write(' in ');
    iterable.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

class InternalVariableGet extends InternalExpression {
  /// The target variable.
  final InternalVariable variable;

  new(this.variable, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalVariableGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName ?? '<unnamed-variable>');
  }
}

class InternalVariableSet extends InternalExpression {
  /// The target variable.
  final InternalVariable variable;

  InternalExpression value;

  new(this.variable, this.value, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalVariableSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName ?? '<unnamed-variable>');
    printer.write(' = ');
    value.toTextInternal(printer);
  }
}

class InternalFunctionNode extends InternalNode {
  final DartType? returnType;
  final List<TypeParameter> typeParameters;
  final List<InternalPositionalParameter> positionalParameters;
  final List<InternalNamedParameter> namedParameters;
  final int requiredParameterCount;
  final AsyncMarker asyncMarker;
  final InternalStatement? body;
  final int fileEndOffset;

  new({
    required this.returnType,
    required this.typeParameters,
    required this.positionalParameters,
    required this.namedParameters,
    required this.requiredParameterCount,
    required this.asyncMarker,
    required this.body,
    required super.fileOffset,
    required this.fileEndOffset,
  });

  FunctionType computeFunctionType() {
    return FunctionNode.computeFunctionTypeFromData(
      returnType: returnType ?? const DynamicType(),
      typeParameters: typeParameters,
      // TODO(johnniwinther): Can we avoid creating a list of ast variables?
      positionalParameters: [
        for (InternalPositionalParameter parameter in positionalParameters)
          parameter._astVariable,
      ],
      namedParameters: [
        for (InternalNamedParameter parameter in namedParameters)
          parameter._astVariable,
      ],
      nullability: Nullability.nonNullable,
      requiredParameterCount: requiredParameterCount,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer, {String name = ''}) {
    if (returnType != null) {
      printer.writeType(returnType!);
      printer.write(' ');
    }
    printer.write(name);
    if (typeParameters.isNotEmpty) {
      printer.write('<');
      for (int index = 0; index < typeParameters.length; index++) {
        if (index > 0) {
          printer.write(', ');
        }
        printer.write(typeParameters[index].name ?? '');
        printer.write(' extends ');
        printer.writeType(typeParameters[index].bound);
      }
      printer.write('>');
    }
    printer.write('(');
    for (int index = 0; index < positionalParameters.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      if (index == requiredParameterCount) {
        printer.write('[');
      }
      positionalParameters[index].toTextInternal(printer);
    }
    if (requiredParameterCount < positionalParameters.length) {
      printer.write(']');
    }
    if (namedParameters.isNotEmpty) {
      if (positionalParameters.isNotEmpty) {
        printer.write(', ');
      }
      printer.write('{');
      for (int index = 0; index < namedParameters.length; index++) {
        if (index > 0) {
          printer.write(', ');
        }
        namedParameters[index].toTextInternal(printer);
      }
      printer.write('}');
    }
    printer.write(')');
    InternalStatement? body = this.body;
    if (body != null) {
      if (body is InternalReturnStatement) {
        printer.write(' => ');
        body.expression!.toTextInternal(printer);
      } else {
        printer.write(' ');
        body.toTextInternal(printer);
      }
    } else {
      printer.write(';');
    }
  }
}

class InternalFunctionExpression extends InternalExpression {
  final InternalFunctionNode function;

  new({required this.function, required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalFunctionExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    function.toTextInternal(printer);
  }
}

class InternalFunctionDeclaration extends InternalStatement {
  final InternalLocalFunctionVariable variable;
  late final InternalFunctionNode function;
  late final bool hasImplicitReturnType;

  new({required this.variable, required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalFunctionDeclaration(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    function.toTextInternal(printer, name: variable.cosmeticName ?? '');
    if (function.body is ReturnStatement) {
      printer.write(';');
    }
  }
}

sealed class InternalPattern({required super.fileOffset}) extends InternalNode {
  /// Returns the variable name that this pattern defines, if any.
  ///
  /// This is used to derive an implicit variable name from a pattern to use
  /// on object patterns. For instance
  ///
  ///    if (o case Foo(:var bar, :var baz!)) { ... }
  ///
  /// the getter names 'bar' and 'baz' are implicitly defined by the patterns.
  String? get variableName => null;

  /// Variable declarations induced by nested variable patterns.
  ///
  /// These variables are initialized to the values captured by the variable
  /// patterns nested in the pattern.
  List<InternalDeclaredVariable> get declaredVariables;

  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  );
}

/// An [InternalPattern] for `pattern || pattern`.
class InternalOrPattern extends InternalPattern {
  final InternalPattern left;
  final InternalPattern right;

  final List<InternalDeclaredVariable> orPatternJointVariables;

  @override
  List<InternalDeclaredVariable> get declaredVariables =>
      orPatternJointVariables;

  new(
    this.left,
    this.right, {
    required this.orPatternJointVariables,
    required super.fileOffset,
  });

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalOrPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' || ');
    right.toTextInternal(printer);
  }
}

/// An [InternalPattern] for `pattern && pattern`.
class InternalAndPattern extends InternalPattern {
  final InternalPattern left;
  final InternalPattern right;

  @override
  List<InternalDeclaredVariable> get declaredVariables => [
    ...left.declaredVariables,
    ...right.declaredVariables,
  ];

  new(this.left, this.right, {required super.fileOffset});

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalAndPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' && ');
    right.toTextInternal(printer);
  }
}

/// An [InternalPattern] based on a constant [InternalExpression].
class InternalConstantPattern extends InternalPattern {
  final InternalExpression expression;

  new({required this.expression, required super.fileOffset});

  @override
  List<InternalDeclaredVariable> get declaredVariables => const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalConstantPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }
}

class InternalAssignedVariablePattern extends InternalPattern {
  final InternalVariable variable;

  new(this.variable, {required super.fileOffset});

  @override
  List<InternalDeclaredVariable> get declaredVariables => const [];

  @override
  String get variableName => variable.cosmeticName!;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalAssignedVariablePattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName!);
  }
}

/// An [InternalPattern] for `pattern as type`.
class InternalCastPattern extends InternalPattern {
  final InternalPattern pattern;
  final DartType type;

  new(this.pattern, this.type, {required super.fileOffset});

  @override
  String? get variableName => pattern.variableName;

  @override
  List<InternalDeclaredVariable> get declaredVariables =>
      pattern.declaredVariables;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalCastPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' as ');
    printer.writeType(type);
  }
}

class InternalInvalidPattern extends InternalPattern {
  final InternalInvalidExpression invalidExpression;

  @override
  final List<InternalDeclaredVariable> declaredVariables;

  new({
    required this.invalidExpression,
    required this.declaredVariables,
    required super.fileOffset,
  });

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalInvalidPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    invalidExpression.toTextInternal(printer);
  }
}

/// An [InternalPattern] for `<typeArgument>[pattern0, ... patternN]`.
class InternalListPattern extends InternalPattern {
  /// The element type argument as specified by the list pattern syntax.
  DartType? typeArgument;

  List<InternalPattern> patterns;

  @override
  List<InternalDeclaredVariable> get declaredVariables => [
    for (InternalPattern pattern in patterns) ...pattern.declaredVariables,
  ];

  new({
    required this.typeArgument,
    required this.patterns,
    required super.fileOffset,
  });

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalListPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (typeArgument != null) {
      printer.write('<');
      printer.writeType(typeArgument!);
      printer.write('>');
    }
    printer.write('[');
    String comma = '';
    for (InternalPattern pattern in patterns) {
      printer.write(comma);
      pattern.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(']');
  }
}

class InternalMapPattern extends InternalPattern {
  /// The key type arguments as specific in the map pattern syntax.
  DartType? keyType;

  /// The value type arguments as specific in the map pattern syntax.
  DartType? valueType;

  final List<InternalMapPatternEntry> entries;

  @override
  List<InternalDeclaredVariable> get declaredVariables => [
    for (InternalMapPatternEntry entry in entries)
      if (entry is! InternalMapPatternRestEntry)
        ...entry.value.declaredVariables,
  ];

  new({
    required this.keyType,
    required this.valueType,
    required this.entries,
    required super.fileOffset,
  }) : assert((keyType == null) == (valueType == null));

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalMapPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (keyType != null && valueType != null) {
      printer.writeTypeArguments([keyType!, valueType!]);
    }
    printer.write('{');
    String comma = '';
    for (InternalMapPatternEntry entry in entries) {
      printer.write(comma);
      entry.toTextInternal(printer);
      comma = ', ';
    }
    printer.write('}');
  }
}

class InternalMapPatternEntry extends InternalNode {
  final InternalExpression key;
  final InternalPattern value;

  new({required this.key, required this.value, required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    key.toTextInternal(printer);
    printer.write(': ');
    value.toTextInternal(printer);
  }
}

class InternalMapPatternRestEntry extends InternalNode
    implements InternalMapPatternEntry {
  new({required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  InternalExpression get key => throw new UnsupportedError('$runtimeType.key');

  @override
  // Coverage-ignore(suite): Not run.
  InternalPattern get value => throw new UnsupportedError('$runtimeType.value');

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
  }
}

class InternalNamedPattern extends InternalPattern {
  final String name;
  final InternalPattern pattern;

  @override
  List<InternalDeclaredVariable> get declaredVariables =>
      pattern.declaredVariables;

  new({required this.name, required this.pattern, required super.fileOffset});

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    // InternalNamedPattern isn't a real pattern; this code should never be
    // reached.
    throw new StateError(
      '$runtimeType.acceptInference should never be reached',
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    pattern.toTextInternal(printer);
  }
}

/// An [InternalPattern] for `pattern!`.
class InternalNullAssertPattern extends InternalPattern {
  final InternalPattern pattern;

  new({required this.pattern, required super.fileOffset});

  @override
  String? get variableName => pattern.variableName;

  @override
  List<InternalDeclaredVariable> get declaredVariables =>
      pattern.declaredVariables;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalNullAssertPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('!');
  }
}

/// An [InternalPattern] for `pattern?`.
class InternalNullCheckPattern extends InternalPattern {
  final InternalPattern pattern;

  new({required this.pattern, required super.fileOffset});

  @override
  String? get variableName => pattern.variableName;

  @override
  List<InternalDeclaredVariable> get declaredVariables =>
      pattern.declaredVariables;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalNullCheckPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('?');
  }
}

class InternalObjectPattern extends InternalPattern {
  /// The type specified as part of the object pattern syntax.
  DartType requiredType;

  final List<InternalNamedPattern> fields;

  /// If the type name in the object pattern refers to a typedef, the typedef in
  /// question; otherwise `null`.
  final Typedef? typedef;

  /// Indicates whether the object pattern included explicit type arguments; if
  /// `true` this means that no further type inference needs to be performed.
  final bool hasExplicitTypeArguments;

  new({
    required this.requiredType,
    required this.fields,
    required this.typedef,
    required this.hasExplicitTypeArguments,
    required super.fileOffset,
  });

  @override
  List<InternalDeclaredVariable> get declaredVariables {
    return [
      for (InternalNamedPattern field in fields) ...field.declaredVariables,
    ];
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalObjectPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeType(requiredType);
    printer.write('(');
    String comma = '';
    for (InternalPattern field in fields) {
      printer.write(comma);
      field.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(')');
  }
}

class InternalRecordPattern extends InternalPattern {
  final List<InternalPattern> patterns;

  @override
  List<InternalDeclaredVariable> get declaredVariables => [
    for (InternalPattern pattern in patterns) ...pattern.declaredVariables,
  ];

  new({required this.patterns, required super.fileOffset});

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalRecordPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    String comma = '';
    for (InternalPattern pattern in patterns) {
      printer.write(comma);
      pattern.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(')');
  }
}

/// An [InternalPattern] for `operator expression` where `operator  is either
/// ==, !=, <, <=, >, or >=.
class InternalRelationalPattern extends InternalPattern {
  final RelationalPatternKind kind;
  final InternalExpression expression;

  new({
    required this.kind,
    required this.expression,
    required super.fileOffset,
  });

  @override
  List<InternalDeclaredVariable> get declaredVariables => const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalRelationalPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    switch (kind) {
      case RelationalPatternKind.equals:
        printer.write('== ');
        break;
      case RelationalPatternKind.notEquals:
        printer.write('!= ');
        break;
      case RelationalPatternKind.lessThan:
        printer.write('< ');
        break;
      case RelationalPatternKind.lessThanEqual:
        printer.write('<= ');
        break;
      case RelationalPatternKind.greaterThan:
        printer.write('> ');
        break;
      case RelationalPatternKind.greaterThanEqual:
        printer.write('>= ');
        break;
    }
    expression.toTextInternal(printer);
  }
}

class InternalRestPattern extends InternalPattern {
  InternalPattern? subPattern;

  new({required this.subPattern, required super.fileOffset});

  @override
  List<InternalDeclaredVariable> get declaredVariables =>
      subPattern?.declaredVariables ?? const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    // InternalRestPattern isn't a real pattern; this code should never be
    // reached.
    throw new StateError(
      '$runtimeType.acceptInference should never be reached',
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (subPattern != null) {
      subPattern!.toTextInternal(printer);
    }
  }
}

class InternalVariablePattern extends InternalPattern {
  // TODO(johnniwinther): Should this be accessed through [variable] instead?
  final DartType? type;
  final InternalDeclaredVariable variable;

  @override
  List<InternalDeclaredVariable> get declaredVariables => [variable];

  new({required this.type, required this.variable, required super.fileOffset});

  @override
  String get variableName => variable.cosmeticName!;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalVariablePattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    } else {
      printer.write("var ");
    }
    printer.write(variable.cosmeticName!);
  }
}

class InternalWildcardPattern extends InternalPattern {
  final DartType? type;

  new({required this.type, required super.fileOffset});

  @override
  List<InternalDeclaredVariable> get declaredVariables => const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalWildcardPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    }
    printer.write("_");
  }
}

/// A [InternalPattern] with an optional guard [InternalExpression].
class InternalPatternGuard extends InternalNode {
  final InternalPattern pattern;
  final InternalExpression? guard;

  new({required this.pattern, required this.guard, required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    if (guard != null) {
      printer.write(' when ');
      guard!.toTextInternal(printer);
    }
  }
}

class InternalPatternSwitchCase extends InternalSwitchCase {
  final List<int> caseOffsets;
  final List<InternalPatternGuard> patternGuards;

  @override
  final InternalStatement body;

  final bool isDefault;

  @override
  final List<Label>? labels;

  final List<InternalDeclaredVariable> jointVariables;

  final List<int>? jointVariableFirstUseOffsets;

  new({
    required this.caseOffsets,
    required this.patternGuards,
    required this.body,
    required this.isDefault,
    required this.labels,
    required this.jointVariables,
    required this.jointVariableFirstUseOffsets,
    required super.fileOffset,
  });

  int get caseHeadCount => patternGuards.length;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    bool needsNewLine = false;
    if (labels != null) {
      for (Label label in labels!) {
        if (needsNewLine) {
          printer.newLine();
        }
        printer.write(label.name);
        printer.write(':');
        needsNewLine = true;
      }
    }
    for (InternalPatternGuard patternGuard in patternGuards) {
      if (needsNewLine) {
        printer.newLine();
      }
      printer.write('case ');
      patternGuard.toTextInternal(printer);
      printer.write(':');
      needsNewLine = true;
    }
    if (isDefault) {
      if (needsNewLine) {
        printer.newLine();
      }
      printer.write('default:');
    }
    printer.incIndentation();
    InternalStatement? block = body;
    if (block is InternalBlock) {
      for (InternalStatement statement in block.statements) {
        printer.newLine();
        statement.toTextInternal(printer);
      }
    } else {
      printer.write(' ');
      body.toTextInternal(printer);
    }
    printer.decIndentation();
  }
}

class InternalPatternSwitchStatement extends InternalStatement
    implements InternalSwitchStatement {
  final InternalExpression expression;

  @override
  final List<InternalPatternSwitchCase> cases;

  @override
  final List<BreakStatement> breakStatements = [];

  new({
    required this.expression,
    required this.cases,
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalPatternSwitchStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    expression.toTextInternal(printer);
    printer.write(') {');
    printer.incIndentation();
    for (InternalPatternSwitchCase switchCase in cases) {
      printer.newLine();
      switchCase.toTextInternal(printer);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }
}

sealed class InternalSwitch implements InternalNode {}

sealed class InternalSwitchStatement
    implements InternalSwitch, InternalStatement, InternalBreakableStatement {
  List<InternalSwitchCase> get cases;
}

class InternalSwitchExpressionCase extends InternalNode {
  final InternalPatternGuard patternGuard;
  final InternalExpression expression;

  new({
    required this.patternGuard,
    required this.expression,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('case ');
    patternGuard.toTextInternal(printer);
    printer.write(' => ');
    expression.toTextInternal(printer);
  }
}

class InternalSwitchExpression extends InternalExpression
    implements InternalSwitch {
  final InternalExpression expression;
  final List<InternalSwitchExpressionCase> cases;

  new({
    required this.expression,
    required this.cases,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSwitchExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    expression.toTextInternal(printer);
    printer.write(') {');
    String comma = ' ';
    for (InternalSwitchExpressionCase switchCase in cases) {
      printer.write(comma);
      switchCase.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(' }');
  }
}

class InternalPatternVariableDeclaration extends InternalStatement {
  final InternalPattern pattern;
  final InternalExpression initializer;
  final bool isFinal;

  new({
    required this.pattern,
    required this.initializer,
    required this.isFinal,
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalPatternVariableDeclaration(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isFinal) {
      printer.write('final ');
    } else {
      printer.write('var ');
    }
    pattern.toTextInternal(printer);
    printer.write(" = ");
    initializer.toTextInternal(printer);
    printer.write(';');
  }
}

class InternalPatternAssignment extends InternalExpression {
  final InternalPattern pattern;
  final InternalExpression expression;

  new({
    required this.pattern,
    required this.expression,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalPatternAssignment(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' = ');
    expression.toTextInternal(printer);
  }
}

/// Statement for a if-case statements:
///
///     if (expression case pattern) then
///     if (expression case pattern) then else otherwise
///     if (expression case pattern when guard) then
///     if (expression case pattern when guard) then else otherwise
///
class InternalIfCaseStatement extends InternalStatement {
  final InternalExpression expression;
  final InternalPatternGuard patternGuard;
  final InternalStatement then;
  final InternalStatement? otherwise;

  new({
    required this.expression,
    required this.patternGuard,
    required this.then,
    required this.otherwise,
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalIfCaseStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    expression.toTextInternal(printer);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

class InternalContinueSwitchStatement extends InternalStatement
    implements InternalGotoStatement {
  late InternalSwitchCase target;

  @override
  InternalInvalidExpression? error;

  new({required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('continue');
    if (target.labels != null) {
      printer.write(' ');
      printer.write(target.labels!.first.name);
    }
    printer.write(';');
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalContinueSwitchStatement(this);
  }
}

class InternalCatch extends InternalNode {
  final DartType guard; // Not null, defaults to dynamic.
  final InternalCatchVariable? exception;
  final InternalCatchVariable? stackTrace;
  final InternalStatement body;

  new({
    required this.exception,
    required this.body,
    this.guard = const DynamicType(),
    this.stackTrace,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    bool isImplicitType(DartType type) {
      if (type is DynamicType) {
        return true;
      }
      if (type is InterfaceType &&
          type.classReference.node != null &&
          type.classNode.name == 'Object') {
        Uri uri = type.classNode.enclosingLibrary.importUri;
        return uri.isScheme('dart') &&
            uri.path == 'core' &&
            type.nullability == Nullability.nonNullable;
      }
      return false;
    }

    if (exception != null) {
      if (!isImplicitType(guard)) {
        printer.write('on ');
        printer.writeType(guard);
        printer.write(' ');
      }
      printer.write('catch (');
      printer.writeVariableInitialization(
        exception!._astVariable,
        includeModifiersAndType: false,
      );
      if (stackTrace != null) {
        printer.write(', ');
        printer.writeVariableInitialization(
          stackTrace!._astVariable,
          includeModifiersAndType: false,
        );
      }
      printer.write(') ');
    } else {
      printer.write('on ');
      printer.writeType(guard);
      printer.write(' ');
    }
    body.toTextInternal(printer);
  }
}

/// Declaration of a variable with an initial value.
class InternalVariableDeclaration extends InternalNode {
  /// The declared variable.
  final InternalDeclaredVariable variable;

  InternalExpression? initializer;

  final int equalsOffset;

  new(
    this.variable, {
    this.initializer,
    required int nameOffset,
    int? equalsOffset,
  }) : this.equalsOffset = equalsOffset ?? TreeNode.noOffset,
       super(fileOffset: nameOffset);

  void updateInitializer(InternalExpression? value) {
    initializer = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    variable.toTextInternal(printer, initializer: initializer);
  }
}

/// Declaration of a local variable.
class InternalVariableStatement extends InternalStatement {
  /// The declared variable.
  final InternalVariableDeclaration declaration;

  new(this.declaration, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalVariableStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    declaration.toTextInternal(printer);
    printer.write(';');
  }
}

sealed class InternalLoopStatement({required super.fileOffset})
    extends InternalStatement
    implements InternalBreakableStatement, InternalContinuableStatement {
  @override
  final List<BreakStatement> breakStatements = [];

  @override
  final List<BreakStatement> continueStatements = [];
}

class InternalForStatement extends InternalLoopStatement {
  // May be empty, but not null.
  final List<InternalVariableDeclaration> variables;
  final InternalExpression? condition; // May be null.
  final List<InternalExpression> updates; // May be empty, but not null.

  final InternalStatement body;

  new(
    this.variables,
    this.condition,
    this.updates,
    this.body, {
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalForStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      variables[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: variables[index].initializer,
      );
    }
    printer.write('; ');
    if (condition != null) {
      condition!.toTextInternal(printer);
    }
    printer.write('; ');
    updates.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

/// Synthetic expression of form `let v = x in y`
// TODO(johnniwinther): Can we avoid this?
class InternalLet extends InternalExpression {
  final InternalExpression value;
  final DartType valueType;
  final InternalExpression body;

  new({
    required this.value,
    required this.valueType,
    required this.body,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalLet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeType(valueType);
    printer.write(' # = ');
    value.toTextInternal(printer);
    printer.write(' in ');
    body.toTextInternal(printer);
  }
}

class InternalThisVariable extends InternalVariable {
  @override
  final ThisVariable _astVariable;

  new({required DartType type, required super.fileOffset})
    : _astVariable = new ThisVariable(type: type)..fileOffset = fileOffset;

  @override
  ThisVariable get astVariable => _astVariable;

  @override
  // Coverage-ignore(suite): Not run.
  String get cosmeticName => _astVariable.cosmeticName;

  @override
  // Coverage-ignore(suite): Not run.
  bool get forSyntheticToken => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isImplicitlyTyped => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isLocalFunction => false;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
  }
}

final InternalPattern dummyInternalPattern = new InternalConstantPattern(
  expression: dummyInternalExpression,
  fileOffset: TreeNode.noOffset,
);

final InternalPatternGuard dummyInternalPatternGuard = new InternalPatternGuard(
  pattern: dummyInternalPattern,
  guard: null,
  fileOffset: TreeNode.noOffset,
);

final InternalSwitchExpressionCase dummyInternalSwitchExpressionCase =
    new InternalSwitchExpressionCase(
      patternGuard: dummyInternalPatternGuard,
      expression: dummyInternalExpression,
      fileOffset: TreeNode.noOffset,
    );

final InternalSwitchCase dummyInternalSwitchCase =
    new InternalSwitchStatementCase(
      caseOffsets: [],
      expressions: [],
      expressionOffsets: [],
      body: dummyInternalStatement,
      isDefault: false,
      labels: null,
      fileOffset: TreeNode.noOffset,
    );

final InternalCatch dummyInternalCatch = new InternalCatch(
  exception: dummyInternalCatchVariable,
  body: dummyInternalStatement,
  stackTrace: dummyInternalCatchVariable,
  fileOffset: TreeNode.noOffset,
);

final InternalCatchVariable dummyInternalCatchVariable =
    new InternalCatchVariable(
      name: '',
      isImplicitlyTyped: false,
      fileOffset: TreeNode.noOffset,
    );

final InternalSyntheticVariable dummyInternalVariable =
    new InternalSyntheticVariable(
      isImplicitlyTyped: false,
      fileOffset: TreeNode.noOffset,
    );

final InternalVariableDeclaration dummyInternalVariableDeclaration =
    new InternalVariableDeclaration(
      dummyInternalVariable,
      nameOffset: TreeNode.noOffset,
    );

class InternalFieldInitializer extends InternalInitializer {
  /// Reference to the field being initialized.  Not null.
  final Field field;
  final InternalExpression value;

  final bool isSynthetic;

  new(
    this.field,
    this.value, {
    required this.isSynthetic,
    required super.fileOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(field.name);
    printer.write(' = ');
    value.toTextInternal(printer);
  }

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalFieldInitializer(this);
  }
}

class InternalAssertInitializer extends InternalInitializer {
  final InternalAssertStatement statement;

  new(this.statement, {required super.fileOffset});

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalAssertInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    statement.toTextInternal(printer);
  }
}

/// An initializer with a compile-time error.
///
/// Should throw an exception at runtime.
class InternalInvalidInitializer extends InternalInitializer {
  final String message;
  final bool isSuperInitializer;
  final bool isRedirectingInitializer;

  new(
    this.message, {
    required super.fileOffset,
    required this.isSuperInitializer,
    required this.isRedirectingInitializer,
  });

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalInvalidInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<invalid:');
    printer.write(message);
    printer.write('>');
  }
}

class InternalAssertStatement extends InternalStatement {
  final InternalExpression condition;
  final InternalExpression? message; // May be null.

  /// Character offset in the source where the assertion condition begins.
  ///
  /// This is an index into [Source.text].
  final int conditionStartOffset;

  /// Character offset in the source where the assertion condition ends.
  ///
  /// This is an index into [Source.text].
  final int conditionEndOffset;

  new(
    this.condition, {
    this.message,
    required this.conditionStartOffset,
    required this.conditionEndOffset,
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalAssertStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('assert(');
    condition.toTextInternal(printer);
    if (message != null) {
      printer.write(', ');
      message!.toTextInternal(printer);
    }
    printer.write(');');
  }
}

class InternalEmptyStatement extends InternalStatement {
  new({required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalEmptyStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(';');
  }
}

class InternalExpressionStatement extends InternalStatement {
  final InternalExpression expression;

  new(this.expression, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalExpressionStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
    printer.write(';');
  }
}

class InternalIfStatement extends InternalStatement {
  final InternalExpression condition;
  final InternalStatement then;
  final InternalStatement? otherwise;

  new(this.condition, this.then, this.otherwise, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalIfStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    condition.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }
}

class InternalYieldStatement extends InternalStatement {
  final InternalExpression expression;
  final bool isYieldStar;

  new(this.expression, {required this.isYieldStar, required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalYieldStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('yield');
    if (isYieldStar) {
      printer.write('*');
    }
    printer.write(' ');
    expression.toTextInternal(printer);
    printer.write(';');
  }
}

class InternalDoStatement extends InternalLoopStatement {
  final InternalStatement body;

  final InternalExpression condition;

  new(this.body, this.condition, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalDoStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('do ');
    body.toTextInternal(printer);
    printer.write(' while (');
    condition.toTextInternal(printer);
    printer.write(');');
  }
}

class InternalWhileStatement extends InternalLoopStatement {
  final InternalExpression condition;

  final InternalStatement body;

  new(this.condition, this.body, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalWhileStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('while (');
    condition.toTextInternal(printer);
    printer.write(') ');
    body.toTextInternal(printer);
  }
}

class InternalLabeledStatement extends InternalStatement
    implements InternalBreakableStatement {
  final InternalStatement body;

  @override
  final List<BreakStatement> breakStatements = [];

  new(this.body, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalLabeledStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<label>:');
    printer.newLine();
    body.toTextInternal(printer);
  }
}

class InternalBlock extends InternalStatement {
  final List<InternalStatement> statements;

  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  final int fileEndOffset;

  new(
    this.statements, {
    required this.fileEndOffset,
    required super.fileOffset,
  });

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalBlock(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (statements.isEmpty) {
      printer.write('{}');
    } else {
      printer.write('{');
      printer.incIndentation();
      for (InternalStatement statement in statements) {
        printer.newLine();
        statement.toTextInternal(printer);
      }
      printer.decIndentation();
      printer.newLine();
      printer.write('}');
    }
  }
}

class InternalBlockExpression extends InternalExpression {
  final InternalBlock body;
  final InternalExpression value;

  new(this.body, this.value, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalBlockExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('block ');
    body.toTextInternal(printer);
    printer.write(' => ');
    value.toTextInternal(printer);
  }
}

final InternalStatement dummyInternalStatement = new InternalEmptyStatement(
  fileOffset: TreeNode.noOffset,
);

class InternalAsExpression extends InternalExpression {
  final InternalExpression operand;
  final DartType type;

  new(this.operand, this.type, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalAsExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    operand.toTextInternal(
      printer /*, minimumPrecedence: Precedence.BITWISE_OR*/,
    );
    printer.write(' as');
    printer.write(' ');
    printer.writeType(type);
  }
}

class InternalAwaitExpression extends InternalExpression {
  final InternalExpression operand;

  new(this.operand, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalAwaitExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('await ');
    operand.toTextInternal(printer);
  }
}

class InternalBoolLiteral extends InternalExpression {
  final bool value;

  new(this.value, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalBoolLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class InternalConditionalExpression extends InternalExpression {
  final InternalExpression condition;
  final InternalExpression then;
  final InternalExpression otherwise;

  new(this.condition, this.then, this.otherwise, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalConditionalExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    condition.toTextInternal(
      printer,
      /*minimumPrecedence: Precedence.LOGICAL_OR,*/
    );
    printer.write(' ? ');
    then.toTextInternal(printer);
    printer.write(' : ');
    otherwise.toTextInternal(printer);
  }
}

class InternalConstructorTearOff extends InternalExpression {
  final Member target;

  new(this.target, {required super.fileOffset})
    : assert(
        target is Constructor || (target is Procedure && target.isFactory),
        "Unexpected constructor tear off target: $target",
      );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalConstructorTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(target.reference);
  }
}

class InternalDoubleLiteral extends InternalExpression {
  final double value;

  new(this.value, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalDoubleLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('$value');
  }
}

class InternalFileUriExpression extends InternalExpression {
  final Uri fileUri;

  final InternalExpression expression;

  new({
    required this.expression,
    required this.fileUri,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalFileUriExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (printer.includeAuxiliaryProperties) {
      printer.write('{');
      printer.write(fileUri.toString());
      printer.write('}');
    }
    expression.toTextInternal(printer);
  }
}

class InternalInstantiation extends InternalExpression {
  final InternalExpression expression;
  final List<DartType> typeArguments;

  new(this.expression, this.typeArguments, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalInstantiation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
    printer.writeTypeArguments(typeArguments);
  }
}

class InternalInvalidExpression extends InternalExpression {
  final String message;
  final InternalExpression? expression;

  new(this.message, {this.expression, required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalInvalidExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('<invalid:');
    printer.write(message);
    printer.write('>');
  }
}

class InternalIsExpression extends InternalExpression {
  final InternalExpression operand;
  final DartType type;
  final int? notFileOffset;

  new(
    this.operand,
    this.type, {
    required this.notFileOffset,
    required super.fileOffset,
  });

  bool get isNot => notFileOffset != null;

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalIsExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    operand.toTextInternal(
      printer,
      /*, minimumPrecedence: Precedence.BITWISE_OR*/
    );
    printer.write(' is');
    if (isNot) {
      printer.write('!');
    }
    printer.write(' ');
    printer.writeType(type);
  }
}

/// Internal expression for a list literal.
class InternalListLiteral extends InternalExpression {
  /// Whether the literal is const, either explicitly or from context.
  final bool isConst;

  /// The list literal type argument, if provided in the source code.
  final DartType? typeArgument;

  /// The elements in the list literal.
  final List<InternalElement> elements;

  new({
    required this.elements,
    this.typeArgument,
    this.isConst = false,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalListLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    if (typeArgument != null) {
      printer.write('<');
      printer.writeType(typeArgument!);
      printer.write('>');
    }
    printer.write('[');
    elements.toTextInternal(printer);
    printer.write(']');
  }
}

class InternalLogicalExpression extends InternalExpression {
  final InternalExpression left;
  final LogicalExpressionOperator operator; // AND (&&) or OR (||).
  final InternalExpression right;

  new(this.left, this.operator, this.right, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalLogicalExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    //int minimumPrecedence = precedence;
    left.toTextInternal(printer /*, minimumPrecedence: minimumPrecedence*/);
    printer.write(' ${logicalExpressionOperatorToString(operator)} ');
    right.toTextInternal(
      printer /*, minimumPrecedence: minimumPrecedence + 1*/,
    );
  }
}

/// Internal expression for a map or set literal.
class MapOrSetLiteral extends InternalExpression {
  /// Whether the literal is const, either explicitly or from context.
  final bool isConst;

  /// The map/set literal type arguments, if provided in the source code.
  ///
  /// If present, these are normalized to have 1 or 2 types.
  final List<DartType>? typeArguments;

  /// The elements in the map/set literal.
  final List<InternalElement> elements;

  new({
    required this.elements,
    this.typeArguments,
    this.isConst = false,
    required super.fileOffset,
  }) : assert(
         typeArguments == null ||
             typeArguments.length == 1 ||
             typeArguments.length == 2,
       );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitMapOrSetLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    if (typeArguments != null) {
      printer.writeTypeArguments(typeArguments!);
    }
    printer.write('{');
    for (int index = 0; index < elements.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      elements[index].toTextInternal(printer);
    }
    printer.write('}');
  }
}

class InternalNot extends InternalExpression {
  final InternalExpression operand;

  new(this.operand, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalNot(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('!');
    // TODO(johnniwinther): Support precedence on internal expressions.
    operand.toTextInternal(printer /*, minimumPrecedence: Precedence.PREFIX*/);
  }
}

class InternalNullCheck extends InternalExpression {
  final InternalExpression operand;

  new(this.operand, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalNullCheck(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Support precedence on internal expressions.
    operand.toTextInternal(printer /*, minimumPrecedence: Precedence.POSTFIX*/);
    printer.write('!');
  }
}

class InternalNullLiteral extends InternalExpression {
  new({required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalNullLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('null');
  }
}

class InternalRethrow extends InternalExpression {
  new({required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalRethrow(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('rethrow');
  }
}

class InternalStaticGet extends InternalExpression {
  final Member target;

  new(this.target, {required super.fileOffset})
    : assert(
        target is Field || (target is Procedure && target.isGetter),
        "Unexpected static get target $target",
      );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStaticGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(target.reference);
  }
}

class InternalStaticSet extends InternalExpression {
  final Member target;
  final InternalExpression value;

  new(this.target, this.value, {required super.fileOffset})
    : assert(
        target is Field || (target is Procedure && target.isSetter),
        "Unexpected static set target $target",
      );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStaticSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(target.reference);
    printer.write(' = ');
    value.toTextInternal(printer);
  }
}

class InternalStaticTearOff extends InternalExpression {
  final Procedure target;

  new(this.target, {required super.fileOffset})
    : assert(target.isStatic, "Unexpected static tear off target: $target"),
      assert(
        target.kind == ProcedureKind.Method,
        "Unexpected static tear off target: $target",
      );

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStaticTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(target.reference);
  }
}

class InternalStringConcatenation extends InternalExpression {
  final List<InternalExpression> expressions;

  new(this.expressions, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStringConcatenation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    for (InternalExpression part in expressions) {
      if (part is InternalStringLiteral) {
        printer.write(escapeString(part.value));
      } else {
        printer.write(r'${');
        part.toTextInternal(printer);
        printer.write('}');
      }
    }
    printer.write('"');
  }
}

class InternalStringLiteral extends InternalExpression {
  final String value;

  new(this.value, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStringLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('"');
    printer.write(escapeString(value));
    printer.write('"');
  }
}

class InternalSuperPropertyGet extends InternalExpression {
  /// The implicit this expression on which the getter is accessed.
  final InternalThisExpression receiver;

  final Name name;

  final Member interfaceTarget;

  new({
    required this.receiver,
    required this.name,
    required this.interfaceTarget,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSuperPropertyGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTarget.reference, name);
  }
}

class InternalSuperPropertySet extends InternalExpression {
  final InternalExpression receiver;
  final Name name;
  final InternalExpression value;

  final Member interfaceTarget;

  new({
    required this.receiver,
    required this.name,
    required this.value,
    required this.interfaceTarget,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSuperPropertySet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeInterfaceMemberName(interfaceTarget.reference, name);
    printer.write(' = ');
    value.toTextInternal(printer);
  }
}

class InternalSymbolLiteral extends InternalExpression {
  final String value; // Everything strictly after the '#'.

  new(this.value, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSymbolLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('#');
    printer.write(value);
  }
}

class InternalThisExpression extends InternalExpression {
  new({required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalThisExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
  }
}

class InternalThrow extends InternalExpression {
  final InternalExpression expression;

  new(this.expression, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalThrow(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('throw ');
    expression.toTextInternal(printer);
  }
}

class InternalTypedefTearOff extends InternalExpression {
  final List<StructuralParameter> structuralParameters;
  final InternalExpression expression;
  final List<DartType> typeArguments;

  new({
    required this.structuralParameters,
    required this.expression,
    required this.typeArguments,
    required super.fileOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalTypedefTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeStructuralParameters(structuralParameters);
    printer.write(".(");
    expression.toTextInternal(printer);
    printer.writeTypeArguments(typeArguments);
    printer.write(")");
  }
}

class InternalTypeLiteral extends InternalExpression {
  final DartType type;

  new(this.type, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalTypeLiteral(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
  }
}

class InternalNamedExpression extends InternalNode {
  final String name;

  InternalExpression value;

  new({required this.name, required this.value, required super.fileOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    value.toTextInternal(printer);
  }
}

final InternalExpression dummyInternalExpression = new InternalNullLiteral(
  fileOffset: TreeNode.noOffset,
);

final InternalElement dummyInternalElement = new ExpressionElement(
  expression: dummyInternalExpression,
  fileOffset: TreeNode.noOffset,
);

class InternalRedirectingFactoryTearOff extends InternalExpression {
  final Procedure target;

  new(this.target, {required super.fileOffset});

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalRedirectingFactoryTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(target.reference);
  }
}

class MultiVariableDeclaration extends InternalStatement {
  final List<InternalVariableDeclaration> declarations;

  new(this.declarations, {required super.fileOffset});

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    throw new UnsupportedError('$runtimeType.acceptInference');
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < declarations.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      declarations[index].variable.toTextInternal(
        printer,
        includeModifiersAndType: index == 0,
        initializer: declarations[index].initializer,
      );
    }
    printer.write(';');
  }
}
