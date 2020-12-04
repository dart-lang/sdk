// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:analysis_server_client/src/protocol/protocol_base.dart';
import 'package:analysis_server_client/src/protocol/protocol_common.dart';
import 'package:analysis_server_client/src/protocol/protocol_internal.dart';
import 'package:analysis_server_client/src/protocol/protocol_util.dart';

/// analysis.analyzedFiles params
///
/// {
///   "directories": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisAnalyzedFilesParams implements HasToJson {
  List<String> _directories;

  /// A list of the paths of the files that are being analyzed.
  List<String> get directories => _directories;

  /// A list of the paths of the files that are being analyzed.
  set directories(List<String> value) {
    assert(value != null);
    _directories = value;
  }

  AnalysisAnalyzedFilesParams(List<String> directories) {
    this.directories = directories;
  }

  factory AnalysisAnalyzedFilesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> directories;
      if (json.containsKey('directories')) {
        directories = jsonDecoder.decodeList(jsonPath + '.directories',
            json['directories'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'directories');
      }
      return AnalysisAnalyzedFilesParams(directories);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.analyzedFiles params', json);
    }
  }

  factory AnalysisAnalyzedFilesParams.fromNotification(
      Notification notification) {
    return AnalysisAnalyzedFilesParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['directories'] = directories;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.analyzedFiles', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisAnalyzedFilesParams) {
      return listEqual(
          directories, other.directories, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, directories.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.closingLabels params
///
/// {
///   "file": FilePath
///   "labels": List<ClosingLabel>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisClosingLabelsParams implements HasToJson {
  String _file;

  List<ClosingLabel> _labels;

  /// The file the closing labels relate to.
  String get file => _file;

  /// The file the closing labels relate to.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// Closing labels relevant to the file. Each item represents a useful label
  /// associated with some range with may be useful to display to the user
  /// within the editor at the end of the range to indicate what construct is
  /// closed at that location. Closing labels include constructor/method calls
  /// and List arguments that span multiple lines. Note that the ranges that
  /// are returned can overlap each other because they may be associated with
  /// constructs that can be nested.
  List<ClosingLabel> get labels => _labels;

  /// Closing labels relevant to the file. Each item represents a useful label
  /// associated with some range with may be useful to display to the user
  /// within the editor at the end of the range to indicate what construct is
  /// closed at that location. Closing labels include constructor/method calls
  /// and List arguments that span multiple lines. Note that the ranges that
  /// are returned can overlap each other because they may be associated with
  /// constructs that can be nested.
  set labels(List<ClosingLabel> value) {
    assert(value != null);
    _labels = value;
  }

  AnalysisClosingLabelsParams(String file, List<ClosingLabel> labels) {
    this.file = file;
    this.labels = labels;
  }

  factory AnalysisClosingLabelsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<ClosingLabel> labels;
      if (json.containsKey('labels')) {
        labels = jsonDecoder.decodeList(
            jsonPath + '.labels',
            json['labels'],
            (String jsonPath, Object json) =>
                ClosingLabel.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'labels');
      }
      return AnalysisClosingLabelsParams(file, labels);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.closingLabels params', json);
    }
  }

  factory AnalysisClosingLabelsParams.fromNotification(
      Notification notification) {
    return AnalysisClosingLabelsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['labels'] =
        labels.map((ClosingLabel value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.closingLabels', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisClosingLabelsParams) {
      return file == other.file &&
          listEqual(
              labels, other.labels, (ClosingLabel a, ClosingLabel b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, labels.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// AnalysisErrorFixes
///
/// {
///   "error": AnalysisError
///   "fixes": List<SourceChange>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorFixes implements HasToJson {
  AnalysisError _error;

  List<SourceChange> _fixes;

  /// The error with which the fixes are associated.
  AnalysisError get error => _error;

  /// The error with which the fixes are associated.
  set error(AnalysisError value) {
    assert(value != null);
    _error = value;
  }

  /// The fixes associated with the error.
  List<SourceChange> get fixes => _fixes;

  /// The fixes associated with the error.
  set fixes(List<SourceChange> value) {
    assert(value != null);
    _fixes = value;
  }

  AnalysisErrorFixes(AnalysisError error, {List<SourceChange> fixes}) {
    this.error = error;
    if (fixes == null) {
      this.fixes = <SourceChange>[];
    } else {
      this.fixes = fixes;
    }
  }

  factory AnalysisErrorFixes.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      AnalysisError error;
      if (json.containsKey('error')) {
        error = AnalysisError.fromJson(
            jsonDecoder, jsonPath + '.error', json['error']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'error');
      }
      List<SourceChange> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            jsonPath + '.fixes',
            json['fixes'],
            (String jsonPath, Object json) =>
                SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return AnalysisErrorFixes(error, fixes: fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisErrorFixes', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['error'] = error.toJson();
    result['fixes'] =
        fixes.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisErrorFixes) {
      return error == other.error &&
          listEqual(
              fixes, other.fixes, (SourceChange a, SourceChange b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, error.hashCode);
    hash = JenkinsSmiHash.combine(hash, fixes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.errors params
///
/// {
///   "file": FilePath
///   "errors": List<AnalysisError>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisErrorsParams implements HasToJson {
  String _file;

  List<AnalysisError> _errors;

  /// The file containing the errors.
  String get file => _file;

  /// The file containing the errors.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The errors contained in the file.
  List<AnalysisError> get errors => _errors;

  /// The errors contained in the file.
  set errors(List<AnalysisError> value) {
    assert(value != null);
    _errors = value;
  }

  AnalysisErrorsParams(String file, List<AnalysisError> errors) {
    this.file = file;
    this.errors = errors;
  }

  factory AnalysisErrorsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<AnalysisError> errors;
      if (json.containsKey('errors')) {
        errors = jsonDecoder.decodeList(
            jsonPath + '.errors',
            json['errors'],
            (String jsonPath, Object json) =>
                AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'errors');
      }
      return AnalysisErrorsParams(file, errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.errors params', json);
    }
  }

  factory AnalysisErrorsParams.fromNotification(Notification notification) {
    return AnalysisErrorsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['errors'] =
        errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.errors', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisErrorsParams) {
      return file == other.file &&
          listEqual(errors, other.errors,
              (AnalysisError a, AnalysisError b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, errors.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.flushResults params
///
/// {
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisFlushResultsParams implements HasToJson {
  List<String> _files;

  /// The files that are no longer being analyzed.
  List<String> get files => _files;

  /// The files that are no longer being analyzed.
  set files(List<String> value) {
    assert(value != null);
    _files = value;
  }

  AnalysisFlushResultsParams(List<String> files) {
    this.files = files;
  }

  factory AnalysisFlushResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            jsonPath + '.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisFlushResultsParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.flushResults params', json);
    }
  }

  factory AnalysisFlushResultsParams.fromNotification(
      Notification notification) {
    return AnalysisFlushResultsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['files'] = files;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.flushResults', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisFlushResultsParams) {
      return listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.folding params
///
/// {
///   "file": FilePath
///   "regions": List<FoldingRegion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisFoldingParams implements HasToJson {
  String _file;

  List<FoldingRegion> _regions;

  /// The file containing the folding regions.
  String get file => _file;

  /// The file containing the folding regions.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The folding regions contained in the file.
  List<FoldingRegion> get regions => _regions;

  /// The folding regions contained in the file.
  set regions(List<FoldingRegion> value) {
    assert(value != null);
    _regions = value;
  }

  AnalysisFoldingParams(String file, List<FoldingRegion> regions) {
    this.file = file;
    this.regions = regions;
  }

  factory AnalysisFoldingParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<FoldingRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            jsonPath + '.regions',
            json['regions'],
            (String jsonPath, Object json) =>
                FoldingRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisFoldingParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.folding params', json);
    }
  }

  factory AnalysisFoldingParams.fromNotification(Notification notification) {
    return AnalysisFoldingParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['regions'] =
        regions.map((FoldingRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.folding', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisFoldingParams) {
      return file == other.file &&
          listEqual(regions, other.regions,
              (FoldingRegion a, FoldingRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getErrors params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetErrorsParams implements RequestParams {
  String _file;

  /// The file for which errors are being requested.
  String get file => _file;

  /// The file for which errors are being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  AnalysisGetErrorsParams(String file) {
    this.file = file;
  }

  factory AnalysisGetErrorsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return AnalysisGetErrorsParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getErrors params', json);
    }
  }

  factory AnalysisGetErrorsParams.fromRequest(Request request) {
    return AnalysisGetErrorsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getErrors', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetErrorsParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getErrors result
///
/// {
///   "errors": List<AnalysisError>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetErrorsResult implements ResponseResult {
  List<AnalysisError> _errors;

  /// The errors associated with the file.
  List<AnalysisError> get errors => _errors;

  /// The errors associated with the file.
  set errors(List<AnalysisError> value) {
    assert(value != null);
    _errors = value;
  }

  AnalysisGetErrorsResult(List<AnalysisError> errors) {
    this.errors = errors;
  }

  factory AnalysisGetErrorsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<AnalysisError> errors;
      if (json.containsKey('errors')) {
        errors = jsonDecoder.decodeList(
            jsonPath + '.errors',
            json['errors'],
            (String jsonPath, Object json) =>
                AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'errors');
      }
      return AnalysisGetErrorsResult(errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getErrors result', json);
    }
  }

  factory AnalysisGetErrorsResult.fromResponse(Response response) {
    return AnalysisGetErrorsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['errors'] =
        errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetErrorsResult) {
      return listEqual(
          errors, other.errors, (AnalysisError a, AnalysisError b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, errors.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getHover params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetHoverParams implements RequestParams {
  String _file;

  int _offset;

  /// The file in which hover information is being requested.
  String get file => _file;

  /// The file in which hover information is being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset for which hover information is being requested.
  int get offset => _offset;

  /// The offset for which hover information is being requested.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  AnalysisGetHoverParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory AnalysisGetHoverParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return AnalysisGetHoverParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getHover params', json);
    }
  }

  factory AnalysisGetHoverParams.fromRequest(Request request) {
    return AnalysisGetHoverParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getHover', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetHoverParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getHover result
///
/// {
///   "hovers": List<HoverInformation>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetHoverResult implements ResponseResult {
  List<HoverInformation> _hovers;

  /// The hover information associated with the location. The list will be
  /// empty if no information could be determined for the location. The list
  /// can contain multiple items if the file is being analyzed in multiple
  /// contexts in conflicting ways (such as a part that is included in multiple
  /// libraries).
  List<HoverInformation> get hovers => _hovers;

  /// The hover information associated with the location. The list will be
  /// empty if no information could be determined for the location. The list
  /// can contain multiple items if the file is being analyzed in multiple
  /// contexts in conflicting ways (such as a part that is included in multiple
  /// libraries).
  set hovers(List<HoverInformation> value) {
    assert(value != null);
    _hovers = value;
  }

  AnalysisGetHoverResult(List<HoverInformation> hovers) {
    this.hovers = hovers;
  }

  factory AnalysisGetHoverResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<HoverInformation> hovers;
      if (json.containsKey('hovers')) {
        hovers = jsonDecoder.decodeList(
            jsonPath + '.hovers',
            json['hovers'],
            (String jsonPath, Object json) =>
                HoverInformation.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'hovers');
      }
      return AnalysisGetHoverResult(hovers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.getHover result', json);
    }
  }

  factory AnalysisGetHoverResult.fromResponse(Response response) {
    return AnalysisGetHoverResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['hovers'] =
        hovers.map((HoverInformation value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetHoverResult) {
      return listEqual(hovers, other.hovers,
          (HoverInformation a, HoverInformation b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, hovers.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getImportedElements params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetImportedElementsParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /// The file in which import information is being requested.
  String get file => _file;

  /// The file in which import information is being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the region for which import information is being requested.
  int get offset => _offset;

  /// The offset of the region for which import information is being requested.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region for which import information is being requested.
  int get length => _length;

  /// The length of the region for which import information is being requested.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  AnalysisGetImportedElementsParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory AnalysisGetImportedElementsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return AnalysisGetImportedElementsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getImportedElements params', json);
    }
  }

  factory AnalysisGetImportedElementsParams.fromRequest(Request request) {
    return AnalysisGetImportedElementsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getImportedElements', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetImportedElementsParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getImportedElements result
///
/// {
///   "elements": List<ImportedElements>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetImportedElementsResult implements ResponseResult {
  List<ImportedElements> _elements;

  /// The information about the elements that are referenced in the specified
  /// region of the specified file that come from imported libraries.
  List<ImportedElements> get elements => _elements;

  /// The information about the elements that are referenced in the specified
  /// region of the specified file that come from imported libraries.
  set elements(List<ImportedElements> value) {
    assert(value != null);
    _elements = value;
  }

  AnalysisGetImportedElementsResult(List<ImportedElements> elements) {
    this.elements = elements;
  }

  factory AnalysisGetImportedElementsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<ImportedElements> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            jsonPath + '.elements',
            json['elements'],
            (String jsonPath, Object json) =>
                ImportedElements.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      return AnalysisGetImportedElementsResult(elements);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getImportedElements result', json);
    }
  }

  factory AnalysisGetImportedElementsResult.fromResponse(Response response) {
    return AnalysisGetImportedElementsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['elements'] =
        elements.map((ImportedElements value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetImportedElementsResult) {
      return listEqual(elements, other.elements,
          (ImportedElements a, ImportedElements b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getLibraryDependencies params
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetLibraryDependenciesParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getLibraryDependencies', null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisGetLibraryDependenciesParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 246577680;
  }
}

/// analysis.getLibraryDependencies result
///
/// {
///   "libraries": List<FilePath>
///   "packageMap": Map<String, Map<String, List<FilePath>>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetLibraryDependenciesResult implements ResponseResult {
  List<String> _libraries;

  Map<String, Map<String, List<String>>> _packageMap;

  /// A list of the paths of library elements referenced by files in existing
  /// analysis roots.
  List<String> get libraries => _libraries;

  /// A list of the paths of library elements referenced by files in existing
  /// analysis roots.
  set libraries(List<String> value) {
    assert(value != null);
    _libraries = value;
  }

  /// A mapping from context source roots to package maps which map package
  /// names to source directories for use in client-side package URI
  /// resolution.
  Map<String, Map<String, List<String>>> get packageMap => _packageMap;

  /// A mapping from context source roots to package maps which map package
  /// names to source directories for use in client-side package URI
  /// resolution.
  set packageMap(Map<String, Map<String, List<String>>> value) {
    assert(value != null);
    _packageMap = value;
  }

  AnalysisGetLibraryDependenciesResult(List<String> libraries,
      Map<String, Map<String, List<String>>> packageMap) {
    this.libraries = libraries;
    this.packageMap = packageMap;
  }

  factory AnalysisGetLibraryDependenciesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> libraries;
      if (json.containsKey('libraries')) {
        libraries = jsonDecoder.decodeList(jsonPath + '.libraries',
            json['libraries'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraries');
      }
      Map<String, Map<String, List<String>>> packageMap;
      if (json.containsKey('packageMap')) {
        packageMap = jsonDecoder.decodeMap(
            jsonPath + '.packageMap', json['packageMap'],
            valueDecoder: (String jsonPath, Object json) =>
                jsonDecoder.decodeMap(jsonPath, json,
                    valueDecoder: (String jsonPath, Object json) => jsonDecoder
                        .decodeList(jsonPath, json, jsonDecoder.decodeString)));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'packageMap');
      }
      return AnalysisGetLibraryDependenciesResult(libraries, packageMap);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getLibraryDependencies result', json);
    }
  }

  factory AnalysisGetLibraryDependenciesResult.fromResponse(Response response) {
    return AnalysisGetLibraryDependenciesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['libraries'] = libraries;
    result['packageMap'] = packageMap;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetLibraryDependenciesResult) {
      return listEqual(
              libraries, other.libraries, (String a, String b) => a == b) &&
          mapEqual(
              packageMap,
              other.packageMap,
              (Map<String, List<String>> a, Map<String, List<String>> b) =>
                  mapEqual(
                      a,
                      b,
                      (List<String> a, List<String> b) =>
                          listEqual(a, b, (String a, String b) => a == b)));
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, libraries.hashCode);
    hash = JenkinsSmiHash.combine(hash, packageMap.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getNavigation params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetNavigationParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /// The file in which navigation information is being requested.
  String get file => _file;

  /// The file in which navigation information is being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the region for which navigation information is being
  /// requested.
  int get offset => _offset;

  /// The offset of the region for which navigation information is being
  /// requested.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region for which navigation information is being
  /// requested.
  int get length => _length;

  /// The length of the region for which navigation information is being
  /// requested.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  AnalysisGetNavigationParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory AnalysisGetNavigationParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return AnalysisGetNavigationParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getNavigation params', json);
    }
  }

  factory AnalysisGetNavigationParams.fromRequest(Request request) {
    return AnalysisGetNavigationParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getNavigation', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetNavigationParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getNavigation result
///
/// {
///   "files": List<FilePath>
///   "targets": List<NavigationTarget>
///   "regions": List<NavigationRegion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetNavigationResult implements ResponseResult {
  List<String> _files;

  List<NavigationTarget> _targets;

  List<NavigationRegion> _regions;

  /// A list of the paths of files that are referenced by the navigation
  /// targets.
  List<String> get files => _files;

  /// A list of the paths of files that are referenced by the navigation
  /// targets.
  set files(List<String> value) {
    assert(value != null);
    _files = value;
  }

  /// A list of the navigation targets that are referenced by the navigation
  /// regions.
  List<NavigationTarget> get targets => _targets;

  /// A list of the navigation targets that are referenced by the navigation
  /// regions.
  set targets(List<NavigationTarget> value) {
    assert(value != null);
    _targets = value;
  }

  /// A list of the navigation regions within the requested region of the file.
  List<NavigationRegion> get regions => _regions;

  /// A list of the navigation regions within the requested region of the file.
  set regions(List<NavigationRegion> value) {
    assert(value != null);
    _regions = value;
  }

  AnalysisGetNavigationResult(List<String> files,
      List<NavigationTarget> targets, List<NavigationRegion> regions) {
    this.files = files;
    this.targets = targets;
    this.regions = regions;
  }

  factory AnalysisGetNavigationResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            jsonPath + '.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      List<NavigationTarget> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
            jsonPath + '.targets',
            json['targets'],
            (String jsonPath, Object json) =>
                NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      List<NavigationRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            jsonPath + '.regions',
            json['regions'],
            (String jsonPath, Object json) =>
                NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisGetNavigationResult(files, targets, regions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getNavigation result', json);
    }
  }

  factory AnalysisGetNavigationResult.fromResponse(Response response) {
    return AnalysisGetNavigationResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['files'] = files;
    result['targets'] =
        targets.map((NavigationTarget value) => value.toJson()).toList();
    result['regions'] =
        regions.map((NavigationRegion value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetNavigationResult) {
      return listEqual(files, other.files, (String a, String b) => a == b) &&
          listEqual(targets, other.targets,
              (NavigationTarget a, NavigationTarget b) => a == b) &&
          listEqual(regions, other.regions,
              (NavigationRegion a, NavigationRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    hash = JenkinsSmiHash.combine(hash, targets.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getReachableSources params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetReachableSourcesParams implements RequestParams {
  String _file;

  /// The file for which reachable source information is being requested.
  String get file => _file;

  /// The file for which reachable source information is being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  AnalysisGetReachableSourcesParams(String file) {
    this.file = file;
  }

  factory AnalysisGetReachableSourcesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return AnalysisGetReachableSourcesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getReachableSources params', json);
    }
  }

  factory AnalysisGetReachableSourcesParams.fromRequest(Request request) {
    return AnalysisGetReachableSourcesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getReachableSources', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetReachableSourcesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getReachableSources result
///
/// {
///   "sources": Map<String, List<String>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetReachableSourcesResult implements ResponseResult {
  Map<String, List<String>> _sources;

  /// A mapping from source URIs to directly reachable source URIs. For
  /// example, a file "foo.dart" that imports "bar.dart" would have the
  /// corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
  /// "bar.dart" has further imports (or exports) there will be a mapping from
  /// the URI "file:///bar.dart" to them. To check if a specific URI is
  /// reachable from a given file, clients can check for its presence in the
  /// resulting key set.
  Map<String, List<String>> get sources => _sources;

  /// A mapping from source URIs to directly reachable source URIs. For
  /// example, a file "foo.dart" that imports "bar.dart" would have the
  /// corresponding mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If
  /// "bar.dart" has further imports (or exports) there will be a mapping from
  /// the URI "file:///bar.dart" to them. To check if a specific URI is
  /// reachable from a given file, clients can check for its presence in the
  /// resulting key set.
  set sources(Map<String, List<String>> value) {
    assert(value != null);
    _sources = value;
  }

  AnalysisGetReachableSourcesResult(Map<String, List<String>> sources) {
    this.sources = sources;
  }

  factory AnalysisGetReachableSourcesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Map<String, List<String>> sources;
      if (json.containsKey('sources')) {
        sources = jsonDecoder.decodeMap(jsonPath + '.sources', json['sources'],
            valueDecoder: (String jsonPath, Object json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'sources');
      }
      return AnalysisGetReachableSourcesResult(sources);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getReachableSources result', json);
    }
  }

  factory AnalysisGetReachableSourcesResult.fromResponse(Response response) {
    return AnalysisGetReachableSourcesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['sources'] = sources;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetReachableSourcesResult) {
      return mapEqual(
          sources,
          other.sources,
          (List<String> a, List<String> b) =>
              listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, sources.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getSignature params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetSignatureParams implements RequestParams {
  String _file;

  int _offset;

  /// The file in which signature information is being requested.
  String get file => _file;

  /// The file in which signature information is being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The location for which signature information is being requested.
  int get offset => _offset;

  /// The location for which signature information is being requested.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  AnalysisGetSignatureParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory AnalysisGetSignatureParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return AnalysisGetSignatureParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getSignature params', json);
    }
  }

  factory AnalysisGetSignatureParams.fromRequest(Request request) {
    return AnalysisGetSignatureParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.getSignature', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetSignatureParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.getSignature result
///
/// {
///   "name": String
///   "parameters": List<ParameterInfo>
///   "dartdoc": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisGetSignatureResult implements ResponseResult {
  String _name;

  List<ParameterInfo> _parameters;

  String _dartdoc;

  /// The name of the function being invoked at the given offset.
  String get name => _name;

  /// The name of the function being invoked at the given offset.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// A list of information about each of the parameters of the function being
  /// invoked.
  List<ParameterInfo> get parameters => _parameters;

  /// A list of information about each of the parameters of the function being
  /// invoked.
  set parameters(List<ParameterInfo> value) {
    assert(value != null);
    _parameters = value;
  }

  /// The dartdoc associated with the function being invoked. Other than the
  /// removal of the comment delimiters, including leading asterisks in the
  /// case of a block comment, the dartdoc is unprocessed markdown. This data
  /// is omitted if there is no referenced element, or if the element has no
  /// dartdoc.
  String get dartdoc => _dartdoc;

  /// The dartdoc associated with the function being invoked. Other than the
  /// removal of the comment delimiters, including leading asterisks in the
  /// case of a block comment, the dartdoc is unprocessed markdown. This data
  /// is omitted if there is no referenced element, or if the element has no
  /// dartdoc.
  set dartdoc(String value) {
    _dartdoc = value;
  }

  AnalysisGetSignatureResult(String name, List<ParameterInfo> parameters,
      {String dartdoc}) {
    this.name = name;
    this.parameters = parameters;
    this.dartdoc = dartdoc;
  }

  factory AnalysisGetSignatureResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      List<ParameterInfo> parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeList(
            jsonPath + '.parameters',
            json['parameters'],
            (String jsonPath, Object json) =>
                ParameterInfo.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      String dartdoc;
      if (json.containsKey('dartdoc')) {
        dartdoc =
            jsonDecoder.decodeString(jsonPath + '.dartdoc', json['dartdoc']);
      }
      return AnalysisGetSignatureResult(name, parameters, dartdoc: dartdoc);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.getSignature result', json);
    }
  }

  factory AnalysisGetSignatureResult.fromResponse(Response response) {
    return AnalysisGetSignatureResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['parameters'] =
        parameters.map((ParameterInfo value) => value.toJson()).toList();
    if (dartdoc != null) {
      result['dartdoc'] = dartdoc;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetSignatureResult) {
      return name == other.name &&
          listEqual(parameters, other.parameters,
              (ParameterInfo a, ParameterInfo b) => a == b) &&
          dartdoc == other.dartdoc;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, dartdoc.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.highlights params
///
/// {
///   "file": FilePath
///   "regions": List<HighlightRegion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisHighlightsParams implements HasToJson {
  String _file;

  List<HighlightRegion> _regions;

  /// The file containing the highlight regions.
  String get file => _file;

  /// The file containing the highlight regions.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The highlight regions contained in the file. Each highlight region
  /// represents a particular syntactic or semantic meaning associated with
  /// some range. Note that the highlight regions that are returned can overlap
  /// other highlight regions if there is more than one meaning associated with
  /// a particular region.
  List<HighlightRegion> get regions => _regions;

  /// The highlight regions contained in the file. Each highlight region
  /// represents a particular syntactic or semantic meaning associated with
  /// some range. Note that the highlight regions that are returned can overlap
  /// other highlight regions if there is more than one meaning associated with
  /// a particular region.
  set regions(List<HighlightRegion> value) {
    assert(value != null);
    _regions = value;
  }

  AnalysisHighlightsParams(String file, List<HighlightRegion> regions) {
    this.file = file;
    this.regions = regions;
  }

  factory AnalysisHighlightsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<HighlightRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            jsonPath + '.regions',
            json['regions'],
            (String jsonPath, Object json) =>
                HighlightRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      return AnalysisHighlightsParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.highlights params', json);
    }
  }

  factory AnalysisHighlightsParams.fromNotification(Notification notification) {
    return AnalysisHighlightsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['regions'] =
        regions.map((HighlightRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.highlights', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisHighlightsParams) {
      return file == other.file &&
          listEqual(regions, other.regions,
              (HighlightRegion a, HighlightRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.implemented params
///
/// {
///   "file": FilePath
///   "classes": List<ImplementedClass>
///   "members": List<ImplementedMember>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisImplementedParams implements HasToJson {
  String _file;

  List<ImplementedClass> _classes;

  List<ImplementedMember> _members;

  /// The file with which the implementations are associated.
  String get file => _file;

  /// The file with which the implementations are associated.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The classes defined in the file that are implemented or extended.
  List<ImplementedClass> get classes => _classes;

  /// The classes defined in the file that are implemented or extended.
  set classes(List<ImplementedClass> value) {
    assert(value != null);
    _classes = value;
  }

  /// The member defined in the file that are implemented or overridden.
  List<ImplementedMember> get members => _members;

  /// The member defined in the file that are implemented or overridden.
  set members(List<ImplementedMember> value) {
    assert(value != null);
    _members = value;
  }

  AnalysisImplementedParams(String file, List<ImplementedClass> classes,
      List<ImplementedMember> members) {
    this.file = file;
    this.classes = classes;
    this.members = members;
  }

  factory AnalysisImplementedParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<ImplementedClass> classes;
      if (json.containsKey('classes')) {
        classes = jsonDecoder.decodeList(
            jsonPath + '.classes',
            json['classes'],
            (String jsonPath, Object json) =>
                ImplementedClass.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'classes');
      }
      List<ImplementedMember> members;
      if (json.containsKey('members')) {
        members = jsonDecoder.decodeList(
            jsonPath + '.members',
            json['members'],
            (String jsonPath, Object json) =>
                ImplementedMember.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'members');
      }
      return AnalysisImplementedParams(file, classes, members);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.implemented params', json);
    }
  }

  factory AnalysisImplementedParams.fromNotification(
      Notification notification) {
    return AnalysisImplementedParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['classes'] =
        classes.map((ImplementedClass value) => value.toJson()).toList();
    result['members'] =
        members.map((ImplementedMember value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.implemented', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisImplementedParams) {
      return file == other.file &&
          listEqual(classes, other.classes,
              (ImplementedClass a, ImplementedClass b) => a == b) &&
          listEqual(members, other.members,
              (ImplementedMember a, ImplementedMember b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, classes.hashCode);
    hash = JenkinsSmiHash.combine(hash, members.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.invalidate params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
///   "delta": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisInvalidateParams implements HasToJson {
  String _file;

  int _offset;

  int _length;

  int _delta;

  /// The file whose information has been invalidated.
  String get file => _file;

  /// The file whose information has been invalidated.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the invalidated region.
  int get offset => _offset;

  /// The offset of the invalidated region.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the invalidated region.
  int get length => _length;

  /// The length of the invalidated region.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The delta to be applied to the offsets in information that follows the
  /// invalidated region in order to update it so that it doesn't need to be
  /// re-requested.
  int get delta => _delta;

  /// The delta to be applied to the offsets in information that follows the
  /// invalidated region in order to update it so that it doesn't need to be
  /// re-requested.
  set delta(int value) {
    assert(value != null);
    _delta = value;
  }

  AnalysisInvalidateParams(String file, int offset, int length, int delta) {
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.delta = delta;
  }

  factory AnalysisInvalidateParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      int delta;
      if (json.containsKey('delta')) {
        delta = jsonDecoder.decodeInt(jsonPath + '.delta', json['delta']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'delta');
      }
      return AnalysisInvalidateParams(file, offset, length, delta);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.invalidate params', json);
    }
  }

  factory AnalysisInvalidateParams.fromNotification(Notification notification) {
    return AnalysisInvalidateParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    result['delta'] = delta;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.invalidate', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisInvalidateParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length &&
          delta == other.delta;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, delta.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.navigation params
///
/// {
///   "file": FilePath
///   "regions": List<NavigationRegion>
///   "targets": List<NavigationTarget>
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisNavigationParams implements HasToJson {
  String _file;

  List<NavigationRegion> _regions;

  List<NavigationTarget> _targets;

  List<String> _files;

  /// The file containing the navigation regions.
  String get file => _file;

  /// The file containing the navigation regions.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The navigation regions contained in the file. The regions are sorted by
  /// their offsets. Each navigation region represents a list of targets
  /// associated with some range. The lists will usually contain a single
  /// target, but can contain more in the case of a part that is included in
  /// multiple libraries or in Dart code that is compiled against multiple
  /// versions of a package. Note that the navigation regions that are returned
  /// do not overlap other navigation regions.
  List<NavigationRegion> get regions => _regions;

  /// The navigation regions contained in the file. The regions are sorted by
  /// their offsets. Each navigation region represents a list of targets
  /// associated with some range. The lists will usually contain a single
  /// target, but can contain more in the case of a part that is included in
  /// multiple libraries or in Dart code that is compiled against multiple
  /// versions of a package. Note that the navigation regions that are returned
  /// do not overlap other navigation regions.
  set regions(List<NavigationRegion> value) {
    assert(value != null);
    _regions = value;
  }

  /// The navigation targets referenced in the file. They are referenced by
  /// NavigationRegions by their index in this array.
  List<NavigationTarget> get targets => _targets;

  /// The navigation targets referenced in the file. They are referenced by
  /// NavigationRegions by their index in this array.
  set targets(List<NavigationTarget> value) {
    assert(value != null);
    _targets = value;
  }

  /// The files containing navigation targets referenced in the file. They are
  /// referenced by NavigationTargets by their index in this array.
  List<String> get files => _files;

  /// The files containing navigation targets referenced in the file. They are
  /// referenced by NavigationTargets by their index in this array.
  set files(List<String> value) {
    assert(value != null);
    _files = value;
  }

  AnalysisNavigationParams(String file, List<NavigationRegion> regions,
      List<NavigationTarget> targets, List<String> files) {
    this.file = file;
    this.regions = regions;
    this.targets = targets;
    this.files = files;
  }

  factory AnalysisNavigationParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<NavigationRegion> regions;
      if (json.containsKey('regions')) {
        regions = jsonDecoder.decodeList(
            jsonPath + '.regions',
            json['regions'],
            (String jsonPath, Object json) =>
                NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'regions');
      }
      List<NavigationTarget> targets;
      if (json.containsKey('targets')) {
        targets = jsonDecoder.decodeList(
            jsonPath + '.targets',
            json['targets'],
            (String jsonPath, Object json) =>
                NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'targets');
      }
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            jsonPath + '.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisNavigationParams(file, regions, targets, files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.navigation params', json);
    }
  }

  factory AnalysisNavigationParams.fromNotification(Notification notification) {
    return AnalysisNavigationParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['regions'] =
        regions.map((NavigationRegion value) => value.toJson()).toList();
    result['targets'] =
        targets.map((NavigationTarget value) => value.toJson()).toList();
    result['files'] = files;
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.navigation', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisNavigationParams) {
      return file == other.file &&
          listEqual(regions, other.regions,
              (NavigationRegion a, NavigationRegion b) => a == b) &&
          listEqual(targets, other.targets,
              (NavigationTarget a, NavigationTarget b) => a == b) &&
          listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    hash = JenkinsSmiHash.combine(hash, targets.hashCode);
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.occurrences params
///
/// {
///   "file": FilePath
///   "occurrences": List<Occurrences>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOccurrencesParams implements HasToJson {
  String _file;

  List<Occurrences> _occurrences;

  /// The file in which the references occur.
  String get file => _file;

  /// The file in which the references occur.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The occurrences of references to elements within the file.
  List<Occurrences> get occurrences => _occurrences;

  /// The occurrences of references to elements within the file.
  set occurrences(List<Occurrences> value) {
    assert(value != null);
    _occurrences = value;
  }

  AnalysisOccurrencesParams(String file, List<Occurrences> occurrences) {
    this.file = file;
    this.occurrences = occurrences;
  }

  factory AnalysisOccurrencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<Occurrences> occurrences;
      if (json.containsKey('occurrences')) {
        occurrences = jsonDecoder.decodeList(
            jsonPath + '.occurrences',
            json['occurrences'],
            (String jsonPath, Object json) =>
                Occurrences.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return AnalysisOccurrencesParams(file, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.occurrences params', json);
    }
  }

  factory AnalysisOccurrencesParams.fromNotification(
      Notification notification) {
    return AnalysisOccurrencesParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['occurrences'] =
        occurrences.map((Occurrences value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.occurrences', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOccurrencesParams) {
      return file == other.file &&
          listEqual(occurrences, other.occurrences,
              (Occurrences a, Occurrences b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// AnalysisOptions
///
/// {
///   "enableAsync": optional bool
///   "enableDeferredLoading": optional bool
///   "enableEnums": optional bool
///   "enableNullAwareOperators": optional bool
///   "enableSuperMixins": optional bool
///   "generateDart2jsHints": optional bool
///   "generateHints": optional bool
///   "generateLints": optional bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOptions implements HasToJson {
  bool _enableAsync;

  bool _enableDeferredLoading;

  bool _enableEnums;

  bool _enableNullAwareOperators;

  bool _enableSuperMixins;

  bool _generateDart2jsHints;

  bool _generateHints;

  bool _generateLints;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed async
  /// feature.
  bool get enableAsync => _enableAsync;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed async
  /// feature.
  set enableAsync(bool value) {
    _enableAsync = value;
  }

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed deferred
  /// loading feature.
  bool get enableDeferredLoading => _enableDeferredLoading;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed deferred
  /// loading feature.
  set enableDeferredLoading(bool value) {
    _enableDeferredLoading = value;
  }

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed enum feature.
  bool get enableEnums => _enableEnums;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed enum feature.
  set enableEnums(bool value) {
    _enableEnums = value;
  }

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed "null aware
  /// operators" feature.
  bool get enableNullAwareOperators => _enableNullAwareOperators;

  /// Deprecated: this feature is always enabled.
  ///
  /// True if the client wants to enable support for the proposed "null aware
  /// operators" feature.
  set enableNullAwareOperators(bool value) {
    _enableNullAwareOperators = value;
  }

  /// True if the client wants to enable support for the proposed "less
  /// restricted mixins" proposal (DEP 34).
  bool get enableSuperMixins => _enableSuperMixins;

  /// True if the client wants to enable support for the proposed "less
  /// restricted mixins" proposal (DEP 34).
  set enableSuperMixins(bool value) {
    _enableSuperMixins = value;
  }

  /// True if hints that are specific to dart2js should be generated. This
  /// option is ignored if generateHints is false.
  bool get generateDart2jsHints => _generateDart2jsHints;

  /// True if hints that are specific to dart2js should be generated. This
  /// option is ignored if generateHints is false.
  set generateDart2jsHints(bool value) {
    _generateDart2jsHints = value;
  }

  /// True if hints should be generated as part of generating errors and
  /// warnings.
  bool get generateHints => _generateHints;

  /// True if hints should be generated as part of generating errors and
  /// warnings.
  set generateHints(bool value) {
    _generateHints = value;
  }

  /// True if lints should be generated as part of generating errors and
  /// warnings.
  bool get generateLints => _generateLints;

  /// True if lints should be generated as part of generating errors and
  /// warnings.
  set generateLints(bool value) {
    _generateLints = value;
  }

  AnalysisOptions(
      {bool enableAsync,
      bool enableDeferredLoading,
      bool enableEnums,
      bool enableNullAwareOperators,
      bool enableSuperMixins,
      bool generateDart2jsHints,
      bool generateHints,
      bool generateLints}) {
    this.enableAsync = enableAsync;
    this.enableDeferredLoading = enableDeferredLoading;
    this.enableEnums = enableEnums;
    this.enableNullAwareOperators = enableNullAwareOperators;
    this.enableSuperMixins = enableSuperMixins;
    this.generateDart2jsHints = generateDart2jsHints;
    this.generateHints = generateHints;
    this.generateLints = generateLints;
  }

  factory AnalysisOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool enableAsync;
      if (json.containsKey('enableAsync')) {
        enableAsync = jsonDecoder.decodeBool(
            jsonPath + '.enableAsync', json['enableAsync']);
      }
      bool enableDeferredLoading;
      if (json.containsKey('enableDeferredLoading')) {
        enableDeferredLoading = jsonDecoder.decodeBool(
            jsonPath + '.enableDeferredLoading', json['enableDeferredLoading']);
      }
      bool enableEnums;
      if (json.containsKey('enableEnums')) {
        enableEnums = jsonDecoder.decodeBool(
            jsonPath + '.enableEnums', json['enableEnums']);
      }
      bool enableNullAwareOperators;
      if (json.containsKey('enableNullAwareOperators')) {
        enableNullAwareOperators = jsonDecoder.decodeBool(
            jsonPath + '.enableNullAwareOperators',
            json['enableNullAwareOperators']);
      }
      bool enableSuperMixins;
      if (json.containsKey('enableSuperMixins')) {
        enableSuperMixins = jsonDecoder.decodeBool(
            jsonPath + '.enableSuperMixins', json['enableSuperMixins']);
      }
      bool generateDart2jsHints;
      if (json.containsKey('generateDart2jsHints')) {
        generateDart2jsHints = jsonDecoder.decodeBool(
            jsonPath + '.generateDart2jsHints', json['generateDart2jsHints']);
      }
      bool generateHints;
      if (json.containsKey('generateHints')) {
        generateHints = jsonDecoder.decodeBool(
            jsonPath + '.generateHints', json['generateHints']);
      }
      bool generateLints;
      if (json.containsKey('generateLints')) {
        generateLints = jsonDecoder.decodeBool(
            jsonPath + '.generateLints', json['generateLints']);
      }
      return AnalysisOptions(
          enableAsync: enableAsync,
          enableDeferredLoading: enableDeferredLoading,
          enableEnums: enableEnums,
          enableNullAwareOperators: enableNullAwareOperators,
          enableSuperMixins: enableSuperMixins,
          generateDart2jsHints: generateDart2jsHints,
          generateHints: generateHints,
          generateLints: generateLints);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisOptions', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (enableAsync != null) {
      result['enableAsync'] = enableAsync;
    }
    if (enableDeferredLoading != null) {
      result['enableDeferredLoading'] = enableDeferredLoading;
    }
    if (enableEnums != null) {
      result['enableEnums'] = enableEnums;
    }
    if (enableNullAwareOperators != null) {
      result['enableNullAwareOperators'] = enableNullAwareOperators;
    }
    if (enableSuperMixins != null) {
      result['enableSuperMixins'] = enableSuperMixins;
    }
    if (generateDart2jsHints != null) {
      result['generateDart2jsHints'] = generateDart2jsHints;
    }
    if (generateHints != null) {
      result['generateHints'] = generateHints;
    }
    if (generateLints != null) {
      result['generateLints'] = generateLints;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOptions) {
      return enableAsync == other.enableAsync &&
          enableDeferredLoading == other.enableDeferredLoading &&
          enableEnums == other.enableEnums &&
          enableNullAwareOperators == other.enableNullAwareOperators &&
          enableSuperMixins == other.enableSuperMixins &&
          generateDart2jsHints == other.generateDart2jsHints &&
          generateHints == other.generateHints &&
          generateLints == other.generateLints;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, enableAsync.hashCode);
    hash = JenkinsSmiHash.combine(hash, enableDeferredLoading.hashCode);
    hash = JenkinsSmiHash.combine(hash, enableEnums.hashCode);
    hash = JenkinsSmiHash.combine(hash, enableNullAwareOperators.hashCode);
    hash = JenkinsSmiHash.combine(hash, enableSuperMixins.hashCode);
    hash = JenkinsSmiHash.combine(hash, generateDart2jsHints.hashCode);
    hash = JenkinsSmiHash.combine(hash, generateHints.hashCode);
    hash = JenkinsSmiHash.combine(hash, generateLints.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.outline params
///
/// {
///   "file": FilePath
///   "kind": FileKind
///   "libraryName": optional String
///   "outline": Outline
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOutlineParams implements HasToJson {
  String _file;

  FileKind _kind;

  String _libraryName;

  Outline _outline;

  /// The file with which the outline is associated.
  String get file => _file;

  /// The file with which the outline is associated.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The kind of the file.
  FileKind get kind => _kind;

  /// The kind of the file.
  set kind(FileKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The name of the library defined by the file using a "library" directive,
  /// or referenced by a "part of" directive. If both "library" and "part of"
  /// directives are present, then the "library" directive takes precedence.
  /// This field will be omitted if the file has neither "library" nor "part
  /// of" directives.
  String get libraryName => _libraryName;

  /// The name of the library defined by the file using a "library" directive,
  /// or referenced by a "part of" directive. If both "library" and "part of"
  /// directives are present, then the "library" directive takes precedence.
  /// This field will be omitted if the file has neither "library" nor "part
  /// of" directives.
  set libraryName(String value) {
    _libraryName = value;
  }

  /// The outline associated with the file.
  Outline get outline => _outline;

  /// The outline associated with the file.
  set outline(Outline value) {
    assert(value != null);
    _outline = value;
  }

  AnalysisOutlineParams(String file, FileKind kind, Outline outline,
      {String libraryName}) {
    this.file = file;
    this.kind = kind;
    this.libraryName = libraryName;
    this.outline = outline;
  }

  factory AnalysisOutlineParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      FileKind kind;
      if (json.containsKey('kind')) {
        kind = FileKind.fromJson(jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String libraryName;
      if (json.containsKey('libraryName')) {
        libraryName = jsonDecoder.decodeString(
            jsonPath + '.libraryName', json['libraryName']);
      }
      Outline outline;
      if (json.containsKey('outline')) {
        outline = Outline.fromJson(
            jsonDecoder, jsonPath + '.outline', json['outline']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'outline');
      }
      return AnalysisOutlineParams(file, kind, outline,
          libraryName: libraryName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.outline params', json);
    }
  }

  factory AnalysisOutlineParams.fromNotification(Notification notification) {
    return AnalysisOutlineParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['kind'] = kind.toJson();
    if (libraryName != null) {
      result['libraryName'] = libraryName;
    }
    result['outline'] = outline.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.outline', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOutlineParams) {
      return file == other.file &&
          kind == other.kind &&
          libraryName == other.libraryName &&
          outline == other.outline;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, libraryName.hashCode);
    hash = JenkinsSmiHash.combine(hash, outline.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.overrides params
///
/// {
///   "file": FilePath
///   "overrides": List<Override>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisOverridesParams implements HasToJson {
  String _file;

  List<Override> _overrides;

  /// The file with which the overrides are associated.
  String get file => _file;

  /// The file with which the overrides are associated.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The overrides associated with the file.
  List<Override> get overrides => _overrides;

  /// The overrides associated with the file.
  set overrides(List<Override> value) {
    assert(value != null);
    _overrides = value;
  }

  AnalysisOverridesParams(String file, List<Override> overrides) {
    this.file = file;
    this.overrides = overrides;
  }

  factory AnalysisOverridesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<Override> overrides;
      if (json.containsKey('overrides')) {
        overrides = jsonDecoder.decodeList(
            jsonPath + '.overrides',
            json['overrides'],
            (String jsonPath, Object json) =>
                Override.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'overrides');
      }
      return AnalysisOverridesParams(file, overrides);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analysis.overrides params', json);
    }
  }

  factory AnalysisOverridesParams.fromNotification(Notification notification) {
    return AnalysisOverridesParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['overrides'] =
        overrides.map((Override value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return Notification('analysis.overrides', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisOverridesParams) {
      return file == other.file &&
          listEqual(
              overrides, other.overrides, (Override a, Override b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, overrides.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.reanalyze params
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisReanalyzeParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.reanalyze', null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisReanalyzeParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 613039876;
  }
}

/// analysis.reanalyze result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisReanalyzeResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisReanalyzeResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 846803925;
  }
}

/// AnalysisService
///
/// enum {
///   CLOSING_LABELS
///   FOLDING
///   HIGHLIGHTS
///   IMPLEMENTED
///   INVALIDATE
///   NAVIGATION
///   OCCURRENCES
///   OUTLINE
///   OVERRIDES
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisService implements Enum {
  static const AnalysisService CLOSING_LABELS =
      AnalysisService._('CLOSING_LABELS');

  static const AnalysisService FOLDING = AnalysisService._('FOLDING');

  static const AnalysisService HIGHLIGHTS = AnalysisService._('HIGHLIGHTS');

  static const AnalysisService IMPLEMENTED = AnalysisService._('IMPLEMENTED');

  /// This service is not currently implemented and will become a
  /// GeneralAnalysisService in a future release.
  static const AnalysisService INVALIDATE = AnalysisService._('INVALIDATE');

  static const AnalysisService NAVIGATION = AnalysisService._('NAVIGATION');

  static const AnalysisService OCCURRENCES = AnalysisService._('OCCURRENCES');

  static const AnalysisService OUTLINE = AnalysisService._('OUTLINE');

  static const AnalysisService OVERRIDES = AnalysisService._('OVERRIDES');

  /// A list containing all of the enum values that are defined.
  static const List<AnalysisService> VALUES = <AnalysisService>[
    CLOSING_LABELS,
    FOLDING,
    HIGHLIGHTS,
    IMPLEMENTED,
    INVALIDATE,
    NAVIGATION,
    OCCURRENCES,
    OUTLINE,
    OVERRIDES
  ];

  @override
  final String name;

  const AnalysisService._(this.name);

  factory AnalysisService(String name) {
    switch (name) {
      case 'CLOSING_LABELS':
        return CLOSING_LABELS;
      case 'FOLDING':
        return FOLDING;
      case 'HIGHLIGHTS':
        return HIGHLIGHTS;
      case 'IMPLEMENTED':
        return IMPLEMENTED;
      case 'INVALIDATE':
        return INVALIDATE;
      case 'NAVIGATION':
        return NAVIGATION;
      case 'OCCURRENCES':
        return OCCURRENCES;
      case 'OUTLINE':
        return OUTLINE;
      case 'OVERRIDES':
        return OVERRIDES;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory AnalysisService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return AnalysisService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'AnalysisService', json);
  }

  @override
  String toString() => 'AnalysisService.$name';

  String toJson() => name;
}

/// analysis.setAnalysisRoots params
///
/// {
///   "included": List<FilePath>
///   "excluded": List<FilePath>
///   "packageRoots": optional Map<FilePath, FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetAnalysisRootsParams implements RequestParams {
  List<String> _included;

  List<String> _excluded;

  Map<String, String> _packageRoots;

  /// A list of the files and directories that should be analyzed.
  List<String> get included => _included;

  /// A list of the files and directories that should be analyzed.
  set included(List<String> value) {
    assert(value != null);
    _included = value;
  }

  /// A list of the files and directories within the included directories that
  /// should not be analyzed.
  List<String> get excluded => _excluded;

  /// A list of the files and directories within the included directories that
  /// should not be analyzed.
  set excluded(List<String> value) {
    assert(value != null);
    _excluded = value;
  }

  /// A mapping from source directories to package roots that should override
  /// the normal package: URI resolution mechanism.
  ///
  /// If a package root is a file, then the analyzer will behave as though that
  /// file is a ".packages" file in the source directory. The effect is the
  /// same as specifying the file as a "--packages" parameter to the Dart VM
  /// when executing any Dart file inside the source directory.
  ///
  /// Files in any directories that are not overridden by this mapping have
  /// their package: URI's resolved using the normal pubspec.yaml mechanism. If
  /// this field is absent, or the empty map is specified, that indicates that
  /// the normal pubspec.yaml mechanism should always be used.
  Map<String, String> get packageRoots => _packageRoots;

  /// A mapping from source directories to package roots that should override
  /// the normal package: URI resolution mechanism.
  ///
  /// If a package root is a file, then the analyzer will behave as though that
  /// file is a ".packages" file in the source directory. The effect is the
  /// same as specifying the file as a "--packages" parameter to the Dart VM
  /// when executing any Dart file inside the source directory.
  ///
  /// Files in any directories that are not overridden by this mapping have
  /// their package: URI's resolved using the normal pubspec.yaml mechanism. If
  /// this field is absent, or the empty map is specified, that indicates that
  /// the normal pubspec.yaml mechanism should always be used.
  set packageRoots(Map<String, String> value) {
    _packageRoots = value;
  }

  AnalysisSetAnalysisRootsParams(List<String> included, List<String> excluded,
      {Map<String, String> packageRoots}) {
    this.included = included;
    this.excluded = excluded;
    this.packageRoots = packageRoots;
  }

  factory AnalysisSetAnalysisRootsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> included;
      if (json.containsKey('included')) {
        included = jsonDecoder.decodeList(
            jsonPath + '.included', json['included'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'included');
      }
      List<String> excluded;
      if (json.containsKey('excluded')) {
        excluded = jsonDecoder.decodeList(
            jsonPath + '.excluded', json['excluded'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'excluded');
      }
      Map<String, String> packageRoots;
      if (json.containsKey('packageRoots')) {
        packageRoots = jsonDecoder.decodeMap(
            jsonPath + '.packageRoots', json['packageRoots'],
            valueDecoder: jsonDecoder.decodeString);
      }
      return AnalysisSetAnalysisRootsParams(included, excluded,
          packageRoots: packageRoots);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setAnalysisRoots params', json);
    }
  }

  factory AnalysisSetAnalysisRootsParams.fromRequest(Request request) {
    return AnalysisSetAnalysisRootsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['included'] = included;
    result['excluded'] = excluded;
    if (packageRoots != null) {
      result['packageRoots'] = packageRoots;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setAnalysisRoots', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetAnalysisRootsParams) {
      return listEqual(
              included, other.included, (String a, String b) => a == b) &&
          listEqual(excluded, other.excluded, (String a, String b) => a == b) &&
          mapEqual(
              packageRoots, other.packageRoots, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, included.hashCode);
    hash = JenkinsSmiHash.combine(hash, excluded.hashCode);
    hash = JenkinsSmiHash.combine(hash, packageRoots.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.setAnalysisRoots result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetAnalysisRootsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisSetAnalysisRootsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 866004753;
  }
}

/// analysis.setGeneralSubscriptions params
///
/// {
///   "subscriptions": List<GeneralAnalysisService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetGeneralSubscriptionsParams implements RequestParams {
  List<GeneralAnalysisService> _subscriptions;

  /// A list of the services being subscribed to.
  List<GeneralAnalysisService> get subscriptions => _subscriptions;

  /// A list of the services being subscribed to.
  set subscriptions(List<GeneralAnalysisService> value) {
    assert(value != null);
    _subscriptions = value;
  }

  AnalysisSetGeneralSubscriptionsParams(
      List<GeneralAnalysisService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<GeneralAnalysisService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + '.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object json) =>
                GeneralAnalysisService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return AnalysisSetGeneralSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setGeneralSubscriptions params', json);
    }
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromRequest(Request request) {
    return AnalysisSetGeneralSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['subscriptions'] = subscriptions
        .map((GeneralAnalysisService value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setGeneralSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetGeneralSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (GeneralAnalysisService a, GeneralAnalysisService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.setGeneralSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetGeneralSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisSetGeneralSubscriptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 386759562;
  }
}

/// analysis.setPriorityFiles params
///
/// {
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetPriorityFilesParams implements RequestParams {
  List<String> _files;

  /// The files that are to be a priority for analysis.
  List<String> get files => _files;

  /// The files that are to be a priority for analysis.
  set files(List<String> value) {
    assert(value != null);
    _files = value;
  }

  AnalysisSetPriorityFilesParams(List<String> files) {
    this.files = files;
  }

  factory AnalysisSetPriorityFilesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            jsonPath + '.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setPriorityFiles params', json);
    }
  }

  factory AnalysisSetPriorityFilesParams.fromRequest(Request request) {
    return AnalysisSetPriorityFilesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['files'] = files;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setPriorityFiles', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetPriorityFilesParams) {
      return listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.setPriorityFiles result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetPriorityFilesResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisSetPriorityFilesResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 330050055;
  }
}

/// analysis.setSubscriptions params
///
/// {
///   "subscriptions": Map<AnalysisService, List<FilePath>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetSubscriptionsParams implements RequestParams {
  Map<AnalysisService, List<String>> _subscriptions;

  /// A table mapping services to a list of the files being subscribed to the
  /// service.
  Map<AnalysisService, List<String>> get subscriptions => _subscriptions;

  /// A table mapping services to a list of the files being subscribed to the
  /// service.
  set subscriptions(Map<AnalysisService, List<String>> value) {
    assert(value != null);
    _subscriptions = value;
  }

  AnalysisSetSubscriptionsParams(
      Map<AnalysisService, List<String>> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory AnalysisSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Map<AnalysisService, List<String>> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeMap(
            jsonPath + '.subscriptions', json['subscriptions'],
            keyDecoder: (String jsonPath, Object json) =>
                AnalysisService.fromJson(jsonDecoder, jsonPath, json),
            valueDecoder: (String jsonPath, Object json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.setSubscriptions params', json);
    }
  }

  factory AnalysisSetSubscriptionsParams.fromRequest(Request request) {
    return AnalysisSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['subscriptions'] = mapMap(subscriptions,
        keyCallback: (AnalysisService value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetSubscriptionsParams) {
      return mapEqual(
          subscriptions,
          other.subscriptions,
          (List<String> a, List<String> b) =>
              listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisSetSubscriptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 218088493;
  }
}

/// AnalysisStatus
///
/// {
///   "isAnalyzing": bool
///   "analysisTarget": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisStatus implements HasToJson {
  bool _isAnalyzing;

  String _analysisTarget;

  /// True if analysis is currently being performed.
  bool get isAnalyzing => _isAnalyzing;

  /// True if analysis is currently being performed.
  set isAnalyzing(bool value) {
    assert(value != null);
    _isAnalyzing = value;
  }

  /// The name of the current target of analysis. This field is omitted if
  /// analyzing is false.
  String get analysisTarget => _analysisTarget;

  /// The name of the current target of analysis. This field is omitted if
  /// analyzing is false.
  set analysisTarget(String value) {
    _analysisTarget = value;
  }

  AnalysisStatus(bool isAnalyzing, {String analysisTarget}) {
    this.isAnalyzing = isAnalyzing;
    this.analysisTarget = analysisTarget;
  }

  factory AnalysisStatus.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool isAnalyzing;
      if (json.containsKey('isAnalyzing')) {
        isAnalyzing = jsonDecoder.decodeBool(
            jsonPath + '.isAnalyzing', json['isAnalyzing']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isAnalyzing');
      }
      String analysisTarget;
      if (json.containsKey('analysisTarget')) {
        analysisTarget = jsonDecoder.decodeString(
            jsonPath + '.analysisTarget', json['analysisTarget']);
      }
      return AnalysisStatus(isAnalyzing, analysisTarget: analysisTarget);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AnalysisStatus', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['isAnalyzing'] = isAnalyzing;
    if (analysisTarget != null) {
      result['analysisTarget'] = analysisTarget;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisStatus) {
      return isAnalyzing == other.isAnalyzing &&
          analysisTarget == other.analysisTarget;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, isAnalyzing.hashCode);
    hash = JenkinsSmiHash.combine(hash, analysisTarget.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.updateContent params
///
/// {
///   "files": Map<FilePath, AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentParams implements RequestParams {
  Map<String, dynamic> _files;

  /// A table mapping the files whose content has changed to a description of
  /// the content change.
  Map<String, dynamic> get files => _files;

  /// A table mapping the files whose content has changed to a description of
  /// the content change.
  set files(Map<String, dynamic> value) {
    assert(value != null);
    _files = value;
  }

  AnalysisUpdateContentParams(Map<String, dynamic> files) {
    this.files = files;
  }

  factory AnalysisUpdateContentParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Map<String, dynamic> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeMap(jsonPath + '.files', json['files'],
            valueDecoder: (String jsonPath, Object json) =>
                jsonDecoder.decodeUnion(jsonPath, json, 'type', {
                  'add': (String jsonPath, Object json) =>
                      AddContentOverlay.fromJson(jsonDecoder, jsonPath, json),
                  'change': (String jsonPath, Object json) =>
                      ChangeContentOverlay.fromJson(
                          jsonDecoder, jsonPath, json),
                  'remove': (String jsonPath, Object json) =>
                      RemoveContentOverlay.fromJson(jsonDecoder, jsonPath, json)
                }));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.updateContent params', json);
    }
  }

  factory AnalysisUpdateContentParams.fromRequest(Request request) {
    return AnalysisUpdateContentParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['files'] =
        mapMap(files, valueCallback: (dynamic value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.updateContent', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateContentParams) {
      return mapEqual(files, other.files, (dynamic a, dynamic b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.updateContent result
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateContentResult implements ResponseResult {
  AnalysisUpdateContentResult();

  factory AnalysisUpdateContentResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      return AnalysisUpdateContentResult();
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.updateContent result', json);
    }
  }

  factory AnalysisUpdateContentResult.fromResponse(Response response) {
    return AnalysisUpdateContentResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateContentResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.updateOptions params
///
/// {
///   "options": AnalysisOptions
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateOptionsParams implements RequestParams {
  AnalysisOptions _options;

  /// The options that are to be used to control analysis.
  AnalysisOptions get options => _options;

  /// The options that are to be used to control analysis.
  set options(AnalysisOptions value) {
    assert(value != null);
    _options = value;
  }

  AnalysisUpdateOptionsParams(AnalysisOptions options) {
    this.options = options;
  }

  factory AnalysisUpdateOptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      AnalysisOptions options;
      if (json.containsKey('options')) {
        options = AnalysisOptions.fromJson(
            jsonDecoder, jsonPath + '.options', json['options']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'options');
      }
      return AnalysisUpdateOptionsParams(options);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'analysis.updateOptions params', json);
    }
  }

  factory AnalysisUpdateOptionsParams.fromRequest(Request request) {
    return AnalysisUpdateOptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['options'] = options.toJson();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analysis.updateOptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateOptionsParams) {
      return options == other.options;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analysis.updateOptions result
///
/// Clients may not extend, implement or mix-in this class.
class AnalysisUpdateOptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateOptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 179689467;
  }
}

/// analytics.enable params
///
/// {
///   "value": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsEnableParams implements RequestParams {
  bool _value;

  /// Enable or disable analytics.
  bool get value => _value;

  /// Enable or disable analytics.
  set value(bool value) {
    assert(value != null);
    _value = value;
  }

  AnalyticsEnableParams(bool value) {
    this.value = value;
  }

  factory AnalyticsEnableParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool value;
      if (json.containsKey('value')) {
        value = jsonDecoder.decodeBool(jsonPath + '.value', json['value']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'value');
      }
      return AnalyticsEnableParams(value);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.enable params', json);
    }
  }

  factory AnalyticsEnableParams.fromRequest(Request request) {
    return AnalyticsEnableParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['value'] = value;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.enable', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsEnableParams) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analytics.enable result
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsEnableResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalyticsEnableResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 237990792;
  }
}

/// analytics.isEnabled params
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsIsEnabledParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.isEnabled', null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalyticsIsEnabledParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 57215544;
  }
}

/// analytics.isEnabled result
///
/// {
///   "enabled": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsIsEnabledResult implements ResponseResult {
  bool _enabled;

  /// Whether sending analytics is enabled or not.
  bool get enabled => _enabled;

  /// Whether sending analytics is enabled or not.
  set enabled(bool value) {
    assert(value != null);
    _enabled = value;
  }

  AnalyticsIsEnabledResult(bool enabled) {
    this.enabled = enabled;
  }

  factory AnalyticsIsEnabledResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool enabled;
      if (json.containsKey('enabled')) {
        enabled =
            jsonDecoder.decodeBool(jsonPath + '.enabled', json['enabled']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'enabled');
      }
      return AnalyticsIsEnabledResult(enabled);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.isEnabled result', json);
    }
  }

  factory AnalyticsIsEnabledResult.fromResponse(Response response) {
    return AnalyticsIsEnabledResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['enabled'] = enabled;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsIsEnabledResult) {
      return enabled == other.enabled;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, enabled.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analytics.sendEvent params
///
/// {
///   "action": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendEventParams implements RequestParams {
  String _action;

  /// The value used to indicate which action was performed.
  String get action => _action;

  /// The value used to indicate which action was performed.
  set action(String value) {
    assert(value != null);
    _action = value;
  }

  AnalyticsSendEventParams(String action) {
    this.action = action;
  }

  factory AnalyticsSendEventParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String action;
      if (json.containsKey('action')) {
        action = jsonDecoder.decodeString(jsonPath + '.action', json['action']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'action');
      }
      return AnalyticsSendEventParams(action);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.sendEvent params', json);
    }
  }

  factory AnalyticsSendEventParams.fromRequest(Request request) {
    return AnalyticsSendEventParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['action'] = action;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.sendEvent', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendEventParams) {
      return action == other.action;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, action.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analytics.sendEvent result
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendEventResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendEventResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 227063188;
  }
}

/// analytics.sendTiming params
///
/// {
///   "event": String
///   "millis": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendTimingParams implements RequestParams {
  String _event;

  int _millis;

  /// The name of the event.
  String get event => _event;

  /// The name of the event.
  set event(String value) {
    assert(value != null);
    _event = value;
  }

  /// The duration of the event in milliseconds.
  int get millis => _millis;

  /// The duration of the event in milliseconds.
  set millis(int value) {
    assert(value != null);
    _millis = value;
  }

  AnalyticsSendTimingParams(String event, int millis) {
    this.event = event;
    this.millis = millis;
  }

  factory AnalyticsSendTimingParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String event;
      if (json.containsKey('event')) {
        event = jsonDecoder.decodeString(jsonPath + '.event', json['event']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'event');
      }
      int millis;
      if (json.containsKey('millis')) {
        millis = jsonDecoder.decodeInt(jsonPath + '.millis', json['millis']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'millis');
      }
      return AnalyticsSendTimingParams(event, millis);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'analytics.sendTiming params', json);
    }
  }

  factory AnalyticsSendTimingParams.fromRequest(Request request) {
    return AnalyticsSendTimingParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['event'] = event;
    result['millis'] = millis;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'analytics.sendTiming', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendTimingParams) {
      return event == other.event && millis == other.millis;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, event.hashCode);
    hash = JenkinsSmiHash.combine(hash, millis.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// analytics.sendTiming result
///
/// Clients may not extend, implement or mix-in this class.
class AnalyticsSendTimingResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendTimingResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 875010924;
  }
}

/// AvailableSuggestion
///
/// {
///   "label": String
///   "declaringLibraryUri": String
///   "element": Element
///   "defaultArgumentListString": optional String
///   "defaultArgumentListTextRanges": optional List<int>
///   "parameterNames": optional List<String>
///   "parameterTypes": optional List<String>
///   "relevanceTags": optional List<AvailableSuggestionRelevanceTag>
///   "requiredParameterCount": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AvailableSuggestion implements HasToJson {
  String _label;

  String _declaringLibraryUri;

  Element _element;

  String _defaultArgumentListString;

  List<int> _defaultArgumentListTextRanges;

  List<String> _parameterNames;

  List<String> _parameterTypes;

  List<String> _relevanceTags;

  int _requiredParameterCount;

  /// The identifier to present to the user for code completion.
  String get label => _label;

  /// The identifier to present to the user for code completion.
  set label(String value) {
    assert(value != null);
    _label = value;
  }

  /// The URI of the library that declares the element being suggested, not the
  /// URI of the library associated with the enclosing AvailableSuggestionSet.
  String get declaringLibraryUri => _declaringLibraryUri;

  /// The URI of the library that declares the element being suggested, not the
  /// URI of the library associated with the enclosing AvailableSuggestionSet.
  set declaringLibraryUri(String value) {
    assert(value != null);
    _declaringLibraryUri = value;
  }

  /// Information about the element reference being suggested.
  Element get element => _element;

  /// Information about the element reference being suggested.
  set element(Element value) {
    assert(value != null);
    _element = value;
  }

  /// A default String for use in generating argument list source contents on
  /// the client side.
  String get defaultArgumentListString => _defaultArgumentListString;

  /// A default String for use in generating argument list source contents on
  /// the client side.
  set defaultArgumentListString(String value) {
    _defaultArgumentListString = value;
  }

  /// Pairs of offsets and lengths describing 'defaultArgumentListString' text
  /// ranges suitable for use by clients to set up linked edits of default
  /// argument source contents. For example, given an argument list string 'x,
  /// y', the corresponding text range [0, 1, 3, 1], indicates two text ranges
  /// of length 1, starting at offsets 0 and 3. Clients can use these ranges to
  /// treat the 'x' and 'y' values specially for linked edits.
  List<int> get defaultArgumentListTextRanges => _defaultArgumentListTextRanges;

  /// Pairs of offsets and lengths describing 'defaultArgumentListString' text
  /// ranges suitable for use by clients to set up linked edits of default
  /// argument source contents. For example, given an argument list string 'x,
  /// y', the corresponding text range [0, 1, 3, 1], indicates two text ranges
  /// of length 1, starting at offsets 0 and 3. Clients can use these ranges to
  /// treat the 'x' and 'y' values specially for linked edits.
  set defaultArgumentListTextRanges(List<int> value) {
    _defaultArgumentListTextRanges = value;
  }

  /// If the element is an executable, the names of the formal parameters of
  /// all kinds - required, optional positional, and optional named. The names
  /// of positional parameters are empty strings. Omitted if the element is not
  /// an executable.
  List<String> get parameterNames => _parameterNames;

  /// If the element is an executable, the names of the formal parameters of
  /// all kinds - required, optional positional, and optional named. The names
  /// of positional parameters are empty strings. Omitted if the element is not
  /// an executable.
  set parameterNames(List<String> value) {
    _parameterNames = value;
  }

  /// If the element is an executable, the declared types of the formal
  /// parameters of all kinds - required, optional positional, and optional
  /// named. Omitted if the element is not an executable.
  List<String> get parameterTypes => _parameterTypes;

  /// If the element is an executable, the declared types of the formal
  /// parameters of all kinds - required, optional positional, and optional
  /// named. Omitted if the element is not an executable.
  set parameterTypes(List<String> value) {
    _parameterTypes = value;
  }

  /// This field is set if the relevance of this suggestion might be changed
  /// depending on where completion is requested.
  List<String> get relevanceTags => _relevanceTags;

  /// This field is set if the relevance of this suggestion might be changed
  /// depending on where completion is requested.
  set relevanceTags(List<String> value) {
    _relevanceTags = value;
  }

  int get requiredParameterCount => _requiredParameterCount;

  set requiredParameterCount(int value) {
    _requiredParameterCount = value;
  }

  AvailableSuggestion(String label, String declaringLibraryUri, Element element,
      {String defaultArgumentListString,
      List<int> defaultArgumentListTextRanges,
      List<String> parameterNames,
      List<String> parameterTypes,
      List<String> relevanceTags,
      int requiredParameterCount}) {
    this.label = label;
    this.declaringLibraryUri = declaringLibraryUri;
    this.element = element;
    this.defaultArgumentListString = defaultArgumentListString;
    this.defaultArgumentListTextRanges = defaultArgumentListTextRanges;
    this.parameterNames = parameterNames;
    this.parameterTypes = parameterTypes;
    this.relevanceTags = relevanceTags;
    this.requiredParameterCount = requiredParameterCount;
  }

  factory AvailableSuggestion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString(jsonPath + '.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      String declaringLibraryUri;
      if (json.containsKey('declaringLibraryUri')) {
        declaringLibraryUri = jsonDecoder.decodeString(
            jsonPath + '.declaringLibraryUri', json['declaringLibraryUri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'declaringLibraryUri');
      }
      Element element;
      if (json.containsKey('element')) {
        element = Element.fromJson(
            jsonDecoder, jsonPath + '.element', json['element']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'element');
      }
      String defaultArgumentListString;
      if (json.containsKey('defaultArgumentListString')) {
        defaultArgumentListString = jsonDecoder.decodeString(
            jsonPath + '.defaultArgumentListString',
            json['defaultArgumentListString']);
      }
      List<int> defaultArgumentListTextRanges;
      if (json.containsKey('defaultArgumentListTextRanges')) {
        defaultArgumentListTextRanges = jsonDecoder.decodeList(
            jsonPath + '.defaultArgumentListTextRanges',
            json['defaultArgumentListTextRanges'],
            jsonDecoder.decodeInt);
      }
      List<String> parameterNames;
      if (json.containsKey('parameterNames')) {
        parameterNames = jsonDecoder.decodeList(jsonPath + '.parameterNames',
            json['parameterNames'], jsonDecoder.decodeString);
      }
      List<String> parameterTypes;
      if (json.containsKey('parameterTypes')) {
        parameterTypes = jsonDecoder.decodeList(jsonPath + '.parameterTypes',
            json['parameterTypes'], jsonDecoder.decodeString);
      }
      List<String> relevanceTags;
      if (json.containsKey('relevanceTags')) {
        relevanceTags = jsonDecoder.decodeList(jsonPath + '.relevanceTags',
            json['relevanceTags'], jsonDecoder.decodeString);
      }
      int requiredParameterCount;
      if (json.containsKey('requiredParameterCount')) {
        requiredParameterCount = jsonDecoder.decodeInt(
            jsonPath + '.requiredParameterCount',
            json['requiredParameterCount']);
      }
      return AvailableSuggestion(label, declaringLibraryUri, element,
          defaultArgumentListString: defaultArgumentListString,
          defaultArgumentListTextRanges: defaultArgumentListTextRanges,
          parameterNames: parameterNames,
          parameterTypes: parameterTypes,
          relevanceTags: relevanceTags,
          requiredParameterCount: requiredParameterCount);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AvailableSuggestion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['label'] = label;
    result['declaringLibraryUri'] = declaringLibraryUri;
    result['element'] = element.toJson();
    if (defaultArgumentListString != null) {
      result['defaultArgumentListString'] = defaultArgumentListString;
    }
    if (defaultArgumentListTextRanges != null) {
      result['defaultArgumentListTextRanges'] = defaultArgumentListTextRanges;
    }
    if (parameterNames != null) {
      result['parameterNames'] = parameterNames;
    }
    if (parameterTypes != null) {
      result['parameterTypes'] = parameterTypes;
    }
    if (relevanceTags != null) {
      result['relevanceTags'] = relevanceTags;
    }
    if (requiredParameterCount != null) {
      result['requiredParameterCount'] = requiredParameterCount;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AvailableSuggestion) {
      return label == other.label &&
          declaringLibraryUri == other.declaringLibraryUri &&
          element == other.element &&
          defaultArgumentListString == other.defaultArgumentListString &&
          listEqual(defaultArgumentListTextRanges,
              other.defaultArgumentListTextRanges, (int a, int b) => a == b) &&
          listEqual(parameterNames, other.parameterNames,
              (String a, String b) => a == b) &&
          listEqual(parameterTypes, other.parameterTypes,
              (String a, String b) => a == b) &&
          listEqual(relevanceTags, other.relevanceTags,
              (String a, String b) => a == b) &&
          requiredParameterCount == other.requiredParameterCount;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, declaringLibraryUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultArgumentListString.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultArgumentListTextRanges.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterNames.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterTypes.hashCode);
    hash = JenkinsSmiHash.combine(hash, relevanceTags.hashCode);
    hash = JenkinsSmiHash.combine(hash, requiredParameterCount.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// AvailableSuggestionSet
///
/// {
///   "id": int
///   "uri": String
///   "items": List<AvailableSuggestion>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class AvailableSuggestionSet implements HasToJson {
  int _id;

  String _uri;

  List<AvailableSuggestion> _items;

  /// The id associated with the library.
  int get id => _id;

  /// The id associated with the library.
  set id(int value) {
    assert(value != null);
    _id = value;
  }

  /// The URI of the library.
  String get uri => _uri;

  /// The URI of the library.
  set uri(String value) {
    assert(value != null);
    _uri = value;
  }

  List<AvailableSuggestion> get items => _items;

  set items(List<AvailableSuggestion> value) {
    assert(value != null);
    _items = value;
  }

  AvailableSuggestionSet(int id, String uri, List<AvailableSuggestion> items) {
    this.id = id;
    this.uri = uri;
    this.items = items;
  }

  factory AvailableSuggestionSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      String uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeString(jsonPath + '.uri', json['uri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'uri');
      }
      List<AvailableSuggestion> items;
      if (json.containsKey('items')) {
        items = jsonDecoder.decodeList(
            jsonPath + '.items',
            json['items'],
            (String jsonPath, Object json) =>
                AvailableSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'items');
      }
      return AvailableSuggestionSet(id, uri, items);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'AvailableSuggestionSet', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    result['uri'] = uri;
    result['items'] =
        items.map((AvailableSuggestion value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AvailableSuggestionSet) {
      return id == other.id &&
          uri == other.uri &&
          listEqual(items, other.items,
              (AvailableSuggestion a, AvailableSuggestion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, items.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// BulkFix
///
/// {
///   "path": FilePath
///   "fixes": List<BulkFixDetail>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class BulkFix implements HasToJson {
  String _path;

  List<BulkFixDetail> _fixes;

  /// The path of the library.
  String get path => _path;

  /// The path of the library.
  set path(String value) {
    assert(value != null);
    _path = value;
  }

  /// A list of bulk fix details.
  List<BulkFixDetail> get fixes => _fixes;

  /// A list of bulk fix details.
  set fixes(List<BulkFixDetail> value) {
    assert(value != null);
    _fixes = value;
  }

  BulkFix(String path, List<BulkFixDetail> fixes) {
    this.path = path;
    this.fixes = fixes;
  }

  factory BulkFix.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeString(jsonPath + '.path', json['path']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      List<BulkFixDetail> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            jsonPath + '.fixes',
            json['fixes'],
            (String jsonPath, Object json) =>
                BulkFixDetail.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return BulkFix(path, fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'BulkFix', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['path'] = path;
    result['fixes'] =
        fixes.map((BulkFixDetail value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is BulkFix) {
      return path == other.path &&
          listEqual(
              fixes, other.fixes, (BulkFixDetail a, BulkFixDetail b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    hash = JenkinsSmiHash.combine(hash, fixes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// BulkFixDetail
///
/// {
///   "code": String
///   "occurrences": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class BulkFixDetail implements HasToJson {
  String _code;

  int _occurrences;

  /// The code of the diagnostic associated with the fix.
  String get code => _code;

  /// The code of the diagnostic associated with the fix.
  set code(String value) {
    assert(value != null);
    _code = value;
  }

  /// The number times the associated diagnostic was fixed in the associated
  /// source edit.
  int get occurrences => _occurrences;

  /// The number times the associated diagnostic was fixed in the associated
  /// source edit.
  set occurrences(int value) {
    assert(value != null);
    _occurrences = value;
  }

  BulkFixDetail(String code, int occurrences) {
    this.code = code;
    this.occurrences = occurrences;
  }

  factory BulkFixDetail.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String code;
      if (json.containsKey('code')) {
        code = jsonDecoder.decodeString(jsonPath + '.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      int occurrences;
      if (json.containsKey('occurrences')) {
        occurrences = jsonDecoder.decodeInt(
            jsonPath + '.occurrences', json['occurrences']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return BulkFixDetail(code, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'BulkFixDetail', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['code'] = code;
    result['occurrences'] = occurrences;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is BulkFixDetail) {
      return code == other.code && occurrences == other.occurrences;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ClosingLabel
///
/// {
///   "offset": int
///   "length": int
///   "label": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ClosingLabel implements HasToJson {
  int _offset;

  int _length;

  String _label;

  /// The offset of the construct being labelled.
  int get offset => _offset;

  /// The offset of the construct being labelled.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the whole construct to be labelled.
  int get length => _length;

  /// The length of the whole construct to be labelled.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The label associated with this range that should be displayed to the
  /// user.
  String get label => _label;

  /// The label associated with this range that should be displayed to the
  /// user.
  set label(String value) {
    assert(value != null);
    _label = value;
  }

  ClosingLabel(int offset, int length, String label) {
    this.offset = offset;
    this.length = length;
    this.label = label;
  }

  factory ClosingLabel.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString(jsonPath + '.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      return ClosingLabel(offset, length, label);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ClosingLabel', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    result['label'] = label;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ClosingLabel) {
      return offset == other.offset &&
          length == other.length &&
          label == other.label;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.availableSuggestions params
///
/// {
///   "changedLibraries": optional List<AvailableSuggestionSet>
///   "removedLibraries": optional List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionAvailableSuggestionsParams implements HasToJson {
  List<AvailableSuggestionSet> _changedLibraries;

  List<int> _removedLibraries;

  /// A list of pre-computed, potential completions coming from this set of
  /// completion suggestions.
  List<AvailableSuggestionSet> get changedLibraries => _changedLibraries;

  /// A list of pre-computed, potential completions coming from this set of
  /// completion suggestions.
  set changedLibraries(List<AvailableSuggestionSet> value) {
    _changedLibraries = value;
  }

  /// A list of library ids that no longer apply.
  List<int> get removedLibraries => _removedLibraries;

  /// A list of library ids that no longer apply.
  set removedLibraries(List<int> value) {
    _removedLibraries = value;
  }

  CompletionAvailableSuggestionsParams(
      {List<AvailableSuggestionSet> changedLibraries,
      List<int> removedLibraries}) {
    this.changedLibraries = changedLibraries;
    this.removedLibraries = removedLibraries;
  }

  factory CompletionAvailableSuggestionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<AvailableSuggestionSet> changedLibraries;
      if (json.containsKey('changedLibraries')) {
        changedLibraries = jsonDecoder.decodeList(
            jsonPath + '.changedLibraries',
            json['changedLibraries'],
            (String jsonPath, Object json) =>
                AvailableSuggestionSet.fromJson(jsonDecoder, jsonPath, json));
      }
      List<int> removedLibraries;
      if (json.containsKey('removedLibraries')) {
        removedLibraries = jsonDecoder.decodeList(
            jsonPath + '.removedLibraries',
            json['removedLibraries'],
            jsonDecoder.decodeInt);
      }
      return CompletionAvailableSuggestionsParams(
          changedLibraries: changedLibraries,
          removedLibraries: removedLibraries);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.availableSuggestions params', json);
    }
  }

  factory CompletionAvailableSuggestionsParams.fromNotification(
      Notification notification) {
    return CompletionAvailableSuggestionsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (changedLibraries != null) {
      result['changedLibraries'] = changedLibraries
          .map((AvailableSuggestionSet value) => value.toJson())
          .toList();
    }
    if (removedLibraries != null) {
      result['removedLibraries'] = removedLibraries;
    }
    return result;
  }

  Notification toNotification() {
    return Notification('completion.availableSuggestions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionAvailableSuggestionsParams) {
      return listEqual(changedLibraries, other.changedLibraries,
              (AvailableSuggestionSet a, AvailableSuggestionSet b) => a == b) &&
          listEqual(removedLibraries, other.removedLibraries,
              (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, changedLibraries.hashCode);
    hash = JenkinsSmiHash.combine(hash, removedLibraries.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.existingImports params
///
/// {
///   "file": FilePath
///   "imports": ExistingImports
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionExistingImportsParams implements HasToJson {
  String _file;

  ExistingImports _imports;

  /// The defining file of the library.
  String get file => _file;

  /// The defining file of the library.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The existing imports in the library.
  ExistingImports get imports => _imports;

  /// The existing imports in the library.
  set imports(ExistingImports value) {
    assert(value != null);
    _imports = value;
  }

  CompletionExistingImportsParams(String file, ExistingImports imports) {
    this.file = file;
    this.imports = imports;
  }

  factory CompletionExistingImportsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      ExistingImports imports;
      if (json.containsKey('imports')) {
        imports = ExistingImports.fromJson(
            jsonDecoder, jsonPath + '.imports', json['imports']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'imports');
      }
      return CompletionExistingImportsParams(file, imports);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.existingImports params', json);
    }
  }

  factory CompletionExistingImportsParams.fromNotification(
      Notification notification) {
    return CompletionExistingImportsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['imports'] = imports.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('completion.existingImports', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionExistingImportsParams) {
      return file == other.file && imports == other.imports;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, imports.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.getSuggestionDetails params
///
/// {
///   "file": FilePath
///   "id": int
///   "label": String
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionDetailsParams implements RequestParams {
  String _file;

  int _id;

  String _label;

  int _offset;

  /// The path of the file into which this completion is being inserted.
  String get file => _file;

  /// The path of the file into which this completion is being inserted.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The identifier of the AvailableSuggestionSet containing the selected
  /// label.
  int get id => _id;

  /// The identifier of the AvailableSuggestionSet containing the selected
  /// label.
  set id(int value) {
    assert(value != null);
    _id = value;
  }

  /// The label from the AvailableSuggestionSet with the `id` for which
  /// insertion information is requested.
  String get label => _label;

  /// The label from the AvailableSuggestionSet with the `id` for which
  /// insertion information is requested.
  set label(String value) {
    assert(value != null);
    _label = value;
  }

  /// The offset in the file where the completion will be inserted.
  int get offset => _offset;

  /// The offset in the file where the completion will be inserted.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  CompletionGetSuggestionDetailsParams(
      String file, int id, String label, int offset) {
    this.file = file;
    this.id = id;
    this.label = label;
    this.offset = offset;
  }

  factory CompletionGetSuggestionDetailsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString(jsonPath + '.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return CompletionGetSuggestionDetailsParams(file, id, label, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestionDetails params', json);
    }
  }

  factory CompletionGetSuggestionDetailsParams.fromRequest(Request request) {
    return CompletionGetSuggestionDetailsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['id'] = id;
    result['label'] = label;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.getSuggestionDetails', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionDetailsParams) {
      return file == other.file &&
          id == other.id &&
          label == other.label &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.getSuggestionDetails result
///
/// {
///   "completion": String
///   "change": optional SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionDetailsResult implements ResponseResult {
  String _completion;

  SourceChange _change;

  /// The full text to insert, including any optional import prefix.
  String get completion => _completion;

  /// The full text to insert, including any optional import prefix.
  set completion(String value) {
    assert(value != null);
    _completion = value;
  }

  /// A change for the client to apply in case the library containing the
  /// accepted completion suggestion needs to be imported. The field will be
  /// omitted if there are no additional changes that need to be made.
  SourceChange get change => _change;

  /// A change for the client to apply in case the library containing the
  /// accepted completion suggestion needs to be imported. The field will be
  /// omitted if there are no additional changes that need to be made.
  set change(SourceChange value) {
    _change = value;
  }

  CompletionGetSuggestionDetailsResult(String completion,
      {SourceChange change}) {
    this.completion = completion;
    this.change = change;
  }

  factory CompletionGetSuggestionDetailsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String completion;
      if (json.containsKey('completion')) {
        completion = jsonDecoder.decodeString(
            jsonPath + '.completion', json['completion']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'completion');
      }
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, jsonPath + '.change', json['change']);
      }
      return CompletionGetSuggestionDetailsResult(completion, change: change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestionDetails result', json);
    }
  }

  factory CompletionGetSuggestionDetailsResult.fromResponse(Response response) {
    return CompletionGetSuggestionDetailsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['completion'] = completion;
    if (change != null) {
      result['change'] = change.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionDetailsResult) {
      return completion == other.completion && change == other.change;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, completion.hashCode);
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.getSuggestions params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsParams implements RequestParams {
  String _file;

  int _offset;

  /// The file containing the point at which suggestions are to be made.
  String get file => _file;

  /// The file containing the point at which suggestions are to be made.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset within the file at which suggestions are to be made.
  int get offset => _offset;

  /// The offset within the file at which suggestions are to be made.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  CompletionGetSuggestionsParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory CompletionGetSuggestionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return CompletionGetSuggestionsParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestions params', json);
    }
  }

  factory CompletionGetSuggestionsParams.fromRequest(Request request) {
    return CompletionGetSuggestionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.getSuggestions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.getSuggestions result
///
/// {
///   "id": CompletionId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionGetSuggestionsResult implements ResponseResult {
  String _id;

  /// The identifier used to associate results with this completion request.
  String get id => _id;

  /// The identifier used to associate results with this completion request.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  CompletionGetSuggestionsResult(String id) {
    this.id = id;
  }

  factory CompletionGetSuggestionsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return CompletionGetSuggestionsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.getSuggestions result', json);
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(Response response) {
    return CompletionGetSuggestionsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.listTokenDetails params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionListTokenDetailsParams implements RequestParams {
  String _file;

  /// The path to the file from which tokens should be returned.
  String get file => _file;

  /// The path to the file from which tokens should be returned.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  CompletionListTokenDetailsParams(String file) {
    this.file = file;
  }

  factory CompletionListTokenDetailsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return CompletionListTokenDetailsParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.listTokenDetails params', json);
    }
  }

  factory CompletionListTokenDetailsParams.fromRequest(Request request) {
    return CompletionListTokenDetailsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.listTokenDetails', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionListTokenDetailsParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.listTokenDetails result
///
/// {
///   "tokens": List<TokenDetails>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionListTokenDetailsResult implements ResponseResult {
  List<TokenDetails> _tokens;

  /// A list of the file's scanned tokens including analysis information about
  /// them.
  List<TokenDetails> get tokens => _tokens;

  /// A list of the file's scanned tokens including analysis information about
  /// them.
  set tokens(List<TokenDetails> value) {
    assert(value != null);
    _tokens = value;
  }

  CompletionListTokenDetailsResult(List<TokenDetails> tokens) {
    this.tokens = tokens;
  }

  factory CompletionListTokenDetailsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<TokenDetails> tokens;
      if (json.containsKey('tokens')) {
        tokens = jsonDecoder.decodeList(
            jsonPath + '.tokens',
            json['tokens'],
            (String jsonPath, Object json) =>
                TokenDetails.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'tokens');
      }
      return CompletionListTokenDetailsResult(tokens);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.listTokenDetails result', json);
    }
  }

  factory CompletionListTokenDetailsResult.fromResponse(Response response) {
    return CompletionListTokenDetailsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['tokens'] =
        tokens.map((TokenDetails value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionListTokenDetailsResult) {
      return listEqual(
          tokens, other.tokens, (TokenDetails a, TokenDetails b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, tokens.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.registerLibraryPaths params
///
/// {
///   "paths": List<LibraryPathSet>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionRegisterLibraryPathsParams implements RequestParams {
  List<LibraryPathSet> _paths;

  /// A list of objects each containing a path and the additional libraries
  /// from which the client is interested in receiving completion suggestions.
  /// If one configured path is beneath another, the descendent will override
  /// the ancestors' configured libraries of interest.
  List<LibraryPathSet> get paths => _paths;

  /// A list of objects each containing a path and the additional libraries
  /// from which the client is interested in receiving completion suggestions.
  /// If one configured path is beneath another, the descendent will override
  /// the ancestors' configured libraries of interest.
  set paths(List<LibraryPathSet> value) {
    assert(value != null);
    _paths = value;
  }

  CompletionRegisterLibraryPathsParams(List<LibraryPathSet> paths) {
    this.paths = paths;
  }

  factory CompletionRegisterLibraryPathsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<LibraryPathSet> paths;
      if (json.containsKey('paths')) {
        paths = jsonDecoder.decodeList(
            jsonPath + '.paths',
            json['paths'],
            (String jsonPath, Object json) =>
                LibraryPathSet.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'paths');
      }
      return CompletionRegisterLibraryPathsParams(paths);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.registerLibraryPaths params', json);
    }
  }

  factory CompletionRegisterLibraryPathsParams.fromRequest(Request request) {
    return CompletionRegisterLibraryPathsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['paths'] =
        paths.map((LibraryPathSet value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.registerLibraryPaths', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionRegisterLibraryPathsParams) {
      return listEqual(
          paths, other.paths, (LibraryPathSet a, LibraryPathSet b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, paths.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.registerLibraryPaths result
///
/// Clients may not extend, implement or mix-in this class.
class CompletionRegisterLibraryPathsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is CompletionRegisterLibraryPathsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 104675661;
  }
}

/// completion.results params
///
/// {
///   "id": CompletionId
///   "replacementOffset": int
///   "replacementLength": int
///   "results": List<CompletionSuggestion>
///   "isLast": bool
///   "libraryFile": optional FilePath
///   "includedSuggestionSets": optional List<IncludedSuggestionSet>
///   "includedElementKinds": optional List<ElementKind>
///   "includedSuggestionRelevanceTags": optional List<IncludedSuggestionRelevanceTag>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionResultsParams implements HasToJson {
  String _id;

  int _replacementOffset;

  int _replacementLength;

  List<CompletionSuggestion> _results;

  bool _isLast;

  String _libraryFile;

  List<IncludedSuggestionSet> _includedSuggestionSets;

  List<ElementKind> _includedElementKinds;

  List<IncludedSuggestionRelevanceTag> _includedSuggestionRelevanceTags;

  /// The id associated with the completion.
  String get id => _id;

  /// The id associated with the completion.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  /// The offset of the start of the text to be replaced. This will be
  /// different than the offset used to request the completion suggestions if
  /// there was a portion of an identifier before the original offset. In
  /// particular, the replacementOffset will be the offset of the beginning of
  /// said identifier.
  int get replacementOffset => _replacementOffset;

  /// The offset of the start of the text to be replaced. This will be
  /// different than the offset used to request the completion suggestions if
  /// there was a portion of an identifier before the original offset. In
  /// particular, the replacementOffset will be the offset of the beginning of
  /// said identifier.
  set replacementOffset(int value) {
    assert(value != null);
    _replacementOffset = value;
  }

  /// The length of the text to be replaced if the remainder of the identifier
  /// containing the cursor is to be replaced when the suggestion is applied
  /// (that is, the number of characters in the existing identifier).
  int get replacementLength => _replacementLength;

  /// The length of the text to be replaced if the remainder of the identifier
  /// containing the cursor is to be replaced when the suggestion is applied
  /// (that is, the number of characters in the existing identifier).
  set replacementLength(int value) {
    assert(value != null);
    _replacementLength = value;
  }

  /// The completion suggestions being reported. The notification contains all
  /// possible completions at the requested cursor position, even those that do
  /// not match the characters the user has already typed. This allows the
  /// client to respond to further keystrokes from the user without having to
  /// make additional requests.
  List<CompletionSuggestion> get results => _results;

  /// The completion suggestions being reported. The notification contains all
  /// possible completions at the requested cursor position, even those that do
  /// not match the characters the user has already typed. This allows the
  /// client to respond to further keystrokes from the user without having to
  /// make additional requests.
  set results(List<CompletionSuggestion> value) {
    assert(value != null);
    _results = value;
  }

  /// True if this is that last set of results that will be returned for the
  /// indicated completion.
  bool get isLast => _isLast;

  /// True if this is that last set of results that will be returned for the
  /// indicated completion.
  set isLast(bool value) {
    assert(value != null);
    _isLast = value;
  }

  /// The library file that contains the file where completion was requested.
  /// The client might use it for example together with the existingImports
  /// notification to filter out available suggestions. If there were changes
  /// to existing imports in the library, the corresponding existingImports
  /// notification will be sent before the completion notification.
  String get libraryFile => _libraryFile;

  /// The library file that contains the file where completion was requested.
  /// The client might use it for example together with the existingImports
  /// notification to filter out available suggestions. If there were changes
  /// to existing imports in the library, the corresponding existingImports
  /// notification will be sent before the completion notification.
  set libraryFile(String value) {
    _libraryFile = value;
  }

  /// References to AvailableSuggestionSet objects previously sent to the
  /// client. The client can include applicable names from the referenced
  /// library in code completion suggestions.
  List<IncludedSuggestionSet> get includedSuggestionSets =>
      _includedSuggestionSets;

  /// References to AvailableSuggestionSet objects previously sent to the
  /// client. The client can include applicable names from the referenced
  /// library in code completion suggestions.
  set includedSuggestionSets(List<IncludedSuggestionSet> value) {
    _includedSuggestionSets = value;
  }

  /// The client is expected to check this list against the ElementKind sent in
  /// IncludedSuggestionSet to decide whether or not these symbols should
  /// should be presented to the user.
  List<ElementKind> get includedElementKinds => _includedElementKinds;

  /// The client is expected to check this list against the ElementKind sent in
  /// IncludedSuggestionSet to decide whether or not these symbols should
  /// should be presented to the user.
  set includedElementKinds(List<ElementKind> value) {
    _includedElementKinds = value;
  }

  /// The client is expected to check this list against the values of the field
  /// relevanceTags of AvailableSuggestion to decide if the suggestion should
  /// be given a different relevance than the IncludedSuggestionSet that
  /// contains it. This might be used for example to give higher relevance to
  /// suggestions of matching types.
  ///
  /// If an AvailableSuggestion has relevance tags that match more than one
  /// IncludedSuggestionRelevanceTag, the maximum relevance boost is used.
  List<IncludedSuggestionRelevanceTag> get includedSuggestionRelevanceTags =>
      _includedSuggestionRelevanceTags;

  /// The client is expected to check this list against the values of the field
  /// relevanceTags of AvailableSuggestion to decide if the suggestion should
  /// be given a different relevance than the IncludedSuggestionSet that
  /// contains it. This might be used for example to give higher relevance to
  /// suggestions of matching types.
  ///
  /// If an AvailableSuggestion has relevance tags that match more than one
  /// IncludedSuggestionRelevanceTag, the maximum relevance boost is used.
  set includedSuggestionRelevanceTags(
      List<IncludedSuggestionRelevanceTag> value) {
    _includedSuggestionRelevanceTags = value;
  }

  CompletionResultsParams(String id, int replacementOffset,
      int replacementLength, List<CompletionSuggestion> results, bool isLast,
      {String libraryFile,
      List<IncludedSuggestionSet> includedSuggestionSets,
      List<ElementKind> includedElementKinds,
      List<IncludedSuggestionRelevanceTag> includedSuggestionRelevanceTags}) {
    this.id = id;
    this.replacementOffset = replacementOffset;
    this.replacementLength = replacementLength;
    this.results = results;
    this.isLast = isLast;
    this.libraryFile = libraryFile;
    this.includedSuggestionSets = includedSuggestionSets;
    this.includedElementKinds = includedElementKinds;
    this.includedSuggestionRelevanceTags = includedSuggestionRelevanceTags;
  }

  factory CompletionResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      int replacementOffset;
      if (json.containsKey('replacementOffset')) {
        replacementOffset = jsonDecoder.decodeInt(
            jsonPath + '.replacementOffset', json['replacementOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementOffset');
      }
      int replacementLength;
      if (json.containsKey('replacementLength')) {
        replacementLength = jsonDecoder.decodeInt(
            jsonPath + '.replacementLength', json['replacementLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'replacementLength');
      }
      List<CompletionSuggestion> results;
      if (json.containsKey('results')) {
        results = jsonDecoder.decodeList(
            jsonPath + '.results',
            json['results'],
            (String jsonPath, Object json) =>
                CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'results');
      }
      bool isLast;
      if (json.containsKey('isLast')) {
        isLast = jsonDecoder.decodeBool(jsonPath + '.isLast', json['isLast']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isLast');
      }
      String libraryFile;
      if (json.containsKey('libraryFile')) {
        libraryFile = jsonDecoder.decodeString(
            jsonPath + '.libraryFile', json['libraryFile']);
      }
      List<IncludedSuggestionSet> includedSuggestionSets;
      if (json.containsKey('includedSuggestionSets')) {
        includedSuggestionSets = jsonDecoder.decodeList(
            jsonPath + '.includedSuggestionSets',
            json['includedSuggestionSets'],
            (String jsonPath, Object json) =>
                IncludedSuggestionSet.fromJson(jsonDecoder, jsonPath, json));
      }
      List<ElementKind> includedElementKinds;
      if (json.containsKey('includedElementKinds')) {
        includedElementKinds = jsonDecoder.decodeList(
            jsonPath + '.includedElementKinds',
            json['includedElementKinds'],
            (String jsonPath, Object json) =>
                ElementKind.fromJson(jsonDecoder, jsonPath, json));
      }
      List<IncludedSuggestionRelevanceTag> includedSuggestionRelevanceTags;
      if (json.containsKey('includedSuggestionRelevanceTags')) {
        includedSuggestionRelevanceTags = jsonDecoder.decodeList(
            jsonPath + '.includedSuggestionRelevanceTags',
            json['includedSuggestionRelevanceTags'],
            (String jsonPath, Object json) =>
                IncludedSuggestionRelevanceTag.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return CompletionResultsParams(
          id, replacementOffset, replacementLength, results, isLast,
          libraryFile: libraryFile,
          includedSuggestionSets: includedSuggestionSets,
          includedElementKinds: includedElementKinds,
          includedSuggestionRelevanceTags: includedSuggestionRelevanceTags);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'completion.results params', json);
    }
  }

  factory CompletionResultsParams.fromNotification(Notification notification) {
    return CompletionResultsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    result['replacementOffset'] = replacementOffset;
    result['replacementLength'] = replacementLength;
    result['results'] =
        results.map((CompletionSuggestion value) => value.toJson()).toList();
    result['isLast'] = isLast;
    if (libraryFile != null) {
      result['libraryFile'] = libraryFile;
    }
    if (includedSuggestionSets != null) {
      result['includedSuggestionSets'] = includedSuggestionSets
          .map((IncludedSuggestionSet value) => value.toJson())
          .toList();
    }
    if (includedElementKinds != null) {
      result['includedElementKinds'] = includedElementKinds
          .map((ElementKind value) => value.toJson())
          .toList();
    }
    if (includedSuggestionRelevanceTags != null) {
      result['includedSuggestionRelevanceTags'] =
          includedSuggestionRelevanceTags
              .map((IncludedSuggestionRelevanceTag value) => value.toJson())
              .toList();
    }
    return result;
  }

  Notification toNotification() {
    return Notification('completion.results', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionResultsParams) {
      return id == other.id &&
          replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          listEqual(results, other.results,
              (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          isLast == other.isLast &&
          libraryFile == other.libraryFile &&
          listEqual(includedSuggestionSets, other.includedSuggestionSets,
              (IncludedSuggestionSet a, IncludedSuggestionSet b) => a == b) &&
          listEqual(includedElementKinds, other.includedElementKinds,
              (ElementKind a, ElementKind b) => a == b) &&
          listEqual(
              includedSuggestionRelevanceTags,
              other.includedSuggestionRelevanceTags,
              (IncludedSuggestionRelevanceTag a,
                      IncludedSuggestionRelevanceTag b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacementOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacementLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, results.hashCode);
    hash = JenkinsSmiHash.combine(hash, isLast.hashCode);
    hash = JenkinsSmiHash.combine(hash, libraryFile.hashCode);
    hash = JenkinsSmiHash.combine(hash, includedSuggestionSets.hashCode);
    hash = JenkinsSmiHash.combine(hash, includedElementKinds.hashCode);
    hash =
        JenkinsSmiHash.combine(hash, includedSuggestionRelevanceTags.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// CompletionService
///
/// enum {
///   AVAILABLE_SUGGESTION_SETS
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionService implements Enum {
  /// The client will receive availableSuggestions notifications once
  /// subscribed with completion suggestion sets from the libraries of
  /// interest. The client should keep an up-to-date record of these in memory
  /// so that it will be able to union these candidates with other completion
  /// suggestions when applicable at completion time.
  ///
  /// The client will also receive existingImports notifications.
  static const CompletionService AVAILABLE_SUGGESTION_SETS =
      CompletionService._('AVAILABLE_SUGGESTION_SETS');

  /// A list containing all of the enum values that are defined.
  static const List<CompletionService> VALUES = <CompletionService>[
    AVAILABLE_SUGGESTION_SETS
  ];

  @override
  final String name;

  const CompletionService._(this.name);

  factory CompletionService(String name) {
    switch (name) {
      case 'AVAILABLE_SUGGESTION_SETS':
        return AVAILABLE_SUGGESTION_SETS;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory CompletionService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return CompletionService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'CompletionService', json);
  }

  @override
  String toString() => 'CompletionService.$name';

  String toJson() => name;
}

/// completion.setSubscriptions params
///
/// {
///   "subscriptions": List<CompletionService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSetSubscriptionsParams implements RequestParams {
  List<CompletionService> _subscriptions;

  /// A list of the services being subscribed to.
  List<CompletionService> get subscriptions => _subscriptions;

  /// A list of the services being subscribed to.
  set subscriptions(List<CompletionService> value) {
    assert(value != null);
    _subscriptions = value;
  }

  CompletionSetSubscriptionsParams(List<CompletionService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory CompletionSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<CompletionService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + '.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object json) =>
                CompletionService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return CompletionSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'completion.setSubscriptions params', json);
    }
  }

  factory CompletionSetSubscriptionsParams.fromRequest(Request request) {
    return CompletionSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['subscriptions'] =
        subscriptions.map((CompletionService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'completion.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionSetSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (CompletionService a, CompletionService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// completion.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class CompletionSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is CompletionSetSubscriptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 2482770;
  }
}

/// ContextData
///
/// {
///   "name": String
///   "explicitFileCount": int
///   "implicitFileCount": int
///   "workItemQueueLength": int
///   "cacheEntryExceptions": List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ContextData implements HasToJson {
  String _name;

  int _explicitFileCount;

  int _implicitFileCount;

  int _workItemQueueLength;

  List<String> _cacheEntryExceptions;

  /// The name of the context.
  String get name => _name;

  /// The name of the context.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// Explicitly analyzed files.
  int get explicitFileCount => _explicitFileCount;

  /// Explicitly analyzed files.
  set explicitFileCount(int value) {
    assert(value != null);
    _explicitFileCount = value;
  }

  /// Implicitly analyzed files.
  int get implicitFileCount => _implicitFileCount;

  /// Implicitly analyzed files.
  set implicitFileCount(int value) {
    assert(value != null);
    _implicitFileCount = value;
  }

  /// The number of work items in the queue.
  int get workItemQueueLength => _workItemQueueLength;

  /// The number of work items in the queue.
  set workItemQueueLength(int value) {
    assert(value != null);
    _workItemQueueLength = value;
  }

  /// Exceptions associated with cache entries.
  List<String> get cacheEntryExceptions => _cacheEntryExceptions;

  /// Exceptions associated with cache entries.
  set cacheEntryExceptions(List<String> value) {
    assert(value != null);
    _cacheEntryExceptions = value;
  }

  ContextData(String name, int explicitFileCount, int implicitFileCount,
      int workItemQueueLength, List<String> cacheEntryExceptions) {
    this.name = name;
    this.explicitFileCount = explicitFileCount;
    this.implicitFileCount = implicitFileCount;
    this.workItemQueueLength = workItemQueueLength;
    this.cacheEntryExceptions = cacheEntryExceptions;
  }

  factory ContextData.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      int explicitFileCount;
      if (json.containsKey('explicitFileCount')) {
        explicitFileCount = jsonDecoder.decodeInt(
            jsonPath + '.explicitFileCount', json['explicitFileCount']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'explicitFileCount');
      }
      int implicitFileCount;
      if (json.containsKey('implicitFileCount')) {
        implicitFileCount = jsonDecoder.decodeInt(
            jsonPath + '.implicitFileCount', json['implicitFileCount']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'implicitFileCount');
      }
      int workItemQueueLength;
      if (json.containsKey('workItemQueueLength')) {
        workItemQueueLength = jsonDecoder.decodeInt(
            jsonPath + '.workItemQueueLength', json['workItemQueueLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'workItemQueueLength');
      }
      List<String> cacheEntryExceptions;
      if (json.containsKey('cacheEntryExceptions')) {
        cacheEntryExceptions = jsonDecoder.decodeList(
            jsonPath + '.cacheEntryExceptions',
            json['cacheEntryExceptions'],
            jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'cacheEntryExceptions');
      }
      return ContextData(name, explicitFileCount, implicitFileCount,
          workItemQueueLength, cacheEntryExceptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ContextData', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['explicitFileCount'] = explicitFileCount;
    result['implicitFileCount'] = implicitFileCount;
    result['workItemQueueLength'] = workItemQueueLength;
    result['cacheEntryExceptions'] = cacheEntryExceptions;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ContextData) {
      return name == other.name &&
          explicitFileCount == other.explicitFileCount &&
          implicitFileCount == other.implicitFileCount &&
          workItemQueueLength == other.workItemQueueLength &&
          listEqual(cacheEntryExceptions, other.cacheEntryExceptions,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, explicitFileCount.hashCode);
    hash = JenkinsSmiHash.combine(hash, implicitFileCount.hashCode);
    hash = JenkinsSmiHash.combine(hash, workItemQueueLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, cacheEntryExceptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// convertGetterToMethod feedback
///
/// Clients may not extend, implement or mix-in this class.
class ConvertGetterToMethodFeedback extends RefactoringFeedback
    implements HasToJson {
  @override
  bool operator ==(other) {
    if (other is ConvertGetterToMethodFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 616032599;
  }
}

/// convertGetterToMethod options
///
/// Clients may not extend, implement or mix-in this class.
class ConvertGetterToMethodOptions extends RefactoringOptions
    implements HasToJson {
  @override
  bool operator ==(other) {
    if (other is ConvertGetterToMethodOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 488848400;
  }
}

/// convertMethodToGetter feedback
///
/// Clients may not extend, implement or mix-in this class.
class ConvertMethodToGetterFeedback extends RefactoringFeedback
    implements HasToJson {
  @override
  bool operator ==(other) {
    if (other is ConvertMethodToGetterFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 165291526;
  }
}

/// convertMethodToGetter options
///
/// Clients may not extend, implement or mix-in this class.
class ConvertMethodToGetterOptions extends RefactoringOptions
    implements HasToJson {
  @override
  bool operator ==(other) {
    if (other is ConvertMethodToGetterOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 27952290;
  }
}

/// DartFix
///
/// {
///   "name": String
///   "description": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DartFix implements HasToJson {
  String _name;

  String _description;

  /// The name of the fix.
  String get name => _name;

  /// The name of the fix.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// A human readable description of the fix.
  String get description => _description;

  /// A human readable description of the fix.
  set description(String value) {
    _description = value;
  }

  DartFix(String name, {String description}) {
    this.name = name;
    this.description = description;
  }

  factory DartFix.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String description;
      if (json.containsKey('description')) {
        description = jsonDecoder.decodeString(
            jsonPath + '.description', json['description']);
      }
      return DartFix(name, description: description);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'DartFix', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    if (description != null) {
      result['description'] = description;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DartFix) {
      return name == other.name && description == other.description;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, description.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// DartFixSuggestion
///
/// {
///   "description": String
///   "location": optional Location
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DartFixSuggestion implements HasToJson {
  String _description;

  Location _location;

  /// A human readable description of the suggested change.
  String get description => _description;

  /// A human readable description of the suggested change.
  set description(String value) {
    assert(value != null);
    _description = value;
  }

  /// The location of the suggested change.
  Location get location => _location;

  /// The location of the suggested change.
  set location(Location value) {
    _location = value;
  }

  DartFixSuggestion(String description, {Location location}) {
    this.description = description;
    this.location = location;
  }

  factory DartFixSuggestion.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String description;
      if (json.containsKey('description')) {
        description = jsonDecoder.decodeString(
            jsonPath + '.description', json['description']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'description');
      }
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, jsonPath + '.location', json['location']);
      }
      return DartFixSuggestion(description, location: location);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'DartFixSuggestion', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['description'] = description;
    if (location != null) {
      result['location'] = location.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DartFixSuggestion) {
      return description == other.description && location == other.location;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, description.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// diagnostic.getDiagnostics params
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetDiagnosticsParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'diagnostic.getDiagnostics', null);
  }

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetDiagnosticsParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 587526202;
  }
}

/// diagnostic.getDiagnostics result
///
/// {
///   "contexts": List<ContextData>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetDiagnosticsResult implements ResponseResult {
  List<ContextData> _contexts;

  /// The list of analysis contexts.
  List<ContextData> get contexts => _contexts;

  /// The list of analysis contexts.
  set contexts(List<ContextData> value) {
    assert(value != null);
    _contexts = value;
  }

  DiagnosticGetDiagnosticsResult(List<ContextData> contexts) {
    this.contexts = contexts;
  }

  factory DiagnosticGetDiagnosticsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<ContextData> contexts;
      if (json.containsKey('contexts')) {
        contexts = jsonDecoder.decodeList(
            jsonPath + '.contexts',
            json['contexts'],
            (String jsonPath, Object json) =>
                ContextData.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contexts');
      }
      return DiagnosticGetDiagnosticsResult(contexts);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'diagnostic.getDiagnostics result', json);
    }
  }

  factory DiagnosticGetDiagnosticsResult.fromResponse(Response response) {
    return DiagnosticGetDiagnosticsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['contexts'] =
        contexts.map((ContextData value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetDiagnosticsResult) {
      return listEqual(
          contexts, other.contexts, (ContextData a, ContextData b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, contexts.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// diagnostic.getServerPort params
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetServerPortParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'diagnostic.getServerPort', null);
  }

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetServerPortParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 367508704;
  }
}

/// diagnostic.getServerPort result
///
/// {
///   "port": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class DiagnosticGetServerPortResult implements ResponseResult {
  int _port;

  /// The diagnostic server port.
  int get port => _port;

  /// The diagnostic server port.
  set port(int value) {
    assert(value != null);
    _port = value;
  }

  DiagnosticGetServerPortResult(int port) {
    this.port = port;
  }

  factory DiagnosticGetServerPortResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int port;
      if (json.containsKey('port')) {
        port = jsonDecoder.decodeInt(jsonPath + '.port', json['port']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'port');
      }
      return DiagnosticGetServerPortResult(port);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'diagnostic.getServerPort result', json);
    }
  }

  factory DiagnosticGetServerPortResult.fromResponse(Response response) {
    return DiagnosticGetServerPortResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['port'] = port;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetServerPortResult) {
      return port == other.port;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.bulkFixes params
///
/// {
///   "included": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditBulkFixesParams implements RequestParams {
  List<String> _included;

  /// A list of the files and directories for which edits should be suggested.
  ///
  /// If a request is made with a path that is invalid, e.g. is not absolute
  /// and normalized, an error of type INVALID_FILE_PATH_FORMAT will be
  /// generated. If a request is made for a file which does not exist, or which
  /// is not currently subject to analysis (e.g. because it is not associated
  /// with any analysis root specified to analysis.setAnalysisRoots), an error
  /// of type FILE_NOT_ANALYZED will be generated.
  List<String> get included => _included;

  /// A list of the files and directories for which edits should be suggested.
  ///
  /// If a request is made with a path that is invalid, e.g. is not absolute
  /// and normalized, an error of type INVALID_FILE_PATH_FORMAT will be
  /// generated. If a request is made for a file which does not exist, or which
  /// is not currently subject to analysis (e.g. because it is not associated
  /// with any analysis root specified to analysis.setAnalysisRoots), an error
  /// of type FILE_NOT_ANALYZED will be generated.
  set included(List<String> value) {
    assert(value != null);
    _included = value;
  }

  EditBulkFixesParams(List<String> included) {
    this.included = included;
  }

  factory EditBulkFixesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> included;
      if (json.containsKey('included')) {
        included = jsonDecoder.decodeList(
            jsonPath + '.included', json['included'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'included');
      }
      return EditBulkFixesParams(included);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.bulkFixes params', json);
    }
  }

  factory EditBulkFixesParams.fromRequest(Request request) {
    return EditBulkFixesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['included'] = included;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.bulkFixes', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditBulkFixesParams) {
      return listEqual(
          included, other.included, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, included.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.bulkFixes result
///
/// {
///   "edits": List<SourceFileEdit>
///   "details": List<BulkFix>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditBulkFixesResult implements ResponseResult {
  List<SourceFileEdit> _edits;

  List<BulkFix> _details;

  /// A list of source edits to apply the recommended changes.
  List<SourceFileEdit> get edits => _edits;

  /// A list of source edits to apply the recommended changes.
  set edits(List<SourceFileEdit> value) {
    assert(value != null);
    _edits = value;
  }

  /// Details that summarize the fixes associated with the recommended changes.
  List<BulkFix> get details => _details;

  /// Details that summarize the fixes associated with the recommended changes.
  set details(List<BulkFix> value) {
    assert(value != null);
    _details = value;
  }

  EditBulkFixesResult(List<SourceFileEdit> edits, List<BulkFix> details) {
    this.edits = edits;
    this.details = details;
  }

  factory EditBulkFixesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<SourceFileEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            jsonPath + '.edits',
            json['edits'],
            (String jsonPath, Object json) =>
                SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      List<BulkFix> details;
      if (json.containsKey('details')) {
        details = jsonDecoder.decodeList(
            jsonPath + '.details',
            json['details'],
            (String jsonPath, Object json) =>
                BulkFix.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'details');
      }
      return EditBulkFixesResult(edits, details);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.bulkFixes result', json);
    }
  }

  factory EditBulkFixesResult.fromResponse(Response response) {
    return EditBulkFixesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['edits'] =
        edits.map((SourceFileEdit value) => value.toJson()).toList();
    result['details'] = details.map((BulkFix value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditBulkFixesResult) {
      return listEqual(edits, other.edits,
              (SourceFileEdit a, SourceFileEdit b) => a == b) &&
          listEqual(details, other.details, (BulkFix a, BulkFix b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = JenkinsSmiHash.combine(hash, details.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.dartfix params
///
/// {
///   "included": List<FilePath>
///   "includedFixes": optional List<String>
///   "includePedanticFixes": optional bool
///   "excludedFixes": optional List<String>
///   "port": optional int
///   "outputDir": optional FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditDartfixParams implements RequestParams {
  List<String> _included;

  List<String> _includedFixes;

  bool _includePedanticFixes;

  List<String> _excludedFixes;

  int _port;

  String _outputDir;

  /// A list of the files and directories for which edits should be suggested.
  ///
  /// If a request is made with a path that is invalid, e.g. is not absolute
  /// and normalized, an error of type INVALID_FILE_PATH_FORMAT will be
  /// generated. If a request is made for a file which does not exist, or which
  /// is not currently subject to analysis (e.g. because it is not associated
  /// with any analysis root specified to analysis.setAnalysisRoots), an error
  /// of type FILE_NOT_ANALYZED will be generated.
  List<String> get included => _included;

  /// A list of the files and directories for which edits should be suggested.
  ///
  /// If a request is made with a path that is invalid, e.g. is not absolute
  /// and normalized, an error of type INVALID_FILE_PATH_FORMAT will be
  /// generated. If a request is made for a file which does not exist, or which
  /// is not currently subject to analysis (e.g. because it is not associated
  /// with any analysis root specified to analysis.setAnalysisRoots), an error
  /// of type FILE_NOT_ANALYZED will be generated.
  set included(List<String> value) {
    assert(value != null);
    _included = value;
  }

  /// A list of names indicating which fixes should be applied.
  ///
  /// If a name is specified that does not match the name of a known fix, an
  /// error of type UNKNOWN_FIX will be generated.
  List<String> get includedFixes => _includedFixes;

  /// A list of names indicating which fixes should be applied.
  ///
  /// If a name is specified that does not match the name of a known fix, an
  /// error of type UNKNOWN_FIX will be generated.
  set includedFixes(List<String> value) {
    _includedFixes = value;
  }

  /// A flag indicating whether "pedantic" fixes should be applied.
  bool get includePedanticFixes => _includePedanticFixes;

  /// A flag indicating whether "pedantic" fixes should be applied.
  set includePedanticFixes(bool value) {
    _includePedanticFixes = value;
  }

  /// A list of names indicating which fixes should not be applied.
  ///
  /// If a name is specified that does not match the name of a known fix, an
  /// error of type UNKNOWN_FIX will be generated.
  List<String> get excludedFixes => _excludedFixes;

  /// A list of names indicating which fixes should not be applied.
  ///
  /// If a name is specified that does not match the name of a known fix, an
  /// error of type UNKNOWN_FIX will be generated.
  set excludedFixes(List<String> value) {
    _excludedFixes = value;
  }

  /// Deprecated: This field is now ignored by server.
  int get port => _port;

  /// Deprecated: This field is now ignored by server.
  set port(int value) {
    _port = value;
  }

  /// Deprecated: This field is now ignored by server.
  String get outputDir => _outputDir;

  /// Deprecated: This field is now ignored by server.
  set outputDir(String value) {
    _outputDir = value;
  }

  EditDartfixParams(List<String> included,
      {List<String> includedFixes,
      bool includePedanticFixes,
      List<String> excludedFixes,
      int port,
      String outputDir}) {
    this.included = included;
    this.includedFixes = includedFixes;
    this.includePedanticFixes = includePedanticFixes;
    this.excludedFixes = excludedFixes;
    this.port = port;
    this.outputDir = outputDir;
  }

  factory EditDartfixParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> included;
      if (json.containsKey('included')) {
        included = jsonDecoder.decodeList(
            jsonPath + '.included', json['included'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'included');
      }
      List<String> includedFixes;
      if (json.containsKey('includedFixes')) {
        includedFixes = jsonDecoder.decodeList(jsonPath + '.includedFixes',
            json['includedFixes'], jsonDecoder.decodeString);
      }
      bool includePedanticFixes;
      if (json.containsKey('includePedanticFixes')) {
        includePedanticFixes = jsonDecoder.decodeBool(
            jsonPath + '.includePedanticFixes', json['includePedanticFixes']);
      }
      List<String> excludedFixes;
      if (json.containsKey('excludedFixes')) {
        excludedFixes = jsonDecoder.decodeList(jsonPath + '.excludedFixes',
            json['excludedFixes'], jsonDecoder.decodeString);
      }
      int port;
      if (json.containsKey('port')) {
        port = jsonDecoder.decodeInt(jsonPath + '.port', json['port']);
      }
      String outputDir;
      if (json.containsKey('outputDir')) {
        outputDir = jsonDecoder.decodeString(
            jsonPath + '.outputDir', json['outputDir']);
      }
      return EditDartfixParams(included,
          includedFixes: includedFixes,
          includePedanticFixes: includePedanticFixes,
          excludedFixes: excludedFixes,
          port: port,
          outputDir: outputDir);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.dartfix params', json);
    }
  }

  factory EditDartfixParams.fromRequest(Request request) {
    return EditDartfixParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['included'] = included;
    if (includedFixes != null) {
      result['includedFixes'] = includedFixes;
    }
    if (includePedanticFixes != null) {
      result['includePedanticFixes'] = includePedanticFixes;
    }
    if (excludedFixes != null) {
      result['excludedFixes'] = excludedFixes;
    }
    if (port != null) {
      result['port'] = port;
    }
    if (outputDir != null) {
      result['outputDir'] = outputDir;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.dartfix', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditDartfixParams) {
      return listEqual(
              included, other.included, (String a, String b) => a == b) &&
          listEqual(includedFixes, other.includedFixes,
              (String a, String b) => a == b) &&
          includePedanticFixes == other.includePedanticFixes &&
          listEqual(excludedFixes, other.excludedFixes,
              (String a, String b) => a == b) &&
          port == other.port &&
          outputDir == other.outputDir;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, included.hashCode);
    hash = JenkinsSmiHash.combine(hash, includedFixes.hashCode);
    hash = JenkinsSmiHash.combine(hash, includePedanticFixes.hashCode);
    hash = JenkinsSmiHash.combine(hash, excludedFixes.hashCode);
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    hash = JenkinsSmiHash.combine(hash, outputDir.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.dartfix result
///
/// {
///   "suggestions": List<DartFixSuggestion>
///   "otherSuggestions": List<DartFixSuggestion>
///   "hasErrors": bool
///   "edits": List<SourceFileEdit>
///   "details": optional List<String>
///   "port": optional int
///   "urls": optional List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditDartfixResult implements ResponseResult {
  List<DartFixSuggestion> _suggestions;

  List<DartFixSuggestion> _otherSuggestions;

  bool _hasErrors;

  List<SourceFileEdit> _edits;

  List<String> _details;

  int _port;

  List<String> _urls;

  /// A list of recommended changes that can be automatically made by applying
  /// the 'edits' included in this response.
  List<DartFixSuggestion> get suggestions => _suggestions;

  /// A list of recommended changes that can be automatically made by applying
  /// the 'edits' included in this response.
  set suggestions(List<DartFixSuggestion> value) {
    assert(value != null);
    _suggestions = value;
  }

  /// A list of recommended changes that could not be automatically made.
  List<DartFixSuggestion> get otherSuggestions => _otherSuggestions;

  /// A list of recommended changes that could not be automatically made.
  set otherSuggestions(List<DartFixSuggestion> value) {
    assert(value != null);
    _otherSuggestions = value;
  }

  /// True if the analyzed source contains errors that might impact the
  /// correctness of the recommended changes that can be automatically applied.
  bool get hasErrors => _hasErrors;

  /// True if the analyzed source contains errors that might impact the
  /// correctness of the recommended changes that can be automatically applied.
  set hasErrors(bool value) {
    assert(value != null);
    _hasErrors = value;
  }

  /// A list of source edits to apply the recommended changes.
  List<SourceFileEdit> get edits => _edits;

  /// A list of source edits to apply the recommended changes.
  set edits(List<SourceFileEdit> value) {
    assert(value != null);
    _edits = value;
  }

  /// Messages that should be displayed to the user that describe details of
  /// the fix generation. For example, the messages might (a) point out details
  /// that users might want to explore before committing the changes or (b)
  /// describe exceptions that were thrown but that did not stop the fixes from
  /// being produced. The list will be omitted if it is empty.
  List<String> get details => _details;

  /// Messages that should be displayed to the user that describe details of
  /// the fix generation. For example, the messages might (a) point out details
  /// that users might want to explore before committing the changes or (b)
  /// describe exceptions that were thrown but that did not stop the fixes from
  /// being produced. The list will be omitted if it is empty.
  set details(List<String> value) {
    _details = value;
  }

  /// The port on which the preview tool will respond to GET requests. The
  /// field is omitted if a preview was not requested.
  int get port => _port;

  /// The port on which the preview tool will respond to GET requests. The
  /// field is omitted if a preview was not requested.
  set port(int value) {
    _port = value;
  }

  /// The URLs that users can visit in a browser to see a preview of the
  /// proposed changes. There is one URL for each of the included file paths.
  /// The field is omitted if a preview was not requested.
  List<String> get urls => _urls;

  /// The URLs that users can visit in a browser to see a preview of the
  /// proposed changes. There is one URL for each of the included file paths.
  /// The field is omitted if a preview was not requested.
  set urls(List<String> value) {
    _urls = value;
  }

  EditDartfixResult(
      List<DartFixSuggestion> suggestions,
      List<DartFixSuggestion> otherSuggestions,
      bool hasErrors,
      List<SourceFileEdit> edits,
      {List<String> details,
      int port,
      List<String> urls}) {
    this.suggestions = suggestions;
    this.otherSuggestions = otherSuggestions;
    this.hasErrors = hasErrors;
    this.edits = edits;
    this.details = details;
    this.port = port;
    this.urls = urls;
  }

  factory EditDartfixResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<DartFixSuggestion> suggestions;
      if (json.containsKey('suggestions')) {
        suggestions = jsonDecoder.decodeList(
            jsonPath + '.suggestions',
            json['suggestions'],
            (String jsonPath, Object json) =>
                DartFixSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'suggestions');
      }
      List<DartFixSuggestion> otherSuggestions;
      if (json.containsKey('otherSuggestions')) {
        otherSuggestions = jsonDecoder.decodeList(
            jsonPath + '.otherSuggestions',
            json['otherSuggestions'],
            (String jsonPath, Object json) =>
                DartFixSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'otherSuggestions');
      }
      bool hasErrors;
      if (json.containsKey('hasErrors')) {
        hasErrors =
            jsonDecoder.decodeBool(jsonPath + '.hasErrors', json['hasErrors']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'hasErrors');
      }
      List<SourceFileEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            jsonPath + '.edits',
            json['edits'],
            (String jsonPath, Object json) =>
                SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      List<String> details;
      if (json.containsKey('details')) {
        details = jsonDecoder.decodeList(
            jsonPath + '.details', json['details'], jsonDecoder.decodeString);
      }
      int port;
      if (json.containsKey('port')) {
        port = jsonDecoder.decodeInt(jsonPath + '.port', json['port']);
      }
      List<String> urls;
      if (json.containsKey('urls')) {
        urls = jsonDecoder.decodeList(
            jsonPath + '.urls', json['urls'], jsonDecoder.decodeString);
      }
      return EditDartfixResult(suggestions, otherSuggestions, hasErrors, edits,
          details: details, port: port, urls: urls);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.dartfix result', json);
    }
  }

  factory EditDartfixResult.fromResponse(Response response) {
    return EditDartfixResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['suggestions'] =
        suggestions.map((DartFixSuggestion value) => value.toJson()).toList();
    result['otherSuggestions'] = otherSuggestions
        .map((DartFixSuggestion value) => value.toJson())
        .toList();
    result['hasErrors'] = hasErrors;
    result['edits'] =
        edits.map((SourceFileEdit value) => value.toJson()).toList();
    if (details != null) {
      result['details'] = details;
    }
    if (port != null) {
      result['port'] = port;
    }
    if (urls != null) {
      result['urls'] = urls;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditDartfixResult) {
      return listEqual(suggestions, other.suggestions,
              (DartFixSuggestion a, DartFixSuggestion b) => a == b) &&
          listEqual(otherSuggestions, other.otherSuggestions,
              (DartFixSuggestion a, DartFixSuggestion b) => a == b) &&
          hasErrors == other.hasErrors &&
          listEqual(edits, other.edits,
              (SourceFileEdit a, SourceFileEdit b) => a == b) &&
          listEqual(details, other.details, (String a, String b) => a == b) &&
          port == other.port &&
          listEqual(urls, other.urls, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, suggestions.hashCode);
    hash = JenkinsSmiHash.combine(hash, otherSuggestions.hashCode);
    hash = JenkinsSmiHash.combine(hash, hasErrors.hashCode);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = JenkinsSmiHash.combine(hash, details.hashCode);
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    hash = JenkinsSmiHash.combine(hash, urls.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.format params
///
/// {
///   "file": FilePath
///   "selectionOffset": int
///   "selectionLength": int
///   "lineLength": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditFormatParams implements RequestParams {
  String _file;

  int _selectionOffset;

  int _selectionLength;

  int _lineLength;

  /// The file containing the code to be formatted.
  String get file => _file;

  /// The file containing the code to be formatted.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the current selection in the file.
  int get selectionOffset => _selectionOffset;

  /// The offset of the current selection in the file.
  set selectionOffset(int value) {
    assert(value != null);
    _selectionOffset = value;
  }

  /// The length of the current selection in the file.
  int get selectionLength => _selectionLength;

  /// The length of the current selection in the file.
  set selectionLength(int value) {
    assert(value != null);
    _selectionLength = value;
  }

  /// The line length to be used by the formatter.
  int get lineLength => _lineLength;

  /// The line length to be used by the formatter.
  set lineLength(int value) {
    _lineLength = value;
  }

  EditFormatParams(String file, int selectionOffset, int selectionLength,
      {int lineLength}) {
    this.file = file;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
    this.lineLength = lineLength;
  }

  factory EditFormatParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int selectionOffset;
      if (json.containsKey('selectionOffset')) {
        selectionOffset = jsonDecoder.decodeInt(
            jsonPath + '.selectionOffset', json['selectionOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionOffset');
      }
      int selectionLength;
      if (json.containsKey('selectionLength')) {
        selectionLength = jsonDecoder.decodeInt(
            jsonPath + '.selectionLength', json['selectionLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionLength');
      }
      int lineLength;
      if (json.containsKey('lineLength')) {
        lineLength =
            jsonDecoder.decodeInt(jsonPath + '.lineLength', json['lineLength']);
      }
      return EditFormatParams(file, selectionOffset, selectionLength,
          lineLength: lineLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.format params', json);
    }
  }

  factory EditFormatParams.fromRequest(Request request) {
    return EditFormatParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['selectionOffset'] = selectionOffset;
    result['selectionLength'] = selectionLength;
    if (lineLength != null) {
      result['lineLength'] = lineLength;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.format', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditFormatParams) {
      return file == other.file &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength &&
          lineLength == other.lineLength;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, lineLength.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.format result
///
/// {
///   "edits": List<SourceEdit>
///   "selectionOffset": int
///   "selectionLength": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditFormatResult implements ResponseResult {
  List<SourceEdit> _edits;

  int _selectionOffset;

  int _selectionLength;

  /// The edit(s) to be applied in order to format the code. The list will be
  /// empty if the code was already formatted (there are no changes).
  List<SourceEdit> get edits => _edits;

  /// The edit(s) to be applied in order to format the code. The list will be
  /// empty if the code was already formatted (there are no changes).
  set edits(List<SourceEdit> value) {
    assert(value != null);
    _edits = value;
  }

  /// The offset of the selection after formatting the code.
  int get selectionOffset => _selectionOffset;

  /// The offset of the selection after formatting the code.
  set selectionOffset(int value) {
    assert(value != null);
    _selectionOffset = value;
  }

  /// The length of the selection after formatting the code.
  int get selectionLength => _selectionLength;

  /// The length of the selection after formatting the code.
  set selectionLength(int value) {
    assert(value != null);
    _selectionLength = value;
  }

  EditFormatResult(
      List<SourceEdit> edits, int selectionOffset, int selectionLength) {
    this.edits = edits;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
  }

  factory EditFormatResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<SourceEdit> edits;
      if (json.containsKey('edits')) {
        edits = jsonDecoder.decodeList(
            jsonPath + '.edits',
            json['edits'],
            (String jsonPath, Object json) =>
                SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edits');
      }
      int selectionOffset;
      if (json.containsKey('selectionOffset')) {
        selectionOffset = jsonDecoder.decodeInt(
            jsonPath + '.selectionOffset', json['selectionOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionOffset');
      }
      int selectionLength;
      if (json.containsKey('selectionLength')) {
        selectionLength = jsonDecoder.decodeInt(
            jsonPath + '.selectionLength', json['selectionLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'selectionLength');
      }
      return EditFormatResult(edits, selectionOffset, selectionLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.format result', json);
    }
  }

  factory EditFormatResult.fromResponse(Response response) {
    return EditFormatResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['edits'] = edits.map((SourceEdit value) => value.toJson()).toList();
    result['selectionOffset'] = selectionOffset;
    result['selectionLength'] = selectionLength;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditFormatResult) {
      return listEqual(
              edits, other.edits, (SourceEdit a, SourceEdit b) => a == b) &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getAssists params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAssistsParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /// The file containing the code for which assists are being requested.
  String get file => _file;

  /// The file containing the code for which assists are being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the code for which assists are being requested.
  int get offset => _offset;

  /// The offset of the code for which assists are being requested.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the code for which assists are being requested.
  int get length => _length;

  /// The length of the code for which assists are being requested.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  EditGetAssistsParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory EditGetAssistsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return EditGetAssistsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getAssists params', json);
    }
  }

  factory EditGetAssistsParams.fromRequest(Request request) {
    return EditGetAssistsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getAssists', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetAssistsParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getAssists result
///
/// {
///   "assists": List<SourceChange>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAssistsResult implements ResponseResult {
  List<SourceChange> _assists;

  /// The assists that are available at the given location.
  List<SourceChange> get assists => _assists;

  /// The assists that are available at the given location.
  set assists(List<SourceChange> value) {
    assert(value != null);
    _assists = value;
  }

  EditGetAssistsResult(List<SourceChange> assists) {
    this.assists = assists;
  }

  factory EditGetAssistsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<SourceChange> assists;
      if (json.containsKey('assists')) {
        assists = jsonDecoder.decodeList(
            jsonPath + '.assists',
            json['assists'],
            (String jsonPath, Object json) =>
                SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'assists');
      }
      return EditGetAssistsResult(assists);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getAssists result', json);
    }
  }

  factory EditGetAssistsResult.fromResponse(Response response) {
    return EditGetAssistsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['assists'] =
        assists.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetAssistsResult) {
      return listEqual(
          assists, other.assists, (SourceChange a, SourceChange b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, assists.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getAvailableRefactorings params
///
/// {
///   "file": FilePath
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAvailableRefactoringsParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /// The file containing the code on which the refactoring would be based.
  String get file => _file;

  /// The file containing the code on which the refactoring would be based.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the code on which the refactoring would be based.
  int get offset => _offset;

  /// The offset of the code on which the refactoring would be based.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the code on which the refactoring would be based.
  int get length => _length;

  /// The length of the code on which the refactoring would be based.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  EditGetAvailableRefactoringsParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory EditGetAvailableRefactoringsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return EditGetAvailableRefactoringsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getAvailableRefactorings params', json);
    }
  }

  factory EditGetAvailableRefactoringsParams.fromRequest(Request request) {
    return EditGetAvailableRefactoringsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getAvailableRefactorings', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetAvailableRefactoringsParams) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getAvailableRefactorings result
///
/// {
///   "kinds": List<RefactoringKind>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetAvailableRefactoringsResult implements ResponseResult {
  List<RefactoringKind> _kinds;

  /// The kinds of refactorings that are valid for the given selection.
  List<RefactoringKind> get kinds => _kinds;

  /// The kinds of refactorings that are valid for the given selection.
  set kinds(List<RefactoringKind> value) {
    assert(value != null);
    _kinds = value;
  }

  EditGetAvailableRefactoringsResult(List<RefactoringKind> kinds) {
    this.kinds = kinds;
  }

  factory EditGetAvailableRefactoringsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<RefactoringKind> kinds;
      if (json.containsKey('kinds')) {
        kinds = jsonDecoder.decodeList(
            jsonPath + '.kinds',
            json['kinds'],
            (String jsonPath, Object json) =>
                RefactoringKind.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kinds');
      }
      return EditGetAvailableRefactoringsResult(kinds);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getAvailableRefactorings result', json);
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(Response response) {
    return EditGetAvailableRefactoringsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kinds'] =
        kinds.map((RefactoringKind value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetAvailableRefactoringsResult) {
      return listEqual(
          kinds, other.kinds, (RefactoringKind a, RefactoringKind b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kinds.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getDartfixInfo params
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetDartfixInfoParams implements RequestParams {
  EditGetDartfixInfoParams();

  factory EditGetDartfixInfoParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      return EditGetDartfixInfoParams();
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getDartfixInfo params', json);
    }
  }

  factory EditGetDartfixInfoParams.fromRequest(Request request) {
    return EditGetDartfixInfoParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getDartfixInfo', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetDartfixInfoParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getDartfixInfo result
///
/// {
///   "fixes": List<DartFix>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetDartfixInfoResult implements ResponseResult {
  List<DartFix> _fixes;

  /// A list of fixes that can be specified in an edit.dartfix request.
  List<DartFix> get fixes => _fixes;

  /// A list of fixes that can be specified in an edit.dartfix request.
  set fixes(List<DartFix> value) {
    assert(value != null);
    _fixes = value;
  }

  EditGetDartfixInfoResult(List<DartFix> fixes) {
    this.fixes = fixes;
  }

  factory EditGetDartfixInfoResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<DartFix> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            jsonPath + '.fixes',
            json['fixes'],
            (String jsonPath, Object json) =>
                DartFix.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return EditGetDartfixInfoResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getDartfixInfo result', json);
    }
  }

  factory EditGetDartfixInfoResult.fromResponse(Response response) {
    return EditGetDartfixInfoResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['fixes'] = fixes.map((DartFix value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetDartfixInfoResult) {
      return listEqual(fixes, other.fixes, (DartFix a, DartFix b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, fixes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getFixes params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetFixesParams implements RequestParams {
  String _file;

  int _offset;

  /// The file containing the errors for which fixes are being requested.
  String get file => _file;

  /// The file containing the errors for which fixes are being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset used to select the errors for which fixes will be returned.
  int get offset => _offset;

  /// The offset used to select the errors for which fixes will be returned.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  EditGetFixesParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory EditGetFixesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditGetFixesParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getFixes params', json);
    }
  }

  factory EditGetFixesParams.fromRequest(Request request) {
    return EditGetFixesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getFixes', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetFixesParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getFixes result
///
/// {
///   "fixes": List<AnalysisErrorFixes>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetFixesResult implements ResponseResult {
  List<AnalysisErrorFixes> _fixes;

  /// The fixes that are available for the errors at the given offset.
  List<AnalysisErrorFixes> get fixes => _fixes;

  /// The fixes that are available for the errors at the given offset.
  set fixes(List<AnalysisErrorFixes> value) {
    assert(value != null);
    _fixes = value;
  }

  EditGetFixesResult(List<AnalysisErrorFixes> fixes) {
    this.fixes = fixes;
  }

  factory EditGetFixesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<AnalysisErrorFixes> fixes;
      if (json.containsKey('fixes')) {
        fixes = jsonDecoder.decodeList(
            jsonPath + '.fixes',
            json['fixes'],
            (String jsonPath, Object json) =>
                AnalysisErrorFixes.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fixes');
      }
      return EditGetFixesResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getFixes result', json);
    }
  }

  factory EditGetFixesResult.fromResponse(Response response) {
    return EditGetFixesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['fixes'] =
        fixes.map((AnalysisErrorFixes value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetFixesResult) {
      return listEqual(fixes, other.fixes,
          (AnalysisErrorFixes a, AnalysisErrorFixes b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, fixes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getPostfixCompletion params
///
/// {
///   "file": FilePath
///   "key": String
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetPostfixCompletionParams implements RequestParams {
  String _file;

  String _key;

  int _offset;

  /// The file containing the postfix template to be expanded.
  String get file => _file;

  /// The file containing the postfix template to be expanded.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The unique name that identifies the template in use.
  String get key => _key;

  /// The unique name that identifies the template in use.
  set key(String value) {
    assert(value != null);
    _key = value;
  }

  /// The offset used to identify the code to which the template will be
  /// applied.
  int get offset => _offset;

  /// The offset used to identify the code to which the template will be
  /// applied.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  EditGetPostfixCompletionParams(String file, String key, int offset) {
    this.file = file;
    this.key = key;
    this.offset = offset;
  }

  factory EditGetPostfixCompletionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      String key;
      if (json.containsKey('key')) {
        key = jsonDecoder.decodeString(jsonPath + '.key', json['key']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'key');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditGetPostfixCompletionParams(file, key, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getPostfixCompletion params', json);
    }
  }

  factory EditGetPostfixCompletionParams.fromRequest(Request request) {
    return EditGetPostfixCompletionParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['key'] = key;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getPostfixCompletion', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetPostfixCompletionParams) {
      return file == other.file && key == other.key && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, key.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getPostfixCompletion result
///
/// {
///   "change": SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetPostfixCompletionResult implements ResponseResult {
  SourceChange _change;

  /// The change to be applied in order to complete the statement.
  SourceChange get change => _change;

  /// The change to be applied in order to complete the statement.
  set change(SourceChange value) {
    assert(value != null);
    _change = value;
  }

  EditGetPostfixCompletionResult(SourceChange change) {
    this.change = change;
  }

  factory EditGetPostfixCompletionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, jsonPath + '.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      return EditGetPostfixCompletionResult(change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getPostfixCompletion result', json);
    }
  }

  factory EditGetPostfixCompletionResult.fromResponse(Response response) {
    return EditGetPostfixCompletionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['change'] = change.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetPostfixCompletionResult) {
      return change == other.change;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getRefactoring params
///
/// {
///   "kind": RefactoringKind
///   "file": FilePath
///   "offset": int
///   "length": int
///   "validateOnly": bool
///   "options": optional RefactoringOptions
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetRefactoringParams implements RequestParams {
  RefactoringKind _kind;

  String _file;

  int _offset;

  int _length;

  bool _validateOnly;

  RefactoringOptions _options;

  /// The kind of refactoring to be performed.
  RefactoringKind get kind => _kind;

  /// The kind of refactoring to be performed.
  set kind(RefactoringKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The file containing the code involved in the refactoring.
  String get file => _file;

  /// The file containing the code involved in the refactoring.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the region involved in the refactoring.
  int get offset => _offset;

  /// The offset of the region involved in the refactoring.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the region involved in the refactoring.
  int get length => _length;

  /// The length of the region involved in the refactoring.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// True if the client is only requesting that the values of the options be
  /// validated and no change be generated.
  bool get validateOnly => _validateOnly;

  /// True if the client is only requesting that the values of the options be
  /// validated and no change be generated.
  set validateOnly(bool value) {
    assert(value != null);
    _validateOnly = value;
  }

  /// Data used to provide values provided by the user. The structure of the
  /// data is dependent on the kind of refactoring being performed. The data
  /// that is expected is documented in the section titled Refactorings,
  /// labeled as "Options". This field can be omitted if the refactoring does
  /// not require any options or if the values of those options are not known.
  RefactoringOptions get options => _options;

  /// Data used to provide values provided by the user. The structure of the
  /// data is dependent on the kind of refactoring being performed. The data
  /// that is expected is documented in the section titled Refactorings,
  /// labeled as "Options". This field can be omitted if the refactoring does
  /// not require any options or if the values of those options are not known.
  set options(RefactoringOptions value) {
    _options = value;
  }

  EditGetRefactoringParams(RefactoringKind kind, String file, int offset,
      int length, bool validateOnly,
      {RefactoringOptions options}) {
    this.kind = kind;
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.validateOnly = validateOnly;
    this.options = options;
  }

  factory EditGetRefactoringParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      RefactoringKind kind;
      if (json.containsKey('kind')) {
        kind = RefactoringKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      bool validateOnly;
      if (json.containsKey('validateOnly')) {
        validateOnly = jsonDecoder.decodeBool(
            jsonPath + '.validateOnly', json['validateOnly']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'validateOnly');
      }
      RefactoringOptions options;
      if (json.containsKey('options')) {
        options = RefactoringOptions.fromJson(
            jsonDecoder, jsonPath + '.options', json['options'], kind);
      }
      return EditGetRefactoringParams(kind, file, offset, length, validateOnly,
          options: options);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getRefactoring params', json);
    }
  }

  factory EditGetRefactoringParams.fromRequest(Request request) {
    var params = EditGetRefactoringParams.fromJson(
        RequestDecoder(request), 'params', request.params);
    REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind;
    return params;
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['file'] = file;
    result['offset'] = offset;
    result['length'] = length;
    result['validateOnly'] = validateOnly;
    if (options != null) {
      result['options'] = options.toJson();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getRefactoring', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetRefactoringParams) {
      return kind == other.kind &&
          file == other.file &&
          offset == other.offset &&
          length == other.length &&
          validateOnly == other.validateOnly &&
          options == other.options;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, validateOnly.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getRefactoring result
///
/// {
///   "initialProblems": List<RefactoringProblem>
///   "optionsProblems": List<RefactoringProblem>
///   "finalProblems": List<RefactoringProblem>
///   "feedback": optional RefactoringFeedback
///   "change": optional SourceChange
///   "potentialEdits": optional List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetRefactoringResult implements ResponseResult {
  List<RefactoringProblem> _initialProblems;

  List<RefactoringProblem> _optionsProblems;

  List<RefactoringProblem> _finalProblems;

  RefactoringFeedback _feedback;

  SourceChange _change;

  List<String> _potentialEdits;

  /// The initial status of the refactoring, i.e. problems related to the
  /// context in which the refactoring is requested. The array will be empty if
  /// there are no known problems.
  List<RefactoringProblem> get initialProblems => _initialProblems;

  /// The initial status of the refactoring, i.e. problems related to the
  /// context in which the refactoring is requested. The array will be empty if
  /// there are no known problems.
  set initialProblems(List<RefactoringProblem> value) {
    assert(value != null);
    _initialProblems = value;
  }

  /// The options validation status, i.e. problems in the given options, such
  /// as light-weight validation of a new name, flags compatibility, etc. The
  /// array will be empty if there are no known problems.
  List<RefactoringProblem> get optionsProblems => _optionsProblems;

  /// The options validation status, i.e. problems in the given options, such
  /// as light-weight validation of a new name, flags compatibility, etc. The
  /// array will be empty if there are no known problems.
  set optionsProblems(List<RefactoringProblem> value) {
    assert(value != null);
    _optionsProblems = value;
  }

  /// The final status of the refactoring, i.e. problems identified in the
  /// result of a full, potentially expensive validation and / or change
  /// creation. The array will be empty if there are no known problems.
  List<RefactoringProblem> get finalProblems => _finalProblems;

  /// The final status of the refactoring, i.e. problems identified in the
  /// result of a full, potentially expensive validation and / or change
  /// creation. The array will be empty if there are no known problems.
  set finalProblems(List<RefactoringProblem> value) {
    assert(value != null);
    _finalProblems = value;
  }

  /// Data used to provide feedback to the user. The structure of the data is
  /// dependent on the kind of refactoring being created. The data that is
  /// returned is documented in the section titled Refactorings, labeled as
  /// "Feedback".
  RefactoringFeedback get feedback => _feedback;

  /// Data used to provide feedback to the user. The structure of the data is
  /// dependent on the kind of refactoring being created. The data that is
  /// returned is documented in the section titled Refactorings, labeled as
  /// "Feedback".
  set feedback(RefactoringFeedback value) {
    _feedback = value;
  }

  /// The changes that are to be applied to affect the refactoring. This field
  /// will be omitted if there are problems that prevent a set of changes from
  /// being computed, such as having no options specified for a refactoring
  /// that requires them, or if only validation was requested.
  SourceChange get change => _change;

  /// The changes that are to be applied to affect the refactoring. This field
  /// will be omitted if there are problems that prevent a set of changes from
  /// being computed, such as having no options specified for a refactoring
  /// that requires them, or if only validation was requested.
  set change(SourceChange value) {
    _change = value;
  }

  /// The ids of source edits that are not known to be valid. An edit is not
  /// known to be valid if there was insufficient type information for the
  /// server to be able to determine whether or not the code needs to be
  /// modified, such as when a member is being renamed and there is a reference
  /// to a member from an unknown type. This field will be omitted if the
  /// change field is omitted or if there are no potential edits for the
  /// refactoring.
  List<String> get potentialEdits => _potentialEdits;

  /// The ids of source edits that are not known to be valid. An edit is not
  /// known to be valid if there was insufficient type information for the
  /// server to be able to determine whether or not the code needs to be
  /// modified, such as when a member is being renamed and there is a reference
  /// to a member from an unknown type. This field will be omitted if the
  /// change field is omitted or if there are no potential edits for the
  /// refactoring.
  set potentialEdits(List<String> value) {
    _potentialEdits = value;
  }

  EditGetRefactoringResult(
      List<RefactoringProblem> initialProblems,
      List<RefactoringProblem> optionsProblems,
      List<RefactoringProblem> finalProblems,
      {RefactoringFeedback feedback,
      SourceChange change,
      List<String> potentialEdits}) {
    this.initialProblems = initialProblems;
    this.optionsProblems = optionsProblems;
    this.finalProblems = finalProblems;
    this.feedback = feedback;
    this.change = change;
    this.potentialEdits = potentialEdits;
  }

  factory EditGetRefactoringResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<RefactoringProblem> initialProblems;
      if (json.containsKey('initialProblems')) {
        initialProblems = jsonDecoder.decodeList(
            jsonPath + '.initialProblems',
            json['initialProblems'],
            (String jsonPath, Object json) =>
                RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'initialProblems');
      }
      List<RefactoringProblem> optionsProblems;
      if (json.containsKey('optionsProblems')) {
        optionsProblems = jsonDecoder.decodeList(
            jsonPath + '.optionsProblems',
            json['optionsProblems'],
            (String jsonPath, Object json) =>
                RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'optionsProblems');
      }
      List<RefactoringProblem> finalProblems;
      if (json.containsKey('finalProblems')) {
        finalProblems = jsonDecoder.decodeList(
            jsonPath + '.finalProblems',
            json['finalProblems'],
            (String jsonPath, Object json) =>
                RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'finalProblems');
      }
      RefactoringFeedback feedback;
      if (json.containsKey('feedback')) {
        feedback = RefactoringFeedback.fromJson(
            jsonDecoder, jsonPath + '.feedback', json['feedback'], json);
      }
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, jsonPath + '.change', json['change']);
      }
      List<String> potentialEdits;
      if (json.containsKey('potentialEdits')) {
        potentialEdits = jsonDecoder.decodeList(jsonPath + '.potentialEdits',
            json['potentialEdits'], jsonDecoder.decodeString);
      }
      return EditGetRefactoringResult(
          initialProblems, optionsProblems, finalProblems,
          feedback: feedback, change: change, potentialEdits: potentialEdits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.getRefactoring result', json);
    }
  }

  factory EditGetRefactoringResult.fromResponse(Response response) {
    return EditGetRefactoringResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['initialProblems'] = initialProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    result['optionsProblems'] = optionsProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    result['finalProblems'] = finalProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    if (feedback != null) {
      result['feedback'] = feedback.toJson();
    }
    if (change != null) {
      result['change'] = change.toJson();
    }
    if (potentialEdits != null) {
      result['potentialEdits'] = potentialEdits;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetRefactoringResult) {
      return listEqual(initialProblems, other.initialProblems,
              (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          listEqual(optionsProblems, other.optionsProblems,
              (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          listEqual(finalProblems, other.finalProblems,
              (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          feedback == other.feedback &&
          change == other.change &&
          listEqual(potentialEdits, other.potentialEdits,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, initialProblems.hashCode);
    hash = JenkinsSmiHash.combine(hash, optionsProblems.hashCode);
    hash = JenkinsSmiHash.combine(hash, finalProblems.hashCode);
    hash = JenkinsSmiHash.combine(hash, feedback.hashCode);
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    hash = JenkinsSmiHash.combine(hash, potentialEdits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getStatementCompletion params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetStatementCompletionParams implements RequestParams {
  String _file;

  int _offset;

  /// The file containing the statement to be completed.
  String get file => _file;

  /// The file containing the statement to be completed.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset used to identify the statement to be completed.
  int get offset => _offset;

  /// The offset used to identify the statement to be completed.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  EditGetStatementCompletionParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory EditGetStatementCompletionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditGetStatementCompletionParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getStatementCompletion params', json);
    }
  }

  factory EditGetStatementCompletionParams.fromRequest(Request request) {
    return EditGetStatementCompletionParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.getStatementCompletion', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetStatementCompletionParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.getStatementCompletion result
///
/// {
///   "change": SourceChange
///   "whitespaceOnly": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditGetStatementCompletionResult implements ResponseResult {
  SourceChange _change;

  bool _whitespaceOnly;

  /// The change to be applied in order to complete the statement.
  SourceChange get change => _change;

  /// The change to be applied in order to complete the statement.
  set change(SourceChange value) {
    assert(value != null);
    _change = value;
  }

  /// Will be true if the change contains nothing but whitespace characters, or
  /// is empty.
  bool get whitespaceOnly => _whitespaceOnly;

  /// Will be true if the change contains nothing but whitespace characters, or
  /// is empty.
  set whitespaceOnly(bool value) {
    assert(value != null);
    _whitespaceOnly = value;
  }

  EditGetStatementCompletionResult(SourceChange change, bool whitespaceOnly) {
    this.change = change;
    this.whitespaceOnly = whitespaceOnly;
  }

  factory EditGetStatementCompletionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, jsonPath + '.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      bool whitespaceOnly;
      if (json.containsKey('whitespaceOnly')) {
        whitespaceOnly = jsonDecoder.decodeBool(
            jsonPath + '.whitespaceOnly', json['whitespaceOnly']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'whitespaceOnly');
      }
      return EditGetStatementCompletionResult(change, whitespaceOnly);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.getStatementCompletion result', json);
    }
  }

  factory EditGetStatementCompletionResult.fromResponse(Response response) {
    return EditGetStatementCompletionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['change'] = change.toJson();
    result['whitespaceOnly'] = whitespaceOnly;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetStatementCompletionResult) {
      return change == other.change && whitespaceOnly == other.whitespaceOnly;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    hash = JenkinsSmiHash.combine(hash, whitespaceOnly.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.importElements params
///
/// {
///   "file": FilePath
///   "elements": List<ImportedElements>
///   "offset": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditImportElementsParams implements RequestParams {
  String _file;

  List<ImportedElements> _elements;

  int _offset;

  /// The file in which the specified elements are to be made accessible.
  String get file => _file;

  /// The file in which the specified elements are to be made accessible.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The elements to be made accessible in the specified file.
  List<ImportedElements> get elements => _elements;

  /// The elements to be made accessible in the specified file.
  set elements(List<ImportedElements> value) {
    assert(value != null);
    _elements = value;
  }

  /// The offset at which the specified elements need to be made accessible. If
  /// provided, this is used to guard against adding imports for text that
  /// would be inserted into a comment, string literal, or other location where
  /// the imports would not be necessary.
  int get offset => _offset;

  /// The offset at which the specified elements need to be made accessible. If
  /// provided, this is used to guard against adding imports for text that
  /// would be inserted into a comment, string literal, or other location where
  /// the imports would not be necessary.
  set offset(int value) {
    _offset = value;
  }

  EditImportElementsParams(String file, List<ImportedElements> elements,
      {int offset}) {
    this.file = file;
    this.elements = elements;
    this.offset = offset;
  }

  factory EditImportElementsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      List<ImportedElements> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            jsonPath + '.elements',
            json['elements'],
            (String jsonPath, Object json) =>
                ImportedElements.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      }
      return EditImportElementsParams(file, elements, offset: offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.importElements params', json);
    }
  }

  factory EditImportElementsParams.fromRequest(Request request) {
    return EditImportElementsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['elements'] =
        elements.map((ImportedElements value) => value.toJson()).toList();
    if (offset != null) {
      result['offset'] = offset;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.importElements', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditImportElementsParams) {
      return file == other.file &&
          listEqual(elements, other.elements,
              (ImportedElements a, ImportedElements b) => a == b) &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.importElements result
///
/// {
///   "edit": optional SourceFileEdit
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditImportElementsResult implements ResponseResult {
  SourceFileEdit _edit;

  /// The edits to be applied in order to make the specified elements
  /// accessible. The file to be edited will be the defining compilation unit
  /// of the library containing the file specified in the request, which can be
  /// different than the file specified in the request if the specified file is
  /// a part file. This field will be omitted if there are no edits that need
  /// to be applied.
  SourceFileEdit get edit => _edit;

  /// The edits to be applied in order to make the specified elements
  /// accessible. The file to be edited will be the defining compilation unit
  /// of the library containing the file specified in the request, which can be
  /// different than the file specified in the request if the specified file is
  /// a part file. This field will be omitted if there are no edits that need
  /// to be applied.
  set edit(SourceFileEdit value) {
    _edit = value;
  }

  EditImportElementsResult({SourceFileEdit edit}) {
    this.edit = edit;
  }

  factory EditImportElementsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey('edit')) {
        edit = SourceFileEdit.fromJson(
            jsonDecoder, jsonPath + '.edit', json['edit']);
      }
      return EditImportElementsResult(edit: edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.importElements result', json);
    }
  }

  factory EditImportElementsResult.fromResponse(Response response) {
    return EditImportElementsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (edit != null) {
      result['edit'] = edit.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditImportElementsResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.isPostfixCompletionApplicable params
///
/// {
///   "file": FilePath
///   "key": String
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditIsPostfixCompletionApplicableParams implements RequestParams {
  String _file;

  String _key;

  int _offset;

  /// The file containing the postfix template to be expanded.
  String get file => _file;

  /// The file containing the postfix template to be expanded.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The unique name that identifies the template in use.
  String get key => _key;

  /// The unique name that identifies the template in use.
  set key(String value) {
    assert(value != null);
    _key = value;
  }

  /// The offset used to identify the code to which the template will be
  /// applied.
  int get offset => _offset;

  /// The offset used to identify the code to which the template will be
  /// applied.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  EditIsPostfixCompletionApplicableParams(String file, String key, int offset) {
    this.file = file;
    this.key = key;
    this.offset = offset;
  }

  factory EditIsPostfixCompletionApplicableParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      String key;
      if (json.containsKey('key')) {
        key = jsonDecoder.decodeString(jsonPath + '.key', json['key']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'key');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return EditIsPostfixCompletionApplicableParams(file, key, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.isPostfixCompletionApplicable params', json);
    }
  }

  factory EditIsPostfixCompletionApplicableParams.fromRequest(Request request) {
    return EditIsPostfixCompletionApplicableParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['key'] = key;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.isPostfixCompletionApplicable', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditIsPostfixCompletionApplicableParams) {
      return file == other.file && key == other.key && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, key.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.isPostfixCompletionApplicable result
///
/// {
///   "value": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditIsPostfixCompletionApplicableResult implements ResponseResult {
  bool _value;

  /// True if the template can be expanded at the given location.
  bool get value => _value;

  /// True if the template can be expanded at the given location.
  set value(bool value) {
    assert(value != null);
    _value = value;
  }

  EditIsPostfixCompletionApplicableResult(bool value) {
    this.value = value;
  }

  factory EditIsPostfixCompletionApplicableResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool value;
      if (json.containsKey('value')) {
        value = jsonDecoder.decodeBool(jsonPath + '.value', json['value']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'value');
      }
      return EditIsPostfixCompletionApplicableResult(value);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.isPostfixCompletionApplicable result', json);
    }
  }

  factory EditIsPostfixCompletionApplicableResult.fromResponse(
      Response response) {
    return EditIsPostfixCompletionApplicableResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['value'] = value;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditIsPostfixCompletionApplicableResult) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.listPostfixCompletionTemplates params
///
/// Clients may not extend, implement or mix-in this class.
class EditListPostfixCompletionTemplatesParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.listPostfixCompletionTemplates', null);
  }

  @override
  bool operator ==(other) {
    if (other is EditListPostfixCompletionTemplatesParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 690713107;
  }
}

/// edit.listPostfixCompletionTemplates result
///
/// {
///   "templates": List<PostfixTemplateDescriptor>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditListPostfixCompletionTemplatesResult implements ResponseResult {
  List<PostfixTemplateDescriptor> _templates;

  /// The list of available templates.
  List<PostfixTemplateDescriptor> get templates => _templates;

  /// The list of available templates.
  set templates(List<PostfixTemplateDescriptor> value) {
    assert(value != null);
    _templates = value;
  }

  EditListPostfixCompletionTemplatesResult(
      List<PostfixTemplateDescriptor> templates) {
    this.templates = templates;
  }

  factory EditListPostfixCompletionTemplatesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<PostfixTemplateDescriptor> templates;
      if (json.containsKey('templates')) {
        templates = jsonDecoder.decodeList(
            jsonPath + '.templates',
            json['templates'],
            (String jsonPath, Object json) =>
                PostfixTemplateDescriptor.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'templates');
      }
      return EditListPostfixCompletionTemplatesResult(templates);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.listPostfixCompletionTemplates result', json);
    }
  }

  factory EditListPostfixCompletionTemplatesResult.fromResponse(
      Response response) {
    return EditListPostfixCompletionTemplatesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['templates'] = templates
        .map((PostfixTemplateDescriptor value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditListPostfixCompletionTemplatesResult) {
      return listEqual(templates, other.templates,
          (PostfixTemplateDescriptor a, PostfixTemplateDescriptor b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, templates.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.organizeDirectives params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditOrganizeDirectivesParams implements RequestParams {
  String _file;

  /// The Dart file to organize directives in.
  String get file => _file;

  /// The Dart file to organize directives in.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  EditOrganizeDirectivesParams(String file) {
    this.file = file;
  }

  factory EditOrganizeDirectivesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return EditOrganizeDirectivesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.organizeDirectives params', json);
    }
  }

  factory EditOrganizeDirectivesParams.fromRequest(Request request) {
    return EditOrganizeDirectivesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.organizeDirectives', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditOrganizeDirectivesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.organizeDirectives result
///
/// {
///   "edit": SourceFileEdit
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditOrganizeDirectivesResult implements ResponseResult {
  SourceFileEdit _edit;

  /// The file edit that is to be applied to the given file to effect the
  /// organizing.
  SourceFileEdit get edit => _edit;

  /// The file edit that is to be applied to the given file to effect the
  /// organizing.
  set edit(SourceFileEdit value) {
    assert(value != null);
    _edit = value;
  }

  EditOrganizeDirectivesResult(SourceFileEdit edit) {
    this.edit = edit;
  }

  factory EditOrganizeDirectivesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey('edit')) {
        edit = SourceFileEdit.fromJson(
            jsonDecoder, jsonPath + '.edit', json['edit']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edit');
      }
      return EditOrganizeDirectivesResult(edit);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'edit.organizeDirectives result', json);
    }
  }

  factory EditOrganizeDirectivesResult.fromResponse(Response response) {
    return EditOrganizeDirectivesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['edit'] = edit.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditOrganizeDirectivesResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.sortMembers params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditSortMembersParams implements RequestParams {
  String _file;

  /// The Dart file to sort.
  String get file => _file;

  /// The Dart file to sort.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  EditSortMembersParams(String file) {
    this.file = file;
  }

  factory EditSortMembersParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return EditSortMembersParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.sortMembers params', json);
    }
  }

  factory EditSortMembersParams.fromRequest(Request request) {
    return EditSortMembersParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'edit.sortMembers', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditSortMembersParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// edit.sortMembers result
///
/// {
///   "edit": SourceFileEdit
/// }
///
/// Clients may not extend, implement or mix-in this class.
class EditSortMembersResult implements ResponseResult {
  SourceFileEdit _edit;

  /// The file edit that is to be applied to the given file to effect the
  /// sorting.
  SourceFileEdit get edit => _edit;

  /// The file edit that is to be applied to the given file to effect the
  /// sorting.
  set edit(SourceFileEdit value) {
    assert(value != null);
    _edit = value;
  }

  EditSortMembersResult(SourceFileEdit edit) {
    this.edit = edit;
  }

  factory EditSortMembersResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey('edit')) {
        edit = SourceFileEdit.fromJson(
            jsonDecoder, jsonPath + '.edit', json['edit']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'edit');
      }
      return EditSortMembersResult(edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'edit.sortMembers result', json);
    }
  }

  factory EditSortMembersResult.fromResponse(Response response) {
    return EditSortMembersResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['edit'] = edit.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditSortMembersResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ElementDeclaration
///
/// {
///   "name": String
///   "kind": ElementKind
///   "fileIndex": int
///   "offset": int
///   "line": int
///   "column": int
///   "codeOffset": int
///   "codeLength": int
///   "className": optional String
///   "mixinName": optional String
///   "parameters": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ElementDeclaration implements HasToJson {
  String _name;

  ElementKind _kind;

  int _fileIndex;

  int _offset;

  int _line;

  int _column;

  int _codeOffset;

  int _codeLength;

  String _className;

  String _mixinName;

  String _parameters;

  /// The name of the declaration.
  String get name => _name;

  /// The name of the declaration.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The kind of the element that corresponds to the declaration.
  ElementKind get kind => _kind;

  /// The kind of the element that corresponds to the declaration.
  set kind(ElementKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The index of the file (in the enclosing response).
  int get fileIndex => _fileIndex;

  /// The index of the file (in the enclosing response).
  set fileIndex(int value) {
    assert(value != null);
    _fileIndex = value;
  }

  /// The offset of the declaration name in the file.
  int get offset => _offset;

  /// The offset of the declaration name in the file.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The one-based index of the line containing the declaration name.
  int get line => _line;

  /// The one-based index of the line containing the declaration name.
  set line(int value) {
    assert(value != null);
    _line = value;
  }

  /// The one-based index of the column containing the declaration name.
  int get column => _column;

  /// The one-based index of the column containing the declaration name.
  set column(int value) {
    assert(value != null);
    _column = value;
  }

  /// The offset of the first character of the declaration code in the file.
  int get codeOffset => _codeOffset;

  /// The offset of the first character of the declaration code in the file.
  set codeOffset(int value) {
    assert(value != null);
    _codeOffset = value;
  }

  /// The length of the declaration code in the file.
  int get codeLength => _codeLength;

  /// The length of the declaration code in the file.
  set codeLength(int value) {
    assert(value != null);
    _codeLength = value;
  }

  /// The name of the class enclosing this declaration. If the declaration is
  /// not a class member, this field will be absent.
  String get className => _className;

  /// The name of the class enclosing this declaration. If the declaration is
  /// not a class member, this field will be absent.
  set className(String value) {
    _className = value;
  }

  /// The name of the mixin enclosing this declaration. If the declaration is
  /// not a mixin member, this field will be absent.
  String get mixinName => _mixinName;

  /// The name of the mixin enclosing this declaration. If the declaration is
  /// not a mixin member, this field will be absent.
  set mixinName(String value) {
    _mixinName = value;
  }

  /// The parameter list for the element. If the element is not a method or
  /// function this field will not be defined. If the element doesn't have
  /// parameters (e.g. getter), this field will not be defined. If the element
  /// has zero parameters, this field will have a value of "()". The value
  /// should not be treated as exact presentation of parameters, it is just
  /// approximation of parameters to give the user general idea.
  String get parameters => _parameters;

  /// The parameter list for the element. If the element is not a method or
  /// function this field will not be defined. If the element doesn't have
  /// parameters (e.g. getter), this field will not be defined. If the element
  /// has zero parameters, this field will have a value of "()". The value
  /// should not be treated as exact presentation of parameters, it is just
  /// approximation of parameters to give the user general idea.
  set parameters(String value) {
    _parameters = value;
  }

  ElementDeclaration(String name, ElementKind kind, int fileIndex, int offset,
      int line, int column, int codeOffset, int codeLength,
      {String className, String mixinName, String parameters}) {
    this.name = name;
    this.kind = kind;
    this.fileIndex = fileIndex;
    this.offset = offset;
    this.line = line;
    this.column = column;
    this.codeOffset = codeOffset;
    this.codeLength = codeLength;
    this.className = className;
    this.mixinName = mixinName;
    this.parameters = parameters;
  }

  factory ElementDeclaration.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      ElementKind kind;
      if (json.containsKey('kind')) {
        kind =
            ElementKind.fromJson(jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      int fileIndex;
      if (json.containsKey('fileIndex')) {
        fileIndex =
            jsonDecoder.decodeInt(jsonPath + '.fileIndex', json['fileIndex']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'fileIndex');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int line;
      if (json.containsKey('line')) {
        line = jsonDecoder.decodeInt(jsonPath + '.line', json['line']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'line');
      }
      int column;
      if (json.containsKey('column')) {
        column = jsonDecoder.decodeInt(jsonPath + '.column', json['column']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'column');
      }
      int codeOffset;
      if (json.containsKey('codeOffset')) {
        codeOffset =
            jsonDecoder.decodeInt(jsonPath + '.codeOffset', json['codeOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeOffset');
      }
      int codeLength;
      if (json.containsKey('codeLength')) {
        codeLength =
            jsonDecoder.decodeInt(jsonPath + '.codeLength', json['codeLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeLength');
      }
      String className;
      if (json.containsKey('className')) {
        className = jsonDecoder.decodeString(
            jsonPath + '.className', json['className']);
      }
      String mixinName;
      if (json.containsKey('mixinName')) {
        mixinName = jsonDecoder.decodeString(
            jsonPath + '.mixinName', json['mixinName']);
      }
      String parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeString(
            jsonPath + '.parameters', json['parameters']);
      }
      return ElementDeclaration(
          name, kind, fileIndex, offset, line, column, codeOffset, codeLength,
          className: className, mixinName: mixinName, parameters: parameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ElementDeclaration', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['kind'] = kind.toJson();
    result['fileIndex'] = fileIndex;
    result['offset'] = offset;
    result['line'] = line;
    result['column'] = column;
    result['codeOffset'] = codeOffset;
    result['codeLength'] = codeLength;
    if (className != null) {
      result['className'] = className;
    }
    if (mixinName != null) {
      result['mixinName'] = mixinName;
    }
    if (parameters != null) {
      result['parameters'] = parameters;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ElementDeclaration) {
      return name == other.name &&
          kind == other.kind &&
          fileIndex == other.fileIndex &&
          offset == other.offset &&
          line == other.line &&
          column == other.column &&
          codeOffset == other.codeOffset &&
          codeLength == other.codeLength &&
          className == other.className &&
          mixinName == other.mixinName &&
          parameters == other.parameters;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, fileIndex.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, line.hashCode);
    hash = JenkinsSmiHash.combine(hash, column.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    hash = JenkinsSmiHash.combine(hash, mixinName.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ExecutableFile
///
/// {
///   "file": FilePath
///   "kind": ExecutableKind
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutableFile implements HasToJson {
  String _file;

  ExecutableKind _kind;

  /// The path of the executable file.
  String get file => _file;

  /// The path of the executable file.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The kind of the executable file.
  ExecutableKind get kind => _kind;

  /// The kind of the executable file.
  set kind(ExecutableKind value) {
    assert(value != null);
    _kind = value;
  }

  ExecutableFile(String file, ExecutableKind kind) {
    this.file = file;
    this.kind = kind;
  }

  factory ExecutableFile.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      ExecutableKind kind;
      if (json.containsKey('kind')) {
        kind = ExecutableKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      return ExecutableFile(file, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ExecutableFile', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['kind'] = kind.toJson();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutableFile) {
      return file == other.file && kind == other.kind;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ExecutableKind
///
/// enum {
///   CLIENT
///   EITHER
///   NOT_EXECUTABLE
///   SERVER
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutableKind implements Enum {
  static const ExecutableKind CLIENT = ExecutableKind._('CLIENT');

  static const ExecutableKind EITHER = ExecutableKind._('EITHER');

  static const ExecutableKind NOT_EXECUTABLE =
      ExecutableKind._('NOT_EXECUTABLE');

  static const ExecutableKind SERVER = ExecutableKind._('SERVER');

  /// A list containing all of the enum values that are defined.
  static const List<ExecutableKind> VALUES = <ExecutableKind>[
    CLIENT,
    EITHER,
    NOT_EXECUTABLE,
    SERVER
  ];

  @override
  final String name;

  const ExecutableKind._(this.name);

  factory ExecutableKind(String name) {
    switch (name) {
      case 'CLIENT':
        return CLIENT;
      case 'EITHER':
        return EITHER;
      case 'NOT_EXECUTABLE':
        return NOT_EXECUTABLE;
      case 'SERVER':
        return SERVER;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ExecutableKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return ExecutableKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ExecutableKind', json);
  }

  @override
  String toString() => 'ExecutableKind.$name';

  String toJson() => name;
}

/// execution.createContext params
///
/// {
///   "contextRoot": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionCreateContextParams implements RequestParams {
  String _contextRoot;

  /// The path of the Dart or HTML file that will be launched, or the path of
  /// the directory containing the file.
  String get contextRoot => _contextRoot;

  /// The path of the Dart or HTML file that will be launched, or the path of
  /// the directory containing the file.
  set contextRoot(String value) {
    assert(value != null);
    _contextRoot = value;
  }

  ExecutionCreateContextParams(String contextRoot) {
    this.contextRoot = contextRoot;
  }

  factory ExecutionCreateContextParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String contextRoot;
      if (json.containsKey('contextRoot')) {
        contextRoot = jsonDecoder.decodeString(
            jsonPath + '.contextRoot', json['contextRoot']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contextRoot');
      }
      return ExecutionCreateContextParams(contextRoot);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.createContext params', json);
    }
  }

  factory ExecutionCreateContextParams.fromRequest(Request request) {
    return ExecutionCreateContextParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['contextRoot'] = contextRoot;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.createContext', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionCreateContextParams) {
      return contextRoot == other.contextRoot;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, contextRoot.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.createContext result
///
/// {
///   "id": ExecutionContextId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionCreateContextResult implements ResponseResult {
  String _id;

  /// The identifier used to refer to the execution context that was created.
  String get id => _id;

  /// The identifier used to refer to the execution context that was created.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  ExecutionCreateContextResult(String id) {
    this.id = id;
  }

  factory ExecutionCreateContextResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return ExecutionCreateContextResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.createContext result', json);
    }
  }

  factory ExecutionCreateContextResult.fromResponse(Response response) {
    return ExecutionCreateContextResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionCreateContextResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.deleteContext params
///
/// {
///   "id": ExecutionContextId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionDeleteContextParams implements RequestParams {
  String _id;

  /// The identifier of the execution context that is to be deleted.
  String get id => _id;

  /// The identifier of the execution context that is to be deleted.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  ExecutionDeleteContextParams(String id) {
    this.id = id;
  }

  factory ExecutionDeleteContextParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return ExecutionDeleteContextParams(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.deleteContext params', json);
    }
  }

  factory ExecutionDeleteContextParams.fromRequest(Request request) {
    return ExecutionDeleteContextParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.deleteContext', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionDeleteContextParams) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.deleteContext result
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionDeleteContextResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is ExecutionDeleteContextResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 479954425;
  }
}

/// execution.getSuggestions params
///
/// {
///   "code": String
///   "offset": int
///   "contextFile": FilePath
///   "contextOffset": int
///   "variables": List<RuntimeCompletionVariable>
///   "expressions": optional List<RuntimeCompletionExpression>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionGetSuggestionsParams implements RequestParams {
  String _code;

  int _offset;

  String _contextFile;

  int _contextOffset;

  List<RuntimeCompletionVariable> _variables;

  List<RuntimeCompletionExpression> _expressions;

  /// The code to get suggestions in.
  String get code => _code;

  /// The code to get suggestions in.
  set code(String value) {
    assert(value != null);
    _code = value;
  }

  /// The offset within the code to get suggestions at.
  int get offset => _offset;

  /// The offset within the code to get suggestions at.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The path of the context file, e.g. the file of the current debugger
  /// frame. The combination of the context file and context offset can be used
  /// to ensure that all variables of the context are available for completion
  /// (with their static types).
  String get contextFile => _contextFile;

  /// The path of the context file, e.g. the file of the current debugger
  /// frame. The combination of the context file and context offset can be used
  /// to ensure that all variables of the context are available for completion
  /// (with their static types).
  set contextFile(String value) {
    assert(value != null);
    _contextFile = value;
  }

  /// The offset in the context file, e.g. the line offset in the current
  /// debugger frame.
  int get contextOffset => _contextOffset;

  /// The offset in the context file, e.g. the line offset in the current
  /// debugger frame.
  set contextOffset(int value) {
    assert(value != null);
    _contextOffset = value;
  }

  /// The runtime context variables that are potentially referenced in the
  /// code.
  List<RuntimeCompletionVariable> get variables => _variables;

  /// The runtime context variables that are potentially referenced in the
  /// code.
  set variables(List<RuntimeCompletionVariable> value) {
    assert(value != null);
    _variables = value;
  }

  /// The list of sub-expressions in the code for which the client wants to
  /// provide runtime types. It does not have to be the full list of
  /// expressions requested by the server, for missing expressions their static
  /// types will be used.
  ///
  /// When this field is omitted, the server will return completion suggestions
  /// only when there are no interesting sub-expressions in the given code. The
  /// client may provide an empty list, in this case the server will return
  /// completion suggestions.
  List<RuntimeCompletionExpression> get expressions => _expressions;

  /// The list of sub-expressions in the code for which the client wants to
  /// provide runtime types. It does not have to be the full list of
  /// expressions requested by the server, for missing expressions their static
  /// types will be used.
  ///
  /// When this field is omitted, the server will return completion suggestions
  /// only when there are no interesting sub-expressions in the given code. The
  /// client may provide an empty list, in this case the server will return
  /// completion suggestions.
  set expressions(List<RuntimeCompletionExpression> value) {
    _expressions = value;
  }

  ExecutionGetSuggestionsParams(String code, int offset, String contextFile,
      int contextOffset, List<RuntimeCompletionVariable> variables,
      {List<RuntimeCompletionExpression> expressions}) {
    this.code = code;
    this.offset = offset;
    this.contextFile = contextFile;
    this.contextOffset = contextOffset;
    this.variables = variables;
    this.expressions = expressions;
  }

  factory ExecutionGetSuggestionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String code;
      if (json.containsKey('code')) {
        code = jsonDecoder.decodeString(jsonPath + '.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      String contextFile;
      if (json.containsKey('contextFile')) {
        contextFile = jsonDecoder.decodeString(
            jsonPath + '.contextFile', json['contextFile']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contextFile');
      }
      int contextOffset;
      if (json.containsKey('contextOffset')) {
        contextOffset = jsonDecoder.decodeInt(
            jsonPath + '.contextOffset', json['contextOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'contextOffset');
      }
      List<RuntimeCompletionVariable> variables;
      if (json.containsKey('variables')) {
        variables = jsonDecoder.decodeList(
            jsonPath + '.variables',
            json['variables'],
            (String jsonPath, Object json) =>
                RuntimeCompletionVariable.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'variables');
      }
      List<RuntimeCompletionExpression> expressions;
      if (json.containsKey('expressions')) {
        expressions = jsonDecoder.decodeList(
            jsonPath + '.expressions',
            json['expressions'],
            (String jsonPath, Object json) =>
                RuntimeCompletionExpression.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return ExecutionGetSuggestionsParams(
          code, offset, contextFile, contextOffset, variables,
          expressions: expressions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.getSuggestions params', json);
    }
  }

  factory ExecutionGetSuggestionsParams.fromRequest(Request request) {
    return ExecutionGetSuggestionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['code'] = code;
    result['offset'] = offset;
    result['contextFile'] = contextFile;
    result['contextOffset'] = contextOffset;
    result['variables'] = variables
        .map((RuntimeCompletionVariable value) => value.toJson())
        .toList();
    if (expressions != null) {
      result['expressions'] = expressions
          .map((RuntimeCompletionExpression value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.getSuggestions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionGetSuggestionsParams) {
      return code == other.code &&
          offset == other.offset &&
          contextFile == other.contextFile &&
          contextOffset == other.contextOffset &&
          listEqual(
              variables,
              other.variables,
              (RuntimeCompletionVariable a, RuntimeCompletionVariable b) =>
                  a == b) &&
          listEqual(
              expressions,
              other.expressions,
              (RuntimeCompletionExpression a, RuntimeCompletionExpression b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, contextFile.hashCode);
    hash = JenkinsSmiHash.combine(hash, contextOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, variables.hashCode);
    hash = JenkinsSmiHash.combine(hash, expressions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.getSuggestions result
///
/// {
///   "suggestions": optional List<CompletionSuggestion>
///   "expressions": optional List<RuntimeCompletionExpression>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionGetSuggestionsResult implements ResponseResult {
  List<CompletionSuggestion> _suggestions;

  List<RuntimeCompletionExpression> _expressions;

  /// The completion suggestions. In contrast to usual completion request,
  /// suggestions for private elements also will be provided.
  ///
  /// If there are sub-expressions that can have different runtime types, and
  /// are considered to be safe to evaluate at runtime (e.g. getters), so using
  /// their actual runtime types can improve completion results, the server
  /// omits this field in the response, and instead will return the
  /// "expressions" field.
  List<CompletionSuggestion> get suggestions => _suggestions;

  /// The completion suggestions. In contrast to usual completion request,
  /// suggestions for private elements also will be provided.
  ///
  /// If there are sub-expressions that can have different runtime types, and
  /// are considered to be safe to evaluate at runtime (e.g. getters), so using
  /// their actual runtime types can improve completion results, the server
  /// omits this field in the response, and instead will return the
  /// "expressions" field.
  set suggestions(List<CompletionSuggestion> value) {
    _suggestions = value;
  }

  /// The list of sub-expressions in the code for which the server would like
  /// to know runtime types to provide better completion suggestions.
  ///
  /// This field is omitted the field "suggestions" is returned.
  List<RuntimeCompletionExpression> get expressions => _expressions;

  /// The list of sub-expressions in the code for which the server would like
  /// to know runtime types to provide better completion suggestions.
  ///
  /// This field is omitted the field "suggestions" is returned.
  set expressions(List<RuntimeCompletionExpression> value) {
    _expressions = value;
  }

  ExecutionGetSuggestionsResult(
      {List<CompletionSuggestion> suggestions,
      List<RuntimeCompletionExpression> expressions}) {
    this.suggestions = suggestions;
    this.expressions = expressions;
  }

  factory ExecutionGetSuggestionsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<CompletionSuggestion> suggestions;
      if (json.containsKey('suggestions')) {
        suggestions = jsonDecoder.decodeList(
            jsonPath + '.suggestions',
            json['suggestions'],
            (String jsonPath, Object json) =>
                CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      }
      List<RuntimeCompletionExpression> expressions;
      if (json.containsKey('expressions')) {
        expressions = jsonDecoder.decodeList(
            jsonPath + '.expressions',
            json['expressions'],
            (String jsonPath, Object json) =>
                RuntimeCompletionExpression.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return ExecutionGetSuggestionsResult(
          suggestions: suggestions, expressions: expressions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.getSuggestions result', json);
    }
  }

  factory ExecutionGetSuggestionsResult.fromResponse(Response response) {
    return ExecutionGetSuggestionsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (suggestions != null) {
      result['suggestions'] = suggestions
          .map((CompletionSuggestion value) => value.toJson())
          .toList();
    }
    if (expressions != null) {
      result['expressions'] = expressions
          .map((RuntimeCompletionExpression value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionGetSuggestionsResult) {
      return listEqual(suggestions, other.suggestions,
              (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          listEqual(
              expressions,
              other.expressions,
              (RuntimeCompletionExpression a, RuntimeCompletionExpression b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, suggestions.hashCode);
    hash = JenkinsSmiHash.combine(hash, expressions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.launchData params
///
/// {
///   "file": FilePath
///   "kind": optional ExecutableKind
///   "referencedFiles": optional List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionLaunchDataParams implements HasToJson {
  String _file;

  ExecutableKind _kind;

  List<String> _referencedFiles;

  /// The file for which launch data is being provided. This will either be a
  /// Dart library or an HTML file.
  String get file => _file;

  /// The file for which launch data is being provided. This will either be a
  /// Dart library or an HTML file.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The kind of the executable file. This field is omitted if the file is not
  /// a Dart file.
  ExecutableKind get kind => _kind;

  /// The kind of the executable file. This field is omitted if the file is not
  /// a Dart file.
  set kind(ExecutableKind value) {
    _kind = value;
  }

  /// A list of the Dart files that are referenced by the file. This field is
  /// omitted if the file is not an HTML file.
  List<String> get referencedFiles => _referencedFiles;

  /// A list of the Dart files that are referenced by the file. This field is
  /// omitted if the file is not an HTML file.
  set referencedFiles(List<String> value) {
    _referencedFiles = value;
  }

  ExecutionLaunchDataParams(String file,
      {ExecutableKind kind, List<String> referencedFiles}) {
    this.file = file;
    this.kind = kind;
    this.referencedFiles = referencedFiles;
  }

  factory ExecutionLaunchDataParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      ExecutableKind kind;
      if (json.containsKey('kind')) {
        kind = ExecutableKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      }
      List<String> referencedFiles;
      if (json.containsKey('referencedFiles')) {
        referencedFiles = jsonDecoder.decodeList(jsonPath + '.referencedFiles',
            json['referencedFiles'], jsonDecoder.decodeString);
      }
      return ExecutionLaunchDataParams(file,
          kind: kind, referencedFiles: referencedFiles);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'execution.launchData params', json);
    }
  }

  factory ExecutionLaunchDataParams.fromNotification(
      Notification notification) {
    return ExecutionLaunchDataParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    if (kind != null) {
      result['kind'] = kind.toJson();
    }
    if (referencedFiles != null) {
      result['referencedFiles'] = referencedFiles;
    }
    return result;
  }

  Notification toNotification() {
    return Notification('execution.launchData', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionLaunchDataParams) {
      return file == other.file &&
          kind == other.kind &&
          listEqual(referencedFiles, other.referencedFiles,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, referencedFiles.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.mapUri params
///
/// {
///   "id": ExecutionContextId
///   "file": optional FilePath
///   "uri": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionMapUriParams implements RequestParams {
  String _id;

  String _file;

  String _uri;

  /// The identifier of the execution context in which the URI is to be mapped.
  String get id => _id;

  /// The identifier of the execution context in which the URI is to be mapped.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  /// The path of the file to be mapped into a URI.
  String get file => _file;

  /// The path of the file to be mapped into a URI.
  set file(String value) {
    _file = value;
  }

  /// The URI to be mapped into a file path.
  String get uri => _uri;

  /// The URI to be mapped into a file path.
  set uri(String value) {
    _uri = value;
  }

  ExecutionMapUriParams(String id, {String file, String uri}) {
    this.id = id;
    this.file = file;
    this.uri = uri;
  }

  factory ExecutionMapUriParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      }
      String uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeString(jsonPath + '.uri', json['uri']);
      }
      return ExecutionMapUriParams(id, file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'execution.mapUri params', json);
    }
  }

  factory ExecutionMapUriParams.fromRequest(Request request) {
    return ExecutionMapUriParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    if (file != null) {
      result['file'] = file;
    }
    if (uri != null) {
      result['uri'] = uri;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.mapUri', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionMapUriParams) {
      return id == other.id && file == other.file && uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.mapUri result
///
/// {
///   "file": optional FilePath
///   "uri": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionMapUriResult implements ResponseResult {
  String _file;

  String _uri;

  /// The file to which the URI was mapped. This field is omitted if the uri
  /// field was not given in the request.
  String get file => _file;

  /// The file to which the URI was mapped. This field is omitted if the uri
  /// field was not given in the request.
  set file(String value) {
    _file = value;
  }

  /// The URI to which the file path was mapped. This field is omitted if the
  /// file field was not given in the request.
  String get uri => _uri;

  /// The URI to which the file path was mapped. This field is omitted if the
  /// file field was not given in the request.
  set uri(String value) {
    _uri = value;
  }

  ExecutionMapUriResult({String file, String uri}) {
    this.file = file;
    this.uri = uri;
  }

  factory ExecutionMapUriResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      }
      String uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeString(jsonPath + '.uri', json['uri']);
      }
      return ExecutionMapUriResult(file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'execution.mapUri result', json);
    }
  }

  factory ExecutionMapUriResult.fromResponse(Response response) {
    return ExecutionMapUriResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (file != null) {
      result['file'] = file;
    }
    if (uri != null) {
      result['uri'] = uri;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionMapUriResult) {
      return file == other.file && uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ExecutionService
///
/// enum {
///   LAUNCH_DATA
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionService implements Enum {
  static const ExecutionService LAUNCH_DATA = ExecutionService._('LAUNCH_DATA');

  /// A list containing all of the enum values that are defined.
  static const List<ExecutionService> VALUES = <ExecutionService>[LAUNCH_DATA];

  @override
  final String name;

  const ExecutionService._(this.name);

  factory ExecutionService(String name) {
    switch (name) {
      case 'LAUNCH_DATA':
        return LAUNCH_DATA;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ExecutionService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return ExecutionService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ExecutionService', json);
  }

  @override
  String toString() => 'ExecutionService.$name';

  String toJson() => name;
}

/// execution.setSubscriptions params
///
/// {
///   "subscriptions": List<ExecutionService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionSetSubscriptionsParams implements RequestParams {
  List<ExecutionService> _subscriptions;

  /// A list of the services being subscribed to.
  List<ExecutionService> get subscriptions => _subscriptions;

  /// A list of the services being subscribed to.
  set subscriptions(List<ExecutionService> value) {
    assert(value != null);
    _subscriptions = value;
  }

  ExecutionSetSubscriptionsParams(List<ExecutionService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory ExecutionSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<ExecutionService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + '.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object json) =>
                ExecutionService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return ExecutionSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'execution.setSubscriptions params', json);
    }
  }

  factory ExecutionSetSubscriptionsParams.fromRequest(Request request) {
    return ExecutionSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['subscriptions'] =
        subscriptions.map((ExecutionService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'execution.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionSetSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (ExecutionService a, ExecutionService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// execution.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class ExecutionSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is ExecutionSetSubscriptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 287678780;
  }
}

/// ExistingImport
///
/// {
///   "uri": int
///   "elements": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExistingImport implements HasToJson {
  int _uri;

  List<int> _elements;

  /// The URI of the imported library. It is an index in the strings field, in
  /// the enclosing ExistingImports and its ImportedElementSet object.
  int get uri => _uri;

  /// The URI of the imported library. It is an index in the strings field, in
  /// the enclosing ExistingImports and its ImportedElementSet object.
  set uri(int value) {
    assert(value != null);
    _uri = value;
  }

  /// The list of indexes of elements, in the enclosing ExistingImports object.
  List<int> get elements => _elements;

  /// The list of indexes of elements, in the enclosing ExistingImports object.
  set elements(List<int> value) {
    assert(value != null);
    _elements = value;
  }

  ExistingImport(int uri, List<int> elements) {
    this.uri = uri;
    this.elements = elements;
  }

  factory ExistingImport.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int uri;
      if (json.containsKey('uri')) {
        uri = jsonDecoder.decodeInt(jsonPath + '.uri', json['uri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'uri');
      }
      List<int> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            jsonPath + '.elements', json['elements'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      return ExistingImport(uri, elements);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ExistingImport', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['uri'] = uri;
    result['elements'] = elements;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExistingImport) {
      return uri == other.uri &&
          listEqual(elements, other.elements, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ExistingImports
///
/// {
///   "elements": ImportedElementSet
///   "imports": List<ExistingImport>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExistingImports implements HasToJson {
  ImportedElementSet _elements;

  List<ExistingImport> _imports;

  /// The set of all unique imported elements for all imports.
  ImportedElementSet get elements => _elements;

  /// The set of all unique imported elements for all imports.
  set elements(ImportedElementSet value) {
    assert(value != null);
    _elements = value;
  }

  /// The list of imports in the library.
  List<ExistingImport> get imports => _imports;

  /// The list of imports in the library.
  set imports(List<ExistingImport> value) {
    assert(value != null);
    _imports = value;
  }

  ExistingImports(ImportedElementSet elements, List<ExistingImport> imports) {
    this.elements = elements;
    this.imports = imports;
  }

  factory ExistingImports.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      ImportedElementSet elements;
      if (json.containsKey('elements')) {
        elements = ImportedElementSet.fromJson(
            jsonDecoder, jsonPath + '.elements', json['elements']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      List<ExistingImport> imports;
      if (json.containsKey('imports')) {
        imports = jsonDecoder.decodeList(
            jsonPath + '.imports',
            json['imports'],
            (String jsonPath, Object json) =>
                ExistingImport.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'imports');
      }
      return ExistingImports(elements, imports);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ExistingImports', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['elements'] = elements.toJson();
    result['imports'] =
        imports.map((ExistingImport value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExistingImports) {
      return elements == other.elements &&
          listEqual(imports, other.imports,
              (ExistingImport a, ExistingImport b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    hash = JenkinsSmiHash.combine(hash, imports.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// extractLocalVariable feedback
///
/// {
///   "coveringExpressionOffsets": optional List<int>
///   "coveringExpressionLengths": optional List<int>
///   "names": List<String>
///   "offsets": List<int>
///   "lengths": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractLocalVariableFeedback extends RefactoringFeedback {
  List<int> _coveringExpressionOffsets;

  List<int> _coveringExpressionLengths;

  List<String> _names;

  List<int> _offsets;

  List<int> _lengths;

  /// The offsets of the expressions that cover the specified selection, from
  /// the down most to the up most.
  List<int> get coveringExpressionOffsets => _coveringExpressionOffsets;

  /// The offsets of the expressions that cover the specified selection, from
  /// the down most to the up most.
  set coveringExpressionOffsets(List<int> value) {
    _coveringExpressionOffsets = value;
  }

  /// The lengths of the expressions that cover the specified selection, from
  /// the down most to the up most.
  List<int> get coveringExpressionLengths => _coveringExpressionLengths;

  /// The lengths of the expressions that cover the specified selection, from
  /// the down most to the up most.
  set coveringExpressionLengths(List<int> value) {
    _coveringExpressionLengths = value;
  }

  /// The proposed names for the local variable.
  List<String> get names => _names;

  /// The proposed names for the local variable.
  set names(List<String> value) {
    assert(value != null);
    _names = value;
  }

  /// The offsets of the expressions that would be replaced by a reference to
  /// the variable.
  List<int> get offsets => _offsets;

  /// The offsets of the expressions that would be replaced by a reference to
  /// the variable.
  set offsets(List<int> value) {
    assert(value != null);
    _offsets = value;
  }

  /// The lengths of the expressions that would be replaced by a reference to
  /// the variable. The lengths correspond to the offsets. In other words, for
  /// a given expression, if the offset of that expression is offsets[i], then
  /// the length of that expression is lengths[i].
  List<int> get lengths => _lengths;

  /// The lengths of the expressions that would be replaced by a reference to
  /// the variable. The lengths correspond to the offsets. In other words, for
  /// a given expression, if the offset of that expression is offsets[i], then
  /// the length of that expression is lengths[i].
  set lengths(List<int> value) {
    assert(value != null);
    _lengths = value;
  }

  ExtractLocalVariableFeedback(
      List<String> names, List<int> offsets, List<int> lengths,
      {List<int> coveringExpressionOffsets,
      List<int> coveringExpressionLengths}) {
    this.coveringExpressionOffsets = coveringExpressionOffsets;
    this.coveringExpressionLengths = coveringExpressionLengths;
    this.names = names;
    this.offsets = offsets;
    this.lengths = lengths;
  }

  factory ExtractLocalVariableFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<int> coveringExpressionOffsets;
      if (json.containsKey('coveringExpressionOffsets')) {
        coveringExpressionOffsets = jsonDecoder.decodeList(
            jsonPath + '.coveringExpressionOffsets',
            json['coveringExpressionOffsets'],
            jsonDecoder.decodeInt);
      }
      List<int> coveringExpressionLengths;
      if (json.containsKey('coveringExpressionLengths')) {
        coveringExpressionLengths = jsonDecoder.decodeList(
            jsonPath + '.coveringExpressionLengths',
            json['coveringExpressionLengths'],
            jsonDecoder.decodeInt);
      }
      List<String> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
            jsonPath + '.names', json['names'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
            jsonPath + '.offsets', json['offsets'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      List<int> lengths;
      if (json.containsKey('lengths')) {
        lengths = jsonDecoder.decodeList(
            jsonPath + '.lengths', json['lengths'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lengths');
      }
      return ExtractLocalVariableFeedback(names, offsets, lengths,
          coveringExpressionOffsets: coveringExpressionOffsets,
          coveringExpressionLengths: coveringExpressionLengths);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'extractLocalVariable feedback', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (coveringExpressionOffsets != null) {
      result['coveringExpressionOffsets'] = coveringExpressionOffsets;
    }
    if (coveringExpressionLengths != null) {
      result['coveringExpressionLengths'] = coveringExpressionLengths;
    }
    result['names'] = names;
    result['offsets'] = offsets;
    result['lengths'] = lengths;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableFeedback) {
      return listEqual(coveringExpressionOffsets,
              other.coveringExpressionOffsets, (int a, int b) => a == b) &&
          listEqual(coveringExpressionLengths, other.coveringExpressionLengths,
              (int a, int b) => a == b) &&
          listEqual(names, other.names, (String a, String b) => a == b) &&
          listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          listEqual(lengths, other.lengths, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, coveringExpressionOffsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, coveringExpressionLengths.hashCode);
    hash = JenkinsSmiHash.combine(hash, names.hashCode);
    hash = JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, lengths.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// extractLocalVariable options
///
/// {
///   "name": String
///   "extractAll": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractLocalVariableOptions extends RefactoringOptions {
  String _name;

  bool _extractAll;

  /// The name that the local variable should be given.
  String get name => _name;

  /// The name that the local variable should be given.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// True if all occurrences of the expression within the scope in which the
  /// variable will be defined should be replaced by a reference to the local
  /// variable. The expression used to initiate the refactoring will always be
  /// replaced.
  bool get extractAll => _extractAll;

  /// True if all occurrences of the expression within the scope in which the
  /// variable will be defined should be replaced by a reference to the local
  /// variable. The expression used to initiate the refactoring will always be
  /// replaced.
  set extractAll(bool value) {
    assert(value != null);
    _extractAll = value;
  }

  ExtractLocalVariableOptions(String name, bool extractAll) {
    this.name = name;
    this.extractAll = extractAll;
  }

  factory ExtractLocalVariableOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      bool extractAll;
      if (json.containsKey('extractAll')) {
        extractAll = jsonDecoder.decodeBool(
            jsonPath + '.extractAll', json['extractAll']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'extractAll');
      }
      return ExtractLocalVariableOptions(name, extractAll);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'extractLocalVariable options', json);
    }
  }

  factory ExtractLocalVariableOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return ExtractLocalVariableOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['extractAll'] = extractAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableOptions) {
      return name == other.name && extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, extractAll.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// extractMethod feedback
///
/// {
///   "offset": int
///   "length": int
///   "returnType": String
///   "names": List<String>
///   "canCreateGetter": bool
///   "parameters": List<RefactoringMethodParameter>
///   "offsets": List<int>
///   "lengths": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractMethodFeedback extends RefactoringFeedback {
  int _offset;

  int _length;

  String _returnType;

  List<String> _names;

  bool _canCreateGetter;

  List<RefactoringMethodParameter> _parameters;

  List<int> _offsets;

  List<int> _lengths;

  /// The offset to the beginning of the expression or statements that will be
  /// extracted.
  int get offset => _offset;

  /// The offset to the beginning of the expression or statements that will be
  /// extracted.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the expression or statements that will be extracted.
  int get length => _length;

  /// The length of the expression or statements that will be extracted.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The proposed return type for the method. If the returned element does not
  /// have a declared return type, this field will contain an empty string.
  String get returnType => _returnType;

  /// The proposed return type for the method. If the returned element does not
  /// have a declared return type, this field will contain an empty string.
  set returnType(String value) {
    assert(value != null);
    _returnType = value;
  }

  /// The proposed names for the method.
  List<String> get names => _names;

  /// The proposed names for the method.
  set names(List<String> value) {
    assert(value != null);
    _names = value;
  }

  /// True if a getter could be created rather than a method.
  bool get canCreateGetter => _canCreateGetter;

  /// True if a getter could be created rather than a method.
  set canCreateGetter(bool value) {
    assert(value != null);
    _canCreateGetter = value;
  }

  /// The proposed parameters for the method.
  List<RefactoringMethodParameter> get parameters => _parameters;

  /// The proposed parameters for the method.
  set parameters(List<RefactoringMethodParameter> value) {
    assert(value != null);
    _parameters = value;
  }

  /// The offsets of the expressions or statements that would be replaced by an
  /// invocation of the method.
  List<int> get offsets => _offsets;

  /// The offsets of the expressions or statements that would be replaced by an
  /// invocation of the method.
  set offsets(List<int> value) {
    assert(value != null);
    _offsets = value;
  }

  /// The lengths of the expressions or statements that would be replaced by an
  /// invocation of the method. The lengths correspond to the offsets. In other
  /// words, for a given expression (or block of statements), if the offset of
  /// that expression is offsets[i], then the length of that expression is
  /// lengths[i].
  List<int> get lengths => _lengths;

  /// The lengths of the expressions or statements that would be replaced by an
  /// invocation of the method. The lengths correspond to the offsets. In other
  /// words, for a given expression (or block of statements), if the offset of
  /// that expression is offsets[i], then the length of that expression is
  /// lengths[i].
  set lengths(List<int> value) {
    assert(value != null);
    _lengths = value;
  }

  ExtractMethodFeedback(
      int offset,
      int length,
      String returnType,
      List<String> names,
      bool canCreateGetter,
      List<RefactoringMethodParameter> parameters,
      List<int> offsets,
      List<int> lengths) {
    this.offset = offset;
    this.length = length;
    this.returnType = returnType;
    this.names = names;
    this.canCreateGetter = canCreateGetter;
    this.parameters = parameters;
    this.offsets = offsets;
    this.lengths = lengths;
  }

  factory ExtractMethodFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
            jsonPath + '.returnType', json['returnType']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'returnType');
      }
      List<String> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
            jsonPath + '.names', json['names'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      bool canCreateGetter;
      if (json.containsKey('canCreateGetter')) {
        canCreateGetter = jsonDecoder.decodeBool(
            jsonPath + '.canCreateGetter', json['canCreateGetter']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'canCreateGetter');
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeList(
            jsonPath + '.parameters',
            json['parameters'],
            (String jsonPath, Object json) =>
                RefactoringMethodParameter.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      List<int> offsets;
      if (json.containsKey('offsets')) {
        offsets = jsonDecoder.decodeList(
            jsonPath + '.offsets', json['offsets'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offsets');
      }
      List<int> lengths;
      if (json.containsKey('lengths')) {
        lengths = jsonDecoder.decodeList(
            jsonPath + '.lengths', json['lengths'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lengths');
      }
      return ExtractMethodFeedback(offset, length, returnType, names,
          canCreateGetter, parameters, offsets, lengths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractMethod feedback', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    result['returnType'] = returnType;
    result['names'] = names;
    result['canCreateGetter'] = canCreateGetter;
    result['parameters'] = parameters
        .map((RefactoringMethodParameter value) => value.toJson())
        .toList();
    result['offsets'] = offsets;
    result['lengths'] = lengths;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractMethodFeedback) {
      return offset == other.offset &&
          length == other.length &&
          returnType == other.returnType &&
          listEqual(names, other.names, (String a, String b) => a == b) &&
          canCreateGetter == other.canCreateGetter &&
          listEqual(
              parameters,
              other.parameters,
              (RefactoringMethodParameter a, RefactoringMethodParameter b) =>
                  a == b) &&
          listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          listEqual(lengths, other.lengths, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, names.hashCode);
    hash = JenkinsSmiHash.combine(hash, canCreateGetter.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, lengths.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// extractMethod options
///
/// {
///   "returnType": String
///   "createGetter": bool
///   "name": String
///   "parameters": List<RefactoringMethodParameter>
///   "extractAll": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractMethodOptions extends RefactoringOptions {
  String _returnType;

  bool _createGetter;

  String _name;

  List<RefactoringMethodParameter> _parameters;

  bool _extractAll;

  /// The return type that should be defined for the method.
  String get returnType => _returnType;

  /// The return type that should be defined for the method.
  set returnType(String value) {
    assert(value != null);
    _returnType = value;
  }

  /// True if a getter should be created rather than a method. It is an error
  /// if this field is true and the list of parameters is non-empty.
  bool get createGetter => _createGetter;

  /// True if a getter should be created rather than a method. It is an error
  /// if this field is true and the list of parameters is non-empty.
  set createGetter(bool value) {
    assert(value != null);
    _createGetter = value;
  }

  /// The name that the method should be given.
  String get name => _name;

  /// The name that the method should be given.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The parameters that should be defined for the method.
  ///
  /// It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
  /// parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
  /// NAMED parameter.
  ///
  /// - To change the order and/or update proposed parameters, add parameters
  ///   with the same identifiers as proposed.
  /// - To add new parameters, omit their identifier.
  /// - To remove some parameters, omit them in this list.
  List<RefactoringMethodParameter> get parameters => _parameters;

  /// The parameters that should be defined for the method.
  ///
  /// It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
  /// parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
  /// NAMED parameter.
  ///
  /// - To change the order and/or update proposed parameters, add parameters
  ///   with the same identifiers as proposed.
  /// - To add new parameters, omit their identifier.
  /// - To remove some parameters, omit them in this list.
  set parameters(List<RefactoringMethodParameter> value) {
    assert(value != null);
    _parameters = value;
  }

  /// True if all occurrences of the expression or statements should be
  /// replaced by an invocation of the method. The expression or statements
  /// used to initiate the refactoring will always be replaced.
  bool get extractAll => _extractAll;

  /// True if all occurrences of the expression or statements should be
  /// replaced by an invocation of the method. The expression or statements
  /// used to initiate the refactoring will always be replaced.
  set extractAll(bool value) {
    assert(value != null);
    _extractAll = value;
  }

  ExtractMethodOptions(String returnType, bool createGetter, String name,
      List<RefactoringMethodParameter> parameters, bool extractAll) {
    this.returnType = returnType;
    this.createGetter = createGetter;
    this.name = name;
    this.parameters = parameters;
    this.extractAll = extractAll;
  }

  factory ExtractMethodOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String returnType;
      if (json.containsKey('returnType')) {
        returnType = jsonDecoder.decodeString(
            jsonPath + '.returnType', json['returnType']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'returnType');
      }
      bool createGetter;
      if (json.containsKey('createGetter')) {
        createGetter = jsonDecoder.decodeBool(
            jsonPath + '.createGetter', json['createGetter']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'createGetter');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey('parameters')) {
        parameters = jsonDecoder.decodeList(
            jsonPath + '.parameters',
            json['parameters'],
            (String jsonPath, Object json) =>
                RefactoringMethodParameter.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'parameters');
      }
      bool extractAll;
      if (json.containsKey('extractAll')) {
        extractAll = jsonDecoder.decodeBool(
            jsonPath + '.extractAll', json['extractAll']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'extractAll');
      }
      return ExtractMethodOptions(
          returnType, createGetter, name, parameters, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractMethod options', json);
    }
  }

  factory ExtractMethodOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return ExtractMethodOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['returnType'] = returnType;
    result['createGetter'] = createGetter;
    result['name'] = name;
    result['parameters'] = parameters
        .map((RefactoringMethodParameter value) => value.toJson())
        .toList();
    result['extractAll'] = extractAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractMethodOptions) {
      return returnType == other.returnType &&
          createGetter == other.createGetter &&
          name == other.name &&
          listEqual(
              parameters,
              other.parameters,
              (RefactoringMethodParameter a, RefactoringMethodParameter b) =>
                  a == b) &&
          extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, createGetter.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, extractAll.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// extractWidget feedback
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractWidgetFeedback extends RefactoringFeedback {
  ExtractWidgetFeedback();

  factory ExtractWidgetFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      return ExtractWidgetFeedback();
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractWidget feedback', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractWidgetFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/// extractWidget options
///
/// {
///   "name": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ExtractWidgetOptions extends RefactoringOptions {
  String _name;

  /// The name that the widget class should be given.
  String get name => _name;

  /// The name that the widget class should be given.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  ExtractWidgetOptions(String name) {
    this.name = name;
  }

  factory ExtractWidgetOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      return ExtractWidgetOptions(name);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'extractWidget options', json);
    }
  }

  factory ExtractWidgetOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return ExtractWidgetOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractWidgetOptions) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FileKind
///
/// enum {
///   LIBRARY
///   PART
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FileKind implements Enum {
  static const FileKind LIBRARY = FileKind._('LIBRARY');

  static const FileKind PART = FileKind._('PART');

  /// A list containing all of the enum values that are defined.
  static const List<FileKind> VALUES = <FileKind>[LIBRARY, PART];

  @override
  final String name;

  const FileKind._(this.name);

  factory FileKind(String name) {
    switch (name) {
      case 'LIBRARY':
        return LIBRARY;
      case 'PART':
        return PART;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FileKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return FileKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FileKind', json);
  }

  @override
  String toString() => 'FileKind.$name';

  String toJson() => name;
}

/// flutter.getWidgetDescription params
///
/// {
///   "file": FilePath
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterGetWidgetDescriptionParams implements RequestParams {
  String _file;

  int _offset;

  /// The file where the widget instance is created.
  String get file => _file;

  /// The file where the widget instance is created.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset in the file where the widget instance is created.
  int get offset => _offset;

  /// The offset in the file where the widget instance is created.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  FlutterGetWidgetDescriptionParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory FlutterGetWidgetDescriptionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return FlutterGetWidgetDescriptionParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.getWidgetDescription params', json);
    }
  }

  factory FlutterGetWidgetDescriptionParams.fromRequest(Request request) {
    return FlutterGetWidgetDescriptionParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'flutter.getWidgetDescription', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterGetWidgetDescriptionParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// flutter.getWidgetDescription result
///
/// {
///   "properties": List<FlutterWidgetProperty>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterGetWidgetDescriptionResult implements ResponseResult {
  List<FlutterWidgetProperty> _properties;

  /// The list of properties of the widget. Some of the properties might be
  /// read only, when their editor is not set. This might be because they have
  /// type that we don't know how to edit, or for compound properties that work
  /// as containers for sub-properties.
  List<FlutterWidgetProperty> get properties => _properties;

  /// The list of properties of the widget. Some of the properties might be
  /// read only, when their editor is not set. This might be because they have
  /// type that we don't know how to edit, or for compound properties that work
  /// as containers for sub-properties.
  set properties(List<FlutterWidgetProperty> value) {
    assert(value != null);
    _properties = value;
  }

  FlutterGetWidgetDescriptionResult(List<FlutterWidgetProperty> properties) {
    this.properties = properties;
  }

  factory FlutterGetWidgetDescriptionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<FlutterWidgetProperty> properties;
      if (json.containsKey('properties')) {
        properties = jsonDecoder.decodeList(
            jsonPath + '.properties',
            json['properties'],
            (String jsonPath, Object json) =>
                FlutterWidgetProperty.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'properties');
      }
      return FlutterGetWidgetDescriptionResult(properties);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.getWidgetDescription result', json);
    }
  }

  factory FlutterGetWidgetDescriptionResult.fromResponse(Response response) {
    return FlutterGetWidgetDescriptionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['properties'] = properties
        .map((FlutterWidgetProperty value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterGetWidgetDescriptionResult) {
      return listEqual(properties, other.properties,
          (FlutterWidgetProperty a, FlutterWidgetProperty b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, properties.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterOutline
///
/// {
///   "kind": FlutterOutlineKind
///   "offset": int
///   "length": int
///   "codeOffset": int
///   "codeLength": int
///   "label": optional String
///   "dartElement": optional Element
///   "attributes": optional List<FlutterOutlineAttribute>
///   "className": optional String
///   "parentAssociationLabel": optional String
///   "variableName": optional String
///   "children": optional List<FlutterOutline>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutline implements HasToJson {
  FlutterOutlineKind _kind;

  int _offset;

  int _length;

  int _codeOffset;

  int _codeLength;

  String _label;

  Element _dartElement;

  List<FlutterOutlineAttribute> _attributes;

  String _className;

  String _parentAssociationLabel;

  String _variableName;

  List<FlutterOutline> _children;

  /// The kind of the node.
  FlutterOutlineKind get kind => _kind;

  /// The kind of the node.
  set kind(FlutterOutlineKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The offset of the first character of the element. This is different than
  /// the offset in the Element, which is the offset of the name of the
  /// element. It can be used, for example, to map locations in the file back
  /// to an outline.
  int get offset => _offset;

  /// The offset of the first character of the element. This is different than
  /// the offset in the Element, which is the offset of the name of the
  /// element. It can be used, for example, to map locations in the file back
  /// to an outline.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the element.
  int get length => _length;

  /// The length of the element.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The offset of the first character of the element code, which is neither
  /// documentation, nor annotation.
  int get codeOffset => _codeOffset;

  /// The offset of the first character of the element code, which is neither
  /// documentation, nor annotation.
  set codeOffset(int value) {
    assert(value != null);
    _codeOffset = value;
  }

  /// The length of the element code.
  int get codeLength => _codeLength;

  /// The length of the element code.
  set codeLength(int value) {
    assert(value != null);
    _codeLength = value;
  }

  /// The text label of the node children of the node. It is provided for any
  /// FlutterOutlineKind.GENERIC node, where better information is not
  /// available.
  String get label => _label;

  /// The text label of the node children of the node. It is provided for any
  /// FlutterOutlineKind.GENERIC node, where better information is not
  /// available.
  set label(String value) {
    _label = value;
  }

  /// If this node is a Dart element, the description of it; omitted otherwise.
  Element get dartElement => _dartElement;

  /// If this node is a Dart element, the description of it; omitted otherwise.
  set dartElement(Element value) {
    _dartElement = value;
  }

  /// Additional attributes for this node, which might be interesting to
  /// display on the client. These attributes are usually arguments for the
  /// instance creation or the invocation that created the widget.
  List<FlutterOutlineAttribute> get attributes => _attributes;

  /// Additional attributes for this node, which might be interesting to
  /// display on the client. These attributes are usually arguments for the
  /// instance creation or the invocation that created the widget.
  set attributes(List<FlutterOutlineAttribute> value) {
    _attributes = value;
  }

  /// If the node creates a new class instance, or a reference to an instance,
  /// this field has the name of the class.
  String get className => _className;

  /// If the node creates a new class instance, or a reference to an instance,
  /// this field has the name of the class.
  set className(String value) {
    _className = value;
  }

  /// A short text description how this node is associated with the parent
  /// node. For example "appBar" or "body" in Scaffold.
  String get parentAssociationLabel => _parentAssociationLabel;

  /// A short text description how this node is associated with the parent
  /// node. For example "appBar" or "body" in Scaffold.
  set parentAssociationLabel(String value) {
    _parentAssociationLabel = value;
  }

  /// If FlutterOutlineKind.VARIABLE, the name of the variable.
  String get variableName => _variableName;

  /// If FlutterOutlineKind.VARIABLE, the name of the variable.
  set variableName(String value) {
    _variableName = value;
  }

  /// The children of the node. The field will be omitted if the node has no
  /// children.
  List<FlutterOutline> get children => _children;

  /// The children of the node. The field will be omitted if the node has no
  /// children.
  set children(List<FlutterOutline> value) {
    _children = value;
  }

  FlutterOutline(FlutterOutlineKind kind, int offset, int length,
      int codeOffset, int codeLength,
      {String label,
      Element dartElement,
      List<FlutterOutlineAttribute> attributes,
      String className,
      String parentAssociationLabel,
      String variableName,
      List<FlutterOutline> children}) {
    this.kind = kind;
    this.offset = offset;
    this.length = length;
    this.codeOffset = codeOffset;
    this.codeLength = codeLength;
    this.label = label;
    this.dartElement = dartElement;
    this.attributes = attributes;
    this.className = className;
    this.parentAssociationLabel = parentAssociationLabel;
    this.variableName = variableName;
    this.children = children;
  }

  factory FlutterOutline.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      FlutterOutlineKind kind;
      if (json.containsKey('kind')) {
        kind = FlutterOutlineKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      int codeOffset;
      if (json.containsKey('codeOffset')) {
        codeOffset =
            jsonDecoder.decodeInt(jsonPath + '.codeOffset', json['codeOffset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeOffset');
      }
      int codeLength;
      if (json.containsKey('codeLength')) {
        codeLength =
            jsonDecoder.decodeInt(jsonPath + '.codeLength', json['codeLength']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'codeLength');
      }
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString(jsonPath + '.label', json['label']);
      }
      Element dartElement;
      if (json.containsKey('dartElement')) {
        dartElement = Element.fromJson(
            jsonDecoder, jsonPath + '.dartElement', json['dartElement']);
      }
      List<FlutterOutlineAttribute> attributes;
      if (json.containsKey('attributes')) {
        attributes = jsonDecoder.decodeList(
            jsonPath + '.attributes',
            json['attributes'],
            (String jsonPath, Object json) =>
                FlutterOutlineAttribute.fromJson(jsonDecoder, jsonPath, json));
      }
      String className;
      if (json.containsKey('className')) {
        className = jsonDecoder.decodeString(
            jsonPath + '.className', json['className']);
      }
      String parentAssociationLabel;
      if (json.containsKey('parentAssociationLabel')) {
        parentAssociationLabel = jsonDecoder.decodeString(
            jsonPath + '.parentAssociationLabel',
            json['parentAssociationLabel']);
      }
      String variableName;
      if (json.containsKey('variableName')) {
        variableName = jsonDecoder.decodeString(
            jsonPath + '.variableName', json['variableName']);
      }
      List<FlutterOutline> children;
      if (json.containsKey('children')) {
        children = jsonDecoder.decodeList(
            jsonPath + '.children',
            json['children'],
            (String jsonPath, Object json) =>
                FlutterOutline.fromJson(jsonDecoder, jsonPath, json));
      }
      return FlutterOutline(kind, offset, length, codeOffset, codeLength,
          label: label,
          dartElement: dartElement,
          attributes: attributes,
          className: className,
          parentAssociationLabel: parentAssociationLabel,
          variableName: variableName,
          children: children);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterOutline', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    result['offset'] = offset;
    result['length'] = length;
    result['codeOffset'] = codeOffset;
    result['codeLength'] = codeLength;
    if (label != null) {
      result['label'] = label;
    }
    if (dartElement != null) {
      result['dartElement'] = dartElement.toJson();
    }
    if (attributes != null) {
      result['attributes'] = attributes
          .map((FlutterOutlineAttribute value) => value.toJson())
          .toList();
    }
    if (className != null) {
      result['className'] = className;
    }
    if (parentAssociationLabel != null) {
      result['parentAssociationLabel'] = parentAssociationLabel;
    }
    if (variableName != null) {
      result['variableName'] = variableName;
    }
    if (children != null) {
      result['children'] =
          children.map((FlutterOutline value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterOutline) {
      return kind == other.kind &&
          offset == other.offset &&
          length == other.length &&
          codeOffset == other.codeOffset &&
          codeLength == other.codeLength &&
          label == other.label &&
          dartElement == other.dartElement &&
          listEqual(
              attributes,
              other.attributes,
              (FlutterOutlineAttribute a, FlutterOutlineAttribute b) =>
                  a == b) &&
          className == other.className &&
          parentAssociationLabel == other.parentAssociationLabel &&
          variableName == other.variableName &&
          listEqual(children, other.children,
              (FlutterOutline a, FlutterOutline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, dartElement.hashCode);
    hash = JenkinsSmiHash.combine(hash, attributes.hashCode);
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    hash = JenkinsSmiHash.combine(hash, parentAssociationLabel.hashCode);
    hash = JenkinsSmiHash.combine(hash, variableName.hashCode);
    hash = JenkinsSmiHash.combine(hash, children.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterOutlineAttribute
///
/// {
///   "name": String
///   "label": String
///   "literalValueBoolean": optional bool
///   "literalValueInteger": optional int
///   "literalValueString": optional String
///   "nameLocation": optional Location
///   "valueLocation": optional Location
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutlineAttribute implements HasToJson {
  String _name;

  String _label;

  bool _literalValueBoolean;

  int _literalValueInteger;

  String _literalValueString;

  Location _nameLocation;

  Location _valueLocation;

  /// The name of the attribute.
  String get name => _name;

  /// The name of the attribute.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The label of the attribute value, usually the Dart code. It might be
  /// quite long, the client should abbreviate as needed.
  String get label => _label;

  /// The label of the attribute value, usually the Dart code. It might be
  /// quite long, the client should abbreviate as needed.
  set label(String value) {
    assert(value != null);
    _label = value;
  }

  /// The boolean literal value of the attribute. This field is absent if the
  /// value is not a boolean literal.
  bool get literalValueBoolean => _literalValueBoolean;

  /// The boolean literal value of the attribute. This field is absent if the
  /// value is not a boolean literal.
  set literalValueBoolean(bool value) {
    _literalValueBoolean = value;
  }

  /// The integer literal value of the attribute. This field is absent if the
  /// value is not an integer literal.
  int get literalValueInteger => _literalValueInteger;

  /// The integer literal value of the attribute. This field is absent if the
  /// value is not an integer literal.
  set literalValueInteger(int value) {
    _literalValueInteger = value;
  }

  /// The string literal value of the attribute. This field is absent if the
  /// value is not a string literal.
  String get literalValueString => _literalValueString;

  /// The string literal value of the attribute. This field is absent if the
  /// value is not a string literal.
  set literalValueString(String value) {
    _literalValueString = value;
  }

  /// If the attribute is a named argument, the location of the name, without
  /// the colon.
  Location get nameLocation => _nameLocation;

  /// If the attribute is a named argument, the location of the name, without
  /// the colon.
  set nameLocation(Location value) {
    _nameLocation = value;
  }

  /// The location of the value.
  ///
  /// This field is always available, but marked optional for backward
  /// compatibility between new clients with older servers.
  Location get valueLocation => _valueLocation;

  /// The location of the value.
  ///
  /// This field is always available, but marked optional for backward
  /// compatibility between new clients with older servers.
  set valueLocation(Location value) {
    _valueLocation = value;
  }

  FlutterOutlineAttribute(String name, String label,
      {bool literalValueBoolean,
      int literalValueInteger,
      String literalValueString,
      Location nameLocation,
      Location valueLocation}) {
    this.name = name;
    this.label = label;
    this.literalValueBoolean = literalValueBoolean;
    this.literalValueInteger = literalValueInteger;
    this.literalValueString = literalValueString;
    this.nameLocation = nameLocation;
    this.valueLocation = valueLocation;
  }

  factory FlutterOutlineAttribute.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String label;
      if (json.containsKey('label')) {
        label = jsonDecoder.decodeString(jsonPath + '.label', json['label']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'label');
      }
      bool literalValueBoolean;
      if (json.containsKey('literalValueBoolean')) {
        literalValueBoolean = jsonDecoder.decodeBool(
            jsonPath + '.literalValueBoolean', json['literalValueBoolean']);
      }
      int literalValueInteger;
      if (json.containsKey('literalValueInteger')) {
        literalValueInteger = jsonDecoder.decodeInt(
            jsonPath + '.literalValueInteger', json['literalValueInteger']);
      }
      String literalValueString;
      if (json.containsKey('literalValueString')) {
        literalValueString = jsonDecoder.decodeString(
            jsonPath + '.literalValueString', json['literalValueString']);
      }
      Location nameLocation;
      if (json.containsKey('nameLocation')) {
        nameLocation = Location.fromJson(
            jsonDecoder, jsonPath + '.nameLocation', json['nameLocation']);
      }
      Location valueLocation;
      if (json.containsKey('valueLocation')) {
        valueLocation = Location.fromJson(
            jsonDecoder, jsonPath + '.valueLocation', json['valueLocation']);
      }
      return FlutterOutlineAttribute(name, label,
          literalValueBoolean: literalValueBoolean,
          literalValueInteger: literalValueInteger,
          literalValueString: literalValueString,
          nameLocation: nameLocation,
          valueLocation: valueLocation);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterOutlineAttribute', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['label'] = label;
    if (literalValueBoolean != null) {
      result['literalValueBoolean'] = literalValueBoolean;
    }
    if (literalValueInteger != null) {
      result['literalValueInteger'] = literalValueInteger;
    }
    if (literalValueString != null) {
      result['literalValueString'] = literalValueString;
    }
    if (nameLocation != null) {
      result['nameLocation'] = nameLocation.toJson();
    }
    if (valueLocation != null) {
      result['valueLocation'] = valueLocation.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterOutlineAttribute) {
      return name == other.name &&
          label == other.label &&
          literalValueBoolean == other.literalValueBoolean &&
          literalValueInteger == other.literalValueInteger &&
          literalValueString == other.literalValueString &&
          nameLocation == other.nameLocation &&
          valueLocation == other.valueLocation;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, literalValueBoolean.hashCode);
    hash = JenkinsSmiHash.combine(hash, literalValueInteger.hashCode);
    hash = JenkinsSmiHash.combine(hash, literalValueString.hashCode);
    hash = JenkinsSmiHash.combine(hash, nameLocation.hashCode);
    hash = JenkinsSmiHash.combine(hash, valueLocation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterOutlineKind
///
/// enum {
///   DART_ELEMENT
///   GENERIC
///   NEW_INSTANCE
///   INVOCATION
///   VARIABLE
///   PLACEHOLDER
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutlineKind implements Enum {
  /// A dart element declaration.
  static const FlutterOutlineKind DART_ELEMENT =
      FlutterOutlineKind._('DART_ELEMENT');

  /// A generic Flutter element, without additional information.
  static const FlutterOutlineKind GENERIC = FlutterOutlineKind._('GENERIC');

  /// A new instance creation.
  static const FlutterOutlineKind NEW_INSTANCE =
      FlutterOutlineKind._('NEW_INSTANCE');

  /// An invocation of a method, a top-level function, a function expression,
  /// etc.
  static const FlutterOutlineKind INVOCATION =
      FlutterOutlineKind._('INVOCATION');

  /// A reference to a local variable, or a field.
  static const FlutterOutlineKind VARIABLE = FlutterOutlineKind._('VARIABLE');

  /// The parent node has a required Widget. The node works as a placeholder
  /// child to drop a new Widget to.
  static const FlutterOutlineKind PLACEHOLDER =
      FlutterOutlineKind._('PLACEHOLDER');

  /// A list containing all of the enum values that are defined.
  static const List<FlutterOutlineKind> VALUES = <FlutterOutlineKind>[
    DART_ELEMENT,
    GENERIC,
    NEW_INSTANCE,
    INVOCATION,
    VARIABLE,
    PLACEHOLDER
  ];

  @override
  final String name;

  const FlutterOutlineKind._(this.name);

  factory FlutterOutlineKind(String name) {
    switch (name) {
      case 'DART_ELEMENT':
        return DART_ELEMENT;
      case 'GENERIC':
        return GENERIC;
      case 'NEW_INSTANCE':
        return NEW_INSTANCE;
      case 'INVOCATION':
        return INVOCATION;
      case 'VARIABLE':
        return VARIABLE;
      case 'PLACEHOLDER':
        return PLACEHOLDER;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FlutterOutlineKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return FlutterOutlineKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FlutterOutlineKind', json);
  }

  @override
  String toString() => 'FlutterOutlineKind.$name';

  String toJson() => name;
}

/// flutter.outline params
///
/// {
///   "file": FilePath
///   "outline": FlutterOutline
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterOutlineParams implements HasToJson {
  String _file;

  FlutterOutline _outline;

  /// The file with which the outline is associated.
  String get file => _file;

  /// The file with which the outline is associated.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The outline associated with the file.
  FlutterOutline get outline => _outline;

  /// The outline associated with the file.
  set outline(FlutterOutline value) {
    assert(value != null);
    _outline = value;
  }

  FlutterOutlineParams(String file, FlutterOutline outline) {
    this.file = file;
    this.outline = outline;
  }

  factory FlutterOutlineParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      FlutterOutline outline;
      if (json.containsKey('outline')) {
        outline = FlutterOutline.fromJson(
            jsonDecoder, jsonPath + '.outline', json['outline']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'outline');
      }
      return FlutterOutlineParams(file, outline);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'flutter.outline params', json);
    }
  }

  factory FlutterOutlineParams.fromNotification(Notification notification) {
    return FlutterOutlineParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['outline'] = outline.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('flutter.outline', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterOutlineParams) {
      return file == other.file && outline == other.outline;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, outline.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterService
///
/// enum {
///   OUTLINE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterService implements Enum {
  static const FlutterService OUTLINE = FlutterService._('OUTLINE');

  /// A list containing all of the enum values that are defined.
  static const List<FlutterService> VALUES = <FlutterService>[OUTLINE];

  @override
  final String name;

  const FlutterService._(this.name);

  factory FlutterService(String name) {
    switch (name) {
      case 'OUTLINE':
        return OUTLINE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FlutterService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return FlutterService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'FlutterService', json);
  }

  @override
  String toString() => 'FlutterService.$name';

  String toJson() => name;
}

/// flutter.setSubscriptions params
///
/// {
///   "subscriptions": Map<FlutterService, List<FilePath>>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetSubscriptionsParams implements RequestParams {
  Map<FlutterService, List<String>> _subscriptions;

  /// A table mapping services to a list of the files being subscribed to the
  /// service.
  Map<FlutterService, List<String>> get subscriptions => _subscriptions;

  /// A table mapping services to a list of the files being subscribed to the
  /// service.
  set subscriptions(Map<FlutterService, List<String>> value) {
    assert(value != null);
    _subscriptions = value;
  }

  FlutterSetSubscriptionsParams(
      Map<FlutterService, List<String>> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory FlutterSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Map<FlutterService, List<String>> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeMap(
            jsonPath + '.subscriptions', json['subscriptions'],
            keyDecoder: (String jsonPath, Object json) =>
                FlutterService.fromJson(jsonDecoder, jsonPath, json),
            valueDecoder: (String jsonPath, Object json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return FlutterSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.setSubscriptions params', json);
    }
  }

  factory FlutterSetSubscriptionsParams.fromRequest(Request request) {
    return FlutterSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['subscriptions'] = mapMap(subscriptions,
        keyCallback: (FlutterService value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'flutter.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterSetSubscriptionsParams) {
      return mapEqual(
          subscriptions,
          other.subscriptions,
          (List<String> a, List<String> b) =>
              listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// flutter.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is FlutterSetSubscriptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 628296315;
  }
}

/// flutter.setWidgetPropertyValue params
///
/// {
///   "id": int
///   "value": optional FlutterWidgetPropertyValue
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetWidgetPropertyValueParams implements RequestParams {
  int _id;

  FlutterWidgetPropertyValue _value;

  /// The identifier of the property, previously returned as a part of a
  /// FlutterWidgetProperty.
  ///
  /// An error of type FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID is
  /// generated if the identifier is not valid.
  int get id => _id;

  /// The identifier of the property, previously returned as a part of a
  /// FlutterWidgetProperty.
  ///
  /// An error of type FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID is
  /// generated if the identifier is not valid.
  set id(int value) {
    assert(value != null);
    _id = value;
  }

  /// The new value to set for the property.
  ///
  /// If absent, indicates that the property should be removed. If the property
  /// corresponds to an optional parameter, the corresponding named argument is
  /// removed. If the property isRequired is true,
  /// FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED error is generated.
  ///
  /// If the expression is not a syntactically valid Dart code, then
  /// FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION is reported.
  FlutterWidgetPropertyValue get value => _value;

  /// The new value to set for the property.
  ///
  /// If absent, indicates that the property should be removed. If the property
  /// corresponds to an optional parameter, the corresponding named argument is
  /// removed. If the property isRequired is true,
  /// FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED error is generated.
  ///
  /// If the expression is not a syntactically valid Dart code, then
  /// FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION is reported.
  set value(FlutterWidgetPropertyValue value) {
    _value = value;
  }

  FlutterSetWidgetPropertyValueParams(int id,
      {FlutterWidgetPropertyValue value}) {
    this.id = id;
    this.value = value;
  }

  factory FlutterSetWidgetPropertyValueParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      FlutterWidgetPropertyValue value;
      if (json.containsKey('value')) {
        value = FlutterWidgetPropertyValue.fromJson(
            jsonDecoder, jsonPath + '.value', json['value']);
      }
      return FlutterSetWidgetPropertyValueParams(id, value: value);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.setWidgetPropertyValue params', json);
    }
  }

  factory FlutterSetWidgetPropertyValueParams.fromRequest(Request request) {
    return FlutterSetWidgetPropertyValueParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    if (value != null) {
      result['value'] = value.toJson();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'flutter.setWidgetPropertyValue', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterSetWidgetPropertyValueParams) {
      return id == other.id && value == other.value;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// flutter.setWidgetPropertyValue result
///
/// {
///   "change": SourceChange
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterSetWidgetPropertyValueResult implements ResponseResult {
  SourceChange _change;

  /// The change that should be applied.
  SourceChange get change => _change;

  /// The change that should be applied.
  set change(SourceChange value) {
    assert(value != null);
    _change = value;
  }

  FlutterSetWidgetPropertyValueResult(SourceChange change) {
    this.change = change;
  }

  factory FlutterSetWidgetPropertyValueResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      SourceChange change;
      if (json.containsKey('change')) {
        change = SourceChange.fromJson(
            jsonDecoder, jsonPath + '.change', json['change']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'change');
      }
      return FlutterSetWidgetPropertyValueResult(change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'flutter.setWidgetPropertyValue result', json);
    }
  }

  factory FlutterSetWidgetPropertyValueResult.fromResponse(Response response) {
    return FlutterSetWidgetPropertyValueResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['change'] = change.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterSetWidgetPropertyValueResult) {
      return change == other.change;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterWidgetProperty
///
/// {
///   "documentation": optional String
///   "expression": optional String
///   "id": int
///   "isRequired": bool
///   "isSafeToUpdate": bool
///   "name": String
///   "children": optional List<FlutterWidgetProperty>
///   "editor": optional FlutterWidgetPropertyEditor
///   "value": optional FlutterWidgetPropertyValue
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetProperty implements HasToJson {
  String _documentation;

  String _expression;

  int _id;

  bool _isRequired;

  bool _isSafeToUpdate;

  String _name;

  List<FlutterWidgetProperty> _children;

  FlutterWidgetPropertyEditor _editor;

  FlutterWidgetPropertyValue _value;

  /// The documentation of the property to show to the user. Omitted if the
  /// server does not know the documentation, e.g. because the corresponding
  /// field is not documented.
  String get documentation => _documentation;

  /// The documentation of the property to show to the user. Omitted if the
  /// server does not know the documentation, e.g. because the corresponding
  /// field is not documented.
  set documentation(String value) {
    _documentation = value;
  }

  /// If the value of this property is set, the Dart code of the expression of
  /// this property.
  String get expression => _expression;

  /// If the value of this property is set, the Dart code of the expression of
  /// this property.
  set expression(String value) {
    _expression = value;
  }

  /// The unique identifier of the property, must be passed back to the server
  /// when updating the property value. Identifiers become invalid on any
  /// source code change.
  int get id => _id;

  /// The unique identifier of the property, must be passed back to the server
  /// when updating the property value. Identifiers become invalid on any
  /// source code change.
  set id(int value) {
    assert(value != null);
    _id = value;
  }

  /// True if the property is required, e.g. because it corresponds to a
  /// required parameter of a constructor.
  bool get isRequired => _isRequired;

  /// True if the property is required, e.g. because it corresponds to a
  /// required parameter of a constructor.
  set isRequired(bool value) {
    assert(value != null);
    _isRequired = value;
  }

  /// If the property expression is a concrete value (e.g. a literal, or an
  /// enum constant), then it is safe to replace the expression with another
  /// concrete value. In this case this field is true. Otherwise, for example
  /// when the expression is a reference to a field, so that its value is
  /// provided from outside, this field is false.
  bool get isSafeToUpdate => _isSafeToUpdate;

  /// If the property expression is a concrete value (e.g. a literal, or an
  /// enum constant), then it is safe to replace the expression with another
  /// concrete value. In this case this field is true. Otherwise, for example
  /// when the expression is a reference to a field, so that its value is
  /// provided from outside, this field is false.
  set isSafeToUpdate(bool value) {
    assert(value != null);
    _isSafeToUpdate = value;
  }

  /// The name of the property to display to the user.
  String get name => _name;

  /// The name of the property to display to the user.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The list of children properties, if any. For example any property of type
  /// EdgeInsets will have four children properties of type double - left / top
  /// / right / bottom.
  List<FlutterWidgetProperty> get children => _children;

  /// The list of children properties, if any. For example any property of type
  /// EdgeInsets will have four children properties of type double - left / top
  /// / right / bottom.
  set children(List<FlutterWidgetProperty> value) {
    _children = value;
  }

  /// The editor that should be used by the client. This field is omitted if
  /// the server does not know the editor for this property, for example
  /// because it does not have one of the supported types.
  FlutterWidgetPropertyEditor get editor => _editor;

  /// The editor that should be used by the client. This field is omitted if
  /// the server does not know the editor for this property, for example
  /// because it does not have one of the supported types.
  set editor(FlutterWidgetPropertyEditor value) {
    _editor = value;
  }

  /// If the expression is set, and the server knows the value of the
  /// expression, this field is set.
  FlutterWidgetPropertyValue get value => _value;

  /// If the expression is set, and the server knows the value of the
  /// expression, this field is set.
  set value(FlutterWidgetPropertyValue value) {
    _value = value;
  }

  FlutterWidgetProperty(
      int id, bool isRequired, bool isSafeToUpdate, String name,
      {String documentation,
      String expression,
      List<FlutterWidgetProperty> children,
      FlutterWidgetPropertyEditor editor,
      FlutterWidgetPropertyValue value}) {
    this.documentation = documentation;
    this.expression = expression;
    this.id = id;
    this.isRequired = isRequired;
    this.isSafeToUpdate = isSafeToUpdate;
    this.name = name;
    this.children = children;
    this.editor = editor;
    this.value = value;
  }

  factory FlutterWidgetProperty.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String documentation;
      if (json.containsKey('documentation')) {
        documentation = jsonDecoder.decodeString(
            jsonPath + '.documentation', json['documentation']);
      }
      String expression;
      if (json.containsKey('expression')) {
        expression = jsonDecoder.decodeString(
            jsonPath + '.expression', json['expression']);
      }
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      bool isRequired;
      if (json.containsKey('isRequired')) {
        isRequired = jsonDecoder.decodeBool(
            jsonPath + '.isRequired', json['isRequired']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isRequired');
      }
      bool isSafeToUpdate;
      if (json.containsKey('isSafeToUpdate')) {
        isSafeToUpdate = jsonDecoder.decodeBool(
            jsonPath + '.isSafeToUpdate', json['isSafeToUpdate']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isSafeToUpdate');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      List<FlutterWidgetProperty> children;
      if (json.containsKey('children')) {
        children = jsonDecoder.decodeList(
            jsonPath + '.children',
            json['children'],
            (String jsonPath, Object json) =>
                FlutterWidgetProperty.fromJson(jsonDecoder, jsonPath, json));
      }
      FlutterWidgetPropertyEditor editor;
      if (json.containsKey('editor')) {
        editor = FlutterWidgetPropertyEditor.fromJson(
            jsonDecoder, jsonPath + '.editor', json['editor']);
      }
      FlutterWidgetPropertyValue value;
      if (json.containsKey('value')) {
        value = FlutterWidgetPropertyValue.fromJson(
            jsonDecoder, jsonPath + '.value', json['value']);
      }
      return FlutterWidgetProperty(id, isRequired, isSafeToUpdate, name,
          documentation: documentation,
          expression: expression,
          children: children,
          editor: editor,
          value: value);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterWidgetProperty', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (documentation != null) {
      result['documentation'] = documentation;
    }
    if (expression != null) {
      result['expression'] = expression;
    }
    result['id'] = id;
    result['isRequired'] = isRequired;
    result['isSafeToUpdate'] = isSafeToUpdate;
    result['name'] = name;
    if (children != null) {
      result['children'] = children
          .map((FlutterWidgetProperty value) => value.toJson())
          .toList();
    }
    if (editor != null) {
      result['editor'] = editor.toJson();
    }
    if (value != null) {
      result['value'] = value.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetProperty) {
      return documentation == other.documentation &&
          expression == other.expression &&
          id == other.id &&
          isRequired == other.isRequired &&
          isSafeToUpdate == other.isSafeToUpdate &&
          name == other.name &&
          listEqual(children, other.children,
              (FlutterWidgetProperty a, FlutterWidgetProperty b) => a == b) &&
          editor == other.editor &&
          value == other.value;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, documentation.hashCode);
    hash = JenkinsSmiHash.combine(hash, expression.hashCode);
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, isRequired.hashCode);
    hash = JenkinsSmiHash.combine(hash, isSafeToUpdate.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, children.hashCode);
    hash = JenkinsSmiHash.combine(hash, editor.hashCode);
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterWidgetPropertyEditor
///
/// {
///   "kind": FlutterWidgetPropertyEditorKind
///   "enumItems": optional List<FlutterWidgetPropertyValueEnumItem>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyEditor implements HasToJson {
  FlutterWidgetPropertyEditorKind _kind;

  List<FlutterWidgetPropertyValueEnumItem> _enumItems;

  FlutterWidgetPropertyEditorKind get kind => _kind;

  set kind(FlutterWidgetPropertyEditorKind value) {
    assert(value != null);
    _kind = value;
  }

  List<FlutterWidgetPropertyValueEnumItem> get enumItems => _enumItems;

  set enumItems(List<FlutterWidgetPropertyValueEnumItem> value) {
    _enumItems = value;
  }

  FlutterWidgetPropertyEditor(FlutterWidgetPropertyEditorKind kind,
      {List<FlutterWidgetPropertyValueEnumItem> enumItems}) {
    this.kind = kind;
    this.enumItems = enumItems;
  }

  factory FlutterWidgetPropertyEditor.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      FlutterWidgetPropertyEditorKind kind;
      if (json.containsKey('kind')) {
        kind = FlutterWidgetPropertyEditorKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      List<FlutterWidgetPropertyValueEnumItem> enumItems;
      if (json.containsKey('enumItems')) {
        enumItems = jsonDecoder.decodeList(
            jsonPath + '.enumItems',
            json['enumItems'],
            (String jsonPath, Object json) =>
                FlutterWidgetPropertyValueEnumItem.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      return FlutterWidgetPropertyEditor(kind, enumItems: enumItems);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterWidgetPropertyEditor', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['kind'] = kind.toJson();
    if (enumItems != null) {
      result['enumItems'] = enumItems
          .map((FlutterWidgetPropertyValueEnumItem value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetPropertyEditor) {
      return kind == other.kind &&
          listEqual(
              enumItems,
              other.enumItems,
              (FlutterWidgetPropertyValueEnumItem a,
                      FlutterWidgetPropertyValueEnumItem b) =>
                  a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, enumItems.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterWidgetPropertyEditorKind
///
/// enum {
///   BOOL
///   DOUBLE
///   ENUM
///   ENUM_LIKE
///   INT
///   STRING
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyEditorKind implements Enum {
  /// The editor for a property of type bool.
  static const FlutterWidgetPropertyEditorKind BOOL =
      FlutterWidgetPropertyEditorKind._('BOOL');

  /// The editor for a property of the type double.
  static const FlutterWidgetPropertyEditorKind DOUBLE =
      FlutterWidgetPropertyEditorKind._('DOUBLE');

  /// The editor for choosing an item of an enumeration, see the enumItems
  /// field of FlutterWidgetPropertyEditor.
  static const FlutterWidgetPropertyEditorKind ENUM =
      FlutterWidgetPropertyEditorKind._('ENUM');

  /// The editor for either choosing a pre-defined item from a list of provided
  /// static field references (like ENUM), or specifying a free-form
  /// expression.
  static const FlutterWidgetPropertyEditorKind ENUM_LIKE =
      FlutterWidgetPropertyEditorKind._('ENUM_LIKE');

  /// The editor for a property of type int.
  static const FlutterWidgetPropertyEditorKind INT =
      FlutterWidgetPropertyEditorKind._('INT');

  /// The editor for a property of the type String.
  static const FlutterWidgetPropertyEditorKind STRING =
      FlutterWidgetPropertyEditorKind._('STRING');

  /// A list containing all of the enum values that are defined.
  static const List<FlutterWidgetPropertyEditorKind> VALUES =
      <FlutterWidgetPropertyEditorKind>[
    BOOL,
    DOUBLE,
    ENUM,
    ENUM_LIKE,
    INT,
    STRING
  ];

  @override
  final String name;

  const FlutterWidgetPropertyEditorKind._(this.name);

  factory FlutterWidgetPropertyEditorKind(String name) {
    switch (name) {
      case 'BOOL':
        return BOOL;
      case 'DOUBLE':
        return DOUBLE;
      case 'ENUM':
        return ENUM;
      case 'ENUM_LIKE':
        return ENUM_LIKE;
      case 'INT':
        return INT;
      case 'STRING':
        return STRING;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory FlutterWidgetPropertyEditorKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return FlutterWidgetPropertyEditorKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(
        jsonPath, 'FlutterWidgetPropertyEditorKind', json);
  }

  @override
  String toString() => 'FlutterWidgetPropertyEditorKind.$name';

  String toJson() => name;
}

/// FlutterWidgetPropertyValue
///
/// {
///   "boolValue": optional bool
///   "doubleValue": optional double
///   "intValue": optional int
///   "stringValue": optional String
///   "enumValue": optional FlutterWidgetPropertyValueEnumItem
///   "expression": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyValue implements HasToJson {
  bool _boolValue;

  double _doubleValue;

  int _intValue;

  String _stringValue;

  FlutterWidgetPropertyValueEnumItem _enumValue;

  String _expression;

  bool get boolValue => _boolValue;

  set boolValue(bool value) {
    _boolValue = value;
  }

  double get doubleValue => _doubleValue;

  set doubleValue(double value) {
    _doubleValue = value;
  }

  int get intValue => _intValue;

  set intValue(int value) {
    _intValue = value;
  }

  String get stringValue => _stringValue;

  set stringValue(String value) {
    _stringValue = value;
  }

  FlutterWidgetPropertyValueEnumItem get enumValue => _enumValue;

  set enumValue(FlutterWidgetPropertyValueEnumItem value) {
    _enumValue = value;
  }

  /// A free-form expression, which will be used as the value as is.
  String get expression => _expression;

  /// A free-form expression, which will be used as the value as is.
  set expression(String value) {
    _expression = value;
  }

  FlutterWidgetPropertyValue(
      {bool boolValue,
      double doubleValue,
      int intValue,
      String stringValue,
      FlutterWidgetPropertyValueEnumItem enumValue,
      String expression}) {
    this.boolValue = boolValue;
    this.doubleValue = doubleValue;
    this.intValue = intValue;
    this.stringValue = stringValue;
    this.enumValue = enumValue;
    this.expression = expression;
  }

  factory FlutterWidgetPropertyValue.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool boolValue;
      if (json.containsKey('boolValue')) {
        boolValue =
            jsonDecoder.decodeBool(jsonPath + '.boolValue', json['boolValue']);
      }
      double doubleValue;
      if (json.containsKey('doubleValue')) {
        doubleValue = jsonDecoder.decodeDouble(
            jsonPath + '.doubleValue', json['doubleValue']);
      }
      int intValue;
      if (json.containsKey('intValue')) {
        intValue =
            jsonDecoder.decodeInt(jsonPath + '.intValue', json['intValue']);
      }
      String stringValue;
      if (json.containsKey('stringValue')) {
        stringValue = jsonDecoder.decodeString(
            jsonPath + '.stringValue', json['stringValue']);
      }
      FlutterWidgetPropertyValueEnumItem enumValue;
      if (json.containsKey('enumValue')) {
        enumValue = FlutterWidgetPropertyValueEnumItem.fromJson(
            jsonDecoder, jsonPath + '.enumValue', json['enumValue']);
      }
      String expression;
      if (json.containsKey('expression')) {
        expression = jsonDecoder.decodeString(
            jsonPath + '.expression', json['expression']);
      }
      return FlutterWidgetPropertyValue(
          boolValue: boolValue,
          doubleValue: doubleValue,
          intValue: intValue,
          stringValue: stringValue,
          enumValue: enumValue,
          expression: expression);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'FlutterWidgetPropertyValue', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (boolValue != null) {
      result['boolValue'] = boolValue;
    }
    if (doubleValue != null) {
      result['doubleValue'] = doubleValue;
    }
    if (intValue != null) {
      result['intValue'] = intValue;
    }
    if (stringValue != null) {
      result['stringValue'] = stringValue;
    }
    if (enumValue != null) {
      result['enumValue'] = enumValue.toJson();
    }
    if (expression != null) {
      result['expression'] = expression;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetPropertyValue) {
      return boolValue == other.boolValue &&
          doubleValue == other.doubleValue &&
          intValue == other.intValue &&
          stringValue == other.stringValue &&
          enumValue == other.enumValue &&
          expression == other.expression;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, boolValue.hashCode);
    hash = JenkinsSmiHash.combine(hash, doubleValue.hashCode);
    hash = JenkinsSmiHash.combine(hash, intValue.hashCode);
    hash = JenkinsSmiHash.combine(hash, stringValue.hashCode);
    hash = JenkinsSmiHash.combine(hash, enumValue.hashCode);
    hash = JenkinsSmiHash.combine(hash, expression.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// FlutterWidgetPropertyValueEnumItem
///
/// {
///   "libraryUri": String
///   "className": String
///   "name": String
///   "documentation": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class FlutterWidgetPropertyValueEnumItem implements HasToJson {
  String _libraryUri;

  String _className;

  String _name;

  String _documentation;

  /// The URI of the library containing the className. When the enum item is
  /// passed back, this will allow the server to import the corresponding
  /// library if necessary.
  String get libraryUri => _libraryUri;

  /// The URI of the library containing the className. When the enum item is
  /// passed back, this will allow the server to import the corresponding
  /// library if necessary.
  set libraryUri(String value) {
    assert(value != null);
    _libraryUri = value;
  }

  /// The name of the class or enum.
  String get className => _className;

  /// The name of the class or enum.
  set className(String value) {
    assert(value != null);
    _className = value;
  }

  /// The name of the field in the enumeration, or the static field in the
  /// class.
  String get name => _name;

  /// The name of the field in the enumeration, or the static field in the
  /// class.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The documentation to show to the user. Omitted if the server does not
  /// know the documentation, e.g. because the corresponding field is not
  /// documented.
  String get documentation => _documentation;

  /// The documentation to show to the user. Omitted if the server does not
  /// know the documentation, e.g. because the corresponding field is not
  /// documented.
  set documentation(String value) {
    _documentation = value;
  }

  FlutterWidgetPropertyValueEnumItem(
      String libraryUri, String className, String name,
      {String documentation}) {
    this.libraryUri = libraryUri;
    this.className = className;
    this.name = name;
    this.documentation = documentation;
  }

  factory FlutterWidgetPropertyValueEnumItem.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String libraryUri;
      if (json.containsKey('libraryUri')) {
        libraryUri = jsonDecoder.decodeString(
            jsonPath + '.libraryUri', json['libraryUri']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraryUri');
      }
      String className;
      if (json.containsKey('className')) {
        className = jsonDecoder.decodeString(
            jsonPath + '.className', json['className']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'className');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String documentation;
      if (json.containsKey('documentation')) {
        documentation = jsonDecoder.decodeString(
            jsonPath + '.documentation', json['documentation']);
      }
      return FlutterWidgetPropertyValueEnumItem(libraryUri, className, name,
          documentation: documentation);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'FlutterWidgetPropertyValueEnumItem', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['libraryUri'] = libraryUri;
    result['className'] = className;
    result['name'] = name;
    if (documentation != null) {
      result['documentation'] = documentation;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is FlutterWidgetPropertyValueEnumItem) {
      return libraryUri == other.libraryUri &&
          className == other.className &&
          name == other.name &&
          documentation == other.documentation;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, libraryUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// GeneralAnalysisService
///
/// enum {
///   ANALYZED_FILES
/// }
///
/// Clients may not extend, implement or mix-in this class.
class GeneralAnalysisService implements Enum {
  static const GeneralAnalysisService ANALYZED_FILES =
      GeneralAnalysisService._('ANALYZED_FILES');

  /// A list containing all of the enum values that are defined.
  static const List<GeneralAnalysisService> VALUES = <GeneralAnalysisService>[
    ANALYZED_FILES
  ];

  @override
  final String name;

  const GeneralAnalysisService._(this.name);

  factory GeneralAnalysisService(String name) {
    switch (name) {
      case 'ANALYZED_FILES':
        return ANALYZED_FILES;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory GeneralAnalysisService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return GeneralAnalysisService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'GeneralAnalysisService', json);
  }

  @override
  String toString() => 'GeneralAnalysisService.$name';

  String toJson() => name;
}

/// HoverInformation
///
/// {
///   "offset": int
///   "length": int
///   "containingLibraryPath": optional String
///   "containingLibraryName": optional String
///   "containingClassDescription": optional String
///   "dartdoc": optional String
///   "elementDescription": optional String
///   "elementKind": optional String
///   "isDeprecated": optional bool
///   "parameter": optional String
///   "propagatedType": optional String
///   "staticType": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class HoverInformation implements HasToJson {
  int _offset;

  int _length;

  String _containingLibraryPath;

  String _containingLibraryName;

  String _containingClassDescription;

  String _dartdoc;

  String _elementDescription;

  String _elementKind;

  bool _isDeprecated;

  String _parameter;

  String _propagatedType;

  String _staticType;

  /// The offset of the range of characters that encompasses the cursor
  /// position and has the same hover information as the cursor position.
  int get offset => _offset;

  /// The offset of the range of characters that encompasses the cursor
  /// position and has the same hover information as the cursor position.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the range of characters that encompasses the cursor
  /// position and has the same hover information as the cursor position.
  int get length => _length;

  /// The length of the range of characters that encompasses the cursor
  /// position and has the same hover information as the cursor position.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The path to the defining compilation unit of the library in which the
  /// referenced element is declared. This data is omitted if there is no
  /// referenced element, or if the element is declared inside an HTML file.
  String get containingLibraryPath => _containingLibraryPath;

  /// The path to the defining compilation unit of the library in which the
  /// referenced element is declared. This data is omitted if there is no
  /// referenced element, or if the element is declared inside an HTML file.
  set containingLibraryPath(String value) {
    _containingLibraryPath = value;
  }

  /// The URI of the containing library, examples here include "dart:core",
  /// "package:.." and file uris represented by the path on disk, "/..". The
  /// data is omitted if the element is declared inside an HTML file.
  String get containingLibraryName => _containingLibraryName;

  /// The URI of the containing library, examples here include "dart:core",
  /// "package:.." and file uris represented by the path on disk, "/..". The
  /// data is omitted if the element is declared inside an HTML file.
  set containingLibraryName(String value) {
    _containingLibraryName = value;
  }

  /// A human-readable description of the class declaring the element being
  /// referenced. This data is omitted if there is no referenced element, or if
  /// the element is not a class member.
  String get containingClassDescription => _containingClassDescription;

  /// A human-readable description of the class declaring the element being
  /// referenced. This data is omitted if there is no referenced element, or if
  /// the element is not a class member.
  set containingClassDescription(String value) {
    _containingClassDescription = value;
  }

  /// The dartdoc associated with the referenced element. Other than the
  /// removal of the comment delimiters, including leading asterisks in the
  /// case of a block comment, the dartdoc is unprocessed markdown. This data
  /// is omitted if there is no referenced element, or if the element has no
  /// dartdoc.
  String get dartdoc => _dartdoc;

  /// The dartdoc associated with the referenced element. Other than the
  /// removal of the comment delimiters, including leading asterisks in the
  /// case of a block comment, the dartdoc is unprocessed markdown. This data
  /// is omitted if there is no referenced element, or if the element has no
  /// dartdoc.
  set dartdoc(String value) {
    _dartdoc = value;
  }

  /// A human-readable description of the element being referenced. This data
  /// is omitted if there is no referenced element.
  String get elementDescription => _elementDescription;

  /// A human-readable description of the element being referenced. This data
  /// is omitted if there is no referenced element.
  set elementDescription(String value) {
    _elementDescription = value;
  }

  /// A human-readable description of the kind of element being referenced
  /// (such as "class" or "function type alias"). This data is omitted if there
  /// is no referenced element.
  String get elementKind => _elementKind;

  /// A human-readable description of the kind of element being referenced
  /// (such as "class" or "function type alias"). This data is omitted if there
  /// is no referenced element.
  set elementKind(String value) {
    _elementKind = value;
  }

  /// True if the referenced element is deprecated.
  bool get isDeprecated => _isDeprecated;

  /// True if the referenced element is deprecated.
  set isDeprecated(bool value) {
    _isDeprecated = value;
  }

  /// A human-readable description of the parameter corresponding to the
  /// expression being hovered over. This data is omitted if the location is
  /// not in an argument to a function.
  String get parameter => _parameter;

  /// A human-readable description of the parameter corresponding to the
  /// expression being hovered over. This data is omitted if the location is
  /// not in an argument to a function.
  set parameter(String value) {
    _parameter = value;
  }

  /// The name of the propagated type of the expression. This data is omitted
  /// if the location does not correspond to an expression or if there is no
  /// propagated type information.
  String get propagatedType => _propagatedType;

  /// The name of the propagated type of the expression. This data is omitted
  /// if the location does not correspond to an expression or if there is no
  /// propagated type information.
  set propagatedType(String value) {
    _propagatedType = value;
  }

  /// The name of the static type of the expression. This data is omitted if
  /// the location does not correspond to an expression.
  String get staticType => _staticType;

  /// The name of the static type of the expression. This data is omitted if
  /// the location does not correspond to an expression.
  set staticType(String value) {
    _staticType = value;
  }

  HoverInformation(int offset, int length,
      {String containingLibraryPath,
      String containingLibraryName,
      String containingClassDescription,
      String dartdoc,
      String elementDescription,
      String elementKind,
      bool isDeprecated,
      String parameter,
      String propagatedType,
      String staticType}) {
    this.offset = offset;
    this.length = length;
    this.containingLibraryPath = containingLibraryPath;
    this.containingLibraryName = containingLibraryName;
    this.containingClassDescription = containingClassDescription;
    this.dartdoc = dartdoc;
    this.elementDescription = elementDescription;
    this.elementKind = elementKind;
    this.isDeprecated = isDeprecated;
    this.parameter = parameter;
    this.propagatedType = propagatedType;
    this.staticType = staticType;
  }

  factory HoverInformation.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String containingLibraryPath;
      if (json.containsKey('containingLibraryPath')) {
        containingLibraryPath = jsonDecoder.decodeString(
            jsonPath + '.containingLibraryPath', json['containingLibraryPath']);
      }
      String containingLibraryName;
      if (json.containsKey('containingLibraryName')) {
        containingLibraryName = jsonDecoder.decodeString(
            jsonPath + '.containingLibraryName', json['containingLibraryName']);
      }
      String containingClassDescription;
      if (json.containsKey('containingClassDescription')) {
        containingClassDescription = jsonDecoder.decodeString(
            jsonPath + '.containingClassDescription',
            json['containingClassDescription']);
      }
      String dartdoc;
      if (json.containsKey('dartdoc')) {
        dartdoc =
            jsonDecoder.decodeString(jsonPath + '.dartdoc', json['dartdoc']);
      }
      String elementDescription;
      if (json.containsKey('elementDescription')) {
        elementDescription = jsonDecoder.decodeString(
            jsonPath + '.elementDescription', json['elementDescription']);
      }
      String elementKind;
      if (json.containsKey('elementKind')) {
        elementKind = jsonDecoder.decodeString(
            jsonPath + '.elementKind', json['elementKind']);
      }
      bool isDeprecated;
      if (json.containsKey('isDeprecated')) {
        isDeprecated = jsonDecoder.decodeBool(
            jsonPath + '.isDeprecated', json['isDeprecated']);
      }
      String parameter;
      if (json.containsKey('parameter')) {
        parameter = jsonDecoder.decodeString(
            jsonPath + '.parameter', json['parameter']);
      }
      String propagatedType;
      if (json.containsKey('propagatedType')) {
        propagatedType = jsonDecoder.decodeString(
            jsonPath + '.propagatedType', json['propagatedType']);
      }
      String staticType;
      if (json.containsKey('staticType')) {
        staticType = jsonDecoder.decodeString(
            jsonPath + '.staticType', json['staticType']);
      }
      return HoverInformation(offset, length,
          containingLibraryPath: containingLibraryPath,
          containingLibraryName: containingLibraryName,
          containingClassDescription: containingClassDescription,
          dartdoc: dartdoc,
          elementDescription: elementDescription,
          elementKind: elementKind,
          isDeprecated: isDeprecated,
          parameter: parameter,
          propagatedType: propagatedType,
          staticType: staticType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'HoverInformation', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    if (containingLibraryPath != null) {
      result['containingLibraryPath'] = containingLibraryPath;
    }
    if (containingLibraryName != null) {
      result['containingLibraryName'] = containingLibraryName;
    }
    if (containingClassDescription != null) {
      result['containingClassDescription'] = containingClassDescription;
    }
    if (dartdoc != null) {
      result['dartdoc'] = dartdoc;
    }
    if (elementDescription != null) {
      result['elementDescription'] = elementDescription;
    }
    if (elementKind != null) {
      result['elementKind'] = elementKind;
    }
    if (isDeprecated != null) {
      result['isDeprecated'] = isDeprecated;
    }
    if (parameter != null) {
      result['parameter'] = parameter;
    }
    if (propagatedType != null) {
      result['propagatedType'] = propagatedType;
    }
    if (staticType != null) {
      result['staticType'] = staticType;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is HoverInformation) {
      return offset == other.offset &&
          length == other.length &&
          containingLibraryPath == other.containingLibraryPath &&
          containingLibraryName == other.containingLibraryName &&
          containingClassDescription == other.containingClassDescription &&
          dartdoc == other.dartdoc &&
          elementDescription == other.elementDescription &&
          elementKind == other.elementKind &&
          isDeprecated == other.isDeprecated &&
          parameter == other.parameter &&
          propagatedType == other.propagatedType &&
          staticType == other.staticType;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, containingLibraryPath.hashCode);
    hash = JenkinsSmiHash.combine(hash, containingLibraryName.hashCode);
    hash = JenkinsSmiHash.combine(hash, containingClassDescription.hashCode);
    hash = JenkinsSmiHash.combine(hash, dartdoc.hashCode);
    hash = JenkinsSmiHash.combine(hash, elementDescription.hashCode);
    hash = JenkinsSmiHash.combine(hash, elementKind.hashCode);
    hash = JenkinsSmiHash.combine(hash, isDeprecated.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameter.hashCode);
    hash = JenkinsSmiHash.combine(hash, propagatedType.hashCode);
    hash = JenkinsSmiHash.combine(hash, staticType.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ImplementedClass
///
/// {
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImplementedClass implements HasToJson {
  int _offset;

  int _length;

  /// The offset of the name of the implemented class.
  int get offset => _offset;

  /// The offset of the name of the implemented class.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the name of the implemented class.
  int get length => _length;

  /// The length of the name of the implemented class.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  ImplementedClass(int offset, int length) {
    this.offset = offset;
    this.length = length;
  }

  factory ImplementedClass.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return ImplementedClass(offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImplementedClass', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImplementedClass) {
      return offset == other.offset && length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ImplementedMember
///
/// {
///   "offset": int
///   "length": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImplementedMember implements HasToJson {
  int _offset;

  int _length;

  /// The offset of the name of the implemented member.
  int get offset => _offset;

  /// The offset of the name of the implemented member.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the name of the implemented member.
  int get length => _length;

  /// The length of the name of the implemented member.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  ImplementedMember(int offset, int length) {
    this.offset = offset;
    this.length = length;
  }

  factory ImplementedMember.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      return ImplementedMember(offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImplementedMember', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImplementedMember) {
      return offset == other.offset && length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ImportedElementSet
///
/// {
///   "strings": List<String>
///   "uris": List<int>
///   "names": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImportedElementSet implements HasToJson {
  List<String> _strings;

  List<int> _uris;

  List<int> _names;

  /// The list of unique strings in this object.
  List<String> get strings => _strings;

  /// The list of unique strings in this object.
  set strings(List<String> value) {
    assert(value != null);
    _strings = value;
  }

  /// The library URI part of the element. It is an index in the strings field.
  List<int> get uris => _uris;

  /// The library URI part of the element. It is an index in the strings field.
  set uris(List<int> value) {
    assert(value != null);
    _uris = value;
  }

  /// The name part of a the element. It is an index in the strings field.
  List<int> get names => _names;

  /// The name part of a the element. It is an index in the strings field.
  set names(List<int> value) {
    assert(value != null);
    _names = value;
  }

  ImportedElementSet(List<String> strings, List<int> uris, List<int> names) {
    this.strings = strings;
    this.uris = uris;
    this.names = names;
  }

  factory ImportedElementSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<String> strings;
      if (json.containsKey('strings')) {
        strings = jsonDecoder.decodeList(
            jsonPath + '.strings', json['strings'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'strings');
      }
      List<int> uris;
      if (json.containsKey('uris')) {
        uris = jsonDecoder.decodeList(
            jsonPath + '.uris', json['uris'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'uris');
      }
      List<int> names;
      if (json.containsKey('names')) {
        names = jsonDecoder.decodeList(
            jsonPath + '.names', json['names'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'names');
      }
      return ImportedElementSet(strings, uris, names);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImportedElementSet', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['strings'] = strings;
    result['uris'] = uris;
    result['names'] = names;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImportedElementSet) {
      return listEqual(
              strings, other.strings, (String a, String b) => a == b) &&
          listEqual(uris, other.uris, (int a, int b) => a == b) &&
          listEqual(names, other.names, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, strings.hashCode);
    hash = JenkinsSmiHash.combine(hash, uris.hashCode);
    hash = JenkinsSmiHash.combine(hash, names.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ImportedElements
///
/// {
///   "path": FilePath
///   "prefix": String
///   "elements": List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ImportedElements implements HasToJson {
  String _path;

  String _prefix;

  List<String> _elements;

  /// The absolute and normalized path of the file containing the library.
  String get path => _path;

  /// The absolute and normalized path of the file containing the library.
  set path(String value) {
    assert(value != null);
    _path = value;
  }

  /// The prefix that was used when importing the library into the original
  /// source.
  String get prefix => _prefix;

  /// The prefix that was used when importing the library into the original
  /// source.
  set prefix(String value) {
    assert(value != null);
    _prefix = value;
  }

  /// The names of the elements imported from the library.
  List<String> get elements => _elements;

  /// The names of the elements imported from the library.
  set elements(List<String> value) {
    assert(value != null);
    _elements = value;
  }

  ImportedElements(String path, String prefix, List<String> elements) {
    this.path = path;
    this.prefix = prefix;
    this.elements = elements;
  }

  factory ImportedElements.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeString(jsonPath + '.path', json['path']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      String prefix;
      if (json.containsKey('prefix')) {
        prefix = jsonDecoder.decodeString(jsonPath + '.prefix', json['prefix']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'prefix');
      }
      List<String> elements;
      if (json.containsKey('elements')) {
        elements = jsonDecoder.decodeList(
            jsonPath + '.elements', json['elements'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elements');
      }
      return ImportedElements(path, prefix, elements);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ImportedElements', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['path'] = path;
    result['prefix'] = prefix;
    result['elements'] = elements;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImportedElements) {
      return path == other.path &&
          prefix == other.prefix &&
          listEqual(elements, other.elements, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    hash = JenkinsSmiHash.combine(hash, prefix.hashCode);
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// IncludedSuggestionRelevanceTag
///
/// {
///   "tag": AvailableSuggestionRelevanceTag
///   "relevanceBoost": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class IncludedSuggestionRelevanceTag implements HasToJson {
  String _tag;

  int _relevanceBoost;

  /// The opaque value of the tag.
  String get tag => _tag;

  /// The opaque value of the tag.
  set tag(String value) {
    assert(value != null);
    _tag = value;
  }

  /// The boost to the relevance of the completion suggestions that match this
  /// tag, which is added to the relevance of the containing
  /// IncludedSuggestionSet.
  int get relevanceBoost => _relevanceBoost;

  /// The boost to the relevance of the completion suggestions that match this
  /// tag, which is added to the relevance of the containing
  /// IncludedSuggestionSet.
  set relevanceBoost(int value) {
    assert(value != null);
    _relevanceBoost = value;
  }

  IncludedSuggestionRelevanceTag(String tag, int relevanceBoost) {
    this.tag = tag;
    this.relevanceBoost = relevanceBoost;
  }

  factory IncludedSuggestionRelevanceTag.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String tag;
      if (json.containsKey('tag')) {
        tag = jsonDecoder.decodeString(jsonPath + '.tag', json['tag']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'tag');
      }
      int relevanceBoost;
      if (json.containsKey('relevanceBoost')) {
        relevanceBoost = jsonDecoder.decodeInt(
            jsonPath + '.relevanceBoost', json['relevanceBoost']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'relevanceBoost');
      }
      return IncludedSuggestionRelevanceTag(tag, relevanceBoost);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'IncludedSuggestionRelevanceTag', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['tag'] = tag;
    result['relevanceBoost'] = relevanceBoost;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is IncludedSuggestionRelevanceTag) {
      return tag == other.tag && relevanceBoost == other.relevanceBoost;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, tag.hashCode);
    hash = JenkinsSmiHash.combine(hash, relevanceBoost.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// IncludedSuggestionSet
///
/// {
///   "id": int
///   "relevance": int
///   "displayUri": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class IncludedSuggestionSet implements HasToJson {
  int _id;

  int _relevance;

  String _displayUri;

  /// Clients should use it to access the set of precomputed completions to be
  /// displayed to the user.
  int get id => _id;

  /// Clients should use it to access the set of precomputed completions to be
  /// displayed to the user.
  set id(int value) {
    assert(value != null);
    _id = value;
  }

  /// The relevance of completion suggestions from this library where a higher
  /// number indicates a higher relevance.
  int get relevance => _relevance;

  /// The relevance of completion suggestions from this library where a higher
  /// number indicates a higher relevance.
  set relevance(int value) {
    assert(value != null);
    _relevance = value;
  }

  /// The optional string that should be displayed instead of the uri of the
  /// referenced AvailableSuggestionSet.
  ///
  /// For example libraries in the "test" directory of a package have only
  /// "file://" URIs, so are usually long, and don't look nice, but actual
  /// import directives will use relative URIs, which are short, so we probably
  /// want to display such relative URIs to the user.
  String get displayUri => _displayUri;

  /// The optional string that should be displayed instead of the uri of the
  /// referenced AvailableSuggestionSet.
  ///
  /// For example libraries in the "test" directory of a package have only
  /// "file://" URIs, so are usually long, and don't look nice, but actual
  /// import directives will use relative URIs, which are short, so we probably
  /// want to display such relative URIs to the user.
  set displayUri(String value) {
    _displayUri = value;
  }

  IncludedSuggestionSet(int id, int relevance, {String displayUri}) {
    this.id = id;
    this.relevance = relevance;
    this.displayUri = displayUri;
  }

  factory IncludedSuggestionSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeInt(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      int relevance;
      if (json.containsKey('relevance')) {
        relevance =
            jsonDecoder.decodeInt(jsonPath + '.relevance', json['relevance']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'relevance');
      }
      String displayUri;
      if (json.containsKey('displayUri')) {
        displayUri = jsonDecoder.decodeString(
            jsonPath + '.displayUri', json['displayUri']);
      }
      return IncludedSuggestionSet(id, relevance, displayUri: displayUri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'IncludedSuggestionSet', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    result['relevance'] = relevance;
    if (displayUri != null) {
      result['displayUri'] = displayUri;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is IncludedSuggestionSet) {
      return id == other.id &&
          relevance == other.relevance &&
          displayUri == other.displayUri;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, relevance.hashCode);
    hash = JenkinsSmiHash.combine(hash, displayUri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// inlineLocalVariable feedback
///
/// {
///   "name": String
///   "occurrences": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class InlineLocalVariableFeedback extends RefactoringFeedback {
  String _name;

  int _occurrences;

  /// The name of the variable being inlined.
  String get name => _name;

  /// The name of the variable being inlined.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The number of times the variable occurs.
  int get occurrences => _occurrences;

  /// The number of times the variable occurs.
  set occurrences(int value) {
    assert(value != null);
    _occurrences = value;
  }

  InlineLocalVariableFeedback(String name, int occurrences) {
    this.name = name;
    this.occurrences = occurrences;
  }

  factory InlineLocalVariableFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      int occurrences;
      if (json.containsKey('occurrences')) {
        occurrences = jsonDecoder.decodeInt(
            jsonPath + '.occurrences', json['occurrences']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'occurrences');
      }
      return InlineLocalVariableFeedback(name, occurrences);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'inlineLocalVariable feedback', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['occurrences'] = occurrences;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineLocalVariableFeedback) {
      return name == other.name && occurrences == other.occurrences;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// inlineLocalVariable options
///
/// Clients may not extend, implement or mix-in this class.
class InlineLocalVariableOptions extends RefactoringOptions
    implements HasToJson {
  @override
  bool operator ==(other) {
    if (other is InlineLocalVariableOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 540364977;
  }
}

/// inlineMethod feedback
///
/// {
///   "className": optional String
///   "methodName": String
///   "isDeclaration": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class InlineMethodFeedback extends RefactoringFeedback {
  String _className;

  String _methodName;

  bool _isDeclaration;

  /// The name of the class enclosing the method being inlined. If not a class
  /// member is being inlined, this field will be absent.
  String get className => _className;

  /// The name of the class enclosing the method being inlined. If not a class
  /// member is being inlined, this field will be absent.
  set className(String value) {
    _className = value;
  }

  /// The name of the method (or function) being inlined.
  String get methodName => _methodName;

  /// The name of the method (or function) being inlined.
  set methodName(String value) {
    assert(value != null);
    _methodName = value;
  }

  /// True if the declaration of the method is selected. So all references
  /// should be inlined.
  bool get isDeclaration => _isDeclaration;

  /// True if the declaration of the method is selected. So all references
  /// should be inlined.
  set isDeclaration(bool value) {
    assert(value != null);
    _isDeclaration = value;
  }

  InlineMethodFeedback(String methodName, bool isDeclaration,
      {String className}) {
    this.className = className;
    this.methodName = methodName;
    this.isDeclaration = isDeclaration;
  }

  factory InlineMethodFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String className;
      if (json.containsKey('className')) {
        className = jsonDecoder.decodeString(
            jsonPath + '.className', json['className']);
      }
      String methodName;
      if (json.containsKey('methodName')) {
        methodName = jsonDecoder.decodeString(
            jsonPath + '.methodName', json['methodName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'methodName');
      }
      bool isDeclaration;
      if (json.containsKey('isDeclaration')) {
        isDeclaration = jsonDecoder.decodeBool(
            jsonPath + '.isDeclaration', json['isDeclaration']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isDeclaration');
      }
      return InlineMethodFeedback(methodName, isDeclaration,
          className: className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'inlineMethod feedback', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (className != null) {
      result['className'] = className;
    }
    result['methodName'] = methodName;
    result['isDeclaration'] = isDeclaration;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineMethodFeedback) {
      return className == other.className &&
          methodName == other.methodName &&
          isDeclaration == other.isDeclaration;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    hash = JenkinsSmiHash.combine(hash, methodName.hashCode);
    hash = JenkinsSmiHash.combine(hash, isDeclaration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// inlineMethod options
///
/// {
///   "deleteSource": bool
///   "inlineAll": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class InlineMethodOptions extends RefactoringOptions {
  bool _deleteSource;

  bool _inlineAll;

  /// True if the method being inlined should be removed. It is an error if
  /// this field is true and inlineAll is false.
  bool get deleteSource => _deleteSource;

  /// True if the method being inlined should be removed. It is an error if
  /// this field is true and inlineAll is false.
  set deleteSource(bool value) {
    assert(value != null);
    _deleteSource = value;
  }

  /// True if all invocations of the method should be inlined, or false if only
  /// the invocation site used to create this refactoring should be inlined.
  bool get inlineAll => _inlineAll;

  /// True if all invocations of the method should be inlined, or false if only
  /// the invocation site used to create this refactoring should be inlined.
  set inlineAll(bool value) {
    assert(value != null);
    _inlineAll = value;
  }

  InlineMethodOptions(bool deleteSource, bool inlineAll) {
    this.deleteSource = deleteSource;
    this.inlineAll = inlineAll;
  }

  factory InlineMethodOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool deleteSource;
      if (json.containsKey('deleteSource')) {
        deleteSource = jsonDecoder.decodeBool(
            jsonPath + '.deleteSource', json['deleteSource']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'deleteSource');
      }
      bool inlineAll;
      if (json.containsKey('inlineAll')) {
        inlineAll =
            jsonDecoder.decodeBool(jsonPath + '.inlineAll', json['inlineAll']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'inlineAll');
      }
      return InlineMethodOptions(deleteSource, inlineAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'inlineMethod options', json);
    }
  }

  factory InlineMethodOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return InlineMethodOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['deleteSource'] = deleteSource;
    result['inlineAll'] = inlineAll;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineMethodOptions) {
      return deleteSource == other.deleteSource && inlineAll == other.inlineAll;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, deleteSource.hashCode);
    hash = JenkinsSmiHash.combine(hash, inlineAll.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// kythe.getKytheEntries params
///
/// {
///   "file": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class KytheGetKytheEntriesParams implements RequestParams {
  String _file;

  /// The file containing the code for which the Kythe Entry objects are being
  /// requested.
  String get file => _file;

  /// The file containing the code for which the Kythe Entry objects are being
  /// requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  KytheGetKytheEntriesParams(String file) {
    this.file = file;
  }

  factory KytheGetKytheEntriesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      return KytheGetKytheEntriesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'kythe.getKytheEntries params', json);
    }
  }

  factory KytheGetKytheEntriesParams.fromRequest(Request request) {
    return KytheGetKytheEntriesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'kythe.getKytheEntries', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is KytheGetKytheEntriesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// kythe.getKytheEntries result
///
/// {
///   "entries": List<KytheEntry>
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class KytheGetKytheEntriesResult implements ResponseResult {
  List<KytheEntry> _entries;

  List<String> _files;

  /// The list of KytheEntry objects for the queried file.
  List<KytheEntry> get entries => _entries;

  /// The list of KytheEntry objects for the queried file.
  set entries(List<KytheEntry> value) {
    assert(value != null);
    _entries = value;
  }

  /// The set of files paths that were required, but not in the file system, to
  /// give a complete and accurate Kythe graph for the file. This could be due
  /// to a referenced file that does not exist or generated files not being
  /// generated or passed before the call to "getKytheEntries".
  List<String> get files => _files;

  /// The set of files paths that were required, but not in the file system, to
  /// give a complete and accurate Kythe graph for the file. This could be due
  /// to a referenced file that does not exist or generated files not being
  /// generated or passed before the call to "getKytheEntries".
  set files(List<String> value) {
    assert(value != null);
    _files = value;
  }

  KytheGetKytheEntriesResult(List<KytheEntry> entries, List<String> files) {
    this.entries = entries;
    this.files = files;
  }

  factory KytheGetKytheEntriesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<KytheEntry> entries;
      if (json.containsKey('entries')) {
        entries = jsonDecoder.decodeList(
            jsonPath + '.entries',
            json['entries'],
            (String jsonPath, Object json) =>
                KytheEntry.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'entries');
      }
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            jsonPath + '.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return KytheGetKytheEntriesResult(entries, files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'kythe.getKytheEntries result', json);
    }
  }

  factory KytheGetKytheEntriesResult.fromResponse(Response response) {
    return KytheGetKytheEntriesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['entries'] =
        entries.map((KytheEntry value) => value.toJson()).toList();
    result['files'] = files;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is KytheGetKytheEntriesResult) {
      return listEqual(
              entries, other.entries, (KytheEntry a, KytheEntry b) => a == b) &&
          listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, entries.hashCode);
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// LibraryPathSet
///
/// {
///   "scope": FilePath
///   "libraryPaths": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class LibraryPathSet implements HasToJson {
  String _scope;

  List<String> _libraryPaths;

  /// The filepath for which this request's libraries should be active in
  /// completion suggestions. This object associates filesystem regions to
  /// libraries and library directories of interest to the client.
  String get scope => _scope;

  /// The filepath for which this request's libraries should be active in
  /// completion suggestions. This object associates filesystem regions to
  /// libraries and library directories of interest to the client.
  set scope(String value) {
    assert(value != null);
    _scope = value;
  }

  /// The paths of the libraries of interest to the client for completion
  /// suggestions.
  List<String> get libraryPaths => _libraryPaths;

  /// The paths of the libraries of interest to the client for completion
  /// suggestions.
  set libraryPaths(List<String> value) {
    assert(value != null);
    _libraryPaths = value;
  }

  LibraryPathSet(String scope, List<String> libraryPaths) {
    this.scope = scope;
    this.libraryPaths = libraryPaths;
  }

  factory LibraryPathSet.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String scope;
      if (json.containsKey('scope')) {
        scope = jsonDecoder.decodeString(jsonPath + '.scope', json['scope']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'scope');
      }
      List<String> libraryPaths;
      if (json.containsKey('libraryPaths')) {
        libraryPaths = jsonDecoder.decodeList(jsonPath + '.libraryPaths',
            json['libraryPaths'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'libraryPaths');
      }
      return LibraryPathSet(scope, libraryPaths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'LibraryPathSet', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['scope'] = scope;
    result['libraryPaths'] = libraryPaths;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is LibraryPathSet) {
      return scope == other.scope &&
          listEqual(
              libraryPaths, other.libraryPaths, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, scope.hashCode);
    hash = JenkinsSmiHash.combine(hash, libraryPaths.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// moveFile feedback
///
/// Clients may not extend, implement or mix-in this class.
class MoveFileFeedback extends RefactoringFeedback implements HasToJson {
  @override
  bool operator ==(other) {
    if (other is MoveFileFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 438975893;
  }
}

/// moveFile options
///
/// {
///   "newFile": FilePath
/// }
///
/// Clients may not extend, implement or mix-in this class.
class MoveFileOptions extends RefactoringOptions {
  String _newFile;

  /// The new file path to which the given file is being moved.
  String get newFile => _newFile;

  /// The new file path to which the given file is being moved.
  set newFile(String value) {
    assert(value != null);
    _newFile = value;
  }

  MoveFileOptions(String newFile) {
    this.newFile = newFile;
  }

  factory MoveFileOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String newFile;
      if (json.containsKey('newFile')) {
        newFile =
            jsonDecoder.decodeString(jsonPath + '.newFile', json['newFile']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'newFile');
      }
      return MoveFileOptions(newFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'moveFile options', json);
    }
  }

  factory MoveFileOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return MoveFileOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['newFile'] = newFile;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is MoveFileOptions) {
      return newFile == other.newFile;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, newFile.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// OverriddenMember
///
/// {
///   "element": Element
///   "className": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class OverriddenMember implements HasToJson {
  Element _element;

  String _className;

  /// The element that is being overridden.
  Element get element => _element;

  /// The element that is being overridden.
  set element(Element value) {
    assert(value != null);
    _element = value;
  }

  /// The name of the class in which the member is defined.
  String get className => _className;

  /// The name of the class in which the member is defined.
  set className(String value) {
    assert(value != null);
    _className = value;
  }

  OverriddenMember(Element element, String className) {
    this.element = element;
    this.className = className;
  }

  factory OverriddenMember.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Element element;
      if (json.containsKey('element')) {
        element = Element.fromJson(
            jsonDecoder, jsonPath + '.element', json['element']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'element');
      }
      String className;
      if (json.containsKey('className')) {
        className = jsonDecoder.decodeString(
            jsonPath + '.className', json['className']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'className');
      }
      return OverriddenMember(element, className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'OverriddenMember', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['element'] = element.toJson();
    result['className'] = className;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is OverriddenMember) {
      return element == other.element && className == other.className;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// Override
///
/// {
///   "offset": int
///   "length": int
///   "superclassMember": optional OverriddenMember
///   "interfaceMembers": optional List<OverriddenMember>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class Override implements HasToJson {
  int _offset;

  int _length;

  OverriddenMember _superclassMember;

  List<OverriddenMember> _interfaceMembers;

  /// The offset of the name of the overriding member.
  int get offset => _offset;

  /// The offset of the name of the overriding member.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the name of the overriding member.
  int get length => _length;

  /// The length of the name of the overriding member.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The member inherited from a superclass that is overridden by the
  /// overriding member. The field is omitted if there is no superclass member,
  /// in which case there must be at least one interface member.
  OverriddenMember get superclassMember => _superclassMember;

  /// The member inherited from a superclass that is overridden by the
  /// overriding member. The field is omitted if there is no superclass member,
  /// in which case there must be at least one interface member.
  set superclassMember(OverriddenMember value) {
    _superclassMember = value;
  }

  /// The members inherited from interfaces that are overridden by the
  /// overriding member. The field is omitted if there are no interface
  /// members, in which case there must be a superclass member.
  List<OverriddenMember> get interfaceMembers => _interfaceMembers;

  /// The members inherited from interfaces that are overridden by the
  /// overriding member. The field is omitted if there are no interface
  /// members, in which case there must be a superclass member.
  set interfaceMembers(List<OverriddenMember> value) {
    _interfaceMembers = value;
  }

  Override(int offset, int length,
      {OverriddenMember superclassMember,
      List<OverriddenMember> interfaceMembers}) {
    this.offset = offset;
    this.length = length;
    this.superclassMember = superclassMember;
    this.interfaceMembers = interfaceMembers;
  }

  factory Override.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      OverriddenMember superclassMember;
      if (json.containsKey('superclassMember')) {
        superclassMember = OverriddenMember.fromJson(jsonDecoder,
            jsonPath + '.superclassMember', json['superclassMember']);
      }
      List<OverriddenMember> interfaceMembers;
      if (json.containsKey('interfaceMembers')) {
        interfaceMembers = jsonDecoder.decodeList(
            jsonPath + '.interfaceMembers',
            json['interfaceMembers'],
            (String jsonPath, Object json) =>
                OverriddenMember.fromJson(jsonDecoder, jsonPath, json));
      }
      return Override(offset, length,
          superclassMember: superclassMember,
          interfaceMembers: interfaceMembers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'Override', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    if (superclassMember != null) {
      result['superclassMember'] = superclassMember.toJson();
    }
    if (interfaceMembers != null) {
      result['interfaceMembers'] = interfaceMembers
          .map((OverriddenMember value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is Override) {
      return offset == other.offset &&
          length == other.length &&
          superclassMember == other.superclassMember &&
          listEqual(interfaceMembers, other.interfaceMembers,
              (OverriddenMember a, OverriddenMember b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, superclassMember.hashCode);
    hash = JenkinsSmiHash.combine(hash, interfaceMembers.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// PostfixTemplateDescriptor
///
/// {
///   "name": String
///   "key": String
///   "example": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PostfixTemplateDescriptor implements HasToJson {
  String _name;

  String _key;

  String _example;

  /// The template name, shown in the UI.
  String get name => _name;

  /// The template name, shown in the UI.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The unique template key, not shown in the UI.
  String get key => _key;

  /// The unique template key, not shown in the UI.
  set key(String value) {
    assert(value != null);
    _key = value;
  }

  /// A short example of the transformation performed when the template is
  /// applied.
  String get example => _example;

  /// A short example of the transformation performed when the template is
  /// applied.
  set example(String value) {
    assert(value != null);
    _example = value;
  }

  PostfixTemplateDescriptor(String name, String key, String example) {
    this.name = name;
    this.key = key;
    this.example = example;
  }

  factory PostfixTemplateDescriptor.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      String key;
      if (json.containsKey('key')) {
        key = jsonDecoder.decodeString(jsonPath + '.key', json['key']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'key');
      }
      String example;
      if (json.containsKey('example')) {
        example =
            jsonDecoder.decodeString(jsonPath + '.example', json['example']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'example');
      }
      return PostfixTemplateDescriptor(name, key, example);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'PostfixTemplateDescriptor', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['key'] = key;
    result['example'] = example;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PostfixTemplateDescriptor) {
      return name == other.name && key == other.key && example == other.example;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, key.hashCode);
    hash = JenkinsSmiHash.combine(hash, example.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// PubStatus
///
/// {
///   "isListingPackageDirs": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class PubStatus implements HasToJson {
  bool _isListingPackageDirs;

  /// True if the server is currently running pub to produce a list of package
  /// directories.
  bool get isListingPackageDirs => _isListingPackageDirs;

  /// True if the server is currently running pub to produce a list of package
  /// directories.
  set isListingPackageDirs(bool value) {
    assert(value != null);
    _isListingPackageDirs = value;
  }

  PubStatus(bool isListingPackageDirs) {
    this.isListingPackageDirs = isListingPackageDirs;
  }

  factory PubStatus.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool isListingPackageDirs;
      if (json.containsKey('isListingPackageDirs')) {
        isListingPackageDirs = jsonDecoder.decodeBool(
            jsonPath + '.isListingPackageDirs', json['isListingPackageDirs']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isListingPackageDirs');
      }
      return PubStatus(isListingPackageDirs);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'PubStatus', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['isListingPackageDirs'] = isListingPackageDirs;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PubStatus) {
      return isListingPackageDirs == other.isListingPackageDirs;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, isListingPackageDirs.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RefactoringFeedback
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringFeedback implements HasToJson {
  RefactoringFeedback();

  factory RefactoringFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json, Map responseJson) {
    return refactoringFeedbackFromJson(
        jsonDecoder, jsonPath, json, responseJson);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RefactoringFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/// RefactoringOptions
///
/// {
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RefactoringOptions implements HasToJson {
  RefactoringOptions();

  factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath,
      Object json, RefactoringKind kind) {
    return refactoringOptionsFromJson(jsonDecoder, jsonPath, json, kind);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RefactoringOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/// rename feedback
///
/// {
///   "offset": int
///   "length": int
///   "elementKindName": String
///   "oldName": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RenameFeedback extends RefactoringFeedback {
  int _offset;

  int _length;

  String _elementKindName;

  String _oldName;

  /// The offset to the beginning of the name selected to be renamed, or -1 if
  /// the name does not exist yet.
  int get offset => _offset;

  /// The offset to the beginning of the name selected to be renamed, or -1 if
  /// the name does not exist yet.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the name selected to be renamed.
  int get length => _length;

  /// The length of the name selected to be renamed.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// The human-readable description of the kind of element being renamed (such
  /// as "class" or "function type alias").
  String get elementKindName => _elementKindName;

  /// The human-readable description of the kind of element being renamed (such
  /// as "class" or "function type alias").
  set elementKindName(String value) {
    assert(value != null);
    _elementKindName = value;
  }

  /// The old name of the element before the refactoring.
  String get oldName => _oldName;

  /// The old name of the element before the refactoring.
  set oldName(String value) {
    assert(value != null);
    _oldName = value;
  }

  RenameFeedback(
      int offset, int length, String elementKindName, String oldName) {
    this.offset = offset;
    this.length = length;
    this.elementKindName = elementKindName;
    this.oldName = oldName;
  }

  factory RenameFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      String elementKindName;
      if (json.containsKey('elementKindName')) {
        elementKindName = jsonDecoder.decodeString(
            jsonPath + '.elementKindName', json['elementKindName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'elementKindName');
      }
      String oldName;
      if (json.containsKey('oldName')) {
        oldName =
            jsonDecoder.decodeString(jsonPath + '.oldName', json['oldName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'oldName');
      }
      return RenameFeedback(offset, length, elementKindName, oldName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'rename feedback', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    result['elementKindName'] = elementKindName;
    result['oldName'] = oldName;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RenameFeedback) {
      return offset == other.offset &&
          length == other.length &&
          elementKindName == other.elementKindName &&
          oldName == other.oldName;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, elementKindName.hashCode);
    hash = JenkinsSmiHash.combine(hash, oldName.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// rename options
///
/// {
///   "newName": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RenameOptions extends RefactoringOptions {
  String _newName;

  /// The name that the element should have after the refactoring.
  String get newName => _newName;

  /// The name that the element should have after the refactoring.
  set newName(String value) {
    assert(value != null);
    _newName = value;
  }

  RenameOptions(String newName) {
    this.newName = newName;
  }

  factory RenameOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String newName;
      if (json.containsKey('newName')) {
        newName =
            jsonDecoder.decodeString(jsonPath + '.newName', json['newName']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'newName');
      }
      return RenameOptions(newName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'rename options', json);
    }
  }

  factory RenameOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return RenameOptions.fromJson(
        RequestDecoder(request), 'options', refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['newName'] = newName;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RenameOptions) {
      return newName == other.newName;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, newName.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RequestError
///
/// {
///   "code": RequestErrorCode
///   "message": String
///   "stackTrace": optional String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RequestError implements HasToJson {
  RequestErrorCode _code;

  String _message;

  String _stackTrace;

  /// A code that uniquely identifies the error that occurred.
  RequestErrorCode get code => _code;

  /// A code that uniquely identifies the error that occurred.
  set code(RequestErrorCode value) {
    assert(value != null);
    _code = value;
  }

  /// A short description of the error.
  String get message => _message;

  /// A short description of the error.
  set message(String value) {
    assert(value != null);
    _message = value;
  }

  /// The stack trace associated with processing the request, used for
  /// debugging the server.
  String get stackTrace => _stackTrace;

  /// The stack trace associated with processing the request, used for
  /// debugging the server.
  set stackTrace(String value) {
    _stackTrace = value;
  }

  RequestError(RequestErrorCode code, String message, {String stackTrace}) {
    this.code = code;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  factory RequestError.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      RequestErrorCode code;
      if (json.containsKey('code')) {
        code = RequestErrorCode.fromJson(
            jsonDecoder, jsonPath + '.code', json['code']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'code');
      }
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString(jsonPath + '.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String stackTrace;
      if (json.containsKey('stackTrace')) {
        stackTrace = jsonDecoder.decodeString(
            jsonPath + '.stackTrace', json['stackTrace']);
      }
      return RequestError(code, message, stackTrace: stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RequestError', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['code'] = code.toJson();
    result['message'] = message;
    if (stackTrace != null) {
      result['stackTrace'] = stackTrace;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RequestError) {
      return code == other.code &&
          message == other.message &&
          stackTrace == other.stackTrace;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, stackTrace.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RequestErrorCode
///
/// enum {
///   CONTENT_MODIFIED
///   DEBUG_PORT_COULD_NOT_BE_OPENED
///   FILE_NOT_ANALYZED
///   FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED
///   FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET
///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION
///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID
///   FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED
///   FORMAT_INVALID_FILE
///   FORMAT_WITH_ERRORS
///   GET_ERRORS_INVALID_FILE
///   GET_FIXES_INVALID_FILE
///   GET_IMPORTED_ELEMENTS_INVALID_FILE
///   GET_KYTHE_ENTRIES_INVALID_FILE
///   GET_NAVIGATION_INVALID_FILE
///   GET_REACHABLE_SOURCES_INVALID_FILE
///   GET_SIGNATURE_INVALID_FILE
///   GET_SIGNATURE_INVALID_OFFSET
///   GET_SIGNATURE_UNKNOWN_FUNCTION
///   IMPORT_ELEMENTS_INVALID_FILE
///   INVALID_ANALYSIS_ROOT
///   INVALID_EXECUTION_CONTEXT
///   INVALID_FILE_PATH_FORMAT
///   INVALID_OVERLAY_CHANGE
///   INVALID_PARAMETER
///   INVALID_REQUEST
///   ORGANIZE_DIRECTIVES_ERROR
///   REFACTORING_REQUEST_CANCELLED
///   SERVER_ALREADY_STARTED
///   SERVER_ERROR
///   SORT_MEMBERS_INVALID_FILE
///   SORT_MEMBERS_PARSE_ERRORS
///   UNKNOWN_FIX
///   UNKNOWN_REQUEST
///   UNSUPPORTED_FEATURE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RequestErrorCode implements Enum {
  /// An "analysis.getErrors" or "analysis.getNavigation" request could not be
  /// satisfied because the content of the file changed before the requested
  /// results could be computed.
  static const RequestErrorCode CONTENT_MODIFIED =
      RequestErrorCode._('CONTENT_MODIFIED');

  /// The server was unable to open a port for the diagnostic server.
  static const RequestErrorCode DEBUG_PORT_COULD_NOT_BE_OPENED =
      RequestErrorCode._('DEBUG_PORT_COULD_NOT_BE_OPENED');

  /// A request specified a FilePath which does not match a file in an analysis
  /// root, or the requested operation is not available for the file.
  static const RequestErrorCode FILE_NOT_ANALYZED =
      RequestErrorCode._('FILE_NOT_ANALYZED');

  /// A file was change while widget descriptions were being computed.
  static const RequestErrorCode
      FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED =
      RequestErrorCode._('FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED');

  /// The given location does not have a supported widget.
  static const RequestErrorCode FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET =
      RequestErrorCode._('FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET');

  /// The given property expression is invalid, e.g. has a syntax error.
  static const RequestErrorCode
      FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION = RequestErrorCode._(
          'FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION');

  /// The given property identifier is not valid. It might have never been
  /// valid, or a change to code invalidated it, or its TTL was exceeded.
  static const RequestErrorCode FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID =
      RequestErrorCode._('FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID');

  /// The value of the property cannot be removed, for example because the
  /// corresponding constructor argument is required, and the server does not
  /// know what default value to use.
  static const RequestErrorCode FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED =
      RequestErrorCode._('FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED');

  /// An "edit.format" request specified a FilePath which does not match a Dart
  /// file in an analysis root.
  static const RequestErrorCode FORMAT_INVALID_FILE =
      RequestErrorCode._('FORMAT_INVALID_FILE');

  /// An "edit.format" request specified a file that contains syntax errors.
  static const RequestErrorCode FORMAT_WITH_ERRORS =
      RequestErrorCode._('FORMAT_WITH_ERRORS');

  /// An "analysis.getErrors" request specified a FilePath which does not match
  /// a file currently subject to analysis.
  static const RequestErrorCode GET_ERRORS_INVALID_FILE =
      RequestErrorCode._('GET_ERRORS_INVALID_FILE');

  /// An "edit.getFixes" request specified a FilePath which does not match a
  /// file currently subject to analysis.
  static const RequestErrorCode GET_FIXES_INVALID_FILE =
      RequestErrorCode._('GET_FIXES_INVALID_FILE');

  /// An "analysis.getImportedElements" request specified a FilePath that does
  /// not match a file currently subject to analysis.
  static const RequestErrorCode GET_IMPORTED_ELEMENTS_INVALID_FILE =
      RequestErrorCode._('GET_IMPORTED_ELEMENTS_INVALID_FILE');

  /// An "analysis.getKytheEntries" request specified a FilePath that does not
  /// match a file that is currently subject to analysis.
  static const RequestErrorCode GET_KYTHE_ENTRIES_INVALID_FILE =
      RequestErrorCode._('GET_KYTHE_ENTRIES_INVALID_FILE');

  /// An "analysis.getNavigation" request specified a FilePath which does not
  /// match a file currently subject to analysis.
  static const RequestErrorCode GET_NAVIGATION_INVALID_FILE =
      RequestErrorCode._('GET_NAVIGATION_INVALID_FILE');

  /// An "analysis.getReachableSources" request specified a FilePath which does
  /// not match a file currently subject to analysis.
  static const RequestErrorCode GET_REACHABLE_SOURCES_INVALID_FILE =
      RequestErrorCode._('GET_REACHABLE_SOURCES_INVALID_FILE');

  /// An "analysis.getSignature" request specified a FilePath which does not
  /// match a file currently subject to analysis.
  static const RequestErrorCode GET_SIGNATURE_INVALID_FILE =
      RequestErrorCode._('GET_SIGNATURE_INVALID_FILE');

  /// An "analysis.getSignature" request specified an offset which is not a
  /// valid location within for the contents of the file specified FilePath.
  static const RequestErrorCode GET_SIGNATURE_INVALID_OFFSET =
      RequestErrorCode._('GET_SIGNATURE_INVALID_OFFSET');

  /// An "analysis.getSignature" request specified an offset that could not be
  /// matched to a function call.
  static const RequestErrorCode GET_SIGNATURE_UNKNOWN_FUNCTION =
      RequestErrorCode._('GET_SIGNATURE_UNKNOWN_FUNCTION');

  /// An "edit.importElements" request specified a FilePath that does not match
  /// a file currently subject to analysis.
  static const RequestErrorCode IMPORT_ELEMENTS_INVALID_FILE =
      RequestErrorCode._('IMPORT_ELEMENTS_INVALID_FILE');

  /// A path passed as an argument to a request (such as analysis.reanalyze) is
  /// required to be an analysis root, but isn't.
  static const RequestErrorCode INVALID_ANALYSIS_ROOT =
      RequestErrorCode._('INVALID_ANALYSIS_ROOT');

  /// The context root used to create an execution context does not exist.
  static const RequestErrorCode INVALID_EXECUTION_CONTEXT =
      RequestErrorCode._('INVALID_EXECUTION_CONTEXT');

  /// The format of the given file path is invalid, e.g. is not absolute and
  /// normalized.
  static const RequestErrorCode INVALID_FILE_PATH_FORMAT =
      RequestErrorCode._('INVALID_FILE_PATH_FORMAT');

  /// An "analysis.updateContent" request contained a ChangeContentOverlay
  /// object which can't be applied, due to an edit having an offset or length
  /// that is out of range.
  static const RequestErrorCode INVALID_OVERLAY_CHANGE =
      RequestErrorCode._('INVALID_OVERLAY_CHANGE');

  /// One of the method parameters was invalid.
  static const RequestErrorCode INVALID_PARAMETER =
      RequestErrorCode._('INVALID_PARAMETER');

  /// A malformed request was received.
  static const RequestErrorCode INVALID_REQUEST =
      RequestErrorCode._('INVALID_REQUEST');

  /// An "edit.organizeDirectives" request specified a Dart file that cannot be
  /// analyzed. The reason is described in the message.
  static const RequestErrorCode ORGANIZE_DIRECTIVES_ERROR =
      RequestErrorCode._('ORGANIZE_DIRECTIVES_ERROR');

  /// Another refactoring request was received during processing of this one.
  static const RequestErrorCode REFACTORING_REQUEST_CANCELLED =
      RequestErrorCode._('REFACTORING_REQUEST_CANCELLED');

  /// The analysis server has already been started (and hence won't accept new
  /// connections).
  ///
  /// This error is included for future expansion; at present the analysis
  /// server can only speak to one client at a time so this error will never
  /// occur.
  static const RequestErrorCode SERVER_ALREADY_STARTED =
      RequestErrorCode._('SERVER_ALREADY_STARTED');

  /// An internal error occurred in the analysis server. Also see the
  /// server.error notification.
  static const RequestErrorCode SERVER_ERROR =
      RequestErrorCode._('SERVER_ERROR');

  /// An "edit.sortMembers" request specified a FilePath which does not match a
  /// Dart file in an analysis root.
  static const RequestErrorCode SORT_MEMBERS_INVALID_FILE =
      RequestErrorCode._('SORT_MEMBERS_INVALID_FILE');

  /// An "edit.sortMembers" request specified a Dart file that has scan or
  /// parse errors.
  static const RequestErrorCode SORT_MEMBERS_PARSE_ERRORS =
      RequestErrorCode._('SORT_MEMBERS_PARSE_ERRORS');

  /// A dartfix request was received containing the name of a fix which does
  /// not match the name of any known fixes.
  static const RequestErrorCode UNKNOWN_FIX = RequestErrorCode._('UNKNOWN_FIX');

  /// A request was received which the analysis server does not recognize, or
  /// cannot handle in its current configuration.
  static const RequestErrorCode UNKNOWN_REQUEST =
      RequestErrorCode._('UNKNOWN_REQUEST');

  /// The analysis server was requested to perform an action which is not
  /// supported.
  ///
  /// This is a legacy error; it will be removed before the API reaches version
  /// 1.0.
  static const RequestErrorCode UNSUPPORTED_FEATURE =
      RequestErrorCode._('UNSUPPORTED_FEATURE');

  /// A list containing all of the enum values that are defined.
  static const List<RequestErrorCode> VALUES = <RequestErrorCode>[
    CONTENT_MODIFIED,
    DEBUG_PORT_COULD_NOT_BE_OPENED,
    FILE_NOT_ANALYZED,
    FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED,
    FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET,
    FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION,
    FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID,
    FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED,
    FORMAT_INVALID_FILE,
    FORMAT_WITH_ERRORS,
    GET_ERRORS_INVALID_FILE,
    GET_FIXES_INVALID_FILE,
    GET_IMPORTED_ELEMENTS_INVALID_FILE,
    GET_KYTHE_ENTRIES_INVALID_FILE,
    GET_NAVIGATION_INVALID_FILE,
    GET_REACHABLE_SOURCES_INVALID_FILE,
    GET_SIGNATURE_INVALID_FILE,
    GET_SIGNATURE_INVALID_OFFSET,
    GET_SIGNATURE_UNKNOWN_FUNCTION,
    IMPORT_ELEMENTS_INVALID_FILE,
    INVALID_ANALYSIS_ROOT,
    INVALID_EXECUTION_CONTEXT,
    INVALID_FILE_PATH_FORMAT,
    INVALID_OVERLAY_CHANGE,
    INVALID_PARAMETER,
    INVALID_REQUEST,
    ORGANIZE_DIRECTIVES_ERROR,
    REFACTORING_REQUEST_CANCELLED,
    SERVER_ALREADY_STARTED,
    SERVER_ERROR,
    SORT_MEMBERS_INVALID_FILE,
    SORT_MEMBERS_PARSE_ERRORS,
    UNKNOWN_FIX,
    UNKNOWN_REQUEST,
    UNSUPPORTED_FEATURE
  ];

  @override
  final String name;

  const RequestErrorCode._(this.name);

  factory RequestErrorCode(String name) {
    switch (name) {
      case 'CONTENT_MODIFIED':
        return CONTENT_MODIFIED;
      case 'DEBUG_PORT_COULD_NOT_BE_OPENED':
        return DEBUG_PORT_COULD_NOT_BE_OPENED;
      case 'FILE_NOT_ANALYZED':
        return FILE_NOT_ANALYZED;
      case 'FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED':
        return FLUTTER_GET_WIDGET_DESCRIPTION_CONTENT_MODIFIED;
      case 'FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET':
        return FLUTTER_GET_WIDGET_DESCRIPTION_NO_WIDGET;
      case 'FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION':
        return FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_EXPRESSION;
      case 'FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID':
        return FLUTTER_SET_WIDGET_PROPERTY_VALUE_INVALID_ID;
      case 'FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED':
        return FLUTTER_SET_WIDGET_PROPERTY_VALUE_IS_REQUIRED;
      case 'FORMAT_INVALID_FILE':
        return FORMAT_INVALID_FILE;
      case 'FORMAT_WITH_ERRORS':
        return FORMAT_WITH_ERRORS;
      case 'GET_ERRORS_INVALID_FILE':
        return GET_ERRORS_INVALID_FILE;
      case 'GET_FIXES_INVALID_FILE':
        return GET_FIXES_INVALID_FILE;
      case 'GET_IMPORTED_ELEMENTS_INVALID_FILE':
        return GET_IMPORTED_ELEMENTS_INVALID_FILE;
      case 'GET_KYTHE_ENTRIES_INVALID_FILE':
        return GET_KYTHE_ENTRIES_INVALID_FILE;
      case 'GET_NAVIGATION_INVALID_FILE':
        return GET_NAVIGATION_INVALID_FILE;
      case 'GET_REACHABLE_SOURCES_INVALID_FILE':
        return GET_REACHABLE_SOURCES_INVALID_FILE;
      case 'GET_SIGNATURE_INVALID_FILE':
        return GET_SIGNATURE_INVALID_FILE;
      case 'GET_SIGNATURE_INVALID_OFFSET':
        return GET_SIGNATURE_INVALID_OFFSET;
      case 'GET_SIGNATURE_UNKNOWN_FUNCTION':
        return GET_SIGNATURE_UNKNOWN_FUNCTION;
      case 'IMPORT_ELEMENTS_INVALID_FILE':
        return IMPORT_ELEMENTS_INVALID_FILE;
      case 'INVALID_ANALYSIS_ROOT':
        return INVALID_ANALYSIS_ROOT;
      case 'INVALID_EXECUTION_CONTEXT':
        return INVALID_EXECUTION_CONTEXT;
      case 'INVALID_FILE_PATH_FORMAT':
        return INVALID_FILE_PATH_FORMAT;
      case 'INVALID_OVERLAY_CHANGE':
        return INVALID_OVERLAY_CHANGE;
      case 'INVALID_PARAMETER':
        return INVALID_PARAMETER;
      case 'INVALID_REQUEST':
        return INVALID_REQUEST;
      case 'ORGANIZE_DIRECTIVES_ERROR':
        return ORGANIZE_DIRECTIVES_ERROR;
      case 'REFACTORING_REQUEST_CANCELLED':
        return REFACTORING_REQUEST_CANCELLED;
      case 'SERVER_ALREADY_STARTED':
        return SERVER_ALREADY_STARTED;
      case 'SERVER_ERROR':
        return SERVER_ERROR;
      case 'SORT_MEMBERS_INVALID_FILE':
        return SORT_MEMBERS_INVALID_FILE;
      case 'SORT_MEMBERS_PARSE_ERRORS':
        return SORT_MEMBERS_PARSE_ERRORS;
      case 'UNKNOWN_FIX':
        return UNKNOWN_FIX;
      case 'UNKNOWN_REQUEST':
        return UNKNOWN_REQUEST;
      case 'UNSUPPORTED_FEATURE':
        return UNSUPPORTED_FEATURE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RequestErrorCode.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return RequestErrorCode(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'RequestErrorCode', json);
  }

  @override
  String toString() => 'RequestErrorCode.$name';

  String toJson() => name;
}

/// RuntimeCompletionExpression
///
/// {
///   "offset": int
///   "length": int
///   "type": optional RuntimeCompletionExpressionType
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionExpression implements HasToJson {
  int _offset;

  int _length;

  RuntimeCompletionExpressionType _type;

  /// The offset of the expression in the code for completion.
  int get offset => _offset;

  /// The offset of the expression in the code for completion.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// The length of the expression in the code for completion.
  int get length => _length;

  /// The length of the expression in the code for completion.
  set length(int value) {
    assert(value != null);
    _length = value;
  }

  /// When the expression is sent from the server to the client, the type is
  /// omitted. The client should fill the type when it sends the request to the
  /// server again.
  RuntimeCompletionExpressionType get type => _type;

  /// When the expression is sent from the server to the client, the type is
  /// omitted. The client should fill the type when it sends the request to the
  /// server again.
  set type(RuntimeCompletionExpressionType value) {
    _type = value;
  }

  RuntimeCompletionExpression(int offset, int length,
      {RuntimeCompletionExpressionType type}) {
    this.offset = offset;
    this.length = length;
    this.type = type;
  }

  factory RuntimeCompletionExpression.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      int length;
      if (json.containsKey('length')) {
        length = jsonDecoder.decodeInt(jsonPath + '.length', json['length']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'length');
      }
      RuntimeCompletionExpressionType type;
      if (json.containsKey('type')) {
        type = RuntimeCompletionExpressionType.fromJson(
            jsonDecoder, jsonPath + '.type', json['type']);
      }
      return RuntimeCompletionExpression(offset, length, type: type);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RuntimeCompletionExpression', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['offset'] = offset;
    result['length'] = length;
    if (type != null) {
      result['type'] = type.toJson();
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RuntimeCompletionExpression) {
      return offset == other.offset &&
          length == other.length &&
          type == other.type;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RuntimeCompletionExpressionType
///
/// {
///   "libraryPath": optional FilePath
///   "kind": RuntimeCompletionExpressionTypeKind
///   "name": optional String
///   "typeArguments": optional List<RuntimeCompletionExpressionType>
///   "returnType": optional RuntimeCompletionExpressionType
///   "parameterTypes": optional List<RuntimeCompletionExpressionType>
///   "parameterNames": optional List<String>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionExpressionType implements HasToJson {
  String _libraryPath;

  RuntimeCompletionExpressionTypeKind _kind;

  String _name;

  List<RuntimeCompletionExpressionType> _typeArguments;

  RuntimeCompletionExpressionType _returnType;

  List<RuntimeCompletionExpressionType> _parameterTypes;

  List<String> _parameterNames;

  /// The path of the library that has this type. Omitted if the type is not
  /// declared in any library, e.g. "dynamic", or "void".
  String get libraryPath => _libraryPath;

  /// The path of the library that has this type. Omitted if the type is not
  /// declared in any library, e.g. "dynamic", or "void".
  set libraryPath(String value) {
    _libraryPath = value;
  }

  /// The kind of the type.
  RuntimeCompletionExpressionTypeKind get kind => _kind;

  /// The kind of the type.
  set kind(RuntimeCompletionExpressionTypeKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The name of the type. Omitted if the type does not have a name, e.g. an
  /// inline function type.
  String get name => _name;

  /// The name of the type. Omitted if the type does not have a name, e.g. an
  /// inline function type.
  set name(String value) {
    _name = value;
  }

  /// The type arguments of the type. Omitted if the type does not have type
  /// parameters.
  List<RuntimeCompletionExpressionType> get typeArguments => _typeArguments;

  /// The type arguments of the type. Omitted if the type does not have type
  /// parameters.
  set typeArguments(List<RuntimeCompletionExpressionType> value) {
    _typeArguments = value;
  }

  /// If the type is a function type, the return type of the function. Omitted
  /// if the type is not a function type.
  RuntimeCompletionExpressionType get returnType => _returnType;

  /// If the type is a function type, the return type of the function. Omitted
  /// if the type is not a function type.
  set returnType(RuntimeCompletionExpressionType value) {
    _returnType = value;
  }

  /// If the type is a function type, the types of the function parameters of
  /// all kinds - required, optional positional, and optional named. Omitted if
  /// the type is not a function type.
  List<RuntimeCompletionExpressionType> get parameterTypes => _parameterTypes;

  /// If the type is a function type, the types of the function parameters of
  /// all kinds - required, optional positional, and optional named. Omitted if
  /// the type is not a function type.
  set parameterTypes(List<RuntimeCompletionExpressionType> value) {
    _parameterTypes = value;
  }

  /// If the type is a function type, the names of the function parameters of
  /// all kinds - required, optional positional, and optional named. The names
  /// of positional parameters are empty strings. Omitted if the type is not a
  /// function type.
  List<String> get parameterNames => _parameterNames;

  /// If the type is a function type, the names of the function parameters of
  /// all kinds - required, optional positional, and optional named. The names
  /// of positional parameters are empty strings. Omitted if the type is not a
  /// function type.
  set parameterNames(List<String> value) {
    _parameterNames = value;
  }

  RuntimeCompletionExpressionType(RuntimeCompletionExpressionTypeKind kind,
      {String libraryPath,
      String name,
      List<RuntimeCompletionExpressionType> typeArguments,
      RuntimeCompletionExpressionType returnType,
      List<RuntimeCompletionExpressionType> parameterTypes,
      List<String> parameterNames}) {
    this.libraryPath = libraryPath;
    this.kind = kind;
    this.name = name;
    this.typeArguments = typeArguments;
    this.returnType = returnType;
    this.parameterTypes = parameterTypes;
    this.parameterNames = parameterNames;
  }

  factory RuntimeCompletionExpressionType.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String libraryPath;
      if (json.containsKey('libraryPath')) {
        libraryPath = jsonDecoder.decodeString(
            jsonPath + '.libraryPath', json['libraryPath']);
      }
      RuntimeCompletionExpressionTypeKind kind;
      if (json.containsKey('kind')) {
        kind = RuntimeCompletionExpressionTypeKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      }
      List<RuntimeCompletionExpressionType> typeArguments;
      if (json.containsKey('typeArguments')) {
        typeArguments = jsonDecoder.decodeList(
            jsonPath + '.typeArguments',
            json['typeArguments'],
            (String jsonPath, Object json) =>
                RuntimeCompletionExpressionType.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      RuntimeCompletionExpressionType returnType;
      if (json.containsKey('returnType')) {
        returnType = RuntimeCompletionExpressionType.fromJson(
            jsonDecoder, jsonPath + '.returnType', json['returnType']);
      }
      List<RuntimeCompletionExpressionType> parameterTypes;
      if (json.containsKey('parameterTypes')) {
        parameterTypes = jsonDecoder.decodeList(
            jsonPath + '.parameterTypes',
            json['parameterTypes'],
            (String jsonPath, Object json) =>
                RuntimeCompletionExpressionType.fromJson(
                    jsonDecoder, jsonPath, json));
      }
      List<String> parameterNames;
      if (json.containsKey('parameterNames')) {
        parameterNames = jsonDecoder.decodeList(jsonPath + '.parameterNames',
            json['parameterNames'], jsonDecoder.decodeString);
      }
      return RuntimeCompletionExpressionType(kind,
          libraryPath: libraryPath,
          name: name,
          typeArguments: typeArguments,
          returnType: returnType,
          parameterTypes: parameterTypes,
          parameterNames: parameterNames);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'RuntimeCompletionExpressionType', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (libraryPath != null) {
      result['libraryPath'] = libraryPath;
    }
    result['kind'] = kind.toJson();
    if (name != null) {
      result['name'] = name;
    }
    if (typeArguments != null) {
      result['typeArguments'] = typeArguments
          .map((RuntimeCompletionExpressionType value) => value.toJson())
          .toList();
    }
    if (returnType != null) {
      result['returnType'] = returnType.toJson();
    }
    if (parameterTypes != null) {
      result['parameterTypes'] = parameterTypes
          .map((RuntimeCompletionExpressionType value) => value.toJson())
          .toList();
    }
    if (parameterNames != null) {
      result['parameterNames'] = parameterNames;
    }
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RuntimeCompletionExpressionType) {
      return libraryPath == other.libraryPath &&
          kind == other.kind &&
          name == other.name &&
          listEqual(
              typeArguments,
              other.typeArguments,
              (RuntimeCompletionExpressionType a,
                      RuntimeCompletionExpressionType b) =>
                  a == b) &&
          returnType == other.returnType &&
          listEqual(
              parameterTypes,
              other.parameterTypes,
              (RuntimeCompletionExpressionType a,
                      RuntimeCompletionExpressionType b) =>
                  a == b) &&
          listEqual(parameterNames, other.parameterNames,
              (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, libraryPath.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, typeArguments.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterTypes.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterNames.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// RuntimeCompletionExpressionTypeKind
///
/// enum {
///   DYNAMIC
///   FUNCTION
///   INTERFACE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionExpressionTypeKind implements Enum {
  static const RuntimeCompletionExpressionTypeKind DYNAMIC =
      RuntimeCompletionExpressionTypeKind._('DYNAMIC');

  static const RuntimeCompletionExpressionTypeKind FUNCTION =
      RuntimeCompletionExpressionTypeKind._('FUNCTION');

  static const RuntimeCompletionExpressionTypeKind INTERFACE =
      RuntimeCompletionExpressionTypeKind._('INTERFACE');

  /// A list containing all of the enum values that are defined.
  static const List<RuntimeCompletionExpressionTypeKind> VALUES =
      <RuntimeCompletionExpressionTypeKind>[DYNAMIC, FUNCTION, INTERFACE];

  @override
  final String name;

  const RuntimeCompletionExpressionTypeKind._(this.name);

  factory RuntimeCompletionExpressionTypeKind(String name) {
    switch (name) {
      case 'DYNAMIC':
        return DYNAMIC;
      case 'FUNCTION':
        return FUNCTION;
      case 'INTERFACE':
        return INTERFACE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory RuntimeCompletionExpressionTypeKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return RuntimeCompletionExpressionTypeKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(
        jsonPath, 'RuntimeCompletionExpressionTypeKind', json);
  }

  @override
  String toString() => 'RuntimeCompletionExpressionTypeKind.$name';

  String toJson() => name;
}

/// RuntimeCompletionVariable
///
/// {
///   "name": String
///   "type": RuntimeCompletionExpressionType
/// }
///
/// Clients may not extend, implement or mix-in this class.
class RuntimeCompletionVariable implements HasToJson {
  String _name;

  RuntimeCompletionExpressionType _type;

  /// The name of the variable. The name "this" has a special meaning and is
  /// used as an implicit target for runtime completion, and in explicit "this"
  /// references.
  String get name => _name;

  /// The name of the variable. The name "this" has a special meaning and is
  /// used as an implicit target for runtime completion, and in explicit "this"
  /// references.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  /// The type of the variable.
  RuntimeCompletionExpressionType get type => _type;

  /// The type of the variable.
  set type(RuntimeCompletionExpressionType value) {
    assert(value != null);
    _type = value;
  }

  RuntimeCompletionVariable(String name, RuntimeCompletionExpressionType type) {
    this.name = name;
    this.type = type;
  }

  factory RuntimeCompletionVariable.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      RuntimeCompletionExpressionType type;
      if (json.containsKey('type')) {
        type = RuntimeCompletionExpressionType.fromJson(
            jsonDecoder, jsonPath + '.type', json['type']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'type');
      }
      return RuntimeCompletionVariable(name, type);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'RuntimeCompletionVariable', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    result['type'] = type.toJson();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RuntimeCompletionVariable) {
      return name == other.name && type == other.type;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findElementReferences params
///
/// {
///   "file": FilePath
///   "offset": int
///   "includePotential": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindElementReferencesParams implements RequestParams {
  String _file;

  int _offset;

  bool _includePotential;

  /// The file containing the declaration of or reference to the element used
  /// to define the search.
  String get file => _file;

  /// The file containing the declaration of or reference to the element used
  /// to define the search.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset within the file of the declaration of or reference to the
  /// element.
  int get offset => _offset;

  /// The offset within the file of the declaration of or reference to the
  /// element.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// True if potential matches are to be included in the results.
  bool get includePotential => _includePotential;

  /// True if potential matches are to be included in the results.
  set includePotential(bool value) {
    assert(value != null);
    _includePotential = value;
  }

  SearchFindElementReferencesParams(
      String file, int offset, bool includePotential) {
    this.file = file;
    this.offset = offset;
    this.includePotential = includePotential;
  }

  factory SearchFindElementReferencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      bool includePotential;
      if (json.containsKey('includePotential')) {
        includePotential = jsonDecoder.decodeBool(
            jsonPath + '.includePotential', json['includePotential']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'includePotential');
      }
      return SearchFindElementReferencesParams(file, offset, includePotential);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findElementReferences params', json);
    }
  }

  factory SearchFindElementReferencesParams.fromRequest(Request request) {
    return SearchFindElementReferencesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    result['includePotential'] = includePotential;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findElementReferences', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindElementReferencesParams) {
      return file == other.file &&
          offset == other.offset &&
          includePotential == other.includePotential;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, includePotential.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findElementReferences result
///
/// {
///   "id": optional SearchId
///   "element": optional Element
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindElementReferencesResult implements ResponseResult {
  String _id;

  Element _element;

  /// The identifier used to associate results with this search request.
  ///
  /// If no element was found at the given location, this field will be absent,
  /// and no results will be reported via the search.results notification.
  String get id => _id;

  /// The identifier used to associate results with this search request.
  ///
  /// If no element was found at the given location, this field will be absent,
  /// and no results will be reported via the search.results notification.
  set id(String value) {
    _id = value;
  }

  /// The element referenced or defined at the given offset and whose
  /// references will be returned in the search results.
  ///
  /// If no element was found at the given location, this field will be absent.
  Element get element => _element;

  /// The element referenced or defined at the given offset and whose
  /// references will be returned in the search results.
  ///
  /// If no element was found at the given location, this field will be absent.
  set element(Element value) {
    _element = value;
  }

  SearchFindElementReferencesResult({String id, Element element}) {
    this.id = id;
    this.element = element;
  }

  factory SearchFindElementReferencesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      }
      Element element;
      if (json.containsKey('element')) {
        element = Element.fromJson(
            jsonDecoder, jsonPath + '.element', json['element']);
      }
      return SearchFindElementReferencesResult(id: id, element: element);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findElementReferences result', json);
    }
  }

  factory SearchFindElementReferencesResult.fromResponse(Response response) {
    return SearchFindElementReferencesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (id != null) {
      result['id'] = id;
    }
    if (element != null) {
      result['element'] = element.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindElementReferencesResult) {
      return id == other.id && element == other.element;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findMemberDeclarations params
///
/// {
///   "name": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberDeclarationsParams implements RequestParams {
  String _name;

  /// The name of the declarations to be found.
  String get name => _name;

  /// The name of the declarations to be found.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  SearchFindMemberDeclarationsParams(String name) {
    this.name = name;
  }

  factory SearchFindMemberDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      return SearchFindMemberDeclarationsParams(name);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberDeclarations params', json);
    }
  }

  factory SearchFindMemberDeclarationsParams.fromRequest(Request request) {
    return SearchFindMemberDeclarationsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findMemberDeclarations', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberDeclarationsParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findMemberDeclarations result
///
/// {
///   "id": SearchId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberDeclarationsResult implements ResponseResult {
  String _id;

  /// The identifier used to associate results with this search request.
  String get id => _id;

  /// The identifier used to associate results with this search request.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  SearchFindMemberDeclarationsResult(String id) {
    this.id = id;
  }

  factory SearchFindMemberDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return SearchFindMemberDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberDeclarations result', json);
    }
  }

  factory SearchFindMemberDeclarationsResult.fromResponse(Response response) {
    return SearchFindMemberDeclarationsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findMemberReferences params
///
/// {
///   "name": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberReferencesParams implements RequestParams {
  String _name;

  /// The name of the references to be found.
  String get name => _name;

  /// The name of the references to be found.
  set name(String value) {
    assert(value != null);
    _name = value;
  }

  SearchFindMemberReferencesParams(String name) {
    this.name = name;
  }

  factory SearchFindMemberReferencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String name;
      if (json.containsKey('name')) {
        name = jsonDecoder.decodeString(jsonPath + '.name', json['name']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'name');
      }
      return SearchFindMemberReferencesParams(name);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberReferences params', json);
    }
  }

  factory SearchFindMemberReferencesParams.fromRequest(Request request) {
    return SearchFindMemberReferencesParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['name'] = name;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findMemberReferences', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberReferencesParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findMemberReferences result
///
/// {
///   "id": SearchId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindMemberReferencesResult implements ResponseResult {
  String _id;

  /// The identifier used to associate results with this search request.
  String get id => _id;

  /// The identifier used to associate results with this search request.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  SearchFindMemberReferencesResult(String id) {
    this.id = id;
  }

  factory SearchFindMemberReferencesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return SearchFindMemberReferencesResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findMemberReferences result', json);
    }
  }

  factory SearchFindMemberReferencesResult.fromResponse(Response response) {
    return SearchFindMemberReferencesResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberReferencesResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findTopLevelDeclarations params
///
/// {
///   "pattern": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindTopLevelDeclarationsParams implements RequestParams {
  String _pattern;

  /// The regular expression used to match the names of the declarations to be
  /// found.
  String get pattern => _pattern;

  /// The regular expression used to match the names of the declarations to be
  /// found.
  set pattern(String value) {
    assert(value != null);
    _pattern = value;
  }

  SearchFindTopLevelDeclarationsParams(String pattern) {
    this.pattern = pattern;
  }

  factory SearchFindTopLevelDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String pattern;
      if (json.containsKey('pattern')) {
        pattern =
            jsonDecoder.decodeString(jsonPath + '.pattern', json['pattern']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'pattern');
      }
      return SearchFindTopLevelDeclarationsParams(pattern);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findTopLevelDeclarations params', json);
    }
  }

  factory SearchFindTopLevelDeclarationsParams.fromRequest(Request request) {
    return SearchFindTopLevelDeclarationsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['pattern'] = pattern;
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.findTopLevelDeclarations', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindTopLevelDeclarationsParams) {
      return pattern == other.pattern;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, pattern.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.findTopLevelDeclarations result
///
/// {
///   "id": SearchId
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchFindTopLevelDeclarationsResult implements ResponseResult {
  String _id;

  /// The identifier used to associate results with this search request.
  String get id => _id;

  /// The identifier used to associate results with this search request.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  SearchFindTopLevelDeclarationsResult(String id) {
    this.id = id;
  }

  factory SearchFindTopLevelDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      return SearchFindTopLevelDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.findTopLevelDeclarations result', json);
    }
  }

  factory SearchFindTopLevelDeclarationsResult.fromResponse(Response response) {
    return SearchFindTopLevelDeclarationsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindTopLevelDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.getElementDeclarations params
///
/// {
///   "file": optional FilePath
///   "pattern": optional String
///   "maxResults": optional int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetElementDeclarationsParams implements RequestParams {
  String _file;

  String _pattern;

  int _maxResults;

  /// If this field is provided, return only declarations in this file. If this
  /// field is missing, return declarations in all files.
  String get file => _file;

  /// If this field is provided, return only declarations in this file. If this
  /// field is missing, return declarations in all files.
  set file(String value) {
    _file = value;
  }

  /// The regular expression used to match the names of declarations. If this
  /// field is missing, return all declarations.
  String get pattern => _pattern;

  /// The regular expression used to match the names of declarations. If this
  /// field is missing, return all declarations.
  set pattern(String value) {
    _pattern = value;
  }

  /// The maximum number of declarations to return. If this field is missing,
  /// return all matching declarations.
  int get maxResults => _maxResults;

  /// The maximum number of declarations to return. If this field is missing,
  /// return all matching declarations.
  set maxResults(int value) {
    _maxResults = value;
  }

  SearchGetElementDeclarationsParams(
      {String file, String pattern, int maxResults}) {
    this.file = file;
    this.pattern = pattern;
    this.maxResults = maxResults;
  }

  factory SearchGetElementDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      }
      String pattern;
      if (json.containsKey('pattern')) {
        pattern =
            jsonDecoder.decodeString(jsonPath + '.pattern', json['pattern']);
      }
      int maxResults;
      if (json.containsKey('maxResults')) {
        maxResults =
            jsonDecoder.decodeInt(jsonPath + '.maxResults', json['maxResults']);
      }
      return SearchGetElementDeclarationsParams(
          file: file, pattern: pattern, maxResults: maxResults);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getElementDeclarations params', json);
    }
  }

  factory SearchGetElementDeclarationsParams.fromRequest(Request request) {
    return SearchGetElementDeclarationsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (file != null) {
      result['file'] = file;
    }
    if (pattern != null) {
      result['pattern'] = pattern;
    }
    if (maxResults != null) {
      result['maxResults'] = maxResults;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.getElementDeclarations', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetElementDeclarationsParams) {
      return file == other.file &&
          pattern == other.pattern &&
          maxResults == other.maxResults;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, pattern.hashCode);
    hash = JenkinsSmiHash.combine(hash, maxResults.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.getElementDeclarations result
///
/// {
///   "declarations": List<ElementDeclaration>
///   "files": List<FilePath>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetElementDeclarationsResult implements ResponseResult {
  List<ElementDeclaration> _declarations;

  List<String> _files;

  /// The list of declarations.
  List<ElementDeclaration> get declarations => _declarations;

  /// The list of declarations.
  set declarations(List<ElementDeclaration> value) {
    assert(value != null);
    _declarations = value;
  }

  /// The list of the paths of files with declarations.
  List<String> get files => _files;

  /// The list of the paths of files with declarations.
  set files(List<String> value) {
    assert(value != null);
    _files = value;
  }

  SearchGetElementDeclarationsResult(
      List<ElementDeclaration> declarations, List<String> files) {
    this.declarations = declarations;
    this.files = files;
  }

  factory SearchGetElementDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<ElementDeclaration> declarations;
      if (json.containsKey('declarations')) {
        declarations = jsonDecoder.decodeList(
            jsonPath + '.declarations',
            json['declarations'],
            (String jsonPath, Object json) =>
                ElementDeclaration.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'declarations');
      }
      List<String> files;
      if (json.containsKey('files')) {
        files = jsonDecoder.decodeList(
            jsonPath + '.files', json['files'], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'files');
      }
      return SearchGetElementDeclarationsResult(declarations, files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getElementDeclarations result', json);
    }
  }

  factory SearchGetElementDeclarationsResult.fromResponse(Response response) {
    return SearchGetElementDeclarationsResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['declarations'] =
        declarations.map((ElementDeclaration value) => value.toJson()).toList();
    result['files'] = files;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetElementDeclarationsResult) {
      return listEqual(declarations, other.declarations,
              (ElementDeclaration a, ElementDeclaration b) => a == b) &&
          listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, declarations.hashCode);
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.getTypeHierarchy params
///
/// {
///   "file": FilePath
///   "offset": int
///   "superOnly": optional bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetTypeHierarchyParams implements RequestParams {
  String _file;

  int _offset;

  bool _superOnly;

  /// The file containing the declaration or reference to the type for which a
  /// hierarchy is being requested.
  String get file => _file;

  /// The file containing the declaration or reference to the type for which a
  /// hierarchy is being requested.
  set file(String value) {
    assert(value != null);
    _file = value;
  }

  /// The offset of the name of the type within the file.
  int get offset => _offset;

  /// The offset of the name of the type within the file.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  /// True if the client is only requesting superclasses and interfaces
  /// hierarchy.
  bool get superOnly => _superOnly;

  /// True if the client is only requesting superclasses and interfaces
  /// hierarchy.
  set superOnly(bool value) {
    _superOnly = value;
  }

  SearchGetTypeHierarchyParams(String file, int offset, {bool superOnly}) {
    this.file = file;
    this.offset = offset;
    this.superOnly = superOnly;
  }

  factory SearchGetTypeHierarchyParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String file;
      if (json.containsKey('file')) {
        file = jsonDecoder.decodeString(jsonPath + '.file', json['file']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'file');
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      bool superOnly;
      if (json.containsKey('superOnly')) {
        superOnly =
            jsonDecoder.decodeBool(jsonPath + '.superOnly', json['superOnly']);
      }
      return SearchGetTypeHierarchyParams(file, offset, superOnly: superOnly);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getTypeHierarchy params', json);
    }
  }

  factory SearchGetTypeHierarchyParams.fromRequest(Request request) {
    return SearchGetTypeHierarchyParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['file'] = file;
    result['offset'] = offset;
    if (superOnly != null) {
      result['superOnly'] = superOnly;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'search.getTypeHierarchy', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetTypeHierarchyParams) {
      return file == other.file &&
          offset == other.offset &&
          superOnly == other.superOnly;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, superOnly.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// search.getTypeHierarchy result
///
/// {
///   "hierarchyItems": optional List<TypeHierarchyItem>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchGetTypeHierarchyResult implements ResponseResult {
  List<TypeHierarchyItem> _hierarchyItems;

  /// A list of the types in the requested hierarchy. The first element of the
  /// list is the item representing the type for which the hierarchy was
  /// requested. The index of other elements of the list is unspecified, but
  /// correspond to the integers used to reference supertype and subtype items
  /// within the items.
  ///
  /// This field will be absent if the code at the given file and offset does
  /// not represent a type, or if the file has not been sufficiently analyzed
  /// to allow a type hierarchy to be produced.
  List<TypeHierarchyItem> get hierarchyItems => _hierarchyItems;

  /// A list of the types in the requested hierarchy. The first element of the
  /// list is the item representing the type for which the hierarchy was
  /// requested. The index of other elements of the list is unspecified, but
  /// correspond to the integers used to reference supertype and subtype items
  /// within the items.
  ///
  /// This field will be absent if the code at the given file and offset does
  /// not represent a type, or if the file has not been sufficiently analyzed
  /// to allow a type hierarchy to be produced.
  set hierarchyItems(List<TypeHierarchyItem> value) {
    _hierarchyItems = value;
  }

  SearchGetTypeHierarchyResult({List<TypeHierarchyItem> hierarchyItems}) {
    this.hierarchyItems = hierarchyItems;
  }

  factory SearchGetTypeHierarchyResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<TypeHierarchyItem> hierarchyItems;
      if (json.containsKey('hierarchyItems')) {
        hierarchyItems = jsonDecoder.decodeList(
            jsonPath + '.hierarchyItems',
            json['hierarchyItems'],
            (String jsonPath, Object json) =>
                TypeHierarchyItem.fromJson(jsonDecoder, jsonPath, json));
      }
      return SearchGetTypeHierarchyResult(hierarchyItems: hierarchyItems);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'search.getTypeHierarchy result', json);
    }
  }

  factory SearchGetTypeHierarchyResult.fromResponse(Response response) {
    return SearchGetTypeHierarchyResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (hierarchyItems != null) {
      result['hierarchyItems'] = hierarchyItems
          .map((TypeHierarchyItem value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchGetTypeHierarchyResult) {
      return listEqual(hierarchyItems, other.hierarchyItems,
          (TypeHierarchyItem a, TypeHierarchyItem b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, hierarchyItems.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// SearchResult
///
/// {
///   "location": Location
///   "kind": SearchResultKind
///   "isPotential": bool
///   "path": List<Element>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchResult implements HasToJson {
  Location _location;

  SearchResultKind _kind;

  bool _isPotential;

  List<Element> _path;

  /// The location of the code that matched the search criteria.
  Location get location => _location;

  /// The location of the code that matched the search criteria.
  set location(Location value) {
    assert(value != null);
    _location = value;
  }

  /// The kind of element that was found or the kind of reference that was
  /// found.
  SearchResultKind get kind => _kind;

  /// The kind of element that was found or the kind of reference that was
  /// found.
  set kind(SearchResultKind value) {
    assert(value != null);
    _kind = value;
  }

  /// True if the result is a potential match but cannot be confirmed to be a
  /// match. For example, if all references to a method m defined in some class
  /// were requested, and a reference to a method m from an unknown class were
  /// found, it would be marked as being a potential match.
  bool get isPotential => _isPotential;

  /// True if the result is a potential match but cannot be confirmed to be a
  /// match. For example, if all references to a method m defined in some class
  /// were requested, and a reference to a method m from an unknown class were
  /// found, it would be marked as being a potential match.
  set isPotential(bool value) {
    assert(value != null);
    _isPotential = value;
  }

  /// The elements that contain the result, starting with the most immediately
  /// enclosing ancestor and ending with the library.
  List<Element> get path => _path;

  /// The elements that contain the result, starting with the most immediately
  /// enclosing ancestor and ending with the library.
  set path(List<Element> value) {
    assert(value != null);
    _path = value;
  }

  SearchResult(Location location, SearchResultKind kind, bool isPotential,
      List<Element> path) {
    this.location = location;
    this.kind = kind;
    this.isPotential = isPotential;
    this.path = path;
  }

  factory SearchResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Location location;
      if (json.containsKey('location')) {
        location = Location.fromJson(
            jsonDecoder, jsonPath + '.location', json['location']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'location');
      }
      SearchResultKind kind;
      if (json.containsKey('kind')) {
        kind = SearchResultKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      bool isPotential;
      if (json.containsKey('isPotential')) {
        isPotential = jsonDecoder.decodeBool(
            jsonPath + '.isPotential', json['isPotential']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isPotential');
      }
      List<Element> path;
      if (json.containsKey('path')) {
        path = jsonDecoder.decodeList(
            jsonPath + '.path',
            json['path'],
            (String jsonPath, Object json) =>
                Element.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'path');
      }
      return SearchResult(location, kind, isPotential, path);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'SearchResult', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['location'] = location.toJson();
    result['kind'] = kind.toJson();
    result['isPotential'] = isPotential;
    result['path'] = path.map((Element value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchResult) {
      return location == other.location &&
          kind == other.kind &&
          isPotential == other.isPotential &&
          listEqual(path, other.path, (Element a, Element b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, isPotential.hashCode);
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// SearchResultKind
///
/// enum {
///   DECLARATION
///   INVOCATION
///   READ
///   READ_WRITE
///   REFERENCE
///   UNKNOWN
///   WRITE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchResultKind implements Enum {
  /// The declaration of an element.
  static const SearchResultKind DECLARATION = SearchResultKind._('DECLARATION');

  /// The invocation of a function or method.
  static const SearchResultKind INVOCATION = SearchResultKind._('INVOCATION');

  /// A reference to a field, parameter or variable where it is being read.
  static const SearchResultKind READ = SearchResultKind._('READ');

  /// A reference to a field, parameter or variable where it is being read and
  /// written.
  static const SearchResultKind READ_WRITE = SearchResultKind._('READ_WRITE');

  /// A reference to an element.
  static const SearchResultKind REFERENCE = SearchResultKind._('REFERENCE');

  /// Some other kind of search result.
  static const SearchResultKind UNKNOWN = SearchResultKind._('UNKNOWN');

  /// A reference to a field, parameter or variable where it is being written.
  static const SearchResultKind WRITE = SearchResultKind._('WRITE');

  /// A list containing all of the enum values that are defined.
  static const List<SearchResultKind> VALUES = <SearchResultKind>[
    DECLARATION,
    INVOCATION,
    READ,
    READ_WRITE,
    REFERENCE,
    UNKNOWN,
    WRITE
  ];

  @override
  final String name;

  const SearchResultKind._(this.name);

  factory SearchResultKind(String name) {
    switch (name) {
      case 'DECLARATION':
        return DECLARATION;
      case 'INVOCATION':
        return INVOCATION;
      case 'READ':
        return READ;
      case 'READ_WRITE':
        return READ_WRITE;
      case 'REFERENCE':
        return REFERENCE;
      case 'UNKNOWN':
        return UNKNOWN;
      case 'WRITE':
        return WRITE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory SearchResultKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return SearchResultKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'SearchResultKind', json);
  }

  @override
  String toString() => 'SearchResultKind.$name';

  String toJson() => name;
}

/// search.results params
///
/// {
///   "id": SearchId
///   "results": List<SearchResult>
///   "isLast": bool
/// }
///
/// Clients may not extend, implement or mix-in this class.
class SearchResultsParams implements HasToJson {
  String _id;

  List<SearchResult> _results;

  bool _isLast;

  /// The id associated with the search.
  String get id => _id;

  /// The id associated with the search.
  set id(String value) {
    assert(value != null);
    _id = value;
  }

  /// The search results being reported.
  List<SearchResult> get results => _results;

  /// The search results being reported.
  set results(List<SearchResult> value) {
    assert(value != null);
    _results = value;
  }

  /// True if this is that last set of results that will be returned for the
  /// indicated search.
  bool get isLast => _isLast;

  /// True if this is that last set of results that will be returned for the
  /// indicated search.
  set isLast(bool value) {
    assert(value != null);
    _isLast = value;
  }

  SearchResultsParams(String id, List<SearchResult> results, bool isLast) {
    this.id = id;
    this.results = results;
    this.isLast = isLast;
  }

  factory SearchResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String id;
      if (json.containsKey('id')) {
        id = jsonDecoder.decodeString(jsonPath + '.id', json['id']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'id');
      }
      List<SearchResult> results;
      if (json.containsKey('results')) {
        results = jsonDecoder.decodeList(
            jsonPath + '.results',
            json['results'],
            (String jsonPath, Object json) =>
                SearchResult.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'results');
      }
      bool isLast;
      if (json.containsKey('isLast')) {
        isLast = jsonDecoder.decodeBool(jsonPath + '.isLast', json['isLast']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isLast');
      }
      return SearchResultsParams(id, results, isLast);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'search.results params', json);
    }
  }

  factory SearchResultsParams.fromNotification(Notification notification) {
    return SearchResultsParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['id'] = id;
    result['results'] =
        results.map((SearchResult value) => value.toJson()).toList();
    result['isLast'] = isLast;
    return result;
  }

  Notification toNotification() {
    return Notification('search.results', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchResultsParams) {
      return id == other.id &&
          listEqual(results, other.results,
              (SearchResult a, SearchResult b) => a == b) &&
          isLast == other.isLast;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, results.hashCode);
    hash = JenkinsSmiHash.combine(hash, isLast.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// server.connected params
///
/// {
///   "version": String
///   "pid": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerConnectedParams implements HasToJson {
  String _version;

  int _pid;

  /// The version number of the analysis server.
  String get version => _version;

  /// The version number of the analysis server.
  set version(String value) {
    assert(value != null);
    _version = value;
  }

  /// The process id of the analysis server process.
  int get pid => _pid;

  /// The process id of the analysis server process.
  set pid(int value) {
    assert(value != null);
    _pid = value;
  }

  ServerConnectedParams(String version, int pid) {
    this.version = version;
    this.pid = pid;
  }

  factory ServerConnectedParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String version;
      if (json.containsKey('version')) {
        version =
            jsonDecoder.decodeString(jsonPath + '.version', json['version']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'version');
      }
      int pid;
      if (json.containsKey('pid')) {
        pid = jsonDecoder.decodeInt(jsonPath + '.pid', json['pid']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'pid');
      }
      return ServerConnectedParams(version, pid);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.connected params', json);
    }
  }

  factory ServerConnectedParams.fromNotification(Notification notification) {
    return ServerConnectedParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['version'] = version;
    result['pid'] = pid;
    return result;
  }

  Notification toNotification() {
    return Notification('server.connected', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerConnectedParams) {
      return version == other.version && pid == other.pid;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    hash = JenkinsSmiHash.combine(hash, pid.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// server.error params
///
/// {
///   "isFatal": bool
///   "message": String
///   "stackTrace": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerErrorParams implements HasToJson {
  bool _isFatal;

  String _message;

  String _stackTrace;

  /// True if the error is a fatal error, meaning that the server will shutdown
  /// automatically after sending this notification.
  bool get isFatal => _isFatal;

  /// True if the error is a fatal error, meaning that the server will shutdown
  /// automatically after sending this notification.
  set isFatal(bool value) {
    assert(value != null);
    _isFatal = value;
  }

  /// The error message indicating what kind of error was encountered.
  String get message => _message;

  /// The error message indicating what kind of error was encountered.
  set message(String value) {
    assert(value != null);
    _message = value;
  }

  /// The stack trace associated with the generation of the error, used for
  /// debugging the server.
  String get stackTrace => _stackTrace;

  /// The stack trace associated with the generation of the error, used for
  /// debugging the server.
  set stackTrace(String value) {
    assert(value != null);
    _stackTrace = value;
  }

  ServerErrorParams(bool isFatal, String message, String stackTrace) {
    this.isFatal = isFatal;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  factory ServerErrorParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      bool isFatal;
      if (json.containsKey('isFatal')) {
        isFatal =
            jsonDecoder.decodeBool(jsonPath + '.isFatal', json['isFatal']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'isFatal');
      }
      String message;
      if (json.containsKey('message')) {
        message =
            jsonDecoder.decodeString(jsonPath + '.message', json['message']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'message');
      }
      String stackTrace;
      if (json.containsKey('stackTrace')) {
        stackTrace = jsonDecoder.decodeString(
            jsonPath + '.stackTrace', json['stackTrace']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'stackTrace');
      }
      return ServerErrorParams(isFatal, message, stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.error params', json);
    }
  }

  factory ServerErrorParams.fromNotification(Notification notification) {
    return ServerErrorParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['isFatal'] = isFatal;
    result['message'] = message;
    result['stackTrace'] = stackTrace;
    return result;
  }

  Notification toNotification() {
    return Notification('server.error', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerErrorParams) {
      return isFatal == other.isFatal &&
          message == other.message &&
          stackTrace == other.stackTrace;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, isFatal.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, stackTrace.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// server.getVersion params
///
/// Clients may not extend, implement or mix-in this class.
class ServerGetVersionParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'server.getVersion', null);
  }

  @override
  bool operator ==(other) {
    if (other is ServerGetVersionParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 55877452;
  }
}

/// server.getVersion result
///
/// {
///   "version": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerGetVersionResult implements ResponseResult {
  String _version;

  /// The version number of the analysis server.
  String get version => _version;

  /// The version number of the analysis server.
  set version(String value) {
    assert(value != null);
    _version = value;
  }

  ServerGetVersionResult(String version) {
    this.version = version;
  }

  factory ServerGetVersionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String version;
      if (json.containsKey('version')) {
        version =
            jsonDecoder.decodeString(jsonPath + '.version', json['version']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'version');
      }
      return ServerGetVersionResult(version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.getVersion result', json);
    }
  }

  factory ServerGetVersionResult.fromResponse(Response response) {
    return ServerGetVersionResult.fromJson(
        ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        'result',
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['version'] = version;
    return result;
  }

  @override
  Response toResponse(String id) {
    return Response(id, result: toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerGetVersionResult) {
      return version == other.version;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ServerLogEntry
///
/// {
///   "time": int
///   "kind": ServerLogEntryKind
///   "data": String
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerLogEntry implements HasToJson {
  int _time;

  ServerLogEntryKind _kind;

  String _data;

  /// The time (milliseconds since epoch) at which the server created this log
  /// entry.
  int get time => _time;

  /// The time (milliseconds since epoch) at which the server created this log
  /// entry.
  set time(int value) {
    assert(value != null);
    _time = value;
  }

  /// The kind of the entry, used to determine how to interpret the "data"
  /// field.
  ServerLogEntryKind get kind => _kind;

  /// The kind of the entry, used to determine how to interpret the "data"
  /// field.
  set kind(ServerLogEntryKind value) {
    assert(value != null);
    _kind = value;
  }

  /// The payload of the entry, the actual format is determined by the "kind"
  /// field.
  String get data => _data;

  /// The payload of the entry, the actual format is determined by the "kind"
  /// field.
  set data(String value) {
    assert(value != null);
    _data = value;
  }

  ServerLogEntry(int time, ServerLogEntryKind kind, String data) {
    this.time = time;
    this.kind = kind;
    this.data = data;
  }

  factory ServerLogEntry.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      int time;
      if (json.containsKey('time')) {
        time = jsonDecoder.decodeInt(jsonPath + '.time', json['time']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'time');
      }
      ServerLogEntryKind kind;
      if (json.containsKey('kind')) {
        kind = ServerLogEntryKind.fromJson(
            jsonDecoder, jsonPath + '.kind', json['kind']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'kind');
      }
      String data;
      if (json.containsKey('data')) {
        data = jsonDecoder.decodeString(jsonPath + '.data', json['data']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'data');
      }
      return ServerLogEntry(time, kind, data);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'ServerLogEntry', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['time'] = time;
    result['kind'] = kind.toJson();
    result['data'] = data;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerLogEntry) {
      return time == other.time && kind == other.kind && data == other.data;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, time.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, data.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ServerLogEntryKind
///
/// enum {
///   NOTIFICATION
///   RAW
///   REQUEST
///   RESPONSE
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerLogEntryKind implements Enum {
  /// A notification from the server, such as "analysis.highlights". The "data"
  /// field contains a JSON object with abbreviated notification.
  static const ServerLogEntryKind NOTIFICATION =
      ServerLogEntryKind._('NOTIFICATION');

  /// Arbitrary string, describing some event that happened in the server, e.g.
  /// starting a file analysis, and details which files were accessed. These
  /// entries are not structured, but provide context information about
  /// requests and notification, and can be related by "time" for further
  /// manual analysis.
  static const ServerLogEntryKind RAW = ServerLogEntryKind._('RAW');

  /// A request from the client, as the server views it, e.g.
  /// "edit.getAssists". The "data" field contains a JSON object with
  /// abbreviated request.
  static const ServerLogEntryKind REQUEST = ServerLogEntryKind._('REQUEST');

  /// Various counters and measurements related to execution of a request. The
  /// "data" field contains a JSON object with following fields:
  ///
  /// - "id" - the id of the request - copied from the request.
  /// - "method" - the method of the request, e.g. "edit.getAssists".
  /// - "clientRequestTime" - the time (milliseconds since epoch) at which the
  ///   client made the request - copied from the request.
  /// - "serverRequestTime" - the time (milliseconds since epoch) at which the
  ///   server received and decoded the JSON request.
  /// - "responseTime" - the time (milliseconds since epoch) at which the
  ///   server created the response to be encoded into JSON and sent to the
  ///   client.
  static const ServerLogEntryKind RESPONSE = ServerLogEntryKind._('RESPONSE');

  /// A list containing all of the enum values that are defined.
  static const List<ServerLogEntryKind> VALUES = <ServerLogEntryKind>[
    NOTIFICATION,
    RAW,
    REQUEST,
    RESPONSE
  ];

  @override
  final String name;

  const ServerLogEntryKind._(this.name);

  factory ServerLogEntryKind(String name) {
    switch (name) {
      case 'NOTIFICATION':
        return NOTIFICATION;
      case 'RAW':
        return RAW;
      case 'REQUEST':
        return REQUEST;
      case 'RESPONSE':
        return RESPONSE;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ServerLogEntryKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return ServerLogEntryKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ServerLogEntryKind', json);
  }

  @override
  String toString() => 'ServerLogEntryKind.$name';

  String toJson() => name;
}

/// server.log params
///
/// {
///   "entry": ServerLogEntry
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerLogParams implements HasToJson {
  ServerLogEntry _entry;

  ServerLogEntry get entry => _entry;

  set entry(ServerLogEntry value) {
    assert(value != null);
    _entry = value;
  }

  ServerLogParams(ServerLogEntry entry) {
    this.entry = entry;
  }

  factory ServerLogParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      ServerLogEntry entry;
      if (json.containsKey('entry')) {
        entry = ServerLogEntry.fromJson(
            jsonDecoder, jsonPath + '.entry', json['entry']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'entry');
      }
      return ServerLogParams(entry);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.log params', json);
    }
  }

  factory ServerLogParams.fromNotification(Notification notification) {
    return ServerLogParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['entry'] = entry.toJson();
    return result;
  }

  Notification toNotification() {
    return Notification('server.log', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerLogParams) {
      return entry == other.entry;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, entry.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// ServerService
///
/// enum {
///   LOG
///   STATUS
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerService implements Enum {
  static const ServerService LOG = ServerService._('LOG');

  static const ServerService STATUS = ServerService._('STATUS');

  /// A list containing all of the enum values that are defined.
  static const List<ServerService> VALUES = <ServerService>[LOG, STATUS];

  @override
  final String name;

  const ServerService._(this.name);

  factory ServerService(String name) {
    switch (name) {
      case 'LOG':
        return LOG;
      case 'STATUS':
        return STATUS;
    }
    throw Exception('Illegal enum value: $name');
  }

  factory ServerService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return ServerService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, 'ServerService', json);
  }

  @override
  String toString() => 'ServerService.$name';

  String toJson() => name;
}

/// server.setSubscriptions params
///
/// {
///   "subscriptions": List<ServerService>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerSetSubscriptionsParams implements RequestParams {
  List<ServerService> _subscriptions;

  /// A list of the services being subscribed to.
  List<ServerService> get subscriptions => _subscriptions;

  /// A list of the services being subscribed to.
  set subscriptions(List<ServerService> value) {
    assert(value != null);
    _subscriptions = value;
  }

  ServerSetSubscriptionsParams(List<ServerService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory ServerSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      List<ServerService> subscriptions;
      if (json.containsKey('subscriptions')) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + '.subscriptions',
            json['subscriptions'],
            (String jsonPath, Object json) =>
                ServerService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subscriptions');
      }
      return ServerSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, 'server.setSubscriptions params', json);
    }
  }

  factory ServerSetSubscriptionsParams.fromRequest(Request request) {
    return ServerSetSubscriptionsParams.fromJson(
        RequestDecoder(request), 'params', request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['subscriptions'] =
        subscriptions.map((ServerService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return Request(id, 'server.setSubscriptions', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerSetSubscriptionsParams) {
      return listEqual(subscriptions, other.subscriptions,
          (ServerService a, ServerService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// server.setSubscriptions result
///
/// Clients may not extend, implement or mix-in this class.
class ServerSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is ServerSetSubscriptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 748820900;
  }
}

/// server.shutdown params
///
/// Clients may not extend, implement or mix-in this class.
class ServerShutdownParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return Request(id, 'server.shutdown', null);
  }

  @override
  bool operator ==(other) {
    if (other is ServerShutdownParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 366630911;
  }
}

/// server.shutdown result
///
/// Clients may not extend, implement or mix-in this class.
class ServerShutdownResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return Response(id, result: null);
  }

  @override
  bool operator ==(other) {
    if (other is ServerShutdownResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 193626532;
  }
}

/// server.status params
///
/// {
///   "analysis": optional AnalysisStatus
///   "pub": optional PubStatus
/// }
///
/// Clients may not extend, implement or mix-in this class.
class ServerStatusParams implements HasToJson {
  AnalysisStatus _analysis;

  PubStatus _pub;

  /// The current status of analysis, including whether analysis is being
  /// performed and if so what is being analyzed.
  AnalysisStatus get analysis => _analysis;

  /// The current status of analysis, including whether analysis is being
  /// performed and if so what is being analyzed.
  set analysis(AnalysisStatus value) {
    _analysis = value;
  }

  /// The current status of pub execution, indicating whether we are currently
  /// running pub.
  ///
  /// Note: this status type is deprecated, and is no longer sent by the
  /// server.
  PubStatus get pub => _pub;

  /// The current status of pub execution, indicating whether we are currently
  /// running pub.
  ///
  /// Note: this status type is deprecated, and is no longer sent by the
  /// server.
  set pub(PubStatus value) {
    _pub = value;
  }

  ServerStatusParams({AnalysisStatus analysis, PubStatus pub}) {
    this.analysis = analysis;
    this.pub = pub;
  }

  factory ServerStatusParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      AnalysisStatus analysis;
      if (json.containsKey('analysis')) {
        analysis = AnalysisStatus.fromJson(
            jsonDecoder, jsonPath + '.analysis', json['analysis']);
      }
      PubStatus pub;
      if (json.containsKey('pub')) {
        pub = PubStatus.fromJson(jsonDecoder, jsonPath + '.pub', json['pub']);
      }
      return ServerStatusParams(analysis: analysis, pub: pub);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'server.status params', json);
    }
  }

  factory ServerStatusParams.fromNotification(Notification notification) {
    return ServerStatusParams.fromJson(
        ResponseDecoder(null), 'params', notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    if (analysis != null) {
      result['analysis'] = analysis.toJson();
    }
    if (pub != null) {
      result['pub'] = pub.toJson();
    }
    return result;
  }

  Notification toNotification() {
    return Notification('server.status', toJson());
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerStatusParams) {
      return analysis == other.analysis && pub == other.pub;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, analysis.hashCode);
    hash = JenkinsSmiHash.combine(hash, pub.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// TokenDetails
///
/// {
///   "lexeme": String
///   "type": optional String
///   "validElementKinds": optional List<String>
///   "offset": int
/// }
///
/// Clients may not extend, implement or mix-in this class.
class TokenDetails implements HasToJson {
  String _lexeme;

  String _type;

  List<String> _validElementKinds;

  int _offset;

  /// The token's lexeme.
  String get lexeme => _lexeme;

  /// The token's lexeme.
  set lexeme(String value) {
    assert(value != null);
    _lexeme = value;
  }

  /// A unique id for the type of the identifier. Omitted if the token is not
  /// an identifier in a reference position.
  String get type => _type;

  /// A unique id for the type of the identifier. Omitted if the token is not
  /// an identifier in a reference position.
  set type(String value) {
    _type = value;
  }

  /// An indication of whether this token is in a declaration or reference
  /// position. (If no other purpose is found for this field then it should be
  /// renamed and converted to a boolean value.) Omitted if the token is not an
  /// identifier.
  List<String> get validElementKinds => _validElementKinds;

  /// An indication of whether this token is in a declaration or reference
  /// position. (If no other purpose is found for this field then it should be
  /// renamed and converted to a boolean value.) Omitted if the token is not an
  /// identifier.
  set validElementKinds(List<String> value) {
    _validElementKinds = value;
  }

  /// The offset of the first character of the token in the file which it
  /// originated from.
  int get offset => _offset;

  /// The offset of the first character of the token in the file which it
  /// originated from.
  set offset(int value) {
    assert(value != null);
    _offset = value;
  }

  TokenDetails(String lexeme, int offset,
      {String type, List<String> validElementKinds}) {
    this.lexeme = lexeme;
    this.type = type;
    this.validElementKinds = validElementKinds;
    this.offset = offset;
  }

  factory TokenDetails.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      String lexeme;
      if (json.containsKey('lexeme')) {
        lexeme = jsonDecoder.decodeString(jsonPath + '.lexeme', json['lexeme']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'lexeme');
      }
      String type;
      if (json.containsKey('type')) {
        type = jsonDecoder.decodeString(jsonPath + '.type', json['type']);
      }
      List<String> validElementKinds;
      if (json.containsKey('validElementKinds')) {
        validElementKinds = jsonDecoder.decodeList(
            jsonPath + '.validElementKinds',
            json['validElementKinds'],
            jsonDecoder.decodeString);
      }
      int offset;
      if (json.containsKey('offset')) {
        offset = jsonDecoder.decodeInt(jsonPath + '.offset', json['offset']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'offset');
      }
      return TokenDetails(lexeme, offset,
          type: type, validElementKinds: validElementKinds);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'TokenDetails', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['lexeme'] = lexeme;
    if (type != null) {
      result['type'] = type;
    }
    if (validElementKinds != null) {
      result['validElementKinds'] = validElementKinds;
    }
    result['offset'] = offset;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is TokenDetails) {
      return lexeme == other.lexeme &&
          type == other.type &&
          listEqual(validElementKinds, other.validElementKinds,
              (String a, String b) => a == b) &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, lexeme.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, validElementKinds.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/// TypeHierarchyItem
///
/// {
///   "classElement": Element
///   "displayName": optional String
///   "memberElement": optional Element
///   "superclass": optional int
///   "interfaces": List<int>
///   "mixins": List<int>
///   "subclasses": List<int>
/// }
///
/// Clients may not extend, implement or mix-in this class.
class TypeHierarchyItem implements HasToJson {
  Element _classElement;

  String _displayName;

  Element _memberElement;

  int _superclass;

  List<int> _interfaces;

  List<int> _mixins;

  List<int> _subclasses;

  /// The class element represented by this item.
  Element get classElement => _classElement;

  /// The class element represented by this item.
  set classElement(Element value) {
    assert(value != null);
    _classElement = value;
  }

  /// The name to be displayed for the class. This field will be omitted if the
  /// display name is the same as the name of the element. The display name is
  /// different if there is additional type information to be displayed, such
  /// as type arguments.
  String get displayName => _displayName;

  /// The name to be displayed for the class. This field will be omitted if the
  /// display name is the same as the name of the element. The display name is
  /// different if there is additional type information to be displayed, such
  /// as type arguments.
  set displayName(String value) {
    _displayName = value;
  }

  /// The member in the class corresponding to the member on which the
  /// hierarchy was requested. This field will be omitted if the hierarchy was
  /// not requested for a member or if the class does not have a corresponding
  /// member.
  Element get memberElement => _memberElement;

  /// The member in the class corresponding to the member on which the
  /// hierarchy was requested. This field will be omitted if the hierarchy was
  /// not requested for a member or if the class does not have a corresponding
  /// member.
  set memberElement(Element value) {
    _memberElement = value;
  }

  /// The index of the item representing the superclass of this class. This
  /// field will be omitted if this item represents the class Object.
  int get superclass => _superclass;

  /// The index of the item representing the superclass of this class. This
  /// field will be omitted if this item represents the class Object.
  set superclass(int value) {
    _superclass = value;
  }

  /// The indexes of the items representing the interfaces implemented by this
  /// class. The list will be empty if there are no implemented interfaces.
  List<int> get interfaces => _interfaces;

  /// The indexes of the items representing the interfaces implemented by this
  /// class. The list will be empty if there are no implemented interfaces.
  set interfaces(List<int> value) {
    assert(value != null);
    _interfaces = value;
  }

  /// The indexes of the items representing the mixins referenced by this
  /// class. The list will be empty if there are no classes mixed in to this
  /// class.
  List<int> get mixins => _mixins;

  /// The indexes of the items representing the mixins referenced by this
  /// class. The list will be empty if there are no classes mixed in to this
  /// class.
  set mixins(List<int> value) {
    assert(value != null);
    _mixins = value;
  }

  /// The indexes of the items representing the subtypes of this class. The
  /// list will be empty if there are no subtypes or if this item represents a
  /// supertype of the pivot type.
  List<int> get subclasses => _subclasses;

  /// The indexes of the items representing the subtypes of this class. The
  /// list will be empty if there are no subtypes or if this item represents a
  /// supertype of the pivot type.
  set subclasses(List<int> value) {
    assert(value != null);
    _subclasses = value;
  }

  TypeHierarchyItem(Element classElement,
      {String displayName,
      Element memberElement,
      int superclass,
      List<int> interfaces,
      List<int> mixins,
      List<int> subclasses}) {
    this.classElement = classElement;
    this.displayName = displayName;
    this.memberElement = memberElement;
    this.superclass = superclass;
    if (interfaces == null) {
      this.interfaces = <int>[];
    } else {
      this.interfaces = interfaces;
    }
    if (mixins == null) {
      this.mixins = <int>[];
    } else {
      this.mixins = mixins;
    }
    if (subclasses == null) {
      this.subclasses = <int>[];
    } else {
      this.subclasses = subclasses;
    }
  }

  factory TypeHierarchyItem.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    json ??= {};
    if (json is Map) {
      Element classElement;
      if (json.containsKey('classElement')) {
        classElement = Element.fromJson(
            jsonDecoder, jsonPath + '.classElement', json['classElement']);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'classElement');
      }
      String displayName;
      if (json.containsKey('displayName')) {
        displayName = jsonDecoder.decodeString(
            jsonPath + '.displayName', json['displayName']);
      }
      Element memberElement;
      if (json.containsKey('memberElement')) {
        memberElement = Element.fromJson(
            jsonDecoder, jsonPath + '.memberElement', json['memberElement']);
      }
      int superclass;
      if (json.containsKey('superclass')) {
        superclass =
            jsonDecoder.decodeInt(jsonPath + '.superclass', json['superclass']);
      }
      List<int> interfaces;
      if (json.containsKey('interfaces')) {
        interfaces = jsonDecoder.decodeList(jsonPath + '.interfaces',
            json['interfaces'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'interfaces');
      }
      List<int> mixins;
      if (json.containsKey('mixins')) {
        mixins = jsonDecoder.decodeList(
            jsonPath + '.mixins', json['mixins'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'mixins');
      }
      List<int> subclasses;
      if (json.containsKey('subclasses')) {
        subclasses = jsonDecoder.decodeList(jsonPath + '.subclasses',
            json['subclasses'], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, 'subclasses');
      }
      return TypeHierarchyItem(classElement,
          displayName: displayName,
          memberElement: memberElement,
          superclass: superclass,
          interfaces: interfaces,
          mixins: mixins,
          subclasses: subclasses);
    } else {
      throw jsonDecoder.mismatch(jsonPath, 'TypeHierarchyItem', json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    var result = <String, dynamic>{};
    result['classElement'] = classElement.toJson();
    if (displayName != null) {
      result['displayName'] = displayName;
    }
    if (memberElement != null) {
      result['memberElement'] = memberElement.toJson();
    }
    if (superclass != null) {
      result['superclass'] = superclass;
    }
    result['interfaces'] = interfaces;
    result['mixins'] = mixins;
    result['subclasses'] = subclasses;
    return result;
  }

  @override
  String toString() => json.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is TypeHierarchyItem) {
      return classElement == other.classElement &&
          displayName == other.displayName &&
          memberElement == other.memberElement &&
          superclass == other.superclass &&
          listEqual(interfaces, other.interfaces, (int a, int b) => a == b) &&
          listEqual(mixins, other.mixins, (int a, int b) => a == b) &&
          listEqual(subclasses, other.subclasses, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    var hash = 0;
    hash = JenkinsSmiHash.combine(hash, classElement.hashCode);
    hash = JenkinsSmiHash.combine(hash, displayName.hashCode);
    hash = JenkinsSmiHash.combine(hash, memberElement.hashCode);
    hash = JenkinsSmiHash.combine(hash, superclass.hashCode);
    hash = JenkinsSmiHash.combine(hash, interfaces.hashCode);
    hash = JenkinsSmiHash.combine(hash, mixins.hashCode);
    hash = JenkinsSmiHash.combine(hash, subclasses.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}
