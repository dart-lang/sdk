// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.qualified_name;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart' show Expression;

import 'problems.dart' show unhandled, unsupported;

class Identifier {
  final Token token;

  Identifier(this.token);

  String get name => token.lexeme;

  int get charOffset => token.charOffset;

  Expression? get initializer => null;

  int get endCharOffset => charOffset + name.length;

  QualifiedName withQualifier(Object qualifier) {
    return new QualifiedName(qualifier, token);
  }

  @override
  String toString() => "identifier($name)";
}

class InitializedIdentifier extends Identifier {
  @override
  final Expression initializer;

  InitializedIdentifier(Identifier identifier, this.initializer)
      : super(identifier.token);

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  String toString() => "initialized-identifier($name, $initializer)";
}

class QualifiedName extends Identifier {
  final Object qualifier;

  QualifiedName(this.qualifier, Token suffix) : super(suffix);

  Token get suffix => token;

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  String toString() => "qualified-name($qualifier, $name)";
}

void flattenQualifiedNameOn(
    QualifiedName name, StringBuffer buffer, int charOffset, Uri? fileUri) {
  final Object qualifier = name.qualifier;
  if (qualifier is QualifiedName) {
    flattenQualifiedNameOn(qualifier, buffer, charOffset, fileUri);
  } else if (qualifier is Identifier) {
    buffer.write(qualifier.name);
  } else if (qualifier is String) {
    buffer.write(qualifier);
  } else {
    unhandled("${qualifier.runtimeType}", "flattenQualifiedNameOn", charOffset,
        fileUri);
  }
  buffer.write(".");
  buffer.write(name.name);
}

String flattenName(Object name, int charOffset, Uri? fileUri) {
  if (name is String) {
    return name;
  } else if (name is QualifiedName) {
    StringBuffer buffer = new StringBuffer();
    flattenQualifiedNameOn(name, buffer, charOffset, fileUri);
    return "$buffer";
  } else if (name is Identifier) {
    return name.name;
  } else {
    return unhandled("${name.runtimeType}", "flattenName", charOffset, fileUri);
  }
}
