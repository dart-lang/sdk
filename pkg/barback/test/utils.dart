// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.utils;

import 'dart:async';
import 'dart:convert' show Encoding;

import 'package:barback/barback.dart';
import 'package:barback/src/utils.dart';
import 'package:barback/src/utils/cancelable_future.dart';
import 'package:path/path.dart' as pathos;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/compact_vm_config.dart';

export 'transformer/bad.dart';
export 'transformer/bad_log.dart';
export 'transformer/catch_asset_not_found.dart';
export 'transformer/check_content.dart';
export 'transformer/check_content_and_rename.dart';
export 'transformer/conditionally_consume_primary.dart';
export 'transformer/create_asset.dart';
export 'transformer/declare_assets.dart';
export 'transformer/declaring_bad.dart';
export 'transformer/declaring_check_content_and_rename.dart';
export 'transformer/declaring_rewrite.dart';
export 'transformer/emit_nothing.dart';
export 'transformer/has_input.dart';
export 'transformer/lazy_assets.dart';
export 'transformer/lazy_bad.dart';
export 'transformer/lazy_check_content_and_rename.dart';
export 'transformer/lazy_many_to_one.dart';
export 'transformer/lazy_rewrite.dart';
export 'transformer/many_to_one.dart';
export 'transformer/mock.dart';
export 'transformer/one_to_many.dart';
export 'transformer/rewrite.dart';
export 'transformer/sync_rewrite.dart';

var _configured = false;

MockProvider _provider;
Barback _barback;

/// Calls to [buildShouldSucceed] and [buildShouldFail] set expectations on
/// successive [BuildResult]s from [_barback]. This keeps track of how many
/// calls have already been made so later calls know which result to look for.
int _nextBuildResult;

/// Calls to [buildShouldLog] set expectations on successive log entries from
/// [_barback]. This keeps track of how many calls have already been made so
/// later calls know which result to look for.
int _nextLog;

void initConfig() {
  if (_configured) return;
  _configured = true;
  useCompactVMConfiguration();
  filterStacks = true;
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

  _provider = new MockProvider(assets, additionalPackages: transformers.keys);
  _barback = new Barback(_provider);
  // Add a dummy listener to the log so it doesn't print to stdout.
  _barback.log.listen((_) {});
  _nextBuildResult = 0;
  _nextLog = 0;

  schedule(() => transformers.forEach(_barback.updateTransformers));

  // There should be one successful build after adding all the transformers but
  // before adding any sources.
  if (!transformers.isEmpty) buildShouldSucceed();
}

/// Updates [assets] in the current [PackageProvider].
///
/// Each item in the list may either be an [AssetId] or a string that can be
/// parsed as one.
void updateSources(Iterable assets) {
  assets = _parseAssets(assets);
  schedule(() => _barback.updateSources(assets),
      "updating ${assets.join(', ')}");
}

/// Updates [assets] in the current [PackageProvider].
///
/// Each item in the list may either be an [AssetId] or a string that can be
/// parsed as one. Unlike [updateSources], this is not automatically scheduled
/// and will be run synchronously when called.
void updateSourcesSync(Iterable assets) =>
    _barback.updateSources(_parseAssets(assets));

/// Removes [assets] from the current [PackageProvider].
///
/// Each item in the list may either be an [AssetId] or a string that can be
/// parsed as one.
void removeSources(Iterable assets) {
  assets = _parseAssets(assets);
  schedule(() => _barback.removeSources(assets),
      "removing ${assets.join(', ')}");
}

/// Removes [assets] from the current [PackageProvider].
///
/// Each item in the list may either be an [AssetId] or a string that can be
/// parsed as one. Unlike [removeSources], this is not automatically scheduled
/// and will be run synchronously when called.
void removeSourcesSync(Iterable assets) =>
    _barback.removeSources(_parseAssets(assets));

/// Sets the transformers for [package] to [transformers].
void updateTransformers(String package, Iterable<Iterable> transformers) {
  schedule(() => _barback.updateTransformers(package, transformers),
      "updating transformers for $package");
}

