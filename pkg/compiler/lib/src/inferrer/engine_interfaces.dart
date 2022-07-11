// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/elements.dart';
import '../elements/entities.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/no_such_method_registry_interfaces.dart';
import '../universe/selector.dart';
import '../world_interfaces.dart';
import 'abstract_value_domain.dart';

abstract class InferrerEngine {
  AbstractValueDomain get abstractValueDomain;
  JClosedWorld get closedWorld;
  CommonElements get commonElements;
  InferredDataBuilder get inferredDataBuilder;
  FunctionEntity get mainElement;
  NoSuchMethodData get noSuchMethodData;

  bool returnsListElementType(Selector selector, AbstractValue mask);
  bool returnsMapValueType(Selector selector, AbstractValue mask);
}
