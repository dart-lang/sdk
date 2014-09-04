// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protocol;

import 'dart:collection';
import 'dart:convert';

import 'package:analysis_server/src/computer/element.dart' show
    elementFromEngine;
import 'package:analysis_server/src/search/search_result.dart' show
    searchResultFromMatch;
import 'package:analysis_server/src/services/correction/fix.dart' show Fix;
import 'package:analysis_server/src/services/json.dart';
import 'package:analysis_server/src/services/search/search_engine.dart' as
    engine;
import 'package:analyzer/src/generated/ast.dart' as engine;
import 'package:analyzer/src/generated/element.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/error.dart' as engine;
import 'package:analyzer/src/generated/source.dart' as engine;

part 'generated_protocol.dart';


final Map<String, RefactoringKind> REQUEST_ID_REFACTORING_KINDS =
    new HashMap<String, RefactoringKind>();

/**
 * Translate the input [map], applying [keyCallback] to all its keys, and
 * [valueCallback] to all its values.
 */
mapMap(Map map, {dynamic keyCallback(key), dynamic valueCallback(value)}) {
  Map result = {};
  map.forEach((key, value) {
    if (keyCallback != null) {
      key = keyCallback(key);
    }
    if (valueCallback != null) {
      value = valueCallback(value);
    }
    result[key] = value;
  });
  return result;
}

/**
 * Adds the given [sourceEdits] to the list in [sourceFileEdit].
 */
void _addAllEditsForSource(SourceFileEdit sourceFileEdit,
    Iterable<SourceEdit> edits) {
  edits.forEach(sourceFileEdit.add);
}

/**
 * Adds the given [sourceEdit] to the list in [sourceFileEdit].
 */
void _addEditForSource(SourceFileEdit sourceFileEdit, SourceEdit sourceEdit) {
  List<SourceEdit> edits = sourceFileEdit.edits;
  int index = 0;
  while (index < edits.length && edits[index].offset > sourceEdit.offset) {
    index++;
  }
  edits.insert(index, sourceEdit);
}

/**
 * Adds [edit] to the [FileEdit] for the given [file].
 */
void _addEditToSourceChange(SourceChange change, String file, SourceEdit edit) {
  SourceFileEdit fileEdit = change.getFileEdit(file);
  if (fileEdit == null) {
    fileEdit = new SourceFileEdit(file);
    change.addFileEdit(fileEdit);
  }
  fileEdit.add(edit);
}

/**
 * Create an AnalysisError based on error information from the analyzer
 * engine.  Access via AnalysisError.fromEngine().
 */
AnalysisError _analysisErrorFromEngine(engine.LineInfo lineInfo,
    engine.AnalysisError error) {
  engine.ErrorCode errorCode = error.errorCode;
  // prepare location
  Location location;
  {
    String file = error.source.fullName;
    int offset = error.offset;
    int length = error.length;
    int startLine = -1;
    int startColumn = -1;
    if (lineInfo != null) {
      engine.LineInfo_Location lineLocation = lineInfo.getLocation(offset);
      if (lineLocation != null) {
        startLine = lineLocation.lineNumber;
        startColumn = lineLocation.columnNumber;
      }
    }
    location = new Location(file, offset, length, startLine, startColumn);
  }
  // done
  var severity = new AnalysisErrorSeverity(errorCode.errorSeverity.name);
  var type = new AnalysisErrorType(errorCode.type.name);
  String message = error.message;
  String correction = error.correction;
  return new AnalysisError(
      severity,
      type,
      location,
      message,
      correction: correction);
}

/**
 * Returns a list of AnalysisErrors correponding to the given list of Engine
 * errors.  Access via AnalysisError.listFromEngine().
 */
List<AnalysisError> _analysisErrorListFromEngine(engine.LineInfo lineInfo,
    List<engine.AnalysisError> errors) {
  return errors.map((engine.AnalysisError error) {
    return new AnalysisError.fromEngine(lineInfo, error);
  }).toList();
}

/**
 * Get the result of applying the edit to the given [code].  Access via
 * SourceEdit.apply().
 */
String _applyEdit(String code, SourceEdit edit) {
  return code.substring(0, edit.offset) +
      edit.replacement +
      code.substring(edit.end);
}

