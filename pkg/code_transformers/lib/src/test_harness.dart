// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utilities for creating unit tests of Barback transformers.
library code_transformers.src.test_harness;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:unittest/unittest.dart';

String idToString(AssetId id) => '${id.package}|${id.path}';
AssetId idFromString(String s) {
  int index = s.indexOf('|');
  return new AssetId(s.substring(0, index), s.substring(index + 1));
}

String _removeTrailingWhitespace(String str) =>
    str.splitMapJoin('\n',
        onNonMatch: (s) => s.replaceAll(new RegExp(r'\s+$'), ''));

/// A helper package provider that has files stored in memory, also wraps
/// [Barback] to simply our tests.
class TestHelper implements PackageProvider {

  /// Maps from an asset string identifier of the form 'package|path' to the
  /// file contents.
  final Map<String, String> files;
  final Iterable<String> packages;
  final List<String> messages;
  int messagesSeen = 0;
  bool errorSeen = false;

  Barback barback;
  var errorSubscription;
  var resultSubscription;
  var logSubscription;

  Future<Asset> getAsset(AssetId id) =>
      new Future.value(new Asset.fromString(id, files[idToString(id)]));

  TestHelper(List<List<Transformer>> transformers, Map<String, String> files,
      this.messages)
      : files = files,
        packages = files.keys.map((s) => idFromString(s).package) {
    barback = new Barback(this);
    for (var p in packages) {
      barback.updateTransformers(p, transformers);
    }

    errorSubscription = barback.errors.listen((e) {
      var trace = null;
      if (e is Error) trace = e.stackTrace;
      if (trace != null) {
        print(Trace.format(trace));
      }
      fail('error running barback: $e');
    });

    resultSubscription = barback.results.listen((result) {
      expect(result.succeeded, !errorSeen, reason: "${result.errors}");
    });

    logSubscription = barback.log.listen((entry) {
      // Ignore info messages.
      if (entry.level == LogLevel.INFO) return;
      if (entry.level == LogLevel.ERROR) errorSeen = true;
      // We only check messages when an expectation is provided.
      if (messages == null) return;

      var msg = '${entry.level.name.toLowerCase()}: ${entry.message}';
      var span = entry.span;
      var spanInfo = span == null ? '' :
          ' (${span.sourceUrl} ${span.start.line} ${span.start.column})';
      expect(messagesSeen, lessThan(messages.length),
          reason: 'more messages than expected.\nMessage seen: $msg$spanInfo');
      expect('$msg$spanInfo', messages[messagesSeen++]);
    });
  }

  void tearDown() {
    errorSubscription.cancel();
    resultSubscription.cancel();
    logSubscription.cancel();
  }

  /// Tells barback which files have changed, and thus anything that depends on
  /// it on should be computed. By default mark all the input files.
  void run([Iterable<String> paths]) {
    if (paths == null) paths = files.keys;
    barback.updateSources(paths.map(idFromString));
  }

  Future<String> operator [](String assetString){
    return barback.getAssetById(idFromString(assetString))
        .then((asset) => asset.readAsString());
  }

  Future check(String assetIdString, String content) {
    return this[assetIdString].then((value) {
      value = _removeTrailingWhitespace(value);
      content = _removeTrailingWhitespace(content);
      expect(value, content, reason: 'Final output of $assetIdString differs.');
    });
  }

  Future checkAll(Map<String, String> files) {
    return barback.results.first.then((_) {
      if (files == null) return null;
      var futures = [];
      files.forEach((k, v) {
        futures.add(check(k, v));
      });
      return Future.wait(futures);
    }).then((_) {
      // We only check messages when an expectation is provided.
      if (messages == null) return;
      expect(messagesSeen, messages.length,
          reason: 'less messages than expected');
    });
  }
}
