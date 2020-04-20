// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A diagnostic, as defined by the [Diagnostic Design Guidelines][guidelines]:
///
/// > An indication of a specific problem at a specific location within the
/// > source code being processed by a development tool.
///
/// Clients may not extend, implement or mix-in this class.
///
/// [guidelines]: ../doc/diagnostics.md
abstract class Diagnostic {
  /// A list of messages that provide context for understanding the problem
  /// being reported. The list will be empty if there are no such messages.
  List<DiagnosticMessage> get contextMessages;

  /// A description of how to fix the problem, or `null` if there is no such
  /// description.
  String get correctionMessage;

  /// A message describing what is wrong and why.
  DiagnosticMessage get problemMessage;

  /// The severity associated with the diagnostic.
  Severity get severity;
}

/// A single message associated with a [Diagnostic], consisting of the text of
/// the message and the location associated with it.
///
/// Clients may not extend, implement or mix-in this class.
abstract class DiagnosticMessage {
  /// The absolute and normalized path of the file associated with this message.
  String get filePath;

  /// The length of the source range associated with this message.
  int get length;

  /// The text of the message.
  String get message;

  /// The zero-based offset from the start of the file to the beginning of the
  /// source range associated with this message.
  int get offset;
}

/// An indication of the severity of a [Diagnostic].
enum Severity { error, warning, info }