/**
 * Get the result of applying a set of [edits] to the given [code].  Edits
 * are applied in the order they appear in [edits].  Access via
 * SourceEdit.applySequence().
 */
String _applySequence(String code, Iterable<SourceEdit> edits) {
  edits.forEach((SourceEdit edit) {
    code = edit.apply(code);
  });
  return code;
}

/**
 * Map an element kind from the analyzer engine to a [CompletionSuggestionKind].
 */
CompletionSuggestionKind _completionSuggestionKindFromElementKind(engine.ElementKind kind) {
  //    ElementKind.ANGULAR_FORMATTER,
  //    ElementKind.ANGULAR_COMPONENT,
  //    ElementKind.ANGULAR_CONTROLLER,
  //    ElementKind.ANGULAR_DIRECTIVE,
  //    ElementKind.ANGULAR_PROPERTY,
  //    ElementKind.ANGULAR_SCOPE_PROPERTY,
  //    ElementKind.ANGULAR_SELECTOR,
  //    ElementKind.ANGULAR_VIEW,
  if (kind == engine.ElementKind.CLASS) return CompletionSuggestionKind.CLASS;
  //    ElementKind.COMPILATION_UNIT,
  if (kind == engine.ElementKind.CONSTRUCTOR) return CompletionSuggestionKind.CONSTRUCTOR;
  //    ElementKind.DYNAMIC,
  //    ElementKind.EMBEDDED_HTML_SCRIPT,
  //    ElementKind.ERROR,
  //    ElementKind.EXPORT,
  //    ElementKind.EXTERNAL_HTML_SCRIPT,
  if (kind == engine.ElementKind.FIELD) return CompletionSuggestionKind.FIELD;
  if (kind == engine.ElementKind.FUNCTION) return CompletionSuggestionKind.FUNCTION;
  if (kind == engine.ElementKind.FUNCTION_TYPE_ALIAS) return CompletionSuggestionKind.FUNCTION_TYPE_ALIAS;
  if (kind == engine.ElementKind.GETTER) return CompletionSuggestionKind.GETTER;
  //    ElementKind.HTML,
  if (kind == engine.ElementKind.IMPORT) return CompletionSuggestionKind.IMPORT;
  //    ElementKind.LABEL,
  //    ElementKind.LIBRARY,
  if (kind == engine.ElementKind.LOCAL_VARIABLE) return CompletionSuggestionKind.LOCAL_VARIABLE;
  if (kind == engine.ElementKind.METHOD) return CompletionSuggestionKind.METHOD;
  //    ElementKind.NAME,
  if (kind == engine.ElementKind.PARAMETER) return CompletionSuggestionKind.PARAMETER;
  //    ElementKind.POLYMER_ATTRIBUTE,
  //    ElementKind.POLYMER_TAG_DART,
  //    ElementKind.POLYMER_TAG_HTML,
  //    ElementKind.PREFIX,
  if (kind == engine.ElementKind.SETTER) return CompletionSuggestionKind.SETTER;
  if (kind == engine.ElementKind.TOP_LEVEL_VARIABLE) return CompletionSuggestionKind.TOP_LEVEL_VARIABLE;
  //    ElementKind.TYPE_PARAMETER,
  //    ElementKind.UNIVERSE
  throw new ArgumentError('Unknown CompletionSuggestionKind for: $kind');
}

/**
 * Create an ElementKind based on a value from the analyzer engine.  Access
 * this function via new ElementKind.fromEngine().
 */
