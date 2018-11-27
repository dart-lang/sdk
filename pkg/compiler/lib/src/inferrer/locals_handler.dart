// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library locals_handler;

import 'dart:collection' show IterableMixin;
import 'package:kernel/ast.dart' as ir;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../util/util.dart';
import 'inferrer_engine.dart';
import 'type_graph_nodes.dart';

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

  /// The [ir.Node] that created this scope.
  final ir.Node block;

  /// `true` if this scope is for a try block.
  final bool isTry;

  VariableScope(this.block, {VariableScope parent, this.isTry})
      : this.variables = null,
        this.parent = parent {
    assert(isTry == (block is ir.TryCatch || block is ir.TryFinally),
        "Unexpected block $block for isTry=$isTry");
  }

  VariableScope.deepCopyOf(VariableScope other)
      : variables = other.variables == null
            ? null
            : new Map<Local, TypeInformation>.from(other.variables),
        block = other.block,
        isTry = other.isTry,
        parent = other.parent == null
            ? null
            : new VariableScope.deepCopyOf(other.parent);

  VariableScope.topLevelCopyOf(VariableScope other)
      : variables = other.variables == null
            ? null
            : new Map<Local, TypeInformation>.from(other.variables),
        block = other.block,
        isTry = other.isTry,
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
      ir.Node node, void f(Local variable, TypeInformation type),
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
  Map<FieldEntity, TypeInformation> fields;
  bool isThisExposed;

  /// `true` when control flow prevents accumulating definite assignments,
  /// e.g. an early return or caught exception.
  bool isIndefinite;

  FieldInitializationScope()
      : isThisExposed = false,
        isIndefinite = false;

  FieldInitializationScope.internalFrom(FieldInitializationScope other)
      : isThisExposed = other.isThisExposed,
        isIndefinite = other.isIndefinite;

  factory FieldInitializationScope.from(FieldInitializationScope other) {
    if (other == null) return null;
    return new FieldInitializationScope.internalFrom(other);
  }

  void updateField(FieldEntity field, TypeInformation type) {
    if (isThisExposed) return;
    if (isIndefinite) return;
    fields ??= new Map<FieldEntity, TypeInformation>();
    fields[field] = type;
  }

  TypeInformation readField(FieldEntity field) {
    return fields == null ? null : fields[field];
  }

  void forEach(void f(FieldEntity element, TypeInformation type)) {
    fields?.forEach(f);
  }

  FieldInitializationScope mergeDiamondFlow(InferrerEngine inferrer,
      FieldInitializationScope thenScope, FieldInitializationScope elseScope) {
    if (elseScope == null) return this;

    // Quick bailout check. If [isThisExposed] or [isIndefinite] is true, we
    // know the code following won'TypeInformation do anything.
    if (isThisExposed) return this;
    if (isIndefinite) return this;

    FieldInitializationScope otherScope =
        (elseScope == null || elseScope.fields == null) ? this : elseScope;

    thenScope.forEach((FieldEntity field, TypeInformation type) {
      TypeInformation otherType = otherScope.readField(field);
      if (otherType == null) return;
      updateField(field, inferrer.types.allocateDiamondPhi(type, otherType));
    });

    isThisExposed = thenScope.isThisExposed || elseScope.isThisExposed;
    isIndefinite = thenScope.isIndefinite || elseScope.isIndefinite;
    return this;
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
    var result = true;
    named.forEach((name, type) {
      if (other.named[name] != type) result = false;
    });
    return result;
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

  bool contains(Object type) {
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
  final VariableScope _locals;
  LocalsHandler _tryBlock;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }

  bool get inTryBlock => _tryBlock != null;

  LocalsHandler.internal(ir.Node block, this._locals, this._tryBlock);

  LocalsHandler(ir.Node block)
      : _locals = new VariableScope(block, isTry: false),
        _tryBlock = null;

  LocalsHandler.from(LocalsHandler other, ir.Node block,
      {bool isTry: false, bool useOtherTryBlock: true})
      : _locals =
            new VariableScope(block, isTry: isTry, parent: other._locals) {
    _tryBlock = useOtherTryBlock ? other._tryBlock : this;
  }

  LocalsHandler.deepCopyOf(LocalsHandler other)
      : _locals = new VariableScope.deepCopyOf(other._locals),
        _tryBlock = other._tryBlock;

  LocalsHandler.topLevelCopyOf(LocalsHandler other)
      : _locals = new VariableScope.topLevelCopyOf(other._locals),
        _tryBlock = other._tryBlock;

  TypeInformation use(InferrerEngine inferrer,
      Map<Local, FieldEntity> capturedAndBoxed, Local local) {
    FieldEntity field = capturedAndBoxed[local];
    if (field != null) {
      return inferrer.typeOfMember(field);
    } else {
      return _locals[local];
    }
  }

  void update(InferrerEngine inferrer, Map<Local, FieldEntity> capturedAndBoxed,
      Local local, TypeInformation type, ir.Node node, DartType staticType) {
    assert(type != null);
    type = inferrer.types.narrowType(type, staticType);

    FieldEntity field = capturedAndBoxed[local];
    if (field != null) {
      inferrer.recordTypeOfField(field, type);
    } else if (inTryBlock) {
      // We don't know if an assignment in a try block
      // will be executed, so all assignments in that block are
      // potential types after we have left it. We update the parent
      // of the try block so that, at exit of the try block, we get
      // the right phi for it.
      TypeInformation existing = _tryBlock._locals.parent[local];
      if (existing != null) {
        TypeInformation phiType = inferrer.types.allocatePhi(
            _tryBlock._locals.block, local, existing,
            isTry: _tryBlock._locals.isTry);
        TypeInformation inputType =
            inferrer.types.addPhiInput(local, phiType, type);
        _tryBlock._locals.parent[local] = inputType;
      }
      // Update the current handler unconditionally with the new
      // type.
      _locals[local] = type;
    } else {
      _locals[local] = type;
    }
  }

  void narrow(InferrerEngine inferrer, Map<Local, FieldEntity> capturedAndBoxed,
      Local local, DartType type, ir.Node node) {
    TypeInformation existing = use(inferrer, capturedAndBoxed, local);
    TypeInformation newType =
        inferrer.types.narrowType(existing, type, isNullable: false);
    update(inferrer, capturedAndBoxed, local, newType, node, type);
  }

  LocalsHandler mergeDiamondFlow(InferrerEngine inferrer,
      LocalsHandler thenBranch, LocalsHandler elseBranch) {
    seenReturnOrThrow = thenBranch.seenReturnOrThrow &&
        elseBranch != null &&
        elseBranch.seenReturnOrThrow;
    seenBreakOrContinue = thenBranch.seenBreakOrContinue &&
        elseBranch != null &&
        elseBranch.seenBreakOrContinue;
    if (aborts) return this;

    void mergeOneBranch(LocalsHandler other) {
      other._locals.forEachOwnLocal((Local local, TypeInformation type) {
        TypeInformation myType = _locals[local];
        if (myType == null) return; // Variable is only defined in [other].
        if (type == myType) return;
        _locals[local] = inferrer.types.allocateDiamondPhi(myType, type);
      });
    }

    void inPlaceUpdateOneBranch(LocalsHandler other) {
      other._locals.forEachOwnLocal((Local local, TypeInformation type) {
        TypeInformation myType = _locals[local];
        if (myType == null) return; // Variable is only defined in [other].
        if (type == myType) return;
        _locals[local] = type;
      });
    }

    if (thenBranch.aborts) {
      if (elseBranch == null) return this;
      inPlaceUpdateOneBranch(elseBranch);
    } else if (elseBranch == null) {
      mergeOneBranch(thenBranch);
    } else if (elseBranch.aborts) {
      inPlaceUpdateOneBranch(thenBranch);
    } else {
      void mergeLocal(Local local) {
        TypeInformation myType = _locals[local];
        if (myType == null) return;
        TypeInformation elseType = elseBranch._locals[local];
        TypeInformation thenType = thenBranch._locals[local];
        if (thenType == elseType) {
          _locals[local] = thenType;
        } else {
          _locals[local] =
              inferrer.types.allocateDiamondPhi(thenType, elseType);
        }
      }

      thenBranch._locals.forEachOwnLocal((Local local, _) {
        mergeLocal(local);
      });
      elseBranch._locals.forEachOwnLocal((Local local, _) {
        // Discard locals we already processed when iterating over
        // [thenBranch]'s locals.
        if (!thenBranch._locals.updates(local)) mergeLocal(local);
      });
    }
    return this;
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
  LocalsHandler mergeAfterBreaks(
      InferrerEngine inferrer, List<LocalsHandler> handlers,
      {bool keepOwnLocals: true}) {
    ir.Node level = _locals.block;
    // Use a separate locals handler to perform the merge in, so that Phi
    // creation does not invalidate previous type knowledge while we might
    // still look it up.
    LocalsHandler merged =
        new LocalsHandler.from(this, level, isTry: _locals.isTry);
    Set<Local> seenLocals = new Setlet<Local>();
    bool allBranchesAbort = true;
    // Merge all other handlers.
    for (LocalsHandler handler in handlers) {
      allBranchesAbort = allBranchesAbort && handler.seenReturnOrThrow;
      merged._mergeHandler(inferrer, handler, seenLocals);
    }
    // If we want to keep own locals, we merge [seenLocals] from [this] into
    // [merged] to update the Phi nodes with original values.
    if (keepOwnLocals && !seenReturnOrThrow) {
      for (Local variable in seenLocals) {
        TypeInformation originalType = _locals[variable];
        if (originalType != null) {
          merged._locals[variable] = inferrer.types
              .addPhiInput(variable, merged._locals[variable], originalType);
        }
      }
    }
    // Clean up Phi nodes with single input and store back result into
    // actual locals handler.
    merged._locals.forEachOwnLocal((Local variable, TypeInformation type) {
      _locals[variable] = inferrer.types.simplifyPhi(level, variable, type);
    });
    seenReturnOrThrow =
        allBranchesAbort && (!keepOwnLocals || seenReturnOrThrow);
    return this;
  }

  /**
   * Merge [other] into this handler. Returns whether a local in this
   * has changed. If [seen] is not null, we allocate new Phi nodes
   * unless the local is already present in the set [seen]. This effectively
   * overwrites the current type knowledge in this handler.
   */
  bool _mergeHandler(InferrerEngine inferrer, LocalsHandler other,
      [Set<Local> seen]) {
    if (other.seenReturnOrThrow) return false;
    bool changed = false;
    other._locals.forEachLocalUntilNode(_locals.block, (local, otherType) {
      TypeInformation myType = _locals[local];
      if (myType == null) return;
      TypeInformation newType;
      if (seen != null && !seen.contains(local)) {
        newType = inferrer.types
            .allocatePhi(_locals.block, local, otherType, isTry: _locals.isTry);
        seen.add(local);
      } else {
        newType = inferrer.types.addPhiInput(local, myType, otherType);
      }
      if (newType != myType) {
        changed = true;
        _locals[local] = newType;
      }
    });
    return changed;
  }

  /**
   * Merge all [LocalsHandler] in [handlers] into this handler.
   * Returns whether a local in this handler has changed.
   */
  bool mergeAll(InferrerEngine inferrer, List<LocalsHandler> handlers) {
    bool changed = false;
    assert(!seenReturnOrThrow);
    handlers.forEach((other) {
      changed = _mergeHandler(inferrer, other) || changed;
    });
    return changed;
  }

  void startLoop(InferrerEngine inferrer, ir.Node loop) {
    _locals.forEachLocal((Local variable, TypeInformation type) {
      TypeInformation newType =
          inferrer.types.allocateLoopPhi(loop, variable, type, isTry: false);
      if (newType != type) {
        _locals[variable] = newType;
      }
    });
  }

  void endLoop(InferrerEngine inferrer, ir.Node loop) {
    _locals.forEachLocal((Local variable, TypeInformation type) {
      TypeInformation newType =
          inferrer.types.simplifyPhi(loop, variable, type);
      if (newType != type) {
        _locals[variable] = newType;
      }
    });
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('LocalsHandler(');
    sb.write('locals=$_locals');
    sb.write(')');
    return sb.toString();
  }
}
