// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test infrastructure for testing pub. Unlike typical unit tests, most pub
/// tests are integration tests that stage some stuff on the file system, run
/// pub, and then validate the results. This library provides an API to build
/// tests like that.
library test_pub;

import 'dart:async';
import 'dart:collection' show Queue;
import 'dart:io' hide sleep;
import 'dart:json' as json;
import 'dart:math';
import 'dart:uri';
import 'dart:utf';

import 'package:http/testing.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:yaml/yaml.dart';

import '../../pub/entrypoint.dart';
// TODO(rnystrom): Using "gitlib" as the prefix here is ugly, but "git" collides
// with the git descriptor method. Maybe we should try to clean up the top level
// scope a bit?
import '../../pub/git.dart' as gitlib;
import '../../pub/git_source.dart';
import '../../pub/hosted_source.dart';
import '../../pub/http.dart';
import '../../pub/io.dart';
import '../../pub/path_source.dart';
import '../../pub/safe_http_server.dart';
import '../../pub/system_cache.dart';
import '../../pub/utils.dart';
import '../../pub/validator.dart';
import 'command_line_config.dart';
import 'descriptor.dart' as d;

/// This should be called at the top of a test file to set up an appropriate
/// test configuration for the machine running the tests.
initConfig() {
  // If we aren't running on the bots, use the human-friendly config.
  if (!runningOnBuildbot) {
    unittestConfiguration = new CommandLineConfiguration();
  }
}

/// Returns whether we're running on a Dart build bot.
bool get runningOnBuildbot =>
  Platform.environment.containsKey('BUILDBOT_BUILDERNAME');

/// The current [HttpServer] created using [serve].
var _server;

/// The cached value for [_portCompleter].
Completer<int> _portCompleterCache;

/// The completer for [port].
Completer<int> get _portCompleter {
  if (_portCompleterCache != null) return _portCompleterCache;
  _portCompleterCache = new Completer<int>();
  currentSchedule.onComplete.schedule(() {
    _portCompleterCache = null;
  }, 'clearing the port completer');
  return _portCompleterCache;
}

/// A future that will complete to the port used for the current server.
Future<int> get port => _portCompleter.future;

/// Creates an HTTP server to serve [contents] as static files. This server will
/// exist only for the duration of the pub run.
///
/// Subsequent calls to [serve] will replace the previous server.
void serve([List<d.Descriptor> contents]) {
  var baseDir = d.dir("serve-dir", contents);

  schedule(() {
    return _closeServer().then((_) {
      return SafeHttpServer.bind("127.0.0.1", 0).then((server) {
        _server = server;
        server.listen((request) {
          var response = request.response;
          try {
            var path = request.uri.path.replaceFirst("/", "");
            response.persistentConnection = false;
            var stream = baseDir.load(path);

            new ByteStream(stream).toBytes().then((data) {
              response.statusCode = 200;
              response.contentLength = data.length;
              response.add(data);
              response.close();
            }).catchError((e) {
              response.statusCode = 404;
              response.contentLength = 0;
              response.close();
            });
          } catch (e) {
            currentSchedule.signalError(e);
            response.statusCode = 500;
            response.close();
            return;
          }
        });
        _portCompleter.complete(_server.port);
        currentSchedule.onComplete.schedule(_closeServer);
        return null;
      });
    });
  }, 'starting a server serving:\n${baseDir.describe()}');
}

/// Closes [_server]. Returns a [Future] that will complete after the [_server]
/// is closed.
Future _closeServer() {
  if (_server == null) return new Future.value();
  _server.close();
  _server = null;
  _portCompleterCache = null;
  // TODO(nweiz): Remove this once issue 4155 is fixed. Pumping the event loop
  // *seems* to be enough to ensure that the server is actually closed, but I'm
  // putting this at 10ms to be safe.
  return sleep(10);
}

/// The [d.DirectoryDescriptor] describing the server layout of packages that
/// are being served via [servePackages]. This is `null` if [servePackages] has
/// not yet been called for this test.
d.DirectoryDescriptor _servedPackageDir;

