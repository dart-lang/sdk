// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interacting with an analysis server that is running in a separate
 * process.
 */
import 'dart:async';
import 'dart:collection';
import 'dart:convert' hide JsonDecoder;
import 'dart:io';
import 'dart:math' as math;

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart' as path;

import 'logger.dart';

/**
 * Return the current time expressed as milliseconds since the epoch.
 */
int get currentTime => new DateTime.now().millisecondsSinceEpoch;

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
 * Data that has been collected about a request sent to the server.
 */
class RequestData {
  /**
   * The unique id of the request.
   */
  final String id;

  /**
   * The method that was requested.
   */
  final String method;

  /**
   * The request parameters.
   */
  final Map<String, dynamic> params;

  /**
   * The time at which the request was sent.
   */
  final int requestTime;

  /**
   * The time at which the response was received, or `null` if no response has
   * been received.
   */
  int responseTime = null;

  /**
   * The response that was received.
   */
  Response _response;

  /**
   * The completer that will be completed when a response is received.
   */
  Completer<Response> _responseCompleter;

  /**
   * Initialize a newly created set of request data.
   */
  RequestData(this.id, this.method, this.params, this.requestTime);

  /**
   * Return the number of milliseconds that elapsed between the request and the
   * response. This getter assumes that the response was received.
   */
  int get elapsedTime => responseTime - requestTime;

  /**
   * Return a future that will complete when a response is received.
   */
  Future<Response> get respondedTo {
    if (_response != null) {
      return new Future.value(_response);
    }
    if (_responseCompleter == null) {
      _responseCompleter = new Completer<Response>();
    }
    return _responseCompleter.future;
  }

  /**
   * Record that the given [response] was received.
   */
  void recordResponse(Response response) {
    if (_response != null) {
      stdout.writeln(
          'Received a second response to a $method request (id = $id)');
      return;
    }
    responseTime = currentTime;
    _response = response;
    if (_responseCompleter != null) {
      _responseCompleter.complete(response);
      _responseCompleter = null;
    }
  }
}

/**
 * A utility for starting and communicating with an analysis server that is
 * running in a separate process.
 */
class Server {
  /**
   * The label used for communications from the client.
   */
  static const String fromClient = 'client';

  /**
   * The label used for normal communications from the server.
   */
  static const String fromServer = 'server';

  /**
   * The label used for output written by the server on [fromStderr].
   */
  static const String fromStderr = 'stderr';

  /**
   * The logger to which the communications log should be written, or `null` if
   * the log should not be written.
   */
  final Logger logger;

  /**
   * The process in which the server is running, or `null` if the server hasn't
   * been started yet.
   */
  Process _process = null;

  /**
   * Number that should be used to compute the 'id' to send in the next command
   * sent to the server.
   */
  int _nextId = 0;

  /**
   * The analysis roots that are included.
   */
  List<String> _analysisRootIncludes = <String>[];

  /**
   * A list containing the paths of files for which an overlay has been created.
   */
  List<String> filesWithOverlays = <String>[];

  /**
   * The files that the server reported as being analyzed.
   */
  List<String> _analyzedFiles = <String>[];

  /**
   * A mapping from the absolute paths of files to the most recent set of errors
   * received for that file.
   */
  ErrorMap _errorMap = new ErrorMap();

  /**
   * The completer that will be completed the next time a 'server.status'
   * notification is received from the server with 'analyzing' set to false.
   */
  Completer<Null> _analysisFinishedCompleter;

  /**
   * The completer that will be completed the next time a 'server.connected'
   * notification is received from the server.
   */
  Completer<Null> _serverConnectedCompleter;

  /**
   * A table mapping the ids of requests that have been sent to the server to
   * data about those requests.
   */
  final Map<String, RequestData> _requestDataMap = <String, RequestData>{};

  /**
   * A table mapping the number of times a request whose 'event' is equal to the
   * key was sent to the server.
   */
  final Map<String, int> _notificationCountMap = <String, int>{};

  /**
   * Initialize a new analysis server. The analysis server is not running and
   * must be started using [start].
   *
   * If a [logger] is provided, the communications between the client (this
   * test) and the server will be written to it.
   */
  Server({this.logger = null});

