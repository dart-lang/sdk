
class _SVGTransformableImpl extends _SVGLocatableImpl implements SVGTransformable {
  _SVGTransformableImpl._wrap(ptr) : super._wrap(ptr);

  SVGAnimatedTransformList get transform() => _wrap(_ptr.transform);
}
