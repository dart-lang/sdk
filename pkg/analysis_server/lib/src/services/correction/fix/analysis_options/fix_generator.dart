// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Many functions here are mostly camelcase, with an occasional underscore to
// separate phrases.
// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/yaml_node_locator.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_yaml.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// The generator used to generate fixes in analysis options files.
class AnalysisOptionsFixGenerator {
  static const List<DiagnosticCode> codesWithFixes = [
    AnalysisOptionsWarningCode.DEPRECATED_LINT,
    AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT,
    AnalysisOptionsWarningCode.DUPLICATE_RULE,
    AnalysisOptionsWarningCode.REMOVED_LINT,
    AnalysisOptionsWarningCode.UNDEFINED_LINT,
    AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES,
  ];

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  final Diagnostic diagnostic;

  final int diagnosticOffset;

  final int diagnosticLength;

  final String content;

  final YamlMap options;

  final LineInfo lineInfo;

  final List<Fix> fixes = <Fix>[];

  AnalysisOptionsFixGenerator(
    this.resourceProvider,
    this.diagnostic,
    this.content,
    this.options,
  ) : diagnosticOffset = diagnostic.offset,
      diagnosticLength = diagnostic.length,
      lineInfo = LineInfo.fromContent(content);

  /// The absolute, normalized path to the file in which the diagnostic was
  /// reported.
  String get file => diagnostic.source.fullName;

  /// Returns the list of fixes that apply to the diagnostic being fixed.
  Future<List<Fix>> computeFixes() async {
    var locator = YamlNodeLocator(
      start: diagnosticOffset,
      end: diagnosticOffset + diagnosticLength - 1,
    );
    var coveringNodePath = locator.searchWithin(options);
    if (coveringNodePath.isEmpty) {
      return fixes;
    }

    var diagnosticCode = diagnostic.diagnosticCode;
    // Check whether [diagnosticCode] is within [codeWithFixes], which is
    // (currently) the canonical list of analysis option diagnostic codes with
    // fixes. If we move analysis option fixes to the style of correction
    // producers, and a map from diagnostic codes to the correction producers
    // that can fix violations, we won't need this check.
    if (!codesWithFixes.contains(diagnosticCode)) {
      return fixes;
    }

    if (diagnosticCode ==
        AnalysisOptionsWarningCode
            .ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT) {
      var analyzerMap = options['analyzer'];
      if (analyzerMap is! YamlMap) {
        return fixes;
      }

      var strongModeMap = analyzerMap['strong-mode'];
      if (strongModeMap is! YamlMap) {
        return fixes;
      }

      if (_isErrorAtMapKey(strongModeMap, 'implicit-casts')) {
        await _addFix_replaceWithStrictCasts(
          coveringNodePath,
          analyzerMap,
          strongModeMap,
        );
      } else if (_isErrorAtMapKey(strongModeMap, 'implicit-dynamic')) {
        await _addFix_replaceWithStrictRawTypes(
          coveringNodePath,
          analyzerMap,
          strongModeMap,
        );
      }
    } else if (diagnosticCode == AnalysisOptionsWarningCode.DEPRECATED_LINT ||
        diagnosticCode == AnalysisOptionsWarningCode.DUPLICATE_RULE ||
        diagnosticCode == AnalysisOptionsWarningCode.REMOVED_LINT ||
        diagnosticCode == AnalysisOptionsWarningCode.UNDEFINED_LINT) {
      await _addFix_removeLint(coveringNodePath);
    } else if (diagnosticCode ==
        AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES) {
      await _addFix_removeSetting(coveringNodePath);
    }
    return fixes;
  }

  Future<void> _addFix_removeLint(List<YamlNode> coveringNodePath) async {
    var builder = await _createScalarDeletionBuilder(coveringNodePath);
    if (builder != null) {
      _addFixFromBuilder(
        builder,
        AnalysisOptionsFixKind.REMOVE_LINT,
        args: [coveringNodePath[0].toString()],
      );
    }
  }

