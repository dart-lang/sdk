// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for interacting with an analysis server that is running in a
/// separate process.
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

/// Return the current time expressed as milliseconds since the epoch.
int get currentTime => DateTime.now().millisecondsSinceEpoch;

/// ???
class ErrorMap {
  /// A table mapping file paths to the errors associated with that file.
  final Map<String, List<AnalysisError>> pathMap =
      HashMap<String, List<AnalysisError>>();

  /// Initialize a newly created error map.
  ErrorMap();

  /// Initialize a newly created error map to contain the same mapping as the
  /// given [errorMap].
  ErrorMap.from(ErrorMap errorMap) {
    pathMap.addAll(errorMap.pathMap);
  }

  void operator []=(String filePath, List<AnalysisError> errors) {
    pathMap[filePath] = errors;
  }
}

/// Data that has been collected about a request sent to the server.
class RequestData {
  /// The unique id of the request.
  final String id;

  /// The method that was requested.
  final String method;

  /// The request parameters.
  final Map<String, dynamic> params;

  /// The time at which the request was sent.
  final int requestTime;

  /// The time at which the response was received, or `null` if no response has
  /// been received.
  int responseTime;

  /// The response that was received.
  Response _response;

  /// The completer that will be completed when a response is received.
  Completer<Response> _responseCompleter;

  /// Initialize a newly created set of request data.
  RequestData(this.id, this.method, this.params, this.requestTime);

  /// Return the number of milliseconds that elapsed between the request and the
  /// response. This getter assumes that the response was received.
  int get elapsedTime => responseTime - requestTime;

  /// Return a future that will complete when a response is received.
  Future<Response> get respondedTo {
    if (_response != null) {
      return Future.value(_response);
    }
    _responseCompleter ??= Completer<Response>();
    return _responseCompleter.future;
  }

  /// Record that the given [response] was received.
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

/// A utility for starting and communicating with an analysis server that is
/// running in a separate process.
class Server {
  /// The label used for communications from the client.
  static const String fromClient = 'client';

  /// The label used for normal communications from the server.
  static const String fromServer = 'server';

  /// The label used for output written by the server on [fromStderr].
  static const String fromStderr = 'stderr';

  /// The logger to which the communications log should be written, or `null` if
  /// the log should not be written.
  final Logger logger;

  /// The process in which the server is running, or `null` if the server hasn't
  /// been started yet.
  Process _process;

  /// Number that should be used to compute the 'id' to send in the next command
  /// sent to the server.
  int _nextId = 0;

  /// The analysis roots that are included.
  List<String> _analysisRootIncludes = <String>[];

  /// A list containing the paths of files for which an overlay has been
  /// created.
  List<String> filesWithOverlays = <String>[];

  /// The files that the server reported as being analyzed.
  List<String> _analyzedFiles = <String>[];

  /// A mapping from the absolute paths of files to the most recent set of
  /// errors received for that file.
  final ErrorMap _errorMap = ErrorMap();

  /// The completer that will be completed the next time a 'server.status'
  /// notification is received from the server with 'analyzing' set to false.
  Completer<void> _analysisFinishedCompleter;

  /// The completer that will be completed the next time a 'server.connected'
  /// notification is received from the server.
  Completer<void> _serverConnectedCompleter;

  /// A table mapping the ids of requests that have been sent to the server to
  /// data about those requests.
  final Map<String, RequestData> _requestDataMap = <String, RequestData>{};

  /// A table mapping the number of times a request whose 'event' is equal to
  /// the key was sent to the server.
  final Map<String, int> _notificationCountMap = <String, int>{};

  /// Initialize a new analysis server. The analysis server is not running and
  /// must be started using [start].
  ///
  /// If a [logger] is provided, the communications between the client (this
  /// test) and the server will be written to it.
  Server({this.logger});

  /// Return a future that will complete when a 'server.status' notification is
  /// received from the server with 'analyzing' set to false.
  ///
  /// The future will only be completed by 'server.status' notifications that
  /// are received after this function call, so it is safe to use this getter
  /// multiple times in one test; each time it is used it will wait afresh for
  /// analysis to finish.
  Future get analysisFinished {
    _analysisFinishedCompleter ??= Completer<void>();
    return _analysisFinishedCompleter.future;
  }

