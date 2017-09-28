Dart - Fixed-Size Integers
===
2017-09-26
floitsch@google.com

This document discusses Dart's plan to switch the `int` type so that it represents 64-bit integers instead of bignums. It is part of our continued effort of changing the integer type to fixed size ([issue]).

[issue]: https://github.com/dart-lang/sdk/issues/30343

We propose to set the size of integers to 64 bits. Among all the investigated options, 64-bit integers have the smallest migration cost, and provide the most consistent and future-proof API capabilities.

## Motivation
Dart​ ​1​ ​has​ ​infinite-precision​ ​integers​ ​(aka​ ​bignums).​ ​On​ ​the​ ​VM,​ ​almost​ ​every
number-operation​ ​must​ ​check​ ​if​ ​the​ ​result​ ​overflowed,​ ​and​ ​if​ ​yes,​ ​allocate​ ​a
next-bigger​ ​number​ ​type.​ ​In​ ​practice​ ​this​ ​means​ ​that​ ​most​ ​numbers​ ​are​ ​represented​ ​as
SMIs​ ​(Small​ ​Integers),​ ​a​ ​tagged​ ​number​ ​type,​ ​that​ ​overflow​ ​into​ ​MINTs​ ​(Medium
Integers),​ ​and​ ​finally​ ​overflow​ ​into​ ​arbitrary-size ​big-ints.

In​ ​a​ ​jitted​ ​environment,​ ​the​ ​code​ ​for​ ​mints​ ​and​ ​bigints​ ​can​ ​be​ ​generated​ ​lazily
during​ ​a​ ​bailout​ ​that​ ​is​ ​invoked​ ​when​ ​the​ ​overflow​ ​is​ ​detected.​ ​This​ ​means​ ​that
almost​ ​all​ ​compiled​ ​code​ simply ​has​ ​the​ ​SMI​ ​assembly,​ ​and​ ​just​ ​checks​ ​for​ ​overflows.​ ​In the​ ​rare​ ​case​ ​where​ ​more​ ​than​ ​31/63​ ​bits​ ​(the​ ​SMI​ ​size​ ​on​ ​32bit​ ​and​ ​64bit
architectures)​ ​are​ ​needed,​ ​does​ ​the​ ​JIT​ ​generate​ ​the​ ​code​ ​for​ ​more​ ​number​ ​types.

For​ ​precompilation​ ​it's​ ​not​ ​possible​ ​to​ ​generate​ ​the​ ​mint/bigint​ ​code​ ​lazily.​ Typically, the generated code only contains inlined SMI instructions and falls back to calls when the type is not a SMI. Before being able to use the SMI code, instructions have to be checked for their type (`null`, or `Mint`/`BigInt`) and after most operations they need to be checked for overflows. This blows​ ​up​ ​the​ ​executable​ ​and​ ​generally​ ​slows​ ​down​ ​the​ ​code.​ ​As​ ​a​ ​consequence,​ ​Dart 2.0 ​switches​ ​to​ ​fixed-size​ ​integers. Without knowing if a number variable is non-nullable, most of the checks cannot be removed, but there are two ways to get this information:
1. a global type-inference can sometimes know that specific variables can never be `null`, and
2. Dart intends to add non-nullable types.

## Semantics
An `int` represents a signed 64-bit two's complement integer. They have the following properties:

