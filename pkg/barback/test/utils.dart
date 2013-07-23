// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.utils;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:barback/barback.dart';
import 'package:barback/src/asset_cascade.dart';
import 'package:barback/src/package_graph.dart';
import 'package:barback/src/utils.dart';
import 'package:path/path.dart' as pathos;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/compact_vm_config.dart';

var _configured = false;

MockProvider _provider;
PackageGraph _graph;

/// Calls to [buildShouldSucceed] and [buildShouldFail] set expectations on
/// successive [BuildResult]s from [_graph]. This keeps track of how many calls
/// have already been made so later calls know which result to look for.
int _nextBuildResult;

void initConfig() {
  if (_configured) return;
  _configured = true;
  useCompactVMConfiguration();
}

/// Creates a new [PackageProvider] and [PackageGraph] with the given [assets]
/// and [transformers].
///
/// This graph is used internally by most of the other functions in this
/// library so you must call it in the test before calling any of the other
/// functions.
///
/// [assets] may either be an [Iterable] or a [Map]. If it's an [Iterable],
/// each element may either be an [AssetId] or a string that can be parsed to
/// one. If it's a [Map], each key should be a string that can be parsed to an
/// [AssetId] and the value should be a string defining the contents of that
/// asset.
///
/// [transformers] is a map from package names to the transformers for each
/// package.
void initGraph([assets,
    Map<String, Iterable<Iterable<Transformer>>> transformers]) {
  if (assets == null) assets = [];
  if (transformers == null) transformers = {};

  _provider = new MockProvider(assets, transformers);
  _graph = new PackageGraph(_provider);
  _nextBuildResult = 0;
}

/// Updates [assets] in the current [PackageProvider].
///
/// Each item in the list may either be an [AssetId] or a string that can be
/// parsed as one. Note that this method is not automatically scheduled.
void updateSources(Iterable assets) {
  // Allow strings as asset IDs.
  assets = assets.map((asset) {
    if (asset is String) return new AssetId.parse(asset);
    return asset;
  });

  _graph.updateSources(assets);
}

/// Removes [assets] from the current [PackageProvider].
///
/// Each item in the list may either be an [AssetId] or a string that can be
/// parsed as one. Note that this method is not automatically scheduled.
void removeSources(Iterable assets) {
  // Allow strings as asset IDs.
  assets = assets.map((asset) {
    if (asset is String) return new AssetId.parse(asset);
    return asset;
  });

  _graph.removeSources(assets);
}

/// Schedules a change to the contents of an asset identified by [name] to
/// [contents].
///
/// Does not update it in the graph.
void modifyAsset(String name, String contents) {
  schedule(() {
    _provider._modifyAsset(name, contents);
  }, "modify asset $name");
}

/// Schedules a pause of the internally created [PackageProvider].
///
/// All asset requests that the [PackageGraph] makes to the provider after this
/// will not complete until [resumeProvider] is called.
void pauseProvider() {
  schedule(() => _provider._pause(), "pause provider");
}

/// Schedules an unpause of the provider after a call to [pauseProvider] and
/// allows all pending asset loads to finish.
void resumeProvider() {
  schedule(() => _provider._resume(), "resume provider");
}

/// Asserts that the current build step shouldn't have finished by this point in
/// the schedule.
///
/// This uses the same build counter as [buildShouldSucceed] and
/// [buildShouldFail], so those can be used to validate build results before and
/// after this.
void buildShouldNotBeDone() {
  var resultAllowed = false;
  var trace = new Trace.current();
  _graph.results.elementAt(_nextBuildResult).then((result) {
    if (resultAllowed) return;

    currentSchedule.signalError(
        new Exception("Expected build not to terminate "
            "here, but it terminated with result: $result"), trace);
  }).catchError((error) {
    if (resultAllowed) return;
    currentSchedule.signalError(error);
  });

  schedule(() {
    // Pump the event queue in case the build completes out-of-band after we get
    // here. If it does, we want to signal an error.
    return pumpEventQueue().then((_) {
      resultAllowed = true;
    });
  }, "ensuring build doesn't terminate");
}

