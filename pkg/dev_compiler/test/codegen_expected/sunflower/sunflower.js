define(['dart_sdk'], function(dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const html = dart_sdk.html;
  const math = dart_sdk.math;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const sunflower = Object.create(null);
  const circle = Object.create(null);
  const painter = Object.create(null);
  let StringToElement = () => (StringToElement = dart.constFn(dart.definiteFunctionType(html.Element, [core.String])))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [html.Event])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  sunflower.SEED_RADIUS = 2;
  sunflower.SCALE_FACTOR = 4;
  sunflower.MAX_D = 300;
  sunflower.centerX = sunflower.MAX_D / 2;
  sunflower.centerY = sunflower.centerX;
  sunflower.querySelector = function(selector) {
    return html.document[dartx.querySelector](selector);
  };
  dart.fn(sunflower.querySelector, StringToElement());
  dart.defineLazy(sunflower, {
    get canvas() {
      return html.CanvasElement.as(sunflower.querySelector("#canvas"));
    }
  });
  dart.defineLazy(sunflower, {
    get context() {
      return html.CanvasRenderingContext2D.as(sunflower.canvas[dartx.getContext]('2d'));
    }
  });
  dart.defineLazy(sunflower, {
    get slider() {
      return html.InputElement.as(sunflower.querySelector("#slider"));
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
    sunflower.slider[dartx.addEventListener]('change', dart.fn(e => sunflower.draw(), EventTovoid()));
    sunflower.draw();
  };
  dart.fn(sunflower.main, VoidTovoid());
  sunflower.draw = function() {
    sunflower.seeds = core.int.parse(sunflower.slider[dartx.value]);
    sunflower.context[dartx.clearRect](0, 0, sunflower.MAX_D, sunflower.MAX_D);
    for (let i = 0; i < dart.notNull(sunflower.seeds); i++) {
      let theta = i * painter.TAU / dart.notNull(sunflower.PHI);
      let r = dart.notNull(math.sqrt(i)) * sunflower.SCALE_FACTOR;
      let x = sunflower.centerX + r * dart.notNull(math.cos(theta));
      let y = sunflower.centerY - r * dart.notNull(math.sin(theta));
      new sunflower.SunflowerSeed(x, y, sunflower.SEED_RADIUS).draw(sunflower.context);
    }
    sunflower.notes[dartx.text] = dart.str`${sunflower.seeds} seeds`;
  };
  dart.fn(sunflower.draw, VoidTovoid());
  circle.Circle = class Circle extends core.Object {
    new(x, y, radius) {
      this.x = x;
      this.y = y;
      this.radius = radius;
    }
  };
  dart.setSignature(circle.Circle, {
    fields: () => ({
      x: core.num,
      y: core.num,
      radius: core.num
    })
  });
  painter.CirclePainter = class CirclePainter extends core.Object {
    new() {
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
    fields: () => ({color: core.String}),
    methods: () => ({draw: dart.definiteFunctionType(dart.void, [html.CanvasRenderingContext2D])})
  });
  sunflower.SunflowerSeed = class SunflowerSeed extends dart.mixin(circle.Circle, painter.CirclePainter) {
    new(x, y, radius, color) {
      if (color === void 0) color = null;
      super.new(x, y, radius);
      if (color != null) this.color = color;
    }
  };
  painter.ORANGE = "orange";
  painter.RED = "red";
  painter.BLUE = "blue";
  painter.TAU = math.PI * 2;
  painter.querySelector = function(selector) {
    return html.document[dartx.querySelector](selector);
  };
  dart.fn(painter.querySelector, StringToElement());
  dart.defineLazy(painter, {
    get canvas() {
      return html.CanvasElement.as(painter.querySelector("#canvas"));
    }
  });
  dart.defineLazy(painter, {
    get context() {
      return html.CanvasRenderingContext2D.as(painter.canvas[dartx.getContext]('2d'));
    }
  });
  // Exports:
  return {
    sunflower: sunflower,
    circle: circle,
    painter: painter
  };
});

//# sourceMappingURL=sunflower.js.map
