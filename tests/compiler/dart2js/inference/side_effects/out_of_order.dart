// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the capability of the side effects computation based on
// [SideEffectsBuilder].
//
// None of these methods have any side effects, but the old side effects
// computation, based on [Selector] count, computed
// [_callNoSideEffectsManyTimes] last and thus made
// [callCallNoSideEffectsManyTimes] and with it [main] assume all side-effects
// from the call to [_callNoSideEffectsManyTimes].
//
// The new computation, based on [SideEffectsBuilder], computes the precise
// result regardless of computation order.

/*element: _noSideEffects:Depends on nothing, Changes nothing.*/
_noSideEffects() {}

/*element: callCallNoSideEffectsManyTimes:Depends on nothing, Changes nothing.*/
callCallNoSideEffectsManyTimes() {
  _callNoSideEffectsManyTimes();
}

/*element: main:Depends on nothing, Changes nothing.*/
main() {
  callCallNoSideEffectsManyTimes();
  callCallNoSideEffectsManyTimes();
}

/*element: _callNoSideEffectsManyTimes:Depends on nothing, Changes nothing.*/
_callNoSideEffectsManyTimes() {
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
  _noSideEffects();
}
