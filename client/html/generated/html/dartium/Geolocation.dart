
class _GeolocationImpl extends _DOMTypeBase implements Geolocation {
  _GeolocationImpl._wrap(ptr) : super._wrap(ptr);

  void clearWatch(int watchId) {
    _ptr.clearWatch(_unwrap(watchId));
    return;
  }

  void getCurrentPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      _ptr.getCurrentPosition(_unwrap(successCallback));
      return;
    } else {
      _ptr.getCurrentPosition(_unwrap(successCallback), _unwrap(errorCallback));
      return;
    }
  }

  int watchPosition(PositionCallback successCallback, [PositionErrorCallback errorCallback = null]) {
    if (errorCallback === null) {
      return _wrap(_ptr.watchPosition(_unwrap(successCallback)));
    } else {
      return _wrap(_ptr.watchPosition(_unwrap(successCallback), _unwrap(errorCallback)));
    }
  }
}
