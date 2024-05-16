> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Frequently asked questions about the Dart VM

## Inlining of Dart methods by the JIT/AOT compilers

1. What are the conditions and requirements for a method to be inlined ?

    First, compiler needs to figure out that a particular call in the caller leads to a particular callee. For static methods and constructors this is always the case. For instance methods it depends on the class hierarchy, whether the method is overridden and whether compiler can determine (or speculate on) the actual type of the receiver. Method is less likely to be inlined if call site is polymorphic (can call multiple different methods).
    
    After figuring out the target of the call, compiler uses a very complex heuristic to decide whether to inline a method or not. The heuristic is based on the size of the caller and the callee, number of call sites in the callee, loop nesting in the caller etc. @pragma("vm:prefer-inline") on the callee bypasses those heuristics and tells compiler to inline annotated method if it is possible.

    Currently compiler cannot inline certain methods, even if they are annotated with @pragma("vm:prefer-inline"). Those include methods with a try block, methods declared async, async*, sync* and certain core library methods.


2. Could this pragma be useful for public methods which called from other classes and using private fields like in this example
  `@pragma(vm:prefer-inline)`
  `void removeClient(int fd) => _serversByClients.remove(fd);`?

    Absolutely. However, unless the method is critical for performance and you can measure that inlining of this method improves performance, consider relying on the compiler heuristic. Excessive inlining causes larger code size, and in certain cases inlining may regress performance instead of improving it.

3. Inlining is possible in JIT and AOT modes or only JIT?

    Both JIT and AOT compilers do the method inlining. However, the heuristic for choosing whether to inline is slightly different and based on different information. JIT can inline speculatively, based on the collected feedback from executing program. AOT compiler uses whole-program analysis to determine possible call targets which can be inlined. Both JIT and AOT respect @pragma("vm:prefer-inline") annotation.
