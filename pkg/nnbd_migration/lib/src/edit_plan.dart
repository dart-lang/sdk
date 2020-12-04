// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/instrumentation.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';

Map<int, List<AtomicEdit>> _removeCode(
    int offset, int end, _RemovalStyle removalStyle, AtomicEditInfo info) {
  if (offset < end) {
    // TODO(paulberry): handle preexisting comments?
    switch (removalStyle) {
      case _RemovalStyle.commentSpace:
        return {
          offset: [AtomicEdit.insert('/* ', info: info)],
          end: [AtomicEdit.insert('*/ ', info: info)]
        };
      case _RemovalStyle.delete:
        return {
          offset: [AtomicEdit.delete(end - offset, info: info)]
        };
      case _RemovalStyle.spaceComment:
        return {
          offset: [AtomicEdit.insert(' /*', info: info)],
          end: [AtomicEdit.insert(' */', info: info)]
        };
      case _RemovalStyle.spaceInsideComment:
        return {
          offset: [AtomicEdit.insert('/* ', info: info)],
          end: [AtomicEdit.insert(' */', info: info)]
        };
    }
    throw StateError('Null value for removalStyle');
  } else {
    return null;
  }
}

/// A single atomic change to a source file, decoupled from the location at
/// which the change is made. The [EditPlan] class performs its duties by
/// creating and manipulating [AtomicEdit] objects.
///
/// A list of [AtomicEdit]s may be converted to a [SourceEdit] using the
/// extension [AtomicEditList], and a map of offsets to lists of [AtomicEdit]s
/// may be converted to a list of [SourceEdit] using the extension
/// [AtomicEditMap].
///
/// May be subclassed to allow additional information to be recorded about the
/// edit.
class AtomicEdit {
  /// Additional information about this edit, or `null` if no additional
  /// information is available.
  final AtomicEditInfo info;

  /// The number of characters that should be deleted by this edit, or `0` if no
  /// characters should be deleted.
  final int length;

  /// The characters that should be inserted by this edit, or the empty string
  /// if no characters should be inserted.
  final String replacement;

  /// If `true`, this edit shouldn't actually be made to the source file; it
  /// exists merely to provide additional information to be shown in the preview
  /// tool.
  final bool isInformative;

  /// Initialize an edit to delete [length] characters.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  const AtomicEdit.delete(this.length, {this.info, this.isInformative = false})
      : assert(length > 0),
        assert(isInformative is bool),
        replacement = '';

  /// Initialize an edit to insert the [replacement] characters.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  const AtomicEdit.insert(this.replacement,
      {this.info, this.isInformative = false})
      : assert(replacement.length > 0),
        assert(isInformative is bool),
        length = 0;

  /// Initialize an edit to replace [length] characters with the [replacement]
  /// characters.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  const AtomicEdit.replace(this.length, this.replacement, {this.info})
      : assert(length > 0 || replacement.length > 0),
        isInformative = false;

  /// Return `true` if this edit is a deletion (no characters added).
  bool get isDeletion => replacement.isEmpty;

  /// Return `true` if this edit is an insertion (no characters removed).
  bool get isInsertion => length == 0;

  /// Return `true` if this edit is a replacement.
  bool get isReplacement => length > 0 && replacement.isNotEmpty;

  @override
  String toString() {
    if (isInsertion) {
      return 'InsertText(${json.encode(replacement)})';
    } else if (isDeletion) {
      return 'DeleteText($length)';
    } else {
      return 'ReplaceText($length, ${json.encode(replacement)})';
    }
  }
}

/// Information stored along with an atomic edit indicating how it arose.
class AtomicEditInfo {
  /// A description of the change that was made.
  final NullabilityFixDescription description;

  /// The reasons for the edit.
  final Map<FixReasonTarget, FixReasonInfo> fixReasons;

  /// If the edit is being made due to a hint, the hint in question; otherwise
  /// `null`.
  final HintComment hintComment;

  AtomicEditInfo(this.description, this.fixReasons, {this.hintComment});
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
  EditPlan._();

  /// Returns the "parent" of the node edited by this [EditPlan].  For edit
  /// plans that replace one AST node with another, this is the parent of the
  /// AST node being replaced.  For edit plans that insert or delete AST nodes,
  /// this is the parent of the AST nodes that will be inserted or deleted.
  AstNode get parentNode;
}

/// Factory class for creating [EditPlan]s.
class EditPlanner {
  /// Indicates whether code removed by the EditPlanner should be removed by
  /// commenting it out.  A value of `false` means to actually delete the code
  /// that is removed.
  final bool removeViaComments;

  /// The line info for the source file being edited.  This is used when
  /// removing statements that fill one or more lines, so that we can remove
  /// the indentation as well as the statement, and avoid leaving behind ugly
  /// whitespace.
  final LineInfo lineInfo;

  /// The text of the source file being edited.  This is used when removing
  /// code, so that we can figure out if it is safe to remove adjoining
  /// whitespace.
  final String sourceText;

