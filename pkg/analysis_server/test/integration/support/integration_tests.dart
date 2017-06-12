// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'integration_test_methods.dart';
import 'protocol_matchers.dart';

const Matcher isBool = const isInstanceOf<bool>();

const Matcher isInt = const isInstanceOf<int>();

const Matcher isNotification = const MatchesJsonObject(
    'notification', const {'event': isString},
    optionalFields: const {'params': isMap});

const Matcher isObject = isMap;

const Matcher isString = const isInstanceOf<String>();

final Matcher isResponse = new MatchesJsonObject('response', {'id': isString},
    optionalFields: {'result': anything, 'error': isRequestError});

Matcher isListOf(Matcher elementMatcher) => new _ListOf(elementMatcher);

Matcher isMapOf(Matcher keyMatcher, Matcher valueMatcher) =>
    new _MapOf(keyMatcher, valueMatcher);

Matcher isOneOf(List<Matcher> choiceMatchers) => new _OneOf(choiceMatchers);

/**
 * Assert that [actual] matches [matcher].
 */
void outOfTestExpect(actual, matcher,
    {String reason, skip, bool verbose: false}) {
  var matchState = {};
  try {
    if (matcher.matches(actual, matchState)) return;
  } catch (e, trace) {
    if (reason == null) {
      reason = '${(e is String) ? e : e.toString()} at $trace';
    }
  }
  fail(_defaultFailFormatter(actual, matcher, reason, matchState, verbose));
}

String _defaultFailFormatter(
    actual, Matcher matcher, String reason, Map matchState, bool verbose) {
  var description = new StringDescription();
  description.add('Expected: ').addDescriptionOf(matcher).add('\n');
  description.add('  Actual: ').addDescriptionOf(actual).add('\n');

  var mismatchDescription = new StringDescription();
  matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);

  if (mismatchDescription.length > 0) {
    description.add('   Which: $mismatchDescription\n');
  }
  if (reason != null) description.add(reason).add('\n');
  return description.toString();
}

/**
 * Type of closures used by LazyMatcher.
 */
typedef Matcher MatcherCreator();

/**
 * Type of closures used by MatchesJsonObject to record field mismatches.
 */
typedef Description MismatchDescriber(Description mismatchDescription);

/**
 * Type of callbacks used to process notifications.
 */
typedef void NotificationProcessor(String event, params);

/**
 * Base class for analysis server integration tests.
 */
