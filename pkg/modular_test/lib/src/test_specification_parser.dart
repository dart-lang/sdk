// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines how to read a test specification from a Yaml
/// file. We expect specifications written in this format:
///
///    dependencies:
///      b: a
///      main: [b, expect]
///    flags:
///      - constant-update-2018
///    packages:
///      c: .
///      a: a
///
///
/// Where:
///   - the dependencies section describe how modules depend on one another,
///   - the flags section show what flags are needed to run that specific test,
///   - the packages section is used to create a package structure on top of the
///     declared modules.
///
/// When defining dependencies:
///   - Each name corresponds to a module.
///   - Module names correlate to either a file, a folder, or a package.
///   - A map entry contains all the dependencies of a module, if any.
///   - If a module has a single dependency, it can be written as a single
///     value.
///
/// When defining packages:
///   - The name corresponds to a package name, this doesn't need to match
///     the name of the module. That said, it's common for some modules
///     and packages to share their name (especially for the default set of
///     packages included by the framework, like package:expect).
///   - The value is a path to the folder containing the libraries of that
///     package.
///
/// The packages entry is optional.  If this is not specified, the test will
/// still have a default set of packages, like package:expect and package:meta.
/// If the packages entry is specified, it will be extended with the definitions
/// of the default set of packages as well. Thus, the list of packages provided
/// is expected to be disjoint with those in the default set. The default set is
/// defined directly in the code of `loader.dart`.
///
/// The logic in this library mostly treats these names as strings, separately
/// `loader.dart` is responsible for validating, attaching dependency
/// information to a set of module definitions, and resolving package paths.
///
/// The framework is agnostic of what the flags are, but at this time we only
/// use the name of experimental language features. These are then used to
/// decide what options to pass to the tools that compile and run the tests.
library;

import 'package:yaml/yaml.dart';

/// Parses [contents] containing a module dependencies specification written in
/// yaml, and returns a [TestSpecification].
TestSpecification parseTestSpecification(String contents) {
  var spec = loadYaml(contents);
  if (spec is! YamlMap) {
    return _invalidSpecification("spec is not a map");
  }
  var dependencies = spec['dependencies'];
  if (dependencies == null) {
    return _invalidSpecification("no dependencies section");
  }
  if (dependencies is! YamlMap) {
    return _invalidSpecification("dependencies is not a map");
  }

  Map<String, List<String>> normalizedMap = {};
  dependencies.forEach((key, value) {
    if (key is! String) {
      _invalidSpecification("key: '$key' is not a string");
    }
    final values = normalizedMap[key] = [];
    if (value is String) {
      values.add(value);
    } else if (value is List) {
      for (var entry in value) {
        if (entry is! String) {
          _invalidSpecification("entry: '$entry' is not a string");
        }
        values.add(entry);
      }
    } else {
      _invalidSpecification(
          "entry: '$value' is not a string or a list of strings");
    }
  });

  List<String> normalizedFlags = [];
  dynamic flags = spec['flags'];
  if (flags is String) {
    normalizedFlags.add(flags);
  } else if (flags is List) {
    normalizedFlags.addAll(flags.cast<String>());
  } else if (flags != null) {
    _invalidSpecification(
        "flags: '$flags' expected to be string or list of strings");
  }

  Map<String, String> normalizedPackages = {};
  final packages = spec['packages'];
  if (packages != null) {
    if (packages is Map) {
      normalizedPackages.addAll(packages.cast<String, String>());
    } else {
      _invalidSpecification("packages is not a map");
    }
  }

  final Map<String, Map<String, Map<String, List<String>>>> normalizedMacros =
      {};
  var macros = spec['macros'];
  if (macros != null) {
    if (macros is Map) {
      macros.forEach((module, macroConfig) {
        if (module is! String) {
          _invalidSpecification("macros key $module was not a String");
        }
        if (macroConfig is! Map) {
          _invalidSpecification(
              "macros[$module] value $macroConfig was not a Map");
        }
        var normalizedConfig = normalizedMacros[module] = {};
        macroConfig.forEach((library, macroConstructors) {
          if (library is! String) {
            _invalidSpecification(
                "macros[$module] key `$library` was not a String");
          }
          if (macroConstructors is! Map) {
            _invalidSpecification(
                "macros[$module][$library] value `$macroConstructors` was not "
                "a Map");
          }
          var normalizedConstructors = normalizedConfig[library] = {};
          macroConstructors.forEach((clazz, constructors) {
            if (clazz is! String) {
              _invalidSpecification(
                  "macros[$module][$library] key `$clazz` was not a String");
            }
            if (constructors is! List) {
              _invalidSpecification(
                  "macro[$module][$library][$clazz] value `$constructors` was "
                  "not a List");
            }
            var constructorNames = normalizedConstructors[clazz] = [];
            for (var constructor in constructors) {
              if (constructor is! String) {
                _invalidSpecification(
                    "macros[$module][$library][$clazz] element `$constructor` "
                    "was not a String");
              }
              constructorNames.add(constructor);
            }
          });
        });
      });
    } else {
      _invalidSpecification("macros is not a Map");
    }
  }
  return TestSpecification(
      normalizedFlags, normalizedMap, normalizedPackages, normalizedMacros);
}

/// Data specifying details about a modular test including dependencies and
/// flags that are necessary in order to properly run a test.
///
class TestSpecification {
  /// Set of flags necessary to properly run a test.
  ///
  /// Usually this contains flags enabling language experiments.
  final List<String> flags;

  /// Dependencies of the modules that are expected to exist on the test.
  ///
  /// Note: some values in the map may not have a corresponding key. That may be
  /// the case for modules that have no dependencies and modules that are not
  /// specified explicitly because they are added automatically by the framework
  /// (for instance, the module of `package:expect` or the sdk itself).
  final Map<String, List<String>> dependencies;

  /// Map of package name to a relative path.
  ///
  /// The paths in this map are meant to be resolved relative to the location
  /// where this test specification was defined.
  final Map<String, String> packages;

  /// A map containing information about the macros defined in each module.
  ///
  /// The keys are the macro names, and the values describe the macros in each
  /// module.
  ///
  /// See the `Module` class for more information about the values.
  final Map<String, Map<String, Map<String, List<String>>>> macros;

  TestSpecification(this.flags, this.dependencies, this.packages, this.macros);
}

Never _invalidSpecification(String message) {
  throw InvalidSpecificationError(message);
}

class InvalidSpecificationError extends Error {
  final String message;
  InvalidSpecificationError(this.message);
  @override
  String toString() => "Invalid specification: $message";
}
