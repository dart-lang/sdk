// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_kind.dart';
import 'package:analysis_server/src/utilities/yaml_node_locator.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';

/// The generator used to generate fixes in pubspec.yaml files.
class PubspecFixGenerator {
  static const List<ErrorCode> codesWithFixes = [
    PubspecWarningCode.MISSING_DEPENDENCY,
    PubspecWarningCode.MISSING_NAME,
  ];

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The error for which fixes are being generated.
  final AnalysisError error;

  /// The offset of the [error] for which fixes are being generated.
  final int errorOffset;

  /// The length of the [error] for which fixes are being generated.
  final int errorLength;

  /// The textual content of the file for which fixes are being generated.
  final String content;

  /// The parsed content of the file for which fixes are being generated.
  final YamlNode node;

  final LineInfo lineInfo;

  /// The fixes that were generated.
  final List<Fix> fixes = <Fix>[];

  /// The end-of-line marker used in the `pubspec.yaml` file.
  String? _endOfLine;

  PubspecFixGenerator(
    this.resourceProvider,
    this.error,
    this.content,
    this.node,
  ) : errorOffset = error.offset,
      errorLength = error.length,
      lineInfo = LineInfo.fromContent(content);

  /// Returns the end-of-line marker to use for the `pubspec.yaml` file.
  String get endOfLine {
    // TODO(brianwilkerson): Share this with CorrectionUtils, probably by
    //  creating a subclass of CorrectionUtils containing utilities that are
    //  only dependent on knowing the content of the file. Also consider moving
    //  this kind of utility into the ChangeBuilder API directly.
    var endOfLine = _endOfLine;
    if (endOfLine != null) {
      return endOfLine;
    }

    if (content.contains('\r\n')) {
      return _endOfLine = '\r\n';
    } else {
      return _endOfLine = '\n';
    }
  }

  /// Return the absolute, normalized path to the file in which the error was
  /// reported.
  String get file => error.source.fullName;

  /// Return the list of fixes that apply to the error being fixed.
  Future<List<Fix>> computeFixes() async {
    var locator = YamlNodeLocator(
      start: errorOffset,
      end: errorOffset + errorLength - 1,
    );
    var coveringNodePath = locator.searchWithin(node);
    if (coveringNodePath.isEmpty) {
      // One of the errors doesn't have a covering path but can still be fixed.
      // The `if` was left so that the variable wouldn't be unused.
      // return fixes;
    }

    var errorCode = error.errorCode;
    // Check whether [errorCode] is within [codeWithFixes], which is (currently)
    // the canonical list of pubspec error codes with fixes. If we move pubspec
    // fixes to the style of correction producers, and a map from error codes to
    // the correction producers that can fix violations, we won't need this
    // check.
    if (!codesWithFixes.contains(errorCode)) {
      return fixes;
    }

    if (errorCode == PubspecWarningCode.ASSET_DOES_NOT_EXIST) {
      // Consider replacing the path with a valid path.
    } else if (errorCode == PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST) {
      // Consider replacing the path with a valid path.
      // Consider creating the directory.
    } else if (errorCode == PubspecWarningCode.ASSET_FIELD_NOT_LIST) {
      // Not sure how to fix a structural issue.
    } else if (errorCode == PubspecWarningCode.ASSET_NOT_STRING) {
      // Not sure how to fix a structural issue.
    } else if (errorCode == PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP) {
      // Not sure how to fix a structural issue.
    } else if (errorCode == PubspecWarningCode.DEPRECATED_FIELD) {
      // Consider removing the field.
    } else if (errorCode == PubspecWarningCode.FLUTTER_FIELD_NOT_MAP) {
      // Not sure how to fix a structural issue.
    } else if (errorCode == PubspecWarningCode.INVALID_DEPENDENCY) {
      // Consider adding `publish_to: none`.
    } else if (errorCode == PubspecWarningCode.MISSING_NAME) {
      await _addNameEntry();
    } else if (errorCode == PubspecWarningCode.NAME_NOT_STRING) {
      // Not sure how to fix a structural issue.
    } else if (errorCode == PubspecWarningCode.PATH_DOES_NOT_EXIST) {
      // Consider replacing the path with a valid path.
    } else if (errorCode == PubspecWarningCode.PATH_NOT_POSIX) {
      // Consider converting to a POSIX-style path.
    } else if (errorCode == PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST) {
      // Consider replacing the path with a valid path.
    } else if (errorCode == PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY) {
      // Consider removing the dependency.
    } else if (errorCode == PubspecWarningCode.MISSING_DEPENDENCY) {
      await _addMissingDependency(errorCode);
    }
    return fixes;
  }