abstract class AbstractAnalysisServerIntegrationTest
    extends IntegrationTestMixin {
  /**
   * Amount of time to give the server to respond to a shutdown request before
   * forcibly terminating it.
   */
  static const Duration SHUTDOWN_TIMEOUT = const Duration(seconds: 5);

  /**
   * Connection to the analysis server.
   */
  final Server server = new Server();

  /**
   * Temporary directory in which source files can be stored.
   */
  Directory sourceDirectory;

  /**
   * Map from file path to the list of analysis errors which have most recently
   * been received for the file.
   */
  HashMap<String, List<AnalysisError>> currentAnalysisErrors =
      new HashMap<String, List<AnalysisError>>();

  /**
   * The last list of analyzed files received.
   */
  List<String> lastAnalyzedFiles;

  /**
   * True if the teardown process should skip sending a "server.shutdown"
   * request (e.g. because the server is known to have already shutdown).
   */
  bool skipShutdown = false;

  /**
   * True if we are currently subscribed to [SERVER_STATUS] updates.
   */
  bool _subscribedToServerStatus = false;

  AbstractAnalysisServerIntegrationTest() {
    initializeInttestMixin();
  }

  /**
   * Return a future which will complete when a 'server.status' notification is
   * received from the server with 'analyzing' set to false.
   *
   * The future will only be completed by 'server.status' notifications that are
   * received after this function call.  So it is safe to use this getter
   * multiple times in one test; each time it is used it will wait afresh for
   * analysis to finish.
   */
  Future<ServerStatusParams> get analysisFinished {
    Completer completer = new Completer();
    StreamSubscription subscription;
    // This will only work if the caller has already subscribed to
    // SERVER_STATUS (e.g. using sendServerSetSubscriptions(['STATUS']))
    outOfTestExpect(_subscribedToServerStatus, isTrue);
    subscription = onServerStatus.listen((ServerStatusParams params) {
      if (params.analysis != null && !params.analysis.isAnalyzing) {
        completer.complete(params);
        subscription.cancel();
      }
    });
    return completer.future;
  }

  /**
   * Print out any messages exchanged with the server.  If some messages have
   * already been exchanged with the server, they are printed out immediately.
   */
  void debugStdio() {
    server.debugStdio();
  }

  List<AnalysisError> getErrors(String pathname) =>
      currentAnalysisErrors[pathname];

  /**
   * Read a source file with the given absolute [pathname].
   */
  String readFile(String pathname) => new File(pathname).readAsStringSync();

  @override
  Future sendServerSetSubscriptions(List<ServerService> subscriptions) {
    _subscribedToServerStatus = subscriptions.contains(ServerService.STATUS);
    return super.sendServerSetSubscriptions(subscriptions);
  }

  /**
   * The server is automatically started before every test, and a temporary
   * [sourceDirectory] is created.
   */
  Future setUp() async {
    sourceDirectory = new Directory(Directory.systemTemp
        .createTempSync('analysisServer')
        .resolveSymbolicLinksSync());

    onAnalysisErrors.listen((AnalysisErrorsParams params) {
      currentAnalysisErrors[params.file] = params.errors;
    });
    onAnalysisAnalyzedFiles.listen((AnalysisAnalyzedFilesParams params) {
      lastAnalyzedFiles = params.directories;
    });
    Completer serverConnected = new Completer();
    onServerConnected.listen((_) {
      outOfTestExpect(serverConnected.isCompleted, isFalse);
      serverConnected.complete();
    });
    onServerError.listen((ServerErrorParams params) {
      // A server error should never happen during an integration test.
      fail('${params.message}\n${params.stackTrace}');
    });
    await startServer();
    server.listenToOutput(dispatchNotification);
    server.exitCode.then((_) {
      skipShutdown = true;
    });
    return serverConnected.future;
  }

  /**
   * If [skipShutdown] is not set, shut down the server.
   */
  Future shutdownIfNeeded() {
    if (skipShutdown) {
      return new Future.value();
    }
    // Give the server a short time to comply with the shutdown request; if it
    // doesn't exit, then forcibly terminate it.
    sendServerShutdown();
    return server.exitCode.timeout(SHUTDOWN_TIMEOUT, onTimeout: () {
      // The integer value of the exit code isn't used, but we have to return
      // an integer to keep the typing correct.
      return server.kill('server failed to exit').then((_) => -1);
    });
  }

  /**
   * Convert the given [relativePath] to an absolute path, by interpreting it
   * relative to [sourceDirectory].  On Windows any forward slashes in
   * [relativePath] are converted to backslashes.
   */
  String sourcePath(String relativePath) {
    return join(sourceDirectory.path, relativePath.replaceAll('/', separator));
  }

  /**
   * Send the server an 'analysis.setAnalysisRoots' command directing it to
   * analyze [sourceDirectory].  If [subscribeStatus] is true (the default),
   * then also enable [SERVER_STATUS] notifications so that [analysisFinished]
   * can be used.
   */
  Future standardAnalysisSetup({bool subscribeStatus: true}) {
    List<Future> futures = <Future>[];
    if (subscribeStatus) {
      futures.add(sendServerSetSubscriptions([ServerService.STATUS]));
    }
    futures.add(sendAnalysisSetAnalysisRoots([sourceDirectory.path], []));
    return Future.wait(futures);
  }

  /**
   * Start [server].
   */
  Future startServer(
          {bool checked: true, int diagnosticPort, int servicesPort}) =>
      server.start(
          checked: checked,
          diagnosticPort: diagnosticPort,
          servicesPort: servicesPort);

  /**
   * After every test, the server is stopped and [sourceDirectory] is deleted.
   */
  Future tearDown() {
    return shutdownIfNeeded().then((_) {
      sourceDirectory.deleteSync(recursive: true);
    });
  }

  /**
   * Write a source file with the given absolute [pathname] and [contents].
   *
   * If the file didn't previously exist, it is created.  If it did, it is
   * overwritten.
   *
   * Parent directories are created as necessary.
   *
   * Return a normalized path to the file (with symbolic links resolved).
   */
  String writeFile(String pathname, String contents) {
    new Directory(dirname(pathname)).createSync(recursive: true);
    File file = new File(pathname);
    file.writeAsStringSync(contents);
    return file.resolveSymbolicLinksSync();
  }
}

