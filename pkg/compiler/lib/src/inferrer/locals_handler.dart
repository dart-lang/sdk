// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library locals_handler;

import 'dart:collection' show IterableMixin;

import '../options.dart' show CompilerOptions;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../tree/tree.dart';
import '../util/util.dart';
import 'inferrer_engine.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

/**
 * A variable scope holds types for variables. It has a link to a
 * parent scope, but never changes the types in that parent. Instead,
 * updates to locals of a parent scope are put in the current scope.
 * The inferrer makes sure updates get merged into the parent scope,
 * once the control flow block has been visited.
 */
class VariableScope {
  Map<Local, TypeInformation> variables;

  /// The parent of this scope. Null for the root scope.
  final VariableScope parent;

  /// The [Node] that created this scope.
  final Node block;

  VariableScope(this.block, [parent])
      : this.variables = null,
        this.parent = parent;

  VariableScope.deepCopyOf(VariableScope other)
      : variables = other.variables == null
            ? null
            : new Map<Local, TypeInformation>.from(other.variables),
        block = other.block,
        parent = other.parent == null
            ? null
            : new VariableScope.deepCopyOf(other.parent);

  VariableScope.topLevelCopyOf(VariableScope other)
      : variables = other.variables == null
            ? null
            : new Map<Local, TypeInformation>.from(other.variables),
        block = other.block,
        parent = other.parent;

  TypeInformation operator [](Local variable) {
    TypeInformation result;
    if (variables == null || (result = variables[variable]) == null) {
      return parent == null ? null : parent[variable];
    }
    return result;
  }

  void operator []=(Local variable, TypeInformation mask) {
    assert(mask != null);
    if (variables == null) {
      variables = new Map<Local, TypeInformation>();
    }
    variables[variable] = mask;
  }

  void forEachOwnLocal(void f(Local variable, TypeInformation type)) {
    if (variables == null) return;
    variables.forEach(f);
  }

  void forEachLocalUntilNode(
      Node node, void f(Local variable, TypeInformation type),
      [Setlet<Local> seenLocals]) {
    if (seenLocals == null) seenLocals = new Setlet<Local>();
    if (variables != null) {
      variables.forEach((variable, type) {
        if (seenLocals.contains(variable)) return;
        seenLocals.add(variable);
        f(variable, type);
      });
    }
    if (block == node) return;
    if (parent != null) parent.forEachLocalUntilNode(node, f, seenLocals);
  }

  void forEachLocal(void f(Local variable, TypeInformation type)) {
    forEachLocalUntilNode(null, f);
  }

  bool updates(Local variable) {
    if (variables == null) return false;
    return variables.containsKey(variable);
  }

  String toString() {
    String rest = parent == null ? "null" : parent.toString();
    return '$variables $rest';
  }
}

/// Tracks initializers via initializations and assignments.
class FieldInitializationScope {
  final TypeSystem types;
  Map<Element, TypeInformation> fields;
  bool isThisExposed;

  /// `true` when control flow prevents accumulating definite assignments,
  /// e.g. an early return or caught exception.
  bool isIndefinite;

  FieldInitializationScope(this.types)
      : isThisExposed = false,
        isIndefinite = false;

  FieldInitializationScope.internalFrom(FieldInitializationScope other)
      : types = other.types,
        isThisExposed = other.isThisExposed,
        isIndefinite = other.isIndefinite;

  factory FieldInitializationScope.from(FieldInitializationScope other) {
    if (other == null) return null;
    return new FieldInitializationScope.internalFrom(other);
  }

  void updateField(Element field, TypeInformation type) {
    if (isThisExposed) return;
    if (isIndefinite) return;
    fields ??= new Map<Element, TypeInformation>();
    fields[field] = type;
  }

  TypeInformation readField(Element field) {
    return fields == null ? null : fields[field];
  }

  void forEach(void f(Element element, TypeInformation type)) {
    fields?.forEach(f);
  }

  void mergeDiamondFlow(
      FieldInitializationScope thenScope, FieldInitializationScope elseScope) {
    // Quick bailout check. If [isThisExposed] or [isIndefinite] is true, we
    // know the code following won'TypeInformation do anything.
    if (isThisExposed) return;
    if (isIndefinite) return;

    FieldInitializationScope otherScope =
        (elseScope == null || elseScope.fields == null) ? this : elseScope;

    thenScope.forEach((Element field, TypeInformation type) {
      TypeInformation otherType = otherScope.readField(field);
      if (otherType == null) return;
      updateField(field, types.allocateDiamondPhi(type, otherType));
    });

    isThisExposed = thenScope.isThisExposed || elseScope.isThisExposed;
    isIndefinite = thenScope.isIndefinite || elseScope.isIndefinite;
  }
}

