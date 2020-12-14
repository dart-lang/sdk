// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/src/span.dart';
import 'package:yaml/yaml.dart';

class PubspecValidator {
  /// The name of the sub-field (under `flutter`) whose value is a list of
  /// assets available to Flutter apps at runtime.
  static const String ASSETS_FIELD = 'assets';

  /// The name of the field whose value is a map of dependencies.
  static const String DEPENDENCIES_FIELD = 'dependencies';

  /// The name of the field whose value is a map of development dependencies.
  static const String DEV_DEPENDENCIES_FIELD = 'dev_dependencies';

  /// The name of the field whose value is a specification of Flutter-specific
  /// configuration data.
  static const String FLUTTER_FIELD = 'flutter';

  /// The name of the field whose value is a git dependency.
  static const String GIT_FIELD = 'git';

  /// The name of the field whose value is the name of the package.
  static const String NAME_FIELD = 'name';

  /// The name of the field whose value is a path to a package dependency.
  static const String PATH_FIELD = 'path';

  /// The name of the field whose value is the where to publish the package.
  static const String PUBLISH_TO_FIELD = 'publish_to';

  /// The name of the field whose value is the version of the package.
  static const String VERSION_FIELD = 'version';

  /// The resource provider used to access the file system.
  final ResourceProvider provider;

  /// The source representing the file being validated.
  final Source source;

  /// Initialize a newly create validator to validate the content of the given
  /// [source].
  PubspecValidator(this.provider, this.source);

  /// Validate the given [contents].
  List<AnalysisError> validate(Map<dynamic, YamlNode> contents) {
    RecordingErrorListener recorder = RecordingErrorListener();
    ErrorReporter reporter = ErrorReporter(
      recorder,
      source,
      isNonNullableByDefault: false,
    );

    _validateDependencies(reporter, contents);
    _validateFlutter(reporter, contents);
    _validateName(reporter, contents);

    return recorder.errors;
  }

  /// Return `true` if an asset (file) exists at the given absolute, normalized
  /// [assetPath] or in a subdirectory of the parent of the file.
  bool _assetExistsAtPath(String assetPath) {
    // Check for asset directories.
    Folder assetDirectory = provider.getFolder(assetPath);
    if (assetDirectory.exists) {
      return true;
    }

    // Else, check for an asset file.
    File assetFile = provider.getFile(assetPath);
    if (assetFile.exists) {
      return true;
    }
    String fileName = assetFile.shortName;
    Folder assetFolder = assetFile.parent;
    if (!assetFolder.exists) {
      return false;
    }
    for (Resource child in assetFolder.getChildren()) {
      if (child is Folder) {
        File innerFile = child.getChildAssumingFile(fileName);
        if (innerFile.exists) {
          return true;
        }
      }
    }
    return false;
  }

  String _asString(dynamic node) {
    if (node is String) {
      return node;
    }
    if (node is YamlScalar && node.value is String) {
      return node.value as String;
    }
    return null;
  }

  /// Return a map whose keys are the names of declared dependencies and whose
  /// values are the specifications of those dependencies. The map is extracted
  /// from the given [contents] using the given [key].
  Map<dynamic, YamlNode> _getDeclaredDependencies(
      ErrorReporter reporter, Map<dynamic, YamlNode> contents, String key) {
    YamlNode field = contents[key];
    if (field == null || (field is YamlScalar && field.value == null)) {
      return <String, YamlNode>{};
    } else if (field is YamlMap) {
      return field.nodes;
    }
    _reportErrorForNode(
        reporter, field, PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP, [key]);
    return <String, YamlNode>{};
  }

  /// Report an error for the given node.
  void _reportErrorForNode(
      ErrorReporter reporter, YamlNode node, ErrorCode errorCode,
      [List<Object> arguments]) {
    SourceSpan span = node.span;
    reporter.reportErrorForOffset(
        errorCode, span.start.offset, span.length, arguments);
  }

  /// Validate the value of the required `name` field.
  void _validateDependencies(
      ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    Map<dynamic, YamlNode> declaredDependencies =
        _getDeclaredDependencies(reporter, contents, DEPENDENCIES_FIELD);
    Map<dynamic, YamlNode> declaredDevDependencies =
        _getDeclaredDependencies(reporter, contents, DEV_DEPENDENCIES_FIELD);

    bool isPublishablePackage = false;
    var version = contents[VERSION_FIELD];
    if (version != null) {
      var publishTo = _asString(contents[PUBLISH_TO_FIELD]);
      if (publishTo != 'none') {
        isPublishablePackage = true;
      }
    }

    for (var dependency in declaredDependencies.entries) {
      _validatePathEntries(reporter, dependency.value, isPublishablePackage);
    }

    for (var dependency in declaredDevDependencies.entries) {
      var packageName = dependency.key;
      if (declaredDependencies.containsKey(packageName)) {
        _reportErrorForNode(reporter, packageName,
            PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY, [packageName.value]);
      }
      _validatePathEntries(reporter, dependency.value, false);
    }
  }