/**
 * Wrapper class for Matcher which doesn't create the underlying Matcher object
 * until it is needed.  This is necessary in order to create matchers that can
 * refer to themselves (so that recursive data structures can be represented).
 */
class LazyMatcher implements Matcher {
  /**
   * Callback that will be used to create the matcher the first time it is
   * needed.
   */
  final MatcherCreator _creator;

  /**
   * The matcher returned by [_creator], if it has already been called.
   * Otherwise null.
   */
  Matcher _wrappedMatcher;

  LazyMatcher(this._creator);

  @override
  Description describe(Description description) {
    _createMatcher();
    return _wrappedMatcher.describe(description);
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    _createMatcher();
    return _wrappedMatcher.describeMismatch(
        item, mismatchDescription, matchState, verbose);
  }

  @override
  bool matches(item, Map matchState) {
    _createMatcher();
    return _wrappedMatcher.matches(item, matchState);
  }

  /**
   * Create the wrapped matcher object, if it hasn't been created already.
   */
  void _createMatcher() {
    if (_wrappedMatcher == null) {
      _wrappedMatcher = _creator();
    }
  }
}

/**
 * Matcher that matches a String drawn from a limited set.
 */
class MatchesEnum extends Matcher {
  /**
   * Short description of the expected type.
   */
  final String description;

  /**
   * The set of enum values that are allowed.
   */
  final List<String> allowedValues;

  const MatchesEnum(this.description, this.allowedValues);

  @override
  Description describe(Description description) =>
      description.add(this.description);

  @override
  bool matches(item, Map matchState) {
    return allowedValues.contains(item);
  }
}

/**
 * Matcher that matches a JSON object, with a given set of required and
 * optional fields, and their associated types (expressed as [Matcher]s).
 */
class MatchesJsonObject extends _RecursiveMatcher {
  /**
   * Short description of the expected type.
   */
  final String description;

  /**
   * Fields that are required to be in the JSON object, and [Matcher]s describing
   * their expected types.
   */
  final Map<String, Matcher> requiredFields;

  /**
   * Fields that are optional in the JSON object, and [Matcher]s describing
   * their expected types.
   */
  final Map<String, Matcher> optionalFields;

  const MatchesJsonObject(this.description, this.requiredFields,
      {this.optionalFields});

  @override
  Description describe(Description description) =>
      description.add(this.description);

  @override
  void populateMismatches(item, List<MismatchDescriber> mismatches) {
    if (item is! Map) {
      mismatches.add(simpleDescription('is not a map'));
      return;
    }
    if (requiredFields != null) {
      requiredFields.forEach((String key, Matcher valueMatcher) {
        if (!item.containsKey(key)) {
          mismatches.add((Description mismatchDescription) =>
              mismatchDescription
                  .add('is missing field ')
                  .addDescriptionOf(key)
                  .add(' (')
                  .addDescriptionOf(valueMatcher)
                  .add(')'));
        } else {
          _checkField(key, item[key], valueMatcher, mismatches);
        }
      });
    }
    item.forEach((key, value) {
      if (requiredFields != null && requiredFields.containsKey(key)) {
        // Already checked this field
      } else if (optionalFields != null && optionalFields.containsKey(key)) {
        _checkField(key, value, optionalFields[key], mismatches);
      } else {
        mismatches.add((Description mismatchDescription) => mismatchDescription
            .add('has unexpected field ')
            .addDescriptionOf(key));
      }
    });
  }

  /**
   * Check the type of a field called [key], having value [value], using
   * [valueMatcher].  If it doesn't match, record a closure in [mismatches]
   * which can describe the mismatch.
   */
  void _checkField(String key, value, Matcher valueMatcher,
      List<MismatchDescriber> mismatches) {
    checkSubstructure(
        value,
        valueMatcher,
        mismatches,
        (Description description) =>
            description.add('field ').addDescriptionOf(key));
  }
}

