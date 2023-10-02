// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.suite;

import 'chain.dart' show Chain;

import 'test_dart.dart' show TestDart;

/// Records the properties of a test suite.
abstract class Suite {
  final String name;

  final String kind;

  final Uri? statusFile;

  Suite(this.name, this.kind, this.statusFile);

  factory Suite.fromJsonMap(Uri base, Map json) {
    String kind = json["kind"].toLowerCase();
    String name = json["name"];
    switch (kind) {
      case "dart":
        return Dart.fromJsonMap(base, json, name);

      case "chain":
        return Chain.fromJsonMap(base, json, name, kind);

      case "test_dart":
        return TestDart.fromJsonMap(base, json, name, kind);

      default:
        throw "Suite '$name' has unknown kind '$kind'.";
    }
  }

  @override
  String toString() => "Suite($name, $kind)";
}

/// A suite of standalone tests. The tests are combined and run as one program.
///
/// A standalone test is a test with a `main` method. The test is considered
/// successful if main doesn't throw an error (or if `main` returns a future,
/// that future completes without errors).
///
/// The tests are combined by generating a Dart file which imports all the main
/// methods and calls them sequentially.
///
/// Example JSON configuration:
///
///     {
///       "name": "test",
///       "kind": "Dart",
///       # Root directory of tests in this suite.
///       "path": "test/",
///       # Files in `path` that match any of the following regular expressions
///       # are considered to be part of this suite.
///       "pattern": [
///         "_test.dart$"
///       ],
///       # Except if they match any of the following regular expressions.
///       "exclude": [
///         "/golden/"
///       ]
///     }
class Dart extends Suite {
  final Uri uri;

  final List<RegExp> pattern;

  final List<RegExp> exclude;

  Dart(String name, this.uri, this.pattern, this.exclude)
      : super(name, "dart", null);

  factory Dart.fromJsonMap(Uri base, Map json, String name) {
    Uri uri = base.resolve(json["path"]);
    List<RegExp> pattern =
        List<RegExp>.from(json["pattern"].map((String p) => RegExp(p)));
    List<RegExp> exclude =
        List<RegExp>.from(json["exclude"].map((String p) => RegExp(p)));
    return Dart(name, uri, pattern, exclude);
  }

  @override
  String toString() => "Dart($name, $uri, $pattern, $exclude)";
}
