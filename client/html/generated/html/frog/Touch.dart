
class _TouchImpl implements Touch native "*Touch" {

  final int clientX;

  final int clientY;

  final int identifier;

  final int pageX;

  final int pageY;

  final int screenX;

  final int screenY;

  _EventTargetImpl get target() => _FixHtmlDocumentReference(_target);

  _EventTargetImpl get _target() native "return this.target;";

  final num webkitForce;

  final int webkitRadiusX;

  final int webkitRadiusY;

  final num webkitRotationAngle;
}
