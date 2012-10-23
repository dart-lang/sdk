// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * The [LiveRange] class covers a range where an instruction is live.
 */
class LiveRange {
  final int start;
  // [end] is not final because it can be updated due to loops.
  int end;
  LiveRange(this.start, this.end) {
    assert(start <= end);
  }

  String toString() => '[$start $end[';
}

/**
 * The [LiveInterval] class contains the list of ranges where an
 * instruction is live.
 */
class LiveInterval {
  /**
   * The id where the instruction is defined.
   */
  int start;
  final List<LiveRange> ranges;
  LiveInterval() : ranges = <LiveRange>[];

  /**
   * Update all ranges that are contained in [from, to[ to
   * die at [to].
   */
  void loopUpdate(int from, int to) {
    for (LiveRange range in ranges) {
      if (from <= range.start && range.end < to) {
        range.end = to;
      }
    }
  }

  /**
   * Add a new range to this interval.
   */
  void add(LiveRange interval) {
    ranges.add(interval);
  }

  /**
   * Returns true if one of the ranges of this interval dies at [at].
   */
  bool diesAt(int at) {
    for (LiveRange range in ranges) {
      if (range.end == at) return true;
    }
    return false;
  }

  String toString() {
    List<String> res = new List<String>();
    for (final interval in ranges) res.add(interval.toString());
    return '(${Strings.join(res, ', ')})';
  }
}

/**
 * The [LiveEnvironment] class contains the liveIn set of a basic
 * block. A liveIn set of a block contains the instructions that are
 * live when entering that block.
 */
class LiveEnvironment {
  /**
   * The instruction id where the basic block starts. See
   * [SsaLiveIntervalBuilder.instructionId].
   */
  int startId;

  /**
   * The instruction id where the basic block ends.
   */
  final int endId;

  /**
   * Loop markers that will be updated once the loop header is
   * visited. The liveIn set of the loop header will be merged into this
   * environment. [loopMarkers] is a mapping from block header to the
   * end instruction id of the loop exit block.
   */
  final Map<HBasicBlock, int> loopMarkers;

  /**
   * The instructions that are live in this basic block. The values of
   * the map contain the instruction ids where the instructions die.
   * It will be used when adding a range to the live interval of an
   * instruction.
   */
  final Map<HInstruction, int> liveInstructions;

  /**
   * Map containing the live intervals of instructions.
   */
  final Map<HInstruction, LiveInterval> liveIntervals;

  LiveEnvironment(this.liveIntervals, this.endId)
    : liveInstructions = new Map<HInstruction, int>(),
      loopMarkers = new Map<HBasicBlock, int>();

  /**
   * Remove an instruction from the liveIn set. This method also
   * updates the live interval of [instruction] to contain the new
   * range: [id, / id contained in [liveInstructions] /].
   */
  void remove(HInstruction instruction, int id) {
    // Special case the HCheck instruction to have the same live
    // interval as the instruction it is checking.
    if (instruction is HCheck) {
      var input = instruction.checkedInput;
      while (input is HCheck) input = input.checkedInput;
      liveIntervals.putIfAbsent(input, () => new LiveInterval());
      // Unconditionally force the live interval of the HCheck to
      // be the live interval of the instruction it is checking.
      liveIntervals[instruction] = liveIntervals[input];
    } else {
      LiveInterval range = liveIntervals.putIfAbsent(
          instruction, () => new LiveInterval());
      int lastId = liveInstructions[instruction];
      // If [lastId] is null, then this instruction is not being used.
      range.add(new LiveRange(id, lastId == null ? id : lastId));
      // The instruction is defined at [id].
      range.start = id;
    }
    liveInstructions.remove(instruction);
  }

  /**
   * Add [instruction] to the liveIn set. If the instruction is not
   * already in the set, we save the id where it dies.
   */
  void add(HInstruction instruction, int userId) {
    // Note that we are visiting the graph in post-dominator order, so
    // the first time we see a variable is when it dies.
    liveInstructions.putIfAbsent(instruction, () => userId);
    if (instruction is HCheck) {
      // Special case the HCheck instruction to mark the actual
      // checked instruction live.
      var input = instruction.checkedInput;
      while (input is HCheck) input = input.checkedInput;
      liveInstructions.putIfAbsent(input, () => userId);
    }
  }

