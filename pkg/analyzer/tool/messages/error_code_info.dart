// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// Decodes a YAML object (obtained from `pkg/front_end/messages.yaml`) into a
/// map from error name to [ErrorCodeInfo].
Map<String, ErrorCodeInfo> decodeCfeMessagesYaml(Map<Object?, Object?> yaml) {
  var result = <String, ErrorCodeInfo>{};
  for (var entry in yaml.entries) {
    result[entry.key as String] =
        ErrorCodeInfo.fromYaml(entry.value as Map<Object?, Object?>);
  }
  return result;
}

/// Data tables mapping between CFE errors and their corresponding automatically
/// generated analyzer errors.
class CfeToAnalyzerErrorCodeTables {
  /// List of CFE errors for which analyzer errors should be automatically
  /// generated, organized by their `index` property.
  final List<ErrorCodeInfo?> indexToInfo = [];

  /// Map whose values are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose keys are the corresponding analyzer
  /// error name.  (Names are simple identifiers; they are not prefixed by the
  /// class name `ParserErrorCode`)
  final Map<String, ErrorCodeInfo> analyzerCodeToInfo = {};

  /// Map whose values are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose keys are the front end error name.
  final Map<String, ErrorCodeInfo> frontEndCodeToInfo = {};

  /// Map whose keys are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose values are the corresponding analyzer
  /// error name.  (Names are simple identifiers; they are not prefixed by the
  /// class name `ParserErrorCode`)
  final Map<ErrorCodeInfo, String> infoToAnalyzerCode = {};

  /// Map whose keys are the CFE errors for which analyzer errors should be
  /// automatically generated, and whose values are the front end error name.
  final Map<ErrorCodeInfo, String> infoToFrontEndCode = {};

  CfeToAnalyzerErrorCodeTables(Map<String, ErrorCodeInfo> messages) {
    for (var entry in messages.entries) {
      var errorCodeInfo = entry.value;
      var index = errorCodeInfo.index;
      if (index == null || errorCodeInfo.analyzerCode.length != 1) {
        continue;
      }
      var frontEndCode = entry.key;
      if (index < 1) {
        throw '''
$frontEndCode specifies index $index but indices must be 1 or greater.
For more information run:
pkg/front_end/tool/fasta generate-messages
''';
      }
      if (indexToInfo.length <= index) {
        indexToInfo.length = index + 1;
      }
      var previousEntryForIndex = indexToInfo[index];
      if (previousEntryForIndex != null) {
        throw 'Index $index used by both '
            '${infoToFrontEndCode[previousEntryForIndex]} and $frontEndCode';
      }
      indexToInfo[index] = errorCodeInfo;
      frontEndCodeToInfo[frontEndCode] = errorCodeInfo;
      infoToFrontEndCode[errorCodeInfo] = frontEndCode;
      var analyzerCodeLong = errorCodeInfo.analyzerCode.single;
      var expectedPrefix = 'ParserErrorCode.';
      if (!analyzerCodeLong.startsWith(expectedPrefix)) {
        throw 'Expected all analyzer error codes to be prefixed with '
            '${json.encode(expectedPrefix)}.  Found '
            '${json.encode(analyzerCodeLong)}.';
      }
      var analyzerCode = analyzerCodeLong.substring(expectedPrefix.length);
      infoToAnalyzerCode[errorCodeInfo] = analyzerCode;
      var previousEntryForAnalyzerCode = analyzerCodeToInfo[analyzerCode];
      if (previousEntryForAnalyzerCode != null) {
        throw 'Analyzer code $analyzerCode used by both '
            '${infoToFrontEndCode[previousEntryForAnalyzerCode]} and '
            '$frontEndCode';
      }
      analyzerCodeToInfo[analyzerCode] = errorCodeInfo;
    }
    for (int i = 1; i < indexToInfo.length; i++) {
      if (indexToInfo[i] == null) {
        throw 'Indices are not consecutive; no error code has index $i.';
      }
    }
  }
}

