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
      throw jsonDecoder.mismatch(jsonPath, "server.getVersion result", json);
    }
  }

  factory ServerGetVersionResult.fromResponse(Response response) {
    return new ServerGetVersionResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "server.setSubscriptions params", json);
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
 *
 * {
 *   "version": String
 * }
 */
class ServerConnectedParams implements HasToJson {
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

  ServerConnectedParams(String version) {
    this.version = version;
  }

  factory ServerConnectedParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      return new ServerConnectedParams(version);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.connected params", json);
    }
  }

  factory ServerConnectedParams.fromNotification(Notification notification) {
    return new ServerConnectedParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["version"] = version;
    return result;
  }

  Notification toNotification() {
    return new Notification("server.connected", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is ServerConnectedParams) {
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
 * server.error params
 *
 * {
 *   "isFatal": bool
 *   "message": String
 *   "stackTrace": String
 * }
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
      throw jsonDecoder.mismatch(jsonPath, "server.error params", json);
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
 *   "pub": optional PubStatus
 * }
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

  factory ServerStatusParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      AnalysisStatus analysis;
      if (json.containsKey("analysis")) {
        analysis = new AnalysisStatus.fromJson(jsonDecoder, jsonPath + ".analysis", json["analysis"]);
      }
      PubStatus pub;
      if (json.containsKey("pub")) {
        pub = new PubStatus.fromJson(jsonDecoder, jsonPath + ".pub", json["pub"]);
      }
      return new ServerStatusParams(analysis: analysis, pub: pub);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "server.status params", json);
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
  bool operator==(other) {
    if (other is ServerStatusParams) {
      return analysis == other.analysis &&
          pub == other.pub;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, analysis.hashCode);
    hash = _JenkinsSmiHash.combine(hash, pub.hashCode);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.getErrors params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.getErrors result", json);
    }
  }

  factory AnalysisGetErrorsResult.fromResponse(Response response) {
    return new AnalysisGetErrorsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.getHover params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.getHover result", json);
    }
  }

  factory AnalysisGetHoverResult.fromResponse(Response response) {
    return new AnalysisGetHoverResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
 * analysis.getLibraryDependencies params
 */
class AnalysisGetLibraryDependenciesParams {
  Request toRequest(String id) {
    return new Request(id, "analysis.getLibraryDependencies", null);
  }

  @override
  bool operator==(other) {
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
 */
class AnalysisGetLibraryDependenciesResult implements HasToJson {
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

  AnalysisGetLibraryDependenciesResult(List<String> libraries, Map<String, Map<String, List<String>>> packageMap) {
    this.libraries = libraries;
    this.packageMap = packageMap;
  }

  factory AnalysisGetLibraryDependenciesResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> libraries;
      if (json.containsKey("libraries")) {
        libraries = jsonDecoder._decodeList(jsonPath + ".libraries", json["libraries"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "libraries");
      }
      Map<String, Map<String, List<String>>> packageMap;
      if (json.containsKey("packageMap")) {
        packageMap = jsonDecoder._decodeMap(jsonPath + ".packageMap", json["packageMap"], valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeMap(jsonPath, json, valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeList(jsonPath, json, jsonDecoder._decodeString)));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "packageMap");
      }
      return new AnalysisGetLibraryDependenciesResult(libraries, packageMap);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getLibraryDependencies result", json);
    }
  }

  factory AnalysisGetLibraryDependenciesResult.fromResponse(Response response) {
    return new AnalysisGetLibraryDependenciesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["libraries"] = libraries;
    result["packageMap"] = packageMap;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisGetLibraryDependenciesResult) {
      return _listEqual(libraries, other.libraries, (String a, String b) => a == b) &&
          _mapEqual(packageMap, other.packageMap, (Map<String, List<String>> a, Map<String, List<String>> b) => _mapEqual(a, b, (List<String> a, List<String> b) => _listEqual(a, b, (String a, String b) => a == b)));
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, libraries.hashCode);
    hash = _JenkinsSmiHash.combine(hash, packageMap.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class AnalysisGetNavigationParams implements HasToJson {
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

  factory AnalysisGetNavigationParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      return new AnalysisGetNavigationParams(file, offset, length);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getNavigation params", json);
    }
  }

  factory AnalysisGetNavigationParams.fromRequest(Request request) {
    return new AnalysisGetNavigationParams.fromJson(
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
    return new Request(id, "analysis.getNavigation", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class AnalysisGetNavigationResult implements HasToJson {
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

  AnalysisGetNavigationResult(List<String> files, List<NavigationTarget> targets, List<NavigationRegion> regions) {
    this.files = files;
    this.targets = targets;
    this.regions = regions;
  }

  factory AnalysisGetNavigationResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      List<NavigationTarget> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder._decodeList(jsonPath + ".targets", json["targets"], (String jsonPath, Object json) => new NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "targets");
      }
      List<NavigationRegion> regions;
      if (json.containsKey("regions")) {
        regions = jsonDecoder._decodeList(jsonPath + ".regions", json["regions"], (String jsonPath, Object json) => new NavigationRegion.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "regions");
      }
      return new AnalysisGetNavigationResult(files, targets, regions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.getNavigation result", json);
    }
  }

  factory AnalysisGetNavigationResult.fromResponse(Response response) {
    return new AnalysisGetNavigationResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["files"] = files;
    result["targets"] = targets.map((NavigationTarget value) => value.toJson()).toList();
    result["regions"] = regions.map((NavigationRegion value) => value.toJson()).toList();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisGetNavigationResult) {
      return _listEqual(files, other.files, (String a, String b) => a == b) &&
          _listEqual(targets, other.targets, (NavigationTarget a, NavigationTarget b) => a == b) &&
          _listEqual(regions, other.regions, (NavigationRegion a, NavigationRegion b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, files.hashCode);
    hash = _JenkinsSmiHash.combine(hash, targets.hashCode);
    hash = _JenkinsSmiHash.combine(hash, regions.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * analysis.reanalyze params
 *
 * {
 *   "roots": optional List<FilePath>
 * }
 */
class AnalysisReanalyzeParams implements HasToJson {
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

  factory AnalysisReanalyzeParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> roots;
      if (json.containsKey("roots")) {
        roots = jsonDecoder._decodeList(jsonPath + ".roots", json["roots"], jsonDecoder._decodeString);
      }
      return new AnalysisReanalyzeParams(roots: roots);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.reanalyze params", json);
    }
  }

  factory AnalysisReanalyzeParams.fromRequest(Request request) {
    return new AnalysisReanalyzeParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (roots != null) {
      result["roots"] = roots;
    }
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.reanalyze", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisReanalyzeParams) {
      return _listEqual(roots, other.roots, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, roots.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 *   "packageRoots": optional Map<FilePath, FilePath>
 * }
 */
class AnalysisSetAnalysisRootsParams implements HasToJson {
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
   * A mapping from source directories to target directories that should
   * override the normal package: URI resolution mechanism. The analyzer will
   * behave as though each source directory in the map contains a special
   * pubspec.yaml file which resolves any package: URI to the corresponding
   * path within the target directory. The effect is the same as specifying the
   * target directory as a "--package_root" parameter to the Dart VM when
   * executing any Dart file inside the source directory.
   *
   * Files in any directories that are not overridden by this mapping have
   * their package: URI's resolved using the normal pubspec.yaml mechanism. If
   * this field is absent, or the empty map is specified, that indicates that
   * the normal pubspec.yaml mechanism should always be used.
   */
  Map<String, String> get packageRoots => _packageRoots;

  /**
   * A mapping from source directories to target directories that should
   * override the normal package: URI resolution mechanism. The analyzer will
   * behave as though each source directory in the map contains a special
   * pubspec.yaml file which resolves any package: URI to the corresponding
   * path within the target directory. The effect is the same as specifying the
   * target directory as a "--package_root" parameter to the Dart VM when
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

  AnalysisSetAnalysisRootsParams(List<String> included, List<String> excluded, {Map<String, String> packageRoots}) {
    this.included = included;
    this.excluded = excluded;
    this.packageRoots = packageRoots;
  }

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
      Map<String, String> packageRoots;
      if (json.containsKey("packageRoots")) {
        packageRoots = jsonDecoder._decodeMap(jsonPath + ".packageRoots", json["packageRoots"], valueDecoder: jsonDecoder._decodeString);
      }
      return new AnalysisSetAnalysisRootsParams(included, excluded, packageRoots: packageRoots);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setAnalysisRoots params", json);
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
    if (packageRoots != null) {
      result["packageRoots"] = packageRoots;
    }
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
          _listEqual(excluded, other.excluded, (String a, String b) => a == b) &&
          _mapEqual(packageRoots, other.packageRoots, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, included.hashCode);
    hash = _JenkinsSmiHash.combine(hash, excluded.hashCode);
    hash = _JenkinsSmiHash.combine(hash, packageRoots.hashCode);
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
 * analysis.setGeneralSubscriptions params
 *
 * {
 *   "subscriptions": List<GeneralAnalysisService>
 * }
 */
class AnalysisSetGeneralSubscriptionsParams implements HasToJson {
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

  AnalysisSetGeneralSubscriptionsParams(List<GeneralAnalysisService> subscriptions) {
    this.subscriptions = subscriptions;
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<GeneralAnalysisService> subscriptions;
      if (json.containsKey("subscriptions")) {
        subscriptions = jsonDecoder._decodeList(jsonPath + ".subscriptions", json["subscriptions"], (String jsonPath, Object json) => new GeneralAnalysisService.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "subscriptions");
      }
      return new AnalysisSetGeneralSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setGeneralSubscriptions params", json);
    }
  }

  factory AnalysisSetGeneralSubscriptionsParams.fromRequest(Request request) {
    return new AnalysisSetGeneralSubscriptionsParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["subscriptions"] = subscriptions.map((GeneralAnalysisService value) => value.toJson()).toList();
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "analysis.setGeneralSubscriptions", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisSetGeneralSubscriptionsParams) {
      return _listEqual(subscriptions, other.subscriptions, (GeneralAnalysisService a, GeneralAnalysisService b) => a == b);
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
 * analysis.setGeneralSubscriptions result
 */
class AnalysisSetGeneralSubscriptionsResult {
  Response toResponse(String id) {
    return new Response(id, result: null);
  }

  @override
  bool operator==(other) {
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
 */
class AnalysisSetPriorityFilesParams implements HasToJson {
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
        files = jsonDecoder._decodeList(jsonPath + ".files", json["files"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "files");
      }
      return new AnalysisSetPriorityFilesParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setPriorityFiles params", json);
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
        subscriptions = jsonDecoder._decodeMap(jsonPath + ".subscriptions", json["subscriptions"], keyDecoder: (String jsonPath, Object json) => new AnalysisService.fromJson(jsonDecoder, jsonPath, json), valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeList(jsonPath, json, jsonDecoder._decodeString));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "subscriptions");
      }
      return new AnalysisSetSubscriptionsParams(subscriptions);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.setSubscriptions params", json);
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
        files = jsonDecoder._decodeMap(jsonPath + ".files", json["files"], valueDecoder: (String jsonPath, Object json) => jsonDecoder._decodeUnion(jsonPath, json, "type", {"add": (String jsonPath, Object json) => new AddContentOverlay.fromJson(jsonDecoder, jsonPath, json), "change": (String jsonPath, Object json) => new ChangeContentOverlay.fromJson(jsonDecoder, jsonPath, json), "remove": (String jsonPath, Object json) => new RemoveContentOverlay.fromJson(jsonDecoder, jsonPath, json)}));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "files");
      }
      return new AnalysisUpdateContentParams(files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.updateContent params", json);
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
 *
 * {
 * }
 */
class AnalysisUpdateContentResult implements HasToJson {
  AnalysisUpdateContentResult();

  factory AnalysisUpdateContentResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      return new AnalysisUpdateContentResult();
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.updateContent result", json);
    }
  }

  factory AnalysisUpdateContentResult.fromResponse(Response response) {
    return new AnalysisUpdateContentResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is AnalysisUpdateContentResult) {
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
 * analysis.updateOptions params
 *
 * {
 *   "options": AnalysisOptions
 * }
 */
class AnalysisUpdateOptionsParams implements HasToJson {
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.updateOptions params", json);
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
 * analysis.analyzedFiles params
 *
 * {
 *   "directories": List<FilePath>
 * }
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

  factory AnalysisAnalyzedFilesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<String> directories;
      if (json.containsKey("directories")) {
        directories = jsonDecoder._decodeList(jsonPath + ".directories", json["directories"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "directories");
      }
      return new AnalysisAnalyzedFilesParams(directories);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.analyzedFiles params", json);
    }
  }

  factory AnalysisAnalyzedFilesParams.fromNotification(Notification notification) {
    return new AnalysisAnalyzedFilesParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
  bool operator==(other) {
    if (other is AnalysisAnalyzedFilesParams) {
      return _listEqual(directories, other.directories, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, directories.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.errors params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.flushResults params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.folding params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.highlights params", json);
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
 * analysis.invalidate params
 *
 * {
 *   "file": FilePath
 *   "offset": int
 *   "length": int
 *   "delta": int
 * }
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

  factory AnalysisInvalidateParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      int delta;
      if (json.containsKey("delta")) {
        delta = jsonDecoder._decodeInt(jsonPath + ".delta", json["delta"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "delta");
      }
      return new AnalysisInvalidateParams(file, offset, length, delta);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.invalidate params", json);
    }
  }

  factory AnalysisInvalidateParams.fromNotification(Notification notification) {
    return new AnalysisInvalidateParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
  bool operator==(other) {
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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, delta.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
      List<NavigationTarget> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder._decodeList(jsonPath + ".targets", json["targets"], (String jsonPath, Object json) => new NavigationTarget.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "targets");
      }
      List<String> files;
      if (json.containsKey("files")) {
        files = jsonDecoder._decodeList(jsonPath + ".files", json["files"], jsonDecoder._decodeString);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "files");
      }
      return new AnalysisNavigationParams(file, regions, targets, files);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "analysis.navigation params", json);
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
          _listEqual(regions, other.regions, (NavigationRegion a, NavigationRegion b) => a == b) &&
          _listEqual(targets, other.targets, (NavigationTarget a, NavigationTarget b) => a == b) &&
          _listEqual(files, other.files, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, regions.hashCode);
    hash = _JenkinsSmiHash.combine(hash, targets.hashCode);
    hash = _JenkinsSmiHash.combine(hash, files.hashCode);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.occurrences params", json);
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
  String _file;

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

  AnalysisOutlineParams(String file, Outline outline) {
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.outline params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "analysis.overrides params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "completion.getSuggestions params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "completion.getSuggestions result", json);
    }
  }

  factory CompletionGetSuggestionsResult.fromResponse(Response response) {
    return new CompletionGetSuggestionsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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

  CompletionResultsParams(String id, int replacementOffset, int replacementLength, List<CompletionSuggestion> results, bool isLast) {
    this.id = id;
    this.replacementOffset = replacementOffset;
    this.replacementLength = replacementLength;
    this.results = results;
    this.isLast = isLast;
  }

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
      throw jsonDecoder.mismatch(jsonPath, "completion.results params", json);
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

  SearchFindElementReferencesParams(String file, int offset, bool includePotential) {
    this.file = file;
    this.offset = offset;
    this.includePotential = includePotential;
  }

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
      throw jsonDecoder.mismatch(jsonPath, "search.findElementReferences params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findElementReferences result", json);
    }
  }

  factory SearchFindElementReferencesResult.fromResponse(Response response) {
    return new SearchFindElementReferencesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberDeclarations params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberDeclarations result", json);
    }
  }

  factory SearchFindMemberDeclarationsResult.fromResponse(Response response) {
    return new SearchFindMemberDeclarationsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberReferences params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findMemberReferences result", json);
    }
  }

  factory SearchFindMemberReferencesResult.fromResponse(Response response) {
    return new SearchFindMemberReferencesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findTopLevelDeclarations params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "search.findTopLevelDeclarations result", json);
    }
  }

  factory SearchFindTopLevelDeclarationsResult.fromResponse(Response response) {
    return new SearchFindTopLevelDeclarationsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
  String _file;

  int _offset;

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

  SearchGetTypeHierarchyParams(String file, int offset) {
    this.file = file;
    this.offset = offset;
  }

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
      throw jsonDecoder.mismatch(jsonPath, "search.getTypeHierarchy params", json);
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

  factory SearchGetTypeHierarchyResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<TypeHierarchyItem> hierarchyItems;
      if (json.containsKey("hierarchyItems")) {
        hierarchyItems = jsonDecoder._decodeList(jsonPath + ".hierarchyItems", json["hierarchyItems"], (String jsonPath, Object json) => new TypeHierarchyItem.fromJson(jsonDecoder, jsonPath, json));
      }
      return new SearchGetTypeHierarchyResult(hierarchyItems: hierarchyItems);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "search.getTypeHierarchy result", json);
    }
  }

  factory SearchGetTypeHierarchyResult.fromResponse(Response response) {
    return new SearchGetTypeHierarchyResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    if (hierarchyItems != null) {
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
      throw jsonDecoder.mismatch(jsonPath, "search.results params", json);
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
 * edit.format params
 *
 * {
 *   "file": FilePath
 *   "selectionOffset": int
 *   "selectionLength": int
 *   "lineLength": optional int
 * }
 */
class EditFormatParams implements HasToJson {
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

  EditFormatParams(String file, int selectionOffset, int selectionLength, {int lineLength}) {
    this.file = file;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
    this.lineLength = lineLength;
  }

  factory EditFormatParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      int lineLength;
      if (json.containsKey("lineLength")) {
        lineLength = jsonDecoder._decodeInt(jsonPath + ".lineLength", json["lineLength"]);
      }
      return new EditFormatParams(file, selectionOffset, selectionLength, lineLength: lineLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.format params", json);
    }
  }

  factory EditFormatParams.fromRequest(Request request) {
    return new EditFormatParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

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

  Request toRequest(String id) {
    return new Request(id, "edit.format", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
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
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selectionLength.hashCode);
    hash = _JenkinsSmiHash.combine(hash, lineLength.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class EditFormatResult implements HasToJson {
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

  EditFormatResult(List<SourceEdit> edits, int selectionOffset, int selectionLength) {
    this.edits = edits;
    this.selectionOffset = selectionOffset;
    this.selectionLength = selectionLength;
  }

  factory EditFormatResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      List<SourceEdit> edits;
      if (json.containsKey("edits")) {
        edits = jsonDecoder._decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edits");
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
      return new EditFormatResult(edits, selectionOffset, selectionLength);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.format result", json);
    }
  }

  factory EditFormatResult.fromResponse(Response response) {
    return new EditFormatResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edits"] = edits.map((SourceEdit value) => value.toJson()).toList();
    result["selectionOffset"] = selectionOffset;
    result["selectionLength"] = selectionLength;
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditFormatResult) {
      return _listEqual(edits, other.edits, (SourceEdit a, SourceEdit b) => a == b) &&
          selectionOffset == other.selectionOffset &&
          selectionLength == other.selectionLength;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, edits.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selectionOffset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, selectionLength.hashCode);
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getAssists params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getAssists result", json);
    }
  }

  factory EditGetAssistsResult.fromResponse(Response response) {
    return new EditGetAssistsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getAvailableRefactorings params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getAvailableRefactorings result", json);
    }
  }

  factory EditGetAvailableRefactoringsResult.fromResponse(Response response) {
    return new EditGetAvailableRefactoringsResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getFixes params", json);
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
        fixes = jsonDecoder._decodeList(jsonPath + ".fixes", json["fixes"], (String jsonPath, Object json) => new AnalysisErrorFixes.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "fixes");
      }
      return new EditGetFixesResult(fixes);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getFixes result", json);
    }
  }

  factory EditGetFixesResult.fromResponse(Response response) {
    return new EditGetFixesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
   * as “Options”. This field can be omitted if the refactoring does not
   * require any options or if the values of those options are not known.
   */
  RefactoringOptions get options => _options;

  /**
   * Data used to provide values provided by the user. The structure of the
   * data is dependent on the kind of refactoring being performed. The data
   * that is expected is documented in the section titled Refactorings, labeled
   * as “Options”. This field can be omitted if the refactoring does not
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
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring params", json);
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
   * “Feedback”.
   */
  RefactoringFeedback get feedback => _feedback;

  /**
   * Data used to provide feedback to the user. The structure of the data is
   * dependent on the kind of refactoring being created. The data that is
   * returned is documented in the section titled Refactorings, labeled as
   * “Feedback”.
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
      }
      return new EditGetRefactoringResult(initialProblems, optionsProblems, finalProblems, feedback: feedback, change: change, potentialEdits: potentialEdits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.getRefactoring result", json);
    }
  }

  factory EditGetRefactoringResult.fromResponse(Response response) {
    return new EditGetRefactoringResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
    if (potentialEdits != null) {
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
 * edit.sortMembers params
 *
 * {
 *   "file": FilePath
 * }
 */
class EditSortMembersParams implements HasToJson {
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

  factory EditSortMembersParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      return new EditSortMembersParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.sortMembers params", json);
    }
  }

  factory EditSortMembersParams.fromRequest(Request request) {
    return new EditSortMembersParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "edit.sortMembers", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditSortMembersParams) {
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
 * edit.sortMembers result
 *
 * {
 *   "edit": SourceFileEdit
 * }
 */
class EditSortMembersResult implements HasToJson {
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

  factory EditSortMembersResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey("edit")) {
        edit = new SourceFileEdit.fromJson(jsonDecoder, jsonPath + ".edit", json["edit"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edit");
      }
      return new EditSortMembersResult(edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.sortMembers result", json);
    }
  }

  factory EditSortMembersResult.fromResponse(Response response) {
    return new EditSortMembersResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edit"] = edit.toJson();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditSortMembersResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, edit.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * edit.organizeDirectives params
 *
 * {
 *   "file": FilePath
 * }
 */
class EditOrganizeDirectivesParams implements HasToJson {
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

  factory EditOrganizeDirectivesParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      return new EditOrganizeDirectivesParams(file);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.organizeDirectives params", json);
    }
  }

  factory EditOrganizeDirectivesParams.fromRequest(Request request) {
    return new EditOrganizeDirectivesParams.fromJson(
        new RequestDecoder(request), "params", request._params);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["file"] = file;
    return result;
  }

  Request toRequest(String id) {
    return new Request(id, "edit.organizeDirectives", toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditOrganizeDirectivesParams) {
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
 * edit.organizeDirectives result
 *
 * {
 *   "edit": SourceFileEdit
 * }
 */
class EditOrganizeDirectivesResult implements HasToJson {
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

  factory EditOrganizeDirectivesResult.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      SourceFileEdit edit;
      if (json.containsKey("edit")) {
        edit = new SourceFileEdit.fromJson(jsonDecoder, jsonPath + ".edit", json["edit"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edit");
      }
      return new EditOrganizeDirectivesResult(edit);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "edit.organizeDirectives result", json);
    }
  }

  factory EditOrganizeDirectivesResult.fromResponse(Response response) {
    return new EditOrganizeDirectivesResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["edit"] = edit.toJson();
    return result;
  }

  Response toResponse(String id) {
    return new Response(id, result: toJson());
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is EditOrganizeDirectivesResult) {
      return edit == other.edit;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, edit.hashCode);
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
      throw jsonDecoder.mismatch(jsonPath, "execution.createContext params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "execution.createContext result", json);
    }
  }

  factory ExecutionCreateContextResult.fromResponse(Response response) {
    return new ExecutionCreateContextResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "execution.deleteContext params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "execution.mapUri params", json);
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
      throw jsonDecoder.mismatch(jsonPath, "execution.mapUri result", json);
    }
  }

  factory ExecutionMapUriResult.fromResponse(Response response) {
    return new ExecutionMapUriResult.fromJson(
        new ResponseDecoder(REQUEST_ID_REFACTORING_KINDS.remove(response.id)), "result", response._result);
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
      throw jsonDecoder.mismatch(jsonPath, "execution.setSubscriptions params", json);
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
 *   "file": FilePath
 *   "kind": optional ExecutableKind
 *   "referencedFiles": optional List<FilePath>
 * }
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

  ExecutionLaunchDataParams(String file, {ExecutableKind kind, List<String> referencedFiles}) {
    this.file = file;
    this.kind = kind;
    this.referencedFiles = referencedFiles;
  }

  factory ExecutionLaunchDataParams.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
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
      }
      List<String> referencedFiles;
      if (json.containsKey("referencedFiles")) {
        referencedFiles = jsonDecoder._decodeList(jsonPath + ".referencedFiles", json["referencedFiles"], jsonDecoder._decodeString);
      }
      return new ExecutionLaunchDataParams(file, kind: kind, referencedFiles: referencedFiles);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "execution.launchData params", json);
    }
  }

  factory ExecutionLaunchDataParams.fromNotification(Notification notification) {
    return new ExecutionLaunchDataParams.fromJson(
        new ResponseDecoder(null), "params", notification._params);
  }

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
  bool operator==(other) {
    if (other is ExecutionLaunchDataParams) {
      return file == other.file &&
          kind == other.kind &&
          _listEqual(referencedFiles, other.referencedFiles, (String a, String b) => a == b);
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, file.hashCode);
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, referencedFiles.hashCode);
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
        content = jsonDecoder._decodeString(jsonPath + ".content", json["content"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "content");
      }
      return new AddContentOverlay(content);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AddContentOverlay", json);
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
  AnalysisErrorSeverity _severity;

  AnalysisErrorType _type;

  Location _location;

  String _message;

  String _correction;

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

  AnalysisError(AnalysisErrorSeverity severity, AnalysisErrorType type, Location location, String message, {String correction}) {
    this.severity = severity;
    this.type = type;
    this.location = location;
    this.message = message;
    this.correction = correction;
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
      throw jsonDecoder.mismatch(jsonPath, "AnalysisError", json);
    }
  }

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
      throw jsonDecoder.mismatch(jsonPath, "AnalysisErrorFixes", json);
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["error"] = error.toJson();
    result["fixes"] = fixes.map((SourceChange value) => value.toJson()).toList();
    return result;
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
class AnalysisErrorSeverity implements Enum {
  static const INFO = const AnalysisErrorSeverity._("INFO");

