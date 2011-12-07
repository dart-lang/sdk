// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.compiler.backend.js;

import com.google.common.collect.Lists;
import com.google.dart.compiler.InternalCompilerException;
import com.google.dart.compiler.ast.DartArrayAccess;
import com.google.dart.compiler.ast.DartBinaryExpression;
import com.google.dart.compiler.ast.DartBlock;
import com.google.dart.compiler.ast.DartCase;
import com.google.dart.compiler.ast.DartClass;
import com.google.dart.compiler.ast.DartClassMember;
import com.google.dart.compiler.ast.DartContext;
import com.google.dart.compiler.ast.DartDefault;
import com.google.dart.compiler.ast.DartDoWhileStatement;
import com.google.dart.compiler.ast.DartExprStmt;
import com.google.dart.compiler.ast.DartExpression;
import com.google.dart.compiler.ast.DartForInStatement;
import com.google.dart.compiler.ast.DartForStatement;
import com.google.dart.compiler.ast.DartFunction;
import com.google.dart.compiler.ast.DartFunctionExpression;
import com.google.dart.compiler.ast.DartFunctionObjectInvocation;
import com.google.dart.compiler.ast.DartIdentifier;
import com.google.dart.compiler.ast.DartIfStatement;
import com.google.dart.compiler.ast.DartInitializer;
import com.google.dart.compiler.ast.DartIntegerLiteral;
import com.google.dart.compiler.ast.DartLabel;
import com.google.dart.compiler.ast.DartMethodDefinition;
import com.google.dart.compiler.ast.DartMethodInvocation;
import com.google.dart.compiler.ast.DartModVisitor;
import com.google.dart.compiler.ast.DartNewExpression;
import com.google.dart.compiler.ast.DartNode;
import com.google.dart.compiler.ast.DartNodeTraverser;
import com.google.dart.compiler.ast.DartParameter;
import com.google.dart.compiler.ast.DartParenthesizedExpression;
import com.google.dart.compiler.ast.DartPropertyAccess;
import com.google.dart.compiler.ast.DartRedirectConstructorInvocation;
import com.google.dart.compiler.ast.DartReturnStatement;
import com.google.dart.compiler.ast.DartStatement;
import com.google.dart.compiler.ast.DartSuperConstructorInvocation;
import com.google.dart.compiler.ast.DartSwitchMember;
import com.google.dart.compiler.ast.DartSwitchStatement;
import com.google.dart.compiler.ast.DartThrowStatement;
import com.google.dart.compiler.ast.DartTypeNode;
import com.google.dart.compiler.ast.DartUnaryExpression;
import com.google.dart.compiler.ast.DartUnit;
import com.google.dart.compiler.ast.DartVariable;
import com.google.dart.compiler.ast.DartVariableStatement;
import com.google.dart.compiler.ast.DartWhileStatement;
import com.google.dart.compiler.ast.Modifiers;
import com.google.dart.compiler.parser.Token;
import com.google.dart.compiler.resolver.ClassElement;
import com.google.dart.compiler.resolver.ConstructorElement;
import com.google.dart.compiler.resolver.CoreTypeProvider;
import com.google.dart.compiler.resolver.Element;
import com.google.dart.compiler.resolver.ElementKind;
import com.google.dart.compiler.resolver.Elements;
import com.google.dart.compiler.resolver.EnclosingElement;
import com.google.dart.compiler.resolver.FieldElement;
import com.google.dart.compiler.resolver.LabelElement;
import com.google.dart.compiler.resolver.MethodElement;
import com.google.dart.compiler.resolver.SyntheticDefaultConstructorElement;
import com.google.dart.compiler.resolver.VariableElement;
import com.google.dart.compiler.type.InterfaceType;
import com.google.dart.compiler.type.Types;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Normalization phase of Dart compiler. Rewrites the AST to simplify later
 * phases.
 * <ul>
 * <li>Split 'type' declarations such as "int a = 0, b = 0"
 * <li>Introduce block statements for control structures such as IF, WHILE, and
 *     FOR
 * <li>normalize case statements, including adding FallThroughError throws
 * <li>pull initializers out of FOR loops
 * <li>remove useless statement labels
 * <li>remove parenthesized expression nodes
 * </ul>
 */
public class Normalizer {

  public DartUnit exec(DartUnit unit, CoreTypeProvider typeProvider,
      OptimizationStrategy optimizationStrategy) {
    new ParenNormalizer().accept(unit);
    new BlockNormalizer(typeProvider).accept(unit);
    new ForLoopInitNormalizer().accept(unit);
    // Now that the have been inserted and the For VAR has been
    // pulled out.  It is easy to split up the VAR declarations.
    new VarNormalizer().accept(unit);
    unit.accept(new NormalizerVisitor(optimizationStrategy));
    // debugPrint(unit);
    return unit;
  }

