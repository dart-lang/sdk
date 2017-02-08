// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:convert' hide JsonDecoder;

import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';

/**
 * AddContentOverlay
 *
 * {
 *   "type": "add"
 *   "content": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AddContentOverlay implements HasToJson {
  String _content;

  /**
   * The new content of the file.
   */
  String get content => _content;

  /**
   * The new content of the file.
   */
  void set content(String value) {
    assert(value != null);
    this._content = value;
  }

  AddContentOverlay(String content) {
    this.content = content;
  }

  factory AddContentOverlay.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      if (json["type"] != "add") {
        throw jsonDecoder.mismatch(jsonPath, "equal " + "add", json);
      }
      String content;
      if (json.containsKey("content")) {
        content = jsonDecoder.decodeString(jsonPath + ".content", json["content"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "content");
      }
      return new AddContentOverlay(content);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AddContentOverlay", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["type"] = "add";
    result["content"] = content;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AddContentOverlay) {
      return content == other.content;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, 704418402);
    hash = JenkinsSmiHash.combine(hash, content.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * AnalysisError
 *
 * {
 *   "severity": AnalysisErrorSeverity
 *   "type": AnalysisErrorType
 *   "location": Location
 *   "message": String
 *   "correction": optional String
 *   "code": String
 *   "hasFix": optional bool
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisError implements HasToJson {
  AnalysisErrorSeverity _severity;

  AnalysisErrorType _type;

  Location _location;

  String _message;

  String _correction;

  String _code;

  bool _hasFix;

  /**
   * The severity of the error.
   */
  AnalysisErrorSeverity get severity => _severity;

  /**
   * The severity of the error.
   */
  void set severity(AnalysisErrorSeverity value) {
    assert(value != null);
    this._severity = value;
  }

  /**
   * The type of the error.
   */
  AnalysisErrorType get type => _type;

  /**
   * The type of the error.
   */
  void set type(AnalysisErrorType value) {
    assert(value != null);
    this._type = value;
  }

  /**
   * The location associated with the error.
   */
  Location get location => _location;

  /**
   * The location associated with the error.
   */
  void set location(Location value) {
    assert(value != null);
    this._location = value;
  }

  /**
   * The message to be displayed for this error. The message should indicate
   * what is wrong with the code and why it is wrong.
   */
  String get message => _message;

  /**
   * The message to be displayed for this error. The message should indicate
   * what is wrong with the code and why it is wrong.
   */
  void set message(String value) {
    assert(value != null);
    this._message = value;
  }

  /**
   * The correction message to be displayed for this error. The correction
   * message should indicate how the user can fix the error. The field is
   * omitted if there is no correction message associated with the error code.
   */
  String get correction => _correction;

  /**
   * The correction message to be displayed for this error. The correction
   * message should indicate how the user can fix the error. The field is
   * omitted if there is no correction message associated with the error code.
   */
  void set correction(String value) {
    this._correction = value;
  }

  /**
   * The name, as a string, of the error code associated with this error.
   */
  String get code => _code;

  /**
   * The name, as a string, of the error code associated with this error.
   */
  void set code(String value) {
    assert(value != null);
    this._code = value;
  }

  /**
   * A hint to indicate to interested clients that this error has an associated
   * fix (or fixes). The absence of this field implies there are not known to
   * be fixes. Note that since the operation to calculate whether fixes apply
   * needs to be performant it is possible that complicated tests will be
   * skipped and a false negative returned. For this reason, this attribute
   * should be treated as a "hint". Despite the possibility of false negatives,
   * no false positives should be returned. If a client sees this flag set they
   * can proceed with the confidence that there are in fact associated fixes.
   */
  bool get hasFix => _hasFix;

  /**
   * A hint to indicate to interested clients that this error has an associated
   * fix (or fixes). The absence of this field implies there are not known to
   * be fixes. Note that since the operation to calculate whether fixes apply
   * needs to be performant it is possible that complicated tests will be
   * skipped and a false negative returned. For this reason, this attribute
   * should be treated as a "hint". Despite the possibility of false negatives,
   * no false positives should be returned. If a client sees this flag set they
   * can proceed with the confidence that there are in fact associated fixes.
   */
  void set hasFix(bool value) {
    this._hasFix = value;
  }

  AnalysisError(AnalysisErrorSeverity severity, AnalysisErrorType type, Location location, String message, String code, {String correction, bool hasFix}) {
    this.severity = severity;
    this.type = type;
    this.location = location;
    this.message = message;
    this.correction = correction;
    this.code = code;
    this.hasFix = hasFix;
  }

  factory AnalysisError.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisErrorSeverity severity;
      if (json.containsKey("severity")) {
        severity = new AnalysisErrorSeverity.fromJson(jsonDecoder, jsonPath + ".severity", json["severity"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "severity");
      }
      AnalysisErrorType type;
      if (json.containsKey("type")) {
        type = new AnalysisErrorType.fromJson(jsonDecoder, jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "type");
      }
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "location");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      String correction;
      if (json.containsKey("correction")) {
        correction = jsonDecoder.decodeString(jsonPath + ".correction", json["correction"]);
      }
      String code;
      if (json.containsKey("code")) {
        code = jsonDecoder.decodeString(jsonPath + ".code", json["code"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "code");
      }
      bool hasFix;
      if (json.containsKey("hasFix")) {
        hasFix = jsonDecoder.decodeBool(jsonPath + ".hasFix", json["hasFix"]);
      }
      return new AnalysisError(severity, type, location, message, code, correction: correction, hasFix: hasFix);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisError", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["severity"] = severity.toJson();
    result["type"] = type.toJson();
    result["location"] = location.toJson();
    result["message"] = message;
    if (correction != null) {
      result["correction"] = correction;
    }
    result["code"] = code;
    if (hasFix != null) {
      result["hasFix"] = hasFix;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisError) {
      return severity == other.severity &&
          type == other.type &&
          location == other.location &&
          message == other.message &&
          correction == other.correction &&
          code == other.code &&
          hasFix == other.hasFix;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, correction.hashCode);
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, hasFix.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * AnalysisErrorFixes
 *
 * {
 *   "error": AnalysisError
 *   "fixes": List<PrioritizedSourceChange>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisErrorFixes implements HasToJson {
  AnalysisError _error;

  List<PrioritizedSourceChange> _fixes;

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
  List<PrioritizedSourceChange> get fixes => _fixes;

  /**
   * The fixes associated with the error.
   */
  void set fixes(List<PrioritizedSourceChange> value) {
    assert(value != null);
    this._fixes = value;
  }

  AnalysisErrorFixes(AnalysisError error, {List<PrioritizedSourceChange> fixes}) {
    this.error = error;
    if (fixes == null) {
      this.fixes = <PrioritizedSourceChange>[];
    } else {
      this.fixes = fixes;
    }
  }

  factory AnalysisErrorFixes.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisError error;
      if (json.containsKey("error")) {
        error = new AnalysisError.fromJson(jsonDecoder, jsonPath + ".error", json["error"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "error");
      }
      List<PrioritizedSourceChange> fixes;
      if (json.containsKey("fixes")) {
        fixes = jsonDecoder.decodeList(jsonPath + ".fixes", json["fixes"], (String jsonPath, Object json) => new PrioritizedSourceChange.fromJson(jsonDecoder, jsonPath, json));
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
    result["fixes"] = fixes.map((PrioritizedSourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisErrorFixes) {
      return error == other.error &&
          listEqual(fixes, other.fixes, (PrioritizedSourceChange a, PrioritizedSourceChange b) => a == b);
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
 * AnalysisErrorSeverity
 *
 * enum {
 *   INFO
 *   WARNING
 *   ERROR
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisErrorSeverity implements Enum {
  static const AnalysisErrorSeverity INFO = const AnalysisErrorSeverity._("INFO");

  static const AnalysisErrorSeverity WARNING = const AnalysisErrorSeverity._("WARNING");

  static const AnalysisErrorSeverity ERROR = const AnalysisErrorSeverity._("ERROR");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisErrorSeverity> VALUES = const <AnalysisErrorSeverity>[INFO, WARNING, ERROR];

  @override
  final String name;

  const AnalysisErrorSeverity._(this.name);

  factory AnalysisErrorSeverity(String name) {
    switch (name) {
      case "INFO":
        return INFO;
      case "WARNING":
        return WARNING;
      case "ERROR":
        return ERROR;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory AnalysisErrorSeverity.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new AnalysisErrorSeverity(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorSeverity", json);
  }

  @override
  String toString() => "AnalysisErrorSeverity.$name";

  String toJson() => name;
}

/**
 * AnalysisErrorType
 *
 * enum {
 *   CHECKED_MODE_COMPILE_TIME_ERROR
 *   COMPILE_TIME_ERROR
 *   HINT
 *   LINT
 *   STATIC_TYPE_WARNING
 *   STATIC_WARNING
 *   SYNTACTIC_ERROR
 *   TODO
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisErrorType implements Enum {
  static const AnalysisErrorType CHECKED_MODE_COMPILE_TIME_ERROR = const AnalysisErrorType._("CHECKED_MODE_COMPILE_TIME_ERROR");

  static const AnalysisErrorType COMPILE_TIME_ERROR = const AnalysisErrorType._("COMPILE_TIME_ERROR");

  static const AnalysisErrorType HINT = const AnalysisErrorType._("HINT");

  static const AnalysisErrorType LINT = const AnalysisErrorType._("LINT");

  static const AnalysisErrorType STATIC_TYPE_WARNING = const AnalysisErrorType._("STATIC_TYPE_WARNING");

  static const AnalysisErrorType STATIC_WARNING = const AnalysisErrorType._("STATIC_WARNING");

  static const AnalysisErrorType SYNTACTIC_ERROR = const AnalysisErrorType._("SYNTACTIC_ERROR");

  static const AnalysisErrorType TODO = const AnalysisErrorType._("TODO");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisErrorType> VALUES = const <AnalysisErrorType>[CHECKED_MODE_COMPILE_TIME_ERROR, COMPILE_TIME_ERROR, HINT, LINT, STATIC_TYPE_WARNING, STATIC_WARNING, SYNTACTIC_ERROR, TODO];

  @override
  final String name;

  const AnalysisErrorType._(this.name);

  factory AnalysisErrorType(String name) {
    switch (name) {
      case "CHECKED_MODE_COMPILE_TIME_ERROR":
        return CHECKED_MODE_COMPILE_TIME_ERROR;
      case "COMPILE_TIME_ERROR":
        return COMPILE_TIME_ERROR;
      case "HINT":
        return HINT;
      case "LINT":
        return LINT;
      case "STATIC_TYPE_WARNING":
        return STATIC_TYPE_WARNING;
      case "STATIC_WARNING":
        return STATIC_WARNING;
      case "SYNTACTIC_ERROR":
        return SYNTACTIC_ERROR;
      case "TODO":
        return TODO;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory AnalysisErrorType.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new AnalysisErrorType(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorType", json);
  }

  @override
  String toString() => "AnalysisErrorType.$name";

  String toJson() => name;
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

  factory AnalysisErrorsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        errors = jsonDecoder.decodeList(jsonPath + ".errors", json["errors"], (String jsonPath, Object json) => new AnalysisError.fromJson(jsonDecoder, jsonPath, json));
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
    result["errors"] = errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.errors", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisErrorsParams) {
      return file == other.file &&
          listEqual(errors, other.errors, (AnalysisError a, AnalysisError b) => a == b);
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

  factory AnalysisFoldingParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        regions = jsonDecoder.decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new FoldingRegion.fromJson(jsonDecoder, jsonPath, json));
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
    result["regions"] = regions.map((FoldingRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.folding", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisFoldingParams) {
      return file == other.file &&
          listEqual(regions, other.regions, (FoldingRegion a, FoldingRegion b) => a == b);
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
 * analysis.handleWatchEvents params
 *
 * {
 *   "events": List<WatchEvent>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisHandleWatchEventsParams implements RequestParams {
  List<WatchEvent> _events;

  /**
   * The watch events that the plugin should handle.
   */
  List<WatchEvent> get events => _events;

  /**
   * The watch events that the plugin should handle.
   */
  void set events(List<WatchEvent> value) {
    assert(value != null);
    this._events = value;
  }

  AnalysisHandleWatchEventsParams(List<WatchEvent> events) {
    this.events = events;
  }

  factory AnalysisHandleWatchEventsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<WatchEvent> events;
      if (json.containsKey("events")) {
        events = jsonDecoder.decodeList(jsonPath + ".events", json["events"], (String jsonPath, Object json) => new WatchEvent.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "events");
      }
      return new AnalysisHandleWatchEventsParams(events);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.handleWatchEvents params", json);
    }
  }

  factory AnalysisHandleWatchEventsParams.fromRequest(Request request) {
    return new AnalysisHandleWatchEventsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["events"] = events.map((WatchEvent value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.handleWatchEvents", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisHandleWatchEventsParams) {
      return listEqual(events, other.events, (WatchEvent a, WatchEvent b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, events.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.handleWatchEvents result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisHandleWatchEventsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
    if (other is AnalysisHandleWatchEventsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 779767607;
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
   * The highlight regions contained in the file.
   */
  List<HighlightRegion> get regions => _regions;

  /**
   * The highlight regions contained in the file.
   */
  void set regions(List<HighlightRegion> value) {
    assert(value != null);
    this._regions = value;
  }

  AnalysisHighlightsParams(String file, List<HighlightRegion> regions) {
    this.file = file;
    this.regions = regions;
  }

  factory AnalysisHighlightsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        regions = jsonDecoder.decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new HighlightRegion.fromJson(jsonDecoder, jsonPath, json));
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
    result["regions"] = regions.map((HighlightRegion value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.highlights", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisHighlightsParams) {
      return file == other.file &&
          listEqual(regions, other.regions, (HighlightRegion a, HighlightRegion b) => a == b);
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
   * The navigation regions contained in the file.
   */
  List<NavigationRegion> get regions => _regions;

  /**
   * The navigation regions contained in the file.
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

  AnalysisNavigationParams(String file, List<NavigationRegion> regions, List<NavigationTarget> targets, List<String> files) {
    this.file = file;
    this.regions = regions;
    this.targets = targets;
    this.files = files;
  }

  factory AnalysisNavigationParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        regions = jsonDecoder.decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "regions");
      }
      List<NavigationTarget> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder.decodeList(jsonPath + ".targets", json["targets"], (String jsonPath, Object json) => new NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "targets");
      }
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(jsonPath + ".files", json["files"], jsonDecoder.decodeString);
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
    result["regions"] = regions.map((NavigationRegion value) => value.toJson()).toList();
    result["targets"] = targets.map((NavigationTarget value) => value.toJson()).toList();
    result["files"] = files;
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.navigation", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisNavigationParams) {
      return file == other.file &&
          listEqual(regions, other.regions, (NavigationRegion a, NavigationRegion b) => a == b) &&
          listEqual(targets, other.targets, (NavigationTarget a, NavigationTarget b) => a == b) &&
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

  factory AnalysisOccurrencesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        occurrences = jsonDecoder.decodeList(jsonPath + ".occurrences", json["occurrences"], (String jsonPath, Object json) => new Occurrences.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "occurrences");
      }
      return new AnalysisOccurrencesParams(file, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.occurrences params", json);
    }
  }

  factory AnalysisOccurrencesParams.fromNotification(Notification notification) {
    return new AnalysisOccurrencesParams.fromJson(
        new ResponseDecoder(null), "params", notification.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["occurrences"] = occurrences.map((Occurrences value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.occurrences", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisOccurrencesParams) {
      return file == other.file &&
          listEqual(occurrences, other.occurrences, (Occurrences a, Occurrences b) => a == b);
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
 * analysis.outline params
 *
 * {
 *   "file": FilePath
 *   "outline": List<Outline>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisOutlineParams implements HasToJson {
  String _file;

  List<Outline> _outline;

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
   * The outline fragments associated with the file.
   */
  List<Outline> get outline => _outline;

  /**
   * The outline fragments associated with the file.
   */
  void set outline(List<Outline> value) {
    assert(value != null);
    this._outline = value;
  }

  AnalysisOutlineParams(String file, List<Outline> outline) {
    this.file = file;
    this.outline = outline;
  }

  factory AnalysisOutlineParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      List<Outline> outline;
      if (json.containsKey("outline")) {
        outline = jsonDecoder.decodeList(jsonPath + ".outline", json["outline"], (String jsonPath, Object json) => new Outline.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "outline");
      }
      return new AnalysisOutlineParams(file, outline);
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
    result["outline"] = outline.map((Outline value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.outline", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisOutlineParams) {
      return file == other.file &&
          listEqual(outline, other.outline, (Outline a, Outline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, outline.hashCode);
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
   * A list of the context roots that are to be re-analyzed.
   *
   * If no context roots are provided, then all current context roots should be
   * re-analyzed.
   */
  List<String> get roots => _roots;

  /**
   * A list of the context roots that are to be re-analyzed.
   *
   * If no context roots are provided, then all current context roots should be
   * re-analyzed.
   */
  void set roots(List<String> value) {
    this._roots = value;
  }

  AnalysisReanalyzeParams({List<String> roots}) {
    this.roots = roots;
  }

  factory AnalysisReanalyzeParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> roots;
      if (json.containsKey("roots")) {
        roots = jsonDecoder.decodeList(jsonPath + ".roots", json["roots"], jsonDecoder.decodeString);
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
  bool operator==(other) {
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
  bool operator==(other) {
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
 *   FOLDING
 *   HIGHLIGHTS
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisService implements Enum {
  static const AnalysisService FOLDING = const AnalysisService._("FOLDING");

  static const AnalysisService HIGHLIGHTS = const AnalysisService._("HIGHLIGHTS");

  static const AnalysisService NAVIGATION = const AnalysisService._("NAVIGATION");

  static const AnalysisService OCCURRENCES = const AnalysisService._("OCCURRENCES");

  static const AnalysisService OUTLINE = const AnalysisService._("OUTLINE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisService> VALUES = const <AnalysisService>[FOLDING, HIGHLIGHTS, NAVIGATION, OCCURRENCES, OUTLINE];

  @override
  final String name;

  const AnalysisService._(this.name);

  factory AnalysisService(String name) {
    switch (name) {
      case "FOLDING":
        return FOLDING;
      case "HIGHLIGHTS":
        return HIGHLIGHTS;
      case "NAVIGATION":
        return NAVIGATION;
      case "OCCURRENCES":
        return OCCURRENCES;
      case "OUTLINE":
        return OUTLINE;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory AnalysisService.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new AnalysisService(json);
      } catch(_) {
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
 * analysis.setContextBuilderOptions params
 *
 * {
 *   "options": ContextBuilderOptions
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetContextBuilderOptionsParams implements RequestParams {
  ContextBuilderOptions _options;

  /**
   * The options used to build the analysis contexts.
   */
  ContextBuilderOptions get options => _options;

  /**
   * The options used to build the analysis contexts.
   */
  void set options(ContextBuilderOptions value) {
    assert(value != null);
    this._options = value;
  }

  AnalysisSetContextBuilderOptionsParams(ContextBuilderOptions options) {
    this.options = options;
  }

  factory AnalysisSetContextBuilderOptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      ContextBuilderOptions options;
      if (json.containsKey("options")) {
        options = new ContextBuilderOptions.fromJson(jsonDecoder, jsonPath + ".options", json["options"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "options");
      }
      return new AnalysisSetContextBuilderOptionsParams(options);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setContextBuilderOptions params", json);
    }
  }

  factory AnalysisSetContextBuilderOptionsParams.fromRequest(Request request) {
    return new AnalysisSetContextBuilderOptionsParams.fromJson(
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
    return new Request(id, "analysis.setContextBuilderOptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetContextBuilderOptionsParams) {
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
 * analysis.setContextBuilderOptions result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetContextBuilderOptionsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
    if (other is AnalysisSetContextBuilderOptionsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 645412314;
  }
}

/**
 * analysis.setContextRoots params
 *
 * {
 *   "roots": List<ContextRoot>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetContextRootsParams implements RequestParams {
  List<ContextRoot> _roots;

  /**
   * A list of the context roots that should be analyzed.
   */
  List<ContextRoot> get roots => _roots;

  /**
   * A list of the context roots that should be analyzed.
   */
  void set roots(List<ContextRoot> value) {
    assert(value != null);
    this._roots = value;
  }

  AnalysisSetContextRootsParams(List<ContextRoot> roots) {
    this.roots = roots;
  }

  factory AnalysisSetContextRootsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ContextRoot> roots;
      if (json.containsKey("roots")) {
        roots = jsonDecoder.decodeList(jsonPath + ".roots", json["roots"], (String jsonPath, Object json) => new ContextRoot.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "roots");
      }
      return new AnalysisSetContextRootsParams(roots);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setContextRoots params", json);
    }
  }

  factory AnalysisSetContextRootsParams.fromRequest(Request request) {
    return new AnalysisSetContextRootsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["roots"] = roots.map((ContextRoot value) => value.toJson()).toList();
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.setContextRoots", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetContextRootsParams) {
      return listEqual(roots, other.roots, (ContextRoot a, ContextRoot b) => a == b);
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
 * analysis.setContextRoots result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisSetContextRootsResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
    if (other is AnalysisSetContextRootsResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 969645618;
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

  factory AnalysisSetPriorityFilesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeList(jsonPath + ".files", json["files"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setPriorityFiles params", json);
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
  bool operator==(other) {
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
  bool operator==(other) {
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

  AnalysisSetSubscriptionsParams(Map<AnalysisService, List<String>> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory AnalysisSetSubscriptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<AnalysisService, List<String>> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder.decodeMap(jsonPath + ".subscriptions", json["subscriptions"], keyDecoder: (String jsonPath, Object json) => new AnalysisService.fromJson(jsonDecoder, jsonPath, json), valueDecoder: (String jsonPath, Object json) => jsonDecoder.decodeList(jsonPath, json, jsonDecoder.decodeString));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "subscriptions");
      }
      return new AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setSubscriptions params", json);
    }
  }

  factory AnalysisSetSubscriptionsParams.fromRequest(Request request) {
    return new AnalysisSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = mapMap(subscriptions, keyCallback: (AnalysisService value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetSubscriptionsParams) {
      return mapEqual(subscriptions, other.subscriptions, (List<String> a, List<String> b) => listEqual(a, b, (String a, String b) => a == b));
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
  bool operator==(other) {
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

  factory AnalysisUpdateContentParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<String, dynamic> files;
      if (json.containsKey("files")) {
        files = jsonDecoder.decodeMap(jsonPath + ".files", json["files"], valueDecoder: (String jsonPath, Object json) => jsonDecoder.decodeUnion(jsonPath, json, "type", {"add": (String jsonPath, Object json) => new AddContentOverlay.fromJson(jsonDecoder, jsonPath, json), "change": (String jsonPath, Object json) => new ChangeContentOverlay.fromJson(jsonDecoder, jsonPath, json), "remove": (String jsonPath, Object json) => new RemoveContentOverlay.fromJson(jsonDecoder, jsonPath, json)}));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "files");
      }
      return new AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.updateContent params", json);
    }
  }

  factory AnalysisUpdateContentParams.fromRequest(Request request) {
    return new AnalysisUpdateContentParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = mapMap(files, valueCallback: (dynamic value) => value.toJson());
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "analysis.updateContent", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
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
 * Clients may not extend, implement or mix-in this class.
 */
class AnalysisUpdateContentResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
    if (other is AnalysisUpdateContentResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 468798730;
  }
}

/**
 * ChangeContentOverlay
 *
 * {
 *   "type": "change"
 *   "edits": List<SourceEdit>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ChangeContentOverlay implements HasToJson {
  List<SourceEdit> _edits;

  /**
   * The edits to be applied to the file.
   */
  List<SourceEdit> get edits => _edits;

  /**
   * The edits to be applied to the file.
   */
  void set edits(List<SourceEdit> value) {
    assert(value != null);
    this._edits = value;
  }

  ChangeContentOverlay(List<SourceEdit> edits) {
    this.edits = edits;
  }

  factory ChangeContentOverlay.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      if (json["type"] != "change") {
        throw jsonDecoder.mismatch(jsonPath, "equal " + "change", json);
      }
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder.decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edits");
      }
      return new ChangeContentOverlay(edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ChangeContentOverlay", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["type"] = "change";
    result["edits"] = edits.map((SourceEdit value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ChangeContentOverlay) {
      return listEqual(edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, 873118866);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
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

  factory CompletionGetSuggestionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      throw jsonDecoder.mismatch(jsonPath, "completion.getSuggestions params", json);
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
  bool operator==(other) {
    if (other is CompletionGetSuggestionsParams) {
      return file == other.file &&
          offset == other.offset;
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
 *   "replacementOffset": int
 *   "replacementLength": int
 *   "results": List<CompletionSuggestion>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionGetSuggestionsResult implements ResponseResult {
  int _replacementOffset;

  int _replacementLength;

  List<CompletionSuggestion> _results;

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

  CompletionGetSuggestionsResult(int replacementOffset, int replacementLength, List<CompletionSuggestion> results) {
    this.replacementOffset = replacementOffset;
    this.replacementLength = replacementLength;
    this.results = results;
  }

  factory CompletionGetSuggestionsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int replacementOffset;
      if (json.containsKey("replacementOffset")) {
        replacementOffset = jsonDecoder.decodeInt(jsonPath + ".replacementOffset", json["replacementOffset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "replacementOffset");
      }
      int replacementLength;
      if (json.containsKey("replacementLength")) {
        replacementLength = jsonDecoder.decodeInt(jsonPath + ".replacementLength", json["replacementLength"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "replacementLength");
      }
      List<CompletionSuggestion> results;
      if (json.containsKey("results")) {
        results = jsonDecoder.decodeList(jsonPath + ".results", json["results"], (String jsonPath, Object json) => new CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "results");
      }
      return new CompletionGetSuggestionsResult(replacementOffset, replacementLength, results);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "completion.getSuggestions result", json);
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(Response response) {
    return new CompletionGetSuggestionsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["replacementOffset"] = replacementOffset;
    result["replacementLength"] = replacementLength;
    result["results"] = results.map((CompletionSuggestion value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is CompletionGetSuggestionsResult) {
      return replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          listEqual(results, other.results, (CompletionSuggestion a, CompletionSuggestion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, replacementOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacementLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, results.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * CompletionSuggestion
 *
 * {
 *   "kind": CompletionSuggestionKind
 *   "relevance": int
 *   "completion": String
 *   "selectionOffset": int
 *   "selectionLength": int
 *   "isDeprecated": bool
 *   "isPotential": bool
 *   "docSummary": optional String
 *   "docComplete": optional String
 *   "declaringType": optional String
 *   "element": optional Element
 *   "returnType": optional String
 *   "parameterNames": optional List<String>
 *   "parameterTypes": optional List<String>
 *   "requiredParameterCount": optional int
 *   "hasNamedParameters": optional bool
 *   "parameterName": optional String
 *   "parameterType": optional String
 *   "importUri": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionSuggestion implements HasToJson {
  CompletionSuggestionKind _kind;

  int _relevance;

  String _completion;

  int _selectionOffset;

  int _selectionLength;

  bool _isDeprecated;

  bool _isPotential;

  String _docSummary;

  String _docComplete;

  String _declaringType;

  Element _element;

  String _returnType;

  List<String> _parameterNames;

  List<String> _parameterTypes;

  int _requiredParameterCount;

  bool _hasNamedParameters;

  String _parameterName;

  String _parameterType;

  String _importUri;

  /**
   * The kind of element being suggested.
   */
  CompletionSuggestionKind get kind => _kind;

  /**
   * The kind of element being suggested.
   */
  void set kind(CompletionSuggestionKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The relevance of this completion suggestion where a higher number
   * indicates a higher relevance.
   */
  int get relevance => _relevance;

  /**
   * The relevance of this completion suggestion where a higher number
   * indicates a higher relevance.
   */
  void set relevance(int value) {
    assert(value != null);
    this._relevance = value;
  }

  /**
   * The identifier to be inserted if the suggestion is selected. If the
   * suggestion is for a method or function, the client might want to
   * additionally insert a template for the parameters. The information
   * required in order to do so is contained in other fields.
   */
  String get completion => _completion;

  /**
   * The identifier to be inserted if the suggestion is selected. If the
   * suggestion is for a method or function, the client might want to
   * additionally insert a template for the parameters. The information
   * required in order to do so is contained in other fields.
   */
  void set completion(String value) {
    assert(value != null);
    this._completion = value;
  }

  /**
   * The offset, relative to the beginning of the completion, of where the
   * selection should be placed after insertion.
   */
  int get selectionOffset => _selectionOffset;

  /**
   * The offset, relative to the beginning of the completion, of where the
   * selection should be placed after insertion.
   */
  void set selectionOffset(int value) {
    assert(value != null);
    this._selectionOffset = value;
  }

  /**
   * The number of characters that should be selected after insertion.
   */
  int get selectionLength => _selectionLength;

  /**
   * The number of characters that should be selected after insertion.
   */
  void set selectionLength(int value) {
    assert(value != null);
    this._selectionLength = value;
  }

  /**
   * True if the suggested element is deprecated.
   */
  bool get isDeprecated => _isDeprecated;

  /**
   * True if the suggested element is deprecated.
   */
  void set isDeprecated(bool value) {
    assert(value != null);
    this._isDeprecated = value;
  }

  /**
   * True if the element is not known to be valid for the target. This happens
   * if the type of the target is dynamic.
   */
  bool get isPotential => _isPotential;

  /**
   * True if the element is not known to be valid for the target. This happens
   * if the type of the target is dynamic.
   */
  void set isPotential(bool value) {
    assert(value != null);
    this._isPotential = value;
  }

  /**
   * An abbreviated version of the Dartdoc associated with the element being
   * suggested, This field is omitted if there is no Dartdoc associated with
   * the element.
   */
  String get docSummary => _docSummary;

  /**
   * An abbreviated version of the Dartdoc associated with the element being
   * suggested, This field is omitted if there is no Dartdoc associated with
   * the element.
   */
  void set docSummary(String value) {
    this._docSummary = value;
  }

  /**
   * The Dartdoc associated with the element being suggested. This field is
   * omitted if there is no Dartdoc associated with the element.
   */
  String get docComplete => _docComplete;

  /**
   * The Dartdoc associated with the element being suggested. This field is
   * omitted if there is no Dartdoc associated with the element.
   */
  void set docComplete(String value) {
    this._docComplete = value;
  }

  /**
   * The class that declares the element being suggested. This field is omitted
   * if the suggested element is not a member of a class.
   */
  String get declaringType => _declaringType;

  /**
   * The class that declares the element being suggested. This field is omitted
   * if the suggested element is not a member of a class.
   */
  void set declaringType(String value) {
    this._declaringType = value;
  }

  /**
   * Information about the element reference being suggested.
   */
  Element get element => _element;

  /**
   * Information about the element reference being suggested.
   */
  void set element(Element value) {
    this._element = value;
  }

  /**
   * The return type of the getter, function or method or the type of the field
   * being suggested. This field is omitted if the suggested element is not a
   * getter, function or method.
   */
  String get returnType => _returnType;

  /**
   * The return type of the getter, function or method or the type of the field
   * being suggested. This field is omitted if the suggested element is not a
   * getter, function or method.
   */
  void set returnType(String value) {
    this._returnType = value;
  }

  /**
   * The names of the parameters of the function or method being suggested.
   * This field is omitted if the suggested element is not a setter, function
   * or method.
   */
  List<String> get parameterNames => _parameterNames;

  /**
   * The names of the parameters of the function or method being suggested.
   * This field is omitted if the suggested element is not a setter, function
   * or method.
   */
  void set parameterNames(List<String> value) {
    this._parameterNames = value;
  }

  /**
   * The types of the parameters of the function or method being suggested.
   * This field is omitted if the parameterNames field is omitted.
   */
  List<String> get parameterTypes => _parameterTypes;

  /**
   * The types of the parameters of the function or method being suggested.
   * This field is omitted if the parameterNames field is omitted.
   */
  void set parameterTypes(List<String> value) {
    this._parameterTypes = value;
  }

  /**
   * The number of required parameters for the function or method being
   * suggested. This field is omitted if the parameterNames field is omitted.
   */
  int get requiredParameterCount => _requiredParameterCount;

  /**
   * The number of required parameters for the function or method being
   * suggested. This field is omitted if the parameterNames field is omitted.
   */
  void set requiredParameterCount(int value) {
    this._requiredParameterCount = value;
  }

  /**
   * True if the function or method being suggested has at least one named
   * parameter. This field is omitted if the parameterNames field is omitted.
   */
  bool get hasNamedParameters => _hasNamedParameters;

  /**
   * True if the function or method being suggested has at least one named
   * parameter. This field is omitted if the parameterNames field is omitted.
   */
  void set hasNamedParameters(bool value) {
    this._hasNamedParameters = value;
  }

  /**
   * The name of the optional parameter being suggested. This field is omitted
   * if the suggestion is not the addition of an optional argument within an
   * argument list.
   */
  String get parameterName => _parameterName;

  /**
   * The name of the optional parameter being suggested. This field is omitted
   * if the suggestion is not the addition of an optional argument within an
   * argument list.
   */
  void set parameterName(String value) {
    this._parameterName = value;
  }

  /**
   * The type of the options parameter being suggested. This field is omitted
   * if the parameterName field is omitted.
   */
  String get parameterType => _parameterType;

  /**
   * The type of the options parameter being suggested. This field is omitted
   * if the parameterName field is omitted.
   */
  void set parameterType(String value) {
    this._parameterType = value;
  }

  /**
   * The import to be added if the suggestion is out of scope and needs an
   * import to be added to be in scope.
   */
  String get importUri => _importUri;

  /**
   * The import to be added if the suggestion is out of scope and needs an
   * import to be added to be in scope.
   */
  void set importUri(String value) {
    this._importUri = value;
  }

  CompletionSuggestion(CompletionSuggestionKind kind, int relevance, String completion, int selectionOffset, int selectionLength, bool isDeprecated, bool isPotential, {String docSummary, String docComplete, String declaringType, Element element, String returnType, List<String> parameterNames, List<String> parameterTypes, int requiredParameterCount, bool hasNamedParameters, String parameterName, String parameterType, String importUri}) {
    this.kind = kind;
    this.relevance = relevance;
    this.completion = completion;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
    this.isDeprecated = isDeprecated;
    this.isPotential = isPotential;
    this.docSummary = docSummary;
    this.docComplete = docComplete;
    this.declaringType = declaringType;
    this.element = element;
    this.returnType = returnType;
    this.parameterNames = parameterNames;
    this.parameterTypes = parameterTypes;
    this.requiredParameterCount = requiredParameterCount;
    this.hasNamedParameters = hasNamedParameters;
    this.parameterName = parameterName;
    this.parameterType = parameterType;
    this.importUri = importUri;
  }

  factory CompletionSuggestion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      CompletionSuggestionKind kind;
      if (json.containsKey("kind")) {
        kind = new CompletionSuggestionKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      int relevance;
      if (json.containsKey("relevance")) {
        relevance = jsonDecoder.decodeInt(jsonPath + ".relevance", json["relevance"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "relevance");
      }
      String completion;
      if (json.containsKey("completion")) {
        completion = jsonDecoder.decodeString(jsonPath + ".completion", json["completion"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "completion");
      }
      int selectionOffset;
      if (json.containsKey("selectionOffset")) {
        selectionOffset = jsonDecoder.decodeInt(jsonPath + ".selectionOffset", json["selectionOffset"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "selectionOffset");
      }
      int selectionLength;
      if (json.containsKey("selectionLength")) {
        selectionLength = jsonDecoder.decodeInt(jsonPath + ".selectionLength", json["selectionLength"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "selectionLength");
      }
      bool isDeprecated;
      if (json.containsKey("isDeprecated")) {
        isDeprecated = jsonDecoder.decodeBool(jsonPath + ".isDeprecated", json["isDeprecated"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isDeprecated");
      }
      bool isPotential;
      if (json.containsKey("isPotential")) {
        isPotential = jsonDecoder.decodeBool(jsonPath + ".isPotential", json["isPotential"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isPotential");
      }
      String docSummary;
      if (json.containsKey("docSummary")) {
        docSummary = jsonDecoder.decodeString(jsonPath + ".docSummary", json["docSummary"]);
      }
      String docComplete;
      if (json.containsKey("docComplete")) {
        docComplete = jsonDecoder.decodeString(jsonPath + ".docComplete", json["docComplete"]);
      }
      String declaringType;
      if (json.containsKey("declaringType")) {
        declaringType = jsonDecoder.decodeString(jsonPath + ".declaringType", json["declaringType"]);
      }
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      }
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder.decodeString(jsonPath + ".returnType", json["returnType"]);
      }
      List<String> parameterNames;
      if (json.containsKey("parameterNames")) {
        parameterNames = jsonDecoder.decodeList(jsonPath + ".parameterNames", json["parameterNames"], jsonDecoder.decodeString);
      }
      List<String> parameterTypes;
      if (json.containsKey("parameterTypes")) {
        parameterTypes = jsonDecoder.decodeList(jsonPath + ".parameterTypes", json["parameterTypes"], jsonDecoder.decodeString);
      }
      int requiredParameterCount;
      if (json.containsKey("requiredParameterCount")) {
        requiredParameterCount = jsonDecoder.decodeInt(jsonPath + ".requiredParameterCount", json["requiredParameterCount"]);
      }
      bool hasNamedParameters;
      if (json.containsKey("hasNamedParameters")) {
        hasNamedParameters = jsonDecoder.decodeBool(jsonPath + ".hasNamedParameters", json["hasNamedParameters"]);
      }
      String parameterName;
      if (json.containsKey("parameterName")) {
        parameterName = jsonDecoder.decodeString(jsonPath + ".parameterName", json["parameterName"]);
      }
      String parameterType;
      if (json.containsKey("parameterType")) {
        parameterType = jsonDecoder.decodeString(jsonPath + ".parameterType", json["parameterType"]);
      }
      String importUri;
      if (json.containsKey("importUri")) {
        importUri = jsonDecoder.decodeString(jsonPath + ".importUri", json["importUri"]);
      }
      return new CompletionSuggestion(kind, relevance, completion, selectionOffset, selectionLength, isDeprecated, isPotential, docSummary: docSummary, docComplete: docComplete, declaringType: declaringType, element: element, returnType: returnType, parameterNames: parameterNames, parameterTypes: parameterTypes, requiredParameterCount: requiredParameterCount, hasNamedParameters: hasNamedParameters, parameterName: parameterName, parameterType: parameterType, importUri: importUri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "CompletionSuggestion", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kind"] = kind.toJson();
    result["relevance"] = relevance;
    result["completion"] = completion;
    result["selectionOffset"] = selectionOffset;
    result["selectionLength"] = selectionLength;
    result["isDeprecated"] = isDeprecated;
    result["isPotential"] = isPotential;
    if (docSummary != null) {
      result["docSummary"] = docSummary;
    }
    if (docComplete != null) {
      result["docComplete"] = docComplete;
    }
    if (declaringType != null) {
      result["declaringType"] = declaringType;
    }
    if (element != null) {
      result["element"] = element.toJson();
    }
    if (returnType != null) {
      result["returnType"] = returnType;
    }
    if (parameterNames != null) {
      result["parameterNames"] = parameterNames;
    }
    if (parameterTypes != null) {
      result["parameterTypes"] = parameterTypes;
    }
    if (requiredParameterCount != null) {
      result["requiredParameterCount"] = requiredParameterCount;
    }
    if (hasNamedParameters != null) {
      result["hasNamedParameters"] = hasNamedParameters;
    }
    if (parameterName != null) {
      result["parameterName"] = parameterName;
    }
    if (parameterType != null) {
      result["parameterType"] = parameterType;
    }
    if (importUri != null) {
      result["importUri"] = importUri;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is CompletionSuggestion) {
      return kind == other.kind &&
          relevance == other.relevance &&
          completion == other.completion &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength &&
          isDeprecated == other.isDeprecated &&
          isPotential == other.isPotential &&
          docSummary == other.docSummary &&
          docComplete == other.docComplete &&
          declaringType == other.declaringType &&
          element == other.element &&
          returnType == other.returnType &&
          listEqual(parameterNames, other.parameterNames, (String a, String b) => a == b) &&
          listEqual(parameterTypes, other.parameterTypes, (String a, String b) => a == b) &&
          requiredParameterCount == other.requiredParameterCount &&
          hasNamedParameters == other.hasNamedParameters &&
          parameterName == other.parameterName &&
          parameterType == other.parameterType &&
          importUri == other.importUri;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, relevance.hashCode);
    hash = JenkinsSmiHash.combine(hash, completion.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, isDeprecated.hashCode);
    hash = JenkinsSmiHash.combine(hash, isPotential.hashCode);
    hash = JenkinsSmiHash.combine(hash, docSummary.hashCode);
    hash = JenkinsSmiHash.combine(hash, docComplete.hashCode);
    hash = JenkinsSmiHash.combine(hash, declaringType.hashCode);
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterNames.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterTypes.hashCode);
    hash = JenkinsSmiHash.combine(hash, requiredParameterCount.hashCode);
    hash = JenkinsSmiHash.combine(hash, hasNamedParameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterName.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterType.hashCode);
    hash = JenkinsSmiHash.combine(hash, importUri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * CompletionSuggestionKind
 *
 * enum {
 *   ARGUMENT_LIST
 *   IMPORT
 *   IDENTIFIER
 *   INVOCATION
 *   KEYWORD
 *   NAMED_ARGUMENT
 *   OPTIONAL_ARGUMENT
 *   PARAMETER
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class CompletionSuggestionKind implements Enum {
  /**
   * A list of arguments for the method or function that is being invoked. For
   * this suggestion kind, the completion field is a textual representation of
   * the invocation and the parameterNames, parameterTypes, and
   * requiredParameterCount attributes are defined.
   */
  static const CompletionSuggestionKind ARGUMENT_LIST = const CompletionSuggestionKind._("ARGUMENT_LIST");

  static const CompletionSuggestionKind IMPORT = const CompletionSuggestionKind._("IMPORT");

  /**
   * The element identifier should be inserted at the completion location. For
   * example "someMethod" in import 'myLib.dart' show someMethod;. For
   * suggestions of this kind, the element attribute is defined and the
   * completion field is the element's identifier.
   */
  static const CompletionSuggestionKind IDENTIFIER = const CompletionSuggestionKind._("IDENTIFIER");

  /**
   * The element is being invoked at the completion location. For example,
   * 'someMethod' in x.someMethod();. For suggestions of this kind, the element
   * attribute is defined and the completion field is the element's identifier.
   */
  static const CompletionSuggestionKind INVOCATION = const CompletionSuggestionKind._("INVOCATION");

  /**
   * A keyword is being suggested. For suggestions of this kind, the completion
   * is the keyword.
   */
  static const CompletionSuggestionKind KEYWORD = const CompletionSuggestionKind._("KEYWORD");

  /**
   * A named argument for the current call site is being suggested. For
   * suggestions of this kind, the completion is the named argument identifier
   * including a trailing ':' and a space.
   */
  static const CompletionSuggestionKind NAMED_ARGUMENT = const CompletionSuggestionKind._("NAMED_ARGUMENT");

  static const CompletionSuggestionKind OPTIONAL_ARGUMENT = const CompletionSuggestionKind._("OPTIONAL_ARGUMENT");

  static const CompletionSuggestionKind PARAMETER = const CompletionSuggestionKind._("PARAMETER");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<CompletionSuggestionKind> VALUES = const <CompletionSuggestionKind>[ARGUMENT_LIST, IMPORT, IDENTIFIER, INVOCATION, KEYWORD, NAMED_ARGUMENT, OPTIONAL_ARGUMENT, PARAMETER];

  @override
  final String name;

  const CompletionSuggestionKind._(this.name);

  factory CompletionSuggestionKind(String name) {
    switch (name) {
      case "ARGUMENT_LIST":
        return ARGUMENT_LIST;
      case "IMPORT":
        return IMPORT;
      case "IDENTIFIER":
        return IDENTIFIER;
      case "INVOCATION":
        return INVOCATION;
      case "KEYWORD":
        return KEYWORD;
      case "NAMED_ARGUMENT":
        return NAMED_ARGUMENT;
      case "OPTIONAL_ARGUMENT":
        return OPTIONAL_ARGUMENT;
      case "PARAMETER":
        return PARAMETER;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory CompletionSuggestionKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new CompletionSuggestionKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "CompletionSuggestionKind", json);
  }

  @override
  String toString() => "CompletionSuggestionKind.$name";

  String toJson() => name;
}

/**
 * ContextBuilderOptions
 *
 * {
 *   "dartSdkSummaryPath": optional String
 *   "defaultAnalysisOptionsFilePath": optional List<String>
 *   "declaredVariables": optional Map<String, String>
 *   "defaultPackageFilePath": optional List<String>
 *   "defaultPackagesDirectoryPath": optional List<String>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ContextBuilderOptions implements HasToJson {
  String _dartSdkSummaryPath;

  List<String> _defaultAnalysisOptionsFilePath;

  Map<String, String> _declaredVariables;

  List<String> _defaultPackageFilePath;

  List<String> _defaultPackagesDirectoryPath;

  /**
   * The file path of the file containing the summary of the SDK that should be
   * used to "analyze" the SDK. The field will be omitted if the summary should
   * be found in the SDK.
   */
  String get dartSdkSummaryPath => _dartSdkSummaryPath;

  /**
   * The file path of the file containing the summary of the SDK that should be
   * used to "analyze" the SDK. The field will be omitted if the summary should
   * be found in the SDK.
   */
  void set dartSdkSummaryPath(String value) {
    this._dartSdkSummaryPath = value;
  }

  /**
   * The file path of the analysis options file that should be used in place of
   * any file in the root directory or a parent of the root directory. The
   * field will be omitted if the normal lookup mechanism should be used.
   */
  List<String> get defaultAnalysisOptionsFilePath => _defaultAnalysisOptionsFilePath;

  /**
   * The file path of the analysis options file that should be used in place of
   * any file in the root directory or a parent of the root directory. The
   * field will be omitted if the normal lookup mechanism should be used.
   */
  void set defaultAnalysisOptionsFilePath(List<String> value) {
    this._defaultAnalysisOptionsFilePath = value;
  }

  /**
   * A table mapping variable names to values for the declared variables. The
   * field will be omitted if no additional variables need to be declared.
   */
  Map<String, String> get declaredVariables => _declaredVariables;

  /**
   * A table mapping variable names to values for the declared variables. The
   * field will be omitted if no additional variables need to be declared.
   */
  void set declaredVariables(Map<String, String> value) {
    this._declaredVariables = value;
  }

  /**
   * The file path of the .packages file that should be used in place of any
   * file found using the normal (Package Specification DEP) lookup mechanism.
   * The field will be omitted if the normal lookup mechanism should be used.
   */
  List<String> get defaultPackageFilePath => _defaultPackageFilePath;

  /**
   * The file path of the .packages file that should be used in place of any
   * file found using the normal (Package Specification DEP) lookup mechanism.
   * The field will be omitted if the normal lookup mechanism should be used.
   */
  void set defaultPackageFilePath(List<String> value) {
    this._defaultPackageFilePath = value;
  }

  /**
   * The file path of the packages directory that should be used in place of
   * any file found using the normal (Package Specification DEP) lookup
   * mechanism. The field will be omitted if the normal lookup mechanism should
   * be used.
   */
  List<String> get defaultPackagesDirectoryPath => _defaultPackagesDirectoryPath;

  /**
   * The file path of the packages directory that should be used in place of
   * any file found using the normal (Package Specification DEP) lookup
   * mechanism. The field will be omitted if the normal lookup mechanism should
   * be used.
   */
  void set defaultPackagesDirectoryPath(List<String> value) {
    this._defaultPackagesDirectoryPath = value;
  }

  ContextBuilderOptions({String dartSdkSummaryPath, List<String> defaultAnalysisOptionsFilePath, Map<String, String> declaredVariables, List<String> defaultPackageFilePath, List<String> defaultPackagesDirectoryPath}) {
    this.dartSdkSummaryPath = dartSdkSummaryPath;
    this.defaultAnalysisOptionsFilePath = defaultAnalysisOptionsFilePath;
    this.declaredVariables = declaredVariables;
    this.defaultPackageFilePath = defaultPackageFilePath;
    this.defaultPackagesDirectoryPath = defaultPackagesDirectoryPath;
  }

  factory ContextBuilderOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String dartSdkSummaryPath;
      if (json.containsKey("dartSdkSummaryPath")) {
        dartSdkSummaryPath = jsonDecoder.decodeString(jsonPath + ".dartSdkSummaryPath", json["dartSdkSummaryPath"]);
      }
      List<String> defaultAnalysisOptionsFilePath;
      if (json.containsKey("defaultAnalysisOptionsFilePath")) {
        defaultAnalysisOptionsFilePath = jsonDecoder.decodeList(jsonPath + ".defaultAnalysisOptionsFilePath", json["defaultAnalysisOptionsFilePath"], jsonDecoder.decodeString);
      }
      Map<String, String> declaredVariables;
      if (json.containsKey("declaredVariables")) {
        declaredVariables = jsonDecoder.decodeMap(jsonPath + ".declaredVariables", json["declaredVariables"], valueDecoder: jsonDecoder.decodeString);
      }
      List<String> defaultPackageFilePath;
      if (json.containsKey("defaultPackageFilePath")) {
        defaultPackageFilePath = jsonDecoder.decodeList(jsonPath + ".defaultPackageFilePath", json["defaultPackageFilePath"], jsonDecoder.decodeString);
      }
      List<String> defaultPackagesDirectoryPath;
      if (json.containsKey("defaultPackagesDirectoryPath")) {
        defaultPackagesDirectoryPath = jsonDecoder.decodeList(jsonPath + ".defaultPackagesDirectoryPath", json["defaultPackagesDirectoryPath"], jsonDecoder.decodeString);
      }
      return new ContextBuilderOptions(dartSdkSummaryPath: dartSdkSummaryPath, defaultAnalysisOptionsFilePath: defaultAnalysisOptionsFilePath, declaredVariables: declaredVariables, defaultPackageFilePath: defaultPackageFilePath, defaultPackagesDirectoryPath: defaultPackagesDirectoryPath);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ContextBuilderOptions", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (dartSdkSummaryPath != null) {
      result["dartSdkSummaryPath"] = dartSdkSummaryPath;
    }
    if (defaultAnalysisOptionsFilePath != null) {
      result["defaultAnalysisOptionsFilePath"] = defaultAnalysisOptionsFilePath;
    }
    if (declaredVariables != null) {
      result["declaredVariables"] = declaredVariables;
    }
    if (defaultPackageFilePath != null) {
      result["defaultPackageFilePath"] = defaultPackageFilePath;
    }
    if (defaultPackagesDirectoryPath != null) {
      result["defaultPackagesDirectoryPath"] = defaultPackagesDirectoryPath;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ContextBuilderOptions) {
      return dartSdkSummaryPath == other.dartSdkSummaryPath &&
          listEqual(defaultAnalysisOptionsFilePath, other.defaultAnalysisOptionsFilePath, (String a, String b) => a == b) &&
          mapEqual(declaredVariables, other.declaredVariables, (String a, String b) => a == b) &&
          listEqual(defaultPackageFilePath, other.defaultPackageFilePath, (String a, String b) => a == b) &&
          listEqual(defaultPackagesDirectoryPath, other.defaultPackagesDirectoryPath, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dartSdkSummaryPath.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultAnalysisOptionsFilePath.hashCode);
    hash = JenkinsSmiHash.combine(hash, declaredVariables.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultPackageFilePath.hashCode);
    hash = JenkinsSmiHash.combine(hash, defaultPackagesDirectoryPath.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ContextRoot
 *
 * {
 *   "root": String
 *   "exclude": List<String>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ContextRoot implements HasToJson {
  String _root;

  List<String> _exclude;

  /**
   * The absolute path of the root directory containing the files to be
   * analyzed.
   */
  String get root => _root;

  /**
   * The absolute path of the root directory containing the files to be
   * analyzed.
   */
  void set root(String value) {
    assert(value != null);
    this._root = value;
  }

  /**
   * A list of the absolute paths of files and directories within the root
   * directory that should not be analyzed.
   */
  List<String> get exclude => _exclude;

  /**
   * A list of the absolute paths of files and directories within the root
   * directory that should not be analyzed.
   */
  void set exclude(List<String> value) {
    assert(value != null);
    this._exclude = value;
  }

  ContextRoot(String root, List<String> exclude) {
    this.root = root;
    this.exclude = exclude;
  }

  factory ContextRoot.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String root;
      if (json.containsKey("root")) {
        root = jsonDecoder.decodeString(jsonPath + ".root", json["root"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "root");
      }
      List<String> exclude;
      if (json.containsKey("exclude")) {
        exclude = jsonDecoder.decodeList(jsonPath + ".exclude", json["exclude"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "exclude");
      }
      return new ContextRoot(root, exclude);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ContextRoot", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["root"] = root;
    result["exclude"] = exclude;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ContextRoot) {
      return root == other.root &&
          listEqual(exclude, other.exclude, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, root.hashCode);
    hash = JenkinsSmiHash.combine(hash, exclude.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * convertGetterToMethod feedback
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ConvertGetterToMethodFeedback extends RefactoringFeedback implements HasToJson {
  @override
  bool operator==(other) {
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
class ConvertGetterToMethodOptions extends RefactoringOptions implements HasToJson {
  @override
  bool operator==(other) {
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
class ConvertMethodToGetterFeedback extends RefactoringFeedback implements HasToJson {
  @override
  bool operator==(other) {
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
class ConvertMethodToGetterOptions extends RefactoringOptions implements HasToJson {
  @override
  bool operator==(other) {
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

  factory EditGetAssistsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
  bool operator==(other) {
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
 *   "assists": List<PrioritizedSourceChange>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class EditGetAssistsResult implements ResponseResult {
  List<PrioritizedSourceChange> _assists;

  /**
   * The assists that are available at the given location.
   */
  List<PrioritizedSourceChange> get assists => _assists;

  /**
   * The assists that are available at the given location.
   */
  void set assists(List<PrioritizedSourceChange> value) {
    assert(value != null);
    this._assists = value;
  }

  EditGetAssistsResult(List<PrioritizedSourceChange> assists) {
    this.assists = assists;
  }

  factory EditGetAssistsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<PrioritizedSourceChange> assists;
      if (json.containsKey("assists")) {
        assists = jsonDecoder.decodeList(jsonPath + ".assists", json["assists"], (String jsonPath, Object json) => new PrioritizedSourceChange.fromJson(jsonDecoder, jsonPath, json));
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
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["assists"] = assists.map((PrioritizedSourceChange value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetAssistsResult) {
      return listEqual(assists, other.assists, (PrioritizedSourceChange a, PrioritizedSourceChange b) => a == b);
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

  factory EditGetAvailableRefactoringsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getAvailableRefactorings params", json);
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
  bool operator==(other) {
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
   *
   * The list of refactoring kinds is currently limited to those defined by the
   * server API, preventing plugins from adding their own refactorings.
   * However, plugins can support pre-defined refactorings, such as a rename
   * refactoring, at locations not supported by server.
   */
  List<RefactoringKind> get kinds => _kinds;

  /**
   * The kinds of refactorings that are valid for the given selection.
   *
   * The list of refactoring kinds is currently limited to those defined by the
   * server API, preventing plugins from adding their own refactorings.
   * However, plugins can support pre-defined refactorings, such as a rename
   * refactoring, at locations not supported by server.
   */
  void set kinds(List<RefactoringKind> value) {
    assert(value != null);
    this._kinds = value;
  }

  EditGetAvailableRefactoringsResult(List<RefactoringKind> kinds) {
    this.kinds = kinds;
  }

  factory EditGetAvailableRefactoringsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<RefactoringKind> kinds;
      if (json.containsKey("kinds")) {
        kinds = jsonDecoder.decodeList(jsonPath + ".kinds", json["kinds"], (String jsonPath, Object json) => new RefactoringKind.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kinds");
      }
      return new EditGetAvailableRefactoringsResult(kinds);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAvailableRefactorings result", json);
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(Response response) {
    return new EditGetAvailableRefactoringsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kinds"] = kinds.map((RefactoringKind value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetAvailableRefactoringsResult) {
      return listEqual(kinds, other.kinds, (RefactoringKind a, RefactoringKind b) => a == b);
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

  factory EditGetFixesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
  bool operator==(other) {
    if (other is EditGetFixesParams) {
      return file == other.file &&
          offset == other.offset;
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

  factory EditGetFixesResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<AnalysisErrorFixes> fixes;
      if (json.containsKey("fixes")) {
        fixes = jsonDecoder.decodeList(jsonPath + ".fixes", json["fixes"], (String jsonPath, Object json) => new AnalysisErrorFixes.fromJson(jsonDecoder, jsonPath, json));
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
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["fixes"] = fixes.map((AnalysisErrorFixes value) => value.toJson()).toList();
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetFixesResult) {
      return listEqual(fixes, other.fixes, (AnalysisErrorFixes a, AnalysisErrorFixes b) => a == b);
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

  EditGetRefactoringParams(RefactoringKind kind, String file, int offset, int length, bool validateOnly, {RefactoringOptions options}) {
    this.kind = kind;
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.validateOnly = validateOnly;
    this.options = options;
  }

  factory EditGetRefactoringParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RefactoringKind kind;
      if (json.containsKey("kind")) {
        kind = new RefactoringKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
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
        validateOnly = jsonDecoder.decodeBool(jsonPath + ".validateOnly", json["validateOnly"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "validateOnly");
      }
      RefactoringOptions options;
      if (json.containsKey("options")) {
        options = new RefactoringOptions.fromJson(jsonDecoder, jsonPath + ".options", json["options"], kind);
      }
      return new EditGetRefactoringParams(kind, file, offset, length, validateOnly, options: options);
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
  bool operator==(other) {
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
   * The initial status of the refactoring, that is, problems related to the
   * context in which the refactoring is requested. The list should be empty if
   * there are no known problems.
   */
  List<RefactoringProblem> get initialProblems => _initialProblems;

  /**
   * The initial status of the refactoring, that is, problems related to the
   * context in which the refactoring is requested. The list should be empty if
   * there are no known problems.
   */
  void set initialProblems(List<RefactoringProblem> value) {
    assert(value != null);
    this._initialProblems = value;
  }

  /**
   * The options validation status, that is, problems in the given options,
   * such as light-weight validation of a new name, flags compatibility, etc.
   * The list should be empty if there are no known problems.
   */
  List<RefactoringProblem> get optionsProblems => _optionsProblems;

  /**
   * The options validation status, that is, problems in the given options,
   * such as light-weight validation of a new name, flags compatibility, etc.
   * The list should be empty if there are no known problems.
   */
  void set optionsProblems(List<RefactoringProblem> value) {
    assert(value != null);
    this._optionsProblems = value;
  }

  /**
   * The final status of the refactoring, that is, problems identified in the
   * result of a full, potentially expensive validation and / or change
   * creation. The list should be empty if there are no known problems.
   */
  List<RefactoringProblem> get finalProblems => _finalProblems;

  /**
   * The final status of the refactoring, that is, problems identified in the
   * result of a full, potentially expensive validation and / or change
   * creation. The list should be empty if there are no known problems.
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
   * can be omitted if there are problems that prevent a set of changes from
   * being computed, such as having no options specified for a refactoring that
   * requires them, or if only validation was requested.
   */
  SourceChange get change => _change;

  /**
   * The changes that are to be applied to affect the refactoring. This field
   * can be omitted if there are problems that prevent a set of changes from
   * being computed, such as having no options specified for a refactoring that
   * requires them, or if only validation was requested.
   */
  void set change(SourceChange value) {
    this._change = value;
  }

  /**
   * The ids of source edits that are not known to be valid. An edit is not
   * known to be valid if there was insufficient type information for the
   * plugin to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field can be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  List<String> get potentialEdits => _potentialEdits;

  /**
   * The ids of source edits that are not known to be valid. An edit is not
   * known to be valid if there was insufficient type information for the
   * plugin to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field can be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  void set potentialEdits(List<String> value) {
    this._potentialEdits = value;
  }

  EditGetRefactoringResult(List<RefactoringProblem> initialProblems, List<RefactoringProblem> optionsProblems, List<RefactoringProblem> finalProblems, {RefactoringFeedback feedback, SourceChange change, List<String> potentialEdits}) {
    this.initialProblems = initialProblems;
    this.optionsProblems = optionsProblems;
    this.finalProblems = finalProblems;
    this.feedback = feedback;
    this.change = change;
    this.potentialEdits = potentialEdits;
  }

  factory EditGetRefactoringResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<RefactoringProblem> initialProblems;
      if (json.containsKey("initialProblems")) {
        initialProblems = jsonDecoder.decodeList(jsonPath + ".initialProblems", json["initialProblems"], (String jsonPath, Object json) => new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "initialProblems");
      }
      List<RefactoringProblem> optionsProblems;
      if (json.containsKey("optionsProblems")) {
        optionsProblems = jsonDecoder.decodeList(jsonPath + ".optionsProblems", json["optionsProblems"], (String jsonPath, Object json) => new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "optionsProblems");
      }
      List<RefactoringProblem> finalProblems;
      if (json.containsKey("finalProblems")) {
        finalProblems = jsonDecoder.decodeList(jsonPath + ".finalProblems", json["finalProblems"], (String jsonPath, Object json) => new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "finalProblems");
      }
      RefactoringFeedback feedback;
      if (json.containsKey("feedback")) {
        feedback = new RefactoringFeedback.fromJson(jsonDecoder, jsonPath + ".feedback", json["feedback"], json);
      }
      SourceChange change;
      if (json.containsKey("change")) {
        change = new SourceChange.fromJson(jsonDecoder, jsonPath + ".change", json["change"]);
      }
      List<String> potentialEdits;
      if (json.containsKey("potentialEdits")) {
        potentialEdits = jsonDecoder.decodeList(jsonPath + ".potentialEdits", json["potentialEdits"], jsonDecoder.decodeString);
      }
      return new EditGetRefactoringResult(initialProblems, optionsProblems, finalProblems, feedback: feedback, change: change, potentialEdits: potentialEdits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring result", json);
    }
  }

  factory EditGetRefactoringResult.fromResponse(Response response) {
    return new EditGetRefactoringResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["initialProblems"] = initialProblems.map((RefactoringProblem value) => value.toJson()).toList();
    result["optionsProblems"] = optionsProblems.map((RefactoringProblem value) => value.toJson()).toList();
    result["finalProblems"] = finalProblems.map((RefactoringProblem value) => value.toJson()).toList();
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
  bool operator==(other) {
    if (other is EditGetRefactoringResult) {
      return listEqual(initialProblems, other.initialProblems, (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          listEqual(optionsProblems, other.optionsProblems, (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          listEqual(finalProblems, other.finalProblems, (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          feedback == other.feedback &&
          change == other.change &&
          listEqual(potentialEdits, other.potentialEdits, (String a, String b) => a == b);
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
 * Element
 *
 * {
 *   "kind": ElementKind
 *   "name": String
 *   "location": optional Location
 *   "flags": int
 *   "parameters": optional String
 *   "returnType": optional String
 *   "typeParameters": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Element implements HasToJson {
  static const int FLAG_ABSTRACT = 0x01;
  static const int FLAG_CONST = 0x02;
  static const int FLAG_FINAL = 0x04;
  static const int FLAG_STATIC = 0x08;
  static const int FLAG_PRIVATE = 0x10;
  static const int FLAG_DEPRECATED = 0x20;

  static int makeFlags({isAbstract: false, isConst: false, isFinal: false, isStatic: false, isPrivate: false, isDeprecated: false}) {
    int flags = 0;
    if (isAbstract) flags |= FLAG_ABSTRACT;
    if (isConst) flags |= FLAG_CONST;
    if (isFinal) flags |= FLAG_FINAL;
    if (isStatic) flags |= FLAG_STATIC;
    if (isPrivate) flags |= FLAG_PRIVATE;
    if (isDeprecated) flags |= FLAG_DEPRECATED;
    return flags;
  }

  ElementKind _kind;

  String _name;

  Location _location;

  int _flags;

  String _parameters;

  String _returnType;

  String _typeParameters;

  /**
   * The kind of the element.
   */
  ElementKind get kind => _kind;

  /**
   * The kind of the element.
   */
  void set kind(ElementKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The name of the element. This is typically used as the label in the
   * outline.
   */
  String get name => _name;

  /**
   * The name of the element. This is typically used as the label in the
   * outline.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * The location of the name in the declaration of the element.
   */
  Location get location => _location;

  /**
   * The location of the name in the declaration of the element.
   */
  void set location(Location value) {
    this._location = value;
  }

  /**
   * A bit-map containing the following flags:
   *
   * - 0x01 - set if the element is explicitly or implicitly abstract
   * - 0x02 - set if the element was declared to be ‘const’
   * - 0x04 - set if the element was declared to be ‘final’
   * - 0x08 - set if the element is a static member of a class or is a
   *   top-level function or field
   * - 0x10 - set if the element is private
   * - 0x20 - set if the element is deprecated
   */
  int get flags => _flags;

  /**
   * A bit-map containing the following flags:
   *
   * - 0x01 - set if the element is explicitly or implicitly abstract
   * - 0x02 - set if the element was declared to be ‘const’
   * - 0x04 - set if the element was declared to be ‘final’
   * - 0x08 - set if the element is a static member of a class or is a
   *   top-level function or field
   * - 0x10 - set if the element is private
   * - 0x20 - set if the element is deprecated
   */
  void set flags(int value) {
    assert(value != null);
    this._flags = value;
  }

  /**
   * The parameter list for the element. If the element is not a method or
   * function this field will not be defined. If the element doesn't have
   * parameters (e.g. getter), this field will not be defined. If the element
   * has zero parameters, this field will have a value of "()".
   */
  String get parameters => _parameters;

  /**
   * The parameter list for the element. If the element is not a method or
   * function this field will not be defined. If the element doesn't have
   * parameters (e.g. getter), this field will not be defined. If the element
   * has zero parameters, this field will have a value of "()".
   */
  void set parameters(String value) {
    this._parameters = value;
  }

  /**
   * The return type of the element. If the element is not a method or function
   * this field will not be defined. If the element does not have a declared
   * return type, this field will contain an empty string.
   */
  String get returnType => _returnType;

  /**
   * The return type of the element. If the element is not a method or function
   * this field will not be defined. If the element does not have a declared
   * return type, this field will contain an empty string.
   */
  void set returnType(String value) {
    this._returnType = value;
  }

  /**
   * The type parameter list for the element. If the element doesn't have type
   * parameters, this field will not be defined.
   */
  String get typeParameters => _typeParameters;

  /**
   * The type parameter list for the element. If the element doesn't have type
   * parameters, this field will not be defined.
   */
  void set typeParameters(String value) {
    this._typeParameters = value;
  }

  Element(ElementKind kind, String name, int flags, {Location location, String parameters, String returnType, String typeParameters}) {
    this.kind = kind;
    this.name = name;
    this.location = location;
    this.flags = flags;
    this.parameters = parameters;
    this.returnType = returnType;
    this.typeParameters = typeParameters;
  }

  factory Element.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      ElementKind kind;
      if (json.containsKey("kind")) {
        kind = new ElementKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      }
      int flags;
      if (json.containsKey("flags")) {
        flags = jsonDecoder.decodeInt(jsonPath + ".flags", json["flags"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "flags");
      }
      String parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder.decodeString(jsonPath + ".parameters", json["parameters"]);
      }
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder.decodeString(jsonPath + ".returnType", json["returnType"]);
      }
      String typeParameters;
      if (json.containsKey("typeParameters")) {
        typeParameters = jsonDecoder.decodeString(jsonPath + ".typeParameters", json["typeParameters"]);
      }
      return new Element(kind, name, flags, location: location, parameters: parameters, returnType: returnType, typeParameters: typeParameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Element", json);
    }
  }

  bool get isAbstract => (flags & FLAG_ABSTRACT) != 0;
  bool get isConst => (flags & FLAG_CONST) != 0;
  bool get isFinal => (flags & FLAG_FINAL) != 0;
  bool get isStatic => (flags & FLAG_STATIC) != 0;
  bool get isPrivate => (flags & FLAG_PRIVATE) != 0;
  bool get isDeprecated => (flags & FLAG_DEPRECATED) != 0;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kind"] = kind.toJson();
    result["name"] = name;
    if (location != null) {
      result["location"] = location.toJson();
    }
    result["flags"] = flags;
    if (parameters != null) {
      result["parameters"] = parameters;
    }
    if (returnType != null) {
      result["returnType"] = returnType;
    }
    if (typeParameters != null) {
      result["typeParameters"] = typeParameters;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is Element) {
      return kind == other.kind &&
          name == other.name &&
          location == other.location &&
          flags == other.flags &&
          parameters == other.parameters &&
          returnType == other.returnType &&
          typeParameters == other.typeParameters;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, flags.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = JenkinsSmiHash.combine(hash, typeParameters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * ElementKind
 *
 * enum {
 *   CLASS
 *   CLASS_TYPE_ALIAS
 *   COMPILATION_UNIT
 *   CONSTRUCTOR
 *   ENUM
 *   ENUM_CONSTANT
 *   FIELD
 *   FILE
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER
 *   LABEL
 *   LIBRARY
 *   LOCAL_VARIABLE
 *   METHOD
 *   PARAMETER
 *   PREFIX
 *   SETTER
 *   TOP_LEVEL_VARIABLE
 *   TYPE_PARAMETER
 *   UNKNOWN
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class ElementKind implements Enum {
  static const ElementKind CLASS = const ElementKind._("CLASS");

  static const ElementKind CLASS_TYPE_ALIAS = const ElementKind._("CLASS_TYPE_ALIAS");

  static const ElementKind COMPILATION_UNIT = const ElementKind._("COMPILATION_UNIT");

  static const ElementKind CONSTRUCTOR = const ElementKind._("CONSTRUCTOR");

  static const ElementKind ENUM = const ElementKind._("ENUM");

  static const ElementKind ENUM_CONSTANT = const ElementKind._("ENUM_CONSTANT");

  static const ElementKind FIELD = const ElementKind._("FIELD");

  static const ElementKind FILE = const ElementKind._("FILE");

  static const ElementKind FUNCTION = const ElementKind._("FUNCTION");

  static const ElementKind FUNCTION_TYPE_ALIAS = const ElementKind._("FUNCTION_TYPE_ALIAS");

  static const ElementKind GETTER = const ElementKind._("GETTER");

  static const ElementKind LABEL = const ElementKind._("LABEL");

  static const ElementKind LIBRARY = const ElementKind._("LIBRARY");

  static const ElementKind LOCAL_VARIABLE = const ElementKind._("LOCAL_VARIABLE");

  static const ElementKind METHOD = const ElementKind._("METHOD");

  static const ElementKind PARAMETER = const ElementKind._("PARAMETER");

  static const ElementKind PREFIX = const ElementKind._("PREFIX");

  static const ElementKind SETTER = const ElementKind._("SETTER");

  static const ElementKind TOP_LEVEL_VARIABLE = const ElementKind._("TOP_LEVEL_VARIABLE");

  static const ElementKind TYPE_PARAMETER = const ElementKind._("TYPE_PARAMETER");

  static const ElementKind UNKNOWN = const ElementKind._("UNKNOWN");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ElementKind> VALUES = const <ElementKind>[CLASS, CLASS_TYPE_ALIAS, COMPILATION_UNIT, CONSTRUCTOR, ENUM, ENUM_CONSTANT, FIELD, FILE, FUNCTION, FUNCTION_TYPE_ALIAS, GETTER, LABEL, LIBRARY, LOCAL_VARIABLE, METHOD, PARAMETER, PREFIX, SETTER, TOP_LEVEL_VARIABLE, TYPE_PARAMETER, UNKNOWN];

  @override
  final String name;

  const ElementKind._(this.name);

  factory ElementKind(String name) {
    switch (name) {
      case "CLASS":
        return CLASS;
      case "CLASS_TYPE_ALIAS":
        return CLASS_TYPE_ALIAS;
      case "COMPILATION_UNIT":
        return COMPILATION_UNIT;
      case "CONSTRUCTOR":
        return CONSTRUCTOR;
      case "ENUM":
        return ENUM;
      case "ENUM_CONSTANT":
        return ENUM_CONSTANT;
      case "FIELD":
        return FIELD;
      case "FILE":
        return FILE;
      case "FUNCTION":
        return FUNCTION;
      case "FUNCTION_TYPE_ALIAS":
        return FUNCTION_TYPE_ALIAS;
      case "GETTER":
        return GETTER;
      case "LABEL":
        return LABEL;
      case "LIBRARY":
        return LIBRARY;
      case "LOCAL_VARIABLE":
        return LOCAL_VARIABLE;
      case "METHOD":
        return METHOD;
      case "PARAMETER":
        return PARAMETER;
      case "PREFIX":
        return PREFIX;
      case "SETTER":
        return SETTER;
      case "TOP_LEVEL_VARIABLE":
        return TOP_LEVEL_VARIABLE;
      case "TYPE_PARAMETER":
        return TYPE_PARAMETER;
      case "UNKNOWN":
        return UNKNOWN;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ElementKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ElementKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ElementKind", json);
  }

  @override
  String toString() => "ElementKind.$name";

  String toJson() => name;
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

  ExtractLocalVariableFeedback(List<String> names, List<int> offsets, List<int> lengths, {List<int> coveringExpressionOffsets, List<int> coveringExpressionLengths}) {
    this.coveringExpressionOffsets = coveringExpressionOffsets;
    this.coveringExpressionLengths = coveringExpressionLengths;
    this.names = names;
    this.offsets = offsets;
    this.lengths = lengths;
  }

  factory ExtractLocalVariableFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<int> coveringExpressionOffsets;
      if (json.containsKey("coveringExpressionOffsets")) {
        coveringExpressionOffsets = jsonDecoder.decodeList(jsonPath + ".coveringExpressionOffsets", json["coveringExpressionOffsets"], jsonDecoder.decodeInt);
      }
      List<int> coveringExpressionLengths;
      if (json.containsKey("coveringExpressionLengths")) {
        coveringExpressionLengths = jsonDecoder.decodeList(jsonPath + ".coveringExpressionLengths", json["coveringExpressionLengths"], jsonDecoder.decodeInt);
      }
      List<String> names;
      if (json.containsKey("names")) {
        names = jsonDecoder.decodeList(jsonPath + ".names", json["names"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "names");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder.decodeList(jsonPath + ".offsets", json["offsets"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offsets");
      }
      List<int> lengths;
      if (json.containsKey("lengths")) {
        lengths = jsonDecoder.decodeList(jsonPath + ".lengths", json["lengths"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "lengths");
      }
      return new ExtractLocalVariableFeedback(names, offsets, lengths, coveringExpressionOffsets: coveringExpressionOffsets, coveringExpressionLengths: coveringExpressionLengths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractLocalVariable feedback", json);
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
  bool operator==(other) {
    if (other is ExtractLocalVariableFeedback) {
      return listEqual(coveringExpressionOffsets, other.coveringExpressionOffsets, (int a, int b) => a == b) &&
          listEqual(coveringExpressionLengths, other.coveringExpressionLengths, (int a, int b) => a == b) &&
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

  factory ExtractLocalVariableOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        extractAll = jsonDecoder.decodeBool(jsonPath + ".extractAll", json["extractAll"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "extractAll");
      }
      return new ExtractLocalVariableOptions(name, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractLocalVariable options", json);
    }
  }

  factory ExtractLocalVariableOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
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
  bool operator==(other) {
    if (other is ExtractLocalVariableOptions) {
      return name == other.name &&
          extractAll == other.extractAll;
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

  ExtractMethodFeedback(int offset, int length, String returnType, List<String> names, bool canCreateGetter, List<RefactoringMethodParameter> parameters, List<int> offsets, List<int> lengths) {
    this.offset = offset;
    this.length = length;
    this.returnType = returnType;
    this.names = names;
    this.canCreateGetter = canCreateGetter;
    this.parameters = parameters;
    this.offsets = offsets;
    this.lengths = lengths;
  }

  factory ExtractMethodFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        returnType = jsonDecoder.decodeString(jsonPath + ".returnType", json["returnType"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "returnType");
      }
      List<String> names;
      if (json.containsKey("names")) {
        names = jsonDecoder.decodeList(jsonPath + ".names", json["names"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "names");
      }
      bool canCreateGetter;
      if (json.containsKey("canCreateGetter")) {
        canCreateGetter = jsonDecoder.decodeBool(jsonPath + ".canCreateGetter", json["canCreateGetter"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "canCreateGetter");
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder.decodeList(jsonPath + ".parameters", json["parameters"], (String jsonPath, Object json) => new RefactoringMethodParameter.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "parameters");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder.decodeList(jsonPath + ".offsets", json["offsets"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offsets");
      }
      List<int> lengths;
      if (json.containsKey("lengths")) {
        lengths = jsonDecoder.decodeList(jsonPath + ".lengths", json["lengths"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "lengths");
      }
      return new ExtractMethodFeedback(offset, length, returnType, names, canCreateGetter, parameters, offsets, lengths);
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
    result["parameters"] = parameters.map((RefactoringMethodParameter value) => value.toJson()).toList();
    result["offsets"] = offsets;
    result["lengths"] = lengths;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExtractMethodFeedback) {
      return offset == other.offset &&
          length == other.length &&
          returnType == other.returnType &&
          listEqual(names, other.names, (String a, String b) => a == b) &&
          canCreateGetter == other.canCreateGetter &&
          listEqual(parameters, other.parameters, (RefactoringMethodParameter a, RefactoringMethodParameter b) => a == b) &&
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

  ExtractMethodOptions(String returnType, bool createGetter, String name, List<RefactoringMethodParameter> parameters, bool extractAll) {
    this.returnType = returnType;
    this.createGetter = createGetter;
    this.name = name;
    this.parameters = parameters;
    this.extractAll = extractAll;
  }

  factory ExtractMethodOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder.decodeString(jsonPath + ".returnType", json["returnType"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "returnType");
      }
      bool createGetter;
      if (json.containsKey("createGetter")) {
        createGetter = jsonDecoder.decodeBool(jsonPath + ".createGetter", json["createGetter"]);
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
        parameters = jsonDecoder.decodeList(jsonPath + ".parameters", json["parameters"], (String jsonPath, Object json) => new RefactoringMethodParameter.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "parameters");
      }
      bool extractAll;
      if (json.containsKey("extractAll")) {
        extractAll = jsonDecoder.decodeBool(jsonPath + ".extractAll", json["extractAll"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "extractAll");
      }
      return new ExtractMethodOptions(returnType, createGetter, name, parameters, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractMethod options", json);
    }
  }

  factory ExtractMethodOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
    return new ExtractMethodOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["returnType"] = returnType;
    result["createGetter"] = createGetter;
    result["name"] = name;
    result["parameters"] = parameters.map((RefactoringMethodParameter value) => value.toJson()).toList();
    result["extractAll"] = extractAll;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExtractMethodOptions) {
      return returnType == other.returnType &&
          createGetter == other.createGetter &&
          name == other.name &&
          listEqual(parameters, other.parameters, (RefactoringMethodParameter a, RefactoringMethodParameter b) => a == b) &&
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
 * FoldingKind
 *
 * enum {
 *   COMMENT
 *   CLASS_MEMBER
 *   DIRECTIVES
 *   DOCUMENTATION_COMMENT
 *   TOP_LEVEL_DECLARATION
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FoldingKind implements Enum {
  static const FoldingKind COMMENT = const FoldingKind._("COMMENT");

  static const FoldingKind CLASS_MEMBER = const FoldingKind._("CLASS_MEMBER");

  static const FoldingKind DIRECTIVES = const FoldingKind._("DIRECTIVES");

  static const FoldingKind DOCUMENTATION_COMMENT = const FoldingKind._("DOCUMENTATION_COMMENT");

  static const FoldingKind TOP_LEVEL_DECLARATION = const FoldingKind._("TOP_LEVEL_DECLARATION");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<FoldingKind> VALUES = const <FoldingKind>[COMMENT, CLASS_MEMBER, DIRECTIVES, DOCUMENTATION_COMMENT, TOP_LEVEL_DECLARATION];

  @override
  final String name;

  const FoldingKind._(this.name);

  factory FoldingKind(String name) {
    switch (name) {
      case "COMMENT":
        return COMMENT;
      case "CLASS_MEMBER":
        return CLASS_MEMBER;
      case "DIRECTIVES":
        return DIRECTIVES;
      case "DOCUMENTATION_COMMENT":
        return DOCUMENTATION_COMMENT;
      case "TOP_LEVEL_DECLARATION":
        return TOP_LEVEL_DECLARATION;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory FoldingKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new FoldingKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "FoldingKind", json);
  }

  @override
  String toString() => "FoldingKind.$name";

  String toJson() => name;
}

/**
 * FoldingRegion
 *
 * {
 *   "kind": FoldingKind
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FoldingRegion implements HasToJson {
  FoldingKind _kind;

  int _offset;

  int _length;

  /**
   * The kind of the region.
   */
  FoldingKind get kind => _kind;

  /**
   * The kind of the region.
   */
  void set kind(FoldingKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The offset of the region to be folded.
   */
  int get offset => _offset;

  /**
   * The offset of the region to be folded.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region to be folded.
   */
  int get length => _length;

  /**
   * The length of the region to be folded.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  FoldingRegion(FoldingKind kind, int offset, int length) {
    this.kind = kind;
    this.offset = offset;
    this.length = length;
  }

  factory FoldingRegion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      FoldingKind kind;
      if (json.containsKey("kind")) {
        kind = new FoldingKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
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
      return new FoldingRegion(kind, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "FoldingRegion", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kind"] = kind.toJson();
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is FoldingRegion) {
      return kind == other.kind &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * HighlightRegion
 *
 * {
 *   "type": HighlightRegionType
 *   "offset": int
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class HighlightRegion implements HasToJson {
  HighlightRegionType _type;

  int _offset;

  int _length;

  /**
   * The type of highlight associated with the region.
   */
  HighlightRegionType get type => _type;

  /**
   * The type of highlight associated with the region.
   */
  void set type(HighlightRegionType value) {
    assert(value != null);
    this._type = value;
  }

  /**
   * The offset of the region to be highlighted.
   */
  int get offset => _offset;

  /**
   * The offset of the region to be highlighted.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region to be highlighted.
   */
  int get length => _length;

  /**
   * The length of the region to be highlighted.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  HighlightRegion(HighlightRegionType type, int offset, int length) {
    this.type = type;
    this.offset = offset;
    this.length = length;
  }

  factory HighlightRegion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      HighlightRegionType type;
      if (json.containsKey("type")) {
        type = new HighlightRegionType.fromJson(jsonDecoder, jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "type");
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
      return new HighlightRegion(type, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "HighlightRegion", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["type"] = type.toJson();
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is HighlightRegion) {
      return type == other.type &&
          offset == other.offset &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * HighlightRegionType
 *
 * enum {
 *   ANNOTATION
 *   BUILT_IN
 *   CLASS
 *   COMMENT_BLOCK
 *   COMMENT_DOCUMENTATION
 *   COMMENT_END_OF_LINE
 *   CONSTRUCTOR
 *   DIRECTIVE
 *   DYNAMIC_TYPE
 *   DYNAMIC_LOCAL_VARIABLE_DECLARATION
 *   DYNAMIC_LOCAL_VARIABLE_REFERENCE
 *   DYNAMIC_PARAMETER_DECLARATION
 *   DYNAMIC_PARAMETER_REFERENCE
 *   ENUM
 *   ENUM_CONSTANT
 *   FIELD
 *   FIELD_STATIC
 *   FUNCTION
 *   FUNCTION_DECLARATION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER_DECLARATION
 *   IDENTIFIER_DEFAULT
 *   IMPORT_PREFIX
 *   INSTANCE_FIELD_DECLARATION
 *   INSTANCE_FIELD_REFERENCE
 *   INSTANCE_GETTER_DECLARATION
 *   INSTANCE_GETTER_REFERENCE
 *   INSTANCE_METHOD_DECLARATION
 *   INSTANCE_METHOD_REFERENCE
 *   INSTANCE_SETTER_DECLARATION
 *   INSTANCE_SETTER_REFERENCE
 *   INVALID_STRING_ESCAPE
 *   KEYWORD
 *   LABEL
 *   LIBRARY_NAME
 *   LITERAL_BOOLEAN
 *   LITERAL_DOUBLE
 *   LITERAL_INTEGER
 *   LITERAL_LIST
 *   LITERAL_MAP
 *   LITERAL_STRING
 *   LOCAL_FUNCTION_DECLARATION
 *   LOCAL_FUNCTION_REFERENCE
 *   LOCAL_VARIABLE
 *   LOCAL_VARIABLE_DECLARATION
 *   LOCAL_VARIABLE_REFERENCE
 *   METHOD
 *   METHOD_DECLARATION
 *   METHOD_DECLARATION_STATIC
 *   METHOD_STATIC
 *   PARAMETER
 *   SETTER_DECLARATION
 *   TOP_LEVEL_VARIABLE
 *   PARAMETER_DECLARATION
 *   PARAMETER_REFERENCE
 *   STATIC_FIELD_DECLARATION
 *   STATIC_GETTER_DECLARATION
 *   STATIC_GETTER_REFERENCE
 *   STATIC_METHOD_DECLARATION
 *   STATIC_METHOD_REFERENCE
 *   STATIC_SETTER_DECLARATION
 *   STATIC_SETTER_REFERENCE
 *   TOP_LEVEL_FUNCTION_DECLARATION
 *   TOP_LEVEL_FUNCTION_REFERENCE
 *   TOP_LEVEL_GETTER_DECLARATION
 *   TOP_LEVEL_GETTER_REFERENCE
 *   TOP_LEVEL_SETTER_DECLARATION
 *   TOP_LEVEL_SETTER_REFERENCE
 *   TOP_LEVEL_VARIABLE_DECLARATION
 *   TYPE_NAME_DYNAMIC
 *   TYPE_PARAMETER
 *   UNRESOLVED_INSTANCE_MEMBER_REFERENCE
 *   VALID_STRING_ESCAPE
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class HighlightRegionType implements Enum {
  static const HighlightRegionType ANNOTATION = const HighlightRegionType._("ANNOTATION");

  static const HighlightRegionType BUILT_IN = const HighlightRegionType._("BUILT_IN");

  static const HighlightRegionType CLASS = const HighlightRegionType._("CLASS");

  static const HighlightRegionType COMMENT_BLOCK = const HighlightRegionType._("COMMENT_BLOCK");

  static const HighlightRegionType COMMENT_DOCUMENTATION = const HighlightRegionType._("COMMENT_DOCUMENTATION");

  static const HighlightRegionType COMMENT_END_OF_LINE = const HighlightRegionType._("COMMENT_END_OF_LINE");

  static const HighlightRegionType CONSTRUCTOR = const HighlightRegionType._("CONSTRUCTOR");

  static const HighlightRegionType DIRECTIVE = const HighlightRegionType._("DIRECTIVE");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType DYNAMIC_TYPE = const HighlightRegionType._("DYNAMIC_TYPE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType DYNAMIC_LOCAL_VARIABLE_DECLARATION = const HighlightRegionType._("DYNAMIC_LOCAL_VARIABLE_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType DYNAMIC_LOCAL_VARIABLE_REFERENCE = const HighlightRegionType._("DYNAMIC_LOCAL_VARIABLE_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType DYNAMIC_PARAMETER_DECLARATION = const HighlightRegionType._("DYNAMIC_PARAMETER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType DYNAMIC_PARAMETER_REFERENCE = const HighlightRegionType._("DYNAMIC_PARAMETER_REFERENCE");

  static const HighlightRegionType ENUM = const HighlightRegionType._("ENUM");

  static const HighlightRegionType ENUM_CONSTANT = const HighlightRegionType._("ENUM_CONSTANT");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType FIELD = const HighlightRegionType._("FIELD");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType FIELD_STATIC = const HighlightRegionType._("FIELD_STATIC");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType FUNCTION = const HighlightRegionType._("FUNCTION");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType FUNCTION_DECLARATION = const HighlightRegionType._("FUNCTION_DECLARATION");

  static const HighlightRegionType FUNCTION_TYPE_ALIAS = const HighlightRegionType._("FUNCTION_TYPE_ALIAS");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType GETTER_DECLARATION = const HighlightRegionType._("GETTER_DECLARATION");

  static const HighlightRegionType IDENTIFIER_DEFAULT = const HighlightRegionType._("IDENTIFIER_DEFAULT");

  static const HighlightRegionType IMPORT_PREFIX = const HighlightRegionType._("IMPORT_PREFIX");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_FIELD_DECLARATION = const HighlightRegionType._("INSTANCE_FIELD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_FIELD_REFERENCE = const HighlightRegionType._("INSTANCE_FIELD_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_GETTER_DECLARATION = const HighlightRegionType._("INSTANCE_GETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_GETTER_REFERENCE = const HighlightRegionType._("INSTANCE_GETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_METHOD_DECLARATION = const HighlightRegionType._("INSTANCE_METHOD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_METHOD_REFERENCE = const HighlightRegionType._("INSTANCE_METHOD_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_SETTER_DECLARATION = const HighlightRegionType._("INSTANCE_SETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INSTANCE_SETTER_REFERENCE = const HighlightRegionType._("INSTANCE_SETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType INVALID_STRING_ESCAPE = const HighlightRegionType._("INVALID_STRING_ESCAPE");

  static const HighlightRegionType KEYWORD = const HighlightRegionType._("KEYWORD");

  static const HighlightRegionType LABEL = const HighlightRegionType._("LABEL");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType LIBRARY_NAME = const HighlightRegionType._("LIBRARY_NAME");

  static const HighlightRegionType LITERAL_BOOLEAN = const HighlightRegionType._("LITERAL_BOOLEAN");

  static const HighlightRegionType LITERAL_DOUBLE = const HighlightRegionType._("LITERAL_DOUBLE");

  static const HighlightRegionType LITERAL_INTEGER = const HighlightRegionType._("LITERAL_INTEGER");

  static const HighlightRegionType LITERAL_LIST = const HighlightRegionType._("LITERAL_LIST");

  static const HighlightRegionType LITERAL_MAP = const HighlightRegionType._("LITERAL_MAP");

  static const HighlightRegionType LITERAL_STRING = const HighlightRegionType._("LITERAL_STRING");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType LOCAL_FUNCTION_DECLARATION = const HighlightRegionType._("LOCAL_FUNCTION_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType LOCAL_FUNCTION_REFERENCE = const HighlightRegionType._("LOCAL_FUNCTION_REFERENCE");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType LOCAL_VARIABLE = const HighlightRegionType._("LOCAL_VARIABLE");

  static const HighlightRegionType LOCAL_VARIABLE_DECLARATION = const HighlightRegionType._("LOCAL_VARIABLE_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType LOCAL_VARIABLE_REFERENCE = const HighlightRegionType._("LOCAL_VARIABLE_REFERENCE");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType METHOD = const HighlightRegionType._("METHOD");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType METHOD_DECLARATION = const HighlightRegionType._("METHOD_DECLARATION");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType METHOD_DECLARATION_STATIC = const HighlightRegionType._("METHOD_DECLARATION_STATIC");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType METHOD_STATIC = const HighlightRegionType._("METHOD_STATIC");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType PARAMETER = const HighlightRegionType._("PARAMETER");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType SETTER_DECLARATION = const HighlightRegionType._("SETTER_DECLARATION");

  /**
   * Only for version 1 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_VARIABLE = const HighlightRegionType._("TOP_LEVEL_VARIABLE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType PARAMETER_DECLARATION = const HighlightRegionType._("PARAMETER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType PARAMETER_REFERENCE = const HighlightRegionType._("PARAMETER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_FIELD_DECLARATION = const HighlightRegionType._("STATIC_FIELD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_GETTER_DECLARATION = const HighlightRegionType._("STATIC_GETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_GETTER_REFERENCE = const HighlightRegionType._("STATIC_GETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_METHOD_DECLARATION = const HighlightRegionType._("STATIC_METHOD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_METHOD_REFERENCE = const HighlightRegionType._("STATIC_METHOD_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_SETTER_DECLARATION = const HighlightRegionType._("STATIC_SETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType STATIC_SETTER_REFERENCE = const HighlightRegionType._("STATIC_SETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_FUNCTION_DECLARATION = const HighlightRegionType._("TOP_LEVEL_FUNCTION_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_FUNCTION_REFERENCE = const HighlightRegionType._("TOP_LEVEL_FUNCTION_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_GETTER_DECLARATION = const HighlightRegionType._("TOP_LEVEL_GETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_GETTER_REFERENCE = const HighlightRegionType._("TOP_LEVEL_GETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_SETTER_DECLARATION = const HighlightRegionType._("TOP_LEVEL_SETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_SETTER_REFERENCE = const HighlightRegionType._("TOP_LEVEL_SETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType TOP_LEVEL_VARIABLE_DECLARATION = const HighlightRegionType._("TOP_LEVEL_VARIABLE_DECLARATION");

  static const HighlightRegionType TYPE_NAME_DYNAMIC = const HighlightRegionType._("TYPE_NAME_DYNAMIC");

  static const HighlightRegionType TYPE_PARAMETER = const HighlightRegionType._("TYPE_PARAMETER");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType UNRESOLVED_INSTANCE_MEMBER_REFERENCE = const HighlightRegionType._("UNRESOLVED_INSTANCE_MEMBER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const HighlightRegionType VALID_STRING_ESCAPE = const HighlightRegionType._("VALID_STRING_ESCAPE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<HighlightRegionType> VALUES = const <HighlightRegionType>[ANNOTATION, BUILT_IN, CLASS, COMMENT_BLOCK, COMMENT_DOCUMENTATION, COMMENT_END_OF_LINE, CONSTRUCTOR, DIRECTIVE, DYNAMIC_TYPE, DYNAMIC_LOCAL_VARIABLE_DECLARATION, DYNAMIC_LOCAL_VARIABLE_REFERENCE, DYNAMIC_PARAMETER_DECLARATION, DYNAMIC_PARAMETER_REFERENCE, ENUM, ENUM_CONSTANT, FIELD, FIELD_STATIC, FUNCTION, FUNCTION_DECLARATION, FUNCTION_TYPE_ALIAS, GETTER_DECLARATION, IDENTIFIER_DEFAULT, IMPORT_PREFIX, INSTANCE_FIELD_DECLARATION, INSTANCE_FIELD_REFERENCE, INSTANCE_GETTER_DECLARATION, INSTANCE_GETTER_REFERENCE, INSTANCE_METHOD_DECLARATION, INSTANCE_METHOD_REFERENCE, INSTANCE_SETTER_DECLARATION, INSTANCE_SETTER_REFERENCE, INVALID_STRING_ESCAPE, KEYWORD, LABEL, LIBRARY_NAME, LITERAL_BOOLEAN, LITERAL_DOUBLE, LITERAL_INTEGER, LITERAL_LIST, LITERAL_MAP, LITERAL_STRING, LOCAL_FUNCTION_DECLARATION, LOCAL_FUNCTION_REFERENCE, LOCAL_VARIABLE, LOCAL_VARIABLE_DECLARATION, LOCAL_VARIABLE_REFERENCE, METHOD, METHOD_DECLARATION, METHOD_DECLARATION_STATIC, METHOD_STATIC, PARAMETER, SETTER_DECLARATION, TOP_LEVEL_VARIABLE, PARAMETER_DECLARATION, PARAMETER_REFERENCE, STATIC_FIELD_DECLARATION, STATIC_GETTER_DECLARATION, STATIC_GETTER_REFERENCE, STATIC_METHOD_DECLARATION, STATIC_METHOD_REFERENCE, STATIC_SETTER_DECLARATION, STATIC_SETTER_REFERENCE, TOP_LEVEL_FUNCTION_DECLARATION, TOP_LEVEL_FUNCTION_REFERENCE, TOP_LEVEL_GETTER_DECLARATION, TOP_LEVEL_GETTER_REFERENCE, TOP_LEVEL_SETTER_DECLARATION, TOP_LEVEL_SETTER_REFERENCE, TOP_LEVEL_VARIABLE_DECLARATION, TYPE_NAME_DYNAMIC, TYPE_PARAMETER, UNRESOLVED_INSTANCE_MEMBER_REFERENCE, VALID_STRING_ESCAPE];

  @override
  final String name;

  const HighlightRegionType._(this.name);

  factory HighlightRegionType(String name) {
    switch (name) {
      case "ANNOTATION":
        return ANNOTATION;
      case "BUILT_IN":
        return BUILT_IN;
      case "CLASS":
        return CLASS;
      case "COMMENT_BLOCK":
        return COMMENT_BLOCK;
      case "COMMENT_DOCUMENTATION":
        return COMMENT_DOCUMENTATION;
      case "COMMENT_END_OF_LINE":
        return COMMENT_END_OF_LINE;
      case "CONSTRUCTOR":
        return CONSTRUCTOR;
      case "DIRECTIVE":
        return DIRECTIVE;
      case "DYNAMIC_TYPE":
        return DYNAMIC_TYPE;
      case "DYNAMIC_LOCAL_VARIABLE_DECLARATION":
        return DYNAMIC_LOCAL_VARIABLE_DECLARATION;
      case "DYNAMIC_LOCAL_VARIABLE_REFERENCE":
        return DYNAMIC_LOCAL_VARIABLE_REFERENCE;
      case "DYNAMIC_PARAMETER_DECLARATION":
        return DYNAMIC_PARAMETER_DECLARATION;
      case "DYNAMIC_PARAMETER_REFERENCE":
        return DYNAMIC_PARAMETER_REFERENCE;
      case "ENUM":
        return ENUM;
      case "ENUM_CONSTANT":
        return ENUM_CONSTANT;
      case "FIELD":
        return FIELD;
      case "FIELD_STATIC":
        return FIELD_STATIC;
      case "FUNCTION":
        return FUNCTION;
      case "FUNCTION_DECLARATION":
        return FUNCTION_DECLARATION;
      case "FUNCTION_TYPE_ALIAS":
        return FUNCTION_TYPE_ALIAS;
      case "GETTER_DECLARATION":
        return GETTER_DECLARATION;
      case "IDENTIFIER_DEFAULT":
        return IDENTIFIER_DEFAULT;
      case "IMPORT_PREFIX":
        return IMPORT_PREFIX;
      case "INSTANCE_FIELD_DECLARATION":
        return INSTANCE_FIELD_DECLARATION;
      case "INSTANCE_FIELD_REFERENCE":
        return INSTANCE_FIELD_REFERENCE;
      case "INSTANCE_GETTER_DECLARATION":
        return INSTANCE_GETTER_DECLARATION;
      case "INSTANCE_GETTER_REFERENCE":
        return INSTANCE_GETTER_REFERENCE;
      case "INSTANCE_METHOD_DECLARATION":
        return INSTANCE_METHOD_DECLARATION;
      case "INSTANCE_METHOD_REFERENCE":
        return INSTANCE_METHOD_REFERENCE;
      case "INSTANCE_SETTER_DECLARATION":
        return INSTANCE_SETTER_DECLARATION;
      case "INSTANCE_SETTER_REFERENCE":
        return INSTANCE_SETTER_REFERENCE;
      case "INVALID_STRING_ESCAPE":
        return INVALID_STRING_ESCAPE;
      case "KEYWORD":
        return KEYWORD;
      case "LABEL":
        return LABEL;
      case "LIBRARY_NAME":
        return LIBRARY_NAME;
      case "LITERAL_BOOLEAN":
        return LITERAL_BOOLEAN;
      case "LITERAL_DOUBLE":
        return LITERAL_DOUBLE;
      case "LITERAL_INTEGER":
        return LITERAL_INTEGER;
      case "LITERAL_LIST":
        return LITERAL_LIST;
      case "LITERAL_MAP":
        return LITERAL_MAP;
      case "LITERAL_STRING":
        return LITERAL_STRING;
      case "LOCAL_FUNCTION_DECLARATION":
        return LOCAL_FUNCTION_DECLARATION;
      case "LOCAL_FUNCTION_REFERENCE":
        return LOCAL_FUNCTION_REFERENCE;
      case "LOCAL_VARIABLE":
        return LOCAL_VARIABLE;
      case "LOCAL_VARIABLE_DECLARATION":
        return LOCAL_VARIABLE_DECLARATION;
      case "LOCAL_VARIABLE_REFERENCE":
        return LOCAL_VARIABLE_REFERENCE;
      case "METHOD":
        return METHOD;
      case "METHOD_DECLARATION":
        return METHOD_DECLARATION;
      case "METHOD_DECLARATION_STATIC":
        return METHOD_DECLARATION_STATIC;
      case "METHOD_STATIC":
        return METHOD_STATIC;
      case "PARAMETER":
        return PARAMETER;
      case "SETTER_DECLARATION":
        return SETTER_DECLARATION;
      case "TOP_LEVEL_VARIABLE":
        return TOP_LEVEL_VARIABLE;
      case "PARAMETER_DECLARATION":
        return PARAMETER_DECLARATION;
      case "PARAMETER_REFERENCE":
        return PARAMETER_REFERENCE;
      case "STATIC_FIELD_DECLARATION":
        return STATIC_FIELD_DECLARATION;
      case "STATIC_GETTER_DECLARATION":
        return STATIC_GETTER_DECLARATION;
      case "STATIC_GETTER_REFERENCE":
        return STATIC_GETTER_REFERENCE;
      case "STATIC_METHOD_DECLARATION":
        return STATIC_METHOD_DECLARATION;
      case "STATIC_METHOD_REFERENCE":
        return STATIC_METHOD_REFERENCE;
      case "STATIC_SETTER_DECLARATION":
        return STATIC_SETTER_DECLARATION;
      case "STATIC_SETTER_REFERENCE":
        return STATIC_SETTER_REFERENCE;
      case "TOP_LEVEL_FUNCTION_DECLARATION":
        return TOP_LEVEL_FUNCTION_DECLARATION;
      case "TOP_LEVEL_FUNCTION_REFERENCE":
        return TOP_LEVEL_FUNCTION_REFERENCE;
      case "TOP_LEVEL_GETTER_DECLARATION":
        return TOP_LEVEL_GETTER_DECLARATION;
      case "TOP_LEVEL_GETTER_REFERENCE":
        return TOP_LEVEL_GETTER_REFERENCE;
      case "TOP_LEVEL_SETTER_DECLARATION":
        return TOP_LEVEL_SETTER_DECLARATION;
      case "TOP_LEVEL_SETTER_REFERENCE":
        return TOP_LEVEL_SETTER_REFERENCE;
      case "TOP_LEVEL_VARIABLE_DECLARATION":
        return TOP_LEVEL_VARIABLE_DECLARATION;
      case "TYPE_NAME_DYNAMIC":
        return TYPE_NAME_DYNAMIC;
      case "TYPE_PARAMETER":
        return TYPE_PARAMETER;
      case "UNRESOLVED_INSTANCE_MEMBER_REFERENCE":
        return UNRESOLVED_INSTANCE_MEMBER_REFERENCE;
      case "VALID_STRING_ESCAPE":
        return VALID_STRING_ESCAPE;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory HighlightRegionType.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new HighlightRegionType(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "HighlightRegionType", json);
  }

  @override
  String toString() => "HighlightRegionType.$name";

  String toJson() => name;
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

  factory InlineLocalVariableFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        occurrences = jsonDecoder.decodeInt(jsonPath + ".occurrences", json["occurrences"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "occurrences");
      }
      return new InlineLocalVariableFeedback(name, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineLocalVariable feedback", json);
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
  bool operator==(other) {
    if (other is InlineLocalVariableFeedback) {
      return name == other.name &&
          occurrences == other.occurrences;
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
class InlineLocalVariableOptions extends RefactoringOptions implements HasToJson {
  @override
  bool operator==(other) {
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
   * True if the declaration of the method is selected and all references
   * should be inlined.
   */
  bool get isDeclaration => _isDeclaration;

  /**
   * True if the declaration of the method is selected and all references
   * should be inlined.
   */
  void set isDeclaration(bool value) {
    assert(value != null);
    this._isDeclaration = value;
  }

  InlineMethodFeedback(String methodName, bool isDeclaration, {String className}) {
    this.className = className;
    this.methodName = methodName;
    this.isDeclaration = isDeclaration;
  }

  factory InlineMethodFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String className;
      if (json.containsKey("className")) {
        className = jsonDecoder.decodeString(jsonPath + ".className", json["className"]);
      }
      String methodName;
      if (json.containsKey("methodName")) {
        methodName = jsonDecoder.decodeString(jsonPath + ".methodName", json["methodName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "methodName");
      }
      bool isDeclaration;
      if (json.containsKey("isDeclaration")) {
        isDeclaration = jsonDecoder.decodeBool(jsonPath + ".isDeclaration", json["isDeclaration"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isDeclaration");
      }
      return new InlineMethodFeedback(methodName, isDeclaration, className: className);
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
  bool operator==(other) {
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

  factory InlineMethodOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool deleteSource;
      if (json.containsKey("deleteSource")) {
        deleteSource = jsonDecoder.decodeBool(jsonPath + ".deleteSource", json["deleteSource"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "deleteSource");
      }
      bool inlineAll;
      if (json.containsKey("inlineAll")) {
        inlineAll = jsonDecoder.decodeBool(jsonPath + ".inlineAll", json["inlineAll"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "inlineAll");
      }
      return new InlineMethodOptions(deleteSource, inlineAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod options", json);
    }
  }

  factory InlineMethodOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
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
  bool operator==(other) {
    if (other is InlineMethodOptions) {
      return deleteSource == other.deleteSource &&
          inlineAll == other.inlineAll;
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
 * LinkedEditGroup
 *
 * {
 *   "positions": List<Position>
 *   "length": int
 *   "suggestions": List<LinkedEditSuggestion>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class LinkedEditGroup implements HasToJson {
  List<Position> _positions;

  int _length;

  List<LinkedEditSuggestion> _suggestions;

  /**
   * The positions of the regions that should be edited simultaneously.
   */
  List<Position> get positions => _positions;

  /**
   * The positions of the regions that should be edited simultaneously.
   */
  void set positions(List<Position> value) {
    assert(value != null);
    this._positions = value;
  }

  /**
   * The length of the regions that should be edited simultaneously.
   */
  int get length => _length;

  /**
   * The length of the regions that should be edited simultaneously.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * Pre-computed suggestions for what every region might want to be changed
   * to.
   */
  List<LinkedEditSuggestion> get suggestions => _suggestions;

  /**
   * Pre-computed suggestions for what every region might want to be changed
   * to.
   */
  void set suggestions(List<LinkedEditSuggestion> value) {
    assert(value != null);
    this._suggestions = value;
  }

  LinkedEditGroup(List<Position> positions, int length, List<LinkedEditSuggestion> suggestions) {
    this.positions = positions;
    this.length = length;
    this.suggestions = suggestions;
  }

  factory LinkedEditGroup.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<Position> positions;
      if (json.containsKey("positions")) {
        positions = jsonDecoder.decodeList(jsonPath + ".positions", json["positions"], (String jsonPath, Object json) => new Position.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "positions");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      List<LinkedEditSuggestion> suggestions;
      if (json.containsKey("suggestions")) {
        suggestions = jsonDecoder.decodeList(jsonPath + ".suggestions", json["suggestions"], (String jsonPath, Object json) => new LinkedEditSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "suggestions");
      }
      return new LinkedEditGroup(positions, length, suggestions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "LinkedEditGroup", json);
    }
  }

  /**
   * Construct an empty LinkedEditGroup.
   */
  LinkedEditGroup.empty() : this(<Position>[], 0, <LinkedEditSuggestion>[]);

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["positions"] = positions.map((Position value) => value.toJson()).toList();
    result["length"] = length;
    result["suggestions"] = suggestions.map((LinkedEditSuggestion value) => value.toJson()).toList();
    return result;
  }

  /**
   * Add a new position and change the length.
   */
  void addPosition(Position position, int length) {
    positions.add(position);
    this.length = length;
  }

  /**
   * Add a new suggestion.
   */
  void addSuggestion(LinkedEditSuggestion suggestion) {
    suggestions.add(suggestion);
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is LinkedEditGroup) {
      return listEqual(positions, other.positions, (Position a, Position b) => a == b) &&
          length == other.length &&
          listEqual(suggestions, other.suggestions, (LinkedEditSuggestion a, LinkedEditSuggestion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, positions.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, suggestions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * LinkedEditSuggestion
 *
 * {
 *   "value": String
 *   "kind": LinkedEditSuggestionKind
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class LinkedEditSuggestion implements HasToJson {
  String _value;

  LinkedEditSuggestionKind _kind;

  /**
   * The value that could be used to replace all of the linked edit regions.
   */
  String get value => _value;

  /**
   * The value that could be used to replace all of the linked edit regions.
   */
  void set value(String value) {
    assert(value != null);
    this._value = value;
  }

  /**
   * The kind of value being proposed.
   */
  LinkedEditSuggestionKind get kind => _kind;

  /**
   * The kind of value being proposed.
   */
  void set kind(LinkedEditSuggestionKind value) {
    assert(value != null);
    this._kind = value;
  }

  LinkedEditSuggestion(String value, LinkedEditSuggestionKind kind) {
    this.value = value;
    this.kind = kind;
  }

  factory LinkedEditSuggestion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String value;
      if (json.containsKey("value")) {
        value = jsonDecoder.decodeString(jsonPath + ".value", json["value"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "value");
      }
      LinkedEditSuggestionKind kind;
      if (json.containsKey("kind")) {
        kind = new LinkedEditSuggestionKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      return new LinkedEditSuggestion(value, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "LinkedEditSuggestion", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["value"] = value;
    result["kind"] = kind.toJson();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is LinkedEditSuggestion) {
      return value == other.value &&
          kind == other.kind;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * LinkedEditSuggestionKind
 *
 * enum {
 *   METHOD
 *   PARAMETER
 *   TYPE
 *   VARIABLE
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class LinkedEditSuggestionKind implements Enum {
  static const LinkedEditSuggestionKind METHOD = const LinkedEditSuggestionKind._("METHOD");

  static const LinkedEditSuggestionKind PARAMETER = const LinkedEditSuggestionKind._("PARAMETER");

  static const LinkedEditSuggestionKind TYPE = const LinkedEditSuggestionKind._("TYPE");

  static const LinkedEditSuggestionKind VARIABLE = const LinkedEditSuggestionKind._("VARIABLE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<LinkedEditSuggestionKind> VALUES = const <LinkedEditSuggestionKind>[METHOD, PARAMETER, TYPE, VARIABLE];

  @override
  final String name;

  const LinkedEditSuggestionKind._(this.name);

  factory LinkedEditSuggestionKind(String name) {
    switch (name) {
      case "METHOD":
        return METHOD;
      case "PARAMETER":
        return PARAMETER;
      case "TYPE":
        return TYPE;
      case "VARIABLE":
        return VARIABLE;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory LinkedEditSuggestionKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new LinkedEditSuggestionKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "LinkedEditSuggestionKind", json);
  }

  @override
  String toString() => "LinkedEditSuggestionKind.$name";

  String toJson() => name;
}

/**
 * Location
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "startLine": int
 *   "startColumn": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Location implements HasToJson {
  String _file;

  int _offset;

  int _length;

  int _startLine;

  int _startColumn;

  /**
   * The file containing the range.
   */
  String get file => _file;

  /**
   * The file containing the range.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the range.
   */
  int get offset => _offset;

  /**
   * The offset of the range.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the range.
   */
  int get length => _length;

  /**
   * The length of the range.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The one-based index of the line containing the first character of the
   * range.
   */
  int get startLine => _startLine;

  /**
   * The one-based index of the line containing the first character of the
   * range.
   */
  void set startLine(int value) {
    assert(value != null);
    this._startLine = value;
  }

  /**
   * The one-based index of the column containing the first character of the
   * range.
   */
  int get startColumn => _startColumn;

  /**
   * The one-based index of the column containing the first character of the
   * range.
   */
  void set startColumn(int value) {
    assert(value != null);
    this._startColumn = value;
  }

  Location(String file, int offset, int length, int startLine, int startColumn) {
    this.file = file;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
  }

  factory Location.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      int startLine;
      if (json.containsKey("startLine")) {
        startLine = jsonDecoder.decodeInt(jsonPath + ".startLine", json["startLine"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "startLine");
      }
      int startColumn;
      if (json.containsKey("startColumn")) {
        startColumn = jsonDecoder.decodeInt(jsonPath + ".startColumn", json["startColumn"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "startColumn");
      }
      return new Location(file, offset, length, startLine, startColumn);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Location", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    result["startLine"] = startLine;
    result["startColumn"] = startColumn;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is Location) {
      return file == other.file &&
          offset == other.offset &&
          length == other.length &&
          startLine == other.startLine &&
          startColumn == other.startColumn;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = JenkinsSmiHash.combine(hash, startColumn.hashCode);
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
  bool operator==(other) {
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

  factory MoveFileOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String newFile;
      if (json.containsKey("newFile")) {
        newFile = jsonDecoder.decodeString(jsonPath + ".newFile", json["newFile"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "newFile");
      }
      return new MoveFileOptions(newFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "moveFile options", json);
    }
  }

  factory MoveFileOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
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
  bool operator==(other) {
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
 * NavigationRegion
 *
 * {
 *   "offset": int
 *   "length": int
 *   "targets": List<int>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class NavigationRegion implements HasToJson {
  int _offset;

  int _length;

  List<int> _targets;

  /**
   * The offset of the region from which the user can navigate.
   */
  int get offset => _offset;

  /**
   * The offset of the region from which the user can navigate.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region from which the user can navigate.
   */
  int get length => _length;

  /**
   * The length of the region from which the user can navigate.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The indexes of the targets (in the enclosing navigation response) to which
   * the given region is bound. By opening the target, clients can implement
   * one form of navigation. This list cannot be empty.
   */
  List<int> get targets => _targets;

  /**
   * The indexes of the targets (in the enclosing navigation response) to which
   * the given region is bound. By opening the target, clients can implement
   * one form of navigation. This list cannot be empty.
   */
  void set targets(List<int> value) {
    assert(value != null);
    this._targets = value;
  }

  NavigationRegion(int offset, int length, List<int> targets) {
    this.offset = offset;
    this.length = length;
    this.targets = targets;
  }

  factory NavigationRegion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      List<int> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder.decodeList(jsonPath + ".targets", json["targets"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "targets");
      }
      return new NavigationRegion(offset, length, targets);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "NavigationRegion", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    result["targets"] = targets;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is NavigationRegion) {
      return offset == other.offset &&
          length == other.length &&
          listEqual(targets, other.targets, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, targets.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * NavigationTarget
 *
 * {
 *   "kind": ElementKind
 *   "fileIndex": int
 *   "offset": int
 *   "length": int
 *   "startLine": int
 *   "startColumn": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class NavigationTarget implements HasToJson {
  ElementKind _kind;

  int _fileIndex;

  int _offset;

  int _length;

  int _startLine;

  int _startColumn;

  /**
   * The kind of the element.
   */
  ElementKind get kind => _kind;

  /**
   * The kind of the element.
   */
  void set kind(ElementKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The index of the file (in the enclosing navigation response) to navigate
   * to.
   */
  int get fileIndex => _fileIndex;

  /**
   * The index of the file (in the enclosing navigation response) to navigate
   * to.
   */
  void set fileIndex(int value) {
    assert(value != null);
    this._fileIndex = value;
  }

  /**
   * The offset of the region to which the user can navigate.
   */
  int get offset => _offset;

  /**
   * The offset of the region to which the user can navigate.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region to which the user can navigate.
   */
  int get length => _length;

  /**
   * The length of the region to which the user can navigate.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The one-based index of the line containing the first character of the
   * region.
   */
  int get startLine => _startLine;

  /**
   * The one-based index of the line containing the first character of the
   * region.
   */
  void set startLine(int value) {
    assert(value != null);
    this._startLine = value;
  }

  /**
   * The one-based index of the column containing the first character of the
   * region.
   */
  int get startColumn => _startColumn;

  /**
   * The one-based index of the column containing the first character of the
   * region.
   */
  void set startColumn(int value) {
    assert(value != null);
    this._startColumn = value;
  }

  NavigationTarget(ElementKind kind, int fileIndex, int offset, int length, int startLine, int startColumn) {
    this.kind = kind;
    this.fileIndex = fileIndex;
    this.offset = offset;
    this.length = length;
    this.startLine = startLine;
    this.startColumn = startColumn;
  }

  factory NavigationTarget.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      ElementKind kind;
      if (json.containsKey("kind")) {
        kind = new ElementKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      int fileIndex;
      if (json.containsKey("fileIndex")) {
        fileIndex = jsonDecoder.decodeInt(jsonPath + ".fileIndex", json["fileIndex"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "fileIndex");
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
      int startLine;
      if (json.containsKey("startLine")) {
        startLine = jsonDecoder.decodeInt(jsonPath + ".startLine", json["startLine"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "startLine");
      }
      int startColumn;
      if (json.containsKey("startColumn")) {
        startColumn = jsonDecoder.decodeInt(jsonPath + ".startColumn", json["startColumn"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "startColumn");
      }
      return new NavigationTarget(kind, fileIndex, offset, length, startLine, startColumn);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "NavigationTarget", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kind"] = kind.toJson();
    result["fileIndex"] = fileIndex;
    result["offset"] = offset;
    result["length"] = length;
    result["startLine"] = startLine;
    result["startColumn"] = startColumn;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is NavigationTarget) {
      return kind == other.kind &&
          fileIndex == other.fileIndex &&
          offset == other.offset &&
          length == other.length &&
          startLine == other.startLine &&
          startColumn == other.startColumn;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, fileIndex.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = JenkinsSmiHash.combine(hash, startColumn.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * Occurrences
 *
 * {
 *   "element": Element
 *   "offsets": List<int>
 *   "length": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Occurrences implements HasToJson {
  Element _element;

  List<int> _offsets;

  int _length;

  /**
   * The element that was referenced.
   */
  Element get element => _element;

  /**
   * The element that was referenced.
   */
  void set element(Element value) {
    assert(value != null);
    this._element = value;
  }

  /**
   * The offsets of the name of the referenced element within the file.
   */
  List<int> get offsets => _offsets;

  /**
   * The offsets of the name of the referenced element within the file.
   */
  void set offsets(List<int> value) {
    assert(value != null);
    this._offsets = value;
  }

  /**
   * The length of the name of the referenced element.
   */
  int get length => _length;

  /**
   * The length of the name of the referenced element.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  Occurrences(Element element, List<int> offsets, int length) {
    this.element = element;
    this.offsets = offsets;
    this.length = length;
  }

  factory Occurrences.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "element");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder.decodeList(jsonPath + ".offsets", json["offsets"], jsonDecoder.decodeInt);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "offsets");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder.decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "length");
      }
      return new Occurrences(element, offsets, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Occurrences", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["element"] = element.toJson();
    result["offsets"] = offsets;
    result["length"] = length;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is Occurrences) {
      return element == other.element &&
          listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * Outline
 *
 * {
 *   "element": Element
 *   "offset": int
 *   "length": int
 *   "children": optional List<Outline>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Outline implements HasToJson {
  Element _element;

  int _offset;

  int _length;

  List<Outline> _children;

  /**
   * A description of the element represented by this node.
   */
  Element get element => _element;

  /**
   * A description of the element represented by this node.
   */
  void set element(Element value) {
    assert(value != null);
    this._element = value;
  }

  /**
   * The offset of the first character of the element. This is different than
   * the offset in the Element, which is the offset of the name of the element.
   * It can be used, for example, to map locations in the file back to an
   * outline.
   */
  int get offset => _offset;

  /**
   * The offset of the first character of the element. This is different than
   * the offset in the Element, which is the offset of the name of the element.
   * It can be used, for example, to map locations in the file back to an
   * outline.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the element.
   */
  int get length => _length;

  /**
   * The length of the element.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The children of the node. The field will be omitted if the node has no
   * children.
   */
  List<Outline> get children => _children;

  /**
   * The children of the node. The field will be omitted if the node has no
   * children.
   */
  void set children(List<Outline> value) {
    this._children = value;
  }

  Outline(Element element, int offset, int length, {List<Outline> children}) {
    this.element = element;
    this.offset = offset;
    this.length = length;
    this.children = children;
  }

  factory Outline.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "element");
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
      List<Outline> children;
      if (json.containsKey("children")) {
        children = jsonDecoder.decodeList(jsonPath + ".children", json["children"], (String jsonPath, Object json) => new Outline.fromJson(jsonDecoder, jsonPath, json));
      }
      return new Outline(element, offset, length, children: children);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Outline", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["element"] = element.toJson();
    result["offset"] = offset;
    result["length"] = length;
    if (children != null) {
      result["children"] = children.map((Outline value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is Outline) {
      return element == other.element &&
          offset == other.offset &&
          length == other.length &&
          listEqual(children, other.children, (Outline a, Outline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, element.hashCode);
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, children.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * plugin.error params
 *
 * {
 *   "isFatal": bool
 *   "message": String
 *   "stackTrace": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PluginErrorParams implements HasToJson {
  bool _isFatal;

  String _message;

  String _stackTrace;

  /**
   * A flag indicating whether the error is a fatal error, meaning that the
   * plugin will shutdown automatically after sending this notification. If
   * true, the server will not expect any other responses or notifications from
   * the plugin.
   */
  bool get isFatal => _isFatal;

  /**
   * A flag indicating whether the error is a fatal error, meaning that the
   * plugin will shutdown automatically after sending this notification. If
   * true, the server will not expect any other responses or notifications from
   * the plugin.
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
   * debugging the plugin.
   */
  String get stackTrace => _stackTrace;

  /**
   * The stack trace associated with the generation of the error, used for
   * debugging the plugin.
   */
  void set stackTrace(String value) {
    assert(value != null);
    this._stackTrace = value;
  }

  PluginErrorParams(bool isFatal, String message, String stackTrace) {
    this.isFatal = isFatal;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  factory PluginErrorParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isFatal;
      if (json.containsKey("isFatal")) {
        isFatal = jsonDecoder.decodeBool(jsonPath + ".isFatal", json["isFatal"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isFatal");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      String stackTrace;
      if (json.containsKey("stackTrace")) {
        stackTrace = jsonDecoder.decodeString(jsonPath + ".stackTrace", json["stackTrace"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "stackTrace");
      }
      return new PluginErrorParams(isFatal, message, stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "plugin.error params", json);
    }
  }

  factory PluginErrorParams.fromNotification(Notification notification) {
    return new PluginErrorParams.fromJson(
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
    return new Notification("plugin.error", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is PluginErrorParams) {
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
 * plugin.shutdown params
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PluginShutdownParams implements RequestParams {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Request toRequest(String id) {
    return new Request(id, "plugin.shutdown", null);
  }

  @override
  bool operator==(other) {
    if (other is PluginShutdownParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 478064585;
  }
}

/**
 * plugin.shutdown result
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PluginShutdownResult implements ResponseResult {
  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
    if (other is PluginShutdownResult) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 9389109;
  }
}

/**
 * plugin.versionCheck params
 *
 * {
 *   "byteStorePath": String
 *   "version": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PluginVersionCheckParams implements RequestParams {
  String _byteStorePath;

  String _version;

  /**
   * The path to the directory containing the on-disk byte store that is to be
   * used by any analysis drivers that are created.
   */
  String get byteStorePath => _byteStorePath;

  /**
   * The path to the directory containing the on-disk byte store that is to be
   * used by any analysis drivers that are created.
   */
  void set byteStorePath(String value) {
    assert(value != null);
    this._byteStorePath = value;
  }

  /**
   * The version number of the plugin spec supported by the analysis server
   * that is executing the plugin.
   */
  String get version => _version;

  /**
   * The version number of the plugin spec supported by the analysis server
   * that is executing the plugin.
   */
  void set version(String value) {
    assert(value != null);
    this._version = value;
  }

  PluginVersionCheckParams(String byteStorePath, String version) {
    this.byteStorePath = byteStorePath;
    this.version = version;
  }

  factory PluginVersionCheckParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String byteStorePath;
      if (json.containsKey("byteStorePath")) {
        byteStorePath = jsonDecoder.decodeString(jsonPath + ".byteStorePath", json["byteStorePath"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "byteStorePath");
      }
      String version;
      if (json.containsKey("version")) {
        version = jsonDecoder.decodeString(jsonPath + ".version", json["version"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "version");
      }
      return new PluginVersionCheckParams(byteStorePath, version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "plugin.versionCheck params", json);
    }
  }

  factory PluginVersionCheckParams.fromRequest(Request request) {
    return new PluginVersionCheckParams.fromJson(
        new RequestDecoder(request), "params", request.params);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["byteStorePath"] = byteStorePath;
    result["version"] = version;
    return result;
  }

  @override
  Request toRequest(String id) {
    return new Request(id, "plugin.versionCheck", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is PluginVersionCheckParams) {
      return byteStorePath == other.byteStorePath &&
          version == other.version;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, byteStorePath.hashCode);
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * plugin.versionCheck result
 *
 * {
 *   "isCompatible": bool
 *   "name": String
 *   "version": String
 *   "contactInfo": optional String
 *   "interestingFiles": List<String>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PluginVersionCheckResult implements ResponseResult {
  bool _isCompatible;

  String _name;

  String _version;

  String _contactInfo;

  List<String> _interestingFiles;

  /**
   * A flag indicating whether the plugin supports the same version of the
   * plugin spec as the analysis server. If the value is false, then the plugin
   * is expected to shutdown after returning the response.
   */
  bool get isCompatible => _isCompatible;

  /**
   * A flag indicating whether the plugin supports the same version of the
   * plugin spec as the analysis server. If the value is false, then the plugin
   * is expected to shutdown after returning the response.
   */
  void set isCompatible(bool value) {
    assert(value != null);
    this._isCompatible = value;
  }

  /**
   * The name of the plugin. This value is only used when the server needs to
   * identify the plugin, either to the user or for debugging purposes.
   */
  String get name => _name;

  /**
   * The name of the plugin. This value is only used when the server needs to
   * identify the plugin, either to the user or for debugging purposes.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * The version of the plugin. This value is only used when the server needs
   * to identify the plugin, either to the user or for debugging purposes.
   */
  String get version => _version;

  /**
   * The version of the plugin. This value is only used when the server needs
   * to identify the plugin, either to the user or for debugging purposes.
   */
  void set version(String value) {
    assert(value != null);
    this._version = value;
  }

  /**
   * Information that the user can use to use to contact the maintainers of the
   * plugin when there is a problem.
   */
  String get contactInfo => _contactInfo;

  /**
   * Information that the user can use to use to contact the maintainers of the
   * plugin when there is a problem.
   */
  void set contactInfo(String value) {
    this._contactInfo = value;
  }

  /**
   * The glob patterns of the files for which the plugin will provide
   * information. This value is ignored if the isCompatible field is false.
   * Otherwise, it will be used to identify the files for which the plugin
   * should be notified of changes.
   */
  List<String> get interestingFiles => _interestingFiles;

  /**
   * The glob patterns of the files for which the plugin will provide
   * information. This value is ignored if the isCompatible field is false.
   * Otherwise, it will be used to identify the files for which the plugin
   * should be notified of changes.
   */
  void set interestingFiles(List<String> value) {
    assert(value != null);
    this._interestingFiles = value;
  }

  PluginVersionCheckResult(bool isCompatible, String name, String version, List<String> interestingFiles, {String contactInfo}) {
    this.isCompatible = isCompatible;
    this.name = name;
    this.version = version;
    this.contactInfo = contactInfo;
    this.interestingFiles = interestingFiles;
  }

  factory PluginVersionCheckResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isCompatible;
      if (json.containsKey("isCompatible")) {
        isCompatible = jsonDecoder.decodeBool(jsonPath + ".isCompatible", json["isCompatible"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "isCompatible");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      String version;
      if (json.containsKey("version")) {
        version = jsonDecoder.decodeString(jsonPath + ".version", json["version"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "version");
      }
      String contactInfo;
      if (json.containsKey("contactInfo")) {
        contactInfo = jsonDecoder.decodeString(jsonPath + ".contactInfo", json["contactInfo"]);
      }
      List<String> interestingFiles;
      if (json.containsKey("interestingFiles")) {
        interestingFiles = jsonDecoder.decodeList(jsonPath + ".interestingFiles", json["interestingFiles"], jsonDecoder.decodeString);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "interestingFiles");
      }
      return new PluginVersionCheckResult(isCompatible, name, version, interestingFiles, contactInfo: contactInfo);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "plugin.versionCheck result", json);
    }
  }

  factory PluginVersionCheckResult.fromResponse(Response response) {
    return new PluginVersionCheckResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response.result);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["isCompatible"] = isCompatible;
    result["name"] = name;
    result["version"] = version;
    if (contactInfo != null) {
      result["contactInfo"] = contactInfo;
    }
    result["interestingFiles"] = interestingFiles;
    return result;
  }

  @override
  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is PluginVersionCheckResult) {
      return isCompatible == other.isCompatible &&
          name == other.name &&
          version == other.version &&
          contactInfo == other.contactInfo &&
          listEqual(interestingFiles, other.interestingFiles, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, isCompatible.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    hash = JenkinsSmiHash.combine(hash, contactInfo.hashCode);
    hash = JenkinsSmiHash.combine(hash, interestingFiles.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * Position
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Position implements HasToJson {
  String _file;

  int _offset;

  /**
   * The file containing the position.
   */
  String get file => _file;

  /**
   * The file containing the position.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The offset of the position.
   */
  int get offset => _offset;

  /**
   * The offset of the position.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  Position(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

  factory Position.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      return new Position(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Position", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is Position) {
      return file == other.file &&
          offset == other.offset;
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
 * PrioritizedSourceChange
 *
 * {
 *   "priority": int
 *   "change": SourceChange
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class PrioritizedSourceChange implements HasToJson {
  int _priority;

  SourceChange _change;

  /**
   * The priority of the change. The value is expected to be non-negative, and
   * zero (0) is the lowest priority.
   */
  int get priority => _priority;

  /**
   * The priority of the change. The value is expected to be non-negative, and
   * zero (0) is the lowest priority.
   */
  void set priority(int value) {
    assert(value != null);
    this._priority = value;
  }

  /**
   * The change with which the relevance is associated.
   */
  SourceChange get change => _change;

  /**
   * The change with which the relevance is associated.
   */
  void set change(SourceChange value) {
    assert(value != null);
    this._change = value;
  }

  PrioritizedSourceChange(int priority, SourceChange change) {
    this.priority = priority;
    this.change = change;
  }

  factory PrioritizedSourceChange.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int priority;
      if (json.containsKey("priority")) {
        priority = jsonDecoder.decodeInt(jsonPath + ".priority", json["priority"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "priority");
      }
      SourceChange change;
      if (json.containsKey("change")) {
        change = new SourceChange.fromJson(jsonDecoder, jsonPath + ".change", json["change"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "change");
      }
      return new PrioritizedSourceChange(priority, change);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "PrioritizedSourceChange", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["priority"] = priority;
    result["change"] = change.toJson();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is PrioritizedSourceChange) {
      return priority == other.priority &&
          change == other.change;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, priority.hashCode);
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
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

  factory RefactoringFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json, Map responseJson) {
    return refactoringFeedbackFromJson(jsonDecoder, jsonPath, json, responseJson);
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
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
 * RefactoringKind
 *
 * enum {
 *   CONVERT_GETTER_TO_METHOD
 *   CONVERT_METHOD_TO_GETTER
 *   EXTRACT_LOCAL_VARIABLE
 *   EXTRACT_METHOD
 *   INLINE_LOCAL_VARIABLE
 *   INLINE_METHOD
 *   MOVE_FILE
 *   RENAME
 *   SORT_MEMBERS
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringKind implements Enum {
  static const RefactoringKind CONVERT_GETTER_TO_METHOD = const RefactoringKind._("CONVERT_GETTER_TO_METHOD");

  static const RefactoringKind CONVERT_METHOD_TO_GETTER = const RefactoringKind._("CONVERT_METHOD_TO_GETTER");

  static const RefactoringKind EXTRACT_LOCAL_VARIABLE = const RefactoringKind._("EXTRACT_LOCAL_VARIABLE");

  static const RefactoringKind EXTRACT_METHOD = const RefactoringKind._("EXTRACT_METHOD");

  static const RefactoringKind INLINE_LOCAL_VARIABLE = const RefactoringKind._("INLINE_LOCAL_VARIABLE");

  static const RefactoringKind INLINE_METHOD = const RefactoringKind._("INLINE_METHOD");

  static const RefactoringKind MOVE_FILE = const RefactoringKind._("MOVE_FILE");

  static const RefactoringKind RENAME = const RefactoringKind._("RENAME");

  static const RefactoringKind SORT_MEMBERS = const RefactoringKind._("SORT_MEMBERS");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RefactoringKind> VALUES = const <RefactoringKind>[CONVERT_GETTER_TO_METHOD, CONVERT_METHOD_TO_GETTER, EXTRACT_LOCAL_VARIABLE, EXTRACT_METHOD, INLINE_LOCAL_VARIABLE, INLINE_METHOD, MOVE_FILE, RENAME, SORT_MEMBERS];

  @override
  final String name;

  const RefactoringKind._(this.name);

  factory RefactoringKind(String name) {
    switch (name) {
      case "CONVERT_GETTER_TO_METHOD":
        return CONVERT_GETTER_TO_METHOD;
      case "CONVERT_METHOD_TO_GETTER":
        return CONVERT_METHOD_TO_GETTER;
      case "EXTRACT_LOCAL_VARIABLE":
        return EXTRACT_LOCAL_VARIABLE;
      case "EXTRACT_METHOD":
        return EXTRACT_METHOD;
      case "INLINE_LOCAL_VARIABLE":
        return INLINE_LOCAL_VARIABLE;
      case "INLINE_METHOD":
        return INLINE_METHOD;
      case "MOVE_FILE":
        return MOVE_FILE;
      case "RENAME":
        return RENAME;
      case "SORT_MEMBERS":
        return SORT_MEMBERS;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory RefactoringKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new RefactoringKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "RefactoringKind", json);
  }

  @override
  String toString() => "RefactoringKind.$name";

  String toJson() => name;
}

/**
 * RefactoringMethodParameter
 *
 * {
 *   "id": optional String
 *   "kind": RefactoringMethodParameterKind
 *   "type": String
 *   "name": String
 *   "parameters": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringMethodParameter implements HasToJson {
  String _id;

  RefactoringMethodParameterKind _kind;

  String _type;

  String _name;

  String _parameters;

  /**
   * The unique identifier of the parameter. Clients may omit this field for
   * the parameters they want to add.
   */
  String get id => _id;

  /**
   * The unique identifier of the parameter. Clients may omit this field for
   * the parameters they want to add.
   */
  void set id(String value) {
    this._id = value;
  }

  /**
   * The kind of the parameter.
   */
  RefactoringMethodParameterKind get kind => _kind;

  /**
   * The kind of the parameter.
   */
  void set kind(RefactoringMethodParameterKind value) {
    assert(value != null);
    this._kind = value;
  }

  /**
   * The type that should be given to the parameter, or the return type of the
   * parameter's function type.
   */
  String get type => _type;

  /**
   * The type that should be given to the parameter, or the return type of the
   * parameter's function type.
   */
  void set type(String value) {
    assert(value != null);
    this._type = value;
  }

  /**
   * The name that should be given to the parameter.
   */
  String get name => _name;

  /**
   * The name that should be given to the parameter.
   */
  void set name(String value) {
    assert(value != null);
    this._name = value;
  }

  /**
   * The parameter list of the parameter's function type. If the parameter is
   * not of a function type, this field will not be defined. If the function
   * type has zero parameters, this field will have a value of '()'.
   */
  String get parameters => _parameters;

  /**
   * The parameter list of the parameter's function type. If the parameter is
   * not of a function type, this field will not be defined. If the function
   * type has zero parameters, this field will have a value of '()'.
   */
  void set parameters(String value) {
    this._parameters = value;
  }

  RefactoringMethodParameter(RefactoringMethodParameterKind kind, String type, String name, {String id, String parameters}) {
    this.id = id;
    this.kind = kind;
    this.type = type;
    this.name = name;
    this.parameters = parameters;
  }

  factory RefactoringMethodParameter.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      }
      RefactoringMethodParameterKind kind;
      if (json.containsKey("kind")) {
        kind = new RefactoringMethodParameterKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "kind");
      }
      String type;
      if (json.containsKey("type")) {
        type = jsonDecoder.decodeString(jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "type");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder.decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "name");
      }
      String parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder.decodeString(jsonPath + ".parameters", json["parameters"]);
      }
      return new RefactoringMethodParameter(kind, type, name, id: id, parameters: parameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RefactoringMethodParameter", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (id != null) {
      result["id"] = id;
    }
    result["kind"] = kind.toJson();
    result["type"] = type;
    result["name"] = name;
    if (parameters != null) {
      result["parameters"] = parameters;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is RefactoringMethodParameter) {
      return id == other.id &&
          kind == other.kind &&
          type == other.type &&
          name == other.name &&
          parameters == other.parameters;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * RefactoringMethodParameterKind
 *
 * enum {
 *   REQUIRED
 *   POSITIONAL
 *   NAMED
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringMethodParameterKind implements Enum {
  static const RefactoringMethodParameterKind REQUIRED = const RefactoringMethodParameterKind._("REQUIRED");

  static const RefactoringMethodParameterKind POSITIONAL = const RefactoringMethodParameterKind._("POSITIONAL");

  static const RefactoringMethodParameterKind NAMED = const RefactoringMethodParameterKind._("NAMED");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RefactoringMethodParameterKind> VALUES = const <RefactoringMethodParameterKind>[REQUIRED, POSITIONAL, NAMED];

  @override
  final String name;

  const RefactoringMethodParameterKind._(this.name);

  factory RefactoringMethodParameterKind(String name) {
    switch (name) {
      case "REQUIRED":
        return REQUIRED;
      case "POSITIONAL":
        return POSITIONAL;
      case "NAMED":
        return NAMED;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory RefactoringMethodParameterKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new RefactoringMethodParameterKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "RefactoringMethodParameterKind", json);
  }

  @override
  String toString() => "RefactoringMethodParameterKind.$name";

  String toJson() => name;
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

  factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json, RefactoringKind kind) {
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
  bool operator==(other) {
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
 * RefactoringProblem
 *
 * {
 *   "severity": RefactoringProblemSeverity
 *   "message": String
 *   "location": optional Location
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringProblem implements HasToJson {
  RefactoringProblemSeverity _severity;

  String _message;

  Location _location;

  /**
   * The severity of the problem being represented.
   */
  RefactoringProblemSeverity get severity => _severity;

  /**
   * The severity of the problem being represented.
   */
  void set severity(RefactoringProblemSeverity value) {
    assert(value != null);
    this._severity = value;
  }

  /**
   * A human-readable description of the problem being represented.
   */
  String get message => _message;

  /**
   * A human-readable description of the problem being represented.
   */
  void set message(String value) {
    assert(value != null);
    this._message = value;
  }

  /**
   * The location of the problem being represented. This field is omitted
   * unless there is a specific location associated with the problem (such as a
   * location where an element being renamed will be shadowed).
   */
  Location get location => _location;

  /**
   * The location of the problem being represented. This field is omitted
   * unless there is a specific location associated with the problem (such as a
   * location where an element being renamed will be shadowed).
   */
  void set location(Location value) {
    this._location = value;
  }

  RefactoringProblem(RefactoringProblemSeverity severity, String message, {Location location}) {
    this.severity = severity;
    this.message = message;
    this.location = location;
  }

  factory RefactoringProblem.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RefactoringProblemSeverity severity;
      if (json.containsKey("severity")) {
        severity = new RefactoringProblemSeverity.fromJson(jsonDecoder, jsonPath + ".severity", json["severity"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "severity");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      }
      return new RefactoringProblem(severity, message, location: location);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RefactoringProblem", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["severity"] = severity.toJson();
    result["message"] = message;
    if (location != null) {
      result["location"] = location.toJson();
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is RefactoringProblem) {
      return severity == other.severity &&
          message == other.message &&
          location == other.location;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * RefactoringProblemSeverity
 *
 * enum {
 *   INFO
 *   WARNING
 *   ERROR
 *   FATAL
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RefactoringProblemSeverity implements Enum {
  /**
   * A minor code problem. No example, because it is not used yet.
   */
  static const RefactoringProblemSeverity INFO = const RefactoringProblemSeverity._("INFO");

  /**
   * A minor code problem. For example names of local variables should be camel
   * case and start with a lower case letter. Staring the name of a variable
   * with an upper case is OK from the language point of view, but it is nice
   * to warn the user.
   */
  static const RefactoringProblemSeverity WARNING = const RefactoringProblemSeverity._("WARNING");

  /**
   * The refactoring technically can be performed, but there is a logical
   * problem. For example the name of a local variable being extracted
   * conflicts with another name in the scope, or duplicate parameter names in
   * the method being extracted, or a conflict between a parameter name and a
   * local variable, etc. In some cases the location of the problem is also
   * provided, so the IDE can show user the location and the problem, and let
   * the user decide whether they want to perform the refactoring. For example
   * the name conflict might be expected, and the user wants to fix it
   * afterwards.
   */
  static const RefactoringProblemSeverity ERROR = const RefactoringProblemSeverity._("ERROR");

  /**
   * A fatal error, which prevents performing the refactoring. For example the
   * name of a local variable being extracted is not a valid identifier, or
   * selection is not a valid expression.
   */
  static const RefactoringProblemSeverity FATAL = const RefactoringProblemSeverity._("FATAL");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RefactoringProblemSeverity> VALUES = const <RefactoringProblemSeverity>[INFO, WARNING, ERROR, FATAL];

  @override
  final String name;

  const RefactoringProblemSeverity._(this.name);

  factory RefactoringProblemSeverity(String name) {
    switch (name) {
      case "INFO":
        return INFO;
      case "WARNING":
        return WARNING;
      case "ERROR":
        return ERROR;
      case "FATAL":
        return FATAL;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory RefactoringProblemSeverity.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new RefactoringProblemSeverity(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "RefactoringProblemSeverity", json);
  }

  /**
   * Returns the [RefactoringProblemSeverity] with the maximal severity.
   */
  static RefactoringProblemSeverity max(RefactoringProblemSeverity a, RefactoringProblemSeverity b) =>
      maxRefactoringProblemSeverity(a, b);

  @override
  String toString() => "RefactoringProblemSeverity.$name";

  String toJson() => name;
}

/**
 * RemoveContentOverlay
 *
 * {
 *   "type": "remove"
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RemoveContentOverlay implements HasToJson {
  RemoveContentOverlay();

  factory RemoveContentOverlay.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      if (json["type"] != "remove") {
        throw jsonDecoder.mismatch(jsonPath, "equal " + "remove", json);
      }
      return new RemoveContentOverlay();
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RemoveContentOverlay", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["type"] = "remove";
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is RemoveContentOverlay) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, 114870849);
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
   * as “class” or “function type alias”).
   */
  String get elementKindName => _elementKindName;

  /**
   * The human-readable description of the kind of element being renamed (such
   * as “class” or “function type alias”).
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

  RenameFeedback(int offset, int length, String elementKindName, String oldName) {
    this.offset = offset;
    this.length = length;
    this.elementKindName = elementKindName;
    this.oldName = oldName;
  }

  factory RenameFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
        elementKindName = jsonDecoder.decodeString(jsonPath + ".elementKindName", json["elementKindName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "elementKindName");
      }
      String oldName;
      if (json.containsKey("oldName")) {
        oldName = jsonDecoder.decodeString(jsonPath + ".oldName", json["oldName"]);
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
  bool operator==(other) {
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

  factory RenameOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String newName;
      if (json.containsKey("newName")) {
        newName = jsonDecoder.decodeString(jsonPath + ".newName", json["newName"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "newName");
      }
      return new RenameOptions(newName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "rename options", json);
    }
  }

  factory RenameOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
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
  bool operator==(other) {
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
   * the plugin.
   */
  String get stackTrace => _stackTrace;

  /**
   * The stack trace associated with processing the request, used for debugging
   * the plugin.
   */
  void set stackTrace(String value) {
    this._stackTrace = value;
  }

  RequestError(RequestErrorCode code, String message, {String stackTrace}) {
    this.code = code;
    this.message = message;
    this.stackTrace = stackTrace;
  }

  factory RequestError.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RequestErrorCode code;
      if (json.containsKey("code")) {
        code = new RequestErrorCode.fromJson(jsonDecoder, jsonPath + ".code", json["code"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "code");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      String stackTrace;
      if (json.containsKey("stackTrace")) {
        stackTrace = jsonDecoder.decodeString(jsonPath + ".stackTrace", json["stackTrace"]);
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
  bool operator==(other) {
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
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   PLUGIN_ERROR
 *   UNKNOWN_REQUEST
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class RequestErrorCode implements Enum {
  /**
   * An "analysis.updateContent" request contained a ChangeContentOverlay
   * object that can't be applied. This can happen for two reasons:
   *
   * - there was no preceding AddContentOverlay and hence no content to which
   *   the edits could be applied, or
   * - one or more of the specified edits have an offset or length that is out
   *   of range.
   */
  static const RequestErrorCode INVALID_OVERLAY_CHANGE = const RequestErrorCode._("INVALID_OVERLAY_CHANGE");

  /**
   * One of the method parameters was invalid.
   */
  static const RequestErrorCode INVALID_PARAMETER = const RequestErrorCode._("INVALID_PARAMETER");

  /**
   * An internal error occurred in the plugin while attempting to respond to a
   * request. Also see the plugin.error notification for errors that occur
   * outside of handling a request.
   */
  static const RequestErrorCode PLUGIN_ERROR = const RequestErrorCode._("PLUGIN_ERROR");

  /**
   * A request was received that the plugin does not recognize, or cannot
   * handle in its current configuration.
   */
  static const RequestErrorCode UNKNOWN_REQUEST = const RequestErrorCode._("UNKNOWN_REQUEST");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RequestErrorCode> VALUES = const <RequestErrorCode>[INVALID_OVERLAY_CHANGE, INVALID_PARAMETER, PLUGIN_ERROR, UNKNOWN_REQUEST];

  @override
  final String name;

  const RequestErrorCode._(this.name);

  factory RequestErrorCode(String name) {
    switch (name) {
      case "INVALID_OVERLAY_CHANGE":
        return INVALID_OVERLAY_CHANGE;
      case "INVALID_PARAMETER":
        return INVALID_PARAMETER;
      case "PLUGIN_ERROR":
        return PLUGIN_ERROR;
      case "UNKNOWN_REQUEST":
        return UNKNOWN_REQUEST;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory RequestErrorCode.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new RequestErrorCode(json);
      } catch(_) {
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
 * SourceChange
 *
 * {
 *   "message": String
 *   "edits": List<SourceFileEdit>
 *   "linkedEditGroups": List<LinkedEditGroup>
 *   "selection": optional Position
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SourceChange implements HasToJson {
  String _message;

  List<SourceFileEdit> _edits;

  List<LinkedEditGroup> _linkedEditGroups;

  Position _selection;

  /**
   * A human-readable description of the change to be applied.
   */
  String get message => _message;

  /**
   * A human-readable description of the change to be applied.
   */
  void set message(String value) {
    assert(value != null);
    this._message = value;
  }

  /**
   * A list of the edits used to effect the change, grouped by file.
   */
  List<SourceFileEdit> get edits => _edits;

  /**
   * A list of the edits used to effect the change, grouped by file.
   */
  void set edits(List<SourceFileEdit> value) {
    assert(value != null);
    this._edits = value;
  }

  /**
   * A list of the linked editing groups used to customize the changes that
   * were made.
   */
  List<LinkedEditGroup> get linkedEditGroups => _linkedEditGroups;

  /**
   * A list of the linked editing groups used to customize the changes that
   * were made.
   */
  void set linkedEditGroups(List<LinkedEditGroup> value) {
    assert(value != null);
    this._linkedEditGroups = value;
  }

  /**
   * The position that should be selected after the edits have been applied.
   */
  Position get selection => _selection;

  /**
   * The position that should be selected after the edits have been applied.
   */
  void set selection(Position value) {
    this._selection = value;
  }

  SourceChange(String message, {List<SourceFileEdit> edits, List<LinkedEditGroup> linkedEditGroups, Position selection}) {
    this.message = message;
    if (edits == null) {
      this.edits = <SourceFileEdit>[];
    } else {
      this.edits = edits;
    }
    if (linkedEditGroups == null) {
      this.linkedEditGroups = <LinkedEditGroup>[];
    } else {
      this.linkedEditGroups = linkedEditGroups;
    }
    this.selection = selection;
  }

  factory SourceChange.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder.decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "message");
      }
      List<SourceFileEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder.decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edits");
      }
      List<LinkedEditGroup> linkedEditGroups;
      if (json.containsKey("linkedEditGroups")) {
        linkedEditGroups = jsonDecoder.decodeList(jsonPath + ".linkedEditGroups", json["linkedEditGroups"], (String jsonPath, Object json) => new LinkedEditGroup.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "linkedEditGroups");
      }
      Position selection;
      if (json.containsKey("selection")) {
        selection = new Position.fromJson(jsonDecoder, jsonPath + ".selection", json["selection"]);
      }
      return new SourceChange(message, edits: edits, linkedEditGroups: linkedEditGroups, selection: selection);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SourceChange", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["message"] = message;
    result["edits"] = edits.map((SourceFileEdit value) => value.toJson()).toList();
    result["linkedEditGroups"] = linkedEditGroups.map((LinkedEditGroup value) => value.toJson()).toList();
    if (selection != null) {
      result["selection"] = selection.toJson();
    }
    return result;
  }

  /**
   * Adds [edit] to the [FileEdit] for the given [file].
   */
  void addEdit(String file, int fileStamp, SourceEdit edit) =>
      addEditToSourceChange(this, file, fileStamp, edit);

  /**
   * Adds the given [FileEdit].
   */
  void addFileEdit(SourceFileEdit edit) {
    edits.add(edit);
  }

  /**
   * Adds the given [LinkedEditGroup].
   */
  void addLinkedEditGroup(LinkedEditGroup linkedEditGroup) {
    linkedEditGroups.add(linkedEditGroup);
  }

  /**
   * Returns the [FileEdit] for the given [file], maybe `null`.
   */
  SourceFileEdit getFileEdit(String file) =>
      getChangeFileEdit(this, file);

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SourceChange) {
      return message == other.message &&
          listEqual(edits, other.edits, (SourceFileEdit a, SourceFileEdit b) => a == b) &&
          listEqual(linkedEditGroups, other.linkedEditGroups, (LinkedEditGroup a, LinkedEditGroup b) => a == b) &&
          selection == other.selection;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = JenkinsSmiHash.combine(hash, linkedEditGroups.hashCode);
    hash = JenkinsSmiHash.combine(hash, selection.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * SourceEdit
 *
 * {
 *   "offset": int
 *   "length": int
 *   "replacement": String
 *   "id": optional String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SourceEdit implements HasToJson {
  /**
   * Get the result of applying a set of [edits] to the given [code]. Edits are
   * applied in the order they appear in [edits].
   */
  static String applySequence(String code, Iterable<SourceEdit> edits) =>
      applySequenceOfEdits(code, edits);

  int _offset;

  int _length;

  String _replacement;

  String _id;

  /**
   * The offset of the region to be modified.
   */
  int get offset => _offset;

  /**
   * The offset of the region to be modified.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the region to be modified.
   */
  int get length => _length;

  /**
   * The length of the region to be modified.
   */
  void set length(int value) {
    assert(value != null);
    this._length = value;
  }

  /**
   * The code that is to replace the specified region in the original code.
   */
  String get replacement => _replacement;

  /**
   * The code that is to replace the specified region in the original code.
   */
  void set replacement(String value) {
    assert(value != null);
    this._replacement = value;
  }

  /**
   * An identifier that uniquely identifies this source edit from other edits
   * in the same response. This field is omitted unless a containing structure
   * needs to be able to identify the edit for some reason.
   *
   * For example, some refactoring operations can produce edits that might not
   * be appropriate (referred to as potential edits). Such edits will have an
   * id so that they can be referenced. Edits in the same response that do not
   * need to be referenced will not have an id.
   */
  String get id => _id;

  /**
   * An identifier that uniquely identifies this source edit from other edits
   * in the same response. This field is omitted unless a containing structure
   * needs to be able to identify the edit for some reason.
   *
   * For example, some refactoring operations can produce edits that might not
   * be appropriate (referred to as potential edits). Such edits will have an
   * id so that they can be referenced. Edits in the same response that do not
   * need to be referenced will not have an id.
   */
  void set id(String value) {
    this._id = value;
  }

  SourceEdit(int offset, int length, String replacement, {String id}) {
    this.offset = offset;
    this.length = length;
    this.replacement = replacement;
    this.id = id;
  }

  factory SourceEdit.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      String replacement;
      if (json.containsKey("replacement")) {
        replacement = jsonDecoder.decodeString(jsonPath + ".replacement", json["replacement"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "replacement");
      }
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder.decodeString(jsonPath + ".id", json["id"]);
      }
      return new SourceEdit(offset, length, replacement, id: id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SourceEdit", json);
    }
  }

  /**
   * The end of the region to be modified.
   */
  int get end => offset + length;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    result["replacement"] = replacement;
    if (id != null) {
      result["id"] = id;
    }
    return result;
  }

  /**
   * Get the result of applying the edit to the given [code].
   */
  String apply(String code) => applyEdit(code, this);

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SourceEdit) {
      return offset == other.offset &&
          length == other.length &&
          replacement == other.replacement &&
          id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = JenkinsSmiHash.combine(hash, length.hashCode);
    hash = JenkinsSmiHash.combine(hash, replacement.hashCode);
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * SourceFileEdit
 *
 * {
 *   "file": FilePath
 *   "fileStamp": long
 *   "edits": List<SourceEdit>
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class SourceFileEdit implements HasToJson {
  String _file;

  int _fileStamp;

  List<SourceEdit> _edits;

  /**
   * The file containing the code to be modified.
   */
  String get file => _file;

  /**
   * The file containing the code to be modified.
   */
  void set file(String value) {
    assert(value != null);
    this._file = value;
  }

  /**
   * The modification stamp of the file at the moment when the change was
   * created, in milliseconds since the "Unix epoch". Will be -1 if the file
   * did not exist and should be created. The client may use this field to make
   * sure that the file was not changed since then, so it is safe to apply the
   * change.
   */
  int get fileStamp => _fileStamp;

  /**
   * The modification stamp of the file at the moment when the change was
   * created, in milliseconds since the "Unix epoch". Will be -1 if the file
   * did not exist and should be created. The client may use this field to make
   * sure that the file was not changed since then, so it is safe to apply the
   * change.
   */
  void set fileStamp(int value) {
    assert(value != null);
    this._fileStamp = value;
  }

  /**
   * A list of the edits used to effect the change.
   */
  List<SourceEdit> get edits => _edits;

  /**
   * A list of the edits used to effect the change.
   */
  void set edits(List<SourceEdit> value) {
    assert(value != null);
    this._edits = value;
  }

  SourceFileEdit(String file, int fileStamp, {List<SourceEdit> edits}) {
    this.file = file;
    this.fileStamp = fileStamp;
    if (edits == null) {
      this.edits = <SourceEdit>[];
    } else {
      this.edits = edits;
    }
  }

  factory SourceFileEdit.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      int fileStamp;
      if (json.containsKey("fileStamp")) {
        fileStamp = jsonDecoder.decodeInt(jsonPath + ".fileStamp", json["fileStamp"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "fileStamp");
      }
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder.decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.mismatch(jsonPath, "edits");
      }
      return new SourceFileEdit(file, fileStamp, edits: edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SourceFileEdit", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["fileStamp"] = fileStamp;
    result["edits"] = edits.map((SourceEdit value) => value.toJson()).toList();
    return result;
  }

  /**
   * Adds the given [Edit] to the list.
   */
  void add(SourceEdit edit) => addEditForSource(this, edit);

  /**
   * Adds the given [Edit]s.
   */
  void addAll(Iterable<SourceEdit> edits) =>
      addAllEditsForSource(this, edits);

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SourceFileEdit) {
      return file == other.file &&
          fileStamp == other.fileStamp &&
          listEqual(edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, file.hashCode);
    hash = JenkinsSmiHash.combine(hash, fileStamp.hashCode);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * WatchEvent
 *
 * {
 *   "type": WatchEventType
 *   "path": String
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class WatchEvent implements HasToJson {
  WatchEventType _type;

  String _path;

  /**
   * The type of change represented by this event.
   */
  WatchEventType get type => _type;

  /**
   * The type of change represented by this event.
   */
  void set type(WatchEventType value) {
    assert(value != null);
    this._type = value;
  }

  /**
   * The absolute path of the file or directory that changed.
   */
  String get path => _path;

  /**
   * The absolute path of the file or directory that changed.
   */
  void set path(String value) {
    assert(value != null);
    this._path = value;
  }

  WatchEvent(WatchEventType type, String path) {
    this.type = type;
    this.path = path;
  }

  factory WatchEvent.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      WatchEventType type;
      if (json.containsKey("type")) {
        type = new WatchEventType.fromJson(jsonDecoder, jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "type");
      }
      String path;
      if (json.containsKey("path")) {
        path = jsonDecoder.decodeString(jsonPath + ".path", json["path"]);
      } else {
        throw jsonDecoder.mismatch(jsonPath, "path");
      }
      return new WatchEvent(type, path);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "WatchEvent", json);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["type"] = type.toJson();
    result["path"] = path;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is WatchEvent) {
      return type == other.type &&
          path == other.path;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, path.hashCode);
    return JenkinsSmiHash.finish(hash);
  }
}

/**
 * WatchEventType
 *
 * enum {
 *   ADD
 *   MODIFY
 *   REMOVE
 * }
 *
 * Clients may not extend, implement or mix-in this class.
 */
class WatchEventType implements Enum {
  /**
   * An indication that the file or directory was added.
   */
  static const WatchEventType ADD = const WatchEventType._("ADD");

  /**
   * An indication that the file was modified.
   */
  static const WatchEventType MODIFY = const WatchEventType._("MODIFY");

  /**
   * An indication that the file or directory was removed.
   */
  static const WatchEventType REMOVE = const WatchEventType._("REMOVE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<WatchEventType> VALUES = const <WatchEventType>[ADD, MODIFY, REMOVE];

  @override
  final String name;

  const WatchEventType._(this.name);

  factory WatchEventType(String name) {
    switch (name) {
      case "ADD":
        return ADD;
      case "MODIFY":
        return MODIFY;
      case "REMOVE":
        return REMOVE;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory WatchEventType.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new WatchEventType(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "WatchEventType", json);
  }

  @override
  String toString() => "WatchEventType.$name";

  String toJson() => name;
}
