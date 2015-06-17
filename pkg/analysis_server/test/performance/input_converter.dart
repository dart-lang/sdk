// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library input.transformer;

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:logging/logging.dart';

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
   * A mapping from request/response id to expected error message.
   */
  final Map<String, dynamic> expectedErrors = new Map<String, dynamic>();

  /**
   * A mapping of source path prefixes
   * from location where instrumentation or log file was generated
   * to the target location of the source using during performance measurement.
   */
  final Map<String, String> srcPathMap;

  /**
   * A mapping of current overlay content
   * parallel to what is in the analysis server
   * so that we can update the file system.
   */
  final Map<String, String> overlays = new Map<String, String>();

  CommonInputConverter(this.srcPathMap);

  /**
   * Return an operation for the notification or `null` if none.
   */
  Operation convertNotification(Map<String, dynamic> json) {
    String event = json['event'];
    if (event == SERVER_STATUS) {
      // {"event":"server.status","params":{"analysis":{"isAnalyzing":false}}}
      Map<String, dynamic> params = json['params'];
      if (params != null) {
        Map<String, dynamic> analysis = params['analysis'];
        if (analysis != null && analysis['isAnalyzing'] == false) {
          return new WaitForAnalysisCompleteOperation();
        }
      }
    }
    if (event == SERVER_CONNECTED) {
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
    Map<String, dynamic> json = translateSrcPaths(origJson);
    String method = json['method'];
    if (method == ANALYSIS_GET_HOVER ||
        method == ANALYSIS_SET_ANALYSIS_ROOTS ||
        method == ANALYSIS_SET_PRIORITY_FILES ||
        method == ANALYSIS_SET_SUBSCRIPTIONS ||
        method == ANALYSIS_UPDATE_OPTIONS ||
        method == COMPLETION_GET_SUGGESTIONS ||
        method == EDIT_GET_ASSISTS ||
        method == EDIT_GET_AVAILABLE_REFACTORINGS ||
        method == EDIT_GET_FIXES ||
        method == EDIT_GET_REFACTORING ||
        method == EDIT_SORT_MEMBERS ||
        method == EXECUTION_CREATE_CONTEXT ||
        method == EXECUTION_DELETE_CONTEXT ||
        method == EXECUTION_MAP_URI ||
        method == EXECUTION_SET_SUBSCRIPTIONS ||
        method == SERVER_GET_VERSION ||
        method == SERVER_SET_SUBSCRIPTIONS) {
      return new RequestOperation(this, json);
    }
    // Sanity check operations that modify source
    // to ensure that the operation is on source in temp space
    if (method == ANALYSIS_UPDATE_CONTENT) {
      try {
        validateSrcPaths(json);
      } catch (e, s) {
        throw new AnalysisException('invalid src path in update request\n$json',
            new CaughtException(e, s));
      }
      // Track overlays in parallel with the analysis server
      // so that when an overlay is removed, the file can be updated on disk
      Request request = new Request.fromJson(json);
      var params = new AnalysisUpdateContentParams.fromRequest(request);
      params.files.forEach((String path, change) {
        if (change is AddContentOverlay) {
          String content = change.content;
          if (content == null) {
            throw 'expected new overlay content\n$json';
          }
          overlays[path] = content;
        } else if (change is ChangeContentOverlay) {
          String content = overlays[path];
          if (content == null) {
            throw 'expected cached overlay content\n$json';
          }
          overlays[path] = SourceEdit.applySequence(content, change.edits);
        } else if (change is RemoveContentOverlay) {
          String content = overlays.remove(path);
          if (content == null) {
            throw 'expected cached overlay content\n$json';
          }
          validateSrcPaths(path);
          new File(path).writeAsStringSync(content);
        } else {
          throw 'unknown overlay change $change\n$json';
        }
      });
      return new RequestOperation(this, json);
    }
    throw 'unknown request: $method\n  $json';
  }

  /**
   * Determine if the given request is expected to fail
   * and log an exception if not.
   */
  void recordErrorResponse(Map<String, dynamic> jsonRequest, exception) {
    var actualErr;
    if (exception is UnimplementedError) {
      if (exception.message.startsWith(ERROR_PREFIX)) {
        Map<String, dynamic> jsonResponse =
            JSON.decode(exception.message.substring(ERROR_PREFIX.length));
        actualErr = jsonResponse['error'];
      }
    }
    String id = jsonRequest['id'];
    if (id != null && actualErr != null) {
      var expectedErr = expectedErrors[id];
      if (expectedErr != null && actualErr == expectedErr) {
        return;
      }
//      if (jsonRequest['method'] == EDIT_SORT_MEMBERS) {
//        var params = jsonRequest['params'];
//        if (params is Map) {
//          var filePath = params['file'];
//          if (filePath is String) {
//            var content = overlays[filePath];
//            if (content is String) {
//              logger.log(Level.WARNING, 'sort failed: $filePath\n$content');
//            }
//          }
//        }
//      }
    }
    logger.log(
        Level.SEVERE, 'Send request failed for $id\n$exception\n$jsonRequest');
  }

  /**
   * Examine recorded responses and record any expected errors.
   */
  void recordResponse(Map<String, dynamic> json) {
    var error = json['error'];
    if (error != null) {
      String id = json['id'];
      print('expected error for $id is $error');
    }
  }

  /**
   * Recursively translate source paths in the specified JSON to reference
   * the temporary source used during performance measurement rather than
   * the original source when the instrumentation or log file was generated.
   */
  translateSrcPaths(json) {
    if (json is String) {
      String result = json;
      srcPathMap.forEach((String oldPrefix, String newPrefix) {
        if (json.startsWith(oldPrefix)) {
          result = '$newPrefix${json.substring(oldPrefix.length)}';
        }
      });
      return result;
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

  /**
   * Recursively verify that the source paths in the specified JSON
   * only reference the temporary source used during performance measurement.
   */
  void validateSrcPaths(json) {
    if (json is String) {
      if (json != null &&
          json.startsWith('/Users/') &&
          !srcPathMap.values.any((String prefix) => json.startsWith(prefix))) {
        throw 'found path referencing source outside temp space\n$json';
      }
    } else if (json is List) {
      for (int i = json.length - 1; i >= 0; --i) {
        validateSrcPaths(json[i]);
      }
    } else if (json is Map) {
      json.forEach((String key, value) {
        validateSrcPaths(key);
        validateSrcPaths(value);
      });
    }
  }
}

/**
 * [InputConverter] converts an input stream
 * into a series of operations to be sent to the analysis server.
 * The input stream can be either an instrumenation or log file.
 */
class InputConverter extends Converter<String, Operation> {
  final Logger logger = new Logger('InputConverter');

  /**
   * A mapping of source path prefixes
   * from location where instrumentation or log file was generated
   * to the target location of the source using during performance measurement.
   */
  final Map<String, String> srcPathMap;

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

  InputConverter(this.srcPathMap);

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
      converter = new InstrumentationInputConverter(srcPathMap);
    } else if (LogFileInputConverter.isFormat(line)) {
      converter = new LogFileInputConverter(srcPathMap);
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