/// Parse a list of strings or [AssetId]s into a list of [AssetId]s.
List<AssetId> _parseAssets(Iterable assets) {
  return assets.map((asset) {
    if (asset is String) return new AssetId.parse(asset);
    return asset;
  }).toList();
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

/// Schedules an error to be generated when loading the asset identified by
/// [name].
///
/// Does not update the asset in the graph. If [async] is true, the error is
/// thrown asynchronously.
void setAssetError(String name, {bool async: true}) {
  schedule(() {
    _provider._setAssetError(name, async);
  }, "set error for asset $name");
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
  _futureShouldNotCompleteUntil(
      _barback.results.elementAt(_nextBuildResult),
      schedule(() => pumpEventQueue(), "build should not terminate"),
      "build");
}

/// Expects that the next [BuildResult] is a build success.
void buildShouldSucceed() {
  expect(_getNextBuildResult("build should succeed").then((result) {
    result.errors.forEach(currentSchedule.signalError);
    expect(result.succeeded, isTrue);
  }), completes);
}

/// Expects that the next [BuildResult] emitted is a failure.
///
/// [matchers] is a list of matchers to match against the errors that caused the
/// build to fail. Every matcher is expected to match an error, but the order of
/// matchers is unimportant.
void buildShouldFail(List matchers) {
  expect(_getNextBuildResult("build should fail").then((result) {
    expect(result.succeeded, isFalse);
    expect(result.errors.length, equals(matchers.length));
    for (var matcher in matchers) {
      expect(result.errors, contains(matcher));
    }
  }), completes);
}

/// Expects that the nexted logged [LogEntry] matches [matcher] which may be
/// either a [Matcher] or a string to match a literal string.
void buildShouldLog(LogLevel level, matcher) {
  expect(_getNextLog("build should log").then((log) {
    expect(log.level, equals(level));
    expect(log.message, matcher);
  }), completes);
}

Future<BuildResult> _getNextBuildResult(String description) {
  var result = currentSchedule.wrapFuture(
      _barback.results.elementAt(_nextBuildResult++));
  return schedule(() => result, description);
}

Future<LogEntry> _getNextLog(String description) {
  var result = currentSchedule.wrapFuture(
      _barback.log.elementAt(_nextLog++));
  return schedule(() => result, description);
}

/// Schedules an expectation that the graph will deliver an asset matching
/// [name] and [contents].
///
/// [contents] may be a [String] or a [Matcher] that matches a string. If
/// [contents] is omitted, defaults to the asset's filename without an extension
/// (which is the same default that [initGraph] uses).
void expectAsset(String name, [contents]) {
  var id = new AssetId.parse(name);

  if (contents == null) {
    contents = pathos.basenameWithoutExtension(id.path);
  }

  schedule(() {
    return _barback.getAssetById(id).then((asset) {
      // TODO(rnystrom): Make an actual Matcher class for this.
      expect(asset.id, equals(id));
      expect(asset.readAsString(), completion(contents));
    });
  }, "get asset $name");
}

/// Schedules an expectation that the graph will not find an asset matching
/// [name].
void expectNoAsset(String name) {
  var id = new AssetId.parse(name);

  // Make sure the future gets the error.
  schedule(() {
    return _barback.getAssetById(id).then((asset) {
      fail("Should have thrown error but got $asset.");
    }).catchError((error) {
      expect(error, new isInstanceOf<AssetNotFoundException>());
      expect(error.id, equals(id));
    });
  }, "get asset $name");
}

/// Schedules an expectation that the graph will output all of the given
/// assets, and no others.
///
/// [assets] may be an iterable of asset id strings, in which case this asserts
/// that the graph outputs exactly the assets with those ids. It may also be a
/// map from asset id strings to asset contents, in which case the contents must
/// also match.
void expectAllAssets(assets) {
  var expected;
  var expectedString;
  if (assets is Map) {
    expected = mapMapKeys(assets, (key, _) => new AssetId.parse(key));
    expectedString = expected.toString();
  } else {
    expected = assets.map((asset) => new AssetId.parse(asset));
    expectedString = expected.join(', ');
  }

  schedule(() {
    return _barback.getAllAssets().then((actualAssets) {
      var actualIds = actualAssets.map((asset) => asset.id).toSet();

      if (expected is Map) {
        expected.forEach((id, contents) {
          expect(actualIds, contains(id));
          actualIds.remove(id);
          expect(actualAssets[id].readAsString(), completion(equals(contents)));
        });
      } else {
        for (var id in expected) {
          expect(actualIds, contains(id));
          actualIds.remove(id);
        }
      }

      expect(actualIds, isEmpty);
    });
  }, "get all assets, expecting $expectedString");
}

/// Schedules an expectation that [Barback.getAllAssets] will return a [Future]
/// that completes to a error that matches [matcher].
///
/// If [match] is a [List], then it expects the completed error to be an
/// [AggregateException] whose errors match each matcher in the list. Otherwise,
/// [match] should be a single matcher that the error should match.
void expectAllAssetsShouldFail(Matcher matcher) {
  schedule(() {
    expect(_barback.getAllAssets(), throwsA(matcher));
  }, "get all assets should fail");
}

/// Schedules an expectation that a [getAssetById] call for the given asset
/// won't terminate at this point in the schedule.
void expectAssetDoesNotComplete(String name) {
  var id = new AssetId.parse(name);

  schedule(() {
    return _futureShouldNotCompleteUntil(
        _barback.getAssetById(id),
        pumpEventQueue(),
        "asset $id");
  }, "asset $id should not complete");
}

/// Returns a matcher for an [AggregateException] containing errors that match
/// [matchers].
Matcher isAggregateException(Iterable<Matcher> errors) {
  // Match the aggregate error itself.
  var matchers = [
    new isInstanceOf<AggregateException>(),
    transform((error) => error.errors, hasLength(errors.length),
        'errors.length == ${errors.length}')
  ];

  // Make sure its contained errors match the matchers.
  for (var error in errors) {
    matchers.add(transform((error) => error.errors, contains(error),
        error.toString()));
  }

  return allOf(matchers);
}

/// Returns a matcher for an [AssetNotFoundException] with the given [id].
Matcher isAssetNotFoundException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<AssetNotFoundException>(),
      predicate((error) => error.id == id, 'id == $name'));
}

