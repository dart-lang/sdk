// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa.tracer;

import '../../compiler_new.dart' show OutputSink;
import '../diagnostics/invariant.dart' show DEBUG_MODE;
import '../js_backend/namer.dart' show Namer;
import '../tracer.dart';
import '../world.dart' show ClosedWorld;
import 'nodes.dart';

/**
 * Outputs SSA code in a format readable by Hydra IR.
 * Tracing is disabled by default, see ../tracer.dart for how
 * to enable it.
 */
class HTracer extends HGraphVisitor with TracerUtil {
  final ClosedWorld closedWorld;
  final Namer namer;
  final OutputSink output;

  HTracer(this.output, this.closedWorld, this.namer);

  void traceGraph(String name, HGraph graph) {
    DEBUG_MODE = true;
    tag("cfg", () {
      printProperty("name", name);
      visitDominatorTree(graph);
    });
  }

  void addPredecessors(HBasicBlock block) {
    if (block.predecessors.isEmpty) {
      printEmptyProperty("predecessors");
    } else {
      addIndent();
      add("predecessors");
      for (HBasicBlock predecessor in block.predecessors) {
        add(' "B${predecessor.id}"');
      }
      add("\n");
    }
  }

  void addSuccessors(HBasicBlock block) {
    if (block.successors.isEmpty) {
      printEmptyProperty("successors");
    } else {
      addIndent();
      add("successors");
      for (HBasicBlock successor in block.successors) {
        add(' "B${successor.id}"');
      }
      add("\n");
    }
  }

  void addInstructions(
      HInstructionStringifier stringifier, HInstructionList list) {
    for (HInstruction instruction = list.first;
        instruction != null;
        instruction = instruction.next) {
      int bci = 0;
      int uses = instruction.usedBy.length;
      String changes = instruction.sideEffects.hasSideEffects() ? '!' : ' ';
      String depends = instruction.sideEffects.dependsOnSomething() ? '?' : '';
      addIndent();
      String temporaryId = stringifier.temporaryId(instruction);
      String instructionString = stringifier.visit(instruction);
      add("$bci $uses $temporaryId $instructionString $changes $depends <|@\n");
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstructionStringifier stringifier =
        new HInstructionStringifier(block, closedWorld, namer);
    assert(block.id != null);
    tag("block", () {
      printProperty("name", "B${block.id}");
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      addPredecessors(block);
      addSuccessors(block);
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      if (block.dominator != null) {
        printProperty("dominator", "B${block.dominator.id}");
      }
      tag("states", () {
        tag("locals", () {
          printProperty("size", 0);
          printProperty("method", "None");
          block.forEachPhi((phi) {
            String phiId = stringifier.temporaryId(phi);
            StringBuffer inputIds = new StringBuffer();
            for (int i = 0; i < phi.inputs.length; i++) {
              inputIds.write(stringifier.temporaryId(phi.inputs[i]));
              inputIds.write(" ");
            }
            println("${phi.id} $phiId [ $inputIds]");
          });
        });
      });
      tag("HIR", () {
        addInstructions(stringifier, block.phis);
        addInstructions(stringifier, block);
      });
    });
  }
}

class HInstructionStringifier implements HVisitor<String> {
  final ClosedWorld closedWorld;
  final Namer namer;
  final HBasicBlock currentBlock;

  HInstructionStringifier(this.currentBlock, this.closedWorld, this.namer);

  visit(HInstruction node) => '${node.accept(this)} ${node.instructionType}';

  String temporaryId(HInstruction instruction) {
    String prefix;
    if (instruction.isNull()) {
      prefix = 'u';
    } else if (instruction.isConflicting()) {
      prefix = 'c';
    } else if (instruction.isExtendableArray(closedWorld)) {
      prefix = 'e';
    } else if (instruction.isFixedArray(closedWorld)) {
      prefix = 'f';
    } else if (instruction.isMutableArray(closedWorld)) {
      prefix = 'm';
    } else if (instruction.isReadableArray(closedWorld)) {
      prefix = 'a';
    } else if (instruction.isString(closedWorld)) {
      prefix = 's';
    } else if (instruction.isIndexablePrimitive(closedWorld)) {
      prefix = 'r';
    } else if (instruction.isBoolean(closedWorld)) {
      prefix = 'b';
    } else if (instruction.isInteger(closedWorld)) {
      prefix = 'i';
    } else if (instruction.isDouble(closedWorld)) {
      prefix = 'd';
    } else if (instruction.isNumber(closedWorld)) {
      prefix = 'n';
    } else if (instruction.instructionType.containsAll(closedWorld)) {
      prefix = 'v';
    } else {
      prefix = 'U';
    }
    return "$prefix${instruction.id}";
  }

