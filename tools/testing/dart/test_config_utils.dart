// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_config_utils");

/**
 * TestUtils is a collection of utility methods used to write
 * test_config.dart scripts for test suites.
 */
class TestUtils {

  /**
   * Get a list of argument lists for the dart shell command.
   */
  static List<List<String>> argumentLists(String filename,
                                          Map optionsFromFile,
                                          Map configuration) {
    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add("--enable_type_checks");
    }
    if (configuration["component"] == "leg") {
      args.add("--enable_leg");
    }
    if (configuration["component"] == "dartc") {
      if (configuration["mode"] == "release") {
        args.add("--optimize");
      }
    }

    List<String> dartOptions = optionsFromFile["dartOptions"];
    args.addAll(dartOptions == null ? [filename] : dartOptions);

    var result = new List<List<String>>();
    List<List<String>> vmOptionsList = optionsFromFile["vmOptions"];
    if (vmOptionsList.isEmpty()) {
      result.add(args);
    } else {
      for (var vmOptions in vmOptionsList) {
        vmOptions.addAll(args);
        result.add(vmOptions);
      }
    }

    return result;
  }

  /**
   * Extract test options from the test file itself.
   */
  static Map optionsFromFile(String filename, Map configuration) {
    RegExp testOptionsRegExp = const RegExp(@"// VMOptions=(.*)");
    RegExp dartOptionsRegExp = const RegExp(@"// DartOptions=(.*)");

    // Read the entire file into a byte buffer and transform it to a
    // String. This will treat the file as ascii but the only parts
    // we are interested in will be ascii in any case.
    File file = new File(filename);
    file.openSync();
    List chars = new List(file.lengthSync());
    var offset = 0;
    while (offset != chars.length) {
      offset += file.readListSync(chars, offset, chars.length - offset);
    }
    file.closeSync();
    String contents = new String.fromCharCodes(chars);
    chars = null;

    // Find the options in the file.
    List<List> result = new List<List>();
    List<String> dartOptions;
    bool isNegative = false;

    Iterable<Match> matches = testOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      result.add(match[1].split(' ').filter((e) => e != ''));
    }

    matches = dartOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      if (dartOptions != null) {
        throw new Exception(
            'More than one "// DartOptions=" line in test $filename');
      }
      dartOptions = match[1].split(' ').filter((e) => e != '');
    }

    if (contents.contains("@compile-error") ||
        contents.contains("@runtime-error")) {
      isNegative = true;
    } else if (contents.contains("@dynamic-type-error") &&
               configuration['checked']) {
      isNegative = true;
    }

    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "isNegative" : isNegative };
  }
}