/// Returns a matcher for an [AssetCollisionException] with the given [id].
Matcher isAssetCollisionException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<AssetCollisionException>(),
      predicate((error) => error.id == id, 'id == $name'));
}

/// Returns a matcher for a [MissingInputException] with the given [id].
Matcher isMissingInputException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<MissingInputException>(),
      predicate((error) => error.id == id, 'id == $name'));
}

/// Returns a matcher for an [InvalidOutputException] with the given id.
Matcher isInvalidOutputException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<InvalidOutputException>(),
      predicate((error) => error.id == id, 'id == $name'));
}

/// Returns a matcher for an [AssetLoadException] with the given id and a
/// wrapped error that matches [error].
Matcher isAssetLoadException(String name, error) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<AssetLoadException>(),
      transform((error) => error.id, equals(id), 'id'),
      transform((error) => error.error, wrapMatcher(error), 'error'));
}

/// Returns a matcher for a [TransformerException] with a wrapped error that
/// matches [error].
Matcher isTransformerException(error) {
  return allOf(
      new isInstanceOf<TransformerException>(),
      transform((error) => error.error, wrapMatcher(error), 'error'));
}

/// Returns a matcher for a [MockLoadException] with the given [id].
Matcher isMockLoadException(String name) {
  var id = new AssetId.parse(name);
  return allOf(
      new isInstanceOf<MockLoadException>(),
      predicate((error) => error.id == id, 'id == $name'));
}

/// Returns a matcher that runs [transformation] on its input, then matches
/// the output against [matcher].
///
/// [description] should be a noun phrase that describes the relation of the
/// output of [transformation] to its input.
Matcher transform(transformation(value), matcher, String description) =>
  new _TransformMatcher(transformation, wrapMatcher(matcher), description);

class _TransformMatcher extends Matcher {
  final Function _transformation;
  final Matcher _matcher;
  final String _description;

  _TransformMatcher(this._transformation, this._matcher, this._description);

  bool matches(item, Map matchState) =>
    _matcher.matches(_transformation(item), matchState);

  Description describe(Description description) =>
    description.add(_description).add(' ').addDescriptionOf(_matcher);
}

