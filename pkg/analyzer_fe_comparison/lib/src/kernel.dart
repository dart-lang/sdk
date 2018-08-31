// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer_fe_comparison/src/comparison_node.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/kernel_generator.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart';

/// Compiles the given [inputs] to kernel using the front_end, and returns a
/// [ComparisonNode] representing them.
Future<ComparisonNode> driveKernel(
    List<Uri> inputs, Uri packagesFileUri, Uri platformUri) async {
  var targetFlags = TargetFlags(strongMode: true, syncAsync: true);
  var target = NoneTarget(targetFlags);
  var fileSystem = StandardFileSystem.instance;

  var compilerOptions = CompilerOptions()
    ..fileSystem = fileSystem
    ..packagesFileUri = packagesFileUri
    ..sdkSummary = platformUri
    ..strongMode = true
    ..target = target
    ..throwOnErrorsForDebugging = true
    ..embedSourceText = false;

  var component = await kernelForComponent(inputs, compilerOptions);
  return component.accept(new _KernelVisitor(inputs.toSet()));
}

/// Visitor for serializing a kernel representation of a program into
/// ComparisonNodes.
class _KernelVisitor extends TreeVisitor<ComparisonNode> {
  final Set<Uri> _inputs;

  _KernelVisitor(this._inputs);

  @override
  ComparisonNode defaultTreeNode(TreeNode node) {
    throw new UnimplementedError('KernelVisitor: ${node.runtimeType}');
  }

  @override
  ComparisonNode visitClass(Class class_) {
    if (class_.isAnonymousMixin) return null;
    var kind = class_.isEnum ? 'Enum' : 'Class';
    // TODO(paulberry): handle fields from Class
    return ComparisonNode('$kind ${class_.name}');
  }

  @override
  ComparisonNode visitComponent(Component component) {
    return ComparisonNode.sorted(
        'Component',
        component.libraries
            .where((library) => _inputs.contains(library.importUri))
            .map<ComparisonNode>((library) => library.accept(this)));
  }

  @override
  ComparisonNode visitLibrary(Library library) {
    var children = <ComparisonNode>[];
    if (library.name != null) {
      children.add(ComparisonNode('name=${library.name}'));
    }
    for (var class_ in library.classes) {
      var childNode = class_.accept(this);
      if (childNode != null) {
        children.add(childNode);
      }
    }
    // TODO(paulberry): handle more fields from Library
    return ComparisonNode.sorted(library.importUri.toString(), children);
  }
}
