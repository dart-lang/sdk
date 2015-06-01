var domtest = dart.defineLibrary(domtest, {});
var dom = dart.import(dom);
var core = dart.import(core);
(function(exports, dom, core) {
  'use strict';
  // Function testNativeIndexers: () → dynamic
  function testNativeIndexers() {
    let nodes = dom.document.querySelector('body').childNodes;
    for (let i = 0; dart.notNull(i) < dart.notNull(nodes.length); i = dart.notNull(i) + 1) {
      core.print(nodes[i]);
      core.print(nodes[i] = null);
    }
  }
  // Exports:
  exports.testNativeIndexers = testNativeIndexers;
})(domtest, dom, core);
