// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.task;

import '../common/tasks.dart' show CompilerTask;
import '../compiler.dart' show Compiler;
import '../elements/modelx.dart' show ElementX;
import 'package:front_end/src/fasta/scanner.dart' show Token;
import '../tree/tree.dart' show Node;

class ParserTask extends CompilerTask {
  final Compiler compiler;

  ParserTask(Compiler compiler)
      : compiler = compiler,
        super(compiler.measurer);

  String get name => 'Parser';

  Node parse(ElementX element) => null;

  Node parseCompilationUnit(Token token) => null;
}
