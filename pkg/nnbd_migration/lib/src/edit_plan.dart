// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';

/// Abstract base class representing a single atomic change to a source file,
/// decoupled from the location at which the change is made.  The [EditPlan]
/// class performs its duties by creating and manipulating [AtomicEdit] objects.
///
/// A list of [AtomicEdit]s may be converted to a [SourceEdit] using the
/// extension [AtomicEditList], and a map of offsets to lists of [AtomicEdit]s
/// may be converted to a list of [SourceEdit] using the extension
/// [AtomicEditMap].
///
/// May be subclassed to allow additional information to be recorded about the
/// deletion.
abstract class AtomicEdit {
  const AtomicEdit();

  /// Queries the number of source characters that should be deleted by this
  /// edit, or 0 if no characters should be deleted.
  int get length;

  /// Queries the source characters that should be inserted by this edit, or
  /// the empty string if no characters should be inserted.
  String get replacement;
}

/// Implementation of [AtomicEdit] that deletes characters of text.
///
/// May be subclassed to allow additional information to be recorded about the
/// deletion.
class DeleteText extends AtomicEdit {
  @override
  final int length;

  const DeleteText(this.length);

  @override
  String get replacement => '';

  @override
  String toString() => 'DeleteText($length)';
}

/// An [EditPlan] is a builder capable of accumulating a set of edits to be
/// applied to a given [AstNode].
///
/// Examples of edits include replacing it with a different node, prefixing or
/// suffixing it with additional text, or deleting some of the text it contains.
/// When the text being produced represents an expression, [EditPlan] also keeps
/// track of the precedence of the expression and whether it ends in a
/// casade--this allows automatic insertion of parentheses when necessary, as
/// well as removal of parentheses when they become unnecessary.
///
/// Typical usage will be to produce one or more [EditPlan] objects representing
/// changes to be made to the source code, compose them together, and then call
/// [EditPlan.finalize] to convert into a representation of the concrete edits
/// that need to be made to the source file.
abstract class EditPlan {
  /// The AST node to which the edit plan applies.
  final AstNode sourceNode;

  EditPlan(this.sourceNode);

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// removing from the source code any code that is in [sourceNode] but not in
  /// [innerPlan.sourceNode].  This is intended to be used to drop unnecessary
  /// syntax (for example, to drop an unnecessary cast).
  ///
  /// If no changes are required to the AST node that is being extracted, the
  /// caller may create innerPlan using [EditPlan.passThrough].
  ///
  /// [innerPlan] will be finalized as a side effect (either immediately or when
  /// the newly created plan is finalized), so it should not be re-used by the
  /// caller.
  factory EditPlan.extract(AstNode sourceNode, EditPlan innerPlan) {
    innerPlan = innerPlan._incorporateParenParentIfPresent(sourceNode);
    if (innerPlan is _ProvisionalParenEditPlan) {
      return _ProvisionalParenExtractEditPlan(sourceNode, innerPlan);
    } else {
      return _ExtractEditPlan(sourceNode, innerPlan);
    }
  }

