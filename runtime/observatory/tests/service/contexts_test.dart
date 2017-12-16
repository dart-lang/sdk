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
  var x = 42; // I must captured in a context.
  block() => x;
  x++;
  return block;
}

Function genFullBlockWithChain() {
  var x = 420; // I must captured in a context.
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
  (Isolate isolate) => isolate.rootLibrary.load().then((Library lib) {
        Field field = lib.variables.singleWhere((v) => v.name == 'cleanBlock');
        return field.load().then((_) {
          return field.staticValue.load().then((Instance block) {
            expect(block.isClosure, isTrue);
            expect(block.closureContext, isNull);
          });
        });
      }),
  (Isolate isolate) => isolate.rootLibrary.load().then((Library lib) {
        Field field =
            lib.variables.singleWhere((v) => v.name == 'copyingBlock');
        return field.load().then((_) {
          return field.staticValue.load().then((Instance block) {
            expect(block.isClosure, isTrue);
            expect(block.closureContext.isContext, isTrue);
            expect(block.closureContext.length, equals(1));
            return block.closureContext.load().then((Context ctxt) {
              expect(ctxt.variables.single.value.asValue.isString, isTrue);
              expect(ctxt.variables.single.value.asValue.valueAsString,
                  equals('I could be copied into the block'));
              expect(ctxt.parentContext, isNull);
            });
          });
        });
      }),
  (Isolate isolate) => isolate.rootLibrary.load().then((Library lib) {
        Field field = lib.variables.singleWhere((v) => v.name == 'fullBlock');
        return field.load().then((_) {
          return field.staticValue.load().then((Instance block) {
            expect(block.isClosure, isTrue);
            expect(block.closureContext.isContext, isTrue);
            expect(block.closureContext.length, equals(1));
            return block.closureContext.load().then((Context ctxt) {
              expect(ctxt.variables.single.value.asValue.isInt, isTrue);
              expect(ctxt.variables.single.value.asValue.valueAsString,
                  equals('43'));
              expect(ctxt.parentContext, isNull);
            });
          });
        });
      }),
  (Isolate isolate) => isolate.rootLibrary.load().then((Library lib) {
        Field field =
            lib.variables.singleWhere((v) => v.name == 'fullBlockWithChain');
        return field.load().then((_) {
          return field.staticValue.load().then((Instance block) {
            expect(block.isClosure, isTrue);
            expect(block.closureContext.isContext, isTrue);
            expect(block.closureContext.length, equals(1));
            return block.closureContext.load().then((Context ctxt) {
              expect(ctxt.variables.single.value.asValue.isInt, isTrue);
              expect(ctxt.variables.single.value.asValue.valueAsString,
                  equals('4201'));
              expect(ctxt.parentContext.isContext, isTrue);
              expect(ctxt.parentContext.length, equals(1));
              return ctxt.parentContext.load().then((Context outerCtxt) {
                expect(outerCtxt.variables.single.value.asValue.isInt, isTrue);
                expect(outerCtxt.variables.single.value.asValue.valueAsString,
                    equals('421'));
                expect(outerCtxt.parentContext, isNull);
              });
            });
          });
        });
      }),
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
