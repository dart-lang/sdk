// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class Box<E> {
  E get item;
  const Box();
}

class FilledBox<E> extends Box<E> {
  @override
  final E item;

  const FilledBox(this.item);
}

class NeverBox extends Box<Never> {
  @override
  Never get item => throw Error();

  const NeverBox();
}

Box<O> switchFunction<O>(
        O? object) => /*
 checkingOrder={Object?,Object,Null},
 subtypes={Object,Null},
 type=Object?
*/
    switch (object) {
      O object /*space=Object?*/ => FilledBox(object),
      null /*space=Null*/ => NeverBox(),
    };
