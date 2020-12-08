// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'dart:io' show File;

import 'crashing_test_case_minimizer_impl.dart';

// TODO(jensj): Option to automatically find and search for _all_ crashes that
// it uncovers --- i.e. it currently has an option to ask if we want to search
// for the other crash instead --- add an option so it does that automatically
// for everything it sees. One can possibly just make a copy of the state of
// the file system and save that for later...

// TODO(jensj): Add asserts or similar where - after each rewrite - we run the
// parser on it and verifies that no syntax errors have been introduced.

main(List<String> arguments) async {
  String filename;
  Uri loadJson;
  for (String arg in arguments) {
    if (arg.startsWith("--json=")) {
      String json = arg.substring("--json=".length);
      loadJson = Uri.base.resolve(json);
      break;
    }
  }
  TestMinimizerSettings settings = new TestMinimizerSettings();

  if (loadJson != null) {
    File f = new File.fromUri(loadJson);
    settings.initializeFromJson((jsonDecode(f.readAsStringSync())));
  } else {
    for (String arg in arguments) {
      if (arg.startsWith("--")) {
        if (arg == "--experimental-invalidation") {
          settings.experimentalInvalidation = true;
        } else if (arg == "--serialize") {
          settings.serialize = true;
        } else if (arg.startsWith("--platform=")) {
          String platform = arg.substring("--platform=".length);
          settings.platformUri = Uri.base.resolve(platform);
        } else if (arg == "--no-platform") {
          settings.noPlatform = true;
        } else if (arg.startsWith("--invalidate=")) {
          for (String s in arg.substring("--invalidate=".length).split(",")) {
            settings.invalidate.add(Uri.base.resolve(s));
          }
        } else if (arg.startsWith("--widgetTransformation")) {
          settings.widgetTransformation = true;
        } else if (arg.startsWith("--target=VM")) {
          settings.targetString = "VM";
        } else if (arg.startsWith("--target=flutter")) {
          settings.targetString = "flutter";
        } else if (arg.startsWith("--target=ddc")) {
          settings.targetString = "ddc";
        } else if (arg == "--oldBlockDelete") {
          settings.oldBlockDelete = true;
        } else if (arg == "--lineDelete") {
          settings.lineDelete = true;
        } else if (arg == "--byteDelete") {
          settings.byteDelete = true;
        } else if (arg == "--ask-redirect-target") {
          settings.askAboutRedirectCrashTarget = true;
        } else if (arg == "--auto-uncover-all-crashes") {
          settings.autoUncoverAllCrashes = true;
        } else if (arg.startsWith("--stack-matches=")) {
          String stackMatches = arg.substring("--stack-matches=".length);
          settings.stackTraceMatches = int.parse(stackMatches);
        } else {
          throw "Unknown option $arg";
        }
      } else if (filename != null) {
        throw "Already got '$filename', '$arg' is also a filename; "
            "can only get one";
      } else {
        filename = arg;
      }
    }
    if (settings.noPlatform) {
      int i = 0;
      while (settings.platformUri == null ||
          new File.fromUri(settings.platformUri).existsSync()) {
        settings.platformUri = Uri.base.resolve("nonexisting_$i");
        i++;
      }
    } else {
      if (settings.platformUri == null) {
        throw "No platform given. Use --platform=/path/to/platform.dill";
      }
      if (!new File.fromUri(settings.platformUri).existsSync()) {
        throw "The platform file '${settings.platformUri}' doesn't exist";
      }
    }
    if (filename == null) {
      throw "Need file to operate on";
    }
    File file = new File(filename);
    if (!file.existsSync()) throw "File $filename doesn't exist.";
    settings.mainUri = file.absolute.uri;
  }

  TestMinimizer testMinimizer = new TestMinimizer(settings);
  await testMinimizer.tryToMinimize();
}
