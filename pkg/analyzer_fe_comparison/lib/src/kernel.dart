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
    var children = <ComparisonNode>[];
    if (class_.isEnum) {
      for (var field in class_.fields) {
        if (!field.isStatic) continue;
        if (field.name.name == 'values') continue;
        // TODO(paulberry): handle index
        children.add(ComparisonNode('EnumValue ${field.name.name}'));
      }
    } else {
      _visitList(class_.fields, children);
      _visitList(class_.constructors, children);
      _visitList(class_.procedures, children);
    }
    // TODO(paulberry): handle more fields from Class
    return ComparisonNode.sorted('$kind ${class_.name}', children);
  }

  @override
  ComparisonNode visitComponent(Component component) {
    var children = <ComparisonNode>[];
    _visitList(component.libraries, children);
    return ComparisonNode.sorted('Component', children);
  }

  @override
  ComparisonNode visitConstructor(Constructor constructor) {
    if (constructor.isSynthetic) return null;
    var name = constructor.name.name;
    if (name.isEmpty) {
      name = '(unnamed)';
    }
    // TODO(paulberry): handle fields from Constructor
    return ComparisonNode('Constructor $name');
  }

  @override
  ComparisonNode visitField(Field field) {
    if (field.name.name == '_redirecting#') return null;
    // TODO(paulberry): handle fields from Field
    return ComparisonNode('Field ${field.name.name}');
  }

  @override
  ComparisonNode visitLibrary(Library library) {
    if (!_inputs.contains(library.importUri)) return null;
    var children = <ComparisonNode>[];
    if (library.name != null) {
      children.add(ComparisonNode('name=${library.name}'));
    }
    _visitList(library.typedefs, children);
    _visitList(library.classes, children);
    _visitList(library.procedures, children);
    _visitList(library.fields, children);
    // TODO(paulberry): handle more fields from Library
    return ComparisonNode.sorted(library.importUri.toString(), children);
  }

  @override
  ComparisonNode visitProcedure(Procedure procedure) {
    if (procedure.isForwardingStub) return null;
    // TODO(paulberry): add an annotation to the ComparisonNode when the
    // procedure is a factory.
    var kind = procedure.isFactory
        ? 'Constructor'
        : procedure.kind.toString().replaceAll('ProcedureKind.', '');
    var name = procedure.name.name;
    if (name.isEmpty) {
      name = '(unnamed)';
    }
    // TODO(paulberry): handle fields from Procedure
    return ComparisonNode('$kind $name');
  }

  @override
  ComparisonNode visitTypedef(Typedef typedef) {
    // TODO(paulberry): handle fields from Typedef
    return ComparisonNode('Typedef ${typedef.name}');
  }

  /// Transforms all the nodes in [src] to [ComparisonNode]s, and adds those
  /// with non-null results to [dst].
  void _visitList(List<TreeNode> src, List<ComparisonNode> dst) {
    for (var item in src) {
      ComparisonNode result = item.accept(this);
      if (result != null) {
        dst.add(result);
      }
    }
  }
}