  static const WARNING = const AnalysisErrorSeverity._("WARNING");

  static const ERROR = const AnalysisErrorSeverity._("ERROR");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisErrorSeverity> VALUES = const <AnalysisErrorSeverity>[INFO, WARNING, ERROR];

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
 */
class AnalysisErrorType implements Enum {
  static const CHECKED_MODE_COMPILE_TIME_ERROR = const AnalysisErrorType._("CHECKED_MODE_COMPILE_TIME_ERROR");

  static const COMPILE_TIME_ERROR = const AnalysisErrorType._("COMPILE_TIME_ERROR");

  static const HINT = const AnalysisErrorType._("HINT");

  static const LINT = const AnalysisErrorType._("LINT");

  static const STATIC_TYPE_WARNING = const AnalysisErrorType._("STATIC_TYPE_WARNING");

  static const STATIC_WARNING = const AnalysisErrorType._("STATIC_WARNING");

  static const SYNTACTIC_ERROR = const AnalysisErrorType._("SYNTACTIC_ERROR");

  static const TODO = const AnalysisErrorType._("TODO");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisErrorType> VALUES = const <AnalysisErrorType>[CHECKED_MODE_COMPILE_TIME_ERROR, COMPILE_TIME_ERROR, HINT, LINT, STATIC_TYPE_WARNING, STATIC_WARNING, SYNTACTIC_ERROR, TODO];

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
 * AnalysisOptions
 *
 * {
 *   "enableAsync": optional bool
 *   "enableDeferredLoading": optional bool
 *   "enableEnums": optional bool
 *   "enableNullAwareOperators": optional bool
 *   "generateDart2jsHints": optional bool
 *   "generateHints": optional bool
 *   "generateLints": optional bool
 * }
 */
class AnalysisOptions implements HasToJson {
  bool _enableAsync;