ElementKind _elementKindFromEngine(engine.ElementKind kind) {
  if (kind == engine.ElementKind.CLASS) {
    return ElementKind.CLASS;
  }
  if (kind == engine.ElementKind.COMPILATION_UNIT) {
    return ElementKind.COMPILATION_UNIT;
  }
  if (kind == engine.ElementKind.CONSTRUCTOR) {
    return ElementKind.CONSTRUCTOR;
  }
  if (kind == engine.ElementKind.FIELD) {
    return ElementKind.FIELD;
  }
  if (kind == engine.ElementKind.FUNCTION) {
    return ElementKind.FUNCTION;
  }
  if (kind == engine.ElementKind.FUNCTION_TYPE_ALIAS) {
    return ElementKind.FUNCTION_TYPE_ALIAS;
  }
  if (kind == engine.ElementKind.GETTER) {
    return ElementKind.GETTER;
  }
  if (kind == engine.ElementKind.LIBRARY) {
    return ElementKind.LIBRARY;
  }
  if (kind == engine.ElementKind.LOCAL_VARIABLE) {
    return ElementKind.LOCAL_VARIABLE;
  }
  if (kind == engine.ElementKind.METHOD) {
    return ElementKind.METHOD;
  }
  if (kind == engine.ElementKind.PARAMETER) {
    return ElementKind.PARAMETER;
  }
  if (kind == engine.ElementKind.SETTER) {
    return ElementKind.SETTER;
  }
  if (kind == engine.ElementKind.TOP_LEVEL_VARIABLE) {
    return ElementKind.TOP_LEVEL_VARIABLE;
  }
  if (kind == engine.ElementKind.TYPE_PARAMETER) {
    return ElementKind.TYPE_PARAMETER;
  }
  return ElementKind.UNKNOWN;
}

/**
 * Returns the [FileEdit] for the given [file], maybe `null`.
 */
SourceFileEdit _getChangeFileEdit(SourceChange change, String file) {
  for (SourceFileEdit fileEdit in change.edits) {
    if (fileEdit.file == file) {
      return fileEdit;
    }
  }
  return null;
}

/**
 * Compare the lists [listA] and [listB], using [itemEqual] to compare
 * list elements.
 */
bool _listEqual(List listA, List listB, bool itemEqual(a, b)) {
  if (listA.length != listB.length) {
    return false;
  }
  for (int i = 0; i < listA.length; i++) {
    if (!itemEqual(listA[i], listB[i])) {
      return false;
    }
  }
  return true;
}

/**
 * Creates a new [Location].
 */
Location _locationForArgs(engine.AnalysisContext context, engine.Source source,
    engine.SourceRange range) {
  int startLine = 0;
  int startColumn = 0;
  {
    engine.LineInfo lineInfo = context.getLineInfo(source);
    if (lineInfo != null) {
      engine.LineInfo_Location offsetLocation =
          lineInfo.getLocation(range.offset);
      startLine = offsetLocation.lineNumber;
      startColumn = offsetLocation.columnNumber;
    }
  }
  return new Location(
      source.fullName,
      range.offset,
      range.length,
      startLine,
      startColumn);
}

/**
 * Creates a new [Location] for the given [engine.Element].
 */
Location _locationFromElement(engine.Element element) {
  engine.AnalysisContext context = element.context;
  engine.Source source = element.source;
  if (context == null || source == null) {
    return null;
  }
  String name = element.displayName;
  int offset = element.nameOffset;
  int length = name != null ? name.length : 0;
  if (element is engine.CompilationUnitElement) {
    offset = 0;
    length = 0;
  }
  engine.SourceRange range = new engine.SourceRange(offset, length);
  return _locationForArgs(context, source, range);
}

/**
 * Creates a new [Location] for the given [engine.SearchMatch].
 */
Location _locationFromMatch(engine.SearchMatch match) {
  engine.Element enclosingElement = match.element;
  return _locationForArgs(
      enclosingElement.context,
      enclosingElement.source,
      match.sourceRange);
}

/**
 * Creates a new [Location] for the given [engine.AstNode].
 */
Location _locationFromNode(engine.AstNode node) {
  engine.CompilationUnit unit =
      node.getAncestor((node) => node is engine.CompilationUnit);
  engine.CompilationUnitElement unitElement = unit.element;
  engine.AnalysisContext context = unitElement.context;
  engine.Source source = unitElement.source;
  engine.SourceRange range = new engine.SourceRange(node.offset, node.length);
  return _locationForArgs(context, source, range);
}

/**
 * Creates a new [Location] for the given [engine.CompilationUnit].
 */
Location _locationFromUnit(engine.CompilationUnit unit,
    engine.SourceRange range) {
  engine.CompilationUnitElement unitElement = unit.element;
  engine.AnalysisContext context = unitElement.context;
  engine.Source source = unitElement.source;
  return _locationForArgs(context, source, range);
}

/**
 * Compare the maps [mapA] and [mapB], using [valueEqual] to compare map
 * values.
 */
bool _mapEqual(Map mapA, Map mapB, bool valueEqual(a, b)) {
  if (mapA.length != mapB.length) {
    return false;
  }
  for (var key in mapA.keys) {
    if (!mapB.containsKey(key)) {
      return false;
    }
    if (!valueEqual(mapA[key], mapB[key])) {
      return false;
    }
  }
  return true;
}

