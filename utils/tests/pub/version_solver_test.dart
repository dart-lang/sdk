// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_update_test;

import 'dart:io';
import 'dart:isolate';

import '../../pub/lock_file.dart';
import '../../pub/package.dart';
import '../../pub/pubspec.dart';
import '../../pub/root_source.dart';
import '../../pub/source.dart';
import '../../pub/source_registry.dart';
import '../../pub/utils.dart';
import '../../pub/version.dart';
import '../../pub/version_solver.dart';
import '../../../pkg/unittest/unittest.dart';

final noVersion = 'no version';
final disjointConstraint = 'disjoint';
final sourceMismatch = 'source mismatch';
final descriptionMismatch = 'description mismatch';
final couldNotSolve = 'unsolved';

Source source1;
Source source2;
Source versionlessSource;
Source rootSource;

main() {
  testResolve('no dependencies', {
    'myapp 0.0.0': {}
  }, result: {
    'myapp from root': '0.0.0'
  });

  testResolve('simple dependency tree', {
    'myapp 0.0.0': {
      'a': '1.0.0',
      'b': '1.0.0'
    },
    'a 1.0.0': {
      'aa': '1.0.0',
      'ab': '1.0.0'
    },
    'aa 1.0.0': {},
    'ab 1.0.0': {},
    'b 1.0.0': {
      'ba': '1.0.0',
      'bb': '1.0.0'
    },
    'ba 1.0.0': {},
    'bb 1.0.0': {}
  }, result: {
    'myapp from root': '0.0.0',
    'a': '1.0.0',
    'aa': '1.0.0',
    'ab': '1.0.0',
    'b': '1.0.0',
    'ba': '1.0.0',
    'bb': '1.0.0'
  });

  testResolve('shared dependency with overlapping constraints', {
    'myapp 0.0.0': {
      'a': '1.0.0',
      'b': '1.0.0'
    },
    'a 1.0.0': {
      'shared': '>=2.0.0 <4.0.0'
    },
    'b 1.0.0': {
      'shared': '>=3.0.0 <5.0.0'
    },
    'shared 2.0.0': {},
    'shared 3.0.0': {},
    'shared 3.6.9': {},
    'shared 4.0.0': {},
    'shared 5.0.0': {},
  }, result: {
    'myapp from root': '0.0.0',
    'a': '1.0.0',
    'b': '1.0.0',
    'shared': '3.6.9'
  });

  testResolve('shared dependency where dependent version in turn affects '
              'other dependencies', {
    'myapp 0.0.0': {
      'foo': '<=1.0.2',
      'bar': '1.0.0'
    },
    'foo 1.0.0': {},
    'foo 1.0.1': { 'bang': '1.0.0' },
    'foo 1.0.2': { 'whoop': '1.0.0' },
    'foo 1.0.3': { 'zoop': '1.0.0' },
    'bar 1.0.0': { 'foo': '<=1.0.1' },
    'bang 1.0.0': {},
    'whoop 1.0.0': {},
    'zoop 1.0.0': {}
  }, result: {
    'myapp from root': '0.0.0',
    'foo': '1.0.1',
    'bar': '1.0.0',
    'bang': '1.0.0'
  });

  testResolve('from versionless source', {
    'myapp 0.0.0': {
      'foo from versionless': 'any'
    },
    'foo 1.2.3 from versionless': {}
  }, result: {
    'myapp from root': '0.0.0',
    'foo from versionless': '1.2.3'
  });

  testResolve('transitively through versionless source', {
    'myapp 0.0.0': {
      'foo from versionless': 'any'
    },
    'foo 1.2.3 from versionless': {
      'bar': '>=1.0.0'
    },
    'bar 1.1.0': {}
  }, result: {
    'myapp from root': '0.0.0',
    'foo from versionless': '1.2.3',
    'bar': '1.1.0'
  });

  testResolve('with compatible locked dependency', {
    'myapp 0.0.0': {
      'foo': 'any'
    },
    'foo 1.0.0': { 'bar': '1.0.0' },
    'foo 1.0.1': { 'bar': '1.0.1' },
    'foo 1.0.2': { 'bar': '1.0.2' },
    'bar 1.0.0': {},
    'bar 1.0.1': {},
    'bar 1.0.2': {}
  }, lockfile: {
    'foo': '1.0.1'
  }, result: {
    'myapp from root': '0.0.0',
    'foo': '1.0.1',
    'bar': '1.0.1'
  });

  testResolve('with incompatible locked dependency', {
    'myapp 0.0.0': {
      'foo': '>1.0.1'
    },
    'foo 1.0.0': { 'bar': '1.0.0' },
    'foo 1.0.1': { 'bar': '1.0.1' },
    'foo 1.0.2': { 'bar': '1.0.2' },
    'bar 1.0.0': {},
    'bar 1.0.1': {},
    'bar 1.0.2': {}
  }, lockfile: {
    'foo': '1.0.1'
  }, result: {
    'myapp from root': '0.0.0',
    'foo': '1.0.2',
    'bar': '1.0.2'
  });

  testResolve('with unrelated locked dependency', {
    'myapp 0.0.0': {
      'foo': 'any'
    },
    'foo 1.0.0': { 'bar': '1.0.0' },
    'foo 1.0.1': { 'bar': '1.0.1' },
    'foo 1.0.2': { 'bar': '1.0.2' },
    'bar 1.0.0': {},
    'bar 1.0.1': {},
    'bar 1.0.2': {},
    'baz 1.0.0': {}
  }, lockfile: {
    'baz': '1.0.0'
  }, result: {
    'myapp from root': '0.0.0',
    'foo': '1.0.2',
    'bar': '1.0.2'
  });

  testResolve('circular dependency', {
    'myapp 1.0.0': {
      'foo': '1.0.0'
    },
    'foo 1.0.0': {
      'bar': '1.0.0'
    },
    'bar 1.0.0': {
      'foo': '1.0.0'
    }
  }, result: {
    'myapp from root': '1.0.0',
    'foo': '1.0.0',
    'bar': '1.0.0'
  });

  testResolve('dependency back onto root package', {
    'myapp 1.0.0': {
      'foo': '1.0.0'
    },
    'foo 1.0.0': {
      'myapp from root': '>=1.0.0'
    }
  }, result: {
    'myapp from root': '1.0.0',
    'foo': '1.0.0'
  });

  testResolve('dependency back onto root package with different source', {
    'myapp 1.0.0': {
      'foo': '1.0.0'
    },
    'foo 1.0.0': {
      'myapp': '>=1.0.0'
    }
  }, result: {
    'myapp from root': '1.0.0',
    'foo': '1.0.0'
  });

  testResolve('mismatched dependencies back onto root package', {
    'myapp 1.0.0': {
      'foo': '1.0.0',
      'bar': '1.0.0'
    },
    'foo 1.0.0': {
      'myapp': '>=1.0.0'
    },
    'bar 1.0.0': {
      'myapp from mock2': '>=1.0.0'
    }
  }, error: sourceMismatch);

  testResolve('dependency back onto root package with wrong version', {
    'myapp 1.0.0': {
      'foo': '1.0.0'
    },
    'foo 1.0.0': {
      'myapp': '<1.0.0'
    }
  }, error: disjointConstraint);

  testResolve('no version that matches requirement', {
    'myapp 0.0.0': {
      'foo': '>=1.0.0 <2.0.0'
    },
    'foo 2.0.0': {},
    'foo 2.1.3': {}
  }, error: noVersion);

  testResolve('no version that matches combined constraint', {
    'myapp 0.0.0': {
      'foo': '1.0.0',
      'bar': '1.0.0'
    },
    'foo 1.0.0': {
      'shared': '>=2.0.0 <3.0.0'
    },
    'bar 1.0.0': {
      'shared': '>=2.9.0 <4.0.0'
    },
    'shared 2.5.0': {},
    'shared 3.5.0': {}
  }, error: noVersion);

  testResolve('disjoint constraints', {
    'myapp 0.0.0': {
      'foo': '1.0.0',
      'bar': '1.0.0'
    },
    'foo 1.0.0': {
      'shared': '<=2.0.0'
    },
    'bar 1.0.0': {
      'shared': '>3.0.0'
    },
    'shared 2.0.0': {},
    'shared 4.0.0': {}
  }, error: disjointConstraint);

  testResolve('mismatched descriptions', {
    'myapp 0.0.0': {
      'foo': '1.0.0',
      'bar': '1.0.0'
    },
    'foo 1.0.0': {
      'shared-x': '1.0.0'
    },
    'bar 1.0.0': {
      'shared-y': '1.0.0'
    },
    'shared-x 1.0.0': {},
    'shared-y 1.0.0': {}
  }, error: descriptionMismatch);

  testResolve('mismatched sources', {
    'myapp 0.0.0': {
      'foo': '1.0.0',
      'bar': '1.0.0'
    },
    'foo 1.0.0': {
      'shared': '1.0.0'
    },
    'bar 1.0.0': {
      'shared from mock2': '1.0.0'
    },
    'shared 1.0.0': {},
    'shared 1.0.0 from mock2': {}
  }, error: sourceMismatch);

  testResolve('unstable dependency graph', {
    'myapp 0.0.0': {
      'a': '>=1.0.0'
    },
    'a 1.0.0': {},
    'a 2.0.0': {
      'b': '1.0.0'
    },
    'b 1.0.0': {
      'a': '1.0.0'
    }
  }, error: couldNotSolve);

// TODO(rnystrom): More stuff to test:
// - Two packages depend on the same package, but from different sources. Should
//   fail.
// - Depending on a non-existent package.
// - Test that only a certain number requests are sent to the mock source so we
//   can keep track of server traffic.
}

