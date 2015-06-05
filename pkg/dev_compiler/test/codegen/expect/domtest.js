dart.library('domtest', null, /* Imports */[
  'sunflower/dom',
  'dart/core'
], /* Lazy imports */[
], function(exports, dom, core) {
  'use strict';
  function testNativeIndexers() {
    let nodes = dom.document.querySelector('body').childNodes;
    for (let i = 0; dart.notNull(i) < dart.notNull(nodes.length); i = dart.notNull(i) + 1) {
      let old = nodes[i];
      nodes[i] = dom.document.createElement('div');
      core.print(dart.equals(nodes[i], old));
    }
  }
  dart.fn(testNativeIndexers);
  // Exports:
  exports.testNativeIndexers = testNativeIndexers;
});
