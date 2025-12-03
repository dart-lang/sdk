// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/pub/pub_command.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../test/constants.dart';
import '../../test/support/configuration_files.dart';
import '../../test/support/sdk_paths.dart';
import 'integration_test_methods.dart';
import 'protocol_matchers.dart';

const Matcher isBool = TypeMatcher<bool>();

const Matcher isDouble = TypeMatcher<double>();

const Matcher isInt = TypeMatcher<int>();

const Matcher isNotification = MatchesJsonObject(
  'notification',
  {'event': isString},
  optionalFields: {'params': isMap},
);

const Matcher isObject = TypeMatcher<Object>();

const Matcher isString = TypeMatcher<String>();

final Matcher isResponse = MatchesJsonObject(
  'response',
  {'id': isString},
  optionalFields: {'result': anything, 'error': isRequestError},
);

Matcher isListOf(Matcher elementMatcher) => _ListOf(elementMatcher);

Matcher isMapOf(Matcher keyMatcher, Matcher valueMatcher) =>
    _MapOf(keyMatcher, valueMatcher);

Matcher isOneOf(List<Matcher> choiceMatchers) => _OneOf(choiceMatchers);

/// Assert that [actual] matches [matcher].
void outOfTestExpect(
  Object? actual,
  Matcher matcher, {
  String? reason,
  skip,
  bool verbose = false,
}) {
  var matchState = {};
  try {
    if (matcher.matches(actual, matchState)) return;
  } catch (e, trace) {
    reason ??= '${(e is String) ? e : e.toString()} at $trace';
  }
  fail(_defaultFailFormatter(actual, matcher, reason, matchState, verbose));
}

String _defaultFailFormatter(
  dynamic actual,
  Matcher matcher,
  String? reason,
  Map<Object?, Object?> matchState,
  bool verbose,
) {
  var description = StringDescription();
  description.add('Expected: ').addDescriptionOf(matcher).add('\n');
  description.add('  Actual: ').addDescriptionOf(actual).add('\n');

  var mismatchDescription = StringDescription();
  matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);

  if (mismatchDescription.length > 0) {
    description.add('   Which: $mismatchDescription\n');
  }
  if (reason != null) description.add(reason).add('\n');
  return description.toString();
}

/// Type of closures used by LazyMatcher.
typedef MatcherCreator = Matcher Function();

/// Type of closures used by MatchesJsonObject to record field mismatches.
typedef MismatchDescriber =
    Description Function(Description mismatchDescription);

/// Type of callbacks used to process notifications.
typedef NotificationProcessor =
    void Function(String event, Map<Object?, Object?> params);

/// Type of callbacks used to process reverse-requests.
typedef ReverseRequestProcessor = void Function(Request request);

