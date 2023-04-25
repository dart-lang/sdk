// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:collection";

abstract class MyList<T> implements List<T> {}

sealed class SealedList<T> implements List<T> {}

class ListA<T> extends SealedList<T> {}

class ListB<T> extends SealedList<T> {}

enum EnumList<T> implements List<T> {
  a,
  b,
}

exhaustiveList(
        List<int>
            l) => /*
 checkingOrder={List<int>,<int>[],<int>[()],<int>[(), (), ...]},
 subtypes={<int>[],<int>[()],<int>[(), (), ...]},
 type=List<int>
*/
    switch (l) {
      // Ok. No error, exhaustive
      [] /*space=<[]>*/ => "0",
      [_] /*space=<[int]>*/ => "1",
      [_, _] /*space=<[int, int]>*/ => "2",
      [_, _, ...] /*space=<[int, int, ...List<int>]>*/ => "2+"
    };

exhaustiveCustomListAsList(
        MyList<int>
            ml) => /*
 checkingOrder={MyList<int>,<int>[],<int>[()],<int>[(), (), ...]},
 subtypes={<int>[],<int>[()],<int>[(), (), ...]},
 type=MyList<int>
*/
    switch (ml) {
      [] /*space=<[]>*/ => "0",
      [_] /*space=<[int]>*/ => "1",
      [_, _] /*space=<[int, int]>*/ => "2",
      [_, _, ...] /*space=<[int, int, ...List<int>]>*/ => "2+"
    };

exhaustiveCustomListByType(
        MyList<int>
            ml) => /*
 checkingOrder={MyList<int>,<int>[...]},
 subtypes={<int>[...]},
 type=MyList<int>
*/
    switch (ml) {
      MyList() /*space=MyList<int>*/ => 0,
    };

exhaustiveCustomListMixed(
        MyList<int>
            ml) => /*
 checkingOrder={MyList<int>,<int>[...]},
 subtypes={<int>[...]},
 type=MyList<int>
*/
    switch (ml) {
      [] /*space=<[]>*/ => 0,
      MyList() /*space=MyList<int>*/ => 1,
    };

exhaustiveCustomListWithRest(
        MyList<int>
            ml) => /*
 checkingOrder={MyList<int>,<int>[...]},
 subtypes={<int>[...]},
 type=MyList<int>
*/
    switch (ml) {
      [...List()] /*space=<[...List<int>]>*/ => 0,
    };

nonExhaustiveCustomListWithRest(
        MyList<int>
            ml) => /*
 checkingOrder={MyList<int>,<int>[...]},
 error=non-exhaustive:[...[...]]/[...],
 subtypes={<int>[...]},
 type=MyList<int>
*/
    switch (ml) {
      [...MyList()] /*space=<[...MyList<int>]>*/ => 0,
    };

exhaustiveSealedListAsList(
        SealedList<int>
            sl) => /*
             checkingOrder={SealedList<int>,ListA<int>,ListB<int>,<int>[],<int>[()],<int>[(), (), ...],<int>[],<int>[()],<int>[(), (), ...]},
             error=non-exhaustive:[Object()],
             expandedSubtypes={<int>[],<int>[()],<int>[(), (), ...],<int>[],<int>[()],<int>[(), (), ...]},
             subtypes={ListA<int>,ListB<int>},
             type=SealedList<int>
            */
    switch (sl) {
      [] /*space=<[]>*/ => "0",
      [_] /*space=<[int]>*/ => "1",
      [_, _] /*space=<[int, int]>*/ => "2",
      [_, _, ...] /*space=<[int, int, ...List<int>]>*/ => "2+"
    };

nonExhaustiveSealedListAsList(
        SealedList<int>
            sl) => /*
             checkingOrder={SealedList<int>,ListA<int>,ListB<int>,<int>[],<int>[()],<int>[(), (), ...],<int>[],<int>[()],<int>[(), (), ...]},
             error=non-exhaustive:[_],
             expandedSubtypes={<int>[],<int>[()],<int>[(), (), ...],<int>[],<int>[()],<int>[(), (), ...]},
             subtypes={ListA<int>,ListB<int>},
             type=SealedList<int>
            */
    switch (sl) {
      [] /*space=<[]>*/ => "0",
      [_, _] /*space=<[int, int]>*/ => "2",
      [_, _, ...] /*space=<[int, int, ...List<int>]>*/ => "2+"
    };

