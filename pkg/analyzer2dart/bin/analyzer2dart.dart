// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** The entry point for the command-line version analyzer2dart. */
library analyzer2dart.cmdline;

import 'package:analyzer/analyzer.dart';
import 'package:compiler/implementation/compiler.dart';

void main(List<String> args) {
  // TODO(brianwilkerson,paulberry): Run the analyzer `args[0]` and provide
  // access to the element model/ast of the `main` method.

  // TODO(brianwilkerson,paulberry,johnniwinther): Perform tree-growing by
  // visiting the ast and feeding the dependencies into a work queue (enqueuer).

  // TODO(brianwilkerson,paulberry,johnniwinther): Convert the ast into cps by
  // visiting the ast and invoking the ir builder.

  // TODO(johnniwinther): Convert the analyzer element model into the dart2js
  // element model to fit the needs of the cps encoding above.

  // TODO(johnniwinther): Feed the cps ir into the new dart2dart backend to
  // generate dart file(s).
}
