package com.google.dart.compiler.ast;

import java.math.BigInteger;
import java.net.URI;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.google.dart.compiler.common.SourceInfo;
import com.google.dart.compiler.CommandLineOptions.CompilerOptions;
import com.google.dart.compiler.CompilerConfiguration;

/**
 * CoverageInstrumenter contains specialized instrumenters to perform specific
 * instrumentation for obtaining coverage of different program entities
 */
public class CoverageInstrumenter {
  private List<BaseInstrumenter> instrumenters;
  private static final String[] ignoredLibs = { "corelib", "corelib_impl",
      "dom", "html", "htmlimpl", "base", "touch", "view", "utilslib",
      "observable", "layout.dart", "unittest", "dartest" };

  private static final String functionCoverage = "function";
  private static final String statementCoverage = "statement";
  private static final String branchCoverage = "branch";
  private static final String allCoverage = "all";

  // Only createInstance should be used to instantiate this class
  private CoverageInstrumenter() {
  }

  /**
   * Method to instantiate a CoverageInstrumenter containing multiple
   * instrumenters created based on command line flags.
   * 
   * @param config
   * @return instance of this class
   */
  public static CoverageInstrumenter createInstance(
      CompilerConfiguration config) {

    CompilerOptions compilerOptions = config.getCompilerOptions();
    String coverageTypes = compilerOptions.getCoverageType();

    CoverageInstrumenter instr = new CoverageInstrumenter();
    if (!"".equals(coverageTypes)) {
      String outDir = compilerOptions.getWorkDirectory()
          .getAbsolutePath();
      instr.createInstrumenters(coverageTypes, outDir);
    }
    return instr;
  }

  /**
   * Performs instrumentation of all classes
   * 
   * @param libraries
   */
  public void process(Map<URI, LibraryUnit> libraries) {

    if (instrumenters == null) {
      return;
    }

    // Instrument all dart units
    for (LibraryUnit lib : libraries.values()) {
      for (DartUnit unit : lib.getUnits()) {
        exec(unit);
      }
    }

    // Populate totals and initialize coverage
    for (LibraryUnit lib : libraries.values()) {
      for (DartUnit unit : lib.getUnits()) {
        init(unit);
      }
    }
  }

  /**
   * Runs all instrumenters on a particular Dart unit
   * 
   * @param unit
   */
  private void exec(DartUnit unit) {
    if (isIgnored(unit)) {
      return;
    }
    System.out.println("Instrumenting " + unit.getSourceName() + ", lib:"
        + unit.getLibrary().getName());
    for (BaseInstrumenter instrumenter : instrumenters) {
      instrumenter.accept(unit);
    }
  }

