// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.target.implementation_options;

final Map<String, ImplementationOption> implementationOptions =
    ImplementationOption._validateOptions(<ImplementationOption>[
  new ImplementationOption._(
      "strong-aot", Platform.vm, new DateTime.utc(2018, 1), """
Enables strong-mode in AOT (precompiler) mode of the Dart VM."""),
]);

final RegExp _namePattern = new RegExp(r"^[-a-z0-9]+$");

class ImplementationOption {
  final String name;
  final String description;
  final Platform platform;
  final DateTime expires;

  ImplementationOption._(
      this.name, this.platform, this.expires, this.description);

  bool _validate(int index, List<String> reasons) {
    if (name == null) {
      reasons.add("[name] is null for option #$index.");
      return false;
    }
    if (!_namePattern.hasMatch(name)) {
      reasons.add("'$name' doesn't match regular expression"
          " '${_namePattern.pattern}'.");
      return false;
    }
    if (description == null) {
      reasons.add("[description] is null for option '$name'.");
      return false;
    }
    if (description.isEmpty) {
      reasons.add("[description] is empty for option '$name'.");
      return false;
    }
    if (description == name) {
      reasons.add("[description] == [name] for option '$name'.");
      return false;
    }
    if (platform == null) {
      reasons.add("[platform] is null for option '$name'.");
      return false;
    }
    if (expires == null) {
      reasons.add("[expires] is null for option '$name'.");
      return false;
    }
    if (!expires.isUtc) {
      reasons.add("[expires] isn't in UTC for option '$name'.");
      return false;
    }
    if (expires.isBefore(new DateTime.now().toUtc())) {
      print("Warning: option '$name' has expired "
          "(see pkg/kernel/lib/target/implementation_option.dart).");
      return false;
    }
    return true;
  }

  static Map<String, ImplementationOption> _validateOptions(
      List<ImplementationOption> options) {
    Map<String, ImplementationOption> result = <String, ImplementationOption>{};
    int i = 0;
    List<String> reasons = <String>[];
    for (ImplementationOption option in options) {
      if (result.containsKey(option.name)) {
        throw "Duplicated option name at index $i.";
      }
      if (option._validate(i++, reasons)) {
        result[option.name] = option;
      }
    }
    if (reasons.isNotEmpty) {
      throw reasons.join("\n");
    }
    return new Map<String, ImplementationOption>.unmodifiable(result);
  }

  static void validate(ImplementationOption option) {
    List<String> reasons = <String>[];
    if (!option._validate(-1, reasons)) {
      throw new ArgumentError(reasons.join("\n"));
    }
  }
}

enum Platform {
  analyzer,
  dart2js,
  devcompiler,
  vm,
}