/// Base class for analysis server integration tests.
abstract class AbstractAnalysisServerIntegrationTest extends IntegrationTest
    with MockPackagesMixin, ConfigurationFilesMixin {
  /// Amount of time to give the server to respond to a shutdown request before
  /// forcibly terminating it.
  static const Duration shutdownTimeout = Duration(seconds: 60);

  /// Connection to the analysis server.
  @override
  final Server server = Server();

  /// Temporary folders created by the test that should be deleted (recursively)
  /// during [tearDown].
  final List<String> _temporaryFolders = [];

  /// Temporary directory in which source files can be stored.
  late Directory sourceDirectory;

  /// Temporary directory in which additional packages can be stored.
  late Directory packagesDirectory;

  @override
  final resourceProvider = PhysicalResourceProvider.INSTANCE;

  /// Map from file path to the list of analysis errors which have most recently
  /// been received for the file.
  ///
  /// If the server requests a files errors are flushed, they will be removed
  /// from the map.
  Map<String, List<AnalysisError>> currentAnalysisErrors =
      HashMap<String, List<AnalysisError>>();

  /// The last list of analyzed files received.
  late List<String> lastAnalyzedFiles;

  /// True if the teardown process should skip sending a "server.shutdown"
  /// request (e.g. because the server is known to have already shutdown).
  bool skipShutdown = false;

  /// True if we are currently subscribed to [SERVER_NOTIFICATION_STATUS]
  /// updates.
  bool _subscribedToServerStatus = false;

  String dartSdkPath = path.dirname(path.dirname(Platform.resolvedExecutable));

  StreamController<Request> serverToClientRequestsController =
      StreamController<Request>.broadcast();

  /// Return a future which will complete when a 'server.status' notification is
  /// received from the server with 'analyzing' set to false.
  ///
  /// The future will only be completed by 'server.status' notifications that
  /// are received after this function call.  So it is safe to use this getter
  /// multiple times in one test; each time it is used it will wait afresh for
  /// analysis to finish.
  Future<ServerStatusParams> get analysisFinished {
    var completer = Completer<ServerStatusParams>();
    late StreamSubscription<ServerStatusParams> subscription;
    // This will only work if the caller has already subscribed to
    // SERVER_STATUS (e.g. using sendServerSetSubscriptions(['STATUS']))
    outOfTestExpect(_subscribedToServerStatus, isTrue);
    subscription = onServerStatus.listen((ServerStatusParams params) {
      var analysisStatus = params.analysis;
      if (analysisStatus != null && !analysisStatus.isAnalyzing) {
        completer.complete(params);
        subscription.cancel();
      }
    });
    return completer.future;
  }

  /// The line terminator being used for test files and to be expected in edits.
  String get eol => testEol;

  @override
  String get packagesRootPath => packagesDirectory.path;

  Stream<Request> get serverToClientRequests =>
      serverToClientRequestsController.stream;

  @override
  String get testPackageRootPath => sourceDirectory.path;

  /// Print out any messages exchanged with the server.  If some messages have
  /// already been exchanged with the server, they are printed out immediately.
  void debugStdio() {
    server.debugStdio();
  }

  /// Deletes the folder at [pathname], recursively deleting all children.
  void deleteFolder(String pathname) {
    Directory(pathname).deleteSync(recursive: true);
  }

  void dispatchReverseRequest(Request request) {
    serverToClientRequestsController.add(request);
  }

  /// If there was a set of errors (might be empty) received for the file
  /// with the given [path], return it. If no errors have been received (or they
  /// have since been flushed) - fail.
  List<AnalysisError> existingErrorsForFile(String path) {
    var errors = currentAnalysisErrors[path];
    if (errors == null) {
      fail('Expected errors for: $path');
    }
    return errors;
  }

  List<AnalysisError>? getErrors(String pathname) =>
      currentAnalysisErrors[pathname];

  /// Read a source file with the given absolute [pathname].
  String readFile(String pathname) => File(pathname).readAsStringSync();

  @override
  Future<void> sendServerSetSubscriptions(List<ServerService> subscriptions) {
    _subscribedToServerStatus = subscriptions.contains(ServerService.STATUS);
    return super.sendServerSetSubscriptions(subscriptions);
  }

  /// The server is automatically started before every test, and a temporary
  /// [sourceDirectory] is created.
  Future<void> setUp() async {
    var pathContext = resourceProvider.pathContext;
    var testTemporaryDirectory = Directory(
      Directory.systemTemp
          .createTempSync('analysisServer_test_integration_project')
          .resolveSymbolicLinksSync(),
    );
    var tempDirectoryPath = testTemporaryDirectory.path;
    _temporaryFolders.add(tempDirectoryPath);
    sourceDirectory = Directory(pathContext.join(tempDirectoryPath, 'app'))
      ..createSync();
    packagesDirectory = Directory(
      pathContext.join(tempDirectoryPath, 'packages'),
    )..createSync();
    writeTestPackageConfig();

    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: ['macros']),
    );

    onAnalysisErrors.listen((AnalysisErrorsParams params) {
      currentAnalysisErrors[params.file] = params.errors;
    });
    onAnalysisFlushResults.listen((AnalysisFlushResultsParams params) {
      for (var file in params.files) {
        currentAnalysisErrors.remove(file);
      }
    });
    onAnalysisAnalyzedFiles.listen((AnalysisAnalyzedFilesParams params) {
      lastAnalyzedFiles = params.directories;
    });
    var serverConnected = Completer();
    onServerConnected.listen((_) {
      outOfTestExpect(serverConnected.isCompleted, isFalse);
      serverConnected.complete();
    });
    onServerError.listen((ServerErrorParams params) {
      // A server error should never happen during an integration test.
      fail('${params.message}\n${params.stackTrace}');
    });
    await startServer();
    server.listenToOutput(dispatchNotification, dispatchReverseRequest);
    unawaited(
      server.exitCode.then((_) {
        skipShutdown = true;
      }),
    );
    return serverConnected.future;
  }

  /// If [skipShutdown] is not set, shut down the server.
  Future<void> shutdownIfNeeded() {
    if (skipShutdown) {
      return Future.value();
    }
    // Give the server a short time to comply with the shutdown request; if it
    // doesn't exit, then forcibly terminate it.
    sendServerShutdown();
    return server.exitCode.timeout(
      shutdownTimeout,
      onTimeout: () {
        // The integer value of the exit code isn't used, but we have to return
        // an integer to keep the typing correct.
        return server.kill('server failed to exit').then((_) => -1);
      },
    );
  }

  /// Convert the given [relativePath] to an absolute path, by interpreting it
  /// relative to [sourceDirectory].  On Windows any forward slashes in
  /// [relativePath] are converted to backslashes.
  String sourcePath(String relativePath) {
    return path.join(
      sourceDirectory.path,
      relativePath.replaceAll('/', path.separator),
    );
  }

  /// Send the server an 'analysis.setAnalysisRoots' command directing it to
  /// analyze [sourceDirectory].  If [subscribeStatus] is true (the default),
  /// then also enable [SERVER_NOTIFICATION_STATUS] notifications so that
  /// [analysisFinished] can be used.
  Future<void> standardAnalysisSetup({bool subscribeStatus = true}) {
    var futures = <Future<void>>[];
    if (subscribeStatus) {
      futures.add(sendServerSetSubscriptions([ServerService.STATUS]));
    }
    futures.add(sendAnalysisSetAnalysisRoots([sourceDirectory.path], []));
    return Future.wait(futures);
  }

  /// Start [server].
  Future<void> startServer({int? diagnosticPort, int? servicePort}) {
    return server.start(
      dartSdkPath: dartSdkPath,
      diagnosticPort: diagnosticPort,
      servicePort: servicePort,
    );
  }

  /// After every test, the server is stopped and [sourceDirectory] and
  /// [packagesDirectory] are deleted.
  @mustCallSuper
  Future<void> tearDown() {
    return shutdownIfNeeded().then((_) {
      for (var temporaryFolder in _temporaryFolders) {
        deleteFolder(temporaryFolder);
      }
    });
  }

  /// Returns the latest set of errors for the file.
  ///
  /// If there are no errors received from the server yet, waits for them.
  /// Removes the set from the storage, so will wait again next time.
  Future<List<AnalysisError>> waitForFileErrors(String path) async {
    while (true) {
      var result = currentAnalysisErrors.remove(path);
      if (result != null) {
        return result;
      }
      await pumpEventQueue();
    }
  }

  /// Write a source file with the given absolute [pathname] and [contents].
  ///
  /// If the file didn't previously exist, it is created.  If it did, it is
  /// overwritten.
  ///
  /// Parent directories are created as necessary.
  ///
  /// Return a normalized path to the file (with symbolic links resolved).
  String writeFile(String pathname, String contents) {
    Directory(path.dirname(pathname)).createSync(recursive: true);
    var file = File(pathname);
    file.writeAsStringSync(contents);
    return file.resolveSymbolicLinksSync();
  }

  void writeTestPackageAnalysisOptionsFile(String content) {
    String filePath = path.join(
      testPackageRootPath,
      file_paths.analysisOptionsYaml,
    );
    writeFile(filePath, content);
  }
}