  /**
   * Ignores a Dart unit based on the library it belongs to
   * 
   * @param unit
   * @return true is the unit should be ignored
   */
  private boolean isIgnored(DartUnit unit) {
    LibraryUnit lu = unit.getLibrary();
    if (lu != null) {
      String libName = lu.getName();
      for (String ignoredLib : ignoredLibs) {
        if (ignoredLib.equals(libName)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Runs the TotalSettingInstrumenter on the supplied Dart unit, which adds
   * totals of all coverable program entities
   * 
   * @param unit
   */
  private void init(DartUnit unit) {
    if (isIgnored(unit)) {
      return;
    }
    new TotalSettingInstrumenter().accept(unit);
  }

  /**
   * Factory method to create instrumenters based on supplied command line
   * configuration
   * 
   * @param coverageTypes
   * @param outDir
   */
  private void createInstrumenters(String coverageTypes, String outDir) {
    BaseInstrumenter.setOutDir(outDir);
    instrumenters = new ArrayList<BaseInstrumenter>();
    if (coverageTypes.length() > 0) {
      for (String covType : coverageTypes.split(",")) {
        if (allCoverage.equals(covType)) {
          instrumenters.add(new StatementInstrumenter());
          instrumenters.add(new FunctionInstrumenter());
          instrumenters.add(new BranchInstrumenter());
        }
        if (statementCoverage.equals(covType)) {
          instrumenters.add(new StatementInstrumenter());
        }
        if (functionCoverage.equals(covType)) {
          instrumenters.add(new FunctionInstrumenter());
        }
        if (branchCoverage.equals(covType)) {
          instrumenters.add(new BranchInstrumenter());
        }
      }
    }
  }

  /**
   * The Base Instrumenter class that provides some common functionalities to
   * all Instrumenters
   */
  private static class BaseInstrumenter extends DartModVisitor {
    // TODO: Switch to DartNodeTraverser
    private static String outputDir;
    protected DartUnit currentUnit;
    protected static Set<String> unitsVisited = new HashSet<String>();
    protected static Map<String, Integer> numFunctionsMap = 
        new HashMap<String, Integer>();
    protected static Map<String, Integer> numStatementsMap = 
        new HashMap<String, Integer>();
    protected static Map<String, Integer> numBranchesMap = 
        new HashMap<String, Integer>();

    public static void setOutDir(String outDir) {
      outputDir = outDir;
    }

    @Override
    public boolean visit(DartUnit x, DartContext ctx) {
      currentUnit = x;
      unitsVisited.add(x.getSourceName());
      return super.visit(x, ctx);
    }

    /**
     * Prepend a function call to a Dart block, which is a body of a
     * function.
     * 
     * @param oldBody
     * @param functionStmt
     * @return
     */
    protected DartBlock prependToFnBody(DartBlock oldBody,
        DartExprStmt functionStmt) {
      List<DartStatement> blockStmts = new ArrayList<DartStatement>();
      blockStmts.add(functionStmt);
      if (oldBody != null) {
        List<DartStatement> stmts = oldBody.getStatements();
        if (stmts != null) {
          blockStmts.addAll(stmts);
        }
      }
      DartBlock newDB = new DartBlock(blockStmts);
      if (oldBody != null) {
        newDB.setSourceInfo(oldBody.getSourceInfo());
      }
      return newDB;
    }

    protected void replaceFunction(DartContext ctx, DartFunction x,
        DartBlock newFnBody) {
      DartFunction newFn = new DartFunction(x.getParams(), newFnBody,
          x.getReturnTypeNode());
      newFn.setSourceInfo(x.getSourceInfo());
      ctx.replaceMe(newFn);
    }

    protected DartExprStmt createFunctionCall(String functionName,
        List<DartExpression> args, DartNode oldNode) {
      DartIdentifier funcName = new DartIdentifier(functionName);
      DartUnqualifiedInvocation funcInvocation = new DartUnqualifiedInvocation(
          funcName, args);
      DartExprStmt functionStmt = new DartExprStmt(funcInvocation);
      if (oldNode != null) {
        SourceInfo sourceInfo = oldNode.getSourceInfo();
        setInstrumentedSourceInfo(functionStmt, sourceInfo);
        setInstrumentedSourceInfo(funcInvocation, sourceInfo);
        setInstrumentedSourceInfo(funcName, sourceInfo);
        for (DartExpression arg : args) {
          setInstrumentedSourceInfo(arg, sourceInfo);
        }
      }
      return functionStmt;
    }

    void setInstrumentedSourceInfo(DartNode node, SourceInfo info) {
      node.setInstrumentedNode(true);
      node.setSourceInfo(info);
    }
  }

  /**
   * TotalSettingInstrumenter instruments the main function to initialize
   * coverage variables and set totals for covered entities
   */
  private class TotalSettingInstrumenter extends BaseInstrumenter {

    @Override
    public boolean visit(DartFunction x, DartContext ctx) {
      DartNode parent = x.getParent();
      if (parent instanceof DartMethodDefinition) {
        String funcName = ((DartMethodDefinition) parent).getName()
            .toString();
        if ("main".equals(funcName)) {
          DartBlock newFnBody = x.getBody();

          for (String unitName : unitsVisited) {
            int numFunctions = nullCheckingUnBox(numFunctionsMap
                .get(unitName));
            int numStatements = nullCheckingUnBox(numStatementsMap
                .get(unitName));
            int numBranches = nullCheckingUnBox(numBranchesMap
                .get(unitName));
            List<DartExpression> args = new ArrayList<DartExpression>();
            args.add(DartStringLiteral.get(unitName));
            args.add(DartIntegerLiteral.get(BigInteger
                .valueOf(numFunctions)));
            args.add(DartIntegerLiteral.get(BigInteger
                .valueOf(numStatements)));
            args.add(DartIntegerLiteral.get(BigInteger
                .valueOf(numBranches)));
            DartExprStmt callCovTotals = createFunctionCall(
                "setCoverageTotals", args, newFnBody);
            callCovTotals.setInstrumentedNode(true);
            newFnBody = prependToFnBody(newFnBody, callCovTotals);
          }

          replaceFunction(ctx, x, newFnBody);
        }
      }
      return super.visit(x, ctx);
    }

    int nullCheckingUnBox(Integer value) {
      int ret = 0;
      if (value != null) {
        ret = value.intValue();
      }
      return ret;
    }
  }

  /**
   * FunctionInstrumenter adds instrumentation to track function coverage
   */
  private class FunctionInstrumenter extends BaseInstrumenter {

    private int numFunctions;

    /**
     * This visitor method transforms:
     * 
     * myFunction(){ stmts; ... }
     * 
     * to:
     * 
     * myFunction(){ coverFunction('unit.dart', 'myFunction'); stmts; ... }
     * 
     * TODO: Cover closures as well
     */
    @Override
    public boolean visit(DartFunction x, DartContext ctx) {
      DartNode parent = x.getParent();
      if (parent instanceof DartMethodDefinition) {
        String funcName = ((DartMethodDefinition) parent).getName()
            .toString();
        DartBlock oldBody = x.getBody();
        List<DartExpression> covArgs = new ArrayList<DartExpression>();
        covArgs.add(DartStringLiteral.get(currentUnit.getSourceName()));
        covArgs.add(DartStringLiteral.get(funcName));
        DartExprStmt callCovFunc = createFunctionCall("coverFunction",
            covArgs, oldBody);
        DartBlock newFnBody = prependToFnBody(oldBody, callCovFunc);
        replaceFunction(ctx, x, newFnBody);
        numFunctions++;
      }
      return super.visit(x, ctx);
    }

    /**
     * Initialize function counter
     */
    @Override
    public boolean visit(DartUnit x, DartContext ctx) {
      numFunctions = 0;
      return super.visit(x, ctx);
    }

    /**
     * Populate number of functions for current unit
     */
    @Override
    public void endVisit(DartUnit x, DartContext ctx) {
      numFunctionsMap.put(currentUnit.getSourceName(), numFunctions);
      super.endVisit(x, ctx);
    }

  }

  /**
   * StatementInstrumenter adds instrumentation before each statement to
   * capture runtime coverage of that statement
   */
  private class StatementInstrumenter extends BaseInstrumenter {
    private int numStatements;

    /**
     * Initialize statement counter
     */
    @Override
    public boolean visit(DartUnit x, DartContext ctx) {
      numStatements = 0;
      return super.visit(x, ctx);
    }

    /**
     * Populate number of statements for current unit
     */
    @Override
    public void endVisit(DartUnit x, DartContext ctx) {
      numStatementsMap.put(currentUnit.getSourceName(), numStatements);
      super.endVisit(x, ctx);
    }

    /**
     * This visitor method transforms:
     * 
     * { stmts; ... }
     * 
     * to:
     * 
     * { coverStatement('unit.dart', lineNum1); stmt1; 
     *   coverStatement('unit.dart', lineNum2); stmt2;
     * ... }
     * 
     */
    @Override
    public boolean visit(DartBlock x, DartContext ctx) {
      List<DartStatement> newStmts = new ArrayList<DartStatement>();
      for (DartStatement stmt : x.getStatements()) {
        if (!stmt.isInstrumentedNode()) {
          List<DartExpression> covArgs = new ArrayList<DartExpression>();
          covArgs.add(DartStringLiteral.get(currentUnit
              .getSourceName()));
          covArgs.add(DartIntegerLiteral.get(BigInteger.valueOf(stmt
              .getSourceLine())));
          DartExprStmt callCoverStmt = createFunctionCall(
              "coverStatement", covArgs, stmt);
          newStmts.add(callCoverStmt);
        }
        newStmts.add(stmt);
        numStatements++;
      }
      DartBlock newBlock = new DartBlock(newStmts);
      ctx.replaceMe(newBlock);
      return super.visit(x, ctx);
    }

  }

  /**
   * BranchInstrumenter captures runtime execution of each branch in the
   * program by adding instrumentation at each branch point
   */
  private class BranchInstrumenter extends BaseInstrumenter {
    private int numBranches;

    @Override
    public boolean visit(DartUnit x, DartContext ctx) {
      numBranches = 0;
      return super.visit(x, ctx);
    }

    @Override
    public void endVisit(DartUnit x, DartContext ctx) {
      numBranchesMap.put(currentUnit.getSourceName(), numBranches);
      super.endVisit(x, ctx);
    }

    /**
     * 
     * This visitor method transforms:
     * 
     * if { stmts; ... }
     * else { ... }
     *
     * to:
     * 
     * if { coverBranch('unit.dart', lineNum1, startLineNum); stmts; ... }
     * else { coverBranch('unit.dart', lineNum1, startLineNum); ... }
     *
     * A synthetic else is added to track the non-if branch if there is no else
     *
     * Post-order instrumentation is needed to handle nested ifs and
     * synthetic else
     */
    @Override
    public void endVisit(DartIfStatement x, DartContext ctx) {
      DartIfStatement newIfStmt;
      DartStatement thenStmt = x.getThenStatement();
      DartStatement elseStmt = x.getElseStatement();

      List<DartStatement> newThen = doCallCoverBranch(thenStmt);
      numBranches++;
      if (thenStmt instanceof DartBlock) {
        List<DartStatement> stmts = ((DartBlock) thenStmt)
            .getStatements();
        if (stmts != null) {
          newThen.addAll(stmts);
        }
      } else {
        newThen.add(thenStmt);
      }

      if (elseStmt instanceof DartIfStatement) {
        newIfStmt = new DartIfStatement(x.getCondition(),
            new DartBlock(newThen), elseStmt);
      } else {
        List<DartStatement> newElse;
        if (elseStmt != null) {
          newElse = doCallCoverBranch(elseStmt);
          if (elseStmt instanceof DartBlock) {
            List<DartStatement> stmts = ((DartBlock) elseStmt)
                .getStatements();
            if (stmts != null) {
              newElse.addAll(stmts);
            }
          } else {
            newElse.add(elseStmt);
          }
        } else {
          // Although else block is missing, there is a branch which
          // doesn't cover the IfStatement
          // So, we need to add a synthetic else block to track that
          newElse = doCallCoverBranch(x);
        }
        newIfStmt = new DartIfStatement(x.getCondition(),
            new DartBlock(newThen), new DartBlock(newElse));
        numBranches++;
      }
      newIfStmt.setSourceInfo(x.getSourceInfo());
      ctx.replaceMe(newIfStmt);
      super.endVisit(x, ctx);
    }

    /**
     * This method instruments all non-empty switch case blocks and the
     * default block. It inserts a synthetic default statement if one
     * doesn't exist.
     * This visitor method transforms:
     * 
     * switch(var a) { 
     *   case a: ...;
     *   case b: ...;
     * }
     *
     * to:
     * 
     * switch(var a) { 
     *   case a: coverBranch('unit.dart', lineNum1, startLineNum1); ...;
     *   case b: coverBranch('unit.dart', lineNum2, startLineNum2); ...;
     *   default: coverBranch('unit.dart', lineNum3, startLineNum3); ...;
     * }
     * 
     * The existing code ignores empty switch cases.
     * 
     * For tracking branch on empty cases, this logic won't work directly
     * since instrumenting empty cases will throw a FallThroughError at
     * runtime. For achieving this, the switch needs to be transformed into
     * an if. Its slightly complicated but here is what I think the
     * transformation should be:
     * 
     * switch(expr) {
     *   case 'a': // empty switch case 
     *   case 'b': do1(); break;
     *   case 'c': do2(); break;
     *   default: doDefault();
     * }
     * 
     * should be transformed to:
     * 
     * var tmp = expr;
     * if( (tmp == 'a' && coverBranch(..)) || (tmp == 'b' &&
     *   coverBranch(..))) {
     *   do1(); 
     * } else if (tmp == 'a' && coverBranch(..)) {
     *   do2();
     * } else {
     *   coverBranch(..); 
     *   doDefault();
     * }
     *
     * However, I don't see much value in covering empty cases and hence 
     * this was written like described.
     */
    @Override
    public void endVisit(DartSwitchStatement x, DartContext ctx) {
      List<DartSwitchMember> newSwitchMembers = 
        new ArrayList<DartSwitchMember>();
      boolean hasDefault = false;
      for (DartSwitchMember swMember : x.getMembers()) {
        List<DartStatement> stmts = doCallCoverBranch(swMember);
        List<DartStatement> oldStmts = swMember.getStatements();
        if (oldStmts == null || oldStmts.size() == 0) {
          newSwitchMembers.add(swMember);
          continue; // Ignore empty cases
        } else {
          stmts.addAll(oldStmts);
        }

        assert (swMember instanceof DartCase || 
          swMember instanceof DartDefault);

        DartSwitchMember newMember;
        if (swMember instanceof DartCase) {
          newMember = new DartCase(((DartCase) swMember).getExpr(),
              swMember.getLabel(), stmts);
        } else {
          hasDefault = true;
          newMember = new DartDefault(swMember.getLabel(), stmts);
        }
        setInstrumentedSourceInfo(newMember, swMember);
        newSwitchMembers.add(newMember);
        numBranches++;
      }

      if (!hasDefault) {
        List<DartStatement> statements = doCallCoverBranch(x);
        DartSwitchMember defaultMember = new DartDefault(null,
            statements);
        newSwitchMembers.add(defaultMember);
        numBranches++;
      }

      DartSwitchStatement newSwitch = new DartSwitchStatement(
          x.getExpression(), newSwitchMembers);
      newSwitch.setSourceInfo(x.getSourceInfo());

      ctx.replaceMe(newSwitch);
      super.visit(x, ctx);
    }

    /**
     * The instrumentation is similar to if and switch.
     * A synthetic finally block is inserted if not present.
     */

    @Override
    public void endVisit(DartTryStatement x, DartContext ctx) {
      DartBlock tryBlock = x.getTryBlock(), finallyBlock = x
          .getFinallyBlock();
      List<DartCatchBlock> catchBlocks = x.getCatchBlocks();

      List<DartStatement> tryStmts = doCallCoverBranch(tryBlock);
      if (tryBlock != null && tryBlock.getStatements() != null) {
        tryStmts.addAll(tryBlock.getStatements());
      }
      DartBlock newTryBlock = new DartBlock(tryStmts);
      setInstrumentedSourceInfo(newTryBlock, tryBlock.getSourceInfo());
      numBranches++;

      List<DartCatchBlock> newCatchBlocks = null;
      if (catchBlocks != null) {
        newCatchBlocks = new ArrayList<DartCatchBlock>();
        for (DartCatchBlock cBlock : catchBlocks) {
          DartBlock oldBlock = cBlock.getBlock();

          List<DartStatement> cBlockStmts = doCallCoverBranch(cBlock);
          if (oldBlock != null && oldBlock.getStatements() != null) {
            cBlockStmts.addAll(oldBlock.getStatements());
          }
          DartBlock newBlock = new DartBlock(cBlockStmts);
          setInstrumentedSourceInfo(newBlock,
              oldBlock.getSourceInfo());

          DartCatchBlock newCatchBlock = new DartCatchBlock(newBlock,
              cBlock.getException(), cBlock.getStackTrace());
          setInstrumentedSourceInfo(newCatchBlock,
              cBlock.getSourceInfo());

          newCatchBlocks.add(newCatchBlock);
          numBranches++;
        }
      }
      
      DartBlock newFinallyBlock = null;
      if(finallyBlock != null){
        List<DartStatement> finallyStmts = doCallCoverBranch(finallyBlock);
        if(finallyBlock.getStatements() != null){
          finallyStmts.addAll(finallyBlock.getStatements());
        }
        newFinallyBlock = new DartBlock(finallyStmts);
        setInstrumentedSourceInfo(newFinallyBlock, 
            finallyBlock.getSourceInfo());
      } else {
        List<DartStatement> finallyStmts = doCallCoverBranch(x);
        newFinallyBlock = new DartBlock(finallyStmts);
        setInstrumentedSourceInfo(newFinallyBlock, x.getSourceInfo());
      }
      numBranches++;
      
      DartTryStatement newTry = new DartTryStatement(tryBlock,
          newCatchBlocks, newFinallyBlock);
      ctx.replaceMe(newTry);
      super.endVisit(x, ctx);
    }

    /**
     * Rewrite all loops in this block
     * 
     * While loop is transformed from this:
     * 
     * while(cond) { stmts; }
     * 
     * to:
     * 
     * loopBranchBefore('unit.dart', loopLine, loopStart);
     * while(cond) { 
     *   loopBranchInside('unit.dart', loopLine, loopStart);
     *   stmts;
     * }
     * coverLoopBranch('unit.dart', loopLine, loopStart);
     * 
     * We track two branches for every loop - one that goes inside and one that
     * doesn't execute the loop at all. This is tracked by resetting/setting
     * a variable from loopBranchBefore and loopBranchInside, which is checked
     * in coverLoopBranch to decide which branch was taken.
     */
    @Override
    public void endVisit(DartBlock x, DartContext ctx) {
      List<DartStatement> blockStmts = new ArrayList<DartStatement>(); 
      for(DartStatement stmt : x.getStatements()) {
        if(stmt instanceof DartForInStatement) {
          doLoopBefore(stmt, blockStmts);
          
          DartForInStatement oldForIn = (DartForInStatement) stmt;
          DartStatement setup = null;
          if(oldForIn.introducesVariable()){
            setup = oldForIn.getVariableStatement();
          } else {
            setup = new DartExprStmt(oldForIn.getIdentifier());
          }
          DartBlock body = doLoopInside(stmt, oldForIn.getBody());
          DartForInStatement newForIn = 
              new DartForInStatement(setup, oldForIn.getIterable(), body);
          setInstrumentedSourceInfo(newForIn, oldForIn.getSourceInfo());
          
          doLoopAfter(stmt, blockStmts);
          numBranches+=2;
        } else if (stmt instanceof DartForStatement) {
          doLoopBefore(stmt, blockStmts);
          
          DartForStatement oldFor = (DartForStatement) stmt;
          DartBlock body = doLoopInside(stmt, oldFor.getBody());
          DartForStatement newFor = new DartForStatement(oldFor.getInit(), 
              oldFor.getCondition(), oldFor.getIncrement(), body);
          setInstrumentedSourceInfo(newFor, oldFor.getSourceInfo());
          
          doLoopAfter(stmt, blockStmts);
          numBranches+=2;
        } else if (stmt instanceof DartWhileStatement) {
          doLoopBefore(stmt, blockStmts);
          
          DartWhileStatement oldWhile = (DartWhileStatement) stmt;
          DartBlock body = doLoopInside(stmt, oldWhile.getBody());
          DartWhileStatement newWhile = 
              new DartWhileStatement(oldWhile.getCondition(), body);
          setInstrumentedSourceInfo(newWhile, oldWhile.getSourceInfo());
          
          doLoopAfter(stmt, blockStmts);
          numBranches+=2;
        } else if (stmt instanceof DartDoWhileStatement) {
          doLoopBefore(stmt, blockStmts);
          
          DartDoWhileStatement oldDoWhile = (DartDoWhileStatement) stmt;
          DartBlock body = doLoopInside(stmt, oldDoWhile.getBody());
          DartDoWhileStatement newDoWhile = 
              new DartDoWhileStatement(oldDoWhile.getCondition(), body);
          setInstrumentedSourceInfo(newDoWhile, oldDoWhile.getSourceInfo());
          
          doLoopAfter(stmt, blockStmts);
          numBranches+=2;
        } else {
          blockStmts.add(stmt);
        }
      }
      
      super.visit(x, ctx);
    }

    /**
     * Adds function call to track coverage of a branch represented by
     * blockNode
     * 
     * @param blockNode
     * @return
     */
    private List<DartStatement> doCallCoverBranch(DartNode blockNode) {
      List<DartStatement> newBlockStmts = new ArrayList<DartStatement>();
      List<DartExpression> covArgs = makeCoverageArgs(blockNode);
      DartExprStmt callCoverBranch = createFunctionCall("coverBranch",
          covArgs, blockNode);
      newBlockStmts.add(callCoverBranch);
      setInstrumentedSourceInfo(callCoverBranch,
          blockNode.getSourceInfo());
      return newBlockStmts;
    }
    
    private void doLoopBefore(DartNode loopNode, List<DartStatement> stmts) {
      List<DartExpression> args = makeCoverageArgs(loopNode);
      DartExprStmt callLoopBefore = 
          createFunctionCall("loopBranchBefore", args, loopNode);
      stmts.add(callLoopBefore);
    }
    
    private void doLoopAfter(DartNode loopNode, List<DartStatement> stmts) {
      List<DartExpression> args = makeCoverageArgs(loopNode);
      args.add(DartIntegerLiteral.get(BigInteger.valueOf(
          loopNode.getSourceStart() + loopNode.getSourceLength())));
      DartExprStmt callLoopAfter = 
          createFunctionCall("coverLoopBranch", args, loopNode);
      stmts.add(callLoopAfter);
    }
    
    private DartBlock doLoopInside(DartNode loopNode, DartStatement body) {
      List<DartStatement> newBlockStmts = new ArrayList<DartStatement>();
      List<DartExpression> covArgs = makeCoverageArgs(loopNode);
      DartExprStmt callCoverBranch = createFunctionCall("loopBranchInside",
          covArgs, loopNode);
      newBlockStmts.add(callCoverBranch);
      setInstrumentedSourceInfo(callCoverBranch,
          loopNode.getSourceInfo());
      
      if(body instanceof DartBlock) {
        newBlockStmts.addAll(((DartBlock) body).getStatements());
      } else {
        newBlockStmts.add(body);
      }
      
      return new DartBlock(newBlockStmts);
    }

    private List<DartExpression> makeCoverageArgs(DartNode blockNode) {
      List<DartExpression> covArgs = new ArrayList<DartExpression>();
      covArgs.add(DartStringLiteral.get(currentUnit.getSourceName()));
      covArgs.add(DartIntegerLiteral.get(BigInteger.valueOf(blockNode
          .getSourceLine())));
      covArgs.add(DartIntegerLiteral.get(BigInteger.valueOf(blockNode
          .getSourceStart())));
      return covArgs;
    }
  }

}