  /**
   * Merge this environment with [other]. Update the end id of
   * instructions in case they are different between this and [other].
   */
  void mergeWith(LiveEnvironment other) {
    other.liveInstructions.forEach((HInstruction instruction, int existingId) {
      // If both environments have the same instruction id of where
      // [instruction] dies, there is no need to update the live
      // interval of [instruction]. For example the if block and the
      // else block have the same end id for an instruction that is
      // being used in the join block and defined before the if/else.
      if (existingId == endId) return;
      LiveInterval range = liveIntervals.putIfAbsent(
          instruction, () => new LiveInterval());
      range.add(new LiveRange(other.startId, existingId));
      liveInstructions[instruction] = endId;
    });
    other.loopMarkers.forEach((k, v) { loopMarkers[k] = v; });
  }

  void addLoopMarker(HBasicBlock header, int id) {
    assert(!loopMarkers.containsKey(header));
    loopMarkers[header] = id;
  }

  void removeLoopMarker(HBasicBlock header) {
    assert(loopMarkers.containsKey(header));
    loopMarkers.remove(header);
  }

  bool isEmpty() => liveInstructions.isEmpty() && loopMarkers.isEmpty();
  bool contains(HInstruction instruction) =>
      liveInstructions.containsKey(instruction);
  String toString() => liveInstructions.toString();
}

/**
 * Builds the live intervals of each instruction. The algorithm visits
 * the graph post-dominator tree to find the last uses of an
 * instruction, and computes the liveIns of each basic block.
 */
class SsaLiveIntervalBuilder extends HBaseVisitor {
  final Compiler compiler;
  final Set<HInstruction> generateAtUseSite;

  /**
   * A counter to assign start and end ids to live ranges. The initial
   * value is not relevant. Note that instructionId goes downward to ease
   * reasoning about live ranges (the first instruction of a graph has
   * the lowest id).
   */
  int instructionId = 0;

  /**
   * The liveIns of basic blocks.
   */
  final Map<HBasicBlock, LiveEnvironment> liveInstructions;

  /**
   * The live intervals of instructions.
   */
  final Map<HInstruction, LiveInterval> liveIntervals;

  SsaLiveIntervalBuilder(this.compiler, this.generateAtUseSite)
    : liveInstructions = new Map<HBasicBlock, LiveEnvironment>(),
      liveIntervals = new Map<HInstruction, LiveInterval>();

  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
    if (!liveInstructions[graph.entry].isEmpty()) {
      compiler.internalError('LiveIntervalBuilder',
          node: compiler.currentElement.parseNode(compiler));
    }
  }

  void markInputsAsLiveInEnvironment(HInstruction instruction,
                                     LiveEnvironment environment) {
    for (int i = 0, len = instruction.inputs.length; i < len; i++) {
      markAsLiveInEnvironment(instruction.inputs[i], environment);
    }
  }

  void markAsLiveInEnvironment(HInstruction instruction,
                               LiveEnvironment environment) {
    if (environment.contains(instruction)) return;
    environment.add(instruction, instructionId);
    // HPhis are treated specially.
    if (generateAtUseSite.contains(instruction) && instruction is !HPhi) {
      markInputsAsLiveInEnvironment(instruction, environment);
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    LiveEnvironment environment =
        new LiveEnvironment(liveIntervals, instructionId);

    // Add to the environment the liveIn of its successor, as well as
    // the inputs of the phis of the successor that flow from this block.
    for (int i = 0; i < block.successors.length; i++) {
      HBasicBlock successor = block.successors[i];
      LiveEnvironment successorEnv = liveInstructions[successor];
      if (successorEnv != null) {
        environment.mergeWith(successorEnv);
      } else {
        environment.addLoopMarker(successor, instructionId);
      }

      int index = successor.predecessors.indexOf(block);
      for (HPhi phi = successor.phis.first; phi != null; phi = phi.next) {
        markAsLiveInEnvironment(phi.inputs[index], environment);
      }
    }

    // Iterate over all instructions to remove an instruction from the
    // environment and add its inputs.
    HInstruction instruction = block.last;
    while (instruction != null) {
      environment.remove(instruction, instructionId);
      markInputsAsLiveInEnvironment(instruction, environment);
      instruction = instruction.previous;
      instructionId--;
    }

    // We just remove the phis from the environment. The inputs of the
    // phis will be put in the environment of the predecessors.
    for (HPhi phi = block.phis.first; phi != null; phi = phi.next) {
      environment.remove(phi, instructionId);
    }

    // Save the liveInstructions of that block.
    environment.startId = instructionId + 1;
    liveInstructions[block] = environment;

    // If the block is a loop header, we can remove the loop marker,
    // because it will just recompute the loop phis.
    if (block.isLoopHeader()) {
      updateLoopMarker(block);
    }
  }

  void updateLoopMarker(HBasicBlock header) {
    LiveEnvironment env = liveInstructions[header];
    int lastId = env.loopMarkers[header];
    // Update all instructions that are liveIns in [header] to have a
    // range that covers the loop.
    env.liveInstructions.forEach((HInstruction instruction, int id) {
      LiveInterval range = env.liveIntervals.putIfAbsent(
          instruction, () => new LiveInterval());
      range.loopUpdate(env.startId, lastId);
      env.liveInstructions[instruction] = lastId;
    });

    env.removeLoopMarker(header);

    // Update all liveIns set to contain the liveIns of [header].
    liveInstructions.forEach((HBasicBlock block, LiveEnvironment other) {
      if (other.loopMarkers.containsKey(header)) {
        env.liveInstructions.forEach((HInstruction instruction, int id) {
          other.liveInstructions[instruction] = id;
        });
        other.removeLoopMarker(header);
        env.loopMarkers.forEach((k, v) { other.loopMarkers[k] = v; });
      }
    });
  }
}

