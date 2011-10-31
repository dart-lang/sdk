
class HTMLCanvasElement extends HTMLElement native "HTMLCanvasElement" {

  int height;

  int width;

  Object getContext(String contextId) native;

  String toDataURL(String type) native;
}
