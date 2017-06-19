// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library flatten_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import "package:compiler/src/elements/elements.dart" show ClassElement;

void main() {
  asyncTest(() => TypeEnvironment.create(r"""
      abstract class F<T> implements Future<T> {}
      abstract class G<T> implements Future<G<T>> {}
      abstract class H<T> implements Future<H<H<T>>> {}
      """).then((env) {
        void check(
            ResolutionDartType T, ResolutionDartType expectedFlattenedType) {
          ResolutionDartType flattenedType = env.flatten(T);
          Expect.equals(
              expectedFlattenedType,
              flattenedType,
              "Unexpected flattening of '$T' = '$flattenedType',"
              "expected '$expectedFlattenedType'.");
        }

        ClassElement Future_ = env.getElement('Future');
        ClassElement F = env.getElement('F');
        ClassElement G = env.getElement('G');
        ClassElement H = env.getElement('H');
        ResolutionDartType int_ = env['int'];
        ResolutionDartType dynamic_ = env['dynamic'];
        ResolutionDartType Future_int = instantiate(Future_, [int_]);
        ResolutionDartType F_int = instantiate(F, [int_]);
        ResolutionDartType G_int = instantiate(G, [int_]);
        ResolutionDartType H_int = instantiate(H, [int_]);
        ResolutionDartType H_H_int = instantiate(H, [H_int]);

        // flatten(int) = int
        check(int_, int_);

        // flatten(Future) = dynamic
        check(Future_.rawType, dynamic_);

        // flatten(Future<int>) = int
        check(Future_int, int_);

        // flatten(Future<Future<int>>) = int
        check(instantiate(Future_, [Future_int]), int_);

        // flatten(F) = dynamic
        check(F.rawType, dynamic_);

        // flatten(F<int>) = int
        check(F_int, int_);

        // flatten(F<Future<int>>) = Future<int>
        check(instantiate(F, [Future_int]), Future_int);

        // flatten(G) = G
        check(G.rawType, G.rawType);

        // flatten(G<int>) = G<int>
        check(G_int, G_int);

        // flatten(H) = H<H>
        check(H.rawType, instantiate(H, [H.rawType]));

        // flatten(H<int>) = H<H<int>>
        check(H_int, H_H_int);

        // flatten(Future<F<int>>) = int
        check(instantiate(Future_, [F_int]), int_);

        // flatten(Future<G<int>>) = int
        check(instantiate(Future_, [G_int]), G_int);

        // flatten(Future<H<int>>) = int
        check(instantiate(Future_, [H_int]), H_H_int);
      }));
}
