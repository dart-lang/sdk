var DeltaBlue;
(function(DeltaBlue) {
  'use strict';
  // Function main: () → dynamic
  function main() {
    new DeltaBlue().report();
  }
  class DeltaBlue extends BenchmarkBase.BenchmarkBase {
    DeltaBlue() {
      super.BenchmarkBase("DeltaBlue");
    }
    run() {
      chainTest(100);
      projectionTest(100);
    }
  }
  class Strength extends dart.Object {
    Strength(value, name) {
      this.value = value;
      this.name = name;
    }
    nextWeaker() {
      return /* Unimplemented const */new List.from([STRONG_PREFERRED, PREFERRED, STRONG_DEFAULT, NORMAL, WEAK_DEFAULT, WEAKEST]).get(this.value);
    }
    static stronger(s1, s2) {
      return s1.value < s2.value;
    }
    static weaker(s1, s2) {
      return s1.value > s2.value;
    }
    static weakest(s1, s2) {
      return weaker(s1, s2) ? s1 : s2;
    }
    static strongest(s1, s2) {
      return stronger(s1, s2) ? s1 : s2;
    }
  }
  let REQUIRED = new Strength(0, "required");
  let STRONG_PREFERRED = new Strength(1, "strongPreferred");
  let PREFERRED = new Strength(2, "preferred");
  let STRONG_DEFAULT = new Strength(3, "strongDefault");
  let NORMAL = new Strength(4, "normal");
  let WEAK_DEFAULT = new Strength(5, "weakDefault");
  let WEAKEST = new Strength(6, "weakest");
  class Constraint extends dart.Object {
    Constraint(strength) {
      this.strength = strength;
    }
    addConstraint() {
      this.addToGraph();
      DeltaBlue.planner.incrementalAdd(this);
    }
    satisfy(mark) {
      this.chooseMethod(dart.as(mark, core.int));
      if (!dart.notNull(this.isSatisfied())) {
        if (dart.equals(this.strength, REQUIRED)) {
          core.print("Could not satisfy a required constraint!");
        }
        return null;
      }
      this.markInputs(dart.as(mark, core.int));
      let out = this.output();
      let overridden = out.determinedBy;
      if (overridden !== null)
        overridden.markUnsatisfied();
      out.determinedBy = this;
      if (!dart.notNull(DeltaBlue.planner.addPropagate(this, dart.as(mark, core.int))))
        core.print("Cycle encountered");
      out.mark = dart.as(mark, core.int);
      return overridden;
    }
    destroyConstraint() {
      if (this.isSatisfied())
        DeltaBlue.planner.incrementalRemove(this);
      this.removeFromGraph();
    }
    isInput() {
      return false;
    }
  }
  class UnaryConstraint extends Constraint {
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
      this.satisfied = dart.notNull(this.myOutput.mark !== mark) && dart.notNull(Strength.stronger(this.strength, this.myOutput.walkStrength));
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
      if (this.myOutput.stay)
        this.execute();
    }
    markUnsatisfied() {
      this.satisfied = false;
    }
    inputsKnown(mark) {
      return true;
    }
    removeFromGraph() {
      if (this.myOutput !== null)
        this.myOutput.removeConstraint(this);
      this.satisfied = false;
    }
  }
  class StayConstraint extends UnaryConstraint {
    StayConstraint(v, str) {
      super.UnaryConstraint(v, str);
    }
    execute() {}
  }
  class EditConstraint extends UnaryConstraint {
    EditConstraint(v, str) {
      super.UnaryConstraint(v, str);
    }
    isInput() {
      return true;
    }
    execute() {}
  }
  let NONE = 1;
  let FORWARD = 2;
  let BACKWARD = 0;
  class BinaryConstraint extends Constraint {
    BinaryConstraint(v1, v2, strength) {
      this.v1 = v1;
      this.v2 = v2;
      this.direction = NONE;
      super.Constraint(strength);
      this.addConstraint();
    }
    chooseMethod(mark) {
      if (this.v1.mark === mark) {
        this.direction = dart.notNull(this.v2.mark !== mark) && dart.notNull(Strength.stronger(this.strength, this.v2.walkStrength)) ? FORWARD : NONE;
      }
      if (this.v2.mark === mark) {
        this.direction = dart.notNull(this.v1.mark !== mark) && dart.notNull(Strength.stronger(this.strength, this.v1.walkStrength)) ? BACKWARD : NONE;
      }
      if (Strength.weaker(this.v1.walkStrength, this.v2.walkStrength)) {
        this.direction = Strength.stronger(this.strength, this.v1.walkStrength) ? BACKWARD : NONE;
      } else {
        this.direction = Strength.stronger(this.strength, this.v2.walkStrength) ? FORWARD : BACKWARD;
      }
    }
    addToGraph() {
      this.v1.addConstraint(this);
      this.v2.addConstraint(this);
      this.direction = NONE;
    }
    isSatisfied() {
      return this.direction !== NONE;
    }
    markInputs(mark) {
      this.input().mark = mark;
    }
    input() {
      return this.direction === FORWARD ? this.v1 : this.v2;
    }
    output() {
      return this.direction === FORWARD ? this.v2 : this.v1;
    }
    recalculate() {
      let ihn = this.input(), out = this.output();
      out.walkStrength = Strength.weakest(this.strength, ihn.walkStrength);
      out.stay = ihn.stay;
      if (out.stay)
        this.execute();
    }
    markUnsatisfied() {
      this.direction = NONE;
    }
    inputsKnown(mark) {
      let i = this.input();
      return dart.notNull(dart.notNull(i.mark === mark) || dart.notNull(i.stay)) || dart.notNull(i.determinedBy === null);
    }
    removeFromGraph() {
      if (this.v1 !== null)
        this.v1.removeConstraint(this);
      if (this.v2 !== null)
        this.v2.removeConstraint(this);
      this.direction = NONE;
    }
  }
  class ScaleConstraint extends BinaryConstraint {
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
      if (this.scale !== null)
        this.scale.removeConstraint(this);
      if (this.offset !== null)
        this.offset.removeConstraint(this);
    }
    markInputs(mark) {
      super.markInputs(mark);
      this.scale.mark = this.offset.mark = mark;
    }
    execute() {
      if (this.direction === FORWARD) {
        this.v2.value = this.v1.value * this.scale.value + this.offset.value;
      } else {
        this.v1.value = ((this.v2.value - this.offset.value) / this.scale.value).truncate();
      }
    }
    recalculate() {
      let ihn = this.input(), out = this.output();
      out.walkStrength = Strength.weakest(this.strength, ihn.walkStrength);
      out.stay = dart.notNull(dart.notNull(ihn.stay) && dart.notNull(this.scale.stay)) && dart.notNull(this.offset.stay);
      if (out.stay)
        this.execute();
    }
  }
  class EqualityConstraint extends BinaryConstraint {
    EqualityConstraint(v1, v2, strength) {
      super.BinaryConstraint(v1, v2, strength);
    }
    execute() {
      this.output().value = this.input().value;
    }
  }
  class Variable extends dart.Object {
    Variable(name, value) {
      this.constraints = new List.from([]);
      this.name = name;
      this.value = value;
      this.determinedBy = null;
      this.mark = 0;
      this.walkStrength = WEAKEST;
      this.stay = true;
    }
    addConstraint(c) {
      this.constraints.add(c);
    }
    removeConstraint(c) {
      this.constraints.remove(c);
      if (dart.equals(this.determinedBy, c))
        this.determinedBy = null;
    }
  }
  class Planner extends dart.Object {
    Planner() {
      this.currentMark = 0;
    }
    incrementalAdd(c) {
      let mark = this.newMark();
      for (let overridden = c.satisfy(mark); overridden !== null; overridden = overridden.satisfy(mark))
        ;
    }
    incrementalRemove(c) {
      let out = c.output();
      c.markUnsatisfied();
      c.removeFromGraph();
      let unsatisfied = this.removePropagateFrom(out);
      let strength = REQUIRED;
      do {
        for (let i = 0; i < unsatisfied.length; i++) {
          let u = unsatisfied.get(i);
          if (dart.equals(u.strength, strength))
            this.incrementalAdd(u);
        }
        strength = strength.nextWeaker();
      } while (!dart.equals(strength, WEAKEST));
    }
    newMark() {
      return ++this.currentMark;
    }
    makePlan(sources) {
      let mark = this.newMark();
      let plan = new Plan();
      let todo = sources;
      while (todo.length > 0) {
        let c = todo.removeLast();
        if (dart.notNull(c.output().mark !== mark) && dart.notNull(c.inputsKnown(mark))) {
          plan.addConstraint(c);
          c.output().mark = mark;
          this.addConstraintsConsumingTo(c.output(), todo);
        }
      }
      return plan;
    }
    extractPlanFromConstraints(constraints) {
      let sources = new List.from([]);
      for (let i = 0; i < constraints.length; i++) {
        let c = constraints.get(i);
        if (dart.notNull(c.isInput()) && dart.notNull(c.isSatisfied()))
          sources.add(c);
      }
      return this.makePlan(sources);
    }
    addPropagate(c, mark) {
      let todo = new List.from([c]);
      while (todo.length > 0) {
        let d = todo.removeLast();
        if (d.output().mark === mark) {
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
      out.walkStrength = WEAKEST;
      out.stay = true;
      let unsatisfied = new List.from([]);
      let todo = new List.from([out]);
      while (todo.length > 0) {
        let v = todo.removeLast();
        for (let i = 0; i < v.constraints.length; i++) {
          let c = v.constraints.get(i);
          if (!dart.notNull(c.isSatisfied()))
            unsatisfied.add(c);
        }
        let determining = v.determinedBy;
        for (let i = 0; i < v.constraints.length; i++) {
          let next = v.constraints.get(i);
          if (dart.notNull(!dart.equals(next, determining)) && dart.notNull(next.isSatisfied())) {
            next.recalculate();
            todo.add(next.output());
          }
        }
      }
      return unsatisfied;
    }
    addConstraintsConsumingTo(v, coll) {
      let determining = v.determinedBy;
      for (let i = 0; i < v.constraints.length; i++) {
        let c = v.constraints.get(i);
        if (dart.notNull(!dart.equals(c, determining)) && dart.notNull(c.isSatisfied()))
          coll.add(c);
      }
    }
  }
  class Plan extends dart.Object {
    Plan() {
      this.list = new List.from([]);
    }
    addConstraint(c) {
      this.list.add(c);
    }
    size() {
      return this.list.length;
    }
    execute() {
      for (let i = 0; i < this.list.length; i++) {
        this.list.get(i).execute();
      }
    }
  }
  // Function chainTest: (int) → void
  function chainTest(n) {
    DeltaBlue.planner = new Planner();
    let prev = null, first = null, last = null;
    for (let i = 0; i <= n; i++) {
      let v = new Variable("v", 0);
      if (prev !== null)
        new EqualityConstraint(prev, v, REQUIRED);
      if (i === 0)
        first = v;
      if (i === n)
        last = v;
      prev = v;
    }
    new StayConstraint(last, STRONG_DEFAULT);
    let edit = new EditConstraint(first, PREFERRED);
    let plan = DeltaBlue.planner.extractPlanFromConstraints(new List.from([edit]));
    for (let i = 0; i < 100; i++) {
      first.value = i;
      plan.execute();
      if (last.value !== i) {
        core.print("Chain test failed:");
        core.print(`Expected last value to be ${i} but it was ${last.value}.`);
      }
    }
  }
  // Function projectionTest: (int) → void
  function projectionTest(n) {
    DeltaBlue.planner = new Planner();
    let scale = new Variable("scale", 10);
    let offset = new Variable("offset", 1000);
    let src = null, dst = null;
    let dests = new List.from([]);
    for (let i = 0; i < n; i++) {
      src = new Variable("src", i);
      dst = new Variable("dst", i);
      dests.add(dst);
      new StayConstraint(src, NORMAL);
      new ScaleConstraint(src, scale, offset, dst, REQUIRED);
    }
    change(src, 17);
    if (dst.value !== 1170)
      core.print("Projection 1 failed");
    change(dst, 1050);
    if (src.value !== 5)
      core.print("Projection 2 failed");
    change(scale, 5);
    for (let i = 0; i < n - 1; i++) {
      if (dests.get(i).value !== i * 5 + 1000)
        core.print("Projection 3 failed");
    }
    change(offset, 2000);
    for (let i = 0; i < n - 1; i++) {
      if (dests.get(i).value !== i * 5 + 2000)
        core.print("Projection 4 failed");
    }
  }
  // Function change: (Variable, int) → void
  function change(v, newValue) {
    let edit = new EditConstraint(v, PREFERRED);
    let plan = DeltaBlue.planner.extractPlanFromConstraints(new List.from([edit]));
    for (let i = 0; i < 10; i++) {
      v.value = newValue;
      plan.execute();
    }
    edit.destroyConstraint();
  }
  DeltaBlue.planner = null;
  // Exports:
  DeltaBlue.main = main;
  DeltaBlue.DeltaBlue = DeltaBlue;
  DeltaBlue.Strength = Strength;
  DeltaBlue.REQUIRED = REQUIRED;
  DeltaBlue.STRONG_PREFERRED = STRONG_PREFERRED;
  DeltaBlue.PREFERRED = PREFERRED;
  DeltaBlue.STRONG_DEFAULT = STRONG_DEFAULT;
  DeltaBlue.NORMAL = NORMAL;
  DeltaBlue.WEAK_DEFAULT = WEAK_DEFAULT;
  DeltaBlue.WEAKEST = WEAKEST;
  DeltaBlue.Constraint = Constraint;
  DeltaBlue.UnaryConstraint = UnaryConstraint;
  DeltaBlue.StayConstraint = StayConstraint;
  DeltaBlue.EditConstraint = EditConstraint;
  DeltaBlue.NONE = NONE;
  DeltaBlue.FORWARD = FORWARD;
  DeltaBlue.BACKWARD = BACKWARD;
  DeltaBlue.BinaryConstraint = BinaryConstraint;
  DeltaBlue.ScaleConstraint = ScaleConstraint;
  DeltaBlue.EqualityConstraint = EqualityConstraint;
  DeltaBlue.Variable = Variable;
  DeltaBlue.Planner = Planner;
  DeltaBlue.Plan = Plan;
  DeltaBlue.chainTest = chainTest;
  DeltaBlue.projectionTest = projectionTest;
  DeltaBlue.change = change;
})(DeltaBlue || (DeltaBlue = {}));
