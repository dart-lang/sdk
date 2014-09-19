// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

part of protocol;
/**
 * server.getVersion params
 */
class ServerGetVersionParams {
  Request toRequest(String id) {
    return new Request(id, "server.getVersion", null);
  }

  @override
  bool operator==(other) {
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
 */
class ServerGetVersionResult implements HasToJson {
  /**
   * The version number of the analysis server.
   */
  String version;

  ServerGetVersionResult(this.version);

  factory ServerGetVersionResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String version;
      if (json.containsKey("version")) {
        version = jsonDecoder._decodeString(jsonPath + ".version", json["version"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "version");
      }
      return new ServerGetVersionResult(version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.getVersion result");
    }
  }

  factory ServerGetVersionResult.fromResponse(Response response) {
    return new ServerGetVersionResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["version"] = version;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ServerGetVersionResult) {
      return version == other.version;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, version.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * server.shutdown params
 */
class ServerShutdownParams {
  Request toRequest(String id) {
    return new Request(id, "server.shutdown", null);
  }

  @override
  bool operator==(other) {
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
 */
class ServerShutdownResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 * server.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ServerService>
 * }
 */
class ServerSetSubscriptionsParams implements HasToJson {
  /**
   * A list of the services being subscribed to.
   */
  List<ServerService> subscriptions;

  ServerSetSubscriptionsParams(this.subscriptions);

  factory ServerSetSubscriptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ServerService> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder._decodeList(jsonPath + ".subscriptions", json["subscriptions"], (String jsonPath, Object json) => new ServerService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "subscriptions");
      }
      return new ServerSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.setSubscriptions params");
    }
  }

  factory ServerSetSubscriptionsParams.fromRequest(Request request) {
    return new ServerSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = subscriptions.map((ServerService value) => value.toJson()).toList();
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "server.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ServerSetSubscriptionsParams) {
      return _listEqual(subscriptions, other.subscriptions, (ServerService a, ServerService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * server.setSubscriptions result
 */
class ServerSetSubscriptionsResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 * server.connected params
 */
class ServerConnectedParams {
  Notification toNotification() {
    return new Notification("server.connected", null);
  }

  @override
  bool operator==(other) {
    if (other is ServerConnectedParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    return 509239412;
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
 */
class ServerErrorParams implements HasToJson {
  /**
   * True if the error is a fatal error, meaning that the server will shutdown
   * automatically after sending this notification.
   */
  bool isFatal;

  /**
   * The error message indicating what kind of error was encountered.
   */
  String message;

  /**
   * The stack trace associated with the generation of the error, used for
   * debugging the server.
   */
  String stackTrace;

  ServerErrorParams(this.isFatal, this.message, this.stackTrace);

  factory ServerErrorParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isFatal;
      if (json.containsKey("isFatal")) {
        isFatal = jsonDecoder._decodeBool(jsonPath + ".isFatal", json["isFatal"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isFatal");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder._decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "message");
      }
      String stackTrace;
      if (json.containsKey("stackTrace")) {
        stackTrace = jsonDecoder._decodeString(jsonPath + ".stackTrace", json["stackTrace"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "stackTrace");
      }
      return new ServerErrorParams(isFatal, message, stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.error params");
    }
  }

  factory ServerErrorParams.fromNotification(Notification notification) {
    return new ServerErrorParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
  bool operator==(other) {
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
    hash = _JenkinsSmiHash.combine(hash, isFatal.hashCode);
    hash = _JenkinsSmiHash.combine(hash, message.hashCode);
    hash = _JenkinsSmiHash.combine(hash, stackTrace.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * server.status params
 *
 * {
 *   "analysis": optional AnalysisStatus
 * }
 */
class ServerStatusParams implements HasToJson {
  /**
   * The current status of analysis, including whether analysis is being
   * performed and if so what is being analyzed.
   */
  AnalysisStatus analysis;

  ServerStatusParams({this.analysis});

  factory ServerStatusParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisStatus analysis;
      if (json.containsKey("analysis")) {
        analysis = new AnalysisStatus.fromJson(jsonDecoder, jsonPath + ".analysis", json["analysis"]);
      }
      return new ServerStatusParams(analysis: analysis);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.status params");
    }
  }

  factory ServerStatusParams.fromNotification(Notification notification) {
    return new ServerStatusParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (analysis != null) {
      result["analysis"] = analysis.toJson();
    }
    return result;
  }

  Notification toNotification() {
    return new Notification("server.status", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ServerStatusParams) {
      return analysis == other.analysis;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, analysis.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getErrors params
 *
 * {
 *   "file": FilePath
 * }
 */
class AnalysisGetErrorsParams implements HasToJson {
  /**
   * The file for which errors are being requested.
   */
  String file;

  AnalysisGetErrorsParams(this.file);

  factory AnalysisGetErrorsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      return new AnalysisGetErrorsParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getErrors params");
    }
  }

  factory AnalysisGetErrorsParams.fromRequest(Request request) {
    return new AnalysisGetErrorsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.getErrors", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisGetErrorsParams) {
      return file == other.file;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getErrors result
 *
 * {
 *   "errors": List<AnalysisError>
 * }
 */
class AnalysisGetErrorsResult implements HasToJson {
  /**
   * The errors associated with the file.
   */
  List<AnalysisError> errors;

  AnalysisGetErrorsResult(this.errors);

  factory AnalysisGetErrorsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<AnalysisError> errors;
      if (json.containsKey("errors")) {
        errors = jsonDecoder._decodeList(jsonPath + ".errors", json["errors"], (String jsonPath, Object json) => new AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "errors");
      }
      return new AnalysisGetErrorsResult(errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getErrors result");
    }
  }

  factory AnalysisGetErrorsResult.fromResponse(Response response) {
    return new AnalysisGetErrorsResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["errors"] = errors.map((AnalysisError value) => value.toJson()).toList();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisGetErrorsResult) {
      return _listEqual(errors, other.errors, (AnalysisError a, AnalysisError b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, errors.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getHover params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
class AnalysisGetHoverParams implements HasToJson {
  /**
   * The file in which hover information is being requested.
   */
  String file;

  /**
   * The offset for which hover information is being requested.
   */
  int offset;

  AnalysisGetHoverParams(this.file, this.offset);

  factory AnalysisGetHoverParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      return new AnalysisGetHoverParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getHover params");
    }
  }

  factory AnalysisGetHoverParams.fromRequest(Request request) {
    return new AnalysisGetHoverParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.getHover", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisGetHoverParams) {
      return file == other.file &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.getHover result
 *
 * {
 *   "hovers": List<HoverInformation>
 * }
 */
class AnalysisGetHoverResult implements HasToJson {
  /**
   * The hover information associated with the location. The list will be empty
   * if no information could be determined for the location. The list can
   * contain multiple items if the file is being analyzed in multiple contexts
   * in conflicting ways (such as a part that is included in multiple
   * libraries).
   */
  List<HoverInformation> hovers;

  AnalysisGetHoverResult(this.hovers);

  factory AnalysisGetHoverResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<HoverInformation> hovers;
      if (json.containsKey("hovers")) {
        hovers = jsonDecoder._decodeList(jsonPath + ".hovers", json["hovers"], (String jsonPath, Object json) => new HoverInformation.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "hovers");
      }
      return new AnalysisGetHoverResult(hovers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getHover result");
    }
  }

  factory AnalysisGetHoverResult.fromResponse(Response response) {
    return new AnalysisGetHoverResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["hovers"] = hovers.map((HoverInformation value) => value.toJson()).toList();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisGetHoverResult) {
      return _listEqual(hovers, other.hovers, (HoverInformation a, HoverInformation b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, hovers.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * analysis.reanalyze params
 */
class AnalysisReanalyzeParams {
  Request toRequest(String id) {
    return new Request(id, "analysis.reanalyze", null);
  }

  @override
  bool operator==(other) {
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
/**
 * analysis.reanalyze result
 */
class AnalysisReanalyzeResult {
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
 * analysis.setAnalysisRoots params
 *
 * {
 *   "included": List<FilePath>
 *   "excluded": List<FilePath>
 * }
 */
class AnalysisSetAnalysisRootsParams implements HasToJson {
  /**
   * A list of the files and directories that should be analyzed.
   */
  List<String> included;

  /**
   * A list of the files and directories within the included directories that
   * should not be analyzed.
   */
  List<String> excluded;

  AnalysisSetAnalysisRootsParams(this.included, this.excluded);

  factory AnalysisSetAnalysisRootsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> included;
      if (json.containsKey("included")) {
        included = jsonDecoder._decodeList(jsonPath + ".included", json["included"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "included");
      }
      List<String> excluded;
      if (json.containsKey("excluded")) {
        excluded = jsonDecoder._decodeList(jsonPath + ".excluded", json["excluded"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "excluded");
      }
      return new AnalysisSetAnalysisRootsParams(included, excluded);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setAnalysisRoots params");
    }
  }

  factory AnalysisSetAnalysisRootsParams.fromRequest(Request request) {
    return new AnalysisSetAnalysisRootsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["included"] = included;
    result["excluded"] = excluded;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.setAnalysisRoots", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetAnalysisRootsParams) {
      return _listEqual(included, other.included, (String a, String b) => a == b) &&
          _listEqual(excluded, other.excluded, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, included.hashCode);
    hash = _JenkinsSmiHash.combine(hash, excluded.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * analysis.setAnalysisRoots result
 */
class AnalysisSetAnalysisRootsResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 * analysis.setPriorityFiles params
 *
 * {
 *   "files": List<FilePath>
 * }
 */
class AnalysisSetPriorityFilesParams implements HasToJson {
  /**
   * The files that are to be a priority for analysis.
   */
  List<String> files;

  AnalysisSetPriorityFilesParams(this.files);

  factory AnalysisSetPriorityFilesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder._decodeList(jsonPath + ".files", json["files"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "files");
      }
      return new AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setPriorityFiles params");
    }
  }

  factory AnalysisSetPriorityFilesParams.fromRequest(Request request) {
    return new AnalysisSetPriorityFilesParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = files;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.setPriorityFiles", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetPriorityFilesParams) {
      return _listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, files.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * analysis.setPriorityFiles result
 */
class AnalysisSetPriorityFilesResult {
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
 */
class AnalysisSetSubscriptionsParams implements HasToJson {
  /**
   * A table mapping services to a list of the files being subscribed to the
   * service.
   */
  Map<AnalysisService, List<String>> subscriptions;

  AnalysisSetSubscriptionsParams(this.subscriptions);

  factory AnalysisSetSubscriptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<AnalysisService, List<String>> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder._decodeMap(jsonPath + ".subscriptions", json["subscriptions"], keyDecoder: (String jsonPath, Object json) => new AnalysisService.fromJson(jsonDecoder, jsonPath, json), valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeList(jsonPath, json, jsonDecoder._decodeString));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "subscriptions");
      }
      return new AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setSubscriptions params");
    }
  }

  factory AnalysisSetSubscriptionsParams.fromRequest(Request request) {
    return new AnalysisSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = mapMap(subscriptions, keyCallback: (AnalysisService value) => value.toJson());
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetSubscriptionsParams) {
      return _mapEqual(subscriptions, other.subscriptions, (List<String> a, List<String> b) => _listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * analysis.setSubscriptions result
 */
class AnalysisSetSubscriptionsResult {
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
 */
class AnalysisUpdateContentParams implements HasToJson {
  /**
   * A table mapping the files whose content has changed to a description of
   * the content change.
   */
  Map<String, dynamic> files;

  AnalysisUpdateContentParams(this.files);

  factory AnalysisUpdateContentParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Map<String, dynamic> files;
      if (json.containsKey("files")) {
        files = jsonDecoder._decodeMap(jsonPath + ".files", json["files"], valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeUnion(jsonPath, json, "type", {"add": (String jsonPath, Object json) => new AddContentOverlay.fromJson(jsonDecoder, jsonPath, json), "change": (String jsonPath, Object json) => new ChangeContentOverlay.fromJson(jsonDecoder, jsonPath, json), "remove": (String jsonPath, Object json) => new RemoveContentOverlay.fromJson(jsonDecoder, jsonPath, json)}));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "files");
      }
      return new AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.updateContent params");
    }
  }

  factory AnalysisUpdateContentParams.fromRequest(Request request) {
    return new AnalysisUpdateContentParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = mapMap(files, valueCallback: (dynamic value) => value.toJson());
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.updateContent", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisUpdateContentParams) {
      return _mapEqual(files, other.files, (dynamic a, dynamic b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, files.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * analysis.updateContent result
 */
class AnalysisUpdateContentResult {
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
 * analysis.updateOptions params
 *
 * {
 *   "options": AnalysisOptions
 * }
 */
class AnalysisUpdateOptionsParams implements HasToJson {
  /**
   * The options that are to be used to control analysis.
   */
  AnalysisOptions options;

  AnalysisUpdateOptionsParams(this.options);

  factory AnalysisUpdateOptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisOptions options;
      if (json.containsKey("options")) {
        options = new AnalysisOptions.fromJson(jsonDecoder, jsonPath + ".options", json["options"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "options");
      }
      return new AnalysisUpdateOptionsParams(options);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.updateOptions params");
    }
  }

  factory AnalysisUpdateOptionsParams.fromRequest(Request request) {
    return new AnalysisUpdateOptionsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["options"] = options.toJson();
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.updateOptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisUpdateOptionsParams) {
      return options == other.options;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, options.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * analysis.updateOptions result
 */
class AnalysisUpdateOptionsResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 * analysis.errors params
 *
 * {
 *   "file": FilePath
 *   "errors": List<AnalysisError>
 * }
 */
class AnalysisErrorsParams implements HasToJson {
  /**
   * The file containing the errors.
   */
  String file;

  /**
   * The errors contained in the file.
   */
  List<AnalysisError> errors;

  AnalysisErrorsParams(this.file, this.errors);

  factory AnalysisErrorsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      List<AnalysisError> errors;
      if (json.containsKey("errors")) {
        errors = jsonDecoder._decodeList(jsonPath + ".errors", json["errors"], (String jsonPath, Object json) => new AnalysisError.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "errors");
      }
      return new AnalysisErrorsParams(file, errors);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.errors params");
    }
  }

  factory AnalysisErrorsParams.fromNotification(Notification notification) {
    return new AnalysisErrorsParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
          _listEqual(errors, other.errors, (AnalysisError a, AnalysisError b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, errors.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.flushResults params
 *
 * {
 *   "files": List<FilePath>
 * }
 */
class AnalysisFlushResultsParams implements HasToJson {
  /**
   * The files that are no longer being analyzed.
   */
  List<String> files;

  AnalysisFlushResultsParams(this.files);

  factory AnalysisFlushResultsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder._decodeList(jsonPath + ".files", json["files"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "files");
      }
      return new AnalysisFlushResultsParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.flushResults params");
    }
  }

  factory AnalysisFlushResultsParams.fromNotification(Notification notification) {
    return new AnalysisFlushResultsParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
  bool operator==(other) {
    if (other is AnalysisFlushResultsParams) {
      return _listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, files.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.folding params
 *
 * {
 *   "file": FilePath
 *   "regions": List<FoldingRegion>
 * }
 */
class AnalysisFoldingParams implements HasToJson {
  /**
   * The file containing the folding regions.
   */
  String file;

  /**
   * The folding regions contained in the file.
   */
  List<FoldingRegion> regions;

  AnalysisFoldingParams(this.file, this.regions);

  factory AnalysisFoldingParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      List<FoldingRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder._decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new FoldingRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "regions");
      }
      return new AnalysisFoldingParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.folding params");
    }
  }

  factory AnalysisFoldingParams.fromNotification(Notification notification) {
    return new AnalysisFoldingParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
          _listEqual(regions, other.regions, (FoldingRegion a, FoldingRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, regions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.highlights params
 *
 * {
 *   "file": FilePath
 *   "regions": List<HighlightRegion>
 * }
 */
class AnalysisHighlightsParams implements HasToJson {
  /**
   * The file containing the highlight regions.
   */
  String file;

  /**
   * The highlight regions contained in the file. Each highlight region
   * represents a particular syntactic or semantic meaning associated with some
   * range. Note that the highlight regions that are returned can overlap other
   * highlight regions if there is more than one meaning associated with a
   * particular region.
   */
  List<HighlightRegion> regions;

  AnalysisHighlightsParams(this.file, this.regions);

  factory AnalysisHighlightsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      List<HighlightRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder._decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new HighlightRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "regions");
      }
      return new AnalysisHighlightsParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.highlights params");
    }
  }

  factory AnalysisHighlightsParams.fromNotification(Notification notification) {
    return new AnalysisHighlightsParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
          _listEqual(regions, other.regions, (HighlightRegion a, HighlightRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, regions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.navigation params
 *
 * {
 *   "file": FilePath
 *   "regions": List<NavigationRegion>
 * }
 */
class AnalysisNavigationParams implements HasToJson {
  /**
   * The file containing the navigation regions.
   */
  String file;

  /**
   * The navigation regions contained in the file. Each navigation region
   * represents a list of targets associated with some range. The lists will
   * usually contain a single target, but can contain more in the case of a
   * part that is included in multiple libraries or in Dart code that is
   * compiled against multiple versions of a package. Note that the navigation
   * regions that are returned do not overlap other navigation regions.
   */
  List<NavigationRegion> regions;

  AnalysisNavigationParams(this.file, this.regions);

  factory AnalysisNavigationParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      List<NavigationRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder._decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "regions");
      }
      return new AnalysisNavigationParams(file, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.navigation params");
    }
  }

  factory AnalysisNavigationParams.fromNotification(Notification notification) {
    return new AnalysisNavigationParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["regions"] = regions.map((NavigationRegion value) => value.toJson()).toList();
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
          _listEqual(regions, other.regions, (NavigationRegion a, NavigationRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, regions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.occurrences params
 *
 * {
 *   "file": FilePath
 *   "occurrences": List<Occurrences>
 * }
 */
class AnalysisOccurrencesParams implements HasToJson {
  /**
   * The file in which the references occur.
   */
  String file;

  /**
   * The occurrences of references to elements within the file.
   */
  List<Occurrences> occurrences;

  AnalysisOccurrencesParams(this.file, this.occurrences);

  factory AnalysisOccurrencesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      List<Occurrences> occurrences;
      if (json.containsKey("occurrences")) {
        occurrences = jsonDecoder._decodeList(jsonPath + ".occurrences", json["occurrences"], (String jsonPath, Object json) => new Occurrences.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "occurrences");
      }
      return new AnalysisOccurrencesParams(file, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.occurrences params");
    }
  }

  factory AnalysisOccurrencesParams.fromNotification(Notification notification) {
    return new AnalysisOccurrencesParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
          _listEqual(occurrences, other.occurrences, (Occurrences a, Occurrences b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.outline params
 *
 * {
 *   "file": FilePath
 *   "outline": Outline
 * }
 */
class AnalysisOutlineParams implements HasToJson {
  /**
   * The file with which the outline is associated.
   */
  String file;

  /**
   * The outline associated with the file.
   */
  Outline outline;

  AnalysisOutlineParams(this.file, this.outline);

  factory AnalysisOutlineParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      Outline outline;
      if (json.containsKey("outline")) {
        outline = new Outline.fromJson(jsonDecoder, jsonPath + ".outline", json["outline"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "outline");
      }
      return new AnalysisOutlineParams(file, outline);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.outline params");
    }
  }

  factory AnalysisOutlineParams.fromNotification(Notification notification) {
    return new AnalysisOutlineParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["outline"] = outline.toJson();
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
          outline == other.outline;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, outline.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.overrides params
 *
 * {
 *   "file": FilePath
 *   "overrides": List<Override>
 * }
 */
class AnalysisOverridesParams implements HasToJson {
  /**
   * The file with which the overrides are associated.
   */
  String file;

  /**
   * The overrides associated with the file.
   */
  List<Override> overrides;

  AnalysisOverridesParams(this.file, this.overrides);

  factory AnalysisOverridesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      List<Override> overrides;
      if (json.containsKey("overrides")) {
        overrides = jsonDecoder._decodeList(jsonPath + ".overrides", json["overrides"], (String jsonPath, Object json) => new Override.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "overrides");
      }
      return new AnalysisOverridesParams(file, overrides);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.overrides params");
    }
  }

  factory AnalysisOverridesParams.fromNotification(Notification notification) {
    return new AnalysisOverridesParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["overrides"] = overrides.map((Override value) => value.toJson()).toList();
    return result;
  }

  Notification toNotification() {
    return new Notification("analysis.overrides", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisOverridesParams) {
      return file == other.file &&
          _listEqual(overrides, other.overrides, (Override a, Override b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, overrides.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * completion.getSuggestions params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
class CompletionGetSuggestionsParams implements HasToJson {
  /**
   * The file containing the point at which suggestions are to be made.
   */
  String file;

  /**
   * The offset within the file at which suggestions are to be made.
   */
  int offset;

  CompletionGetSuggestionsParams(this.file, this.offset);

  factory CompletionGetSuggestionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      return new CompletionGetSuggestionsParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "completion.getSuggestions params");
    }
  }

  factory CompletionGetSuggestionsParams.fromRequest(Request request) {
    return new CompletionGetSuggestionsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * completion.getSuggestions result
 *
 * {
 *   "id": CompletionId
 * }
 */
class CompletionGetSuggestionsResult implements HasToJson {
  /**
   * The identifier used to associate results with this completion request.
   */
  String id;

  CompletionGetSuggestionsResult(this.id);

  factory CompletionGetSuggestionsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      return new CompletionGetSuggestionsResult(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "completion.getSuggestions result");
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(Response response) {
    return new CompletionGetSuggestionsResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is CompletionGetSuggestionsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class CompletionResultsParams implements HasToJson {
  /**
   * The id associated with the completion.
   */
  String id;

  /**
   * The offset of the start of the text to be replaced. This will be different
   * than the offset used to request the completion suggestions if there was a
   * portion of an identifier before the original offset. In particular, the
   * replacementOffset will be the offset of the beginning of said identifier.
   */
  int replacementOffset;

  /**
   * The length of the text to be replaced if the remainder of the identifier
   * containing the cursor is to be replaced when the suggestion is applied
   * (that is, the number of characters in the existing identifier).
   */
  int replacementLength;

  /**
   * The completion suggestions being reported. The notification contains all
   * possible completions at the requested cursor position, even those that do
   * not match the characters the user has already typed. This allows the
   * client to respond to further keystrokes from the user without having to
   * make additional requests.
   */
  List<CompletionSuggestion> results;

  /**
   * True if this is that last set of results that will be returned for the
   * indicated completion.
   */
  bool isLast;

  CompletionResultsParams(this.id, this.replacementOffset, this.replacementLength, this.results, this.isLast);

  factory CompletionResultsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      int replacementOffset;
      if (json.containsKey("replacementOffset")) {
        replacementOffset = jsonDecoder._decodeInt(jsonPath + ".replacementOffset", json["replacementOffset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "replacementOffset");
      }
      int replacementLength;
      if (json.containsKey("replacementLength")) {
        replacementLength = jsonDecoder._decodeInt(jsonPath + ".replacementLength", json["replacementLength"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "replacementLength");
      }
      List<CompletionSuggestion> results;
      if (json.containsKey("results")) {
        results = jsonDecoder._decodeList(jsonPath + ".results", json["results"], (String jsonPath, Object json) => new CompletionSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "results");
      }
      bool isLast;
      if (json.containsKey("isLast")) {
        isLast = jsonDecoder._decodeBool(jsonPath + ".isLast", json["isLast"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isLast");
      }
      return new CompletionResultsParams(id, replacementOffset, replacementLength, results, isLast);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "completion.results params");
    }
  }

  factory CompletionResultsParams.fromNotification(Notification notification) {
    return new CompletionResultsParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    result["replacementOffset"] = replacementOffset;
    result["replacementLength"] = replacementLength;
    result["results"] = results.map((CompletionSuggestion value) => value.toJson()).toList();
    result["isLast"] = isLast;
    return result;
  }

  Notification toNotification() {
    return new Notification("completion.results", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is CompletionResultsParams) {
      return id == other.id &&
          replacementOffset == other.replacementOffset &&
          replacementLength == other.replacementLength &&
          _listEqual(results, other.results, (CompletionSuggestion a, CompletionSuggestion b) => a == b) &&
          isLast == other.isLast;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    hash = _JenkinsSmiHash.combine(hash, replacementOffset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, replacementLength.hashCode);
    hash = _JenkinsSmiHash.combine(hash, results.hashCode);
    hash = _JenkinsSmiHash.combine(hash, isLast.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findElementReferences params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "includePotential": bool
 * }
 */
class SearchFindElementReferencesParams implements HasToJson {
  /**
   * The file containing the declaration of or reference to the element used to
   * define the search.
   */
  String file;

  /**
   * The offset within the file of the declaration of or reference to the
   * element.
   */
  int offset;

  /**
   * True if potential matches are to be included in the results.
   */
  bool includePotential;

  SearchFindElementReferencesParams(this.file, this.offset, this.includePotential);

  factory SearchFindElementReferencesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      bool includePotential;
      if (json.containsKey("includePotential")) {
        includePotential = jsonDecoder._decodeBool(jsonPath + ".includePotential", json["includePotential"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "includePotential");
      }
      return new SearchFindElementReferencesParams(file, offset, includePotential);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findElementReferences params");
    }
  }

  factory SearchFindElementReferencesParams.fromRequest(Request request) {
    return new SearchFindElementReferencesParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["includePotential"] = includePotential;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "search.findElementReferences", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, includePotential.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findElementReferences result
 *
 * {
 *   "id": optional SearchId
 *   "element": optional Element
 * }
 */
class SearchFindElementReferencesResult implements HasToJson {
  /**
   * The identifier used to associate results with this search request.
   *
   * If no element was found at the given location, this field will be absent,
   * and no results will be reported via the search.results notification.
   */
  String id;

  /**
   * The element referenced or defined at the given offset and whose references
   * will be returned in the search results.
   *
   * If no element was found at the given location, this field will be absent.
   */
  Element element;

  SearchFindElementReferencesResult({this.id, this.element});

  factory SearchFindElementReferencesResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      }
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      }
      return new SearchFindElementReferencesResult(id: id, element: element);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findElementReferences result");
    }
  }

  factory SearchFindElementReferencesResult.fromResponse(Response response) {
    return new SearchFindElementReferencesResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

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

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindElementReferencesResult) {
      return id == other.id &&
          element == other.element;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    hash = _JenkinsSmiHash.combine(hash, element.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberDeclarations params
 *
 * {
 *   "name": String
 * }
 */
class SearchFindMemberDeclarationsParams implements HasToJson {
  /**
   * The name of the declarations to be found.
   */
  String name;

  SearchFindMemberDeclarationsParams(this.name);

  factory SearchFindMemberDeclarationsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      return new SearchFindMemberDeclarationsParams(name);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberDeclarations params");
    }
  }

  factory SearchFindMemberDeclarationsParams.fromRequest(Request request) {
    return new SearchFindMemberDeclarationsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "search.findMemberDeclarations", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindMemberDeclarationsParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
class SearchFindMemberDeclarationsResult implements HasToJson {
  /**
   * The identifier used to associate results with this search request.
   */
  String id;

  SearchFindMemberDeclarationsResult(this.id);

  factory SearchFindMemberDeclarationsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      return new SearchFindMemberDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberDeclarations result");
    }
  }

  factory SearchFindMemberDeclarationsResult.fromResponse(Response response) {
    return new SearchFindMemberDeclarationsResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindMemberDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberReferences params
 *
 * {
 *   "name": String
 * }
 */
class SearchFindMemberReferencesParams implements HasToJson {
  /**
   * The name of the references to be found.
   */
  String name;

  SearchFindMemberReferencesParams(this.name);

  factory SearchFindMemberReferencesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      return new SearchFindMemberReferencesParams(name);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberReferences params");
    }
  }

  factory SearchFindMemberReferencesParams.fromRequest(Request request) {
    return new SearchFindMemberReferencesParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["name"] = name;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "search.findMemberReferences", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindMemberReferencesParams) {
      return name == other.name;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findMemberReferences result
 *
 * {
 *   "id": SearchId
 * }
 */
class SearchFindMemberReferencesResult implements HasToJson {
  /**
   * The identifier used to associate results with this search request.
   */
  String id;

  SearchFindMemberReferencesResult(this.id);

  factory SearchFindMemberReferencesResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      return new SearchFindMemberReferencesResult(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberReferences result");
    }
  }

  factory SearchFindMemberReferencesResult.fromResponse(Response response) {
    return new SearchFindMemberReferencesResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindMemberReferencesResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findTopLevelDeclarations params
 *
 * {
 *   "pattern": String
 * }
 */
class SearchFindTopLevelDeclarationsParams implements HasToJson {
  /**
   * The regular expression used to match the names of the declarations to be
   * found.
   */
  String pattern;

  SearchFindTopLevelDeclarationsParams(this.pattern);

  factory SearchFindTopLevelDeclarationsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String pattern;
      if (json.containsKey("pattern")) {
        pattern = jsonDecoder._decodeString(jsonPath + ".pattern", json["pattern"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "pattern");
      }
      return new SearchFindTopLevelDeclarationsParams(pattern);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findTopLevelDeclarations params");
    }
  }

  factory SearchFindTopLevelDeclarationsParams.fromRequest(Request request) {
    return new SearchFindTopLevelDeclarationsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["pattern"] = pattern;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "search.findTopLevelDeclarations", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindTopLevelDeclarationsParams) {
      return pattern == other.pattern;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, pattern.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.findTopLevelDeclarations result
 *
 * {
 *   "id": SearchId
 * }
 */
class SearchFindTopLevelDeclarationsResult implements HasToJson {
  /**
   * The identifier used to associate results with this search request.
   */
  String id;

  SearchFindTopLevelDeclarationsResult(this.id);

  factory SearchFindTopLevelDeclarationsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      return new SearchFindTopLevelDeclarationsResult(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.findTopLevelDeclarations result");
    }
  }

  factory SearchFindTopLevelDeclarationsResult.fromResponse(Response response) {
    return new SearchFindTopLevelDeclarationsResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchFindTopLevelDeclarationsResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.getTypeHierarchy params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
class SearchGetTypeHierarchyParams implements HasToJson {
  /**
   * The file containing the declaration or reference to the type for which a
   * hierarchy is being requested.
   */
  String file;

  /**
   * The offset of the name of the type within the file.
   */
  int offset;

  SearchGetTypeHierarchyParams(this.file, this.offset);

  factory SearchGetTypeHierarchyParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      return new SearchGetTypeHierarchyParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.getTypeHierarchy params");
    }
  }

  factory SearchGetTypeHierarchyParams.fromRequest(Request request) {
    return new SearchGetTypeHierarchyParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "search.getTypeHierarchy", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchGetTypeHierarchyParams) {
      return file == other.file &&
          offset == other.offset;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.getTypeHierarchy result
 *
 * {
 *   "hierarchyItems": optional List<TypeHierarchyItem>
 * }
 */
class SearchGetTypeHierarchyResult implements HasToJson {
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
  List<TypeHierarchyItem> hierarchyItems;

  SearchGetTypeHierarchyResult({this.hierarchyItems}) {
    if (hierarchyItems == null) {
      hierarchyItems = <TypeHierarchyItem>[];
    }
  }

  factory SearchGetTypeHierarchyResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<TypeHierarchyItem> hierarchyItems;
      if (json.containsKey("hierarchyItems")) {
        hierarchyItems = jsonDecoder._decodeList(jsonPath + ".hierarchyItems", json["hierarchyItems"], (String jsonPath, Object json) => new TypeHierarchyItem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        hierarchyItems = <TypeHierarchyItem>[];
      }
      return new SearchGetTypeHierarchyResult(hierarchyItems: hierarchyItems);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.getTypeHierarchy result");
    }
  }

  factory SearchGetTypeHierarchyResult.fromResponse(Response response) {
    return new SearchGetTypeHierarchyResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (hierarchyItems.isNotEmpty) {
      result["hierarchyItems"] = hierarchyItems.map((TypeHierarchyItem value) => value.toJson()).toList();
    }
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchGetTypeHierarchyResult) {
      return _listEqual(hierarchyItems, other.hierarchyItems, (TypeHierarchyItem a, TypeHierarchyItem b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, hierarchyItems.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * search.results params
 *
 * {
 *   "id": SearchId
 *   "results": List<SearchResult>
 *   "isLast": bool
 * }
 */
class SearchResultsParams implements HasToJson {
  /**
   * The id associated with the search.
   */
  String id;

  /**
   * The search results being reported.
   */
  List<SearchResult> results;

  /**
   * True if this is that last set of results that will be returned for the
   * indicated search.
   */
  bool isLast;

  SearchResultsParams(this.id, this.results, this.isLast);

  factory SearchResultsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      List<SearchResult> results;
      if (json.containsKey("results")) {
        results = jsonDecoder._decodeList(jsonPath + ".results", json["results"], (String jsonPath, Object json) => new SearchResult.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "results");
      }
      bool isLast;
      if (json.containsKey("isLast")) {
        isLast = jsonDecoder._decodeBool(jsonPath + ".isLast", json["isLast"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isLast");
      }
      return new SearchResultsParams(id, results, isLast);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.results params");
    }
  }

  factory SearchResultsParams.fromNotification(Notification notification) {
    return new SearchResultsParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    result["results"] = results.map((SearchResult value) => value.toJson()).toList();
    result["isLast"] = isLast;
    return result;
  }

  Notification toNotification() {
    return new Notification("search.results", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SearchResultsParams) {
      return id == other.id &&
          _listEqual(results, other.results, (SearchResult a, SearchResult b) => a == b) &&
          isLast == other.isLast;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    hash = _JenkinsSmiHash.combine(hash, results.hashCode);
    hash = _JenkinsSmiHash.combine(hash, isLast.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class EditGetAssistsParams implements HasToJson {
  /**
   * The file containing the code for which assists are being requested.
   */
  String file;

  /**
   * The offset of the code for which assists are being requested.
   */
  int offset;

  /**
   * The length of the code for which assists are being requested.
   */
  int length;

  EditGetAssistsParams(this.file, this.offset, this.length);

  factory EditGetAssistsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      return new EditGetAssistsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAssists params");
    }
  }

  factory EditGetAssistsParams.fromRequest(Request request) {
    return new EditGetAssistsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getAssists result
 *
 * {
 *   "assists": List<SourceChange>
 * }
 */
class EditGetAssistsResult implements HasToJson {
  /**
   * The assists that are available at the given location.
   */
  List<SourceChange> assists;

  EditGetAssistsResult(this.assists);

  factory EditGetAssistsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<SourceChange> assists;
      if (json.containsKey("assists")) {
        assists = jsonDecoder._decodeList(jsonPath + ".assists", json["assists"], (String jsonPath, Object json) => new SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "assists");
      }
      return new EditGetAssistsResult(assists);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAssists result");
    }
  }

  factory EditGetAssistsResult.fromResponse(Response response) {
    return new EditGetAssistsResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["assists"] = assists.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetAssistsResult) {
      return _listEqual(assists, other.assists, (SourceChange a, SourceChange b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, assists.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class EditGetAvailableRefactoringsParams implements HasToJson {
  /**
   * The file containing the code on which the refactoring would be based.
   */
  String file;

  /**
   * The offset of the code on which the refactoring would be based.
   */
  int offset;

  /**
   * The length of the code on which the refactoring would be based.
   */
  int length;

  EditGetAvailableRefactoringsParams(this.file, this.offset, this.length);

  factory EditGetAvailableRefactoringsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      return new EditGetAvailableRefactoringsParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAvailableRefactorings params");
    }
  }

  factory EditGetAvailableRefactoringsParams.fromRequest(Request request) {
    return new EditGetAvailableRefactoringsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    result["length"] = length;
    return result;
  }

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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getAvailableRefactorings result
 *
 * {
 *   "kinds": List<RefactoringKind>
 * }
 */
class EditGetAvailableRefactoringsResult implements HasToJson {
  /**
   * The kinds of refactorings that are valid for the given selection.
   */
  List<RefactoringKind> kinds;

  EditGetAvailableRefactoringsResult(this.kinds);

  factory EditGetAvailableRefactoringsResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<RefactoringKind> kinds;
      if (json.containsKey("kinds")) {
        kinds = jsonDecoder._decodeList(jsonPath + ".kinds", json["kinds"], (String jsonPath, Object json) => new RefactoringKind.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kinds");
      }
      return new EditGetAvailableRefactoringsResult(kinds);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getAvailableRefactorings result");
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(Response response) {
    return new EditGetAvailableRefactoringsResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kinds"] = kinds.map((RefactoringKind value) => value.toJson()).toList();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetAvailableRefactoringsResult) {
      return _listEqual(kinds, other.kinds, (RefactoringKind a, RefactoringKind b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, kinds.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getFixes params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
class EditGetFixesParams implements HasToJson {
  /**
   * The file containing the errors for which fixes are being requested.
   */
  String file;

  /**
   * The offset used to select the errors for which fixes will be returned.
   */
  int offset;

  EditGetFixesParams(this.file, this.offset);

  factory EditGetFixesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      return new EditGetFixesParams(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getFixes params");
    }
  }

  factory EditGetFixesParams.fromRequest(Request request) {
    return new EditGetFixesParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["offset"] = offset;
    return result;
  }

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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.getFixes result
 *
 * {
 *   "fixes": List<AnalysisErrorFixes>
 * }
 */
class EditGetFixesResult implements HasToJson {
  /**
   * The fixes that are available for the errors at the given offset.
   */
  List<AnalysisErrorFixes> fixes;

  EditGetFixesResult(this.fixes);

  factory EditGetFixesResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<AnalysisErrorFixes> fixes;
      if (json.containsKey("fixes")) {
        fixes = jsonDecoder._decodeList(jsonPath + ".fixes", json["fixes"], (String jsonPath, Object json) => new AnalysisErrorFixes.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "fixes");
      }
      return new EditGetFixesResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getFixes result");
    }
  }

  factory EditGetFixesResult.fromResponse(Response response) {
    return new EditGetFixesResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["fixes"] = fixes.map((AnalysisErrorFixes value) => value.toJson()).toList();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetFixesResult) {
      return _listEqual(fixes, other.fixes, (AnalysisErrorFixes a, AnalysisErrorFixes b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, fixes.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class EditGetRefactoringParams implements HasToJson {
  /**
   * The kind of refactoring to be performed.
   */
  RefactoringKind kind;

  /**
   * The file containing the code involved in the refactoring.
   */
  String file;

  /**
   * The offset of the region involved in the refactoring.
   */
  int offset;

  /**
   * The length of the region involved in the refactoring.
   */
  int length;

  /**
   * True if the client is only requesting that the values of the options be
   * validated and no change be generated.
   */
  bool validateOnly;

  /**
   * Data used to provide values provided by the user. The structure of the
   * data is dependent on the kind of refactoring being performed. The data
   * that is expected is documented in the section titled Refactorings, labeled
   * as “Options”. This field can be omitted if the refactoring does not
   * require any options or if the values of those options are not known.
   */
  RefactoringOptions options;

  EditGetRefactoringParams(this.kind, this.file, this.offset, this.length, this.validateOnly, {this.options});

  factory EditGetRefactoringParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RefactoringKind kind;
      if (json.containsKey("kind")) {
        kind = new RefactoringKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      bool validateOnly;
      if (json.containsKey("validateOnly")) {
        validateOnly = jsonDecoder._decodeBool(jsonPath + ".validateOnly", json["validateOnly"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "validateOnly");
      }
      RefactoringOptions options;
      if (json.containsKey("options")) {
        options = new RefactoringOptions.fromJson(jsonDecoder, jsonPath + ".options", json["options"], kind);
      }
      return new EditGetRefactoringParams(kind, file, offset, length, validateOnly, options: options);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring params");
    }
  }

  factory EditGetRefactoringParams.fromRequest(Request request) {
    var params = new EditGetRefactoringParams.fromJson(
        new RequestDecoder(request), "params", request._params);
    REQUEST_ID_REFACTORING_KINDS[request.id] = params.kind;
    return params;
  }

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
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, validateOnly.hashCode);
    hash = _JenkinsSmiHash.combine(hash, options.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class EditGetRefactoringResult implements HasToJson {
  /**
   * The initial status of the refactoring, i.e. problems related to the
   * context in which the refactoring is requested. The array will be empty if
   * there are no known problems.
   */
  List<RefactoringProblem> initialProblems;

  /**
   * The options validation status, i.e. problems in the given options, such as
   * light-weight validation of a new name, flags compatibility, etc. The array
   * will be empty if there are no known problems.
   */
  List<RefactoringProblem> optionsProblems;

  /**
   * The final status of the refactoring, i.e. problems identified in the
   * result of a full, potentially expensive validation and / or change
   * creation. The array will be empty if there are no known problems.
   */
  List<RefactoringProblem> finalProblems;

  /**
   * Data used to provide feedback to the user. The structure of the data is
   * dependent on the kind of refactoring being created. The data that is
   * returned is documented in the section titled Refactorings, labeled as
   * “Feedback”.
   */
  RefactoringFeedback feedback;

  /**
   * The changes that are to be applied to affect the refactoring. This field
   * will be omitted if there are problems that prevent a set of changes from
   * being computed, such as having no options specified for a refactoring that
   * requires them, or if only validation was requested.
   */
  SourceChange change;

  /**
   * The ids of source edits that are not known to be valid. An edit is not
   * known to be valid if there was insufficient type information for the
   * server to be able to determine whether or not the code needs to be
   * modified, such as when a member is being renamed and there is a reference
   * to a member from an unknown type. This field will be omitted if the change
   * field is omitted or if there are no potential edits for the refactoring.
   */
  List<String> potentialEdits;

  EditGetRefactoringResult(this.initialProblems, this.optionsProblems, this.finalProblems, {this.feedback, this.change, this.potentialEdits}) {
    if (potentialEdits == null) {
      potentialEdits = <String>[];
    }
  }

  factory EditGetRefactoringResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<RefactoringProblem> initialProblems;
      if (json.containsKey("initialProblems")) {
        initialProblems = jsonDecoder._decodeList(jsonPath + ".initialProblems", json["initialProblems"], (String jsonPath, Object json) => new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "initialProblems");
      }
      List<RefactoringProblem> optionsProblems;
      if (json.containsKey("optionsProblems")) {
        optionsProblems = jsonDecoder._decodeList(jsonPath + ".optionsProblems", json["optionsProblems"], (String jsonPath, Object json) => new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "optionsProblems");
      }
      List<RefactoringProblem> finalProblems;
      if (json.containsKey("finalProblems")) {
        finalProblems = jsonDecoder._decodeList(jsonPath + ".finalProblems", json["finalProblems"], (String jsonPath, Object json) => new RefactoringProblem.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "finalProblems");
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
        potentialEdits = jsonDecoder._decodeList(jsonPath + ".potentialEdits", json["potentialEdits"], jsonDecoder._decodeString);
      } else {
        potentialEdits = <String>[];
      }
      return new EditGetRefactoringResult(initialProblems, optionsProblems, finalProblems, feedback: feedback, change: change, potentialEdits: potentialEdits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring result");
    }
  }

  factory EditGetRefactoringResult.fromResponse(Response response) {
    return new EditGetRefactoringResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

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
    if (potentialEdits.isNotEmpty) {
      result["potentialEdits"] = potentialEdits;
    }
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditGetRefactoringResult) {
      return _listEqual(initialProblems, other.initialProblems, (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          _listEqual(optionsProblems, other.optionsProblems, (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          _listEqual(finalProblems, other.finalProblems, (RefactoringProblem a, RefactoringProblem b) => a == b) &&
          feedback == other.feedback &&
          change == other.change &&
          _listEqual(potentialEdits, other.potentialEdits, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, initialProblems.hashCode);
    hash = _JenkinsSmiHash.combine(hash, optionsProblems.hashCode);
    hash = _JenkinsSmiHash.combine(hash, finalProblems.hashCode);
    hash = _JenkinsSmiHash.combine(hash, feedback.hashCode);
    hash = _JenkinsSmiHash.combine(hash, change.hashCode);
    hash = _JenkinsSmiHash.combine(hash, potentialEdits.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.createContext params
 *
 * {
 *   "contextRoot": FilePath
 * }
 */
class ExecutionCreateContextParams implements HasToJson {
  /**
   * The path of the Dart or HTML file that will be launched.
   */
  String contextRoot;

  ExecutionCreateContextParams(this.contextRoot);

  factory ExecutionCreateContextParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String contextRoot;
      if (json.containsKey("contextRoot")) {
        contextRoot = jsonDecoder._decodeString(jsonPath + ".contextRoot", json["contextRoot"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "contextRoot");
      }
      return new ExecutionCreateContextParams(contextRoot);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.createContext params");
    }
  }

  factory ExecutionCreateContextParams.fromRequest(Request request) {
    return new ExecutionCreateContextParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["contextRoot"] = contextRoot;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "execution.createContext", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionCreateContextParams) {
      return contextRoot == other.contextRoot;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, contextRoot.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.createContext result
 *
 * {
 *   "id": ExecutionContextId
 * }
 */
class ExecutionCreateContextResult implements HasToJson {
  /**
   * The identifier used to refer to the execution context that was created.
   */
  String id;

  ExecutionCreateContextResult(this.id);

  factory ExecutionCreateContextResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      return new ExecutionCreateContextResult(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.createContext result");
    }
  }

  factory ExecutionCreateContextResult.fromResponse(Response response) {
    return new ExecutionCreateContextResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionCreateContextResult) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.deleteContext params
 *
 * {
 *   "id": ExecutionContextId
 * }
 */
class ExecutionDeleteContextParams implements HasToJson {
  /**
   * The identifier of the execution context that is to be deleted.
   */
  String id;

  ExecutionDeleteContextParams(this.id);

  factory ExecutionDeleteContextParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      return new ExecutionDeleteContextParams(id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.deleteContext params");
    }
  }

  factory ExecutionDeleteContextParams.fromRequest(Request request) {
    return new ExecutionDeleteContextParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["id"] = id;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "execution.deleteContext", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionDeleteContextParams) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * execution.deleteContext result
 */
class ExecutionDeleteContextResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 * execution.mapUri params
 *
 * {
 *   "id": ExecutionContextId
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
class ExecutionMapUriParams implements HasToJson {
  /**
   * The identifier of the execution context in which the URI is to be mapped.
   */
  String id;

  /**
   * The path of the file to be mapped into a URI.
   */
  String file;

  /**
   * The URI to be mapped into a file path.
   */
  String uri;

  ExecutionMapUriParams(this.id, {this.file, this.uri});

  factory ExecutionMapUriParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "id");
      }
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      }
      String uri;
      if (json.containsKey("uri")) {
        uri = jsonDecoder._decodeString(jsonPath + ".uri", json["uri"]);
      }
      return new ExecutionMapUriParams(id, file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.mapUri params");
    }
  }

  factory ExecutionMapUriParams.fromRequest(Request request) {
    return new ExecutionMapUriParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

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

  Request toRequest(String id) {
    return new Request(id, "execution.mapUri", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionMapUriParams) {
      return id == other.id &&
          file == other.file &&
          uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, uri.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.mapUri result
 *
 * {
 *   "file": optional FilePath
 *   "uri": optional String
 * }
 */
class ExecutionMapUriResult implements HasToJson {
  /**
   * The file to which the URI was mapped. This field is omitted if the uri
   * field was not given in the request.
   */
  String file;

  /**
   * The URI to which the file path was mapped. This field is omitted if the
   * file field was not given in the request.
   */
  String uri;

  ExecutionMapUriResult({this.file, this.uri});

  factory ExecutionMapUriResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      }
      String uri;
      if (json.containsKey("uri")) {
        uri = jsonDecoder._decodeString(jsonPath + ".uri", json["uri"]);
      }
      return new ExecutionMapUriResult(file: file, uri: uri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.mapUri result");
    }
  }

  factory ExecutionMapUriResult.fromResponse(Response response) {
    return new ExecutionMapUriResult.fromJson(
        new ResponseDecoder(response), "result", response._result);
  }

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

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionMapUriResult) {
      return file == other.file &&
          uri == other.uri;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, uri.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * execution.setSubscriptions params
 *
 * {
 *   "subscriptions": List<ExecutionService>
 * }
 */
class ExecutionSetSubscriptionsParams implements HasToJson {
  /**
   * A list of the services being subscribed to.
   */
  List<ExecutionService> subscriptions;

  ExecutionSetSubscriptionsParams(this.subscriptions);

  factory ExecutionSetSubscriptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ExecutionService> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder._decodeList(jsonPath + ".subscriptions", json["subscriptions"], (String jsonPath, Object json) => new ExecutionService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "subscriptions");
      }
      return new ExecutionSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.setSubscriptions params");
    }
  }

  factory ExecutionSetSubscriptionsParams.fromRequest(Request request) {
    return new ExecutionSetSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = subscriptions.map((ExecutionService value) => value.toJson()).toList();
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "execution.setSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionSetSubscriptionsParams) {
      return _listEqual(subscriptions, other.subscriptions, (ExecutionService a, ExecutionService b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, subscriptions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * execution.setSubscriptions result
 */
class ExecutionSetSubscriptionsResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 * execution.launchData params
 *
 * {
 *   "executables": List<ExecutableFile>
 *   "dartToHtml": Map<FilePath, List<FilePath>>
 *   "htmlToDart": Map<FilePath, List<FilePath>>
 * }
 */
class ExecutionLaunchDataParams implements HasToJson {
  /**
   * A list of the files that are executable. This list replaces any previous
   * list provided.
   */
  List<ExecutableFile> executables;

  /**
   * A mapping from the paths of Dart files that are referenced by HTML files
   * to a list of the HTML files that reference the Dart files.
   */
  Map<String, List<String>> dartToHtml;

  /**
   * A mapping from the paths of HTML files that reference Dart files to a list
   * of the Dart files they reference.
   */
  Map<String, List<String>> htmlToDart;

  ExecutionLaunchDataParams(this.executables, this.dartToHtml, this.htmlToDart);

  factory ExecutionLaunchDataParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<ExecutableFile> executables;
      if (json.containsKey("executables")) {
        executables = jsonDecoder._decodeList(jsonPath + ".executables", json["executables"], (String jsonPath, Object json) => new ExecutableFile.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "executables");
      }
      Map<String, List<String>> dartToHtml;
      if (json.containsKey("dartToHtml")) {
        dartToHtml = jsonDecoder._decodeMap(jsonPath + ".dartToHtml", json["dartToHtml"], valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeList(jsonPath, json, jsonDecoder._decodeString));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "dartToHtml");
      }
      Map<String, List<String>> htmlToDart;
      if (json.containsKey("htmlToDart")) {
        htmlToDart = jsonDecoder._decodeMap(jsonPath + ".htmlToDart", json["htmlToDart"], valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeList(jsonPath, json, jsonDecoder._decodeString));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "htmlToDart");
      }
      return new ExecutionLaunchDataParams(executables, dartToHtml, htmlToDart);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.launchData params");
    }
  }

  factory ExecutionLaunchDataParams.fromNotification(Notification notification) {
    return new ExecutionLaunchDataParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["executables"] = executables.map((ExecutableFile value) => value.toJson()).toList();
    result["dartToHtml"] = dartToHtml;
    result["htmlToDart"] = htmlToDart;
    return result;
  }

  Notification toNotification() {
    return new Notification("execution.launchData", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutionLaunchDataParams) {
      return _listEqual(executables, other.executables, (ExecutableFile a, ExecutableFile b) => a == b) &&
          _mapEqual(dartToHtml, other.dartToHtml, (List<String> a, List<String> b) => _listEqual(a, b, (String a, String b) => a == b)) &&
          _mapEqual(htmlToDart, other.htmlToDart, (List<String> a, List<String> b) => _listEqual(a, b, (String a, String b) => a == b));
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, executables.hashCode);
    hash = _JenkinsSmiHash.combine(hash, dartToHtml.hashCode);
    hash = _JenkinsSmiHash.combine(hash, htmlToDart.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * AddContentOverlay
 *
 * {
 *   "type": "add"
 *   "content": String
 * }
 */
class AddContentOverlay implements HasToJson {
  /**
   * The new content of the file.
   */
  String content;

  AddContentOverlay(this.content);

  factory AddContentOverlay.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      if (json["type"] != "add") {
        throw jsonDecoder.mismatch(jsonPath, "equal " + "add");
      }
      String content;
      if (json.containsKey("content")) {
        content = jsonDecoder._decodeString(jsonPath + ".content", json["content"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "content");
      }
      return new AddContentOverlay(content);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AddContentOverlay");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, 704418402);
    hash = _JenkinsSmiHash.combine(hash, content.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 * }
 */
class AnalysisError implements HasToJson {
  /**
   * Returns a list of AnalysisErrors correponding to the given list of Engine
   * errors.
   */
  static List<AnalysisError> listFromEngine(engine.LineInfo lineInfo, List<engine.AnalysisError> errors) =>
      _analysisErrorListFromEngine(lineInfo, errors);

  /**
   * The severity of the error.
   */
  AnalysisErrorSeverity severity;

  /**
   * The type of the error.
   */
  AnalysisErrorType type;

  /**
   * The location associated with the error.
   */
  Location location;

  /**
   * The message to be displayed for this error. The message should indicate
   * what is wrong with the code and why it is wrong.
   */
  String message;

  /**
   * The correction message to be displayed for this error. The correction
   * message should indicate how the user can fix the error. The field is
   * omitted if there is no correction message associated with the error code.
   */
  String correction;

  AnalysisError(this.severity, this.type, this.location, this.message, {this.correction});

  factory AnalysisError.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisErrorSeverity severity;
      if (json.containsKey("severity")) {
        severity = new AnalysisErrorSeverity.fromJson(jsonDecoder, jsonPath + ".severity", json["severity"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "severity");
      }
      AnalysisErrorType type;
      if (json.containsKey("type")) {
        type = new AnalysisErrorType.fromJson(jsonDecoder, jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "type");
      }
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "location");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder._decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "message");
      }
      String correction;
      if (json.containsKey("correction")) {
        correction = jsonDecoder._decodeString(jsonPath + ".correction", json["correction"]);
      }
      return new AnalysisError(severity, type, location, message, correction: correction);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisError");
    }
  }

  /**
   * Construct based on error information from the analyzer engine.
   */
  factory AnalysisError.fromEngine(engine.LineInfo lineInfo, engine.AnalysisError error) =>
      _analysisErrorFromEngine(lineInfo, error);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["severity"] = severity.toJson();
    result["type"] = type.toJson();
    result["location"] = location.toJson();
    result["message"] = message;
    if (correction != null) {
      result["correction"] = correction;
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
          correction == other.correction;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = _JenkinsSmiHash.combine(hash, type.hashCode);
    hash = _JenkinsSmiHash.combine(hash, location.hashCode);
    hash = _JenkinsSmiHash.combine(hash, message.hashCode);
    hash = _JenkinsSmiHash.combine(hash, correction.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * AnalysisErrorFixes
 *
 * {
 *   "error": AnalysisError
 *   "fixes": List<SourceChange>
 * }
 */
class AnalysisErrorFixes implements HasToJson {
  /**
   * The error with which the fixes are associated.
   */
  AnalysisError error;

  /**
   * The fixes associated with the error.
   */
  List<SourceChange> fixes;

  AnalysisErrorFixes(this.error, {this.fixes}) {
    if (fixes == null) {
      fixes = <SourceChange>[];
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
        throw jsonDecoder.missingKey(jsonPath, "error");
      }
      List<SourceChange> fixes;
      if (json.containsKey("fixes")) {
        fixes = jsonDecoder._decodeList(jsonPath + ".fixes", json["fixes"], (String jsonPath, Object json) => new SourceChange.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "fixes");
      }
      return new AnalysisErrorFixes(error, fixes: fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorFixes");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["error"] = error.toJson();
    result["fixes"] = fixes.map((SourceChange value) => value.toJson()).toList();
    return result;
  }

  /**
   * Add a [Fix]
   */
  void addFix(Fix fix) {
    fixes.add(fix.change);
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisErrorFixes) {
      return error == other.error &&
          _listEqual(fixes, other.fixes, (SourceChange a, SourceChange b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, error.hashCode);
    hash = _JenkinsSmiHash.combine(hash, fixes.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class AnalysisErrorSeverity {
  static const INFO = const AnalysisErrorSeverity._("INFO");

  static const WARNING = const AnalysisErrorSeverity._("WARNING");

  static const ERROR = const AnalysisErrorSeverity._("ERROR");

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
    throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorSeverity");
  }

  @override
  String toString() => "AnalysisErrorSeverity.$name";

  String toJson() => name;
}

/**
 * AnalysisErrorType
 *
 * enum {
 *   ANGULAR
 *   COMPILE_TIME_ERROR
 *   HINT
 *   POLYMER
 *   STATIC_TYPE_WARNING
 *   STATIC_WARNING
 *   SYNTACTIC_ERROR
 *   TODO
 * }
 */
class AnalysisErrorType {
  static const ANGULAR = const AnalysisErrorType._("ANGULAR");

  static const COMPILE_TIME_ERROR = const AnalysisErrorType._("COMPILE_TIME_ERROR");

  static const HINT = const AnalysisErrorType._("HINT");

  static const POLYMER = const AnalysisErrorType._("POLYMER");

  static const STATIC_TYPE_WARNING = const AnalysisErrorType._("STATIC_TYPE_WARNING");

  static const STATIC_WARNING = const AnalysisErrorType._("STATIC_WARNING");

  static const SYNTACTIC_ERROR = const AnalysisErrorType._("SYNTACTIC_ERROR");

  static const TODO = const AnalysisErrorType._("TODO");

  final String name;

  const AnalysisErrorType._(this.name);

  factory AnalysisErrorType(String name) {
    switch (name) {
      case "ANGULAR":
        return ANGULAR;
      case "COMPILE_TIME_ERROR":
        return COMPILE_TIME_ERROR;
      case "HINT":
        return HINT;
      case "POLYMER":
        return POLYMER;
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
    throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorType");
  }

  @override
  String toString() => "AnalysisErrorType.$name";

  String toJson() => name;
}

/**
 * AnalysisOptions
 *
 * {
 *   "enableAsync": optional bool
 *   "enableDeferredLoading": optional bool
 *   "enableEnums": optional bool
 *   "generateDart2jsHints": optional bool
 *   "generateHints": optional bool
 * }
 */
class AnalysisOptions implements HasToJson {
  /**
   * True if the client wants to enable support for the proposed async feature.
   */
  bool enableAsync;

  /**
   * True if the client wants to enable support for the proposed deferred
   * loading feature.
   */
  bool enableDeferredLoading;

  /**
   * True if the client wants to enable support for the proposed enum feature.
   */
  bool enableEnums;

  /**
   * True if hints that are specific to dart2js should be generated. This
   * option is ignored if generateHints is false.
   */
  bool generateDart2jsHints;

  /**
   * True is hints should be generated as part of generating errors and
   * warnings.
   */
  bool generateHints;

  AnalysisOptions({this.enableAsync, this.enableDeferredLoading, this.enableEnums, this.generateDart2jsHints, this.generateHints});

  factory AnalysisOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool enableAsync;
      if (json.containsKey("enableAsync")) {
        enableAsync = jsonDecoder._decodeBool(jsonPath + ".enableAsync", json["enableAsync"]);
      }
      bool enableDeferredLoading;
      if (json.containsKey("enableDeferredLoading")) {
        enableDeferredLoading = jsonDecoder._decodeBool(jsonPath + ".enableDeferredLoading", json["enableDeferredLoading"]);
      }
      bool enableEnums;
      if (json.containsKey("enableEnums")) {
        enableEnums = jsonDecoder._decodeBool(jsonPath + ".enableEnums", json["enableEnums"]);
      }
      bool generateDart2jsHints;
      if (json.containsKey("generateDart2jsHints")) {
        generateDart2jsHints = jsonDecoder._decodeBool(jsonPath + ".generateDart2jsHints", json["generateDart2jsHints"]);
      }
      bool generateHints;
      if (json.containsKey("generateHints")) {
        generateHints = jsonDecoder._decodeBool(jsonPath + ".generateHints", json["generateHints"]);
      }
      return new AnalysisOptions(enableAsync: enableAsync, enableDeferredLoading: enableDeferredLoading, enableEnums: enableEnums, generateDart2jsHints: generateDart2jsHints, generateHints: generateHints);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisOptions");
    }
  }

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
    if (generateDart2jsHints != null) {
      result["generateDart2jsHints"] = generateDart2jsHints;
    }
    if (generateHints != null) {
      result["generateHints"] = generateHints;
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisOptions) {
      return enableAsync == other.enableAsync &&
          enableDeferredLoading == other.enableDeferredLoading &&
          enableEnums == other.enableEnums &&
          generateDart2jsHints == other.generateDart2jsHints &&
          generateHints == other.generateHints;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, enableAsync.hashCode);
    hash = _JenkinsSmiHash.combine(hash, enableDeferredLoading.hashCode);
    hash = _JenkinsSmiHash.combine(hash, enableEnums.hashCode);
    hash = _JenkinsSmiHash.combine(hash, generateDart2jsHints.hashCode);
    hash = _JenkinsSmiHash.combine(hash, generateHints.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 *   OVERRIDES
 * }
 */
class AnalysisService {
  static const FOLDING = const AnalysisService._("FOLDING");

  static const HIGHLIGHTS = const AnalysisService._("HIGHLIGHTS");

  static const NAVIGATION = const AnalysisService._("NAVIGATION");

  static const OCCURRENCES = const AnalysisService._("OCCURRENCES");

  static const OUTLINE = const AnalysisService._("OUTLINE");

  static const OVERRIDES = const AnalysisService._("OVERRIDES");

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
      case "OVERRIDES":
        return OVERRIDES;
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
    throw jsonDecoder.mismatch(jsonPath, "AnalysisService");
  }

  @override
  String toString() => "AnalysisService.$name";

  String toJson() => name;
}

/**
 * AnalysisStatus
 *
 * {
 *   "isAnalyzing": bool
 *   "analysisTarget": optional String
 * }
 */
class AnalysisStatus implements HasToJson {
  /**
   * True if analysis is currently being performed.
   */
  bool isAnalyzing;

  /**
   * The name of the current target of analysis. This field is omitted if
   * analyzing is false.
   */
  String analysisTarget;

  AnalysisStatus(this.isAnalyzing, {this.analysisTarget});

  factory AnalysisStatus.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isAnalyzing;
      if (json.containsKey("isAnalyzing")) {
        isAnalyzing = jsonDecoder._decodeBool(jsonPath + ".isAnalyzing", json["isAnalyzing"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isAnalyzing");
      }
      String analysisTarget;
      if (json.containsKey("analysisTarget")) {
        analysisTarget = jsonDecoder._decodeString(jsonPath + ".analysisTarget", json["analysisTarget"]);
      }
      return new AnalysisStatus(isAnalyzing, analysisTarget: analysisTarget);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisStatus");
    }
  }

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
  bool operator==(other) {
    if (other is AnalysisStatus) {
      return isAnalyzing == other.isAnalyzing &&
          analysisTarget == other.analysisTarget;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, isAnalyzing.hashCode);
    hash = _JenkinsSmiHash.combine(hash, analysisTarget.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * ChangeContentOverlay
 *
 * {
 *   "type": "change"
 *   "edits": List<SourceEdit>
 * }
 */
class ChangeContentOverlay implements HasToJson {
  /**
   * The edits to be applied to the file.
   */
  List<SourceEdit> edits;

  ChangeContentOverlay(this.edits);

  factory ChangeContentOverlay.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      if (json["type"] != "change") {
        throw jsonDecoder.mismatch(jsonPath, "equal " + "change");
      }
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder._decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edits");
      }
      return new ChangeContentOverlay(edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ChangeContentOverlay");
    }
  }

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
      return _listEqual(edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, 873118866);
    hash = _JenkinsSmiHash.combine(hash, edits.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * CompletionRelevance
 *
 * enum {
 *   LOW
 *   DEFAULT
 *   HIGH
 * }
 */
class CompletionRelevance {
  static const LOW = const CompletionRelevance._("LOW");

  static const DEFAULT = const CompletionRelevance._("DEFAULT");

  static const HIGH = const CompletionRelevance._("HIGH");

  final String name;

  const CompletionRelevance._(this.name);

  factory CompletionRelevance(String name) {
    switch (name) {
      case "LOW":
        return LOW;
      case "DEFAULT":
        return DEFAULT;
      case "HIGH":
        return HIGH;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory CompletionRelevance.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new CompletionRelevance(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "CompletionRelevance");
  }

  @override
  String toString() => "CompletionRelevance.$name";

  String toJson() => name;
}

/**
 * CompletionSuggestion
 *
 * {
 *   "kind": CompletionSuggestionKind
 *   "relevance": CompletionRelevance
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
 *   "positionalParameterCount": optional int
 *   "parameterName": optional String
 *   "parameterType": optional String
 * }
 */
class CompletionSuggestion implements HasToJson {
  /**
   * The kind of element being suggested.
   */
  CompletionSuggestionKind kind;

  /**
   * The relevance of this completion suggestion.
   */
  CompletionRelevance relevance;

  /**
   * The identifier to be inserted if the suggestion is selected. If the
   * suggestion is for a method or function, the client might want to
   * additionally insert a template for the parameters. The information
   * required in order to do so is contained in other fields.
   */
  String completion;

  /**
   * The offset, relative to the beginning of the completion, of where the
   * selection should be placed after insertion.
   */
  int selectionOffset;

  /**
   * The number of characters that should be selected after insertion.
   */
  int selectionLength;

  /**
   * True if the suggested element is deprecated.
   */
  bool isDeprecated;

  /**
   * True if the element is not known to be valid for the target. This happens
   * if the type of the target is dynamic.
   */
  bool isPotential;

  /**
   * An abbreviated version of the Dartdoc associated with the element being
   * suggested, This field is omitted if there is no Dartdoc associated with
   * the element.
   */
  String docSummary;

  /**
   * The Dartdoc associated with the element being suggested, This field is
   * omitted if there is no Dartdoc associated with the element.
   */
  String docComplete;

  /**
   * The class that declares the element being suggested. This field is omitted
   * if the suggested element is not a member of a class.
   */
  String declaringType;

  /**
   * Information about the element reference being suggested.
   */
  Element element;

  /**
   * The return type of the getter, function or method being suggested. This
   * field is omitted if the suggested element is not a getter, function or
   * method.
   */
  String returnType;

  /**
   * The names of the parameters of the function or method being suggested.
   * This field is omitted if the suggested element is not a setter, function
   * or method.
   */
  List<String> parameterNames;

  /**
   * The types of the parameters of the function or method being suggested.
   * This field is omitted if the parameterNames field is omitted.
   */
  List<String> parameterTypes;

  /**
   * The number of required parameters for the function or method being
   * suggested. This field is omitted if the parameterNames field is omitted.
   */
  int requiredParameterCount;

  /**
   * The number of positional parameters for the function or method being
   * suggested. This field is omitted if the parameterNames field is omitted.
   */
  int positionalParameterCount;

  /**
   * The name of the optional parameter being suggested. This field is omitted
   * if the suggestion is not the addition of an optional argument within an
   * argument list.
   */
  String parameterName;

  /**
   * The type of the options parameter being suggested. This field is omitted
   * if the parameterName field is omitted.
   */
  String parameterType;

  CompletionSuggestion(this.kind, this.relevance, this.completion, this.selectionOffset, this.selectionLength, this.isDeprecated, this.isPotential, {this.docSummary, this.docComplete, this.declaringType, this.element, this.returnType, this.parameterNames, this.parameterTypes, this.requiredParameterCount, this.positionalParameterCount, this.parameterName, this.parameterType}) {
    if (parameterNames == null) {
      parameterNames = <String>[];
    }
    if (parameterTypes == null) {
      parameterTypes = <String>[];
    }
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
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      CompletionRelevance relevance;
      if (json.containsKey("relevance")) {
        relevance = new CompletionRelevance.fromJson(jsonDecoder, jsonPath + ".relevance", json["relevance"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "relevance");
      }
      String completion;
      if (json.containsKey("completion")) {
        completion = jsonDecoder._decodeString(jsonPath + ".completion", json["completion"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "completion");
      }
      int selectionOffset;
      if (json.containsKey("selectionOffset")) {
        selectionOffset = jsonDecoder._decodeInt(jsonPath + ".selectionOffset", json["selectionOffset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "selectionOffset");
      }
      int selectionLength;
      if (json.containsKey("selectionLength")) {
        selectionLength = jsonDecoder._decodeInt(jsonPath + ".selectionLength", json["selectionLength"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "selectionLength");
      }
      bool isDeprecated;
      if (json.containsKey("isDeprecated")) {
        isDeprecated = jsonDecoder._decodeBool(jsonPath + ".isDeprecated", json["isDeprecated"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isDeprecated");
      }
      bool isPotential;
      if (json.containsKey("isPotential")) {
        isPotential = jsonDecoder._decodeBool(jsonPath + ".isPotential", json["isPotential"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isPotential");
      }
      String docSummary;
      if (json.containsKey("docSummary")) {
        docSummary = jsonDecoder._decodeString(jsonPath + ".docSummary", json["docSummary"]);
      }
      String docComplete;
      if (json.containsKey("docComplete")) {
        docComplete = jsonDecoder._decodeString(jsonPath + ".docComplete", json["docComplete"]);
      }
      String declaringType;
      if (json.containsKey("declaringType")) {
        declaringType = jsonDecoder._decodeString(jsonPath + ".declaringType", json["declaringType"]);
      }
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      }
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder._decodeString(jsonPath + ".returnType", json["returnType"]);
      }
      List<String> parameterNames;
      if (json.containsKey("parameterNames")) {
        parameterNames = jsonDecoder._decodeList(jsonPath + ".parameterNames", json["parameterNames"], jsonDecoder._decodeString);
      } else {
        parameterNames = <String>[];
      }
      List<String> parameterTypes;
      if (json.containsKey("parameterTypes")) {
        parameterTypes = jsonDecoder._decodeList(jsonPath + ".parameterTypes", json["parameterTypes"], jsonDecoder._decodeString);
      } else {
        parameterTypes = <String>[];
      }
      int requiredParameterCount;
      if (json.containsKey("requiredParameterCount")) {
        requiredParameterCount = jsonDecoder._decodeInt(jsonPath + ".requiredParameterCount", json["requiredParameterCount"]);
      }
      int positionalParameterCount;
      if (json.containsKey("positionalParameterCount")) {
        positionalParameterCount = jsonDecoder._decodeInt(jsonPath + ".positionalParameterCount", json["positionalParameterCount"]);
      }
      String parameterName;
      if (json.containsKey("parameterName")) {
        parameterName = jsonDecoder._decodeString(jsonPath + ".parameterName", json["parameterName"]);
      }
      String parameterType;
      if (json.containsKey("parameterType")) {
        parameterType = jsonDecoder._decodeString(jsonPath + ".parameterType", json["parameterType"]);
      }
      return new CompletionSuggestion(kind, relevance, completion, selectionOffset, selectionLength, isDeprecated, isPotential, docSummary: docSummary, docComplete: docComplete, declaringType: declaringType, element: element, returnType: returnType, parameterNames: parameterNames, parameterTypes: parameterTypes, requiredParameterCount: requiredParameterCount, positionalParameterCount: positionalParameterCount, parameterName: parameterName, parameterType: parameterType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "CompletionSuggestion");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["kind"] = kind.toJson();
    result["relevance"] = relevance.toJson();
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
    if (parameterNames.isNotEmpty) {
      result["parameterNames"] = parameterNames;
    }
    if (parameterTypes.isNotEmpty) {
      result["parameterTypes"] = parameterTypes;
    }
    if (requiredParameterCount != null) {
      result["requiredParameterCount"] = requiredParameterCount;
    }
    if (positionalParameterCount != null) {
      result["positionalParameterCount"] = positionalParameterCount;
    }
    if (parameterName != null) {
      result["parameterName"] = parameterName;
    }
    if (parameterType != null) {
      result["parameterType"] = parameterType;
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
          _listEqual(parameterNames, other.parameterNames, (String a, String b) => a == b) &&
          _listEqual(parameterTypes, other.parameterTypes, (String a, String b) => a == b) &&
          requiredParameterCount == other.requiredParameterCount &&
          positionalParameterCount == other.positionalParameterCount &&
          parameterName == other.parameterName &&
          parameterType == other.parameterType;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, relevance.hashCode);
    hash = _JenkinsSmiHash.combine(hash, completion.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    hash = _JenkinsSmiHash.combine(hash, isDeprecated.hashCode);
    hash = _JenkinsSmiHash.combine(hash, isPotential.hashCode);
    hash = _JenkinsSmiHash.combine(hash, docSummary.hashCode);
    hash = _JenkinsSmiHash.combine(hash, docComplete.hashCode);
    hash = _JenkinsSmiHash.combine(hash, declaringType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, element.hashCode);
    hash = _JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameterNames.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameterTypes.hashCode);
    hash = _JenkinsSmiHash.combine(hash, requiredParameterCount.hashCode);
    hash = _JenkinsSmiHash.combine(hash, positionalParameterCount.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameterName.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameterType.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * CompletionSuggestionKind
 *
 * enum {
 *   ARGUMENT_LIST
 *   CLASS
 *   CLASS_ALIAS
 *   CONSTRUCTOR
 *   FIELD
 *   FUNCTION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER
 *   IMPORT
 *   KEYWORD
 *   LABEL
 *   LIBRARY_PREFIX
 *   LOCAL_VARIABLE
 *   METHOD
 *   METHOD_NAME
 *   NAMED_ARGUMENT
 *   OPTIONAL_ARGUMENT
 *   PARAMETER
 *   SETTER
 *   TOP_LEVEL_VARIABLE
 *   TYPE_PARAMETER
 * }
 */
class CompletionSuggestionKind {
  static const ARGUMENT_LIST = const CompletionSuggestionKind._("ARGUMENT_LIST");

  static const CLASS = const CompletionSuggestionKind._("CLASS");

  static const CLASS_ALIAS = const CompletionSuggestionKind._("CLASS_ALIAS");

  static const CONSTRUCTOR = const CompletionSuggestionKind._("CONSTRUCTOR");

  static const FIELD = const CompletionSuggestionKind._("FIELD");

  static const FUNCTION = const CompletionSuggestionKind._("FUNCTION");

  static const FUNCTION_TYPE_ALIAS = const CompletionSuggestionKind._("FUNCTION_TYPE_ALIAS");

  static const GETTER = const CompletionSuggestionKind._("GETTER");

  static const IMPORT = const CompletionSuggestionKind._("IMPORT");

  static const KEYWORD = const CompletionSuggestionKind._("KEYWORD");

  static const LABEL = const CompletionSuggestionKind._("LABEL");

  static const LIBRARY_PREFIX = const CompletionSuggestionKind._("LIBRARY_PREFIX");

  static const LOCAL_VARIABLE = const CompletionSuggestionKind._("LOCAL_VARIABLE");

  static const METHOD = const CompletionSuggestionKind._("METHOD");

  static const METHOD_NAME = const CompletionSuggestionKind._("METHOD_NAME");

  static const NAMED_ARGUMENT = const CompletionSuggestionKind._("NAMED_ARGUMENT");

  static const OPTIONAL_ARGUMENT = const CompletionSuggestionKind._("OPTIONAL_ARGUMENT");

  static const PARAMETER = const CompletionSuggestionKind._("PARAMETER");

  static const SETTER = const CompletionSuggestionKind._("SETTER");

  static const TOP_LEVEL_VARIABLE = const CompletionSuggestionKind._("TOP_LEVEL_VARIABLE");

  static const TYPE_PARAMETER = const CompletionSuggestionKind._("TYPE_PARAMETER");

  final String name;

  const CompletionSuggestionKind._(this.name);

  factory CompletionSuggestionKind(String name) {
    switch (name) {
      case "ARGUMENT_LIST":
        return ARGUMENT_LIST;
      case "CLASS":
        return CLASS;
      case "CLASS_ALIAS":
        return CLASS_ALIAS;
      case "CONSTRUCTOR":
        return CONSTRUCTOR;
      case "FIELD":
        return FIELD;
      case "FUNCTION":
        return FUNCTION;
      case "FUNCTION_TYPE_ALIAS":
        return FUNCTION_TYPE_ALIAS;
      case "GETTER":
        return GETTER;
      case "IMPORT":
        return IMPORT;
      case "KEYWORD":
        return KEYWORD;
      case "LABEL":
        return LABEL;
      case "LIBRARY_PREFIX":
        return LIBRARY_PREFIX;
      case "LOCAL_VARIABLE":
        return LOCAL_VARIABLE;
      case "METHOD":
        return METHOD;
      case "METHOD_NAME":
        return METHOD_NAME;
      case "NAMED_ARGUMENT":
        return NAMED_ARGUMENT;
      case "OPTIONAL_ARGUMENT":
        return OPTIONAL_ARGUMENT;
      case "PARAMETER":
        return PARAMETER;
      case "SETTER":
        return SETTER;
      case "TOP_LEVEL_VARIABLE":
        return TOP_LEVEL_VARIABLE;
      case "TYPE_PARAMETER":
        return TYPE_PARAMETER;
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
    throw jsonDecoder.mismatch(jsonPath, "CompletionSuggestionKind");
  }

  /**
   * Construct from an analyzer engine element kind.
   */
  factory CompletionSuggestionKind.fromElementKind(engine.ElementKind kind) =>
      _completionSuggestionKindFromElementKind(kind);

  @override
  String toString() => "CompletionSuggestionKind.$name";

  String toJson() => name;
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
 * }
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

  /**
   * The kind of the element.
   */
  ElementKind kind;

  /**
   * The name of the element. This is typically used as the label in the
   * outline.
   */
  String name;

  /**
   * The location of the name in the declaration of the element.
   */
  Location location;

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
  int flags;

  /**
   * The parameter list for the element. If the element is not a method or
   * function this field will not be defined. If the element has zero
   * parameters, this field will have a value of "()".
   */
  String parameters;

  /**
   * The return type of the element. If the element is not a method or function
   * this field will not be defined. If the element does not have a declared
   * return type, this field will contain an empty string.
   */
  String returnType;

  Element(this.kind, this.name, this.flags, {this.location, this.parameters, this.returnType});

  factory Element.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      ElementKind kind;
      if (json.containsKey("kind")) {
        kind = new ElementKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      }
      int flags;
      if (json.containsKey("flags")) {
        flags = jsonDecoder._decodeInt(jsonPath + ".flags", json["flags"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "flags");
      }
      String parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder._decodeString(jsonPath + ".parameters", json["parameters"]);
      }
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder._decodeString(jsonPath + ".returnType", json["returnType"]);
      }
      return new Element(kind, name, flags, location: location, parameters: parameters, returnType: returnType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Element");
    }
  }

  /**
   * Construct based on a value from the analyzer engine.
   */
  factory Element.fromEngine(engine.Element element) =>
      elementFromEngine(element);

  bool get isAbstract => (flags & FLAG_ABSTRACT) != 0;
  bool get isConst => (flags & FLAG_CONST) != 0;
  bool get isFinal => (flags & FLAG_FINAL) != 0;
  bool get isStatic => (flags & FLAG_STATIC) != 0;
  bool get isPrivate => (flags & FLAG_PRIVATE) != 0;
  bool get isDeprecated => (flags & FLAG_DEPRECATED) != 0;

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
          returnType == other.returnType;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    hash = _JenkinsSmiHash.combine(hash, location.hashCode);
    hash = _JenkinsSmiHash.combine(hash, flags.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = _JenkinsSmiHash.combine(hash, returnType.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 *   FIELD
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
 *   UNIT_TEST_GROUP
 *   UNIT_TEST_TEST
 *   UNKNOWN
 * }
 */
class ElementKind {
  static const CLASS = const ElementKind._("CLASS");

  static const CLASS_TYPE_ALIAS = const ElementKind._("CLASS_TYPE_ALIAS");

  static const COMPILATION_UNIT = const ElementKind._("COMPILATION_UNIT");

  static const CONSTRUCTOR = const ElementKind._("CONSTRUCTOR");

  static const FIELD = const ElementKind._("FIELD");

  static const FUNCTION = const ElementKind._("FUNCTION");

  static const FUNCTION_TYPE_ALIAS = const ElementKind._("FUNCTION_TYPE_ALIAS");

  static const GETTER = const ElementKind._("GETTER");

  static const LABEL = const ElementKind._("LABEL");

  static const LIBRARY = const ElementKind._("LIBRARY");

  static const LOCAL_VARIABLE = const ElementKind._("LOCAL_VARIABLE");

  static const METHOD = const ElementKind._("METHOD");

  static const PARAMETER = const ElementKind._("PARAMETER");

  static const PREFIX = const ElementKind._("PREFIX");

  static const SETTER = const ElementKind._("SETTER");

  static const TOP_LEVEL_VARIABLE = const ElementKind._("TOP_LEVEL_VARIABLE");

  static const TYPE_PARAMETER = const ElementKind._("TYPE_PARAMETER");

  static const UNIT_TEST_GROUP = const ElementKind._("UNIT_TEST_GROUP");

  static const UNIT_TEST_TEST = const ElementKind._("UNIT_TEST_TEST");

  static const UNKNOWN = const ElementKind._("UNKNOWN");

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
      case "FIELD":
        return FIELD;
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
      case "UNIT_TEST_GROUP":
        return UNIT_TEST_GROUP;
      case "UNIT_TEST_TEST":
        return UNIT_TEST_TEST;
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
    throw jsonDecoder.mismatch(jsonPath, "ElementKind");
  }

  /**
   * Construct based on a value from the analyzer engine.
   */
  factory ElementKind.fromEngine(engine.ElementKind kind) =>
      _elementKindFromEngine(kind);

  @override
  String toString() => "ElementKind.$name";

  String toJson() => name;
}

/**
 * ExecutableFile
 *
 * {
 *   "file": FilePath
 *   "kind": ExecutableKind
 * }
 */
class ExecutableFile implements HasToJson {
  /**
   * The path of the executable file.
   */
  String file;

  /**
   * The kind of the executable file.
   */
  ExecutableKind kind;

  ExecutableFile(this.file, this.kind);

  factory ExecutableFile.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      ExecutableKind kind;
      if (json.containsKey("kind")) {
        kind = new ExecutableKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      return new ExecutableFile(file, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ExecutableFile");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    result["kind"] = kind.toJson();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ExecutableFile) {
      return file == other.file &&
          kind == other.kind;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * ExecutableKind
 *
 * enum {
 *   CLIENT
 *   EITHER
 *   SERVER
 * }
 */
class ExecutableKind {
  static const CLIENT = const ExecutableKind._("CLIENT");

  static const EITHER = const ExecutableKind._("EITHER");

  static const SERVER = const ExecutableKind._("SERVER");

  final String name;

  const ExecutableKind._(this.name);

  factory ExecutableKind(String name) {
    switch (name) {
      case "CLIENT":
        return CLIENT;
      case "EITHER":
        return EITHER;
      case "SERVER":
        return SERVER;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ExecutableKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ExecutableKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ExecutableKind");
  }

  @override
  String toString() => "ExecutableKind.$name";

  String toJson() => name;
}

/**
 * ExecutionService
 *
 * enum {
 *   LAUNCH_DATA
 * }
 */
class ExecutionService {
  static const LAUNCH_DATA = const ExecutionService._("LAUNCH_DATA");

  final String name;

  const ExecutionService._(this.name);

  factory ExecutionService(String name) {
    switch (name) {
      case "LAUNCH_DATA":
        return LAUNCH_DATA;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ExecutionService.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ExecutionService(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ExecutionService");
  }

  @override
  String toString() => "ExecutionService.$name";

  String toJson() => name;
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
 */
class FoldingKind {
  static const COMMENT = const FoldingKind._("COMMENT");

  static const CLASS_MEMBER = const FoldingKind._("CLASS_MEMBER");

  static const DIRECTIVES = const FoldingKind._("DIRECTIVES");

  static const DOCUMENTATION_COMMENT = const FoldingKind._("DOCUMENTATION_COMMENT");

  static const TOP_LEVEL_DECLARATION = const FoldingKind._("TOP_LEVEL_DECLARATION");

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
    throw jsonDecoder.mismatch(jsonPath, "FoldingKind");
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
 */
class FoldingRegion implements HasToJson {
  /**
   * The kind of the region.
   */
  FoldingKind kind;

  /**
   * The offset of the region to be folded.
   */
  int offset;

  /**
   * The length of the region to be folded.
   */
  int length;

  FoldingRegion(this.kind, this.offset, this.length);

  factory FoldingRegion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      FoldingKind kind;
      if (json.containsKey("kind")) {
        kind = new FoldingKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      return new FoldingRegion(kind, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "FoldingRegion");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class HighlightRegion implements HasToJson {
  /**
   * The type of highlight associated with the region.
   */
  HighlightRegionType type;

  /**
   * The offset of the region to be highlighted.
   */
  int offset;

  /**
   * The length of the region to be highlighted.
   */
  int length;

  HighlightRegion(this.type, this.offset, this.length);

  factory HighlightRegion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      HighlightRegionType type;
      if (json.containsKey("type")) {
        type = new HighlightRegionType.fromJson(jsonDecoder, jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "type");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      return new HighlightRegion(type, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "HighlightRegion");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, type.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 *   FIELD
 *   FIELD_STATIC
 *   FUNCTION
 *   FUNCTION_DECLARATION
 *   FUNCTION_TYPE_ALIAS
 *   GETTER_DECLARATION
 *   IDENTIFIER_DEFAULT
 *   IMPORT_PREFIX
 *   KEYWORD
 *   LABEL
 *   LITERAL_BOOLEAN
 *   LITERAL_DOUBLE
 *   LITERAL_INTEGER
 *   LITERAL_LIST
 *   LITERAL_MAP
 *   LITERAL_STRING
 *   LOCAL_VARIABLE
 *   LOCAL_VARIABLE_DECLARATION
 *   METHOD
 *   METHOD_DECLARATION
 *   METHOD_DECLARATION_STATIC
 *   METHOD_STATIC
 *   PARAMETER
 *   SETTER_DECLARATION
 *   TOP_LEVEL_VARIABLE
 *   TYPE_NAME_DYNAMIC
 *   TYPE_PARAMETER
 * }
 */
class HighlightRegionType {
  static const ANNOTATION = const HighlightRegionType._("ANNOTATION");

  static const BUILT_IN = const HighlightRegionType._("BUILT_IN");

  static const CLASS = const HighlightRegionType._("CLASS");

  static const COMMENT_BLOCK = const HighlightRegionType._("COMMENT_BLOCK");

  static const COMMENT_DOCUMENTATION = const HighlightRegionType._("COMMENT_DOCUMENTATION");

  static const COMMENT_END_OF_LINE = const HighlightRegionType._("COMMENT_END_OF_LINE");

  static const CONSTRUCTOR = const HighlightRegionType._("CONSTRUCTOR");

  static const DIRECTIVE = const HighlightRegionType._("DIRECTIVE");

  static const DYNAMIC_TYPE = const HighlightRegionType._("DYNAMIC_TYPE");

  static const FIELD = const HighlightRegionType._("FIELD");

  static const FIELD_STATIC = const HighlightRegionType._("FIELD_STATIC");

  static const FUNCTION = const HighlightRegionType._("FUNCTION");

  static const FUNCTION_DECLARATION = const HighlightRegionType._("FUNCTION_DECLARATION");

  static const FUNCTION_TYPE_ALIAS = const HighlightRegionType._("FUNCTION_TYPE_ALIAS");

  static const GETTER_DECLARATION = const HighlightRegionType._("GETTER_DECLARATION");

  static const IDENTIFIER_DEFAULT = const HighlightRegionType._("IDENTIFIER_DEFAULT");

  static const IMPORT_PREFIX = const HighlightRegionType._("IMPORT_PREFIX");

  static const KEYWORD = const HighlightRegionType._("KEYWORD");

  static const LABEL = const HighlightRegionType._("LABEL");

  static const LITERAL_BOOLEAN = const HighlightRegionType._("LITERAL_BOOLEAN");

  static const LITERAL_DOUBLE = const HighlightRegionType._("LITERAL_DOUBLE");

  static const LITERAL_INTEGER = const HighlightRegionType._("LITERAL_INTEGER");

  static const LITERAL_LIST = const HighlightRegionType._("LITERAL_LIST");

  static const LITERAL_MAP = const HighlightRegionType._("LITERAL_MAP");

  static const LITERAL_STRING = const HighlightRegionType._("LITERAL_STRING");

  static const LOCAL_VARIABLE = const HighlightRegionType._("LOCAL_VARIABLE");

  static const LOCAL_VARIABLE_DECLARATION = const HighlightRegionType._("LOCAL_VARIABLE_DECLARATION");

  static const METHOD = const HighlightRegionType._("METHOD");

  static const METHOD_DECLARATION = const HighlightRegionType._("METHOD_DECLARATION");

  static const METHOD_DECLARATION_STATIC = const HighlightRegionType._("METHOD_DECLARATION_STATIC");

  static const METHOD_STATIC = const HighlightRegionType._("METHOD_STATIC");

  static const PARAMETER = const HighlightRegionType._("PARAMETER");

  static const SETTER_DECLARATION = const HighlightRegionType._("SETTER_DECLARATION");

  static const TOP_LEVEL_VARIABLE = const HighlightRegionType._("TOP_LEVEL_VARIABLE");

  static const TYPE_NAME_DYNAMIC = const HighlightRegionType._("TYPE_NAME_DYNAMIC");

  static const TYPE_PARAMETER = const HighlightRegionType._("TYPE_PARAMETER");

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
      case "KEYWORD":
        return KEYWORD;
      case "LABEL":
        return LABEL;
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
      case "LOCAL_VARIABLE":
        return LOCAL_VARIABLE;
      case "LOCAL_VARIABLE_DECLARATION":
        return LOCAL_VARIABLE_DECLARATION;
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
      case "TYPE_NAME_DYNAMIC":
        return TYPE_NAME_DYNAMIC;
      case "TYPE_PARAMETER":
        return TYPE_PARAMETER;
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
    throw jsonDecoder.mismatch(jsonPath, "HighlightRegionType");
  }

  @override
  String toString() => "HighlightRegionType.$name";

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
 *   "dartdoc": optional String
 *   "elementDescription": optional String
 *   "elementKind": optional String
 *   "parameter": optional String
 *   "propagatedType": optional String
 *   "staticType": optional String
 * }
 */
class HoverInformation implements HasToJson {
  /**
   * The offset of the range of characters that encompases the cursor position
   * and has the same hover information as the cursor position.
   */
  int offset;

  /**
   * The length of the range of characters that encompases the cursor position
   * and has the same hover information as the cursor position.
   */
  int length;

  /**
   * The path to the defining compilation unit of the library in which the
   * referenced element is declared. This data is omitted if there is no
   * referenced element, or if the element is declared inside an HTML file.
   */
  String containingLibraryPath;

  /**
   * The name of the library in which the referenced element is declared. This
   * data is omitted if there is no referenced element, or if the element is
   * declared inside an HTML file.
   */
  String containingLibraryName;

  /**
   * The dartdoc associated with the referenced element. Other than the removal
   * of the comment delimiters, including leading asterisks in the case of a
   * block comment, the dartdoc is unprocessed markdown. This data is omitted
   * if there is no referenced element, or if the element has no dartdoc.
   */
  String dartdoc;

  /**
   * A human-readable description of the element being referenced. This data is
   * omitted if there is no referenced element.
   */
  String elementDescription;

  /**
   * A human-readable description of the kind of element being referenced (such
   * as “class” or “function type alias”). This data is omitted if there is no
   * referenced element.
   */
  String elementKind;

  /**
   * A human-readable description of the parameter corresponding to the
   * expression being hovered over. This data is omitted if the location is not
   * in an argument to a function.
   */
  String parameter;

  /**
   * The name of the propagated type of the expression. This data is omitted if
   * the location does not correspond to an expression or if there is no
   * propagated type information.
   */
  String propagatedType;

  /**
   * The name of the static type of the expression. This data is omitted if the
   * location does not correspond to an expression.
   */
  String staticType;

  HoverInformation(this.offset, this.length, {this.containingLibraryPath, this.containingLibraryName, this.dartdoc, this.elementDescription, this.elementKind, this.parameter, this.propagatedType, this.staticType});

  factory HoverInformation.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      String containingLibraryPath;
      if (json.containsKey("containingLibraryPath")) {
        containingLibraryPath = jsonDecoder._decodeString(jsonPath + ".containingLibraryPath", json["containingLibraryPath"]);
      }
      String containingLibraryName;
      if (json.containsKey("containingLibraryName")) {
        containingLibraryName = jsonDecoder._decodeString(jsonPath + ".containingLibraryName", json["containingLibraryName"]);
      }
      String dartdoc;
      if (json.containsKey("dartdoc")) {
        dartdoc = jsonDecoder._decodeString(jsonPath + ".dartdoc", json["dartdoc"]);
      }
      String elementDescription;
      if (json.containsKey("elementDescription")) {
        elementDescription = jsonDecoder._decodeString(jsonPath + ".elementDescription", json["elementDescription"]);
      }
      String elementKind;
      if (json.containsKey("elementKind")) {
        elementKind = jsonDecoder._decodeString(jsonPath + ".elementKind", json["elementKind"]);
      }
      String parameter;
      if (json.containsKey("parameter")) {
        parameter = jsonDecoder._decodeString(jsonPath + ".parameter", json["parameter"]);
      }
      String propagatedType;
      if (json.containsKey("propagatedType")) {
        propagatedType = jsonDecoder._decodeString(jsonPath + ".propagatedType", json["propagatedType"]);
      }
      String staticType;
      if (json.containsKey("staticType")) {
        staticType = jsonDecoder._decodeString(jsonPath + ".staticType", json["staticType"]);
      }
      return new HoverInformation(offset, length, containingLibraryPath: containingLibraryPath, containingLibraryName: containingLibraryName, dartdoc: dartdoc, elementDescription: elementDescription, elementKind: elementKind, parameter: parameter, propagatedType: propagatedType, staticType: staticType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "HoverInformation");
    }
  }

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
    if (dartdoc != null) {
      result["dartdoc"] = dartdoc;
    }
    if (elementDescription != null) {
      result["elementDescription"] = elementDescription;
    }
    if (elementKind != null) {
      result["elementKind"] = elementKind;
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
  bool operator==(other) {
    if (other is HoverInformation) {
      return offset == other.offset &&
          length == other.length &&
          containingLibraryPath == other.containingLibraryPath &&
          containingLibraryName == other.containingLibraryName &&
          dartdoc == other.dartdoc &&
          elementDescription == other.elementDescription &&
          elementKind == other.elementKind &&
          parameter == other.parameter &&
          propagatedType == other.propagatedType &&
          staticType == other.staticType;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, containingLibraryPath.hashCode);
    hash = _JenkinsSmiHash.combine(hash, containingLibraryName.hashCode);
    hash = _JenkinsSmiHash.combine(hash, dartdoc.hashCode);
    hash = _JenkinsSmiHash.combine(hash, elementDescription.hashCode);
    hash = _JenkinsSmiHash.combine(hash, elementKind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameter.hashCode);
    hash = _JenkinsSmiHash.combine(hash, propagatedType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, staticType.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class LinkedEditGroup implements HasToJson {
  /**
   * The positions of the regions that should be edited simultaneously.
   */
  List<Position> positions;

  /**
   * The length of the regions that should be edited simultaneously.
   */
  int length;

  /**
   * Pre-computed suggestions for what every region might want to be changed
   * to.
   */
  List<LinkedEditSuggestion> suggestions;

  LinkedEditGroup(this.positions, this.length, this.suggestions);

  factory LinkedEditGroup.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<Position> positions;
      if (json.containsKey("positions")) {
        positions = jsonDecoder._decodeList(jsonPath + ".positions", json["positions"], (String jsonPath, Object json) => new Position.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "positions");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      List<LinkedEditSuggestion> suggestions;
      if (json.containsKey("suggestions")) {
        suggestions = jsonDecoder._decodeList(jsonPath + ".suggestions", json["suggestions"], (String jsonPath, Object json) => new LinkedEditSuggestion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "suggestions");
      }
      return new LinkedEditGroup(positions, length, suggestions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "LinkedEditGroup");
    }
  }

  /**
   * Construct an empty LinkedEditGroup.
   */
  LinkedEditGroup.empty() : this(<Position>[], 0, <LinkedEditSuggestion>[]);

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
      return _listEqual(positions, other.positions, (Position a, Position b) => a == b) &&
          length == other.length &&
          _listEqual(suggestions, other.suggestions, (LinkedEditSuggestion a, LinkedEditSuggestion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, positions.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, suggestions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * LinkedEditSuggestion
 *
 * {
 *   "value": String
 *   "kind": LinkedEditSuggestionKind
 * }
 */
class LinkedEditSuggestion implements HasToJson {
  /**
   * The value that could be used to replace all of the linked edit regions.
   */
  String value;

  /**
   * The kind of value being proposed.
   */
  LinkedEditSuggestionKind kind;

  LinkedEditSuggestion(this.value, this.kind);

  factory LinkedEditSuggestion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String value;
      if (json.containsKey("value")) {
        value = jsonDecoder._decodeString(jsonPath + ".value", json["value"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "value");
      }
      LinkedEditSuggestionKind kind;
      if (json.containsKey("kind")) {
        kind = new LinkedEditSuggestionKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      return new LinkedEditSuggestion(value, kind);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "LinkedEditSuggestion");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, value.hashCode);
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class LinkedEditSuggestionKind {
  static const METHOD = const LinkedEditSuggestionKind._("METHOD");

  static const PARAMETER = const LinkedEditSuggestionKind._("PARAMETER");

  static const TYPE = const LinkedEditSuggestionKind._("TYPE");

  static const VARIABLE = const LinkedEditSuggestionKind._("VARIABLE");

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
    throw jsonDecoder.mismatch(jsonPath, "LinkedEditSuggestionKind");
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
 */
class Location implements HasToJson {
  /**
   * The file containing the range.
   */
  String file;

  /**
   * The offset of the range.
   */
  int offset;

  /**
   * The length of the range.
   */
  int length;

  /**
   * The one-based index of the line containing the first character of the
   * range.
   */
  int startLine;

  /**
   * The one-based index of the column containing the first character of the
   * range.
   */
  int startColumn;

  Location(this.file, this.offset, this.length, this.startLine, this.startColumn);

  factory Location.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      int startLine;
      if (json.containsKey("startLine")) {
        startLine = jsonDecoder._decodeInt(jsonPath + ".startLine", json["startLine"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "startLine");
      }
      int startColumn;
      if (json.containsKey("startColumn")) {
        startColumn = jsonDecoder._decodeInt(jsonPath + ".startColumn", json["startColumn"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "startColumn");
      }
      return new Location(file, offset, length, startLine, startColumn);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Location");
    }
  }

  /**
   * Create a Location based on an [engine.Element].
   */
  factory Location.fromElement(engine.Element element) =>
      _locationFromElement(element);

  /**
   * Create a Location based on an [engine.SearchMatch].
   */
  factory Location.fromMatch(engine.SearchMatch match) =>
      _locationFromMatch(match);

  /**
   * Create a Location based on an [engine.AstNode].
   */
  factory Location.fromNode(engine.AstNode node) =>
      _locationFromNode(node);

  /**
   * Create a Location based on an [engine.CompilationUnit].
   */
  factory Location.fromUnit(engine.CompilationUnit unit, engine.SourceRange range) =>
      _locationFromUnit(unit, range);

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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = _JenkinsSmiHash.combine(hash, startColumn.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * NavigationRegion
 *
 * {
 *   "offset": int
 *   "length": int
 *   "targets": List<Element>
 * }
 */
class NavigationRegion implements HasToJson {
  /**
   * The offset of the region from which the user can navigate.
   */
  int offset;

  /**
   * The length of the region from which the user can navigate.
   */
  int length;

  /**
   * The elements to which the given region is bound. By opening the
   * declaration of the elements, clients can implement one form of navigation.
   */
  List<Element> targets;

  NavigationRegion(this.offset, this.length, this.targets);

  factory NavigationRegion.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      List<Element> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder._decodeList(jsonPath + ".targets", json["targets"], (String jsonPath, Object json) => new Element.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "targets");
      }
      return new NavigationRegion(offset, length, targets);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "NavigationRegion");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    result["targets"] = targets.map((Element value) => value.toJson()).toList();
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is NavigationRegion) {
      return offset == other.offset &&
          length == other.length &&
          _listEqual(targets, other.targets, (Element a, Element b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, targets.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class Occurrences implements HasToJson {
  /**
   * The element that was referenced.
   */
  Element element;

  /**
   * The offsets of the name of the referenced element within the file.
   */
  List<int> offsets;

  /**
   * The length of the name of the referenced element.
   */
  int length;

  Occurrences(this.element, this.offsets, this.length);

  factory Occurrences.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "element");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder._decodeList(jsonPath + ".offsets", json["offsets"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offsets");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      return new Occurrences(element, offsets, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Occurrences");
    }
  }

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
          _listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          length == other.length;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, element.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class Outline implements HasToJson {
  /**
   * A description of the element represented by this node.
   */
  Element element;

  /**
   * The offset of the first character of the element. This is different than
   * the offset in the Element, which if the offset of the name of the element.
   * It can be used, for example, to map locations in the file back to an
   * outline.
   */
  int offset;

  /**
   * The length of the element.
   */
  int length;

  /**
   * The children of the node. The field will be omitted if the node has no
   * children.
   */
  List<Outline> children;

  Outline(this.element, this.offset, this.length, {this.children}) {
    if (children == null) {
      children = <Outline>[];
    }
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
        throw jsonDecoder.missingKey(jsonPath, "element");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      List<Outline> children;
      if (json.containsKey("children")) {
        children = jsonDecoder._decodeList(jsonPath + ".children", json["children"], (String jsonPath, Object json) => new Outline.fromJson(jsonDecoder, jsonPath, json));
      } else {
        children = <Outline>[];
      }
      return new Outline(element, offset, length, children: children);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Outline");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["element"] = element.toJson();
    result["offset"] = offset;
    result["length"] = length;
    if (children.isNotEmpty) {
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
          _listEqual(children, other.children, (Outline a, Outline b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, element.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, children.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class Override implements HasToJson {
  /**
   * The offset of the name of the overriding member.
   */
  int offset;

  /**
   * The length of the name of the overriding member.
   */
  int length;

  /**
   * The member inherited from a superclass that is overridden by the
   * overriding member. The field is omitted if there is no superclass member,
   * in which case there must be at least one interface member.
   */
  OverriddenMember superclassMember;

  /**
   * The members inherited from interfaces that are overridden by the
   * overriding member. The field is omitted if there are no interface members,
   * in which case there must be a superclass member.
   */
  List<OverriddenMember> interfaceMembers;

  Override(this.offset, this.length, {this.superclassMember, this.interfaceMembers}) {
    if (interfaceMembers == null) {
      interfaceMembers = <OverriddenMember>[];
    }
  }

  factory Override.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      OverriddenMember superclassMember;
      if (json.containsKey("superclassMember")) {
        superclassMember = new OverriddenMember.fromJson(jsonDecoder, jsonPath + ".superclassMember", json["superclassMember"]);
      }
      List<OverriddenMember> interfaceMembers;
      if (json.containsKey("interfaceMembers")) {
        interfaceMembers = jsonDecoder._decodeList(jsonPath + ".interfaceMembers", json["interfaceMembers"], (String jsonPath, Object json) => new OverriddenMember.fromJson(jsonDecoder, jsonPath, json));
      } else {
        interfaceMembers = <OverriddenMember>[];
      }
      return new Override(offset, length, superclassMember: superclassMember, interfaceMembers: interfaceMembers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Override");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    if (superclassMember != null) {
      result["superclassMember"] = superclassMember.toJson();
    }
    if (interfaceMembers.isNotEmpty) {
      result["interfaceMembers"] = interfaceMembers.map((OverriddenMember value) => value.toJson()).toList();
    }
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is Override) {
      return offset == other.offset &&
          length == other.length &&
          superclassMember == other.superclassMember &&
          _listEqual(interfaceMembers, other.interfaceMembers, (OverriddenMember a, OverriddenMember b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, superclassMember.hashCode);
    hash = _JenkinsSmiHash.combine(hash, interfaceMembers.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * OverriddenMember
 *
 * {
 *   "element": Element
 *   "className": String
 * }
 */
class OverriddenMember implements HasToJson {
  /**
   * The element that is being overridden.
   */
  Element element;

  /**
   * The name of the class in which the member is defined.
   */
  String className;

  OverriddenMember(this.element, this.className);

  factory OverriddenMember.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element element;
      if (json.containsKey("element")) {
        element = new Element.fromJson(jsonDecoder, jsonPath + ".element", json["element"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "element");
      }
      String className;
      if (json.containsKey("className")) {
        className = jsonDecoder._decodeString(jsonPath + ".className", json["className"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "className");
      }
      return new OverriddenMember(element, className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "OverriddenMember");
    }
  }

  /**
   * Construct based on an element from the analyzer engine.
   */
  factory OverriddenMember.fromEngine(engine.Element member) =>
      _overriddenMemberFromEngine(member);

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["element"] = element.toJson();
    result["className"] = className;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is OverriddenMember) {
      return element == other.element &&
          className == other.className;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, element.hashCode);
    hash = _JenkinsSmiHash.combine(hash, className.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * Position
 *
 * {
 *   "file": FilePath
 *   "offset": int
 * }
 */
class Position implements HasToJson {
  /**
   * The file containing the position.
   */
  String file;

  /**
   * The offset of the position.
   */
  int offset;

  Position(this.file, this.offset);

  factory Position.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      return new Position(file, offset);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Position");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 *   RENAME
 * }
 */
class RefactoringKind {
  static const CONVERT_GETTER_TO_METHOD = const RefactoringKind._("CONVERT_GETTER_TO_METHOD");

  static const CONVERT_METHOD_TO_GETTER = const RefactoringKind._("CONVERT_METHOD_TO_GETTER");

  static const EXTRACT_LOCAL_VARIABLE = const RefactoringKind._("EXTRACT_LOCAL_VARIABLE");

  static const EXTRACT_METHOD = const RefactoringKind._("EXTRACT_METHOD");

  static const INLINE_LOCAL_VARIABLE = const RefactoringKind._("INLINE_LOCAL_VARIABLE");

  static const INLINE_METHOD = const RefactoringKind._("INLINE_METHOD");

  static const RENAME = const RefactoringKind._("RENAME");

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
      case "RENAME":
        return RENAME;
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
    throw jsonDecoder.mismatch(jsonPath, "RefactoringKind");
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
 */
class RefactoringMethodParameter implements HasToJson {
  /**
   * The unique identifier of the parameter. Clients may omit this field for
   * the parameters they want to add.
   */
  String id;

  /**
   * The kind of the parameter.
   */
  RefactoringMethodParameterKind kind;

  /**
   * The type that should be given to the parameter, or the return type of the
   * parameter's function type.
   */
  String type;

  /**
   * The name that should be given to the parameter.
   */
  String name;

  /**
   * The parameter list of the parameter's function type. If the parameter is
   * not of a function type, this field will not be defined. If the function
   * type has zero parameters, this field will have a value of "()".
   */
  String parameters;

  RefactoringMethodParameter(this.kind, this.type, this.name, {this.id, this.parameters});

  factory RefactoringMethodParameter.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      }
      RefactoringMethodParameterKind kind;
      if (json.containsKey("kind")) {
        kind = new RefactoringMethodParameterKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      String type;
      if (json.containsKey("type")) {
        type = jsonDecoder._decodeString(jsonPath + ".type", json["type"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "type");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      String parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder._decodeString(jsonPath + ".parameters", json["parameters"]);
      }
      return new RefactoringMethodParameter(kind, type, name, id: id, parameters: parameters);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RefactoringMethodParameter");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, type.hashCode);
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameters.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * RefactoringFeedback
 *
 * {
 * }
 */
class RefactoringFeedback implements HasToJson {
  RefactoringFeedback();

  factory RefactoringFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json, Map responseJson) {
    return _refactoringFeedbackFromJson(jsonDecoder, jsonPath, json, responseJson);
  }

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
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * RefactoringOptions
 *
 * {
 * }
 */
class RefactoringOptions implements HasToJson {
  RefactoringOptions();

  factory RefactoringOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json, RefactoringKind kind) {
    return _refactoringOptionsFromJson(jsonDecoder, jsonPath, json, kind);
  }

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
    return _JenkinsSmiHash.finish(hash);
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
 */
class RefactoringMethodParameterKind {
  static const REQUIRED = const RefactoringMethodParameterKind._("REQUIRED");

  static const POSITIONAL = const RefactoringMethodParameterKind._("POSITIONAL");

  static const NAMED = const RefactoringMethodParameterKind._("NAMED");

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
    throw jsonDecoder.mismatch(jsonPath, "RefactoringMethodParameterKind");
  }

  @override
  String toString() => "RefactoringMethodParameterKind.$name";

  String toJson() => name;
}

/**
 * RefactoringProblem
 *
 * {
 *   "severity": RefactoringProblemSeverity
 *   "message": String
 *   "location": optional Location
 * }
 */
class RefactoringProblem implements HasToJson {
  /**
   * The severity of the problem being represented.
   */
  RefactoringProblemSeverity severity;

  /**
   * A human-readable description of the problem being represented.
   */
  String message;

  /**
   * The location of the problem being represented. This field is omitted
   * unless there is a specific location associated with the problem (such as a
   * location where an element being renamed will be shadowed).
   */
  Location location;

  RefactoringProblem(this.severity, this.message, {this.location});

  factory RefactoringProblem.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RefactoringProblemSeverity severity;
      if (json.containsKey("severity")) {
        severity = new RefactoringProblemSeverity.fromJson(jsonDecoder, jsonPath + ".severity", json["severity"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "severity");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder._decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "message");
      }
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      }
      return new RefactoringProblem(severity, message, location: location);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RefactoringProblem");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = _JenkinsSmiHash.combine(hash, message.hashCode);
    hash = _JenkinsSmiHash.combine(hash, location.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class RefactoringProblemSeverity {
  static const INFO = const RefactoringProblemSeverity._("INFO");

  static const WARNING = const RefactoringProblemSeverity._("WARNING");

  static const ERROR = const RefactoringProblemSeverity._("ERROR");

  static const FATAL = const RefactoringProblemSeverity._("FATAL");

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
    throw jsonDecoder.mismatch(jsonPath, "RefactoringProblemSeverity");
  }

  /**
   * Returns the [RefactoringProblemSeverity] with the maximal severity.
   */
  static RefactoringProblemSeverity max(RefactoringProblemSeverity a, RefactoringProblemSeverity b) =>
      _maxRefactoringProblemSeverity(a, b);

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
 */
class RemoveContentOverlay implements HasToJson {
  RemoveContentOverlay();

  factory RemoveContentOverlay.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      if (json["type"] != "remove") {
        throw jsonDecoder.mismatch(jsonPath, "equal " + "remove");
      }
      return new RemoveContentOverlay();
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RemoveContentOverlay");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, 114870849);
    return _JenkinsSmiHash.finish(hash);
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
 */
class RequestError implements HasToJson {
  /**
   * A code that uniquely identifies the error that occurred.
   */
  RequestErrorCode code;

  /**
   * A short description of the error.
   */
  String message;

  /**
   * The stack trace associated with processing the request, used for debugging
   * the server.
   */
  String stackTrace;

  RequestError(this.code, this.message, {this.stackTrace});

  factory RequestError.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      RequestErrorCode code;
      if (json.containsKey("code")) {
        code = new RequestErrorCode.fromJson(jsonDecoder, jsonPath + ".code", json["code"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "code");
      }
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder._decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "message");
      }
      String stackTrace;
      if (json.containsKey("stackTrace")) {
        stackTrace = jsonDecoder._decodeString(jsonPath + ".stackTrace", json["stackTrace"]);
      }
      return new RequestError(code, message, stackTrace: stackTrace);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RequestError");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, code.hashCode);
    hash = _JenkinsSmiHash.combine(hash, message.hashCode);
    hash = _JenkinsSmiHash.combine(hash, stackTrace.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * RequestErrorCode
 *
 * enum {
 *   GET_ERRORS_INVALID_FILE
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   INVALID_REQUEST
 *   SERVER_ALREADY_STARTED
 *   SERVER_ERROR
 *   UNANALYZED_PRIORITY_FILES
 *   UNKNOWN_REQUEST
 *   UNSUPPORTED_FEATURE
 * }
 */
class RequestErrorCode {
  /**
   * An "analysis.getErrors" request specified a FilePath which does not match
   * a file currently subject to analysis.
   */
  static const GET_ERRORS_INVALID_FILE = const RequestErrorCode._("GET_ERRORS_INVALID_FILE");

  /**
   * An analysis.updateContent request contained a ChangeContentOverlay object
   * which can't be applied, due to an edit having an offset or length that is
   * out of range.
   */
  static const INVALID_OVERLAY_CHANGE = const RequestErrorCode._("INVALID_OVERLAY_CHANGE");

  /**
   * One of the method parameters was invalid.
   */
  static const INVALID_PARAMETER = const RequestErrorCode._("INVALID_PARAMETER");

  /**
   * A malformed request was received.
   */
  static const INVALID_REQUEST = const RequestErrorCode._("INVALID_REQUEST");

  /**
   * The analysis server has already been started (and hence won't accept new
   * connections).
   *
   * This error is included for future expansion; at present the analysis
   * server can only speak to one client at a time so this error will never
   * occur.
   */
  static const SERVER_ALREADY_STARTED = const RequestErrorCode._("SERVER_ALREADY_STARTED");

  /**
   * An internal error occurred in the analysis server. Also see the
   * server.error notification.
   */
  static const SERVER_ERROR = const RequestErrorCode._("SERVER_ERROR");

  /**
   * An "analysis.setPriorityFiles" request includes one or more files that are
   * not being analyzed.
   *
   * This is a legacy error; it will be removed before the API reaches version
   * 1.0.
   */
  static const UNANALYZED_PRIORITY_FILES = const RequestErrorCode._("UNANALYZED_PRIORITY_FILES");

  /**
   * A request was received which the analysis server does not recognize, or
   * cannot handle in its current configuation.
   */
  static const UNKNOWN_REQUEST = const RequestErrorCode._("UNKNOWN_REQUEST");

  /**
   * The analysis server was requested to perform an action which is not
   * supported.
   *
   * This is a legacy error; it will be removed before the API reaches version
   * 1.0.
   */
  static const UNSUPPORTED_FEATURE = const RequestErrorCode._("UNSUPPORTED_FEATURE");

  final String name;

  const RequestErrorCode._(this.name);

  factory RequestErrorCode(String name) {
    switch (name) {
      case "GET_ERRORS_INVALID_FILE":
        return GET_ERRORS_INVALID_FILE;
      case "INVALID_OVERLAY_CHANGE":
        return INVALID_OVERLAY_CHANGE;
      case "INVALID_PARAMETER":
        return INVALID_PARAMETER;
      case "INVALID_REQUEST":
        return INVALID_REQUEST;
      case "SERVER_ALREADY_STARTED":
        return SERVER_ALREADY_STARTED;
      case "SERVER_ERROR":
        return SERVER_ERROR;
      case "UNANALYZED_PRIORITY_FILES":
        return UNANALYZED_PRIORITY_FILES;
      case "UNKNOWN_REQUEST":
        return UNKNOWN_REQUEST;
      case "UNSUPPORTED_FEATURE":
        return UNSUPPORTED_FEATURE;
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
    throw jsonDecoder.mismatch(jsonPath, "RequestErrorCode");
  }

  @override
  String toString() => "RequestErrorCode.$name";

  String toJson() => name;
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
 */
class SearchResult implements HasToJson {
  /**
   * The location of the code that matched the search criteria.
   */
  Location location;

  /**
   * The kind of element that was found or the kind of reference that was
   * found.
   */
  SearchResultKind kind;

  /**
   * True if the result is a potential match but cannot be confirmed to be a
   * match. For example, if all references to a method m defined in some class
   * were requested, and a reference to a method m from an unknown class were
   * found, it would be marked as being a potential match.
   */
  bool isPotential;

  /**
   * The elements that contain the result, starting with the most immediately
   * enclosing ancestor and ending with the library.
   */
  List<Element> path;

  SearchResult(this.location, this.kind, this.isPotential, this.path);

  factory SearchResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Location location;
      if (json.containsKey("location")) {
        location = new Location.fromJson(jsonDecoder, jsonPath + ".location", json["location"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "location");
      }
      SearchResultKind kind;
      if (json.containsKey("kind")) {
        kind = new SearchResultKind.fromJson(jsonDecoder, jsonPath + ".kind", json["kind"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      bool isPotential;
      if (json.containsKey("isPotential")) {
        isPotential = jsonDecoder._decodeBool(jsonPath + ".isPotential", json["isPotential"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isPotential");
      }
      List<Element> path;
      if (json.containsKey("path")) {
        path = jsonDecoder._decodeList(jsonPath + ".path", json["path"], (String jsonPath, Object json) => new Element.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "path");
      }
      return new SearchResult(location, kind, isPotential, path);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SearchResult");
    }
  }

  /**
   * Construct based on a value from the search engine.
   */
  factory SearchResult.fromMatch(engine.SearchMatch match) =>
      searchResultFromMatch(match);

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
  bool operator==(other) {
    if (other is SearchResult) {
      return location == other.location &&
          kind == other.kind &&
          isPotential == other.isPotential &&
          _listEqual(path, other.path, (Element a, Element b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, location.hashCode);
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, isPotential.hashCode);
    hash = _JenkinsSmiHash.combine(hash, path.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class SearchResultKind {
  /**
   * The declaration of an element.
   */
  static const DECLARATION = const SearchResultKind._("DECLARATION");

  /**
   * The invocation of a function or method.
   */
  static const INVOCATION = const SearchResultKind._("INVOCATION");

  /**
   * A reference to a field, parameter or variable where it is being read.
   */
  static const READ = const SearchResultKind._("READ");

  /**
   * A reference to a field, parameter or variable where it is being read and
   * written.
   */
  static const READ_WRITE = const SearchResultKind._("READ_WRITE");

  /**
   * A reference to an element.
   */
  static const REFERENCE = const SearchResultKind._("REFERENCE");

  /**
   * Some other kind of search result.
   */
  static const UNKNOWN = const SearchResultKind._("UNKNOWN");

  /**
   * A reference to a field, parameter or variable where it is being written.
   */
  static const WRITE = const SearchResultKind._("WRITE");

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

  factory SearchResultKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new SearchResultKind(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "SearchResultKind");
  }

  /**
   * Construct based on a value from the search engine.
   */
  factory SearchResultKind.fromEngine(engine.MatchKind kind) =>
      _searchResultKindFromEngine(kind);

  @override
  String toString() => "SearchResultKind.$name";

  String toJson() => name;
}

/**
 * ServerService
 *
 * enum {
 *   STATUS
 * }
 */
class ServerService {
  static const STATUS = const ServerService._("STATUS");

  final String name;

  const ServerService._(this.name);

  factory ServerService(String name) {
    switch (name) {
      case "STATUS":
        return STATUS;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory ServerService.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ServerService(json);
      } catch(_) {
        // Fall through
      }
    }
    throw jsonDecoder.mismatch(jsonPath, "ServerService");
  }

  @override
  String toString() => "ServerService.$name";

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
 */
class SourceChange implements HasToJson {
  /**
   * A human-readable description of the change to be applied.
   */
  String message;

  /**
   * A list of the edits used to effect the change, grouped by file.
   */
  List<SourceFileEdit> edits;

  /**
   * A list of the linked editing groups used to customize the changes that
   * were made.
   */
  List<LinkedEditGroup> linkedEditGroups;

  /**
   * The position that should be selected after the edits have been applied.
   */
  Position selection;

  SourceChange(this.message, {this.edits, this.linkedEditGroups, this.selection}) {
    if (edits == null) {
      edits = <SourceFileEdit>[];
    }
    if (linkedEditGroups == null) {
      linkedEditGroups = <LinkedEditGroup>[];
    }
  }

  factory SourceChange.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String message;
      if (json.containsKey("message")) {
        message = jsonDecoder._decodeString(jsonPath + ".message", json["message"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "message");
      }
      List<SourceFileEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder._decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceFileEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edits");
      }
      List<LinkedEditGroup> linkedEditGroups;
      if (json.containsKey("linkedEditGroups")) {
        linkedEditGroups = jsonDecoder._decodeList(jsonPath + ".linkedEditGroups", json["linkedEditGroups"], (String jsonPath, Object json) => new LinkedEditGroup.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "linkedEditGroups");
      }
      Position selection;
      if (json.containsKey("selection")) {
        selection = new Position.fromJson(jsonDecoder, jsonPath + ".selection", json["selection"]);
      }
      return new SourceChange(message, edits: edits, linkedEditGroups: linkedEditGroups, selection: selection);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SourceChange");
    }
  }

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
      _addEditToSourceChange(this, file, fileStamp, edit);

  /**
   * Adds [edit] to the [FileEdit] for the given [source].
   */
  void addSourceEdit(engine.AnalysisContext context,
      engine.Source source, SourceEdit edit) =>
      _addSourceEditToSourceChange(this, context, source, edit);

  /**
   * Adds [edit] to the [FileEdit] for the given [element].
   */
  void addElementEdit(engine.Element element, SourceEdit edit) =>
      _addElementEditToSourceChange(this, element, edit);

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
      _getChangeFileEdit(this, file);

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SourceChange) {
      return message == other.message &&
          _listEqual(edits, other.edits, (SourceFileEdit a, SourceFileEdit b) => a == b) &&
          _listEqual(linkedEditGroups, other.linkedEditGroups, (LinkedEditGroup a, LinkedEditGroup b) => a == b) &&
          selection == other.selection;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, message.hashCode);
    hash = _JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = _JenkinsSmiHash.combine(hash, linkedEditGroups.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selection.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class SourceEdit implements HasToJson {
  /**
   * Get the result of applying a set of [edits] to the given [code]. Edits are
   * applied in the order they appear in [edits].
   */
  static String applySequence(String code, Iterable<SourceEdit> edits) =>
      _applySequence(code, edits);

  /**
   * The offset of the region to be modified.
   */
  int offset;

  /**
   * The length of the region to be modified.
   */
  int length;

  /**
   * The code that is to replace the specified region in the original code.
   */
  String replacement;

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
  String id;

  SourceEdit(this.offset, this.length, this.replacement, {this.id});

  factory SourceEdit.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      String replacement;
      if (json.containsKey("replacement")) {
        replacement = jsonDecoder._decodeString(jsonPath + ".replacement", json["replacement"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "replacement");
      }
      String id;
      if (json.containsKey("id")) {
        id = jsonDecoder._decodeString(jsonPath + ".id", json["id"]);
      }
      return new SourceEdit(offset, length, replacement, id: id);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SourceEdit");
    }
  }

  /**
   * Construct based on a SourceRange.
   */
  SourceEdit.range(engine.SourceRange range, String replacement, {String id})
      : this(range.offset, range.length, replacement, id: id);

  /**
   * The end of the region to be modified.
   */
  int get end => offset + length;

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
  String apply(String code) => _applyEdit(code, this);

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
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, replacement.hashCode);
    hash = _JenkinsSmiHash.combine(hash, id.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class SourceFileEdit implements HasToJson {
  /**
   * The file containing the code to be modified.
   */
  String file;

  /**
   * The modification stamp of the file at the moment when the change was
   * created, in milliseconds since the "Unix epoch". Will be -1 if the file
   * did not exist and should be created. The client may use this field to make
   * sure that the file was not changed since then, so it is safe to apply the
   * change.
   */
  int fileStamp;

  /**
   * A list of the edits used to effect the change.
   */
  List<SourceEdit> edits;

  SourceFileEdit(this.file, this.fileStamp, {this.edits}) {
    if (edits == null) {
      edits = <SourceEdit>[];
    }
  }

  factory SourceFileEdit.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String file;
      if (json.containsKey("file")) {
        file = jsonDecoder._decodeString(jsonPath + ".file", json["file"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "file");
      }
      int fileStamp;
      if (json.containsKey("fileStamp")) {
        fileStamp = jsonDecoder._decodeInt(jsonPath + ".fileStamp", json["fileStamp"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "fileStamp");
      }
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder._decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edits");
      }
      return new SourceFileEdit(file, fileStamp, edits: edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "SourceFileEdit");
    }
  }

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
  void add(SourceEdit edit) => _addEditForSource(this, edit);

  /**
   * Adds the given [Edit]s.
   */
  void addAll(Iterable<SourceEdit> edits) =>
      _addAllEditsForSource(this, edits);

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is SourceFileEdit) {
      return file == other.file &&
          fileStamp == other.fileStamp &&
          _listEqual(edits, other.edits, (SourceEdit a, SourceEdit b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, fileStamp.hashCode);
    hash = _JenkinsSmiHash.combine(hash, edits.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class TypeHierarchyItem implements HasToJson {
  /**
   * The class element represented by this item.
   */
  Element classElement;

  /**
   * The name to be displayed for the class. This field will be omitted if the
   * display name is the same as the name of the element. The display name is
   * different if there is additional type information to be displayed, such as
   * type arguments.
   */
  String displayName;

  /**
   * The member in the class corresponding to the member on which the hierarchy
   * was requested. This field will be omitted if the hierarchy was not
   * requested for a member or if the class does not have a corresponding
   * member.
   */
  Element memberElement;

  /**
   * The index of the item representing the superclass of this class. This
   * field will be omitted if this item represents the class Object.
   */
  int superclass;

  /**
   * The indexes of the items representing the interfaces implemented by this
   * class. The list will be empty if there are no implemented interfaces.
   */
  List<int> interfaces;

  /**
   * The indexes of the items representing the mixins referenced by this class.
   * The list will be empty if there are no classes mixed in to this class.
   */
  List<int> mixins;

  /**
   * The indexes of the items representing the subtypes of this class. The list
   * will be empty if there are no subtypes or if this item represents a
   * supertype of the pivot type.
   */
  List<int> subclasses;

  TypeHierarchyItem(this.classElement, {this.displayName, this.memberElement, this.superclass, this.interfaces, this.mixins, this.subclasses}) {
    if (interfaces == null) {
      interfaces = <int>[];
    }
    if (mixins == null) {
      mixins = <int>[];
    }
    if (subclasses == null) {
      subclasses = <int>[];
    }
  }

  factory TypeHierarchyItem.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      Element classElement;
      if (json.containsKey("classElement")) {
        classElement = new Element.fromJson(jsonDecoder, jsonPath + ".classElement", json["classElement"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "classElement");
      }
      String displayName;
      if (json.containsKey("displayName")) {
        displayName = jsonDecoder._decodeString(jsonPath + ".displayName", json["displayName"]);
      }
      Element memberElement;
      if (json.containsKey("memberElement")) {
        memberElement = new Element.fromJson(jsonDecoder, jsonPath + ".memberElement", json["memberElement"]);
      }
      int superclass;
      if (json.containsKey("superclass")) {
        superclass = jsonDecoder._decodeInt(jsonPath + ".superclass", json["superclass"]);
      }
      List<int> interfaces;
      if (json.containsKey("interfaces")) {
        interfaces = jsonDecoder._decodeList(jsonPath + ".interfaces", json["interfaces"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "interfaces");
      }
      List<int> mixins;
      if (json.containsKey("mixins")) {
        mixins = jsonDecoder._decodeList(jsonPath + ".mixins", json["mixins"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "mixins");
      }
      List<int> subclasses;
      if (json.containsKey("subclasses")) {
        subclasses = jsonDecoder._decodeList(jsonPath + ".subclasses", json["subclasses"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "subclasses");
      }
      return new TypeHierarchyItem(classElement, displayName: displayName, memberElement: memberElement, superclass: superclass, interfaces: interfaces, mixins: mixins, subclasses: subclasses);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "TypeHierarchyItem");
    }
  }

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
  bool operator==(other) {
    if (other is TypeHierarchyItem) {
      return classElement == other.classElement &&
          displayName == other.displayName &&
          memberElement == other.memberElement &&
          superclass == other.superclass &&
          _listEqual(interfaces, other.interfaces, (int a, int b) => a == b) &&
          _listEqual(mixins, other.mixins, (int a, int b) => a == b) &&
          _listEqual(subclasses, other.subclasses, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, classElement.hashCode);
    hash = _JenkinsSmiHash.combine(hash, displayName.hashCode);
    hash = _JenkinsSmiHash.combine(hash, memberElement.hashCode);
    hash = _JenkinsSmiHash.combine(hash, superclass.hashCode);
    hash = _JenkinsSmiHash.combine(hash, interfaces.hashCode);
    hash = _JenkinsSmiHash.combine(hash, mixins.hashCode);
    hash = _JenkinsSmiHash.combine(hash, subclasses.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * convertGetterToMethod feedback
 */
class ConvertGetterToMethodFeedback {
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
 */
class ConvertGetterToMethodOptions {
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
 */
class ConvertMethodToGetterFeedback {
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
 */
class ConvertMethodToGetterOptions {
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
 * extractLocalVariable feedback
 *
 * {
 *   "names": List<String>
 *   "offsets": List<int>
 *   "lengths": List<int>
 * }
 */
class ExtractLocalVariableFeedback extends RefactoringFeedback implements HasToJson {
  /**
   * The proposed names for the local variable.
   */
  List<String> names;

  /**
   * The offsets of the expressions that would be replaced by a reference to
   * the variable.
   */
  List<int> offsets;

  /**
   * The lengths of the expressions that would be replaced by a reference to
   * the variable. The lengths correspond to the offsets. In other words, for a
   * given expression, if the offset of that expression is offsets[i], then the
   * length of that expression is lengths[i].
   */
  List<int> lengths;

  ExtractLocalVariableFeedback(this.names, this.offsets, this.lengths);

  factory ExtractLocalVariableFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> names;
      if (json.containsKey("names")) {
        names = jsonDecoder._decodeList(jsonPath + ".names", json["names"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "names");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder._decodeList(jsonPath + ".offsets", json["offsets"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offsets");
      }
      List<int> lengths;
      if (json.containsKey("lengths")) {
        lengths = jsonDecoder._decodeList(jsonPath + ".lengths", json["lengths"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "lengths");
      }
      return new ExtractLocalVariableFeedback(names, offsets, lengths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractLocalVariable feedback");
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
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
      return _listEqual(names, other.names, (String a, String b) => a == b) &&
          _listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          _listEqual(lengths, other.lengths, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, names.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = _JenkinsSmiHash.combine(hash, lengths.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * extractLocalVariable options
 *
 * {
 *   "name": String
 *   "extractAll": bool
 * }
 */
class ExtractLocalVariableOptions extends RefactoringOptions implements HasToJson {
  /**
   * The name that the local variable should be given.
   */
  String name;

  /**
   * True if all occurrences of the expression within the scope in which the
   * variable will be defined should be replaced by a reference to the local
   * variable. The expression used to initiate the refactoring will always be
   * replaced.
   */
  bool extractAll;

  ExtractLocalVariableOptions(this.name, this.extractAll);

  factory ExtractLocalVariableOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      bool extractAll;
      if (json.containsKey("extractAll")) {
        extractAll = jsonDecoder._decodeBool(jsonPath + ".extractAll", json["extractAll"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "extractAll");
      }
      return new ExtractLocalVariableOptions(name, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractLocalVariable options");
    }
  }

  factory ExtractLocalVariableOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
    return new ExtractLocalVariableOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

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
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    hash = _JenkinsSmiHash.combine(hash, extractAll.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class ExtractMethodFeedback extends RefactoringFeedback implements HasToJson {
  /**
   * The offset to the beginning of the expression or statements that will be
   * extracted.
   */
  int offset;

  /**
   * The length of the expression or statements that will be extracted.
   */
  int length;

  /**
   * The proposed return type for the method.
   */
  String returnType;

  /**
   * The proposed names for the method.
   */
  List<String> names;

  /**
   * True if a getter could be created rather than a method.
   */
  bool canCreateGetter;

  /**
   * The proposed parameters for the method.
   */
  List<RefactoringMethodParameter> parameters;

  /**
   * The offsets of the expressions or statements that would be replaced by an
   * invocation of the method.
   */
  List<int> offsets;

  /**
   * The lengths of the expressions or statements that would be replaced by an
   * invocation of the method. The lengths correspond to the offsets. In other
   * words, for a given expression (or block of statements), if the offset of
   * that expression is offsets[i], then the length of that expression is
   * lengths[i].
   */
  List<int> lengths;

  ExtractMethodFeedback(this.offset, this.length, this.returnType, this.names, this.canCreateGetter, this.parameters, this.offsets, this.lengths);

  factory ExtractMethodFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder._decodeString(jsonPath + ".returnType", json["returnType"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "returnType");
      }
      List<String> names;
      if (json.containsKey("names")) {
        names = jsonDecoder._decodeList(jsonPath + ".names", json["names"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "names");
      }
      bool canCreateGetter;
      if (json.containsKey("canCreateGetter")) {
        canCreateGetter = jsonDecoder._decodeBool(jsonPath + ".canCreateGetter", json["canCreateGetter"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "canCreateGetter");
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder._decodeList(jsonPath + ".parameters", json["parameters"], (String jsonPath, Object json) => new RefactoringMethodParameter.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "parameters");
      }
      List<int> offsets;
      if (json.containsKey("offsets")) {
        offsets = jsonDecoder._decodeList(jsonPath + ".offsets", json["offsets"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offsets");
      }
      List<int> lengths;
      if (json.containsKey("lengths")) {
        lengths = jsonDecoder._decodeList(jsonPath + ".lengths", json["lengths"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "lengths");
      }
      return new ExtractMethodFeedback(offset, length, returnType, names, canCreateGetter, parameters, offsets, lengths);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractMethod feedback");
    }
  }

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
          _listEqual(names, other.names, (String a, String b) => a == b) &&
          canCreateGetter == other.canCreateGetter &&
          _listEqual(parameters, other.parameters, (RefactoringMethodParameter a, RefactoringMethodParameter b) => a == b) &&
          _listEqual(offsets, other.offsets, (int a, int b) => a == b) &&
          _listEqual(lengths, other.lengths, (int a, int b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, names.hashCode);
    hash = _JenkinsSmiHash.combine(hash, canCreateGetter.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offsets.hashCode);
    hash = _JenkinsSmiHash.combine(hash, lengths.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class ExtractMethodOptions extends RefactoringOptions implements HasToJson {
  /**
   * The return type that should be defined for the method.
   */
  String returnType;

  /**
   * True if a getter should be created rather than a method. It is an error if
   * this field is true and the list of parameters is non-empty.
   */
  bool createGetter;

  /**
   * The name that the method should be given.
   */
  String name;

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
  List<RefactoringMethodParameter> parameters;

  /**
   * True if all occurrences of the expression or statements should be replaced
   * by an invocation of the method. The expression or statements used to
   * initiate the refactoring will always be replaced.
   */
  bool extractAll;

  ExtractMethodOptions(this.returnType, this.createGetter, this.name, this.parameters, this.extractAll);

  factory ExtractMethodOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String returnType;
      if (json.containsKey("returnType")) {
        returnType = jsonDecoder._decodeString(jsonPath + ".returnType", json["returnType"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "returnType");
      }
      bool createGetter;
      if (json.containsKey("createGetter")) {
        createGetter = jsonDecoder._decodeBool(jsonPath + ".createGetter", json["createGetter"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "createGetter");
      }
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      List<RefactoringMethodParameter> parameters;
      if (json.containsKey("parameters")) {
        parameters = jsonDecoder._decodeList(jsonPath + ".parameters", json["parameters"], (String jsonPath, Object json) => new RefactoringMethodParameter.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "parameters");
      }
      bool extractAll;
      if (json.containsKey("extractAll")) {
        extractAll = jsonDecoder._decodeBool(jsonPath + ".extractAll", json["extractAll"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "extractAll");
      }
      return new ExtractMethodOptions(returnType, createGetter, name, parameters, extractAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "extractMethod options");
    }
  }

  factory ExtractMethodOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
    return new ExtractMethodOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

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
          _listEqual(parameters, other.parameters, (RefactoringMethodParameter a, RefactoringMethodParameter b) => a == b) &&
          extractAll == other.extractAll;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, createGetter.hashCode);
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = _JenkinsSmiHash.combine(hash, extractAll.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * inlineLocalVariable feedback
 *
 * {
 *   "name": String
 *   "occurrences": int
 * }
 */
class InlineLocalVariableFeedback extends RefactoringFeedback implements HasToJson {
  /**
   * The name of the variable being inlined.
   */
  String name;

  /**
   * The number of times the variable occurs.
   */
  int occurrences;

  InlineLocalVariableFeedback(this.name, this.occurrences);

  factory InlineLocalVariableFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String name;
      if (json.containsKey("name")) {
        name = jsonDecoder._decodeString(jsonPath + ".name", json["name"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "name");
      }
      int occurrences;
      if (json.containsKey("occurrences")) {
        occurrences = jsonDecoder._decodeInt(jsonPath + ".occurrences", json["occurrences"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "occurrences");
      }
      return new InlineLocalVariableFeedback(name, occurrences);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineLocalVariable feedback");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    hash = _JenkinsSmiHash.combine(hash, occurrences.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * inlineLocalVariable options
 */
class InlineLocalVariableOptions {
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
 */
class InlineMethodFeedback extends RefactoringFeedback implements HasToJson {
  /**
   * The name of the class enclosing the method being inlined. If not a class
   * member is being inlined, this field will be absent.
   */
  String className;

  /**
   * The name of the method (or function) being inlined.
   */
  String methodName;

  /**
   * True if the declaration of the method is selected. So all references
   * should be inlined.
   */
  bool isDeclaration;

  InlineMethodFeedback(this.methodName, this.isDeclaration, {this.className});

  factory InlineMethodFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String className;
      if (json.containsKey("className")) {
        className = jsonDecoder._decodeString(jsonPath + ".className", json["className"]);
      }
      String methodName;
      if (json.containsKey("methodName")) {
        methodName = jsonDecoder._decodeString(jsonPath + ".methodName", json["methodName"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "methodName");
      }
      bool isDeclaration;
      if (json.containsKey("isDeclaration")) {
        isDeclaration = jsonDecoder._decodeBool(jsonPath + ".isDeclaration", json["isDeclaration"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isDeclaration");
      }
      return new InlineMethodFeedback(methodName, isDeclaration, className: className);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod feedback");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, className.hashCode);
    hash = _JenkinsSmiHash.combine(hash, methodName.hashCode);
    hash = _JenkinsSmiHash.combine(hash, isDeclaration.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * inlineMethod options
 *
 * {
 *   "deleteSource": bool
 *   "inlineAll": bool
 * }
 */
class InlineMethodOptions extends RefactoringOptions implements HasToJson {
  /**
   * True if the method being inlined should be removed. It is an error if this
   * field is true and inlineAll is false.
   */
  bool deleteSource;

  /**
   * True if all invocations of the method should be inlined, or false if only
   * the invocation site used to create this refactoring should be inlined.
   */
  bool inlineAll;

  InlineMethodOptions(this.deleteSource, this.inlineAll);

  factory InlineMethodOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool deleteSource;
      if (json.containsKey("deleteSource")) {
        deleteSource = jsonDecoder._decodeBool(jsonPath + ".deleteSource", json["deleteSource"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "deleteSource");
      }
      bool inlineAll;
      if (json.containsKey("inlineAll")) {
        inlineAll = jsonDecoder._decodeBool(jsonPath + ".inlineAll", json["inlineAll"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "inlineAll");
      }
      return new InlineMethodOptions(deleteSource, inlineAll);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod options");
    }
  }

  factory InlineMethodOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
    return new InlineMethodOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

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
    hash = _JenkinsSmiHash.combine(hash, deleteSource.hashCode);
    hash = _JenkinsSmiHash.combine(hash, inlineAll.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
/**
 * moveFile feedback
 */
class MoveFileFeedback {
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
 */
class MoveFileOptions extends RefactoringOptions implements HasToJson {
  /**
   * The new file path to which the given file is being moved.
   */
  String newFile;

  MoveFileOptions(this.newFile);

  factory MoveFileOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String newFile;
      if (json.containsKey("newFile")) {
        newFile = jsonDecoder._decodeString(jsonPath + ".newFile", json["newFile"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "newFile");
      }
      return new MoveFileOptions(newFile);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "moveFile options");
    }
  }

  factory MoveFileOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
    return new MoveFileOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

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
    hash = _JenkinsSmiHash.combine(hash, newFile.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class RenameFeedback extends RefactoringFeedback implements HasToJson {
  /**
   * The offset to the beginning of the name selected to be renamed.
   */
  int offset;

  /**
   * The length of the name selected to be renamed.
   */
  int length;

  /**
   * The human-readable description of the kind of element being renamed (such
   * as “class” or “function type alias”).
   */
  String elementKindName;

  /**
   * The old name of the element before the refactoring.
   */
  String oldName;

  RenameFeedback(this.offset, this.length, this.elementKindName, this.oldName);

  factory RenameFeedback.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      int offset;
      if (json.containsKey("offset")) {
        offset = jsonDecoder._decodeInt(jsonPath + ".offset", json["offset"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "offset");
      }
      int length;
      if (json.containsKey("length")) {
        length = jsonDecoder._decodeInt(jsonPath + ".length", json["length"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "length");
      }
      String elementKindName;
      if (json.containsKey("elementKindName")) {
        elementKindName = jsonDecoder._decodeString(jsonPath + ".elementKindName", json["elementKindName"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "elementKindName");
      }
      String oldName;
      if (json.containsKey("oldName")) {
        oldName = jsonDecoder._decodeString(jsonPath + ".oldName", json["oldName"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "oldName");
      }
      return new RenameFeedback(offset, length, elementKindName, oldName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "rename feedback");
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, elementKindName.hashCode);
    hash = _JenkinsSmiHash.combine(hash, oldName.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * rename options
 *
 * {
 *   "newName": String
 * }
 */
class RenameOptions extends RefactoringOptions implements HasToJson {
  /**
   * The name that the element should have after the refactoring.
   */
  String newName;

  RenameOptions(this.newName);

  factory RenameOptions.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      String newName;
      if (json.containsKey("newName")) {
        newName = jsonDecoder._decodeString(jsonPath + ".newName", json["newName"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "newName");
      }
      return new RenameOptions(newName);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "rename options");
    }
  }

  factory RenameOptions.fromRefactoringParams(EditGetRefactoringParams refactoringParams, Request request) {
    return new RenameOptions.fromJson(
        new RequestDecoder(request), "options", refactoringParams.options);
  }

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
    hash = _JenkinsSmiHash.combine(hash, newName.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}
