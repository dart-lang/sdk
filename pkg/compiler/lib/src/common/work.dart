// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.common.work;

import '../elements/entities.dart' show MemberEntity;
import '../universe/world_impact.dart' show WorldImpact;

abstract class WorkItem {
  /// Element on which the work will be done.
  MemberEntity get element;

  WorldImpact run();
}
