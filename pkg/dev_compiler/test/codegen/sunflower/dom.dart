// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@js.JS('window')
library dom;

import 'package:js/js.dart' as js;

@js.JS()
class Window {}

class Overload {
  const Overload();
}
const overload = const Overload();

external Document get document;
external Window get window;

@js.JS()
abstract class Document extends Node {
  Element createElement(String name);
  Element querySelector(String selector);

  HTMLElement head;
  HTMLElement body;
}

@js.JS()
class Blob {
  external Blob(blobParts, {String type});
}

class CustomEvent {
  external CustomEvent(String type, {detail, bubbles, cancelable});
}

@js.JS()
abstract class Element extends Node {
  void addEventListener(String type, EventListener callback, [bool capture]);
  String textContent;
}

@js.JS()
abstract class HTMLElement extends Element {
  String innerHTML;
  HTMLCollection get children;
}

@js.JS()
abstract class Node {
  bool hasChildNodes();
  NodeList get childNodes;

  Node insertBefore(Node node, [Node child]);
  Node appendChild(Node node);
  Node replaceChild(Node node, Node child);
  Node removeChild(Node child);
}

abstract class HTMLCollection {
  int get length;
  external Element operator [](num index);
}

@js.JS()
class NodeList {
  external NodeList();
  external num get length;
  external set length(num _);
  external Node item(num index);

  external Node operator [](num index);
  external void operator []=(num index, Node);
}

typedef void EventListener(Event e);

@js.JS()
abstract class Event {}

// TODO(jmesserly): rename these
@js.JS('HTMLInputElement')
abstract class InputElement extends HTMLElement {
  String value;
}

@js.JS('HTMLCanvasElement')
abstract class CanvasElement extends HTMLElement {
  RenderingContext getContext(String contextId);
}

@js.JS('HTMLDivElement')
abstract class DivElement extends HTMLElement {
  RenderingContext getContext(String contextId);
}

@js.JS('HTMLScriptElement')
abstract class ScriptElement extends HTMLElement {
  String type;
}


// TODO(jmesserly): union type of CanvasRenderingContext2D and
// WebGLRenderingContext
abstract class RenderingContext {}

// http://www.w3.org/html/wg/drafts/2dcontext/html5_canvas_CR/
@js.JS()
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

@js.JS()
abstract class CanvasGradient {
  // opaque object
  void addColorStop(num offset, String color);
}

@js.JS()
abstract class CanvasPattern {
  // opaque object
}

@js.JS()
abstract class TextMetrics {
  num get width;
}

@js.JS()
abstract class ImageData {
  int get width;
  int get height;
  // TODO: readonly Uint8ClampedArray data;
}
