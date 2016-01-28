dart_library.library('domtest', null, /* Imports */[
  'dart/_runtime',
  'sunflower/dom',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, dom, core) {
  'use strict';
  let dartx = dart.dartx;
  function testNativeIndexers() {
    let nodes = dom.document.querySelector('body').childNodes;
    for (let i = 0; i < dart.notNull(nodes.length); i++) {
      let old = nodes[i];
      nodes[i] = dom.document.createElement('div');
      core.print(dart.equals(nodes[i], old));
    }
  }
  dart.fn(testNativeIndexers);
  // Exports:
  exports.testNativeIndexers = testNativeIndexers;
});