/// Wrapper class for Matcher which doesn't create the underlying Matcher object
/// until it is needed.  This is necessary in order to create matchers that can
/// refer to themselves (so that recursive data structures can be represented).
class LazyMatcher implements Matcher {
  /// Callback that will be used to create the matcher the first time it is
  /// needed.
  final MatcherCreator _creator;

  /// The matcher returned by [_creator], if it has already been called.
  /// Otherwise null.
  Matcher? _wrappedMatcher;

  LazyMatcher(this._creator);

  /// Create the wrapped matcher object, if it hasn't been created already.
  Matcher get _matcher {
    return _wrappedMatcher ??= _creator();
  }

  @override
  Description describe(Description description) {
    return _matcher.describe(description);
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    return _matcher.describeMismatch(
      item,
      mismatchDescription,
      matchState,
      verbose,
    );
  }

  @override
  bool matches(dynamic item, Map<Object?, Object?> matchState) {
    return _matcher.matches(item, matchState);
  }
}

/// Matcher that matches a String drawn from a limited set.
class MatchesEnum extends Matcher {
  /// Short description of the expected type.
  final String description;

  /// The set of enum values that are allowed.
  final List<String> allowedValues;

  const MatchesEnum(this.description, this.allowedValues);

  @override
  Description describe(Description description) =>
      description.add(this.description);

