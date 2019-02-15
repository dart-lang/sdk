// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.codes;

import 'dart:convert' show JsonEncoder, json;

import 'package:kernel/ast.dart'
    show Constant, DartType, demangleMixinApplicationName;

import '../api_prototype/diagnostic_message.dart' show DiagnosticMessage;

import '../scanner/token.dart' show Token;

import 'kernel/type_labeler.dart';

import 'severity.dart' show Severity;

import 'util/relativize.dart' as util show relativizeUri;

part 'fasta_codes_generated.dart';

const int noLength = 1;

class Code<T> {
  final String name;

  /// The unique positive integer associated with this code,
  /// or `-1` if none. This index is used when translating
  /// this error to its corresponding Analyzer error.
  final int index;

  final Template<T> template;

  final List<String> analyzerCodes;

  final Severity severity;

  const Code(this.name, this.template,
      {int index, this.analyzerCodes, this.severity: Severity.error})
      : this.index = index ?? -1;

  String toString() => name;
}

class Message {
  final Code code;

  final String message;

  final String tip;

  final Map<String, dynamic> arguments;

  const Message(this.code, {this.message, this.tip, this.arguments});

  LocatedMessage withLocation(Uri uri, int charOffset, int length) {
    return new LocatedMessage(uri, charOffset, length, this);
  }

  LocatedMessage withoutLocation() {
    return new LocatedMessage(null, -1, noLength, this);
  }
}

class MessageCode extends Code<Null> implements Message {
  final String message;

  final String tip;

  const MessageCode(String name,
      {int index,
      List<String> analyzerCodes,
      Severity severity: Severity.error,
      this.message,
      this.tip})
      : super(name, null,
            index: index, analyzerCodes: analyzerCodes, severity: severity);

  Map<String, dynamic> get arguments => const <String, dynamic>{};

  Code get code => this;

  @override
  LocatedMessage withLocation(Uri uri, int charOffset, int length) {
    return new LocatedMessage(uri, charOffset, length, this);
  }

  LocatedMessage withoutLocation() {
    return new LocatedMessage(null, -1, noLength, this);
  }
}

class Template<T> {
  final String messageTemplate;

  final String tipTemplate;

  final T withArguments;

  const Template({this.messageTemplate, this.tipTemplate, this.withArguments});
}

class LocatedMessage implements Comparable<LocatedMessage> {
  final Uri uri;

  final int charOffset;

  final int length;

  final Message messageObject;

  const LocatedMessage(
      this.uri, this.charOffset, this.length, this.messageObject);

  Code get code => messageObject.code;

  String get message => messageObject.message;

  String get tip => messageObject.tip;

  Map<String, dynamic> get arguments => messageObject.arguments;

  int compareTo(LocatedMessage other) {
    int result = "${uri}".compareTo("${other.uri}");
    if (result != 0) return result;
    result = charOffset.compareTo(other.charOffset);
    if (result != 0) return result;
    return message.compareTo(message);
  }

  FormattedMessage withFormatting(String formatted, int line, int column,
      Severity severity, List<FormattedMessage> relatedInformation) {
    return new FormattedMessage(
        this, formatted, line, column, severity, relatedInformation);
  }
}

class FormattedMessage implements DiagnosticMessage {
  final LocatedMessage locatedMessage;

  final String formatted;

  final int line;

  final int column;

  @override
  final Severity severity;

  final List<FormattedMessage> relatedInformation;

  const FormattedMessage(this.locatedMessage, this.formatted, this.line,
      this.column, this.severity, this.relatedInformation);

  Code get code => locatedMessage.code;

  String get message => locatedMessage.message;

  String get tip => locatedMessage.tip;

  Map<String, dynamic> get arguments => locatedMessage.arguments;

  Uri get uri => locatedMessage.uri;

  int get charOffset => locatedMessage.charOffset;

  int get length => locatedMessage.length;

  @override
  Iterable<String> get ansiFormatted sync* {
    yield formatted;
    if (relatedInformation != null) {
      for (FormattedMessage m in relatedInformation) {
        yield m.formatted;
      }
    }
  }

  @override
  Iterable<String> get plainTextFormatted {
    // TODO(ahe): Implement this correctly.
    return ansiFormatted;
  }

  Map<String, Object> toJson() {
    // This should be kept in sync with package:kernel/problems.md
    return <String, Object>{
      "ansiFormatted": ansiFormatted.toList(),
      "plainTextFormatted": plainTextFormatted.toList(),
      "severity": severity.index,
      "uri": uri.toString(),
    };
  }

  String toJsonString() {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    return encoder.convert(this);
  }
}

class DiagnosticMessageFromJson implements DiagnosticMessage {
  @override
  final Iterable<String> ansiFormatted;

  @override
  final Iterable<String> plainTextFormatted;

  @override
  final Severity severity;

  final Uri uri;

  DiagnosticMessageFromJson(
      this.ansiFormatted, this.plainTextFormatted, this.severity, this.uri);

  factory DiagnosticMessageFromJson.fromJson(String jsonString) {
    Map<String, Object> decoded = json.decode(jsonString);
    List<String> ansiFormatted =
        new List<String>.from(decoded["ansiFormatted"]);
    List<String> plainTextFormatted =
        new List<String>.from(decoded["plainTextFormatted"]);
    Severity severity = Severity.values[decoded["severity"]];
    Uri uri = Uri.parse(decoded["uri"]);

    return new DiagnosticMessageFromJson(
        ansiFormatted, plainTextFormatted, severity, uri);
  }

  Map<String, Object> toJson() {
    // This should be kept in sync with package:kernel/problems.md
    return <String, Object>{
      "ansiFormatted": ansiFormatted.toList(),
      "plainTextFormatted": plainTextFormatted.toList(),
      "severity": severity.index,
      "uri": uri.toString(),
    };
  }

  String toJsonString() {
    JsonEncoder encoder = new JsonEncoder.withIndent("  ");
    return encoder.convert(this);
  }
}

String relativizeUri(Uri uri) {
  // We have this method here for two reasons:
  //
  // 1. It allows us to implement #uri message argument without using it
  // (otherwise, we might get an `UNUSED_IMPORT` warning).
  //
  // 2. We can change `base` argument here if needed.
  return util.relativizeUri(uri, base: Uri.base);
}

typedef SummaryTemplate = Message Function(int, int, num, num, num);

String itemizeNames(List<String> names) {
  StringBuffer buffer = new StringBuffer();
  for (int i = 0; i < names.length - 1; i++) {
    buffer.write(" - ");
    buffer.writeln(names[i]);
  }
  buffer.write(" - ");
  buffer.write(names.last);
  return "$buffer";
}
