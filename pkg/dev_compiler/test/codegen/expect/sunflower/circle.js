var circle = dart.defineLibrary(circle, {});
var core = dart.import(core);
(function(exports, core) {
  'use strict';
  class Circle extends core.Object {
    Circle(x, y, radius) {
      this.x = x;
      this.y = y;
      this.radius = radius;
    }
  }
  dart.setSignature(Circle, {
    constructors: () => ({Circle: [Circle, [core.num, core.num, core.num]]})
  });
  // Exports:
  exports.Circle = Circle;
})(circle, core);