  EditPlanner(this.lineInfo, this.sourceText, {this.removeViaComments = false});

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// converting the late [hint] into an explicit `late`.
  NodeProducingEditPlan acceptLateHint(
      NodeProducingEditPlan innerPlan, HintComment hint,
      {AtomicEditInfo info}) {
    var affixPlan = innerPlan is _CommentAffixPlan
        ? innerPlan
        : _CommentAffixPlan(innerPlan);
    var changes = hint.changesToAccept(sourceText, info: info);
    assert(affixPlan.offset >= _endForChanges(changes));
    affixPlan.offset = _offsetForChanges(changes);
    affixPlan._prefixChanges = changes + affixPlan._prefixChanges;
    return affixPlan;
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// converting the nullability [hint] into an explicit `?` or `!`.
  NodeProducingEditPlan acceptNullabilityOrNullCheckHint(
      NodeProducingEditPlan innerPlan, HintComment hint,
      {AtomicEditInfo info}) {
    var affixPlan = innerPlan is _CommentAffixPlan
        ? innerPlan
        : _CommentAffixPlan(innerPlan);
    var changes = hint.changesToAccept(sourceText);
    assert(affixPlan.end <= _offsetForChanges(changes));
    affixPlan.end = _endForChanges(changes);
    affixPlan._postfixChanges += hint.changesToAccept(sourceText, info: info);
    return affixPlan;
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// appending the given [operand], with an intervening binary [operator].
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  NodeProducingEditPlan addBinaryPostfix(
      NodeProducingEditPlan innerPlan, TokenType operator, String operand,
      {AtomicEditInfo info}) {
    assert(innerPlan.sourceNode is Expression);
    var precedence = Precedence.forTokenType(operator);
    var isAssociative = precedence != Precedence.relational &&
        precedence != Precedence.equality &&
        precedence != Precedence.assignment;
    return surround(innerPlan,
        suffix: [AtomicEdit.insert(' ${operator.lexeme} $operand', info: info)],
        outerPrecedence: precedence,
        innerPrecedence: precedence,
        associative: isAssociative);
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// prepending the given [operand], with an intervening binary [operator].
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  ///
  /// If the expression represented by [operand] is known not to end in a
  /// cascade expression, caller may optionally set [allowCascade] to `true` to
  /// prevent a rare corner case where parentheses would be added unnecessarily.
  /// Note that it is always safe to leave [allowCascade] at its default value
  /// of `false`.
  NodeProducingEditPlan addBinaryPrefix(
      String operand, TokenType operator, NodeProducingEditPlan innerPlan,
      {AtomicEditInfo info, bool allowCascade = false}) {
    assert(innerPlan.sourceNode is Expression);
    var precedence = Precedence.forTokenType(operator);
    var isAssociative = precedence == Precedence.assignment;
    return surround(innerPlan,
        prefix: [AtomicEdit.insert('$operand ${operator.lexeme} ', info: info)],
        outerPrecedence: precedence,
        innerPrecedence: precedence,
        associative: isAssociative,
        allowCascade: allowCascade);
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// appending the given [comment]].
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  ///
  /// Optional argument [isInformative] indicates whether the comment is simply
  /// informative, or should actually be applied to the final output (the
  /// default).
  NodeProducingEditPlan addCommentPostfix(
      NodeProducingEditPlan innerPlan, String comment,
      {AtomicEditInfo info, bool isInformative = false}) {
    var end = innerPlan.end;
    return surround(innerPlan, suffix: [
      AtomicEdit.insert(' ', isInformative: isInformative),
      AtomicEdit.insert(comment, info: info, isInformative: isInformative),
      if (!_isJustBefore(end, const [')', ']', '}', ';']) &&
          !_isJustBeforeWhitespace(end))
        AtomicEdit.insert(' ', isInformative: isInformative)
    ]);
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// appending the given postfix [operator].  This could be used, for example,
  /// to add a null check.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  NodeProducingEditPlan addUnaryPostfix(
      NodeProducingEditPlan innerPlan, TokenType operator,
      {AtomicEditInfo info}) {
    assert(innerPlan.sourceNode is Expression);
    return surround(innerPlan,
        suffix: [AtomicEdit.insert(operator.lexeme, info: info)],
        outerPrecedence: Precedence.postfix,
        innerPrecedence: Precedence.postfix,
        associative: true);
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// prepending the given prefix [operator].
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  NodeProducingEditPlan addUnaryPrefix(
      TokenType operator, NodeProducingEditPlan innerPlan,
      {AtomicEditInfo info}) {
    assert(innerPlan.sourceNode is Expression);
    return surround(innerPlan,
        prefix: [AtomicEdit.insert(operator.lexeme, info: info)],
        outerPrecedence: Precedence.prefix,
        innerPrecedence: Precedence.prefix,
        associative: true);
  }

  /// Creates a [_PassThroughBuilder] object based around [node].
  ///
  /// Exposed so that we can substitute a mock class in unit tests.
  @visibleForTesting
  PassThroughBuilder createPassThroughBuilder(AstNode node) =>
      _PassThroughBuilderImpl(node);

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// dropping the given nullability [hint].
  NodeProducingEditPlan dropNullabilityHint(
      NodeProducingEditPlan innerPlan, HintComment hint,
      {AtomicEditInfo info}) {
    var affixPlan = innerPlan is _CommentAffixPlan
        ? innerPlan
        : _CommentAffixPlan(innerPlan);
    var changes = hint.changesToRemove(sourceText, info: info);
    assert(affixPlan.end <= _offsetForChanges(changes));
    affixPlan.end = _endForChanges(changes);
    affixPlan._postfixChanges += changes;
    return affixPlan;
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// appending an informative ` `, to illustrate that the type is non-nullable.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  NodeProducingEditPlan explainNonNullable(NodeProducingEditPlan innerPlan,
      {AtomicEditInfo info}) {
    assert(innerPlan.sourceNode is TypeAnnotation);
    return surround(innerPlan,
        suffix: [AtomicEdit.insert(' ', info: info, isInformative: true)]);
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// removing from the source code any code that is in [sourceNode] but not in
  /// [innerPlan.sourceNode].  This is intended to be used to drop unnecessary
  /// syntax (for example, to drop an unnecessary cast).
  ///
  /// If no changes are required to the AST node that is being extracted, the
  /// caller may create innerPlan using [EditPlan.passThrough].
  ///
  /// Optional parameters [infoBefore] and [infoAfter] contain information about
  /// why the change was made.  The reason there are two of these parameters is
  /// because in general, two chunks of source code will be removed: the code
  /// coming before [innerPlan.sourceNode] and the code coming after it.
  ///
  /// [innerPlan] will be finalized as a side effect (either immediately or when
  /// the newly created plan is finalized), so it should not be re-used by the
  /// caller.
  NodeProducingEditPlan extract(
      AstNode sourceNode, NodeProducingEditPlan innerPlan,
      {AtomicEditInfo infoBefore,
      AtomicEditInfo infoAfter,
      bool alwaysDelete = false}) {
    var parent = innerPlan.sourceNode.parent;
    if (!identical(parent, sourceNode) && parent is ParenthesizedExpression) {
      innerPlan = _ProvisionalParenEditPlan(parent, innerPlan);
    }
    return _ExtractEditPlan(
        sourceNode, innerPlan, this, infoBefore, infoAfter, alwaysDelete);
  }

  /// Converts [plan] to a representation of the concrete edits that need
  /// to be made to the source file.  These edits may be converted into
  /// [SourceEdit]s using the extensions [AtomicEditList] and [AtomicEditMap].
  ///
  /// Finalizing an [EditPlan] is a destructive operation; it should not be used
  /// again after it is finalized.
  Map<int, List<AtomicEdit>> finalize(EditPlan plan) {
    // Convert to a plan for the top level CompilationUnit.
    var parent = plan.parentNode;
    if (parent != null) {
      var unit = parent.thisOrAncestorOfType<CompilationUnit>();
      plan = passThrough(unit, innerPlans: [plan]);
    }
    // The plan for a compilation unit should always be a NodeProducingEditPlan.
    // So we can just ask it for its changes.
    return (plan as NodeProducingEditPlan)._getChanges(false);
  }

  /// Creates a new edit plan that adds an informative message to the given
  /// [token].
  ///
  /// The created edit plan should be inserted into the list of inner plans for
  /// a pass-through plan targeted at the [containingNode].  See [passThrough].
  EditPlan informativeMessageForToken(AstNode containingNode, Token token,
      {AtomicEditInfo info}) {
    return _TokenChangePlan(containingNode, {
      token.offset: [
        AtomicEdit.delete(token.lexeme.length, info: info, isInformative: true)
      ]
    });
  }

  /// Creates a new edit plan that inserts the text indicated by [edits] at the
  /// given [offset].
  ///
  /// The created edit will have the given [parentNode].  In general this should
  /// be the innermost AST node containing the given [offset].
  EditPlan insertText(AstNode parentNode, int offset, List<AtomicEdit> edits) {
    assert(!edits.any((edit) => !edit.isInsertion),
        'All edits should be insertions');
    return _TokenChangePlan(parentNode, {offset: edits});
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// appending a `?`, to make a type nullable.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  NodeProducingEditPlan makeNullable(NodeProducingEditPlan innerPlan,
      {AtomicEditInfo info}) {
    var sourceNode = innerPlan.sourceNode;
    assert(sourceNode is TypeAnnotation ||
        sourceNode is FunctionTypedFormalParameter ||
        (sourceNode is FieldFormalParameter && sourceNode.parameters != null));
    return surround(innerPlan, suffix: [AtomicEdit.insert('?', info: info)]);
  }

  /// Creates a new edit plan that makes no changes to [node], but may make
  /// changes to some of its descendants (specified via [innerPlans]).
  ///
  /// Note that the [innerPlans] must be specified in document order.
  ///
  /// All plans in [innerPlans] will be finalized as a side effect (either
  /// immediately or when the newly created plan is finalized), so they should
  /// not be re-used by the caller.
  NodeProducingEditPlan passThrough(AstNode node,
      {Iterable<EditPlan> innerPlans = const []}) {
    // It's possible that some of the inner plans are nested more deeply within
    // [node] than others.  We want to group these inner plans together into
    // pass through plans at each level in the AST until we bubble up to [node].
    // To do so, we form a stack of [_PassThroughBuilder] objects to handle each
    // level of AST depth, where the first entry in the stack corresponds to
    // [node], and each subsequent entry will correspond to a child of the
    // previous.
    var builderStack = [createPassThroughBuilder(node)];
    var ancestryPath = <AstNode>[];
    for (var plan in innerPlans) {
      // Compute the ancestryPath (the path from `plan.parentNode` up to
      // `node`).  Note that whereas builderStack walks stepwise down the AST,
      // ancestryStack will walk stepwise up the AST, with the last entry of
      // ancestryStack corresponding to the first entry of builderStack.  We
      // re-use the same list for each loop iteration to reduce GC load.
      ancestryPath.clear();
      for (var parent = plan.parentNode;
          !identical(parent, node);
          parent = parent.parent) {
        ancestryPath.add(parent);
      }
      ancestryPath.add(node);
      // Find the deepest entry in builderStack that's on the ancestryPath.
      var builderIndex = _findMatchingBuilder(builderStack, ancestryPath);
      // We're finished with all builders beyond that entry.
      while (builderStack.length > builderIndex + 1) {
        var passThrough = builderStack.removeLast().finish(this);
        builderStack.last.add(passThrough);
      }
      // And we may need to add new builders to make our way down to
      // `plan.parentNode`.
      while (builderStack.length < ancestryPath.length) {
        // Since builderStack and ancestryPath walk in different directions
        // through the AST, when building entry builderIndex, we need to count
        // backwards from the end of ancestryPath to figure out which node to
        // associate the builder with.
        builderStack.add(createPassThroughBuilder(
            ancestryPath[ancestryPath.length - builderStack.length - 1]));
      }
      // Now the deepest entry in the builderStack corresponds to
      // `plan.parentNode`, so we can add the plan to it.
      builderStack.last.add(plan);
    }
    // We're now finished with all builders.
    while (true) {
      var passThrough = builderStack.removeLast().finish(this);
      if (builderStack.isEmpty) return passThrough;
      builderStack.last.add(passThrough);
    }
  }

  /// Creates a new edit plan that removes [sourceNode] from the AST.
  ///
  /// [sourceNode] must be one element of a variable length sequence maintained
  /// by [sourceNode]'s parent (for example, a statement in a block, an element
  /// in a list, a declaration in a class, etc.).  If it is not, an exception is
  /// thrown.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  EditPlan removeNode(AstNode sourceNode, {AtomicEditInfo info}) {
    var result = tryRemoveNode(sourceNode, info: info);
    if (result == null) {
      var parent = sourceNode.parent;
      throw StateError(
          'Cannot remove node whose parent is of type ${parent.runtimeType}');
    }
    return result;
  }

  /// Creates a new edit plan that removes a sequence of adjacent nodes from
  /// the AST, starting with [firstSourceNode] and ending with [lastSourceNode].
  ///
  /// [firstSourceNode] and [lastSourceNode] must be elements of a variable
  /// length sequence maintained by their (common) parent (for example,
  /// statements in a block, elements in a list, declarations in a class, etc.)
  /// [lastSourceNode] must come after [firstSourceNode].
  ///
  /// If [firstSourceNode] and [lastSourceNode] are the same node, then the
  /// behavior is identical to [removeNode] (i.e. just the one node is removed).
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  EditPlan removeNodes(AstNode firstSourceNode, AstNode lastSourceNode,
      {AtomicEditInfo info}) {
    var parent = firstSourceNode.parent;
    assert(identical(lastSourceNode.parent, parent));
    var sequenceNodes = _computeSequenceNodes(parent);
    if (sequenceNodes == null) {
      throw StateError(
          'Cannot remove node whose parent is of type ${parent.runtimeType}');
    }
    var firstIndex = sequenceNodes.indexOf(firstSourceNode);
    assert(firstIndex != -1);
    var lastIndex = sequenceNodes.indexOf(lastSourceNode, firstIndex);
    assert(lastIndex >= firstIndex);
    return _RemoveEditPlan(parent, firstIndex, lastIndex, info);
  }

  /// Creates a new edit plan that removes null awareness from [sourceNode].
  ///
  /// The created edit plan should be inserted into the list of inner plans for
  /// a pass-through plan targeted at the source node.  See [passThrough].
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  ///
  /// Optional argument [isInformative] indicates whether the comment is simply
  /// informative, or should actually be applied to the final output (the
  /// default).
  EditPlan removeNullAwareness(Expression sourceNode,
      {AtomicEditInfo info, bool isInformative = false}) {
    Token operator;
    if (sourceNode is MethodInvocation) {
      operator = sourceNode.operator;
    } else if (sourceNode is PropertyAccess) {
      operator = sourceNode.operator;
    } else {
      throw StateError(
          'Tried to remove null awareness from an unexpected node type: '
          '${sourceNode.runtimeType}');
    }
    assert(operator.type == TokenType.QUESTION_PERIOD);
    return _TokenChangePlan(sourceNode, {
      operator.offset: [
        AtomicEdit.delete(1, info: info, isInformative: isInformative)
      ]
    });
  }

  /// Creates a new edit plan that replaces the contents of [sourceNode] with
  /// the given [replacement] text.
  ///
  /// If the edit plan is going to be used in a context where an expression is
  /// expected, additional arguments should be provided to control the behavior
  /// of parentheses insertion and deletion: [precedence] indicates the
  /// precedence of the resulting expression.  [endsInCascade] indicates whether
  /// the resulting plan will end in a cascade.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  NodeProducingEditPlan replace(
      AstNode sourceNode, List<AtomicEdit> replacement,
      {Precedence precedence = Precedence.primary,
      bool endsInCascade = false,
      AtomicEditInfo info}) {
    assert(!replacement.any((edit) => !edit.isInsertion),
        'All edits should be insertions');
    return _SimpleEditPlan(sourceNode, precedence, endsInCascade, {
      sourceNode.offset: [
        AtomicEdit.delete(sourceNode.length, info: info),
        ...replacement
      ]
    });
  }

  /// Creates a new edit plan that replaces [token] with the given [replacement]
  /// text.
  ///
  /// [parentNode] should be the innermost AST node containing [token].
  EditPlan replaceToken(AstNode parentNode, Token token, String replacement,
      {AtomicEditInfo info}) {
    return _TokenChangePlan(parentNode, {
      token.offset: [AtomicEdit.replace(token.length, replacement, info: info)]
    });
  }

  /// Creates a new edit plan that consists of executing [innerPlan], and then
  /// surrounding it with [prefix] and [suffix] text.  This could be used, for
  /// example, to add a cast.
  ///
  /// Note that it's tricky to get precedence correct.  When possible, use one
  /// of the other methods in this class, such as [addBinaryPostfix],
  /// [addBinaryPrefix], [addUnaryPostfix], or [addUnaryPrefix].
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
  NodeProducingEditPlan surround(NodeProducingEditPlan innerPlan,
      {List<AtomicEdit> prefix,
      List<AtomicEdit> suffix,
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
      (innerChanges[innerPlan.offset] ??= []).insertAll(0, prefix);
    }
    if (suffix != null) {
      (innerChanges[innerPlan.end] ??= []).addAll(suffix);
    }
    return _SimpleEditPlan(
        innerPlan.sourceNode,
        outerPrecedence,
        suffix == null
            ? innerPlan.endsInCascade && !parensNeeded
            : endsInCascade,
        innerChanges);
  }

  /// Tries to create a new edit plan that removes [node] from the AST.
  ///
  /// [node] must be one element of a variable length sequence maintained by
  /// [node]'s parent (for example, a statement in a block, an element in a
  /// list, a declaration in a class, etc.).  If it is not, `null` is returned.
  ///
  /// Optional argument [info] contains information about why the change was
  /// made.
  EditPlan tryRemoveNode(AstNode sourceNode,
      {List<AstNode> sequenceNodes, AtomicEditInfo info}) {
    var parent = sourceNode.parent;
    sequenceNodes ??= _computeSequenceNodes(parent);
    if (sequenceNodes == null) {
      return null;
    }
    var index = sequenceNodes.indexOf(sourceNode);
    assert(index != -1);
    return _RemoveEditPlan(parent, index, index, info);
  }

  /// Walks backward through the source text, starting at [offset] and stopping
  /// before passing any non-whitespace character.
  ///
  /// Does not walk further than [limit] (which should be less than or equal to
  /// [offset]).
  int _backAcrossWhitespace(int offset, int limit) {
    assert(limit <= offset);
    return limit + sourceText.substring(limit, offset).trimRight().length;
  }

  /// Walks backward through the source text, starting at [offset] and stopping
  /// when the beginning of the line is reached.
  ///
  /// If [offset] is at the beginning of the line, it is returned unchanged.
  int _backToLineStart(int offset) {
    var lineNumber = lineInfo.getLocation(offset).lineNumber;
    // lineNumber is one-based, but lineInfo.lineStarts expects a zero-based
    // index, so we need `lineInfo.lineStarts[lineNumber - 1]`.
    return lineInfo.lineStarts[lineNumber - 1];
  }

  int _endForChanges(Map<int, List<AtomicEdit>> changes) {
    int result;
    for (var entry in changes.entries) {
      var end = entry.key;
      for (var edit in entry.value) {
        end += edit.length;
      }
      if (result == null || end > result) result = end;
    }
    return result;
  }

  /// Finds the deepest entry in [builderStack] that matches an entry in
  /// [ancestryStack], taking advantage of the fact that [builderStack] walks
  /// stepwise down the AST, and [ancestryStack] walks stepwise up the AST, with
  /// the last entry of [ancestryStack] corresponding to the first entry of
  /// [builderStack].
  int _findMatchingBuilder(
      List<PassThroughBuilder> builderStack, List<AstNode> ancestryStack) {
    var builderIndex = builderStack.length - 1;
    while (builderIndex > 0) {
      var ancestryIndex = ancestryStack.length - builderIndex - 1;
      if (ancestryIndex >= 0 &&
          identical(
              builderStack[builderIndex].node, ancestryStack[ancestryIndex])) {
        break;
      }
      --builderIndex;
    }
    return builderIndex;
  }

  /// Walks forward through the source text, starting at [offset] and stopping
  /// before passing any non-whitespace character.
  ///
  /// Does not walk further than [limit] (which should be greater than or equal
  /// to [offset]).
  int _forwardAcrossWhitespace(int offset, int limit) {
    return limit - sourceText.substring(offset, limit).trimLeft().length;
  }

  /// Walks forward through the source text, starting at [offset] and stopping
  /// at the beginning of the next line (or at the end of the document, if this
  /// line is the last line).
  int _forwardToLineEnd(int offset) {
    int lineNumber = lineInfo.getLocation(offset).lineNumber;
    // lineNumber is one-based, so if it is equal to
    // `lineInfo.lineStarts.length`, then we are on the last line.
    if (lineNumber >= lineInfo.lineStarts.length) {
      return sourceText.length;
    }
    // lineInfo.lineStarts expects a zero-based index, so
    // `lineInfo.lineStarts[lineNumber]` gives us the beginning of the next
    // line.
    return lineInfo.lineStarts[lineNumber];
  }

  /// Determines whether the given source [offset] comes just after one of the
  /// characters in [characters].
  bool _isJustAfter(int offset, List<String> characters) =>
      offset > 0 && characters.contains(sourceText[offset - 1]);

  /// Determines whether the given source [end] comes just before one of the
  /// characters in [characters].
  bool _isJustBefore(int end, List<String> characters) =>
      end < sourceText.length && characters.contains(sourceText[end]);

  /// Determines whether the given source [end] comes just before whitespace.
  /// For the purpose of this check, the end of the file is considered
  /// whitespace.
  bool _isJustBeforeWhitespace(int end) =>
      end >= sourceText.length || _isWhitespaceRange(end, end + 1);

  /// Determines if the characters between [offset] and [end] in the source text
  /// are all whitespace characters.
  bool _isWhitespaceRange(int offset, int end) {
    return sourceText.substring(offset, end).trimRight().isEmpty;
  }

  int _offsetForChanges(Map<int, List<AtomicEdit>> changes) {
    int result;
    for (var key in changes.keys) {
      if (result == null || key < result) result = key;
    }
    return result;
  }

  /// If the given [node] maintains a variable-length sequence of child nodes,
  /// returns a list containing those child nodes, otherwise returns `null`.
  ///
  /// The returned list may or may not be the exact list used by the node to
  /// maintain its child nodes.  For example, [CompilationUnit] maintains its
  /// directives and declarations in separate lists, so the returned list is
  /// a new list containing both directives and declarations.
  static List<AstNode> _computeSequenceNodes(AstNode node) {
    if (node is Block) {
      return node.statements;
    } else if (node is ListLiteral) {
      return node.elements;
    } else if (node is SetOrMapLiteral) {
      return node.elements;
    } else if (node is ArgumentList) {
      return node.arguments;
    } else if (node is FormalParameter) {
      return node.metadata;
    } else if (node is FormalParameterList) {
      return node.parameters;
    } else if (node is VariableDeclarationList) {
      return node.variables;
    } else if (node is TypeArgumentList) {
      return node.arguments;
    } else if (node is TypeParameterList) {
      return node.typeParameters;
    } else if (node is EnumDeclaration) {
      return node.constants;
    } else if (node is ClassDeclaration) {
      return node.members;
    } else if (node is CompilationUnit) {
      return [...node.directives, ...node.declarations];
    } else {
      return null;
    }
  }
}

/// Specialization of [EditPlan] for the situation where the text being produced
/// represents a single expression (i.e. an expression, statement, class
/// declaration, etc.)
abstract class NodeProducingEditPlan extends EditPlan {
  /// The AST node to which the edit plan applies.
  final AstNode sourceNode;

  NodeProducingEditPlan._(this.sourceNode) : super._();

  /// Offset just past the end of the source text affected by this plan.
  int get end => sourceNode.end;

  /// If the result of executing this [EditPlan] will be an expression,
  /// indicates whether the expression will end in an unparenthesized cascade.
  @visibleForTesting
  bool get endsInCascade;

  /// Offset of the start of the source text affected by this plan.
  int get offset => sourceNode.offset;

  @override
  AstNode get parentNode => sourceNode.parent;

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
    (changes[offset] ??= []).insert(0, const AtomicEdit.insert('('));
    (changes[end] ??= []).add(const AtomicEdit.insert(')'));
    return changes;
  }

  /// Computes the necessary set of [changes] for this [EditPlan], either
  /// including or not including parentheses depending on the value of [parens].
  ///
  /// An [EditPlan] for which [_getChanges] has been called is considered to be
  /// finalized.
  Map<int, List<AtomicEdit>> _getChanges(bool parens);

  /// Determines if the text that would be produced by [EditPlan] needs to be
  /// surrounded by parens, based on the context in which it will be used.
  bool _parensNeeded(
      {@required Precedence threshold,
      bool associative = false,
      bool allowCascade = false});
}

/// Data structure that accumulates together a set of [EditPlans] sharing a
/// common parent node, and groups them together into an [EditPlan] with a
/// parent node one level up the AST.
@visibleForTesting
abstract class PassThroughBuilder {
  /// The AST node that is the parent of all the [EditPlan]s being accumulated.
  AstNode get node;

  /// Accumulate another edit plan.
  void add(EditPlan innerPlan);

  /// Called when no more edit plans need to be added.  Returns the final
  /// [EditPlan].
  NodeProducingEditPlan finish(EditPlanner planner);
}

/// [EditPlan] that wraps an inner plan with optional prefix and suffix changes.
class _CommentAffixPlan extends _NestedEditPlan {
  Map<int, List<AtomicEdit>> _prefixChanges;

  Map<int, List<AtomicEdit>> _postfixChanges;

  @override
  int offset;

  @override
  int end;

  _CommentAffixPlan(NodeProducingEditPlan innerPlan)
      : offset = innerPlan.offset,
        end = innerPlan.end,
        super(innerPlan.sourceNode, innerPlan);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) =>
      _prefixChanges + innerPlan._getChanges(parens) + _postfixChanges;
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
  final EditPlanner _planner;

  final AtomicEditInfo _infoBefore;

  final AtomicEditInfo _infoAfter;

  /// Whether text-to-be-removed should be removed (as opposed to commented out)
  /// even when [EditPlan.removeViaComments] is true.
  final bool _alwaysDelete;

  _ExtractEditPlan(AstNode sourceNode, NodeProducingEditPlan innerPlan,
      this._planner, this._infoBefore, this._infoAfter, this._alwaysDelete)
      : super(sourceNode, innerPlan);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) {
    // Get the inner changes.  If they already have provisional parens and we
    // need them, use them.
    var useInnerParens = parens && innerPlan is _ProvisionalParenEditPlan;
    var changes = innerPlan._getChanges(useInnerParens);
    // TODO(paulberry): don't remove comments
    _RemovalStyle leadingChangeRemovalStyle;
    _RemovalStyle trailingChangeRemovalStyle;
    if (_alwaysDelete || !_planner.removeViaComments) {
      leadingChangeRemovalStyle = _RemovalStyle.delete;
      trailingChangeRemovalStyle = _RemovalStyle.delete;
    } else {
      leadingChangeRemovalStyle = _RemovalStyle.commentSpace;
      trailingChangeRemovalStyle = _RemovalStyle.spaceComment;
    }
    // Extract the inner expression.
    changes = _removeCode(
            offset, innerPlan.offset, leadingChangeRemovalStyle, _infoBefore) +
        changes +
        _removeCode(innerPlan.end, end, trailingChangeRemovalStyle, _infoAfter);
    // Apply parens if needed.
    if (parens && !useInnerParens) {
      changes = _createAddParenChanges(changes);
    }
    return changes;
  }
}

/// [EditPlan] representing additional edits performed on the result of a
/// previous [innerPlan].
///
/// By default, defers computation of whether parentheses are needed to the
/// inner plan.
abstract class _NestedEditPlan extends NodeProducingEditPlan {
  final NodeProducingEditPlan innerPlan;