testResolve(description, packages, {lockfile, result, error}) {
  test(description, () {
    var isNoVersionException = predicate((x)=> x is NoVersionException,
        "is a NoVersionException");
    var isDisjointConstraintException =
        predicate((x)=> x is DisjointConstraintException,
       "    is a DisjointConstraintException");
    var isSourceMismatchException =
        predicate((x)=> x is SourceMismatchException,
            "is a SourceMismatchException");
    var isDescriptionMismatchException =
        predicate((x)=> x is DescriptionMismatchException,
            "is a DescriptionMismatchException");
    var isCouldNotSolveException = predicate((x)=> x is CouldNotSolveException,
            "is a CouldNotSolveException");

    var sources = new SourceRegistry();
    source1 = new MockSource('mock1');
    source2 = new MockSource('mock2');
    versionlessSource = new MockVersionlessSource();
    sources.register(source1);
    sources.register(source2);
    sources.register(versionlessSource);
    sources.setDefault(source1.name);

    // Build the test package graph.
    var root;
    packages.forEach((nameVersion, dependencies) {
      var parsed = parseSource(nameVersion);
      nameVersion = parsed.first;
      var source = parsed.last;

      var parts = nameVersion.split(' ');
      var name = parts[0];
      var version = parts[1];

      var package = source1.mockPackage(name, version, dependencies);
      if (name == 'myapp') {
        // Don't add the root package to the server, so we can verify that Pub
        // doesn't try to look up information about the local package on the
        // remote server.
        root = package;
        rootSource = new RootSource(root);
        sources.register(rootSource);
      } else {
        source.addPackage(package);
      }
    });

    // Clean up the expectation.
    if (result != null) {
      var newResult = {};
      result.forEach((name, version) {
        var parsed = parseSource(name);
        name = parsed.first;
        var source = parsed.last;
        version = new Version.parse(version);
        newResult[name] = new PackageId(name, source, version, name);
      });
      result = newResult;
    }

    var realLockFile = new LockFile.empty();
    if (lockfile != null) {
      lockfile.forEach((name, version) {
        version = new Version.parse(version);
        realLockFile.packages[name] =
          new PackageId(name, source1, version, name);
      });
    }

    // Resolve the versions.
    var future = resolveVersions(sources, root, realLockFile);

    if (result != null) {
      expect(future, completion(predicate((actualResult) {
        for (var actualId in actualResult) {
          if (!result.containsKey(actualId.name)) return false;
          var expectedId = result.remove(actualId.name);
          if (actualId != expectedId) return false;
        }
        return result.isEmpty;
      }, 'packages to match $result')));
    } else if (error == noVersion) {
      expect(future, throwsA(isNoVersionException));
    } else if (error == disjointConstraint) {
      expect(future, throwsA(isDisjointConstraintException));
    } else if (error == sourceMismatch) {
      expect(future, throwsA(isSourceMismatchException));
    } else if (error == descriptionMismatch) {
      expect(future, throwsA(isDescriptionMismatchException));
    } else if (error == couldNotSolve) {
      expect(future, throwsA(isCouldNotSolveException));
    } else {
      expect(future, throwsA(error));
    }

    // If we aren't expecting an error, print some debugging info if we get one.
    if (error == null) {
      future.handleException((ex) {
        print(ex);
        print(future.stackTrace);
        return true;
      });
    }
  });
}

