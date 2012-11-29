// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test infrastructure for testing pub. Unlike typical unit tests, most pub
 * tests are integration tests that stage some stuff on the file system, run
 * pub, and then validate the results. This library provides an API to build
 * tests like that.
 */
library test_pub;

import 'dart:io';
import 'dart:isolate';
import 'dart:json';
import 'dart:math';
import 'dart:uri';

import '../../../pkg/oauth2/lib/oauth2.dart' as oauth2;
import '../../../pkg/unittest/lib/unittest.dart';
import '../../lib/file_system.dart' as fs;
import '../../pub/git_source.dart';
import '../../pub/hosted_source.dart';
import '../../pub/io.dart';
import '../../pub/sdk_source.dart';
import '../../pub/utils.dart';
import '../../pub/yaml/yaml.dart';

/**
 * Creates a new [FileDescriptor] with [name] and [contents].
 */
FileDescriptor file(Pattern name, String contents) =>
    new FileDescriptor(name, contents);

/**
 * Creates a new [DirectoryDescriptor] with [name] and [contents].
 */
DirectoryDescriptor dir(Pattern name, [List<Descriptor> contents]) =>
    new DirectoryDescriptor(name, contents);

/**
 * Creates a new [FutureDescriptor] wrapping [future].
 */
FutureDescriptor async(Future<Descriptor> future) =>
    new FutureDescriptor(future);

/**
 * Creates a new [GitRepoDescriptor] with [name] and [contents].
 */
GitRepoDescriptor git(Pattern name, [List<Descriptor> contents]) =>
    new GitRepoDescriptor(name, contents);

/**
 * Creates a new [TarFileDescriptor] with [name] and [contents].
 */
TarFileDescriptor tar(Pattern name, [List<Descriptor> contents]) =>
    new TarFileDescriptor(name, contents);

/**
 * Creates a new [NothingDescriptor] with [name].
 */
NothingDescriptor nothing(String name) => new NothingDescriptor(name);

/**
 * The current [HttpServer] created using [serve].
 */
var _server;

/** The cached value for [_portCompleter]. */
Completer<int> _portCompleterCache;

/** The completer for [port]. */
Completer<int> get _portCompleter {
  if (_portCompleterCache != null) return _portCompleterCache;
  _portCompleterCache = new Completer<int>();
  _scheduleCleanup((_) {
    _portCompleterCache = null;
  });
  return _portCompleterCache;
}

/**
 * A future that will complete to the port used for the current server.
 */
Future<int> get port => _portCompleter.future;

/**
 * Creates an HTTP server to serve [contents] as static files. This server will
 * exist only for the duration of the pub run.
 *
 * Subsequent calls to [serve] will replace the previous server.
 */
void serve([List<Descriptor> contents]) {
  var baseDir = dir("serve-dir", contents);

  _schedule((_) {
    return _closeServer().transform((_) {
      _server = new HttpServer();
      _server.defaultRequestHandler = (request, response) {
        var path = request.uri.replaceFirst("/", "").split("/");
        response.persistentConnection = false;
        var stream;
        try {
          stream = baseDir.load(path);
        } catch (e) {
          response.statusCode = 404;
          response.contentLength = 0;
          closeHttpResponse(request, response);
          return;
        }

        var future = consumeInputStream(stream);
        future.then((data) {
          response.statusCode = 200;
          response.contentLength = data.length;
          response.outputStream.write(data);
          closeHttpResponse(request, response);
        });

        future.handleException((e) {
          print("Exception while handling ${request.uri}: $e");
          response.statusCode = 500;
          response.reasonPhrase = e.message;
          closeHttpResponse(request, response);
        });
      };
      _server.listen("127.0.0.1", 0);
      _portCompleter.complete(_server.port);
      _scheduleCleanup((_) => _closeServer());
      return null;
    });
  });
}

/**
 * Closes [_server]. Returns a [Future] that will complete after the [_server]
 * is closed.
 */
Future _closeServer() {
  if (_server == null) return new Future.immediate(null);
  _server.close();
  _server = null;
  _portCompleterCache = null;
  // TODO(nweiz): Remove this once issue 4155 is fixed. Pumping the event loop
  // *seems* to be enough to ensure that the server is actually closed, but I'm
  // putting this at 10ms to be safe.
  return sleep(10);
}

/**
 * The [DirectoryDescriptor] describing the server layout of packages that are
 * being served via [servePackages]. This is `null` if [servePackages] has not
 * yet been called for this test.
 */
DirectoryDescriptor _servedPackageDir;

/**
 * A map from package names to version numbers to YAML-serialized pubspecs for
 * those packages. This represents the packages currently being served by
 * [servePackages], and is `null` if [servePackages] has not yet been called for
 * this test.
 */
Map<String, Map<String, String>> _servedPackages;

/**
 * Creates an HTTP server that replicates the structure of pub.dartlang.org.
 * [pubspecs] is a list of unserialized pubspecs representing the packages to
 * serve.
 *
 * Subsequent calls to [servePackages] will add to the set of packages that are
 * being served. Previous packages will continue to be served.
 */