/**
 * Placeholder for inferred arguments types on sends.
 */
class ArgumentsTypes extends IterableMixin<TypeInformation> {
  final List<TypeInformation> positional;
  final Map<String, TypeInformation> named;
  ArgumentsTypes(this.positional, named)
      : this.named = (named == null || named.isEmpty) ? const {} : named {
    assert(this.positional.every((TypeInformation type) => type != null));
    assert(this.named.values.every((TypeInformation type) => type != null));
  }

  ArgumentsTypes.empty()
      : positional = const [],
        named = const {};

  int get length => positional.length + named.length;

  Iterator<TypeInformation> get iterator => new ArgumentsTypesIterator(this);

  String toString() => "{ positional = $positional, named = $named }";

  bool operator ==(other) {
    if (positional.length != other.positional.length) return false;
    if (named.length != other.named.length) return false;
    for (int i = 0; i < positional.length; i++) {
      if (positional[i] != other.positional[i]) return false;
    }
    named.forEach((name, type) {
      if (other.named[name] != type) return false;
    });
    return true;
  }

  int get hashCode => throw new UnsupportedError('ArgumentsTypes.hashCode');

  bool hasNoArguments() => positional.isEmpty && named.isEmpty;

  void forEach(void f(TypeInformation type)) {
    positional.forEach(f);
    named.values.forEach(f);
  }

  bool every(bool f(TypeInformation type)) {
    return positional.every(f) && named.values.every(f);
  }

  bool contains(TypeInformation type) {
    return positional.contains(type) || named.containsValue(type);
  }
}

class ArgumentsTypesIterator implements Iterator<TypeInformation> {
  final Iterator<TypeInformation> positional;
  final Iterator<TypeInformation> named;
  bool _iteratePositional = true;

  ArgumentsTypesIterator(ArgumentsTypes iteratee)
      : positional = iteratee.positional.iterator,
        named = iteratee.named.values.iterator;

  Iterator<TypeInformation> get _currentIterator =>
      _iteratePositional ? positional : named;

  TypeInformation get current => _currentIterator.current;

  bool moveNext() {
    if (_iteratePositional && positional.moveNext()) {
      return true;
    }
    _iteratePositional = false;
    return named.moveNext();
  }
}

/**
 * Placeholder for inferred types of local variables.
 */
