// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Most of the code from tools/testing/dart/environment.dart.
// TODO(mkroghj) add package with all settings, such as these
// and also information about test-suites.

import 'package:status_file/environment.dart';
import 'result_json_models.dart';
import 'configurations.dart';

typedef String _LookUpFunction(Configuration configuration);
typedef bool _BoolLookUpFunction(Configuration configuration);

// TODO(29756): Instead of synthesized negated variables like "unchecked",
// consider adding support for "!" to status expressions.
final _variables = {
  "analyzer":
      new _Variable.bool((c) => c.compiler == Compiler.dart2analyzer.name),
  "arch": new _Variable((c) => c.arch, Architecture.names),
  "browser": new _Variable.bool((c) {
    var runtime = runtimeFromName(c.runtime);
    return runtime != null ? runtime.isBrowser : false;
  }),
  "builder_tag": new _Variable((c) => c.builderTag ?? "", const []),
  "checked": new _Variable.bool((c) => c.checked),
  "compiler": new _Variable((c) => c.compiler, Compiler.names),
  "csp": new _Variable.bool((c) => c.csp),
  "fasta": new _Variable.bool((c) => c.fasta),
  "fast_startup": new _Variable.bool((c) => c.fastStartup),
  "enable_asserts": new _Variable.bool((c) => c.enableAsserts),
  "host_checked": new _Variable.bool((c) => c.hostChecked),
  "host_unchecked": new _Variable.bool((c) => !c.hostChecked),
  "hot_reload": new _Variable.bool((c) => c.hotReload),
  "hot_reload_rollback": new _Variable.bool((c) => c.hotReloadRollback),
  "ie": new _Variable.bool((c) {
    var runtime = runtimeFromName(c.runtime);
    return runtime != null ? runtime.isIE : false;
  }),
  "jscl": new _Variable.bool((c) {
    var runtime = runtimeFromName(c.runtime);
    return runtime != null ? runtime.isJSCommandLine : false;
  }),
  "minified": new _Variable.bool((c) => c.minified),
  "mode": new _Variable((c) => c.mode, Mode.names),
  "no_preview_dart_2": new _Variable.bool((c) => c.noPreviewDart2),
  "runtime": new _Variable(_runtimeName, Runtime.names),
  "spec_parser": new _Variable.bool((c) => c.compiler == Compiler.specParser),
  "strong": new _Variable.bool((c) => c.strong),
  "system": new _Variable((c) => c.system, System.names),
  "use_sdk": new _Variable.bool((c) => c.useSdk)
};

/// Gets the name of the runtime as it appears in status files.
String _runtimeName(Configuration configuration) {
  if (configuration.runtime == Runtime.firefox.name) return 'ff';
  return configuration.runtime;
}

/// Defines the variables that are available for use inside a status file
/// section header.
///
/// These mostly map to command line arguments with the same name, though this
/// is only a subset of the full set of command line arguments.
class ConfigurationEnvironment implements Environment {
  /// The configuration where variable data is found.
  final Configuration _configuration;

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
      throw new ArgumentError('Unknown variable "$name".');
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
