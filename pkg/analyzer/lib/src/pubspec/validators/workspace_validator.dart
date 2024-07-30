// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Validates the values of the optional `workspace` field.
void workspaceValidator(PubspecValidationContext ctx) {
  var contents = ctx.contents;
  if (contents is! YamlMap) return;
  var workspaceField = contents.nodes[PubspecField.WORKSPACE_FIELD];
  if (workspaceField == null) return;
  if (workspaceField is! YamlList) {
    ctx.reportErrorForNode(
      workspaceField,
      PubspecWarningCode.WORKSPACE_FIELD_NOT_LIST,
    );
    return;
  }

  for (var directoryField in workspaceField.nodes) {
    if (directoryField is YamlScalar) {
      var entry = directoryField.valueOrThrow;
      if (entry is! String) {
        ctx.reportErrorForNode(
          directoryField,
          PubspecWarningCode.WORKSPACE_VALUE_NOT_STRING,
        );
        return;
      }
      _validateDirectoryPath(ctx, entry, directoryField);
    } else {
      ctx.reportErrorForNode(
          directoryField, PubspecWarningCode.WORKSPACE_VALUE_NOT_STRING);
    }
  }
}

/// Validates that [pathValue] is a sub directory of the directory containing
/// the pubspec.yaml file, and that it exists, reporting any error on
/// [errorField].
void _validateDirectoryPath(
    PubspecValidationContext ctx, String pathValue, YamlScalar errorField) {
  var context = ctx.provider.pathContext;
  var packageRoot = context.dirname(ctx.source.fullName);
  var packageRootFolder = ctx.provider.getFolder(packageRoot);
  var normalizedEntry = context.joinAll(path.posix.split(pathValue));
  var dirPath = context.join(packageRoot, normalizedEntry);
  // Check if given path is a sub directory of the package root.
  if (!packageRootFolder.contains(dirPath)) {
    ctx.reportErrorForNode(errorField,
        PubspecWarningCode.WORKSPACE_VALUE_NOT_SUBDIRECTORY, [packageRoot]);
    return;
  }
  var subDirectory = ctx.provider.getFolder(dirPath);
  if (!subDirectory.exists) {
    ctx.reportErrorForNode(
        errorField, PubspecWarningCode.PATH_DOES_NOT_EXIST, [pathValue]);
  }
}
