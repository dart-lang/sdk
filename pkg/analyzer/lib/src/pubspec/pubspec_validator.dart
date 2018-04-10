// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/src/span.dart';
import 'package:yaml/yaml.dart';

class PubspecValidator {
  /**
   * The name of the sub-field (under `flutter`) whose value is a list of assets
   * available to Flutter apps at runtime.
   */
  static const String ASSETS_FIELD = 'assets';

  /**
   * The name of the field whose value is a map of dependencies.
   */
  static const String DEPENDENCIES_FIELD = 'dependencies';

  /**
   * The name of the field whose value is a map of development dependencies.
   */
  static const String DEV_DEPENDENCIES_FIELD = 'dev_dependencies';

  /**
   * The name of the field whose value is a specification of Flutter-specific
   * configuration data.
   */
  static const String FLUTTER_FIELD = 'flutter';

  /**
   * The name of the field whose value is the name of the package.
   */
  static const String NAME_FIELD = 'name';

  /**
   * The resource provider used to access the file system.
   */
  final ResourceProvider provider;

  /**
   * The source representing the file being validated.
   */
  final Source source;

  /**
   * Initialize a newly create validator to validate the content of the given
   * [source].
   */
  PubspecValidator(this.provider, this.source);

  /**
   * Validate the given [contents].
   */
  List<AnalysisError> validate(Map<dynamic, YamlNode> contents) {
    RecordingErrorListener recorder = new RecordingErrorListener();
    ErrorReporter reporter = new ErrorReporter(recorder, source);

    _validateDependencies(reporter, contents);
    _validateFlutter(reporter, contents);
    _validateName(reporter, contents);

    return recorder.errors;
  }

  /**
   * Return `true` if an asset (file) exists at the given absolute, normalized
   * [assetPath] or in a subdirectory of the parent of the file.
   */
  bool _assetExistsAtPath(String assetPath) {
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

  /**
   * Return a map whose keys are the names of declared dependencies and whose
   * values are the specifications of those dependencies. The map is extracted
   * from the given [contents] using the given [key].
   */
  Map<dynamic, YamlNode> _getDeclaredDependencies(
      ErrorReporter reporter, Map<dynamic, YamlNode> contents, String key) {
    YamlNode field = contents[key];
    if (field == null) {
      return <String, YamlNode>{};
    } else if (field is YamlMap) {
      return field.nodes;
    }
    _reportErrorForNode(
        reporter, field, PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP, [key]);
    return <String, YamlNode>{};
  }

  /**
   * Report an error for the given node.
   */
  void _reportErrorForNode(
      ErrorReporter reporter, YamlNode node, ErrorCode errorCode,
      [List<Object> arguments]) {
    SourceSpan span = node.span;
    reporter.reportErrorForOffset(
        errorCode, span.start.offset, span.length, arguments);
  }

  /**
   * Validate the value of the required `name` field.
   */
  void _validateDependencies(
      ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    Map<dynamic, YamlNode> declaredDependencies =
        _getDeclaredDependencies(reporter, contents, DEPENDENCIES_FIELD);
    Map<dynamic, YamlNode> declaredDevDependencies =
        _getDeclaredDependencies(reporter, contents, DEV_DEPENDENCIES_FIELD);

    for (YamlNode packageName in declaredDevDependencies.keys) {
      if (declaredDependencies.containsKey(packageName)) {
        _reportErrorForNode(reporter, packageName,
            PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY, [packageName.value]);
      }
    }
  }

  /**
   * Validate the value of the optional `flutter` field.
   */
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
                String normalizedEntry =
                    context.joinAll(path.posix.split(entry));
                String assetPath = context.join(packageRoot, normalizedEntry);
                if (!_assetExistsAtPath(assetPath)) {
                  _reportErrorForNode(
                      reporter,
                      entryValue,
                      PubspecWarningCode.ASSET_DOES_NOT_EXIST,
                      [entryValue.value]);
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

  /**
   * Validate the value of the required `name` field.
   */
  void _validateName(ErrorReporter reporter, Map<dynamic, YamlNode> contents) {
    YamlNode nameField = contents[NAME_FIELD];
    if (nameField == null) {
      reporter.reportErrorForOffset(PubspecWarningCode.MISSING_NAME, 0, 0);
    } else if (nameField is! YamlScalar || nameField.value is! String) {
      _reportErrorForNode(
          reporter, nameField, PubspecWarningCode.NAME_NOT_STRING);
    }
  }
}
