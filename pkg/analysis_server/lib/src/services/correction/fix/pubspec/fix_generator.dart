// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analysis_server/src/utilities/yaml_node_locator.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:yaml/yaml.dart';

/// The generator used to generate fixes in pubspec.yaml files.
class PubspecFixGenerator {
  final AnalysisError error;

  final int errorOffset;

  final int errorLength;

  final String content;

  final YamlMap options;

  final LineInfo lineInfo;

  final List<Fix> fixes = <Fix>[];

  List<YamlNode> coveringNodePath;

  PubspecFixGenerator(this.error, this.content, this.options)
      : errorOffset = error.offset,
        errorLength = error.length,
        lineInfo = LineInfo.fromContent(content);

  /// Return the absolute, normalized path to the file in which the error was
  /// reported.
  String get file => error.source.fullName;

  /// Return the list of fixes that apply to the error being fixed.
  Future<List<Fix>> computeFixes() async {
    var locator =
        YamlNodeLocator(start: errorOffset, end: errorOffset + errorLength - 1);
    coveringNodePath = locator.searchWithin(options);
    if (coveringNodePath.isEmpty) {
      return fixes;
    }

    var errorCode = error.errorCode;
    if (errorCode == PubspecWarningCode.ASSET_DOES_NOT_EXIST) {
    } else if (errorCode == PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST) {
    } else if (errorCode == PubspecWarningCode.ASSET_FIELD_NOT_LIST) {
    } else if (errorCode == PubspecWarningCode.ASSET_NOT_STRING) {
    } else if (errorCode == PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP) {
    } else if (errorCode == PubspecWarningCode.FLUTTER_FIELD_NOT_MAP) {
    } else if (errorCode == PubspecWarningCode.MISSING_NAME) {
    } else if (errorCode == PubspecWarningCode.NAME_NOT_STRING) {
    } else if (errorCode == PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY) {}
    return fixes;
  }

  /// Add a fix whose edits were built by the [builder] that has the given
  /// [kind]. If [args] are provided, they will be used to fill in the message
  /// for the fix.
  // ignore: unused_element
  void _addFixFromBuilder(ChangeBuilder builder, FixKind kind, {List args}) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }
    change.message = formatList(kind.message, args);
    fixes.add(Fix(kind, change));
  }

  // ignore: unused_element
  int _firstNonWhitespaceBefore(int offset) {
    while (offset > 0 && isWhitespace(content.codeUnitAt(offset - 1))) {
      offset--;
    }
    return offset;
  }

  // ignore: unused_element
  SourceRange _lines(int start, int end) {
    CharacterLocation startLocation = lineInfo.getLocation(start);
    var startOffset = lineInfo.getOffsetOfLine(startLocation.lineNumber - 1);
    CharacterLocation endLocation = lineInfo.getLocation(end);
    var endOffset = lineInfo.getOffsetOfLine(
        math.min(endLocation.lineNumber, lineInfo.lineCount - 1));
    return SourceRange(startOffset, endOffset - startOffset);
  }
}