  /// Creates a new edit plan that makes no changes to [node], but may make
  /// changes to some of its descendants (specified via [innerPlans]).
  ///
  /// All plans in [innerPlans] will be finalized as a side effect (either
  /// immediately or when the newly created plan is finalized), so they should
  /// not be re-used by the caller.
  factory EditPlan.passThrough(AstNode node,
      {Iterable<EditPlan> innerPlans = const []}) {
    if (node is ParenthesizedExpression) {
      return _ProvisionalParenEditPlan(
          node, _PassThroughEditPlan(node.expression, innerPlans: innerPlans));
    } else {
      return _PassThroughEditPlan(node, innerPlans: innerPlans);
    }
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// surrounding it with [prefix] and [suffix] text.  This could be used, for
  /// example, to add a cast.
  ///
  /// If the edit plan is going to be used in a context where an expression is
  /// expected, additional arguments should be provided to control the behavior
  /// of parentheses insertion and deletion: [outerPrecedence] indicates the
  /// precedence of the resulting expression.  [innerPrecedence] indicates the
  /// precedence that is required for [innerPlan].  [associative] indicates
  /// whether it is allowed for [innerPlan]'s precedence to match
  /// [innerPrecedence].  [allowCascade] indicates whether [innerPlan] can end
  /// in a cascade section without requiring parentheses.  [endsInCascade]
  /// indicates whether the resulting plan will end in a cascade.
  ///
  /// So, for example, if it is desired to append the suffix ` + foo` to an
  /// expression, specify `Precedence.additive` for [outerPrecedence] and
  /// [innerPrecedence], and `true` for [associative] (since addition associates
  /// to the left).
  ///
  /// Note that [endsInCascade] is ignored if there is no [suffix] (since in
  /// this situation, whether the final plan ends in a cascade section will be
  /// determined by [innerPlan]).
  factory EditPlan.surround(EditPlan innerPlan,
      {List<InsertText> prefix,
      List<InsertText> suffix,
      Precedence outerPrecedence = Precedence.primary,
      Precedence innerPrecedence = Precedence.none,
      bool associative = false,
      bool allowCascade = false,
      bool endsInCascade = false}) {
    var parensNeeded = innerPlan._parensNeeded(
        threshold: innerPrecedence,
        associative: associative,
        allowCascade: allowCascade);
    var innerChanges =
        innerPlan._getChanges(parensNeeded) ?? <int, List<AtomicEdit>>{};
    if (prefix != null) {
      (innerChanges[innerPlan.sourceNode.offset] ??= []).insertAll(0, prefix);
    }
    if (suffix != null) {
      (innerChanges[innerPlan.sourceNode.end] ??= []).addAll(suffix);
    }
    return _SimpleEditPlan(
        innerPlan.sourceNode,
        outerPrecedence,
        suffix == null
            ? innerPlan.endsInCascade && !parensNeeded
            : endsInCascade,
        innerChanges);
  }

  /// If the result of executing this [EditPlan] will be an expression,
  /// indicates whether the expression will end in an unparenthesized cascade.
  @visibleForTesting
  bool get endsInCascade;

  /// Converts this [EditPlan] a representation of the concrete edits that need
  /// to be made to the source file.  These edits may be converted into
  /// [SourceEdit]s using the extensions [AtomicEditList] and [AtomicEditMap].
  ///
  /// Finalizing an [EditPlan] is a destructive operation; it should not be used
  /// again after it is finalized.
  Map<int, List<AtomicEdit>> finalize() {
    var plan = _incorporateParenParentIfPresent(null);
    return plan._getChanges(plan.parensNeededFromContext(null));
  }

  /// Determines whether the text produced by this [EditPlan] would need
  /// parentheses if it were to be used as a replacement for its [sourceNode].
  ///
  /// If this [EditPlan] would produce an expression that ends in a cascade, it
  /// will be necessary to search the [sourceNode]'s ancestors to see if any of
  /// them represents a cascade section (and hence, parentheses are required).
  /// If a non-null value is provided for [cascadeSearchLimit], it is the most
  /// distant ancestor that will be searched.
  @visibleForTesting
  bool parensNeededFromContext(AstNode cascadeSearchLimit) {
    if (sourceNode is! Expression) return false;
    var parent = sourceNode.parent;
    return parent == null
        ? false
        : parent
            .accept(_ParensNeededFromContextVisitor(this, cascadeSearchLimit));
  }

  /// Modifies [changes] to insert parentheses enclosing the [sourceNode].  This
  /// works even if [changes] already includes modifications at the beginning or
  /// end of [sourceNode]--the parentheses are inserted outside of any
  /// pre-existing changes.
  Map<int, List<AtomicEdit>> _createAddParenChanges(
      Map<int, List<AtomicEdit>> changes) {
    changes ??= {};
    (changes[sourceNode.offset] ??= []).insert(0, const InsertText('('));
    (changes[sourceNode.end] ??= []).add(const InsertText(')'));
    return changes;
  }

  /// Computes the necessary set of [changes] for this [EditPlan], either
  /// including or not including parentheses depending on the value of [parens].
  ///
  /// An [EditPlan] for which [_getChanges] has been called is considered to be
  /// finalized.
  Map<int, List<AtomicEdit>> _getChanges(bool parens);

  /// If the [sourceNode]'s parent is a [ParenthesizedExpression] returns a
  /// [_ProvisionalParenEditPlan] which will keep or discard the enclosing
  /// parentheses as necessary based on precedence.  Otherwise, returns this.
  ///
  /// If [limit] is provided, and it is the same as [sourceNode]'s parent, then
  /// the parent is ignored.  This is used to avoid trying to remove parentheses
  /// twice.
  ///
  /// This method is used when composing and finalizing plans, to ensure that
  /// parentheses are removed when they are no longer needed.
  EditPlan _incorporateParenParentIfPresent(AstNode limit) {
    var parent = sourceNode.parent;
    if (!identical(parent, limit) && parent is ParenthesizedExpression) {
      return _ProvisionalParenEditPlan(parent, this);
    } else {
      return this;
    }
  }

  /// Determines if the text that would be produced by [EditPlan] needs to be
  /// surrounded by parens, based on the context in which it will be used.
  bool _parensNeeded(
      {@required Precedence threshold,
      bool associative = false,
      bool allowCascade = false});

  /// Creates the set of changes needed for an "extract" plan (see
  /// [EditPlan.extract]).  This is in its own method so that the computation
  /// can be deferred when appropriate.
  static Map<int, List<AtomicEdit>> _createExtractChanges(EditPlan innerPlan,
      AstNode sourceNode, Map<int, List<AtomicEdit>> changes) {
    // TODO(paulberry): don't remove comments
    if (innerPlan.sourceNode.offset > sourceNode.offset) {
      ((changes ??= {})[sourceNode.offset] ??= []).insert(
          0, DeleteText(innerPlan.sourceNode.offset - sourceNode.offset));
    }
    if (innerPlan.sourceNode.end < sourceNode.end) {
      ((changes ??= {})[innerPlan.sourceNode.end] ??= [])
          .add(DeleteText(sourceNode.end - innerPlan.sourceNode.end));
    }
    return changes;
  }
}

/// Implementation of [AtomicEdit] that inserts a string of new text.
///
/// May be subclassed to allow additional information to be recorded about the
/// insertion.
class InsertText extends AtomicEdit {
  @override
  final String replacement;

