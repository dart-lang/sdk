// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'instrumentation_input_converter.dart';
import 'log_file_input_converter.dart';
import 'operation.dart';

/**
 * Common input converter superclass for sharing implementation.
 */
abstract class CommonInputConverter extends Converter<String, Operation> {
  static final ERROR_PREFIX = 'Server responded with an error: ';
  final Logger logger = new Logger('InstrumentationInputConverter');
  final Set<String> eventsSeen = new Set<String>();

  /**
   * A mapping from request/response id to request json
   * for those requests for which a response has not been processed.
   */
  final Map<String, dynamic> requestMap = {};

  /**
   * A mapping from request/response id to a completer
   * for those requests for which a response has not been processed.
   * The completer is called with the actual json response
   * when it becomes available.
   */
  final Map<String, Completer> responseCompleters = {};

  /**
   * A mapping from request/response id to the actual response result
   * for those responses that have not been processed.
   */
  final Map<String, dynamic> responseMap = {};

  /**
   * A mapping of current overlay content
   * parallel to what is in the analysis server
   * so that we can update the file system.
   */
  final Map<String, String> overlays = {};

  /**
   * The prefix used to determine if a request parameter is a file path.
   */
  final String rootPrefix = path.rootPrefix(path.current);

  /**
   * A mapping of source path prefixes
   * from location where instrumentation or log file was generated
   * to the target location of the source using during performance measurement.
   */
  final PathMap srcPathMap;

  /**
   * The root directory for all source being modified
   * during performance measurement.
   */
  final String tmpSrcDirPath;

  CommonInputConverter(this.tmpSrcDirPath, this.srcPathMap);

  Map<String, dynamic> asMap(dynamic value) => value as Map<String, dynamic>;

  /**
   * Return an operation for the notification or `null` if none.
   */
  Operation convertNotification(Map<String, dynamic> json) {
    String event = json['event'];
    if (event == SERVER_NOTIFICATION_STATUS) {
      // {"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}
      Map<String, dynamic> params = asMap(json['params']);
      if (params != null) {
        Map<String, dynamic> analysis = asMap(params['analysis']);
        if (analysis != null && analysis['isAnalyzing'] == false) {
          return new WaitForAnalysisCompleteOperation();
        }
      }
    }
    if (event == SERVER_NOTIFICATION_CONNECTED) {
      // {"event":"server.connected","params":{"version":"1.7.0"}}
      return new StartServerOperation();
    }
    if (eventsSeen.add(event)) {
      logger.log(Level.INFO, 'Ignored notification: $event\n  $json');
    }
    return null;
  }

