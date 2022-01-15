// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_utilities/check/check.dart';

extension FormalParameterExtension on CheckTarget<FormalParameter> {
  CheckTarget<SimpleIdentifier?> get identifier {
    return nest(
      value.identifier,
      (selected) => 'has identifier ${valueStr(selected)}',
    );
  }
}

extension SimpleFormalParameterExtension on CheckTarget<SimpleFormalParameter> {
  CheckTarget<Token?> get keyword {
    return nest(
      value.keyword,
      (selected) => 'has keyword ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeAnnotation?> get type {
    return nest(
      value.type,
      (selected) => 'has type ${valueStr(selected)}',
    );
  }
}

extension SimpleIdentifierExtension on CheckTarget<SimpleIdentifier> {
  CheckTarget<bool> get inDeclarationContext {
    return nest(
      value.inDeclarationContext(),
      (selected) => 'has inDeclarationContext() ${valueStr(selected)}',
    );
  }

  CheckTarget<String> get name {
    return nest(
      value.name,
      (selected) => 'has name ${valueStr(selected)}',
    );
  }
}

extension SuperFormalParameterExtension on CheckTarget<SuperFormalParameter> {
  CheckTarget<SimpleIdentifier> get identifier {
    return nest(
      value.identifier,
      (selected) => 'has identifier ${valueStr(selected)}',
    );
  }

  CheckTarget<Token?> get keyword {
    return nest(
      value.keyword,
      (selected) => 'has keyword ${valueStr(selected)}',
    );
  }

  CheckTarget<FormalParameterList?> get parameters {
    return nest(
      value.parameters,
      (selected) => 'has parameters ${valueStr(selected)}',
    );
  }

  CheckTarget<Token?> get superKeyword {
    return nest(
      value.superKeyword,
      (selected) => 'has superKeyword ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeAnnotation?> get type {
    return nest(
      value.type,
      (selected) => 'has type ${valueStr(selected)}',
    );
  }

  CheckTarget<TypeParameterList?> get typeParameters {
    return nest(
      value.typeParameters,
      (selected) => 'has typeParameters ${valueStr(selected)}',
    );
  }
}

extension TypeParameterListExtension on CheckTarget<TypeParameterList> {
  CheckTarget<List<TypeParameter>> get typeParameters {
    return nest(
      value.typeParameters,
      (selected) => 'has typeParameters ${valueStr(selected)}',
    );
  }
}
