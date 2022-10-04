// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../universe/selector.dart' show Selector;
import 'package:js_shared/synced/embedded_names.dart' show JsGetName;

abstract class ModularNamer {
  jsAst.Name nameForOneShotInterceptor(
      Selector selector, Set<ClassEntity> classes);
  jsAst.Name getNameForJsGetName(Spannable spannable, JsGetName name);
}
