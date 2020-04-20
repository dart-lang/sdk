// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.test.incremental_expectations;

import "dart:convert" show JsonDecoder, JsonEncoder;

const JsonEncoder json = const JsonEncoder.withIndent("  ");

List<IncrementalExpectation> extractJsonExpectations(String source) {
  return new List<IncrementalExpectation>.from(source
      .split("\n")
      .where((l) => l.startsWith("<<<< ") || l.startsWith("==== "))
      .map((l) => l.substring("<<<< ".length))
      .map((l) => new IncrementalExpectation.fromJson(l)));
}

class IncrementalExpectation {
  final List<String> messages;

  final bool commitChangesShouldFail;

  final bool hasCompileTimeError;

  const IncrementalExpectation(this.messages,
      {this.commitChangesShouldFail: false, this.hasCompileTimeError: false});

  factory IncrementalExpectation.fromJson(String json) {
    var data = const JsonDecoder().convert(json);
    if (data is String) {
      data = <String>[data];
    }
    if (data is List) {
      return new IncrementalExpectation(data.cast<String>());
    }
    return new IncrementalExpectation(extractMessages(data),
        commitChangesShouldFail: extractCommitChangesShouldFail(data),
        hasCompileTimeError: extractHasCompileTimeError(data));
  }

  toJson() {
    if (!commitChangesShouldFail && !hasCompileTimeError) {
      return messages.length == 1 ? messages.first : messages;
    }
    Map<String, dynamic> result = <String, dynamic>{
      "messages": messages,
    };
    if (commitChangesShouldFail) {
      result['commitChangesShouldFail'] = 1;
    }
    if (hasCompileTimeError) {
      result['hasCompileTimeError'] = 1;
    }
    return result;
  }

  String toString() {
    return """
IncrementalExpectation(
    ${json.convert(messages)},
    commitChangesShouldFail: $commitChangesShouldFail,
    hasCompileTimeError: $hasCompileTimeError)""";
  }

  static List<String> extractMessages(Map<String, dynamic> json) {
    return new List<String>.from(json["messages"]);
  }

  static bool extractCommitChangesShouldFail(Map<String, dynamic> json) {
    return json["commitChangesShouldFail"] == 1;
  }

  static bool extractHasCompileTimeError(Map<String, dynamic> json) {
    return json["hasCompileTimeError"] == 1;
  }
}
