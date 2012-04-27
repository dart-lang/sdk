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

#import('../../../lib/unittest/unittest.dart');
#import('../../lib/file_system.dart', prefix: 'fs');
#import('../../pub/io.dart');

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

void testPub(String description, [List<Descriptor> cache, Descriptor app,
    List<String> args, List<Descriptor> expectedPackageDir,
    String output, int exitCode = 0]) {
  asyncTest(description, 1, () {
    var createdSandboxDir;
    var createdAppDir;

    deleteSandboxIfCreated() {
      if (createdSandboxDir != null) {
        deleteDir(createdSandboxDir).then((_) {
          callbackDone();
        });
      } else {
        callbackDone();
      }
    }

    final future = _setUpSandbox().chain((sandboxDir) {
      createdSandboxDir = sandboxDir;
      return _setUpApp(sandboxDir, app);
    }).chain((appDir) {
      createdAppDir = appDir;
      return _setUpCache(createdSandboxDir, cache);
    }).chain((cacheDir) {
      var workingDir;
      if (createdAppDir != null) workingDir = createdAppDir.path;

      if (cacheDir != null) {
        // TODO(rnystrom): Hack in the cache directory path. Should pass this
        // in using environment var once #752 is done.
        args.add('--cachedir=${getFullPath(cacheDir)}');
      }

      return _runPub(args, workingDir);
    }).chain((result) {
      _validateOutput(output, result.stdout);

      Expect.equals(result.stderr.length, 0,
          'Did not expect any output on stderr, and got:\n' +
          Strings.join(result.stderr, '\n'));

      Expect.equals(result.exitCode, exitCode,
          'Pub returned exit code ${result.exitCode}, expected $exitCode.');

      return _validateExpectedPackages(createdAppDir, expectedPackageDir);
    });

    future.then((error) {
      // Null means there were no errors.
      if (error != null) Expect.fail(error);

      deleteSandboxIfCreated();
    });

    future.handleException((error) {
      deleteSandboxIfCreated();
    });
  });
}

Future<Directory> _setUpSandbox() {
  return createTempDir('pub-test-sandbox-');
}

Future _setUpCache(Directory sandboxDir, List<Descriptor> cache) {
  // No cache.
  if (cache == null) return new Future.immediate(null);

  return dir('pub-cache', cache).create(sandboxDir);
}

Future _setUpApp(Directory sandboxDir, Descriptor app) {
  // No app directory.
  if (app == null) return new Future.immediate(null);

  return app.create(sandboxDir);
}

Future<ProcessResult> _runPub(List<String> pubArgs, String workingDir) {
  // Find a dart executable we can use to run pub. Uses the one that the
  // test infrastructure uses.
  final scriptDir = new File(new Options().script).directorySync().path;
  final platform = Platform.operatingSystem();
  final dartBin = join(scriptDir, '../../../tools/testing/bin/$platform/dart');

  // Find the main pub entrypoint.
  final pubPath = fs.joinPaths(scriptDir, '../../pub/pub.dart');

  final args = [pubPath];
  args.addAll(pubArgs);

  return runProcess(dartBin, args, workingDir);
}

/**
 * Validates the contents of the "packages" directory inside [appDir] against
 * [expectedPackageDir].
 */
Future<String> _validateExpectedPackages(Directory appDir,
    List<Descriptor> expectedPackageDir) {
  // No expectation.
  if (expectedPackageDir == null) return new Future.immediate(null);

  return dir('packages', expectedPackageDir).validate(appDir.path);
}

/**
 * Compares the [actual] output from running pub with [expectedText]. Ignores
 * leading and trailing whitespace differences and tries to report the
 * offending difference in a nice way.
 */
void _validateOutput(String expectedText, List<String> actual) {
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
  abstract Future create(String dir);

  /**
   * Validates that this descriptor correctly matches the corresponding file
   * system entry within [dir]. Returns a [Future] that completes to `null` if
   * the entry is valid, or a message describing the error if it failed.
   */
  abstract Future<String> validate(String dir);
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
  Future<File> create(String dir) {
    return writeTextFile(join(dir, name), contents);
  }

  /**
   * Validates that this file correctly matches the actual file at [path].
   */
  Future<String> validate(String path) {
    path = join(path, name);
    return fileExists(path).chain((exists) {
      if (!exists) {
        return new Future.immediate('Expected file $path does not exist.');
      }

      return readTextFile(path).transform((text) {
        if (text == contents) return null;

        return 'File $path should contain:\n\n$contents\n\n'
               'but contained:\n\n$text';
      });
    });
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
  Future<Directory> create(String parentDir) {
    final completer = new Completer<Directory>();

    // Create the directory.
    createDir(join(parentDir, name)).then((dir) {
      if (contents == null) {
        completer.complete(dir);
      } else {
        // Recursively create all of its children.
        final childFutures = contents.map((child) => child.create(dir.path));
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
  Future<String> validate(String path) {
    // Validate each of the items in this directory.
    final entryFutures = contents.map(
        (entry) => entry.validate(join(path, name)));

    // If they are all valid, the directory is valid.
    return Futures.wait(entryFutures).transform((entries) {
      for (final entry in entries) {
        if (entry != null) return entry;
      }

      // If we got here, all of the sub-entries were valid.
      return null;
    });
  }
}
