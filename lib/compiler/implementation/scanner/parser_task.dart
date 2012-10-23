// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

class ParserTask extends CompilerTask {
  ParserTask(Compiler compiler) : super(compiler);
  String get name => 'Parser';

  Node parse(Element element) {
    return measure(() => element.parseNode(compiler));
  }
}
