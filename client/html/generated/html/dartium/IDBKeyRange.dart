
class _IDBKeyRangeImpl extends _DOMTypeBase implements IDBKeyRange {
  _IDBKeyRangeImpl._wrap(ptr) : super._wrap(ptr);

  IDBKey get lower() => _wrap(_ptr.lower);

  bool get lowerOpen() => _wrap(_ptr.lowerOpen);

  IDBKey get upper() => _wrap(_ptr.upper);

  bool get upperOpen() => _wrap(_ptr.upperOpen);

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) {
    if (lowerOpen === null) {
      if (upperOpen === null) {
        return _wrap(_ptr.bound(_unwrap(lower), _unwrap(upper)));
      }
    } else {
      if (upperOpen === null) {
        return _wrap(_ptr.bound(_unwrap(lower), _unwrap(upper), _unwrap(lowerOpen)));
      } else {
        return _wrap(_ptr.bound(_unwrap(lower), _unwrap(upper), _unwrap(lowerOpen), _unwrap(upperOpen)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return _wrap(_ptr.lowerBound(_unwrap(bound)));
    } else {
      return _wrap(_ptr.lowerBound(_unwrap(bound), _unwrap(open)));
    }
  }

  IDBKeyRange only(IDBKey value) {
    return _wrap(_ptr.only(_unwrap(value)));
  }

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) {
    if (open === null) {
      return _wrap(_ptr.upperBound(_unwrap(bound)));
    } else {
      return _wrap(_ptr.upperBound(_unwrap(bound), _unwrap(open)));
    }
  }
}
