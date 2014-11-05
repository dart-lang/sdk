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

  // We want [HCheck] instructions to have the same name as the
  // instruction it checks, so both instructions should share the same
  // live ranges.
  LiveInterval.forCheck(this.start, LiveInterval checkedInterval)
      : ranges = checkedInterval.ranges;

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
    return '(${res.join(", ")})';
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
    LiveInterval interval = liveIntervals.putIfAbsent(
        instruction, () => new LiveInterval());
    int lastId = liveInstructions[instruction];
    // If [lastId] is null, then this instruction is not being used.
    interval.add(new LiveRange(id, lastId == null ? id : lastId));
    // The instruction is defined at [id].
    interval.start = id;
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

  bool get isEmpty => liveInstructions.isEmpty && loopMarkers.isEmpty;
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
  final Set<HInstruction> controlFlowOperators;

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

  SsaLiveIntervalBuilder(
      this.compiler, this.generateAtUseSite, this.controlFlowOperators)
    : liveInstructions = new Map<HBasicBlock, LiveEnvironment>(),
      liveIntervals = new Map<HInstruction, LiveInterval>();

  void visitGraph(HGraph graph) {
    visitPostDominatorTree(graph);
    if (!liveInstructions[graph.entry].isEmpty) {
      compiler.internalError(CURRENT_ELEMENT_SPANNABLE, 'LiveIntervalBuilder.');
    }
  }

  void markInputsAsLiveInEnvironment(HInstruction instruction,
                                     LiveEnvironment environment) {
    for (int i = 0, len = instruction.inputs.length; i < len; i++) {
      markAsLiveInEnvironment(instruction.inputs[i], environment);
    }
  }

  // Returns the non-HCheck instruction, or the last [HCheck] in the
  // check chain that is not generate at use site.
  //
  // For example:
  //
  //     t1 = GeneratedAtUseSite instruction
  //     t2 = check(t1)
  //     t3 = check(t2)
  //     t4 = use(t3)
  //     t5 = use(t3)
  //     t6 = use(t2)
  //
  // The t1 is generate-at-use site, and the live-range must thus be on t2 and
  // not on the checked instruction t1.
  // When looking for the checkedInstructionOrNonGenerateAtUseSite of t3 we must
  // return t2.
  HInstruction checkedInstructionOrNonGenerateAtUseSite(HCheck check) {
    var checked = check.checkedInput;
    while (checked is HCheck) {
      HInstruction next = checked.checkedInput;
      if (generateAtUseSite.contains(next)) break;
      checked = next;
    }
    return checked;
  }

  void markAsLiveInEnvironment(HInstruction instruction,
                               LiveEnvironment environment) {
    if (generateAtUseSite.contains(instruction)) {
      markInputsAsLiveInEnvironment(instruction, environment);
    } else {
      environment.add(instruction, instructionId);
      // Special case the HCheck instruction to mark the actual
      // checked instruction live. The checked instruction and the
      // [HCheck] will share the same live ranges.
      if (instruction is HCheck) {
        HCheck check = instruction;
        HInstruction checked = checkedInstructionOrNonGenerateAtUseSite(check);
        if (!generateAtUseSite.contains(checked)) {
          environment.add(checked, instructionId);
        }
      }
    }
  }

  void removeFromEnvironment(HInstruction instruction,
                             LiveEnvironment environment) {
    environment.remove(instruction, instructionId);
    // Special case the HCheck instruction to have the same live
    // interval as the instruction it is checking.
    if (instruction is HCheck) {
      HCheck check = instruction;
      HInstruction checked = checkedInstructionOrNonGenerateAtUseSite(check);
      if (!generateAtUseSite.contains(checked)) {
        liveIntervals.putIfAbsent(checked, () => new LiveInterval());
        // Unconditionally force the live ranges of the HCheck to
        // be the live ranges of the instruction it is checking.
        liveIntervals[instruction] =
            new LiveInterval.forCheck(instructionId, liveIntervals[checked]);
      }
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    LiveEnvironment environment =
        new LiveEnvironment(liveIntervals, instructionId);

    // If the control flow instruction in this block will actually be
    // inlined in the codegen in the join block, we need to make
    // whatever is used by that control flow instruction as live in
    // the join block.
    if (controlFlowOperators.contains(block.last)) {
      HIf ifInstruction = block.last;
      HBasicBlock joinBlock = ifInstruction.joinBlock;
      if (generateAtUseSite.contains(joinBlock.phis.first)) {
        markInputsAsLiveInEnvironment(
            ifInstruction, liveInstructions[joinBlock]);
      }
    }

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
      if (!generateAtUseSite.contains(instruction)) {
        removeFromEnvironment(instruction, environment);
        markInputsAsLiveInEnvironment(instruction, environment);
      }
      instructionId--;
      instruction = instruction.previous;
    }

    // We just remove the phis from the environment. The inputs of the
    // phis will be put in the environment of the predecessors.
    for (HPhi phi = block.phis.first; phi != null; phi = phi.next) {
      if (!generateAtUseSite.contains(phi)) {
        environment.remove(phi, instructionId);
      }
    }

    // Save the liveInstructions of that block.
    environment.startId = instructionId + 1;
    liveInstructions[block] = environment;

    // If the block is a loop header, we can remove the loop marker,
    // because it will just recompute the loop phis.
    // We also check if this loop header has any back edges. If not,
    // we know there is no loop marker for it.
    if (block.isLoopHeader() && block.predecessors.length > 1) {
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
  bool get isEmpty => copies.isEmpty && assignments.isEmpty;
}

/**
 * Contains the mapping between instructions and their names for code
 * generation, as well as the [CopyHandler] for each basic block.
 */
class VariableNames {
  final Map<HInstruction, String> ownName;
  final Map<HBasicBlock, CopyHandler> copyHandlers;

  // Used to control heuristic that determines how local variables are declared.
  final Set<String> allUsedNames;
  /**
   * Name that is used as a temporary to break cycles in
   * parallel copies. We make sure this name is not being used
   * anywhere by reserving it when we allocate names for instructions.
   */
  final String swapTemp;

  String getSwapTemp() {
    allUsedNames.add(swapTemp);
    return swapTemp;
  }

  VariableNames()
    : ownName = new Map<HInstruction, String>(),
      copyHandlers = new Map<HBasicBlock, CopyHandler>(),
      allUsedNames = new Set<String>(),
      swapTemp = 't0';

  int get numberOfVariables => allUsedNames.length;

  String getName(HInstruction instruction) {
    return ownName[instruction];
  }

  CopyHandler getCopyHandler(HBasicBlock block) {
    return copyHandlers[block];
  }

  void addNameUsed(String name) {
    allUsedNames.add(name);
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
  final Compiler compiler;
  final Set<String> usedNames;
  final List<String> freeTemporaryNames;
  int temporaryIndex = 0;
  static final RegExp regexp = new RegExp('t[0-9]+');

  VariableNamer(LiveEnvironment environment,
                this.names,
                this.compiler)
    : usedNames = new Set<String>(),
      freeTemporaryNames = new List<String>() {
    // [VariableNames.swapTemp] is used when there is a cycle in a copy handler.
    // Therefore we make sure no one uses it.
    usedNames.add(names.swapTemp);

    // All liveIns instructions must have a name at this point, so we
    // add them to the list of used names.
    environment.liveInstructions.forEach((HInstruction instruction, int index) {
      String name = names.getName(instruction);
      if (name != null) {
        usedNames.add(name);
        names.addNameUsed(name);
      }
    });
  }

  String allocateWithHint(String originalName) {
    int i = 0;
    JavaScriptBackend backend = compiler.backend;
    String name = backend.namer.safeVariableName(originalName);
    while (usedNames.contains(name)) {
      name = backend.namer.safeVariableName('$originalName${i++}');
    }
    return name;
  }

  String allocateTemporary() {
    while (!freeTemporaryNames.isEmpty) {
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
    }

    if (instruction.sourceElement != null) {
      name = allocateWithHint(instruction.sourceElement.name);
    } else {
      // We could not find an element for the instruction. If the
      // instruction is used by a phi, try to use the name of the phi.
      // Otherwise, just allocate a temporary name.
      HPhi phi = firstPhiUserWithElement(instruction);
      if (phi != null) {
        name = allocateWithHint(phi.sourceElement.name);
      } else {
        name = allocateTemporary();
      }
    }
    return addAllocatedName(instruction, name);
  }

  String addAllocatedName(HInstruction instruction, String name) {
    usedNames.add(name);
    names.addNameUsed(name);
    names.ownName[instruction] = name;
    return name;
  }

  /**
   * Frees [instruction]'s name so it can be used for other instructions.
   */
  void freeName(HInstruction instruction) {
    String ownName = names.ownName[instruction];
    if (ownName != null) {
      // We check if we have already looked for temporary names
      // because if we haven't, chances are the temporary we allocate
      // in this block can match a phi with the same name in the
      // successor block.
      if (temporaryIndex != 0 && regexp.hasMatch(ownName)) {
        freeTemporaryNames.add(ownName);
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

  final VariableNames names;

  SsaVariableAllocator(this.compiler,
                       this.liveInstructions,
                       this.liveIntervals,
                       this.generateAtUseSite)
    : this.names = new VariableNames();

  void visitGraph(HGraph graph) {
    visitDominatorTree(graph);
  }

  void visitBasicBlock(HBasicBlock block) {
    VariableNamer namer = new VariableNamer(
        liveInstructions[block], names, compiler);

    block.forEachPhi((HPhi phi) {
      handlePhi(phi, namer);
    });

    block.forEachInstruction((HInstruction instruction) {
      handleInstruction(instruction, namer);
    });
  }

  /**
   * Returns whether [instruction] needs a name. Instructions that
   * have no users or that are generated at use site do not need a name.
   */
  bool needsName(instruction) {
    if (instruction is HThis) return false;
    if (instruction is HParameterValue) return true;
    if (instruction.usedBy.isEmpty) return false;
    if (generateAtUseSite.contains(instruction)) return false;
    return !instruction.nonCheck().isCodeMotionInvariant();
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

  void freeUsedNamesAt(HInstruction instruction,
                       HInstruction at,
                       VariableNamer namer) {
    if (needsName(instruction)) {
      if (diesAt(instruction, at)) {
        namer.freeName(instruction);
      }
    } else if (generateAtUseSite.contains(instruction)) {
      // If the instruction is generated at use site, then all its
      // inputs may also die at [at].
      for (int i = 0, len = instruction.inputs.length; i < len; i++) {
        HInstruction input = instruction.inputs[i];
        freeUsedNamesAt(input, at, namer);
      }
    }
  }

  void handleInstruction(HInstruction instruction, VariableNamer namer) {
    if (generateAtUseSite.contains(instruction)) {
      assert(!liveIntervals.containsKey(instruction));
      return;
    }

    for (int i = 0, len = instruction.inputs.length; i < len; i++) {
      HInstruction input = instruction.inputs[i];
      freeUsedNamesAt(input, instruction, namer);
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
      // A [HTypeKnown] instruction never has a name, but its checked
      // input might, therefore we need to do a copy instead of an
      // assignment.
      while (input is HTypeKnown) input = input.inputs[0];
      if (!needsName(input)) {
        names.addAssignment(predecessor, input, phi);
      } else {
        names.addCopy(predecessor, input, phi);
      }
    }

    namer.allocateName(phi);
  }
}
