// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.vmstats;

class BarGraph {
  CanvasElement _canvas;
  GraphModel _model;
  List<Element> _elements;
  double scaleHeight = 0;

  static const int SAMPLE_WIDTH = 5;
  static const int LEFT_MARGIN = 50;
  static const int RIGHT_MARGIN = 150;
  static const int LEGEND_WIDTH = 130;
  static const int LEGEND_Y = 20;
  static const int INSIDE_MARGIN = 2;
  static const int LINE_WIDTH = 2;

  static const int NUM_DIVIDERS = 5;
  static const String FONT = "14px sans-serif";

  BarGraph(this._canvas, this._elements) {
    var maxElements =
        (_canvas.width - LEFT_MARGIN - RIGHT_MARGIN) ~/ SAMPLE_WIDTH;
    _model = new GraphModel(maxElements);
    _model.addListener(drawGraph, null);
    drawBarGraph();
 }

  void addSample(List<int> segments) {
    if (segments.length != _elements.length) {
      throw new RuntimeError('invalid sample size for graph');
    }
    _model.addSample(segments);
  }

  void drawBarGraph() {
    // Draw chart's outer box.
    var context = _canvas.context2D;
    context.beginPath();
    context.strokeStyle = 'black';
    // The '2's are the width of the line, even though 1 is specified.
    context.strokeRect(
        LEFT_MARGIN - 2, 1, _canvas.width - LEFT_MARGIN - RIGHT_MARGIN + 2,
        _canvas.height - 2, 1);

    // Draw legend.
    var x = _canvas.width - LEGEND_WIDTH;
    var y = LEGEND_Y;
    context.font = FONT;
    for (var i = _elements.length - 1; i >= 0; i--) {
      context.fillStyle = _elements[i].color;
      context.fillRect(x, y, 20, 20);
      context.fillStyle = 'black';
      context.fillText(_elements[i].name, x + 30, y + 15);
      y += 30;
    }
  }

  void drawGraph(GraphModel model) {
    var graphHeight = model.maxTotal;
    var width = _canvas.clientWidth;
    var height = _canvas.clientHeight;
    if (graphHeight >= scaleHeight) {
      // Make scale height a bit higher to allow for growth, and
      // round to nearest 100.
      scaleHeight = graphHeight * 1.2;
      scaleHeight = ((scaleHeight / 100).ceil() * 100);
    }
    var scale = height / scaleHeight;
    drawValues(scaleHeight, scale);
    drawChart(scaleHeight, scale);
  }

  void drawChart(int maxHeight, double scale) {
    var dividerHeight = maxHeight ~/ NUM_DIVIDERS;
    var context = _canvas.context2D;
    context.beginPath();
    var height = maxHeight.toInt();
    var scaledY = dividerHeight * scale;

    // Draw the vertical axis values and lines.
    context.clearRect(0, 0, LEFT_MARGIN - INSIDE_MARGIN, maxHeight);
    for (var i = 1; i < NUM_DIVIDERS; i++) {
      height -= (dividerHeight ~/ 100) * 100;
      context.font = FONT;
      context.fillStyle = 'black';
      context.textAlign = 'right';
      context.textBaseline = 'middle';
      context.fillText(height.toString(), LEFT_MARGIN - 10, scaledY);
      context.moveTo(LEFT_MARGIN - INSIDE_MARGIN, scaledY);
      context.strokeStyle = 'grey';
      context.lineWidth = 0.5;
      context.lineTo(_canvas.width - RIGHT_MARGIN, scaledY);
      context.stroke();
      scaledY += dividerHeight * scale;
    }
  }

  void drawValues(int maxHeight, num scale) {
    Iterator<Sample> iterator = _model.iterator;
    var x = LEFT_MARGIN + INSIDE_MARGIN;
    var y = INSIDE_MARGIN;
    var w = _canvas.width - LEFT_MARGIN - RIGHT_MARGIN - INSIDE_MARGIN;
    var h = (maxHeight * scale).ceil() - (2 * INSIDE_MARGIN);
    _canvas.context2D.clearRect(x, y, w, h);

    while (iterator.moveNext()) {
      Sample s = iterator.current;
      var y = INSIDE_MARGIN;
      if (s != null) {
        var blankHeight = scaleHeight - s.total();
        drawVerticalSegment(x, y, SAMPLE_WIDTH, blankHeight, 'white', scale);
        y += blankHeight;
        for (int i = s.length - 1; i >= 0; i--) {
          var h = s[i];
          drawVerticalSegment(x, y, SAMPLE_WIDTH, h, _elements[i].color, scale);
          y += s[i];
        }
      } else {
        drawVerticalSegment(x, INSIDE_MARGIN, SAMPLE_WIDTH,
            maxHeight, 'white', scale);
      }
      x += SAMPLE_WIDTH ;
    }
  }

  void drawVerticalSegment(int x, int y, int w, int h, String color,
                           num scale) {
    var context = _canvas.context2D;
    y = (y * scale).floor();
    h = (h * scale).ceil();
    context.beginPath();
    context.lineWidth = w;
    context.fillStyle = color;
    context.strokeStyle = color;
    if (x < INSIDE_MARGIN) {
      x = INSIDE_MARGIN;
    }
    if (y < INSIDE_MARGIN) {
      y = INSIDE_MARGIN;
    }
    var max = _canvas.height - INSIDE_MARGIN;
    if ((y + h) > max) {
      h = max - y;
    }
    context.moveTo(x, y);
    context.lineTo(x, y + h);
    context.stroke();
  }
}

class GraphModel extends ObservableModel {
  List<Sample> _samples = new List<Sample>();
  int _maxSize;

  static const int _LARGE_LENGTH = 999999999;

  GraphModel(this._maxSize) {}

  void addSample(List<int> segments) {
    var len = _samples.length;
    if (_samples.length >= _maxSize) {
      _samples.remove(_samples.first);
    }
    _samples.add(new Sample(segments));
    notifySuccess();
  }

  int get maxSize => _maxSize;

  Iterator<Sample> get iterator => _samples.iterator;

  Sample operator[](int i) => _samples[i];

  /**
   * Returns the minimum total from all the samples.
   */
  int get minTotal {
    var min = _LARGE_LENGTH;
    _samples.forEach((Sample s) => min = (s.total() < min ? s.total() : min));
    return min;
  }

  /**
   * Returns the maximum total from all the samples.
   */
  int get maxTotal {
    var max = 1;  // Must be non-zero.
    _samples.forEach((Sample s) => max = (s.total() > max ? s.total() : max));
    return max;
  }
}

/**
 * An element is a data type that gets charted. Each element has a name for
 * the legend, and a color for the bar graph. The number of elements in a
 * graph should match the number of segments in each sample.
 */
class Element {
  final String name;
  final String color;  // Any description the DOM will accept, like "red".

  Element(this.name, this.color) {}
}

/**
 * A sample is a list of segment lengths.
 */
class Sample {
  List<int> _segments;

  Sample(this._segments) {}

  int get length => _segments.length;
  int operator[](int i) => _segments[i];

  Iterator<int> get iterator => _segments.iterator;

  int total() {
    return _segments.fold(0, (int prev, int element) => prev + element);
  }
}
