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
import 'package:kernel/ast.dart' as kernel
    show DartType, Initializer, Member, Name, Procedure;

class AnalyzerDeferredAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.DeferredAccessGenerator<Expression, Statement, Arguments> {
  final Token token;
  final fasta.PrefixBuilder builder;
  final fasta.Generator<Expression, Statement, Arguments> generator;

  AnalyzerDeferredAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.builder,
      this.generator)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() => generator.buildSimpleRead();
}

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
    // TODO(brianwilkerson) Figure out how to get the token for the operator.
    return astFactory.assignmentExpression(buildSimpleRead(), null, value);
  }

  @override
  Expression buildCompoundAssignment(
      kernel.Name binaryOperator, Expression value,
      {int offset,
      bool voidContext,
      kernel.Procedure interfaceTarget,
      bool isPreIncDec}) {
    // TODO(brianwilkerson) Figure out how to get the token for the operator.
    return astFactory.assignmentExpression(buildSimpleRead(), null, value);
  }

  @override
  kernel.Initializer buildFieldInitializer(Map<String, int> initializedFields) {
    // TODO: implement buildFieldInitializer
    throw new UnimplementedError();
  }

  /// For most accessors, the AST structure will be the same whether the result
  /// is being used for access or modification.
  Expression buildForEffect() => buildSimpleRead();

  @override
  Expression buildNullAwareAssignment(
      Expression value, kernel.DartType type, int offset,
      {bool voidContext}) {
    // TODO(brianwilkerson) Figure out how to get the token for the operator.
    // TODO(brianwilkerson) Capture the type information?
    return astFactory.assignmentExpression(buildSimpleRead(), null, value);
  }

  @override
  Expression buildPostfixIncrement(kernel.Name binaryOperator,
      {int offset, bool voidContext, kernel.Procedure interfaceTarget}) {
    // TODO(brianwilkerson) Figure out how to get the token for the operator.
    return astFactory.postfixExpression(buildSimpleRead(), null);
  }

  @override
  Expression buildPrefixIncrement(kernel.Name binaryOperator,
      {int offset, bool voidContext, kernel.Procedure interfaceTarget}) {
    // TODO(brianwilkerson) Figure out how to get the token for the operator.
    return astFactory.prefixExpression(null, buildSimpleRead());
  }

  @override
  buildPropertyAccess(fasta.IncompleteSendGenerator send, int operatorOffset,
      bool isNullAware) {
    // TODO: implement buildPropertyAccess
//    return astFactory.propertyAccess(buildSimpleRead(), null, null);
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
  kernel.DartType buildTypeWithBuiltArguments(List<kernel.DartType> arguments,
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
  Expression buildSimpleRead() => astFactory.indexExpressionForTarget(
      target, leftBracket, index, rightBracket);
}

class AnalyzerLargeIntAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.LargeIntAccessGenerator<Expression, Statement, Arguments> {
  final Token token;

  AnalyzerLargeIntAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() => astFactory.integerLiteral(token, null);
}

class AnalyzerLoadLibraryGenerator extends AnalyzerExpressionGenerator
    with fasta.LoadLibraryGenerator<Expression, Statement, Arguments> {
  final Token token;
  final fasta.LoadLibraryBuilder builder;

  AnalyzerLoadLibraryGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.builder)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() {
    // TODO: implement buildSimpleRead
    throw new UnimplementedError();
  }
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

class AnalyzerPropertyAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.PropertyAccessGenerator<Expression, Statement, Arguments> {
  final Token token;
  final Expression receiver;
  final kernel.Name name;
  final kernel.Member getter;
  final kernel.Member setter;

  AnalyzerPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.receiver,
      this.name,
      this.getter,
      this.setter)
      : super(helper, astFactory);

  @override
  // TODO(brianwilkerson) Figure out how to get the property name token (or node).
  Expression buildSimpleRead() =>
      astFactory.propertyAccess(receiver, token, null);
}

class AnalyzerReadOnlyAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.ReadOnlyAccessGenerator<Expression, Statement, Arguments> {
  final Token token;
  final Expression expression;
  final String plainNameForRead;

  AnalyzerReadOnlyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.expression,
      this.plainNameForRead)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() {
    // TODO: implement buildSimpleRead
    throw new UnimplementedError();
  }
}

class AnalyzerStaticAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.StaticAccessGenerator<Expression, Statement, Arguments> {
  final Token token;
  final kernel.Member getter;
  final kernel.Member setter;

  AnalyzerStaticAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.getter,
      this.setter)
      : super(helper, astFactory);

  @override
  kernel.Member get readTarget {
    // TODO: implement readTarget
    throw new UnimplementedError();
  }

  @override
  Expression buildSimpleRead() {
    // TODO: implement buildSimpleRead
    throw new UnimplementedError();
  }
}

class AnalyzerSuperIndexedAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.SuperIndexedAccessGenerator<Expression, Statement, Arguments> {
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
  AnalyzerSuperIndexedAccessGenerator(
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
  Expression buildSimpleRead() => astFactory.indexExpressionForTarget(
      target, leftBracket, index, rightBracket);
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

class AnalyzerThisIndexedAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.ThisIndexedAccessGenerator<Expression, Statement, Arguments> {
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
  AnalyzerThisIndexedAccessGenerator(
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
  Expression buildSimpleRead() => astFactory.indexExpressionForTarget(
      target, leftBracket, index, rightBracket);
}

class AnalyzerThisPropertyAccessGenerator extends AnalyzerExpressionGenerator
    with fasta.ThisPropertyAccessGenerator<Expression, Statement, Arguments> {
  final Token token;
  final kernel.Name name;
  final kernel.Member getter;
  final kernel.Member setter;

  AnalyzerThisPropertyAccessGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.name,
      this.getter,
      this.setter)
      : super(helper, astFactory);

  @override
  // TODO(brianwilkerson) Figure out how to get the token (or node) for `this`.
  // TODO(brianwilkerson) Figure out how to get the property name token (or node).
  Expression buildSimpleRead() => astFactory.propertyAccess(null, token, null);
}

class AnalyzerTypeUseGenerator extends AnalyzerExpressionGenerator
    with fasta.TypeUseGenerator<Expression, Statement, Arguments> {
  final Token token;
  final fasta.PrefixBuilder prefix;
  final int declarationReferenceOffset;
  final fasta.TypeDeclarationBuilder declaration;
  final String plainNameForRead;

  AnalyzerTypeUseGenerator(
      ExpressionGeneratorHelper<Expression, Statement, Arguments> helper,
      AstFactory astFactory,
      this.token,
      this.prefix,
      this.declarationReferenceOffset,
      this.declaration,
      this.plainNameForRead)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() {
    // TODO: implement buildSimpleRead
    throw new UnimplementedError();
  }
}

class AnalyzerUnlinkedNameGenerator extends AnalyzerExpressionGenerator
    with fasta.UnlinkedGenerator<Expression, Statement, Arguments> {
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
  Expression buildSimpleRead() => astFactory.simpleIdentifier(token);
}

class AnalyzerUnresolvedNameGenerator extends AnalyzerExpressionGenerator
    with
        fasta.ErroneousExpressionGenerator<Expression, Statement, Arguments>,
        fasta.UnresolvedNameGenerator<Expression, Statement, Arguments> {
  @override
  final Token token;

  @override
  final kernel.Name name;

  AnalyzerUnresolvedNameGenerator(
      ExpressionGeneratorHelper<dynamic, dynamic, dynamic> helper,
      AstFactory astFactory,
      this.token,
      this.name)
      : super(helper, astFactory);

  @override
  Expression buildSimpleRead() => astFactory.simpleIdentifier(token);
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