  _NestedEditPlan(AstNode sourceNode, this.innerPlan) : super._(sourceNode);

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
  final NodeProducingEditPlan _editPlan;

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

class _PassThroughBuilderImpl implements PassThroughBuilder {
  @override
  final AstNode node;

  /// The [EditPlan]s accumulated so far.
  final List<EditPlan> innerPlans = [];

  /// The [EditPlanner] currently being used to create this
  /// [_PassThroughEditPlan].
  EditPlanner planner;

  /// Determination of whether the resulting [EditPlan] will end in a cascade,
  /// or `null` if it is not yet known.
  bool endsInCascade;

  /// The set of changes aggregated together so far.
  Map<int, List<AtomicEdit>> changes;

  /// If [node] is a sequence, the list of its child nodes.  Otherwise `null`.
  List<AstNode> sequenceNodes;

  /// If [node] is a sequence that uses separators (e.g. a list literal, which
  /// uses comma separators), a list of its separators.  Otherwise `null`.
  List<Token> separators;

  /// If [separators] is non-null, and nodes are being removed from the
  /// sequence, this boolean indicates whether each node should be removed along
  /// with the separator that *precedes* it.
  ///
  /// `false` indicates that each node should be removed along with the
  /// separator that *follows* it.
  bool removeLeadingSeparators = false;

