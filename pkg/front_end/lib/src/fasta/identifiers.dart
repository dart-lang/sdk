// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.qualified_name;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart' show Expression;

import 'builder/type_builder.dart';
import 'operator.dart';
import 'problems.dart' show unhandled, unsupported;

abstract class Identifier {
  Token get token;

  String get name;

  /// The left-most offset of this identifier.
  int get firstOffset;

  /// The offset of the qualifier if this identifier is a [QualifiedName].
  /// Otherwise the [nameOffset].
  int get qualifierOffset;

  /// The offset of the simple name of this identifier. If this is a
  /// [QualifiedName], this is the offset of the suffix.
  int get nameOffset;

  Expression? get initializer;

  int get endCharOffset;

  Operator? get operator;

  QualifiedName withQualifier(Object qualifier);

  TypeName get typeName;
}

class SimpleIdentifier implements Identifier {
  @override
  final Token token;

  SimpleIdentifier(this.token);

  @override
  String get name => token.lexeme;

  int get charOffset => token.charOffset;

  @override
  int get firstOffset => charOffset;

  @override
  int get qualifierOffset => charOffset;

  @override
  int get nameOffset => charOffset;

  @override
  Expression? get initializer => null;

  @override
  int get endCharOffset => charOffset + name.length;

  @override
  Operator? get operator => null;

  @override
  QualifiedName withQualifier(Object qualifier) {
    return new QualifiedName(qualifier, token);
  }

  @override
  TypeName get typeName => new IdentifierTypeName(name, nameOffset);

  @override
  String toString() => "SimpleIdentifier($name)";
}

class OperatorIdentifier implements Identifier {
  @override
  final Token token;

  @override
  final Operator operator;

  OperatorIdentifier(this.token)
      : this.operator = Operator.fromText(token.stringValue!)!;

  @override
  String get name => operator.text;

  int get charOffset => token.charOffset;

  @override
  int get firstOffset => token.charOffset;

  @override
  int get qualifierOffset => token.charOffset;

  @override
  int get nameOffset => token.charOffset;

  @override
  Expression? get initializer => null;

  @override
  int get endCharOffset => charOffset + name.length;

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  TypeName get typeName {
    return unsupported("typeName", charOffset, null);
  }

  @override
  String toString() => "Operator($name)";
}

class InitializedIdentifier extends SimpleIdentifier {
  @override
  final Expression initializer;

  InitializedIdentifier(Identifier identifier, this.initializer)
      : super(identifier.token);

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  TypeName get typeName {
    return unsupported("typeName", charOffset, null);
  }

  @override
  String toString() => "initialized-identifier($name, $initializer)";
}

class QualifiedName extends SimpleIdentifier {
  // TODO(johnniwinther): Type this field.
  final Object qualifier;

  QualifiedName(this.qualifier, Token suffix) : super(suffix);

  Token get suffix => token;

  @override
  int get firstOffset => (qualifier as Identifier).firstOffset;

  @override
  int get qualifierOffset => (qualifier as Identifier).nameOffset;

  @override
  int get nameOffset => token.charOffset;

  @override
  QualifiedName withQualifier(Object qualifier) {
    return unsupported("withQualifier", charOffset, null);
  }

  @override
  TypeName get typeName => new QualifiedTypeName(
      (qualifier as Identifier).name, qualifierOffset, name, nameOffset);

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