  @SuppressWarnings("unused")
  private void debugPrint(DartUnit unit) {
    DartNodeTraverser<Void> debugPrinter = new DartNodeTraverser<Void>() {
      @Override
      public Void visitClassMember(DartClassMember<?> node) {
        System.err.println(node);
        return super.visitClassMember(node);
      }

      @Override
      public Void visitNode(DartNode node) {
        DartNode normalizedNode = node.getNormalizedNode();
        if (node != normalizedNode) {
          System.err.println("orig: " + node);
          System.err.println("norm: " + normalizedNode);
          System.err.println();
        }
        return super.visitNode(node);
      }
    };
    unit.accept(debugPrinter);
  }

  /**
   * Minimize the complexity of adding statements to the AST by inserting BLOCK
   * nodes where there can be statements, after this pass there are only
   * three statement holders: BLOCK, FOR, and LABEL.
   * <p>
   * This also simplifies scope handling.
   * <p>
   * The complexity of dealing with LABEL statements is reduced by minimizing
   * the number of places that a label can be used to four statement types:
   *     BLOCK, FOR, WHILE, and DO-WHILE.
   * BLOCK could also be removed by using "label:do { statement } while (false);"
   * should we choose to.
   */
  private static class BlockNormalizer extends DartModVisitor {

    private final ConstructorElement fallThroughError;

    private static ConstructorElement getFallThroughError(
        CoreTypeProvider typeProvider) {
      ClassElement element = typeProvider.getFallThroughError().getElement();
      // TODO(fabiomfv): remove local resolution once we settle on the approach.
      ConstructorElement constructor = element.lookupConstructor("");
      if (constructor == null) {
        throw new InternalCompilerException("FallThroughError does not have unnamed constructor.");
      }
      return constructor;
    }

    public BlockNormalizer(CoreTypeProvider typeProvider) {
      fallThroughError = getFallThroughError(typeProvider);
    }

    @Override
    public void endVisit(DartLabel x, DartContext ctx) {
      DartStatement body = x.getStatement();
      if (body instanceof DartVariableStatement) {
        // TODO(johnlenz): I'm assuming labelled statements don't introduce
        // a new scope.
        // Don't push a single VAR into a BLOCK, the label can't be referenced
        // so drop it entirely.
        ctx.replaceMe(body);
      } else if (!(body instanceof DartBlock) && !canContinueControlStructure(body)) {
        DartIdentifier label = x.getLabel();
        DartLabel replacement = new DartLabel(label, maybeAddBlock(body));
        LabelElement element = (LabelElement) x.getSymbol();
        element.setNode(replacement);
        replacement.setSymbol(element);
        replacement.setSourceInfo(x);
        ctx.replaceMe(replacement);
      }
    }

    /**
     * @return Whether this is a control structure that can be used
     *     with a named "continue" statement.
     */
    private boolean canContinueControlStructure(DartStatement stmt) {
      if (stmt instanceof DartForStatement
          || stmt instanceof DartWhileStatement
          || stmt instanceof DartDoWhileStatement) {
        return true;
      }
      return false;
    }

    @Override
    public void endVisit(DartForStatement x, DartContext ctx) {
      DartStatement body = x.getBody();
      if (!(body instanceof DartBlock)) {
        DartStatement init = x.getInit();
        DartExpression condition = x.getCondition();
        DartExpression increment = x.getIncrement();

        DartStatement replacement = new DartForStatement(
            init, condition, increment, maybeAddBlock(body));
        replacement.setSourceInfo(x);
        ctx.replaceMe(replacement);
      }
    }

    @Override
    public void endVisit(DartIfStatement x, DartContext ctx) {
      DartStatement thenStmt = x.getThenStatement();
      DartStatement elseStmt = x.getElseStatement();
      if (!(thenStmt instanceof DartBlock) || !(elseStmt instanceof DartBlock)) {
        DartExpression condition = x.getCondition();

        // TODO(johnlenz): Preserve source location?
        DartIfStatement replacement = new DartIfStatement(
            condition,
            maybeAddBlock(thenStmt),
            (elseStmt != null) ? maybeAddBlock(elseStmt) : null);
        replacement.setSourceInfo(x);
        ctx.replaceMe(replacement);
      }
    }