  @override
  bool matches(item, Map<Object?, Object?> matchState) {
    return allowedValues.contains(item);
  }
}

/// Matcher that matches a JSON object, with a given set of required and
/// optional fields, and their associated types (expressed as [Matcher]s).
class MatchesJsonObject extends _RecursiveMatcher {
  /// Short description of the expected type.
  final String description;

  /// Fields that are required to be in the JSON object, and [Matcher]s
  /// describing their expected types.
  final Map<String, Matcher>? requiredFields;

  /// Fields that are optional in the JSON object, and [Matcher]s describing
  /// their expected types.
  final Map<String, Matcher>? optionalFields;

  const MatchesJsonObject(
    this.description,
    this.requiredFields, {
    this.optionalFields,
  });

  @override
  Description describe(Description description) =>
      description.add(this.description);

  @override
  void populateMismatches(Object? item, List<MismatchDescriber> mismatches) {
    if (item is! Map<String, Object?>) {
      mismatches.add(simpleDescription('is not a map'));
      return;
    }
    var requiredFields = this.requiredFields;
    var optionalFields = this.optionalFields;
    if (requiredFields != null) {
      requiredFields.forEach((String key, Matcher valueMatcher) {
        if (!item.containsKey(key)) {
          mismatches.add(
            (Description mismatchDescription) => mismatchDescription
                .add('is missing field ')
                .addDescriptionOf(key)
                .add(' (')
                .addDescriptionOf(valueMatcher)
                .add(')'),
          );
        } else {
          _checkField(key, item[key], valueMatcher, mismatches);
        }
      });
    }
    item.forEach((key, value) {
      if (requiredFields != null && requiredFields.containsKey(key)) {
        // Already checked this field
        return;
      }
      if (optionalFields != null) {
        var optionalValue = optionalFields[key];
        if (optionalValue != null) {
          _checkField(key, value, optionalValue, mismatches);
          return;
        }
      }
      mismatches.add(
        (Description mismatchDescription) => mismatchDescription
            .add('has unexpected field ')
            .addDescriptionOf(key),
      );
    });
  }

  /// Check the type of a field called [key], having value [value], using
  /// [valueMatcher].  If it doesn't match, record a closure in [mismatches]
  /// which can describe the mismatch.
  void _checkField(
    String key,
    value,
    Matcher valueMatcher,
    List<MismatchDescriber> mismatches,
  ) {
    checkSubstructure(
      value,
      valueMatcher,
      mismatches,
      (Description description) =>
          description.add('field ').addDescriptionOf(key),
    );
  }
}

