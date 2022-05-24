// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

library dart2js.universe.world_impact;

import '../elements/entities.dart';
import '../util/util.dart' show Setlet;
import 'use.dart';

/// Describes how an element (e.g. a method) impacts the closed-world
/// semantics of a program.
///
/// A [WorldImpact] contains information about how a program element affects our
/// understanding of what's live in a program. For example, it can indicate
/// that a method uses a certain feature, or allocates a specific type.
///
/// The impact object can be computed locally by inspecting just the resolution
/// information of that element alone. The compiler uses [Universe] and
/// [World] to combine the information discovered in the impact objects of
/// all elements reachable in an application.
class WorldImpact {
  const WorldImpact();

  MemberEntity get member => null;

  Iterable<DynamicUse> get dynamicUses => const [];

  Iterable<StaticUse> get staticUses => const [];

  // TODO(johnniwinther): Replace this by called constructors with type
  // arguments.
  // TODO(johnniwinther): Collect all checked types for checked mode separately
  // to support serialization.

  Iterable<TypeUse> get typeUses => const [];

  Iterable<ConstantUse> get constantUses => const [];

  void _forEach<U>(Iterable<U> uses, void Function(MemberEntity, U) visitUse) =>
      uses.forEach((use) => visitUse(member, use));

  void forEachDynamicUse(void Function(MemberEntity, DynamicUse) visitUse) =>
      _forEach(dynamicUses, visitUse);
  void forEachStaticUse(void Function(MemberEntity, StaticUse) visitUse) =>
      _forEach(staticUses, visitUse);
  void forEachTypeUse(void Function(MemberEntity, TypeUse) visitUse) =>
      _forEach(typeUses, visitUse);
  void forEachConstantUse(void Function(MemberEntity, ConstantUse) visitUse) =>
      _forEach(constantUses, visitUse);

  bool get isEmpty => true;

  @override
  String toString() => dump(this);

  static String dump(WorldImpact worldImpact) {
    StringBuffer sb = StringBuffer();
    printOn(sb, worldImpact);
    return sb.toString();
  }

  static void printOn(StringBuffer sb, WorldImpact worldImpact) {
    sb.write('member: ${worldImpact.member}');

    void add(String title, Iterable iterable) {
      if (iterable.isNotEmpty) {
        sb.write('\n $title:');
        iterable.forEach((e) => sb.write('\n  $e'));
      }
    }

    add('dynamic uses', worldImpact.dynamicUses);
    add('static uses', worldImpact.staticUses);
    add('type uses', worldImpact.typeUses);
    add('constant uses', worldImpact.constantUses);
  }
}

abstract class WorldImpactBuilder extends WorldImpact {
  void registerDynamicUse(DynamicUse dynamicUse);
  void registerTypeUse(TypeUse typeUse);
  void registerStaticUse(StaticUse staticUse);
  void registerConstantUse(ConstantUse constantUse);
}

class WorldImpactBuilderImpl extends WorldImpactBuilder {
  /// The [MemberEntity] associated with this set of impacts. Maybe null.
  @override
  final MemberEntity member;

  // TODO(johnniwinther): Do we benefit from lazy initialization of the
  // [Setlet]s?
  Set<DynamicUse> _dynamicUses;
  Set<StaticUse> _staticUses;
  Set<TypeUse> _typeUses;
  Set<ConstantUse> _constantUses;

  WorldImpactBuilderImpl([this.member]);

  WorldImpactBuilderImpl.internal(
      this._dynamicUses, this._staticUses, this._typeUses, this._constantUses,
      {this.member});

  @override
  bool get isEmpty =>
      _dynamicUses == null &&
      _staticUses == null &&
      _typeUses == null &&
      _constantUses == null;

  /// Copy uses in [impact] to this impact builder.
  void addImpact(WorldImpact impact) {
    if (impact.isEmpty) return;
    impact.dynamicUses.forEach(registerDynamicUse);
    impact.staticUses.forEach(registerStaticUse);
    impact.typeUses.forEach(registerTypeUse);
    impact.constantUses.forEach(registerConstantUse);
  }

  @override
  void registerDynamicUse(DynamicUse dynamicUse) {
    assert(dynamicUse != null);
    _dynamicUses ??= Setlet();
    _dynamicUses.add(dynamicUse);
  }

  @override
  Iterable<DynamicUse> get dynamicUses {
    return _dynamicUses ?? const [];
  }

  @override
  void registerTypeUse(TypeUse typeUse) {
    assert(typeUse != null);
    _typeUses ??= Setlet();
    _typeUses.add(typeUse);
  }

  @override
  Iterable<TypeUse> get typeUses {
    return _typeUses ?? const [];
  }

  @override
  void registerStaticUse(StaticUse staticUse) {
    assert(staticUse != null);
    _staticUses ??= Setlet();
    _staticUses.add(staticUse);
  }

  @override
  Iterable<StaticUse> get staticUses {
    return _staticUses ?? const [];
  }

  @override
  void registerConstantUse(ConstantUse constantUse) {
    assert(constantUse != null);
    _constantUses ??= Setlet();
    _constantUses.add(constantUse);
  }

  @override
  Iterable<ConstantUse> get constantUses {
    return _constantUses ?? const [];
  }
}

/// Mutable implementation of [WorldImpact] used to transform
/// [ResolutionImpact] or [CodegenImpact] to [WorldImpact].
class TransformedWorldImpact extends WorldImpactBuilder {
  final WorldImpact worldImpact;

  Setlet<StaticUse> _staticUses;
  Setlet<TypeUse> _typeUses;
  Setlet<DynamicUse> _dynamicUses;
  Setlet<ConstantUse> _constantUses;

  TransformedWorldImpact(this.worldImpact);

  @override
  MemberEntity get member => worldImpact.member;

  @override
  bool get isEmpty {
    return worldImpact.isEmpty &&
        _staticUses == null &&
        _typeUses == null &&
        _dynamicUses == null &&
        _constantUses == null;
  }

  @override
  Iterable<DynamicUse> get dynamicUses {
    return _dynamicUses ?? worldImpact.dynamicUses;
  }

  @override
  void registerDynamicUse(DynamicUse dynamicUse) {
    _dynamicUses ??= Setlet.of(worldImpact.dynamicUses);
    _dynamicUses.add(dynamicUse);
  }

  @override
  void registerTypeUse(TypeUse typeUse) {
    _typeUses ??= Setlet.of(worldImpact.typeUses);
    _typeUses.add(typeUse);
  }

  @override
  Iterable<TypeUse> get typeUses {
    return _typeUses ?? worldImpact.typeUses;
  }

  @override
  void registerStaticUse(StaticUse staticUse) {
    _staticUses ??= Setlet.of(worldImpact.staticUses);
    _staticUses.add(staticUse);
  }

  @override
  Iterable<StaticUse> get staticUses {
    return _staticUses ?? worldImpact.staticUses;
  }

  @override
  Iterable<ConstantUse> get constantUses {
    return _constantUses ?? worldImpact.constantUses;
  }

  @override
  void registerConstantUse(ConstantUse constantUse) {
    _constantUses ??= Setlet.of(worldImpact.constantUses);
    _constantUses.add(constantUse);
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('TransformedWorldImpact($worldImpact)');
    WorldImpact.printOn(sb, this);
    return sb.toString();
  }
}
