// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../builder/builder.dart';
import '../builder/member_builder.dart';
import 'scope.dart';

abstract class LookupResult {
  /// The [NamedBuilder] used for reading this entity, if any.
  NamedBuilder? get getable;

  /// The [NamedBuilder] used for writing to this entity, if any.
  NamedBuilder? get setable;

  /// Creates a [LookupResult] for [getable] and [setable] which filters
  /// instance members if [staticOnly] is `true`, and creates an
  /// [AmbiguousBuilder] for duplicates using [fileUri] and [fileOffset].
  static LookupResult? createProcessedResult(
      NamedBuilder? getable, NamedBuilder? setable,
      {required String name,
      required Uri fileUri,
      required int fileOffset,
      required bool staticOnly}) {
    if (getable != null) {
      if (getable.next != null) {
        getable = new AmbiguousBuilder(name, getable, fileOffset, fileUri);
      }
      if (staticOnly && getable.isDeclarationInstanceMember) {
        getable = null;
      }
    }
    if (setable != null) {
      if (setable.next != null) {
        AmbiguousBuilder ambiguousBuilder =
            setable = new AmbiguousBuilder(name, setable, fileOffset, fileUri);
        Builder firstSetable = ambiguousBuilder.getFirstDeclaration();
        if (firstSetable is MemberBuilder && firstSetable.isConflictingSetter) {
          setable = null;
        }
      } else if (setable is MemberBuilder && setable.isConflictingSetter) {
        setable = null;
      }
      if (setable != null &&
          staticOnly &&
          setable.isDeclarationInstanceMember) {
        setable = null;
      }
    }

    return _fromBuilders(getable, setable, assertNoGetterSetterConflict: true);
  }

  static LookupResult? createResult(
      NamedBuilder? getable, NamedBuilder? setable) {
    return _fromBuilders(getable, setable, assertNoGetterSetterConflict: false);
  }

  static LookupResult? _fromBuilders(
      NamedBuilder? getable, NamedBuilder? setable,
      {required bool assertNoGetterSetterConflict}) {
    if (getable is LookupResult) {
      LookupResult lookupResult = getable as LookupResult;
      if (setable == null) {
        return lookupResult;
      } else {
        assert(getable != setable,
            "Unexpected getable $getable and setable $setable.");
        assert(
            !assertNoGetterSetterConflict || lookupResult.setable == null,
            "Unexpected setable ${lookupResult.setable} from "
            "getable $getable and setable $setable.");
        return new GetableSetableResult(getable!, setable);
      }
    } else if (setable is LookupResult) {
      LookupResult lookupResult = setable as LookupResult;
      if (getable == null) {
        return lookupResult;
      } else {
        assert(getable != setable,
            "Unexpected getable $getable and setable $setable.");
        assert(
            !assertNoGetterSetterConflict || lookupResult.getable == null,
            "Unexpected getable ${lookupResult.getable} from "
            "setable $setable and getable $getable.");
        return new GetableSetableResult(getable, setable!);
      }
    } else {
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
}

class GetableResult implements LookupResult {
  @override
  final NamedBuilder getable;

  GetableResult(this.getable);

  @override
  NamedBuilder? get setable => null;
}

class SetableResult implements LookupResult {
  @override
  final NamedBuilder setable;

  SetableResult(this.setable);

  @override
  NamedBuilder? get getable => null;
}

class GetableSetableResult implements LookupResult {
  @override
  final NamedBuilder getable;

  @override
  final NamedBuilder setable;

  GetableSetableResult(this.getable, this.setable);
}
