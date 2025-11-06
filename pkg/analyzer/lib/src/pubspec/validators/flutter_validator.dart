// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Validates the value of the optional `flutter` field.
void flutterValidator(PubspecValidationContext ctx) {
  var contents = ctx.contents;
  if (contents is! YamlMap) return;
  var flutterField = contents.nodes[PubspecField.FLUTTER_FIELD];
  if (flutterField == null) return;
  if (flutterField is! YamlMap) {
    // Allow an empty `flutter:` section; explicitly fail on a non-empty,
    // non-map one.
    if (flutterField.value == null) {
    } else {
      ctx.reportErrorForNode(
        flutterField,
        PubspecWarningCode.flutterFieldNotMap,
      );
    }
    return;
  }

  var assetsField = flutterField.nodes[PubspecField.ASSETS_FIELD];
  if (assetsField == null) return;
  if (assetsField is! YamlList) {
    ctx.reportErrorForNode(assetsField, PubspecWarningCode.assetFieldNotList);
    return;
  }

  for (var assetField in assetsField.nodes) {
    if (assetField is YamlScalar) {
      var entry = assetField.valueOrThrow;
      if (entry is! String) {
        ctx.reportErrorForNode(
          assetField,
          PubspecWarningCode.assetNotStringOrMap,
        );
        return;
      }

      _validateAssetPath(ctx, entry, assetField);
    } else if (assetField is YamlMap) {
      var pathField = assetField.nodes[PubspecField.ASSET_PATH_FIELD];
      if (pathField == null) {
        ctx.reportErrorForNode(assetField, PubspecWarningCode.assetMissingPath);
      } else if (pathField is! YamlScalar) {
        ctx.reportErrorForNode(
          pathField,
          PubspecWarningCode.assetPathNotString,
        );
      } else {
        var entry = pathField.valueOrThrow;
        if (entry is! String) {
          ctx.reportErrorForNode(pathField, PubspecWarningCode.assetNotString);
          return;
        }

        _validateAssetPath(ctx, entry, pathField);
      }
    } else {
      ctx.reportErrorForNode(
        assetField,
        PubspecWarningCode.assetNotStringOrMap,
      );
    }
  }

  if (flutterField.length > 1) {
    // TODO(brianwilkerson): Should we report an error if `flutter` contains
    // keys other than `assets`?
  }
}

/// Returns `true` if an asset (file) exists at the given absolute, normalized
/// [assetPath] or in a subdirectory of the parent of the file.
bool _assetExistsAtPath(PubspecValidationContext ctx, String assetPath) {
  // Check for asset directories.
  var assetDirectory = ctx.provider.getFolder(assetPath);
  if (assetDirectory.exists) {
    return true;
  }

  // Else, check for an asset file.
  var assetFile = ctx.provider.getFile(assetPath);
  if (assetFile.exists) {
    return true;
  }
  var fileName = assetFile.shortName;
  var assetFolder = assetFile.parent;
  if (!assetFolder.exists) {
    return false;
  }
  for (var child in assetFolder.getChildren()) {
    if (child is Folder) {
      var innerFile = child.getChildAssumingFile(fileName);
      if (innerFile.exists) {
        return true;
      }
    }
  }
  return false;
}

/// Validates that [pathValue] is a valid path value, reporting any error on
/// [errorField].
void _validateAssetPath(
  PubspecValidationContext ctx,
  String pathValue,
  YamlScalar errorField,
) {
  if (pathValue.startsWith('packages/')) {
    // TODO(brianwilkerson): Add validation of package references.
  } else {
    var isDirectoryEntry = pathValue.endsWith('/');
    var context = ctx.provider.pathContext;
    var packageRoot = context.dirname(ctx.source.fullName);
    var normalizedEntry = context.joinAll(path.posix.split(pathValue));
    var assetPath = context.join(packageRoot, normalizedEntry);
    if (!_assetExistsAtPath(ctx, assetPath)) {
      var errorCode = isDirectoryEntry
          ? PubspecWarningCode.assetDirectoryDoesNotExist
          : PubspecWarningCode.assetDoesNotExist;
      ctx.reportErrorForNode(errorField, errorCode, [pathValue]);
    }
  }
}
