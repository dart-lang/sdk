// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// [Configuration] holds information about a specific configuration, parsed
/// from a JSON result.log file.
class Configuration {
  final String mode;
  final String arch;
  final String compiler;
  final String runtime;
  final bool checked;
  final bool strong;
  final bool hostChecked;
  final bool minified;
  final bool csp;
  final String system;
  final List<String> vmOptions;
  final bool useSdk;
  final String builderTag;
  final bool fastStartup;
  final int timeout;
  final bool dart2JsWithKernel;
  final bool dart2JsWithKernelInSsa;
  final bool enableAsserts;
  final bool hotReload;
  final bool hotReloadRollback;

  Configuration(
      this.mode,
      this.arch,
      this.compiler,
      this.runtime,
      this.checked,
      this.strong,
      this.hostChecked,
      this.minified,
      this.csp,
      this.system,
      this.vmOptions,
      this.useSdk,
      this.builderTag,
      this.fastStartup,
      this.timeout,
      this.dart2JsWithKernel,
      this.dart2JsWithKernelInSsa,
      this.enableAsserts,
      this.hotReload,
      this.hotReloadRollback);

  static Configuration getFromJson(dynamic json) {
    return new Configuration(
        json["mode"],
        json["arch"],
        json["compiler"],
        json["runtime"],
        json["checked"],
        json["strong"],
        json["host_checked"],
        json["minified"],
        json["csp"],
        json["system"],
        json["vm_options"],
        json["use_sdk"],
        json["builder_tag"],
        json["fast_startup"],
        json["timeout"],
        json["dart2js_with_kernel"] ?? false,
        json["dart2js_with_kernel_in_ssa"] ?? false,
        json["enable_asserts"] ?? false,
        json["hot_reload"] ?? false,
        json["hot_reload_rollback"] ?? false);
  }

  /// Returns the arguments needed for running test.py with the arguments
  /// corresponding to this configuration.
  List<String> toArgs() {
    return [
      stringToArg("mode", mode),
      stringToArg("arch", arch),
      stringToArg("compiler", compiler),
      stringToArg("runtime", runtime),
      boolToArg("checked", checked),
      boolToArg("strong", strong),
      boolToArg("host-checked", hostChecked),
      boolToArg("minified", minified),
      boolToArg("csp", csp),
      stringToArg("system", system),
      listToArg("vm-options", vmOptions),
      boolToArg("use-sdk", useSdk),
      stringToArg("builder-tag", builderTag),
      boolToArg("fast-startup", fastStartup),
      boolToArg("dart2js-with-kernel", dart2JsWithKernel),
      boolToArg("dart2js-with-kernel-in-ssa", dart2JsWithKernelInSsa),
      boolToArg("enable-asserts", enableAsserts),
      boolToArg("hot-reload", hotReload),
      boolToArg("hot-reload-rollback", hotReloadRollback),
    ].where((x) => x != null).toList();
  }

  String stringToArg(String name, String value) {
    if (value == null || value.length == 0) {
      return null;
    }
    return "--$name=$value";
  }

  String boolToArg(String name, bool value) {
    return value ? "--$name" : null;
  }

  String listToArg(String name, List<String> strings) {
    if (strings == null || strings.length == 0) {
      return null;
    }
    return "--$name=${strings.join(',')}";
  }
}

/// [Result] contains the [result] of executing a single test on a specified
/// [configuration].
class Result {
  final String configuration;
  final String name;
  final String result;
  final List<Command> commands;

  Result(this.configuration, this.name, this.result, this.commands);

  static Result getFromJson(dynamic json) {
    var commands = json["commands"].map((x) => Command.getFromJson(x)).toList();
    return new Result(
        json["configuration"], json["name"], json["result"], commands);
  }
}

/// [Command] used to get a result for a test.
class Command {
  final String name;
  final int exitCode;
  final bool timeout;
  final int duration;

  Command(this.name, this.exitCode, this.timeout, this.duration);

  static Command getFromJson(dynamic json) {
    return new Command(
        json["name"], json["exitCode"], json["timeout"], json["duration"]);
  }
}

/// [TestResult] is a collection of configurations and test results,
/// corresponding to the information found in a result.log json file.
class TestResult {
  final dynamic jsonObject;

  TestResult(this.jsonObject);

  Map<String, Configuration> _configurations;
  Map<String, Configuration> get configurations {
    if (_configurations != null) {
      return _configurations;
    }
    _configurations = {};
    this.jsonObject["configurations"].forEach((key, value) {
      _configurations[key] = Configuration.getFromJson(value);
    });
    return _configurations;
  }

  List<Result> _results;
  List<Result> get results {
    return _results ??=
        this.jsonObject["results"].map((x) => Result.getFromJson(x)).toList();
  }
}
