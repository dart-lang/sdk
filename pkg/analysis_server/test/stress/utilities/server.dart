// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interacting with an analysis server running in a separate
 * process.
 */
library analysis_server.test.stress.utilities.server;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/plugin/protocol/protocol.dart';

import '../../integration/integration_test_methods.dart';
import '../../integration/integration_tests.dart' as base;

/**
 * ???
 */
class ErrorMap {
  /**
   * A table mapping file paths to the errors associated with that file.
   */
  final Map<String, List<AnalysisError>> pathMap =
      new HashMap<String, List<AnalysisError>>();

  /**
   * Initialize a newly created error map.
   */
  ErrorMap();

  /**
   * Initialize a newly created error map to contain the same mapping as the
   * given [errorMap].
   */
  ErrorMap.from(ErrorMap errorMap) {
    pathMap.addAll(errorMap.pathMap);
  }

  void operator []=(String filePath, List<AnalysisError> errors) {
    pathMap[filePath] = errors;
  }

  /**
   * Compare the this error map with the state captured in the given [errorMap].
   * Throw an exception if the two maps do not agree.
   */
  String expectErrorMap(ErrorMap errorMap) {
    StringBuffer buffer = new StringBuffer();
    _ErrorComparator comparator = new _ErrorComparator(buffer);
    comparator.compare(pathMap, errorMap.pathMap);
    if (buffer.length > 0) {
      return buffer.toString();
    }
    return null;
  }
}

/**
 * An interface for starting and communicating with an analysis server running
 * in a separate process.
 */
class Server extends base.Server with IntegrationTestMixin {
  /**
   * A list containing the paths of files for which an overlay has been created.
   */
  List<String> filesWithOverlays = <String>[];

  /**
   * A mapping from the absolute paths of files to the most recent set of errors
   * received for that file.
   */
  ErrorMap _errorMap = new ErrorMap();

  /**
   * Initialize a new analysis server. The analysis server is not running and
   * must be started using [start].
   */
  Server() {
    initializeInttestMixin();
    onAnalysisErrors.listen(_recordErrors);
  }

  /**
   * Return a list of the paths of files that are currently being analyzed.
   */
  List<String> get analyzedDartFiles {
    // TODO(brianwilkerson) Implement this.
    return <String>[];
  }

  /**
   * Return a table mapping the absolute paths of files to the most recent set
   * of errors received for that file. The content of the map will not change
   * when new sets of errors are received.
   */
  ErrorMap get errorMap => new ErrorMap.from(_errorMap);

  @override
  base.Server get server => this;

  /**
   * Compute a mapping from each of the file paths in the given list of
   * [filePaths] to the list of errors in the file at that path.
   */
  Future<ErrorMap> computeErrorMap(List<String> filePaths) async {
    ErrorMap errorMap = new ErrorMap();
    List<Future> futures = <Future>[];
    for (String filePath in filePaths) {
      futures.add(sendAnalysisGetErrors(filePath)
          .then((AnalysisGetErrorsResult result) {
        errorMap[filePath] = result.errors;
      }));
    }
    await Future.wait(futures);
    return errorMap;
  }

  /**
   * Remove any existing overlays.
   */
  Future<AnalysisUpdateContentResult> removeAllOverlays() {
    Map<String, dynamic> files = new HashMap<String, dynamic>();
    for (String path in filesWithOverlays) {
      files[path] = new RemoveContentOverlay();
    }
    return sendAnalysisUpdateContent(files);
  }

  @override
  Future<AnalysisUpdateContentResult> sendAnalysisUpdateContent(
      Map<String, dynamic> files) {
    files.forEach((String path, dynamic overlay) {
      if (overlay is AddContentOverlay) {
        filesWithOverlays.add(path);
      } else if (overlay is RemoveContentOverlay) {
        filesWithOverlays.remove(path);
      }
    });
    return super.sendAnalysisUpdateContent(files);
  }

  /**
   * Record the errors in the given [params].
   */
  void _recordErrors(AnalysisErrorsParams params) {
    _errorMap[params.file] = params.errors;
  }
}

/**
 * A utility class used to compare two sets of errors.
 */
class _ErrorComparator {
  /**
   * An empty list of analysis errors.
   */
  static final List<AnalysisError> NO_ERRORS = <AnalysisError>[];

