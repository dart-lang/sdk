// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

bool equals(e1, e2, bool unordered) {
  if (/*{}*/ e1 is Set) {
    return /*{e1:[{true:Set<dynamic>}|Set<dynamic>]}*/
        e2 is Set &&
            /*{
             e1:[{true:Set<dynamic>}|Set<dynamic>],
             e2:[{true:Set<dynamic>}|Set<dynamic>]}
            */
            e1 == null;
  }
  if (/*{e1:[{false:Set<dynamic>}|Set<dynamic>]}*/ e1 is Map) {
    return
        /*{e1:[{true:Map<dynamic,dynamic>,false:Set<dynamic>}|Set<dynamic>,Map<dynamic,dynamic>]}*/
        e2 is Map &&
            /*{
             e1:[{true:Map<dynamic,dynamic>,false:Set<dynamic>}|Set<dynamic>,Map<dynamic,dynamic>],
             e2:[{true:Map<dynamic,dynamic>}|Map<dynamic,dynamic>]}
            */
            e1 == null;
  }
  if (! /*{e1:[{false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>]}*/
      unordered) {
    if (/*{e1:[{false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>]}*/
        e1 is List) {
      return
          /*{e1:[{true:List<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>]}*/
          e2 is List &&
              /*{
               e1:[{true:List<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>],
               e2:[{true:List<dynamic>}|List<dynamic>]}
              */
              e1 == null;
    }
    if (/*{e1:[{false:Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>]}*/
        e1 is Iterable) {
      return
          /*{e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>,Iterable<dynamic>]}*/
          e2 is Iterable &&
              /*{
               e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,List<dynamic>,Iterable<dynamic>],
               e2:[{true:Iterable<dynamic>}|Iterable<dynamic>]}
              */
              e1 == null;
    }
  } else if (/*{e1:[{false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>]}*/
      e1 is Iterable) {
    if (
        /*{e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,Iterable<dynamic>]}*/
        e1 is List !=
            /*{e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,Iterable<dynamic>]}*/
            e2 is List) {
      return
          /*{e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Iterable<dynamic>,Set<dynamic>,Map<dynamic,dynamic>]}*/
          e1 == null;
    }
    return /*{e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Iterable<dynamic>,Set<dynamic>,Map<dynamic,dynamic>]}*/
        e2 is Iterable &&

            /*{
             e1:[{true:Iterable<dynamic>,false:Set<dynamic>,Map<dynamic,dynamic>}|Iterable<dynamic>,Set<dynamic>,Map<dynamic,dynamic>],
             e2:[{true:Iterable<dynamic>}|Iterable<dynamic>]}
            */
            e1 == null;
  }
  return
      /*{e1:[{false:Set<dynamic>,Map<dynamic,dynamic>,Iterable<dynamic>}|Set<dynamic>,Map<dynamic,dynamic>,Iterable<dynamic>]}*/
      e1 == null;
}

main() {
  equals(null, null, true);
}
