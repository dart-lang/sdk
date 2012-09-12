// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.parser;

import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ArrayLiteral;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.BinaryExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.Block;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.BreakStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.CatchClause;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.CatchParameter;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ClassBody;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ClassMember;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.CompilationUnit;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ConditionalExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ConstExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ConstructorName;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ContinueStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.DoStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.EmptyStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.Expression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ExpressionList;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ExpressionStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.FieldInitializerOrRedirectedConstructor;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.FinalDeclaration;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ForInitialization;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ForStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.FormalParameterList;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.FunctionDeclaration;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.FunctionLiteral;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.FunctionTypeInterface;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.Identifier;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.IfStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.Initializer;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.Label;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.Literal;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.MapLiteral;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.MapLiteralEntry;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.MethodName;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.NativeBody;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.NewExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.OperatorName;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ParenthesizedExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.PostfixExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.QualifiedIdentifier;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ReturnStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.SelectorExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.SpreadExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.StringInterpolation;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.StringSegment;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.SuperExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.SuperInitializer;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.SwitchMember;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.SwitchStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ThisExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.ThrowStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TopLevelElement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TryStatement;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TypeAnnotation;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TypeArguments;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TypeExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TypeFunctionOrVarable;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.TypeParameter;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.UnaryExpression;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.VarDeclaration;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.VariableDeclaration;
import static com.google.dart.compiler.parser.ParserEventsTest.Mark.WhileStatement;

import com.google.common.collect.Sets;
import com.google.dart.compiler.DartCompilerListener;
import com.google.dart.compiler.Source;
import com.google.dart.compiler.metrics.CompilerMetrics;

import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;

public class ParserEventsTest extends AbstractParserTest {

  /**
   * A collection of marks representing interesting parser states. Copied from
   * com.google.dart.tools.core.internal.completion.
   * <p>
   * TODO(messick) Find a way to share the implementation of Mark.
   */
  static enum Mark {
    // some elements are roots of the kind-of relationships, they must be first
    Block,
    Expression,
    Literal(Expression),
    FormalParameterList,
    Statement,
    // all others are alphabetical
    ArrayLiteral(Literal),
    BinaryExpression(Expression),
    BreakStatement(Statement),
    CatchClause,
    CatchParameter,
    ClassBody(Block),
    ClassMember,
    CompilationUnit,
    ConditionalExpression(Expression),
    FinalDeclaration,
    ConstExpression(Expression),
    ConstructorName,
    ContinueStatement(Statement),
    DoStatement(Statement),
    EmptyStatement(Statement),
    ExpressionList,
    ExpressionStatement(Statement),
    FieldInitializerOrRedirectedConstructor,
    ForInitialization,
     ForStatement(Statement),
    FunctionDeclaration,
    FunctionLiteral(Literal),
    FunctionTypeInterface,
    Identifier(Expression),
    IfStatement(Statement),
    Initializer,
    TypeExpression(Expression),
    Label,
    MapLiteral(Literal),
    MapLiteralEntry,
    MethodName,
    NativeBody,
    NewExpression(Expression),
    OperatorName,
    ParenthesizedExpression(Expression),
    PostfixExpression(Expression),
    QualifiedIdentifier,
    ReturnStatement(Statement),
    SelectorExpression(Expression),
    SpreadExpression(Expression),
    StringInterpolation,
    StringSegment,
    SuperExpression(Expression),
    SuperInitializer,
    SwitchMember,
    SwitchStatement(Statement),
    ThisExpression(Expression),
    ThrowStatement(Statement),
    TopLevelElement,
    TryStatement(Statement),
    TypeAnnotation,
    TypeArguments,
    TypeFunctionOrVarable,
    TypeParameter,
    UnaryExpression(Expression),
    VarDeclaration,
    VariableDeclaration,
    WhileStatement(Statement);

    public final Mark kind;

    private Mark() {
      kind = null;
    }

    private Mark(Mark kind) {
      this.kind = kind;
    }

    /**
     * Return <code>true</code> if this Mark has a kind-of relation to the given Mark.
     *
     * @param other the Mark to test for a kind-of relation
     * @return <code>true</code> if the test succeeds
     */
    public boolean isKindOf(Mark other) {
      if (this == other) {
        return true;
      }
      if (kind == null) {
        return false;
      }
      return kind.isKindOf(other);
    }
  }

