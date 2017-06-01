// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'configuration.dart';

typedef String _LookUpFunction(Configuration configuration);
typedef bool _BoolLookUpFunction(Configuration configuration);

// TODO(29756): Instead of synthesized negated variables like "unchecked",
// consider adding support for "!" to status expressions.
final _variables = {
  "analyzer": new _Variable.bool((c) => c.compiler == Compiler.dart2analyzer),
  "arch": new _Variable((c) => c.architecture.name, Architecture.names),
  "browser": new _Variable.bool((c) => c.runtime.isBrowser),
  "builder_tag": new _Variable((c) => c.builderTag ?? "", const []),
  "checked": new _Variable.bool((c) => c.isChecked),
  "compiler": new _Variable((c) => c.compiler.name, Compiler.names),
  "csp": new _Variable.bool((c) => c.isCsp),
  "dart2js_with_kernel": new _Variable.bool((c) => c.useDart2JSWithKernel),
  "fast_startup": new _Variable.bool((c) => c.useFastStartup),
  "host_checked": new _Variable.bool((c) => c.isHostChecked),
  "host_unchecked": new _Variable.bool((c) => !c.isHostChecked),
  "hot_reload": new _Variable.bool((c) => c.hotReload),
  "hot_reload_rollback": new _Variable.bool((c) => c.hotReloadRollback),
  "ie": new _Variable.bool((c) => c.runtime.isIE),
  "jscl": new _Variable.bool((c) => c.runtime.isJSCommandLine),
  "minified": new _Variable.bool((c) => c.isMinified),
  "mode": new _Variable((c) => c.mode.name, Mode.names),
  "runtime": new _Variable(_runtimeName, Runtime.names),
  "strong": new _Variable.bool((c) => c.isStrong),
  "system": new _Variable((c) => c.system.name, System.names),
  "unchecked": new _Variable.bool((c) => !c.isChecked),
  "unminified": new _Variable.bool((c) => !c.isMinified),
  "use_sdk": new _Variable.bool((c) => c.useSdk)
};

/// Gets the name of the runtime as it appears in status files.
String _runtimeName(Configuration configuration) {
  // TODO(rnystrom): Handle "ff" being used as the name for firefox. We don't
  // want to make the Runtime itself use that as the name because it appears
  // elsewhere in test.dart and we want those other places to show "firefox".
  if (configuration.runtime == Runtime.firefox) return 'ff';

  return configuration.runtime.name;
}

/// Defines the variables that are available for use inside a status file
/// section header.
///
/// These mostly map to command line arguments with the same name, though this
/// is only a subset of the full set of command line arguments.
class Environment {
  /// Validates that the variable with [name] exists and can be compared
  /// against [value].
  ///
  /// If any errors are found, adds them to [errors].
  static void validate(String name, String value, List<String> errors) {
    var variable = _variables[name];
    if (variable == null) {
      errors.add('Unknown variable "$name".');
      return;
    }

    // The "builder_tag" variable doesn't have an enumerated set of values.
    if (variable.allowedValues.isEmpty) return;

    if (!variable.allowedValues.contains(value)) {
      errors.add(
          'Variable "$name" cannot have value "$value". Allowed values are:\n' +
              variable.allowedValues.join(', ') +
              '.');
    }
  }

  /// The configuration where variable data is found.
  final Configuration _configuration;

  Environment(this._configuration);

  /// Looks up the value of the variable with [name].
  String lookUp(String name) {
    var variable = _variables[name];
    if (variable == null) {
      // This shouldn't happen since we validate variables before evaluating
      // expressions.
      throw new ArgumentError('Unknown variable "$variable".');
    }

    return variable.lookUp(_configuration);
  }
}

// TODO(rnystrom): There's some overlap between these and _Option in
// options.dart. Unify?
/// Describes a variable name whose value can be tested in a status file.
///
/// Each variable is an enumerated string type that only accepts a limited range
/// of values. Each instance of this class defines one variable, the values it
/// permits, and the logic needed to look up the variable's value from a
/// [Configuration]
class _Variable {
  final _LookUpFunction _lookUp;
  final List<String> allowedValues;

  _Variable(this._lookUp, Iterable<String> allowed)
      : allowedValues = allowed.toList();

  /// Creates a Boolean variable with allowed values "true" and "false".
  _Variable.bool(_BoolLookUpFunction lookUp)
      : _lookUp = ((configuration) => lookUp(configuration).toString()),
        allowedValues = const ["true", "false"];

  String lookUp(Configuration configuration) => _lookUp(configuration);
}