  /**
   * Return a future that will complete when a 'server.status' notification is
   * received from the server with 'analyzing' set to false.
   *
   * The future will only be completed by 'server.status' notifications that are
   * received after this function call, so it is safe to use this getter
   * multiple times in one test; each time it is used it will wait afresh for
   * analysis to finish.
   */
  Future get analysisFinished {
    if (_analysisFinishedCompleter == null) {
      _analysisFinishedCompleter = new Completer();
    }
    return _analysisFinishedCompleter.future;
  }

  /**
   * Return a list of the paths of files that are currently being analyzed.
   */
  List<String> get analyzedDartFiles {
    bool isAnalyzed(String filePath) {
      // TODO(brianwilkerson) This should use the path package to determine
      // inclusion, and needs to take exclusions into account.
      for (String includedRoot in _analysisRootIncludes) {
        if (filePath.startsWith(includedRoot)) {
          return true;
        }
      }
      return false;
    }

    List<String> analyzedFiles = <String>[];
    for (String filePath in _analyzedFiles) {
      if (filePath.endsWith('.dart') && isAnalyzed(filePath)) {
        analyzedFiles.add(filePath);
      }
    }
    return analyzedFiles;
  }

  /**
   * Return a table mapping the absolute paths of files to the most recent set
   * of errors received for that file. The content of the map will not change
   * when new sets of errors are received.
   */
  ErrorMap get errorMap => new ErrorMap.from(_errorMap);

  /**
   * Compute a mapping from each of the file paths in the given list of
   * [filePaths] to the list of errors in the file at that path.
   */
  Future<ErrorMap> computeErrorMap(List<String> filePaths) async {
    ErrorMap errorMap = new ErrorMap();
    List<Future> futures = <Future>[];
    for (String filePath in filePaths) {
      RequestData requestData = sendAnalysisGetErrors(filePath);
      futures.add(requestData.respondedTo.then((Response response) {
        if (response.result != null) {
          AnalysisGetErrorsResult result =
              new AnalysisGetErrorsResult.fromResponse(response);
          errorMap[filePath] = result.errors;
        }
      }));
    }
    await Future.wait(futures);
    return errorMap;
  }

  /**
   * Print information about the communications with the server.
   */
  void printStatistics() {
    void writeSpaces(int count) {
      for (int i = 0; i < count; i++) {
        stdout.write(' ');
      }
    }

    //
    // Print information about the requests that were sent.
    //
    stdout.writeln('Request Counts');
    if (_requestDataMap.isEmpty) {
      stdout.writeln('  none');
    } else {
      Map<String, List<RequestData>> requestsByMethod =
          <String, List<RequestData>>{};
      _requestDataMap.values.forEach((RequestData requestData) {
        requestsByMethod
            .putIfAbsent(requestData.method, () => <RequestData>[])
            .add(requestData);
      });
      List<String> keys = requestsByMethod.keys.toList();
      keys.sort();
      int maxCount = requestsByMethod.values
          .fold(0, (int count, List<RequestData> list) => count + list.length);
      int countWidth = maxCount.toString().length;
      for (String key in keys) {
        List<RequestData> requests = requestsByMethod[key];
        int noResponseCount = 0;
        int responseCount = 0;
        int minTime = -1;
        int maxTime = -1;
        int totalTime = 0;
        requests.forEach((RequestData data) {
          if (data.responseTime == null) {
            noResponseCount++;
          } else {
            responseCount++;
            int time = data.elapsedTime;
            minTime = minTime < 0 ? time : math.min(minTime, time);
            maxTime = math.max(maxTime, time);
            totalTime += time;
          }
        });
        String count = requests.length.toString();
        writeSpaces(countWidth - count.length);
        stdout.write('  ');
        stdout.write(count);
        stdout.write(' - ');
        stdout.write(key);
        if (noResponseCount > 0) {
          stdout.write(', ');
          stdout.write(noResponseCount);
          stdout.write(' with no response');
        }
        if (maxTime >= 0) {
          stdout.write(' (');
          stdout.write(minTime);
          stdout.write(', ');
          stdout.write(totalTime / responseCount);
          stdout.write(', ');
          stdout.write(maxTime);
          stdout.write(')');
        }
        stdout.writeln();
      }
    }
    //
    // Print information about the notifications that were received.
    //
    stdout.writeln();
    stdout.writeln('Notification Counts');
    if (_notificationCountMap.isEmpty) {
      stdout.writeln('  none');
    } else {
      List<String> keys = _notificationCountMap.keys.toList();
      keys.sort();
      int maxCount = _notificationCountMap.values.fold(0, math.max);
      int countWidth = maxCount.toString().length;
      for (String key in keys) {
        String count = _notificationCountMap[key].toString();
        writeSpaces(countWidth - count.length);
        stdout.write('  ');
        stdout.write(count);
        stdout.write(' - ');
        stdout.writeln(key);
      }
    }
  }