RefactoringProblemSeverity
    _maxRefactoringProblemSeverity(RefactoringProblemSeverity a,
    RefactoringProblemSeverity b) {
  if (b == null) {
    return a;
  }
  if (a == null) {
    return b;
  } else if (a == RefactoringProblemSeverity.INFO) {
    return b;
  } else if (a == RefactoringProblemSeverity.WARNING) {
    if (b == RefactoringProblemSeverity.ERROR ||
        b == RefactoringProblemSeverity.FATAL) {
      return b;
    }
  } else if (a == RefactoringProblemSeverity.ERROR) {
    if (b == RefactoringProblemSeverity.FATAL) {
      return b;
    }
  }
  return a;
}

/**
 * Create an OverriddenMember based on an element from the analyzer engine.
 */
OverriddenMember _overriddenMemberFromEngine(engine.Element member) {
  Element element = elementFromEngine(member);
  String className = member.enclosingElement.displayName;
  return new OverriddenMember(element, className);
}


/**
 * Create a [RefactoringFeedback] corresponding the given [kind].
 */
RefactoringFeedback _refactoringFeedbackFromJson(JsonDecoder jsonDecoder,
    String jsonPath, Object json, Map feedbackJson) {
  String requestId;
  if (jsonDecoder is ResponseDecoder) {
    requestId = jsonDecoder.response.id;
  }
  RefactoringKind kind = REQUEST_ID_REFACTORING_KINDS.remove(requestId);
  if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
    return new ExtractLocalVariableFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_METHOD) {
    return new ExtractMethodFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.RENAME) {
    return new RenameFeedback.fromJson(jsonDecoder, jsonPath, json);
  }
  return null;
}


/**
 * Create a [RefactoringOptions] corresponding the given [kind].
 */
