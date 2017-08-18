// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.formal_parameter_kind;

enum FormalParameterKind {
  mandatory,
  optionalNamed,
  optionalPositional,
}

bool isMandatoryFormalParameterKind(FormalParameterKind type) {
  return FormalParameterKind.mandatory == type;
}

bool isOptionalNamedFormalParameterKind(FormalParameterKind type) {
  return FormalParameterKind.optionalNamed == type;
}

bool isOptionalPositionalFormalParameterKind(FormalParameterKind type) {
  return FormalParameterKind.optionalPositional == type;
}