/**
 * A source used for testing. This both creates mock package objects and acts as
 * a source for them.
 *
 * In order to support testing packages that have the same name but different
 * descriptions, a package's name is calculated by taking the description string
 * and stripping off any trailing hyphen followed by non-hyphen characters.
 */
class MockSource extends Source {
  final Map<String, Map<Version, Package>> _packages;

  final String name;
  bool get shouldCache => true;

  MockSource(this.name)
      : _packages = <String, Map<Version, Package>>{};

  Future<List<Version>> getVersions(String name, String description) {
    return fakeAsync(() => _packages[description].keys);
  }

  Future<Pubspec> describe(PackageId id) {
    return fakeAsync(() {
      return _packages[id.name][id.version].pubspec;
    });
  }

  Future<bool> install(PackageId id, String path) {
    throw 'no';
  }

  Package mockPackage(String description, String version,
      Map dependencyStrings) {
    // Build the pubspec dependencies.
    var dependencies = <PackageRef>[];
    dependencyStrings.forEach((name, constraint) {
      var parsed = parseSource(name);
      var description = parsed.first;
      var packageName = description.replaceFirst(new RegExp(r"-[^-]+$"), "");
      dependencies.add(new PackageRef(packageName, parsed.last,
          new VersionConstraint.parse(constraint), description));
    });

    var pubspec = new Pubspec(
        description, new Version.parse(version), dependencies);
    return new Package.inMemory(pubspec);
  }

