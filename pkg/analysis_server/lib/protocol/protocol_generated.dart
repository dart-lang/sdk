// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

/**
 * analysis.analyzedFiles params
 *
 * {
 *   "directories": List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisAnalyzedFilesParams implements HasToJson {
  List<String> _directories;

  /**
   * A list of the paths of the files that are being analyzed.
   */
  List<String> get directories => _directories;

  /**
   * A list of the paths of the files that are being analyzed.
   */
  void set directories(List<String> value) {
    assert(value != null);
    this._directories = value;
  }

  AnalysisAnalyzedFilesParams(List<String> directories) {
    this.directories = directories;
  }

  factory AnalysisAnalyzedFilesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> directories;
      if (json.containsKey("directories")) {
        directories = jsonDecoder.decodeList(jsonPath + ".directories",
            json["directories"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "directories");
      }
      return new AnalysisAnalyzedFilesParams(directories);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.analyzedFiles params", json);
    }
  }

  factory AnalysisAnalyzedFilesParams.fromNotification(
      Notification notification) {
    return new AnalysisAnalyzedFilesParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["directories"] = directories;
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.analyzedFiles", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, directories.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.closingLabels params
 *
 * {
 *   "file": FilePath
 *   "labels": List<ClosingLabel>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisClosingLabelsParams implements HasToJson {
  String _file;

  List<ClosingLabel> _labels;

  /**
   * The file the closing labels relate to.
   */
  String get file => _file;

  /**
   * The file the closing labels relate to.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * Closing labels relevant to the file. Each item represents a useful label
   * associated with some range with may be useful to display to the user
   * within the editor at the end of the range to indicate what construct is
   * closed at that location. Closing labels include constructor/method calls
   * and List arguments that span multiple lines. Note that the ranges that are
   * returned can overlap each other because they may be associated with
   * constructs that can be nested.
   */
  List<ClosingLabel> get labels => _labels;

  /**
   * Closing labels relevant to the file. Each item represents a useful label
   * associated with some range with may be useful to display to the user
   * within the editor at the end of the range to indicate what construct is
   * closed at that location. Closing labels include constructor/method calls
   * and List arguments that span multiple lines. Note that the ranges that are
   * returned can overlap each other because they may be associated with
   * constructs that can be nested.
   */
  void set labels(List<ClosingLabel> value) {
    assert(value != null);
    this._labels = value;
  }

  AnalysisClosingLabelsParams(String file, List<ClosingLabel> labels) {
    this.file = file;
    this.labels = labels;
  }

  factory AnalysisClosingLabelsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<ClosingLabel> labels;
      if (json.containsKey("labels")) {
        labels = jsonDecoder.decodeList(
            jsonPath + ".labels",
            json["labels"],
            (String jsonPath, Object json) =>
                new ClosingLabel.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "labels");
      }
      return new AnalysisClosingLabelsParams(file, labels);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.closingLabels params", json);
    }
  }

  factory AnalysisClosingLabelsParams.fromNotification(
      Notification notification) {
    return new AnalysisClosingLabelsParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["labels"] =
        labels.map((ClosingLabel value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.closingLabels", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, labels.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * AnalysisErrorFixes
 *
 * {
 *   "error": AnalysisError
 *   "fixes": List<SourceChange>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisErrorFixes implements HasToJson {
  AnalysisError _error;

  List<SourceChange> _fixes;

  /**
   * The error with which the fixes are associated.
   */
  AnalysisError get error => _error;

  /**
   * The error with which the fixes are associated.
   */
  void set error(AnalysisError value) {
    assert(value != null);
    this._error = value;
  }

  /**
   * The fixes associated with the error.
   */
  List<SourceChange> get fixes => _fixes;

  /**
   * The fixes associated with the error.
   */
  void set fixes(List<SourceChange> value) {
    assert(value != null);
    this._fixes = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisError error;
      if (json.containsKey("error")) {
        error = new AnalysisError.fromJson(
            jsonDecoder, jsonPath + ".error", json["error"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "error");
      }
      List<SourceChange> fixes;
      if (json.containsKey("fixes")) {
        fixes = jsonDecoder.decodeList(
            jsonPath + ".fixes",
            json["fixes"],
            (String jsonPath, Object json) =>
                new SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "fixes");
      }
      return new AnalysisErrorFixes(error, fixes: fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorFixes", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["error"] = error.toJson();
    result["fixes"] =
        fixes.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, error.hashCode);
    hash = JenkinsSmiHash.combine(hash, fixes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.errors params
 *
 * {
 *   "file": FilePath
 *   "errors": List<AnalysisError>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisErrorsParams implements HasToJson {
  String _file;

  List<AnalysisError> _errors;

  /**
   * The file containing the errors.
   */
  String get file => _file;

  /**
   * The file containing the errors.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The errors contained in the file.
   */
  List<AnalysisError> get errors => _errors;

  /**
   * The errors contained in the file.
   */
  void set errors(List<AnalysisError> value) {
    assert(value != null);
    this._errors = value;
  }

  AnalysisErrorsParams(String file, List<AnalysisError> errors) {
    this.file = file;
    this.errors = errors;
  }

  factory AnalysisErrorsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<AnalysisError> errors;
      if (json.containsKey("errors")) {
        errors = jsonDecoder.decodeList(
            jsonPath + ".errors",
            json["errors"],
            (String jsonPath, Object json) =>
                new AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "errors");
      }
      return new AnalysisErrorsParams(file, errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.errors params", json);
    }
  }

  factory AnalysisErrorsParams.fromNotification(Notification notification) {
    return new AnalysisErrorsParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["errors"] =
        errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.errors", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, errors.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.flushResults params
 *
 * {
 *   "files": List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisFlushResultsParams implements HasToJson {
  List<String> _files;

  /**
   * The files that are no longer being analyzed.
   */
  List<String> get files => _files;

  /**
   * The files that are no longer being analyzed.
   */
  void set files(List<String> value) {
    assert(value != null);
    this._files = value;
  }

  AnalysisFlushResultsParams(List<String> files) {
    this.files = files;
  }

  factory AnalysisFlushResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(
            jsonPath + ".files", json["files"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new AnalysisFlushResultsParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.flushResults params", json);
    }
  }

  factory AnalysisFlushResultsParams.fromNotification(
      Notification notification) {
    return new AnalysisFlushResultsParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = files;
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.flushResults", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisFlushResultsParams) {
      return listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.folding params
 *
 * {
 *   "file": FilePath
 *   "regions": List<FoldingRegion>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisFoldingParams implements HasToJson {
  String _file;

  List<FoldingRegion> _regions;

  /**
   * The file containing the folding regions.
   */
  String get file => _file;

  /**
   * The file containing the folding regions.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The folding regions contained in the file.
   */
  List<FoldingRegion> get regions => _regions;

  /**
   * The folding regions contained in the file.
   */
  void set regions(List<FoldingRegion> value) {
    assert(value != null);
    this._regions = value;
  }

  AnalysisFoldingParams(String file, List<FoldingRegion> regions) {
    this.file = file;
    this.regions = regions;
  }

  factory AnalysisFoldingParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<FoldingRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder.decodeList(
            jsonPath + ".regions",
            json["regions"],
            (String jsonPath, Object json) =>
                new FoldingRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "regions");
      }
      return new AnalysisFoldingParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.folding params", json);
    }
  }

  factory AnalysisFoldingParams.fromNotification(Notification notification) {
    return new AnalysisFoldingParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["regions"] =
        regions.map((FoldingRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.folding", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getErrors params
 *
 * {
 *   "file": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetErrorsParams implements RequestParams {
  String _file;

  /**
   * The file for which errors are being requested.
   */
  String get file => _file;

  /**
   * The file for which errors are being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  AnalysisGetErrorsParams(String file) {
    this.file = file;
  }

  factory AnalysisGetErrorsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      return new AnalysisGetErrorsParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getErrors params", json);
    }
  }

  factory AnalysisGetErrorsParams.fromRequest(Request request) {
    return new AnalysisGetErrorsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.getErrors", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetErrorsParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getErrors result
 *
 * {
 *   "errors": List<AnalysisError>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetErrorsResult implements ResponseResult {
  List<AnalysisError> _errors;

  /**
   * The errors associated with the file.
   */
  List<AnalysisError> get errors => _errors;

  /**
   * The errors associated with the file.
   */
  void set errors(List<AnalysisError> value) {
    assert(value != null);
    this._errors = value;
  }

  AnalysisGetErrorsResult(List<AnalysisError> errors) {
    this.errors = errors;
  }

  factory AnalysisGetErrorsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<AnalysisError> errors;
      if (json.containsKey("errors")) {
        errors = jsonDecoder.decodeList(
            jsonPath + ".errors",
            json["errors"],
            (String jsonPath, Object json) =>
                new AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "errors");
      }
      return new AnalysisGetErrorsResult(errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getErrors result", json);
    }
  }

  factory AnalysisGetErrorsResult.fromResponse(Response response) {
    return new AnalysisGetErrorsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["errors"] =
        errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, errors.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getHover params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetHoverParams implements RequestParams {
  String _file;

  int _offset;

  /**
   * The file in which hover information is being requested.
   */
  String get file => _file;

  /**
   * The file in which hover information is being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset for which hover information is being requested.
   */
  int get offset => _offset;

  /**
   * The offset for which hover information is being requested.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  AnalysisGetHoverParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory AnalysisGetHoverParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      return new AnalysisGetHoverParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getHover params", json);
    }
  }

  factory AnalysisGetHoverParams.fromRequest(Request request) {
    return new AnalysisGetHoverParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.getHover", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetHoverParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getHover result
 *
 * {
 *   "hovers": List<HoverInformation>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetHoverResult implements ResponseResult {
  List<HoverInformation> _hovers;

  /**
   * The hover information associated with the location. The list will be empty
   * if no information could be determined for the location. The list can
   * contain multiple items if the file is being analyzed in multiple contexts
   * in conflicting ways (such as a part that is included in multiple
   * libraries).
   */
  List<HoverInformation> get hovers => _hovers;

  /**
   * The hover information associated with the location. The list will be empty
   * if no information could be determined for the location. The list can
   * contain multiple items if the file is being analyzed in multiple contexts
   * in conflicting ways (such as a part that is included in multiple
   * libraries).
   */
  void set hovers(List<HoverInformation> value) {
    assert(value != null);
    this._hovers = value;
  }

  AnalysisGetHoverResult(List<HoverInformation> hovers) {
    this.hovers = hovers;
  }

  factory AnalysisGetHoverResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<HoverInformation> hovers;
      if (json.containsKey("hovers")) {
        hovers = jsonDecoder.decodeList(
            jsonPath + ".hovers",
            json["hovers"],
            (String jsonPath, Object json) =>
                new HoverInformation.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "hovers");
      }
      return new AnalysisGetHoverResult(hovers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getHover result", json);
    }
  }

  factory AnalysisGetHoverResult.fromResponse(Response response) {
    return new AnalysisGetHoverResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["hovers"] =
        hovers.map((HoverInformation value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, hovers.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getImportedElements params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetImportedElementsParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /**
   * The file in which import information is being requested.
   */
  String get file => _file;

  /**
   * The file in which import information is being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the region for which import information is being requested.
   */
  int get offset => _offset;

  /**
   * The offset of the region for which import information is being requested.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region for which import information is being requested.
   */
  int get length => _length;

  /**
   * The length of the region for which import information is being requested.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  AnalysisGetImportedElementsParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory AnalysisGetImportedElementsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new AnalysisGetImportedElementsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getImportedElements params", json);
    }
  }

  factory AnalysisGetImportedElementsParams.fromRequest(Request request) {
    return new AnalysisGetImportedElementsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.getImportedElements", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getImportedElements result
 *
 * {
 *   "elements": List<ImportedElements>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetImportedElementsResult implements ResponseResult {
  List<ImportedElements> _elements;

  /**
   * The information about the elements that are referenced in the specified
   * region of the specified file that come from imported libraries.
   */
  List<ImportedElements> get elements => _elements;

  /**
   * The information about the elements that are referenced in the specified
   * region of the specified file that come from imported libraries.
   */
  void set elements(List<ImportedElements> value) {
    assert(value != null);
    this._elements = value;
  }

  AnalysisGetImportedElementsResult(List<ImportedElements> elements) {
    this.elements = elements;
  }

  factory AnalysisGetImportedElementsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ImportedElements> elements;
      if (json.containsKey("elements")) {
        elements = jsonDecoder.decodeList(
            jsonPath + ".elements",
            json["elements"],
            (String jsonPath, Object json) =>
                new ImportedElements.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "elements");
      }
      return new AnalysisGetImportedElementsResult(elements);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getImportedElements result", json);
    }
  }

  factory AnalysisGetImportedElementsResult.fromResponse(Response response) {
    return new AnalysisGetImportedElementsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["elements"] =
        elements.map((ImportedElements value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getLibraryDependencies params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetLibraryDependenciesParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.getLibraryDependencies", null);
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

/**
 * analysis.getLibraryDependencies result
 *
 * {
 *   "libraries": List<FilePath>
 *   "packageMap": Map<String, Map<String, List<FilePath>>>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetLibraryDependenciesResult implements ResponseResult {
  List<String> _libraries;

  Map<String, Map<String, List<String>>> _packageMap;

  /**
   * A list of the paths of library elements referenced by files in existing
   * analysis roots.
   */
  List<String> get libraries => _libraries;

  /**
   * A list of the paths of library elements referenced by files in existing
   * analysis roots.
   */
  void set libraries(List<String> value) {
    assert(value != null);
    this._libraries = value;
  }

  /**
   * A mapping from context source roots to package maps which map package
   * names to source directories for use in client-side package URI resolution.
   */
  Map<String, Map<String, List<String>>> get packageMap => _packageMap;

  /**
   * A mapping from context source roots to package maps which map package
   * names to source directories for use in client-side package URI resolution.
   */
  void set packageMap(Map<String, Map<String, List<String>>> value) {
    assert(value != null);
    this._packageMap = value;
  }

  AnalysisGetLibraryDependenciesResult(List<String> libraries,
      Map<String, Map<String, List<String>>> packageMap) {
    this.libraries = libraries;
    this.packageMap = packageMap;
  }

  factory AnalysisGetLibraryDependenciesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> libraries;
      if (json.containsKey("libraries")) {
        libraries = jsonDecoder.decodeList(jsonPath + ".libraries",
            json["libraries"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "libraries");
      }
      Map<String, Map<String, List<String>>> packageMap;
      if (json.containsKey("packageMap")) {
        packageMap = jsonDecoder.decodeMap(
            jsonPath + ".packageMap", json["packageMap"],
            valueDecoder: (String jsonPath, Object json) =>
                jsonDecoder.decodeMap(jsonPath, json,
                    valueDecoder: (String jsonPath, Object json) => jsonDecoder
                        .decodeList(jsonPath, json, jsonDecoder.decodeString)));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "packageMap");
      }
      return new AnalysisGetLibraryDependenciesResult(libraries, packageMap);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getLibraryDependencies result", json);
    }
  }

  factory AnalysisGetLibraryDependenciesResult.fromResponse(Response response) {
    return new AnalysisGetLibraryDependenciesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["libraries"] = libraries;
    result["packageMap"] = packageMap;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, libraries.hashCode);
    hash = JenkinsSmiHash.combine(hash, packageMap.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getNavigation params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetNavigationParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /**
   * The file in which navigation information is being requested.
   */
  String get file => _file;

  /**
   * The file in which navigation information is being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the region for which navigation information is being
   * requested.
   */
  int get offset => _offset;

  /**
   * The offset of the region for which navigation information is being
   * requested.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region for which navigation information is being
   * requested.
   */
  int get length => _length;

  /**
   * The length of the region for which navigation information is being
   * requested.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  AnalysisGetNavigationParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory AnalysisGetNavigationParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new AnalysisGetNavigationParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getNavigation params", json);
    }
  }

  factory AnalysisGetNavigationParams.fromRequest(Request request) {
    return new AnalysisGetNavigationParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.getNavigation", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getNavigation result
 *
 * {
 *   "files": List<FilePath>
 *   "targets": List<NavigationTarget>
 *   "regions": List<NavigationRegion>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetNavigationResult implements ResponseResult {
  List<String> _files;

  List<NavigationTarget> _targets;

  List<NavigationRegion> _regions;

  /**
   * A list of the paths of files that are referenced by the navigation
   * targets.
   */
  List<String> get files => _files;

  /**
   * A list of the paths of files that are referenced by the navigation
   * targets.
   */
  void set files(List<String> value) {
    assert(value != null);
    this._files = value;
  }

  /**
   * A list of the navigation targets that are referenced by the navigation
   * regions.
   */
  List<NavigationTarget> get targets => _targets;

  /**
   * A list of the navigation targets that are referenced by the navigation
   * regions.
   */
  void set targets(List<NavigationTarget> value) {
    assert(value != null);
    this._targets = value;
  }

  /**
   * A list of the navigation regions within the requested region of the file.
   */
  List<NavigationRegion> get regions => _regions;

  /**
   * A list of the navigation regions within the requested region of the file.
   */
  void set regions(List<NavigationRegion> value) {
    assert(value != null);
    this._regions = value;
  }

  AnalysisGetNavigationResult(List<String> files,
      List<NavigationTarget> targets, List<NavigationRegion> regions) {
    this.files = files;
    this.targets = targets;
    this.regions = regions;
  }

  factory AnalysisGetNavigationResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(
            jsonPath + ".files", json["files"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      List<NavigationTarget> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder.decodeList(
            jsonPath + ".targets",
            json["targets"],
            (String jsonPath, Object json) =>
                new NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "targets");
      }
      List<NavigationRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder.decodeList(
            jsonPath + ".regions",
            json["regions"],
            (String jsonPath, Object json) =>
                new NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "regions");
      }
      return new AnalysisGetNavigationResult(files, targets, regions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getNavigation result", json);
    }
  }

  factory AnalysisGetNavigationResult.fromResponse(Response response) {
    return new AnalysisGetNavigationResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = files;
    result["targets"] =
        targets.map((NavigationTarget value) => value.toJson()).toList();
    result["regions"] =
        regions.map((NavigationRegion value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    hash = JenkinsSmiHash.combine(hash, targets.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getReachableSources params
 *
 * {
 *   "file": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetReachableSourcesParams implements RequestParams {
  String _file;

  /**
   * The file for which reachable source information is being requested.
   */
  String get file => _file;

  /**
   * The file for which reachable source information is being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  AnalysisGetReachableSourcesParams(String file) {
    this.file = file;
  }

  factory AnalysisGetReachableSourcesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      return new AnalysisGetReachableSourcesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getReachableSources params", json);
    }
  }

  factory AnalysisGetReachableSourcesParams.fromRequest(Request request) {
    return new AnalysisGetReachableSourcesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.getReachableSources", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisGetReachableSourcesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getReachableSources result
 *
 * {
 *   "sources": Map<String, List<String>>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisGetReachableSourcesResult implements ResponseResult {
  Map<String, List<String>> _sources;

  /**
   * A mapping from source URIs to directly reachable source URIs. For example,
   * a file "foo.dart" that imports "bar.dart" would have the corresponding
   * mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If "bar.dart" has
   * further imports (or exports) there will be a mapping from the URI
   * "file:///bar.dart" to them. To check if a specific URI is reachable from a
   * given file, clients can check for its presence in the resulting key set.
   */
  Map<String, List<String>> get sources => _sources;

  /**
   * A mapping from source URIs to directly reachable source URIs. For example,
   * a file "foo.dart" that imports "bar.dart" would have the corresponding
   * mapping { "file:///foo.dart" : ["file:///bar.dart"] }. If "bar.dart" has
   * further imports (or exports) there will be a mapping from the URI
   * "file:///bar.dart" to them. To check if a specific URI is reachable from a
   * given file, clients can check for its presence in the resulting key set.
   */
  void set sources(Map<String, List<String>> value) {
    assert(value != null);
    this._sources = value;
  }

  AnalysisGetReachableSourcesResult(Map<String, List<String>> sources) {
    this.sources = sources;
  }

  factory AnalysisGetReachableSourcesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<String, List<String>> sources;
      if (json.containsKey("sources")) {
        sources = jsonDecoder.decodeMap(jsonPath + ".sources", json["sources"],
            valueDecoder: (String jsonPath, Object json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "sources");
      }
      return new AnalysisGetReachableSourcesResult(sources);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.getReachableSources result", json);
    }
  }

  factory AnalysisGetReachableSourcesResult.fromResponse(Response response) {
    return new AnalysisGetReachableSourcesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["sources"] = sources;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, sources.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.highlights params
 *
 * {
 *   "file": FilePath
 *   "regions": List<HighlightRegion>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisHighlightsParams implements HasToJson {
  String _file;

  List<HighlightRegion> _regions;

  /**
   * The file containing the highlight regions.
   */
  String get file => _file;

  /**
   * The file containing the highlight regions.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The highlight regions contained in the file. Each highlight region
   * represents a particular syntactic or semantic meaning associated with some
   * range. Note that the highlight regions that are returned can overlap other
   * highlight regions if there is more than one meaning associated with a
   * particular region.
   */
  List<HighlightRegion> get regions => _regions;

  /**
   * The highlight regions contained in the file. Each highlight region
   * represents a particular syntactic or semantic meaning associated with some
   * range. Note that the highlight regions that are returned can overlap other
   * highlight regions if there is more than one meaning associated with a
   * particular region.
   */
  void set regions(List<HighlightRegion> value) {
    assert(value != null);
    this._regions = value;
  }

  AnalysisHighlightsParams(String file, List<HighlightRegion> regions) {
    this.file = file;
    this.regions = regions;
  }

  factory AnalysisHighlightsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<HighlightRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder.decodeList(
            jsonPath + ".regions",
            json["regions"],
            (String jsonPath, Object json) =>
                new HighlightRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "regions");
      }
      return new AnalysisHighlightsParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.highlights params", json);
    }
  }

  factory AnalysisHighlightsParams.fromNotification(Notification notification) {
    return new AnalysisHighlightsParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["regions"] =
        regions.map((HighlightRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.highlights", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.implemented params
 *
 * {
 *   "file": FilePath
 *   "classes": List<ImplementedClass>
 *   "members": List<ImplementedMember>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisImplementedParams implements HasToJson {
  String _file;

  List<ImplementedClass> _classes;

  List<ImplementedMember> _members;

  /**
   * The file with which the implementations are associated.
   */
  String get file => _file;

  /**
   * The file with which the implementations are associated.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The classes defined in the file that are implemented or extended.
   */
  List<ImplementedClass> get classes => _classes;

  /**
   * The classes defined in the file that are implemented or extended.
   */
  void set classes(List<ImplementedClass> value) {
    assert(value != null);
    this._classes = value;
  }

  /**
   * The member defined in the file that are implemented or overridden.
   */
  List<ImplementedMember> get members => _members;

  /**
   * The member defined in the file that are implemented or overridden.
   */
  void set members(List<ImplementedMember> value) {
    assert(value != null);
    this._members = value;
  }

  AnalysisImplementedParams(String file, List<ImplementedClass> classes,
      List<ImplementedMember> members) {
    this.file = file;
    this.classes = classes;
    this.members = members;
  }

  factory AnalysisImplementedParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<ImplementedClass> classes;
      if (json.containsKey("classes")) {
        classes = jsonDecoder.decodeList(
            jsonPath + ".classes",
            json["classes"],
            (String jsonPath, Object json) =>
                new ImplementedClass.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "classes");
      }
      List<ImplementedMember> members;
      if (json.containsKey("members")) {
        members = jsonDecoder.decodeList(
            jsonPath + ".members",
            json["members"],
            (String jsonPath, Object json) =>
                new ImplementedMember.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "members");
      }
      return new AnalysisImplementedParams(file, classes, members);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.implemented params", json);
    }
  }

  factory AnalysisImplementedParams.fromNotification(
      Notification notification) {
    return new AnalysisImplementedParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["classes"] =
        classes.map((ImplementedClass value) => value.toJson()).toList();
    result["members"] =
        members.map((ImplementedMember value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.implemented", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, classes.hashCode);
    hash = JenkinsSmiHash.combine(hash, members.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.invalidate params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "delta": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisInvalidateParams implements HasToJson {
  String _file;

  int _offset;

  int _length;

  int _delta;

  /**
   * The file whose information has been invalidated.
   */
  String get file => _file;

  /**
   * The file whose information has been invalidated.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the invalidated region.
   */
  int get offset => _offset;

  /**
   * The offset of the invalidated region.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the invalidated region.
   */
  int get length => _length;

  /**
   * The length of the invalidated region.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The delta to be applied to the offsets in information that follows the
   * invalidated region in order to update it so that it doesn't need to be
   * re-requested.
   */
  int get delta => _delta;

  /**
   * The delta to be applied to the offsets in information that follows the
   * invalidated region in order to update it so that it doesn't need to be
   * re-requested.
   */
  void set delta(int value) {
    assert(value != null);
    this._delta = value;
  }

  AnalysisInvalidateParams(String file, int offset, int length, int delta) {
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.delta = delta;
  }

  factory AnalysisInvalidateParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      int delta;
      if (json.containsKey("delta")) {
        delta = jsonDecoder.decodeInt(jsonPath + ".delta", json["delta"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "delta");
      }
      return new AnalysisInvalidateParams(file, offset, length, delta);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.invalidate params", json);
    }
  }

  factory AnalysisInvalidateParams.fromNotification(Notification notification) {
    return new AnalysisInvalidateParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    result["delta"] = delta;
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.invalidate", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, delta.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.navigation params
 *
 * {
 *   "file": FilePath
 *   "regions": List<NavigationRegion>
 *   "targets": List<NavigationTarget>
 *   "files": List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisNavigationParams implements HasToJson {
  String _file;

  List<NavigationRegion> _regions;

  List<NavigationTarget> _targets;

  List<String> _files;

  /**
   * The file containing the navigation regions.
   */
  String get file => _file;

  /**
   * The file containing the navigation regions.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The navigation regions contained in the file. The regions are sorted by
   * their offsets. Each navigation region represents a list of targets
   * associated with some range. The lists will usually contain a single
   * target, but can contain more in the case of a part that is included in
   * multiple libraries or in Dart code that is compiled against multiple
   * versions of a package. Note that the navigation regions that are returned
   * do not overlap other navigation regions.
   */
  List<NavigationRegion> get regions => _regions;

  /**
   * The navigation regions contained in the file. The regions are sorted by
   * their offsets. Each navigation region represents a list of targets
   * associated with some range. The lists will usually contain a single
   * target, but can contain more in the case of a part that is included in
   * multiple libraries or in Dart code that is compiled against multiple
   * versions of a package. Note that the navigation regions that are returned
   * do not overlap other navigation regions.
   */
  void set regions(List<NavigationRegion> value) {
    assert(value != null);
    this._regions = value;
  }

  /**
   * The navigation targets referenced in the file. They are referenced by
   * NavigationRegions by their index in this array.
   */
  List<NavigationTarget> get targets => _targets;

  /**
   * The navigation targets referenced in the file. They are referenced by
   * NavigationRegions by their index in this array.
   */
  void set targets(List<NavigationTarget> value) {
    assert(value != null);
    this._targets = value;
  }

  /**
   * The files containing navigation targets referenced in the file. They are
   * referenced by NavigationTargets by their index in this array.
   */
  List<String> get files => _files;

  /**
   * The files containing navigation targets referenced in the file. They are
   * referenced by NavigationTargets by their index in this array.
   */
  void set files(List<String> value) {
    assert(value != null);
    this._files = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<NavigationRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder.decodeList(
            jsonPath + ".regions",
            json["regions"],
            (String jsonPath, Object json) =>
                new NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "regions");
      }
      List<NavigationTarget> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder.decodeList(
            jsonPath + ".targets",
            json["targets"],
            (String jsonPath, Object json) =>
                new NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "targets");
      }
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(
            jsonPath + ".files", json["files"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new AnalysisNavigationParams(file, regions, targets, files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.navigation params", json);
    }
  }

  factory AnalysisNavigationParams.fromNotification(Notification notification) {
    return new AnalysisNavigationParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["regions"] =
        regions.map((NavigationRegion value) => value.toJson()).toList();
    result["targets"] =
        targets.map((NavigationTarget value) => value.toJson()).toList();
    result["files"] = files;
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.navigation", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, regions.hashCode);
    hash = JenkinsSmiHash.combine(hash, targets.hashCode);
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.occurrences params
 *
 * {
 *   "file": FilePath
 *   "occurrences": List<Occurrences>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisOccurrencesParams implements HasToJson {
  String _file;

  List<Occurrences> _occurrences;

  /**
   * The file in which the references occur.
   */
  String get file => _file;

  /**
   * The file in which the references occur.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The occurrences of references to elements within the file.
   */
  List<Occurrences> get occurrences => _occurrences;

  /**
   * The occurrences of references to elements within the file.
   */
  void set occurrences(List<Occurrences> value) {
    assert(value != null);
    this._occurrences = value;
  }

  AnalysisOccurrencesParams(String file, List<Occurrences> occurrences) {
    this.file = file;
    this.occurrences = occurrences;
  }

  factory AnalysisOccurrencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<Occurrences> occurrences;
      if (json.containsKey("occurrences")) {
        occurrences = jsonDecoder.decodeList(
            jsonPath + ".occurrences",
            json["occurrences"],
            (String jsonPath, Object json) =>
                new Occurrences.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "occurrences");
      }
      return new AnalysisOccurrencesParams(file, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.occurrences params", json);
    }
  }

  factory AnalysisOccurrencesParams.fromNotification(
      Notification notification) {
    return new AnalysisOccurrencesParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["occurrences"] =
        occurrences.map((Occurrences value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.occurrences", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * AnalysisOptions
 *
 * {
 *   "enableAsync": optional bool
 *   "enableDeferredLoading": optional bool
 *   "enableEnums": optional bool
 *   "enableNullAwareOperators": optional bool
 *   "enableSuperMixins": optional bool
 *   "generateDart2jsHints": optional bool
 *   "generateHints": optional bool
 *   "generateLints": optional bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisOptions implements HasToJson {
  bool _enableAsync;

  bool _enableDeferredLoading;

  bool _enableEnums;

  bool _enableNullAwareOperators;

  bool _enableSuperMixins;

  bool _generateDart2jsHints;

  bool _generateHints;

  bool _generateLints;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed async feature.
   */
  bool get enableAsync => _enableAsync;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed async feature.
   */
  void set enableAsync(bool value) {
    this._enableAsync = value;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed deferred
   * loading feature.
   */
  bool get enableDeferredLoading => _enableDeferredLoading;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed deferred
   * loading feature.
   */
  void set enableDeferredLoading(bool value) {
    this._enableDeferredLoading = value;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed enum feature.
   */
  bool get enableEnums => _enableEnums;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed enum feature.
   */
  void set enableEnums(bool value) {
    this._enableEnums = value;
  }

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed "null aware
   * operators" feature.
   */
  bool get enableNullAwareOperators => _enableNullAwareOperators;

  /**
   * Deprecated: this feature is always enabled.
   *
   * True if the client wants to enable support for the proposed "null aware
   * operators" feature.
   */
  void set enableNullAwareOperators(bool value) {
    this._enableNullAwareOperators = value;
  }

  /**
   * True if the client wants to enable support for the proposed "less
   * restricted mixins" proposal (DEP 34).
   */
  bool get enableSuperMixins => _enableSuperMixins;

  /**
   * True if the client wants to enable support for the proposed "less
   * restricted mixins" proposal (DEP 34).
   */
  void set enableSuperMixins(bool value) {
    this._enableSuperMixins = value;
  }

  /**
   * True if hints that are specific to dart2js should be generated. This
   * option is ignored if generateHints is false.
   */
  bool get generateDart2jsHints => _generateDart2jsHints;

  /**
   * True if hints that are specific to dart2js should be generated. This
   * option is ignored if generateHints is false.
   */
  void set generateDart2jsHints(bool value) {
    this._generateDart2jsHints = value;
  }

  /**
   * True if hints should be generated as part of generating errors and
   * warnings.
   */
  bool get generateHints => _generateHints;

  /**
   * True if hints should be generated as part of generating errors and
   * warnings.
   */
  void set generateHints(bool value) {
    this._generateHints = value;
  }

  /**
   * True if lints should be generated as part of generating errors and
   * warnings.
   */
  bool get generateLints => _generateLints;

  /**
   * True if lints should be generated as part of generating errors and
   * warnings.
   */
  void set generateLints(bool value) {
    this._generateLints = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool enableAsync;
      if (json.containsKey("enableAsync")) {
        enableAsync = jsonDecoder.decodeBool(
            jsonPath + ".enableAsync", json["enableAsync"]);
      }
      bool enableDeferredLoading;
      if (json.containsKey("enableDeferredLoading")) {
        enableDeferredLoading = jsonDecoder.decodeBool(
            jsonPath + ".enableDeferredLoading", json["enableDeferredLoading"]);
      }
      bool enableEnums;
      if (json.containsKey("enableEnums")) {
        enableEnums = jsonDecoder.decodeBool(
            jsonPath + ".enableEnums", json["enableEnums"]);
      }
      bool enableNullAwareOperators;
      if (json.containsKey("enableNullAwareOperators")) {
        enableNullAwareOperators = jsonDecoder.decodeBool(
            jsonPath + ".enableNullAwareOperators",
            json["enableNullAwareOperators"]);
      }
      bool enableSuperMixins;
      if (json.containsKey("enableSuperMixins")) {
        enableSuperMixins = jsonDecoder.decodeBool(
            jsonPath + ".enableSuperMixins", json["enableSuperMixins"]);
      }
      bool generateDart2jsHints;
      if (json.containsKey("generateDart2jsHints")) {
        generateDart2jsHints = jsonDecoder.decodeBool(
            jsonPath + ".generateDart2jsHints", json["generateDart2jsHints"]);
      }
      bool generateHints;
      if (json.containsKey("generateHints")) {
        generateHints = jsonDecoder.decodeBool(
            jsonPath + ".generateHints", json["generateHints"]);
      }
      bool generateLints;
      if (json.containsKey("generateLints")) {
        generateLints = jsonDecoder.decodeBool(
            jsonPath + ".generateLints", json["generateLints"]);
      }
      return new AnalysisOptions(
          enableAsync: enableAsync,
          enableDeferredLoading: enableDeferredLoading,
          enableEnums: enableEnums,
          enableNullAwareOperators: enableNullAwareOperators,
          enableSuperMixins: enableSuperMixins,
          generateDart2jsHints: generateDart2jsHints,
          generateHints: generateHints,
          generateLints: generateLints);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisOptions", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (enableAsync != null) {
      result["enableAsync"] = enableAsync;
    }
    if (enableDeferredLoading != null) {
      result["enableDeferredLoading"] = enableDeferredLoading;
    }
    if (enableEnums != null) {
      result["enableEnums"] = enableEnums;
    }
    if (enableNullAwareOperators != null) {
      result["enableNullAwareOperators"] = enableNullAwareOperators;
    }
    if (enableSuperMixins != null) {
      result["enableSuperMixins"] = enableSuperMixins;
    }
    if (generateDart2jsHints != null) {
      result["generateDart2jsHints"] = generateDart2jsHints;
    }
    if (generateHints != null) {
      result["generateHints"] = generateHints;
    }
    if (generateLints != null) {
      result["generateLints"] = generateLints;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
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

/**
 * analysis.outline params
 *
 * {
 *   "file": FilePath
 *   "kind": FileKind
 *   "libraryName": optional String
 *   "outline": Outline
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisOutlineParams implements HasToJson {
  String _file;

  FileKind _kind;

  String _libraryName;

  Outline _outline;

  /**
   * The file with which the outline is associated.
   */
  String get file => _file;

  /**
   * The file with which the outline is associated.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The kind of the file.
   */
  FileKind get kind => _kind;

  /**
   * The kind of the file.
   */
  void set kind(FileKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The name of the library defined by the file using a "library" directive,
   * or referenced by a "part of" directive. If both "library" and "part of"
   * directives are present, then the "library" directive takes precedence.
   * This field will be omitted if the file has neither "library" nor "part of"
   * directives.
   */
  String get libraryName => _libraryName;

  /**
   * The name of the library defined by the file using a "library" directive,
   * or referenced by a "part of" directive. If both "library" and "part of"
   * directives are present, then the "library" directive takes precedence.
   * This field will be omitted if the file has neither "library" nor "part of"
   * directives.
   */
  void set libraryName(String value) {
    this._libraryName = value;
  }

  /**
   * The outline associated with the file.
   */
  Outline get outline => _outline;

  /**
   * The outline associated with the file.
   */
  void set outline(Outline value) {
    assert(value != null);
    this._outline = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      FileKind kind;
      if (json.containsKey("kind")) {
        kind = new FileKind.fromJson(
            jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      String libraryName;
      if (json.containsKey("libraryName")) {
        libraryName = jsonDecoder.decodeString(
            jsonPath + ".libraryName", json["libraryName"]);
      }
      Outline outline;
      if (json.containsKey("outline")) {
        outline = new Outline.fromJson(
            jsonDecoder, jsonPath + ".outline", json["outline"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "outline");
      }
      return new AnalysisOutlineParams(file, kind, outline,
          libraryName: libraryName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.outline params", json);
    }
  }

  factory AnalysisOutlineParams.fromNotification(Notification notification) {
    return new AnalysisOutlineParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["kind"] = kind.toJson();
    if (libraryName != null) {
      result["libraryName"] = libraryName;
    }
    result["outline"] = outline.toJson();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.outline", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, libraryName.hashCode);
    hash = JenkinsSmiHash.combine(hash, outline.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.overrides params
 *
 * {
 *   "file": FilePath
 *   "overrides": List<Override>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisOverridesParams implements HasToJson {
  String _file;

  List<Override> _overrides;

  /**
   * The file with which the overrides are associated.
   */
  String get file => _file;

  /**
   * The file with which the overrides are associated.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The overrides associated with the file.
   */
  List<Override> get overrides => _overrides;

  /**
   * The overrides associated with the file.
   */
  void set overrides(List<Override> value) {
    assert(value != null);
    this._overrides = value;
  }

  AnalysisOverridesParams(String file, List<Override> overrides) {
    this.file = file;
    this.overrides = overrides;
  }

  factory AnalysisOverridesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<Override> overrides;
      if (json.containsKey("overrides")) {
        overrides = jsonDecoder.decodeList(
            jsonPath + ".overrides",
            json["overrides"],
            (String jsonPath, Object json) =>
                new Override.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "overrides");
      }
      return new AnalysisOverridesParams(file, overrides);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.overrides params", json);
    }
  }

  factory AnalysisOverridesParams.fromNotification(Notification notification) {
    return new AnalysisOverridesParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["overrides"] =
        overrides.map((Override value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.overrides", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, overrides.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.reanalyze params
 *
 * {
 *   "roots": optional List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisReanalyzeParams implements RequestParams {
  List<String> _roots;

  /**
   * A list of the analysis roots that are to be re-analyzed.
   */
  List<String> get roots => _roots;

  /**
   * A list of the analysis roots that are to be re-analyzed.
   */
  void set roots(List<String> value) {
    this._roots = value;
  }

  AnalysisReanalyzeParams({List<String> roots}) {
    this.roots = roots;
  }

  factory AnalysisReanalyzeParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> roots;
      if (json.containsKey("roots")) {
        roots = jsonDecoder.decodeList(
            jsonPath + ".roots", json["roots"], jsonDecoder.decodeString);
      }
      return new AnalysisReanalyzeParams(roots: roots);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.reanalyze params", json);
    }
  }

  factory AnalysisReanalyzeParams.fromRequest(Request request) {
    return new AnalysisReanalyzeParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (roots != null) {
      result["roots"] = roots;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.reanalyze", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisReanalyzeParams) {
      return listEqual(roots, other.roots, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, roots.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.reanalyze result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisReanalyzeResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * AnalysisService
 *
 * enum {
 *   CLOSING_LABELS
 *   FOLDING
 *   HIGHLIGHTS
 *   IMPLEMENTED
 *   INVALIDATE
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 *   OVERRIDES
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisService implements Enum {
  static const AnalysisService CLOSING_LABELS =
      const AnalysisService._("CLOSING_LABELS");

  static const AnalysisService FOLDING = const AnalysisService._("FOLDING");

  static const AnalysisService HIGHLIGHTS =
      const AnalysisService._("HIGHLIGHTS");

  static const AnalysisService IMPLEMENTED =
      const AnalysisService._("IMPLEMENTED");

  /**
   * This service is not currently implemented and will become a
   * GeneralAnalysisService in a future release.
   */
  static const AnalysisService INVALIDATE =
      const AnalysisService._("INVALIDATE");

  static const AnalysisService NAVIGATION =
      const AnalysisService._("NAVIGATION");

  static const AnalysisService OCCURRENCES =
      const AnalysisService._("OCCURRENCES");

  static const AnalysisService OUTLINE = const AnalysisService._("OUTLINE");

  static const AnalysisService OVERRIDES = const AnalysisService._("OVERRIDES");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisService> VALUES = const <AnalysisService>[
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
      case "CLOSING_LABELS":
        return CLOSING_LABELS;
      case "FOLDING":
        return FOLDING;
      case "HIGHLIGHTS":
        return HIGHLIGHTS;
      case "IMPLEMENTED":
        return IMPLEMENTED;
      case "INVALIDATE":
        return INVALIDATE;
      case "NAVIGATION":
        return NAVIGATION;
      case "OCCURRENCES":
        return OCCURRENCES;
      case "OUTLINE":
        return OUTLINE;
      case "OVERRIDES":
        return OVERRIDES;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory AnalysisService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new AnalysisService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "AnalysisService", json);
  }

  @override
  String toString() => "AnalysisService.$name";

  String toJson() => name;
}

/**
 * analysis.setAnalysisRoots params
 *
 * {
 *   "included": List<FilePath>
 *   "excluded": List<FilePath>
 *   "packageRoots": optional Map<FilePath, FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetAnalysisRootsParams implements RequestParams {
  List<String> _included;

  List<String> _excluded;

  Map<String, String> _packageRoots;

  /**
   * A list of the files and directories that should be analyzed.
   */
  List<String> get included => _included;

  /**
   * A list of the files and directories that should be analyzed.
   */
  void set included(List<String> value) {
    assert(value != null);
    this._included = value;
  }

  /**
   * A list of the files and directories within the included directories that
   * should not be analyzed.
   */
  List<String> get excluded => _excluded;

  /**
   * A list of the files and directories within the included directories that
   * should not be analyzed.
   */
  void set excluded(List<String> value) {
    assert(value != null);
    this._excluded = value;
  }

  /**
   * A mapping from source directories to package roots that should override
   * the normal package: URI resolution mechanism.
   *
   * If a package root is a directory, then the analyzer will behave as though
   * the associated source directory in the map contains a special pubspec.yaml
   * file which resolves any package: URI to the corresponding path within that
   * package root directory. The effect is the same as specifying the package
   * root directory as a "--package_root" parameter to the Dart VM when
   * executing any Dart file inside the source directory.
   *
   * If a package root is a file, then the analyzer will behave as though that
   * file is a ".packages" file in the source directory. The effect is the same
   * as specifying the file as a "--packages" parameter to the Dart VM when
   * executing any Dart file inside the source directory.
   *
   * Files in any directories that are not overridden by this mapping have
   * their package: URI's resolved using the normal pubspec.yaml mechanism. If
   * this field is absent, or the empty map is specified, that indicates that
   * the normal pubspec.yaml mechanism should always be used.
   */
  Map<String, String> get packageRoots => _packageRoots;

  /**
   * A mapping from source directories to package roots that should override
   * the normal package: URI resolution mechanism.
   *
   * If a package root is a directory, then the analyzer will behave as though
   * the associated source directory in the map contains a special pubspec.yaml
   * file which resolves any package: URI to the corresponding path within that
   * package root directory. The effect is the same as specifying the package
   * root directory as a "--package_root" parameter to the Dart VM when
   * executing any Dart file inside the source directory.
   *
   * If a package root is a file, then the analyzer will behave as though that
   * file is a ".packages" file in the source directory. The effect is the same
   * as specifying the file as a "--packages" parameter to the Dart VM when
   * executing any Dart file inside the source directory.
   *
   * Files in any directories that are not overridden by this mapping have
   * their package: URI's resolved using the normal pubspec.yaml mechanism. If
   * this field is absent, or the empty map is specified, that indicates that
   * the normal pubspec.yaml mechanism should always be used.
   */
  void set packageRoots(Map<String, String> value) {
    this._packageRoots = value;
  }

  AnalysisSetAnalysisRootsParams(List<String> included, List<String> excluded,
      {Map<String, String> packageRoots}) {
    this.included = included;
    this.excluded = excluded;
    this.packageRoots = packageRoots;
  }

  factory AnalysisSetAnalysisRootsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> included;
      if (json.containsKey("included")) {
        included = jsonDecoder.decodeList(
            jsonPath + ".included", json["included"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "included");
      }
      List<String> excluded;
      if (json.containsKey("excluded")) {
        excluded = jsonDecoder.decodeList(
            jsonPath + ".excluded", json["excluded"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "excluded");
      }
      Map<String, String> packageRoots;
      if (json.containsKey("packageRoots")) {
        packageRoots = jsonDecoder.decodeMap(
            jsonPath + ".packageRoots", json["packageRoots"],
            valueDecoder: jsonDecoder.decodeString);
      }
      return new AnalysisSetAnalysisRootsParams(included, excluded,
          packageRoots: packageRoots);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.setAnalysisRoots params", json);
    }
  }

  factory AnalysisSetAnalysisRootsParams.fromRequest(Request request) {
    return new AnalysisSetAnalysisRootsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["included"] = included;
    result["excluded"] = excluded;
    if (packageRoots != null) {
      result["packageRoots"] = packageRoots;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.setAnalysisRoots", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, included.hashCode);
    hash = JenkinsSmiHash.combine(hash, excluded.hashCode);
    hash = JenkinsSmiHash.combine(hash, packageRoots.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.setAnalysisRoots result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetAnalysisRootsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * analysis.setGeneralSubscriptions params
 *
 * {
 *   "subscriptions": List<GeneralAnalysisService>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetGeneralSubscriptionsParams implements RequestParams {
  List<GeneralAnalysisService> _subscriptions;

  /**
   * A list of the services being subscribed to.
   */
  List<GeneralAnalysisService> get subscriptions => _subscriptions;

  /**
   * A list of the services being subscribed to.
   */
  void set subscriptions(List<GeneralAnalysisService> value) {
    assert(value != null);
    this._subscriptions = value;
  }

  AnalysisSetGeneralSubscriptionsParams(
      List<GeneralAnalysisService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<GeneralAnalysisService> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + ".subscriptions",
            json["subscriptions"],
            (String jsonPath, Object json) =>
                new GeneralAnalysisService.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "subscriptions");
      }
      return new AnalysisSetGeneralSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.setGeneralSubscriptions params", json);
    }
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromRequest(Request request) {
    return new AnalysisSetGeneralSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = subscriptions
        .map((GeneralAnalysisService value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.setGeneralSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.setGeneralSubscriptions result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetGeneralSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * analysis.setPriorityFiles params
 *
 * {
 *   "files": List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetPriorityFilesParams implements RequestParams {
  List<String> _files;

  /**
   * The files that are to be a priority for analysis.
   */
  List<String> get files => _files;

  /**
   * The files that are to be a priority for analysis.
   */
  void set files(List<String> value) {
    assert(value != null);
    this._files = value;
  }

  AnalysisSetPriorityFilesParams(List<String> files) {
    this.files = files;
  }

  factory AnalysisSetPriorityFilesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(
            jsonPath + ".files", json["files"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.setPriorityFiles params", json);
    }
  }

  factory AnalysisSetPriorityFilesParams.fromRequest(Request request) {
    return new AnalysisSetPriorityFilesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = files;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.setPriorityFiles", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisSetPriorityFilesParams) {
      return listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.setPriorityFiles result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetPriorityFilesResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * analysis.setSubscriptions params
 *
 * {
 *   "subscriptions": Map<AnalysisService, List<FilePath>>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetSubscriptionsParams implements RequestParams {
  Map<AnalysisService, List<String>> _subscriptions;

  /**
   * A table mapping services to a list of the files being subscribed to the
   * service.
   */
  Map<AnalysisService, List<String>> get subscriptions => _subscriptions;

  /**
   * A table mapping services to a list of the files being subscribed to the
   * service.
   */
  void set subscriptions(Map<AnalysisService, List<String>> value) {
    assert(value != null);
    this._subscriptions = value;
  }

  AnalysisSetSubscriptionsParams(
      Map<AnalysisService, List<String>> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory AnalysisSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<AnalysisService, List<String>> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder.decodeMap(
            jsonPath + ".subscriptions", json["subscriptions"],
            keyDecoder: (String jsonPath, Object json) =>
                new AnalysisService.fromJson(jsonDecoder, jsonPath, json),
            valueDecoder: (String jsonPath, Object json) => jsonDecoder
                .decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "subscriptions");
      }
      return new AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.setSubscriptions params", json);
    }
  }

  factory AnalysisSetSubscriptionsParams.fromRequest(Request request) {
    return new AnalysisSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = mapMap(subscriptions,
        keyCallback: (AnalysisService value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.setSubscriptions result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * AnalysisStatus
 *
 * {
 *   "isAnalyzing": bool
 *   "analysisTarget": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisStatus implements HasToJson {
  bool _isAnalyzing;

  String _analysisTarget;

  /**
   * True if analysis is currently being performed.
   */
  bool get isAnalyzing => _isAnalyzing;

  /**
   * True if analysis is currently being performed.
   */
  void set isAnalyzing(bool value) {
    assert(value != null);
    this._isAnalyzing = value;
  }

  /**
   * The name of the current target of analysis. This field is omitted if
   * analyzing is false.
   */
  String get analysisTarget => _analysisTarget;

  /**
   * The name of the current target of analysis. This field is omitted if
   * analyzing is false.
   */
  void set analysisTarget(String value) {
    this._analysisTarget = value;
  }

  AnalysisStatus(bool isAnalyzing, {String analysisTarget}) {
    this.isAnalyzing = isAnalyzing;
    this.analysisTarget = analysisTarget;
  }

  factory AnalysisStatus.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isAnalyzing;
      if (json.containsKey("isAnalyzing")) {
        isAnalyzing = jsonDecoder.decodeBool(
            jsonPath + ".isAnalyzing", json["isAnalyzing"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isAnalyzing");
      }
      String analysisTarget;
      if (json.containsKey("analysisTarget")) {
        analysisTarget = jsonDecoder.decodeString(
            jsonPath + ".analysisTarget", json["analysisTarget"]);
      }
      return new AnalysisStatus(isAnalyzing, analysisTarget: analysisTarget);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisStatus", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["isAnalyzing"] = isAnalyzing;
    if (analysisTarget != null) {
      result["analysisTarget"] = analysisTarget;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, isAnalyzing.hashCode);
    hash = JenkinsSmiHash.combine(hash, analysisTarget.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.updateContent params
 *
 * {
 *   "files": Map<FilePath, AddContentOverlay | ChangeContentOverlay | RemoveContentOverlay>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisUpdateContentParams implements RequestParams {
  Map<String, dynamic> _files;

  /**
   * A table mapping the files whose content has changed to a description of
   * the content change.
   */
  Map<String, dynamic> get files => _files;

  /**
   * A table mapping the files whose content has changed to a description of
   * the content change.
   */
  void set files(Map<String, dynamic> value) {
    assert(value != null);
    this._files = value;
  }

  AnalysisUpdateContentParams(Map<String, dynamic> files) {
    this.files = files;
  }

  factory AnalysisUpdateContentParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<String, dynamic> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeMap(jsonPath + ".files", json["files"],
            valueDecoder: (String jsonPath, Object json) =>
                jsonDecoder.decodeUnion(jsonPath, json, "type", {
                  "add": (String jsonPath, Object json) =>
                      new AddContentOverlay.fromJson(
                          jsonDecoder, jsonPath, json),
                  "change": (String jsonPath, Object json) =>
                      new ChangeContentOverlay.fromJson(
                          jsonDecoder, jsonPath, json),
                  "remove": (String jsonPath, Object json) =>
                      new RemoveContentOverlay.fromJson(
                          jsonDecoder, jsonPath, json)
                }));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.updateContent params", json);
    }
  }

  factory AnalysisUpdateContentParams.fromRequest(Request request) {
    return new AnalysisUpdateContentParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] =
        mapMap(files, valueCallback: (dynamic value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.updateContent", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateContentParams) {
      return mapEqual(files, other.files, (dynamic a, dynamic b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.updateContent result
 *
 * {
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisUpdateContentResult implements ResponseResult {
  AnalysisUpdateContentResult();

  factory AnalysisUpdateContentResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      return new AnalysisUpdateContentResult();
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.updateContent result", json);
    }
  }

  factory AnalysisUpdateContentResult.fromResponse(Response response) {
    return new AnalysisUpdateContentResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateContentResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.updateOptions params
 *
 * {
 *   "options": AnalysisOptions
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisUpdateOptionsParams implements RequestParams {
  AnalysisOptions _options;

  /**
   * The options that are to be used to control analysis.
   */
  AnalysisOptions get options => _options;

  /**
   * The options that are to be used to control analysis.
   */
  void set options(AnalysisOptions value) {
    assert(value != null);
    this._options = value;
  }

  AnalysisUpdateOptionsParams(AnalysisOptions options) {
    this.options = options;
  }

  factory AnalysisUpdateOptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisOptions options;
      if (json.containsKey("options")) {
        options = new AnalysisOptions.fromJson(
            jsonDecoder, jsonPath + ".options", json["options"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "options");
      }
      return new AnalysisUpdateOptionsParams(options);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "analysis.updateOptions params", json);
    }
  }

  factory AnalysisUpdateOptionsParams.fromRequest(Request request) {
    return new AnalysisUpdateOptionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["options"] = options.toJson();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.updateOptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalysisUpdateOptionsParams) {
      return options == other.options;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.updateOptions result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisUpdateOptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * analytics.enable params
 *
 * {
 *   "value": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsEnableParams implements RequestParams {
  bool _value;

  /**
   * Enable or disable analytics.
   */
  bool get value => _value;

  /**
   * Enable or disable analytics.
   */
  void set value(bool value) {
    assert(value != null);
    this._value = value;
  }

  AnalyticsEnableParams(bool value) {
    this.value = value;
  }

  factory AnalyticsEnableParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool value;
      if (json.containsKey("value")) {
        value = jsonDecoder.decodeBool(jsonPath + ".value", json["value"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "value");
      }
      return new AnalyticsEnableParams(value);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analytics.enable params", json);
    }
  }

  factory AnalyticsEnableParams.fromRequest(Request request) {
    return new AnalyticsEnableParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["value"] = value;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analytics.enable", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsEnableParams) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analytics.enable result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsEnableResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * analytics.isEnabled params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsIsEnabledParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "analytics.isEnabled", null);
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

/**
 * analytics.isEnabled result
 *
 * {
 *   "enabled": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsIsEnabledResult implements ResponseResult {
  bool _enabled;

  /**
   * Whether sending analytics is enabled or not.
   */
  bool get enabled => _enabled;

  /**
   * Whether sending analytics is enabled or not.
   */
  void set enabled(bool value) {
    assert(value != null);
    this._enabled = value;
  }

  AnalyticsIsEnabledResult(bool enabled) {
    this.enabled = enabled;
  }

  factory AnalyticsIsEnabledResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool enabled;
      if (json.containsKey("enabled")) {
        enabled =
            jsonDecoder.decodeBool(jsonPath + ".enabled", json["enabled"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "enabled");
      }
      return new AnalyticsIsEnabledResult(enabled);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analytics.isEnabled result", json);
    }
  }

  factory AnalyticsIsEnabledResult.fromResponse(Response response) {
    return new AnalyticsIsEnabledResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["enabled"] = enabled;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsIsEnabledResult) {
      return enabled == other.enabled;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, enabled.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analytics.sendEvent params
 *
 * {
 *   "action": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsSendEventParams implements RequestParams {
  String _action;

  /**
   * The value used to indicate which action was performed.
   */
  String get action => _action;

  /**
   * The value used to indicate which action was performed.
   */
  void set action(String value) {
    assert(value != null);
    this._action = value;
  }

  AnalyticsSendEventParams(String action) {
    this.action = action;
  }

  factory AnalyticsSendEventParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String action;
      if (json.containsKey("action")) {
        action = jsonDecoder.decodeString(jsonPath + ".action", json["action"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "action");
      }
      return new AnalyticsSendEventParams(action);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analytics.sendEvent params", json);
    }
  }

  factory AnalyticsSendEventParams.fromRequest(Request request) {
    return new AnalyticsSendEventParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["action"] = action;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analytics.sendEvent", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendEventParams) {
      return action == other.action;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, action.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analytics.sendEvent result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsSendEventResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * analytics.sendTiming params
 *
 * {
 *   "event": String
 *   "millis": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsSendTimingParams implements RequestParams {
  String _event;

  int _millis;

  /**
   * The name of the event.
   */
  String get event => _event;

  /**
   * The name of the event.
   */
  void set event(String value) {
    assert(value != null);
    this._event = value;
  }

  /**
   * The duration of the event in milliseconds.
   */
  int get millis => _millis;

  /**
   * The duration of the event in milliseconds.
   */
  void set millis(int value) {
    assert(value != null);
    this._millis = value;
  }

  AnalyticsSendTimingParams(String event, int millis) {
    this.event = event;
    this.millis = millis;
  }

  factory AnalyticsSendTimingParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String event;
      if (json.containsKey("event")) {
        event = jsonDecoder.decodeString(jsonPath + ".event", json["event"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "event");
      }
      int millis;
      if (json.containsKey("millis")) {
        millis = jsonDecoder.decodeInt(jsonPath + ".millis", json["millis"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "millis");
      }
      return new AnalyticsSendTimingParams(event, millis);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analytics.sendTiming params", json);
    }
  }

  factory AnalyticsSendTimingParams.fromRequest(Request request) {
    return new AnalyticsSendTimingParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["event"] = event;
    result["millis"] = millis;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analytics.sendTiming", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is AnalyticsSendTimingParams) {
      return event == other.event && millis == other.millis;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, event.hashCode);
    hash = JenkinsSmiHash.combine(hash, millis.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analytics.sendTiming result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalyticsSendTimingResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * ClosingLabel
 *
 * {
 *   "offset": int
 *   "length": int
 *   "label": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ClosingLabel implements HasToJson {
  int _offset;

  int _length;

  String _label;

  /**
   * The offset of the construct being labelled.
   */
  int get offset => _offset;

  /**
   * The offset of the construct being labelled.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the whole construct to be labelled.
   */
  int get length => _length;

  /**
   * The length of the whole construct to be labelled.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The label associated with this range that should be displayed to the user.
   */
  String get label => _label;

  /**
   * The label associated with this range that should be displayed to the user.
   */
  void set label(String value) {
    assert(value != null);
    this._label = value;
  }

  ClosingLabel(int offset, int length, String label) {
    this.offset = offset;
    this.length = length;
    this.label = label;
  }

  factory ClosingLabel.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      String label;
      if (json.containsKey("label")) {
        label = jsonDecoder.decodeString(jsonPath + ".label", json["label"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "label");
      }
      return new ClosingLabel(offset, length, label);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ClosingLabel", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    result["label"] = label;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * completion.getSuggestions params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionGetSuggestionsParams implements RequestParams {
  String _file;

  int _offset;

  /**
   * The file containing the point at which suggestions are to be made.
   */
  String get file => _file;

  /**
   * The file containing the point at which suggestions are to be made.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset within the file at which suggestions are to be made.
   */
  int get offset => _offset;

  /**
   * The offset within the file at which suggestions are to be made.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  CompletionGetSuggestionsParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory CompletionGetSuggestionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      return new CompletionGetSuggestionsParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "completion.getSuggestions params", json);
    }
  }

  factory CompletionGetSuggestionsParams.fromRequest(Request request) {
    return new CompletionGetSuggestionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "completion.getSuggestions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * completion.getSuggestions result
 *
 * {
 *   "id": CompletionId
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionGetSuggestionsResult implements ResponseResult {
  String _id;

  /**
   * The identifier used to associate results with this completion request.
   */
  String get id => _id;

  /**
   * The identifier used to associate results with this completion request.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  CompletionGetSuggestionsResult(String id) {
    this.id = id;
  }

  factory CompletionGetSuggestionsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      return new CompletionGetSuggestionsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "completion.getSuggestions result", json);
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(Response response) {
    return new CompletionGetSuggestionsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionGetSuggestionsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * completion.results params
 *
 * {
 *   "id": CompletionId
 *   "replacementOffset": int
 *   "replacementLength": int
 *   "results": List<CompletionSuggestion>
 *   "isLast": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionResultsParams implements HasToJson {
  String _id;

  int _replacementOffset;

  int _replacementLength;

  List<CompletionSuggestion> _results;

  bool _isLast;

  /**
   * The id associated with the completion.
   */
  String get id => _id;

  /**
   * The id associated with the completion.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  /**
   * The offset of the start of the text to be replaced. This will be different
   * than the offset used to request the completion suggestions if there was a
   * portion of an identifier before the original offset. In particular, the
   * replacementOffset will be the offset of the beginning of said identifier.
   */
  int get replacementOffset => _replacementOffset;

  /**
   * The offset of the start of the text to be replaced. This will be different
   * than the offset used to request the completion suggestions if there was a
   * portion of an identifier before the original offset. In particular, the
   * replacementOffset will be the offset of the beginning of said identifier.
   */
  void set replacementOffset(int value) {
    assert(value != null);
    this._replacementOffset = value;
  }

  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   */
  int get replacementLength => _replacementLength;

  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   */
  void set replacementLength(int value) {
    assert(value != null);
    this._replacementLength = value;
  }

  /**
   * The completion suggestions being reported. The notification contains all
   * possible completions at the requested cursor position, even those that do
   * not match the characters the user has already typed. This allows the
   * client to respond to further keystrokes from the user without having to
   * make additional requests.
   */
  List<CompletionSuggestion> get results => _results;

  /**
   * The completion suggestions being reported. The notification contains all
   * possible completions at the requested cursor position, even those that do
   * not match the characters the user has already typed. This allows the
   * client to respond to further keystrokes from the user without having to
   * make additional requests.
   */
  void set results(List<CompletionSuggestion> value) {
    assert(value != null);
    this._results = value;
  }

  /**
   * True if this is that last set of results that will be returned for the
   * indicated completion.
   */
  bool get isLast => _isLast;

  /**
   * True if this is that last set of results that will be returned for the
   * indicated completion.
   */
  void set isLast(bool value) {
    assert(value != null);
    this._isLast = value;
  }

  CompletionResultsParams(String id, int replacementOffset,
      int replacementLength, List<CompletionSuggestion> results, bool isLast) {
    this.id = id;
    this.replacementOffset = replacementOffset;
    this.replacementLength = replacementLength;
    this.results = results;
    this.isLast = isLast;
  }

  factory CompletionResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      int replacementOffset;
      if (json.containsKey("replacementOffset")) {
        replacementOffset = jsonDecoder.decodeInt(
            jsonPath + ".replacementOffset", json["replacementOffset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "replacementOffset");
      }
      int replacementLength;
      if (json.containsKey("replacementLength")) {
        replacementLength = jsonDecoder.decodeInt(
            jsonPath + ".replacementLength", json["replacementLength"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "replacementLength");
      }
      List<CompletionSuggestion> results;
      if (json.containsKey("results")) {
        results = jsonDecoder.decodeList(
            jsonPath + ".results",
            json["results"],
            (String jsonPath, Object json) =>
                new CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "results");
      }
      bool isLast;
      if (json.containsKey("isLast")) {
        isLast = jsonDecoder.decodeBool(jsonPath + ".isLast", json["isLast"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isLast");
      }
      return new CompletionResultsParams(
          id, replacementOffset, replacementLength, results, isLast);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "completion.results params", json);
    }
  }

  factory CompletionResultsParams.fromNotification(Notification notification) {
    return new CompletionResultsParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    result["replacementOffset"] = replacementOffset;
    result["replacementLength"] = replacementLength;
    result["results"] =
        results.map((CompletionSuggestion value) => value.toJson()).toList();
    result["isLast"] = isLast;
    return result;
  }

  Notification toNotification() {
    return new Notification("completion.results", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is CompletionResultsParams) {
      return id == other.id &&
          replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          listEqual(results, other.results,
              (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          isLast == other.isLast;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacementOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacementLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, results.hashCode);
    hash = JenkinsSmiHash.combine(hash, isLast.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ContextData
 *
 * {
 *   "name": String
 *   "explicitFileCount": int
 *   "implicitFileCount": int
 *   "workItemQueueLength": int
 *   "cacheEntryExceptions": List<String>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ContextData implements HasToJson {
  String _name;

  int _explicitFileCount;

  int _implicitFileCount;

  int _workItemQueueLength;

  List<String> _cacheEntryExceptions;

  /**
   * The name of the context.
   */
  String get name => _name;

  /**
   * The name of the context.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * Explicitly analyzed files.
   */
  int get explicitFileCount => _explicitFileCount;

  /**
   * Explicitly analyzed files.
   */
  void set explicitFileCount(int value) {
    assert(value != null);
    this._explicitFileCount = value;
  }

  /**
   * Implicitly analyzed files.
   */
  int get implicitFileCount => _implicitFileCount;

  /**
   * Implicitly analyzed files.
   */
  void set implicitFileCount(int value) {
    assert(value != null);
    this._implicitFileCount = value;
  }

  /**
   * The number of work items in the queue.
   */
  int get workItemQueueLength => _workItemQueueLength;

  /**
   * The number of work items in the queue.
   */
  void set workItemQueueLength(int value) {
    assert(value != null);
    this._workItemQueueLength = value;
  }

  /**
   * Exceptions associated with cache entries.
   */
  List<String> get cacheEntryExceptions => _cacheEntryExceptions;

  /**
   * Exceptions associated with cache entries.
   */
  void set cacheEntryExceptions(List<String> value) {
    assert(value != null);
    this._cacheEntryExceptions = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      int explicitFileCount;
      if (json.containsKey("explicitFileCount")) {
        explicitFileCount = jsonDecoder.decodeInt(
            jsonPath + ".explicitFileCount", json["explicitFileCount"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "explicitFileCount");
      }
      int implicitFileCount;
      if (json.containsKey("implicitFileCount")) {
        implicitFileCount = jsonDecoder.decodeInt(
            jsonPath + ".implicitFileCount", json["implicitFileCount"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "implicitFileCount");
      }
      int workItemQueueLength;
      if (json.containsKey("workItemQueueLength")) {
        workItemQueueLength = jsonDecoder.decodeInt(
            jsonPath + ".workItemQueueLength", json["workItemQueueLength"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "workItemQueueLength");
      }
      List<String> cacheEntryExceptions;
      if (json.containsKey("cacheEntryExceptions")) {
        cacheEntryExceptions = jsonDecoder.decodeList(
            jsonPath + ".cacheEntryExceptions",
            json["cacheEntryExceptions"],
            jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "cacheEntryExceptions");
      }
      return new ContextData(name, explicitFileCount, implicitFileCount,
          workItemQueueLength, cacheEntryExceptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ContextData", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    result["explicitFileCount"] = explicitFileCount;
    result["implicitFileCount"] = implicitFileCount;
    result["workItemQueueLength"] = workItemQueueLength;
    result["cacheEntryExceptions"] = cacheEntryExceptions;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, explicitFileCount.hashCode);
    hash = JenkinsSmiHash.combine(hash, implicitFileCount.hashCode);
    hash = JenkinsSmiHash.combine(hash, workItemQueueLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, cacheEntryExceptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * convertGetterToMethod feedback
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

/**
 * convertGetterToMethod options
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

/**
 * convertMethodToGetter feedback
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

/**
 * convertMethodToGetter options
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

/**
 * diagnostic.getDiagnostics params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DiagnosticGetDiagnosticsParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "diagnostic.getDiagnostics", null);
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

/**
 * diagnostic.getDiagnostics result
 *
 * {
 *   "contexts": List<ContextData>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DiagnosticGetDiagnosticsResult implements ResponseResult {
  List<ContextData> _contexts;

  /**
   * The list of analysis contexts.
   */
  List<ContextData> get contexts => _contexts;

  /**
   * The list of analysis contexts.
   */
  void set contexts(List<ContextData> value) {
    assert(value != null);
    this._contexts = value;
  }

  DiagnosticGetDiagnosticsResult(List<ContextData> contexts) {
    this.contexts = contexts;
  }

  factory DiagnosticGetDiagnosticsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ContextData> contexts;
      if (json.containsKey("contexts")) {
        contexts = jsonDecoder.decodeList(
            jsonPath + ".contexts",
            json["contexts"],
            (String jsonPath, Object json) =>
                new ContextData.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "contexts");
      }
      return new DiagnosticGetDiagnosticsResult(contexts);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "diagnostic.getDiagnostics result", json);
    }
  }

  factory DiagnosticGetDiagnosticsResult.fromResponse(Response response) {
    return new DiagnosticGetDiagnosticsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["contexts"] =
        contexts.map((ContextData value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, contexts.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * diagnostic.getServerPort params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DiagnosticGetServerPortParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "diagnostic.getServerPort", null);
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

/**
 * diagnostic.getServerPort result
 *
 * {
 *   "port": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class DiagnosticGetServerPortResult implements ResponseResult {
  int _port;

  /**
   * The diagnostic server port.
   */
  int get port => _port;

  /**
   * The diagnostic server port.
   */
  void set port(int value) {
    assert(value != null);
    this._port = value;
  }

  DiagnosticGetServerPortResult(int port) {
    this.port = port;
  }

  factory DiagnosticGetServerPortResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int port;
      if (json.containsKey("port")) {
        port = jsonDecoder.decodeInt(jsonPath + ".port", json["port"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "port");
      }
      return new DiagnosticGetServerPortResult(port);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "diagnostic.getServerPort result", json);
    }
  }

  factory DiagnosticGetServerPortResult.fromResponse(Response response) {
    return new DiagnosticGetServerPortResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["port"] = port;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is DiagnosticGetServerPortResult) {
      return port == other.port;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, port.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.format params
 *
 * {
 *   "file": FilePath
 *   "selectionOffset": int
 *   "selectionLength": int
 *   "lineLength": optional int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditFormatParams implements RequestParams {
  String _file;

  int _selectionOffset;

  int _selectionLength;

  int _lineLength;

  /**
   * The file containing the code to be formatted.
   */
  String get file => _file;

  /**
   * The file containing the code to be formatted.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the current selection in the file.
   */
  int get selectionOffset => _selectionOffset;

  /**
   * The offset of the current selection in the file.
   */
  void set selectionOffset(int value) {
    assert(value != null);
    this._selectionOffset = value;
  }

  /**
   * The length of the current selection in the file.
   */
  int get selectionLength => _selectionLength;

  /**
   * The length of the current selection in the file.
   */
  void set selectionLength(int value) {
    assert(value != null);
    this._selectionLength = value;
  }

  /**
   * The line length to be used by the formatter.
   */
  int get lineLength => _lineLength;

  /**
   * The line length to be used by the formatter.
   */
  void set lineLength(int value) {
    this._lineLength = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int selectionOffset;
      if (json.containsKey("selectionOffset")) {
        selectionOffset = jsonDecoder.decodeInt(
            jsonPath + ".selectionOffset", json["selectionOffset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "selectionOffset");
      }
      int selectionLength;
      if (json.containsKey("selectionLength")) {
        selectionLength = jsonDecoder.decodeInt(
            jsonPath + ".selectionLength", json["selectionLength"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "selectionLength");
      }
      int lineLength;
      if (json.containsKey("lineLength")) {
        lineLength =
            jsonDecoder.decodeInt(jsonPath + ".lineLength", json["lineLength"]);
      }
      return new EditFormatParams(file, selectionOffset, selectionLength,
          lineLength: lineLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.format params", json);
    }
  }

  factory EditFormatParams.fromRequest(Request request) {
    return new EditFormatParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["selectionOffset"] = selectionOffset;
    result["selectionLength"] = selectionLength;
    if (lineLength != null) {
      result["lineLength"] = lineLength;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.format", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, lineLength.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.format result
 *
 * {
 *   "edits": List<SourceEdit>
 *   "selectionOffset": int
 *   "selectionLength": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditFormatResult implements ResponseResult {
  List<SourceEdit> _edits;

  int _selectionOffset;

  int _selectionLength;

  /**
   * The edit(s) to be applied in order to format the code. The list will be
   * empty if the code was already formatted (there are no changes).
   */
  List<SourceEdit> get edits => _edits;

  /**
   * The edit(s) to be applied in order to format the code. The list will be
   * empty if the code was already formatted (there are no changes).
   */
  void set edits(List<SourceEdit> value) {
    assert(value != null);
    this._edits = value;
  }

  /**
   * The offset of the selection after formatting the code.
   */
  int get selectionOffset => _selectionOffset;

  /**
   * The offset of the selection after formatting the code.
   */
  void set selectionOffset(int value) {
    assert(value != null);
    this._selectionOffset = value;
  }

  /**
   * The length of the selection after formatting the code.
   */
  int get selectionLength => _selectionLength;

  /**
   * The length of the selection after formatting the code.
   */
  void set selectionLength(int value) {
    assert(value != null);
    this._selectionLength = value;
  }

  EditFormatResult(
      List<SourceEdit> edits, int selectionOffset, int selectionLength) {
    this.edits = edits;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
  }

  factory EditFormatResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder.decodeList(
            jsonPath + ".edits",
            json["edits"],
            (String jsonPath, Object json) =>
                new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edits");
      }
      int selectionOffset;
      if (json.containsKey("selectionOffset")) {
        selectionOffset = jsonDecoder.decodeInt(
            jsonPath + ".selectionOffset", json["selectionOffset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "selectionOffset");
      }
      int selectionLength;
      if (json.containsKey("selectionLength")) {
        selectionLength = jsonDecoder.decodeInt(
            jsonPath + ".selectionLength", json["selectionLength"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "selectionLength");
      }
      return new EditFormatResult(edits, selectionOffset, selectionLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.format result", json);
    }
  }

  factory EditFormatResult.fromResponse(Response response) {
    return new EditFormatResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edits"] = edits.map((SourceEdit value) => value.toJson()).toList();
    result["selectionOffset"] = selectionOffset;
    result["selectionLength"] = selectionLength;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getAssists params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetAssistsParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /**
   * The file containing the code for which assists are being requested.
   */
  String get file => _file;

  /**
   * The file containing the code for which assists are being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the code for which assists are being requested.
   */
  int get offset => _offset;

  /**
   * The offset of the code for which assists are being requested.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the code for which assists are being requested.
   */
  int get length => _length;

  /**
   * The length of the code for which assists are being requested.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  EditGetAssistsParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory EditGetAssistsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new EditGetAssistsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAssists params", json);
    }
  }

  factory EditGetAssistsParams.fromRequest(Request request) {
    return new EditGetAssistsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.getAssists", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getAssists result
 *
 * {
 *   "assists": List<SourceChange>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetAssistsResult implements ResponseResult {
  List<SourceChange> _assists;

  /**
   * The assists that are available at the given location.
   */
  List<SourceChange> get assists => _assists;

  /**
   * The assists that are available at the given location.
   */
  void set assists(List<SourceChange> value) {
    assert(value != null);
    this._assists = value;
  }

  EditGetAssistsResult(List<SourceChange> assists) {
    this.assists = assists;
  }

  factory EditGetAssistsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<SourceChange> assists;
      if (json.containsKey("assists")) {
        assists = jsonDecoder.decodeList(
            jsonPath + ".assists",
            json["assists"],
            (String jsonPath, Object json) =>
                new SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "assists");
      }
      return new EditGetAssistsResult(assists);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAssists result", json);
    }
  }

  factory EditGetAssistsResult.fromResponse(Response response) {
    return new EditGetAssistsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["assists"] =
        assists.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, assists.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getAvailableRefactorings params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetAvailableRefactoringsParams implements RequestParams {
  String _file;

  int _offset;

  int _length;

  /**
   * The file containing the code on which the refactoring would be based.
   */
  String get file => _file;

  /**
   * The file containing the code on which the refactoring would be based.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the code on which the refactoring would be based.
   */
  int get offset => _offset;

  /**
   * The offset of the code on which the refactoring would be based.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the code on which the refactoring would be based.
   */
  int get length => _length;

  /**
   * The length of the code on which the refactoring would be based.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  EditGetAvailableRefactoringsParams(String file, int offset, int length) {
    this.file = file;
    this.offset = offset;
    this.length = length;
  }

  factory EditGetAvailableRefactoringsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new EditGetAvailableRefactoringsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.getAvailableRefactorings params", json);
    }
  }

  factory EditGetAvailableRefactoringsParams.fromRequest(Request request) {
    return new EditGetAvailableRefactoringsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.getAvailableRefactorings", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getAvailableRefactorings result
 *
 * {
 *   "kinds": List<RefactoringKind>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetAvailableRefactoringsResult implements ResponseResult {
  List<RefactoringKind> _kinds;

  /**
   * The kinds of refactorings that are valid for the given selection.
   */
  List<RefactoringKind> get kinds => _kinds;

  /**
   * The kinds of refactorings that are valid for the given selection.
   */
  void set kinds(List<RefactoringKind> value) {
    assert(value != null);
    this._kinds = value;
  }

  EditGetAvailableRefactoringsResult(List<RefactoringKind> kinds) {
    this.kinds = kinds;
  }

  factory EditGetAvailableRefactoringsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<RefactoringKind> kinds;
      if (json.containsKey("kinds")) {
        kinds = jsonDecoder.decodeList(
            jsonPath + ".kinds",
            json["kinds"],
            (String jsonPath, Object json) =>
                new RefactoringKind.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kinds");
      }
      return new EditGetAvailableRefactoringsResult(kinds);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.getAvailableRefactorings result", json);
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(Response response) {
    return new EditGetAvailableRefactoringsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kinds"] =
        kinds.map((RefactoringKind value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kinds.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getFixes params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetFixesParams implements RequestParams {
  String _file;

  int _offset;

  /**
   * The file containing the errors for which fixes are being requested.
   */
  String get file => _file;

  /**
   * The file containing the errors for which fixes are being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset used to select the errors for which fixes will be returned.
   */
  int get offset => _offset;

  /**
   * The offset used to select the errors for which fixes will be returned.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  EditGetFixesParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory EditGetFixesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      return new EditGetFixesParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getFixes params", json);
    }
  }

  factory EditGetFixesParams.fromRequest(Request request) {
    return new EditGetFixesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.getFixes", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetFixesParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getFixes result
 *
 * {
 *   "fixes": List<AnalysisErrorFixes>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetFixesResult implements ResponseResult {
  List<AnalysisErrorFixes> _fixes;

  /**
   * The fixes that are available for the errors at the given offset.
   */
  List<AnalysisErrorFixes> get fixes => _fixes;

  /**
   * The fixes that are available for the errors at the given offset.
   */
  void set fixes(List<AnalysisErrorFixes> value) {
    assert(value != null);
    this._fixes = value;
  }

  EditGetFixesResult(List<AnalysisErrorFixes> fixes) {
    this.fixes = fixes;
  }

  factory EditGetFixesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<AnalysisErrorFixes> fixes;
      if (json.containsKey("fixes")) {
        fixes = jsonDecoder.decodeList(
            jsonPath + ".fixes",
            json["fixes"],
            (String jsonPath, Object json) =>
                new AnalysisErrorFixes.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "fixes");
      }
      return new EditGetFixesResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getFixes result", json);
    }
  }

  factory EditGetFixesResult.fromResponse(Response response) {
    return new EditGetFixesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["fixes"] =
        fixes.map((AnalysisErrorFixes value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, fixes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getPostfixCompletion params
 *
 * {
 *   "file": FilePath
 *   "key": String
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetPostfixCompletionParams implements RequestParams {
  String _file;

  String _key;

  int _offset;

  /**
   * The file containing the postfix template to be expanded.
   */
  String get file => _file;

  /**
   * The file containing the postfix template to be expanded.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The unique name that identifies the template in use.
   */
  String get key => _key;

  /**
   * The unique name that identifies the template in use.
   */
  void set key(String value) {
    assert(value != null);
    this._key = value;
  }

  /**
   * The offset used to identify the code to which the template will be
   * applied.
   */
  int get offset => _offset;

  /**
   * The offset used to identify the code to which the template will be
   * applied.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  EditGetPostfixCompletionParams(String file, String key, int offset) {
    this.file = file;
    this.key = key;
    this.offset = offset;
  }

  factory EditGetPostfixCompletionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      String key;
      if (json.containsKey("key")) {
        key = jsonDecoder.decodeString(jsonPath + ".key", json["key"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "key");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      return new EditGetPostfixCompletionParams(file, key, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.getPostfixCompletion params", json);
    }
  }

  factory EditGetPostfixCompletionParams.fromRequest(Request request) {
    return new EditGetPostfixCompletionParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["key"] = key;
    result["offset"] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.getPostfixCompletion", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetPostfixCompletionParams) {
      return file == other.file && key == other.key && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, key.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getPostfixCompletion result
 *
 * {
 *   "change": SourceChange
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetPostfixCompletionResult implements ResponseResult {
  SourceChange _change;

  /**
   * The change to be applied in order to complete the statement.
   */
  SourceChange get change => _change;

  /**
   * The change to be applied in order to complete the statement.
   */
  void set change(SourceChange value) {
    assert(value != null);
    this._change = value;
  }

  EditGetPostfixCompletionResult(SourceChange change) {
    this.change = change;
  }

  factory EditGetPostfixCompletionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      SourceChange change;
      if (json.containsKey("change")) {
        change = new SourceChange.fromJson(
            jsonDecoder, jsonPath + ".change", json["change"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "change");
      }
      return new EditGetPostfixCompletionResult(change);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.getPostfixCompletion result", json);
    }
  }

  factory EditGetPostfixCompletionResult.fromResponse(Response response) {
    return new EditGetPostfixCompletionResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["change"] = change.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetPostfixCompletionResult) {
      return change == other.change;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getRefactoring params
 *
 * {
 *   "kind": RefactoringKind
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "validateOnly": bool
 *   "options": optional RefactoringOptions
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetRefactoringParams implements RequestParams {
  RefactoringKind _kind;

  String _file;

  int _offset;

  int _length;

  bool _validateOnly;

  RefactoringOptions _options;

  /**
   * The kind of refactoring to be performed.
   */
  RefactoringKind get kind => _kind;

  /**
   * The kind of refactoring to be performed.
   */
  void set kind(RefactoringKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The file containing the code involved in the refactoring.
   */
  String get file => _file;

  /**
   * The file containing the code involved in the refactoring.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the region involved in the refactoring.
   */
  int get offset => _offset;

  /**
   * The offset of the region involved in the refactoring.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region involved in the refactoring.
   */
  int get length => _length;

  /**
   * The length of the region involved in the refactoring.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * True if the client is only requesting that the values of the options be
   * validated and no change be generated.
   */
  bool get validateOnly => _validateOnly;

  /**
   * True if the client is only requesting that the values of the options be
   * validated and no change be generated.
   */
  void set validateOnly(bool value) {
    assert(value != null);
    this._validateOnly = value;
  }

  /**
   * Data used to provide values provided by the user. The structure of the
   * data is dependent on the kind of refactoring being performed. The data
   * that is expected is documented in the section titled Refactorings, labeled
   * as "Options". This field can be omitted if the refactoring does not
   * require any options or if the values of those options are not known.
   */
  RefactoringOptions get options => _options;

  /**
   * Data used to provide values provided by the user. The structure of the
   * data is dependent on the kind of refactoring being performed. The data
   * that is expected is documented in the section titled Refactorings, labeled
   * as "Options". This field can be omitted if the refactoring does not
   * require any options or if the values of those options are not known.
   */
  void set options(RefactoringOptions value) {
    this._options = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RefactoringKind kind;
      if (json.containsKey("kind")) {
        kind = new RefactoringKind.fromJson(
            jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      bool validateOnly;
      if (json.containsKey("validateOnly")) {
        validateOnly = jsonDecoder.decodeBool(
            jsonPath + ".validateOnly", json["validateOnly"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "validateOnly");
      }
      RefactoringOptions options;
      if (json.containsKey("options")) {
        options = new RefactoringOptions.fromJson(
            jsonDecoder, jsonPath + ".options", json["options"], kind);
      }
      return new EditGetRefactoringParams(
          kind, file, offset, length, validateOnly,
          options: options);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring params", json);
    }
  }

  factory EditGetRefactoringParams.fromRequest(Request request) {
    var params = new EditGetRefactoringParams.fromJson(
        new RequestDecoder(request), "params", request.params);
    REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind;
    return params;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kind"] = kind.toJson();
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    result["validateOnly"] = validateOnly;
    if (options != null) {
      result["options"] = options.toJson();
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.getRefactoring", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, validateOnly.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getRefactoring result
 *
 * {
 *   "initialProblems": List<RefactoringProblem>
 *   "optionsProblems": List<RefactoringProblem>
 *   "finalProblems": List<RefactoringProblem>
 *   "feedback": optional RefactoringFeedback
 *   "change": optional SourceChange
 *   "potentialEdits": optional List<String>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetRefactoringResult implements ResponseResult {
  List<RefactoringProblem> _initialProblems;

  List<RefactoringProblem> _optionsProblems;

  List<RefactoringProblem> _finalProblems;

  RefactoringFeedback _feedback;

  SourceChange _change;

  List<String> _potentialEdits;

  /**
   * The initial status of the refactoring, i.e. problems related to the
   * context in which the refactoring is requested. The array will be empty if
   * there are no known problems.
   */
  List<RefactoringProblem> get initialProblems => _initialProblems;

  /**
   * The initial status of the refactoring, i.e. problems related to the
   * context in which the refactoring is requested. The array will be empty if
   * there are no known problems.
   */
  void set initialProblems(List<RefactoringProblem> value) {
    assert(value != null);
    this._initialProblems = value;
  }

  /**
   * The options validation status, i.e. problems in the given options, such as
   * light-weight validation of a new name, flags compatibility, etc. The array
   * will be empty if there are no known problems.
   */
  List<RefactoringProblem> get optionsProblems => _optionsProblems;

  /**
   * The options validation status, i.e. problems in the given options, such as
   * light-weight validation of a new name, flags compatibility, etc. The array
   * will be empty if there are no known problems.
   */
  void set optionsProblems(List<RefactoringProblem> value) {
    assert(value != null);
    this._optionsProblems = value;
  }

  /**
   * The final status of the refactoring, i.e. problems identified in the
   * result of a full, potentially expensive validation and / or change
   * creation. The array will be empty if there are no known problems.
   */
  List<RefactoringProblem> get finalProblems => _finalProblems;

  /**
   * The final status of the refactoring, i.e. problems identified in the
   * result of a full, potentially expensive validation and / or change
   * creation. The array will be empty if there are no known problems.
   */
  void set finalProblems(List<RefactoringProblem> value) {
    assert(value != null);
    this._finalProblems = value;
  }

  /**
   * Data used to provide feedback to the user. The structure of the data is
   * dependent on the kind of refactoring being created. The data that is
   * returned is documented in the section titled Refactorings, labeled as
   * "Feedback".
   */
  RefactoringFeedback get feedback => _feedback;

  /**
   * Data used to provide feedback to the user. The structure of the data is
   * dependent on the kind of refactoring being created. The data that is
   * returned is documented in the section titled Refactorings, labeled as
   * "Feedback".
   */
  void set feedback(RefactoringFeedback value) {
    this._feedback = value;
  }

  /**
   * The changes that are to be applied to affect the refactoring. This field
   * will be omitted if there are problems that prevent a set of changes from
   * being computed, such as having no options specified for a refactoring that
   * requires them, or if only validation was requested.
   */
  SourceChange get change => _change;

  /**
   * The changes that are to be applied to affect the refactoring. This field
   * will be omitted if there are problems that prevent a set of changes from
   * being computed, such as having no options specified for a refactoring that
   * requires them, or if only validation was requested.
   */
  void set change(SourceChange value) {
    this._change = value;
  }

  /**
   * The ids of source edits that are not known to be valid. An edit is not
   * known to be valid if there was insufficient type information for the
   * server to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field will be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  List<String> get potentialEdits => _potentialEdits;

  /**
   * The ids of source edits that are not known to be valid. An edit is not
   * known to be valid if there was insufficient type information for the
   * server to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field will be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  void set potentialEdits(List<String> value) {
    this._potentialEdits = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<RefactoringProblem> initialProblems;
      if (json.containsKey("initialProblems")) {
        initialProblems = jsonDecoder.decodeList(
            jsonPath + ".initialProblems",
            json["initialProblems"],
            (String jsonPath, Object json) =>
                new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "initialProblems");
      }
      List<RefactoringProblem> optionsProblems;
      if (json.containsKey("optionsProblems")) {
        optionsProblems = jsonDecoder.decodeList(
            jsonPath + ".optionsProblems",
            json["optionsProblems"],
            (String jsonPath, Object json) =>
                new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "optionsProblems");
      }
      List<RefactoringProblem> finalProblems;
      if (json.containsKey("finalProblems")) {
        finalProblems = jsonDecoder.decodeList(
            jsonPath + ".finalProblems",
            json["finalProblems"],
            (String jsonPath, Object json) =>
                new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "finalProblems");
      }
      RefactoringFeedback feedback;
      if (json.containsKey("feedback")) {
        feedback = new RefactoringFeedback.fromJson(
            jsonDecoder, jsonPath + ".feedback", json["feedback"], json);
      }
      SourceChange change;
      if (json.containsKey("change")) {
        change = new SourceChange.fromJson(
            jsonDecoder, jsonPath + ".change", json["change"]);
      }
      List<String> potentialEdits;
      if (json.containsKey("potentialEdits")) {
        potentialEdits = jsonDecoder.decodeList(jsonPath + ".potentialEdits",
            json["potentialEdits"], jsonDecoder.decodeString);
      }
      return new EditGetRefactoringResult(
          initialProblems, optionsProblems, finalProblems,
          feedback: feedback, change: change, potentialEdits: potentialEdits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring result", json);
    }
  }

  factory EditGetRefactoringResult.fromResponse(Response response) {
    return new EditGetRefactoringResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["initialProblems"] = initialProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    result["optionsProblems"] = optionsProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    result["finalProblems"] = finalProblems
        .map((RefactoringProblem value) => value.toJson())
        .toList();
    if (feedback != null) {
      result["feedback"] = feedback.toJson();
    }
    if (change != null) {
      result["change"] = change.toJson();
    }
    if (potentialEdits != null) {
      result["potentialEdits"] = potentialEdits;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, initialProblems.hashCode);
    hash = JenkinsSmiHash.combine(hash, optionsProblems.hashCode);
    hash = JenkinsSmiHash.combine(hash, finalProblems.hashCode);
    hash = JenkinsSmiHash.combine(hash, feedback.hashCode);
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    hash = JenkinsSmiHash.combine(hash, potentialEdits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getStatementCompletion params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetStatementCompletionParams implements RequestParams {
  String _file;

  int _offset;

  /**
   * The file containing the statement to be completed.
   */
  String get file => _file;

  /**
   * The file containing the statement to be completed.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset used to identify the statement to be completed.
   */
  int get offset => _offset;

  /**
   * The offset used to identify the statement to be completed.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  EditGetStatementCompletionParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory EditGetStatementCompletionParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      return new EditGetStatementCompletionParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.getStatementCompletion params", json);
    }
  }

  factory EditGetStatementCompletionParams.fromRequest(Request request) {
    return new EditGetStatementCompletionParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.getStatementCompletion", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetStatementCompletionParams) {
      return file == other.file && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getStatementCompletion result
 *
 * {
 *   "change": SourceChange
 *   "whitespaceOnly": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetStatementCompletionResult implements ResponseResult {
  SourceChange _change;

  bool _whitespaceOnly;

  /**
   * The change to be applied in order to complete the statement.
   */
  SourceChange get change => _change;

  /**
   * The change to be applied in order to complete the statement.
   */
  void set change(SourceChange value) {
    assert(value != null);
    this._change = value;
  }

  /**
   * Will be true if the change contains nothing but whitespace characters, or
   * is empty.
   */
  bool get whitespaceOnly => _whitespaceOnly;

  /**
   * Will be true if the change contains nothing but whitespace characters, or
   * is empty.
   */
  void set whitespaceOnly(bool value) {
    assert(value != null);
    this._whitespaceOnly = value;
  }

  EditGetStatementCompletionResult(SourceChange change, bool whitespaceOnly) {
    this.change = change;
    this.whitespaceOnly = whitespaceOnly;
  }

  factory EditGetStatementCompletionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      SourceChange change;
      if (json.containsKey("change")) {
        change = new SourceChange.fromJson(
            jsonDecoder, jsonPath + ".change", json["change"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "change");
      }
      bool whitespaceOnly;
      if (json.containsKey("whitespaceOnly")) {
        whitespaceOnly = jsonDecoder.decodeBool(
            jsonPath + ".whitespaceOnly", json["whitespaceOnly"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "whitespaceOnly");
      }
      return new EditGetStatementCompletionResult(change, whitespaceOnly);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.getStatementCompletion result", json);
    }
  }

  factory EditGetStatementCompletionResult.fromResponse(Response response) {
    return new EditGetStatementCompletionResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["change"] = change.toJson();
    result["whitespaceOnly"] = whitespaceOnly;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditGetStatementCompletionResult) {
      return change == other.change && whitespaceOnly == other.whitespaceOnly;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    hash = JenkinsSmiHash.combine(hash, whitespaceOnly.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.importElements params
 *
 * {
 *   "file": FilePath
 *   "elements": List<ImportedElements>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditImportElementsParams implements RequestParams {
  String _file;

  List<ImportedElements> _elements;

  /**
   * The file in which the specified elements are to be made accessible.
   */
  String get file => _file;

  /**
   * The file in which the specified elements are to be made accessible.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The elements to be made accessible in the specified file.
   */
  List<ImportedElements> get elements => _elements;

  /**
   * The elements to be made accessible in the specified file.
   */
  void set elements(List<ImportedElements> value) {
    assert(value != null);
    this._elements = value;
  }

  EditImportElementsParams(String file, List<ImportedElements> elements) {
    this.file = file;
    this.elements = elements;
  }

  factory EditImportElementsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      List<ImportedElements> elements;
      if (json.containsKey("elements")) {
        elements = jsonDecoder.decodeList(
            jsonPath + ".elements",
            json["elements"],
            (String jsonPath, Object json) =>
                new ImportedElements.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "elements");
      }
      return new EditImportElementsParams(file, elements);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.importElements params", json);
    }
  }

  factory EditImportElementsParams.fromRequest(Request request) {
    return new EditImportElementsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["elements"] =
        elements.map((ImportedElements value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.importElements", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditImportElementsParams) {
      return file == other.file &&
          listEqual(elements, other.elements,
              (ImportedElements a, ImportedElements b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.importElements result
 *
 * {
 *   "edits": List<SourceEdit>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditImportElementsResult implements ResponseResult {
  List<SourceEdit> _edits;

  /**
   * The edit(s) to be applied in order to make the specified elements
   * accessible.
   */
  List<SourceEdit> get edits => _edits;

  /**
   * The edit(s) to be applied in order to make the specified elements
   * accessible.
   */
  void set edits(List<SourceEdit> value) {
    assert(value != null);
    this._edits = value;
  }

  EditImportElementsResult(List<SourceEdit> edits) {
    this.edits = edits;
  }

  factory EditImportElementsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder.decodeList(
            jsonPath + ".edits",
            json["edits"],
            (String jsonPath, Object json) =>
                new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edits");
      }
      return new EditImportElementsResult(edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.importElements result", json);
    }
  }

  factory EditImportElementsResult.fromResponse(Response response) {
    return new EditImportElementsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edits"] = edits.map((SourceEdit value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditImportElementsResult) {
      return listEqual(
          edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.isPostfixCompletionApplicable params
 *
 * {
 *   "file": FilePath
 *   "key": String
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditIsPostfixCompletionApplicableParams implements RequestParams {
  String _file;

  String _key;

  int _offset;

  /**
   * The file containing the postfix template to be expanded.
   */
  String get file => _file;

  /**
   * The file containing the postfix template to be expanded.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The unique name that identifies the template in use.
   */
  String get key => _key;

  /**
   * The unique name that identifies the template in use.
   */
  void set key(String value) {
    assert(value != null);
    this._key = value;
  }

  /**
   * The offset used to identify the code to which the template will be
   * applied.
   */
  int get offset => _offset;

  /**
   * The offset used to identify the code to which the template will be
   * applied.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  EditIsPostfixCompletionApplicableParams(String file, String key, int offset) {
    this.file = file;
    this.key = key;
    this.offset = offset;
  }

  factory EditIsPostfixCompletionApplicableParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      String key;
      if (json.containsKey("key")) {
        key = jsonDecoder.decodeString(jsonPath + ".key", json["key"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "key");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      return new EditIsPostfixCompletionApplicableParams(file, key, offset);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.isPostfixCompletionApplicable params", json);
    }
  }

  factory EditIsPostfixCompletionApplicableParams.fromRequest(Request request) {
    return new EditIsPostfixCompletionApplicableParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["key"] = key;
    result["offset"] = offset;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.isPostfixCompletionApplicable", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditIsPostfixCompletionApplicableParams) {
      return file == other.file && key == other.key && offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, key.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.isPostfixCompletionApplicable result
 *
 * {
 *   "value": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditIsPostfixCompletionApplicableResult implements ResponseResult {
  bool _value;

  /**
   * True if the template can be expanded at the given location.
   */
  bool get value => _value;

  /**
   * True if the template can be expanded at the given location.
   */
  void set value(bool value) {
    assert(value != null);
    this._value = value;
  }

  EditIsPostfixCompletionApplicableResult(bool value) {
    this.value = value;
  }

  factory EditIsPostfixCompletionApplicableResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool value;
      if (json.containsKey("value")) {
        value = jsonDecoder.decodeBool(jsonPath + ".value", json["value"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "value");
      }
      return new EditIsPostfixCompletionApplicableResult(value);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.isPostfixCompletionApplicable result", json);
    }
  }

  factory EditIsPostfixCompletionApplicableResult.fromResponse(
      Response response) {
    return new EditIsPostfixCompletionApplicableResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["value"] = value;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditIsPostfixCompletionApplicableResult) {
      return value == other.value;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.listPostfixCompletionTemplates params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditListPostfixCompletionTemplatesParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.listPostfixCompletionTemplates", null);
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

/**
 * edit.listPostfixCompletionTemplates result
 *
 * {
 *   "templates": List<PostfixTemplateDescriptor>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditListPostfixCompletionTemplatesResult implements ResponseResult {
  List<PostfixTemplateDescriptor> _templates;

  /**
   * The list of available templates.
   */
  List<PostfixTemplateDescriptor> get templates => _templates;

  /**
   * The list of available templates.
   */
  void set templates(List<PostfixTemplateDescriptor> value) {
    assert(value != null);
    this._templates = value;
  }

  EditListPostfixCompletionTemplatesResult(
      List<PostfixTemplateDescriptor> templates) {
    this.templates = templates;
  }

  factory EditListPostfixCompletionTemplatesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<PostfixTemplateDescriptor> templates;
      if (json.containsKey("templates")) {
        templates = jsonDecoder.decodeList(
            jsonPath + ".templates",
            json["templates"],
            (String jsonPath, Object json) =>
                new PostfixTemplateDescriptor.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "templates");
      }
      return new EditListPostfixCompletionTemplatesResult(templates);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.listPostfixCompletionTemplates result", json);
    }
  }

  factory EditListPostfixCompletionTemplatesResult.fromResponse(
      Response response) {
    return new EditListPostfixCompletionTemplatesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["templates"] = templates
        .map((PostfixTemplateDescriptor value) => value.toJson())
        .toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, templates.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.organizeDirectives params
 *
 * {
 *   "file": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditOrganizeDirectivesParams implements RequestParams {
  String _file;

  /**
   * The Dart file to organize directives in.
   */
  String get file => _file;

  /**
   * The Dart file to organize directives in.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  EditOrganizeDirectivesParams(String file) {
    this.file = file;
  }

  factory EditOrganizeDirectivesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      return new EditOrganizeDirectivesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.organizeDirectives params", json);
    }
  }

  factory EditOrganizeDirectivesParams.fromRequest(Request request) {
    return new EditOrganizeDirectivesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.organizeDirectives", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditOrganizeDirectivesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.organizeDirectives result
 *
 * {
 *   "edit": SourceFileEdit
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditOrganizeDirectivesResult implements ResponseResult {
  SourceFileEdit _edit;

  /**
   * The file edit that is to be applied to the given file to effect the
   * organizing.
   */
  SourceFileEdit get edit => _edit;

  /**
   * The file edit that is to be applied to the given file to effect the
   * organizing.
   */
  void set edit(SourceFileEdit value) {
    assert(value != null);
    this._edit = value;
  }

  EditOrganizeDirectivesResult(SourceFileEdit edit) {
    this.edit = edit;
  }

  factory EditOrganizeDirectivesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey("edit")) {
        edit = new SourceFileEdit.fromJson(
            jsonDecoder, jsonPath + ".edit", json["edit"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edit");
      }
      return new EditOrganizeDirectivesResult(edit);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "edit.organizeDirectives result", json);
    }
  }

  factory EditOrganizeDirectivesResult.fromResponse(Response response) {
    return new EditOrganizeDirectivesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edit"] = edit.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditOrganizeDirectivesResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.sortMembers params
 *
 * {
 *   "file": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditSortMembersParams implements RequestParams {
  String _file;

  /**
   * The Dart file to sort.
   */
  String get file => _file;

  /**
   * The Dart file to sort.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  EditSortMembersParams(String file) {
    this.file = file;
  }

  factory EditSortMembersParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      return new EditSortMembersParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.sortMembers params", json);
    }
  }

  factory EditSortMembersParams.fromRequest(Request request) {
    return new EditSortMembersParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "edit.sortMembers", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditSortMembersParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.sortMembers result
 *
 * {
 *   "edit": SourceFileEdit
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditSortMembersResult implements ResponseResult {
  SourceFileEdit _edit;

  /**
   * The file edit that is to be applied to the given file to effect the
   * sorting.
   */
  SourceFileEdit get edit => _edit;

  /**
   * The file edit that is to be applied to the given file to effect the
   * sorting.
   */
  void set edit(SourceFileEdit value) {
    assert(value != null);
    this._edit = value;
  }

  EditSortMembersResult(SourceFileEdit edit) {
    this.edit = edit;
  }

  factory EditSortMembersResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey("edit")) {
        edit = new SourceFileEdit.fromJson(
            jsonDecoder, jsonPath + ".edit", json["edit"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edit");
      }
      return new EditSortMembersResult(edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.sortMembers result", json);
    }
  }

  factory EditSortMembersResult.fromResponse(Response response) {
    return new EditSortMembersResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edit"] = edit.toJson();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is EditSortMembersResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ExecutableFile
 *
 * {
 *   "file": FilePath
 *   "kind": ExecutableKind
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutableFile implements HasToJson {
  String _file;

  ExecutableKind _kind;

  /**
   * The path of the executable file.
   */
  String get file => _file;

  /**
   * The path of the executable file.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The kind of the executable file.
   */
  ExecutableKind get kind => _kind;

  /**
   * The kind of the executable file.
   */
  void set kind(ExecutableKind value) {
    assert(value != null);
    this._kind = value;
  }

  ExecutableFile(String file, ExecutableKind kind) {
    this.file = file;
    this.kind = kind;
  }

  factory ExecutableFile.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      ExecutableKind kind;
      if (json.containsKey("kind")) {
        kind = new ExecutableKind.fromJson(
            jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      return new ExecutableFile(file, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ExecutableFile", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["kind"] = kind.toJson();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutableFile) {
      return file == other.file && kind == other.kind;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ExecutableKind
 *
 * enum {
 *   CLIENT
 *   EITHER
 *   NOT_EXECUTABLE
 *   SERVER
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutableKind implements Enum {
  static const ExecutableKind CLIENT = const ExecutableKind._("CLIENT");

  static const ExecutableKind EITHER = const ExecutableKind._("EITHER");

  static const ExecutableKind NOT_EXECUTABLE =
      const ExecutableKind._("NOT_EXECUTABLE");

  static const ExecutableKind SERVER = const ExecutableKind._("SERVER");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ExecutableKind> VALUES = const <ExecutableKind>[
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
      case "CLIENT":
        return CLIENT;
      case "EITHER":
        return EITHER;
      case "NOT_EXECUTABLE":
        return NOT_EXECUTABLE;
      case "SERVER":
        return SERVER;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ExecutableKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ExecutableKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ExecutableKind", json);
  }

  @override
  String toString() => "ExecutableKind.$name";

  String toJson() => name;
}

/**
 * execution.createContext params
 *
 * {
 *   "contextRoot": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionCreateContextParams implements RequestParams {
  String _contextRoot;

  /**
   * The path of the Dart or HTML file that will be launched, or the path of
   * the directory containing the file.
   */
  String get contextRoot => _contextRoot;

  /**
   * The path of the Dart or HTML file that will be launched, or the path of
   * the directory containing the file.
   */
  void set contextRoot(String value) {
    assert(value != null);
    this._contextRoot = value;
  }

  ExecutionCreateContextParams(String contextRoot) {
    this.contextRoot = contextRoot;
  }

  factory ExecutionCreateContextParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String contextRoot;
      if (json.containsKey("contextRoot")) {
        contextRoot = jsonDecoder.decodeString(
            jsonPath + ".contextRoot", json["contextRoot"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "contextRoot");
      }
      return new ExecutionCreateContextParams(contextRoot);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "execution.createContext params", json);
    }
  }

  factory ExecutionCreateContextParams.fromRequest(Request request) {
    return new ExecutionCreateContextParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["contextRoot"] = contextRoot;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "execution.createContext", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionCreateContextParams) {
      return contextRoot == other.contextRoot;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, contextRoot.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.createContext result
 *
 * {
 *   "id": ExecutionContextId
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionCreateContextResult implements ResponseResult {
  String _id;

  /**
   * The identifier used to refer to the execution context that was created.
   */
  String get id => _id;

  /**
   * The identifier used to refer to the execution context that was created.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  ExecutionCreateContextResult(String id) {
    this.id = id;
  }

  factory ExecutionCreateContextResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      return new ExecutionCreateContextResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "execution.createContext result", json);
    }
  }

  factory ExecutionCreateContextResult.fromResponse(Response response) {
    return new ExecutionCreateContextResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionCreateContextResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.deleteContext params
 *
 * {
 *   "id": ExecutionContextId
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionDeleteContextParams implements RequestParams {
  String _id;

  /**
   * The identifier of the execution context that is to be deleted.
   */
  String get id => _id;

  /**
   * The identifier of the execution context that is to be deleted.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  ExecutionDeleteContextParams(String id) {
    this.id = id;
  }

  factory ExecutionDeleteContextParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      return new ExecutionDeleteContextParams(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "execution.deleteContext params", json);
    }
  }

  factory ExecutionDeleteContextParams.fromRequest(Request request) {
    return new ExecutionDeleteContextParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "execution.deleteContext", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionDeleteContextParams) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.deleteContext result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionDeleteContextResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * execution.launchData params
 *
 * {
 *   "file": FilePath
 *   "kind": optional ExecutableKind
 *   "referencedFiles": optional List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionLaunchDataParams implements HasToJson {
  String _file;

  ExecutableKind _kind;

  List<String> _referencedFiles;

  /**
   * The file for which launch data is being provided. This will either be a
   * Dart library or an HTML file.
   */
  String get file => _file;

  /**
   * The file for which launch data is being provided. This will either be a
   * Dart library or an HTML file.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The kind of the executable file. This field is omitted if the file is not
   * a Dart file.
   */
  ExecutableKind get kind => _kind;

  /**
   * The kind of the executable file. This field is omitted if the file is not
   * a Dart file.
   */
  void set kind(ExecutableKind value) {
    this._kind = value;
  }

  /**
   * A list of the Dart files that are referenced by the file. This field is
   * omitted if the file is not an HTML file.
   */
  List<String> get referencedFiles => _referencedFiles;

  /**
   * A list of the Dart files that are referenced by the file. This field is
   * omitted if the file is not an HTML file.
   */
  void set referencedFiles(List<String> value) {
    this._referencedFiles = value;
  }

  ExecutionLaunchDataParams(String file,
      {ExecutableKind kind, List<String> referencedFiles}) {
    this.file = file;
    this.kind = kind;
    this.referencedFiles = referencedFiles;
  }

  factory ExecutionLaunchDataParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      ExecutableKind kind;
      if (json.containsKey("kind")) {
        kind = new ExecutableKind.fromJson(
            jsonDecoder, jsonPath + ".kind", json["kind"]);
      }
      List<String> referencedFiles;
      if (json.containsKey("referencedFiles")) {
        referencedFiles = jsonDecoder.decodeList(jsonPath + ".referencedFiles",
            json["referencedFiles"], jsonDecoder.decodeString);
      }
      return new ExecutionLaunchDataParams(file,
          kind: kind, referencedFiles: referencedFiles);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.launchData params", json);
    }
  }

  factory ExecutionLaunchDataParams.fromNotification(
      Notification notification) {
    return new ExecutionLaunchDataParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    if (kind != null) {
      result["kind"] = kind.toJson();
    }
    if (referencedFiles != null) {
      result["referencedFiles"] = referencedFiles;
    }
    return result;
  }

  Notification toNotification() {
    return new Notification("execution.launchData", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, referencedFiles.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.mapUri params
 *
 * {
 *   "id": ExecutionContextId
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionMapUriParams implements RequestParams {
  String _id;

  String _file;

  String _uri;

  /**
   * The identifier of the execution context in which the URI is to be mapped.
   */
  String get id => _id;

  /**
   * The identifier of the execution context in which the URI is to be mapped.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  /**
   * The path of the file to be mapped into a URI.
   */
  String get file => _file;

  /**
   * The path of the file to be mapped into a URI.
   */
  void set file(String value) {
    this._file = value;
  }

  /**
   * The URI to be mapped into a file path.
   */
  String get uri => _uri;

  /**
   * The URI to be mapped into a file path.
   */
  void set uri(String value) {
    this._uri = value;
  }

  ExecutionMapUriParams(String id, {String file, String uri}) {
    this.id = id;
    this.file = file;
    this.uri = uri;
  }

  factory ExecutionMapUriParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      }
      String uri;
      if (json.containsKey("uri")) {
        uri = jsonDecoder.decodeString(jsonPath + ".uri", json["uri"]);
      }
      return new ExecutionMapUriParams(id, file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.mapUri params", json);
    }
  }

  factory ExecutionMapUriParams.fromRequest(Request request) {
    return new ExecutionMapUriParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    if (file != null) {
      result["file"] = file;
    }
    if (uri != null) {
      result["uri"] = uri;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "execution.mapUri", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionMapUriParams) {
      return id == other.id && file == other.file && uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.mapUri result
 *
 * {
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionMapUriResult implements ResponseResult {
  String _file;

  String _uri;

  /**
   * The file to which the URI was mapped. This field is omitted if the uri
   * field was not given in the request.
   */
  String get file => _file;

  /**
   * The file to which the URI was mapped. This field is omitted if the uri
   * field was not given in the request.
   */
  void set file(String value) {
    this._file = value;
  }

  /**
   * The URI to which the file path was mapped. This field is omitted if the
   * file field was not given in the request.
   */
  String get uri => _uri;

  /**
   * The URI to which the file path was mapped. This field is omitted if the
   * file field was not given in the request.
   */
  void set uri(String value) {
    this._uri = value;
  }

  ExecutionMapUriResult({String file, String uri}) {
    this.file = file;
    this.uri = uri;
  }

  factory ExecutionMapUriResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      }
      String uri;
      if (json.containsKey("uri")) {
        uri = jsonDecoder.decodeString(jsonPath + ".uri", json["uri"]);
      }
      return new ExecutionMapUriResult(file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.mapUri result", json);
    }
  }

  factory ExecutionMapUriResult.fromResponse(Response response) {
    return new ExecutionMapUriResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (file != null) {
      result["file"] = file;
    }
    if (uri != null) {
      result["uri"] = uri;
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExecutionMapUriResult) {
      return file == other.file && uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ExecutionService
 *
 * enum {
 *   LAUNCH_DATA
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionService implements Enum {
  static const ExecutionService LAUNCH_DATA =
      const ExecutionService._("LAUNCH_DATA");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ExecutionService> VALUES = const <ExecutionService>[
    LAUNCH_DATA
  ];

  @override
  final String name;

  const ExecutionService._(this.name);

  factory ExecutionService(String name) {
    switch (name) {
      case "LAUNCH_DATA":
        return LAUNCH_DATA;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ExecutionService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ExecutionService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ExecutionService", json);
  }

  @override
  String toString() => "ExecutionService.$name";

  String toJson() => name;
}

/**
 * execution.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ExecutionService>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionSetSubscriptionsParams implements RequestParams {
  List<ExecutionService> _subscriptions;

  /**
   * A list of the services being subscribed to.
   */
  List<ExecutionService> get subscriptions => _subscriptions;

  /**
   * A list of the services being subscribed to.
   */
  void set subscriptions(List<ExecutionService> value) {
    assert(value != null);
    this._subscriptions = value;
  }

  ExecutionSetSubscriptionsParams(List<ExecutionService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory ExecutionSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ExecutionService> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + ".subscriptions",
            json["subscriptions"],
            (String jsonPath, Object json) =>
                new ExecutionService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "subscriptions");
      }
      return new ExecutionSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "execution.setSubscriptions params", json);
    }
  }

  factory ExecutionSetSubscriptionsParams.fromRequest(Request request) {
    return new ExecutionSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] =
        subscriptions.map((ExecutionService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "execution.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.setSubscriptions result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExecutionSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * extractLocalVariable feedback
 *
 * {
 *   "coveringExpressionOffsets": optional List<int>
 *   "coveringExpressionLengths": optional List<int>
 *   "names": List<String>
 *   "offsets": List<int>
 *   "lengths": List<int>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExtractLocalVariableFeedback extends RefactoringFeedback {
  List<int> _coveringExpressionOffsets;

  List<int> _coveringExpressionLengths;

  List<String> _names;

  List<int> _offsets;

  List<int> _lengths;

  /**
   * The offsets of the expressions that cover the specified selection, from
   * the down most to the up most.
   */
  List<int> get coveringExpressionOffsets => _coveringExpressionOffsets;

  /**
   * The offsets of the expressions that cover the specified selection, from
   * the down most to the up most.
   */
  void set coveringExpressionOffsets(List<int> value) {
    this._coveringExpressionOffsets = value;
  }

  /**
   * The lengths of the expressions that cover the specified selection, from
   * the down most to the up most.
   */
  List<int> get coveringExpressionLengths => _coveringExpressionLengths;

  /**
   * The lengths of the expressions that cover the specified selection, from
   * the down most to the up most.
   */
  void set coveringExpressionLengths(List<int> value) {
    this._coveringExpressionLengths = value;
  }

  /**
   * The proposed names for the local variable.
   */
  List<String> get names => _names;

  /**
   * The proposed names for the local variable.
   */
  void set names(List<String> value) {
    assert(value != null);
    this._names = value;
  }

  /**
   * The offsets of the expressions that would be replaced by a reference to
   * the variable.
   */
  List<int> get offsets => _offsets;

  /**
   * The offsets of the expressions that would be replaced by a reference to
   * the variable.
   */
  void set offsets(List<int> value) {
    assert(value != null);
    this._offsets = value;
  }

  /**
   * The lengths of the expressions that would be replaced by a reference to
   * the variable. The lengths correspond to the offsets. In other words, for a
   * given expression, if the offset of that expression is offsets[i], then the
   * length of that expression is lengths[i].
   */
  List<int> get lengths => _lengths;

  /**
   * The lengths of the expressions that would be replaced by a reference to
   * the variable. The lengths correspond to the offsets. In other words, for a
   * given expression, if the offset of that expression is offsets[i], then the
   * length of that expression is lengths[i].
   */
  void set lengths(List<int> value) {
    assert(value != null);
    this._lengths = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<int> coveringExpressionOffsets;
      if (json.containsKey("coveringExpressionOffsets")) {
        coveringExpressionOffsets = jsonDecoder.decodeList(
            jsonPath + ".coveringExpressionOffsets",
            json["coveringExpressionOffsets"],
            jsonDecoder.decodeInt);
      }
      List<int> coveringExpressionLengths;
      if (json.containsKey("coveringExpressionLengths")) {
        coveringExpressionLengths = jsonDecoder.decodeList(
            jsonPath + ".coveringExpressionLengths",
            json["coveringExpressionLengths"],
            jsonDecoder.decodeInt);
      }
      List<String> names;
      if (json.containsKey("names")) {
        names = jsonDecoder.decodeList(
            jsonPath + ".names", json["names"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "names");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder.decodeList(
            jsonPath + ".offsets", json["offsets"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offsets");
      }
      List<int> lengths;
      if (json.containsKey("lengths")) {
        lengths = jsonDecoder.decodeList(
            jsonPath + ".lengths", json["lengths"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "lengths");
      }
      return new ExtractLocalVariableFeedback(names, offsets, lengths,
          coveringExpressionOffsets: coveringExpressionOffsets,
          coveringExpressionLengths: coveringExpressionLengths);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "extractLocalVariable feedback", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (coveringExpressionOffsets != null) {
      result["coveringExpressionOffsets"] = coveringExpressionOffsets;
    }
    if (coveringExpressionLengths != null) {
      result["coveringExpressionLengths"] = coveringExpressionLengths;
    }
    result["names"] = names;
    result["offsets"] = offsets;
    result["lengths"] = lengths;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, coveringExpressionOffsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, coveringExpressionLengths.hashCode);
    hash = JenkinsSmiHash.combine(hash, names.hashCode);
    hash = JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, lengths.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * extractLocalVariable options
 *
 * {
 *   "name": String
 *   "extractAll": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExtractLocalVariableOptions extends RefactoringOptions {
  String _name;

  bool _extractAll;

  /**
   * The name that the local variable should be given.
   */
  String get name => _name;

  /**
   * The name that the local variable should be given.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * True if all occurrences of the expression within the scope in which the
   * variable will be defined should be replaced by a reference to the local
   * variable. The expression used to initiate the refactoring will always be
   * replaced.
   */
  bool get extractAll => _extractAll;

  /**
   * True if all occurrences of the expression within the scope in which the
   * variable will be defined should be replaced by a reference to the local
   * variable. The expression used to initiate the refactoring will always be
   * replaced.
   */
  void set extractAll(bool value) {
    assert(value != null);
    this._extractAll = value;
  }

  ExtractLocalVariableOptions(String name, bool extractAll) {
    this.name = name;
    this.extractAll = extractAll;
  }

  factory ExtractLocalVariableOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      bool extractAll;
      if (json.containsKey("extractAll")) {
        extractAll = jsonDecoder.decodeBool(
            jsonPath + ".extractAll", json["extractAll"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "extractAll");
      }
      return new ExtractLocalVariableOptions(name, extractAll);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "extractLocalVariable options", json);
    }
  }

  factory ExtractLocalVariableOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return new ExtractLocalVariableOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    result["extractAll"] = extractAll;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ExtractLocalVariableOptions) {
      return name == other.name && extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, extractAll.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * extractMethod feedback
 *
 * {
 *   "offset": int
 *   "length": int
 *   "returnType": String
 *   "names": List<String>
 *   "canCreateGetter": bool
 *   "parameters": List<RefactoringMethodParameter>
 *   "offsets": List<int>
 *   "lengths": List<int>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExtractMethodFeedback extends RefactoringFeedback {
  int _offset;

  int _length;

  String _returnType;

  List<String> _names;

  bool _canCreateGetter;

  List<RefactoringMethodParameter> _parameters;

  List<int> _offsets;

  List<int> _lengths;

  /**
   * The offset to the beginning of the expression or statements that will be
   * extracted.
   */
  int get offset => _offset;

  /**
   * The offset to the beginning of the expression or statements that will be
   * extracted.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the expression or statements that will be extracted.
   */
  int get length => _length;

  /**
   * The length of the expression or statements that will be extracted.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The proposed return type for the method. If the returned element does not
   * have a declared return type, this field will contain an empty string.
   */
  String get returnType => _returnType;

  /**
   * The proposed return type for the method. If the returned element does not
   * have a declared return type, this field will contain an empty string.
   */
  void set returnType(String value) {
    assert(value != null);
    this._returnType = value;
  }

  /**
   * The proposed names for the method.
   */
  List<String> get names => _names;

  /**
   * The proposed names for the method.
   */
  void set names(List<String> value) {
    assert(value != null);
    this._names = value;
  }

  /**
   * True if a getter could be created rather than a method.
   */
  bool get canCreateGetter => _canCreateGetter;

  /**
   * True if a getter could be created rather than a method.
   */
  void set canCreateGetter(bool value) {
    assert(value != null);
    this._canCreateGetter = value;
  }

  /**
   * The proposed parameters for the method.
   */
  List<RefactoringMethodParameter> get parameters => _parameters;

  /**
   * The proposed parameters for the method.
   */
  void set parameters(List<RefactoringMethodParameter> value) {
    assert(value != null);
    this._parameters = value;
  }

  /**
   * The offsets of the expressions or statements that would be replaced by an
   * invocation of the method.
   */
  List<int> get offsets => _offsets;

  /**
   * The offsets of the expressions or statements that would be replaced by an
   * invocation of the method.
   */
  void set offsets(List<int> value) {
    assert(value != null);
    this._offsets = value;
  }

  /**
   * The lengths of the expressions or statements that would be replaced by an
   * invocation of the method. The lengths correspond to the offsets. In other
   * words, for a given expression (or block of statements), if the offset of
   * that expression is offsets[i], then the length of that expression is
   * lengths[i].
   */
  List<int> get lengths => _lengths;

  /**
   * The lengths of the expressions or statements that would be replaced by an
   * invocation of the method. The lengths correspond to the offsets. In other
   * words, for a given expression (or block of statements), if the offset of
   * that expression is offsets[i], then the length of that expression is
   * lengths[i].
   */
  void set lengths(List<int> value) {
    assert(value != null);
    this._lengths = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder.decodeString(
            jsonPath + ".returnType", json["returnType"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "returnType");
      }
      List<String> names;
      if (json.containsKey("names")) {
        names = jsonDecoder.decodeList(
            jsonPath + ".names", json["names"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "names");
      }
      bool canCreateGetter;
      if (json.containsKey("canCreateGetter")) {
        canCreateGetter = jsonDecoder.decodeBool(
            jsonPath + ".canCreateGetter", json["canCreateGetter"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "canCreateGetter");
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder.decodeList(
            jsonPath + ".parameters",
            json["parameters"],
            (String jsonPath, Object json) =>
                new RefactoringMethodParameter.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "parameters");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder.decodeList(
            jsonPath + ".offsets", json["offsets"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offsets");
      }
      List<int> lengths;
      if (json.containsKey("lengths")) {
        lengths = jsonDecoder.decodeList(
            jsonPath + ".lengths", json["lengths"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "lengths");
      }
      return new ExtractMethodFeedback(offset, length, returnType, names,
          canCreateGetter, parameters, offsets, lengths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractMethod feedback", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    result["returnType"] = returnType;
    result["names"] = names;
    result["canCreateGetter"] = canCreateGetter;
    result["parameters"] = parameters
        .map((RefactoringMethodParameter value) => value.toJson())
        .toList();
    result["offsets"] = offsets;
    result["lengths"] = lengths;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
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

/**
 * extractMethod options
 *
 * {
 *   "returnType": String
 *   "createGetter": bool
 *   "name": String
 *   "parameters": List<RefactoringMethodParameter>
 *   "extractAll": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ExtractMethodOptions extends RefactoringOptions {
  String _returnType;

  bool _createGetter;

  String _name;

  List<RefactoringMethodParameter> _parameters;

  bool _extractAll;

  /**
   * The return type that should be defined for the method.
   */
  String get returnType => _returnType;

  /**
   * The return type that should be defined for the method.
   */
  void set returnType(String value) {
    assert(value != null);
    this._returnType = value;
  }

  /**
   * True if a getter should be created rather than a method. It is an error if
   * this field is true and the list of parameters is non-empty.
   */
  bool get createGetter => _createGetter;

  /**
   * True if a getter should be created rather than a method. It is an error if
   * this field is true and the list of parameters is non-empty.
   */
  void set createGetter(bool value) {
    assert(value != null);
    this._createGetter = value;
  }

  /**
   * The name that the method should be given.
   */
  String get name => _name;

  /**
   * The name that the method should be given.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * The parameters that should be defined for the method.
   *
   * It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
   * parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
   * NAMED parameter.
   *
   * - To change the order and/or update proposed parameters, add parameters
   *   with the same identifiers as proposed.
   * - To add new parameters, omit their identifier.
   * - To remove some parameters, omit them in this list.
   */
  List<RefactoringMethodParameter> get parameters => _parameters;

  /**
   * The parameters that should be defined for the method.
   *
   * It is an error if a REQUIRED or NAMED parameter follows a POSITIONAL
   * parameter. It is an error if a REQUIRED or POSITIONAL parameter follows a
   * NAMED parameter.
   *
   * - To change the order and/or update proposed parameters, add parameters
   *   with the same identifiers as proposed.
   * - To add new parameters, omit their identifier.
   * - To remove some parameters, omit them in this list.
   */
  void set parameters(List<RefactoringMethodParameter> value) {
    assert(value != null);
    this._parameters = value;
  }

  /**
   * True if all occurrences of the expression or statements should be replaced
   * by an invocation of the method. The expression or statements used to
   * initiate the refactoring will always be replaced.
   */
  bool get extractAll => _extractAll;

  /**
   * True if all occurrences of the expression or statements should be replaced
   * by an invocation of the method. The expression or statements used to
   * initiate the refactoring will always be replaced.
   */
  void set extractAll(bool value) {
    assert(value != null);
    this._extractAll = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder.decodeString(
            jsonPath + ".returnType", json["returnType"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "returnType");
      }
      bool createGetter;
      if (json.containsKey("createGetter")) {
        createGetter = jsonDecoder.decodeBool(
            jsonPath + ".createGetter", json["createGetter"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "createGetter");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder.decodeList(
            jsonPath + ".parameters",
            json["parameters"],
            (String jsonPath, Object json) =>
                new RefactoringMethodParameter.fromJson(
                    jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "parameters");
      }
      bool extractAll;
      if (json.containsKey("extractAll")) {
        extractAll = jsonDecoder.decodeBool(
            jsonPath + ".extractAll", json["extractAll"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "extractAll");
      }
      return new ExtractMethodOptions(
          returnType, createGetter, name, parameters, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractMethod options", json);
    }
  }

  factory ExtractMethodOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return new ExtractMethodOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["returnType"] = returnType;
    result["createGetter"] = createGetter;
    result["name"] = name;
    result["parameters"] = parameters
        .map((RefactoringMethodParameter value) => value.toJson())
        .toList();
    result["extractAll"] = extractAll;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, createGetter.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, extractAll.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * FileKind
 *
 * enum {
 *   LIBRARY
 *   PART
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FileKind implements Enum {
  static const FileKind LIBRARY = const FileKind._("LIBRARY");

  static const FileKind PART = const FileKind._("PART");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<FileKind> VALUES = const <FileKind>[LIBRARY, PART];

  @override
  final String name;

  const FileKind._(this.name);

  factory FileKind(String name) {
    switch (name) {
      case "LIBRARY":
        return LIBRARY;
      case "PART":
        return PART;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory FileKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new FileKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "FileKind", json);
  }

  @override
  String toString() => "FileKind.$name";

  String toJson() => name;
}

/**
 * GeneralAnalysisService
 *
 * enum {
 *   ANALYZED_FILES
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class GeneralAnalysisService implements Enum {
  static const GeneralAnalysisService ANALYZED_FILES =
      const GeneralAnalysisService._("ANALYZED_FILES");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<GeneralAnalysisService> VALUES =
      const <GeneralAnalysisService>[ANALYZED_FILES];

  @override
  final String name;

  const GeneralAnalysisService._(this.name);

  factory GeneralAnalysisService(String name) {
    switch (name) {
      case "ANALYZED_FILES":
        return ANALYZED_FILES;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory GeneralAnalysisService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new GeneralAnalysisService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "GeneralAnalysisService", json);
  }

  @override
  String toString() => "GeneralAnalysisService.$name";

  String toJson() => name;
}

/**
 * HoverInformation
 *
 * {
 *   "offset": int
 *   "length": int
 *   "containingLibraryPath": optional String
 *   "containingLibraryName": optional String
 *   "containingClassDescription": optional String
 *   "dartdoc": optional String
 *   "elementDescription": optional String
 *   "elementKind": optional String
 *   "isDeprecated": optional bool
 *   "parameter": optional String
 *   "propagatedType": optional String
 *   "staticType": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

  /**
   * The offset of the range of characters that encompasses the cursor position
   * and has the same hover information as the cursor position.
   */
  int get offset => _offset;

  /**
   * The offset of the range of characters that encompasses the cursor position
   * and has the same hover information as the cursor position.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the range of characters that encompasses the cursor position
   * and has the same hover information as the cursor position.
   */
  int get length => _length;

  /**
   * The length of the range of characters that encompasses the cursor position
   * and has the same hover information as the cursor position.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The path to the defining compilation unit of the library in which the
   * referenced element is declared. This data is omitted if there is no
   * referenced element, or if the element is declared inside an HTML file.
   */
  String get containingLibraryPath => _containingLibraryPath;

  /**
   * The path to the defining compilation unit of the library in which the
   * referenced element is declared. This data is omitted if there is no
   * referenced element, or if the element is declared inside an HTML file.
   */
  void set containingLibraryPath(String value) {
    this._containingLibraryPath = value;
  }

  /**
   * The name of the library in which the referenced element is declared. This
   * data is omitted if there is no referenced element, or if the element is
   * declared inside an HTML file.
   */
  String get containingLibraryName => _containingLibraryName;

  /**
   * The name of the library in which the referenced element is declared. This
   * data is omitted if there is no referenced element, or if the element is
   * declared inside an HTML file.
   */
  void set containingLibraryName(String value) {
    this._containingLibraryName = value;
  }

  /**
   * A human-readable description of the class declaring the element being
   * referenced. This data is omitted if there is no referenced element, or if
   * the element is not a class member.
   */
  String get containingClassDescription => _containingClassDescription;

  /**
   * A human-readable description of the class declaring the element being
   * referenced. This data is omitted if there is no referenced element, or if
   * the element is not a class member.
   */
  void set containingClassDescription(String value) {
    this._containingClassDescription = value;
  }

  /**
   * The dartdoc associated with the referenced element. Other than the removal
   * of the comment delimiters, including leading asterisks in the case of a
   * block comment, the dartdoc is unprocessed markdown. This data is omitted
   * if there is no referenced element, or if the element has no dartdoc.
   */
  String get dartdoc => _dartdoc;

  /**
   * The dartdoc associated with the referenced element. Other than the removal
   * of the comment delimiters, including leading asterisks in the case of a
   * block comment, the dartdoc is unprocessed markdown. This data is omitted
   * if there is no referenced element, or if the element has no dartdoc.
   */
  void set dartdoc(String value) {
    this._dartdoc = value;
  }

  /**
   * A human-readable description of the element being referenced. This data is
   * omitted if there is no referenced element.
   */
  String get elementDescription => _elementDescription;

  /**
   * A human-readable description of the element being referenced. This data is
   * omitted if there is no referenced element.
   */
  void set elementDescription(String value) {
    this._elementDescription = value;
  }

  /**
   * A human-readable description of the kind of element being referenced (such
   * as "class" or "function type alias"). This data is omitted if there is no
   * referenced element.
   */
  String get elementKind => _elementKind;

  /**
   * A human-readable description of the kind of element being referenced (such
   * as "class" or "function type alias"). This data is omitted if there is no
   * referenced element.
   */
  void set elementKind(String value) {
    this._elementKind = value;
  }

  /**
   * True if the referenced element is deprecated.
   */
  bool get isDeprecated => _isDeprecated;

  /**
   * True if the referenced element is deprecated.
   */
  void set isDeprecated(bool value) {
    this._isDeprecated = value;
  }

  /**
   * A human-readable description of the parameter corresponding to the
   * expression being hovered over. This data is omitted if the location is not
   * in an argument to a function.
   */
  String get parameter => _parameter;

  /**
   * A human-readable description of the parameter corresponding to the
   * expression being hovered over. This data is omitted if the location is not
   * in an argument to a function.
   */
  void set parameter(String value) {
    this._parameter = value;
  }

  /**
   * The name of the propagated type of the expression. This data is omitted if
   * the location does not correspond to an expression or if there is no
   * propagated type information.
   */
  String get propagatedType => _propagatedType;

  /**
   * The name of the propagated type of the expression. This data is omitted if
   * the location does not correspond to an expression or if there is no
   * propagated type information.
   */
  void set propagatedType(String value) {
    this._propagatedType = value;
  }

  /**
   * The name of the static type of the expression. This data is omitted if the
   * location does not correspond to an expression.
   */
  String get staticType => _staticType;

  /**
   * The name of the static type of the expression. This data is omitted if the
   * location does not correspond to an expression.
   */
  void set staticType(String value) {
    this._staticType = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      String containingLibraryPath;
      if (json.containsKey("containingLibraryPath")) {
        containingLibraryPath = jsonDecoder.decodeString(
            jsonPath + ".containingLibraryPath", json["containingLibraryPath"]);
      }
      String containingLibraryName;
      if (json.containsKey("containingLibraryName")) {
        containingLibraryName = jsonDecoder.decodeString(
            jsonPath + ".containingLibraryName", json["containingLibraryName"]);
      }
      String containingClassDescription;
      if (json.containsKey("containingClassDescription")) {
        containingClassDescription = jsonDecoder.decodeString(
            jsonPath + ".containingClassDescription",
            json["containingClassDescription"]);
      }
      String dartdoc;
      if (json.containsKey("dartdoc")) {
        dartdoc =
            jsonDecoder.decodeString(jsonPath + ".dartdoc", json["dartdoc"]);
      }
      String elementDescription;
      if (json.containsKey("elementDescription")) {
        elementDescription = jsonDecoder.decodeString(
            jsonPath + ".elementDescription", json["elementDescription"]);
      }
      String elementKind;
      if (json.containsKey("elementKind")) {
        elementKind = jsonDecoder.decodeString(
            jsonPath + ".elementKind", json["elementKind"]);
      }
      bool isDeprecated;
      if (json.containsKey("isDeprecated")) {
        isDeprecated = jsonDecoder.decodeBool(
            jsonPath + ".isDeprecated", json["isDeprecated"]);
      }
      String parameter;
      if (json.containsKey("parameter")) {
        parameter = jsonDecoder.decodeString(
            jsonPath + ".parameter", json["parameter"]);
      }
      String propagatedType;
      if (json.containsKey("propagatedType")) {
        propagatedType = jsonDecoder.decodeString(
            jsonPath + ".propagatedType", json["propagatedType"]);
      }
      String staticType;
      if (json.containsKey("staticType")) {
        staticType = jsonDecoder.decodeString(
            jsonPath + ".staticType", json["staticType"]);
      }
      return new HoverInformation(offset, length,
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
      throw jsonDecoder.mismatch(jsonPath, "HoverInformation", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    if (containingLibraryPath != null) {
      result["containingLibraryPath"] = containingLibraryPath;
    }
    if (containingLibraryName != null) {
      result["containingLibraryName"] = containingLibraryName;
    }
    if (containingClassDescription != null) {
      result["containingClassDescription"] = containingClassDescription;
    }
    if (dartdoc != null) {
      result["dartdoc"] = dartdoc;
    }
    if (elementDescription != null) {
      result["elementDescription"] = elementDescription;
    }
    if (elementKind != null) {
      result["elementKind"] = elementKind;
    }
    if (isDeprecated != null) {
      result["isDeprecated"] = isDeprecated;
    }
    if (parameter != null) {
      result["parameter"] = parameter;
    }
    if (propagatedType != null) {
      result["propagatedType"] = propagatedType;
    }
    if (staticType != null) {
      result["staticType"] = staticType;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
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

/**
 * ImplementedClass
 *
 * {
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ImplementedClass implements HasToJson {
  int _offset;

  int _length;

  /**
   * The offset of the name of the implemented class.
   */
  int get offset => _offset;

  /**
   * The offset of the name of the implemented class.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the name of the implemented class.
   */
  int get length => _length;

  /**
   * The length of the name of the implemented class.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  ImplementedClass(int offset, int length) {
    this.offset = offset;
    this.length = length;
  }

  factory ImplementedClass.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new ImplementedClass(offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ImplementedClass", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImplementedClass) {
      return offset == other.offset && length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ImplementedMember
 *
 * {
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ImplementedMember implements HasToJson {
  int _offset;

  int _length;

  /**
   * The offset of the name of the implemented member.
   */
  int get offset => _offset;

  /**
   * The offset of the name of the implemented member.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the name of the implemented member.
   */
  int get length => _length;

  /**
   * The length of the name of the implemented member.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  ImplementedMember(int offset, int length) {
    this.offset = offset;
    this.length = length;
  }

  factory ImplementedMember.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new ImplementedMember(offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ImplementedMember", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ImplementedMember) {
      return offset == other.offset && length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ImportedElements
 *
 * {
 *   "path": FilePath
 *   "prefix": String
 *   "elements": List<String>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ImportedElements implements HasToJson {
  String _path;

  String _prefix;

  List<String> _elements;

  /**
   * The absolute and normalized path of the file containing the library.
   */
  String get path => _path;

  /**
   * The absolute and normalized path of the file containing the library.
   */
  void set path(String value) {
    assert(value != null);
    this._path = value;
  }

  /**
   * The prefix that was used when importing the library into the original
   * source.
   */
  String get prefix => _prefix;

  /**
   * The prefix that was used when importing the library into the original
   * source.
   */
  void set prefix(String value) {
    assert(value != null);
    this._prefix = value;
  }

  /**
   * The names of the elements imported from the library.
   */
  List<String> get elements => _elements;

  /**
   * The names of the elements imported from the library.
   */
  void set elements(List<String> value) {
    assert(value != null);
    this._elements = value;
  }

  ImportedElements(String path, String prefix, List<String> elements) {
    this.path = path;
    this.prefix = prefix;
    this.elements = elements;
  }

  factory ImportedElements.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String path;
      if (json.containsKey("path")) {
        path = jsonDecoder.decodeString(jsonPath + ".path", json["path"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "path");
      }
      String prefix;
      if (json.containsKey("prefix")) {
        prefix = jsonDecoder.decodeString(jsonPath + ".prefix", json["prefix"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "prefix");
      }
      List<String> elements;
      if (json.containsKey("elements")) {
        elements = jsonDecoder.decodeList(
            jsonPath + ".elements", json["elements"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "elements");
      }
      return new ImportedElements(path, prefix, elements);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ImportedElements", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["path"] = path;
    result["prefix"] = prefix;
    result["elements"] = elements;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    hash = JenkinsSmiHash.combine(hash, prefix.hashCode);
    hash = JenkinsSmiHash.combine(hash, elements.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * inlineLocalVariable feedback
 *
 * {
 *   "name": String
 *   "occurrences": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class InlineLocalVariableFeedback extends RefactoringFeedback {
  String _name;

  int _occurrences;

  /**
   * The name of the variable being inlined.
   */
  String get name => _name;

  /**
   * The name of the variable being inlined.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * The number of times the variable occurs.
   */
  int get occurrences => _occurrences;

  /**
   * The number of times the variable occurs.
   */
  void set occurrences(int value) {
    assert(value != null);
    this._occurrences = value;
  }

  InlineLocalVariableFeedback(String name, int occurrences) {
    this.name = name;
    this.occurrences = occurrences;
  }

  factory InlineLocalVariableFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      int occurrences;
      if (json.containsKey("occurrences")) {
        occurrences = jsonDecoder.decodeInt(
            jsonPath + ".occurrences", json["occurrences"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "occurrences");
      }
      return new InlineLocalVariableFeedback(name, occurrences);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "inlineLocalVariable feedback", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    result["occurrences"] = occurrences;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineLocalVariableFeedback) {
      return name == other.name && occurrences == other.occurrences;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * inlineLocalVariable options
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

/**
 * inlineMethod feedback
 *
 * {
 *   "className": optional String
 *   "methodName": String
 *   "isDeclaration": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class InlineMethodFeedback extends RefactoringFeedback {
  String _className;

  String _methodName;

  bool _isDeclaration;

  /**
   * The name of the class enclosing the method being inlined. If not a class
   * member is being inlined, this field will be absent.
   */
  String get className => _className;

  /**
   * The name of the class enclosing the method being inlined. If not a class
   * member is being inlined, this field will be absent.
   */
  void set className(String value) {
    this._className = value;
  }

  /**
   * The name of the method (or function) being inlined.
   */
  String get methodName => _methodName;

  /**
   * The name of the method (or function) being inlined.
   */
  void set methodName(String value) {
    assert(value != null);
    this._methodName = value;
  }

  /**
   * True if the declaration of the method is selected. So all references
   * should be inlined.
   */
  bool get isDeclaration => _isDeclaration;

  /**
   * True if the declaration of the method is selected. So all references
   * should be inlined.
   */
  void set isDeclaration(bool value) {
    assert(value != null);
    this._isDeclaration = value;
  }

  InlineMethodFeedback(String methodName, bool isDeclaration,
      {String className}) {
    this.className = className;
    this.methodName = methodName;
    this.isDeclaration = isDeclaration;
  }

  factory InlineMethodFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String className;
      if (json.containsKey("className")) {
        className = jsonDecoder.decodeString(
            jsonPath + ".className", json["className"]);
      }
      String methodName;
      if (json.containsKey("methodName")) {
        methodName = jsonDecoder.decodeString(
            jsonPath + ".methodName", json["methodName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "methodName");
      }
      bool isDeclaration;
      if (json.containsKey("isDeclaration")) {
        isDeclaration = jsonDecoder.decodeBool(
            jsonPath + ".isDeclaration", json["isDeclaration"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isDeclaration");
      }
      return new InlineMethodFeedback(methodName, isDeclaration,
          className: className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod feedback", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (className != null) {
      result["className"] = className;
    }
    result["methodName"] = methodName;
    result["isDeclaration"] = isDeclaration;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    hash = JenkinsSmiHash.combine(hash, methodName.hashCode);
    hash = JenkinsSmiHash.combine(hash, isDeclaration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * inlineMethod options
 *
 * {
 *   "deleteSource": bool
 *   "inlineAll": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class InlineMethodOptions extends RefactoringOptions {
  bool _deleteSource;

  bool _inlineAll;

  /**
   * True if the method being inlined should be removed. It is an error if this
   * field is true and inlineAll is false.
   */
  bool get deleteSource => _deleteSource;

  /**
   * True if the method being inlined should be removed. It is an error if this
   * field is true and inlineAll is false.
   */
  void set deleteSource(bool value) {
    assert(value != null);
    this._deleteSource = value;
  }

  /**
   * True if all invocations of the method should be inlined, or false if only
   * the invocation site used to create this refactoring should be inlined.
   */
  bool get inlineAll => _inlineAll;

  /**
   * True if all invocations of the method should be inlined, or false if only
   * the invocation site used to create this refactoring should be inlined.
   */
  void set inlineAll(bool value) {
    assert(value != null);
    this._inlineAll = value;
  }

  InlineMethodOptions(bool deleteSource, bool inlineAll) {
    this.deleteSource = deleteSource;
    this.inlineAll = inlineAll;
  }

  factory InlineMethodOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool deleteSource;
      if (json.containsKey("deleteSource")) {
        deleteSource = jsonDecoder.decodeBool(
            jsonPath + ".deleteSource", json["deleteSource"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "deleteSource");
      }
      bool inlineAll;
      if (json.containsKey("inlineAll")) {
        inlineAll =
            jsonDecoder.decodeBool(jsonPath + ".inlineAll", json["inlineAll"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "inlineAll");
      }
      return new InlineMethodOptions(deleteSource, inlineAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod options", json);
    }
  }

  factory InlineMethodOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return new InlineMethodOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["deleteSource"] = deleteSource;
    result["inlineAll"] = inlineAll;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is InlineMethodOptions) {
      return deleteSource == other.deleteSource && inlineAll == other.inlineAll;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, deleteSource.hashCode);
    hash = JenkinsSmiHash.combine(hash, inlineAll.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * kythe.getKytheEntries params
 *
 * {
 *   "file": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class KytheGetKytheEntriesParams implements RequestParams {
  String _file;

  /**
   * The file containing the code for which the Kythe Entry objects are being
   * requested.
   */
  String get file => _file;

  /**
   * The file containing the code for which the Kythe Entry objects are being
   * requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  KytheGetKytheEntriesParams(String file) {
    this.file = file;
  }

  factory KytheGetKytheEntriesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      return new KytheGetKytheEntriesParams(file);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "kythe.getKytheEntries params", json);
    }
  }

  factory KytheGetKytheEntriesParams.fromRequest(Request request) {
    return new KytheGetKytheEntriesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "kythe.getKytheEntries", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is KytheGetKytheEntriesParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * kythe.getKytheEntries result
 *
 * {
 *   "entries": List<KytheEntry>
 *   "files": List<FilePath>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class KytheGetKytheEntriesResult implements ResponseResult {
  List<KytheEntry> _entries;

  List<String> _files;

  /**
   * The list of KytheEntry objects for the queried file.
   */
  List<KytheEntry> get entries => _entries;

  /**
   * The list of KytheEntry objects for the queried file.
   */
  void set entries(List<KytheEntry> value) {
    assert(value != null);
    this._entries = value;
  }

  /**
   * The set of files paths that were required, but not in the file system, to
   * give a complete and accurate Kythe graph for the file. This could be due
   * to a referenced file that does not exist or generated files not being
   * generated or passed before the call to "getKytheEntries".
   */
  List<String> get files => _files;

  /**
   * The set of files paths that were required, but not in the file system, to
   * give a complete and accurate Kythe graph for the file. This could be due
   * to a referenced file that does not exist or generated files not being
   * generated or passed before the call to "getKytheEntries".
   */
  void set files(List<String> value) {
    assert(value != null);
    this._files = value;
  }

  KytheGetKytheEntriesResult(List<KytheEntry> entries, List<String> files) {
    this.entries = entries;
    this.files = files;
  }

  factory KytheGetKytheEntriesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<KytheEntry> entries;
      if (json.containsKey("entries")) {
        entries = jsonDecoder.decodeList(
            jsonPath + ".entries",
            json["entries"],
            (String jsonPath, Object json) =>
                new KytheEntry.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "entries");
      }
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(
            jsonPath + ".files", json["files"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new KytheGetKytheEntriesResult(entries, files);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "kythe.getKytheEntries result", json);
    }
  }

  factory KytheGetKytheEntriesResult.fromResponse(Response response) {
    return new KytheGetKytheEntriesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["entries"] =
        entries.map((KytheEntry value) => value.toJson()).toList();
    result["files"] = files;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, entries.hashCode);
    hash = JenkinsSmiHash.combine(hash, files.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * moveFile feedback
 *
 * Clients may not extend, implement or mix-in this class.
 */
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

/**
 * moveFile options
 *
 * {
 *   "newFile": FilePath
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class MoveFileOptions extends RefactoringOptions {
  String _newFile;

  /**
   * The new file path to which the given file is being moved.
   */
  String get newFile => _newFile;

  /**
   * The new file path to which the given file is being moved.
   */
  void set newFile(String value) {
    assert(value != null);
    this._newFile = value;
  }

  MoveFileOptions(String newFile) {
    this.newFile = newFile;
  }

  factory MoveFileOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String newFile;
      if (json.containsKey("newFile")) {
        newFile =
            jsonDecoder.decodeString(jsonPath + ".newFile", json["newFile"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "newFile");
      }
      return new MoveFileOptions(newFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "moveFile options", json);
    }
  }

  factory MoveFileOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return new MoveFileOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["newFile"] = newFile;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is MoveFileOptions) {
      return newFile == other.newFile;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, newFile.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * OverriddenMember
 *
 * {
 *   "element": Element
 *   "className": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class OverriddenMember implements HasToJson {
  Element _element;

  String _className;

  /**
   * The element that is being overridden.
   */
  Element get element => _element;

  /**
   * The element that is being overridden.
   */
  void set element(Element value) {
    assert(value != null);
    this._element = value;
  }

  /**
   * The name of the class in which the member is defined.
   */
  String get className => _className;

  /**
   * The name of the class in which the member is defined.
   */
  void set className(String value) {
    assert(value != null);
    this._className = value;
  }

  OverriddenMember(Element element, String className) {
    this.element = element;
    this.className = className;
  }

  factory OverriddenMember.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(
            jsonDecoder, jsonPath + ".element", json["element"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "element");
      }
      String className;
      if (json.containsKey("className")) {
        className = jsonDecoder.decodeString(
            jsonPath + ".className", json["className"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "className");
      }
      return new OverriddenMember(element, className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "OverriddenMember", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["element"] = element.toJson();
    result["className"] = className;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is OverriddenMember) {
      return element == other.element && className == other.className;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, className.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * Override
 *
 * {
 *   "offset": int
 *   "length": int
 *   "superclassMember": optional OverriddenMember
 *   "interfaceMembers": optional List<OverriddenMember>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Override implements HasToJson {
  int _offset;

  int _length;

  OverriddenMember _superclassMember;

  List<OverriddenMember> _interfaceMembers;

  /**
   * The offset of the name of the overriding member.
   */
  int get offset => _offset;

  /**
   * The offset of the name of the overriding member.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the name of the overriding member.
   */
  int get length => _length;

  /**
   * The length of the name of the overriding member.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The member inherited from a superclass that is overridden by the
   * overriding member. The field is omitted if there is no superclass member,
   * in which case there must be at least one interface member.
   */
  OverriddenMember get superclassMember => _superclassMember;

  /**
   * The member inherited from a superclass that is overridden by the
   * overriding member. The field is omitted if there is no superclass member,
   * in which case there must be at least one interface member.
   */
  void set superclassMember(OverriddenMember value) {
    this._superclassMember = value;
  }

  /**
   * The members inherited from interfaces that are overridden by the
   * overriding member. The field is omitted if there are no interface members,
   * in which case there must be a superclass member.
   */
  List<OverriddenMember> get interfaceMembers => _interfaceMembers;

  /**
   * The members inherited from interfaces that are overridden by the
   * overriding member. The field is omitted if there are no interface members,
   * in which case there must be a superclass member.
   */
  void set interfaceMembers(List<OverriddenMember> value) {
    this._interfaceMembers = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      OverriddenMember superclassMember;
      if (json.containsKey("superclassMember")) {
        superclassMember = new OverriddenMember.fromJson(jsonDecoder,
            jsonPath + ".superclassMember", json["superclassMember"]);
      }
      List<OverriddenMember> interfaceMembers;
      if (json.containsKey("interfaceMembers")) {
        interfaceMembers = jsonDecoder.decodeList(
            jsonPath + ".interfaceMembers",
            json["interfaceMembers"],
            (String jsonPath, Object json) =>
                new OverriddenMember.fromJson(jsonDecoder, jsonPath, json));
      }
      return new Override(offset, length,
          superclassMember: superclassMember,
          interfaceMembers: interfaceMembers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Override", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    if (superclassMember != null) {
      result["superclassMember"] = superclassMember.toJson();
    }
    if (interfaceMembers != null) {
      result["interfaceMembers"] = interfaceMembers
          .map((OverriddenMember value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, superclassMember.hashCode);
    hash = JenkinsSmiHash.combine(hash, interfaceMembers.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * PostfixTemplateDescriptor
 *
 * {
 *   "name": String
 *   "key": String
 *   "example": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PostfixTemplateDescriptor implements HasToJson {
  String _name;

  String _key;

  String _example;

  /**
   * The template name, shown in the UI.
   */
  String get name => _name;

  /**
   * The template name, shown in the UI.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * The unique template key, not shown in the UI.
   */
  String get key => _key;

  /**
   * The unique template key, not shown in the UI.
   */
  void set key(String value) {
    assert(value != null);
    this._key = value;
  }

  /**
   * A short example of the transformation performed when the template is
   * applied.
   */
  String get example => _example;

  /**
   * A short example of the transformation performed when the template is
   * applied.
   */
  void set example(String value) {
    assert(value != null);
    this._example = value;
  }

  PostfixTemplateDescriptor(String name, String key, String example) {
    this.name = name;
    this.key = key;
    this.example = example;
  }

  factory PostfixTemplateDescriptor.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      String key;
      if (json.containsKey("key")) {
        key = jsonDecoder.decodeString(jsonPath + ".key", json["key"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "key");
      }
      String example;
      if (json.containsKey("example")) {
        example =
            jsonDecoder.decodeString(jsonPath + ".example", json["example"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "example");
      }
      return new PostfixTemplateDescriptor(name, key, example);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "PostfixTemplateDescriptor", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    result["key"] = key;
    result["example"] = example;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PostfixTemplateDescriptor) {
      return name == other.name && key == other.key && example == other.example;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, key.hashCode);
    hash = JenkinsSmiHash.combine(hash, example.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * PubStatus
 *
 * {
 *   "isListingPackageDirs": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PubStatus implements HasToJson {
  bool _isListingPackageDirs;

  /**
   * True if the server is currently running pub to produce a list of package
   * directories.
   */
  bool get isListingPackageDirs => _isListingPackageDirs;

  /**
   * True if the server is currently running pub to produce a list of package
   * directories.
   */
  void set isListingPackageDirs(bool value) {
    assert(value != null);
    this._isListingPackageDirs = value;
  }

  PubStatus(bool isListingPackageDirs) {
    this.isListingPackageDirs = isListingPackageDirs;
  }

  factory PubStatus.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isListingPackageDirs;
      if (json.containsKey("isListingPackageDirs")) {
        isListingPackageDirs = jsonDecoder.decodeBool(
            jsonPath + ".isListingPackageDirs", json["isListingPackageDirs"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isListingPackageDirs");
      }
      return new PubStatus(isListingPackageDirs);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "PubStatus", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["isListingPackageDirs"] = isListingPackageDirs;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is PubStatus) {
      return isListingPackageDirs == other.isListingPackageDirs;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, isListingPackageDirs.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * RefactoringFeedback
 *
 * {
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringFeedback implements HasToJson {
  RefactoringFeedback();

  factory RefactoringFeedback.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json, Map responseJson) {
    return refactoringFeedbackFromJson(
        jsonDecoder, jsonPath, json, responseJson);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RefactoringFeedback) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * RefactoringOptions
 *
 * {
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringOptions implements HasToJson {
  RefactoringOptions();

  factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath,
      Object json, RefactoringKind kind) {
    return refactoringOptionsFromJson(jsonDecoder, jsonPath, json, kind);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RefactoringOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * rename feedback
 *
 * {
 *   "offset": int
 *   "length": int
 *   "elementKindName": String
 *   "oldName": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RenameFeedback extends RefactoringFeedback {
  int _offset;

  int _length;

  String _elementKindName;

  String _oldName;

  /**
   * The offset to the beginning of the name selected to be renamed.
   */
  int get offset => _offset;

  /**
   * The offset to the beginning of the name selected to be renamed.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the name selected to be renamed.
   */
  int get length => _length;

  /**
   * The length of the name selected to be renamed.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The human-readable description of the kind of element being renamed (such
   * as "class" or "function type alias").
   */
  String get elementKindName => _elementKindName;

  /**
   * The human-readable description of the kind of element being renamed (such
   * as "class" or "function type alias").
   */
  void set elementKindName(String value) {
    assert(value != null);
    this._elementKindName = value;
  }

  /**
   * The old name of the element before the refactoring.
   */
  String get oldName => _oldName;

  /**
   * The old name of the element before the refactoring.
   */
  void set oldName(String value) {
    assert(value != null);
    this._oldName = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      String elementKindName;
      if (json.containsKey("elementKindName")) {
        elementKindName = jsonDecoder.decodeString(
            jsonPath + ".elementKindName", json["elementKindName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "elementKindName");
      }
      String oldName;
      if (json.containsKey("oldName")) {
        oldName =
            jsonDecoder.decodeString(jsonPath + ".oldName", json["oldName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "oldName");
      }
      return new RenameFeedback(offset, length, elementKindName, oldName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "rename feedback", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    result["elementKindName"] = elementKindName;
    result["oldName"] = oldName;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, elementKindName.hashCode);
    hash = JenkinsSmiHash.combine(hash, oldName.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * rename options
 *
 * {
 *   "newName": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RenameOptions extends RefactoringOptions {
  String _newName;

  /**
   * The name that the element should have after the refactoring.
   */
  String get newName => _newName;

  /**
   * The name that the element should have after the refactoring.
   */
  void set newName(String value) {
    assert(value != null);
    this._newName = value;
  }

  RenameOptions(String newName) {
    this.newName = newName;
  }

  factory RenameOptions.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String newName;
      if (json.containsKey("newName")) {
        newName =
            jsonDecoder.decodeString(jsonPath + ".newName", json["newName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "newName");
      }
      return new RenameOptions(newName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "rename options", json);
    }
  }

  factory RenameOptions.fromRefactoringParams(
      EditGetRefactoringParams refactoringParams, Request request) {
    return new RenameOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["newName"] = newName;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is RenameOptions) {
      return newName == other.newName;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, newName.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * RequestError
 *
 * {
 *   "code": RequestErrorCode
 *   "message": String
 *   "stackTrace": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RequestError implements HasToJson {
  RequestErrorCode _code;

  String _message;

  String _stackTrace;

  /**
   * A code that uniquely identifies the error that occurred.
   */
  RequestErrorCode get code => _code;

  /**
   * A code that uniquely identifies the error that occurred.
   */
  void set code(RequestErrorCode value) {
    assert(value != null);
    this._code = value;
  }

  /**
   * A short description of the error.
   */
  String get message => _message;

  /**
   * A short description of the error.
   */
  void set message(String value) {
    assert(value != null);
    this._message = value;
  }

  /**
   * The stack trace associated with processing the request, used for debugging
   * the server.
   */
  String get stackTrace => _stackTrace;

  /**
   * The stack trace associated with processing the request, used for debugging
   * the server.
   */
  void set stackTrace(String value) {
    this._stackTrace = value;
  }

  RequestError(RequestErrorCode code, String message, {String stackTrace}) {
    this.code = code;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  factory RequestError.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RequestErrorCode code;
      if (json.containsKey("code")) {
        code = new RequestErrorCode.fromJson(
            jsonDecoder, jsonPath + ".code", json["code"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "code");
      }
      String message;
      if (json.containsKey("message")) {
        message =
            jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      String stackTrace;
      if (json.containsKey("stackTrace")) {
        stackTrace = jsonDecoder.decodeString(
            jsonPath + ".stackTrace", json["stackTrace"]);
      }
      return new RequestError(code, message, stackTrace: stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RequestError", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["code"] = code.toJson();
    result["message"] = message;
    if (stackTrace != null) {
      result["stackTrace"] = stackTrace;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, stackTrace.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * RequestErrorCode
 *
 * enum {
 *   CONTENT_MODIFIED
 *   DEBUG_PORT_COULD_NOT_BE_OPENED
 *   FILE_NOT_ANALYZED
 *   FORMAT_INVALID_FILE
 *   FORMAT_WITH_ERRORS
 *   GET_ERRORS_INVALID_FILE
 *   GET_IMPORTED_ELEMENTS_INVALID_FILE
 *   GET_NAVIGATION_INVALID_FILE
 *   GET_REACHABLE_SOURCES_INVALID_FILE
 *   IMPORT_ELEMENTS_INVALID_FILE
 *   INVALID_ANALYSIS_ROOT
 *   INVALID_EXECUTION_CONTEXT
 *   INVALID_FILE_PATH_FORMAT
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   INVALID_REQUEST
 *   ORGANIZE_DIRECTIVES_ERROR
 *   REFACTORING_REQUEST_CANCELLED
 *   SERVER_ALREADY_STARTED
 *   SERVER_ERROR
 *   SORT_MEMBERS_INVALID_FILE
 *   SORT_MEMBERS_PARSE_ERRORS
 *   UNANALYZED_PRIORITY_FILES
 *   UNKNOWN_REQUEST
 *   UNKNOWN_SOURCE
 *   UNSUPPORTED_FEATURE
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RequestErrorCode implements Enum {
  /**
   * An "analysis.getErrors" or "analysis.getNavigation" request could not be
   * satisfied because the content of the file changed before the requested
   * results could be computed.
   */
  static const RequestErrorCode CONTENT_MODIFIED =
      const RequestErrorCode._("CONTENT_MODIFIED");

  /**
   * The server was unable to open a port for the diagnostic server.
   */
  static const RequestErrorCode DEBUG_PORT_COULD_NOT_BE_OPENED =
      const RequestErrorCode._("DEBUG_PORT_COULD_NOT_BE_OPENED");

  /**
   * A request specified a FilePath which does not match a file in an analysis
   * root, or the requested operation is not available for the file.
   */
  static const RequestErrorCode FILE_NOT_ANALYZED =
      const RequestErrorCode._("FILE_NOT_ANALYZED");

  /**
   * An "edit.format" request specified a FilePath which does not match a Dart
   * file in an analysis root.
   */
  static const RequestErrorCode FORMAT_INVALID_FILE =
      const RequestErrorCode._("FORMAT_INVALID_FILE");

  /**
   * An "edit.format" request specified a file that contains syntax errors.
   */
  static const RequestErrorCode FORMAT_WITH_ERRORS =
      const RequestErrorCode._("FORMAT_WITH_ERRORS");

  /**
   * An "analysis.getErrors" request specified a FilePath which does not match
   * a file currently subject to analysis.
   */
  static const RequestErrorCode GET_ERRORS_INVALID_FILE =
      const RequestErrorCode._("GET_ERRORS_INVALID_FILE");

  /**
   * An "analysis.getImportedElements" request specified a FilePath that does
   * not match a file currently subject to analysis.
   */
  static const RequestErrorCode GET_IMPORTED_ELEMENTS_INVALID_FILE =
      const RequestErrorCode._("GET_IMPORTED_ELEMENTS_INVALID_FILE");

  /**
   * An "analysis.getNavigation" request specified a FilePath which does not
   * match a file currently subject to analysis.
   */
  static const RequestErrorCode GET_NAVIGATION_INVALID_FILE =
      const RequestErrorCode._("GET_NAVIGATION_INVALID_FILE");

  /**
   * An "analysis.getReachableSources" request specified a FilePath which does
   * not match a file currently subject to analysis.
   */
  static const RequestErrorCode GET_REACHABLE_SOURCES_INVALID_FILE =
      const RequestErrorCode._("GET_REACHABLE_SOURCES_INVALID_FILE");

  /**
   * An "edit.importElements" request specified a FilePath that does not match
   * a file currently subject to analysis.
   */
  static const RequestErrorCode IMPORT_ELEMENTS_INVALID_FILE =
      const RequestErrorCode._("IMPORT_ELEMENTS_INVALID_FILE");

  /**
   * A path passed as an argument to a request (such as analysis.reanalyze) is
   * required to be an analysis root, but isn't.
   */
  static const RequestErrorCode INVALID_ANALYSIS_ROOT =
      const RequestErrorCode._("INVALID_ANALYSIS_ROOT");

  /**
   * The context root used to create an execution context does not exist.
   */
  static const RequestErrorCode INVALID_EXECUTION_CONTEXT =
      const RequestErrorCode._("INVALID_EXECUTION_CONTEXT");

  /**
   * The format of the given file path is invalid, e.g. is not absolute and
   * normalized.
   */
  static const RequestErrorCode INVALID_FILE_PATH_FORMAT =
      const RequestErrorCode._("INVALID_FILE_PATH_FORMAT");

  /**
   * An "analysis.updateContent" request contained a ChangeContentOverlay
   * object which can't be applied, due to an edit having an offset or length
   * that is out of range.
   */
  static const RequestErrorCode INVALID_OVERLAY_CHANGE =
      const RequestErrorCode._("INVALID_OVERLAY_CHANGE");

  /**
   * One of the method parameters was invalid.
   */
  static const RequestErrorCode INVALID_PARAMETER =
      const RequestErrorCode._("INVALID_PARAMETER");

  /**
   * A malformed request was received.
   */
  static const RequestErrorCode INVALID_REQUEST =
      const RequestErrorCode._("INVALID_REQUEST");

  /**
   * An "edit.organizeDirectives" request specified a Dart file that cannot be
   * analyzed. The reason is described in the message.
   */
  static const RequestErrorCode ORGANIZE_DIRECTIVES_ERROR =
      const RequestErrorCode._("ORGANIZE_DIRECTIVES_ERROR");

  /**
   * Another refactoring request was received during processing of this one.
   */
  static const RequestErrorCode REFACTORING_REQUEST_CANCELLED =
      const RequestErrorCode._("REFACTORING_REQUEST_CANCELLED");

  /**
   * The analysis server has already been started (and hence won't accept new
   * connections).
   *
   * This error is included for future expansion; at present the analysis
   * server can only speak to one client at a time so this error will never
   * occur.
   */
  static const RequestErrorCode SERVER_ALREADY_STARTED =
      const RequestErrorCode._("SERVER_ALREADY_STARTED");

  /**
   * An internal error occurred in the analysis server. Also see the
   * server.error notification.
   */
  static const RequestErrorCode SERVER_ERROR =
      const RequestErrorCode._("SERVER_ERROR");

  /**
   * An "edit.sortMembers" request specified a FilePath which does not match a
   * Dart file in an analysis root.
   */
  static const RequestErrorCode SORT_MEMBERS_INVALID_FILE =
      const RequestErrorCode._("SORT_MEMBERS_INVALID_FILE");

  /**
   * An "edit.sortMembers" request specified a Dart file that has scan or parse
   * errors.
   */
  static const RequestErrorCode SORT_MEMBERS_PARSE_ERRORS =
      const RequestErrorCode._("SORT_MEMBERS_PARSE_ERRORS");

  /**
   * An "analysis.setPriorityFiles" request includes one or more files that are
   * not being analyzed.
   *
   * This is a legacy error; it will be removed before the API reaches version
   * 1.0.
   */
  static const RequestErrorCode UNANALYZED_PRIORITY_FILES =
      const RequestErrorCode._("UNANALYZED_PRIORITY_FILES");

  /**
   * A request was received which the analysis server does not recognize, or
   * cannot handle in its current configuration.
   */
  static const RequestErrorCode UNKNOWN_REQUEST =
      const RequestErrorCode._("UNKNOWN_REQUEST");

  /**
   * The analysis server was requested to perform an action on a source that
   * does not exist.
   */
  static const RequestErrorCode UNKNOWN_SOURCE =
      const RequestErrorCode._("UNKNOWN_SOURCE");

  /**
   * The analysis server was requested to perform an action which is not
   * supported.
   *
   * This is a legacy error; it will be removed before the API reaches version
   * 1.0.
   */
  static const RequestErrorCode UNSUPPORTED_FEATURE =
      const RequestErrorCode._("UNSUPPORTED_FEATURE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RequestErrorCode> VALUES = const <RequestErrorCode>[
    CONTENT_MODIFIED,
    DEBUG_PORT_COULD_NOT_BE_OPENED,
    FILE_NOT_ANALYZED,
    FORMAT_INVALID_FILE,
    FORMAT_WITH_ERRORS,
    GET_ERRORS_INVALID_FILE,
    GET_IMPORTED_ELEMENTS_INVALID_FILE,
    GET_NAVIGATION_INVALID_FILE,
    GET_REACHABLE_SOURCES_INVALID_FILE,
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
    UNANALYZED_PRIORITY_FILES,
    UNKNOWN_REQUEST,
    UNKNOWN_SOURCE,
    UNSUPPORTED_FEATURE
  ];

  @override
  final String name;

  const RequestErrorCode._(this.name);

  factory RequestErrorCode(String name) {
    switch (name) {
      case "CONTENT_MODIFIED":
        return CONTENT_MODIFIED;
      case "DEBUG_PORT_COULD_NOT_BE_OPENED":
        return DEBUG_PORT_COULD_NOT_BE_OPENED;
      case "FILE_NOT_ANALYZED":
        return FILE_NOT_ANALYZED;
      case "FORMAT_INVALID_FILE":
        return FORMAT_INVALID_FILE;
      case "FORMAT_WITH_ERRORS":
        return FORMAT_WITH_ERRORS;
      case "GET_ERRORS_INVALID_FILE":
        return GET_ERRORS_INVALID_FILE;
      case "GET_IMPORTED_ELEMENTS_INVALID_FILE":
        return GET_IMPORTED_ELEMENTS_INVALID_FILE;
      case "GET_NAVIGATION_INVALID_FILE":
        return GET_NAVIGATION_INVALID_FILE;
      case "GET_REACHABLE_SOURCES_INVALID_FILE":
        return GET_REACHABLE_SOURCES_INVALID_FILE;
      case "IMPORT_ELEMENTS_INVALID_FILE":
        return IMPORT_ELEMENTS_INVALID_FILE;
      case "INVALID_ANALYSIS_ROOT":
        return INVALID_ANALYSIS_ROOT;
      case "INVALID_EXECUTION_CONTEXT":
        return INVALID_EXECUTION_CONTEXT;
      case "INVALID_FILE_PATH_FORMAT":
        return INVALID_FILE_PATH_FORMAT;
      case "INVALID_OVERLAY_CHANGE":
        return INVALID_OVERLAY_CHANGE;
      case "INVALID_PARAMETER":
        return INVALID_PARAMETER;
      case "INVALID_REQUEST":
        return INVALID_REQUEST;
      case "ORGANIZE_DIRECTIVES_ERROR":
        return ORGANIZE_DIRECTIVES_ERROR;
      case "REFACTORING_REQUEST_CANCELLED":
        return REFACTORING_REQUEST_CANCELLED;
      case "SERVER_ALREADY_STARTED":
        return SERVER_ALREADY_STARTED;
      case "SERVER_ERROR":
        return SERVER_ERROR;
      case "SORT_MEMBERS_INVALID_FILE":
        return SORT_MEMBERS_INVALID_FILE;
      case "SORT_MEMBERS_PARSE_ERRORS":
        return SORT_MEMBERS_PARSE_ERRORS;
      case "UNANALYZED_PRIORITY_FILES":
        return UNANALYZED_PRIORITY_FILES;
      case "UNKNOWN_REQUEST":
        return UNKNOWN_REQUEST;
      case "UNKNOWN_SOURCE":
        return UNKNOWN_SOURCE;
      case "UNSUPPORTED_FEATURE":
        return UNSUPPORTED_FEATURE;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory RequestErrorCode.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new RequestErrorCode(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "RequestErrorCode", json);
  }

  @override
  String toString() => "RequestErrorCode.$name";

  String toJson() => name;
}

/**
 * search.findElementReferences params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "includePotential": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindElementReferencesParams implements RequestParams {
  String _file;

  int _offset;

  bool _includePotential;

  /**
   * The file containing the declaration of or reference to the element used to
   * define the search.
   */
  String get file => _file;

  /**
   * The file containing the declaration of or reference to the element used to
   * define the search.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset within the file of the declaration of or reference to the
   * element.
   */
  int get offset => _offset;

  /**
   * The offset within the file of the declaration of or reference to the
   * element.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * True if potential matches are to be included in the results.
   */
  bool get includePotential => _includePotential;

  /**
   * True if potential matches are to be included in the results.
   */
  void set includePotential(bool value) {
    assert(value != null);
    this._includePotential = value;
  }

  SearchFindElementReferencesParams(
      String file, int offset, bool includePotential) {
    this.file = file;
    this.offset = offset;
    this.includePotential = includePotential;
  }

  factory SearchFindElementReferencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      bool includePotential;
      if (json.containsKey("includePotential")) {
        includePotential = jsonDecoder.decodeBool(
            jsonPath + ".includePotential", json["includePotential"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "includePotential");
      }
      return new SearchFindElementReferencesParams(
          file, offset, includePotential);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findElementReferences params", json);
    }
  }

  factory SearchFindElementReferencesParams.fromRequest(Request request) {
    return new SearchFindElementReferencesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["includePotential"] = includePotential;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "search.findElementReferences", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, includePotential.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findElementReferences result
 *
 * {
 *   "id": optional SearchId
 *   "element": optional Element
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindElementReferencesResult implements ResponseResult {
  String _id;

  Element _element;

  /**
   * The identifier used to associate results with this search request.
   *
   * If no element was found at the given location, this field will be absent,
   * and no results will be reported via the search.results notification.
   */
  String get id => _id;

  /**
   * The identifier used to associate results with this search request.
   *
   * If no element was found at the given location, this field will be absent,
   * and no results will be reported via the search.results notification.
   */
  void set id(String value) {
    this._id = value;
  }

  /**
   * The element referenced or defined at the given offset and whose references
   * will be returned in the search results.
   *
   * If no element was found at the given location, this field will be absent.
   */
  Element get element => _element;

  /**
   * The element referenced or defined at the given offset and whose references
   * will be returned in the search results.
   *
   * If no element was found at the given location, this field will be absent.
   */
  void set element(Element value) {
    this._element = value;
  }

  SearchFindElementReferencesResult({String id, Element element}) {
    this.id = id;
    this.element = element;
  }

  factory SearchFindElementReferencesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      }
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(
            jsonDecoder, jsonPath + ".element", json["element"]);
      }
      return new SearchFindElementReferencesResult(id: id, element: element);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findElementReferences result", json);
    }
  }

  factory SearchFindElementReferencesResult.fromResponse(Response response) {
    return new SearchFindElementReferencesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (id != null) {
      result["id"] = id;
    }
    if (element != null) {
      result["element"] = element.toJson();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindElementReferencesResult) {
      return id == other.id && element == other.element;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberDeclarations params
 *
 * {
 *   "name": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindMemberDeclarationsParams implements RequestParams {
  String _name;

  /**
   * The name of the declarations to be found.
   */
  String get name => _name;

  /**
   * The name of the declarations to be found.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  SearchFindMemberDeclarationsParams(String name) {
    this.name = name;
  }

  factory SearchFindMemberDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      return new SearchFindMemberDeclarationsParams(name);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findMemberDeclarations params", json);
    }
  }

  factory SearchFindMemberDeclarationsParams.fromRequest(Request request) {
    return new SearchFindMemberDeclarationsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "search.findMemberDeclarations", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberDeclarationsParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindMemberDeclarationsResult implements ResponseResult {
  String _id;

  /**
   * The identifier used to associate results with this search request.
   */
  String get id => _id;

  /**
   * The identifier used to associate results with this search request.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  SearchFindMemberDeclarationsResult(String id) {
    this.id = id;
  }

  factory SearchFindMemberDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      return new SearchFindMemberDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findMemberDeclarations result", json);
    }
  }

  factory SearchFindMemberDeclarationsResult.fromResponse(Response response) {
    return new SearchFindMemberDeclarationsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberReferences params
 *
 * {
 *   "name": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindMemberReferencesParams implements RequestParams {
  String _name;

  /**
   * The name of the references to be found.
   */
  String get name => _name;

  /**
   * The name of the references to be found.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  SearchFindMemberReferencesParams(String name) {
    this.name = name;
  }

  factory SearchFindMemberReferencesParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      return new SearchFindMemberReferencesParams(name);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findMemberReferences params", json);
    }
  }

  factory SearchFindMemberReferencesParams.fromRequest(Request request) {
    return new SearchFindMemberReferencesParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "search.findMemberReferences", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberReferencesParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberReferences result
 *
 * {
 *   "id": SearchId
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindMemberReferencesResult implements ResponseResult {
  String _id;

  /**
   * The identifier used to associate results with this search request.
   */
  String get id => _id;

  /**
   * The identifier used to associate results with this search request.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  SearchFindMemberReferencesResult(String id) {
    this.id = id;
  }

  factory SearchFindMemberReferencesResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      return new SearchFindMemberReferencesResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findMemberReferences result", json);
    }
  }

  factory SearchFindMemberReferencesResult.fromResponse(Response response) {
    return new SearchFindMemberReferencesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindMemberReferencesResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findTopLevelDeclarations params
 *
 * {
 *   "pattern": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindTopLevelDeclarationsParams implements RequestParams {
  String _pattern;

  /**
   * The regular expression used to match the names of the declarations to be
   * found.
   */
  String get pattern => _pattern;

  /**
   * The regular expression used to match the names of the declarations to be
   * found.
   */
  void set pattern(String value) {
    assert(value != null);
    this._pattern = value;
  }

  SearchFindTopLevelDeclarationsParams(String pattern) {
    this.pattern = pattern;
  }

  factory SearchFindTopLevelDeclarationsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String pattern;
      if (json.containsKey("pattern")) {
        pattern =
            jsonDecoder.decodeString(jsonPath + ".pattern", json["pattern"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "pattern");
      }
      return new SearchFindTopLevelDeclarationsParams(pattern);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findTopLevelDeclarations params", json);
    }
  }

  factory SearchFindTopLevelDeclarationsParams.fromRequest(Request request) {
    return new SearchFindTopLevelDeclarationsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["pattern"] = pattern;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "search.findTopLevelDeclarations", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindTopLevelDeclarationsParams) {
      return pattern == other.pattern;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, pattern.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findTopLevelDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchFindTopLevelDeclarationsResult implements ResponseResult {
  String _id;

  /**
   * The identifier used to associate results with this search request.
   */
  String get id => _id;

  /**
   * The identifier used to associate results with this search request.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  SearchFindTopLevelDeclarationsResult(String id) {
    this.id = id;
  }

  factory SearchFindTopLevelDeclarationsResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      return new SearchFindTopLevelDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.findTopLevelDeclarations result", json);
    }
  }

  factory SearchFindTopLevelDeclarationsResult.fromResponse(Response response) {
    return new SearchFindTopLevelDeclarationsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is SearchFindTopLevelDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.getTypeHierarchy params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "superOnly": optional bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchGetTypeHierarchyParams implements RequestParams {
  String _file;

  int _offset;

  bool _superOnly;

  /**
   * The file containing the declaration or reference to the type for which a
   * hierarchy is being requested.
   */
  String get file => _file;

  /**
   * The file containing the declaration or reference to the type for which a
   * hierarchy is being requested.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the name of the type within the file.
   */
  int get offset => _offset;

  /**
   * The offset of the name of the type within the file.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * True if the client is only requesting superclasses and interfaces
   * hierarchy.
   */
  bool get superOnly => _superOnly;

  /**
   * True if the client is only requesting superclasses and interfaces
   * hierarchy.
   */
  void set superOnly(bool value) {
    this._superOnly = value;
  }

  SearchGetTypeHierarchyParams(String file, int offset, {bool superOnly}) {
    this.file = file;
    this.offset = offset;
    this.superOnly = superOnly;
  }

  factory SearchGetTypeHierarchyParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder.decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder.decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offset");
      }
      bool superOnly;
      if (json.containsKey("superOnly")) {
        superOnly =
            jsonDecoder.decodeBool(jsonPath + ".superOnly", json["superOnly"]);
      }
      return new SearchGetTypeHierarchyParams(file, offset,
          superOnly: superOnly);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.getTypeHierarchy params", json);
    }
  }

  factory SearchGetTypeHierarchyParams.fromRequest(Request request) {
    return new SearchGetTypeHierarchyParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    if (superOnly != null) {
      result["superOnly"] = superOnly;
    }
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "search.getTypeHierarchy", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, superOnly.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.getTypeHierarchy result
 *
 * {
 *   "hierarchyItems": optional List<TypeHierarchyItem>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchGetTypeHierarchyResult implements ResponseResult {
  List<TypeHierarchyItem> _hierarchyItems;

  /**
   * A list of the types in the requested hierarchy. The first element of the
   * list is the item representing the type for which the hierarchy was
   * requested. The index of other elements of the list is unspecified, but
   * correspond to the integers used to reference supertype and subtype items
   * within the items.
   *
   * This field will be absent if the code at the given file and offset does
   * not represent a type, or if the file has not been sufficiently analyzed to
   * allow a type hierarchy to be produced.
   */
  List<TypeHierarchyItem> get hierarchyItems => _hierarchyItems;

  /**
   * A list of the types in the requested hierarchy. The first element of the
   * list is the item representing the type for which the hierarchy was
   * requested. The index of other elements of the list is unspecified, but
   * correspond to the integers used to reference supertype and subtype items
   * within the items.
   *
   * This field will be absent if the code at the given file and offset does
   * not represent a type, or if the file has not been sufficiently analyzed to
   * allow a type hierarchy to be produced.
   */
  void set hierarchyItems(List<TypeHierarchyItem> value) {
    this._hierarchyItems = value;
  }

  SearchGetTypeHierarchyResult({List<TypeHierarchyItem> hierarchyItems}) {
    this.hierarchyItems = hierarchyItems;
  }

  factory SearchGetTypeHierarchyResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<TypeHierarchyItem> hierarchyItems;
      if (json.containsKey("hierarchyItems")) {
        hierarchyItems = jsonDecoder.decodeList(
            jsonPath + ".hierarchyItems",
            json["hierarchyItems"],
            (String jsonPath, Object json) =>
                new TypeHierarchyItem.fromJson(jsonDecoder, jsonPath, json));
      }
      return new SearchGetTypeHierarchyResult(hierarchyItems: hierarchyItems);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "search.getTypeHierarchy result", json);
    }
  }

  factory SearchGetTypeHierarchyResult.fromResponse(Response response) {
    return new SearchGetTypeHierarchyResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (hierarchyItems != null) {
      result["hierarchyItems"] = hierarchyItems
          .map((TypeHierarchyItem value) => value.toJson())
          .toList();
    }
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, hierarchyItems.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * SearchResult
 *
 * {
 *   "location": Location
 *   "kind": SearchResultKind
 *   "isPotential": bool
 *   "path": List<Element>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchResult implements HasToJson {
  Location _location;

  SearchResultKind _kind;

  bool _isPotential;

  List<Element> _path;

  /**
   * The location of the code that matched the search criteria.
   */
  Location get location => _location;

  /**
   * The location of the code that matched the search criteria.
   */
  void set location(Location value) {
    assert(value != null);
    this._location = value;
  }

  /**
   * The kind of element that was found or the kind of reference that was
   * found.
   */
  SearchResultKind get kind => _kind;

  /**
   * The kind of element that was found or the kind of reference that was
   * found.
   */
  void set kind(SearchResultKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * True if the result is a potential match but cannot be confirmed to be a
   * match. For example, if all references to a method m defined in some class
   * were requested, and a reference to a method m from an unknown class were
   * found, it would be marked as being a potential match.
   */
  bool get isPotential => _isPotential;

  /**
   * True if the result is a potential match but cannot be confirmed to be a
   * match. For example, if all references to a method m defined in some class
   * were requested, and a reference to a method m from an unknown class were
   * found, it would be marked as being a potential match.
   */
  void set isPotential(bool value) {
    assert(value != null);
    this._isPotential = value;
  }

  /**
   * The elements that contain the result, starting with the most immediately
   * enclosing ancestor and ending with the library.
   */
  List<Element> get path => _path;

  /**
   * The elements that contain the result, starting with the most immediately
   * enclosing ancestor and ending with the library.
   */
  void set path(List<Element> value) {
    assert(value != null);
    this._path = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(
            jsonDecoder, jsonPath + ".location", json["location"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "location");
      }
      SearchResultKind kind;
      if (json.containsKey("kind")) {
        kind = new SearchResultKind.fromJson(
            jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      bool isPotential;
      if (json.containsKey("isPotential")) {
        isPotential = jsonDecoder.decodeBool(
            jsonPath + ".isPotential", json["isPotential"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isPotential");
      }
      List<Element> path;
      if (json.containsKey("path")) {
        path = jsonDecoder.decodeList(
            jsonPath + ".path",
            json["path"],
            (String jsonPath, Object json) =>
                new Element.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "path");
      }
      return new SearchResult(location, kind, isPotential, path);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SearchResult", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["location"] = location.toJson();
    result["kind"] = kind.toJson();
    result["isPotential"] = isPotential;
    result["path"] = path.map((Element value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, isPotential.hashCode);
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * SearchResultKind
 *
 * enum {
 *   DECLARATION
 *   INVOCATION
 *   READ
 *   READ_WRITE
 *   REFERENCE
 *   UNKNOWN
 *   WRITE
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchResultKind implements Enum {
  /**
   * The declaration of an element.
   */
  static const SearchResultKind DECLARATION =
      const SearchResultKind._("DECLARATION");

  /**
   * The invocation of a function or method.
   */
  static const SearchResultKind INVOCATION =
      const SearchResultKind._("INVOCATION");

  /**
   * A reference to a field, parameter or variable where it is being read.
   */
  static const SearchResultKind READ = const SearchResultKind._("READ");

  /**
   * A reference to a field, parameter or variable where it is being read and
   * written.
   */
  static const SearchResultKind READ_WRITE =
      const SearchResultKind._("READ_WRITE");

  /**
   * A reference to an element.
   */
  static const SearchResultKind REFERENCE =
      const SearchResultKind._("REFERENCE");

  /**
   * Some other kind of search result.
   */
  static const SearchResultKind UNKNOWN = const SearchResultKind._("UNKNOWN");

  /**
   * A reference to a field, parameter or variable where it is being written.
   */
  static const SearchResultKind WRITE = const SearchResultKind._("WRITE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<SearchResultKind> VALUES = const <SearchResultKind>[
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
      case "DECLARATION":
        return DECLARATION;
      case "INVOCATION":
        return INVOCATION;
      case "READ":
        return READ;
      case "READ_WRITE":
        return READ_WRITE;
      case "REFERENCE":
        return REFERENCE;
      case "UNKNOWN":
        return UNKNOWN;
      case "WRITE":
        return WRITE;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory SearchResultKind.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new SearchResultKind(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "SearchResultKind", json);
  }

  @override
  String toString() => "SearchResultKind.$name";

  String toJson() => name;
}

/**
 * search.results params
 *
 * {
 *   "id": SearchId
 *   "results": List<SearchResult>
 *   "isLast": bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SearchResultsParams implements HasToJson {
  String _id;

  List<SearchResult> _results;

  bool _isLast;

  /**
   * The id associated with the search.
   */
  String get id => _id;

  /**
   * The id associated with the search.
   */
  void set id(String value) {
    assert(value != null);
    this._id = value;
  }

  /**
   * The search results being reported.
   */
  List<SearchResult> get results => _results;

  /**
   * The search results being reported.
   */
  void set results(List<SearchResult> value) {
    assert(value != null);
    this._results = value;
  }

  /**
   * True if this is that last set of results that will be returned for the
   * indicated search.
   */
  bool get isLast => _isLast;

  /**
   * True if this is that last set of results that will be returned for the
   * indicated search.
   */
  void set isLast(bool value) {
    assert(value != null);
    this._isLast = value;
  }

  SearchResultsParams(String id, List<SearchResult> results, bool isLast) {
    this.id = id;
    this.results = results;
    this.isLast = isLast;
  }

  factory SearchResultsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "id");
      }
      List<SearchResult> results;
      if (json.containsKey("results")) {
        results = jsonDecoder.decodeList(
            jsonPath + ".results",
            json["results"],
            (String jsonPath, Object json) =>
                new SearchResult.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "results");
      }
      bool isLast;
      if (json.containsKey("isLast")) {
        isLast = jsonDecoder.decodeBool(jsonPath + ".isLast", json["isLast"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isLast");
      }
      return new SearchResultsParams(id, results, isLast);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.results params", json);
    }
  }

  factory SearchResultsParams.fromNotification(Notification notification) {
    return new SearchResultsParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    result["results"] =
        results.map((SearchResult value) => value.toJson()).toList();
    result["isLast"] = isLast;
    return result;
  }

  Notification toNotification() {
    return new Notification("search.results", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, results.hashCode);
    hash = JenkinsSmiHash.combine(hash, isLast.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * server.connected params
 *
 * {
 *   "version": String
 *   "pid": int
 *   "sessionId": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerConnectedParams implements HasToJson {
  String _version;

  int _pid;

  String _sessionId;

  /**
   * The version number of the analysis server.
   */
  String get version => _version;

  /**
   * The version number of the analysis server.
   */
  void set version(String value) {
    assert(value != null);
    this._version = value;
  }

  /**
   * The process id of the analysis server process.
   */
  int get pid => _pid;

  /**
   * The process id of the analysis server process.
   */
  void set pid(int value) {
    assert(value != null);
    this._pid = value;
  }

  /**
   * The session id for this session.
   */
  String get sessionId => _sessionId;

  /**
   * The session id for this session.
   */
  void set sessionId(String value) {
    this._sessionId = value;
  }

  ServerConnectedParams(String version, int pid, {String sessionId}) {
    this.version = version;
    this.pid = pid;
    this.sessionId = sessionId;
  }

  factory ServerConnectedParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String version;
      if (json.containsKey("version")) {
        version =
            jsonDecoder.decodeString(jsonPath + ".version", json["version"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "version");
      }
      int pid;
      if (json.containsKey("pid")) {
        pid = jsonDecoder.decodeInt(jsonPath + ".pid", json["pid"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "pid");
      }
      String sessionId;
      if (json.containsKey("sessionId")) {
        sessionId = jsonDecoder.decodeString(
            jsonPath + ".sessionId", json["sessionId"]);
      }
      return new ServerConnectedParams(version, pid, sessionId: sessionId);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.connected params", json);
    }
  }

  factory ServerConnectedParams.fromNotification(Notification notification) {
    return new ServerConnectedParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["version"] = version;
    result["pid"] = pid;
    if (sessionId != null) {
      result["sessionId"] = sessionId;
    }
    return result;
  }

  Notification toNotification() {
    return new Notification("server.connected", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerConnectedParams) {
      return version == other.version &&
          pid == other.pid &&
          sessionId == other.sessionId;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    hash = JenkinsSmiHash.combine(hash, pid.hashCode);
    hash = JenkinsSmiHash.combine(hash, sessionId.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * server.error params
 *
 * {
 *   "isFatal": bool
 *   "message": String
 *   "stackTrace": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerErrorParams implements HasToJson {
  bool _isFatal;

  String _message;

  String _stackTrace;

  /**
   * True if the error is a fatal error, meaning that the server will shutdown
   * automatically after sending this notification.
   */
  bool get isFatal => _isFatal;

  /**
   * True if the error is a fatal error, meaning that the server will shutdown
   * automatically after sending this notification.
   */
  void set isFatal(bool value) {
    assert(value != null);
    this._isFatal = value;
  }

  /**
   * The error message indicating what kind of error was encountered.
   */
  String get message => _message;

  /**
   * The error message indicating what kind of error was encountered.
   */
  void set message(String value) {
    assert(value != null);
    this._message = value;
  }

  /**
   * The stack trace associated with the generation of the error, used for
   * debugging the server.
   */
  String get stackTrace => _stackTrace;

  /**
   * The stack trace associated with the generation of the error, used for
   * debugging the server.
   */
  void set stackTrace(String value) {
    assert(value != null);
    this._stackTrace = value;
  }

  ServerErrorParams(bool isFatal, String message, String stackTrace) {
    this.isFatal = isFatal;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  factory ServerErrorParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isFatal;
      if (json.containsKey("isFatal")) {
        isFatal =
            jsonDecoder.decodeBool(jsonPath + ".isFatal", json["isFatal"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isFatal");
      }
      String message;
      if (json.containsKey("message")) {
        message =
            jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      String stackTrace;
      if (json.containsKey("stackTrace")) {
        stackTrace = jsonDecoder.decodeString(
            jsonPath + ".stackTrace", json["stackTrace"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "stackTrace");
      }
      return new ServerErrorParams(isFatal, message, stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.error params", json);
    }
  }

  factory ServerErrorParams.fromNotification(Notification notification) {
    return new ServerErrorParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["isFatal"] = isFatal;
    result["message"] = message;
    result["stackTrace"] = stackTrace;
    return result;
  }

  Notification toNotification() {
    return new Notification("server.error", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, isFatal.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, stackTrace.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * server.getVersion params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerGetVersionParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "server.getVersion", null);
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

/**
 * server.getVersion result
 *
 * {
 *   "version": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerGetVersionResult implements ResponseResult {
  String _version;

  /**
   * The version number of the analysis server.
   */
  String get version => _version;

  /**
   * The version number of the analysis server.
   */
  void set version(String value) {
    assert(value != null);
    this._version = value;
  }

  ServerGetVersionResult(String version) {
    this.version = version;
  }

  factory ServerGetVersionResult.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String version;
      if (json.containsKey("version")) {
        version =
            jsonDecoder.decodeString(jsonPath + ".version", json["version"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "version");
      }
      return new ServerGetVersionResult(version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.getVersion result", json);
    }
  }

  factory ServerGetVersionResult.fromResponse(Response response) {
    return new ServerGetVersionResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)),
        "result",
        response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["version"] = version;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerGetVersionResult) {
      return version == other.version;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ServerService
 *
 * enum {
 *   STATUS
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerService implements Enum {
  static const ServerService STATUS = const ServerService._("STATUS");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ServerService> VALUES = const <ServerService>[STATUS];

  @override
  final String name;

  const ServerService._(this.name);

  factory ServerService(String name) {
    switch (name) {
      case "STATUS":
        return STATUS;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ServerService.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ServerService(json);
      } catch (_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ServerService", json);
  }

  @override
  String toString() => "ServerService.$name";

  String toJson() => name;
}

/**
 * server.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ServerService>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerSetSubscriptionsParams implements RequestParams {
  List<ServerService> _subscriptions;

  /**
   * A list of the services being subscribed to.
   */
  List<ServerService> get subscriptions => _subscriptions;

  /**
   * A list of the services being subscribed to.
   */
  void set subscriptions(List<ServerService> value) {
    assert(value != null);
    this._subscriptions = value;
  }

  ServerSetSubscriptionsParams(List<ServerService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory ServerSetSubscriptionsParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ServerService> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder.decodeList(
            jsonPath + ".subscriptions",
            json["subscriptions"],
            (String jsonPath, Object json) =>
                new ServerService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "subscriptions");
      }
      return new ServerSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(
          jsonPath, "server.setSubscriptions params", json);
    }
  }

  factory ServerSetSubscriptionsParams.fromRequest(Request request) {
    return new ServerSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] =
        subscriptions.map((ServerService value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "server.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * server.setSubscriptions result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerSetSubscriptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * server.shutdown params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerShutdownParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "server.shutdown", null);
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

/**
 * server.shutdown result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerShutdownResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
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

/**
 * server.status params
 *
 * {
 *   "analysis": optional AnalysisStatus
 *   "pub": optional PubStatus
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ServerStatusParams implements HasToJson {
  AnalysisStatus _analysis;

  PubStatus _pub;

  /**
   * The current status of analysis, including whether analysis is being
   * performed and if so what is being analyzed.
   */
  AnalysisStatus get analysis => _analysis;

  /**
   * The current status of analysis, including whether analysis is being
   * performed and if so what is being analyzed.
   */
  void set analysis(AnalysisStatus value) {
    this._analysis = value;
  }

  /**
   * The current status of pub execution, indicating whether we are currently
   * running pub.
   */
  PubStatus get pub => _pub;

  /**
   * The current status of pub execution, indicating whether we are currently
   * running pub.
   */
  void set pub(PubStatus value) {
    this._pub = value;
  }

  ServerStatusParams({AnalysisStatus analysis, PubStatus pub}) {
    this.analysis = analysis;
    this.pub = pub;
  }

  factory ServerStatusParams.fromJson(
      JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisStatus analysis;
      if (json.containsKey("analysis")) {
        analysis = new AnalysisStatus.fromJson(
            jsonDecoder, jsonPath + ".analysis", json["analysis"]);
      }
      PubStatus pub;
      if (json.containsKey("pub")) {
        pub =
            new PubStatus.fromJson(jsonDecoder, jsonPath + ".pub", json["pub"]);
      }
      return new ServerStatusParams(analysis: analysis, pub: pub);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.status params", json);
    }
  }

  factory ServerStatusParams.fromNotification(Notification notification) {
    return new ServerStatusParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (analysis != null) {
      result["analysis"] = analysis.toJson();
    }
    if (pub != null) {
      result["pub"] = pub.toJson();
    }
    return result;
  }

  Notification toNotification() {
    return new Notification("server.status", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator ==(other) {
    if (other is ServerStatusParams) {
      return analysis == other.analysis && pub == other.pub;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, analysis.hashCode);
    hash = JenkinsSmiHash.combine(hash, pub.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * TypeHierarchyItem
 *
 * {
 *   "classElement": Element
 *   "displayName": optional String
 *   "memberElement": optional Element
 *   "superclass": optional int
 *   "interfaces": List<int>
 *   "mixins": List<int>
 *   "subclasses": List<int>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class TypeHierarchyItem implements HasToJson {
  Element _classElement;

  String _displayName;

  Element _memberElement;

  int _superclass;

  List<int> _interfaces;

  List<int> _mixins;

  List<int> _subclasses;

  /**
   * The class element represented by this item.
   */
  Element get classElement => _classElement;

  /**
   * The class element represented by this item.
   */
  void set classElement(Element value) {
    assert(value != null);
    this._classElement = value;
  }

  /**
   * The name to be displayed for the class. This field will be omitted if the
   * display name is the same as the name of the element. The display name is
   * different if there is additional type information to be displayed, such as
   * type arguments.
   */
  String get displayName => _displayName;

  /**
   * The name to be displayed for the class. This field will be omitted if the
   * display name is the same as the name of the element. The display name is
   * different if there is additional type information to be displayed, such as
   * type arguments.
   */
  void set displayName(String value) {
    this._displayName = value;
  }

  /**
   * The member in the class corresponding to the member on which the hierarchy
   * was requested. This field will be omitted if the hierarchy was not
   * requested for a member or if the class does not have a corresponding
   * member.
   */
  Element get memberElement => _memberElement;

  /**
   * The member in the class corresponding to the member on which the hierarchy
   * was requested. This field will be omitted if the hierarchy was not
   * requested for a member or if the class does not have a corresponding
   * member.
   */
  void set memberElement(Element value) {
    this._memberElement = value;
  }

  /**
   * The index of the item representing the superclass of this class. This
   * field will be omitted if this item represents the class Object.
   */
  int get superclass => _superclass;

  /**
   * The index of the item representing the superclass of this class. This
   * field will be omitted if this item represents the class Object.
   */
  void set superclass(int value) {
    this._superclass = value;
  }

  /**
   * The indexes of the items representing the interfaces implemented by this
   * class. The list will be empty if there are no implemented interfaces.
   */
  List<int> get interfaces => _interfaces;

  /**
   * The indexes of the items representing the interfaces implemented by this
   * class. The list will be empty if there are no implemented interfaces.
   */
  void set interfaces(List<int> value) {
    assert(value != null);
    this._interfaces = value;
  }

  /**
   * The indexes of the items representing the mixins referenced by this class.
   * The list will be empty if there are no classes mixed in to this class.
   */
  List<int> get mixins => _mixins;

  /**
   * The indexes of the items representing the mixins referenced by this class.
   * The list will be empty if there are no classes mixed in to this class.
   */
  void set mixins(List<int> value) {
    assert(value != null);
    this._mixins = value;
  }

  /**
   * The indexes of the items representing the subtypes of this class. The list
   * will be empty if there are no subtypes or if this item represents a
   * supertype of the pivot type.
   */
  List<int> get subclasses => _subclasses;

  /**
   * The indexes of the items representing the subtypes of this class. The list
   * will be empty if there are no subtypes or if this item represents a
   * supertype of the pivot type.
   */
  void set subclasses(List<int> value) {
    assert(value != null);
    this._subclasses = value;
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
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element classElement;
      if (json.containsKey("classElement")) {
        classElement = new Element.fromJson(
            jsonDecoder, jsonPath + ".classElement", json["classElement"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "classElement");
      }
      String displayName;
      if (json.containsKey("displayName")) {
        displayName = jsonDecoder.decodeString(
            jsonPath + ".displayName", json["displayName"]);
      }
      Element memberElement;
      if (json.containsKey("memberElement")) {
        memberElement = new Element.fromJson(
            jsonDecoder, jsonPath + ".memberElement", json["memberElement"]);
      }
      int superclass;
      if (json.containsKey("superclass")) {
        superclass =
            jsonDecoder.decodeInt(jsonPath + ".superclass", json["superclass"]);
      }
      List<int> interfaces;
      if (json.containsKey("interfaces")) {
        interfaces = jsonDecoder.decodeList(jsonPath + ".interfaces",
            json["interfaces"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "interfaces");
      }
      List<int> mixins;
      if (json.containsKey("mixins")) {
        mixins = jsonDecoder.decodeList(
            jsonPath + ".mixins", json["mixins"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "mixins");
      }
      List<int> subclasses;
      if (json.containsKey("subclasses")) {
        subclasses = jsonDecoder.decodeList(jsonPath + ".subclasses",
            json["subclasses"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "subclasses");
      }
      return new TypeHierarchyItem(classElement,
          displayName: displayName,
          memberElement: memberElement,
          superclass: superclass,
          interfaces: interfaces,
          mixins: mixins,
          subclasses: subclasses);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "TypeHierarchyItem", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["classElement"] = classElement.toJson();
    if (displayName != null) {
      result["displayName"] = displayName;
    }
    if (memberElement != null) {
      result["memberElement"] = memberElement.toJson();
    }
    if (superclass != null) {
      result["superclass"] = superclass;
    }
    result["interfaces"] = interfaces;
    result["mixins"] = mixins;
    result["subclasses"] = subclasses;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

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
    int hash = 0;
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