    @Override
    public void endVisit(DartWhileStatement x, DartContext ctx) {
      DartStatement body = x.getBody();
      if (!(body instanceof DartBlock)) {
        DartExpression condition = x.getCondition();

        // TODO(johnlenz): Preserve source location?
        DartWhileStatement replacement = new DartWhileStatement(
            condition, maybeAddBlock(body));
        replacement.setSourceInfo(x);
        ctx.replaceMe(replacement);
      }
    }

    @Override
    public void endVisit(DartDoWhileStatement x, DartContext ctx) {
      DartStatement body = x.getBody();
      if (!(body instanceof DartBlock)) {
        DartExpression condition = x.getCondition();

        // TODO(johnlenz): Preserve source location?
        DartDoWhileStatement replacement = new DartDoWhileStatement(
            condition, maybeAddBlock(body));
        replacement.setSourceInfo(x);
        ctx.replaceMe(replacement);
      }
    }

    /**
     * Normalize case statements.  There are two main things to be accomplished:
     * <ol>
     * <li>add throw new FallThroughError at the end of non-empty cases which
     * may fall through to the next block
     * <li>wrap individual statements or empty cases in blocks
     * </ol>
     *
     * For example:
     * <pre>
     * case 1:
     * case 2: ...
     * </pre>
     * becomes
     * <pre>
     * case 1: {}
     * case 2: ...
     * </pre>
     * while this:
     * <pre>
     * case 1: {}
     * case 2: ...
     * </pre>
     * becomes
     * <pre>
     * case 1: { throw new FallThroughError(); }
     * case 2: ...
     * </pre>
     * The last case (and any empty labels that fall through into it) does not get
     * a throw added, but does get changed to an empty block.
     *
     * @param caseStmt the "case: stmt;*" block being normalized
     * @param ctx {@link DartContext}
     */
    @Override
    public void endVisit(DartCase caseStmt, DartContext ctx) {
      List<DartStatement> stmts = caseStmt.getStatements();
      if (stmts.size() == 0) {
        replaceWithBlock(stmts, Lists.newArrayList(stmts));
        return;
      }

      // unpack an outer block if present
      List<DartStatement> innerStatements = stmts;
      if (stmts.get(0) instanceof DartBlock) {
        innerStatements = ((DartBlock) stmts.get(0)).getStatements();
      }

      // check if we need to add a throw
      boolean needsThrow = !isLastSwitchMember(caseStmt);
      if (needsThrow) {
        // TODO(jat): should we only look at the last statement?
        // DartParser.parseCaseStatemets seems to stop as soon as it hits an
        // AbruptCompletingStatement.
        for (DartStatement stmt : innerStatements) {
          if (stmt.isAbruptCompletingStatement()) {
            needsThrow = false;
            break;
          }
        }
      }

      // if we don't need to modify the block, nothing to do
      if (!needsThrow && stmts.get(0) instanceof DartBlock) {
        return;
      }

      // copy the list of statements and add a throw
      List<DartStatement> newStmts = Lists.newArrayList(innerStatements);
      if (needsThrow) {
        newStmts.add(buildThrow(fallThroughError));
      }
      caseStmt.setNormalizedNode(new DartCase(caseStmt.getExpr(), caseStmt.getLabel(), newStmts));
      replaceWithBlock(stmts, newStmts);
    }

    /**
     * Check to see if the supplied switch member is the last one in the switch
     * statement, or is allowed to fall through to the last one.
     *
     * @param member
     * @return true if the specified member is the last one in the switch
     *     statement or is allowed to fall through to the l
     */
    private boolean isLastSwitchMember(DartSwitchMember member) {
      /*
       * We are replacing empty switch members with empty blocks as we go, but
       * that is ok because we start from the end here.
       */
      DartSwitchStatement switchStmt = (DartSwitchStatement) member.getParent();
      List<DartSwitchMember> members = switchStmt.getMembers();
      int i = members.size() - 1;
      if (members.get(i) == member) {
        // last switch member
        return true;
      }
      // now we only want ones that are empty and have no non-empty switch members
      // between them and the last member
      while (i >= 0) {
        DartSwitchMember curMember = members.get(i);
        if (curMember.getStatements().size() > 0) {
          // non-empty, so no earlier members can fall through
          return false;
        }
        if (curMember == member) {
          return true;
        }
        i--;
      }
      return false;
    }

    /**
     * Create a throw new ExceptionCtor() statement.
     *
     * @param exceptionCtor constructor to use to create exception instance
     * @param args zero or more arguments for the supplied constructor
     * @return a {@link DartStatement} representing a throw of the supplied
     *     exception
     */
    private static DartStatement buildThrow(ConstructorElement exceptionCtor,
        DartExpression... args) {
      // Create AST nodes representing 'throw new FallThroughException();'.
      DartNewExpression newExpr = new DartNewExpression(new DartTypeNode(new DartIdentifier(
          exceptionCtor.getName())), Arrays.asList(args), false);
      newExpr.setSymbol(exceptionCtor);
      return new DartThrowStatement(newExpr);
    }