  Future<void> _addFix_removeSetting(List<YamlNode> coveringNodePath) async {
    var builder = await _createScalarDeletionBuilder(coveringNodePath);
    if (builder != null) {
      _addFixFromBuilder(
        builder,
        AnalysisOptionsFixKind.REMOVE_SETTING,
        args: [coveringNodePath[0].toString()],
      );
    }
  }

  /// Replaces `analyzer: strong-mode: implicit-casts: false` with
  /// `analyzer: language: strict-casts: true`.
  Future<void> _addFix_replaceWithStrictCasts(
    List<YamlNode> coveringNodePath,
    YamlMap analyzerMap,
    YamlMap strongModeMap,
  ) async {
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
    );
    await builder.addYamlFileEdit(file, (builder) {
      _replaceStrongModeEntryWithLanguageEntry(
        builder,
        coveringNodePath,
        analyzerMap,
        strongModeMap,
        strongModeKey: 'implicit-casts',
        languageKey: 'strict-casts',
        languageValue: true,
      );
    });
    _addFixFromBuilder(
      builder,
      AnalysisOptionsFixKind.REPLACE_WITH_STRICT_CASTS,
      args: [coveringNodePath[0].toString()],
    );
  }

  /// Replaces `analyzer: strong-mode: implicit-dynamic: false` with
  /// `analyzer: language: strict-raw-types: true`.
  Future<void> _addFix_replaceWithStrictRawTypes(
    List<YamlNode> coveringNodePath,
    YamlMap analyzerMap,
    YamlMap strongModeMap,
  ) async {
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
    );
    await builder.addYamlFileEdit(file, (builder) {
      _replaceStrongModeEntryWithLanguageEntry(
        builder,
        coveringNodePath,
        analyzerMap,
        strongModeMap,
        strongModeKey: 'implicit-dynamic',
        languageKey: 'strict-raw-types',
        languageValue: true,
      );
    });
    _addFixFromBuilder(
      builder,
      AnalysisOptionsFixKind.REPLACE_WITH_STRICT_RAW_TYPES,
      args: [coveringNodePath[0].toString()],
    );
  }

  /// Add a fix whose edits were built by the [builder] that has the given
  /// [kind]. If [args] are provided, they will be used to fill in the message
  /// for the fix.
  void _addFixFromBuilder(
    ChangeBuilder builder,
    FixKind kind, {
    required List<String> args,
  }) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, args);
    fixes.add(Fix(kind: kind, change: change));
  }

  Future<ChangeBuilder?> _createScalarDeletionBuilder(
    List<YamlNode> coveringNodePath,
  ) async {
    if (coveringNodePath[0] is! YamlScalar) {
      return null;
    }

    SourceRange? deletionRange;
    var index = 1;
    while (index < coveringNodePath.length) {
      var parent = coveringNodePath[index];
      if (parent is YamlList) {
        if (parent.nodes.length > 1) {
          var nodeToDelete = coveringNodePath[index - 1];
          deletionRange = _lines(
            nodeToDelete.span.start.offset,
            nodeToDelete.span.end.offset,
          );
          break;
        }
      } else if (parent is YamlMap) {
        var nodes = parent.nodes;
        if (nodes.length > 1) {
          YamlNode? key;
          YamlNode? value;
          var child = coveringNodePath[index - 1];
          if (nodes.containsKey(child)) {
            key = child;
            value = nodes[child];
          } else if (nodes.containsValue(child)) {
            for (var entry in nodes.entries) {
              if (child == entry.value) {
                key = entry.key as YamlNode?;
                value = child;
                break;
              }
            }
          }
          if (key == null || value == null) {
            throw StateError(
              'Child is neither a key nor a value in the parent',
            );
          }
          deletionRange = _lines(
            key.span.start.offset,
            _firstNonWhitespaceBefore(value.span.end.offset),
          );
          break;
        }
      } else if (parent is YamlDocument) {
        break;
      }
      index++;
    }
    var nodeToDelete = coveringNodePath[index - 1];
    deletionRange ??= _lines(
      nodeToDelete.span.start.offset,
      nodeToDelete.span.end.offset,
    );
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
    );

    var deletionRange_final = deletionRange;
    await builder.addYamlFileEdit(file, (builder) {
      builder.addDeletion(deletionRange_final);
    });
    return builder;
  }

  int _firstNonWhitespaceBefore(int offset) {
    while (offset > 0 && content.codeUnitAt(offset - 1).isWhitespace) {
      offset--;
    }
    return offset;
  }

  /// Returns whether the error is located within [map], covering the
  /// [YamlScalar] node for [key].
  bool _isErrorAtMapKey(YamlMap map, String key) {
    var keyNode = map.nodes.keys.whereType<YamlScalar>().firstWhereOrNull(
      (k) => k.value == key,
    );
    if (keyNode == null) {
      return false;
    }
    var keyOffset = keyNode.span.start.offset;
    var keyLength = keyNode.span.end.offset - keyOffset;
    return keyOffset == diagnosticOffset && keyLength == diagnosticLength;
  }

  SourceRange _lines(int start, int end) {
    var startLocation = lineInfo.getLocation(start);
    var startOffset = lineInfo.getOffsetOfLine(startLocation.lineNumber - 1);
    var endLocation = lineInfo.getLocation(end);
    var endOffset = lineInfo.getOffsetOfLine(
      math.min(endLocation.lineNumber, lineInfo.lineCount - 1),
    );
    return SourceRange(startOffset, endOffset - startOffset);
  }

  /// Replaces a 'strong-mode' entry keyed to [strongModeKey] with a 'language'
  /// entry with [languageKey] and [languageValue].
  ///
  /// 'strong-mode' and 'language' are each maps which can be found under the
  /// top-level 'analyzer' map. 'strong-mode' (given as [strongModeMap]) must
  /// already be present under the 'analyzer' map (given as [analyzerMap]).
  void _replaceStrongModeEntryWithLanguageEntry(
    YamlFileEditBuilder builder,
    List<YamlNode> coveringNodePath,
    YamlMap analyzerMap,
    YamlMap strongModeMap, {
    required String strongModeKey,
    required String languageKey,
    required Object? languageValue,
  }) {
    var yamlEditor = YamlEditor(content);
    // If 'language' does not exist yet under 'analyzer', create it.
    if (analyzerMap['language'] == null) {
      yamlEditor.update(['analyzer', 'language'], {languageKey: languageValue});
    } else {
      yamlEditor.update(['analyzer', 'language', languageKey], languageValue);
    }
    var languageEdit = yamlEditor.edits.single;
    builder.addSimpleReplacement(
      SourceRange(languageEdit.offset, languageEdit.length),
      languageEdit.replacement,
    );

    // If `strongModeKey` is the only entry under 'strong-mode', then remove
    // the entire 'strong-mode' entry.
    if (strongModeMap.length == 1) {
      yamlEditor.remove(['analyzer', 'strong-mode']);
    } else {
      yamlEditor.remove(['analyzer', 'strong-mode', strongModeKey]);
    }
    var strongModeEdit = yamlEditor.edits[1];
    int strongModeEditOffset;
    if (strongModeEdit.offset > languageEdit.offset) {
      strongModeEditOffset =
          strongModeEdit.offset -
          (languageEdit.replacement.length - languageEdit.length);
    } else {
      strongModeEditOffset = strongModeEdit.offset;
    }
    builder.addSimpleReplacement(
      SourceRange(strongModeEditOffset, strongModeEdit.length),
      strongModeEdit.replacement,
    );
  }
}

class _NonDartChangeWorkspace implements ChangeWorkspace {
  @override
  ResourceProvider resourceProvider;

  _NonDartChangeWorkspace(this.resourceProvider);

  @override
  bool containsFile(String path) {
    return true;
  }

  @override
  AnalysisSession getSession(String path) {
    throw UnimplementedError('Attempt to work a Dart file.');
  }
}