  String visitBoolify(HBoolify node) {
    return "Boolify: ${temporaryId(node.inputs[0])}";
  }

  String handleInvokeBinary(HInvokeBinary node, String opcode) {
    String left = temporaryId(node.left);
    String right = temporaryId(node.right);
    return '$opcode: $left $right';
  }

  String visitAdd(HAdd node) => handleInvokeBinary(node, 'Add');

  String visitBitAnd(HBitAnd node) => handleInvokeBinary(node, 'BitAnd');

  String visitBitNot(HBitNot node) {
    String operand = temporaryId(node.operand);
    return "BitNot: $operand";
  }

  String visitBitOr(HBitOr node) => handleInvokeBinary(node, 'BitOr');

  String visitBitXor(HBitXor node) => handleInvokeBinary(node, 'BitXor');

  String visitBoundsCheck(HBoundsCheck node) {
    String lengthId = temporaryId(node.length);
    String indexId = temporaryId(node.index);
    return "BoundsCheck: length = $lengthId, index = $indexId";
  }

  String visitBreak(HBreak node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label != null) {
      return "Break ${node.label.labelName}: (B${target.id})";
    }
    return "Break: (B${target.id})";
  }

  String visitConstant(HConstant constant) => "Constant: ${constant.constant}";

  String visitContinue(HContinue node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label != null) {
      return "Continue ${node.label.labelName}: (B${target.id})";
    }
    return "Continue: (B${target.id})";
  }

  String visitCreate(HCreate node) {
    return handleGenericInvoke("Create", "${node.element.name}", node.inputs);
  }

  String visitCreateBox(HCreateBox node) {
    return handleGenericInvoke("CreateBox", "", node.inputs);
  }

  String visitDivide(HDivide node) => handleInvokeBinary(node, 'Divide');

  String visitExit(HExit node) => "Exit";

  String visitFieldGet(HFieldGet node) {
    if (node.isNullCheck) {
      return 'FieldGet: NullCheck ${temporaryId(node.receiver)}';
    }
    String fieldName = node.element.name;
    return 'FieldGet: ${temporaryId(node.receiver)}.$fieldName';
  }

  String visitFieldSet(HFieldSet node) {
    String valueId = temporaryId(node.value);
    String fieldName = node.element.name;
    return 'FieldSet: ${temporaryId(node.receiver)}.$fieldName to $valueId';
  }

  String visitReadModifyWrite(HReadModifyWrite node) {
    String fieldName = node.element.name;
    String receiverId = temporaryId(node.receiver);
    String op = node.jsOp;
    if (node.isAssignOp) {
      String valueId = temporaryId(node.value);
      return 'ReadModifyWrite: $receiverId.$fieldName $op= $valueId';
    } else if (node.isPreOp) {
      return 'ReadModifyWrite: $op$receiverId.$fieldName';
    } else {
      return 'ReadModifyWrite: $receiverId.$fieldName$op';
    }
  }

  String visitGetLength(HGetLength node) {
    return 'GetLength: ${temporaryId(node.receiver)}';
  }

  String visitLocalGet(HLocalGet node) {
    String localName = node.variable.name;
    return 'LocalGet: ${temporaryId(node.local)}.$localName';
  }

  String visitLocalSet(HLocalSet node) {
    String valueId = temporaryId(node.value);
    String localName = node.variable.name;
    return 'LocalSet: ${temporaryId(node.local)}.$localName to $valueId';
  }

  String visitGoto(HGoto node) {
    HBasicBlock target = currentBlock.successors[0];
    return "Goto: (B${target.id})";
  }

  String visitGreater(HGreater node) => handleInvokeBinary(node, 'Greater');
  String visitGreaterEqual(HGreaterEqual node) {
    return handleInvokeBinary(node, 'GreaterEqual');
  }

  String visitIdentity(HIdentity node) => handleInvokeBinary(node, 'Identity');

  String visitIf(HIf node) {
    HBasicBlock thenBlock = currentBlock.successors[0];
    HBasicBlock elseBlock = currentBlock.successors[1];
    String conditionId = temporaryId(node.inputs[0]);
    return "If ($conditionId): (B${thenBlock.id}) else (B${elseBlock.id})";
  }

  String handleGenericInvoke(
      String invokeType, String functionName, List<HInstruction> arguments) {
    StringBuffer argumentsString = new StringBuffer();
    for (int i = 0; i < arguments.length; i++) {
      if (i != 0) argumentsString.write(", ");
      argumentsString.write(temporaryId(arguments[i]));
    }
    return "$invokeType: $functionName($argumentsString)";
  }

  String visitIndex(HIndex node) {
    String receiver = temporaryId(node.receiver);
    String index = temporaryId(node.index);
    return "Index: $receiver[$index]";
  }

  String visitIndexAssign(HIndexAssign node) {
    String receiver = temporaryId(node.receiver);
    String index = temporaryId(node.index);
    String value = temporaryId(node.value);
    return "IndexAssign: $receiver[$index] = $value";
  }

  String visitInterceptor(HInterceptor node) {
    String value = temporaryId(node.inputs[0]);
    if (node.interceptedClasses != null) {
      String cls = namer.suffixForGetInterceptor(node.interceptedClasses);
      return "Interceptor ($cls): $value";
    }
    return "Interceptor: $value";
  }

  String visitInvokeClosure(HInvokeClosure node) =>
      handleInvokeDynamic(node, "InvokeClosure");

  String handleInvokeDynamic(HInvokeDynamic invoke, String kind) {
    String receiver = temporaryId(invoke.receiver);
    String name = invoke.selector.name;
    String target = "$receiver.$name";
    int offset = HInvoke.ARGUMENTS_OFFSET;
    List arguments = invoke.inputs.sublist(offset);
    return handleGenericInvoke(kind, target, arguments) + "(${invoke.mask})";
  }

  String visitInvokeDynamicMethod(HInvokeDynamicMethod node) =>
      handleInvokeDynamic(node, "InvokeDynamicMethod");
  String visitInvokeDynamicGetter(HInvokeDynamicGetter node) =>
      handleInvokeDynamic(node, "InvokeDynamicGetter");
  String visitInvokeDynamicSetter(HInvokeDynamicSetter node) =>
      handleInvokeDynamic(node, "InvokeDynamicSetter");

  String visitInvokeStatic(HInvokeStatic invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeStatic", target, invoke.inputs);
  }

  String visitInvokeSuper(HInvokeSuper invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeSuper", target, invoke.inputs);
  }

  String visitInvokeConstructorBody(HInvokeConstructorBody invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeConstructorBody", target, invoke.inputs);
  }

  String visitForeignCode(HForeignCode node) {
    var template = node.codeTemplate;
    String code = '${template.ast}';
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "ForeignCode: $code ($inputs)";
  }

  String visitLess(HLess node) => handleInvokeBinary(node, 'Less');
  String visitLessEqual(HLessEqual node) =>
      handleInvokeBinary(node, 'LessEqual');

  String visitLiteralList(HLiteralList node) {
    StringBuffer elementsString = new StringBuffer();
    for (int i = 0; i < node.inputs.length; i++) {
      if (i != 0) elementsString.write(", ");
      elementsString.write(temporaryId(node.inputs[i]));
    }
    return "LiteralList: [$elementsString]";
  }

  String visitLoopBranch(HLoopBranch branch) {
    HBasicBlock bodyBlock = currentBlock.successors[0];
    HBasicBlock exitBlock = currentBlock.successors[1];
    String conditionId = temporaryId(branch.inputs[0]);
    return "LoopBranch ($conditionId): (B${bodyBlock.id}) then (B${exitBlock.id})";
  }

  String visitMultiply(HMultiply node) => handleInvokeBinary(node, 'Multiply');

  String visitNegate(HNegate node) {
    String operand = temporaryId(node.operand);
    return "Negate: $operand";
  }

  String visitNot(HNot node) => "Not: ${temporaryId(node.inputs[0])}";

  String visitParameterValue(HParameterValue node) {
    return "ParameterValue: ${node.sourceElement.name}";
  }

  String visitLocalValue(HLocalValue node) {
    return "LocalValue: ${node.sourceElement.name}";
  }

  String visitPhi(HPhi phi) {
    StringBuffer buffer = new StringBuffer();
    buffer.write("Phi: ");
    for (int i = 0; i < phi.inputs.length; i++) {
      if (i > 0) buffer.write(", ");
      buffer.write(temporaryId(phi.inputs[i]));
    }
    return buffer.toString();
  }

  String visitRef(HRef node) {
    return 'Ref: ${temporaryId(node.value)}';
  }

  String visitReturn(HReturn node) => "Return: ${temporaryId(node.inputs[0])}";

  String visitShiftLeft(HShiftLeft node) =>
      handleInvokeBinary(node, 'ShiftLeft');
  String visitShiftRight(HShiftRight node) =>
      handleInvokeBinary(node, 'ShiftRight');

  String visitStatic(HStatic node) => "Static: ${node.element.name}";

  String visitLazyStatic(HLazyStatic node) =>
      "LazyStatic: ${node.element.name}";

  String visitOneShotInterceptor(HOneShotInterceptor node) =>
      handleInvokeDynamic(node, "OneShotInterceptor");

  String visitStaticStore(HStaticStore node) {
    String lhs = node.element.name;
    return "StaticStore: $lhs = ${temporaryId(node.inputs[0])}";
  }

  String visitStringConcat(HStringConcat node) {
    var leftId = temporaryId(node.left);
    var rightId = temporaryId(node.right);
    return "StringConcat: $leftId + $rightId";
  }

  String visitStringify(HStringify node) {
    return "Stringify: ${temporaryId(node.inputs[0])}";
  }

  String visitSubtract(HSubtract node) => handleInvokeBinary(node, 'Subtract');

  String visitSwitch(HSwitch node) {
    StringBuffer buf = new StringBuffer();
    buf.write("Switch: (");
    buf.write(temporaryId(node.inputs[0]));
    buf.write(") ");
    for (int i = 1; i < node.inputs.length; i++) {
      buf.write(temporaryId(node.inputs[i]));
      buf.write(": B");
      buf.write(node.block.successors[i - 1].id);
      buf.write(", ");
    }
    buf.write("default: B");
    buf.write(node.defaultTarget.id);
    return buf.toString();
  }

  String visitThis(HThis node) => "This";

  String visitThrow(HThrow node) => "Throw: ${temporaryId(node.inputs[0])}";

  String visitThrowExpression(HThrowExpression node) {
    return "ThrowExpression: ${temporaryId(node.inputs[0])}";
  }

  String visitTruncatingDivide(HTruncatingDivide node) {
    return handleInvokeBinary(node, 'TruncatingDivide');
  }

  String visitRemainder(HRemainder node) {
    return handleInvokeBinary(node, 'Remainder');
  }

  String visitExitTry(HExitTry node) {
    return "ExitTry";
  }

  String visitTry(HTry node) {
    List<HBasicBlock> successors = currentBlock.successors;
    String tryBlock = 'B${successors[0].id}';
    String catchBlock = 'none';
    if (node.catchBlock != null) {
      catchBlock = 'B${successors[1].id}';
    }

    String finallyBlock = 'none';
    if (node.finallyBlock != null) {
      finallyBlock = 'B${node.finallyBlock.id}';
    }

    return "Try: $tryBlock, Catch: $catchBlock, Finally: $finallyBlock, "
        "Join: B${successors.last.id}";
  }

  String visitIs(HIs node) {
    String type = node.typeExpression.toString();
    return "Is: ${temporaryId(node.expression)} is $type";
  }

  String visitIsViaInterceptor(HIsViaInterceptor node) {
    String type = node.typeExpression.toString();
    return "IsViaInterceptor: ${temporaryId(node.inputs[0])} is $type";
  }

  String visitTypeConversion(HTypeConversion node) {
    String checkedInput = temporaryId(node.checkedInput);
    String rest;
    if (node.inputs.length == 2) {
      rest = " ${temporaryId(node.inputs.last)}";
    } else {
      assert(node.inputs.length == 1);
      rest = "";
    }
    return "TypeConversion: $checkedInput to ${node.instructionType}$rest";
  }

  String visitTypeKnown(HTypeKnown node) {
    assert(node.inputs.length <= 2);
    String result =
        "TypeKnown: ${temporaryId(node.checkedInput)} is ${node.knownType}";
    if (node.witness != null) {
      result += " witnessed by ${temporaryId(node.witness)}";
    }
    return result;
  }

  String visitRangeConversion(HRangeConversion node) {
    return "RangeConversion: ${node.checkedInput}";
  }

  String visitTypeInfoReadRaw(HTypeInfoReadRaw node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "TypeInfoReadRaw: $inputs";
  }

  String visitTypeInfoReadVariable(HTypeInfoReadVariable node) {
    return "TypeInfoReadVariable: "
        "${temporaryId(node.inputs.single)}.${node.variable}";
  }

  String visitTypeInfoExpression(HTypeInfoExpression node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "TypeInfoExpression: ${node.kindAsString} ${node.dartType}"
        " ($inputs)";
  }

  String visitAwait(HAwait node) {
    return "Await: ${temporaryId(node.inputs[0])}";
  }

  String visitYield(HYield node) {
    return "Yield${node.hasStar ? "*" : ""}: ${temporaryId(node.inputs[0])}";
  }
}
