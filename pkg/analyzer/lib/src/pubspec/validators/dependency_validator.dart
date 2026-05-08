// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Validate the value of the required `name` field.
void dependencyValidator(PubspecValidationContext ctx) {
  /// Return a map whose keys are the names of declared dependencies and whose
  /// values are the specifications of those dependencies. The map is extracted
  /// from the given [contents] using the given [key].
  Map<dynamic, YamlNode> getDeclaredDependencies(String key) {
    var contents = ctx.contents;
    if (contents is! YamlMap) return {};
    var field = contents.nodes[key];
    if (field == null || (field is YamlScalar && field.value == null)) {
      return <String, YamlNode>{};
    } else if (field is YamlMap) {
      return field.nodes;
    }
    ctx.reportErrorForNode(
      field,
      diag.dependenciesFieldNotMap.withArguments(fieldName: key),
    );
    return <String, YamlNode>{};
  }

  /// Validate that `path` entries reference valid paths.
  ///
  /// Valid paths are directories that:
  ///
  /// 1. exist,
  /// 2. contain a pubspec.yaml file
  ///
  /// If [checkForPathAndGitDeps] is true, `git` or `path` dependencies will
  /// be marked invalid.
  void validatePathEntries(YamlNode dependency, bool checkForPathAndGitDeps) {
    if (dependency is! YamlMap) {
      return;
    }
    var pathEntry = ctx.asString(dependency[PubspecField.PATH_FIELD]);
    if (pathEntry != null) {
      YamlNode pathKey() => dependency.getKey(PubspecField.PATH_FIELD)!;
      YamlNode pathValue() => dependency.valueAt(PubspecField.PATH_FIELD)!;

      if (pathEntry.contains(r'\')) {
        ctx.reportErrorForNode(
          pathValue(),
          diag.pathNotPosix.withArguments(path: pathEntry),
        );
        return;
      }
      var context = ctx.provider.pathContext;
      var normalizedPath = context.joinAll(path.posix.split(pathEntry));
      var packageRoot = context.dirname(ctx.source.fullName);
      var dependencyPath = context.join(packageRoot, normalizedPath);
      dependencyPath = context.absolute(dependencyPath);
      dependencyPath = context.normalize(dependencyPath);
      var packageFolder = ctx.provider.getFolder(dependencyPath);
      if (!packageFolder.exists) {
        ctx.reportErrorForNode(
          pathValue(),
          diag.pathDoesNotExist.withArguments(path: pathEntry),
        );
      } else {
        if (!packageFolder.getChild(file_paths.pubspecYaml).exists) {
          ctx.reportErrorForNode(
            pathValue(),
            diag.pathPubspecDoesNotExist.withArguments(path: pathEntry),
          );
        }
      }
      if (checkForPathAndGitDeps) {
        ctx.reportErrorForNode(
          pathKey(),
          diag.invalidDependency.withArguments(kind: PubspecField.PATH_FIELD),
        );
      }
    }

    var gitEntry = dependency[PubspecField.GIT_FIELD];
    if (gitEntry != null && checkForPathAndGitDeps) {
      ctx.reportErrorForNode(
        dependency.getKey(PubspecField.GIT_FIELD)!,
        diag.invalidDependency.withArguments(kind: PubspecField.GIT_FIELD),
      );
    }
  }

  var declaredDependencies = getDeclaredDependencies(
    PubspecField.DEPENDENCIES_FIELD,
  );
  var declaredDevDependencies = getDeclaredDependencies(
    PubspecField.DEV_DEPENDENCIES_FIELD,
  );

  bool isPublishablePackage = false;
  var contents = ctx.contents;
  if (contents is! YamlMap) return;
  var version = contents[PubspecField.VERSION_FIELD];
  if (version != null) {
    var publishTo = ctx.asString(contents[PubspecField.PUBLISH_TO_FIELD]);
    if (publishTo != 'none') {
      isPublishablePackage = true;
    }
  }

  for (var dependency in declaredDependencies.entries) {
    validatePathEntries(dependency.value, isPublishablePackage);
  }

  for (var dependency in declaredDevDependencies.entries) {
    var packageName = dependency.key as YamlNode;
    if (declaredDependencies.containsKey(packageName)) {
      ctx.reportErrorForNode(
        packageName,
        diag.unnecessaryDevDependency.withArguments(
          package: packageName.valueOrThrow.toString(),
        ),
      );
    }
    validatePathEntries(dependency.value, false);
  }
}