  _PassThroughBuilderImpl(this.node);

  @override
  void add(EditPlan innerPlan) {
    assert(identical(innerPlan.parentNode, node));
    innerPlans.add(innerPlan);
  }

  @override
  NodeProducingEditPlan finish(EditPlanner planner) {
    this.planner = planner;
    var node = this.node;
    if (node is ParenthesizedExpression) {
      assert(innerPlans.length <= 1);
      var innerPlan = innerPlans.isEmpty
          ? planner.passThrough(node.expression)
          : innerPlans[0];
      if (innerPlan is NodeProducingEditPlan) {
        return _ProvisionalParenEditPlan(node, innerPlan);
      }
    }

    // Make a provisional determination of whether the result will end in a
    // cascade.
    // TODO(paulberry): can we make some of these computations lazy?
    endsInCascade = node is CascadeExpression ? true : null;
    sequenceNodes = EditPlanner._computeSequenceNodes(node);
    separators =
        sequenceNodes == null ? null : _computeSeparators(node, sequenceNodes);
    _processPlans();
    Precedence precedence;
    if (node is FunctionExpression && node.body is ExpressionFunctionBody) {
      // To avoid ambiguities when adding `as Type` after a function expression,
      // assume assignment precedence.
      // TODO(paulberry): this is a hack - see
      // https://github.com/dart-lang/sdk/issues/40536
      precedence = Precedence.assignment;
    } else if (node is Expression) {
      precedence = node.precedence;
    } else {
      precedence = Precedence.primary;
    }
    return _PassThroughEditPlan._(
        node, precedence, endsInCascade ?? node.endsInCascade, changes);
  }