RefactoringOptions _refactoringOptionsFromJson(JsonDecoder jsonDecoder,
    String jsonPath, Object json, RefactoringKind kind) {
  if (kind == RefactoringKind.EXTRACT_LOCAL_VARIABLE) {
    return new ExtractLocalVariableOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.EXTRACT_METHOD) {
    return new ExtractMethodOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.INLINE_METHOD) {
    return new InlineMethodOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  if (kind == RefactoringKind.RENAME) {
    return new RenameOptions.fromJson(jsonDecoder, jsonPath, json);
  }
  return null;
}


/**
 * Create a SearchResultKind based on a value from the search engine.
 */
SearchResultKind _searchResultKindFromEngine(engine.MatchKind kind) {
  if (kind == engine.MatchKind.DECLARATION) {
    return SearchResultKind.DECLARATION;
  }
  if (kind == engine.MatchKind.READ) {
    return SearchResultKind.READ;
  }
  if (kind == engine.MatchKind.READ_WRITE) {
    return SearchResultKind.READ_WRITE;
  }
  if (kind == engine.MatchKind.WRITE) {
    return SearchResultKind.WRITE;
  }
  if (kind == engine.MatchKind.INVOCATION) {
    return SearchResultKind.INVOCATION;
  }
  if (kind == engine.MatchKind.REFERENCE) {
    return SearchResultKind.REFERENCE;
  }
  return SearchResultKind.UNKNOWN;
}


/**
 * Type of callbacks used to decode parts of JSON objects.  [jsonPath] is a
 * string describing the part of the JSON object being decoded, and [value] is
 * the part to decode.
 */
typedef Object JsonDecoderCallback(String jsonPath, Object value);

/**
 * Base class for decoding JSON objects.  The derived class must implement
 * error reporting logic.
 */
abstract class JsonDecoder {
  /**
   * Create an exception to throw if the JSON object at [jsonPath] fails to
   * match the API definition of [expected].
   */
  dynamic mismatch(String jsonPath, String expected);

  /**
   * Create an exception to throw if the JSON object at [jsonPath] is missing
   * the key [key].
   */
  dynamic missingKey(String jsonPath, String key);

  /**
   * Decode a JSON object that is expected to be a boolean.  The strings "true"
   * and "false" are also accepted.
   */
  bool _decodeBool(String jsonPath, Object json) {
    if (json is bool) {
      return json;
    } else if (json == 'true') {
      return true;
    } else if (json == 'false') {
      return false;
    }
    throw mismatch(jsonPath, 'bool');
  }

  /**
   * Decode a JSON object that is expected to be an integer.  A string
   * representation of an integer is also accepted.
   */
  int _decodeInt(String jsonPath, Object json) {
    if (json is int) {
      return json;
    } else if (json is String) {
      return int.parse(json, onError: (String value) {
        throw mismatch(jsonPath, 'int');
      });
    }
    throw mismatch(jsonPath, 'int');
  }

  /**
   * Decode a JSON object that is expected to be a List.  [decoder] is used to
   * decode the items in the list.
   */
  List _decodeList(String jsonPath, Object json,
      [JsonDecoderCallback decoder]) {
    if (json == null) {
      return [];
    } else if (json is List) {
      List result = [];
      for (int i = 0; i < json.length; i++) {
        result.add(decoder('$jsonPath[$i]', json[i]));
      }
      return result;
    } else {
      throw mismatch(jsonPath, 'List');
    }
  }

  /**
   * Decode a JSON object that is expected to be a Map.  [keyDecoder] is used
   * to decode the keys, and [valueDecoder] is used to decode the values.
   */
  Map _decodeMap(String jsonPath, Object json, {JsonDecoderCallback keyDecoder,
      JsonDecoderCallback valueDecoder}) {
    if (json == null) {
      return {};
    } else if (json is Map) {
      Map result = {};
      json.forEach((String key, value) {
        Object decodedKey;
        if (keyDecoder != null) {
          decodedKey = keyDecoder('$jsonPath.key', key);
        } else {
          decodedKey = key;
        }
        if (valueDecoder != null) {
          value = valueDecoder('$jsonPath[${JSON.encode(key)}]', value);
        }
        result[decodedKey] = value;
      });
      return result;
    } else {
      throw mismatch(jsonPath, 'Map');
    }
  }

  /**
   * Decode a JSON object that is expected to be a string.
   */
  String _decodeString(String jsonPath, Object json) {
    if (json is String) {
      return json;
    } else {
      throw mismatch(jsonPath, 'String');
    }
  }

  /**
   * Decode a JSON object that is expected to be one of several choices,
   * where the choices are disambiguated by the contents of the field [field].
   * [decoders] is a map from each possible string in the field to the decoder
   * that should be used to decode the JSON object.
   */
  Object _decodeUnion(String jsonPath, Map json, String field, Map<String,
      JsonDecoderCallback> decoders) {
    if (json is Map) {
      if (!json.containsKey(field)) {
        throw missingKey(jsonPath, field);
      }
      var disambiguatorPath = '$jsonPath[${JSON.encode(field)}]';
      String disambiguator = _decodeString(disambiguatorPath, json[field]);
      if (!decoders.containsKey(disambiguator)) {
        throw mismatch(disambiguatorPath, 'One of: ${decoders.keys.toList()}');
      }
      return decoders[disambiguator](jsonPath, json);
    } else {
      throw mismatch(jsonPath, 'Map');
    }
  }
}


/**
 * Instances of the class [Notification] represent a notification from the
 * server about an event that occurred.
 */
class Notification {
  /**
   * The name of the JSON attribute containing the name of the event that
   * triggered the notification.
   */
  static const String EVENT = 'event';

  /**
   * The name of the JSON attribute containing the result values.
   */
  static const String PARAMS = 'params';

  /**
   * The name of the event that triggered the notification.
   */
  final String event;

  /**
   * A table mapping the names of notification parameters to their values, or
   * null if there are no notification parameters.
   */
  Map<String, Object> _params;

  /**
   * Initialize a newly created [Notification] to have the given [event] name.
   * If [_params] is provided, it will be used as the params; otherwise no
   * params will be used.
   */
  Notification(this.event, [this._params]);

  /**
   * Initialize a newly created instance based upon the given JSON data
   */
  factory Notification.fromJson(Map<String, Object> json) {
    return new Notification(json[Notification.EVENT],
        json[Notification.PARAMS]);
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = {};
    jsonObject[EVENT] = event;
    if (_params != null) {
      jsonObject[PARAMS] = _params;
    }
    return jsonObject;
  }
}


/**
 * Instances of the class [Request] represent a request that was received.
 */
class Request {
  /**
   * The name of the JSON attribute containing the id of the request.
   */
  static const String ID = 'id';

  /**
   * The name of the JSON attribute containing the name of the request.
   */
  static const String METHOD = 'method';

  /**
   * The name of the JSON attribute containing the request parameters.
   */
  static const String PARAMS = 'params';

  /**
   * The unique identifier used to identify this request.
   */
  final String id;

  /**
   * The method being requested.
   */
  final String method;

  /**
   * A table mapping the names of request parameters to their values.
   */
  final Map<String, Object> _params;

  /**
   * Initialize a newly created [Request] to have the given [id] and [method]
   * name.  If [params] is supplied, it is used as the "params" map for the
   * request.  Otherwise an empty "params" map is allocated.
   */
  Request(this.id, this.method, [Map<String, Object> params])
      : _params = params != null ? params : new HashMap<String, Object>();

  /**
   * Return a request parsed from the given [data], or `null` if the [data] is
   * not a valid json representation of a request. The [data] is expected to
   * have the following format:
   *
   *   {
   *     'id': String,
   *     'method': methodName,
   *     'params': {
   *       paramter_name: value
   *     }
   *   }
   *
   * where the parameters are optional and can contain any number of name/value
   * pairs.
   */
  factory Request.fromString(String data) {
    try {
      var result = JSON.decode(data);
      if (result is! Map) {
        return null;
      }
      var id = result[Request.ID];
      var method = result[Request.METHOD];
      if (id is! String || method is! String) {
        return null;
      }
      var params = result[Request.PARAMS];
      if (params is Map || params == null) {
        return new Request(id, method, params);
      } else {
        return null;
      }
    } catch (exception) {
      return null;
    }
  }

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = new HashMap<String, Object>();
    jsonObject[ID] = id;
    jsonObject[METHOD] = method;
    if (_params.isNotEmpty) {
      jsonObject[PARAMS] = _params;
    }
    return jsonObject;
  }
}

