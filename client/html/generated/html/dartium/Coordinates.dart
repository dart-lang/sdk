
class _CoordinatesImpl extends _DOMTypeBase implements Coordinates {
  _CoordinatesImpl._wrap(ptr) : super._wrap(ptr);

  num get accuracy() => _wrap(_ptr.accuracy);

  num get altitude() => _wrap(_ptr.altitude);

  num get altitudeAccuracy() => _wrap(_ptr.altitudeAccuracy);

  num get heading() => _wrap(_ptr.heading);

  num get latitude() => _wrap(_ptr.latitude);

  num get longitude() => _wrap(_ptr.longitude);

  num get speed() => _wrap(_ptr.speed);
}
