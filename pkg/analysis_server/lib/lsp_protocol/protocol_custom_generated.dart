// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unused_import
// ignore_for_file: unused_shown_name

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart'
    show listEqual, mapEqual;
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonEncoder = const JsonEncoder.withIndent('    ');

class AnalyzerStatusParams implements ToJsonable {
  static const jsonHandler = const LspJsonHandler(
      AnalyzerStatusParams.canParse, AnalyzerStatusParams.fromJson);

  AnalyzerStatusParams(this.isAnalyzing) {
    if (isAnalyzing == null) {
      throw 'isAnalyzing is required but was not provided';
    }
  }
  static AnalyzerStatusParams fromJson(Map<String, dynamic> json) {
    final isAnalyzing = json['isAnalyzing'];
    return new AnalyzerStatusParams(isAnalyzing);
  }

  final bool isAnalyzing;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['isAnalyzing'] =
        isAnalyzing ?? (throw 'isAnalyzing is required but was not set');
    return __result;
  }

  static bool canParse(Object obj, [LspJsonReporter reporter]) {
    reporter?.push();
    try {
      if (obj is Map<String, dynamic>) {
        reporter?.field = 'isAnalyzing';
        if (!obj.containsKey('isAnalyzing')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['isAnalyzing'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['isAnalyzing'] != null && !(obj['isAnalyzing'] is bool)) {
          reporter?.reportError("must be of type bool");
          return false;
        }
        return true;
      } else {
        reporter?.reportError("must be a JavaScript object");
        return false;
      }
    } finally {
      reporter?.pop();
    }
  }

  @override
  bool operator ==(other) {
    if (other is AnalyzerStatusParams) {
      return isAnalyzing == other.isAnalyzing && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, isAnalyzing.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ClosingLabel implements ToJsonable {
  static const jsonHandler =
      const LspJsonHandler(ClosingLabel.canParse, ClosingLabel.fromJson);

  ClosingLabel(this.range, this.label) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (label == null) {
      throw 'label is required but was not provided';
    }
  }
  static ClosingLabel fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final label = json['label'];
    return new ClosingLabel(range, label);
  }

  final String label;
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['label'] = label ?? (throw 'label is required but was not set');
    return __result;
  }

  static bool canParse(Object obj, [LspJsonReporter reporter]) {
    reporter?.push();
    try {
      if (obj is Map<String, dynamic>) {
        reporter?.field = 'range';
        if (!obj.containsKey('range')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['range'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['range'] != null && !(Range.canParse(obj['range'], reporter))) {
          reporter?.reportError("must be of type Range");
          return false;
        }
        reporter?.field = 'label';
        if (!obj.containsKey('label')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['label'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['label'] != null && !(obj['label'] is String)) {
          reporter?.reportError("must be of type String");
          return false;
        }
        return true;
      } else {
        reporter?.reportError("must be a JavaScript object");
        return false;
      }
    } finally {
      reporter?.pop();
    }
  }

  @override
  bool operator ==(other) {
    if (other is ClosingLabel) {
      return range == other.range && label == other.label && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = const LspJsonHandler(
      CompletionItemResolutionInfo.canParse,
      CompletionItemResolutionInfo.fromJson);

  CompletionItemResolutionInfo(this.file, this.offset, this.libId,
      this.displayUri, this.rOffset, this.rLength) {
    if (file == null) {
      throw 'file is required but was not provided';
    }
    if (offset == null) {
      throw 'offset is required but was not provided';
    }
    if (libId == null) {
      throw 'libId is required but was not provided';
    }
    if (displayUri == null) {
      throw 'displayUri is required but was not provided';
    }
    if (rOffset == null) {
      throw 'rOffset is required but was not provided';
    }
    if (rLength == null) {
      throw 'rLength is required but was not provided';
    }
  }
  static CompletionItemResolutionInfo fromJson(Map<String, dynamic> json) {
    final file = json['file'];
    final offset = json['offset'];
    final libId = json['libId'];
    final displayUri = json['displayUri'];
    final rOffset = json['rOffset'];
    final rLength = json['rLength'];
    return new CompletionItemResolutionInfo(
        file, offset, libId, displayUri, rOffset, rLength);
  }

  final String displayUri;
  final String file;
  final num libId;
  final num offset;
  final num rLength;
  final num rOffset;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['file'] = file ?? (throw 'file is required but was not set');
    __result['offset'] = offset ?? (throw 'offset is required but was not set');
    __result['libId'] = libId ?? (throw 'libId is required but was not set');
    __result['displayUri'] =
        displayUri ?? (throw 'displayUri is required but was not set');
    __result['rOffset'] =
        rOffset ?? (throw 'rOffset is required but was not set');
    __result['rLength'] =
        rLength ?? (throw 'rLength is required but was not set');
    return __result;
  }

  static bool canParse(Object obj, [LspJsonReporter reporter]) {
    reporter?.push();
    try {
      if (obj is Map<String, dynamic>) {
        reporter?.field = 'file';
        if (!obj.containsKey('file')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['file'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['file'] != null && !(obj['file'] is String)) {
          reporter?.reportError("must be of type String");
          return false;
        }
        reporter?.field = 'offset';
        if (!obj.containsKey('offset')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['offset'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['offset'] != null && !(obj['offset'] is num)) {
          reporter?.reportError("must be of type num");
          return false;
        }
        reporter?.field = 'libId';
        if (!obj.containsKey('libId')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['libId'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['libId'] != null && !(obj['libId'] is num)) {
          reporter?.reportError("must be of type num");
          return false;
        }
        reporter?.field = 'displayUri';
        if (!obj.containsKey('displayUri')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['displayUri'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['displayUri'] != null && !(obj['displayUri'] is String)) {
          reporter?.reportError("must be of type String");
          return false;
        }
        reporter?.field = 'rOffset';
        if (!obj.containsKey('rOffset')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['rOffset'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['rOffset'] != null && !(obj['rOffset'] is num)) {
          reporter?.reportError("must be of type num");
          return false;
        }
        reporter?.field = 'rLength';
        if (!obj.containsKey('rLength')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['rLength'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['rLength'] != null && !(obj['rLength'] is num)) {
          reporter?.reportError("must be of type num");
          return false;
        }
        return true;
      } else {
        reporter?.reportError("must be a JavaScript object");
        return false;
      }
    } finally {
      reporter?.pop();
    }
  }

  @override
  bool operator ==(other) {
    if (other is CompletionItemResolutionInfo) {
      return file == other.file &&
          offset == other.offset &&
          libId == other.libId &&
          displayUri == other.displayUri &&
          rOffset == other.rOffset &&
          rLength == other.rLength &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, libId.hashCode);
    hash = JenkinsSmiHash.combine(hash, displayUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, rOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, rLength.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DartDiagnosticServer implements ToJsonable {
  static const jsonHandler = const LspJsonHandler(
      DartDiagnosticServer.canParse, DartDiagnosticServer.fromJson);

  DartDiagnosticServer(this.port) {
    if (port == null) {
      throw 'port is required but was not provided';
    }
  }
  static DartDiagnosticServer fromJson(Map<String, dynamic> json) {
    final port = json['port'];
    return new DartDiagnosticServer(port);
  }

  final num port;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['port'] = port ?? (throw 'port is required but was not set');
    return __result;
  }

  static bool canParse(Object obj, [LspJsonReporter reporter]) {
    reporter?.push();
    try {
      if (obj is Map<String, dynamic>) {
        reporter?.field = 'port';
        if (!obj.containsKey('port')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['port'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['port'] != null && !(obj['port'] is num)) {
          reporter?.reportError("must be of type num");
          return false;
        }
        return true;
      } else {
        reporter?.reportError("must be a JavaScript object");
        return false;
      }
    } finally {
      reporter?.pop();
    }
  }

  @override
  bool operator ==(other) {
    if (other is DartDiagnosticServer) {
      return port == other.port && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishClosingLabelsParams implements ToJsonable {
  static const jsonHandler = const LspJsonHandler(
      PublishClosingLabelsParams.canParse, PublishClosingLabelsParams.fromJson);

  PublishClosingLabelsParams(this.uri, this.labels) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
    if (labels == null) {
      throw 'labels is required but was not provided';
    }
  }
  static PublishClosingLabelsParams fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final labels = json['labels']
        ?.map((item) => item != null ? ClosingLabel.fromJson(item) : null)
        ?.cast<ClosingLabel>()
        ?.toList();
    return new PublishClosingLabelsParams(uri, labels);
  }

  final List<ClosingLabel> labels;
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['labels'] = labels ?? (throw 'labels is required but was not set');
    return __result;
  }

  static bool canParse(Object obj, [LspJsonReporter reporter]) {
    reporter?.push();
    try {
      if (obj is Map<String, dynamic>) {
        reporter?.field = 'uri';
        if (!obj.containsKey('uri')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['uri'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['uri'] != null && !(obj['uri'] is String)) {
          reporter?.reportError("must be of type String");
          return false;
        }
        reporter?.field = 'labels';
        if (!obj.containsKey('labels')) {
          reporter?.reportError("may not be undefined");
          return false;
        }
        if (obj['labels'] == null) {
          reporter?.reportError("may not be null");
          return false;
        }
        if (obj['labels'] != null &&
            !((obj['labels'] is List &&
                (obj['labels'].every(
                    (item) => ClosingLabel.canParse(item, reporter)))))) {
          reporter?.reportError("must be of type List<ClosingLabel>");
          return false;
        }
        return true;
      } else {
        reporter?.reportError("must be a JavaScript object");
        return false;
      }
    } finally {
      reporter?.pop();
    }
  }

  @override
  bool operator ==(other) {
    if (other is PublishClosingLabelsParams) {
      return uri == other.uri &&
          listEqual(labels, other.labels,
              (ClosingLabel a, ClosingLabel b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, labels.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}