exhaustiveSealedListByType(
        SealedList<int>
            sl) => /*
 checkingOrder={SealedList<int>,ListA<int>,ListB<int>,<int>[...],<int>[...]},
 expandedSubtypes={<int>[...],<int>[...]},
 subtypes={ListA<int>,ListB<int>},
 type=SealedList<int>
*/
    switch (sl) {
      SealedList() /*space=SealedList<int>*/ => 0,
    };

exhaustiveSealedListBySubtype(
        SealedList<int>
            sl) => /*
 checkingOrder={SealedList<int>,ListA<int>,ListB<int>,<int>[...],<int>[...]},
 expandedSubtypes={<int>[...],<int>[...]},
 subtypes={ListA<int>,ListB<int>},
 type=SealedList<int>
*/
    switch (sl) {
      ListA() /*space=ListA<int>*/ => 0,
      ListB() /*space=ListB<int>*/ => 1,
    };

nonExhaustiveSealedListBySubtype(
        SealedList<int>
            sl) => /*
             checkingOrder={SealedList<int>,ListA<int>,ListB<int>,<int>[...],<int>[...]},
             error=non-exhaustive:[...],
             expandedSubtypes={<int>[...],<int>[...]},
             subtypes={ListA<int>,ListB<int>},
             type=SealedList<int>
            */
    switch (sl) {
      ListB() /*space=ListB<int>*/ => 1,
    };

exhaustiveSealedListMixed(
        SealedList<int>
            sl) => /*
             checkingOrder={SealedList<int>,ListA<int>,ListB<int>,<int>[],<int>[()],<int>[(), (), ...],<int>[],<int>[()],<int>[(), (), ...]},
             expandedSubtypes={<int>[],<int>[()],<int>[(), (), ...],<int>[],<int>[()],<int>[(), (), ...]},
             subtypes={ListA<int>,ListB<int>},
             type=SealedList<int>
            */
    switch (sl) {
      [_, _] /*space=<[int, int]>*/ => 0,
      ListA() /*space=ListA<int>*/ => 1,
      ListB() /*space=ListB<int>*/ => 2,
    };

exhaustiveEnumListAsList(
        EnumList<int>
            el) => /*
             checkingOrder={EnumList<int>},
             type=EnumList<int>
            */
    switch (el) {
      [] /*space=<[]>*/ => "0",
      [_] /*space=<[int]>*/ => "1",
      [_, _] /*space=<[int, int]>*/ => "2",
      [_, _, ...] /*space=<[int, int, ...List<int>]>*/ => "2+"
    };

nonExhaustiveEnumListAsList(
        EnumList<int>
            el) => /*
             checkingOrder={EnumList<int>},
             type=EnumList<int>
            */
    switch (el) {
      [] /*space=<[]>*/ => "0",
      [_, _] /*space=<[int, int]>*/ => "2",
      [_, _, ...] /*space=<[int, int, ...List<int>]>*/ => "2+"
    };

exhaustiveEnumListByType(
        EnumList<int>
            el) => /*
             checkingOrder={EnumList<int>},
             type=EnumList<int>
            */
    switch (el) {
      EnumList() /*space=EnumList<int>*/ => 0,
    };

exhaustiveEnumListBySubtype(
        EnumList<int>
            el) => /*
             checkingOrder={EnumList<int>},
             type=EnumList<int>
            */
    switch (el) {
      EnumList.a /*space=EnumList.a*/ => 0,
      EnumList.b /*space=EnumList.b*/ => 1,
    };

exhaustiveEnumListMixed(
        EnumList<int>
            el) => /*
             checkingOrder={EnumList<int>},
             type=EnumList<int>
            */
    switch (el) {
      [_, _] /*space=<[int, int]>*/ => 0,
      EnumList.a /*space=EnumList.a*/ => 1,
      EnumList.b /*space=EnumList.b*/ => 2,
    };