/**
 * Represents a copy from one instruction to another. The codegen
 * also uses this class to represent a copy from one variable to
 * another.
 */
class Copy {
  final source;
  final destination;
  Copy(this.source, this.destination);
  String toString() => '$destination <- $source';
}

/**
 * A copy handler contains the copies that a basic block needs to do
 * after executing all its instructions.
 */
class CopyHandler {
  /**
   * The copies from an instruction to a phi of the successor.
   */
  final List<Copy> copies;

  /**
   * Assignments from an instruction that does not need a name (e.g. a
   * constant) to the phi of a successor.
   */
  final List<Copy> assignments;

  CopyHandler()
    : copies = new List<Copy>(),
      assignments = new List<Copy>();

  void addCopy(HInstruction source, HInstruction destination) {
    copies.add(new Copy(source, destination));
  }

  void addAssignment(HInstruction source, HInstruction destination) {
    assignments.add(new Copy(source, destination));
  }

  String toString() => 'Copies: $copies, assignments: $assignments';
  bool isEmpty() => copies.isEmpty() && assignments.isEmpty();
}

/**
 * Contains the mapping between instructions and their names for code
 * generation, as well as the [CopyHandler] for each basic block.
 */
class VariableNames {
  final Map<HInstruction, String> ownName;
  final Map<HBasicBlock, CopyHandler> copyHandlers;
  /**
   * Name that is used as a temporary to break cycles in
   * parallel copies. We make sure this name is not being used
   * anywhere by reserving it when we allocate names for instructions.
   */
  final String swapTemp;
  /**
   * Name that is used in bailout code. We make sure this name is not being used
   * anywhere by reserving it when we allocate names for instructions.
   */
  final String stateName;

  VariableNames(Map<Element, String> parameterNames)
    : ownName = new Map<HInstruction, String>(),
      copyHandlers = new Map<HBasicBlock, CopyHandler>(),
      swapTemp = computeFreshWithPrefix("t", parameterNames),
      stateName = computeFreshWithPrefix("state", parameterNames);

  /** Returns a fresh variable with the given prefix. */
  static String computeFreshWithPrefix(String prefix,
                                       Map<Element, String> parameterNames) {
    Set<String> parameters = new Set<String>.from(parameterNames.getValues());
    String name = '${prefix}0';
    int i = 1;
    while (parameters.contains(name)) name = '$prefix${i++}';
    return name;
  }