void servePackages(List<Map> pubspecs) {
  if (_servedPackages == null || _servedPackageDir == null) {
    _servedPackages = <String, Map<String, String>>{};
    _servedPackageDir = dir('packages', []);
    serve([_servedPackageDir]);

    _scheduleCleanup((_) {
      _servedPackages = null;
      _servedPackageDir = null;
    });
  }

  _schedule((_) {
    return _awaitObject(pubspecs).transform((resolvedPubspecs) {
      for (var spec in resolvedPubspecs) {
        var name = spec['name'];
        var version = spec['version'];
        var versions = _servedPackages.putIfAbsent(
            name, () => <String, String>{});
        versions[version] = yaml(spec);
      }

      _servedPackageDir.contents.clear();
      for (var name in _servedPackages.keys) {
        var versions = _servedPackages[name].keys;
        _servedPackageDir.contents.addAll([
          file('$name.json',
              JSON.stringify({'versions': versions})),
          dir(name, [
            dir('versions', flatten(versions.map((version) {
              return [
                file('$version.yaml', _servedPackages[name][version]),
                tar('$version.tar.gz', [
                  file('pubspec.yaml', _servedPackages[name][version]),
                  libDir(name, '$name $version')
                ])
              ];
            })))
          ])
        ]);
      }
    });
  });
}

/** Converts [value] into a YAML string. */
String yaml(value) => JSON.stringify(value);

/**
 * Describes a file named `pubspec.yaml` with the given YAML-serialized
 * [contents], which should be a serializable object.
 *
 * [contents] may contain [Future]s that resolve to serializable objects, which
 * may in turn contain [Future]s recursively.
 */
Descriptor pubspec(Map contents) {
  return async(_awaitObject(contents).transform((resolvedContents) =>
      file("pubspec.yaml", yaml(resolvedContents))));
}

/**
 * Describes a file named `pubspec.yaml` for an application package with the
 * given [dependencies].
 */
Descriptor appPubspec(List dependencies) {
  return pubspec({
    "name": "myapp",
    "dependencies": _dependencyListToMap(dependencies)
  });
}

/**
 * Describes a file named `pubspec.yaml` for a library package with the given
 * [name], [version], and [dependencies].
 */
Descriptor libPubspec(String name, String version, [List dependencies]) =>
  pubspec(package(name, version, dependencies));

/**
 * Describes a directory named `lib` containing a single dart file named
 * `<name>.dart` that contains a line of Dart code.
 */
Descriptor libDir(String name, [String code]) {
  // Default to printing the name if no other code was given.
  if (code == null) {
    code = name;
  }

  return dir("lib", [
    file("$name.dart", 'main() => "$code";')
  ]);
}

/**
 * Describes a map representing a library package with the given [name],
 * [version], and [dependencies].
 */
Map package(String name, String version, [List dependencies]) {
  var package = {"name": name, "version": version};
  if (dependencies != null) {
    package["dependencies"] = _dependencyListToMap(dependencies);
  }
  return package;
}

/**
 * Describes a map representing a dependency on a package in the package
 * repository.
 */
Map dependency(String name, [String versionConstraint]) {
  var url = port.transform((p) => "http://localhost:$p");
  var dependency = {"hosted": {"name": name, "url": url}};
  if (versionConstraint != null) dependency["version"] = versionConstraint;
  return dependency;
}

/**
 * Describes a directory for a package installed from the mock package server.
 * This directory is of the form found in the global package cache.
 */
DirectoryDescriptor packageCacheDir(String name, String version) {
  return dir("$name-$version", [
    libDir(name, '$name $version')
  ]);
}

/**
 * Describes a directory for a Git package. This directory is of the form found
 * in the revision cache of the global package cache.
 */
DirectoryDescriptor gitPackageRevisionCacheDir(String name, [int modifier]) {
  var value = name;
  if (modifier != null) value = "$name $modifier";
  return dir(new RegExp("$name${r'-[a-f0-9]+'}"), [
    libDir(name, value)
  ]);
}

/**
 * Describes a directory for a Git package. This directory is of the form found
 * in the repo cache of the global package cache.
 */
DirectoryDescriptor gitPackageRepoCacheDir(String name) {
  return dir(new RegExp("$name${r'-[a-f0-9]+'}"), [
    dir('hooks'),
    dir('info'),
    dir('objects'),
    dir('refs')
  ]);
}

/**
 * Describes the `packages/` directory containing all the given [packages],
 * which should be name/version pairs. The packages will be validated against
 * the format produced by the mock package server.
 *
 * A package with a null version should not be installed.
 */
DirectoryDescriptor packagesDir(Map<String, String> packages) {
  var contents = <Descriptor>[];
  packages.forEach((name, version) {
    if (version == null) {
      contents.add(nothing(name));
    } else {
      contents.add(dir(name, [
        file("$name.dart", 'main() => "$name $version";')
      ]));
    }
  });
  return dir(packagesPath, contents);
}

/**
 * Describes the global package cache directory containing all the given
 * [packages], which should be name/version pairs. The packages will be
 * validated against the format produced by the mock package server.
 *
 * A package's value may also be a list of versions, in which case all versions
 * are expected to be installed.
 */
DirectoryDescriptor cacheDir(Map packages) {
  var contents = <Descriptor>[];
  packages.forEach((name, versions) {
    if (versions is! List) versions = [versions];
    for (var version in versions) {
      contents.add(packageCacheDir(name, version));
    }
  });
  return dir(cachePath, [
    dir('hosted', [
      async(port.transform((p) => dir('localhost%58$p', contents)))
    ])
  ]);
}

