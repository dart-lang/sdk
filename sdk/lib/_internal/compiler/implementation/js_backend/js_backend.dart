// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js_backend;

import 'dart:collection' show LinkedHashMap;

import '../closure.dart';
import '../../compiler.dart' as api;
import '../elements/elements.dart';
import '../elements/modelx.dart' show FunctionElementX;

// TODO(ahe): There seems to be a bug in the VM, so we have to hide "js".
import '../dart2jslib.dart' hide Selector, js;
import '../dart_types.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js; // TODO(ahe): VM bug, see above.
import '../native_handler.dart' as native;
import '../source_file.dart';
import '../source_map_builder.dart';
import '../ssa/ssa.dart' hide js; // TODO(ahe): VM bug, see above.
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/universe.dart' hide js; // TODO(ahe): VM bug, see above.
import '../util/characters.dart';
import '../util/util.dart';

part 'backend.dart';
part 'constant_emitter.dart';
part 'constant_system_javascript.dart';
part 'emitter.dart';
part 'emitter_no_eval.dart';
part 'minify_namer.dart';
part 'namer.dart';
part 'native_emitter.dart';
part 'runtime_types.dart';
