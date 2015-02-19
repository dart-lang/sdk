var html_input_a;
(function (html_input_a) {
  'use strict';
  // Function main: () → dynamic
  function main() {
    core.print(`fib(${html_input_b.x} + ${html_input_c.y}) = `);
    core.print(`  ... ${html_input_d.fib(html_input_b.x + html_input_c.y)}`);
  }

  // Exports:
  html_input_a.main = main;
})(html_input_a || (html_input_a = {}));
