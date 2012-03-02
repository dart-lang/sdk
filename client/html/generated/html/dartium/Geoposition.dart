
class _GeopositionImpl extends _DOMTypeBase implements Geoposition {
  _GeopositionImpl._wrap(ptr) : super._wrap(ptr);

  Coordinates get coords() => _wrap(_ptr.coords);

  int get timestamp() => _wrap(_ptr.timestamp);
}