/**
 * Instances of the class [Server] manage a connection to a server process, and
 * facilitate communication to and from the server.
 */
class Server {
  /**
   * Server process object, or null if server hasn't been started yet.
   */
  Process _process;

  /**
   * Commands that have been sent to the server but not yet acknowledged, and
   * the [Completer] objects which should be completed when acknowledgement is
   * received.
   */
  final Map<String, Completer> _pendingCommands = <String, Completer>{};

  /**
   * Number which should be used to compute the 'id' to send in the next command
   * sent to the server.
   */
  int _nextId = 0;

  /**
   * Messages which have been exchanged with the server; we buffer these
   * up until the test finishes, so that they can be examined in the debugger
   * or printed out in response to a call to [debugStdio].
   */
  final List<String> _recordedStdio = <String>[];

  /**
   * True if we are currently printing out messages exchanged with the server.
   */
  bool _debuggingStdio = false;

  /**
   * True if we've received bad data from the server, and we are aborting the
   * test.
   */
  bool _receivedBadDataFromServer = false;

  /**
   * Stopwatch that we use to generate timing information for debug output.
   */
  Stopwatch _time = new Stopwatch();

  /**
   * The [currentElapseTime] at which the last communication was received from the server
   * or `null` if no communication has been received.
   */
  double lastCommunicationTime;

  /**
   * The current elapse time (seconds) since the server was started.
   */
  double get currentElapseTime => _time.elapsedTicks / _time.frequency;

  /**
   * Future that completes when the server process exits.
   */
  Future<int> get exitCode => _process.exitCode;

  /**
   * Print out any messages exchanged with the server.  If some messages have
   * already been exchanged with the server, they are printed out immediately.
   */
  void debugStdio() {
    if (_debuggingStdio) {
      return;
    }
    _debuggingStdio = true;
    for (String line in _recordedStdio) {
      print(line);
    }
  }

  /**
   * Find the root directory of the analysis_server package by proceeding
   * upward to the 'test' dir, and then going up one more directory.
   */
  String findRoot(String pathname) {
    while (!['benchmark', 'test'].contains(basename(pathname))) {
      String parent = dirname(pathname);
      if (parent.length >= pathname.length) {
        throw new Exception("Can't find root directory");
      }
      pathname = parent;
    }
    return dirname(pathname);
  }

  /**
   * Return a future that will complete when all commands that have been sent
   * to the server so far have been flushed to the OS buffer.
   */
  Future flushCommands() {
    return _process.stdin.flush();
  }

  /**
   * Stop the server.
   */
  Future<int> kill(String reason) {
    debugStdio();
    _recordStdio('FORCIBLY TERMINATING PROCESS: $reason');
    _process.kill();
    return _process.exitCode;
  }