/// In-memory representation of error code information obtained from a
/// `messages.yaml` file.
class ErrorCodeInfo {
  /// Pattern used by the front end to identify placeholders in error message
  /// strings.  TODO(paulberry): share this regexp (and the code for interpreting
  /// it) between the CFE and analyzer.
  static final RegExp _placeholderPattern =
      RegExp("#\([-a-zA-Z0-9_]+\)(?:%\([0-9]*\)\.\([0-9]+\))?");

  /// For error code information obtained from the CFE, the set of analyzer
  /// error codes that corresponds to this error code, if any.
  final List<String> analyzerCode;

  /// `true` if diagnostics with this code have documentation for them that has
  /// been published.
  final bool hasPublishedDocs;

  /// For error code information obtained from the CFE, the index of the error
  /// in the analyzer's `fastaAnalyzerErrorCodes` table.
  final int? index;

  /// The template for the error message.
  final String template;

  /// If the error code has an associated tip/correction message, the template
  /// for it.
  final String? tip;

  ErrorCodeInfo(
      {this.analyzerCode = const [],
      this.hasPublishedDocs = false,
      this.index,
      required this.template,
      this.tip});

  /// Decodes an [ErrorCodeInfo] object from its YAML representation.
  ErrorCodeInfo.fromYaml(Map<Object?, Object?> yaml)
      : this(
            analyzerCode: _decodeAnalyzerCode(yaml['analyzerCode']),
            hasPublishedDocs: yaml['hasPublishedDocs'] as bool? ?? false,
            index: yaml['index'] as int?,
            template: yaml['template'] as String,
            tip: yaml['tip'] as String?);

  /// Generates a dart declaration for this error code, suitable for inclusion
  /// in the error class [className].  [errorCode] is the name of the error code
  /// to be generated.
  String toAnalyzerCode(String className, String errorCode) {
    var out = StringBuffer();
    out.writeln('$className(');
    out.writeln("'$errorCode',");
    final placeholderToIndexMap = _computePlaceholderToIndexMap();
    out.writeln(json.encode(_convertTemplate(placeholderToIndexMap, template)));
    final tip = this.tip;
    if (tip is String) {
      out.write(',correction: ');
      out.writeln(json.encode(_convertTemplate(placeholderToIndexMap, tip)));
    }
    if (hasPublishedDocs) {
      out.writeln(',hasPublishedDocs:true');
    }
    out.write(');');
    return out.toString();
  }

  /// Given a messages.yaml entry, come up with a mapping from placeholder
  /// patterns in its message and tip strings to their corresponding indices.
  Map<String, int> _computePlaceholderToIndexMap() {
    var mapping = <String, int>{};
    for (var value in [template, tip]) {
      if (value is! String) continue;
      for (Match match in _placeholderPattern.allMatches(value)) {
        // CFE supports a bunch of formatting options that we don't; make sure
        // none of those are used.
        if (match.group(0) != '#${match.group(1)}') {
          throw 'Template string ${json.encode(value)} contains unsupported '
              'placeholder pattern ${json.encode(match.group(0))}';
        }

        mapping[match.group(0)!] ??= mapping.length;
      }
    }
    return mapping;
  }

  /// Convert a CFE template string (which uses placeholders like `#string`) to
  /// an analyzer template string (which uses placeholders like `{0}`).
  static String _convertTemplate(
      Map<String, int> placeholderToIndexMap, String entry) {
    return entry.replaceAllMapped(_placeholderPattern,
        (match) => '{${placeholderToIndexMap[match.group(0)!]}}');
  }

  static List<String> _decodeAnalyzerCode(Object? value) {
    if (value == null) {
      return const [];
    } else if (value is String) {
      return [value];
    } else if (value is List) {
      return [for (var s in value) s as String];
    } else {
      throw 'Unrecognized analyzer code: $value';
    }
  }
}
