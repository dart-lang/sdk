dart_library.library('extensions', null, /* Imports */[
  'dart/_runtime',
  'dart/collection',
  'dart/core'
], /* Lazy imports */[
], function(exports, dart, collection, core) {
  'use strict';
  let dartx = dart.dartx;
  class StringIterable extends collection.IterableBase$(core.String) {
    StringIterable() {
      this.iterator = null;
      super.IterableBase();
    }
  }
  dart.virtualField(StringIterable, 'iterator');
  dart.setSignature(StringIterable, {});
  dart.defineExtensionMembers(StringIterable, ['iterator']);
  function main() {
    return new StringIterable();
  }
  dart.fn(main);
  // Exports:
  exports.StringIterable = StringIterable;
  exports.main = main;
});