  bool _enableDeferredLoading;

  bool _enableEnums;

  bool _enableNullAwareOperators;

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

  AnalysisOptions({bool enableAsync, bool enableDeferredLoading, bool enableEnums, bool enableNullAwareOperators, bool generateDart2jsHints, bool generateHints, bool generateLints}) {
    this.enableAsync = enableAsync;
    this.enableDeferredLoading = enableDeferredLoading;
    this.enableEnums = enableEnums;
    this.enableNullAwareOperators = enableNullAwareOperators;
    this.generateDart2jsHints = generateDart2jsHints;
    this.generateHints = generateHints;
    this.generateLints = generateLints;
  }

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
      bool enableNullAwareOperators;
      if (json.containsKey("enableNullAwareOperators")) {
        enableNullAwareOperators = jsonDecoder._decodeBool(jsonPath + ".enableNullAwareOperators", json["enableNullAwareOperators"]);
      }
      bool generateDart2jsHints;
      if (json.containsKey("generateDart2jsHints")) {
        generateDart2jsHints = jsonDecoder._decodeBool(jsonPath + ".generateDart2jsHints", json["generateDart2jsHints"]);
      }
      bool generateHints;
      if (json.containsKey("generateHints")) {
        generateHints = jsonDecoder._decodeBool(jsonPath + ".generateHints", json["generateHints"]);
      }
      bool generateLints;
      if (json.containsKey("generateLints")) {
        generateLints = jsonDecoder._decodeBool(jsonPath + ".generateLints", json["generateLints"]);
      }
      return new AnalysisOptions(enableAsync: enableAsync, enableDeferredLoading: enableDeferredLoading, enableEnums: enableEnums, enableNullAwareOperators: enableNullAwareOperators, generateDart2jsHints: generateDart2jsHints, generateHints: generateHints, generateLints: generateLints);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "AnalysisOptions", json);
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
    if (enableNullAwareOperators != null) {
      result["enableNullAwareOperators"] = enableNullAwareOperators;
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
  bool operator==(other) {
    if (other is AnalysisOptions) {
      return enableAsync == other.enableAsync &&
          enableDeferredLoading == other.enableDeferredLoading &&
          enableEnums == other.enableEnums &&
          enableNullAwareOperators == other.enableNullAwareOperators &&
          generateDart2jsHints == other.generateDart2jsHints &&
          generateHints == other.generateHints &&
          generateLints == other.generateLints;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, enableAsync.hashCode);
    hash = _JenkinsSmiHash.combine(hash, enableDeferredLoading.hashCode);
    hash = _JenkinsSmiHash.combine(hash, enableEnums.hashCode);
    hash = _JenkinsSmiHash.combine(hash, enableNullAwareOperators.hashCode);
    hash = _JenkinsSmiHash.combine(hash, generateDart2jsHints.hashCode);
    hash = _JenkinsSmiHash.combine(hash, generateHints.hashCode);
    hash = _JenkinsSmiHash.combine(hash, generateLints.hashCode);
    return _JenkinsSmiHash.finish(hash);
  }
}

/**
 * AnalysisService
 *
 * enum {
 *   FOLDING
 *   HIGHLIGHTS
 *   INVALIDATE
 *   NAVIGATION
 *   OCCURRENCES
 *   OUTLINE
 *   OVERRIDES
 * }
 */
class AnalysisService implements Enum {
  static const FOLDING = const AnalysisService._("FOLDING");

