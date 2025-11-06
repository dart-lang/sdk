// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Dart scope
///
/// Provides information about symbols available inside a dart scope.
class DartScope {
  final Library library;
  final Uri? fileUri;
  final int? offset;
  final Class? cls;
  final Member? member;
  final bool isStatic;
  final Map<String, VariableDeclaration> variables;
  final List<TypeParameter> typeParameters;

  DartScope(this.library, this.fileUri, this.offset, this.cls, this.member,
      this.variables, this.typeParameters)
      : isStatic = member is Procedure ? member.isStatic : false;

  Map<String, DartType> variablesAsMapToType() {
    Map<String, DartType> result = {};
    for (MapEntry<String, VariableDeclaration> entry in variables.entries) {
      result[entry.key] = entry.value.type;
    }
    return result;
  }

  @override
  String toString() {
    return '''DartScope {
      Library: ${library.importUri},
      Class: ${cls?.name},
      Procedure: $member,
      isStatic: $isStatic,
      Scope: $variables,
      typeParameters: $typeParameters
    }
    ''';
  }
}

/// Dart scope
///
/// Provides information about symbols available inside a dart scope.
class DartScope2 {
  final TreeNode node;
  final Library library;
  final Class? cls;
  final Member? member;
  final bool isStatic;
  final Map<String, VariableDeclaration> variables;
  final List<TypeParameter> typeParameters;

  DartScope2(this.node, this.library, this.cls, this.member, this.variables,
      this.typeParameters)
      : isStatic = member is Procedure ? member.isStatic : false;

  @override
  String toString() {
    return '''DartScope {
      Library: ${library.importUri},
      Class: ${cls?.name},
      Procedure: $member,
      isStatic: $isStatic,
      Scope: $variables,
      typeParameters: $typeParameters
    }
    ''';
  }
}

class DartScopeBuilder2 extends VisitorDefault<void> with VisitorVoidMixin {
  final Library _library;
  final Uri _scriptUri;
  final int _offset;
  final List<DartScope2> findScopes = [];
  int? closestLessOrEqualFoundOffset;

  final Set<VariableDeclaration> hoistedUnwritten = {};
  final List<List<VariableDeclaration>> scopes = [];
  final List<List<TypeParameter>> typeParameterScopes = [];

  Class? _currentCls = null;
  Member? _currentMember = null;

  bool checkClasses = true;
  Uri _currentUri;

  DartScopeBuilder2._(this._library, this._scriptUri, this._offset)
      : _currentUri = _library.fileUri;

  void clearScope() {
    scopes.clear();
    hoistedUnwritten.clear();
  }

  void addFound(TreeNode node) {
    Map<String, VariableDeclaration> definitions = {};
    for (List<VariableDeclaration> scope in scopes) {
      for (VariableDeclaration decl in scope) {
        String? name = decl.name;
        if (name != null &&
            !decl.isSynthesized &&
            !hoistedUnwritten.contains(decl) &&
            !decl.isWildcard) {
          definitions[name] = decl;
        }
      }
    }
    int fromIndex = 0;
    if (_currentCls != null &&
        _currentMember != null &&
        !_currentMember!.isInstanceMember &&
        _currentMember is! Constructor) {
      // We're inside a class, but currently in a static member (that is not a
      // constructor). The first list in [typeParameterScopes] are the class
      // ones, so we'll skip those here.
      fromIndex = 1;
    }
    List<TypeParameter> typeParameters = [];
    for (int i = fromIndex; i < typeParameterScopes.length; i++) {
      List<TypeParameter> typeParameterScope = typeParameterScopes[i];
      typeParameters.addAll(typeParameterScope);
    }
    DartScope2 findScope = new DartScope2(node, _library, _currentCls,
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
    clearScope();
    typeParameterScopes.removeLast();
    assert(typeParameterScopes.isEmpty);
    _currentCls = null;
  }

  @override
  void visitConstructor(Constructor node) {
    Uri prevUri = _currentUri;
    _currentUri = node.fileUri;

    _currentMember = node;
    clearScope();
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

    clearScope();
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
    clearScope();
    scopes.add([]);
    super.visitField(node);
    clearScope();
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
    clearScope();
  }

  @override
  void visitProcedure(Procedure node) {
    _currentMember = node;
    clearScope();
    scopes.add([]);
    super.visitProcedure(node);
    clearScope();
    _currentMember = null;
  }

  @override
  void visitTypedef(Typedef node) {
    clearScope();
    scopes.add([]);
    typeParameterScopes.add([...node.typeParameters]);
    super.visitTypedef(node);
    typeParameterScopes.removeLast();
    clearScope();
  }

  @override
  void visitVariableSet(VariableSet node) {
    super.visitVariableSet(node);
    if (node.variable.isHoisted) {
      hoistedUnwritten.remove(node.variable);
    }
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.isHoisted) hoistedUnwritten.add(node);
    super.visitVariableDeclaration(node);
    // Declare it after.
    scopes.last.add(node);
  }

