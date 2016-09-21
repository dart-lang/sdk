// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.universe.world_impact;

import '../elements/elements.dart' show Element;
import '../util/util.dart' show Setlet;
import 'use.dart' show DynamicUse, StaticUse, TypeUse;

/// Describes how an element (e.g. a method) impacts the closed-world
/// semantics of a program.
///
/// A [WorldImpact] contains information about how a program element affects our
/// understanding of what's live in a program. For example, it can indicate
/// that a method uses a certain feature, or allocates a specific type.
///
/// The impact object can be computed locally by inspecting just the resolution
/// information of that element alone. The compiler uses [Universe] and
/// [ClassWorld] to combine the information discovered in the impact objects of
/// all elements reachable in an application.
class WorldImpact {
  const WorldImpact();

  Iterable<DynamicUse> get dynamicUses => const <DynamicUse>[];

  Iterable<StaticUse> get staticUses => const <StaticUse>[];

  // TODO(johnniwinther): Replace this by called constructors with type
  // arguments.
  // TODO(johnniwinther): Collect all checked types for checked mode separately
  // to support serialization.

  Iterable<TypeUse> get typeUses => const <TypeUse>[];

  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach(visitor.visitStaticUse);
    dynamicUses.forEach(visitor.visitDynamicUse);
    typeUses.forEach(visitor.visitTypeUse);
  }

  String toString() => dump(this);

  static String dump(WorldImpact worldImpact) {
    StringBuffer sb = new StringBuffer();
    printOn(sb, worldImpact);
    return sb.toString();
  }

  static void printOn(StringBuffer sb, WorldImpact worldImpact) {
    void add(String title, Iterable iterable) {
      if (iterable.isNotEmpty) {
        sb.write('\n $title:');
        iterable.forEach((e) => sb.write('\n  $e'));
      }
    }

    add('dynamic uses', worldImpact.dynamicUses);
    add('static uses', worldImpact.staticUses);
    add('type uses', worldImpact.typeUses);
  }
}

class WorldImpactBuilder {
  // TODO(johnniwinther): Do we benefit from lazy initialization of the
  // [Setlet]s?
  Setlet<DynamicUse> _dynamicUses;
  Setlet<StaticUse> _staticUses;
  Setlet<TypeUse> _typeUses;

  void registerDynamicUse(DynamicUse dynamicUse) {
    assert(dynamicUse != null);
    if (_dynamicUses == null) {
      _dynamicUses = new Setlet<DynamicUse>();
    }
    _dynamicUses.add(dynamicUse);
  }

  Iterable<DynamicUse> get dynamicUses {
    return _dynamicUses != null ? _dynamicUses : const <DynamicUse>[];
  }

  void registerTypeUse(TypeUse typeUse) {
    assert(typeUse != null);
    if (_typeUses == null) {
      _typeUses = new Setlet<TypeUse>();
    }
    _typeUses.add(typeUse);
  }

  Iterable<TypeUse> get typeUses {
    return _typeUses != null ? _typeUses : const <TypeUse>[];
  }

  void registerStaticUse(StaticUse staticUse) {
    assert(staticUse != null);
    if (_staticUses == null) {
      _staticUses = new Setlet<StaticUse>();
    }
    _staticUses.add(staticUse);
  }

  Iterable<StaticUse> get staticUses {
    return _staticUses != null ? _staticUses : const <StaticUse>[];
  }
}

/// Mutable implementation of [WorldImpact] used to transform
/// [ResolutionImpact] or [CodegenImpact] to [WorldImpact].
class TransformedWorldImpact implements WorldImpact {
  final WorldImpact worldImpact;

  Setlet<StaticUse> _staticUses;
  Setlet<TypeUse> _typeUses;
  Setlet<DynamicUse> _dynamicUses;

  TransformedWorldImpact(this.worldImpact);

  @override
  Iterable<DynamicUse> get dynamicUses {
    return _dynamicUses != null ? _dynamicUses : worldImpact.dynamicUses;
  }

  void registerDynamicUse(DynamicUse dynamicUse) {
    if (_dynamicUses == null) {
      _dynamicUses = new Setlet<DynamicUse>();
      _dynamicUses.addAll(worldImpact.dynamicUses);
    }
    _dynamicUses.add(dynamicUse);
  }

  void registerTypeUse(TypeUse typeUse) {
    if (_typeUses == null) {
      _typeUses = new Setlet<TypeUse>();
      _typeUses.addAll(worldImpact.typeUses);
    }
    _typeUses.add(typeUse);
  }

  @override
  Iterable<TypeUse> get typeUses {
    return _typeUses != null ? _typeUses : worldImpact.typeUses;
  }

  void registerStaticUse(StaticUse staticUse) {
    if (_staticUses == null) {
      _staticUses = new Setlet<StaticUse>();
      _staticUses.addAll(worldImpact.staticUses);
    }
    _staticUses.add(staticUse);
  }

  @override
  Iterable<StaticUse> get staticUses {
    return _staticUses != null ? _staticUses : worldImpact.staticUses;
  }

  void apply(WorldImpactVisitor visitor) {
    staticUses.forEach(visitor.visitStaticUse);
    dynamicUses.forEach(visitor.visitDynamicUse);
    typeUses.forEach(visitor.visitTypeUse);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('TransformedWorldImpact($worldImpact)');
    WorldImpact.printOn(sb, this);
    return sb.toString();
  }
}

/// Constant used to denote a specific use of a [WorldImpact].
class ImpactUseCase {
  final String name;

  const ImpactUseCase(this.name);

  String toString() => 'ImpactUseCase($name)';
}

/// Strategy used for processing [WorldImpact] object in various use cases.
class ImpactStrategy {
  const ImpactStrategy();

  /// Applies [impact] to [visitor] for the [impactUseCase] of [element].
  void visitImpact(Element element, WorldImpact impact,
      WorldImpactVisitor visitor, ImpactUseCase impactUseCase) {
    // Apply unconditionally.
    impact.apply(visitor);
  }

  /// Notifies the strategy that no more impacts of [impactUseCase] will be
  /// applied.
  void onImpactUsed(ImpactUseCase impactUseCase) {
    // Do nothing.
  }
}

/// Visitor used to process the uses of a [WorldImpact].
abstract class WorldImpactVisitor {
  void visitStaticUse(StaticUse staticUse);
  void visitDynamicUse(DynamicUse dynamicUse);
  void visitTypeUse(TypeUse typeUse);
}

// TODO(johnniwinther): Remove these when we get anonymous local classes.
typedef void VisitUse<U>(U use);

class WorldImpactVisitorImpl implements WorldImpactVisitor {
  final VisitUse<StaticUse> _visitStaticUse;
  final VisitUse<DynamicUse> _visitDynamicUse;
  final VisitUse<TypeUse> _visitTypeUse;

  WorldImpactVisitorImpl(
      {VisitUse<StaticUse> visitStaticUse,
      VisitUse<DynamicUse> visitDynamicUse,
      VisitUse<TypeUse> visitTypeUse})
      : _visitStaticUse = visitStaticUse,
        _visitDynamicUse = visitDynamicUse,
        _visitTypeUse = visitTypeUse;

  @override
  void visitStaticUse(StaticUse use) {
    if (_visitStaticUse != null) {
      _visitStaticUse(use);
    }
  }

  @override
  void visitDynamicUse(DynamicUse use) {
    if (_visitDynamicUse != null) {
      _visitDynamicUse(use);
    }
  }

  @override
  void visitTypeUse(TypeUse use) {
    if (_visitTypeUse != null) {
      _visitTypeUse(use);
    }
  }
}