/// A map from package names to version numbers to YAML-serialized pubspecs for
/// those packages. This represents the packages currently being served by
/// [servePackages], and is `null` if [servePackages] has not yet been called
/// for this test.
Map<String, Map<String, String>> _servedPackages;

/// Creates an HTTP server that replicates the structure of pub.dartlang.org.
/// [pubspecs] is a list of unserialized pubspecs representing the packages to
/// serve.
///
/// Subsequent calls to [servePackages] will add to the set of packages that
/// are being served. Previous packages will continue to be served.
void servePackages(List<Map> pubspecs) {
  if (_servedPackages == null || _servedPackageDir == null) {
    _servedPackages = <String, Map<String, String>>{};
    _servedPackageDir = d.dir('packages', []);
    serve([_servedPackageDir]);

    currentSchedule.onComplete.schedule(() {
      _servedPackages = null;
      _servedPackageDir = null;
    }, 'cleaning up served packages');
  }

  schedule(() {
    return awaitObject(pubspecs).then((resolvedPubspecs) {
      for (var spec in resolvedPubspecs) {
        var name = spec['name'];
        var version = spec['version'];
        var versions = _servedPackages.putIfAbsent(
            name, () => <String, String>{});
        versions[version] = yaml(spec);
      }

      _servedPackageDir.contents.clear();
      for (var name in _servedPackages.keys) {
        var versions = _servedPackages[name].keys.toList();
        _servedPackageDir.contents.addAll([
          d.file('$name.json', json.stringify({'versions': versions})),
          d.dir(name, [
            d.dir('versions', flatten(versions.map((version) {
              return [
                d.file('$version.yaml', _servedPackages[name][version]),
                d.tar('$version.tar.gz', [
                  d.file('pubspec.yaml', _servedPackages[name][version]),
                  d.libDir(name, '$name $version')
                ])
              ];
            })))
          ])
        ]);
      }
    });
  }, 'initializing the package server');
}

/// Converts [value] into a YAML string.
String yaml(value) => json.stringify(value);

/// The full path to the created sandbox directory for an integration test.
String get sandboxDir => _sandboxDir;
String _sandboxDir;

/// The path of the package cache directory used for tests. Relative to the
/// sandbox directory.
final String cachePath = "cache";

/// The path of the mock SDK directory used for tests. Relative to the sandbox
/// directory.
final String sdkPath = "sdk";

/// The path of the mock app directory used for tests. Relative to the sandbox
/// directory.
final String appPath = "myapp";

/// The path of the packages directory in the mock app used for tests. Relative
/// to the sandbox directory.
final String packagesPath = "$appPath/packages";

/// Set to true when the current batch of scheduled events should be aborted.
bool _abortScheduled = false;

/// Defines an integration test. The [body] should schedule a series of
/// operations which will be run asynchronously.
void integration(String description, void body()) =>
  _integration(description, body, test);

/// Like [integration], but causes only this test to run.
void solo_integration(String description, void body()) =>
  _integration(description, body, solo_test);

void _integration(String description, void body(), [Function testFn]) {
  testFn(description, () {
    // The windows bots are very slow, so we increase the default timeout.
    if (Platform.operatingSystem == "windows") {
      currentSchedule.timeout = new Duration(seconds: 10);
    }

    // By default, don't capture stack traces since they slow the tests way
    // down. To debug failing tests, comment this out.
    currentSchedule.captureStackTraces =
        new Options().arguments.contains('--trace');

    // Ensure the SDK version is always available.
    d.dir(sdkPath, [
      d.file('version', '0.1.2.3')
    ]).create();

    _sandboxDir = createTempDir();
    d.defaultRoot = sandboxDir;
    currentSchedule.onComplete.schedule(() => deleteEntry(_sandboxDir),
        'deleting the sandbox directory');

    // Schedule the test.
    body();
  });
}

/// Get the path to the root "util/test/pub" directory containing the pub
/// tests.
String get testDirectory {
  var dir = new Options().script;
  while (path.basename(dir) != 'pub') dir = path.dirname(dir);

  return path.absolute(dir);
}