  /**
   * Remove any existing overlays.
   */
  void removeAllOverlays() {
    Map<String, dynamic> files = new HashMap<String, dynamic>();
    for (String path in filesWithOverlays) {
      files[path] = new RemoveContentOverlay();
    }
    sendAnalysisUpdateContent(files);
  }

  RequestData sendAnalysisGetErrors(String file) {
    var params = new AnalysisGetErrorsParams(file).toJson();
    return _send("analysis.getErrors", params);
  }

  RequestData sendAnalysisGetHover(String file, int offset) {
    var params = new AnalysisGetHoverParams(file, offset).toJson();
    return _send("analysis.getHover", params);
  }

  RequestData sendAnalysisGetLibraryDependencies() {
    return _send("analysis.getLibraryDependencies", null);
  }

  RequestData sendAnalysisGetNavigation(String file, int offset, int length) {
    var params = new AnalysisGetNavigationParams(file, offset, length).toJson();
    return _send("analysis.getNavigation", params);
  }

  RequestData sendAnalysisGetReachableSources(String file) {
    var params = new AnalysisGetReachableSourcesParams(file).toJson();
    return _send("analysis.getReachableSources", params);
  }

  void sendAnalysisReanalyze({List<String> roots}) {
    var params = new AnalysisReanalyzeParams(roots: roots).toJson();
    _send("analysis.reanalyze", params);
  }

  void sendAnalysisSetAnalysisRoots(
      List<String> included, List<String> excluded,
      {Map<String, String> packageRoots}) {
    _analysisRootIncludes = included;
    var params = new AnalysisSetAnalysisRootsParams(included, excluded,
            packageRoots: packageRoots)
        .toJson();
    _send("analysis.setAnalysisRoots", params);
  }

  void sendAnalysisSetGeneralSubscriptions(
      List<GeneralAnalysisService> subscriptions) {
    var params =
        new AnalysisSetGeneralSubscriptionsParams(subscriptions).toJson();
    _send("analysis.setGeneralSubscriptions", params);
  }

  void sendAnalysisSetPriorityFiles(List<String> files) {
    var params = new AnalysisSetPriorityFilesParams(files).toJson();
    _send("analysis.setPriorityFiles", params);
  }

  void sendAnalysisSetSubscriptions(
      Map<AnalysisService, List<String>> subscriptions) {
    var params = new AnalysisSetSubscriptionsParams(subscriptions).toJson();
    _send("analysis.setSubscriptions", params);
  }

  void sendAnalysisUpdateContent(Map<String, dynamic> files) {
    files.forEach((String path, dynamic overlay) {
      if (overlay is AddContentOverlay) {
        filesWithOverlays.add(path);
      } else if (overlay is RemoveContentOverlay) {
        filesWithOverlays.remove(path);
      }
    });
    var params = new AnalysisUpdateContentParams(files).toJson();
    _send('analysis.updateContent', params);
  }

  void sendAnalysisUpdateOptions(AnalysisOptions options) {
    var params = new AnalysisUpdateOptionsParams(options).toJson();
    _send("analysis.updateOptions", params);
  }

  void sendCompletionGetSuggestions(String file, int offset) {
    var params = new CompletionGetSuggestionsParams(file, offset).toJson();
    _send("completion.getSuggestions", params);
  }

  RequestData sendDiagnosticGetDiagnostics() {
    return _send("diagnostic.getDiagnostics", null);
  }

  RequestData sendEditFormat(
      String file, int selectionOffset, int selectionLength,
      {int lineLength}) {
    var params = new EditFormatParams(file, selectionOffset, selectionLength,
            lineLength: lineLength)
        .toJson();
    return _send("edit.format", params);
  }

  RequestData sendEditGetAssists(String file, int offset, int length) {
    var params = new EditGetAssistsParams(file, offset, length).toJson();
    return _send("edit.getAssists", params);
  }

  RequestData sendEditGetAvailableRefactorings(
      String file, int offset, int length) {
    var params =
        new EditGetAvailableRefactoringsParams(file, offset, length).toJson();
    return _send("edit.getAvailableRefactorings", params);
  }

