// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.deferred_load_data;

import 'package:kernel/ast.dart' as ir;

import '../compiler.dart' show Compiler;
import '../common_elements.dart';
import '../constants/values.dart' show ConstantValue;
import '../deferred_load.dart';
import '../elements/entities.dart';
import 'element_map.dart';

class KernelDeferredLoadTask extends DeferredLoadTask {
  KernelToElementMapForImpact _elementMap;

  KernelDeferredLoadTask(Compiler compiler, this._elementMap) : super(compiler);

  @override
  Iterable<ImportEntity> importsTo(Entity element, LibraryEntity library) {
    if (element is! MemberEntity) return const <ImportEntity>[];
    List<ImportEntity> imports = [];
    ir.Library source = _elementMap.getLibraryNode(library);
    ir.Member member = _elementMap.getMemberDefinition(element).node;
    for (ir.LibraryDependency dependency in source.dependencies) {
      if (dependency.isExport) continue;
      if (!_isVisible(dependency.combinators, member.name.name)) continue;
      if (member.enclosingLibrary == dependency.targetLibrary ||
          dependency.targetLibrary.additionalExports
              .any((ir.Reference ref) => ref.node == member)) {
        imports.add(_elementMap.getImport(dependency));
      }
    }
    return imports;
  }

  @override
  void checkForDeferredErrorCases(LibraryEntity library) {
    // Nothing to do. The FE checks for error cases upfront.
  }

  @override
  void collectConstantsInBody(
      covariant MemberEntity element, Set<ConstantValue> constants) {
    ir.Member node = _elementMap.getMemberDefinition(element).node;
    node.accept(new ConstantCollector(_elementMap, constants));
  }

  /// Adds extra dependencies coming from mirror usage.
  @override
  void addDeferredMirrorElements(WorkQueue queue) {
    throw new UnsupportedError(
        "KernelDeferredLoadTask.addDeferredMirrorElements");
  }

  /// Add extra dependencies coming from mirror usage in [root] marking it with
  /// [newSet].
  @override
  void addMirrorElementsForLibrary(
      WorkQueue queue, LibraryEntity root, ImportSet newSet) {
    throw new UnsupportedError(
        "KernelDeferredLoadTask.addMirrorElementsForLibrary");
  }
}

/// Returns whether [name] would be visible according to the given list of
/// show/hide [combinators].
bool _isVisible(List<ir.Combinator> combinators, String name) {
  for (var c in combinators) {
    if (c.isShow && !c.names.contains(name)) return false;
    if (c.isHide && c.names.contains(name)) return false;
  }
  return true;
}

class ConstantCollector extends ir.RecursiveVisitor {
  final KernelToElementMapForImpact elementMap;
  final Set<ConstantValue> constants;

  ConstantCollector(this.elementMap, this.constants);

  CommonElements get commonElements => elementMap.commonElements;

  void add(ir.Expression node) =>
      constants.add(elementMap.getConstantValue(node));

  @override
  void visitIntLiteral(ir.IntLiteral literal) {}

  @override
  void visitDoubleLiteral(ir.DoubleLiteral literal) {}

  @override
  void visitBoolLiteral(ir.BoolLiteral literal) {}

  @override
  void visitStringLiteral(ir.StringLiteral literal) {}

  @override
  void visitSymbolLiteral(ir.SymbolLiteral literal) => add(literal);

  @override
  void visitNullLiteral(ir.NullLiteral literal) {}

  @override
  void visitListLiteral(ir.ListLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitListLiteral(literal);
    }
  }

  @override
  void visitMapLiteral(ir.MapLiteral literal) {
    if (literal.isConst) {
      add(literal);
    } else {
      super.visitMapLiteral(literal);
    }
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    if (node.isConst) {
      add(node);
    } else {
      super.visitConstructorInvocation(node);
    }
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    // Do not recurse - closures are visited separately.
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    // Do not recurse - closures are visited separately.
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    if (node.type is! ir.TypeParameterType) add(node);
  }
}