/// Schedules renaming (moving) the directory at [from] to [to], both of which
/// are assumed to be relative to [sandboxDir].
void scheduleRename(String from, String to) {
  schedule(
      () => renameDir(
          path.join(sandboxDir, from),
          path.join(sandboxDir, to)),
      'renaming $from to $to');
}

/// Schedules creating a symlink at path [symlink] that points to [target],
/// both of which are assumed to be relative to [sandboxDir].
void scheduleSymlink(String target, String symlink) {
  schedule(
      () => createSymlink(
          path.join(sandboxDir, target),
          path.join(sandboxDir, symlink)),
      'symlinking $target to $symlink');
}

/// Schedules a call to the Pub command-line utility. Runs Pub with [args] and
/// validates that its results match [output], [error], and [exitCode].
void schedulePub({List args, Pattern output, Pattern error,
    Future<Uri> tokenEndpoint, int exitCode: 0}) {
  var pub = startPub(args: args, tokenEndpoint: tokenEndpoint);
  pub.shouldExit(exitCode);

  expect(Future.wait([
    pub.remainingStdout(),
    pub.remainingStderr()
  ]).then((results) {
    var failures = [];
    _validateOutput(failures, 'stdout', output, results[0].split('\n'));
    _validateOutput(failures, 'stderr', error, results[1].split('\n'));
    if (!failures.isEmpty) throw new TestFailure(failures.join('\n'));
  }), completes);
}

/// Like [startPub], but runs `pub lish` in particular with [server] used both
/// as the OAuth2 server (with "/token" as the token endpoint) and as the
/// package server.
///
/// Any futures in [args] will be resolved before the process is started.
ScheduledProcess startPublish(ScheduledServer server, {List args}) {
  var tokenEndpoint = server.url.then((url) =>
      url.resolve('/token').toString());
  if (args == null) args = [];
  args = flatten(['lish', '--server', tokenEndpoint, args]);
  return startPub(args: args, tokenEndpoint: tokenEndpoint);
}

/// Handles the beginning confirmation process for uploading a packages.
/// Ensures that the right output is shown and then enters "y" to confirm the
/// upload.
void confirmPublish(ScheduledProcess pub) {
  // TODO(rnystrom): This is overly specific and inflexible regarding different
  // test packages. Should validate this a little more loosely.
  expect(pub.nextLine(), completion(equals('Publishing "test_pkg" 1.0.0:')));
  expect(pub.nextLine(), completion(equals("|-- LICENSE")));
  expect(pub.nextLine(), completion(equals("|-- lib")));
  expect(pub.nextLine(), completion(equals("|   '-- test_pkg.dart")));
  expect(pub.nextLine(), completion(equals("'-- pubspec.yaml")));
  expect(pub.nextLine(), completion(equals("")));

  pub.writeLine("y");
}

/// Starts a Pub process and returns a [ScheduledProcess] that supports
/// interaction with that process.
///
/// Any futures in [args] will be resolved before the process is started.
ScheduledProcess startPub({List args, Future<Uri> tokenEndpoint}) {
  String pathInSandbox(String relPath) {
    return path.join(path.absolute(sandboxDir), relPath);
  }

  ensureDir(pathInSandbox(appPath));

  // Find a Dart executable we can use to spawn. Use the same one that was
  // used to run this script itself.
  var dartBin = new Options().executable;

  // If the executable looks like a path, get its full path. That way we
  // can still find it when we spawn it with a different working directory.
  if (dartBin.contains(Platform.pathSeparator)) {
    dartBin = new File(dartBin).fullPathSync();
  }

  // Find the main pub entrypoint.
  var pubPath = path.join(testDirectory, '..', '..', 'pub', 'pub.dart');

  var dartArgs = ['--package-root=$_packageRoot/', '--checked', pubPath,
      '--trace'];
  dartArgs.addAll(args);

  if (tokenEndpoint == null) tokenEndpoint = new Future.value();
  var optionsFuture = tokenEndpoint.then((tokenEndpoint) {
    var options = new ProcessOptions();
    options.workingDirectory = pathInSandbox(appPath);
    // TODO(nweiz): remove this when issue 9294 is fixed.
    options.environment = new Map.from(Platform.environment);
    options.environment['PUB_CACHE'] = pathInSandbox(cachePath);
    options.environment['DART_SDK'] = pathInSandbox(sdkPath);
    if (tokenEndpoint != null) {
      options.environment['_PUB_TEST_TOKEN_ENDPOINT'] =
        tokenEndpoint.toString();
    }
    return options;
  });

  return new ScheduledProcess.start(dartBin, dartArgs, options: optionsFuture,
      description: args.isEmpty ? 'pub' : 'pub ${args.first}');
}

