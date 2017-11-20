// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// None of these methods have any side effects, but using [Selector] count to
// order side-effects computation will make [_callNoSideEffectsManyTimes] be
// computed last and thus make [callCallNoSideEffectsManyTimes] and with it
// [main] assume all side-effects from the call to
// [_callNoSideEffectsManyTimes].
//
// The methods are deliberately put in order of increasing [Selector] count to
// make the [InferrerEngineImpl.useSorterForTesting] flag mimmick the order in
// the old inference.

/*element: _noSideEffects:Depends on nothing, Changes nothing.*/
_noSideEffects() {}

/*element: callCallNoSideEffectsManyTimes:Depends on [] field store static store, Changes [] field static.*/
callCallNoSideEffectsManyTimes() {
  _callNoSideEffectsManyTimes();
}

/*element: main:Depends on [] field store static store, Changes [] field static.*/
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