  /// Starting at index [planIndex] of [innerPlans] (whose value is [plan]),
  /// scans forward to see if there is a range of inner plans that remove a
  /// contiguous range of AST nodes.
  ///
  /// Returns the index into [innerPlans] of the last such contiguous plan, or
  /// [planIndex] if a contiguous range of removals wasn't found.
  int _findConsecutiveRemovals(int planIndex, _RemoveEditPlan plan) {
    assert(identical(innerPlans[planIndex], plan));
    var lastRemovePlanIndex = planIndex;
    var lastRemoveEditPlan = plan;
    while (lastRemovePlanIndex + 1 < innerPlans.length) {
      var nextPlan = innerPlans[lastRemovePlanIndex + 1];
      if (nextPlan is _RemoveEditPlan) {
        if (nextPlan.firstChildIndex == lastRemoveEditPlan.lastChildIndex + 1) {
          // Removals are consecutive.  Slurp up.
          lastRemovePlanIndex++;
          lastRemoveEditPlan = nextPlan;
          continue;
        }
      }
      break;
    }
    return lastRemovePlanIndex;
  }

  /// Processes an inner plan of type [NodeProducingEditPlan].
  void _handleNodeProducingEditPlan(NodeProducingEditPlan innerPlan) {
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
    // Note: we use innerPlan.sourceNode.end here instead of innerPlan.end,
    // because what we care about is the input grammar, so we don't want to be
    // fooled by any whitespace or comments included in the innerPlan.
    if (endsInCascade == null && innerPlan.sourceNode.end == node.end) {
      endsInCascade = !parensNeeded && innerPlan.endsInCascade;
    }
  }

