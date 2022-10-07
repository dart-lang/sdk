// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../elements/entities.dart';
import '../serialization/serialization.dart';
import 'locals.dart';

/// [LocalLookup] implementation used to deserialize [JsClosedWorld].
class LocalLookupImpl implements LocalLookup {
  final GlobalLocalsMap _globalLocalsMap;

  LocalLookupImpl(this._globalLocalsMap);

  @override
  Local getLocalByIndex(MemberEntity memberContext, int index) {
    final map = _globalLocalsMap.getLocalsMap(memberContext);
    return map.getLocalByIndex(index);
  }
}
