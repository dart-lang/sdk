// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:front_end/src/api_prototype/lowering_predicates.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:record_use/record_use_internal.dart';
import 'package:vm/metadata/loading_units.dart' as vm_metadata;
import 'package:vm/transformations/record_use/record_call.dart';
import 'package:vm/transformations/record_use/record_instance.dart';

/// Maps a kernel node to the a string representing the loading unit it belongs
/// to. Different backends may represent loading units differently.
typedef LoadingUnitLookup = LoadingUnit Function(ast.TreeNode node);

LoadingUnitLookup _getDefaultLoadingUnitLookup(ast.Component component) {
  final loadingMetadata =
      component.metadata[vm_metadata
              .LoadingUnitsMetadataRepository
              .repositoryTag]
          as vm_metadata.LoadingUnitsMetadataRepository;
  final loadingUnits = loadingMetadata.mapping[component]?.loadingUnits ?? [];
  return (ast.TreeNode node) => LoadingUnit(
    _loadingUnitForLibrary(enclosingLibrary(node)!, loadingUnits).toString(),
  );
}

/// Collect calls and constant instances annotated with `@RecordUse`.
///
/// Identify and collect all calls to static methods and loadings of constant
/// instances of classes annotated in reachable code in the given [component].
/// This requires the deferred loading to be handled already to also save which
/// loading unit the usage is made in. Write the result into a JSON at
/// [recordedUsagesFile].
///
/// Only usages in reachable code (executable code) are tracked.
/// Usages appearing within metadata (annotations) are ignored.
///
/// The purpose of this feature is to be able to pass the recorded information
/// to packages in a post-compilation step, allowing them to remove or modify
/// assets based on the actual usage in the code prior to bundling in the final
/// application.
ast.Component transformComponent(
  ast.Component component,
  Uri recordedUsagesFile, {
  LoadingUnitLookup? loadingUnitLookup,
}) {
  loadingUnitLookup ??= _getDefaultLoadingUnitLookup(component);

  final callRecorder = CallRecorder(loadingUnitLookup);
  final instanceRecorder = InstanceRecorder(loadingUnitLookup);
  component.accept(_RecordUseVisitor(callRecorder, instanceRecorder));

  final usages = _usages(
    callRecorder.callsForMethod,
    instanceRecorder.instancesForClass,
  );
  final usagesStorageFormat = usages.toJson();
  File.fromUri(recordedUsagesFile).writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(usagesStorageFormat),
  );

  return component;
}

class _RecordUseVisitor extends ast.RecursiveVisitor {
  final CallRecorder staticCallRecorder;
  final InstanceRecorder instanceUseRecorder;

  _RecordUseVisitor(this.staticCallRecorder, this.instanceUseRecorder);

  @override
  void visitProcedure(ast.Procedure node) {
    // Extension member tear-offs call the implementation. We skip them here
    // to avoid recording the implementation call as a usage, as the usage is
    // already recorded by the call to the extension member tear-off itself.
    if (isExtensionMemberTearOff(node)) {
      return;
    }
    super.visitProcedure(node);
  }

  @override
  void visitStaticInvocation(ast.StaticInvocation node) {
    if (_isAnnotation(node)) return;

    staticCallRecorder.recordStaticInvocation(node);

    super.visitStaticInvocation(node);
  }

  @override
  void visitConstantExpression(ast.ConstantExpression node) {
    if (_isAnnotation(node)) return;

    staticCallRecorder.recordConstantExpression(node);
    instanceUseRecorder.recordConstantExpression(node);

    super.visitConstantExpression(node);
  }

  @override
  void defaultExpression(ast.Expression node) {
    // Prune the traversal of annotations. Since we catch the outermost
    // expression of an annotation here, we don't need to check sub-expressions
    // recursively in [_isAnnotation].
    if (_isAnnotation(node)) return;
    super.defaultExpression(node);
  }

  /// Returns whether [node] is a top-level expression in an annotation list.
  ///
  /// This only checks the immediate parent because [_RecordUseVisitor] relies on
  /// [defaultExpression] catching annotations at the outermost expression level
  /// and pruning the traversal into any sub-expressions.
  static bool _isAnnotation(ast.TreeNode? node) {
    final parent = node?.parent;
    return parent is ast.Annotatable && parent.annotations.contains(node);
  }
}

Recordings _usages(
  Map<Definition, List<CallReference>> calls,
  Map<Definition, List<InstanceReference>> instances,
) {
  return Recordings(
    metadata: Metadata(
      comment:
          'Recorded usages of objects tagged with a `RecordUse` annotation',
      version: version,
    ),
    calls: calls,
    instances: instances,
  );
}

