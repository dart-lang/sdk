dart.library('circle', null, /* Imports */[
  'dart/core'
], /* Lazy imports */[
], function(exports, core) {
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
});
