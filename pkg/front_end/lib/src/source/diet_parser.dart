// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show ClassMemberParser, Listener, MemberKind;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

const bool useImplicitCreationExpressionInCfe = true;

// TODO(ahe): Move this to parser package.
class DietParser extends ClassMemberParser {
  DietParser(
    Listener listener, {
    required bool allowPatterns,
    required bool enableFeatureEnhancedParts,
  }) : super(
         listener,
         useImplicitCreationExpression: useImplicitCreationExpressionInCfe,
         allowPatterns: allowPatterns,
         enableFeatureEnhancedParts: enableFeatureEnhancedParts,
       );

  @override
  Token parseFormalParametersRest(Token token, MemberKind kind) {
    return skipFormalParametersRest(token, kind);
  }
}
