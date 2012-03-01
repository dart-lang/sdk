
class _CanvasElementImpl extends _ElementImpl implements CanvasElement native "*HTMLCanvasElement" {

  int height;

  int width;

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}
