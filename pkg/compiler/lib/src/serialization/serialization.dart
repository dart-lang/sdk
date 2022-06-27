// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'dart:typed_data';
import 'package:kernel/ast.dart' as ir;
import '../closure.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../diagnostics/source_span.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../ir/constants.dart';
import '../ir/static_type_base.dart';
import '../js/js.dart' as js;
import '../js_model/closure.dart';
import '../js_model/locals.dart';
import '../js_model/type_recipe.dart' show TypeRecipe;

import '../options.dart';
import 'data_sink.dart';
import 'data_source.dart';
import 'deferrable.dart';
import 'member_data.dart';
import 'serialization_interfaces.dart' as migrated
    show
        CodegenReader,
        CodegenWriter,
        DataSourceReader,
        DataSourceIndices,
        DataSourceTypeIndices,
        DataSinkWriter,
        EntityLookup,
        EntityReader,
        EntityWriter,
        LocalLookup,
        ValueInterner;
import 'indexed_sink_source.dart';
import 'tags.dart';

export 'binary_sink.dart';
export 'binary_source.dart';
export 'member_data.dart' show ComponentLookup, computeMemberName;
export 'object_sink.dart';
export 'object_source.dart';
export 'tags.dart';
export 'serialization_interfaces.dart'
    show CodegenReader, EntityLookup, EntityReader, EntityWriter;

part 'sink.dart';
part 'source.dart';
part 'helpers.dart';