  /// Return a list of the paths of files that are currently being analyzed.
  List<String> get analyzedDartFiles {
    bool isAnalyzed(String filePath) {
      // TODO(brianwilkerson) This should use the path package to determine
      // inclusion, and needs to take exclusions into account.
      for (var includedRoot in _analysisRootIncludes) {
        if (filePath.startsWith(includedRoot)) {
          return true;
        }
      }
      return false;
    }

    var analyzedFiles = <String>[];
    for (var filePath in _analyzedFiles) {
      if (filePath.endsWith('.dart') && isAnalyzed(filePath)) {
        analyzedFiles.add(filePath);
      }
    }
    return analyzedFiles;
  }

  /// Return a table mapping the absolute paths of files to the most recent set
  /// of errors received for that file. The content of the map will not change
  /// when new sets of errors are received.
  ErrorMap get errorMap => ErrorMap.from(_errorMap);

  /// Compute a mapping from each of the file paths in the given list of
  /// [filePaths] to the list of errors in the file at that path.
  Future<ErrorMap> computeErrorMap(List<String> filePaths) async {
    var errorMap = ErrorMap();
    var futures = <Future>[];
    for (var filePath in filePaths) {
      var requestData = sendAnalysisGetErrors(filePath);
      futures.add(requestData.respondedTo.then((Response response) {
        if (response.result != null) {
          var result = AnalysisGetErrorsResult.fromResponse(response);
          errorMap[filePath] = result.errors;
        }
      }));
    }
    await Future.wait(futures);
    return errorMap;
  }

