// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/diagnostic_message.dart'
    show DiagnosticMessage, getMessageUri;

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:front_end/src/fasta/fasta_codes.dart'
    show
        Code,
        DiagnosticMessageFromJson,
        FormattedMessage,
        LocatedMessage,
        Message;

/// Test that turning a message into json and back again retains the wanted
/// information.
main() {
  for (int i = 0; i < Severity.values.length; i++) {
    Severity severity = Severity.values[i];
    Code code = new Code("MyCodeName");
    Message message = new Message(code, message: '');
    LocatedMessage locatedMessage1 =
        new LocatedMessage(Uri.parse("what:ever/fun_1.dart"), 117, 2, message);
    FormattedMessage formattedMessage2 = new FormattedMessage(
        null, "Formatted string #2", 13, 2, Severity.error, []);
    FormattedMessage formattedMessage3 = new FormattedMessage(
        null, "Formatted string #3", 313, 32, Severity.error, []);

    FormattedMessage formattedMessage1 = new FormattedMessage(
        locatedMessage1, "Formatted string", 42, 86, severity, [
      formattedMessage2,
      formattedMessage3
    ], involvedFiles: [
      Uri.parse("what:ever/foo.dart"),
      Uri.parse("what:ever/bar.dart")
    ]);
    expect(formattedMessage1.codeName, "MyCodeName");

    DiagnosticMessageFromJson diagnosticMessageFromJson =
        new DiagnosticMessageFromJson.fromJson(
            formattedMessage1.toJsonString());
    compareMessages(formattedMessage1, diagnosticMessageFromJson);

    DiagnosticMessageFromJson diagnosticMessageFromJson2 =
        new DiagnosticMessageFromJson.fromJson(
            diagnosticMessageFromJson.toJsonString());
    compareMessages(diagnosticMessageFromJson, diagnosticMessageFromJson2);

    expect(diagnosticMessageFromJson2.toJsonString(),
        formattedMessage1.toJsonString());
  }
}

void compareMessages(DiagnosticMessage a, DiagnosticMessage b) {
  List<String> list1 = a.ansiFormatted.toList();
  List<String> list2 = b.ansiFormatted.toList();
  expect(list1.length, list2.length);
  for (int i = 0; i < list1.length; i++) {
    expect(list1[i], list2[i]);
  }

  list1 = a.plainTextFormatted.toList();
  list2 = b.plainTextFormatted.toList();
  expect(list1.length, list2.length);
  for (int i = 0; i < list1.length; i++) {
    expect(list1[i], list2[i]);
  }

  expect(a.severity, b.severity);
  expect(getMessageUri(a), getMessageUri(b));

  List<Uri> uriList1 = a.involvedFiles?.toList();
  List<Uri> uriList2 = b.involvedFiles?.toList();
  expect(uriList1?.length, uriList2?.length);
  if (uriList1 != null) {
    for (int i = 0; i < uriList1.length; i++) {
      expect(uriList1[i], uriList2[i]);
    }
  }

  String string1 = a.codeName;
  String string2 = b.codeName;
  expect(string1, string2);
}

void expect(Object actual, Object expect) {
  if (expect != actual) throw "Expected $expect got $actual";
}
