// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.resolution;

import '../constants/values.dart' show ConstantValue;
import '../elements/entities.dart';
import '../universe/world_impact.dart' show WorldImpact;
import '../universe/feature.dart';

class ResolutionImpact extends WorldImpact {
  const ResolutionImpact();

  Iterable<Feature> get features => const <Feature>[];
  Iterable<MapLiteralUse> get mapLiterals => const <MapLiteralUse>[];
  Iterable<SetLiteralUse> get setLiterals => const <SetLiteralUse>[];
  Iterable<ListLiteralUse> get listLiterals => const <ListLiteralUse>[];
  Iterable<String> get constSymbolNames => const <String>[];
  Iterable<ConstantValue> get constantLiterals => const <ConstantValue>[];
  Iterable<ClassEntity> get seenClasses => const <ClassEntity>[];
  Iterable<RuntimeTypeUse> get runtimeTypeUses => const <RuntimeTypeUse>[];

  Iterable<dynamic> get nativeData => const <dynamic>[];

  Iterable<GenericInstantiation> get genericInstantiations =>
      const <GenericInstantiation>[];
}
