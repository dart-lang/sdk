// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/member_builder.dart';
import '../codes/cfe_codes.dart';
import 'compiler_context.dart';
import 'scope.dart';

abstract class LookupResult {
  /// The [NamedBuilder] used for reading this entity, if any.
  NamedBuilder? get getable;

  /// The [NamedBuilder] used for writing to this entity, if any.
  NamedBuilder? get setable;

  /// Returns `true` if the result is invalid.
  ///
  /// For instance because of duplicate declaration or because of an invalid
  /// scope origin.
  bool get isInvalidLookup;

  static LocatedMessage createDuplicateMessage(LookupResult lookupResult,
      {DeclarationBuilder? enclosingDeclaration,
      required String name,
      required Uri fileUri,
      required int fileOffset,
      required int length}) {
    if (name.isEmpty) {
      if (enclosingDeclaration != null) {
        name = enclosingDeclaration.name;
      } else {
        name = 'new';
      }
      length = noLength;
    }
    Message message = templateDuplicatedDeclarationUse.withArguments(name);
    return message.withLocation(fileUri, fileOffset, length);
  }

  static InvalidExpression createDuplicateExpression(LookupResult lookupResult,
      {required CompilerContext context,
      DeclarationBuilder? enclosingDeclaration,
      required String name,
      required Uri fileUri,
      required int fileOffset,
      required int length}) {
    String text = context
        .format(
            createDuplicateMessage(lookupResult,
                enclosingDeclaration: enclosingDeclaration,
                name: name,
                fileUri: fileUri,
                fileOffset: fileOffset,
                length: length),
            Severity.error)
        .plain;
    return new InvalidExpression(text)..fileOffset = fileOffset;
  }

  /// Creates a [LookupResult] for [getable] and [setable] which filters
  /// instance members if [staticOnly] is `true`, and creates an
  /// [AmbiguousBuilder] for duplicates using [fileUri] and [fileOffset].
  static LookupResult? createProcessedResult(LookupResult? result,
      {required String name,
      required Uri fileUri,
      required int fileOffset,
      required bool staticOnly}) {
    if (result == null) return null;
    NamedBuilder? getable = result.getable;
    NamedBuilder? setable = result.setable;
    bool changed = false;
    if (getable != null) {
      if (getable.next != null) {
        // Coverage-ignore-block(suite): Not run.
        getable = new AmbiguousBuilder(name, getable, fileOffset, fileUri);
        changed = true;
      }
      if (staticOnly && getable.isDeclarationInstanceMember) {
        getable = null;
        changed = true;
      }
    }
    if (setable != null) {
      if (setable.next != null) {
        // Coverage-ignore-block(suite): Not run.
        setable = new AmbiguousBuilder(name, setable, fileOffset, fileUri);
        changed = true;
      }
      if (staticOnly && setable.isDeclarationInstanceMember) {
        setable = null;
        changed = true;
      }
    }
    if (!changed) {
      return result;
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
      if (setable == getable) {
        return lookupResult;
      } else if (setable == null) {
        return lookupResult;
      } else {
        assert(getable != setable,
            "Unexpected getable $getable and setable $setable.");
        assert(
            !assertNoGetterSetterConflict ||
                // Coverage-ignore(suite): Not run.
                lookupResult.setable == null,
            "Unexpected setable ${lookupResult.setable} from "
            "getable $getable and setable $setable.");
        return new GetableSetableResult(getable!, setable);
      }
    } else if (setable is LookupResult) {
      // Coverage-ignore-block(suite): Not run.
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
      // Coverage-ignore-block(suite): Not run.
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

  static void addNamedBuilder(
      Map<String, LookupResult> content, String name, NamedBuilder member,
      {required bool setter}) {
    LookupResult? existing = content[name];
    if (existing != null) {
      if (setter) {
        assert(existing.getable != null,
            "No existing getable for $name: $existing, trying to add $member.");
        content[name] = new GetableSetableResult(existing.getable!, member);
        return;
      } else {
        assert(existing.setable != null,
            "No existing setable for $name: $existing, trying to add $member.");
        content[name] = new GetableSetableResult(member, existing.setable!);
        return;
      }
    }
    if (member is LookupResult) {
      content[name] = member as LookupResult;
    } else {
      // Coverage-ignore-block(suite): Not run.
      content[name] =
          setter ? new SetableResult(member) : new GetableResult(member);
    }
  }
}

abstract class InvalidLookupResult implements LookupResult {
  factory InvalidLookupResult(LocatedMessage message) =
      _InvalidLookupResultImpl;

  LocatedMessage get message;
}

// Coverage-ignore(suite): Not run.
class _InvalidLookupResultImpl implements InvalidLookupResult {
  @override
  final LocatedMessage message;

  _InvalidLookupResultImpl(this.message);

  @override
  bool get isInvalidLookup => true;

  @override
  NamedBuilder? get getable => null;

  @override
  NamedBuilder? get setable => null;
}

abstract class MemberLookupResult implements LookupResult {
  /// The [MemberBuilder] used for reading this entity, if any.
  @override
  MemberBuilder? get getable;

  /// The [MemberBuilder] used for writing to this entity, if any.
  @override
  MemberBuilder? get setable;

  /// Return `true` if this [MemberBuilder]s of this lookup result are accessed
  /// statically.
  bool get isStatic;
}

class InvalidMemberLookupResult
    implements InvalidLookupResult, MemberLookupResult {
  @override
  final LocatedMessage message;

  InvalidMemberLookupResult(this.message);

  @override
  bool get isInvalidLookup => true;

  @override
  // Coverage-ignore(suite): Not run.
  MemberBuilder? get getable => null;

  @override
  // Coverage-ignore(suite): Not run.
  MemberBuilder? get setable => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isStatic => true;
}

class GetableResult with LookupResultMixin implements LookupResult {
  @override
  final NamedBuilder getable;

  GetableResult(this.getable);

  @override
  NamedBuilder? get setable => null;
}

// Coverage-ignore(suite): Not run.
class SetableResult with LookupResultMixin implements LookupResult {
  @override
  final NamedBuilder setable;

  SetableResult(this.setable);

  @override
  NamedBuilder? get getable => null;
}

class GetableSetableResult with LookupResultMixin implements LookupResult {
  @override
  final NamedBuilder getable;

  @override
  final NamedBuilder setable;

  GetableSetableResult(this.getable, this.setable);
}

mixin LookupResultMixin implements LookupResult {
  @override
  bool get isInvalidLookup =>
      (getable?.isDuplicate ?? false) || (setable?.isDuplicate ?? false);
}

class DuplicateMemberLookupResult implements MemberLookupResult {
  final List<MemberBuilder> declarations;

  DuplicateMemberLookupResult(this.declarations);

  @override
  MemberBuilder? get getable => null;

  @override
  bool get isInvalidLookup => true;

  @override
  MemberBuilder? get setable => null;

  /// Return `true` if this [MemberBuilder]s of this lookup result are accessed
  /// statically.
  ///
  /// Since this lookup can contain both static and non-static members, we
  /// return `true` so that it will not be filtered in static member lookup.
  @override
  bool get isStatic => true;
}
