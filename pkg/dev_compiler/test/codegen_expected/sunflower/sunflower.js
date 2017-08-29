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
  const $getContext = dartx.getContext;
  const $addEventListener = dartx.addEventListener;
  const $text = dartx.text;
  const $arc = dartx.arc;
  const $fill = dartx.fill;
  let StringToElement = () => (StringToElement = dart.constFn(dart.fnType(html.Element, [core.String])))();
  let EventTovoid = () => (EventTovoid = dart.constFn(dart.fnType(dart.void, [html.Event])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.fnType(dart.void, [])))();
  dart.defineLazy(sunflower, {
    get SEED_RADIUS() {
      return 2;
    },
    get SCALE_FACTOR() {
      return 4;
    },
    get MAX_D() {
      return 300;
    },
    get centerX() {
      return sunflower.MAX_D / 2;
    },
    get centerY() {
      return sunflower.centerX;
    }
  });
  sunflower.querySelector = function(selector) {
    return html.document.querySelector(selector);
  };
  dart.fn(sunflower.querySelector, StringToElement());
  dart.defineLazy(sunflower, {
    get canvas() {
      return html.CanvasElement.as(sunflower.querySelector("#canvas"));
    },
    get context() {
      return html.CanvasRenderingContext2D.as(sunflower.canvas[$getContext]('2d'));
    },
    get slider() {
      return html.InputElement.as(sunflower.querySelector("#slider"));
    },
    get notes() {
      return sunflower.querySelector("#notes");
    },
    get PHI() {
      return (math.sqrt(5) + 1) / 2;
    },
    get seeds() {
      return 0;
    },
    set seeds(_) {}
  });
  sunflower.main = function() {
    sunflower.slider[$addEventListener]('change', dart.fn(e => sunflower.draw(), EventTovoid()));
    sunflower.draw();
  };
  dart.fn(sunflower.main, VoidTovoid());
  sunflower.draw = function() {
    sunflower.seeds = core.int.parse(sunflower.slider.value);
    sunflower.context.clearRect(0, 0, sunflower.MAX_D, sunflower.MAX_D);
    for (let i = 0; i < dart.notNull(sunflower.seeds); i++) {
      let theta = i * painter.TAU / dart.notNull(sunflower.PHI);
      let r = math.sqrt(i) * sunflower.SCALE_FACTOR;
      let x = sunflower.centerX + r * math.cos(theta);
      let y = sunflower.centerY - r * math.sin(theta);
      new sunflower.SunflowerSeed.new(x, y, sunflower.SEED_RADIUS).draw(sunflower.context);
    }
    sunflower.notes[$text] = dart.str`${sunflower.seeds} seeds`;
  };
  dart.fn(sunflower.draw, VoidTovoid());
  circle.Circle = class Circle extends core.Object {
    get x() {
      return this[x$];
    }
    set x(value) {
      super.x = value;
    }
    get y() {
      return this[y$];
    }
    set y(value) {
      super.y = value;
    }
    get radius() {
      return this[radius$];
    }
    set radius(value) {
      super.radius = value;
    }
  };
  (circle.Circle.new = function(x, y, radius) {
    this[x$] = x;
    this[y$] = y;
    this[radius$] = radius;
  }).prototype = circle.Circle.prototype;
  dart.addTypeTests(circle.Circle);
  const x$ = Symbol("Circle.x");
  const y$ = Symbol("Circle.y");
  const radius$ = Symbol("Circle.radius");
  dart.setSignature(circle.Circle, {
    fields: () => ({
      x: dart.finalFieldType(core.num),
      y: dart.finalFieldType(core.num),
      radius: dart.finalFieldType(core.num)
    })
  });
  painter.CirclePainter = class CirclePainter extends core.Object {
    get color() {
      return this[color];
    }
    set color(value) {
      this[color] = value;
    }
    draw(context) {
      context.beginPath();
      context.lineWidth = 2;
      context.fillStyle = this.color;
      context.strokeStyle = this.color;
      context[$arc](this.x, this.y, this.radius, 0, painter.TAU, false);
      context[$fill]();
      context.closePath();
      context.stroke();
    }
  };
  (painter.CirclePainter.new = function() {
    this[color] = painter.ORANGE;
  }).prototype = painter.CirclePainter.prototype;
  dart.addTypeTests(painter.CirclePainter);
  const color = Symbol("CirclePainter.color");
  painter.CirclePainter[dart.implements] = () => [circle.Circle];
  dart.setSignature(painter.CirclePainter, {
    fields: () => ({color: dart.fieldType(core.String)}),
    methods: () => ({draw: dart.fnType(dart.void, [html.CanvasRenderingContext2D])})
  });
  sunflower.SunflowerSeed = class SunflowerSeed extends dart.mixin(circle.Circle, painter.CirclePainter) {};
  (sunflower.SunflowerSeed.new = function(x, y, radius, color) {
    if (color === void 0) color = null;
    sunflower.SunflowerSeed.__proto__.new.call(this, x, y, radius);
    if (color != null) this.color = color;
  }).prototype = sunflower.SunflowerSeed.prototype;
  dart.addTypeTests(sunflower.SunflowerSeed);
  dart.defineLazy(painter, {
    get ORANGE() {
      return "orange";
    },
    get RED() {
      return "red";
    },
    get BLUE() {
      return "blue";
    },
    get TAU() {
      return math.PI * 2;
    }
  });
  painter.querySelector = function(selector) {
    return html.document.querySelector(selector);
  };
  dart.fn(painter.querySelector, StringToElement());
  dart.defineLazy(painter, {
    get canvas() {
      return html.CanvasElement.as(painter.querySelector("#canvas"));
    },
    get context() {
      return html.CanvasRenderingContext2D.as(painter.canvas[$getContext]('2d'));
    }
  });
  dart.trackLibraries("sunflower", {
    "sunflower.dart": sunflower,
    "circle.dart": circle,
    "painter.dart": painter
  }, null);
  // Exports:
  return {
    sunflower: sunflower,
    circle: circle,
    painter: painter
  };
});

//# sourceMappingURL=sunflower.js.map