  static const HIGHLIGHTS = const AnalysisService._("HIGHLIGHTS");

  /**
   * This service is not currently implemented and will become a
   * GeneralAnalysisService in a future release.
   */
  static const INVALIDATE = const AnalysisService._("INVALIDATE");

  static const NAVIGATION = const AnalysisService._("NAVIGATION");

  static const OCCURRENCES = const AnalysisService._("OCCURRENCES");

  static const OUTLINE = const AnalysisService._("OUTLINE");

  static const OVERRIDES = const AnalysisService._("OVERRIDES");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<AnalysisService> VALUES = const <AnalysisService>[FOLDING, HIGHLIGHTS, INVALIDATE, NAVIGATION, OCCURRENCES, OUTLINE, OVERRIDES];

  final String name;

  const AnalysisService._(this.name);

  factory AnalysisService(String name) {
    switch (name) {
      case "FOLDING":
        return FOLDING;
      case "HIGHLIGHTS":
        return HIGHLIGHTS;
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
 * AnalysisStatus
 *
 * {
 *   "isAnalyzing": bool
 *   "analysisTarget": optional String
 * }
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
      throw jsonDecoder.mismatch(jsonPath, "AnalysisStatus", json);
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
        edits = jsonDecoder._decodeList(jsonPath + ".edits", json["edits"], (String jsonPath, Object json) => new SourceEdit.fromJson(jsonDecoder, jsonPath, json));
      } else {
        throw jsonDecoder.missingKey(jsonPath, "edits");
      }
      return new ChangeContentOverlay(edits);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "ChangeContentOverlay", json);
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
   * The Dartdoc associated with the element being suggested, This field is
   * omitted if there is no Dartdoc associated with the element.
   */
  String get docComplete => _docComplete;

  /**
   * The Dartdoc associated with the element being suggested, This field is
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
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      int relevance;
      if (json.containsKey("relevance")) {
        relevance = jsonDecoder._decodeInt(jsonPath + ".relevance", json["relevance"]);
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
      }
      List<String> parameterTypes;
      if (json.containsKey("parameterTypes")) {
        parameterTypes = jsonDecoder._decodeList(jsonPath + ".parameterTypes", json["parameterTypes"], jsonDecoder._decodeString);
      }
      int requiredParameterCount;
      if (json.containsKey("requiredParameterCount")) {
        requiredParameterCount = jsonDecoder._decodeInt(jsonPath + ".requiredParameterCount", json["requiredParameterCount"]);
      }
      bool hasNamedParameters;
      if (json.containsKey("hasNamedParameters")) {
        hasNamedParameters = jsonDecoder._decodeBool(jsonPath + ".hasNamedParameters", json["hasNamedParameters"]);
      }
      String parameterName;
      if (json.containsKey("parameterName")) {
        parameterName = jsonDecoder._decodeString(jsonPath + ".parameterName", json["parameterName"]);
      }
      String parameterType;
      if (json.containsKey("parameterType")) {
        parameterType = jsonDecoder._decodeString(jsonPath + ".parameterType", json["parameterType"]);
      }
      String importUri;
      if (json.containsKey("importUri")) {
        importUri = jsonDecoder._decodeString(jsonPath + ".importUri", json["importUri"]);
      }
      return new CompletionSuggestion(kind, relevance, completion, selectionOffset, selectionLength, isDeprecated, isPotential, docSummary: docSummary, docComplete: docComplete, declaringType: declaringType, element: element, returnType: returnType, parameterNames: parameterNames, parameterTypes: parameterTypes, requiredParameterCount: requiredParameterCount, hasNamedParameters: hasNamedParameters, parameterName: parameterName, parameterType: parameterType, importUri: importUri);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "CompletionSuggestion", json);
    }
  }

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
          _listEqual(parameterNames, other.parameterNames, (String a, String b) => a == b) &&
          _listEqual(parameterTypes, other.parameterTypes, (String a, String b) => a == b) &&
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
    hash = _JenkinsSmiHash.combine(hash, hasNamedParameters.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameterName.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameterType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, importUri.hashCode);
    return _JenkinsSmiHash.finish(hash);
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
 */
class CompletionSuggestionKind implements Enum {
  /**
   * A list of arguments for the method or function that is being invoked. For
   * this suggestion kind, the completion field is a textual representation of
   * the invocation and the parameterNames, parameterTypes, and
   * requiredParameterCount attributes are defined.
   */
  static const ARGUMENT_LIST = const CompletionSuggestionKind._("ARGUMENT_LIST");

  static const IMPORT = const CompletionSuggestionKind._("IMPORT");

  /**
   * The element identifier should be inserted at the completion location. For
   * example "someMethod" in import 'myLib.dart' show someMethod; . For
   * suggestions of this kind, the element attribute is defined and the
   * completion field is the element's identifier.
   */
  static const IDENTIFIER = const CompletionSuggestionKind._("IDENTIFIER");