/// Whether pub is running from within the Dart SDK, as opposed to from the Dart
/// source repository.
bool get _runningFromSdk => path.dirname(relativeToPub('..')) == 'util';

// TODO(nweiz): use the built-in mechanism for accessing this once it exists
// (issue 9119).
/// The path to the `packages` directory from which pub loads its dependencies.
String get _packageRoot {
  if (_runningFromSdk) {
    return path.absolute(relativeToPub(path.join('..', '..', 'packages')));
  } else {
    return path.absolute(path.join(
        path.dirname(new Options().executable), '..', '..', 'packages'));
  }
}

/// Skips the current test if Git is not installed. This validates that the
/// current test is running on a buildbot in which case we expect git to be
/// installed. If we are not running on the buildbot, we will instead see if
/// git is installed and skip the test if not. This way, users don't need to
/// have git installed to run the tests locally (unless they actually care
/// about the pub git tests).
///
/// This will also increase the [Schedule] timeout to 30 seconds on Windows,
/// where Git runs really slowly.
void ensureGit() {
  if (Platform.operatingSystem == "windows") {
    currentSchedule.timeout = new Duration(seconds: 30);
  }

  schedule(() {
    return gitlib.isInstalled.then((installed) {
      if (installed) return;
      if (runningOnBuildbot) return;
      currentSchedule.abort();
    });
  }, 'ensuring that Git is installed');
}

/// Use [client] as the mock HTTP client for this test.
///
/// Note that this will only affect HTTP requests made via http.dart in the
/// parent process.
void useMockClient(MockClient client) {
  var oldInnerClient = httpClient.inner;
  httpClient.inner = client;
  currentSchedule.onComplete.schedule(() {
    httpClient.inner = oldInnerClient;
  }, 'de-activating the mock client');
}

/// Describes a map representing a library package with the given [name],
/// [version], and [dependencies].
Map packageMap(String name, String version, [List dependencies]) {
  var package = {
    "name": name,
    "version": version,
    "author": "Nathan Weizenbaum <nweiz@google.com>",
    "homepage": "http://pub.dartlang.org",
    "description": "A package, I guess."
  };
  if (dependencies != null) {
    package["dependencies"] = dependencyListToMap(dependencies);
  }
  return package;
}

/// Describes a map representing a dependency on a package in the package
/// repository.
Map dependencyMap(String name, [String versionConstraint]) {
  var url = port.then((p) => "http://localhost:$p");
  var dependency = {"hosted": {"name": name, "url": url}};
  if (versionConstraint != null) dependency["version"] = versionConstraint;
  return dependency;
}

/// Converts a list of dependencies as passed to [package] into a hash as used
/// in a pubspec.
Future<Map> dependencyListToMap(List<Map> dependencies) {
  return awaitObject(dependencies).then((resolvedDependencies) {
    var result = <String, Map>{};
    for (var dependency in resolvedDependencies) {
      var keys = dependency.keys.where((key) => key != "version");
      var sourceName = only(keys);
      var source;
      switch (sourceName) {
      case "git":
        source = new GitSource();
        break;
      case "hosted":
        source = new HostedSource();
        break;
      case "path":
        source = new PathSource();
        break;
      default:
        throw 'Unknown source "$sourceName"';
      }

      result[_packageName(sourceName, dependency[sourceName])] = dependency;
    }
    return result;
  });
}