  void _updateClosestFoundOffset(int offset) {
    if (offset > _offset) {
      // This offset is larger that the one we're looking for so we'll skip.
      return;
    }
    if (closestLessOrEqualFoundOffset == null ||
        offset > closestLessOrEqualFoundOffset!) {
      closestLessOrEqualFoundOffset = offset;
      return;
    }
  }

  void _checkOffset(TreeNode node) {
    if (_currentUri != _scriptUri) return;

    _updateClosestFoundOffset(node.fileOffset);
    if (node.fileOffset == _offset) {
      addFound(node);
    } else {
      List<int>? allOffsets = node.fileOffsetsIfMultiple;
      if (allOffsets != null) {
        for (final int offset in allOffsets) {
          _updateClosestFoundOffset(offset);
          if (offset == _offset) {
            addFound(node);
            break;
          }
        }
      }
    }
  }

  static DartScope findScopeFromOffsetAndClass(
      Library library, Uri scriptUri, Class? cls, int offset) {
    DartScopeBuilder2 data = _raw(library, scriptUri, cls, offset);
    if (data.findScopes.isEmpty) {
      int? closestLessOrEqualFoundOffset = data.closestLessOrEqualFoundOffset;
      if (closestLessOrEqualFoundOffset != null) {
        offset = closestLessOrEqualFoundOffset;
        data = _raw(library, scriptUri, cls, offset);
      }
    }
    return _findScopePick(data.findScopes, scriptUri, library, cls, offset);
  }

  static DartScope _findScopePick(List<DartScope2> scopes, Uri scriptUri,
      Library library, Class? cls, int offset) {
    DartScope2 scope;
    if (scopes.length == 0) {
      // This shouldn't happen.
      return new DartScope(library, null, null, cls, null, {}, []);
    } else if (scopes.length == 1) {
      scope = scopes.single;
    } else {
      List<DartScope2> filteredScopes = _filterAll(scopes, library, offset);
      if (filteredScopes.length == 0) {
        // This shouldn't happen.
        filteredScopes = scopes;
      }
      if (filteredScopes.length == 1) {
        scope = filteredScopes.single;
      } else {
        // TODO(jensj): This shouldn't happen, but inevitably will.
        // When it does, what should we do?
        scope = scopes.last;
      }
    }

    return new DartScope(scope.library, scriptUri, offset, scope.cls,
        scope.member, scope.variables, scope.typeParameters);
  }

  static DartScope findScopeFromOffset(
      Library library, Uri scriptUri, int offset) {
    DartScopeBuilder2 data = _rawNoClass(library, scriptUri, offset);
    if (data.findScopes.isEmpty) {
      int? closestLessOrEqualFoundOffset = data.closestLessOrEqualFoundOffset;
      if (closestLessOrEqualFoundOffset != null) {
        offset = closestLessOrEqualFoundOffset;
        data = _rawNoClass(library, scriptUri, offset);
      }
    }
    return _findScopePick(data.findScopes, scriptUri, library, null, offset);
  }