  const InsertText(this.replacement);

  @override
  int get length => 0;

  @override
  String toString() => 'InsertText(${json.encode(replacement)})';
}

/// Visitor that determines whether a given [AstNode] ends in a cascade.
class _EndsInCascadeVisitor extends UnifyingAstVisitor<void> {
  bool endsInCascade = false;

  final int end;

  _EndsInCascadeVisitor(this.end);

  @override
  void visitCascadeExpression(CascadeExpression node) {
    if (node.end != end) return;
    endsInCascade = true;
  }

  @override
  void visitNode(AstNode node) {
    if (node.end != end) return;
    node.visitChildren(this);
  }
}

/// [EditPlan] representing an "extraction" of an inner AST node, e.g. replacing
/// `a + b * c` with `b + c`.
///
/// Defers computation of whether parentheses are needed to the inner plan.
class _ExtractEditPlan extends _NestedEditPlan {
  final Map<int, List<AtomicEdit>> _innerChanges;

  bool _finalized = false;

  _ExtractEditPlan(AstNode sourceNode, EditPlan innerPlan)
      : _innerChanges = EditPlan._createExtractChanges(
            innerPlan, sourceNode, innerPlan._getChanges(false)),
        super(sourceNode, innerPlan);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) {
    assert(!_finalized);
    _finalized = true;
    return parens ? _createAddParenChanges(_innerChanges) : _innerChanges;
  }
}

/// [EditPlan] representing additional edits performed on the result of a
/// previous [innerPlan].
///
/// By default, defers computation of whether parentheses are needed to the
/// inner plan.
abstract class _NestedEditPlan extends EditPlan {
  final EditPlan innerPlan;

  _NestedEditPlan(AstNode sourceNode, this.innerPlan) : super(sourceNode);

  @override
  bool get endsInCascade => innerPlan.endsInCascade;