/// Return the name for the package described by [description] and from
/// [sourceName].
String _packageName(String sourceName, description) {
  switch (sourceName) {
  case "git":
    var url = description is String ? description : description['url'];
    // TODO(rnystrom): Using path.basename on a URL is hacky. If we add URL
    // support to pkg/pathos, should use an explicit builder for that.
    return path.basename(url.replaceFirst(new RegExp(r"(\.git)?/?$"), ""));
  case "hosted":
    if (description is String) return description;
    return description['name'];
  case "path":
    return path.basename(description);
  case "sdk":
    return description;
  default:
    return description;
  }
}

/// Compares the [actual] output from running pub with [expected]. For [String]
/// patterns, ignores leading and trailing whitespace differences and tries to
/// report the offending difference in a nice way. For other [Pattern]s, just
/// reports whether the output contained the pattern.
void _validateOutput(List<String> failures, String pipe, Pattern expected,
                     List<String> actual) {
  if (expected == null) return;

  if (expected is RegExp) {
    _validateOutputRegex(failures, pipe, expected, actual);
  } else {
    _validateOutputString(failures, pipe, expected, actual);
  }
}

void _validateOutputRegex(List<String> failures, String pipe,
                          RegExp expected, List<String> actual) {
  var actualText = actual.join('\n');
  if (actualText.contains(expected)) return;

  if (actual.length == 0) {
    failures.add('Expected $pipe to match "${expected.pattern}" but got none.');
  } else {
    failures.add('Expected $pipe to match "${expected.pattern}" but got:');
    failures.addAll(actual.map((line) => '| $line'));
  }
}

void _validateOutputString(List<String> failures, String pipe,
                           String expectedText, List<String> actual) {
  final expected = expectedText.split('\n');

  // Strip off the last line. This lets us have expected multiline strings
  // where the closing ''' is on its own line. It also fixes '' expected output
  // to expect zero lines of output, not a single empty line.
  if (expected.last.trim() == '') {
    expected.removeLast();
  }

  var results = [];
  var failed = false;

  // Compare them line by line to see which ones match.
  var length = max(expected.length, actual.length);
  for (var i = 0; i < length; i++) {
    if (i >= actual.length) {
      // Missing output.
      failed = true;
      results.add('? ${expected[i]}');
    } else if (i >= expected.length) {
      // Unexpected extra output.
      failed = true;
      results.add('X ${actual[i]}');
    } else {
      var expectedLine = expected[i].trim();
      var actualLine = actual[i].trim();

      if (expectedLine != actualLine) {
        // Mismatched lines.
        failed = true;
        results.add('X ${actual[i]}');
      } else {
        // Output is OK, but include it in case other lines are wrong.
        results.add('| ${actual[i]}');
      }
    }
  }

  // If any lines mismatched, show the expected and actual.
  if (failed) {
    failures.add('Expected $pipe:');
    failures.addAll(expected.map((line) => '| $line'));
    failures.add('Got:');
    failures.addAll(results);
  }
}

/// A function that creates a [Validator] subclass.
typedef Validator ValidatorCreator(Entrypoint entrypoint);

/// Schedules a single [Validator] to run on the [appPath]. Returns a scheduled
/// Future that contains the errors and warnings produced by that validator.
Future<Pair<List<String>, List<String>>> schedulePackageValidation(
    ValidatorCreator fn) {
  return schedule(() {
    var cache = new SystemCache.withSources(path.join(sandboxDir, cachePath));

    return new Future.sync(() {
      var validator = fn(new Entrypoint(path.join(sandboxDir, appPath), cache));
      return validator.validate().then((_) {
        return new Pair(validator.errors, validator.warnings);
      });
    });
  }, "validating package");
}

/// A matcher that matches a Pair.
Matcher pairOf(Matcher firstMatcher, Matcher lastMatcher) =>
   new _PairMatcher(firstMatcher, lastMatcher);

class _PairMatcher extends BaseMatcher {
  final Matcher _firstMatcher;
  final Matcher _lastMatcher;

  _PairMatcher(this._firstMatcher, this._lastMatcher);

  bool matches(item, MatchState matchState) {
    if (item is! Pair) return false;
    return _firstMatcher.matches(item.first, matchState) &&
        _lastMatcher.matches(item.last, matchState);
  }

  Description describe(Description description) {
    description.addAll("(", ", ", ")", [_firstMatcher, _lastMatcher]);
  }
}
