# Language Versioning and Experiments

This document explains our model for how to language versioning and experiment
flags interact, and the processes we use to work with them. The key principles:

*   Every major and minor (".0") release of the SDK creates a new language
    version. A shipped language version's semantics are entirely fixed by how it
    behaves in that version of the SDK.

*   At any point in time, there is an "in-progress" language version with a
    family of related languages, one for each combination of experiments.

*   Language versioning, experiment flags, and other magic for handling the core
    libraries and special packages like Flutter all boil down to mechanisms to
    select which of these many languages a given library wants to target.

## Language Versions

There is an ordered series of shipped language versions, 2.5, 2.6, etc. Each one
is a different language. They may be mutually incompatible (in practice they are
mostly compatible). Each Dart library targets&mdash;is "written in"&mdash;a
*single* version of the language. (We'll get to how they target one soon.)
Programs may contain libraries written in a variety of languages, and a Dart SDK
supports multiple different Dart versions simultaneously.

Each time we ship a major or minor stable release of the SDK, the corresponding
language version gets carved in stone. The day we shipped Dart 2.5.0, we
henceforth and forevermore declared that there is only one Dart 2.5, and it
refers to the first Dart version that supports the "constant update" changes.

As of today, the 2.5, 2.6, and 2.7 language versions are all locked down.

Patch releases, like 2.5.1, do not introduce new language versions. Both Dart
SDK 2.5.0 and 2.5.1 contain language version 2.5. This implies that we cannot
ship breaking language changes in patch releases. Doing so would spontaneously
break any user whose library already targeted that language version.

### "In-progress" version

At any point in time, there is also an **in-progress language version.** It
corresponds to the current dev build or (equivalently) the next stable version
to be released. Today's current in-progress language version is 2.8 because we
have shipped 2.7.1 and have not yet shipped 2.8.0.

Unlike the previous stable releases, the in-progress version is not carved in
stone. As we develop the SDK, its behavior may change.

### Experimental languages

The in-progress version is not alone. Hanging off it are a family of sibling
**experimental languages.** Each one corresponds to a specific combination of
experiment flags. While there is only one Dart 2.7, there are several Dart 2.8s:

*   "2.8": The Dart you get right now on bleeding edge with no experiments enabled.

*   "2.8+non-nullable": The same but with the "non-nullable" experiment enabled.

*   "2.8+variance": Likewise but with "variance" instead.

*   "2.8+non-nullable+variance": Both "non-nullable" and "variance" experiments.

All of these languages exist simultaneously and in parallel. Dart 2.6, Dart 2.7,
Dart 2.8, and Dart 2.8+non-nullable, etc. all *are* in some sense. They have
(sometimes incomplete) specs. There are tools that implement them. Think of each
as a different language with its own name, syntax, and semantics.

Don't think of an experiment flag as "turning on a feature". The feature is
there, it's just in some other language. The only question is which libraries
want to go over there and use it.

You can visualize the space of different flavors of Dart something like this:

```
┌──────── shipped ─────────┐ ┌─ in-progress ─────────────┐
older... ┄─ 2.5 ─ 2.6 ─ 2.7 ─ 2.8
                               │
           ┌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┐  2.8+non-nullable
           ╎               ╎   │
           ╎      no       ╎  2.8+variance
           ╎   languages   ╎   │
           ╎    here...    ╎  2.8+triple-shift
           ╎               ╎   │
           ╎               ╎  2.8+non-nullable+variance
           └╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┘   │
                               ┆
                              other experiment combinations...
```

There is a line of numeric languages for all of the shipped stable versions of
Dart, receding back into history. Then there is a single in-progress version and
next to it are all of the various combinations of experiments. There are no
other languages. In particular, there are no combinations of "shipped version +
experiment". **You cannot "enable an experiment" in a library targeting a shipped
version of the language.**

## Selecting a Language

This is the fundamental concept: there are a variety of different Dart languages
for various versions and combinations of experimental in-progress features.
Everything else is just a mechanism for users to select *which* of these
languages they use.

The first part to picking a language for a library is picking the numeric part.
The language versioning spec defines how that works. For completeness' sake, the
basic rules are (in priority order):

1.  A comment like `// @dart=2.5` selects that (numeric) version for the library.

2.  For other libraries in a package, the "package_config.json" file specifies
    their language version. This file is generated by pub from the SDK
    constraints in the pubspecs of the various packages the user is using.

3.  If a package does not specify an SDK constraint, then pub doesn't put a
    language version in the "package_config.json" for that file. In that case,
    libraries in that package default to the "current SDK" version.

4.  Likewise, any library not part of a package defaults to the "current SDK"
    version.

### SDK version &rarr; Language version

The "current SDK version" is generally the semver version you get when you run
one of the various Dart tools with `--version`.

To convert that three-component semver SDK version to a major.minor language
version, use this rule: **The language version of an SDK is the major and minor
version of the version reported by tools in that SDK.** This means that:

*   Stable releases of the Dart SDK have the language version you expect: Dart
    2.5.3's language version is 2.5.

*   Dev and bleeding edge releases have the language version of the upcoming
    stable release. On my machine today, `dart --version` reports
    "2.8.0-edge.a38…", which means its language version is "2.8". In other
    words, **the default language version of non-stable versions of the SDK is
    the in-progress language.**

Internally in the Dart SDK repo, the source of truth for the SDK version number
is `tools/VERSION`. That file gets updated during the release process when
various branches are cut and releases shipped. We could calculate the language
version from that using the above rule, but we're worried that that means the
language version could change inadvertently as a consequence of release
administrivia. Instead, the repo stores the language version explicitly in
`tools/experimental_features.yaml`.

In theory this means the SDK's reported version can get out of sync with its
language version. In practice, slippage should be rare and only visible to users
building the Dart SDK on bleeding edge.

### SDK constraint &rarr; Language version

The rule to convert an SDK constraint to a language is: **The default language
version used by a package is the language version of its SDK constraint's
minimum version.** Thus the following SDK constraints yield these language
versions:

*   `>=2.6.0 <3.0.0` &rarr; 2.6

*   `>=2.6.3 <3.0.0` &rarr; 2.6 (still on 2.6)

*   `>=2.7.1 <3.0.0` &rarr; 2.7 (still on 2.7)

*   `>=2.8.0-dev.1 <3.0.0` &rarr; (2.8, in-progress version)

This rule lets users target language versions that exist only in dev releases.
It also lets them use a patch version as their minimum version in order to get
bug fixes or core library changes.

## Experiment Flags

Language versioning and the above section cover cases where you just want your
library to get onto a specific numeric language version like 2.7, even including
the current in-progress version 2.8. But what if you want to play with some
experimental in-progress features? For that, you need to get onto one of the
experimental sibling languages of the in-progress version. You get there by
passing experiment flags to the various tools (and in their
`analysis_options.yaml` file).

This is *all* the experiment flags do. Passing a set of experiment flags to a
Dart tool means **Treat every user library using the in-progress language as
using the given experimental language instead.**

"User library" means libraries authored by normal Dart users outside of the Dart
and Flutter teams who may have some special powers described below.

"Using the in-progress language" means this rule only comes into play for the
in-progress language. Today, passing the "non-nullable" flag shunts every user
library targeting 2.8 over to 2.8+non-nullable, but has no effect on any library
targeting 2.7 or older. *There is no such thing as 2.7+non-nullable.* The day
2.7.0 shipped, 2.7 got locked down and all of the experimental versions
surrounding it evaporated, to be replaced by a new set of experimental languages
surrounding the new in-progress version 2.8.

Shipping a version of the SDK and language does not imply that all experiment
flags that exist at that point automatically get turned on in that version. Many
language changes gated behind experiment flags float through several releases
before finally becoming ready to ship. The "non-nullable" and "variance"
experiments existed before we shipped 2.7.0 and still exist today.

When a new version of the SDK is released, unless an experimental feature is
deliberately "shipped" (meaning the behavior is turned on by default and the
flag goes away), the flag simply carries forward as an experimental feature in
the next in-progress version. So the day we shipped Dart 2.7.0, "variance"
ceased to be a flag that affects Dart 2.7 and instead became a flag that affects
Dart 2.8.

### Experiment flags are global across all user libraries

Note that passing an experiment flag moves *all* in-progress version user
libraries onto that experimental language. If you pass "non-nullable", all of
your 2.8 libraries *and every 2.8 library in every package you use* instantly
starts targeting 2.8+non-nullable. We support mixed-mode Dart programs
consisting of libraries using a variety of *shipped* versions like 2.7 and 2.6.
You can even mix them with *one* in-progress version like 2.8 or
2.8+non-nullable.

We do *not* support user programs that are arbitrary combinations of
*experimental* languages. We don't want to have to define or implement what it
means to have, for example, a 2.8+variance library importing a 2.8+non-nullable
library and extending a generic class from it. Combinations of combinations is a
path to madness.

We may internally allow some mixture to occur because of things like core
libraries (see below), but that's because we can carefully control what code is
in that weird state. We do not want to let *users* write programs that mix
different experimental languages. If you have some user library that you don't
want to be affected by an experiment you are playing with, make sure that
library is not on the in-progress version.

### SDK core libraries and other special friends

Experiment flags are *a* way to shift a library from the in-progress version
over to one of its experimental siblings, but not the only way. Remember, all
experimental flavors of the in-progress version exist simultaneously. Experiment
flags are primarily intended to let *users* opt their libraries into one of
those experimental languages.

We on the Dart team have our own special powers. The migrated SDK core libraries
do not need the user to pass any experiment flag to move them into
2.8+non-nullable. Our tools know to do that automatically when compiling those
particular libs. Likewise, when Flutter (and a couple of packages like
vector_math that it exports from its API) migrate, we can also use whitelists or
other special sauce to move them into 2.8+non-nullable.

However, all those libraries do need to take care to select the right *numeric*
version. Because, again, there is no such thing as 2.7+non-nullable. So if, say,
a core lib doesn't get marked as 2.8, it ain't gonna be 2.8+non-nullable. Dart's
"language versioning" support is how libraries do that.

## Using Null Safety

OK, so let's put that all together to see how someone goes about being able to
use `?` and `late` in their library today.

1.  You must be running on a dev or bleeding edge build of the SDK. No stable
    release of Dart has support for any language later than 2.7.

2.  Tell Dart that your libraries should be treated as 2.8. In the core libs,
    we've been using the version comments and/or some hardcoding. In a package,
    you can set the SDK constraint to:

    ```yaml
    environment:
      sdk: >=2.8.0-dev.0 <2.8.0
    ```

    *SDK min constraint:* You can require a higher dev release if you want. The
    important part is that the minimum is at least *a dev version of 2.8.0*. You
    could also omit the SDK constraint completely. That works OK for application
    packages but not for library packages since pub will not let you publish a
    package without an SDK constraint.

    SDK max constraint: The relatively low max version gives us some wiggle room
    to break things before 2.8.0. I don't know if it's wise to claim that a
    package we publish right now will keep working all the way through, say,
    3.0.0. It's not strictly necessary. Everything in this doc still works if
    you do <3.0.0

3.  Tell your Dart compiler to shunt all version 2.8 user libraries over to
    2.8+non-nullable by passing `--enable-experiment=non-nullable` when you
    invoke the tool. Put something similar in your `analysis_options.yaml` file
    for IDE goodness. See the [experimental flags doc][] for details.

That's it. Now you have a library that Dart tools know targets 2.8+non-nullable,
at least today.

[experimental flags doc]: https://github.com/dart-lang/sdk/blob/master/docs/process/experimental-flags.md

### 2.8.0 ships without null safety

Let's say we ship Dart 2.8.0 stable and it does not include stable support for null safety. That means null safety is still behind the "non-nullable" flag. What happens?

The day this happens, 2.8 is no longer an "in-progress" language version. It has
become carved in stone and that language version refers to exactly the behavior
shipped by that SDK. All of the 2.8 experimental versions disappear. The
experiment flags no longer affect libraries using language 2.8. Instead, at that
exact same moment, a new 2.9 in-progress version appears. Any flags that we
didn't ship and carried forward now apply to that. So there is 2.9+non-nullable,
2.9+variance, etc.

This closing of 2.8 and opening of 2.9 implies several things:

*   **Any library targeting 2.8 and using null safety features needs to have its
    language version changed to target 2.9.** This can mean changing a ``//
    @dart=2.8` comment or bumping the minimum SDK constraint in the pubspec.

*   **In the 2.8.0 stable SDK that we just shipped, the language version for the
    core libraries must be 2.9.** They must be because they use null safety
    features, which can no longer be enabled for 2.8 libraries. This seems
    weird. How can 2.8.0 support a *future* version of Dart? The reality is that
    2.8.0 has secret *internal* support for some subset of 2.9 that we know the
    core libraries happen to fit within. It's an implementation detail that
    those core libraries happen to use capabilities within the SDK that we don't
    expose externally yet. It's strange, but I think should be OK.

*   **Any packages needed by Flutter for users to play with null safety after
    2.8.0 ships need to have min SDK constraints above 2.8.0.** They need to get
    to language level 2.9, and the only way to do that is with a constraint that
    excludes 2.8.0. But if users are running on Dart 2.8.0 stable, Pub won't
    select any of those packages because 2.8.0 is outside of their SDK
    constraint!

    This is a real problem, a consequence of using SDK constraints to control
    *both* language version and package resolution. To address this, shortly after
    shipping the stable build, we will also ship a Dart 2.9.0-dev.0 dev release
    and roll that into Flutter's dev channel. Anyone who wants to experiment
    with non-nullability needs to be on the dev channel. Null-safety is still an
    experimental feature, and the point of stable releases is to be, well,
    stable. If you want to experiment with experimental features, get yourself
    on dev channel.

### 2.10.0 ships with null safety

Then let's say we finally ship null safety officially in 2.10.0. Every package
out there playing with the null safety experiment has already revved its minimum
SDK constraint to something like `>=2.10.0-dev.0`. What happens next?

*   **If the SDK constraint is like `>=2.10.0-dev.0 <2.10.0`, they just need to
    raise that to include 2.10.0.** This path is the safe choice because it's
    risky to assume the next stable release will be compatible with preceding
    in-progress dev builds. The point of dev builds is that they are in flux. So
    most packages using null safety should be in this state. Once we ship null
    safety, we just need to raise their max SDK constraints to include 2.10.0
    after verifying that the package still works with the stable release.

*   **If the SDK constraint is like `>=2.10.0-dev.0 <3.0.0` the package author
    has nothing to do.** The package claims to support both the previous dev
    versions of null safety and the shipped stable version. A constraint like
    this is dubious because we reserve the right to make arbitrary breaking
    changes to features that are gated behind experiment flags. But if the
    package author is confident that no breakage has or will happen (likely
    because said "author" is a member of the Dart team), a wide constraint like
    this *can* be reasonable. And, in that case the package keeps working. It's
    already on language 2.10 and 2.10 now supports null safety out of the box.
    There's nothing to do.

*   **If the SDK constraint is like `>=2.8.0 <3.0.0`, the package is on a
    previous "legacy" language version.** The package has "opted out of NNBD"
    and keeps working like it did before.

There's nothing special about "2.10.0" in this scenario. Whenever we choose to
ship an experimental feature, in whatever version, this is how it should play
out regarding packages.