/**
 * JsonDecoder for decoding requests.  Errors are reporting by throwing a
 * [RequestFailure].
 */
class RequestDecoder extends JsonDecoder {
  /**
   * The request being deserialized.
   */
  final Request _request;

  RequestDecoder(this._request);

  @override
  dynamic mismatch(String jsonPath, String expected) {
    return new RequestFailure(
        new Response.invalidParameter(_request, jsonPath, 'be $expected'));
  }

  @override
  dynamic missingKey(String jsonPath, String key) {
    return new RequestFailure(
        new Response.invalidParameter(
            _request,
            jsonPath,
            'contain key ${JSON.encode(key)}'));
  }
}


/**
 * Instances of the class [RequestFailure] represent an exception that occurred
 * during the handling of a request that requires that an error be returned to
 * the client.
 */
class RequestFailure implements Exception {
  /**
   * The response to be returned as a result of the failure.
   */
  final Response response;

  /**
   * Initialize a newly created exception to return the given reponse.
   */
  RequestFailure(this.response);
}

/**
 * Instances of the class [RequestHandler] implement a handler that can handle
 * requests and produce responses for them.
 */
abstract class RequestHandler {
  /**
   * Attempt to handle the given [request]. If the request is not recognized by
   * this handler, return `null` so that other handlers will be given a chance
   * to handle it. Otherwise, return the response that should be passed back to
   * the client.
   */
  Response handleRequest(Request request);
}

/**
 * Instances of the class [Response] represent a response to a request.
 */
class Response {
  /**
   * The [Response] instance that is returned when a real [Response] cannot
   * be provided at the moment.
   */
  static final Response DELAYED_RESPONSE = new Response('DELAYED_RESPONSE');

  /**
   * The name of the JSON attribute containing the id of the request for which
   * this is a response.
   */
  static const String ID = 'id';

  /**
   * The name of the JSON attribute containing the error message.
   */
  static const String ERROR = 'error';

  /**
   * The name of the JSON attribute containing the result values.
   */
  static const String RESULT = 'result';

  /**
   * The unique identifier used to identify the request that this response is
   * associated with.
   */
  final String id;

  /**
   * The error that was caused by attempting to handle the request, or `null` if
   * there was no error.
   */
  final RequestError error;