  /**
   * Start listening to output from the server, and deliver notifications to
   * [notificationProcessor].
   */
  void listenToOutput(NotificationProcessor notificationProcessor) {
    _process.stdout
        .transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      lastCommunicationTime = currentElapseTime;
      String trimmedLine = line.trim();
      if (trimmedLine.startsWith('Observatory listening on ')) {
        return;
      }
      _recordStdio('RECV: $trimmedLine');
      var message;
      try {
        message = JSON.decoder.convert(trimmedLine);
      } catch (exception) {
        _badDataFromServer('JSON decode failure: $exception');
        return;
      }
      outOfTestExpect(message, isMap);
      Map messageAsMap = message;
      if (messageAsMap.containsKey('id')) {
        outOfTestExpect(messageAsMap['id'], isString);
        String id = message['id'];
        Completer completer = _pendingCommands[id];
        if (completer == null) {
          fail('Unexpected response from server: id=$id');
        } else {
          _pendingCommands.remove(id);
        }
        if (messageAsMap.containsKey('error')) {
          completer.completeError(new ServerErrorMessage(messageAsMap));
        } else {
          completer.complete(messageAsMap['result']);
        }
        // Check that the message is well-formed.  We do this after calling
        // completer.complete() or completer.completeError() so that we don't
        // stall the test in the event of an error.
        outOfTestExpect(message, isResponse);
      } else {
        // Message is a notification.  It should have an event and possibly
        // params.
        outOfTestExpect(messageAsMap, contains('event'));
        outOfTestExpect(messageAsMap['event'], isString);
        notificationProcessor(messageAsMap['event'], messageAsMap['params']);
        // Check that the message is well-formed.  We do this after calling
        // notificationController.add() so that we don't stall the test in the
        // event of an error.
        outOfTestExpect(message, isNotification);
      }
    });
    _process.stderr
        .transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      String trimmedLine = line.trim();
      _recordStdio('ERR:  $trimmedLine');
      _badDataFromServer('Message received on stderr', silent: true);
    });
  }

  /**
   * Send a command to the server.  An 'id' will be automatically assigned.
   * The returned [Future] will be completed when the server acknowledges the
   * command with a response.  If the server acknowledges the command with a
   * normal (non-error) response, the future will be completed with the 'result'
   * field from the response.  If the server acknowledges the command with an
   * error response, the future will be completed with an error.
   */
  Future send(String method, Map<String, dynamic> params) {
    String id = '${_nextId++}';
    Map<String, dynamic> command = <String, dynamic>{
      'id': id,
      'method': method
    };
    if (params != null) {
      command['params'] = params;
    }
    Completer completer = new Completer();
    _pendingCommands[id] = completer;
    String line = JSON.encode(command);
    _recordStdio('SEND: $line');
    _process.stdin.add(UTF8.encoder.convert("$line\n"));
    return completer.future;
  }

  /**
   * Start the server. If [profileServer] is `true`, the server will be started
   * with "--observe" and "--pause-isolates-on-exit", allowing the observatory
   * to be used.
   */
  Future start({
    bool checked: true,
    int diagnosticPort,
    String instrumentationLogFile,
    bool profileServer: false,
    String sdkPath,
    int servicesPort,
    bool useAnalysisHighlight2: false,
  }) async {
    if (_process != null) {
      throw new Exception('Process already started');
    }
    _time.start();
    String dartBinary = Platform.executable;
    String rootDir =
        findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
    String serverPath = normalize(join(rootDir, 'bin', 'server.dart'));
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
    if (instrumentationLogFile != null) {
      arguments.add('--instrumentation-log-file=$instrumentationLogFile');
    }
    if (sdkPath != null) {
      arguments.add('--sdk=$sdkPath');
    }
    if (useAnalysisHighlight2) {
      arguments.add('--useAnalysisHighlight2');
    }
//    print('Launching $serverPath');
//    print('$dartBinary ${arguments.join(' ')}');
    // TODO(devoncarew): We could experiment with instead launching the analysis
    // server in a separate isolate. This would make it easier to debug the
    // integration tests, and would likely speed the tests up as well.
    _process = await Process.start(dartBinary, arguments);
    _process.exitCode.then((int code) {
      if (code != 0) {
        _badDataFromServer('server terminated with exit code $code');
      }
    });
  }

  /**
   * Deal with bad data received from the server.
   */
  void _badDataFromServer(String details, {bool silent: false}) {
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
    new Future.delayed(new Duration(seconds: 1), expectAsync0(() {
      fail('Bad data received from server: $details');
    }));
  }

  /**
   * Record a message that was exchanged with the server, and print it out if
   * [debugStdio] has been called.
   */
  void _recordStdio(String line) {
    double elapsedTime = currentElapseTime;
    line = "$elapsedTime: $line";
    if (_debuggingStdio) {
      print(line);
    }
    _recordedStdio.add(line);
  }
}

/**
 * An error result from a server request.
 */
class ServerErrorMessage {
  final Map message;

  ServerErrorMessage(this.message);

  dynamic get error => message['error'];

  String toString() => message.toString();
}

/**
 * Matcher that matches a list of objects, each of which satisfies the given
 * matcher.
 */
class _ListOf extends Matcher {
  /**
   * Matcher which every element of the list must satisfy.
   */
  final Matcher elementMatcher;