  @override
  bool _parensNeeded(
          {@required Precedence threshold,
          bool associative = false,
          bool allowCascade = false}) =>
      innerPlan._parensNeeded(
          threshold: threshold,
          associative: associative,
          allowCascade: allowCascade);
}

/// Visitor that determines whether an [_editPlan] needs to be parenthesized
/// based on the context surrounding its source node.  To use this class, visit
/// the source node's parent.
class _ParensNeededFromContextVisitor extends GeneralizingAstVisitor<bool> {
  final EditPlan _editPlan;

  /// If [_editPlan] would produce an expression that ends in a cascade, it
  /// will be necessary to search the [_target]'s ancestors to see if any of
  /// them represents a cascade section (and hence, parentheses are required).
  /// If a non-null value is provided for [_cascadeSearchLimit], it is the most
  /// distant ancestor that will be searched.
  final AstNode _cascadeSearchLimit;

  _ParensNeededFromContextVisitor(this._editPlan, this._cascadeSearchLimit) {
    assert(_target is Expression);
  }

  AstNode get _target => _editPlan.sourceNode;

  @override
  bool visitAsExpression(AsExpression node) {
    if (identical(_target, node.expression)) {
      return _editPlan._parensNeeded(threshold: Precedence.relational);
    } else {
      return false;
    }
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    if (identical(_target, node.rightHandSide)) {
      return _editPlan._parensNeeded(
          threshold: Precedence.none,
          allowCascade: !_isRightmostDescendantOfCascadeSection(node));
    } else {
      return false;
    }
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    assert(identical(_target, node.expression));
    return _editPlan._parensNeeded(
        threshold: Precedence.prefix, associative: true);
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    var precedence = node.precedence;
    return _editPlan._parensNeeded(
        threshold: precedence,
        associative: identical(_target, node.leftOperand) &&
            precedence != Precedence.relational &&
            precedence != Precedence.equality);
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    if (identical(_target, node.target)) {
      return _editPlan._parensNeeded(
          threshold: Precedence.cascade, associative: true, allowCascade: true);
    } else {
      return false;
    }
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    if (identical(_target, node.condition)) {
      return _editPlan._parensNeeded(threshold: Precedence.conditional);
    } else {
      return _editPlan._parensNeeded(threshold: Precedence.none);
    }
  }

  @override
  bool visitExtensionOverride(ExtensionOverride node) {
    assert(identical(_target, node.extensionName));
    return _editPlan._parensNeeded(
        threshold: Precedence.postfix, associative: true);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    assert(identical(_target, node.function));
    return _editPlan._parensNeeded(
        threshold: Precedence.postfix, associative: true);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    if (identical(_target, node.target)) {
      return _editPlan._parensNeeded(
          threshold: Precedence.postfix, associative: true);
    } else {
      return false;
    }
  }

  @override
  bool visitIsExpression(IsExpression node) {
    if (identical(_target, node.expression)) {
      return _editPlan._parensNeeded(threshold: Precedence.relational);
    } else {
      return false;
    }
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    // Note: it's tempting to assert identical(_target, node.target) here,
    // because in a method invocation like `x.m(...)`, the only AST node that's
    // a child of the method invocation and semantically represents an
    // expression is the target (`x` in this example).  Unfortunately, that
    // doesn't work, because even though `m` isn't semantically an expression,
    // it's represented in the analyzer AST as an identifier and Identifier
    // implements Expression.  So we have to handle both `x` and `m`.
    //
    // Fortunately we don't have to do any extra work to handle `m`, because it
    // will always be an identifier, hence it will always be high precedence and
    // it will never require parentheses.  So we just do the correct logic for
    // the target, without asserting.
    return _editPlan._parensNeeded(
        threshold: Precedence.postfix, associative: true);
  }

