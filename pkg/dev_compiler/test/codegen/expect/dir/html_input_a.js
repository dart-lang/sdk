var html_input_a = dart.defineLibrary(html_input_a, {});
var core = dart.import(core);
var html_input_b = dart.import(html_input_b);
var html_input_c = dart.import(html_input_c);
var html_input_d = dart.import(html_input_d);
(function(exports, core, html_input_b, html_input_c, html_input_d) {
  'use strict';
  function main() {
    core.print(`fib(${html_input_b.x} + ${html_input_c.y}) = `);
    core.print(`  ... ${html_input_d.fib(dart.notNull(html_input_b.x) + dart.notNull(html_input_c.y))}`);
  }
  dart.fn(main);
  // Exports:
  exports.main = main;
})(html_input_a, core, html_input_b, html_input_c, html_input_d);
