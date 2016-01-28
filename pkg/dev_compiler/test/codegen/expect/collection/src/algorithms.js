dart_library.library('collection/src/algorithms', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/math'
], /* Lazy imports */[
], function(exports, dart, core, math) {
  'use strict';
  let dartx = dart.dartx;
  function _comparableBinarySearch(list, value) {
    let min = 0;
    let max = list[dartx.length];
    while (min < dart.notNull(max)) {
      let mid = min + (dart.notNull(max) - min >> 1);
      let element = list[dartx.get](mid);
      let comp = element[dartx.compareTo](value);
      if (comp == 0) return mid;
      if (dart.notNull(comp) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }
  dart.fn(_comparableBinarySearch, core.int, [core.List$(core.Comparable), core.Comparable]);
  function binarySearch(sortedList, value, opts) {
    let compare = opts && 'compare' in opts ? opts.compare : null;
    if (compare == null) {
      return _comparableBinarySearch(dart.as(sortedList, core.List$(core.Comparable)), dart.as(value, core.Comparable));
    }
    let min = 0;
    let max = sortedList[dartx.length];
    while (min < dart.notNull(max)) {
      let mid = min + (dart.notNull(max) - min >> 1);
      let element = sortedList[dartx.get](mid);
      let comp = dart.dcall(compare, element, value);
      if (comp == 0) return mid;
      if (dart.notNull(comp) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }
  dart.fn(binarySearch, core.int, [core.List, dart.dynamic], {compare: dart.functionType(core.int, [dart.dynamic, dart.dynamic])});
  function _comparableLowerBound(list, value) {
    let min = 0;
    let max = list[dartx.length];
    while (min < dart.notNull(max)) {
      let mid = min + (dart.notNull(max) - min >> 1);
      let element = list[dartx.get](mid);
      let comp = element[dartx.compareTo](value);
      if (dart.notNull(comp) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  }
  dart.fn(_comparableLowerBound, core.int, [core.List$(core.Comparable), core.Comparable]);
  function lowerBound(sortedList, value, opts) {
    let compare = opts && 'compare' in opts ? opts.compare : null;
    if (compare == null) {
      return _comparableLowerBound(dart.as(sortedList, core.List$(core.Comparable)), dart.as(value, core.Comparable));
    }
    let min = 0;
    let max = sortedList[dartx.length];
    while (min < dart.notNull(max)) {
      let mid = min + (dart.notNull(max) - min >> 1);
      let element = sortedList[dartx.get](mid);
      let comp = dart.dcall(compare, element, value);
      if (dart.notNull(comp) < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return min;
  }
  dart.fn(lowerBound, core.int, [core.List, dart.dynamic], {compare: dart.functionType(core.int, [dart.dynamic, dart.dynamic])});
  function shuffle(list, start, end) {
    if (start === void 0) start = 0;
    if (end === void 0) end = null;
    let random = math.Random.new();
    if (end == null) end = list[dartx.length];
    let length = dart.notNull(end) - dart.notNull(start);
    while (length > 1) {
      let pos = random.nextInt(length);
      length--;
      let tmp1 = list[dartx.get](dart.notNull(start) + dart.notNull(pos));
      list[dartx.set](dart.notNull(start) + dart.notNull(pos), list[dartx.get](dart.notNull(start) + length));
      list[dartx.set](dart.notNull(start) + length, tmp1);
    }
  }
  dart.fn(shuffle, dart.void, [core.List], [core.int, core.int]);
  function reverse(list, start, end) {
    if (start === void 0) start = 0;
    if (end === void 0) end = null;
    if (end == null) end = list[dartx.length];
    _reverse(list, start, end);
  }
  dart.fn(reverse, dart.void, [core.List], [core.int, core.int]);
  function _reverse(list, start, end) {
    for (let i = start, j = dart.notNull(end) - 1; dart.notNull(i) < j; i = dart.notNull(i) + 1, j--) {
      let tmp = list[dartx.get](i);
      list[dartx.set](i, list[dartx.get](j));
      list[dartx.set](j, tmp);
    }
  }
  dart.fn(_reverse, dart.void, [core.List, core.int, core.int]);
  function insertionSort(list, opts) {
    let compare = opts && 'compare' in opts ? opts.compare : null;
    let start = opts && 'start' in opts ? opts.start : 0;
    let end = opts && 'end' in opts ? opts.end : null;
    if (end == null) end = list[dartx.length];
    if (compare == null) compare = core.Comparable.compare;
    _insertionSort(list, compare, start, end, dart.notNull(start) + 1);
  }
  dart.fn(insertionSort, dart.void, [core.List], {compare: dart.functionType(core.int, [dart.dynamic, dart.dynamic]), start: core.int, end: core.int});
  function _insertionSort(list, compare, start, end, sortedUntil) {
    for (let pos = sortedUntil; dart.notNull(pos) < dart.notNull(end); pos = dart.notNull(pos) + 1) {
      let min = start;
      let max = pos;
      let element = list[dartx.get](pos);
      while (dart.notNull(min) < dart.notNull(max)) {
        let mid = dart.notNull(min) + (dart.notNull(max) - dart.notNull(min) >> 1);
        let comparison = dart.dcall(compare, element, list[dartx.get](mid));
        if (dart.notNull(comparison) < 0) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      list[dartx.setRange](dart.notNull(min) + 1, dart.notNull(pos) + 1, list, min);
      list[dartx.set](min, element);
    }
  }
  dart.fn(_insertionSort, dart.void, [core.List, dart.functionType(core.int, [dart.dynamic, dart.dynamic]), core.int, core.int, core.int]);
  const _MERGE_SORT_LIMIT = 32;
  function mergeSort(list, opts) {
    let start = opts && 'start' in opts ? opts.start : 0;
    let end = opts && 'end' in opts ? opts.end : null;
    let compare = opts && 'compare' in opts ? opts.compare : null;
    if (end == null) end = list[dartx.length];
    if (compare == null) compare = core.Comparable.compare;
    let length = dart.notNull(end) - dart.notNull(start);
    if (length < 2) return;
    if (length < dart.notNull(_MERGE_SORT_LIMIT)) {
      _insertionSort(list, compare, start, end, dart.notNull(start) + 1);
      return;
    }
    let middle = dart.notNull(start) + (dart.notNull(end) - dart.notNull(start) >> 1);
    let firstLength = middle - dart.notNull(start);
    let secondLength = dart.notNull(end) - middle;
    let scratchSpace = core.List.new(secondLength);
    _mergeSort(list, compare, middle, end, scratchSpace, 0);
    let firstTarget = dart.notNull(end) - firstLength;
    _mergeSort(list, compare, start, middle, list, firstTarget);
    _merge(compare, list, firstTarget, end, scratchSpace, 0, secondLength, list, start);
  }
  dart.fn(mergeSort, dart.void, [core.List], {start: core.int, end: core.int, compare: dart.functionType(core.int, [dart.dynamic, dart.dynamic])});
  function _movingInsertionSort(list, compare, start, end, target, targetOffset) {
    let length = dart.notNull(end) - dart.notNull(start);
    if (length == 0) return;
    target[dartx.set](targetOffset, list[dartx.get](start));
    for (let i = 1; i < length; i++) {
      let element = list[dartx.get](dart.notNull(start) + i);
      let min = targetOffset;
      let max = dart.notNull(targetOffset) + i;
      while (dart.notNull(min) < max) {
        let mid = dart.notNull(min) + (max - dart.notNull(min) >> 1);
        if (dart.notNull(dart.dcall(compare, element, target[dartx.get](mid))) < 0) {
          max = mid;
        } else {
          min = mid + 1;
        }
      }
      target[dartx.setRange](dart.notNull(min) + 1, dart.notNull(targetOffset) + i + 1, target, min);
      target[dartx.set](min, element);
    }
  }
  dart.fn(_movingInsertionSort, dart.void, [core.List, dart.functionType(core.int, [dart.dynamic, dart.dynamic]), core.int, core.int, core.List, core.int]);
  function _mergeSort(list, compare, start, end, target, targetOffset) {
    let length = dart.notNull(end) - dart.notNull(start);
    if (length < dart.notNull(_MERGE_SORT_LIMIT)) {
      _movingInsertionSort(list, compare, start, end, target, targetOffset);
      return;
    }
    let middle = dart.notNull(start) + (length >> 1);
    let firstLength = middle - dart.notNull(start);
    let secondLength = dart.notNull(end) - middle;
    let targetMiddle = dart.notNull(targetOffset) + firstLength;
    _mergeSort(list, compare, middle, end, target, targetMiddle);
    _mergeSort(list, compare, start, middle, list, middle);
    _merge(compare, list, middle, middle + firstLength, target, targetMiddle, targetMiddle + secondLength, target, targetOffset);
  }
  dart.fn(_mergeSort, dart.void, [core.List, dart.functionType(core.int, [dart.dynamic, dart.dynamic]), core.int, core.int, core.List, core.int]);
  function _merge(compare, firstList, firstStart, firstEnd, secondList, secondStart, secondEnd, target, targetOffset) {
    dart.assert(dart.notNull(firstStart) < dart.notNull(firstEnd));
    dart.assert(dart.notNull(secondStart) < dart.notNull(secondEnd));
    let cursor1 = firstStart;
    let cursor2 = secondStart;
    let firstElement = firstList[dartx.get]((() => {
      let x = cursor1;
      cursor1 = dart.notNull(x) + 1;
      return x;
    })());
    let secondElement = secondList[dartx.get]((() => {
      let x = cursor2;
      cursor2 = dart.notNull(x) + 1;
      return x;
    })());
    while (true) {
      if (dart.notNull(dart.dcall(compare, firstElement, secondElement)) <= 0) {
        target[dartx.set]((() => {
          let x = targetOffset;
          targetOffset = dart.notNull(x) + 1;
          return x;
        })(), firstElement);
        if (cursor1 == firstEnd) break;
        firstElement = firstList[dartx.get]((() => {
          let x = cursor1;
          cursor1 = dart.notNull(x) + 1;
          return x;
        })());
      } else {
        target[dartx.set]((() => {
          let x = targetOffset;
          targetOffset = dart.notNull(x) + 1;
          return x;
        })(), secondElement);
        if (cursor2 != secondEnd) {
          secondElement = secondList[dartx.get]((() => {
            let x = cursor2;
            cursor2 = dart.notNull(x) + 1;
            return x;
          })());
          continue;
        }
        target[dartx.set]((() => {
          let x = targetOffset;
          targetOffset = dart.notNull(x) + 1;
          return x;
        })(), firstElement);
        target[dartx.setRange](targetOffset, dart.notNull(targetOffset) + (dart.notNull(firstEnd) - dart.notNull(cursor1)), firstList, cursor1);
        return;
      }
    }
    target[dartx.set]((() => {
      let x = targetOffset;
      targetOffset = dart.notNull(x) + 1;
      return x;
    })(), secondElement);
    target[dartx.setRange](targetOffset, dart.notNull(targetOffset) + (dart.notNull(secondEnd) - dart.notNull(cursor2)), secondList, cursor2);
  }
  dart.fn(_merge, dart.void, [dart.functionType(core.int, [dart.dynamic, dart.dynamic]), core.List, core.int, core.int, core.List, core.int, core.int, core.List, core.int]);
  // Exports:
  exports.binarySearch = binarySearch;
  exports.lowerBound = lowerBound;
  exports.shuffle = shuffle;
  exports.reverse = reverse;
  exports.insertionSort = insertionSort;
  exports.mergeSort = mergeSort;
});
