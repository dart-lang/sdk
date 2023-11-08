// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library testing.expectation;

/// An expectation represents the expected outcome of a test (or if it should
/// be skipped).
///
/// An expectation belongs to a group, for example, [ExpectationGroup.Fail].
///
/// Each expectation group has a canonical expectation, defined below. You can
/// use the canonical expectation instead of a more specific one. Note this
/// isn't implemented yet.
class Expectation {
  static const Expectation pass = Expectation("Pass", ExpectationGroup.pass);

  static const Expectation crash = Expectation("Crash", ExpectationGroup.crash);

  static const Expectation timeout =
      Expectation("Timeout", ExpectationGroup.timeout);

  static const Expectation fail = Expectation("Fail", ExpectationGroup.fail);

  static const Expectation skip = Expectation("Skip", ExpectationGroup.skip);

  final String name;

  final ExpectationGroup group;

  const Expectation(this.name, this.group);

  /// Returns the canonical expectation representing [group]. That is, one of
  /// the above expectations (except for `Meta` which returns `this`).
  Expectation get canonical => fromGroup(group) ?? this;

  @override
  String toString() => name;

  static Expectation? fromGroup(ExpectationGroup group) {
    switch (group) {
      case ExpectationGroup.crash:
        return Expectation.crash;
      case ExpectationGroup.fail:
        return Expectation.fail;
      case ExpectationGroup.meta:
        return null;
      case ExpectationGroup.pass:
        return Expectation.pass;
      case ExpectationGroup.skip:
        return Expectation.skip;
      case ExpectationGroup.timeout:
        return Expectation.timeout;
    }
  }
}

class ExpectationSet {
  static const ExpectationSet defaultExpectations = ExpectationSet(
    <String, Expectation>{
      "pass": Expectation.pass,
      "crash": Expectation.crash,
      "timeout": Expectation.timeout,
      "fail": Expectation.fail,
      "skip": Expectation.skip,
      "missingcompiletimeerror":
          Expectation("MissingCompileTimeError", ExpectationGroup.fail),
      "missingruntimeerror":
          Expectation("MissingRuntimeError", ExpectationGroup.fail),
      "runtimeerror": Expectation("RuntimeError", ExpectationGroup.fail),
    },
  );

  final Map<String, Expectation> internalMap;

  const ExpectationSet(this.internalMap);

  Expectation operator [](String name) {
    return internalMap[name.toLowerCase()] ??
        (throw "No expectation named: '$name'.");
  }

  factory ExpectationSet.fromJsonList(List data) {
    Map<String, Expectation> internalMap =
        Map<String, Expectation>.from(defaultExpectations.internalMap);
    for (Map map in data) {
      String? name;
      String? group;
      map.cast<String, String>().forEach((key, value) {
        switch (key) {
          case "name":
            name = value;
            break;
          case "group":
            group = value;
            break;
          default:
            throw "Unrecognized key: '$key' in '$map'.";
        }
      });
      if (name == null) {
        throw "No name provided in '$map'";
      }
      if (group == null) {
        throw "No group provided in '$map'";
      }
      Expectation expectation = Expectation(name!, groupFromString(group!));
      name = name!.toLowerCase();
      if (internalMap.containsKey(name)) {
        throw "Duplicated expectation name: '$name'.";
      }
      internalMap[name!] = expectation;
    }
    return ExpectationSet(internalMap);
  }
}

enum ExpectationGroup {
  crash,
  fail,
  meta,
  pass,
  skip,
  timeout,
}

ExpectationGroup groupFromString(String name) {
  switch (name) {
    case "Crash":
      return ExpectationGroup.crash;
    case "Fail":
      return ExpectationGroup.fail;
    case "Meta":
      return ExpectationGroup.meta;
    case "Pass":
      return ExpectationGroup.pass;
    case "Skip":
      return ExpectationGroup.skip;
    case "Timeout":
      return ExpectationGroup.timeout;
    default:
      throw "Unrecognized group: '$name'.";
  }
}
