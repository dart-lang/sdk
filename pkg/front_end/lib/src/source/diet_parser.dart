// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ClassMemberParser, Listener, MemberKind, ExperimentalFeatures;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

const bool useImplicitCreationExpressionInCfe = true;

// TODO(ahe): Move this to parser package.
class DietParser extends ClassMemberParser {
  DietParser(
    Listener listener, {
    required ExperimentalFeatures experimentalFeatures,
  }) : super(
         listener,
         useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
         experimentalFeatures: experimentalFeatures,
       );

  @override
  Token parseFormalParametersRest(Token token, MemberKind kind) {
    return skipFormalParametersRest(token, kind);
  }
}
