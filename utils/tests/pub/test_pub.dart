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
#import('dart:uri');

#import('../../../lib/unittest/unittest.dart');
#import('../../lib/file_system.dart', prefix: 'fs');
#import('../../pub/io.dart');
#import('../../pub/yaml/yaml.dart');

/**
 * Creates a new [FileDescriptor] with [name] and [contents].
 */
FileDescriptor file(String name, String contents) =>
    new FileDescriptor(name, contents);

/**
 * Creates a new [DirectoryDescriptor] with [name] and [contents].
 */
DirectoryDescriptor dir(String name, [List<Descriptor> contents]) =>
    new DirectoryDescriptor(name, contents);

/**
 * Creates a new [GitRepoDescriptor] with [name] and [contents].
 */
DirectoryDescriptor git(String name, [List<Descriptor> contents]) =>
    new GitRepoDescriptor(name, contents);

/**
 * Creates a new [TarFileDescriptor] with [name] and [contents].
 */
TarFileDescriptor tar(String name, [List<Descriptor> contents]) =>
    new TarFileDescriptor(name, contents);

/**
 * Creates an HTTP server to serve [contents] as static files. This server will
 * exist only for the duration of the pub run.
 */
void serve(String host, int port, [List<Descriptor> contents]) {
  var baseDir = dir("serve-dir", contents);
  if (host == 'localhost') {
    host = '127.0.0.1';
  }

  _scheduleBeforePub((_) {
    var server = new HttpServer();
    server.defaultRequestHandler = (request, response) {
      var path = request.uri.replaceFirst("/", "").split("/");
      var stream = baseDir.load(path);
      response.persistentConnection = false;
      if (stream == null) {
        response.statusCode = 404;
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
    server.listen(host, port);
    _scheduleCleanup((_) => server.close());

    return new Future.immediate(null);
  });
}

/**
 * Creates an HTTP server that replicates the structure of pub.dartlang.org.
 * [pubspecs] is a list of YAML-format pubspecs representing the packages to
 * serve.
 */
void servePackages(String host, int port, List<String> pubspecs) {
  var packages = <Map<String, String>>{};
  pubspecs.forEach((spec) {
    var parsed = loadYaml(spec);
    var name = parsed['name'];
    var version = parsed['version'];
    packages.putIfAbsent(name, () => <String>{})[version] = spec;
  });

  serve(host, port, [
    dir('packages', packages.getKeys().map((name) {
      return dir(name, [
        dir('versions', packages[name].getKeys().map((version) {
          return tar('$version.tar.gz', [
            file('pubspec.yaml', packages[name][version]),
            file('$name.dart', 'main() => print("$name $version");')
          ]);
        }))
      ]);
    }))
  ]);
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
 * The list of events that are scheduled to run after the sandbox directory has
 * been created but before Pub is run.
 */
List<_ScheduledEvent> _scheduledBeforePub;

/**
 * The list of events that are scheduled to run after Pub has been run.
 */
List<_ScheduledEvent> _scheduledAfterPub;

/**
 * The list of events that are scheduled to run after Pub has been run, even if
 * it failed.
 */
List<_ScheduledEvent> _scheduledCleanup;

void runPub([List<String> args, Pattern output, Pattern error,
    int exitCode = 0]) {
  var createdSandboxDir;

  var asyncDone = expectAsync0(() {});

  Future cleanup() {
    return _runScheduled(createdSandboxDir, _scheduledCleanup).chain((_) {
      _scheduledBeforePub = null;
      _scheduledAfterPub = null;
      if (createdSandboxDir != null) return deleteDir(createdSandboxDir);
      return new Future.immediate(null);
    });
  }

  String pathInSandbox(path) => join(getFullPath(createdSandboxDir), path);

  final future = _setUpSandbox().chain((sandboxDir) {
    createdSandboxDir = sandboxDir;
    return _runScheduled(sandboxDir, _scheduledBeforePub);
  }).chain((_) {
    return ensureDir(pathInSandbox(appPath));
  }).chain((_) {
    // TODO(rnystrom): Hack in the cache directory path. Should pass this
    // in using environment var once #752 is done.
    args.add('--cachedir=${pathInSandbox(cachePath)}');

    // TODO(rnystrom): Hack in the SDK path. Should pass this in using
    // environment var once #752 is done.
    args.add('--sdkdir=${pathInSandbox(sdkPath)}');

    return _runPub(args, pathInSandbox(appPath), pipeStdout: output == null,
        pipeStderr: error == null);
  }).chain((result) {
    _validateOutput(output, result.stdout);
    _validateOutput(error, result.stderr);

    Expect.equals(result.exitCode, exitCode,
        'Pub returned exit code ${result.exitCode}, expected $exitCode.');

    return _runScheduled(createdSandboxDir, _scheduledAfterPub);
  });

  future.chain((_) => cleanup()).then((_) => asyncDone());

  future.handleException((error) {
    // If an error occurs during testing, delete the sandbox, throw the error so
    // that the test framework sees it, then finally call asyncDone so that the
    // test framework knows we're done doing asynchronous stuff.
    cleanup().then((_) {
      guardAsync(() { throw error; }, asyncDone);
    });
    return true;
  });
}


/**
 * Wraps a test that needs git in order to run. This validates that the test is
 * running on a builbot in which case we expect git to be installed. If we are
 * not running on the buildbot, we will instead see if git is installed and
 * skip the test if not. This way, users don't need to have git installed to
 * run the tests locally (unless they actually care about the pub git tests).
 */
void withGit(void callback()) {
  isGitInstalled.then(expectAsync1((installed) {
    if (installed || Platform.environment.containsKey('BUILDBOT_BUILDERNAME')) {
      callback();
    }
  }));
}

Future<Directory> _setUpSandbox() {
  return createTempDir('pub-test-sandbox-');
}

_runScheduled(Directory parentDir, List<_ScheduledEvent> scheduled) {
  if (scheduled == null) return new Future.immediate(null);
  var future = Futures.wait(scheduled.map((event) {
    var subFuture = event(parentDir);
    return subFuture == null ? new Future.immediate(null) : subFuture;
  }));
  scheduled.clear();
  return future;
}

Future<ProcessResult> _runPub(List<String> pubArgs, String workingDir,
    [bool pipeStdout=false, bool pipeStderr=false]) {
  // Find a dart executable we can use to run pub. Uses the one that the
  // test infrastructure uses. We are not using new Options.executable here
  // because that gets confused if you invoked Dart through a shell script.
  final scriptDir = new File(new Options().script).directorySync().path;
  final platform = Platform.operatingSystem;
  final dartBin = join(scriptDir, '../../../tools/testing/bin/$platform/dart');

  // Find the main pub entrypoint.
  final pubPath = fs.joinPaths(scriptDir, '../../pub/pub.dart');

  final args = ['--enable-type-checks', '--enable-asserts', pubPath];
  args.addAll(pubArgs);

  return runProcess(dartBin, args, workingDir, pipeStdout, pipeStderr);
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

  final length = Math.min(expected.length, actual.length);
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
   * The short name of this file or directory.
   */
  final String name;

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
   * Loads the file at [path] from within this descriptor. If [path] is empty,
   * loads the contents of the descriptor itself.
   */
  abstract InputStream load(List<String> path);

  /**
   * Schedules the directory to be created before Pub is run with [runPub]. The
   * directory will be created relative to the sandbox directory.
   */
  // TODO(nweiz): Use implicit closurization once issue 2984 is fixed.
  void scheduleCreate() => _scheduleBeforePub((dir) => this.create(dir));

  /**
   * Schedules the directory to be validated after Pub is run with [runPub]. The
   * directory will be validated relative to the sandbox directory.
   */
  void scheduleValidate() =>
    _scheduleAfterPub((parentDir) => validate(parentDir.path));
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

  FileDescriptor(String name, this.contents) : super(name);

  /**
   * Creates the file within [dir]. Returns a [Future] that is completed after
   * the creation is done.
   */
  Future<File> create(dir) {
    return writeTextFile(join(dir, name), contents);
  }

  /**
   * Validates that this file correctly matches the actual file at [path].
   */
  Future validate(String path) {
    path = join(path, name);
    return fileExists(path).chain((exists) {
      if (!exists) Expect.fail('Expected file $path does not exist.');

      return readTextFile(path).transform((text) {
        if (text == contents) return null;

        Expect.fail('File $path should contain:\n\n$contents\n\n'
                    'but contained:\n\n$text');
      });
    });
  }

  /**
   * Loads the contents of the file.
   */
  InputStream load(List<String> path) {
    if (!path.isEmpty()) {
      var joinedPath = Strings.join('/', path);
      throw "Can't load $joinedPath from within $name: not a directory.";
    }

    var stream = new ListInputStream();
    stream.write(contents.charCodes());
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

  DirectoryDescriptor(String name, this.contents) : super(name);

  /**
   * Creates the file within [dir]. Returns a [Future] that is completed after
   * the creation is done.
   */
  Future<Directory> create(parentDir) {
    final completer = new Completer<Directory>();

    // Create the directory.
    createDir(join(parentDir, name)).then((dir) {
      if (contents == null) {
        completer.complete(dir);
      } else {
        // Recursively create all of its children.
        final childFutures = contents.map((child) => child.create(dir));
        Futures.wait(childFutures).then((_) {
          // Only complete once all of the children have been created too.
          completer.complete(dir);
        });
      }
    });

    return completer.future;
  }

  /**
   * Validates that the directory at [path] contains all of the expected
   * contents in this descriptor. Note that this does *not* check that the
   * directory doesn't contain other unexpected stuff, just that it *does*
   * contain the stuff we do expect.
   */
  Future validate(String path) {
    // Validate each of the items in this directory.
    final entryFutures = contents.map(
        (entry) => entry.validate(join(path, name)));

    // If they are all valid, the directory is valid.
    return Futures.wait(entryFutures).transform((entries) => null);
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

    throw "Directory $name doesn't contain ${Strings.join('/', path)}.";
  }
}

/**
 * Describes a Git repository and its contents.
 */
class GitRepoDescriptor extends DirectoryDescriptor {
  GitRepoDescriptor(String name, List<Descriptor> contents)
  : super(name, contents);

  /**
   * Creates the Git repository and commits the contents.
   */
  Future<Directory> create(parentDir) {
    var workingDir;
    Future runGit(List<String> args) {
      return runProcess('git', args, workingDir: workingDir.path).
        transform((result) {
          if (!result.success) throw "Error running git: ${result.stderr}";
          return null;
        });
    }

    return super.create(parentDir).chain((rootDir) {
      workingDir = rootDir;
      return runGit(['init']);
    }).chain((_) => runGit(['add', '.']))
      .chain((_) => runGit(['commit', '-m', 'initial commit']))
      .transform((_) => workingDir);
  }
}

/**
 * Describes a gzipped tar file and its contents.
 */
class TarFileDescriptor extends Descriptor {
  final List<Descriptor> contents;

  TarFileDescriptor(String name, this.contents)
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
        join(parentDir, name)];
      args.addAll(contents.map((child) => child.name));
      return runProcess("tar", args);
    }).chain((result) {
      if (!result.success) {
        throw "Failed to create tar file $name.\n"
          "STDERR: ${Strings.join(result.stderr, "\n")}";
      }
      return deleteDir(tempDir);
    }).transform((_) {
      return new File(join(parentDir, name));
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
      var joinedPath = Strings.join('/', path);
      throw "Can't load $joinedPath from within $name: not a directory.";
    }

    var stream = new ListInputStream();
    var tempDir;
    // TODO(nweiz): propagate any errors to the return value. See issue 3657.
    createTempDir("pub-test-tmp-").chain((_tempDir) {
      tempDir = _tempDir;
      return create(tempDir);
    }).then((tar) {
      pipeInputToInput(tar.openInputStream(), stream);
      tempDir.deleteRecursively();
    });
    return stream;
  }
}

/**
 * Schedules a callback to be called before Pub is run with [runPub].
 */
void _scheduleBeforePub(_ScheduledEvent event) {
  if (_scheduledBeforePub == null) _scheduledBeforePub = [];
  _scheduledBeforePub.add(event);
}

/**
 * Schedules a callback to be called after Pub is run with [runPub].
 */
void _scheduleAfterPub(_ScheduledEvent event) {
  if (_scheduledAfterPub == null) _scheduledAfterPub = [];
  _scheduledAfterPub.add(event);
}

/**
 * Schedules a callback to be called after Pub is run with [runPub], even if it
 * fails.
 */
void _scheduleCleanup(_ScheduledEvent event) {
  if (_scheduledCleanup == null) _scheduledCleanup = [];
  _scheduledCleanup.add(event);
}