  private static class ParserEventRecorder extends DartParser {
    private LinkedHashSet<Mark> marks;

    @Override
    protected void rollback() {
      super.rollback();
      Mark lastMark = null;
      for (Mark mark: marks) {
        lastMark = mark;
      }
      if (lastMark != null) {
        marks.remove(lastMark);
      }
    }

    public ParserEventRecorder(Source source,
        String sourceCode,
        boolean isDietParse,
        Set<String> prefixes,
        DartCompilerListener listener,
        CompilerMetrics compilerMetrics) {
      super(source, sourceCode, isDietParse, prefixes, listener, compilerMetrics);
      marks = new LinkedHashSet<Mark>();
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    public HashSet<Mark> copyMarks() {
      return (HashSet) marks.clone();
    }

    @Override
    protected void beginArrayLiteral() {
      super.beginArrayLiteral();
      recordMark(ArrayLiteral);
    }

    @Override
    protected void beginBinaryExpression() {
      super.beginBinaryExpression();
      recordMark(BinaryExpression);
    }

    @Override
    protected void beginBlock() {
      super.beginBlock();
      recordMark(Block);
    }

    @Override
    protected void beginBreakStatement() {
      super.beginBreakStatement();
      recordMark(BreakStatement);
    }

    @Override
    protected void beginCatchClause() {
      super.beginCatchClause();
      recordMark(CatchClause);
    }

    @Override
    protected void beginCatchParameter() {
      super.beginFormalParameter();
      recordMark(CatchParameter);
    }

    @Override
    protected void beginClassBody() {
      super.beginClassBody();
      recordMark(ClassBody);
    }

    @Override
    protected void beginClassMember() {
      super.beginClassMember();
      recordMark(ClassMember);
    }

    @Override
    protected void beginCompilationUnit() {
      super.beginCompilationUnit();
      recordMark(CompilationUnit);
    }

    @Override
    protected void beginConditionalExpression() {
      super.beginConditionalExpression();
      recordMark(ConditionalExpression);
    }

    @Override
    protected void beginConstExpression() {
      super.beginConstExpression();
      recordMark(ConstExpression);
    }

    @Override
    protected void beginConstructor() {
      super.beginConstructor();
      recordMark(ConstructorName);
    }

    @Override
    protected void beginContinueStatement() {
      super.beginContinueStatement();
      recordMark(ContinueStatement);
    }

    @Override
    protected void beginDoStatement() {
      super.beginDoStatement();
      recordMark(DoStatement);
    }

    @Override
    protected void beginEmptyStatement() {
      super.beginEmptyStatement();
      recordMark(EmptyStatement);
    }

    @Override
    protected void beginEntryPoint() {
      super.beginEntryPoint();
      // TODO(messick): add recording
    }

    @Override
    protected void beginExpression() {
      super.beginExpression();
      recordMark(Expression);
    }

    @Override
    protected void beginExpressionList() {
      super.beginExpressionList();
      recordMark(ExpressionList);
    }

    @Override
    protected void beginExpressionStatement() {
      super.beginExpressionStatement();
      recordMark(ExpressionStatement);
    }

    @Override
    protected void beginFieldInitializerOrRedirectedConstructor() {
      super.beginFieldInitializerOrRedirectedConstructor();
      recordMark(FieldInitializerOrRedirectedConstructor);
    }

    @Override
    protected void beginFinalDeclaration() {
      super.beginFinalDeclaration();
      recordMark(FinalDeclaration);
    }

    @Override
    protected void beginForInitialization() {
      super.beginForInitialization();
      recordMark(ForInitialization);
    }

    @Override
    protected void beginFormalParameterList() {
      super.beginFormalParameterList();
      recordMark(FormalParameterList);
    }

    @Override
    protected void beginForStatement() {
      super.beginForStatement();
      recordMark(ForStatement);
    }

    @Override
    protected void beginFunctionDeclaration() {
      super.beginFunctionDeclaration();
      recordMark(FunctionDeclaration);
    }

    @Override
    protected void beginFunctionLiteral() {
      super.beginFunctionLiteral();
      recordMark(FunctionLiteral);
    }

    @Override
    protected void beginFunctionTypeInterface() {
      super.beginFunctionTypeInterface();
      recordMark(FunctionTypeInterface);
    }

    @Override
    protected void beginIdentifier() {
      super.beginIdentifier();
      recordMark(Identifier);
    }

    @Override
    protected void beginIfStatement() {
      super.beginIfStatement();
      recordMark(IfStatement);
    }

    @Override
    protected void beginInitializer() {
      super.beginInitializer();
      recordMark(Initializer);
    }

    @Override
    protected void beginTypeExpression() {
      super.beginTypeExpression();
      recordMark(TypeExpression);
    }

    @Override
    protected void beginLabel() {
      super.beginLabel();
      recordMark(Label);
    }

    @Override
    protected void beginLiteral() {
      super.beginLiteral();
      recordMark(Literal);
    }

    @Override
    protected void beginMapLiteral() {
      super.beginMapLiteral();
      recordMark(MapLiteral);
    }

    @Override
    protected void beginMapLiteralEntry() {
      super.beginMapLiteralEntry();
      recordMark(MapLiteralEntry);
    }

    @Override
    protected void beginMethodName() {
      super.beginMethodName();
      recordMark(MethodName);
    }

    @Override
    protected void beginNativeBody() {
      super.beginNativeBody();
      recordMark(NativeBody);
    }

    @Override
    protected void beginNewExpression() {
      super.beginNewExpression();
      recordMark(NewExpression);
    }

    @Override
    protected void beginOperatorName() {
      super.beginOperatorName();
      recordMark(OperatorName);
    }

    @Override
    protected void beginParameter() {
      super.beginParameter();
      // TODO(messick): add recording
    }

    @Override
    protected void beginParameterName() {
      super.beginParameterName();
      // TODO(messick): add recording
    }

    @Override
    protected void beginParenthesizedExpression() {
      super.beginParenthesizedExpression();
      recordMark(ParenthesizedExpression);
    }

    @Override
    protected void beginPostfixExpression() {
      super.beginPostfixExpression();
      recordMark(PostfixExpression);
    }

    @Override
    protected void beginQualifiedIdentifier() {
      super.beginQualifiedIdentifier();
      recordMark(QualifiedIdentifier);
    }

    @Override
    protected void beginReturnStatement() {
      super.beginReturnStatement();
      recordMark(ReturnStatement);
    }

    @Override
    protected void beginReturnType() {
      super.beginReturnType();
      // TODO(messick): add recording
    }

    @Override
    protected void beginSelectorExpression() {
      super.beginSelectorExpression();
      recordMark(SelectorExpression);
    }

    @Override
    protected void beginSpreadExpression() {
      super.beginSpreadExpression();
      recordMark(SpreadExpression);
    }

    @Override
    protected void beginStringInterpolation() {
      super.beginStringInterpolation();
      recordMark(StringInterpolation);
    }

    @Override
    protected void beginStringSegment() {
      super.beginStringSegment();
      recordMark(StringSegment);
    }

    @Override
    protected void beginSuperExpression() {
      super.beginSuperExpression();
      recordMark(SuperExpression);
    }

    @Override
    protected void beginSuperInitializer() {
      super.beginSuperInitializer();
      recordMark(SuperInitializer);
    }

    @Override
    protected void beginSwitchMember() {
      super.beginSwitchMember();
      recordMark(SwitchMember);
    }

    @Override
    protected void beginSwitchStatement() {
      super.beginSwitchStatement();
      recordMark(SwitchStatement);
    }

    @Override
    protected void beginThisExpression() {
      super.beginThisExpression();
      recordMark(ThisExpression);
    }

    @Override
    protected void beginThrowExpression() {
      super.beginThrowExpression();
      recordMark(ThrowStatement);
    }

    @Override
    protected void beginTopLevelElement() {
      super.beginTopLevelElement();
      recordMark(TopLevelElement);
    }

    @Override
    protected void beginTryStatement() {
      super.beginTryStatement();
      recordMark(TryStatement);
    }

    @Override
    protected void beginTypeAnnotation() {
      super.beginTypeAnnotation();
      recordMark(TypeAnnotation);
    }

    @Override
    protected void beginTypeArguments() {
      super.beginTypeArguments();
      recordMark(TypeArguments);
    }

    @Override
    protected void beginTypeFunctionOrVariable() {
      super.beginTypeFunctionOrVariable();
      recordMark(TypeFunctionOrVarable);
    }

    @Override
    protected void beginTypeParameter() {
      super.beginTypeParameter();
      recordMark(TypeParameter);
    }

    @Override
    protected void beginUnaryExpression() {
      super.beginUnaryExpression();
      recordMark(UnaryExpression);
    }

    @Override
    protected void beginVarDeclaration() {
      super.beginVarDeclaration();
      recordMark(VarDeclaration);
    }

    @Override
    protected void beginVariableDeclaration() {
      super.beginVariableDeclaration();
      recordMark(VariableDeclaration);
    }

    @Override
    protected void beginWhileStatement() {
      super.beginWhileStatement();
      recordMark(WhileStatement);
    }

    private void recordMark(Mark mark) {
      marks.add(mark);
    }
  }