  /**
   * Return an operation for the request or `null` if none.
   */
  Operation convertRequest(Map<String, dynamic> origJson) {
    Map<String, dynamic> json = asMap(translateSrcPaths(origJson));
    requestMap[json['id']] = json;
    String method = json['method'];
    // Sanity check operations that modify source
    // to ensure that the operation is on source in temp space
    if (method == ANALYSIS_REQUEST_UPDATE_CONTENT) {
      // Track overlays in parallel with the analysis server
      // so that when an overlay is removed, the file can be updated on disk
      Request request = new Request.fromJson(json);
      var params = new AnalysisUpdateContentParams.fromRequest(request);
      params.files.forEach((String filePath, change) {
        if (change is AddContentOverlay) {
          String content = change.content;
          if (content == null) {
            throw 'expected new overlay content\n$json';
          }
          overlays[filePath] = content;
        } else if (change is ChangeContentOverlay) {
          String content = overlays[filePath];
          if (content == null) {
            throw 'expected cached overlay content\n$json';
          }
          overlays[filePath] = SourceEdit.applySequence(content, change.edits);
        } else if (change is RemoveContentOverlay) {
          String content = overlays.remove(filePath);
          if (content == null) {
            throw 'expected cached overlay content\n$json';
          }
          if (!path.isWithin(tmpSrcDirPath, filePath)) {
            throw 'found path referencing source outside temp space\n$filePath\n$json';
          }
          new File(filePath).writeAsStringSync(content);
        } else {
          throw 'unknown overlay change $change\n$json';
        }
      });
      return new RequestOperation(this, json);
    }
    // Track performance for completion notifications
    if (method == COMPLETION_REQUEST_GET_SUGGESTIONS) {
      return new CompletionRequestOperation(this, json);
    }
    // TODO(danrubel) replace this with code
    // that just forwards the translated request
    if (method == ANALYSIS_REQUEST_GET_HOVER ||
        method == ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS ||
        method == ANALYSIS_REQUEST_SET_PRIORITY_FILES ||
        method == ANALYSIS_REQUEST_SET_SUBSCRIPTIONS ||
        method == ANALYSIS_REQUEST_UPDATE_OPTIONS ||
        method == EDIT_REQUEST_GET_ASSISTS ||
        method == EDIT_REQUEST_GET_AVAILABLE_REFACTORINGS ||
        method == EDIT_REQUEST_GET_FIXES ||
        method == EDIT_REQUEST_GET_REFACTORING ||
        method == EDIT_REQUEST_SORT_MEMBERS ||
        method == EXECUTION_REQUEST_CREATE_CONTEXT ||
        method == EXECUTION_REQUEST_DELETE_CONTEXT ||
        method == EXECUTION_REQUEST_MAP_URI ||
        method == EXECUTION_REQUEST_SET_SUBSCRIPTIONS ||
        method == SEARCH_REQUEST_FIND_ELEMENT_REFERENCES ||
        method == SEARCH_REQUEST_FIND_MEMBER_DECLARATIONS ||
        method == SERVER_REQUEST_GET_VERSION ||
        method == SERVER_REQUEST_SET_SUBSCRIPTIONS) {
      return new RequestOperation(this, json);
    }
    throw 'unknown request: $method\n  $json';
  }

  /**
   * Return an operation for the recorded/expected response.
   */
  Operation convertResponse(Map<String, dynamic> json) {
    return new ResponseOperation(this, asMap(requestMap.remove(json['id'])),
        asMap(translateSrcPaths(json)));
  }

  void logOverlayContent() {
    logger.log(Level.WARNING, '${overlays.length} overlays');
    List<String> allPaths = overlays.keys.toList()..sort();
    for (String filePath in allPaths) {
      logger.log(Level.WARNING, 'overlay $filePath\n${overlays[filePath]}');
    }
  }

  /**
   * Process an error response from the server by either
   * completing the associated completer in the [responseCompleters]
   * or stashing it in [responseMap] if no completer exists.
   */
  void processErrorResponse(String id, exception) {
    var result = exception;
    if (exception is UnimplementedError) {
      if (exception.message.startsWith(ERROR_PREFIX)) {
        result = JSON.decode(exception.message.substring(ERROR_PREFIX.length));
      }
    }
    processResponseResult(id, result);
  }

  /**
   * Process the expected response by completing the given completer
   * with the result if it has already been received,
   * or caching the completer to be completed when the server
   * returns the associated result.
   * Return a future that completes when the response is received
   * or `null` if the response has already been received
   * and the completer completed.
   */
  Future processExpectedResponse(String id, Completer completer) {
    if (responseMap.containsKey(id)) {
      logger.log(Level.INFO, 'processing cached response $id');
      completer.complete(responseMap.remove(id));
      return null;
    } else {
      logger.log(Level.INFO, 'waiting for response $id');
      responseCompleters[id] = completer;
      return completer.future;
    }
  }

  /**
   * Process a success response result from the server by either
   * completing the associated completer in the [responseCompleters]
   * or stashing it in [responseMap] if no completer exists.
   * The response result may be `null`.
   */
  void processResponseResult(String id, result) {
    Completer completer = responseCompleters[id];
    if (completer != null) {
      logger.log(Level.INFO, 'processing response $id');
      completer.complete(result);
    } else {
      logger.log(Level.INFO, 'caching response $id');
      responseMap[id] = result;
    }
  }

