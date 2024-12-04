// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that pattern type schemas produced by the implementation correspond
// to the specification in
// https://github.com/dart-lang/language/blob/main/accepted/3.0/patterns/feature-specification.md#pattern-context-type-schema.

import 'package:expect/static_type_helper.dart';

test() {
  // The context type schema for a pattern `p` is:

  // - Logical-and: The greatest lower bound of the context type schemas of the
  //   branches.
  {
    var (void Function(int) x && void Function(double) y) =
        contextType((n) => n.expectStaticType<Exactly<num>>())
          ..expectStaticType<Exactly<void Function(num)>>();
  }

  // - Null-assert: A context type schema `E?` where `E` is the context type
  //   schema of the inner pattern.
  {
    var ((int i)!) = contextType(1)..expectStaticType<Exactly<int?>>();
  }

  // - Variable:
  //
  //   i. If `p` has a type annotation, the context type schema is the annotated
  //      type.
  {
    var (int i) = contextType(1)..expectStaticType<Exactly<int>>();
  }

  //   ii. Else the context type schema is _.
  //
  //   This rule is actually never used, because:
  //   - Pattern type schemas are only computed for pattern variable
  //     declarations and pattern assignments.
  //   - It is a compile-time error if a variable pattern appears in an
  //     assignment context. So the context type schema for a variable pattern
  //     only matters if it appears in a declaration context.
  //   - It is a compile-time error if a variable pattern in a declaration
  //     context is marked with `var` or `final`. So a variable pattern inside a
  //     pattern variable declaration must have a type annotation.

  // - Identifier:
  //
  //   i. In an assignment context, the context type schema is the static type
  //      of the variable that `p` resolves to.
  {
    int i;
    (i) = contextType(1)..expectStaticType<Exactly<int>>();
  }

  //   ii. Else the context type schema is `_`.
  {
    var [x] = [1]..expectStaticType<Exactly<List<int>>>();
    var [_] = [1]..expectStaticType<Exactly<List<int>>>();
  }

  // - Cast: The context type schema is `_`.
  {
    var [_ as Object] = [1]..expectStaticType<Exactly<List<int>>>();
  }

  // - Parenthesized: The context type schema of the inner subpattern.
  {
    var (<int>[]) = contextType(<int>[])
      ..expectStaticType<Exactly<List<int>>>();
  }

  // - List: A context type schema `List<E>` where:
  //
  //   i. If `p` has a type argument, then `E` is the type argument.
  {
    var <int>[] = contextType(<int>[])..expectStaticType<Exactly<List<int>>>();
  }

  //   ii. Else if `p` has no elements then `E` is `_`.
  {
    var [] = [1]
      ..expectStaticType<Exactly<List<int>>>()
      ..removeLast();
  }

  //   iii. Else, infer the type schema from the elements:
  //
  //        a. Let `es` be an empty list of type schemas.
  //
  //        b. For each element `e` in `p`:
  //
  //           a. If `e` is a matching rest element with subpattern `s` and the
  //              context type schema of `s` is an `Iterable<T>` for some type
  //              schema `T`, then add `T` to es.
  {
    var [
      ...Iterable<int> x
    ] = contextType(<int>[])..expectStaticType<Exactly<List<int>>>();
    var [
      ...List<int> y
    ] = contextType(<int>[])..expectStaticType<Exactly<List<int>>>();
  }

  //           b. Else if `e` is not a rest element, add the context type schema
  //              of `e` to `es`.
  {
    var [int x] = contextType(<int>[0])..expectStaticType<Exactly<List<int>>>();
  }

  //        c. If `es` is empty, then `E` is `_`.
  {
    var [...] = [1]..expectStaticType<Exactly<List<int>>>();
    var [...Object x] = [1]..expectStaticType<Exactly<List<int>>>();
  }

  //        d. Else `E` is the greatest lower bound of the type schemas in `es`.
  {
    var [void Function(int) x, void Function(double) y] = contextType([
      (n) => n.expectStaticType<Exactly<num>>(),
      (n) => n.expectStaticType<Exactly<num>>()
    ])
      ..expectStaticType<Exactly<List<void Function(num)>>>();
  }

  // - Map: A type schema `Map<K, V>` where:
  //
  //   i. If `p` has type arguments then `K`, and `V` are those type arguments.
  {
    var <int, String>{0: _} = contextType(<int, String>{0: 'x'})
      ..expectStaticType<Exactly<Map<int, String>>>();
  }

  //   ii. Else `K` is `_` and `V` is the greatest lower bound of the context
  //       type schemas of all value subpatterns.
  {
    var {1: void Function(int) x, 2: void Function(double) y} = {
      (1 as num): (n) => n.expectStaticType<Exactly<num>>(),
      (2 as num): (n) => n.expectStaticType<Exactly<num>>()
    }..expectStaticType<Exactly<Map<num, void Function(num)>>>();
  }

  // Record: A record type schema with positional and named fields corresponding
  // to the type schemas of the corresponding field subpatterns.
  {
    var (int _, y: String _) = contextType((1, y: 'y'))
      ..expectStaticType<Exactly<(int, {String y})>>();
  }

  // Object: The type the object name resolves to.
  {
    var List<int>() = contextType(<int>[])
      ..expectStaticType<Exactly<List<int>>>();
  }

  // If the type the object name resolves to is generic, and no type arguments
  // are specified, then instantiate to bounds is used to fill in provisional
  // type arguments for the purpose of determining the context type schema.
  {
    var List(
      first: x
    ) = contextType([1])..expectStaticType<Exactly<List<dynamic>>>();
    var List(first: y) = <int>[1];
    y.expectStaticType<Exactly<int>>();
  }
}

main() {
  test();
}
