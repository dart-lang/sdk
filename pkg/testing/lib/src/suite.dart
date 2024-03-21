// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.suite;

import 'chain.dart' show Chain;

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
      case "chain":
        return Chain.fromJsonMap(base, json, name, kind);

      default:
        throw "Suite '$name' has unknown kind '$kind'.";
    }
  }

  @override
  String toString() => "Suite($name, $kind)";
}
