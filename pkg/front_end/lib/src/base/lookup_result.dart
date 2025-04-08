// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';

abstract class LookupResult {
  /// The [Builder] used for reading this entity, if any.
  Builder? get getable;

  /// The [Builder] used for writing to this entity, if any.
  Builder? get setable;

  static LookupResult? fromBuilders(Builder? getable, Builder? setable) {
    if (getable != null && setable != null) {
      return new GetableSetableResult(getable, setable);
    } else if (getable != null) {
      return new GetableResult(getable);
    } else if (setable != null) {
      return new SetableResult(setable);
    } else {
      return null;
    }
  }
}

class GetableResult implements LookupResult {
  @override
  final Builder getable;

  GetableResult(this.getable);

  @override
  Builder? get setable => null;
}

class SetableResult implements LookupResult {
  @override
  final Builder setable;

  SetableResult(this.setable);

  @override
  Builder? get getable => null;
}

class GetableSetableResult implements LookupResult {
  @override
  final Builder getable;

  @override
  final Builder setable;

  GetableSetableResult(this.getable, this.setable);
}
