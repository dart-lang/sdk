// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

/// Methods for [ParameterStructure] that have not yet been migrated to null
/// safety.
// TODO(48820): Move these methods back to [ParameterStructure].
library entities.parameter_structure_methods;

import '../serialization/serialization.dart';
import '../universe/call_structure.dart' show CallStructure;
import 'entities.dart';
import 'types.dart' show FunctionType;

extension UnmigratedParameterStructureInstanceMethods on ParameterStructure {
  /// Returns the [CallStructure] corresponding to a call site passing all
  /// parameters both required and optional.
  CallStructure get callStructure {
    return CallStructure(totalParameters, namedParameters, typeParameters);
  }

  /// Serializes this [ParameterStructure] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    final tag = ParameterStructure.tag;
    sink.begin(tag);
    sink.writeInt(requiredPositionalParameters);
    sink.writeInt(positionalParameters);
    sink.writeStrings(namedParameters);
    sink.writeStrings(requiredNamedParameters);
    sink.writeInt(typeParameters);
    sink.end(tag);
  }
}

class ParameterStructureMethods {
  static ParameterStructure fromType(FunctionType type) {
    return ParameterStructure(
        type.parameterTypes.length,
        type.parameterTypes.length + type.optionalParameterTypes.length,
        type.namedParameters,
        type.requiredNamedParameters,
        type.typeVariables.length);
  }

  /// Deserializes a [ParameterStructure] object from [source].
  static readFromDataSource(DataSourceReader source) {
    final tag = ParameterStructure.tag;
    source.begin(tag);
    int requiredPositionalParameters = source.readInt();
    int positionalParameters = source.readInt();
    List<String> namedParameters = source.readStrings() /*!*/;
    Set<String> requiredNamedParameters =
        source.readStrings(emptyAsNull: true)?.toSet() ?? const <String>{};
    int typeParameters = source.readInt();
    source.end(tag);
    return ParameterStructure(
        requiredPositionalParameters,
        positionalParameters,
        namedParameters,
        requiredNamedParameters,
        typeParameters);
  }
}
