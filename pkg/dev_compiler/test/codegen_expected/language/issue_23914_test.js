dart_library.library('language/issue_23914_test', null, /* Imports */[
  'dart_sdk'
], function load__issue_23914_test(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const collection = dart_sdk.collection;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const issue_23914_test = Object.create(null);
  let LinkedListEntryOfE = () => (LinkedListEntryOfE = dart.constFn(collection.LinkedListEntry$(E)))();
  let LinkedListEntryOfLinkedListEntryOfE = () => (LinkedListEntryOfLinkedListEntryOfE = dart.constFn(collection.LinkedListEntry$(LinkedListEntryOfE())))();
  let LinkedListOfLinkedListEntryOfLinkedListEntryOfE = () => (LinkedListOfLinkedListEntryOfLinkedListEntryOfE = dart.constFn(collection.LinkedList$(LinkedListEntryOfLinkedListEntryOfE())))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  issue_23914_test.main = function() {
    let a = core.List.unmodifiable(new (LinkedListOfLinkedListEntryOfLinkedListEntryOfE())());
  };
  dart.fn(issue_23914_test.main, VoidTodynamic());
  // Exports:
  exports.issue_23914_test = issue_23914_test;
});