/// Instances of the class [Server] manage a connection to a server process, and
/// facilitate communication to and from the server.
class Server {
  /// Server process object, or null if server hasn't been started yet.
  late final Process _process;

  /// Commands that have been sent to the server but not yet acknowledged, and
  /// the [Completer] objects which should be completed when acknowledgement is
  /// received.
  final Map<String, Completer<Map<String, Object?>?>> _pendingCommands = {};

  /// Number which should be used to compute the 'id' to send in the next
  /// command sent to the server.
  int _nextId = 0;

  /// Messages which have been exchanged with the server; we buffer these
  /// up until the test finishes, so that they can be examined in the debugger
  /// or printed out in response to a call to [debugStdio].
  final List<String> _recordedStdio = <String>[];

  /// True if we are currently printing out messages exchanged with the server.
  bool _debuggingStdio = debugPrintCommunication;

  /// True if we've received bad data from the server, and we are aborting the
  /// test.
  bool _receivedBadDataFromServer = false;

  /// Stopwatch that we use to generate timing information for debug output.
  final Stopwatch _time = Stopwatch();

  /// The [currentElapseTime] at which the last communication was received from
  /// the server or `null` if no communication has been received.
  double? lastCommunicationTime;

  /// The current elapse time (seconds) since the server was started.
  double get currentElapseTime => _time.elapsedTicks / _time.frequency;

  /// Future that completes when the server process exits.
  Future<int> get exitCode => _process.exitCode;

  /// Print out any messages exchanged with the server.  If some messages have
  /// already been exchanged with the server, they are printed out immediately.
  void debugStdio() {
    if (_debuggingStdio) {
      return;
    }
    _debuggingStdio = true;
    for (var line in _recordedStdio) {
      print(line);
    }
  }

  /// Return a future that will complete when all commands that have been sent
  /// to the server so far have been flushed to the OS buffer.
  Future<void> flushCommands() {
    return _process.stdin.flush();
  }

  /// Stop the server.
  Future<int> kill(String reason) {
    debugStdio();
    _recordStdio('FORCIBLY TERMINATING PROCESS: $reason');
    _process.kill();
    return _process.exitCode;
  }

