// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';
import 'package:kernel/ast.dart' as ir;
import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../elements/entities.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../io/source_information.dart';
import '../ir/constants.dart';
import '../ir/static_type_base.dart';
import '../js/js.dart' as js;
import '../js_model/closure.dart';
import '../js_model/elements.dart';
import '../js_model/locals.dart';
import '../js_model/type_recipe.dart' show TypeRecipe;
import '../universe/record_shape.dart' show RecordShape;

import '../options.dart';
import 'deferrable.dart';
import 'member_data.dart';
import 'indexed_sink_source.dart';
import 'tags.dart';

export 'binary_sink.dart';
export 'binary_source.dart';
export 'indexed_sink_source.dart' show SerializationIndices;
export 'member_data.dart' show ComponentLookup, computeMemberName;
export 'object_sink.dart';
export 'object_source.dart';
export 'tags.dart';

part 'sink.dart';
part 'source.dart';
part 'helpers.dart';

abstract class StringInterner {
  String internString(String string);
}

class ValueInterner {
  final Map<DartType, DartType> _dartTypeMap = HashMap();
  final Map<ir.DartType?, ir.DartType?> _dartTypeNodeMap = HashMap();

  DartType internDartType(DartType dartType) {
    return _dartTypeMap[dartType] ??= dartType;
  }

  ir.DartType? internDartTypeNode(ir.DartType? dartType) {
    return _dartTypeNodeMap[dartType] ??= dartType;
  }
}

/// Interface used for reading codegen only data during deserialization.
abstract class CodegenReader {
  AbstractValue readAbstractValue(DataSourceReader source);
  OutputUnit readOutputUnitReference(DataSourceReader source);
  js.Node readJsNode(DataSourceReader source);
  TypeRecipe readTypeRecipe(DataSourceReader source);
}

/// Interface used for writing codegen only data during serialization.
abstract class CodegenWriter {
  void writeAbstractValue(DataSinkWriter sink, AbstractValue value);
  void writeOutputUnitReference(DataSinkWriter sink, OutputUnit value);
  void writeJsNode(DataSinkWriter sink, js.Node node);
  void writeTypeRecipe(DataSinkWriter sink, TypeRecipe recipe);
}