  static List<DartScope2> _filterAll(
      List<DartScope2> rawScopes, Library library, int offset) {
    List<DartScope2> firstFilteredScopes =
        _filterScopesWithArtificialNodes(rawScopes, library);
    if (firstFilteredScopes.isEmpty) {
      return rawScopes;
    }
    if (_allHaveTheSameDefinitions(firstFilteredScopes)) {
      return [firstFilteredScopes.first];
    }
    List<DartScope2> filteredScopes =
        _filter(firstFilteredScopes, library, offset);
    if (_allHaveTheSameDefinitions(filteredScopes)) {
      return [filteredScopes.first];
    }
    return filteredScopes;
  }

  static List<DartScope2> filterAllForTesting(
      List<DartScope2> rawScopes, Library library, int offset) {
    return _filterAll(rawScopes, library, offset);
  }

  static List<DartScope2> _filterScopesWithArtificialNodes(
      List<DartScope2> unfilteredScopes, Library library) {
    Set<Member> skipMembers = {};
    for (Extension node in library.extensions) {
      for (ExtensionMemberDescriptor memberDescriptor
          in node.memberDescriptors) {
        // The tear off procedures have two enclosing function nodes with the
        // same offsets, but with (possibly) different type parameters.
        // Skip them.
        Member? skip = memberDescriptor.tearOffReference?.asMember;
        if (skip != null) skipMembers.add(skip);
      }
    }

    List<DartScope2> filtered = [];
    for (DartScope2 node in unfilteredScopes) {
      Member? member = node.member;
      if (skipMembers.contains(member)) {
        // Skip these.
        continue;
      }
      if (member is Field) {
        if (member.isInternalImplementation) {
          // E.g. synthesized fields added by late lowering. Skip those.
          continue;
        }
      } else if (member is Procedure) {
        if (member.isSynthetic) {
          // Skip synthetic procedures.
          continue;
        }
      }
      filtered.add(node);
    }

    return filtered;
  }

  static bool _allHaveTheSameDefinitions(List<DartScope2> scopes) {
    if (scopes.isEmpty) return false;
    Map<String, VariableDeclaration> variables = scopes.first.variables;
    for (int i = 1; i < scopes.length; i++) {
      DartScope2 scope = scopes[i];
      if (scope.variables.length != variables.length) return false;
      for (MapEntry<String, VariableDeclaration> entry
          in scope.variables.entries) {
        VariableDeclaration? existing = variables[entry.key];
        if (existing == null) {
          return false;
        } else {
          if (existing != entry.value) {
            return false;
          }
        }
      }
    }
    return true;
  }

