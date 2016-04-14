dart_library.library('DeltaBlue', null, /* Imports */[
  'dart_sdk'
], function(exports, dart_sdk) {
  'use strict';
  const core = dart_sdk.core;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const DeltaBlue$ = Object.create(null);
  const BenchmarkBase$ = Object.create(null);
  DeltaBlue$.main = function() {
    new DeltaBlue$.DeltaBlue().report();
  };
  dart.fn(DeltaBlue$.main);
  BenchmarkBase$.BenchmarkBase = class BenchmarkBase extends core.Object {
    BenchmarkBase(name) {
      this.name = name;
    }
    run() {}
    warmup() {
      this.run();
    }
    exercise() {
      for (let i = 0; i < 10; i++) {
        this.run();
      }
    }
    setup() {}
    teardown() {}
    static measureFor(f, timeMinimum) {
      let time = 0;
      let iter = 0;
      let watch = new core.Stopwatch();
      watch.start();
      let elapsed = 0;
      while (dart.notNull(elapsed) < dart.notNull(timeMinimum)) {
        dart.dcall(f);
        elapsed = watch.elapsedMilliseconds;
        iter++;
      }
      return 1000.0 * dart.notNull(elapsed) / iter;
    }
    measure() {
      this.setup();
      BenchmarkBase$.BenchmarkBase.measureFor(dart.fn(() => {
        this.warmup();
      }), 100);
      let result = BenchmarkBase$.BenchmarkBase.measureFor(dart.fn(() => {
        this.exercise();
      }), 2000);
      this.teardown();
      return result;
    }
    report() {
      let score = this.measure();
      core.print(`${this.name}(RunTime): ${score} us.`);
    }
  };
  dart.setSignature(BenchmarkBase$.BenchmarkBase, {
    constructors: () => ({BenchmarkBase: [BenchmarkBase$.BenchmarkBase, [core.String]]}),
    methods: () => ({
      run: [dart.void, []],
      warmup: [dart.void, []],
      exercise: [dart.void, []],
      setup: [dart.void, []],
      teardown: [dart.void, []],
      measure: [core.double, []],
      report: [dart.void, []]
    }),
    statics: () => ({measureFor: [core.double, [core.Function, core.int]]}),
    names: ['measureFor']
  });
  DeltaBlue$.DeltaBlue = class DeltaBlue extends BenchmarkBase$.BenchmarkBase {
    DeltaBlue() {
      super.BenchmarkBase("DeltaBlue");
    }
    run() {
      DeltaBlue$.chainTest(100);
      DeltaBlue$.projectionTest(100);
    }
  };
  dart.setSignature(DeltaBlue$.DeltaBlue, {
    constructors: () => ({DeltaBlue: [DeltaBlue$.DeltaBlue, []]})
  });
  DeltaBlue$.Strength = class Strength extends core.Object {
    Strength(value, name) {
      this.value = value;
      this.name = name;
    }
    nextWeaker() {
      return dart.const(dart.list([DeltaBlue$.STRONG_PREFERRED, DeltaBlue$.PREFERRED, DeltaBlue$.STRONG_DEFAULT, DeltaBlue$.NORMAL, DeltaBlue$.WEAK_DEFAULT, DeltaBlue$.WEAKEST], DeltaBlue$.Strength))[dartx.get](this.value);
    }
    static stronger(s1, s2) {
      return dart.notNull(s1.value) < dart.notNull(s2.value);
    }
    static weaker(s1, s2) {
      return dart.notNull(s1.value) > dart.notNull(s2.value);
    }
    static weakest(s1, s2) {
      return dart.notNull(DeltaBlue$.Strength.weaker(s1, s2)) ? s1 : s2;
    }
    static strongest(s1, s2) {
      return dart.notNull(DeltaBlue$.Strength.stronger(s1, s2)) ? s1 : s2;
    }
  };
  dart.setSignature(DeltaBlue$.Strength, {
    constructors: () => ({Strength: [DeltaBlue$.Strength, [core.int, core.String]]}),
    methods: () => ({nextWeaker: [DeltaBlue$.Strength, []]}),
    statics: () => ({
      stronger: [core.bool, [DeltaBlue$.Strength, DeltaBlue$.Strength]],
      weaker: [core.bool, [DeltaBlue$.Strength, DeltaBlue$.Strength]],
      weakest: [DeltaBlue$.Strength, [DeltaBlue$.Strength, DeltaBlue$.Strength]],
      strongest: [DeltaBlue$.Strength, [DeltaBlue$.Strength, DeltaBlue$.Strength]]
    }),
    names: ['stronger', 'weaker', 'weakest', 'strongest']
  });
  DeltaBlue$.REQUIRED = dart.const(new DeltaBlue$.Strength(0, "required"));
  DeltaBlue$.STRONG_PREFERRED = dart.const(new DeltaBlue$.Strength(1, "strongPreferred"));
  DeltaBlue$.PREFERRED = dart.const(new DeltaBlue$.Strength(2, "preferred"));
  DeltaBlue$.STRONG_DEFAULT = dart.const(new DeltaBlue$.Strength(3, "strongDefault"));
  DeltaBlue$.NORMAL = dart.const(new DeltaBlue$.Strength(4, "normal"));
  DeltaBlue$.WEAK_DEFAULT = dart.const(new DeltaBlue$.Strength(5, "weakDefault"));
  DeltaBlue$.WEAKEST = dart.const(new DeltaBlue$.Strength(6, "weakest"));
  DeltaBlue$.Constraint = class Constraint extends core.Object {
    Constraint(strength) {
      this.strength = strength;
    }
    addConstraint() {
      this.addToGraph();
      DeltaBlue$.planner.incrementalAdd(this);
    }
    satisfy(mark) {
      this.chooseMethod(dart.as(mark, core.int));
      if (!dart.notNull(this.isSatisfied())) {
        if (dart.equals(this.strength, DeltaBlue$.REQUIRED)) {
          core.print("Could not satisfy a required constraint!");
        }
        return null;
      }
      this.markInputs(dart.as(mark, core.int));
      let out = this.output();
      let overridden = out.determinedBy;
      if (overridden != null) overridden.markUnsatisfied();
      out.determinedBy = this;
      if (!dart.notNull(DeltaBlue$.planner.addPropagate(this, dart.as(mark, core.int)))) core.print("Cycle encountered");
      out.mark = dart.as(mark, core.int);
      return overridden;
    }
    destroyConstraint() {
      if (dart.notNull(this.isSatisfied())) DeltaBlue$.planner.incrementalRemove(this);
      this.removeFromGraph();
    }
    isInput() {
      return false;
    }
  };
  dart.setSignature(DeltaBlue$.Constraint, {
    constructors: () => ({Constraint: [DeltaBlue$.Constraint, [DeltaBlue$.Strength]]}),
    methods: () => ({
      addConstraint: [dart.void, []],
      satisfy: [DeltaBlue$.Constraint, [dart.dynamic]],
      destroyConstraint: [dart.void, []],
      isInput: [core.bool, []]
    })
  });
  DeltaBlue$.UnaryConstraint = class UnaryConstraint extends DeltaBlue$.Constraint {
    UnaryConstraint(myOutput, strength) {
      this.myOutput = myOutput;
      this.satisfied = false;
      super.Constraint(strength);
      this.addConstraint();
    }
    addToGraph() {
      this.myOutput.addConstraint(this);
      this.satisfied = false;
    }
    chooseMethod(mark) {
      this.satisfied = this.myOutput.mark != mark && dart.notNull(DeltaBlue$.Strength.stronger(this.strength, this.myOutput.walkStrength));
    }
    isSatisfied() {
      return this.satisfied;
    }
    markInputs(mark) {}
    output() {
      return this.myOutput;
    }
    recalculate() {
      this.myOutput.walkStrength = this.strength;
      this.myOutput.stay = !dart.notNull(this.isInput());
      if (dart.notNull(this.myOutput.stay)) this.execute();
    }
    markUnsatisfied() {
      this.satisfied = false;
    }
    inputsKnown(mark) {
      return true;
    }
    removeFromGraph() {
      if (this.myOutput != null) this.myOutput.removeConstraint(this);
      this.satisfied = false;
    }
  };
  dart.setSignature(DeltaBlue$.UnaryConstraint, {
    constructors: () => ({UnaryConstraint: [DeltaBlue$.UnaryConstraint, [DeltaBlue$.Variable, DeltaBlue$.Strength]]}),
    methods: () => ({
      addToGraph: [dart.void, []],
      chooseMethod: [dart.void, [core.int]],
      isSatisfied: [core.bool, []],
      markInputs: [dart.void, [core.int]],
      output: [DeltaBlue$.Variable, []],
      recalculate: [dart.void, []],
      markUnsatisfied: [dart.void, []],
      inputsKnown: [core.bool, [core.int]],
      removeFromGraph: [dart.void, []]
    })
  });
  DeltaBlue$.StayConstraint = class StayConstraint extends DeltaBlue$.UnaryConstraint {
    StayConstraint(v, str) {
      super.UnaryConstraint(v, str);
    }
    execute() {}
  };
  dart.setSignature(DeltaBlue$.StayConstraint, {
    constructors: () => ({StayConstraint: [DeltaBlue$.StayConstraint, [DeltaBlue$.Variable, DeltaBlue$.Strength]]}),
    methods: () => ({execute: [dart.void, []]})
  });
  DeltaBlue$.EditConstraint = class EditConstraint extends DeltaBlue$.UnaryConstraint {
    EditConstraint(v, str) {
      super.UnaryConstraint(v, str);
    }
    isInput() {
      return true;
    }
    execute() {}
  };
  dart.setSignature(DeltaBlue$.EditConstraint, {
    constructors: () => ({EditConstraint: [DeltaBlue$.EditConstraint, [DeltaBlue$.Variable, DeltaBlue$.Strength]]}),
    methods: () => ({execute: [dart.void, []]})
  });
  DeltaBlue$.NONE = 1;
  DeltaBlue$.FORWARD = 2;
  DeltaBlue$.BACKWARD = 0;
  DeltaBlue$.BinaryConstraint = class BinaryConstraint extends DeltaBlue$.Constraint {
    BinaryConstraint(v1, v2, strength) {
      this.v1 = v1;
      this.v2 = v2;
      this.direction = DeltaBlue$.NONE;
      super.Constraint(strength);
      this.addConstraint();
    }
    chooseMethod(mark) {
      if (this.v1.mark == mark) {
        this.direction = this.v2.mark != mark && dart.notNull(DeltaBlue$.Strength.stronger(this.strength, this.v2.walkStrength)) ? DeltaBlue$.FORWARD : DeltaBlue$.NONE;
      }
      if (this.v2.mark == mark) {
        this.direction = this.v1.mark != mark && dart.notNull(DeltaBlue$.Strength.stronger(this.strength, this.v1.walkStrength)) ? DeltaBlue$.BACKWARD : DeltaBlue$.NONE;
      }
      if (dart.notNull(DeltaBlue$.Strength.weaker(this.v1.walkStrength, this.v2.walkStrength))) {
        this.direction = dart.notNull(DeltaBlue$.Strength.stronger(this.strength, this.v1.walkStrength)) ? DeltaBlue$.BACKWARD : DeltaBlue$.NONE;
      } else {
        this.direction = dart.notNull(DeltaBlue$.Strength.stronger(this.strength, this.v2.walkStrength)) ? DeltaBlue$.FORWARD : DeltaBlue$.BACKWARD;
      }
    }
    addToGraph() {
      this.v1.addConstraint(this);
      this.v2.addConstraint(this);
      this.direction = DeltaBlue$.NONE;
    }
    isSatisfied() {
      return this.direction != DeltaBlue$.NONE;
    }
    markInputs(mark) {
      this.input().mark = mark;
    }
    input() {
      return this.direction == DeltaBlue$.FORWARD ? this.v1 : this.v2;
    }
    output() {
      return this.direction == DeltaBlue$.FORWARD ? this.v2 : this.v1;
    }
    recalculate() {
      let ihn = this.input(), out = this.output();
      out.walkStrength = DeltaBlue$.Strength.weakest(this.strength, ihn.walkStrength);
      out.stay = ihn.stay;
      if (dart.notNull(out.stay)) this.execute();
    }
    markUnsatisfied() {
      this.direction = DeltaBlue$.NONE;
    }
    inputsKnown(mark) {
      let i = this.input();
      return i.mark == mark || dart.notNull(i.stay) || i.determinedBy == null;
    }
    removeFromGraph() {
      if (this.v1 != null) this.v1.removeConstraint(this);
      if (this.v2 != null) this.v2.removeConstraint(this);
      this.direction = DeltaBlue$.NONE;
    }
  };
  dart.setSignature(DeltaBlue$.BinaryConstraint, {
    constructors: () => ({BinaryConstraint: [DeltaBlue$.BinaryConstraint, [DeltaBlue$.Variable, DeltaBlue$.Variable, DeltaBlue$.Strength]]}),
    methods: () => ({
      chooseMethod: [dart.void, [core.int]],
      addToGraph: [dart.void, []],
      isSatisfied: [core.bool, []],
      markInputs: [dart.void, [core.int]],
      input: [DeltaBlue$.Variable, []],
      output: [DeltaBlue$.Variable, []],
      recalculate: [dart.void, []],
      markUnsatisfied: [dart.void, []],
      inputsKnown: [core.bool, [core.int]],
      removeFromGraph: [dart.void, []]
    })
  });
  DeltaBlue$.ScaleConstraint = class ScaleConstraint extends DeltaBlue$.BinaryConstraint {
    ScaleConstraint(src, scale, offset, dest, strength) {
      this.scale = scale;
      this.offset = offset;
      super.BinaryConstraint(src, dest, strength);
    }
    addToGraph() {
      super.addToGraph();
      this.scale.addConstraint(this);
      this.offset.addConstraint(this);
    }
    removeFromGraph() {
      super.removeFromGraph();
      if (this.scale != null) this.scale.removeConstraint(this);
      if (this.offset != null) this.offset.removeConstraint(this);
    }
    markInputs(mark) {
      super.markInputs(mark);
      this.scale.mark = this.offset.mark = mark;
    }
    execute() {
      if (this.direction == DeltaBlue$.FORWARD) {
        this.v2.value = dart.notNull(this.v1.value) * dart.notNull(this.scale.value) + dart.notNull(this.offset.value);
      } else {
        this.v1.value = ((dart.notNull(this.v2.value) - dart.notNull(this.offset.value)) / dart.notNull(this.scale.value))[dartx.truncate]();
      }
    }
    recalculate() {
      let ihn = this.input(), out = this.output();
      out.walkStrength = DeltaBlue$.Strength.weakest(this.strength, ihn.walkStrength);
      out.stay = dart.notNull(ihn.stay) && dart.notNull(this.scale.stay) && dart.notNull(this.offset.stay);
      if (dart.notNull(out.stay)) this.execute();
    }
  };
  dart.setSignature(DeltaBlue$.ScaleConstraint, {
    constructors: () => ({ScaleConstraint: [DeltaBlue$.ScaleConstraint, [DeltaBlue$.Variable, DeltaBlue$.Variable, DeltaBlue$.Variable, DeltaBlue$.Variable, DeltaBlue$.Strength]]}),
    methods: () => ({execute: [dart.void, []]})
  });
  DeltaBlue$.EqualityConstraint = class EqualityConstraint extends DeltaBlue$.BinaryConstraint {
    EqualityConstraint(v1, v2, strength) {
      super.BinaryConstraint(v1, v2, strength);
    }
    execute() {
      this.output().value = this.input().value;
    }
  };
  dart.setSignature(DeltaBlue$.EqualityConstraint, {
    constructors: () => ({EqualityConstraint: [DeltaBlue$.EqualityConstraint, [DeltaBlue$.Variable, DeltaBlue$.Variable, DeltaBlue$.Strength]]}),
    methods: () => ({execute: [dart.void, []]})
  });
  DeltaBlue$.Variable = class Variable extends core.Object {
    Variable(name, value) {
      this.constraints = dart.list([], DeltaBlue$.Constraint);
      this.name = name;
      this.value = value;
      this.determinedBy = null;
      this.mark = 0;
      this.walkStrength = DeltaBlue$.WEAKEST;
      this.stay = true;
    }
    addConstraint(c) {
      this.constraints[dartx.add](c);
    }
    removeConstraint(c) {
      this.constraints[dartx.remove](c);
      if (dart.equals(this.determinedBy, c)) this.determinedBy = null;
    }
  };
  dart.setSignature(DeltaBlue$.Variable, {
    constructors: () => ({Variable: [DeltaBlue$.Variable, [core.String, core.int]]}),
    methods: () => ({
      addConstraint: [dart.void, [DeltaBlue$.Constraint]],
      removeConstraint: [dart.void, [DeltaBlue$.Constraint]]
    })
  });
  DeltaBlue$.Planner = class Planner extends core.Object {
    Planner() {
      this.currentMark = 0;
    }
    incrementalAdd(c) {
      let mark = this.newMark();
      for (let overridden = c.satisfy(mark); overridden != null; overridden = overridden.satisfy(mark))
        ;
    }
    incrementalRemove(c) {
      let out = c.output();
      c.markUnsatisfied();
      c.removeFromGraph();
      let unsatisfied = this.removePropagateFrom(out);
      let strength = DeltaBlue$.REQUIRED;
      do {
        for (let i = 0; i < dart.notNull(unsatisfied[dartx.length]); i++) {
          let u = unsatisfied[dartx.get](i);
          if (dart.equals(u.strength, strength)) this.incrementalAdd(u);
        }
        strength = strength.nextWeaker();
      } while (!dart.equals(strength, DeltaBlue$.WEAKEST));
    }
    newMark() {
      return this.currentMark = dart.notNull(this.currentMark) + 1;
    }
    makePlan(sources) {
      let mark = this.newMark();
      let plan = new DeltaBlue$.Plan();
      let todo = sources;
      while (dart.notNull(todo[dartx.length]) > 0) {
        let c = todo[dartx.removeLast]();
        if (c.output().mark != mark && dart.notNull(c.inputsKnown(mark))) {
          plan.addConstraint(c);
          c.output().mark = mark;
          this.addConstraintsConsumingTo(c.output(), todo);
        }
      }
      return plan;
    }
    extractPlanFromConstraints(constraints) {
      let sources = dart.list([], DeltaBlue$.Constraint);
      for (let i = 0; i < dart.notNull(constraints[dartx.length]); i++) {
        let c = constraints[dartx.get](i);
        if (dart.notNull(c.isInput()) && dart.notNull(c.isSatisfied())) sources[dartx.add](c);
      }
      return this.makePlan(sources);
    }
    addPropagate(c, mark) {
      let todo = dart.list([c], DeltaBlue$.Constraint);
      while (dart.notNull(todo[dartx.length]) > 0) {
        let d = todo[dartx.removeLast]();
        if (d.output().mark == mark) {
          this.incrementalRemove(c);
          return false;
        }
        d.recalculate();
        this.addConstraintsConsumingTo(d.output(), todo);
      }
      return true;
    }
    removePropagateFrom(out) {
      out.determinedBy = null;
      out.walkStrength = DeltaBlue$.WEAKEST;
      out.stay = true;
      let unsatisfied = dart.list([], DeltaBlue$.Constraint);
      let todo = dart.list([out], DeltaBlue$.Variable);
      while (dart.notNull(todo[dartx.length]) > 0) {
        let v = todo[dartx.removeLast]();
        for (let i = 0; i < dart.notNull(v.constraints[dartx.length]); i++) {
          let c = v.constraints[dartx.get](i);
          if (!dart.notNull(c.isSatisfied())) unsatisfied[dartx.add](c);
        }
        let determining = v.determinedBy;
        for (let i = 0; i < dart.notNull(v.constraints[dartx.length]); i++) {
          let next = v.constraints[dartx.get](i);
          if (!dart.equals(next, determining) && dart.notNull(next.isSatisfied())) {
            next.recalculate();
            todo[dartx.add](next.output());
          }
        }
      }
      return unsatisfied;
    }
    addConstraintsConsumingTo(v, coll) {
      let determining = v.determinedBy;
      for (let i = 0; i < dart.notNull(v.constraints[dartx.length]); i++) {
        let c = v.constraints[dartx.get](i);
        if (!dart.equals(c, determining) && dart.notNull(c.isSatisfied())) coll[dartx.add](c);
      }
    }
  };
  dart.setSignature(DeltaBlue$.Planner, {
    methods: () => ({
      incrementalAdd: [dart.void, [DeltaBlue$.Constraint]],
      incrementalRemove: [dart.void, [DeltaBlue$.Constraint]],
      newMark: [core.int, []],
      makePlan: [DeltaBlue$.Plan, [core.List$(DeltaBlue$.Constraint)]],
      extractPlanFromConstraints: [DeltaBlue$.Plan, [core.List$(DeltaBlue$.Constraint)]],
      addPropagate: [core.bool, [DeltaBlue$.Constraint, core.int]],
      removePropagateFrom: [core.List$(DeltaBlue$.Constraint), [DeltaBlue$.Variable]],
      addConstraintsConsumingTo: [dart.void, [DeltaBlue$.Variable, core.List$(DeltaBlue$.Constraint)]]
    })
  });
  DeltaBlue$.Plan = class Plan extends core.Object {
    Plan() {
      this.list = dart.list([], DeltaBlue$.Constraint);
    }
    addConstraint(c) {
      this.list[dartx.add](c);
    }
    size() {
      return this.list[dartx.length];
    }
    execute() {
      for (let i = 0; i < dart.notNull(this.list[dartx.length]); i++) {
        this.list[dartx.get](i).execute();
      }
    }
  };
  dart.setSignature(DeltaBlue$.Plan, {
    methods: () => ({
      addConstraint: [dart.void, [DeltaBlue$.Constraint]],
      size: [core.int, []],
      execute: [dart.void, []]
    })
  });
  DeltaBlue$.chainTest = function(n) {
    DeltaBlue$.planner = new DeltaBlue$.Planner();
    let prev = null, first = null, last = null;
    for (let i = 0; i <= dart.notNull(n); i++) {
      let v = new DeltaBlue$.Variable("v", 0);
      if (prev != null) new DeltaBlue$.EqualityConstraint(prev, v, DeltaBlue$.REQUIRED);
      if (i == 0) first = v;
      if (i == n) last = v;
      prev = v;
    }
    new DeltaBlue$.StayConstraint(last, DeltaBlue$.STRONG_DEFAULT);
    let edit = new DeltaBlue$.EditConstraint(first, DeltaBlue$.PREFERRED);
    let plan = DeltaBlue$.planner.extractPlanFromConstraints(dart.list([edit], DeltaBlue$.Constraint));
    for (let i = 0; i < 100; i++) {
      first.value = i;
      plan.execute();
      if (last.value != i) {
        core.print("Chain test failed:");
        core.print(`Expected last value to be ${i} but it was ${last.value}.`);
      }
    }
  };
  dart.fn(DeltaBlue$.chainTest, dart.void, [core.int]);
  DeltaBlue$.projectionTest = function(n) {
    DeltaBlue$.planner = new DeltaBlue$.Planner();
    let scale = new DeltaBlue$.Variable("scale", 10);
    let offset = new DeltaBlue$.Variable("offset", 1000);
    let src = null, dst = null;
    let dests = dart.list([], DeltaBlue$.Variable);
    for (let i = 0; i < dart.notNull(n); i++) {
      src = new DeltaBlue$.Variable("src", i);
      dst = new DeltaBlue$.Variable("dst", i);
      dests[dartx.add](dst);
      new DeltaBlue$.StayConstraint(src, DeltaBlue$.NORMAL);
      new DeltaBlue$.ScaleConstraint(src, scale, offset, dst, DeltaBlue$.REQUIRED);
    }
    DeltaBlue$.change(src, 17);
    if (dst.value != 1170) core.print("Projection 1 failed");
    DeltaBlue$.change(dst, 1050);
    if (src.value != 5) core.print("Projection 2 failed");
    DeltaBlue$.change(scale, 5);
    for (let i = 0; i < dart.notNull(n) - 1; i++) {
      if (dests[dartx.get](i).value != i * 5 + 1000) core.print("Projection 3 failed");
    }
    DeltaBlue$.change(offset, 2000);
    for (let i = 0; i < dart.notNull(n) - 1; i++) {
      if (dests[dartx.get](i).value != i * 5 + 2000) core.print("Projection 4 failed");
    }
  };
  dart.fn(DeltaBlue$.projectionTest, dart.void, [core.int]);
  DeltaBlue$.change = function(v, newValue) {
    let edit = new DeltaBlue$.EditConstraint(v, DeltaBlue$.PREFERRED);
    let plan = DeltaBlue$.planner.extractPlanFromConstraints(dart.list([edit], DeltaBlue$.EditConstraint));
    for (let i = 0; i < 10; i++) {
      v.value = newValue;
      plan.execute();
    }
    edit.destroyConstraint();
  };
  dart.fn(DeltaBlue$.change, dart.void, [DeltaBlue$.Variable, core.int]);
  DeltaBlue$.planner = null;
  BenchmarkBase$.Expect = class Expect extends core.Object {
    static equals(expected, actual) {
      if (!dart.equals(expected, actual)) {
        dart.throw(`Values not equal: ${expected} vs ${actual}`);
      }
    }
    static listEquals(expected, actual) {
      if (expected[dartx.length] != actual[dartx.length]) {
        dart.throw(`Lists have different lengths: ${expected[dartx.length]} vs ${actual[dartx.length]}`);
      }
      for (let i = 0; i < dart.notNull(actual[dartx.length]); i++) {
        BenchmarkBase$.Expect.equals(expected[dartx.get](i), actual[dartx.get](i));
      }
    }
    fail(message) {
      dart.throw(message);
    }
  };
  dart.setSignature(BenchmarkBase$.Expect, {
    methods: () => ({fail: [dart.dynamic, [dart.dynamic]]}),
    statics: () => ({
      equals: [dart.void, [dart.dynamic, dart.dynamic]],
      listEquals: [dart.void, [core.List, core.List]]
    }),
    names: ['equals', 'listEquals']
  });
  // Exports:
  exports.DeltaBlue = DeltaBlue$;
  exports.BenchmarkBase = BenchmarkBase$;
});