- Integers wrap around, or worded differently, all operations are done modulo 2^64.
  If an operation overflows (that is the resulting value exceeds the maximum int64 value 9,223,372,036,854,775,807) then the value is reduced modulo 2^64 and the resulting bits are treated as a signed 64 bit integer (using 2's complement for negative numbers). A similar operation happens when the operation underflows.
- Integer literals must fit into the signed 64-bit range. For convenience, hexadecimal literals are also valid if they fit the unsigned 64-bit range. It is a compile-time error if literals do not fit this range. The check takes '-' into account. That is, the `MIN_INT64` literal -9223372036854775808 is accepted.
  Conceptually, the evaluation of unary-minus looks at its expression first, and, if it is an integer literal, evaluates that literal allowing 9223372036854775808 (and not just 9223372036854775807). In practice, this means that `-9223372036854775808` is accepted, but `-9223372036854775808.floor()` is not, because the nested expression of `-` is `9223372036854775808.floor()` and not just the integer literal.
- The `<<` operator is specified to shift "out" bits that leave the 64-bit range. Shifting might change the sign of an integer value. All bits of the operand are used as input to shifting operations. Some CPU architectures, like ia32 and x64, only use the least-significant 6 bits for the right-hand-side operand, so this requires more work from the compiler: `int x = 0x10000; printf("%d\n" 1 << x);` prints "1".
- A new `>>>` operator is added to support "unsigned" right-shifts and is added as const-operation.

### Rationale
#### Wrap-around
Dart 2.0's integers wrap around when they over/underflow. We considered alternatives, such as saturation, unspecified behavior, or exceptions, but found that wrap-around provides the most convenient properties:

1. It's efficient (one CPU instruction on 64-bit machines).
2. It makes it possible to do unsigned int64 operations without too much code. For example, addition, subtraction, and multiplication can be done on int64s (representing unsigned int64 values) and the bits of the result can then simply be interpreted as unsigned int64.
3. Some architectures (for example RISC-V) don't support overflow checks. (See https://www.slideshare.net/YiHsiuHsu/riscv-introduction slide 12).


#### Literals
It is a compile-time error if a decimal literal does not fit into the signed int64 range (-9,223,372,036,854,775,808 to +9,223,372,036,854,775,807). When the operand expression of a unary minus operator is an integer literal, the negation expression itself is also considered part of the integer literal. Writing literals that don't fit in that range are not allowed.

However, when integers are treated as individual bits rather than numerical values, then developers generally use the hexadecimal notation. In these cases, it is convenient to allow unsigned int64 values as well, even though their bits are immediately interpreted as signed int64. This means that `0xFFFFFFFFFFFFFFFF` is valid, and is equivalent to -1. Similarly, users can write code like `int signBit = 0x8000000000000000;`.

## Library Changes
- `double.toInt()`, `double.ceil()`, `double.floor()` and `double.round()` are clamped to `MIN_INT64` and `MAX_INT64`. The `ceilToDouble()`, `floorToDouble()` and `roundToDouble()` functions are unaffected and don't clamp.
- `int.parse` fails (invokes the provided `onError` function) if the input is a decimal representation of an integer that doesn't fit the signed 64-bit range. This is true for all radices. The only exception are hexadecimal literals that start with "0x". Literals starting with "0x" may encode 64-bit integers (thus spanning the unsigned 64-bit range).
  This behavior is equivalent to the treatment of integer literals.
- `int.parseHex` is added to support reading in unsigned 64 bit integers. The `int.parseHex` does not allow negative signs and is optimized to read positive hex numbers of up to 64 bits.
- `int.toUnsigned` throws if the argument is >= 64. This adds a check to the method. When performance is important, these members are generally invoked with a constant (usually 32, 16, or 8) in which case the check can be eliminated.

## Constants
Const operations have the same semantics as their runtime counterparts. Specifically, const operations also wrap around. Contrary to Go, which uses arbitrary-size integers to compute constants, Dart has the same semantics for const and runtime operations. This choice is motivated by the fact that in Dart many operations are compile-time constants, even if they haven't been marked as such.

For example:

``` dart
var x = (0x7FFFFFFFFFFFFFFF + 1) ~/ 3;  // A compile-time constant.
var y_0 = 0x7FFFFFFFFFFFFFFF;
var y = (y_0 + 1) ~/ 3;  // Not a compile-time constant.
```

As can be seen in this example, Dart does not rely on a context to determine if an expression is constant or not. Expressions (even inside non-const expressions) that satisfy specific properties are considered const and must be executed at compile-time. It would be extremely confusing if `x` and `y` would yield different values. If constants were computed with bigInt semantics, then `x` would be equal to `3074457345618258602`, whereas the non-constant `y` would be equal to `-3074457345618258602` (a negative number).

## Spec-Change
In section "10.1.1 Operators", add `>>>` as an allowed operator.

In section "16.1 Constants", add `e1 >>> e2` as constant expression.

In section "16.3 Numbers".

Update the sections defining numeric literals and their grammar as follows:
```
A numeric literal is either a decimal or hexadecimal numeral representing an integer value, or a decimal double representation.
```

Update the explanatory paragraphs of the integer range
> In principle, the range of integers supported by a Dart implementations is unlimited. In practice, it is limited by available memory. Implementations may also be limited by other considerations.
>
> In practice, implementations may be limited by other considerations. For example, implementations may choose to limit the range to facilitate efficient compilation to JavaScript.

and replace it with:

```
Integers in Dart are signed values of 64 bits in two's complement form. It is a compile-time error if a decimal integer literal does not fit into this size (-9,223,372,036,854,775,808 to +9,223,372,036,854,775,807). It is a compile-time error if a hexadecimal integer literal does not fit into the signed *or* unsigned 64 bit range (in total -9,223,372,036,854,775,808 to 18,446,744,073,709,551,615). If the literal only fits the unsigned range, then the literal's value is determined by using the corresponding value modulo 2^64 in the signed 64-bit range.

In practice, implementations may be limited by other considerations. For example, implementations may choose a different representation to facilitate efficient compilation to JavaScript.
```

Finally add error checking (maybe in 16.3):
```
It is a compile-time error if a decimal numeric literal represents an integer value that cannot be represented as a signed 64-bit two's complement integer, unless that numeric literal is the operand of a unary minus operator, in which case it is a compile-time error if the negation of the numeral's integer value cannot be represented as a signed 64-bit two's complement integer.

It is a compile-time error if a hexadecimal numeric literal represents an integer value that cannot be represented as an unsigned 64-bit two's complement integer, unless that numeric literal is the operand of a unary minus operator, in which case it is a compile-time error if the negation of the numeral's integer value cannot be represented as a signed 64-bit two's complement integer.
```

## Compatibility & JavaScript
This change has very positive backwards-compatibility properties: it is almost non-breaking for all web applications, and only affects VM programs that use integers of 65+ bits. These are relatively rare. In fact, many common operations will get simpler on the VM, since users don't need to think about SMIs anymore. For example, users often bit-and their numbers to ensure that the compiler can see that a number will never need more than a SMI. A typical example would be the JenkinsHash which has been modified to fit into SMIs:

``` dart
/**
 * Jenkins hash function, optimized for small integers.
 * Borrowed from sdk/lib/math/jenkins_smi_hash.dart.
 */
class JenkinsSmiHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
  ...
}
```

For applications that compile to JavaScript this function would still be useful, but in a pure VM/AoT context the hash function could be simplified or updated to use a performant 64 bit hash instead.

We expect dart2js to continue mapping to JavaScript's numbers, which means that dart2js would continue to be non-compliant. That is, it would still not implement the correct integer type and only support 53 bits of accurate integers (32 bits for bit-operations). For bigger values, in particular protobuf IDs, users would still need to use the 64-bit `Int64` class from the `fixnum` package, or switch to the `typed_data:BigInt` class (see below).

This also means that packages need to pay attention when developing on the VM. Their code might not run correctly when compiled to dart2js. These problems do exist already now, and there is unfortunately not a good solution.

Note that dart2js might want to do one change to its treatment of integers. Whereas currently `1e100` is identified as an integer (in checked mode or in an `is` check), this could change. Dart2js could modify type-checks to ensure that the number is in the int64 range. In this scenario, an `int` (after compilation to JavaScript) would be a floating-point number with 53 bits accuracy, but being limited to being an integer (`floor == 0`) and less than the max 64 bit integer.

## Comparison to other Platforms
Among the common and popular languages we observe two approaches (different from bigints and ECMAScript's Number type):

1. int having 32 bits.
2. architecture specific integer sizes.

Java, C#, and all languages that compile onto their VMs use 32-bit integers. Given that Java was released in 1994 (JDK Beta), and C# first appeared in 2000, it is not surprising that they chose a 32 bit integer as default size for their `int`s. At that time, 64 bit processors were uncommon (the Athlon 64 was released in 2003), and a 32-bit `int` corresponds to the equivalent `int` type in the popular languages at that time (C, C++ and Pascal/Delphi).

32 bits are generally not big enough for most applications, so Java supports a `long` type. It also supports smaller sizes. However, contrary to C#, it only features signed numbers.

C, C++, Go, and Swift support a wide range of integer types, going from `uint8` to `int64`. In addition to the specific types (imposing a specific size), Swift also supports `Int` and `UInt` which are architecture dependent: on 32-bit architectures an `Int`/`UInt` is 32 bits, whereas on a 64-bit architecture they are 64 bits.

C and C++ have a more complicated number hierarchy. Not only do they provide more architecture-specific types, `short`, `int`, `long` and `long long`, they also provide fewer guarantees. For example, an `int` simply has to be at least 16 bits. In practice `short`s are exactly 16 bit, `int`s exactly 32 bits, and `long long` exactly 64 bits wide. However, there are no reasonable guarantees for the `long` type. See the [cppreference] for a detailed table. This is, why many people use typedefs like `int8`, `uint32`, instead of the builtin integer types.

[cppreference]: http://en.cppreference.com/w/cpp/language/types

Python uses architecture-dependent types, too. Their `int` type is mapped to C's `long` type (thus guaranteeing at least 32 bits, but otherwise being dependent on the architecture and the OS). Its `long` type is an unlimited-precision integer.

Looking forward, Swift will probably converge towards a 64-bit integer world since more and more architectures are 64 bits. Apple's iPhone 5S (2013) was the first 64-bit smartphone, and Android started shipping 64-bit Androids in 2014 with the Nexus 9.

## BigInts / Migration
Since integers are of fixed size, an additional `BigInt` class is added to the `dart:typed_data` library. For code that exclusively works on big integers, this allows to migrate from Dart 1.x to Dart 2.0 by simply replacing the `int` type annotations to `BigInt` annotations. Code that is supposed to work on both small and big integers either needs to do a dynamic switch or provide two different entry points (by duplicating its code). In some cases, this might require significant rewrites.

The `BigInt` class would also behave correctly in JavaScript.

The migration to the new system is straightforward. Dart2js could maybe change their `is int` check, but is otherwise unaffected. Users would not see any change.

For the VM, shrinking `int`s to 64 bit is a breaking change. Users need to update their programs. Fortunately, these uses are generally known by the authors. Since we provide the bignum type, migrating to the new system is often as simple as changing a few type annotations and int literals (which now need to be written as `BigInt` allocations).

## Extensions
The most common concern about 64-bit integers is related to its memory use. Compared to other languages Dart would use up to two times the amount of space for integers.

If memory becomes an issue we could explore extensions that limit the size of integers for fields. For example, a type annotation like `int:32` could imply a setter that takes an `int` and bit-ands any new value with `0xFFFFFFFF` and a getter that sign-extends back to 64 bits. The underlying implementation could then use this knowledge to shrink the allocated memory for the field.

This kind of extensions is not on our priority list, but it's good to know that there are possible solutions to potential memory issues due to integers.

## Evaluation of Size and Performance
We have done experiments that show that removing bigInt support from integers significantly reduces the size of generated code for precompiled code. Here are experimental findings from Vipunen: https://docs.google.com/document/d/1IUbo_1dZWNupR6-17l28D4yw4Sbt7QUV5e8vZFOKwg0/edit

With a wrap-around int64 semantics, all arithmetic operations can be mapped to a single CPU instruction (on 64-bit architectures). As long as the compiler can avoid SMI and null checks, the performance of integer operations is thus optimal.

Alternative integer sizes (like 32 and 63 bits) may have similar performance, but have been ruled out for usability reasons (see below).

## Alternatives
The following alternatives have been investigated.

### Int64 with Throw on Under/Overflow
Instead of an implicit wrap-around, exceeding the int64 range throws.

Since many security problems are due to bad protection against overflows, the hope would be to reduce the attack vector of Dart programs.

Also, some optimizations work better when integers are not allowed to overflow.

Switching from wraparound to exceptions is a small change in this proposal. If the implementation teams (VM and AoT) present convincing numbers, we would reevaluate this alternative. Since this change is breaking, we would need to do it before our users start relying on wraparound.

### Different int32 Strategies
Executing 64-bit integer operations on 32-bit architectures is slower than sticking to 32 bits, but the main reason for 32-bit integers would be dart2js. Given the 53 bits of precision that doubles provide, dart2js can't reasonably implement a 64-bit integer.

In the following we discuss the different options that would allow dart2js to run in a 32-bit mode.

An `int` is mapped to a 32-bit integer on JavaScript and (possibly) on 32-bit architectures. Similarly to Python, the core libraries provide an additional `BigInt` type for anything that requires more precision. Alternatively or additionally, Dart provides an `int64` type.

With this specification, dart2js can easily implement the spec. The easiest approach would be to bit-and all number operations with `|0`. In JavaScript, this operation truncates numbers to 32 bits. Because of asm.js this operation is furthermore well recognized and leads to efficient code and even integer multiplication can be performed efficiently without overflow using Math.imul.

Unfortunately, lots of library code actually requires (potentially) more than 32 bits. Examples are:

``` dart
// All Iterable functions that take/return a length related value:
Iterable.length
Iterable.indexOf
List.setRange

// Same for Stream.
Stream.length
new Stream.generate

// String length
String.length
String.indexOf
Match.end

// Durations
StopWatch.elapsedTicks
Date.millisecondsSinceEpoch
Duration.inMilliseconds
```

Files with more than 2GB are not uncommon anymore (even on 32-bit systems), and working with them might require `Stream`s that use a 64-bit length. The same applies to `Iterable`s. We would thus need to annotate many of them as returning an `int64` (or simply `long`).

We could impose 64-bit integers on non-JavaScript platforms: 32 bits on the web; 64 bits everywhere else. Lots of problems with the core libraries would go away (since JavaScript has fewer core libraries and can live with more restrictions). However, some would stay (like exchanging `millisecondsSinceEpoch` values), and users wouldn't really win.

With the chosen 64-bit integer approach, dart2js isn't compliant and users will need to treat it specially. With an architecture-specific integer size, dart2js would be compliant, but users would *still* need to treat it specially.

Note that allowing 53-bit integers (just to get the most out of JavaScript numbers) wouldn't be easy either: there is no good way to wrap, truncate, or throw when numbers exceed that limit. While there is a very efficient way to truncate to 32 bits (`|0`) we are not aware of any similar efficient operation to stay in 53-bit range.

### Additional Integer Types
Many other languages provide types that denote smaller (or bigger) integers: `uint8`, ... `int64`. Our proposal doesn't exclude them for Dart, but we feel that they shouldn't be necessary. Programmers should not need to worry about the exact sizes of their integers, as long as 64 bits are enough (or 53 bits when compiling to JavaScript). In most circumstances this is very evident and doesn't require lots of cognitive overhead.

If we added multiple integer types we would furthermore have to solve the following issues:

- subtyping: is a `int8` a subtype of `int16` or `int`?
- coercions: should it be allowed to assign an `int8` to an `int16`? What about `uint8` to `int16`? or `uint16` to `int16`?

Additional integer types add little in terms of functionality. Users can always do the operation on 64-bit `int`s, followed by some bit-operations (like `& 0xFF`). Dart already provides a `toSigned(bitCount)` which makes it easy to emulate signed integers of smaller size.

Smaller integers mainly win in terms of memory, and we are confident that we can propose alternatives that don't rely on additional types.

A disadvantage of having multiple equally prominent integer types with different size and signedness is the cognitive overhead on the developer. Every time an API takes or receives an integer, the user has to consider which type is optimal. Choosing poorly leads to bad interoperability with other code (because types don't match up anymore), or, even more dangerously, the type could be too small and users run into (rare?) over and underflows.

### 63-bits (SMI Size)
Using an integer size of 63 would allow the virtual machine to only use SMIs (on 64-bit architectures) without worrying about any other integer type. It could avoid overflow checks, thus often yielding optimal speed (one CPU instruction per operation).

63 bits are furthermore enough for most API considerations. For example, `Iterable.length` would be handicapped with a 32-bit integer, but would be OK with a 63 bit integer.

We rejected this alternative because 63 bit integers are extremely uncommon (although they exist, for example in some Scheme implementations), and because some operations (mainly cryptographic routines) require 64 bits. The complexity of providing an additional 64-bit type would increase the complexity (similar to multiple integer types as discussed above).
