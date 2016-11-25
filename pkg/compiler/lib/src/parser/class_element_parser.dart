// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.classes;

import '../tokens/token.dart' show Token;
import 'listener.dart' show Listener;
import 'partial_parser.dart' show PartialParser;

class ClassElementParser extends PartialParser {
  ClassElementParser(Listener listener): super(listener);

  Token parseClassBody(Token token) => fullParseClassBody(token);
}