  String getName(HInstruction instruction) {
    return ownName[instruction];
  }

  CopyHandler getCopyHandler(HBasicBlock block) {
    return copyHandlers[block];
  }

  bool hasName(HInstruction instruction) => ownName.containsKey(instruction);

  void addCopy(HBasicBlock block, HInstruction source, HPhi destination) {
    CopyHandler handler =
        copyHandlers.putIfAbsent(block, () => new CopyHandler());
    handler.addCopy(source, destination);
  }

  void addAssignment(HBasicBlock block, HInstruction source, HPhi destination) {
    CopyHandler handler =
        copyHandlers.putIfAbsent(block, () => new CopyHandler());
    handler.addAssignment(source, destination);
  }
}

/**
 * Allocates variable names for instructions, making sure they don't collide.
 */
class VariableNamer {
  final VariableNames names;
  final Set<String> usedNames;
  final Map<Element, String> parameterNames;
  final List<String> freeTemporaryNames;
  int temporaryIndex = 0;

  VariableNamer(LiveEnvironment environment, this.names, this.parameterNames)
    : usedNames = new Set<String>(),
      freeTemporaryNames = new List<String>() {
    // [VariableNames.swapTemp] and [VariableNames.stateName] are being used
    // throughout the function. Therefore we make sure no one uses it at any
    // time.
    usedNames.add(names.swapTemp);
    usedNames.add(names.stateName);

    // All liveIns instructions must have a name at this point, so we
    // add them to the list of used names.
    environment.liveInstructions.forEach((HInstruction instruction, int index) {
      String name = names.getName(instruction);
      if (name != null) {
        usedNames.add(name);
      }
    });
  }

  String allocateWithHint(String originalName) {
    int i = 0;
    String name = JsNames.getValid(originalName);
    while (usedNames.contains(name)) {
      name = JsNames.getValid('$originalName${i++}');
    }
    return name;
  }

  String allocateTemporary() {
    while (!freeTemporaryNames.isEmpty()) {
      String name = freeTemporaryNames.removeLast();
      if (!usedNames.contains(name)) return name;
    }
    String name = 't${temporaryIndex++}';
    while (usedNames.contains(name)) name = 't${temporaryIndex++}';
    return name;
  }

  HPhi firstPhiUserWithElement(HInstruction instruction) {
    for (HInstruction user in instruction.usedBy) {
      if (user is HPhi && user.sourceElement != null) {
        return user;
      }
    }
    return null;
  }

  String allocateName(HInstruction instruction) {
    String name;
    if (instruction is HCheck) {
      // Special case this instruction to use the name of its
      // input if it has one.
      var temp = instruction;
      do {
        temp = temp.checkedInput;
        name = names.ownName[temp];
      } while (name == null && temp is HCheck);
      if (name != null) return addAllocatedName(instruction, name);
    } else if (instruction is HParameterValue) {
      HParameterValue parameter = instruction;
      name = parameterNames[parameter.sourceElement];
      if (name == null) {
        name = allocateWithHint(parameter.sourceElement.name.slowToString());
      }
      return addAllocatedName(instruction, name);
    }

    if (instruction.sourceElement != null) {
      name = allocateWithHint(instruction.sourceElement.name.slowToString());
    } else {
      // We could not find an element for the instruction. If the
      // instruction is used by a phi, try to use the name of the phi.
      // Otherwise, just allocate a temporary name.
      HPhi phi = firstPhiUserWithElement(instruction);
      if (phi != null) {
        name = allocateWithHint(phi.sourceElement.name.slowToString());
      } else {
        name = allocateTemporary();
      }
    }

    return addAllocatedName(instruction, name);
  }

  String addAllocatedName(HInstruction instruction, String name) {
    usedNames.add(name);
    names.ownName[instruction] = name;
    return name;
  }

  /**
   * Frees [instruction]'s name so it can be used for other instructions.
   */
  void freeName(HInstruction instruction) {
    String ownName = names.ownName[instruction];
    if (ownName != null) {
      RegExp regexp = const RegExp('t[0-9]+');
      // We check if we have already looked for temporary names
      // because if we haven't, chances are the temporary we allocate
      // in this block can match a phi with the same name in the
      // successor block.
      if (temporaryIndex != 0 && regexp.hasMatch(ownName)) {
        freeTemporaryNames.addLast(ownName);
      }
      usedNames.remove(ownName);
    }
  }
}

