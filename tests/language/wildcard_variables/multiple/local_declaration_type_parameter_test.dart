// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests multiple wildcard generic type parameters.

// SharedOptions=--enable-experiment=wildcard-variables

// Class type parameters
class T<_, _> {}

typedef ForgetfulMap<_, _> = Map<Object?, Object?>;
typedef F<_, X, _> = X Function<_ extends X>(X _, X _);

// Function type parameters
void genericFunction<_, _>() {}
void genericFunction2<_ extends Iterable<int>, _ extends num>() {}
void genericFunction3<_ extends void Function<_>(_, _), _>() {}

void main() {
  void genericCallback(bool Function<T, E>() func) {}
  genericCallback(<_, _>() => true);
}
