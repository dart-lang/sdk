// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/kernel.dart';

/// Converts a [jsonObject] into a kernel [Constant].
///
/// [jsonObject] must consist only of [double], [int], [String], [List], and
/// [Map] recursively.
Constant jsonToKernelConstant(Object jsonObject) {
  if (jsonObject is int) {
    return IntConstant(jsonObject);
  }

  if (jsonObject is double) {
    return DoubleConstant(jsonObject);
  }

  if (jsonObject is String) {
    return StringConstant(jsonObject);
  }

  if (jsonObject is List) {
    return ListConstant(
      DynamicType(),
      [
        for (final element in jsonObject)
          jsonToKernelConstant(element as Object),
      ],
    );
  }

  if (jsonObject is Map) {
    return MapConstant(
      DynamicType(),
      DynamicType(),
      [
        for (final entry in jsonObject.entries)
          ConstantMapEntry(
            jsonToKernelConstant(entry.key as Object),
            jsonToKernelConstant(entry.value as Object),
          )
      ],
    );
  }

  throw UnsupportedError(
      'Unknown data type: ${jsonObject.runtimeType} $jsonObject');
}