  static List<DartScope2> _filter(
      List<DartScope2> unfilteredScopes, Library library, int offset) {
    List<DartScope2> filtered = unfilteredScopes.toList();
    List<DartScope2> withoutEndOffset = [];
    for (DartScope2 scope in unfilteredScopes) {
      TreeNode? node = scope.node;
      // Possibly filter out nodes that was only included because their end
      // offset matched the offset we we're looking for.
      if (node is Member) {
        if (offset != node.fileEndOffset) {
          withoutEndOffset.add(scope);
        }
      } else if (node is FunctionNode) {
        if (offset != node.fileEndOffset) {
          withoutEndOffset.add(scope);
        }
      } else if (node is Block) {
        if (offset != node.fileEndOffset) {
          withoutEndOffset.add(scope);
        }
      } else {
        withoutEndOffset.add(scope);
      }
    }

    if (withoutEndOffset.length == 1) {
      return withoutEndOffset;
    } else if (withoutEndOffset.isEmpty) {
      // They're all on the end offset. Just return the last one.
      // E.g.
      // ```
      // static makeErrorHandler(_EventSink controller) =>
      // (Object e, StackTrace s) {
      //   controller._addError(e, s);
      //   controller._close();
      // };
      // ```
      // have both the Procedure, the first FunctionNode and the second
      // FunctionNode with the same end offset.
      return [filtered.last];
    } else {
      filtered = withoutEndOffset;
    }

    if ((filtered.length == 2 &&
            filtered[0].node is ForInStatement &&
            filtered[1].node is Block) ||
        (filtered.length == 3 &&
            filtered[0].node is ForInStatement &&
            filtered[1].node is LabeledStatement &&
            filtered[2].node is Block)) {
      // In the below code the for in statement was included on the brace
      // because of the body offset, but as we have the block that's what we
      // should use, so we remove the ForInStatement.
      // ```
      // String? name = node.name;
      // // [...]
      // for (String name in combinator.names) { // <- this brace
      //   // whatnot
      // }
      // ```
      return [filtered.last];
    }

    if (filtered.length == 2 &&
        filtered[0].node is ForInStatement &&
        filtered[1].node is YieldStatement) {
      // E.g.
      // ```
      // for (var key in keys) yield MapEntry<K, V>(key, this[key] as dynamic);
      // ```
      // where the ForIn and the yield has the same (body) offset.
      return [filtered[1]];
    }

    if (filtered.length > 2 &&
        filtered.length < 5 &&
        filtered[0].node is ForInStatement &&
        filtered[1].node is ExpressionStatement) {
      // E.g.
      // ```
      // for (var entry in entries) this[entry.key] = entry.value;
      // ```
      return [filtered.last];
    }

    if (filtered.length == 2 &&
        filtered[0].node is FunctionNode &&
        filtered[1].node is Block) {
      // Remove the function node one(s) --- assume we're on the block
      // to remove some uncertainty in for instance these situations:
      // ```
      // void foo(String? s) {
      //   if (s == null) return;
      //   bar(String s) {
      //     // whatever
      //   } // <- if the position is at this brace.
      //   bar(s);
      // }
      // ```
      // and
      // ```
      // void bla() {
      //   void foo(String foo) {
      //     // Here "foo" is a string.
      //   } // <- if the position is at this brace.
      // }
      // ```
      // In both situations we have two variables with the same name but
      // different types, depending on if the positionals from the function node
      // is "on" or not.
      return [filtered[1]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is VariableDeclaration &&
        filtered[1].node is FieldInitializer) {
      // Pick the FieldInitializer (i.e. have the variable in scope).
      return [filtered[1]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is VariableDeclaration &&
        filtered[1].node is VariableGet &&
        filtered[1].node.parent?.parent is SuperInitializer) {
      // E.g. `Foo(super.bar)`.
      // Pick the VariableGet (with all variables in scope --- this is not
      // great if we can actually stop before, but can we?).
      return [filtered[1]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is Constructor &&
        filtered[1].node is SuperInitializer) {
      // Pick the SuperInitializer (i.e. have any variables in scope).
      return [filtered[1]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is VariableDeclaration &&
        filtered[1].node is VariableGet &&
        filtered[0].node.parent?.parent is Procedure &&
        (filtered[0].node.parent?.parent as Procedure).isRedirectingFactory) {
      return [filtered[1]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is FunctionNode &&
        filtered[1].node is InvocationExpression &&
        filtered[0].node.parent is Procedure &&
        (filtered[0].node.parent as Procedure).isRedirectingFactory) {
      return [filtered[1]];
    }
    if (filtered.length > 1 &&
        filtered[0].node is Class &&
        (filtered[0].node as Class).isEnum) {
      return [filtered[0]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is VariableDeclaration &&
        filtered[1].node is VariableGet &&
        filtered[0].node.parent?.parent is Constructor &&
        filtered[1].node.parent?.parent is Arguments) {
      // E.g. `super.localId`.
      return [filtered[1]];
    }
    if (filtered.length == 2 &&
        filtered[0].node is IfStatement &&
        filtered[1].node is Block) {
      return [filtered[0]];
    }
    if (filtered.length > 1 &&
        filtered[0].node is InstanceGet &&
        (filtered[0].node as InstanceGet).receiver is VariableGet &&
        ((filtered[0].node as InstanceGet).receiver as VariableGet)
            .variable
            .isSynthesized) {
      // E.g. `await for (var fileEntity in stream) { [...] }` that has become
      // FileSystemEntity fileEntity = :for-iterator.{_StreamIterator.current};
      // {
      //   [...]
      // }
      // where the getting of the iterator and the block has the same offset,
      // pointing to the start brace after `fileEntity` was defined in the
      // source. We remove the InstanceGet.
      filtered.removeAt(0);
    }
    if (filtered.length == 1) return filtered;

    DartScope2? lookup;

    // TODO(jensj): Look into rewriting the matching to use patterns.
    // See also
    // https://dart-review.googlesource.com/c/sdk/+/338840/8/pkg/kernel/lib/dart_scope_calculator.dart#924
    lookup = _looksLikeVmForInTransformation(filtered);
    if (lookup != null) return [lookup];

    lookup = _looksLikeVmFfiTransformation(filtered);
    if (lookup != null) return [lookup];

    lookup = _looksLikeLateLoweredField(filtered);
    if (lookup != null) return [lookup];

    lookup = _looksLikePatternMatching(filtered);
    if (lookup != null) return [lookup];

    lookup = _looksLikeLateLoweredLocal(filtered);
    if (lookup != null) return [lookup];

    lookup = _looksLikeThrowPatternMatchingError(filtered);
    if (lookup != null) return [lookup];

    return filtered;
  }

  static DartScope2? _looksLikeVmForInTransformation(
      List<DartScope2> filtered) {
    // The VM has a transformation where
    // ```
    // void foo(String x) {
    //   for(dynamic x in bar()) {
    //     if (x == null) continue;
    //     print(x);
    //   }
    // }
    // List bar() => [1, 2, 3];
    // ```
    // is transformed into something like
    // ```
    // {
    //   synthesized core::Iterator<dynamic> :sync-for-iterator =
    //      self::bar().{core::Iterable::iterator}{core::Iterator<dynamic>};
    //   for (;
    //     :sync-for-iterator.{core::Iterator::moveNext}(){() → core::bool}; )
    //     { // <- this block
    //     dynamic x = :sync-for-iterator.
    //       {core::Iterator::current}{dynamic}; // <- the initializer
    //     #L1: // <- this label
    //     { // <- this block
    //       if(x == null)
    //         break #L1;
    //       core::print(x);
    //     }
    //   }
    // }
    // ```
    // where I've marked the 4 places where the offset is the same.
    // In the first 2 cases the "x" will be String, in the other 2 the "x" will
    // be dynamic.
    // Try to filter this so that we say we're where "x" is dynamic.
    if (filtered.length >= 3 &&
        filtered.first.node is Block &&
        filtered[1].node is InstanceGet) {
      Block firstBlock = filtered.first.node as Block;
      InstanceGet instanceGet = filtered[1].node as InstanceGet;
      Expression receiver = instanceGet.receiver;
      if (firstBlock.parent is ForStatement &&
          receiver is VariableGet &&
          receiver.variable.isSynthesized &&
          receiver.variable.name == ":sync-for-iterator") {
        // Matches the case. Return the last block.
        return filtered.last;
      }
    }
    return null;
  }

  static DartScope2? _looksLikeVmFfiTransformation(List<DartScope2> filtered) {
    if (filtered.length > 4 &&
        filtered[0].node is Procedure &&
        filtered[2].node is Field &&
        (filtered[2].node as Field).name.text.endsWith("\$FfiNative\$Ptr")) {
      return filtered[0];
    } else if (filtered.length > 4 &&
        filtered[0].node is Procedure &&
        filtered[2].node is Procedure &&
        (filtered[2].node as Procedure).name.text.endsWith("\$FfiNative")) {
      return filtered[0];
    }

    return null;
  }

  // TODO(jensj): Possibly move the file to package:front_end and use
  // lowering_predicates.dart.
  static DartScope2? _looksLikeLateLoweredField(List<DartScope2> filtered) {
    if (filtered.length > 10 &&
        filtered[0].node is Procedure &&
        filtered[1].node is FunctionNode &&
        filtered[2].node is ReturnStatement &&
        filtered[3].node is Let &&
        filtered[4].node is VariableDeclaration) {
      // The 10 is not special. This has just been observed to contain lots of
      // scopes.
      return filtered[0];
    } else if (filtered.length > 10 &&
        filtered[0].node is Procedure &&
        filtered[1].node is FunctionNode &&
        filtered[2].node is ReturnStatement) {
      // The 10 is not special. This has just been observed to contain lots of
      // scopes.
      for (int i = 3; i < filtered.length - 1; i++) {
        if (filtered[i].node is Let &&
            filtered[i + 1].node is VariableDeclaration) {
          return filtered[0];
        }
      }
    } else if (filtered.length > 15 &&
        filtered[0].node is Procedure &&
        filtered[1].node is FunctionNode) {
      // The 15 is not special. This has just been observed to contain lots of
      // scopes.
      for (int i = 3; i < filtered.length - 1; i++) {
        if (filtered[i].node is Procedure &&
            filtered[i + 1].node is FunctionNode &&
            filtered[i + 2].node is ReturnStatement) {
          for (int j = i + 1; j < filtered.length - 1; j++) {
            if (filtered[j].node is Let &&
                filtered[j + 1].node is VariableDeclaration) {
              return filtered[0];
            }
          }
        }
      }
    }
    // late final field.
    if (filtered.length > 10 &&
        filtered[0].node is Procedure &&
        filtered[1].node is FunctionNode &&
        filtered[2].node is ReturnStatement &&
        filtered[3].node is ConditionalExpression &&
        filtered[4].node is InstanceGet &&
        filtered[5].node is ThisExpression &&
        filtered[6].node is InstanceGet &&
        filtered[7].node is ThisExpression &&
        filtered[8].node is Throw) {
      // The 10 is not special. This has just been observed to contain lots of
      // scopes.
      return filtered[0];
    }

    return null;
  }

  static DartScope2? _looksLikePatternMatching(List<DartScope2> filtered) {
    if (filtered.length > 5 &&
        filtered[0].node is VariableDeclaration &&
        (filtered[0].node as VariableDeclaration).isHoisted) {
      // The 5 is not special. This has just been observed to contain lots of
      // scopes.
      // Pattern matching looks something like this:
      // ```
      // hoisted variable1; // offset x
      // hoisted variable2; // offset y
      // // some initialization stuff for variable1. // offset x
      // // some initialization stuff for variable2. // offset y
      // if (stuff with variable1 ending in the setting of it /* offset x */ &&
      //     stuff with variable2 ending in the setting of it /* offset y */) {
      //   // body
      // }
      // ```
      // Meaning that even if only seeing a hoisted variable as in scope after
      // it has been written for position y in the above example we'll have
      // variable1 in scope for ~half the scopes.
      // We'll assume we've hit this case if we can find a LogicalExpression
      // followed later by a VariableSet.
      // We'll then pick the VariableSet as the scope.
      int foundLogicalExpressionAt = -1;
      for (int i = 1; i < filtered.length; i++) {
        if (filtered[i].node is LogicalExpression) {
          foundLogicalExpressionAt = i;
        }
      }
      if (foundLogicalExpressionAt >= 0) {
        for (int i = foundLogicalExpressionAt + 1; i < filtered.length; i++) {
          if (filtered[i].node is VariableSet) {
            return filtered[i];
          }
        }
      }
    }
    if (filtered.length > 5 &&
        filtered[0].node is VariableDeclaration &&
        filtered[1].node is VariableDeclaration &&
        filtered.last.node is LocalFunctionInvocation) {
      // It's beginning to look a lot like a late lowered nullable pattern
      // matching case.
      VariableDeclaration variable1 = filtered[0].node as VariableDeclaration;
      VariableDeclaration variable2 = filtered[1].node as VariableDeclaration;
      if (variable1.isSynthesized &&
          variable1.name?.startsWith("#") == true &&
          variable2.isSynthesized &&
          variable2.isLowered &&
          variable2.name?.startsWith("#") == true) {
        // Assume so. We'll pick the last one where we have previous variables
        //that already matched in scope.
        return filtered.last;
      }
    }
    if (filtered.length <= 4 &&
        filtered[0].node is VariableDeclaration &&
        (filtered[0].node as VariableDeclaration).isHoisted &&
        filtered.last.node is VariableSet &&
        (filtered.last.node as VariableSet).variable == filtered[0].node) {
      return filtered.last;
    }
    return null;
  }

  static DartScope2? _looksLikeLateLoweredLocal(List<DartScope2> filtered) {
    VariableDeclaration? variable1;
    VariableDeclaration? variable2;
    if (filtered.length > 5 &&
        filtered[0].node is VariableDeclaration &&
        filtered[1].node is VariableDeclaration) {
      // A nullable one, e.g. `late Foo? foo` becomes something like
      // ```
      // Foo? #foo;
      // bool #foo#isSet = false;
      // ```
      variable1 = filtered[0].node as VariableDeclaration;
      variable2 = filtered[1].node as VariableDeclaration;
    } else if (filtered.length > 5 &&
        filtered[0].node is VariableDeclaration &&
        filtered[2].node is VariableDeclaration) {
      // A non-nullable one, e.g. `late Foo foo` becomes something like
      // ```
      // Foo? #foo;
      // Foo #foo#get() => bla bla
      // ```
      variable1 = filtered[0].node as VariableDeclaration;
      variable2 = filtered[2].node as VariableDeclaration;
    }
    if (variable1 != null && variable2 != null) {
      // isLateLoweredLocalName/isLateLoweredLocalSetter/etc is in the CFE so we
      // can't call it from here.
      if (variable1.isLowered &&
          variable1.name?.startsWith("#") == true &&
          variable2.isLowered &&
          variable2.name?.startsWith("#") == true) {
        // Assume it's a late lowering thing with an exuberant amount of nodes
        // with the same offset. Just pick the first one.
        return filtered[0];
      }
    }
    return null;
  }

  static DartScope2? _looksLikeThrowPatternMatchingError(
      List<DartScope2> filtered) {
    if (filtered.length == 5 &&
        filtered[0].node is IfStatement &&
        filtered[1].node is ExpressionStatement &&
        filtered[2].node is Throw &&
        filtered[3].node is ConstructorInvocation &&
        filtered[4].node is StringLiteral) {
      // Something like
      // `var (Foo? a, Foo? b) = someCall();`
      // becomes something like
      // ```
      //if (!(checks for Foo? and lets with assigns etc))
      //  throw new StateError("Pattern matching error");
      // ```
      // Pick the if.
      return filtered[0];
    } else if (filtered.length == 6 &&
        filtered[0].node is Block &&
        filtered[1].node is IfStatement &&
        filtered[2].node is ExpressionStatement &&
        filtered[3].node is Throw &&
        filtered[4].node is ConstructorInvocation &&
        filtered[5].node is StringLiteral) {
      // As above, but inside a block, e.g. if used in a for-in loop like
      // ```
      // for (var Foo(:Whatnot? bar, :Whatnot? baz ) in entries) { [...] }
      // ```
      // Pick the if.
      return filtered[1];
    }
    return null;
  }

  static DartScopeBuilder2 _raw(
      Library library, Uri scriptUri, Class? cls, int offset) {
    DartScopeBuilder2 builder = DartScopeBuilder2._(library, scriptUri, offset);
    if (cls != null) {
      builder.visitClass(cls);
    } else {
      builder.checkClasses = false;
      builder.visitLibrary(library);
    }

    return builder;
  }

  static DartScopeBuilder2 _rawNoClass(
      Library library, Uri scriptUri, int offset) {
    DartScopeBuilder2 builder = DartScopeBuilder2._(library, scriptUri, offset);
    builder.visitLibrary(library);
    return builder;
  }

  static List<DartScope2> findScopeFromOffsetAndClassRawForTesting(
          Library library, Uri scriptUri, Class? cls, int offset) =>
      _raw(library, scriptUri, cls, offset).findScopes;
}
