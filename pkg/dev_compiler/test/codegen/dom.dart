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
  CanvasRenderingContext2D get context2D;
}

// http://www.w3.org/html/wg/drafts/2dcontext/html5_canvas_CR/
@JsType()
abstract class CanvasRenderingContext2D
    implements CanvasDrawingStyles, CanvasPathMethods {

  // back-reference to the canvas
  CanvasElement get canvas;

  // state
  void save(); // push state on state stack
  void restore(); // pop state stack and restore state

  // transformations (default transform is the identity matrix)
  void scale(double x, double y);
  void rotate(double angle);
  void translate(double x, double y);
  void transform(double a, double b, double c, double d, double e, double f);
  void setTransform(double a, double b, double c, double d, double e, double f);

  // compositing
  double globalAlpha; // (default 1.0)
  String globalCompositeOperation; // (default source-over)

  // colors and styles (see also the CanvasDrawingStyles interface)
  Object strokeStyle; // (default black)
  Object fillStyle; // (default black)
  CanvasGradient createLinearGradient(
      double x0, double y0, double x1, double y1);
  CanvasGradient createRadialGradient(
      double x0, double y0, double r0, double x1, double y1, double r1);
  CanvasPattern createPattern(Element image, [String repetition]);

  // shadows
  double shadowOffsetX; // (default 0)
  double shadowOffsetY; // (default 0)
  double shadowBlur; // (default 0)
  String shadowColor; // (default transparent black)

  // rects
  void clearRect(double x, double y, double w, double h);
  void fillRect(double x, double y, double w, double h);
  void strokeRect(double x, double y, double w, double h);

  // path API (see also CanvasPathMethods)
  void beginPath();
  void fill();
  void stroke();
  void drawFocusIfNeeded(Element element);
  void clip();
  bool isPointInPath(double x, double y);

  // text (see also the CanvasDrawingStyles interface)
  void fillText(String text, double x, double y, [double maxWidth]);
  void strokeText(String text, double x, double y, [double maxWidth]);
  TextMetrics measureText(String text);

  // drawing images
  void drawImage(
      Element image, double dx_or_sx, double dy_or_sy, [double dw_or_sw,
      double dh_or_sh, double dx, double dy, double dw, double dh]);
  @overload void _drawImage_0(Element image, double dx, double dy);
  @overload void _drawImage_1(
      Element image, double dx, double dy, double dw, double dh);
  @overload void _drawImage_2(Element image, double sx, double sy, double sw,
      double sh, double dx, double dy, double dw, double dh);

  // hit regions
  void addHitRegion({String id: '', Element control});
  void removeHitRegion(String id);
  void clearHitRegions();

  // pixel manipulation
  ImageData createImageData(Object sw_or_imageData, [double sh]);
  @overload ImageData _createImageData_0(double sw, double sh);
  @overload ImageData _createImageData_1(ImageData imagedata);

  ImageData getImageData(double sx, double sy, double sw, double sh);
  void putImageData(ImageData imagedata, double dx, double dy, [double dirtyX,
      double dirtyY, double dirtyWidth, double dirtyHeight]);
  @overload void _putImageData_0(ImageData imagedata, double dx, double dy,
      double dirtyX, double dirtyY, double dirtyWidth, double dirtyHeight);
  @overload void _putImageData_1(ImageData imagedata, double dx, double dy);
}

abstract class CanvasDrawingStyles {
  // line caps/joins
  double lineWidth; // (default 1)
  String lineCap; // "butt", "round", "square" (default "butt")
  String lineJoin; // "round", "bevel", "miter" (default "miter")
  double miterLimit; // (default 10)

  // dashed lines
  void setLineDash(List<double> segments); // default empty
  List<double> getLineDash();
  double lineDashOffset;

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
  void moveTo(double x, double y);
  void lineTo(double x, double y);
  void quadraticCurveTo(double cpx, double cpy, double x, double y);
  void bezierCurveTo(
      double cp1x, double cp1y, double cp2x, double cp2y, double x, double y);
  void arcTo(double x1, double y1, double x2, double y2, double radius);
  void rect(double x, double y, double w, double h);
  void arc(double x, double y, double radius, double startAngle,
      double endAngle, [bool anticlockwise]);
}

@JsType()
abstract class CanvasGradient {
  // opaque object
  void addColorStop(double offset, String color);
}

@JsType()
abstract class CanvasPattern {
  // opaque object
}

@JsType()
abstract class TextMetrics {
  double get width;
}

@JsType()
abstract class ImageData {
  int get width;
  int get height;
  // TODO: readonly Uint8ClampedArray data;
}