/// Expects that the next [BuildResult] is a build success.
void buildShouldSucceed() {
  expect(_getNextBuildResult().then((result) {
    expect(result.succeeded, isTrue);
  }), completes);
}

/// Expects that the next [BuildResult] emitted is a failure.
///
/// [matchers] is a list of matchers to match against the errors that caused the
/// build to fail. Every matcher is expected to match an error, but the order of
/// matchers is unimportant.
void buildShouldFail(List matchers) {
  expect(_getNextBuildResult().then((result) {
    expect(result.succeeded, isFalse);
    expect(result.errors.length, equals(matchers.length));
    for (var matcher in matchers) {
      expect(result.errors, contains(matcher));
    }
  }), completes);
}

Future<BuildResult> _getNextBuildResult() =>
  _graph.results.elementAt(_nextBuildResult++);

/// Pauses the schedule until the currently running build completes.
///
/// Validates that the build completed successfully.
void waitForBuild() {
  schedule(() {
    return _graph.results.first.then((result) {
      expect(result.succeeded, isTrue);
    });
  }, "wait for build");
}

/// Schedules an expectation that the graph will deliver an asset matching
/// [name] and [contents].
///
/// If [contents] is omitted, defaults to the asset's filename without an
/// extension (which is the same default that [initGraph] uses).
void expectAsset(String name, [String contents]) {
  var id = new AssetId.parse(name);

  if (contents == null) {
    contents = pathos.basenameWithoutExtension(id.path);
  }

  schedule(() {
    return _graph.getAssetById(id).then((asset) {
      // TODO(rnystrom): Make an actual Matcher class for this.
      expect(asset, new isInstanceOf<MockAsset>());
      expect(asset.id, equals(id));
      expect(asset.contents, equals(contents));
    });
  }, "get asset $name");
}

/// Schedules an expectation that the graph will not find an asset matching
/// [name].
void expectNoAsset(String name) {
  var id = new AssetId.parse(name);

  // Make sure the future gets the error.
  schedule(() {
    return _graph.getAssetById(id).then((asset) {
      fail("Should have thrown error but got $asset.");
    }).catchError((error) {
      expect(error, new isInstanceOf<AssetNotFoundException>());
      expect(error.id, equals(id));
    });
  }, "get asset $name");
}

/// Returns a matcher for an [AssetNotFoundException] with the given [id].
Matcher isAssetNotFoundException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<AssetNotFoundException>(),
      predicate((error) => error.id == id, 'id is $name'));
}

/// Returns a matcher for an [AssetCollisionException] with the given [id].
Matcher isAssetCollisionException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<AssetCollisionException>(),
      predicate((error) => error.id == id, 'id is $name'));
}

/// Returns a matcher for a [MissingInputException] with the given [id].
Matcher isMissingInputException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<MissingInputException>(),
      predicate((error) => error.id == id, 'id is $name'));
}

/// Returns a matcher for an [InvalidOutputException] with the given id and
/// package name.
Matcher isInvalidOutputException(String package, String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<InvalidOutputException>(),
      predicate((error) => error.package == package, 'package is $package'),
      predicate((error) => error.id == id, 'id is $name'));
}

/// An [AssetProvider] that provides the given set of assets.
class MockProvider implements PackageProvider {
  Iterable<String> get packages => _packages.keys;

  Map<String, _MockPackage> _packages;

  /// The completer that [getAsset()] is waiting on to complete when paused.
  ///
  /// If `null` it will return the asset immediately.
  Completer _pauseCompleter;

  /// Tells the provider to wait during [getAsset] until [complete()]
  /// is called.
  ///
  /// Lets you test the asynchronous behavior of loading.
  void _pause() {
    _pauseCompleter = new Completer();
  }

  void _resume() {
    _pauseCompleter.complete();
    _pauseCompleter = null;
  }

