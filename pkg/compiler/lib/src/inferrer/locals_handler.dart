// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library locals_handler;

import 'dart:collection' show IterableMixin;
import 'package:kernel/ast.dart' as ir;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/util.dart';
import '../util/util.dart';
import 'inferrer_engine.dart';
import 'type_graph_nodes.dart';

/// A variable scope holds types for variables. It has a link to a
/// parent scope, but never changes the types in that parent. Instead,
/// updates to locals of a parent scope are put in the current scope.
/// The inferrer makes sure updates get merged into the parent scope,
/// once the control flow block has been visited.
class VariableScope {
  /// The number of parent scopes of this scope.
  ///
  /// This is used for computing common parents efficiently.
  final int _level;

  Map<Local, TypeInformation> variables;

  /// The parent of this scope. Null for the root scope.
  final VariableScope parent;

  /// The [ir.Node] that created this scope.
  final ir.Node tryBlock;

  final VariableScope copyOf;

  VariableScope({this.parent})
      : this.variables = null,
        this.copyOf = null,
        this.tryBlock = null,
        _level = (parent?._level ?? -1) + 1;

  VariableScope.tryBlock(this.tryBlock, {this.parent})
      : this.variables = null,
        this.copyOf = null,
        _level = (parent?._level ?? -1) + 1 {
    assert(tryBlock is ir.TryCatch || tryBlock is ir.TryFinally,
        "Unexpected block $tryBlock for VariableScope.tryBlock");
  }

  VariableScope.deepCopyOf(VariableScope other)
      : variables = other.variables == null
            ? null
            : new Map<Local, TypeInformation>.from(other.variables),
        tryBlock = other.tryBlock,
        copyOf = other.copyOf ?? other,
        _level = other._level,
        parent = other.parent == null
            ? null
            : new VariableScope.deepCopyOf(other.parent);

  /// `true` if this scope is for a try block.
  bool get isTry => tryBlock != null;

  /// Returns the [VariableScope] that defines the identity of this scope.
  ///
  /// If this scope is a copy of another scope, the identity is the identity
  /// of the other scope, otherwise the identity is the scope itself.
  VariableScope get identity => copyOf ?? this;

  /// Returns the common parent between this and [other] based on [identity].
  VariableScope commonParent(VariableScope other) {
    if (identity == other.identity) {
      return identity;
    } else if (_level > other._level) {
      return parent.commonParent(other);
    } else if (_level < other._level) {
      return commonParent(other.parent);
    } else if (_level > 0) {
      return parent.commonParent(other.parent);
    } else {
      return null;
    }
  }

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

  /// Calls [f] for all variables in this and parent scopes until and including
  /// [scope]. [f] is called at most once for each variable.
  void forEachLocalUntilScope(
      VariableScope scope, void f(Local variable, TypeInformation type)) {
    _forEachLocalUntilScope(scope, f, new Setlet<Local>(), this);
  }

  void _forEachLocalUntilScope(
      VariableScope scope,
      void f(Local variable, TypeInformation type),
      Setlet<Local> seenLocals,
      VariableScope origin) {
    if (variables != null) {
      variables.forEach((variable, type) {
        if (seenLocals.contains(variable)) return;
        seenLocals.add(variable);
        f(variable, type);
      });
    }
    if (scope?.identity == identity) {
      return;
    }
    if (parent != null) {
      parent._forEachLocalUntilScope(scope, f, seenLocals, origin);
    } else {
      assert(
          scope == null,
          "Scope not found: \n"
          "origin=${origin.toStructuredText('')}\n"
          "scope=${scope.toStructuredText('')}");
    }
  }

  void forEachLocal(void f(Local variable, TypeInformation type)) {
    forEachLocalUntilScope(null, f);
  }

  bool updates(Local variable) {
    if (variables == null) return false;
    return variables.containsKey(variable);
  }

  String toStructuredText(String indent) {
    StringBuffer sb = new StringBuffer();
    _toStructuredText(sb, indent);
    return sb.toString();
  }

