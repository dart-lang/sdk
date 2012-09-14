// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Test infrastructure for testing pub. Unlike typical unit tests, most pub
 * tests are integration tests that stage some stuff on the file system, run
 * pub, and then validate the results. This library provides an API to build
 * tests like that.
 */
#library('test_pub');

#import('dart:io');
#import('dart:isolate');
#import('dart:json');
#import('dart:math');
#import('dart:uri');

#import('../../../pkg/unittest/lib/unittest.dart');
#import('../../lib/file_system.dart', prefix: 'fs');
#import('../../pub/git_source.dart');
#import('../../pub/hosted_source.dart');
#import('../../pub/io.dart');
#import('../../pub/sdk_source.dart');
#import('../../pub/utils.dart');
#import('../../pub/yaml/yaml.dart');

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
          response.outputStream.close();
          return;
        }

        var future = consumeInputStream(stream);
        future.then((data) {
          response.statusCode = 200;
          response.contentLength = data.length;
          response.outputStream.write(data);
          response.outputStream.close();
        });

        future.handleException((e) {
          print("Exception while handling ${request.uri}: $e");
          response.statusCode = 500;
          response.reasonPhrase = e.message;
          response.outputStream.close();
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
      for (var name in _servedPackages.getKeys()) {
        var versions = _servedPackages[name].getKeys();
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
  return dir(new RegExp("$name${@'-[a-f0-9]+'}"), [
    libDir(name, value)
  ]);
}

/**
 * Describes a directory for a Git package. This directory is of the form found
 * in the repo cache of the global package cache.
 */
DirectoryDescriptor gitPackageRepoCacheDir(String name) {
  return dir(new RegExp("$name${@'-[a-f0-9]+'}"), [
    dir('branches'),
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
      var keys = dependency.getKeys().filter((key) => key != "version");
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

      result[source.packageName(dependency[sourceName])] = dependency;
    }
    return result;
  });
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
    cleanup().then((_) => registerException(error, future.stackTrace));
    return true;
  });

  future.chain((_) => cleanup()).then((_) {
    asyncDone();
  });
}

/**
 * Schedules a call to the Pub command-line utility. Runs Pub with [args] and
 * validates that its results match [output], [error], and [exitCode].
 */
void schedulePub([List<String> args, Pattern output, Pattern error,
    int exitCode = 0]) {
  _schedule((sandboxDir) {
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

      var scriptDir = new File(new Options().script).directorySync().path;

      // Find the main pub entrypoint.
      var pubPath = fs.joinPaths(scriptDir, '../../pub/pub.dart');

      var dartArgs =
          ['--enable-type-checks', '--enable-asserts', pubPath, '--trace'];
      dartArgs.addAll(args);

      var environment = new Map.from(Platform.environment);
      environment['PUB_CACHE'] = pathInSandbox(cachePath);
      environment['DART_SDK'] = pathInSandbox(sdkPath);

      return runProcess(dartBin, dartArgs, workingDir: pathInSandbox(appPath),
          environment: environment, pipeStdout: output == null,
          pipeStderr: error == null);
    }).transform((result) {
      _validateOutput(output, result.stdout);
      _validateOutput(error, result.stderr);

      Expect.equals(result.exitCode, exitCode,
          'Pub returned exit code ${result.exitCode}, expected $exitCode.');

      return null;
    });
  });
}

/**
 * A shorthand for [schedulePub] and [run] when no validation needs to be done
 * after Pub has been run.
 */