/// Asserts that [future] shouldn't complete until after [delay] completes.
///
/// Once [delay] completes, the output of [future] is ignored, even if it's an
/// error.
///
/// [description] should describe [future].
Future _futureShouldNotCompleteUntil(Future future, Future delay,
    String description) {
  var trace = new Trace.current();
  var cancelable = new CancelableFuture(future);
  cancelable.then((result) {
    currentSchedule.signalError(
        new Exception("Expected $description not to complete here, but it "
            "completed with result: $result"),
        trace);
  }).catchError((error) {
    currentSchedule.signalError(error);
  });

  return delay.then((_) => cancelable.cancel());
}

/// An [AssetProvider] that provides the given set of assets.
class MockProvider implements PackageProvider {
  Iterable<String> get packages => _assets.keys;

  final Map<String, AssetSet> _assets;

  /// The set of assets for which [MockLoadException]s should be emitted if
  /// they're loaded.
  final _errors = new Set<AssetId>();

  /// The set of assets for which synchronous [MockLoadException]s should be
  /// emitted if they're loaded.
  final _syncErrors = new Set<AssetId>();

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

  MockProvider(assets, {Iterable<String> additionalPackages})
      : _assets = _normalizeAssets(assets, additionalPackages);

  static Map<String, AssetSet> _normalizeAssets(assets,
      Iterable<String> additionalPackages) {
    var assetList;
    if (assets is Map) {
      assetList = assets.keys.map((asset) {
        var id = new AssetId.parse(asset);
        return new _MockAsset(id, assets[asset]);
      });
    } else if (assets is Iterable) {
      assetList = assets.map((asset) {
        var id = new AssetId.parse(asset);
        var contents = pathos.basenameWithoutExtension(id.path);
        return new _MockAsset(id, contents);
      });
    }

    var assetMap = mapMapValues(groupBy(assetList, (asset) => asset.id.package),
        (package, assets) => new AssetSet.from(assets));

    // Make sure that packages that have transformers but no assets are
    // considered by MockProvider to exist.
    if (additionalPackages != null) {
      for (var package in additionalPackages) {
        assetMap.putIfAbsent(package, () => new AssetSet());
      }
    }

    // If there are no assets or transformers, add a dummy package. This better
    // simulates the real world, where there'll always be at least the
    // entrypoint package.
    return assetMap.isEmpty ? {"app": new AssetSet()} : assetMap;
  }

  void _modifyAsset(String name, String contents) {
    var id = new AssetId.parse(name);
    _errors.remove(id);
    _syncErrors.remove(id);
    (_assets[id.package][id] as _MockAsset).contents = contents;
  }

  void _setAssetError(String name, bool async) {
    (async ? _errors : _syncErrors).add(new AssetId.parse(name));
  }

  List<AssetId> listAssets(String package, {String within}) {
    if (within != null) {
      throw new UnimplementedError("Doesn't handle 'within' yet.");
    }

    return _assets[package].map((asset) => asset.id);
  }

  Future<Asset> getAsset(AssetId id) {
    // Eagerly load the asset so we can test an asset's value changing between
    // when a load starts and when it finishes.
    var assets = _assets[id.package];
    var asset;
    if (assets != null) asset = assets[id];

    if (_syncErrors.contains(id)) throw new MockLoadException(id);
    var hasError = _errors.contains(id);

    var future;
    if (_pauseCompleter != null) {
      future = _pauseCompleter.future;
    } else {
      future = new Future.value();
    }

    return future.then((_) {
      if (hasError) throw new MockLoadException(id);
      if (asset == null) throw new AssetNotFoundException(id);
      return asset;
    });
  }
}

/// Error thrown for assets with [setAssetError] set.
class MockLoadException implements Exception {
  final AssetId id;

  MockLoadException(this.id);

  String toString() => "Error loading $id.";
}

/// An implementation of [Asset] that never hits the file system.
class _MockAsset implements Asset {
  final AssetId id;
  String contents;

  _MockAsset(this.id, this.contents);

  Future<String> readAsString({Encoding encoding}) =>
      new Future.value(contents);

  Stream<List<int>> read() => throw new UnimplementedError();

  String toString() => "MockAsset $id $contents";
}