/// Describes the file in the system cache that contains the client's OAuth2
/// credentials. The URL "/token" on [server] will be used as the token
/// endpoint for refreshing the access token.
Descriptor credentialsFile(
    ScheduledServer server,
    String accessToken,
    {String refreshToken,
     Date expiration}) {
  return async(server.url.transform((url) {
    return dir(cachePath, [
      file('credentials.json', new oauth2.Credentials(
          accessToken,
          refreshToken,
          url.resolve('/token'),
          ['https://www.googleapis.com/auth/userinfo.email'],
          expiration).toJson())
    ]);
  }));
}

/**
 * Describes the application directory, containing only a pubspec specifying the
 * given [dependencies].
 */
DirectoryDescriptor appDir(List dependencies) =>
  dir(appPath, [appPubspec(dependencies)]);

/**
 * Converts a list of dependencies as passed to [package] into a hash as used in
 * a pubspec.
 */
Future<Map> _dependencyListToMap(List<Map> dependencies) {
  return _awaitObject(dependencies).transform((resolvedDependencies) {
    var result = <String, Map>{};
    for (var dependency in resolvedDependencies) {
      var keys = dependency.keys.filter((key) => key != "version");
      var sourceName = only(keys);
      var source;
      switch (sourceName) {
      case "git":
        source = new GitSource();
        break;
      case "hosted":
        source = new HostedSource();
        break;
      case "sdk":
        source = new SdkSource('');
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
    return basename(url.replaceFirst(new RegExp(r"(\.git)?/?$"), ""));
  case "hosted":
    if (description is String) return description;
    return description['name'];
  case "sdk":
    return description;
  default:
    return description;
  }
}

/**
 * The path of the package cache directory used for tests. Relative to the
 * sandbox directory.
 */
final String cachePath = "cache";

/**
 * The path of the mock SDK directory used for tests. Relative to the sandbox
 * directory.
 */
final String sdkPath = "sdk";

/**
 * The path of the mock app directory used for tests. Relative to the sandbox
 * directory.
 */
final String appPath = "myapp";

/**
 * The path of the packages directory in the mock app used for tests. Relative
 * to the sandbox directory.
 */
final String packagesPath = "$appPath/packages";

/**
 * The type for callbacks that will be fired during [runPub]. Takes the sandbox
 * directory as a parameter.
 */
typedef Future _ScheduledEvent(Directory parentDir);

/**
 * The list of events that are scheduled to run as part of the test case.
 */
List<_ScheduledEvent> _scheduled;

/**
 * The list of events that are scheduled to run after the test case, even if it
 * failed.
 */
List<_ScheduledEvent> _scheduledCleanup;

/// The list of events that are scheduled to run after the test case only if it
/// failed.
List<_ScheduledEvent> _scheduledOnException;

/**
 * Set to true when the current batch of scheduled events should be aborted.
 */
bool _abortScheduled = false;

/**
 * Runs all the scheduled events for a test case. This should only be called
 * once per test case.
 */
void run() {
  var createdSandboxDir;

  var asyncDone = expectAsync0(() {});

  Future cleanup() {
    return _runScheduled(createdSandboxDir, _scheduledCleanup).chain((_) {
      _scheduled = null;
      _scheduledCleanup = null;
      _scheduledOnException = null;
      if (createdSandboxDir != null) return deleteDir(createdSandboxDir);
      return new Future.immediate(null);
    });
  }

  final future = _setUpSandbox().chain((sandboxDir) {
    createdSandboxDir = sandboxDir;
    return _runScheduled(sandboxDir, _scheduled);
  });

  future.handleException((error) {
    // If an error occurs during testing, delete the sandbox, throw the error so
    // that the test framework sees it, then finally call asyncDone so that the
    // test framework knows we're done doing asynchronous stuff.
    var future = _runScheduled(createdSandboxDir, _scheduledOnException)
        .chain((_) => cleanup());
    future.handleException((e) {
      print("Exception while cleaning up: $e");
      print(future.stackTrace);
      registerException(error, future.stackTrace);
      return true;
    });
    future.then((_) => registerException(error, future.stackTrace));
    return true;
  });

  future.chain((_) => cleanup()).then((_) {
    asyncDone();
  });
}

/// Get the path to the root "util/test/pub" directory containing the pub tests.
String get testDirectory {
  var dir = new Path.fromNative(new Options().script);
  while (dir.filename != 'pub') dir = dir.directoryPath;

  return new File(dir.toNativePath()).fullPathSync();
}

/**
 * Schedules a call to the Pub command-line utility. Runs Pub with [args] and
 * validates that its results match [output], [error], and [exitCode].
 */
void schedulePub({List<String> args, Pattern output, Pattern error,
    Future<Uri> tokenEndpoint, int exitCode: 0}) {
  _schedule((sandboxDir) {
    return _doPub(runProcess, sandboxDir, args, tokenEndpoint)
        .transform((result) {
      var failures = [];

      _validateOutput(failures, 'stdout', output, result.stdout);
      _validateOutput(failures, 'stderr', error, result.stderr);

      if (result.exitCode != exitCode) {
        failures.add(
            'Pub returned exit code ${result.exitCode}, expected $exitCode.');
      }

      if (failures.length > 0) {
        if (error == null) {
          // If we aren't validating the error, still show it on failure.
          failures.add('Pub stderr:');
          failures.addAll(result.stderr.map((line) => '| $line'));
        }

        throw new ExpectException(Strings.join(failures, '\n'));
      }

      return null;
    });
  });
}

/**
 * A shorthand for [schedulePub] and [run] when no validation needs to be done
 * after Pub has been run.
 */
void runPub({List<String> args, Pattern output, Pattern error,
    int exitCode: 0}) {
  schedulePub(args: args, output: output, error: error, exitCode: exitCode);
  run();
}

/// Starts a Pub process and returns a [ScheduledProcess] that supports
/// interaction with that process.
ScheduledProcess startPub({List<String> args}) {
  var process = _scheduleValue((sandboxDir) =>
      _doPub(startProcess, sandboxDir, args));
  return new ScheduledProcess("pub", process);
}

/// Like [startPub], but runs `pub lish` in particular with [server] used both
/// as the OAuth2 server (with "/token" as the token endpoint) and as the
/// package server.
ScheduledProcess startPubLish(ScheduledServer server, {List<String> args}) {
  var process = _scheduleValue((sandboxDir) {
    return server.url.chain((url) {
      var tokenEndpoint = url.resolve('/token');
      if (args == null) args = [];
      args = flatten(['lish', '--server', url.toString(), args]);
      return _doPub(startProcess, sandboxDir, args, tokenEndpoint);
    });
  });
  return new ScheduledProcess("pub lish", process);
}

/// Calls [fn] with appropriately modified arguments to run a pub process. [fn]
/// should have the same signature as [startProcess], except that the returned
/// [Future] may have a type other than [Process].
Future _doPub(Function fn, sandboxDir, List<String> args, Uri tokenEndpoint) {
  String pathInSandbox(path) => join(getFullPath(sandboxDir), path);

  return ensureDir(pathInSandbox(appPath)).chain((_) {
    // Find a Dart executable we can use to spawn. Use the same one that was
    // used to run this script itself.
    var dartBin = new Options().executable;

    // If the executable looks like a path, get its full path. That way we
    // can still find it when we spawn it with a different working directory.
    if (dartBin.contains(Platform.pathSeparator)) {
      dartBin = new File(dartBin).fullPathSync();
    }

    // Find the main pub entrypoint.
    var pubPath = fs.joinPaths(testDirectory, '../../pub/pub.dart');

    var dartArgs =
        ['--enable-type-checks', '--enable-asserts', pubPath, '--trace'];
    dartArgs.addAll(args);

    var environment = {
      'PUB_CACHE': pathInSandbox(cachePath),
      'DART_SDK': pathInSandbox(sdkPath)
    };
    if (tokenEndpoint != null) {
      environment['_PUB_TEST_TOKEN_ENDPOINT'] = tokenEndpoint.toString();
    }

    return fn(dartBin, dartArgs, workingDir: pathInSandbox(appPath),
        environment: environment);
  });
}

/**
 * Skips the current test if Git is not installed. This validates that the
 * current test is running on a buildbot in which case we expect git to be
 * installed. If we are not running on the buildbot, we will instead see if git
 * is installed and skip the test if not. This way, users don't need to have git
 * installed to run the tests locally (unless they actually care about the pub
 * git tests).
 */
void ensureGit() {
  _schedule((_) {
    return isGitInstalled.transform((installed) {
      if (!installed &&
          !Platform.environment.containsKey('BUILDBOT_BUILDERNAME')) {
        _abortScheduled = true;
      }
      return null;
    });
  });
}

Future<Directory> _setUpSandbox() => createTempDir();

Future _runScheduled(Directory parentDir, List<_ScheduledEvent> scheduled) {
  if (scheduled == null) return new Future.immediate(null);
  var iterator = scheduled.iterator();

  Future runNextEvent(_) {
    if (_abortScheduled || !iterator.hasNext) {
      _abortScheduled = false;
      scheduled.clear();
      return new Future.immediate(null);
    }

    var future = iterator.next()(parentDir);
    if (future != null) {
      return future.chain(runNextEvent);
    } else {
      return runNextEvent(null);
    }
  }

  return runNextEvent(null);
}

/**
 * Compares the [actual] output from running pub with [expected]. For [String]
 * patterns, ignores leading and trailing whitespace differences and tries to
 * report the offending difference in a nice way. For other [Pattern]s, just
 * reports whether the output contained the pattern.
 */
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
  var actualText = Strings.join(actual, '\n');
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
  expected.removeLast();

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

/**
 * Base class for [FileDescriptor] and [DirectoryDescriptor] so that a
 * directory can contain a heterogeneous collection of files and
 * subdirectories.
 */
abstract class Descriptor {
  /**
   * The name of this file or directory. This must be a [String] if the fiel or
   * directory is going to be created.
   */
  final Pattern name;

  Descriptor(this.name);

  /**
   * Creates the file or directory within [dir]. Returns a [Future] that is
   * completed after the creation is done.
   */
  Future create(dir);

  /**
   * Validates that this descriptor correctly matches the corresponding file
   * system entry within [dir]. Returns a [Future] that completes to `null` if
   * the entry is valid, or throws an error if it failed.
   */
  Future validate(String dir);

  /**
   * Deletes the file or directory within [dir]. Returns a [Future] that is
   * completed after the deletion is done.
   */
  Future delete(String dir);

  /**
   * Loads the file at [path] from within this descriptor. If [path] is empty,
   * loads the contents of the descriptor itself.
   */
  InputStream load(List<String> path);

  /**
   * Schedules the directory to be created before Pub is run with [runPub]. The
   * directory will be created relative to the sandbox directory.
   */
  // TODO(nweiz): Use implicit closurization once issue 2984 is fixed.
  void scheduleCreate() => _schedule((dir) => this.create(dir));

  /**
   * Schedules the file or directory to be deleted recursively.
   */
  void scheduleDelete() => _schedule((dir) => this.delete(dir));

  /**
   * Schedules the directory to be validated after Pub is run with [runPub]. The
   * directory will be validated relative to the sandbox directory.
   */
  void scheduleValidate() => _schedule((parentDir) => validate(parentDir.path));

  /**
   * Asserts that the name of the descriptor is a [String] and returns it.
   */
  String get _stringName {
    if (name is String) return name;
    throw 'Pattern $name must be a string.';
  }

  /**
   * Validates that at least one file in [dir] matching [name] is valid
   * according to [validate]. [validate] should complete to an exception if the
   * input path is invalid.
   */
  Future _validateOneMatch(String dir, Future validate(String path)) {
    // Special-case strings to support multi-level names like "myapp/packages".
    if (name is String) {
      var path = join(dir, name);
      return exists(path).chain((exists) {
        if (!exists) Expect.fail('File $name in $dir not found.');
        return validate(path);
      });
    }

    // TODO(nweiz): remove this when issue 4061 is fixed.
    var stackTrace;
    try {
      throw "";
    } catch (_, localStackTrace) {
      stackTrace = localStackTrace;
    }

    return listDir(dir).chain((files) {
      var matches = files.filter((file) => endsWithPattern(file, name));
      if (matches.length == 0) {
        Expect.fail('No files in $dir match pattern $name.');
      }
      if (matches.length == 1) return validate(matches[0]);

      var failures = [];
      var successes = 0;
      var completer = new Completer();
      checkComplete() {
        if (failures.length + successes != matches.length) return;
        if (successes > 0) {
          completer.complete(null);
          return;
        }

        var error = new StringBuffer();
        error.add("No files named $name in $dir were valid:\n");
        for (var failure in failures) {
          error.add("  ").add(failure).add("\n");
        }
        completer.completeException(
            new ExpectException(error.toString()), stackTrace);
      }

      for (var match in matches) {
        var future = validate(match);

        future.handleException((e) {
          failures.add(e);
          checkComplete();
          return true;
        });

        future.then((_) {
          successes++;
          checkComplete();
        });
      }
      return completer.future;
    });
  }
}

/**
 * Describes a file. These are used both for setting up an expected directory
 * tree before running a test, and for validating that the file system matches
 * some expectations after running it.
 */
class FileDescriptor extends Descriptor {
  /**
   * The text contents of the file.
   */
  final String contents;

  FileDescriptor(Pattern name, this.contents) : super(name);

  /**
   * Creates the file within [dir]. Returns a [Future] that is completed after
   * the creation is done.
   */
  Future<File> create(dir) {
    return writeTextFile(join(dir, _stringName), contents);
  }

  /**
   * Deletes the file within [dir]. Returns a [Future] that is completed after
   * the deletion is done.
   */
  Future delete(dir) {
    return deleteFile(join(dir, _stringName));
  }

  /**
   * Validates that this file correctly matches the actual file at [path].
   */
  Future validate(String path) {
    return _validateOneMatch(path, (file) {
      return readTextFile(file).transform((text) {
        if (text == contents) return null;

        Expect.fail('File $file should contain:\n\n$contents\n\n'
                    'but contained:\n\n$text');
      });
    });
  }

  /**
   * Loads the contents of the file.
   */
  InputStream load(List<String> path) {
    if (!path.isEmpty) {
      var joinedPath = Strings.join(path, '/');
      throw "Can't load $joinedPath from within $name: not a directory.";
    }

    var stream = new ListInputStream();
    stream.write(contents.charCodes);
    stream.markEndOfStream();
    return stream;
  }
}

/**
 * Describes a directory and its contents. These are used both for setting up
 * an expected directory tree before running a test, and for validating that
 * the file system matches some expectations after running it.
 */
class DirectoryDescriptor extends Descriptor {
  /**
   * The files and directories contained in this directory.
   */
  final List<Descriptor> contents;

  DirectoryDescriptor(Pattern name, List<Descriptor> contents)
    : this.contents = contents == null ? <Descriptor>[] : contents,
      super(name);

  /**
   * Creates the file within [dir]. Returns a [Future] that is completed after
   * the creation is done.
   */
  Future<Directory> create(parentDir) {
    // Create the directory.
    return ensureDir(join(parentDir, _stringName)).chain((dir) {
      if (contents == null) return new Future<Directory>.immediate(dir);

      // Recursively create all of its children.
      final childFutures = contents.map((child) => child.create(dir));
      // Only complete once all of the children have been created too.
      return Futures.wait(childFutures).transform((_) => dir);
    });
  }

  /**
   * Deletes the directory within [dir]. Returns a [Future] that is completed
   * after the deletion is done.
   */
  Future delete(dir) {
    return deleteDir(join(dir, _stringName));
  }

  /**
   * Validates that the directory at [path] contains all of the expected
   * contents in this descriptor. Note that this does *not* check that the
   * directory doesn't contain other unexpected stuff, just that it *does*
   * contain the stuff we do expect.
   */
  Future validate(String path) {
    return _validateOneMatch(path, (dir) {
      // Validate each of the items in this directory.
      final entryFutures = contents.map((entry) => entry.validate(dir));

      // If they are all valid, the directory is valid.
      return Futures.wait(entryFutures).transform((entries) => null);
    });
  }

  /**
   * Loads [path] from within this directory.
   */
  InputStream load(List<String> path) {
    if (path.isEmpty) {
      throw "Can't load the contents of $name: is a directory.";
    }

    for (var descriptor in contents) {
      if (descriptor.name == path[0]) {
        return descriptor.load(path.getRange(1, path.length - 1));
      }
    }

    throw "Directory $name doesn't contain ${Strings.join(path, '/')}.";
  }
}

/**
 * Wraps a [Future] that will complete to a [Descriptor] and makes it behave
 * like a concrete [Descriptor]. This is necessary when the contents of the
 * descriptor depends on information that's not available until part of the test
 * run is completed.
 */
class FutureDescriptor extends Descriptor {
  Future<Descriptor> _future;

  FutureDescriptor(this._future) : super('<unknown>');

  Future create(dir) => _future.chain((desc) => desc.create(dir));

  Future validate(dir) => _future.chain((desc) => desc.validate(dir));

  Future delete(dir) => _future.chain((desc) => desc.delete(dir));

  InputStream load(List<String> path) {
    var resultStream = new ListInputStream();
    _future.then((desc) => pipeInputToInput(desc.load(path), resultStream));
    return resultStream;
  }
}

/**
 * Describes a Git repository and its contents.
 */
class GitRepoDescriptor extends DirectoryDescriptor {
  GitRepoDescriptor(Pattern name, List<Descriptor> contents)
  : super(name, contents);

  /**
   * Creates the Git repository and commits the contents.
   */
  Future<Directory> create(parentDir) {
    return _runGitCommands(parentDir, [
      ['init'],
      ['add', '.'],
      ['commit', '-m', 'initial commit']
    ]);
  }

  /**
   * Commits any changes to the Git repository.
   */
  Future commit(parentDir) {
    return _runGitCommands(parentDir, [
      ['add', '.'],
      ['commit', '-m', 'update']
    ]);
  }

  /**
   * Schedules changes to be committed to the Git repository.
   */
  void scheduleCommit() => _schedule((dir) => this.commit(dir));

  /**
   * Return a Future that completes to the commit in the git repository referred
   * to by [ref] at the current point in the scheduled test run.
   */
  Future<String> revParse(String ref) {
    return _scheduleValue((parentDir) {
      return super.create(parentDir).chain((rootDir) {
        return _runGit(['rev-parse', ref], rootDir);
      }).transform((output) => output[0]);
    });
  }

  /// Schedule a Git command to run in this repository.
  void scheduleGit(List<String> args) {
    _schedule((parentDir) {
      var gitDir = new Directory(join(parentDir, name));
      return _runGit(args, gitDir);
    });
  }

  Future _runGitCommands(parentDir, List<List<String>> commands) {
    var workingDir;

    Future runGitStep(_) {
      if (commands.isEmpty) return new Future.immediate(workingDir);
      var command = commands.removeAt(0);
      return _runGit(command, workingDir).chain(runGitStep);
    }

    return super.create(parentDir).chain((rootDir) {
      workingDir = rootDir;
      return runGitStep(null);
    });
  }

  Future<String> _runGit(List<String> args, Directory workingDir) {
    // Explicitly specify the committer information. Git needs this to commit
    // and we don't want to rely on the buildbots having this already set up.
    var environment = {
      'GIT_AUTHOR_NAME': 'Pub Test',
      'GIT_AUTHOR_EMAIL': 'pub@dartlang.org',
      'GIT_COMMITTER_NAME': 'Pub Test',
      'GIT_COMMITTER_EMAIL': 'pub@dartlang.org'
    };

    return runGit(args, workingDir: workingDir.path,
        environment: environment).transform((result) {
      if (!result.success) {
        throw "Error running: git ${Strings.join(args, ' ')}\n"
            "${Strings.join(result.stderr, '\n')}";
      }

      return result.stdout;
    });
  }
}

/**
 * Describes a gzipped tar file and its contents.
 */
class TarFileDescriptor extends Descriptor {
  final List<Descriptor> contents;

  TarFileDescriptor(Pattern name, this.contents)
  : super(name);

  /**
   * Creates the files and directories within this tar file, then archives them,
   * compresses them, and saves the result to [parentDir].
   */
  Future<File> create(parentDir) {
    // TODO(rnystrom): Use withTempDir().
    var tempDir;
    return createTempDir().chain((_tempDir) {
      tempDir = _tempDir;
      return Futures.wait(contents.map((child) => child.create(tempDir)));
    }).chain((createdContents) {
      return consumeInputStream(createTarGz(createdContents, baseDir: tempDir));
    }).chain((bytes) {
      return new File(join(parentDir, _stringName)).writeAsBytes(bytes);
    }).chain((file) {
      return deleteDir(tempDir).transform((_) => file);
    });
  }

  /**
   * Validates that the `.tar.gz` file at [path] contains the expected contents.
   */
  Future validate(String path) {
    throw "TODO(nweiz): implement this";
  }

  Future delete(dir) {
    throw new UnsupportedError('');
  }

  /**
   * Loads the contents of this tar file.
   */
  InputStream load(List<String> path) {
    if (!path.isEmpty) {
      var joinedPath = Strings.join(path, '/');
      throw "Can't load $joinedPath from within $name: not a directory.";
    }

    var sinkStream = new ListInputStream();
    var tempDir;
    // TODO(rnystrom): Use withTempDir() here.
    // TODO(nweiz): propagate any errors to the return value. See issue 3657.
    createTempDir().chain((_tempDir) {
      tempDir = _tempDir;
      return create(tempDir);
    }).then((tar) {
      var sourceStream = tar.openInputStream();
      pipeInputToInput(sourceStream, sinkStream).then((_) {
        tempDir.delete(recursive: true);
      });
    });
    return sinkStream;
  }
}

/**
 * A descriptor that validates that no file exists with the given name.
 */
class NothingDescriptor extends Descriptor {
  NothingDescriptor(String name) : super(name);

  Future create(dir) => new Future.immediate(null);
  Future delete(dir) => new Future.immediate(null);

  Future validate(String dir) {
    return exists(join(dir, name)).transform((exists) {
      if (exists) Expect.fail('File $name in $dir should not exist.');
    });
  }

  InputStream load(List<String> path) {
    if (path.isEmpty) {
      throw "Can't load the contents of $name: it doesn't exist.";
    } else {
      throw "Can't load ${Strings.join(path, '/')} from within $name: $name "
        "doesn't exist.";
    }
  }
}

/// A class representing a [Process] that is scheduled to run in the course of
/// the test. This class allows actions on the process to be scheduled
/// synchronously. All operations on this class are scheduled.
///
/// Before running the test, either [shouldExit] or [kill] must be called on
/// this to ensure that the process terminates when expected.
///
/// If the test fails, this will automatically print out any remaining stdout
/// and stderr from the process to aid debugging.
class ScheduledProcess {
  /// The name of the process. Used for error reporting.
  final String name;

  /// The process that's scheduled to run.
  final Future<Process> _process;

  /// A [StringInputStream] wrapping the stdout of the process that's scheduled
  /// to run.
  final Future<StringInputStream> _stdout;

  /// A [StringInputStream] wrapping the stderr of the process that's scheduled
  /// to run.
  final Future<StringInputStream> _stderr;

  /// The exit code of the process that's scheduled to run. This will naturally
  /// only complete once the process has terminated.
  Future<int> get _exitCode => _exitCodeCompleter.future;

  /// The completer for [_exitCode].
  final Completer<int> _exitCodeCompleter = new Completer();

  /// Whether the user has scheduled the end of this process by calling either
  /// [shouldExit] or [kill].
  bool _endScheduled = false;

  /// Whether the process is expected to terminate at this point.
  bool _endExpected = false;

  /// Wraps a [Process] [Future] in a scheduled process.
  ScheduledProcess(this.name, Future<Process> process)
    : _process = process,
      _stdout = process.transform((p) => new StringInputStream(p.stdout)),
      _stderr = process.transform((p) => new StringInputStream(p.stderr)) {

    _schedule((_) {
      if (!_endScheduled) {
        throw new StateError("Scheduled process $name must have shouldExit() "
            "or kill() called before the test is run.");
      }

      return _process.transform((p) {
        p.onExit = (c) {
          if (_endExpected) {
            _exitCodeCompleter.complete(c);
            return;
          }

          // Sleep for half a second in case _endExpected is set in the next
          // scheduled event.
          sleep(500).then((_) {
            if (_endExpected) {
              _exitCodeCompleter.complete(c);
              return;
            }

            _printStreams().then((_) {
              registerException(new ExpectException("Process $name ended "
                  "earlier than scheduled with exit code $c"));
            });
          });
        };
      });
    });

    _scheduleOnException((_) {
      if (!_process.hasValue) return;

      if (!_exitCode.hasValue) {
        print("\nKilling process $name prematurely.");
        _endExpected = true;
        _process.value.kill();
      }

      return _printStreams();
    });

    _scheduleCleanup((_) {
      if (!_process.hasValue) return;
      // Ensure that the process is dead and we aren't waiting on any IO.
      var process = _process.value;
      process.kill();
      process.stdout.close();
      process.stderr.close();
    });
  }

  /// Reads the next line of stdout from the process.
  Future<String> nextLine() {
    return _scheduleValue((_) {
      return timeout(_stdout.chain(readLine), 5000,
          "waiting for the next stdout line from process $name");
    });
  }

  /// Reads the next line of stderr from the process.
  Future<String> nextErrLine() {
    return _scheduleValue((_) {
      return timeout(_stderr.chain(readLine), 5000,
          "waiting for the next stderr line from process $name");
    });
  }

  /// Writes [line] to the process as stdin.
  void writeLine(String line) {
    _schedule((_) => _process.transform((p) => p.stdin.writeString('$line\n')));
  }

  /// Kills the process, and waits until it's dead.
  void kill() {
    _endScheduled = true;
    _schedule((_) {
      _endExpected = true;
      return _process.chain((p) {
        p.kill();
        return timeout(_exitCode, 5000, "waiting for process $name to die");
      });
    });
  }

  /// Waits for the process to exit, and verifies that the exit code matches
  /// [expectedExitCode] (if given).
  void shouldExit([int expectedExitCode]) {
    _endScheduled = true;
    _schedule((_) {
      _endExpected = true;
      return timeout(_exitCode, 5000, "waiting for process $name to exit")
          .transform((exitCode) {
        if (expectedExitCode != null) {
          expect(exitCode, equals(expectedExitCode));
        }
      });
    });
  }

  /// Prints the remaining data in the process's stdout and stderr streams.
  /// Prints nothing if the straems are empty.
  Future _printStreams() {
    Future printStream(String streamName, StringInputStream stream) {
      return consumeStringInputStream(stream).transform((output) {
        if (output.isEmpty) return;

        print('\nProcess $name $streamName:');
        for (var line in output.trim().split("\n")) {
          print('| $line');
        }
        return;
      });
    }

    return printStream('stdout', _stdout.value)
        .chain((_) => printStream('stderr', _stderr.value));
  }
}

/// A class representing an [HttpServer] that's scheduled to run in the course
/// of the test. This class allows the server's request handling to be scheduled
/// synchronously. All operations on this class are scheduled.
class ScheduledServer {
  /// The wrapped server.
  final Future<HttpServer> _server;

  /// The queue of handlers to run for upcoming requests.
  final _handlers = new Queue<Future>();

  ScheduledServer._(this._server);

  /// Creates a new server listening on an automatically-allocated port on
  /// localhost.
  factory ScheduledServer() {
    var scheduledServer;
    scheduledServer = new ScheduledServer._(_scheduleValue((_) {
      var server = new HttpServer();
      server.defaultRequestHandler = scheduledServer._awaitHandle;
      server.listen("127.0.0.1", 0);
      _scheduleCleanup((_) => server.close());
      return new Future.immediate(server);
    }));
    return scheduledServer;
  }

  /// The port on which the server is listening.
  Future<int> get port => _server.transform((s) => s.port);

  /// The base URL of the server, including its port.
  Future<Uri> get url =>
    port.transform((p) => new Uri.fromString("http://localhost:$p"));

  /// Assert that the next request has the given [method] and [path], and pass
  /// it to [handler] to handle. If [handler] returns a [Future], wait until
  /// it's completed to continue the schedule.
  void handle(String method, String path,
      Future handler(HttpRequest request, HttpResponse response)) {
    var handlerCompleter = new Completer<Function>();
    _scheduleValue((_) {
      var requestCompleteCompleter = new Completer();
      handlerCompleter.complete((request, response) {
        expect(request.method, equals(method));
        expect(request.path, equals(path));

        var future = handler(request, response);
        if (future == null) future = new Future.immediate(null);
        chainToCompleter(future, requestCompleteCompleter);
      });
      return timeout(requestCompleteCompleter.future,
          5000, "waiting for $method $path");
    });
    _handlers.add(handlerCompleter.future);
  }

  /// Raises an error complaining of an unexpected request.
  void _awaitHandle(HttpRequest request, HttpResponse response) {
    var future = timeout(new Future.immediate(null).chain((_) {
      var handlerFuture = _handlers.removeFirst();
      if (handlerFuture == null) {
        fail('Unexpected ${request.method} request to ${request.path}.');
      }
      return handlerFuture;
    }).transform((handler) {
      handler(request, response);
    }), 5000, "waiting for a handler for ${request.method} ${request.path}");
    expect(future, completes);
  }
}

/**
 * Takes a simple data structure (composed of [Map]s, [List]s, scalar objects,
 * and [Future]s) and recursively resolves all the [Future]s contained within.
 * Completes with the fully resolved structure.
 */
Future _awaitObject(object) {
  // Unroll nested futures.
  if (object is Future) return object.chain(_awaitObject);
  if (object is Collection) return Futures.wait(object.map(_awaitObject));
  if (object is! Map) return new Future.immediate(object);

  var pairs = <Future<Pair>>[];
  object.forEach((key, value) {
    pairs.add(_awaitObject(value)
        .transform((resolved) => new Pair(key, resolved)));
  });
  return Futures.wait(pairs).transform((resolvedPairs) {
    var map = {};
    for (var pair in resolvedPairs) {
      map[pair.first] = pair.last;
    }
    return map;
  });
}

/**
 * Schedules a callback to be called as part of the test case.
 */
void _schedule(_ScheduledEvent event) {
  if (_scheduled == null) _scheduled = [];
  _scheduled.add(event);
}

/// Like [_schedule], but pipes the return value of [event] to a returned
/// [Future].
Future _scheduleValue(_ScheduledEvent event) {
  var completer = new Completer();
  _schedule((parentDir) {
    chainToCompleter(event(parentDir), completer);
    return completer.future;
  });
  return completer.future;
}

/// Schedules a callback to be called after the test case has completed, even if
/// it failed.
void _scheduleCleanup(_ScheduledEvent event) {
  if (_scheduledCleanup == null) _scheduledCleanup = [];
  _scheduledCleanup.add(event);
}

/// Schedules a callback to be called after the test case has completed, but
/// only if it failed.
void _scheduleOnException(_ScheduledEvent event) {
  if (_scheduledOnException == null) _scheduledOnException = [];
  _scheduledOnException.add(event);
}

/// Like [expect], but for [Future]s that complete as part of the scheduled
/// test. This is necessary to ensure that the exception thrown by the
/// expectation failing is handled by the scheduler.
///
/// Note that [matcher] matches against the completed value of [actual], so
/// calling [completion] is unnecessary.
void expectLater(Future actual, matcher, {String reason,
    FailureHandler failureHandler, bool verbose: false}) {
  _schedule((_) {
    return actual.transform((value) {
      expect(value, matcher, reason: reason, failureHandler: failureHandler,
          verbose: false);
    });
  });
}