  MockProvider(assets,
      Map<String, Iterable<Iterable<Transformer>>> transformers) {
    var assetList;
    if (assets is Map) {
      assetList = assets.keys.map((asset) {
        var id = new AssetId.parse(asset);
        return new MockAsset(id, assets[asset]);
      });
    } else if (assets is Iterable) {
      assetList = assets.map((asset) {
        var id = new AssetId.parse(asset);
        var contents = pathos.basenameWithoutExtension(id.path);
        return new MockAsset(id, contents);
      });
    }

    _packages = mapMapValues(groupBy(assetList, (asset) => asset.id.package),
        (package, assets) {
      var packageTransformers = transformers[package];
      if (packageTransformers == null) packageTransformers = [];
      return new _MockPackage(assets, packageTransformers.toList());
    });

    // If there are no assets or transformers, add a dummy package. This better
    // simulates the real world, where there'll always be at least the
    // entrypoint package.
    if (_packages.isEmpty) _packages = {"app": new _MockPackage([], [])};
  }

  void _modifyAsset(String name, String contents) {
    var id = new AssetId.parse(name);
    var asset = _packages[id.package].assets.firstWhere((a) => a.id == id);
    asset.contents = contents;
  }

  List<AssetId> listAssets(String package, {String within}) {
    if (within != null) {
      throw new UnimplementedError("Doesn't handle 'within' yet.");
    }

    return _packages[package].assets.map((asset) => asset.id);
  }

  Iterable<Iterable<Transformer>> getTransformers(String package) {
    var mockPackage = _packages[package];
    if (mockPackage == null) {
      throw new ArgumentError("No package named $package.");
    }
    return mockPackage.transformers;
  }

  Future<Asset> getAsset(AssetId id) {
    var future;
    if (_pauseCompleter != null) {
      future = _pauseCompleter.future;
    } else {
      future = new Future.value();
    }

    return future.then((_) {
      var package = _packages[id.package];
      if (package == null) throw new AssetNotFoundException(id);

      return package.assets.firstWhere((asset) => asset.id == id,
          orElse: () => throw new AssetNotFoundException(id));
    });
  }
}

/// Used by [MockProvider] to keep track of which assets and transformers exist
/// for each package.
class _MockPackage {
  final List<MockAsset> assets;
  final List<List<Transformer>> transformers;

  _MockPackage(this.assets, Iterable<Iterable<Transformer>> transformers)
      : transformers = transformers.map((phase) => phase.toList()).toList();
}

/// A [Transformer] that takes assets ending with one extension and generates
/// assets with a given extension.
///
/// Appends the output extension to the contents of the input file.
class RewriteTransformer extends Transformer {
  final String from;
  final String to;

  /// The number of times the transformer has been applied.
  int numRuns = 0;

  /// The number of currently running transforms.
  int _runningTransforms = 0;

  /// The completer that the transform is waiting on to complete.
  ///
  /// If `null` the transform will complete immediately.
  Completer _wait;

  /// A future that completes when the first apply of this transformer begins.
  Future get started => _started.future;
  final _started = new Completer();

  /// Creates a transformer that rewrites assets whose extension is [from] to
  /// one whose extension is [to].
  ///
  /// [to] may be a space-separated list in which case multiple outputs will be
  /// created for each input.
  RewriteTransformer(this.from, this.to);

  /// `true` if any transforms are currently running.
  bool get isRunning => _runningTransforms > 0;

  /// Tells the transform to wait during its transformation until [complete()]
  /// is called.
  ///
  /// Lets you test the asynchronous behavior of transformers.
  void wait() {
    _wait = new Completer();
  }

  void complete() {
    _wait.complete();
    _wait = null;
  }

  Future<bool> isPrimary(Asset asset) {
    return new Future.value(asset.id.extension == ".$from");
  }

  Future apply(Transform transform) {
    numRuns++;
    if (!_started.isCompleted) _started.complete();
    _runningTransforms++;
    return transform.primaryInput.then((input) {
      return Future.wait(to.split(" ").map((extension) {
        var id = transform.primaryId.changeExtension(".$extension");
        return input.readAsString().then((content) {
          transform.addOutput(new MockAsset(id, "$content.$extension"));
        });
      })).then((_) {
        if (_wait != null) return _wait.future;
      });
    }).whenComplete(() {
      _runningTransforms--;
    });
  }

