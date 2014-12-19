// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.test.program_result;

import 'dart:convert' show
    JSON;

import '../poi/source_update.dart';

class ProgramResult {
  final /* Map<String, String> or String */ code;

  final List<String> messages;

  final bool compileUpdatesShouldThrow;

  const ProgramResult(
      this.code, this.messages, {this.compileUpdatesShouldThrow: false});

  List<String> messagesWith(String extra) {
    return new List<String>.from(messages)..add(extra);
  }

  String toString() {
    return """
ProgramResult(
    ${JSON.encode(code)},
    ${JSON.encode(messages)},
    compileUpdatesShouldThrow: $compileUpdatesShouldThrow)""";
  }
}

class ProgramExpectation {
  final List<String> messages;

  final bool compileUpdatesShouldThrow;

  const ProgramExpectation(
      this.messages, {this.compileUpdatesShouldThrow: false});

  ProgramResult toResult(String code) {
    return new ProgramResult(
        code, messages, compileUpdatesShouldThrow: compileUpdatesShouldThrow);
  }
}

class EncodedResult {
  final /* String or List */ updates;

  final List expectations;

  const EncodedResult(this.updates, this.expectations);

  List<ProgramResult> decode() {
    if (updates is List) {
      if (updates.length == 1) {
        throw new StateError("Trivial diff, no reason to use decode.");
      }
      List<String> sources = expandUpdates(updates);
      if (sources.length != expectations.length) {
        throw new StateError(
            "Number of sources and expectations differ"
            " (${sources.length} sources,"
            " ${expectations.length} expectations).");
      }
      List<ProgramResult> result = new List<ProgramResult>(sources.length);
      for (int i = 0; i < sources.length; i++) {
        result[i] = expectations[i].toResult(sources[i]);
      }
      return result;
    } else if (updates is String) {
      Map<String, String> files = splitFiles(updates);
      Map<String, List<String>> fileMap = <String, List<String>>{};
      int updateCount = -1;
      for (String name in files.keys) {
        if (name.endsWith(".patch")) {
          String realname = name.substring(0, name.length - ".patch".length);
          if (files.containsKey(realname)) {
            throw new StateError("Patch '$name' conflicts with '$realname'");
          }
          if (fileMap.containsKey(realname)) {
            // Can't happen.
            throw new StateError("Duplicated entry for '$realname'.");
          }
          List<String> updates = expandUpdates(expandDiff(files[name]));
          if (updates.length == 1) {
            throw new StateError("No patches found in:\n ${files[name]}");
          }
          if (updateCount == -1) {
            updateCount = updates.length;
          } else if (updateCount != updates.length) {
            throw new StateError(
                "Unexpected number of patches: ${updates.length},"
                " expected ${updateCount}");
          }
          fileMap[realname] = updates;
        }
      }
      if (updateCount == -1) {
        throw new StateError("No patch files in $updates");
      }
      for (String name in files.keys) {
        if (!name.endsWith(".patch")) {
          fileMap[name] = new List<String>.filled(updateCount, files[name]);
        }
      }
      if (updateCount != expectations.length) {
        throw new StateError(
            "Number of patches and expectations differ "
            "(${updateCount} patches, ${expectations.length} expectations).");
      }
      List<ProgramResult> result = new List<ProgramResult>(updateCount);
      for (int i = 0; i < updateCount; i++) {
        ProgramExpectation expectation = decodeExpectation(expectations[i]);
        result[i] = new ProgramResult(
            <String, String>{},
            expectation.messages,
            compileUpdatesShouldThrow: expectation.compileUpdatesShouldThrow);
      }
      for (String name in fileMap.keys) {
        for (int i = 0; i < updateCount; i++) {
          result[i].code[name] = fileMap[name][i];
        }
      }
      return result;
    } else {
      throw new StateError("Unknown encoding of updates");
    }
  }
}

ProgramExpectation decodeExpectation(expectation) {
  if (expectation is ProgramExpectation) {
    return expectation;
  } else if (expectation is String) {
    return new ProgramExpectation(<String>[expectation]);
  } else if (expectation is List) {
    return new ProgramExpectation(new List<String>.from(expectation));
  } else {
    throw new ArgumentError("Don't know how to decode $expectation");
  }
}