void runPub([List<String> args, Pattern output, Pattern error,
    int exitCode = 0]) {
  schedulePub(args, output, error, exitCode);
  run();
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

Future<Directory> _setUpSandbox() {
  return createTempDir();
}

Future _runScheduled(Directory parentDir, List<_ScheduledEvent> scheduled) {
  if (scheduled == null) return new Future.immediate(null);
  var iterator = scheduled.iterator();

  Future runNextEvent(_) {
    if (_abortScheduled || !iterator.hasNext()) {
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
void _validateOutput(Pattern expected, List<String> actual) {
  if (expected == null) return;

  if (expected is String) return _validateOutputString(expected, actual);
  var actualText = Strings.join(actual, "\n");
  if (actualText.contains(expected)) return;
  Expect.fail('Expected output to match "$expected", was:\n$actualText');
}

void _validateOutputString(String expectedText, List<String> actual) {
  final expected = expectedText.split('\n');

  // Strip off the last line. This lets us have expected multiline strings
  // where the closing ''' is on its own line. It also fixes '' expected output
  // to expect zero lines of output, not a single empty line.
  expected.removeLast();

  final length = min(expected.length, actual.length);
  for (var i = 0; i < length; i++) {
    if (expected[i].trim() != actual[i].trim()) {
      Expect.fail(
        'Output line ${i + 1} was: ${actual[i]}\nexpected: ${expected[i]}');
    }
  }

  if (expected.length > actual.length) {
    final message = new StringBuffer();
    message.add('Missing expected output:\n');
    for (var i = actual.length; i < expected.length; i++) {
      message.add(expected[i]);
      message.add('\n');
    }

    Expect.fail(message.toString());
  }

  if (expected.length < actual.length) {
    final message = new StringBuffer();
    message.add('Unexpected output:\n');
    for (var i = expected.length; i < actual.length; i++) {
      message.add(actual[i]);
      message.add('\n');
    }

    Expect.fail(message.toString());
  }
}

/**
 * Base class for [FileDescriptor] and [DirectoryDescriptor] so that a
 * directory can contain a heterogeneous collection of files and
 * subdirectories.
 */
class Descriptor {
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
  abstract Future create(dir);

  /**
   * Validates that this descriptor correctly matches the corresponding file
   * system entry within [dir]. Returns a [Future] that completes to `null` if
   * the entry is valid, or throws an error if it failed.
   */
  abstract Future validate(String dir);

  /**
   * Deletes the file or directory within [dir]. Returns a [Future] that is
   * completed after the deletion is done.
   */
  abstract Future delete(String dir);

  /**
   * Loads the file at [path] from within this descriptor. If [path] is empty,
   * loads the contents of the descriptor itself.
   */
  abstract InputStream load(List<String> path);

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
        completer.completeException(new ExpectException(error.toString()));
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
    if (!path.isEmpty()) {
      var joinedPath = Strings.join(path, '/');
      throw "Can't load $joinedPath from within $name: not a directory.";
    }

    var stream = new ListInputStream();
    stream.write(contents.charCodes());
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
    if (path.isEmpty()) {
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
    var workingDir;
    Future runGit(List<String> args) => _runGit(args, workingDir);

    return super.create(parentDir).chain((rootDir) {
      workingDir = rootDir;
      return runGit(['init']);
    }).chain((_) => runGit(['add', '.']))
      .chain((_) => runGit(['commit', '-m', 'initial commit']))
      .transform((_) => workingDir);
  }

  /**
   * Commits any changes to the Git repository.
   */
  Future commit(parentDir) {
    var workingDir;
    Future runGit(List<String> args) => _runGit(args, workingDir);

    return super.create(parentDir).chain((rootDir) {
      workingDir = rootDir;
      return runGit(['add', '.']);
    }).chain((_) => runGit(['commit', '-m', 'update']));
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
    var completer = new Completer<String>();
    // TODO(nweiz): inline this once issue 3197 is fixed
    var superCreate = super.create;
    _schedule((parentDir) {
      return superCreate(parentDir).chain((rootDir) {
        return _runGit(['rev-parse', ref], rootDir);
      }).transform((output) {
        completer.complete(output[0]);
        return null;
      });
    });
    return completer.future;
  }

  /// Schedule a Git command to run in this repository.
  void scheduleGit(List<String> args) {
    _schedule((parentDir) {
      var gitDir = new Directory(join(parentDir, name));
      return _runGit(args, gitDir);
    });
  }

  Future<String> _runGit(List<String> args, Directory workingDir) {
    return runGit(args, workingDir: workingDir.path).transform((result) {
      if (!result.success) throw "Error running git: ${result.stderr}";
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
    var tempDir;
    return parentDir.createTemp().chain((_tempDir) {
      tempDir = _tempDir;
      return Futures.wait(contents.map((child) => child.create(tempDir)));
    }).chain((_) {
      var args = ["--directory", tempDir.path, "--create", "--gzip", "--file",
          join(parentDir, _stringName)];
      args.addAll(contents.map((child) => child.name));
      return runProcess("tar", args);
    }).chain((result) {
      if (!result.success) {
        throw "Failed to create tar file $name.\n"
            "STDERR: ${Strings.join(result.stderr, "\n")}";
      }
      return deleteDir(tempDir);
    }).transform((_) {
      return new File(join(parentDir, _stringName));
    });
  }

  /**
   * Validates that the `.tar.gz` file at [path] contains the expected contents.
   */
  Future validate(String path) {
    throw "TODO(nweiz): implement this";
  }

  /**
   * Loads the contents of this tar file.
   */
  InputStream load(List<String> path) {
    if (!path.isEmpty()) {
      var joinedPath = Strings.join(path, '/');
      throw "Can't load $joinedPath from within $name: not a directory.";
    }

    var sinkStream = new ListInputStream();
    var tempDir;
    // TODO(nweiz): propagate any errors to the return value. See issue 3657.
    createTempDir().chain((_tempDir) {
      tempDir = _tempDir;
      return create(tempDir);
    }).then((tar) {
      var sourceStream = tar.openInputStream();
      pipeInputToInput(
          sourceStream, sinkStream, onClosed: tempDir.deleteRecursively);
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
    if (path.isEmpty()) {
      throw "Can't load the contents of $name: it doesn't exist.";
    } else {
      throw "Can't load ${Strings.join(path, '/')} from within $name: $name "
        "doesn't exist.";
    }
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

/**
 * Schedules a callback to be called after Pub is run with [runPub], even if it
 * fails.
 */
void _scheduleCleanup(_ScheduledEvent event) {
  if (_scheduledCleanup == null) _scheduledCleanup = [];
  _scheduledCleanup.add(event);
}
