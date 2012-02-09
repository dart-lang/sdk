
class _HTMLCanvasElementJs extends _HTMLElementJs implements HTMLCanvasElement native "*HTMLCanvasElement" {

  int height;

  int width;

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}
