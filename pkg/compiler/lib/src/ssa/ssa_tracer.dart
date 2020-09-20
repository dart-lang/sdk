// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa.tracer;

import '../../compiler_new.dart' show OutputSink;
import '../diagnostics/invariant.dart' show DEBUG_MODE;
import '../inferrer/abstract_value_domain.dart';
import '../js_backend/namer.dart' show suffixForGetInterceptor;
import '../tracer.dart';
import '../world.dart' show JClosedWorld;
import 'nodes.dart';

/// Outputs SSA code in a format readable by Hydra IR.
/// Tracing is disabled by default, see ../tracer.dart for how
/// to enable it.
class HTracer extends HGraphVisitor with TracerUtil {
  final JClosedWorld closedWorld;
  @override
  final OutputSink output;

  HTracer(this.output, this.closedWorld);

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

  @override
  void visitBasicBlock(HBasicBlock block) {
    HInstructionStringifier stringifier =
        new HInstructionStringifier(block, closedWorld);
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
  final JClosedWorld closedWorld;
  final HBasicBlock currentBlock;

  HInstructionStringifier(this.currentBlock, this.closedWorld);

  AbstractValueDomain get _abstractValueDomain =>
      closedWorld.abstractValueDomain;

  visit(HInstruction node) => '${node.accept(this)} ${node.instructionType}';

  String temporaryId(HInstruction instruction) {
    String prefix;
    if (instruction.isNull(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 'u';
    } else if (instruction
        .isConflicting(_abstractValueDomain)
        .isDefinitelyTrue) {
      prefix = 'c';
    } else if (instruction
        .isExtendableArray(_abstractValueDomain)
        .isDefinitelyTrue) {
      prefix = 'e';
    } else if (instruction
        .isFixedArray(_abstractValueDomain)
        .isDefinitelyTrue) {
      prefix = 'f';
    } else if (instruction
        .isMutableArray(_abstractValueDomain)
        .isDefinitelyTrue) {
      prefix = 'm';
    } else if (instruction.isArray(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 'a';
    } else if (instruction.isString(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 's';
    } else if (instruction
        .isIndexablePrimitive(_abstractValueDomain)
        .isDefinitelyTrue) {
      prefix = 'r';
    } else if (instruction.isBoolean(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 'b';
    } else if (instruction.isInteger(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 'i';
    } else if (instruction.isDouble(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 'd';
    } else if (instruction.isNumber(_abstractValueDomain).isDefinitelyTrue) {
      prefix = 'n';
    } else if (_abstractValueDomain
        .containsAll(instruction.instructionType)
        .isPotentiallyTrue) {
      prefix = 'v';
    } else {
      prefix = 'U';
    }
    return "$prefix${instruction.id}";
  }

  @override
  String visitLateValue(HLateValue node) {
    return "LateValue: ${temporaryId(node.inputs[0])}";
  }

  String handleInvokeBinary(HInvokeBinary node, String opcode) {
    String left = temporaryId(node.left);
    String right = temporaryId(node.right);
    return '$opcode: $left $right';
  }

  @override
  String visitAbs(HAbs node) {
    String operand = temporaryId(node.operand);
    return "Abs: $operand";
  }

  @override
  String visitAdd(HAdd node) => handleInvokeBinary(node, 'Add');

  @override
  String visitBitAnd(HBitAnd node) => handleInvokeBinary(node, 'BitAnd');

  @override
  String visitBitNot(HBitNot node) {
    String operand = temporaryId(node.operand);
    return "BitNot: $operand";
  }

  @override
  String visitBitOr(HBitOr node) => handleInvokeBinary(node, 'BitOr');

  @override
  String visitBitXor(HBitXor node) => handleInvokeBinary(node, 'BitXor');

  @override
  String visitBoundsCheck(HBoundsCheck node) {
    String lengthId = temporaryId(node.length);
    String indexId = temporaryId(node.index);
    return "BoundsCheck: length = $lengthId, index = $indexId";
  }

  @override
  String visitBreak(HBreak node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label != null) {
      return "Break ${node.label.labelName}: (B${target.id})";
    }
    return "Break: (B${target.id})";
  }

  @override
  String visitConstant(HConstant constant) => "Constant: ${constant.constant}";

  @override
  String visitContinue(HContinue node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label != null) {
      return "Continue ${node.label.labelName}: (B${target.id})";
    }
    return "Continue: (B${target.id})";
  }

  @override
  String visitCreate(HCreate node) {
    return handleGenericInvoke("Create", "${node.element.name}", node.inputs);
  }

  @override
  String visitCreateBox(HCreateBox node) {
    return handleGenericInvoke("CreateBox", "", node.inputs);
  }

  @override
  String visitDivide(HDivide node) => handleInvokeBinary(node, 'Divide');

  @override
  String visitExit(HExit node) => "Exit";

  @override
  String visitFieldGet(HFieldGet node) {
    String fieldName = node.element.name;
    return 'FieldGet: ${temporaryId(node.receiver)}.$fieldName';
  }

  @override
  String visitFieldSet(HFieldSet node) {
    String valueId = temporaryId(node.value);
    String fieldName = node.element.name;
    return 'FieldSet: ${temporaryId(node.receiver)}.$fieldName to $valueId';
  }

  @override
  String visitFunctionReference(HFunctionReference node) {
    return 'FunctionReference: ${node.element}';
  }

  @override
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

  @override
  String visitGetLength(HGetLength node) {
    return 'GetLength: ${temporaryId(node.receiver)}';
  }

  @override
  String visitLocalGet(HLocalGet node) {
    String localName = node.variable.name;
    return 'LocalGet: ${temporaryId(node.receiver)}.$localName';
  }

  @override
  String visitLocalSet(HLocalSet node) {
    String valueId = temporaryId(node.value);
    String localName = node.variable.name;
    return 'LocalSet: ${temporaryId(node.receiver)}.$localName to $valueId';
  }

  @override
  String visitGoto(HGoto node) {
    HBasicBlock target = currentBlock.successors[0];
    return "Goto: (B${target.id})";
  }

  @override
  String visitGreater(HGreater node) => handleInvokeBinary(node, 'Greater');
  @override
  String visitGreaterEqual(HGreaterEqual node) {
    return handleInvokeBinary(node, 'GreaterEqual');
  }

  @override
  String visitIdentity(HIdentity node) => handleInvokeBinary(node, 'Identity');

  @override
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

  @override
  String visitIndex(HIndex node) {
    String receiver = temporaryId(node.receiver);
    String index = temporaryId(node.index);
    return "Index: $receiver[$index]";
  }

  @override
  String visitIndexAssign(HIndexAssign node) {
    String receiver = temporaryId(node.receiver);
    String index = temporaryId(node.index);
    String value = temporaryId(node.value);
    return "IndexAssign: $receiver[$index] = $value";
  }

  @override
  String visitInterceptor(HInterceptor node) {
    String value = temporaryId(node.inputs[0]);
    if (node.interceptedClasses != null) {
      String cls = suffixForGetInterceptor(closedWorld.commonElements,
          closedWorld.nativeData, node.interceptedClasses);
      return "Interceptor (${cls}): $value";
    }
    return "Interceptor: $value";
  }

  @override
  String visitInvokeClosure(HInvokeClosure node) =>
      handleInvokeDynamic(node, "InvokeClosure");

  String handleInvokeDynamic(HInvokeDynamic invoke, String kind) {
    String receiver = temporaryId(invoke.receiver);
    String name = invoke.selector.name;
    String target = "$receiver.$name";
    int offset = HInvoke.ARGUMENTS_OFFSET;
    List arguments = invoke.inputs.sublist(offset);
    return handleGenericInvoke(kind, target, arguments) +
        "(${invoke.receiverType})";
  }

  @override
  String visitInvokeDynamicMethod(HInvokeDynamicMethod node) =>
      handleInvokeDynamic(node, "InvokeDynamicMethod");
  @override
  String visitInvokeDynamicGetter(HInvokeDynamicGetter node) =>
      handleInvokeDynamic(node, "InvokeDynamicGetter");
  @override
  String visitInvokeDynamicSetter(HInvokeDynamicSetter node) =>
      handleInvokeDynamic(node, "InvokeDynamicSetter");

  @override
  String visitInvokeStatic(HInvokeStatic invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeStatic", target, invoke.inputs);
  }

  @override
  String visitInvokeSuper(HInvokeSuper invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeSuper", target, invoke.inputs);
  }

  @override
  String visitInvokeConstructorBody(HInvokeConstructorBody invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeConstructorBody", target, invoke.inputs);
  }

  @override
  String visitInvokeGeneratorBody(HInvokeGeneratorBody invoke) {
    String target = invoke.element.name;
    return handleGenericInvoke("InvokeGeneratorBody", target, invoke.inputs);
  }

  @override
  String visitInvokeExternal(HInvokeExternal node) {
    var target = node.element;
    var inputs = node.inputs;
    String targetString;
    if (target.isInstanceMember) {
      targetString = temporaryId(inputs.first) + '.${target.name}';
      inputs = inputs.sublist(1);
    } else {
      targetString = target.name;
    }
    return handleGenericInvoke('InvokeExternal', targetString, inputs);
  }

  @override
  String visitForeignCode(HForeignCode node) {
    var template = node.codeTemplate;
    String code = '${template.ast}';
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "ForeignCode: $code ($inputs)";
  }

  @override
  String visitLess(HLess node) => handleInvokeBinary(node, 'Less');
  @override
  String visitLessEqual(HLessEqual node) =>
      handleInvokeBinary(node, 'LessEqual');

  @override
  String visitLiteralList(HLiteralList node) {
    StringBuffer elementsString = new StringBuffer();
    for (int i = 0; i < node.inputs.length; i++) {
      if (i != 0) elementsString.write(", ");
      elementsString.write(temporaryId(node.inputs[i]));
    }
    return "LiteralList: [$elementsString]";
  }

  @override
  String visitLoopBranch(HLoopBranch branch) {
    HBasicBlock bodyBlock = currentBlock.successors[0];
    HBasicBlock exitBlock = currentBlock.successors[1];
    String conditionId = temporaryId(branch.inputs[0]);
    return "LoopBranch ($conditionId): (B${bodyBlock.id}) then (B${exitBlock.id})";
  }

  @override
  String visitMultiply(HMultiply node) => handleInvokeBinary(node, 'Multiply');

  @override
  String visitNegate(HNegate node) {
    String operand = temporaryId(node.operand);
    return "Negate: $operand";
  }

  @override
  String visitNot(HNot node) => "Not: ${temporaryId(node.inputs[0])}";

  @override
  String visitParameterValue(HParameterValue node) {
    return "ParameterValue: ${node.sourceElement.name}";
  }

  @override
  String visitLocalValue(HLocalValue node) {
    return "LocalValue: ${node.sourceElement.name}";
  }

  @override
  String visitPhi(HPhi phi) {
    StringBuffer buffer = new StringBuffer();
    buffer.write("Phi: ");
    for (int i = 0; i < phi.inputs.length; i++) {
      if (i > 0) buffer.write(", ");
      buffer.write(temporaryId(phi.inputs[i]));
    }
    return buffer.toString();
  }

  @override
  String visitRef(HRef node) {
    return 'Ref: ${temporaryId(node.value)}';
  }

  @override
  String visitReturn(HReturn node) {
    if (node.inputs.isEmpty) return "Return";
    return "Return: ${temporaryId(node.inputs.single)}";
  }

  @override
  String visitShiftLeft(HShiftLeft node) =>
      handleInvokeBinary(node, 'ShiftLeft');
  @override
  String visitShiftRight(HShiftRight node) =>
      handleInvokeBinary(node, 'ShiftRight');

  @override
  String visitStatic(HStatic node) => "Static: ${node.element.name}";

  @override
  String visitLazyStatic(HLazyStatic node) =>
      "LazyStatic: ${node.element.name}";

  @override
  String visitOneShotInterceptor(HOneShotInterceptor node) =>
      handleInvokeDynamic(node, "OneShotInterceptor");

  @override
  String visitStaticStore(HStaticStore node) {
    String lhs = node.element.name;
    return "StaticStore: $lhs = ${temporaryId(node.inputs[0])}";
  }

  @override
  String visitStringConcat(HStringConcat node) {
    var leftId = temporaryId(node.left);
    var rightId = temporaryId(node.right);
    return "StringConcat: $leftId + $rightId";
  }

  @override
  String visitStringify(HStringify node) {
    return "Stringify: ${temporaryId(node.inputs[0])}";
  }

  @override
  String visitSubtract(HSubtract node) => handleInvokeBinary(node, 'Subtract');

  @override
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

  @override
  String visitThis(HThis node) => "This";

  @override
  String visitThrow(HThrow node) => "Throw: ${temporaryId(node.inputs[0])}";

  @override
  String visitThrowExpression(HThrowExpression node) {
    return "ThrowExpression: ${temporaryId(node.inputs[0])}";
  }

  @override
  String visitTruncatingDivide(HTruncatingDivide node) {
    return handleInvokeBinary(node, 'TruncatingDivide');
  }

  @override
  String visitRemainder(HRemainder node) {
    return handleInvokeBinary(node, 'Remainder');
  }

  @override
  String visitExitTry(HExitTry node) {
    return "ExitTry";
  }

  @override
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

  @override
  String visitPrimitiveCheck(HPrimitiveCheck node) {
    String checkedInput = temporaryId(node.checkedInput);
    assert(node.inputs.length == 1);
    String kind = _primitiveCheckKind(node);
    return "PrimitiveCheck: $kind $checkedInput to ${node.instructionType}";
  }

  String _primitiveCheckKind(HPrimitiveCheck node) {
    if (node.isReceiverTypeCheck) return 'RECEIVER';
    if (node.isArgumentTypeCheck) return 'ARGUMENT';
    return '?';
  }

  @override
  String visitBoolConversion(HBoolConversion node) {
    String checkedInput = temporaryId(node.checkedInput);
    return "BoolConversion: $checkedInput";
  }

  @override
  String visitNullCheck(HNullCheck node) {
    String checkedInput = temporaryId(node.checkedInput);
    var comments = [
      if (node.selector != null) 'for ${node.selector}',
      if (node.field != null) 'for ${node.field}',
    ].join(', ');
    return "NullCheck: $checkedInput $comments";
  }

  @override
  String visitTypeKnown(HTypeKnown node) {
    assert(node.inputs.length <= 2);
    String result =
        "TypeKnown: ${temporaryId(node.checkedInput)} is ${node.knownType}";
    if (node.witness != null) {
      result += " witnessed by ${temporaryId(node.witness)}";
    }
    return result;
  }

  @override
  String visitRangeConversion(HRangeConversion node) {
    return "RangeConversion: ${node.checkedInput}";
  }

  @override
  String visitAwait(HAwait node) {
    return "Await: ${temporaryId(node.inputs[0])}";
  }

  @override
  String visitYield(HYield node) {
    return "Yield${node.hasStar ? "*" : ""}: ${temporaryId(node.inputs[0])}";
  }

  @override
  String visitIsTest(HIsTest node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "IsTest: $inputs";
  }

  @override
  String visitIsTestSimple(HIsTestSimple node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "IsTestSimple: ${node.dartType} $inputs";
  }

  @override
  String visitAsCheck(HAsCheck node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    String error = node.isTypeError ? 'TypeError' : 'CastError';
    return "AsCheck: $error $inputs";
  }

  @override
  String visitAsCheckSimple(HAsCheckSimple node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    String error = node.isTypeError ? 'TypeError' : 'CastError';
    return "AsCheckSimple: $error ${node.dartType} $inputs";
  }

  @override
  String visitSubtypeCheck(HSubtypeCheck node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "SubtypeCheck: $inputs";
  }

  @override
  String visitLoadType(HLoadType node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "LoadType: ${node.typeExpression}  $inputs";
  }

  @override
  String visitInstanceEnvironment(HInstanceEnvironment node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "InstanceEnvironment: $inputs";
  }

  @override
  String visitTypeEval(HTypeEval node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "TypeEval: ${node.typeExpression}  ${node.envStructure}  $inputs";
  }

  @override
  String visitTypeBind(HTypeBind node) {
    var inputs = node.inputs.map(temporaryId).join(', ');
    return "TypeBind: $inputs";
  }
}
