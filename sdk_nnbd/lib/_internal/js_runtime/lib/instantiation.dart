// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

/// Support class for generic function type instantiation (binding of types).
///
abstract class Instantiation extends Closure {
  final Closure _genericClosure;
  Instantiation(this._genericClosure) {
    // TODO(sra): Copy some metadata used by Function.apply.

    // Mark support code as used.  The JS condition is inscrutable to dart2js,
    // so the 'if (false)' is in the final program.
    // TODO(sra): Find a better way to do this. Generating the signature methods
    // earlier as SSA on the instantiation closures should achieve this.
    if (JS('bool', 'false')) {
      // [instantiatedGenericFunctionType] is called from injected $signature
      // methods with runtime type representations.
      if (JS_GET_FLAG('USE_NEW_RTI')) {
        newRti.instantiatedGenericFunctionType(JS('', '0'), JS('', '0'));
      } else {
        instantiatedGenericFunctionType(JS('', '0'), JS('', '0'));
      }
    }
  }

  /// Returns a list of the bound types.
  List get _types;

  String toString() {
    var types = "<${_types.join(', ')}>";
    // TODO(sra): Refactor Closure formatting to place type arguments inside,
    // e.g. "Closure 'map<String>' of Instance of 'JSArray<int>'".
    return '$_genericClosure with $types';
  }
}

/// Instantiation classes are subclasses of [Instantiation]. For now we have a
/// fixed number of subclasses. Later we might generate the classes on demand.
class Instantiation1<T1> extends Instantiation {
  Instantiation1(Closure f) : super(f);
  List get _types => [T1];
}

class Instantiation2<T1, T2> extends Instantiation {
  Instantiation2(Closure f) : super(f);
  List get _types => [T1, T2];
}

class Instantiation3<T1, T2, T3> extends Instantiation {
  Instantiation3(Closure f) : super(f);
  List get _types => [T1, T2, T3];
}

class Instantiation4<T1, T2, T3, T4> extends Instantiation {
  Instantiation4(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4];
}

class Instantiation5<T1, T2, T3, T4, T5> extends Instantiation {
  Instantiation5(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5];
}

class Instantiation6<T1, T2, T3, T4, T5, T6> extends Instantiation {
  Instantiation6(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6];
}

class Instantiation7<T1, T2, T3, T4, T5, T6, T7> extends Instantiation {
  Instantiation7(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7];
}

class Instantiation8<T1, T2, T3, T4, T5, T6, T7, T8> extends Instantiation {
  Instantiation8(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7, T8];
}

class Instantiation9<T1, T2, T3, T4, T5, T6, T7, T8, T9> extends Instantiation {
  Instantiation9(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7, T8, T9];
}

class Instantiation10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>
    extends Instantiation {
  Instantiation10(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10];
}

class Instantiation11<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>
    extends Instantiation {
  Instantiation11(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11];
}

class Instantiation12<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>
    extends Instantiation {
  Instantiation12(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12];
}

class Instantiation13<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13>
    extends Instantiation {
  Instantiation13(Closure f) : super(f);
  List get _types => [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13];
}

class Instantiation14<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14> extends Instantiation {
  Instantiation14(Closure f) : super(f);
  List get _types =>
      [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14];
}

class Instantiation15<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14, T15> extends Instantiation {
  Instantiation15(Closure f) : super(f);
  List get _types =>
      [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15];
}

class Instantiation16<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14, T15, T16> extends Instantiation {
  Instantiation16(Closure f) : super(f);
  List get _types =>
      [T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16];
}

class Instantiation17<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14, T15, T16, T17> extends Instantiation {
  Instantiation17(Closure f) : super(f);
  List get _types => [
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        T10,
        T11,
        T12,
        T13,
        T14,
        T15,
        T16,
        T17
      ];
}