  /// Start listening to output from the server, and deliver notifications to
  /// [notificationProcessor] and reverse requests to [reverseRequestProcessor].
  void listenToOutput(
    NotificationProcessor notificationProcessor, [
    ReverseRequestProcessor? reverseRequestProcessor,
  ]) {
    // Provide a default implementation of the reverse request processor that
    // just throws because there are many tests that don't use reverse-requests.
    reverseRequestProcessor ??= (_) => throw UnimplementedError(
      "A reverse request was received but the test did not provide 'reverseRequestProcessor'",
    );

    _process.stdout.transform(utf8.decoder).transform(LineSplitter()).listen((
      String line,
    ) {
      lastCommunicationTime = currentElapseTime;
      var trimmedLine = line.trim();

      // Guard against lines like:
      //   {"event":"server.connected","params":{...}}The Dart VM service is listening on ...
      const dartVMServiceMessage = 'The Dart VM service is listening on ';
      if (trimmedLine.contains(dartVMServiceMessage)) {
        trimmedLine = trimmedLine
            .substring(0, trimmedLine.indexOf(dartVMServiceMessage))
            .trim();
      }
      const devtoolsMessage =
          'The Dart DevTools debugger and profiler is available at:';
      if (trimmedLine.contains(devtoolsMessage)) {
        trimmedLine = trimmedLine
            .substring(0, trimmedLine.indexOf(devtoolsMessage))
            .trim();
      }
      if (trimmedLine.isEmpty) {
        return;
      }

      _recordStdio('<== $trimmedLine');
      Map<Object?, Object?> message;
      try {
        message = json.decoder.convert(trimmedLine) as Map<Object?, Object?>;
      } catch (exception) {
        _badDataFromServer('JSON decode failure: $exception');
        return;
      }
      outOfTestExpect(message, isMap);
      if (message.containsKey('id') && message.containsKey('method')) {
        // Message is a reverse-request from the server.
        outOfTestExpect(message['id'], isString);
        var id = message['id'] as String;
        outOfTestExpect(message['method'], isString);
        var method = message['method'] as String;
        reverseRequestProcessor!(
          Request(id, method, message['params'] as Map<String, Object?>?),
        );
      } else if (message.containsKey('id')) {
        // Message is a response to an outstanding request.
        outOfTestExpect(message['id'], isString);
        var id = message['id'] as String;
        var completer = _pendingCommands[id];
        if (completer == null) {
          fail('Unexpected response from server: id=$id');
        } else {
          _pendingCommands.remove(id);
        }
        if (message.containsKey('error')) {
          completer.completeError(ServerErrorMessage(message));
        } else {
          completer.complete(message['result'] as Map<String, Object?>?);
        }
        // Check that the message is well-formed.  We do this after calling
        // completer.complete() or completer.completeError() so that we don't
        // stall the test in the event of an error.
        outOfTestExpect(message, isResponse);
      } else {
        // Message is a notification.  It should have an event and possibly
        // params.
        outOfTestExpect(message, contains('event'));
        outOfTestExpect(message['event'], isString);
        notificationProcessor(
          message['event'] as String,
          message['params'] as Map<Object?, Object?>,
        );
        // Check that the message is well-formed.  We do this after calling
        // notificationController.add() so that we don't stall the test in the
        // event of an error.
        outOfTestExpect(message, isNotification);
      }
    });
    _process.stderr
        .transform(Utf8Codec().decoder)
        .transform(LineSplitter())
        .listen((String line) {
          var trimmedLine = line.trim();
          _recordStdio('ERR:  $trimmedLine');
          _badDataFromServer('Message received on stderr', silent: true);
        });
  }

  /// Send a command to the server.  An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges the
  /// command with a response.  If the server acknowledges the command with a
  /// normal (non-error) response, the future will be completed with the
  /// 'result' field from the response.  If the server acknowledges the command
  /// with an error response, the future will be completed with an error.
  Future<Map<String, Object?>?> send(
    String method,
    Map<String, Object?>? params,
  ) {
    var id = '${_nextId++}';
    var command = <String, Object?>{'id': id, 'method': method};
    if (params != null) {
      command['params'] = params;
    }
    var completer = Completer<Map<String, Object?>?>();
    _pendingCommands[id] = completer;
    sendRaw(command);
    return completer.future;
  }

  /// Send a raw object to the server.
  void sendRaw(Map<String, Object?> data) {
    var line = json.encode(data);
    _recordStdio('==> $line');
    _process.stdin.add(utf8.encode('$line\n'));
  }

  /// Start the server. If [profileServer] is `true`, the server will be started
  /// with "--observe" and "--pause-isolates-on-exit", allowing Dart DevTools
  /// to be used.
  Future<void> start({
    required String dartSdkPath,
    int? diagnosticPort,
    String? instrumentationLogFile,
    String? packagesFile,
    bool profileServer = false,
    int? servicePort,
    bool useAnalysisHighlight2 = false,
  }) async {
    _time.start();

    var dartBinary = path.join(dartSdkPath, 'bin', 'dart');
    var serverPath = await getAnalysisServerPath(dartSdkPath);

    var arguments = <String>['--disable-dart-dev', '--no-dds'];
    //
    // Add VM arguments.
    //
    if (profileServer) {
      if (servicePort == null) {
        arguments.add('--observe');
      } else {
        arguments.add('--observe=$servicePort');
      }
      arguments.add('--pause-isolates-on-exit');
    } else if (servicePort != null) {
      arguments.add('--enable-vm-service=$servicePort');
    }
    if (Platform.packageConfig != null) {
      arguments.add('--packages=${Platform.packageConfig}');
    }
    arguments.add('--disable-service-auth-codes');
    //
    // Add the server executable.
    //
    arguments.add(serverPath);
    //
    // Add server arguments.
    //
    arguments.add('--suppress-analytics');
    arguments.add('--sdk=$dartSdkPath');
    if (diagnosticPort != null) {
      arguments.add('--port');
      arguments.add(diagnosticPort.toString());
    }
    if (instrumentationLogFile != null) {
      arguments.add('--instrumentation-log-file=$instrumentationLogFile');
    }
    if (packagesFile != null) {
      arguments.add('--packages=$packagesFile');
    }
    if (useAnalysisHighlight2) {
      arguments.add('--useAnalysisHighlight2');
    }
    _process = await Process.start(
      dartBinary,
      arguments,
      environment: {PubCommand.disablePubCommandEnvironmentKey: 'true'},
    );
    unawaited(
      _process.exitCode.then((int code) {
        if (code != 0) {
          _badDataFromServer('server terminated with exit code $code');
        }
      }),
    );
  }