  private ParserEventRecorder recorder = null;

  @Override
  public void testListObjectLiterals() {
    parseUnit("ListObjectLiterals.dart");
  }

  @Override
  public void testCatchFinally() {
    parseUnit("CatchFinally.dart");
  }

  @Override
  public void testClasses() {
    parseUnit("ClassesInterfaces.dart");
    compareMarks(ReturnStatement, TopLevelElement, Block,
        ForStatement, ClassBody, FunctionLiteral, ParenthesizedExpression, TypeExpression,
        MethodName, ConditionalExpression, BinaryExpression, FormalParameterList,
        FunctionDeclaration, BreakStatement, PostfixExpression, SuperInitializer, TypeAnnotation,
        ClassMember, VarDeclaration, SwitchMember, CompilationUnit, Expression,
        TypeFunctionOrVarable, TypeParameter, ExpressionList, Identifier,
        IfStatement, QualifiedIdentifier, SwitchStatement,
        SelectorExpression, ForInitialization, CatchClause, CatchParameter,
        FieldInitializerOrRedirectedConstructor, ContinueStatement, Label, TryStatement, Literal,
        SpreadExpression, VariableDeclaration, TypeArguments, ExpressionStatement, ThrowStatement,
        WhileStatement, Initializer);
  }

  @Override
  public void testFormalParameters() {
    parseUnit("FormalParameters.dart");
    compareMarks(TopLevelElement, ClassMember, CompilationUnit,
        BinaryExpression, NativeBody, Identifier, TypeAnnotation, ClassBody,
        Literal, Block, PostfixExpression, MethodName, Expression, QualifiedIdentifier,
        FormalParameterList, ConditionalExpression);
  }