  String toString() => "$from->$to";
}

/// A [Transformer] that takes an input asset that contains a comma-separated
/// list of paths and outputs a file for each path.
class OneToManyTransformer extends Transformer {
  final String extension;

  /// The number of times the transformer has been applied.
  int numRuns = 0;

  /// Creates a transformer that consumes assets with [extension].
  ///
  /// That file contains a comma-separated list of paths and it will output
  /// files at each of those paths.
  OneToManyTransformer(this.extension);

  Future<bool> isPrimary(Asset asset) {
    return new Future.value(asset.id.extension == ".$extension");
  }

  Future apply(Transform transform) {
    numRuns++;
    return transform.primaryInput.then((input) {
      return input.readAsString().then((lines) {
        for (var line in lines.split(",")) {
          var id = new AssetId(transform.primaryId.package, line);
          transform.addOutput(new MockAsset(id, "spread $extension"));
        }
      });
    });
  }

  String toString() => "1->many $extension";
}

/// A transformer that uses the contents of a file to define the other inputs.
///
/// Outputs a file with the same name as the primary but with an "out"
/// extension containing the concatenated contents of all non-primary inputs.
class ManyToOneTransformer extends Transformer {
  final String extension;

  /// The number of times the transformer has been applied.
  int numRuns = 0;

  /// Creates a transformer that consumes assets with [extension].
  ///
  /// That file contains a comma-separated list of paths and it will input
  /// files at each of those paths.
  ManyToOneTransformer(this.extension);

  Future<bool> isPrimary(Asset asset) {
    return new Future.value(asset.id.extension == ".$extension");
  }

  Future apply(Transform transform) {
    numRuns++;
    return transform.primaryInput.then((primary) {
      return primary.readAsString().then((contents) {
        // Get all of the included inputs.
        var inputs = contents.split(",").map((path) {
          var id = new AssetId(transform.primaryId.package, path);
          return transform.getInput(id);
        });

        return Future.wait(inputs);
      }).then((inputs) {
        // Concatenate them to one output.
        var output = "";
        return Future.forEach(inputs, (input) {
          return input.readAsString().then((contents) {
            output += contents;
          });
        }).then((_) {
          var id = transform.primaryId.changeExtension(".out");
          transform.addOutput(new MockAsset(id, output));
        });
      });
    });
  }

  String toString() => "many->1 $extension";
}

/// A transformer that throws an exception when run, after generating the
/// given outputs.
class BadTransformer extends Transformer {
  /// The error it throws.
  static const ERROR = "I am a bad transformer!";

  /// The list of asset names that it should output.
  final List<String> outputs;

  BadTransformer(this.outputs);

  Future<bool> isPrimary(Asset asset) => new Future.value(true);
  Future apply(Transform transform) {
    return newFuture(() {
      // Create the outputs first.
      for (var output in outputs) {
        var id = new AssetId.parse(output);
        transform.addOutput(new MockAsset(id, output));
      }

      // Then fail.
      throw ERROR;
    });
  }
}

/// A transformer that outputs an asset with the given id.
class CreateAssetTransformer extends Transformer {
  final String output;

  CreateAssetTransformer(this.output);

  Future<bool> isPrimary(Asset asset) => new Future.value(true);

  Future apply(Transform transform) {
    return newFuture(() {
      transform.addOutput(new MockAsset(new AssetId.parse(output), output));
    });
  }
}

/// An implementation of [Asset] that never hits the file system.
class MockAsset implements Asset {
  final AssetId id;
  String contents;

  MockAsset(this.id, this.contents);

  Future<String> readAsString({Encoding encoding}) =>
      new Future.value(contents);

  Stream<List<int>> read() => throw new UnimplementedError();

  String toString() => "MockAsset $id $contents";
}