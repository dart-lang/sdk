// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

library inbound_references_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var cleanBlock, copyingBlock, fullBlock, fullBlockWithChain;

Function genCleanBlock() {
  block(x) => x;
  return block;
}

Function genCopyingBlock() {
  final x = 'I could be copied into the block';
  block() => x;
  return block;
}

Function genFullBlock() {
  var x = 42;  // I must captured in a context.
  block() => x;
  x++;
  return block;
}

Function genFullBlockWithChain() {
  var x = 420;  // I must captured in a context.
  outerBlock() {
    var y = 4200;
    innerBlock() => x + y;
    y++;
    return innerBlock;
  }
  x++;
  return outerBlock();
}

void script() {
  cleanBlock = genCleanBlock();
  copyingBlock = genCopyingBlock();
  fullBlock = genFullBlock();
  fullBlockWithChain = genFullBlockWithChain();
}

var tests = [

(Isolate isolate) =>
  isolate.rootLibrary.load().then((Library lib) {
    Field field = lib.variables.singleWhere((v) => v.name == 'cleanBlock');
    return field.load().then((_) {
      return field.staticValue.load().then((Instance block) {
        expect(block.isClosure, isTrue);
        expect(block.context.isContext, isTrue);
        expect(block.context.length, equals(0));
        return block.context.load().then((Context ctxt) {
          expect(ctxt.parentContext, isNull);
        });
      });
    });
  }),

(Isolate isolate) =>
  isolate.rootLibrary.load().then((Library lib) {
    Field field = lib.variables.singleWhere((v) => v.name == 'copyingBlock');
    return field.load().then((_) {
      return field.staticValue.load().then((Instance block) {
        expect(block.isClosure, isTrue);
        expect(block.context.isContext, isTrue);
        expect(block.context.length, equals(1));
        return block.context.load().then((Context ctxt) {
          expect(ctxt.variables.single['value'].isString, isTrue);
          expect(ctxt.variables.single['value'].valueAsString, equals('I could be copied into the block'));
          expect(ctxt.parentContext.isContext, isTrue);
          expect(ctxt.parentContext.length, equals(0));
          return ctxt.parentContext.load().then((Context outerCtxt) {
            expect(outerCtxt.parentContext, isNull);
          });
        });
      });
    });
  }),

(Isolate isolate) =>
  isolate.rootLibrary.load().then((Library lib) {
    Field field = lib.variables.singleWhere((v) => v.name == 'fullBlock');
    return field.load().then((_) {
      return field.staticValue.load().then((Instance block) {
        expect(block.isClosure, isTrue);
        expect(block.context.isContext, isTrue);
        expect(block.context.length, equals(1));
        return block.context.load().then((ctxt) {
          expect(ctxt.variables.single['value'].isInt, isTrue);
          expect(ctxt.variables.single['value'].valueAsString, equals('43'));
          expect(ctxt.parentContext.isContext, isTrue);
          expect(ctxt.parentContext.length, equals(0));
          return ctxt.parentContext.load().then((Context outerCtxt) {
            expect(outerCtxt.parentContext, isNull);
          });
        });
      });
    });
  }),

(Isolate isolate) =>
  isolate.rootLibrary.load().then((Library lib) {
    Field field = lib.variables.singleWhere((v) => v.name == 'fullBlockWithChain');
    return field.load().then((_) {
      return field.staticValue.load().then((Instance block) {
        expect(block.isClosure, isTrue);
        expect(block.context.isContext, isTrue);
        expect(block.context.length, equals(1));
        return block.context.load().then((Context ctxt) {
          expect(ctxt.variables.single['value'].isInt, isTrue);
          expect(ctxt.variables.single['value'].valueAsString, equals('4201'));
          expect(ctxt.parentContext.isContext, isTrue);
          expect(ctxt.parentContext.length, equals(1));
          return ctxt.parentContext.load().then((Context outerCtxt) {
            expect(outerCtxt.variables.single['value'].isInt, isTrue);
            expect(outerCtxt.variables.single['value'].valueAsString, equals('421'));
            expect(outerCtxt.parentContext.isContext, isTrue);
            expect(outerCtxt.parentContext.length, equals(0));
            return outerCtxt.parentContext.load().then((Context outerCtxt2) {
                expect(outerCtxt2.parentContext, isNull);
            });
          });
        });
      });
    });
  }),

];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