class Instantiation18<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14, T15, T16, T17, T18> extends Instantiation {
  Instantiation18(Closure f) : super(f);
  List get _types => [
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        T10,
        T11,
        T12,
        T13,
        T14,
        T15,
        T16,
        T17,
        T18
      ];
}

class Instantiation19<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14, T15, T16, T17, T18, T19> extends Instantiation {
  Instantiation19(Closure f) : super(f);
  List get _types => [
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        T10,
        T11,
        T12,
        T13,
        T14,
        T15,
        T16,
        T17,
        T18,
        T19
      ];
}

class Instantiation20<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13,
    T14, T15, T16, T17, T18, T19, T20> extends Instantiation {
  Instantiation20(Closure f) : super(f);
  List get _types => [
        T1,
        T2,
        T3,
        T4,
        T5,
        T6,
        T7,
        T8,
        T9,
        T10,
        T11,
        T12,
        T13,
        T14,
        T15,
        T16,
        T17,
        T18,
        T19,
        T20
      ];
}

Instantiation instantiate1<T1>(Closure f) {
  return new Instantiation1<T1>(f);
}

Instantiation instantiate2<T1, T2>(Closure f) {
  return new Instantiation2<T1, T2>(f);
}

Instantiation instantiate3<T1, T2, T3>(Closure f) {
  return new Instantiation3<T1, T2, T3>(f);
}

Instantiation instantiate4<T1, T2, T3, T4>(Closure f) {
  return new Instantiation4<T1, T2, T3, T4>(f);
}

Instantiation instantiate5<T1, T2, T3, T4, T5>(Closure f) {
  return new Instantiation5<T1, T2, T3, T4, T5>(f);
}

Instantiation instantiate6<T1, T2, T3, T4, T5, T6>(Closure f) {
  return new Instantiation6<T1, T2, T3, T4, T5, T6>(f);
}

Instantiation instantiate7<T1, T2, T3, T4, T5, T6, T7>(Closure f) {
  return new Instantiation7<T1, T2, T3, T4, T5, T6, T7>(f);
}

Instantiation instantiate8<T1, T2, T3, T4, T5, T6, T7, T8>(Closure f) {
  return new Instantiation8<T1, T2, T3, T4, T5, T6, T7, T8>(f);
}

Instantiation instantiate9<T1, T2, T3, T4, T5, T6, T7, T8, T9>(Closure f) {
  return new Instantiation9<T1, T2, T3, T4, T5, T6, T7, T8, T9>(f);
}

Instantiation instantiate10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(
    Closure f) {
  return new Instantiation10<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(f);
}

Instantiation instantiate11<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(
    Closure f) {
  return new Instantiation11<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(f);
}

Instantiation instantiate12<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(
    Closure f) {
  return new Instantiation12<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(
      f);
}

Instantiation
    instantiate13<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13>(
        Closure f) {
  return new Instantiation13<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13>(f);
}

Instantiation
    instantiate14<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>(
        Closure f) {
  return new Instantiation14<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14>(f);
}

Instantiation instantiate15<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
    T13, T14, T15>(Closure f) {
  return new Instantiation15<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15>(f);
}

Instantiation instantiate16<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
    T13, T14, T15, T16>(Closure f) {
  return new Instantiation16<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16>(f);
}

Instantiation instantiate17<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
    T13, T14, T15, T16, T17>(Closure f) {
  return new Instantiation17<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17>(f);
}

Instantiation instantiate18<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
    T13, T14, T15, T16, T17, T18>(Closure f) {
  return new Instantiation18<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17, T18>(f);
}

Instantiation instantiate19<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
    T13, T14, T15, T16, T17, T18, T19>(Closure f) {
  return new Instantiation19<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17, T18, T19>(f);
}

Instantiation instantiate20<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
    T13, T14, T15, T16, T17, T18, T19, T20>(Closure f) {
  return new Instantiation20<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12,
      T13, T14, T15, T16, T17, T18, T19, T20>(f);
}
