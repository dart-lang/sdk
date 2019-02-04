## Dart Mini Design Doc

### Using Data Dependence to Preserve Control Dependence

## Introduction

The [DartFuzzer](http://go/dartfuzz) found [bug 34684](https://github.com/dart-lang/sdk/issues/34684) with the current LICM implementation. We need a fix urgently, since this bug may break user code, emerges for pretty much every nightly fuzz test run (making investigating new fuzz test divergences cumbersome; most of the time, it is a "same as"), and blocks moving towards more shards per nightly fuzz test run (the Q4 objective is 100 shards with 8 isolates each). Fixing the LICM bug, however, requires a bit more redesign in the way _control dependence_ is preserved in our IR.

## The Problem

The bug itself consists of an issue with applying LICM to an array bound check with loop invariant values. In its simplest form, LICM should not be applied to the bounds check that belongs to `l[j]` below since the loop condition (for a situation `k <= 0`) could logically protect OOB exceptions for particular values of `n` (for example, calling `foo(2,0)` should not throw).

```
void foo(int n, int k) {
  var l = new List<int>(1);
  var j = n - 1;
  for (var i = 0; i < k; i++) {
     l[j] = 10;
  }
}
```
Hosting the seemingly loop invariant bounds check out of the loop would break the control dependence between the loop condition and potentially move an OOB exception into the always-taken path.

An obvious fix would simply disable hoisting `CheckBound` constructs of out loops, thereby respecting the control dependence between condition and check. However, this exposes another omission in our IR with respect to control dependence. Leaving `CheckBound` in place would not prevent hoisting the IndexLoad that follows, as illustrated below.

```
              ←-----------------+
for loop                         |
    Checkbound (length, index)   |      <- pinned in the loop
    IndexLoad (base, index)   ---+
```
In this case, this problem is caused by the fact that the control dependence from `CheckBound` to `IndexLoad` is not made explicit. Trending on the same path would require us to disable hoisting such instructions as well….

At first glance, it may seem that a `Redefinition` could help here, as in:

```
for loop
  v0 = get array
  v1 = get length of v0
  v2 = get index
  CheckBound:id(v1, v2)
  v3 <- Redefinition(v2)
  IndexLoad(v0, v3)
```
This would indeed keep the index load instruction inside the loop, thereby relying on not-too-well-documented assumptions on unmovable redefinitions and the now explicit data dependence on `v3`. However, this approach would be too prohibitive, since cases that would allow for hoisting or eliminating `CheckBound` from the IR would not break the newly introduced chain on v3 (nothing in the IR expresses the relation between the `Redefinition` and the `CheckBound`).

Alternatively, we could introduce control dependence as an explicit, but orthogonal order in our compiler. However, this would require introducing a new data structure to our IR as well as inspecting all code to ensure that this new order is indeed respected. The next section introduces a simpler solution.

## Proposed Solution

The proposed solution is making the control dependence between any check and all its uses explicit with a data dependence, as shown below.

```
  v3 <- CheckBound:id(v1, v2)   // returns the index value v2 in v3
  IndexLoad(v0, v3)
```

The semantics of the new node is that the returned value (`v3`) is a safe index (viz. checked values `v2`) into any load that uses that value. Any optimization that hoists or removes the `CheckBound` automatically exposes the opportunity for further optimization of the load by hoisting or breaking the dependence on `v3`. Common subexpression elimination can also be applied to equal-valued `CheckBound` nodes.

For completeness, the same approach will be taken for null checks.

The construct

```
 CheckNull:id(v2)
 v100 <- LoadField(v2, …)
```
will be replaced by

```
 v3 = CheckNull:id(v2)  // returns the reference value v2 in v3
 v100 <- LoadField(v3, …)
```
Here, the value `v3` denotes a safe, null-checked reference of `v2`.

The explicit data dependence ensures that all passes and transformations automatically preserve the required order, without the need to make adjustments anywhere else. In contrast, introducing an explicit control dependence as a new concept in our compiler would require a careful inspection of all code to make sure the new dependence is respected. A drawback of the new "indirection" through the check is that it may break some optimizations and simplifications that inspect the inputs directly. Although cumbersome, since it also involves looking at a lot of code, this is easily remedied by "looking under the hood" of checks (as is done for redefinitions). Missed opportunities for optimizations are preferable over missed correctness.

The proposed solution will have _no impact_ on the register allocator or any of our backends, since the new data dependence will be removed in the `FinalizeGraph` pass, similar to what is already done now for redefinitions in `RemoveRedefinitions()`, except that this method will only redirect the inputs across checks, but obviously not remove the checks themselves. Nothing that runs after the register allocator should move code around too freely, an assumption that is already made in our current implementation with respect to redefinitions.

This approach was used successfully in [the ART optimization compiler](https://cs.corp.google.com/android/art/compiler/optimizing/nodes.h). Here, check-based control dependence was made explicit with data dependence. All passes and transformations were aware that data dependence should always be satisfied (inter- and intra-basic block), whereas all optimizations that crossed basic blocks were aware of _implicit_ control dependence (e.g. using dominance relation). In combination with the actual LICM fix, the proposed solution will result in a previously proven robust framework for null and bounds checks.

## IR Nodes

Our IR currently has the following "check" instructions. Although potentially others could benefit form this new scheme too, the first CL will focus on the ones marked below only. As the implementation progresses, we may introduce some "object-orientedness" for check instructions that return their safe value.

```
CheckEitherNonSmiInstr
CheckClassInstr
CheckSmiInstr
CheckNullInstr                 // returns safe non-null reference
CheckClassIdInstr
CheckArrayBoundInstr           // returns safe non-OOBE index
GenericCheckBoundInstr         // returns safe non-OOBE index
CheckConditionInstr