  /**
   * Recursively translate source paths in the specified JSON to reference
   * the temporary source used during performance measurement rather than
   * the original source when the instrumentation or log file was generated.
   */
  translateSrcPaths(json) {
    if (json is String) {
      return srcPathMap.translate(json);
    }
    if (json is List) {
      List result = [];
      for (int i = 0; i < json.length; ++i) {
        result.add(translateSrcPaths(json[i]));
      }
      return result;
    }
    if (json is Map) {
      Map<String, dynamic> result = new Map<String, dynamic>();
      json.forEach((String origKey, value) {
        result[translateSrcPaths(origKey)] = translateSrcPaths(value);
      });
      return result;
    }
    return json;
  }
}

/**
 * [InputConverter] converts an input stream
 * into a series of operations to be sent to the analysis server.
 * The input stream can be either an instrumentation or log file.
 */
class InputConverter extends Converter<String, Operation> {
  final Logger logger = new Logger('InputConverter');

  /**
   * A mapping of source path prefixes
   * from location where instrumentation or log file was generated
   * to the target location of the source using during performance measurement.
   */
  final PathMap srcPathMap;

  /**
   * The root directory for all source being modified
   * during performance measurement.
   */
  final String tmpSrcDirPath;

  /**
   * The number of lines read before the underlying converter was determined
   * or the end of file was reached.
   */
  int headerLineCount = 0;

  /**
   * The underlying converter used to translate lines into operations
   * or `null` if it has not yet been determined.
   */
  Converter<String, Operation> converter;

  /**
   * [active] is `true` if converting lines to operations
   * or `false` if an exception has occurred.
   */
  bool active = true;

  InputConverter(this.tmpSrcDirPath, this.srcPathMap);

  @override
  Operation convert(String line) {
    if (!active) {
      return null;
    }
    if (converter != null) {
      try {
        return converter.convert(line);
      } catch (e) {
        active = false;
        rethrow;
      }
    }
    if (headerLineCount == 20) {
      throw 'Failed to determine input file format';
    }
    if (InstrumentationInputConverter.isFormat(line)) {
      converter = new InstrumentationInputConverter(tmpSrcDirPath, srcPathMap);
    } else if (LogFileInputConverter.isFormat(line)) {
      converter = new LogFileInputConverter(tmpSrcDirPath, srcPathMap);
    }
    if (converter != null) {
      return converter.convert(line);
    }
    logger.log(Level.INFO, 'skipped input line: $line');
    return null;
  }

  @override
  _InputSink startChunkedConversion(outSink) {
    return new _InputSink(this, outSink);
  }
}

/**
 * A container of [PathMapEntry]s used to translate a source path in the log
 * before it is sent to the analysis server.
 */
class PathMap {
  final List<PathMapEntry> entries = [];

  void add(String oldSrcPrefix, String newSrcPrefix) {
    entries.add(new PathMapEntry(oldSrcPrefix, newSrcPrefix));
  }

  String translate(String original) {
    String result = original;
    for (PathMapEntry entry in entries) {
      result = entry.translate(result);
    }
    return result;
  }
}

/**
 * An entry in [PathMap] used to translate a source path in the log
 * before it is sent to the analysis server.
 */
class PathMapEntry {
  final String oldSrcPrefix;
  final String newSrcPrefix;

  PathMapEntry(this.oldSrcPrefix, this.newSrcPrefix);

  String translate(String original) {
    return original.startsWith(oldSrcPrefix)
        ? '$newSrcPrefix${original.substring(oldSrcPrefix.length)}'
        : original;
  }
}

class _InputSink extends ChunkedConversionSink<String> {
  final Converter<String, Operation> converter;
  final outSink;

  _InputSink(this.converter, this.outSink);

  @override
  void add(String line) {
    Operation op = converter.convert(line);
    if (op != null) {
      outSink.add(op);
    }
  }

  @override
  void close() {
    outSink.close();
  }
}
