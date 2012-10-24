// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tracer;

import 'dart:io';
import 'ssa.dart';
import '../js_backend/js_backend.dart';
import '../dart2jslib.dart';

const bool GENERATE_SSA_TRACE = false;
const String SSA_TRACE_FILTER = null;

class HTracer extends HGraphVisitor implements Tracer {
  JavaScriptItemCompilationContext context;
  int indent = 0;
  final RandomAccessFile output;
  final bool enabled = GENERATE_SSA_TRACE;
  bool traceActive = false;

  HTracer([String path = "dart.cfg"])
      : output = GENERATE_SSA_TRACE ? new File(path).openSync(FileMode.WRITE)
                                    : null;

  void close() {
    if (enabled) output.closeSync();
  }

  void traceCompilation(String methodName,
                        JavaScriptItemCompilationContext compilationContext) {
    if (!enabled) return;
    this.context = compilationContext;
    traceActive =
        SSA_TRACE_FILTER == null || methodName.contains(SSA_TRACE_FILTER);
    if (!traceActive) return;
    tag("compilation", () {
      printProperty("name", methodName);
      printProperty("method", methodName);
      printProperty("date", new Date.now().millisecondsSinceEpoch);
    });
  }

  void traceGraph(String name, HGraph graph) {
    if (!traceActive) return;
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

  void addInstructions(HInstructionStringifier stringifier,
                       HInstructionList list) {
    HTypeMap types = context.types;
    for (HInstruction instruction = list.first;
         instruction != null;
         instruction = instruction.next) {
      int bci = 0;
      int uses = instruction.usedBy.length;
      String changes = instruction.hasSideEffects(types) ? '!' : ' ';
      String depends = instruction.dependsOnSomething() ? '?' : '';
      addIndent();
      String temporaryId = stringifier.temporaryId(instruction);
      String instructionString = stringifier.visit(instruction);
      add("$bci $uses $temporaryId $instructionString $changes $depends <|@\n");
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstructionStringifier stringifier =
        new HInstructionStringifier(context, block);
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
              inputIds.add(stringifier.temporaryId(phi.inputs[i]));
              inputIds.add(" ");
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

  void tag(String tagName, Function f) {
    println("begin_$tagName");
    indent++;
    f();
    indent--;
    println("end_$tagName");
  }

  void println(String string) {
    addIndent();
    add(string);
    add("\n");
  }

  void printEmptyProperty(String propertyName) {
    println(propertyName);
  }

  void printProperty(String propertyName, var value) {
    if (value is num) {
      println("$propertyName $value");
    } else {
      println('$propertyName "$value"');
    }
  }

  void add(String string) {
    output.writeStringSync(string);
  }

  void addIndent() {
    for (int i = 0; i < indent; i++) {
      add("  ");
    }
  }
}

class HInstructionStringifier implements HVisitor<String> {
  JavaScriptItemCompilationContext context;
  HBasicBlock currentBlock;

  HInstructionStringifier(this.context, this.currentBlock);

  visit(HInstruction node) => node.accept(this);

  String temporaryId(HInstruction instruction) {
    String prefix;
    HType type = context.types[instruction];
    if (!type.isPrimitive()) {
      prefix = 'U';
    } else {
      if (type == HType.MUTABLE_ARRAY) {
        prefix = 'm';
      } else if (type == HType.READABLE_ARRAY) {
        prefix = 'a';
      } else if (type == HType.EXTENDABLE_ARRAY) {
        prefix = 'e';
      } else if (type == HType.BOOLEAN) {
        prefix = 'b';
      } else if (type == HType.INTEGER) {
        prefix = 'i';
      } else if (type == HType.DOUBLE) {
        prefix = 'd';
      } else if (type == HType.NUMBER) {
        prefix = 'n';
      } else if (type == HType.STRING) {
        prefix = 's';
      } else if (type == HType.UNKNOWN) {
        prefix = 'v';
      } else if (type == HType.CONFLICTING) {
        prefix = 'c';
      } else if (type == HType.INDEXABLE_PRIMITIVE) {
        prefix = 'r';
      } else if (type == HType.NULL) {
        prefix = 'u';
      } else {
        prefix = 'x';
      }
    }
    return "$prefix${instruction.id}";
  }

  String visitBailoutTarget(HBailoutTarget node) {
    StringBuffer envBuffer = new StringBuffer();
    List<HInstruction> inputs = node.inputs;
    for (int i = 0; i < inputs.length; i++) {
      envBuffer.add(" ${temporaryId(inputs[i])}");
    }
    String on = node.isEnabled ? "enabled" : "disabled";
    return "BailoutTarget($on): id: ${node.state} env: $envBuffer";
  }

  String visitBoolify(HBoolify node) {
    return "Boolify: ${temporaryId(node.inputs[0])}";
  }

  String visitAdd(HAdd node) => visitInvokeStatic(node);

  String visitBitAnd(HBitAnd node) => visitInvokeStatic(node);

  String visitBitNot(HBitNot node) => visitInvokeStatic(node);

  String visitBitOr(HBitOr node) => visitInvokeStatic(node);

  String visitBitXor(HBitXor node) => visitInvokeStatic(node);

  String visitBoundsCheck(HBoundsCheck node) {
    String lengthId = temporaryId(node.length);
    String indexId = temporaryId(node.index);
    return "Bounds check: length = $lengthId, index = $indexId";
  }

  String visitBreak(HBreak node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label != null) {
      return "Break ${node.label.labelName}: (B${target.id})";
    }
    return "Break: (B${target.id})";
  }

  String visitConstant(HConstant constant) => "Constant ${constant.constant}";

  String visitContinue(HContinue node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label != null) {
      return "Continue ${node.label.labelName}: (B${target.id})";
    }
    return "Continue: (B${target.id})";
  }

  String visitDivide(HDivide node) => visitInvokeStatic(node);

  String visitEquals(HEquals node) => visitInvokeStatic(node);

  String visitExit(HExit node) => "exit";

  String visitFieldGet(HFieldGet node) {
    String fieldName = node.element.name.slowToString();
    return 'get ${temporaryId(node.receiver)}.$fieldName';
  }

  String visitFieldSet(HFieldSet node) {
    String valueId = temporaryId(node.value);
    String fieldName = node.element.name.slowToString();
    return 'set ${temporaryId(node.receiver)}.$fieldName to $valueId';
  }

  String visitLocalGet(HLocalGet node) => visitFieldGet(node);
  String visitLocalSet(HLocalSet node) => visitFieldSet(node);

  String visitGoto(HGoto node) {
    HBasicBlock target = currentBlock.successors[0];
    return "Goto: (B${target.id})";
  }

  String visitGreater(HGreater node) => visitInvokeStatic(node);
  String visitGreaterEqual(HGreaterEqual node) => visitInvokeStatic(node);

  String visitIdentity(HIdentity node) => visitInvokeStatic(node);

  String visitIf(HIf node) {
    HBasicBlock thenBlock = currentBlock.successors[0];
    HBasicBlock elseBlock = currentBlock.successors[1];
    String conditionId = temporaryId(node.inputs[0]);
    return "If ($conditionId): (B${thenBlock.id}) else (B${elseBlock.id})";
  }

  String visitGenericInvoke(String invokeType, String functionName,
                            List<HInstruction> arguments) {
    StringBuffer argumentsString = new StringBuffer();
    for (int i = 0; i < arguments.length; i++) {
      if (i != 0) argumentsString.add(", ");
      argumentsString.add(temporaryId(arguments[i]));
    }
    return "$invokeType: $functionName($argumentsString)";
  }

  String visitIndex(HIndex node) => visitInvokeStatic(node);
  String visitIndexAssign(HIndexAssign node) => visitInvokeStatic(node);

  String visitIntegerCheck(HIntegerCheck node) {
    String value = temporaryId(node.value);
    return "Integer check: $value";
  }

  String visitInvokeClosure(HInvokeClosure node)
      => visitInvokeDynamic(node, "closure");

  String visitInvokeDynamic(HInvokeDynamic invoke, String kind) {
    String receiver = temporaryId(invoke.receiver);
    String name = invoke.selector.name.slowToString();
    String target = "($kind) $receiver.$name";
    int offset = HInvoke.ARGUMENTS_OFFSET;
    List arguments =
        invoke.inputs.getRange(offset, invoke.inputs.length - offset);
    return visitGenericInvoke("Invoke", target, arguments);
  }

  String visitInvokeDynamicMethod(HInvokeDynamicMethod node)
      => visitInvokeDynamic(node, "method");
  String visitInvokeDynamicGetter(HInvokeDynamicGetter node)
      => visitInvokeDynamic(node, "get");
  String visitInvokeDynamicSetter(HInvokeDynamicSetter node)
      => visitInvokeDynamic(node, "set");

  String visitInvokeInterceptor(HInvokeInterceptor invoke)
      => visitInvokeStatic(invoke);

  String visitInvokeStatic(HInvokeStatic invoke) {
    String target = temporaryId(invoke.target);
    int offset = HInvoke.ARGUMENTS_OFFSET;
    List arguments =
        invoke.inputs.getRange(offset, invoke.inputs.length - offset);
    return visitGenericInvoke("Invoke", target, arguments);
  }

  String visitInvokeSuper(HInvokeSuper invoke) {
    String target = temporaryId(invoke.target);
    int offset = HInvoke.ARGUMENTS_OFFSET + 1;
    List arguments =
        invoke.inputs.getRange(offset, invoke.inputs.length - offset);
    return visitGenericInvoke("Invoke super", target, arguments);
  }

  String visitForeign(HForeign foreign) {
    return visitGenericInvoke("Foreign", "${foreign.code}", foreign.inputs);
  }

  String visitForeignNew(HForeignNew node) {
    return visitGenericInvoke("New",
                              "${node.element.name.slowToString()}",
                              node.inputs);
  }

  String visitLess(HLess node) => visitInvokeStatic(node);
  String visitLessEqual(HLessEqual node) => visitInvokeStatic(node);

  String visitLiteralList(HLiteralList node) {
    StringBuffer elementsString = new StringBuffer();
    for (int i = 0; i < node.inputs.length; i++) {
      if (i != 0) elementsString.add(", ");
      elementsString.add(temporaryId(node.inputs[i]));
    }
    return "Literal list: [$elementsString]";
  }

  String visitLoopBranch(HLoopBranch branch) {
    HBasicBlock bodyBlock = currentBlock.successors[0];
    HBasicBlock exitBlock = currentBlock.successors[1];
    String conditionId = temporaryId(branch.inputs[0]);
    return "While ($conditionId): (B${bodyBlock.id}) then (B${exitBlock.id})";
  }

  String visitModulo(HModulo node) => visitInvokeStatic(node);

  String visitMultiply(HMultiply node) => visitInvokeStatic(node);

  String visitNegate(HNegate node) => visitInvokeStatic(node);

  String visitNot(HNot node) => "Not: ${temporaryId(node.inputs[0])}";

  String visitParameterValue(HParameterValue node) {
    return "p${node.sourceElement.name.slowToString()}";
  }

  String visitLocalValue(HLocalValue node) {
    return "l${node.sourceElement.name.slowToString()}";
  }

  String visitPhi(HPhi phi) {
    StringBuffer buffer = new StringBuffer();
    buffer.add("Phi(");
    for (int i = 0; i < phi.inputs.length; i++) {
      if (i > 0) buffer.add(", ");
      buffer.add(temporaryId(phi.inputs[i]));
    }
    buffer.add(")");
    return buffer.toString();
  }

  String visitReturn(HReturn node) => "Return ${temporaryId(node.inputs[0])}";

  String visitShiftLeft(HShiftLeft node) => visitInvokeStatic(node);

  String visitShiftRight(HShiftRight node) => visitInvokeStatic(node);

  String visitStatic(HStatic node)
      => "Static ${node.element.name.slowToString()}";

  String visitLazyStatic(HLazyStatic node)
      => "LazyStatic ${node.element.name.slowToString()}";

  String visitStaticStore(HStaticStore node) {
    String lhs = node.element.name.slowToString();
    return "Static $lhs = ${temporaryId(node.inputs[0])}";
  }

  String visitStringConcat(HStringConcat node) {
    var leftId = temporaryId(node.left);
    var rightId = temporaryId(node.right);
    return "StringConcat: $leftId + $rightId";
  }

  String visitSubtract(HSubtract node) => visitInvokeStatic(node);

  String visitSwitch(HSwitch node) {
    StringBuffer buf = new StringBuffer();
    buf.add("Switch: (");
    buf.add(temporaryId(node.inputs[0]));
    buf.add(") ");
    for (int i = 1; i < node.inputs.length; i++) {
      buf.add(temporaryId(node.inputs[i]));
      buf.add(": B");
      buf.add(node.block.successors[i - 1].id);
      buf.add(", ");
    }
    buf.add("default: B");
    buf.add(node.block.successors.last().id);
    return buf.toString();
  }

  String visitThis(HThis node) => "this";

  String visitThrow(HThrow node) => "Throw ${temporaryId(node.inputs[0])}";

  String visitTruncatingDivide(HTruncatingDivide node) {
    return visitInvokeStatic(node);
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
        "Join: B${successors.last().id}";
  }

  String visitTypeGuard(HTypeGuard node) {
    String type;
    HType guardedType = node.guardedType;
    if (guardedType == HType.MUTABLE_ARRAY) {
      type = "mutable_array";
    } else if (guardedType == HType.READABLE_ARRAY) {
      type = "readable_array";
    } else if (guardedType == HType.EXTENDABLE_ARRAY) {
      type = "extendable_array";
    } else if (guardedType == HType.BOOLEAN) {
      type = "bool";
    } else if (guardedType == HType.INTEGER) {
      type = "integer";
    } else if (guardedType == HType.DOUBLE) {
      type = "double";
    } else if (guardedType == HType.NUMBER) {
      type = "number";
    } else if (guardedType == HType.STRING) {
      type = "string";
    } else if (guardedType == HType.INDEXABLE_PRIMITIVE) {
      type = "string_or_array";
    } else if (guardedType == HType.UNKNOWN) {
      type = 'unknown';
    } else {
      throw new CompilerCancelledException('Unexpected type guard: $type');
    }
    HInstruction guarded = node.guarded;
    HInstruction bailoutTarget = node.bailoutTarget;
    StringBuffer envBuffer = new StringBuffer();
    List<HInstruction> inputs = node.inputs;
    assert(inputs.length >= 2);
    assert(inputs[0] == guarded);
    assert(inputs[1] == bailoutTarget);
    for (int i = 2; i < inputs.length; i++) {
      envBuffer.add(" ${temporaryId(inputs[i])}");
    }
    String on = node.isEnabled ? "enabled" : "disabled";
    String guardedId = temporaryId(node.guarded);
    String bailoutId = temporaryId(node.bailoutTarget);
    return "TypeGuard($on): $guardedId is $type bailout: $bailoutId "
           "env: $envBuffer";
  }

  String visitIs(HIs node) {
    String type = node.typeExpression.toString();
    return "TypeTest: ${temporaryId(node.expression)} is $type";
  }

  String visitTypeConversion(HTypeConversion node) {
    return "TypeConversion: ${temporaryId(node.checkedInput)} to ${node.type}";
  }

  String visitRangeConversion(HRangeConversion node) {
    return "RangeConversion: ${node.checkedInput}";
  }
}