    /**
     * @param stmts
     * @param newStmts
     */
    private void replaceWithBlock(List<DartStatement> stmts, List<DartStatement> newStmts) {
      DartBlock block = new DartBlock(newStmts);
      stmts.clear();
      stmts.add(block);
    }

    @Override
    public void endVisit(DartDefault member, DartContext ctx) {
      // default labels must be last, so they do not need to throw FallThroughErrors
      // So, all we need to do is make sure they are blocks
      List<DartStatement> stmts = member.getStatements();
      if (stmts.size() == 0 || !(stmts.get(0) instanceof DartBlock)) {
        replaceWithBlock(stmts, Lists.newArrayList(stmts));
      }
    }

    private DartBlock maybeAddBlock(DartStatement statement) {
      if (statement instanceof DartBlock) {
        return (DartBlock)statement;
      }
      return new DartBlock(Lists.newArrayList(statement));
    }
  }

  /**
   * Extract the any initializer statements out of the FOR loop.  This is done
   * to minimize the amount of code that needs to be special cased for handling
   * expressions in a FOR loop.
   */
  private static class ForLoopInitNormalizer extends DartModVisitor {
    @Override
    public boolean visit(DartLabel x, DartContext ctx) {
      // Pulled any FOR loop initializer expressions up above the label,
      // we do this in the visit to allow the DartForStatement to handle
      // the unlabelled case.

      LabeledForVisitor labelVisitor = new LabeledForVisitor();
      labelVisitor.accept(x);
      if (labelVisitor.forInit != null) {
        // FOR loop initializer need to be scoped, put them in a block.
        List<DartStatement> stmts = Lists.newArrayList(labelVisitor.forInit, x);
        DartBlock replacement = new DartBlock(stmts);
        ctx.replaceMe(replacement);

        // The removed expression hasn't be visited yet, do it now so it isn't
        // skipped.
        accept(replacement);
      }
      return true;
    }

    @Override
    public void endVisit(DartForStatement x, DartContext ctx) {
      DartStatement init = x.getInit();
      if (init != null) {
        DartStatement body = x.getBody();
        DartExpression condition = x.getCondition();
        DartExpression increment = x.getIncrement();

        DartStatement newFor = new DartForStatement(
            null, condition, increment, body);
        newFor.setSourceInfo(x);

        // FOR loop initializer need to be scoped, put them in a block.
        DartStatement replacementBlock = new DartBlock(
            Lists.newArrayList(init, newFor));

        ctx.replaceMe(replacementBlock);
      }
    }

    private static class LabeledForVisitor extends DartModVisitor {
      DartStatement forInit = null;

      @Override
      public boolean visit(DartForStatement x, DartContext ctx) {
        if (x.getInit() != null) {
          DartStatement init = x.getInit();
          if (init != null) {
            DartStatement body = x.getBody();
            DartExpression condition = x.getCondition();
            DartExpression increment = x.getIncrement();

            // TODO(johnlenz): Preserve source location?
            DartStatement newFor = new DartForStatement(
                null, condition, increment, body);
            newFor.setSourceInfo(x);
            ctx.replaceMe(newFor);
          }
          forInit = init;
        }
        return false;
      }

      @Override
      public boolean visit(DartLabel x, DartContext ctx) {
        DartStatement stmt = x.getStatement();
        return (stmt instanceof DartLabel) || (stmt instanceof DartForStatement);
      }
    }
  }

  /**
   * Remove parenthesized expression nodes. This simplifies all of the rest of
   * the normalizers by not requiring them to deal with this special case.
   */
  private static class ParenNormalizer extends DartModVisitor {
    @Override
    public void endVisit(DartParenthesizedExpression x, DartContext ctx) {
      ctx.replaceMe(x.getExpression());
    }
  }

  /**
   * Split VAR declarations so that there is only one VAR declaration per
   * statement. This simplifies rewriting of VAR statements.
   */
  private static class VarNormalizer extends DartModVisitor {
    @Override
    public void endVisit(DartVariableStatement x, DartContext ctx) {
      List<DartVariable> vars = x.getVariables();
      if (vars.size() > 1) {
        for (DartVariable v : vars) {
          DartVariableStatement stmt = new DartVariableStatement(
              Lists.newArrayList(v), x.getTypeNode());
          stmt.setSourceInfo(v);
          ctx.insertBefore(stmt);
        }
        ctx.removeMe();
      }
    }
  }