  @override
  bool visitNode(AstNode node) {
    return false;
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    assert(identical(_target, node.expression));
    return false;
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    assert(identical(_target, node.operand));
    return _editPlan._parensNeeded(
        threshold: Precedence.postfix, associative: true);
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(_target, node.prefix)) {
      return _editPlan._parensNeeded(
          threshold: Precedence.postfix, associative: true);
    } else {
      assert(identical(_target, node.identifier));
      return _editPlan._parensNeeded(
          threshold: Precedence.primary, associative: true);
    }
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    assert(identical(_target, node.operand));
    return _editPlan._parensNeeded(
        threshold: Precedence.prefix, associative: true);
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    if (identical(_target, node.target)) {
      return _editPlan._parensNeeded(
          threshold: Precedence.postfix, associative: true);
    } else {
      assert(identical(_target, node.propertyName));
      return _editPlan._parensNeeded(
          threshold: Precedence.primary, associative: true);
    }
  }

  @override
  bool visitThrowExpression(ThrowExpression node) {
    assert(identical(_target, node.expression));
    return _editPlan._parensNeeded(
        threshold: Precedence.assignment,
        associative: true,
        allowCascade: !_isRightmostDescendantOfCascadeSection(node));
  }

  /// Searches the ancestors of [node] to determine if it is the rightmost
  /// descendant of a cascade section.  (If this is the case, parentheses may be
  /// required).  The search is limited by [_cascadeSearchLimit].
  bool _isRightmostDescendantOfCascadeSection(AstNode node) {
    while (true) {
      var parent = node.parent;
      if (parent == null) {
        // No more ancestors, so we can stop.
        return false;
      }
      if (parent is CascadeExpression && !identical(parent.target, node)) {
        // Node is a cascade section.
        return true;
      }
      if (parent.end != node.end) {
        // Node is not the rightmost descendant of parent, so we can stop.
        return false;
      }
      if (identical(node, _cascadeSearchLimit)) {
        // We reached the cascade search limit so we don't have to look any
        // further.
        return false;
      }
      node = parent;
    }
  }
}

/// [EditPlan] representing an AstNode that is not to be changed, but may have
/// some changes applied to some of its descendants.
class _PassThroughEditPlan extends _SimpleEditPlan {
  factory _PassThroughEditPlan(AstNode node,
      {Iterable<EditPlan> innerPlans = const []}) {
    bool /*?*/ endsInCascade = node is CascadeExpression ? true : null;
    Map<int, List<AtomicEdit>> changes;
    for (var innerPlan in innerPlans) {
      innerPlan = innerPlan._incorporateParenParentIfPresent(node);
      var parensNeeded = innerPlan.parensNeededFromContext(node);
      assert(_checkParenLogic(innerPlan, parensNeeded));
      if (!parensNeeded && innerPlan is _ProvisionalParenEditPlan) {
        var innerInnerPlan = innerPlan.innerPlan;
        if (innerInnerPlan is _PassThroughEditPlan) {
          // Input source code had redundant parens, so keep them.
          parensNeeded = true;
        }
      }
      changes += innerPlan._getChanges(parensNeeded);
      if (endsInCascade == null && innerPlan.sourceNode.end == node.end) {
        endsInCascade = !parensNeeded && innerPlan.endsInCascade;
      }
    }
    return _PassThroughEditPlan._(
        node,
        node is Expression ? node.precedence : Precedence.primary,
        endsInCascade ?? node.endsInCascade,
        changes);
  }

  _PassThroughEditPlan._(AstNode node, Precedence precedence,
      bool endsInCascade, Map<int, List<AtomicEdit>> innerChanges)
      : super(node, precedence, endsInCascade, innerChanges);

  static bool _checkParenLogic(EditPlan innerPlan, bool parensNeeded) {
    if (innerPlan is _SimpleEditPlan && innerPlan._innerChanges == null) {
      assert(
          !parensNeeded,
          "Code prior to fixes didn't need parens here, "
          "shouldn't need parens now.");
    }
    return true;
  }
}

