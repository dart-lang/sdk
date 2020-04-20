# Dart MiniDesign Doc

## Optimization Levels for AOT Dart Compiler

# Introduction

In order to strike the right balance between compile-time, code speed, and code size, most optimizing compilers support several levels of optimizations, typically controlled by an -Ox switch. The usual ones relevant to this design code are:

*   O0: short compilation-time, unoptimized code, small code size; highly debuggable
*   O2: medium compilation-time, optimized code, reasonable code size
*   O3: potentially long compilation-time, highly optimized code, possibly larger code size
*   Os: medium compilation-time, optimized while favoring code size

The O0 level is typically used during development and early testing, when a very fast compilation-time is more desirable than code speed. Also, this code is best for debugging, since unoptimized code has a very straightforward mapping between native instructions and memory locations and source program instructions and variables.

The O2 level is used to generate code for shipping. It strikes a right balance between compile-time and generated code speed and size. Since shipping occurs less frequently than debugging and testing, slightly longer compilation-times are acceptable.

When either code speed or size is favored, respectively, levels O3 or Os are used. For the former, longer compilation-times are acceptable as well.

The Dart compiler conceptually only supports level O0 (the un-optimized code that is used as our deopt "fallback") and level O2 (optimized code). Although the quality of optimization can heavily depend on profile feedback (JIT) and the possibility for speculative execution, both JIT and AOT strike more or less the same balance between generated code speed and size.

# Proposal

Some optimizations are known to benefit mostly code speed (with an unfavorable or unknown impact on code size) or mostly code size (with an unfavorable or unknown impact on code speed). For example, more aggressively inlining (to a certain extent) usually yields faster but more sizable code. Conversely, not aligning code (where allowed) usually yields more compact, but potentially slower running code.

Sometimes performing more expensive analysis, which negatively impacts compile-time, may discover more optimization opportunities in some cases, but remain completely empty handed in other cases. For example, doing an expensive data dependence analysis of loops only pays of if the loop is eventually vectorized or parallelized. Otherwise, all analysis time is wasted.

Note that almost every optimization decision_ is heuristic in nature_; optimizations generally improve a certain aspect of the code, but there are no hard guarantees.

Since Dart conceptually only supports O2, _all_ optimizations must always be chosen to strike a balance between compile-time and generated code speed and size. In order to give users more control over the optimization decision when using the Dart compiler, we propose adding the concept of Os and O3 as additional compilation modes. This could be implemented as an optimization level, for example as:

```
--optimization_level=
       0: unoptimized (O0)
       1: size optimized (Os)
       2: default optimized (O2)
       3: speed optimized (O3)
```

Level 0 corresponds to our current unoptimized path, whereas level 2 corresponds to the default path through our optimization passes. The other two levels alter the default path using the following guidelines.

*   optimization_level=1 (Os)
    *   Skip O2 optimizations that tend to increase code size, even if doing so may negatively impacts code speed
    *   Introduce new optimizations that "heuristically" decrease code size, but at high risk of negatively impacting code speed
*   optimization_level=3 (O3)
    *   Introduce more detailed analysis or optimizations that "heuristically" increase code speed, but at high risk of negatively impacting compile-time or code size

The guidelines are intentionally worded this way to avoid reckless use of the flag as a substitute for proper heuristics. For example, an optimization aimed at reducing code size with a neutral impact on code speed belongs in O2, not Os. As another example, always inlining without proper heuristics just in the hope to improve speed by blindly giving up size is not something we want in O3. Also, inlining heuristics that overall increase code speed with only minimal code size increase belongs in O2.

The proposal would apply to both the JIT and AOT compiler (to avoid adding yet another dimension through the optimization passes), although initially we may only want to expose the switch externally for the AOT compiler.

Advantages of approach:

*   Allows new optimizations for size or speed that don't fit the current O2 philosophy
*   Enables removal of existing optimization from O2 that had a disproportionate negative impact on only size
*   Allows introduction of more expensive analysis that can (but is not guaranteed to) find more opportunities for optimization
*   Gives more control to users that favor size or speed differently than others
*   Potentially gives more insights on optimizations that were initially deemed to risky but helped "in the field"; perhaps better heuristics can be found to move these to O2

Disadvantages of the approach:

*   Two additional code paths through compiler, increases the size of all testing matrices (Dart, Flutter, performance, correctness)
*   Risk of misusing the flag to avoid spending time finding better heuristics