  /**
   * The actual normalization.
   */
  private static class NormalizerVisitor extends DartNodeTraverser<DartNode> {
    // Collects names to avoid conflicts with synthesized variables.
    private final Set<String> usedNames = new HashSet<String>();
    private final OptimizationStrategy optimizationStrategy;

    NormalizerVisitor(OptimizationStrategy optimizationStrategy) {
      this.optimizationStrategy = optimizationStrategy;
    }

    @Override
    public DartNode visitClassMember(DartClassMember<?> node) {
      usedNames.clear();
      return super.visitClassMember(node);
    }

    @Override
    public DartNode visitForInStatement(DartForInStatement node) {
      node.visitChildren(this);

      // Normalize for (var? name in expression) { ... } into:
      // {
      //   var i = expression.iterator();
      //   while (i.hasNext()) {
      //     var? name = i.next();
      //     ...
      //   }
      // }
     List<DartStatement> topLevelStatements = new ArrayList<DartStatement>();

      // Generate the call to expression.iterator().
      DartMethodInvocation iteratorCall = call(node.getIterable(), "iterator");

      // Create and add the iterator variable to the statements.
      DartVariableStatement iteratorVariable = makeTempVariable(0, iteratorCall);
      topLevelStatements.add(iteratorVariable);

      // Generate the call to i.hasNext();
      DartIdentifier iterator = ref(iteratorVariable);
      DartMethodInvocation hasNext = call(iterator, "hasNext");

      // Generate the call to i.next();
      iterator = ref(iteratorVariable);
      DartMethodInvocation next = call(iterator, "next");

      DartStatement setup = normalizeForInSetup(node, next);
      DartWhileStatement whileStatement = whileStmt(hasNext, setup, node.getBody());
      topLevelStatements.add(whileStatement);

      DartBlock newBlock = new DartBlock(topLevelStatements);
      node.setNormalizedNode(newBlock);
      return node;
    }

    private DartStatement normalizeForInSetup(DartForInStatement node, DartExpression next) {
      if (node.introducesVariable()) {
        // Since we're going to change the variable to have an initializer expression,
        // we have to create a new variable statement around it too. Make sure it has
        // the right type and modifiers.
        DartVariableStatement variableStatement = node.getVariableStatement();
        DartVariable oldVariable = variableStatement.getVariables().get(0);
        DartVariable newVariable = new DartVariable(oldVariable.getName(), next);
        newVariable.setSymbol(oldVariable.getSymbol());
        return new DartVariableStatement(Lists.newArrayList(newVariable),
            variableStatement.getTypeNode(), variableStatement.getModifiers());
      } else {
        return exprStmt(assign(node.getIdentifier(), next));
      }
    }

    @Override
    public DartNode visitClass(DartClass node) {
      final ClassElement classElement = node.getSymbol();
      // Ensure implicit default constructor with method.
      if (Elements.needsImplicitDefaultConstructor(classElement)) {
        DartMethodDefinition method = createImplicitDefaultConstructor(classElement);
        // TODO - We should really normalize the class itself.
        node.getMembers().add(method);
      }
      return super.visitClass(node);
    }

    private DartMethodDefinition createImplicitDefaultConstructor(final ClassElement classElement) {
      assert (Elements.needsImplicitDefaultConstructor(classElement));
      DartFunction function = new DartFunction(Collections.<DartParameter>emptyList(), 
          new DartBlock(Collections.<DartStatement>emptyList()), null);
      final DartMethodDefinition method =
          DartMethodDefinition.create(new DartIdentifier(""), function, Modifiers.NONE, null, null);
      method.setSymbol(new SyntheticDefaultConstructorElement(method, classElement, null));
      return method;
    }

    @Override
    public DartExpression visitBinaryExpression(DartBinaryExpression node) {
      node.visitChildren(this);
      Token operator = node.getOperator();
      if (operator.isAssignmentOperator() && operator != Token.ASSIGN
          && shouldNormalizeOperator(node)) {
        node.setNormalizedNode(normalizeCompoundAssignment(mapAssignableOp(operator), false,
                                                           node.getArg1().getNormalizedNode(),
                                                           node.getArg2().getNormalizedNode()));
      }
      return node;
    }

    @Override
    public DartExpression visitUnaryExpression(DartUnaryExpression node) {
      node.visitChildren(this);
      Token operator = node.getOperator();
      if (operator.isCountOperator() && shouldNormalizeOperator(node)) {
        DartExpression lhs = node.getArg().getNormalizedNode();
        DartIntegerLiteral rhs = DartIntegerLiteral.one();
        node.setNormalizedNode(normalizeCompoundAssignment(mapAssignableOp(operator),
                                                           !node.isPrefix(), lhs, rhs));
      }
      return node;
    }