/// [EditPlan] applying to a [ParenthesizedExpression].  Unlike the normal
/// behavior of adding parentheses when needed, [_ProvisionalParenEditPlan]
/// preserves existing parens if they are needed, and removes them if they are
/// not.
///
/// Defers computation of whether parentheses are needed to the inner plan.
class _ProvisionalParenEditPlan extends _NestedEditPlan {
  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// possibly removing surrounding parentheses from the source code.
  ///
  /// Caller should not re-use [innerPlan] after this call--it (and the data
  /// structures it points to) may be incorporated into this edit plan and later
  /// modified.
  _ProvisionalParenEditPlan(ParenthesizedExpression node, EditPlan innerPlan)
      : super(node, innerPlan);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) {
    var changes = innerPlan._getChanges(false);
    if (!parens) {
      changes ??= {};
      (changes[sourceNode.offset] ??= []).insert(0, const DeleteText(1));
      (changes[sourceNode.end - 1] ??= []).add(const DeleteText(1));
    }
    return changes;
  }
}

/// [EditPlan] representing an "extraction" of an inner AST node that is
/// parenthesized, e.g. replacing `a * (b + c)` with `b + c`.
///
/// Defers computation of whether parentheses are needed to the inner plan.
class _ProvisionalParenExtractEditPlan extends _NestedEditPlan {
  _ProvisionalParenExtractEditPlan(
      AstNode sourceNode, _ProvisionalParenEditPlan innerPlan)
      : super(sourceNode, innerPlan);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) {
    var changes = innerPlan._getChanges(parens);
    return EditPlan._createExtractChanges(innerPlan, sourceNode, changes);
  }
}

/// Implementation of [EditPlan] underlying simple cases where no computation
/// needs to be deferred.
class _SimpleEditPlan extends EditPlan {
  final Precedence _precedence;

  @override
  final bool endsInCascade;

  final Map<int, List<AtomicEdit>> _innerChanges;

  bool _finalized = false;

  _SimpleEditPlan(
      AstNode node, this._precedence, this.endsInCascade, this._innerChanges)
      : super(node);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) {
    assert(!_finalized);
    _finalized = true;
    return parens ? _createAddParenChanges(_innerChanges) : _innerChanges;
  }

  @override
  bool _parensNeeded(
      {@required Precedence threshold,
      bool associative = false,
      bool allowCascade = false}) {
    if (endsInCascade && !allowCascade) return true;
    if (_precedence < threshold) return true;
    if (_precedence == threshold && !associative) return true;
    return false;
  }
}

/// Extension containing useful operations on a list of [AtomicEdit]s.
extension AtomicEditList on List<AtomicEdit> {
  /// Converts a list of [AtomicEdits] to a single [SourceEdit] by concatenating
  /// them.
  SourceEdit toSourceEdit(int offset) {
    var totalLength = 0;
    var replacement = '';
    for (var edit in this) {
      totalLength += edit.length;
      replacement += edit.replacement;
    }
    return SourceEdit(offset, totalLength, replacement);
  }
}

/// Extension containing useful operations on a map from offsets to lists of
/// [AtomicEdit]s.  This data structure is used by [EditPlans] to accumulate
/// source file changes.
extension AtomicEditMap on Map<int, List<AtomicEdit>> {
  /// Applies the changes to source file text.
  String applyTo(String code) {
    return SourceEdit.applySequence(code, toSourceEdits());
  }

  /// Converts the changes to a list of [SourceEdit]s.  The list is reverse
  /// sorted by offset so that they can be applied in order.
  List<SourceEdit> toSourceEdits() {
    return [
      for (var offset in keys.toList()..sort((a, b) => b.compareTo(a)))
        this[offset].toSourceEdit(offset)
    ];
  }

  /// Destructively combines two change representations.  If one or the other
  /// input is null, the other input is returned unchanged for efficiency.
  Map<int, List<AtomicEdit>> operator +(Map<int, List<AtomicEdit>> newChanges) {
    if (newChanges == null) return this;
    if (this == null) {
      return newChanges;
    } else {
      for (var entry in newChanges.entries) {
        var currentValue = this[entry.key];
        if (currentValue == null) {
          this[entry.key] = entry.value;
        } else {
          currentValue.addAll(entry.value);
        }
      }
      return this;
    }
  }
}

/// Extension allowing an AstNode to be queried to see if it ends in a casade
/// expression.
extension EndsInCascadeExtension on AstNode {
  @visibleForTesting
  bool get endsInCascade {
    var visitor = _EndsInCascadeVisitor(end);
    accept(visitor);
    return visitor.endsInCascade;
  }
}