  /**
   * Iterable matcher which we use to test the contents of the list.
   */
  final Matcher iterableMatcher;

  _ListOf(elementMatcher)
      : elementMatcher = elementMatcher,
        iterableMatcher = everyElement(elementMatcher);

  @override
  Description describe(Description description) =>
      description.add('List of ').addDescriptionOf(elementMatcher);

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! List) {
      return super
          .describeMismatch(item, mismatchDescription, matchState, verbose);
    } else {
      return iterableMatcher.describeMismatch(
          item, mismatchDescription, matchState, verbose);
    }
  }

  @override
  bool matches(item, Map matchState) {
    if (item is! List) {
      return false;
    }
    return iterableMatcher.matches(item, matchState);
  }
}

/**
 * Matcher that matches a map of objects, where each key/value pair in the
 * map satisies the given key and value matchers.
 */
class _MapOf extends _RecursiveMatcher {
  /**
   * Matcher which every key in the map must satisfy.
   */
  final Matcher keyMatcher;

  /**
   * Matcher which every value in the map must satisfy.
   */
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
              description.add('key ').addDescriptionOf(key));
      checkSubstructure(
          value,
          valueMatcher,
          mismatches,
          (Description description) =>
              description.add('field ').addDescriptionOf(key));
    });
  }
}

/**
 * Matcher that matches a union of different types, each of which is described
 * by a matcher.
 */
class _OneOf extends Matcher {
  /**
   * Matchers for the individual choices.
   */
  final List<Matcher> choiceMatchers;

  _OneOf(this.choiceMatchers);

  @override
  Description describe(Description description) {
    for (int i = 0; i < choiceMatchers.length; i++) {
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
  bool matches(item, Map matchState) {
    for (Matcher choiceMatcher in choiceMatchers) {
      Map subState = {};
      if (choiceMatcher.matches(item, subState)) {
        return true;
      }
    }
    return false;
  }
}

/**
 * Base class for matchers that operate by recursing through the contents of
 * an object.
 */
abstract class _RecursiveMatcher extends Matcher {
  const _RecursiveMatcher();

  /**
   * Check the type of a substructure whose value is [item], using [matcher].
   * If it doesn't match, record a closure in [mismatches] which can describe
   * the mismatch.  [describeSubstructure] is used to describe which
   * substructure did not match.
   */
  checkSubstructure(item, Matcher matcher, List<MismatchDescriber> mismatches,
      Description describeSubstructure(Description)) {
    Map subState = {};
    if (!matcher.matches(item, subState)) {
      mismatches.add((Description mismatchDescription) {
        mismatchDescription = mismatchDescription.add('contains malformed ');
        mismatchDescription = describeSubstructure(mismatchDescription);
        mismatchDescription =
            mismatchDescription.add(' (should be ').addDescriptionOf(matcher);
        String subDescription = matcher
            .describeMismatch(item, new StringDescription(), subState, false)
            .toString();
        if (subDescription.isNotEmpty) {
          mismatchDescription =
              mismatchDescription.add('; ').add(subDescription);
        }
        return mismatchDescription.add(')');
      });
    }
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    List<MismatchDescriber> mismatches =
        matchState['mismatches'] as List<MismatchDescriber>;
    if (mismatches != null) {
      for (int i = 0; i < mismatches.length; i++) {
        MismatchDescriber mismatch = mismatches[i];
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
      return super
          .describeMismatch(item, mismatchDescription, matchState, verbose);
    }
  }

  @override
  bool matches(item, Map matchState) {
    List<MismatchDescriber> mismatches = <MismatchDescriber>[];
    populateMismatches(item, mismatches);
    if (mismatches.isEmpty) {
      return true;
    } else {
      addStateInfo(matchState, {'mismatches': mismatches});
      return false;
    }
  }

  /**
   * Populate [mismatches] with descriptions of all the ways in which [item]
   * does not match.
   */
  void populateMismatches(item, List<MismatchDescriber> mismatches);

  /**
   * Create a [MismatchDescriber] describing a mismatch with a simple string.
   */
  MismatchDescriber simpleDescription(String description) =>
      (Description mismatchDescription) {
        mismatchDescription.add(description);
      };
}
