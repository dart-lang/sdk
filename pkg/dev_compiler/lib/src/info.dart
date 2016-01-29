// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines static information collected by the type checker and used later by
/// emitters to generate code.

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/parser.dart';

import 'utils.dart' as utils;
import 'package:analyzer/src/task/strong/info.dart';
export 'package:analyzer/src/task/strong/info.dart';

/// Represents a summary of the results collected by running the program
/// checker.
class CheckerResults {
  final List<LibraryInfo> libraries;
  final bool failure;

  CheckerResults(this.libraries, this.failure);
}

/// Computed information about each library.
class LibraryInfo {
  /// Canonical name of the library. This is unfortunately not derived from the
  /// library directive as it doesn't have any meaningful rules enforced.
  /// Instead, this is inferred from the path to the file defining the library.
  final String name;

  /// Corresponding analyzer element.
  final LibraryElement library;

  LibraryInfo(library)
      : library = library,
        name = utils.canonicalLibraryName(library);
}

class LibraryUnit {
  final CompilationUnit library;
  final List<CompilationUnit> parts;

  LibraryUnit(this.library, this.parts);

  Iterable<CompilationUnit> get libraryThenParts sync* {
    yield library;
    yield* parts;
  }

  Iterable<CompilationUnit> get partsThenLibrary sync* {
    yield* parts;
    yield library;
  }

  /// Creates a clone of this library's AST.
  LibraryUnit clone() {
    return new LibraryUnit(
        _cloneUnit(library), parts.map(_cloneUnit).toList(growable: false));
  }

  static CompilationUnit _cloneUnit(CompilationUnit oldNode) {
    var newNode = oldNode.accept(new _AstCloner());
    ResolutionCopier.copyResolutionData(oldNode, newNode);
    return newNode;
  }
}

class _AstCloner extends AstCloner {
  void _cloneProperties(AstNode clone, AstNode node) {
    if (clone != null) {
      CoercionInfo.set(clone, CoercionInfo.get(node));
      DynamicInvoke.set(clone, DynamicInvoke.get(node));
    }
  }

  @override
  AstNode cloneNode(AstNode node) {
    var clone = super.cloneNode(node);
    _cloneProperties(clone, node);
    return clone;
  }

  @override
  List cloneNodeList(List list) {
    var clone = super.cloneNodeList(list);
    for (int i = 0, len = list.length; i < len; i++) {
      _cloneProperties(clone[i], list[i]);
    }
    return clone;
  }

  // TODO(jmesserly): as a workaround for analyzer <0.26.0-alpha.1.
  // ResolutionCopier won't copy the type, so we do it here.
  @override
  AwaitExpression visitAwaitExpression(AwaitExpression node) {
    var clone = super.visitAwaitExpression(node);
    clone.staticType = node.staticType;
    clone.propagatedType = node.propagatedType;
    return clone;
  }
}