  /// Processes one or more inner plans of type [_RemoveEditPlan], and returns
  /// an updated [planIndex] pointing to the next inner plan to be processed.
  ///
  /// [firstPlan] should be the plan located at index [planIndex].
  int _handleRemoveEditPlans(_RemoveEditPlan firstPlan, int planIndex) {
    assert(identical(innerPlans[planIndex], firstPlan));
    assert(identical(firstPlan.parentNode, node));
    var firstPlanIndex = planIndex;
    var lastPlanIndex = _findConsecutiveRemovals(firstPlanIndex, firstPlan);
    var lastPlan = innerPlans[lastPlanIndex] as _RemoveEditPlan;
    int lastRemovalEnd;
    int nextRemovalOffset;
    removeLeadingSeparators = separators != null &&
        firstPlan.firstChildIndex != 0 &&
        lastPlan.lastChildIndex >= separators.length;
    if (planner.removeViaComments) {
      nextRemovalOffset = _removalOffset(firstPlan);
      lastRemovalEnd = _removalEnd(lastPlan);
    } else {
      var firstRemovalOffset = _removalOffset(firstPlan);
      var firstLineStart = planner._backToLineStart(firstRemovalOffset);
      var startsOnLineBoundary =
          planner._isWhitespaceRange(firstLineStart, firstRemovalOffset);
      lastRemovalEnd = _removalEnd(lastPlan);
      var lastLineEnd = planner._forwardToLineEnd(lastRemovalEnd);
      var endsOnLineBoundary =
          planner._isWhitespaceRange(lastRemovalEnd, lastLineEnd);
      if (!endsOnLineBoundary) {
        // E.g. removing B and C, and possibly A, from `A; B; C; D;`.  Want to
        // remove the whitespace after `C;`.
        lastRemovalEnd =
            planner._forwardAcrossWhitespace(lastRemovalEnd, lastLineEnd);
      } else if (!startsOnLineBoundary) {
        // E.g. removing B and C from `A; B; C;`.  Want to remove the whitespace
        // before `B`.
        firstRemovalOffset =
            planner._backAcrossWhitespace(firstRemovalOffset, firstLineStart);
      } else {
        // Removing whole lines.
        firstRemovalOffset = firstLineStart;
        lastRemovalEnd = lastLineEnd;
      }
      if (firstPlanIndex == 0 && lastPlanIndex == sequenceNodes.length - 1) {
        // We're removing everything.  Try to remove additional whitespace so
        // that we're left with just `()`, `{}`, or `[]`.
        var candidateFirstRemovalOffset =
            planner._backAcrossWhitespace(firstRemovalOffset, node.offset);
        if (planner
            ._isJustAfter(candidateFirstRemovalOffset, const ['(', '[', '{'])) {
          var candidateLastRemovalEnd =
              planner._forwardAcrossWhitespace(lastRemovalEnd, node.end);
          if (planner
              ._isJustBefore(candidateLastRemovalEnd, const [')', ']', '}'])) {
            firstRemovalOffset = candidateFirstRemovalOffset;
            lastRemovalEnd = candidateLastRemovalEnd;
          }
        }
      }
      nextRemovalOffset = firstRemovalOffset;
    }

    for (; planIndex <= lastPlanIndex; planIndex++) {
      var innerPlan = innerPlans[planIndex] as _RemoveEditPlan;
      var offset = nextRemovalOffset;
      int end;
      if (planIndex == lastPlanIndex) {
        end = lastRemovalEnd;
      } else {
        var nextInnerPlan = innerPlans[planIndex + 1] as _RemoveEditPlan;
        assert(identical(nextInnerPlan.parentNode, node));
        nextRemovalOffset = _removalOffset(nextInnerPlan);
        if (planner.removeViaComments) {
          end = _removalEnd(innerPlans[planIndex] as _RemoveEditPlan);
        } else {
          var lineStart = planner._backToLineStart(nextRemovalOffset);
          if (planner._isWhitespaceRange(lineStart, nextRemovalOffset)) {
            // The next node to remove starts at the beginning of a line
            // (possibly with whitespace before it).  Consider the removal of
            // the whitespace to be part of removing the next node.
            nextRemovalOffset = lineStart;
          }
          end = nextRemovalOffset;
        }
      }
      changes += _removeCode(
          offset,
          end,
          planner.removeViaComments
              ? _RemovalStyle.spaceInsideComment
              : _RemovalStyle.delete,
          innerPlan.info);
    }

    return planIndex;
  }

