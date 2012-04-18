// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('tracer');

#import('dart:io');
#import('ssa.dart');
#import('../leg.dart');

final bool GENERATE_SSA_TRACE = false;

class HTracer extends HGraphVisitor implements Tracer {
  int indent = 0;
  final RandomAccessFile output;
  final bool enabled = GENERATE_SSA_TRACE;

  HTracer([String path = "dart.cfg"])
      : output = GENERATE_SSA_TRACE ? new File(path).openSync(FileMode.WRITE)
                                    : null;

  void close() {
    if (enabled) output.closeSync();
  }

  void traceCompilation(String methodName) {
    tag("compilation", () {
      printProperty("name", methodName);
      printProperty("method", methodName);
      printProperty("date", new Date.now().value);
    });
  }

  void traceGraph(String name, HGraph graph) {
    if (!enabled) return;
    tag("cfg", () {
      printProperty("name", name);
      visitDominatorTree(graph);
    });
  }

  void addPredecessors(HBasicBlock block) {
    if (block.predecessors.isEmpty()) {
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
    if (block.successors.isEmpty()) {
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
    for (HInstruction instruction = list.first;
         instruction !== null;
         instruction = instruction.next) {
      int bci = 0;
      int uses = instruction.usedBy.length;
      addIndent();
      String temporaryId = stringifier.temporaryId(instruction);
      String instructionString = stringifier.visit(instruction);
      add("$bci $uses $temporaryId $instructionString <|@\n");
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstructionStringifier stringifier = new HInstructionStringifier(block);
    assert(block.id !== null);
    tag("block", () {
      printProperty("name", "B${block.id}");
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      addPredecessors(block);
      addSuccessors(block);
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      if (block.dominator !== null) {
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
  HBasicBlock currentBlock;

  HInstructionStringifier(this.currentBlock);

  visit(HInstruction node) => node.accept(this);

  visitBasicBlock(HBasicBlock node) {
    unreachable();
  }

  String temporaryId(HInstruction instruction) {
    String prefix;
    HType type = instruction.propagatedType;
    switch (type) {
      case HType.MUTABLE_ARRAY: prefix = 'm'; break;
      case HType.READABLE_ARRAY: prefix = 'a'; break;
      case HType.BOOLEAN: prefix = 'b'; break;
      case HType.INTEGER: prefix = 'i'; break;
      case HType.DOUBLE: prefix = 'd'; break;
      case HType.NUMBER: prefix = 'n'; break;
      case HType.STRING: prefix = 's'; break;
      case HType.UNKNOWN: prefix = 'v'; break;
      case HType.CONFLICTING: prefix = 'c'; break;
      case HType.STRING_OR_ARRAY: prefix = 'r'; break;
      default: unreachable();
    }
    return "$prefix${instruction.id}";
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
    if (node.label !== null) {
      return "Break ${node.label.labelName}: (B${target.id})";
    }
    return "Break: (B${target.id})";
  }

  String visitConstant(HConstant constant) => "Constant ${constant.constant}";

  String visitContinue(HContinue node) {
    HBasicBlock target = currentBlock.successors[0];
    if (node.label !== null) {
      return "Continue ${node.label.labelName}: (B${target.id})";
    }
    return "Continue: (B${target.id})";
  }

  String visitDivide(HDivide node) => visitInvokeStatic(node);

  String visitEquals(HEquals node) => visitInvokeStatic(node);

  String visitExit(HExit node) => "exit";

  String visitFieldGet(HFieldGet node) {
    return 'get ${node.element.name.slowToString()}';
  }

  String visitFieldSet(HFieldSet node) {
    String valueId = temporaryId(node.value);
    return 'set ${node.element.name.slowToString()} to $valueId';
  }

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
    String target = "($kind) $receiver.${invoke.name.slowToString()}";
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
    return "p${node.element.name.slowToString()}";
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
  String visitStaticStore(HStaticStore node) {
    String lhs = node.element.name.slowToString();
    return "Static $lhs = ${temporaryId(node.inputs[0])}";
  }

  String visitSubtract(HSubtract node) => visitInvokeStatic(node);

  String visitThis(HThis node) => "this";

  String visitThrow(HThrow node) => "Throw ${temporaryId(node.inputs[0])}";

  String visitTruncatingDivide(HTruncatingDivide node) {
    return visitInvokeStatic(node);
  }

  String visitTry(HTry node) {
    List<HBasicBlock> successors = currentBlock.successors;
    String tryBlock = 'B${successors[0].id}';
    StringBuffer catchBlocks = new StringBuffer();
    for (int i = 1; i < successors.length - 1; i++) {
      catchBlocks.add('B${successors[i].id}, ');
    }

    String finallyBlock;
    if (node.finallyBlock != null) {
      finallyBlock = 'B${node.finallyBlock.id}';
    } else {
      catchBlocks.add('B${successors[successors.length - 1].id}');
      finallyBlock = 'none';
    }
    return "Try: $tryBlock, Catch: $catchBlocks, Finally: $finallyBlock";
  }

  String visitTypeGuard(HTypeGuard node) {
    String type;
    switch (node.guardedType) {
      case HType.MUTABLE_ARRAY: type = "mutable_array"; break;
      case HType.READABLE_ARRAY: type = "readable_array"; break;
      case HType.BOOLEAN: type = "bool"; break;
      case HType.INTEGER: type = "integer"; break;
      case HType.DOUBLE: type = "double"; break;
      case HType.NUMBER: type = "number"; break;
      case HType.STRING: type = "string"; break;
      case HType.STRING_OR_ARRAY: type = "string_or_array"; break;
      case HType.UNKNOWN: type = 'unknown'; break;
      default: unreachable();
    }
    String onString = node.isOn ? "on" : "off";
    return "TypeGuard: ${temporaryId(node.inputs[0])} is $type ($onString)";
  }

  String visitIs(HIs node) {
    String type = node.typeName.toString();
    return "TypeTest: ${temporaryId(node.expression)} is $type";
  }
}
