// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/world_interfaces.dart';
import 'package:compiler/src/universe/selector.dart';

class MemberAppliesTo {
  final MemberEntity member;
  AbstractValue mask;

  MemberAppliesTo(this.member, this.mask);

  @override
  String toString() => 'MemberAppliesTo($member:$mask)';
}

class MemberAppliesToBuilder {
  final JClosedWorld _closedWorld;
  final Map<Selector, Iterable<MemberAppliesTo>> _memberSetsBySelector = {};
  final Map<Selector, List<MemberEntity>> _membersBySelector = {};

  MemberAppliesToBuilder(this._closedWorld) {
    for (final member in _closedWorld.liveInstanceMembers) {
      if (member.isFunction || member.isGetter || member.isSetter) {
        (_membersBySelector[Selector.fromElement(member)] ??= []).add(member);
      }
    }
  }

  Iterable<MemberAppliesTo> _buildSets(Selector selector) {
    final List<MemberAppliesTo> memberSets = [];
    final members = _membersBySelector.remove(selector);
    if (members == null) {
      return selector == Selectors.noSuchMethod_
          ? const []
          : forSelector(Selectors.noSuchMethod_);
    }
    for (final member in members) {
      // TODO(fishythefish): Use type cone mask here.
      final mask = _closedWorld.abstractValueDomain
          .createNonNullSubclass(member.enclosingClass!);
      final memberSet = MemberAppliesTo(member, mask);
      memberSets.add(memberSet);
    }
    return memberSets;
  }

  Iterable<MemberAppliesTo> forSelector(Selector selector) =>
      _memberSetsBySelector[selector] ??= _buildSets(selector);
}