  /**
   * The element is being invoked at the completion location. For example,
   * "someMethod" in x.someMethod(); . For suggestions of this kind, the
   * element attribute is defined and the completion field is the element's
   * identifier.
   */
  static const INVOCATION = const CompletionSuggestionKind._("INVOCATION");

  /**
   * A keyword is being suggested. For suggestions of this kind, the completion
   * is the keyword.
   */
  static const KEYWORD = const CompletionSuggestionKind._("KEYWORD");

  /**
   * A named argument for the current callsite is being suggested. For
   * suggestions of this kind, the completion is the named argument identifier
   * including a trailing ':' and space.
   */
  static const NAMED_ARGUMENT = const CompletionSuggestionKind._("NAMED_ARGUMENT");

  static const OPTIONAL_ARGUMENT = const CompletionSuggestionKind._("OPTIONAL_ARGUMENT");

  static const PARAMETER = const CompletionSuggestionKind._("PARAMETER");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<CompletionSuggestionKind> VALUES = const <CompletionSuggestionKind>[ARGUMENT_LIST, IMPORT, IDENTIFIER, INVOCATION, KEYWORD, NAMED_ARGUMENT, OPTIONAL_ARGUMENT, PARAMETER];

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
      String typeParameters;
      if (json.containsKey("typeParameters")) {
        typeParameters = jsonDecoder._decodeString(jsonPath + ".typeParameters", json["typeParameters"]);
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
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, name.hashCode);
    hash = _JenkinsSmiHash.combine(hash, location.hashCode);
    hash = _JenkinsSmiHash.combine(hash, flags.hashCode);
    hash = _JenkinsSmiHash.combine(hash, parameters.hashCode);
    hash = _JenkinsSmiHash.combine(hash, returnType.hashCode);
    hash = _JenkinsSmiHash.combine(hash, typeParameters.hashCode);
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
 *   ENUM
 *   ENUM_CONSTANT
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
class ElementKind implements Enum {
  static const CLASS = const ElementKind._("CLASS");

  static const CLASS_TYPE_ALIAS = const ElementKind._("CLASS_TYPE_ALIAS");

  static const COMPILATION_UNIT = const ElementKind._("COMPILATION_UNIT");

  static const CONSTRUCTOR = const ElementKind._("CONSTRUCTOR");

  static const ENUM = const ElementKind._("ENUM");

  static const ENUM_CONSTANT = const ElementKind._("ENUM_CONSTANT");

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

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ElementKind> VALUES = const <ElementKind>[CLASS, CLASS_TYPE_ALIAS, COMPILATION_UNIT, CONSTRUCTOR, ENUM, ENUM_CONSTANT, FIELD, FUNCTION, FUNCTION_TYPE_ALIAS, GETTER, LABEL, LIBRARY, LOCAL_VARIABLE, METHOD, PARAMETER, PREFIX, SETTER, TOP_LEVEL_VARIABLE, TYPE_PARAMETER, UNIT_TEST_GROUP, UNIT_TEST_TEST, UNKNOWN];

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
    throw jsonDecoder.mismatch(jsonPath, "ElementKind", json);
  }

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
      throw jsonDecoder.mismatch(jsonPath, "ExecutableFile", json);
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
 *   NOT_EXECUTABLE
 *   SERVER
 * }
 */
class ExecutableKind implements Enum {
  static const CLIENT = const ExecutableKind._("CLIENT");

  static const EITHER = const ExecutableKind._("EITHER");

  static const NOT_EXECUTABLE = const ExecutableKind._("NOT_EXECUTABLE");

  static const SERVER = const ExecutableKind._("SERVER");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ExecutableKind> VALUES = const <ExecutableKind>[CLIENT, EITHER, NOT_EXECUTABLE, SERVER];

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