class LocalsHandler {
  final CompilerOptions options;
  final TypeSystem types;
  final InferrerEngine inferrer;
  final VariableScope locals;
  final Map<Local, Element> captured;
  final Map<Local, Element> capturedAndBoxed;
  final FieldInitializationScope fieldScope;
  LocalsHandler tryBlock;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }

  bool get inTryBlock => tryBlock != null;

  LocalsHandler(this.inferrer, this.types, this.options, Node block,
      [this.fieldScope])
      : locals = new VariableScope(block),
        captured = new Map<Local, Element>(),
        capturedAndBoxed = new Map<Local, Element>(),
        tryBlock = null;

  LocalsHandler.from(LocalsHandler other, Node block,
      {bool useOtherTryBlock: true})
      : locals = new VariableScope(block, other.locals),
        fieldScope = new FieldInitializationScope.from(other.fieldScope),
        captured = other.captured,
        capturedAndBoxed = other.capturedAndBoxed,
        types = other.types,
        inferrer = other.inferrer,
        options = other.options {
    tryBlock = useOtherTryBlock ? other.tryBlock : this;
  }

  LocalsHandler.deepCopyOf(LocalsHandler other)
      : locals = new VariableScope.deepCopyOf(other.locals),
        fieldScope = new FieldInitializationScope.from(other.fieldScope),
        captured = other.captured,
        capturedAndBoxed = other.capturedAndBoxed,
        tryBlock = other.tryBlock,
        types = other.types,
        inferrer = other.inferrer,
        options = other.options;

  LocalsHandler.topLevelCopyOf(LocalsHandler other)
      : locals = new VariableScope.topLevelCopyOf(other.locals),
        fieldScope = new FieldInitializationScope.from(other.fieldScope),
        captured = other.captured,
        capturedAndBoxed = other.capturedAndBoxed,
        tryBlock = other.tryBlock,
        types = other.types,
        inferrer = other.inferrer,
        options = other.options;

  TypeInformation use(Local local) {
    if (capturedAndBoxed.containsKey(local)) {
      return inferrer.typeOfElement(capturedAndBoxed[local]);
    } else {
      if (captured.containsKey(local)) {
        inferrer.recordCapturedLocalRead(local);
      }
      return locals[local];
    }
  }

  void update(LocalElement local, TypeInformation type, Node node) {
    assert(type != null);
    if (options.trustTypeAnnotations || options.enableTypeAssertions) {
      type = types.narrowType(type, local.type);
    }
    updateLocal() {
      TypeInformation currentType = locals[local];

      SendSet send = node != null ? node.asSendSet() : null;
      if (send != null && send.isIfNullAssignment && currentType != null) {
        // If-null assignments may return either the new or the original value
        // narrowed to non-null.
        type = types.addPhiInput(
            local,
            types.allocatePhi(
                locals.block, local, types.narrowNotNull(currentType)),
            type);
      }
      locals[local] = type;
      if (currentType != type) {
        inferrer.recordLocalUpdate(local, type);
      }
    }

    if (capturedAndBoxed.containsKey(local)) {
      inferrer.recordTypeOfNonFinalField(node, capturedAndBoxed[local], type);
    } else if (inTryBlock) {
      // We don'TypeInformation know if an assignment in a try block
      // will be executed, so all assignments in that block are
      // potential types after we have left it. We update the parent
      // of the try block so that, at exit of the try block, we get
      // the right phi for it.
      TypeInformation existing = tryBlock.locals.parent[local];
      if (existing != null) {
        TypeInformation phiType =
            types.allocatePhi(tryBlock.locals.block, local, existing);
        TypeInformation inputType = types.addPhiInput(local, phiType, type);
        tryBlock.locals.parent[local] = inputType;
      }
      // Update the current handler unconditionnally with the new
      // type.
      updateLocal();
    } else {
      updateLocal();
    }
  }

  void setCaptured(Local local, Element field) {
    captured[local] = field;
  }

  void setCapturedAndBoxed(Local local, Element field) {
    capturedAndBoxed[local] = field;
  }

  void mergeDiamondFlow(LocalsHandler thenBranch, LocalsHandler elseBranch) {
    if (fieldScope != null && elseBranch != null) {
      fieldScope.mergeDiamondFlow(thenBranch.fieldScope, elseBranch.fieldScope);
    }
    seenReturnOrThrow = thenBranch.seenReturnOrThrow &&
        elseBranch != null &&
        elseBranch.seenReturnOrThrow;
    seenBreakOrContinue = thenBranch.seenBreakOrContinue &&
        elseBranch != null &&
        elseBranch.seenBreakOrContinue;
    if (aborts) return;

    void mergeOneBranch(LocalsHandler other) {
      other.locals.forEachOwnLocal((Local local, TypeInformation type) {
        TypeInformation myType = locals[local];
        if (myType == null) return; // Variable is only defined in [other].
        if (type == myType) return;
        locals[local] = types.allocateDiamondPhi(myType, type);
      });
    }

    void inPlaceUpdateOneBranch(LocalsHandler other) {
      other.locals.forEachOwnLocal((Local local, TypeInformation type) {
        TypeInformation myType = locals[local];
        if (myType == null) return; // Variable is only defined in [other].
        if (type == myType) return;
        locals[local] = type;
      });
    }

    if (thenBranch.aborts) {
      if (elseBranch == null) return;
      inPlaceUpdateOneBranch(elseBranch);
    } else if (elseBranch == null) {
      mergeOneBranch(thenBranch);
    } else if (elseBranch.aborts) {
      inPlaceUpdateOneBranch(thenBranch);
    } else {
      void mergeLocal(Local local) {
        TypeInformation myType = locals[local];
        if (myType == null) return;
        TypeInformation elseType = elseBranch.locals[local];
        TypeInformation thenType = thenBranch.locals[local];
        if (thenType == elseType) {
          locals[local] = thenType;
        } else {
          locals[local] = types.allocateDiamondPhi(thenType, elseType);
        }
      }

      thenBranch.locals.forEachOwnLocal((Local local, _) {
        mergeLocal(local);
      });
      elseBranch.locals.forEachOwnLocal((Local local, _) {
        // Discard locals we already processed when iterating over
        // [thenBranch]'s locals.
        if (!thenBranch.locals.updates(local)) mergeLocal(local);
      });
    }
  }

  /**
   * Merge all [LocalsHandler] in [handlers] into [:this:].
   *
   * If [keepOwnLocals] is true, the types of locals in this
   * [LocalsHandler] are being used in the merge. [keepOwnLocals]
   * should be true if this [LocalsHandler], the dominator of
   * all [handlers], also directly flows into the join point,
   * that is the code after all [handlers]. For example, consider:
   *
   * [: switch (...) {
   *      case 1: ...; break;
   *    }
   * :]
   *
   * The [LocalsHandler] at entry of the switch also flows into the
   * exit of the switch, because there is no default case. So the
   * types of locals at entry of the switch have to take part to the
   * merge.
   *
   * The above situation is also true for labeled statements like
   *
   * [: L: {
   *      if (...) break;
   *      ...
   *    }
   * :]
   *
   * where [:this:] is the [LocalsHandler] for the paths through the
   * labeled statement that do not break out.
   */
  void mergeAfterBreaks(List<LocalsHandler> handlers,
      {bool keepOwnLocals: true}) {
    Node level = locals.block;
    // Use a separate locals handler to perform the merge in, so that Phi
    // creation does not invalidate previous type knowledge while we might
    // still look it up.
    LocalsHandler merged = new LocalsHandler.from(this, level);
    Set<Local> seenLocals = new Setlet<Local>();
    bool allBranchesAbort = true;
    // Merge all other handlers.
    for (LocalsHandler handler in handlers) {
      allBranchesAbort = allBranchesAbort && handler.seenReturnOrThrow;
      merged.mergeHandler(handler, seenLocals);
    }
    // If we want to keep own locals, we merge [seenLocals] from [this] into
    // [merged] to update the Phi nodes with original values.
    if (keepOwnLocals && !seenReturnOrThrow) {
      for (Local variable in seenLocals) {
        TypeInformation originalType = locals[variable];
        if (originalType != null) {
          merged.locals[variable] = types.addPhiInput(
              variable, merged.locals[variable], originalType);
        }
      }
    }
    // Clean up Phi nodes with single input and store back result into
    // actual locals handler.
    merged.locals.forEachOwnLocal((Local variable, TypeInformation type) {
      locals[variable] = types.simplifyPhi(level, variable, type);
    });
    seenReturnOrThrow =
        allBranchesAbort && (!keepOwnLocals || seenReturnOrThrow);
  }

  /**
   * Merge [other] into this handler. Returns whether a local in this
   * has changed. If [seen] is not null, we allocate new Phi nodes
   * unless the local is already present in the set [seen]. This effectively
   * overwrites the current type knowledge in this handler.
   */
  bool mergeHandler(LocalsHandler other, [Set<Local> seen]) {
    if (other.seenReturnOrThrow) return false;
    bool changed = false;
    other.locals.forEachLocalUntilNode(locals.block, (local, otherType) {
      TypeInformation myType = locals[local];
      if (myType == null) return;
      TypeInformation newType;
      if (seen != null && !seen.contains(local)) {
        newType = types.allocatePhi(locals.block, local, otherType);
        seen.add(local);
      } else {
        newType = types.addPhiInput(local, myType, otherType);
      }
      if (newType != myType) {
        changed = true;
        locals[local] = newType;
      }
    });
    return changed;
  }

  /**
   * Merge all [LocalsHandler] in [handlers] into this handler.
   * Returns whether a local in this handler has changed.
   */
  bool mergeAll(List<LocalsHandler> handlers) {
    bool changed = false;
    assert(!seenReturnOrThrow);
    handlers.forEach((other) {
      changed = mergeHandler(other) || changed;
    });
    return changed;
  }

  void startLoop(Node loop) {
    locals.forEachLocal((Local variable, TypeInformation type) {
      TypeInformation newType = types.allocateLoopPhi(loop, variable, type);
      if (newType != type) {
        locals[variable] = newType;
      }
    });
  }

  void endLoop(Node loop) {
    locals.forEachLocal((Local variable, TypeInformation type) {
      TypeInformation newType = types.simplifyPhi(loop, variable, type);
      if (newType != type) {
        locals[variable] = newType;
      }
    });
  }

  void updateField(Element element, TypeInformation type) {
    fieldScope.updateField(element, type);
  }
}
