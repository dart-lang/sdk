// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.codes;

import 'package:front_end/src/scanner/token.dart' show Token;

part 'fasta_codes_generated.dart';

class Code<T> {
  final String name;

  final Template<T> template;

  final String analyzerCode;

  final String dart2jsCode;

  const Code(this.name, this.template, {this.analyzerCode, this.dart2jsCode});

  String toString() => name;
}

class Message {
  final Code code;

  final String message;

  final String tip;

  final Map<String, dynamic> arguments;

  const Message(this.code, {this.message, this.tip, this.arguments});

  LocatedMessage withLocation(Uri uri, int charOffset) {
    return new LocatedMessage(uri, charOffset, this);
  }
}

class MessageCode extends Code<Null> implements Message {
  final String message;

  final String tip;

  const MessageCode(String name,
      {String analyzerCode, String dart2jsCode, this.message, this.tip})
      : super(name, null, analyzerCode: analyzerCode, dart2jsCode: dart2jsCode);

  Map<String, dynamic> get arguments => const <String, dynamic>{};

  Code get code => this;

  LocatedMessage withLocation(Uri uri, int charOffset) {
    return new LocatedMessage(uri, charOffset, this);
  }
}

class Template<T> {
  final String messageTemplate;

  final String tipTemplate;

  final T withArguments;

  const Template({this.messageTemplate, this.tipTemplate, this.withArguments});
}

class LocatedMessage {
  final Uri uri;

  final int charOffset;

  final Message messageObject;

  const LocatedMessage(this.uri, this.charOffset, this.messageObject);

  Code get code => messageObject.code;

  String get message => messageObject.message;

  String get tip => messageObject.tip;

  Map<String, dynamic> get arguments => messageObject.arguments;
}
