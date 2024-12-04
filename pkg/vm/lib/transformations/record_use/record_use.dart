// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show relativizeUri;
import 'package:collection/collection.dart';
import 'package:kernel/ast.dart' as ast;
import 'package:pub_semver/pub_semver.dart';
import 'package:record_use/record_use_internal.dart';
import 'package:vm/metadata/loading_units.dart';
import 'package:vm/transformations/record_use/record_call.dart';
import 'package:vm/transformations/record_use/record_instance.dart';

/// Collect calls to methods annotated with `@RecordUse`.
///
/// Identify and collect all calls to static methods annotated in the given
/// [component]. This requires the deferred loading to be handled already to
/// also save which loading unit the call is made in. Write the result into a
/// JSON at [recordedUsagesFile].
///
/// The purpose of this feature is to be able to pass the recorded information
/// to packages in a post-compilation step, allowing them to remove or modify
/// assets based on the actual usage in the code prior to bundling in the final
/// application.
ast.Component transformComponent(
  ast.Component component,
  Uri recordedUsagesFile,
  Uri source,
) {
  final tag = LoadingUnitsMetadataRepository.repositoryTag;
  final loadingMetadata =
      component.metadata[tag] as LoadingUnitsMetadataRepository;
  final loadingUnits = loadingMetadata.mapping[component]?.loadingUnits ?? [];

  final staticCallRecorder = CallRecorder(source, loadingUnits);
  final instanceUseRecorder = InstanceRecorder(source, loadingUnits);
  component.accept(_RecordUseVisitor(
    staticCallRecorder,
    instanceUseRecorder,
  ));

  final usages = _usages(
    staticCallRecorder.foundCalls,
    instanceUseRecorder.foundInstances,
  );
  var usagesStorageFormat = usages.toJson();
  File.fromUri(recordedUsagesFile).writeAsStringSync(
    JsonEncoder.withIndent('  ').convert(usagesStorageFormat),
  );

  return component;
}

class _RecordUseVisitor extends ast.RecursiveVisitor {
  final CallRecorder staticCallRecorder;
  final InstanceRecorder instanceUseRecorder;

  _RecordUseVisitor(
    this.staticCallRecorder,
    this.instanceUseRecorder,
  );

  @override
  void visitStaticInvocation(ast.StaticInvocation node) {
    staticCallRecorder.recordStaticInvocation(node);

    super.visitStaticInvocation(node);
  }

  @override
  void visitConstantExpression(ast.ConstantExpression node) {
    staticCallRecorder.recordConstantExpression(node);
    instanceUseRecorder.recordConstantExpression(node);

    super.visitConstantExpression(node);
  }
}

UsageRecord _usages(
  Iterable<Usage<CallReference>> calls,
  Iterable<Usage<InstanceReference>> instances,
) {
  return UsageRecord(
    metadata: Metadata(
      comment:
          'Recorded usages of objects tagged with a `RecordUse` annotation',
      version: Version(0, 1, 0),
    ),
    calls: calls.toList(),
    instances: instances.toList(),
  );
}

Constant evaluateConstant(ast.Constant constant) => switch (constant) {
      ast.NullConstant() => NullConstant(),
      ast.BoolConstant() => BoolConstant(constant.value),
      ast.IntConstant() => IntConstant(constant.value),
      ast.DoubleConstant() => _unsupported('DoubleConstant'),
      ast.StringConstant() => StringConstant(constant.value),
      ast.SymbolConstant() => StringConstant(constant.name),
      ast.MapConstant() => MapConstant(Map.fromEntries(
          constant.entries.map((e) => MapEntry(
              (e.key as ast.StringConstant).value, evaluateConstant(e.value))),
        )),
      ast.ListConstant() =>
        ListConstant(constant.entries.map(evaluateConstant).toList()),
      // The following are not supported, but theoretically could be, so they
      // are listed explicitly here.
      ast.InstanceConstant() => _unsupported('InstanceConstant'),
      ast.AuxiliaryConstant() => _unsupported('AuxiliaryConstant'),
      ast.SetConstant() => _unsupported('SetConstant'),
      ast.RecordConstant() => _unsupported('RecordConstant'),
      ast.InstantiationConstant() => _unsupported('InstantiationConstant'),
      ast.TearOffConstant() => _unsupported('TearOffConstant'),
      ast.TypedefTearOffConstant() => _unsupported('TypedefTearOffConstant'),
      ast.TypeLiteralConstant() => _unsupported('TypeLiteralConstant'),
      ast.UnevaluatedConstant() => _unsupported('UnevaluatedConstant'),
    };

Constant evaluateLiteral(ast.BasicLiteral expression) => switch (expression) {
      ast.NullLiteral() => NullConstant(),
      ast.IntLiteral() => IntConstant(expression.value),
      ast.BoolLiteral() => BoolConstant(expression.value),
      ast.StringLiteral() => StringConstant(expression.value),
      ast.DoubleLiteral() => _unsupported('DoubleLiteral'),
      ast.BasicLiteral() => _unsupported(expression.runtimeType.toString()),
    };

Never _unsupported(String constantType) =>
    throw UnsupportedError('$constantType is not supported for recording.');

extension RecordUseLocation on ast.Location {
  Location recordLocation(Uri source) => Location(
        uri: relativizeUri(source, this.file, Platform.isWindows),
        line: line,
        column: column,
      );
}

String getImportUri(ast.Library library, Uri source) {
  String file;
  final importUri = library.importUri;
  if (importUri.isScheme('file')) {
    file = relativizeUri(source, library.fileUri, Platform.isWindows);
  } else {
    file = library.importUri.toString();
  }
  return file;
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
  List<LoadingUnit> loadingUnits,
) {
  final importUri = library.importUri.toString();
  return loadingUnits
          .firstWhereOrNull((unit) => unit.libraryUris.contains(importUri))
          ?.id ??
      -1;
}

int loadingUnitForNode(ast.TreeNode node, List<LoadingUnit> loadingUnits) {
  final library = enclosingLibrary(node)!;
  return _loadingUnitForLibrary(library, loadingUnits);
}
