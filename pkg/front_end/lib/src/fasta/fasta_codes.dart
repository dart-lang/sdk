// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.codes;

import 'package:front_end/src/fasta/scanner/token.dart' show Token;

part 'fasta_codes_generated.dart';

class FastaCode<T> {
  final String template;

  final String tip;

  final String analyzerCode;

  final String dart2jsCode;

  final T format;

  const FastaCode(
      {this.template,
      this.tip,
      this.analyzerCode,
      this.dart2jsCode,
      this.format});
}

class FastaMessage {
  final Uri uri;

  final int charOffset;

  final String message;

  final String tip;

  final FastaCode code;

  final Map<String, dynamic> arguments;

  const FastaMessage(this.uri, this.charOffset, this.code,
      {this.message, this.tip, this.arguments});
}
