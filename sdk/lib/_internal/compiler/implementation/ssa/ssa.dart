// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ssa;

import '../closure.dart';
import '../js/js.dart' as js;
import '../dart2jslib.dart' hide Selector;
import '../source_file.dart';
import '../source_map_builder.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
import '../native_handler.dart' as native;
import '../tree/tree.dart';
import '../types/types.dart';
import '../universe/universe.dart';
import '../util/util.dart';
import '../util/characters.dart';

import '../scanner/scannerlib.dart' show PartialFunctionElement,
                                         Token,
                                         PLUS_TOKEN;

part 'bailout.dart';
part 'builder.dart';
part 'codegen.dart';
part 'codegen_helpers.dart';
part 'js_names.dart';
part 'nodes.dart';
part 'optimize.dart';
part 'types.dart';
part 'types_propagation.dart';
part 'validate.dart';
part 'variable_allocator.dart';
part 'value_range_analyzer.dart';
part 'value_set.dart';