  RequestData sendEditGetFixes(String file, int offset) {
    var params = new EditGetFixesParams(file, offset).toJson();
    return _send("edit.getFixes", params);
  }

  RequestData sendEditGetRefactoring(RefactoringKind kind, String file,
      int offset, int length, bool validateOnly,
      {RefactoringOptions options}) {
    var params = new EditGetRefactoringParams(
            kind, file, offset, length, validateOnly,
            options: options)
        .toJson();
    return _send("edit.getRefactoring", params);
  }

  RequestData sendEditOrganizeDirectives(String file) {
    var params = new EditOrganizeDirectivesParams(file).toJson();
    return _send("edit.organizeDirectives", params);
  }

  RequestData sendEditSortMembers(String file) {
    var params = new EditSortMembersParams(file).toJson();
    return _send("edit.sortMembers", params);
  }

  RequestData sendExecutionCreateContext(String contextRoot) {
    var params = new ExecutionCreateContextParams(contextRoot).toJson();
    return _send("execution.createContext", params);
  }

  RequestData sendExecutionDeleteContext(String id) {
    var params = new ExecutionDeleteContextParams(id).toJson();
    return _send("execution.deleteContext", params);
  }

  RequestData sendExecutionMapUri(String id, {String file, String uri}) {
    var params = new ExecutionMapUriParams(id, file: file, uri: uri).toJson();
    return _send("execution.mapUri", params);
  }

  RequestData sendExecutionSetSubscriptions(
      List<ExecutionService> subscriptions) {
    var params = new ExecutionSetSubscriptionsParams(subscriptions).toJson();
    return _send("execution.setSubscriptions", params);
  }

  void sendSearchFindElementReferences(
      String file, int offset, bool includePotential) {
    var params =
        new SearchFindElementReferencesParams(file, offset, includePotential)
            .toJson();
    _send("search.findElementReferences", params);
  }

  void sendSearchFindMemberDeclarations(String name) {
    var params = new SearchFindMemberDeclarationsParams(name).toJson();
    _send("search.findMemberDeclarations", params);
  }

  void sendSearchFindMemberReferences(String name) {
    var params = new SearchFindMemberReferencesParams(name).toJson();
    _send("search.findMemberReferences", params);
  }

  void sendSearchFindTopLevelDeclarations(String pattern) {
    var params = new SearchFindTopLevelDeclarationsParams(pattern).toJson();
    _send("search.findTopLevelDeclarations", params);
  }

  void sendSearchGetTypeHierarchy(String file, int offset, {bool superOnly}) {
    var params =
        new SearchGetTypeHierarchyParams(file, offset, superOnly: superOnly)
            .toJson();
    _send("search.getTypeHierarchy", params);
  }

  RequestData sendServerGetVersion() {
    return _send("server.getVersion", null);
  }

  void sendServerSetSubscriptions(List<ServerService> subscriptions) {
    var params = new ServerSetSubscriptionsParams(subscriptions).toJson();
    _send("server.setSubscriptions", params);
  }

  void sendServerShutdown() {
    _send("server.shutdown", null);
  }

