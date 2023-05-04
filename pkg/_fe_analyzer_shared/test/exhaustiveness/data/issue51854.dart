// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  print(sum([1, 2, 3, 4, 5]));
}

int sum(
        Iterable<int>
            list) => /*
 fields={first:int,isEmpty:bool,Iterable<int>.rest:Iterable<int>},
 type=Iterable<int>
*/
    switch (list) {
      Iterable(isEmpty: true) /*space=Iterable<int>(isEmpty: true)*/ => 0,
      Iterable(
        first: var x,
        rest: var xs
      ) /*space=Iterable<int>(first: int, Iterable<int>.rest: Iterable<int> (Iterable<int>))*/ =>
        x + sum(xs),
    };

int sum1(
        Iterable<int>
            list) => /*
 fields={first:int,isEmpty:bool,Iterable<int>.rest:Iterable<int>},
 type=Iterable<int>
*/
    switch (list) {
      Iterable(isEmpty: true) /*space=Iterable<int>(isEmpty: true)*/ => 0,
      Iterable(
        first: var x,
        rest: Iterable<int> xs
      ) /*space=Iterable<int>(first: int, Iterable<int>.rest: Iterable<int> (Iterable<int>))*/ =>
        x + sum(xs),
    };

int sum2(
        Iterable<int>
            list) => /*
             error=non-exhaustive:Iterable<int>(first: int(), isEmpty: false, rest: Iterable<int>())/Iterable<int>(isEmpty: false),
             fields={first:int,isEmpty:bool,Iterable<int>.rest:Iterable<int>},
             type=Iterable<int>
            */
    switch (list) {
      Iterable(isEmpty: true) /*space=Iterable<int>(isEmpty: true)*/ => 0,
      Iterable(
        first: var x,
        rest: List<int> xs
      ) /*space=Iterable<int>(first: int, Iterable<int>.rest: List<int> (Iterable<int>))*/ =>
        x + sum(xs),
    };

extension<A> on Iterable<A> {
  Iterable<A> get rest => skip(1);
}
