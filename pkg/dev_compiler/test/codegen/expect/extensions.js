dart_library.library('extensions', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const extensions = Object.create(null);
  extensions.StringIterable = class StringIterable extends collection.IterableBase$(core.String) {
    StringIterable() {
      this.iterator = null;
      super.IterableBase();
    }
  };
  dart.setSignature(extensions.StringIterable, {});
  dart.defineExtensionMembers(extensions.StringIterable, ['iterator']);
  extensions.main = function() {
    return new extensions.StringIterable();
  };
  dart.fn(extensions.main);
  // Exports:
  exports.extensions = extensions;
});