  /// Print information about the communications with the server.
  void printStatistics() {
    void writeSpaces(int count) {
      for (var i = 0; i < count; i++) {
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
      var requestsByMethod = <String, List<RequestData>>{};
      _requestDataMap.values.forEach((RequestData requestData) {
        requestsByMethod
            .putIfAbsent(requestData.method, () => <RequestData>[])
            .add(requestData);
      });
      var keys = requestsByMethod.keys.toList();
      keys.sort();
      var maxCount = requestsByMethod.values
          .fold(0, (int count, List<RequestData> list) => count + list.length);
      var countWidth = maxCount.toString().length;
      for (var key in keys) {
        var requests = requestsByMethod[key];
        var noResponseCount = 0;
        var responseCount = 0;
        var minTime = -1;
        var maxTime = -1;
        var totalTime = 0;
        requests.forEach((RequestData data) {
          if (data.responseTime == null) {
            noResponseCount++;
          } else {
            responseCount++;
            var time = data.elapsedTime;
            minTime = minTime < 0 ? time : math.min(minTime, time);
            maxTime = math.max(maxTime, time);
            totalTime += time;
          }
        });
        var count = requests.length.toString();
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
      var keys = _notificationCountMap.keys.toList();
      keys.sort();
      var maxCount = _notificationCountMap.values.fold(0, math.max);
      var countWidth = maxCount.toString().length;
      for (var key in keys) {
        var count = _notificationCountMap[key].toString();
        writeSpaces(countWidth - count.length);
        stdout.write('  ');
        stdout.write(count);
        stdout.write(' - ');
        stdout.writeln(key);
      }
    }
  }

  /// Remove any existing overlays.
  void removeAllOverlays() {
    Map<String, dynamic> files = HashMap<String, dynamic>();
    for (var path in filesWithOverlays) {
      files[path] = RemoveContentOverlay();
    }
    sendAnalysisUpdateContent(files);
  }

  RequestData sendAnalysisGetErrors(String file) {
    var params = AnalysisGetErrorsParams(file).toJson();
    return _send('analysis.getErrors', params);
  }

  RequestData sendAnalysisGetHover(String file, int offset) {
    var params = AnalysisGetHoverParams(file, offset).toJson();
    return _send('analysis.getHover', params);
  }

  RequestData sendAnalysisGetLibraryDependencies() {
    return _send('analysis.getLibraryDependencies', null);
  }

  RequestData sendAnalysisGetNavigation(String file, int offset, int length) {
    var params = AnalysisGetNavigationParams(file, offset, length).toJson();
    return _send('analysis.getNavigation', params);
  }

  RequestData sendAnalysisGetReachableSources(String file) {
    var params = AnalysisGetReachableSourcesParams(file).toJson();
    return _send('analysis.getReachableSources', params);
  }

  void sendAnalysisReanalyze() {
    var params = AnalysisReanalyzeParams().toJson();
    _send('analysis.reanalyze', params);
  }

  void sendAnalysisSetAnalysisRoots(
      List<String> included, List<String> excluded,
      {Map<String, String> packageRoots}) {
    _analysisRootIncludes = included;
    var params = AnalysisSetAnalysisRootsParams(included, excluded,
            packageRoots: packageRoots)
        .toJson();
    _send('analysis.setAnalysisRoots', params);
  }

  void sendAnalysisSetGeneralSubscriptions(
      List<GeneralAnalysisService> subscriptions) {
    var params = AnalysisSetGeneralSubscriptionsParams(subscriptions).toJson();
    _send('analysis.setGeneralSubscriptions', params);
  }

  void sendAnalysisSetPriorityFiles(List<String> files) {
    var params = AnalysisSetPriorityFilesParams(files).toJson();
    _send('analysis.setPriorityFiles', params);
  }

  void sendAnalysisSetSubscriptions(
      Map<AnalysisService, List<String>> subscriptions) {
    var params = AnalysisSetSubscriptionsParams(subscriptions).toJson();
    _send('analysis.setSubscriptions', params);
  }

  void sendAnalysisUpdateContent(Map<String, dynamic> files) {
    files.forEach((String path, dynamic overlay) {
      if (overlay is AddContentOverlay) {
        filesWithOverlays.add(path);
      } else if (overlay is RemoveContentOverlay) {
        filesWithOverlays.remove(path);
      }
    });
    var params = AnalysisUpdateContentParams(files).toJson();
    _send('analysis.updateContent', params);
  }

  void sendAnalysisUpdateOptions(AnalysisOptions options) {
    var params = AnalysisUpdateOptionsParams(options).toJson();
    _send('analysis.updateOptions', params);
  }

  void sendCompletionGetSuggestions(String file, int offset) {
    var params = CompletionGetSuggestionsParams(file, offset).toJson();
    _send('completion.getSuggestions', params);
  }

  RequestData sendDiagnosticGetDiagnostics() {
    return _send('diagnostic.getDiagnostics', null);
  }

  RequestData sendEditFormat(
      String file, int selectionOffset, int selectionLength,
      {int lineLength}) {
    var params = EditFormatParams(file, selectionOffset, selectionLength,
            lineLength: lineLength)
        .toJson();
    return _send('edit.format', params);
  }

  RequestData sendEditGetAssists(String file, int offset, int length) {
    var params = EditGetAssistsParams(file, offset, length).toJson();
    return _send('edit.getAssists', params);
  }

  RequestData sendEditGetAvailableRefactorings(
      String file, int offset, int length) {
    var params =
        EditGetAvailableRefactoringsParams(file, offset, length).toJson();
    return _send('edit.getAvailableRefactorings', params);
  }

  RequestData sendEditGetFixes(String file, int offset) {
    var params = EditGetFixesParams(file, offset).toJson();
    return _send('edit.getFixes', params);
  }

  RequestData sendEditGetRefactoring(RefactoringKind kind, String file,
      int offset, int length, bool validateOnly,
      {RefactoringOptions options}) {
    var params = EditGetRefactoringParams(
            kind, file, offset, length, validateOnly,
            options: options)
        .toJson();
    return _send('edit.getRefactoring', params);
  }

  RequestData sendEditOrganizeDirectives(String file) {
    var params = EditOrganizeDirectivesParams(file).toJson();
    return _send('edit.organizeDirectives', params);
  }

  RequestData sendEditSortMembers(String file) {
    var params = EditSortMembersParams(file).toJson();
    return _send('edit.sortMembers', params);
  }

  RequestData sendExecutionCreateContext(String contextRoot) {
    var params = ExecutionCreateContextParams(contextRoot).toJson();
    return _send('execution.createContext', params);
  }

  RequestData sendExecutionDeleteContext(String id) {
    var params = ExecutionDeleteContextParams(id).toJson();
    return _send('execution.deleteContext', params);
  }

  RequestData sendExecutionMapUri(String id, {String file, String uri}) {
    var params = ExecutionMapUriParams(id, file: file, uri: uri).toJson();
    return _send('execution.mapUri', params);
  }

  RequestData sendExecutionSetSubscriptions(
      List<ExecutionService> subscriptions) {
    var params = ExecutionSetSubscriptionsParams(subscriptions).toJson();
    return _send('execution.setSubscriptions', params);
  }

  void sendSearchFindElementReferences(
      String file, int offset, bool includePotential) {
    var params =
        SearchFindElementReferencesParams(file, offset, includePotential)
            .toJson();
    _send('search.findElementReferences', params);
  }

  void sendSearchFindMemberDeclarations(String name) {
    var params = SearchFindMemberDeclarationsParams(name).toJson();
    _send('search.findMemberDeclarations', params);
  }

  void sendSearchFindMemberReferences(String name) {
    var params = SearchFindMemberReferencesParams(name).toJson();
    _send('search.findMemberReferences', params);
  }

  void sendSearchFindTopLevelDeclarations(String pattern) {
    var params = SearchFindTopLevelDeclarationsParams(pattern).toJson();
    _send('search.findTopLevelDeclarations', params);
  }

  void sendSearchGetTypeHierarchy(String file, int offset, {bool superOnly}) {
    var params =
        SearchGetTypeHierarchyParams(file, offset, superOnly: superOnly)
            .toJson();
    _send('search.getTypeHierarchy', params);
  }

  RequestData sendServerGetVersion() {
    return _send('server.getVersion', null);
  }

  void sendServerSetSubscriptions(List<ServerService> subscriptions) {
    var params = ServerSetSubscriptionsParams(subscriptions).toJson();
    _send('server.setSubscriptions', params);
  }

  void sendServerShutdown() {
    _send('server.shutdown', null);
  }

  /// Start the server and listen for communications from it.
  ///
  /// If [checked] is `true`, the server's VM will be running in checked mode.
  ///
  /// If [diagnosticPort] is not `null`, the server will serve status pages to
  /// the specified port.
  ///
  /// If [profileServer] is `true`, the server will be started with "--observe"
  /// and "--pause-isolates-on-exit", allowing the observatory to be used.
  ///
  /// If [useAnalysisHighlight2] is `true`, the server will use the new
  /// highlight APIs.
  Future<void> start(
      {bool checked = true,
      int diagnosticPort,
      bool profileServer = false,
      String sdkPath,
      int servicesPort,
      bool useAnalysisHighlight2 = false}) async {
    if (_process != null) {
      throw Exception('Process already started');
    }
    var dartBinary = Platform.executable;
    var rootDir =
        _findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
    var serverPath = path.normalize(path.join(rootDir, 'bin', 'server.dart'));
    var arguments = <String>[];
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
        throw StateError('Server terminated with exit code $code');
      }
    });
    _listenToOutput();
    _serverConnectedCompleter = Completer<void>();
    return _serverConnectedCompleter.future;
  }