Constant evaluateConstant(ast.Constant constant) => switch (constant) {
  ast.NullConstant() => NullConstant(),
  ast.BoolConstant() => BoolConstant(constant.value),
  ast.IntConstant() => IntConstant(constant.value),
  ast.DoubleConstant() => UnsupportedConstant(
    'Double literals are not supported for recording.',
  ),
  ast.StringConstant() => StringConstant(constant.value),
  ast.SymbolConstant() => StringConstant(constant.name),
  ast.MapConstant() => MapConstant(
    constant.entries
        .map(
          (e) => MapEntry(evaluateConstant(e.key), evaluateConstant(e.value)),
        )
        .toList(),
  ),
  ast.ListConstant() => ListConstant(
    constant.entries.map(evaluateConstant).toList(),
  ),
  ast.InstanceConstant() =>
    constant.classNode.isEnum
        ? evaluateEnumConstant(constant)
        : evaluateInstanceConstant(constant),
  ast.RecordConstant() => evaluateRecordConstant(constant),
  // The following are not supported, but theoretically could be, so they
  // are listed explicitly here.
  ast.AuxiliaryConstant() => _unsupported('AuxiliaryConstant'),
  ast.SetConstant() => UnsupportedConstant(
    'Set literals are not supported for recording.',
  ),
  ast.InstantiationConstant() => UnsupportedConstant(
    'Generic instantiations are not supported for recording.',
  ),
  ast.TearOffConstant() => UnsupportedConstant(
    'Function/Method tear-offs are not supported for recording.',
  ),
  ast.TypedefTearOffConstant() => UnsupportedConstant(
    'Typedef tear-offs are not supported for recording.',
  ),
  ast.TypeLiteralConstant() => UnsupportedConstant(
    'Type literals are not supported for recording.',
  ),
  ast.UnevaluatedConstant() => UnsupportedConstant(
    'Unevaluated constants are not supported for recording.',
  ),
};

Constant evaluateLiteral(ast.BasicLiteral expression) => switch (expression) {
  ast.NullLiteral() => NullConstant(),
  ast.IntLiteral() => IntConstant(expression.value),
  ast.BoolLiteral() => BoolConstant(expression.value),
  ast.StringLiteral() => StringConstant(expression.value),
  ast.DoubleLiteral() => UnsupportedConstant(
    'Double literals are not supported for recording.',
  ),
  ast.BasicLiteral() => _unsupported(expression.runtimeType.toString()),
};

EnumConstant evaluateEnumConstant(ast.InstanceConstant constant) {
  int? index;
  String? name;
  final fields = <String, Constant>{};
  for (final entry in constant.fieldValues.entries) {
    final fieldName = entry.key.asField.name.text;
    if (fieldName == enumIndexFieldName) {
      index = (entry.value as ast.IntConstant).value;
    } else if (fieldName == enumNameFieldName) {
      name = (entry.value as ast.StringConstant).value;
    } else {
      fields[fieldName] = evaluateConstant(entry.value);
    }
  }
  return EnumConstant(
    definition: _definitionFromClass(constant.classNode),
    index: index!,
    name: name!,
    fields: fields,
  );
}

InstanceConstant evaluateInstanceConstant(ast.InstanceConstant constant) =>
    InstanceConstant(
      definition: _definitionFromClass(constant.classNode),
      fields: constant.fieldValues.map(
        (key, value) =>
            MapEntry(key.asField.name.text, evaluateConstant(value)),
      ),
    );

RecordConstant evaluateRecordConstant(ast.RecordConstant constant) {
  return RecordConstant(
    positional: constant.positional.map(evaluateConstant).toList(),
    named: constant.named.map(
      (key, value) => MapEntry(key, evaluateConstant(value)),
    ),
  );
}

UnsupportedConstant _unsupported(String constantType) =>
    UnsupportedConstant('$constantType is not supported for recording.');

Definition _definitionFromClass(ast.Class cls) {
  final enclosingLibrary = cls.enclosingLibrary;
  final importUri = enclosingLibrary.importUri.toString();

  return Definition(importUri, [
    Name(
      cls.name,
      kind: cls.isEnum ? DefinitionKind.enumKind : DefinitionKind.classKind,
    ),
  ]);
}

ast.Library? enclosingLibrary(ast.TreeNode node) {
  while (node is! ast.Library) {
    final parent = node.parent;
    if (parent == null) return null;
    node = parent;
  }
  return node;
}

int _loadingUnitForLibrary(
  ast.Library library,
  List<vm_metadata.LoadingUnit> loadingUnits,
) {
  final importUri = library.importUri.toString();
  return loadingUnits
          .firstWhereOrNull((unit) => unit.libraryUris.contains(importUri))
          ?.id ??
      -1;
}
