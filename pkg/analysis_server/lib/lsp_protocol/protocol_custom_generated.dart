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

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;

import 'package:analysis_server/lsp_protocol/protocol_special.dart';
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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('isAnalyzing') &&
        obj['isAnalyzing'] is bool;
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

class CompletionItemResolutionInfo implements ToJsonable {
  static const jsonHandler = const LspJsonHandler(
      CompletionItemResolutionInfo.canParse,
      CompletionItemResolutionInfo.fromJson);

  CompletionItemResolutionInfo(
      this.file, this.offset, this.libraryId, this.autoImportDisplayUri) {
    if (file == null) {
      throw 'file is required but was not provided';
    }
    if (offset == null) {
      throw 'offset is required but was not provided';
    }
    if (libraryId == null) {
      throw 'libraryId is required but was not provided';
    }
    if (autoImportDisplayUri == null) {
      throw 'autoImportDisplayUri is required but was not provided';
    }
  }
  static CompletionItemResolutionInfo fromJson(Map<String, dynamic> json) {
    final file = json['file'];
    final offset = json['offset'];
    final libraryId = json['libraryId'];
    final autoImportDisplayUri = json['autoImportDisplayUri'];
    return new CompletionItemResolutionInfo(
        file, offset, libraryId, autoImportDisplayUri);
  }

  final String autoImportDisplayUri;
  final String file;
  final num libraryId;
  final num offset;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['file'] = file ?? (throw 'file is required but was not set');
    __result['offset'] = offset ?? (throw 'offset is required but was not set');
    __result['libraryId'] =
        libraryId ?? (throw 'libraryId is required but was not set');
    __result['autoImportDisplayUri'] = autoImportDisplayUri ??
        (throw 'autoImportDisplayUri is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('file') &&
        obj['file'] is String &&
        obj.containsKey('offset') &&
        obj['offset'] is num &&
        obj.containsKey('libraryId') &&
        obj['libraryId'] is num &&
        obj.containsKey('autoImportDisplayUri') &&
        obj['autoImportDisplayUri'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is CompletionItemResolutionInfo) {
      return file == other.file &&
          offset == other.offset &&
          libraryId == other.libraryId &&
          autoImportDisplayUri == other.autoImportDisplayUri &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, libraryId.hashCode);
    hash = JenkinsSmiHash.combine(hash, autoImportDisplayUri.hashCode);
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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('port') &&
        obj['port'] is num;
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
