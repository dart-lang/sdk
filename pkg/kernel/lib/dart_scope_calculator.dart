// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        Block,
        Class,
        Component,
        Constructor,
        DartType,
        Field,
        FunctionNode,
        Library,
        Member,
        Node,
        Procedure,
        TreeNode,
        TypeParameter,
        VariableDeclaration,
        VisitorDefault,
        VisitorNullMixin,
        VisitorVoidMixin;

/// Dart scope
///
/// Provides information about symbols available inside a dart scope.
class DartScope {
  final Library library;
  final Class? cls;
  final Member? member;
  final bool isStatic;
  final Map<String, DartType> definitions;
  final List<TypeParameter> typeParameters;

  DartScope(this.library, this.cls, this.member, this.definitions,
      this.typeParameters)
      : isStatic = member is Procedure ? member.isStatic : false;

  @override
  String toString() {
    return '''DartScope {
      Library: ${library.importUri},
      Class: ${cls?.name},
      Procedure: $member,
      isStatic: $isStatic,
      Scope: $definitions,
      typeParameters: $typeParameters
    }
    ''';
  }
}

/// DartScopeBuilder finds dart scope information for a location.
///
/// Find all definitions in scope at a given 1-based [line] and [column]:
///
/// - library
/// - class
/// - locals
/// - formals
/// - captured variables (for closures)
class DartScopeBuilder extends VisitorDefault<void> with VisitorVoidMixin {
  final Component _component;
  final int _line;
  final int _column;

  Library? _library;
  Class? _cls;
  Member? _member;
  int _offset = -1;

  final List<FunctionNode> _functions = [];
  final Map<String, DartType> _definitions = {};
  final List<TypeParameter> _typeParameters = [];

  DartScopeBuilder._(this._component, this._line, this._column);

  static DartScope? findScope(
      Component component, Library library, int line, int column) {
    DartScopeBuilder builder = DartScopeBuilder._(component, line, column);
    library.accept(builder);
    return builder.build();
  }

  DartScope? build() {
    if (_offset < 0 || _library == null) return null;

    return DartScope(_library!, _cls, _member, _definitions, _typeParameters);
  }

  @override
  void defaultTreeNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitLibrary(Library library) {
    _library = library;
    _offset = 0;
    if (_line > 0) {
      _offset = _component.getOffset(_library!.fileUri, _line, _column);
    }

    // Exit early if the evaluation offset is not found.
    // Note: the complete scope is not found in this case,
    // so the expression compiler will report an error.
    if (_offset >= 0) super.visitLibrary(library);
  }

  @override
  void visitClass(Class cls) {
    if (_scopeContainsOffset(cls.fileOffset, cls.fileEndOffset, _offset)) {
      _cls = cls;
      _typeParameters.addAll(cls.typeParameters);

      super.visitClass(cls);
    }
  }

  @override
  void defaultMember(Member m) {
    if (_scopeContainsOffset(m.fileOffset, m.fileEndOffset, _offset)) {
      _member = m;

      super.defaultMember(m);
    }
  }

  @override
  void visitFunctionNode(FunctionNode fun) {
    if (_scopeContainsOffset(fun.fileOffset, fun.fileEndOffset, _offset)) {
      _functions.add(fun);
      _typeParameters.addAll(fun.typeParameters);

      super.visitFunctionNode(fun);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration decl) {
    String? name = decl.name;
    // Collect locals and formals appearing before current breakpoint.
    // Note that we include variables with no offset because the offset
    // is not set in many cases in generated code, so omitting them would
    // make expression evaluation fail in too many cases.
    // Issue: https://github.com/dart-lang/sdk/issues/43966
    //
    // A null name signals that the variable was synthetically introduced by the
    // compiler so they are skipped.
    if ((decl.fileOffset < 0 || decl.fileOffset < _offset) && name != null) {
      _definitions[name] = decl.type;
    }
    super.visitVariableDeclaration(decl);
  }

  @override
  void visitBlock(Block block) {
    int fileEndOffset = FileEndOffsetCalculator.calculateEndOffset(block);
    if (_scopeContainsOffset(block.fileOffset, fileEndOffset, _offset)) {
      super.visitBlock(block);
    }
  }

  bool _scopeContainsOffset(int startOffset, int endOffset, int offset) {
    if (offset < 0 || startOffset < 0 || endOffset < 0) {
      return false;
    }
    return startOffset <= offset && offset <= endOffset;
  }
}

/// File end offset calculator.
///
/// Helps calculate file end offsets for nodes with internal scope
/// that do not have .fileEndOffset field.
///
/// For example - [Block]
class FileEndOffsetCalculator extends VisitorDefault<int?>
    with VisitorNullMixin<int> {
  static const int noOffset = -1;

  final int _startOffset;
  final TreeNode _root;
  final TreeNode _original;

  int _endOffset = noOffset;

  /// Create calculator for a scoping node with no .fileEndOffset.
  ///
  /// [_root] is the parent of the scoping node.
  /// [_startOffset] is the start offset of the scoping node.
  FileEndOffsetCalculator._(this._root, this._original)
      : _startOffset = _original.fileOffset;

  /// Calculate file end offset for a scoping node.
  ///
  /// This calculator finds the first node in the ancestor chain that
  /// can give such information for a given [node], i.e. satisfies one
  /// of the following conditions:
  ///
  /// - a node with a greater start offset that is a child of the
  ///   closest ancestor. The start offset of this child is used as a
  ///   file end offset of the [node].
  ///
  /// - the closest ancestor with .fileEndOffset information. The file
  ///   end offset of the ancestor is used as the file end offset of
  ///   the [node.]
  ///
  /// If none found, return [noOffset].
  static int calculateEndOffset(TreeNode node) {
    for (TreeNode? n = node.parent; n != null; n = n.parent) {
      FileEndOffsetCalculator calculator = FileEndOffsetCalculator._(n, node);
      int? offset = n.accept(calculator);
      if (offset != noOffset) return offset!;
    }
    return noOffset;
  }

  @override
  int defaultTreeNode(TreeNode node) {
    if (node == _original) return _endOffset;
    if (node == _root) {
      node.visitChildren(this);
      if (_endOffset != noOffset) return _endOffset;
      return _endOffsetForNode(node);
    }
    // Skip synthesized variables as they could have offsets
    // from later code (in case they are hoisted, for example).
    if ((node is! VariableDeclaration || !node.isSynthesized) &&
        _endOffset == noOffset &&
        node.fileOffset > _startOffset) {
      _endOffset = node.fileOffset;
    }
    return _endOffset;
  }

  static int _endOffsetForNode(TreeNode node) {
    if (node is Class) return node.fileEndOffset;
    if (node is Constructor) return node.fileEndOffset;
    if (node is Procedure) return node.fileEndOffset;
    if (node is Field) return node.fileEndOffset;
    if (node is FunctionNode) return node.fileEndOffset;
    return noOffset;
  }
}