    static class NeedsImplicitSuperInvocationDeterminant extends DartNodeTraverser<Void> {
      private boolean needsSuperInvocation = true;
      
      @Override
      public Void visitSuperConstructorInvocation(DartSuperConstructorInvocation node) {
        needsSuperInvocation = false;
        return super.visitSuperConstructorInvocation(node);
      }
      
      @Override
      public Void visitRedirectConstructorInvocation(DartRedirectConstructorInvocation node) {
        needsSuperInvocation = false;
        return super.visitRedirectConstructorInvocation(node);
      }
      
      @Override
      public Void visitMethodDefinition(DartMethodDefinition node) {
        // Ignore everything except the initializers
        for (DartInitializer initializer : node.getInitializers()) {
          initializer.accept(this);
        }
        return null;
      }
    }

    @Override
    public DartMethodDefinition visitMethodDefinition(DartMethodDefinition node) {
      super.visitMethodDefinition(node);
      if (Elements.isNonFactoryConstructor(node.getSymbol())) {
        normalizeParameterInitializer(node);
      }
      
      return node;
    }

    @Override
    public DartNode visitNewExpression(DartNewExpression node) {
      ConstructorElement symbol = node.getSymbol();
      if (symbol == null) {
        InterfaceType constructorType = Types.constructorType(node);
        if (!constructorType.getElement().isDynamic() && node.getArgs().isEmpty()) {
          // HACK use proper normalized node
          ClassElement classToInstantiate = constructorType.getElement();
          if (classToInstantiate.getDefaultClass() != null) {
            classToInstantiate = classToInstantiate.getDefaultClass().getElement();
          }

          if (classToInstantiate != null
              && Elements.needsImplicitDefaultConstructor(classToInstantiate)) {
            DartMethodDefinition implicitDefaultConstructor =
                createImplicitDefaultConstructor(classToInstantiate);
            node.setSymbol(implicitDefaultConstructor.getSymbol());
          }
        }
      }
      
      return super.visitNewExpression(node);
    }
    
    @Override
    public DartNode visitSwitchStatement(DartSwitchStatement node) {
      node.getExpression().accept(this);
      for (DartNode member : node.getMembers()) {
        member.accept(this);
      }
      return node;
    }

    // Normalize parameter initializer.
    //   transforms: class A { A(this.x) { } }
    //   into:       class A { A(this.x) : this.x = x { }
    private void normalizeParameterInitializer(DartMethodDefinition node) {
      List<DartInitializer> nInit = new ArrayList<DartInitializer>();
      for (DartParameter param : node.getFunction().getParams()) {
        FieldElement fieldElement = param.getSymbol().getParameterInitializerElement();
        if (fieldElement != null) {
          DartIdentifier left = new DartIdentifier(param.getParameterName());
          left.setSymbol(fieldElement);
          left.setSourceInfo(param);
          Element ve = Elements.makeVariable(param.getParameterName());
          DartParameter nParam = new DartParameter(param.getName(), param.getTypeNode(),
            param.getFunctionParameters(), param.getDefaultExpr(), param.getModifiers());
          nParam.setSymbol(ve);
          param.setNormalizedNode(nParam);
          DartIdentifier right = new DartIdentifier(param.getParameterName());
          right.setSymbol(ve);
          right.setSourceInfo(param);
          DartInitializer di = new DartInitializer(left, right);
          di.setSourceInfo(param);
          nInit.add(di);
        }
      }

      EnclosingElement enclosingElement = node.getSymbol().getEnclosingElement();
      if (ElementKind.of(enclosingElement) == ElementKind.CLASS) {
        ClassElement classElement = (ClassElement) enclosingElement;
        if (!classElement.isObject()) {
          NeedsImplicitSuperInvocationDeterminant superLocator = new NeedsImplicitSuperInvocationDeterminant();
          node.accept(superLocator);
          if (superLocator.needsSuperInvocation) {
            DartSuperConstructorInvocation superInvocation = new DartSuperConstructorInvocation(
                new DartIdentifier(""), Collections.<DartExpression>emptyList());
            superInvocation.setSymbol(new SyntheticDefaultConstructorElement(null, 
                classElement.getSupertype().getElement(), null));
            nInit.add(new DartInitializer(null, superInvocation));
          }    
        }
      }
      
      if (!nInit.isEmpty()) {
        if (!node.getInitializers().isEmpty()) {
          nInit.addAll(0, node.getInitializers());
        }
        
        DartMethodDefinition nConstructor = DartMethodDefinition.create(
                node.getName(), node.getFunction(), node.getModifiers(), nInit, null);
        nConstructor.setSymbol(node.getSymbol());
        nConstructor.setSourceInfo(node.getSourceInfo());
        node.setNormalizedNode(nConstructor);
      }
    }