  @Override
  public void testFunctionInterfaces() {
    parseUnit("FunctionInterfaces.dart");
    compareMarks(TypeAnnotation, TopLevelElement, CompilationUnit,
        FormalParameterList, QualifiedIdentifier, Identifier, FunctionTypeInterface);
  }

  @Override
  public void testFunctionTypes() {
    parseUnit("FunctionTypes.dart");
    compareMarks(Identifier, TypeAnnotation, MethodName, CompilationUnit, ClassMember,
        TopLevelElement, NativeBody, QualifiedIdentifier, FormalParameterList, ClassBody, Block,
        VariableDeclaration);
  }

  @Override
  public void testGenericTypes() {
    parseUnit("GenericTypes.dart");
    compareMarks(NativeBody, MethodName, ClassBody, ExpressionStatement, FormalParameterList,
        Literal, ReturnStatement, Expression, TypeParameter,
        PostfixExpression, TopLevelElement, ConditionalExpression, ThisExpression, ConstructorName,
        NewExpression, QualifiedIdentifier, CompilationUnit, Block,
        Identifier, VariableDeclaration, BinaryExpression, ClassMember, TypeAnnotation);
  }

  @Override
  public void testMethodSignatures() {
    parseUnit("MethodSignatures.dart");
    compareMarks(TopLevelElement, ClassMember, TypeAnnotation,
        CompilationUnit, MethodName, QualifiedIdentifier, Identifier,
        ClassBody, FormalParameterList);
  }

  @Override
  public void testNewWithPrefix() {
    parseUnit("NewWithPrefix.dart");
    compareMarks(VarDeclaration, ClassMember, ConstructorName,
        ConditionalExpression, ConstExpression, Literal, NewExpression, Identifier, TypeAnnotation,
        PostfixExpression, FormalParameterList, QualifiedIdentifier, TopLevelElement,
        BinaryExpression, NativeBody, ClassBody, ExpressionStatement, MethodName, CompilationUnit,
        VariableDeclaration, Block, Expression);
  }