  /// Walks through the plans in [innerPlans], adjusting them as necessary and
  /// collecting their changes in [changes].
  void _processPlans() {
    int planIndex = 0;
    while (planIndex < innerPlans.length) {
      var innerPlan = innerPlans[planIndex];
      if (innerPlan is NodeProducingEditPlan) {
        _handleNodeProducingEditPlan(innerPlan);
        planIndex++;
      } else if (innerPlan is _RemoveEditPlan) {
        planIndex = _handleRemoveEditPlans(innerPlan, planIndex);
      } else if (innerPlan is _TokenChangePlan) {
        changes += innerPlan.changes;
        planIndex++;
      } else {
        throw UnimplementedError('Unrecognized inner plan type');
      }
    }
  }

  /// Computes the end for the text that should be removed by the given
  /// [innerPlan].
  int _removalEnd(_RemoveEditPlan innerPlan) {
    if (separators != null &&
        !removeLeadingSeparators &&
        innerPlan.lastChildIndex < separators.length) {
      return separators[innerPlan.lastChildIndex].end;
    } else {
      return sequenceNodes[innerPlan.lastChildIndex].end;
    }
  }

  /// Computes the offset for the text that should be removed by the given
  /// [innerPlan].
  int _removalOffset(_RemoveEditPlan innerPlan) {
    if (separators != null && removeLeadingSeparators) {
      return separators[innerPlan.firstChildIndex - 1].offset;
    } else {
      return sequenceNodes[innerPlan.firstChildIndex].offset;
    }
  }