  void addPackage(Package package) {
    _packages.putIfAbsent(package.name, () => new Map<Version, Package>());
    _packages[package.name][package.version] = package;
  }
}

/**
 * A source used for testing that doesn't natively understand versioning,
 * similar to how the Git and SDK sources work.
 */
class MockVersionlessSource extends Source {
  final Map<String, Package> _packages;

  final String name = 'versionless';
  final bool shouldCache = false;

  MockVersionlessSource()
    : _packages = <String, Package>{};

  Future<bool> install(PackageId id, String path) {
    throw 'no';
  }

  Future<Pubspec> describe(PackageId id) {
    return new Future<Pubspec>.immediate(_packages[id.description].pubspec);
  }

  void addPackage(Package package) {
    _packages[package.name] = package;
  }
}

Future fakeAsync(callback()) {
  var completer = new Completer();
  new Timer(0, (_) {
    completer.complete(callback());
  });

  return completer.future;
}

Pair<String, Source> parseSource(String name) {
  var match = new RegExp(r"(.*) from (.*)").firstMatch(name);
  if (match == null) return new Pair<String, Source>(name, source1);
  switch (match[2]) {
  case 'mock1': return new Pair<String, Source>(match[1], source1);
  case 'mock2': return new Pair<String, Source>(match[1], source2);
  case 'root': return new Pair<String, Source>(match[1], rootSource);
  case 'versionless':
    return new Pair<String, Source>(match[1], versionlessSource);
  }
}
