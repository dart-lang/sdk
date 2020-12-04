// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:status_file/environment.dart';

import 'configuration.dart';

typedef _LookUpFunction = String Function(TestConfiguration configuration);
typedef _BoolLookUpFunction = bool Function(TestConfiguration configuration);

// TODO(29756): Instead of synthesized negated variables like "unchecked",
// consider adding support for "!" to status expressions.
final _variables = {
  "analyzer": _Variable.bool((c) => c.compiler == Compiler.dart2analyzer),
  "analyzer_use_fasta_parser": _Variable.bool((c) => c.useAnalyzerFastaParser),
  "arch": _Variable((c) => c.architecture.name, Architecture.names),
  "browser": _Variable.bool((c) => c.runtime.isBrowser),
  "builder_tag": _Variable((c) => c.builderTag ?? "", const []),
  "checked": _Variable.bool((c) => c.isChecked),
  "compiler": _Variable((c) => c.compiler.name, Compiler.names),
  "csp": _Variable.bool((c) => c.isCsp),
  "enable_asserts": _Variable.bool((c) => c.enableAsserts),
  "fasta": _Variable.bool((c) => c.usesFasta),
  "host_checked": _Variable.bool((c) => c.isHostChecked),
  "host_unchecked": _Variable.bool((c) => !c.isHostChecked),
  "hot_reload": _Variable.bool((c) => c.hotReload),
  "hot_reload_rollback": _Variable.bool((c) => c.hotReloadRollback),
  "ie": _Variable.bool((c) => c.runtime.isIE),
  "jscl": _Variable.bool((c) => c.runtime.isJSCommandLine),
  "minified": _Variable.bool((c) => c.isMinified),
  "mode": _Variable((c) => c.mode.name, Mode.names),
  "nnbd": _Variable((TestConfiguration c) => c.nnbdMode.name, NnbdMode.names),
  "runtime": _Variable(_runtimeName, _runtimeNames),
  "spec_parser": _Variable.bool((c) => c.compiler == Compiler.specParser),
  "system": _Variable(_systemName, _systemNames),
  "use_sdk": _Variable.bool((c) => c.useSdk)
};

/// Gets the name of the runtime as it appears in status files.
String _runtimeName(TestConfiguration configuration) {
  // TODO(rnystrom): Handle "ff" being used as the name for firefox. We don't
  // want to make the Runtime itself use that as the name because it appears
  // elsewhere in test.dart and we want those other places to show "firefox".
  if (configuration.runtime == Runtime.firefox) return 'ff';

  return configuration.runtime.name;
}

List<String> _runtimeNames = ['ff', 'drt']..addAll(Runtime.names);

/// Gets the name of the runtime as it appears in status files.
String _systemName(TestConfiguration configuration) {
  // Because we are getting rid of status files, we don't want to change all
  // of them to say "win" instead of "windows" and "mac" instead of "macos"
  if (configuration.system == System.win) return 'windows';
  if (configuration.system == System.mac) return 'macos';

  return configuration.system.name;
}

List<String> _systemNames = ['windows', 'macos']..addAll(System.names);

/// Defines the variables that are available for use inside a status file
/// section header.
///
/// These mostly map to command line arguments with the same name, though this
/// is only a subset of the full set of command line arguments.
class ConfigurationEnvironment implements Environment {
  /// The configuration where variable data is found.
  final TestConfiguration _configuration;

  ConfigurationEnvironment(this._configuration);

  /// Validates that the variable with [name] exists and can be compared
  /// against [value].
  ///
  /// If any errors are found, adds them to [errors].
  void validate(String name, String value, List<String> errors) {
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

  /// Looks up the value of the variable with [name].
  String lookUp(String name) {
    var variable = _variables[name];
    if (variable == null) {
      // This shouldn't happen since we validate variables before evaluating
      // expressions.
      throw ArgumentError('Unknown variable "$variable".');
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
/// [TestConfiguration]
class _Variable {
  final _LookUpFunction _lookUp;
  final List<String> allowedValues;

  _Variable(this._lookUp, Iterable<String> allowed)
      : allowedValues = allowed.toList();

  /// Creates a Boolean variable with allowed values "true" and "false".
  _Variable.bool(_BoolLookUpFunction lookUp)
      : _lookUp = ((configuration) => lookUp(configuration).toString()),
        allowedValues = const ["true", "false"];

  String lookUp(TestConfiguration configuration) => _lookUp(configuration);
}