  /// Validate the value of the optional `flutter` field.
  void _validateFlutter(
      ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    YamlNode flutterField = contents[FLUTTER_FIELD];
    if (flutterField is YamlMap) {
      YamlNode assetsField = flutterField.nodes[ASSETS_FIELD];
      if (assetsField is YamlList) {
        path.Context context = provider.pathContext;
        String packageRoot = context.dirname(source.fullName);
        for (YamlNode entryValue in assetsField.nodes) {
          if (entryValue is YamlScalar) {
            Object entry = entryValue.value;
            if (entry is String) {
              if (entry.startsWith('packages/')) {
                // TODO(brianwilkerson) Add validation of package references.
              } else {
                bool isDirectoryEntry = entry.endsWith("/");
                String normalizedEntry =
                    context.joinAll(path.posix.split(entry));
                String assetPath = context.join(packageRoot, normalizedEntry);
                if (!_assetExistsAtPath(assetPath)) {
                  ErrorCode errorCode = isDirectoryEntry
                      ? PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST
                      : PubspecWarningCode.ASSET_DOES_NOT_EXIST;
                  _reportErrorForNode(
                      reporter, entryValue, errorCode, [entryValue.value]);
                }
              }
            } else {
              _reportErrorForNode(
                  reporter, entryValue, PubspecWarningCode.ASSET_NOT_STRING);
            }
          } else {
            _reportErrorForNode(
                reporter, entryValue, PubspecWarningCode.ASSET_NOT_STRING);
          }
        }
      } else if (assetsField != null) {
        _reportErrorForNode(
            reporter, assetsField, PubspecWarningCode.ASSET_FIELD_NOT_LIST);
      }

      if (flutterField.length > 1) {
        // TODO(brianwilkerson) Should we report an error if `flutter` contains
        // keys other than `assets`?
      }
    } else if (flutterField != null) {
      if (flutterField.value == null) {
        // allow an empty `flutter:` section; explicitly fail on a non-empty,
        // non-map one
      } else {
        _reportErrorForNode(
            reporter, flutterField, PubspecWarningCode.FLUTTER_FIELD_NOT_MAP);
      }
    }
  }

  /// Validate the value of the required `name` field.
  void _validateName(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    YamlNode nameField = contents[NAME_FIELD];
    if (nameField == null) {
      reporter.reportErrorForOffset(PubspecWarningCode.MISSING_NAME, 0, 0);
    } else if (nameField is! YamlScalar || nameField.value is! String) {
      _reportErrorForNode(
          reporter, nameField, PubspecWarningCode.NAME_NOT_STRING);
    }
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
  void _validatePathEntries(ErrorReporter reporter, YamlNode dependency,
      bool checkForPathAndGitDeps) {
    if (dependency is YamlMap) {
      var pathEntry = _asString(dependency[PATH_FIELD]);
      if (pathEntry != null) {
        YamlNode pathKey() => getKey(dependency, PATH_FIELD);
        YamlNode pathValue() => getValue(dependency, PATH_FIELD);

        if (pathEntry.contains(r'\')) {
          _reportErrorForNode(reporter, pathValue(),
              PubspecWarningCode.PATH_NOT_POSIX, [pathEntry]);
          return;
        }
        var context = provider.pathContext;
        var normalizedPath = context.joinAll(path.posix.split(pathEntry));
        var packageRoot = context.dirname(source.fullName);
        var dependencyPath = context.join(packageRoot, normalizedPath);
        dependencyPath = context.absolute(dependencyPath);
        dependencyPath = context.normalize(dependencyPath);
        var packageFolder = provider.getFolder(dependencyPath);
        if (!packageFolder.exists) {
          _reportErrorForNode(reporter, pathValue(),
              PubspecWarningCode.PATH_DOES_NOT_EXIST, [pathEntry]);
        } else {
          if (!packageFolder
              .getChild(AnalysisEngine.PUBSPEC_YAML_FILE)
              .exists) {
            _reportErrorForNode(reporter, pathValue(),
                PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST, [pathEntry]);
          }
        }
        if (checkForPathAndGitDeps) {
          _reportErrorForNode(reporter, pathKey(),
              PubspecWarningCode.INVALID_DEPENDENCY, [PATH_FIELD]);
        }
      }

      var gitEntry = dependency[GIT_FIELD];
      if (gitEntry != null && checkForPathAndGitDeps) {
        _reportErrorForNode(reporter, getKey(dependency, GIT_FIELD),
            PubspecWarningCode.INVALID_DEPENDENCY, [GIT_FIELD]);
      }
    }
  }
}
