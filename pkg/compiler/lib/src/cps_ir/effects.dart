// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.cps_ir.effects;

import 'dart:typed_data';
import '../universe/side_effects.dart' show SideEffects;

/// Bitmasks for tracking non-local side effects and dependencies.
///
/// All effects must be attributed to an effect area.  The `other` area is a
/// catch-all for any effect that does not belong to any of the specific areas;
/// this includes external effects such as printing to the console.
class Effects {
  // Effect areas.
  // These are bit positions, not bit masks. They are private because it is
  // otherwise easy to mistake them for bitmasks.
  static const int _staticField = 0;
  static const int _instanceField = 1;
  static const int _indexableContent = 2;
  static const int _indexableLength = 3;
  static const int _other = 4;
  static const int numberOfEffectAreas = 5;

  // Bitmasks for computation that modifies state in a given area.
  static const int _changes = 1;
  static const int changesStaticField = _changes << _staticField;
  static const int changesInstanceField = _changes << _instanceField;
  static const int changesIndexableContent = _changes << _indexableContent;
  static const int changesIndexableLength = _changes << _indexableLength;
  static const int changesOther = _changes << _other;

  static const int changesAll =
      changesStaticField |
      changesInstanceField |
      changesIndexableContent |
      changesIndexableLength |
      changesOther;

  // Bitmasks for computation that depends on state in a given area.
  static const int _depends = 1 << numberOfEffectAreas;
  static const int dependsOnStaticField = _depends << _staticField;
  static const int dependsOnInstanceField = _depends << _instanceField;
  static const int dependsOnIndexableContent = _depends << _indexableContent;
  static const int dependsOnIndexableLength = _depends << _indexableLength;
  static const int dependsOnOther = _depends << _other;

  static const int dependsOnAll =
      dependsOnStaticField |
      dependsOnInstanceField |
      dependsOnIndexableContent |
      dependsOnIndexableLength |
      dependsOnOther;

  static const int all = changesAll | dependsOnAll;
  static const int none = 0;

  static int _changesArea(int effectArea) => _changes << effectArea;

  static int _dependsOnArea(int effectArea) => _depends << effectArea;

  static int changesToDepends(int changesFlags) {
    return (changesFlags & changesAll) << numberOfEffectAreas;
  }

  static int dependsToChanges(int dependsFlags) {
    return (dependsFlags & dependsOnAll) >> numberOfEffectAreas;
  }

  /// Converts [SideEffects] from a JS annotation or type inference to the
  /// more fine-grained flag set.
  //
  // TODO(asgerf): Once we finalize the set of flags to use, unify the two
  //               systems.
  static int from(SideEffects fx) {
    int result = 0;
    if (fx.changesInstanceProperty()) {
      result |= changesInstanceField;
    }
    if (fx.changesStaticProperty()) {
      result |= changesStaticField;
    }
    if (fx.changesIndex()) {
      result |= changesIndexableContent | changesIndexableLength;
    }
    if (fx.hasSideEffects()) {
      result |= changesOther;
    }
    if (fx.dependsOnInstancePropertyStore()) {
      result |= dependsOnInstanceField;
    }
    if (fx.dependsOnStaticPropertyStore()) {
      result |= dependsOnStaticField;
    }
    if (fx.dependsOnIndexStore()) {
      result |= dependsOnIndexableContent | dependsOnIndexableLength;
    }
    if (fx.dependsOnSomething()) {
      result |= dependsOnOther;
    }
    return result;
  }
}

/// Creates fresh IDs to ensure effect numbers do not clash with each other.
class EffectNumberer {
  int _id = 0;
  int next() => ++_id;

  /// Special effect number that can be used in place for an effect area that
  /// is irrelevant for a computation.
  ///
  /// This value is never returned by [next].
  static const int none = 0;
}

/// A mutable vector of effect numbers, one for each effect area.
///
/// Effect numbers are used to identify regions of code wherein the given
/// effect area is unmodified.
class EffectNumbers {
  final Int32List _effectNumbers = new Int32List(Effects.numberOfEffectAreas);

  EffectNumbers._zero();

  EffectNumbers.fresh(EffectNumberer numberer) {
    reset(numberer);
  }

  EffectNumbers copy() {
    return new EffectNumbers._zero().._effectNumbers.setAll(0, _effectNumbers);
  }

  int operator[](int i) => _effectNumbers[i];

  void operator[]=(int i, int value) {
    _effectNumbers[i] = value;
  }

  int get staticField => _effectNumbers[Effects._staticField];
  int get instanceField => _effectNumbers[Effects._instanceField];
  int get indexableContent => _effectNumbers[Effects._indexableContent];
  int get indexableLength => _effectNumbers[Effects._indexableLength];
  int get other => _effectNumbers[Effects._other];

  void set staticField(int n) {
    _effectNumbers[Effects._staticField] = n;
  }
  void set instanceField(int n) {
    _effectNumbers[Effects._instanceField] = n;
  }
  void set indexableContent(int n) {
    _effectNumbers[Effects._indexableContent] = n;
  }
  void set indexableLength(int n) {
    _effectNumbers[Effects._indexableLength] = n;
  }
  void set other(int n) {
    _effectNumbers[Effects._other] = n;
  }

  void reset(EffectNumberer numberer) {
    for (int i = 0; i < Effects.numberOfEffectAreas; ++i) {
      _effectNumbers[i] = numberer.next();
    }
  }

  void join(EffectNumberer numberer, EffectNumbers other) {
    for (int i = 0; i < Effects.numberOfEffectAreas; ++i) {
      if (_effectNumbers[i] != other._effectNumbers[i]) {
        _effectNumbers[i] = numberer.next();
      }
    }
  }

  void change(EffectNumberer numberer, int changeFlags) {
    for (int i = 0; i < Effects.numberOfEffectAreas; ++i) {
      if (changeFlags & Effects._changesArea(i) != 0) {
        _effectNumbers[i] = numberer.next();
      }
    }
  }

  /// Builds a vector where all entries that are not depended on are replaced
  /// by [EffectNumberer.none].
  //
  // TODO(asgerf): Use this in GVN to simplify the dispatching code.
  List<int> getDependencies(int dependsFlags) {
    Int32List copy = new Int32List.fromList(_effectNumbers);
    for (int i = 0; i < Effects.numberOfEffectAreas; ++i) {
      if (dependsFlags & Effects._dependsOnArea(i) == 0) {
        copy[i] = EffectNumberer.none;
      }
    }
    return copy;
  }
}
