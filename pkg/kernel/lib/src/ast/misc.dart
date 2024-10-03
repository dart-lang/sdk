// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

/// Any type of node in the IR.
abstract class Node {
  const Node();

  R accept<R>(Visitor<R> v);
  R accept1<R, A>(Visitor1<R, A> v, A arg);
  void visitChildren(Visitor v);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toString] should only be used for debugging, but should not leak.
  ///
  /// The data is generally bare-bones, but can easily be updated for your
  /// specific debugging needs.
  @override
  String toString();

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// [toStringInternal] should only be used for debugging, but should not leak.
  ///
  /// The data is generally bare-bones, but can easily be updated for your
  /// specific debugging needs.
  ///
  /// This method is called internally by toString methods to create conciser
  /// textual representations.
  String toStringInternal() => toText(defaultAstTextStrategy);

  /// Returns the textual representation of this node for use in debugging.
  ///
  /// Note that this adds some nodes to a static map to ensure consistent
  /// naming, but that it thus also leaks memory. [leakingDebugToString] should
  /// thus only be used for debugging and short-running test tools.
  ///
  /// Synthetic names are cached globally to retain consistency across different
  /// [leakingDebugToString] calls (hence the memory leak).
  String leakingDebugToString() => astToText.debugNodeToString(this);

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  void toTextInternal(AstPrinter printer);
}

/// A mutable AST node with a parent pointer.
///
/// This is anything other than [Name] and [DartType] nodes.
abstract class TreeNode extends Node {
  static int _hashCounter = 0;
  @override
  final int hashCode = _hashCounter = (_hashCounter + 1) & 0x3fffffff;
  static const int noOffset = -1;

  TreeNode? parent;

  /// Offset in the source file the node comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([noOffset]) if the file offset is
  /// not available (this is the default if none is specifically set).
  ///
  /// This is an index into [Source.text].
  int fileOffset = noOffset;

  /// When the node has more offsets that just [fileOffset], the list of all
  /// offsets.
  List<int>? get fileOffsetsIfMultiple => null;

  @override
  R accept<R>(TreeVisitor<R> v);
  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg);
  @override
  void visitChildren(Visitor v);
  void transformChildren(Transformer v);
  void transformOrRemoveChildren(RemovingTransformer v);

  /// Replaces [child] with [replacement].
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// Has no effect if [child] is not actually a child of this node.
  ///
  /// [replacement] must be non-null.
  void replaceChild(TreeNode child, TreeNode replacement) {
    transformChildren(new _ChildReplacer(child, replacement));
  }

  /// Inserts another node in place of this one.
  ///
  /// The caller is responsible for ensuring that the AST remains a tree.  In
  /// particular, [replacement] should be an orphan or be part of an orphaned
  /// subtree.
  ///
  /// [replacement] must be non-null.
  void replaceWith(TreeNode replacement) {
    parent!.replaceChild(this, replacement);
    parent = null;
  }

  // TODO(johnniwinther): Make this non-nullable.
  Component? get enclosingComponent => parent?.enclosingComponent;

  /// Returns the best known source location of the given AST node, or `null` if
  /// the node is orphaned.
  ///
  /// This getter is intended for diagnostics and debugging, and should be
  /// avoided in production code.
  Location? get location {
    if (fileOffset == noOffset) return parent?.location;
    return _getLocationInEnclosingFile(fileOffset);
  }

  Location? _getLocationInEnclosingFile(int offset) {
    return parent?._getLocationInEnclosingFile(offset);
  }
}

/// An AST node that can be referenced by other nodes.
///
/// There is a single [reference] belonging to this node, providing a level of
/// indirection that is needed during serialization.
abstract class NamedNode extends TreeNode {
  final Reference reference;

  NamedNode(Reference? reference)
      : this.reference = reference ?? new Reference() {
    this.reference.node = this;
  }

  /// This is an advanced feature.
  ///
  /// See [Component.relink] for a comprehensive description.
  ///
  /// Makes sure the reference in this named node points to itself.
  void _relinkNode() {
    this.reference.node = this;
  }

  /// Computes the canonical names for this node using the [parent] as the
  /// canonical name of the parent node.
  void bindCanonicalNames(CanonicalName parent);
}

/// Declaration that can introduce [TypeParameter]s.
sealed class GenericDeclaration implements TreeNode {
  /// The type parameters introduced by this declaration.
  List<TypeParameter> get typeParameters;
}

/// Functions that can introduce [TypeParameter]s.
sealed class GenericFunction implements GenericDeclaration {
  /// The [FunctionNode] that holds the introduced [typeParameters].
  FunctionNode get function;
}

abstract class FileUriNode extends TreeNode {
  /// The URI of the source file this node was loaded from.
  Uri get fileUri;

  void set fileUri(Uri value);
}

abstract class Annotatable extends TreeNode {
  List<Expression> get annotations;
  void addAnnotation(Expression node);
}

class Version extends Object {
  final int major;
  final int minor;

  const Version(this.major, this.minor);

  bool operator <(Version other) {
    if (major < other.major) return true;
    if (major > other.major) return false;

    // Major is the same.
    if (minor < other.minor) return true;
    return false;
  }

  bool operator <=(Version other) {
    if (major < other.major) return true;
    if (major > other.major) return false;

    // Major is the same.
    if (minor <= other.minor) return true;
    return false;
  }

  bool operator >(Version other) {
    if (major > other.major) return true;
    if (major < other.major) return false;

    // Major is the same.
    if (minor > other.minor) return true;
    return false;
  }

  bool operator >=(Version other) {
    if (major > other.major) return true;
    if (major < other.major) return false;

    // Major is the same.
    if (minor >= other.minor) return true;
    return false;
  }

  /// Returns this language version as a 'major.minor' text.
  String toText() => '${major}.${minor}';

  @override
  int get hashCode {
    return major.hashCode * 13 + minor.hashCode * 17;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Version && major == other.major && minor == other.minor;
  }

  @override
  String toString() {
    return "Version(major=$major, minor=$minor)";
  }
}
