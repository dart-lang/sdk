// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart';
import 'package:analyzer/src/fasta/ast_building_factory.dart';
import 'package:front_end/src/fasta/kernel/expression_generator.dart' as fasta;
import 'package:front_end/src/fasta/kernel/expression_generator_helper.dart';
import 'package:front_end/src/fasta/kernel/forest.dart' as fasta;
import 'package:front_end/src/scanner/token.dart';
import 'package:kernel/ast.dart' show DartType, Initializer, Name, Procedure;

abstract class AnalyzerExpressionGenerator
    implements fasta.Generator<Expression, Statement, Arguments> {
  final ExpressionGeneratorHelper<Expression, Statement, Arguments> helper;

  final AstFactory astFactory;

  AnalyzerExpressionGenerator(this.helper, this.astFactory);

  fasta.Forest<Expression, Statement, Token, Arguments> get forest =>
      helper.forest;

  @override
// TODO: implement isInitializer
  bool get isInitializer => throw new UnimplementedError();
  @override
// TODO: implement isThisPropertyAccess
  bool get isThisPropertyAccess => throw new UnimplementedError();

  @override
// TODO: implement plainNameForRead
  String get plainNameForRead => throw new UnimplementedError();

  @override
// TODO: implement plainNameForWrite
  String get plainNameForWrite => throw new UnimplementedError();

  @override
// TODO: implement uri
  Uri get uri => throw new UnimplementedError();

  @override
  Expression buildAssignment(Expression value, {bool voidContext}) {
    // TODO: implement buildAssignment
    throw new UnimplementedError();
  }

  @override
  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset,
      bool voidContext,
      Procedure interfaceTarget,
      bool isPreIncDec}) {
    // TODO: implement buildCompoundAssignment
    throw new UnimplementedError();
  }

  @override
  Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    // TODO: implement buildFieldInitializer
    throw new UnimplementedError();
  }

  /// For most accessors, the AST structure will be the same whether the result
  /// is being used for access or modification.
  Expression buildForEffect() => buildSimpleRead();

  @override
  Expression buildNullAwareAssignment(
      Expression value, DartType type, int offset,
      {bool voidContext}) {
    // TODO: implement buildNullAwareAssignment
    throw new UnimplementedError();
  }

  @override
  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset, bool voidContext, Procedure interfaceTarget}) {
    // TODO: implement buildPostfixIncrement
    throw new UnimplementedError();
  }

  @override
  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset, bool voidContext, Procedure interfaceTarget}) {
    // TODO: implement buildPrefixIncrement
    throw new UnimplementedError();
  }

  @override
  buildPropertyAccess(fasta.IncompleteSendGenerator send, int operatorOffset,
      bool isNullAware) {
    // TODO: implement buildPropertyAccess
    throw new UnimplementedError();
  }

  @override
  buildThrowNoSuchMethodError(Expression receiver, Arguments arguments,
      {bool isSuper,
      bool isGetter,
      bool isSetter,
      bool isStatic,
      String name,
      int offset,
      /*LocatedMessage*/ argMessage}) {
    // TODO: implement buildThrowNoSuchMethodError
    throw new UnimplementedError();
  }

  @override
  DartType buildTypeWithBuiltArguments(List<DartType> arguments,
      {bool nonInstanceAccessIsError: false}) {
    // TODO: implement buildTypeWithBuiltArguments
    throw new UnimplementedError();
  }

  @override
  doInvocation(int offset, Arguments arguments) {
    // TODO: implement doInvocation
    throw new UnimplementedError();
  }

  @override
  Expression makeInvalidRead() {
    // TODO: implement makeInvalidRead
    throw new UnimplementedError();
  }

  @override
  Expression makeInvalidWrite(Expression value) {
    // TODO: implement makeInvalidWrite
    throw new UnimplementedError();
  }

  @override
  void printOn(StringSink sink) {
    // TODO: implement printOn
    throw new UnimplementedError();
  }

  @override
  T storeOffset<T>(T node, int offset) {
    // TODO: implement storeOffset
    throw new UnimplementedError();
  }
}

class AnalyzerIndexedAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.IndexedAccessGenerator<Expression, Statement, Arguments> {
  /// The expression computing the object on which the index operation will be
  /// invoked.
  final Expression target;

  /// The left bracket.
  final Token leftBracket;

  /// The expression computing the argument for the index operation.
  final Expression index;

  /// The right bracket.
  final Token rightBracket;

  /// Initialize a newly created generator to have the given helper.
  AnalyzerIndexedAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.target,
      this.leftBracket,
      this.index,
      this.rightBracket)
      : super(helper, astFactory);

  @override
  Token get token => leftBracket;

  @override
  Expression buildAssignment(Expression value, {bool voidContext}) {
    // TODO(brianwilkerson) Figure out how to get the token for the operator.
    return astFactory.assignmentExpression(buildSimpleRead(), null, value);
  }

  @override
  Expression buildSimpleRead() => astFactory.indexExpressionForTarget(
      target, leftBracket, index, rightBracket);
}

class AnalyzerNullAwarePropertyAccessGenerator
    extends AnalyzerExpressionGenerator
    with
        fasta.NullAwarePropertyAccessGenerator<Expression, Statement,
            Arguments> {
  final Expression target;
  final Token operator;
  final SimpleIdentifier propertyName;

  AnalyzerNullAwarePropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.target,
      this.operator,
      this.propertyName)
      : super(helper, astFactory);

  @override
  Token get token => operator;

  @override
  Expression buildSimpleRead() =>
      astFactory.propertyAccess(target, operator, propertyName);
}

class AnalyzerSuperPropertyAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.SuperPropertyAccessGenerator<Expression, Statement, Arguments> {
  /// The `super` keyword.
  Token superKeyword;

  /// The `.` or `?.` operator.
  Token operator;

  /// The name of the property being accessed,
  SimpleIdentifier propertyName;

  AnalyzerSuperPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.superKeyword,
      this.operator,
      this.propertyName)
      : super(helper, astFactory);

  @override
  Token get token => operator;

  @override
  Expression buildSimpleRead() => astFactory.propertyAccess(
      astFactory.superExpression(superKeyword), operator, propertyName);
}

class AnalyzerUnlinkedNameGenerator extends AnalyzerExpressionGenerator
    with
        fasta.ErroneousExpressionGenerator<Expression, Statement, Arguments>,
        fasta.UnlinkedGenerator<Expression, Statement, Arguments> {
  @override
  final Token token;

  @override
  final fasta.UnlinkedDeclaration declaration;

  AnalyzerUnlinkedNameGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      AstFactory astFactory,
      this.token,
      this.declaration)
      : super(helper, astFactory);

  @override
  DartType buildErroneousTypeNotAPrefix(fasta.Identifier suffix) {
    // TODO: implement buildErroneousTypeNotAPrefix
    throw new UnimplementedError();
  }

  @override
  Expression buildError(Arguments arguments,
      {bool isGetter: false, bool isSetter: false, int offset}) {
    // TODO: implement buildError
    throw new UnimplementedError();
  }

  @override
  Expression buildSimpleRead() => astFactory.simpleIdentifier(token);

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class AnalyzerUnresolvedNameGenerator extends AnalyzerExpressionGenerator
    with
        fasta.ErroneousExpressionGenerator<Expression, Statement, Arguments>,
        fasta.UnresolvedNameGenerator<Expression, Statement, Arguments> {
  @override
  final Token token;

  @override
  final Name name;

  AnalyzerUnresolvedNameGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      AstFactory astFactory,
      this.token,
      this.name)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() => astFactory.simpleIdentifier(token);

  @override
  void printOn(StringSink sink) {
    sink.write(", name: ");
    sink.write(name.name);
  }
}

class AnalyzerVariableUseGenerator extends AnalyzerExpressionGenerator
    with fasta.VariableUseGenerator<Expression, Statement, Arguments> {
  final Token nameToken;

  AnalyzerVariableUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.nameToken)
      : super(helper, astFactory);

  @override
  Token get token => nameToken;

  @override
  Expression buildSimpleRead() => astFactory.simpleIdentifier(nameToken);
}
