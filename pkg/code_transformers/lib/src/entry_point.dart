// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:analyzer/analyzer.dart' as analyzer;
import 'package:analyzer/src/generated/ast.dart';
import 'package:barback/barback.dart';

/// Checks to see if the provided AssetId is a Dart file in a directory which
/// may contain entry points.
///
/// Directories are considered entry points if they are Dart files located in
/// web/, test/, benchmark/ or example/.
bool isPossibleDartEntryId(AssetId id) {
  if (id.extension != '.dart') return false;

  return ['benchmark', 'example', 'test', 'web']
      .any((dir) => id.path.startsWith("$dir/"));
}

/// Checks to see if the provided Asset is possibly a Dart entry point.
///
/// Assets are considered entry points if they pass [isPossibleDartEntryId] and
/// have a main() method.
///
/// Because this only analyzes the primary asset this may return true for files
/// which are not dart entries if the file does not have a main() but does have
/// parts or exports.
Future<bool> isPossibleDartEntry(Asset asset) {
  if (!isPossibleDartEntryId(asset.id)) return new Future.value(false);

  return asset.readAsString().then((contents) {
    return _couldBeEntrypoint(
        analyzer.parseCompilationUnit(contents, suppressErrors: true));
  });
}

bool _couldBeEntrypoint(CompilationUnit compilationUnit) {
  // Allow two or fewer arguments so that entrypoints intended for use with
  // [spawnUri] get counted.
  var hasMain = compilationUnit.declarations.any((node) =>
      node is FunctionDeclaration &&
      node.name.name == "main" &&
      node.functionExpression.parameters.parameters.length <= 2);

  if (hasMain) return true;

  // If it has an export or a part, assume the worst- that the main could be
  // in there.
  // We avoid loading those since this can be run from isPrimaryAsset calls
  // where we do not have access to other sources.
  return compilationUnit.directives.any((node) =>
      node is ExportDirective || node is PartDirective);
}