  /**
   * Start the server and listen for communications from it.
   *
   * If [checked] is `true`, the server's VM will be running in checked mode.
   *
   * If [diagnosticPort] is not `null`, the server will serve status pages to
   * the specified port.
   *
   * If [profileServer] is `true`, the server will be started with "--observe"
   * and "--pause-isolates-on-exit", allowing the observatory to be used.
   *
   * If [useAnalysisHighlight2] is `true`, the server will use the new highlight
   * APIs.
   */
  Future<Null> start(
      {bool checked: true,
      int diagnosticPort,
      bool profileServer: false,
      String sdkPath,
      int servicesPort,
      bool useAnalysisHighlight2: false}) async {
    if (_process != null) {
      throw new Exception('Process already started');
    }
    String dartBinary = Platform.executable;
    String rootDir =
        _findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
    String serverPath =
        path.normalize(path.join(rootDir, 'bin', 'server.dart'));
    List<String> arguments = [];
    //
    // Add VM arguments.
    //
    if (profileServer) {
      if (servicesPort == null) {
        arguments.add('--observe');
      } else {
        arguments.add('--observe=$servicesPort');
      }
      arguments.add('--pause-isolates-on-exit');
    } else if (servicesPort != null) {
      arguments.add('--enable-vm-service=$servicesPort');
    }
    if (Platform.packageRoot != null) {
      arguments.add('--package-root=${Platform.packageRoot}');
    }
    if (Platform.packageConfig != null) {
      arguments.add('--packages=${Platform.packageConfig}');
    }
    if (checked) {
      arguments.add('--checked');
    }
    //
    // Add the server executable.
    //
    arguments.add(serverPath);
    //
    // Add server arguments.
    //
    if (diagnosticPort != null) {
      arguments.add('--port');
      arguments.add(diagnosticPort.toString());
    }
    if (sdkPath != null) {
      arguments.add('--sdk=$sdkPath');
    }
    if (useAnalysisHighlight2) {
      arguments.add('--useAnalysisHighlight2');
    }
//    stdout.writeln('Launching $serverPath');
//    stdout.writeln('$dartBinary ${arguments.join(' ')}');
    _process = await Process.start(dartBinary, arguments);
    _process.exitCode.then((int code) {
      if (code != 0) {
        throw new StateError('Server terminated with exit code $code');
      }
    });
    _listenToOutput();
    _serverConnectedCompleter = new Completer();
    return _serverConnectedCompleter.future;
  }

  /**
   * Find the root directory of the analysis_server package by proceeding
   * upward to the 'test' dir, and then going up one more directory.
   */
  String _findRoot(String pathname) {
    while (!['benchmark', 'test'].contains(path.basename(pathname))) {
      String parent = path.dirname(pathname);
      if (parent.length >= pathname.length) {
        throw new Exception("Can't find root directory");
      }
      pathname = parent;
    }
    return path.dirname(pathname);
  }

  /**
   * Handle a [notification] received from the server.
   */
  void _handleNotification(Notification notification) {
    switch (notification.event) {
      case "server.connected":
//        new ServerConnectedParams.fromNotification(notification);
        _serverConnectedCompleter.complete(null);
        break;
      case "server.error":
//        new ServerErrorParams.fromNotification(notification);
        throw new StateError('Server error: ${notification.toJson()}');
        break;
      case "server.status":
        if (_analysisFinishedCompleter != null) {
          ServerStatusParams params =
              new ServerStatusParams.fromNotification(notification);
          var analysis = params.analysis;
          if (analysis != null && !analysis.isAnalyzing) {
            _analysisFinishedCompleter.complete(null);
          }
        }
        break;
      case "analysis.analyzedFiles":
        AnalysisAnalyzedFilesParams params =
            new AnalysisAnalyzedFilesParams.fromNotification(notification);
        _analyzedFiles = params.directories;
        break;
      case "analysis.errors":
        AnalysisErrorsParams params =
            new AnalysisErrorsParams.fromNotification(notification);
        _errorMap.pathMap[params.file] = params.errors;
        break;
      case "analysis.flushResults":
//        new AnalysisFlushResultsParams.fromNotification(notification);
        _errorMap.pathMap.clear();
        break;
      case "analysis.folding":
//        new AnalysisFoldingParams.fromNotification(notification);
        break;
      case "analysis.highlights":
//        new AnalysisHighlightsParams.fromNotification(notification);
        break;
      case "analysis.implemented":
//        new AnalysisImplementedParams.fromNotification(notification);
        break;
      case "analysis.invalidate":
//        new AnalysisInvalidateParams.fromNotification(notification);
        break;
      case "analysis.navigation":
//        new AnalysisNavigationParams.fromNotification(notification);
        break;
      case "analysis.occurrences":
//        new AnalysisOccurrencesParams.fromNotification(notification);
        break;
      case "analysis.outline":
//        new AnalysisOutlineParams.fromNotification(notification);
        break;
      case "analysis.overrides":
//        new AnalysisOverridesParams.fromNotification(notification);
        break;
      case "completion.results":
//        new CompletionResultsParams.fromNotification(notification);
        break;
      case "search.results":
//        new SearchResultsParams.fromNotification(notification);
        break;
      case "execution.launchData":
//        new ExecutionLaunchDataParams.fromNotification(notification);
        break;
      default:
        throw new StateError(
            'Unhandled notification: ${notification.toJson()}');
    }
  }