  /// Deal with bad data received from the server.
  void _badDataFromServer(String details, {bool silent = false}) {
    if (!silent) {
      _recordStdio('BAD DATA FROM SERVER: $details');
    }
    if (_receivedBadDataFromServer) {
      // We're already dealing with it.
      return;
    }
    _receivedBadDataFromServer = true;
    debugStdio();
    // Give the server 1 second to continue outputting bad data before we kill
    // the test.  This is helpful if the server has had an unhandled exception
    // and is outputting a stacktrace, because it ensures that we see the
    // entire stacktrace.  Use expectAsync() to prevent the test from
    // ending during this 1 second.
    Future.delayed(
      Duration(seconds: 1),
      expectAsync0(() {
        fail('Bad data received from server: $details');
      }),
    );
  }

  /// Record a message that was exchanged with the server, and print it out if
  /// [debugStdio] has been called.
  void _recordStdio(String line) {
    var elapsedTime = currentElapseTime;
    line = '$elapsedTime: $line';
    if (_debuggingStdio) {
      print(line);
    }
    _recordedStdio.add(line);
  }
}

/// An error result from a server request.
class ServerErrorMessage {
  final Map<Object?, Object?> message;

  ServerErrorMessage(this.message);

  dynamic get error => message['error'];

  @override
  String toString() => message.toString();
}

/// Matcher that matches a list of objects, each of which satisfies the given
/// matcher.
class _ListOf extends Matcher {
  /// Matcher which every element of the list must satisfy.
  final Matcher elementMatcher;

  /// Iterable matcher which we use to test the contents of the list.
  final Matcher iterableMatcher;

  _ListOf(this.elementMatcher) : iterableMatcher = everyElement(elementMatcher);

  @override
  Description describe(Description description) =>
      description.add('List of ').addDescriptionOf(elementMatcher);

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! List) {
      return super.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    } else {
      return iterableMatcher.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    }
  }

  @override
  bool matches(item, Map<Object?, Object?> matchState) {
    if (item is! List) {
      return false;
    }
    return iterableMatcher.matches(item, matchState);
  }
}

/// Matcher that matches a map of objects, where each key/value pair in the
/// map satisfies the given key and value matchers.
class _MapOf extends _RecursiveMatcher {
  /// Matcher which every key in the map must satisfy.
  final Matcher keyMatcher;

  /// Matcher which every value in the map must satisfy.
  final Matcher valueMatcher;

  _MapOf(this.keyMatcher, this.valueMatcher);

  @override
  Description describe(Description description) => description
      .add('Map from ')
      .addDescriptionOf(keyMatcher)
      .add(' to ')
      .addDescriptionOf(valueMatcher);