  @Override
  public void testRedirectedConstructor() {
    parseUnit("RedirectedConstructor.dart");
    compareMarks(BinaryExpression, CompilationUnit, FormalParameterList, ConditionalExpression,
        Expression, PostfixExpression, ClassBody, ThisExpression,
        Initializer, TopLevelElement, NativeBody, Block, MethodName, SuperInitializer, Literal,
        ClassMember, Identifier, QualifiedIdentifier, FieldInitializerOrRedirectedConstructor,
        TypeAnnotation, VariableDeclaration);
  }

  @Override
  public void testShifting() {
    parseUnit("Shifting.dart");
    compareMarks(Expression, ClassBody, TypeFunctionOrVarable, VariableDeclaration,
        CompilationUnit, ConditionalExpression, Identifier, ClassMember,
        Block, QualifiedIdentifier, NativeBody, OperatorName, TypeAnnotation, TypeArguments,
        PostfixExpression, BinaryExpression, FormalParameterList, TopLevelElement, Literal,
        ReturnStatement);
  }

  @Override
  public void testStringBuffer() {
    parseUnit("StringBuffer.dart");
    compareMarks(ClassBody, ConstructorName, TypeAnnotation,
        TypeFunctionOrVarable, NativeBody, SelectorExpression, TopLevelElement, Block,
        NewExpression, MethodName, Literal, Expression, CompilationUnit, Identifier,
        ThrowStatement, PostfixExpression, BinaryExpression, ClassMember, VariableDeclaration,
        ConditionalExpression, ExpressionStatement, ReturnStatement, IfStatement,
        QualifiedIdentifier, FormalParameterList, FunctionLiteral);
  }

  @Override
  public void testStrings() {
    parseUnit("Strings.dart");
    compareMarks(Expression, MethodName, ExpressionStatement, Block, ConditionalExpression,
        ClassBody, TopLevelElement, VariableDeclaration, CompilationUnit, ClassMember,
        PostfixExpression, BinaryExpression, VarDeclaration, Identifier, Literal,
        FormalParameterList, NativeBody);
  }

  @Override
  public void testStringsErrors() {
    parseUnitErrors("StringsErrorsNegativeTest.dart",
        "Unexpected token 'ILLEGAL'", 7, 13,
        "Unexpected token 'ILLEGAL'", 9, 9,
        "Unexpected token 'ILLEGAL'", 11, 9);
    compareMarks(NativeBody, TopLevelElement, PostfixExpression, ClassMember, CompilationUnit,
        VariableDeclaration, Identifier, BinaryExpression, ClassBody,
        ConditionalExpression, Literal, Expression, MethodName, ExpressionStatement, Block,
        FormalParameterList, VarDeclaration);
  }

  @Override
  public void testSuperCalls() {
    parseUnit("SuperCalls.dart");
    compareMarks(ExpressionStatement, ClassMember, SelectorExpression,
        VariableDeclaration, BinaryExpression, Literal, Identifier, SuperExpression,
        FormalParameterList, TopLevelElement, PostfixExpression, NativeBody, ClassBody, MethodName,
        CompilationUnit, Expression, VarDeclaration, Block, ConditionalExpression);
  }

  @Override
  public void testTiming() {
    // do nothing except stop broken superclass method from printing to console
  }

  @Override
  public void testTopLevel() {
    parseUnit("TopLevel.dart");
    compareMarks(ArrayLiteral, CompilationUnit, PostfixExpression, NativeBody, Literal, Identifier,
        ClassMember, Block, MethodName, TopLevelElement, TypeAnnotation, Expression,
        QualifiedIdentifier, ConditionalExpression, BinaryExpression, VariableDeclaration,
        FormalParameterList);
  }
  
  @Override
  protected DartParser makeParser(Source src, String sourceCode, DartCompilerListener listener) {
    recorder = new ParserEventRecorder(src, sourceCode, false, Sets.<String>newHashSet(), listener, null);
    return recorder;
  }

  private void compareMarks(Mark... expectedMarks) {
    HashSet<Mark> recordedMarks = recorder.copyMarks();
    for (Mark m : expectedMarks) {
      assertNotNull("Missing mark: " + m.name(), recordedMarks.remove(m));
    }
    for (Mark m : recordedMarks) {
      fail("Unexpected mark: " + m.name());
    }
  }
}
