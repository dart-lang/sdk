// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart'
    show
        AssertBlock,
        Block,
        BlockExpression,
        Catch,
        Class,
        Component,
        Constructor,
        DartType,
        Extension,
        ExtensionTypeDeclaration,
        Field,
        FileUriNode,
        ForInStatement,
        ForStatement,
        FunctionNode,
        Initializer,
        Let,
        Library,
        Member,
        Node,
        Procedure,
        TreeNode,
        TypeParameter,
        Typedef,
        TypedefTearOff,
        VariableDeclaration,
        VisitorDefault,
        VisitorNullMixin,
        VisitorVoidMixin;

/// Dart scope
///
/// Provides information about symbols available inside a dart scope.
class DartScope {
  final TreeNode? node;
  final Library library;
  final Class? cls;
  final Member? member;
  final bool isStatic;
  final Map<String, DartType> definitions;
  final List<TypeParameter> typeParameters;

  DartScope(this.node, this.library, this.cls, this.member, this.definitions,
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

    return DartScope(
        null, _library!, _cls, _member, _definitions, _typeParameters);
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

class DartScopeBuilder2 extends VisitorDefault<void> with VisitorVoidMixin {
  final Library _library;
  final Uri _scriptUri;
  final int _offset;
  final List<DartScope> findScopes = [];

  final List<List<VariableDeclaration>> scopes = [];
  final List<List<TypeParameter>> typeParameterScopes = [];

  Class? _currentCls = null;
  Member? _currentMember = null;

  bool checkClasses = true;
  Uri _currentUri;

  DartScopeBuilder2._(this._library, this._scriptUri, this._offset)
      : _currentUri = _library.fileUri;

  void addFound(TreeNode node) {
    Map<String, DartType> definitions = {};
    for (List<VariableDeclaration> scope in scopes) {
      for (VariableDeclaration decl in scope) {
        String? name = decl.name;
        if (name != null && name != "") {
          definitions[name] = decl.type;
        }
      }
    }
    List<TypeParameter> typeParameters = [];
    for (List<TypeParameter> typeParameterScope in typeParameterScopes) {
      typeParameters.addAll(typeParameterScope);
    }
    DartScope findScope = new DartScope(node, _library, _currentCls,
        _currentMember, definitions, typeParameters);
    findScopes.add(findScope);
  }

  @override
  void defaultDartType(DartType node) {
    return;
  }

  @override
  void defaultTreeNode(TreeNode node) {
    Uri prevUri = _currentUri;
    if (node is FileUriNode) {
      _currentUri = node.fileUri;
    }
    _checkOffset(node);
    node.visitChildren(this);
    _currentUri = prevUri;
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    scopes.add([]);
    super.visitAssertBlock(node);
    scopes.removeLast();
  }

  @override
  void visitBlock(Block node) {
    scopes.add([]);

    _checkOffset(node);

    bool shouldSkip;

    // See also the test [DillBlockChecker] which checks that we can do this
    // pruning!
    if (_currentUri != _scriptUri) {
      shouldSkip = true;
    } else if (node.parent is ForInStatement) {
      // E.g. dart2js implicit cast in for-in loop
      shouldSkip = false;
    } else if (node.parent?.parent is ForStatement) {
      // A vm transformation turns
      // `for (var foo in bar) {}`
      // into
      // `for(;iterator.moveNext; ) { var foo = iterator.current; {} }`
      // where the block directly containing `foo` has the original blocks
      // offset, i.e. after the variable declaration, but it still contain
      // it. So we pretend it has no offsets.
      shouldSkip = false;
    } else if (node.fileOffset >= 0 &&
        node.fileEndOffset >= 0 &&
        node.fileOffset != node.fileEndOffset) {
      if (_offset < node.fileOffset || _offset > node.fileEndOffset) {
        // Not contained in the block.
        shouldSkip = true;
      } else {
        // Contained in the block.
        shouldSkip = false;
      }
    } else {
      // The block doesn't have valid offsets.
      shouldSkip = false;
    }

    if (!shouldSkip) {
      node.visitChildren(this);
    }

    scopes.removeLast();
  }

  @override
  void visitBlockExpression(BlockExpression node) {
    scopes.add([]);
    super.visitBlockExpression(node);
    scopes.removeLast();
  }

  @override
  void visitCatch(Catch node) {
    scopes.add([]);
    super.visitCatch(node);
    scopes.removeLast();
  }

  @override
  void visitClass(Class node) {
    if (!checkClasses) {
      return;
    }
    _currentCls = node;
    typeParameterScopes.add([...node.typeParameters]);
    scopes.add([]);
    super.visitClass(node);
    scopes.clear();
    typeParameterScopes.removeLast();
    assert(typeParameterScopes.isEmpty);
    _currentCls = null;
  }

  @override
  void visitConstructor(Constructor node) {
    Uri prevUri = _currentUri;
    _currentUri = node.fileUri;

    _currentMember = node;
    scopes.clear();
    scopes.add([]);

    _checkOffset(node);

    // The constructor is special in that the parameters from the contained
    // function node is in scope in the initializers.
    node.function.accept(this);
    for (VariableDeclaration param in node.function.positionalParameters) {
      scopes.last.add(param);
    }
    for (VariableDeclaration param in node.function.namedParameters) {
      scopes.last.add(param);
    }
    for (Initializer initializer in node.initializers) {
      initializer.accept(this);
    }

    scopes.clear();
    _currentMember = null;
    _currentUri = prevUri;
  }

  @override
  void visitExtension(Extension node) {
    typeParameterScopes.add([...node.typeParameters]);
    super.visitExtension(node);
    typeParameterScopes.removeLast();
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    typeParameterScopes.add([...node.typeParameters]);
    super.visitExtensionTypeDeclaration(node);
    typeParameterScopes.removeLast();
  }

  @override
  void visitField(Field node) {
    _currentMember = node;
    scopes.clear();
    scopes.add([]);
    super.visitField(node);
    scopes.clear();
    _currentMember = null;
  }

  @override
  void visitForInStatement(ForInStatement node) {
    scopes.add([]);
    super.visitForInStatement(node);
    scopes.removeLast();
  }

  @override
  void visitForStatement(ForStatement node) {
    scopes.add([]);
    super.visitForStatement(node);
    scopes.removeLast();
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    typeParameterScopes.add([...node.typeParameters]);
    scopes.add([]);
    super.visitFunctionNode(node);
    scopes.removeLast();
    typeParameterScopes.removeLast();
  }

  @override
  void visitLet(Let node) {
    scopes.add([]);
    super.visitLet(node);
    scopes.removeLast();
  }

  @override
  void visitLibrary(Library node) {
    scopes.add([]);
    super.visitLibrary(node);
    scopes.clear();
  }

  @override
  void visitProcedure(Procedure node) {
    _currentMember = node;
    scopes.clear();
    scopes.add([]);
    super.visitProcedure(node);
    scopes.clear();
    _currentMember = null;
  }

  @override
  void visitTypedef(Typedef node) {
    scopes.clear();
    scopes.add([]);
    typeParameterScopes.add([...node.typeParameters]);
    super.visitTypedef(node);
    typeParameterScopes.removeLast();
    scopes.clear();
  }

  @override
  void visitTypedefTearOff(TypedefTearOff node) {
    typeParameterScopes.add([...node.typeParameters]);
    super.visitTypedefTearOff(node);
    typeParameterScopes.removeLast();
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    super.visitVariableDeclaration(node);
    // Declare it after.
    scopes.last.add(node);
  }

  void _checkOffset(TreeNode node) {
    if (_currentUri == _scriptUri) {
      if (node.fileOffset == _offset) {
        addFound(node);
      } else {
        List<int>? allOffsets = node.fileOffsetsIfMultiple;
        if (allOffsets != null) {
          for (final int offset in allOffsets) {
            if (offset == _offset) {
              addFound(node);
              break;
            }
          }
        }
      }
    }
  }

  static List<DartScope> findScopeFromOffsetAndClass(
      Library library, Uri scriptUri, Class? cls, int offset) {
    DartScopeBuilder2 builder = DartScopeBuilder2._(library, scriptUri, offset);
    if (cls != null) {
      builder.visitClass(cls);
    } else {
      builder.checkClasses = false;
      builder.visitLibrary(library);
    }

    return builder.findScopes;
  }
}
