// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// [Configuration] holds information about a specific configuration, parsed
/// from a JSON result.log file.
/// TODO(mkroghj): Needs a shared package to keep information in sync with
/// test.py.
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
  final bool enableAsserts;
  final bool hotReload;
  final bool hotReloadRollback;
  final bool previewDart2;
  final List<String> selectors;

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
      this.enableAsserts,
      this.hotReload,
      this.hotReloadRollback,
      this.previewDart2,
      this.selectors);

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
        json["enable_asserts"] ?? false,
        json["hot_reload"] ?? false,
        json["hot_reload_rollback"] ?? false,
        json["preview_dart_2"] ?? false,
        json["selectors"] ?? []);
  }

  /// Returns the arguments needed for running test.py with the arguments
  /// corresponding to this configuration.
  List<String> toArgs({includeSelectors: true}) {
    var args = [
      _stringToArg("mode", mode),
      _stringToArg("arch", arch),
      _stringToArg("compiler", compiler),
      _stringToArg("runtime", runtime),
      _boolToArg("checked", checked),
      _boolToArg("strong", strong),
      _boolToArg("host-checked", hostChecked),
      _boolToArg("minified", minified),
      _boolToArg("csp", csp),
      _stringToArg("system", system),
      _listToArg("vm-options", vmOptions),
      _boolToArg("use-sdk", useSdk),
      _stringToArg("builder-tag", builderTag),
      _boolToArg("fast-startup", fastStartup),
      _boolToArg("dart2js-with-kernel", dart2JsWithKernel),
      _boolToArg("enable-asserts", enableAsserts),
      _boolToArg("hot-reload", hotReload),
      _boolToArg("hot-reload-rollback", hotReloadRollback),
      _boolToArg("preview-dart-2", previewDart2)
    ].where((x) => x != null).toList();
    if (includeSelectors && selectors != null && selectors.length > 0) {
      args.addAll(selectors);
    }
    return args;
  }

  String toCsvString() {
    return "$mode;$arch;$compiler;$runtime;$checked;$strong;$hostChecked;"
        "$minified;$csp;$system;$vmOptions;$useSdk;$builderTag;$fastStartup;"
        "$dart2JsWithKernel;$enableAsserts;$hotReload;"
        "$hotReloadRollback;$previewDart2;$selectors";
  }

  String _stringToArg(String name, String value) {
    if (value == null || value.length == 0) {
      return null;
    }
    return "--$name=$value";
  }

  String _boolToArg(String name, bool value) {
    return value ? "--$name" : null;
  }

  String _listToArg(String name, List<String> strings) {
    if (strings == null || strings.length == 0) {
      return null;
    }
    return "--$name=${strings.join(',')}";
  }
}

/// [Result] contains the [result] of executing a single test on a specified
/// [configuration].
class Result {
  // Not final since we have to update it when combining test results.
  String configuration;
  final String name;
  final String result;
  final bool flaky;
  final bool negative;
  final List<String> testExpectations;
  final List<Command> commands;

  Result(this.configuration, this.name, this.result, this.flaky, this.negative,
      this.testExpectations, this.commands);

  static Result getFromJson(dynamic json) {
    var commands = json["commands"].map((x) => Command.getFromJson(x)).toList();
    var testExpectations = json["test_expectation"];
    return new Result(json["configuration"], json["name"], json["result"],
        json["flaky"], json["negative"], testExpectations, commands);
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

  TestResult() : jsonObject = null {
    _configurations = {};
    _results = [];
  }

  TestResult.fromJson(this.jsonObject);

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

  /// Combines multiple test-results into a single test-result, potentially by
  /// giving new names to later configurations.
  void combineWith(Iterable<TestResult> results) {
    results.forEach((tr) {
      Map<String, String> translatedConfigurations = {};
      for (var confKey in tr.configurations.keys) {
        var newKey = _findExistingConfiguration(
            tr.configurations[confKey], this.configurations);
        newKey ??= "conf${this.configurations.length + 1}";
        translatedConfigurations[confKey] = newKey;
        this.configurations[newKey] = tr.configurations[confKey];
      }
      this.results.addAll(tr.results.map((res) {
        res.configuration = translatedConfigurations[res.configuration];
        return res;
      }));
    });
  }

  /// Finds an existing configuration based on the arguments passed to test.py.
  String _findExistingConfiguration(Configuration configurationToFind,
      Map<String, Configuration> existingConfigurations) {
    String thisArgs = configurationToFind.toArgs().join();
    for (var confKey in existingConfigurations.keys) {
      String confArgs = existingConfigurations[confKey].toArgs().join();
      if (confArgs == thisArgs) {
        return confKey;
      }
    }
    return null;
  }
}
