// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dump_info.javascript_monitor;

import 'package:js_ast/js_ast.dart' as jsAst show Node;

/// Interface implemented by `DumpInfoTask` used to monitor the generated
/// JavaScript as it is written.
// TODO(48820): Remove this interface when `DumpInfoTask` is migrated.
// TODO(sra): Perhaps `DumpInfoTask` should have a member that implements
// `JavaScriptPrintingContext` instead of this very similar interface.
abstract class DumpInfoJavaScriptMonitor {
  void enterNode(jsAst.Node node, int start);
  void emit(String string);
  void exitNode(jsAst.Node node, int start, int end, int? closing);
}