/**
 * Visits all blocks in the graph, sets names to instructions, and
 * creates the [CopyHandler] for each block. This class needs to have
 * the liveIns set as well as all the live intervals of instructions.
 * It visits the graph in dominator order, so that at each entry of a
 * block, the instructions in its liveIns set have names.
 *
 * When visiting a block, it goes through all instructions. For each
 * instruction, it frees the names of the inputs that die at that
 * instruction, and allocates a name to the instruction. For each phi,
 * it adds a copy to the CopyHandler of the corresponding predecessor.
 */
class SsaVariableAllocator extends HBaseVisitor {

  final Compiler compiler;
  final Map<HBasicBlock, LiveEnvironment> liveInstructions;
  final Map<HInstruction, LiveInterval> liveIntervals;
  final Set<HInstruction> generateAtUseSite;
  final Map<Element, String> parameterNames;

  final VariableNames names;

  SsaVariableAllocator(this.compiler,
                       this.liveInstructions,
                       this.liveIntervals,
                       this.generateAtUseSite,
                       parameterNames)
    : this.names = new VariableNames(parameterNames),
      this.parameterNames = parameterNames;

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    VariableNamer namer = new VariableNamer(
        liveInstructions[block], names, parameterNames);

    block.forEachPhi((HPhi phi) {
      handlePhi(phi, namer);
    });

    block.forEachInstruction((HInstruction instruction) {
      handleInstruction(instruction, namer);
    });
  }

  /**
   * Returns whether [instruction] needs a name. Instructions that
   * have no users or that are generated at use site does not need a name.
   */
  bool needsName(HInstruction instruction) {
    if (instruction.usedBy.isEmpty()) return false;
    // TODO(ngeoffray): locals/parameters are being generated at use site,
    // but we need a name for them. We should probably not make
    // them generate at use site to make things simpler.
    if (instruction is HLocalValue && instruction is !HThis) return true;
    if (generateAtUseSite.contains(instruction)) return false;
    // A [HCheck] instruction that has control flow needs a name only if its
    // checked input needs a name (e.g. a check [HConstant] does not
    // need a name).
    if (instruction is HCheck && instruction.isControlFlow()) {
      HCheck check = instruction;
      return needsName(instruction.checkedInput);
    }
    return true;
  }

  /**
   * Returns whether [instruction] dies at the instruction [at].
   */
  bool diesAt(HInstruction instruction, HInstruction at) {
    LiveInterval atInterval = liveIntervals[at];
    LiveInterval instructionInterval = liveIntervals[instruction];
    int start = atInterval.start;
    return instructionInterval.diesAt(start);
  }

  void handleInstruction(HInstruction instruction, VariableNamer namer) {
    // TODO(ager): We cannot perform this check to free names for
    // HCheck instructions because they are special cased to have the
    // same live intervals as the instruction they are checking. This
    // includes sharing the start id with the checked
    // input. Therefore, for HCheck(checkedInput, otherInput) we would
    // end up checking that otherInput dies not here, but at the
    // location of checkedInput. We should preserve the start id for
    // the check instruction.
    if (instruction is! HCheck) {
      for (int i = 0, len = instruction.inputs.length; i < len; i++) {
        HInstruction input = instruction.inputs[i];
        // If [input] has a name, and its use here is the last use, free
        // its name.
        if (needsName(input) && diesAt(input, instruction)) {
          namer.freeName(input);
        }
      }
    }

    if (needsName(instruction)) {
      namer.allocateName(instruction);
    }
  }

  void handlePhi(HPhi phi, VariableNamer namer) {
    if (!needsName(phi)) return;

    for (int i = 0; i < phi.inputs.length; i++) {
      HInstruction input = phi.inputs[i];
      HBasicBlock predecessor = phi.block.predecessors[i];
      if (!needsName(input)) {
        names.addAssignment(predecessor, input, phi);
      } else {
        names.addCopy(predecessor, input, phi);
      }
    }

    namer.allocateName(phi);
  }
}