  /**
   * Handle a [response] received from the server.
   */
  void _handleResponse(Response response) {
    String id = response.id.toString();
    RequestData requestData = _requestDataMap[id];
    requestData.recordResponse(response);
//    switch (requestData.method) {
//      case "analysis.getErrors":
//        break;
//      case "analysis.getHover":
//        break;
//      case "analysis.getLibraryDependencies":
//        break;
//      case "analysis.getNavigation":
//        break;
//      case "analysis.getReachableSources":
//        break;
//      case "analysis.reanalyze":
//        break;
//      case "analysis.setAnalysisRoots":
//        break;
//      case "analysis.setGeneralSubscriptions":
//        break;
//      case "analysis.setPriorityFiles":
//        break;
//      case "analysis.setSubscriptions":
//        break;
//      case 'analysis.updateContent':
//        break;
//      case "analysis.updateOptions":
//        break;
//      case "completion.getSuggestions":
//        break;
//      case "diagnostic.getDiagnostics":
//        break;
//      case "edit.format":
//        break;
//      case "edit.getAssists":
//        break;
//      case "edit.getAvailableRefactorings":
//        break;
//      case "edit.getFixes":
//        break;
//      case "edit.getRefactoring":
//        break;
//      case "edit.organizeDirectives":
//        break;
//      case "edit.sortMembers":
//        break;
//      case "execution.createContext":
//        break;
//      case "execution.deleteContext":
//        break;
//      case "execution.mapUri":
//        break;
//      case "execution.setSubscriptions":
//        break;
//      case "search.findElementReferences":
//        break;
//      case "search.findMemberDeclarations":
//        break;
//      case "search.findMemberReferences":
//        break;
//      case "search.findTopLevelDeclarations":
//        break;
//      case "search.getTypeHierarchy":
//        break;
//      case "server.getVersion":
//        break;
//      case "server.setSubscriptions":
//        break;
//      case "server.shutdown":
//        break;
//      default:
//        throw new StateError('Unhandled response: ${response.toJson()}');
//    }
  }

  /**
   * Handle a [line] of input read from stderr.
   */
  void _handleStdErr(String line) {
    String trimmedLine = line.trim();
    logger?.log(fromStderr, '$trimmedLine');
    throw new StateError('Message received on stderr: "$trimmedLine"');
  }

  /**
   * Handle a [line] of input read from stdout.
   */
  void _handleStdOut(String line) {
    /**
     * Cast the given [value] to a Map, or throw an [ArgumentError] if the value
     * cannot be cast.
     */
    Map asMap(Object value) {
      if (value is Map) {
        return value;
      }
      throw new ArgumentError('Expected a Map, found a ${value.runtimeType}');
    }

    String trimmedLine = line.trim();
    if (trimmedLine.isEmpty ||
        trimmedLine.startsWith('Observatory listening on ')) {
      return;
    }
    logger?.log(fromServer, '$trimmedLine');
    Map message = asMap(JSON.decoder.convert(trimmedLine));
    if (message.containsKey('id')) {
      // The message is a response.
      Response response = new Response.fromJson(message);
      _handleResponse(response);
    } else {
      // The message is a notification.
      Notification notification = new Notification.fromJson(message);
      String event = notification.event;
      _notificationCountMap[event] = (_notificationCountMap[event] ?? 0) + 1;
      _handleNotification(notification);
    }
  }

  /**
   * Start listening to output from the server.
   */
  void _listenToOutput() {
    /**
     * Install the given [handler] to listen to transformed output from the
     * given [stream].
     */
    void installHandler(Stream<List<int>> stream, handler(String line)) {
      stream
          .transform((new Utf8Codec()).decoder)
          .transform(new LineSplitter())
          .listen(handler);
    }

    installHandler(_process.stdout, _handleStdOut);
    installHandler(_process.stderr, _handleStdErr);
  }

  /**
   * Send a command to the server. An 'id' will be automatically assigned.
   */
  RequestData _send(String method, Map<String, dynamic> params,
      {void onResponse(Response response)}) {
    String id = '${_nextId++}';
    RequestData requestData = new RequestData(id, method, params, currentTime);
    _requestDataMap[id] = requestData;
    Map<String, dynamic> command = <String, dynamic>{
      'id': id,
      'method': method
    };
    if (params != null) {
      command['params'] = params;
    }
    String line = JSON.encode(command);
    _process.stdin.add(UTF8.encoder.convert('$line\n'));
    logger?.log(fromClient, '$line');
    return requestData;
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
    _writeErrors('  Found ', actualErrors);
  }
}
