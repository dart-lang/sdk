// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'configuration.dart';
import 'environment.dart';
import 'expectation.dart';
import 'status_file.dart';

/// Tracks the [Expectation]s associated with a set of file paths.
///
/// For any given file path, returns the expected test results for that file.
/// A set can be loaded from a collection of status files. A file path may
/// exist in multiple files (or even multiple sections within the file). When
/// that happens, all of the expectations of every entry are combined.
class ExpectationSet {
  /// Reads the expectations defined by the status files at [statusFilePaths]
  /// when in [configuration].
  static ExpectationSet read(
      List<String> statusFilePaths, Configuration configuration) {
    var environment = new Environment(configuration);
    var expectations = new ExpectationSet._();
    for (var path in statusFilePaths) {
      var file = new StatusFile.read(path);
      for (var section in file.sections) {
        if (section.isEnabled(environment)) {
          for (var entry in section.entries) {
            expectations.addEntry(entry);
          }
        }
      }
    }

    return expectations;
  }

  // Only create one copy of each Set<Expectation>.
  // We just use .toString as a key, so we may make a few
  // sets that only differ in their toString element order.
  static Map<String, Set<Expectation>> _cachedSets = {};

  Map<String, Set<Expectation>> _map = {};
  Map<String, List<RegExp>> _keyToRegExps;

  /// Create a TestExpectations object. See the [expectations] method
  /// for an explanation of matching.
  ExpectationSet._();

  /// Add [entry] to the set of expectations.
  void addEntry(StatusEntry entry) {
    // Once we have started using the expectations we cannot add more
    // rules.
    if (_keyToRegExps != null) {
      throw new StateError("Cannot add entries after it is already in use.");
    }

    _map
        .putIfAbsent(entry.path, () => new Set<Expectation>())
        .addAll(entry.expectations);
  }

  /// Get the expectations for the test at [path].
  ///
  /// For every (key, expectation) pair, matches the key with the file name.
  /// Returns the union of the expectations for all the keys that match.
  ///
  /// Normal matching splits the key and the filename into path components and
  /// checks that the anchored regular expression "^$keyComponent\$" matches
  /// the corresponding filename component.
  Set<Expectation> expectations(String path) {
    var result = new Set<Expectation>();
    var parts = path.split('/');

    // Create mapping from keys to list of RegExps once and for all.
    _preprocessForMatching();

    _map.forEach((key, expectations) {
      var regExps = _keyToRegExps[key];
      if (regExps.length > parts.length) return;

      for (var i = 0; i < regExps.length; i++) {
        if (!regExps[i].hasMatch(parts[i])) return;
      }

      // If all components of the status file key matches the filename
      // add the expectations to the result.
      result.addAll(expectations);
    });

    // If no expectations were found the expectation is that the test
    // passes.
    if (result.isEmpty) {
      result.add(Expectation.pass);
    }
    return _cachedSets.putIfAbsent(result.toString(), () => result);
  }

  /// Preprocesses the expectations for matching against filenames. Generates
  /// lists of regular expressions once and for all for each key.
  void _preprocessForMatching() {
    if (_keyToRegExps != null) return;

    _keyToRegExps = {};
    var regExpCache = <String, RegExp>{};

    _map.forEach((key, expectations) {
      if (_keyToRegExps[key] != null) return;
      var splitKey = key.split('/');
      var regExps = new List<RegExp>(splitKey.length);

      for (var i = 0; i < splitKey.length; i++) {
        var component = splitKey[i];
        var regExp = regExpCache.putIfAbsent(component,
            () => new RegExp("^${splitKey[i]}\$".replaceAll('*', '.*')));
        regExps[i] = regExp;
      }

      _keyToRegExps[key] = regExps;
    });
  }
}