  void _toStructuredText(StringBuffer sb, String indent) {
    sb.write('VariableScope($hashCode) [');
    sb.write('\n${indent}  level:$_level');
    if (copyOf != null) {
      sb.write('\n${indent}  copyOf:VariableScope(${copyOf.hashCode})');
    }
    if (tryBlock != null) {
      sb.write('\n${indent}  tryBlock: ${nodeToDebugString(tryBlock)}');
    }
    if (variables != null) {
      sb.write('\n${indent}  variables:');
      variables.forEach((Local local, TypeInformation type) {
        sb.write('\n${indent}    $local: ');
        sb.write(type.toStructuredText('${indent}      '));
      });
    }
    if (parent != null) {
      sb.write('\n${indent}  parent:');
      parent._toStructuredText(sb, '${indent}     ');
    }
    sb.write(']');
  }

  @override
  String toString() {
    String rest = parent == null ? "null" : parent.toString();
    return '{$variables} $rest';
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

  /// Returns the join between [thenScope] and [elseScope] which models the
  /// flow through either [thenScope] or [elseScope].
  FieldInitializationScope mergeDiamondFlow(InferrerEngine inferrer,
      FieldInitializationScope thenScope, FieldInitializationScope elseScope) {
    assert(elseScope != null);

    // Quick bailout check. If [isThisExposed] or [isIndefinite] is true, we
    // know the code following won'TypeInformation do anything.
    if (isThisExposed) return this;
    if (isIndefinite) return this;

    FieldInitializationScope otherScope =
        elseScope.fields == null ? this : elseScope;

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

/// Placeholder for inferred arguments types on sends.
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

  @override
  int get length => positional.length + named.length;

  @override
  Iterator<TypeInformation> get iterator => new ArgumentsTypesIterator(this);

  @override
  String toString() => "{ positional = $positional, named = $named }";

  @override
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

  @override
  int get hashCode => throw new UnsupportedError('ArgumentsTypes.hashCode');

  bool hasNoArguments() => positional.isEmpty && named.isEmpty;

  @override
  void forEach(void f(TypeInformation type)) {
    positional.forEach(f);
    named.values.forEach(f);
  }

  @override
  bool every(bool f(TypeInformation type)) {
    return positional.every(f) && named.values.every(f);
  }

  @override
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

  @override
  TypeInformation get current => _currentIterator.current;

  @override
  bool moveNext() {
    if (_iteratePositional && positional.moveNext()) {
      return true;
    }
    _iteratePositional = false;
    return named.moveNext();
  }
}

/// Placeholder for inferred types of local variables.
class LocalsHandler {
  final VariableScope _locals;

  LocalsHandler() : _locals = new VariableScope();

  LocalsHandler.from(LocalsHandler other)
      : _locals = new VariableScope(parent: other._locals);

  LocalsHandler.tryBlock(LocalsHandler other, ir.TreeNode block)
      : _locals = new VariableScope.tryBlock(block, parent: other._locals);

  LocalsHandler.deepCopyOf(LocalsHandler other)
      : _locals = new VariableScope.deepCopyOf(other._locals);

  TypeInformation use(InferrerEngine inferrer, Local local) {
    return _locals[local];
  }

  void update(InferrerEngine inferrer, Local local, TypeInformation type,
      ir.Node node, DartType staticType, LocalsHandler tryBlock) {
    if (tryBlock != null) {
      // We don't know if an assignment in a try block
      // will be executed, so all assignments in that block are
      // potential types after we have left it. We update the parent
      // of the try block so that, at exit of the try block, we get
      // the right phi for it.
      TypeInformation existing = tryBlock._locals.parent[local];
      if (existing != null) {
        TypeInformation phiType = inferrer.types.allocatePhi(
            tryBlock._locals.tryBlock, local, existing,
            isTry: tryBlock._locals.isTry);
        TypeInformation inputType =
            inferrer.types.addPhiInput(local, phiType, type);
        tryBlock._locals.parent[local] = inputType;
      }
      // Update the current handler unconditionally with the new
      // type.
      _locals[local] = type;
    } else {
      _locals[local] = type;
    }
  }

  /// Returns the join between this locals handler and [other] which models the
  /// flow through either this or [other].
  ///
  /// If [inPlace] is `true`, the variable types in this locals handler are
  /// replaced by the variables types in [other]. Otherwise the variable types
  /// from both are merged with a phi type.
  LocalsHandler mergeFlow(InferrerEngine inferrer, LocalsHandler other,
      {bool inPlace: false}) {
    VariableScope common = _locals.commonParent(other._locals);
    assert(
        common != null,
        "No common parent for\n"
        "1:${_locals.toStructuredText('  ')}\n"
        "2:${other._locals.toStructuredText('  ')}");
    assert(
        common == _locals || _locals.variables == null,
        "Non-empty common parent for\n"
        "1:${common.toStructuredText('  ')}\n"
        "2:${_locals.toStructuredText('  ')}");
    other._locals.forEachLocalUntilScope(common,
        (Local local, TypeInformation type) {
      TypeInformation myType = _locals[local];
      if (myType == null) return; // Variable is only defined in [other].
      if (type == myType) return;
      _locals[local] =
          inPlace ? type : inferrer.types.allocateDiamondPhi(myType, type);
    });
    return this;
  }

  /// Returns the join between [thenBranch] and [elseBranch] which models the
  /// flow through either [thenBranch] or [elseBranch].
  LocalsHandler mergeDiamondFlow(InferrerEngine inferrer,
      LocalsHandler thenBranch, LocalsHandler elseBranch) {
    assert(elseBranch != null);

    void mergeLocal(Local local) {
      TypeInformation myType = _locals[local];
      if (myType == null) return;
      TypeInformation elseType = elseBranch._locals[local];
      TypeInformation thenType = thenBranch._locals[local];
      if (thenType == elseType) {
        _locals[local] = thenType;
      } else {
        _locals[local] = inferrer.types.allocateDiamondPhi(thenType, elseType);
      }
    }

    VariableScope common = _locals.commonParent(thenBranch._locals);
    assert(
        common != null,
        "No common parent for\n"
        "1:${_locals.toStructuredText('  ')}\n"
        "2:${thenBranch._locals.toStructuredText('  ')}");
    assert(
        _locals.commonParent(elseBranch._locals) == common,
        "Diff common parent for\n"
        "1:${common.toStructuredText('  ')}\n2:"
        "${_locals.commonParent(elseBranch._locals)?.toStructuredText('  ')}");
    assert(
        common == _locals || _locals.variables == null,
        "Non-empty common parent for\n"
        "common:${common.toStructuredText('  ')}\n"
        "1:${_locals.toStructuredText('  ')}\n"
        "2:${thenBranch._locals.toStructuredText('  ')}");
    thenBranch._locals.forEachLocalUntilScope(common, (Local local, _) {
      mergeLocal(local);
    });
    elseBranch._locals.forEachLocalUntilScope(common, (Local local, _) {
      // Discard locals we already processed when iterating over
      // [thenBranch]'s locals.
      if (!thenBranch._locals.updates(local)) mergeLocal(local);
    });
    return this;
  }

  /// Merge all [LocalsHandler] in [handlers] into [:this:].
  ///
  /// If [keepOwnLocals] is true, the types of locals in this
  /// [LocalsHandler] are being used in the merge. [keepOwnLocals]
  /// should be true if this [LocalsHandler], the dominator of
  /// all [handlers], also directly flows into the join point,
  /// that is the code after all [handlers]. For example, consider:
  ///
  /// [: switch (...) {
  ///      case 1: ...; break;
  ///    }
  /// :]
  ///
  /// The [LocalsHandler] at entry of the switch also flows into the
  /// exit of the switch, because there is no default case. So the
  /// types of locals at entry of the switch have to take part to the
  /// merge.
  ///
  /// The above situation is also true for labeled statements like
  ///
  /// [: L: {
  ///      if (...) break;
  ///      ...
  ///    }
  /// :]
  ///
  /// where [:this:] is the [LocalsHandler] for the paths through the
  /// labeled statement that do not break out.
  LocalsHandler mergeAfterBreaks(
      InferrerEngine inferrer, Iterable<LocalsHandler> handlers,
      {bool keepOwnLocals: true}) {
    ir.Node tryBlock = _locals.tryBlock;
    // Use a separate locals handler to perform the merge in, so that Phi
    // creation does not invalidate previous type knowledge while we might
    // still look it up.
    VariableScope merged = tryBlock != null
        ? new VariableScope.tryBlock(tryBlock, parent: _locals)
        : new VariableScope(parent: _locals);
    Set<Local> seenLocals = new Setlet<Local>();
    // Merge all other handlers.
    for (LocalsHandler handler in handlers) {
      VariableScope common = _locals.commonParent(handler._locals);
      assert(
          common != null,
          "No common parent for\n"
          "1:${_locals.toStructuredText('  ')}\n"
          "2:${handler._locals.toStructuredText('  ')}");
      assert(
          common == _locals || _locals.variables == null,
          "Non-empty common parent for\n"
          "common:${common.toStructuredText('  ')}\n"
          "1:${_locals.toStructuredText('  ')}\n"
          "2:${handler._locals.toStructuredText('  ')}");
      handler._locals.forEachLocalUntilScope(common, (local, otherType) {
        TypeInformation myType = merged[local];
        if (myType == null) return;
        TypeInformation newType;
        if (!seenLocals.contains(local)) {
          newType = inferrer.types.allocatePhi(
              merged.tryBlock, local, otherType,
              isTry: merged.isTry);
          seenLocals.add(local);
        } else {
          newType = inferrer.types.addPhiInput(local, myType, otherType);
        }
        if (newType != myType) {
          merged[local] = newType;
        }
      });
    }
    // If we want to keep own locals, we merge [seenLocals] from [this] into
    // [merged] to update the Phi nodes with original values.
    if (keepOwnLocals) {
      for (Local variable in seenLocals) {
        TypeInformation originalType = _locals[variable];
        if (originalType != null) {
          merged[variable] = inferrer.types
              .addPhiInput(variable, merged[variable], originalType);
        }
      }
    }
    // Clean up Phi nodes with single input and store back result into
    // actual locals handler.
    merged.forEachLocalUntilScope(merged,
        (Local variable, TypeInformation type) {
      _locals[variable] = inferrer.types.simplifyPhi(tryBlock, variable, type);
    });
    return this;
  }

  /// Merge all [LocalsHandler] in [handlers] into this handler.
  /// Returns whether a local in this handler has changed.
  bool mergeAll(InferrerEngine inferrer, Iterable<LocalsHandler> handlers) {
    bool changed = false;
    handlers.forEach((LocalsHandler other) {
      VariableScope common = _locals.commonParent(other._locals);
      assert(
          common != null,
          "No common parent for\n"
          "1:${_locals.toStructuredText('  ')}\n"
          "2:${other._locals.toStructuredText('  ')}");
      assert(
          common == _locals || _locals.variables == null,
          "Non-empty common parent for\n"
          "common:${common.toStructuredText('  ')}\n"
          "1:${_locals.toStructuredText('  ')}\n"
          "2:${other._locals.toStructuredText('  ')}");
      other._locals.forEachLocalUntilScope(common, (local, otherType) {
        TypeInformation myType = _locals[local];
        if (myType == null) return;
        TypeInformation newType =
            inferrer.types.addPhiInput(local, myType, otherType);
        if (newType != myType) {
          changed = true;
          _locals[local] = newType;
        }
      });
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

  String toStructuredText(String indent) {
    StringBuffer sb = new StringBuffer();
    _toStructuredText(sb, indent);
    return sb.toString();
  }

  void _toStructuredText(StringBuffer sb, String indent) {
    sb.write('LocalsHandler($hashCode) [');
    sb.write('\n${indent}  locals:');
    _locals._toStructuredText(sb, '${indent}    ');
    sb.write('\n]');
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('LocalsHandler(');
    sb.write('locals=$_locals');
    sb.write(')');
    return sb.toString();
  }
}
