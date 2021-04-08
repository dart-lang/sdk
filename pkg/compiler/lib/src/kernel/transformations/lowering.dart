// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'factory_specializer.dart';
import 'late_lowering.dart';

/// dart2js-specific lowering transformations and optimizations combined into a
/// single transformation pass.
///
/// Each transformation is applied locally to AST nodes of certain types after
/// transforming children nodes.
void transformLibraries(
    List<Library> libraries, CoreTypes coreTypes, ClassHierarchy hierarchy) {
  final transformer = _Lowering(coreTypes, hierarchy);
  libraries.forEach(transformer.visitLibrary);
}

class _Lowering extends Transformer {
  final FactorySpecializer factorySpecializer;
  final LateLowering _lateLowering;

  Member _currentMember;

  _Lowering(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : factorySpecializer = FactorySpecializer(coreTypes, hierarchy),
        _lateLowering = LateLowering(coreTypes.index);

  @override
  TreeNode defaultMember(Member node) {
    _currentMember = node;
    return super.defaultMember(node);
  }

  @override
  TreeNode visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    return factorySpecializer.transformStaticInvocation(node, _currentMember);
  }

  @override
  TreeNode visitVariableDeclaration(VariableDeclaration node) {
    node.transformChildren(this);
    return _lateLowering.transformVariableDeclaration(node, _currentMember);
  }

  @override
  TreeNode visitVariableGet(VariableGet node) {
    node.transformChildren(this);
    return _lateLowering.transformVariableGet(node, _currentMember);
  }

  @override
  TreeNode visitVariableSet(VariableSet node) {
    node.transformChildren(this);
    return _lateLowering.transformVariableSet(node, _currentMember);
  }
}
