// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.test.program_result;

import '../poi/source_update.dart';

class ProgramResult {
  final String code;

  final List<String> messages;

  final bool compileUpdatesShouldThrow;

  const ProgramResult(
      this.code, this.messages, {this.compileUpdatesShouldThrow: false});

  List<String> messagesWith(String extra) {
    return new List<String>.from(messages)..add(extra);
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
  final List updates;

  final List<ProgramExpectation> expectations;

  const EncodedResult(this.updates, this.expectations);

  List<ProgramResult> decode() {
    if (updates.length == 1) {
      throw new StateError("Trivial diff, no reason to use decode.");
    }
    List<String> sources = expandUpdates(updates);
    if (sources.length != expectations.length) {
      throw new StateError(
          "Number of sources and expectations differ "
          "(${sources.length} sources, ${expectations.length} expectations).");
    }
    List<ProgramResult> result = new List<ProgramResult>(sources.length);
    for (int i = 0; i < sources.length; i++) {
      result[i] = expectations[i].toResult(sources[i]);
    }
    return result;
  }
}