  static bool _checkParenLogic(EditPlan innerPlan, bool parensNeeded) {
    if (innerPlan is _SimpleEditPlan && innerPlan._innerChanges == null) {
      if (innerPlan.sourceNode is FunctionExpression) {
        // Skip parentheses check for function expressions; it produces false
        // failures when examining an expression like `x ?? (y) => z`, due to
        // https://github.com/dart-lang/sdk/issues/40536.
        // TODO(paulberry): fix this.
      } else {
        assert(
            !parensNeeded,
            "Code prior to fixes didn't need parens here, "
            "shouldn't need parens now.");
      }
    }
    return true;
  }

  /// Compute the set of tokens used by the given [parent] node to separate its
  /// [childNodes].
  static List<Token> _computeSeparators(
      AstNode parent, List<AstNode> childNodes) {
    if (parent is Block ||
        parent is ClassDeclaration ||
        parent is CompilationUnit ||
        parent is FormalParameter) {
      // These parent types don't use separators.
      return null;
    } else {
      var result = <Token>[];
      for (var child in childNodes) {
        var separator = child.endToken.next;
        if (separator != null && separator.type == TokenType.COMMA) {
          result.add(separator);
        }
      }
      assert(result.length == childNodes.length ||
          result.length == childNodes.length - 1);
      return result;
    }
  }
}

/// [EditPlan] representing an AstNode that is not to be changed, but may have
/// some changes applied to some of its descendants.
class _PassThroughEditPlan extends _SimpleEditPlan {
  _PassThroughEditPlan._(AstNode node, Precedence precedence,
      bool endsInCascade, Map<int, List<AtomicEdit>> innerChanges)
      : super(node, precedence, endsInCascade, innerChanges);
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
  _ProvisionalParenEditPlan(
      ParenthesizedExpression node, NodeProducingEditPlan innerPlan)
      : super(node, innerPlan);

  @override
  Map<int, List<AtomicEdit>> _getChanges(bool parens) {
    var changes = innerPlan._getChanges(false);
    if (!parens) {
      changes ??= {};
      (changes[offset] ??= []).insert(0, const AtomicEdit.delete(1));
      (changes[end - 1] ??= []).add(const AtomicEdit.delete(1));
    }
    return changes;
  }
}

/// Enum used by [_ExtractEditPlan._removeCode] to describe how code should be
/// removed.
enum _RemovalStyle {
  /// Code should be removed by commenting it out.  Inserted comment delimiters
  /// should be a comment delimiter followed by a space (i.e. `/* ` and `*/ `).
  commentSpace,

  /// Code should be removed by deleting it.
  delete,

  /// Code should be removed by commenting it out.  Inserted comment delimiters
  /// should be a space followed by a comment delimiter (i.e. ` /*` and ` */`).
  spaceComment,

  /// Code should be removed by commenting it out.  Inserted comment delimiters
  /// should have a space inside the comment.
  spaceInsideComment,
}

/// [EditPlan] representing one or more AstNodes that are to be removed from
/// their (common) parent, which must be an AST node that stores a list of
/// sub-nodes.
///
/// If more than one node is to be removed by this [EditPlan], they must be
/// contiguous.
class _RemoveEditPlan extends EditPlan {
  @override
  final AstNode parentNode;

  /// Index of the node to be removed within the parent.
  final int firstChildIndex;

  /// Index of the node to be removed within the parent.
  final int lastChildIndex;

  final AtomicEditInfo info;

  _RemoveEditPlan(
      this.parentNode, this.firstChildIndex, this.lastChildIndex, this.info)
      : super._();
}

/// Implementation of [EditPlan] underlying simple cases where no computation
/// needs to be deferred.
class _SimpleEditPlan extends NodeProducingEditPlan {
  final Precedence _precedence;

  @override
  final bool endsInCascade;

  final Map<int, List<AtomicEdit>> _innerChanges;

  bool _finalized = false;

  _SimpleEditPlan(
      AstNode node, this._precedence, this.endsInCascade, this._innerChanges)
      : super._(node);

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

/// [EditPlan] representing a change (or changes) to be made to a token in the
/// [parentNode].
///
/// This is used, for example, to change the `?.` token of a [MethodInvocation]
/// or [PropertyAccess] to `.`.
class _TokenChangePlan extends EditPlan {
  @override
  final AstNode parentNode;

  /// The changes to be made.
  final Map<int, List<AtomicEdit>> changes;

  _TokenChangePlan(this.parentNode, this.changes) : super._();
}

/// Extension containing useful operations on a list of [AtomicEdit]s.
extension AtomicEditList on List<AtomicEdit> {
  /// Converts a list of [AtomicEdits] to a single [SourceEdit] by concatenating
  /// them.
  ///
  /// If [includeInformative] is `true`, informative edits are included;
  /// otherwise they are ignored.
  SourceEdit toSourceEdit(int offset, {bool includeInformative = false}) {
    var totalLength = 0;
    var replacement = '';
    for (var edit in this) {
      if (!edit.isInformative || includeInformative) {
        totalLength += edit.length;
        replacement += edit.replacement;
      }
    }
    return SourceEdit(offset, totalLength, replacement);
  }
}

/// Extension containing useful operations on a map from offsets to lists of
/// [AtomicEdit]s.  This data structure is used by [EditPlans] to accumulate
/// source file changes.
extension AtomicEditMap on Map<int, List<AtomicEdit>> {
  /// Applies the changes to source file text.
  ///
  /// If [includeInformative] is `true`, informative edits are included;
  /// otherwise they are ignored.
  String applyTo(String code, {bool includeInformative = false}) {
    return SourceEdit.applySequence(
        code, toSourceEdits(includeInformative: includeInformative));
  }

  /// Converts the changes to a list of [SourceEdit]s.  The list is reverse
  /// sorted by offset so that they can be applied in order.
  ///
  /// If [includeInformative] is `true`, informative edits are included;
  /// otherwise they are ignored.
  List<SourceEdit> toSourceEdits({bool includeInformative = false}) {
    return [
      for (var offset in keys.toList()..sort((a, b) => b.compareTo(a)))
        this[offset]
            .toSourceEdit(offset, includeInformative: includeInformative)
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
