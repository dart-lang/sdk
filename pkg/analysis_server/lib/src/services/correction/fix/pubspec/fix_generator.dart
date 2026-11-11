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
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/src/utilities/extensions/string_extension.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:linter/src/diagnostic.dart' as diag;
import 'package:yaml/yaml.dart';

/// The generator used to generate fixes in pubspec.yaml files.
class PubspecFixGenerator {
  static const List<DiagnosticCode> codesWithFixes = [
    diag.missingDependency,
    diag.missingName,
    diag.sortPubDependencies,
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

  new(
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
    } else if (diagnosticCode == diag.sortPubDependencies) {
      await _sortPubDependencies();
    }
    return fixes;
  }

  /// Adds a fix whose edits were built by the [builder] that has the given
  /// [kind].
  void _addFixFromBuilder(ChangeBuilderImpl builder, FixKind kind) {
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
    var fixKind = PubspecFixKind.addDependency;
    var builder = _createChangeBuilder(fixKind);
    var data = MissingDependencyData.byDiagnostic[diagnostic]!;
    var addDeps = data.addDeps;
    var addDevDeps = data.addDevDeps;
    var removeDevDeps = data.removeDevDeps;

    for (var (sectionName, packageNames) in [
      ('dependencies', addDeps),
      ('dev_dependencies', addDevDeps),
    ]) {
      if (packageNames.isEmpty) continue;
      var insertions = _computeInsertions(node, sectionName, packageNames);
      await builder.addYamlFileEdit(file, (builder) {
        for (var (offset, text) in insertions) {
          builder.addSimpleInsertion(offset, text);
        }
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
            var startOffset = prevEntry != null
                ? prevEntry.value.span.end.offset
                : (currentEntry.key as YamlNode).span.start.offset;
            // If nextEntry is null, this is the last entry in the
            // dev_dependencies section, so delete till the end of its value.
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
    _addFixFromBuilder(builder, fixKind);
  }

  Future<void> _addNameEntry() async {
    var context = resourceProvider.pathContext;
    var packageName = _identifierFrom(context.basename(context.dirname(file)));
    var fixKind = PubspecFixKind.addName;
    var builder = _createChangeBuilder(fixKind);
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
    _addFixFromBuilder(builder, fixKind);
  }

  /// Returns the `(offset, text)` insertions needed to add [packageNames] to
  /// the section named [sectionName] in the pubspec [node].
  ///
  /// When the section is an existing, non-empty block map, entries are
  /// inserted in alphabetical order if the existing entries are already
  /// sorted (matching the behavior of `dart pub add`), and are otherwise
  /// appended directly after the last entry (before any trailing blank lines
  /// or comments that separate it from the next section).
  ///
  /// When the section key is present but has no value, entries are inserted
  /// directly below the key. When the section is missing, it is added at the
  /// end of the document.
  ///
  /// Returns an empty list if the section has some other shape (for example a
  /// flow-style map or a non-map value) that cannot be safely edited.
  List<(int, String)> _computeInsertions(
    YamlMap node,
    String sectionName,
    List<String> packageNames,
  ) {
    var section = node.nodes[sectionName];
    if (section == null) {
      var (text, offset) = _getTextAndOffset(node, sectionName, packageNames);
      return [(offset, text)];
    }
    if (section is YamlMap &&
        section.style == CollectionStyle.BLOCK &&
        section.nodes.isNotEmpty) {
      return _computeInsertionsInMap(section, packageNames);
    }
    if (section is YamlScalar &&
        section.value == null &&
        section.span.length == 0) {
      // The key is present with an empty value (`dependencies:`).
      var key = node.nodes.keys.whereType<YamlNode>().firstWhere(
        (key) => key.value == sectionName,
      );
      var (offset, prefix) = _offsetAfterNode(key);
      var buffer = StringBuffer(prefix);
      for (var name in packageNames) {
        buffer.write('  $name: any$endOfLine');
      }
      return [(offset, buffer.toString())];
    }
    return const [];
  }

  /// Returns the `(offset, text)` insertions needed to add [packageNames] to
  /// the non-empty block map [section].
  List<(int, String)> _computeInsertionsInMap(
    YamlMap section,
    List<String> packageNames,
  ) {
    var entries = section.nodes.entries.toList()
      ..sort(
        (a, b) => (a.key as YamlNode).span.start.offset.compareTo(
          (b.key as YamlNode).span.start.offset,
        ),
      );
    var names = [
      for (var entry in entries) (entry.key as YamlNode).value.toString(),
    ];
    var firstKey = entries.first.key as YamlNode;
    var indent = ' ' * firstKey.span.start.column;

    var isSorted = true;
    for (var i = 1; i < names.length; i++) {
      if (names[i].compareTo(names[i - 1]) < 0) {
        isSorted = false;
        break;
      }
    }

    var (endOffset, endPrefix) = _offsetAfterNode(entries.last.value);

    // Group insertions by offset so that multiple packages inserted at the
    // same location are emitted as a single edit, in the desired order.
    var insertions = <int, StringBuffer>{};
    void add(int offset, String prefix, String name) {
      insertions
          .putIfAbsent(offset, () => StringBuffer()..write(prefix))
          .write('$indent$name: any$endOfLine');
    }

    if (!isSorted) {
      for (var name in packageNames) {
        add(endOffset, endPrefix, name);
      }
    } else {
      for (var name in packageNames.toList()..sort()) {
        var index = names.indexWhere((n) => n.compareTo(name) > 0);
        if (index < 0) {
          add(endOffset, endPrefix, name);
        } else {
          var key = entries[index].key as YamlNode;
          add(lineInfo.getOffsetOfLine(key.span.start.line), '', name);
        }
      }
    }
    return [
      for (var entry in insertions.entries) (entry.key, entry.value.toString()),
    ];
  }

  /// Creates a [ChangeBuilder] with the change description set correctly for
  /// [fixKind].
  ChangeBuilderImpl _createChangeBuilder(FixKind fixKind) {
    var builder = ChangeBuilder(
      workspace: _NonDartChangeWorkspace(resourceProvider),
      defaultEol: endOfLine,
    ) as ChangeBuilderImpl;
    builder.currentChangeDescription = fixKind.message;
    return builder;
  }

  /// Returns the text and offset needed to add a new section named
  /// [sectionName], containing [packageNames], at the end of [node].
  ///
  /// Must only be called when [node] has no entry for [sectionName].
  (String, int) _getTextAndOffset(
    YamlMap node,
    String sectionName,
    List<String> packageNames,
  ) {
    assert(!node.nodes.containsKey(sectionName));
    var insertNewline = !node.span.text.endsWith(endOfLine);

    var buffer = StringBuffer();
    if (insertNewline) {
      buffer.write(endOfLine);
    }
    buffer.write('$sectionName:');
    buffer.write(endOfLine);
    for (var name in packageNames) {
      buffer.write('  $name: any');
      buffer.write(endOfLine);
    }

    return (buffer.toString(), node.span.end.offset);
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

  bool _isWhitespace(int char) =>
      char == $SPACE || char == $TAB || char == $CR || char == $LF;

  /// Normalizes the indentation of a dependency entry.
  String _normalizeEntryIndentation(String text, String indentation) {
    var lines = text.split(RegExp(r'\r?\n'));
    var result = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (i == 0) {
        // First line gets the base indentation.
        result.write('$indentation${line.trimLeft()}');
      } else {
        // Subsequent lines keep their relative indentation.
        result.write('$endOfLine$indentation  ${line.trimLeft()}');
      }
    }
    return result.toString();
  }

  /// Returns the offset of the start of the line following the last
  /// non-whitespace character of [node], along with a prefix that must be
  /// inserted before new content at that offset (an end-of-line marker when
  /// [node] ends on the last line of a file without a trailing newline).
  (int, String) _offsetAfterNode(YamlNode node) {
    var end = node.span.end.offset;
    while (end > 0 && _isWhitespace(content.codeUnitAt(end - 1))) {
      end--;
    }
    // `lineNumber` is one-based, so it is the zero-based index of the
    // following line.
    var nextLine = lineInfo.getLocation(end).lineNumber;
    if (nextLine < lineInfo.lineCount) {
      return (lineInfo.getOffsetOfLine(nextLine), '');
    }
    return (content.length, endOfLine);
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

  /// Sorts dependencies alphabetically in the section containing the
  /// diagnostic.
  Future<void> _sortPubDependencies() async {
    var rootNode = node;
    if (rootNode is! YamlMap) {
      return;
    }

    // Find the dependency section containing the diagnostic offset.
    YamlMap? dependencySection;
    for (var sectionName in const [
      'dependencies',
      'dev_dependencies',
      'dependency_overrides',
    ]) {
      var section = rootNode[sectionName];
      if (section is YamlMap) {
        var sectionStart = section.span.start.offset;
        var sectionEnd = section.span.end.offset;
        if (diagnosticOffset >= sectionStart &&
            diagnosticOffset <= sectionEnd) {
          dependencySection = section;
          break;
        }
      }
    }

    if (dependencySection == null) {
      return;
    }

    // Collect all dependency entries with their text representations.
    var entries = <_DependencyEntry>[];
    for (var MapEntry(key: YamlNode keyNode, value: valueNode)
        in dependencySection.nodes.entries) {
      var keyName = keyNode.value as String;

      // The start of this entry (including the key).
      var entryStart = keyNode.span.start.offset;
      // The end of this entry (the end of the value).
      var entryEnd = valueNode.span.end.offset;
      var entryText = content.substring(entryStart, entryEnd);
      entries.add(_DependencyEntry(keyName, entryStart, entryEnd, entryText));
    }

    // Sort entries alphabetically by package name.
    var sortedEntries = List<_DependencyEntry>.from(entries)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Build the sorted content.
    // First, find the indentation used for dependencies.
    var firstEntryLine =
        lineInfo.getLocation(entries.first.startOffset).lineNumber - 1;
    var lineStart = lineInfo.lineStarts[firstEntryLine];
    var indentation = '';
    for (var i = lineStart; i < entries.first.startOffset; i++) {
      var char = content[i];
      if (char == ' ' || char == '\t') {
        indentation += char;
      } else {
        break;
      }
    }

    // Build the new sorted section content.
    var sortedContent = StringBuffer();
    for (var i = 0; i < sortedEntries.length; i++) {
      var entry = sortedEntries[i];
      // Normalize the entry text to use consistent indentation.
      var normalizedText = _normalizeEntryIndentation(entry.text, indentation);
      sortedContent.write(normalizedText);
      if (i < sortedEntries.length - 1) {
        sortedContent.write(endOfLine);
      }
    }

    // Calculate the range to replace (from first entry start to last entry end).
    var replaceStart = lineStart;
    var lastEntry = entries.last;
    var replaceEnd = lastEntry.endOffset;

    var fixKind = PubspecFixKind.sortDependencies;
    var builder = _createChangeBuilder(fixKind);
    await builder.addYamlFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        SourceRange(replaceStart, replaceEnd - replaceStart),
        sortedContent.toString(),
      );
    });
    _addFixFromBuilder(builder, fixKind);
  }
}

/// Represents a dependency entry in the pubspec.yaml file.
class _DependencyEntry {
  /// The package name (the key in the YAML map).
  final String name;

  /// The start offset of this entry in the file content.
  final int startOffset;

  /// The end offset of this entry in the file content.
  final int endOffset;

  /// The full text of this entry (key: value).
  final String text;

  new(this.name, this.startOffset, this.endOffset, this.text);
}

class _NonDartChangeWorkspace implements ChangeWorkspace {
  @override
  ResourceProvider resourceProvider;

  new(this.resourceProvider);

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

  new(this.startOffset, this.endOffset);
}