  /// Add a fix whose edits were built by the [builder] that has the given
  /// [kind]. If [args] are provided, they will be used to fill in the message
  /// for the fix.
  void _addFixFromBuilder(ChangeBuilder builder, FixKind kind) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, null);
    fixes.add(Fix(kind: kind, change: change));
  }

  Future<void> _addMissingDependency(ErrorCode errorCode) async {
    var node = this.node;
    if (node is! YamlMap) {
      return;
    }
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
      eol: endOfLine,
    );

    var data = error.data as MissingDependencyData;
    var addDeps = data.addDeps;
    var addDevDeps = data.addDevDeps;
    var removeDevDeps = data.removeDevDeps;

    if (addDeps.isNotEmpty) {
      var (text, offset) = _getTextAndOffset(node, 'dependencies', addDeps);
      await builder.addYamlFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset, text);
      });
    }
    if (addDevDeps.isNotEmpty) {
      var (text, offset) = _getTextAndOffset(
        node,
        'dev_dependencies',
        addDevDeps,
      );
      await builder.addYamlFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset, text);
      });
    }
    if (removeDevDeps.isNotEmpty) {
      var section = node['dev_dependencies'] as YamlMap;
      // Remove the section if all entries are to be deleted.
      if (removeDevDeps.length == section.nodes.length) {
        MapEntry<dynamic, YamlNode>? currentEntry, prevEntry;
        for (var entry in node.nodes.entries) {
          if (entry.key.value == 'dev_dependencies') {
            currentEntry = entry;
            break;
          }
          prevEntry = entry;
        }
        if (currentEntry != null && prevEntry != null) {
          var startOffset = prevEntry.value.span.end.offset;
          var endOffset = currentEntry.value.span.end.offset;
          await builder.addYamlFileEdit(file, (builder) {
            builder.addDeletion(
              SourceRange(startOffset, endOffset - startOffset),
            );
          });
        }
      } else {
        // Keep track of the current edit.
        _Range? edit;
        // Go through entries and remove each one.
        for (var dep in removeDevDeps) {
          MapEntry<dynamic, YamlNode>? currentEntry, nextEntry, prevEntry;
          var length = section.nodes.entries.length;
          for (int i = 0; i < length; i++) {
            var entry = section.nodes.entries.elementAt(i);
            if (entry.key.value == dep) {
              currentEntry = entry;
              if (i + 1 < length) {
                nextEntry = section.nodes.entries.elementAt(i + 1);
              }
              break;
            }
            prevEntry = entry;
          }
          if (currentEntry != null) {
            if (nextEntry == null) {
              // Removing the last entry, check to see if there are any other
              // sections after dev_dependencies.
              MapEntry<dynamic, YamlNode>? deps;
              for (var entry in node.nodes.entries) {
                if (entry.key.value == 'dev_dependencies') {
                  deps = entry;
                  continue;
                }
                if (deps != null) {
                  nextEntry == entry;
                  break;
                }
              }
            }

            var startOffset =
                prevEntry != null
                    ? prevEntry.value.span.end.offset
                    : (currentEntry.key as YamlNode).span.start.offset;
            // If nextEntry is null, this is the last entry in the
            // dev_dependencies section, and also dev_dependencies is the the
            // last section in the pubspec file. So delete till the end of the
            // section.
            var endOffset =
                nextEntry == null
                    ? currentEntry.value.span.end.offset
                    : (nextEntry.key as YamlNode).span.start.offset;
            // If entry in the middle of two other entries that are not to be
            // removed, delete the line.
            if (prevEntry != null &&
                nextEntry != null &&
                !removeDevDeps.contains(prevEntry.key.value) &&
                !removeDevDeps.contains(nextEntry.key.value)) {
              var line = (currentEntry.key as YamlNode).span.start.line;
              startOffset = lineInfo.lineStarts[line];
              var nextLine = (nextEntry.key as YamlNode).span.start.line;
              endOffset = lineInfo.lineStarts[nextLine];
            }
            if (edit == null) {
              edit = _Range(startOffset, endOffset);
            } else if (edit.endOffset > startOffset) {
              // Conflicting ranges for edits, merge them.
              edit = _Range(edit.startOffset, endOffset);
            } else {
              // Edits don't conflict, add previously computed edit to builder.
              await builder.addYamlFileEdit(file, (builder) {
                builder.addDeletion(
                  SourceRange(
                    edit!.startOffset,
                    edit.endOffset - edit.startOffset,
                  ),
                );
              });
              edit = _Range(startOffset, endOffset);
            }
          }
        }
        // Iterated through all the entries to be removed, add the last computed
        // edit to builder.
        if (edit != null) {
          await builder.addYamlFileEdit(file, (builder) {
            builder.addDeletion(
              SourceRange(edit!.startOffset, edit.endOffset - edit.startOffset),
            );
          });
        }
      }
    }
    _addFixFromBuilder(builder, PubspecFixKind.addDependency);
  }

  Future<void> _addNameEntry() async {
    var context = resourceProvider.pathContext;
    var packageName = _identifierFrom(context.basename(context.dirname(file)));
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
      eol: endOfLine,
    );
    var firstOffset = _initialOffset(node);
    if (firstOffset < 0) {
      // The document contains a list, and we don't support converting it to a
      // map.
      return;
    }
    await builder.addYamlFileEdit(file, (builder) {
      // TODO(brianwilkerson): Generalize this to add a key to any map by
      //  inserting the indentation of the line containing `firstOffset` after
      //  the end-of-line marker.
      builder.addSimpleInsertion(firstOffset, 'name: $packageName$endOfLine');
    });
    _addFixFromBuilder(builder, PubspecFixKind.addName);
  }

  (String, int) _getTextAndOffset(
    YamlMap node,
    String sectionName,
    List<String> packageNames,
  ) {
    var section = node[sectionName];
    var buffer = StringBuffer();
    if (section == null) {
      buffer.writeln('$sectionName:');
    }
    for (var name in packageNames) {
      buffer.writeln('  $name: any');
    }

    var offset =
        section == null
            ? node.span.end.offset
            : (section as YamlNode).span.end.offset;

    return (buffer.toString(), offset);
  }

  String _identifierFrom(String directoryName) {
    var buffer = StringBuffer();
    for (var i = 0; i < directoryName.length; i++) {
      var currentChar = directoryName[i];
      if (_isIdentifierChar(currentChar.codeUnitAt(0))) {
        buffer.write(currentChar.toLowerCase());
      }
    }
    if (buffer.isEmpty) {
      return 'insertNameHere';
    }
    return buffer.toString();
  }

  int _initialOffset(YamlNode node) {
    if (node is YamlMap) {
      return _offsetOfFirstKey(node);
    } else if (node is YamlScalar) {
      return node.span.start.offset;
    }
    return -1;
  }

  bool _isIdentifierChar(int next) {
    return ($a <= next && next <= $z) ||
        ($A <= next && next <= $Z) ||
        ($0 <= next && next <= $9) ||
        identical(next, $_);
  }

  int _offsetOfFirstKey(YamlMap map) {
    var firstOffset = -1;
    for (var key in map.nodeMap.keys) {
      var keyOffset = key.span.start.offset;
      if (firstOffset < 0 || keyOffset < firstOffset) {
        firstOffset = keyOffset;
      }
    }
    if (firstOffset < 0) {
      firstOffset = 0;
    }
    return firstOffset;
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

class _Range {
  int startOffset;
  int endOffset;

  _Range(this.startOffset, this.endOffset);
}
