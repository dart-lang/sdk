// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.codes;

import 'package:kernel/ast.dart' show DartType;

import 'package:kernel/text/ast_to_text.dart' show NameSystem, Printer;

import '../scanner/token.dart' show Token;

import 'severity.dart' show Severity;

import 'util/relativize.dart' as util show relativizeUri;

part 'fasta_codes_generated.dart';

const int noLength = 1;

class Code<T> {
  final String name;

  final Template<T> template;

  final String analyzerCode;

  final String dart2jsCode;

  final Severity severity;

  const Code(this.name, this.template,
      {this.analyzerCode, this.dart2jsCode, this.severity});

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
      {String analyzerCode,
      String dart2jsCode,
      Severity severity,
      this.message,
      this.tip})
      : super(name, null,
            analyzerCode: analyzerCode,
            dart2jsCode: dart2jsCode,
            severity: severity);

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

typedef Message SummaryTemplate(
    int count, int count2, String string, String string2, String string3);
