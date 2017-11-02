// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'result_models.dart';
import 'dart:io';

const String BUILDER_PROJECT = "chromium";

/// [PathHelper] is a utility class holding information about static paths.
class PathHelper {
  static String testPyPath() {
    var root = sdkRepositoryRoot();
    return "${root}/tools/test.py";
  }

  static String _sdkRepositoryRoot;
  static String sdkRepositoryRoot() {
    return _sdkRepositoryRoot ??=
        _findRoot(new Directory.fromUri(Platform.script));
  }

  static String _findRoot(Directory current) {
    if (current.path.endsWith("sdk")) {
      return current.path;
    }
    if (current.parent == null) {
      print("Could not find the dart sdk folder. "
          "Please run the tool in the root of the dart-sdk local repository.");
      exit(1);
    }
    return _findRoot(current.parent);
  }
}

/// Tests if all strings passed in [stringsToTest] are integers.
bool areNumbers(Iterable<String> stringsToTest) {
  RegExp isNumberRegExp = new RegExp(r"^\d+$");
  return stringsToTest
      .every((string) => isNumberRegExp.firstMatch(string) != null);
}

bool isNumber(String stringToTest) {
  bool succeeded = true;
  int.parse(stringToTest, onError: (String) {
    succeeded = false;
    return 0;
  });
  return succeeded;
}

/// Gets if the [url] is a swarming task url.
bool isSwarmingTaskUrl(String url) {
  return url.startsWith("https://ci.chromium.org/swarming");
}

/// Gets the swarming task id from the [url].
String getSwarmingTaskId(String url) {
  RegExp swarmingTaskIdInPathRegExp =
      new RegExp(r"https:\/\/ci\.chromium\.org\/swarming\/task\/(.*)\?server");
  Match swarmingTaskIdMatch = swarmingTaskIdInPathRegExp.firstMatch(url);
  if (swarmingTaskIdMatch == null) {
    return null;
  }
  return swarmingTaskIdMatch.group(1);
}

/// Returns the test-suite for [name].
String getSuiteNameForTest(String name) {
  var reg = new RegExp(r"^(.*?)\/.*$");
  var match = reg.firstMatch(name);
  if (match == null) {
    return null;
  }
  return match.group(1);
}

/// Returns the qualified name (what to use in status-files) for a test with
/// [name].
String getQualifiedNameForTest(String name) {
  if (name.startsWith("cc/")) {
    return name;
  }
  return name.substring(name.indexOf("/") + 1);
}

/// Returns the reproduction command for test.py based on the [configuration]
/// and [name].
String getReproductionCommand(Configuration configuration, String name) {
  var allArgs = configuration.toArgs(includeSelectors: false)..add(name);
  return "${PathHelper.testPyPath()} ${allArgs.join(' ')}";
}
