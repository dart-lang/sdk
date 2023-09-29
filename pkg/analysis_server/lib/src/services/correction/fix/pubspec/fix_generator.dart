// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_kind.dart';
import 'package:analysis_server/src/utilities/yaml_node_locator.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/util/yaml.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';

/// The generator used to generate fixes in pubspec.yaml files.
class PubspecFixGenerator {
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
  final YamlDocument document;

  final LineInfo lineInfo;

  /// The fixes that were generated.
  final List<Fix> fixes = <Fix>[];

  /// The end-of-line marker used in the `pubspec.yaml` file.
  String? _endOfLine;

  PubspecFixGenerator(
      this.resourceProvider, this.error, this.content, this.document)
      : errorOffset = error.offset,
        errorLength = error.length,
        lineInfo = LineInfo.fromContent(content);

  /// Returns the end-of-line marker to use for the `pubspec.yaml` file.
  String get endOfLine {
    // TODO(brianwilkerson) Share this with CorrectionUtils, probably by
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
    var locator =
        YamlNodeLocator(start: errorOffset, end: errorOffset + errorLength - 1);
    var coveringNodePath = locator.searchWithin(document.contents);
    if (coveringNodePath.isEmpty) {
      // One of the errors doesn't have a covering path but can still be fixed.
      // The `if` was left so that the variable wouldn't be unused.
      // return fixes;
    }

    var errorCode = error.errorCode;
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
    fixes.add(Fix(kind, change));
  }

  Future<void> _addMissingDependency(ErrorCode errorCode) async {
    var builder = ChangeBuilder(
        workspace: _NonDartChangeWorkspace(resourceProvider), eol: endOfLine);

    final data = error.data as MissingDependencyData;
    var addDeps = data.addDeps;
    var addDevDeps = data.addDevDeps;
    var removeDevDeps = data.removeDevDeps;

    if (addDeps.isNotEmpty) {
      var (text, offset) = _getTextAndOffset('dependencies', addDeps);
      await builder.addGenericFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset, text);
      });
    }
    if (addDevDeps.isNotEmpty) {
      var (text, offset) = _getTextAndOffset('dev_dependencies', addDevDeps);
      await builder.addGenericFileEdit(file, (builder) {
        builder.addSimpleInsertion(offset, text);
      });
    }
    if (removeDevDeps.isNotEmpty) {
      var section = document.contents.value['dev_dependencies'] as YamlMap;
      // remove the section if all entries are removed.
      if (removeDevDeps.length == section.nodes.length) {
        MapEntry<dynamic, YamlNode>? node, prevNode;
        for (var entry in (document.contents as YamlMap).nodes.entries) {
          if (entry.key.value == 'dev_dependencies') {
            node = entry;
            break;
          }
          prevNode = entry;
        }
        if (node != null && prevNode != null) {
          var startOffset = (prevNode.value as YamlMap).span.end.offset;
          var endOffset = (node.value as YamlMap).span.end.offset;
          await builder.addGenericFileEdit(file, (builder) {
            builder
                .addDeletion(SourceRange(startOffset, endOffset - startOffset));
          });
        }
      } else {
        // go through entries and remove them.
        for (var dep in removeDevDeps) {
          dynamic node, nextNode;
          for (var entry in section.nodes.entries) {
            if (entry.key.value == dep) {
              node = entry;
              continue;
            }
            if (node != null) {
              nextNode = entry;
              break;
            }
          }
          if (node != null) {
            var startOffset = (node.key as YamlScalar).span.start.offset;
            if (nextNode == null) {
              // Removing the last entry, check to see if there are any other
              // sections after dev_dependencies.
              MapEntry<dynamic, YamlNode>? deps;
              for (var entry in (document.contents as YamlMap).nodes.entries) {
                if (entry.key.value == 'dev_dependencies') {
                  deps = entry;
                }
                if (deps != null) {
                  nextNode == entry;
                  break;
                }
              }
            }
            var endOffset = nextNode == null
                ? (node.value as YamlScalar).span.end.offset
                : (nextNode.key as YamlScalar).span.start.offset;
            await builder.addGenericFileEdit(file, (builder) {
              builder.addDeletion(
                  SourceRange(startOffset, endOffset - startOffset));
            });
          }
        }
      }
    }
    _addFixFromBuilder(builder, PubspecFixKind.addDependency);
  }

  Future<void> _addNameEntry() async {
    var context = resourceProvider.pathContext;
    var packageName = _identifierFrom(context.basename(context.dirname(file)));
    var builder = ChangeBuilder(
        workspace: _NonDartChangeWorkspace(resourceProvider), eol: endOfLine);
    var firstOffset = _initialOffset(document.contents);
    if (firstOffset < 0) {
      // The document contains a list, and we don't support converting it to a
      // map.
      return;
    }
    await builder.addGenericFileEdit(file, (builder) {
      // TODO(brianwilkerson) Generalize this to add a key to any map by
      //  inserting the indentation of the line containing `firstOffset` after
      //  the end-of-line marker.
      builder.addSimpleInsertion(firstOffset, 'name: $packageName$endOfLine');
    });
    _addFixFromBuilder(builder, PubspecFixKind.addName);
  }

  (String, int) _getTextAndOffset(
      String sectionName, List<String> packageNames) {
    var section = document.contents.value[sectionName];
    var buffer = StringBuffer();
    if (section == null) {
      buffer.writeln('$sectionName:');
    }
    for (var name in packageNames) {
      buffer.writeln('  $name: any');
    }

    var offset = section == null
        ? document.contents.span.end.offset
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
