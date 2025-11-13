// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_kind.dart';
import 'package:analysis_server/src/utilities/yaml_node_locator.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_plugin/src/utilities/extensions/string_extension.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';

/// The generator used to generate fixes in pubspec.yaml files.
class PubspecFixGenerator {
  static const List<DiagnosticCode> codesWithFixes = [
    diag.missingDependency,
    diag.missingName,
  ];

  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The diagnostic for which fixes are being generated.
  final Diagnostic diagnostic;

  /// The offset of the [diagnostic] for which fixes are being generated.
  final int diagnosticOffset;

  /// The length of the [diagnostic] for which fixes are being generated.
  final int diagnosticLength;

  /// The textual content of the file for which fixes are being generated.
  final String content;

  /// The parsed content of the file for which fixes are being generated.
  final YamlNode node;

  final LineInfo lineInfo;

  /// The fixes that were generated.
  final List<Fix> fixes = <Fix>[];

  /// The end-of-line marker to be used in this `pubspec.yaml` file.
  final String endOfLine;

  PubspecFixGenerator(
    this.resourceProvider,
    this.diagnostic,
    this.content,
    this.node, {
    required String defaultEol,
  }) : diagnosticOffset = diagnostic.offset,
       diagnosticLength = diagnostic.length,
       lineInfo = LineInfo.fromContent(content),
       endOfLine = content.endOfLine ?? defaultEol;

  /// Return the absolute, normalized path to the file in which the error was
  /// reported.
  String get file => diagnostic.source.fullName;

  /// Return the list of fixes that apply to the error being fixed.
  Future<List<Fix>> computeFixes() async {
    var locator = YamlNodeLocator(
      start: diagnosticOffset,
      end: diagnosticOffset + diagnosticLength - 1,
    );
    var coveringNodePath = locator.searchWithin(node);
    if (coveringNodePath.isEmpty) {
      // One of the errors doesn't have a covering path but can still be fixed.
      // The `if` was left so that the variable wouldn't be unused.
      // return fixes;
    }

    var diagnosticCode = diagnostic.diagnosticCode;
    // Check whether [diagnosticCode] is within [codeWithFixes], which is
    // (currently) the canonical list of pubspec diagnostic codes with fixes. If
    // we move pubspec fixes to the style of correction producers, and a map
    // from diagnostic codes to the correction producers that can fix
    // violations, we won't need this check.
    if (!codesWithFixes.contains(diagnosticCode)) {
      return fixes;
    }

    if (diagnosticCode == diag.assetDoesNotExist) {
      // Consider replacing the path with a valid path.
    } else if (diagnosticCode == diag.assetDirectoryDoesNotExist) {
      // Consider replacing the path with a valid path.
      // Consider creating the directory.
    } else if (diagnosticCode == diag.assetFieldNotList) {
      // Not sure how to fix a structural issue.
    } else if (diagnosticCode == diag.assetNotString) {
      // Not sure how to fix a structural issue.
    } else if (diagnosticCode == diag.dependenciesFieldNotMap) {
      // Not sure how to fix a structural issue.
    } else if (diagnosticCode == diag.deprecatedField) {
      // Consider removing the field.
    } else if (diagnosticCode == diag.flutterFieldNotMap) {
      // Not sure how to fix a structural issue.
    } else if (diagnosticCode == diag.invalidDependency) {
      // Consider adding `publish_to: none`.
    } else if (diagnosticCode == diag.missingName) {
      await _addNameEntry();
    } else if (diagnosticCode == diag.nameNotString) {
      // Not sure how to fix a structural issue.
    } else if (diagnosticCode == diag.pathDoesNotExist) {
      // Consider replacing the path with a valid path.
    } else if (diagnosticCode == diag.pathNotPosix) {
      // Consider converting to a POSIX-style path.
    } else if (diagnosticCode == diag.pathPubspecDoesNotExist) {
      // Consider replacing the path with a valid path.
    } else if (diagnosticCode == diag.unnecessaryDevDependency) {
      // Consider removing the dependency.
    } else if (diagnosticCode == diag.missingDependency) {
      await _addMissingDependency(diagnosticCode);
    }
    return fixes;
  }

  /// Adds a fix whose edits were built by the [builder] that has the given
  /// [kind].
  void _addFixFromBuilder(ChangeBuilder builder, FixKind kind) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.id = kind.id;
    change.message = formatList(kind.message, null);
    fixes.add(Fix(kind: kind, change: change));
  }

  Future<void> _addMissingDependency(DiagnosticCode diagnosticCode) async {
    var node = this.node;
    if (node is! YamlMap) {
      return;
    }
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
      defaultEol: endOfLine,
    );

    var data = MissingDependencyData.byDiagnostic[diagnostic]!;
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

            var startOffset = prevEntry != null
                ? prevEntry.value.span.end.offset
                : (currentEntry.key as YamlNode).span.start.offset;
            // If nextEntry is null, this is the last entry in the
            // dev_dependencies section, and also dev_dependencies is the last
            // section in the pubspec file. So delete till the end of the
            // section.
            var endOffset = nextEntry == null
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
      defaultEol: endOfLine,
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
      buffer.write('$sectionName:');
      buffer.write(endOfLine);
    }
    for (var name in packageNames) {
      buffer.write('  $name: any');
      buffer.write(endOfLine);
    }

    var offset = section == null
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
