library dom;

class JsType {
  /// The JavaScript constructor function name.
  /// Used for construction and instanceof checks.
  /// Note that this could be an expression, e.g. `lib.TypeName` in JS, but it
  /// should be kept simple, as it will be generated directly into the code.
  final String name;
  const JsType({this.name});
}
class JsGlobal {
  const JsGlobal();
}
class Overload {
  const Overload();
}
const overload = const Overload();

// TODO(jmesserly): uncomment once fix lands for:
// https://github.com/dart-lang/dart_style/issues/85
// @JsGlobal()
final Document document;

@JsType(name: 'Document')
abstract class Document {
  Element querySelector(String selector);
}

@JsType(name: 'Element')
abstract class Element {
  void addEventListener(String type, EventListener callback, [bool capture]);
  String textContent;
}

typedef void EventListener(Event e);

abstract class Event {}

@JsType(name: 'HTMLInputElement')
abstract class InputElement extends Element {
  String value;
}

@JsType(name: 'HTMLCanvasElement')
abstract class CanvasElement extends Element {
  RenderingContext getContext(String contextId);
}

// TODO(jmesserly): union type of CanvasRenderingContext2D and
// WebGLRenderingContext
abstract class RenderingContext {}

// http://www.w3.org/html/wg/drafts/2dcontext/html5_canvas_CR/
@JsType()
abstract class CanvasRenderingContext2D
    implements CanvasDrawingStyles, CanvasPathMethods, RenderingContext {

  // back-reference to the canvas
  CanvasElement get canvas;

  // state
  void save(); // push state on state stack
  void restore(); // pop state stack and restore state

  // transformations (default transform is the identity matrix)
  void scale(num x, num y);
  void rotate(num angle);
  void translate(num x, num y);
  void transform(num a, num b, num c, num d, num e, num f);
  void setTransform(num a, num b, num c, num d, num e, num f);

  // compositing
  num globalAlpha; // (default 1.0)
  String globalCompositeOperation; // (default source-over)

  // colors and styles (see also the CanvasDrawingStyles interface)
  Object strokeStyle; // (default black)
  Object fillStyle; // (default black)
  CanvasGradient createLinearGradient(num x0, num y0, num x1, num y1);
  CanvasGradient createRadialGradient(
      num x0, num y0, num r0, num x1, num y1, num r1);
  CanvasPattern createPattern(Element image, [String repetition]);

  // shadows
  num shadowOffsetX; // (default 0)
  num shadowOffsetY; // (default 0)
  num shadowBlur; // (default 0)
  String shadowColor; // (default transparent black)

  // rects
  void clearRect(num x, num y, num w, num h);
  void fillRect(num x, num y, num w, num h);
  void strokeRect(num x, num y, num w, num h);

  // path API (see also CanvasPathMethods)
  void beginPath();
  void fill();
  void stroke();
  void drawFocusIfNeeded(Element element);
  void clip();
  bool isPointInPath(num x, num y);

  // text (see also the CanvasDrawingStyles interface)
  void fillText(String text, num x, num y, [num maxWidth]);
  void strokeText(String text, num x, num y, [num maxWidth]);
  TextMetrics measureText(String text);

  // drawing images
  void drawImage(Element image, num dx_or_sx, num dy_or_sy,
      [num dw_or_sw, num dh_or_sh, num dx, num dy, num dw, num dh]);
  @overload void _drawImage_0(Element image, num dx, num dy);
  @overload void _drawImage_1(Element image, num dx, num dy, num dw, num dh);
  @overload void _drawImage_2(Element image, num sx, num sy, num sw, num sh,
      num dx, num dy, num dw, num dh);

  // hit regions
  void addHitRegion({String id: '', Element control});
  void removeHitRegion(String id);
  void clearHitRegions();

  // pixel manipulation
  ImageData createImageData(Object sw_or_imageData, [num sh]);
  @overload ImageData _createImageData_0(num sw, num sh);
  @overload ImageData _createImageData_1(ImageData imagedata);

  ImageData getImageData(num sx, num sy, num sw, num sh);
  void putImageData(ImageData imagedata, num dx, num dy,
      [num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight]);
  @overload void _putImageData_0(ImageData imagedata, num dx, num dy,
      num dirtyX, num dirtyY, num dirtyWidth, num dirtyHeight);
  @overload void _putImageData_1(ImageData imagedata, num dx, num dy);
}

abstract class CanvasDrawingStyles {
  // line caps/joins
  num lineWidth; // (default 1)
  String lineCap; // "butt", "round", "square" (default "butt")
  String lineJoin; // "round", "bevel", "miter" (default "miter")
  num miterLimit; // (default 10)

  // dashed lines
  void setLineDash(List<num> segments); // default empty
  List<num> getLineDash();
  num lineDashOffset;

  // text
  String font; // (default 10px sans-serif)

  // "start", "end", "left", "right", "center" (default: "start")
  String textAlign;

  // "top", "hanging", "middle", "alphabetic",
  // "ideographic", "bottom" (default: "alphabetic")
  String textBaseline;
}

abstract class CanvasPathMethods {
  // shared path API methods
  void closePath();
  void moveTo(num x, num y);
  void lineTo(num x, num y);
  void quadraticCurveTo(num cpx, num cpy, num x, num y);
  void bezierCurveTo(num cp1x, num cp1y, num cp2x, num cp2y, num x, num y);
  void arcTo(num x1, num y1, num x2, num y2, num radius);
  void rect(num x, num y, num w, num h);
  void arc(num x, num y, num radius, num startAngle, num endAngle,
      [bool anticlockwise]);
}

@JsType()
abstract class CanvasGradient {
  // opaque object
  void addColorStop(num offset, String color);
}

@JsType()
abstract class CanvasPattern {
  // opaque object
}

@JsType()
abstract class TextMetrics {
  num get width;
}

@JsType()
abstract class ImageData {
  int get width;
  int get height;
  // TODO: readonly Uint8ClampedArray data;
}