  /// Find the root directory of the analysis_server package by proceeding
  /// upward to the 'test' dir, and then going up one more directory.
  String _findRoot(String pathname) {
    while (!['benchmark', 'test'].contains(path.basename(pathname))) {
      var parent = path.dirname(pathname);
      if (parent.length >= pathname.length) {
        throw Exception("Can't find root directory");
      }
      pathname = parent;
    }
    return path.dirname(pathname);
  }

  /// Handle a [notification] received from the server.
  void _handleNotification(Notification notification) {
    switch (notification.event) {
      case 'server.connected':
//        new ServerConnectedParams.fromNotification(notification);
        _serverConnectedCompleter.complete(null);
        break;
      case 'server.error':
//        new ServerErrorParams.fromNotification(notification);
        throw StateError('Server error: ${notification.toJson()}');
        break;
      case 'server.status':
        if (_analysisFinishedCompleter != null) {
          var params = ServerStatusParams.fromNotification(notification);
          var analysis = params.analysis;
          if (analysis != null && !analysis.isAnalyzing) {
            _analysisFinishedCompleter.complete(null);
          }
        }
        break;
      case 'analysis.analyzedFiles':
        var params = AnalysisAnalyzedFilesParams.fromNotification(notification);
        _analyzedFiles = params.directories;
        break;
      case 'analysis.errors':
        var params = AnalysisErrorsParams.fromNotification(notification);
        _errorMap.pathMap[params.file] = params.errors;
        break;
      case 'analysis.flushResults':
//        new AnalysisFlushResultsParams.fromNotification(notification);
        _errorMap.pathMap.clear();
        break;
      case 'analysis.folding':
//        new AnalysisFoldingParams.fromNotification(notification);
        break;
      case 'analysis.highlights':
//        new AnalysisHighlightsParams.fromNotification(notification);
        break;
      case 'analysis.implemented':
//        new AnalysisImplementedParams.fromNotification(notification);
        break;
      case 'analysis.invalidate':
//        new AnalysisInvalidateParams.fromNotification(notification);
        break;
      case 'analysis.navigation':
//        new AnalysisNavigationParams.fromNotification(notification);
        break;
      case 'analysis.occurrences':
//        new AnalysisOccurrencesParams.fromNotification(notification);
        break;
      case 'analysis.outline':
//        new AnalysisOutlineParams.fromNotification(notification);
        break;
      case 'analysis.overrides':
//        new AnalysisOverridesParams.fromNotification(notification);
        break;
      case 'completion.results':
//        new CompletionResultsParams.fromNotification(notification);
        break;
      case 'search.results':
//        new SearchResultsParams.fromNotification(notification);
        break;
      case 'execution.launchData':
//        new ExecutionLaunchDataParams.fromNotification(notification);
        break;
      default:
        throw StateError('Unhandled notification: ${notification.toJson()}');
    }
  }

