// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.qualified_name;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart' show Expression;

import 'problems.dart' show unhandled, unsupported;

class Identifier {
  final String name;
  final int charOffset;

  Identifier(Token token)
      : name = token.lexeme,
        charOffset = token.charOffset;

  Identifier._(this.name, this.charOffset);

  factory Identifier.preserveToken(Token token) {
    return new _TokenIdentifier(token);
  }

  Expression get initializer => null;

  int get endCharOffset => charOffset + name.length;

  QualifiedName withQualifier(Object qualifier) {
    return new QualifiedName._(qualifier, name, charOffset);
  }

  @override
  String toString() => "identifier($name)";
}

class _TokenIdentifier implements Identifier {
  final Token token;

  _TokenIdentifier(this.token);

  @override
  String get name => token.lexeme;

  @override
  int get charOffset => token.charOffset;

  @override
  Expression get initializer => null;

  @override
  int get endCharOffset => charOffset + name.length;

  @override
  QualifiedName withQualifier(Object qualifier) {
    return new _TokenQualifiedName(qualifier, token);
  }

  @override
  String toString() => "token-identifier($name)";
}

class InitializedIdentifier extends _TokenIdentifier {
  @override
  final Expression initializer;

  InitializedIdentifier(_TokenIdentifier identifier, this.initializer)
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

  QualifiedName._(this.qualifier, String name, int charOffset)
      : super._(name, charOffset);

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  String toString() => "qualified-name($qualifier, $name)";
}

class _TokenQualifiedName extends _TokenIdentifier implements QualifiedName {
  @override
  final Object qualifier;

  _TokenQualifiedName(this.qualifier, Token suffix)
      : assert(qualifier is! Identifier || qualifier is _TokenIdentifier),
        super(suffix);

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  String toString() => "token-qualified-name($qualifier, $name)";
}

void flattenQualifiedNameOn(
    QualifiedName name, StringBuffer buffer, int charOffset, Uri fileUri) {
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

String flattenName(Object name, int charOffset, Uri fileUri) {
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

Token deprecated_extractToken(Identifier identifier) {
  _TokenIdentifier tokenIdentifier = identifier;
  return tokenIdentifier?.token;
}
