dart_library.library('language/mixin_bound_test', null, /* Imports */[
  'dart_sdk',
  'expect'
], function load__mixin_bound_test(exports, dart_sdk, expect) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const expect$ = expect.expect;
  const mixin_bound_test = Object.create(null);
  let AbstractAddition = () => (AbstractAddition = dart.constFn(mixin_bound_test.AbstractAddition$()))();
  let AbstractSubtraction = () => (AbstractSubtraction = dart.constFn(mixin_bound_test.AbstractSubtraction$()))();
  let AdditionWithEval = () => (AdditionWithEval = dart.constFn(mixin_bound_test.AdditionWithEval$()))();
  let SubtractionWithEval = () => (SubtractionWithEval = dart.constFn(mixin_bound_test.SubtractionWithEval$()))();
  let AbstractMultiplication = () => (AbstractMultiplication = dart.constFn(mixin_bound_test.AbstractMultiplication$()))();
  let MultiplicationWithEval = () => (MultiplicationWithEval = dart.constFn(mixin_bound_test.MultiplicationWithEval$()))();
  let AdditionWithStringConversion = () => (AdditionWithStringConversion = dart.constFn(mixin_bound_test.AdditionWithStringConversion$()))();
  let SubtractionWithStringConversion = () => (SubtractionWithStringConversion = dart.constFn(mixin_bound_test.SubtractionWithStringConversion$()))();
  let MultiplicationWithStringConversion = () => (MultiplicationWithStringConversion = dart.constFn(mixin_bound_test.MultiplicationWithStringConversion$()))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  mixin_bound_test.AbstractExpression = class AbstractExpression extends core.Object {};
  mixin_bound_test.AbstractAddition$ = dart.generic(E => {
    class AbstractAddition extends core.Object {
      new(operand1, operand2) {
        this.operand1 = operand1;
        this.operand2 = operand2;
      }
    }
    dart.addTypeTests(AbstractAddition);
    dart.setSignature(AbstractAddition, {
      constructors: () => ({new: dart.definiteFunctionType(mixin_bound_test.AbstractAddition$(E), [E, E])})
    });
    return AbstractAddition;
  });
  mixin_bound_test.AbstractAddition = AbstractAddition();
  mixin_bound_test.AbstractSubtraction$ = dart.generic(E => {
    class AbstractSubtraction extends core.Object {
      new(operand1, operand2) {
        this.operand1 = operand1;
        this.operand2 = operand2;
      }
    }
    dart.addTypeTests(AbstractSubtraction);
    dart.setSignature(AbstractSubtraction, {
      constructors: () => ({new: dart.definiteFunctionType(mixin_bound_test.AbstractSubtraction$(E), [E, E])})
    });
    return AbstractSubtraction;
  });
  mixin_bound_test.AbstractSubtraction = AbstractSubtraction();
  mixin_bound_test.AbstractNumber = class AbstractNumber extends core.Object {
    new(val) {
      this.val = val;
    }
  };
  dart.setSignature(mixin_bound_test.AbstractNumber, {
    constructors: () => ({new: dart.definiteFunctionType(mixin_bound_test.AbstractNumber, [core.int])})
  });
  mixin_bound_test.ExpressionWithEval = class ExpressionWithEval extends core.Object {};
  mixin_bound_test.AdditionWithEval$ = dart.generic(E => {
    class AdditionWithEval extends core.Object {
      get eval() {
        return dart.notNull(this.operand1.eval) + dart.notNull(this.operand2.eval);
      }
    }
    dart.addTypeTests(AdditionWithEval);
    return AdditionWithEval;
  });
  mixin_bound_test.AdditionWithEval = AdditionWithEval();
  mixin_bound_test.SubtractionWithEval$ = dart.generic(E => {
    class SubtractionWithEval extends core.Object {
      get eval() {
        return dart.notNull(this.operand1.eval) - dart.notNull(this.operand2.eval);
      }
    }
    dart.addTypeTests(SubtractionWithEval);
    return SubtractionWithEval;
  });
  mixin_bound_test.SubtractionWithEval = SubtractionWithEval();
  mixin_bound_test.NumberWithEval = class NumberWithEval extends core.Object {
    get eval() {
      return this.val;
    }
  };
  mixin_bound_test.AbstractMultiplication$ = dart.generic(E => {
    class AbstractMultiplication extends core.Object {
      new(operand1, operand2) {
        this.operand1 = operand1;
        this.operand2 = operand2;
      }
    }
    dart.addTypeTests(AbstractMultiplication);
    dart.setSignature(AbstractMultiplication, {
      constructors: () => ({new: dart.definiteFunctionType(mixin_bound_test.AbstractMultiplication$(E), [E, E])})
    });
    return AbstractMultiplication;
  });
  mixin_bound_test.AbstractMultiplication = AbstractMultiplication();
  mixin_bound_test.MultiplicationWithEval$ = dart.generic(E => {
    class MultiplicationWithEval extends core.Object {
      get eval() {
        return dart.notNull(this.operand1.eval) * dart.notNull(this.operand2.eval);
      }
    }
    dart.addTypeTests(MultiplicationWithEval);
    return MultiplicationWithEval;
  });
  mixin_bound_test.MultiplicationWithEval = MultiplicationWithEval();
  mixin_bound_test.ExpressionWithStringConversion = class ExpressionWithStringConversion extends core.Object {};
  mixin_bound_test.AdditionWithStringConversion$ = dart.generic(E => {
    class AdditionWithStringConversion extends core.Object {
      toString() {
        return dart.str`(${this.operand1} + ${this.operand2}))`;
      }
    }
    dart.addTypeTests(AdditionWithStringConversion);
    return AdditionWithStringConversion;
  });
  mixin_bound_test.AdditionWithStringConversion = AdditionWithStringConversion();
  mixin_bound_test.SubtractionWithStringConversion$ = dart.generic(E => {
    class SubtractionWithStringConversion extends core.Object {
      toString() {
        return dart.str`(${this.operand1} - ${this.operand2})`;
      }
    }
    dart.addTypeTests(SubtractionWithStringConversion);
    return SubtractionWithStringConversion;
  });
  mixin_bound_test.SubtractionWithStringConversion = SubtractionWithStringConversion();
  mixin_bound_test.NumberWithStringConversion = class NumberWithStringConversion extends core.Object {
    toString() {
      return dart.toString(this.val);
    }
  };
  mixin_bound_test.MultiplicationWithStringConversion$ = dart.generic(E => {
    class MultiplicationWithStringConversion extends core.Object {
      toString() {
        return dart.str`(${this.operand1} * ${this.operand2})`;
      }
    }
    dart.addTypeTests(MultiplicationWithStringConversion);
    return MultiplicationWithStringConversion;
  });
  mixin_bound_test.MultiplicationWithStringConversion = MultiplicationWithStringConversion();
  mixin_bound_test.Expression = class Expression extends dart.mixin(mixin_bound_test.AbstractExpression, mixin_bound_test.ExpressionWithEval, mixin_bound_test.ExpressionWithStringConversion) {
    new() {
      super.new();
    }
  };
  mixin_bound_test.Addition = class Addition extends dart.mixin(mixin_bound_test.AbstractAddition$(mixin_bound_test.Expression), mixin_bound_test.AdditionWithEval$(mixin_bound_test.Expression), mixin_bound_test.AdditionWithStringConversion$(mixin_bound_test.Expression)) {
    new(operand1, operand2) {
      super.new(operand1, operand2);
    }
  };
  mixin_bound_test.Subtraction = class Subtraction extends dart.mixin(mixin_bound_test.AbstractSubtraction$(mixin_bound_test.Expression), mixin_bound_test.SubtractionWithEval$(mixin_bound_test.Expression), mixin_bound_test.SubtractionWithStringConversion$(mixin_bound_test.Expression)) {
    new(operand1, operand2) {
      super.new(operand1, operand2);
    }
  };
  mixin_bound_test.Number = class Number extends dart.mixin(mixin_bound_test.AbstractNumber, mixin_bound_test.NumberWithEval, mixin_bound_test.NumberWithStringConversion) {
    new(val) {
      super.new(val);
    }
  };
  mixin_bound_test.Multiplication = class Multiplication extends dart.mixin(mixin_bound_test.AbstractMultiplication$(mixin_bound_test.Expression), mixin_bound_test.MultiplicationWithEval$(mixin_bound_test.Expression), mixin_bound_test.MultiplicationWithStringConversion$(mixin_bound_test.Expression)) {
    new(operand1, operand2) {
      super.new(operand1, operand2);
    }
  };
  mixin_bound_test.main = function() {
    let e = new mixin_bound_test.Multiplication(new mixin_bound_test.Addition(new mixin_bound_test.Number(4), new mixin_bound_test.Number(2)), new mixin_bound_test.Subtraction(new mixin_bound_test.Number(10), new mixin_bound_test.Number(7)));
    expect$.Expect.equals('((4 + 2)) * (10 - 7)) = 18', dart.str`${e} = ${e.eval}`);
  };
  dart.fn(mixin_bound_test.main, VoidTovoid());
  // Exports:
  exports.mixin_bound_test = mixin_bound_test;
});
