// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.qualified_name;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:kernel/ast.dart' show Expression;

import '../builder/builder.dart';
import '../builder/type_builder.dart';
import '../kernel/expression_generator.dart';
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

  Operator? get operator;

  TypeName get typeName;
}

abstract class IdentifierImpl implements Identifier {
  @override
  final Token token;

  IdentifierImpl(this.token);

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
  Operator? get operator => null;

  @override
  TypeName get typeName => new IdentifierTypeName(name, nameOffset);

  @override
  String toString() => "IdentifierImpl($name)";
}

class SimpleIdentifier extends IdentifierImpl {
  SimpleIdentifier(super.token);

  QualifiedNameIdentifier withIdentifierQualifier(Identifier qualifier) {
    return new QualifiedNameIdentifier(qualifier, token);
  }

  QualifiedNameGenerator withGeneratorQualifier(Generator qualifier) {
    return new QualifiedNameGenerator(qualifier, token);
  }

  QualifiedNameBuilder withBuilderQualifier(Builder qualifier) {
    return new QualifiedNameBuilder(qualifier, token);
  }

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

  // Coverage-ignore(suite): Not run.
  int get charOffset => token.charOffset;

  @override
  // Coverage-ignore(suite): Not run.
  int get firstOffset => token.charOffset;

  @override
  int get qualifierOffset => token.charOffset;

  @override
  int get nameOffset => token.charOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Expression? get initializer => null;

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  TypeName get typeName {
    return unsupported("typeName", charOffset, null);
  }

  @override
  String toString() => "initialized-identifier($name, $initializer)";
}

sealed class QualifiedName extends IdentifierImpl {
  QualifiedName(Token suffix) : super(suffix);
}

class QualifiedNameIdentifier extends QualifiedName {
  final Identifier qualifier;

  QualifiedNameIdentifier(this.qualifier, Token suffix) : super(suffix);

  // Coverage-ignore(suite): Not run.
  Token get suffix => token;

  @override
  int get firstOffset => qualifier.firstOffset;

  @override
  int get qualifierOffset => qualifier.nameOffset;

  @override
  int get nameOffset => token.charOffset;

  @override
  TypeName get typeName =>
      new QualifiedTypeName(qualifier.name, qualifierOffset, name, nameOffset);

  @override
  String toString() => "qualified-name-identifier($qualifier, $name)";
}

class QualifiedNameGenerator extends QualifiedName {
  final Generator qualifier;

  QualifiedNameGenerator(this.qualifier, Token suffix) : super(suffix);

  Token get suffix => token;

  @override
  // Coverage-ignore(suite): Not run.
  int get firstOffset => qualifier.fileOffset;

  @override
  String toString() => "qualified-name-generator($qualifier, $name)";
}

class QualifiedNameBuilder extends QualifiedName {
  final Builder qualifier;

  QualifiedNameBuilder(this.qualifier, Token suffix) : super(suffix);

  Token get suffix => token;

  @override
  // Coverage-ignore(suite): Not run.
  int get firstOffset => qualifier.charOffset;

  @override
  String toString() => "qualified-name-builder($qualifier, $name)";
}

void flattenQualifiedNameOn(
    QualifiedName name, StringBuffer buffer, int charOffset, Uri? fileUri) {
  switch (name) {
    case QualifiedNameIdentifier():
      Identifier qualifier = name.qualifier;
      if (qualifier is QualifiedName) {
        flattenQualifiedNameOn(qualifier, buffer, charOffset, fileUri);
      } else {
        buffer.write(qualifier.name);
      }
    // Coverage-ignore(suite): Not run.
    case QualifiedNameGenerator():
    case QualifiedNameBuilder():
      unhandled(
          "${name.runtimeType}", "flattenQualifiedNameOn", charOffset, fileUri);
  }
  buffer.write(".");
  buffer.write(name.name);
}

String flattenName(Identifier name, int charOffset, Uri? fileUri) {
  if (name is QualifiedName) {
    StringBuffer buffer = new StringBuffer();
    flattenQualifiedNameOn(name, buffer, charOffset, fileUri);
    return "$buffer";
  } else {
    return name.name;
  }
}
