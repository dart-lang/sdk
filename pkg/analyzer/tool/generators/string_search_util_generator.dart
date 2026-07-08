// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server_client/protocol.dart' hide Element;
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:path/path.dart';

Future<void> main() async {
  var generator = StringSearchUtilGenerator();
  var code = await generator.generate();
  io.File(generator.filePath).writeAsStringSync(code);
}

/// Adapted from
/// https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore%E2%80%93Horspool_algorithm#Description
List<int> _bmhTable(String needle, {int tableSize = 256}) {
  List<int> result = List.filled(tableSize, needle.length);
  for (int i = 0; i < needle.length - 1; i++) {
    result[needle.codeUnitAt(i)] = needle.length - 1 - i;
  }
  return result;
}

/// Adapted from
/// https://en.wikipedia.org/wiki/Knuth%E2%80%93Morris%E2%80%93Pratt_algorithm#Description_of_pseudocode_for_the_table-building_algorithm
///
/// This gives comparable results to the one given in
/// "Introduction to Algorithms (2nd edition)" 32.4 (with the addition from
/// exercice 32.4-4), except for the distinction between 0 and -1 that this
/// version offers.
List<int> _kmpTable(String needle) {
  int pos = 1;
  // the zero-based index in needle of the next character of the current
  // candidate substring
  int cnd = 0;
  List<int> result = List.filled(needle.length, 0);
  result[0] = -1;
  int needleLength = needle.length;
  while (pos < needleLength) {
    int needleAtPos = needle.codeUnitAt(pos);
    if (needleAtPos == needle.codeUnitAt(cnd)) {
      result[pos] = result[cnd];
    } else {
      result[pos] = cnd;
      while (cnd >= 0 && needleAtPos != needle.codeUnitAt(cnd)) {
        cnd = result[cnd];
      }
    }
    pos++;
    cnd++;
  }
  return result;
}

class StringSearchUtilGenerator {
  String get filePath {
    var analyzerPath = normalize(join(pkg_root.packageRoot, 'analyzer'));
    var analyzerLibPath = normalize(join(analyzerPath, 'lib'));
    return normalize(
      join(analyzerLibPath, 'src', 'utilities', 'string_search.dart'),
    );
  }

  Future<String> generate() async {
    ResolvedUnitResult resolvedUnit = await _getAstResolvedUnit();
    String newCode = resolvedUnit.content;

    var methods = _findMethods(resolvedUnit);
    newCode = _replaceMethods(newCode, methods);
    newCode = await _formatSortCode(filePath, newCode);
    return newCode;
  }

  List<MethodDeclarationImpl> _findMethods(ResolvedUnitResult resolvedUnit) {
    List<MethodDeclarationImpl> result = [];
    for (var nodeImpl in resolvedUnit.unit.declarations) {
      if (nodeImpl is ClassDeclarationImpl) {
        for (var member in nodeImpl.body.members) {
          if (member is! MethodDeclarationImpl) continue;
          var method = member.declaredFragment?.element;
          if (method is! MethodElementImpl) continue;
          var annotationData = _getAnnotationData(method);
          if (annotationData == null) continue;
          result.add(member);
        }
      }
    }
    return result;
  }

  String _formatListElements(List<int> list) {
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < list.length; i++) {
      sb.write(list[i]);
      sb.write(",");
      if (i % 8 == 7) sb.write("\n");
    }
    return sb.toString();
  }

  ({String needle, bool addNeedleLength})? _getAnnotationData(
    MethodElementImpl method,
  ) {
    for (var annotation in method.metadata.annotations) {
      var value = annotation.computeConstantValue();
      if (value == null) continue;
      var valueType = value.type;
      if (valueType == null) continue;
      if (valueType.element?.name != '_GeneratedSearchData') continue;

      var needle = value.getField('needle');
      if (needle == null) continue;
      if (!(needle.type?.isDartCoreString ?? false)) continue;

      var addNeedleLength = value.getField('addNeedleLength');
      if (addNeedleLength == null) continue;
      if (!(addNeedleLength.type?.isDartCoreBool ?? false)) continue;

      var needleString = needle.toStringValue();
      var addNeedleLengthBool = addNeedleLength.toBoolValue();
      if (needleString != null && addNeedleLengthBool != null) {
        return (needle: needleString, addNeedleLength: addNeedleLengthBool);
      }
    }
    return null;
  }

  Future<ResolvedUnitResult> _getAstResolvedUnit() async {
    var collection = AnalysisContextCollection(includedPaths: [filePath]);
    var analysisContext = collection.contextFor(filePath);
    var analysisSession = analysisContext.currentSession;
    var astUnitResult = await analysisSession.getResolvedUnit(filePath);
    return astUnitResult as ResolvedUnitResult;
  }

  String _replaceMethods(String newCode, List<MethodDeclarationImpl> methods) {
    var replacements = <_Replacement>[];
    for (var method in methods) {
      var element = method.declaredFragment?.element as MethodElementImpl;

      var annotationData = _getAnnotationData(element)!;
      var bmhTable = _bmhTable(annotationData.needle, tableSize: 128);
      var kmpTable = _kmpTable(annotationData.needle);
      String addNeedleString = "";
      if (annotationData.addNeedleLength) {
        addNeedleString = "if (result >= 0) result += needle.length;";
      }
      String replaceWith =
          """
      static int ${element.name}(String haystack, int offset) {
        const String needle = '${annotationData.needle}';
        const List<int> bmhTable = [
          // Format hack.
          ${_formatListElements(bmhTable)}
        ];
        const List<int> kmpTable = [
          // Format hack.
          ${_formatListElements(kmpTable)}
        ];
        int result = _combinedBmhAndKmp(bmhTable, kmpTable, haystack,
                                        needle, offset);
        $addNeedleString
        return result;
      }""";
      replacements.add(
        _Replacement(
          method.firstTokenAfterCommentAndMetadata.offset,
          method.end,
          replaceWith,
        ),
      );
    }

    replacements.sort((a, b) => b.offset - a.offset);
    for (var replacement in replacements) {
      newCode =
          newCode.substring(0, replacement.offset) +
          replacement.text +
          newCode.substring(replacement.end);
    }

    return newCode;
  }

  static Future<String> _formatSortCode(String path, String code) async {
    var server = Server();
    await server.start();
    server.listenToOutput();

    await server.send('analysis.setAnalysisRoots', {
      'included': [path],
      'excluded': [],
    });

    Future<void> updateContent() async {
      await server.send('analysis.updateContent', {
        'files': {
          path: {'type': 'add', 'content': code},
        },
      });
    }

    await updateContent();
    var formatResponse = await server.send('edit.format', {
      'file': path,
      'selectionOffset': 0,
      'selectionLength': code.length,
    });
    var formatResult = EditFormatResult.fromJson(
      ResponseDecoder(null),
      'result',
      formatResponse,
    );
    code = SourceEdit.applySequence(code, formatResult.edits);

    await updateContent();
    var sortResponse = await server.send('edit.sortMembers', {'file': path});
    var sortResult = EditSortMembersResult.fromJson(
      ResponseDecoder(null),
      'result',
      sortResponse,
    );
    code = SourceEdit.applySequence(code, sortResult.edit.edits);

    await server.kill();
    return code;
  }
}

class _Replacement {
  final int offset;
  final int end;
  final String text;

  _Replacement(this.offset, this.end, this.text);
}