  /**
   * A table mapping the names of result fields to their values.  Should be
   * null if there is no result to send.
   */
  Map<String, Object> _result;

  /**
   * Initialize a newly created instance to represent a response to a request
   * with the given [id].  If [_result] is provided, it will be used as the
   * result; otherwise an empty result will be used.  If an [error] is provided
   * then the response will represent an error condition.
   */
  Response(this.id, {Map<String, Object> result, this.error})
      : _result = result;

  /**
   * Initialize a newly created instance based upon the given JSON data
   */
  factory Response.fromJson(Map<String, Object> json) {
    try {
      Object id = json[Response.ID];
      if (id is! String) {
        return null;
      }
      Object error = json[Response.ERROR];
      RequestError decodedError;
      if (error is Map) {
        decodedError = new RequestError.fromJson(new ResponseDecoder(null),
            '.error', error);
      }
      Object result = json[Response.RESULT];
      Map<String, Object> decodedResult;
      if (result is Map) {
        decodedResult = result;
      }
      return new Response(id, error: decodedError,
          result: decodedResult);
    } catch (exception) {
      return null;
    }
  }

  /**
   * Initialize a newly created instance to represent the
   * GET_ERRORS_INVALID_FILE error condition.
   */
  Response.getErrorsInvalidFile(Request request)
    : this(
        request.id,
        error: new RequestError(RequestErrorCode.GET_ERRORS_INVALID_FILE,
            'Error during `analysis.getErrors`: invalid file.'));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a [request] that had invalid parameter.  [path] is the path to the
   * invalid parameter, in Javascript notation (e.g. "foo.bar" means that the
   * parameter "foo" contained a key "bar" whose value was the wrong type).
   * [expectation] is a description of the type of data that was expected.
   */
  Response.invalidParameter(Request request, String path, String expectation)
      : this(request.id, error: new RequestError(RequestErrorCode.INVALID_PARAMETER,
          "Expected parameter $path to $expectation"));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a malformed request.
   */
  Response.invalidRequestFormat()
    : this('', error: new RequestError(RequestErrorCode.INVALID_REQUEST, 'Invalid request'));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a `analysis.setPriorityFiles` [request] that includes one or more files
   * that are not being analyzed.
   */
  Response.unanalyzedPriorityFiles(Request request, String fileNames)
    : this(request.id, error: new RequestError(RequestErrorCode.UNANALYZED_PRIORITY_FILES, "Unanalyzed files cannot be a priority: '$fileNames'"));

  /**
   * Initialize a newly created instance to represent an error condition caused
   * by a [request] that cannot be handled by any known handlers.
   */
  Response.unknownRequest(Request request)
    : this(request.id, error: new RequestError(RequestErrorCode.UNKNOWN_REQUEST, 'Unknown request'));

  Response.unsupportedFeature(String requestId, String message)
    : this(requestId, error: new RequestError(RequestErrorCode.UNSUPPORTED_FEATURE, message));

  /**
   * Return a table representing the structure of the Json object that will be
   * sent to the client to represent this response.
   */
  Map<String, Object> toJson() {
    Map<String, Object> jsonObject = new HashMap<String, Object>();
    jsonObject[ID] = id;
    if (error != null) {
      jsonObject[ERROR] = error.toJson();
    }
    if (_result != null) {
      jsonObject[RESULT] = _result;
    }
    return jsonObject;
  }
}

/**
 * JsonDecoder for decoding responses from the server.  This is intended to be
 * used only for testing.  Errors are reported using bare [Exception] objects.
 */
class ResponseDecoder extends JsonDecoder {
  final Response response;

  ResponseDecoder(this.response);

  @override
  dynamic mismatch(String jsonPath, String expected) {
    return new Exception('Expected $expected at $jsonPath');
  }

  @override
  dynamic missingKey(String jsonPath, String key) {
    return new Exception('Missing key $key at $jsonPath');
  }
}

/**
 * Jenkins hash function, optimized for small integers.  Borrowed from
 * sdk/lib/math/jenkins_smi_hash.dart.
 *
 * TODO(paulberry): Move to somewhere that can be shared with other code.
 */
class _JenkinsSmiHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  static int hash2(a, b) => finish(combine(combine(0, a), b));

  static int hash4(a, b, c, d) =>
      finish(combine(combine(combine(combine(0, a), b), c), d));
}