  @override
  void populateMismatches(item, List<MismatchDescriber> mismatches) {
    if (item is! Map) {
      mismatches.add(simpleDescription('is not a map'));
      return;
    }
    item.forEach((key, value) {
      checkSubstructure(
        key,
        keyMatcher,
        mismatches,
        (Description description) =>
            description.add('key ').addDescriptionOf(key),
      );
      checkSubstructure(
        value,
        valueMatcher,
        mismatches,
        (Description description) =>
            description.add('field ').addDescriptionOf(key),
      );
    });
  }
}

/// Matcher that matches a union of different types, each of which is described
/// by a matcher.
class _OneOf extends Matcher {
  /// Matchers for the individual choices.
  final List<Matcher> choiceMatchers;

  _OneOf(this.choiceMatchers);

  @override
  Description describe(Description description) {
    for (var i = 0; i < choiceMatchers.length; i++) {
      if (i != 0) {
        if (choiceMatchers.length == 2) {
          description = description.add(' or ');
        } else {
          description = description.add(', ');
          if (i == choiceMatchers.length - 1) {
            description = description.add('or ');
          }
        }
      }
      description = description.addDescriptionOf(choiceMatchers[i]);
    }
    return description;
  }

  @override
  bool matches(item, Map<Object?, Object?> matchState) {
    for (var choiceMatcher in choiceMatchers) {
      var subState = {};
      if (choiceMatcher.matches(item, subState)) {
        return true;
      }
    }
    return false;
  }
}

/// Base class for matchers that operate by recursing through the contents of
/// an object.
abstract class _RecursiveMatcher extends Matcher {
  const _RecursiveMatcher();

  /// Check the type of a substructure whose value is [item], using [matcher].
  /// If it doesn't match, record a closure in [mismatches] which can describe
  /// the mismatch.  [describeSubstructure] is used to describe which
  /// substructure did not match.
  void checkSubstructure(
    Object? item,
    Matcher matcher,
    List<MismatchDescriber> mismatches,
    Description Function(Description) describeSubstructure,
  ) {
    var subState = {};
    if (!matcher.matches(item, subState)) {
      mismatches.add((Description mismatchDescription) {
        mismatchDescription = mismatchDescription.add('contains malformed ');
        mismatchDescription = describeSubstructure(mismatchDescription);
        mismatchDescription = mismatchDescription
            .add(' (should be ')
            .addDescriptionOf(matcher);
        var subDescription = matcher
            .describeMismatch(item, StringDescription(), subState, false)
            .toString();
        if (subDescription.isNotEmpty) {
          mismatchDescription = mismatchDescription
              .add('; ')
              .add(subDescription);
        }
        return mismatchDescription.add(')');
      });
    }
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    var mismatches = matchState['mismatches'] as List<MismatchDescriber>?;
    if (mismatches != null) {
      for (var i = 0; i < mismatches.length; i++) {
        var mismatch = mismatches[i];
        if (i > 0) {
          if (mismatches.length == 2) {
            mismatchDescription = mismatchDescription.add(' and ');
          } else if (i == mismatches.length - 1) {
            mismatchDescription = mismatchDescription.add(', and ');
          } else {
            mismatchDescription = mismatchDescription.add(', ');
          }
        }
        mismatchDescription = mismatch(mismatchDescription);
      }
      return mismatchDescription;
    } else {
      return super.describeMismatch(
        item,
        mismatchDescription,
        matchState,
        verbose,
      );
    }
  }

  @override
  bool matches(item, Map<Object?, Object?> matchState) {
    var mismatches = <MismatchDescriber>[];
    populateMismatches(item, mismatches);
    if (mismatches.isEmpty) {
      return true;
    } else {
      addStateInfo(matchState, {'mismatches': mismatches});
      return false;
    }
  }

  /// Populate [mismatches] with descriptions of all the ways in which [item]
  /// does not match.
  void populateMismatches(Object? item, List<MismatchDescriber> mismatches);

  /// Create a [MismatchDescriber] describing a mismatch with a simple string.
  MismatchDescriber simpleDescription(String description) =>
      (Description mismatchDescription) {
        mismatchDescription.add(description);
        return mismatchDescription;
      };
}