  /// Handle a [response] received from the server.
  void _handleResponse(Response response) {
    var id = response.id.toString();
    var requestData = _requestDataMap[id];
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

  /// Handle a [line] of input read from stderr.
  void _handleStdErr(String line) {
    var trimmedLine = line.trim();
    logger?.log(fromStderr, '$trimmedLine');
    throw StateError('Message received on stderr: "$trimmedLine"');
  }

  /// Handle a [line] of input read from stdout.
  void _handleStdOut(String line) {
    /// Cast the given [value] to a Map, or throw an [ArgumentError] if the
    /// value cannot be cast.
    Map asMap(Object value) {
      if (value is Map) {
        return value;
      }
      throw ArgumentError('Expected a Map, found a ${value.runtimeType}');
    }

    var trimmedLine = line.trim();
    if (trimmedLine.isEmpty ||
        trimmedLine.startsWith('Observatory listening on ')) {
      return;
    }
    logger?.log(fromServer, '$trimmedLine');
    var message = asMap(json.decoder.convert(trimmedLine));
    if (message.containsKey('id')) {
      // The message is a response.
      var response = Response.fromJson(message);
      _handleResponse(response);
    } else {
      // The message is a notification.
      var notification = Notification.fromJson(message);
      var event = notification.event;
      _notificationCountMap[event] = (_notificationCountMap[event] ?? 0) + 1;
      _handleNotification(notification);
    }
  }

  /// Start listening to output from the server.
  void _listenToOutput() {
    /// Install the given [handler] to listen to transformed output from the
    /// given [stream].
    void installHandler(
        Stream<List<int>> stream, void Function(String) handler) {
      stream
          .transform((Utf8Codec()).decoder)
          .transform(LineSplitter())
          .listen(handler);
    }

    installHandler(_process.stdout, _handleStdOut);
    installHandler(_process.stderr, _handleStdErr);
  }

  /// Send a command to the server. An 'id' will be automatically assigned.
  RequestData _send(String method, Map<String, dynamic> params) {
    var id = '${_nextId++}';
    var requestData = RequestData(id, method, params, currentTime);
    _requestDataMap[id] = requestData;
    var command = <String, dynamic>{'id': id, 'method': method};
    if (params != null) {
      command['params'] = params;
    }
    var line = json.encode(command);
    _process.stdin.add(utf8.encoder.convert('$line\n'));
    logger?.log(fromClient, '$line');
    return requestData;
  }
}
