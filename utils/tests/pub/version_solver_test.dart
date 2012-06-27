// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('pub_update_test');

#import('dart:io');
#import('dart:isolate');

#import('../../pub/package.dart');
#import('../../pub/pubspec.dart');
#import('../../pub/source.dart');
#import('../../pub/source_registry.dart');
#import('../../pub/version.dart');
#import('../../pub/version_solver.dart');
#import('../../../lib/unittest/unittest.dart');

final noVersion = 'no version';
final disjointConstraint = 'disjoint';
final couldNotSolve = 'unsolved';

main() {
  testResolve('no dependencies', {
    'myapp 0.0.0': {}
  }, result: {
    'myapp': '0.0.0'
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
    'myapp': '0.0.0',
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
    'myapp': '0.0.0',
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
    'myapp': '0.0.0',
    'foo': '1.0.1',
    'bar': '1.0.0',
    'bang': '1.0.0'
  });

  testResolve('dependency back onto root package', {
    'myapp 1.0.0': {
      'foo': '1.0.0'
    },
    'foo 1.0.0': {
      'myapp': '>=1.0.0'
    }
  }, result: {
    'myapp': '1.0.0',
    'foo': '1.0.0'
  });

  testResolve("dependency back onto root package that doesn't contain root's "
              "version", {
    'myapp 1.0.0': {
      'foo': '1.0.0'
    },
    'foo 1.0.0': {
      'myapp': '>=2.0.0'
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

testResolve(description, packages, [result, error]) {
  test(description, () {
    var sources = new SourceRegistry();
    var source = new MockSource();
    sources.register(source);
    sources.setDefault(source.name);

    // Build the test package graph.
    var root;
    packages.forEach((nameVersion, dependencies) {
      var parts = nameVersion.split(' ');
      var name = parts[0];
      var version = parts[1];
      var package = source.mockPackage(name, version, dependencies);
      if (name == 'myapp') {
        // Don't add the root package to the server, so we can verify that Pub
        // doesn't try to look up information about the local package on the
        // remote server.
        root = package;
      } else {
        source.addPackage(package);
      }
    });

    // Clean up the expectation.
    if (result != null) {
      result.forEach((name, version) {
        result[name] = new Version.parse(version);
      });
    }

    // Resolve the versions.
    var future = resolveVersions(sources, root);

    if (result != null) {
      expect(future, completion(equals(result)));
    } else if (error == noVersion) {
      expect(future, throwsA(new isInstanceOf<NoVersionException>()));
    } else if (error == disjointConstraint) {
      expect(future, throwsA(new isInstanceOf<DisjointConstraintException>()));
    } else if (error == couldNotSolve) {
      expect(future, throwsA(new isInstanceOf<CouldNotSolveException>()));
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

class MockSource extends Source {
  final Map<String, Map<Version, Package>> _packages;

  String get name() => 'mock';
  bool get shouldCache() => true;

  MockSource()
      : _packages = <Map<Version, Package>>{};

  Future<List<Version>> getVersions(String name) {
    return fakeAsync(() => _packages[name].getKeys());
  }

  Future<Pubspec> describe(String package, Version version) {
    return fakeAsync(() {
      return _packages[package][version].pubspec;
    });
  }

  Future<bool> install(PackageId id, String path) {
    throw 'no';
  }

  Package mockPackage(String name, String version, Map dependencyStrings) {
    // Build the pubspec dependencies.
    var dependencies = <PackageRef>[];
    dependencyStrings.forEach((name, constraint) {
      dependencies.add(new PackageRef(name, this,
          new VersionConstraint.parse(constraint), name));
    });

    var pubspec = new Pubspec(new Version.parse(version), dependencies);
    return new Package.inMemory(name, pubspec);
  }

  void addPackage(Package package) {
    _packages.putIfAbsent(package.name, () => new Map<Version, Package>());
    _packages[package.name][package.version] = package;
    return package;
  }
}

Future fakeAsync(callback()) {
  var completer = new Completer();
  new Timer(0, (_) {
    completer.complete(callback());
  });

  return completer.future;
}