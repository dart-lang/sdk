dart_library.library('sunflower', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const sunflower = Object.create(null);
  const circle = Object.create(null);
  const painter = Object.create(null);
  sunflower.SEED_RADIUS = 2;
  sunflower.SCALE_FACTOR = 4;
  sunflower.MAX_D = 300;
  sunflower.centerX = dart.notNull(sunflower.MAX_D) / 2;
  sunflower.centerY = sunflower.centerX;
  sunflower.querySelector = function(selector) {
    return html.document[dartx.querySelector](selector);
  };
  dart.fn(sunflower.querySelector, html.Element, [core.String]);
  dart.defineLazy(sunflower, {
    get canvas() {
      return dart.as(sunflower.querySelector("#canvas"), html.CanvasElement);
    }
  });
  dart.defineLazy(sunflower, {
    get context() {
      return dart.as(sunflower.canvas[dartx.getContext]('2d'), html.CanvasRenderingContext2D);
    }
  });
  dart.defineLazy(sunflower, {
    get slider() {
      return dart.as(sunflower.querySelector("#slider"), html.InputElement);
    }
  });
  dart.defineLazy(sunflower, {
    get notes() {
      return sunflower.querySelector("#notes");
    }
  });
  dart.defineLazy(sunflower, {
    get PHI() {
      return (dart.notNull(math.sqrt(5)) + 1) / 2;
    }
  });
  sunflower.seeds = 0;
  sunflower.main = function() {
    sunflower.slider[dartx.addEventListener]('change', dart.fn(e => sunflower.draw(), dart.void, [html.Event]));
    sunflower.draw();
  };
  dart.fn(sunflower.main, dart.void, []);
  sunflower.draw = function() {
    sunflower.seeds = core.int.parse(sunflower.slider[dartx.value]);
    sunflower.context[dartx.clearRect](0, 0, sunflower.MAX_D, sunflower.MAX_D);
    for (let i = 0; i < dart.notNull(sunflower.seeds); i++) {
      let theta = i * dart.notNull(painter.TAU) / dart.notNull(sunflower.PHI);
      let r = dart.notNull(math.sqrt(i)) * dart.notNull(sunflower.SCALE_FACTOR);
      let x = dart.notNull(sunflower.centerX) + r * dart.notNull(math.cos(theta));
      let y = dart.notNull(sunflower.centerY) - r * dart.notNull(math.sin(theta));
      new sunflower.SunflowerSeed(x, y, sunflower.SEED_RADIUS).draw(sunflower.context);
    }
    sunflower.notes[dartx.text] = `${sunflower.seeds} seeds`;
  };
  dart.fn(sunflower.draw, dart.void, []);
  circle.Circle = class Circle extends core.Object {
    Circle(x, y, radius) {
      this.x = x;
      this.y = y;
      this.radius = radius;
    }
  };
  dart.setSignature(circle.Circle, {
    constructors: () => ({Circle: [circle.Circle, [core.num, core.num, core.num]]})
  });
  painter.CirclePainter = class CirclePainter extends core.Object {
    CirclePainter() {
      this.color = painter.ORANGE;
    }
    draw(context) {
      context[dartx.beginPath]();
      context[dartx.lineWidth] = 2;
      context[dartx.fillStyle] = this.color;
      context[dartx.strokeStyle] = this.color;
      context[dartx.arc](this.x, this.y, this.radius, 0, painter.TAU, false);
      context[dartx.fill]();
      context[dartx.closePath]();
      context[dartx.stroke]();
    }
  };
  painter.CirclePainter[dart.implements] = () => [circle.Circle];
  dart.setSignature(painter.CirclePainter, {
    methods: () => ({draw: [dart.void, [html.CanvasRenderingContext2D]]})
  });
  sunflower.SunflowerSeed = class SunflowerSeed extends dart.mixin(circle.Circle, painter.CirclePainter) {
    SunflowerSeed(x, y, radius, color) {
      if (color === void 0) color = null;
      super.Circle(x, y, radius);
      if (color != null) this.color = color;
    }
  };
  dart.setSignature(sunflower.SunflowerSeed, {
    constructors: () => ({SunflowerSeed: [sunflower.SunflowerSeed, [core.num, core.num, core.num], [core.String]]})
  });
  painter.ORANGE = "orange";
  painter.RED = "red";
  painter.BLUE = "blue";
  painter.TAU = dart.notNull(math.PI) * 2;
  painter.querySelector = function(selector) {
    return html.document[dartx.querySelector](selector);
  };
  dart.fn(painter.querySelector, html.Element, [core.String]);
  dart.defineLazy(painter, {
    get canvas() {
      return dart.as(painter.querySelector("#canvas"), html.CanvasElement);
    }
  });
  dart.defineLazy(painter, {
    get context() {
      return dart.as(painter.canvas[dartx.getContext]('2d'), html.CanvasRenderingContext2D);
    }
  });
  // Exports:
  exports.sunflower = sunflower;
  exports.circle = circle;
  exports.painter = painter;
});

//# sourceMappingURL=sunflower.js.map