    private DartExpression normalizeCompoundAssignment(Token operator,
                                                       boolean isPostfix,
                                                       DartExpression operand1,
                                                       DartExpression operand2) {
      return operand1.accept(new CompoundAssignmentNormalizer(operator, isPostfix, operand2));
    }

    private String makeTempName(int i) {
      String name;
      do {
        name = "$" + i;
        i++;
      } while (usedNames.contains(name));
      usedNames.add(name);
      return name;
    }

    private DartVariableStatement makeTempVariable(int i, DartExpression init) {
      String variableName = makeTempName(i);
      DartIdentifier variableIdentifier = new DartIdentifier(variableName);
      DartVariable variable = new DartVariable(variableIdentifier, init);
      VariableElement element = Elements.variableElement(variable,
                                                         variableName,
                                                         Modifiers.NONE);
      variable.setSymbol(element);
      return new DartVariableStatement(Lists.newArrayList(variable), null);
    }

    private class Let {
      private final List<DartExpression> arguments;
      final DartParameter[] parameters;

      Let(DartExpression... arguments) {
        this.arguments = Arrays.asList(arguments);
        parameters = new DartParameter[arguments.length];
        for (int i = 0; i < arguments.length; i++) {
          parameters[i] = makeTempParameter(i);
        }
      }

      DartExpression expression() {
        DartBlock body = new DartBlock(Arrays.<DartStatement>asList(body()));
        return call(makeFunctionExpression(body), arguments);
      }

      private DartFunctionExpression makeFunctionExpression(DartBlock body) {
        DartFunction function = new DartFunction(Arrays.asList(parameters), body , null);
        DartFunctionExpression expression = new DartFunctionExpression(null, function, false);
        MethodElement element =
            Elements.methodFromFunctionExpression(expression, Modifiers.NONE.makeInlinable());
        expression.setSymbol(element);
        for (DartParameter parameter : parameters) {
          Elements.addParameter(element, parameter.getSymbol());
        }
        return expression;
      }

      DartExpression p(int i) {
        return ref(parameters[i]);
      }

      DartStatement[] body() {
        return new DartStatement[0];
      }

      private DartParameter makeTempParameter(int i) {
        String name = makeTempName(i);
        DartIdentifier identifier = new DartIdentifier(name);
        DartParameter parameter = new DartParameter(identifier, null, null, null, Modifiers.NONE);
        VariableElement element = Elements.parameterElement(parameter, name, Modifiers.NONE);
        parameter.setSymbol(element);
        return parameter;
      }
    }

    private class CompoundAssignmentNormalizer extends DartNodeTraverser<DartExpression> {
      final Token operator;
      final boolean isPostfix;
      final DartExpression rhs;

      CompoundAssignmentNormalizer(Token operator, boolean isPostfix,
                                   DartExpression rhs) {
        this.operator = operator;
        this.isPostfix = isPostfix;
        this.rhs = rhs;
      }

      @Override
      public DartExpression visitNode(DartNode lhs) {
        throw new AssertionError(lhs);
      }

      @Override
      public DartExpression visitIdentifier(DartIdentifier id) {
        return rewriteExpression(id);
      }

      private DartExpression rewriteExpression(final DartExpression lhs) {
        if (!isPostfix) {
          // Turns: lhs += rhs
          // Into: lhs = lhs + rhs
          // Turns: ++lhs
          // Into: lhs = lhs + 1
          return assign(lhs, bin(operator, lhs, rhs));
        } else {
          // Turns: lhs++
          // Into: function($2) { id = $2 + 1; return $2; }(lhs)
          return new Let(lhs) {
            @Override DartStatement[] body() {
              return statements(exprStmt(assign(lhs, bin(operator, p(0), rhs))),
                                retrn(p(0)));
            }
          }.expression();
        }
      }

      @Override
      public DartExpression visitPropertyAccess(DartPropertyAccess access) {
        Element element = access.getTargetSymbol();
        if (element != null && element.getModifiers().isStatic()) {
          return rewriteExpression(access);
        }
        final DartIdentifier name = access.getName();
        return new RewriteAccess((DartExpression) access.getQualifier()) {
          @Override
          DartExpression operand1() {
            return access(p(0), name);
          }
        }.expression();
      }

