// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Validates the values of the optional `workspace` field.
void workspaceValidator(PubspecValidationContext ctx) {
  var contents = ctx.contents;
  if (contents is! YamlMap) return;
  var workspaceField = contents.nodes[PubspecField.WORKSPACE_FIELD];
  if (workspaceField == null) return;
  if (workspaceField is! YamlList) {
    ctx.reportErrorForNode(workspaceField, diag.workspaceFieldNotList);
    return;
  }

  for (var directoryField in workspaceField.nodes) {
    if (directoryField is YamlScalar) {
      var entry = directoryField.valueOrThrow;
      if (entry is! String) {
        ctx.reportErrorForNode(directoryField, diag.workspaceValueNotString);
        return;
      }
      _validateDirectoryPath(ctx, entry, directoryField);
    } else {
      ctx.reportErrorForNode(directoryField, diag.workspaceValueNotString);
    }
  }
}

/// Validates that [pathValue] is a sub directory of the directory containing
/// the pubspec.yaml file, and that it exists, reporting any error on
/// [errorField].
///
/// For glob patterns, validates only that the base directory (prefix before
/// the first wildcard segment) exists.
void _validateDirectoryPath(
  PubspecValidationContext ctx,
  String pathValue,
  YamlScalar errorField,
) {
  var context = ctx.provider.pathContext;
  var packageRoot = context.dirname(ctx.source.fullName);
  var packageRootFolder = ctx.provider.getFolder(packageRoot);
  var normalizedEntry = context.joinAll(path.posix.split(pathValue));
  var dirPath = context.join(packageRoot, normalizedEntry);
  if (!packageRootFolder.contains(dirPath)) {
    ctx.reportErrorForNode(
      errorField,
      diag.workspaceValueNotSubdirectory.withArguments(path: packageRoot),
    );
    return;
  }
  if (_isGlobPattern(pathValue)) {
    var basePath = _globBasePath(pathValue);
    if (basePath != null) {
      var normalizedBase = context.joinAll(path.posix.split(basePath));
      var baseDir = ctx.provider.getFolder(
        context.join(packageRoot, normalizedBase),
      );
      if (!baseDir.exists) {
        ctx.reportErrorForNode(
          errorField,
          diag.pathDoesNotExist.withArguments(path: basePath),
        );
      }
    }
    return;
  }
  var subDirectory = ctx.provider.getFolder(dirPath);
  if (!subDirectory.exists) {
    ctx.reportErrorForNode(
      errorField,
      diag.pathDoesNotExist.withArguments(path: pathValue),
    );
  }
}

bool _isGlobPattern(String pathValue) => Glob.quote(pathValue) != pathValue;

String? _globBasePath(String pathValue) {
  var parts = path.posix.split(pathValue);
  var nonGlobParts = <String>[];
  for (var part in parts) {
    if (_isGlobPattern(part)) break;
    nonGlobParts.add(part);
  }
  if (nonGlobParts.isEmpty) return null;
  return path.posix.joinAll(nonGlobParts);
}