  /**
   * The buffer to which an error description will be written if any of the
   * files have different errors than are expected.
   */
  final StringBuffer buffer;

  /**
   * Initialize a newly created comparator to write to the given [buffer].
   */
  _ErrorComparator(this.buffer);

  /**
   * Compare the [actualErrorMap] and the [expectedErrorMap], writing a
   * description to the [buffer] if they are not the same. The error maps are
   * expected to be maps from absolute file paths to the list of actual or
   * expected errors.
   */
  void compare(Map<String, List<AnalysisError>> actualErrorMap,
      Map<String, List<AnalysisError>> expectedErrorMap) {
    Set<String> allFiles = new HashSet();
    allFiles.addAll(actualErrorMap.keys);
    allFiles.addAll(expectedErrorMap.keys);
    List<String> sortedFiles = allFiles.toList()..sort();
    for (String filePath in sortedFiles) {
      List<AnalysisError> actualErrors = actualErrorMap[filePath];
      List<AnalysisError> expectedErrors = expectedErrorMap[filePath];
      _compareLists(
          filePath, actualErrors ?? NO_ERRORS, expectedErrors ?? NO_ERRORS);
    }
  }

  /**
   * Compare the [actualErrors] and [expectedErrors], writing a description to
   * the [buffer] if they are not the same.
   */
  void _compareLists(String filePath, List<AnalysisError> actualErrors,
      List<AnalysisError> expectedErrors) {
    List<AnalysisError> remainingExpected =
        new List<AnalysisError>.from(expectedErrors);
    for (AnalysisError actualError in actualErrors) {
      AnalysisError expectedError = _findError(remainingExpected, actualError);
      if (expectedError == null) {
        _writeReport(filePath, actualErrors, expectedErrors);
        return;
      }
      remainingExpected.remove(expectedError);
    }
    if (remainingExpected.isNotEmpty) {
      _writeReport(filePath, actualErrors, expectedErrors);
    }
  }

  /**
   * Return `true` if the [firstError] and the [secondError] are equivalent.
   */
  bool _equalErrors(AnalysisError firstError, AnalysisError secondError) =>
      firstError.severity == secondError.severity &&
      firstError.type == secondError.type &&
      _equalLocations(firstError.location, secondError.location) &&
      firstError.message == secondError.message;

  /**
   * Return `true` if the [firstLocation] and the [secondLocation] are
   * equivalent.
   */
  bool _equalLocations(Location firstLocation, Location secondLocation) =>
      firstLocation.file == secondLocation.file &&
      firstLocation.offset == secondLocation.offset &&
      firstLocation.length == secondLocation.length;

  /**
   * Search through the given list of [errors] for an error that is equal to the
   * [targetError]. If one is found, return it, otherwise return `null`.
   */
  AnalysisError _findError(
      List<AnalysisError> errors, AnalysisError targetError) {
    for (AnalysisError error in errors) {
      if (_equalErrors(error, targetError)) {
        return error;
      }
    }
    return null;
  }

  /**
   * Write the given list of [errors], preceded by a header beginning with the
   * given [prefix].
   */
  void _writeErrors(String prefix, List<AnalysisError> errors) {
    buffer.write(prefix);
    buffer.write(errors.length);
    buffer.write(' errors:');
    for (AnalysisError error in errors) {
      buffer.writeln();
      Location location = error.location;
      int offset = location.offset;
      buffer.write('    ');
      buffer.write(location.file);
      buffer.write(' (');
      buffer.write(offset);
      buffer.write('..');
      buffer.write(offset + location.length);
      buffer.write(') ');
      buffer.write(error.severity);
      buffer.write(', ');
      buffer.write(error.type);
      buffer.write(' : ');
      buffer.write(error.message);
    }
  }

  /**
   * Write a report of the differences between the [actualErrors] and the
   * [expectedErrors]. The errors are reported as being from the file at the
   * given [filePath].
   */
  void _writeReport(String filePath, List<AnalysisError> actualErrors,
      List<AnalysisError> expectedErrors) {
    if (buffer.length > 0) {
      buffer.writeln();
      buffer.writeln();
    }
    buffer.writeln(filePath);
    _writeErrors('  Expected ', expectedErrors);
    buffer.writeln();
    _writeErrors('  Found ', expectedErrors);
  }
}