  factory ExecutableKind.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new ExecutableKind(json);
      } catch(_) {
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
 * ExecutionService
 *
 * enum {
 *   LAUNCH_DATA
 * }
 */
class ExecutionService implements Enum {
  static const LAUNCH_DATA = const ExecutionService._("LAUNCH_DATA");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ExecutionService> VALUES = const <ExecutionService>[LAUNCH_DATA];

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
    throw jsonDecoder.mismatch(jsonPath, "ExecutionService", json);
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
class FoldingKind implements Enum {
  static const COMMENT = const FoldingKind._("COMMENT");

  static const CLASS_MEMBER = const FoldingKind._("CLASS_MEMBER");

  static const DIRECTIVES = const FoldingKind._("DIRECTIVES");

  static const DOCUMENTATION_COMMENT = const FoldingKind._("DOCUMENTATION_COMMENT");

  static const TOP_LEVEL_DECLARATION = const FoldingKind._("TOP_LEVEL_DECLARATION");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<FoldingKind> VALUES = const <FoldingKind>[COMMENT, CLASS_MEMBER, DIRECTIVES, DOCUMENTATION_COMMENT, TOP_LEVEL_DECLARATION];

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
      throw jsonDecoder.mismatch(jsonPath, "FoldingRegion", json);
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
 * GeneralAnalysisService
 *
 * enum {
 *   ANALYZED_FILES
 * }
 */
class GeneralAnalysisService implements Enum {
  static const ANALYZED_FILES = const GeneralAnalysisService._("ANALYZED_FILES");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<GeneralAnalysisService> VALUES = const <GeneralAnalysisService>[ANALYZED_FILES];

  final String name;

  const GeneralAnalysisService._(this.name);

  factory GeneralAnalysisService(String name) {
    switch (name) {
      case "ANALYZED_FILES":
        return ANALYZED_FILES;
    }
    throw new Exception('Illegal enum value: $name');
  }

  factory GeneralAnalysisService.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json is String) {
      try {
        return new GeneralAnalysisService(json);
      } catch(_) {
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
 * HighlightRegion
 *
 * {
 *   "type": HighlightRegionType
 *   "offset": int
 *   "length": int
 * }
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
      throw jsonDecoder.mismatch(jsonPath, "HighlightRegion", json);
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
 */
class HighlightRegionType implements Enum {
  static const ANNOTATION = const HighlightRegionType._("ANNOTATION");

  static const BUILT_IN = const HighlightRegionType._("BUILT_IN");

  static const CLASS = const HighlightRegionType._("CLASS");

  static const COMMENT_BLOCK = const HighlightRegionType._("COMMENT_BLOCK");

  static const COMMENT_DOCUMENTATION = const HighlightRegionType._("COMMENT_DOCUMENTATION");

  static const COMMENT_END_OF_LINE = const HighlightRegionType._("COMMENT_END_OF_LINE");

  static const CONSTRUCTOR = const HighlightRegionType._("CONSTRUCTOR");

  static const DIRECTIVE = const HighlightRegionType._("DIRECTIVE");

  /**
   * Only for version 1 of highlight.
   */
  static const DYNAMIC_TYPE = const HighlightRegionType._("DYNAMIC_TYPE");

  /**
   * Only for version 2 of highlight.
   */
  static const DYNAMIC_LOCAL_VARIABLE_DECLARATION = const HighlightRegionType._("DYNAMIC_LOCAL_VARIABLE_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const DYNAMIC_LOCAL_VARIABLE_REFERENCE = const HighlightRegionType._("DYNAMIC_LOCAL_VARIABLE_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const DYNAMIC_PARAMETER_DECLARATION = const HighlightRegionType._("DYNAMIC_PARAMETER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const DYNAMIC_PARAMETER_REFERENCE = const HighlightRegionType._("DYNAMIC_PARAMETER_REFERENCE");

  static const ENUM = const HighlightRegionType._("ENUM");

  static const ENUM_CONSTANT = const HighlightRegionType._("ENUM_CONSTANT");

  /**
   * Only for version 1 of highlight.
   */
  static const FIELD = const HighlightRegionType._("FIELD");

  /**
   * Only for version 1 of highlight.
   */
  static const FIELD_STATIC = const HighlightRegionType._("FIELD_STATIC");

  /**
   * Only for version 1 of highlight.
   */
  static const FUNCTION = const HighlightRegionType._("FUNCTION");

  /**
   * Only for version 1 of highlight.
   */
  static const FUNCTION_DECLARATION = const HighlightRegionType._("FUNCTION_DECLARATION");

  static const FUNCTION_TYPE_ALIAS = const HighlightRegionType._("FUNCTION_TYPE_ALIAS");

  /**
   * Only for version 1 of highlight.
   */
  static const GETTER_DECLARATION = const HighlightRegionType._("GETTER_DECLARATION");

  static const IDENTIFIER_DEFAULT = const HighlightRegionType._("IDENTIFIER_DEFAULT");

  static const IMPORT_PREFIX = const HighlightRegionType._("IMPORT_PREFIX");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_FIELD_DECLARATION = const HighlightRegionType._("INSTANCE_FIELD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_FIELD_REFERENCE = const HighlightRegionType._("INSTANCE_FIELD_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_GETTER_DECLARATION = const HighlightRegionType._("INSTANCE_GETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_GETTER_REFERENCE = const HighlightRegionType._("INSTANCE_GETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_METHOD_DECLARATION = const HighlightRegionType._("INSTANCE_METHOD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_METHOD_REFERENCE = const HighlightRegionType._("INSTANCE_METHOD_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_SETTER_DECLARATION = const HighlightRegionType._("INSTANCE_SETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const INSTANCE_SETTER_REFERENCE = const HighlightRegionType._("INSTANCE_SETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const INVALID_STRING_ESCAPE = const HighlightRegionType._("INVALID_STRING_ESCAPE");

  static const KEYWORD = const HighlightRegionType._("KEYWORD");

  static const LABEL = const HighlightRegionType._("LABEL");

  /**
   * Only for version 2 of highlight.
   */
  static const LIBRARY_NAME = const HighlightRegionType._("LIBRARY_NAME");

  static const LITERAL_BOOLEAN = const HighlightRegionType._("LITERAL_BOOLEAN");

  static const LITERAL_DOUBLE = const HighlightRegionType._("LITERAL_DOUBLE");

  static const LITERAL_INTEGER = const HighlightRegionType._("LITERAL_INTEGER");

  static const LITERAL_LIST = const HighlightRegionType._("LITERAL_LIST");

  static const LITERAL_MAP = const HighlightRegionType._("LITERAL_MAP");

  static const LITERAL_STRING = const HighlightRegionType._("LITERAL_STRING");

  /**
   * Only for version 2 of highlight.
   */
  static const LOCAL_FUNCTION_DECLARATION = const HighlightRegionType._("LOCAL_FUNCTION_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const LOCAL_FUNCTION_REFERENCE = const HighlightRegionType._("LOCAL_FUNCTION_REFERENCE");

  /**
   * Only for version 1 of highlight.
   */
  static const LOCAL_VARIABLE = const HighlightRegionType._("LOCAL_VARIABLE");

  static const LOCAL_VARIABLE_DECLARATION = const HighlightRegionType._("LOCAL_VARIABLE_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const LOCAL_VARIABLE_REFERENCE = const HighlightRegionType._("LOCAL_VARIABLE_REFERENCE");

  /**
   * Only for version 1 of highlight.
   */
  static const METHOD = const HighlightRegionType._("METHOD");

  /**
   * Only for version 1 of highlight.
   */
  static const METHOD_DECLARATION = const HighlightRegionType._("METHOD_DECLARATION");

  /**
   * Only for version 1 of highlight.
   */
  static const METHOD_DECLARATION_STATIC = const HighlightRegionType._("METHOD_DECLARATION_STATIC");

  /**
   * Only for version 1 of highlight.
   */
  static const METHOD_STATIC = const HighlightRegionType._("METHOD_STATIC");

  /**
   * Only for version 1 of highlight.
   */
  static const PARAMETER = const HighlightRegionType._("PARAMETER");

  /**
   * Only for version 1 of highlight.
   */
  static const SETTER_DECLARATION = const HighlightRegionType._("SETTER_DECLARATION");

  /**
   * Only for version 1 of highlight.
   */
  static const TOP_LEVEL_VARIABLE = const HighlightRegionType._("TOP_LEVEL_VARIABLE");

  /**
   * Only for version 2 of highlight.
   */
  static const PARAMETER_DECLARATION = const HighlightRegionType._("PARAMETER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const PARAMETER_REFERENCE = const HighlightRegionType._("PARAMETER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_FIELD_DECLARATION = const HighlightRegionType._("STATIC_FIELD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_GETTER_DECLARATION = const HighlightRegionType._("STATIC_GETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_GETTER_REFERENCE = const HighlightRegionType._("STATIC_GETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_METHOD_DECLARATION = const HighlightRegionType._("STATIC_METHOD_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_METHOD_REFERENCE = const HighlightRegionType._("STATIC_METHOD_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_SETTER_DECLARATION = const HighlightRegionType._("STATIC_SETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const STATIC_SETTER_REFERENCE = const HighlightRegionType._("STATIC_SETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_FUNCTION_DECLARATION = const HighlightRegionType._("TOP_LEVEL_FUNCTION_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_FUNCTION_REFERENCE = const HighlightRegionType._("TOP_LEVEL_FUNCTION_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_GETTER_DECLARATION = const HighlightRegionType._("TOP_LEVEL_GETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_GETTER_REFERENCE = const HighlightRegionType._("TOP_LEVEL_GETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_SETTER_DECLARATION = const HighlightRegionType._("TOP_LEVEL_SETTER_DECLARATION");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_SETTER_REFERENCE = const HighlightRegionType._("TOP_LEVEL_SETTER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const TOP_LEVEL_VARIABLE_DECLARATION = const HighlightRegionType._("TOP_LEVEL_VARIABLE_DECLARATION");

  static const TYPE_NAME_DYNAMIC = const HighlightRegionType._("TYPE_NAME_DYNAMIC");

  static const TYPE_PARAMETER = const HighlightRegionType._("TYPE_PARAMETER");

  /**
   * Only for version 2 of highlight.
   */
  static const UNRESOLVED_INSTANCE_MEMBER_REFERENCE = const HighlightRegionType._("UNRESOLVED_INSTANCE_MEMBER_REFERENCE");

  /**
   * Only for version 2 of highlight.
   */
  static const VALID_STRING_ESCAPE = const HighlightRegionType._("VALID_STRING_ESCAPE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<HighlightRegionType> VALUES = const <HighlightRegionType>[ANNOTATION, BUILT_IN, CLASS, COMMENT_BLOCK, COMMENT_DOCUMENTATION, COMMENT_END_OF_LINE, CONSTRUCTOR, DIRECTIVE, DYNAMIC_TYPE, DYNAMIC_LOCAL_VARIABLE_DECLARATION, DYNAMIC_LOCAL_VARIABLE_REFERENCE, DYNAMIC_PARAMETER_DECLARATION, DYNAMIC_PARAMETER_REFERENCE, ENUM, ENUM_CONSTANT, FIELD, FIELD_STATIC, FUNCTION, FUNCTION_DECLARATION, FUNCTION_TYPE_ALIAS, GETTER_DECLARATION, IDENTIFIER_DEFAULT, IMPORT_PREFIX, INSTANCE_FIELD_DECLARATION, INSTANCE_FIELD_REFERENCE, INSTANCE_GETTER_DECLARATION, INSTANCE_GETTER_REFERENCE, INSTANCE_METHOD_DECLARATION, INSTANCE_METHOD_REFERENCE, INSTANCE_SETTER_DECLARATION, INSTANCE_SETTER_REFERENCE, INVALID_STRING_ESCAPE, KEYWORD, LABEL, LIBRARY_NAME, LITERAL_BOOLEAN, LITERAL_DOUBLE, LITERAL_INTEGER, LITERAL_LIST, LITERAL_MAP, LITERAL_STRING, LOCAL_FUNCTION_DECLARATION, LOCAL_FUNCTION_REFERENCE, LOCAL_VARIABLE, LOCAL_VARIABLE_DECLARATION, LOCAL_VARIABLE_REFERENCE, METHOD, METHOD_DECLARATION, METHOD_DECLARATION_STATIC, METHOD_STATIC, PARAMETER, SETTER_DECLARATION, TOP_LEVEL_VARIABLE, PARAMETER_DECLARATION, PARAMETER_REFERENCE, STATIC_FIELD_DECLARATION, STATIC_GETTER_DECLARATION, STATIC_GETTER_REFERENCE, STATIC_METHOD_DECLARATION, STATIC_METHOD_REFERENCE, STATIC_SETTER_DECLARATION, STATIC_SETTER_REFERENCE, TOP_LEVEL_FUNCTION_DECLARATION, TOP_LEVEL_FUNCTION_REFERENCE, TOP_LEVEL_GETTER_DECLARATION, TOP_LEVEL_GETTER_REFERENCE, TOP_LEVEL_SETTER_DECLARATION, TOP_LEVEL_SETTER_REFERENCE, TOP_LEVEL_VARIABLE_DECLARATION, TYPE_NAME_DYNAMIC, TYPE_PARAMETER, UNRESOLVED_INSTANCE_MEMBER_REFERENCE, VALID_STRING_ESCAPE];

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
 *   "parameter": optional String
 *   "propagatedType": optional String
 *   "staticType": optional String
 * }
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

  String _parameter;

  String _propagatedType;

  String _staticType;

  /**
   * The offset of the range of characters that encompases the cursor position
   * and has the same hover information as the cursor position.
   */
  int get offset => _offset;

  /**
   * The offset of the range of characters that encompases the cursor position
   * and has the same hover information as the cursor position.
   */
  void set offset(int value) {
    assert(value != null);
    this._offset = value;
  }

  /**
   * The length of the range of characters that encompases the cursor position
   * and has the same hover information as the cursor position.
   */
  int get length => _length;

  /**
   * The length of the range of characters that encompases the cursor position
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
   * as “class” or “function type alias”). This data is omitted if there is no
   * referenced element.
   */
  String get elementKind => _elementKind;

  /**
   * A human-readable description of the kind of element being referenced (such
   * as “class” or “function type alias”). This data is omitted if there is no
   * referenced element.
   */
  void set elementKind(String value) {
    this._elementKind = value;
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

  HoverInformation(int offset, int length, {String containingLibraryPath, String containingLibraryName, String containingClassDescription, String dartdoc, String elementDescription, String elementKind, String parameter, String propagatedType, String staticType}) {
    this.offset = offset;
    this.length = length;
    this.containingLibraryPath = containingLibraryPath;
    this.containingLibraryName = containingLibraryName;
    this.containingClassDescription = containingClassDescription;
    this.dartdoc = dartdoc;
    this.elementDescription = elementDescription;
    this.elementKind = elementKind;
    this.parameter = parameter;
    this.propagatedType = propagatedType;
    this.staticType = staticType;
  }

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
      String containingClassDescription;
      if (json.containsKey("containingClassDescription")) {
        containingClassDescription = jsonDecoder._decodeString(jsonPath + ".containingClassDescription", json["containingClassDescription"]);
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
      return new HoverInformation(offset, length, containingLibraryPath: containingLibraryPath, containingLibraryName: containingLibraryName, containingClassDescription: containingClassDescription, dartdoc: dartdoc, elementDescription: elementDescription, elementKind: elementKind, parameter: parameter, propagatedType: propagatedType, staticType: staticType);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "HoverInformation", json);
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
          containingClassDescription == other.containingClassDescription &&
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
    hash = _JenkinsSmiHash.combine(hash, containingClassDescription.hashCode);
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
      throw jsonDecoder.mismatch(jsonPath, "LinkedEditGroup", json);
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
      throw jsonDecoder.mismatch(jsonPath, "LinkedEditSuggestion", json);
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
class LinkedEditSuggestionKind implements Enum {
  static const METHOD = const LinkedEditSuggestionKind._("METHOD");

  static const PARAMETER = const LinkedEditSuggestionKind._("PARAMETER");

  static const TYPE = const LinkedEditSuggestionKind._("TYPE");

  static const VARIABLE = const LinkedEditSuggestionKind._("VARIABLE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<LinkedEditSuggestionKind> VALUES = const <LinkedEditSuggestionKind>[METHOD, PARAMETER, TYPE, VARIABLE];

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
      throw jsonDecoder.mismatch(jsonPath, "Location", json);
    }
  }

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
 *   "targets": List<int>
 * }
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
   * one form of navigation.
   */
  List<int> get targets => _targets;

  /**
   * The indexes of the targets (in the enclosing navigation response) to which
   * the given region is bound. By opening the target, clients can implement
   * one form of navigation.
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
      List<int> targets;
      if (json.containsKey("targets")) {
        targets = jsonDecoder._decodeList(jsonPath + ".targets", json["targets"], jsonDecoder._decodeInt);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "targets");
      }
      return new NavigationRegion(offset, length, targets);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "NavigationRegion", json);
    }
  }

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
          _listEqual(targets, other.targets, (int a, int b) => a == b);
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
        throw jsonDecoder.missingKey(jsonPath, "kind");
      }
      int fileIndex;
      if (json.containsKey("fileIndex")) {
        fileIndex = jsonDecoder._decodeInt(jsonPath + ".fileIndex", json["fileIndex"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "fileIndex");
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
      return new NavigationTarget(kind, fileIndex, offset, length, startLine, startColumn);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "NavigationTarget", json);
    }
  }

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
    hash = _JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = _JenkinsSmiHash.combine(hash, fileIndex.hashCode);
    hash = _JenkinsSmiHash.combine(hash, offset.hashCode);
    hash = _JenkinsSmiHash.combine(hash, length.hashCode);
    hash = _JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = _JenkinsSmiHash.combine(hash, startColumn.hashCode);
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
      throw jsonDecoder.mismatch(jsonPath, "Occurrences", json);
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
   * the offset in the Element, which if the offset of the name of the element.
   * It can be used, for example, to map locations in the file back to an
   * outline.
   */
  int get offset => _offset;

  /**
   * The offset of the first character of the element. This is different than
   * the offset in the Element, which if the offset of the name of the element.
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
      }
      return new Outline(element, offset, length, children: children);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Outline", json);
    }
  }

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

  Override(int offset, int length, {OverriddenMember superclassMember, List<OverriddenMember> interfaceMembers}) {
    this.offset = offset;
    this.length = length;
    this.superclassMember = superclassMember;
    this.interfaceMembers = interfaceMembers;
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
      }
      return new Override(offset, length, superclassMember: superclassMember, interfaceMembers: interfaceMembers);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "Override", json);
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["offset"] = offset;
    result["length"] = length;
    if (superclassMember != null) {
      result["superclassMember"] = superclassMember.toJson();
    }
    if (interfaceMembers != null) {
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
      throw jsonDecoder.mismatch(jsonPath, "OverriddenMember", json);
    }
  }

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
      throw jsonDecoder.mismatch(jsonPath, "Position", json);
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
 * PubStatus
 *
 * {
 *   "isListingPackageDirs": bool
 * }
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

  factory PubStatus.fromJson(JsonDecoder jsonDecoder, String jsonPath, Object json) {
    if (json == null) {
      json = {};
    }
    if (json is Map) {
      bool isListingPackageDirs;
      if (json.containsKey("isListingPackageDirs")) {
        isListingPackageDirs = jsonDecoder._decodeBool(jsonPath + ".isListingPackageDirs", json["isListingPackageDirs"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "isListingPackageDirs");
      }
      return new PubStatus(isListingPackageDirs);
    } else {
      throw jsonDecoder.mismatch(jsonPath, "PubStatus", json);
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result["isListingPackageDirs"] = isListingPackageDirs;
    return result;
  }

  @override
  String toString() => JSON.encode(toJson());

  @override
  bool operator==(other) {
    if (other is PubStatus) {
      return isListingPackageDirs == other.isListingPackageDirs;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = _JenkinsSmiHash.combine(hash, isListingPackageDirs.hashCode);
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
 *   MOVE_FILE
 *   RENAME
 *   SORT_MEMBERS
 * }
 */
class RefactoringKind implements Enum {
  static const CONVERT_GETTER_TO_METHOD = const RefactoringKind._("CONVERT_GETTER_TO_METHOD");

  static const CONVERT_METHOD_TO_GETTER = const RefactoringKind._("CONVERT_METHOD_TO_GETTER");

  static const EXTRACT_LOCAL_VARIABLE = const RefactoringKind._("EXTRACT_LOCAL_VARIABLE");

  static const EXTRACT_METHOD = const RefactoringKind._("EXTRACT_METHOD");

  static const INLINE_LOCAL_VARIABLE = const RefactoringKind._("INLINE_LOCAL_VARIABLE");

  static const INLINE_METHOD = const RefactoringKind._("INLINE_METHOD");

  static const MOVE_FILE = const RefactoringKind._("MOVE_FILE");

  static const RENAME = const RefactoringKind._("RENAME");

  static const SORT_MEMBERS = const RefactoringKind._("SORT_MEMBERS");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RefactoringKind> VALUES = const <RefactoringKind>[CONVERT_GETTER_TO_METHOD, CONVERT_METHOD_TO_GETTER, EXTRACT_LOCAL_VARIABLE, EXTRACT_METHOD, INLINE_LOCAL_VARIABLE, INLINE_METHOD, MOVE_FILE, RENAME, SORT_MEMBERS];

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
   * type has zero parameters, this field will have a value of "()".
   */
  String get parameters => _parameters;

  /**
   * The parameter list of the parameter's function type. If the parameter is
   * not of a function type, this field will not be defined. If the function
   * type has zero parameters, this field will have a value of "()".
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
      throw jsonDecoder.mismatch(jsonPath, "RefactoringMethodParameter", json);
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
class RefactoringMethodParameterKind implements Enum {
  static const REQUIRED = const RefactoringMethodParameterKind._("REQUIRED");

  static const POSITIONAL = const RefactoringMethodParameterKind._("POSITIONAL");

  static const NAMED = const RefactoringMethodParameterKind._("NAMED");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RefactoringMethodParameterKind> VALUES = const <RefactoringMethodParameterKind>[REQUIRED, POSITIONAL, NAMED];

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
 * RefactoringProblem
 *
 * {
 *   "severity": RefactoringProblemSeverity
 *   "message": String
 *   "location": optional Location
 * }
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
      throw jsonDecoder.mismatch(jsonPath, "RefactoringProblem", json);
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
class RefactoringProblemSeverity implements Enum {
  static const INFO = const RefactoringProblemSeverity._("INFO");

  static const WARNING = const RefactoringProblemSeverity._("WARNING");

  static const ERROR = const RefactoringProblemSeverity._("ERROR");

  static const FATAL = const RefactoringProblemSeverity._("FATAL");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RefactoringProblemSeverity> VALUES = const <RefactoringProblemSeverity>[INFO, WARNING, ERROR, FATAL];

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
        throw jsonDecoder.mismatch(jsonPath, "equal " + "remove", json);
      }
      return new RemoveContentOverlay();
    } else {
      throw jsonDecoder.mismatch(jsonPath, "RemoveContentOverlay", json);
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
      throw jsonDecoder.mismatch(jsonPath, "RequestError", json);
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
 *   CONTENT_MODIFIED
 *   FILE_NOT_ANALYZED
 *   FORMAT_INVALID_FILE
 *   FORMAT_WITH_ERRORS
 *   GET_ERRORS_INVALID_FILE
 *   GET_NAVIGATION_INVALID_FILE
 *   INVALID_ANALYSIS_ROOT
 *   INVALID_EXECUTION_CONTEXT
 *   INVALID_OVERLAY_CHANGE
 *   INVALID_PARAMETER
 *   INVALID_REQUEST
 *   NO_INDEX_GENERATED
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
 */
class RequestErrorCode implements Enum {
  /**
   * An "analysis.getErrors" or "analysis.getNavigation" request could not be
   * satisfied because the content of the file changed before the requested
   * results could be computed.
   */
  static const CONTENT_MODIFIED = const RequestErrorCode._("CONTENT_MODIFIED");

  /**
   * A request specified a FilePath which does not match a file in an analysis
   * root, or the requested operation is not available for the file.
   */
  static const FILE_NOT_ANALYZED = const RequestErrorCode._("FILE_NOT_ANALYZED");

  /**
   * An "edit.format" request specified a FilePath which does not match a Dart
   * file in an analysis root.
   */
  static const FORMAT_INVALID_FILE = const RequestErrorCode._("FORMAT_INVALID_FILE");

  /**
   * An "edit.format" request specified a file that contains syntax errors.
   */
  static const FORMAT_WITH_ERRORS = const RequestErrorCode._("FORMAT_WITH_ERRORS");

  /**
   * An "analysis.getErrors" request specified a FilePath which does not match
   * a file currently subject to analysis.
   */
  static const GET_ERRORS_INVALID_FILE = const RequestErrorCode._("GET_ERRORS_INVALID_FILE");

  /**
   * An "analysis.getNavigation" request specified a FilePath which does not
   * match a file currently subject to analysis.
   */
  static const GET_NAVIGATION_INVALID_FILE = const RequestErrorCode._("GET_NAVIGATION_INVALID_FILE");

  /**
   * A path passed as an argument to a request (such as analysis.reanalyze) is
   * required to be an analysis root, but isn't.
   */
  static const INVALID_ANALYSIS_ROOT = const RequestErrorCode._("INVALID_ANALYSIS_ROOT");

  /**
   * The context root used to create an execution context does not exist.
   */
  static const INVALID_EXECUTION_CONTEXT = const RequestErrorCode._("INVALID_EXECUTION_CONTEXT");

  /**
   * An "analysis.updateContent" request contained a ChangeContentOverlay
   * object which can't be applied, due to an edit having an offset or length
   * that is out of range.
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
   * The "--no-index" flag was passed when the analysis server created, but
   * this API call requires an index to have been generated.
   */
  static const NO_INDEX_GENERATED = const RequestErrorCode._("NO_INDEX_GENERATED");

  /**
   * An "edit.organizeDirectives" request specified a Dart file that cannot be
   * analyzed. The reason is described in the message.
   */
  static const ORGANIZE_DIRECTIVES_ERROR = const RequestErrorCode._("ORGANIZE_DIRECTIVES_ERROR");

  /**
   * Another refactoring request was received during processing of this one.
   */
  static const REFACTORING_REQUEST_CANCELLED = const RequestErrorCode._("REFACTORING_REQUEST_CANCELLED");

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
   * An "edit.sortMembers" request specified a FilePath which does not match a
   * Dart file in an analysis root.
   */
  static const SORT_MEMBERS_INVALID_FILE = const RequestErrorCode._("SORT_MEMBERS_INVALID_FILE");

  /**
   * An "edit.sortMembers" request specified a Dart file that has scan or parse
   * errors.
   */
  static const SORT_MEMBERS_PARSE_ERRORS = const RequestErrorCode._("SORT_MEMBERS_PARSE_ERRORS");

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
   * The analysis server was requested to perform an action on a source that
   * does not exist.
   */
  static const UNKNOWN_SOURCE = const RequestErrorCode._("UNKNOWN_SOURCE");

  /**
   * The analysis server was requested to perform an action which is not
   * supported.
   *
   * This is a legacy error; it will be removed before the API reaches version
   * 1.0.
   */
  static const UNSUPPORTED_FEATURE = const RequestErrorCode._("UNSUPPORTED_FEATURE");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<RequestErrorCode> VALUES = const <RequestErrorCode>[CONTENT_MODIFIED, FILE_NOT_ANALYZED, FORMAT_INVALID_FILE, FORMAT_WITH_ERRORS, GET_ERRORS_INVALID_FILE, GET_NAVIGATION_INVALID_FILE, INVALID_ANALYSIS_ROOT, INVALID_EXECUTION_CONTEXT, INVALID_OVERLAY_CHANGE, INVALID_PARAMETER, INVALID_REQUEST, NO_INDEX_GENERATED, ORGANIZE_DIRECTIVES_ERROR, REFACTORING_REQUEST_CANCELLED, SERVER_ALREADY_STARTED, SERVER_ERROR, SORT_MEMBERS_INVALID_FILE, SORT_MEMBERS_PARSE_ERRORS, UNANALYZED_PRIORITY_FILES, UNKNOWN_REQUEST, UNKNOWN_SOURCE, UNSUPPORTED_FEATURE];

  final String name;

  const RequestErrorCode._(this.name);

  factory RequestErrorCode(String name) {
    switch (name) {
      case "CONTENT_MODIFIED":
        return CONTENT_MODIFIED;
      case "FILE_NOT_ANALYZED":
        return FILE_NOT_ANALYZED;
      case "FORMAT_INVALID_FILE":
        return FORMAT_INVALID_FILE;
      case "FORMAT_WITH_ERRORS":
        return FORMAT_WITH_ERRORS;
      case "GET_ERRORS_INVALID_FILE":
        return GET_ERRORS_INVALID_FILE;
      case "GET_NAVIGATION_INVALID_FILE":
        return GET_NAVIGATION_INVALID_FILE;
      case "INVALID_ANALYSIS_ROOT":
        return INVALID_ANALYSIS_ROOT;
      case "INVALID_EXECUTION_CONTEXT":
        return INVALID_EXECUTION_CONTEXT;
      case "INVALID_OVERLAY_CHANGE":
        return INVALID_OVERLAY_CHANGE;
      case "INVALID_PARAMETER":
        return INVALID_PARAMETER;
      case "INVALID_REQUEST":
        return INVALID_REQUEST;
      case "NO_INDEX_GENERATED":
        return NO_INDEX_GENERATED;
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

  SearchResult(Location location, SearchResultKind kind, bool isPotential, List<Element> path) {
    this.location = location;
    this.kind = kind;
    this.isPotential = isPotential;
    this.path = path;
  }

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
      throw jsonDecoder.mismatch(jsonPath, "SearchResult", json);
    }
  }

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
class SearchResultKind implements Enum {
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

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<SearchResultKind> VALUES = const <SearchResultKind>[DECLARATION, INVOCATION, READ, READ_WRITE, REFERENCE, UNKNOWN, WRITE];

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
    throw jsonDecoder.mismatch(jsonPath, "SearchResultKind", json);
  }

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
class ServerService implements Enum {
  static const STATUS = const ServerService._("STATUS");

  /**
   * A list containing all of the enum values that are defined.
   */
  static const List<ServerService> VALUES = const <ServerService>[STATUS];

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
    throw jsonDecoder.mismatch(jsonPath, "ServerService", json);
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
      throw jsonDecoder.mismatch(jsonPath, "SourceChange", json);
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
      throw jsonDecoder.mismatch(jsonPath, "SourceEdit", json);
    }
  }

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
      throw jsonDecoder.mismatch(jsonPath, "SourceFileEdit", json);
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

  TypeHierarchyItem(Element classElement, {String displayName, Element memberElement, int superclass, List<int> interfaces, List<int> mixins, List<int> subclasses}) {
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
      throw jsonDecoder.mismatch(jsonPath, "TypeHierarchyItem", json);
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
  List<String> _names;

  List<int> _offsets;

  List<int> _lengths;

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

  ExtractLocalVariableFeedback(List<String> names, List<int> offsets, List<int> lengths) {
    this.names = names;
    this.offsets = offsets;
    this.lengths = lengths;
  }

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
      throw jsonDecoder.mismatch(jsonPath, "extractLocalVariable feedback", json);
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
      throw jsonDecoder.mismatch(jsonPath, "extractLocalVariable options", json);
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
      throw jsonDecoder.mismatch(jsonPath, "extractMethod feedback", json);
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
      throw jsonDecoder.mismatch(jsonPath, "extractMethod options", json);
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
      throw jsonDecoder.mismatch(jsonPath, "inlineLocalVariable feedback", json);
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
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod feedback", json);
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
      throw jsonDecoder.mismatch(jsonPath, "inlineMethod options", json);
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
        newFile = jsonDecoder._decodeString(jsonPath + ".newFile", json["newFile"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "newFile");
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
      throw jsonDecoder.mismatch(jsonPath, "rename feedback", json);
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
        newName = jsonDecoder._decodeString(jsonPath + ".newName", json["newName"]);
      } else {
        throw jsonDecoder.missingKey(jsonPath, "newName");
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