      @Override
      public DartExpression visitArrayAccess(DartArrayAccess access) {
        DartExpression target = access.getTarget();
        DartExpression key = access.getKey();
        // TODO(5408710): Evaluation order of target vs. key? (order passed to constructor)
        return new RewriteAccess(target, key) {
          @Override
          DartExpression operand1() {
            return arrayAccess(p(0), p(1));
          }
        }.expression();
      }

      private abstract class RewriteAccess extends Let {
        public RewriteAccess(DartExpression... arguments) {
          super(arguments);
        }

        abstract DartExpression operand1();

        @Override
        DartStatement[] body() {
          final DartExpression operand1 = operand1();
          if (isPostfix) {
            // Turns: this[0.0]--
            // Into: function($0, $1) {
            //   return function($2) { $0[$1] = $2 - 1; return $2; }($0[$1]);
            // }(this, 0.0)
            Let let = new Let(operand1) {
              @Override DartStatement[] body() {
                return statements(exprStmt(assign(operand1, bin(operator, p(0), rhs))),
                                  retrn(p(0)));
              }
            };
            return statements(retrn(let.expression()));
          } else {
            // Turns: this[0.0] += $0
            // Into: function($3, $4) { return $3[$4] = $3[$4] + $0; }(this, 0.0)
            // Turns: ++this[0.0]
            // Into: function($3, $4) { return $3[$4] = $3[$4] + 1; }(this, 0.0)
            return statements(retrn(assign(operand1, bin(operator, operand1, rhs))));
          }
        }
      }
    }

    private DartStatement[] statements(DartStatement... statements) {
      return statements;
    }

    private DartWhileStatement whileStmt(DartExpression condition, DartStatement... statements) {
      return new DartWhileStatement(condition, new DartBlock(Arrays.asList(statements)));
    }

    private DartExpression call(DartFunctionExpression function, List<DartExpression> args) {
      return new DartFunctionObjectInvocation(function, args);
    }

    private DartMethodInvocation call(DartExpression receiver, String name) {
      return new DartMethodInvocation(receiver,
                                      new DartIdentifier(name),
                                      Collections.<DartExpression>emptyList());
    }

    private boolean shouldNormalizeOperator(DartBinaryExpression node) {
      return !optimizationStrategy.canSkipNormalization(node);
    }

    private boolean shouldNormalizeOperator(DartUnaryExpression node) {
      return !optimizationStrategy.canSkipNormalization(node);
    }

    private DartArrayAccess arrayAccess(DartExpression target, DartExpression key) {
      return new DartArrayAccess(target, key);
    }

    private DartReturnStatement retrn(DartExpression value) {
      return new DartReturnStatement(value);
    }

    private DartBinaryExpression bin(Token operator, DartExpression lhs, DartExpression rhs) {
      return new DartBinaryExpression(operator, lhs, rhs);
    }

    private DartBinaryExpression assign(DartExpression lhs, DartExpression rhs) {
      return bin(Token.ASSIGN, lhs, rhs);
    }

    private DartExprStmt exprStmt(DartExpression expression) {
      return new DartExprStmt(expression);
    }

    private DartPropertyAccess access(DartExpression qualifier, DartIdentifier name) {
      return new DartPropertyAccess(qualifier, name);
    }

    private DartExpression ref(DartParameter parameter) {
      DartIdentifier identifier = new DartIdentifier(parameter.getParameterName());
      identifier.setSymbol(parameter.getSymbol());
      return identifier;
    }

    private DartIdentifier ref(DartVariableStatement variableStatement) {
      DartVariable variable = variableStatement.getVariables().get(0);
      DartIdentifier identifier = new DartIdentifier(variable.getVariableName());
      identifier.setSymbol(variable.getSymbol());
      return identifier;
    }

    private Token mapAssignableOp(Token operator) {
      switch (operator) {
        case ASSIGN_BIT_OR: return Token.BIT_OR;
        case ASSIGN_BIT_XOR: return Token.BIT_XOR;
        case ASSIGN_BIT_AND: return Token.BIT_AND;
        case ASSIGN_SHL: return Token.SHL;
        case ASSIGN_SAR: return Token.SAR;
        case ASSIGN_SHR: return Token.SHR;
        case ASSIGN_ADD: return Token.ADD;
        case ASSIGN_SUB: return Token.SUB;
        case ASSIGN_MUL: return Token.MUL;
        case ASSIGN_DIV: return Token.DIV;
        case ASSIGN_MOD: return Token.MOD;
        case ASSIGN_TRUNC: return Token.TRUNC;
        case INC: return Token.ADD;
        case DEC: return Token.SUB;

        default:
          throw new InternalCompilerException("Invalid assignment operator");
      }
    }
  }
}
